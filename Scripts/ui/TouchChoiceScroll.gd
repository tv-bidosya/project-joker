extends Node
## Finger scrolling over reaction buttons, without turning a swipe into a click.
var target: ScrollContainer
var allowed: Callable
var pointer := -1
var origin := Vector2.ZERO
var initial_scroll := 0.0
var dragging := false
var pressed_choice: Button
var ignore_mouse_until := 0

func configure(scroll: ScrollContainer, input_allowed: Callable) -> void:
	target = scroll
	allowed = input_allowed

func _cancel() -> void:
	if is_instance_valid(pressed_choice):
		pressed_choice.modulate = Color.WHITE
	pressed_choice = null
	pointer = -1
	dragging = false

func _find_choice(node: Node, point: Vector2) -> Button:
	for child in node.get_children():
		if child is Button and child.is_visible_in_tree() and not child.disabled and child.get_global_rect().has_point(point):
			return child
		var nested := _find_choice(child, point)
		if nested != null:
			return nested
	return null

func _input(event: InputEvent) -> void:
	if not is_instance_valid(target) or not target.is_visible_in_tree() or (allowed.is_valid() and not allowed.call()):
		_cancel()
		return
	if event is InputEventMouse:
		if (event.device == -1 or Time.get_ticks_msec() < ignore_mouse_until) and target.get_global_rect().has_point(event.position):
			get_viewport().set_input_as_handled()
		return
	if event is InputEventScreenTouch:
		ignore_mouse_until = Time.get_ticks_msec() + 600
		if event.pressed:
			if pointer != -1:
				_cancel()
				get_viewport().set_input_as_handled()
			elif target.get_global_rect().has_point(event.position):
				pointer = event.index
				origin = event.position
				initial_scroll = target.get_v_scroll_bar().value
				dragging = false
				pressed_choice = _find_choice(target, origin)
				if pressed_choice != null:
					pressed_choice.modulate = Color(1.2, 1.2, 1.2)
				get_viewport().set_input_as_handled()
		elif event.index == pointer:
			var choice := pressed_choice
			var can_select: bool = not dragging and not event.canceled and is_instance_valid(choice) and choice.get_global_rect().has_point(event.position) and target.get_global_rect().has_point(event.position)
			_cancel()
			get_viewport().set_input_as_handled()
			if can_select and not choice.disabled:
				if choice.toggle_mode:
					var group := choice.button_group
					if not (group != null and not group.allow_unpress and choice.button_pressed):
						choice.button_pressed = not choice.button_pressed
				choice.pressed.emit()
	elif event is InputEventScreenDrag and event.index == pointer:
		ignore_mouse_until = Time.get_ticks_msec() + 600
		var distance: float = event.position.y - origin.y
		if event.position.distance_to(origin) >= 10.0 or dragging:
			dragging = true
			if is_instance_valid(pressed_choice):
				pressed_choice.modulate = Color.WHITE
			target.get_v_scroll_bar().value = initial_scroll - distance
		get_viewport().set_input_as_handled()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		_cancel()
