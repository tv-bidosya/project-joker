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
	await process_frame
	assert(main_scene.chat_toggle_button.visible, "The Steam table must expose a room chat button")
	assert(main_scene.chat_panel.visible, "The room chat must open by default on the Steam table")
	assert(main_scene.chat_panel.size.y <= 330.0, "The docked chat must use the compact lower-right height")
	var chat_style := main_scene.chat_panel.get_theme_stylebox("panel") as StyleBoxFlat
	assert(chat_style != null and chat_style.bg_color.r > 0.9, "The chat must use the light history-style background")
	var chat_title := main_scene.chat_panel.find_child("ChatTitle", true, false) as Label
	assert(chat_title != null and chat_title.text == "ЧАТ", "The compact panel title must stay concise")
	assert(main_scene.social_controls_container.size.y <= 110.0, "Three social controls must form a compact stack")
	var player_panel_center_y: float = (
		float(main_scene.player_panels[0].position.y)
		+ float(main_scene.player_panels[0].size.y) * 0.5
	)
	var social_controls_center_y: float = (
		float(main_scene.social_controls_container.position.y)
		+ float(main_scene.social_controls_container.size.y) * 0.5
	)
	assert(
		absf(player_panel_center_y - social_controls_center_y) <= 10.0,
		"The social controls must stay centred beside the local player panel"
	)
	assert(
		is_equal_approx(main_scene.chat_panel.anchor_left, 1.0)
		and main_scene.chat_panel.offset_right <= -20.0,
		"The chat panel must be docked in the right lane"
	)
	var maximum_hand_right: float = float(main_scene.players_container.size.x) * 0.5 + 436.0
	var chat_panel_left: float = float(main_scene.players_container.size.x) + float(main_scene.chat_panel.offset_left)
	assert(chat_panel_left > maximum_hand_right, "The docked chat must not overlap a centred nine-card hand")
	main_scene._close_chat_panel()

	main_scene._present_network_chat_event({
		"event_id": 50,
		"kind": "chat",
		"actor_player_index": 1,
		"message": "Виден даже при муте саундпада"
	}, 0)
	assert(main_scene.network_chat_messages.size() == 1, "A network chat event must be appended to the local chat log")
	assert(main_scene.chat_unread_count == 1, "A hidden chat panel must count unread remote messages")

	main_scene.muted_network_player_indices[1] = true
	main_scene._hide_reaction_bubble()
	main_scene._present_network_reaction_event({"actor_player_index": 1, "reaction": "😄"}, 0)
	assert(main_scene.reaction_bubble.visible, "Soundpad mute must not hide a player's reaction")
	main_scene._hide_all_sticker_flyers()
	main_scene._present_network_sticker_event({
		"actor_player_index": 1,
		"target_player_index": 0,
		"sticker": "🌹"
	}, 0)
	assert(main_scene.sticker_flyers[0].visible, "Soundpad mute must not hide a player's gift")
	var test_sound := AudioStreamWAV.new()
	main_scene.soundpad_sounds.clear()
	main_scene.soundpad_sounds.append({"path": "test-muted-sound", "stream": test_sound})
	main_scene._hide_soundpad_bubble()
	main_scene._present_network_soundpad_event({
		"actor_player_index": 1,
		"sound_id": "test-muted-sound"
	}, 0)
	assert(main_scene.soundpad_bubble.visible, "Soundpad mute must keep the visual sound cue")
	for soundpad_player: AudioStreamPlayer in main_scene.soundpad_players:
		assert(soundpad_player.stream == null, "Soundpad mute must suppress only the remote audio stream")

	print("NETWORK_CHAT_SOUND_MUTE_TEST_PASS")
	quit()
