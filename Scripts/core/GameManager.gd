extends Control


const PLAYER_NAMES := ["Андрей", "Олег", "Маша", "Лена"]
const HUMAN_PLAYER_INDEX := 0
const NORMAL_ROUND_COUNT := 13
const DARK_ROUND_COUNT := 5
const NO_TRUMP_ROUND_COUNT := 4
const GOLDEN_ROUND_COUNT := 5
const MISERE_ROUND_COUNT := 5
const TOTAL_ROUND_COUNT := NORMAL_ROUND_COUNT + DARK_ROUND_COUNT + NO_TRUMP_ROUND_COUNT + GOLDEN_ROUND_COUNT + MISERE_ROUND_COUNT
const CARD_FLY_DURATION := 0.32
const TRICK_WINNER_HOLD_DURATION := 0.7
const TRICK_COLLECTION_DURATION := 0.3
const BOT_SPEED_COUNT := 3
const BOT_DIFFICULTY_COUNT := 3
const SOUND_VOLUME_COUNT := 4
const MUSIC_VOLUME_COUNT := 4
const MUSIC_TRACK_COUNT := 3
const MAX_CUSTOM_MUSIC_FILE_SIZE_BYTES := 40 * 1024 * 1024
const MAX_PLAYER_NAME_LENGTH := 16
const MAX_MUSIC_TITLE_LENGTH := 26
const MUSIC_PLAYLIST_PAGE_SIZE := 25
const PROFILE_PLAYLIST_PREVIEW_COUNT := 20
const AUTO_TURN_DURATION_SECONDS := 60.0
const BUILT_IN_AVATAR_COUNT := 4
const CUSTOM_AVATAR_INDEX := BUILT_IN_AVATAR_COUNT
const HUMAN_AVATAR_COUNT := BUILT_IN_AVATAR_COUNT + 1
const PERSISTENT_SETTINGS_PATH := "user://project_joker_settings.cfg"
const SESSION_SAVE_PATH := "user://project_joker_session.save"
const SESSION_SAVE_VERSION := 1
const CUSTOM_PROFILE_AVATAR_PATH := "user://project_joker_profile_avatar.png"


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
@onready var music_player_panel: PanelContainer = %MusicPlayerPanel
@onready var music_track_label: Label = %MusicTrackLabel
@onready var music_previous_button: Button = %MusicPreviousButton
@onready var music_play_pause_button: Button = %MusicPlayPauseButton
@onready var music_next_button: Button = %MusicNextButton
@onready var music_playlist_button: Button = %MusicPlaylistButton
@onready var music_add_button: Button = %MusicAddButton
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
var player_score_labels: Array[Label] = []
var player_panels: Array[PanelContainer] = []
var avatar_badges: Array[PanelContainer] = []
var avatar_images: Array[TextureRect] = []
var avatar_labels: Array[Label] = []
var turn_timer_indicator: TurnTimerIndicator
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
var show_last_completed_trick := false
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
var tutorial_enabled := false
var auto_turn_enabled := false
var turn_timer_active := false
var turn_timer_remaining := AUTO_TURN_DURATION_SECONDS
var sound_volume_index := 2
var music_volume_index := 1
var music_volume_percent := 30
var music_track_index := 0
var music_is_paused := false
var music_player_hidden := false
var music_playback_position := 0.0
var music_repeat_enabled := false
var music_shuffle_enabled := false
var music_playlist_page := 0
var music_playlist_search_query := ""
var is_pause_menu_open := false
var configured_player_names: Array[String] = ["Андрей", "Олег", "Маша", "Лена"]
var configured_avatar_indices: Array[int] = [0, 1, 2, 3]
var custom_profile_avatar_path := ""
var new_game_name_inputs: Array[LineEdit] = []
var new_game_avatar_selectors: Array[OptionButton] = []
var new_game_bot_difficulty_selector: OptionButton
var profile_name_input: LineEdit
var profile_avatar_selector: OptionButton
var profile_avatar_status_label: Label
var profile_avatar_file_dialog: FileDialog
var pending_profile_avatar_path := ""
var is_avatar_file_dialog_for_new_game := false
var profile_music_status_label: Label
var profile_music_playlist_container: VBoxContainer
var profile_music_file_dialog: FileDialog
var is_music_file_dialog_opened_from_table := false
var last_music_import_status := ""
var sound_players: Array[AudioStreamPlayer] = []
var sound_streams: Dictionary = {}
var next_sound_player_index := 0
var background_music_player: AudioStreamPlayer
var background_music_streams: Array[AudioStreamWAV] = []
var custom_music_paths: Array[String] = []
var available_custom_music_paths: Array[String] = []
var loaded_custom_music_path := ""
var custom_music_stream: AudioStream
var music_controls_popup: PopupPanel
var music_popup_volume_label: Label
var music_popup_volume_slider: HSlider
var music_popup_repeat_button: Button
var music_popup_shuffle_button: Button
var music_popup_folder_button: Button
var music_popup_clear_button: Button
var music_popup_import_label: Label
var music_popup_search_input: LineEdit
var music_popup_previous_page_button: Button
var music_popup_next_page_button: Button
var music_popup_page_label: Label
var music_popup_playlist_container: VBoxContainer
var score_sheet_backdrop: ColorRect
var score_sheet_close_button: Button
var tutorial_panel: PanelContainer
var tutorial_title_label: Label
var tutorial_text_label: Label
var tutorial_disable_button: Button


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
	_create_score_sheet_overlay()
	_create_table_surface()
	_create_player_panels()
	_create_player_avatar_badges()
	_create_trick_slots()
	_create_bot_card_backs()
	_create_deck_visual()
	_create_table_markers()
	_create_sound_players()
	_create_background_music_player()
	music_player_panel.reparent(self)
	_set_control_layout(music_player_panel, 0.0, 1.0, 0.0, 1.0, 36.0, -102.0, 312.0, -24.0)
	music_player_panel.z_index = 90
	_create_music_controls_popup()
	_create_tutorial_panel()
	_create_profile_avatar_file_dialog()
	_create_profile_music_file_dialog()
	joker_controls.reparent(self)
	_create_main_menu()
	joker_controls.z_index = 80
	joker_controls.mouse_filter = Control.MOUSE_FILTER_PASS
	undo_button.pressed.connect(_on_undo_pressed)
	score_sheet_toggle_button.pressed.connect(_on_score_sheet_toggle_pressed)
	round_history_toggle_button.pressed.connect(_on_round_history_toggle_pressed)
	hand_sort_by_suit_button.pressed.connect(_on_hand_sort_by_suit_pressed)
	hand_sort_trumps_left_button.pressed.connect(_on_hand_sort_trumps_left_pressed)
	music_previous_button.pressed.connect(_on_music_previous_pressed)
	music_play_pause_button.pressed.connect(_on_music_play_pause_pressed)
	music_next_button.pressed.connect(_on_music_next_pressed)
	music_playlist_button.pressed.connect(_on_music_playlist_pressed)
	music_add_button.pressed.connect(_on_music_add_pressed)
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
	music_player_panel.add_theme_stylebox_override("panel", _create_flat_style(Color(0.012, 0.055, 0.034, 0.94), Color(0.38, 0.255, 0.11, 0.0), 0, 6, 0))
	round_results_panel.add_theme_stylebox_override("panel", _create_flat_style(Color(0.018, 0.08, 0.052, 0.97), Color(0.38, 0.255, 0.11, 0.78), 1, 10, 3))


func _create_table_surface() -> void:
	# Первый тестовый вариант стола: форму можно позднее заменить на квадратную,
	# не меняя расположение игроков и игровую логику.
	var outer_table := Panel.new()
	outer_table.name = "OvalTableOuter"
	outer_table.mouse_filter = Control.MOUSE_FILTER_IGNORE
	outer_table.add_theme_stylebox_override(
		"panel",
		_create_flat_style(Color(0.115, 0.062, 0.028, 1.0), Color(0.6, 0.39, 0.13, 1.0), 7, 286, 10)
	)
	_set_control_layout(outer_table, 0.5, 0.0, 0.5, 0.0, -660.0, 150.0, 660.0, 710.0)
	players_container.add_child(outer_table)

	var inner_table := Panel.new()
	inner_table.name = "OvalTableCloth"
	inner_table.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner_table.add_theme_stylebox_override(
		"panel",
		_create_flat_style(Color(0.035, 0.255, 0.145, 1.0), Color(0.74, 0.84, 0.66, 0.72), 3, 266, 0)
	)
	inner_table.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	inner_table.offset_left = 18.0
	inner_table.offset_top = 18.0
	inner_table.offset_right = -18.0
	inner_table.offset_bottom = -18.0
	outer_table.add_child(inner_table)


func _create_score_sheet_overlay() -> void:
	score_sheet_backdrop = ColorRect.new()
	score_sheet_backdrop.name = "ScoreSheetBackdrop"
	score_sheet_backdrop.color = Color(0.002, 0.012, 0.008, 0.74)
	score_sheet_backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	score_sheet_backdrop.z_index = 94
	score_sheet_backdrop.visible = false
	score_sheet_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	score_sheet_backdrop.gui_input.connect(_on_score_sheet_backdrop_gui_input)
	add_child(score_sheet_backdrop)

	# Расписка открывается отдельным плотным окном поверх стола,
	# чтобы таблицу можно было спокойно прочитать в любой момент партии.
	score_sheet_panel.reparent(self)
	score_sheet_panel.z_index = 95
	var score_sheet_style: StyleBoxFlat = _create_flat_style(Color(0.012, 0.07, 0.045, 1.0), Color(0.78, 0.62, 0.24, 1.0), 3, 14, 10)
	score_sheet_style.content_margin_left = 24.0
	score_sheet_style.content_margin_top = 20.0
	score_sheet_style.content_margin_right = 24.0
	score_sheet_style.content_margin_bottom = 20.0
	score_sheet_panel.add_theme_stylebox_override("panel", score_sheet_style)
	_set_control_layout(score_sheet_panel, 0.5, 0.5, 0.5, 0.5, -780.0, -450.0, 780.0, 450.0)

	score_sheet_close_button = Button.new()
	score_sheet_close_button.name = "ScoreSheetCloseButton"
	score_sheet_close_button.text = "Закрыть"
	score_sheet_close_button.custom_minimum_size = Vector2(0.0, 38.0)
	score_sheet_close_button.add_theme_font_size_override("font_size", 16)
	score_sheet_close_button.z_index = 96
	score_sheet_close_button.visible = false
	_set_control_layout(score_sheet_close_button, 0.5, 0.5, 0.5, 0.5, 584.0, -426.0, 744.0, -382.0)
	score_sheet_close_button.pressed.connect(_on_score_sheet_toggle_pressed)
	add_child(score_sheet_close_button)


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
	_stop_background_music()
	menu_overlay.visible = true
	_refresh_music_player()
	_build_main_menu_content()


func _hide_main_menu() -> void:
	menu_overlay.visible = false
	_start_background_music()
	_refresh_music_player()


func _build_main_menu_content() -> void:
	_clear_children(menu_content)
	_add_menu_title("PROJECT JOKER", "Локальная карточная партия для четырёх игроков")
	_add_menu_spacer(18.0)
	if _has_saved_session():
		_add_menu_button("Продолжить партию", _on_continue_saved_game_pressed, true)
	_add_menu_button("Новая партия", _show_new_game_setup, true)
	_add_menu_button("Обучение", _show_tutorial_menu)
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
	_add_menu_title("Новая партия", "Укажи имена и выбери аватары игроков")
	_add_menu_label("Для своего профиля можно сразу выбрать личную картинку или настроить её позже в разделе «Профиль».", 14, Color(0.72, 0.85, 0.76, 1.0))

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
	name_input.max_length = MAX_PLAYER_NAME_LENGTH
	name_input.custom_minimum_size = Vector2(200.0 if player_index == HUMAN_PLAYER_INDEX else 250.0, 38.0)
	name_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_input.add_theme_font_size_override("font_size", 17)
	row.add_child(name_input)
	new_game_name_inputs.append(name_input)

	var avatar_selector := OptionButton.new()
	avatar_selector.custom_minimum_size = Vector2(156.0, 38.0)
	avatar_selector.add_theme_font_size_override("font_size", 16)
	var avatar_option_count := HUMAN_AVATAR_COUNT if player_index == HUMAN_PLAYER_INDEX else BUILT_IN_AVATAR_COUNT
	for avatar_index in avatar_option_count:
		avatar_selector.add_item(_get_avatar_option_label(avatar_index))
	avatar_selector.selected = clampi(configured_avatar_indices[player_index], 0, avatar_option_count - 1)
	row.add_child(avatar_selector)
	new_game_avatar_selectors.append(avatar_selector)

	if player_index == HUMAN_PLAYER_INDEX:
		var upload_avatar_button := Button.new()
		upload_avatar_button.text = "Загрузить"
		upload_avatar_button.tooltip_text = "Выбрать свою картинку"
		upload_avatar_button.custom_minimum_size = Vector2(94.0, 38.0)
		upload_avatar_button.add_theme_font_size_override("font_size", 14)
		upload_avatar_button.pressed.connect(_open_new_game_avatar_file_dialog)
		row.add_child(upload_avatar_button)


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
		configured_player_names[player_index] = _sanitize_player_name(new_game_name_inputs[player_index].text, str(PLAYER_NAMES[player_index]))
		var max_avatar_index := CUSTOM_AVATAR_INDEX if player_index == HUMAN_PLAYER_INDEX else BUILT_IN_AVATAR_COUNT - 1
		configured_avatar_indices[player_index] = clampi(new_game_avatar_selectors[player_index].selected, 0, max_avatar_index)

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
		CUSTOM_AVATAR_INDEX:
			return "Своя картинка"

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


func _sanitize_player_name(value: String, fallback: String) -> String:
	var sanitized_name := value.strip_edges().left(MAX_PLAYER_NAME_LENGTH)
	return sanitized_name if not sanitized_name.is_empty() else fallback.left(MAX_PLAYER_NAME_LENGTH)


func _show_profile_menu() -> void:
	menu_overlay.visible = true
	_clear_children(menu_content)
	pending_profile_avatar_path = custom_profile_avatar_path
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
	profile_name_input.max_length = MAX_PLAYER_NAME_LENGTH
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
	for avatar_index in HUMAN_AVATAR_COUNT:
		profile_avatar_selector.add_item(_get_avatar_option_label(avatar_index))
	profile_avatar_selector.selected = clampi(configured_avatar_indices[HUMAN_PLAYER_INDEX], 0, CUSTOM_AVATAR_INDEX)
	profile_avatar_selector.item_selected.connect(_on_profile_avatar_selected)
	menu_content.add_child(profile_avatar_selector)

	profile_avatar_status_label = Label.new()
	profile_avatar_status_label.add_theme_font_size_override("font_size", 14)
	profile_avatar_status_label.add_theme_color_override("font_color", Color(0.72, 0.85, 0.76, 1.0))
	profile_avatar_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	menu_content.add_child(profile_avatar_status_label)
	_update_profile_avatar_status()

	_add_menu_button("Выбрать свою картинку", _open_profile_avatar_file_dialog)
	_add_menu_button("Вернуть стандартный аватар", _on_reset_profile_avatar_pressed)
	_add_menu_spacer(10.0)
	_add_menu_button("Музыка профиля", _show_music_profile_menu)
	_add_menu_button("Сохранить профиль", _save_profile, true)
	_add_menu_button("Назад", _return_from_menu_subpage)


func _save_profile() -> void:
	configured_player_names[HUMAN_PLAYER_INDEX] = _sanitize_player_name(profile_name_input.text, str(PLAYER_NAMES[HUMAN_PLAYER_INDEX]))
	var selected_avatar_index := clampi(profile_avatar_selector.selected, 0, CUSTOM_AVATAR_INDEX)
	if selected_avatar_index == CUSTOM_AVATAR_INDEX and pending_profile_avatar_path.is_empty():
		selected_avatar_index = 0

	configured_avatar_indices[HUMAN_PLAYER_INDEX] = selected_avatar_index
	custom_profile_avatar_path = pending_profile_avatar_path if selected_avatar_index == CUSTOM_AVATAR_INDEX else ""
	_save_persistent_settings()

	if game.current_round.state != Round.State.SETUP:
		game.players[HUMAN_PLAYER_INDEX].display_name = configured_player_names[HUMAN_PLAYER_INDEX]
		_save_current_session()
		_refresh_ui()

	if is_pause_menu_open:
		_build_pause_menu_content()
		return

	_build_main_menu_content()


func _create_profile_avatar_file_dialog() -> void:
	profile_avatar_file_dialog = FileDialog.new()
	profile_avatar_file_dialog.name = "ProfileAvatarFileDialog"
	profile_avatar_file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	profile_avatar_file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	profile_avatar_file_dialog.filters = PackedStringArray(["*.png,*.jpg,*.jpeg,*.webp;Изображения"])
	profile_avatar_file_dialog.file_selected.connect(_on_profile_avatar_file_selected)
	add_child(profile_avatar_file_dialog)


func _open_profile_avatar_file_dialog() -> void:
	is_avatar_file_dialog_for_new_game = false
	if profile_avatar_file_dialog != null:
		profile_avatar_file_dialog.popup_centered_ratio(0.75)


func _open_new_game_avatar_file_dialog() -> void:
	is_avatar_file_dialog_for_new_game = true
	if profile_avatar_file_dialog != null:
		profile_avatar_file_dialog.popup_centered_ratio(0.75)


func _on_profile_avatar_file_selected(source_path: String) -> void:
	var apply_to_new_game := is_avatar_file_dialog_for_new_game
	is_avatar_file_dialog_for_new_game = false
	var image: Image = Image.load_from_file(source_path)
	if image == null or image.is_empty():
		if is_instance_valid(profile_avatar_status_label):
			profile_avatar_status_label.text = "Не удалось прочитать картинку. Выбери PNG, JPG или WebP."
		return

	var largest_side := maxi(image.get_width(), image.get_height())
	if largest_side > 512:
		var resize_scale := 512.0 / float(largest_side)
		var resized_width := maxi(1, roundi(float(image.get_width()) * resize_scale))
		var resized_height := maxi(1, roundi(float(image.get_height()) * resize_scale))
		image.resize(resized_width, resized_height, Image.INTERPOLATE_LANCZOS)

	var local_avatar_path := ProjectSettings.globalize_path(CUSTOM_PROFILE_AVATAR_PATH)
	var save_result: Error = image.save_png(local_avatar_path)
	if save_result != OK or not FileAccess.file_exists(CUSTOM_PROFILE_AVATAR_PATH):
		if is_instance_valid(profile_avatar_status_label):
			profile_avatar_status_label.text = "Не удалось сохранить личный аватар."
		return

	if apply_to_new_game:
		custom_profile_avatar_path = CUSTOM_PROFILE_AVATAR_PATH
		configured_avatar_indices[HUMAN_PLAYER_INDEX] = CUSTOM_AVATAR_INDEX
		if new_game_avatar_selectors.size() > HUMAN_PLAYER_INDEX:
			new_game_avatar_selectors[HUMAN_PLAYER_INDEX].selected = CUSTOM_AVATAR_INDEX
		_save_persistent_settings()
		return

	pending_profile_avatar_path = CUSTOM_PROFILE_AVATAR_PATH
	if is_instance_valid(profile_avatar_selector):
		profile_avatar_selector.selected = CUSTOM_AVATAR_INDEX
	_update_profile_avatar_status()


func _on_profile_avatar_selected(selected_index: int) -> void:
	if selected_index != CUSTOM_AVATAR_INDEX:
		pending_profile_avatar_path = ""
	_update_profile_avatar_status()


func _on_reset_profile_avatar_pressed() -> void:
	pending_profile_avatar_path = ""
	if is_instance_valid(profile_avatar_selector):
		profile_avatar_selector.select(0)
	_update_profile_avatar_status()


func _update_profile_avatar_status() -> void:
	if not is_instance_valid(profile_avatar_status_label):
		return

	if not pending_profile_avatar_path.is_empty():
		profile_avatar_status_label.text = "Личная картинка готова. Нажми «Сохранить профиль», чтобы применить её."
	elif is_instance_valid(profile_avatar_selector) and profile_avatar_selector.selected == CUSTOM_AVATAR_INDEX:
		profile_avatar_status_label.text = "Сначала выбери файл PNG, JPG или WebP."
	else:
		profile_avatar_status_label.text = "Используется один из встроенных авторских аватаров."


func _create_profile_music_file_dialog() -> void:
	profile_music_file_dialog = FileDialog.new()
	profile_music_file_dialog.name = "ProfileMusicFileDialog"
	profile_music_file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILES
	profile_music_file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	profile_music_file_dialog.filters = PackedStringArray([
		"*.mp3;MP3",
		"*.ogg;Ogg Vorbis",
		"*.wav;WAV"
	])
	profile_music_file_dialog.files_selected.connect(_on_profile_music_files_selected)
	profile_music_file_dialog.dir_selected.connect(_on_profile_music_directory_selected)
	add_child(profile_music_file_dialog)


func _show_music_profile_menu() -> void:
	menu_overlay.visible = true
	_clear_children(menu_content)
	_add_menu_title("Музыка профиля", "Собери личный плейлист: он появится в плеере рядом с темами игры")
	_add_menu_label("Поддерживаются MP3, Ogg Vorbis и WAV до 40 МБ каждый. Файлы остаются на твоём компьютере: если переместить файл, игра просто пропустит его.", 14, Color(0.72, 0.85, 0.76, 1.0))
	_add_menu_spacer(10.0)

	profile_music_status_label = Label.new()
	profile_music_status_label.add_theme_font_size_override("font_size", 16)
	profile_music_status_label.add_theme_color_override("font_color", Color(0.91, 0.96, 0.91, 1.0))
	profile_music_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	menu_content.add_child(profile_music_status_label)
	_update_profile_music_status()

	var playlist_scroll := ScrollContainer.new()
	playlist_scroll.custom_minimum_size = Vector2(0.0, 180.0)
	playlist_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	playlist_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	menu_content.add_child(playlist_scroll)

	profile_music_playlist_container = VBoxContainer.new()
	profile_music_playlist_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	profile_music_playlist_container.add_theme_constant_override("separation", 6)
	playlist_scroll.add_child(profile_music_playlist_container)
	_refresh_profile_music_playlist()

	_add_menu_spacer(8.0)
	_add_menu_button("Добавить файлы", _open_profile_music_file_dialog, true)
	_add_menu_button("Добавить папку с музыкой", _on_profile_music_folder_pressed)
	_add_menu_button("Очистить плейлист", _on_clear_profile_music_pressed)
	_add_menu_button("Назад к профилю", _show_profile_menu)


func _open_profile_music_file_dialog() -> void:
	is_music_file_dialog_opened_from_table = false
	_open_music_files_dialog()


func _on_music_add_pressed() -> void:
	is_music_file_dialog_opened_from_table = true
	_open_music_files_dialog()


func _on_profile_music_folder_pressed() -> void:
	is_music_file_dialog_opened_from_table = false
	_open_music_folder_dialog()


func _on_music_popup_folder_pressed() -> void:
	is_music_file_dialog_opened_from_table = true
	_open_music_folder_dialog()


func _open_music_files_dialog() -> void:
	if profile_music_file_dialog != null:
		profile_music_file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILES
		profile_music_file_dialog.popup_centered_ratio(0.75)


func _open_music_folder_dialog() -> void:
	if profile_music_file_dialog != null:
		profile_music_file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_DIR
		profile_music_file_dialog.popup_centered_ratio(0.75)


func _on_profile_music_files_selected(selected_paths: PackedStringArray) -> void:
	var opened_from_table := is_music_file_dialog_opened_from_table
	is_music_file_dialog_opened_from_table = false
	var paths_to_add: Array[String] = []
	for selected_path in selected_paths:
		paths_to_add.append(selected_path)
	_add_custom_music_paths(paths_to_add, opened_from_table)


func _on_profile_music_directory_selected(selected_directory: String) -> void:
	var opened_from_table := is_music_file_dialog_opened_from_table
	is_music_file_dialog_opened_from_table = false
	var directory := DirAccess.open(selected_directory)
	if directory == null:
		_report_music_import("Не удалось открыть выбранную папку.", opened_from_table)
		return

	var paths_to_add: Array[String] = []
	for file_name in directory.get_files():
		var file_path := selected_directory.path_join(file_name)
		if file_path.get_extension().to_lower() in ["mp3", "ogg", "wav"]:
			paths_to_add.append(file_path)
	paths_to_add.sort()

	if paths_to_add.is_empty():
		_report_music_import("В папке не найдено MP3, Ogg Vorbis или WAV-файлов.", opened_from_table)
		return

	_add_custom_music_paths(paths_to_add, opened_from_table)


func _add_custom_music_paths(paths_to_add: Array[String], opened_from_table: bool) -> void:
	var added_paths: Array[String] = []
	var skipped_count := 0

	for music_path in paths_to_add:
		if custom_music_paths.has(music_path) or not _is_custom_music_path_supported(music_path):
			skipped_count += 1
			continue

		custom_music_paths.append(music_path)
		available_custom_music_paths.append(music_path)
		added_paths.append(music_path)

	if added_paths.is_empty():
		_report_music_import("Ни одного нового подходящего трека не добавлено.", opened_from_table)
		return

	var first_added_path: String = added_paths[0]
	loaded_custom_music_path = ""
	custom_music_stream = null
	music_track_index = MUSIC_TRACK_COUNT + available_custom_music_paths.find(first_added_path)
	music_is_paused = false
	music_playback_position = 0.0
	music_playlist_page = 0
	music_playlist_search_query = ""
	_apply_selected_music_track()
	if not menu_overlay.visible:
		_start_background_music()
	_save_persistent_settings()
	_update_profile_music_status()
	_refresh_profile_music_playlist()
	_refresh_music_player()
	_refresh_music_controls_popup()

	var summary := "Добавлено: %d · пропущено: %d." % [added_paths.size(), skipped_count]
	_report_music_import(summary, opened_from_table)


func _report_music_import(status: String, opened_from_table: bool) -> void:
	if not opened_from_table and is_instance_valid(profile_music_status_label) and profile_music_status_label.is_inside_tree():
		profile_music_status_label.text = status
		return

	last_music_import_status = status
	_open_music_controls_popup()


func _on_clear_profile_music_pressed() -> void:
	custom_music_paths.clear()
	available_custom_music_paths.clear()
	loaded_custom_music_path = ""
	custom_music_stream = null
	music_playlist_page = 0
	music_playlist_search_query = ""
	last_music_import_status = "Личный плейлист очищен."
	if music_track_index >= MUSIC_TRACK_COUNT:
		music_track_index = 0
	_apply_selected_music_track()
	_save_persistent_settings()
	_update_profile_music_status()
	_refresh_profile_music_playlist()
	_refresh_music_player()
	_refresh_music_controls_popup()


func _on_remove_profile_music_pressed(track_path: String) -> void:
	custom_music_paths.erase(track_path)
	available_custom_music_paths.erase(track_path)
	if loaded_custom_music_path == track_path:
		loaded_custom_music_path = ""
		custom_music_stream = null
	_ensure_valid_music_track_index()
	music_playlist_page = 0
	_apply_selected_music_track()
	_save_persistent_settings()
	_update_profile_music_status()
	_refresh_profile_music_playlist()
	_refresh_music_player()
	_refresh_music_controls_popup()


func _update_profile_music_status() -> void:
	if not is_instance_valid(profile_music_status_label):
		return

	if custom_music_paths.is_empty():
		profile_music_status_label.text = "Сейчас доступны только три встроенные темы игры."
		return

	var available_track_count := _get_available_custom_music_paths().size()
	profile_music_status_label.text = "В плейлисте: %d · доступны сейчас: %d." % [custom_music_paths.size(), available_track_count]


func _refresh_profile_music_playlist() -> void:
	if not is_instance_valid(profile_music_playlist_container):
		return

	_clear_children(profile_music_playlist_container)
	if custom_music_paths.is_empty():
		var empty_label := Label.new()
		empty_label.text = "Личных треков пока нет."
		empty_label.add_theme_font_size_override("font_size", 15)
		empty_label.add_theme_color_override("font_color", Color(0.72, 0.85, 0.76, 1.0))
		profile_music_playlist_container.add_child(empty_label)
		return

	var preview_count := mini(custom_music_paths.size(), PROFILE_PLAYLIST_PREVIEW_COUNT)
	for preview_index in preview_count:
		var track_path: String = custom_music_paths[preview_index]
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		profile_music_playlist_container.add_child(row)

		var track_label := Label.new()
		track_label.text = "♫ %s%s" % [_shorten_music_title(track_path.get_file()), "" if _is_custom_music_path_supported(track_path) else " — файл не найден"]
		track_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		track_label.clip_text = true
		track_label.tooltip_text = track_path
		track_label.add_theme_font_size_override("font_size", 15)
		track_label.add_theme_color_override("font_color", Color(0.91, 0.96, 0.91, 1.0) if _is_custom_music_path_supported(track_path) else Color(0.9, 0.66, 0.48, 1.0))
		row.add_child(track_label)

		var remove_button := Button.new()
		remove_button.text = "Убрать"
		remove_button.custom_minimum_size = Vector2(82.0, 32.0)
		remove_button.add_theme_font_size_override("font_size", 14)
		remove_button.pressed.connect(_on_remove_profile_music_pressed.bind(track_path))
		row.add_child(remove_button)

	if custom_music_paths.size() > preview_count:
		var remaining_label := Label.new()
		remaining_label.text = "…ещё %d треков. Полный список с поиском — в плеере за столом." % (custom_music_paths.size() - preview_count)
		remaining_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		remaining_label.add_theme_font_size_override("font_size", 14)
		remaining_label.add_theme_color_override("font_color", Color(0.72, 0.85, 0.76, 1.0))
		profile_music_playlist_container.add_child(remaining_label)


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


func _show_tutorial_menu() -> void:
	if menu_overlay != null:
		menu_overlay.visible = true
	_clear_children(menu_content)
	_add_menu_title("Обучение", "Короткие подсказки помогают освоиться за столом и не блокируют игру")
	_add_menu_label("Сейчас подсказки: %s." % ("включены" if tutorial_enabled else "выключены"), 16, Color(0.97, 0.86, 0.55, 1.0))
	_add_menu_label("• Заказы: перед розыгрышем назови, сколько взяток планируешь взять.", 16)
	_add_menu_label("• Розыгрыш: если масть захода есть на руке, её нужно положить. Если масти нет — действуют правила козыря и Джокера.", 16)
	_add_menu_label("• Джокер: при первом ходе можно объявить масть и условие; в середине взятки он может забирать или быть сбросом.", 16)
	_add_menu_label("• После раздачи сверяй заказ, взятые карты и очки в итогах справа или в расписке.", 16)
	_add_menu_spacer(10.0)
	_add_menu_button("Включить подсказки", _on_tutorial_enable_pressed)
	_add_menu_button("Отключить подсказки", _on_tutorial_disable_pressed)
	_add_menu_button("Назад", _return_from_menu_subpage, true)
	_refresh_tutorial_panel()


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

	var music_label := Label.new()
	music_label.text = "Громкость музыки"
	music_label.add_theme_font_size_override("font_size", 18)
	music_label.add_theme_color_override("font_color", Color(0.91, 0.96, 0.91, 1.0))
	menu_content.add_child(music_label)

	var music_selector := OptionButton.new()
	music_selector.add_item("Без музыки")
	music_selector.add_item("Тихо")
	music_selector.add_item("Обычно")
	music_selector.add_item("Громко")
	music_selector.selected = music_volume_index
	music_selector.custom_minimum_size = Vector2(0.0, 42.0)
	music_selector.add_theme_font_size_override("font_size", 17)
	music_selector.item_selected.connect(_on_music_volume_selected)
	menu_content.add_child(music_selector)

	var tutorial_toggle := CheckButton.new()
	tutorial_toggle.text = "Режим обучения: подсказки на столе"
	tutorial_toggle.button_pressed = tutorial_enabled
	tutorial_toggle.add_theme_font_size_override("font_size", 18)
	tutorial_toggle.add_theme_color_override("font_color", Color(0.91, 0.96, 0.91, 1.0))
	tutorial_toggle.toggled.connect(_on_tutorial_toggled)
	menu_content.add_child(tutorial_toggle)

	var auto_turn_toggle := CheckButton.new()
	auto_turn_toggle.text = "Автоход по таймеру: 60 секунд"
	auto_turn_toggle.button_pressed = auto_turn_enabled
	auto_turn_toggle.add_theme_font_size_override("font_size", 18)
	auto_turn_toggle.add_theme_color_override("font_color", Color(0.91, 0.96, 0.91, 1.0))
	auto_turn_toggle.toggled.connect(_on_auto_turn_toggled)
	menu_content.add_child(auto_turn_toggle)
	_add_menu_label("Если время твоего решения выйдет, игра выберет корректный заказ, карту или условие Джокера по уровню ботов.", 14, Color(0.72, 0.85, 0.76, 1.0))

	_add_menu_button("Начать обучение заново", _on_tutorial_enable_pressed)
	_add_menu_label("Подсказки не мешают игре и всегда доступны из настроек или меню паузы.", 14, Color(0.72, 0.85, 0.76, 1.0))
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
	_add_menu_button("Показать аудиоплеер" if music_player_hidden else "Скрыть аудиоплеер", _on_music_player_visibility_toggle_pressed)
	_add_menu_button("Обучение", _show_tutorial_menu)
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


func _on_tutorial_toggled(enabled: bool) -> void:
	tutorial_enabled = enabled
	_save_persistent_settings()
	_refresh_tutorial_panel()


func _on_auto_turn_toggled(enabled: bool) -> void:
	auto_turn_enabled = enabled
	_save_persistent_settings()

	if auto_turn_enabled:
		_start_human_turn_timer()
	else:
		_stop_human_turn_timer()

	_refresh_ui()


func _on_tutorial_enable_pressed() -> void:
	tutorial_enabled = true
	_save_persistent_settings()
	_refresh_tutorial_panel()
	if menu_overlay != null and menu_overlay.visible:
		_show_tutorial_menu()


func _on_tutorial_disable_pressed() -> void:
	tutorial_enabled = false
	_save_persistent_settings()
	_refresh_tutorial_panel()
	if menu_overlay != null and menu_overlay.visible:
		_show_tutorial_menu()


func _on_bot_speed_selected(selected_index: int) -> void:
	bot_speed_index = clampi(selected_index, 0, BOT_SPEED_COUNT - 1)
	_save_persistent_settings()


func _on_sound_volume_selected(selected_index: int) -> void:
	sound_volume_index = clampi(selected_index, 0, SOUND_VOLUME_COUNT - 1)
	_apply_sound_volume()
	_save_persistent_settings()


func _on_music_volume_selected(selected_index: int) -> void:
	music_volume_index = clampi(selected_index, 0, MUSIC_VOLUME_COUNT - 1)
	music_volume_percent = _get_music_volume_percent_for_index(music_volume_index)
	_apply_music_volume()
	if music_volume_percent == 0:
		_stop_background_music()
	elif not menu_overlay.visible:
		_start_background_music()
	_save_persistent_settings()
	_refresh_music_player()
	_refresh_music_controls_popup()


func _on_music_previous_pressed() -> void:
	_select_music_track(-1)


func _on_music_play_pause_pressed() -> void:
	if music_is_paused:
		music_is_paused = false
		if not menu_overlay.visible:
			_start_background_music()
	else:
		if background_music_player != null and background_music_player.playing:
			music_playback_position = background_music_player.get_playback_position()
		music_is_paused = true
		_stop_background_music()
	_save_persistent_settings()
	_refresh_music_player()


func _on_music_next_pressed() -> void:
	_select_music_track(1)


func _on_music_repeat_pressed() -> void:
	music_repeat_enabled = not music_repeat_enabled
	_save_persistent_settings()
	_refresh_music_controls_popup()


func _on_music_shuffle_pressed() -> void:
	music_shuffle_enabled = not music_shuffle_enabled
	_save_persistent_settings()
	_refresh_music_controls_popup()


func _on_music_playlist_search_changed(search_text: String) -> void:
	music_playlist_search_query = search_text.strip_edges().to_lower()
	music_playlist_page = 0
	_refresh_music_controls_popup()


func _on_music_playlist_previous_page_pressed() -> void:
	music_playlist_page = maxi(0, music_playlist_page - 1)
	_refresh_music_controls_popup()


func _on_music_playlist_next_page_pressed() -> void:
	var filtered_track_indices := _get_filtered_music_track_indices()
	var total_pages: int = maxi(1, ceili(float(filtered_track_indices.size()) / float(MUSIC_PLAYLIST_PAGE_SIZE)))
	music_playlist_page = mini(total_pages - 1, music_playlist_page + 1)
	_refresh_music_controls_popup()


func _on_music_playlist_pressed() -> void:
	if music_controls_popup == null:
		return

	if music_controls_popup.visible:
		music_controls_popup.hide()
		return

	_open_music_controls_popup()


func _open_music_controls_popup() -> void:
	if music_controls_popup == null:
		return

	_refresh_music_controls_popup()
	var popup_size := Vector2i(340, 610)
	var popup_top := maxi(20, roundi(get_viewport_rect().size.y - float(popup_size.y) - 118.0))
	music_controls_popup.popup(Rect2i(Vector2i(36, popup_top), popup_size))


func _on_music_volume_slider_changed(value: float) -> void:
	music_volume_percent = clampi(roundi(value), 0, 100)
	music_volume_index = _get_music_volume_index_for_percent(music_volume_percent)
	_apply_music_volume()
	if music_volume_percent == 0:
		_stop_background_music()
	elif not menu_overlay.visible and not music_is_paused:
		_start_background_music()
	_save_persistent_settings()
	_refresh_music_player()
	_refresh_music_controls_popup()


func _on_music_popup_track_pressed(selected_index: int) -> void:
	if selected_index < 0 or selected_index >= _get_available_music_track_count():
		return

	music_track_index = selected_index
	music_is_paused = false
	music_playback_position = 0.0
	_apply_selected_music_track()
	if not menu_overlay.visible:
		_start_background_music()
	_save_persistent_settings()
	_refresh_music_player()
	_refresh_music_controls_popup()
	if music_controls_popup != null:
		music_controls_popup.hide()


func _select_music_track(direction: int) -> void:
	var available_track_count := _get_available_music_track_count()
	music_track_index += direction
	if music_track_index < 0:
		music_track_index = available_track_count - 1
	elif music_track_index >= available_track_count:
		music_track_index = 0

	music_playback_position = 0.0
	_apply_selected_music_track()
	if not menu_overlay.visible and not music_is_paused:
		_start_background_music()
	_save_persistent_settings()
	_refresh_music_player()
	_refresh_music_controls_popup()


func _load_persistent_settings() -> void:
	var config := ConfigFile.new()
	if config.load(PERSISTENT_SETTINGS_PATH) != OK:
		return

	for player_index in PLAYER_NAMES.size():
		var saved_name: String = str(config.get_value("players", "name_%d" % player_index, configured_player_names[player_index]))
		configured_player_names[player_index] = _sanitize_player_name(saved_name, str(PLAYER_NAMES[player_index]))
		var saved_avatar: int = int(config.get_value("players", "avatar_%d" % player_index, configured_avatar_indices[player_index]))
		var max_avatar_index := CUSTOM_AVATAR_INDEX if player_index == HUMAN_PLAYER_INDEX else BUILT_IN_AVATAR_COUNT - 1
		configured_avatar_indices[player_index] = clampi(saved_avatar, 0, max_avatar_index)

	var saved_custom_avatar_path: String = str(config.get_value("players", "custom_avatar_path", ""))
	if saved_custom_avatar_path.begins_with("user://") and FileAccess.file_exists(saved_custom_avatar_path):
		custom_profile_avatar_path = saved_custom_avatar_path
	else:
		custom_profile_avatar_path = ""

	if configured_avatar_indices[HUMAN_PLAYER_INDEX] == CUSTOM_AVATAR_INDEX and custom_profile_avatar_path.is_empty():
		configured_avatar_indices[HUMAN_PLAYER_INDEX] = 0

	var saved_difficulty: int = int(config.get_value("game", "bot_difficulty", BotDifficulty.NORMAL))
	bot_difficulty = clampi(saved_difficulty, 0, BOT_DIFFICULTY_COUNT - 1)
	var saved_speed: int = int(config.get_value("game", "bot_speed", bot_speed_index))
	bot_speed_index = clampi(saved_speed, 0, BOT_SPEED_COUNT - 1)
	tutorial_enabled = bool(config.get_value("game", "tutorial_enabled", tutorial_enabled))
	auto_turn_enabled = bool(config.get_value("game", "auto_turn_enabled", auto_turn_enabled))
	var saved_sound_volume: int = int(config.get_value("audio", "sound_volume", sound_volume_index))
	sound_volume_index = clampi(saved_sound_volume, 0, SOUND_VOLUME_COUNT - 1)
	var saved_music_volume: int = int(config.get_value("audio", "music_volume", music_volume_index))
	music_volume_index = clampi(saved_music_volume, 0, MUSIC_VOLUME_COUNT - 1)
	var saved_music_percent: int = int(config.get_value("audio", "music_volume_percent", -1))
	music_volume_percent = clampi(saved_music_percent, 0, 100) if saved_music_percent >= 0 else _get_music_volume_percent_for_index(music_volume_index)
	music_volume_index = _get_music_volume_index_for_percent(music_volume_percent)
	var saved_music_track: int = int(config.get_value("audio", "music_track", music_track_index))
	music_track_index = maxi(0, saved_music_track)
	music_is_paused = bool(config.get_value("audio", "music_paused", false))
	music_player_hidden = bool(config.get_value("audio", "music_player_hidden", false))
	music_repeat_enabled = bool(config.get_value("audio", "music_repeat", false))
	music_shuffle_enabled = bool(config.get_value("audio", "music_shuffle", false))
	custom_music_paths.clear()
	var saved_custom_music_paths: Variant = config.get_value("audio", "custom_music_paths", PackedStringArray())
	if saved_custom_music_paths is PackedStringArray or saved_custom_music_paths is Array:
		for saved_path_variant in saved_custom_music_paths:
			var saved_path := str(saved_path_variant)
			if not saved_path.is_empty() and not custom_music_paths.has(saved_path):
				custom_music_paths.append(saved_path)

	if custom_music_paths.is_empty():
		var legacy_custom_music_path := str(config.get_value("audio", "custom_music_path", ""))
		if not legacy_custom_music_path.is_empty():
			custom_music_paths.append(legacy_custom_music_path)
	_refresh_available_custom_music_paths()

	var fullscreen_enabled: bool = bool(config.get_value("display", "fullscreen", false))
	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen_enabled else DisplayServer.WINDOW_MODE_MAXIMIZED
	)


func _save_persistent_settings() -> void:
	var config := ConfigFile.new()

	for player_index in PLAYER_NAMES.size():
		config.set_value("players", "name_%d" % player_index, configured_player_names[player_index])
		config.set_value("players", "avatar_%d" % player_index, configured_avatar_indices[player_index])
	config.set_value("players", "custom_avatar_path", custom_profile_avatar_path)

	config.set_value("game", "bot_difficulty", bot_difficulty)
	config.set_value("game", "bot_speed", bot_speed_index)
	config.set_value("game", "tutorial_enabled", tutorial_enabled)
	config.set_value("game", "auto_turn_enabled", auto_turn_enabled)
	config.set_value("audio", "sound_volume", sound_volume_index)
	config.set_value("audio", "music_volume", music_volume_index)
	config.set_value("audio", "music_volume_percent", music_volume_percent)
	config.set_value("audio", "music_track", music_track_index)
	config.set_value("audio", "music_paused", music_is_paused)
	config.set_value("audio", "music_player_hidden", music_player_hidden)
	config.set_value("audio", "music_repeat", music_repeat_enabled)
	config.set_value("audio", "music_shuffle", music_shuffle_enabled)
	var saved_custom_music_paths := PackedStringArray()
	for custom_music_path in custom_music_paths:
		saved_custom_music_paths.append(custom_music_path)
	config.set_value("audio", "custom_music_paths", saved_custom_music_paths)
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
		var restored_name: String = str(saved_names[player_index])
		configured_player_names.append(_sanitize_player_name(restored_name, str(PLAYER_NAMES[player_index])))
		var max_avatar_index := CUSTOM_AVATAR_INDEX if player_index == HUMAN_PLAYER_INDEX else BUILT_IN_AVATAR_COUNT - 1
		configured_avatar_indices.append(clampi(int(saved_avatars[player_index]), 0, max_avatar_index))

	if configured_avatar_indices[HUMAN_PLAYER_INDEX] == CUSTOM_AVATAR_INDEX and custom_profile_avatar_path.is_empty():
		configured_avatar_indices[HUMAN_PLAYER_INDEX] = 0

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
		_write_pcm_sample(data, sample_index, sample)

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


func _create_background_music_player() -> void:
	background_music_player = AudioStreamPlayer.new()
	background_music_player.name = "BackgroundMusicPlayer"
	background_music_player.bus = &"Master"
	for track_index in MUSIC_TRACK_COUNT:
		background_music_streams.append(_create_background_music_stream(track_index))
	_ensure_valid_music_track_index()
	background_music_player.stream = _get_selected_music_stream()
	background_music_player.finished.connect(_on_background_music_finished)
	add_child(background_music_player)
	_apply_music_volume()


func _create_background_music_stream(track_index: int) -> AudioStreamWAV:
	var mix_rate := 22050
	var duration := 12.0
	var sample_count: int = roundi(duration * mix_rate)
	var data := PackedByteArray()
	data.resize(sample_count * 2)
	var chords: Array[Array] = []
	var step_duration := 0.5
	var pad_gain := 0.1
	var arpeggio_gain := 0.075
	var bass_gain := 0.045

	match track_index:
		1:
			chords = [
				[146.83, 174.61, 220.0, 293.66],
				[110.0, 146.83, 174.61, 220.0],
				[130.81, 164.81, 196.0, 261.63],
				[123.47, 146.83, 196.0, 246.94]
			]
			step_duration = 0.75
			pad_gain = 0.085
			arpeggio_gain = 0.06
			bass_gain = 0.055
		2:
			chords = [
				[196.0, 246.94, 293.66, 392.0],
				[174.61, 220.0, 261.63, 349.23],
				[164.81, 207.65, 246.94, 329.63],
				[146.83, 196.0, 246.94, 293.66]
			]
			step_duration = 0.375
			pad_gain = 0.07
			arpeggio_gain = 0.09
			bass_gain = 0.035
		_:
			chords = [
				[164.81, 196.0, 246.94, 293.66],
				[130.81, 164.81, 196.0, 261.63],
				[196.0, 246.94, 293.66, 392.0],
				[146.83, 174.61, 220.0, 293.66]
			]

	var chord_duration := duration / float(chords.size())

	for sample_index in sample_count:
		var time: float = float(sample_index) / float(mix_rate)
		var progress: float = time / duration
		var chord_index: int = mini(int(time / chord_duration), chords.size() - 1)
		var chord: Array = chords[chord_index]
		var chord_time := fmod(time, chord_duration)
		var chord_fade := sin(PI * chord_time / chord_duration)
		var pad := 0.0
		for note in chord:
			pad += sin(TAU * float(note) * time)
		pad /= float(chord.size())

		var step_index: int = int(time / step_duration) % chord.size()
		var step_time := fmod(time, step_duration)
		var arpeggio_envelope := pow(sin(PI * step_time / step_duration), 1.6)
		var arpeggio := sin(TAU * float(chord[step_index]) * 2.0 * time) * arpeggio_envelope
		if track_index == 1:
			arpeggio = (arpeggio * 0.72 + sin(TAU * float(chord[step_index]) * 3.0 * time) * 0.28 * arpeggio_envelope)
		elif track_index == 2:
			arpeggio = sin(TAU * float(chord[step_index]) * 3.0 * time) * arpeggio_envelope
		var bass := sin(TAU * float(chord[0]) * 0.5 * time)
		var loop_fade := pow(sin(PI * progress), 0.5)
		var sample: float = (pad * pad_gain * chord_fade + arpeggio * arpeggio_gain + bass * bass_gain) * loop_fade
		_write_pcm_sample(data, sample_index, sample)

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = mix_rate
	stream.stereo = false
	stream.loop_mode = AudioStreamWAV.LOOP_DISABLED
	stream.loop_begin = 0
	stream.loop_end = sample_count
	stream.data = data
	return stream


func _write_pcm_sample(data: PackedByteArray, sample_index: int, sample: float) -> void:
	var sample_value: int = clampi(roundi(clampf(sample, -1.0, 1.0) * 32767.0), -32767, 32767)
	var unsigned_sample: int = sample_value if sample_value >= 0 else sample_value + 65536
	data[sample_index * 2] = unsigned_sample & 0xff
	data[sample_index * 2 + 1] = (unsigned_sample >> 8) & 0xff


func _start_background_music() -> void:
	if background_music_player == null or music_volume_percent == 0 or music_is_paused or background_music_player.playing:
		return

	background_music_player.play(music_playback_position)
	music_playback_position = 0.0


func _stop_background_music() -> void:
	if background_music_player != null:
		background_music_player.stop()


func _apply_selected_music_track() -> void:
	if background_music_player == null or background_music_streams.is_empty():
		return

	_ensure_valid_music_track_index()
	_stop_background_music()
	music_playback_position = 0.0
	background_music_player.stream = _get_selected_music_stream()


func _on_background_music_finished() -> void:
	if music_is_paused or menu_overlay.visible:
		return

	if music_repeat_enabled:
		background_music_player.play()
		return

	var available_track_count := _get_available_music_track_count()
	if available_track_count <= 0:
		return

	if music_shuffle_enabled and available_track_count > 1:
		var next_track_index := music_track_index
		while next_track_index == music_track_index:
			next_track_index = bot_random.randi_range(0, available_track_count - 1)
		music_track_index = next_track_index
	else:
		music_track_index = (music_track_index + 1) % available_track_count

	music_playback_position = 0.0
	_apply_selected_music_track()
	_start_background_music()
	_save_persistent_settings()
	_refresh_music_player()
	_refresh_music_controls_popup()


func _apply_music_volume() -> void:
	if background_music_player != null:
		background_music_player.volume_db = _get_music_volume_db()


func _get_music_volume_db() -> float:
	if music_volume_percent <= 0:
		return -80.0

	return lerpf(-36.0, -15.0, float(music_volume_percent) / 100.0)


func _get_music_volume_percent_for_index(selected_index: int) -> int:
	match selected_index:
		0:
			return 0
		1:
			return 30
		2:
			return 60
		3:
			return 100

	return 30


func _get_music_volume_index_for_percent(percent: int) -> int:
	if percent <= 0:
		return 0
	if percent <= 35:
		return 1
	if percent <= 75:
		return 2
	return 3


func _get_music_track_label() -> String:
	return _get_music_track_label_for_index(music_track_index)


func _get_music_track_label_for_index(track_index: int) -> String:
	return _shorten_music_title(_get_full_music_track_label_for_index(track_index))


func _get_full_music_track_label_for_index(track_index: int) -> String:
	if track_index >= MUSIC_TRACK_COUNT:
		var custom_track_index := track_index - MUSIC_TRACK_COUNT
		var available_custom_tracks := _get_available_custom_music_paths()
		if custom_track_index >= 0 and custom_track_index < available_custom_tracks.size():
			return available_custom_tracks[custom_track_index].get_file()

	match track_index:
		1:
			return "Ночная колода"
		2:
			return "Тёплый круг"

	return "Тихий стол"


func _shorten_music_title(title: String) -> String:
	if title.length() <= MAX_MUSIC_TITLE_LENGTH:
		return title

	return "%s…" % title.left(MAX_MUSIC_TITLE_LENGTH - 1)


func _get_filtered_music_track_indices() -> Array[int]:
	var filtered_indices: Array[int] = []
	for track_index in _get_available_music_track_count():
		var track_title := _get_full_music_track_label_for_index(track_index).to_lower()
		if music_playlist_search_query.is_empty() or track_title.contains(music_playlist_search_query):
			filtered_indices.append(track_index)

	return filtered_indices


func _get_available_music_track_count() -> int:
	return MUSIC_TRACK_COUNT + _get_available_custom_music_paths().size()


func _ensure_valid_music_track_index() -> void:
	if music_track_index < 0 or music_track_index >= _get_available_music_track_count():
		music_track_index = 0


func _get_selected_music_stream() -> AudioStream:
	if music_track_index >= MUSIC_TRACK_COUNT:
		var custom_track_index := music_track_index - MUSIC_TRACK_COUNT
		if custom_track_index >= 0 and custom_track_index < available_custom_music_paths.size():
			var selected_custom_path := available_custom_music_paths[custom_track_index]
			if custom_music_stream == null or loaded_custom_music_path != selected_custom_path:
				custom_music_stream = _load_custom_music_stream_from_path(selected_custom_path)
				loaded_custom_music_path = selected_custom_path if custom_music_stream != null else ""
			if custom_music_stream != null:
				return custom_music_stream

			available_custom_music_paths.erase(selected_custom_path)
			music_track_index = clampi(MUSIC_TRACK_COUNT + custom_track_index, 0, _get_available_music_track_count() - 1)
			loaded_custom_music_path = ""
			custom_music_stream = null
			_save_persistent_settings()
			return _get_selected_music_stream()

	return background_music_streams[clampi(music_track_index, 0, MUSIC_TRACK_COUNT - 1)]


func _get_available_custom_music_paths() -> Array[String]:
	return available_custom_music_paths


func _refresh_available_custom_music_paths() -> void:
	available_custom_music_paths.clear()
	for custom_music_path in custom_music_paths:
		available_custom_music_paths.append(custom_music_path)
	loaded_custom_music_path = ""
	custom_music_stream = null


func _is_custom_music_path_supported(custom_music_path: String) -> bool:
	if custom_music_path.is_empty() or not FileAccess.file_exists(custom_music_path):
		return false

	var file_size := FileAccess.get_size(custom_music_path)
	if file_size <= 0 or file_size > MAX_CUSTOM_MUSIC_FILE_SIZE_BYTES:
		return false

	return custom_music_path.get_extension().to_lower() in ["mp3", "ogg", "wav"]


func _load_custom_music_stream_from_path(custom_music_path: String) -> AudioStream:
	if not _is_custom_music_path_supported(custom_music_path):
		return null

	match custom_music_path.get_extension().to_lower():
		"mp3":
			var mp3_stream: AudioStreamMP3 = AudioStreamMP3.load_from_file(custom_music_path)
			if mp3_stream == null:
				return null
			mp3_stream.loop = false
			return mp3_stream
		"ogg":
			var ogg_stream: AudioStreamOggVorbis = AudioStreamOggVorbis.load_from_file(custom_music_path)
			if ogg_stream == null:
				return null
			ogg_stream.loop = false
			return ogg_stream
		"wav":
			var wav_stream: AudioStreamWAV = AudioStreamWAV.load_from_file(custom_music_path)
			if wav_stream == null:
				return null
			wav_stream.loop_mode = AudioStreamWAV.LOOP_DISABLED
			return wav_stream
		_:
			return null


func _create_music_controls_popup() -> void:
	music_controls_popup = PopupPanel.new()
	music_controls_popup.name = "MusicControlsPopup"
	music_controls_popup.add_theme_stylebox_override(
		"panel",
		_create_flat_style(Color(0.02, 0.075, 0.05, 0.98), Color(0.7, 0.52, 0.16, 0.95), 2, 10, 4)
	)
	add_child(music_controls_popup)

	var margins := MarginContainer.new()
	margins.add_theme_constant_override("margin_left", 14)
	margins.add_theme_constant_override("margin_top", 12)
	margins.add_theme_constant_override("margin_right", 14)
	margins.add_theme_constant_override("margin_bottom", 12)
	music_controls_popup.add_child(margins)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	margins.add_child(content)

	var volume_title := Label.new()
	volume_title.text = "Громкость музыки"
	volume_title.add_theme_font_size_override("font_size", 16)
	volume_title.add_theme_color_override("font_color", Color(0.91, 0.96, 0.91, 1.0))
	content.add_child(volume_title)

	music_popup_volume_label = Label.new()
	music_popup_volume_label.add_theme_font_size_override("font_size", 14)
	music_popup_volume_label.add_theme_color_override("font_color", Color(0.72, 0.85, 0.76, 1.0))
	content.add_child(music_popup_volume_label)

	music_popup_volume_slider = HSlider.new()
	music_popup_volume_slider.min_value = 0.0
	music_popup_volume_slider.max_value = 100.0
	music_popup_volume_slider.step = 1.0
	music_popup_volume_slider.custom_minimum_size = Vector2(0.0, 28.0)
	music_popup_volume_slider.value_changed.connect(_on_music_volume_slider_changed)
	content.add_child(music_popup_volume_slider)

	var play_modes := HBoxContainer.new()
	play_modes.add_theme_constant_override("separation", 8)
	content.add_child(play_modes)

	music_popup_repeat_button = Button.new()
	music_popup_repeat_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	music_popup_repeat_button.custom_minimum_size = Vector2(0.0, 32.0)
	music_popup_repeat_button.add_theme_font_size_override("font_size", 14)
	music_popup_repeat_button.tooltip_text = "После окончания повторять текущий трек"
	music_popup_repeat_button.pressed.connect(_on_music_repeat_pressed)
	play_modes.add_child(music_popup_repeat_button)

	music_popup_shuffle_button = Button.new()
	music_popup_shuffle_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	music_popup_shuffle_button.custom_minimum_size = Vector2(0.0, 32.0)
	music_popup_shuffle_button.add_theme_font_size_override("font_size", 14)
	music_popup_shuffle_button.tooltip_text = "После окончания выбирать случайный следующий трек"
	music_popup_shuffle_button.pressed.connect(_on_music_shuffle_pressed)
	play_modes.add_child(music_popup_shuffle_button)

	var playlist_actions := HBoxContainer.new()
	playlist_actions.add_theme_constant_override("separation", 8)
	content.add_child(playlist_actions)

	music_popup_folder_button = Button.new()
	music_popup_folder_button.text = "📁 Добавить папку"
	music_popup_folder_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	music_popup_folder_button.custom_minimum_size = Vector2(0.0, 32.0)
	music_popup_folder_button.add_theme_font_size_override("font_size", 14)
	music_popup_folder_button.pressed.connect(_on_music_popup_folder_pressed)
	playlist_actions.add_child(music_popup_folder_button)

	music_popup_clear_button = Button.new()
	music_popup_clear_button.text = "Очистить свои"
	music_popup_clear_button.custom_minimum_size = Vector2(112.0, 32.0)
	music_popup_clear_button.add_theme_font_size_override("font_size", 14)
	music_popup_clear_button.tooltip_text = "Удалить из плейлиста только добавленные треки"
	music_popup_clear_button.pressed.connect(_on_clear_profile_music_pressed)
	playlist_actions.add_child(music_popup_clear_button)

	music_popup_import_label = Label.new()
	music_popup_import_label.add_theme_font_size_override("font_size", 14)
	music_popup_import_label.add_theme_color_override("font_color", Color(0.72, 0.85, 0.76, 1.0))
	music_popup_import_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(music_popup_import_label)

	var playlist_title := Label.new()
	playlist_title.text = "Плейлист"
	playlist_title.add_theme_font_size_override("font_size", 16)
	playlist_title.add_theme_color_override("font_color", Color(0.91, 0.96, 0.91, 1.0))
	content.add_child(playlist_title)

	music_popup_search_input = LineEdit.new()
	music_popup_search_input.placeholder_text = "Поиск по названию"
	music_popup_search_input.custom_minimum_size = Vector2(0.0, 32.0)
	music_popup_search_input.add_theme_font_size_override("font_size", 15)
	music_popup_search_input.text_changed.connect(_on_music_playlist_search_changed)
	content.add_child(music_popup_search_input)

	var page_controls := HBoxContainer.new()
	page_controls.add_theme_constant_override("separation", 8)
	content.add_child(page_controls)

	music_popup_previous_page_button = Button.new()
	music_popup_previous_page_button.text = "◀"
	music_popup_previous_page_button.custom_minimum_size = Vector2(44.0, 30.0)
	music_popup_previous_page_button.pressed.connect(_on_music_playlist_previous_page_pressed)
	page_controls.add_child(music_popup_previous_page_button)

	music_popup_page_label = Label.new()
	music_popup_page_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	music_popup_page_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	music_popup_page_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	music_popup_page_label.add_theme_font_size_override("font_size", 14)
	music_popup_page_label.add_theme_color_override("font_color", Color(0.72, 0.85, 0.76, 1.0))
	page_controls.add_child(music_popup_page_label)

	music_popup_next_page_button = Button.new()
	music_popup_next_page_button.text = "▶"
	music_popup_next_page_button.custom_minimum_size = Vector2(44.0, 30.0)
	music_popup_next_page_button.pressed.connect(_on_music_playlist_next_page_pressed)
	page_controls.add_child(music_popup_next_page_button)

	var playlist_scroll := ScrollContainer.new()
	playlist_scroll.custom_minimum_size = Vector2(0.0, 240.0)
	playlist_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	playlist_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	content.add_child(playlist_scroll)

	music_popup_playlist_container = VBoxContainer.new()
	music_popup_playlist_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	music_popup_playlist_container.add_theme_constant_override("separation", 5)
	playlist_scroll.add_child(music_popup_playlist_container)


func _create_tutorial_panel() -> void:
	tutorial_panel = PanelContainer.new()
	tutorial_panel.name = "TutorialPanel"
	tutorial_panel.z_index = 85
	tutorial_panel.visible = false
	tutorial_panel.add_theme_stylebox_override(
		"panel",
		_create_flat_style(Color(0.028, 0.085, 0.055, 0.97), Color(0.78, 0.62, 0.24, 0.95), 2, 10, 4)
	)
	add_child(tutorial_panel)
	# Нижняя левая зона рядом с твоей рукой: здесь подсказка не закрывает
	# историю, карточки игроков, ставки и карты на столе.
	_set_control_layout(tutorial_panel, 0.0, 1.0, 0.0, 1.0, 40.0, -430.0, 380.0, -230.0)

	var margins := MarginContainer.new()
	margins.add_theme_constant_override("margin_left", 14)
	margins.add_theme_constant_override("margin_top", 12)
	margins.add_theme_constant_override("margin_right", 14)
	margins.add_theme_constant_override("margin_bottom", 12)
	tutorial_panel.add_child(margins)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	margins.add_child(content)

	tutorial_title_label = Label.new()
	tutorial_title_label.text = "✦ Режим обучения"
	tutorial_title_label.add_theme_font_size_override("font_size", 17)
	tutorial_title_label.add_theme_color_override("font_color", Color(0.97, 0.86, 0.55, 1.0))
	content.add_child(tutorial_title_label)

	tutorial_text_label = Label.new()
	tutorial_text_label.custom_minimum_size = Vector2(0.0, 76.0)
	tutorial_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tutorial_text_label.add_theme_font_size_override("font_size", 14)
	tutorial_text_label.add_theme_color_override("font_color", Color(0.88, 0.94, 0.88, 1.0))
	content.add_child(tutorial_text_label)

	tutorial_disable_button = Button.new()
	tutorial_disable_button.text = "Выключить подсказки"
	tutorial_disable_button.custom_minimum_size = Vector2(0.0, 30.0)
	tutorial_disable_button.add_theme_font_size_override("font_size", 14)
	tutorial_disable_button.tooltip_text = "Включить подсказки снова можно в настройках или через меню"
	tutorial_disable_button.pressed.connect(_on_tutorial_disable_pressed)
	content.add_child(tutorial_disable_button)


func _refresh_tutorial_panel() -> void:
	if not is_instance_valid(tutorial_panel) or not is_instance_valid(tutorial_text_label):
		return

	var is_table_visible := menu_overlay != null and not menu_overlay.visible
	# Во время выбора условия Джокера важнее показать все кнопки решения.
	# Подсказка появится снова сразу после подтверждения выбора.
	var can_show_tutorial := tutorial_enabled and is_table_visible and game.current_round.state != Round.State.SETUP and pending_joker_card == null
	tutorial_panel.visible = can_show_tutorial
	if not can_show_tutorial:
		return

	tutorial_text_label.text = _get_tutorial_hint_text()


func _get_tutorial_hint_text() -> String:
	match game.current_round.state:
		Round.State.BIDDING:
			if _is_dark_round():
				return "Тёмная раздача: сначала игроки заказывают взятки вслепую, а карты открываются после всех заказов."
			if game.current_round.current_player_index == HUMAN_PLAYER_INDEX:
				return "Сейчас твой заказ. Назови, сколько взяток планируешь взять в этой раздаче. Последний заказ не может сравнять общую сумму с числом карт."
			return "Заказы идут по кругу от игрока после сдающего. Следи за уже названными числами на карточках игроков."
		Round.State.PLAYING:
			if pending_joker_card != null:
				if game.active_trick == null:
					return "Ты вышел Джокером. Объяви масть и условие: Джокер забирает взятку или считается старшей/младшей объявленной мастью."
				return "Джокер можно использовать как сильную карту или как сброс. Выбери, должен ли он забирать эту взятку."
			if _get_current_player_index() == HUMAN_PLAYER_INDEX:
				if game.active_trick == null:
					return "Твой заход. Выбери карту, которой начнётся взятка; другие игроки по возможности должны ответить этой мастью."
				return "Твой ответ. Если масть захода есть на руке — положи её. Если нет, дальше действуют козырь и правила Джокера."
			return "Сейчас ход другого игрока. Карты в центре образуют взятку; победитель следующей взятки будет ходить первым."
		Round.State.FINISHED:
			return "Раздача завершена. Сверь заказ, число взяток и очки справа; полную историю всех раздач можно открыть кнопкой «Расписка»."

	return "Подсказки будут меняться вместе с этапом раздачи."


func _refresh_music_controls_popup() -> void:
	if not is_instance_valid(music_popup_volume_label) or not is_instance_valid(music_popup_volume_slider) or not is_instance_valid(music_popup_repeat_button) or not is_instance_valid(music_popup_shuffle_button) or not is_instance_valid(music_popup_folder_button) or not is_instance_valid(music_popup_clear_button) or not is_instance_valid(music_popup_import_label) or not is_instance_valid(music_popup_search_input) or not is_instance_valid(music_popup_previous_page_button) or not is_instance_valid(music_popup_next_page_button) or not is_instance_valid(music_popup_page_label) or not is_instance_valid(music_popup_playlist_container):
		return

	music_popup_volume_label.text = "%d%%" % music_volume_percent
	music_popup_volume_slider.set_value_no_signal(music_volume_percent)
	music_popup_repeat_button.text = "↻ Повтор: %s" % ("вкл" if music_repeat_enabled else "выкл")
	music_popup_shuffle_button.text = "⤨ Случайно: %s" % ("вкл" if music_shuffle_enabled else "выкл")
	music_popup_import_label.text = last_music_import_status
	music_popup_import_label.visible = not last_music_import_status.is_empty()
	music_popup_clear_button.disabled = custom_music_paths.is_empty()
	if music_popup_search_input.text != music_playlist_search_query:
		music_popup_search_input.set_text(music_playlist_search_query)
	_clear_children(music_popup_playlist_container)

	var filtered_track_indices := _get_filtered_music_track_indices()
	var total_pages: int = maxi(1, ceili(float(filtered_track_indices.size()) / float(MUSIC_PLAYLIST_PAGE_SIZE)))
	music_playlist_page = clampi(music_playlist_page, 0, total_pages - 1)
	var first_result_index := music_playlist_page * MUSIC_PLAYLIST_PAGE_SIZE
	var last_result_index := mini(first_result_index + MUSIC_PLAYLIST_PAGE_SIZE, filtered_track_indices.size())
	music_popup_previous_page_button.disabled = music_playlist_page <= 0
	music_popup_next_page_button.disabled = music_playlist_page >= total_pages - 1
	if filtered_track_indices.is_empty():
		music_popup_page_label.text = "Ничего не найдено"
	else:
		music_popup_page_label.text = "%d–%d из %d" % [first_result_index + 1, last_result_index, filtered_track_indices.size()]

	for result_index in range(first_result_index, last_result_index):
		var track_index: int = filtered_track_indices[result_index]
		var track_button := Button.new()
		track_button.text = "%s%s" % ["✓ " if track_index == music_track_index else "   ", _get_music_track_label_for_index(track_index)]
		track_button.tooltip_text = _get_full_music_track_label_for_index(track_index)
		track_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		track_button.custom_minimum_size = Vector2(0.0, 34.0)
		track_button.add_theme_font_size_override("font_size", 15)
		track_button.pressed.connect(_on_music_popup_track_pressed.bind(track_index))
		music_popup_playlist_container.add_child(track_button)


func _refresh_music_player() -> void:
	var is_table_visible := menu_overlay != null and not menu_overlay.visible
	music_player_panel.visible = is_table_visible and not music_player_hidden

	music_track_label.text = "♫ %s · %d%%" % [_get_music_track_label(), music_volume_percent]
	music_track_label.tooltip_text = _get_full_music_track_label_for_index(music_track_index)
	music_play_pause_button.text = "▶ Играть" if music_is_paused else "Ⅱ Пауза"
	music_previous_button.disabled = false
	music_play_pause_button.disabled = false
	music_next_button.disabled = false
	music_playlist_button.disabled = false
	music_add_button.disabled = false


func _reset_game_session() -> void:
	_stop_human_turn_timer()
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
				_start_human_turn_timer()
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
				_start_human_turn_timer()
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

	_stop_human_turn_timer()
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

	_stop_human_turn_timer()
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

	_stop_human_turn_timer()
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
	_stop_human_turn_timer()
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


func _on_score_sheet_backdrop_gui_input(event: InputEvent) -> void:
	if is_processing_automatic_actions or not is_score_sheet_visible:
		return

	var mouse_button_event: InputEventMouseButton = event as InputEventMouseButton
	if mouse_button_event == null:
		return

	if mouse_button_event.button_index == MOUSE_BUTTON_LEFT and mouse_button_event.pressed:
		_on_score_sheet_toggle_pressed()


func _on_music_player_visibility_toggle_pressed() -> void:
	music_player_hidden = not music_player_hidden
	if music_player_hidden and is_instance_valid(music_controls_popup):
		music_controls_popup.hide()

	_save_persistent_settings()
	_refresh_ui()
	_build_pause_menu_content()


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
		show_last_completed_trick = true
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
	await _animate_trick_collection(winner_player_index)
	show_last_completed_trick = false
	_refresh_table()


func _animate_played_card(player_index: int) -> void:
	if player_index < 0 or player_index >= trick_card_views.size():
		return

	var card_view: CardView = trick_card_views[player_index]
	if not card_view.visible:
		return

	await get_tree().process_frame
	var target_position: Vector2 = card_view.global_position
	var source_position: Vector2 = _get_played_card_source_global_position(player_index, card_view.size)
	card_view.pivot_offset = card_view.size * 0.5
	card_view.global_position = source_position
	card_view.scale = Vector2(0.78, 0.78)
	card_view.modulate = Color(1.0, 1.0, 1.0, 0.86)
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(card_view, "global_position", target_position, CARD_FLY_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(card_view, "scale", Vector2.ONE, CARD_FLY_DURATION).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(card_view, "modulate", Color.WHITE, CARD_FLY_DURATION)
	await tween.finished


func _get_played_card_source_global_position(player_index: int, card_size: Vector2) -> Vector2:
	var source_control: Control = hand_container

	if player_index != HUMAN_PLAYER_INDEX:
		var bot_holder_index: int = player_index - 1
		if bot_holder_index >= 0 and bot_holder_index < bot_card_back_holders.size():
			source_control = bot_card_back_holders[bot_holder_index]
		elif player_index >= 0 and player_index < avatar_badges.size():
			source_control = avatar_badges[player_index]

	var source_rect: Rect2 = source_control.get_global_rect()
	return source_rect.get_center() - card_size * 0.5


func _animate_trick_collection(winner_player_index: int) -> void:
	if winner_player_index < 0 or winner_player_index >= avatar_badges.size():
		return

	var card_size := Vector2(108.0, 132.0)
	var destination_position: Vector2 = _get_trick_collection_target_global_position(winner_player_index, card_size)
	var tween: Tween = create_tween()
	var has_visible_cards := false
	tween.set_parallel(true)

	for player_index in trick_card_views.size():
		var card_view: CardView = trick_card_views[player_index]
		if not card_view.visible:
			continue

		has_visible_cards = true
		card_view.pivot_offset = card_view.size * 0.5
		var stack_offset := Vector2(float(player_index * 3), float(player_index * 2))
		tween.tween_property(card_view, "global_position", destination_position + stack_offset, TRICK_COLLECTION_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.tween_property(card_view, "scale", Vector2(0.36, 0.36), TRICK_COLLECTION_DURATION)
		tween.tween_property(card_view, "modulate", Color(1.0, 1.0, 1.0, 0.0), TRICK_COLLECTION_DURATION)

	if has_visible_cards:
		await tween.finished

	for card_view in trick_card_views:
		card_view.visible = false
		card_view.scale = Vector2.ONE
		card_view.modulate = Color.WHITE


func _get_trick_collection_target_global_position(player_index: int, card_size: Vector2) -> Vector2:
	var target_rect: Rect2 = avatar_badges[player_index].get_global_rect()
	return target_rect.get_center() - card_size * 0.5


func _set_trick_winner_highlight(player_index: int, highlighted: bool) -> void:
	if player_index < 0 or player_index >= trick_card_views.size():
		return

	trick_card_views[player_index].set_winner_highlight(highlighted)


func _reset_trick_presentation() -> void:
	is_trick_presentation_active = false
	pending_play_presentation = false
	pending_card_animation_player_index = -1
	pending_trick_winner_player_index = -1
	show_last_completed_trick = false

	for card_view in trick_card_views:
		card_view.set_winner_highlight(false)
		card_view.visible = false
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
	_refresh_music_player()
	_refresh_tutorial_panel()
	_refresh_turn_timer_indicator()


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
		player_panels[player_index].add_theme_stylebox_override("panel", _get_player_panel_style(player_index, is_current))
		player_labels[player_index].text = "%s%s" % [marker, player.display_name]

		if _round_uses_bids():
			var bid_text := "—" if player.bid < 0 else str(player.bid)
			player_stats_labels[player_index].text = "Заказ: %s  ·  Взято: %d" % [
				bid_text,
				player.tricks_taken
			]
		else:
			player_stats_labels[player_index].text = "Взято: %d" % player.tricks_taken
		player_score_labels[player_index].text = "Очки: %d" % player.total_score
		player_score_labels[player_index].add_theme_color_override(
			"font_color",
			Color(0.97, 0.84, 0.38, 1.0) if player.total_score >= 0 else Color(0.96, 0.42, 0.34, 1.0)
		)

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
	if player_index == HUMAN_PLAYER_INDEX and avatar_index == CUSTOM_AVATAR_INDEX:
		return custom_profile_avatar_path

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


func _get_player_avatar_texture(player_index: int) -> Texture2D:
	var texture_path := _get_player_avatar_texture_path(player_index)
	if texture_path.is_empty():
		return null

	if texture_path.begins_with("user://"):
		var local_texture_path := ProjectSettings.globalize_path(texture_path)
		var image: Image = Image.load_from_file(local_texture_path)
		if image == null or image.is_empty():
			return null
		return ImageTexture.create_from_image(image)

	return ResourceLoader.load(texture_path, "Texture2D") as Texture2D


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
		avatar_label.add_theme_font_size_override("font_size", 30)
		avatar_label.add_theme_color_override("font_color", Color(0.98, 0.9, 0.6, 1.0))
		avatar_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		avatar_content.add_child(avatar_label)

		if player_index == HUMAN_PLAYER_INDEX:
			turn_timer_indicator = TurnTimerIndicator.new()
			turn_timer_indicator.visible = false
			turn_timer_indicator.z_index = 2
			avatar_content.add_child(turn_timer_indicator)
		players_container.add_child(badge)
		avatar_badges.append(badge)
		avatar_images.append(avatar_image)
		avatar_labels.append(avatar_label)


func _refresh_player_avatar_badges() -> void:
	for player_index in avatar_badges.size():
		avatar_badges[player_index].tooltip_text = "Аватар: %s" % game.players[player_index].display_name
		var avatar_texture: Texture2D = _get_player_avatar_texture(player_index)
		avatar_images[player_index].texture = avatar_texture
		avatar_labels[player_index].visible = avatar_texture == null
		avatar_labels[player_index].text = _get_player_avatar_symbol(player_index)


func _place_player_avatar_badge(badge: PanelContainer, player_index: int) -> void:
	match player_index:
		HUMAN_PLAYER_INDEX:
			_set_control_layout(badge, 0.5, 1.0, 0.5, 1.0, -236.0, -402.0, -132.0, -298.0)
		1:
			_set_control_layout(badge, 0.0, 0.0, 0.0, 0.0, 180.0, 348.0, 284.0, 452.0)
		2:
			_set_control_layout(badge, 0.5, 0.0, 0.5, 0.0, -235.0, 74.0, -131.0, 178.0)
		3:
			_set_control_layout(badge, 1.0, 0.0, 1.0, 0.0, -284.0, 348.0, -180.0, 452.0)


func _refresh_table() -> void:
	var table_title := ""

	if game.active_trick == null:
		table_title = "Последняя взятка" if show_last_completed_trick else "Следующая взятка"
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

	if game.active_trick == null and show_last_completed_trick:
		played_cards = game.last_completed_trick_cards
		played_by = game.last_completed_trick_played_by
	elif game.active_trick != null:
		played_cards = game.active_trick.played_cards
		played_by = game.active_trick.played_by

	for card_index in played_cards.size():
		cards_by_player[played_by[card_index]] = played_cards[card_index]

	for player_index in game.players.size():
		var card := cards_by_player[player_index]
		var card_view: CardView = trick_card_views[player_index]
		_place_trick_slot(card_view, player_index)
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
	if is_instance_valid(score_sheet_backdrop):
		score_sheet_backdrop.visible = is_score_sheet_visible
	if is_instance_valid(score_sheet_close_button):
		score_sheet_close_button.visible = is_score_sheet_visible
		score_sheet_close_button.disabled = is_processing_automatic_actions
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
		_set_control_layout(joker_controls, 0.0, 1.0, 0.0, 1.0, 64.0, -510.0, 444.0, -128.0)
		return

	joker_controls.columns = 2
	_set_control_layout(joker_controls, 0.5, 1.0, 0.5, 1.0, -280.0, -270.0, 280.0, -218.0)


func _refresh_hand() -> void:
	_clear_children(hand_container)
	hand_title.text = "Твоя рука"

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
		content.add_theme_constant_override("separation", 2)
		panel.add_child(content)

		var name_label := Label.new()
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.add_theme_font_size_override("font_size", 19)
		name_label.add_theme_color_override("font_color", Color(0.95, 0.97, 0.93, 1.0))
		content.add_child(name_label)

		var stats_label := Label.new()
		stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		stats_label.add_theme_font_size_override("font_size", 15)
		stats_label.add_theme_color_override("font_color", Color(0.82, 0.88, 0.82, 1.0))
		content.add_child(stats_label)

		var score_label := Label.new()
		score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		score_label.add_theme_font_size_override("font_size", 19)
		score_label.add_theme_color_override("font_color", Color(0.97, 0.84, 0.38, 1.0))
		content.add_child(score_label)
		players_container.add_child(panel)
		player_labels.append(name_label)
		player_stats_labels.append(stats_label)
		player_score_labels.append(score_label)
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
			_set_control_layout(holder, 0.0, 0.0, 0.0, 0.0, 440.0, 462.0, 532.0, 518.0)
		2:
			_set_control_layout(holder, 0.5, 0.0, 0.5, 0.0, 130.0, 112.0, 222.0, 168.0)
		3:
			_set_control_layout(holder, 1.0, 0.0, 1.0, 0.0, -392.0, 462.0, -300.0, 518.0)


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
	deck_visual.visible = game.current_round.state != Round.State.SETUP
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
				_set_control_layout(marker, 0.5, 0.0, 0.5, 0.0, 122.0, 402.0, 170.0, 430.0)
			3:
				_set_control_layout(marker, 1.0, 0.0, 1.0, 0.0, -610.0, 342.0, -562.0, 370.0)
		return

	match player_index:
		HUMAN_PLAYER_INDEX:
			_set_control_layout(marker, 0.5, 1.0, 0.5, 1.0, -248.0, -444.0, -170.0, -416.0)
		1:
			_set_control_layout(marker, 0.0, 0.0, 0.0, 0.0, 350.0, 324.0, 428.0, 352.0)
		2:
			_set_control_layout(marker, 0.5, 0.0, 0.5, 0.0, -258.0, 160.0, -180.0, 188.0)
		3:
			_set_control_layout(marker, 1.0, 0.0, 1.0, 0.0, -428.0, 324.0, -350.0, 352.0)


func _place_player_panel(panel: PanelContainer, player_index: int) -> void:
	match player_index:
		HUMAN_PLAYER_INDEX:
			_set_control_layout(panel, 0.5, 1.0, 0.5, 1.0, -120.0, -396.0, 120.0, -314.0)
		1:
			_set_control_layout(panel, 0.0, 0.0, 0.0, 0.0, 300.0, 358.0, 510.0, 440.0)
		2:
			_set_control_layout(panel, 0.5, 0.0, 0.5, 0.0, -115.0, 82.0, 115.0, 164.0)
		3:
			_set_control_layout(panel, 1.0, 0.0, 1.0, 0.0, -510.0, 358.0, -300.0, 440.0)


func _place_trick_slot(panel: Control, player_index: int) -> void:
	match player_index:
		HUMAN_PLAYER_INDEX:
			_set_control_layout(panel, 0.5, 0.0, 0.5, 0.0, -54.0, 455.0, 54.0, 587.0)
		1:
			_set_control_layout(panel, 0.5, 0.0, 0.5, 0.0, -265.0, 365.0, -157.0, 497.0)
		2:
			_set_control_layout(panel, 0.5, 0.0, 0.5, 0.0, -54.0, 255.0, 54.0, 387.0)
		3:
			_set_control_layout(panel, 0.5, 0.0, 0.5, 0.0, 157.0, 365.0, 265.0, 497.0)


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


func _process(delta: float) -> void:
	if not turn_timer_active or not auto_turn_enabled:
		return

	if menu_overlay != null and menu_overlay.visible:
		return

	if not _is_human_decision_pending():
		_stop_human_turn_timer()
		return

	turn_timer_remaining = maxf(0.0, turn_timer_remaining - delta)
	_refresh_turn_timer_indicator()

	if is_zero_approx(turn_timer_remaining):
		_resolve_human_turn_timeout()


func _is_human_decision_pending() -> bool:
	return (
		not is_processing_automatic_actions
		and (game.current_round.state == Round.State.BIDDING or game.current_round.state == Round.State.PLAYING)
		and _get_current_player_index() == HUMAN_PLAYER_INDEX
	)


func _start_human_turn_timer() -> void:
	if not auto_turn_enabled or turn_timer_active or not _is_human_decision_pending():
		return

	turn_timer_remaining = AUTO_TURN_DURATION_SECONDS
	turn_timer_active = true
	_refresh_turn_timer_indicator()


func _stop_human_turn_timer() -> void:
	turn_timer_active = false
	turn_timer_remaining = AUTO_TURN_DURATION_SECONDS
	_refresh_turn_timer_indicator()


func _refresh_turn_timer_indicator() -> void:
	if not is_instance_valid(turn_timer_indicator):
		return

	var should_show_timer := auto_turn_enabled and turn_timer_active and _is_human_decision_pending()
	turn_timer_indicator.visible = should_show_timer
	if should_show_timer:
		turn_timer_indicator.set_time_remaining(turn_timer_remaining, AUTO_TURN_DURATION_SECONDS)


func _resolve_human_turn_timeout() -> void:
	_stop_human_turn_timer()

	if game.current_round.state == Round.State.BIDDING:
		_play_automatic_human_bid()
		return

	if game.current_round.state == Round.State.PLAYING:
		_play_automatic_human_card()


func _play_automatic_human_bid() -> void:
	var cards_were_hidden := _is_dark_round() and not game.cards_are_dealt
	var bid := _choose_automatic_bid(HUMAN_PLAYER_INDEX)

	_commit_test_checkpoint()
	if not game.place_bid(HUMAN_PLAYER_INDEX, bid):
		action_text = "Время вышло, но автоматический заказ не удалось применить."
		_refresh_ui()
		return

	action_text = "Время вышло: за тебя выбран заказ %d." % bid
	_add_history(action_text)
	_announce_dark_cards_dealt(cards_were_hidden)
	_save_current_session()
	_refresh_ui()
	_advance_automatic_actions()


func _play_automatic_human_card() -> void:
	var player := game.players[HUMAN_PLAYER_INDEX]
	var card: Card = pending_joker_card
	if card == null:
		card = _choose_automatic_card(player)

	if card == null:
		action_text = "Время вышло, но автоматический ход не нашёл допустимую карту."
		_refresh_ui()
		return

	var is_leading_joker := card.is_joker and game.active_trick == null
	var joker_mode: Trick.JokerMode = Trick.JokerMode.NONE
	var declared_suit := -1
	var played_successfully := false

	_commit_test_checkpoint()
	if card.is_joker:
		joker_mode = _choose_automatic_joker_mode(player)
		declared_suit = pending_joker_suit if pending_joker_suit >= 0 else _choose_automatic_joker_suit(player, joker_mode == Trick.JokerMode.NORMAL_CARD_WINS)
		played_successfully = game.play_card(HUMAN_PLAYER_INDEX, card, joker_mode, declared_suit)
	else:
		played_successfully = game.play_card(HUMAN_PLAYER_INDEX, card)

	if not played_successfully:
		action_text = "Время вышло, но автоматический ход не удалось применить."
		_refresh_ui()
		return

	pending_joker_card = null
	pending_joker_suit = -1
	action_text = "Время вышло: за тебя сыграна %s." % card.get_card_name()
	_add_history(action_text)
	_record_play("Автоход", card, HUMAN_PLAYER_INDEX)
	if card.is_joker:
		_add_history(_get_joker_rule_text(joker_mode, declared_suit, Trick.ForcedCardRank.NONE, is_leading_joker))
	_save_current_session()
	_advance_automatic_actions()


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

		# Взятку уже невозможно забрать: сохраняем сильные карты для следующего захода.
		var weakest_losing_regular_card := _select_weakest_losing_regular_card(legal_cards)
		if weakest_losing_regular_card != null:
			return weakest_losing_regular_card

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

		# Даже при невыполненном заказе не тратим туза, если эта взятка проиграна.
		var weakest_losing_regular_card := _select_weakest_losing_regular_card(legal_cards)
		if weakest_losing_regular_card != null:
			return weakest_losing_regular_card

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
	var original_bot_difficulty: BotDifficulty = bot_difficulty
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

	assert(test_game.start_round(1, Round.RoundType.NORMAL, Round.TrumpSuit.CLUBS), "Проверка бота: раздача для сохранения туза должна запускаться.")
	test_game.current_round.start_playing_without_bids()
	for player in test_game.players:
		player.hand.clear()

	var discard_leader_index: int = test_game.current_round.current_player_index
	var discard_bot_index: int = (discard_leader_index + 1) % test_game.players.size()
	var trump_lead := _create_card(Card.Suit.CLUBS, Card.Rank.ACE)
	var low_discard := _create_card(Card.Suit.HEARTS, Card.Rank.SIX)
	var saved_ace := _create_card(Card.Suit.DIAMONDS, Card.Rank.ACE)
	test_game.players[discard_leader_index].receive_card(trump_lead)
	test_game.players[discard_bot_index].receive_card(low_discard)
	test_game.players[discard_bot_index].receive_card(saved_ace)
	test_game.players[discard_bot_index].bid = 2
	assert(test_game.play_card(discard_leader_index, trump_lead), "Проверка бота: козырная карта захода должна быть сыграна.")

	bot_difficulty = BotDifficulty.NORMAL
	var normal_discard_choice: Card = _choose_automatic_card(test_game.players[discard_bot_index])
	assert(normal_discard_choice == low_discard, "Проверка бота: обычный бот должен сохранить туза, если взятку уже не забрать.")
	bot_difficulty = BotDifficulty.HARD
	var hard_discard_choice: Card = _choose_automatic_card(test_game.players[discard_bot_index])
	assert(hard_discard_choice == low_discard, "Проверка бота: сложный бот должен сохранить туза, если взятку уже не забрать.")

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
	bot_difficulty = original_bot_difficulty


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
