extends SceneTree


const Planner = preload("res://Scripts/core/BotMonteCarloStrategy.gd")
const SteamMatch = preload("res://Scripts/core/SteamP2PMatch.gd")
const MatchHost = preload("res://Scripts/core/LocalMatchHost.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_planner_uses_public_information_only()
	_test_misere_respects_public_void_suits()
	_test_nine_card_planning_budget()
	_test_network_last_card_auto_play()
	await _test_local_last_card_auto_play()
	print("BOT_MONTE_CARLO_STRATEGY_TEST_PASS")
	quit()


func _test_planner_uses_public_information_only() -> void:
	var first_game := _create_two_card_planning_game(false)
	var second_game := _create_two_card_planning_game(true)
	var first_random := RandomNumberGenerator.new()
	var second_random := RandomNumberGenerator.new()
	first_random.seed = 20260820
	second_random.seed = 20260820
	var first_choice: Card = Planner.choose_card(
		first_game,
		0,
		first_game.players[0].hand,
		first_random,
		false,
		72
	)
	var second_choice: Card = Planner.choose_card(
		second_game,
		0,
		second_game.players[0].hand,
		second_random,
		false,
		72
	)
	assert(first_choice != null and second_choice != null, "The planner must complete sampled continuations.")
	assert(
		_card_key(first_choice) == _card_key(second_choice),
		"Changing real hidden cards must not change a seeded decision; the bot may use only public information."
	)


func _test_misere_respects_public_void_suits() -> void:
	var game := Game.new(["Planner", "Void opponent", "Across", "Right"])
	game.dealer_index = 3
	game.round_number = 28
	game.cards_are_dealt = true
	game.current_round.setup(28, Round.RoundType.MISERE, 2, Round.TrumpSuit.CLUBS, 3, 4)
	game.current_round.state = Round.State.PLAYING
	game.current_round.lead_player_index = 0
	game.current_round.current_player_index = 0
	for player in game.players:
		player.hand.clear()
		player.bid = -1
		player.tricks_taken = 0
	game.players[0].receive_card(_card(Card.Suit.SPADES, Card.Rank.SIX))
	game.players[0].receive_card(_card(Card.Suit.HEARTS, Card.Rank.SIX))
	for player_index in range(1, 4):
		game.players[player_index].receive_card(_card(Card.Suit.DIAMONDS, Card.Rank.SIX + player_index))
		game.players[player_index].receive_card(_card(Card.Suit.CLUBS, Card.Rank.SIX + player_index))

	# In the previous trick player 1 failed to follow spades and trumped. This is
	# public knowledge: leading spades again would deliberately hand them a trump.
	game.played_cards_this_round.assign([
		_card(Card.Suit.SPADES, Card.Rank.NINE),
		_card(Card.Suit.CLUBS, Card.Rank.EIGHT),
		_card(Card.Suit.SPADES, Card.Rank.SEVEN),
		_card(Card.Suit.SPADES, Card.Rank.TEN),
	])
	game.played_cards_by_this_round.assign([0, 1, 2, 3])

	var filtered: Array[Card] = Planner._filter_misere_lead_candidates(
		game,
		0,
		game.players[0].hand
	)
	assert(filtered.size() == 1 and filtered[0].suit == Card.Suit.HEARTS)
	var unknown_cards: Array[Card] = Planner._build_unknown_card_pool(game, 0)
	for seed_value in range(12):
		var sample_random := RandomNumberGenerator.new()
		sample_random.seed = 20260820 + seed_value
		var sampled: Dictionary = Planner._sample_hidden_hands(game, 0, unknown_cards, sample_random)
		assert(not sampled.is_empty())
		for sampled_card in sampled[1]:
			assert(sampled_card.is_joker or sampled_card.suit != Card.Suit.SPADES)

	var choice_random := RandomNumberGenerator.new()
	choice_random.seed = 20260820
	var choice: Card = Planner.choose_card(game, 0, game.players[0].hand, choice_random, false, 48)
	assert(choice != null and choice.suit == Card.Suit.HEARTS)
func _test_nine_card_planning_budget() -> void:
	var game := Game.new(["Planner", "Left", "Partner", "Right"])
	game.dealer_index = 3
	assert(game.start_round(9, Round.RoundType.NORMAL, Round.TrumpSuit.CLUBS))
	game.current_round.state = Round.State.PLAYING
	game.current_round.lead_player_index = 0
	game.current_round.current_player_index = 0
	game.current_round.bids.assign([3, 2, 2, 2])
	game.current_round.bids_made = 4
	for player_index in game.players.size():
		game.players[player_index].bid = game.current_round.bids[player_index]
	var random := RandomNumberGenerator.new()
	random.seed = 45102026
	var started_at := Time.get_ticks_msec()
	var selected: Card = Planner.choose_card(
		game,
		0,
		game.players[0].hand,
		random,
		false,
		Planner.DEFAULT_SIMULATION_COUNT
	)
	var elapsed_msec := Time.get_ticks_msec() - started_at
	assert(selected != null and selected in game.players[0].hand)
	assert(elapsed_msec < 2500, "A hard-bot decision must not freeze the table for several seconds.")
	print("BOT_MONTE_CARLO_9_CARD_MS=%d" % elapsed_msec)


func _test_network_last_card_auto_play() -> void:
	var network_match := SteamMatch.new()
	root.add_child(network_match)
	var final_trick_game := _create_final_trick_game()
	network_match.mode = LoopbackNetworkTest.Mode.HOST
	network_match.lobby_round_started = true
	network_match.match_host = MatchHost.new(final_trick_game)
	assert(network_match._is_last_card_auto_play_pending(0))
	network_match._process_human_auto_turn(0.0)
	var timer_snapshot: Dictionary = network_match._append_reconnect_state(
		network_match.match_host.create_player_snapshot(0)
	)
	assert(int(timer_snapshot.get("active_auto_turn_player_index", -1)) == 0)
	assert(
		is_equal_approx(
			float(timer_snapshot.get("active_auto_turn_total_seconds", 0.0)),
			SteamMatch.LAST_CARD_AUTO_PLAY_DELAY_SECONDS
		),
		"Every network participant must receive the shared five-second last-card countdown."
	)
	network_match._process_human_auto_turn(SteamMatch.LAST_CARD_AUTO_PLAY_DELAY_SECONDS + 0.1)
	assert(final_trick_game.players[0].hand.is_empty(), "The Steam host must play a human's last card after five seconds.")
	assert(
		not network_match._human_auto_turn_enabled_by_player.has(0),
		"Last-card assistance must not enable the persistent AFK auto-turn setting."
	)
	network_match.queue_free()

	var joker_network_match := SteamMatch.new()
	root.add_child(joker_network_match)
	var joker_final_trick_game := _create_final_trick_game(true)
	joker_network_match.mode = LoopbackNetworkTest.Mode.HOST
	joker_network_match.lobby_round_started = true
	joker_network_match.match_host = MatchHost.new(joker_final_trick_game)
	assert(
		not joker_network_match._is_last_card_auto_play_pending(0),
		"A final Joker must wait for the player's take/discard or lead-condition choice."
	)
	joker_network_match._process_human_auto_turn(0.0)
	joker_network_match._process_human_auto_turn(SteamMatch.LAST_CARD_AUTO_PLAY_DELAY_SECONDS + 0.1)
	assert(
		joker_final_trick_game.players[0].hand.size() == 1
		and joker_final_trick_game.players[0].hand[0].is_joker,
		"The five-second network shortcut must never auto-play a final Joker."
	)
	joker_network_match.queue_free()


func _test_local_last_card_auto_play() -> void:
	var main_scene: Variant = load("res://Scenes/main.tscn").instantiate()
	root.add_child(main_scene)
	await process_frame
	main_scene._show_stage_announcement_if_needed(Round.RoundType.DARK, 14)
	assert(main_scene.stage_announcement_overlay.visible)
	assert("2" in main_scene.stage_announcement_stage_label.text)
	var announced_type: int = int(main_scene.last_announced_round_type)
	main_scene._show_stage_announcement_if_needed(Round.RoundType.DARK, 15)
	assert(
		main_scene.last_announced_round_type == announced_type,
		"The announcement must not restart for every deal within the same stage."
	)
	main_scene.game = _create_final_trick_game()
	main_scene.is_processing_automatic_actions = false
	main_scene.is_bug_report_review_mode = false
	main_scene.local_first_turn_roll_active = false
	main_scene.bot_speed_index = 2
	main_scene.pending_joker_card = null
	main_scene._reset_turn_reminder()
	assert(main_scene._is_last_human_card_auto_play_pending())
	main_scene.turn_reminder_elapsed_seconds = main_scene.LAST_CARD_AUTO_PLAY_DELAY_SECONDS + 0.1
	assert(main_scene._try_auto_play_last_human_card(false))
	assert(main_scene.game.players[0].hand.is_empty(), "The local player's last card must be played after five seconds.")

	main_scene.game = _create_final_trick_game(true)
	main_scene.pending_joker_card = null
	main_scene._reset_turn_reminder()
	assert(
		not main_scene._is_last_human_card_auto_play_pending(),
		"A final Joker must remain interactive in a local match."
	)
	main_scene.turn_reminder_elapsed_seconds = main_scene.LAST_CARD_AUTO_PLAY_DELAY_SECONDS + 0.1
	assert(not main_scene._try_auto_play_last_human_card(false))
	assert(
		main_scene.game.players[0].hand.size() == 1
		and main_scene.game.players[0].hand[0].is_joker,
		"The five-second local shortcut must never auto-play a final Joker."
	)
	main_scene.queue_free()
	await process_frame
	await process_frame


func _create_two_card_planning_game(swap_hidden_cards: bool) -> Game:
	var game := Game.new(["Planner", "Left", "Partner", "Right"])
	game.dealer_index = 3
	game.round_number = 1
	game.cards_are_dealt = true
	game.current_round.setup(1, Round.RoundType.NORMAL, 2, Round.TrumpSuit.SPADES, 3, 4)
	game.current_round.state = Round.State.PLAYING
	game.current_round.lead_player_index = 0
	game.current_round.current_player_index = 0
	game.current_round.bids.assign([1, 1, 1, 1])
	game.current_round.bids_made = 4
	for player in game.players:
		player.hand.clear()
		player.bid = 1
		player.tricks_taken = 0
	game.players[0].receive_card(_card(Card.Suit.SPADES, Card.Rank.ACE))
	game.players[0].receive_card(_card(Card.Suit.HEARTS, Card.Rank.SIX))
	var hidden_sets := [
		[_card(Card.Suit.CLUBS, Card.Rank.SIX), _card(Card.Suit.DIAMONDS, Card.Rank.SIX)],
		[_card(Card.Suit.CLUBS, Card.Rank.ACE), _card(Card.Suit.DIAMONDS, Card.Rank.ACE)],
		[_card(Card.Suit.HEARTS, Card.Rank.SEVEN), _card(Card.Suit.SPADES, Card.Rank.SEVEN)]
	]
	for player_index in range(1, 4):
		var hidden_index := (player_index - 1 + (1 if swap_hidden_cards else 0)) % hidden_sets.size()
		for hidden_card in hidden_sets[hidden_index]:
			game.players[player_index].receive_card(hidden_card)
	return game


func _create_final_trick_game(human_last_card_is_joker := false) -> Game:
	var game := Game.new(["Human", "Bot 1", "Bot 2", "Bot 3"])
	game.dealer_index = 3
	game.round_number = 1
	game.cards_are_dealt = true
	game.current_round.setup(1, Round.RoundType.NORMAL, 1, Round.TrumpSuit.CLUBS, 3, 4)
	game.current_round.state = Round.State.PLAYING
	game.current_round.lead_player_index = 0
	game.current_round.current_player_index = 0
	game.current_round.bids.assign([0, 0, 0, 0])
	game.current_round.bids_made = 4
	for player_index in game.players.size():
		var player := game.players[player_index]
		player.hand.clear()
		player.bid = 0
		player.tricks_taken = 0
		if player_index == 0 and human_last_card_is_joker:
			var joker := Card.new()
			joker.is_joker = true
			player.receive_card(joker)
		else:
			player.receive_card(_card(player_index, Card.Rank.SIX))
	return game


func _card(suit: int, rank: int) -> Card:
	var card := Card.new()
	card.suit = suit as Card.Suit
	card.rank = rank as Card.Rank
	return card


func _card_key(card: Card) -> String:
	return "joker" if card.is_joker else "%d_%d" % [card.suit, card.rank]
