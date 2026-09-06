extends SceneTree


const LoopbackNetwork = preload("res://Scripts/core/LoopbackNetworkTest.gd")
const LocalMatchHost = preload("res://Scripts/core/LocalMatchHost.gd")
const SteamP2PMatch = preload("res://Scripts/core/SteamP2PMatch.gd")


class FakeRemoteRoll:
	extends Node

	var submitted := false
	var lobby_seats: Array = [
		{"player_index": 0, "display_name": "Desktop"},
		{"player_index": 1, "display_name": "Android"},
		{"player_index": 2, "display_name": "Rhysand"},
		{"player_index": 3, "display_name": "Azriel"}
	]

	func is_running() -> bool:
		return true

	func is_in_room() -> bool:
		return true

	func is_first_turn_roll_active() -> bool:
		return true

	func get_first_turn_roll_state() -> Dictionary:
		return {
			"phase": 1,
			"roll_round": 1,
			"contenders": [0, 1, 2, 3],
			"values": [-1, -1, -1, -1],
			"submitted": [submitted, false, true, true],
			"winner_player_index": -1
		}

	func get_test_table_viewer_index() -> int:
		return 0

	func can_start_first_real_round() -> bool:
		return false

	func start_first_real_round() -> bool:
		return false

	func can_submit_first_turn_roll() -> bool:
		return not submitted

	func submit_first_turn_roll() -> bool:
		submitted = true
		return true

	func get_test_table_snapshot() -> Dictionary:
		return {}


class FakeRemoteBid:
	extends Node

	var submitted_bid := -1
	var lobby_seats: Array = []

	func is_running() -> bool:
		return true

	func is_in_room() -> bool:
		return true

	func is_host() -> bool:
		return false

	func is_client() -> bool:
		return true

	func is_match_finished() -> bool:
		return false

	func is_first_turn_roll_active() -> bool:
		return false

	func get_test_table_viewer_index() -> int:
		return 1

	func can_submit_test_bid() -> bool:
		return submitted_bid < 0

	func get_available_test_bids() -> Array[int]:
		var bids: Array[int] = []
		if can_submit_test_bid():
			bids.assign([0, 1])
		return bids

	func submit_test_bid(bid: int) -> bool:
		if not get_available_test_bids().has(bid):
			return false
		submitted_bid = bid
		return true

	func can_submit_test_joker() -> bool:
		return false

	func get_test_table_snapshot() -> Dictionary:
		return {
			"recipient_player_index": 1,
			"round_number": 1,
			"revision": 0,
			"round": {
				"state": Round.State.BIDDING,
				"current_player_index": 1,
				"cards_per_player": 1,
				"bids": [-1, -1, -1, -1],
				"bids_made": 0
			}
		}


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await _test_local_first_player_mapping()
	await _test_remote_roll_pointer_input()
	await _test_remote_first_bid_pointer_input()
	_test_authoritative_network_roll()
	_test_network_bots_roll_automatically()
	print("FIRST_TURN_ROLL_TEST_PASS")
	quit()


func _test_local_first_player_mapping() -> void:
	var main_scene: Variant = load("res://Scenes/main.tscn").instantiate()
	root.add_child(main_scene)
	await process_frame
	assert(not main_scene.first_turn_roll_panel.z_as_relative)
	assert(
		main_scene.first_turn_roll_panel.z_index > main_scene.network_table_view.z_index,
		"The roll dialog must stay above the full-screen remote table on desktop"
	)
	main_scene._reset_game_session()
	main_scene._begin_local_first_turn_roll()
	main_scene.local_first_turn_roll_random.seed = 20260726
	assert(main_scene.first_turn_roll_panel.visible, "Local game must open with the first-turn roll")
	assert(main_scene.first_turn_roll_grid.get_child_count() == 4, "Roll panel must show all four participants")
	assert(main_scene.first_turn_roll_panel.size.x >= 700.0, "Four dice slots must fit without clipping")

	for attempt in 20:
		main_scene._perform_local_first_turn_roll()
		if main_scene.local_first_turn_roll_winner_index >= 0:
			break
	assert(main_scene.local_first_turn_roll_winner_index >= 0, "Local dice roll must resolve ties")
	var winner_index: int = main_scene.local_first_turn_roll_winner_index
	assert(
		main_scene.game.dealer_index == posmod(winner_index - 1, main_scene.game.players.size()),
		"The dealer must sit immediately before the first player"
	)
	assert(
		main_scene.game.start_round(1, Round.RoundType.NORMAL, Round.TrumpSuit.RANDOM),
		"First local round must start after the roll"
	)
	assert(main_scene.game.current_round.current_player_index == winner_index, "Dice winner must place the first bid")
	assert(main_scene.game.current_round.lead_player_index == winner_index, "Dice winner must lead the first trick")
	main_scene.queue_free()
	await process_frame


func _test_remote_roll_pointer_input() -> void:
	var main_scene: Variant = load("res://Scenes/main.tscn").instantiate()
	root.add_child(main_scene)
	await process_frame
	var fake_remote := FakeRemoteRoll.new()
	main_scene.add_child(fake_remote)
	main_scene.remote_enet_match = fake_remote
	main_scene.remote_enet_table_presentation = true
	main_scene.network_table_view.visible = true
	main_scene._refresh_network_table_view()
	await process_frame

	assert(not main_scene.first_turn_roll_button.disabled)
	var pointer_press := InputEventMouseButton.new()
	pointer_press.button_index = MOUSE_BUTTON_LEFT
	pointer_press.pressed = true
	pointer_press.position = main_scene.first_turn_roll_button.get_global_rect().get_center()
	main_scene._input(pointer_press)
	assert(fake_remote.submitted, "A pointer press must reach the remote roll action through the full-screen table")
	main_scene.queue_free()
	await process_frame


func _test_remote_first_bid_pointer_input() -> void:
	var main_scene: Variant = load("res://Scenes/main.tscn").instantiate()
	root.add_child(main_scene)
	await process_frame
	var fake_remote := FakeRemoteBid.new()
	main_scene.add_child(fake_remote)
	main_scene.remote_enet_match = fake_remote
	main_scene.remote_enet_table_presentation = true
	main_scene.network_table_view.visible = true
	main_scene._refresh_network_table_action_controls(fake_remote.get_test_table_snapshot())
	await process_frame

	assert(main_scene.network_table_action_panel.visible, "The active remote bidder must see the action panel")
	assert(main_scene.network_table_action_panel.z_index > main_scene.network_table_hand_container.z_index)
	var first_button := main_scene.network_table_action_controls.get_child(1).get_child(0) as Button
	var bid_button: Button = main_scene._find_enabled_button_at_position(
		main_scene.network_table_action_controls,
		first_button.get_global_rect().get_center()
	)
	assert(bid_button != null, "The first bid button must have a tappable on-screen rectangle")
	var touch := InputEventScreenTouch.new()
	touch.pressed = true
	touch.position = bid_button.get_global_rect().get_center()
	main_scene._input(touch)
	assert(fake_remote.submitted_bid == 0, "The full-screen remote table must not swallow Android bid input")
	main_scene.queue_free()
	await process_frame


func _test_authoritative_network_roll() -> void:
	var network := LoopbackNetwork.new()
	root.add_child(network)
	network.mode = LoopbackNetwork.Mode.HOST
	network.match_host = LocalMatchHost.new(Game.new(["Хост", "Игрок 2", "Игрок 3", "Игрок 4"]))
	network._confirmed_client_peers_by_player = {1: 2, 2: 3, 3: 4}
	assert(network.begin_first_turn_roll(), "Host must start the roll after all seats are confirmed")
	network._first_turn_roll_random.seed = 260726
	assert(network.get_first_turn_roll_state().get("values", []) == [-1, -1, -1, -1], "Roll values must stay hidden before everyone submits")

	for attempt in 20:
		for player_index in network.first_turn_roll_contenders.duplicate():
			network._record_first_turn_roll(player_index, false)
		if network.is_first_turn_roll_complete():
			break
		if network.first_turn_roll_phase == LoopbackNetwork.FirstTurnRollPhase.REVEAL:
			network._start_first_turn_roll_round(network.first_turn_roll_contenders.duplicate())
	assert(network.is_first_turn_roll_complete(), "Authoritative roll must resolve ties")

	var state := network.get_first_turn_roll_state()
	var winner_index := int(state.get("winner_player_index", -1))
	assert(winner_index >= 0, "Network roll must publish a winner")
	assert(network.match_host.game.dealer_index == posmod(winner_index - 1, 4), "Network dealer mapping must give the winner first action")
	assert(network.start_first_real_round(), "The first network round must start after the roll")
	assert(network.match_host.game.current_round.current_player_index == winner_index, "Network roll winner must place the first bid")
	assert(network.match_host.game.current_round.lead_player_index == winner_index, "Network roll winner must lead the first trick")
	network.queue_free()


func _test_network_bots_roll_automatically() -> void:
	var network := SteamP2PMatch.new()
	root.add_child(network)
	network.mode = LoopbackNetwork.Mode.HOST
	network._expected_remote_player_count = 0
	network._local_bot_player_indices.assign([1, 2, 3])
	network.match_host = LocalMatchHost.new(Game.new(["Хост", "Бот 1", "Бот 2", "Бот 3"]))
	assert(network.begin_first_turn_roll(), "Host-and-bots table must start the roll")
	var state := network.get_first_turn_roll_state()
	var submitted: Array = state.get("submitted", [])
	assert(not submitted[0], "Human host must roll manually")
	assert(submitted[1] and submitted[2] and submitted[3], "Bots must roll automatically")
	network.queue_free()
