class_name RemoteEnetMatch

extends Node


signal status_changed
signal public_table_event_received
signal player_snapshot_received
signal session_token_changed(token: String)
signal directory_changed
signal room_joined
signal room_left

const DEFAULT_HOST := "130.61.155.173"
const DEFAULT_PORT := 8765
const PROTOCOL_VERSION := 2
const PLAYER_COUNT := 4
const REQUEST_RETRY_SECONDS := 1.0
const NetworkSnapshot = preload("res://Scripts/core/MatchStateSnapshot.gd")
const NetworkCommand = preload("res://Scripts/core/MatchCommand.gd")
const NetworkHost = preload("res://Scripts/core/LocalMatchHost.gd")

var peer: ENetMultiplayerPeer
var status_text := "Удалённый сервер не подключён."
var active_host := DEFAULT_HOST
var active_port := DEFAULT_PORT
var display_name := "Игрок"
var session_token := ""
var saved_room_id := 0
var current_room_id := 0
var current_room_name := ""
var current_room_is_private := false
var directory_ready := false
var lobbies: Array[Dictionary] = []
var client_snapshot: Dictionary = {}
var client_snapshot_is_safe := false
var client_private_hand_size := 0
var client_player_index := -1
var client_seat_confirmed := false
var client_command_in_flight := false
var client_expected_revision := -1
var client_last_command_message := ""
var lobby_seats: Array[Dictionary] = []
var lobby_round_started := false
var _directory_request_sent := false
var _request_retry_elapsed := 0.0
var _rejected := false


func start_client(host: String = DEFAULT_HOST, port: int = DEFAULT_PORT, player_name: String = "", reconnect_token: String = "", reconnect_room_id: int = 0) -> bool:
	_disconnect_transport()
	active_host = host.strip_edges() if not host.strip_edges().is_empty() else DEFAULT_HOST
	active_port = port
	display_name = player_name.replace("\n", " ").replace("\r", " ").strip_edges().left(20)
	if display_name.is_empty():
		display_name = tr("Игрок")
	session_token = reconnect_token.strip_edges()
	saved_room_id = maxi(0, reconnect_room_id)
	_reset_directory_state()
	_clear_current_room(false)
	peer = ENetMultiplayerPeer.new()
	var result := peer.create_client(active_host, active_port)
	if result != OK:
		peer = null
		_set_status(tr("Не удалось начать подключение к %s:%d: %s") % [active_host, active_port, error_string(result)])
		return false
	_set_status(tr("Подключаюсь к Project Joker: %s:%d…") % [active_host, active_port])
	return true


func stop() -> void:
	_disconnect_transport()
	_reset_directory_state()
	_clear_current_room(false)
	_set_status(tr("Удалённый сервер отключён."))


func _disconnect_transport() -> void:
	if peer != null:
		peer.close()
	peer = null
	_directory_request_sent = false
	_request_retry_elapsed = 0.0
	_rejected = false


func _reset_directory_state() -> void:
	directory_ready = false
	lobbies.clear()


func _clear_current_room(clear_saved_credentials: bool) -> void:
	current_room_id = 0
	current_room_name = ""
	current_room_is_private = false
	client_snapshot.clear()
	client_snapshot_is_safe = false
	client_private_hand_size = 0
	client_player_index = -1
	client_seat_confirmed = false
	client_command_in_flight = false
	client_expected_revision = -1
	client_last_command_message = ""
	lobby_seats.clear()
	lobby_round_started = false
	if clear_saved_credentials:
		session_token = ""
		saved_room_id = 0
		session_token_changed.emit("")


func is_running() -> bool:
	return peer != null


func is_directory_connected() -> bool:
	return peer != null and directory_ready


func is_in_room() -> bool:
	return current_room_id > 0 and client_player_index >= 0


func is_host() -> bool:
	return false


func is_client() -> bool:
	return is_in_room()


func get_lobbies() -> Array[Dictionary]:
	return lobbies.duplicate(true)


func get_test_table_snapshot() -> Dictionary:
	return client_snapshot.duplicate(true)


func get_test_table_viewer_index() -> int:
	return client_player_index


func get_lobby_seats() -> Array[Dictionary]:
	return lobby_seats.duplicate(true)


func get_client_private_hand_text() -> String:
	if not client_snapshot_is_safe:
		return ""
	var names: Array[String] = []
	for card_variant in client_snapshot.get("private_hand", []):
		if card_variant is Dictionary:
			names.append(_get_serialized_card_name(card_variant))
	return tr("Твоя рука: %s") % ", ".join(names)


func is_first_turn_roll_active() -> bool:
	return false


func is_first_turn_roll_complete() -> bool:
	return false


func get_first_turn_roll_state() -> Dictionary:
	return {}


func can_submit_first_turn_roll() -> bool:
	return false


func submit_first_turn_roll() -> bool:
	return false


func request_lobby_list() -> bool:
	if peer == null or peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
		return false
	return _send_message({"type": "directory_request", "protocol_version": PROTOCOL_VERSION}, 1)


func create_lobby(room_name: String, is_private: bool, password: String = "") -> bool:
	if not is_directory_connected() or is_in_room():
		return false
	var clean_name := room_name.replace("\n", " ").replace("\r", " ").strip_edges().left(28)
	var password_hash := password.sha256_text() if is_private and not password.is_empty() else ""
	if is_private and password_hash.is_empty():
		_set_status(tr("Для закрытой комнаты нужен пароль."))
		return false
	var was_sent := _send_message({
		"type": "create_lobby",
		"protocol_version": PROTOCOL_VERSION,
		"room_name": clean_name,
		"is_private": is_private,
		"password_hash": password_hash,
		"display_name": display_name
	}, 1)
	if was_sent:
		_set_status(tr("Создаю интернет-комнату…"))
	return was_sent


func join_lobby(room_id: int, password: String = "") -> bool:
	if not is_directory_connected() or room_id <= 0:
		return false
	var reconnect_token := session_token if saved_room_id == room_id else ""
	var password_hash := password.sha256_text() if not password.is_empty() else ""
	var was_sent := _send_message({
		"type": "join_lobby",
		"protocol_version": PROTOCOL_VERSION,
		"room_id": room_id,
		"display_name": display_name,
		"session_token": reconnect_token,
		"password_hash": password_hash,
		"requested_player_index": -1
	}, 1)
	if was_sent:
		_set_status(tr("Подключаюсь к выбранной комнате…"))
	return was_sent


func leave_lobby() -> bool:
	if peer == null or not is_in_room():
		return false
	if not _send_message({"type": "leave_lobby"}, 1):
		return false
	_set_status(tr("Покидаю комнату…"))
	return true


func _process(delta: float) -> void:
	if peer == null:
		return
	peer.poll()
	var connection_status := peer.get_connection_status()
	if connection_status == MultiplayerPeer.CONNECTION_DISCONNECTED:
		peer.close()
		peer = null
		directory_ready = false
		client_seat_confirmed = false
		client_snapshot.clear()
		client_snapshot_is_safe = false
		_set_status(tr("Связь с сервером потеряна. Нажми «Подключиться» ещё раз."))
		directory_changed.emit()
		return
	if connection_status == MultiplayerPeer.CONNECTION_CONNECTED and not directory_ready and not _rejected:
		_request_retry_elapsed += delta
		if not _directory_request_sent or _request_retry_elapsed >= REQUEST_RETRY_SECONDS:
			if request_lobby_list():
				_directory_request_sent = true
				_request_retry_elapsed = 0.0
				_set_status(tr("Сервер отвечает. Получаю список комнат…"))
	while peer != null and peer.get_available_packet_count() > 0:
		var sender_peer_id := peer.get_packet_peer()
		var parsed: Variant = JSON.parse_string(peer.get_packet().get_string_from_utf8())
		if parsed is Dictionary and sender_peer_id == 1:
			_handle_message(parsed)


func _handle_message(message: Dictionary) -> void:
	match str(message.get("type", "")):
		"directory_state":
			_handle_directory_state(message)
		"directory_rejected":
			_rejected = true
			_set_status(_get_rejection_text(str(message.get("reason", "unknown"))))
		"seat_assigned":
			_handle_seat_assigned(message)
		"seat_confirmed":
			_handle_seat_confirmed(message)
		"lobby_state":
			_store_lobby_state(message)
		"left_lobby":
			_clear_current_room(true)
			_set_status(tr("Комната покинута."))
			room_left.emit()
			request_lobby_list()
		"player_snapshot":
			_handle_player_snapshot(message)
		"command_result":
			_handle_command_result(message)
		"public_table_event":
			_handle_public_table_event(message)
		"lobby_rejected":
			_set_status(_get_rejection_text(str(message.get("reason", "unknown"))))
			directory_changed.emit()
		"error":
			_set_status(tr("Ошибка сервера: %s") % str(message.get("reason", "unknown")))
		"pong":
			pass


func _handle_directory_state(message: Dictionary) -> void:
	if int(message.get("protocol_version", -1)) != PROTOCOL_VERSION:
		_rejected = true
		_set_status(tr("Версия игры не совпадает с версией сервера."))
		return
	lobbies.clear()
	var lobby_data: Variant = message.get("lobbies", [])
	if lobby_data is Array:
		for lobby_variant in lobby_data:
			if lobby_variant is Dictionary:
				lobbies.append(lobby_variant.duplicate(true))
	directory_ready = true
	_directory_request_sent = true
	if saved_room_id > 0 and current_room_id != saved_room_id:
		var saved_room_still_exists := false
		for summary in lobbies:
			if int(summary.get("room_id", 0)) == saved_room_id:
				saved_room_still_exists = true
				break
		if not saved_room_still_exists:
			session_token = ""
			saved_room_id = 0
			session_token_changed.emit("")
	_set_status(tr("Сервер подключён. Комнат в списке: %d.") % lobbies.size())
	directory_changed.emit()


func _handle_seat_assigned(message: Dictionary) -> void:
	if int(message.get("protocol_version", -1)) != PROTOCOL_VERSION:
		_rejected = true
		_set_status(tr("Версия игры не совпадает с версией сервера."))
		return
	current_room_id = int(message.get("room_id", 0))
	current_room_name = str(message.get("room_name", ""))
	current_room_is_private = bool(message.get("is_private", false))
	client_player_index = int(message.get("player_index", -1))
	if current_room_id <= 0 or client_player_index < 0 or client_player_index >= PLAYER_COUNT:
		_set_status(tr("Сервер прислал некорректное место."))
		return
	var new_token := str(message.get("session_token", "")).strip_edges()
	if not new_token.is_empty() and (new_token != session_token or saved_room_id != current_room_id):
		session_token = new_token
		saved_room_id = current_room_id
		session_token_changed.emit(session_token)
	lobby_round_started = bool(message.get("round_started", false))
	_store_lobby_seats(message.get("lobby_seats", []))
	client_seat_confirmed = false
	_rejected = false
	if _send_message({"type": "seat_ack", "player_index": client_player_index}, 1):
		_set_status(tr("Получено место %d. Подтверждаю участие…") % (client_player_index + 1))
	room_joined.emit()


func _handle_seat_confirmed(message: Dictionary) -> void:
	if int(message.get("room_id", current_room_id)) != current_room_id or int(message.get("player_index", -1)) != client_player_index:
		return
	client_seat_confirmed = true
	lobby_round_started = bool(message.get("round_started", false))
	_store_lobby_seats(message.get("lobby_seats", []))
	_set_status(_get_lobby_status())
	if lobby_round_started:
		_send_message({"type": "resync_request"}, 1)


func _store_lobby_state(message: Dictionary) -> void:
	var message_room_id := int(message.get("room_id", current_room_id))
	if current_room_id > 0 and message_room_id != current_room_id:
		return
	current_room_id = message_room_id
	current_room_name = str(message.get("room_name", current_room_name))
	current_room_is_private = bool(message.get("is_private", current_room_is_private))
	lobby_round_started = bool(message.get("round_started", false))
	_store_lobby_seats(message.get("lobby_seats", []))
	for seat in lobby_seats:
		if int(seat.get("player_index", -1)) == client_player_index:
			client_seat_confirmed = bool(seat.get("confirmed", false))
			break
	_set_status(_get_lobby_status())


func _handle_player_snapshot(message: Dictionary) -> void:
	if int(message.get("room_id", current_room_id)) != current_room_id:
		return
	var snapshot_data: Variant = message.get("snapshot", {})
	if not (snapshot_data is Dictionary) or client_player_index < 0:
		_set_status(tr("Получен повреждённый снимок стола."))
		return
	client_snapshot = snapshot_data.duplicate(true)
	client_snapshot_is_safe = NetworkSnapshot.is_player_snapshot_safe(client_snapshot, client_player_index)
	var private_hand: Variant = client_snapshot.get("private_hand", [])
	client_private_hand_size = private_hand.size() if private_hand is Array else 0
	if not client_snapshot_is_safe:
		client_snapshot.clear()
		_set_status(tr("Сервер прислал небезопасный снимок; он отклонён."))
		return
	if client_command_in_flight and (client_expected_revision < 0 or int(client_snapshot.get("revision", -1)) >= client_expected_revision):
		client_command_in_flight = false
		client_expected_revision = -1
		client_last_command_message = tr("Сервер принял действие.")
	player_snapshot_received.emit()
	_set_status(_get_lobby_status())


func _handle_command_result(message: Dictionary) -> void:
	if bool(message.get("accepted", false)):
		client_expected_revision = int(message.get("revision", -1))
		client_last_command_message = tr("Действие принято, обновляю стол…")
	else:
		client_command_in_flight = false
		client_expected_revision = -1
		client_last_command_message = tr("Сервер отклонил действие: %s.") % str(message.get("reason", "unknown"))
	_set_status(_get_lobby_status())


func _handle_public_table_event(message: Dictionary) -> void:
	var event_data: Variant = message.get("event", {})
	if not (event_data is Dictionary):
		return
	var events: Array = client_snapshot.get("public_table_events", []).duplicate(true)
	events.append(event_data.duplicate(true))
	while events.size() > 48:
		events.pop_front()
	client_snapshot["public_table_events"] = events
	public_table_event_received.emit()


func can_submit_test_bid() -> bool:
	var round_data := _get_client_round_data()
	return client_snapshot_is_safe and not client_command_in_flight and int(round_data.get("state", Round.State.SETUP)) == Round.State.BIDDING and int(round_data.get("current_player_index", -1)) == client_player_index


func get_available_test_bids() -> Array[int]:
	var available: Array[int] = []
	if not can_submit_test_bid():
		return available
	var round_data := _get_client_round_data()
	var cards_per_player := int(round_data.get("cards_per_player", 0))
	var total_previous_bids := 0
	for bid_variant in round_data.get("bids", []):
		if int(bid_variant) >= 0:
			total_previous_bids += int(bid_variant)
	for bid in range(cards_per_player + 1):
		if int(round_data.get("bids_made", 0)) == PLAYER_COUNT - 1 and total_previous_bids + bid == cards_per_player:
			continue
		available.append(bid)
	return available


func submit_test_bid(bid: int) -> bool:
	if not get_available_test_bids().has(bid):
		return false
	return _send_command(NetworkCommand.Type.BID, {"bid": bid}, tr("Отправляю заказ %d…") % bid)


func can_submit_test_card() -> bool:
	var round_data := _get_client_round_data()
	return client_snapshot_is_safe and not client_command_in_flight and int(round_data.get("state", Round.State.SETUP)) == Round.State.PLAYING and _get_current_playing_player_index() == client_player_index and not get_available_test_cards().is_empty()


func get_available_test_cards() -> Array[Dictionary]:
	var available: Array[Dictionary] = []
	if not client_snapshot_is_safe or int(_get_client_round_data().get("state", Round.State.SETUP)) != Round.State.PLAYING:
		return available
	var private_hand: Array = client_snapshot.get("private_hand", [])
	for card_variant in private_hand:
		if not (card_variant is Dictionary):
			continue
		var card_data: Dictionary = card_variant
		if bool(card_data.get("is_joker", false)) or not _is_normal_card_allowed(card_data, private_hand):
			continue
		available.append({"card_key": str(card_data.get("card_key", "")), "label": _get_serialized_card_name(card_data)})
	return available


func submit_test_card(card_key: String) -> bool:
	for card_data in get_available_test_cards():
		if str(card_data.get("card_key", "")) == card_key:
			return _send_command(NetworkCommand.Type.PLAY_CARD, {"card_key": card_key}, tr("Отправляю карту…"))
	return false


func can_submit_test_joker() -> bool:
	return client_snapshot_is_safe and not client_command_in_flight and int(_get_client_round_data().get("state", Round.State.SETUP)) == Round.State.PLAYING and _get_current_playing_player_index() == client_player_index and is_test_joker_rule_available()


func is_test_joker_rule_available() -> bool:
	if not client_snapshot_is_safe:
		return false
	for card_variant in client_snapshot.get("private_hand", []):
		if card_variant is Dictionary and bool(card_variant.get("is_joker", false)):
			return true
	return false


func is_client_test_joker_leading() -> bool:
	return can_submit_test_joker() and _get_active_trick_data().is_empty()


func submit_test_joker_choice(mode: Trick.JokerMode, declared_suit: int = -1, forced_card_rank: Trick.ForcedCardRank = Trick.ForcedCardRank.NONE) -> bool:
	if not can_submit_test_joker():
		return false
	var is_leading := is_client_test_joker_leading()
	if is_leading:
		if mode == Trick.JokerMode.NONE or declared_suit < Card.Suit.CLUBS or declared_suit > Card.Suit.DIAMONDS:
			return false
	elif mode != Trick.JokerMode.JOKER_WINS and mode != Trick.JokerMode.NORMAL_CARD_WINS:
		return false
	return _send_command(NetworkCommand.Type.PLAY_CARD, {
		"card_key": "joker",
		"joker_mode": int(mode),
		"declared_suit": declared_suit,
		"forced_card_rank": int(forced_card_rank)
	}, tr("Отправляю условие Джокера…"))


func submit_social_action(payload: Dictionary) -> bool:
	if not client_snapshot_is_safe or payload.is_empty():
		return false
	return _send_command(NetworkCommand.Type.SOCIAL_ACTION, payload, tr("Отправляю действие…"), false)


func can_request_undo() -> bool:
	if not lobby_round_started or not client_snapshot_is_safe or client_command_in_flight:
		return false
	var undo_state: Dictionary = client_snapshot.get("undo_state", {})
	return not bool(undo_state.get("pending", false)) and bool(undo_state.get("can_request", false))


func request_undo() -> bool:
	return can_request_undo() and _send_command(NetworkCommand.Type.UNDO_REQUEST, {}, tr("Запрашиваю возврат хода…"))


func can_submit_undo_vote() -> bool:
	if not lobby_round_started or not client_snapshot_is_safe or client_command_in_flight:
		return false
	var undo_state: Dictionary = client_snapshot.get("undo_state", {})
	if not bool(undo_state.get("pending", false)) or int(undo_state.get("requester_player_index", -1)) == client_player_index:
		return false
	var votes: Variant = undo_state.get("votes", [])
	return votes is Array and client_player_index >= 0 and client_player_index < votes.size() and int(votes[client_player_index]) == NetworkHost.UndoVote.NONE


func submit_undo_vote(approved: bool) -> bool:
	return can_submit_undo_vote() and _send_command(NetworkCommand.Type.UNDO_VOTE, {"approved": approved}, tr("Отправляю голос…"))


func _send_command(command_type: int, payload: Dictionary, pending_text: String, lock_until_snapshot: bool = true) -> bool:
	if not client_snapshot_is_safe or client_player_index < 0:
		return false
	var command := NetworkCommand.new(command_type, client_player_index, int(client_snapshot.get("round_number", -1)), int(client_snapshot.get("revision", -1)), payload)
	if not _send_message({"type": "match_command", "command": command.to_dictionary()}, 1):
		return false
	client_command_in_flight = lock_until_snapshot
	client_expected_revision = -1
	client_last_command_message = pending_text
	_set_status(_get_lobby_status())
	return true


func _get_client_round_data() -> Dictionary:
	var data: Variant = client_snapshot.get("round", {})
	return data if data is Dictionary else {}


func _get_active_trick_data() -> Dictionary:
	var data: Variant = client_snapshot.get("active_trick", {})
	return data if data is Dictionary else {}


func _get_current_playing_player_index() -> int:
	var trick := _get_active_trick_data()
	if not trick.is_empty():
		return int(trick.get("current_player_index", -1))
	var round_data := _get_client_round_data()
	return int(round_data.get("lead_player_index", round_data.get("current_player_index", -1)))


func _is_normal_card_allowed(card_data: Dictionary, private_hand: Array) -> bool:
	var trick := _get_active_trick_data()
	if trick.is_empty():
		return true
	var lead_suit := int(trick.get("lead_suit", -1))
	if lead_suit < 0:
		return false
	var card_suit := int(card_data.get("suit", -1))
	if _hand_has_suit(private_hand, lead_suit):
		return card_suit == lead_suit and _is_forced_card_allowed(card_data, private_hand, lead_suit, int(trick.get("forced_card_rank", Trick.ForcedCardRank.NONE)))
	var trump := int(trick.get("trump", Round.TrumpSuit.NONE))
	if trump != Round.TrumpSuit.NONE and trump != Round.TrumpSuit.RANDOM and _hand_has_suit(private_hand, trump):
		return card_suit == trump
	return true


func _hand_has_suit(hand: Array, suit: int) -> bool:
	for card_variant in hand:
		if card_variant is Dictionary and not bool(card_variant.get("is_joker", false)) and int(card_variant.get("suit", -1)) == suit:
			return true
	return false


func _is_forced_card_allowed(card_data: Dictionary, hand: Array, lead_suit: int, forced_rank: int) -> bool:
	if forced_rank == Trick.ForcedCardRank.NONE:
		return true
	var forced_card: Dictionary = {}
	for variant in hand:
		if not (variant is Dictionary):
			continue
		var candidate: Dictionary = variant
		if bool(candidate.get("is_joker", false)) or int(candidate.get("suit", -1)) != lead_suit:
			continue
		var replaces := forced_card.is_empty()
		if not replaces and forced_rank == Trick.ForcedCardRank.HIGHEST:
			replaces = int(candidate.get("rank", -1)) > int(forced_card.get("rank", -1))
		elif not replaces:
			replaces = int(candidate.get("rank", -1)) < int(forced_card.get("rank", -1))
		if replaces:
			forced_card = candidate
	return forced_card.is_empty() or str(card_data.get("card_key", "")) == str(forced_card.get("card_key", ""))


func _store_lobby_seats(data: Variant) -> void:
	lobby_seats.clear()
	if data is Array:
		for seat_variant in data:
			if seat_variant is Dictionary:
				lobby_seats.append(seat_variant.duplicate(true))


func _get_lobby_status() -> String:
	if client_player_index < 0:
		return tr("Ожидание свободного места…")
	var ready_count := 0
	for seat in lobby_seats:
		if bool(seat.get("confirmed", false)):
			ready_count += 1
	var result := tr("Ты на месте %d. Игроков готово: %d/%d.") % [client_player_index + 1, ready_count, PLAYER_COUNT]
	if lobby_round_started:
		result += " " + tr("Партия началась.")
	elif client_seat_confirmed:
		result += " " + tr("Ждём остальных игроков.")
	if not client_last_command_message.is_empty():
		result += "\n" + client_last_command_message
	return result


func _get_rejection_text(reason: String) -> String:
	match reason:
		"table_full":
			return tr("Сейчас все четыре места заняты. Попробуй немного позже.")
		"match_in_progress":
			return tr("Партия уже идёт. Войти можно только по сохранённому месту.")
		"protocol_version_mismatch":
			return tr("Нужно обновить игру: версия клиента не совпадает с сервером.")
		"wrong_password":
			return tr("Неверный пароль комнаты.")
		"room_not_found":
			return tr("Комната больше не существует. Обнови список.")
		"password_required":
			return tr("Для закрытой комнаты нужен пароль.")
		"room_limit_reached":
			return tr("На сервере временно достигнут лимит комнат.")
	return tr("Сервер отклонил подключение: %s") % reason


func _get_serialized_card_name(card_data: Dictionary) -> String:
	if bool(card_data.get("is_joker", false)):
		return tr("🃏 Джокер")
	var rank_names := ["6", "7", "8", "9", "10", "В", "Д", "К", "Т"]
	var suit_names := ["♣", "♠", "♥", "♦"]
	var rank := int(card_data.get("rank", -1))
	var suit := int(card_data.get("suit", -1))
	if rank < 0 or rank >= rank_names.size() or suit < 0 or suit >= suit_names.size():
		return tr("неизвестная карта")
	return "%s%s" % [rank_names[rank], suit_names[suit]]


func _send_message(message: Dictionary, target_peer_id: int) -> bool:
	if peer == null:
		return false
	peer.set_target_peer(target_peer_id)
	var result := peer.put_packet(JSON.stringify(message).to_utf8_buffer())
	peer.set_target_peer(0)
	return result == OK


func _set_status(new_status: String) -> void:
	if status_text == new_status:
		return
	status_text = new_status
	status_changed.emit()
