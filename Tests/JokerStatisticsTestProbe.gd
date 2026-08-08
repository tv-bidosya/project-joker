extends SceneTree


const MatchHost := preload("res://Scripts/core/LocalMatchHost.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var game := Game.new(["Хост", "Олег", "Маша", "Лена"])
	game.dealer_index = 3
	assert(game.start_round(9, Round.RoundType.NORMAL, Round.TrumpSuit.CLUBS))
	var dealt_jokers := 0
	for count in game.jokers_dealt_this_round:
		dealt_jokers += count
	assert(dealt_jokers == 1, "A full fixed-trump deal must account for the deck's Joker exactly once")

	var restored_game := Game.new(["Хост", "Олег", "Маша", "Лена"])
	restored_game.restore_snapshot(game.create_snapshot())
	assert(restored_game.jokers_dealt_this_round == game.jokers_dealt_this_round, "Undo/session snapshots must preserve dealt-Joker statistics")

	var host := MatchHost.new(game)
	host._record_completed_round([0, 0, 0, 0])
	var recorded_total := 0
	for result_variant in (host.completed_round_history[0] as Dictionary).get("players", []):
		recorded_total += int((result_variant as Dictionary).get("jokers_dealt", 0))
	assert(recorded_total == 1, "Completed network rounds must retain each player's dealt-Joker count")

	var main_scene: Variant = load("res://Scenes/main.tscn").instantiate()
	root.add_child(main_scene)
	await process_frame
	main_scene.game = game
	main_scene.round_history = host.completed_round_history.duplicate(true)
	var standings: Array[Dictionary] = main_scene._get_final_standings()
	var standings_total := 0
	for standing in standings:
		standings_total += int(standing.get("jokers_dealt", 0))
	assert(standings_total == 1, "Final standings must sum dealt Jokers across completed rounds")

	var network_snapshot := host.create_host_snapshot()
	var network_standings: Array[Dictionary] = main_scene._get_network_final_standings(network_snapshot)
	var network_standings_total := 0
	for standing in network_standings:
		network_standings_total += int(standing.get("jokers_dealt", 0))
	assert(network_standings_total == 1, "Network final standings must expose the same cumulative Joker statistic")

	print("JOKER_STATISTICS_TEST_PASS")
	quit()
