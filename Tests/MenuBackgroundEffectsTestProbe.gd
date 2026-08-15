extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var main_scene: Variant = load("res://Scenes/main.tscn").instantiate()
	root.add_child(main_scene)
	await process_frame

	var effects: Variant = main_scene.menu_background_effects
	assert(effects != null and effects.mouse_filter == Control.MOUSE_FILTER_IGNORE)
	assert(effects.size.x >= 1900.0 and effects.size.y >= 1000.0, "The animated layer must cover the full 1920×1080 menu viewport.")
	assert(effects.smoke_emitters.size() == 3, "Each extinguished candle must have its own smoke emitter.")
	for effect_kind in [0, 1, 2]:
		effects.set_background_kind(effect_kind)
		effects.elapsed_seconds = 12.5
		effects.queue_redraw()
		await process_frame
		assert(effects.background_kind == effect_kind)
		for emitter in effects.smoke_emitters:
			assert(emitter.emitting == (effect_kind == 0), "Smoke must only run on the daytime background.")
	assert(effects.soft_glow_texture != null, "Candle, lantern and moonlight must use a smooth radial texture.")

	main_scene.menu_background_theme = 0
	var automatic_theme: int = main_scene._get_effective_menu_background_theme()
	assert(automatic_theme == 1 or automatic_theme == 2)
	main_scene.menu_background_theme = 1
	assert(main_scene._get_effective_menu_background_theme() == 1)
	main_scene.menu_background_theme = 2
	assert(main_scene._get_effective_menu_background_theme() == 2)
	main_scene.menu_background_theme = 3
	assert(main_scene._get_effective_menu_background_theme() == 3)

	print("MENU_BACKGROUND_EFFECTS_TEST_PASS")
	quit()
