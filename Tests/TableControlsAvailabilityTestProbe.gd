extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var main_scene: Variant = load("res://Scenes/main.tscn").instantiate()
	root.add_child(main_scene)
	await process_frame

	main_scene.is_processing_automatic_actions = true
	main_scene._refresh_ui()
	assert(not main_scene.pause_menu_button.disabled, "Menu must remain available while waiting for automatic actions")
	assert(not main_scene.score_sheet_toggle_button.disabled, "Score sheet must remain available while waiting for automatic actions")
	assert(not main_scene.round_history_toggle_button.disabled, "Round history must remain available while waiting for automatic actions")

	main_scene._on_pause_menu_pressed()
	assert(main_scene.is_pause_menu_open and main_scene.menu_overlay.visible, "Menu button must open the menu while waiting")
	var score_sheet_was_visible: bool = main_scene.is_score_sheet_visible
	main_scene._on_score_sheet_toggle_pressed()
	assert(main_scene.is_score_sheet_visible != score_sheet_was_visible, "Score sheet button must work while waiting")
	var round_history_was_visible: bool = main_scene.is_round_history_visible
	main_scene._on_round_history_toggle_pressed()
	assert(main_scene.is_round_history_visible != round_history_was_visible, "Round history button must work while waiting")

	print("TABLE_CONTROLS_AVAILABILITY_TEST_PASS")
	quit()
