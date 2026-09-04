extends SceneTree

const Server = preload("res://Scripts/server/WebSocketGameServer.gd")
const RemoteMatch = preload("res://Scripts/core/RemoteEnetMatch.gd")
const TEST_PORT := 28768
const TEST_ACCOUNT_DB_PATH := "user://remote_two_player_accounts_test.json"
const TEST_MATCH_DB_PATH := "user://remote_two_player_matches_test.json"

var server
var clients: Array[Node] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_cleanup()
	server = Server.new()
	assert(server.start(TEST_PORT, "127.0.0.1", TEST_ACCOUNT_DB_PATH, TEST_MATCH_DB_PATH) == OK)
	for player_name in ["Desktop", "Android"]:
		var client = RemoteMatch.new()
		root.add_child(client)
		clients.append(client)
		assert(client.start_client("127.0.0.1", TEST_PORT, player_name))
	assert(await _wait_until(func(): return clients.all(func(client): return client.is_directory_connected())))

	assert(clients[0].create_lobby("Two devices and bots", false, "", "classic", true, 1))
	assert(await _wait_until(func(): return clients[0].client_seat_confirmed))
	var room_id: int = clients[0].current_room_id
	assert(clients[1].join_lobby(room_id, ""))
	assert(await _wait_until(func(): return clients.all(func(client): return client.client_seat_confirmed)))
	for client in clients:
		assert(client.set_ready(true))
	assert(await _wait_until(func(): return clients[0].can_start_match()))
	assert(clients[0].start_match())
	assert(await _wait_until(func(): return clients.all(func(client): return client.is_first_turn_roll_active())))

	var submitted: Array = clients[0].get_first_turn_roll_state().get("submitted", [])
	assert(submitted == [false, false, true, true], "Bots must roll while both devices remain interactive")
	assert(clients[0].can_submit_first_turn_roll())
	assert(clients[1].can_submit_first_turn_roll())

	var duplicate_updates := [0]
	clients[0].room_state_changed.connect(func(): duplicate_updates[0] += 1)
	assert(clients[0].request_room_resync())
	await _pump_for(0.2)
	assert(duplicate_updates[0] == 0, "An identical periodic resync must not redraw and flicker the room")

	assert(clients[0].submit_first_turn_roll())
	assert(clients[1].submit_first_turn_roll())
	assert(await _wait_until(_finish_roll_and_receive_snapshots, 20.0))
	assert(clients.all(func(client): return int(client.get_test_table_snapshot().get("round_number", 0)) == 1))
	print("REMOTE_TWO_PLAYER_START_TEST_PASS")
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


func _pump_for(seconds: float) -> void:
	var deadline := Time.get_ticks_msec() + int(seconds * 1000.0)
	while Time.get_ticks_msec() < deadline:
		server.poll()
		await process_frame


func _finish_roll_and_receive_snapshots() -> bool:
	for client in clients:
		if client.can_submit_first_turn_roll():
			client.submit_first_turn_roll()
	return clients.all(func(client): return client.client_snapshot_is_safe)


func _cleanup() -> void:
	for client in clients:
		if is_instance_valid(client):
			client.stop()
			client.queue_free()
	clients.clear()
	if server != null:
		server.stop()
	for base_path in [TEST_ACCOUNT_DB_PATH, TEST_MATCH_DB_PATH]:
		for suffix in ["", ".tmp", ".bak"]:
			var path: String = str(base_path) + str(suffix)
			if FileAccess.file_exists(path):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
