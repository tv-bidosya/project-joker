class_name Game

extends RefCounted


var players: Array[Player] = []
var deck := Deck.new()
var current_round := Round.new()
var active_trick: Trick
var trump_card: Card
var last_completed_trick_cards: Array[Card] = []
var last_completed_trick_played_by: Array[int] = []
var dealer_index := -1
var last_trick_winner_index := -1
var round_number := 0
var cards_are_dealt := false

var _random := RandomNumberGenerator.new()


func _init(player_names: Array) -> void:
	_random.randomize()

	for player_index in player_names.size():
		players.append(Player.new(player_index, str(player_names[player_index])))

	if not players.is_empty():
		dealer_index = _random.randi_range(0, players.size() - 1)


func start_round(
	cards_per_player: int,
	round_type: Round.RoundType,
	trump: Round.TrumpSuit,
	deal_cards_immediately := true
) -> bool:
	if players.size() != 4 or cards_per_player <= 0:
		return false

	round_number += 1
	deck.create_deck()
	deck.shuffle()

	current_round.setup(
		round_number,
		round_type,
		cards_per_player,
		trump,
		dealer_index,
		players.size()
	)

	_reset_players_for_round()
	cards_are_dealt = false
	trump_card = null

	if deal_cards_immediately:
		_deal_cards(cards_per_player)

	if trump == Round.TrumpSuit.RANDOM:
		trump_card = deck.draw()

		if trump_card == null:
			return false

		current_round.set_trump(Round.trump_from_card(trump_card))

	current_round.start_bidding()
	active_trick = null
	last_trick_winner_index = -1
	last_completed_trick_cards.clear()
	last_completed_trick_played_by.clear()
	return true


func place_bid(player_index: int, bid: int) -> bool:
	if not current_round.place_bid(player_index, bid):
		return false

	players[player_index].bid = bid

	if current_round.state == Round.State.PLAYING and not cards_are_dealt:
		_deal_cards(current_round.cards_per_player)

	return true


func play_card(
	player_index: int,
	card: Card,
	joker_mode: Trick.JokerMode = Trick.JokerMode.NONE,
	declared_suit: int = -1,
	forced_card_rank: Trick.ForcedCardRank = Trick.ForcedCardRank.NONE
) -> bool:
	if player_index < 0 or player_index >= players.size():
		return false

	if active_trick == null:
		_begin_trick()

	if not active_trick.play_card(players[player_index], card, joker_mode, declared_suit, forced_card_rank):
		return false

	if active_trick.is_complete():
		last_trick_winner_index = active_trick.get_winner_index()
		last_completed_trick_cards.assign(active_trick.played_cards)
		last_completed_trick_played_by.assign(active_trick.played_by)
		players[last_trick_winner_index].tricks_taken += 1
		current_round.tricks_played += 1
		current_round.lead_player_index = last_trick_winner_index
		active_trick = null

	return true


func is_round_complete() -> bool:
	return (
		current_round.state == Round.State.PLAYING
		and active_trick == null
		and current_round.tricks_played == current_round.cards_per_player
	)


func finish_round() -> Array[int]:
	var round_scores: Array[int] = []

	if not is_round_complete():
		return round_scores

	for player in players:
		round_scores.append(player.apply_round_result(current_round.round_type))

	current_round.finish()
	return round_scores


func advance_dealer() -> void:
	dealer_index = (dealer_index + 1) % players.size()


func create_snapshot() -> Dictionary:
	var player_states: Array[Dictionary] = []

	for player in players:
		player_states.append({
			"hand": player.hand.duplicate(),
			"bid": player.bid,
			"tricks_taken": player.tricks_taken,
			"total_score": player.total_score,
			"exact_orders_completed": player.exact_orders_completed
		})

	return {
		"players": player_states,
		"deck_cards": deck.cards.duplicate(),
		"round": _create_round_snapshot(),
		"active_trick": _create_trick_snapshot(),
		"trump_card": trump_card,
		"last_completed_trick_cards": last_completed_trick_cards.duplicate(),
		"last_completed_trick_played_by": last_completed_trick_played_by.duplicate(),
		"dealer_index": dealer_index,
		"last_trick_winner_index": last_trick_winner_index,
		"round_number": round_number,
		"cards_are_dealt": cards_are_dealt
	}


func restore_snapshot(snapshot: Dictionary) -> void:
	var player_states: Array = snapshot["players"]

	for player_index in players.size():
		var player_state: Dictionary = player_states[player_index]
		var player := players[player_index]
		player.hand.clear()

		for card in player_state["hand"]:
			player.hand.append(card)

		player.bid = player_state["bid"]
		player.tricks_taken = player_state["tricks_taken"]
		player.total_score = player_state["total_score"]
		player.exact_orders_completed = player_state["exact_orders_completed"]

	deck.cards.assign(snapshot["deck_cards"])
	_restore_round_snapshot(snapshot["round"])
	_restore_trick_snapshot(snapshot["active_trick"])
	trump_card = snapshot["trump_card"]
	last_completed_trick_cards.assign(snapshot["last_completed_trick_cards"])
	last_completed_trick_played_by.assign(snapshot["last_completed_trick_played_by"])
	dealer_index = snapshot["dealer_index"]
	last_trick_winner_index = snapshot["last_trick_winner_index"]
	round_number = snapshot["round_number"]
	cards_are_dealt = snapshot["cards_are_dealt"]


func _deal_cards(cards_per_player: int) -> void:
	for card_number in cards_per_player:
		for player_offset in players.size():
			var player_index := (dealer_index + 1 + player_offset) % players.size()
			var card := deck.draw()

			if card == null:
				push_error("Недостаточно карт для раздачи.")
				return

			players[player_index].receive_card(card)

	for player in players:
		player.sort_hand()

	cards_are_dealt = true


func _reset_players_for_round() -> void:
	for player in players:
		player.reset_for_round()


func _begin_trick() -> void:
	active_trick = Trick.new()
	active_trick.setup(
		current_round.lead_player_index,
		players.size(),
		current_round.trump
	)


func _create_round_snapshot() -> Dictionary:
	return {
		"number": current_round.number,
		"cards_per_player": current_round.cards_per_player,
		"round_type": current_round.round_type,
		"trump": current_round.trump,
		"dealer_index": current_round.dealer_index,
		"player_count": current_round.player_count,
		"current_player_index": current_round.current_player_index,
		"lead_player_index": current_round.lead_player_index,
		"bids": current_round.bids.duplicate(),
		"bids_made": current_round.bids_made,
		"tricks_played": current_round.tricks_played,
		"state": current_round.state
	}


func _restore_round_snapshot(snapshot: Dictionary) -> void:
	current_round.number = snapshot["number"]
	current_round.cards_per_player = snapshot["cards_per_player"]
	current_round.round_type = snapshot["round_type"]
	current_round.trump = snapshot["trump"]
	current_round.dealer_index = snapshot["dealer_index"]
	current_round.player_count = snapshot["player_count"]
	current_round.current_player_index = snapshot["current_player_index"]
	current_round.lead_player_index = snapshot["lead_player_index"]
	current_round.bids.assign(snapshot["bids"])
	current_round.bids_made = snapshot["bids_made"]
	current_round.tricks_played = snapshot["tricks_played"]
	current_round.state = snapshot["state"]


func _create_trick_snapshot() -> Dictionary:
	if active_trick == null:
		return {}

	return {
		"player_count": active_trick.player_count,
		"trump": active_trick.trump,
		"leader_index": active_trick.leader_index,
		"current_player_index": active_trick.current_player_index,
		"lead_suit": active_trick.lead_suit,
		"joker_mode": active_trick.joker_mode,
		"declared_suit": active_trick.declared_suit,
		"forced_card_rank": active_trick.forced_card_rank,
		"played_cards": active_trick.played_cards.duplicate(),
		"played_by": active_trick.played_by.duplicate()
	}


func _restore_trick_snapshot(snapshot: Dictionary) -> void:
	if snapshot.is_empty():
		active_trick = null
		return

	active_trick = Trick.new()
	active_trick.player_count = snapshot["player_count"]
	active_trick.trump = snapshot["trump"]
	active_trick.leader_index = snapshot["leader_index"]
	active_trick.current_player_index = snapshot["current_player_index"]
	active_trick.lead_suit = snapshot["lead_suit"]
	active_trick.joker_mode = snapshot["joker_mode"]
	active_trick.declared_suit = snapshot["declared_suit"]
	active_trick.forced_card_rank = snapshot["forced_card_rank"]
	active_trick.played_cards.assign(snapshot["played_cards"])
	active_trick.played_by.assign(snapshot["played_by"])
