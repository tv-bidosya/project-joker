extends SceneTree


const DESIGN_SIZE := Vector2(1920.0, 1080.0)
const TEST_RESOLUTIONS := [
	Vector2(1280.0, 720.0),
	Vector2(1366.0, 768.0),
	Vector2(1920.0, 1080.0),
	Vector2(2560.0, 1440.0),
	Vector2(3840.0, 2160.0)
]


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var main_scene: Variant = load("res://Scenes/main.tscn").instantiate()
	root.add_child(main_scene)
	await process_frame

	var panel_rect: Rect2 = main_scene.first_turn_roll_panel.get_global_rect()
	assert(panel_rect.size.x <= 720.0 and panel_rect.size.y <= 356.0, "The dice panel must retain its compact logical bounds")
	assert(main_scene.first_turn_roll_grid.columns == 4, "The opening roll grid must reserve one column for each player")

	for resolution in TEST_RESOLUTIONS:
		var scale := Vector2(resolution.x / DESIGN_SIZE.x, resolution.y / DESIGN_SIZE.y)
		var scaled_position := panel_rect.position * scale
		var scaled_size := panel_rect.size * scale
		assert(scaled_position.x >= 0.0 and scaled_position.y >= 0.0, "The dice panel must stay on-screen at %s" % resolution)
		assert(
			scaled_position.x + scaled_size.x <= resolution.x
			and scaled_position.y + scaled_size.y <= resolution.y,
			"The dice panel must fit resolution %s without clipping" % resolution
		)
		assert(82.0 * scale.y >= 54.0, "The 3D die must remain readable at %s" % resolution)

	print("DICE_RESPONSIVE_LAYOUT_TEST_PASS")
	quit()
