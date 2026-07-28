extends SceneTree


const LocalMatchHost = preload("res://Scripts/core/LocalMatchHost.gd")
const LoopbackNetwork = preload("res://Scripts/core/LoopbackNetworkTest.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var main_scene: Variant = load("res://Scenes/main.tscn").instantiate()
	root.add_child(main_scene)
	await process_frame
	await _test_turn_reminder(main_scene)
	_test_network_human_auto_turn()
	_test_network_menu_stays_open(main_scene)
	_test_network_profile_name_update()
	print("NETWORK_QUALITY_OF_LIFE_TEST_PASS")
	quit()


func _test_turn_reminder(main_scene: Variant) -> void:
	main_scene.game = Game.new(["Я", "Бот 1", "Бот 2", "Бот 3"])
	main_scene.game.dealer_index = 3
	assert(main_scene.game.start_round(1, Round.RoundType.NORMAL, Round.TrumpSuit.CLUBS))
	main_scene.sound_volume_index = 0
	main_scene.bot_speed_index = 2
	main_scene.auto_turn_enabled = false
	main_scene._stop_human_turn_timer()
	main_scene._reset_turn_reminder()
	main_scene._process_turn_reminder(9.9)
	assert(not main_scene.turn_reminder_was_played, "Turn reminder must stay silent before ten seconds")
	main_scene._process_turn_reminder(0.2)
	assert(main_scene.turn_reminder_was_played, "Turn reminder must trigger after ten seconds")
	assert(main_scene.turn_reminder_play_count == 1, "The first reminder must be counted")
	main_scene._process_turn_reminder(10.0)
	assert(main_scene.turn_reminder_play_count == 2, "Turn reminder must repeat every ten seconds")
	main_scene._reset_turn_reminder()
	main_scene._process_turn_reminder(119.9)
	assert(not main_scene.turn_timer_active, "Fallback auto-turn timer must stay hidden during the first two minutes")
	main_scene._process_turn_reminder(0.2)
	assert(main_scene.turn_timer_active, "Fallback auto-turn timer must start after two minutes of inactivity")
	assert(main_scene.auto_turn_enabled, "Two minutes of inactivity must latch auto-turn on until the player disables it")
	assert(is_equal_approx(main_scene.turn_timer_remaining, 60.0), "Fallback auto-turn countdown must start at 60 seconds")
	var bids_before_timeout: int = main_scene.game.current_round.bids_made
	main_scene._process(60.1)
	assert(main_scene.game.current_round.bids_made > bids_before_timeout, "Fallback countdown must finish with a valid local auto-bid")
	assert(not main_scene.turn_timer_active, "Fallback countdown must stop after the automatic decision")
	main_scene._process_turn_reminder(0.1)
	assert(not main_scene.turn_reminder_was_played, "Reminder must reset when it is no longer the local player's turn")
	assert(main_scene.turn_reminder_play_count == 0, "Reminder count must reset after the decision changes")
	await create_timer(0.8).timeout
	assert(main_scene.turn_timer_active, "Latched local auto-turn must start at once on the player's next decision")
	main_scene._on_auto_turn_toggled(false)
	assert(not main_scene.auto_turn_enabled and not main_scene.turn_timer_active, "The player setting must disable latched local auto-turn")


func _test_network_human_auto_turn() -> void:
	var steam_match := SteamP2PMatch.new()
	steam_match.mode = LoopbackNetwork.Mode.HOST
	steam_match.lobby_round_started = true
	var network_game := Game.new(["Host", "Player 2", "Player 3", "Player 4"])
	network_game.dealer_index = 3
	assert(network_game.start_round(1, Round.RoundType.NORMAL, Round.TrumpSuit.CLUBS))
	steam_match.match_host = LocalMatchHost.new(network_game)
	var initial_revision: int = steam_match.match_host.revision
	steam_match._process_human_auto_turn(0.0)
	steam_match._process_human_auto_turn(119.9)
	assert(steam_match.match_host.revision == initial_revision, "Network auto-turn must wait during the first two minutes")
	steam_match._process_human_auto_turn(0.2)
	assert(steam_match.match_host.revision == initial_revision, "Network auto-turn must start a 60-second grace countdown after two minutes")
	assert(steam_match._human_auto_turn_enabled_by_player.has(0), "Network AFK must latch auto-turn on for that player")
	steam_match._process_human_auto_turn(59.7)
	assert(steam_match.match_host.revision == initial_revision, "Network auto-turn must wait until the grace countdown ends")
	steam_match._process_human_auto_turn(0.3)
	assert(steam_match.match_host.revision == initial_revision + 1, "Host must perform a network auto-turn after 120 plus 60 seconds")
	assert(network_game.current_round.bids_made == 1, "Timed-out network bidder must receive a valid automatic bid")
	for player_index in range(1, 4):
		steam_match._set_player_auto_turn_enabled(player_index, true, false)

	var bid_guard := 0
	while network_game.current_round.state == Round.State.BIDDING and bid_guard < 4:
		steam_match._reset_human_auto_turn()
		steam_match._process_human_auto_turn(0.0)
		steam_match._process_human_auto_turn(60.1)
		bid_guard += 1
	assert(network_game.current_round.state == Round.State.PLAYING, "Network auto-turn must finish the bidding phase")

	var playing_revision: int = steam_match.match_host.revision
	var playing_player_index: int = steam_match._get_host_current_playing_player_index()
	assert(playing_player_index == 0, "The first bidder must lead so the same AFK player can verify latched auto-turn")
	var hand_size_before: int = network_game.players[playing_player_index].hand.size()
	steam_match._reset_human_auto_turn()
	steam_match._process_human_auto_turn(0.0)
	steam_match._process_human_auto_turn(60.1)
	assert(steam_match.match_host.revision == playing_revision + 1, "Host must play a legal network card after the timeout")
	assert(network_game.players[playing_player_index].hand.size() == hand_size_before - 1, "Timed-out network player must play exactly one card")
	steam_match.set_local_auto_turn_enabled(false)
	assert(not steam_match._human_auto_turn_enabled_by_player.has(0), "Only the player setting must disable latched network auto-turn")

	var reset_game := Game.new(["Host", "Player 2", "Player 3", "Player 4"])
	reset_game.dealer_index = 3
	assert(reset_game.start_round(1, Round.RoundType.NORMAL, Round.TrumpSuit.CLUBS))
	steam_match.match_host = LocalMatchHost.new(reset_game)
	steam_match._reset_human_auto_turn()
	steam_match._process_human_auto_turn(0.0)
	steam_match._process_human_auto_turn(60.1)
	assert(steam_match.match_host.revision == 0, "Manual disable must restore the initial two-minute AFK wait")
	steam_match._process_human_auto_turn(60.0)
	assert(steam_match.match_host.revision == 0, "Two-minute AFK must enable the timer without making an immediate move")
	assert(steam_match._human_auto_turn_enabled_by_player.has(0), "AFK must be able to latch auto-turn on again after manual disable")
	steam_match.free()


func _test_network_menu_stays_open(main_scene: Variant) -> void:
	var steam_match := SteamP2PMatch.new()
	main_scene.add_child(steam_match)
	steam_match.mode = LoopbackNetwork.Mode.HOST
	steam_match._transport_active = true
	var network_game := Game.new(["Хост", "Игрок 2", "Игрок 3", "Игрок 4"])
	network_game.dealer_index = 3
	assert(network_game.start_round(1, Round.RoundType.NORMAL, Round.TrumpSuit.CLUBS))
	steam_match.match_host = LocalMatchHost.new(network_game)
	main_scene.steam_p2p_match = steam_match
	main_scene.steam_p2p_table_presentation = true
	main_scene.steam_p2p_main_table_presentation = true
	assert(not main_scene._get_local_turn_reminder_decision_key().is_empty(), "Network host must be reminded only on the host's own turn")
	network_game.current_round.current_player_index = 1
	assert(main_scene._get_local_turn_reminder_decision_key().is_empty(), "Network host must stay silent during another player's turn")
	main_scene.is_pause_menu_open = true
	main_scene.menu_overlay.visible = true
	main_scene._refresh_network_main_table()
	assert(main_scene.menu_overlay.visible, "Incoming network refresh must not close an open menu")
	main_scene.steam_p2p_match = null
	steam_match.queue_free()


func _test_network_profile_name_update() -> void:
	var network := LoopbackNetwork.new()
	network.mode = LoopbackNetwork.Mode.HOST
	network.match_host = LocalMatchHost.new(Game.new(["Хост", "Игрок 2", "Игрок 3", "Игрок 4"]))
	network._connected_player_by_peer[22] = 1
	network._connected_client_peers_by_player[1] = 22
	network._confirmed_client_peers_by_player[1] = 22
	network._handle_host_profile_name({
		"player_index": 1,
		"display_name": "Тестер",
		"avatar_index": 3,
		"avatar_data": "dGVzdA=="
	}, 22)
	assert(network.match_host.game.players[1].display_name == "Тестер", "Host must apply a client's profile name")
	assert(int(network._avatar_index_by_player.get(1, -1)) == 3, "Host must apply a client's avatar choice")
	assert(str(network._avatar_data_by_player.get(1, "")) == "dGVzdA==", "Host must retain the avatar preview payload")
	network.update_local_profile("Ведущий", 2)
	assert(network.match_host.game.players[0].display_name == "Ведущий", "Host profile name must update live")
	assert(int(network._avatar_index_by_player.get(0, -1)) == 2, "Host avatar must update live")
	network.free()
