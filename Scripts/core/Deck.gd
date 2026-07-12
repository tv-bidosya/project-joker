class_name Deck

extends RefCounted

var cards: Array[Card] = []

func create_deck():

	cards.clear()

	for suit in Card.Suit.values():

		for rank in Card.Rank.values():

			var card := Card.new()

			card.suit = suit
			card.rank = rank

			if suit == Card.Suit.CLUBS and rank == Card.Rank.SEVEN:
				card.is_joker = true

			cards.append(card)
func shuffle():
	cards.shuffle()

func cards_left() -> int:
	return cards.size()
func draw() -> Card:
	if cards.is_empty():
		return null

	return cards.pop_front()
