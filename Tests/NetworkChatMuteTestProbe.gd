extends SceneTree


const MatchHost := preload("res://Scripts/core/LocalMatchHost.gd")
const MatchCommand := preload("res://Scripts/core/MatchCommand.gd")
const LoopbackNetwork := preload("res://Scripts/core/LoopbackNetworkTest.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var game := Game.new(["Хост", "Олег", "Маша", "Лена"])
	var host := MatchHost.new(game)
	var chat_command := MatchCommand.new(
		MatchCommand.Type.SOCIAL_ACTION,
		1,
		game.round_number,
		host.revision,
		{"kind": "chat", "message": "  Всем привет!\nИграем?  "}
	)
	var result := host.apply_command(chat_command)
	assert(bool(result.get("accepted", false)), "The host must accept a valid room chat message")
	var snapshot := host.create_player_snapshot(0)
	var events: Array = snapshot.get("public_table_events", [])
	assert(events.size() == 1 and str((events[0] as Dictionary).get("kind", "")) == "chat")
	assert(str((events[0] as Dictionary).get("message", "")) == "Всем привет! Играем?", "The host must sanitize chat line breaks")

	var immediate_repeat := MatchCommand.new(
		MatchCommand.Type.SOCIAL_ACTION,
		1,
		game.round_number,
		host.revision,
		{"kind": "chat", "message": "Спам"}
	)
	var repeat_result := host.apply_command(immediate_repeat)
	assert(not bool(repeat_result.get("accepted", true)), "Chat messages must be rate-limited by the host")
	assert(str(repeat_result.get("reason", "")) == "chat_cooldown")

	var too_long_host := MatchHost.new(Game.new(["Хост", "Олег", "Маша", "Лена"]))
	var too_long_command := MatchCommand.new(
		MatchCommand.Type.SOCIAL_ACTION,
		1,
		too_long_host.game.round_number,
		too_long_host.revision,
		{"kind": "chat", "message": "я".repeat(MatchHost.CHAT_MESSAGE_MAX_LENGTH + 1)}
	)
	var too_long_result := too_long_host.apply_command(too_long_command)
	assert(not bool(too_long_result.get("accepted", true)), "The host must reject overlong chat messages")
	assert(str(too_long_result.get("reason", "")) == "chat_message_too_long")

	var main_scene: Variant = load("res://Scenes/main.tscn").instantiate()
	root.add_child(main_scene)
	await process_frame
	var steam_match := SteamP2PMatch.new()
	main_scene.add_child(steam_match)
	steam_match.mode = LoopbackNetwork.Mode.HOST
	steam_match._transport_active = true
	steam_match.lobby_round_started = true
	var network_game := Game.new(["Хост", "Олег", "Маша", "Лена"])
	assert(network_game.start_round(1, Round.RoundType.NORMAL, Round.TrumpSuit.CLUBS))
	steam_match.match_host = MatchHost.new(network_game)
	main_scene.steam_p2p_match = steam_match
	main_scene.steam_p2p_table_presentation = true
	main_scene.steam_p2p_main_table_presentation = true
	main_scene._refresh_network_main_table()
	assert(main_scene.chat_toggle_button.visible, "The Steam table must expose a room chat button")
	assert(main_scene.social_controls_container.size.y >= 124.0, "Three social controls must fit without overlapping")
	assert(
		main_scene.chat_panel.offset_left >= main_scene.social_controls_container.offset_right,
		"The chat panel must open to the right of the social controls"
	)

	main_scene._present_network_chat_event({
		"event_id": 50,
		"kind": "chat",
		"actor_player_index": 1,
		"message": "Виден даже при визуальном муте"
	}, 0)
	assert(main_scene.network_chat_messages.size() == 1, "A network chat event must be appended to the local chat log")
	assert(main_scene.chat_unread_count == 1, "A hidden chat panel must count unread remote messages")

	main_scene.muted_network_player_indices[1] = true
	main_scene._hide_reaction_bubble()
	main_scene._present_network_reaction_event({"actor_player_index": 1, "reaction": "😄"}, 0)
	assert(not main_scene.reaction_bubble.visible, "A muted player's reaction must stay hidden locally")
	main_scene._hide_all_sticker_flyers()
	main_scene._present_network_sticker_event({
		"actor_player_index": 1,
		"target_player_index": 0,
		"sticker": "🌹"
	}, 0)
	assert(not main_scene.sticker_flyers[0].visible, "A muted player's gift must stay hidden locally")
	main_scene._hide_soundpad_bubble()
	main_scene._present_network_soundpad_event({
		"actor_player_index": 1,
		"sound_id": ""
	}, 0)
	assert(not main_scene.soundpad_bubble.visible, "A muted player's sound bubble must stay hidden locally")

	print("NETWORK_CHAT_MUTE_TEST_PASS")
	quit()
