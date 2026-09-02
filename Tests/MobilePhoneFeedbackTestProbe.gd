extends SceneTree

class LocalBotMatch extends SteamP2PMatch:
	func _configure_multiplayer_peer_as_host() -> bool:
		return true

var scene: Variant


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	scene = load("res://Scenes/main.tscn").instantiate()
	scene.persistent_settings_writes_enabled = false
	scene.persistent_settings_path = "user://mobile_fixes_probe.cfg"
	scene.session_save_path = "user://mobile_fixes_probe.save"
	root.add_child(scene)
	await process_frame
	scene.set_process(false)
	scene._stop_background_music()
	scene.mobile_table_layout = true
	scene._apply_mobile_table_layout()
	await _check_setup()
	await _check_tutorial_and_results()
	await _check_history()
	await _check_score_sheet_and_roll()
	_check_network_bots()
	scene._delete_saved_session()
	scene.queue_free()
	await process_frame
	print("MOBILE_PHONE_FEEDBACK_TEST_PASS")
	quit()


func _check_setup() -> void:
	TranslationServer.set_locale("uk")
	scene._show_new_game_setup()
	await process_frame
	await process_frame
	assert(scene.new_game_name_inputs.size() == 1)
	assert(scene.new_game_name_inputs[0].get_theme_font_size("font_size") == 42, "Input text must grow by 75%")
	assert(scene.new_game_bot_avatar_selectors.is_empty())
	assert(scene.menu_content.find_child("NewGameHistoryModeSelector", true, false) == null)
	assert(not scene.new_game_match_mode_selector.visible and not scene.new_game_bot_difficulty_selector.visible)
	var tiles: Array[Button] = []
	_collect_choices(scene.menu_content, tiles)
	assert(tiles.size() == 5, "Two modes and three difficulty tiles")
	for selector in [scene.new_game_match_mode_selector, scene.new_game_bot_difficulty_selector]:
		for index in selector.item_count:
			for tile in tiles:
				if tile.get_meta("setup_choice") == selector.name and tile.get_meta("choice_index") == index:
					tile.button_pressed = true
					tile.pressed.emit()
					assert(selector.selected == index)
					for other in tiles:
						if other.get_meta("setup_choice") == selector.name:
							assert(other.button_pressed == (other == tile), "Exactly one selected tile in each group")
							assert(other.get_node("SelectionCheck").visible == other.button_pressed, "Check mark must follow the selected tile")
	scene.new_game_name_inputs[0].text = "MobileTest"
	scene._start_configured_new_game()
	assert(scene.configured_player_names == ["MobileTest", "Rhysand", "Azriel", "Cassian"])
	assert(scene.local_match_mode == SteamBridge.MATCH_MODE_TEAMS_2V2)
	assert(scene.bot_difficulty == 2)
	assert(scene.match_history_mode == 0)
	for index in range(1, 4):
		assert(scene.configured_avatar_indices[index] >= 0 and scene.configured_avatar_indices[index] < scene.BUILT_IN_AVATAR_COUNT)
	var save: Dictionary = scene._create_session_save_data()
	save["history_mode"] = 1
	assert(scene._restore_session_from_data(save, false))
	assert(scene.match_history_mode == 0, "Old local saves must also use full history")
	print("MOBILE_SETUP_BOTS_PASS")


func _collect_choices(node: Node, tiles: Array[Button]) -> void:
	if node is Button and node.has_meta("setup_choice"):
		tiles.append(node)
	for child in node.get_children():
		_collect_choices(child, tiles)


func _check_tutorial_and_results() -> void:
	scene.menu_overlay.visible = false
	scene.first_turn_roll_panel.visible = false
	scene.stage_announcement_overlay.visible = false
	scene.tutorial_enabled = true
	for locale in ["en", "uk", "pl", "be", "kz", "ru"]:
		TranslationServer.set_locale(locale)
		for state in [Round.State.BIDDING, Round.State.PLAYING, Round.State.FINISHED]:
			scene.game.current_round.state = state
			scene._refresh_tutorial_panel()
			assert(scene.tutorial_title_label.text == scene.tr("TUTORIAL_HINT_TITLE"))
			assert(scene.tutorial_disable_button.text == scene.tr("TUTORIAL_HINT_DISABLE"))
			assert(not scene.tutorial_text_label.text.begins_with("TUTORIAL_HINT_"))
			if locale != "ru":
				assert(not scene.tutorial_title_label.text.contains("Режим обучения"))
				assert(not scene.tutorial_text_label.text.contains("Сейчас твой заказ"))
	TranslationServer.set_locale("uk")
	scene.tutorial_panel.hide()
	scene.round_results_panel.show()
	scene.next_round_button.show()
	var rows := PackedStringArray()
	for nickname in ["ДужеДовгийНікГравця123456", "Rhysand", "Azriel", "Cassian"]:
		rows.append(scene._format_round_result_bbcode(nickname, 13, 11, -100, 12345, true))
	scene.round_results_label.text = "\n".join(rows)
	scene._fit_round_results_panel(scene.round_results_label.get_parsed_text())
	for frame in 4:
		await process_frame
	scene._position_round_results_actions()
	await process_frame
	assert(scene.round_results_panel.size.x >= 1000)
	assert(scene.round_results_panel.size.x <= scene.size.x - 64)
	assert(not scene.round_results_label.scroll_active, "All four Ukrainian results including a long nickname must fit")
	assert(scene.round_results_label.size.y >= scene.round_results_label.get_content_height(), "No last row may be clipped")
	assert(not scene.next_round_button.get_global_rect().intersects(scene.round_results_panel.get_global_rect()), "Next-round button must not overlap results")
	print("UKRAINIAN_RESULTS_RECT=", scene.round_results_panel.get_global_rect())
	print("TUTORIAL_RESULTS_TRANSLATION_PASS")


func _check_history() -> void:
	scene.round_results_panel.hide()
	scene.next_round_button.hide()
	scene.menu_overlay.hide()
	scene.first_turn_roll_panel.hide()
	scene.stage_announcement_overlay.hide()
	scene.is_score_sheet_visible = false
	scene.round_history_panel.show()
	scene.history_label.text = "Історія\n" + "Довгий рядок історії розіграшу карт\n".repeat(50)
	for frame in 4:
		await process_frame
	var bar: VScrollBar = scene.round_history_scroll.get_v_scroll_bar()
	assert(bar.max_value > bar.page)
	bar.value = bar.max_value
	var start_value := bar.value
	var point: Vector2 = scene.round_history_scroll.get_global_rect().get_center()
	_touch(point, true)
	_drag(point + Vector2(0, 100))
	assert(bar.value < start_value - 80, "Finger drag inside white panel must scroll upwards through the log")
	_touch(point + Vector2(0, 100), false)
	var manual_value := bar.value
	scene._scroll_round_history_to_bottom()
	assert(bar.value == manual_value, "New game events must not steal the scroll position")
	_touch(point, true)
	_drag(point - Vector2(0, 100))
	_touch(point - Vector2(0, 100), false)
	assert(bar.value > manual_value + 80)
	scene.menu_overlay.show()
	start_value = bar.value
	_touch(point, true)
	_drag(point + Vector2(0, 100))
	_touch(point + Vector2(0, 100), false)
	assert(bar.value == start_value, "Modal menu must block touches to history behind it")
	print("MOBILE_HISTORY_TOUCH_PASS")


func _touch(point: Vector2, pressed: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.index = 0
	event.position = root.get_final_transform() * point
	event.pressed = pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()


func _drag(point: Vector2) -> void:
	var event := InputEventScreenDrag.new()
	event.index = 0
	event.position = root.get_final_transform() * point
	Input.parse_input_event(event)
	Input.flush_buffered_events()


func _check_score_sheet_and_roll() -> void:
	scene.menu_overlay.hide()
	scene.is_score_sheet_visible = true
	scene._refresh_score_sheet()
	scene.score_sheet_panel.show()
	for frame in 5:
		await process_frame
	assert(scene.score_sheet_title.get_theme_font_size("font_size") >= 44)
	assert(scene.score_sheet_panel.size.x >= scene.size.x - scene.PhoneTable.SAFE_LEFT - 40)
	assert(scene.score_sheet_close_button.size.x >= 88 and scene.score_sheet_close_button.size.y >= 76)
	assert(scene.score_sheet_close_button.get_theme_font_size("font_size") >= 48)
	assert(not scene.mobile_bid_menu_button.visible, "Bid action must be hidden while the modal score sheet is open")
	assert(scene.score_sheet_panel.z_index > scene.mobile_bid_menu_button.z_index)
	var first_row := scene.score_sheet_grid.get_child(0) as HBoxContainer
	var first_cell := first_row.get_child(0) as Label
	var mode_cell := first_row.get_child(1) as Label
	var cards_cell := first_row.get_child(2) as Label
	var first_player_group := first_row.get_child(4) as PanelContainer
	assert(first_cell.get_theme_font_size("font_size") >= 18)
	assert(first_cell.mouse_filter == Control.MOUSE_FILTER_IGNORE)
	assert(first_cell.size.x < mode_cell.size.x and cards_cell.size.x < mode_cell.size.x)
	assert(first_player_group.size.x >= 340.0, "Player results must receive the width saved by compact service columns")
	var score_bar: VScrollBar = scene.score_sheet_scroll.get_v_scroll_bar()
	assert(score_bar.max_value > score_bar.page, "Large phone score sheet must scroll")
	score_bar.value = score_bar.max_value
	var start := score_bar.value
	var point: Vector2 = scene.score_sheet_scroll.get_global_rect().get_center()
	_touch(point, true)
	_drag(point + Vector2(0, 150))
	_touch(point + Vector2(0, 150), false)
	assert(score_bar.value < start - 100, "Score sheet must scroll over its counting cells")
	scene.is_score_sheet_visible = false
	scene._refresh_score_sheet()
	assert(scene.mobile_bid_menu_button.visible, "Bid action must return after closing the score sheet")
	scene.first_turn_roll_panel.show()
	assert(scene.first_turn_roll_panel.size.x >= 1400 and scene.first_turn_roll_panel.size.y >= 700)
	assert(scene.first_turn_roll_title.get_theme_font_size("font_size") >= 52)
	scene.first_turn_roll_panel.hide()
	print("MOBILE_SCORE_SHEET_FIRST_ROLL_PASS")


func _check_network_bots() -> void:
	var host := LocalBotMatch.new()
	root.add_child(host)
	host.set_process(false)
	host._local_display_name = "HostTest"
	host._local_bot_player_indices.assign([1, 2, 3])
	host._fill_empty_seats_with_bots = true
	host._start_as_host()
	var names: Array[String] = []
	for index in range(1, 4):
		var player_name: String = host.match_host.game.players[index].display_name
		assert(player_name in SteamP2PMatch.BOT_NAMES)
		assert(not names.has(player_name), "A full bot table must use all three names")
		names.append(player_name)
		assert(host._avatar_index_by_player.has(index))
		assert(host.lobby_seats[index]["display_name"] == player_name)
	var original_seats: Array = host.lobby_seats.duplicate(true)
	host._rebuild_host_lobby_seats()
	assert(host.lobby_seats == original_seats, "Refreshing a room must not randomize bots again")
	host.free()
	print("NETWORK_STANDARD_BOT_NAMES_PASS")
