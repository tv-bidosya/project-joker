extends SceneTree


const LocalMatchHostResource := preload("res://Scripts/core/LocalMatchHost.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	assert("🖕" in LocalMatchHostResource.NETWORK_REACTIONS, "Network reactions must allow the middle-finger reaction")
	assert(LocalMatchHostResource.NETWORK_STICKERS.size() == 10, "Network gifts must contain exactly ten options")
	for expected_gift in ["🌹", "🍰", "🧸", "🏆", "💩"]:
		assert(expected_gift in LocalMatchHostResource.NETWORK_STICKERS, "Missing network gift: %s" % expected_gift)

	var main_scene: Variant = load("res://Scenes/main.tscn").instantiate()
	root.add_child(main_scene)
	await process_frame

	var gifts: Array[Dictionary] = main_scene._get_network_available_stickers()
	assert(gifts.size() == 10, "Gift picker must expose exactly ten built-in gifts")
	var gift_symbols: Array[String] = []
	for gift in gifts:
		gift_symbols.append(str(gift.get("symbol", "")))
	assert(gift_symbols == LocalMatchHostResource.NETWORK_STICKERS, "Client and host social option lists must match")

	var reaction_row := main_scene.reaction_picker.get_child(0) as HBoxContainer
	assert(reaction_row != null and reaction_row.get_child_count() == 5, "Reaction picker must show five reactions")

	main_scene.sticker_selected_target_index = 1
	main_scene._build_sticker_choice_picker()
	var sticker_scroll := main_scene.sticker_picker_content.get_child(0) as ScrollContainer
	var sticker_grid := sticker_scroll.get_child(0) as GridContainer
	assert(sticker_grid.columns == 5 and sticker_grid.get_child_count() == 10, "Gift picker must show a 5x2 grid")

	print("SOCIAL_OPTIONS_TEST_PASS")
	quit()
