extends SceneTree

var scene: Variant

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	scene = load("res://Scenes/main.tscn").instantiate()
	scene.persistent_settings_writes_enabled = false
	scene.persistent_settings_path = "user://social_alignment_probe_%d.cfg" % Time.get_ticks_usec()
	scene.session_save_path = "user://social_alignment_probe_%d.save" % Time.get_ticks_usec()
	root.add_child(scene)
	await process_frame
	scene.set_process(false)
	scene._stop_background_music()
	scene.game.current_round.state = Round.State.BIDDING
	scene.first_turn_roll_panel.visible = false
	scene.menu_overlay.visible = false
	scene.social_controls_container.visible = true
	var buttons: Array[Button] = [scene.reaction_toggle_button, scene.sticker_toggle_button, scene.soundpad_toggle_button]
	for locale in ["en", "ru"]:
		scene.interface_locale = locale
		TranslationServer.set_locale(locale)
		scene._refresh_social_action_buttons()
		for show_gift in [false, true]:
			scene.reaction_toggle_button.visible = true
			scene.soundpad_toggle_button.visible = true
			scene.sticker_toggle_button.visible = show_gift
			scene.social_controls_container.visible = true
			scene.social_controls_container.queue_sort()
			await process_frame
			await process_frame
			var centre_x: float = scene.reaction_toggle_button.get_global_rect().get_center().x
			for button in buttons:
				assert(button.custom_minimum_size == Vector2(36.0, 34.0))
				if not button.visible:
					continue
				assert(button.size.is_equal_approx(Vector2(36.0, 34.0)), "Desktop social buttons must have matching hit areas")
				assert(is_equal_approx(button.get_global_rect().get_center().x, centre_x), "Social button centres must align")
				assert(button.alignment == HORIZONTAL_ALIGNMENT_CENTER, "Text must be centred")
				if button.icon != null:
					assert(button.icon_alignment == HORIZONTAL_ALIGNMENT_CENTER, "Texture icons must be centred, not left-aligned")
				scene._on_bare_social_icon_hover(button, true)
				assert(is_equal_approx(button.get_global_rect().get_center().x, centre_x), "Hover must preserve the centre")
				scene._on_bare_social_icon_hover(button, false)
			var top_rect: Rect2 = scene.reaction_toggle_button.get_global_rect()
			var bottom_rect: Rect2 = scene.soundpad_toggle_button.get_global_rect()
			assert(not top_rect.intersects(bottom_rect), "Top %s bottom %s stack visible %s top visible %s" % [top_rect, bottom_rect, scene.social_controls_container.is_visible_in_tree(), scene.reaction_toggle_button.is_visible_in_tree()])
			if show_gift:
				var gift_rect: Rect2 = scene.sticker_toggle_button.get_global_rect()
				assert(is_equal_approx(gift_rect.position.y - top_rect.end.y, bottom_rect.position.y - gift_rect.end.y), "Stack spacing must be uniform")
	assert(scene.soundpad_toggle_button.icon != null)
	assert(scene.reaction_toggle_button.text == "☺")
	scene.mobile_table_layout = true
	scene._apply_mobile_table_layout()
	scene._refresh_social_action_buttons()
	assert(scene.reaction_toggle_button.text == tr("Смайлы"))
	assert(scene.sticker_toggle_button.text == tr("Подарок"))
	assert(scene.soundpad_toggle_button.text == tr("Саундбар"))
	assert(scene.soundpad_toggle_button.icon == null)
	scene.queue_free()
	await process_frame
	await process_frame
	print("SOCIAL_ICON_ALIGNMENT_TEST_PASS")
	quit()
