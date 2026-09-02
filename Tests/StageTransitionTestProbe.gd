extends SceneTree

class Announcements extends "res://Scripts/core/GameManager.gd":
	var calls: Array[int] = []
	func _show_stage_announcement(round_type: int) -> void:
		calls.append(round_type)

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene: Variant = load("res://Scenes/main.tscn").instantiate()
	scene.set_script(Announcements)
	scene.persistent_settings_writes_enabled = false
	scene.session_save_path = "user://stage_transition_probe.save"
	root.add_child(scene)
	await process_frame
	scene.set_process(false)
	scene._reset_game_session()
	var stages := [Round.RoundType.NORMAL, Round.RoundType.DARK, Round.RoundType.NO_TRUMP, Round.RoundType.GOLDEN, Round.RoundType.MISERE]
	var counts: Array[int] = [scene.NORMAL_ROUND_COUNT, scene.DARK_ROUND_COUNT, scene.NO_TRUMP_ROUND_COUNT, scene.GOLDEN_ROUND_COUNT, scene.MISERE_ROUND_COUNT]
	var number := 0
	for index in stages.size():
		for deal in counts[index]:
			number += 1
			var previous: int = scene.calls.size()
			scene._show_stage_announcement_if_needed(stages[index], number)
			assert(scene.calls.size() - previous == (1 if index > 0 and deal == 0 else 0), "Announce only the first deal of a special stage")
			scene._show_stage_announcement_if_needed(stages[index], number)
			assert(scene.calls.size() - previous == (1 if index > 0 and deal == 0 else 0), "Repeated snapshots must not replay announcements")
	assert(number == 32 and scene.calls.size() == 4)
	for index in range(1, stages.size()):
		scene._reset_game_session()
		scene.calls.clear()
		scene._show_stage_announcement_if_needed(stages[index], scene._get_stage_first_round_number(stages[index]) + 1)
		assert(scene.calls.is_empty(), "Mid-stage reconnect must not announce a stage")
	scene._reset_game_session()
	scene.calls.clear()
	assert(scene.game.start_round(3, Round.RoundType.DARK, Round.TrumpSuit.CLUBS))
	scene.game.current_round.number = scene.NORMAL_ROUND_COUNT + 1
	var saved: Dictionary = scene._create_session_save_data()
	scene._reset_game_session()
	assert(scene._restore_session_from_data(saved, false))
	scene._show_stage_announcement_if_needed(Round.RoundType.DARK, scene.game.current_round.number)
	assert(scene.calls.is_empty(), "Restoring a saved deal must not replay its announcement")
	print("STAGE_TRANSITIONS_32_DEALS_FOUR_ANNOUNCEMENTS_PASS")
	scene.queue_free()
	await process_frame
	quit()
