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
	assert(
		int(ProjectSettings.get_setting("rendering/anti_aliasing/quality/msaa_2d", 0)) == 2,
		"Rotated 2D card edges must use 4x MSAA instead of exposing jagged texture boundaries"
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

	CardArtworkResource.set_deck_style(CardArtworkResource.DeckStyle.VECTOR_CLASSIC)
	var crisp_joker := Card.new()
	crisp_joker.is_joker = true
	var crisp_joker_texture := CardArtworkResource.get_face_texture(crisp_joker)
	assert(crisp_joker_texture.resource_path.ends_with("project_joker_crisp.png"), "Vector Classic must use the crisp game-sized Joker")
	var crisp_joker_image := crisp_joker_texture.get_image()
	assert(crisp_joker_image.get_width() == 500 and crisp_joker_image.get_height() == 726, "The crisp Joker must match the Vector Classic face-card dimensions")
	assert(crisp_joker_image.get_pixel(0, 363).a > 0.99, "The crisp Joker must not keep a second inner alpha edge")
	for side_x in [4, 495]:
		var side_color := crisp_joker_image.get_pixel(side_x, 363)
		assert(
			side_color.r > 0.9 and side_color.g > 0.9 and side_color.b > 0.8,
			"The crisp Joker side fields must not contain a second black keyline"
		)

	var card_view := CardView.new()
	root.add_child(card_view)
	var badge_joker := Card.new()
	badge_joker.is_joker = true
	card_view.set_card(badge_joker)
	assert(card_view.depth_shadow != null, "Every card must have an independent 2.5D depth shadow")
	var depth_shadow_style := card_view.depth_shadow.get_theme_stylebox("panel") as StyleBoxFlat
	assert(depth_shadow_style != null and is_zero_approx(depth_shadow_style.bg_color.a), "The 2.5D shadow must not draw a solid fake side wall")
	assert(depth_shadow_style.shadow_size > 0, "Cards must retain a soft cast shadow after removing the fake side wall")
	assert(not card_view.depth_shadow.visible, "Finished card artwork must move without a second shadow layer around it")
	assert(card_view.artwork_texture.offset_left == 0.0 and card_view.artwork_texture.offset_right == 0.0, "Finished card artwork must fill the view without an inset glass rim")
	assert(card_view.artwork_texture.texture_filter == CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC, "Finished card artwork must use anisotropic mipmap filtering when tilted")
	assert(card_view.artwork_texture.texture_repeat == CanvasItem.TEXTURE_REPEAT_DISABLED, "Finished card artwork must never repeat edge pixels around a tilted card")
	var edge_material := card_view.artwork_texture.material as ShaderMaterial
	assert(edge_material != null and edge_material.shader != null, "Finished card artwork must use a clean alpha-edge mask")
	assert(edge_material.shader.code.contains("fwidth(edge_distance)"), "The artwork edge mask must adapt its antialiasing to the rendered card size")
	assert(edge_material.shader.code.contains("smoothstep"), "The artwork edge mask must smooth rotated card boundaries")
	var finished_artwork_style := card_view.face_panel.get_theme_stylebox("panel") as StyleBoxFlat
	assert(finished_artwork_style != null and finished_artwork_style.get_border_width(SIDE_LEFT) == 0, "Finished card artwork must not receive a second frame")
	assert(is_zero_approx(finished_artwork_style.bg_color.a), "Finished card artwork must not receive a glass background")
	assert(finished_artwork_style.shadow_size == 0, "Finished card artwork must not receive an outer style shadow")
	card_view.set_hand_presentation(0, 3)
	assert(not is_zero_approx(card_view.presentation_rotation), "Joker artwork must retain the same 2.5D hand tilt as the other cards")
	var root_position_before_hover := card_view.position
	card_view.set_interactive(true, false)
	card_view._on_mouse_entered()
	assert(card_view.position == root_position_before_hover, "2.5D hover must not move the clickable card hitbox")
	assert(card_view.is_hovered, "Interactive cards must enter the 2.5D hover pose")
	card_view._on_mouse_exited()
	card_view.set_status("ЗАБИРАЕТ")
	assert(card_view.status_badge.visible, "Joker action badge must be visible")
	var take_style := card_view.status_badge.get_theme_stylebox("panel") as StyleBoxFlat
	assert(take_style != null and take_style.bg_color.g > take_style.bg_color.r, "Winning Joker action must use the green badge")
	card_view.set_status("НЕ БЕРЁТ")
	var discard_style := card_view.status_badge.get_theme_stylebox("panel") as StyleBoxFlat
	assert(discard_style != null and discard_style.bg_color.r > discard_style.bg_color.g, "Discarding Joker action must use the red badge")
	card_view.set_status("")
	assert(not card_view.status_badge.visible, "Empty Joker action must hide the badge")
	card_view.queue_free()

	CardArtworkResource.set_deck_style(CardArtworkResource.DeckStyle.SIMPLE_FIRST_VERSION)
	var simple_card_view := CardView.new()
	root.add_child(simple_card_view)
	var simple_card := Card.new()
	simple_card.suit = Card.Suit.SPADES
	simple_card.rank = Card.Rank.ACE
	simple_card_view.set_card(simple_card)
	assert(simple_card_view.depth_shadow.visible, "The simple text deck must retain its supporting card shadow")
	var simple_style := simple_card_view.face_panel.get_theme_stylebox("panel") as StyleBoxFlat
	assert(simple_style != null and simple_style.get_border_width(SIDE_LEFT) > 0, "The simple text deck must retain its generated card frame")
	simple_card_view.queue_free()

	print("CARD_ARTWORK_TEST_PASS")
	quit()
