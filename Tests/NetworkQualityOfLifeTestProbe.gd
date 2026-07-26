extends SceneTree


const LocalMatchHost = preload("res://Scripts/core/LocalMatchHost.gd")
const LoopbackNetwork = preload("res://Scripts/core/LoopbackNetworkTest.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var main_scene: Variant = load("res://Scenes/main.tscn").instantiate()
	root.add_child(main_scene)
	await process_frame
	_test_turn_reminder(main_scene)
	_test_network_menu_stays_open(main_scene)
	_test_network_profile_name_update()
	print("NETWORK_QUALITY_OF_LIFE_TEST_PASS")
	quit()


func _test_turn_reminder(main_scene: Variant) -> void:
	main_scene.game = Game.new(["Я", "Бот 1", "Бот 2", "Бот 3"])
	main_scene.game.dealer_index = 3
	assert(main_scene.game.start_round(1, Round.RoundType.NORMAL, Round.TrumpSuit.CLUBS))
	main_scene.sound_volume_index = 0
	main_scene._reset_turn_reminder()
	main_scene._process_turn_reminder(9.9)
	assert(not main_scene.turn_reminder_was_played, "Turn reminder must stay silent before ten seconds")
	main_scene._process_turn_reminder(0.2)
	assert(main_scene.turn_reminder_was_played, "Turn reminder must trigger after ten seconds")
	main_scene.game.current_round.current_player_index = 1
	main_scene._process_turn_reminder(0.1)
	assert(not main_scene.turn_reminder_was_played, "Reminder must reset when it is no longer the local player's turn")


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
		"display_name": "Тестер"
	}, 22)
	assert(network.match_host.game.players[1].display_name == "Тестер", "Host must apply a client's profile name")
	network.update_local_display_name("Ведущий")
	assert(network.match_host.game.players[0].display_name == "Ведущий", "Host profile name must update live")
	network.free()
