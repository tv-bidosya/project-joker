extends SceneTree


const CardArtworkResource := preload("res://Scripts/ui/CardArtwork.gd")


func _init() -> void:
	assert(
		CardArtworkResource.DEFAULT_DECK_STYLE == CardArtworkResource.DeckStyle.VECTOR_CLASSIC,
		"Fresh installs must start with the classic vector deck"
	)
	assert(
		CardArtworkResource.selected_deck_style == CardArtworkResource.DEFAULT_DECK_STYLE,
		"Card artwork must initialize with the fresh-install default"
	)
	for deck_style in range(
		CardArtworkResource.DeckStyle.JUMBO_FOUR_COLOR,
		CardArtworkResource.DeckStyle.VECTOR_CLASSIC + 1
	):
		CardArtworkResource.set_deck_style(deck_style)
		for suit in Card.Suit.values():
			for rank in Card.Rank.values():
				var card := Card.new()
				card.suit = suit
				card.rank = rank
				assert(
					CardArtworkResource.get_face_texture(card) != null
					or deck_style == CardArtworkResource.DeckStyle.SIMPLE_FIRST_VERSION,
					"Missing card artwork for style=%d suit=%d rank=%d" % [deck_style, suit, rank]
				)

		var joker := Card.new()
		joker.is_joker = true
		assert(
			CardArtworkResource.get_face_texture(joker) != null
			or deck_style == CardArtworkResource.DeckStyle.SIMPLE_FIRST_VERSION,
			"Missing Joker artwork"
		)
		assert(
			CardArtworkResource.get_back_texture() != null
			or deck_style == CardArtworkResource.DeckStyle.SIMPLE_FIRST_VERSION,
			"Missing card back artwork"
		)

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

	var card_view := CardView.new()
	var badge_joker := Card.new()
	badge_joker.is_joker = true
	card_view.set_card(badge_joker)
	card_view.set_status("ЗАБИРАЕТ")
	assert(card_view.status_badge.visible, "Joker action badge must be visible")
	var take_style := card_view.status_badge.get_theme_stylebox("panel") as StyleBoxFlat
	assert(take_style != null and take_style.bg_color.g > take_style.bg_color.r, "Winning Joker action must use the green badge")
	card_view.set_status("НЕ БЕРЁТ")
	var discard_style := card_view.status_badge.get_theme_stylebox("panel") as StyleBoxFlat
	assert(discard_style != null and discard_style.bg_color.r > discard_style.bg_color.g, "Discarding Joker action must use the red badge")
	card_view.set_status("")
	assert(not card_view.status_badge.visible, "Empty Joker action must hide the badge")
	card_view.free()

	print("CARD_ARTWORK_TEST_PASS")
	quit()
