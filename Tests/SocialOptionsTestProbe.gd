extends SceneTree


const LocalMatchHostResource := preload("res://Scripts/core/LocalMatchHost.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	assert("🖕" in LocalMatchHostResource.NETWORK_REACTIONS, "Network reactions must allow the middle-finger reaction")
	assert(LocalMatchHostResource.NETWORK_REACTIONS.size() == 20, "Network reactions must expose twenty curated options")
	for expected_reaction in ["😂", "😍", "🤔", "🤦", "👍", "🔥"]:
		assert(expected_reaction in LocalMatchHostResource.NETWORK_REACTIONS, "Missing popular network reaction: %s" % expected_reaction)
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
		var gift_texture := gift.get("texture", null) as Texture2D
		assert(gift_texture != null, "Every built-in gift must use its bundled Fluent Emoji texture")
	assert(gift_symbols == LocalMatchHostResource.NETWORK_STICKERS, "Client and host social option lists must match")
	assert(main_scene.FLUENT_EMOJI_TEXTURE_PATHS.size() == 30, "The bundled Fluent Emoji subset must contain ten gifts and twenty reactions")
	assert(main_scene.reaction_toggle_button.text == "☺", "The table reaction toggle must stay icon-only without a usage counter")
	assert(main_scene.soundpad_toggle_button.text == "🔊", "The table soundpad toggle must stay icon-only without a usage counter")
	assert(
		main_scene.FLUENT_EMOJI_LICENSE.LICENSE_TEXT.contains("Copyright (c) Microsoft Corporation."),
		"The exported project must retain the Fluent Emoji MIT notice"
	)

	var reaction_grid := main_scene.reaction_picker.get_child(0) as GridContainer
	assert(reaction_grid != null and reaction_grid.columns == 5, "Reaction picker must use a five-column grid")
	assert(reaction_grid.get_child_count() == 20, "Reaction picker must show twenty reactions")
	for reaction_button_variant in reaction_grid.get_children():
		var reaction_button := reaction_button_variant as Button
		assert(reaction_button != null and reaction_button.icon != null, "Every reaction button must use a Fluent Emoji texture")
		assert(reaction_button.text.is_empty(), "The system-font emoji must stay hidden when its texture is available")
		assert(reaction_button.get_theme_stylebox("normal") is StyleBoxEmpty, "Reaction icons must not have a tile background or border")
		assert(reaction_button.icon_alignment == HORIZONTAL_ALIGNMENT_CENTER, "Every reaction icon must stay centered in its cell")
	var reaction_picker_padding: float = main_scene.reaction_picker.size.x - reaction_grid.get_combined_minimum_size().x
	assert(
		reaction_picker_padding >= 12.0 and reaction_picker_padding <= 36.0,
		"Reaction picker must keep balanced breathing room around the grid"
	)
	main_scene.reaction_picker.visible = true
	await process_frame
	var reaction_picker_rect: Rect2 = main_scene.reaction_picker.get_global_rect()
	var reaction_grid_rect: Rect2 = reaction_grid.get_global_rect()
	var reaction_top_space := reaction_grid_rect.position.y - reaction_picker_rect.position.y
	var reaction_bottom_space := reaction_picker_rect.end.y - reaction_grid_rect.end.y
	assert(is_equal_approx(reaction_picker_rect.size.y, 198.0), "Reaction picker must fit four rows without a black footer")
	assert(absf(reaction_top_space - reaction_bottom_space) <= 3.0, "Reaction grid must have balanced top and bottom spacing")
	main_scene.reaction_picker.visible = false

	main_scene.sticker_selected_target_index = 1
	main_scene._build_sticker_choice_picker()
	main_scene.sticker_picker.visible = true
	assert(
		is_equal_approx(main_scene.sticker_picker.offset_right - main_scene.sticker_picker.offset_left, 326.0),
		"Gift picker must fit the five buttons without an empty right gutter"
	)
	var sticker_scroll := main_scene.sticker_picker_content.get_child(0) as ScrollContainer
	var sticker_grid_center := sticker_scroll.get_child(0) as CenterContainer
	var sticker_grid := sticker_grid_center.get_child(0) as GridContainer
	assert(sticker_grid.columns == 5 and sticker_grid.get_child_count() == 10, "Gift picker must show a 5x2 grid")
	for sticker_button_variant in sticker_grid.get_children():
		var sticker_button := sticker_button_variant as Button
		assert(sticker_button != null and sticker_button.get_theme_stylebox("normal") is StyleBoxEmpty, "Gift icons must not have a tile background or border")
		assert(sticker_button.icon_alignment == HORIZONTAL_ALIGNMENT_CENTER, "Every gift must stay centered in its grid cell")
	await process_frame
	var picker_rect: Rect2 = main_scene.sticker_picker.get_global_rect()
	var grid_rect: Rect2 = sticker_grid.get_global_rect()
	var gift_left_space := grid_rect.position.x - picker_rect.position.x
	var gift_right_space := picker_rect.end.x - grid_rect.end.x
	if absf(gift_left_space - gift_right_space) > 3.0:
		push_error(
			"The complete gift grid must be horizontally centered in its panel (left=%.1f, right=%.1f)"
			% [gift_left_space, gift_right_space]
		)
		quit(1)
		return

	assert(main_scene.sticker_flyers.size() == 4, "Each player seat must have an independent gift flyer")
	assert(main_scene.sticker_flyers[0].get_theme_stylebox("panel") is StyleBoxEmpty, "Flying gifts must contain only the gift artwork")
	main_scene._show_sticker_flyer({"symbol": "🌹"}, 0, 1)
	var first_target_tween: Tween = main_scene.sticker_flyer_tweens.get(1) as Tween
	main_scene._show_sticker_flyer({"symbol": "🍰"}, 0, 2)
	assert(
		main_scene.sticker_flyers[1].visible and main_scene.sticker_flyers[2].visible,
		"Gifts to different players must remain visible together"
	)
	assert(
		main_scene.sticker_flyer_tweens.get(1) == first_target_tween,
		"A gift to another player must not restart the first player's timer"
	)
	main_scene._show_sticker_flyer({"symbol": "🏆"}, 0, 1)
	assert(main_scene.sticker_flyer_images[1].visible and not main_scene.sticker_flyer_labels[1].visible)
	assert(
		main_scene.sticker_flyer_images[1].texture.resource_path.ends_with("trophy_3d.png"),
		"A new 3D gift must replace the previous gift for the same player"
	)
	assert(
		main_scene.sticker_flyers[2].visible
		and main_scene.sticker_flyer_images[2].texture.resource_path.ends_with("shortcake_3d.png"),
		"Replacing one player's gift must not hide another player's gift"
	)
	assert(main_scene.sticker_flyer_shadows[1].visible, "A 3D gift must keep its depth shadow")
	var gift_material := main_scene.sticker_flyer_images[1].material as ShaderMaterial
	assert(gift_material != null, "A 3D gift must use the animated highlight shader")

	main_scene._show_reaction_bubble("😄", 0)
	assert(main_scene.reaction_bubble_image.visible and main_scene.reaction_bubble_image.texture != null)
	assert(main_scene.reaction_bubble.get_theme_stylebox("panel") is StyleBoxEmpty, "Displayed reactions must contain only the emoji artwork")
	assert(main_scene.reaction_bubble_shadow.visible, "A 3D reaction must keep its depth shadow")
	assert(not main_scene.reaction_bubble_label.visible, "The text fallback must stay hidden for bundled reactions")
	main_scene._present_network_sticker_event({
		"actor_player_index": 0,
		"target_player_index": 3,
		"sticker": "🍺"
	}, 0)
	assert(
		main_scene.sticker_flyer_images[3].texture.resource_path.ends_with("beer_mug_3d.png"),
		"A network gift symbol must resolve to the same local 3D texture"
	)
	main_scene._present_network_reaction_event({"actor_player_index": 2, "reaction": "👏"}, 0)
	assert(
		main_scene.reaction_bubble_image.texture.resource_path.ends_with("clapping_hands_3d_default.png"),
		"A network reaction symbol must resolve to the same local 3D texture"
	)

	print("SOCIAL_OPTIONS_TEST_PASS")
	quit()
