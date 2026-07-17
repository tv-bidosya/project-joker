class_name TurnTimerIndicator

extends Control


var remaining_ratio := 1.0
var remaining_seconds := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func set_time_remaining(remaining: float, total: float) -> void:
	remaining_seconds = maxf(0.0, remaining)
	remaining_ratio = clampf(remaining / maxf(total, 0.001), 0.0, 1.0)
	tooltip_text = "Автоход через %d с" % ceili(remaining_seconds)
	queue_redraw()


func _draw() -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return

	var center := size * 0.5
	var radius := maxf(8.0, minf(size.x, size.y) * 0.5 - 4.0)
	var start_angle := -PI * 0.5
	var end_angle := start_angle + TAU * remaining_ratio
	var progress_color := _get_progress_color()

	draw_arc(center, radius, 0.0, TAU, 64, Color(0.01, 0.03, 0.02, 0.76), 6.0, true)
	if remaining_ratio > 0.0:
		draw_arc(center, radius, start_angle, end_angle, 64, progress_color, 6.0, true)

	var badge_radius := 14.0
	var badge_center := Vector2(size.x - badge_radius - 2.0, badge_radius + 2.0)
	draw_circle(badge_center, badge_radius, Color(0.01, 0.04, 0.025, 0.88))
	draw_arc(badge_center, badge_radius, 0.0, TAU, 32, progress_color, 1.5, true)

	var seconds_text := str(ceili(remaining_seconds))
	var font: Font = ThemeDB.fallback_font
	var font_size := 12
	var text_baseline := badge_center.y + (font.get_ascent(font_size) - font.get_descent(font_size)) * 0.5
	var text_position := Vector2(badge_center.x - badge_radius, text_baseline)
	draw_string(font, text_position, seconds_text, HORIZONTAL_ALIGNMENT_CENTER, badge_radius * 2.0, font_size, Color(1.0, 0.95, 0.78, 1.0))


func _get_progress_color() -> Color:
	if remaining_ratio <= 0.16:
		return Color(0.95, 0.28, 0.18, 1.0)
	if remaining_ratio <= 0.35:
		return Color(0.98, 0.68, 0.2, 1.0)
	return Color(0.48, 0.9, 0.55, 1.0)
