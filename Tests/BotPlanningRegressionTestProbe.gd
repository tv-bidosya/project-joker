extends SceneTree

const Planner = preload("res://Scripts/core/BotMonteCarloStrategy.gd")
const SteamMatch = preload("res://Scripts/core/SteamP2PMatch.gd")
const MatchHost = preload("res://Scripts/core/LocalMatchHost.gd")
var completed_checks := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_no_trump_master_discard()
	_test_golden_cash_ace_and_help_partner()
	_test_bid_planning()
	_test_declared_suit_memory()
	_test_misere_partner_void()
	await _test_wrapped_team_results()
	if completed_checks != 6:
		push_error("A bot/layout regression check did not complete.")
		quit(1)
		return
	print("BOT_PLANNING_REGRESSION_TEST_PASS")
	quit()


func _test_no_trump_master_discard() -> void:
	var game := _game(Round.RoundType.NO_TRUMP, 2)
	game.players[0].hand.assign([_card(0, 10), _card(1, 8)])
	game.players[1].hand.assign([_card(1, 14), _card(2, 6)])
	game.players[2].hand.assign([_card(0, 8), _card(3, 8)])
	game.players[3].hand.assign([_card(0, 9), _card(3, 9)])
	assert(game.play_card(0, game.players[0].hand[0]))
	for seed_value in range(4):
		var choice: Card = Planner.choose_card(game, 1, Planner._get_legal_cards(game, game.players[1]), _rng(seed_value), false, 72)
		assert(choice != null and choice.suit == Card.Suit.HEARTS, "Keep the off-suit ace when a low discard exists and the order still needs tricks.")
	completed_checks += 1


func _test_golden_cash_ace_and_help_partner() -> void:
	var game := _golden_last_seat()
	for seed_value in range(4):
		var choice: Card = Planner.choose_card(game, 3, game.players[3].hand, _rng(seed_value), false, 96)
		assert(choice != null and choice.rank == Card.Rank.ACE, "Cash the golden ace against opponents instead of ducking with the six.")
	# Here player 1 (across from actor 3) is winning with the king. In golden,
	# leaving their first trick removes the partner's -50 zero-trick penalty.
	game = _golden_last_seat(true)
	game.current_round.cards_per_player = 3
	game.current_round.tricks_played = 1
	game.players[3].tricks_taken = 1
	for seed_value in range(4):
		var choice: Card = Planner.choose_card(game, 3, game.players[3].hand, _rng(seed_value), true, 96)
		assert(choice != null and choice.rank == Card.Rank.SIX, "Do not steal the zero-trick partner's golden trick.")
	assert(Planner.choose_joker_mode(game, 3, true) == Trick.JokerMode.NORMAL_CARD_WINS)
	assert(Planner.choose_joker_mode(game, 3, false) == Trick.JokerMode.JOKER_WINS)
	completed_checks += 1


func _test_bid_planning() -> void:
	var game := _game(Round.RoundType.NO_TRUMP, 4)
	game.current_round.start_bidding()
	game.current_round.bids.fill(-1)
	game.current_round.bids_made = 0
	# The Joker is publicly open, so these aces really are cashable. With a
	# hidden Joker a cautious lower order can legitimately have better value.
	game.trump_card = _card(0, 7)
	game.trump_card.is_joker = true
	for index in 4:
		game.players[index].bid = -1
		for suit in 4:
			game.players[index].receive_card(_card(suit, 14 if index == 0 else 6 + index + 1))
	assert(Planner.estimate_hand_bid(game.players[0], game.current_round) == 4, "Four aces must not be counted as two high-card tricks.")
	var started := Time.get_ticks_msec()
	var chosen: int = Planner.choose_bid(game, 0, _rng(319), false, 120)
	assert(chosen == 4, "Four cashable aces in no-trump should support a four-trick bid.")
	assert(Time.get_ticks_msec() - started < 2500)
	var hidden_hand := game.players[1].hand.duplicate()
	game.players[1].hand.assign(game.players[2].hand)
	game.players[2].hand.assign(hidden_hand)
	assert(Planner.choose_bid(game, 0, _rng(319), false, 120) == chosen, "Bidding must not peek at real hidden cards.")
	# The last bidder cannot make the total equal the number of cards.
	game.current_round.dealer_index = 0
	game.current_round.current_player_index = 0
	game.current_round.bids.assign([-1, 0, 0, 0])
	game.current_round.bids_made = 3
	for index in range(1, 4):
		game.players[index].bid = 0
	chosen = Planner.choose_bid(game, 0, _rng(319), false, 120)
	assert(chosen >= 0 and chosen != 4 and game.current_round.can_place_bid(0, chosen))
	completed_checks += 1


func _test_declared_suit_memory() -> void:
	var game := _game(Round.RoundType.GOLDEN, 2)
	var joker := _card(0, 7)
	joker.is_joker = true
	game.players[0].hand.assign([joker, _card(1, 8)])
	game.players[1].hand.assign([_card(0, 6), _card(3, 8)])
	game.players[2].hand.assign([_card(2, 8), _card(3, 9)])
	game.players[3].hand.assign([_card(2, 9), _card(3, 10)])
	assert(game.play_card(0, joker, Trick.JokerMode.JOKER_WINS, Card.Suit.HEARTS))
	for index in range(1, 4):
		assert(game.play_card(index, game.players[index].hand[0]))
	assert(game.active_trick == null)
	assert(game.played_lead_suits_this_round == [2, 2, 2, 2])
	var restored := Game.new(["A", "B", "C", "D"])
	restored.restore_snapshot(game.create_snapshot())
	var voids: Dictionary = Planner._infer_public_void_suits(restored)
	assert(voids.get(1, {}).has(Card.Suit.HEARTS), "Remember the Joker's declared lead after the trick ends and after restore.")
	var pool: Array[Card] = Planner._build_unknown_card_pool(restored, 0)
	for seed_value in range(8):
		var hands: Dictionary = Planner._sample_hidden_hands(restored, 0, pool, _rng(seed_value))
		assert(not hands.is_empty())
		for card: Card in hands[1]:
			assert(card.is_joker or card.suit != Card.Suit.HEARTS)
	completed_checks += 1


func _test_wrapped_team_results() -> void:
	var scene: Variant = load("res://Scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene.set_process(false)
	var panel: PanelContainer = scene.get_node("%RoundResultsPanel")
	var label: RichTextLabel = scene.get_node("%RoundResultsLabel")
	var button: Button = scene.get_node("%NextRoundButton")
	panel.show()
	button.show()
	var rows := "Player A: +10\nPlayer B: +10\nPlayer C: +5\nPlayer D: -10\nA very long historical team name that wraps onto another line and includes additional translated scoring details — team score: 999\nAnother long historical team name that wraps onto another line and includes additional translated scoring details — team score: 998"
	label.text = rows
	scene._fit_round_results_panel(rows)
	for frame in 8:
		await process_frame
	print("RESULTS_CONTENT size=%s min=%s height=%s panel_min=%s" % [label.size, label.get_combined_minimum_size(), label.get_content_height(), panel.get_combined_minimum_size()])
	assert(label.get_line_count() > 6, "The fixture must actually wrap its long team names.")
	assert(button.position.y >= panel.position.y + panel.size.y + 12.0, "Next round must stay below the actual wrapped panel height.")
	assert(button.z_index > panel.z_index, "The timer/results overlay must not cover the next-round button.")
	print("RESULTS_GEOMETRY panel=%s button=%s player=%s" % [panel.get_global_rect(), button.get_global_rect(), scene.player_panels[0].get_global_rect()])
	assert(button.get_global_rect().end.y < scene.player_panels[0].get_global_rect().position.y, "Results must grow upwards instead of covering the player's panel.")
	# Shared local/Steam entry points must agree on the new planner and Joker policy.
	var game := _golden_last_seat()
	scene.game = game
	var serialized: Dictionary = scene._serialize_game_state()
	var player_names: Array[String] = ["A", "B", "C", "D"]
	var restored: Game = scene._deserialize_game_state(serialized, player_names)
	assert(restored != null and restored.played_lead_suits_this_round == game.played_lead_suits_this_round)
	assert(scene._choose_hard_automatic_card(game.players[3], game.players[3].hand).rank == Card.Rank.ACE)
	var network := SteamMatch.new()
	network.match_host = MatchHost.new(game)
	assert(network._choose_hard_local_bot_card(game.players[3], game.players[3].hand).rank == Card.Rank.ACE)
	network.free()
	scene.queue_free()
	await process_frame
	await process_frame
	completed_checks += 1


func _test_misere_partner_void() -> void:
	var game := _game(Round.RoundType.MISERE, 2)
	game.players[0].hand.assign([_card(1, 6), _card(2, 6)])
	for index in range(1, 4):
		game.players[index].hand.assign([_card(3, 7 + index), _card(2, 7 + index)])
	game.played_cards_this_round.assign([_card(1, 9), _card(0, 8), _card(1, 7), _card(1, 10)])
	game.played_cards_by_this_round.assign([0, 1, 2, 3])
	var candidates: Array[Card] = Planner._filter_misere_lead_candidates(game, 0, game.players[0].hand, true)
	assert(candidates.size() == 2, "An opponent being void must not be mistaken for a partner risk in 2v2.")
	game.played_cards_by_this_round.assign([1, 2, 3, 0])
	candidates = Planner._filter_misere_lead_candidates(game, 0, game.players[0].hand, true)
	assert(candidates.size() == 1 and candidates[0].suit == Card.Suit.HEARTS, "Avoid forcing the partner's known void suit on misere.")
	completed_checks += 1


func _golden_last_seat(partner_winning := false) -> Game:
	var game := _game(Round.RoundType.GOLDEN, 2)
	game.players[0].hand.assign([_card(0, 8), _card(1, 6)])
	game.players[1].hand.assign([_card(0, 13 if partner_winning else 9), _card(2, 6)])
	game.players[2].hand.assign([_card(0, 10), _card(3, 6)])
	game.players[3].hand.assign([_card(0, 6), _card(0, 14)])
	for index in 3:
		assert(game.play_card(index, game.players[index].hand[0]))
	return game


func _game(type: Round.RoundType, count: int) -> Game:
	var game := Game.new(["A", "B", "C", "D"])
	game.dealer_index = 3
	game.round_number = 1
	game.cards_are_dealt = true
	game.current_round.setup(1, type, count, Round.TrumpSuit.NONE, 3, 4)
	game.current_round.state = Round.State.PLAYING
	game.current_round.bids.assign([1, 1, 1, 1])
	game.current_round.bids_made = 4
	for player in game.players:
		player.bid = 1
	return game


func _card(suit: int, rank: int) -> Card:
	var card := Card.new()
	card.suit = suit as Card.Suit
	card.rank = (rank - 6) as Card.Rank
	return card


func _rng(seed_value: int) -> RandomNumberGenerator:
	var random := RandomNumberGenerator.new()
	random.seed = 20260826 + seed_value
	return random
