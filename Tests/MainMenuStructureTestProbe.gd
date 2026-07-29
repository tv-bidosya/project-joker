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


func _get_buttons(root_control: Node) -> Array[Button]:
	var result: Array[Button] = []
	for child in root_control.get_children():
		if child is Button:
			result.append(child as Button)
		result.append_array(_get_buttons(child))
	return result
