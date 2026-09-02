extends SceneTree

const TEST_SAVE := "user://mobile_menu_regression.save"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var scene: Variant = load("res://Scenes/main.tscn").instantiate()
	scene.persistent_settings_writes_enabled = false
	scene.session_save_path = TEST_SAVE
	root.add_child(scene)
	await process_frame
	scene.mobile_table_layout = true
	scene._apply_mobile_table_layout()
	TranslationServer.set_locale("ru")
	scene._reset_game_session()
	assert(not scene.is_round_history_visible, "New sessions must hide history")

	for build_page in [
		scene._show_settings_menu,
		scene._show_language_settings_menu,
		scene._show_sound_settings_menu,
		scene._show_appearance_settings_menu,
		scene._show_game_settings_menu,
		scene._show_display_settings_menu,
		scene._show_tutorial_menu,
		scene._show_profile_menu,
		scene._show_new_game_setup,
		scene._show_end_session_confirmation,
		scene._show_save_and_menu_confirmation,
		scene._build_pause_menu_content,
	]:
		scene.menu_overlay.visible = true
		build_page.call()
		await process_frame
		await process_frame
		scene._fit_menu_panel_to_content()
		assert(_check_tiles(scene.menu_content), "Mobile menu must use readable tiles")
		assert(scene.menu_panel.size.x >= 1200.0, "Mobile menu must fit three tiles")
		assert(scene.menu_panel.size.y <= scene.get_viewport_rect().size.y - (32.0 if scene.mobile_reading_page else 64.0), "Menu must stay on screen")
	print("MOBILE_MENU_TILES_PASS")

	scene._reset_game_session()
	scene.menu_overlay.visible = false
	scene.game.dealer_index = 0
	assert(scene.game.start_round(3, Round.RoundType.NORMAL, Round.TrumpSuit.HEARTS))
	scene._advance_automatic_actions()
	assert(scene.is_processing_automatic_actions, "Test must pause an in-flight bot action")
	scene._on_pause_menu_pressed()
	var saved_game: Dictionary = scene._create_session_save_data()["game"]
	scene.turn_timer_active = true
	scene.auto_turn_enabled = true
	scene.turn_timer_remaining = 30.0
	scene.network_round_countdown_active = true
	scene.network_round_countdown_remaining_seconds = 10.0
	scene._process(5.0)
	assert(scene.turn_timer_remaining == 30.0, "Pause must freeze the local turn timer")
	assert(scene.network_round_countdown_remaining_seconds == 10.0, "Pause must freeze next-round countdown")
	await scene._save_and_return_to_main_menu()
	assert(scene.menu_overlay.visible and not scene.is_pause_menu_open, "Save exit must reach main menu")
	assert(scene._has_saved_session(), "Save exit must preserve a file")
	assert(scene.game.current_round.state == Round.State.SETUP, "Game must not keep running in the menu")
	assert(scene._load_saved_session(), "Saved party must restore from disk")
	assert(scene._create_session_save_data()["game"] == saved_game, "Cards, bids, scores and turn must survive menu exit")
	assert(not scene.is_round_history_visible, "Resume must not open the old history panel")
	scene.is_round_history_visible = true
	assert(scene._save_current_session())
	scene._reset_game_session()
	assert(scene._load_saved_session())
	assert(not scene.is_round_history_visible, "Legacy visible history must remain collapsed on mobile")
	print("MOBILE_SAVE_AND_MENU_PASS")

	scene.set_process(false)
	scene.menu_overlay.visible = false
	var rows := PackedStringArray()
	for index in 4:
		rows.append(scene._format_round_result_bbcode("Игрок %d" % index, 3, 2, -10, 30, true))
	scene.round_results_panel.visible = true
	scene.next_round_button.visible = true
	scene.round_results_label.text = "\n".join(rows)
	scene._fit_round_results_panel(scene.round_results_label.get_parsed_text())
	await process_frame
	await process_frame
	scene._position_round_results_actions()
	assert(not scene.round_results_label.scroll_active, "Ordinary results must fit without scrolling")
	assert(scene.round_results_panel.size.x >= 1000.0, "Mobile results must be wider")
	assert(scene.round_results_label.get_theme_font_size("normal_font_size") >= 24, "Mobile result text must be readable")
	assert(scene.next_round_button.size.x >= 460.0 and scene.next_round_button.size.y >= 84.0, "Next-round button must be easy to tap")
	assert(scene.next_round_button.global_position.y >= scene.round_results_panel.get_global_rect().end.y + 9.0, "Results and next button must not overlap")
	assert(not scene.next_round_button.get_global_rect().intersects(scene.player_panels[0].get_global_rect()), "Next button must not cover the local player")
	print("MOBILE_RESULTS_RECT=", scene.round_results_panel.get_global_rect())
	print("MOBILE_NEXT_BUTTON_RECT=", scene.next_round_button.get_global_rect())
	rows.clear()
	for index in 4:
		rows.append(scene._format_round_result_bbcode("ОченьДлинноеИмяИгрока%d" % index, 13, 11, -100, 12345, true))
	rows.append("[center]Команда 1 · общий счёт 12345[/center]")
	rows.append("[center]Команда 2 · общий счёт 54321[/center]")
	scene.round_results_label.text = "\n".join(rows)
	scene._fit_round_results_panel(scene.round_results_label.get_parsed_text())
	await process_frame
	await process_frame
	scene._position_round_results_actions()
	for index in [0, 2]:
		assert(not scene.round_results_panel.get_global_rect().intersects(scene.player_panels[index].get_global_rect()), "Results must leave the top and local players visible")
	assert(not scene.next_round_button.get_global_rect().intersects(scene.player_panels[0].get_global_rect()), "Long/team results button must stay above local player")
	print("MOBILE_LONG_RESULTS_RECT=", scene.round_results_panel.get_global_rect())
	rows.clear()
	for index in 4:
		rows.append(scene._format_round_result_bbcode("Игрок %d" % index, 1, 1, 10, 40, true))
	scene.round_results_label.text = "\n".join(rows)
	scene._fit_round_results_panel(scene.round_results_label.get_parsed_text())
	await process_frame
	await process_frame
	scene._position_round_results_actions()
	assert(not scene.round_results_label.scroll_active, "Short results must stop scrolling after long results")
	assert(scene.round_results_panel.size.y < 300.0, "Short results must shrink again")
	scene._delete_saved_session()
	scene.queue_free()
	await process_frame
	print("MOBILE_MENU_RESULTS_TEST_PASS")
	quit()


func _check_tiles(node: Node) -> bool:
	for child in node.get_children():
		if child is Button and not (child is OptionButton or child is CheckButton) and child.name != "MobileProfileAvatarPreview":
			if not child.has_meta("mobile_menu_tile"):
				push_error("Old strip button remains: %s" % child.text)
				return false
			if child.get_meta("mobile_setting_tile", false):
				continue
			if child.custom_minimum_size != (Vector2(270, 96) if child.get_meta("mobile_small_action_tile", false) else (Vector2(255.0, 162.0) if child.get_meta("mobile_compact_tile", false) else Vector2(300.0, 190.0))):
				push_error("Incorrect tile size: %s" % child.text)
				return false
		if not _check_tiles(child):
			return false
	return true