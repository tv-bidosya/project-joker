class_name Card

extends RefCounted


enum Suit {
	CLUBS,
	SPADES,
	HEARTS,
	DIAMONDS
}

enum Rank {
	SIX,
	SEVEN,
	EIGHT,
	NINE,
	TEN,
	JACK,
	QUEEN,
	KING,
	ACE
}


var suit: Suit
var rank: Rank
var is_joker := false

func get_card_name() -> String:
	var suit_name := ""

	match suit:
		Suit.CLUBS:
			suit_name = "♣"
		Suit.SPADES:
			suit_name = "♠"
		Suit.HEARTS:
			suit_name = "♥"
		Suit.DIAMONDS:
			suit_name = "♦"

	var rank_name := ""

	match rank:
		Rank.SIX:
			rank_name = "6"
		Rank.SEVEN:
			rank_name = "7"
		Rank.EIGHT:
			rank_name = "8"
		Rank.NINE:
			rank_name = "9"
		Rank.TEN:
			rank_name = "10"
		Rank.JACK:
			rank_name = "В"
		Rank.QUEEN:
			rank_name = "Д"
		Rank.KING:
			rank_name = "К"
		Rank.ACE:
			rank_name = "Т"

	if is_joker:
		return "🃏 Джокер (%s%s)" % [rank_name, suit_name]

	return "%s%s" % [rank_name, suit_name]
