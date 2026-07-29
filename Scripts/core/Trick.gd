class_name Trick

extends RefCounted


enum JokerMode {
	NONE,
	JOKER_WINS,
	HIGHEST_DECLARED_CARD_WINS,
	LOWEST_DECLARED_CARD_WINS,
	NORMAL_CARD_WINS
}


enum ForcedCardRank {
	NONE,
	HIGHEST,
	LOWEST
}


var player_count := 0
var trump: Round.TrumpSuit = Round.TrumpSuit.NONE
var leader_index := -1
var current_player_index := -1
var lead_suit := -1
var joker_mode: JokerMode = JokerMode.NONE
var declared_suit := -1
var forced_card_rank: ForcedCardRank = ForcedCardRank.NONE
var played_cards: Array[Card] = []
var played_by: Array[int] = []


func setup(p_leader_index: int, p_player_count: int, p_trump: Round.TrumpSuit) -> void:
	leader_index = p_leader_index
	current_player_index = p_leader_index
	player_count = p_player_count
	trump = p_trump
	lead_suit = -1
	declared_suit = -1
	joker_mode = JokerMode.NONE
	forced_card_rank = ForcedCardRank.NONE
	played_cards.clear()
	played_by.clear()


func can_play_card(player: Player, card: Card) -> bool:
	if player.player_id != current_player_index:
		return false
	return is_card_allowed_for_player(player, card)


func is_card_allowed_for_player(player: Player, card: Card) -> bool:
	if not player.hand.has(card):
		return false

	if played_cards.is_empty():
		return true

	# Джокер — добровольное универсальное исключение: в ответ его можно
	# сыграть при любой руке, а затем выбрать «берёт» или виртуальную младшую.
	if card.is_joker:
		return true

	if _hand_has_suit(player.hand, lead_suit):
		if card.suit != lead_suit:
			return false

		return _is_forced_card_allowed(player, card)

	if trump != Round.TrumpSuit.NONE and _hand_has_suit(player.hand, trump):
		return card.suit == trump

	return true


func play_card(
	player: Player,
	card: Card,
	p_joker_mode: JokerMode = JokerMode.NONE,
	p_declared_suit: int = -1,
	p_forced_card_rank: ForcedCardRank = ForcedCardRank.NONE
) -> bool:
	if not can_play_card(player, card):
		return false

	if played_cards.is_empty():
		if card.is_joker:
			if p_joker_mode == JokerMode.NONE or p_declared_suit < 0:
				return false

			joker_mode = p_joker_mode
			declared_suit = p_declared_suit
			lead_suit = declared_suit
			forced_card_rank = p_forced_card_rank
		else:
			lead_suit = card.suit
	elif card.is_joker:
		joker_mode = p_joker_mode

		if joker_mode == JokerMode.NONE:
			joker_mode = JokerMode.JOKER_WINS

		if joker_mode != JokerMode.JOKER_WINS:
			declared_suit = lead_suit

	if not player.remove_card(card):
		return false

	played_cards.append(card)
	played_by.append(player.player_id)
	current_player_index = (current_player_index + 1) % player_count
	return true


func is_complete() -> bool:
	return played_cards.size() == player_count


func get_winner_index() -> int:
	if not is_complete():
		return -1

	if joker_mode == JokerMode.JOKER_WINS:
		return played_by[_get_joker_card_index()]

	var winning_card_index := _get_highest_trump_index()

	if winning_card_index != -1:
		return played_by[winning_card_index]

	if joker_mode == JokerMode.HIGHEST_DECLARED_CARD_WINS:
		winning_card_index = _get_card_index_by_suit(declared_suit, true)
	elif joker_mode == JokerMode.LOWEST_DECLARED_CARD_WINS:
		winning_card_index = _get_card_index_by_suit(declared_suit, false)
	else:
		winning_card_index = _get_card_index_by_suit(lead_suit, true)

	if winning_card_index != -1:
		return played_by[winning_card_index]

	var joker_card_index := _get_joker_card_index()
	if joker_card_index != -1:
		return played_by[joker_card_index]

	return -1


func _hand_has_suit(hand: Array[Card], suit: int) -> bool:
	for hand_card in hand:
		if not hand_card.is_joker and hand_card.suit == suit:
			return true

	return false


func _is_forced_card_allowed(player: Player, card: Card) -> bool:
	if forced_card_rank == ForcedCardRank.NONE:
		return true

	var forced_card := _get_hand_card_by_rank(
		player.hand,
		lead_suit,
		forced_card_rank == ForcedCardRank.HIGHEST
	)
	return forced_card == null or card == forced_card


func _get_hand_card_by_rank(hand: Array[Card], suit: int, choose_highest: bool) -> Card:
	var selected_card: Card

	for hand_card in hand:
		if hand_card.is_joker or hand_card.suit != suit:
			continue

		if selected_card == null:
			selected_card = hand_card
			continue

		var replaces_selected := hand_card.rank > selected_card.rank if choose_highest else hand_card.rank < selected_card.rank
		if replaces_selected:
			selected_card = hand_card

	return selected_card


func _get_highest_trump_index() -> int:
	if trump == Round.TrumpSuit.NONE or trump == Round.TrumpSuit.RANDOM:
		return -1

	return _get_card_index_by_suit(trump, true)


func _get_card_index_by_suit(suit: int, choose_highest: bool) -> int:
	var winning_card_index := -1

	for card_index in played_cards.size():
		var card := played_cards[card_index]

		if card.is_joker or card.suit != suit:
			continue

		if winning_card_index == -1:
			winning_card_index = card_index
			continue

		var winning_card := played_cards[winning_card_index]
		var replaces_winner := card.rank > winning_card.rank if choose_highest else card.rank < winning_card.rank

		if replaces_winner:
			winning_card_index = card_index

	return winning_card_index


func _get_joker_card_index() -> int:
	for card_index in played_cards.size():
		if played_cards[card_index].is_joker:
			return card_index

	return -1
