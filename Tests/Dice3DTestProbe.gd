extends SceneTree


const Dice3DViewResource := preload("res://Scripts/ui/Dice3DView.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var face_normals := {1: Vector3.UP, 2: Vector3.FORWARD, 3: Vector3.RIGHT, 4: Vector3.LEFT, 5: Vector3.BACK, 6: Vector3.DOWN}
	var to_camera := Vector3(0, 1.45, 3.25).normalized()
	for value in range(1, 7):
		var dice_view = Dice3DViewResource.new()
		root.add_child(dice_view)
		dice_view.configure(value, true, true, value == 6)
		var pose := Basis.from_euler(dice_view._get_result_rotation(value))
		var visible_face := 0
		var best_facing := -1.0
		for face in face_normals:
			var facing: float = (pose * face_normals[face]).dot(to_camera)
			if facing > best_facing:
				best_facing = facing
				visible_face = face
		assert(visible_face == value, "The dominant pip face must match the announced result %d, got %d" % [value, visible_face])
		await process_frame
		assert(dice_view.viewport != null and dice_view.viewport.own_world_3d, "Each roll slot must render its own 3D scene")
		assert(dice_view.die_body.get_child_count() == 22, "A 3D die must contain the body and all 21 physical pips")
		assert(dice_view.result_badge.visible and dice_view.result_badge.text == str(value), "The accessible result badge must match the 3D face")
		assert(dice_view.roll_tween != null, "A revealed result must animate toward the host-authoritative value")
		if value == 6:
			assert(dice_view.winner_light.light_energy > 0.0, "The winning die must receive a golden 3D light")
		dice_view.queue_free()
		await process_frame

	var waiting_dice = Dice3DViewResource.new()
	root.add_child(waiting_dice)
	waiting_dice.configure(-1, true, true, false)
	await process_frame
	assert(waiting_dice.roll_tween != null, "A submitted hidden roll must keep tumbling while waiting for the reveal")
	assert(not waiting_dice.result_badge.visible, "A hidden network roll must not leak its value")
	waiting_dice.queue_free()

	print("DICE_3D_TEST_PASS")
	quit()
