extends Node

func _ready():

	print("=== Project Joker ===")

	var deck := Deck.new()

	deck.create_deck()

	print("Карт в колоде:", deck.cards.size())

	for card in deck.cards:
		print(card.get_card_name())
