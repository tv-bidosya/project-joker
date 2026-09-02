extends RefCounted
## Phone settings use explicit choice tiles; desktop keeps its original controls.
var main: Variant
const ToggleSwitch = preload("res://Scripts/ui/MobileToggleSwitch.gd")
const DECK_NAMES := ["Jumbo · четыре цвета", "Классическая · четыре цвета", "Компактная · четыре цвета", "Jumbo · оригинальная (2 цвета)", "Простая · первая версия", "Классическая векторная · Full HD"]

func _init(manager: Node) -> void:
	main = manager

func _begin(title: String) -> void:
	main.menu_overlay.show()
	main._clear_children(main.menu_content)
	main.mobile_settings_page = true
	main._add_menu_title(title, "")
	main._ensure_mobile_menu_touch_scroll()

func _back(callback: Callable) -> void:
	main._add_menu_spacer(14)
	main._add_menu_button("Назад", callback)
	main._queue_menu_panel_fit()

func _grid(columns: int) -> GridContainer:
	var center := CenterContainer.new()
	main.menu_content.add_child(center)
	var grid := GridContainer.new()
	grid.columns = columns
	grid.add_theme_constant_override("h_separation", 18)
	grid.add_theme_constant_override("v_separation", 18)
	center.add_child(grid)
	return grid

func _tile(text: String, dimensions: Vector2) -> Button:
	var button: Button = main._create_menu_button(text, func(): pass)
	main._apply_mobile_menu_tile_style(button)
	button.custom_minimum_size = dimensions
	button.add_theme_font_size_override("font_size", 28)
	button.set_meta("mobile_setting_tile", true)
	return button

func _label(text: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = tr(text)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_override("font", main.menu_body_font)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", main._get_menu_palette().text)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label

func _content(button: Button, margin := 22.0) -> VBoxContainer:
	var content := VBoxContainer.new()
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content.offset_left = margin
	content.offset_top = 18
	content.offset_right = -margin
	content.offset_bottom = -18
	content.add_theme_constant_override("separation", 12)
	button.add_child(content)
	return content

func _choice_group(group_name: String, heading: String, names: Array, selected: int, callback: Callable, columns := 3) -> void:
	if not heading.is_empty():
		main._add_menu_label(heading, 32, Color(0.97, 0.86, 0.55, 1))
	var grid := _grid(columns)
	grid.name = group_name
	var group := ButtonGroup.new()
	group.allow_unpress = false
	for index in names.size():
		var button := _tile(str(names[index]), Vector2(540 if columns == 2 else 350, 150))
		button.name = "%sChoice%d" % [group_name, index]
		button.toggle_mode = true
		button.button_group = group
		button.button_pressed = index == selected
		button.set_meta("choice_index", index)
		grid.add_child(button)
		var check := Label.new()
		check.name = "SelectionCheck"
		check.text = "✓"
		check.mouse_filter = Control.MOUSE_FILTER_IGNORE
		check.add_theme_font_size_override("font_size", 30)
		check.add_theme_color_override("font_color", Color(1, 0.89, 0.4))
		check.position = Vector2(22, 8)
		check.visible = button.button_pressed
		button.add_child(check)
		button.toggled.connect(func(enabled: bool): check.visible = enabled)
		button.pressed.connect(func(): callback.call(index))
	main._add_menu_spacer(10)

func _summary(parent: GridContainer, title: String, value: String, callback: Callable) -> void:
	var button := _tile("", Vector2(350, 240))
	parent.add_child(button)
	var content := _content(button)
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	var heading := _label(title, 34)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(heading)
	var selected := _label(value, 26)
	selected.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	selected.add_theme_color_override("font_color", main._get_menu_palette().secondary)
	content.add_child(selected)
	button.pressed.connect(callback)

func show_appearance() -> void:
	_begin("Оформление")
	var grid := _grid(3)
	_summary(grid, "MOBILE_SETTINGS_CARDS", DECK_NAMES[main.card_deck_style], show_decks)
	_summary(grid, "MOBILE_SETTINGS_FELT", main.TABLE_FELT_NAMES[main.table_felt_theme], show_felt)
	_summary(grid, "MOBILE_SETTINGS_SURROUND", main.TABLE_SURROUND_NAMES[main.table_surround_theme], show_surround)
	_back(main._show_settings_menu)

func show_decks() -> void:
	_begin("Оформление карт")
	_choice_group("MobileDeckChoices", "", DECK_NAMES, main.card_deck_style, main._on_card_deck_style_selected)
	main.card_deck_preview_container = HBoxContainer.new()
	main.card_deck_preview_container.alignment = BoxContainer.ALIGNMENT_CENTER
	main.card_deck_preview_container.add_theme_constant_override("separation", 12)
	main.menu_content.add_child(main.card_deck_preview_container)
	main._refresh_card_deck_preview()
	_back(show_appearance)

func _table_preview() -> void:
	main.table_theme_preview_surround = PanelContainer.new()
	main.table_theme_preview_surround.name = "TableThemePreview"
	main.table_theme_preview_surround.custom_minimum_size = Vector2(0, 170)
	main.menu_content.add_child(main.table_theme_preview_surround)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 22)
	main.table_theme_preview_surround.add_child(margin)
	main.table_theme_preview_felt = Panel.new()
	margin.add_child(main.table_theme_preview_felt)
	main._refresh_table_theme_preview()

func show_felt() -> void:
	_begin("MOBILE_SETTINGS_FELT")
	_choice_group("MobileFeltChoices", "", main.TABLE_FELT_NAMES, main.table_felt_theme, main._on_table_felt_theme_selected)
	_table_preview()
	_back(show_appearance)

func show_surround() -> void:
	_begin("MOBILE_SETTINGS_SURROUND")
	_choice_group("MobileSurroundChoices", "", main.TABLE_SURROUND_NAMES, main.table_surround_theme, main._on_table_surround_theme_selected)
	_table_preview()
	_back(show_appearance)

func show_game() -> void:
	_begin("Игра")
	_choice_group("MobileBotSpeedChoices", "Скорость ходов ботов", ["Медленно", "Обычно", "Быстро"], main.bot_speed_index, main._on_bot_speed_selected)
	var grid := _grid(2)
	add_toggle(grid, "SettingsTutorialToggle", "Режим обучения", "Показывает на столе подсказки по заказам, картам и этапам раздачи.", main.tutorial_enabled, main._on_tutorial_toggled, Vector2(550, 250))
	add_toggle(grid, "SettingsAutoTurnToggle", "Автоход · 45 секунд", "MOBILE_AUTO_TURN_HELP", main.auto_turn_enabled, main._on_auto_turn_toggled, Vector2(550, 250))
	_back(main._show_settings_menu)

func show_display() -> void:
	_begin("Экран")
	_choice_group("MobileUiThemeChoices", "Оформление интерфейса", main.MENU_UI_THEME_NAMES, main.menu_ui_theme, main._on_menu_ui_theme_selected, 2)
	_choice_group("MobileBackgroundChoices", "Фон главного меню", main.MENU_BACKGROUND_THEME_NAMES, main.menu_background_theme, main._on_menu_background_theme_selected, 2)
	main._add_menu_label("Автоматический режим использует системное время: день с 06:00 до 17:59, вечер — с 18:00 до 05:59.", 26)
	_back(main._show_settings_menu)

func add_toggle(parent: Node, node_name: String, title: String, help: String, enabled: bool, callback: Callable, dimensions := Vector2(1100, 180)) -> Button:
	var button := _tile("", dimensions)
	button.name = node_name
	button.toggle_mode = true
	button.button_pressed = enabled
	button.set_meta("mobile_toggle_tile", true)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	parent.add_child(button)
	var content := _content(button, 30)
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 14)
	content.add_child(row)
	var title_label := _label(title, 32)
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(title_label)
	var switch := ToggleSwitch.new()
	switch.name = "SwitchTrack"
	switch.mouse_filter = Control.MOUSE_FILTER_IGNORE
	switch.custom_minimum_size = Vector2(92, 46)
	switch.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(switch)
	switch.set_on(enabled, false)
	var state := _label("MOBILE_TOGGLE_ON" if enabled else "MOBILE_TOGGLE_OFF", 28)
	state.name = "SwitchState"
	state.custom_minimum_size.x = 90
	row.add_child(state)
	if not help.is_empty():
		var hint := _label(help, 26)
		hint.add_theme_color_override("font_color", main._get_menu_palette().secondary)
		content.add_child(hint)
	button.toggled.connect(func(value: bool):
		switch.set_on(value)
		state.text = tr("MOBILE_TOGGLE_ON" if value else "MOBILE_TOGGLE_OFF")
		callback.call(value)
	)
	return button
