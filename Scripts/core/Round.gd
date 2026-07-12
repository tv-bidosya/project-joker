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


var cards_per_player: int

var round_type: RoundType

var trump: TrumpSuit
