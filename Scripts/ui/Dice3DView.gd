class_name Dice3DView

extends SubViewportContainer


const VIEWPORT_SIZE := Vector2i(180, 116)
const PIP_SPACING := 0.25


var viewport: SubViewport
var die_body: Node3D
var die_mesh: MeshInstance3D
var winner_light: OmniLight3D
var result_badge: Label
var roll_tween: Tween
var roll_value := -1
var is_contender := true
var has_submitted := false
var is_winner := false


func _init() -> void:
	custom_minimum_size = Vector2(0.0, 82.0)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	stretch = true
	_create_3d_scene()
	_create_result_badge()


func configure(value: int, contender: bool, submitted: bool, winner: bool) -> void:
	roll_value = value
	is_contender = contender
	has_submitted = submitted
	is_winner = winner
	if is_inside_tree():
		_refresh_presentation()


func _ready() -> void:
	_refresh_presentation()


func _create_3d_scene() -> void:
	viewport = SubViewport.new()
	viewport.size = VIEWPORT_SIZE
	viewport.transparent_bg = true
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.msaa_3d = Viewport.MSAA_4X
	add_child(viewport)

	var camera := Camera3D.new()
	var camera_position := Vector3(0.0, 1.45, 3.25)
	camera.fov = 31.0
	camera.look_at_from_position(camera_position, Vector3(0.0, 0.03, 0.0), Vector3.UP)
	viewport.add_child(camera)

	var key_light := DirectionalLight3D.new()
	key_light.rotation_degrees = Vector3(-42.0, -28.0, 0.0)
	key_light.light_color = Color(1.0, 0.86, 0.62)
	key_light.light_energy = 1.45
	key_light.shadow_enabled = true
	viewport.add_child(key_light)

	var fill_light := OmniLight3D.new()
	fill_light.position = Vector3(-1.4, 0.7, 1.8)
	fill_light.light_color = Color(0.48, 0.66, 1.0)
	fill_light.light_energy = 0.7
	fill_light.omni_range = 5.0
	viewport.add_child(fill_light)

	winner_light = OmniLight3D.new()
	winner_light.position = Vector3(0.0, 0.7, 1.1)
	winner_light.light_color = Color(1.0, 0.64, 0.14)
	winner_light.light_energy = 0.0
	winner_light.omni_range = 4.0
	viewport.add_child(winner_light)

	var ground := MeshInstance3D.new()
	var ground_mesh := PlaneMesh.new()
	ground_mesh.size = Vector2(8.0, 8.0)
	ground.mesh = ground_mesh
	ground.position = Vector3(0.0, -0.69, 0.0)
	var ground_material := StandardMaterial3D.new()
	ground_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ground_material.albedo_color = Color(0.018, 0.13, 0.075, 0.44)
	ground_material.roughness = 0.9
	ground.material_override = ground_material
	viewport.add_child(ground)

	die_body = Node3D.new()
	die_body.position = Vector3(0.0, -0.08, 0.0)
	viewport.add_child(die_body)

	die_mesh = MeshInstance3D.new()
	var box_mesh := BoxMesh.new()
	box_mesh.size = Vector3(1.12, 1.12, 1.12)
	die_mesh.mesh = box_mesh
	var die_material := StandardMaterial3D.new()
	die_material.albedo_color = Color(0.97, 0.92, 0.78)
	die_material.metallic = 0.08
	die_material.roughness = 0.31
	die_material.emission_enabled = true
	die_material.emission = Color(0.12, 0.075, 0.025)
	die_material.emission_energy_multiplier = 0.26
	die_mesh.material_override = die_material
	die_body.add_child(die_mesh)

	_add_face_pips(1, Vector3.UP, Vector3.RIGHT, Vector3(0.0, 0.0, -1.0))
	_add_face_pips(6, Vector3.DOWN, Vector3.RIGHT, Vector3(0.0, 0.0, 1.0))
	_add_face_pips(2, Vector3.FORWARD, Vector3.RIGHT, Vector3.UP)
	_add_face_pips(5, Vector3.BACK, Vector3.LEFT, Vector3.UP)
	_add_face_pips(3, Vector3.RIGHT, Vector3(0.0, 0.0, -1.0), Vector3.UP)
	_add_face_pips(4, Vector3.LEFT, Vector3(0.0, 0.0, 1.0), Vector3.UP)


func _create_result_badge() -> void:
	result_badge = Label.new()
	result_badge.anchor_left = 1.0
	result_badge.anchor_top = 1.0
	result_badge.anchor_right = 1.0
	result_badge.anchor_bottom = 1.0
	result_badge.offset_left = -34.0
	result_badge.offset_top = -31.0
	result_badge.offset_right = -5.0
	result_badge.offset_bottom = -5.0
	result_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	result_badge.add_theme_font_size_override("font_size", 17)
	result_badge.add_theme_color_override("font_color", Color(0.12, 0.075, 0.025))
	result_badge.add_theme_color_override("font_outline_color", Color(1.0, 0.82, 0.3))
	result_badge.add_theme_constant_override("outline_size", 5)
	result_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(result_badge)


func _add_face_pips(value: int, normal: Vector3, horizontal_axis: Vector3, vertical_axis: Vector3) -> void:
	var pip_material := StandardMaterial3D.new()
	pip_material.albedo_color = Color(0.11, 0.055, 0.025)
	pip_material.metallic = 0.18
	pip_material.roughness = 0.4
	for point in _get_pip_pattern(value):
		var pip := MeshInstance3D.new()
		var pip_mesh := CylinderMesh.new()
		pip_mesh.top_radius = 0.073
		pip_mesh.bottom_radius = 0.073
		pip_mesh.height = 0.025
		pip_mesh.radial_segments = 16
		pip.mesh = pip_mesh
		pip.material_override = pip_material
		pip.position = normal * 0.569 + horizontal_axis * point.x * PIP_SPACING + vertical_axis * point.y * PIP_SPACING
		pip.quaternion = Quaternion(Vector3.UP, normal)
		die_body.add_child(pip)


func _get_pip_pattern(value: int) -> Array[Vector2]:
	var center := Vector2.ZERO
	var top_left := Vector2(-1.0, 1.0)
	var top_right := Vector2(1.0, 1.0)
	var middle_left := Vector2(-1.0, 0.0)
	var middle_right := Vector2(1.0, 0.0)
	var bottom_left := Vector2(-1.0, -1.0)
	var bottom_right := Vector2(1.0, -1.0)
	match value:
		1:
			return [center]
		2:
			return [top_left, bottom_right]
		3:
			return [top_left, center, bottom_right]
		4:
			return [top_left, top_right, bottom_left, bottom_right]
		5:
			return [top_left, top_right, center, bottom_left, bottom_right]
		6:
			return [top_left, top_right, middle_left, middle_right, bottom_left, bottom_right]
	return []


func _refresh_presentation() -> void:
	if not is_instance_valid(die_body):
		return
	if is_instance_valid(roll_tween):
		roll_tween.kill()
	roll_tween = null
	winner_light.light_energy = 2.4 if is_winner else 0.0
	result_badge.visible = roll_value >= 1 and roll_value <= 6
	result_badge.text = str(roll_value) if result_badge.visible else ""
	modulate = Color.WHITE if is_contender else Color(0.58, 0.62, 0.58, 0.56)

	if roll_value >= 1 and roll_value <= 6:
		_animate_to_result(roll_value)
	elif has_submitted:
		_animate_waiting_roll()
	else:
		die_body.position = Vector3(0.0, -0.08, 0.0)
		die_body.rotation = Vector3(-0.18, 0.38, -0.08)


func _animate_to_result(value: int) -> void:
	var target_rotation := _get_result_rotation(value)
	die_body.position = Vector3(-0.18, 0.62, 0.0)
	die_body.rotation = target_rotation + Vector3(-TAU * 2.0, TAU * 2.5, -TAU * 1.5)
	roll_tween = create_tween().set_parallel(true)
	roll_tween.tween_property(die_body, "position", Vector3(0.0, -0.08, 0.0), 0.92).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	roll_tween.tween_property(die_body, "rotation", target_rotation, 0.92).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	roll_tween.tween_property(die_body, "scale", Vector3.ONE, 0.92).from(Vector3(0.84, 0.84, 0.84)).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _animate_waiting_roll() -> void:
	die_body.position = Vector3(0.0, 0.12, 0.0)
	die_body.rotation = Vector3(-0.35, 0.0, 0.18)
	roll_tween = create_tween().set_loops()
	roll_tween.tween_property(die_body, "rotation", Vector3(-0.35 + TAU, TAU * 2.0, 0.18 + TAU), 1.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)


func _get_result_rotation(value: int) -> Vector3:
	match value:
		1:
			return Vector3(PI * 0.5, 0.18, -0.08)
		2:
			return Vector3(-0.16, 0.18, -0.08)
		3:
			return Vector3(-0.16, -PI * 0.5 + 0.18, -0.08)
		4:
			return Vector3(-0.16, PI * 0.5 + 0.18, -0.08)
		5:
			return Vector3(-0.16, PI + 0.18, -0.08)
		6:
			return Vector3(-PI * 0.5, 0.18, -0.08)
	return Vector3.ZERO
