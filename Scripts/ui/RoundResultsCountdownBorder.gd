class_name RoundResultsCountdownBorder

extends Control


var remaining_ratio := 0.0
var remaining_seconds := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func set_time_remaining(remaining: float, total: float, tooltip_template: String = "") -> void:
	remaining_seconds = maxf(0.0, remaining)
	remaining_ratio = clampf(remaining_seconds / maxf(total, 0.001), 0.0, 1.0)
	tooltip_text = tooltip_template % ceili(remaining_seconds) if not tooltip_template.is_empty() else ""
	queue_redraw()


func _draw() -> void:
	if size.x <= 8.0 or size.y <= 8.0:
		return

	var inset := 3.0
	var left := inset
	var top := inset
	var right := size.x - inset
	var bottom := size.y - inset
	var path := PackedVector2Array([
		Vector2(size.x * 0.5, top),
		Vector2(right, top),
		Vector2(right, bottom),
		Vector2(left, bottom),
		Vector2(left, top),
		Vector2(size.x * 0.5, top)
	])

	draw_polyline(path, Color(0.2, 0.13, 0.045, 0.82), 3.0, true)
	if remaining_ratio <= 0.0:
		return

	var remaining_path := _build_partial_path(path, remaining_ratio)
	var fuse_color := _get_fuse_color()
	draw_polyline(remaining_path, Color(fuse_color.r, fuse_color.g, fuse_color.b, 0.2), 9.0, true)
	draw_polyline(remaining_path, fuse_color, 3.5, true)
	if remaining_path.size() > 0:
		var fuse_head := remaining_path[remaining_path.size() - 1]
		draw_circle(fuse_head, 5.5, Color(fuse_color.r, fuse_color.g, fuse_color.b, 0.22))
		draw_circle(fuse_head, 2.7, Color(1.0, 0.94, 0.62, 1.0))


func _build_partial_path(path: PackedVector2Array, ratio: float) -> PackedVector2Array:
	var total_length := 0.0
	for point_index in range(path.size() - 1):
		total_length += path[point_index].distance_to(path[point_index + 1])

	var target_length := total_length * clampf(ratio, 0.0, 1.0)
	var result := PackedVector2Array([path[0]])
	var drawn_length := 0.0
	for point_index in range(path.size() - 1):
		var from_point := path[point_index]
		var to_point := path[point_index + 1]
		var segment_length := from_point.distance_to(to_point)
		if drawn_length + segment_length <= target_length:
			result.append(to_point)
			drawn_length += segment_length
			continue
		var segment_ratio := (target_length - drawn_length) / maxf(segment_length, 0.001)
		result.append(from_point.lerp(to_point, clampf(segment_ratio, 0.0, 1.0)))
		break
	return result


func _get_fuse_color() -> Color:
	if remaining_ratio <= 0.18:
		return Color(1.0, 0.28, 0.15, 1.0)
	if remaining_ratio <= 0.4:
		return Color(1.0, 0.67, 0.16, 1.0)
	return Color(0.98, 0.82, 0.3, 1.0)
