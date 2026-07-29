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

	var winning_joker := Card.new()
	winning_joker.is_joker = true
	main_scene.game.last_completed_trick_cards.assign([winning_joker])
	main_scene.game.last_completed_trick_played_by.assign([1])
	main_scene.game.last_completed_trick_joker_mode = Trick.JokerMode.JOKER_WINS
	assert(main_scene._did_local_joker_win_last_trick(1), "A taking Joker must trigger the local celebration")
	assert(not main_scene._did_local_joker_win_last_trick(0), "The celebration must belong only to the Joker winner")
	var network_joker_snapshot := {
		"last_completed_trick": {
			"cards": [{"is_joker": true}],
			"played_by": [2],
			"joker_mode": Trick.JokerMode.JOKER_WINS
		}
	}
	assert(main_scene._did_network_joker_win_last_trick(network_joker_snapshot, 2))
	network_joker_snapshot["last_completed_trick"]["joker_mode"] = Trick.JokerMode.NORMAL_CARD_WINS
	assert(
		not main_scene._did_network_joker_win_last_trick(network_joker_snapshot, 2),
		"A discarded low Joker must never trigger the celebration"
	)
	main_scene._show_joker_celebration(1)
	assert(main_scene.joker_celebration.visible, "The winning Joker must reveal its celebration overlay")
	assert(main_scene.joker_celebration_image.texture != null, "The celebration must use the bundled original jester art")
	assert(
		main_scene.joker_celebration_image.texture.resource_path.ends_with("laughing_jester_middle_fingers.png"),
		"The winning Joker must use the cheeky two-hand gesture variant"
	)
	var celebration_image: Image = main_scene.joker_celebration_image.texture.get_image()
	assert(celebration_image.get_width() == 640 and celebration_image.get_height() == 640)
	assert(is_zero_approx(celebration_image.get_pixel(0, 0).a), "The celebration sprite must retain transparent corners")
	assert(celebration_image.get_pixel(320, 240).a > 0.99, "The celebration sprite must retain the face and costume")
	assert(main_scene.joker_celebration_sparkles.size() == 8, "The celebration must include animated gold sparkles")
	await create_timer(2.0).timeout
	assert(not main_scene.joker_celebration.visible, "The Joker celebration must dismiss itself")

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
