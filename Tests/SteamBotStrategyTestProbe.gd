extends SceneTree


const MatchHost = preload("res://Scripts/core/LocalMatchHost.gd")


func _init() -> void:
	var network_match := SteamP2PMatch.new()
	network_match.mode = LoopbackNetworkTest.Mode.HOST

	_test_dark_bid_range(network_match)
	_test_ace_is_saved_in_lost_trick(network_match)
	_test_misere_avoids_trick(network_match)
	_test_golden_round_seeks_trick(network_match)
	_test_golden_round_preserves_unsafe_trump_king(network_match)
	_test_overbid_bot_keeps_taking(network_match)
	_test_joker_takes_when_regular_card_cannot(network_match)
	_test_hard_bot_preserves_leading_joker(network_match)

	network_match.free()
	print("STEAM_BOT_STRATEGY_TEST_PASS")
	quit()


func _test_dark_bid_range(network_match: SteamP2PMatch) -> void:
	var game := Game.new(["Host", "Bot", "Player 3", "Player 4"])
	game.dealer_index = 0
	assert(game.start_round(9, Round.RoundType.DARK, Round.TrumpSuit.CLUBS, false))
	network_match.match_host = MatchHost.new(game)
	var bot_player_index := game.current_round.current_player_index
	assert(game.players[bot_player_index].hand.is_empty(), "A dark-round bot must bid before seeing its hand.")

	for difficulty in [
		SteamP2PMatch.BOT_DIFFICULTY_EASY,
		SteamP2PMatch.BOT_DIFFICULTY_NORMAL,
		SteamP2PMatch.BOT_DIFFICULTY_HARD
	]:
		network_match._bot_difficulty = difficulty
		network_match._bot_random.seed = 20260728 + difficulty
		var observed_bids: Dictionary = {}
		for _sample_index in 60:
			var bid := network_match._get_local_bot_bid(bot_player_index, game.current_round)
			assert(bid >= 2 and bid <= 4, "A network bot must bid from 2 to 4 in a dark round.")
			observed_bids[bid] = true
		assert(
			observed_bids.size() == 3,
			"Every difficulty must randomly use bids 2, 3 and 4 when all three are legal."
		)

	assert(game.place_bid(1, 2))
	assert(game.place_bid(2, 2))
	assert(game.place_bid(3, 1))
	assert(game.current_round.current_player_index == 0)
	assert(not game.current_round.can_place_bid(0, 4), "The final bid of 4 must be forbidden when the total would equal nine.")
	for difficulty in [
		SteamP2PMatch.BOT_DIFFICULTY_EASY,
		SteamP2PMatch.BOT_DIFFICULTY_NORMAL,
		SteamP2PMatch.BOT_DIFFICULTY_HARD
	]:
		network_match._bot_difficulty = difficulty
		var observed_final_bids: Dictionary = {}
		for _sample_index in 40:
			var final_bid := network_match._get_local_bot_bid(0, game.current_round)
			assert(final_bid == 2 or final_bid == 3, "A dark bot must respect the forbidden final bid.")
			observed_final_bids[final_bid] = true
		assert(observed_final_bids.size() == 2, "The final dark bidder must randomize between all remaining legal values.")


func _test_ace_is_saved_in_lost_trick(network_match: SteamP2PMatch) -> void:
	var game := _create_playing_game(Round.RoundType.NORMAL, Round.TrumpSuit.CLUBS)
	var leader_index := game.current_round.current_player_index
	var bot_index := (leader_index + 1) % game.players.size()
	var trump_ace := _card(Card.Suit.CLUBS, Card.Rank.ACE)
	var low_discard := _card(Card.Suit.HEARTS, Card.Rank.SIX)
	var saved_ace := _card(Card.Suit.DIAMONDS, Card.Rank.ACE)
	game.players[leader_index].receive_card(trump_ace)
	game.players[bot_index].receive_card(low_discard)
	game.players[bot_index].receive_card(saved_ace)
	game.players[bot_index].bid = 2
	assert(game.play_card(leader_index, trump_ace))
	network_match.match_host = MatchHost.new(game)

	for difficulty in [
		SteamP2PMatch.BOT_DIFFICULTY_NORMAL,
		SteamP2PMatch.BOT_DIFFICULTY_HARD
	]:
		network_match._bot_difficulty = difficulty
		var payload := network_match._get_local_bot_card_payload(bot_index)
		assert(payload.get("card_key", "") == _card_key(low_discard), "The bot must save an ace when the trick is already lost.")


func _test_misere_avoids_trick(network_match: SteamP2PMatch) -> void:
	var game := _create_playing_game(Round.RoundType.MISERE, Round.TrumpSuit.NONE)
	var leader_index := game.current_round.current_player_index
	var bot_index := (leader_index + 1) % game.players.size()
	var lead_card := _card(Card.Suit.SPADES, Card.Rank.NINE)
	var losing_card := _card(Card.Suit.SPADES, Card.Rank.SIX)
	var winning_ace := _card(Card.Suit.SPADES, Card.Rank.ACE)
	game.players[leader_index].receive_card(lead_card)
	game.players[bot_index].receive_card(losing_card)
	game.players[bot_index].receive_card(winning_ace)
	assert(game.play_card(leader_index, lead_card))
	network_match.match_host = MatchHost.new(game)
	network_match._bot_difficulty = SteamP2PMatch.BOT_DIFFICULTY_HARD

	var payload := network_match._get_local_bot_card_payload(bot_index)
	assert(payload.get("card_key", "") == _card_key(losing_card), "The bot must avoid taking a trick in misere.")


func _test_golden_round_seeks_trick(network_match: SteamP2PMatch) -> void:
	var game := _create_playing_game(Round.RoundType.GOLDEN, Round.TrumpSuit.NONE)
	var bot_index := game.current_round.current_player_index
	var low_card := _card(Card.Suit.HEARTS, Card.Rank.SIX)
	var ace := _card(Card.Suit.HEARTS, Card.Rank.ACE)
	game.players[bot_index].receive_card(low_card)
	game.players[bot_index].receive_card(ace)
	network_match.match_host = MatchHost.new(game)
	network_match._bot_difficulty = SteamP2PMatch.BOT_DIFFICULTY_HARD

	var payload := network_match._get_local_bot_card_payload(bot_index)
	assert(payload.get("card_key", "") == _card_key(ace), "The bot must seek tricks in a golden round.")


func _test_golden_round_preserves_unsafe_trump_king(network_match: SteamP2PMatch) -> void:
	var game := _create_playing_game(Round.RoundType.GOLDEN, Round.TrumpSuit.CLUBS)
	var bot_index := game.current_round.current_player_index
	var trump_king := _card(Card.Suit.CLUBS, Card.Rank.KING)
	var low_non_trump := _card(Card.Suit.HEARTS, Card.Rank.SIX)
	game.players[bot_index].receive_card(trump_king)
	game.players[bot_index].receive_card(low_non_trump)
	network_match.match_host = MatchHost.new(game)
	network_match._bot_difficulty = SteamP2PMatch.BOT_DIFFICULTY_HARD
	var payload := network_match._get_local_bot_card_payload(bot_index)
	assert(
		payload.get("card_key", "") == _card_key(low_non_trump),
		"A hard golden bot must not donate a trump king while the trump ace is still unknown."
	)


func _test_overbid_bot_keeps_taking(network_match: SteamP2PMatch) -> void:
	var game := _create_playing_game(Round.RoundType.NORMAL, Round.TrumpSuit.CLUBS)
	var bot_index := game.current_round.current_player_index
	game.players[bot_index].bid = 1
	game.players[bot_index].tricks_taken = 2
	network_match.match_host = MatchHost.new(game)
	assert(network_match._local_bot_wants_trick(game.players[bot_index]), "An overbid bot must keep seeking tricks.")


func _test_joker_takes_when_regular_card_cannot(network_match: SteamP2PMatch) -> void:
	var game := _create_playing_game(Round.RoundType.NORMAL, Round.TrumpSuit.CLUBS)
	var leader_index := game.current_round.current_player_index
	var bot_index := (leader_index + 1) % game.players.size()
	var trump_ace := _card(Card.Suit.CLUBS, Card.Rank.ACE)
	var losing_trump := _card(Card.Suit.CLUBS, Card.Rank.KING)
	var joker := _card(Card.Suit.CLUBS, Card.Rank.SEVEN, true)
	game.players[leader_index].receive_card(trump_ace)
	game.players[bot_index].receive_card(losing_trump)
	game.players[bot_index].receive_card(joker)
	game.players[bot_index].bid = 1
	assert(game.play_card(leader_index, trump_ace))
	network_match.match_host = MatchHost.new(game)
	network_match._bot_difficulty = SteamP2PMatch.BOT_DIFFICULTY_HARD

	var payload := network_match._get_local_bot_card_payload(bot_index)
	assert(payload.get("card_key", "") == "joker", "The bot must use a joker when no regular card can win.")
	assert(int(payload.get("joker_mode", Trick.JokerMode.NONE)) == Trick.JokerMode.JOKER_WINS)


func _test_hard_bot_preserves_leading_joker(network_match: SteamP2PMatch) -> void:
	var game := _create_playing_game(Round.RoundType.NORMAL, Round.TrumpSuit.CLUBS)
	var bot_index := game.current_round.current_player_index
	var trump_ace := _card(Card.Suit.CLUBS, Card.Rank.ACE)
	var joker := _card(Card.Suit.CLUBS, Card.Rank.SEVEN, true)
	game.players[bot_index].receive_card(trump_ace)
	game.players[bot_index].receive_card(joker)
	game.players[bot_index].bid = 1
	network_match.match_host = MatchHost.new(game)

	network_match._bot_difficulty = SteamP2PMatch.BOT_DIFFICULTY_NORMAL
	var normal_payload := network_match._get_local_bot_card_payload(bot_index)
	network_match._bot_difficulty = SteamP2PMatch.BOT_DIFFICULTY_HARD
	var hard_payload := network_match._get_local_bot_card_payload(bot_index)
	assert(normal_payload.get("card_key", "") == "joker", "A normal bot may lead with a taking joker.")
	assert(hard_payload.get("card_key", "") == _card_key(trump_ace), "A hard bot must preserve a joker when a strong regular lead is available.")


func _create_playing_game(round_type: Round.RoundType, trump: Round.TrumpSuit) -> Game:
	var game := Game.new(["Host", "Bot", "Player 3", "Player 4"])
	assert(game.start_round(2, round_type, trump))
	game.current_round.start_playing_without_bids()
	for player in game.players:
		player.hand.clear()
	return game


func _card(suit: Card.Suit, rank: Card.Rank, is_joker := false) -> Card:
	var card := Card.new()
	card.suit = suit
	card.rank = rank
	card.is_joker = is_joker
	return card


func _card_key(card: Card) -> String:
	return "joker" if card.is_joker else "%d_%d" % [card.suit, card.rank]
