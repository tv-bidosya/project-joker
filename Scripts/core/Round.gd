class_name Round

extends RefCounted

enum RoundType {
	NORMAL,
	DARK,
	NO_TRUMP,
	GOLDEN,
	MISERE
}


enum TrumpSuit {
	CLUBS,
	SPADES,
	HEARTS,
	DIAMONDS,
	NONE,
	RANDOM
}

enum State {
	SETUP,
	BIDDING,
	PLAYING,
	FINISHED
}

var number := 0
var cards_per_player := 0
var round_type: RoundType = RoundType.NORMAL
var trump: TrumpSuit = TrumpSuit.RANDOM
var dealer_index := -1
var player_count := 0
var current_player_index := -1
var lead_player_index := -1
var bids: Array[int] = []
var bids_made := 0
var tricks_played := 0
var state: State = State.SETUP


func setup(
	p_number: int,
	p_round_type: RoundType,
	p_cards_per_player: int,
	p_trump: TrumpSuit,
	p_dealer_index: int,
	p_player_count: int
) -> void:
	number = p_number
	round_type = p_round_type
	cards_per_player = p_cards_per_player
	trump = p_trump
	dealer_index = p_dealer_index
	player_count = p_player_count
	current_player_index = (dealer_index + 1) % player_count
	lead_player_index = current_player_index
	bids.resize(player_count)
	bids.fill(-1)
	bids_made = 0
	tricks_played = 0
	state = State.SETUP


func set_trump(p_trump: TrumpSuit) -> void:
	trump = p_trump


func start_bidding() -> void:
	state = State.BIDDING
	current_player_index = (dealer_index + 1) % player_count


func start_playing_without_bids() -> void:
	state = State.PLAYING
	lead_player_index = (dealer_index + 1) % player_count
	current_player_index = lead_player_index


func can_place_bid(player_index: int, value: int) -> bool:
	if state != State.BIDDING:
		return false

	if not _is_valid_player_index(player_index):
		return false

	if player_index != current_player_index:
		return false

	if value < 0 or value > cards_per_player:
		return false

	if bids[player_index] != -1:
		return false

	if bids_made == player_count - 1:
		return get_total_bids() + value != cards_per_player

	return true


func place_bid(player_index: int, value: int) -> bool:
	if not can_place_bid(player_index, value):
		return false

	bids[player_index] = value
	bids_made += 1

	if bids_made == player_count:
		state = State.PLAYING
		lead_player_index = (dealer_index + 1) % player_count
		current_player_index = lead_player_index
	else:
		current_player_index = (current_player_index + 1) % player_count

	return true


func finish() -> void:
	state = State.FINISHED


func get_total_bids() -> int:
	var total := 0

	for bid in bids:
		if bid >= 0:
			total += bid

	return total


func get_trump_name() -> String:
	match trump:
		TrumpSuit.CLUBS:
			return "♣"
		TrumpSuit.SPADES:
			return "♠"
		TrumpSuit.HEARTS:
			return "♥"
		TrumpSuit.DIAMONDS:
			return "♦"
		TrumpSuit.NONE:
			return "без козыря"
		TrumpSuit.RANDOM:
			return "не определён"

	return "не определён"


static func trump_from_card(card: Card) -> TrumpSuit:
	if card.is_joker:
		return TrumpSuit.NONE

	match card.suit:
		Card.Suit.CLUBS:
			return TrumpSuit.CLUBS
		Card.Suit.SPADES:
			return TrumpSuit.SPADES
		Card.Suit.HEARTS:
			return TrumpSuit.HEARTS
		Card.Suit.DIAMONDS:
			return TrumpSuit.DIAMONDS

	return TrumpSuit.NONE


func _is_valid_player_index(player_index: int) -> bool:
	return player_index >= 0 and player_index < player_count
