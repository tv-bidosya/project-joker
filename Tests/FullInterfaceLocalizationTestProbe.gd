extends SceneTree


var failures: PackedStringArray = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var main_scene: Variant = load("res://Scenes/main.tscn").instantiate()
	root.add_child(main_scene)
	await process_frame

	main_scene._on_interface_locale_selected("en", false)
	await process_frame
	_check(main_scene.phase_label.text == "Stage: preparation", "English phase: %s" % main_scene.phase_label.text)
	_check(main_scene.action_label.text == "Preparing the game", "English action: %s" % main_scene.action_label.text)
	_check(main_scene.score_sheet_toggle_button.text == "📋 Score sheet", "English score sheet: %s" % main_scene.score_sheet_toggle_button.text)
	_check(main_scene.round_history_toggle_button.text == "History", "English history: %s" % main_scene.round_history_toggle_button.text)
	_check(main_scene.hand_sort_by_suit_button.text == "By suit", "English suit sort: %s" % main_scene.hand_sort_by_suit_button.text)
	_check(main_scene.hand_sort_trumps_left_button.text == "Trumps left", "English trump sort: %s" % main_scene.hand_sort_trumps_left_button.text)
	_check(main_scene.undo_button.text == "↶ Undo move", "English undo: %s" % main_scene.undo_button.text)

	main_scene.game.current_round.state = Round.State.BIDDING
	main_scene.game.current_round.number = 1
	main_scene.game.current_round.current_player_index = 0
	main_scene.game.current_round.round_type = Round.RoundType.NORMAL
	main_scene.game.current_round.trump = Round.TrumpSuit.RANDOM
	main_scene._relocalize_current_action_text()
	main_scene._refresh_ui()
	await process_frame
	_check(main_scene.phase_label.text.begins_with("Round "), "English active-round header: %s" % main_scene.phase_label.text)
	_check("Bid" in main_scene.player_stats_labels[0].get_parsed_text(), "English bid stats: %s" % main_scene.player_stats_labels[0].get_parsed_text())
	_check("Taken" in main_scene.player_stats_labels[0].get_parsed_text(), "English taken stats: %s" % main_scene.player_stats_labels[0].get_parsed_text())
	_check(main_scene.action_label.text.contains("bid"), "English active action: %s" % main_scene.action_label.text)

	main_scene._show_sound_settings_menu()
	var english_settings := _get_visible_texts(main_scene.menu_content)
	for expected_text in ["Sound", "Game sounds", "Music", "Back to settings"]:
		_check(expected_text in english_settings, "Missing English settings text: %s" % expected_text)

	main_scene._show_new_game_setup()
	var english_setup := _get_visible_texts(main_scene.menu_content)
	for expected_text in ["New game with bots", "Start game", "Bot difficulty", "History"]:
		_check(expected_text in english_setup, "Missing English setup text: %s" % expected_text)

	main_scene._on_interface_locale_selected("uk", false)
	await process_frame
	for stats_label in main_scene.player_stats_labels:
		_check(
			stats_label.autowrap_mode == TextServer.AUTOWRAP_OFF,
			"Localized player stats must remain on one line."
		)
		_check(
			stats_label.get_content_width() <= stats_label.size.x + 1.0,
			"Ukrainian player stats overflow: content %.1f, available %.1f" % [
				stats_label.get_content_width(),
				stats_label.size.x
			]
		)
	var ukrainian_exact_result: String = main_scene._format_round_result_bbcode("admin1", 0, 0, 5, 10, true)
	var ukrainian_over_result: String = main_scene._format_round_result_bbcode("Лена", 0, 2, 2, 7, true)
	for expected_text in ["взято", "замовлення 0 виконано", "рахунок"]:
		_check(expected_text in ukrainian_exact_result, "Missing Ukrainian round-result text '%s': %s" % [expected_text, ukrainian_exact_result])
	_check("перебір 2 (замовлення 0)" in ukrainian_over_result, "Ukrainian overbid result: %s" % ukrainian_over_result)
	for russian_fragment in ["заказ", "выполнен", "перебор", "счёт"]:
		_check(russian_fragment not in ukrainian_exact_result and russian_fragment not in ukrainian_over_result, "Russian round-result fragment remains: %s" % russian_fragment)
	_check(
		main_scene._localize_canonical_history_line("Олег заказывает 2.") == "Олег замовляє 2.",
		"Ukrainian localized bid history must preserve its numeric value."
	)

	main_scene.is_score_sheet_visible = true
	main_scene._refresh_score_sheet()
	var ukrainian_score_sheet := _get_visible_texts(main_scene.score_sheet_panel)
	for expected_text in ["Режим", "Карт", "Козир", "Замовлено", "Взято", "Δ рахунку", "Разом"]:
		_check(expected_text in ukrainian_score_sheet, "Missing Ukrainian score-sheet text: %s" % expected_text)
	_check(main_scene.score_sheet_title.text.begins_with("Розписка: зіграно"), "Ukrainian score-sheet title: %s" % main_scene.score_sheet_title.text)
	_check("Звичайна 1/13" in ukrainian_score_sheet, "Ukrainian normal-round label is missing.")
	_check("випадковий козир" in ukrainian_score_sheet, "Ukrainian random-trump label is missing.")
	for russian_fragment in ["Обычная", "случайный козырь", "Итого", "Счёт"]:
		_check(russian_fragment not in ukrainian_score_sheet, "Russian score-sheet fragment remains: %s" % russian_fragment)
	main_scene._refresh_network_main_score_sheet(
		{"completed_rounds": [], "players": []},
		{"number": 1, "trump": Round.TrumpSuit.RANDOM}
	)
	_check(main_scene.score_sheet_title.text.begins_with("Мережева розписка: зіграно"), "Ukrainian network score-sheet title: %s" % main_scene.score_sheet_title.text)
	var ukrainian_network_score_sheet := _get_visible_texts(main_scene.score_sheet_panel)
	_check("Звичайна 1/13" in ukrainian_network_score_sheet, "Ukrainian network score-sheet round label is missing.")
	_check("випадковий козир" in ukrainian_network_score_sheet, "Ukrainian network random-trump label is missing.")
	main_scene.is_score_sheet_visible = false
	main_scene._refresh_score_sheet()

	main_scene.music_is_paused = true
	main_scene._refresh_music_player()
	main_scene._refresh_music_controls_popup()
	_check(main_scene.music_popup_volume_title.text == "Гучність музики", "Ukrainian music volume title: %s" % main_scene.music_popup_volume_title.text)
	_check(main_scene.music_popup_repeat_button.text == "↻ Повтор: вимк", "Ukrainian repeat state: %s" % main_scene.music_popup_repeat_button.text)
	_check(main_scene.music_popup_shuffle_button.text == "⤨ Випадково: вимк", "Ukrainian shuffle state: %s" % main_scene.music_popup_shuffle_button.text)
	_check(main_scene.music_popup_folder_button.text == "📁 Додати папку", "Ukrainian add-folder button: %s" % main_scene.music_popup_folder_button.text)
	_check(main_scene.music_popup_clear_button.text == "Очистити власні", "Ukrainian clear button: %s" % main_scene.music_popup_clear_button.text)
	_check(main_scene.music_popup_playlist_title.text == "Плейлист", "Ukrainian playlist title: %s" % main_scene.music_popup_playlist_title.text)
	_check(main_scene.music_popup_search_input.placeholder_text == "Пошук за назвою", "Ukrainian playlist search: %s" % main_scene.music_popup_search_input.placeholder_text)
	_check(main_scene.music_play_pause_button.text == "▶ Грати", "Ukrainian play button: %s" % main_scene.music_play_pause_button.text)
	_check(main_scene._get_music_track_label_for_index(0) == "Тихий стіл", "Ukrainian built-in track title: %s" % main_scene._get_music_track_label_for_index(0))
	main_scene._sync_network_round_countdown({
		"next_round_auto_start_total_seconds": 30.0,
		"next_round_auto_start_remaining_seconds": 15.0,
		"completed_rounds": []
	}, "localization-countdown-test")
	_check(main_scene.round_results_countdown_border.visible, "The round-results countdown border must be visible.")
	_check(is_equal_approx(main_scene.round_results_countdown_border.remaining_ratio, 0.5), "The countdown border must represent remaining time.")
	main_scene._reset_network_round_countdown()

	main_scene._on_interface_locale_selected("kz", false)
	await process_frame
	for stats_label in main_scene.player_stats_labels:
		_check(
			stats_label.get_content_width() <= stats_label.size.x + 1.0,
			"Kazakh player stats overflow: content %.1f, available %.1f" % [
				stats_label.get_content_width(),
				stats_label.size.x
			]
		)
	_check(main_scene.phase_label.text.begins_with("Тарату "), "Kazakh phase: %s" % main_scene.phase_label.text)
	_check(main_scene.action_label.text.to_lower().contains("тапсырыс"), "Kazakh action: %s" % main_scene.action_label.text)
	_check(main_scene.score_sheet_toggle_button.text == "📋 Есеп кестесі", "Kazakh score sheet: %s" % main_scene.score_sheet_toggle_button.text)
	_check(main_scene.round_history_toggle_button.text == "Тарих", "Kazakh history: %s" % main_scene.round_history_toggle_button.text)
	_check(main_scene.hand_sort_by_suit_button.text == "Түсі бойынша", "Kazakh suit sort: %s" % main_scene.hand_sort_by_suit_button.text)

	main_scene._build_pause_menu_content()
	var kazakh_pause_menu := _get_visible_texts(main_scene.menu_content)
	_check("Баптаулар" in kazakh_pause_menu, "Kazakh pause-menu settings button is missing.")
	_check("Настройки" not in kazakh_pause_menu, "Russian settings button remains in the Kazakh pause menu.")

	main_scene._show_settings_menu()
	var kazakh_settings := _get_visible_texts(main_scene.menu_content)
	for expected_text in ["Баптаулар", "Дыбыс", "Безендіру", "Ойын", "Экран", "Тіл"]:
		_check(expected_text in kazakh_settings, "Missing Kazakh settings text: %s" % expected_text)

	if failures.is_empty():
		print("FULL_INTERFACE_LOCALIZATION_TEST_PASS")
		quit()
		return
	for failure in failures:
		push_error(failure)
	quit(1)


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _get_visible_texts(node: Node) -> Array[String]:
	var result: Array[String] = []
	for child in node.get_children():
		if child is Label:
			result.append((child as Label).text)
		elif child is Button:
			result.append((child as Button).text)
		result.append_array(_get_visible_texts(child))
	return result
