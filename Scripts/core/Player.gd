class_name Player

extends RefCounted


var player_id: int
var display_name: String
var hand: Array[Card] = []
var bid := -1
var tricks_taken := 0
var total_score := 0


func _init(p_player_id: int, p_display_name: String) -> void:
	player_id = p_player_id
	display_name = p_display_name


func reset_for_round() -> void:
	hand.clear()
	bid = -1
	tricks_taken = 0


func receive_card(card: Card) -> void:
	hand.append(card)


func remove_card(card: Card) -> bool:
	var card_index := hand.find(card)

	if card_index == -1:
		return false

	hand.remove_at(card_index)
	return true


func sort_hand() -> void:
	hand.sort_custom(func(left: Card, right: Card) -> bool:
		if left.suit == right.suit:
			return left.rank < right.rank
		return left.suit < right.suit
	)


func get_hand_text() -> String:
	var card_names := PackedStringArray()

	for card in hand:
		card_names.append(card.get_card_name())

	return ", ".join(card_names)
