class_name WebSocketGameServer

extends RefCounted


signal status_changed(status: String)

const PROTOCOL_VERSION := 7
const PLAYER_COUNT := 4
const DEFAULT_PORT := 8765
const MAX_PACKET_BYTES := 65536
const MAX_CLIENTS := 256
const MAX_ROOMS := 100
const TOTAL_ROUND_COUNT := 32
const NEXT_ROUND_DELAY_MSEC := 8000
const BOT_ACTION_DELAY_MSEC := 650
const CASUAL_RECONNECT_GRACE_SECONDS := 5 * 60
const RANKED_RECONNECT_GRACE_SECONDS := 3 * 24 * 60 * 60
const SERVER_RESTART_RECONNECT_GRACE_MSEC := 5 * 60 * 1000
const FIRST_TURN_ROLL_REVEAL_MSEC := 2400
const FIRST_ROUND_AUTO_START_MSEC := 3200
const MATCH_MODE_CLASSIC := "classic"
const MATCH_MODE_TEAMS_2V2 := "teams_2v2"
const GAME_TYPE_CASUAL := "casual"
const GAME_TYPE_RANKED := "ranked"
const BOT_NAMES := ["Rhysand", "Azriel", "Cassian"]
const EMPTY_MATCH_TTL_MSEC := 6 * 60 * 60 * 1000
const MATCH_BASE_XP := 100
const MATCH_WIN_XP := 20
const BOT_MATCH_XP_MULTIPLIER := 0.5
const ABANDONED_CASUAL_EARLY_XP_MULTIPLIER := 0.05
const ABANDONED_CASUAL_HALF_XP_MULTIPLIER := 0.3
const RATING_K_FACTOR := 24.0
const RATING_FORFEIT_MULTIPLIER := 1.5
const RATING_FORFEIT_MIN_LOSS := 20
const RATING_FORFEIT_MAX_LOSS := 45
const MatchHost = preload("res://Scripts/core/LocalMatchHost.gd")
const MatchCommand = preload("res://Scripts/core/MatchCommand.gd")
const ServerBotTurn = preload("res://Scripts/server/ServerBotTurn.gd")
const AccountStoreResource = preload("res://Scripts/server/AccountStore.gd")
const MatchStoreResource = preload("res://Scripts/server/MatchStore.gd")

var peer: ENetMultiplayerPeer
var active_port := DEFAULT_PORT
var status := "Сервер не запущен."
var _rooms: Dictionary = {}
var _room_id_by_peer: Dictionary = {}
var _room_id_by_session_token: Dictionary = {}
var _room_id_by_account_id: Dictionary = {}
var _known_peer_ids: Dictionary = {}
var _account_id_by_peer: Dictionary = {}
var _account_recovery_attempts_by_peer: Dictionary = {}
var _account_challenge_by_peer: Dictionary = {}
var _next_room_id := 1001
var _account_store
var _match_store
var _completed_matches: Array[Dictionary] = []
var _is_stopping := false


enum FirstTurnRollPhase {
	INACTIVE,
	WAITING,
	REVEAL,
	COMPLETE
}


func start(port: int = DEFAULT_PORT, bind_address: String = "*", account_database_path: String = "", match_database_path: String = "") -> Error:
	stop()
	_account_store = AccountStoreResource.new()
	var account_error: Error = _account_store.open(account_database_path)
	if account_error != OK:
		_set_status("Не удалось открыть базу аккаунтов: %s" % _account_store.last_error)
		_account_store = null
		return account_error
	_match_store = MatchStoreResource.new()
	var match_error: Error = _match_store.open(match_database_path)
	if match_error != OK:
		_set_status("Не удалось открыть базу матчей: %s" % _match_store.last_error)
		_match_store = null
		_account_store = null
		return match_error
	_restore_persistent_rooms()
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
	_is_stopping = true
	_persist_rooms()
	if peer != null:
		peer.close()
	peer = null
	_rooms.clear()
	_room_id_by_peer.clear()
	_room_id_by_session_token.clear()
	_room_id_by_account_id.clear()
	_known_peer_ids.clear()
	_account_id_by_peer.clear()
	_account_recovery_attempts_by_peer.clear()
	_account_challenge_by_peer.clear()
	_account_store = null
	_match_store = null
	_completed_matches.clear()
	_is_stopping = false


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
		"matches_running": matches_running,
		"accounts": _account_store.get_account_count() if _account_store != null else 0,
		"completed_matches_saved": _completed_matches.size()
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
		"round_number": match_host.game.round_number if match_host != null else 0,
		"first_turn_roll_phase": int(room.get("first_turn_roll_phase", FirstTurnRollPhase.INACTIVE)),
		"first_turn_roll_winner_index": int(room.get("first_turn_roll_winner_index", -1)),
		"match_finished": _is_match_finished(room),
		"game_type": str(room.get("game_type", GAME_TYPE_CASUAL))
	}


func _handle_message(sender_peer_id: int, message: Dictionary) -> void:
	match str(message.get("type", "")):
		"ping":
			_send(sender_peer_id, {"type": "pong", "health": get_health()})
		"account_challenge_request":
			_handle_account_challenge_request(sender_peer_id, message)
		"account_create":
			_handle_account_create(sender_peer_id, message)
		"account_login":
			_handle_account_login(sender_peer_id, message)
		"account_recover":
			_handle_account_recover(sender_peer_id, message)
		"account_update":
			_handle_account_update(sender_peer_id, message)
		"account_rotate_recovery":
			_handle_account_rotate_recovery(sender_peer_id, message)
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
		"set_ready":
			_handle_set_ready(sender_peer_id, message)
		"update_room_settings":
			_handle_update_room_settings(sender_peer_id, message)
		"start_match":
			_handle_start_match(sender_peer_id)
		"first_turn_roll":
			_handle_first_turn_roll(sender_peer_id, message)
		"start_first_round":
			_handle_start_first_round(sender_peer_id)
		"return_to_lobby":
			_handle_return_to_lobby(sender_peer_id)
		"match_command":
			_handle_match_command(sender_peer_id, message)
		"resync_request":
			_handle_resync_request(sender_peer_id)
		_:
			_send(sender_peer_id, {"type": "error", "reason": "unknown_message"})


func _handle_account_challenge_request(sender_peer_id: int, message: Dictionary) -> void:
	if not _validate_account_protocol(sender_peer_id, message):
		return
	var challenge := Crypto.new().generate_random_bytes(32).hex_encode()
	_account_challenge_by_peer[sender_peer_id] = challenge
	_send(sender_peer_id, {
		"type": "account_challenge",
		"protocol_version": PROTOCOL_VERSION,
		"challenge": challenge
	})


func _handle_account_create(sender_peer_id: int, message: Dictionary) -> void:
	if not _validate_account_protocol(sender_peer_id, message):
		return
	if _take_account_challenge(sender_peer_id).is_empty():
		_send(sender_peer_id, {"type": "account_rejected", "reason": "account_challenge_required"})
		return
	var result: Dictionary = _account_store.create_account_from_verifiers(
		str(message.get("display_name", "Игрок")),
		int(message.get("avatar_index", 0)),
		str(message.get("device_token_hash", "")),
		str(message.get("recovery_code_hash", ""))
	)
	if not bool(result.get("ok", false)):
		_send(sender_peer_id, {"type": "account_rejected", "reason": str(result.get("error", "account_create_failed"))})
		return
	_authenticate_account_peer(sender_peer_id, result, true)


func _handle_account_login(sender_peer_id: int, message: Dictionary) -> void:
	if not _validate_account_protocol(sender_peer_id, message):
		return
	var challenge := _take_account_challenge(sender_peer_id)
	if challenge.is_empty():
		_send(sender_peer_id, {"type": "account_rejected", "reason": "account_challenge_required"})
		return
	var result: Dictionary = _account_store.authenticate_device_proof(
		str(message.get("account_id", "")),
		challenge,
		str(message.get("proof", ""))
	)
	if not bool(result.get("ok", false)):
		_send(sender_peer_id, {"type": "account_rejected", "reason": str(result.get("error", "account_login_failed"))})
		return
	_authenticate_account_peer(sender_peer_id, result, false)


func _handle_account_recover(sender_peer_id: int, message: Dictionary) -> void:
	if not _validate_account_protocol(sender_peer_id, message):
		return
	var attempt_count := int(_account_recovery_attempts_by_peer.get(sender_peer_id, 0)) + 1
	_account_recovery_attempts_by_peer[sender_peer_id] = attempt_count
	if attempt_count > 5:
		_send(sender_peer_id, {"type": "account_rejected", "reason": "recovery_rate_limited"})
		return
	var challenge := _take_account_challenge(sender_peer_id)
	if challenge.is_empty():
		_send(sender_peer_id, {"type": "account_rejected", "reason": "account_challenge_required"})
		return
	var result: Dictionary = _account_store.recover_account_with_proof(
		str(message.get("account_id", "")),
		challenge,
		str(message.get("proof", "")),
		str(message.get("device_token_hash", ""))
	)
	if not bool(result.get("ok", false)):
		_send(sender_peer_id, {"type": "account_rejected", "reason": str(result.get("error", "account_recovery_failed"))})
		return
	_account_recovery_attempts_by_peer.erase(sender_peer_id)
	_authenticate_account_peer(sender_peer_id, result, false)


func _handle_account_update(sender_peer_id: int, message: Dictionary) -> void:
	var account_id := str(_account_id_by_peer.get(sender_peer_id, ""))
	if account_id.is_empty():
		_send(sender_peer_id, {"type": "account_rejected", "reason": "account_required"})
		return
	var result: Dictionary = _account_store.update_profile(
		account_id,
		str(message.get("display_name", "Игрок")),
		int(message.get("avatar_index", 0))
	)
	if not bool(result.get("ok", false)):
		_send(sender_peer_id, {"type": "account_rejected", "reason": str(result.get("error", "account_update_failed"))})
		return
	_authenticate_account_peer(sender_peer_id, result, false)


func _handle_account_rotate_recovery(sender_peer_id: int, message: Dictionary) -> void:
	var account_id := str(_account_id_by_peer.get(sender_peer_id, ""))
	if account_id.is_empty():
		_send(sender_peer_id, {"type": "account_rejected", "reason": "account_required"})
		return
	var result: Dictionary = _account_store.set_recovery_code_hash(account_id, str(message.get("recovery_code_hash", "")))
	if not bool(result.get("ok", false)):
		_send(sender_peer_id, {"type": "account_rejected", "reason": str(result.get("error", "recovery_rotation_failed"))})
		return
	_authenticate_account_peer(sender_peer_id, result, false)


func _authenticate_account_peer(sender_peer_id: int, result: Dictionary, account_created: bool) -> void:
	var account: Dictionary = result.get("account", {})
	var account_id := str(account.get("account_id", ""))
	if account_id.is_empty():
		_send(sender_peer_id, {"type": "account_rejected", "reason": "account_state_invalid"})
		return
	_account_id_by_peer[sender_peer_id] = account_id
	var response := {
		"type": "account_state",
		"protocol_version": PROTOCOL_VERSION,
		"account": account,
		"created": account_created,
		"active_room_id": int(_room_id_by_account_id.get(account_id, 0))
	}
	var device_token := str(result.get("device_token", ""))
	if not device_token.is_empty():
		response["device_token"] = device_token
	var recovery_code := str(result.get("recovery_code", ""))
	if not recovery_code.is_empty():
		response["recovery_code"] = recovery_code
	_send(sender_peer_id, response)


func _handle_directory_request(sender_peer_id: int, message: Dictionary) -> void:
	if int(message.get("protocol_version", -1)) != PROTOCOL_VERSION:
		_send(sender_peer_id, {
			"type": "directory_rejected",
			"reason": "protocol_version_mismatch",
			"protocol_version": PROTOCOL_VERSION
		})
		return
	if not _account_id_by_peer.has(sender_peer_id):
		_send(sender_peer_id, {"type": "account_rejected", "reason": "account_required"})
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
	var game_type := _sanitize_game_type(str(message.get("game_type", GAME_TYPE_CASUAL)))
	var password_hash := _sanitize_password_hash(str(message.get("password_hash", "")))
	if is_private and password_hash.is_empty():
		_reject_room_action(sender_peer_id, "password_required")
		return
	var display_name := _get_authenticated_display_name(sender_peer_id)
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
		"match_mode": _sanitize_match_mode(str(message.get("match_mode", MATCH_MODE_CLASSIC))),
		"game_type": game_type,
		"fill_empty_seats_with_bots": bool(message.get("fill_empty_seats_with_bots", false)) if game_type == GAME_TYPE_CASUAL else false,
		"bot_difficulty": clampi(int(message.get("bot_difficulty", 1)), 0, 2),
		"bot_players": {},
		"temporary_bot_players": {},
		"abandoned_at_round_by_player": {},
		"forfeited_players": {},
		"reconnecting_since_msec": {},
		"reconnect_deadline_unix_by_player": {},
		"bot_action_at_msec": 0,
		"created_msec": Time.get_ticks_msec(),
		"created_unix": int(Time.get_unix_time_from_system()),
		"last_active_msec": Time.get_ticks_msec(),
		"match_host": MatchHost.new(game_state),
		"round_started": false,
		"next_round_at_msec": 0,
		"first_round_at_msec": 0,
		"first_turn_roll_phase": FirstTurnRollPhase.INACTIVE,
		"first_turn_roll_round": 0,
		"first_turn_roll_contenders": [],
		"first_turn_roll_submitted": [false, false, false, false],
		"first_turn_roll_values": [-1, -1, -1, -1],
		"first_turn_roll_winner_index": -1,
		"first_turn_roll_reveal_at_msec": 0,
		"peer_by_player": {},
		"player_by_peer": {},
		"confirmed_players": {},
		"session_token_by_player": {},
		"player_by_session_token": {},
		"account_id_by_player": {},
		"player_by_account_id": {},
		"match_id": "",
		"completion_recorded": false
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
	var account_id := str(_account_id_by_peer.get(sender_peer_id, ""))
	var account_is_member := not account_id.is_empty() and (room.get("player_by_account_id", {}) as Dictionary).has(account_id)
	var returning_player_index := int((room.get("player_by_account_id", {}) as Dictionary).get(account_id, -1)) if account_is_member else int((room.get("player_by_session_token", {}) as Dictionary).get(session_token, -1))
	if bool(room.get("round_started", false)) and returning_player_index >= 0 and (room.get("forfeited_players", {}) as Dictionary).has(returning_player_index):
		_reject_room_action(sender_peer_id, "ranked_forfeit")
		return
	if bool(room.get("is_private", false)) and not token_is_valid and not account_is_member:
		var supplied_hash := _sanitize_password_hash(str(message.get("password_hash", "")))
		if supplied_hash.is_empty() or supplied_hash != str(room.get("password_hash", "")):
			_reject_room_action(sender_peer_id, "wrong_password")
			return
	if bool(room.get("round_started", false)) and not token_is_valid and not account_is_member:
		_reject_room_action(sender_peer_id, "match_in_progress")
		return
	_leave_current_room(sender_peer_id, false)
	var display_name := _get_authenticated_display_name(sender_peer_id)
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
	var account_by_player: Dictionary = room.get("account_id_by_player", {})
	var player_by_account: Dictionary = room.get("player_by_account_id", {})
	var account_id := str(_account_id_by_peer.get(sender_peer_id, ""))
	var player_index := -1
	if not account_id.is_empty() and player_by_account.has(account_id):
		player_index = int(player_by_account[account_id])
		session_token = str(token_by_player.get(player_index, session_token))
		var previous_peer_id := int(peer_by_player.get(player_index, 0))
		if previous_peer_id > 0 and previous_peer_id != sender_peer_id:
			peer.disconnect_peer(previous_peer_id)
			player_by_peer.erase(previous_peer_id)
			_room_id_by_peer.erase(previous_peer_id)
	elif not session_token.is_empty() and player_by_token.has(session_token):
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
	if player_index >= 0 and not account_id.is_empty():
		account_by_player[player_index] = account_id
		player_by_account[account_id] = player_index
		_room_id_by_account_id[account_id] = room_id
	if player_index < 0:
		return false
	peer_by_player[player_index] = sender_peer_id
	player_by_peer[sender_peer_id] = player_index
	if bool(room.get("round_started", false)):
		(room.get("reconnecting_since_msec", {}) as Dictionary).erase(player_index)
		(room.get("reconnect_deadline_unix_by_player", {}) as Dictionary).erase(player_index)
		(room.get("abandoned_at_round_by_player", {}) as Dictionary).erase(player_index)
		if (room.get("temporary_bot_players", {}) as Dictionary).has(player_index):
			(room.get("temporary_bot_players", {}) as Dictionary).erase(player_index)
			(room.get("bot_players", {}) as Dictionary).erase(player_index)
	else:
		(room.get("confirmed_players", {}) as Dictionary).erase(player_index)
	_room_id_by_peer[sender_peer_id] = room_id
	room["last_active_msec"] = Time.get_ticks_msec()
	var match_host: LocalMatchHost = room.get("match_host")
	if not display_name.is_empty() and match_host != null:
		match_host.game.players[player_index].display_name = display_name
	_send_seat_assigned(sender_peer_id, room, player_index)
	_broadcast_room_state(room)
	if _has_started_round(room):
		_broadcast_player_snapshots(room)
	return true


func _handle_seat_ack(sender_peer_id: int, message: Dictionary) -> void:
	var room := _get_room_for_peer(sender_peer_id)
	if room.is_empty():
		return
	var player_by_peer: Dictionary = room.get("player_by_peer", {})
	var player_index := int(player_by_peer.get(sender_peer_id, -1))
	if player_index < 0 or int(message.get("player_index", -1)) != player_index:
		return
	room["last_active_msec"] = Time.get_ticks_msec()
	_send(sender_peer_id, {
		"type": "seat_confirmed",
		"room_id": int(room.get("room_id", 0)),
		"player_index": player_index,
		"round_started": bool(room.get("round_started", false)),
		"first_turn_roll": _create_first_turn_roll_state(room),
		"lobby_seats": _create_lobby_seats(room)
	})
	_broadcast_room_state(room)
	if _has_started_round(room):
		_send_player_snapshot(room, player_index)
	_broadcast_directory_state()


func _handle_set_ready(sender_peer_id: int, message: Dictionary) -> void:
	var room := _get_room_for_peer(sender_peer_id)
	if room.is_empty() or bool(room.get("round_started", false)):
		return
	var player_index := int((room.get("player_by_peer", {}) as Dictionary).get(sender_peer_id, -1))
	if player_index < 0:
		return
	var ready_players: Dictionary = room.get("confirmed_players", {})
	if bool(message.get("ready", false)):
		ready_players[player_index] = true
	else:
		ready_players.erase(player_index)
	room["last_active_msec"] = Time.get_ticks_msec()
	_broadcast_room_state(room)
	_broadcast_directory_state()


func _handle_update_room_settings(sender_peer_id: int, message: Dictionary) -> void:
	var room := _get_room_for_peer(sender_peer_id)
	if room.is_empty() or bool(room.get("round_started", false)):
		return
	var player_index := int((room.get("player_by_peer", {}) as Dictionary).get(sender_peer_id, -1))
	if player_index != int(room.get("owner_player_index", -1)):
		_reject_room_action(sender_peer_id, "host_only")
		return
	room["match_mode"] = _sanitize_match_mode(str(message.get("match_mode", room.get("match_mode", MATCH_MODE_CLASSIC))))
	room["game_type"] = _sanitize_game_type(str(message.get("game_type", room.get("game_type", GAME_TYPE_CASUAL))))
	room["fill_empty_seats_with_bots"] = bool(message.get("fill_empty_seats_with_bots", room.get("fill_empty_seats_with_bots", false))) if str(room["game_type"]) == GAME_TYPE_CASUAL else false
	room["bot_difficulty"] = clampi(int(message.get("bot_difficulty", room.get("bot_difficulty", 1))), 0, 2)
	(room.get("confirmed_players", {}) as Dictionary).clear()
	room["last_active_msec"] = Time.get_ticks_msec()
	_broadcast_room_state(room)
	_broadcast_directory_state()


func _handle_start_match(sender_peer_id: int) -> void:
	var room := _get_room_for_peer(sender_peer_id)
	if room.is_empty() or bool(room.get("round_started", false)):
		return
	var player_index := int((room.get("player_by_peer", {}) as Dictionary).get(sender_peer_id, -1))
	if player_index != int(room.get("owner_player_index", -1)):
		_reject_room_action(sender_peer_id, "host_only")
		return
	var human_players: Dictionary = room.get("session_token_by_player", {})
	var ready_players: Dictionary = room.get("confirmed_players", {})
	for human_player_index_variant in human_players.keys():
		if not ready_players.has(int(human_player_index_variant)):
			_reject_room_action(sender_peer_id, "players_not_ready")
			return
	var fill_with_bots := bool(room.get("fill_empty_seats_with_bots", false))
	if str(room.get("game_type", GAME_TYPE_CASUAL)) == GAME_TYPE_RANKED and human_players.size() < PLAYER_COUNT:
		_reject_room_action(sender_peer_id, "ranked_requires_four_players")
		return
	if human_players.size() < PLAYER_COUNT and not fill_with_bots:
		_reject_room_action(sender_peer_id, "not_enough_players")
		return
	var bot_players: Dictionary = room.get("bot_players", {})
	bot_players.clear()
	if fill_with_bots:
		var match_host: LocalMatchHost = room.get("match_host")
		var bot_number := 0
		for seat_index in PLAYER_COUNT:
			if human_players.has(seat_index):
				continue
			bot_players[seat_index] = true
			ready_players[seat_index] = true
			if match_host != null:
				match_host.game.players[seat_index].display_name = BOT_NAMES[mini(bot_number, BOT_NAMES.size() - 1)]
			bot_number += 1
	_begin_first_turn_roll(room)


func _handle_first_turn_roll(sender_peer_id: int, message: Dictionary) -> void:
	var room := _get_room_for_peer(sender_peer_id)
	if room.is_empty():
		return
	var player_index := int((room.get("player_by_peer", {}) as Dictionary).get(sender_peer_id, -1))
	if int(message.get("roll_round", -1)) != int(room.get("first_turn_roll_round", 0)) or not _record_first_turn_roll(room, player_index):
		_reject_room_action(sender_peer_id, "roll_not_available")


func _handle_start_first_round(sender_peer_id: int) -> void:
	var room := _get_room_for_peer(sender_peer_id)
	if room.is_empty():
		return
	var player_index := int((room.get("player_by_peer", {}) as Dictionary).get(sender_peer_id, -1))
	if player_index != int(room.get("owner_player_index", -1)):
		_reject_room_action(sender_peer_id, "host_only")
		return
	if int(room.get("first_turn_roll_phase", FirstTurnRollPhase.INACTIVE)) != FirstTurnRollPhase.COMPLETE:
		_reject_room_action(sender_peer_id, "roll_not_complete")
		return
	_start_first_round(room)


func _handle_resync_request(sender_peer_id: int) -> void:
	var room := _get_room_for_peer(sender_peer_id)
	if room.is_empty():
		return
	_send(sender_peer_id, _create_room_state_message(room))
	if _has_started_round(room):
		_send_player_snapshot_for_peer(sender_peer_id)


func _handle_return_to_lobby(sender_peer_id: int) -> void:
	var room := _get_room_for_peer(sender_peer_id)
	if room.is_empty():
		return
	var player_index := int((room.get("player_by_peer", {}) as Dictionary).get(sender_peer_id, -1))
	if player_index != int(room.get("owner_player_index", -1)):
		_reject_room_action(sender_peer_id, "host_only")
		return
	if not _is_match_finished(room):
		_reject_room_action(sender_peer_id, "match_not_finished")
		return
	_reset_room_for_rematch(room)


func _handle_match_command(sender_peer_id: int, message: Dictionary) -> void:
	var room := _get_room_for_peer(sender_peer_id)
	if room.is_empty():
		_send(sender_peer_id, {"type": "command_result", "accepted": false, "reason": "not_in_room"})
		return
	var player_index := int((room.get("player_by_peer", {}) as Dictionary).get(sender_peer_id, -1))
	if _is_room_waiting_on_reconnecting_player(room):
		_send(sender_peer_id, {"type": "command_result", "accepted": false, "reason": "player_reconnecting"})
		return
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


func _begin_first_turn_roll(room: Dictionary) -> void:
	room["round_started"] = true
	if str(room.get("match_id", "")).is_empty():
		room["match_id"] = "%d-%d-%s" % [int(Time.get_unix_time_from_system()), int(room.get("room_id", 0)), Crypto.new().generate_random_bytes(6).hex_encode()]
	_reset_first_turn_roll_state(room)
	_start_first_turn_roll_round(room, [0, 1, 2, 3])
	_broadcast_directory_state()


func _start_first_turn_roll_round(room: Dictionary, contenders: Array) -> void:
	room["first_turn_roll_round"] = int(room.get("first_turn_roll_round", 0)) + 1
	room["first_turn_roll_phase"] = FirstTurnRollPhase.WAITING
	room["first_turn_roll_contenders"] = contenders.duplicate()
	room["first_turn_roll_submitted"] = [false, false, false, false]
	room["first_turn_roll_values"] = [-1, -1, -1, -1]
	room["first_turn_roll_reveal_at_msec"] = 0
	for player_index_variant in (room.get("bot_players", {}) as Dictionary).keys():
		var player_index := int(player_index_variant)
		if contenders.has(player_index):
			_record_first_turn_roll(room, player_index, false)
	room["last_active_msec"] = Time.get_ticks_msec()
	_broadcast_room_state(room)


func _record_first_turn_roll(room: Dictionary, player_index: int, broadcast_update: bool = true) -> bool:
	var contenders: Array = room.get("first_turn_roll_contenders", [])
	var submitted: Array = room.get("first_turn_roll_submitted", [])
	var values: Array = room.get("first_turn_roll_values", [])
	if (
		int(room.get("first_turn_roll_phase", FirstTurnRollPhase.INACTIVE)) != FirstTurnRollPhase.WAITING
		or not contenders.has(player_index)
		or player_index < 0
		or player_index >= submitted.size()
		or bool(submitted[player_index])
	):
		return false
	submitted[player_index] = true
	values[player_index] = randi_range(1, 6)
	if _all_first_turn_roll_contenders_submitted(room):
		_reveal_first_turn_roll(room)
	room["last_active_msec"] = Time.get_ticks_msec()
	if broadcast_update:
		_broadcast_room_state(room)
	return true


func _all_first_turn_roll_contenders_submitted(room: Dictionary) -> bool:
	var submitted: Array = room.get("first_turn_roll_submitted", [])
	for player_index_variant in room.get("first_turn_roll_contenders", []):
		var player_index := int(player_index_variant)
		if player_index < 0 or player_index >= submitted.size() or not bool(submitted[player_index]):
			return false
	return true


func _reveal_first_turn_roll(room: Dictionary) -> void:
	var highest_value := -1
	var leaders: Array[int] = []
	var values: Array = room.get("first_turn_roll_values", [])
	for player_index_variant in room.get("first_turn_roll_contenders", []):
		var player_index := int(player_index_variant)
		var roll_value := int(values[player_index])
		if roll_value > highest_value:
			highest_value = roll_value
			leaders.assign([player_index])
		elif roll_value == highest_value:
			leaders.append(player_index)
	if leaders.size() == 1:
		var winner_index := leaders[0]
		room["first_turn_roll_winner_index"] = winner_index
		room["first_turn_roll_phase"] = FirstTurnRollPhase.COMPLETE
		room["first_round_at_msec"] = Time.get_ticks_msec() + FIRST_ROUND_AUTO_START_MSEC
		var match_host: LocalMatchHost = room.get("match_host")
		if match_host != null:
			match_host.game.dealer_index = posmod(winner_index - 1, PLAYER_COUNT)
		return
	room["first_turn_roll_contenders"] = leaders
	room["first_turn_roll_phase"] = FirstTurnRollPhase.REVEAL
	room["first_turn_roll_reveal_at_msec"] = Time.get_ticks_msec() + FIRST_TURN_ROLL_REVEAL_MSEC


func _process_first_turn_roll(room: Dictionary, now_msec: int) -> void:
	var phase := int(room.get("first_turn_roll_phase", FirstTurnRollPhase.INACTIVE))
	if phase == FirstTurnRollPhase.REVEAL and now_msec >= int(room.get("first_turn_roll_reveal_at_msec", 0)):
		_start_first_turn_roll_round(room, (room.get("first_turn_roll_contenders", []) as Array).duplicate())
	elif phase == FirstTurnRollPhase.COMPLETE and int(room.get("first_round_at_msec", 0)) > 0 and now_msec >= int(room.get("first_round_at_msec", 0)):
		_start_first_round(room)


func _create_first_turn_roll_state(room: Dictionary) -> Dictionary:
	var phase := int(room.get("first_turn_roll_phase", FirstTurnRollPhase.INACTIVE))
	if phase == FirstTurnRollPhase.INACTIVE:
		return {}
	var visible_values := [-1, -1, -1, -1]
	if phase == FirstTurnRollPhase.REVEAL or phase == FirstTurnRollPhase.COMPLETE:
		visible_values = (room.get("first_turn_roll_values", []) as Array).duplicate()
	return {
		"phase": phase,
		"roll_round": int(room.get("first_turn_roll_round", 0)),
		"contenders": (room.get("first_turn_roll_contenders", []) as Array).duplicate(),
		"submitted": (room.get("first_turn_roll_submitted", []) as Array).duplicate(),
		"values": visible_values,
		"winner_player_index": int(room.get("first_turn_roll_winner_index", -1))
	}


func _reset_first_turn_roll_state(room: Dictionary) -> void:
	room["first_round_at_msec"] = 0
	room["first_turn_roll_phase"] = FirstTurnRollPhase.INACTIVE
	room["first_turn_roll_round"] = 0
	room["first_turn_roll_contenders"] = []
	room["first_turn_roll_submitted"] = [false, false, false, false]
	room["first_turn_roll_values"] = [-1, -1, -1, -1]
	room["first_turn_roll_winner_index"] = -1
	room["first_turn_roll_reveal_at_msec"] = 0

func _start_first_round(room: Dictionary) -> void:
	var match_host: LocalMatchHost = room.get("match_host")
	if match_host == null or match_host.game.round_number > 0 or int(room.get("first_turn_roll_phase", FirstTurnRollPhase.INACTIVE)) != FirstTurnRollPhase.COMPLETE:
		return
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
	room["first_round_at_msec"] = 0
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
	room["first_round_at_msec"] = 0
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
		var empty_match_ttl := (RANKED_RECONNECT_GRACE_SECONDS * 1000 + EMPTY_MATCH_TTL_MSEC) if str(room.get("game_type", GAME_TYPE_CASUAL)) == GAME_TYPE_RANKED else EMPTY_MATCH_TTL_MSEC
		if player_by_peer.is_empty() and now - int(room.get("last_active_msec", now)) >= empty_match_ttl:
			rooms_to_remove.append(room_id)
			continue
		_process_reconnect_timeouts(room, now)
		_process_first_turn_roll(room, now)
		_process_room_bot(room, now)
		var next_round_at := int(room.get("next_round_at_msec", 0))
		var bot_count := (room.get("bot_players", {}) as Dictionary).size()
		if next_round_at > 0 and now >= next_round_at and player_by_peer.size() + bot_count == PLAYER_COUNT:
			_start_next_round(room)
	for room_id in rooms_to_remove:
		_remove_room(room_id)


func _process_reconnect_timeouts(room: Dictionary, now_msec: int) -> void:
	if not bool(room.get("round_started", false)):
		return
	var reconnecting: Dictionary = room.get("reconnecting_since_msec", {})
	var deadlines: Dictionary = room.get("reconnect_deadline_unix_by_player", {})
	var now_unix := int(Time.get_unix_time_from_system())
	var expired: Array[int] = []
	for player_index_variant in reconnecting.keys():
		var player_index := int(player_index_variant)
		var deadline_unix := int(deadlines.get(player_index, deadlines.get(str(player_index), 0)))
		if deadline_unix <= 0:
			deadline_unix = now_unix + _get_reconnect_grace_seconds(room)
			deadlines[player_index] = deadline_unix
		if now_unix >= deadline_unix:
			expired.append(player_index)
	for player_index in expired:
		reconnecting.erase(player_index)
		deadlines.erase(player_index)
		deadlines.erase(str(player_index))
		(room.get("temporary_bot_players", {}) as Dictionary)[player_index] = true
		(room.get("bot_players", {}) as Dictionary)[player_index] = true
		if str(room.get("game_type", GAME_TYPE_CASUAL)) == GAME_TYPE_RANKED:
			(room.get("forfeited_players", {}) as Dictionary)[player_index] = true
		else:
			var match_host: LocalMatchHost = room.get("match_host")
			var completed_rounds := match_host.completed_round_history.size() if match_host != null else 0
			(room.get("abandoned_at_round_by_player", {}) as Dictionary)[player_index] = completed_rounds
		room["bot_action_at_msec"] = now_msec + BOT_ACTION_DELAY_MSEC
		if int(room.get("first_turn_roll_phase", FirstTurnRollPhase.INACTIVE)) == FirstTurnRollPhase.WAITING:
			_record_first_turn_roll(room, player_index, false)
	if not expired.is_empty():
		room["last_active_msec"] = now_msec
		_broadcast_room_state(room)
		_broadcast_player_snapshots(room)
		_broadcast_directory_state()

func _process_room_bot(room: Dictionary, now_msec: int) -> void:
	if not bool(room.get("round_started", false)):
		return
	var bot_players: Dictionary = room.get("bot_players", {})
	if _is_room_waiting_on_reconnecting_player(room):
		return
	if bot_players.is_empty() or now_msec < int(room.get("bot_action_at_msec", 0)):
		return
	var match_host: LocalMatchHost = room.get("match_host")
	if match_host == null or match_host.game.current_round == null:
		return
	var round: Round = match_host.game.current_round
	var active_player_index := -1
	if round.state == Round.State.BIDDING:
		active_player_index = round.current_player_index
	elif round.state == Round.State.PLAYING:
		active_player_index = match_host.game.active_trick.current_player_index if match_host.game.active_trick != null else round.lead_player_index
	if active_player_index < 0 or not bot_players.has(active_player_index):
		return
	var effective_difficulty := 2 if (room.get("temporary_bot_players", {}) as Dictionary).has(active_player_index) else int(room.get("bot_difficulty", 1))
	var command = ServerBotTurn.create_command(match_host, active_player_index, effective_difficulty)
	if command == null:
		return
	var result: Dictionary = match_host.apply_command(command)
	room["bot_action_at_msec"] = now_msec + BOT_ACTION_DELAY_MSEC
	if not bool(result.get("accepted", false)):
		return
	room["last_active_msec"] = now_msec
	_broadcast_player_snapshots(room)
	if match_host.game.current_round.state == Round.State.FINISHED:
		room["next_round_at_msec"] = now_msec + NEXT_ROUND_DELAY_MSEC


func _is_room_waiting_on_reconnecting_player(room: Dictionary) -> bool:
	var reconnecting: Dictionary = room.get("reconnecting_since_msec", {})
	if reconnecting.is_empty():
		return false
	if int(room.get("first_turn_roll_phase", FirstTurnRollPhase.INACTIVE)) == FirstTurnRollPhase.WAITING:
		for contender_variant in room.get("first_turn_roll_contenders", []):
			if reconnecting.has(int(contender_variant)):
				return true
	var match_host: LocalMatchHost = room.get("match_host")
	if match_host == null or match_host.game.current_round == null:
		return false
	var round: Round = match_host.game.current_round
	return round.state in [Round.State.BIDDING, Round.State.PLAYING] and reconnecting.has(round.current_player_index)

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
		if not bool(room.get("round_started", false)):
			(room.get("confirmed_players", {}) as Dictionary).erase(player_index)
		if bool(room.get("round_started", false)):
			(room.get("reconnecting_since_msec", {}) as Dictionary)[player_index] = Time.get_ticks_msec()
			(room.get("reconnect_deadline_unix_by_player", {}) as Dictionary)[player_index] = int(Time.get_unix_time_from_system()) + _get_reconnect_grace_seconds(room)
		else:
			var token_by_player: Dictionary = room.get("session_token_by_player", {})
			var player_by_token: Dictionary = room.get("player_by_session_token", {})
			var token := str(token_by_player.get(player_index, ""))
			token_by_player.erase(player_index)
			player_by_token.erase(token)
			_room_id_by_session_token.erase(token)
			var account_by_player: Dictionary = room.get("account_id_by_player", {})
			var player_by_account: Dictionary = room.get("player_by_account_id", {})
			var account_id := str(account_by_player.get(player_index, ""))
			account_by_player.erase(player_index)
			player_by_account.erase(account_id)
			_room_id_by_account_id.erase(account_id)
			if player_index == int(room.get("owner_player_index", -1)):
				_assign_room_owner(room)
	room["last_active_msec"] = Time.get_ticks_msec()
	if notify_client:
		_send(sender_peer_id, {"type": "left_lobby"})
		_send_directory_state(sender_peer_id)
	if player_by_peer.is_empty() and not bool(room.get("round_started", false)):
		_remove_room(room_id)
	else:
		_broadcast_room_state(room)
		if _has_started_round(room):
			_broadcast_player_snapshots(room)
	_broadcast_directory_state()


func _has_started_round(room: Dictionary) -> bool:
	var match_host: LocalMatchHost = room.get("match_host")
	return match_host != null and match_host.game.round_number > 0


func _is_match_finished(room: Dictionary) -> bool:
	var match_host: LocalMatchHost = room.get("match_host")
	return (
		match_host != null
		and match_host.game.round_number >= TOTAL_ROUND_COUNT
		and match_host.game.current_round != null
		and match_host.game.current_round.state == Round.State.FINISHED
	)


func _reset_room_for_rematch(room: Dictionary) -> void:
	_record_completed_match_if_needed(room)
	var old_match_host: LocalMatchHost = room.get("match_host")
	var player_names: Array[String] = []
	for player_index in PLAYER_COUNT:
		player_names.append(old_match_host.game.players[player_index].display_name if old_match_host != null else "Игрок %d" % (player_index + 1))
	var token_by_player: Dictionary = room.get("session_token_by_player", {})
	var player_by_token: Dictionary = room.get("player_by_session_token", {})
	var peer_by_player: Dictionary = room.get("peer_by_player", {})
	var account_by_player: Dictionary = room.get("account_id_by_player", {})
	var player_by_account: Dictionary = room.get("player_by_account_id", {})
	for player_index_variant in token_by_player.keys():
		var player_index := int(player_index_variant)
		if peer_by_player.has(player_index):
			continue
		var stale_token := str(token_by_player.get(player_index, ""))
		token_by_player.erase(player_index)
		player_by_token.erase(stale_token)
		_room_id_by_session_token.erase(stale_token)
		var stale_account_id := str(account_by_player.get(player_index, ""))
		account_by_player.erase(player_index)
		player_by_account.erase(stale_account_id)
		_room_id_by_account_id.erase(stale_account_id)
	(room.get("confirmed_players", {}) as Dictionary).clear()
	(room.get("bot_players", {}) as Dictionary).clear()
	(room.get("temporary_bot_players", {}) as Dictionary).clear()
	(room.get("abandoned_at_round_by_player", {}) as Dictionary).clear()
	(room.get("forfeited_players", {}) as Dictionary).clear()
	(room.get("reconnecting_since_msec", {}) as Dictionary).clear()
	(room.get("reconnect_deadline_unix_by_player", {}) as Dictionary).clear()
	room["match_host"] = MatchHost.new(Game.new(player_names))
	room["round_started"] = false
	room["match_id"] = ""
	room["completion_recorded"] = false
	room["next_round_at_msec"] = 0
	room["bot_action_at_msec"] = 0
	room["last_active_msec"] = Time.get_ticks_msec()
	_reset_first_turn_roll_state(room)
	_broadcast_room_state(room)
	_broadcast_directory_state()
	_set_status("Комната %d вернулась в лобби для реванша." % int(room.get("room_id", 0)))

func _remove_room(room_id: int) -> void:
	if not _rooms.has(room_id):
		return
	var room: Dictionary = _rooms[room_id]
	_record_completed_match_if_needed(room)
	for token_variant in (room.get("player_by_session_token", {}) as Dictionary).keys():
		_room_id_by_session_token.erase(str(token_variant))
	for account_id_variant in (room.get("player_by_account_id", {}) as Dictionary).keys():
		_room_id_by_account_id.erase(str(account_id_variant))
	for peer_id_variant in (room.get("player_by_peer", {}) as Dictionary).keys():
		_room_id_by_peer.erase(int(peer_id_variant))
	_rooms.erase(room_id)
	_persist_rooms()
	_broadcast_directory_state()


func _persist_rooms() -> void:
	if _match_store == null:
		return
	var rooms_data: Array[Dictionary] = []
	for room_variant in _rooms.values():
		var room: Dictionary = room_variant
		if not bool(room.get("round_started", false)):
			continue
		_record_completed_match_if_needed(room)
		var serialized := _serialize_persistent_room(room)
		if not serialized.is_empty():
			rooms_data.append(serialized)
	var save_error: Error = _match_store.save(rooms_data, _completed_matches)
	if save_error != OK and not _is_stopping:
		_set_status("Не удалось сохранить матчи: %s" % _match_store.last_error)


func _serialize_persistent_room(room: Dictionary) -> Dictionary:
	var match_host: LocalMatchHost = room.get("match_host")
	if match_host == null:
		return {}
	var members: Array[Dictionary] = []
	var token_by_player: Dictionary = room.get("session_token_by_player", {})
	var account_by_player: Dictionary = room.get("account_id_by_player", {})
	for player_index_variant in token_by_player.keys():
		var player_index := int(player_index_variant)
		members.append({
			"player_index": player_index,
			"session_token": str(token_by_player.get(player_index_variant, "")),
			"account_id": str(account_by_player.get(player_index_variant, account_by_player.get(player_index, "")))
		})
	return {
		"room_id": int(room.get("room_id", 0)),
		"room_name": str(room.get("room_name", "")),
		"is_private": bool(room.get("is_private", false)),
		"password_hash": str(room.get("password_hash", "")),
		"owner_player_index": int(room.get("owner_player_index", 0)),
		"match_mode": str(room.get("match_mode", MATCH_MODE_CLASSIC)),
		"game_type": str(room.get("game_type", GAME_TYPE_CASUAL)),
		"fill_empty_seats_with_bots": bool(room.get("fill_empty_seats_with_bots", false)),
		"bot_difficulty": int(room.get("bot_difficulty", 1)),
		"bot_player_indices": _sorted_player_indices(room.get("bot_players", {})),
		"temporary_bot_player_indices": _sorted_player_indices(room.get("temporary_bot_players", {})),
		"members": members,
		"created_unix": int(room.get("created_unix", Time.get_unix_time_from_system())),
		"match_id": str(room.get("match_id", "")),
		"completion_recorded": bool(room.get("completion_recorded", false)),
		"abandoned_at_round_by_player": (room.get("abandoned_at_round_by_player", {}) as Dictionary).duplicate(),
		"forfeited_players": (room.get("forfeited_players", {}) as Dictionary).duplicate(),
		"reconnect_deadline_unix_by_player": (room.get("reconnect_deadline_unix_by_player", {}) as Dictionary).duplicate(),
		"first_turn_roll_phase": int(room.get("first_turn_roll_phase", FirstTurnRollPhase.INACTIVE)),
		"first_turn_roll_round": int(room.get("first_turn_roll_round", 0)),
		"first_turn_roll_contenders": (room.get("first_turn_roll_contenders", []) as Array).duplicate(),
		"first_turn_roll_submitted": (room.get("first_turn_roll_submitted", []) as Array).duplicate(),
		"first_turn_roll_values": (room.get("first_turn_roll_values", []) as Array).duplicate(),
		"first_turn_roll_winner_index": int(room.get("first_turn_roll_winner_index", -1)),
		"match_host": match_host.create_persistence_snapshot()
	}


func _restore_persistent_rooms() -> void:
	if _match_store == null:
		return
	_completed_matches = _match_store.get_completed_matches()
	var now_msec := Time.get_ticks_msec()
	for room_data_variant in _match_store.get_rooms():
		if not (room_data_variant is Dictionary):
			continue
		var room_data: Dictionary = room_data_variant
		var host_data_variant: Variant = room_data.get("match_host", {})
		if not (host_data_variant is Dictionary):
			continue
		var match_host: LocalMatchHost = MatchHost.restore_persistence_snapshot(host_data_variant)
		var room_id := int(room_data.get("room_id", 0))
		if match_host == null or room_id <= 0 or _rooms.has(room_id):
			continue
		var token_by_player := {}
		var player_by_token := {}
		var account_by_player := {}
		var player_by_account := {}
		var reconnecting := {}
		var reconnect_deadlines := _dictionary_with_integer_keys(room_data.get("reconnect_deadline_unix_by_player", {}))
		var game_type := _sanitize_game_type(str(room_data.get("game_type", GAME_TYPE_CASUAL)))
		var restored_abandoned := _dictionary_with_integer_keys(room_data.get("abandoned_at_round_by_player", {}))
		var restored_forfeited := _dictionary_with_integer_keys(room_data.get("forfeited_players", {}))
		var restored_temporary_bots := {}
		for player_index_variant in room_data.get("temporary_bot_player_indices", []):
			var temporary_index := int(player_index_variant)
			if temporary_index >= 0 and temporary_index < PLAYER_COUNT:
				restored_temporary_bots[temporary_index] = true
		var now_unix := int(Time.get_unix_time_from_system())
		for member_variant in room_data.get("members", []):
			if not (member_variant is Dictionary):
				continue
			var member: Dictionary = member_variant
			var player_index := int(member.get("player_index", -1))
			var session_token := str(member.get("session_token", ""))
			var account_id := str(member.get("account_id", ""))
			if player_index < 0 or player_index >= PLAYER_COUNT or session_token.is_empty():
				continue
			token_by_player[player_index] = session_token
			player_by_token[session_token] = player_index
			_room_id_by_session_token[session_token] = room_id
			if not account_id.is_empty():
				account_by_player[player_index] = account_id
				player_by_account[account_id] = player_index
				_room_id_by_account_id[account_id] = room_id
			if not restored_temporary_bots.has(player_index):
				reconnecting[player_index] = now_msec
				if not reconnect_deadlines.has(player_index):
					reconnect_deadlines[player_index] = now_unix + (RANKED_RECONNECT_GRACE_SECONDS if game_type == GAME_TYPE_RANKED else CASUAL_RECONNECT_GRACE_SECONDS)
			else:
				reconnect_deadlines.erase(player_index)
		var bot_players := {}
		for player_index_variant in room_data.get("bot_player_indices", []):
			var player_index := int(player_index_variant)
			if player_index >= 0 and player_index < PLAYER_COUNT and (not token_by_player.has(player_index) or restored_temporary_bots.has(player_index)):
				bot_players[player_index] = true
		var phase := clampi(int(room_data.get("first_turn_roll_phase", FirstTurnRollPhase.INACTIVE)), FirstTurnRollPhase.INACTIVE, FirstTurnRollPhase.COMPLETE)
		var room := {
			"room_id": room_id,
			"room_name": _sanitize_room_name(str(room_data.get("room_name", "Стол %d" % room_id))),
			"is_private": bool(room_data.get("is_private", false)),
			"password_hash": _sanitize_password_hash(str(room_data.get("password_hash", ""))),
			"owner_player_index": clampi(int(room_data.get("owner_player_index", 0)), 0, PLAYER_COUNT - 1),
			"match_mode": _sanitize_match_mode(str(room_data.get("match_mode", MATCH_MODE_CLASSIC))),
			"game_type": game_type,
			"fill_empty_seats_with_bots": bool(room_data.get("fill_empty_seats_with_bots", false)) if game_type == GAME_TYPE_CASUAL else false,
			"bot_difficulty": clampi(int(room_data.get("bot_difficulty", 1)), 0, 2),
			"bot_players": bot_players,
			"temporary_bot_players": restored_temporary_bots,
			"abandoned_at_round_by_player": restored_abandoned,
			"forfeited_players": restored_forfeited,
			"reconnecting_since_msec": reconnecting,
			"reconnect_deadline_unix_by_player": reconnect_deadlines,
			"bot_action_at_msec": now_msec + BOT_ACTION_DELAY_MSEC,
			"created_msec": now_msec,
			"created_unix": int(room_data.get("created_unix", Time.get_unix_time_from_system())),
			"last_active_msec": now_msec,
			"match_host": match_host,
			"round_started": true,
			"next_round_at_msec": now_msec + NEXT_ROUND_DELAY_MSEC if match_host.game.current_round.state == Round.State.FINISHED and not _is_restored_host_finished(match_host) else 0,
			"first_round_at_msec": now_msec + FIRST_ROUND_AUTO_START_MSEC if phase == FirstTurnRollPhase.COMPLETE and match_host.game.round_number == 0 else 0,
			"first_turn_roll_phase": phase,
			"first_turn_roll_round": maxi(0, int(room_data.get("first_turn_roll_round", 0))),
			"first_turn_roll_contenders": (room_data.get("first_turn_roll_contenders", []) as Array).duplicate(),
			"first_turn_roll_submitted": (room_data.get("first_turn_roll_submitted", [false, false, false, false]) as Array).duplicate(),
			"first_turn_roll_values": (room_data.get("first_turn_roll_values", [-1, -1, -1, -1]) as Array).duplicate(),
			"first_turn_roll_winner_index": int(room_data.get("first_turn_roll_winner_index", -1)),
			"first_turn_roll_reveal_at_msec": now_msec + FIRST_TURN_ROLL_REVEAL_MSEC if phase == FirstTurnRollPhase.REVEAL else 0,
			"peer_by_player": {},
			"player_by_peer": {},
			"confirmed_players": token_by_player.duplicate(),
			"session_token_by_player": token_by_player,
			"player_by_session_token": player_by_token,
			"account_id_by_player": account_by_player,
			"player_by_account_id": player_by_account,
			"match_id": str(room_data.get("match_id", "")),
			"completion_recorded": bool(room_data.get("completion_recorded", false))
		}
		for bot_index_variant in bot_players.keys():
			(room.get("confirmed_players", {}) as Dictionary)[int(bot_index_variant)] = true
		_rooms[room_id] = room
		_next_room_id = maxi(_next_room_id, room_id + 1)
	if not _rooms.is_empty():
		_set_status("Восстановлено сетевых матчей: %d." % _rooms.size())


func _is_restored_host_finished(match_host: LocalMatchHost) -> bool:
	return match_host.game.round_number >= TOTAL_ROUND_COUNT and match_host.game.current_round.state == Round.State.FINISHED


func _record_completed_match_if_needed(room: Dictionary) -> void:
	if bool(room.get("completion_recorded", false)) or not _is_match_finished(room):
		return
	var match_host: LocalMatchHost = room.get("match_host")
	if match_host == null:
		return
	var match_id := str(room.get("match_id", ""))
	if match_id.is_empty():
		match_id = "%d-%d-%s" % [int(Time.get_unix_time_from_system()), int(room.get("room_id", 0)), Crypto.new().generate_random_bytes(6).hex_encode()]
		room["match_id"] = match_id
	var highest_score := -2147483648
	for player in match_host.game.players:
		highest_score = maxi(highest_score, player.total_score)
	var players: Array[Dictionary] = []
	var winners: Array[int] = []
	var account_by_player: Dictionary = room.get("account_id_by_player", {})
	var abandoned_rounds: Dictionary = room.get("abandoned_at_round_by_player", {})
	var forfeited_players: Dictionary = room.get("forfeited_players", {})
	var game_type := str(room.get("game_type", GAME_TYPE_CASUAL))
	var match_started_with_bots := account_by_player.size() < PLAYER_COUNT
	var ratings: Array[int] = []
	for player_index in match_host.game.players.size():
		var rating_account: Dictionary = _account_store.get_public_account(str(account_by_player.get(player_index, ""))) if _account_store != null else {}
		ratings.append(int(rating_account.get("rating", AccountStoreResource.DEFAULT_RATING)))
	for player_index in match_host.game.players.size():
		var player: Player = match_host.game.players[player_index]
		var is_winner := player.total_score == highest_score
		if is_winner:
			winners.append(player_index)
		var exact_tricks := _get_exact_ordered_tricks(match_host, player_index)
		var raw_xp := MATCH_BASE_XP + (MATCH_WIN_XP if is_winner else 0) + exact_tricks
		var abandoned := abandoned_rounds.has(player_index)
		var forfeited := forfeited_players.has(player_index)
		var abandoned_after_half := int(abandoned_rounds.get(player_index, 0)) >= TOTAL_ROUND_COUNT / 2
		var xp_multiplier := _get_match_xp_multiplier(game_type, forfeited, abandoned, abandoned_after_half, match_started_with_bots)
		var xp_awarded := roundi(float(raw_xp) * xp_multiplier)
		var account_id := str(account_by_player.get(player_index, ""))
		var grant_result := {}
		var rating_result := {}
		var rating_delta := _calculate_ranked_rating_delta(room, match_host, player_index, ratings, forfeited) if game_type == GAME_TYPE_RANKED else 0
		var public_account := {}
		if not account_id.is_empty() and _account_store != null:
			grant_result = _account_store.grant_match_xp(account_id, match_id, xp_awarded)
			public_account = grant_result.get("account", {})
			if game_type == GAME_TYPE_RANKED:
				rating_result = _account_store.apply_ranked_match_result(account_id, match_id, rating_delta)
				if bool(rating_result.get("ok", false)):
					public_account = rating_result.get("account", public_account)
			if bool(grant_result.get("ok", false)) and (game_type != GAME_TYPE_RANKED or bool(rating_result.get("ok", false))):
				_send_account_progress(room, player_index, public_account, {
					"match_id": match_id,
					"base_xp": MATCH_BASE_XP,
					"win_xp": MATCH_WIN_XP if is_winner else 0,
					"exact_tricks_xp": exact_tricks,
					"multiplier": xp_multiplier,
					"xp_awarded": int(grant_result.get("xp_awarded", 0)),
					"abandoned": abandoned,
					"forfeited": forfeited,
					"bot_match": match_started_with_bots,
					"game_type": game_type,
					"rating_delta": int(rating_result.get("rating_delta", 0))
				})
		players.append({
			"player_index": player_index,
			"account_id": account_id,
			"display_name": player.display_name,
			"score": player.total_score,
			"exact_orders_completed": player.exact_orders_completed,
			"exact_ordered_tricks": exact_tricks,
			"abandoned": abandoned,
			"forfeited": forfeited,
			"xp_awarded": xp_awarded if bool(grant_result.get("awarded", false)) else 0,
			"rating_delta": rating_delta if bool(rating_result.get("applied", false)) else 0
		})
	_completed_matches.append({
		"match_id": match_id,
		"room_id": int(room.get("room_id", 0)),
		"room_name": str(room.get("room_name", "")),
		"match_mode": str(room.get("match_mode", MATCH_MODE_CLASSIC)),
		"game_type": str(room.get("game_type", GAME_TYPE_CASUAL)),
		"completed_unix": int(Time.get_unix_time_from_system()),
		"players": players,
		"winner_player_indices": winners
	})
	while _completed_matches.size() > MatchStoreResource.MAX_COMPLETED_MATCHES:
		_completed_matches.pop_front()
	room["completion_recorded"] = true


func _calculate_ranked_rating_delta(room: Dictionary, match_host: LocalMatchHost, player_index: int, ratings: Array[int], forfeited: bool) -> int:
	if player_index < 0 or player_index >= ratings.size():
		return 0
	var player_rating := ratings[player_index]
	var opponent_rating_sum := 0.0
	var opponent_count := 0
	for other_index in ratings.size():
		if other_index != player_index:
			opponent_rating_sum += ratings[other_index]
			opponent_count += 1
	var opponent_average := opponent_rating_sum / maxf(1.0, float(opponent_count))
	var expected := _rating_expected_score(player_rating, opponent_average)
	if forfeited:
		var loss := clampi(roundi(RATING_K_FACTOR * expected * RATING_FORFEIT_MULTIPLIER), RATING_FORFEIT_MIN_LOSS, RATING_FORFEIT_MAX_LOSS)
		return -loss
	var actual := 0.0
	if str(room.get("match_mode", MATCH_MODE_CLASSIC)) == MATCH_MODE_TEAMS_2V2:
		var team_id := player_index % 2
		var own_team_score := match_host.game.players[team_id].total_score + match_host.game.players[team_id + 2].total_score
		var other_team_id := 1 - team_id
		var other_team_score := match_host.game.players[other_team_id].total_score + match_host.game.players[other_team_id + 2].total_score
		actual = 1.0 if own_team_score > other_team_score else 0.5 if own_team_score == other_team_score else 0.0
	else:
		var player_score := match_host.game.players[player_index].total_score
		for other_index in match_host.game.players.size():
			if other_index == player_index:
				continue
			var other_score := match_host.game.players[other_index].total_score
			actual += 1.0 if player_score > other_score else 0.5 if player_score == other_score else 0.0
		actual /= maxf(1.0, float(match_host.game.players.size() - 1))
	return roundi(RATING_K_FACTOR * (actual - expected))


func _rating_expected_score(player_rating: int, opponent_rating: float) -> float:
	return 1.0 / (1.0 + pow(10.0, (opponent_rating - float(player_rating)) / 400.0))


func _get_match_xp_multiplier(game_type: String, forfeited: bool, abandoned: bool, abandoned_after_half: bool, match_started_with_bots: bool) -> float:
	if game_type == GAME_TYPE_RANKED and forfeited:
		return 0.0
	if abandoned:
		return ABANDONED_CASUAL_HALF_XP_MULTIPLIER if abandoned_after_half else ABANDONED_CASUAL_EARLY_XP_MULTIPLIER
	return BOT_MATCH_XP_MULTIPLIER if match_started_with_bots else 1.0


func _get_exact_ordered_tricks(match_host: LocalMatchHost, player_index: int) -> int:
	var exact_tricks := 0
	for round_variant in match_host.completed_round_history:
		if not (round_variant is Dictionary):
			continue
		var round_data: Dictionary = round_variant
		if not bool(round_data.get("uses_bids", false)):
			continue
		var player_results: Array = round_data.get("players", [])
		if player_index < 0 or player_index >= player_results.size() or not (player_results[player_index] is Dictionary):
			continue
		var result: Dictionary = player_results[player_index]
		var bid := int(result.get("bid", -1))
		var tricks_taken := int(result.get("tricks_taken", 0))
		if bid >= 0 and bid == tricks_taken:
			exact_tricks += tricks_taken
	return exact_tricks


func _send_account_progress(room: Dictionary, player_index: int, account_variant: Variant, award: Dictionary) -> void:
	if not (account_variant is Dictionary):
		return
	var peer_by_player: Dictionary = room.get("peer_by_player", {})
	if not peer_by_player.has(player_index):
		return
	_send(int(peer_by_player[player_index]), {
		"type": "account_progress",
		"protocol_version": PROTOCOL_VERSION,
		"account": account_variant,
		"award": award
	})


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
		"first_turn_roll": _create_first_turn_roll_state(room),
		"owner_player_index": int(room.get("owner_player_index", 0)),
		"match_mode": str(room.get("match_mode", MATCH_MODE_CLASSIC)),
		"game_type": str(room.get("game_type", GAME_TYPE_CASUAL)),
		"fill_empty_seats_with_bots": bool(room.get("fill_empty_seats_with_bots", false)),
		"bot_difficulty": int(room.get("bot_difficulty", 1)),
		"lobby_seats": _create_lobby_seats(room)
	})


func _broadcast_room_state(room: Dictionary) -> void:
	_persist_rooms()
	_broadcast_to_room(room, _create_room_state_message(room))


func _create_room_state_message(room: Dictionary) -> Dictionary:
	var match_host: LocalMatchHost = room.get("match_host")
	return {
		"type": "lobby_state",
		"room_id": int(room.get("room_id", 0)),
		"room_name": str(room.get("room_name", "")),
		"is_private": bool(room.get("is_private", false)),
		"round_started": bool(room.get("round_started", false)),
		"round_number": match_host.game.round_number if match_host != null else 0,
		"first_turn_roll": _create_first_turn_roll_state(room),
		"owner_player_index": int(room.get("owner_player_index", 0)),
		"match_mode": str(room.get("match_mode", MATCH_MODE_CLASSIC)),
		"game_type": str(room.get("game_type", GAME_TYPE_CASUAL)),
		"fill_empty_seats_with_bots": bool(room.get("fill_empty_seats_with_bots", false)),
		"bot_difficulty": int(room.get("bot_difficulty", 1)),
		"lobby_seats": _create_lobby_seats(room)
	}


func _broadcast_player_snapshots(room: Dictionary) -> void:
	_persist_rooms()
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
	var snapshot := match_host.create_player_snapshot(player_index)
	snapshot["match_mode"] = str(room.get("match_mode", MATCH_MODE_CLASSIC))
	snapshot["game_type"] = str(room.get("game_type", GAME_TYPE_CASUAL))
	snapshot["team_by_player"] = [0, 1, 0, 1] if str(room.get("match_mode", MATCH_MODE_CLASSIC)) == MATCH_MODE_TEAMS_2V2 else []
	snapshot["team_names"] = ["Команда 1", "Команда 2"]
	snapshot["reconnecting_player_indices"] = _sorted_player_indices(room.get("reconnecting_since_msec", {}))
	snapshot["temporary_bot_player_indices"] = _sorted_player_indices(room.get("temporary_bot_players", {}))
	snapshot["forfeited_player_indices"] = _sorted_player_indices(room.get("forfeited_players", {}))
	snapshot["reconnect_deadline_unix_by_player"] = (room.get("reconnect_deadline_unix_by_player", {}) as Dictionary).duplicate()
	_send(int(peer_by_player[player_index]), {
		"type": "player_snapshot",
		"room_id": int(room.get("room_id", 0)),
		"snapshot": snapshot
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
			"round_number": match_host.game.round_number if match_host != null else 0,
			"match_mode": str(room.get("match_mode", MATCH_MODE_CLASSIC)),
			"game_type": str(room.get("game_type", GAME_TYPE_CASUAL)),
			"fill_empty_seats_with_bots": bool(room.get("fill_empty_seats_with_bots", false)),
			"bot_difficulty": int(room.get("bot_difficulty", 1))
		})
	return summaries


func _create_lobby_seats(room: Dictionary) -> Array[Dictionary]:
	var seats: Array[Dictionary] = []
	var match_host: LocalMatchHost = room.get("match_host")
	var peer_by_player: Dictionary = room.get("peer_by_player", {})
	var ready_players: Dictionary = room.get("confirmed_players", {})
	var token_by_player: Dictionary = room.get("session_token_by_player", {})
	var bot_players: Dictionary = room.get("bot_players", {})
	var temporary_bot_players: Dictionary = room.get("temporary_bot_players", {})
	var reconnecting: Dictionary = room.get("reconnecting_since_msec", {})
	var account_by_player: Dictionary = room.get("account_id_by_player", {})
	var show_bot_placeholders := bool(room.get("fill_empty_seats_with_bots", false))
	var bot_number := 0
	for player_index in PLAYER_COUNT:
		var is_bot := bot_players.has(player_index) or (show_bot_placeholders and not token_by_player.has(player_index))
		var display_name := match_host.game.players[player_index].display_name
		if is_bot and not bot_players.has(player_index):
			display_name = BOT_NAMES[mini(bot_number, BOT_NAMES.size() - 1)]
		if is_bot:
			bot_number += 1
		seats.append({
			"player_index": player_index,
			"display_name": display_name,
			"account_id": str(account_by_player.get(player_index, "")),
			"connected": peer_by_player.has(player_index),
			"confirmed": ready_players.has(player_index) or is_bot,
			"ready": ready_players.has(player_index) or is_bot,
			"is_host": player_index == int(room.get("owner_player_index", 0)),
			"is_bot": is_bot,
			"is_temporary_bot": temporary_bot_players.has(player_index),
			"forfeited": (room.get("forfeited_players", {}) as Dictionary).has(player_index),
			"reconnecting": reconnecting.has(player_index),
			"reconnect_deadline_unix": int((room.get("reconnect_deadline_unix_by_player", {}) as Dictionary).get(player_index, 0)),
			"team_id": player_index % 2 if str(room.get("match_mode", MATCH_MODE_CLASSIC)) == MATCH_MODE_TEAMS_2V2 else -1,
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


func _sorted_player_indices(data_variant: Variant) -> Array[int]:
	var result: Array[int] = []
	if data_variant is Dictionary:
		for player_index_variant in (data_variant as Dictionary).keys():
			result.append(int(player_index_variant))
	result.sort()
	return result

func _assign_room_owner(room: Dictionary) -> void:
	var human_players: Array = (room.get("session_token_by_player", {}) as Dictionary).keys()
	human_players.sort()
	room["owner_player_index"] = int(human_players[0]) if not human_players.is_empty() else -1


func _sanitize_match_mode(value: String) -> String:
	return MATCH_MODE_TEAMS_2V2 if value == MATCH_MODE_TEAMS_2V2 else MATCH_MODE_CLASSIC


func _sanitize_game_type(value: String) -> String:
	return GAME_TYPE_RANKED if value == GAME_TYPE_RANKED else GAME_TYPE_CASUAL


func _get_reconnect_grace_seconds(room: Dictionary) -> int:
	return RANKED_RECONNECT_GRACE_SECONDS if str(room.get("game_type", GAME_TYPE_CASUAL)) == GAME_TYPE_RANKED else CASUAL_RECONNECT_GRACE_SECONDS


func _dictionary_with_integer_keys(source_variant: Variant) -> Dictionary:
	var result := {}
	if source_variant is Dictionary:
		for key_variant in (source_variant as Dictionary).keys():
			var key := int(key_variant)
			if key >= 0 and key < PLAYER_COUNT:
				result[key] = (source_variant as Dictionary)[key_variant]
	return result

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
	if int(message.get("protocol_version", -1)) != PROTOCOL_VERSION:
		_reject_room_action(target_peer_id, "protocol_version_mismatch")
		return false
	if not _account_id_by_peer.has(target_peer_id):
		_reject_room_action(target_peer_id, "account_required")
		return false
	return true


func _validate_account_protocol(target_peer_id: int, message: Dictionary) -> bool:
	if int(message.get("protocol_version", -1)) == PROTOCOL_VERSION:
		return true
	_send(target_peer_id, {"type": "account_rejected", "reason": "protocol_version_mismatch", "protocol_version": PROTOCOL_VERSION})
	return false


func _take_account_challenge(peer_id: int) -> String:
	var challenge := str(_account_challenge_by_peer.get(peer_id, ""))
	_account_challenge_by_peer.erase(peer_id)
	return challenge


func _get_authenticated_display_name(peer_id: int) -> String:
	if _account_store == null:
		return "Игрок"
	var account: Dictionary = _account_store.get_public_account(str(_account_id_by_peer.get(peer_id, "")))
	return _sanitize_display_name(str(account.get("display_name", "Игрок")))


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
	_account_id_by_peer.erase(peer_id)
	_account_recovery_attempts_by_peer.erase(peer_id)
	_account_challenge_by_peer.erase(peer_id)
	_leave_current_room(peer_id, false)


func _set_status(new_status: String) -> void:
	if status == new_status:
		return
	status = new_status
	print("[ProjectJokerServer] ", status)
	status_changed.emit(status)
