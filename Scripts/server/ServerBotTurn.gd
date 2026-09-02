class_name ServerBotTurn

extends RefCounted


const MatchCommand = preload("res://Scripts/core/MatchCommand.gd")


static func create_command(match_host, player_index: int, difficulty: int = 1):
	if match_host == null or match_host.game == null or match_host.game.current_round == null:
		return null
	var round: Round = match_host.game.current_round
	if round.state == Round.State.BIDDING:
		var bid := _choose_bid(match_host.game, player_index, difficulty)
		if bid < 0:
			return null
		return MatchCommand.new(
			MatchCommand.Type.BID,
			player_index,
			match_host.game.round_number,
			match_host.revision,
			{"bid": bid}
		)
	if round.state != Round.State.PLAYING:
		return null
	var payload := _choose_card_payload(match_host.game, player_index, difficulty)
	if payload.is_empty():
		return null
	return MatchCommand.new(
		MatchCommand.Type.PLAY_CARD,
		player_index,
		match_host.game.round_number,
		match_host.revision,
		payload
	)


static func _choose_bid(game: Game, player_index: int, difficulty: int) -> int:
	var round: Round = game.current_round
	var valid_bids: Array[int] = []
	for bid in range(round.cards_per_player + 1):
		if round.can_place_bid(player_index, bid):
			valid_bids.append(bid)
	if valid_bids.is_empty():
		return -1
	if difficulty <= 0:
		return valid_bids[0]
	var estimate := 0
	for card in game.players[player_index].hand:
		if card.is_joker:
			estimate += 1
		elif card.rank == Card.Rank.ACE:
			estimate += 1
		elif round.trump != Round.TrumpSuit.NONE and card.suit == round.trump and card.rank >= Card.Rank.JACK:
			estimate += 1
	if difficulty >= 2 and round.cards_per_player >= 6:
		estimate += 1
	estimate = clampi(estimate, 0, round.cards_per_player)
	var selected := valid_bids[0]
	for bid in valid_bids:
		if absi(bid - estimate) < absi(selected - estimate):
			selected = bid
	return selected


static func _choose_card_payload(game: Game, player_index: int, difficulty: int) -> Dictionary:
	var player: Player = game.players[player_index]
	var legal_cards: Array[Card] = []
	for card in player.hand:
		if game.active_trick == null or game.active_trick.can_play_card(player, card):
			legal_cards.append(card)
	if legal_cards.is_empty():
		return {}
	var selected: Card = legal_cards[0]
	if difficulty > 0:
		for card in legal_cards:
			if card.is_joker:
				continue
			if selected.is_joker or _card_strength(game, card) < _card_strength(game, selected):
				selected = card
	if not selected.is_joker:
		return {"card_key": "%d_%d" % [selected.suit, selected.rank]}
	var is_leading := game.active_trick == null
	return {
		"card_key": "joker",
		"joker_mode": Trick.JokerMode.NORMAL_CARD_WINS if is_leading else Trick.JokerMode.JOKER_WINS,
		"declared_suit": Card.Suit.CLUBS if is_leading else -1,
		"forced_card_rank": Trick.ForcedCardRank.NONE
	}


static func _card_strength(game: Game, card: Card) -> int:
	var value := int(card.rank)
	if game.current_round.trump != Round.TrumpSuit.NONE and card.suit == game.current_round.trump:
		value += 20
	if game.active_trick != null and card.suit == game.active_trick.lead_suit:
		value += 10
	return value