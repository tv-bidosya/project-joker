class_name MenuBackgroundEffects
extends Control


enum BackgroundKind {
	DAY,
	EVENING,
	NIGHT_CITY,
}

const DAY_SMOKE_SOURCES := [
	Vector2(0.902, 0.594),
	Vector2(0.934, 0.535),
	Vector2(0.967, 0.470),
]

var background_kind: BackgroundKind = BackgroundKind.DAY
var elapsed_seconds := 0.0
var random := RandomNumberGenerator.new()
var star_points: Array[Vector2] = []
var window_points: Array[Vector2] = []
var smoke_emitters: Array[CPUParticles2D] = []
var soft_glow_texture: GradientTexture2D


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS
	random.seed = 0x4A4F4B4552
	soft_glow_texture = _create_radial_texture(256)
	_build_night_city_points()
	_build_day_smoke_emitters()
	_update_smoke_emitter_positions()
	_update_smoke_emitting()
	set_process(true)
	queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and is_node_ready():
		_update_smoke_emitter_positions()


func set_background_kind(value: BackgroundKind) -> void:
	if background_kind == value:
		return
	background_kind = value
	_update_smoke_emitting()
	queue_redraw()


func _process(delta: float) -> void:
	elapsed_seconds += delta
	queue_redraw()


func _draw() -> void:
	if size.x <= 1.0 or size.y <= 1.0:
		return
	match background_kind:
		BackgroundKind.EVENING:
			_draw_salon_lights()
		BackgroundKind.NIGHT_CITY:
			_draw_night_city_lights()


func _create_radial_texture(texture_size: int) -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.18, 0.52, 1.0])
	gradient.colors = PackedColorArray([
		Color(1.0, 1.0, 1.0, 0.92),
		Color(1.0, 1.0, 1.0, 0.56),
		Color(1.0, 1.0, 1.0, 0.14),
		Color(1.0, 1.0, 1.0, 0.0),
	])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = texture_size
	texture.height = texture_size
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	return texture


func _create_smoke_texture() -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.35, 1.0])
	gradient.colors = PackedColorArray([
		Color(1.0, 1.0, 1.0, 0.72),
		Color(1.0, 1.0, 1.0, 0.28),
		Color(1.0, 1.0, 1.0, 0.0),
	])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = 64
	texture.height = 64
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	return texture


func _build_day_smoke_emitters() -> void:
	var smoke_texture := _create_smoke_texture()
	for source_index in DAY_SMOKE_SOURCES.size():
		var emitter := CPUParticles2D.new()
		emitter.name = "CandleSmoke%d" % (source_index + 1)
		emitter.z_index = 1
		emitter.amount = 12
		emitter.lifetime = 3.2
		emitter.preprocess = 3.2
		emitter.randomness = 0.72
		emitter.local_coords = true
		emitter.texture = smoke_texture
		emitter.direction = Vector2(0.0, -1.0)
		emitter.spread = 17.0
		emitter.gravity = Vector2(-1.8 if source_index % 2 == 0 else 1.8, -3.5)
		emitter.initial_velocity_min = 11.0
		emitter.initial_velocity_max = 22.0
		emitter.scale_amount_min = 0.20
		emitter.scale_amount_max = 0.48
		var smoke_gradient := Gradient.new()
		smoke_gradient.offsets = PackedFloat32Array([0.0, 0.16, 0.62, 1.0])
		smoke_gradient.colors = PackedColorArray([
			Color(0.72, 0.78, 0.80, 0.0),
			Color(0.76, 0.82, 0.84, 0.22),
			Color(0.66, 0.72, 0.75, 0.11),
			Color(0.62, 0.68, 0.71, 0.0),
		])
		emitter.color_ramp = smoke_gradient
		add_child(emitter)
		smoke_emitters.append(emitter)


func _update_smoke_emitter_positions() -> void:
	for index in mini(smoke_emitters.size(), DAY_SMOKE_SOURCES.size()):
		smoke_emitters[index].position = DAY_SMOKE_SOURCES[index] * size


func _update_smoke_emitting() -> void:
	for emitter in smoke_emitters:
		emitter.emitting = background_kind == BackgroundKind.DAY


func _build_night_city_points() -> void:
	star_points.clear()
	window_points.clear()
	for _index in 96:
		star_points.append(Vector2(random.randf_range(0.08, 0.92), random.randf_range(0.035, 0.38)))
	for index in 32:
		var on_left := index % 2 == 0
		window_points.append(Vector2(
			random.randf_range(0.12, 0.43) if on_left else random.randf_range(0.57, 0.88),
			random.randf_range(0.41, 0.59)
		))


func _draw_salon_lights() -> void:
	var candle_pulse := 0.82 + sin(elapsed_seconds * 7.0) * 0.11 + sin(elapsed_seconds * 13.0) * 0.05
	var lights := [
		[Vector2(0.057, 0.566), 68.0],
		[Vector2(0.785, 0.646), 44.0],
		[Vector2(0.902, 0.568), 54.0],
		[Vector2(0.934, 0.478), 49.0],
		[Vector2(0.967, 0.421), 54.0],
		[Vector2(0.989, 0.468), 38.0],
	]
	for light in lights:
		_draw_soft_glow((light[0] as Vector2) * size, float(light[1]), Color(1.0, 0.51, 0.16, 0.32 * candle_pulse))
	var moon_pulse := 0.93 + sin(elapsed_seconds * 0.72) * 0.07
	_draw_soft_glow(Vector2(0.121, 0.244) * size, 92.0, Color(0.52, 0.72, 1.0, 0.16 * moon_pulse))


func _draw_night_city_lights() -> void:
	for index in star_points.size():
		var raw_pulse := 0.5 + 0.5 * sin(elapsed_seconds * (1.5 + float(index % 5) * 0.24) + float(index) * 1.73)
		var pulse := pow(raw_pulse, 2.4)
		var radius := 1.15 + float(index % 4) * 0.48
		var star_position := star_points[index] * size
		var star_color := Color(0.78, 0.91, 1.0, 0.72 * pulse)
		draw_circle(star_position, radius, star_color, true, -1.0, true)
		if index % 7 == 0 and pulse > 0.42:
			var ray := 3.5 + radius
			draw_line(star_position - Vector2(ray, 0.0), star_position + Vector2(ray, 0.0), star_color, 1.0, true)
			draw_line(star_position - Vector2(0.0, ray), star_position + Vector2(0.0, ray), star_color, 1.0, true)
	for index in window_points.size():
		var pulse := 0.18 + 0.82 * pow(0.5 + 0.5 * sin(elapsed_seconds * (0.75 + float(index % 3) * 0.16) + float(index) * 2.11), 2.0)
		draw_circle(window_points[index] * size, 1.4 + float(index % 2) * 0.8, Color(1.0, 0.69, 0.24, 0.48 * pulse), true, -1.0, true)
	var lantern_pulse := 0.76 + sin(elapsed_seconds * 5.4) * 0.17 + sin(elapsed_seconds * 10.7) * 0.08
	_draw_soft_glow(Vector2(0.022, 0.742) * size, 82.0, Color(1.0, 0.53, 0.15, 0.42 * lantern_pulse))
	_draw_soft_glow(Vector2(0.103, 0.692) * size, 112.0, Color(1.0, 0.53, 0.15, 0.46 * lantern_pulse))
	_draw_soft_glow(Vector2(0.838, 0.704) * size, 108.0, Color(1.0, 0.53, 0.15, 0.45 * lantern_pulse))
	var moon_pulse := 0.94 + sin(elapsed_seconds * 0.58) * 0.06
	_draw_soft_glow(Vector2(0.263, 0.132) * size, 126.0, Color(0.48, 0.64, 1.0, 0.17 * moon_pulse))


func _draw_soft_glow(center: Vector2, radius: float, color: Color) -> void:
	if soft_glow_texture == null:
		return
	var glow_rect := Rect2(center - Vector2.ONE * radius, Vector2.ONE * radius * 2.0)
	draw_texture_rect(soft_glow_texture, glow_rect, false, color)
