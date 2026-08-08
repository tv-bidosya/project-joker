extends SceneTree


const EXPECTED_MAIN_BUTTONS := {
	"uk": ["Нова гра з ботами", "Грати онлайн", "Навчання", "Профіль", "Статистика", "Налаштування", "Вийти"],
	"en": ["New game with bots", "Play online", "Tutorial", "Profile", "Statistics", "Settings", "Quit"],
	"pl": ["Nowa gra z botami", "Graj online", "Samouczek", "Profil", "Statystyki", "Ustawienia", "Wyjdź"],
	"be": ["Новая гульня з ботамі", "Гуляць анлайн", "Навучанне", "Профіль", "Статыстыка", "Налады", "Выйсці"],
	"kz": ["Боттармен жаңа ойын", "Желіде ойнау", "Үйрету", "Профиль", "Статистика", "Баптаулар", "Шығу"],
	"ru": ["Новая игра с ботами", "Играть по сети", "Обучение", "Профиль", "Статистика", "Настройки", "Выход"],
}


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var main_scene: Variant = load("res://Scenes/main.tscn").instantiate()
	assert(main_scene.interface_locale == "en", "English must be the built-in locale before saved settings are loaded")
	root.add_child(main_scene)
	await process_frame

	for locale_code in EXPECTED_MAIN_BUTTONS:
		main_scene.interface_locale = locale_code
		TranslationServer.set_locale(locale_code)
		main_scene._build_main_menu_content()
		var button_texts := _get_button_texts(main_scene.menu_content)
		for expected_text in EXPECTED_MAIN_BUTTONS[locale_code]:
			assert(
				expected_text in button_texts,
				"Main menu translation is missing for %s: %s" % [locale_code, expected_text]
			)

	main_scene.interface_locale = "uk"
	TranslationServer.set_locale("uk")
	main_scene._show_settings_menu()
	assert("Мова" in _get_button_texts(main_scene.menu_content))
	main_scene._show_language_settings_menu(false)
	var language_buttons := _get_button_texts(main_scene.menu_content)
	for language_name in ["Українська", "English", "Polski", "Беларуская", "Қазақша", "Русский · прототип"]:
		assert(language_name in language_buttons)

	main_scene._on_interface_locale_selected("pl-PL", false)
	assert(main_scene.interface_locale == "pl")
	assert(TranslationServer.get_locale().begins_with("pl"))
	var saved_config := ConfigFile.new()
	assert(saved_config.load(main_scene.PERSISTENT_SETTINGS_PATH) == OK)
	assert(str(saved_config.get_value("localization", "locale", "")) == "pl")
	assert(bool(saved_config.get_value("localization", "chosen", false)))

	print("LOCALIZATION_MENU_TEST_PASS")
	quit()


func _get_button_texts(container: Node) -> Array[String]:
	var result: Array[String] = []
	for child in container.get_children():
		if child is Button:
			result.append((child as Button).text)
	return result
