extends Node

func _ready():

	print("=== Project Joker ===")

	var deck := Deck.new()

	deck.create_deck()

	deck.shuffle()

	print("----------------")
	print("После перемешивания:")

	for card in deck.cards:
		print(card.get_card_name())
	var first_card = deck.draw()

	print("")
	print("Первая карта:")
	print(first_card.get_card_name())

	print("")	
	print("Осталось карт:")
	print(deck.cards_left())
