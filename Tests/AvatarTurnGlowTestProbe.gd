extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var main_scene: Variant = load("res://Scenes/main.tscn").instantiate()
	root.add_child(main_scene)
	await process_frame

	assert(main_scene.avatar_turn_glows.size() == 4, "Every player seat must have an animated turn glow")
	for player_index in main_scene.avatar_turn_glows.size():
		main_scene._set_avatar_turn_active(player_index, player_index == 2)

	var visible_glow_count := 0
	for player_index in main_scene.avatar_turn_glows.size():
		var glow: ColorRect = main_scene.avatar_turn_glows[player_index]
		if glow.visible:
			visible_glow_count += 1
		assert(
			glow.visible == (player_index == 2),
			"Only the active player's avatar may shimmer"
		)
		assert(glow.material is ShaderMaterial, "Turn glow must use an animated shader")
		var glow_material := glow.material as ShaderMaterial
		assert(
			glow_material.shader != null and glow_material.shader.code.contains("TIME"),
			"Turn glow shader must animate over time"
		)

	assert(visible_glow_count == 1, "Exactly one avatar must shimmer for the active turn")
	assert(main_scene.avatar_turn_labels[2].visible, "Animated glow must retain the explicit turn label")

	print("AVATAR_TURN_GLOW_TEST_PASS")
	quit()
