extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var main_scene: Variant = load("res://Scenes/main.tscn").instantiate()
	root.add_child(main_scene)
	await process_frame

	main_scene.interface_locale = "ru"
	TranslationServer.set_locale("ru")
	main_scene._build_main_menu_content()
	await process_frame
	await process_frame
	assert(main_scene.menu_panel.size.y < 700.0, "The main menu panel must fit its actual content instead of leaving a large empty footer.")
	var main_menu_buttons := _get_button_texts(main_scene.menu_content)
	assert("Новая игра с ботами" in main_menu_buttons)
	assert("Играть по сети" in main_menu_buttons)
	assert("Обучение" in main_menu_buttons)
	assert("Профиль" in main_menu_buttons)
	assert("Статистика" in main_menu_buttons)
	assert("Настройки" in main_menu_buttons)
	assert("Инструменты разработчика" not in main_menu_buttons)
	assert("Правила" not in main_menu_buttons, "Rules must live inside the training section")
	assert(
		not _contains_label_fragment(main_scene.menu_content, "32 раздачи:"),
		"The obsolete round-list footer must not appear in the main menu"
	)
	var new_game_button := _find_button(main_scene.menu_content, "Новая игра с ботами")
	var tutorial_button := _find_button(main_scene.menu_content, "Обучение")
	assert(new_game_button != null and tutorial_button != null)
	var new_game_style := new_game_button.get_theme_stylebox("normal") as StyleBoxFlat
	var tutorial_style := tutorial_button.get_theme_stylebox("normal") as StyleBoxFlat
	assert(new_game_style != null and tutorial_style != null)
	assert(
		new_game_style.bg_color.is_equal_approx(tutorial_style.bg_color),
		"Main menu entries must all use the same neutral default style"
	)

	main_scene._show_new_game_setup()
	await process_frame
	assert(main_scene.new_game_name_inputs.size() == 4)
	var expected_avatar_indices: Array[int] = main_scene.configured_avatar_indices.duplicate()
	for player_index in expected_avatar_indices.size():
		var preview: Node = main_scene.menu_content.find_child(
			"NewGameAvatarPreview%d" % player_index,
			true,
			false
		)
		assert(preview != null)
		assert(int(preview.get_meta("avatar_index", -1)) == expected_avatar_indices[player_index])

	main_scene._show_tutorial_menu()
	var tutorial_buttons := _get_button_texts(main_scene.menu_content)
	assert("Правила игры" in tutorial_buttons)
	assert("Включить подсказки" not in tutorial_buttons)
	assert("Отключить подсказки" not in tutorial_buttons)
	assert(main_scene.menu_content.find_child("TutorialHintsToggle", true, false) is CheckButton)

	main_scene._show_settings_menu()
	await process_frame
	await process_frame
	assert(main_scene.menu_panel.size.y < 650.0, "The settings section must shrink to its last button.")
	var settings_buttons := _get_button_texts(main_scene.menu_content)
	for expected_section in ["Звук", "Оформление", "Игра", "Экран", "Язык"]:
		assert(expected_section in settings_buttons)
	assert(main_scene.menu_content.find_child("SoundVolumeSlider", true, false) == null)

	main_scene._show_sound_settings_menu()
	var sound_slider := main_scene.menu_content.find_child("SoundVolumeSlider", true, false) as HSlider
	var music_slider := main_scene.menu_content.find_child("MusicVolumeSlider", true, false) as HSlider
	assert(sound_slider != null and sound_slider.min_value == 0.0 and sound_slider.max_value == 100.0)
	assert(music_slider != null and music_slider.min_value == 0.0 and music_slider.max_value == 100.0)
	sound_slider.value = 73.0
	music_slider.value = 44.0
	assert(main_scene.sound_volume_percent == 73)
	assert(main_scene.music_volume_percent == 44)

	main_scene._show_game_settings_menu()
	assert(main_scene.menu_content.find_child("SettingsTutorialToggle", true, false) is CheckButton)
	assert(main_scene.menu_content.find_child("SettingsAutoTurnToggle", true, false) is CheckButton)

	main_scene._show_display_settings_menu()
	await process_frame
	await process_frame
	assert(main_scene.menu_panel.size.y < 760.0, "The display page must not keep the old fixed-height empty footer.")
	var scroll_content_left_margin: int = main_scene.menu_scroll_content_margin.get_theme_constant("margin_left")
	var scroll_content_right_margin: int = main_scene.menu_scroll_content_margin.get_theme_constant("margin_right")
	assert(scroll_content_left_margin >= 18)
	assert(scroll_content_left_margin == scroll_content_right_margin, "Menu controls must keep equal left and right spacing.")
	assert(main_scene.menu_content.find_child("FullscreenToggle", true, false) is CheckButton)
	var ui_theme_selector := main_scene.menu_content.find_child("MenuUiThemeSelector", true, false) as OptionButton
	assert(ui_theme_selector != null and ui_theme_selector.item_count == 2)
	assert(ui_theme_selector.get_item_text(0) == "Классический изумруд")
	assert(ui_theme_selector.get_item_text(1) == "Ночной город · синий")
	var classic_panel_style := main_scene.menu_panel.get_theme_stylebox("panel") as StyleBoxFlat
	var classic_panel_color := classic_panel_style.bg_color
	main_scene._on_menu_ui_theme_selected(1)
	await process_frame
	await process_frame
	ui_theme_selector = main_scene.menu_content.find_child("MenuUiThemeSelector", true, false) as OptionButton
	assert(ui_theme_selector != null and ui_theme_selector.selected == 1)
	var night_panel_style := main_scene.menu_panel.get_theme_stylebox("panel") as StyleBoxFlat
	assert(not night_panel_style.bg_color.is_equal_approx(classic_panel_color))
	assert(main_scene.menu_heading_font.resource_path.ends_with("Forum-Regular.ttf"))
	main_scene.menu_ui_theme = 0
	main_scene._refresh_menu_ui_theme()
	var background_selector := main_scene.menu_content.find_child("MenuBackgroundThemeSelector", true, false) as OptionButton
	assert(background_selector != null and background_selector.item_count == 4)
	assert(background_selector.get_item_text(0) == "Автоматически по времени")
	assert(background_selector.get_item_text(3) == "Ночной город")
	main_scene.menu_background_theme = 3
	main_scene._refresh_menu_background()
	assert(main_scene.menu_background_art.texture.resource_path == main_scene.MENU_BACKGROUND_NIGHT_CITY_TEXTURE_PATH)
	assert(main_scene.menu_background_effects.background_kind == 2)
	assert("Начать обучение заново" not in _get_button_texts(main_scene.menu_content))

	var settings_back_button := _find_button(main_scene.menu_content, "Назад к настройкам")
	assert(settings_back_button != null)
	settings_back_button.pressed.emit()
	assert("Звук" in _get_button_texts(main_scene.menu_content))

	main_scene._show_rules_menu(true)
	var rules_buttons := _get_buttons(main_scene.menu_content)
	var back_button: Button
	for button in rules_buttons:
		if button.text == "Назад":
			back_button = button
			break
	assert(back_button != null)
	back_button.pressed.emit()
	assert("Правила игры" in _get_button_texts(main_scene.menu_content))

	main_scene._show_online_hub(0, false)
	var online_open_buttons := _get_button_texts(main_scene.menu_content)
	assert("Открытые столы" in online_open_buttons)
	assert("Создать комнату" in online_open_buttons)
	assert("Мои игры" in online_open_buttons)
	assert("Обновить список" in online_open_buttons)

	main_scene._show_online_hub(1, false)
	var visibility_selector: OptionButton = main_scene.menu_content.find_child(
		"OnlineLobbyVisibilitySelector",
		true,
		false
	) as OptionButton
	assert(visibility_selector != null)
	assert(visibility_selector.item_count == 3)
	assert(visibility_selector.get_selected_id() == 1)

	main_scene.active_online_lobby_id = 123456789
	main_scene.active_online_match_started = true
	main_scene._show_online_hub(2, false)
	assert("Переподключиться к партии" in _get_button_texts(main_scene.menu_content))
	assert("Убрать из списка" in _get_button_texts(main_scene.menu_content))

	print("MAIN_MENU_STRUCTURE_TEST_PASS")
	quit()


func _get_button_texts(root_control: Node) -> Array[String]:
	var texts: Array[String] = []
	for button in _get_buttons(root_control):
		texts.append(button.text)
	return texts


func _get_label_texts(root_control: Node) -> Array[String]:
	var texts: Array[String] = []
	for child in root_control.get_children():
		if child is Label:
			texts.append((child as Label).text)
		texts.append_array(_get_label_texts(child))
	return texts


func _contains_label_fragment(root_control: Node, fragment: String) -> bool:
	for label_text in _get_label_texts(root_control):
		if fragment in label_text:
			return true
	return false


func _find_button(root_control: Node, button_text: String) -> Button:
	for button in _get_buttons(root_control):
		if button.text == button_text:
			return button
	return null


func _get_buttons(root_control: Node) -> Array[Button]:
	var result: Array[Button] = []
	for child in root_control.get_children():
		if child is Button:
			result.append(child as Button)
		result.append_array(_get_buttons(child))
	return result
