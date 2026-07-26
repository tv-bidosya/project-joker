extends SceneTree


const CardArtworkResource := preload("res://Scripts/ui/CardArtwork.gd")


func _init() -> void:
	for deck_style in range(
		CardArtworkResource.DeckStyle.JUMBO_FOUR_COLOR,
		CardArtworkResource.DeckStyle.ORIGINAL_JUMBO + 1
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

	var club_ace := Card.new()
	club_ace.suit = Card.Suit.CLUBS
	club_ace.rank = Card.Rank.ACE
	CardArtworkResource.set_deck_style(CardArtworkResource.DeckStyle.JUMBO_FOUR_COLOR)
	var recolored_texture := CardArtworkResource.get_face_texture(club_ace)
	CardArtworkResource.set_deck_style(CardArtworkResource.DeckStyle.ORIGINAL_JUMBO)
	var original_texture := CardArtworkResource.get_face_texture(club_ace)
	assert(
		recolored_texture.get_image().get_data() != original_texture.get_image().get_data(),
		"Original Jumbo must remain visually separate from recolored Jumbo"
	)

	print("CARD_ARTWORK_TEST_PASS")
	quit()
