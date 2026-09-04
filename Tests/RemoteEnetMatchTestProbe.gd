extends SceneTree

const Server = preload("res://Scripts/server/WebSocketGameServer.gd")
const RemoteMatch = preload("res://Scripts/core/RemoteEnetMatch.gd")
const TEST_PORT := 28766
const TEST_ACCOUNT_DB_PATH := "user://remote_enet_accounts_test.json"

var server
var clients: Array[Node] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_cleanup_account_database()
	server = Server.new()
	assert(server.start(TEST_PORT, "127.0.0.1", TEST_ACCOUNT_DB_PATH) == OK)
	for player_index in Server.PLAYER_COUNT:
		var client = RemoteMatch.new()
		root.add_child(client)
		clients.append(client)
		assert(client.start_client("127.0.0.1", TEST_PORT, "Client %d" % (player_index + 1), "", 0))
	assert(await _wait_until(func(): return _all_directories_ready()), "Remote directory clients did not connect")
	for client in clients:
		assert(client.is_account_connected())
		assert(client.account_id.begins_with("PJ-"))
		assert(client.account_device_token.length() == 64)
		assert(client.account_recovery_code.length() == 39)

	var recovered_client = RemoteMatch.new()
	root.add_child(recovered_client)
	assert(recovered_client.start_client(
		"127.0.0.1",
		TEST_PORT,
		"Recovered",
		"",
		0,
		"",
		clients[0].account_id,
		clients[0].account_recovery_code
	))
	assert(await _wait_until(func(): return recovered_client.is_directory_connected()), "A second device did not recover the account")
	assert(recovered_client.account_id == clients[0].account_id)
	assert(recovered_client.account_device_token != clients[0].account_device_token)
	recovered_client.stop()
	recovered_client.queue_free()
	await process_frame

	var stale_client = RemoteMatch.new()
	root.add_child(stale_client)
	assert(stale_client.start_client("127.0.0.1", TEST_PORT, "Stale reconnect", "0123456789abcdef0123456789abcdef", 999999))
	assert(await _wait_until(func(): return stale_client.is_directory_connected()), "Stale reconnect client did not reach directory")
	assert(stale_client.saved_room_id == 0)
	assert(stale_client.session_token.is_empty())
	stale_client.stop()
	stale_client.queue_free()
	await process_frame
	assert(clients[0].create_lobby("Ranked validation", false, "", "classic", true, 2, "ranked"))
	assert(await _wait_until(func(): return clients[0].is_in_room()), "Ranked room creator did not enter the room")
	assert(clients[0].current_room_game_type == "ranked")
	assert(not clients[0].current_room_fill_empty_seats_with_bots, "Ranked rooms must reject starting bots")
	assert(not clients[0].can_start_match(), "A ranked room must require four human players")
	assert(clients[0].leave_lobby())
	assert(await _wait_until(func(): return not clients[0].is_in_room()), "Ranked validation room did not close")

	assert(clients[0].create_lobby("Automated room", true, "secret", "teams_2v2", false, 2))
	assert(await _wait_until(func(): return clients[0].is_in_room()), "Creator did not enter the room")
	var room_id: int = clients[0].current_room_id
	assert(room_id > 0)
	for client_index in range(1, clients.size()):
		assert(clients[client_index].join_lobby(room_id, "secret"))
	assert(await _wait_until(func(): return _all_clients_confirmed()), "RemoteEnetMatch clients did not finish the seat handshake")
	assert(clients[0].is_host())
	assert(clients[0].current_room_match_mode == "teams_2v2")
	for client in clients:
		assert(client.set_ready(true))
	assert(await _wait_until(func(): return _all_clients_ready()), "RemoteEnetMatch clients did not become ready")
	assert(await _wait_until(func(): return clients[0].can_start_match()), "Owner did not receive the final ready state")
	assert(clients[0].start_match())
	assert(await _wait_until(func(): return _all_clients_have_first_turn_roll()), "RemoteEnetMatch clients did not enter the first-turn roll")
	clients[0].first_turn_roll_state.clear()
	assert(not clients[0].is_first_turn_roll_active())
	assert(clients[0].request_room_resync())
	assert(
		await _wait_until(func(): return clients[0].is_first_turn_roll_active()),
		"A client that missed the roll update must recover the room state through resync"
	)
	var saved_seats: Array[Dictionary] = clients[0].lobby_seats.duplicate(true)
	clients[0].lobby_seats[1]["reconnecting"] = true
	assert(clients[0].is_match_paused_for_reconnect())
	assert(
		clients[0].can_submit_first_turn_roll(),
		"A connected contender must be able to roll while another player is reconnecting"
	)
	clients[0].lobby_seats.assign(saved_seats)
	assert(await _complete_first_turn_roll(), "RemoteEnetMatch clients did not complete the first-turn roll")
	var first_player_index := int(clients[0].get_first_turn_roll_state().get("winner_player_index", -1))
	assert(first_player_index >= 0)
	assert(clients[0].start_first_real_round())
	assert(await _wait_until(func(): return _all_clients_have_safe_snapshots()), "RemoteEnetMatch clients did not reach the first round")
	assert(int(clients[0].get_test_table_snapshot().get("dealer_index", -1)) == posmod(first_player_index - 1, Server.PLAYER_COUNT))

	for client in clients:
		assert(client.client_seat_confirmed)
		assert(client.session_token.length() == 32)
		assert(client.saved_room_id == room_id)
		assert(client.client_private_hand_size == 1)
		assert(client.client_snapshot_is_safe)

	var active_client
	for client in clients:
		var round_data: Dictionary = client.get_test_table_snapshot().get("round", {})
		if int(round_data.get("current_player_index", -1)) == client.client_player_index:
			active_client = client
			break
	assert(active_client != null)
	var available_bids: Array[int] = active_client.get_available_test_bids()
	assert(not available_bids.is_empty())
	assert(active_client.submit_test_bid(available_bids[0]))
	assert(await _wait_until(func(): return int(server.get_room_debug_state(room_id).get("revision", 0)) == 1 and not active_client.client_command_in_flight), "Remote bid did not round-trip through the authoritative room")

	assert(await _wait_until(func(): return _all_clients_have_safe_snapshots()), "Clients did not receive the post-command snapshots")
	var disconnected_player_index := int(clients[0].get_test_table_snapshot().get("round", {}).get("current_player_index", -1))
	var disconnected_client_slot := -1
	for client_slot in clients.size():
		if clients[client_slot].client_player_index == disconnected_player_index:
			disconnected_client_slot = client_slot
			break
	assert(disconnected_client_slot >= 0)
	var observer_client = clients[0] if disconnected_client_slot != 0 else clients[1]
	var reconnect_token: String = clients[disconnected_client_slot].session_token
	var reconnect_account_id: String = clients[disconnected_client_slot].account_id
	var reconnect_recovery_code: String = clients[disconnected_client_slot].account_recovery_code
	clients[disconnected_client_slot].stop()
	clients[disconnected_client_slot].queue_free()
	clients[disconnected_client_slot] = null
	await process_frame
	assert(await _wait_until(func(): return disconnected_player_index in observer_client.get_reconnecting_player_indices()), "The room did not pause for the disconnected player")
	assert(observer_client.is_match_paused_for_reconnect())
	(server._rooms[room_id].get("reconnect_deadline_unix_by_player", {}) as Dictionary)[disconnected_player_index] = int(Time.get_unix_time_from_system()) - 1
	assert(await _wait_until(func(): return disconnected_player_index in observer_client.get_temporary_bot_player_indices(), 12.0), "A temporary bot did not take over after the reconnect grace period")
	assert(not observer_client.is_match_paused_for_reconnect())
	var reconnecting_client = RemoteMatch.new()
	root.add_child(reconnecting_client)
	clients[disconnected_client_slot] = reconnecting_client
	assert(reconnecting_client.start_client(
		"127.0.0.1",
		TEST_PORT,
		"Client %d reconnected" % (disconnected_player_index + 1),
		"",
		0,
		"",
		reconnect_account_id,
		reconnect_recovery_code
	))
	assert(await _wait_until(func(): return reconnecting_client.is_directory_connected()), "Reconnect client did not reach directory")
	assert(reconnecting_client.account_active_room_id == room_id)
	assert(reconnecting_client.saved_room_id == room_id)
	assert(reconnecting_client.join_lobby(room_id, ""), "Reconnect token should bypass the private-room password")
	assert(await _wait_until(func(): return reconnecting_client.client_snapshot_is_safe), "Reconnect client did not recover its private snapshot")
	assert(await _wait_until(func(): return disconnected_player_index not in observer_client.get_temporary_bot_player_indices()), "The temporary bot did not yield the seat back to the player")
	assert(reconnecting_client.current_room_id == room_id)
	assert(reconnecting_client.session_token == reconnect_token)
	assert(reconnecting_client.account_id == reconnect_account_id)
	assert(reconnecting_client.client_player_index == disconnected_player_index)

	var room: Dictionary = server._rooms[room_id]
	var match_host = room.get("match_host")
	match_host.game.round_number = Server.TOTAL_ROUND_COUNT
	match_host.game.current_round.state = Round.State.FINISHED
	match_host.completed_round_history.clear()
	for completed_round_index in Server.TOTAL_ROUND_COUNT:
		match_host.completed_round_history.append({"round_number": completed_round_index + 1})
	server._broadcast_player_snapshots(room)
	assert(await _wait_until(func(): return clients[0].is_match_finished()), "Remote client did not recognize the final match snapshot")
	assert(await _wait_until(func(): return clients[0].account_xp >= Server.MATCH_BASE_XP), "Remote client did not apply the server XP result")
	assert(not clients[0].last_xp_award.is_empty())
	assert(clients[0].return_finished_match_to_lobby())
	assert(await _wait_until(func(): return _all_clients_returned_to_lobby()), "Remote clients did not reset after returning to the lobby")
	print("REMOTE_ENET_MATCH_TEST_PASS")
	_cleanup()
	quit()


func _wait_until(predicate: Callable, timeout_seconds := 8.0) -> bool:
	var deadline := Time.get_ticks_msec() + int(timeout_seconds * 1000.0)
	while Time.get_ticks_msec() < deadline:
		server.poll()
		if predicate.call():
			return true
		await process_frame
	return false


func _all_directories_ready() -> bool:
	for client in clients:
		if not client.is_directory_connected():
			return false
	return true


func _all_clients_confirmed() -> bool:
	for client in clients:
		if not client.client_seat_confirmed:
			return false
	return true


func _all_clients_ready() -> bool:
	for client in clients:
		if not client.client_ready:
			return false
	return true


func _all_clients_have_first_turn_roll() -> bool:
	for client in clients:
		if not client.is_first_turn_roll_active():
			return false
	return true


func _complete_first_turn_roll(timeout_seconds := 18.0) -> bool:
	var deadline := Time.get_ticks_msec() + int(timeout_seconds * 1000.0)
	while Time.get_ticks_msec() < deadline:
		server.poll()
		var all_complete := true
		for client in clients:
			if client.can_submit_first_turn_roll():
				assert(client.submit_first_turn_roll())
			if not client.is_first_turn_roll_complete():
				all_complete = false
		if all_complete:
			return true
		await process_frame
	return false


func _all_clients_returned_to_lobby() -> bool:
	for client in clients:
		if client.lobby_round_started or client.client_snapshot_is_safe:
			return false
	return true


func _all_clients_have_safe_snapshots() -> bool:
	for client in clients:
		if not client.client_snapshot_is_safe:
			return false
	return true


func _cleanup() -> void:
	for client in clients:
		client.stop()
		client.queue_free()
	server.stop()
	_cleanup_account_database()


func _cleanup_account_database() -> void:
	for suffix in ["", ".tmp", ".bak"]:
		var path: String = TEST_ACCOUNT_DB_PATH + str(suffix)
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
