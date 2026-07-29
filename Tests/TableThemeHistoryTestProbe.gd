extends SceneTree


const MatchHost := preload("res://Scripts/core/LocalMatchHost.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var main_scene: Variant = load("res://Scenes/main.tscn").instantiate()
	root.add_child(main_scene)
	await process_frame

	assert(main_scene.TABLE_FELT_NAMES.size() == 3, "Settings must expose three felt colors")
	assert(main_scene.TABLE_SURROUND_NAMES.size() == 5, "Settings must expose five table surroundings")
	main_scene.table_felt_theme = main_scene.TableFeltTheme.BLUE
	main_scene.table_surround_theme = main_scene.TableSurroundTheme.LIGHT_OAK
	main_scene._apply_table_theme()
	var cloth_style: StyleBoxFlat = main_scene.local_table_cloth.get_theme_stylebox("panel")
	assert(cloth_style.bg_color.is_equal_approx(main_scene._get_felt_color()), "The selected felt must be applied to the live table")
	var backdrop_material: ShaderMaterial = main_scene.background.material
	assert(backdrop_material != null, "The selected surroundings must use the procedural finish material")
	assert(int(backdrop_material.get_shader_parameter("pattern_kind")) == 1, "Oak surroundings must use the wood pattern")

	main_scene._show_settings_menu()
	assert(main_scene.menu_content.find_child("TableFeltThemeSelector", true, false) != null, "Settings must contain a felt selector")
	assert(main_scene.menu_content.find_child("TableSurroundThemeSelector", true, false) != null, "Settings must contain a surroundings selector")
	assert(main_scene.menu_content.find_child("TableThemePreview", true, false) != null, "Settings must contain a live table preview")

	var host_game := Game.new(["Хост", "Олег", "Маша", "Лена"])
	var host := MatchHost.new(host_game)
	host.public_history.assign(["Скрытая старая карта"])
	host.public_table_events.assign([
		{"event_id": 1, "kind": "played_card", "card": {"suit": Card.Suit.CLUBS, "rank": Card.Rank.SIX, "is_joker": false}},
		{"event_id": 2, "kind": "played_card", "card": {"suit": Card.Suit.HEARTS, "rank": Card.Rank.ACE, "is_joker": false}},
		{"event_id": 3, "kind": "reaction", "reaction": "😄"}
	])
	var last_card := Card.new()
	last_card.suit = Card.Suit.HEARTS
	last_card.rank = Card.Rank.ACE
	host_game.last_completed_trick_cards.assign([last_card])
	host_game.last_completed_trick_played_by.assign([1])
	host_game.last_trick_winner_index = 1

	host.set_history_mode(MatchHost.HistoryMode.LAST_TRICK_ONLY)
	var restricted_snapshot := host.create_player_snapshot(0)
	assert(int(restricted_snapshot.get("history_mode", -1)) == MatchHost.HistoryMode.LAST_TRICK_ONLY, "Snapshots must publish the host history rule")
	assert((restricted_snapshot.get("public_history", []) as Array).is_empty(), "Restricted snapshots must not transmit the old public journal")
	var restricted_events: Array = restricted_snapshot.get("public_table_events", [])
	assert(restricted_events.size() == 2, "Restricted snapshots must retain only the visible trick event and non-card events")
	assert(int((restricted_events[0] as Dictionary).get("event_id", -1)) == 2, "Restricted snapshots must drop card events older than the last visible trick")
	assert((restricted_snapshot.get("last_completed_trick", {}) as Dictionary).get("cards", []).size() == 1, "Restricted snapshots must retain the last completed trick")

	host.set_history_mode(MatchHost.HistoryMode.FULL)
	var full_snapshot := host.create_player_snapshot(0)
	assert((full_snapshot.get("public_history", []) as Array).size() == 1, "Full history mode must retain the complete public journal")

	print("TABLE_THEME_HISTORY_TEST_PASS")
	quit()
