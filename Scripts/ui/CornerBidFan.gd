extends PanelContainer
## Mobile bid tray displayed directly on the table. The historical class name is
## kept because saved scenes and probes preload this resource.
const FAN_SIZE := Vector2(1010.0, 226.0)
const MAX_COLUMNS := 7
const BUTTON_SIZE := Vector2(120.0, 72.0)
const H_GAP := 10
const V_GAP := 10
var source_ids: Array[int] = []
var fan_buttons: Array[Button] = []

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP

func configure(source: GridContainer) -> void:
	fan_buttons.clear()
	source_ids.clear()
	var sources: Array[Button] = []
	for child in source.get_children():
		if child is Button and not child.is_queued_for_deletion():
			sources.append(child)
			source_ids.append(child.get_instance_id())
	var option_count := sources.size()
	source.columns = maxi(1, option_count if option_count <= MAX_COLUMNS else ceili(option_count / 2.0))
	source.add_theme_constant_override("h_separation", H_GAP)
	source.add_theme_constant_override("v_separation", V_GAP)
	for button in sources:
		button.custom_minimum_size = BUTTON_SIZE
		button.add_theme_font_size_override("font_size", 30)
		preload("res://Scripts/ui/MobileTableLayout.gd").action_style(button)
		fan_buttons.append(button)
	var rows := maxi(1, ceili(float(option_count) / float(source.columns)))
	var width := float(source.columns) * BUTTON_SIZE.x + float(maxi(0, source.columns - 1) * H_GAP) + 36.0
	var height := float(rows) * BUTTON_SIZE.y + float(maxi(0, rows - 1) * V_GAP) + 72.0
	custom_minimum_size = Vector2(maxf(320.0, width), height)
