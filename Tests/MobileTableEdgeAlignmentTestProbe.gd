extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var scene: Variant = load("res://Scenes/main.tscn").instantiate()
	scene.persistent_settings_writes_enabled = false
	root.add_child(scene)
	await process_frame
	scene.set_process(false)
	scene.mobile_table_layout = true
	scene._apply_mobile_table_layout()
	scene.menu_overlay.visible = false

	for locale in ["ru", "en", "uk", "pl", "be", "kz"]:
		TranslationServer.set_locale(locale)
		scene._refresh_localized_interface()
		await process_frame
		await process_frame
		var bar_rect: Rect2 = scene.mobile_top_bar.get_global_rect()
		assert(absf(scene.phase_label.get_global_rect().get_center().x - bar_rect.get_center().x) <= 0.5, "Phase text must stay at the exact table center in every locale")
		assert(scene.phase_label.horizontal_alignment == HORIZONTAL_ALIGNMENT_CENTER)
		assert(scene.phase_label.get_global_rect().end.x < scene.trump_label.global_position.x, "Trump text must not overlap the centered phase")
		var history_rect: Rect2 = scene.round_history_toggle_button.get_global_rect()
		var menu_rect: Rect2 = scene.pause_menu_button.get_global_rect()
		assert(is_equal_approx(history_rect.position.x - bar_rect.position.x, bar_rect.end.x - menu_rect.end.x), "Left and right buttons must have equal edge insets")
		assert(is_equal_approx(bar_rect.end.x - menu_rect.end.x, 12.0), "Menu must sit at the right inner edge")
		assert(not scene.score_sheet_toggle_button.text.contains("📋"), "Invisible clipboard glyph must not reserve blank space")
		if locale == "ru":
			assert(scene.score_sheet_toggle_button.text == "Расписка")
		for button in [scene.round_history_toggle_button, scene.score_sheet_toggle_button, scene.pause_menu_button]:
			assert(bar_rect.encloses(button.get_global_rect()), "Top actions must stay inside the bar")
			assert(is_equal_approx(button.size.x, button.get_combined_minimum_size().x), "Buttons must fit their text without extra blank width")
			assert(button.alignment == HORIZONTAL_ALIGNMENT_CENTER, "Button labels must be centered")
			for state in ["normal", "hover", "pressed", "disabled"]:
				var style: StyleBoxFlat = button.get_theme_stylebox(state)
				assert(style.content_margin_left == 8.0 and style.content_margin_right == 8.0, "All top actions must have identical balanced padding")
		assert(scene.table_header.get_global_rect().end.x < scene.score_sheet_toggle_button.global_position.x, "Status labels must not overlap right-hand actions")
	print("MOBILE_TOP_EDGE_ALIGNMENT_PASS")

	for count in [1, 2, 3]:
		for player_index in [1, 2, 3]:
			scene.game.players[player_index].hand.clear()
			for card_index in count:
				scene.game.players[player_index].hand.append(scene._create_card(Card.Suit.CLUBS, Card.Rank.SEVEN, false))
		scene._refresh_bot_card_backs()
		await process_frame
		_check_card_gaps(scene, count)
		for viewer_index in 4:
			var players := {}
			for player_index in 4:
				players[player_index] = {"cards_in_hand": count}
			scene._refresh_network_main_card_backs(players, viewer_index)
			await process_frame
			_check_card_gaps(scene, count)
	print("MOBILE_CARD_BACK_GAPS_PASS")
	scene.queue_free()
	await process_frame
	print("MOBILE_TABLE_EDGE_ALIGNMENT_TEST_PASS")
	quit()


func _check_card_gaps(scene: Variant, count: int) -> void:
	for slot in [1, 2, 3]:
		var holder: Control = scene.bot_card_back_holders[slot - 1]
		var left_edge := INF
		var right_edge := -INF
		var visible_count := 0
		for card_back in holder.get_children():
			if card_back.visible:
				visible_count += 1
				left_edge = minf(left_edge, card_back.get_global_rect().position.x)
				right_edge = maxf(right_edge, card_back.get_global_rect().end.x)
		assert(visible_count == count)
		var panel_rect: Rect2 = scene.player_panels[slot].get_global_rect()
		var gap := panel_rect.position.x - right_edge if slot == 3 else left_edge - panel_rect.end.x
		assert(is_equal_approx(gap, 4.0), "Slot %d with %d cards must retain the same four-pixel gap, got %s" % [slot, count, gap])