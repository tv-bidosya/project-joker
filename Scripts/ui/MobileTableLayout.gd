extends RefCounted
## Phone-only table geometry. Desktop controls and gameplay stay untouched.
const HAND_CARD := Vector2(192, 282)
const TABLE_CARD := Vector2(142, 194)
const HAND_LEFT := 340.0
const HAND_RIGHT := 390.0
const SAFE_LEFT := 64.0
static var panel_cache: Dictionary = {}
static var portrait_material: ShaderMaterial

static func rect(control: Control, box: Rect2) -> void:
	var local := box.position
	if control.get_parent() is CanvasItem and control.is_inside_tree():
		local = control.get_parent().get_global_transform().affine_inverse() * local
	control.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	control.position = local
	control.size = box.size

static func action_style(button: Button, hero := false) -> void:
	if button.get_meta("phone_action_style", "") == ("gold" if hero else "green"):
		return
	button.set_meta("phone_action_style", "gold" if hero else "green")
	var texture: Texture2D = load("res://Assets/UI/mobile_action_gold.svg" if hero else "res://Assets/UI/mobile_action_green.svg")
	for state in ["normal", "hover", "pressed", "disabled"]:
		var style := StyleBoxTexture.new()
		style.texture = texture
		style.texture_margin_left = 24
		style.texture_margin_right = 24
		style.texture_margin_top = 24
		style.texture_margin_bottom = 24
		style.content_margin_left = 18
		style.content_margin_right = 18
		style.content_margin_top = 10
		style.content_margin_bottom = 10
		style.modulate_color = Color(1.16, 1.16, 1.08) if state == "hover" else (Color(0.8, 0.8, 0.8) if state == "pressed" else (Color(0.52, 0.56, 0.53, 0.9) if state == "disabled" else Color.WHITE))
		button.add_theme_stylebox_override(state, style)
	var focus := StyleBoxFlat.new()
	focus.bg_color = Color.TRANSPARENT
	focus.border_color = Color(1, 0.86, 0.43, 0.8)
	focus.set_border_width_all(2)
	focus.set_corner_radius_all(16)
	button.add_theme_stylebox_override("focus", focus)
	button.add_theme_color_override("font_color", Color(1, 0.91, 0.66))
	button.add_theme_color_override("font_hover_color", Color(1, 0.98, 0.84))
	button.add_theme_color_override("font_disabled_color", Color(0.65, 0.68, 0.6))
	button.add_theme_font_size_override("font_size", 28)

static func panel_style(slot: int, active: bool) -> StyleBoxFlat:
	var key := "%d:%s" % [slot, active]
	if panel_cache.has(key):
		return panel_cache[key]
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.025, 0.12, 0.077, 0.98) if active else Color(0.012, 0.065, 0.042, 0.98)
	style.border_color = Color(1, 0.77, 0.26) if active else Color(0.69, 0.49, 0.18)
	style.set_border_width_all(3 if active else 2)
	style.set_corner_radius_all(20)
	style.shadow_color = Color(0, 0, 0, 0.55)
	style.shadow_size = 5
	style.content_margin_top = 8 if slot == 1 or slot == 3 else 4
	style.content_margin_bottom = 8 if slot == 1 or slot == 3 else 4
	style.content_margin_left = 126 if slot == 1 else (12 if slot == 3 else 70)
	style.content_margin_right = 126 if slot == 3 else 12
	panel_cache[key] = style
	return style

static func avatar_style(active: bool) -> StyleBoxFlat:
	var key := "avatar:%s" % active
	if panel_cache.has(key):
		return panel_cache[key]
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.01, 0.08, 0.05)
	style.border_color = Color(1, 0.8, 0.25) if active else Color(0.7, 0.5, 0.2)
	style.set_border_width_all(4 if active else 2)
	style.set_corner_radius_all(100)
	style.set_content_margin_all(4)
	style.shadow_size = 8 if active else 4
	style.shadow_color = Color(0.9, 0.53, 0.04, 0.4) if active else Color(0, 0, 0, 0.6)
	panel_cache[key] = style
	return style

static func player(main: Control, panel: Control, slot: int) -> void:
	var size := main.get_viewport_rect().size
	var middle := size.x * 0.5
	var boxes := [Rect2(middle - 138, size.y - 402, 358, 94), Rect2(SAFE_LEFT + 16, 350, 440, 186), Rect2(middle - 138, 112, 342, 108), Rect2(size.x - 466, 350, 440, 186)]
	rect(panel, boxes[slot])

static func avatar(main: Control, badge: Control, slot: int) -> void:
	var size := main.get_viewport_rect().size
	var middle := size.x * 0.5
	var boxes := [Rect2(middle - 212, size.y - 410, 112, 112), Rect2(SAFE_LEFT + 16, 320, 126, 126), Rect2(middle - 212, 108, 112, 112), Rect2(size.x - 152, 320, 126, 126)]
	rect(badge, boxes[slot])

static func trick(main: Control, card: Control, slot: int) -> void:
	var middle := main.get_viewport_rect().size.x * 0.5
	var boxes := [Rect2(middle - 71, 428, 142, 194), Rect2(middle - 330, 306, 142, 194), Rect2(middle - 71, 228, 142, 194), Rect2(middle + 188, 306, 142, 194)]
	card.set_card_size(boxes[slot].size)
	rect(card, boxes[slot])

static func backs(main: Control, holder: Control, slot: int) -> void:
	var width := main.get_viewport_rect().size.x
	var boxes := [Rect2(), Rect2(SAFE_LEFT + 480, 370, 72, 124), Rect2(width * 0.5 + 212, 134, 152, 80), Rect2(width - 552, 370, 72, 124)]
	rect(holder, boxes[slot])
	for index in holder.get_child_count():
		var card: Control = holder.get_child(index)
		card.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
		card.position = Vector2(index * 38, 0) if slot == 2 else Vector2(0, index * 32)
		card.size = Vector2(64, 80) if slot == 2 else Vector2(72, 52)

static func hand(main: Variant) -> void:
	if not main.mobile_table_layout:
		return
	var size: Vector2 = main.get_viewport_rect().size
	var width := size.x - HAND_LEFT - HAND_RIGHT
	var count: int = main.hand_container.get_child_count()
	var gap := minf(6, floorf((width - HAND_CARD.x * count) / float(maxi(1, count - 1))))
	main.hand_container.custom_minimum_size = Vector2.ZERO
	main.hand_container.add_theme_constant_override("separation", int(gap))
	rect(main.hand_container, Rect2(HAND_LEFT, size.y - 294, width, 282))

static func dock(main: Variant) -> void:
	if not is_instance_valid(main.mobile_bid_menu_button):
		return
	var size: Vector2 = main.get_viewport_rect().size
	for button in [main.hand_sort_by_suit_button, main.hand_sort_trumps_left_button]:
		button.hide()
	if not is_instance_valid(main.mobile_sort_button):
		main.mobile_sort_button = Button.new()
		main.mobile_sort_button.name = "MobileSortToggle"
		main.mobile_sort_button.pressed.connect(main._on_mobile_sort_pressed)
		main.mobile_bottom_dock.get_node("MobileBottomRow").add_child(main.mobile_sort_button)
	for button in [main.undo_button, main.mobile_sort_button]:
		button.custom_minimum_size = Vector2.ZERO
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		action_style(button)
		button.add_theme_font_size_override("font_size", 28)
	main.mobile_sort_button.text = main.tr("SORT_BY_SUIT" if main.hand_sort_mode == main.HandSortMode.BY_SUIT else "SORT_TRUMPS_LEFT")
	main.mobile_sort_button.tooltip_text = main.tr("SORT_TRUMPS_LEFT" if main.hand_sort_mode == main.HandSortMode.BY_SUIT else "SORT_BY_SUIT")
	rect(main.undo_button, Rect2(SAFE_LEFT, size.y - 238, 264, 100))
	rect(main.mobile_sort_button, Rect2(SAFE_LEFT, size.y - 126, 264, 100))
	main.mobile_bid_menu_button.custom_minimum_size = Vector2.ZERO
	main.mobile_bid_menu_button.disabled = true
	main.mobile_bid_menu_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	main.mobile_bid_menu_button.hide()
	rect(main.mobile_bid_menu_button, Rect2(size.x - 24, size.y - 24, 0, 0))

static func social(main: Variant) -> void:
	if not main.mobile_table_layout or not is_instance_valid(main.social_controls_container):
		return
	var size: Vector2 = main.get_viewport_rect().size
	var buttons := [main.chat_toggle_button, main.reaction_toggle_button, main.sticker_toggle_button, main.soundpad_toggle_button]
	var icons := ["mobile_chat.svg", "mobile_smile.svg", "player_gift.svg", "soundbar_speaker.svg"]
	for index in buttons.size():
		var button: Button = buttons[index]
		if not is_instance_valid(button):
			continue
		button.text = ""
		button.icon = load("res://Assets/UI/" + icons[index])
		button.expand_icon = true
		button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
		button.alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.add_theme_constant_override("icon_max_width", 55)
		button.custom_minimum_size = Vector2(100, 94)
		action_style(button)
	main.social_controls_container.add_theme_constant_override("separation", 7)
	main.social_controls_container.alignment = BoxContainer.ALIGNMENT_END
	# Keep the social rail in the lower-right safe corner, below the side player.
	rect(main.social_controls_container, Rect2(size.x - 124, size.y - 446, 100, 420))
	rect(main.reaction_picker, Rect2(size.x - 734, size.y - 600, 596, 460))
	rect(main.soundpad_picker, Rect2(size.x - 718, size.y - 322, 580, 296))

static func apply(main: Variant) -> void:
	if not main.mobile_table_layout:
		return
	var size: Vector2 = main.get_viewport_rect().size
	main.mobile_top_bar.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	main.mobile_top_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	main.phase_label.add_theme_color_override("font_color", Color(1, 0.89, 0.58))
	main.phase_label.add_theme_font_size_override("font_size", 25)
	main.score_sheet_title.add_theme_font_size_override("font_size", 44)
	main.final_results_label.add_theme_font_size_override("font_size", 34)
	main.score_sheet_grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var score_sheet_content := main.score_sheet_grid.get_parent() as Control
	if is_instance_valid(score_sheet_content):
		score_sheet_content.custom_minimum_size.x = size.x - SAFE_LEFT - 130.0
	rect(main.score_sheet_panel, Rect2(SAFE_LEFT + 14, 70, size.x - SAFE_LEFT - 34, size.y - 116))
	main.score_sheet_close_button.custom_minimum_size = Vector2(88, 78)
	main.score_sheet_close_button.add_theme_font_size_override("font_size", 48)
	action_style(main.score_sheet_close_button)
	rect(main.score_sheet_close_button, Rect2(size.x - 128, 80, 92, 78))
	main.deck_visual.pivot_offset = Vector2.ZERO
	main.deck_visual.scale = Vector2(1.25, 1.25)
	rect(main.deck_visual, Rect2(size.x - 540, 96, 180, 200))
	main.trump_label.visible = false
	for button in [main.round_history_toggle_button, main.score_sheet_toggle_button, main.pause_menu_button]:
		button.custom_minimum_size = Vector2(210, 84)
		action_style(button)
		button.add_theme_font_size_override("font_size", 26)
	main._queue_mobile_top_bar_layout()
	rect(main.local_table_outer, Rect2(SAFE_LEFT + 10, 106, size.x - SAFE_LEFT - 36, size.y - 344))
	for slot in main.player_panels.size():
		player(main, main.player_panels[slot], slot)
		avatar(main, main.avatar_badges[slot], slot)
		trick(main, main.trick_card_views[slot], slot)
		main.player_labels[slot].clip_text = true
		main.player_labels[slot].text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		main.player_labels[slot].add_theme_font_size_override("font_size", 26 if slot == 1 or slot == 3 else 24)
		var content: VBoxContainer = main.player_panels[slot].get_child(0)
		content.alignment = BoxContainer.ALIGNMENT_CENTER
		content.add_theme_constant_override("separation", 2)
		main.player_stats_labels[slot].set_meta("phone_side_panel", slot == 1 or slot == 3)
		main.player_score_labels[slot].set_meta("phone_side_panel", slot == 1 or slot == 3)
		main.player_stats_labels[slot].custom_minimum_size.y = 58 if slot == 1 or slot == 3 else 30
		main.player_panels[slot].add_theme_stylebox_override("panel", panel_style(slot, false))
		if portrait_material == null:
			var shader := Shader.new()
			shader.code = "shader_type canvas_item; void fragment(){ vec4 c = texture(TEXTURE, UV) * COLOR; c.a *= 1.0-smoothstep(0.475,0.495,length(UV-vec2(0.5))); COLOR=c; }"
			portrait_material = ShaderMaterial.new()
			portrait_material.shader = shader
		main.avatar_images[slot].material = portrait_material
		main.avatar_badges[slot].add_theme_stylebox_override("panel", avatar_style(false))
	for index in main.bot_card_back_holders.size():
		backs(main, main.bot_card_back_holders[index], index + 1)
	hand(main)
	dock(main)
	action_style(main.next_round_button)
	social(main)
	rect(main.action_label, Rect2(size.x * 0.5 - 440, size.y - 444, 880, 34))
	main.action_label.add_theme_font_size_override("font_size", 24)
	rect(main.round_history_panel, Rect2(SAFE_LEFT + 238, 10, 400, 322))
	rect(main.mobile_premove_hint, Rect2(size.x * 0.5 - 400, size.y - 490, 800, 42))
	var tutorial_margins: MarginContainer = main.tutorial_panel.get_child(0)
	tutorial_margins.add_theme_constant_override("margin_top", 4)
	tutorial_margins.add_theme_constant_override("margin_bottom", 4)
	tutorial_margins.get_child(0).add_theme_constant_override("separation", 2)
	rect(main.tutorial_panel, Rect2(SAFE_LEFT, 536, minf(760, size.x * 0.5 - 300), 218))
	main.tutorial_text_label.custom_minimum_size.y = 100
	main.tutorial_text_label.add_theme_font_size_override("font_size", 23)
	main.tutorial_title_label.add_theme_font_size_override("font_size", 26)
	main.tutorial_disable_button.custom_minimum_size.y = 40
	main.tutorial_disable_button.add_theme_font_size_override("font_size", 22)
	if not main.tutorial_panel.minimum_size_changed.is_connected(main._queue_phone_tutorial_fit):
		main.tutorial_panel.minimum_size_changed.connect(main._queue_phone_tutorial_fit)
	main._queue_phone_tutorial_fit()
	if not main.sticker_picker.minimum_size_changed.is_connected(main._queue_phone_gift_fit):
		main.sticker_picker.minimum_size_changed.connect(main._queue_phone_gift_fit)
	main._queue_phone_gift_fit()
