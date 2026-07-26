extends SceneTree


const CardArtworkResource := preload("res://Scripts/ui/CardArtwork.gd")


func _init() -> void:
	for deck_style in range(
		CardArtworkResource.DeckStyle.JUMBO_FOUR_COLOR,
		CardArtworkResource.DeckStyle.COMPACT_FOUR_COLOR + 1
	):
		CardArtworkResource.set_deck_style(deck_style)
		for suit in Card.Suit.values():
			for rank in Card.Rank.values():
				var card := Card.new()
				card.suit = suit
				card.rank = rank
				assert(
					CardArtworkResource.get_face_texture(card) != null,
					"Missing card artwork for style=%d suit=%d rank=%d" % [deck_style, suit, rank]
				)

		var joker := Card.new()
		joker.is_joker = true
		assert(CardArtworkResource.get_face_texture(joker) != null, "Missing Joker artwork")
		assert(CardArtworkResource.get_back_texture() != null, "Missing card back artwork")

	print("CARD_ARTWORK_TEST_PASS")
	quit()
