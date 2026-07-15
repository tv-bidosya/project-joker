class_name CardView

extends Control


signal card_pressed(card: Card)


var displayed_card: Card
var is_interactive := false
var is_disabled := false
var is_hovered := false
var is_winner_highlighted := false

var face_panel: Panel
var top_corner_label: Label
var center_label: Label
var bottom_corner_label: Label
var status_label: Label


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
		label.add_theme_color_override("font_color", card_color)

	_refresh_face_style()


func set_card_size(card_size: Vector2) -> void:
	custom_minimum_size = card_size
	size = card_size


func set_status(status_text: String) -> void:
	status_label.text = status_text
	status_label.visible = not status_text.is_empty()


func set_interactive(interactive: bool, disabled: bool) -> void:
	is_interactive = interactive
	is_disabled = disabled
	mouse_filter = Control.MOUSE_FILTER_STOP if is_interactive and not is_disabled else Control.MOUSE_FILTER_IGNORE
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if is_interactive and not is_disabled else Control.CURSOR_ARROW
	modulate = Color(1.0, 1.0, 1.0, 0.42) if is_disabled else Color.WHITE
	_refresh_face_style()


func set_winner_highlight(enabled: bool) -> void:
	is_winner_highlighted = enabled
	_refresh_face_style()


func _gui_input(event: InputEvent) -> void:
	if not is_interactive or is_disabled or displayed_card == null:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		card_pressed.emit(displayed_card)
		accept_event()


func _create_visuals() -> void:
	face_panel = Panel.new()
	face_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	face_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(face_panel)

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

	status_label = Label.new()
	status_label.anchor_left = 0.0
	status_label.anchor_top = 1.0
	status_label.anchor_right = 1.0
	status_label.anchor_bottom = 1.0
	status_label.offset_left = 6.0
	status_label.offset_top = -30.0
	status_label.offset_right = -6.0
	status_label.offset_bottom = -6.0
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	status_label.add_theme_color_override("font_color", Color(0.42, 0.17, 0.05, 1.0))
	status_label.add_theme_font_size_override("font_size", 10)
	status_label.visible = false
	face_panel.add_child(status_label)

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

	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


func _refresh_face_style() -> void:
	if displayed_card == null:
		return

	var background_color := Color(0.96, 0.95, 0.87, 1.0) if displayed_card.is_joker else Color(0.98, 0.98, 0.94, 1.0)
	var is_hover_highlighted := is_interactive and not is_disabled and is_hovered
	var border_color := Color(0.98, 0.78, 0.25, 1.0) if is_winner_highlighted else (Color(0.88, 0.67, 0.22, 1.0) if is_hover_highlighted else Color(0.16, 0.2, 0.17, 1.0))
	var border_width := 4 if is_winner_highlighted else (3 if is_hover_highlighted else 2)
	var style := StyleBoxFlat.new()
	style.bg_color = background_color
	style.border_color = border_color
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(8)
	style.shadow_color = Color(0.98, 0.72, 0.16, 0.72) if is_winner_highlighted else Color(0.0, 0.0, 0.0, 0.42)
	style.shadow_size = 12 if is_winner_highlighted else 4
	style.shadow_offset = Vector2(0.0, 2.0)
	face_panel.add_theme_stylebox_override("panel", style)


func _on_mouse_entered() -> void:
	if is_interactive and not is_disabled:
		is_hovered = true
		position.y -= 8.0
		_refresh_face_style()


func _on_mouse_exited() -> void:
	if is_hovered:
		is_hovered = false
		position.y += 8.0
		_refresh_face_style()


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
