extends Node
## Scroll a read-only history/result panel with a finger, independent of mouse emulation.

var target: Control
var allowed: Callable
var active_pointer := -1
var start_position := Vector2.ZERO
var start_scroll := 0.0
var follow_tail := true
var dragging := false


func configure(control: Control, input_allowed: Callable) -> void:
	target = control
	allowed = input_allowed


func _bar() -> VScrollBar:
	return target.get_v_scroll_bar()


func _input(event: InputEvent) -> void:
	if not is_instance_valid(target) or not target.is_visible_in_tree() or (allowed.is_valid() and not allowed.call()):
		active_pointer = -1
		dragging = false
		return
	if event is InputEventScreenTouch:
		if event.pressed and active_pointer == -1 and target.get_global_rect().has_point(event.position):
			if _bar().max_value <= _bar().page:
				return
			active_pointer = event.index
			start_position = event.position
			start_scroll = _bar().value
			dragging = false
			get_viewport().set_input_as_handled()
		elif event.index == active_pointer and (not event.pressed or event.canceled):
			active_pointer = -1
			dragging = false
			get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag and event.index == active_pointer:
		var distance: float = event.position.y - start_position.y
		if absf(distance) >= 8.0 or dragging:
			dragging = true
			_bar().value = start_scroll - distance
			follow_tail = _bar().value >= _bar().max_value - _bar().page - 2.0
		get_viewport().set_input_as_handled()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		active_pointer = -1
		dragging = false
