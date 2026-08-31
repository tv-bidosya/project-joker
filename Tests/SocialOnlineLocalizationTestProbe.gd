extends SceneTree

class OfflineBridge extends SteamBridge:
	var probe_state: Dictionary = {"initialized": false, "lobby_id": 0}
	var probe_summary: Dictionary = {}
	func get_lobby_state() -> Dictionary:
		return probe_state
	func get_lobby_summary(_lobby_id: int) -> Dictionary:
		return probe_summary
	func request_lobby_summary(_lobby_id: int) -> bool:
		return false

var scene: Variant
var cyrillic := RegEx.new()

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	cyrillic.compile("[А-Яа-яЁё]")
	scene = load("res://Scenes/main.tscn").instantiate()
	scene.persistent_settings_writes_enabled = false
	scene.persistent_settings_path = "user://social_online_probe_%d.cfg" % Time.get_ticks_usec()
	scene.session_save_path = "user://social_online_probe_%d.save" % Time.get_ticks_usec()
	root.add_child(scene)
	await process_frame
	scene.set_process(false)
	scene._stop_background_music()
	var bridge := OfflineBridge.new()
	scene.steam_bridge = bridge
	for i in scene.game.players.size():
		scene.game.players[i].display_name = "Player%d" % i
	var sounds: Array = scene.soundpad_sounds.duplicate()
	assert(not sounds.is_empty())
	var original_paths: Array[String] = []
	for sound in sounds:
		original_paths.append(str(sound.get("path", "")))
	for locale in ["ru", "en", "uk", "pl", "be", "kz", "en"]:
		scene.interface_locale = locale
		TranslationServer.set_locale(locale)
		scene._relocalize_runtime_controls()
		scene.muted_network_player_indices.clear()
		scene._refresh_player_avatar_badges()
		assert(scene.avatar_mute_buttons[1].tooltip_text == tr("Отключить звуки саундпада этого игрока"))
		scene.muted_network_player_indices[1] = true
		scene._refresh_player_avatar_badges()
		assert(scene.avatar_mute_buttons[1].tooltip_text == tr("Включить звуки саундпада этого игрока"))
		scene._refresh_avatar_mute_buttons({"players": [{"player_index": 1, "display_name": "Player1"}]}, 0)
		assert(scene.avatar_mute_buttons[1].tooltip_text == tr("Включить саундпад этого игрока только у себя"))
		scene.muted_network_player_indices.clear()
		scene._refresh_avatar_mute_buttons({}, 0)
		assert(scene.avatar_mute_buttons[1].tooltip_text == tr("Отключить саундпад этого игрока только у себя"))
		scene._build_sticker_target_picker()
		assert(scene.sticker_picker_title.text == tr("Кому отправить подарок?"))
		_check_english(scene.sticker_picker, locale)
		scene.sticker_selected_target_index = 1
		scene._build_sticker_choice_picker()
		assert(scene.sticker_picker_title.text == tr("Что подарить %s?") % "Player1")
		assert(scene._get_builtin_stickers().size() == 10)
		_check_english(scene.sticker_picker, locale)
		_check_english(scene.reaction_picker, locale)
		scene._build_soundpad_category_picker()
		assert(scene.soundpad_picker_title.text == tr("Саундбар · выбери категорию"))
		_check_english(scene.soundpad_picker, locale)
		scene.soundpad_selected_category_id = "root"
		scene._build_soundpad_sound_picker()
		assert(scene.soundpad_picker_title.text == tr("Саундбар · %s") % tr("Общее"))
		_check_english(scene.soundpad_picker, locale)
		for i in scene.soundpad_sounds.size():
			assert(scene.soundpad_sounds[i].path == original_paths[i], "Locale must not change network audio IDs")
		var unknown := {"path": "custom/test.wav", "title": "My recording"}
		assert(scene._get_soundpad_display_title(unknown) == "My recording")
		scene.soundpad_sounds.clear()
		scene._build_soundpad_category_picker()
		assert(scene.soundpad_picker_title.text == tr("Саундбар пока пуст"))
		_check_english(scene.soundpad_picker, locale)
		scene.soundpad_sounds.assign(sounds)
		scene.social_action_cooldown_until[0] = Time.get_ticks_msec() + 65000
		_check_string(scene._get_social_action_status_text("Эмоции", 0), locale)
		scene.social_action_cooldown_until.clear()
		_check_string(scene._get_social_action_status_text("Эмоции", 0), locale)
		bridge.probe_state = {"lobby_id": 0}
		scene._clear_children(scene.menu_content)
		scene._build_online_create_room_tab()
		assert(scene.online_team_one_name_edit.text == tr("Команда 1"))
		assert(scene.online_lobby_visibility_selector.get_item_text(1) == tr("Только для друзей"))
		assert(scene.online_lobby_visibility_selector.get_selected_id() == SteamBridge.LobbyVisibility.FRIENDS_ONLY)
		_check_english(scene.menu_content, locale)
		for state in ["empty", "checking", "missing", "available", "current"]:
			bridge.probe_state = {"lobby_id": 0}
			bridge.probe_summary = {}
			scene.active_online_lobby_id = 0 if state == "empty" else 12345
			scene.active_online_match_started = true
			if state == "missing":
				bridge.probe_summary = {"confirmed_missing": true}
			elif state == "available":
				bridge.probe_summary = {"available": true, "lobby_id": 12345, "host_name": "Alice", "match_state": SteamBridge.LOBBY_STATE_PLAYING, "member_count": 3, "member_limit": 4}
			elif state == "current":
				bridge.probe_state = {"lobby_id": 12345, "host_name": "Alice"}
			scene._clear_children(scene.menu_content)
			scene._build_online_my_games_tab()
			_check_english(scene.menu_content, locale)
		var summary: String = scene._get_online_lobby_summary_text({"lobby_id": 12345, "host_name": "Алиса"})
		assert(summary.contains("Алиса") and summary.contains("12345"), "Player names and room IDs must be preserved")
		await process_frame
	print("SOCIAL_ONLINE_SIX_LOCALES_PASS")
	scene.sticker_picker.visible = true
	scene.sticker_selected_target_index = 1
	scene.soundpad_picker.visible = true
	scene.soundpad_selected_category_id = "root"
	TranslationServer.set_locale("ru")
	scene._relocalize_runtime_controls()
	TranslationServer.set_locale("en")
	scene._relocalize_runtime_controls()
	_check_english(scene.sticker_picker, "en")
	_check_english(scene.soundpad_picker, "en")
	assert(scene.soundpad_selected_category_id == "root")
	scene.sticker_picker.visible = false
	scene.soundpad_picker.visible = false
	scene._build_soundpad_category_picker()
	assert(scene.soundpad_selected_category_id.is_empty())
	print("OPEN_PICKERS_LOCALE_SWITCH_PASS")
	bridge.probe_state = {"lobby_id": 0}
	scene.active_online_lobby_id = 0
	scene.game.current_round.player_count = 4
	scene.game.current_round.bids.assign([-1, -1, -1, -1])
	scene.game.current_round.state = Round.State.BIDDING
	scene.game.current_round.current_player_index = 0
	scene.is_processing_automatic_actions = false
	scene.loopback_network_test.mode = scene.loopback_network_test.Mode.HOST
	scene.loopback_network_test.lobby_round_started = true
	scene.loopback_network_test.match_host = load("res://Scripts/core/LocalMatchHost.gd").new(scene.game)
	for mobile in [false, true]:
		scene.mobile_table_layout = mobile
		if mobile:
			scene._apply_mobile_table_layout()
		for count in range(2, 11):
			scene.game.current_round.cards_per_player = count - 1
			scene._refresh_bid_controls()
			await _check_bid_layout(count, mobile)
			scene._refresh_network_main_action_controls({}, {"state": Round.State.BIDDING})
			var actual_count: int = scene.bid_controls.get_child_count()
			assert(actual_count > 0)
			await _check_bid_layout(actual_count, mobile)
	scene.loopback_network_test.match_host = null
	scene.loopback_network_test.mode = scene.loopback_network_test.Mode.NONE
	scene.queue_free()
	await process_frame
	await process_frame
	print("DESKTOP_MOBILE_LOCAL_NETWORK_BIDS_PASS")
	print("SOCIAL_ONLINE_LOCALIZATION_TEST_PASS")
	quit()

func _check_bid_layout(count: int, mobile: bool) -> void:
	await process_frame
	await process_frame
	var expected_columns: int = 3 if mobile else (count if count <= 7 else ceili(count / 2.0))
	assert(scene.bid_controls.columns == expected_columns)
	assert(scene.bid_controls.get_child_count() == count)
	if not mobile:
		var rect: Rect2 = scene.bid_controls.get_global_rect()
		assert(scene.get_viewport_rect().encloses(rect), "Desktop bids must fit in viewport")
		for panel in scene.player_panels:
			assert(not rect.intersects(panel.get_global_rect()), "Desktop bids overlap a player")
		for avatar in scene.avatar_badges:
			assert(not rect.intersects(avatar.get_global_rect()), "Desktop bids overlap an avatar")
		assert(ceili(float(count) / expected_columns) <= 2)
		for button in scene.bid_controls.get_children():
			assert(rect.grow(0.1).encloses(button.get_global_rect()), "Bid %s count %d outside %s: %s" % [button.text, count, rect, button.get_global_rect()])
	else:
		assert(scene.bid_controls.get_parent().get_parent() == scene.mobile_bid_popup)

func _check_string(value: String, locale: String) -> void:
	if locale == "en":
		assert(cyrillic.search(value) == null, "Untranslated string: " + value)

func _check_english(node: Node, locale: String) -> void:
	if node is Control:
		_check_string(node.tooltip_text, locale)
	if node is Label or node is Button:
		_check_string(node.text, locale)
	if node is LineEdit:
		_check_string(node.text, locale)
		_check_string(node.placeholder_text, locale)
	if node is OptionButton:
		for i in node.item_count:
			_check_string(node.get_item_text(i), locale)
	for child in node.get_children():
		_check_english(child, locale)
