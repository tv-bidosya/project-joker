extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var main_scene: Variant = load("res://Scenes/main.tscn").instantiate()
	root.add_child(main_scene)
	await process_frame

	var bot_player: Player = main_scene.game.players[1]
	bot_player.hand.clear()
	var unsafe_trump_king := Card.new()
	unsafe_trump_king.suit = Card.Suit.CLUBS
	unsafe_trump_king.rank = Card.Rank.KING
	var low_discard := Card.new()
	low_discard.suit = Card.Suit.HEARTS
	low_discard.rank = Card.Rank.SIX
	bot_player.receive_card(unsafe_trump_king)
	bot_player.receive_card(low_discard)
	main_scene.game.current_round.trump = Round.TrumpSuit.CLUBS
	assert(
		main_scene._select_safe_winning_lead_card(bot_player, bot_player.hand) == low_discard,
		"A solo normal or hard bot must preserve an unsupported trump king."
	)

	main_scene.local_first_turn_roll_active = false
	main_scene.normal_round_index = 0
	main_scene.game.current_round.state = Round.State.FINISHED
	main_scene._refresh_round_results()
	await process_frame
	assert(main_scene.round_results_countdown_border.visible, "Solo results must show the 30-second countdown border.")
	assert(main_scene.network_round_countdown_active, "Solo auto-advance countdown must be active.")
	var content_bottom: float = (
		main_scene.round_results_label.global_position.y
		+ main_scene.round_results_label.get_content_height()
	)
	var countdown_border_bottom: float = (
		main_scene.round_results_panel.global_position.y
		+ main_scene.round_results_panel.size.y
		- 3.0
	)
	assert(
		countdown_border_bottom - content_bottom >= 24.0,
		"Round-result text must keep a visible inner gap above the countdown border."
	)

	main_scene.network_round_countdown_remaining_seconds = 0.01
	main_scene._process_network_round_countdown(0.02)
	await process_frame
	assert(main_scene.normal_round_index == 1, "Solo countdown must advance to the next scheduled round.")
	assert(main_scene.game.current_round.state != Round.State.FINISHED, "The next solo round must start without a host click.")

	print("SOLO_ROUND_AUTO_ADVANCE_TEST_PASS")
	quit()
