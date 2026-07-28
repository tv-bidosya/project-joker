extends SceneTree


const CardArtworkResource := preload("res://Scripts/ui/CardArtwork.gd")
const LocalMatchHostResource := preload("res://Scripts/core/LocalMatchHost.gd")
const LoopbackNetworkResource := preload("res://Scripts/core/LoopbackNetworkTest.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var main_scene: Variant = load("res://Scenes/main.tscn").instantiate()
	root.add_child(main_scene)
	await process_frame

	for suit in Card.Suit.values():
		assert(
			CardArtworkResource.get_scheduled_trump_texture(suit) != null,
			"A fixed trump suit must have decorative vector artwork"
		)

	var colored_suits: String = main_scene._format_suit_symbols_for_dark_ui("♣ ♠ ♥ ♦")
	assert(colored_suits.contains("#ff5148"), "Hearts and diamonds must be red in dark table text")
	assert(colored_suits.contains("#101512"), "Clubs and spades must retain a black center")
	var light_suits: String = main_scene._format_suit_symbols_for_light_ui("♣ ♠ ♥ ♦")
	assert(light_suits.contains("#c91f2a"), "Red suits must remain red on the light history panel")
	assert(light_suits.contains("#111411"), "Black suits must be plain black on the light history panel")
	assert(main_scene.history_label.get_theme_color("font_color").r < 0.2, "The light history panel must use dark text")
	main_scene._refresh_network_main_header(
		{"trump_card": {}},
		{
			"number": 29,
			"round_type": Round.RoundType.MISERE,
			"trump": Round.TrumpSuit.SPADES,
			"state": Round.State.PLAYING
		},
		-1
	)
	assert(main_scene.phase_label.text.contains("Мизерная"), "The network header must name a misere round")
	assert(main_scene.trump_label.get_parsed_text().contains("козырь ♠"), "Misere must show its scheduled trump")

	assert(main_scene.avatar_mute_buttons.size() == 4, "Every avatar must own a local sound toggle")
	assert(main_scene.avatar_gift_buttons.size() == 4, "Every avatar must own a contextual gift button")
	var steam_match := SteamP2PMatch.new()
	main_scene.add_child(steam_match)
	steam_match.mode = LoopbackNetworkResource.Mode.HOST
	steam_match._transport_active = true
	steam_match.lobby_round_started = true
	var network_game := Game.new(["Хост", "Игрок 2", "Игрок 3", "Игрок 4"])
	network_game.dealer_index = 3
	assert(network_game.start_round(1, Round.RoundType.NORMAL, Round.TrumpSuit.CLUBS))
	steam_match.match_host = LocalMatchHostResource.new(network_game)
	main_scene.steam_p2p_match = steam_match
	main_scene.steam_p2p_table_presentation = true
	main_scene.steam_p2p_main_table_presentation = true
	main_scene._refresh_network_main_table()
	main_scene._on_avatar_mute_hover_entered(1)
	assert(main_scene.avatar_mute_buttons[1].visible, "Hovering a remote avatar must reveal its sound toggle")
	assert(main_scene.avatar_gift_buttons[1].visible, "Hovering a remote avatar must reveal its gift button")
	main_scene._on_avatar_mute_button_pressed(1)
	assert(main_scene._is_network_player_sound_muted(1), "The avatar button must mute only that network player")
	assert(not main_scene._is_network_player_sound_muted(2), "Muting one player must not mute another")
	assert(main_scene.avatar_mute_buttons[1].text == "🔇", "A muted avatar must show a crossed speaker")
	main_scene.steam_p2p_main_table_presentation = false
	main_scene.steam_p2p_table_presentation = false
	main_scene.steam_p2p_match = null
	steam_match.queue_free()

	var joker := Card.new()
	joker.is_joker = true
	main_scene.pending_joker_card = joker
	main_scene.game.active_trick = Trick.new()
	main_scene._refresh_joker_controls()
	assert(main_scene.joker_controls.get_child_count() == 3, "A responding Joker must offer two actions and Back")
	assert(
		(main_scene.joker_controls.get_child(2) as Button).text == "← Назад к картам",
		"The responding Joker must be cancellable"
	)
	main_scene._on_cancel_pending_joker_selection_pressed()
	assert(main_scene.pending_joker_card == null, "Back must restore the normal hand")

	main_scene._set_player_score_display(0, 0, false)
	main_scene._hold_player_score_until_round_result(0, 12)
	assert(main_scene.player_score_labels[0].text == "Счёт: 0", "Network score must wait for the round result")
	main_scene._set_player_score_display(0, 12, true)
	main_scene._apply_player_score_tween_value(5.0, 0, 12)
	assert(main_scene.player_score_labels[0].text.contains("+12"), "Score animation must show the round delta")
	await create_timer(1.4).timeout
	assert(main_scene.player_score_labels[0].text == "Счёт: 12", "Score animation must finish on the exact total")

	var completed_rounds: Array[Dictionary] = []
	for round_number in range(1, 33):
		completed_rounds.append({
			"round_number": round_number,
			"players": [
				{"tricks_taken": 2},
				{"tricks_taken": 1},
				{"tricks_taken": 0},
				{"tricks_taken": 0}
			]
		})
	var final_snapshot := {
		"completed_rounds": completed_rounds,
		"players": [
			{"player_index": 0, "display_name": "Первый", "total_score": 120, "exact_orders_completed": 8},
			{"player_index": 1, "display_name": "Второй", "total_score": 90, "exact_orders_completed": 7},
			{"player_index": 2, "display_name": "Третий", "total_score": 50, "exact_orders_completed": 5},
			{"player_index": 3, "display_name": "Четвёртый", "total_score": 10, "exact_orders_completed": 3}
		]
	}
	assert(main_scene._is_network_full_game_complete(final_snapshot), "All 32 rounds must trigger match results")
	var final_text: String = main_scene._get_network_table_result_text(final_snapshot)
	assert(final_text.contains("1-е место · Первый"), "Match results must show final placement")
	assert(final_text.contains("всего 64 вз."), "Match results must show total tricks")
	assert(final_text.contains("точных заказов: 8"), "Match results must retain useful order statistics")

	print("LIVE_PLAYTEST_POLISH_TEST_PASS")
	quit()
