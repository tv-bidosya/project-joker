extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var scene: Variant = load("res://Scenes/main.tscn").instantiate()
	scene.persistent_settings_writes_enabled = false
	scene.session_save_path = "user://desktop_export_smoke.save"
	root.add_child(scene)
	await process_frame
	scene.set_process(false)
	assert(not scene.mobile_table_layout, "Desktop must not enable the mobile layout")
	assert(not is_instance_valid(scene.mobile_hand_input), "Desktop clicks must not use the touch controller")
	assert(not is_instance_valid(scene.mobile_top_bar))
	assert(scene.phase_label.get_parent() == scene.table_header)
	scene._reset_game_session()
	scene.menu_overlay.visible = false
	scene.first_turn_roll_panel.visible = false
	scene.stage_announcement_overlay.visible = false
	scene.game.current_round.state = Round.State.PLAYING
	scene.game.current_round.current_player_index = 0
	scene.game.current_round.lead_player_index = 0
	scene.game.cards_are_dealt = true
	scene.auto_turn_enabled = false
	var first: Card = scene._create_card(Card.Suit.CLUBS, Card.Rank.SEVEN, false)
	var second: Card = scene._create_card(Card.Suit.SPADES, Card.Rank.ACE, false)
	scene.game.players[0].hand.assign([first, second])
	scene._refresh_hand()
	await process_frame
	await process_frame
	var view: CardView
	for child in scene.hand_container.get_children():
		if child is CardView and child.displayed_card == first:
			view = child
	assert(view != null and not view.mobile_input_managed)
	assert(view.mouse_filter == Control.MOUSE_FILTER_STOP)
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.position = view.size / 2.0
	view._gui_input(click)
	scene.menu_overlay.visible = true
	assert(first not in scene.game.players[0].hand, "One desktop click must play the card")
	assert(scene.game.players[0].hand.size() == 1)
	while scene.is_processing_automatic_actions or scene.is_trick_presentation_active:
		await process_frame
	assert(scene._save_current_session())
	assert(scene._load_saved_session(), "Desktop session must load after saving")
	scene._delete_saved_session()
	scene.queue_free()
	await process_frame
	print("DESKTOP_EXPORT_SMOKE_TEST_PASS")
	quit()
