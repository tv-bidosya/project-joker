extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var scene: Variant = load("res://Scenes/main.tscn").instantiate()
	scene.persistent_settings_writes_enabled = false
	root.add_child(scene)
	await process_frame
	scene.mobile_table_layout = true
	scene._load_persistent_settings()
	scene._apply_mobile_table_layout()
	scene.menu_overlay.visible = false
	scene._refresh_social_action_buttons()
	assert(scene.soundpad_toggle_button.text == tr("Саундбар"), "Mobile soundbar must have a clear text label")
	assert(scene.soundpad_toggle_button.icon == null, "Mobile soundbar entry must not have a speaker icon")
	await process_frame
	await process_frame
	for button in [scene.round_history_toggle_button, scene.score_sheet_toggle_button, scene.pause_menu_button]:
		assert(button.size.y >= 52.0, "Top actions must have the same touch height as bottom actions")
		assert(scene.mobile_top_bar.get_global_rect().encloses(button.get_global_rect()), "Top buttons must stay inside the bar")
		assert(button.get_theme_font_size("font_size") >= 18, "Top action labels must remain readable")
		for state in ["normal", "hover", "pressed"]:
			var style: StyleBox = button.get_theme_stylebox(state)
			assert(style is StyleBoxTexture, "Top actions must use the framed mobile button texture")
			var bottom_style: StyleBox = scene.undo_button.get_theme_stylebox(state)
			assert(bottom_style is StyleBoxTexture and (style as StyleBoxTexture).texture == (bottom_style as StyleBoxTexture).texture, "Top and bottom actions must use one style")
	print("MOBILE_TOP_ACTIONS_PASS")
	assert(not scene.music_is_paused, "Mobile music must not inherit the removed player's pause")
	assert(not scene.music_repeat_enabled and not scene.music_shuffle_enabled, "Mobile music must cycle sequentially")
	assert(scene._get_available_music_track_count() == 3, "Mobile music must use three built-in themes")
	scene.music_volume_percent = 100
	scene.music_volume_index = 3
	scene._start_background_music()
	assert(scene.background_music_player.playing, "Background music must start")
	scene._on_music_volume_slider_changed(0.0)
	assert(not scene.background_music_player.playing, "Zero volume must stop background music")
	scene._on_music_volume_slider_changed(60.0)
	assert(scene.background_music_player.playing, "Raising volume must resume background music")
	scene._stop_background_music()

	assert(not scene.soundpad_sounds.is_empty(), "Built-in soundbar clips must load")
	scene.sound_volume_percent = 100
	scene.sound_volume_index = 3
	var stream: AudioStream = scene.soundpad_sounds[0].get("stream")
	assert(stream != null and stream.get_length() > 0.0, "Soundbar clip must be valid audio")
	scene._play_soundpad_stream(stream, 0, 0)
	var active_soundbar_players := 0
	for player in scene.soundpad_players:
		if player.playing:
			active_soundbar_players += 1
	assert(active_soundbar_players == 1, "Soundbar must start an audio player")
	assert(scene.avatar_soundpad_indicators[0].visible, "Playing soundbar must show the speaker")
	assert(scene.avatar_soundpad_indicators[0].texture != null, "Speaker must have a real texture")
	scene._stop_all_soundpad_playback()
	assert(not scene.avatar_soundpad_indicators[0].visible, "Speaker must hide when playback stops")
	print("SOUNDBAR_CLIPS_LOADED=", scene.soundpad_sounds.size())

	scene.pending_joker_card = scene._create_card(Card.Suit.SPADES, Card.Rank.SEVEN, true)
	scene.game.active_trick = null
	scene.pending_joker_suit = -1
	scene._refresh_joker_controls()
	assert(await _check_joker_layout(scene, "suit"), "Suit grid must not overlap players")
	scene.pending_joker_suit = Card.Suit.HEARTS
	scene._refresh_joker_controls()
	assert(await _check_joker_layout(scene, "conditions"), "Condition grid must not overlap players")
	scene.game.active_trick = Trick.new()
	scene._refresh_joker_controls()
	assert(await _check_joker_layout(scene, "response"), "Response grid must not overlap players")
	scene.queue_free()
	await process_frame
	print("MOBILE_AUDIO_JOKER_TEST_PASS")
	quit()


func _check_joker_layout(scene: Variant, stage: String) -> bool:
	await process_frame
	await process_frame
	var controls_rect: Rect2 = scene.joker_controls.get_global_rect()
	for panel in scene.player_panels:
		if controls_rect.intersects(panel.get_global_rect()):
			push_error("Joker %s overlaps player panel: %s" % [stage, controls_rect])
			return false
	for avatar in scene.avatar_badges:
		if controls_rect.intersects(avatar.get_global_rect()):
			push_error("Joker %s overlaps avatar: %s" % [stage, controls_rect])
			return false
	if not scene.get_viewport_rect().encloses(controls_rect):
		push_error("Joker %s escapes viewport: %s" % [stage, controls_rect])
		return false
	for child in scene.joker_controls.get_children():
		if not controls_rect.encloses(child.get_global_rect()):
			push_error("Joker %s button escapes grid" % stage)
			return false
	print("JOKER_LAYOUT_", stage, "=", controls_rect)
	return true