extends Control
var amount := 0.0:
	set(value):
		amount = value
		queue_redraw()
var motion: Tween

func set_on(enabled: bool, animate := true) -> void:
	if motion != null and motion.is_valid():
		motion.kill()
	if animate and is_inside_tree():
		motion = create_tween()
		motion.tween_property(self, "amount", 1.0 if enabled else 0.0, 0.16).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	else:
		amount = 1.0 if enabled else 0.0

func _draw() -> void:
	var track := StyleBoxFlat.new()
	track.bg_color = Color(0.19, 0.22, 0.22).lerp(Color(0.15, 0.55, 0.3), amount)
	track.border_color = Color(0.8, 0.69, 0.38)
	track.set_border_width_all(2)
	track.set_corner_radius_all(23)
	draw_style_box(track, Rect2(Vector2.ZERO, Vector2(92, 46)))
	draw_circle(Vector2(23 + 46 * amount, 23), 17, Color(1.0, 0.94, 0.73))
