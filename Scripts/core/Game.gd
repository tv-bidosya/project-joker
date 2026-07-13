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
	trump: Round.TrumpSuit
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

	_deal_cards(cards_per_player)
	trump_card = null

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
	return true


func play_card(
	player_index: int,
	card: Card,
	joker_mode: Trick.JokerMode = Trick.JokerMode.NONE,
	declared_suit: int = -1
) -> bool:
	if player_index < 0 or player_index >= players.size():
		return false

	if active_trick == null:
		_begin_trick()

	if not active_trick.play_card(players[player_index], card, joker_mode, declared_suit):
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


func _deal_cards(cards_per_player: int) -> void:
	for player in players:
		player.reset_for_round()

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


func _begin_trick() -> void:
	active_trick = Trick.new()
	active_trick.setup(
		current_round.lead_player_index,
		players.size(),
		current_round.trump
	)
