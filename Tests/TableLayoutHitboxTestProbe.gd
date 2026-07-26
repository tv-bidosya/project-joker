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

	var social_rect: Rect2 = main_scene.social_controls_container.get_global_rect()
	assert(is_equal_approx(social_rect.position.x - bottom_panel_rect.end.x, 7.0))
	assert(main_scene.social_controls_container.mouse_filter == Control.MOUSE_FILTER_IGNORE)
	main_scene._place_trick_slot(main_scene.trick_card_views[0], 0)
	await process_frame
	var bottom_trick_rect: Rect2 = main_scene.trick_card_views[0].get_global_rect()
	assert(not bottom_trick_rect.intersects(bottom_panel_rect))
	assert(bottom_panel_rect.position.y - bottom_trick_rect.end.y >= 16.0)

	for button: Button in [
		main_scene.reaction_toggle_button,
		main_scene.sticker_toggle_button,
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

	print("TABLE_LAYOUT_HITBOX_TEST_PASS")
	quit()
