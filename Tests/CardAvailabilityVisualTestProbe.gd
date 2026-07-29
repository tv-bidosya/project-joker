extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var main_scene: Variant = load("res://Scenes/main.tscn").instantiate()
	root.add_child(main_scene)
	await process_frame

	var visual_game := Game.new(["Игрок", "Бот 1", "Бот 2", "Бот 3"])
	assert(visual_game.start_round(3, Round.RoundType.NORMAL, Round.TrumpSuit.CLUBS, false))
	visual_game.current_round.state = Round.State.PLAYING
	visual_game.cards_are_dealt = true

	var legal_spade := _create_card(Card.Suit.SPADES, Card.Rank.SIX)
	var illegal_heart := _create_card(Card.Suit.HEARTS, Card.Rank.ACE)
	var legal_joker := Card.new()
	legal_joker.is_joker = true
	visual_game.players[0].receive_card(legal_spade)
	visual_game.players[0].receive_card(illegal_heart)
	visual_game.players[0].receive_card(legal_joker)

	var leading_spade := _create_card(Card.Suit.SPADES, Card.Rank.SEVEN)
	visual_game.players[3].receive_card(leading_spade)
	var trick := Trick.new()
	trick.setup(3, 4, Round.TrumpSuit.CLUBS)
	assert(trick.play_card(visual_game.players[3], leading_spade))
	visual_game.active_trick = trick
	main_scene.game = visual_game
	main_scene._refresh_hand()

	var card_views := _get_hand_card_views(main_scene)
	assert(card_views.size() == 3)
	for card_view: CardView in card_views:
		if card_view.displayed_card == illegal_heart:
			assert(card_view.is_visually_unavailable, "An off-suit card must be dimmed while following suit")
			var unavailable_style := card_view.availability_overlay.get_theme_stylebox("panel") as StyleBoxFlat
			assert(
				card_view.availability_overlay.visible
				and unavailable_style != null
				and unavailable_style.bg_color.a > 0.5
				and unavailable_style.get_corner_radius(CORNER_TOP_LEFT) == 2
				and unavailable_style.get_border_width(SIDE_LEFT) == 1
			)
		else:
			assert(not card_view.is_visually_unavailable, "The led suit and Joker must stay visually available")
			assert(
				card_view.is_visually_available
				and not card_view.availability_overlay.visible
				and card_view.modulate == Color.WHITE,
				"Every legal response must retain the untouched card artwork"
			)

	trick.current_player_index = 1
	main_scene._refresh_hand()
	await process_frame
	for card_view: CardView in _get_hand_card_views(main_scene):
		if card_view.displayed_card == illegal_heart:
			assert(
				card_view.is_visually_unavailable and card_view.availability_overlay.visible,
				"An illegal waiting card must stay dimmed while premove is available"
			)
		else:
			assert(
				card_view.is_visually_available and card_view.is_interactive,
				"A legal waiting card must be selectable for premove"
			)

	main_scene._on_card_pressed(legal_spade)
	assert(main_scene.local_premove_candidate == legal_spade)
	assert(main_scene.local_premove_card == null)
	main_scene._on_card_pressed(legal_spade)
	assert(main_scene.local_premove_candidate == null)
	assert(main_scene.local_premove_card == legal_spade, "A second click must confirm the premove")
	await process_frame
	for card_view: CardView in _get_hand_card_views(main_scene):
		if card_view.displayed_card == legal_spade:
			assert(
				card_view.status_label.text == "ВЫБРАНО ✓",
				"A confirmed preliminary move needs a clear short badge, got '%s'" % card_view.status_label.text
			)
	trick.current_player_index = 0
	assert(main_scene._try_apply_local_premove(), "A confirmed premove must execute when the turn reaches the player")
	assert(legal_spade not in visual_game.players[0].hand)
	assert(main_scene.local_premove_card == null)

	print("CARD_AVAILABILITY_VISUAL_TEST_PASS")
	quit()


func _create_card(suit: Card.Suit, rank: Card.Rank) -> Card:
	var card := Card.new()
	card.suit = suit
	card.rank = rank
	return card


func _get_hand_card_views(main_scene: Variant) -> Array[CardView]:
	var result: Array[CardView] = []
	for child in main_scene.hand_container.get_children():
		if child is CardView:
			result.append(child as CardView)
	return result
