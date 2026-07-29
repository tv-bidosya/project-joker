extends SceneTree


const LocalMatchHost = preload("res://Scripts/core/LocalMatchHost.gd")
const LoopbackNetwork = preload("res://Scripts/core/LoopbackNetworkTest.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var main_scene: Variant = load("res://Scenes/main.tscn").instantiate()
	root.add_child(main_scene)
	await process_frame

	var steam_match := SteamP2PMatch.new()
	main_scene.add_child(steam_match)
	steam_match.mode = LoopbackNetwork.Mode.HOST
	steam_match._transport_active = true
	steam_match.lobby_round_started = true

	var network_game := Game.new(["Хост", "Игрок 2", "Игрок 3", "Игрок 4"])
	assert(network_game.start_round(3, Round.RoundType.NORMAL, Round.TrumpSuit.CLUBS, false))
	network_game.current_round.state = Round.State.PLAYING
	network_game.cards_are_dealt = true
	var legal_spade := _create_card(Card.Suit.SPADES, Card.Rank.SIX)
	var illegal_heart := _create_card(Card.Suit.HEARTS, Card.Rank.ACE)
	network_game.players[0].receive_card(legal_spade)
	network_game.players[0].receive_card(illegal_heart)
	var leading_spade := _create_card(Card.Suit.SPADES, Card.Rank.SEVEN)
	network_game.players[1].receive_card(leading_spade)
	var trick := Trick.new()
	trick.setup(1, 4, Round.TrumpSuit.CLUBS)
	assert(trick.play_card(network_game.players[1], leading_spade))
	network_game.active_trick = trick
	steam_match.match_host = LocalMatchHost.new(network_game)

	main_scene.steam_p2p_match = steam_match
	main_scene.steam_p2p_table_presentation = true
	main_scene.steam_p2p_main_table_presentation = true
	var snapshot := steam_match.get_test_table_snapshot()
	var round_data: Dictionary = snapshot.get("round", {})
	var active_trick: Dictionary = snapshot.get("active_trick", {})
	var card_key := _find_card_key(snapshot.get("private_hand", []), Card.Suit.SPADES, Card.Rank.SIX)
	assert(not card_key.is_empty())
	assert(
		main_scene._can_prepare_network_premove(snapshot, round_data, active_trick, 0, 2),
		"A player later in the current trick must be able to prepare a premove"
	)

	main_scene._on_network_table_card_pressed(legal_spade, card_key)
	assert(main_scene.network_premove_candidate_key == card_key)
	main_scene._on_network_table_card_pressed(legal_spade, card_key)
	assert(main_scene.network_premove_card_key == card_key, "A second network click must confirm the premove")

	trick.current_player_index = 0
	var queued_round: int = int(main_scene.network_premove_round_number)
	var queued_trick: int = int(main_scene.network_premove_tricks_played)
	main_scene._execute_network_premove(card_key, queued_round, queued_trick)
	assert(legal_spade not in network_game.players[0].hand, "The host must validate and apply a premove only on its turn")
	assert(main_scene.network_premove_card_key.is_empty())

	assert(main_scene.soundpad_bubble.get_theme_stylebox("panel") is StyleBoxEmpty)
	assert(not main_scene.action_label.clip_text)
	assert(main_scene.action_label.autowrap_mode != TextServer.AUTOWRAP_OFF)
	assert(main_scene.trump_label.custom_minimum_size.x == 320.0)

	main_scene.steam_p2p_match = null
	steam_match.match_host = null
	steam_match.queue_free()
	await process_frame
	print("NETWORK_PREMOVE_TEST_PASS")
	quit()


func _create_card(suit: Card.Suit, rank: Card.Rank) -> Card:
	var card := Card.new()
	card.suit = suit
	card.rank = rank
	return card


func _find_card_key(private_hand: Array, suit: Card.Suit, rank: Card.Rank) -> String:
	for card_data_variant in private_hand:
		if not (card_data_variant is Dictionary):
			continue
		var card_data: Dictionary = card_data_variant
		if int(card_data.get("suit", -1)) == suit and int(card_data.get("rank", -1)) == rank:
			return str(card_data.get("card_key", ""))
	return ""
