class_name LoopbackNetworkTest

extends Node


# Временный ENet-полигон для четырёх окон на одном компьютере. Он не является
# частью обычной партии и не использует Steam или интернет.
const HOST_ADDRESS := "127.0.0.1"
const HOST_PORT := 24567
const HOST_PLAYER_INDEX := 0
const FIRST_CLIENT_PLAYER_INDEX := 1
const PLAYER_COUNT := 4
const NORMAL_ROUND_COUNT := 13
const DARK_ROUND_COUNT := 5
const NO_TRUMP_ROUND_COUNT := 4
const GOLDEN_ROUND_COUNT := 5
const MISERE_ROUND_COUNT := 5
const TOTAL_ROUND_COUNT := NORMAL_ROUND_COUNT + DARK_ROUND_COUNT + NO_TRUMP_ROUND_COUNT + GOLDEN_ROUND_COUNT + MISERE_ROUND_COUNT
const PROTOCOL_VERSION := 5
const SNAPSHOT_DELIVERY_INTERVAL_SECONDS := 0.15
const SNAPSHOT_RETRY_INTERVAL_SECONDS := 1.0
const FIRST_TURN_ROLL_REVEAL_SECONDS := 2.4
const MAX_NETWORK_DISPLAY_NAME_LENGTH := 16
const MAX_NETWORK_AVATAR_DATA_LENGTH := 180000
const NetworkHost = preload("res://Scripts/core/LocalMatchHost.gd")
const NetworkSnapshot = preload("res://Scripts/core/MatchStateSnapshot.gd")
const NetworkCommand = preload("res://Scripts/core/MatchCommand.gd")


enum Mode {
	NONE,
	HOST,
	CLIENT
}


enum TestJokerScenario {
	NONE,
	LEADING,
	RESPONSE
}


enum FirstTurnRollPhase {
	INACTIVE,
	WAITING,
	REVEAL,
	COMPLETE
}


signal status_changed
signal public_table_event_received
signal player_snapshot_received


var mode: Mode = Mode.NONE
var peer: ENetMultiplayerPeer
var match_host
var status_text := "Сеть не запущена."
var client_snapshot: Dictionary = {}
var client_snapshot_is_safe := false
var client_private_hand_size := 0
var client_player_index := -1
var client_requested_player_index := FIRST_CLIENT_PLAYER_INDEX
var client_command_in_flight := false
var client_expected_revision := -1
var client_last_command_message := ""
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
var first_turn_roll_phase: FirstTurnRollPhase = FirstTurnRollPhase.INACTIVE
var first_turn_roll_round := 0
var first_turn_roll_contenders: Array[int] = []
var first_turn_roll_submitted: Array[bool] = []
var first_turn_roll_values: Array[int] = []
var first_turn_roll_winner_index := -1
var first_turn_roll_state: Dictionary = {}
var _first_turn_roll_reveal_seconds_remaining := 0.0
var _first_turn_roll_random := RandomNumberGenerator.new()
var _avatar_index_by_player: Dictionary = {}
var _avatar_data_by_player: Dictionary = {}


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
	client_command_in_flight = false
	client_expected_revision = -1
	client_last_command_message = ""
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
	first_turn_roll_phase = FirstTurnRollPhase.INACTIVE
	first_turn_roll_round = 0
	first_turn_roll_contenders.clear()
	first_turn_roll_submitted.clear()
	first_turn_roll_values.clear()
	first_turn_roll_winner_index = -1
	first_turn_roll_state.clear()
	_first_turn_roll_reveal_seconds_remaining = 0.0
	_avatar_index_by_player.clear()
	_avatar_data_by_player.clear()
	_set_status("Сеть остановлена.")


func is_running() -> bool:
	return mode != Mode.NONE and peer != null


func is_host() -> bool:
	return mode == Mode.HOST


func is_client() -> bool:
	return mode == Mode.CLIENT


func get_test_table_snapshot() -> Dictionary:
	if is_host() and match_host != null:
		return match_host.create_player_snapshot(HOST_PLAYER_INDEX)
	if is_client():
		return client_snapshot.duplicate(true)
	return {}


func get_test_table_viewer_index() -> int:
	if is_host():
		return HOST_PLAYER_INDEX
	return client_player_index


func is_lobby_full() -> bool:
	return is_host() and _confirmed_client_peers_by_player.size() == PLAYER_COUNT - 1


func can_start_test_round() -> bool:
	return is_lobby_full() and not lobby_round_started and match_host != null


func can_begin_first_turn_roll() -> bool:
	return can_start_test_round() and first_turn_roll_phase == FirstTurnRollPhase.INACTIVE


func begin_first_turn_roll() -> bool:
	if not can_begin_first_turn_roll():
		_set_status("Розыгрыш первого хода можно начать после подготовки всех мест.")
		return false

	_first_turn_roll_random.randomize()
	first_turn_roll_winner_index = -1
	first_turn_roll_round = 0
	_start_first_turn_roll_round([0, 1, 2, 3])
	return true


func is_first_turn_roll_active() -> bool:
	if is_host():
		return first_turn_roll_phase != FirstTurnRollPhase.INACTIVE and not lobby_round_started
	return not first_turn_roll_state.is_empty() and int(first_turn_roll_state.get("phase", FirstTurnRollPhase.INACTIVE)) != FirstTurnRollPhase.INACTIVE and not lobby_round_started


func is_first_turn_roll_complete() -> bool:
	if is_host():
		return first_turn_roll_phase == FirstTurnRollPhase.COMPLETE and first_turn_roll_winner_index >= 0
	return int(first_turn_roll_state.get("phase", FirstTurnRollPhase.INACTIVE)) == FirstTurnRollPhase.COMPLETE and int(first_turn_roll_state.get("winner_player_index", -1)) >= 0


func get_first_turn_roll_state() -> Dictionary:
	if is_host():
		return _create_first_turn_roll_state()
	return first_turn_roll_state.duplicate(true)


func can_submit_first_turn_roll() -> bool:
	if not is_first_turn_roll_active() or is_first_turn_roll_complete():
		return false
	var player_index := HOST_PLAYER_INDEX if is_host() else client_player_index
	var state := get_first_turn_roll_state()
	var contenders: Array = state.get("contenders", [])
	var submitted: Array = state.get("submitted", [])
	return (
		contenders.has(player_index)
		and player_index >= 0
		and player_index < submitted.size()
		and not bool(submitted[player_index])
	)


func submit_first_turn_roll() -> bool:
	if not can_submit_first_turn_roll():
		return false
	if is_host():
		return _record_first_turn_roll(HOST_PLAYER_INDEX)

	var was_sent := _send_message({
		"type": "first_turn_roll",
		"player_index": client_player_index,
		"roll_round": int(first_turn_roll_state.get("roll_round", -1))
	}, 1)
	if was_sent:
		var submitted: Array = first_turn_roll_state.get("submitted", []).duplicate()
		if client_player_index >= 0 and client_player_index < submitted.size():
			submitted[client_player_index] = true
			first_turn_roll_state["submitted"] = submitted
		_set_status("Кубик брошен. Ждём остальных участников…")
	return was_sent


func update_local_display_name(display_name: String) -> bool:
	var local_player_index := HOST_PLAYER_INDEX if is_host() else client_player_index
	return update_local_profile(
		display_name,
		int(_avatar_index_by_player.get(local_player_index, 0)),
		str(_avatar_data_by_player.get(local_player_index, ""))
	)


func update_local_profile(display_name: String, avatar_index: int, avatar_data: String = "") -> bool:
	var sanitized_name := _sanitize_network_display_name(display_name)
	if sanitized_name.is_empty():
		return false
	var sanitized_avatar_index := clampi(avatar_index, 0, 4)
	var sanitized_avatar_data := avatar_data if avatar_data.length() <= MAX_NETWORK_AVATAR_DATA_LENGTH else ""
	if is_host():
		if match_host == null or match_host.game.players.is_empty():
			return false
		match_host.game.players[HOST_PLAYER_INDEX].display_name = sanitized_name
		_avatar_index_by_player[HOST_PLAYER_INDEX] = sanitized_avatar_index
		_avatar_data_by_player[HOST_PLAYER_INDEX] = sanitized_avatar_data
		_rebuild_host_lobby_seats()
		_broadcast_lobby_state()
		if lobby_round_started:
			_queue_player_snapshots_for_delivery()
		return true
	if not is_client() or client_player_index < FIRST_CLIENT_PLAYER_INDEX:
		return false
	_avatar_index_by_player[client_player_index] = sanitized_avatar_index
	_avatar_data_by_player[client_player_index] = sanitized_avatar_data
	return _send_message({
		"type": "profile_name",
		"player_index": client_player_index,
		"display_name": sanitized_name,
		"avatar_index": sanitized_avatar_index,
		"avatar_data": sanitized_avatar_data
	}, 1)


func can_start_first_real_round() -> bool:
	return can_start_test_round() and is_first_turn_roll_complete()


func start_test_round(force_leading_joker: bool = false) -> bool:
	var joker_scenario := TestJokerScenario.LEADING if force_leading_joker else TestJokerScenario.NONE
	return _start_test_round(joker_scenario)


func start_test_round_with_response_joker() -> bool:
	return _start_test_round(TestJokerScenario.RESPONSE)


func start_first_real_round() -> bool:
	if not can_start_first_real_round():
		_set_status("Сначала завершите розыгрыш первого хода.")
		return false
	if not _prepare_network_round(1, Round.RoundType.NORMAL, Round.TrumpSuit.RANDOM):
		return false
	_finish_network_round_start("Первая обычная раздача начата. Ждём подтверждение получения личных рук от клиентов.")
	return true


func can_start_next_scheduled_round() -> bool:
	if not is_host() or not lobby_round_started or match_host == null or match_host.game.current_round == null:
		return false
	return (
		match_host.game.current_round.state == Round.State.FINISHED
		and match_host.game.round_number < TOTAL_ROUND_COUNT
	)


func start_next_scheduled_round() -> bool:
	if not can_start_next_scheduled_round():
		_set_status("Следующую сетевую раздачу можно начать только после завершения текущей.")
		return false

	var next_round_number: int = match_host.game.round_number + 1
	var plan := _get_scheduled_round_plan(next_round_number)
	if plan.is_empty():
		_set_status("Полный сетевой цикл из %d раздач уже завершён." % TOTAL_ROUND_COUNT)
		return false

	if not match_host.start_next_round(
		int(plan.get("cards_per_player", 0)),
		int(plan.get("round_type", Round.RoundType.NORMAL)),
		int(plan.get("trump", Round.TrumpSuit.RANDOM)),
		bool(plan.get("deal_cards_immediately", true))
	):
		_set_status("Хост не смог начать следующую сетевую раздачу.")
		return false

	_finish_network_round_start("%s начата. Хост раздал карты и ждёт подтверждение личных рук от клиентов." % str(plan.get("label", "Следующая раздача")))
	return true


func _get_scheduled_round_plan(round_number: int) -> Dictionary:
	var round_index := round_number - 1
	if round_index < 0 or round_index >= TOTAL_ROUND_COUNT:
		return {}

	if round_index < NORMAL_ROUND_COUNT:
		var cards_per_player := round_index + 1 if round_index < 8 else 9
		var trump: Round.TrumpSuit = Round.TrumpSuit.RANDOM if round_index < 8 else _get_fixed_trump_for_scheduled_round(round_index - 8)
		return {
			"label": "Обычная раздача %d/%d" % [round_index + 1, NORMAL_ROUND_COUNT],
			"cards_per_player": cards_per_player,
			"round_type": Round.RoundType.NORMAL,
			"trump": trump,
			"deal_cards_immediately": true
		}

	round_index -= NORMAL_ROUND_COUNT
	if round_index < DARK_ROUND_COUNT:
		return {
			"label": "Тёмная раздача %d/%d" % [round_index + 1, DARK_ROUND_COUNT],
			"cards_per_player": 9,
			"round_type": Round.RoundType.DARK,
			"trump": _get_fixed_trump_for_scheduled_round(round_index),
			"deal_cards_immediately": false
		}

	round_index -= DARK_ROUND_COUNT
	if round_index < NO_TRUMP_ROUND_COUNT:
		return {
			"label": "Бескозырка %d/%d" % [round_index + 1, NO_TRUMP_ROUND_COUNT],
			"cards_per_player": 9,
			"round_type": Round.RoundType.NO_TRUMP,
			"trump": Round.TrumpSuit.NONE,
			"deal_cards_immediately": true
		}

	round_index -= NO_TRUMP_ROUND_COUNT
	if round_index < GOLDEN_ROUND_COUNT:
		return {
			"label": "Золотая раздача %d/%d" % [round_index + 1, GOLDEN_ROUND_COUNT],
			"cards_per_player": 9,
			"round_type": Round.RoundType.GOLDEN,
			"trump": _get_fixed_trump_for_scheduled_round(round_index),
			"deal_cards_immediately": true
		}

	round_index -= GOLDEN_ROUND_COUNT
	return {
		"label": "Мизерная раздача %d/%d" % [round_index + 1, MISERE_ROUND_COUNT],
		"cards_per_player": 9,
		"round_type": Round.RoundType.MISERE,
		"trump": _get_fixed_trump_for_scheduled_round(round_index),
		"deal_cards_immediately": true
	}


func _get_fixed_trump_for_scheduled_round(round_index: int) -> Round.TrumpSuit:
	match round_index:
		0:
			return Round.TrumpSuit.CLUBS
		1:
			return Round.TrumpSuit.SPADES
		2:
			return Round.TrumpSuit.HEARTS
		3:
			return Round.TrumpSuit.DIAMONDS
		_:
			return Round.TrumpSuit.NONE


func _start_test_round(joker_scenario: TestJokerScenario) -> bool:
	if not _prepare_network_round(2, Round.RoundType.NORMAL, Round.TrumpSuit.RANDOM):
		return false
	if joker_scenario == TestJokerScenario.LEADING:
		if not _ensure_test_round_has_non_joker_trump():
			_set_status("Не удалось подготовить открытый козырь для теста Джокера.")
			return false
		if not _ensure_leading_test_player_has_joker():
			_set_status("Не удалось подготовить тестовую раздачу с Джокером у первого игрока.")
			return false
	elif joker_scenario == TestJokerScenario.RESPONSE:
		if not _ensure_test_round_has_non_joker_trump():
			_set_status("Не удалось подготовить открытый козырь для теста Джокера.")
			return false
		if not _ensure_response_test_player_has_joker():
			_set_status("Не удалось подготовить тестовую раздачу с Джокером в ответ.")
			return false

	_finish_network_round_start("Тестовая раздача начата. Ждём подтверждение получения личных рук от клиентов.")
	return true


func _prepare_network_round(cards_per_player: int, round_type: Round.RoundType, trump: Round.TrumpSuit, deal_cards_immediately: bool = true) -> bool:
	if not can_start_test_round():
		_set_status("Тестовую раздачу можно начать только после подключения всех четырёх мест.")
		return false

	if not match_host.game.start_round(cards_per_player, round_type, trump, deal_cards_immediately):
		_set_status("Не удалось начать сетевую раздачу.")
		return false
	return true


func _finish_network_round_start(status_text: String) -> void:
	if match_host != null:
		match_host.record_current_round_started()
	lobby_round_started = true
	_rebuild_host_lobby_seats()
	_broadcast_lobby_state()
	_broadcast_round_started()
	_queue_player_snapshots_for_delivery()
	_set_status(status_text)


func _process(delta: float) -> void:
	if peer == null:
		return

	# Этот peer используется напрямую, без MultiplayerAPI сцены. Поэтому
	# соединение и входящие пакеты нужно обновлять вручную каждый кадр.
	peer.poll()

	if mode == Mode.CLIENT:
		_process_client_connection(delta)
	elif mode == Mode.HOST:
		_process_first_turn_roll(delta)
		_process_snapshot_delivery(delta)
		_process_host_undo_vote()

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
	if mode == Mode.HOST and message_type == "first_turn_roll":
		_handle_host_first_turn_roll(message, sender_peer_id)
		return
	if mode == Mode.HOST and message_type == "profile_name":
		_handle_host_profile_name(message, sender_peer_id)
		return
	if mode == Mode.HOST and message_type == "match_command":
		_handle_host_match_command(message, sender_peer_id)
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
	if mode == Mode.CLIENT and message_type == "public_table_event":
		_handle_client_public_table_event(message)
		return
	if mode == Mode.CLIENT and message_type == "command_result":
		_handle_client_command_result(message)
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
	var requested_display_name := _sanitize_network_display_name(str(message.get("display_name", "")))
	if not requested_display_name.is_empty() and assigned_player_index < match_host.game.players.size():
		match_host.game.players[assigned_player_index].display_name = requested_display_name
	_store_network_avatar_profile(assigned_player_index, message)

	_rebuild_host_lobby_seats()
	_send_message({
		"type": "seat_assigned",
		"protocol_version": PROTOCOL_VERSION,
		"player_index": assigned_player_index,
		"lobby_seats": lobby_seats,
		"round_started": lobby_round_started,
		"first_turn_roll": _create_first_turn_roll_state()
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
		"round_started": lobby_round_started,
		"first_turn_roll": _create_first_turn_roll_state()
	}, sender_peer_id)
	_broadcast_lobby_state()
	_set_status(_get_host_lobby_status())


func _handle_host_snapshot_ack(message: Dictionary, sender_peer_id: int) -> void:
	var assigned_player_index := int(_connected_player_by_peer.get(sender_peer_id, -1))
	if assigned_player_index < FIRST_CLIENT_PLAYER_INDEX or not lobby_round_started:
		return
	if int(message.get("player_index", -1)) != assigned_player_index:
		return
	if match_host == null or assigned_player_index >= match_host.game.players.size():
		return
	var expected_hand_size: int = match_host.game.players[assigned_player_index].hand.size()
	if int(message.get("hand_size", -1)) != expected_hand_size:
		_set_status("Клиент места %d подтвердил неверный размер руки." % (assigned_player_index + 1))
		return
	if int(message.get("revision", -1)) != match_host.revision:
		return

	_snapshot_acknowledged_by_player[assigned_player_index] = true
	_set_status(_get_host_lobby_status())


func _handle_host_first_turn_roll(message: Dictionary, sender_peer_id: int) -> void:
	var assigned_player_index := int(_connected_player_by_peer.get(sender_peer_id, -1))
	if assigned_player_index < FIRST_CLIENT_PLAYER_INDEX:
		return
	if int(message.get("player_index", -1)) != assigned_player_index:
		return
	if int(message.get("roll_round", -1)) != first_turn_roll_round:
		return
	_record_first_turn_roll(assigned_player_index)


func _handle_host_profile_name(message: Dictionary, sender_peer_id: int) -> void:
	var assigned_player_index := int(_connected_player_by_peer.get(sender_peer_id, -1))
	if assigned_player_index < FIRST_CLIENT_PLAYER_INDEX:
		return
	if int(message.get("player_index", -1)) != assigned_player_index:
		return
	var display_name := _sanitize_network_display_name(str(message.get("display_name", "")))
	if display_name.is_empty() or match_host == null or assigned_player_index >= match_host.game.players.size():
		return
	match_host.game.players[assigned_player_index].display_name = display_name
	_store_network_avatar_profile(assigned_player_index, message)
	_rebuild_host_lobby_seats()
	_broadcast_lobby_state()
	if lobby_round_started:
		_queue_player_snapshots_for_delivery()
	_set_status("Место %d теперь отображается как %s." % [assigned_player_index + 1, display_name])


func _sanitize_network_display_name(display_name: String) -> String:
	return display_name.replace("\n", " ").replace("\r", " ").strip_edges().left(MAX_NETWORK_DISPLAY_NAME_LENGTH)


func _store_network_avatar_profile(player_index: int, profile_data: Dictionary) -> void:
	_avatar_index_by_player[player_index] = clampi(int(profile_data.get("avatar_index", 0)), 0, 4)
	var avatar_data := str(profile_data.get("avatar_data", ""))
	_avatar_data_by_player[player_index] = avatar_data if avatar_data.length() <= MAX_NETWORK_AVATAR_DATA_LENGTH else ""


func _handle_host_match_command(message: Dictionary, sender_peer_id: int) -> void:
	if match_host == null:
		return

	var assigned_player_index := int(_connected_player_by_peer.get(sender_peer_id, -1))
	if assigned_player_index < FIRST_CLIENT_PLAYER_INDEX or not _confirmed_client_peers_by_player.has(assigned_player_index):
		return

	var command_data: Variant = message.get("command", {})
	if not (command_data is Dictionary):
		_send_command_result(sender_peer_id, false, "invalid_command", match_host.revision)
		return

	var requested_type := int(command_data.get("type", NetworkCommand.Type.INVALID))
	if requested_type != NetworkCommand.Type.BID and requested_type != NetworkCommand.Type.PLAY_CARD and requested_type != NetworkCommand.Type.SOCIAL_ACTION and requested_type != NetworkCommand.Type.UNDO_REQUEST and requested_type != NetworkCommand.Type.UNDO_VOTE:
		_send_command_result(sender_peer_id, false, "unsupported_command", match_host.revision)
		return

	var payload_data: Variant = command_data.get("payload", {})
	if not (payload_data is Dictionary):
		_send_command_result(sender_peer_id, false, "invalid_payload", match_host.revision)
		return
	var command := NetworkCommand.new(
		requested_type,
		assigned_player_index,
		int(command_data.get("round_number", -1)),
		int(command_data.get("revision", -1)),
		payload_data
	)
	var result: Dictionary = match_host.apply_command(command)
	var accepted := bool(result.get("accepted", false))
	_send_command_result(sender_peer_id, accepted, str(result.get("reason", "unknown")), match_host.revision)
	if not accepted:
		_set_status("Хост отклонил действие места %d: %s." % [assigned_player_index + 1, str(result.get("reason", "unknown"))])
		return

	if requested_type == NetworkCommand.Type.SOCIAL_ACTION:
		_broadcast_latest_public_table_event()
	_queue_player_snapshots_for_delivery()
	var action_name := "заказ" if requested_type == NetworkCommand.Type.BID else "ход картой" if requested_type == NetworkCommand.Type.PLAY_CARD else "запрос на возврат" if requested_type == NetworkCommand.Type.UNDO_REQUEST else "голос за возврат" if requested_type == NetworkCommand.Type.UNDO_VOTE else "социальное действие"
	_set_status("Хост принял %s места %d. Ревизия %d отправляется всем клиентам." % [action_name, assigned_player_index + 1, match_host.revision])


func _send_command_result(target_peer_id: int, accepted: bool, reason: String, revision: int) -> void:
	_send_message({
		"type": "command_result",
		"accepted": accepted,
		"reason": reason,
		"revision": revision
	}, target_peer_id)


func _handle_client_seat_assigned(message: Dictionary) -> void:
	if int(message.get("protocol_version", -1)) != PROTOCOL_VERSION:
		_set_status("Версия тестового лобби не совпадает с хостом.")
		return

	client_player_index = int(message.get("player_index", -1))
	lobby_round_started = bool(message.get("round_started", false))
	_store_lobby_seats(message.get("lobby_seats", []))
	_store_first_turn_roll_state(message.get("first_turn_roll", {}))
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
	_store_first_turn_roll_state(message.get("first_turn_roll", {}))
	_set_status(_get_client_lobby_status())


func _handle_lobby_state(message: Dictionary) -> void:
	lobby_round_started = bool(message.get("round_started", false))
	_store_lobby_seats(message.get("lobby_seats", []))
	_store_first_turn_roll_state(message.get("first_turn_roll", {}))
	_update_client_confirmation_from_seats()
	_set_status(_get_client_lobby_status())


func _handle_client_round_started(message: Dictionary) -> void:
	lobby_round_started = true
	client_snapshot_acknowledged = false
	client_command_in_flight = false
	client_expected_revision = -1
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
	if client_command_in_flight and client_expected_revision >= 0 and int(client_snapshot.get("revision", -1)) >= client_expected_revision:
		client_command_in_flight = false
		client_expected_revision = -1
		client_last_command_message = "Хост принял действие. Стол обновлён."
	# Состояние игрового стола может поменяться без изменения status_text:
	# например, при отсчёте голосования за возврат хода или при его тайм-ауте.
	# Отдельный сигнал заставляет клиент перерисовать стол сразу после приёма
	# безопасного личного снимка, а не ждать следующего собственного действия.
	player_snapshot_received.emit()
	_set_status(_get_client_lobby_status())


func _handle_client_public_table_event(message: Dictionary) -> void:
	var event_data: Variant = message.get("event", {})
	if not (event_data is Dictionary):
		return
	var event: Dictionary = event_data.duplicate(true)
	var event_id := int(event.get("event_id", -1))
	if event_id < 0:
		return

	var events: Array = client_snapshot.get("public_table_events", []).duplicate(true)
	for existing_event_variant in events:
		if existing_event_variant is Dictionary and int((existing_event_variant as Dictionary).get("event_id", -1)) == event_id:
			return
	events.append(event)
	while events.size() > 48:
		events.pop_front()
	client_snapshot["public_table_events"] = events
	public_table_event_received.emit()
	_set_status(_get_client_lobby_status())


func _handle_client_command_result(message: Dictionary) -> void:
	var accepted := bool(message.get("accepted", false))
	var reason := str(message.get("reason", "unknown"))
	if accepted:
		client_expected_revision = int(message.get("revision", -1))
		client_last_command_message = "Хост принял действие. Получаю обновлённый стол…"
	else:
		client_command_in_flight = false
		client_expected_revision = -1
		client_last_command_message = "Хост отклонил действие: %s." % reason
	_set_status(_get_client_lobby_status())


func can_submit_test_bid() -> bool:
	if not client_snapshot_is_safe or client_player_index < FIRST_CLIENT_PLAYER_INDEX or client_command_in_flight:
		return false

	var round_data: Dictionary = _get_client_round_data()
	return (
		int(round_data.get("state", Round.State.SETUP)) == Round.State.BIDDING
		and int(round_data.get("current_player_index", -1)) == client_player_index
	)


func get_available_test_bids() -> Array[int]:
	var available_bids: Array[int] = []
	if not can_submit_test_bid():
		return available_bids

	var round_data: Dictionary = _get_client_round_data()
	var cards_per_player := int(round_data.get("cards_per_player", 0))
	var bids_made := int(round_data.get("bids_made", 0))
	var total_previous_bids := 0
	var bids_data: Variant = round_data.get("bids", [])
	if bids_data is Array:
		for bid_variant in bids_data:
			var bid := int(bid_variant)
			if bid >= 0:
				total_previous_bids += bid

	for bid in range(cards_per_player + 1):
		if bids_made == PLAYER_COUNT - 1 and total_previous_bids + bid == cards_per_player:
			continue
		available_bids.append(bid)
	return available_bids


func submit_test_bid(bid: int) -> bool:
	if not can_submit_test_bid() or not get_available_test_bids().has(bid):
		return false

	var command := NetworkCommand.new(
		NetworkCommand.Type.BID,
		client_player_index,
		int(client_snapshot.get("round_number", -1)),
		int(client_snapshot.get("revision", -1)),
		{"bid": bid}
	)
	var was_sent := _send_message({
		"type": "match_command",
		"command": command.to_dictionary()
	}, 1)
	if not was_sent:
		client_last_command_message = "Не удалось отправить заказ хосту."
		_set_status(_get_client_lobby_status())
		return false

	client_command_in_flight = true
	client_last_command_message = "Отправляю заказ %d хосту…" % bid
	_set_status(_get_client_lobby_status())
	return true


func can_submit_test_card() -> bool:
	if not client_snapshot_is_safe or client_player_index < FIRST_CLIENT_PLAYER_INDEX or client_command_in_flight:
		return false

	var round_data: Dictionary = _get_client_round_data()
	return (
		int(round_data.get("state", Round.State.SETUP)) == Round.State.PLAYING
		and _get_client_current_playing_player_index() == client_player_index
		and not get_available_test_cards().is_empty()
	)


func get_available_test_cards() -> Array[Dictionary]:
	var available_cards: Array[Dictionary] = []
	if not client_snapshot_is_safe:
		return available_cards

	var round_data: Dictionary = _get_client_round_data()
	if int(round_data.get("state", Round.State.SETUP)) != Round.State.PLAYING:
		return available_cards

	var private_hand: Variant = client_snapshot.get("private_hand", [])
	if not (private_hand is Array):
		return available_cards

	for card_variant in private_hand:
		if not (card_variant is Dictionary):
			continue
		var card_data: Dictionary = card_variant
		if bool(card_data.get("is_joker", false)) or not _is_client_normal_card_allowed(card_data, private_hand):
			continue
		available_cards.append({
			"card_key": str(card_data.get("card_key", "")),
			"label": _get_serialized_card_name(card_data)
		})
	return available_cards


func submit_test_card(card_key: String) -> bool:
	if not can_submit_test_card():
		return false

	var is_available := false
	for card_data in get_available_test_cards():
		if str(card_data.get("card_key", "")) == card_key:
			is_available = true
			break
	if not is_available:
		return false

	var command := NetworkCommand.new(
		NetworkCommand.Type.PLAY_CARD,
		client_player_index,
		int(client_snapshot.get("round_number", -1)),
		int(client_snapshot.get("revision", -1)),
		{"card_key": card_key}
	)
	var was_sent := _send_message({
		"type": "match_command",
		"command": command.to_dictionary()
	}, 1)
	if not was_sent:
		client_last_command_message = "Не удалось отправить ход хосту."
		_set_status(_get_client_lobby_status())
		return false

	client_command_in_flight = true
	client_expected_revision = -1
	client_last_command_message = "Отправляю ход %s хосту…" % card_key
	_set_status(_get_client_lobby_status())
	return true


func can_submit_test_joker() -> bool:
	if not client_snapshot_is_safe or client_player_index < FIRST_CLIENT_PLAYER_INDEX or client_command_in_flight:
		return false

	var round_data: Dictionary = _get_client_round_data()
	return (
		int(round_data.get("state", Round.State.SETUP)) == Round.State.PLAYING
		and _get_client_current_playing_player_index() == client_player_index
		and _is_client_joker_allowed()
	)


func is_client_test_joker_leading() -> bool:
	return can_submit_test_joker() and _get_client_active_trick_data().is_empty()


func submit_test_joker_choice(mode: Trick.JokerMode, declared_suit: int = -1, forced_card_rank: Trick.ForcedCardRank = Trick.ForcedCardRank.NONE) -> bool:
	if not can_submit_test_joker() or not _is_test_joker_choice_valid(is_client_test_joker_leading(), mode, declared_suit, forced_card_rank):
		return false

	var command := NetworkCommand.new(
		NetworkCommand.Type.PLAY_CARD,
		client_player_index,
		int(client_snapshot.get("round_number", -1)),
		int(client_snapshot.get("revision", -1)),
		_build_joker_payload(mode, declared_suit, forced_card_rank)
	)
	var was_sent := _send_message({
		"type": "match_command",
		"command": command.to_dictionary()
	}, 1)
	if not was_sent:
		client_last_command_message = "Не удалось отправить ход Джокером хосту."
		_set_status(_get_client_lobby_status())
		return false

	client_command_in_flight = true
	client_expected_revision = -1
	client_last_command_message = "Отправляю условие Джокера хосту…"
	_set_status(_get_client_lobby_status())
	return true


func submit_social_action(payload: Dictionary) -> bool:
	if not is_running() or payload.is_empty():
		return false

	if is_host():
		if match_host == null or not lobby_round_started:
			return false
		var host_command := NetworkCommand.new(
			NetworkCommand.Type.SOCIAL_ACTION,
			HOST_PLAYER_INDEX,
			match_host.game.round_number,
			match_host.revision,
			payload
		)
		var host_result: Dictionary = match_host.apply_command(host_command)
		if not bool(host_result.get("accepted", false)):
			_set_status("Хост не смог отправить действие: %s." % str(host_result.get("reason", "unknown")))
			return false
		_broadcast_latest_public_table_event()
		_queue_player_snapshots_for_delivery()
		return true

	if not is_client() or not client_snapshot_is_safe or client_player_index < FIRST_CLIENT_PLAYER_INDEX:
		return false
	var command := NetworkCommand.new(
		NetworkCommand.Type.SOCIAL_ACTION,
		client_player_index,
		int(client_snapshot.get("round_number", -1)),
		int(client_snapshot.get("revision", -1)),
		payload
	)
	var was_sent := _send_message({
		"type": "match_command",
		"command": command.to_dictionary()
	}, 1)
	if not was_sent:
		client_last_command_message = "Не удалось отправить действие за столом."
		_set_status(_get_client_lobby_status())
		return false

	client_last_command_message = "Отправляю действие за столом…"
	_set_status(_get_client_lobby_status())
	return true


func can_request_undo() -> bool:
	if not lobby_round_started:
		return false
	if is_host():
		if match_host == null:
			return false
		return match_host.can_player_request_undo(HOST_PLAYER_INDEX)
	if not is_client() or not client_snapshot_is_safe or client_command_in_flight:
		return false
	var undo_state: Dictionary = client_snapshot.get("undo_state", {})
	return not bool(undo_state.get("pending", false)) and bool(undo_state.get("can_request", false))


func request_undo() -> bool:
	if not can_request_undo():
		return false
	if is_host():
		if match_host == null:
			return false
		var host_command := NetworkCommand.new(
			NetworkCommand.Type.UNDO_REQUEST,
			HOST_PLAYER_INDEX,
			match_host.game.round_number,
			match_host.revision
		)
		var host_result: Dictionary = match_host.apply_command(host_command)
		if not bool(host_result.get("accepted", false)):
			_set_status("Хост не смог запросить возврат: %s." % str(host_result.get("reason", "unknown")))
			return false
		_queue_player_snapshots_for_delivery()
		_set_status("Хост запросил возврат последнего решения. Ожидаем голоса.")
		return true

	var command := NetworkCommand.new(
		NetworkCommand.Type.UNDO_REQUEST,
		client_player_index,
		int(client_snapshot.get("round_number", -1)),
		int(client_snapshot.get("revision", -1))
	)
	if not _send_message({"type": "match_command", "command": command.to_dictionary()}, 1):
		client_last_command_message = "Не удалось отправить запрос на возврат хосту."
		_set_status(_get_client_lobby_status())
		return false
	client_command_in_flight = true
	client_expected_revision = -1
	client_last_command_message = "Запрашиваю согласие игроков на возврат хода…"
	_set_status(_get_client_lobby_status())
	return true


func can_submit_undo_vote() -> bool:
	if not lobby_round_started:
		return false
	if is_host():
		if match_host == null:
			return false
		var host_undo_state: Dictionary = match_host.create_player_snapshot(HOST_PLAYER_INDEX).get("undo_state", {})
		return _can_player_vote_on_undo(host_undo_state, HOST_PLAYER_INDEX)
	if not is_client() or not client_snapshot_is_safe or client_command_in_flight:
		return false
	return _can_player_vote_on_undo(client_snapshot.get("undo_state", {}), client_player_index)


func submit_undo_vote(approved: bool) -> bool:
	if not can_submit_undo_vote():
		return false
	if is_host():
		if match_host == null:
			return false
		var host_command := NetworkCommand.new(
			NetworkCommand.Type.UNDO_VOTE,
			HOST_PLAYER_INDEX,
			match_host.game.round_number,
			match_host.revision,
			{"approved": approved}
		)
		var host_result: Dictionary = match_host.apply_command(host_command)
		if not bool(host_result.get("accepted", false)):
			_set_status("Хост не смог учесть голос: %s." % str(host_result.get("reason", "unknown")))
			return false
		_queue_player_snapshots_for_delivery()
		_set_status("Хост %s возврат хода." % ("подтвердил" if approved else "отклонил"))
		return true

	var command := NetworkCommand.new(
		NetworkCommand.Type.UNDO_VOTE,
		client_player_index,
		int(client_snapshot.get("round_number", -1)),
		int(client_snapshot.get("revision", -1)),
		{"approved": approved}
	)
	if not _send_message({"type": "match_command", "command": command.to_dictionary()}, 1):
		client_last_command_message = "Не удалось отправить голос хосту."
		_set_status(_get_client_lobby_status())
		return false
	client_command_in_flight = true
	client_expected_revision = -1
	client_last_command_message = "Отправляю голос за возврат хода…"
	_set_status(_get_client_lobby_status())
	return true


func _can_player_vote_on_undo(undo_state: Dictionary, player_index: int) -> bool:
	if not bool(undo_state.get("pending", false)) or int(undo_state.get("requester_player_index", -1)) == player_index:
		return false
	var votes: Variant = undo_state.get("votes", [])
	return votes is Array and player_index >= 0 and player_index < votes.size() and int(votes[player_index]) == NetworkHost.UndoVote.NONE


func _process_host_undo_vote() -> void:
	if match_host == null or not match_host.process_undo_vote():
		return
	_queue_player_snapshots_for_delivery()
	_set_status("Голосование за возврат хода завершено. Обновляю стол для всех игроков.")


func can_submit_host_test_bid() -> bool:
	if not is_host() or not lobby_round_started or match_host == null:
		return false

	var round: Round = match_host.game.current_round
	return round != null and round.state == Round.State.BIDDING and round.current_player_index == HOST_PLAYER_INDEX


func get_available_host_test_bids() -> Array[int]:
	var available_bids: Array[int] = []
	if not can_submit_host_test_bid():
		return available_bids

	var round: Round = match_host.game.current_round
	for bid in range(round.cards_per_player + 1):
		if round.can_place_bid(HOST_PLAYER_INDEX, bid):
			available_bids.append(bid)
	return available_bids


func submit_host_test_bid(bid: int) -> bool:
	if not can_submit_host_test_bid() or not get_available_host_test_bids().has(bid):
		return false

	var command := NetworkCommand.new(
		NetworkCommand.Type.BID,
		HOST_PLAYER_INDEX,
		match_host.game.round_number,
		match_host.revision,
		{"bid": bid}
	)
	var result: Dictionary = match_host.apply_command(command)
	if not bool(result.get("accepted", false)):
		_set_status("Хост не смог подтвердить свой заказ: %s." % str(result.get("reason", "unknown")))
		return false

	_queue_player_snapshots_for_delivery()
	_set_status("Хост принял свой заказ %d. Ревизия %d отправляется всем клиентам." % [bid, match_host.revision])
	return true


func can_submit_host_test_card() -> bool:
	if not is_host() or not lobby_round_started or match_host == null:
		return false

	var round: Round = match_host.game.current_round
	return (
		round != null
		and round.state == Round.State.PLAYING
		and _get_host_current_playing_player_index() == HOST_PLAYER_INDEX
		and not get_available_host_test_cards().is_empty()
	)


func get_available_host_test_cards() -> Array[Dictionary]:
	var available_cards: Array[Dictionary] = []
	if not is_host() or match_host == null:
		return available_cards

	var round: Round = match_host.game.current_round
	if round == null or round.state != Round.State.PLAYING:
		return available_cards

	var player: Player = match_host.game.players[HOST_PLAYER_INDEX]
	for card in player.hand:
		if card.is_joker:
			continue
		if match_host.game.active_trick != null and not match_host.game.active_trick.can_play_card(player, card):
			continue
		available_cards.append({
			"card_key": _get_card_key(card),
			"label": _get_card_name(card)
		})
	return available_cards


func submit_host_test_card(card_key: String) -> bool:
	if not can_submit_host_test_card():
		return false

	var is_available := false
	for card_data in get_available_host_test_cards():
		if str(card_data.get("card_key", "")) == card_key:
			is_available = true
			break
	if not is_available:
		return false

	var command := NetworkCommand.new(
		NetworkCommand.Type.PLAY_CARD,
		HOST_PLAYER_INDEX,
		match_host.game.round_number,
		match_host.revision,
		{"card_key": card_key}
	)
	var result: Dictionary = match_host.apply_command(command)
	if not bool(result.get("accepted", false)):
		_set_status("Хост не смог принять свой ход: %s." % str(result.get("reason", "unknown")))
		return false

	_queue_player_snapshots_for_delivery()
	_set_status("Хост сыграл %s. Ревизия %d отправляется всем клиентам." % [card_key, match_host.revision])
	return true


func can_submit_host_test_joker() -> bool:
	if not is_host() or not lobby_round_started or match_host == null:
		return false

	var round: Round = match_host.game.current_round
	if round == null or round.state != Round.State.PLAYING or _get_host_current_playing_player_index() != HOST_PLAYER_INDEX:
		return false

	var player: Player = match_host.game.players[HOST_PLAYER_INDEX]
	for card in player.hand:
		if card.is_joker and (match_host.game.active_trick == null or match_host.game.active_trick.can_play_card(player, card)):
			return true
	return false


func is_host_test_joker_leading() -> bool:
	return can_submit_host_test_joker() and match_host.game.active_trick == null


func submit_host_test_joker_choice(mode: Trick.JokerMode, declared_suit: int = -1, forced_card_rank: Trick.ForcedCardRank = Trick.ForcedCardRank.NONE) -> bool:
	if not can_submit_host_test_joker() or not _is_test_joker_choice_valid(is_host_test_joker_leading(), mode, declared_suit, forced_card_rank):
		return false

	var command := NetworkCommand.new(
		NetworkCommand.Type.PLAY_CARD,
		HOST_PLAYER_INDEX,
		match_host.game.round_number,
		match_host.revision,
		_build_joker_payload(mode, declared_suit, forced_card_rank)
	)
	var result: Dictionary = match_host.apply_command(command)
	if not bool(result.get("accepted", false)):
		_set_status("Хост не смог применить условие Джокера: %s." % str(result.get("reason", "unknown")))
		return false

	_queue_player_snapshots_for_delivery()
	_set_status("Хост сыграл Джокером. Ревизия %d отправляется всем клиентам." % match_host.revision)
	return true


func _get_client_current_playing_player_index() -> int:
	var active_trick_data: Dictionary = _get_client_active_trick_data()
	if not active_trick_data.is_empty():
		return int(active_trick_data.get("current_player_index", -1))

	var round_data: Dictionary = _get_client_round_data()
	return int(round_data.get("lead_player_index", round_data.get("current_player_index", -1)))


func _get_host_current_playing_player_index() -> int:
	if match_host == null or match_host.game.current_round == null:
		return -1
	if match_host.game.active_trick != null:
		return match_host.game.active_trick.current_player_index
	return match_host.game.current_round.lead_player_index


func _get_client_active_trick_data() -> Dictionary:
	var active_trick_data: Variant = client_snapshot.get("active_trick", {})
	if active_trick_data is Dictionary:
		return active_trick_data
	return {}


func _is_client_normal_card_allowed(card_data: Dictionary, private_hand: Array) -> bool:
	var active_trick_data: Dictionary = _get_client_active_trick_data()
	if active_trick_data.is_empty():
		return true

	var lead_suit := int(active_trick_data.get("lead_suit", -1))
	if lead_suit < 0:
		return false
	var card_suit := int(card_data.get("suit", -1))
	if _serialized_hand_has_suit(private_hand, lead_suit):
		return card_suit == lead_suit and _is_client_forced_card_allowed(card_data, private_hand, lead_suit, int(active_trick_data.get("forced_card_rank", Trick.ForcedCardRank.NONE)))

	var trump := int(active_trick_data.get("trump", Round.TrumpSuit.NONE))
	if trump != Round.TrumpSuit.NONE and trump != Round.TrumpSuit.RANDOM and _serialized_hand_has_suit(private_hand, trump):
		return card_suit == trump
	return true


func _is_client_forced_card_allowed(card_data: Dictionary, private_hand: Array, lead_suit: int, forced_card_rank: int) -> bool:
	if forced_card_rank == Trick.ForcedCardRank.NONE:
		return true

	var forced_card: Dictionary = {}
	for hand_card_variant in private_hand:
		if not (hand_card_variant is Dictionary):
			continue
		var hand_card: Dictionary = hand_card_variant
		if bool(hand_card.get("is_joker", false)) or int(hand_card.get("suit", -1)) != lead_suit:
			continue
		if forced_card.is_empty():
			forced_card = hand_card
			continue
		var should_replace := int(hand_card.get("rank", -1)) > int(forced_card.get("rank", -1)) if forced_card_rank == Trick.ForcedCardRank.HIGHEST else int(hand_card.get("rank", -1)) < int(forced_card.get("rank", -1))
		if should_replace:
			forced_card = hand_card

	return forced_card.is_empty() or str(card_data.get("card_key", "")) == str(forced_card.get("card_key", ""))


func _is_client_joker_allowed() -> bool:
	var private_hand: Variant = client_snapshot.get("private_hand", [])
	if not (private_hand is Array):
		return false

	var has_joker := false
	for card_variant in private_hand:
		if card_variant is Dictionary and bool(card_variant.get("is_joker", false)):
			has_joker = true
			break
	if not has_joker:
		return false

	# Клиентская подсветка повторяет правило хоста: Джокер разрешён в ответ
	# независимо от наличия масти или козыря.
	return true


func _is_test_joker_choice_valid(is_leading: bool, mode: Trick.JokerMode, declared_suit: int, forced_card_rank: Trick.ForcedCardRank) -> bool:
	if is_leading:
		return (
			mode != Trick.JokerMode.NONE
			and declared_suit >= Card.Suit.CLUBS
			and declared_suit <= Card.Suit.DIAMONDS
			and forced_card_rank >= Trick.ForcedCardRank.NONE
			and forced_card_rank <= Trick.ForcedCardRank.LOWEST
		)
	return (
		(mode == Trick.JokerMode.JOKER_WINS or mode == Trick.JokerMode.NORMAL_CARD_WINS)
		and declared_suit == -1
		and forced_card_rank == Trick.ForcedCardRank.NONE
	)


func _build_joker_payload(mode: Trick.JokerMode, declared_suit: int, forced_card_rank: Trick.ForcedCardRank) -> Dictionary:
	return {
		"card_key": "joker",
		"joker_mode": int(mode),
		"declared_suit": declared_suit,
		"forced_card_rank": int(forced_card_rank)
	}


func _ensure_leading_test_player_has_joker() -> bool:
	if match_host == null:
		return false

	var game: Game = match_host.game
	var leader_index := game.current_round.lead_player_index
	if leader_index < 0 or leader_index >= game.players.size():
		return false
	var leader: Player = game.players[leader_index]
	for card in leader.hand:
		if card.is_joker:
			return true

	var replacement: Card
	for card in leader.hand:
		if not card.is_joker:
			replacement = card
			break
	if replacement == null:
		return false

	for source_player in game.players:
		for source_card in source_player.hand:
			if not source_card.is_joker:
				continue
			if not leader.remove_card(replacement) or not source_player.remove_card(source_card):
				return false
			leader.receive_card(source_card)
			source_player.receive_card(replacement)
			return true

	for deck_card_index in game.deck.cards.size():
		var deck_card: Card = game.deck.cards[deck_card_index]
		if not deck_card.is_joker:
			continue
		if not leader.remove_card(replacement):
			return false
		game.deck.cards.remove_at(deck_card_index)
		game.deck.cards.append(replacement)
		leader.receive_card(deck_card)
		return true
	return false


func _ensure_test_round_has_non_joker_trump() -> bool:
	if match_host == null:
		return false

	var game: Game = match_host.game
	if game.trump_card == null:
		return false
	if not game.trump_card.is_joker:
		return true

	for deck_card_index in game.deck.cards.size():
		var replacement: Card = game.deck.cards[deck_card_index]
		if replacement.is_joker:
			continue
		game.deck.cards[deck_card_index] = game.trump_card
		game.trump_card = replacement
		game.current_round.set_trump(Round.trump_from_card(replacement))
		return true
	return false


func _ensure_response_test_player_has_joker() -> bool:
	if match_host == null:
		return false

	var game: Game = match_host.game
	var leader_index := game.current_round.lead_player_index
	if leader_index < 0 or leader_index >= game.players.size():
		return false
	var responder_index := (leader_index + 1) % game.players.size()
	var responder: Player = game.players[responder_index]
	var responder_has_joker := false
	for card in responder.hand:
		if card.is_joker:
			responder_has_joker = true
			break

	if not responder_has_joker:
		var replacement: Card
		for card in responder.hand:
			if not card.is_joker:
				replacement = card
				break
		if replacement == null or not _move_joker_to_response_player(responder, replacement):
			return false

	# После обычного захода ответный Джокер допустим, только если у владельца
	# Джокера нет обычной карты масти захода. Оставляем у него одну обычную
	# карту и гарантируем, что у первого игрока не будет этой масти для захода.
	var responder_normal_card: Card
	for card in responder.hand:
		if not card.is_joker:
			responder_normal_card = card
			break
	if responder_normal_card == null:
		return false
	if responder_normal_card.suit == game.current_round.trump:
		return true

	var leader: Player = game.players[leader_index]
	for leader_card_variant in leader.hand.duplicate():
		var leader_card: Card = leader_card_variant
		if leader_card.is_joker or leader_card.suit != responder_normal_card.suit:
			continue
		for deck_card_index in game.deck.cards.size():
			var deck_card: Card = game.deck.cards[deck_card_index]
			if deck_card.is_joker or deck_card.suit == responder_normal_card.suit:
				continue
			if not leader.remove_card(leader_card):
				return false
			game.deck.cards.remove_at(deck_card_index)
			game.deck.cards.append(leader_card)
			leader.receive_card(deck_card)
			break

	for leader_card in leader.hand:
		if not leader_card.is_joker and leader_card.suit == responder_normal_card.suit:
			return false
	return true


func _move_joker_to_response_player(response_player: Player, replacement: Card) -> bool:
	var game: Game = match_host.game
	for source_player in game.players:
		for source_card in source_player.hand:
			if not source_card.is_joker:
				continue
			if not response_player.remove_card(replacement) or not source_player.remove_card(source_card):
				return false
			response_player.receive_card(source_card)
			source_player.receive_card(replacement)
			return true

	for deck_card_index in game.deck.cards.size():
		var deck_card: Card = game.deck.cards[deck_card_index]
		if not deck_card.is_joker:
			continue
		if not response_player.remove_card(replacement):
			return false
		game.deck.cards.remove_at(deck_card_index)
		game.deck.cards.append(replacement)
		response_player.receive_card(deck_card)
		return true
	return false


func _serialized_hand_has_suit(private_hand: Array, suit: int) -> bool:
	for hand_card_variant in private_hand:
		if not (hand_card_variant is Dictionary):
			continue
		var hand_card: Dictionary = hand_card_variant
		if not bool(hand_card.get("is_joker", false)) and int(hand_card.get("suit", -1)) == suit:
			return true
	return false


func _get_card_key(card: Card) -> String:
	if card.is_joker:
		return "joker"
	return "%d_%d" % [card.suit, card.rank]


func _get_card_name(card: Card) -> String:
	return card.get_card_name()


func _get_host_public_trick_text() -> String:
	if match_host == null:
		return ""
	if match_host.game.active_trick != null:
		return _format_public_trick_cards(match_host.game.active_trick.played_cards, match_host.game.active_trick.played_by, "Текущая взятка")
	if not match_host.game.last_completed_trick_cards.is_empty():
		return _format_public_trick_cards(match_host.game.last_completed_trick_cards, match_host.game.last_completed_trick_played_by, "Последняя взятка")
	return ""


func _get_client_public_trick_text() -> String:
	var active_trick_data: Dictionary = _get_client_active_trick_data()
	if not active_trick_data.is_empty():
		return _format_serialized_public_trick_cards(
			active_trick_data.get("played_cards", []),
			active_trick_data.get("played_by", []),
			"Текущая взятка"
		)

	var last_completed_data: Variant = client_snapshot.get("last_completed_trick", {})
	if last_completed_data is Dictionary:
		return _format_serialized_public_trick_cards(
			last_completed_data.get("cards", []),
			last_completed_data.get("played_by", []),
			"Последняя взятка"
		)
	return ""


func _format_public_trick_cards(cards: Array[Card], played_by: Array[int], title: String) -> String:
	if cards.is_empty():
		return ""
	var entries: Array[String] = []
	for card_index in cards.size():
		var player_index := played_by[card_index] if card_index < played_by.size() else -1
		entries.append("место %d — %s" % [player_index + 1, _get_card_name(cards[card_index])])
	return "%s: %s." % [title, "; ".join(entries)]


func _format_serialized_public_trick_cards(cards_data: Variant, played_by_data: Variant, title: String) -> String:
	if not (cards_data is Array) or cards_data.is_empty():
		return ""
	var entries: Array[String] = []
	for card_index in cards_data.size():
		var card_variant: Variant = cards_data[card_index]
		if not (card_variant is Dictionary):
			continue
		var player_index := -1
		if played_by_data is Array and card_index < played_by_data.size():
			player_index = int(played_by_data[card_index])
		entries.append("место %d — %s" % [player_index + 1, _get_serialized_card_name(card_variant)])
	if entries.is_empty():
		return ""
	return "%s: %s." % [title, "; ".join(entries)]


func _queue_player_snapshots_for_delivery() -> void:
	if match_host == null:
		return

	_snapshot_acknowledged_by_player.clear()
	_snapshot_delivery_queue.clear()
	_snapshot_delivery_elapsed_seconds = SNAPSHOT_DELIVERY_INTERVAL_SECONDS
	_snapshot_retry_elapsed_seconds = 0.0
	# Публичные события (эмоции, подарки и саундпад) не меняют игровую
	# ревизию. Поэтому их нельзя оставлять ждать следующего хода или новой
	# ревизии: отправляем актуальный снимок сразу, а очередь сохраняем только
	# как страховку на случай неудачной отправки.
	for player_index_variant in _confirmed_client_peers_by_player:
		_send_player_snapshot(int(player_index_variant))


func _process_snapshot_delivery(delta: float) -> void:
	if not lobby_round_started or match_host == null:
		return

	_snapshot_delivery_elapsed_seconds += delta
	if not _snapshot_delivery_queue.is_empty() and _snapshot_delivery_elapsed_seconds >= SNAPSHOT_DELIVERY_INTERVAL_SECONDS:
		var player_index: int = int(_snapshot_delivery_queue.pop_front())
		_snapshot_delivery_elapsed_seconds = 0.0
		_send_player_snapshot(player_index)

	# В Steam-режиме часть мест может быть занята локальными ботами, а игрок
	# может временно переподключаться. Ждём подтверждений только от реально
	# подключённых клиентских мест, а не от фиксированных трёх сетевых окон.
	if _snapshot_acknowledged_by_player.size() >= _confirmed_client_peers_by_player.size():
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


func _broadcast_latest_public_table_event() -> void:
	if match_host == null or match_host.public_table_events.is_empty():
		return
	var latest_event: Dictionary = match_host.public_table_events.back().duplicate(true)
	for player_index_variant in _confirmed_client_peers_by_player:
		var player_index := int(player_index_variant)
		var client_peer_id := int(_confirmed_client_peers_by_player[player_index])
		_send_message({
			"type": "public_table_event",
			"event": latest_event
		}, client_peer_id)


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
	var roll_state := _create_first_turn_roll_state()
	for player_index_variant in _connected_client_peers_by_player:
		var player_index := int(player_index_variant)
		var client_peer_id := int(_connected_client_peers_by_player[player_index])
		_send_message({
			"type": "lobby_state",
			"lobby_seats": lobby_seats,
			"round_started": lobby_round_started,
			"first_turn_roll": roll_state
		}, client_peer_id)


func _rebuild_host_lobby_seats() -> void:
	lobby_seats.clear()
	for player_index in PLAYER_COUNT:
		var is_host_player := player_index == HOST_PLAYER_INDEX
		var is_assigned := is_host_player or _connected_client_peers_by_player.has(player_index)
		var is_confirmed := is_host_player or _confirmed_client_peers_by_player.has(player_index)
		var fallback_name := "Хост" if is_host_player else "Игрок %d" % (player_index + 1)
		var display_name: String = (
			match_host.game.players[player_index].display_name
			if match_host != null and player_index < match_host.game.players.size()
			else fallback_name
		)
		lobby_seats.append({
			"player_index": player_index,
			"display_name": display_name,
			"is_host": is_host_player,
			"assigned": is_assigned,
			"confirmed": is_confirmed,
			"avatar_index": int(_avatar_index_by_player.get(player_index, 0)),
			"avatar_data": str(_avatar_data_by_player.get(player_index, ""))
		})


func _store_lobby_seats(seat_data: Variant) -> void:
	lobby_seats.clear()
	if not (seat_data is Array):
		return
	for seat_variant in seat_data:
		if seat_variant is Dictionary:
			lobby_seats.append(seat_variant.duplicate(true))


func _store_first_turn_roll_state(state_data: Variant) -> void:
	first_turn_roll_state.clear()
	if state_data is Dictionary:
		first_turn_roll_state = state_data.duplicate(true)


func _create_first_turn_roll_state() -> Dictionary:
	if first_turn_roll_phase == FirstTurnRollPhase.INACTIVE:
		return {}
	var visible_values: Array[int] = []
	visible_values.resize(PLAYER_COUNT)
	visible_values.fill(-1)
	if first_turn_roll_phase == FirstTurnRollPhase.REVEAL or first_turn_roll_phase == FirstTurnRollPhase.COMPLETE:
		visible_values.assign(first_turn_roll_values)
	return {
		"phase": first_turn_roll_phase,
		"roll_round": first_turn_roll_round,
		"contenders": first_turn_roll_contenders.duplicate(),
		"submitted": first_turn_roll_submitted.duplicate(),
		"values": visible_values,
		"winner_player_index": first_turn_roll_winner_index
	}


func _start_first_turn_roll_round(contenders: Array) -> void:
	first_turn_roll_round += 1
	first_turn_roll_phase = FirstTurnRollPhase.WAITING
	first_turn_roll_contenders.clear()
	for contender_variant in contenders:
		first_turn_roll_contenders.append(int(contender_variant))
	first_turn_roll_submitted.resize(PLAYER_COUNT)
	first_turn_roll_submitted.fill(false)
	first_turn_roll_values.resize(PLAYER_COUNT)
	first_turn_roll_values.fill(-1)
	_first_turn_roll_reveal_seconds_remaining = 0.0

	for automatic_player_index in _get_automatic_first_turn_roll_player_indices():
		if first_turn_roll_contenders.has(automatic_player_index):
			_record_first_turn_roll(automatic_player_index, false)
	_broadcast_lobby_state()
	_set_status(_get_host_lobby_status())


func _get_automatic_first_turn_roll_player_indices() -> Array[int]:
	return []


func _record_first_turn_roll(player_index: int, broadcast_update: bool = true) -> bool:
	if (
		not is_host()
		or first_turn_roll_phase != FirstTurnRollPhase.WAITING
		or not first_turn_roll_contenders.has(player_index)
		or first_turn_roll_submitted[player_index]
	):
		return false

	first_turn_roll_submitted[player_index] = true
	first_turn_roll_values[player_index] = _first_turn_roll_random.randi_range(1, 6)
	if _all_first_turn_roll_contenders_submitted():
		_reveal_first_turn_roll()
	if broadcast_update:
		_broadcast_lobby_state()
		_set_status(_get_host_lobby_status())
	return true


func _all_first_turn_roll_contenders_submitted() -> bool:
	for player_index in first_turn_roll_contenders:
		if not first_turn_roll_submitted[player_index]:
			return false
	return true


func _reveal_first_turn_roll() -> void:
	var highest_value := -1
	var leaders: Array[int] = []
	for player_index in first_turn_roll_contenders:
		var roll_value := first_turn_roll_values[player_index]
		if roll_value > highest_value:
			highest_value = roll_value
			leaders.assign([player_index])
		elif roll_value == highest_value:
			leaders.append(player_index)

	if leaders.size() == 1:
		first_turn_roll_winner_index = leaders[0]
		first_turn_roll_phase = FirstTurnRollPhase.COMPLETE
		if match_host != null and not match_host.game.players.is_empty():
			match_host.game.dealer_index = posmod(first_turn_roll_winner_index - 1, match_host.game.players.size())
		return

	first_turn_roll_contenders.assign(leaders)
	first_turn_roll_phase = FirstTurnRollPhase.REVEAL
	_first_turn_roll_reveal_seconds_remaining = FIRST_TURN_ROLL_REVEAL_SECONDS


func _process_first_turn_roll(delta: float) -> void:
	if not is_host() or first_turn_roll_phase != FirstTurnRollPhase.REVEAL:
		return
	_first_turn_roll_reveal_seconds_remaining = maxf(0.0, _first_turn_roll_reveal_seconds_remaining - delta)
	if _first_turn_roll_reveal_seconds_remaining > 0.0:
		return
	_start_first_turn_roll_round(first_turn_roll_contenders.duplicate())


func _store_client_snapshot(snapshot_data: Variant) -> bool:
	if not (snapshot_data is Dictionary) or client_player_index < FIRST_CLIENT_PLAYER_INDEX:
		return false

	client_snapshot = snapshot_data.duplicate(true)
	client_snapshot_is_safe = NetworkSnapshot.is_player_snapshot_safe(client_snapshot, client_player_index)
	var private_hand: Array = client_snapshot.get("private_hand", [])
	client_private_hand_size = private_hand.size()
	return true


func _get_client_round_data() -> Dictionary:
	var round_data: Variant = client_snapshot.get("round", {})
	if round_data is Dictionary:
		return round_data
	return {}


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
		if _is_host_test_round_finished():
			lines.append("Тестовая раздача завершена.")
			lines.append_array(_get_host_test_round_result_lines())
		else:
			lines.append("Тестовая раздача начата: руки подтвердили %d из %d клиентов." % [_snapshot_acknowledged_by_player.size(), PLAYER_COUNT - 1])
			var public_trick_text := _get_host_public_trick_text()
			if not public_trick_text.is_empty():
				lines.append(public_trick_text)
	elif is_first_turn_roll_complete():
		lines.append("Первый ход разыгран. Можно начинать первую раздачу.")
	elif is_first_turn_roll_active():
		if first_turn_roll_phase == FirstTurnRollPhase.REVEAL:
			lines.append("У лидеров ничья. Готовим переброс.")
		else:
			var submitted_count := 0
			for player_index in first_turn_roll_contenders:
				if first_turn_roll_submitted[player_index]:
					submitted_count += 1
			lines.append("Розыгрыш первого хода: бросили %d из %d участников." % [submitted_count, first_turn_roll_contenders.size()])
	elif is_lobby_full():
		lines.append("Все четыре места готовы. Можно разыграть первый ход.")
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
		var round_data: Dictionary = _get_client_round_data()
		var round_state := int(round_data.get("state", Round.State.SETUP))
		var current_player_index := int(round_data.get("current_player_index", -1))
		if round_state == Round.State.FINISHED:
			lines.append("Тестовая раздача завершена. Твоя закрытая рука: %d карт." % client_private_hand_size)
			lines.append_array(_get_client_test_round_result_lines())
		elif round_state == Round.State.BIDDING:
			lines.append("Тестовая раздача начата. Твоя закрытая рука: %d карт." % client_private_hand_size)
			if current_player_index == client_player_index:
				lines.append("Твой тестовый заказ: выбери число взяток ниже.")
			else:
				lines.append("Сейчас заказывает место %d." % (current_player_index + 1))
		elif round_state == Round.State.PLAYING:
			lines.append("Тестовая раздача начата. Твоя закрытая рука: %d карт." % client_private_hand_size)
			var current_playing_player_index := _get_client_current_playing_player_index()
			if current_playing_player_index == client_player_index:
				if can_submit_test_card():
					lines.append("Твой тестовый ход: выбери допустимую обычную карту ниже.")
				else:
					lines.append("Твой ход Джокером: выбери масть и условие ниже.")
			else:
				lines.append("Сейчас ходит место %d." % (current_playing_player_index + 1))
			var public_trick_text := _get_client_public_trick_text()
			if not public_trick_text.is_empty():
				lines.append(public_trick_text)
		lines.append("Подтверждение руки хосту: %s." % ("отправлено" if client_snapshot_acknowledged else "не отправилось"))
		if not client_last_command_message.is_empty():
			lines.append(client_last_command_message)
	elif is_first_turn_roll_complete():
		lines.append("Первый ход разыгран. Ждём запуска первой раздачи хостом.")
	elif is_first_turn_roll_active():
		var state := get_first_turn_roll_state()
		var phase := int(state.get("phase", FirstTurnRollPhase.WAITING))
		if phase == FirstTurnRollPhase.REVEAL:
			lines.append("У лидеров ничья. Готовим переброс.")
		elif can_submit_first_turn_roll():
			lines.append("Розыгрыш первого хода: брось свой кубик на игровом столе.")
		else:
			lines.append("Твой кубик брошен. Ждём остальных участников.")
	else:
		lines.append("Ждём, пока хост соберёт четыре места и запустит розыгрыш первого хода.")
	return "\n".join(lines)


func _is_host_test_round_finished() -> bool:
	return (
		match_host != null
		and match_host.game.current_round != null
		and match_host.game.current_round.state == Round.State.FINISHED
	)


func _get_host_test_round_result_lines() -> Array[String]:
	var result_lines: Array[String] = []
	if match_host == null:
		return result_lines
	for player in match_host.game.players:
		result_lines.append("%s: заказ %d, взято %d, счёт %d" % [player.display_name, player.bid, player.tricks_taken, player.total_score])
	return result_lines


func _get_client_test_round_result_lines() -> Array[String]:
	var result_lines: Array[String] = []
	var public_players_data: Variant = client_snapshot.get("players", [])
	if not (public_players_data is Array):
		return result_lines
	for player_index in public_players_data.size():
		var player_data_variant = public_players_data[player_index]
		if not (player_data_variant is Dictionary):
			continue
		var player_data: Dictionary = player_data_variant
		result_lines.append("Место %d: заказ %d, взято %d, счёт %d" % [
			player_index + 1,
			int(player_data.get("bid", -1)),
			int(player_data.get("tricks_taken", 0)),
			int(player_data.get("total_score", 0))
		])
	return result_lines


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
