extends SceneTree

var scene: Variant
var cyrillic := RegEx.new()
var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	cyrillic.compile("[А-Яа-яЁё]")
	TranslationServer.set_locale("ru")
	scene = load("res://Scenes/main.tscn").instantiate()
	scene.persistent_settings_writes_enabled = false
	scene.persistent_settings_path = "user://locale_export_probe_%d.cfg" % Time.get_ticks_usec()
	scene.session_save_path = "user://locale_export_probe_%d.save" % Time.get_ticks_usec()
	root.add_child(scene)
	await process_frame
	scene.set_process(false)
	assert(scene.interface_locale == "en" and TranslationServer.get_locale().begins_with("en"), "Fresh install must start in English even with a Russian system locale")
	assert(not scene.interface_locale_was_chosen)
	var config := ConfigFile.new()
	config.set_value("localization", "locale", "ru")
	config.set_value("localization", "chosen", true)
	assert(config.save(scene.persistent_settings_path) == OK)
	scene._load_persistent_settings()
	assert(scene.interface_locale == "en", "Legacy automatic locale must not override English")
	scene.persistent_settings_writes_enabled = true
	scene._on_interface_locale_selected("uk", false)
	scene._load_persistent_settings()
	assert(scene.interface_locale == "uk" and scene.interface_locale_was_chosen, "Explicit language choice must survive restart")
	scene.persistent_settings_writes_enabled = false
	print("FRESH_ENGLISH_AND_SAVED_LANGUAGE_PASS")
	for locale in ["en", "uk", "pl", "be", "kz", "ru"]:
		scene.interface_locale = locale
		TranslationServer.set_locale(locale)
		for key in ["SEASON_SPRING", "SEASON_SUMMER", "SEASON_AUTUMN", "SEASON_WINTER", "SEASON_RATING_SUMMARY", "SEASON_WIN_LOSS"]:
			assert(tr(key) != key, "Missing localized key: %s / %s" % [locale, key])
		scene._build_pause_menu_content()
		var texts := _texts(scene.menu_content)
		assert(tr("В главное меню") in texts)
		_assert_no_player_button(texts)
		if locale == "en":
			_assert_english("pause")
		scene._build_network_pause_menu_content()
		if locale == "en":
			_assert_english("network pause")
		_assert_no_player_button(_texts(scene.menu_content))
		scene._show_save_and_menu_confirmation()
		assert(tr("Сохранить и выйти") in _texts(scene.menu_content))
		if locale == "en":
			_assert_english("save confirmation")
		scene._show_end_session_confirmation()
		if locale == "en":
			_assert_english("end confirmation")
		scene._ensure_current_season_statistics()
		scene.local_statistics["season_games"] = 4
		scene.local_statistics["season_total_games"] = 8
		scene.local_statistics["season_points"] = 9.5
		scene.local_statistics["season_mvp"] = 1
		scene.local_statistics["season_wins"] = 2
		scene.local_statistics["season_losses"] = 2
		for completed in [0, 4]:
			scene.local_statistics["completed_games"] = completed
			scene._show_statistics_menu()
			texts = _texts(scene.menu_content)
			var rating: float = scene._calculate_season_rating(9.5, 4, 1, 8)
			assert((tr("SEASON_RATING_SUMMARY") % [rating, 9.5, 4, 1]) in texts)
			assert((tr("SEASON_WIN_LOSS") % [2, 2]) in texts)
			assert(scene._get_current_season_name() in texts)
			if locale == "en":
				_assert_english("statistics")
		scene._show_profile_menu()
		assert(tr("Статистика и рейтинг") in _texts(scene.menu_content))
		if locale == "en":
			_assert_english("profile")
		scene._show_display_settings_menu()
		assert(scene.menu_content.find_child("MusicPlayerVisibleToggle", true, false) != null, "Audio player visibility must remain in Display settings")
		await process_frame
	print("SIX_LOCALE_STATISTICS_AND_PAUSE_PASS")
	scene.mobile_table_layout = true
	scene._apply_mobile_table_layout()
	scene.interface_locale = "en"
	TranslationServer.set_locale("en")
	scene._build_pause_menu_content()
	_assert_english("mobile pause")
	assert("MAIN MENU" in _texts(scene.menu_content))
	_assert_no_player_button(_texts(scene.menu_content))
	scene._show_statistics_menu()
	_assert_english("mobile statistics")
	scene._show_save_and_menu_confirmation()
	_assert_english("mobile save confirmation")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(scene.persistent_settings_path))
	scene.queue_free()
	await process_frame
	if not failures.is_empty():
		for failure in failures:
			push_error(failure)
		quit(1)
		return
	print("FRIENDS_EXPORT_LOCALIZATION_TEST_PASS")
	quit()

func _texts(node: Node) -> Array[String]:
	var result: Array[String] = []
	for child in node.get_children():
		if child is Label or child is Button:
			result.append(child.text)
		elif child is RichTextLabel:
			result.append(child.get_parsed_text())
		result.append_array(_texts(child))
	return result

func _assert_no_player_button(texts: Array[String]) -> void:
	assert(tr("Скрыть аудиоплеер") not in texts and tr("Показать аудиоплеер") not in texts, "Pause must not duplicate the audio-player setting")

func _assert_english(page: String) -> void:
	for label in _texts(scene.menu_content):
		if cyrillic.search(label) != null:
			failures.append("Untranslated Russian on %s: %s" % [page, label])
