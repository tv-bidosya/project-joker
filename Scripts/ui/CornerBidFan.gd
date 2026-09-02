extends PanelContainer
## Mobile bid actions fan out from the lower-right corner. The hidden original
## controls remain the source of truth for availability and callbacks.
const FAN_SIZE := Vector2(520.0, 485.0)
const ORIGIN := Vector2(468.0, 405.0)
const BUTTON_SIZE := Vector2(104.0, 72.0)
var source_ids: Array[int] = []
var fan_buttons: Array[Button] = []
var destinations: Array[Vector2] = []
var motion: Tween
var button_layer: Control

func _ready() -> void:
	add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	button_layer = Control.new()
	button_layer.name = "FanButtons"
	button_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(button_layer)
	visibility_changed.connect(_on_visibility_changed)

func configure(source: GridContainer) -> void:
	var sources: Array[Button] = []
	var ids: Array[int] = []
	for child in source.get_children():
		if child is Button and not child.is_queued_for_deletion():
			sources.append(child)
			ids.append(child.get_instance_id())
	if ids == source_ids:
		for index in sources.size():
			fan_buttons[index].disabled = sources[index].disabled
			fan_buttons[index].text = sources[index].text
		return
	source_ids = ids
	if motion != null and motion.is_valid():
		motion.kill()
	for button in fan_buttons:
		button_layer.remove_child(button)
		button.queue_free()
	fan_buttons.clear()
	destinations.clear()
	var radii := [130.0, 238.0, 364.0]
	var capacities := [2, 4, 6]
	var cursor := 0
	for ring in radii.size():
		var count: int = mini(capacities[ring], sources.size() - cursor)
		for index in maxi(0, count):
			var original: Button = sources[cursor]
			var button := Button.new()
			button.name = "FanBid%d" % cursor
			button.text = original.text
			button.disabled = original.disabled
			button.custom_minimum_size = BUTTON_SIZE
			button.size = BUTTON_SIZE
			button.add_theme_font_size_override("font_size", 28)
			for state in [&"normal", &"hover", &"pressed", &"disabled", &"focus"]:
				button.add_theme_stylebox_override(state, original.get_theme_stylebox(state))
			preload("res://Scripts/ui/MobileTableLayout.gd").action_style(button)
			button.pressed.connect(func():
				if is_instance_valid(original) and not original.disabled:
					original.pressed.emit()
			)
			var angle := lerpf(PI, PI * 1.5, float(index) / float(maxi(1, count - 1))) if count > 1 else PI * 1.25
			var target: Vector2 = ORIGIN + Vector2.from_angle(angle) * float(radii[ring]) - BUTTON_SIZE * 0.5
			button_layer.add_child(button)
			button.position = target
			fan_buttons.append(button)
			destinations.append(target)
			cursor += 1
	queue_redraw()
	if visible:
		animate_open()

func _draw() -> void:
	if fan_buttons.is_empty():
		return
	var radii := [130.0, 238.0, 364.0]
	var rings := 1 if fan_buttons.size() <= 2 else (2 if fan_buttons.size() <= 6 else 3)
	var background_radius: float = radii[rings - 1] + 44.0
	var polygon := PackedVector2Array([ORIGIN])
	for index in 49:
		polygon.append(ORIGIN + Vector2.from_angle(PI + PI * 0.5 * float(index) / 48.0) * background_radius)
	draw_colored_polygon(polygon, Color(0.012, 0.06, 0.04, 0.92))
	for ring in rings:
		draw_arc(ORIGIN, radii[ring], PI, PI * 1.5, 48, Color(0.8, 0.59, 0.22, 0.4), 2.0, true)

func _on_visibility_changed() -> void:
	if visible and is_instance_valid(button_layer):
		animate_open()

func animate_open() -> void:
	if motion != null and motion.is_valid():
		motion.kill()
	motion = create_tween().set_parallel(true)
	for index in fan_buttons.size():
		var button := fan_buttons[index]
		button.position = ORIGIN - BUTTON_SIZE * 0.5
		button.modulate.a = 0.0
		var delay := float(index) * 0.025
		motion.tween_property(button, "position", destinations[index], 0.28).set_delay(delay).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		motion.tween_property(button, "modulate:a", 1.0, 0.2).set_delay(delay)
