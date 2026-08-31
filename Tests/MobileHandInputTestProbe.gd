extends SceneTree

var scene: Variant
var gestures: Variant
var confirmations: Array = []
var clubs: Card
var spades: Card
var joker: Card


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	scene = load("res://Scenes/main.tscn").instantiate()
	scene.persistent_settings_writes_enabled = false
	scene.session_save_path = "user://mobile_gestures_regression.save"
	root.add_child(scene)
	await process_frame
	scene.set_process(false)
	scene.mobile_table_layout = true
	scene._apply_mobile_table_layout()
	gestures = scene.mobile_hand_input
	gestures.card_confirmed.disconnect(scene._on_mobile_hand_card_confirmed)
	gestures.card_confirmed.connect(_capture)
	await _setup_hand()
	var a := _view(clubs)
	var b := _view(spades)
	_tap(a)
	assert(confirmations.is_empty() and a.is_selected, "First tap only selects")
	_mouse(a.get_global_rect().get_center(), true, -1)
	_mouse(a.get_global_rect().get_center(), false, -1)
	assert(confirmations.is_empty(), "Emulated mouse must not become a second tap")
	_tap(b)
	assert(confirmations.is_empty() and b.is_selected and not a.is_selected, "Another card replaces selection")
	_tap(b)
	assert(confirmations.size() == 1 and confirmations.back() == spades, "Second tap confirms once")

	var count := confirmations.size()
	var point := a.get_global_rect().get_center()
	var target: Vector2 = scene._get_mobile_card_drop_rect().get_center()
	_touch(point, true)
	_drag(target)
	a.set_availability_hint(true, false)
	assert(gestures.dragging and gestures.drop_panel.visible and a.modulate.a < 1.0, "Drag previews the card and target zone")
	_touch(Vector2(100, 900), false)
	assert(confirmations.size() == count and a.modulate.a == 1.0, "Drop outside returns the card")
	_touch(point, true)
	_drag(target)
	_touch(target, false)
	assert(confirmations.size() == count + 1 and confirmations.back() == clubs, "Valid drop confirms once")
	count = confirmations.size()

	_touch(point, true)
	_drag(target)
	_touch(point + Vector2(20, 0), true, 1)
	_touch(target, false)
	_touch(point, false, 1)
	assert(confirmations.size() == count and not gestures.dragging, "Second finger cancels both releases")
	_touch(point, true)
	_drag(target)
	_touch(target, false, 0, true)
	assert(confirmations.size() == count, "OS touch cancel cannot play")
	_touch(point, true)
	_drag(target)
	scene.menu_overlay.visible = true
	_touch(target, false)
	assert(confirmations.size() == count and not gestures.drop_panel.visible, "Menu blocks in-flight gesture")
	scene.menu_overlay.visible = false
	_touch(point, true)
	_drag(target)
	scene.game.current_round.tricks_played += 1
	_touch(target, false)
	assert(confirmations.size() == count, "Changing trick invalidates the gesture")
	_touch(point, true)
	_drag(target)
	gestures._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	_touch(target, false)
	assert(confirmations.size() == count, "Losing focus cancels drag")

	_tap(a)
	scene._refresh_hand()
	await process_frame
	await process_frame
	a = _view(clubs)
	assert(a.is_selected, "Selection survives harmless hand rebuild")
	_tap(a)
	assert(confirmations.size() == count + 1, "Rebuilt selected card still needs exactly one confirmation tap")
	count = confirmations.size()
	point = a.get_global_rect().get_center()
	_touch(point, true)
	_drag(target)
	scene._refresh_hand()
	_touch(target, false)
	assert(confirmations.size() == count, "Destroyed drag source cannot submit stale data")
	await process_frame
	await process_frame
	var j := _view(joker)
	_touch(j.get_global_rect().get_center(), true)
	gestures._process(0.56)
	_touch(j.get_global_rect().get_center(), false)
	assert(confirmations.size() == count + 1 and confirmations.back() == joker, "Long press confirms Joker once")
	gestures.cancel()
	count = confirmations.size()
	a = _view(clubs)
	var blocker := Control.new()
	scene.add_child(blocker)
	blocker.global_position = a.global_position
	blocker.size = a.size
	gestures.pointer_blockers.append(blocker)
	_tap(a)
	assert(confirmations.size() == count and not a.is_selected, "Touches inside nonmodal panels cannot reach the hand")
	gestures.pointer_blockers.erase(blocker)
	blocker.queue_free()
	scene.chat_panel.visible = true
	assert(scene._can_use_mobile_hand_input(), "Open chat does not block cards elsewhere")
	scene.chat_input.grab_focus()
	await process_frame
	assert(not scene._can_use_mobile_hand_input(), "Typing in chat blocks card gestures")
	scene.chat_input.release_focus()
	scene.chat_panel.visible = false
	print("MOBILE_CHAT_INPUT_PASS")
	print("MOBILE_TAP_DRAG_CANCEL_PASS")

	# Following clubs: a spade is illegal while the hand contains clubs.
	scene.game.active_trick = Trick.new()
	scene.game.active_trick.setup(3, 4, Round.TrumpSuit.NONE)
	var lead: Card = scene._create_card(Card.Suit.CLUBS, Card.Rank.ACE, false)
	scene.game.players[3].hand.append(lead)
	assert(scene.game.active_trick.play_card(scene.game.players[3], lead))
	scene._refresh_hand()
	await process_frame
	await process_frame
	b = _view(spades)
	assert(b.is_disabled)
	count = confirmations.size()
	_tap(b)
	_tap(b)
	_touch(b.get_global_rect().get_center(), true)
	_drag(target)
	assert(gestures.drop_panel.get_theme_stylebox("panel").border_color.r == 1.0)
	_touch(target, false)
	assert(confirmations.size() == count and scene.game.players[0].hand.size() == 3, "Illegal tap and drag never submit")
	print("MOBILE_ILLEGAL_CARD_PASS")

	gestures.card_confirmed.disconnect(_capture)
	gestures.card_confirmed.connect(scene._on_mobile_hand_card_confirmed)
	await _setup_hand()
	j = _view(joker)
	_tap(j)
	assert(scene.pending_joker_card == null, "First Joker tap must not open actions")
	_tap(j)
	assert(scene.pending_joker_card == joker and joker in scene.game.players[0].hand, "Joker opens actions without playing prematurely")
	assert(scene.joker_controls.get_child_count() >= 4)
	await _setup_hand()
	scene.game.active_trick = Trick.new()
	scene.game.active_trick.setup(1, 4, Round.TrumpSuit.NONE)
	lead = scene._create_card(Card.Suit.CLUBS, Card.Rank.ACE, false)
	scene.game.players[1].hand.append(lead)
	assert(scene.game.active_trick.play_card(scene.game.players[1], lead))
	scene._refresh_hand()
	await process_frame
	await process_frame
	a = _view(clubs)
	_tap(a)
	assert(scene.local_premove_card == null)
	_tap(a)
	assert(scene.local_premove_card == clubs and clubs in scene.game.players[0].hand, "Premove takes two taps, not four")
	print("MOBILE_JOKER_PREMOVE_PASS")
	await _check_network_premove()

	await _setup_hand()
	a = _view(clubs)
	_tap(a)
	assert(scene.game.players[0].hand.size() == 3)
	_tap(a)
	scene.menu_overlay.visible = true
	assert(scene.game.players[0].hand.size() == 2 and clubs not in scene.game.players[0].hand, "Confirmed gesture plays exactly one real card")
	while scene.is_processing_automatic_actions or scene.is_trick_presentation_active:
		await process_frame
	scene._delete_saved_session()
	scene.queue_free()
	await process_frame
	print("MOBILE_HAND_INPUT_TEST_PASS")
	quit()


func _check_network_premove() -> void:
	gestures.cancel()
	var previous_match = scene.steam_p2p_match
	var match_node := SteamP2PMatch.new()
	scene.add_child(match_node)
	match_node.mode = 1 # LoopbackNetwork.Mode.HOST
	match_node._transport_active = true
	match_node.lobby_round_started = true
	var network_game := Game.new(["Host", "Two", "Three", "Four"])
	assert(network_game.start_round(3, Round.RoundType.NORMAL, Round.TrumpSuit.NONE, false))
	network_game.current_round.state = Round.State.PLAYING
	network_game.cards_are_dealt = true
	var legal: Card = scene._create_card(Card.Suit.CLUBS, Card.Rank.SEVEN, false)
	network_game.players[0].hand.append(legal)
	var lead: Card = scene._create_card(Card.Suit.CLUBS, Card.Rank.ACE, false)
	network_game.players[1].hand.append(lead)
	network_game.active_trick = Trick.new()
	network_game.active_trick.setup(1, 4, Round.TrumpSuit.NONE)
	assert(network_game.active_trick.play_card(network_game.players[1], lead))
	match_node.match_host = preload("res://Scripts/core/LocalMatchHost.gd").new(network_game)
	scene.steam_p2p_match = match_node
	scene.steam_p2p_table_presentation = true
	scene.steam_p2p_main_table_presentation = true
	var snapshot := match_node.get_test_table_snapshot()
	scene._refresh_network_main_hand(snapshot, snapshot["round"])
	await process_frame
	await process_frame
	var view: CardView = scene.hand_container.get_child(0)
	var key := str(view.get_meta("mobile_card_key"))
	_tap(view)
	assert(scene.network_premove_card_key.is_empty())
	_tap(view)
	assert(scene.network_premove_card_key == key and legal in network_game.players[0].hand, "Network premove also confirms in two taps without playing early")
	scene._clear_network_premove()
	scene.steam_p2p_table_presentation = false
	scene.steam_p2p_main_table_presentation = false
	scene.steam_p2p_match = previous_match
	match_node.match_host = null
	match_node._transport_active = false
	match_node.queue_free()
	await process_frame
	print("MOBILE_NETWORK_PREMOVE_PASS")


func _setup_hand() -> void:
	gestures.cancel()
	scene._reset_game_session()
	scene.menu_overlay.visible = false
	scene.first_turn_roll_panel.visible = false
	scene.stage_announcement_overlay.visible = false
	scene.game.current_round.state = Round.State.PLAYING
	scene.game.current_round.current_player_index = 0
	scene.game.current_round.lead_player_index = 0
	scene.game.cards_are_dealt = true
	scene.auto_turn_enabled = false
	clubs = scene._create_card(Card.Suit.CLUBS, Card.Rank.SEVEN, false)
	spades = scene._create_card(Card.Suit.SPADES, Card.Rank.ACE, false)
	joker = scene._create_card(Card.Suit.HEARTS, Card.Rank.SEVEN, true)
	scene.game.players[0].hand.assign([clubs, spades, joker])
	scene._refresh_hand()
	await process_frame
	await process_frame


func _view(card: Card) -> CardView:
	for view in scene.hand_container.get_children():
		if view is CardView and view.displayed_card == card:
			return view
	return null


func _capture(card: Card, _key: String) -> void:
	confirmations.append(card)


func _tap(view: CardView) -> void:
	var point := view.get_global_rect().get_center()
	_touch(point, true)
	_touch(point, false)


func _touch(point: Vector2, pressed: bool, finger := 0, canceled := false) -> void:
	var event := InputEventScreenTouch.new()
	event.position = point
	event.pressed = pressed
	event.index = finger
	event.canceled = canceled
	root.push_input(event, true)


func _drag(point: Vector2) -> void:
	var event := InputEventScreenDrag.new()
	event.position = point
	event.index = 0
	root.push_input(event, true)


func _mouse(point: Vector2, pressed: bool, device: int) -> void:
	var event := InputEventMouseButton.new()
	event.position = point
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	event.device = device
	root.push_input(event, true)