extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var main_scene: Variant = load("res://Scenes/main.tscn").instantiate()
	root.add_child(main_scene)
	await process_frame

	main_scene.game.dealer_index = 3
	assert(main_scene.game.start_round(1, Round.RoundType.NORMAL, Round.TrumpSuit.CLUBS))
	main_scene.menu_overlay.visible = false
	main_scene.is_pause_menu_open = false
	main_scene._refresh_ui()
	await process_frame

	for player_index in [0, 2]:
		main_scene._place_player_panel(main_scene.player_panels[player_index], player_index)
		main_scene._place_player_avatar_badge(main_scene.avatar_badges[player_index], player_index)
	await process_frame

	var bottom_avatar_rect: Rect2 = main_scene.avatar_badges[0].get_global_rect()
	var bottom_panel_rect: Rect2 = main_scene.player_panels[0].get_global_rect()
	var top_avatar_rect: Rect2 = main_scene.avatar_badges[2].get_global_rect()
	var top_panel_rect: Rect2 = main_scene.player_panels[2].get_global_rect()
	assert(is_equal_approx(bottom_panel_rect.position.x - bottom_avatar_rect.end.x, 7.0))
	assert(is_equal_approx(top_panel_rect.position.x - top_avatar_rect.end.x, 7.0))
	assert(is_equal_approx(bottom_panel_rect.size.x, 212.0))
	assert(is_equal_approx(top_panel_rect.size.x, 212.0))
	assert(bottom_panel_rect.size.y < bottom_avatar_rect.size.y)
	assert(top_panel_rect.size.y < top_avatar_rect.size.y)

	var social_rect: Rect2 = main_scene.social_controls_container.get_global_rect()
	assert(is_equal_approx(social_rect.position.x - bottom_panel_rect.end.x, 7.0))
	assert(main_scene.social_controls_container.mouse_filter == Control.MOUSE_FILTER_IGNORE)
	assert(
		is_equal_approx(main_scene.reaction_toggle_button.get_global_rect().position.x - bottom_panel_rect.end.x, 7.0),
		"The first visible social button must not keep an empty centered gutter."
	)
	main_scene._place_trick_slot(main_scene.trick_card_views[0], 0)
	await process_frame
	var bottom_trick_rect: Rect2 = main_scene.trick_card_views[0].get_global_rect()
	assert(not bottom_trick_rect.intersects(bottom_panel_rect))
	assert(bottom_panel_rect.position.y - bottom_trick_rect.end.y >= 16.0)

	for button: Button in [
		main_scene.reaction_toggle_button,
		main_scene.soundpad_toggle_button
	]:
		assert(button.visible, "Table social buttons must be visible during a round.")
		assert(button.get_parent() == main_scene.social_controls_container)
		assert(button.mouse_filter == Control.MOUSE_FILTER_STOP)
		assert(button.scale == Vector2.ONE)
		var button_rect := button.get_global_rect()
		assert(is_equal_approx(button_rect.size.x, 64.0))
		assert(is_equal_approx(button_rect.size.y, 50.0))
		for vertical_ratio in [0.25, 0.5, 0.75]:
			var visual_point := Vector2(
				button_rect.get_center().x,
				lerpf(button_rect.position.y, button_rect.end.y, vertical_ratio)
			)
			var local_point: Vector2 = button.get_global_transform().affine_inverse() * visual_point
			assert(
				Rect2(Vector2.ZERO, button.size).has_point(local_point),
				"The button's visible upper, middle and lower areas must map to its hitbox."
			)
	assert(not main_scene.sticker_toggle_button.visible, "The old global gift button must stay hidden.")
	main_scene._on_avatar_mute_hover_entered(1)
	assert(main_scene.avatar_gift_buttons[1].visible, "Gift access must move to the hovered avatar.")
	assert(main_scene.avatar_mute_buttons[1].visible, "Mute access must also appear for a local bot.")
	assert(main_scene.avatar_gift_buttons[1].get_theme_stylebox("normal") is StyleBoxEmpty, "Avatar gift action must not have a circular background.")
	assert(main_scene.avatar_mute_buttons[1].get_theme_stylebox("normal") is StyleBoxEmpty, "Avatar mute action must not have a circular background.")
	await create_timer(0.25).timeout
	var action_tray_rect: Rect2 = main_scene.avatar_action_trays[1].get_global_rect()
	var left_avatar_rect: Rect2 = main_scene.avatar_badges[1].get_global_rect()
	assert(action_tray_rect.end.y <= left_avatar_rect.position.y, "Avatar actions must slide out above the avatar.")
	main_scene._on_avatar_mute_hover_exited(1)
	await create_timer(0.2).timeout
	assert(main_scene.avatar_action_trays[1].visible, "Avatar actions must remain clickable during the hover grace period.")
	await create_timer(1.75).timeout
	assert(not main_scene.avatar_action_trays[1].visible, "Avatar actions must hide after the hover grace period.")

	main_scene._on_avatar_mute_hover_entered(1)
	main_scene._on_avatar_gift_button_pressed(1)
	assert(main_scene.sticker_picker.visible, "The avatar gift button must open the gift picker.")
	assert(not main_scene.sticker_picker_auto_close_timer.is_stopped(), "The open gift picker must start its idle close timer.")
	assert(is_equal_approx(main_scene.sticker_picker_auto_close_timer.wait_time, 5.0))
	await process_frame
	var sticker_picker_rect: Rect2 = main_scene.sticker_picker.get_global_rect()
	var soundpad_button_rect: Rect2 = main_scene.soundpad_toggle_button.get_global_rect()
	assert(
		is_equal_approx(sticker_picker_rect.position.x - soundpad_button_rect.end.x, 12.0),
		"The gift picker must use the empty space to the right of the soundpad."
	)
	assert(
		is_equal_approx(sticker_picker_rect.get_center().y, soundpad_button_rect.get_center().y),
		"The gift picker and soundpad button must share a vertical center."
	)
	assert(main_scene.sticker_picker_close_button.text == "×", "The gift picker must use a close button instead of a back arrow.")
	main_scene.sticker_picker_close_button.pressed.emit()
	assert(not main_scene.sticker_picker.visible, "The close button must dismiss the gift picker.")
	main_scene._on_avatar_gift_button_pressed(1)
	main_scene._on_avatar_gift_button_pressed(1)
	assert(not main_scene.sticker_picker.visible, "Pressing the same avatar gift button again must close the picker.")
	main_scene._on_avatar_gift_button_pressed(1)
	main_scene.sticker_picker_auto_close_timer.timeout.emit()
	assert(not main_scene.sticker_picker.visible, "The gift picker must close when its idle timer expires.")

	main_scene._place_table_marker(main_scene.dealer_marker, 0, true)
	var dealer_rect: Rect2 = main_scene.dealer_marker.get_global_rect()
	assert(bottom_avatar_rect.position.x - dealer_rect.end.x <= 6.0, "Dealer marker must sit close to the avatar.")

	print("TABLE_LAYOUT_HITBOX_TEST_PASS")
	quit()
