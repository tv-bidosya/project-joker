extends Control


const PLAYER_NAMES := ["Андрей", "Олег", "Маша", "Лена"]
const HUMAN_PLAYER_INDEX := 0
const NORMAL_ROUND_COUNT := 13
const DARK_ROUND_COUNT := 5
const NO_TRUMP_ROUND_COUNT := 4
const GOLDEN_ROUND_COUNT := 5
const MISERE_ROUND_COUNT := 5
const TOTAL_ROUND_COUNT := NORMAL_ROUND_COUNT + DARK_ROUND_COUNT + NO_TRUMP_ROUND_COUNT + GOLDEN_ROUND_COUNT + MISERE_ROUND_COUNT
const CARD_APPEAR_DURATION := 0.22
const TRICK_WINNER_HOLD_DURATION := 0.7
const BOT_SPEED_COUNT := 3
const BOT_DIFFICULTY_COUNT := 3
const SOUND_VOLUME_COUNT := 4
const PERSISTENT_SETTINGS_PATH := "user://project_joker_settings.cfg"
const SESSION_SAVE_PATH := "user://project_joker_session.save"
const SESSION_SAVE_VERSION := 1


enum HandSortMode {
	BY_SUIT,
	TRUMPS_LEFT
}


enum BotDifficulty {
	EASY,
	NORMAL,
	HARD
}


enum SoundEffect {
	DEAL,
	CARD,
	TRICK
}


@onready var phase_label: Label = %PhaseLabel
@onready var trump_label: Label = %TrumpLabel
@onready var background: ColorRect = %Background
@onready var players_container: Control = %PlayersContainer
@onready var table_panel: PanelContainer = %TablePanel
@onready var deck_visual: Control = %DeckVisual
@onready var table_label: Label = %TableLabel
@onready var trick_slots: Control = %TrickSlots
@onready var action_label: Label = %ActionLabel
@onready var round_history_toggle_button: Button = %RoundHistoryToggleButton
@onready var round_history_panel: PanelContainer = %RoundHistoryPanel
@onready var round_history_scroll: ScrollContainer = %RoundHistoryScroll
@onready var history_label: Label = %HistoryLabel
@onready var round_results_panel: PanelContainer = %RoundResultsPanel
@onready var round_results_label: Label = %RoundResultsLabel
@onready var bid_controls: HBoxContainer = %BidControls
@onready var joker_controls: GridContainer = %JokerControls
@onready var hand_container: HBoxContainer = %HandContainer
@onready var hand_title: Label = %HandTitle
@onready var hand_sort_by_suit_button: Button = %HandSortBySuitButton
@onready var hand_sort_trumps_left_button: Button = %HandSortTrumpsLeftButton
@onready var undo_button: Button = %UndoButton
@onready var score_sheet_toggle_button: Button = %ScoreSheetToggleButton
@onready var score_sheet_panel: PanelContainer = %ScoreSheetPanel
@onready var score_sheet_title: Label = %ScoreSheetTitle
@onready var score_sheet_grid: GridContainer = %ScoreSheetGrid
@onready var final_results_label: Label = %FinalResultsLabel
@onready var next_round_button: Button = %NextRoundButton
@onready var pause_menu_button: Button = %PauseMenuButton


var game := Game.new(PLAYER_NAMES)
var player_labels: Array[Label] = []
var player_stats_labels: Array[Label] = []
var player_panels: Array[PanelContainer] = []
var avatar_badges: Array[PanelContainer] = []
var avatar_images: Array[TextureRect] = []
var avatar_labels: Array[Label] = []
var trick_card_views: Array[CardView] = []
var bot_card_back_holders: Array[Control] = []
var deck_back_panels: Array[PanelContainer] = []
var deck_trump_panel: PanelContainer
var deck_trump_label: Label
var deck_caption_label: Label
var dealer_marker: PanelContainer
var lead_marker: PanelContainer
var pending_joker_card: Card
var pending_joker_suit := -1
var last_trick_text := "Взятка ещё не началась"
var action_text := "Подготовка партии"
var recent_actions := PackedStringArray()
var normal_round_index := 0
var dark_round_index := -1
var no_trump_round_index := -1
var golden_round_index := -1
var misere_round_index := -1
var is_processing_automatic_actions := false
var is_trick_presentation_active := false
var pending_play_presentation := false
var pending_card_animation_player_index := -1
var pending_trick_winner_player_index := -1
var test_checkpoints: Array[Dictionary] = []
var pending_test_checkpoint: Dictionary = {}
var round_history: Array[Dictionary] = []
var is_score_sheet_visible := false
var is_round_history_visible := true
var bot_random := RandomNumberGenerator.new()
var hand_sort_mode: HandSortMode = HandSortMode.BY_SUIT
var player_panel_style: StyleBoxFlat
var human_player_panel_style: StyleBoxFlat
var active_player_panel_style: StyleBoxFlat
var active_human_player_panel_style: StyleBoxFlat
var card_back_style: StyleBoxFlat
var deck_trump_card_style: StyleBoxFlat
var dealer_marker_style: StyleBoxFlat
var lead_marker_style: StyleBoxFlat
var avatar_badge_style: StyleBoxFlat
var menu_overlay: Control
var menu_panel: PanelContainer
var menu_content: VBoxContainer
var bot_speed_index := 1
var bot_difficulty: BotDifficulty = BotDifficulty.NORMAL
var sound_volume_index := 2
var is_pause_menu_open := false
var configured_player_names: Array[String] = ["Андрей", "Олег", "Маша", "Лена"]
var configured_avatar_indices: Array[int] = [0, 1, 2, 3]
var new_game_name_inputs: Array[LineEdit] = []
var new_game_avatar_selectors: Array[OptionButton] = []
var new_game_bot_difficulty_selector: OptionButton
var profile_name_input: LineEdit
var profile_avatar_selector: OptionButton
var sound_players: Array[AudioStreamPlayer] = []
var sound_streams: Dictionary = {}
var next_sound_player_index := 0


func _ready() -> void:
	bot_random.randomize()
	_run_joker_rule_checks()
	_run_score_rule_checks()
	_run_dark_round_checks()
	_run_no_trump_round_checks()
	_run_no_bid_round_checks()
	_run_bot_rule_checks()
	_run_hand_sort_checks()
	_run_round_history_checks()
	_run_session_save_checks()
	_load_persistent_settings()
	_create_table_visual_styles()
	_create_player_panels()
	_create_player_avatar_badges()
	_create_trick_slots()
	_create_bot_card_backs()
	_create_deck_visual()
	_create_table_markers()
	_create_sound_players()
	joker_controls.reparent(self)
	_create_main_menu()
	joker_controls.z_index = 80
	joker_controls.mouse_filter = Control.MOUSE_FILTER_PASS
	undo_button.pressed.connect(_on_undo_pressed)
	score_sheet_toggle_button.pressed.connect(_on_score_sheet_toggle_pressed)
	round_history_toggle_button.pressed.connect(_on_round_history_toggle_pressed)
	hand_sort_by_suit_button.pressed.connect(_on_hand_sort_by_suit_pressed)
	hand_sort_trumps_left_button.pressed.connect(_on_hand_sort_trumps_left_pressed)
	next_round_button.pressed.connect(_on_next_round_pressed)
	pause_menu_button.pressed.connect(_on_pause_menu_pressed)
	_show_main_menu()


func _create_table_visual_styles() -> void:
	background.color = Color(0.115, 0.062, 0.028, 1.0)
	table_panel.add_theme_stylebox_override(
		"panel",
		_create_flat_style(Color(0.018, 0.145, 0.085, 1.0), Color(0.265, 0.145, 0.058, 1.0), 8, 16, 8)
	)
	player_panel_style = _create_flat_style(Color(0.028, 0.073, 0.052, 0.96), Color(0.38, 0.255, 0.11, 0.86), 1, 10, 3)
	human_player_panel_style = player_panel_style
	active_player_panel_style = _create_flat_style(Color(0.105, 0.12, 0.052, 0.98), Color(0.95, 0.75, 0.28, 1.0), 3, 10, 7)
	active_human_player_panel_style = active_player_panel_style
	card_back_style = _create_flat_style(Color(0.045, 0.11, 0.22, 1.0), Color(0.8, 0.62, 0.25, 1.0), 2, 6, 2)
	deck_trump_card_style = _create_flat_style(Color(0.92, 0.9, 0.76, 1.0), Color(0.88, 0.68, 0.24, 1.0), 2, 8, 3)
	dealer_marker_style = _create_flat_style(Color(0.33, 0.2, 0.07, 1.0), Color(0.96, 0.77, 0.31, 1.0), 2, 12, 3)
	lead_marker_style = _create_flat_style(Color(0.055, 0.2, 0.13, 1.0), Color(0.64, 0.86, 0.52, 1.0), 1, 8, 2)
	avatar_badge_style = _create_flat_style(Color(0.04, 0.1, 0.07, 1.0), Color(0.75, 0.58, 0.2, 1.0), 2, 6, 2)


func _create_flat_style(
	background_color: Color,
	border_color: Color,
	border_width: int,
	corner_radius: int,
	shadow_size: int
) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background_color
	style.border_color = border_color
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(corner_radius)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.45)
	style.shadow_size = shadow_size
	style.shadow_offset = Vector2(0, 2)
	return style


func _create_main_menu() -> void:
	menu_overlay = Control.new()
	menu_overlay.name = "MainMenuOverlay"
	_set_control_layout(menu_overlay, 0.0, 0.0, 1.0, 1.0, 0.0, 0.0, 0.0, 0.0)
	menu_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	menu_overlay.z_index = 100
	add_child(menu_overlay)

	var menu_backdrop := ColorRect.new()
	menu_backdrop.color = Color(0.006, 0.055, 0.034, 0.98)
	menu_backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	menu_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu_overlay.add_child(menu_backdrop)

	menu_panel = PanelContainer.new()
	menu_panel.name = "MenuPanel"
	_set_control_layout(menu_panel, 0.5, 0.5, 0.5, 0.5, -340.0, -350.0, 340.0, 350.0)
	menu_panel.add_theme_stylebox_override(
		"panel",
		_create_flat_style(Color(0.018, 0.145, 0.085, 1.0), Color(0.47, 0.29, 0.1, 1.0), 4, 18, 12)
	)
	menu_overlay.add_child(menu_panel)

	var menu_margin := MarginContainer.new()
	menu_margin.add_theme_constant_override("margin_left", 42)
	menu_margin.add_theme_constant_override("margin_top", 38)
	menu_margin.add_theme_constant_override("margin_right", 42)
	menu_margin.add_theme_constant_override("margin_bottom", 38)
	menu_panel.add_child(menu_margin)

	menu_content = VBoxContainer.new()
	menu_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	menu_content.add_theme_constant_override("separation", 14)
	menu_margin.add_child(menu_content)


func _show_main_menu() -> void:
	is_pause_menu_open = false
	menu_overlay.visible = true
	_build_main_menu_content()


func _hide_main_menu() -> void:
	menu_overlay.visible = false


func _build_main_menu_content() -> void:
	_clear_children(menu_content)
	_add_menu_title("PROJECT JOKER", "Локальная карточная партия для четырёх игроков")
	_add_menu_spacer(18.0)
	if _has_saved_session():
		_add_menu_button("Продолжить партию", _on_continue_saved_game_pressed, true)
	_add_menu_button("Новая партия", _show_new_game_setup, true)
	_add_menu_button("Профиль", _show_profile_menu)
	_add_menu_button("Правила", _show_rules_menu)
	_add_menu_button("Настройки", _show_settings_menu)
	_add_menu_button("Выход", _on_quit_pressed)
	_add_menu_spacer(12.0)
	_add_menu_label("32 раздачи: обычные, тёмные, бескозырные, золотые и мизерные.", 14, Color(0.72, 0.85, 0.76, 1.0))


func _show_new_game_setup() -> void:
	is_pause_menu_open = false
	menu_overlay.visible = true
	_clear_children(menu_content)
	new_game_name_inputs.clear()
	new_game_avatar_selectors.clear()
	_add_menu_title("Новая партия", "Укажи имена и выбери символы игроков")
	_add_menu_label("Символы — временные авторские аватары. Позже их можно будет заменить полноценными иллюстрациями.", 14, Color(0.72, 0.85, 0.76, 1.0))

	for player_index in PLAYER_NAMES.size():
		_add_new_game_player_row(player_index)

	_add_menu_spacer(8.0)
	_add_new_game_bot_difficulty_row()
	_add_menu_spacer(8.0)
	_add_menu_button("Начать партию", _start_configured_new_game, true)
	_add_menu_button("Назад", _build_main_menu_content)


func _add_new_game_player_row(player_index: int) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	menu_content.add_child(row)

	var role_label := Label.new()
	role_label.text = "Ты" if player_index == HUMAN_PLAYER_INDEX else "Бот %d" % player_index
	role_label.custom_minimum_size = Vector2(70.0, 38.0)
	role_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	role_label.add_theme_font_size_override("font_size", 16)
	role_label.add_theme_color_override("font_color", Color(0.91, 0.96, 0.91, 1.0))
	row.add_child(role_label)

	var name_input := LineEdit.new()
	name_input.text = configured_player_names[player_index]
	name_input.placeholder_text = "Имя игрока"
	name_input.max_length = 16
	name_input.custom_minimum_size = Vector2(250.0, 38.0)
	name_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_input.add_theme_font_size_override("font_size", 17)
	row.add_child(name_input)
	new_game_name_inputs.append(name_input)

	var avatar_selector := OptionButton.new()
	avatar_selector.custom_minimum_size = Vector2(156.0, 38.0)
	avatar_selector.add_theme_font_size_override("font_size", 16)
	for avatar_index in 4:
		avatar_selector.add_item(_get_avatar_option_label(avatar_index))
	avatar_selector.selected = configured_avatar_indices[player_index]
	row.add_child(avatar_selector)
	new_game_avatar_selectors.append(avatar_selector)


func _add_new_game_bot_difficulty_row() -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	menu_content.add_child(row)

	var label := Label.new()
	label.text = "Уровень ботов"
	label.custom_minimum_size = Vector2(160.0, 38.0)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color(0.91, 0.96, 0.91, 1.0))
	row.add_child(label)

	new_game_bot_difficulty_selector = OptionButton.new()
	new_game_bot_difficulty_selector.custom_minimum_size = Vector2(0.0, 38.0)
	new_game_bot_difficulty_selector.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	new_game_bot_difficulty_selector.add_theme_font_size_override("font_size", 16)
	for difficulty in BotDifficulty.values():
		new_game_bot_difficulty_selector.add_item(_get_bot_difficulty_label(difficulty))
	new_game_bot_difficulty_selector.selected = bot_difficulty
	row.add_child(new_game_bot_difficulty_selector)


func _start_configured_new_game() -> void:
	for player_index in PLAYER_NAMES.size():
		var selected_name: String = new_game_name_inputs[player_index].text.strip_edges()
		configured_player_names[player_index] = selected_name if not selected_name.is_empty() else str(PLAYER_NAMES[player_index])
		configured_avatar_indices[player_index] = new_game_avatar_selectors[player_index].selected

	bot_difficulty = clampi(new_game_bot_difficulty_selector.selected, 0, BOT_DIFFICULTY_COUNT - 1)
	_save_persistent_settings()

	_on_new_game_pressed()


func _get_avatar_option_label(avatar_index: int) -> String:
	match avatar_index:
		0:
			return "Лис"
		1:
			return "Солнце"
		2:
			return "Луна"
		3:
			return "Искра"

	return "Символ"


func _get_bot_difficulty_label(difficulty: BotDifficulty) -> String:
	match difficulty:
		BotDifficulty.EASY:
			return "Лёгкий — простые решения"
		BotDifficulty.NORMAL:
			return "Обычный — сбалансировано"
		BotDifficulty.HARD:
			return "Сложный — расчётливо"

	return "Обычный — сбалансировано"


func _show_profile_menu() -> void:
	menu_overlay.visible = true
	_clear_children(menu_content)
	_add_menu_title("Профиль", "Настрой локальное имя и аватар для следующих партий")
	_add_menu_label("В Steam-версии здесь позже появится возможность использовать имя и аватар профиля Steam.", 14, Color(0.72, 0.85, 0.76, 1.0))
	_add_menu_spacer(10.0)

	var name_label := Label.new()
	name_label.text = "Имя игрока"
	name_label.add_theme_font_size_override("font_size", 17)
	name_label.add_theme_color_override("font_color", Color(0.91, 0.96, 0.91, 1.0))
	menu_content.add_child(name_label)

	profile_name_input = LineEdit.new()
	profile_name_input.text = configured_player_names[HUMAN_PLAYER_INDEX]
	profile_name_input.placeholder_text = "Имя игрока"
	profile_name_input.max_length = 16
	profile_name_input.custom_minimum_size = Vector2(0.0, 42.0)
	profile_name_input.add_theme_font_size_override("font_size", 18)
	menu_content.add_child(profile_name_input)

	var avatar_label := Label.new()
	avatar_label.text = "Аватар"
	avatar_label.add_theme_font_size_override("font_size", 17)
	avatar_label.add_theme_color_override("font_color", Color(0.91, 0.96, 0.91, 1.0))
	menu_content.add_child(avatar_label)

	profile_avatar_selector = OptionButton.new()
	profile_avatar_selector.custom_minimum_size = Vector2(0.0, 42.0)
	profile_avatar_selector.add_theme_font_size_override("font_size", 17)
	for avatar_index in 4:
		profile_avatar_selector.add_item(_get_avatar_option_label(avatar_index))
	profile_avatar_selector.selected = configured_avatar_indices[HUMAN_PLAYER_INDEX]
	menu_content.add_child(profile_avatar_selector)

	_add_menu_label("Загрузка личной картинки появится после подключения файлового выбора; пока аватары можно заменить в папке проекта.", 14, Color(0.72, 0.85, 0.76, 1.0))
	_add_menu_spacer(10.0)
	_add_menu_button("Сохранить профиль", _save_profile, true)
	_add_menu_button("Назад", _return_from_menu_subpage)


func _save_profile() -> void:
	var selected_name: String = profile_name_input.text.strip_edges()
	configured_player_names[HUMAN_PLAYER_INDEX] = selected_name if not selected_name.is_empty() else str(PLAYER_NAMES[HUMAN_PLAYER_INDEX])
	configured_avatar_indices[HUMAN_PLAYER_INDEX] = clampi(profile_avatar_selector.selected, 0, 3)
	_save_persistent_settings()

	if game.current_round.state != Round.State.SETUP:
		game.players[HUMAN_PLAYER_INDEX].display_name = configured_player_names[HUMAN_PLAYER_INDEX]
		_save_current_session()
		_refresh_ui()

	if is_pause_menu_open:
		_build_pause_menu_content()
		return

	_build_main_menu_content()


func _show_rules_menu() -> void:
	menu_overlay.visible = true
	_clear_children(menu_content)
	_add_menu_title("Правила партии", "Краткая памятка — полный документ остаётся в Game Design Document")
	_add_menu_label("• Играют четыре игрока. Сдающий меняется по кругу; в начале выбирается случайно.", 15)
	_add_menu_label("• В обычных, тёмных и бескозырных раздачах игроки заказывают число взяток. Последний заказ не может уравнять сумму заказов с числом карт.", 15)
	_add_menu_label("• В бескозырке точный заказ даёт +15 за взятку, недобор — −10, перебор — +1; заказ 0 и 0 взяток — +5.", 15)
	_add_menu_label("• В золотой и мизерной сериях заказов нет: золотая поощряет взятки, мизерная — избегание взяток.", 15)
	_add_menu_label("• Джокер можно использовать как сильнейшую карту или как сброс; при первом ходе он позволяет объявить масть и условие розыгрыша.", 15)
	_add_menu_label("• При равенстве очков выше место у игрока, который точнее выполнил заказы за всю партию.", 15)
	_add_menu_spacer(8.0)
	_add_menu_button("Назад", _return_from_menu_subpage)


func _show_settings_menu() -> void:
	menu_overlay.visible = true
	_clear_children(menu_content)
	_add_menu_title("Настройки", "Параметры применяются сразу и действуют до закрытия игры")
	_add_menu_spacer(8.0)

	var fullscreen_toggle := CheckButton.new()
	fullscreen_toggle.text = "Полноэкранный режим"
	fullscreen_toggle.button_pressed = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	fullscreen_toggle.add_theme_font_size_override("font_size", 18)
	fullscreen_toggle.add_theme_color_override("font_color", Color(0.91, 0.96, 0.91, 1.0))
	fullscreen_toggle.toggled.connect(_on_fullscreen_toggled)
	menu_content.add_child(fullscreen_toggle)

	var speed_label := Label.new()
	speed_label.text = "Скорость ходов ботов"
	speed_label.add_theme_font_size_override("font_size", 18)
	speed_label.add_theme_color_override("font_color", Color(0.91, 0.96, 0.91, 1.0))
	menu_content.add_child(speed_label)

	var speed_selector := OptionButton.new()
	speed_selector.add_item("Медленно")
	speed_selector.add_item("Обычно")
	speed_selector.add_item("Быстро")
	speed_selector.selected = bot_speed_index
	speed_selector.custom_minimum_size = Vector2(0.0, 42.0)
	speed_selector.add_theme_font_size_override("font_size", 17)
	speed_selector.item_selected.connect(_on_bot_speed_selected)
	menu_content.add_child(speed_selector)

	var sound_label := Label.new()
	sound_label.text = "Громкость звуков"
	sound_label.add_theme_font_size_override("font_size", 18)
	sound_label.add_theme_color_override("font_color", Color(0.91, 0.96, 0.91, 1.0))
	menu_content.add_child(sound_label)

	var sound_selector := OptionButton.new()
	sound_selector.add_item("Без звука")
	sound_selector.add_item("Тихо")
	sound_selector.add_item("Обычно")
	sound_selector.add_item("Громко")
	sound_selector.selected = sound_volume_index
	sound_selector.custom_minimum_size = Vector2(0.0, 42.0)
	sound_selector.add_theme_font_size_override("font_size", 17)
	sound_selector.item_selected.connect(_on_sound_volume_selected)
	menu_content.add_child(sound_selector)

	_add_menu_label("Сейчас доступны короткие процедурные звуки раздачи, хода картой и взятки. Музыка появится отдельным шагом.", 14, Color(0.72, 0.85, 0.76, 1.0))
	_add_menu_spacer(8.0)
	_add_menu_button("Назад", _return_from_menu_subpage)


func _show_final_session_menu() -> void:
	is_pause_menu_open = false
	menu_overlay.visible = true
	_clear_children(menu_content)
	_add_menu_title("Партия завершена", "Поздравляем — полный цикл из 32 раздач сыгран")
	_add_menu_label(_get_final_results_text(), 16, Color(0.91, 0.96, 0.91, 1.0))
	_add_menu_spacer(10.0)
	_add_menu_button("Сыграть ещё раз", _on_new_game_pressed, true)
	_add_menu_button("Вернуться в меню", _on_return_to_menu_pressed)


func _add_menu_title(title_text: String, subtitle_text: String) -> void:
	var title_label := Label.new()
	title_label.text = title_text
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 34)
	title_label.add_theme_color_override("font_color", Color(0.97, 0.86, 0.55, 1.0))
	menu_content.add_child(title_label)

	var subtitle_label := Label.new()
	subtitle_label.text = subtitle_text
	subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle_label.add_theme_font_size_override("font_size", 16)
	subtitle_label.add_theme_color_override("font_color", Color(0.72, 0.85, 0.76, 1.0))
	menu_content.add_child(subtitle_label)


func _add_menu_label(label_text: String, font_size: int, font_color: Color = Color(0.91, 0.96, 0.91, 1.0)) -> void:
	var label := Label.new()
	label.text = label_text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", font_color)
	menu_content.add_child(label)


func _add_menu_spacer(height: float) -> void:
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0.0, height)
	menu_content.add_child(spacer)


func _add_menu_button(label_text: String, callback: Callable, is_primary: bool = false) -> void:
	var button := Button.new()
	button.text = label_text
	button.custom_minimum_size = Vector2(0.0, 48.0)
	button.add_theme_font_size_override("font_size", 19)
	button.add_theme_color_override("font_color", Color(1.0, 0.95, 0.78, 1.0))
	button.add_theme_stylebox_override(
		"normal",
		_create_flat_style(
			Color(0.15, 0.22, 0.1, 1.0) if is_primary else Color(0.04, 0.1, 0.07, 1.0),
			Color(0.95, 0.75, 0.28, 1.0) if is_primary else Color(0.45, 0.29, 0.1, 1.0),
			2,
			10,
			3
		)
	)
	button.add_theme_stylebox_override(
		"hover",
		_create_flat_style(Color(0.22, 0.3, 0.12, 1.0), Color(1.0, 0.82, 0.34, 1.0), 3, 10, 5)
	)
	button.pressed.connect(callback)
	menu_content.add_child(button)


func _on_new_game_pressed() -> void:
	is_pause_menu_open = false
	_delete_saved_session()
	_reset_game_session()
	_hide_main_menu()
	_start_round()


func _on_return_to_menu_pressed() -> void:
	_delete_saved_session()
	_reset_game_session()
	_show_main_menu()


func _on_pause_menu_pressed() -> void:
	if is_processing_automatic_actions:
		return

	is_pause_menu_open = true
	menu_overlay.visible = true
	_build_pause_menu_content()


func _build_pause_menu_content() -> void:
	_clear_children(menu_content)
	_add_menu_title("Пауза", "Текущая локальная партия ждёт твоего решения")
	_add_menu_spacer(18.0)
	_add_menu_button("Продолжить", _resume_current_game, true)
	_add_menu_button("Профиль", _show_profile_menu)
	_add_menu_button("Правила", _show_rules_menu)
	_add_menu_button("Настройки", _show_settings_menu)
	_add_menu_button("Завершить партию", _show_end_session_confirmation)


func _resume_current_game() -> void:
	is_pause_menu_open = false
	_hide_main_menu()
	_refresh_ui()


func _show_end_session_confirmation() -> void:
	_clear_children(menu_content)
	_add_menu_title("Завершить партию?", "Текущая локальная партия будет сброшена")
	_add_menu_label("Вернуться к этой партии после завершения пока нельзя: сохранение незавершённых игр будет добавлено отдельным этапом.", 16)
	_add_menu_spacer(14.0)
	_add_menu_button("Завершить и вернуться в меню", _confirm_end_current_session)
	_add_menu_button("Отмена", _build_pause_menu_content, true)


func _confirm_end_current_session() -> void:
	_delete_saved_session()
	_reset_game_session()
	_show_main_menu()


func _return_from_menu_subpage() -> void:
	if is_pause_menu_open:
		_build_pause_menu_content()
		return

	_build_main_menu_content()


func _on_quit_pressed() -> void:
	get_tree().quit()


func _on_fullscreen_toggled(enabled: bool) -> void:
	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_FULLSCREEN if enabled else DisplayServer.WINDOW_MODE_MAXIMIZED
	)
	_save_persistent_settings()


func _on_bot_speed_selected(selected_index: int) -> void:
	bot_speed_index = clampi(selected_index, 0, BOT_SPEED_COUNT - 1)
	_save_persistent_settings()


func _on_sound_volume_selected(selected_index: int) -> void:
	sound_volume_index = clampi(selected_index, 0, SOUND_VOLUME_COUNT - 1)
	_apply_sound_volume()
	_save_persistent_settings()


func _load_persistent_settings() -> void:
	var config := ConfigFile.new()
	if config.load(PERSISTENT_SETTINGS_PATH) != OK:
		return

	for player_index in PLAYER_NAMES.size():
		var saved_name: String = str(config.get_value("players", "name_%d" % player_index, configured_player_names[player_index])).strip_edges()
		configured_player_names[player_index] = saved_name if not saved_name.is_empty() else str(PLAYER_NAMES[player_index])
		var saved_avatar: int = int(config.get_value("players", "avatar_%d" % player_index, configured_avatar_indices[player_index]))
		configured_avatar_indices[player_index] = clampi(saved_avatar, 0, 3)

	var saved_difficulty: int = int(config.get_value("game", "bot_difficulty", BotDifficulty.NORMAL))
	bot_difficulty = clampi(saved_difficulty, 0, BOT_DIFFICULTY_COUNT - 1)
	var saved_speed: int = int(config.get_value("game", "bot_speed", bot_speed_index))
	bot_speed_index = clampi(saved_speed, 0, BOT_SPEED_COUNT - 1)
	var saved_sound_volume: int = int(config.get_value("audio", "sound_volume", sound_volume_index))
	sound_volume_index = clampi(saved_sound_volume, 0, SOUND_VOLUME_COUNT - 1)

	var fullscreen_enabled: bool = bool(config.get_value("display", "fullscreen", false))
	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen_enabled else DisplayServer.WINDOW_MODE_MAXIMIZED
	)


func _save_persistent_settings() -> void:
	var config := ConfigFile.new()

	for player_index in PLAYER_NAMES.size():
		config.set_value("players", "name_%d" % player_index, configured_player_names[player_index])
		config.set_value("players", "avatar_%d" % player_index, configured_avatar_indices[player_index])

	config.set_value("game", "bot_difficulty", bot_difficulty)
	config.set_value("game", "bot_speed", bot_speed_index)
	config.set_value("audio", "sound_volume", sound_volume_index)
	config.set_value(
		"display",
		"fullscreen",
		DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	)
	config.save(PERSISTENT_SETTINGS_PATH)


func _has_saved_session() -> bool:
	return FileAccess.file_exists(SESSION_SAVE_PATH)


func _save_current_session() -> void:
	if game.current_round.state == Round.State.SETUP or _is_full_game_complete():
		return

	var save_file := FileAccess.open(SESSION_SAVE_PATH, FileAccess.WRITE)
	if save_file == null:
		push_error("Не удалось открыть файл сохранения партии.")
		return

	save_file.store_var(_create_session_save_data(), false)


func _delete_saved_session() -> void:
	if _has_saved_session():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SESSION_SAVE_PATH))


func _create_session_save_data() -> Dictionary:
	var actions: Array[String] = []
	for action in recent_actions:
		actions.append(action)

	return {
		"version": SESSION_SAVE_VERSION,
		"player_names": configured_player_names.duplicate(),
		"avatar_indices": configured_avatar_indices.duplicate(),
		"bot_difficulty": bot_difficulty,
		"game": _serialize_game_state(),
		"normal_round_index": normal_round_index,
		"dark_round_index": dark_round_index,
		"no_trump_round_index": no_trump_round_index,
		"golden_round_index": golden_round_index,
		"misere_round_index": misere_round_index,
		"round_history": round_history.duplicate(true),
		"recent_actions": actions,
		"last_trick_text": last_trick_text,
		"action_text": action_text,
		"hand_sort_mode": hand_sort_mode,
		"score_sheet_visible": is_score_sheet_visible,
		"round_history_visible": is_round_history_visible
	}


func _serialize_game_state() -> Dictionary:
	var player_states: Array[Dictionary] = []

	for player in game.players:
		player_states.append({
			"hand": _serialize_cards(player.hand),
			"bid": player.bid,
			"tricks_taken": player.tricks_taken,
			"total_score": player.total_score,
			"exact_orders_completed": player.exact_orders_completed
		})

	return {
		"players": player_states,
		"deck_cards": _serialize_cards(game.deck.cards),
		"round": {
			"number": game.current_round.number,
			"cards_per_player": game.current_round.cards_per_player,
			"round_type": game.current_round.round_type,
			"trump": game.current_round.trump,
			"dealer_index": game.current_round.dealer_index,
			"player_count": game.current_round.player_count,
			"current_player_index": game.current_round.current_player_index,
			"lead_player_index": game.current_round.lead_player_index,
			"bids": game.current_round.bids.duplicate(),
			"bids_made": game.current_round.bids_made,
			"tricks_played": game.current_round.tricks_played,
			"state": game.current_round.state
		},
		"active_trick": _serialize_active_trick(),
		"trump_card": _serialize_optional_card(game.trump_card),
		"last_completed_trick_cards": _serialize_cards(game.last_completed_trick_cards),
		"last_completed_trick_played_by": game.last_completed_trick_played_by.duplicate(),
		"last_completed_trick_joker_mode": game.last_completed_trick_joker_mode,
		"last_completed_trick_declared_suit": game.last_completed_trick_declared_suit,
		"last_completed_trick_forced_card_rank": game.last_completed_trick_forced_card_rank,
		"dealer_index": game.dealer_index,
		"last_trick_winner_index": game.last_trick_winner_index,
		"round_number": game.round_number,
		"cards_are_dealt": game.cards_are_dealt
	}


func _serialize_active_trick() -> Dictionary:
	if game.active_trick == null:
		return {}

	return {
		"player_count": game.active_trick.player_count,
		"trump": game.active_trick.trump,
		"leader_index": game.active_trick.leader_index,
		"current_player_index": game.active_trick.current_player_index,
		"lead_suit": game.active_trick.lead_suit,
		"joker_mode": game.active_trick.joker_mode,
		"declared_suit": game.active_trick.declared_suit,
		"forced_card_rank": game.active_trick.forced_card_rank,
		"played_cards": _serialize_cards(game.active_trick.played_cards),
		"played_by": game.active_trick.played_by.duplicate()
	}


func _serialize_cards(cards: Array[Card]) -> Array[Dictionary]:
	var serialized_cards: Array[Dictionary] = []

	for card in cards:
		serialized_cards.append(_serialize_card(card))

	return serialized_cards


func _serialize_optional_card(card: Card) -> Dictionary:
	return {} if card == null else _serialize_card(card)


func _serialize_card(card: Card) -> Dictionary:
	return {
		"suit": card.suit,
		"rank": card.rank,
		"is_joker": card.is_joker
	}


func _on_continue_saved_game_pressed() -> void:
	if not _load_saved_session():
		_delete_saved_session()
		_build_main_menu_content()
		return

	is_pause_menu_open = false
	_hide_main_menu()
	_refresh_ui()
	_advance_automatic_actions()


func _load_saved_session() -> bool:
	if not _has_saved_session():
		return false

	var save_file := FileAccess.open(SESSION_SAVE_PATH, FileAccess.READ)
	if save_file == null:
		return false

	var saved_data: Variant = save_file.get_var(false)
	if not (saved_data is Dictionary):
		return false

	var save_data: Dictionary = saved_data
	if int(save_data.get("version", 0)) != SESSION_SAVE_VERSION:
		return false

	var saved_names: Array = save_data.get("player_names", [])
	var saved_avatars: Array = save_data.get("avatar_indices", [])
	var game_data_variant: Variant = save_data.get("game", {})
	if saved_names.size() != PLAYER_NAMES.size() or saved_avatars.size() != PLAYER_NAMES.size() or not (game_data_variant is Dictionary):
		return false

	configured_player_names.clear()
	configured_avatar_indices.clear()
	for player_index in PLAYER_NAMES.size():
		var restored_name: String = str(saved_names[player_index]).strip_edges()
		configured_player_names.append(restored_name if not restored_name.is_empty() else str(PLAYER_NAMES[player_index]))
		configured_avatar_indices.append(clampi(int(saved_avatars[player_index]), 0, 3))

	bot_difficulty = clampi(int(save_data.get("bot_difficulty", BotDifficulty.NORMAL)), 0, BOT_DIFFICULTY_COUNT - 1)
	var restored_game := _deserialize_game_state(game_data_variant, configured_player_names)
	if restored_game == null:
		return false

	game = restored_game
	normal_round_index = int(save_data.get("normal_round_index", 0))
	dark_round_index = int(save_data.get("dark_round_index", -1))
	no_trump_round_index = int(save_data.get("no_trump_round_index", -1))
	golden_round_index = int(save_data.get("golden_round_index", -1))
	misere_round_index = int(save_data.get("misere_round_index", -1))
	last_trick_text = str(save_data.get("last_trick_text", "Взятка ещё не началась"))
	action_text = str(save_data.get("action_text", "Партия продолжена."))
	hand_sort_mode = clampi(int(save_data.get("hand_sort_mode", HandSortMode.BY_SUIT)), HandSortMode.BY_SUIT, HandSortMode.TRUMPS_LEFT)
	is_score_sheet_visible = bool(save_data.get("score_sheet_visible", false))
	is_round_history_visible = bool(save_data.get("round_history_visible", true))

	round_history.clear()
	var saved_round_history: Array = save_data.get("round_history", [])
	for record in saved_round_history:
		if record is Dictionary:
			round_history.append(record)

	recent_actions.clear()
	var saved_actions: Array = save_data.get("recent_actions", [])
	for saved_action in saved_actions:
		recent_actions.append(str(saved_action))

	is_processing_automatic_actions = false
	test_checkpoints.clear()
	pending_test_checkpoint.clear()
	pending_joker_card = null
	pending_joker_suit = -1
	_reset_trick_presentation()
	_restore_next_round_button()
	_save_persistent_settings()
	return true


func _deserialize_game_state(game_data: Dictionary, player_names: Array[String]) -> Game:
	var player_states: Array = game_data.get("players", [])
	var round_data_variant: Variant = game_data.get("round", {})
	if player_states.size() != PLAYER_NAMES.size() or not (round_data_variant is Dictionary):
		return null

	var restored_game := Game.new(player_names)
	var restored_player_states: Array[Dictionary] = []
	for player_state_variant in player_states:
		if not (player_state_variant is Dictionary):
			return null
		var player_state: Dictionary = player_state_variant
		var hand_data: Array = player_state.get("hand", [])
		restored_player_states.append({
			"hand": _deserialize_cards(hand_data),
			"bid": int(player_state.get("bid", -1)),
			"tricks_taken": int(player_state.get("tricks_taken", 0)),
			"total_score": int(player_state.get("total_score", 0)),
			"exact_orders_completed": int(player_state.get("exact_orders_completed", 0))
		})

	var round_data: Dictionary = round_data_variant
	var active_trick_data: Dictionary = game_data.get("active_trick", {})
	var trump_card_data: Dictionary = game_data.get("trump_card", {})
	var deck_cards_data: Array = game_data.get("deck_cards", [])
	var last_cards_data: Array = game_data.get("last_completed_trick_cards", [])
	var played_by_data: Array = game_data.get("last_completed_trick_played_by", [])
	var bids_data: Array = round_data.get("bids", [])

	restored_game.restore_snapshot({
		"players": restored_player_states,
		"deck_cards": _deserialize_cards(deck_cards_data),
		"round": {
			"number": int(round_data.get("number", 0)),
			"cards_per_player": int(round_data.get("cards_per_player", 0)),
			"round_type": int(round_data.get("round_type", Round.RoundType.NORMAL)),
			"trump": int(round_data.get("trump", Round.TrumpSuit.NONE)),
			"dealer_index": int(round_data.get("dealer_index", -1)),
			"player_count": int(round_data.get("player_count", PLAYER_NAMES.size())),
			"current_player_index": int(round_data.get("current_player_index", -1)),
			"lead_player_index": int(round_data.get("lead_player_index", -1)),
			"bids": bids_data,
			"bids_made": int(round_data.get("bids_made", 0)),
			"tricks_played": int(round_data.get("tricks_played", 0)),
			"state": int(round_data.get("state", Round.State.SETUP))
		},
		"active_trick": _deserialize_active_trick(active_trick_data),
		"trump_card": _deserialize_optional_card(trump_card_data),
		"last_completed_trick_cards": _deserialize_cards(last_cards_data),
		"last_completed_trick_played_by": played_by_data,
		"last_completed_trick_joker_mode": int(game_data.get("last_completed_trick_joker_mode", Trick.JokerMode.NONE)),
		"last_completed_trick_declared_suit": int(game_data.get("last_completed_trick_declared_suit", -1)),
		"last_completed_trick_forced_card_rank": int(game_data.get("last_completed_trick_forced_card_rank", Trick.ForcedCardRank.NONE)),
		"dealer_index": int(game_data.get("dealer_index", -1)),
		"last_trick_winner_index": int(game_data.get("last_trick_winner_index", -1)),
		"round_number": int(game_data.get("round_number", 0)),
		"cards_are_dealt": bool(game_data.get("cards_are_dealt", false))
	})

	return restored_game


func _deserialize_active_trick(trick_data: Dictionary) -> Dictionary:
	if trick_data.is_empty():
		return {}

	var played_cards_data: Array = trick_data.get("played_cards", [])
	var played_by_data: Array = trick_data.get("played_by", [])
	return {
		"player_count": int(trick_data.get("player_count", PLAYER_NAMES.size())),
		"trump": int(trick_data.get("trump", Round.TrumpSuit.NONE)),
		"leader_index": int(trick_data.get("leader_index", -1)),
		"current_player_index": int(trick_data.get("current_player_index", -1)),
		"lead_suit": int(trick_data.get("lead_suit", -1)),
		"joker_mode": int(trick_data.get("joker_mode", Trick.JokerMode.NONE)),
		"declared_suit": int(trick_data.get("declared_suit", -1)),
		"forced_card_rank": int(trick_data.get("forced_card_rank", Trick.ForcedCardRank.NONE)),
		"played_cards": _deserialize_cards(played_cards_data),
		"played_by": played_by_data
	}


func _deserialize_cards(cards_data: Array) -> Array[Card]:
	var cards: Array[Card] = []

	for card_data_variant in cards_data:
		if not (card_data_variant is Dictionary):
			continue
		var card: Card = _deserialize_card(card_data_variant)
		if card != null:
			cards.append(card)

	return cards


func _deserialize_optional_card(card_data: Dictionary) -> Card:
	return null if card_data.is_empty() else _deserialize_card(card_data)


func _deserialize_card(card_data: Dictionary) -> Card:
	var card := Card.new()
	card.suit = clampi(int(card_data.get("suit", Card.Suit.CLUBS)), Card.Suit.CLUBS, Card.Suit.DIAMONDS)
	card.rank = clampi(int(card_data.get("rank", Card.Rank.SIX)), Card.Rank.SIX, Card.Rank.ACE)
	card.is_joker = bool(card_data.get("is_joker", false))
	return card


func _restore_next_round_button() -> void:
	var round_is_finished := game.current_round.state == Round.State.FINISHED
	next_round_button.visible = round_is_finished
	next_round_button.disabled = false

	if not round_is_finished:
		return

	if _is_full_game_complete():
		next_round_button.text = "Партия завершена"
		next_round_button.disabled = true
	elif _is_normal_round() and normal_round_index >= NORMAL_ROUND_COUNT - 1:
		next_round_button.text = "Начать тёмную серию"
	elif _is_dark_round() and dark_round_index >= DARK_ROUND_COUNT - 1:
		next_round_button.text = "Начать бескозырную серию"
	elif _is_no_trump_round() and no_trump_round_index >= NO_TRUMP_ROUND_COUNT - 1:
		next_round_button.text = "Начать золотую серию"
	elif _is_golden_round() and golden_round_index >= GOLDEN_ROUND_COUNT - 1:
		next_round_button.text = "Начать мизерную серию"
	else:
		next_round_button.text = "Следующая раздача"


func _get_bot_action_delay() -> float:
	match bot_speed_index:
		0:
			return 0.75
		2:
			return 0.2

	return 0.45


func _create_sound_players() -> void:
	sound_streams[SoundEffect.DEAL] = _create_procedural_sound(310.0, 210.0, 0.09, 0.32, 0.22)
	sound_streams[SoundEffect.CARD] = _create_procedural_sound(540.0, 360.0, 0.06, 0.24, 0.12)
	sound_streams[SoundEffect.TRICK] = _create_procedural_sound(420.0, 720.0, 0.18, 0.34, 0.3)

	for player_number in 3:
		var player := AudioStreamPlayer.new()
		player.name = "SoundEffectPlayer%d" % player_number
		player.bus = &"Master"
		add_child(player)
		sound_players.append(player)

	_apply_sound_volume()


func _create_procedural_sound(
	start_frequency: float,
	end_frequency: float,
	duration: float,
	amplitude: float,
	overtone_mix: float
) -> AudioStreamWAV:
	var mix_rate := 22050
	var sample_count: int = maxi(1, roundi(duration * mix_rate))
	var data := PackedByteArray()
	data.resize(sample_count * 2)
	var phase := 0.0

	for sample_index in sample_count:
		var progress: float = float(sample_index) / float(sample_count)
		var frequency := lerpf(start_frequency, end_frequency, progress)
		phase = fposmod(phase + frequency / float(mix_rate), 1.0)
		var tone := sin(phase * TAU)
		var overtone := sin(phase * TAU * 2.03)
		var attack := minf(progress / 0.012, 1.0)
		var release := pow(maxf(0.0, 1.0 - progress), 1.7)
		var sample: float = (tone + overtone * overtone_mix) * attack * release * amplitude
		var sample_value: int = clampi(roundi(sample * 32767.0), -32767, 32767)
		var unsigned_sample: int = sample_value if sample_value >= 0 else sample_value + 65536
		data[sample_index * 2] = unsigned_sample & 0xff
		data[sample_index * 2 + 1] = (unsigned_sample >> 8) & 0xff

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = mix_rate
	stream.stereo = false
	stream.data = data
	return stream


func _play_sound(effect: SoundEffect) -> void:
	if sound_volume_index == 0 or not sound_streams.has(effect):
		return

	var sound_player := _get_available_sound_player()
	if sound_player == null:
		return

	var stream: AudioStream = sound_streams[effect] as AudioStream
	if stream == null:
		return

	sound_player.stream = stream
	sound_player.play()


func _get_available_sound_player() -> AudioStreamPlayer:
	for player in sound_players:
		if not player.playing:
			return player

	if sound_players.is_empty():
		return null

	var player := sound_players[next_sound_player_index]
	next_sound_player_index = (next_sound_player_index + 1) % sound_players.size()
	return player


func _apply_sound_volume() -> void:
	var volume_db := _get_sound_volume_db()

	for player in sound_players:
		player.volume_db = volume_db


func _get_sound_volume_db() -> float:
	match sound_volume_index:
		0:
			return -80.0
		1:
			return -24.0
		2:
			return -15.0
		3:
			return -8.0

	return -15.0


func _reset_game_session() -> void:
	game = Game.new(configured_player_names)
	normal_round_index = 0
	dark_round_index = -1
	no_trump_round_index = -1
	golden_round_index = -1
	misere_round_index = -1
	is_processing_automatic_actions = false
	is_score_sheet_visible = false
	is_round_history_visible = true
	hand_sort_mode = HandSortMode.BY_SUIT
	round_history.clear()
	recent_actions.clear()
	test_checkpoints.clear()
	pending_test_checkpoint.clear()
	pending_joker_card = null
	pending_joker_suit = -1
	_reset_trick_presentation()


func _start_round() -> void:
	_reset_trick_presentation()
	pending_joker_card = null
	pending_joker_suit = -1
	last_trick_text = "Взятка ещё не началась"
	recent_actions.clear()
	test_checkpoints.clear()
	pending_test_checkpoint.clear()

	var cards_per_player := _get_cards_per_player_for_current_round()
	var trump := _get_trump_for_current_round()
	var round_type := _get_current_round_type()

	if not game.start_round(cards_per_player, round_type, trump, not _is_dark_round()):
		action_text = "Не удалось начать раздачу."
		_refresh_ui()
		return

	_play_sound(SoundEffect.DEAL)

	if _is_misere_round():
		action_text = "Мизерная раздача %d из %d. Заказов нет; сдающий: %s." % [
			misere_round_index + 1,
			MISERE_ROUND_COUNT,
			game.players[game.dealer_index].display_name
		]
	elif _is_golden_round():
		action_text = "Золотая раздача %d из %d. Заказов нет; сдающий: %s." % [
			golden_round_index + 1,
			GOLDEN_ROUND_COUNT,
			game.players[game.dealer_index].display_name
		]
	elif _is_no_trump_round():
		action_text = "Бескозырка %d из %d. Сдающий: %s." % [
			no_trump_round_index + 1,
			NO_TRUMP_ROUND_COUNT,
			game.players[game.dealer_index].display_name
		]
	elif _is_dark_round():
		action_text = "Тёмная раздача %d из %d. Заказ вслепую; сдающий: %s." % [
			dark_round_index + 1,
			DARK_ROUND_COUNT,
			game.players[game.dealer_index].display_name
		]
	else:
		action_text = "Обычная раздача %d из %d. Сдающий: %s." % [
			normal_round_index + 1,
			NORMAL_ROUND_COUNT,
			game.players[game.dealer_index].display_name
		]
	_add_history(action_text)
	next_round_button.visible = false
	next_round_button.disabled = false
	_refresh_ui()
	_save_current_session()
	_advance_automatic_actions()


func _advance_automatic_actions() -> void:
	if is_processing_automatic_actions:
		return

	is_processing_automatic_actions = true

	while true:
		if pending_play_presentation:
			is_trick_presentation_active = true
			_refresh_ui()
			await _present_pending_play()
			is_trick_presentation_active = false
			continue

		if game.current_round.state == Round.State.BIDDING:
			if game.current_round.current_player_index == HUMAN_PLAYER_INDEX:
				_prepare_test_checkpoint()
				if _is_dark_round():
					action_text = "Тёмная: закажи число взяток вслепую."
				elif _is_no_trump_round():
					action_text = "Бескозырка: выбери число взяток."
				else:
					action_text = "Твой заказ: выбери число взяток."
				is_processing_automatic_actions = false
				_refresh_ui()
				return

			if not _play_automatic_bid():
				is_processing_automatic_actions = false
				_refresh_ui()
				return

			_refresh_ui()
			await get_tree().create_timer(_get_bot_action_delay()).timeout
			continue

		if game.current_round.state == Round.State.PLAYING:
			if game.is_round_complete():
				_finish_round()
				is_processing_automatic_actions = false
				return

			if _get_current_player_index() == HUMAN_PLAYER_INDEX:
				_prepare_test_checkpoint()
				action_text = "Твой ход: выбери допустимую карту."
				is_processing_automatic_actions = false
				_refresh_ui()
				return

			await get_tree().create_timer(_get_bot_action_delay()).timeout

			if not _play_automatic_card():
				is_processing_automatic_actions = false
				_refresh_ui()
				return

			continue

		_refresh_ui()
		is_processing_automatic_actions = false
		return


func _play_automatic_bid() -> bool:
	var player_index := game.current_round.current_player_index
	var bid := _choose_automatic_bid(player_index)
	var cards_were_hidden := _is_dark_round() and not game.cards_are_dealt

	if not game.place_bid(player_index, bid):
		action_text = "Ошибка автоматического заказа."
		return false

	action_text = "%s заказывает %d." % [game.players[player_index].display_name, bid]
	_add_history(action_text)
	_announce_dark_cards_dealt(cards_were_hidden)
	_save_current_session()
	return true


func _play_automatic_card() -> bool:
	var player_index := _get_current_player_index()
	var player := game.players[player_index]
	var card := _choose_automatic_card(player)

	if card == null:
		action_text = "Автоматический игрок не нашёл допустимую карту."
		return false

	var played_successfully := false
	var is_leading_joker := card.is_joker and game.active_trick == null
	var joker_mode: Trick.JokerMode = Trick.JokerMode.NONE
	var declared_suit := -1

	if card.is_joker:
		joker_mode = _choose_automatic_joker_mode(player)
		declared_suit = _choose_automatic_joker_suit(player, joker_mode == Trick.JokerMode.NORMAL_CARD_WINS)
		played_successfully = game.play_card(
			player_index,
			card,
			joker_mode,
			declared_suit
		)
	else:
		played_successfully = game.play_card(player_index, card)

	if not played_successfully:
		action_text = "Недопустимый автоматический ход."
		return false

	_record_play(player.display_name, card, player_index)
	if card.is_joker:
		_add_history(_get_joker_rule_text(joker_mode, declared_suit, Trick.ForcedCardRank.NONE, is_leading_joker))
	_save_current_session()
	return true


func _on_bid_pressed(bid: int) -> void:
	var cards_were_hidden := _is_dark_round() and not game.cards_are_dealt

	if not game.current_round.can_place_bid(HUMAN_PLAYER_INDEX, bid):
		action_text = "Этот заказ сейчас недоступен."
		_refresh_ui()
		return

	_commit_test_checkpoint()
	if not game.place_bid(HUMAN_PLAYER_INDEX, bid):
		action_text = "Этот заказ сейчас недоступен."
		_refresh_ui()
		return

	action_text = "Ты заказываешь %d." % bid
	_add_history(action_text)
	_announce_dark_cards_dealt(cards_were_hidden)
	_save_current_session()
	_refresh_ui()
	_advance_automatic_actions()


func _on_card_pressed(card: Card) -> void:
	if not _is_human_turn() or not _is_card_available_to_human(card):
		return

	if card.is_joker:
		pending_joker_card = card
		pending_joker_suit = -1
		action_text = "Выбери условие для Джокера."
		_refresh_ui()
		return

	_commit_test_checkpoint()
	if not game.play_card(HUMAN_PLAYER_INDEX, card):
		action_text = "Эту карту сейчас играть нельзя."
		_refresh_ui()
		return

	_record_play("Ты", card, HUMAN_PLAYER_INDEX)
	_save_current_session()
	_advance_automatic_actions()


func _on_joker_suit_pressed(suit: int) -> void:
	if pending_joker_card == null or game.active_trick != null:
		return

	pending_joker_suit = suit
	action_text = "Выбери условие для %s." % _get_suit_symbol(suit)
	_refresh_ui()


func _on_joker_choice(
	mode: Trick.JokerMode,
	declared_suit: int = -1,
	forced_card_rank: Trick.ForcedCardRank = Trick.ForcedCardRank.NONE
) -> void:
	if pending_joker_card == null:
		return

	var is_leading_joker := game.active_trick == null

	_commit_test_checkpoint()
	if not game.play_card(HUMAN_PLAYER_INDEX, pending_joker_card, mode, declared_suit, forced_card_rank):
		action_text = "Условие Джокера не удалось применить."
		pending_joker_card = null
		pending_joker_suit = -1
		_refresh_ui()
		return

	_record_play("Ты", pending_joker_card, HUMAN_PLAYER_INDEX)
	_add_history(_get_joker_rule_text(mode, declared_suit, forced_card_rank, is_leading_joker))
	pending_joker_card = null
	pending_joker_suit = -1
	_save_current_session()
	_advance_automatic_actions()


func _on_undo_pressed() -> void:
	if is_processing_automatic_actions or test_checkpoints.is_empty():
		return

	var checkpoint: Dictionary = test_checkpoints.pop_back()
	game.restore_snapshot(checkpoint["game"])
	_reset_trick_presentation()
	pending_joker_card = null
	pending_joker_suit = -1
	last_trick_text = checkpoint["last_trick_text"]
	action_text = "Тест: возвращено к началу прошлого твоего решения."
	recent_actions = checkpoint["recent_actions"].duplicate()
	pending_test_checkpoint = _create_test_checkpoint()
	_save_current_session()
	_refresh_ui()


func _on_score_sheet_toggle_pressed() -> void:
	if is_processing_automatic_actions:
		return

	is_score_sheet_visible = not is_score_sheet_visible
	_save_current_session()
	_refresh_ui()


func _on_round_history_toggle_pressed() -> void:
	if is_processing_automatic_actions:
		return

	is_round_history_visible = not is_round_history_visible
	_save_current_session()
	_refresh_ui()


func _on_hand_sort_by_suit_pressed() -> void:
	if is_processing_automatic_actions:
		return

	hand_sort_mode = HandSortMode.BY_SUIT
	_save_current_session()
	_refresh_ui()


func _on_hand_sort_trumps_left_pressed() -> void:
	if is_processing_automatic_actions:
		return

	hand_sort_mode = HandSortMode.TRUMPS_LEFT
	_save_current_session()
	_refresh_ui()


func _on_next_round_pressed() -> void:
	if not _can_start_next_round():
		return

	game.advance_dealer()

	if normal_round_index < NORMAL_ROUND_COUNT - 1:
		normal_round_index += 1
	elif dark_round_index < 0:
		dark_round_index = 0
	elif dark_round_index < DARK_ROUND_COUNT - 1:
		dark_round_index += 1
	elif no_trump_round_index < 0:
		no_trump_round_index = 0
	elif no_trump_round_index < NO_TRUMP_ROUND_COUNT - 1:
		no_trump_round_index += 1
	elif golden_round_index < 0:
		golden_round_index = 0
	elif golden_round_index < GOLDEN_ROUND_COUNT - 1:
		golden_round_index += 1
	elif misere_round_index < 0:
		misere_round_index = 0
	elif misere_round_index < MISERE_ROUND_COUNT - 1:
		misere_round_index += 1
	else:
		return

	_start_round()


func _finish_round() -> void:
	var round_scores := game.finish_round()

	if round_scores.is_empty():
		action_text = "Не удалось завершить раздачу."
		_refresh_ui()
		return

	_record_completed_round(round_scores)

	var result_lines := PackedStringArray()

	for player_index in game.players.size():
		var player := game.players[player_index]

		if _round_uses_bids():
			result_lines.append("%s: заказ %d, взято %d, очки %d" % [
				player.display_name,
				player.bid,
				player.tricks_taken,
				round_scores[player_index]
			])
		else:
			result_lines.append("%s: взято %d, очки %d" % [
				player.display_name,
				player.tricks_taken,
				round_scores[player_index]
			])

	action_text = "Раздача завершена.\n%s" % "\n".join(result_lines)
	next_round_button.visible = true

	if _is_normal_round() and normal_round_index >= NORMAL_ROUND_COUNT - 1:
		next_round_button.text = "Начать тёмную серию"
		next_round_button.disabled = false
		_add_history("Обычная серия из 13 раздач завершена. Далее — тёмные раздачи.")
	elif _is_dark_round() and dark_round_index >= DARK_ROUND_COUNT - 1:
		next_round_button.text = "Начать бескозырную серию"
		next_round_button.disabled = false
		_add_history("Тёмная серия из 5 раздач завершена. Далее — бескозырка.")
	elif _is_no_trump_round() and no_trump_round_index >= NO_TRUMP_ROUND_COUNT - 1:
		next_round_button.text = "Начать золотую серию"
		next_round_button.disabled = false
		_add_history("Бескозырная серия из 4 раздач завершена. Далее — золотые раздачи.")
	elif _is_golden_round() and golden_round_index >= GOLDEN_ROUND_COUNT - 1:
		next_round_button.text = "Начать мизерную серию"
		next_round_button.disabled = false
		_add_history("Золотая серия из 5 раздач завершена. Далее — мизерные раздачи.")
	elif _is_misere_round() and misere_round_index >= MISERE_ROUND_COUNT - 1:
		next_round_button.text = "Партия завершена"
		next_round_button.disabled = true
		_add_history("Мизерная серия из 5 раздач завершена. Полный локальный цикл партии сыгран.")
		is_score_sheet_visible = true
		action_text += "\nИтоговые места открыты в расписке."
	else:
		next_round_button.text = "Следующая раздача"
		_add_history("Раздача завершена. Следующим сдаёт %s." % game.players[(game.dealer_index + 1) % game.players.size()].display_name)

	_refresh_ui()

	if _is_full_game_complete():
		_delete_saved_session()
		_show_final_session_menu()
	else:
		_save_current_session()


func _record_play(player_name: String, card: Card, player_index: int) -> void:
	_add_history("%s сыграл %s." % [player_name, card.get_card_name()])
	_play_sound(SoundEffect.CARD)
	pending_play_presentation = true
	pending_card_animation_player_index = player_index
	pending_trick_winner_player_index = -1

	if game.active_trick == null:
		pending_trick_winner_player_index = game.last_trick_winner_index
		last_trick_text = "%s сыграл %s. Взятку забирает %s." % [
			player_name,
			card.get_card_name(),
			game.players[game.last_trick_winner_index].display_name
		]
		_add_history("Взятку забирает %s." % game.players[game.last_trick_winner_index].display_name)
	else:
		last_trick_text = _get_active_trick_text()


func _present_pending_play() -> void:
	var card_player_index: int = pending_card_animation_player_index
	var winner_player_index: int = pending_trick_winner_player_index
	pending_play_presentation = false
	pending_card_animation_player_index = -1
	pending_trick_winner_player_index = -1

	await _animate_played_card(card_player_index)

	if winner_player_index < 0:
		return

	_play_sound(SoundEffect.TRICK)
	_set_trick_winner_highlight(winner_player_index, true)
	action_text = "Взятку забирает %s." % game.players[winner_player_index].display_name
	action_label.text = action_text
	await get_tree().create_timer(TRICK_WINNER_HOLD_DURATION).timeout
	_set_trick_winner_highlight(winner_player_index, false)


func _animate_played_card(player_index: int) -> void:
	if player_index < 0 or player_index >= trick_card_views.size():
		return

	var card_view := trick_card_views[player_index]
	if not card_view.visible:
		return

	card_view.pivot_offset = card_view.size * 0.5
	card_view.scale = Vector2(0.76, 0.76)
	card_view.modulate = Color(1.0, 1.0, 1.0, 0.0)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(card_view, "scale", Vector2.ONE, CARD_APPEAR_DURATION).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(card_view, "modulate", Color.WHITE, CARD_APPEAR_DURATION)
	await tween.finished


func _set_trick_winner_highlight(player_index: int, highlighted: bool) -> void:
	if player_index < 0 or player_index >= trick_card_views.size():
		return

	trick_card_views[player_index].set_winner_highlight(highlighted)


func _reset_trick_presentation() -> void:
	is_trick_presentation_active = false
	pending_play_presentation = false
	pending_card_animation_player_index = -1
	pending_trick_winner_player_index = -1

	for card_view in trick_card_views:
		card_view.set_winner_highlight(false)
		card_view.scale = Vector2.ONE
		card_view.modulate = Color.WHITE


func _refresh_ui() -> void:
	_refresh_header()
	_refresh_deck_visual()
	_refresh_player_panels()
	_refresh_table()
	_refresh_history()
	_refresh_round_history_panel()
	_refresh_round_results()
	_refresh_bid_controls()
	_refresh_joker_controls()
	_refresh_hand_sort_controls()
	_refresh_hand()
	_refresh_undo_button()
	_refresh_score_sheet()


func _refresh_header() -> void:
	match game.current_round.state:
		Round.State.BIDDING:
			phase_label.text = _get_phase_text("заказ вслепую" if _is_dark_round() else "заказ взяток")
		Round.State.PLAYING:
			phase_label.text = _get_phase_text("розыгрыш взяток")
		Round.State.FINISHED:
			phase_label.text = _get_phase_text("завершена")
		_:
			phase_label.text = "Этап: подготовка"

	if _is_misere_round():
		trump_label.text = _get_special_trump_text("Мизерная")
	elif _is_golden_round():
		trump_label.text = _get_special_trump_text("Золотая")
	elif _is_no_trump_round():
		trump_label.text = "Бескозырка: козырей нет"
	elif _is_dark_round() and not game.cards_are_dealt:
		trump_label.text = "Тёмная: козырь %s · карты скрыты до завершения заказов" % game.current_round.get_trump_name()
	elif game.trump_card == null:
		trump_label.text = "Козырь: %s (задан)" % game.current_round.get_trump_name()
	elif game.trump_card.is_joker:
		trump_label.text = "Открыта %s (бескозырка)" % game.trump_card.get_card_name()
	else:
		trump_label.text = "Открыта %s · козырь %s" % [
			game.trump_card.get_card_name(),
			game.current_round.get_trump_name()
		]
	var should_show_action_label := (
		game.current_round.state == Round.State.PLAYING
		and pending_joker_card == null
		and (
			_get_current_player_index() == HUMAN_PLAYER_INDEX
			or is_trick_presentation_active
		)
	)
	action_label.visible = should_show_action_label
	action_label.text = action_text
	pause_menu_button.disabled = is_processing_automatic_actions


func _refresh_player_panels() -> void:
	for player_index in game.players.size():
		var player := game.players[player_index]
		var is_current := (
			not is_trick_presentation_active
			and _get_current_player_index() == player_index
			and game.current_round.state != Round.State.FINISHED
		)
		var marker := "Ход · " if is_current else ""
		var person_label := " (ты)" if player_index == HUMAN_PLAYER_INDEX else ""
		var hand_text := "скрыто" if _is_dark_round() and not game.cards_are_dealt else str(player.hand.size())
		player_panels[player_index].add_theme_stylebox_override("panel", _get_player_panel_style(player_index, is_current))
		player_labels[player_index].text = "%s%s%s" % [marker, player.display_name, person_label]

		if _round_uses_bids():
			var bid_text := "—" if player.bid < 0 else str(player.bid)
			player_stats_labels[player_index].text = "Карт: %s | Заказ: %s\nВзято: %d | Очки: %d" % [
				hand_text,
				bid_text,
				player.tricks_taken,
				player.total_score
			]
		else:
			player_stats_labels[player_index].text = "Карт: %s\nВзято: %d | Очки: %d" % [
				hand_text,
				player.tricks_taken,
				player.total_score
			]

	_refresh_bot_card_backs()
	_refresh_player_avatar_badges()
	_refresh_table_markers()


func _get_player_panel_style(player_index: int, is_current: bool) -> StyleBoxFlat:
	if player_index == HUMAN_PLAYER_INDEX:
		return active_human_player_panel_style if is_current else human_player_panel_style

	return active_player_panel_style if is_current else player_panel_style


func _get_player_avatar_symbol(player_index: int) -> String:
	if player_index < 0 or player_index >= configured_avatar_indices.size():
		return "•"

	match configured_avatar_indices[player_index]:
		0:
			return "★"
		1:
			return "☀"
		2:
			return "☾"
		3:
			return "✦"

	return "•"


func _get_player_avatar_texture_path(player_index: int) -> String:
	var avatar_index := configured_avatar_indices[player_index] if player_index >= 0 and player_index < configured_avatar_indices.size() else 0

	match avatar_index:
		0:
			return "res://Assets/Avatars/avatar_fox.png"
		1:
			return "res://Assets/Avatars/avatar_sun.png"
		2:
			return "res://Assets/Avatars/avatar_moon.png"
		3:
			return "res://Assets/Avatars/avatar_spark.png"

	return ""


func _create_player_avatar_badges() -> void:
	for player_index in PLAYER_NAMES.size():
		var badge := PanelContainer.new()
		badge.tooltip_text = "Аватар игрока"
		badge.add_theme_stylebox_override("panel", avatar_badge_style)
		_place_player_avatar_badge(badge, player_index)

		var avatar_content := Control.new()
		avatar_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
		badge.add_child(avatar_content)

		var avatar_image := TextureRect.new()
		avatar_image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		avatar_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		avatar_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		avatar_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
		avatar_content.add_child(avatar_image)

		var avatar_label := Label.new()
		avatar_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		avatar_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		avatar_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		avatar_label.add_theme_font_size_override("font_size", 22)
		avatar_label.add_theme_color_override("font_color", Color(0.98, 0.9, 0.6, 1.0))
		avatar_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		avatar_content.add_child(avatar_label)
		players_container.add_child(badge)
		avatar_badges.append(badge)
		avatar_images.append(avatar_image)
		avatar_labels.append(avatar_label)


func _refresh_player_avatar_badges() -> void:
	for player_index in avatar_badges.size():
		avatar_badges[player_index].tooltip_text = "Аватар: %s" % game.players[player_index].display_name
		var avatar_texture: Texture2D = ResourceLoader.load(_get_player_avatar_texture_path(player_index), "Texture2D") as Texture2D
		avatar_images[player_index].texture = avatar_texture
		avatar_labels[player_index].visible = avatar_texture == null
		avatar_labels[player_index].text = _get_player_avatar_symbol(player_index)


func _place_player_avatar_badge(badge: PanelContainer, player_index: int) -> void:
	match player_index:
		HUMAN_PLAYER_INDEX:
			_set_control_layout(badge, 0.5, 1.0, 0.5, 1.0, 182.0, -390.0, 246.0, -326.0)
		1:
			_set_control_layout(badge, 0.0, 0.0, 0.0, 0.0, 620.0, 366.0, 684.0, 430.0)
		2:
			_set_control_layout(badge, 0.5, 0.0, 0.5, 0.0, -244.0, 90.0, -180.0, 154.0)
		3:
			_set_control_layout(badge, 1.0, 0.0, 1.0, 0.0, -684.0, 366.0, -620.0, 430.0)


func _refresh_table() -> void:
	var table_title := ""

	if game.active_trick == null:
		table_title = "Последняя взятка" if not game.last_completed_trick_cards.is_empty() else "Взятка ещё не началась"
	else:
		table_title = "Текущая взятка"
		var declaration_text := _get_active_joker_declaration_text()
		if not declaration_text.is_empty():
			table_title += "\n%s" % declaration_text

	table_label.text = table_title

	var cards_by_player: Array[Card] = []
	cards_by_player.resize(game.players.size())

	var played_cards: Array[Card] = []
	var played_by: Array[int] = []

	if game.active_trick == null:
		played_cards = game.last_completed_trick_cards
		played_by = game.last_completed_trick_played_by
	else:
		played_cards = game.active_trick.played_cards
		played_by = game.active_trick.played_by

	for card_index in played_cards.size():
		cards_by_player[played_by[card_index]] = played_cards[card_index]

	for player_index in game.players.size():
		var card := cards_by_player[player_index]
		var card_view := trick_card_views[player_index]
		card_view.visible = card != null
		if card == null:
			continue

		card_view.set_card(card)
		card_view.set_status(_get_trick_card_status(card, played_cards, played_by, player_index))


func _get_trick_card_status(
	card: Card,
	played_cards: Array[Card],
	played_by: Array[int],
	player_index: int
) -> String:
	if not card.is_joker:
		return ""

	var is_leading_joker := (
		not played_cards.is_empty()
		and played_cards[0].is_joker
		and played_by[0] == player_index
	)
	var joker_mode := _get_displayed_joker_mode()
	if not is_leading_joker:
		return "ЗАБИРАЕТ" if joker_mode == Trick.JokerMode.JOKER_WINS else "НЕ БЕРЁТ"

	var declared_suit := _get_displayed_joker_declared_suit()
	var forced_card_rank := _get_displayed_joker_forced_card_rank()
	var suit_symbol := _get_suit_symbol(declared_suit)

	if forced_card_rank == Trick.ForcedCardRank.HIGHEST:
		return "%s · СТАРШАЯ" % suit_symbol
	if forced_card_rank == Trick.ForcedCardRank.LOWEST:
		return "%s · МЛАДШАЯ" % suit_symbol
	if joker_mode == Trick.JokerMode.JOKER_WINS:
		return "%s · БЕРЁТ" % suit_symbol
	if joker_mode == Trick.JokerMode.HIGHEST_DECLARED_CARD_WINS:
		return "%s · СТАРШАЯ" % suit_symbol
	if joker_mode == Trick.JokerMode.LOWEST_DECLARED_CARD_WINS:
		return "%s · МЛАДШАЯ" % suit_symbol

	return "%s · НЕ БЕРЁТ" % suit_symbol


func _get_displayed_joker_mode() -> Trick.JokerMode:
	if game.active_trick != null:
		return game.active_trick.joker_mode

	return game.last_completed_trick_joker_mode


func _get_displayed_joker_declared_suit() -> int:
	if game.active_trick != null:
		return game.active_trick.declared_suit

	return game.last_completed_trick_declared_suit


func _get_displayed_joker_forced_card_rank() -> Trick.ForcedCardRank:
	if game.active_trick != null:
		return game.active_trick.forced_card_rank

	return game.last_completed_trick_forced_card_rank


func _refresh_score_sheet() -> void:
	score_sheet_panel.visible = is_score_sheet_visible
	score_sheet_toggle_button.text = "Скрыть расписку" if is_score_sheet_visible else "📋 Расписка"
	score_sheet_toggle_button.disabled = is_processing_automatic_actions
	score_sheet_title.text = "Расписка: %d из %d раздач сыграно · полный план партии" % [round_history.size(), TOTAL_ROUND_COUNT]
	final_results_label.visible = _is_full_game_complete()

	if final_results_label.visible:
		final_results_label.text = _get_final_results_text()
	else:
		final_results_label.text = ""

	if not is_score_sheet_visible:
		return

	_clear_children(score_sheet_grid)

	var completed_rounds: Dictionary = {}
	for completed_round in round_history:
		completed_rounds[int(completed_round["round_number"])] = completed_round

	var header_texts := ["№", "Раздача / козырь"]
	for player_index in game.players.size():
		header_texts.append(game.players[player_index].display_name)
	for header_index in header_texts.size():
		_add_score_sheet_cell(header_texts[header_index], true, false, false, 220.0 if header_index == 1 else 150.0)

	for round_number in range(1, TOTAL_ROUND_COUNT + 1):
		var round_plan: Dictionary = _get_planned_round(round_number)
		var has_completed_round := completed_rounds.has(round_number)
		var is_current_round := round_number == game.current_round.number and not has_completed_round
		var is_future_round := round_number > game.current_round.number
		var trump_name := str(round_plan["trump_name"])

		if has_completed_round:
			var completed_round_record: Dictionary = completed_rounds[round_number]
			trump_name = str(completed_round_record["trump_name"])
		elif is_current_round:
			trump_name = game.current_round.get_trump_name()

		var round_info := "%s · %d карт\n%s" % [
			str(round_plan["label"]),
			int(round_plan["cards_per_player"]),
			trump_name
		]
		_add_score_sheet_cell(str(round_number), false, is_current_round, is_future_round)
		_add_score_sheet_cell(round_info, false, is_current_round, is_future_round, 220.0)

		for player_index in game.players.size():
			var result_text := "—"
			if has_completed_round:
				var result_round_record: Dictionary = completed_rounds[round_number]
				var player_results: Array = result_round_record["players"]
				var player_result: Dictionary = player_results[player_index]
				var bid_text := str(player_result["bid"]) if bool(result_round_record["uses_bids"]) else "—"
				result_text = "%s / %d / %s" % [
					bid_text,
					player_result["tricks_taken"],
					_format_score(int(player_result["round_score"]))
				]
			elif is_current_round:
				result_text = _get_current_score_sheet_result(player_index, bool(round_plan["uses_bids"]))

			_add_score_sheet_cell(result_text, false, is_current_round, is_future_round)


func _get_planned_round(round_number: int) -> Dictionary:
	var round_index := round_number - 1

	if round_index < NORMAL_ROUND_COUNT:
		var cards_per_player := round_index + 1 if round_index < 8 else 9
		var trump_name := "случайный козырь" if round_index < 8 else _get_trump_name_from_suit(_get_fixed_trump_for_special_round(round_index - 8))
		return {
			"label": "Обычная %d/%d" % [round_index + 1, NORMAL_ROUND_COUNT],
			"cards_per_player": cards_per_player,
			"trump_name": trump_name,
			"uses_bids": true
		}

	round_index -= NORMAL_ROUND_COUNT
	if round_index < DARK_ROUND_COUNT:
		return {
			"label": "Тёмная %d/%d · вслепую" % [round_index + 1, DARK_ROUND_COUNT],
			"cards_per_player": 9,
			"trump_name": _get_trump_name_from_suit(_get_fixed_trump_for_special_round(round_index)),
			"uses_bids": true
		}

	round_index -= DARK_ROUND_COUNT
	if round_index < NO_TRUMP_ROUND_COUNT:
		return {
			"label": "Бескозырка %d/%d" % [round_index + 1, NO_TRUMP_ROUND_COUNT],
			"cards_per_player": 9,
			"trump_name": "без козыря",
			"uses_bids": true
		}

	round_index -= NO_TRUMP_ROUND_COUNT
	if round_index < GOLDEN_ROUND_COUNT:
		return {
			"label": "Золотая %d/%d · без заказов" % [round_index + 1, GOLDEN_ROUND_COUNT],
			"cards_per_player": 9,
			"trump_name": _get_trump_name_from_suit(_get_fixed_trump_for_special_round(round_index)),
			"uses_bids": false
		}

	round_index -= GOLDEN_ROUND_COUNT
	return {
		"label": "Мизерная %d/%d · без заказов" % [round_index + 1, MISERE_ROUND_COUNT],
		"cards_per_player": 9,
		"trump_name": _get_trump_name_from_suit(_get_fixed_trump_for_special_round(round_index)),
		"uses_bids": false
	}


func _get_trump_name_from_suit(trump: Round.TrumpSuit) -> String:
	match trump:
		Round.TrumpSuit.CLUBS:
			return "♣"
		Round.TrumpSuit.SPADES:
			return "♠"
		Round.TrumpSuit.HEARTS:
			return "♥"
		Round.TrumpSuit.DIAMONDS:
			return "♦"
		Round.TrumpSuit.NONE:
			return "без козыря"

	return "случайный козырь"


func _get_current_score_sheet_result(player_index: int, uses_bids: bool) -> String:
	var player := game.players[player_index]
	var bid_text := str(player.bid) if uses_bids and player.bid >= 0 else "—"
	return "%s / %d / …" % [bid_text, player.tricks_taken]


func _add_score_sheet_cell(
	text: String,
	is_header := false,
	is_current_round := false,
	is_future_round := false,
	minimum_width := 112.0
) -> void:
	var cell := Label.new()
	cell.custom_minimum_size = Vector2(minimum_width, 42)
	cell.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cell.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cell.autowrap_mode = 2
	cell.text = text
	cell.add_theme_font_size_override("font_size", 14 if is_header else 13)

	if is_header:
		cell.add_theme_color_override("font_color", Color(0.97, 0.86, 0.55))
	elif is_current_round:
		cell.add_theme_color_override("font_color", Color(1.0, 0.83, 0.34))
	elif is_future_round:
		cell.add_theme_color_override("font_color", Color(0.48, 0.64, 0.54))
	else:
		cell.add_theme_color_override("font_color", Color(0.86, 0.94, 0.87))

	score_sheet_grid.add_child(cell)


func _record_completed_round(round_scores: Array[int]) -> void:
	var player_results: Array[Dictionary] = []

	for player_index in game.players.size():
		var player := game.players[player_index]
		player_results.append({
			"bid": player.bid,
			"tricks_taken": player.tricks_taken,
			"round_score": round_scores[player_index]
		})

	round_history.append({
		"round_number": game.current_round.number,
		"round_label": _get_current_round_label(),
		"trump_name": game.current_round.get_trump_name(),
		"uses_bids": _round_uses_bids(),
		"players": player_results
	})


func _get_current_round_label() -> String:
	if _is_misere_round():
		return "Мизерная %d/%d" % [misere_round_index + 1, MISERE_ROUND_COUNT]

	if _is_golden_round():
		return "Золотая %d/%d" % [golden_round_index + 1, GOLDEN_ROUND_COUNT]

	if _is_no_trump_round():
		return "Бескозырка %d/%d" % [no_trump_round_index + 1, NO_TRUMP_ROUND_COUNT]

	if _is_dark_round():
		return "Тёмная %d/%d" % [dark_round_index + 1, DARK_ROUND_COUNT]

	return "Обычная %d/%d" % [normal_round_index + 1, NORMAL_ROUND_COUNT]


func _get_final_results_text() -> String:
	var standings: Array[Dictionary] = []

	for player in game.players:
		standings.append({
			"player_id": player.player_id,
			"name": player.display_name,
			"score": player.total_score,
			"tricks_taken": _get_total_tricks_for_player(player.player_id),
			"exact_orders": player.exact_orders_completed
		})

	standings.sort_custom(func(left: Dictionary, right: Dictionary) -> bool:
		if left["score"] != right["score"]:
			return left["score"] > right["score"]

		return left["exact_orders"] > right["exact_orders"]
	)

	var result_lines := PackedStringArray()
	result_lines.append("Итоги партии")
	var place := 1

	for standing_index in standings.size():
		var standing: Dictionary = standings[standing_index]

		if standing_index > 0:
			var previous_standing: Dictionary = standings[standing_index - 1]
			if not _are_standings_equal(standing, previous_standing):
				place = standing_index + 1

		var shares_place := (
			(standing_index > 0 and _are_standings_equal(standing, standings[standing_index - 1]))
			or (standing_index < standings.size() - 1 and _are_standings_equal(standing, standings[standing_index + 1]))
		)
		var place_prefix := "🏆" if place == 1 and not shares_place else "🤝" if shares_place else "•"
		var place_text := "%d-е место" % place

		if shares_place:
			place_text += " (ничья)"

		result_lines.append("%s %s: %s — %d очк. · %d вз. · точных заказов: %d" % [
			place_prefix,
			place_text,
			standing["name"],
			standing["score"],
			standing["tricks_taken"],
			standing["exact_orders"]
		])

	return "\n".join(result_lines)


func _are_standings_equal(left: Dictionary, right: Dictionary) -> bool:
	return left["score"] == right["score"] and left["exact_orders"] == right["exact_orders"]


func _get_total_tricks_for_player(player_index: int) -> int:
	var total_tricks := 0

	for round_record in round_history:
		var player_results: Array = round_record["players"]
		var player_result: Dictionary = player_results[player_index]
		total_tricks += int(player_result["tricks_taken"])

	return total_tricks


func _format_score(score: int) -> String:
	return "+%d" % score if score > 0 else str(score)


func _refresh_history() -> void:
	if recent_actions.is_empty():
		history_label.text = "Ход раздачи: —"
		return

	history_label.text = "Ход раздачи\n%s" % "\n".join(recent_actions)
	call_deferred("_scroll_round_history_to_bottom")


func _refresh_round_history_panel() -> void:
	round_history_panel.visible = is_round_history_visible
	round_history_toggle_button.text = "История ▾" if is_round_history_visible else "История ▸"
	round_history_toggle_button.disabled = is_processing_automatic_actions


func _refresh_round_results() -> void:
	var round_is_finished := game.current_round.state == Round.State.FINISHED
	round_results_panel.visible = round_is_finished

	if not round_is_finished:
		round_results_label.text = ""
		return

	round_results_label.text = "Итоги раздачи\n\n%s" % action_text.trim_prefix("Раздача завершена.\n")


func _scroll_round_history_to_bottom() -> void:
	var scroll_bar: VScrollBar = round_history_scroll.get_v_scroll_bar()
	round_history_scroll.scroll_vertical = int(scroll_bar.max_value)


func _refresh_bid_controls() -> void:
	_clear_children(bid_controls)

	if (
		is_processing_automatic_actions
		or game.current_round.state != Round.State.BIDDING
		or game.current_round.current_player_index != HUMAN_PLAYER_INDEX
	):
		return

	for bid in game.current_round.cards_per_player + 1:
		var bid_button := Button.new()
		bid_button.text = "Заказать %d" % bid
		bid_button.disabled = not game.current_round.can_place_bid(HUMAN_PLAYER_INDEX, bid)
		bid_button.pressed.connect(_on_bid_pressed.bind(bid))
		bid_controls.add_child(bid_button)


func _refresh_joker_controls() -> void:
	_clear_children(joker_controls)

	if pending_joker_card == null:
		# Верхний слой выбора Джокера не должен перекрывать обычные кнопки,
		# когда игрок ещё не выбирает его условие.
		joker_controls.visible = false
		joker_controls.mouse_filter = Control.MOUSE_FILTER_IGNORE
		return

	joker_controls.visible = true
	joker_controls.mouse_filter = Control.MOUSE_FILTER_STOP
	_place_joker_controls()

	if game.active_trick == null:
		if pending_joker_suit < 0:
			for suit in Card.Suit.values():
				_add_joker_suit_button("Объявить %s" % _get_suit_symbol(suit), suit)
			return

		var suit_symbol := _get_suit_symbol(pending_joker_suit)
		_add_joker_choice_button("%s: Джокер забирает" % suit_symbol, Trick.JokerMode.JOKER_WINS, pending_joker_suit)
		_add_joker_choice_button("%s: старшая забирает" % suit_symbol, Trick.JokerMode.HIGHEST_DECLARED_CARD_WINS, pending_joker_suit)
		_add_joker_choice_button("%s: младшая забирает" % suit_symbol, Trick.JokerMode.LOWEST_DECLARED_CARD_WINS, pending_joker_suit)
		_add_joker_choice_button("%s: кладите старшую — Джокер забирает" % suit_symbol, Trick.JokerMode.JOKER_WINS, pending_joker_suit, Trick.ForcedCardRank.HIGHEST)
		_add_joker_choice_button("%s: кладите младшую — Джокер забирает" % suit_symbol, Trick.JokerMode.JOKER_WINS, pending_joker_suit, Trick.ForcedCardRank.LOWEST)
		_add_joker_choice_button("%s: кладите старшую — Джокер не забирает" % suit_symbol, Trick.JokerMode.NORMAL_CARD_WINS, pending_joker_suit, Trick.ForcedCardRank.HIGHEST)
		_add_joker_choice_button("%s: кладите младшую — Джокер не забирает" % suit_symbol, Trick.JokerMode.NORMAL_CARD_WINS, pending_joker_suit, Trick.ForcedCardRank.LOWEST)
		_add_joker_suit_button("← Выбрать другую масть", -1)
	else:
		_add_joker_choice_button("Джокер забирает", Trick.JokerMode.JOKER_WINS)
		_add_joker_choice_button("Сбросить Джокер (не забирает)", Trick.JokerMode.NORMAL_CARD_WINS)


func _place_joker_controls() -> void:
	var is_leading_joker_choice := pending_joker_card != null and game.active_trick == null

	if is_leading_joker_choice:
		joker_controls.columns = 1
		_set_control_layout(joker_controls, 0.0, 0.0, 0.0, 0.0, 64.0, 400.0, 384.0, 782.0)
		return

	joker_controls.columns = 2
	_set_control_layout(joker_controls, 0.5, 1.0, 0.5, 1.0, -330.0, -340.0, 330.0, -288.0)


func _refresh_hand() -> void:
	_clear_children(hand_container)
	hand_title.text = "Твоя рука (%s)" % game.players[HUMAN_PLAYER_INDEX].display_name

	if _is_dark_round() and not game.cards_are_dealt:
		var hidden_cards_label := Label.new()
		hidden_cards_label.text = "Карты будут сданы после того, как все игроки сделают заказ."
		hidden_cards_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hidden_cards_label.add_theme_font_size_override("font_size", 16)
		hand_container.add_child(hidden_cards_label)
		return

	var human_player := game.players[HUMAN_PLAYER_INDEX]
	var displayed_cards := _sort_cards_for_display(human_player.hand, game.current_round.trump, hand_sort_mode)

	for card in displayed_cards:
		var card_view := CardView.new()
		card_view.set_card(card)
		card_view.set_interactive(
			true,
			not _is_human_turn() or not _is_card_available_to_human(card) or pending_joker_card != null
		)
		card_view.card_pressed.connect(_on_card_pressed)
		hand_container.add_child(card_view)


func _refresh_hand_sort_controls() -> void:
	hand_sort_by_suit_button.disabled = is_processing_automatic_actions or hand_sort_mode == HandSortMode.BY_SUIT
	hand_sort_trumps_left_button.disabled = is_processing_automatic_actions or hand_sort_mode == HandSortMode.TRUMPS_LEFT


func _sort_cards_for_display(
	cards: Array[Card],
	trump: Round.TrumpSuit,
	sort_mode: HandSortMode
) -> Array[Card]:
	var displayed_cards: Array[Card] = cards.duplicate()
	displayed_cards.sort_custom(func(left: Card, right: Card) -> bool:
		return _is_display_card_before(left, right, trump, sort_mode)
	)
	return displayed_cards


func _is_display_card_before(
	left: Card,
	right: Card,
	trump: Round.TrumpSuit,
	sort_mode: HandSortMode
) -> bool:
	if sort_mode == HandSortMode.TRUMPS_LEFT:
		var left_group: int = _get_display_card_group(left, trump)
		var right_group: int = _get_display_card_group(right, trump)
		if left_group != right_group:
			return left_group < right_group

	if left.suit != right.suit:
		return left.suit < right.suit

	if left.rank != right.rank:
		return left.rank < right.rank

	return left.is_joker and not right.is_joker


func _get_display_card_group(card: Card, trump: Round.TrumpSuit) -> int:
	if card.is_joker:
		return 0

	if trump != Round.TrumpSuit.NONE and card.suit == trump:
		return 1

	return 2


func _refresh_undo_button() -> void:
	undo_button.disabled = (
		is_processing_automatic_actions
		or test_checkpoints.is_empty()
		or game.current_round.state == Round.State.FINISHED
	)


func _create_player_panels() -> void:
	for player_index in PLAYER_NAMES.size():
		var panel := PanelContainer.new()
		_place_player_panel(panel, player_index)

		var content := VBoxContainer.new()
		content.add_theme_constant_override("separation", 0)
		panel.add_child(content)

		var name_label := Label.new()
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.add_theme_font_size_override("font_size", 18)
		name_label.add_theme_color_override("font_color", Color(0.95, 0.97, 0.93, 1.0))
		content.add_child(name_label)

		var stats_label := Label.new()
		stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		stats_label.add_theme_font_size_override("font_size", 14)
		stats_label.add_theme_color_override("font_color", Color(0.82, 0.88, 0.82, 1.0))
		content.add_child(stats_label)
		players_container.add_child(panel)
		player_labels.append(name_label)
		player_stats_labels.append(stats_label)
		player_panels.append(panel)


func _create_trick_slots() -> void:
	for player_index in PLAYER_NAMES.size():
		var card_view := CardView.new()
		card_view.set_card_size(Vector2(108.0, 132.0))
		card_view.set_interactive(false, false)
		_place_trick_slot(card_view, player_index)
		card_view.visible = false
		trick_slots.add_child(card_view)
		trick_card_views.append(card_view)


func _create_bot_card_backs() -> void:
	for player_index in range(1, PLAYER_NAMES.size()):
		var holder := Control.new()
		holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_place_bot_card_back_holder(holder, player_index)

		for card_index in 3:
			var card_back := PanelContainer.new()
			card_back.position = Vector2(float(card_index * 14), 0.0)
			card_back.size = Vector2(38.0, 54.0)
			card_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
			card_back.add_theme_stylebox_override("panel", card_back_style)

			var ornament := Label.new()
			ornament.text = "✦"
			ornament.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			ornament.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			ornament.add_theme_color_override("font_color", Color(0.9, 0.73, 0.31, 1.0))
			ornament.add_theme_font_size_override("font_size", 22)
			card_back.add_child(ornament)
			holder.add_child(card_back)

		players_container.add_child(holder)
		bot_card_back_holders.append(holder)


func _place_bot_card_back_holder(holder: Control, player_index: int) -> void:
	match player_index:
		1:
			_set_control_layout(holder, 0.0, 0.0, 0.0, 0.0, 400.0, 446.0, 492.0, 502.0)
		2:
			_set_control_layout(holder, 0.5, 0.0, 0.5, 0.0, 184.0, 96.0, 276.0, 152.0)
		3:
			_set_control_layout(holder, 1.0, 0.0, 1.0, 0.0, -492.0, 446.0, -400.0, 502.0)


func _refresh_bot_card_backs() -> void:
	for holder_index in bot_card_back_holders.size():
		var holder := bot_card_back_holders[holder_index]
		var player_index: int = holder_index + 1
		var visible_card_count: int = mini(3, game.players[player_index].hand.size())
		holder.visible = visible_card_count > 0

		for card_index in holder.get_child_count():
			var card_back: Control = holder.get_child(card_index) as Control
			if card_back != null:
				card_back.visible = card_index < visible_card_count


func _create_deck_visual() -> void:
	for card_index in 3:
		var card_back := PanelContainer.new()
		card_back.position = Vector2(float(card_index * 8), 8.0)
		card_back.size = Vector2(58.0, 78.0)
		card_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card_back.add_theme_stylebox_override("panel", card_back_style)

		var ornament := Label.new()
		ornament.text = "✦"
		ornament.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		ornament.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		ornament.add_theme_color_override("font_color", Color(0.9, 0.73, 0.31, 1.0))
		ornament.add_theme_font_size_override("font_size", 24)
		card_back.add_child(ornament)
		deck_visual.add_child(card_back)
		deck_back_panels.append(card_back)

	deck_trump_panel = PanelContainer.new()
	deck_trump_panel.position = Vector2(48.0, 20.0)
	deck_trump_panel.size = Vector2(76.0, 96.0)
	deck_trump_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	deck_trump_panel.add_theme_stylebox_override("panel", deck_trump_card_style)

	deck_trump_label = Label.new()
	deck_trump_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	deck_trump_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	deck_trump_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	deck_trump_panel.add_child(deck_trump_label)
	deck_visual.add_child(deck_trump_panel)

	deck_caption_label = Label.new()
	deck_caption_label.position = Vector2(0.0, 118.0)
	deck_caption_label.size = Vector2(125.0, 38.0)
	deck_caption_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	deck_caption_label.add_theme_color_override("font_color", Color(0.85, 0.95, 0.88, 1.0))
	deck_caption_label.add_theme_font_size_override("font_size", 13)
	deck_visual.add_child(deck_caption_label)


func _refresh_deck_visual() -> void:
	deck_visual.visible = (
		game.current_round.state != Round.State.SETUP
		and not (pending_joker_card != null and game.active_trick == null)
	)
	if not deck_visual.visible:
		return

	var has_open_trump := game.trump_card != null
	var visible_deck_cards := mini(3, game.deck.cards_left()) if has_open_trump else 0

	for card_index in deck_back_panels.size():
		deck_back_panels[card_index].visible = card_index < visible_deck_cards

	if has_open_trump:
		var trump_card := game.trump_card
		deck_trump_label.text = trump_card.get_card_name()
		deck_trump_label.add_theme_font_size_override("font_size", 17)
		deck_trump_label.add_theme_color_override(
			"font_color",
			Color(0.74, 0.08, 0.06, 1.0) if trump_card.suit == Card.Suit.HEARTS or trump_card.suit == Card.Suit.DIAMONDS else Color(0.08, 0.08, 0.07, 1.0)
		)
		deck_trump_panel.tooltip_text = "Открытая карта определяет козырь."
		deck_caption_label.text = (
			"Открытый Джокер\nБескозырка"
			if trump_card.is_joker
			else "Открытый козырь\nВ колоде: %d" % game.deck.cards_left()
		)
		return

	var trump_name := game.current_round.get_trump_name()
	deck_trump_label.text = "—" if game.current_round.trump == Round.TrumpSuit.NONE else trump_name
	deck_trump_label.add_theme_font_size_override("font_size", 32)
	deck_trump_label.add_theme_color_override("font_color", Color(0.08, 0.08, 0.07, 1.0))
	deck_trump_panel.tooltip_text = "Козырь задан правилами этой раздачи."
	deck_caption_label.text = "Без козыря" if game.current_round.trump == Round.TrumpSuit.NONE else "Козырь задан\n%s" % trump_name


func _create_table_markers() -> void:
	dealer_marker = _create_table_marker("D", "Сдающий", dealer_marker_style, 18)
	lead_marker = _create_table_marker("Заход", "Начинает текущую взятку", lead_marker_style, 14)
	players_container.add_child(dealer_marker)
	players_container.add_child(lead_marker)


func _create_table_marker(label_text: String, tooltip: String, style: StyleBoxFlat, font_size: int) -> PanelContainer:
	var marker := PanelContainer.new()
	marker.tooltip_text = tooltip
	marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	marker.add_theme_stylebox_override("panel", style)

	var label := Label.new()
	label.text = label_text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color(0.98, 0.92, 0.74, 1.0))
	marker.add_child(label)
	return marker


func _refresh_table_markers() -> void:
	var show_markers := game.dealer_index >= 0 and game.current_round.state != Round.State.SETUP
	dealer_marker.visible = show_markers
	lead_marker.visible = show_markers and game.current_round.lead_player_index >= 0

	if not show_markers:
		return

	_place_table_marker(dealer_marker, game.dealer_index, true)
	if lead_marker.visible:
		_place_table_marker(lead_marker, game.current_round.lead_player_index, false)


func _place_table_marker(marker: PanelContainer, player_index: int, is_dealer: bool) -> void:
	if is_dealer:
		match player_index:
			HUMAN_PLAYER_INDEX:
				_set_control_layout(marker, 0.5, 1.0, 0.5, 1.0, 120.0, -404.0, 168.0, -376.0)
			1:
				_set_control_layout(marker, 0.0, 0.0, 0.0, 0.0, 562.0, 342.0, 610.0, 370.0)
			2:
				_set_control_layout(marker, 0.5, 0.0, 0.5, 0.0, 122.0, 72.0, 170.0, 100.0)
			3:
				_set_control_layout(marker, 1.0, 0.0, 1.0, 0.0, -610.0, 342.0, -562.0, 370.0)
		return

	match player_index:
		HUMAN_PLAYER_INDEX:
			_set_control_layout(marker, 0.5, 1.0, 0.5, 1.0, -248.0, -370.0, -170.0, -342.0)
		1:
			_set_control_layout(marker, 0.0, 0.0, 0.0, 0.0, 350.0, 324.0, 428.0, 352.0)
		2:
			_set_control_layout(marker, 0.5, 0.0, 0.5, 0.0, -258.0, 108.0, -180.0, 136.0)
		3:
			_set_control_layout(marker, 1.0, 0.0, 1.0, 0.0, -428.0, 324.0, -350.0, 352.0)


func _place_player_panel(panel: PanelContainer, player_index: int) -> void:
	match player_index:
		HUMAN_PLAYER_INDEX:
			_set_control_layout(panel, 0.5, 1.0, 0.5, 1.0, -170.0, -390.0, 170.0, -314.0)
		1:
			_set_control_layout(panel, 0.0, 0.0, 0.0, 0.0, 350.0, 360.0, 610.0, 436.0)
		2:
			_set_control_layout(panel, 0.5, 0.0, 0.5, 0.0, -170.0, 84.0, 170.0, 160.0)
		3:
			_set_control_layout(panel, 1.0, 0.0, 1.0, 0.0, -610.0, 360.0, -350.0, 436.0)


func _place_trick_slot(panel: Control, player_index: int) -> void:
	match player_index:
		HUMAN_PLAYER_INDEX:
			_set_control_layout(panel, 0.5, 0.0, 0.5, 0.0, -54.0, 460.0, 54.0, 592.0)
		1:
			_set_control_layout(panel, 0.5, 0.0, 0.5, 0.0, -220.0, 368.0, -112.0, 500.0)
		2:
			_set_control_layout(panel, 0.5, 0.0, 0.5, 0.0, -54.0, 178.0, 54.0, 310.0)
		3:
			_set_control_layout(panel, 0.5, 0.0, 0.5, 0.0, 112.0, 368.0, 220.0, 500.0)


func _set_control_layout(
	control: Control,
	left_anchor: float,
	top_anchor: float,
	right_anchor: float,
	bottom_anchor: float,
	left_offset: float,
	top_offset: float,
	right_offset: float,
	bottom_offset: float
) -> void:
	control.anchor_left = left_anchor
	control.anchor_top = top_anchor
	control.anchor_right = right_anchor
	control.anchor_bottom = bottom_anchor
	control.offset_left = left_offset
	control.offset_top = top_offset
	control.offset_right = right_offset
	control.offset_bottom = bottom_offset


func _add_joker_suit_button(label: String, suit: int) -> void:
	var suit_button := Button.new()
	suit_button.text = label
	suit_button.custom_minimum_size = Vector2(0.0, 44.0)
	suit_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	suit_button.disabled = false
	suit_button.mouse_filter = Control.MOUSE_FILTER_STOP
	suit_button.z_index = 1

	if suit < 0:
		suit_button.pressed.connect(_on_joker_suit_reset)
	else:
		suit_button.pressed.connect(_on_joker_suit_pressed.bind(suit))

	joker_controls.add_child(suit_button)


func _on_joker_suit_reset() -> void:
	pending_joker_suit = -1
	action_text = "Выбери объявляемую масть для Джокера."
	_refresh_ui()


func _add_joker_choice_button(
	label: String,
	mode: Trick.JokerMode,
	declared_suit: int = -1,
	forced_card_rank: Trick.ForcedCardRank = Trick.ForcedCardRank.NONE
) -> void:
	var choice_button := Button.new()
	choice_button.text = label
	choice_button.custom_minimum_size = Vector2(0.0, 44.0)
	choice_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	choice_button.disabled = false
	choice_button.mouse_filter = Control.MOUSE_FILTER_STOP
	choice_button.z_index = 1
	choice_button.pressed.connect(_on_joker_choice.bind(mode, declared_suit, forced_card_rank))
	joker_controls.add_child(choice_button)


func _get_current_player_index() -> int:
	if game.current_round.state == Round.State.BIDDING:
		return game.current_round.current_player_index

	if game.current_round.state == Round.State.PLAYING:
		if game.active_trick == null:
			return game.current_round.lead_player_index
		return game.active_trick.current_player_index

	return -1


func _is_human_turn() -> bool:
	return (
		not is_processing_automatic_actions
		and game.current_round.state == Round.State.PLAYING
		and _get_current_player_index() == HUMAN_PLAYER_INDEX
	)


func _is_card_available_to_human(card: Card) -> bool:
	if game.active_trick == null:
		return true

	return game.active_trick.can_play_card(game.players[HUMAN_PLAYER_INDEX], card)


func _choose_automatic_bid(player_index: int) -> int:
	var player := game.players[player_index]
	var is_dark_bid := game.current_round.round_type == Round.RoundType.DARK
	var min_bid := 2 if is_dark_bid else 0
	var max_bid := 4 if is_dark_bid else game.current_round.cards_per_player

	if bot_difficulty == BotDifficulty.EASY:
		return _choose_random_valid_bid(player_index, min_bid, max_bid)

	var desired_bid := bot_random.randi_range(2, 4) if is_dark_bid else _estimate_automatic_bid(player)
	if bot_difficulty == BotDifficulty.HARD and not is_dark_bid:
		desired_bid = _estimate_hard_automatic_bid(player)

	var closest_bid := _find_closest_valid_bid(player_index, desired_bid, min_bid, max_bid)

	if closest_bid >= 0:
		return closest_bid

	return _find_closest_valid_bid(player_index, desired_bid, 0, game.current_round.cards_per_player)


func _choose_random_valid_bid(player_index: int, min_bid: int, max_bid: int) -> int:
	var valid_bids: Array[int] = []

	for bid_value in game.current_round.cards_per_player + 1:
		var bid: int = bid_value
		if bid < min_bid or bid > max_bid:
			continue
		if game.current_round.can_place_bid(player_index, bid):
			valid_bids.append(bid)

	if valid_bids.is_empty():
		return _find_closest_valid_bid(player_index, 0, 0, game.current_round.cards_per_player)

	var random_index: int = bot_random.randi_range(0, valid_bids.size() - 1)
	return valid_bids[random_index]


func _find_closest_valid_bid(player_index: int, desired_bid: int, min_bid: int, max_bid: int) -> int:
	var closest_bid: int = -1
	var closest_difference: int = game.current_round.cards_per_player + 1

	for bid_value in game.current_round.cards_per_player + 1:
		var bid: int = bid_value
		if bid < min_bid or bid > max_bid:
			continue

		if not game.current_round.can_place_bid(player_index, bid):
			continue

		var difference: int = absi(bid - desired_bid)
		if difference < closest_difference:
			closest_bid = bid
			closest_difference = difference

	return closest_bid


func _choose_automatic_card(player: Player) -> Card:
	var legal_cards := _get_legal_cards(player)

	if legal_cards.is_empty():
		return null

	if bot_difficulty == BotDifficulty.EASY:
		var random_index: int = bot_random.randi_range(0, legal_cards.size() - 1)
		return legal_cards[random_index]

	if bot_difficulty == BotDifficulty.HARD:
		return _choose_hard_automatic_card(player, legal_cards)

	var wants_trick := _bot_wants_trick(player)

	if game.active_trick == null:
		if wants_trick:
			var leading_joker := _get_joker_from_cards(legal_cards)
			if leading_joker != null:
				return leading_joker

			return _select_card_by_strength(legal_cards, true)

		var low_lead_card := _select_non_joker_card_by_strength(legal_cards, false)
		return low_lead_card if low_lead_card != null else legal_cards[0]

	if wants_trick:
		var weakest_winning_regular_card: Card = _select_weakest_winning_regular_card(legal_cards)
		if weakest_winning_regular_card != null:
			return weakest_winning_regular_card

		var taking_joker := _get_joker_from_cards(legal_cards)
		if taking_joker != null:
			return taking_joker

		return _select_card_by_strength(legal_cards, true)

	if _should_shed_high_card_in_misere(legal_cards):
		return _select_non_joker_card_by_strength(legal_cards, true)

	var discarding_joker := _get_joker_from_cards(legal_cards)
	if discarding_joker != null:
		return discarding_joker

	return _select_card_by_strength(legal_cards, false)


func _choose_hard_automatic_card(player: Player, legal_cards: Array[Card]) -> Card:
	var wants_trick := _bot_wants_trick(player)

	if game.active_trick == null:
		if wants_trick:
			var strong_regular_lead := _select_non_joker_card_by_strength(legal_cards, true)
			return strong_regular_lead if strong_regular_lead != null else _get_joker_from_cards(legal_cards)

		var weak_regular_lead := _select_non_joker_card_by_strength(legal_cards, false)
		return weak_regular_lead if weak_regular_lead != null else legal_cards[0]

	if wants_trick:
		var weakest_winning_regular_card := _select_weakest_winning_regular_card(legal_cards)
		if weakest_winning_regular_card != null:
			return weakest_winning_regular_card

		var taking_joker := _get_joker_from_cards(legal_cards)
		if taking_joker != null:
			return taking_joker

		return _select_card_by_strength(legal_cards, true)

	if _should_shed_high_card_in_misere(legal_cards):
		return _select_non_joker_card_by_strength(legal_cards, true)

	var weakest_losing_regular_card := _select_weakest_losing_regular_card(legal_cards)
	if weakest_losing_regular_card != null:
		return weakest_losing_regular_card

	var discarding_joker := _get_joker_from_cards(legal_cards)
	if discarding_joker != null:
		return discarding_joker

	return _select_card_by_strength(legal_cards, false)


func _estimate_automatic_bid(player: Player) -> int:
	if player.hand.is_empty():
		return 0

	var estimate := 0
	var trump_cards := 0
	var high_non_trump_cards := 0

	for card in player.hand:
		if card.is_joker:
			estimate += 1
			continue

		if card.suit == game.current_round.trump:
			trump_cards += 1
			if card.rank >= Card.Rank.TEN:
				estimate += 1
		elif card.rank == Card.Rank.ACE:
			high_non_trump_cards += 1
		elif card.rank == Card.Rank.KING:
			high_non_trump_cards += 1

	estimate += floori(float(high_non_trump_cards) / 2.0)

	if trump_cards >= 3 and estimate == 0:
		estimate = 1

	return clampi(estimate, 0, game.current_round.cards_per_player)


func _estimate_hard_automatic_bid(player: Player) -> int:
	var estimate := _estimate_automatic_bid(player)
	var aces := 0
	var high_trumps := 0

	for card in player.hand:
		if card.is_joker:
			continue

		if card.rank == Card.Rank.ACE:
			aces += 1
		if game.current_round.trump != Round.TrumpSuit.NONE and card.suit == game.current_round.trump and card.rank >= Card.Rank.JACK:
			high_trumps += 1

	if aces >= 2:
		estimate += 1
	if high_trumps >= 2:
		estimate += 1

	return clampi(estimate, 0, game.current_round.cards_per_player)


func _get_legal_cards(player: Player) -> Array[Card]:
	var legal_cards: Array[Card] = []

	for card in player.hand:
		if game.active_trick == null or game.active_trick.can_play_card(player, card):
			legal_cards.append(card)

	return legal_cards


func _select_weakest_winning_regular_card(legal_cards: Array[Card]) -> Card:
	var winning_cards: Array[Card] = []

	for card in legal_cards:
		if not card.is_joker and _would_regular_card_win_current_trick(card):
			winning_cards.append(card)

	return _select_card_by_strength(winning_cards, false)


func _select_weakest_losing_regular_card(legal_cards: Array[Card]) -> Card:
	var losing_cards: Array[Card] = []

	for card in legal_cards:
		if not card.is_joker and not _would_regular_card_win_current_trick(card):
			losing_cards.append(card)

	return _select_card_by_strength(losing_cards, false)


func _would_regular_card_win_current_trick(card: Card) -> bool:
	if card.is_joker or game.active_trick == null:
		return false

	var active_trick: Trick = game.active_trick
	var simulated_trick := Trick.new()
	simulated_trick.player_count = active_trick.played_cards.size() + 1
	simulated_trick.trump = active_trick.trump
	simulated_trick.lead_suit = active_trick.lead_suit
	simulated_trick.joker_mode = active_trick.joker_mode
	simulated_trick.declared_suit = active_trick.declared_suit
	simulated_trick.forced_card_rank = active_trick.forced_card_rank
	simulated_trick.played_cards.assign(active_trick.played_cards)
	simulated_trick.played_by.assign(active_trick.played_by)
	simulated_trick.played_cards.append(card)
	simulated_trick.played_by.append(-1)

	return simulated_trick.get_winner_index() == -1


func _should_shed_high_card_in_misere(legal_cards: Array[Card]) -> bool:
	if (
		game.current_round.round_type != Round.RoundType.MISERE
		or game.active_trick == null
		or game.active_trick.played_cards.size() != game.players.size() - 1
		or _get_joker_from_cards(legal_cards) != null
	):
		return false

	var regular_cards: Array[Card] = []

	for card in legal_cards:
		if card.is_joker:
			continue

		regular_cards.append(card)
		if not _would_regular_card_win_current_trick(card):
			return false

	return not regular_cards.is_empty()


func _bot_wants_trick(player: Player) -> bool:
	if game.current_round.round_type == Round.RoundType.GOLDEN:
		return true

	if game.current_round.round_type == Round.RoundType.MISERE:
		return false

	return player.bid > player.tricks_taken


func _get_joker_from_cards(cards: Array[Card]) -> Card:
	for card in cards:
		if card.is_joker:
			return card

	return null


func _select_non_joker_card_by_strength(cards: Array[Card], choose_highest: bool) -> Card:
	var non_joker_cards: Array[Card] = []

	for card in cards:
		if not card.is_joker:
			non_joker_cards.append(card)

	return _select_card_by_strength(non_joker_cards, choose_highest)


func _select_card_by_strength(cards: Array[Card], choose_highest: bool) -> Card:
	var selected_card: Card

	for card in cards:
		if selected_card == null:
			selected_card = card
			continue

		var card_strength := _get_automatic_card_strength(card)
		var selected_strength := _get_automatic_card_strength(selected_card)
		var replaces_selected := card_strength > selected_strength if choose_highest else card_strength < selected_strength

		if replaces_selected:
			selected_card = card

	return selected_card


func _get_automatic_card_strength(card: Card) -> int:
	if card.is_joker:
		return 100

	var strength := card.rank

	if game.current_round.trump != Round.TrumpSuit.NONE and card.suit == game.current_round.trump:
		strength += 20

	if game.active_trick != null and card.suit == game.active_trick.lead_suit:
		strength += 10

	return strength


func _choose_joker_suit(player: Player, prefer_rare_suit := false) -> int:
	var suit_counts: Array[int] = [0, 0, 0, 0]

	for card in player.hand:
		if not card.is_joker:
			suit_counts[card.suit] += 1

	var selected_suit := Card.Suit.CLUBS

	for suit in Card.Suit.values():
		if prefer_rare_suit:
			if suit_counts[suit] < suit_counts[selected_suit]:
				selected_suit = suit
		elif suit_counts[suit] > suit_counts[selected_suit]:
			selected_suit = suit

	return selected_suit


func _choose_automatic_joker_mode(player: Player) -> Trick.JokerMode:
	if bot_difficulty == BotDifficulty.EASY:
		return Trick.JokerMode.JOKER_WINS if bot_random.randi_range(0, 1) == 0 else Trick.JokerMode.NORMAL_CARD_WINS

	return Trick.JokerMode.JOKER_WINS if _bot_wants_trick(player) else Trick.JokerMode.NORMAL_CARD_WINS


func _choose_automatic_joker_suit(player: Player, prefer_rare_suit: bool) -> int:
	if bot_difficulty == BotDifficulty.EASY:
		return bot_random.randi_range(Card.Suit.CLUBS, Card.Suit.DIAMONDS)

	return _choose_joker_suit(player, prefer_rare_suit)


func _get_active_trick_text() -> String:
	var play_texts := PackedStringArray()

	for card_index in game.active_trick.played_cards.size():
		play_texts.append("%s: %s" % [
			game.players[game.active_trick.played_by[card_index]].display_name,
			game.active_trick.played_cards[card_index].get_card_name()
		])

	var declaration_text := _get_active_joker_declaration_text()
	var title := "Текущая взятка"

	if not declaration_text.is_empty():
		title += "\n%s" % declaration_text

	return "%s\n%s" % [title, "   •   ".join(play_texts)]


func _get_active_joker_declaration_text() -> String:
	if game.active_trick == null or game.active_trick.played_cards.is_empty():
		return ""

	if not game.active_trick.played_cards[0].is_joker:
		return ""

	return _get_joker_declaration_text(
		game.active_trick.joker_mode,
		game.active_trick.declared_suit,
		game.active_trick.forced_card_rank
	)


func _get_joker_rule_text(
	mode: Trick.JokerMode,
	declared_suit: int,
	forced_card_rank: Trick.ForcedCardRank,
	is_leading_joker: bool
) -> String:
	if is_leading_joker:
		return _get_joker_declaration_text(mode, declared_suit, forced_card_rank)

	return "Условие: Джокер забирает" if mode == Trick.JokerMode.JOKER_WINS else "Условие: Джокер не забирает"


func _get_joker_declaration_text(
	mode: Trick.JokerMode,
	declared_suit: int,
	forced_card_rank: Trick.ForcedCardRank
) -> String:
	var suit_symbol := _get_suit_symbol(declared_suit)
	var winner_text := "Джокер забирает" if mode == Trick.JokerMode.JOKER_WINS else "Джокер не забирает"

	if forced_card_rank == Trick.ForcedCardRank.HIGHEST:
		return "Условие: кладите старшую %s — %s" % [suit_symbol, winner_text]

	if forced_card_rank == Trick.ForcedCardRank.LOWEST:
		return "Условие: кладите младшую %s — %s" % [suit_symbol, winner_text]

	match mode:
		Trick.JokerMode.JOKER_WINS:
			return "Условие: %s — Джокер забирает" % suit_symbol
		Trick.JokerMode.HIGHEST_DECLARED_CARD_WINS:
			return "Условие: %s — старшая масть забирает" % suit_symbol
		Trick.JokerMode.LOWEST_DECLARED_CARD_WINS:
			return "Условие: %s — младшая масть забирает" % suit_symbol

	return "Условие: %s — обычный розыгрыш" % suit_symbol


func _get_suit_symbol(suit: int) -> String:
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


func _get_cards_per_player_for_current_round() -> int:
	if _is_dark_round() or _is_no_trump_round() or _is_golden_round() or _is_misere_round():
		return 9

	if normal_round_index < 8:
		return normal_round_index + 1

	return 9


func _get_trump_for_current_round() -> Round.TrumpSuit:
	if _is_misere_round():
		return _get_fixed_trump_for_special_round(misere_round_index)

	if _is_golden_round():
		return _get_fixed_trump_for_special_round(golden_round_index)

	if _is_no_trump_round():
		return Round.TrumpSuit.NONE

	if _is_dark_round():
		match dark_round_index:
			0:
				return Round.TrumpSuit.CLUBS
			1:
				return Round.TrumpSuit.SPADES
			2:
				return Round.TrumpSuit.HEARTS
			3:
				return Round.TrumpSuit.DIAMONDS
			_:
				return Round.TrumpSuit.NONE

	if normal_round_index < 8:
		return Round.TrumpSuit.RANDOM

	match normal_round_index - 8:
		0:
			return Round.TrumpSuit.CLUBS
		1:
			return Round.TrumpSuit.SPADES
		2:
			return Round.TrumpSuit.HEARTS
		3:
			return Round.TrumpSuit.DIAMONDS
		_:
			return Round.TrumpSuit.NONE


func _get_fixed_trump_for_special_round(round_index: int) -> Round.TrumpSuit:
	match round_index:
		0:
			return Round.TrumpSuit.CLUBS
		1:
			return Round.TrumpSuit.SPADES
		2:
			return Round.TrumpSuit.HEARTS
		3:
			return Round.TrumpSuit.DIAMONDS
		_:
			return Round.TrumpSuit.NONE


func _get_current_round_type() -> Round.RoundType:
	if _is_misere_round():
		return Round.RoundType.MISERE

	if _is_golden_round():
		return Round.RoundType.GOLDEN

	if _is_no_trump_round():
		return Round.RoundType.NO_TRUMP

	return Round.RoundType.DARK if _is_dark_round() else Round.RoundType.NORMAL


func _is_dark_round() -> bool:
	return dark_round_index >= 0 and no_trump_round_index < 0


func _is_no_trump_round() -> bool:
	return no_trump_round_index >= 0 and golden_round_index < 0


func _is_golden_round() -> bool:
	return golden_round_index >= 0 and misere_round_index < 0


func _is_misere_round() -> bool:
	return misere_round_index >= 0


func _is_full_game_complete() -> bool:
	return (
		_is_misere_round()
		and misere_round_index >= MISERE_ROUND_COUNT - 1
		and game.current_round.state == Round.State.FINISHED
	)


func _is_normal_round() -> bool:
	return dark_round_index < 0


func _can_start_next_round() -> bool:
	return (
		normal_round_index < NORMAL_ROUND_COUNT - 1
		or dark_round_index < DARK_ROUND_COUNT - 1
		or no_trump_round_index < NO_TRUMP_ROUND_COUNT - 1
		or golden_round_index < GOLDEN_ROUND_COUNT - 1
		or misere_round_index < MISERE_ROUND_COUNT - 1
	)


func _get_phase_text(phase_name: String) -> String:
	if _is_misere_round():
		return "Мизерная %d/%d · %s" % [misere_round_index + 1, MISERE_ROUND_COUNT, phase_name]

	if _is_golden_round():
		return "Золотая %d/%d · %s" % [golden_round_index + 1, GOLDEN_ROUND_COUNT, phase_name]

	if _is_no_trump_round():
		return "Бескозырка %d/%d · %s" % [no_trump_round_index + 1, NO_TRUMP_ROUND_COUNT, phase_name]

	if _is_dark_round():
		return "Тёмная %d/%d · %s" % [dark_round_index + 1, DARK_ROUND_COUNT, phase_name]

	return "Раздача %d/%d · %s" % [normal_round_index + 1, NORMAL_ROUND_COUNT, phase_name]


func _round_uses_bids() -> bool:
	return (
		game.current_round.round_type == Round.RoundType.NORMAL
		or game.current_round.round_type == Round.RoundType.DARK
		or game.current_round.round_type == Round.RoundType.NO_TRUMP
	)


func _get_special_trump_text(mode_name: String) -> String:
	if game.current_round.trump == Round.TrumpSuit.NONE:
		return "%s: козырей нет" % mode_name

	return "%s: козырь %s" % [mode_name, game.current_round.get_trump_name()]


func _announce_dark_cards_dealt(cards_were_hidden: bool) -> void:
	if cards_were_hidden and game.cards_are_dealt:
		action_text = "Все заказы сделаны. Карты сданы — начинается розыгрыш."
		_add_history(action_text)


func _prepare_test_checkpoint() -> void:
	pending_test_checkpoint = _create_test_checkpoint()


func _commit_test_checkpoint() -> void:
	if pending_test_checkpoint.is_empty():
		return

	test_checkpoints.append(pending_test_checkpoint.duplicate())
	pending_test_checkpoint.clear()


func _create_test_checkpoint() -> Dictionary:
	return {
		"game": game.create_snapshot(),
		"last_trick_text": last_trick_text,
		"recent_actions": recent_actions.duplicate()
	}


func _add_history(action: String) -> void:
	recent_actions.append(action)


func _run_joker_rule_checks() -> void:
	var player := Player.new(0, "Проверка")
	var leader := Player.new(1, "Заход")
	var joker := _create_card(Card.Suit.CLUBS, Card.Rank.SEVEN, true)
	var discard_card := _create_card(Card.Suit.SPADES, Card.Rank.SIX)
	var lead_card := _create_card(Card.Suit.DIAMONDS, Card.Rank.TEN)

	player.receive_card(joker)
	player.receive_card(discard_card)
	leader.receive_card(lead_card)

	var trick := Trick.new()
	trick.setup(1, 2, Round.TrumpSuit.HEARTS)
	assert(trick.play_card(leader, lead_card), "Проверка: заходящая карта должна быть сыграна.")
	assert(trick.can_play_card(player, discard_card), "Джокер не должен запрещать обычный сброс.")
	assert(trick.can_play_card(player, joker), "Джокер должен оставаться допустимым специальным ходом.")

	var club_leader := Player.new(1, "Заход в кресту")
	var club_lead_card := _create_card(Card.Suit.CLUBS, Card.Rank.TEN)
	club_leader.receive_card(club_lead_card)

	var club_trick := Trick.new()
	club_trick.setup(1, 2, Round.TrumpSuit.HEARTS)
	assert(club_trick.play_card(club_leader, club_lead_card), "Проверка: заход в кресту должен быть сыгран.")
	assert(club_trick.can_play_card(player, discard_card), "Джокер 7♣ не должен считаться крестовой картой.")
	assert(club_trick.can_play_card(player, joker), "Джокер должен оставаться добровольным ходом.")

	var actual_club_card := _create_card(Card.Suit.CLUBS, Card.Rank.EIGHT)
	player.receive_card(actual_club_card)
	var suited_leader := Player.new(1, "Заход в кресту")
	var suited_lead_card := _create_card(Card.Suit.CLUBS, Card.Rank.JACK)
	suited_leader.receive_card(suited_lead_card)

	var suited_trick := Trick.new()
	suited_trick.setup(1, 2, Round.TrumpSuit.HEARTS)
	assert(suited_trick.play_card(suited_leader, suited_lead_card), "Проверка: заход в кресту должен быть сыгран.")
	assert(not suited_trick.can_play_card(player, joker), "При наличии обычной масти Джокер нельзя положить вместо неё.")
	assert(suited_trick.can_play_card(player, actual_club_card), "Обычная карта масти захода должна быть доступна.")

	var no_trump_leader := Player.new(1, "Заход в бескозырке")
	var no_trump_lead_card := _create_card(Card.Suit.CLUBS, Card.Rank.QUEEN)
	no_trump_leader.receive_card(no_trump_lead_card)

	var no_trump_trick := Trick.new()
	no_trump_trick.setup(1, 2, Round.TrumpSuit.NONE)
	assert(no_trump_trick.play_card(no_trump_leader, no_trump_lead_card), "Проверка: заход в бескозырке должен быть сыгран.")
	assert(no_trump_trick.can_play_card(player, joker), "В бескозырке Джокер должен быть доступен при наличии масти захода.")

	var response_leader := Player.new(0, "Заход")
	var response_joker_player := Player.new(1, "Сброс Джокера")
	var response_last_player := Player.new(2, "Старшая карта")
	var response_lead_card := _create_card(Card.Suit.DIAMONDS, Card.Rank.TEN)
	var response_joker := _create_card(Card.Suit.CLUBS, Card.Rank.SEVEN, true)
	var response_winning_card := _create_card(Card.Suit.DIAMONDS, Card.Rank.JACK)
	response_leader.receive_card(response_lead_card)
	response_joker_player.receive_card(response_joker)
	response_last_player.receive_card(response_winning_card)

	var response_trick := Trick.new()
	response_trick.setup(0, 3, Round.TrumpSuit.HEARTS)
	assert(response_trick.play_card(response_leader, response_lead_card), "Проверка: обычный заход должен быть сыгран.")
	assert(response_trick.play_card(response_joker_player, response_joker, Trick.JokerMode.NORMAL_CARD_WINS), "Проверка: Джокер должен сбрасываться без заказа победителя.")
	assert(response_trick.play_card(response_last_player, response_winning_card), "Проверка: старшая карта масти захода должна быть сыграна.")
	assert(response_trick.get_winner_index() == 2, "Сброшенный Джокер не должен менять обычного победителя взятки.")

	var trump_response_player := Player.new(0, "Ответ козырем")
	var trump_joker := _create_card(Card.Suit.CLUBS, Card.Rank.SEVEN, true)
	var actual_trump_card := _create_card(Card.Suit.CLUBS, Card.Rank.EIGHT)
	var trump_leader := Player.new(1, "Заход козырем")
	var trump_lead_card := _create_card(Card.Suit.CLUBS, Card.Rank.KING)
	trump_response_player.receive_card(trump_joker)
	trump_response_player.receive_card(actual_trump_card)
	trump_leader.receive_card(trump_lead_card)

	var trump_trick := Trick.new()
	trump_trick.setup(1, 2, Round.TrumpSuit.CLUBS)
	assert(trump_trick.play_card(trump_leader, trump_lead_card), "Проверка: заход козырем должен быть сыгран.")
	assert(trump_trick.can_play_card(trump_response_player, trump_joker), "При заходе козырем Джокер должен быть доступен.")
	assert(trump_trick.can_play_card(trump_response_player, actual_trump_card), "Обычный козырь должен оставаться доступен.")

	var joker_leader := Player.new(0, "Джокер-заход")
	var forced_player := Player.new(1, "Старшая бубна")
	var leading_joker := _create_card(Card.Suit.CLUBS, Card.Rank.SEVEN, true)
	var diamond_queen := _create_card(Card.Suit.DIAMONDS, Card.Rank.QUEEN)
	var diamond_ace := _create_card(Card.Suit.DIAMONDS, Card.Rank.ACE)
	joker_leader.receive_card(leading_joker)
	forced_player.receive_card(diamond_queen)
	forced_player.receive_card(diamond_ace)

	var forced_trick := Trick.new()
	forced_trick.setup(0, 2, Round.TrumpSuit.DIAMONDS)
	assert(
		forced_trick.play_card(
			joker_leader,
			leading_joker,
			Trick.JokerMode.JOKER_WINS,
			Card.Suit.DIAMONDS,
			Trick.ForcedCardRank.HIGHEST
		),
		"Проверка: Джокер должен объявить старшую бубну."
	)
	assert(not forced_trick.can_play_card(forced_player, diamond_queen), "При заказе старшей бубны нельзя положить даму при наличии туза.")
	assert(forced_trick.can_play_card(forced_player, diamond_ace), "При заказе старшей бубны туз должен быть обязательным.")

	var free_trump_player := Player.new(1, "Свободный козырь")
	var heart_six := _create_card(Card.Suit.HEARTS, Card.Rank.SIX)
	var heart_ace := _create_card(Card.Suit.HEARTS, Card.Rank.ACE)
	free_trump_player.receive_card(heart_six)
	free_trump_player.receive_card(heart_ace)
	var free_trump_joker := _create_card(Card.Suit.CLUBS, Card.Rank.SEVEN, true)
	var free_trump_leader := Player.new(0, "Джокер-заход")
	free_trump_leader.receive_card(free_trump_joker)

	var free_trump_trick := Trick.new()
	free_trump_trick.setup(0, 2, Round.TrumpSuit.HEARTS)
	assert(
		free_trump_trick.play_card(
			free_trump_leader,
			free_trump_joker,
			Trick.JokerMode.JOKER_WINS,
			Card.Suit.SPADES,
			Trick.ForcedCardRank.HIGHEST
		),
		"Проверка: Джокер должен объявить старшую пику."
	)
	assert(free_trump_trick.can_play_card(free_trump_player, heart_six), "При отсутствии заказанной масти можно выбрать любой козырь.")
	assert(free_trump_trick.can_play_card(free_trump_player, heart_ace), "Старшинство обязательного козыря выбирается свободно.")

	var fallback_leader := Player.new(0, "Джокер-заход")
	var fallback_joker := _create_card(Card.Suit.CLUBS, Card.Rank.SEVEN, true)
	var fallback_first := Player.new(1, "Сброс 1")
	var fallback_second := Player.new(2, "Сброс 2")
	var fallback_third := Player.new(3, "Сброс 3")
	fallback_leader.receive_card(fallback_joker)
	fallback_first.receive_card(_create_card(Card.Suit.CLUBS, Card.Rank.SIX))
	fallback_second.receive_card(_create_card(Card.Suit.DIAMONDS, Card.Rank.EIGHT))
	fallback_third.receive_card(_create_card(Card.Suit.CLUBS, Card.Rank.JACK))

	var fallback_trick := Trick.new()
	fallback_trick.setup(0, 4, Round.TrumpSuit.HEARTS)
	assert(fallback_trick.play_card(fallback_leader, fallback_joker, Trick.JokerMode.NORMAL_CARD_WINS, Card.Suit.SPADES, Trick.ForcedCardRank.LOWEST), "Проверка: Джокер должен объявить младшую пику без взятки.")
	assert(fallback_trick.play_card(fallback_first, fallback_first.hand[0]), "Первый сброс должен быть допустим.")
	assert(fallback_trick.play_card(fallback_second, fallback_second.hand[0]), "Второй сброс должен быть допустим.")
	assert(fallback_trick.play_card(fallback_third, fallback_third.hand[0]), "Третий сброс должен быть допустим.")
	assert(fallback_trick.get_winner_index() == 0, "Если нет заказанной масти и козыря, Джокер должен забрать взятку.")

	var spade_leader := Player.new(0, "Джокер-заход")
	var spade_joker := _create_card(Card.Suit.CLUBS, Card.Rank.SEVEN, true)
	var spade_player := Player.new(1, "Шестёрка пик")
	var spade_discard_one := Player.new(2, "Сброс 1")
	var spade_discard_two := Player.new(3, "Сброс 2")
	spade_leader.receive_card(spade_joker)
	spade_player.receive_card(_create_card(Card.Suit.SPADES, Card.Rank.SIX))
	spade_discard_one.receive_card(_create_card(Card.Suit.CLUBS, Card.Rank.EIGHT))
	spade_discard_two.receive_card(_create_card(Card.Suit.DIAMONDS, Card.Rank.NINE))

	var spade_trick := Trick.new()
	spade_trick.setup(0, 4, Round.TrumpSuit.HEARTS)
	assert(spade_trick.play_card(spade_leader, spade_joker, Trick.JokerMode.NORMAL_CARD_WINS, Card.Suit.SPADES, Trick.ForcedCardRank.LOWEST), "Проверка: Джокер должен объявить младшую пику без взятки.")
	assert(spade_trick.play_card(spade_player, spade_player.hand[0]), "Шестёрка пик должна быть обязательной.")
	assert(spade_trick.play_card(spade_discard_one, spade_discard_one.hand[0]), "Первый сброс должен быть допустим.")
	assert(spade_trick.play_card(spade_discard_two, spade_discard_two.hand[0]), "Второй сброс должен быть допустим.")
	assert(spade_trick.get_winner_index() == 1, "Шестёрка пик должна перебивать виртуальную младшую пику Джокера.")


func _run_score_rule_checks() -> void:
	assert(
		ScoreCalculator.calculate_round_score(Round.RoundType.DARK, 3, 3) == 45,
		"Точный тёмный заказ должен давать +15 за каждую взятку."
	)
	assert(
		ScoreCalculator.calculate_round_score(Round.RoundType.DARK, 3, 2) == -10,
		"Недобор в тёмной раздаче должен штрафоваться на −10 за взятку."
	)
	assert(
		ScoreCalculator.calculate_round_score(Round.RoundType.DARK, 0, 0) == 50,
		"Нулевой тёмный заказ должен давать +50."
	)
	assert(
		ScoreCalculator.calculate_round_score(Round.RoundType.NO_TRUMP, 3, 3) == 45,
		"Точный заказ в бескозырке должен давать +15 за каждую взятку."
	)
	assert(
		ScoreCalculator.calculate_round_score(Round.RoundType.NO_TRUMP, 3, 2) == -10,
		"Недобор в бескозырке должен штрафоваться на −10 за взятку."
	)
	assert(
		ScoreCalculator.calculate_round_score(Round.RoundType.NO_TRUMP, 3, 4) == 1,
		"Перебор в бескозырке должен давать +1 за лишнюю взятку."
	)
	assert(
		ScoreCalculator.calculate_round_score(Round.RoundType.NO_TRUMP, 0, 0) == 5,
		"Нулевой заказ в бескозырке должен давать +5."
	)
	assert(
		ScoreCalculator.calculate_round_score(Round.RoundType.GOLDEN, 3, 3) == 60,
		"Золотая раздача должна давать +20 за каждую взятку."
	)
	assert(
		ScoreCalculator.calculate_round_score(Round.RoundType.GOLDEN, 0, 0) == -50,
		"Ноль взяток в золотой раздаче должен давать −50."
	)
	assert(
		ScoreCalculator.calculate_round_score(Round.RoundType.MISERE, 3, 3) == -60,
		"Мизерная раздача должна отнимать 20 за каждую взятку."
	)
	assert(
		ScoreCalculator.calculate_round_score(Round.RoundType.MISERE, 0, 0) == 50,
		"Ноль взяток в мизерной раздаче должен давать +50."
	)


func _run_dark_round_checks() -> void:
	var test_game := Game.new(["Игрок 1", "Игрок 2", "Игрок 3", "Игрок 4"])
	assert(
		test_game.start_round(9, Round.RoundType.DARK, Round.TrumpSuit.CLUBS, false),
		"Тёмная раздача должна запускаться без сдачи карт."
	)
	assert(not test_game.cards_are_dealt, "До заказов карты в тёмной раздаче должны быть скрыты.")

	for player in test_game.players:
		assert(player.hand.is_empty(), "До заказов у игрока не должно быть карт на руках.")

	for bid_number in test_game.players.size():
		var player_index := test_game.current_round.current_player_index
		assert(test_game.place_bid(player_index, 0), "Нулевой заказ должен быть допустим в тёмной раздаче.")

	assert(test_game.cards_are_dealt, "После последнего заказа карты должны быть сданы.")

	for player in test_game.players:
		assert(player.hand.size() == 9, "После заказов каждый игрок должен получить 9 карт.")


func _run_no_trump_round_checks() -> void:
	var test_game := Game.new(["Игрок 1", "Игрок 2", "Игрок 3", "Игрок 4"])
	assert(
		test_game.start_round(9, Round.RoundType.NO_TRUMP, Round.TrumpSuit.NONE),
		"Бескозырная раздача должна запускаться."
	)
	assert(test_game.cards_are_dealt, "В бескозырке карты должны быть сданы до заказов.")
	assert(test_game.current_round.state == Round.State.BIDDING, "В бескозырке должен быть этап заказов.")

	for player in test_game.players:
		assert(player.hand.size() == 9, "В бескозырке каждый игрок должен получить 9 карт.")

	for bid_number in test_game.players.size():
		var player_index := test_game.current_round.current_player_index
		assert(test_game.place_bid(player_index, 0), "Нулевой заказ должен быть допустим в бескозырке.")

	assert(test_game.current_round.state == Round.State.PLAYING, "После заказов бескозырка должна перейти к розыгрышу.")


func _run_no_bid_round_checks() -> void:
	_assert_no_bid_round(Round.RoundType.GOLDEN, "Золотая")
	_assert_no_bid_round(Round.RoundType.MISERE, "Мизерная")


func _assert_no_bid_round(round_type: Round.RoundType, mode_name: String) -> void:
	var test_game := Game.new(["Игрок 1", "Игрок 2", "Игрок 3", "Игрок 4"])
	assert(
		test_game.start_round(9, round_type, Round.TrumpSuit.CLUBS),
		"%s раздача должна запускаться." % mode_name
	)
	assert(test_game.cards_are_dealt, "%s раздача должна сразу раздать карты." % mode_name)
	assert(test_game.current_round.state == Round.State.PLAYING, "%s раздача должна сразу перейти к розыгрышу без заказов." % mode_name)

	for player in test_game.players:
		assert(player.hand.size() == 9, "%s: каждый игрок должен получить 9 карт." % mode_name)
		assert(player.bid == -1, "%s: у игрока не должно быть заказа." % mode_name)


func _run_round_history_checks() -> void:
	var original_actions: PackedStringArray = recent_actions.duplicate()
	recent_actions.clear()

	for action_number in 8:
		_add_history("Проверка журнала %d" % action_number)

	assert(recent_actions.size() == 8, "Проверка журнала: должны сохраняться все действия раздачи.")
	assert(recent_actions[0] == "Проверка журнала 0", "Проверка журнала: ранние действия не должны удаляться.")
	recent_actions = original_actions


func _run_hand_sort_checks() -> void:
	var diamond_six := _create_card(Card.Suit.DIAMONDS, Card.Rank.SIX)
	var heart_eight := _create_card(Card.Suit.HEARTS, Card.Rank.EIGHT)
	var spade_joker := _create_card(Card.Suit.SPADES, Card.Rank.SEVEN, true)
	var club_ace := _create_card(Card.Suit.CLUBS, Card.Rank.ACE)
	var club_eight := _create_card(Card.Suit.CLUBS, Card.Rank.EIGHT)
	var source_cards: Array[Card] = [diamond_six, heart_eight, spade_joker, club_ace, club_eight]
	var suit_sorted_cards := _sort_cards_for_display(source_cards, Round.TrumpSuit.CLUBS, HandSortMode.BY_SUIT)
	var trumps_left_cards := _sort_cards_for_display(source_cards, Round.TrumpSuit.CLUBS, HandSortMode.TRUMPS_LEFT)

	assert(suit_sorted_cards[0] == club_eight, "Проверка сортировки: при порядке по мастям первой должна быть младшая трефа.")
	assert(suit_sorted_cards[1] == club_ace, "Проверка сортировки: туз трефы должен идти после младшей трефы.")
	assert(trumps_left_cards[0] == spade_joker, "Проверка сортировки: Джокер должен быть слева.")
	assert(trumps_left_cards[1] == club_eight, "Проверка сортировки: козыри должны идти после Джокера.")
	assert(trumps_left_cards[2] == club_ace, "Проверка сортировки: козыри должны сохранять порядок по возрастанию.")
	assert(source_cards[0] == diamond_six, "Проверка сортировки: отображение не должно менять реальную руку.")


func _run_bot_rule_checks() -> void:
	var original_game := game
	var test_game := Game.new(["Игрок 1", "Игрок 2", "Игрок 3", "Игрок 4"])
	assert(
		test_game.start_round(9, Round.RoundType.NORMAL, Round.TrumpSuit.HEARTS),
		"Проверка бота: обычная раздача должна запускаться."
	)
	game = test_game

	var estimated_bid := _estimate_automatic_bid(game.players[1])
	assert(estimated_bid >= 0 and estimated_bid <= 9, "Проверка бота: оценка заказа должна быть в допустимом диапазоне.")

	while game.current_round.state == Round.State.BIDDING:
		var player_index := game.current_round.current_player_index
		var valid_bid := -1

		for bid in game.current_round.cards_per_player + 1:
			if game.current_round.can_place_bid(player_index, bid):
				valid_bid = bid
				break

		assert(valid_bid >= 0, "Проверка бота: должен существовать допустимый заказ.")
		assert(game.place_bid(player_index, valid_bid), "Проверка бота: допустимый заказ должен приниматься.")

	var lead_player_index := _get_current_player_index()
	var lead_player := game.players[lead_player_index]
	var lead_card := _select_non_joker_card_by_strength(lead_player.hand, false)
	assert(lead_card != null, "Проверка бота: у ведущего должна быть обычная карта.")
	assert(game.play_card(lead_player_index, lead_card), "Проверка бота: ведущая карта должна быть сыграна.")

	var response_player := game.players[_get_current_player_index()]
	var response_card := _choose_automatic_card(response_player)
	assert(response_card != null, "Проверка бота: бот должен выбрать карту в ответ.")
	assert(game.active_trick.can_play_card(response_player, response_card), "Проверка бота: выбранная карта должна быть допустима.")

	assert(test_game.start_round(9, Round.RoundType.GOLDEN, Round.TrumpSuit.CLUBS), "Проверка бота: золотая раздача должна запускаться.")
	assert(_bot_wants_trick(game.players[_get_current_player_index()]), "Проверка бота: в золотой раздаче бот должен стремиться брать взятки.")
	assert(test_game.start_round(9, Round.RoundType.MISERE, Round.TrumpSuit.CLUBS), "Проверка бота: мизерная раздача должна запускаться.")
	assert(not _bot_wants_trick(game.players[_get_current_player_index()]), "Проверка бота: в мизерной раздаче бот должен избегать взяток.")
	assert(test_game.start_round(9, Round.RoundType.DARK, Round.TrumpSuit.CLUBS, false), "Проверка бота: тёмная раздача должна запускаться.")
	var dark_player_index := game.current_round.current_player_index
	var dark_bid := _choose_automatic_bid(dark_player_index)
	assert(dark_bid >= 2 and dark_bid <= 4, "Проверка бота: тёмный заказ должен быть от 2 до 4.")
	assert(game.current_round.can_place_bid(dark_player_index, dark_bid), "Проверка бота: тёмный заказ должен быть допустим.")

	assert(test_game.start_round(1, Round.RoundType.NORMAL, Round.TrumpSuit.CLUBS), "Проверка бота: раздача для сохранения Джокера должна запускаться.")
	test_game.current_round.start_playing_without_bids()
	for player in test_game.players:
		player.hand.clear()

	var joker_check_leader_index: int = test_game.current_round.current_player_index
	var joker_check_bot_index: int = (joker_check_leader_index + 1) % test_game.players.size()
	var heart_lead := _create_card(Card.Suit.HEARTS, Card.Rank.NINE)
	var saving_trump := _create_card(Card.Suit.CLUBS, Card.Rank.EIGHT)
	var saving_joker := _create_card(Card.Suit.DIAMONDS, Card.Rank.SEVEN, true)
	test_game.players[joker_check_leader_index].receive_card(heart_lead)
	test_game.players[joker_check_bot_index].receive_card(saving_trump)
	test_game.players[joker_check_bot_index].receive_card(saving_joker)
	test_game.players[joker_check_bot_index].bid = 1
	assert(test_game.play_card(joker_check_leader_index, heart_lead), "Проверка бота: ведущая карта для сохранения Джокера должна быть сыграна.")
	var joker_saving_choice: Card = _choose_automatic_card(test_game.players[joker_check_bot_index])
	assert(joker_saving_choice == saving_trump, "Проверка бота: обычный козырь должен сохранять Джокера.")

	assert(test_game.start_round(1, Round.RoundType.NORMAL, Round.TrumpSuit.CLUBS), "Проверка бота: раздача для обязательного Джокера должна запускаться.")
	test_game.current_round.start_playing_without_bids()
	for player in test_game.players:
		player.hand.clear()

	joker_check_leader_index = test_game.current_round.current_player_index
	joker_check_bot_index = (joker_check_leader_index + 1) % test_game.players.size()
	var ace_trump_lead := _create_card(Card.Suit.CLUBS, Card.Rank.ACE)
	var losing_trump := _create_card(Card.Suit.CLUBS, Card.Rank.KING)
	var required_joker := _create_card(Card.Suit.DIAMONDS, Card.Rank.SEVEN, true)
	test_game.players[joker_check_leader_index].receive_card(ace_trump_lead)
	test_game.players[joker_check_bot_index].receive_card(losing_trump)
	test_game.players[joker_check_bot_index].receive_card(required_joker)
	test_game.players[joker_check_bot_index].bid = 1
	assert(test_game.play_card(joker_check_leader_index, ace_trump_lead), "Проверка бота: ведущий туз-козырь должен быть сыгран.")
	var joker_required_choice: Card = _choose_automatic_card(test_game.players[joker_check_bot_index])
	assert(joker_required_choice == required_joker, "Проверка бота: Джокер должен быть выбран, когда обычный козырь не перебивает взятку.")

	assert(test_game.start_round(1, Round.RoundType.MISERE, Round.TrumpSuit.CLUBS), "Проверка бота: мизерная раздача для сброса старшей карты должна запускаться.")
	for player in test_game.players:
		player.hand.clear()

	var misere_leader_index: int = test_game.current_round.current_player_index
	var misere_second_index: int = (misere_leader_index + 1) % test_game.players.size()
	var misere_third_index: int = (misere_leader_index + 2) % test_game.players.size()
	var misere_bot_index: int = (misere_leader_index + 3) % test_game.players.size()
	var nine_spades := _create_card(Card.Suit.SPADES, Card.Rank.NINE)
	var seven_spades := _create_card(Card.Suit.SPADES, Card.Rank.SEVEN)
	var six_spades := _create_card(Card.Suit.SPADES, Card.Rank.SIX)
	var ten_spades := _create_card(Card.Suit.SPADES, Card.Rank.TEN)
	var jack_spades := _create_card(Card.Suit.SPADES, Card.Rank.JACK)
	var king_spades := _create_card(Card.Suit.SPADES, Card.Rank.KING)
	test_game.players[misere_leader_index].receive_card(nine_spades)
	test_game.players[misere_second_index].receive_card(seven_spades)
	test_game.players[misere_third_index].receive_card(six_spades)
	test_game.players[misere_bot_index].receive_card(ten_spades)
	test_game.players[misere_bot_index].receive_card(jack_spades)
	test_game.players[misere_bot_index].receive_card(king_spades)
	assert(test_game.play_card(misere_leader_index, nine_spades), "Проверка бота: девятка пики должна быть сыграна.")
	assert(test_game.play_card(misere_second_index, seven_spades), "Проверка бота: семёрка пики должна быть сыграна.")
	assert(test_game.play_card(misere_third_index, six_spades), "Проверка бота: шестёрка пики должна быть сыграна.")
	var misere_choice: Card = _choose_automatic_card(test_game.players[misere_bot_index])
	assert(misere_choice == king_spades, "Проверка бота: в неизбежной мизерной взятке нужно сбрасывать старшую карту.")

	game = original_game


func _run_session_save_checks() -> void:
	var original_game := game
	var test_names: Array[String] = ["Тест 1", "Тест 2", "Тест 3", "Тест 4"]
	var test_game := Game.new(test_names)
	assert(test_game.start_round(2, Round.RoundType.NORMAL, Round.TrumpSuit.CLUBS), "Проверка сохранения: тестовая раздача должна запускаться.")
	test_game.current_round.start_playing_without_bids()
	game = test_game

	var leader_index := test_game.current_round.current_player_index
	var leading_card: Card = test_game.players[leader_index].hand[0]
	assert(test_game.play_card(leader_index, leading_card), "Проверка сохранения: первая карта должна сыграться.")

	var saved_game_data := _serialize_game_state()
	var restored_game := _deserialize_game_state(saved_game_data, test_names)
	assert(restored_game != null, "Проверка сохранения: состояние игры должно восстановиться.")
	assert(restored_game.players.size() == test_game.players.size(), "Проверка сохранения: число игроков должно сохраниться.")
	assert(restored_game.deck.cards.size() == test_game.deck.cards.size(), "Проверка сохранения: остаток колоды должен сохраниться.")
	assert(restored_game.active_trick != null, "Проверка сохранения: незавершённая взятка должна сохраниться.")
	assert(restored_game.active_trick.played_cards.size() == 1, "Проверка сохранения: карта на столе должна сохраниться.")
	assert(restored_game.players[leader_index].hand.size() == test_game.players[leader_index].hand.size(), "Проверка сохранения: рука игрока должна сохраниться.")

	game = original_game


func _create_card(suit: Card.Suit, rank: Card.Rank, is_joker := false) -> Card:
	var card := Card.new()
	card.suit = suit
	card.rank = rank
	card.is_joker = is_joker
	return card


func _clear_children(container: Container) -> void:
	for child in container.get_children():
		child.queue_free()
