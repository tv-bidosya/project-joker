extends SceneTree

class MobileStartup extends "res://Scripts/core/GameManager.gd":
	func _apply_mobile_table_layout() -> void:
		mobile_table_layout = true
		super()

var scene: Variant

func _init() -> void:
	call_deferred("_run")

func _settle() -> void:
	for index in 6:
		await process_frame

func _check_controls(node: Node) -> void:
	assert(not (node is OptionButton or node is CheckButton), "Mobile settings must use explicit tiles")
	if node is Button and node.has_meta("mobile_toggle_tile"):
		var content: Control = node.get_child(0)
		assert(content.get_global_rect().end.y <= node.get_global_rect().end.y, "Toggle text must fit the tile")
	for child in node.get_children():
		_check_controls(child)

func _has_text(node: Node, text: String) -> bool:
	if node is Label and node.text == text:
		return true
	for child in node.get_children():
		if _has_text(child, text):
			return true
	return false


func _run() -> void:
	scene = load("res://Scenes/main.tscn").instantiate()
	scene.set_script(MobileStartup)
	scene.persistent_settings_writes_enabled = false
	scene.session_save_path = "user://mobile_settings_fullscreen_probe.save"
	root.add_child(scene)
	await _settle()
	scene.set_process(false)
	scene._stop_background_music()
	var pages: RefCounted = scene._mobile_settings()
	for locale in ["en", "ru", "uk", "pl", "be", "kz"]:
		TranslationServer.set_locale(locale)
		scene._refresh_localized_interface()
		for page in [pages.show_appearance, pages.show_decks, pages.show_felt, pages.show_surround, pages.show_game, pages.show_display]:
			page.call()
			await _settle()
			scene._fit_menu_panel_to_content()
			await _settle()
			_check_controls(scene.menu_content)
			var bar: VScrollBar = scene.menu_scroll.get_v_scroll_bar()
			print("SETTINGS_FIT ", locale, " ", page.get_method(), " scroll=", bar.max_value - bar.page)
			assert(bar.max_value - bar.page <= 1, "Settings tiles must fit without excess scrolling")
		pages.show_appearance()
		await _settle()
		for node in scene.menu_content.find_children("*", "Button", true, false):
			if not node.has_meta("mobile_setting_tile"):
				continue
			var content: VBoxContainer = node.get_child(0)
			assert(content.alignment == BoxContainer.ALIGNMENT_CENTER)
			var heading: Label = content.get_child(0)
			var value: Label = content.get_child(1)
			var text_center := (heading.global_position.y + value.get_global_rect().end.y) * 0.5
			assert(absf(text_center - node.get_global_rect().get_center().y) <= 2, "Appearance text block must be vertically centered")
		pages.show_decks()
		assert(not _has_text(scene.menu_content, tr("Предпросмотр")), "Preview must have no redundant heading")
		for first_launch in [false, true]:
			scene._show_language_settings_menu(first_launch)
			assert(not _has_text(scene.menu_content, tr("LANGUAGE_SUBTITLE")), "Language persistence details must stay hidden")
			assert(not _has_text(scene.menu_content, tr("LANGUAGE_CURRENT") % str(scene.INTERFACE_LOCALE_NAMES.get(scene.interface_locale, scene.interface_locale))))
		pages.show_game()
		await _settle()
		var toggle: Button = scene.menu_content.find_child("SettingsTutorialToggle", true, false)
		var previous: bool = scene.tutorial_enabled
		toggle.button_pressed = not previous
		assert(scene.tutorial_enabled != previous)
		var state: Label = toggle.find_child("SwitchState", true, false)
		assert(state.text == tr("MOBILE_TOGGLE_ON" if scene.tutorial_enabled else "MOBILE_TOGGLE_OFF"))
		var speed: Button = scene.menu_content.find_child("MobileBotSpeedChoicesChoice2", true, false)
		speed.button_pressed = true
		speed.pressed.emit()
		assert(scene.bot_speed_index == 2)
		for page in [scene._show_tutorial_menu, scene._show_rules_menu]:
			page.call()
			await _settle()
			scene._fit_menu_panel_to_content()
			await _settle()
			assert(scene.mobile_reading_page)
			assert(is_equal_approx(scene.menu_panel.size.y, scene.get_viewport_rect().size.y - 32))
		scene._show_profile_menu()
		await _settle()
		assert(not scene.profile_avatar_status_label.visible, "Built-in avatar details must stay hidden")
		scene._position_mobile_dock_buttons()
		await _settle()
		var dock_size: Vector2 = scene.undo_button.size
		for button in [scene.undo_button, scene.mobile_sort_button]:
			assert(button.size.is_equal_approx(dock_size), "Left buttons must be equal in every language")
			assert(button.get_theme_font_size("font_size") == 28)
		assert(scene.mobile_bid_menu_button.get_theme_font_size("font_size") == 34)
	scene._show_settings_menu()
	var retired_control: Control = scene.menu_content.get_child(0)
	scene._show_language_settings_menu()
	assert(retired_control.is_inside_tree() and not retired_control.is_visible_in_tree(), "Menu transition must not detach input targets during Android dispatch")
	assert(retired_control.process_mode == Node.PROCESS_MODE_DISABLED)
	await _settle()
	assert(not is_instance_valid(retired_control), "Retired menu content must be freed after dispatch")
	print("MOBILE_SETTINGS_READING_DOCK_PASS")
	assert(ProjectSettings.get_setting("display/window/stretch/aspect.android") == "expand")
	var artwork: Texture2D = load(scene.STUDIO_SPLASH_TEXTURE_PATH)
	assert(artwork.get_size() == Vector2(1280, 720))
	scene._show_studio_splash()
	await _settle()
	var splash: TextureRect = scene.find_child("FullscreenStudioArtwork", true, false)
	assert(splash != null and splash.stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_COVERED)
	assert(splash.size.is_equal_approx(scene.size))
	await create_timer(2.3).timeout
	print("FULLSCREEN_SPLASH_PASS")
	scene.queue_free()
	await process_frame
	quit()
