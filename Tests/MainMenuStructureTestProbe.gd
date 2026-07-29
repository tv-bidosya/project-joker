extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var main_scene: Variant = load("res://Scenes/main.tscn").instantiate()
	root.add_child(main_scene)
	await process_frame

	main_scene._build_main_menu_content()
	var main_menu_buttons := _get_button_texts(main_scene.menu_content)
	assert("Новая игра с ботами" in main_menu_buttons)
	assert("Играть по сети" in main_menu_buttons)
	assert("Обучение" in main_menu_buttons)
	assert("Профиль" in main_menu_buttons)
	assert("Статистика" in main_menu_buttons)
	assert("Настройки" in main_menu_buttons)
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
	var expected_avatar_indices := [
		main_scene.configured_avatar_indices[0],
		1,
		2,
		0,
	]
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
	var settings_buttons := _get_button_texts(main_scene.menu_content)
	for expected_section in ["Звук", "Оформление", "Игра", "Экран"]:
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
	assert(main_scene.menu_content.find_child("FullscreenToggle", true, false) is CheckButton)
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
