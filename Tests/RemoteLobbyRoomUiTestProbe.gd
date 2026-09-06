extends SceneTree


var scene


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	scene = load("res://Scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame

	scene._show_remote_create_lobby_menu()
	await process_frame
	assert(scene.menu_content.find_child("RemoteRoomMatchModeSelector", true, false) != null)
	assert(scene.menu_content.find_child("RemoteRoomFillBotsToggle", true, false) != null)
	assert(scene.menu_content.find_child("RemoteRoomBotDifficultySelector", true, false) != null)

	var remote = scene.remote_enet_match
	remote.current_room_id = 4321
	remote.current_room_name = "Mobile room"
	remote.current_room_is_private = true
	remote.current_room_owner_player_index = 0
	remote.current_room_match_mode = "teams_2v2"
	remote.current_room_fill_empty_seats_with_bots = true
	remote.current_room_bot_difficulty = 2
	remote.client_player_index = 0
	remote.client_seat_confirmed = true
	remote.client_ready = true
	remote.lobby_seats.clear()
	for seat in [
		{"player_index": 0, "display_name": "Host", "connected": true, "ready": true, "is_host": true, "is_bot": false, "team_id": 0},
		{"player_index": 1, "display_name": "Rhysand", "connected": false, "ready": true, "is_host": false, "is_bot": true, "team_id": 1},
		{"player_index": 2, "display_name": "Azriel", "connected": false, "ready": true, "is_host": false, "is_bot": true, "team_id": 0},
		{"player_index": 3, "display_name": "Cassian", "connected": false, "ready": true, "is_host": false, "is_bot": true, "team_id": 1}
	]:
		remote.lobby_seats.append(seat)
	scene._show_remote_enet_lobby()
	await process_frame
	var seat_grid = scene.menu_content.find_child("RemoteLobbySeatGrid", true, false)
	assert(seat_grid != null)
	assert(seat_grid.get_child_count() == 4)
	assert(scene.menu_content.find_child("RemoteLobbyMatchModeSelector", true, false) != null)
	assert(scene.menu_content.find_child("RemoteLobbyFillBotsToggle", true, false) != null)
	assert(scene.menu_content.find_child("RemoteLobbyBotDifficultySelector", true, false) != null)
	var start_button := _find_button(scene.menu_content, tr("Начать матч"))
	assert(start_button != null)
	assert(not start_button.disabled)

	# Landscape phones show three compact cards per row, so six rooms remain
	# visible as a useful 3x2 block rather than four oversized cards.
	scene._clear_children(scene.menu_content)
	scene.mobile_table_layout = true
	var room_grid = scene._create_remote_lobby_cards_grid()
	for room_index in range(6):
		scene._add_remote_lobby_card({
			"room_id": 5000 + room_index,
			"room_name": "Room %d" % room_index,
			"state": "waiting",
			"game_type": "casual",
			"member_count": 2,
			"member_limit": 4,
			"host_name": "Host"
		}, room_grid)
	assert(room_grid.columns == 3)
	assert(room_grid.get_child_count() == 6)
	for card in room_grid.get_children():
		assert(card.custom_minimum_size.y <= 128.0, "Mobile room cards must stay compact")
		var join_button := _find_button(card, tr("Войти"))
		assert(join_button != null)
		assert(join_button.custom_minimum_size.x <= 190.0, "Room actions must not stretch across the whole card")
	print("REMOTE_LOBBY_ROOM_UI_TEST_PASS")
	scene.queue_free()
	await process_frame
	quit()


func _find_button(node: Node, label: String) -> Button:
	if node is Button and (node as Button).text == label:
		return node
	for child in node.get_children():
		var found := _find_button(child, label)
		if found != null:
			return found
	return null
