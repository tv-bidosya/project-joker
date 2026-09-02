class_name WebSocketGameServer

extends RefCounted


signal status_changed(status: String)

const PROTOCOL_VERSION := 2
const PLAYER_COUNT := 4
const DEFAULT_PORT := 8765
const MAX_PACKET_BYTES := 65536
const MAX_CLIENTS := 256
const MAX_ROOMS := 100
const TOTAL_ROUND_COUNT := 32
const NEXT_ROUND_DELAY_MSEC := 8000
const EMPTY_MATCH_TTL_MSEC := 6 * 60 * 60 * 1000
const MatchHost = preload("res://Scripts/core/LocalMatchHost.gd")
const MatchCommand = preload("res://Scripts/core/MatchCommand.gd")

var peer: ENetMultiplayerPeer
var active_port := DEFAULT_PORT
var status := "Сервер не запущен."
var _rooms: Dictionary = {}
var _room_id_by_peer: Dictionary = {}
var _room_id_by_session_token: Dictionary = {}
var _known_peer_ids: Dictionary = {}
var _next_room_id := 1001


func start(port: int = DEFAULT_PORT, bind_address: String = "*") -> Error:
	stop()
	active_port = port
	peer = ENetMultiplayerPeer.new()
	peer.set_bind_ip(bind_address)
	var result := peer.create_server(active_port, MAX_CLIENTS)
	if result != OK:
		peer = null
		_set_status("Не удалось открыть ENet-порт %d: %s" % [active_port, error_string(result)])
		return result
	peer.peer_disconnected.connect(_on_peer_disconnected)
	_set_status("Project Joker ENet v%d слушает %s:%d" % [PROTOCOL_VERSION, bind_address, active_port])
	return OK


func stop() -> void:
	if peer != null:
		peer.close()
	peer = null
	_rooms.clear()
	_room_id_by_peer.clear()
	_room_id_by_session_token.clear()
	_known_peer_ids.clear()


func poll() -> void:
	if peer == null:
		return
	peer.poll()
	while peer != null and peer.get_available_packet_count() > 0:
		var sender_peer_id := peer.get_packet_peer()
		var packet := peer.get_packet()
		_known_peer_ids[sender_peer_id] = true
		if packet.size() > MAX_PACKET_BYTES:
			_send(sender_peer_id, {"type": "error", "reason": "packet_too_large"})
			continue
		var parsed: Variant = JSON.parse_string(packet.get_string_from_utf8())
		if parsed is Dictionary:
			_handle_message(sender_peer_id, parsed)
	_process_rooms()


func is_running() -> bool:
	return peer != null


func get_health() -> Dictionary:
	var players_connected := 0
	var players_confirmed := 0
	var matches_running := 0
	for room_variant in _rooms.values():
		var room: Dictionary = room_variant
		players_connected += (room.get("player_by_peer", {}) as Dictionary).size()
		players_confirmed += (room.get("confirmed_players", {}) as Dictionary).size()
		if bool(room.get("round_started", false)):
			matches_running += 1
	return {
		"service": "project-joker",
		"protocol_version": PROTOCOL_VERSION,
		"port": active_port,
		"rooms": _rooms.size(),
		"players_connected": players_connected,
		"players_confirmed": players_confirmed,
		"matches_running": matches_running
	}


func get_room_count() -> int:
	return _rooms.size()


func get_room_summaries() -> Array[Dictionary]:
	return _create_room_summaries()


func get_room_debug_state(room_id: int) -> Dictionary:
	if not _rooms.has(room_id):
		return {}
	var room: Dictionary = _rooms[room_id]
	var match_host: LocalMatchHost = room.get("match_host")
	return {
		"room_id": room_id,
		"round_started": bool(room.get("round_started", false)),
		"revision": match_host.revision if match_host != null else -1,
		"connected": (room.get("player_by_peer", {}) as Dictionary).size(),
		"confirmed": (room.get("confirmed_players", {}) as Dictionary).size(),
		"round_number": match_host.game.round_number if match_host != null else 0
	}


func _handle_message(sender_peer_id: int, message: Dictionary) -> void:
	match str(message.get("type", "")):
		"ping":
			_send(sender_peer_id, {"type": "pong", "health": get_health()})
		"directory_request":
			_handle_directory_request(sender_peer_id, message)
		"create_lobby":
			_handle_create_lobby(sender_peer_id, message)
		"join_lobby":
			_handle_join_lobby(sender_peer_id, message)
		"leave_lobby":
			_leave_current_room(sender_peer_id, true)
		"seat_ack":
			_handle_seat_ack(sender_peer_id, message)
		"match_command":
			_handle_match_command(sender_peer_id, message)
		"resync_request":
			_send_player_snapshot_for_peer(sender_peer_id)
		_:
			_send(sender_peer_id, {"type": "error", "reason": "unknown_message"})


func _handle_directory_request(sender_peer_id: int, message: Dictionary) -> void:
	if int(message.get("protocol_version", -1)) != PROTOCOL_VERSION:
		_send(sender_peer_id, {
			"type": "directory_rejected",
			"reason": "protocol_version_mismatch",
			"protocol_version": PROTOCOL_VERSION
		})
		return
	_send_directory_state(sender_peer_id)


func _handle_create_lobby(sender_peer_id: int, message: Dictionary) -> void:
	if not _validate_protocol(sender_peer_id, message):
		return
	if _rooms.size() >= MAX_ROOMS:
		_reject_room_action(sender_peer_id, "room_limit_reached")
		return
	_leave_current_room(sender_peer_id, false)
	var room_name := _sanitize_room_name(str(message.get("room_name", "")))
	if room_name.is_empty():
		room_name = "Стол %d" % _next_room_id
	var is_private := bool(message.get("is_private", false))
	var password_hash := _sanitize_password_hash(str(message.get("password_hash", "")))
	if is_private and password_hash.is_empty():
		_reject_room_action(sender_peer_id, "password_required")
		return
	var display_name := _sanitize_display_name(str(message.get("display_name", "")))
	var room_id := _next_room_id
	_next_room_id += 1
	var game_state := Game.new(["Игрок 1", "Игрок 2", "Игрок 3", "Игрок 4"])
	game_state.dealer_index = 0
	var room := {
		"room_id": room_id,
		"room_name": room_name,
		"is_private": is_private,
		"password_hash": password_hash,
		"owner_player_index": 0,
		"created_msec": Time.get_ticks_msec(),
		"last_active_msec": Time.get_ticks_msec(),
		"match_host": MatchHost.new(game_state),
		"round_started": false,
		"next_round_at_msec": 0,
		"peer_by_player": {},
		"player_by_peer": {},
		"confirmed_players": {},
		"session_token_by_player": {},
		"player_by_session_token": {}
	}
	_rooms[room_id] = room
	if not _join_peer_to_room(sender_peer_id, room, display_name, "", 0):
		_rooms.erase(room_id)
		_reject_room_action(sender_peer_id, "room_create_failed")
		return
	_set_status("Создана комната %d «%s»." % [room_id, room_name])
	_broadcast_directory_state()


func _handle_join_lobby(sender_peer_id: int, message: Dictionary) -> void:
	if not _validate_protocol(sender_peer_id, message):
		return
	var room_id := int(message.get("room_id", 0))
	var session_token := str(message.get("session_token", "")).strip_edges()
	if room_id <= 0 and not session_token.is_empty():
		room_id = int(_room_id_by_session_token.get(session_token, 0))
	if not _rooms.has(room_id):
		_reject_room_action(sender_peer_id, "room_not_found")
		return
	var room: Dictionary = _rooms[room_id]
	var token_is_valid := (
		not session_token.is_empty()
		and int(_room_id_by_session_token.get(session_token, 0)) == room_id
		and (room.get("player_by_session_token", {}) as Dictionary).has(session_token)
	)
	if bool(room.get("is_private", false)) and not token_is_valid:
		var supplied_hash := _sanitize_password_hash(str(message.get("password_hash", "")))
		if supplied_hash.is_empty() or supplied_hash != str(room.get("password_hash", "")):
			_reject_room_action(sender_peer_id, "wrong_password")
			return
	if bool(room.get("round_started", false)) and not token_is_valid:
		_reject_room_action(sender_peer_id, "match_in_progress")
		return
	_leave_current_room(sender_peer_id, false)
	var display_name := _sanitize_display_name(str(message.get("display_name", "")))
	if not _join_peer_to_room(sender_peer_id, room, display_name, session_token, int(message.get("requested_player_index", -1))):
		_reject_room_action(sender_peer_id, "table_full")
		return
	_set_status("Игрок подключился к комнате %d." % room_id)
	_broadcast_directory_state()


func _join_peer_to_room(sender_peer_id: int, room: Dictionary, display_name: String, session_token: String, requested_player_index: int) -> bool:
	var room_id := int(room.get("room_id", 0))
	var peer_by_player: Dictionary = room.get("peer_by_player", {})
	var player_by_peer: Dictionary = room.get("player_by_peer", {})
	var token_by_player: Dictionary = room.get("session_token_by_player", {})
	var player_by_token: Dictionary = room.get("player_by_session_token", {})
	var player_index := -1
	if not session_token.is_empty() and player_by_token.has(session_token):
		player_index = int(player_by_token[session_token])
		var previous_peer_id := int(peer_by_player.get(player_index, 0))
		if previous_peer_id > 0 and previous_peer_id != sender_peer_id:
			peer.disconnect_peer(previous_peer_id)
			player_by_peer.erase(previous_peer_id)
			_room_id_by_peer.erase(previous_peer_id)
	elif not bool(room.get("round_started", false)):
		player_index = _find_available_player_index(room, requested_player_index)
		if player_index >= 0:
			session_token = _create_session_token()
			token_by_player[player_index] = session_token
			player_by_token[session_token] = player_index
			_room_id_by_session_token[session_token] = room_id
	if player_index < 0:
		return false
	peer_by_player[player_index] = sender_peer_id
	player_by_peer[sender_peer_id] = player_index
	(room.get("confirmed_players", {}) as Dictionary).erase(player_index)
	_room_id_by_peer[sender_peer_id] = room_id
	room["last_active_msec"] = Time.get_ticks_msec()
	var match_host: LocalMatchHost = room.get("match_host")
	if not display_name.is_empty() and match_host != null:
		match_host.game.players[player_index].display_name = display_name
	_send_seat_assigned(sender_peer_id, room, player_index)
	_broadcast_room_state(room)
	return true


func _handle_seat_ack(sender_peer_id: int, message: Dictionary) -> void:
	var room := _get_room_for_peer(sender_peer_id)
	if room.is_empty():
		return
	var player_by_peer: Dictionary = room.get("player_by_peer", {})
	var player_index := int(player_by_peer.get(sender_peer_id, -1))
	if player_index < 0 or int(message.get("player_index", -1)) != player_index:
		return
	var confirmed: Dictionary = room.get("confirmed_players", {})
	confirmed[player_index] = true
	room["last_active_msec"] = Time.get_ticks_msec()
	_send(sender_peer_id, {
		"type": "seat_confirmed",
		"room_id": int(room.get("room_id", 0)),
		"player_index": player_index,
		"round_started": bool(room.get("round_started", false)),
		"lobby_seats": _create_lobby_seats(room)
	})
	_broadcast_room_state(room)
	if not bool(room.get("round_started", false)) and confirmed.size() == PLAYER_COUNT:
		_start_first_round(room)
	elif bool(room.get("round_started", false)):
		_send_player_snapshot(room, player_index)
	_broadcast_directory_state()


func _handle_match_command(sender_peer_id: int, message: Dictionary) -> void:
	var room := _get_room_for_peer(sender_peer_id)
	if room.is_empty():
		_send(sender_peer_id, {"type": "command_result", "accepted": false, "reason": "not_in_room"})
		return
	var player_index := int((room.get("player_by_peer", {}) as Dictionary).get(sender_peer_id, -1))
	if player_index < 0 or not (room.get("confirmed_players", {}) as Dictionary).has(player_index) or not bool(room.get("round_started", false)):
		_send(sender_peer_id, {"type": "command_result", "accepted": false, "reason": "seat_not_ready"})
		return
	var command_data: Variant = message.get("command", {})
	if not (command_data is Dictionary):
		_send(sender_peer_id, {"type": "command_result", "accepted": false, "reason": "invalid_command"})
		return
	var payload_data: Variant = command_data.get("payload", {})
	if not (payload_data is Dictionary):
		_send(sender_peer_id, {"type": "command_result", "accepted": false, "reason": "invalid_payload"})
		return
	var match_host: LocalMatchHost = room.get("match_host")
	var command := MatchCommand.new(
		int(command_data.get("type", MatchCommand.Type.INVALID)),
		player_index,
		int(command_data.get("round_number", -1)),
		int(command_data.get("revision", -1)),
		payload_data
	)
	var result: Dictionary = match_host.apply_command(command)
	room["last_active_msec"] = Time.get_ticks_msec()
	_send(sender_peer_id, {
		"type": "command_result",
		"accepted": bool(result.get("accepted", false)),
		"reason": str(result.get("reason", "unknown")),
		"revision": match_host.revision
	})
	if bool(result.get("accepted", false)):
		_broadcast_player_snapshots(room)
		if match_host.game.current_round != null and match_host.game.current_round.state == Round.State.FINISHED:
			room["next_round_at_msec"] = Time.get_ticks_msec() + NEXT_ROUND_DELAY_MSEC


func _start_first_round(room: Dictionary) -> void:
	var match_host: LocalMatchHost = room.get("match_host")
	var plan := _get_scheduled_round_plan(1)
	if match_host == null or not match_host.game.start_round(
		int(plan.get("cards_per_player", 1)),
		int(plan.get("round_type", Round.RoundType.NORMAL)),
		int(plan.get("trump", Round.TrumpSuit.RANDOM)),
		bool(plan.get("deal_cards_immediately", true))
	):
		_set_status("Не удалось начать первую раздачу комнаты %d." % int(room.get("room_id", 0)))
		return
	match_host.record_current_round_started()
	room["round_started"] = true
	room["next_round_at_msec"] = 0
	room["last_active_msec"] = Time.get_ticks_msec()
	_broadcast_room_state(room)
	_broadcast_player_snapshots(room)
	_broadcast_directory_state()
	_set_status("Комната %d заполнена: начата первая раздача." % int(room.get("room_id", 0)))


func _start_next_round(room: Dictionary) -> bool:
	var match_host: LocalMatchHost = room.get("match_host")
	if match_host == null or match_host.game.current_round == null or match_host.game.current_round.state != Round.State.FINISHED:
		return false
	var next_round_number := match_host.game.round_number + 1
	var plan := _get_scheduled_round_plan(next_round_number)
	if plan.is_empty():
		room["next_round_at_msec"] = 0
		_broadcast_directory_state()
		return false
	if not match_host.start_next_round(
		int(plan.get("cards_per_player", 0)),
		int(plan.get("round_type", Round.RoundType.NORMAL)),
		int(plan.get("trump", Round.TrumpSuit.RANDOM)),
		bool(plan.get("deal_cards_immediately", true))
	):
		return false
	match_host.record_current_round_started()
	room["next_round_at_msec"] = 0
	room["last_active_msec"] = Time.get_ticks_msec()
	_broadcast_room_state(room)
	_broadcast_player_snapshots(room)
	return true


func _process_rooms() -> void:
	var now := Time.get_ticks_msec()
	var rooms_to_remove: Array[int] = []
	for room_id_variant in _rooms.keys():
		var room_id := int(room_id_variant)
		var room: Dictionary = _rooms[room_id]
		var player_by_peer: Dictionary = room.get("player_by_peer", {})
		if player_by_peer.is_empty() and not bool(room.get("round_started", false)):
			rooms_to_remove.append(room_id)
			continue
		if player_by_peer.is_empty() and now - int(room.get("last_active_msec", now)) >= EMPTY_MATCH_TTL_MSEC:
			rooms_to_remove.append(room_id)
			continue
		var next_round_at := int(room.get("next_round_at_msec", 0))
		if next_round_at > 0 and now >= next_round_at and player_by_peer.size() == PLAYER_COUNT:
			_start_next_round(room)
	for room_id in rooms_to_remove:
		_remove_room(room_id)


func _leave_current_room(sender_peer_id: int, notify_client: bool) -> void:
	var room_id := int(_room_id_by_peer.get(sender_peer_id, 0))
	if room_id <= 0 or not _rooms.has(room_id):
		if notify_client:
			_send(sender_peer_id, {"type": "left_lobby"})
			_send_directory_state(sender_peer_id)
		return
	var room: Dictionary = _rooms[room_id]
	var player_by_peer: Dictionary = room.get("player_by_peer", {})
	var player_index := int(player_by_peer.get(sender_peer_id, -1))
	player_by_peer.erase(sender_peer_id)
	_room_id_by_peer.erase(sender_peer_id)
	if player_index >= 0:
		(room.get("peer_by_player", {}) as Dictionary).erase(player_index)
		(room.get("confirmed_players", {}) as Dictionary).erase(player_index)
		if not bool(room.get("round_started", false)):
			var token_by_player: Dictionary = room.get("session_token_by_player", {})
			var player_by_token: Dictionary = room.get("player_by_session_token", {})
			var token := str(token_by_player.get(player_index, ""))
			token_by_player.erase(player_index)
			player_by_token.erase(token)
			_room_id_by_session_token.erase(token)
	room["last_active_msec"] = Time.get_ticks_msec()
	if notify_client:
		_send(sender_peer_id, {"type": "left_lobby"})
		_send_directory_state(sender_peer_id)
	if player_by_peer.is_empty() and not bool(room.get("round_started", false)):
		_remove_room(room_id)
	else:
		_broadcast_room_state(room)
	_broadcast_directory_state()


func _remove_room(room_id: int) -> void:
	if not _rooms.has(room_id):
		return
	var room: Dictionary = _rooms[room_id]
	for token_variant in (room.get("player_by_session_token", {}) as Dictionary).keys():
		_room_id_by_session_token.erase(str(token_variant))
	for peer_id_variant in (room.get("player_by_peer", {}) as Dictionary).keys():
		_room_id_by_peer.erase(int(peer_id_variant))
	_rooms.erase(room_id)
	_broadcast_directory_state()


func _send_seat_assigned(target_peer_id: int, room: Dictionary, player_index: int) -> void:
	var match_host: LocalMatchHost = room.get("match_host")
	_send(target_peer_id, {
		"type": "seat_assigned",
		"protocol_version": PROTOCOL_VERSION,
		"room_id": int(room.get("room_id", 0)),
		"room_name": str(room.get("room_name", "")),
		"is_private": bool(room.get("is_private", false)),
		"player_index": player_index,
		"session_token": str((room.get("session_token_by_player", {}) as Dictionary).get(player_index, "")),
		"round_started": bool(room.get("round_started", false)),
		"round_number": match_host.game.round_number if match_host != null else 0,
		"lobby_seats": _create_lobby_seats(room)
	})


func _broadcast_room_state(room: Dictionary) -> void:
	var match_host: LocalMatchHost = room.get("match_host")
	_broadcast_to_room(room, {
		"type": "lobby_state",
		"room_id": int(room.get("room_id", 0)),
		"room_name": str(room.get("room_name", "")),
		"is_private": bool(room.get("is_private", false)),
		"round_started": bool(room.get("round_started", false)),
		"round_number": match_host.game.round_number if match_host != null else 0,
		"lobby_seats": _create_lobby_seats(room)
	})


func _broadcast_player_snapshots(room: Dictionary) -> void:
	for player_index_variant in (room.get("peer_by_player", {}) as Dictionary).keys():
		_send_player_snapshot(room, int(player_index_variant))


func _send_player_snapshot_for_peer(target_peer_id: int) -> void:
	var room := _get_room_for_peer(target_peer_id)
	if room.is_empty():
		return
	var player_index := int((room.get("player_by_peer", {}) as Dictionary).get(target_peer_id, -1))
	if player_index >= 0:
		_send_player_snapshot(room, player_index)


func _send_player_snapshot(room: Dictionary, player_index: int) -> void:
	var match_host: LocalMatchHost = room.get("match_host")
	var peer_by_player: Dictionary = room.get("peer_by_player", {})
	if match_host == null or not peer_by_player.has(player_index):
		return
	_send(int(peer_by_player[player_index]), {
		"type": "player_snapshot",
		"room_id": int(room.get("room_id", 0)),
		"snapshot": match_host.create_player_snapshot(player_index)
	})


func _send_directory_state(target_peer_id: int) -> void:
	_send(target_peer_id, {
		"type": "directory_state",
		"protocol_version": PROTOCOL_VERSION,
		"lobbies": _create_room_summaries(),
		"current_room_id": int(_room_id_by_peer.get(target_peer_id, 0))
	})


func _broadcast_directory_state() -> void:
	for peer_id_variant in _known_peer_ids.keys():
		var peer_id := int(peer_id_variant)
		if peer_id > 1:
			_send_directory_state(peer_id)


func _create_room_summaries() -> Array[Dictionary]:
	var summaries: Array[Dictionary] = []
	var room_ids: Array = _rooms.keys()
	room_ids.sort()
	for room_id_variant in room_ids:
		var room: Dictionary = _rooms[int(room_id_variant)]
		var match_host: LocalMatchHost = room.get("match_host")
		var player_by_peer: Dictionary = room.get("player_by_peer", {})
		var token_by_player: Dictionary = room.get("session_token_by_player", {})
		var owner_name := ""
		if match_host != null:
			owner_name = match_host.game.players[int(room.get("owner_player_index", 0))].display_name
		var state := "waiting"
		if bool(room.get("round_started", false)):
			state = "finished" if match_host.game.round_number >= TOTAL_ROUND_COUNT and match_host.game.current_round.state == Round.State.FINISHED else "playing"
		summaries.append({
			"room_id": int(room.get("room_id", 0)),
			"room_name": str(room.get("room_name", "")),
			"is_private": bool(room.get("is_private", false)),
			"state": state,
			"host_name": owner_name,
			"member_count": token_by_player.size(),
			"connected_count": player_by_peer.size(),
			"member_limit": PLAYER_COUNT,
			"round_number": match_host.game.round_number if match_host != null else 0
		})
	return summaries


func _create_lobby_seats(room: Dictionary) -> Array[Dictionary]:
	var seats: Array[Dictionary] = []
	var match_host: LocalMatchHost = room.get("match_host")
	var peer_by_player: Dictionary = room.get("peer_by_player", {})
	var confirmed: Dictionary = room.get("confirmed_players", {})
	var token_by_player: Dictionary = room.get("session_token_by_player", {})
	for player_index in PLAYER_COUNT:
		seats.append({
			"player_index": player_index,
			"display_name": match_host.game.players[player_index].display_name,
			"connected": peer_by_player.has(player_index),
			"confirmed": confirmed.has(player_index),
			"reserved_for_reconnect": bool(room.get("round_started", false)) and token_by_player.has(player_index) and not peer_by_player.has(player_index)
		})
	return seats


func _broadcast_to_room(room: Dictionary, message: Dictionary) -> void:
	for target_peer_id_variant in (room.get("player_by_peer", {}) as Dictionary).keys():
		_send(int(target_peer_id_variant), message)


func _send(target_peer_id: int, message: Dictionary) -> bool:
	if peer == null or target_peer_id <= 0:
		return false
	peer.set_target_peer(target_peer_id)
	var result := peer.put_packet(JSON.stringify(message).to_utf8_buffer())
	peer.set_target_peer(0)
	return result == OK


func _get_room_for_peer(peer_id: int) -> Dictionary:
	var room_id := int(_room_id_by_peer.get(peer_id, 0))
	if room_id > 0 and _rooms.has(room_id):
		return _rooms[room_id]
	return {}


func _find_available_player_index(room: Dictionary, requested_player_index: int) -> int:
	var peer_by_player: Dictionary = room.get("peer_by_player", {})
	var token_by_player: Dictionary = room.get("session_token_by_player", {})
	if requested_player_index >= 0 and requested_player_index < PLAYER_COUNT and not peer_by_player.has(requested_player_index) and not token_by_player.has(requested_player_index):
		return requested_player_index
	for player_index in PLAYER_COUNT:
		if not peer_by_player.has(player_index) and not token_by_player.has(player_index):
			return player_index
	return -1


func _get_scheduled_round_plan(round_number: int) -> Dictionary:
	var round_index := round_number - 1
	if round_index < 0 or round_index >= TOTAL_ROUND_COUNT:
		return {}
	if round_index < 13:
		return {
			"cards_per_player": round_index + 1 if round_index < 8 else 9,
			"round_type": Round.RoundType.NORMAL,
			"trump": Round.TrumpSuit.RANDOM if round_index < 8 else _get_fixed_trump(round_index - 8),
			"deal_cards_immediately": true
		}
	round_index -= 13
	if round_index < 5:
		return {
			"cards_per_player": 9,
			"round_type": Round.RoundType.DARK,
			"trump": _get_fixed_trump(round_index),
			"deal_cards_immediately": false
		}
	round_index -= 5
	if round_index < 4:
		return {"cards_per_player": 9, "round_type": Round.RoundType.NO_TRUMP, "trump": Round.TrumpSuit.NONE, "deal_cards_immediately": true}
	round_index -= 4
	if round_index < 5:
		return {"cards_per_player": 9, "round_type": Round.RoundType.GOLDEN, "trump": _get_fixed_trump(round_index), "deal_cards_immediately": true}
	round_index -= 5
	return {"cards_per_player": 9, "round_type": Round.RoundType.MISERE, "trump": _get_fixed_trump(round_index), "deal_cards_immediately": true}


func _get_fixed_trump(round_index: int) -> Round.TrumpSuit:
	match round_index:
		0:
			return Round.TrumpSuit.CLUBS
		1:
			return Round.TrumpSuit.SPADES
		2:
			return Round.TrumpSuit.HEARTS
		3:
			return Round.TrumpSuit.DIAMONDS
	return Round.TrumpSuit.NONE


func _validate_protocol(target_peer_id: int, message: Dictionary) -> bool:
	if int(message.get("protocol_version", -1)) == PROTOCOL_VERSION:
		return true
	_reject_room_action(target_peer_id, "protocol_version_mismatch")
	return false


func _reject_room_action(target_peer_id: int, reason: String) -> void:
	_send(target_peer_id, {"type": "lobby_rejected", "reason": reason})


func _sanitize_display_name(value: String) -> String:
	return value.replace("\n", " ").replace("\r", " ").strip_edges().left(20)


func _sanitize_room_name(value: String) -> String:
	return value.replace("\n", " ").replace("\r", " ").strip_edges().left(28)


func _sanitize_password_hash(value: String) -> String:
	var cleaned := value.strip_edges().to_lower()
	if cleaned.length() != 64:
		return ""
	for character in cleaned:
		if character not in "0123456789abcdef":
			return ""
	return cleaned


func _create_session_token() -> String:
	return Crypto.new().generate_random_bytes(16).hex_encode()


func _on_peer_disconnected(peer_id: int) -> void:
	_known_peer_ids.erase(peer_id)
	_leave_current_room(peer_id, false)


func _set_status(new_status: String) -> void:
	if status == new_status:
		return
	status = new_status
	print("[ProjectJokerServer] ", status)
	status_changed.emit(status)
