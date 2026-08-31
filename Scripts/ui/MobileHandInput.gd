extends Control
## Mobile hand gestures. Never changes the hand or game state itself.
## The owner revalidates and submits the existing game command on confirmation.

signal card_confirmed(card: Card, card_key: String)

const DRAG_THRESHOLD := 24.0
const LONG_PRESS_SECONDS := 0.55
const NO_POINTER := -1
const MOUSE_POINTER := -2

var hand: HBoxContainer
var input_allowed: Callable
var context_key: Callable
var drop_area: Callable
var pointer_blockers: Array[Control] = []
var selected_key := ""
var active_pointer := NO_POINTER
var pressed_view: CardView
var press_position := Vector2.ZERO
var pointer_position := Vector2.ZERO
var hold_seconds := 0.0
var dragging := false
var pressed_selected := false
var current_context := ""
var ignore_mouse_until := 0
var drag_preview: CardView
var returning_preview: CardView
var return_tween: Tween
var drop_panel: Panel
var drop_label: Label


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 88
	drop_panel = Panel.new()
	drop_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	drop_panel.visible = false
	add_child(drop_panel)
	drop_label = Label.new()
	drop_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	drop_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	drop_label.offset_top = 10.0
	drop_label.offset_bottom = 48.0
	drop_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	drop_label.add_theme_font_size_override("font_size", 23)
	drop_label.add_theme_color_override("font_color", Color(1.0, 0.96, 0.8))
	drop_panel.add_child(drop_label)


func configure(hand_control: HBoxContainer, allowed: Callable, scope: Callable, area: Callable) -> void:
	hand = hand_control
	input_allowed = allowed
	context_key = scope
	drop_area = area
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		cancel()


func _exit_tree() -> void:
	cancel()


func _process(delta: float) -> void:
	if not _validate_context():
		return
	if active_pointer != NO_POINTER and not _view_is_current(pressed_view):
		cancel()
	_sync_selection()
	if active_pointer != NO_POINTER and not dragging and _view_is_current(pressed_view):
		hold_seconds += delta
		if hold_seconds >= LONG_PRESS_SECONDS and pressed_view.displayed_card.is_joker and _usable(pressed_view):
			_confirm(pressed_view)


func _input(event: InputEvent) -> void:
	if not _validate_context():
		return
	var handled := false
	if event is InputEventScreenTouch:
		ignore_mouse_until = Time.get_ticks_msec() + 600
		if event.canceled:
			handled = active_pointer == event.index
			if handled:
				cancel()
		elif event.pressed:
			if active_pointer != NO_POINTER:
				# A second finger cancels the gesture; neither release can play.
				cancel()
				handled = true
			else:
				handled = _begin_pointer(event.position, event.index)
		else:
			handled = _release_pointer(event.position, event.index)
	elif event is InputEventScreenDrag:
		ignore_mouse_until = Time.get_ticks_msec() + 600
		handled = _move_pointer(event.position, event.index)
	elif event is InputEventMouse:
		# Android also synthesizes mouse events from touch. Never count them
		# as a second tap; desktop mouse emulation still supports QA.
		if event.device == -1 or Time.get_ticks_msec() < ignore_mouse_until:
			return
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
			handled = _begin_pointer(event.position, MOUSE_POINTER) if event.pressed else _release_pointer(event.position, MOUSE_POINTER)
		elif event is InputEventMouseMotion:
			handled = _move_pointer(event.position, MOUSE_POINTER)
	if handled:
		get_viewport().set_input_as_handled()


func _validate_context() -> bool:
	if not is_instance_valid(hand) or not input_allowed.is_valid() or not bool(input_allowed.call()):
		cancel()
		return false
	var scope := str(context_key.call())
	if scope != current_context:
		cancel()
		current_context = scope
	return true


func _begin_pointer(point: Vector2, pointer_id: int) -> bool:
	if active_pointer != NO_POINTER:
		return false
	for blocker in pointer_blockers:
		if is_instance_valid(blocker) and blocker.is_visible_in_tree() and blocker.get_global_rect().has_point(point):
			selected_key = ""
			_sync_selection()
			return false
	var view := _card_at(point)
	if view == null:
		selected_key = ""
		_sync_selection()
		return false
	_clear_return_preview()
	pressed_view = view
	active_pointer = pointer_id
	press_position = point
	pointer_position = point
	hold_seconds = 0.0
	pressed_selected = selected_key == _key(view)
	return true


func _move_pointer(point: Vector2, pointer_id: int) -> bool:
	if active_pointer != pointer_id:
		return false
	if not _view_is_current(pressed_view):
		cancel()
		return true
	pointer_position = point
	if not dragging and point.distance_to(press_position) >= DRAG_THRESHOLD:
		dragging = true
		selected_key = ""
		_sync_selection()
		drag_preview = CardView.new()
		drag_preview.set_card(pressed_view.displayed_card)
		drag_preview.set_card_size(pressed_view.size)
		drag_preview.set_interactive(false, false)
		drag_preview.z_index = 1
		add_child(drag_preview)
		pressed_view.set_drag_source(true)
	if dragging:
		_update_drag_feedback()
	return true


func _release_pointer(point: Vector2, pointer_id: int) -> bool:
	if active_pointer != pointer_id:
		return false
	if not _view_is_current(pressed_view):
		cancel()
		return true
	var view := pressed_view
	if dragging:
		if _usable(view) and _drop_rect().has_point(point):
			_confirm(view)
		else:
			_end_pointer(true)
	elif point.distance_to(press_position) < DRAG_THRESHOLD and _card_at(point) == view and _usable(view):
		if pressed_selected:
			_confirm(view)
		else:
			selected_key = _key(view)
			_end_pointer()
			_sync_selection()
	else:
		selected_key = ""
		_end_pointer()
		_sync_selection()
	return true


func _confirm(view: CardView) -> void:
	if not _usable(view) or not bool(input_allowed.call()) or str(context_key.call()) != current_context:
		cancel()
		return
	var card := view.displayed_card
	var card_key := _key(view)
	cancel()
	# Cleanup must happen before the callback: it can rebuild/free the hand.
	card_confirmed.emit(card, card_key)


func cancel() -> void:
	selected_key = ""
	_end_pointer()
	_clear_return_preview()
	_sync_selection()


func _end_pointer(animate_return := false) -> void:
	var source := pressed_view
	if is_instance_valid(source):
		source.set_drag_source(false)
	if is_instance_valid(drag_preview):
		if animate_return and _view_is_current(source):
			_clear_return_preview()
			returning_preview = drag_preview
			return_tween = create_tween()
			return_tween.tween_property(returning_preview, "global_position", source.global_position, 0.16)
			return_tween.tween_callback(_clear_return_preview)
		else:
			drag_preview.queue_free()
	drag_preview = null
	if is_instance_valid(drop_panel):
		drop_panel.visible = false
	pressed_view = null
	active_pointer = NO_POINTER
	dragging = false
	hold_seconds = 0.0
	pressed_selected = false


func _clear_return_preview() -> void:
	if is_instance_valid(return_tween):
		return_tween.kill()
	return_tween = null
	if is_instance_valid(returning_preview):
		returning_preview.queue_free()
	returning_preview = null


func _update_drag_feedback() -> void:
	var rect := _drop_rect()
	var available := _usable(pressed_view)
	var inside := rect.has_point(pointer_position)
	drop_panel.global_position = rect.position
	drop_panel.size = rect.size
	drop_panel.visible = true
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.65, 0.32, 0.14 if inside else 0.07) if available else Color(0.65, 0.12, 0.12, 0.12)
	style.border_color = Color(1.0, 0.84, 0.35, 0.95) if available else Color(1.0, 0.3, 0.24, 0.95)
	style.set_border_width_all(3)
	style.set_corner_radius_all(24)
	drop_panel.add_theme_stylebox_override("panel", style)
	drop_label.text = tr("MOBILE_CARD_DROP") if available else tr("MOBILE_CARD_UNAVAILABLE")
	drag_preview.modulate = Color.WHITE if available else Color(1.0, 0.55, 0.5, 0.9)
	var preview_point := pointer_position - Vector2(drag_preview.size.x * 0.5, drag_preview.size.y * 0.85)
	var viewport_rect := get_viewport_rect()
	preview_point.x = clampf(preview_point.x, 0.0, maxf(0.0, viewport_rect.size.x - drag_preview.size.x))
	preview_point.y = clampf(preview_point.y, 0.0, maxf(0.0, viewport_rect.size.y - drag_preview.size.y))
	drag_preview.global_position = preview_point


func _drop_rect() -> Rect2:
	return drop_area.call() as Rect2


func _card_at(point: Vector2) -> CardView:
	if not is_instance_valid(hand):
		return null
	var views := hand.get_children()
	views.reverse()
	for child in views:
		var view := child as CardView
		if not _view_is_current(view):
			continue
		var rect := view.get_global_rect()
		if view.is_selected:
			rect = rect.expand(rect.position - Vector2(0.0, 28.0))
		if rect.has_point(point):
			return view
	return null


func _view_is_current(view: CardView) -> bool:
	return is_instance_valid(view) and not view.is_queued_for_deletion() and view.is_inside_tree() and view.is_visible_in_tree() and view.get_parent() == hand


func _usable(view: CardView) -> bool:
	return _view_is_current(view) and view.is_interactive and not view.is_disabled and not view.is_visually_unavailable


func _key(view: CardView) -> String:
	return str(view.get_meta("mobile_card_key", ""))


func _sync_selection() -> void:
	if not is_instance_valid(hand):
		return
	var found := false
	for child in hand.get_children():
		var view := child as CardView
		if view == null:
			continue
		var selected := not selected_key.is_empty() and _key(view) == selected_key and _usable(view)
		view.set_selected(selected)
		found = found or selected
	if not found:
		selected_key = ""