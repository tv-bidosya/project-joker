extends SceneTree


const LoopbackNetwork = preload("res://Scripts/core/LoopbackNetworkTest.gd")
const MatchHost = preload("res://Scripts/core/LocalMatchHost.gd")
const Snapshot = preload("res://Scripts/core/MatchStateSnapshot.gd")
const TOTAL_ROUNDS := 32
const PLAYER_COUNT := 4


func _init() -> void:
	seed(20260727)
	var network_match := SteamP2PMatch.new()
	network_match.mode = LoopbackNetwork.Mode.HOST
	network_match.lobby_round_started = true
	network_match._bot_random.seed = 20260727

	var game := Game.new(["Хост", "Игрок 2", "Игрок 3", "Игрок 4"])
	game.dealer_index = 0
	network_match.match_host = MatchHost.new(game)

	var first_plan: Dictionary = network_match._get_scheduled_round_plan(1)
	assert(not first_plan.is_empty(), "The first scheduled network round must exist.")
	assert(
		game.start_round(
			int(first_plan.get("cards_per_player", 0)),
			int(first_plan.get("round_type", Round.RoundType.NORMAL)),
			int(first_plan.get("trump", Round.TrumpSuit.RANDOM)),
			bool(first_plan.get("deal_cards_immediately", true))
		),
		"The full-cycle test could not start the first network round."
	)
	network_match.match_host.record_current_round_started()

	var accepted_action_count := 0
	var leading_joker_count := 0
	var response_joker_count := 0
	var round_two_started_automatically := false

	for expected_round_number in range(1, TOTAL_ROUNDS + 1):
		if expected_round_number > 1 and not (expected_round_number == 2 and round_two_started_automatically):
			assert(
				network_match.start_next_scheduled_round(),
				"The network schedule could not start round %d." % expected_round_number
			)

		_assert_round_matches_schedule(network_match, expected_round_number)
		_assert_all_snapshots_consistent(network_match, expected_round_number)
		_assert_match_metadata_consistent(network_match, expected_round_number)

		var round_started_without_cards: bool = not network_match.match_host.game.cards_are_dealt
		var actions_this_round := 0
		while network_match.match_host.game.current_round.state == Round.State.BIDDING:
			var bidder_index: int = network_match.match_host.game.current_round.current_player_index
			assert(
				network_match._submit_local_bot_action(bidder_index),
				"The host rejected a legal bid in round %d for player %d." % [
					expected_round_number,
					bidder_index
				]
			)
			accepted_action_count += 1
			actions_this_round += 1
			assert(actions_this_round <= 4, "A bidding phase must contain exactly four accepted bids.")
			_assert_revision(network_match, accepted_action_count, expected_round_number)
			_assert_all_snapshots_consistent(network_match, expected_round_number)

		if round_started_without_cards:
			assert(
				network_match.match_host.game.cards_are_dealt,
				"A dark round must deal private hands after all blind bids are accepted."
			)

		while network_match.match_host.game.current_round.state == Round.State.PLAYING:
			var actor_index := network_match._get_host_current_playing_player_index()
			assert(
				actor_index >= 0 and actor_index < PLAYER_COUNT,
				"The playing round must expose one active player."
			)
			var payload: Dictionary = network_match._get_local_bot_card_payload(actor_index)
			assert(not payload.is_empty(), "The active player must have a legal network card payload.")
			if str(payload.get("card_key", "")) == "joker":
				if network_match.match_host.game.active_trick == null:
					leading_joker_count += 1
				else:
					response_joker_count += 1
			assert(
				network_match._submit_local_bot_action(actor_index),
				"The host rejected a legal card in round %d for player %d." % [
					expected_round_number,
					actor_index
				]
			)
			accepted_action_count += 1
			actions_this_round += 1
			assert(
				actions_this_round <= network_match.match_host.game.current_round.cards_per_player * PLAYER_COUNT + 4,
				"A round exceeded its maximum number of legal network actions."
			)
			_assert_revision(network_match, accepted_action_count, expected_round_number)
			_assert_all_snapshots_consistent(network_match, expected_round_number)

		var finished_game: Game = network_match.match_host.game
		assert(
			finished_game.current_round.state == Round.State.FINISHED,
			"Round %d must finish after all scheduled tricks." % expected_round_number
		)
		assert(
			finished_game.current_round.tricks_played == finished_game.current_round.cards_per_player,
			"Round %d must record every scheduled trick." % expected_round_number
		)
		assert(
			network_match.match_host.completed_round_history.size() == expected_round_number,
			"The network score sheet must contain one row per completed round."
		)
		_assert_match_metadata_consistent(network_match, expected_round_number)
		_assert_completed_round(network_match, expected_round_number)
		print(
			"NETWORK_FULL_CYCLE_PROGRESS round=%d/%d revision=%d" % [
				expected_round_number,
				TOTAL_ROUNDS,
				network_match.match_host.revision
			]
		)
		if expected_round_number == 1:
			network_match._process_next_round_auto_start(29.0)
			assert(
				network_match.match_host.game.current_round.state == Round.State.FINISHED,
				"The host must still allow manual review before the 30-second result timeout."
			)
			var countdown_snapshot := network_match.get_test_table_snapshot()
			assert(
				is_equal_approx(float(countdown_snapshot.get("next_round_auto_start_remaining_seconds", -1.0)), 1.0),
				"The authoritative snapshot must expose the remaining result countdown."
			)
			network_match._process_next_round_auto_start(1.1)
			assert(
				network_match.match_host.game.round_number == 2,
				"The host must automatically start round two after 30 seconds on the results screen."
			)
			round_two_started_automatically = true

	assert(
		network_match.match_host.game.round_number == TOTAL_ROUNDS,
		"The network game must stop after the 32nd round."
	)
	assert(
		not network_match.can_start_next_scheduled_round(),
		"No 33rd scheduled network round may be available."
	)
	assert(
		not network_match.start_next_scheduled_round(),
		"The host must reject an attempt to start a 33rd round."
	)
	assert(leading_joker_count > 0, "The full cycle must exercise at least one leading Joker.")
	assert(response_joker_count > 0, "The full cycle must exercise at least one response Joker.")

	var final_snapshot: Dictionary = network_match.match_host.create_host_snapshot()
	assert(final_snapshot.get("completed_rounds", []).size() == TOTAL_ROUNDS)
	assert(final_snapshot.get("players", []).size() == PLAYER_COUNT)

	network_match.free()
	print(
		"NETWORK_FULL_CYCLE_TEST_PASS rounds=%d actions=%d leading_jokers=%d response_jokers=%d" % [
			TOTAL_ROUNDS,
			accepted_action_count,
			leading_joker_count,
			response_joker_count
		]
	)
	quit()


func _assert_revision(network_match: SteamP2PMatch, accepted_action_count: int, round_number: int) -> void:
	var expected_revision := accepted_action_count + round_number - 1
	assert(
		network_match.match_host.revision == expected_revision,
		"Every accepted action and round transition must advance the authoritative revision exactly once."
	)


func _assert_round_matches_schedule(network_match: SteamP2PMatch, round_number: int) -> void:
	var plan: Dictionary = network_match._get_scheduled_round_plan(round_number)
	assert(not plan.is_empty(), "Scheduled round %d must have a plan." % round_number)

	var round: Round = network_match.match_host.game.current_round
	assert(round.number == round_number)
	assert(round.cards_per_player == int(plan.get("cards_per_player", -1)))
	assert(round.round_type == int(plan.get("round_type", -1)))
	assert(round.dealer_index == ((round_number - 1) % PLAYER_COUNT))

	var planned_trump := int(plan.get("trump", Round.TrumpSuit.RANDOM))
	if planned_trump == Round.TrumpSuit.RANDOM:
		assert(
			round.trump != Round.TrumpSuit.RANDOM,
			"A random-trump round must publish the suit revealed by the deck."
		)
	else:
		assert(round.trump == planned_trump)

	var should_deal_immediately := bool(plan.get("deal_cards_immediately", true))
	assert(network_match.match_host.game.cards_are_dealt == should_deal_immediately)
	for player in network_match.match_host.game.players:
		var expected_hand_size := round.cards_per_player if should_deal_immediately else 0
		assert(player.hand.size() == expected_hand_size)


func _assert_all_snapshots_consistent(network_match: SteamP2PMatch, round_number: int) -> void:
	var match_host = network_match.match_host
	var host_snapshot: Dictionary = Snapshot.create_host_snapshot(match_host.game, match_host.revision)
	var player_snapshots: Array[Dictionary] = []
	for player_index in PLAYER_COUNT:
		player_snapshots.append(
			Snapshot.create_player_snapshot(match_host.game, player_index, match_host.revision)
		)
	assert(player_snapshots.size() == PLAYER_COUNT)
	assert(host_snapshot.has("deck_cards"))
	assert(host_snapshot.has("private_hands"))
	assert(not host_snapshot.has("private_hand"))

	var public_keys := [
		"revision",
		"round_number",
		"dealer_index",
		"last_trick_winner_index",
		"cards_are_dealt",
		"cards_left_in_deck",
		"trump_card",
		"players",
		"round",
		"active_trick",
		"last_completed_trick"
	]
	var host_private_hands: Array = host_snapshot.get("private_hands", [])
	assert(host_private_hands.size() == PLAYER_COUNT)

	for player_index in PLAYER_COUNT:
		var player_snapshot: Dictionary = player_snapshots[player_index]
		assert(
			Snapshot.is_player_snapshot_safe(player_snapshot, player_index),
			"Player %d received an unsafe snapshot in round %d." % [player_index, round_number]
		)
		assert(not player_snapshot.has("deck_cards"))
		assert(not player_snapshot.has("private_hands"))
		for public_key in public_keys:
			assert(
				player_snapshot.get(public_key) == host_snapshot.get(public_key),
				"Public snapshot field '%s' diverged for player %d in round %d." % [
					public_key,
					player_index,
					round_number
				]
			)

		var expected_private_hand: Array = host_private_hands[player_index].get("cards", [])
		var actual_private_hand: Array = player_snapshot.get("private_hand", [])
		assert(
			actual_private_hand == expected_private_hand,
			"Player %d did not receive exactly their own hand." % player_index
		)
		var public_players: Array = player_snapshot.get("players", [])
		assert(
			actual_private_hand.size() == int(public_players[player_index].get("cards_in_hand", -1)),
			"The private hand size must match the public card count."
		)


func _assert_match_metadata_consistent(network_match: SteamP2PMatch, round_number: int) -> void:
	var match_host = network_match.match_host
	var host_snapshot: Dictionary = match_host.create_host_snapshot()
	var player_snapshots: Array[Dictionary] = match_host.create_all_player_snapshots()
	var metadata_keys := [
		"public_history",
		"completed_rounds",
		"public_table_events",
		"table_state_reset_id"
	]
	for player_index in PLAYER_COUNT:
		var player_snapshot: Dictionary = player_snapshots[player_index]
		assert(Snapshot.is_player_snapshot_safe(player_snapshot, player_index))
		for metadata_key in metadata_keys:
			assert(
				player_snapshot.get(metadata_key) == host_snapshot.get(metadata_key),
				"Match metadata '%s' diverged for player %d in round %d." % [
					metadata_key,
					player_index,
					round_number
				]
			)


func _assert_completed_round(network_match: SteamP2PMatch, round_number: int) -> void:
	var completed_round: Dictionary = network_match.match_host.completed_round_history[round_number - 1]
	assert(int(completed_round.get("round_number", -1)) == round_number)
	assert(not str(completed_round.get("round_label", "")).is_empty())
	assert(not str(completed_round.get("trump_name", "")).is_empty())

	var result_players: Array = completed_round.get("players", [])
	assert(result_players.size() == PLAYER_COUNT)
	for player_index in PLAYER_COUNT:
		var result: Dictionary = result_players[player_index]
		var player: Player = network_match.match_host.game.players[player_index]
		assert(int(result.get("tricks_taken", -1)) == player.tricks_taken)
		assert(result.has("round_score"))
		if bool(completed_round.get("uses_bids", false)):
			assert(int(result.get("bid", -1)) >= 0)
