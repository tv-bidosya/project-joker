extends SceneTree

const Server = preload("res://Scripts/server/WebSocketGameServer.gd")
const RemoteMatch = preload("res://Scripts/core/RemoteEnetMatch.gd")
const TEST_PORT := 28766

var server
var clients: Array[Node] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	server = Server.new()
	assert(server.start(TEST_PORT, "127.0.0.1") == OK)
	for player_index in Server.PLAYER_COUNT:
		var client = RemoteMatch.new()
		root.add_child(client)
		clients.append(client)
		assert(client.start_client("127.0.0.1", TEST_PORT, "Client %d" % (player_index + 1), "", 0))
	assert(await _wait_until(func(): return _all_directories_ready()), "Remote directory clients did not connect")

	var stale_client = RemoteMatch.new()
	root.add_child(stale_client)
	assert(stale_client.start_client("127.0.0.1", TEST_PORT, "Stale reconnect", "0123456789abcdef0123456789abcdef", 999999))
	assert(await _wait_until(func(): return stale_client.is_directory_connected()), "Stale reconnect client did not reach directory")
	assert(stale_client.saved_room_id == 0)
	assert(stale_client.session_token.is_empty())
	stale_client.stop()
	stale_client.queue_free()
	await process_frame

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
	assert(await _wait_until(func(): return _all_clients_have_safe_snapshots()), "RemoteEnetMatch clients did not reach the first round")

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
	clients[disconnected_client_slot].stop()
	clients[disconnected_client_slot].queue_free()
	clients[disconnected_client_slot] = null
	await process_frame
	assert(await _wait_until(func(): return disconnected_player_index in observer_client.get_reconnecting_player_indices()), "The room did not pause for the disconnected player")
	assert(observer_client.is_match_paused_for_reconnect())
	assert(await _wait_until(func(): return disconnected_player_index in observer_client.get_temporary_bot_player_indices(), 12.0), "A temporary bot did not take over after the reconnect grace period")
	assert(not observer_client.is_match_paused_for_reconnect())
	var reconnecting_client = RemoteMatch.new()
	root.add_child(reconnecting_client)
	clients[disconnected_client_slot] = reconnecting_client
	assert(reconnecting_client.start_client("127.0.0.1", TEST_PORT, "Client %d reconnected" % (disconnected_player_index + 1), reconnect_token, room_id))
	assert(await _wait_until(func(): return reconnecting_client.is_directory_connected()), "Reconnect client did not reach directory")
	assert(reconnecting_client.join_lobby(room_id, ""), "Reconnect token should bypass the private-room password")
	assert(await _wait_until(func(): return reconnecting_client.client_snapshot_is_safe), "Reconnect client did not recover its private snapshot")
	assert(await _wait_until(func(): return disconnected_player_index not in observer_client.get_temporary_bot_player_indices()), "The temporary bot did not yield the seat back to the player")
	assert(reconnecting_client.current_room_id == room_id)
	assert(reconnecting_client.session_token == reconnect_token)
	assert(reconnecting_client.client_player_index == disconnected_player_index)
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
