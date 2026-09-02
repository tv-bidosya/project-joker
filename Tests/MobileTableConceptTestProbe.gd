extends SceneTree
class MobileStartup extends "res://Scripts/core/GameManager.gd":
	func _apply_mobile_table_layout() -> void:
		mobile_table_layout = true
		super()
func _init() -> void:
	call_deferred("_run")
func _run() -> void:
	var scene: Variant = load("res://Scenes/main.tscn").instantiate()
	scene.set_script(MobileStartup)
	scene.persistent_settings_writes_enabled = false
	scene.session_save_path = "user://phone_concept_probe.save"
	root.add_child(scene)
	await process_frame
	scene.set_process(false)
	scene._stop_background_music()
	scene._reset_game_session()
	scene.menu_overlay.hide()
	scene.first_turn_roll_panel.hide()
	scene.stage_announcement_overlay.hide()
	scene.game.current_round.state = Round.State.PLAYING
	scene.game.current_round.current_player_index = 0
	scene.game.current_round.lead_player_index = 0
	scene.game.cards_are_dealt = true
	scene.auto_turn_enabled = false
	for index in 9:
		scene.game.players[0].hand.append(scene._create_card(Card.Suit.CLUBS, Card.Rank.SIX + index, false))
	scene._refresh_ui()
	for frame in 8:
		await process_frame
	print("HAND ", scene.hand_container.get_global_rect(), " sep=", scene.hand_container.get_theme_constant("separation"))
	for slot in 4:
		print("PLAYER ", slot, " ", scene.player_panels[slot].get_global_rect(), " min=",scene.player_panels[slot].get_combined_minimum_size())
		print("AVATAR ", slot, " ", scene.avatar_badges[slot].get_global_rect())
		print("TRICK ", slot, " ", scene.trick_card_views[slot].get_global_rect())
	print("ACTION ",scene.action_label.get_global_rect()," HINT ",scene._get_mobile_card_drop_hint_rect())
	print("SOCIAL ",scene.social_controls_container.get_global_rect())
	for slot in [0, 2]:
		scene._place_table_marker(scene.lead_marker, slot, false)
		var lead_rect: Rect2 = scene.lead_marker.get_global_rect()
		scene._place_table_marker(scene.dealer_marker, slot, true)
		var dealer_rect: Rect2 = scene.dealer_marker.get_global_rect()
		var avatar_rect: Rect2 = scene.avatar_badges[slot].get_global_rect()
		assert(is_equal_approx(avatar_rect.position.x - lead_rect.end.x, 12.0), "Lead marker must sit just left of the avatar")
		if slot == 0:
			assert(is_equal_approx(avatar_rect.position.x - dealer_rect.end.x, 12.0), "Local dealer marker must take the old lead position beside the avatar")
			assert(lead_rect.position.y >= dealer_rect.end.y + 32.0, "Local lead marker must move below the dealer marker")
			assert(lead_rect.end.y <= scene.hand_container.get_global_rect().position.y - 12.0, "Local lead marker must clear the hand")
			assert(not lead_rect.intersects(avatar_rect) and not lead_rect.intersects(scene.player_panels[0].get_global_rect()))
		else:
			assert(is_equal_approx(lead_rect.position.x - dealer_rect.end.x, 12.0), "Dealer marker must sit further left without overlapping the lead marker")
	var deck_rect: Rect2 = scene.deck_visual.get_global_rect()
	print("DECK ", deck_rect, " scale=", scene.deck_visual.scale)
	assert(scene.deck_visual.scale.is_equal_approx(Vector2(1.25, 1.25)))
	assert(deck_rect.end.y <= scene.player_panels[3].get_global_rect().position.y, "Enlarged deck must clear the right player")
	print("LEFT ",scene.undo_button.get_global_rect()," ",scene.mobile_sort_button.get_global_rect()," BID ",scene.mobile_bid_menu_button.get_global_rect())
	for card in scene.hand_container.get_children():
		assert(card.size == scene.PhoneTable.HAND_CARD)
		for button in [scene.undo_button, scene.mobile_sort_button]:
			assert(not card.get_global_rect().intersects(button.get_global_rect()),"Hand must avoid corner actions")
	var first: CardView = scene.hand_container.get_child(0)
	var next: CardView = scene.hand_container.get_child(1)
	var point := Vector2((first.global_position.x + next.global_position.x) * 0.5, first.global_position.y + 40)
	assert(scene.mobile_hand_input._card_at(point) == first, "Exposed rank corner must select its own card")
	scene.mobile_hand_input.selected_key = scene.mobile_hand_input._key(first)
	scene.mobile_hand_input._sync_selection()
	assert(scene.mobile_hand_input._card_at(first.get_global_rect().get_center()) == first, "Raised card wins hit testing")
	scene._on_mobile_sort_pressed()
	assert(scene.hand_sort_mode == scene.HandSortMode.TRUMPS_LEFT)
	assert(scene.mobile_sort_button.text == tr("SORT_TRUMPS_LEFT"))
	assert(not scene.hand_sort_by_suit_button.visible and not scene.hand_sort_trumps_left_button.visible)
	print("PHONE_CONCEPT_HAND_AND_SORT_PASS")
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	for width in [1920, 2160, 2400]:
		root.size = Vector2i(width, 1080)
		for frame in 12:
			await process_frame
		for locale in ["en", "ru", "uk", "pl", "be", "kz"]:
			TranslationServer.set_locale(locale)
			scene._refresh_localized_interface()
			scene.local_match_mode = SteamBridge.MATCH_MODE_TEAMS_2V2
			scene._relayout_phone_table()
			scene._refresh_player_panels()
			for frame in 8:
				await process_frame
			var screen: Rect2 = scene.get_viewport_rect()
			for slot in 4:
				assert(screen.encloses(scene.player_panels[slot].get_global_rect()), "Player panels must remain on screen")
				assert(scene.player_stats_labels[slot].get_content_width() <= scene.player_stats_labels[slot].size.x + 1, "Translated stats must fit compact panels")
				if slot == 1 or slot == 3:
					var score_label: Label = scene.player_score_labels[slot]
					var score_font := score_label.get_theme_font("font")
					var score_width := score_font.get_string_size(score_label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, score_label.get_theme_font_size("font_size")).x
					assert(score_width <= score_label.size.x + 1, "Translated team name must fit the widened side panel")
				for other in 4:
					assert(not scene.trick_card_views[slot].get_global_rect().intersects(scene.player_panels[other].get_global_rect()), "Played cards must avoid every player panel")
				for other in range(slot + 1, 4):
					assert(not scene.trick_card_views[slot].get_global_rect().intersects(scene.trick_card_views[other].get_global_rect()))
			for card in scene.hand_container.get_children():
				assert(screen.encloses(card.get_global_rect()))
				for button in [scene.undo_button, scene.mobile_sort_button]:
					assert(not card.get_global_rect().intersects(button.get_global_rect()))
			assert(scene._get_mobile_card_drop_hint_rect().end.y <= scene.player_panels[0].get_global_rect().position.y, "Drop text must stay above the compact local player panel")
			assert(scene._get_mobile_card_drop_hint_rect().end.y <= scene.action_label.global_position.y)
			scene.tutorial_panel.show()
			for hint_key in ["TUTORIAL_HINT_DARK", "TUTORIAL_HINT_BID", "TUTORIAL_HINT_OTHER_BID", "TUTORIAL_HINT_LEAD", "TUTORIAL_HINT_REPLY", "TUTORIAL_HINT_OTHER_TURN", "TUTORIAL_HINT_FINISHED"]:
				scene.tutorial_text_label.text = tr(hint_key)
				scene.PhoneTable.rect(scene.tutorial_panel, Rect2(scene.PhoneTable.SAFE_LEFT, 536, minf(760, screen.size.x * 0.5 - 300), 218))
				for frame in 5:
					await process_frame
				assert(scene.tutorial_panel.get_global_rect().end.y <= scene.hand_container.global_position.y - 4, "Tutorial must clear the rank corners: " + locale + " " + hint_key)
				assert(not scene.tutorial_panel.get_global_rect().intersects(scene.avatar_badges[0].get_global_rect()))
		print("PHONE_CONCEPT_LOCALES_VIEWPORT_PASS ", scene.get_viewport_rect().size)
	scene.queue_free()
	await process_frame
	quit()
