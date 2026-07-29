class_name CardView

extends Control


const CardArtworkResource = preload("res://Scripts/ui/CardArtwork.gd")
const ARTWORK_EDGE_SHADER_CODE := """
shader_type canvas_item;

void fragment() {
	vec4 artwork = texture(TEXTURE, UV);
	const float edge_inset = 0.003;
	const float corner_radius = 0.026;
	vec2 rounded_box = abs(UV - vec2(0.5)) - vec2(0.5 - edge_inset - corner_radius);
	float edge_distance = length(max(rounded_box, vec2(0.0)))
		+ min(max(rounded_box.x, rounded_box.y), 0.0)
		- corner_radius;
	float antialias_width = max(fwidth(edge_distance) * 0.85, 0.001);
	float clean_edge = 1.0 - smoothstep(-antialias_width, antialias_width, edge_distance);
	COLOR = vec4(artwork.rgb, artwork.a * clean_edge);
}
"""


signal card_pressed(card: Card)


var displayed_card: Card
var is_interactive := false
var is_disabled := false
var is_visually_unavailable := false
var is_visually_available := false
var is_hovered := false
var is_winner_highlighted := false
var requested_presentation_rotation := 0.0
var presentation_rotation := 0.0
var presentation_offset := Vector2.ZERO
var visual_tween: Tween

var depth_shadow: Panel
var winner_glow: Panel
var winner_glow_tween: Tween
var face_panel: Panel
var artwork_texture: TextureRect
var top_corner_label: Label
var center_label: Label
var bottom_corner_label: Label
var status_badge: PanelContainer
var status_label: Label
var availability_overlay: Panel


func _init() -> void:
	custom_minimum_size = Vector2(88.0, 128.0)
	size = custom_minimum_size
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_create_visuals()


func set_card(card: Card) -> void:
	displayed_card = card
	tooltip_text = card.get_card_name()
	set_status("")
	set_winner_highlight(false)
	var face_texture: Texture2D = CardArtworkResource.get_face_texture(card)
	var uses_artwork := face_texture != null
	artwork_texture.texture = face_texture
	artwork_texture.visible = uses_artwork

	var card_color := _get_card_color(card)
	if card.is_joker:
		top_corner_label.text = "J"
		center_label.text = "JOKER\n✦"
		bottom_corner_label.text = "J"
		center_label.add_theme_font_size_override("font_size", 19)
	else:
		var rank_text := _get_rank_text(card.rank)
		var suit_symbol := _get_suit_symbol(card.suit)
		top_corner_label.text = "%s\n%s" % [rank_text, suit_symbol]
		center_label.text = suit_symbol
		bottom_corner_label.text = "%s\n%s" % [rank_text, suit_symbol]
		center_label.add_theme_font_size_override("font_size", 48)

	for label in [top_corner_label, center_label, bottom_corner_label]:
		label.visible = not uses_artwork
		label.add_theme_color_override("font_color", card_color)

	_sync_card_specific_presentation()
	_refresh_face_style()


func set_card_size(card_size: Vector2) -> void:
	custom_minimum_size = card_size
	size = card_size
	_update_visual_pivots()


func set_hand_presentation(card_index: int, card_count: int) -> void:
	var normalized_position := 0.0
	if card_count > 1:
		normalized_position = remap(float(card_index), 0.0, float(card_count - 1), -1.0, 1.0)
	requested_presentation_rotation = deg_to_rad(normalized_position * 2.4)
	presentation_offset = Vector2(0.0, absf(normalized_position) * 4.0)
	_sync_card_specific_presentation()


func set_table_presentation(relative_slot: int) -> void:
	var table_angles := [-1.4, 2.2, -1.8, 1.6]
	requested_presentation_rotation = deg_to_rad(float(table_angles[clampi(relative_slot, 0, table_angles.size() - 1)]))
	presentation_offset = Vector2.ZERO
	_sync_card_specific_presentation()


func reset_presentation() -> void:
	requested_presentation_rotation = 0.0
	presentation_offset = Vector2.ZERO
	_sync_card_specific_presentation()


func set_status(status_text: String) -> void:
	status_label.text = status_text
	status_label.add_theme_font_size_override("font_size", 10 if status_text.length() > 10 else 12)
	status_badge.visible = not status_text.is_empty()
	if status_text.is_empty():
		return

	var is_discard := status_text.contains("НЕ БЕРЁТ") or status_text.contains("НЕ ЗАБИРАЕТ")
	var is_declared_rule := status_text.contains("СТАРШАЯ") or status_text.contains("МЛАДШАЯ")
	var badge_style := StyleBoxFlat.new()
	badge_style.bg_color = (
		Color(0.48, 0.08, 0.08, 0.96)
		if is_discard
		else Color(0.12, 0.25, 0.46, 0.96)
		if is_declared_rule
		else Color(0.04, 0.34, 0.18, 0.96)
	)
	badge_style.border_color = Color(1.0, 0.84, 0.38, 1.0)
	badge_style.set_border_width_all(2)
	badge_style.set_corner_radius_all(7)
	badge_style.shadow_color = Color(0.0, 0.0, 0.0, 0.58)
	badge_style.shadow_size = 4
	badge_style.shadow_offset = Vector2(0.0, 2.0)
	status_badge.add_theme_stylebox_override("panel", badge_style)


func set_interactive(interactive: bool, disabled: bool) -> void:
	is_interactive = interactive
	is_disabled = disabled
	is_visually_unavailable = disabled
	is_visually_available = false
	mouse_filter = Control.MOUSE_FILTER_STOP if is_interactive and not is_disabled else Control.MOUSE_FILTER_IGNORE
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if is_interactive and not is_disabled else Control.CURSOR_ARROW
	_refresh_availability_visual()
	if not is_interactive or is_disabled:
		is_hovered = false
		_apply_visual_pose(false)
	_refresh_face_style()


func set_visually_unavailable(unavailable: bool) -> void:
	is_visually_unavailable = unavailable
	if unavailable:
		is_visually_available = false
	_refresh_availability_visual()


func set_availability_hint(available: bool, unavailable: bool) -> void:
	is_visually_unavailable = unavailable
	is_visually_available = available and not unavailable
	_refresh_availability_visual()


func _refresh_availability_visual() -> void:
	modulate = Color.WHITE
	if not is_instance_valid(availability_overlay):
		return
	availability_overlay.visible = is_visually_unavailable
	if not availability_overlay.visible:
		return
	var style := StyleBoxFlat.new()
	style.set_corner_radius_all(2)
	style.bg_color = Color(0.015, 0.022, 0.018, 0.58)
	style.border_color = Color(0.1, 0.13, 0.11, 0.88)
	style.set_border_width_all(1)
	style.shadow_color = Color.TRANSPARENT
	style.shadow_size = 0
	availability_overlay.add_theme_stylebox_override("panel", style)


func set_winner_highlight(enabled: bool) -> void:
	is_winner_highlighted = enabled
	_refresh_winner_glow()
	_refresh_face_style()


func _gui_input(event: InputEvent) -> void:
	if not is_interactive or is_disabled or displayed_card == null:
		return

	if event is InputEventMouseMotion and is_hovered:
		var horizontal_ratio := clampf(event.position.x / maxf(size.x, 1.0), 0.0, 1.0)
		var hover_rotation := presentation_rotation + deg_to_rad(lerpf(-2.4, 2.4, horizontal_ratio))
		_animate_visual_pose(
			presentation_offset + Vector2(0.0, -11.0),
			hover_rotation,
			Vector2(1.045, 1.045),
			0.08
		)

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_animate_visual_pose(
			presentation_offset + Vector2(0.0, -6.0),
			face_panel.rotation,
			Vector2(0.985, 0.985),
			0.06
		)
		card_pressed.emit(displayed_card)
		accept_event()


func _create_visuals() -> void:
	depth_shadow = Panel.new()
	depth_shadow.set_anchors_preset(Control.PRESET_FULL_RECT)
	depth_shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shadow_style := StyleBoxFlat.new()
	shadow_style.bg_color = Color.TRANSPARENT
	shadow_style.set_corner_radius_all(10)
	shadow_style.shadow_color = Color(0.0, 0.0, 0.0, 0.3)
	shadow_style.shadow_size = 7
	shadow_style.shadow_offset = Vector2(0.0, 4.0)
	depth_shadow.add_theme_stylebox_override("panel", shadow_style)
	add_child(depth_shadow)

	winner_glow = Panel.new()
	winner_glow.name = "WinnerGlow"
	winner_glow.set_anchors_preset(Control.PRESET_FULL_RECT)
	winner_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	winner_glow.visible = false
	var winner_glow_style := StyleBoxFlat.new()
	winner_glow_style.bg_color = Color(1.0, 0.72, 0.12, 0.12)
	winner_glow_style.border_color = Color(1.0, 0.78, 0.2, 0.96)
	winner_glow_style.set_border_width_all(3)
	winner_glow_style.set_corner_radius_all(9)
	winner_glow_style.shadow_color = Color(1.0, 0.62, 0.08, 0.88)
	winner_glow_style.shadow_size = 14
	winner_glow_style.shadow_offset = Vector2.ZERO
	winner_glow.add_theme_stylebox_override("panel", winner_glow_style)
	add_child(winner_glow)

	face_panel = Panel.new()
	face_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	face_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(face_panel)

	artwork_texture = TextureRect.new()
	artwork_texture.set_anchors_preset(Control.PRESET_FULL_RECT)
	artwork_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	artwork_texture.stretch_mode = TextureRect.STRETCH_SCALE
	artwork_texture.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	artwork_texture.texture_repeat = CanvasItem.TEXTURE_REPEAT_DISABLED
	artwork_texture.material = _create_artwork_edge_material()
	artwork_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	artwork_texture.visible = false
	face_panel.add_child(artwork_texture)

	top_corner_label = Label.new()
	top_corner_label.position = Vector2(8.0, 6.0)
	top_corner_label.size = Vector2(34.0, 46.0)
	top_corner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top_corner_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	top_corner_label.add_theme_font_size_override("font_size", 18)
	face_panel.add_child(top_corner_label)

	center_label = Label.new()
	center_label.set_anchors_preset(Control.PRESET_CENTER)
	center_label.offset_left = -40.0
	center_label.offset_top = -28.0
	center_label.offset_right = 40.0
	center_label.offset_bottom = 32.0
	center_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	center_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	face_panel.add_child(center_label)

	status_badge = PanelContainer.new()
	status_badge.anchor_left = 0.0
	status_badge.anchor_top = 1.0
	status_badge.anchor_right = 1.0
	status_badge.anchor_bottom = 1.0
	status_badge.offset_left = 4.0
	status_badge.offset_top = -38.0
	status_badge.offset_right = -4.0
	status_badge.offset_bottom = -4.0
	status_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	status_badge.visible = false
	status_badge.z_index = 3
	face_panel.add_child(status_badge)

	status_label = Label.new()
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	status_label.add_theme_color_override("font_color", Color.WHITE)
	status_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.8))
	status_label.add_theme_constant_override("shadow_offset_x", 1)
	status_label.add_theme_constant_override("shadow_offset_y", 1)
	status_label.add_theme_font_size_override("font_size", 12)
	status_badge.add_child(status_label)

	bottom_corner_label = Label.new()
	bottom_corner_label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	bottom_corner_label.offset_left = -42.0
	bottom_corner_label.offset_top = -52.0
	bottom_corner_label.offset_right = -8.0
	bottom_corner_label.offset_bottom = -6.0
	bottom_corner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bottom_corner_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	bottom_corner_label.add_theme_font_size_override("font_size", 18)
	face_panel.add_child(bottom_corner_label)

	availability_overlay = Panel.new()
	availability_overlay.name = "AvailabilityOverlay"
	availability_overlay.visible = false
	availability_overlay.z_index = 2
	availability_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	availability_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	face_panel.add_child(availability_overlay)

	resized.connect(_update_visual_pivots)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	call_deferred("_update_visual_pivots")


func _create_artwork_edge_material() -> ShaderMaterial:
	var edge_shader := Shader.new()
	edge_shader.code = ARTWORK_EDGE_SHADER_CODE
	var edge_material := ShaderMaterial.new()
	edge_material.shader = edge_shader
	return edge_material


func _refresh_winner_glow() -> void:
	if not is_instance_valid(winner_glow):
		return
	if is_instance_valid(winner_glow_tween):
		winner_glow_tween.kill()
	winner_glow_tween = null
	winner_glow.visible = is_winner_highlighted
	if not is_winner_highlighted:
		return
	winner_glow.modulate = Color(1.0, 1.0, 1.0, 0.98)
	winner_glow_tween = create_tween().set_loops()
	winner_glow_tween.tween_property(winner_glow, "modulate:a", 0.58, 0.32).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	winner_glow_tween.tween_property(winner_glow, "modulate:a", 0.98, 0.32).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _refresh_face_style() -> void:
	if displayed_card == null:
		return

	var background_color := Color(0.96, 0.95, 0.87, 1.0) if displayed_card.is_joker else Color(0.98, 0.98, 0.94, 1.0)
	var is_hover_highlighted := is_interactive and not is_disabled and is_hovered
	var border_color := Color(0.98, 0.78, 0.25, 1.0) if is_winner_highlighted else (Color(0.88, 0.67, 0.22, 1.0) if is_hover_highlighted else Color(0.16, 0.2, 0.17, 1.0))
	var border_width := 4 if is_winner_highlighted else (3 if is_hover_highlighted else 2)
	var uses_finished_artwork := artwork_texture.visible
	depth_shadow.visible = not uses_finished_artwork
	var style := StyleBoxFlat.new()
	style.bg_color = Color.TRANSPARENT if uses_finished_artwork else background_color
	style.border_color = border_color
	style.set_border_width_all(0 if uses_finished_artwork else border_width)
	style.set_corner_radius_all(0 if uses_finished_artwork else 8)
	style.shadow_color = (
		Color(0.98, 0.72, 0.16, 0.72)
		if is_winner_highlighted
		else Color(0.88, 0.67, 0.22, 0.32)
		if uses_finished_artwork and is_hover_highlighted
		else Color(0.0, 0.0, 0.0, 0.42)
	)
	style.shadow_size = 0 if uses_finished_artwork else (12 if is_winner_highlighted else 4)
	style.shadow_offset = Vector2(0.0, 2.0)
	face_panel.add_theme_stylebox_override("panel", style)


func _on_mouse_entered() -> void:
	if is_interactive and not is_disabled:
		is_hovered = true
		_animate_visual_pose(
			presentation_offset + Vector2(0.0, -11.0),
			presentation_rotation,
			Vector2(1.045, 1.045),
			0.13
		)
		_refresh_face_style()


func _on_mouse_exited() -> void:
	if is_hovered:
		is_hovered = false
		_apply_visual_pose(true)
		_refresh_face_style()


func _update_visual_pivots() -> void:
	if is_instance_valid(face_panel):
		face_panel.pivot_offset = size * 0.5
	if is_instance_valid(depth_shadow):
		depth_shadow.pivot_offset = size * 0.5
	if is_instance_valid(winner_glow):
		winner_glow.pivot_offset = size * 0.5


func _sync_card_specific_presentation() -> void:
	presentation_rotation = requested_presentation_rotation
	_apply_visual_pose(false)


func _apply_visual_pose(animated: bool) -> void:
	if animated:
		_animate_visual_pose(presentation_offset, presentation_rotation, Vector2.ONE, 0.16)
		return
	if is_instance_valid(visual_tween):
		visual_tween.kill()
	visual_tween = null
	if not is_instance_valid(face_panel) or not is_instance_valid(depth_shadow) or not is_instance_valid(winner_glow):
		return
	face_panel.position = presentation_offset
	face_panel.rotation = presentation_rotation
	face_panel.scale = Vector2.ONE
	winner_glow.position = presentation_offset
	winner_glow.rotation = presentation_rotation
	winner_glow.scale = Vector2.ONE
	depth_shadow.position = presentation_offset + Vector2(2.0, 4.0)
	depth_shadow.rotation = presentation_rotation
	depth_shadow.scale = Vector2(0.99, 0.99)
	depth_shadow.modulate = Color(1.0, 1.0, 1.0, 0.9)


func _animate_visual_pose(target_offset: Vector2, target_rotation: float, target_scale: Vector2, duration: float) -> void:
	if not is_instance_valid(face_panel) or not is_instance_valid(depth_shadow) or not is_instance_valid(winner_glow):
		return
	if is_instance_valid(visual_tween):
		visual_tween.kill()
	visual_tween = create_tween().set_parallel(true)
	visual_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	visual_tween.tween_property(face_panel, "position", target_offset, duration)
	visual_tween.tween_property(face_panel, "rotation", target_rotation, duration)
	visual_tween.tween_property(face_panel, "scale", target_scale, duration)
	visual_tween.tween_property(winner_glow, "position", target_offset, duration)
	visual_tween.tween_property(winner_glow, "rotation", target_rotation, duration)
	visual_tween.tween_property(winner_glow, "scale", target_scale, duration)
	visual_tween.tween_property(depth_shadow, "position", target_offset + Vector2(3.0, 6.0), duration)
	visual_tween.tween_property(depth_shadow, "rotation", target_rotation, duration)
	visual_tween.tween_property(depth_shadow, "scale", target_scale * 0.99, duration)
	visual_tween.tween_property(depth_shadow, "modulate", Color(1.0, 1.0, 1.0, 0.72), duration)


func _get_card_color(card: Card) -> Color:
	if card.is_joker:
		return Color(0.42, 0.17, 0.05, 1.0)

	if card.suit == Card.Suit.HEARTS or card.suit == Card.Suit.DIAMONDS:
		return Color(0.78, 0.08, 0.07, 1.0)

	return Color(0.07, 0.1, 0.09, 1.0)


func _get_rank_text(rank: Card.Rank) -> String:
	match rank:
		Card.Rank.SIX:
			return "6"
		Card.Rank.SEVEN:
			return "7"
		Card.Rank.EIGHT:
			return "8"
		Card.Rank.NINE:
			return "9"
		Card.Rank.TEN:
			return "10"
		Card.Rank.JACK:
			return "В"
		Card.Rank.QUEEN:
			return "Д"
		Card.Rank.KING:
			return "К"
		Card.Rank.ACE:
			return "Т"

	return "?"


func _get_suit_symbol(suit: Card.Suit) -> String:
	match suit:
		Card.Suit.CLUBS:
			return "♣"
		Card.Suit.SPADES:
			return "♠"
		Card.Suit.HEARTS:
			return "♥"
		Card.Suit.DIAMONDS:
			return "♦"

	return "?"
