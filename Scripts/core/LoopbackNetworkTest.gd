class_name LoopbackNetworkTest

extends Node


# Временный ENet-полигон для четырёх окон на одном компьютере. Он не является
# частью обычной партии и не использует Steam или интернет.
const HOST_ADDRESS := "127.0.0.1"
const HOST_PORT := 24567
const HOST_PLAYER_INDEX := 0
const FIRST_CLIENT_PLAYER_INDEX := 1
const PLAYER_COUNT := 4
const PROTOCOL_VERSION := 2
const SNAPSHOT_DELIVERY_INTERVAL_SECONDS := 0.15
const SNAPSHOT_RETRY_INTERVAL_SECONDS := 1.0
const NetworkHost = preload("res://Scripts/core/LocalMatchHost.gd")
const NetworkSnapshot = preload("res://Scripts/core/MatchStateSnapshot.gd")


enum Mode {
	NONE,
	HOST,
	CLIENT
}


signal status_changed


var mode: Mode = Mode.NONE
var peer: ENetMultiplayerPeer
var match_host
var status_text := "Сеть не запущена."
var client_snapshot: Dictionary = {}
var client_snapshot_is_safe := false
var client_private_hand_size := 0
var client_player_index := -1
var client_requested_player_index := FIRST_CLIENT_PLAYER_INDEX
var active_host_port := HOST_PORT
var lobby_seats: Array[Dictionary] = []
var lobby_round_started := false
var client_seat_confirmed := false
var client_snapshot_acknowledged := false
var _join_request_sent := false
var _join_request_retry_seconds := 0.0
var _connected_client_peers_by_player: Dictionary = {}
var _connected_player_by_peer: Dictionary = {}
var _confirmed_client_peers_by_player: Dictionary = {}
var _snapshot_acknowledged_by_player: Dictionary = {}
var _snapshot_delivery_queue: Array[int] = []
var _snapshot_delivery_elapsed_seconds := 0.0
var _snapshot_retry_elapsed_seconds := 0.0


func start_host(local_port: int = HOST_PORT) -> bool:
	stop()
	active_host_port = local_port
	peer = ENetMultiplayerPeer.new()
	var result := peer.create_server(active_host_port, PLAYER_COUNT - 1)
	if result != OK:
		peer = null
		_set_status("Не удалось открыть локальный порт %d (ошибка %d)." % [active_host_port, result])
		return false

	var test_game := Game.new(["Хост", "Игрок 2", "Игрок 3", "Игрок 4"])
	# Ведущий занимает первое место. Тестовая раздача начнётся только тогда,
	# когда подключатся все три клиентских места.
	test_game.dealer_index = HOST_PLAYER_INDEX
	match_host = NetworkHost.new(test_game)
	mode = Mode.HOST
	_rebuild_host_lobby_seats()
	_set_status(_get_host_lobby_status())
	return true


func start_client(requested_player_index: int = FIRST_CLIENT_PLAYER_INDEX, local_port: int = HOST_PORT) -> bool:
	stop()
	client_requested_player_index = clampi(requested_player_index, FIRST_CLIENT_PLAYER_INDEX, PLAYER_COUNT - 1)
	active_host_port = local_port
	peer = ENetMultiplayerPeer.new()
	var result := peer.create_client(HOST_ADDRESS, active_host_port)
	if result != OK:
		peer = null
		_set_status("Не удалось начать подключение к хосту (ошибка %d)." % result)
		return false

	mode = Mode.CLIENT
	_set_status("Место %d подключается к 127.0.0.1:%d…" % [client_requested_player_index + 1, active_host_port])
	return true


func stop() -> void:
	if peer != null:
		peer.close()
	peer = null
	match_host = null
	mode = Mode.NONE
	client_snapshot.clear()
	client_snapshot_is_safe = false
	client_private_hand_size = 0
	client_player_index = -1
	active_host_port = HOST_PORT
	lobby_seats.clear()
	lobby_round_started = false
	client_seat_confirmed = false
	client_snapshot_acknowledged = false
	_join_request_sent = false
	_join_request_retry_seconds = 0.0
	_connected_client_peers_by_player.clear()
	_connected_player_by_peer.clear()
	_confirmed_client_peers_by_player.clear()
	_snapshot_acknowledged_by_player.clear()
	_snapshot_delivery_queue.clear()
	_snapshot_delivery_elapsed_seconds = 0.0
	_snapshot_retry_elapsed_seconds = 0.0
	_set_status("Сеть остановлена.")


func is_running() -> bool:
	return mode != Mode.NONE and peer != null


func is_host() -> bool:
	return mode == Mode.HOST


func is_client() -> bool:
	return mode == Mode.CLIENT


func is_lobby_full() -> bool:
	return is_host() and _confirmed_client_peers_by_player.size() == PLAYER_COUNT - 1


func can_start_test_round() -> bool:
	return is_lobby_full() and not lobby_round_started and match_host != null


func start_test_round() -> bool:
	if not can_start_test_round():
		_set_status("Тестовую раздачу можно начать только после подключения всех четырёх мест.")
		return false

	if not match_host.game.start_round(2, Round.RoundType.NORMAL, Round.TrumpSuit.CLUBS):
		_set_status("Не удалось начать тестовую раздачу.")
		return false

	lobby_round_started = true
	_rebuild_host_lobby_seats()
	_broadcast_lobby_state()
	_broadcast_round_started()
	_queue_player_snapshots_for_delivery()
	_set_status("Тестовая раздача начата. Ждём подтверждение получения личных рук от клиентов.")
	return true


func _process(delta: float) -> void:
	if peer == null:
		return

	# Этот peer используется напрямую, без MultiplayerAPI сцены. Поэтому
	# соединение и входящие пакеты нужно обновлять вручную каждый кадр.
	peer.poll()

	if mode == Mode.CLIENT:
		_process_client_connection(delta)
	elif mode == Mode.HOST:
		_process_snapshot_delivery(delta)

	while peer != null and peer.get_available_packet_count() > 0:
		var sender_peer_id := peer.get_packet_peer()
		# У ENetMultiplayerPeer ID относится к следующему элементу очереди.
		# После get_packet() элемент уже извлечён, и метод возвращает ID хоста.
		var packet_text := peer.get_packet().get_string_from_utf8()
		var packet_data: Variant = JSON.parse_string(packet_text)
		if not (packet_data is Dictionary):
			continue
		_handle_message(packet_data, sender_peer_id)


func _process_client_connection(delta: float) -> void:
	var connection_status := peer.get_connection_status()
	if connection_status == MultiplayerPeer.CONNECTION_DISCONNECTED:
		_set_status("Клиент не подключился: хост не найден или уже закрыт.")
		return
	if connection_status != MultiplayerPeer.CONNECTION_CONNECTED or client_player_index >= FIRST_CLIENT_PLAYER_INDEX:
		return

	_join_request_retry_seconds += delta
	if _join_request_sent and _join_request_retry_seconds < 1.0:
		return

	var join_request_was_sent := _send_message({
		"type": "join_request",
		"protocol_version": PROTOCOL_VERSION,
		"requested_player_index": client_requested_player_index
	}, 1)
	if join_request_was_sent:
		_join_request_sent = true
		_join_request_retry_seconds = 0.0
		_set_status("Клиент подключён. Запрашиваю место %d за тестовым столом…" % (client_requested_player_index + 1))


func _handle_message(message: Dictionary, sender_peer_id: int) -> void:
	var message_type := str(message.get("type", ""))
	if mode == Mode.HOST and message_type == "join_request":
		_handle_host_join_request(message, sender_peer_id)
		return
	if mode == Mode.HOST and message_type == "seat_ack":
		_handle_host_seat_ack(message, sender_peer_id)
		return
	if mode == Mode.HOST and message_type == "snapshot_ack":
		_handle_host_snapshot_ack(message, sender_peer_id)
		return
	if mode == Mode.CLIENT and message_type == "seat_assigned":
		_handle_client_seat_assigned(message)
		return
	if mode == Mode.CLIENT and message_type == "seat_confirmed":
		_handle_client_seat_confirmed(message)
		return
	if mode == Mode.CLIENT and message_type == "lobby_state":
		_handle_lobby_state(message)
		return
	if mode == Mode.CLIENT and message_type == "round_started":
		_handle_client_round_started(message)
		return
	if mode == Mode.CLIENT and message_type == "player_snapshot":
		_handle_client_snapshot(message)
		return
	if mode == Mode.CLIENT and message_type == "lobby_rejected":
		_set_status("Хост отклонил место %d: %s." % [
			client_requested_player_index + 1,
			str(message.get("reason", "неизвестная причина"))
		])


func _handle_host_join_request(message: Dictionary, sender_peer_id: int) -> void:
	if match_host == null:
		return
	if int(message.get("protocol_version", -1)) != PROTOCOL_VERSION:
		_send_message({
			"type": "lobby_rejected",
			"reason": "protocol_version_mismatch"
		}, sender_peer_id)
		return

	var requested_player_index := int(message.get("requested_player_index", -1))
	var assigned_player_index := _assign_client_player_index(sender_peer_id, requested_player_index)
	if assigned_player_index < FIRST_CLIENT_PLAYER_INDEX:
		_send_message({
			"type": "lobby_rejected",
			"reason": "seat_unavailable"
		}, sender_peer_id)
		return

	_rebuild_host_lobby_seats()
	_send_message({
		"type": "seat_assigned",
		"protocol_version": PROTOCOL_VERSION,
		"player_index": assigned_player_index,
		"lobby_seats": lobby_seats,
		"round_started": lobby_round_started
	}, sender_peer_id)
	_broadcast_lobby_state()
	_set_status(_get_host_lobby_status())


func _assign_client_player_index(sender_peer_id: int, requested_player_index: int) -> int:
	if _connected_player_by_peer.has(sender_peer_id):
		return int(_connected_player_by_peer[sender_peer_id])
	if requested_player_index < FIRST_CLIENT_PLAYER_INDEX or requested_player_index >= PLAYER_COUNT:
		requested_player_index = FIRST_CLIENT_PLAYER_INDEX

	var assigned_player_index := requested_player_index
	if _connected_client_peers_by_player.has(assigned_player_index):
		assigned_player_index = -1
		for available_player_index in range(FIRST_CLIENT_PLAYER_INDEX, PLAYER_COUNT):
			if not _connected_client_peers_by_player.has(available_player_index):
				assigned_player_index = available_player_index
				break
	if assigned_player_index < FIRST_CLIENT_PLAYER_INDEX:
		return -1

	_connected_client_peers_by_player[assigned_player_index] = sender_peer_id
	_connected_player_by_peer[sender_peer_id] = assigned_player_index
	return assigned_player_index


func _handle_host_seat_ack(message: Dictionary, sender_peer_id: int) -> void:
	var assigned_player_index := int(_connected_player_by_peer.get(sender_peer_id, -1))
	if assigned_player_index < FIRST_CLIENT_PLAYER_INDEX:
		return
	if int(message.get("player_index", -1)) != assigned_player_index:
		return

	_confirmed_client_peers_by_player[assigned_player_index] = sender_peer_id
	_rebuild_host_lobby_seats()
	_send_message({
		"type": "seat_confirmed",
		"player_index": assigned_player_index,
		"lobby_seats": lobby_seats,
		"round_started": lobby_round_started
	}, sender_peer_id)
	_broadcast_lobby_state()
	_set_status(_get_host_lobby_status())


func _handle_host_snapshot_ack(message: Dictionary, sender_peer_id: int) -> void:
	var assigned_player_index := int(_connected_player_by_peer.get(sender_peer_id, -1))
	if assigned_player_index < FIRST_CLIENT_PLAYER_INDEX or not lobby_round_started:
		return
	if int(message.get("player_index", -1)) != assigned_player_index:
		return
	if int(message.get("hand_size", 0)) != 2:
		_set_status("Клиент места %d подтвердил неверный размер руки." % (assigned_player_index + 1))
		return

	_snapshot_acknowledged_by_player[assigned_player_index] = true
	_set_status(_get_host_lobby_status())


func _handle_client_seat_assigned(message: Dictionary) -> void:
	if int(message.get("protocol_version", -1)) != PROTOCOL_VERSION:
		_set_status("Версия тестового лобби не совпадает с хостом.")
		return

	client_player_index = int(message.get("player_index", -1))
	lobby_round_started = bool(message.get("round_started", false))
	_store_lobby_seats(message.get("lobby_seats", []))
	if client_player_index < FIRST_CLIENT_PLAYER_INDEX:
		_set_status("Хост прислал некорректное место.")
		return

	client_seat_confirmed = false
	var ack_was_sent := _send_message({
		"type": "seat_ack",
		"player_index": client_player_index
	}, 1)
	if ack_was_sent:
		_set_status("Место %d назначено. Подтверждаю его хосту…" % (client_player_index + 1))
	else:
		_set_status("Место %d назначено, но подтверждение хосту не отправилось." % (client_player_index + 1))


func _handle_client_seat_confirmed(message: Dictionary) -> void:
	if int(message.get("player_index", -1)) != client_player_index:
		return
	client_seat_confirmed = true
	lobby_round_started = bool(message.get("round_started", false))
	_store_lobby_seats(message.get("lobby_seats", []))
	_set_status(_get_client_lobby_status())


func _handle_lobby_state(message: Dictionary) -> void:
	lobby_round_started = bool(message.get("round_started", false))
	_store_lobby_seats(message.get("lobby_seats", []))
	_update_client_confirmation_from_seats()
	_set_status(_get_client_lobby_status())


func _handle_client_round_started(message: Dictionary) -> void:
	lobby_round_started = true
	_store_lobby_seats(message.get("lobby_seats", []))
	_update_client_confirmation_from_seats()
	_set_status("Тестовая раздача началась. Жду только свою закрытую руку…")


func _handle_client_snapshot(message: Dictionary) -> void:
	if not _store_client_snapshot(message.get("snapshot", {})):
		_set_status("Клиент получил повреждённый снимок.")
		return
	var ack_was_sent := _send_message({
		"type": "snapshot_ack",
		"player_index": client_player_index,
		"revision": int(client_snapshot.get("revision", -1)),
		"hand_size": client_private_hand_size
	}, 1)
	client_snapshot_acknowledged = ack_was_sent
	_set_status(_get_client_lobby_status())


func _queue_player_snapshots_for_delivery() -> void:
	if match_host == null:
		return

	_snapshot_acknowledged_by_player.clear()
	_snapshot_delivery_queue.clear()
	_snapshot_delivery_elapsed_seconds = SNAPSHOT_DELIVERY_INTERVAL_SECONDS
	_snapshot_retry_elapsed_seconds = 0.0
	for player_index_variant in _confirmed_client_peers_by_player:
		_snapshot_delivery_queue.append(int(player_index_variant))


func _process_snapshot_delivery(delta: float) -> void:
	if not lobby_round_started or match_host == null:
		return

	_snapshot_delivery_elapsed_seconds += delta
	if not _snapshot_delivery_queue.is_empty() and _snapshot_delivery_elapsed_seconds >= SNAPSHOT_DELIVERY_INTERVAL_SECONDS:
		var player_index: int = int(_snapshot_delivery_queue.pop_front())
		_snapshot_delivery_elapsed_seconds = 0.0
		_send_player_snapshot(player_index)

	if _snapshot_acknowledged_by_player.size() >= PLAYER_COUNT - 1:
		return

	_snapshot_retry_elapsed_seconds += delta
	if _snapshot_retry_elapsed_seconds < SNAPSHOT_RETRY_INTERVAL_SECONDS:
		return

	_snapshot_retry_elapsed_seconds = 0.0
	for player_index_variant in _confirmed_client_peers_by_player:
		var player_index := int(player_index_variant)
		if not _snapshot_acknowledged_by_player.has(player_index) and not _snapshot_delivery_queue.has(player_index):
			_snapshot_delivery_queue.append(player_index)
	_set_status(_get_host_lobby_status())


func _send_player_snapshot(player_index: int) -> void:
	if match_host == null or not _connected_client_peers_by_player.has(player_index):
		return

	var client_peer_id := int(_connected_client_peers_by_player[player_index])
	var was_sent := _send_message({
		"type": "player_snapshot",
		"snapshot": match_host.create_player_snapshot(player_index)
	}, client_peer_id)
	if not was_sent and not _snapshot_delivery_queue.has(player_index):
		_snapshot_delivery_queue.append(player_index)


func _broadcast_round_started() -> void:
	if not is_host():
		return
	for player_index_variant in _confirmed_client_peers_by_player:
		var player_index := int(player_index_variant)
		var client_peer_id := int(_confirmed_client_peers_by_player[player_index])
		_send_message({
			"type": "round_started",
			"lobby_seats": lobby_seats
		}, client_peer_id)


func _broadcast_lobby_state() -> void:
	if not is_host():
		return
	_rebuild_host_lobby_seats()
	for player_index_variant in _connected_client_peers_by_player:
		var player_index := int(player_index_variant)
		var client_peer_id := int(_connected_client_peers_by_player[player_index])
		_send_message({
			"type": "lobby_state",
			"lobby_seats": lobby_seats,
			"round_started": lobby_round_started
		}, client_peer_id)


func _rebuild_host_lobby_seats() -> void:
	lobby_seats.clear()
	for player_index in PLAYER_COUNT:
		var is_host_player := player_index == HOST_PLAYER_INDEX
		var is_assigned := is_host_player or _connected_client_peers_by_player.has(player_index)
		var is_confirmed := is_host_player or _confirmed_client_peers_by_player.has(player_index)
		lobby_seats.append({
			"player_index": player_index,
			"display_name": "Хост" if is_host_player else "Игрок %d" % (player_index + 1),
			"is_host": is_host_player,
			"assigned": is_assigned,
			"confirmed": is_confirmed
		})


func _store_lobby_seats(seat_data: Variant) -> void:
	lobby_seats.clear()
	if not (seat_data is Array):
		return
	for seat_variant in seat_data:
		if seat_variant is Dictionary:
			lobby_seats.append(seat_variant.duplicate(true))


func _store_client_snapshot(snapshot_data: Variant) -> bool:
	if not (snapshot_data is Dictionary) or client_player_index < FIRST_CLIENT_PLAYER_INDEX:
		return false

	client_snapshot = snapshot_data.duplicate(true)
	client_snapshot_is_safe = NetworkSnapshot.is_player_snapshot_safe(client_snapshot, client_player_index)
	var private_hand: Array = client_snapshot.get("private_hand", [])
	client_private_hand_size = private_hand.size()
	return true


func _update_client_confirmation_from_seats() -> void:
	for seat in lobby_seats:
		if int(seat.get("player_index", -1)) == client_player_index:
			client_seat_confirmed = bool(seat.get("confirmed", false))
			return


func get_client_private_hand_text() -> String:
	if not client_snapshot_is_safe:
		return ""

	var card_names: Array[String] = []
	for card_variant in client_snapshot.get("private_hand", []):
		if card_variant is Dictionary:
			card_names.append(_get_serialized_card_name(card_variant))
	return "Твоя тестовая рука: %s" % ", ".join(card_names)


func _get_serialized_card_name(card_data: Dictionary) -> String:
	if bool(card_data.get("is_joker", false)):
		return "🃏 Джокер"

	var rank_names := ["6", "7", "8", "9", "10", "В", "Д", "К", "Т"]
	var suit_names := ["♣", "♠", "♥", "♦"]
	var rank := int(card_data.get("rank", -1))
	var suit := int(card_data.get("suit", -1))
	if rank < 0 or rank >= rank_names.size() or suit < 0 or suit >= suit_names.size():
		return "неизвестная карта"
	return "%s%s" % [rank_names[rank], suit_names[suit]]


func _get_host_lobby_status() -> String:
	var lines := [
		"Хост занимает место 1.",
		"Мест назначено: %d из %d. Подтверждено: %d из %d." % [
			_connected_client_peers_by_player.size(),
			PLAYER_COUNT - 1,
			_confirmed_client_peers_by_player.size(),
			PLAYER_COUNT - 1
		]
	]
	for seat in lobby_seats:
		var state_text := "подтверждён" if bool(seat.get("confirmed", false)) else "ожидание"
		if bool(seat.get("assigned", false)) and not bool(seat.get("confirmed", false)):
			state_text = "ждём подтверждение"
		lines.append("Место %d — %s: %s" % [int(seat.get("player_index", -1)) + 1, str(seat.get("display_name", "Игрок")), state_text])
	if lobby_round_started:
		lines.append("Тестовая раздача начата: руки подтвердили %d из %d клиентов." % [_snapshot_acknowledged_by_player.size(), PLAYER_COUNT - 1])
	elif is_lobby_full():
		lines.append("Все четыре места готовы. Можно начать тестовую раздачу.")
	else:
		lines.append("Открой окна для оставшихся мест.")
	return "\n".join(lines)


func _get_client_lobby_status() -> String:
	if client_player_index < FIRST_CLIENT_PLAYER_INDEX:
		return "Ожидание назначения места хостом…"

	var lines := ["Ты подключён как место %d." % (client_player_index + 1)]
	for seat in lobby_seats:
		var state_text := "подтверждён" if bool(seat.get("confirmed", false)) else "ожидание"
		if bool(seat.get("assigned", false)) and not bool(seat.get("confirmed", false)):
			state_text = "ждём подтверждение"
		lines.append("Место %d: %s" % [int(seat.get("player_index", -1)) + 1, state_text])
	if not client_seat_confirmed:
		lines.append("Ждём, пока хост подтвердит твоё место.")
	elif lobby_round_started and client_snapshot_is_safe:
		lines.append("Тестовая раздача начата. Твоя закрытая рука: %d карт." % client_private_hand_size)
		lines.append("Подтверждение руки хосту: %s." % ("отправлено" if client_snapshot_acknowledged else "не отправилось"))
	else:
		lines.append("Ждём, пока хост соберёт четыре места и начнёт раздачу.")
	return "\n".join(lines)


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
