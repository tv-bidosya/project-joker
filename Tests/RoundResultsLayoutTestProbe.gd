extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var main_scene: Variant = load("res://Scenes/main.tscn").instantiate()
	root.add_child(main_scene)
	await process_frame

	var title: Label = main_scene.get_node("%RoundResultsTitle")
	var title_panel: PanelContainer = main_scene.get_node("%RoundResultsTitlePanel")
	var results_label: Label = main_scene.get_node("%RoundResultsLabel")
	var results_panel: PanelContainer = main_scene.get_node("%RoundResultsPanel")
	assert(title.text == "ИТОГИ РАЗДАЧИ", "Round results must have a clear standalone heading")
	assert(title_panel != results_label.get_parent(), "Heading plaque and result rows must be separate")

	var results_style: StyleBoxFlat = results_panel.get_theme_stylebox("panel")
	assert(results_style.content_margin_top >= 12.0, "Round results content must not touch the top border")
	assert(results_style.content_margin_bottom >= 12.0, "Round results content must not touch the bottom border")
	assert(title_panel.get_theme_stylebox("panel") is StyleBoxFlat, "Round results heading must have a distinct plaque")

	var snapshot := {
		"players": [
			{"display_name": "Андрей", "bid": 2, "tricks_taken": 3, "total_score": 1},
		]
	}
	var panel_text: String = main_scene._get_network_table_result_text(snapshot)
	assert(not panel_text.contains("Раздача завершена"), "Standalone plaque must replace the inline network heading")
	assert(panel_text.begins_with("Андрей:"), "Network round result rows must remain intact")
	var legacy_table_text: String = main_scene._get_network_table_result_text(snapshot, true)
	assert(legacy_table_text.begins_with("Раздача завершена\n"), "Legacy network table must retain its completion heading")

	print("ROUND_RESULTS_LAYOUT_TEST_PASS")
	quit()
