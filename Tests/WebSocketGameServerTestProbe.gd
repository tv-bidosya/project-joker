extends SceneTree

const Server = preload("res://Scripts/server/WebSocketGameServer.gd")
const Snapshot = preload("res://Scripts/core/MatchStateSnapshot.gd")
const Command = preload("res://Scripts/core/MatchCommand.gd")
const TEST_PORT := 28765
const CLIENT_COUNT := 6

var server
var clients: Array[ENetMultiplayerPeer] = []
var inboxes: Array[Array] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	server = Server.new()
	assert(server.start(TEST_PORT, "127.0.0.1") == OK)
	for client_index in CLIENT_COUNT:
		var client := ENetMultiplayerPeer.new()
		assert(client.create_client("127.0.0.1", TEST_PORT) == OK)
		clients.append(client)
		inboxes.append([])
	assert(await _wait_until(func(): return _all_clients_connected()), "Directory clients did not connect")
	for client_index in CLIENT_COUNT:
		_send_client(client_index, {"type": "directory_request", "protocol_version": Server.PROTOCOL_VERSION})
	assert(await _wait_until(func(): return _all_message_types_received("directory_state")), "All clients must receive the directory")

	_send_client(0, {
		"type": "create_lobby",
		"protocol_version": Server.PROTOCOL_VERSION,
		"room_name": "Open table",
		"is_private": false,
		"password_hash": "",
		"display_name": "Open host",
		"match_mode": "classic",
		"fill_empty_seats_with_bots": true,
		"bot_difficulty": 1
	})
	assert(await _wait_until(func(): return _has_message_type(0, "seat_assigned")), "Public room creator must receive a seat")
	var public_seat := _take_message(0, "seat_assigned")
	var public_room_id := int(public_seat.get("room_id", 0))
	assert(public_room_id > 0)

	var private_hash := "secret".sha256_text()
	_send_client(1, {
		"type": "create_lobby",
		"protocol_version": Server.PROTOCOL_VERSION,
		"room_name": "Locked table",
		"is_private": true,
		"password_hash": private_hash,
		"display_name": "Private host"
	})
	assert(await _wait_until(func(): return _has_message_type(1, "seat_assigned")), "Private room creator must receive a seat")
	var private_seat := _take_message(1, "seat_assigned")
	var private_room_id := int(private_seat.get("room_id", 0))
	assert(private_room_id > 0 and private_room_id != public_room_id)

	_send_client(5, {"type": "directory_request", "protocol_version": Server.PROTOCOL_VERSION})
	assert(await _wait_until(func(): return _latest_directory_has_rooms(5, 2)), "Directory must show public and locked rooms")
	var directory := _take_latest_message(5, "directory_state")
	var summaries: Array = directory.get("lobbies", [])
	assert(summaries.size() == 2)
	assert(_find_summary(summaries, public_room_id).get("is_private", true) == false)
	assert(_find_summary(summaries, private_room_id).get("is_private", false) == true)

	_send_client(2, {
		"type": "join_lobby",
		"protocol_version": Server.PROTOCOL_VERSION,
		"room_id": private_room_id,
		"display_name": "Wrong password",
		"password_hash": "wrong".sha256_text()
	})
	assert(await _wait_until(func(): return _has_rejection(2, "wrong_password")), "Wrong password must be rejected")

	for client_index in [2, 3, 4]:
		_send_client(client_index, {
			"type": "join_lobby",
			"protocol_version": Server.PROTOCOL_VERSION,
			"room_id": private_room_id,
			"display_name": "Player %d" % client_index,
			"password_hash": private_hash
		})
	assert(await _wait_until(func(): return _clients_have_message([2, 3, 4], "seat_assigned")), "Private room must assign remaining seats")

	_send_client(1, {"type": "seat_ack", "player_index": int(private_seat.get("player_index", -1))})
	for client_index in [2, 3, 4]:
		var assigned := _take_message(client_index, "seat_assigned")
		assert(int(assigned.get("room_id", 0)) == private_room_id)
		_send_client(client_index, {"type": "seat_ack", "player_index": int(assigned.get("player_index", -1))})
	assert(await _wait_until(func(): return _clients_have_message([1, 2, 3, 4], "seat_confirmed")), "All seats must finish the transport handshake")
	_send_client(2, {"type": "start_match"})
	assert(await _wait_until(func(): return _has_rejection(2, "host_only")), "Only the owner may start the match")
	_send_client(1, {"type": "update_room_settings", "match_mode": "teams_2v2", "fill_empty_seats_with_bots": false, "bot_difficulty": 2})
	for client_index in [1, 2, 3, 4]:
		_send_client(client_index, {"type": "set_ready", "ready": true})
	assert(await _wait_until(func(): return int(server.get_room_debug_state(private_room_id).get("confirmed", 0)) == 4), "All human players must explicitly become ready")
	_send_client(1, {"type": "start_match"})
	assert(await _drive_first_turn_roll(private_room_id, [1, 2, 3, 4]), "Private room must complete the first-turn roll")
	_send_client(1, {"type": "start_first_round"})
	assert(await _wait_until(func(): return _clients_have_message([1, 2, 3, 4], "player_snapshot")), "Owner start must begin only the ready private room")

	var active_client_index := -1
	var active_snapshot: Dictionary = {}
	for client_index in [1, 2, 3, 4]:
		var snapshot_message := _take_latest_message(client_index, "player_snapshot")
		var snapshot: Dictionary = snapshot_message.get("snapshot", {})
		var player_index := _player_index_for_peer(private_room_id, client_index)
		assert(Snapshot.is_player_snapshot_safe(snapshot, player_index))
		if int((snapshot.get("round", {}) as Dictionary).get("current_player_index", -1)) == player_index:
			active_client_index = client_index
			active_snapshot = snapshot
	assert(active_client_index >= 0)

	var actor_index := _player_index_for_peer(private_room_id, active_client_index)
	var bid_command := Command.new(Command.Type.BID, actor_index, int(active_snapshot.get("round_number", -1)), int(active_snapshot.get("revision", -1)), {"bid": 0})
	_send_client(active_client_index, {"type": "match_command", "command": bid_command.to_dictionary()})
	assert(await _wait_until(func(): return _has_accepted_command(active_client_index) and int(server.get_room_debug_state(private_room_id).get("revision", 0)) == 1), "Authoritative room must accept a valid bid")
	assert(not bool(server.get_room_debug_state(public_room_id).get("round_started", true)), "Other room state must remain isolated")

	var private_room: Dictionary = server._rooms[private_room_id]
	var private_match_host = private_room.get("match_host")
	private_match_host.game.round_number = Server.TOTAL_ROUND_COUNT
	private_match_host.game.current_round.state = Round.State.FINISHED
	_send_client(2, {"type": "return_to_lobby"})
	assert(await _wait_until(func(): return _has_rejection(2, "host_only")), "Only the owner may return a finished match to the lobby")
	_send_client(1, {"type": "return_to_lobby"})
	assert(await _wait_until(func(): return not bool(server.get_room_debug_state(private_room_id).get("round_started", true)) and int(server.get_room_debug_state(private_room_id).get("round_number", -1)) == 0), "Finished room must reset for a rematch")

	_send_client(0, {"type": "seat_ack", "player_index": int(public_seat.get("player_index", -1))})
	assert(await _wait_until(func(): return _has_message_type(0, "seat_confirmed")), "Bot-room host seat must be confirmed")
	_send_client(0, {"type": "set_ready", "ready": true})
	_send_client(0, {"type": "start_match"})
	assert(await _drive_first_turn_roll(public_room_id, [0]), "Bot room must complete the first-turn roll")
	_send_client(0, {"type": "start_first_round"})
	assert(await _wait_until(func(): return _has_message_type(0, "player_snapshot") and int(server.get_room_debug_state(public_room_id).get("round_number", 0)) == 1), "One human plus server bots must start the first round")
	print("WEBSOCKET_GAME_SERVER_TEST_PASS")
	_cleanup()
	quit()


func _wait_until(predicate: Callable, timeout_seconds := 8.0) -> bool:
	var deadline := Time.get_ticks_msec() + int(timeout_seconds * 1000.0)
	while Time.get_ticks_msec() < deadline:
		_pump()
		if predicate.call():
			return true
		await process_frame
	return false


func _pump() -> void:
	server.poll()
	for client_index in clients.size():
		var client := clients[client_index]
		client.poll()
		while client.get_available_packet_count() > 0:
			var parsed: Variant = JSON.parse_string(client.get_packet().get_string_from_utf8())
			if parsed is Dictionary:
				inboxes[client_index].append(parsed)


func _drive_first_turn_roll(room_id: int, client_indices: Array, timeout_seconds := 18.0) -> bool:
	var deadline := Time.get_ticks_msec() + int(timeout_seconds * 1000.0)
	while Time.get_ticks_msec() < deadline:
		_pump()
		var debug_state: Dictionary = server.get_room_debug_state(room_id)
		if int(debug_state.get("first_turn_roll_phase", -1)) == Server.FirstTurnRollPhase.COMPLETE:
			return int(debug_state.get("first_turn_roll_winner_index", -1)) >= 0
		for client_index_variant in client_indices:
			var client_index := int(client_index_variant)
			var lobby_state := _peek_latest_message(client_index, "lobby_state")
			var roll_state: Dictionary = lobby_state.get("first_turn_roll", {})
			if int(roll_state.get("phase", -1)) != Server.FirstTurnRollPhase.WAITING:
				continue
			var player_index := _player_index_for_peer(room_id, client_index)
			var contenders: Array = roll_state.get("contenders", [])
			var submitted: Array = roll_state.get("submitted", [])
			var is_contender := false
			for contender_variant in contenders:
				if int(contender_variant) == player_index:
					is_contender = true
					break
			if player_index >= 0 and is_contender and player_index < submitted.size() and not bool(submitted[player_index]):
				_send_client(client_index, {"type": "first_turn_roll", "roll_round": int(roll_state.get("roll_round", -1))})
		await process_frame
	return false


func _all_clients_connected() -> bool:
	for client in clients:
		if client.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
			return false
	return true


func _send_client(client_index: int, message: Dictionary) -> void:
	var client := clients[client_index]
	client.set_target_peer(1)
	assert(client.put_packet(JSON.stringify(message).to_utf8_buffer()) == OK)
	client.set_target_peer(0)


func _all_message_types_received(message_type: String) -> bool:
	for client_index in CLIENT_COUNT:
		if not _has_message_type(client_index, message_type):
			return false
	return true


func _clients_have_message(indices: Array, message_type: String) -> bool:
	for client_index in indices:
		if not _has_message_type(int(client_index), message_type):
			return false
	return true


func _has_message_type(client_index: int, message_type: String) -> bool:
	for message_variant in inboxes[client_index]:
		if message_variant is Dictionary and str((message_variant as Dictionary).get("type", "")) == message_type:
			return true
	return false


func _has_rejection(client_index: int, reason: String) -> bool:
	for message_variant in inboxes[client_index]:
		if message_variant is Dictionary:
			var message: Dictionary = message_variant
			if str(message.get("type", "")) == "lobby_rejected" and str(message.get("reason", "")) == reason:
				return true
	return false


func _has_accepted_command(client_index: int) -> bool:
	for message_variant in inboxes[client_index]:
		if message_variant is Dictionary:
			var message: Dictionary = message_variant
			if str(message.get("type", "")) == "command_result" and bool(message.get("accepted", false)):
				return true
	return false


func _latest_directory_has_rooms(client_index: int, count: int) -> bool:
	for message_index in range(inboxes[client_index].size() - 1, -1, -1):
		var message_variant = inboxes[client_index][message_index]
		if message_variant is Dictionary and str((message_variant as Dictionary).get("type", "")) == "directory_state":
			return (message_variant.get("lobbies", []) as Array).size() == count
	return false


func _find_summary(summaries: Array, room_id: int) -> Dictionary:
	for summary_variant in summaries:
		if summary_variant is Dictionary and int((summary_variant as Dictionary).get("room_id", 0)) == room_id:
			return summary_variant
	return {}


func _player_index_for_peer(room_id: int, client_index: int) -> int:
	for message_variant in inboxes[client_index]:
		if message_variant is Dictionary:
			var message: Dictionary = message_variant
			if str(message.get("type", "")) == "seat_confirmed" and int(message.get("room_id", 0)) == room_id:
				return int(message.get("player_index", -1))
	return -1


func _take_message(client_index: int, message_type: String) -> Dictionary:
	for message_index in inboxes[client_index].size():
		var message_variant = inboxes[client_index][message_index]
		if message_variant is Dictionary and str((message_variant as Dictionary).get("type", "")) == message_type:
			inboxes[client_index].remove_at(message_index)
			return message_variant
	return {}


func _take_latest_message(client_index: int, message_type: String) -> Dictionary:
	for message_index in range(inboxes[client_index].size() - 1, -1, -1):
		var message_variant = inboxes[client_index][message_index]
		if message_variant is Dictionary and str((message_variant as Dictionary).get("type", "")) == message_type:
			inboxes[client_index].remove_at(message_index)
			return message_variant
	return {}


func _peek_latest_message(client_index: int, message_type: String) -> Dictionary:
	for message_index in range(inboxes[client_index].size() - 1, -1, -1):
		var message_variant = inboxes[client_index][message_index]
		if message_variant is Dictionary and str((message_variant as Dictionary).get("type", "")) == message_type:
			return message_variant
	return {}


func _cleanup() -> void:
	for client in clients:
		client.close()
	server.stop()
