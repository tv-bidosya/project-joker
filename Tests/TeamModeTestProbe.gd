extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var team_match := SteamP2PMatch.new()
	team_match.host_steam_id = 100
	var members := [
		{"steam_id": 100, "team_id": 0},
		{"steam_id": 200, "team_id": 1},
		{"steam_id": 300, "team_id": 0},
		{"steam_id": 400, "team_id": 1},
	]
	assert(team_match._build_team_seat_preferences(members), "A balanced 2v2 lobby must produce a seat layout.")
	assert(int(team_match._preferred_player_index_by_steam_id[100]) == 0, "The host must occupy seat 1.")
	assert(int(team_match._preferred_player_index_by_steam_id[300]) == 2, "The host partner must sit opposite at seat 3.")
	assert(int(team_match._preferred_player_index_by_steam_id[200]) == 1, "The first opposing player must occupy seat 2.")
	assert(int(team_match._preferred_player_index_by_steam_id[400]) == 3, "The second opposing player must sit opposite at seat 4.")

	team_match._preferred_player_index_by_steam_id.clear()
	var unbalanced_members := [
		{"steam_id": 100, "team_id": 0},
		{"steam_id": 200, "team_id": 0},
		{"steam_id": 300, "team_id": 0},
	]
	assert(not team_match._build_team_seat_preferences(unbalanced_members), "A team may not contain a third human player.")

	var main_scene: Variant = load("res://Scenes/main.tscn").instantiate()
	root.add_child(main_scene)
	await process_frame
	var snapshot := {
		"match_mode": SteamBridge.MATCH_MODE_TEAMS_2V2,
		"team_names": ["Север", "Юг"],
		"team_by_player": [0, 1, 0, 1],
		"players": [
			{"player_index": 0, "total_score": 12, "exact_orders_completed": 4},
			{"player_index": 1, "total_score": 20, "exact_orders_completed": 2},
			{"player_index": 2, "total_score": -5, "exact_orders_completed": 3},
			{"player_index": 3, "total_score": 3, "exact_orders_completed": 1},
		],
	}
	assert(main_scene._get_network_team_score(snapshot, 0) == 7, "Seats 1 and 3 must share their summed score.")
	assert(main_scene._get_network_team_score(snapshot, 1) == 23, "Seats 2 and 4 must share their summed score.")
	assert(main_scene._get_network_team_name(snapshot, 0) == "Север", "The custom team name must reach the table.")
	var standings: Array[Dictionary] = main_scene._get_network_final_standings(snapshot)
	assert(standings.size() == 2, "A 2v2 match must produce two final team standings.")
	assert(str(standings[0].get("name", "")) == "Юг" and int(standings[0].get("score", 0)) == 23, "The higher combined team score must win.")

	(snapshot["players"][0] as Dictionary)["total_score"] = 28
	standings = main_scene._get_network_final_standings(snapshot)
	assert(str(standings[0].get("name", "")) == "Север", "With equal scores, the team with more exact bids must win.")
	assert(not bool(standings[0].get("shares_place", false)), "Different exact-bid totals must not share first place.")

	(snapshot["players"][0] as Dictionary)["exact_orders_completed"] = 0
	standings = main_scene._get_network_final_standings(snapshot)
	assert(bool(standings[0].get("shares_place", false)) and bool(standings[1].get("shares_place", false)), "Equal team scores and exact bids must share first place.")

	main_scene.local_match_mode = SteamBridge.MATCH_MODE_TEAMS_2V2
	main_scene.game.players[0].total_score = 12
	main_scene.game.players[1].total_score = 20
	main_scene.game.players[2].total_score = -5
	main_scene.game.players[3].total_score = 3
	main_scene.game.players[0].exact_orders_completed = 4
	main_scene.game.players[1].exact_orders_completed = 2
	main_scene.game.players[2].exact_orders_completed = 3
	main_scene.game.players[3].exact_orders_completed = 1
	assert(main_scene._get_local_team_score(0) == 7, "Local seats 1 and 3 must share their summed score.")
	assert(main_scene._get_local_team_score(1) == 23, "Local seats 2 and 4 must share their summed score.")
	standings = main_scene._get_final_standings()
	assert(standings.size() == 2, "A local 2v2 bot match must produce two team standings.")
	assert(int(standings[0].get("player_id", -1)) == 1 and int(standings[0].get("score", 0)) == 23, "The higher-scoring local bot team must win.")

	main_scene.queue_free()
	team_match.free()
	await process_frame
	print("TEAM_MODE_TEST_PASS")
	quit()
