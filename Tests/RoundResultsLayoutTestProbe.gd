extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var main_scene: Variant = load("res://Scenes/main.tscn").instantiate()
	root.add_child(main_scene)
	await process_frame

	var title: Label = main_scene.get_node("%RoundResultsTitle")
	var title_panel: PanelContainer = main_scene.get_node("%RoundResultsTitlePanel")
	var results_label: RichTextLabel = main_scene.get_node("%RoundResultsLabel")
	var results_panel: PanelContainer = main_scene.get_node("%RoundResultsPanel")
	assert(title.text == "ИТОГИ РАЗДАЧИ", "Round results must have a clear standalone heading")
	assert(title_panel != results_label.get_parent(), "Heading plaque and result rows must be separate")

	var results_style: StyleBoxFlat = results_panel.get_theme_stylebox("panel")
	assert(results_style.content_margin_top >= 12.0, "Round results content must not touch the top border")
	assert(results_style.content_margin_bottom >= 12.0, "Round results content must not touch the bottom border")
	assert(results_panel.size.x >= 420.0, "Detailed round result rows must have enough horizontal space")
	assert(results_panel.size.x < 620.0, "Round results must not keep the old oversized fixed width")
	assert(results_panel.size.y < 200.0, "Round results must not keep empty space below four result rows")
	assert(title_panel.get_theme_stylebox("panel") is StyleBoxFlat, "Round results heading must have a distinct plaque")

	var snapshot := {
		"round": {"number": 1},
		"players": [
			{"player_index": 0, "display_name": "Андрей", "bid": 2, "tricks_taken": 3, "total_score": 1},
		],
		"completed_rounds": [{
			"round_number": 1,
			"uses_bids": true,
			"players": [{"bid": 2, "tricks_taken": 3, "round_score": -10}]
		}]
	}
	var panel_text: String = main_scene._get_network_table_result_text(snapshot)
	assert(not panel_text.contains("Раздача завершена"), "Standalone plaque must replace the inline network heading")
	assert(panel_text.begins_with("Андрей:"), "Network round result rows must remain intact")
	assert(panel_text.contains("взято 3 · перебор 1"), "Round result must explain overtricks")
	assert(panel_text.contains("-10 · счёт 11 → 1"), "Round result must show score delta and total")
	var panel_bbcode: String = main_scene._get_network_table_result_bbcode(snapshot)
	assert(panel_bbcode.contains("[color=#ff6b61]перебор 1"), "Overtricks must be highlighted in red")
	results_label.text = panel_bbcode
	main_scene._fit_round_results_panel(panel_text)
	var short_result_width := results_panel.size.x
	main_scene._fit_round_results_panel(panel_text.replace("Андрей", "ОченьДлинныйНикИгрока"))
	assert(results_panel.size.x > short_result_width, "Round results width must follow the longest displayed row")
	var legacy_table_text: String = main_scene._get_network_table_result_text(snapshot, true)
	assert(legacy_table_text.begins_with("Раздача завершена\n"), "Legacy network table must retain its completion heading")
	assert(main_scene.player_stats_labels[0] is RichTextLabel, "Player order and tricks must support bold rich text")
	assert(main_scene._get_player_stats_bbcode("2", 3, true).contains("[font_size=23][b]"), "Order and trick values must be larger and bold")

	for player_index in [1, 2, 3]:
		main_scene._place_table_marker(main_scene.dealer_marker, player_index, true)
		main_scene._place_table_marker(main_scene.lead_marker, player_index, false)
		assert(
			main_scene.dealer_marker.offset_top >= main_scene.lead_marker.offset_bottom + 8.0,
			"Dealer marker must sit below the lead marker without overlap"
		)

	print("ROUND_RESULTS_LAYOUT_TEST_PASS")
	quit()
