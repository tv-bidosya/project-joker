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
const TRICK_WINNER_HOLD_DURATION := 1.2
const TRICK_COLLECTION_DURATION := 0.3
const BOT_SPEED_COUNT := 3
const BOT_DIFFICULTY_COUNT := 3
const SOUND_VOLUME_COUNT := 4
const MUSIC_VOLUME_COUNT := 4
const MUSIC_TRACK_COUNT := 3
const MAX_CUSTOM_MUSIC_FILE_SIZE_BYTES := 40 * 1024 * 1024
const MAX_PLAYER_NAME_LENGTH := 16
const MAX_MUSIC_TITLE_LENGTH := 26
const MAX_SOUNDPAD_TITLE_LENGTH := 20
const MUSIC_PLAYLIST_PAGE_SIZE := 25
const PROFILE_PLAYLIST_PREVIEW_COUNT := 20
const MAX_SOUNDPAD_FILE_SIZE_BYTES := 2 * 1024 * 1024
const MAX_SOUNDPAD_CLIP_DURATION_SECONDS := 25.0
const SOUNDPAD_MANIFEST_SCRIPT_PATH := "res://Assets/Soundboard/soundpad_manifest.gd"
const SoundpadManifest = preload("res://Assets/Soundboard/soundpad_manifest.gd")
const NetworkSnapshot = preload("res://Scripts/core/MatchStateSnapshot.gd")
const NetworkCommand = preload("res://Scripts/core/MatchCommand.gd")
const NetworkHost = preload("res://Scripts/core/LocalMatchHost.gd")
const LoopbackNetwork = preload("res://Scripts/core/LoopbackNetworkTest.gd")
const SteamBridge = preload("res://Scripts/core/SteamBridge.gd")
const SteamP2PMatch = preload("res://Scripts/core/SteamP2PMatch.gd")
const CardArtworkResource = preload("res://Scripts/ui/CardArtwork.gd")
const Dice3DViewResource = preload("res://Scripts/ui/Dice3DView.gd")
const FLUENT_EMOJI_LICENSE = preload("res://Assets/Social/FluentEmoji3D/license_notice.gd")
const JOKER_CELEBRATION_TEXTURE = preload("res://Assets/Effects/Joker/laughing_jester_middle_fingers.png")
const SCORE_SHEET_NUMBER_COLUMN_WIDTH := 46.0
const SCORE_SHEET_MODE_COLUMN_WIDTH := 132.0
const SCORE_SHEET_CARDS_COLUMN_WIDTH := 52.0
const SCORE_SHEET_TRUMP_COLUMN_WIDTH := 96.0
const SCORE_SHEET_BID_COLUMN_WIDTH := 82.0
const SCORE_SHEET_TRICKS_COLUMN_WIDTH := 72.0
const SCORE_SHEET_SCORE_COLUMN_WIDTH := 102.0
const SCORE_SHEET_PLAYER_GROUP_WIDTH := 264.0
const ROUND_RESULTS_PANEL_MIN_WIDTH := 420.0
const ROUND_RESULTS_PANEL_MAX_WIDTH := 760.0
const ROUND_RESULTS_PANEL_HORIZONTAL_PADDING := 56.0
const ROUND_RESULTS_PANEL_TOP := 270.0
const ROUND_RESULTS_PANEL_FIXED_HEIGHT := 82.0
const ROUND_RESULTS_PANEL_ROW_HEIGHT := 26.0
const INACTIVITY_AUTO_TURN_DELAY_SECONDS := 120.0
const AUTO_TURN_DURATION_SECONDS := 60.0
const REACTION_DISPLAY_DURATION := 1.25
const SOUNDPAD_BUBBLE_DISPLAY_DURATION := 1.6
const STICKER_FLY_DURATION := 0.62
const STICKER_HOLD_DURATION := 6.0
const AVATAR_ACTION_HIDE_DELAY_SECONDS := 1.8
const STICKER_PICKER_IDLE_CLOSE_SECONDS := 5.0
const SOCIAL_ACTION_USE_LIMIT := 3
const SOCIAL_ACTION_COOLDOWN_SECONDS := 120.0
const CHAT_LOCAL_SEND_COOLDOWN_MILLISECONDS := 800
const CHAT_VISIBLE_MESSAGE_LIMIT := 40
const BUILT_IN_AVATAR_COUNT := 4
const CUSTOM_AVATAR_INDEX := BUILT_IN_AVATAR_COUNT
const HUMAN_AVATAR_COUNT := BUILT_IN_AVATAR_COUNT + 1
const GAME_VERSION := "0.3.7"
# Перед публичным экспортом поставь false: игрок сможет создать отчёт, но не
# увидит внутреннюю кнопку его загрузки. После экспорта можно вернуть true.
const DEVELOPER_REPORT_TOOLS_ENABLED := true
const PERSISTENT_SETTINGS_PATH := "user://project_joker_settings.cfg"
const SESSION_SAVE_PATH := "user://project_joker_session.save"
const SESSION_SAVE_VERSION := 1
const CUSTOM_PROFILE_AVATAR_PATH := "user://project_joker_profile_avatar.png"
const BUG_REPORT_FORMAT_VERSION := 1
const BUG_REPORT_DIRECTORY_PATH := "user://ProjectJokerReports"
const BUG_REPORT_FILE_EXTENSION := "pjreport"
const BUG_REPORT_TIMELINE_LIMIT := 8
const UNDO_REQUESTS_PER_DECISION_LIMIT := 2
const LOCAL_UNDO_VOTE_INTERVAL_SECONDS := 0.28
const LOCAL_UNDO_VOTE_RESULT_HOLD_SECONDS := 0.45
const FIRST_TURN_ROLL_BOT_REROLL_DELAY_SECONDS := 1.8
const TURN_REMINDER_DELAY_SECONDS := 10.0
const UNSET_SCORE_DISPLAY := -2147483648
const TABLE_FELT_NAMES := ["Классическое зелёное", "Синее", "Бордовое"]
const TABLE_SURROUND_NAMES := ["Тёмно-зелёный", "Тёмный орех", "Светлый дуб", "Тёмный клуб", "Тёплая ткань"]
const TABLE_SURROUND_SHADER_CODE := """
shader_type canvas_item;
render_mode unshaded;

uniform vec4 base_color : source_color = vec4(0.008, 0.05, 0.032, 1.0);
uniform int pattern_kind = 0;

float hash(vec2 point) {
	return fract(sin(dot(point, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec2 point = UV;
	float detail = 0.0;
	if (pattern_kind == 1) {
		float grain = sin(point.y * 190.0 + sin(point.x * 23.0) * 5.0);
		float pores = hash(floor(point * vec2(95.0, 280.0))) - 0.5;
		detail = grain * 0.055 + pores * 0.025;
	} else if (pattern_kind == 2) {
		float threads = sin(point.x * 540.0) * sin(point.y * 420.0);
		detail = threads * 0.022;
	} else if (pattern_kind == 3) {
		float club_glow = 1.0 - smoothstep(0.0, 0.72, distance(point, vec2(0.5)));
		detail = club_glow * 0.055 - 0.025;
	}
	float vignette = 1.0 - smoothstep(0.18, 0.78, distance(point, vec2(0.5)));
	vec3 color = base_color.rgb * (0.88 + vignette * 0.12 + detail);
	COLOR = vec4(color, base_color.a);
}
"""
const AVATAR_TURN_GLOW_SHADER_CODE := """
shader_type canvas_item;
render_mode unshaded;

float rounded_box_sdf(vec2 point, vec2 half_size, float radius) {
	vec2 offset = abs(point) - half_size + vec2(radius);
	return length(max(offset, vec2(0.0))) + min(max(offset.x, offset.y), 0.0) - radius;
}

void fragment() {
	vec2 point = (UV - vec2(0.5)) * 2.0;
	float frame_distance = rounded_box_sdf(point, vec2(0.84), 0.15);
	float ring = 1.0 - smoothstep(0.025, 0.065, abs(frame_distance));
	float halo = 1.0 - smoothstep(0.055, 0.19, abs(frame_distance));
	float angle = (atan(point.y, point.x) + PI) / TAU;
	float sweep = pow(max(cos((angle - TIME * 0.32) * TAU), 0.0), 18.0);
	float sparkle = pow(max(cos((angle + TIME * 0.18) * TAU * 3.0), 0.0), 28.0);
	float pulse = 0.84 + 0.16 * sin(TIME * 4.2);
	vec3 deep_gold = vec3(1.0, 0.48, 0.04);
	vec3 pale_gold = vec3(1.0, 0.98, 0.68);
	vec3 color = mix(deep_gold, pale_gold, clamp(sweep + sparkle * 0.45, 0.0, 1.0));
	float alpha = clamp(
		ring * (0.64 + sweep * 0.78 + sparkle * 0.34)
		+ halo * (0.08 + sweep * 0.18),
		0.0,
		1.0
	) * pulse;
	COLOR = vec4(color, alpha);
}
"""
const SOCIAL_EMOJI_SHINE_SHADER_CODE := """
shader_type canvas_item;
render_mode unshaded;

uniform float shine_progress = -0.5;

void fragment() {
	vec4 source = texture(TEXTURE, UV);
	float diagonal = UV.x + UV.y;
	float shine = 1.0 - smoothstep(0.0, 0.11, abs(diagonal - shine_progress));
	vec3 lit_color = source.rgb + vec3(0.34, 0.29, 0.18) * shine * source.a;
	COLOR = vec4(lit_color, source.a);
}
"""
const JOKER_CELEBRATION_GLOW_SHADER_CODE := """
shader_type canvas_item;
render_mode unshaded;

void fragment() {
	vec2 point = UV - vec2(0.5);
	float radius = length(point);
	float halo = 1.0 - smoothstep(0.08, 0.5, radius);
	float angle = atan(point.y, point.x);
	float rays = pow(max(cos(angle * 10.0 - TIME * 2.4), 0.0), 10.0);
	float pulse = 0.82 + 0.18 * sin(TIME * 6.0);
	float alpha = (halo * 0.34 + halo * rays * 0.28) * pulse;
	COLOR = vec4(1.0, 0.66, 0.12, alpha);
}
"""
const FLUENT_EMOJI_TEXTURE_PATHS := {
	"😄": "res://Assets/Social/FluentEmoji3D/beaming_face_with_smiling_eyes_3d.png",
	"😂": "res://Assets/Social/FluentEmoji3D/face_with_tears_of_joy_3d.png",
	"🤣": "res://Assets/Social/FluentEmoji3D/rolling_on_the_floor_laughing_3d.png",
	"😍": "res://Assets/Social/FluentEmoji3D/smiling_face_with_heart-eyes_3d.png",
	"😘": "res://Assets/Social/FluentEmoji3D/face_blowing_a_kiss_3d.png",
	"😎": "res://Assets/Social/FluentEmoji3D/smiling_face_with_sunglasses_3d.png",
	"🤔": "res://Assets/Social/FluentEmoji3D/thinking_face_3d.png",
	"👏": "res://Assets/Social/FluentEmoji3D/clapping_hands_3d_default.png",
	"😮": "res://Assets/Social/FluentEmoji3D/face_with_open_mouth_3d.png",
	"😢": "res://Assets/Social/FluentEmoji3D/crying_face_3d.png",
	"😡": "res://Assets/Social/FluentEmoji3D/pouting_face_3d.png",
	"🤬": "res://Assets/Social/FluentEmoji3D/face_with_symbols_on_mouth_3d.png",
	"😈": "res://Assets/Social/FluentEmoji3D/smiling_face_with_horns_3d.png",
	"🤡": "res://Assets/Social/FluentEmoji3D/clown_face_3d.png",
	"🤦": "res://Assets/Social/FluentEmoji3D/person_facepalming_3d_default.png",
	"🤷": "res://Assets/Social/FluentEmoji3D/person_shrugging_3d_default.png",
	"👍": "res://Assets/Social/FluentEmoji3D/thumbs_up_3d_default.png",
	"👎": "res://Assets/Social/FluentEmoji3D/thumbs_down_3d_default.png",
	"🔥": "res://Assets/Social/FluentEmoji3D/fire_3d.png",
	"🖕": "res://Assets/Social/FluentEmoji3D/middle_finger_3d_default.png",
	"🍫": "res://Assets/Social/FluentEmoji3D/chocolate_bar_3d.png",
	"☕": "res://Assets/Social/FluentEmoji3D/hot_beverage_3d.png",
	"🍺": "res://Assets/Social/FluentEmoji3D/beer_mug_3d.png",
	"💋": "res://Assets/Social/FluentEmoji3D/kiss_mark_3d.png",
	"♥": "res://Assets/Social/FluentEmoji3D/red_heart_3d.png",
	"🌹": "res://Assets/Social/FluentEmoji3D/rose_3d.png",
	"🍰": "res://Assets/Social/FluentEmoji3D/shortcake_3d.png",
	"🧸": "res://Assets/Social/FluentEmoji3D/teddy_bear_3d.png",
	"🏆": "res://Assets/Social/FluentEmoji3D/trophy_3d.png",
	"💩": "res://Assets/Social/FluentEmoji3D/pile_of_poo_3d.png"
}


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
	TRICK,
	TURN_REMINDER
}


enum SocialAction {
	REACTION,
	STICKER,
	SOUNDPAD
}


enum UndoVoteState {
	NONE,
	APPROVED,
	REJECTED
}


enum TableFeltTheme {
	GREEN,
	BLUE,
	BURGUNDY
}


enum TableSurroundTheme {
	DARK_GREEN,
	DARK_WALNUT,
	LIGHT_OAK,
	DARK_CLUB,
	WARM_FABRIC
}


@onready var phase_label: Label = %PhaseLabel
@onready var trump_label: RichTextLabel = %TrumpLabel
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
@onready var history_label: RichTextLabel = %HistoryLabel
@onready var music_player_panel: PanelContainer = %MusicPlayerPanel
@onready var music_track_label: Label = %MusicTrackLabel
@onready var music_previous_button: Button = %MusicPreviousButton
@onready var music_play_pause_button: Button = %MusicPlayPauseButton
@onready var music_next_button: Button = %MusicNextButton
@onready var music_playlist_button: Button = %MusicPlaylistButton
@onready var music_add_button: Button = %MusicAddButton
@onready var round_results_panel: PanelContainer = %RoundResultsPanel
@onready var round_results_title_panel: PanelContainer = %RoundResultsTitlePanel
@onready var round_results_title: Label = %RoundResultsTitle
@onready var round_results_label: RichTextLabel = %RoundResultsLabel
@onready var first_turn_roll_panel: PanelContainer = %FirstTurnRollPanel
@onready var first_turn_roll_title: Label = %FirstTurnRollTitle
@onready var first_turn_roll_subtitle: Label = %FirstTurnRollSubtitle
@onready var first_turn_roll_grid: GridContainer = %FirstTurnRollGrid
@onready var first_turn_roll_status: Label = %FirstTurnRollStatus
@onready var first_turn_roll_button: Button = %FirstTurnRollButton
@onready var bid_controls: HBoxContainer = %BidControls
@onready var joker_controls: GridContainer = %JokerControls
@onready var hand_container: HBoxContainer = %HandContainer
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
var steam_bridge: RefCounted = SteamBridge.new()
var steam_lobby_status_label: Label
var steam_lobby_details_label: Label
var steam_lobby_members_label: Label
var steam_lobby_bot_difficulty_selector: OptionButton
var steam_lobby_history_mode_selector: OptionButton
var steam_p2p_status_label: Label
var steam_reconnect_controls: VBoxContainer
var steam_lobby_create_button: Button
var steam_lobby_invite_button: Button
var steam_lobby_ready_button: Button
var steam_p2p_prepare_button: Button
var steam_p2p_prepare_with_bots_button: Button
var steam_p2p_start_round_button: Button
var steam_p2p_open_table_button: Button
var steam_lobby_leave_button: Button
var player_labels: Array[Label] = []
var player_stats_labels: Array[RichTextLabel] = []
var player_score_labels: Array[Label] = []
var player_panels: Array[PanelContainer] = []
var avatar_badges: Array[PanelContainer] = []
var avatar_images: Array[TextureRect] = []
var avatar_labels: Array[Label] = []
var avatar_turn_labels: Array[Label] = []
var avatar_turn_glows: Array[ColorRect] = []
var avatar_action_trays: Array[HBoxContainer] = []
var avatar_action_tray_tweens: Dictionary = {}
var avatar_action_hide_generations: Dictionary = {}
var avatar_mute_buttons: Array[Button] = []
var avatar_gift_buttons: Array[Button] = []
var avatar_mute_hovered_slots: Dictionary = {}
var muted_network_player_indices: Dictionary = {}
var turn_timer_indicator: TurnTimerIndicator
var social_controls_container: VBoxContainer
var reaction_toggle_button: Button
var reaction_picker: PanelContainer
var reaction_bubble: PanelContainer
var reaction_bubble_label: Label
var reaction_bubble_image: TextureRect
var reaction_bubble_shadow: TextureRect
var reaction_bubble_tween: Tween
var sticker_toggle_button: Button
var sticker_picker: PanelContainer
var sticker_picker_title: Label
var sticker_picker_close_button: Button
var sticker_picker_content: VBoxContainer
var sticker_picker_auto_close_timer: Timer
var sticker_selected_target_index := -1
var sticker_flyers: Array[PanelContainer] = []
var sticker_flyer_labels: Array[Label] = []
var sticker_flyer_images: Array[TextureRect] = []
var sticker_flyer_shadows: Array[TextureRect] = []
var sticker_flyer_tweens: Dictionary = {}
var social_emoji_texture_cache: Dictionary = {}
var joker_celebration: Control
var joker_celebration_glow: ColorRect
var joker_celebration_shadow: TextureRect
var joker_celebration_image: TextureRect
var joker_celebration_sparkles: Array[Label] = []
var joker_celebration_tween: Tween
var soundpad_toggle_button: Button
var soundpad_picker: PanelContainer
var soundpad_picker_title: Label
var soundpad_picker_back_button: Button
var soundpad_picker_content: VBoxContainer
var soundpad_sounds: Array[Dictionary] = []
var soundpad_selected_category_id := ""
var soundpad_bubble: PanelContainer
var soundpad_bubble_label: Label
var soundpad_bubble_tween: Tween
var chat_toggle_button: Button
var chat_panel: PanelContainer
var chat_messages_scroll: ScrollContainer
var chat_messages_container: VBoxContainer
var chat_input: LineEdit
var chat_send_button: Button
var chat_status_label: Label
var network_chat_messages: Array[Dictionary] = []
var chat_unread_count := 0
var chat_next_send_milliseconds := 0
var trick_card_views: Array[CardView] = []
var bot_card_back_holders: Array[Control] = []
var deck_back_panels: Array[PanelContainer] = []
var deck_trump_panel: PanelContainer
var deck_trump_artwork: TextureRect
var deck_trump_label: Label
var deck_caption_label: Label
var dealer_marker: PanelContainer
var lead_marker: PanelContainer
var undo_vote_badges: Array[PanelContainer] = []
var undo_vote_labels: Array[Label] = []
var undo_vote_states: Array[int] = []
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
var undo_requests_for_current_decision := 0
var is_undo_vote_in_progress := false
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
var active_avatar_badge_style: StyleBoxFlat
var undo_vote_approved_style: StyleBoxFlat
var undo_vote_rejected_style: StyleBoxFlat
var menu_overlay: Control
var menu_backdrop: ColorRect
var menu_panel: PanelContainer
var menu_scroll: ScrollContainer
var menu_content: VBoxContainer
var card_deck_preview_container: HBoxContainer
var table_theme_preview_surround: PanelContainer
var table_theme_preview_felt: Panel
var local_table_outer: Panel
var local_table_cloth: Panel
var network_table_backdrop: ColorRect
var network_table_surface: Panel
var bot_speed_index := 1
var card_deck_style := CardArtworkResource.DEFAULT_DECK_STYLE
var table_felt_theme: TableFeltTheme = TableFeltTheme.GREEN
var table_surround_theme: TableSurroundTheme = TableSurroundTheme.DARK_GREEN
var match_history_mode := NetworkHost.HistoryMode.FULL
var bot_difficulty: BotDifficulty = BotDifficulty.NORMAL
var tutorial_enabled := false
var auto_turn_enabled := false
var turn_timer_active := false
var turn_timer_remaining := AUTO_TURN_DURATION_SECONDS
var social_action_uses: Dictionary = {
	SocialAction.REACTION: 0,
	SocialAction.STICKER: 0,
	SocialAction.SOUNDPAD: 0
}
var social_action_cooldown_until: Dictionary = {
	SocialAction.REACTION: 0,
	SocialAction.STICKER: 0,
	SocialAction.SOUNDPAD: 0
}
var sound_volume_index := 2
var music_volume_index := 2
var music_volume_percent := 60
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
var network_avatar_texture_cache: Dictionary = {}
var new_game_name_inputs: Array[LineEdit] = []
var new_game_avatar_selectors: Array[OptionButton] = []
var new_game_bot_difficulty_selector: OptionButton
var new_game_history_mode_selector: OptionButton
var profile_name_input: LineEdit
var profile_avatar_selector: OptionButton
var profile_avatar_status_label: Label
var profile_avatar_preview: TextureRect
var profile_avatar_preview_placeholder: Label
var profile_avatar_file_dialog: FileDialog
var pending_profile_avatar_path := ""
var is_avatar_file_dialog_for_new_game := false
var bug_report_file_dialog: FileDialog
var bug_report_description_input: TextEdit
var bug_report_status_label: Label
var is_bug_report_review_mode := false
var bug_report_timeline: Array[Dictionary] = []
var bug_report_review_timeline: Array[Dictionary] = []
var bug_report_review_index := -1
var bug_report_review_description := ""
var report_restore_player_names: Array[String] = []
var report_restore_avatar_indices: Array[int] = []
var report_restore_bot_difficulty: BotDifficulty = BotDifficulty.NORMAL
var profile_music_status_label: Label
var profile_music_playlist_container: VBoxContainer
var profile_music_file_dialog: FileDialog
var is_music_file_dialog_opened_from_table := false
var last_music_import_status := ""
var sound_players: Array[AudioStreamPlayer] = []
var sound_streams: Dictionary = {}
var next_sound_player_index := 0
var soundpad_players: Array[AudioStreamPlayer] = []
var next_soundpad_player_index := 0
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
var local_statistics: Dictionary = {
	"completed_games": 0,
	"wins": 0,
	"second_places": 0,
	"third_places": 0,
	"fourth_places": 0,
	"best_score": 0,
	"has_best_score": false,
	"last_place": 0,
	"last_score": 0,
	"last_exact_orders": 0,
	"last_shared_place": false
}
var game_statistics_recorded_for_current_session := false
var statistics_return_to_final_menu := false
var loopback_network_test
var steam_p2p_match
var loopback_network_status_label: Label
var loopback_network_start_round_button: Button
var loopback_network_start_joker_round_button: Button
var loopback_network_start_response_joker_round_button: Button
var loopback_network_private_hand_label: Label
var loopback_network_action_controls: VBoxContainer
var loopback_network_joker_selection_open := false
var loopback_network_pending_joker_suit := -1
var loopback_network_is_technical_presentation := true
var steam_p2p_table_presentation := false
var steam_p2p_main_table_presentation := false
var network_round_result_key := ""
var network_round_finish_presentation_key := ""
var network_round_finish_presentation_active := false
var network_visual_round_number := -1
var network_collected_trick_key := ""
var network_public_event_stream_key := ""
var network_last_public_event_id := -1
var network_card_event_queue: Array[Dictionary] = []
var network_card_play_presentation_active := false
var network_table_state_reset_id := -1
var network_table_view: Control
var network_table_title_label: Label
var network_table_round_label: Label
var network_table_info_label: Label
var network_table_info_panel: PanelContainer
var network_table_history_label: RichTextLabel
var network_table_deck_label: Label
var network_table_deck_visual: Control
var network_table_trump_card_view: CardView
var network_table_deck_back_panels: Array[PanelContainer] = []
var network_table_trick_label: Label
var network_table_joker_label: Label
var network_table_trick_layer: Control
var network_table_hand_container: HBoxContainer
var network_table_action_panel: PanelContainer
var network_table_action_controls: VBoxContainer
var network_table_close_button: Button
var network_table_player_panels: Array[PanelContainer] = []
var network_table_player_name_labels: Array[Label] = []
var network_table_player_stats_labels: Array[RichTextLabel] = []
var network_table_player_score_labels: Array[Label] = []
var network_table_avatar_panels: Array[PanelContainer] = []
var network_table_avatar_images: Array[TextureRect] = []
var network_table_avatar_symbols: Array[Label] = []
var local_first_turn_roll_active := false
var local_first_turn_roll_round := 0
var local_first_turn_roll_contenders: Array[int] = []
var local_first_turn_roll_values: Array[int] = []
var local_first_turn_roll_winner_index := -1
var local_first_turn_roll_random := RandomNumberGenerator.new()
var local_first_turn_roll_generation := 0
var turn_reminder_decision_key := ""
var turn_reminder_elapsed_seconds := 0.0
var turn_reminder_was_played := false
var turn_reminder_play_count := 0
var turn_reminder_next_sound_seconds := TURN_REMINDER_DELAY_SECONDS
var displayed_player_scores: Array[int] = []
var player_score_tweens: Dictionary = {}


func _ready() -> void:
	bot_random.randomize()
	steam_bridge.lobby_status_changed.connect(_refresh_steam_lobby_status)
	steam_bridge.lobby_joined_successfully.connect(_on_steam_lobby_joined_successfully)
	_run_joker_rule_checks()
	_run_score_rule_checks()
	_run_dark_round_checks()
	_run_no_trump_round_checks()
	_run_no_bid_round_checks()
	_run_bot_rule_checks()
	_run_hand_sort_checks()
	_run_round_history_checks()
	_run_session_save_checks()
	_run_network_snapshot_checks()
	_run_local_match_host_checks()
	_run_network_special_round_checks()
	_load_persistent_settings()
	CardArtworkResource.set_deck_style(card_deck_style)
	_create_table_visual_styles()
	_create_score_sheet_overlay()
	_create_table_surface()
	_create_player_panels()
	_create_player_avatar_badges()
	_create_joker_celebration_effect()
	_create_trick_slots()
	_create_bot_card_backs()
	_create_deck_visual()
	_create_table_markers()
	_create_social_controls_container()
	_create_reaction_controls()
	_create_sticker_controls()
	_create_soundpad_controls()
	_create_chat_controls()
	_create_sound_players()
	_create_background_music_player()
	music_player_panel.reparent(self)
	# Внизу слева плеер пересекался с длинным выбором условий Джокера.
	# Переносим его в свободную зону справа от истории раздачи.
	_set_control_layout(music_player_panel, 0.0, 0.0, 0.0, 0.0, 316.0, 54.0, 592.0, 132.0)
	music_player_panel.z_index = 90
	_create_music_controls_popup()
	_create_tutorial_panel()
	_create_profile_avatar_file_dialog()
	_create_bug_report_file_dialog()
	_create_profile_music_file_dialog()
	joker_controls.reparent(self)
	_create_main_menu()
	loopback_network_test = LoopbackNetwork.new()
	loopback_network_test.status_changed.connect(_refresh_loopback_network_status)
	loopback_network_test.public_table_event_received.connect(_on_network_public_table_event_received)
	loopback_network_test.player_snapshot_received.connect(_on_network_player_snapshot_received)
	add_child(loopback_network_test)
	steam_p2p_match = SteamP2PMatch.new()
	steam_p2p_match.name = "SteamP2PMatch"
	steam_p2p_match.status_changed.connect(_refresh_steam_p2p_status)
	steam_p2p_match.public_table_event_received.connect(_on_network_public_table_event_received)
	steam_p2p_match.player_snapshot_received.connect(_on_network_player_snapshot_received)
	add_child(steam_p2p_match)
	_create_network_table_view()
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
	first_turn_roll_button.pressed.connect(_on_first_turn_roll_action_pressed)
	pause_menu_button.pressed.connect(_on_pause_menu_pressed)
	if _is_loopback_network_client_launch():
		if _is_loopback_network_party_client_launch():
			_show_network_party_lobby()
		else:
			_show_loopback_network_test_menu()
		call_deferred("_start_loopback_network_client_from_launch")
	elif steam_bridge.has_lobby_join_request_from_launch():
		steam_bridge.initialize_for_diagnostics()
		steam_bridge.join_lobby_from_launch()
		_show_steam_lobby_menu()
	else:
		_show_main_menu()


func _create_table_visual_styles() -> void:
	_apply_surround_theme_to_rect(background)
	table_panel.add_theme_stylebox_override(
		"panel",
		_create_flat_style(_get_felt_color().darkened(0.48), Color(0.265, 0.145, 0.058, 1.0), 8, 16, 8)
	)
	player_panel_style = _create_flat_style(Color(0.028, 0.073, 0.052, 0.96), Color(0.38, 0.255, 0.11, 0.86), 1, 10, 3)
	human_player_panel_style = player_panel_style
	active_player_panel_style = _create_flat_style(Color(0.105, 0.12, 0.052, 0.98), Color(0.95, 0.75, 0.28, 1.0), 3, 10, 7)
	active_human_player_panel_style = active_player_panel_style
	card_back_style = _create_flat_style(Color(0.045, 0.11, 0.22, 1.0), Color(0.8, 0.62, 0.25, 1.0), 2, 6, 2)
	deck_trump_card_style = _create_flat_style(Color(0.92, 0.9, 0.76, 1.0), Color(0.88, 0.68, 0.24, 1.0), 2, 8, 3)
	dealer_marker_style = _create_flat_style(Color(0.33, 0.2, 0.07, 1.0), Color(0.96, 0.77, 0.31, 1.0), 2, 18, 3)
	lead_marker_style = _create_flat_style(Color(0.055, 0.2, 0.13, 1.0), Color(0.64, 0.86, 0.52, 1.0), 1, 8, 2)
	avatar_badge_style = _create_flat_style(Color(0.04, 0.1, 0.07, 1.0), Color(0.75, 0.58, 0.2, 1.0), 2, 6, 2)
	active_avatar_badge_style = _create_flat_style(Color(0.12, 0.14, 0.045, 1.0), Color(1.0, 0.82, 0.24, 1.0), 5, 10, 12)
	undo_vote_approved_style = _create_flat_style(Color(0.05, 0.34, 0.14, 0.98), Color(0.62, 0.94, 0.46, 1.0), 2, 14, 2)
	undo_vote_rejected_style = _create_flat_style(Color(0.36, 0.07, 0.06, 0.98), Color(1.0, 0.52, 0.42, 1.0), 2, 14, 2)
	music_player_panel.add_theme_stylebox_override("panel", _create_flat_style(Color(0.012, 0.055, 0.034, 0.94), Color(0.38, 0.255, 0.11, 0.0), 0, 6, 0))
	var round_results_style := _create_flat_style(Color(0.018, 0.08, 0.052, 0.97), Color(0.38, 0.255, 0.11, 0.78), 1, 10, 3)
	round_results_style.content_margin_left = 12.0
	round_results_style.content_margin_top = 12.0
	round_results_style.content_margin_right = 12.0
	round_results_style.content_margin_bottom = 12.0
	round_results_panel.add_theme_stylebox_override("panel", round_results_style)
	var round_results_title_style := _create_flat_style(Color(0.15, 0.105, 0.035, 0.96), Color(0.86, 0.64, 0.2, 0.92), 1, 7, 1)
	round_results_title_style.content_margin_left = 8.0
	round_results_title_style.content_margin_right = 8.0
	round_results_title_panel.add_theme_stylebox_override("panel", round_results_title_style)
	var round_history_style := _create_flat_style(Color(0.965, 0.95, 0.89, 0.98), Color(0.45, 0.31, 0.12, 0.9), 2, 10, 3)
	round_history_style.content_margin_left = 10.0
	round_history_style.content_margin_top = 8.0
	round_history_style.content_margin_right = 10.0
	round_history_style.content_margin_bottom = 8.0
	round_history_panel.add_theme_stylebox_override("panel", round_history_style)
	history_label.add_theme_color_override("default_color", Color(0.08, 0.09, 0.075, 1.0))
	history_label.add_theme_color_override("font_color", Color(0.08, 0.09, 0.075, 1.0))
	var first_turn_roll_style := _create_flat_style(Color(0.012, 0.065, 0.04, 0.99), Color(0.91, 0.67, 0.2, 0.96), 2, 14, 8)
	first_turn_roll_style.content_margin_left = 24.0
	first_turn_roll_style.content_margin_top = 20.0
	first_turn_roll_style.content_margin_right = 24.0
	first_turn_roll_style.content_margin_bottom = 20.0
	first_turn_roll_panel.add_theme_stylebox_override("panel", first_turn_roll_style)
	_apply_table_action_button_style(first_turn_roll_button)
	_apply_table_text_button_style(round_history_toggle_button)
	_apply_table_text_button_style(score_sheet_toggle_button)
	_apply_table_text_button_style(pause_menu_button)
	_apply_table_action_button_style(hand_sort_by_suit_button)
	_apply_table_action_button_style(hand_sort_trumps_left_button)
	_apply_table_action_button_style(undo_button)
	_apply_table_action_button_style(next_round_button)
	next_round_button.add_theme_font_size_override("font_size", 18)


func _create_table_surface() -> void:
	# Первый тестовый вариант стола: форму можно позднее заменить на квадратную,
	# не меняя расположение игроков и игровую логику.
	local_table_outer = Panel.new()
	local_table_outer.name = "OvalTableOuter"
	local_table_outer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var outer_table_style := _create_flat_style(_get_table_rim_color(), Color(0.6, 0.39, 0.13, 1.0), 7, 286, 10)
	outer_table_style.corner_detail = 64
	local_table_outer.add_theme_stylebox_override("panel", outer_table_style)
	_set_control_layout(local_table_outer, 0.5, 0.0, 0.5, 0.0, -660.0, 150.0, 660.0, 710.0)
	players_container.add_child(local_table_outer)

	local_table_cloth = Panel.new()
	local_table_cloth.name = "OvalTableCloth"
	local_table_cloth.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var inner_table_style := _create_flat_style(_get_felt_color(), _get_felt_border_color(), 3, 266, 0)
	inner_table_style.corner_detail = 64
	local_table_cloth.add_theme_stylebox_override("panel", inner_table_style)
	local_table_cloth.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	local_table_cloth.offset_left = 18.0
	local_table_cloth.offset_top = 18.0
	local_table_cloth.offset_right = -18.0
	local_table_cloth.offset_bottom = -18.0
	local_table_outer.add_child(local_table_cloth)


func _get_felt_color(theme: int = table_felt_theme) -> Color:
	match clampi(theme, TableFeltTheme.GREEN, TableFeltTheme.BURGUNDY):
		TableFeltTheme.BLUE:
			return Color(0.035, 0.19, 0.34, 1.0)
		TableFeltTheme.BURGUNDY:
			return Color(0.31, 0.055, 0.085, 1.0)
		_:
			return Color(0.035, 0.255, 0.145, 1.0)


func _get_felt_border_color(theme: int = table_felt_theme) -> Color:
	match clampi(theme, TableFeltTheme.GREEN, TableFeltTheme.BURGUNDY):
		TableFeltTheme.BLUE:
			return Color(0.57, 0.76, 0.9, 0.76)
		TableFeltTheme.BURGUNDY:
			return Color(0.91, 0.67, 0.62, 0.76)
		_:
			return Color(0.74, 0.84, 0.66, 0.72)


func _get_surround_color(theme: int = table_surround_theme) -> Color:
	match clampi(theme, TableSurroundTheme.DARK_GREEN, TableSurroundTheme.WARM_FABRIC):
		TableSurroundTheme.DARK_WALNUT:
			return Color(0.115, 0.062, 0.028, 1.0)
		TableSurroundTheme.LIGHT_OAK:
			return Color(0.34, 0.205, 0.095, 1.0)
		TableSurroundTheme.DARK_CLUB:
			return Color(0.025, 0.024, 0.038, 1.0)
		TableSurroundTheme.WARM_FABRIC:
			return Color(0.19, 0.105, 0.075, 1.0)
		_:
			return Color(0.008, 0.05, 0.032, 1.0)


func _get_surround_pattern(theme: int = table_surround_theme) -> int:
	match clampi(theme, TableSurroundTheme.DARK_GREEN, TableSurroundTheme.WARM_FABRIC):
		TableSurroundTheme.DARK_WALNUT, TableSurroundTheme.LIGHT_OAK:
			return 1
		TableSurroundTheme.WARM_FABRIC:
			return 2
		TableSurroundTheme.DARK_CLUB:
			return 3
		_:
			return 0


func _get_table_rim_color() -> Color:
	if table_surround_theme == TableSurroundTheme.LIGHT_OAK:
		return Color(0.31, 0.165, 0.06, 1.0)
	return Color(0.115, 0.062, 0.028, 1.0)


func _apply_surround_theme_to_rect(rect: ColorRect) -> void:
	if not is_instance_valid(rect):
		return
	rect.color = Color.WHITE
	var shader := Shader.new()
	shader.code = TABLE_SURROUND_SHADER_CODE
	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("base_color", _get_surround_color())
	material.set_shader_parameter("pattern_kind", _get_surround_pattern())
	rect.material = material


func _apply_table_theme() -> void:
	_apply_surround_theme_to_rect(background)
	_apply_surround_theme_to_rect(network_table_backdrop)
	table_panel.add_theme_stylebox_override(
		"panel",
		_create_flat_style(_get_felt_color().darkened(0.48), Color(0.265, 0.145, 0.058, 1.0), 8, 16, 8)
	)
	if is_instance_valid(local_table_outer):
		var outer_style := _create_flat_style(_get_table_rim_color(), Color(0.6, 0.39, 0.13, 1.0), 7, 286, 10)
		outer_style.corner_detail = 64
		local_table_outer.add_theme_stylebox_override("panel", outer_style)
	if is_instance_valid(local_table_cloth):
		var cloth_style := _create_flat_style(_get_felt_color(), _get_felt_border_color(), 3, 266, 0)
		cloth_style.corner_detail = 64
		local_table_cloth.add_theme_stylebox_override("panel", cloth_style)
	if is_instance_valid(network_table_surface):
		network_table_surface.add_theme_stylebox_override(
			"panel",
			_create_flat_style(_get_felt_color().darkened(0.12), _get_table_rim_color().lightened(0.24), 8, 250, 10)
		)
	_refresh_table_theme_preview()


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
	score_sheet_close_button.text = "×"
	score_sheet_close_button.tooltip_text = "Закрыть расписку"
	score_sheet_close_button.custom_minimum_size = Vector2(44.0, 44.0)
	score_sheet_close_button.add_theme_font_size_override("font_size", 30)
	score_sheet_close_button.add_theme_color_override("font_color", Color(0.82, 0.9, 0.82, 1.0))
	score_sheet_close_button.add_theme_color_override("font_hover_color", Color(1.0, 0.84, 0.38, 1.0))
	score_sheet_close_button.add_theme_color_override("font_pressed_color", Color(0.98, 0.66, 0.28, 1.0))
	score_sheet_close_button.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	score_sheet_close_button.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	score_sheet_close_button.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	score_sheet_close_button.z_index = 96
	score_sheet_close_button.visible = false
	_set_control_layout(score_sheet_close_button, 0.5, 0.5, 0.5, 0.5, 704.0, -438.0, 748.0, -394.0)
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


func _apply_table_action_button_style(button: Button) -> void:
	button.add_theme_font_size_override("font_size", 15)
	button.add_theme_color_override("font_color", Color(0.96, 0.97, 0.94, 1.0))
	button.add_theme_color_override("font_hover_color", Color(1.0, 0.94, 0.72, 1.0))
	button.add_theme_color_override("font_pressed_color", Color(1.0, 0.88, 0.48, 1.0))
	button.add_theme_color_override("font_disabled_color", Color(0.72, 0.74, 0.68, 0.82))
	var normal_style := _create_flat_style(Color(0.012, 0.02, 0.016, 0.98), Color(0.48, 0.35, 0.11, 0.96), 2, 6, 3)
	normal_style.content_margin_left = 10.0
	normal_style.content_margin_right = 10.0
	button.add_theme_stylebox_override("normal", normal_style)
	var hover_style := _create_flat_style(Color(0.09, 0.072, 0.025, 1.0), Color(0.98, 0.77, 0.28, 1.0), 2, 6, 5)
	hover_style.content_margin_left = 10.0
	hover_style.content_margin_right = 10.0
	button.add_theme_stylebox_override("hover", hover_style)
	var pressed_style := _create_flat_style(Color(0.18, 0.125, 0.028, 1.0), Color(1.0, 0.83, 0.33, 1.0), 2, 6, 2)
	pressed_style.content_margin_left = 10.0
	pressed_style.content_margin_right = 10.0
	button.add_theme_stylebox_override("pressed", pressed_style)
	var disabled_style := _create_flat_style(Color(0.022, 0.028, 0.022, 0.94), Color(0.36, 0.29, 0.12, 0.7), 1, 6, 0)
	disabled_style.content_margin_left = 10.0
	disabled_style.content_margin_right = 10.0
	button.add_theme_stylebox_override("disabled", disabled_style)


func _apply_table_text_button_style(button: Button) -> void:
	button.add_theme_font_size_override("font_size", 16)
	button.add_theme_color_override("font_color", Color(0.84, 0.91, 0.84, 1.0))
	button.add_theme_color_override("font_hover_color", Color(1.0, 0.84, 0.38, 1.0))
	button.add_theme_color_override("font_pressed_color", Color(0.98, 0.66, 0.28, 1.0))
	button.add_theme_color_override("font_disabled_color", Color(0.5, 0.58, 0.52, 0.75))
	button.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	button.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	button.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	button.add_theme_stylebox_override("disabled", StyleBoxEmpty.new())
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())


func _create_main_menu() -> void:
	menu_overlay = Control.new()
	menu_overlay.name = "MainMenuOverlay"
	_set_control_layout(menu_overlay, 0.0, 0.0, 1.0, 1.0, 0.0, 0.0, 0.0, 0.0)
	menu_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	menu_overlay.z_index = 100
	add_child(menu_overlay)

	menu_backdrop = ColorRect.new()
	menu_backdrop.color = Color(0.006, 0.055, 0.034, 0.98)
	menu_backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	menu_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu_backdrop.material = _create_menu_backdrop_material()
	menu_backdrop.gui_input.connect(_on_menu_backdrop_gui_input)
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

	menu_scroll = ScrollContainer.new()
	menu_scroll.name = "MenuScroll"
	menu_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	menu_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	menu_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	menu_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	menu_margin.add_child(menu_scroll)

	menu_content = VBoxContainer.new()
	menu_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	menu_content.add_theme_constant_override("separation", 14)
	menu_scroll.add_child(menu_content)


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


func _create_menu_backdrop_material() -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = """
		shader_type canvas_item;

		uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;

		void fragment() {
			vec4 table = textureLod(screen_texture, SCREEN_UV, 3.0);
			vec3 overlay = vec3(0.006, 0.055, 0.034);
			COLOR = vec4(mix(table.rgb, overlay, 0.72), 1.0);
		}
	"""
	var material := ShaderMaterial.new()
	material.shader = shader
	return material


func _on_menu_backdrop_gui_input(event: InputEvent) -> void:
	if not is_pause_menu_open or is_bug_report_review_mode:
		return

	var mouse_button_event: InputEventMouseButton = event as InputEventMouseButton
	if mouse_button_event != null and mouse_button_event.button_index == MOUSE_BUTTON_LEFT and mouse_button_event.pressed:
		_resume_current_game()


func _build_main_menu_content() -> void:
	_clear_children(menu_content)
	_add_menu_title("PROJECT JOKER", "Локальная карточная партия для четырёх игроков · %s" % _get_build_version_text())
	_add_menu_spacer(18.0)
	if _has_saved_session():
		_add_menu_button("Продолжить партию", _on_continue_saved_game_pressed, true)
	_add_menu_button("Новая партия", _show_new_game_setup, true)
	_add_menu_button("Обучение", _show_tutorial_menu)
	_add_menu_button("Профиль", _show_profile_menu)
	_add_menu_button("Статистика", _show_statistics_menu)
	if _developer_report_tools_enabled():
		_add_menu_button("Инструменты разработчика", _show_developer_tools_menu)
	_add_menu_button("Правила", _show_rules_menu)
	_add_menu_button("Настройки", _show_settings_menu)
	_add_menu_button("Выход", _on_quit_pressed)
	_add_menu_spacer(12.0)
	_add_menu_label("32 раздачи: обычные, тёмные, бескозырные, золотые и мизерные.", 14, Color(0.72, 0.85, 0.76, 1.0))


func _developer_report_tools_enabled() -> bool:
	return DEVELOPER_REPORT_TOOLS_ENABLED


func _get_build_version_text() -> String:
	return "версия разработчика %s" % GAME_VERSION if _developer_report_tools_enabled() else "версия для игроков %s" % GAME_VERSION


func _show_developer_tools_menu() -> void:
	_clear_children(menu_content)
	_add_menu_title("Инструменты разработчика", "Локальные проверки, отчёты и подготовка Steam — эти пункты не войдут в публичное меню")
	_add_menu_spacer(14.0)
	_add_menu_button("Загрузить отчёт", _open_bug_report_file_dialog)
	_add_menu_button("Сетевая партия (локально)", _show_network_party_lobby, true)
	_add_menu_button("Локальная сеть (тест)", _show_loopback_network_test_menu)
	_add_menu_button("Steam · диагностика", _show_steam_diagnostics_menu)
	_add_menu_button("Steam-комната (тест)", _show_steam_lobby_menu)
	_add_menu_spacer(10.0)
	_add_menu_button("Назад", _build_main_menu_content)


func _show_steam_diagnostics_menu() -> void:
	_clear_children(menu_content)
	_add_menu_title("Steam · диагностика", "Безопасная проверка среды — без App ID, ключей, лобби и подключения игроков")
	_add_menu_spacer(12.0)

	var diagnostics: Dictionary = steam_bridge.get_diagnostics()
	var runtime_available := bool(diagnostics.get("runtime_available", false))
	var singleton_available := bool(diagnostics.get("singleton_available", false))
	var can_initialize := bool(diagnostics.get("can_initialize", false))
	var app_id_configured := bool(diagnostics.get("app_id_configured", false))
	var initialization_attempted := bool(diagnostics.get("initialization_attempted", false))
	var initialized := bool(diagnostics.get("initialized", false))
	var available_color := Color(0.72, 0.9, 0.62, 1.0)
	var waiting_color := Color(0.96, 0.78, 0.38, 1.0)
	var muted_color := Color(0.72, 0.85, 0.76, 1.0)

	_add_menu_label("GodotSteam: %s" % ("найден" if runtime_available else "не найден"), 18, available_color if runtime_available else waiting_color)
	_add_menu_label("Steam API: %s" % ("доступен" if singleton_available else "пока не инициализирован"), 16, available_color if singleton_available else muted_color)
	_add_menu_label("Метод инициализации: %s" % ("готов" if can_initialize else "недоступен"), 16, available_color if can_initialize else muted_color)
	_add_menu_label("Локальный App ID: %s" % ("найден" if app_id_configured else "ещё не задан"), 16, muted_color)
	if initialized:
		var persona_name := str(diagnostics.get("persona_name", ""))
		var active_app_id := int(diagnostics.get("active_app_id", 0))
		_add_menu_label("Steam-клиент: подключён", 16, available_color)
		_add_menu_label("Профиль Steam: %s · тестовый App ID: %d" % [persona_name if not persona_name.is_empty() else "без имени", active_app_id], 16, muted_color)
	elif initialization_attempted:
		var initialization_status := int(diagnostics.get("initialization_status", -1))
		var initialization_verbal := str(diagnostics.get("initialization_verbal", ""))
		_add_menu_label("Steam-клиент: не подтвердил подключение · код %d" % initialization_status, 16, waiting_color)
		if not initialization_verbal.is_empty():
			_add_menu_label(initialization_verbal, 15, muted_color)
	_add_menu_spacer(8.0)
	_add_menu_label(str(diagnostics.get("message", "Статус Steam не получен.")), 15, muted_color)
	_add_menu_spacer(16.0)
	_add_menu_label("Тест использует технический App ID 480 только на этом компьютере. Он не войдёт в экспорт, не создаёт лобби и не подключает других игроков.", 14, muted_color)
	_add_menu_spacer(16.0)
	if can_initialize and not initialized:
		_add_menu_button("Проверить Steam-клиент", _on_initialize_steam_diagnostics_pressed, true)
	_add_menu_button("Обновить статус", _show_steam_diagnostics_menu)
	_add_menu_button("Назад", _build_main_menu_content)


func _on_initialize_steam_diagnostics_pressed() -> void:
	steam_bridge.initialize_for_diagnostics()
	_show_steam_diagnostics_menu()


func _show_steam_lobby_menu() -> void:
	is_pause_menu_open = false
	menu_overlay.visible = true
	_clear_children(menu_content)
	_add_menu_title("Приватная Steam-комната", "Четыре места · друзья через Steam · свободные места можно заполнить ботами")
	_add_menu_spacer(12.0)

	steam_lobby_status_label = Label.new()
	steam_lobby_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	steam_lobby_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	steam_lobby_status_label.add_theme_font_size_override("font_size", 18)
	steam_lobby_status_label.add_theme_color_override("font_color", Color(0.72, 0.9, 0.62, 1.0))
	menu_content.add_child(steam_lobby_status_label)

	steam_lobby_details_label = Label.new()
	steam_lobby_details_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	steam_lobby_details_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	steam_lobby_details_label.add_theme_font_size_override("font_size", 15)
	steam_lobby_details_label.add_theme_color_override("font_color", Color(0.72, 0.85, 0.76, 1.0))
	menu_content.add_child(steam_lobby_details_label)

	steam_lobby_members_label = Label.new()
	steam_lobby_members_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	steam_lobby_members_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	steam_lobby_members_label.add_theme_font_size_override("font_size", 15)
	steam_lobby_members_label.add_theme_color_override("font_color", Color(0.86, 0.9, 0.82, 1.0))
	menu_content.add_child(steam_lobby_members_label)

	steam_p2p_status_label = Label.new()
	steam_p2p_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	steam_p2p_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	steam_p2p_status_label.add_theme_font_size_override("font_size", 14)
	steam_p2p_status_label.add_theme_color_override("font_color", Color(0.76, 0.87, 0.82, 1.0))
	menu_content.add_child(steam_p2p_status_label)

	steam_reconnect_controls = VBoxContainer.new()
	steam_reconnect_controls.add_theme_constant_override("separation", 8)
	menu_content.add_child(steam_reconnect_controls)

	var bot_difficulty_label := Label.new()
	bot_difficulty_label.text = "Сложность ботов за сетевым столом"
	bot_difficulty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bot_difficulty_label.add_theme_font_size_override("font_size", 16)
	bot_difficulty_label.add_theme_color_override("font_color", Color(0.91, 0.96, 0.91, 1.0))
	menu_content.add_child(bot_difficulty_label)

	steam_lobby_bot_difficulty_selector = OptionButton.new()
	for difficulty in BOT_DIFFICULTY_COUNT:
		steam_lobby_bot_difficulty_selector.add_item(_get_bot_difficulty_label(difficulty))
	steam_lobby_bot_difficulty_selector.selected = bot_difficulty
	steam_lobby_bot_difficulty_selector.custom_minimum_size = Vector2(0.0, 42.0)
	steam_lobby_bot_difficulty_selector.add_theme_font_size_override("font_size", 16)
	steam_lobby_bot_difficulty_selector.item_selected.connect(_on_steam_lobby_bot_difficulty_selected)
	menu_content.add_child(steam_lobby_bot_difficulty_selector)

	var history_mode_label := Label.new()
	history_mode_label.text = "История раздачи"
	history_mode_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	history_mode_label.add_theme_font_size_override("font_size", 16)
	history_mode_label.add_theme_color_override("font_color", Color(0.91, 0.96, 0.91, 1.0))
	menu_content.add_child(history_mode_label)

	steam_lobby_history_mode_selector = OptionButton.new()
	steam_lobby_history_mode_selector.name = "SteamLobbyHistoryModeSelector"
	steam_lobby_history_mode_selector.add_item(_get_history_mode_label(NetworkHost.HistoryMode.FULL))
	steam_lobby_history_mode_selector.add_item(_get_history_mode_label(NetworkHost.HistoryMode.LAST_TRICK_ONLY))
	steam_lobby_history_mode_selector.selected = match_history_mode
	steam_lobby_history_mode_selector.custom_minimum_size = Vector2(0.0, 42.0)
	steam_lobby_history_mode_selector.add_theme_font_size_override("font_size", 16)
	steam_lobby_history_mode_selector.item_selected.connect(_on_steam_lobby_history_mode_selected)
	menu_content.add_child(steam_lobby_history_mode_selector)
	_add_menu_label("Полная — видны все сыгранные карты. «Только последняя взятка» скрывает старые ходы и оставляет последнюю завершённую взятку плюс текущие карты на столе.", 14, Color(0.72, 0.85, 0.76, 1.0))

	_add_menu_spacer(14.0)
	steam_lobby_create_button = _add_menu_button("Создать закрытую комнату", _on_create_steam_lobby_pressed, true)
	steam_lobby_invite_button = _add_menu_button("Пригласить друга через Steam", _on_open_steam_lobby_invite_pressed)
	steam_lobby_ready_button = _add_menu_button("Отметиться готовым", _on_toggle_steam_lobby_ready_pressed)
	steam_p2p_prepare_button = _add_menu_button("Подключиться к игровому столу", _on_prepare_steam_p2p_pressed)
	steam_p2p_prepare_with_bots_button = _add_menu_button("Заполнить свободные места ботами", _on_toggle_steam_lobby_bots_pressed)
	steam_p2p_start_round_button = _add_menu_button("Разыграть первый ход", _on_start_steam_p2p_round_pressed, true)
	steam_p2p_open_table_button = _add_menu_button("Открыть Steam P2P-стол", _on_open_steam_p2p_table_pressed)
	steam_lobby_leave_button = _add_menu_button("Выйти из комнаты", _on_leave_steam_lobby_pressed)
	_add_menu_spacer(10.0)
	_add_menu_label("Приглашение открывает стандартный Steam Overlay. Хост может заполнить свободные места ботами или дождаться четырёх людей. Все живые участники отмечают готовность и подключаются к игровому столу, после чего хост начинает полноценную партию. Хост проверяет команды и отправляет каждому только его закрытую руку.", 14, Color(0.72, 0.85, 0.76, 1.0))
	_add_menu_spacer(14.0)
	_add_menu_button("Назад", _show_developer_tools_menu)
	_refresh_steam_lobby_status()


func _on_steam_lobby_joined_successfully() -> void:
	# Внешнее приглашение Steam может прийти, пока открыт локальный стол.
	# В этом случае переводим интерфейс прямо в Steam-комнату, не меняя
	# саму локальную партию и не оставляя пользователя в меню паузы.
	steam_p2p_table_presentation = false
	steam_p2p_main_table_presentation = false
	_reset_loopback_network_joker_selection()
	if is_instance_valid(network_table_view):
		network_table_view.visible = false
	_show_steam_lobby_menu()


func _on_create_steam_lobby_pressed() -> void:
	var lobby_state: Dictionary = steam_bridge.get_lobby_state()
	if not bool(lobby_state.get("initialized", false)):
		steam_bridge.initialize_for_diagnostics()
	steam_bridge.create_friends_lobby()
	_refresh_steam_lobby_status()


func _on_leave_steam_lobby_pressed() -> void:
	if steam_p2p_match != null and steam_p2p_match.is_running():
		steam_p2p_match.stop()
	steam_p2p_table_presentation = false
	steam_p2p_main_table_presentation = false
	steam_bridge.leave_lobby()
	_refresh_steam_lobby_status()


func _on_open_steam_lobby_invite_pressed() -> void:
	steam_bridge.open_lobby_invite_overlay()
	_refresh_steam_lobby_status()


func _on_toggle_steam_lobby_ready_pressed() -> void:
	var lobby_state: Dictionary = steam_bridge.get_lobby_state()
	steam_bridge.set_local_lobby_ready(not bool(lobby_state.get("local_ready", false)))
	_refresh_steam_lobby_status()


func _on_prepare_steam_p2p_pressed() -> void:
	_reset_loopback_network_joker_selection()
	muted_network_player_indices.clear()
	avatar_mute_hovered_slots.clear()
	var lobby_state: Dictionary = steam_bridge.get_lobby_state()
	steam_p2p_match.start_from_current_lobby(
		steam_bridge,
		bool(lobby_state.get("fill_empty_seats_with_bots", false)),
		int(lobby_state.get("bot_difficulty", bot_difficulty)),
		configured_player_names[HUMAN_PLAYER_INDEX],
		auto_turn_enabled,
		configured_avatar_indices[HUMAN_PLAYER_INDEX],
		_get_local_network_avatar_data(),
		int(lobby_state.get("history_mode", match_history_mode))
	)
	_refresh_steam_lobby_status()


func _on_toggle_steam_lobby_bots_pressed() -> void:
	var lobby_state: Dictionary = steam_bridge.get_lobby_state()
	steam_bridge.set_fill_empty_seats_with_bots(not bool(lobby_state.get("fill_empty_seats_with_bots", false)))
	_refresh_steam_lobby_status()


func _on_steam_lobby_bot_difficulty_selected(selected_index: int) -> void:
	bot_difficulty = clampi(selected_index, 0, BOT_DIFFICULTY_COUNT - 1)
	steam_bridge.set_lobby_bot_difficulty(bot_difficulty)
	if steam_p2p_match != null and steam_p2p_match.is_host():
		steam_p2p_match.set_bot_difficulty(bot_difficulty)
	_save_persistent_settings()
	_refresh_steam_lobby_status()


func _on_steam_lobby_history_mode_selected(selected_index: int) -> void:
	match_history_mode = clampi(
		selected_index,
		NetworkHost.HistoryMode.FULL,
		NetworkHost.HistoryMode.LAST_TRICK_ONLY
	)
	steam_bridge.set_lobby_history_mode(match_history_mode)
	_save_persistent_settings()
	_refresh_steam_lobby_status()


func _on_start_steam_p2p_round_pressed() -> void:
	if steam_p2p_match == null or not steam_p2p_match.is_host():
		return
	_reset_loopback_network_joker_selection()
	if steam_p2p_match.can_begin_first_turn_roll():
		if steam_p2p_match.begin_first_turn_roll():
			_on_open_steam_p2p_table_pressed()
	elif steam_p2p_match.can_start_first_real_round():
		steam_p2p_match.start_first_real_round()
	_refresh_steam_lobby_status()


func _on_open_steam_p2p_table_pressed() -> void:
	if steam_p2p_match == null or not steam_p2p_match.is_running():
		return
	steam_p2p_table_presentation = true
	steam_p2p_main_table_presentation = true
	_reset_loopback_network_joker_selection()
	menu_overlay.visible = false
	if is_instance_valid(network_table_view):
		network_table_view.visible = false
	_refresh_network_main_table()


func _refresh_steam_lobby_status() -> void:
	if not is_instance_valid(steam_lobby_status_label) or not is_instance_valid(steam_lobby_details_label) or not is_instance_valid(steam_lobby_members_label):
		return

	var lobby_state: Dictionary = steam_bridge.get_lobby_state()
	var initialized := bool(lobby_state.get("initialized", false))
	var lobby_id := int(lobby_state.get("lobby_id", 0))
	var member_count := int(lobby_state.get("member_count", 0))
	var member_limit := int(lobby_state.get("member_limit", 4))
	var lobby_status := str(lobby_state.get("status", "Статус Steam-комнаты не получен."))
	var local_ready := bool(lobby_state.get("local_ready", false))
	var fill_empty_seats_with_bots := bool(lobby_state.get("fill_empty_seats_with_bots", false))
	var lobby_bot_difficulty := clampi(int(lobby_state.get("bot_difficulty", bot_difficulty)), 0, BOT_DIFFICULTY_COUNT - 1)
	var lobby_history_mode := clampi(
		int(lobby_state.get("history_mode", match_history_mode)),
		NetworkHost.HistoryMode.FULL,
		NetworkHost.HistoryMode.LAST_TRICK_ONLY
	)
	var bot_count := int(lobby_state.get("bot_count", 0))
	var local_is_host: bool = int(lobby_state.get("lobby_owner", 0)) == steam_bridge.get_local_steam_id()
	var members: Array = lobby_state.get("members", [])
	bot_difficulty = lobby_bot_difficulty
	match_history_mode = lobby_history_mode
	var network_bot_difficulty_name: String = ["лёгкий", "обычный", "сложный"][lobby_bot_difficulty]

	steam_lobby_status_label.text = lobby_status
	if lobby_id > 0:
		steam_lobby_details_label.text = "Комната: %d\nУчастники: %d из %d\nИстория: %s\nТип: закрытая для друзей · Project Joker · протокол %d" % [
			lobby_id,
			member_count,
			member_limit,
			_get_history_mode_label(lobby_history_mode),
			LoopbackNetwork.PROTOCOL_VERSION
		]
	else:
		steam_lobby_details_label.text = "Steam: %s\nПосле создания появятся ID комнаты и число участников." % ("подключён" if initialized else "ещё не подключён")

	var member_lines: PackedStringArray = []
	for member_variant in members:
		var member: Dictionary = member_variant
		var member_name := str(member.get("name", "Игрок"))
		var member_role := " · хост" if bool(member.get("is_owner", false)) else ""
		var member_ready := "✓ готов" if bool(member.get("ready", false)) else "… ждём"
		member_lines.append("%s%s — %s" % [member_name, member_role, member_ready])
	for bot_index in bot_count:
		member_lines.append("Бот %d — ✓ готов · %s" % [bot_index + 1, network_bot_difficulty_name])
	for empty_index in maxi(0, member_limit - member_count - bot_count):
		member_lines.append("Свободное место %d" % (member_count + bot_count + empty_index + 1))
	steam_lobby_members_label.text = "Участники комнаты\n%s" % "\n".join(member_lines) if not member_lines.is_empty() else ""

	if is_instance_valid(steam_lobby_create_button):
		steam_lobby_create_button.disabled = not initialized or lobby_id > 0
	if is_instance_valid(steam_lobby_invite_button):
		steam_lobby_invite_button.disabled = lobby_id <= 0
	if is_instance_valid(steam_lobby_ready_button):
		steam_lobby_ready_button.disabled = lobby_id <= 0
		steam_lobby_ready_button.text = "Готов ✓ (отменить)" if local_ready else "Отметиться готовым"
	if is_instance_valid(steam_lobby_bot_difficulty_selector):
		steam_lobby_bot_difficulty_selector.selected = lobby_bot_difficulty
		steam_lobby_bot_difficulty_selector.disabled = lobby_id <= 0 or not local_is_host
	if is_instance_valid(steam_lobby_history_mode_selector):
		steam_lobby_history_mode_selector.selected = lobby_history_mode
		steam_lobby_history_mode_selector.disabled = lobby_id <= 0 or not local_is_host or (steam_p2p_match != null and steam_p2p_match.is_running())
	var all_members_ready := member_count > 0
	for member_variant in members:
		if not (member_variant is Dictionary) or not bool(member_variant.get("ready", false)):
			all_members_ready = false
			break
	var seats_are_filled := member_count == member_limit or fill_empty_seats_with_bots
	var can_prepare_p2p: bool = lobby_id > 0 and local_ready and all_members_ready and seats_are_filled and steam_bridge.is_multiplayer_peer_transport_available()
	if is_instance_valid(steam_p2p_prepare_button):
		steam_p2p_prepare_button.disabled = not can_prepare_p2p or (steam_p2p_match != null and steam_p2p_match.is_running())
	if is_instance_valid(steam_p2p_prepare_with_bots_button):
		steam_p2p_prepare_with_bots_button.disabled = lobby_id <= 0 or not local_is_host or (member_count >= member_limit and not fill_empty_seats_with_bots) or (steam_p2p_match != null and steam_p2p_match.is_running())
		steam_p2p_prepare_with_bots_button.text = "Убрать ботов" if fill_empty_seats_with_bots else "Заполнить свободные места ботами"
	if is_instance_valid(steam_p2p_start_round_button):
		_refresh_steam_first_turn_roll_button()
	if is_instance_valid(steam_p2p_open_table_button):
		steam_p2p_open_table_button.disabled = steam_p2p_match == null or not steam_p2p_match.is_running()
	if is_instance_valid(steam_lobby_leave_button):
		steam_lobby_leave_button.disabled = lobby_id <= 0
	_refresh_steam_p2p_status()


func _refresh_steam_p2p_status() -> void:
	if steam_p2p_main_table_presentation and (steam_p2p_match == null or not steam_p2p_match.is_running()):
		steam_p2p_main_table_presentation = false
		steam_p2p_table_presentation = false
	if not is_instance_valid(steam_p2p_status_label):
		if steam_p2p_main_table_presentation:
			_refresh_network_main_table()
		elif steam_p2p_table_presentation and is_instance_valid(network_table_view) and network_table_view.visible:
			_refresh_network_table_view()
		return
	if steam_p2p_match == null or not steam_p2p_match.is_running():
		steam_p2p_status_label.text = "Steam P2P ещё не подключён. После готовности всех четырёх игроков каждый нажимает «Подготовить Steam P2P»."
	else:
		steam_p2p_status_label.text = "Steam P2P: %s" % steam_p2p_match.status_text
	_refresh_steam_reconnect_controls()
	if is_instance_valid(steam_p2p_prepare_button) and steam_p2p_match != null and steam_p2p_match.is_running():
		steam_p2p_prepare_button.disabled = true
	if is_instance_valid(steam_p2p_prepare_with_bots_button) and steam_p2p_match != null and steam_p2p_match.is_running():
		steam_p2p_prepare_with_bots_button.disabled = true
	if is_instance_valid(steam_p2p_start_round_button):
		_refresh_steam_first_turn_roll_button()
	if is_instance_valid(steam_p2p_open_table_button):
		steam_p2p_open_table_button.disabled = steam_p2p_match == null or not steam_p2p_match.is_running()
	if steam_p2p_main_table_presentation:
		_refresh_network_main_table()
	elif steam_p2p_table_presentation and is_instance_valid(network_table_view) and network_table_view.visible:
		_refresh_network_table_view()


func _refresh_steam_first_turn_roll_button() -> void:
	if not is_instance_valid(steam_p2p_start_round_button):
		return
	var host_can_act: bool = steam_p2p_match != null and steam_p2p_match.is_host()
	if steam_p2p_match == null or not steam_p2p_match.is_running():
		steam_p2p_start_round_button.text = "Разыграть первый ход"
		steam_p2p_start_round_button.disabled = true
	elif steam_p2p_match.lobby_round_started:
		steam_p2p_start_round_button.text = "Партия начата"
		steam_p2p_start_round_button.disabled = true
	elif steam_p2p_match.can_start_first_real_round():
		steam_p2p_start_round_button.text = "Начать первую раздачу"
		steam_p2p_start_round_button.disabled = not host_can_act
	elif steam_p2p_match.is_first_turn_roll_active():
		steam_p2p_start_round_button.text = "Розыгрыш первого хода идёт"
		steam_p2p_start_round_button.disabled = true
	else:
		steam_p2p_start_round_button.text = "Разыграть первый ход"
		steam_p2p_start_round_button.disabled = not host_can_act or not steam_p2p_match.can_begin_first_turn_roll()


func _refresh_steam_reconnect_controls() -> void:
	if not is_instance_valid(steam_reconnect_controls):
		return
	_clear_children(steam_reconnect_controls)
	if steam_p2p_match == null or not steam_p2p_match.is_host():
		return
	for player_index_variant in steam_p2p_match.get_reconnecting_player_indices():
		var player_index := int(player_index_variant)
		var label := Label.new()
		label.text = "Место %d: игрок отключился. Можно подождать или временно передать место боту." % (player_index + 1)
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 15)
		label.add_theme_color_override("font_color", Color(1.0, 0.72, 0.32, 1.0))
		steam_reconnect_controls.add_child(label)
		steam_reconnect_controls.add_child(_create_menu_button(
			"Заполнить место %d ботом" % (player_index + 1),
			_on_replace_disconnected_player_with_bot_pressed.bind(player_index),
			true
		))


func _on_replace_disconnected_player_with_bot_pressed(player_index: int) -> void:
	if steam_p2p_match == null:
		return
	steam_p2p_match.replace_reconnecting_player_with_bot(player_index)
	_refresh_steam_p2p_status()


func _on_network_public_table_event_received() -> void:
	# Реакции, подарки и саундпад не меняют ревизию раздачи. Текст статуса у
	# клиента может остаться тем же, хотя событие хоста уже дошло, поэтому
	# обновляем стол по отдельному сигналу, не дожидаясь следующего игрового хода.
	if steam_p2p_main_table_presentation and steam_p2p_match != null and steam_p2p_match.is_running():
		_refresh_network_main_table()
		return
	if steam_p2p_table_presentation and is_instance_valid(network_table_view) and network_table_view.visible:
		_refresh_network_table_view()
		return
	if loopback_network_test != null and loopback_network_test.is_running():
		_refresh_loopback_network_status()


func _on_network_player_snapshot_received() -> void:
	# Личный снимок может менять доступные кнопки, таймер голосования и карты
	# без нового текстового статуса. Это особенно важно для Steam P2P: клиент
	# должен увидеть хостовое обновление сразу, не отправляя встречный ход.
	if steam_p2p_main_table_presentation and steam_p2p_match != null and steam_p2p_match.is_running():
		_refresh_network_main_table()
		return
	if steam_p2p_table_presentation and is_instance_valid(network_table_view) and network_table_view.visible:
		_refresh_network_table_view()
		return
	if loopback_network_test != null and loopback_network_test.is_running():
		_refresh_loopback_network_status()


func _is_loopback_network_client_launch() -> bool:
	return (
		OS.get_cmdline_user_args().has("--local-client")
		or OS.get_cmdline_args().has("--local-client")
		or OS.get_cmdline_user_args().has("--local-party-client")
		or OS.get_cmdline_args().has("--local-party-client")
	)


func _is_loopback_network_party_client_launch() -> bool:
	return OS.get_cmdline_user_args().has("--local-party-client") or OS.get_cmdline_args().has("--local-party-client")


func _get_loopback_client_seat_from_launch() -> int:
	var argument_lists := [OS.get_cmdline_user_args(), OS.get_cmdline_args()]
	for argument_list_variant in argument_lists:
		var argument_list: PackedStringArray = argument_list_variant
		var seat_argument_index := argument_list.find("--local-seat")
		if seat_argument_index >= 0 and seat_argument_index + 1 < argument_list.size():
			return clampi(int(argument_list[seat_argument_index + 1]), 1, 3)
	return 1


func _show_loopback_network_test_menu() -> void:
	loopback_network_is_technical_presentation = true
	_show_loopback_network_lobby()


func _show_network_party_lobby() -> void:
	loopback_network_is_technical_presentation = false
	_show_loopback_network_lobby()


func _show_loopback_network_lobby() -> void:
	is_pause_menu_open = false
	steam_p2p_table_presentation = false
	steam_p2p_main_table_presentation = false
	menu_overlay.visible = true
	_clear_children(menu_content)
	loopback_network_start_round_button = null
	loopback_network_start_joker_round_button = null
	loopback_network_start_response_joker_round_button = null
	loopback_network_private_hand_label = null
	loopback_network_action_controls = null
	if loopback_network_is_technical_presentation:
		_add_menu_title("Локальная сеть", "Проверка четырёх мест через ENet без Steam")
	else:
		_add_menu_title("Сетевая партия", "Комната на четыре места · локальный прототип без Steam")
	_add_menu_spacer(8.0)

	loopback_network_status_label = Label.new()
	loopback_network_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	loopback_network_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	loopback_network_status_label.add_theme_font_size_override("font_size", 16)
	loopback_network_status_label.add_theme_color_override("font_color", Color(0.72, 0.85, 0.76, 1.0))
	menu_content.add_child(loopback_network_status_label)
	_refresh_loopback_network_status()
	if loopback_network_test.is_client() or loopback_network_test.is_host():
		loopback_network_private_hand_label = Label.new()
		loopback_network_private_hand_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		loopback_network_private_hand_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		loopback_network_private_hand_label.add_theme_font_size_override("font_size", 18)
		loopback_network_private_hand_label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.38, 1.0))
		loopback_network_private_hand_label.visible = loopback_network_test.is_client()
		menu_content.add_child(loopback_network_private_hand_label)
		loopback_network_action_controls = VBoxContainer.new()
		loopback_network_action_controls.add_theme_constant_override("separation", 8)
		menu_content.add_child(loopback_network_action_controls)
		_refresh_loopback_network_status()
	_add_menu_spacer(10.0)

	if not loopback_network_test.is_running():
		_add_menu_button("Запустить хост" if loopback_network_is_technical_presentation else "Создать комнату", _on_start_loopback_network_host_pressed, true)
		_add_menu_button("Подключиться как место 2" if loopback_network_is_technical_presentation else "Подключиться к комнате", _on_start_loopback_network_client_pressed)
	else:
		if loopback_network_test.is_host():
			_add_menu_button("Открыть три окна клиентов" if loopback_network_is_technical_presentation else "Открыть три окна участников", _on_open_loopback_network_clients_pressed, true)
			if loopback_network_is_technical_presentation:
				_add_menu_label("Вручную: ProjectJokerDebug.exe -- --local-client --local-seat 1", 14, Color(0.72, 0.85, 0.76, 1.0))
			else:
				_add_menu_label("Пока это локальная проверка на одном ПК. Steam-приглашения заменят этот шаг позднее.", 14, Color(0.72, 0.85, 0.76, 1.0))
			loopback_network_start_round_button = _add_menu_button("Начать тестовую раздачу" if loopback_network_is_technical_presentation else "Начать партию", _on_start_loopback_test_round_pressed, true)
			loopback_network_start_round_button.disabled = not loopback_network_test.can_start_test_round()
			if loopback_network_is_technical_presentation:
				loopback_network_start_joker_round_button = _add_menu_button("Начать раздачу с Джокером", _on_start_loopback_test_joker_round_pressed)
				loopback_network_start_joker_round_button.disabled = not loopback_network_test.can_start_test_round()
				loopback_network_start_response_joker_round_button = _add_menu_button("Начать раздачу с Джокером в ответ", _on_start_loopback_test_response_joker_round_pressed)
				loopback_network_start_response_joker_round_button.disabled = not loopback_network_test.can_start_test_round()
		else:
			_add_menu_label("Это клиентское место тестового лобби. После старта оно получит только свою руку." if loopback_network_is_technical_presentation else "Ты подключён к комнате. После старта партии увидишь только свою руку.", 14, Color(0.72, 0.85, 0.76, 1.0))
		_add_menu_button("Открыть сетевой стол" if loopback_network_is_technical_presentation else "Открыть стол", _on_open_network_table_pressed, true)
		_add_menu_button("Остановить тест" if loopback_network_is_technical_presentation else "Закрыть комнату", _on_stop_loopback_network_pressed)

	_add_menu_spacer(10.0)
	_add_menu_button("Назад", _on_close_loopback_network_test_pressed)


func _on_start_loopback_network_host_pressed() -> void:
	_reset_loopback_network_joker_selection()
	loopback_network_test.start_host()
	_show_loopback_network_lobby()


func _on_start_loopback_network_client_pressed() -> void:
	_reset_loopback_network_joker_selection()
	loopback_network_test.start_client(1)
	_show_loopback_network_lobby()


func _start_loopback_network_client_from_launch() -> void:
	_reset_loopback_network_joker_selection()
	loopback_network_test.start_client(_get_loopback_client_seat_from_launch())
	_show_loopback_network_lobby()


func _on_open_loopback_network_clients_pressed() -> void:
	if OS.has_feature("editor"):
		loopback_network_test.status_text = "В редакторе открой три клиентских окна вручную через экспортированный .exe."
		_refresh_loopback_network_status()
		return

	var opened_window_count := 0
	var launch_mode := "--local-client" if loopback_network_is_technical_presentation else "--local-party-client"
	for player_index in range(1, 4):
		var process_id := OS.create_process(
			OS.get_executable_path(),
			PackedStringArray(["--", launch_mode, "--local-seat", str(player_index)])
		)
		if process_id > 0:
			opened_window_count += 1
	loopback_network_test.status_text = "Открывается клиентских окон: %d из 3." % opened_window_count
	_refresh_loopback_network_status()


func _on_stop_loopback_network_pressed() -> void:
	_reset_loopback_network_joker_selection()
	if is_instance_valid(network_table_view):
		network_table_view.visible = false
	loopback_network_test.stop()
	_show_loopback_network_lobby()


func _on_start_loopback_test_round_pressed() -> void:
	_reset_loopback_network_joker_selection()
	loopback_network_test.start_test_round()
	_refresh_loopback_network_status()
	if not loopback_network_is_technical_presentation:
		_on_open_network_table_pressed()


func _on_start_loopback_test_joker_round_pressed() -> void:
	_reset_loopback_network_joker_selection()
	loopback_network_test.start_test_round(true)
	_refresh_loopback_network_status()


func _on_start_loopback_test_response_joker_round_pressed() -> void:
	_reset_loopback_network_joker_selection()
	loopback_network_test.start_test_round_with_response_joker()
	_refresh_loopback_network_status()


func _on_submit_loopback_test_bid_pressed(bid: int) -> void:
	var network_match = _get_active_network_match()
	if network_match == null:
		return
	if network_match.is_host():
		network_match.submit_host_test_bid(bid)
	else:
		network_match.submit_test_bid(bid)
	_refresh_loopback_network_status()
	_refresh_steam_p2p_status()


func _on_submit_loopback_test_card_pressed(card_key: String) -> void:
	var network_match = _get_active_network_match()
	if network_match == null:
		return
	if network_match.is_host():
		network_match.submit_host_test_card(card_key)
	else:
		network_match.submit_test_card(card_key)
	_refresh_loopback_network_status()
	_refresh_steam_p2p_status()


func _submit_network_social_action(payload: Dictionary) -> bool:
	var network_match = _get_active_network_match()
	if network_match == null or not network_match.has_method(&"submit_social_action"):
		return false
	var was_submitted := bool(network_match.call(&"submit_social_action", payload))
	if not was_submitted:
		_refresh_social_action_buttons()
	_refresh_loopback_network_status()
	_refresh_steam_p2p_status()
	return was_submitted


func _on_open_loopback_test_joker_selection_pressed() -> void:
	if not _can_submit_loopback_test_joker():
		return
	loopback_network_joker_selection_open = true
	loopback_network_pending_joker_suit = -1
	_refresh_loopback_network_status()
	_refresh_steam_p2p_status()


func _on_choose_loopback_test_joker_suit_pressed(suit: int) -> void:
	if not _is_loopback_test_joker_leading():
		_reset_loopback_network_joker_selection()
		_refresh_loopback_network_status()
		return
	loopback_network_pending_joker_suit = suit
	_refresh_loopback_network_status()
	_refresh_steam_p2p_status()


func _on_submit_loopback_test_joker_pressed(mode: Trick.JokerMode, declared_suit: int = -1, forced_card_rank: Trick.ForcedCardRank = Trick.ForcedCardRank.NONE) -> void:
	var was_submitted := false
	var network_match = _get_active_network_match()
	if network_match == null:
		return
	if network_match.is_host():
		was_submitted = network_match.submit_host_test_joker_choice(mode, declared_suit, forced_card_rank)
	else:
		was_submitted = network_match.submit_test_joker_choice(mode, declared_suit, forced_card_rank)
	if was_submitted:
		_reset_loopback_network_joker_selection()
	_refresh_loopback_network_status()
	_refresh_steam_p2p_status()


func _on_cancel_loopback_test_joker_selection_pressed() -> void:
	_reset_loopback_network_joker_selection()
	_refresh_loopback_network_status()
	_refresh_steam_p2p_status()


func _get_active_network_match():
	if steam_p2p_table_presentation and steam_p2p_match != null and steam_p2p_match.is_running():
		return steam_p2p_match
	return loopback_network_test


func _is_steam_p2p_table_active() -> bool:
	return steam_p2p_table_presentation and steam_p2p_match != null and steam_p2p_match.is_running()


func _is_steam_p2p_main_table_active() -> bool:
	return steam_p2p_main_table_presentation and _is_steam_p2p_table_active()


func _get_network_main_snapshot() -> Dictionary:
	var network_match = _get_active_network_match()
	if network_match == null:
		return {}
	return network_match.get_test_table_snapshot()


func _sync_network_auto_turn_setting(snapshot: Dictionary) -> void:
	if not snapshot.has("recipient_auto_turn_enabled"):
		return
	var host_enabled := bool(snapshot.get("recipient_auto_turn_enabled", false))
	if host_enabled == auto_turn_enabled:
		return
	auto_turn_enabled = host_enabled
	_save_persistent_settings()
	_reset_turn_reminder()


func _refresh_network_main_table() -> void:
	if not _is_steam_p2p_main_table_active():
		return
	if is_pause_menu_open and is_instance_valid(menu_overlay) and menu_overlay.visible:
		return

	if is_instance_valid(network_table_view):
		network_table_view.visible = false
	if is_instance_valid(menu_overlay):
		menu_overlay.visible = false

	first_turn_roll_panel.visible = false
	var network_match = _get_active_network_match()
	if network_match != null and network_match.is_first_turn_roll_active():
		_refresh_network_main_waiting_state()
		_refresh_first_turn_roll_panel(network_match.get_first_turn_roll_state(), network_match.lobby_seats)
		return

	var snapshot: Dictionary = _get_network_main_snapshot()
	if snapshot.is_empty():
		_refresh_network_main_waiting_state()
		return
	match_history_mode = clampi(
		int(snapshot.get("history_mode", match_history_mode)),
		NetworkHost.HistoryMode.FULL,
		NetworkHost.HistoryMode.LAST_TRICK_ONLY
	)
	_sync_network_auto_turn_setting(snapshot)
	var table_state_reset_id := int(snapshot.get("table_state_reset_id", 0))
	if table_state_reset_id != network_table_state_reset_id:
		network_table_state_reset_id = table_state_reset_id
		_reset_network_table_after_undo_restore()

	var round_data: Dictionary = snapshot.get("round", {})
	var active_trick: Dictionary = snapshot.get("active_trick", {})
	var viewer_index: int = int(snapshot.get("recipient_player_index", 0))
	var active_player_index: int = _get_network_table_active_player_index(round_data, active_trick)
	var round_finished := int(round_data.get("state", Round.State.SETUP)) == Round.State.FINISHED
	var round_number := int(round_data.get("number", 0))
	if round_number != network_visual_round_number:
		network_visual_round_number = round_number
		network_collected_trick_key = ""
	var result_key := _get_network_round_result_key(snapshot, round_data)
	var completed_trick_key := _get_network_completed_trick_key(round_data, active_trick)
	var hide_completed_trick := (
		(round_finished and network_round_result_key == result_key)
		or (not completed_trick_key.is_empty() and completed_trick_key == network_collected_trick_key)
	)

	_refresh_network_main_header(snapshot, round_data, active_player_index)
	_refresh_network_main_deck(snapshot, round_data)
	_refresh_network_main_players(snapshot, viewer_index, active_player_index)
	_refresh_network_main_trick(snapshot, viewer_index, active_trick, hide_completed_trick)
	_refresh_network_main_history(snapshot, round_data, active_trick, active_player_index)
	_refresh_network_main_action_controls(snapshot, round_data)
	_refresh_network_main_hand(snapshot, round_data)
	_refresh_network_main_results(snapshot, round_data)
	_refresh_network_main_markers(snapshot, round_data, viewer_index)
	_refresh_network_main_score_sheet(snapshot, round_data)
	_refresh_network_main_common_controls(snapshot)
	_process_network_public_table_events(snapshot, viewer_index)


func _refresh_network_main_waiting_state() -> void:
	phase_label.text = "Этап: подключение к сетевому столу"
	trump_label.text = "Козырь будет открыт после запуска раздачи"
	action_label.visible = true
	action_label.text = "Ожидаем безопасный снимок стола от хоста."
	table_label.text = "Сетевой стол ожидает начала раздачи"
	history_label.text = "Сетевая история\nОжидание публичного состояния от хоста."
	round_results_panel.visible = false
	deck_visual.visible = false
	_clear_children(hand_container)
	_clear_children(bid_controls)
	_clear_children(joker_controls)
	joker_controls.visible = false
	next_round_button.visible = false
	undo_button.disabled = true
	_refresh_network_main_common_controls()


func _refresh_network_main_header(snapshot: Dictionary, round_data: Dictionary, active_player_index: int) -> void:
	var state: int = int(round_data.get("state", Round.State.SETUP))
	var round_type: int = int(round_data.get("round_type", Round.RoundType.NORMAL))
	var phase_text := "подготовка"
	match state:
		Round.State.BIDDING:
			phase_text = "заказ взяток"
		Round.State.PLAYING:
			phase_text = "розыгрыш взяток"
		Round.State.FINISHED:
			phase_text = "завершена"
	phase_label.text = "Раздача %d · %s · %s" % [
		int(round_data.get("number", 0)),
		_get_round_type_display_name(round_type),
		phase_text
	]

	var trump_card: Card = _create_network_table_card(snapshot.get("trump_card", {}))
	if round_type == Round.RoundType.MISERE:
		trump_label.text = _get_network_scheduled_trump_text("Мизерная", round_data)
	elif round_type == Round.RoundType.GOLDEN:
		trump_label.text = _get_network_scheduled_trump_text("Золотая", round_data)
	elif trump_card == null:
		var scheduled_trump := int(round_data.get("trump", Round.TrumpSuit.RANDOM))
		trump_label.text = (
			"Козырь: не определён"
			if scheduled_trump == Round.TrumpSuit.RANDOM
			else "Козырь: %s (по расписанию)" % _get_trump_name_from_suit(scheduled_trump)
		)
	elif trump_card.is_joker:
		trump_label.text = "Открыт Джокер · бескозырка"
	else:
		trump_label.text = "Открыта %s · козырь %s" % [trump_card.get_card_name(), _get_suit_symbol(trump_card.suit)]
	trump_label.text = _format_suit_symbols_for_dark_ui(trump_label.text)

	var players_by_index: Dictionary = _get_network_players_by_index(snapshot)
	var action_text_network := "Ожидание действий хоста"
	var undo_state: Dictionary = snapshot.get("undo_state", {})
	if bool(undo_state.get("pending", false)):
		var requester_index := int(undo_state.get("requester_player_index", -1))
		var requester_name := "Игрок"
		if players_by_index.has(requester_index):
			requester_name = str((players_by_index[requester_index] as Dictionary).get("display_name", requester_name))
		action_text_network = "%s просит вернуть ход · осталось %d с." % [requester_name, int(undo_state.get("seconds_left", 0))]
	var reconnecting_player_name := _get_network_reconnecting_player_name(snapshot, players_by_index)
	if not reconnecting_player_name.is_empty():
		action_text_network = "%s переподключается. Партия ожидает возвращения игрока." % reconnecting_player_name
	elif not bool(undo_state.get("pending", false)) and state == Round.State.BIDDING:
		if active_player_index == int(snapshot.get("recipient_player_index", -1)):
			action_text_network = "Твой заказ: выбери число взяток."
		elif players_by_index.has(active_player_index):
			action_text_network = "Заказывает %s" % str((players_by_index[active_player_index] as Dictionary).get("display_name", "игрок"))
	elif not bool(undo_state.get("pending", false)) and state == Round.State.PLAYING:
		if loopback_network_joker_selection_open:
			action_text_network = "Выбери условие для Джокера."
		elif active_player_index == int(snapshot.get("recipient_player_index", -1)):
			action_text_network = "Твой ход: выбери подсвеченную карту в руке."
		elif players_by_index.has(active_player_index):
			action_text_network = "Ходит %s" % str((players_by_index[active_player_index] as Dictionary).get("display_name", "игрок"))
	elif not bool(undo_state.get("pending", false)) and state == Round.State.FINISHED:
		action_text_network = "Раздача завершена. Итоги — в центре стола."
	action_label.visible = true
	action_label.text = action_text_network


func _get_network_players_by_index(snapshot: Dictionary) -> Dictionary:
	var players_by_index: Dictionary = {}
	for player_data_variant in snapshot.get("players", []):
		if player_data_variant is Dictionary:
			var player_data: Dictionary = player_data_variant
			players_by_index[int(player_data.get("player_index", -1))] = player_data
	return players_by_index


func _is_network_player_reconnecting(snapshot: Dictionary, player_index: int) -> bool:
	var reconnecting_data: Variant = snapshot.get("reconnecting_player_indices", [])
	if not (reconnecting_data is Array):
		return false
	for reconnecting_player_index in reconnecting_data:
		if int(reconnecting_player_index) == player_index:
			return true
	return false


func _is_network_player_temporary_bot(snapshot: Dictionary, player_index: int) -> bool:
	var temporary_bot_data: Variant = snapshot.get("temporary_bot_player_indices", [])
	if not (temporary_bot_data is Array):
		return false
	for temporary_bot_player_index in temporary_bot_data:
		if int(temporary_bot_player_index) == player_index:
			return true
	return false


func _get_network_reconnecting_player_name(snapshot: Dictionary, players_by_index: Dictionary) -> String:
	var reconnecting_data: Variant = snapshot.get("reconnecting_player_indices", [])
	if not (reconnecting_data is Array) or reconnecting_data.is_empty():
		return ""
	var player_index := int(reconnecting_data[0])
	if players_by_index.has(player_index):
		return str((players_by_index[player_index] as Dictionary).get("display_name", "Игрок %d" % (player_index + 1)))
	return "Игрок %d" % (player_index + 1)


func _refresh_network_main_common_controls(snapshot: Dictionary = {}) -> void:
	_refresh_music_player()
	hand_sort_by_suit_button.disabled = hand_sort_mode == HandSortMode.BY_SUIT
	hand_sort_trumps_left_button.disabled = hand_sort_mode == HandSortMode.TRUMPS_LEFT
	var network_match = _get_active_network_match()
	var can_request_undo: bool = network_match != null and network_match.has_method(&"can_request_undo") and bool(network_match.call(&"can_request_undo"))
	var undo_state: Dictionary = snapshot.get("undo_state", {})
	undo_button.disabled = not can_request_undo
	if bool(undo_state.get("pending", false)):
		undo_button.tooltip_text = "Сейчас идёт голосование за возврат хода."
	elif can_request_undo:
		undo_button.tooltip_text = "Запросить у всех игроков возврат своего последнего решения."
	else:
		undo_button.tooltip_text = "Возврат доступен только для своего последнего решения и не более двух запросов."
	_refresh_turn_timer_indicator()
	_refresh_reaction_controls()
	_refresh_sticker_controls()
	_refresh_soundpad_controls()
	_refresh_chat_controls()


func _refresh_network_main_deck(snapshot: Dictionary, round_data: Dictionary) -> void:
	var state: int = int(round_data.get("state", Round.State.SETUP))
	deck_visual.visible = state != Round.State.SETUP
	if not deck_visual.visible:
		return

	var trump_card: Card = _create_network_table_card(snapshot.get("trump_card", {}))
	var cards_left: int = int(snapshot.get("cards_left_in_deck", 0))
	var has_open_trump := trump_card != null
	for card_index in deck_back_panels.size():
		deck_back_panels[card_index].visible = has_open_trump and card_index < mini(3, cards_left)

	if has_open_trump:
		var trump_texture: Texture2D = CardArtworkResource.get_face_texture(trump_card)
		deck_trump_artwork.texture = trump_texture
		deck_trump_artwork.visible = trump_texture != null
		deck_trump_label.visible = trump_texture == null
		deck_trump_label.text = trump_card.get_card_name()
		deck_trump_label.add_theme_font_size_override("font_size", 17)
		deck_trump_label.add_theme_color_override(
			"font_color",
			Color(0.74, 0.08, 0.06, 1.0) if trump_card.suit == Card.Suit.HEARTS or trump_card.suit == Card.Suit.DIAMONDS else Color(0.08, 0.08, 0.07, 1.0)
		)
		deck_trump_panel.tooltip_text = "Открытая карта и остаток колоды — публичная информация сетевой раздачи."
		deck_caption_label.text = "Открытый Джокер · бескозырка" if trump_card.is_joker else "Открытый козырь · в колоде: %d" % cards_left
		return

	deck_trump_artwork.texture = null
	deck_trump_artwork.visible = false
	deck_trump_label.visible = true
	var scheduled_trump := int(round_data.get("trump", Round.TrumpSuit.RANDOM))
	var scheduled_trump_texture: Texture2D = CardArtworkResource.get_scheduled_trump_texture(scheduled_trump)
	deck_trump_artwork.texture = scheduled_trump_texture
	deck_trump_artwork.visible = scheduled_trump_texture != null
	deck_trump_label.visible = scheduled_trump_texture == null
	deck_trump_label.text = (
		"—"
		if scheduled_trump == Round.TrumpSuit.NONE or scheduled_trump == Round.TrumpSuit.RANDOM
		else _get_trump_name_from_suit(scheduled_trump)
	)
	deck_trump_label.add_theme_font_size_override("font_size", 32)
	deck_trump_label.add_theme_color_override("font_color", Color(0.08, 0.08, 0.07, 1.0))
	if scheduled_trump == Round.TrumpSuit.RANDOM:
		deck_trump_panel.tooltip_text = "Козырь определится открытой картой после раздачи."
		deck_caption_label.text = "Козырь ещё не открыт"
	elif scheduled_trump == Round.TrumpSuit.NONE:
		deck_trump_panel.tooltip_text = "В этой раздаче козырей нет."
		deck_caption_label.text = "Без козыря"
	else:
		deck_trump_panel.tooltip_text = "Козырь задан расписанием раздач."
		deck_caption_label.text = "Козырь по расписанию: %s" % _get_trump_name_from_suit(scheduled_trump)


func _refresh_network_main_players(snapshot: Dictionary, viewer_index: int, active_player_index: int) -> void:
	var players_by_index: Dictionary = _get_network_players_by_index(snapshot)
	var network_round_data: Dictionary = snapshot.get("round", {})
	var uses_bids := _round_type_uses_bids(int(network_round_data.get("round_type", Round.RoundType.NORMAL)))
	var round_finished := int(network_round_data.get("state", Round.State.SETUP)) == Round.State.FINISHED
	var result_is_presented := (
		round_finished
		and network_round_result_key == _get_network_round_result_key(snapshot, network_round_data)
	)
	for player_index in range(PLAYER_NAMES.size()):
		var relative_slot: int = posmod(player_index - viewer_index, PLAYER_NAMES.size())
		var player_data: Dictionary = players_by_index.get(player_index, {})
		var panel: PanelContainer = player_panels[relative_slot]
		_place_player_panel(panel, relative_slot)
		var is_current := player_index == active_player_index
		panel.add_theme_stylebox_override("panel", active_human_player_panel_style if is_current and relative_slot == HUMAN_PLAYER_INDEX else active_player_panel_style if is_current else human_player_panel_style if relative_slot == HUMAN_PLAYER_INDEX else player_panel_style)

		var is_reconnecting := _is_network_player_reconnecting(snapshot, player_index)
		var is_temporary_bot := _is_network_player_temporary_bot(snapshot, player_index)
		var player_name := str(player_data.get("display_name", "Игрок %d" % (player_index + 1)))
		player_labels[relative_slot].text = (
			("Переподключается · " if is_reconnecting else "Временный бот · " if is_temporary_bot else "Ход · " if is_current else "")
			+ player_name
		)
		var bid_value: int = int(player_data.get("bid", -1))
		var bid_text := "—" if bid_value < 0 else str(bid_value)
		player_stats_labels[relative_slot].text = (
			"[center][color=#ffb34f][b]Переподключается…[/b][/color][/center]"
			if is_reconnecting
			else "[center][color=#ffd45c][b]Бот играет до возвращения игрока[/b][/color][/center]"
			if is_temporary_bot
			else _get_player_stats_bbcode(bid_text, int(player_data.get("tricks_taken", 0)), uses_bids)
		)
		var total_score: int = int(player_data.get("total_score", 0))
		if round_finished and not result_is_presented:
			_hold_player_score_until_round_result(relative_slot, total_score)
		else:
			_set_player_score_display(relative_slot, total_score, result_is_presented)

		var avatar_badge: PanelContainer = avatar_badges[relative_slot]
		_place_player_avatar_badge(avatar_badge, relative_slot)
		avatar_badge.tooltip_text = "Игрок: %s" % str(player_data.get("display_name", "Игрок"))
		_set_avatar_turn_active(relative_slot, is_current)
		var avatar_texture: Texture2D = _get_network_player_avatar_texture(player_index)
		avatar_images[relative_slot].texture = avatar_texture
		avatar_labels[relative_slot].visible = avatar_texture == null
		avatar_labels[relative_slot].text = _get_network_player_avatar_symbol(player_index)

	_refresh_avatar_mute_buttons(snapshot, viewer_index)
	_refresh_network_main_undo_vote_badges(snapshot, viewer_index)

	_refresh_network_main_card_backs(players_by_index, viewer_index)


func _refresh_network_main_card_backs(players_by_index: Dictionary, viewer_index: int) -> void:
	for holder in bot_card_back_holders:
		holder.visible = false

	for player_index in range(PLAYER_NAMES.size()):
		if player_index == viewer_index:
			continue
		var relative_slot: int = posmod(player_index - viewer_index, PLAYER_NAMES.size())
		if relative_slot <= 0 or relative_slot > bot_card_back_holders.size():
			continue
		var holder: Control = bot_card_back_holders[relative_slot - 1]
		var player_data: Dictionary = players_by_index.get(player_index, {})
		var visible_card_count: int = mini(3, int(player_data.get("cards_in_hand", 0)))
		_place_bot_card_back_holder(holder, relative_slot)
		holder.visible = visible_card_count > 0
		for card_index in holder.get_child_count():
			var card_back: Control = holder.get_child(card_index) as Control
			if card_back != null:
				card_back.visible = card_index < visible_card_count


func _refresh_network_main_trick(snapshot: Dictionary, viewer_index: int, active_trick: Dictionary, hide_completed_trick := false) -> void:
	if network_round_finish_presentation_active or network_card_play_presentation_active:
		return

	for card_view in trick_card_views:
		card_view.visible = false
		card_view.set_winner_highlight(false)

	var trick_data: Dictionary = active_trick
	var is_active := not trick_data.is_empty() and not (trick_data.get("played_cards", []) as Array).is_empty()
	if not is_active:
		if hide_completed_trick:
			table_label.text = "Следующая взятка"
			return
		trick_data = snapshot.get("last_completed_trick", {})
	var played_cards: Array = trick_data.get("played_cards", trick_data.get("cards", []))
	var played_by: Array = trick_data.get("played_by", [])
	if played_cards.is_empty():
		table_label.text = "Следующая взятка"
		return

	table_label.text = "Текущая взятка" if is_active else "Последняя взятка"
	var declaration_text := _get_network_table_joker_text(trick_data)
	if not declaration_text.is_empty():
		table_label.text += "\n%s" % declaration_text
	var winner_index: int = -1 if is_active else int(snapshot.get("last_trick_winner_index", -1))
	for card_index in played_cards.size():
		if card_index >= played_by.size() or not (played_cards[card_index] is Dictionary):
			continue
		var player_index: int = int(played_by[card_index])
		var relative_slot: int = posmod(player_index - viewer_index, PLAYER_NAMES.size())
		var card_data: Dictionary = played_cards[card_index]
		var card: Card = _create_network_table_card(card_data)
		if card == null:
			continue
		var card_view: CardView = trick_card_views[relative_slot]
		_place_trick_slot(card_view, relative_slot)
		card_view.set_card(card)
		card_view.set_status(_get_network_main_trick_card_status(card, card_index, trick_data))
		card_view.set_winner_highlight(player_index == winner_index)
		card_view.visible = true


func _get_network_completed_trick_key(round_data: Dictionary, active_trick: Dictionary) -> String:
	if not active_trick.is_empty():
		return ""
	var tricks_played := int(round_data.get("tricks_played", 0))
	if tricks_played <= 0:
		return ""
	return "%d:%d" % [int(round_data.get("number", 0)), tricks_played]


func _process_network_public_table_events(snapshot: Dictionary, viewer_index: int) -> void:
	var network_match = _get_active_network_match()
	if network_match == null:
		return
	var stream_key := "%d:%d" % [network_match.get_instance_id(), viewer_index]
	var events: Array = snapshot.get("public_table_events", [])
	if stream_key != network_public_event_stream_key:
		network_public_event_stream_key = stream_key
		network_last_public_event_id = _get_latest_network_public_event_id(events)
		_rebuild_network_chat_messages(events, snapshot)
		network_card_event_queue.clear()
		network_card_play_presentation_active = false
		network_visual_round_number = -1
		network_collected_trick_key = ""
		social_action_uses[SocialAction.REACTION] = 0
		social_action_uses[SocialAction.STICKER] = 0
		social_action_uses[SocialAction.SOUNDPAD] = 0
		social_action_cooldown_until[SocialAction.REACTION] = 0
		social_action_cooldown_until[SocialAction.STICKER] = 0
		social_action_cooldown_until[SocialAction.SOUNDPAD] = 0
		return

	for event_variant in events:
		if not (event_variant is Dictionary):
			continue
		var event: Dictionary = event_variant
		var event_id := int(event.get("event_id", -1))
		if event_id <= network_last_public_event_id:
			continue
		network_last_public_event_id = event_id
		_present_network_public_table_event(event, viewer_index)


func _get_latest_network_public_event_id(events: Array) -> int:
	var latest_event_id := -1
	for event_variant in events:
		if event_variant is Dictionary:
			latest_event_id = maxi(latest_event_id, int((event_variant as Dictionary).get("event_id", -1)))
	return latest_event_id


func _present_network_public_table_event(event: Dictionary, viewer_index: int) -> void:
	match str(event.get("kind", "")):
		"played_card":
			network_card_event_queue.append(event.duplicate(true))
			if not network_card_play_presentation_active:
				network_card_play_presentation_active = true
				call_deferred("_present_next_network_card_event", viewer_index)
		"reaction":
			_present_network_reaction_event(event, viewer_index)
		"sticker":
			_present_network_sticker_event(event, viewer_index)
		"soundpad":
			_present_network_soundpad_event(event, viewer_index)
		"chat":
			_present_network_chat_event(event, viewer_index)


func _present_next_network_card_event(viewer_index: int) -> void:
	if network_card_event_queue.is_empty():
		network_card_play_presentation_active = false
		return
	var event: Dictionary = network_card_event_queue.pop_front()
	var trick_completed := bool(event.get("trick_completed", false))
	var round_completed := bool(event.get("round_completed", false))
	var actor_player_index := int(event.get("actor_player_index", -1))
	var relative_slot := posmod(actor_player_index - viewer_index, PLAYER_NAMES.size())
	if relative_slot >= 0 and relative_slot < trick_card_views.size():
		var card_view: CardView = trick_card_views[relative_slot]
		var played_card: Card = _create_network_table_card(event.get("card", {}))
		if played_card != null:
			_place_trick_slot(card_view, relative_slot)
			card_view.set_card(played_card)
			card_view.set_status("")
			card_view.set_winner_highlight(false)
			card_view.visible = true
			await get_tree().process_frame
			var target_position := card_view.global_position
			var target_rotation := card_view.rotation
			card_view.pivot_offset = card_view.size * 0.5
			card_view.global_position = _get_played_card_source_global_position(relative_slot, card_view.size)
			card_view.rotation = target_rotation + deg_to_rad(_get_card_flight_start_angle(relative_slot))
			card_view.scale = Vector2(0.78, 0.78)
			card_view.modulate = Color(1.0, 1.0, 1.0, 0.86)
			var tween := create_tween()
			tween.set_parallel(true)
			tween.tween_property(card_view, "global_position", target_position, CARD_FLY_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tween.tween_property(card_view, "rotation", target_rotation, CARD_FLY_DURATION).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tween.tween_property(card_view, "scale", Vector2.ONE, CARD_FLY_DURATION).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tween.tween_property(card_view, "modulate", Color.WHITE, CARD_FLY_DURATION)
			await tween.finished
	if trick_completed and not round_completed:
		await _present_network_completed_trick(
			int(event.get("trick_winner_player_index", -1)),
			viewer_index,
			"%d:%d" % [int(event.get("round_number", 0)), int(event.get("tricks_played", 0))]
		)
	if not network_card_event_queue.is_empty():
		call_deferred("_present_next_network_card_event", viewer_index)
	else:
		network_card_play_presentation_active = false
		_refresh_network_main_table()


func _present_network_completed_trick(winner_player_index: int, viewer_index: int, completed_trick_key: String) -> void:
	var relative_winner_index := posmod(winner_player_index - viewer_index, PLAYER_NAMES.size())
	if winner_player_index < 0 or relative_winner_index < 0 or relative_winner_index >= trick_card_views.size():
		return

	_play_sound(SoundEffect.TRICK)
	_set_trick_winner_highlight(relative_winner_index, true)
	var snapshot := _get_network_main_snapshot()
	var players_by_index := _get_network_players_by_index(snapshot)
	var winner_data: Dictionary = players_by_index.get(winner_player_index, {})
	action_label.text = "Взятку забирает %s." % str(winner_data.get("display_name", "игрок"))
	if _did_network_joker_win_last_trick(snapshot, winner_player_index):
		_show_joker_celebration(relative_winner_index)
	await get_tree().create_timer(TRICK_WINNER_HOLD_DURATION).timeout
	_set_trick_winner_highlight(relative_winner_index, false)
	await _animate_network_trick_collection(relative_winner_index)
	network_collected_trick_key = completed_trick_key


func _present_network_reaction_event(event: Dictionary, viewer_index: int) -> void:
	if not is_instance_valid(reaction_bubble):
		return
	var actor_player_index := int(event.get("actor_player_index", -1))
	if _is_network_player_sound_muted(actor_player_index):
		return
	var relative_slot := posmod(actor_player_index - viewer_index, PLAYER_NAMES.size())
	if relative_slot < 0 or relative_slot >= avatar_badges.size():
		return
	_show_reaction_bubble(str(event.get("reaction", "")), relative_slot)


func _present_network_sticker_event(event: Dictionary, viewer_index: int) -> void:
	var actor_player_index := int(event.get("actor_player_index", -1))
	if _is_network_player_sound_muted(actor_player_index):
		return
	var source_relative := posmod(actor_player_index - viewer_index, PLAYER_NAMES.size())
	var target_relative := posmod(int(event.get("target_player_index", -1)) - viewer_index, PLAYER_NAMES.size())
	if source_relative < 0 or source_relative >= avatar_badges.size() or target_relative < 0 or target_relative >= avatar_badges.size():
		return
	var sticker_symbol := str(event.get("sticker", ""))
	_show_sticker_flyer(_get_builtin_sticker_by_symbol(sticker_symbol), source_relative, target_relative)


func _present_network_soundpad_event(event: Dictionary, viewer_index: int) -> void:
	var actor_player_index := int(event.get("actor_player_index", -1))
	var sound_id := str(event.get("sound_id", ""))
	if _is_network_player_sound_muted(actor_player_index):
		return
	for sound_data in soundpad_sounds:
		if str(sound_data.get("path", "")) == sound_id:
			var sound_stream: AudioStream = sound_data.get("stream", null) as AudioStream
			if sound_stream != null:
				_play_soundpad_stream(sound_stream)
			break
	if not is_instance_valid(soundpad_bubble):
		return
	var relative_slot := posmod(actor_player_index - viewer_index, PLAYER_NAMES.size())
	if relative_slot < 0 or relative_slot >= avatar_badges.size():
		return
	var badge_rect := avatar_badges[relative_slot].get_global_rect()
	soundpad_bubble.global_position = badge_rect.get_center() - soundpad_bubble.size * 0.5 + Vector2(42.0, -42.0)
	_show_soundpad_bubble()


func _present_network_chat_event(event: Dictionary, viewer_index: int) -> void:
	var players_by_index := _get_network_players_by_index(_get_network_main_snapshot())
	var actor_player_index := int(event.get("actor_player_index", -1))
	var player_name := "Игрок %d" % (actor_player_index + 1)
	if players_by_index.has(actor_player_index):
		player_name = str((players_by_index[actor_player_index] as Dictionary).get("display_name", player_name))
	_append_network_chat_message(event, player_name)
	if not is_instance_valid(chat_panel) or not chat_panel.visible:
		if actor_player_index != viewer_index:
			chat_unread_count += 1
	_refresh_chat_controls()


func _is_network_player_sound_muted(player_index: int) -> bool:
	return muted_network_player_indices.has(player_index)


func _get_network_main_trick_card_status(card: Card, card_index: int, trick_data: Dictionary) -> String:
	if not card.is_joker:
		return ""
	var is_leading_joker := card_index == 0
	var joker_mode: int = int(trick_data.get("joker_mode", Trick.JokerMode.NORMAL_CARD_WINS))
	if not is_leading_joker:
		return "ЗАБИРАЕТ" if joker_mode == Trick.JokerMode.JOKER_WINS else "НЕ БЕРЁТ"

	var declared_suit: int = int(trick_data.get("declared_suit", -1))
	var forced_card_rank: int = int(trick_data.get("forced_card_rank", Trick.ForcedCardRank.NONE))
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


func _refresh_network_main_history(snapshot: Dictionary, round_data: Dictionary, active_trick: Dictionary, active_player_index: int) -> void:
	var history_mode := int(snapshot.get("history_mode", NetworkHost.HistoryMode.FULL))
	var history_lines: PackedStringArray = []
	if history_mode == NetworkHost.HistoryMode.LAST_TRICK_ONLY:
		history_lines = _get_restricted_network_history_lines(snapshot, active_trick)
		history_label.text = _format_suit_symbols_for_light_ui("\n".join(history_lines))
		round_history_panel.visible = is_round_history_visible
		round_history_toggle_button.text = "Последняя взятка"
		round_history_toggle_button.tooltip_text = "Скрыть последнюю взятку" if is_round_history_visible else "Показать последнюю взятку"
		round_history_toggle_button.disabled = false
		return

	history_lines.append("Ход раздачи")
	var public_history: Array = snapshot.get("public_history", [])
	for entry in public_history:
		history_lines.append(str(entry))

	if public_history.is_empty():
		var cards_per_player: int = int(round_data.get("cards_per_player", 0))
		history_lines.append("Раздача %d · %d %s" % [int(round_data.get("number", 0)), cards_per_player, "карта" if cards_per_player == 1 else "карты" if cards_per_player < 5 else "карт"])
		var players_by_index: Dictionary = _get_network_players_by_index(snapshot)
		if active_player_index >= 0 and players_by_index.has(active_player_index):
			history_lines.append("Ходит: %s" % str((players_by_index[active_player_index] as Dictionary).get("display_name", "игрок")))
		if not active_trick.is_empty() and not (active_trick.get("played_cards", []) as Array).is_empty():
			history_lines.append("На столе карт: %d" % (active_trick.get("played_cards", []) as Array).size())
	history_label.text = _format_suit_symbols_for_light_ui("\n".join(history_lines))
	round_history_panel.visible = is_round_history_visible
	round_history_toggle_button.text = "История"
	round_history_toggle_button.tooltip_text = "Скрыть историю" if is_round_history_visible else "Показать историю"
	round_history_toggle_button.disabled = false


func _get_restricted_network_history_lines(snapshot: Dictionary, active_trick: Dictionary) -> PackedStringArray:
	var lines := PackedStringArray(["Последняя взятка"])
	var players_by_index := _get_network_players_by_index(snapshot)
	var last_trick: Dictionary = snapshot.get("last_completed_trick", {})
	var last_cards: Array = last_trick.get("cards", [])
	var last_played_by: Array = last_trick.get("played_by", [])
	if last_cards.is_empty():
		lines.append("Завершённых взяток пока нет.")
	else:
		var winner_index := int(snapshot.get("last_trick_winner_index", -1))
		if players_by_index.has(winner_index):
			lines.append("Забрал: %s" % str((players_by_index[winner_index] as Dictionary).get("display_name", "игрок")))
		for card_index in mini(last_cards.size(), last_played_by.size()):
			var player_index := int(last_played_by[card_index])
			var player_name := "Игрок %d" % (player_index + 1)
			if players_by_index.has(player_index):
				player_name = str((players_by_index[player_index] as Dictionary).get("display_name", player_name))
			var card := _create_network_table_card(last_cards[card_index])
			if card != null:
				lines.append("%s — %s" % [player_name, card.get_card_name()])

	var current_cards: Array = active_trick.get("played_cards", [])
	var current_played_by: Array = active_trick.get("played_by", [])
	lines.append("")
	lines.append("Текущая взятка")
	if current_cards.is_empty():
		lines.append("На столе пока нет карт.")
	else:
		for card_index in mini(current_cards.size(), current_played_by.size()):
			var player_index := int(current_played_by[card_index])
			var player_name := "Игрок %d" % (player_index + 1)
			if players_by_index.has(player_index):
				player_name = str((players_by_index[player_index] as Dictionary).get("display_name", player_name))
			var card := _create_network_table_card(current_cards[card_index])
			if card != null:
				lines.append("%s — %s" % [player_name, card.get_card_name()])
	return lines


func _refresh_network_main_action_controls(snapshot: Dictionary, round_data: Dictionary) -> void:
	_clear_children(bid_controls)
	_clear_children(joker_controls)
	joker_controls.visible = false
	var network_match = _get_active_network_match()
	if network_match == steam_p2p_match and steam_p2p_match.is_host():
		var reconnecting_players: Array[int] = steam_p2p_match.get_reconnecting_player_indices()
		if not reconnecting_players.is_empty():
			for player_index in reconnecting_players:
				var replace_button := Button.new()
				replace_button.text = "Место %d → временный бот" % (player_index + 1)
				replace_button.custom_minimum_size = Vector2(190.0, 40.0)
				_apply_table_action_button_style(replace_button)
				replace_button.pressed.connect(_on_replace_disconnected_player_with_bot_pressed.bind(player_index))
				bid_controls.add_child(replace_button)
			return
	var undo_state: Dictionary = snapshot.get("undo_state", {})
	if bool(undo_state.get("pending", false)):
		_reset_loopback_network_joker_selection()
		_refresh_network_main_undo_vote_controls(snapshot, undo_state)
		return
	var state: int = int(round_data.get("state", Round.State.SETUP))
	if state == Round.State.FINISHED:
		return

	if loopback_network_joker_selection_open:
		_refresh_network_main_joker_controls()
		return

	if state != Round.State.BIDDING:
		return
	var available_bids: Array[int] = []
	if network_match != null and network_match.is_host() and network_match.can_submit_host_test_bid():
		available_bids = network_match.get_available_host_test_bids()
	elif network_match != null and network_match.is_client() and network_match.can_submit_test_bid():
		available_bids = network_match.get_available_test_bids()
	for bid in available_bids:
		var bid_button := Button.new()
		bid_button.text = "Заказать %d" % bid
		bid_button.custom_minimum_size = Vector2(104.0, 40.0)
		_apply_table_action_button_style(bid_button)
		bid_button.pressed.connect(_on_submit_loopback_test_bid_pressed.bind(bid))
		bid_controls.add_child(bid_button)


func _refresh_network_main_undo_vote_controls(snapshot: Dictionary, undo_state: Dictionary) -> void:
	var viewer_index := int(snapshot.get("recipient_player_index", -1))
	var requester_index := int(undo_state.get("requester_player_index", -1))
	var votes: Array = undo_state.get("votes", [])
	var title := Label.new()
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 17)
	title.add_theme_color_override("font_color", Color(0.94, 0.85, 0.42, 1.0))
	bid_controls.add_child(title)
	if viewer_index == requester_index:
		title.text = "Запрос отправлен · ждём решения игроков (%d с)" % int(undo_state.get("seconds_left", 0))
		return

	var has_voted := viewer_index >= 0 and viewer_index < votes.size() and int(votes[viewer_index]) != NetworkHost.UndoVote.NONE
	if has_voted:
		title.text = "Твой голос учтён · ждём остальных (%d с)" % int(undo_state.get("seconds_left", 0))
		return

	title.text = "Разрешить вернуть ход? (%d с)" % int(undo_state.get("seconds_left", 0))
	for vote_data in [["✓ Разрешить", true], ["✕ Отклонить", false]]:
		var vote_button := Button.new()
		vote_button.text = str(vote_data[0])
		vote_button.custom_minimum_size = Vector2(150.0, 40.0)
		_apply_table_action_button_style(vote_button)
		vote_button.pressed.connect(_on_submit_network_undo_vote_pressed.bind(bool(vote_data[1])))
		bid_controls.add_child(vote_button)


func _refresh_network_main_undo_vote_badges(snapshot: Dictionary, viewer_index: int) -> void:
	var undo_state: Dictionary = snapshot.get("undo_state", {})
	var pending := bool(undo_state.get("pending", false))
	var votes: Array = undo_state.get("votes", [])
	var last_rejected_player_index := int(undo_state.get("last_rejected_player_index", -1))
	for relative_slot in undo_vote_badges.size():
		var badge := undo_vote_badges[relative_slot]
		badge.visible = false
		var player_index: int = posmod(relative_slot + viewer_index, PLAYER_NAMES.size())
		if not pending:
			if player_index == last_rejected_player_index:
				badge.visible = true
				badge.add_theme_stylebox_override("panel", undo_vote_rejected_style)
				undo_vote_labels[relative_slot].text = "✕"
				undo_vote_labels[relative_slot].add_theme_color_override("font_color", Color(1.0, 0.9, 0.86, 1.0))
				badge.tooltip_text = "Этот игрок отклонил возврат хода"
			continue
		if player_index < 0 or player_index >= votes.size():
			continue
		var vote_state := int(votes[player_index])
		if vote_state == NetworkHost.UndoVote.NONE:
			continue
		var approved := vote_state == NetworkHost.UndoVote.APPROVED
		badge.visible = true
		badge.add_theme_stylebox_override("panel", undo_vote_approved_style if approved else undo_vote_rejected_style)
		undo_vote_labels[relative_slot].text = "✓" if approved else "✕"
		undo_vote_labels[relative_slot].add_theme_color_override("font_color", Color(0.9, 1.0, 0.86, 1.0) if approved else Color(1.0, 0.9, 0.86, 1.0))
		badge.tooltip_text = "Согласен вернуть ход" if approved else "Не согласен вернуть ход"


func _refresh_network_main_joker_controls() -> void:
	if not _can_submit_loopback_test_joker():
		_reset_loopback_network_joker_selection()
		return

	joker_controls.visible = true
	joker_controls.mouse_filter = Control.MOUSE_FILTER_STOP
	var is_leading_joker := _is_loopback_test_joker_leading()
	if is_leading_joker:
		joker_controls.columns = 1
		_set_control_layout(joker_controls, 0.0, 1.0, 0.0, 1.0, 64.0, -510.0, 444.0, -128.0)
	else:
		joker_controls.columns = 2
		_set_control_layout(joker_controls, 0.5, 1.0, 0.5, 1.0, -280.0, -270.0, 280.0, -218.0)

	if not is_leading_joker:
		joker_controls.columns = 3
		_set_control_layout(joker_controls, 0.5, 1.0, 0.5, 1.0, -390.0, -270.0, 390.0, -218.0)
		_add_network_main_joker_button("Джокер забирает", _on_submit_loopback_test_joker_pressed.bind(Trick.JokerMode.JOKER_WINS))
		_add_network_main_joker_button("Сбросить Джокер (не забирает)", _on_submit_loopback_test_joker_pressed.bind(Trick.JokerMode.NORMAL_CARD_WINS))
		_add_network_main_joker_button("← Назад к картам", _on_cancel_loopback_test_joker_selection_pressed)
		return

	if loopback_network_pending_joker_suit < Card.Suit.CLUBS:
		for suit in [Card.Suit.CLUBS, Card.Suit.SPADES, Card.Suit.HEARTS, Card.Suit.DIAMONDS]:
			_add_network_main_joker_button("Объявить %s" % _get_suit_symbol(suit), _on_choose_loopback_test_joker_suit_pressed.bind(suit))
		_add_network_main_joker_button("Отменить выбор", _on_cancel_loopback_test_joker_selection_pressed)
		return

	var suit_symbol := _get_suit_symbol(loopback_network_pending_joker_suit)
	var conditions: Array = [
		["%s: Джокер забирает" % suit_symbol, Trick.JokerMode.JOKER_WINS, Trick.ForcedCardRank.NONE],
		["%s: старшая забирает" % suit_symbol, Trick.JokerMode.HIGHEST_DECLARED_CARD_WINS, Trick.ForcedCardRank.NONE],
		["%s: младшая забирает" % suit_symbol, Trick.JokerMode.LOWEST_DECLARED_CARD_WINS, Trick.ForcedCardRank.NONE],
		["%s: кладите старшую — Джокер забирает" % suit_symbol, Trick.JokerMode.JOKER_WINS, Trick.ForcedCardRank.HIGHEST],
		["%s: кладите младшую — Джокер забирает" % suit_symbol, Trick.JokerMode.JOKER_WINS, Trick.ForcedCardRank.LOWEST],
		["%s: кладите старшую — Джокер не забирает" % suit_symbol, Trick.JokerMode.NORMAL_CARD_WINS, Trick.ForcedCardRank.HIGHEST],
		["%s: кладите младшую — Джокер не забирает" % suit_symbol, Trick.JokerMode.NORMAL_CARD_WINS, Trick.ForcedCardRank.LOWEST]
	]
	for condition_variant in conditions:
		var condition: Array = condition_variant
		_add_network_main_joker_button(
			str(condition[0]),
			_on_submit_loopback_test_joker_pressed.bind(int(condition[1]), loopback_network_pending_joker_suit, int(condition[2]))
		)
	_add_network_main_joker_button("← Выбрать другую масть", _on_clear_loopback_test_joker_suit_pressed)
	_add_network_main_joker_button("Отменить выбор", _on_cancel_loopback_test_joker_selection_pressed)


func _add_network_main_joker_button(label_text: String, callback: Callable) -> void:
	var button := Button.new()
	button.text = label_text
	button.custom_minimum_size = Vector2(0.0, 44.0)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_table_action_button_style(button)
	button.pressed.connect(callback)
	joker_controls.add_child(button)


func _refresh_network_main_hand(snapshot: Dictionary, round_data: Dictionary) -> void:
	_clear_children(hand_container)
	var private_hand: Array = snapshot.get("private_hand", [])
	var round_finished := int(round_data.get("state", Round.State.SETUP)) == Round.State.FINISHED
	if private_hand.is_empty() and bool(snapshot.get("cards_are_dealt", false)) and not round_finished:
		var waiting_label := Label.new()
		waiting_label.text = "Ожидание личной руки от хоста…"
		waiting_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		waiting_label.add_theme_font_size_override("font_size", 16)
		hand_container.add_child(waiting_label)
		return

	var cards: Array[Card] = []
	var card_keys_by_instance: Dictionary = {}
	for card_index in private_hand.size():
		var card_data_variant: Variant = private_hand[card_index]
		if not (card_data_variant is Dictionary):
			continue
		var card_data: Dictionary = card_data_variant
		var card: Card = _create_network_table_card(card_data)
		if card == null:
			continue
		cards.append(card)
		card_keys_by_instance[card] = str(card_data.get("card_key", ""))

	var trump: Round.TrumpSuit = int(round_data.get("trump", Round.TrumpSuit.NONE))
	var undo_pending: bool = bool((snapshot.get("undo_state", {}) as Dictionary).get("pending", false))
	var presentation_locked := network_card_play_presentation_active or network_round_finish_presentation_active or undo_pending
	var displayed_cards: Array[Card] = _sort_cards_for_display(cards, trump, hand_sort_mode)
	for display_index in displayed_cards.size():
		var card: Card = displayed_cards[display_index]
		var card_view := CardView.new()
		card_view.set_card(card)
		card_view.set_hand_presentation(display_index, displayed_cards.size())
		var card_key: String = str(card_keys_by_instance.get(card, ""))
		var card_is_available := _is_network_table_card_available(card_key)
		var joker_is_available := card.is_joker and _can_submit_loopback_test_joker()
		var interactive := (joker_is_available if card.is_joker else card_is_available) and not presentation_locked
		card_view.set_interactive(interactive, not interactive or loopback_network_joker_selection_open)
		if interactive:
			if card.is_joker:
				card_view.card_pressed.connect(_on_network_table_joker_pressed)
			else:
				card_view.card_pressed.connect(_on_network_table_card_pressed.bind(card_key))
		hand_container.add_child(card_view)


func _refresh_network_main_results(snapshot: Dictionary, round_data: Dictionary) -> void:
	var round_finished := int(round_data.get("state", Round.State.SETUP)) == Round.State.FINISHED
	if not round_finished:
		network_round_result_key = ""
		network_round_finish_presentation_key = ""
		network_round_finish_presentation_active = false
		round_results_title.text = "ИТОГИ РАЗДАЧИ"
		round_results_panel.visible = false
		round_results_label.text = ""
		next_round_button.visible = false
		return

	var result_key := _get_network_round_result_key(snapshot, round_data)
	if network_round_result_key == result_key:
		var full_game_complete := _is_network_full_game_complete(snapshot)
		round_results_title.text = "ИТОГИ ПАРТИИ" if full_game_complete else "ИТОГИ РАЗДАЧИ"
		round_results_panel.visible = true
		round_results_label.text = _get_network_table_result_bbcode(snapshot)
		_fit_round_results_panel(_get_network_table_result_text(snapshot))
		_refresh_network_main_next_round_button()
		return

	round_results_panel.visible = false
	next_round_button.visible = false
	if not network_round_finish_presentation_active:
		network_round_finish_presentation_active = true
		network_round_finish_presentation_key = result_key
		call_deferred("_present_network_round_finish", result_key, int(snapshot.get("last_trick_winner_index", -1)), int(snapshot.get("recipient_player_index", 0)))


func _get_network_round_result_key(snapshot: Dictionary, round_data: Dictionary) -> String:
	return "%d:%d" % [int(round_data.get("number", 0)), int(snapshot.get("revision", -1))]


func _present_network_round_finish(result_key: String, winner_player_index: int, viewer_index: int) -> void:
	await get_tree().process_frame
	while network_card_play_presentation_active:
		await get_tree().process_frame
	if not _is_network_round_result_key_current(result_key):
		network_round_finish_presentation_active = false
		return

	var relative_winner_index: int = posmod(winner_player_index - viewer_index, PLAYER_NAMES.size())
	if winner_player_index >= 0:
		_play_sound(SoundEffect.TRICK)
		_set_trick_winner_highlight(relative_winner_index, true)
		var snapshot := _get_network_main_snapshot()
		var players_by_index := _get_network_players_by_index(snapshot)
		var winner_data: Dictionary = players_by_index.get(winner_player_index, {})
		action_label.text = "Взятку забирает %s." % str(winner_data.get("display_name", "игрок"))
		if _did_network_joker_win_last_trick(snapshot, winner_player_index):
			_show_joker_celebration(relative_winner_index)
		await get_tree().create_timer(TRICK_WINNER_HOLD_DURATION).timeout
		if not _is_network_round_result_key_current(result_key):
			network_round_finish_presentation_active = false
			return
		_set_trick_winner_highlight(relative_winner_index, false)
		await _animate_network_trick_collection(relative_winner_index)

	if not _is_network_round_result_key_current(result_key):
		network_round_finish_presentation_active = false
		return
	network_round_result_key = result_key
	network_round_finish_presentation_key = ""
	network_round_finish_presentation_active = false
	_refresh_network_main_table()


func _is_network_round_result_key_current(result_key: String) -> bool:
	if not _is_steam_p2p_main_table_active():
		return false
	var snapshot := _get_network_main_snapshot()
	var round_data: Dictionary = snapshot.get("round", {})
	return (
		int(round_data.get("state", Round.State.SETUP)) == Round.State.FINISHED
		and _get_network_round_result_key(snapshot, round_data) == result_key
	)


func _animate_network_trick_collection(relative_winner_index: int) -> void:
	if relative_winner_index < 0 or relative_winner_index >= avatar_badges.size():
		return

	var card_size := Vector2(108.0, 132.0)
	var destination_rect: Rect2 = avatar_badges[relative_winner_index].get_global_rect()
	var destination_position := destination_rect.get_center() - card_size * 0.5
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
		tween.tween_property(card_view, "rotation", deg_to_rad(float(player_index - relative_winner_index) * 4.0), TRICK_COLLECTION_DURATION)
		tween.tween_property(card_view, "scale", Vector2(0.36, 0.36), TRICK_COLLECTION_DURATION)
		tween.tween_property(card_view, "modulate", Color(1.0, 1.0, 1.0, 0.0), TRICK_COLLECTION_DURATION)

	if has_visible_cards:
		await tween.finished

	for card_view in trick_card_views:
		card_view.visible = false
		card_view.rotation = 0.0
		card_view.scale = Vector2.ONE
		card_view.modulate = Color.WHITE


func _refresh_network_main_next_round_button() -> void:
	var can_start_next: bool = (
		steam_p2p_match != null
		and steam_p2p_match.is_host()
		and steam_p2p_match.can_start_next_scheduled_round()
	)
	next_round_button.visible = can_start_next
	next_round_button.disabled = not can_start_next
	next_round_button.text = "Следующая раздача"


func _refresh_network_main_markers(snapshot: Dictionary, round_data: Dictionary, viewer_index: int) -> void:
	var state: int = int(round_data.get("state", Round.State.SETUP))
	var dealer_index: int = int(snapshot.get("dealer_index", -1))
	dealer_marker.visible = dealer_index >= 0 and state != Round.State.SETUP
	if dealer_marker.visible:
		_place_table_marker(dealer_marker, posmod(dealer_index - viewer_index, PLAYER_NAMES.size()), true)

	var lead_player_index: int = int(round_data.get("lead_player_index", -1))
	lead_marker.visible = lead_player_index >= 0 and state == Round.State.PLAYING
	if lead_marker.visible:
		_place_table_marker(lead_marker, posmod(lead_player_index - viewer_index, PLAYER_NAMES.size()), false)


func _refresh_network_main_score_sheet(snapshot: Dictionary, round_data: Dictionary) -> void:
	score_sheet_toggle_button.text = "📋 Расписка"
	score_sheet_toggle_button.disabled = false
	score_sheet_panel.visible = is_score_sheet_visible
	if is_instance_valid(score_sheet_backdrop):
		score_sheet_backdrop.visible = is_score_sheet_visible
	if is_instance_valid(score_sheet_close_button):
		score_sheet_close_button.visible = is_score_sheet_visible
		score_sheet_close_button.disabled = false
	final_results_label.visible = false
	if not is_score_sheet_visible:
		return

	_clear_children(score_sheet_grid)
	score_sheet_grid.columns = 1
	var completed_rounds: Dictionary = {}
	var completed_rounds_data: Array = snapshot.get("completed_rounds", [])
	for completed_round_variant in completed_rounds_data:
		if completed_round_variant is Dictionary:
			var completed_round: Dictionary = completed_round_variant
			completed_rounds[int(completed_round.get("round_number", 0))] = completed_round

	score_sheet_title.text = "Сетевая расписка: %d из %d раздач сыграно · полный план партии" % [completed_rounds.size(), TOTAL_ROUND_COUNT]
	var header_row := _create_score_sheet_row()
	_add_score_sheet_cell(header_row, "№", true, false, false, SCORE_SHEET_NUMBER_COLUMN_WIDTH)
	_add_score_sheet_cell(header_row, "Режим", true, false, false, SCORE_SHEET_MODE_COLUMN_WIDTH)
	_add_score_sheet_cell(header_row, "Карт", true, false, false, SCORE_SHEET_CARDS_COLUMN_WIDTH)
	_add_score_sheet_cell(header_row, "Козырь", true, false, false, SCORE_SHEET_TRUMP_COLUMN_WIDTH)
	var players_by_index: Dictionary = _get_network_players_by_index(snapshot)
	for player_index in range(PLAYER_NAMES.size()):
		var player_data: Dictionary = players_by_index.get(player_index, {})
		_add_score_sheet_player_header(header_row, player_index, str(player_data.get("display_name", "Игрок %d" % (player_index + 1))))
	score_sheet_grid.add_child(header_row)

	var current_round_number := int(round_data.get("number", 0))
	for round_number in range(1, TOTAL_ROUND_COUNT + 1):
		var round_plan := _get_planned_round(round_number)
		var has_completed_round := completed_rounds.has(round_number)
		var is_current_round := round_number == current_round_number and not has_completed_round
		var is_future_round := round_number > current_round_number
		var trump_name := str(round_plan.get("trump_name", "—"))

		if has_completed_round:
			var completed_round: Dictionary = completed_rounds[round_number]
			trump_name = str(completed_round.get("trump_name", trump_name))
		elif is_current_round:
			var trump_card: Card = _create_network_table_card(snapshot.get("trump_card", {}))
			if trump_card != null:
				trump_name = "без козыря" if trump_card.is_joker else _get_suit_symbol(trump_card.suit)
			else:
				trump_name = _get_trump_name_from_suit(int(round_data.get("trump", Round.TrumpSuit.RANDOM)))

		var row := _create_score_sheet_row()
		_add_score_sheet_cell(row, str(round_number), false, is_current_round, is_future_round, SCORE_SHEET_NUMBER_COLUMN_WIDTH)
		_add_score_sheet_cell(row, str(round_plan.get("label", "Раздача %d" % round_number)), false, is_current_round, is_future_round, SCORE_SHEET_MODE_COLUMN_WIDTH)
		_add_score_sheet_cell(row, str(int(round_plan.get("cards_per_player", 0))), false, is_current_round, is_future_round, SCORE_SHEET_CARDS_COLUMN_WIDTH)
		_add_score_sheet_cell(row, trump_name, false, is_current_round, is_future_round, SCORE_SHEET_TRUMP_COLUMN_WIDTH)

		for player_index in range(PLAYER_NAMES.size()):
			var result_cells := PackedStringArray(["—", "—", "—"])
			if has_completed_round:
				var completed_round: Dictionary = completed_rounds[round_number]
				var player_results: Array = completed_round.get("players", [])
				if player_index < player_results.size() and player_results[player_index] is Dictionary:
					var player_result: Dictionary = player_results[player_index]
					var bid_text := str(player_result.get("bid", "—")) if bool(completed_round.get("uses_bids", true)) else "—"
					result_cells = PackedStringArray([
						bid_text,
						str(int(player_result.get("tricks_taken", 0))),
						_format_score(int(player_result.get("round_score", 0)))
					])
			elif is_current_round:
				var player_data: Dictionary = players_by_index.get(player_index, {})
				var bid_value := int(player_data.get("bid", -1))
				var bid_text := str(bid_value) if bool(round_plan.get("uses_bids", true)) and bid_value >= 0 else "—"
				result_cells = PackedStringArray([bid_text, str(int(player_data.get("tricks_taken", 0))), "…"])

			_add_score_sheet_player_group(row, player_index, result_cells, is_current_round, is_future_round)

		score_sheet_grid.add_child(row)

	var total_row := _create_score_sheet_row()
	_add_score_sheet_cell(total_row, "Итого", false, false, false, SCORE_SHEET_NUMBER_COLUMN_WIDTH, true)
	_add_score_sheet_cell(total_row, "", false, false, false, SCORE_SHEET_MODE_COLUMN_WIDTH, true)
	_add_score_sheet_cell(total_row, "", false, false, false, SCORE_SHEET_CARDS_COLUMN_WIDTH, true)
	_add_score_sheet_cell(total_row, "", false, false, false, SCORE_SHEET_TRUMP_COLUMN_WIDTH, true)
	for player_index in range(PLAYER_NAMES.size()):
		var player_data: Dictionary = players_by_index.get(player_index, {})
		_add_score_sheet_player_group(
			total_row,
			player_index,
			PackedStringArray(["", "", "Счёт: %d" % int(player_data.get("total_score", 0))]),
			false,
			false,
			true
		)
	score_sheet_grid.add_child(total_row)


func _on_close_loopback_network_test_pressed() -> void:
	_reset_loopback_network_joker_selection()
	if is_instance_valid(network_table_view):
		network_table_view.visible = false
	loopback_network_test.stop()
	_build_main_menu_content()


func _refresh_loopback_network_status() -> void:
	if is_instance_valid(loopback_network_status_label) and loopback_network_test != null:
		loopback_network_status_label.text = loopback_network_test.status_text
	if is_instance_valid(loopback_network_private_hand_label) and loopback_network_test != null:
		loopback_network_private_hand_label.text = loopback_network_test.get_client_private_hand_text()
	if is_instance_valid(loopback_network_start_round_button) and loopback_network_test != null:
		loopback_network_start_round_button.disabled = not loopback_network_test.can_start_test_round()
	if is_instance_valid(loopback_network_start_joker_round_button) and loopback_network_test != null:
		loopback_network_start_joker_round_button.disabled = not loopback_network_test.can_start_test_round()
	if is_instance_valid(loopback_network_start_response_joker_round_button) and loopback_network_test != null:
		loopback_network_start_response_joker_round_button.disabled = not loopback_network_test.can_start_test_round()
	_refresh_loopback_network_action_controls()
	if not loopback_network_is_technical_presentation and _should_open_network_table_automatically():
		if is_instance_valid(network_table_view) and not network_table_view.visible:
			menu_overlay.visible = false
			network_table_view.visible = true
	if is_instance_valid(network_table_view) and network_table_view.visible:
		_refresh_network_table_view()


func _should_open_network_table_automatically() -> bool:
	var network_match = _get_active_network_match()
	if network_match == null or not network_match.is_running():
		return false
	var snapshot: Dictionary = network_match.get_test_table_snapshot()
	if snapshot.is_empty():
		return false
	var round_data: Dictionary = snapshot.get("round", {})
	return int(round_data.get("state", Round.State.SETUP)) != Round.State.SETUP


func _on_open_network_table_pressed() -> void:
	var network_match = _get_active_network_match()
	if network_match == null or not network_match.is_running():
		return
	_reset_loopback_network_joker_selection()
	menu_overlay.visible = false
	steam_p2p_main_table_presentation = false
	network_table_view.visible = true
	_refresh_network_table_view()


func _on_close_network_table_pressed() -> void:
	_reset_loopback_network_joker_selection()
	steam_p2p_main_table_presentation = false
	if is_instance_valid(network_table_view):
		network_table_view.visible = false
	if _is_steam_p2p_table_active():
		steam_p2p_table_presentation = false
		is_pause_menu_open = false
		_show_steam_lobby_menu()
	else:
		_show_loopback_network_lobby()


func _create_network_table_view() -> void:
	network_table_view = Control.new()
	network_table_view.name = "LoopbackNetworkTableView"
	network_table_view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	network_table_view.mouse_filter = Control.MOUSE_FILTER_STOP
	network_table_view.z_index = 95
	network_table_view.visible = false
	add_child(network_table_view)

	network_table_backdrop = ColorRect.new()
	network_table_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	network_table_backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	network_table_view.add_child(network_table_backdrop)

	network_table_surface = Panel.new()
	network_table_surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
	network_table_surface.add_theme_stylebox_override(
		"panel",
		_create_flat_style(_get_felt_color().darkened(0.12), _get_table_rim_color().lightened(0.24), 8, 250, 10)
	)
	_set_control_layout(network_table_surface, 0.5, 0.5, 0.5, 0.5, -690.0, -335.0, 690.0, 330.0)
	network_table_view.add_child(network_table_surface)
	_apply_table_theme()

	var history_panel := PanelContainer.new()
	history_panel.add_theme_stylebox_override("panel", _create_flat_style(Color(0.965, 0.95, 0.89, 0.98), Color(0.45, 0.31, 0.12, 0.9), 2, 8, 3))
	history_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_set_control_layout(history_panel, 0.0, 0.0, 0.0, 0.0, 20.0, 72.0, 298.0, 255.0)
	network_table_view.add_child(history_panel)
	network_table_history_label = RichTextLabel.new()
	network_table_history_label.bbcode_enabled = true
	network_table_history_label.fit_content = true
	network_table_history_label.scroll_active = false
	network_table_history_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	network_table_history_label.add_theme_font_size_override("normal_font_size", 14)
	network_table_history_label.add_theme_color_override("default_color", Color(0.08, 0.09, 0.075, 1.0))
	network_table_history_label.add_theme_color_override("font_color", Color(0.08, 0.09, 0.075, 1.0))
	network_table_history_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	network_table_history_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	history_panel.add_child(network_table_history_label)

	network_table_title_label = Label.new()
	network_table_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	network_table_title_label.add_theme_font_size_override("font_size", 24)
	network_table_title_label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.38, 1.0))
	_set_control_layout(network_table_title_label, 0.5, 0.0, 0.5, 0.0, -330.0, 20.0, 330.0, 54.0)
	network_table_view.add_child(network_table_title_label)

	network_table_round_label = Label.new()
	network_table_round_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	network_table_round_label.add_theme_font_size_override("font_size", 17)
	network_table_round_label.add_theme_color_override("font_color", Color(0.76, 0.9, 0.78, 1.0))
	_set_control_layout(network_table_round_label, 0.5, 0.0, 0.5, 0.0, -420.0, 58.0, 420.0, 84.0)
	network_table_view.add_child(network_table_round_label)

	network_table_info_panel = PanelContainer.new()
	network_table_info_panel.add_theme_stylebox_override("panel", _create_flat_style(Color(0.008, 0.035, 0.018, 0.94), Color(0.57, 0.4, 0.11, 0.9), 1, 9, 3))
	network_table_info_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_set_control_layout(network_table_info_panel, 1.0, 1.0, 1.0, 1.0, -430.0, -300.0, -44.0, -158.0)
	network_table_view.add_child(network_table_info_panel)
	network_table_info_label = Label.new()
	network_table_info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	network_table_info_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	network_table_info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	network_table_info_label.add_theme_font_size_override("font_size", 15)
	network_table_info_label.add_theme_color_override("font_color", Color(0.78, 0.86, 0.78, 1.0))
	network_table_info_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	network_table_info_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	network_table_info_panel.add_child(network_table_info_label)

	network_table_deck_label = Label.new()
	network_table_deck_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	network_table_deck_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	network_table_deck_label.add_theme_font_size_override("font_size", 15)
	network_table_deck_label.add_theme_color_override("font_color", Color(0.88, 0.9, 0.8, 1.0))
	_set_control_layout(network_table_deck_label, 1.0, 0.0, 1.0, 0.0, -420.0, 198.0, -42.0, 244.0)
	network_table_view.add_child(network_table_deck_label)
	_create_network_table_deck_visual()

	network_table_close_button = Button.new()
	network_table_close_button.custom_minimum_size = Vector2(185.0, 38.0)
	_apply_table_action_button_style(network_table_close_button)
	network_table_close_button.pressed.connect(_on_close_network_table_pressed)
	_set_control_layout(network_table_close_button, 1.0, 0.0, 1.0, 0.0, -230.0, 25.0, -34.0, 63.0)
	network_table_view.add_child(network_table_close_button)

	network_table_trick_label = Label.new()
	network_table_trick_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	network_table_trick_label.add_theme_font_size_override("font_size", 18)
	network_table_trick_label.add_theme_color_override("font_color", Color(0.85, 0.92, 0.84, 1.0))
	_set_control_layout(network_table_trick_label, 0.5, 0.5, 0.5, 0.5, -260.0, -168.0, 260.0, -140.0)
	network_table_view.add_child(network_table_trick_label)

	network_table_joker_label = Label.new()
	network_table_joker_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	network_table_joker_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	network_table_joker_label.add_theme_font_size_override("font_size", 15)
	network_table_joker_label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.38, 1.0))
	_set_control_layout(network_table_joker_label, 0.5, 0.5, 0.5, 0.5, -330.0, -138.0, 330.0, -104.0)
	network_table_view.add_child(network_table_joker_label)

	network_table_trick_layer = Control.new()
	network_table_trick_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	network_table_trick_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	network_table_view.add_child(network_table_trick_layer)

	_create_network_table_player_widgets()

	network_table_action_panel = PanelContainer.new()
	network_table_action_panel.add_theme_stylebox_override("panel", _create_flat_style(Color(0.008, 0.035, 0.018, 0.92), Color(0.56, 0.39, 0.1, 0.82), 1, 8, 3))
	network_table_action_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	network_table_view.add_child(network_table_action_panel)

	network_table_action_controls = VBoxContainer.new()
	network_table_action_controls.add_theme_constant_override("separation", 6)
	network_table_action_panel.add_child(network_table_action_controls)

	network_table_hand_container = HBoxContainer.new()
	network_table_hand_container.alignment = BoxContainer.ALIGNMENT_CENTER
	network_table_hand_container.add_theme_constant_override("separation", 12)
	_set_control_layout(network_table_hand_container, 0.5, 1.0, 0.5, 1.0, -500.0, -165.0, 500.0, -28.0)
	network_table_view.add_child(network_table_hand_container)


func _create_network_table_deck_visual() -> void:
	network_table_deck_visual = Control.new()
	network_table_deck_visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_set_control_layout(network_table_deck_visual, 1.0, 0.0, 1.0, 0.0, -270.0, 106.0, -52.0, 196.0)
	network_table_view.add_child(network_table_deck_visual)

	for card_index in range(3):
		var card_back := PanelContainer.new()
		card_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card_back.position = Vector2(float(card_index * 13), 9.0)
		card_back.size = Vector2(60.0, 82.0)
		card_back.add_theme_stylebox_override("panel", card_back_style)
		if not _add_card_back_artwork(card_back):
			var ornament := Label.new()
			ornament.text = "✦"
			ornament.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			ornament.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			ornament.add_theme_font_size_override("font_size", 24)
			ornament.add_theme_color_override("font_color", Color(0.94, 0.73, 0.22, 1.0))
			ornament.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			card_back.add_child(ornament)
		network_table_deck_visual.add_child(card_back)
		network_table_deck_back_panels.append(card_back)

	network_table_trump_card_view = CardView.new()
	network_table_trump_card_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	network_table_trump_card_view.set_card_size(Vector2(68.0, 96.0))
	network_table_trump_card_view.position = Vector2(56.0, 0.0)
	network_table_deck_visual.add_child(network_table_trump_card_view)


func _create_network_table_player_widgets() -> void:
	for player_index in PLAYER_NAMES.size():
		var panel := PanelContainer.new()
		panel.add_theme_stylebox_override("panel", player_panel_style)
		panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		network_table_view.add_child(panel)
		network_table_player_panels.append(panel)

		var content := VBoxContainer.new()
		content.alignment = BoxContainer.ALIGNMENT_CENTER
		content.add_theme_constant_override("separation", 1)
		panel.add_child(content)

		var name_label := Label.new()
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.add_theme_font_size_override("font_size", 19)
		content.add_child(name_label)
		network_table_player_name_labels.append(name_label)

		var stats_label := RichTextLabel.new()
		stats_label.bbcode_enabled = true
		stats_label.fit_content = true
		stats_label.scroll_active = false
		stats_label.custom_minimum_size = Vector2(0.0, 32.0)
		stats_label.add_theme_font_size_override("normal_font_size", 17)
		stats_label.add_theme_color_override("font_color", Color(0.83, 0.89, 0.82, 1.0))
		content.add_child(stats_label)
		network_table_player_stats_labels.append(stats_label)

		var score_label := Label.new()
		score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		score_label.add_theme_font_size_override("font_size", 18)
		content.add_child(score_label)
		network_table_player_score_labels.append(score_label)

		var avatar_panel := PanelContainer.new()
		avatar_panel.add_theme_stylebox_override("panel", avatar_badge_style)
		avatar_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		network_table_view.add_child(avatar_panel)
		network_table_avatar_panels.append(avatar_panel)

		var avatar_image := TextureRect.new()
		avatar_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		avatar_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		avatar_image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		avatar_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
		avatar_panel.add_child(avatar_image)
		network_table_avatar_images.append(avatar_image)

		var avatar_symbol := Label.new()
		avatar_symbol.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		avatar_symbol.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		avatar_symbol.add_theme_font_size_override("font_size", 30)
		avatar_symbol.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		avatar_symbol.mouse_filter = Control.MOUSE_FILTER_IGNORE
		avatar_panel.add_child(avatar_symbol)
		network_table_avatar_symbols.append(avatar_symbol)


func _place_network_table_player_widgets(player_index: int, relative_slot: int) -> void:
	var panel: PanelContainer = network_table_player_panels[player_index]
	var avatar: PanelContainer = network_table_avatar_panels[player_index]
	match relative_slot:
		0:
			_set_control_layout(panel, 0.5, 0.5, 0.5, 0.5, -150.0, 240.0, 150.0, 340.0)
			_set_control_layout(avatar, 0.5, 0.5, 0.5, 0.5, -260.0, 238.0, -170.0, 328.0)
		1:
			_set_control_layout(panel, 0.5, 0.5, 0.5, 0.5, -640.0, -46.0, -340.0, 54.0)
			_set_control_layout(avatar, 0.5, 0.5, 0.5, 0.5, -750.0, -48.0, -660.0, 42.0)
		2:
			_set_control_layout(panel, 0.5, 0.5, 0.5, 0.5, -150.0, -346.0, 150.0, -246.0)
			_set_control_layout(avatar, 0.5, 0.5, 0.5, 0.5, -260.0, -348.0, -170.0, -258.0)
		3:
			_set_control_layout(panel, 0.5, 0.5, 0.5, 0.5, 340.0, -46.0, 640.0, 54.0)
			_set_control_layout(avatar, 0.5, 0.5, 0.5, 0.5, 660.0, -48.0, 750.0, 42.0)


func _refresh_network_table_view() -> void:
	var network_match = _get_active_network_match()
	if not is_instance_valid(network_table_view) or network_match == null:
		return

	if _is_steam_p2p_table_active():
		network_table_title_label.text = "Steam P2P · сетевая партия"
		network_table_close_button.text = "Вернуться в Steam-комнату"
		network_table_close_button.tooltip_text = "Вернуться в техническую Steam-комнату"
	else:
		network_table_title_label.text = "Сетевой стол · локальный ENet-тест" if loopback_network_is_technical_presentation else "Сетевая партия"
		network_table_close_button.text = "Вернуться к тесту" if loopback_network_is_technical_presentation else "Вернуться в комнату"
		network_table_close_button.tooltip_text = "Вернуться к техническому окну локальной сети" if loopback_network_is_technical_presentation else "Вернуться в комнату"
	var snapshot: Dictionary = network_match.get_test_table_snapshot()
	if snapshot.is_empty():
		network_table_round_label.text = "Ожидание безопасного снимка стола"
		network_table_info_label.text = "Подключение к хосту… после запуска раздачи здесь появятся публичный стол и только твоя рука."
		network_table_info_panel.visible = false
		network_table_history_label.text = "Сетевая история\n\nПодключение к хосту…\n\nПосле старта здесь появятся только общедоступные события раздачи."
		network_table_deck_label.text = ""
		_refresh_network_table_deck_visual({})
		network_table_trick_label.text = "Стол ещё не создан"
		network_table_joker_label.text = ""
		_clear_network_table_trick_cards()
		_refresh_network_table_hand([])
		_refresh_network_table_action_controls({})
		return

	var round_data: Dictionary = snapshot.get("round", {})
	var active_trick: Dictionary = snapshot.get("active_trick", {})
	var viewer_index: int = network_match.get_test_table_viewer_index()
	var active_player_index := _get_network_table_active_player_index(round_data, active_trick)
	_refresh_network_table_header(snapshot, round_data, active_trick, active_player_index)
	_refresh_network_table_history(snapshot, round_data, active_trick, active_player_index)
	_refresh_network_table_players(snapshot, viewer_index, active_player_index)
	_refresh_network_table_trick(snapshot, viewer_index, active_trick)
	var private_hand: Array = snapshot.get("private_hand", [])
	_refresh_network_table_hand(private_hand)
	_refresh_network_table_action_controls(snapshot)


func _refresh_network_table_header(snapshot: Dictionary, round_data: Dictionary, active_trick: Dictionary, active_player_index: int) -> void:
	var round_number: int = int(round_data.get("number", 0))
	var cards_per_player: int = int(round_data.get("cards_per_player", 0))
	var state: int = int(round_data.get("state", -1))
	var phase_text := "Ожидание"
	if state == Round.State.BIDDING:
		phase_text = "заказ взяток"
	elif state == Round.State.PLAYING:
		phase_text = "розыгрыш взяток"
	elif state == Round.State.FINISHED:
		phase_text = "раздача завершена"
	var round_type_text := "Обычная"
	match int(round_data.get("round_type", Round.RoundType.NORMAL)):
		Round.RoundType.DARK:
			round_type_text = "Тёмная"
		Round.RoundType.MISERE:
			round_type_text = "Мизер"
		Round.RoundType.GOLDEN:
			round_type_text = "Золотая"
		Round.RoundType.NO_TRUMP:
			round_type_text = "Бескозырная"
	var cards_text := "карта" if cards_per_player == 1 else "карты" if cards_per_player >= 2 and cards_per_player <= 4 else "карт"
	var technical_prefix := "Тестовая " if loopback_network_is_technical_presentation and not _is_steam_p2p_table_active() else ""
	network_table_round_label.text = "%s%s раздача %d · %d %s · %s" % [technical_prefix, round_type_text, round_number, cards_per_player, cards_text, phase_text]

	var trump_data: Dictionary = snapshot.get("trump_card", {})
	var trump_card: Card = _create_network_table_card(trump_data)
	_refresh_network_table_deck_visual(trump_data)
	if trump_card == null:
		var scheduled_trump := int(round_data.get("trump", Round.TrumpSuit.RANDOM))
		network_table_deck_label.text = (
			"Колода ещё не открыта"
			if scheduled_trump == Round.TrumpSuit.RANDOM
			else "Без козыря"
			if scheduled_trump == Round.TrumpSuit.NONE
			else "Козырь по расписанию: %s" % _get_trump_name_from_suit(scheduled_trump)
		)
	elif trump_card.is_joker:
		network_table_deck_label.text = "Открытый Джокер · без козыря\nВ колоде: %d" % int(snapshot.get("cards_left_in_deck", 0))
	else:
		network_table_deck_label.text = "Открытый козырь: %s\nВ колоде: %d" % [trump_card.get_card_name(), int(snapshot.get("cards_left_in_deck", 0))]

	if state == Round.State.FINISHED:
		network_table_info_label.text = _get_network_table_result_text(snapshot, true)
		network_table_info_panel.visible = true
	elif active_player_index >= 0:
		network_table_info_panel.visible = false
		network_table_info_label.text = "Сейчас действует место %d." % [active_player_index + 1]
	else:
		network_table_info_panel.visible = false
		network_table_info_label.text = "Ожидание следующего действия хоста."

	var joker_text := _get_network_table_joker_text(active_trick)
	network_table_joker_label.text = joker_text


func _refresh_network_table_deck_visual(trump_data: Dictionary) -> void:
	if not is_instance_valid(network_table_deck_visual) or not is_instance_valid(network_table_trump_card_view):
		return
	var trump_card: Card = _create_network_table_card(trump_data)
	var has_open_trump := trump_card != null
	network_table_deck_visual.visible = has_open_trump
	network_table_trump_card_view.visible = has_open_trump
	for card_back in network_table_deck_back_panels:
		card_back.visible = has_open_trump
	if has_open_trump:
		network_table_trump_card_view.set_card(trump_card)


func _refresh_network_table_history(snapshot: Dictionary, round_data: Dictionary, active_trick: Dictionary, active_player_index: int) -> void:
	if not is_instance_valid(network_table_history_label):
		return
	var history_lines: PackedStringArray = ["Сетевая история"]
	var round_number: int = int(round_data.get("number", 0))
	var cards_per_player: int = int(round_data.get("cards_per_player", 0))
	if round_number > 0:
		history_lines.append("Раздача %d · по %d %s" % [round_number, cards_per_player, "карте" if cards_per_player == 1 else "карт"])
	var trump_card: Card = _create_network_table_card(snapshot.get("trump_card", {}))
	if trump_card != null:
		history_lines.append("Козырь: %s" % ("без козыря" if trump_card.is_joker else trump_card.get_card_name()))

	var state: int = int(round_data.get("state", -1))
	if state == Round.State.BIDDING:
		history_lines.append("Заказы: %d из %d" % [int(round_data.get("bids_made", 0)), PLAYER_NAMES.size()])
	elif state == Round.State.PLAYING:
		history_lines.append("Взятка %d" % (int(round_data.get("tricks_played", 0)) + 1))
	elif state == Round.State.FINISHED:
		history_lines.append("Раздача завершена")

	var players_by_index: Dictionary = {}
	for player_data_variant in snapshot.get("players", []):
		if player_data_variant is Dictionary:
			var player_data: Dictionary = player_data_variant
			players_by_index[int(player_data.get("player_index", -1))] = str(player_data.get("display_name", "Игрок"))
	if active_player_index >= 0 and active_player_index in players_by_index:
		history_lines.append("Действует: %s" % str(players_by_index[active_player_index]))
	var last_winner_index: int = int(snapshot.get("last_trick_winner_index", -1))
	if last_winner_index >= 0 and last_winner_index in players_by_index:
		history_lines.append("Последняя взятка: %s" % str(players_by_index[last_winner_index]))
	if not active_trick.is_empty() and not (active_trick.get("played_cards", []) as Array).is_empty():
		history_lines.append("Карты на столе: %d" % (active_trick.get("played_cards", []) as Array).size())
	network_table_history_label.text = _format_suit_symbols_for_light_ui("\n".join(history_lines))


func _refresh_network_table_players(snapshot: Dictionary, viewer_index: int, active_player_index: int) -> void:
	var players_data: Array = snapshot.get("players", [])
	var players_by_index: Dictionary = {}
	var network_round_data: Dictionary = snapshot.get("round", {})
	var uses_bids := _round_type_uses_bids(int(network_round_data.get("round_type", Round.RoundType.NORMAL)))
	for player_data_variant in players_data:
		if not (player_data_variant is Dictionary):
			continue
		var player_data: Dictionary = player_data_variant
		players_by_index[int(player_data.get("player_index", -1))] = player_data

	for player_index in PLAYER_NAMES.size():
		var player_data: Dictionary = players_by_index.get(player_index, {})
		var relative_slot: int = (player_index - viewer_index + PLAYER_NAMES.size()) % PLAYER_NAMES.size()
		_place_network_table_player_widgets(player_index, relative_slot)
		var is_current := player_index == active_player_index
		var is_reconnecting := _is_network_player_reconnecting(snapshot, player_index)
		var is_temporary_bot := _is_network_player_temporary_bot(snapshot, player_index)
		network_table_player_panels[player_index].add_theme_stylebox_override("panel", active_player_panel_style if is_current else player_panel_style)
		network_table_player_name_labels[player_index].text = (
			("Переподключается · " if is_reconnecting else "Временный бот · " if is_temporary_bot else "")
			+ str(player_data.get("display_name", "Игрок %d" % (player_index + 1)))
		)
		var bid_value: int = int(player_data.get("bid", -1))
		var bid_text := "—" if bid_value < 0 else str(bid_value)
		network_table_player_stats_labels[player_index].text = (
			"[center][color=#ffb34f][b]Переподключается…[/b][/color][/center]"
			if is_reconnecting
			else "[center][color=#ffd45c][b]Бот играет до возвращения[/b][/color][/center]"
			if is_temporary_bot
			else _get_player_stats_bbcode(bid_text, int(player_data.get("tricks_taken", 0)), uses_bids)
		)
		var score: int = int(player_data.get("total_score", 0))
		network_table_player_score_labels[player_index].text = "Счёт: %d" % score
		network_table_player_score_labels[player_index].add_theme_color_override("font_color", Color(0.97, 0.84, 0.38, 1.0) if score >= 0 else Color(0.96, 0.42, 0.34, 1.0))

		var avatar_texture: Texture2D = _get_network_player_avatar_texture(player_index)
		network_table_avatar_images[player_index].texture = avatar_texture
		network_table_avatar_images[player_index].visible = avatar_texture != null
		network_table_avatar_symbols[player_index].text = _get_network_player_avatar_symbol(player_index)
		network_table_avatar_symbols[player_index].visible = avatar_texture == null


func _refresh_network_table_trick(snapshot: Dictionary, viewer_index: int, active_trick: Dictionary) -> void:
	_clear_network_table_trick_cards()
	var trick_data: Dictionary = active_trick
	var is_active := not trick_data.is_empty() and not (trick_data.get("played_cards", []) as Array).is_empty()
	if not is_active:
		trick_data = snapshot.get("last_completed_trick", {})
	var played_cards: Array = trick_data.get("played_cards", trick_data.get("cards", []))
	if played_cards.is_empty():
		network_table_trick_label.text = "Взятка ещё не началась"
		return

	network_table_trick_label.text = "Текущая взятка" if is_active else "Последняя взятка"
	var played_by: Array = trick_data.get("played_by", [])
	var winner_index: int = -1 if is_active else int(snapshot.get("last_trick_winner_index", -1))
	for card_index in played_cards.size():
		if card_index >= played_by.size() or not (played_cards[card_index] is Dictionary):
			continue
		var card_data: Dictionary = played_cards[card_index]
		var card: Card = _create_network_table_card(card_data)
		if card == null:
			continue
		var player_index: int = int(played_by[card_index])
		var relative_slot: int = (player_index - viewer_index + PLAYER_NAMES.size()) % PLAYER_NAMES.size()
		var card_view := CardView.new()
		card_view.set_card(card)
		card_view.set_card_size(Vector2(82.0, 118.0))
		card_view.set_table_presentation(relative_slot)
		card_view.set_winner_highlight(player_index == winner_index)
		_place_network_table_trick_card(card_view, relative_slot)
		network_table_trick_layer.add_child(card_view)


func _place_network_table_trick_card(card_view: CardView, relative_slot: int) -> void:
	match relative_slot:
		0:
			_set_control_layout(card_view, 0.5, 0.5, 0.5, 0.5, -42.0, 86.0, 40.0, 204.0)
		1:
			_set_control_layout(card_view, 0.5, 0.5, 0.5, 0.5, -250.0, -6.0, -168.0, 112.0)
		2:
			_set_control_layout(card_view, 0.5, 0.5, 0.5, 0.5, -42.0, -128.0, 40.0, -10.0)
		3:
			_set_control_layout(card_view, 0.5, 0.5, 0.5, 0.5, 168.0, -6.0, 250.0, 112.0)


func _refresh_network_table_hand(private_hand: Array) -> void:
	if not is_instance_valid(network_table_hand_container):
		return
	_clear_children(network_table_hand_container)
	for card_index in private_hand.size():
		var card_data_variant: Variant = private_hand[card_index]
		if not (card_data_variant is Dictionary):
			continue
		var card_data: Dictionary = card_data_variant
		var card: Card = _create_network_table_card(card_data)
		if card == null:
			continue
		var card_view := CardView.new()
		card_view.set_card(card)
		card_view.set_card_size(Vector2(86.0, 124.0))
		card_view.set_hand_presentation(card_index, private_hand.size())
		var card_key: String = str(card_data.get("card_key", ""))
		var card_is_available := _is_network_table_card_available(card_key)
		var joker_is_available := card.is_joker and _can_submit_loopback_test_joker()
		var interactive := joker_is_available if card.is_joker else card_is_available
		card_view.set_interactive(interactive, not interactive)
		if interactive:
			if card.is_joker:
				card_view.card_pressed.connect(_on_network_table_joker_pressed)
			else:
				card_view.card_pressed.connect(_on_network_table_card_pressed.bind(card_key))
		network_table_hand_container.add_child(card_view)


func _on_network_table_card_pressed(_card: Card, card_key: String) -> void:
	_on_submit_loopback_test_card_pressed(card_key)


func _on_network_table_joker_pressed(_card: Card) -> void:
	_on_open_loopback_test_joker_selection_pressed()


func _is_network_table_card_available(card_key: String) -> bool:
	var network_match = _get_active_network_match()
	if network_match == null or card_key.is_empty():
		return false
	var available_cards: Array[Dictionary] = []
	if network_match.is_host() and network_match.can_submit_host_test_card():
		available_cards = network_match.get_available_host_test_cards()
	elif network_match.is_client() and network_match.can_submit_test_card():
		available_cards = network_match.get_available_test_cards()
	for card_data in available_cards:
		if str(card_data.get("card_key", "")) == card_key:
			return true
	return false


func _refresh_network_table_action_controls(snapshot: Dictionary) -> void:
	if not is_instance_valid(network_table_action_controls):
		return
	_clear_children(network_table_action_controls)
	if snapshot.is_empty():
		network_table_action_panel.visible = false
		return
	network_table_action_panel.visible = true
	if steam_p2p_match != null and _get_active_network_match() == steam_p2p_match and steam_p2p_match.is_host():
		var reconnecting_players: Array[int] = steam_p2p_match.get_reconnecting_player_indices()
		if not reconnecting_players.is_empty():
			_place_network_table_action_panel(false)
			for player_index in reconnecting_players:
				network_table_action_controls.add_child(_create_network_table_action_button(
					"Место %d → временный бот" % (player_index + 1),
					_on_replace_disconnected_player_with_bot_pressed.bind(player_index),
					true
				))
			return
	if loopback_network_joker_selection_open:
		_place_network_table_action_panel(true)
		_create_network_table_joker_choice_controls()
		return

	_place_network_table_action_panel(false)
	var available_bids: Array[int] = []
	var network_match = _get_active_network_match()
	if network_match != null and network_match.is_host() and network_match.can_submit_host_test_bid():
		available_bids = network_match.get_available_host_test_bids()
	elif network_match != null and network_match.is_client() and network_match.can_submit_test_bid():
		available_bids = network_match.get_available_test_bids()

	var title := Label.new()
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(0.9, 0.94, 0.85, 1.0))
	network_table_action_controls.add_child(title)
	if not available_bids.is_empty():
		title.text = "Твой заказ"
		var bid_row := HBoxContainer.new()
		bid_row.alignment = BoxContainer.ALIGNMENT_CENTER
		bid_row.add_theme_constant_override("separation", 8)
		network_table_action_controls.add_child(bid_row)
		for bid in available_bids:
			var bid_button := _create_network_table_action_button("Заказать %d" % bid, _on_submit_loopback_test_bid_pressed.bind(bid), true)
			bid_row.add_child(bid_button)
		return

	if _is_network_table_card_available_in_any_hand(snapshot) or _can_submit_loopback_test_joker():
		title.text = "Твой ход · выбери подсвеченную карту в руке"
	else:
		network_table_action_panel.visible = false


func _place_network_table_action_panel(is_joker_selection: bool) -> void:
	if is_joker_selection:
		_set_control_layout(network_table_action_panel, 0.0, 0.5, 0.0, 0.5, 24.0, -155.0, 398.0, 210.0)
	else:
		_set_control_layout(network_table_action_panel, 0.5, 1.0, 0.5, 1.0, -360.0, -262.0, 360.0, -202.0)


func _create_network_table_joker_choice_controls() -> void:
	if not _can_submit_loopback_test_joker():
		_reset_loopback_network_joker_selection()
		return
	var title := Label.new()
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(1.0, 0.84, 0.38, 1.0))
	network_table_action_controls.add_child(title)

	if not _is_loopback_test_joker_leading():
		title.text = "Джокер: выбери вариант"
		var response_row := HBoxContainer.new()
		response_row.alignment = BoxContainer.ALIGNMENT_CENTER
		response_row.add_theme_constant_override("separation", 8)
		network_table_action_controls.add_child(response_row)
		response_row.add_child(_create_network_table_action_button("Джокер забирает", _on_submit_loopback_test_joker_pressed.bind(Trick.JokerMode.JOKER_WINS), true))
		response_row.add_child(_create_network_table_action_button("Сбросить Джокер", _on_submit_loopback_test_joker_pressed.bind(Trick.JokerMode.NORMAL_CARD_WINS)))
		network_table_action_controls.add_child(_create_network_table_action_button("Отменить выбор", _on_cancel_loopback_test_joker_selection_pressed))
		return

	if loopback_network_pending_joker_suit < Card.Suit.CLUBS:
		title.text = "Джокер: объяви масть"
		var suit_grid := GridContainer.new()
		suit_grid.columns = 2
		suit_grid.add_theme_constant_override("h_separation", 8)
		suit_grid.add_theme_constant_override("v_separation", 6)
		network_table_action_controls.add_child(suit_grid)
		for suit in [Card.Suit.CLUBS, Card.Suit.SPADES, Card.Suit.HEARTS, Card.Suit.DIAMONDS]:
			suit_grid.add_child(_create_network_table_action_button("Объявить %s" % _get_suit_symbol(suit), _on_choose_loopback_test_joker_suit_pressed.bind(suit), true))
		network_table_action_controls.add_child(_create_network_table_action_button("Отменить выбор", _on_cancel_loopback_test_joker_selection_pressed))
		return

	var suit_symbol := _get_suit_symbol(loopback_network_pending_joker_suit)
	title.text = "Джокер: условие для %s" % suit_symbol
	var conditions := [
		["%s: Джокер забирает" % suit_symbol, Trick.JokerMode.JOKER_WINS, Trick.ForcedCardRank.NONE],
		["%s: старшая забирает" % suit_symbol, Trick.JokerMode.HIGHEST_DECLARED_CARD_WINS, Trick.ForcedCardRank.NONE],
		["%s: младшая забирает" % suit_symbol, Trick.JokerMode.LOWEST_DECLARED_CARD_WINS, Trick.ForcedCardRank.NONE],
		["%s: кладите старшую — Джокер забирает" % suit_symbol, Trick.JokerMode.JOKER_WINS, Trick.ForcedCardRank.HIGHEST],
		["%s: кладите младшую — Джокер забирает" % suit_symbol, Trick.JokerMode.JOKER_WINS, Trick.ForcedCardRank.LOWEST],
		["%s: кладите старшую — Джокер не забирает" % suit_symbol, Trick.JokerMode.NORMAL_CARD_WINS, Trick.ForcedCardRank.HIGHEST],
		["%s: кладите младшую — Джокер не забирает" % suit_symbol, Trick.JokerMode.NORMAL_CARD_WINS, Trick.ForcedCardRank.LOWEST]
	]
	for condition_data in conditions:
		var mode: Trick.JokerMode = condition_data[1]
		var forced_rank: Trick.ForcedCardRank = condition_data[2]
		network_table_action_controls.add_child(_create_network_table_action_button(str(condition_data[0]), _on_submit_loopback_test_joker_pressed.bind(mode, loopback_network_pending_joker_suit, forced_rank)))
	network_table_action_controls.add_child(_create_network_table_action_button("Выбрать другую масть", _on_clear_loopback_test_joker_suit_pressed))
	network_table_action_controls.add_child(_create_network_table_action_button("Отменить выбор", _on_cancel_loopback_test_joker_selection_pressed))


func _create_network_table_action_button(label_text: String, callback: Callable, is_primary: bool = false) -> Button:
	var button := Button.new()
	button.text = label_text
	button.custom_minimum_size = Vector2(0.0, 32.0)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_table_action_button_style(button)
	if is_primary:
		button.add_theme_stylebox_override("normal", _create_flat_style(Color(0.16, 0.22, 0.1, 1.0), Color(0.95, 0.75, 0.28, 1.0), 2, 6, 3))
	button.pressed.connect(callback)
	return button


func _is_network_table_card_available_in_any_hand(snapshot: Dictionary) -> bool:
	var private_hand: Array = snapshot.get("private_hand", [])
	for card_data_variant in private_hand:
		if card_data_variant is Dictionary:
			var card_data: Dictionary = card_data_variant
			if _is_network_table_card_available(str(card_data.get("card_key", ""))):
				return true
	return false


func _get_network_table_active_player_index(round_data: Dictionary, active_trick: Dictionary) -> int:
	var state: int = int(round_data.get("state", -1))
	if state == Round.State.BIDDING:
		return int(round_data.get("current_player_index", -1))
	if state == Round.State.PLAYING:
		if not active_trick.is_empty():
			return int(active_trick.get("current_player_index", -1))
		return int(round_data.get("lead_player_index", -1))
	return -1


func _get_network_table_joker_text(trick_data: Dictionary) -> String:
	var played_cards: Array = trick_data.get("played_cards", [])
	if played_cards.is_empty() or not (played_cards[0] is Dictionary):
		return ""
	var first_card_data: Dictionary = played_cards[0]
	if not bool(first_card_data.get("is_joker", false)):
		return ""
	var joker_mode: Trick.JokerMode = int(trick_data.get("joker_mode", Trick.JokerMode.NORMAL_CARD_WINS))
	var forced_card_rank: Trick.ForcedCardRank = int(trick_data.get("forced_card_rank", Trick.ForcedCardRank.NONE))
	return _get_joker_declaration_text(
		joker_mode,
		int(trick_data.get("declared_suit", -1)),
		forced_card_rank
	)


func _get_network_table_result_text(snapshot: Dictionary, include_completion_heading: bool = false) -> String:
	if _is_network_full_game_complete(snapshot):
		var final_lines := PackedStringArray()
		if include_completion_heading:
			final_lines.append("Партия завершена")
		final_lines.append_array(_get_network_final_result_lines(snapshot))
		return "\n".join(final_lines)

	var result_lines: PackedStringArray = []
	if include_completion_heading:
		result_lines.append("Раздача завершена")
	var round_data: Dictionary = snapshot.get("round", {})
	var completed_round := _get_completed_round_data(snapshot.get("completed_rounds", []), int(round_data.get("number", 0)))
	var uses_bids := bool(completed_round.get("uses_bids", true))
	var completed_player_results: Array = completed_round.get("players", [])
	var players_data: Array = snapshot.get("players", [])
	for player_data_variant in players_data:
		if not (player_data_variant is Dictionary):
			continue
		var player_data: Dictionary = player_data_variant
		var player_index := int(player_data.get("player_index", -1))
		var bid: int = int(player_data.get("bid", -1))
		var tricks_taken := int(player_data.get("tricks_taken", 0))
		var total_score := int(player_data.get("total_score", 0))
		var round_score := _get_completed_player_round_score(completed_player_results, player_index)
		result_lines.append("%s: взято %d · %s · %s · счёт %d → %d" % [
			str(player_data.get("display_name", "Игрок")),
			tricks_taken,
			_get_round_order_outcome_text(bid, tricks_taken, uses_bids),
			_format_score(round_score),
			total_score - round_score,
			total_score
		])
	return "\n".join(result_lines)


func _get_network_table_result_bbcode(snapshot: Dictionary) -> String:
	if _is_network_full_game_complete(snapshot):
		return _format_final_standings_bbcode(_get_network_final_standings(snapshot))

	var result_lines: PackedStringArray = []
	var round_data: Dictionary = snapshot.get("round", {})
	var completed_round := _get_completed_round_data(snapshot.get("completed_rounds", []), int(round_data.get("number", 0)))
	var uses_bids := bool(completed_round.get("uses_bids", true))
	var completed_player_results: Array = completed_round.get("players", [])
	for player_data_variant in snapshot.get("players", []):
		if not (player_data_variant is Dictionary):
			continue
		var player_data: Dictionary = player_data_variant
		var player_index := int(player_data.get("player_index", -1))
		var bid := int(player_data.get("bid", -1))
		var tricks_taken := int(player_data.get("tricks_taken", 0))
		var total_score := int(player_data.get("total_score", 0))
		var round_score := _get_completed_player_round_score(completed_player_results, player_index)
		result_lines.append(_format_round_result_bbcode(
			str(player_data.get("display_name", "Игрок")),
			bid,
			tricks_taken,
			round_score,
			total_score,
			uses_bids
		))
	return "\n".join(result_lines)


func _format_final_standings_bbcode(standings: Array[Dictionary]) -> String:
	var final_lines := PackedStringArray()
	for standing in standings:
		var place := int(standing.get("place", 0))
		var shares_place := bool(standing.get("shares_place", false))
		var prefix := "🏆" if place == 1 and not shares_place else "🤝" if shares_place else "•"
		var safe_name := str(standing.get("name", "Игрок")).replace("[", "(").replace("]", ")")
		final_lines.append(
			(
				"[center][font_size=19][b][color=#ffd86a]%s %s · %s[/color][/b][/font_size]"
				+ "  [color=#d7e3d7]счёт[/color] [font_size=21][b][color=#ffffff]%d[/color][/b][/font_size]"
				+ "  [color=#708c77]•[/color] [color=#d7e3d7]всего взяток[/color] [b]%d[/b]"
				+ "  [color=#708c77]•[/color] [color=#d7e3d7]точных заказов[/color] [b]%d[/b][/center]"
			) % [
				prefix,
				_get_place_text(place, shares_place),
				safe_name,
				int(standing.get("score", 0)),
				int(standing.get("tricks_taken", 0)),
				int(standing.get("exact_orders", 0))
			]
		)
	return "\n".join(final_lines)


func _is_network_full_game_complete(snapshot: Dictionary) -> bool:
	var completed_rounds: Variant = snapshot.get("completed_rounds", [])
	return completed_rounds is Array and (completed_rounds as Array).size() >= TOTAL_ROUND_COUNT


func _get_network_final_result_lines(snapshot: Dictionary) -> PackedStringArray:
	var result_lines := PackedStringArray()
	for standing in _get_network_final_standings(snapshot):
		var place := int(standing.get("place", 0))
		var shares_place := bool(standing.get("shares_place", false))
		var prefix := "🏆" if place == 1 and not shares_place else "🤝" if shares_place else "•"
		result_lines.append("%s %s · %s — %d очк. · всего %d вз. · точных заказов: %d" % [
			prefix,
			_get_place_text(place, shares_place),
			str(standing.get("name", "Игрок")),
			int(standing.get("score", 0)),
			int(standing.get("tricks_taken", 0)),
			int(standing.get("exact_orders", 0))
		])
	return result_lines


func _get_network_final_standings(snapshot: Dictionary) -> Array[Dictionary]:
	var total_tricks_by_player: Dictionary = {}
	for completed_round_variant in snapshot.get("completed_rounds", []):
		if not (completed_round_variant is Dictionary):
			continue
		var player_results: Array = (completed_round_variant as Dictionary).get("players", [])
		for player_index in player_results.size():
			if player_results[player_index] is Dictionary:
				total_tricks_by_player[player_index] = (
					int(total_tricks_by_player.get(player_index, 0))
					+ int((player_results[player_index] as Dictionary).get("tricks_taken", 0))
				)

	var standings: Array[Dictionary] = []
	for player_data_variant in snapshot.get("players", []):
		if not (player_data_variant is Dictionary):
			continue
		var player_data: Dictionary = player_data_variant
		var player_index := int(player_data.get("player_index", -1))
		standings.append({
			"player_id": player_index,
			"name": str(player_data.get("display_name", "Игрок")),
			"score": int(player_data.get("total_score", 0)),
			"tricks_taken": int(total_tricks_by_player.get(player_index, 0)),
			"exact_orders": int(player_data.get("exact_orders_completed", 0)),
			"place": 0,
			"shares_place": false
		})

	standings.sort_custom(func(left: Dictionary, right: Dictionary) -> bool:
		if int(left.get("score", 0)) != int(right.get("score", 0)):
			return int(left.get("score", 0)) > int(right.get("score", 0))
		return int(left.get("exact_orders", 0)) > int(right.get("exact_orders", 0))
	)
	var place := 1
	for standing_index in standings.size():
		var standing: Dictionary = standings[standing_index]
		if standing_index > 0 and not _are_standings_equal(standing, standings[standing_index - 1]):
			place = standing_index + 1
		var shares_place := (
			(standing_index > 0 and _are_standings_equal(standing, standings[standing_index - 1]))
			or (
				standing_index < standings.size() - 1
				and _are_standings_equal(standing, standings[standing_index + 1])
			)
		)
		standing["place"] = place
		standing["shares_place"] = shares_place
	return standings


func _get_completed_round_data(completed_rounds_variant: Variant, round_number: int) -> Dictionary:
	if not (completed_rounds_variant is Array):
		return {}
	for completed_round_variant in completed_rounds_variant:
		if completed_round_variant is Dictionary and int(completed_round_variant.get("round_number", -1)) == round_number:
			return completed_round_variant
	return {}


func _get_completed_player_round_score(player_results: Array, player_index: int) -> int:
	if player_index >= 0 and player_index < player_results.size() and player_results[player_index] is Dictionary:
		return int((player_results[player_index] as Dictionary).get("round_score", 0))
	return 0


func _get_round_order_outcome_text(bid: int, tricks_taken: int, uses_bids: bool) -> String:
	if not uses_bids or bid < 0:
		return "без заказа"
	var difference := tricks_taken - bid
	if difference == 0:
		return "заказ %d выполнен" % bid
	if difference < 0:
		return "недобор %d (заказ %d)" % [-difference, bid]
	return "перебор %d (заказ %d)" % [difference, bid]


func _format_round_result_bbcode(
	player_name: String,
	bid: int,
	tricks_taken: int,
	round_score: int,
	total_score: int,
	uses_bids: bool
) -> String:
	var outcome_text := _get_round_order_outcome_text(bid, tricks_taken, uses_bids)
	var order_is_exact := uses_bids and bid >= 0 and bid == tricks_taken
	var outcome_color := "#65e686" if order_is_exact else "#ff6b61" if uses_bids and bid >= 0 else "#d8c77c"
	var score_color := "#65e686" if round_score > 0 else "#ff6b61" if round_score < 0 else "#d8c77c"
	var previous_total := total_score - round_score
	var safe_player_name := player_name.replace("[", "(").replace("]", ")")
	return (
		"[center][font_size=18][b][color=#ffffff]%s[/color][/b][/font_size]"
		+ "  [color=#c9d8ca]взято[/color] [font_size=20][b][color=#ffffff]%d[/color][/b][/font_size]"
		+ "  [color=#6f8d77]•[/color] [b][color=%s]%s[/color][/b]"
		+ "  [color=#6f8d77]•[/color] [b][color=%s]%s[/color][/b]"
		+ "  [color=#c9d8ca]счёт %d → [b]%d[/b][/color][/center]"
	) % [
		safe_player_name,
		tricks_taken,
		outcome_color,
		outcome_text,
		score_color,
		_format_score(round_score),
		previous_total,
		total_score
	]


func _create_network_table_card(card_data: Dictionary) -> Card:
	if card_data.is_empty():
		return null
	var card := Card.new()
	card.suit = int(card_data.get("suit", Card.Suit.CLUBS))
	card.rank = int(card_data.get("rank", Card.Rank.SIX))
	card.is_joker = bool(card_data.get("is_joker", false))
	return card


func _clear_network_table_trick_cards() -> void:
	if not is_instance_valid(network_table_trick_layer):
		return
	for child in network_table_trick_layer.get_children():
		child.queue_free()


func _refresh_loopback_network_action_controls() -> void:
	if not is_instance_valid(loopback_network_action_controls) or loopback_network_test == null:
		return

	_clear_children(loopback_network_action_controls)
	if loopback_network_joker_selection_open:
		_refresh_loopback_network_joker_selection_controls()
		return

	var available_bids: Array[int] = []
	var available_cards: Array[Dictionary] = []
	var can_submit_joker := false
	var title_text := ""
	if loopback_network_test.is_client() and loopback_network_test.can_submit_test_bid():
		available_bids = loopback_network_test.get_available_test_bids()
		title_text = "Твой тестовый заказ"
	elif loopback_network_test.is_host() and loopback_network_test.can_submit_host_test_bid():
		available_bids = loopback_network_test.get_available_host_test_bids()
		title_text = "Заказ хоста (место 1)"
	else:
		if loopback_network_test.is_client():
			if loopback_network_test.can_submit_test_card():
				available_cards = loopback_network_test.get_available_test_cards()
			can_submit_joker = loopback_network_test.can_submit_test_joker()
			title_text = "Твой тестовый ход"
		elif loopback_network_test.is_host():
			if loopback_network_test.can_submit_host_test_card():
				available_cards = loopback_network_test.get_available_host_test_cards()
			can_submit_joker = loopback_network_test.can_submit_host_test_joker()
			title_text = "Ход хоста (место 1)"
	if available_bids.is_empty() and available_cards.is_empty() and not can_submit_joker:
		return

	var title := Label.new()
	title.text = title_text
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(0.85, 0.91, 0.8, 1.0))
	loopback_network_action_controls.add_child(title)

	var action_row := HBoxContainer.new()
	action_row.alignment = BoxContainer.ALIGNMENT_CENTER
	action_row.add_theme_constant_override("separation", 8)
	loopback_network_action_controls.add_child(action_row)
	for bid in available_bids:
		var button := _create_menu_button("Заказать %d" % bid, _on_submit_loopback_test_bid_pressed.bind(bid), true)
		action_row.add_child(button)
	for card_data in available_cards:
		var card_key := str(card_data.get("card_key", ""))
		var card_name := str(card_data.get("label", "карта"))
		var button := _create_menu_button("Сыграть %s" % card_name, _on_submit_loopback_test_card_pressed.bind(card_key), true)
		action_row.add_child(button)
	if can_submit_joker:
		var joker_button := _create_menu_button("Сыграть Джокером", _on_open_loopback_test_joker_selection_pressed, true)
		action_row.add_child(joker_button)


func _refresh_loopback_network_joker_selection_controls() -> void:
	if not _can_submit_loopback_test_joker():
		_reset_loopback_network_joker_selection()
		return

	var title := Label.new()
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(1.0, 0.84, 0.38, 1.0))
	loopback_network_action_controls.add_child(title)

	if not _is_loopback_test_joker_leading():
		title.text = "Джокер: выбери вариант"
		var response_row := HBoxContainer.new()
		response_row.alignment = BoxContainer.ALIGNMENT_CENTER
		response_row.add_theme_constant_override("separation", 8)
		loopback_network_action_controls.add_child(response_row)
		response_row.add_child(_create_menu_button("Джокер забирает", _on_submit_loopback_test_joker_pressed.bind(Trick.JokerMode.JOKER_WINS), true))
		response_row.add_child(_create_menu_button("Сбросить Джокер", _on_submit_loopback_test_joker_pressed.bind(Trick.JokerMode.NORMAL_CARD_WINS), true))
		_add_loopback_test_joker_cancel_button()
		return

	if loopback_network_pending_joker_suit < Card.Suit.CLUBS:
		title.text = "Джокер: объяви масть"
		var suit_row := HBoxContainer.new()
		suit_row.alignment = BoxContainer.ALIGNMENT_CENTER
		suit_row.add_theme_constant_override("separation", 8)
		loopback_network_action_controls.add_child(suit_row)
		for suit in [Card.Suit.CLUBS, Card.Suit.SPADES, Card.Suit.HEARTS, Card.Suit.DIAMONDS]:
			suit_row.add_child(_create_menu_button("Объявить %s" % _get_suit_symbol(suit), _on_choose_loopback_test_joker_suit_pressed.bind(suit), true))
		_add_loopback_test_joker_cancel_button()
		return

	var suit_symbol := _get_suit_symbol(loopback_network_pending_joker_suit)
	title.text = "Джокер: выбери условие для %s" % suit_symbol
	var condition_rows := [
		[
			"%s: Джокер забирает" % suit_symbol,
			Trick.JokerMode.JOKER_WINS,
			Trick.ForcedCardRank.NONE
		],
		[
			"%s: старшая забирает" % suit_symbol,
			Trick.JokerMode.HIGHEST_DECLARED_CARD_WINS,
			Trick.ForcedCardRank.NONE
		],
		[
			"%s: младшая забирает" % suit_symbol,
			Trick.JokerMode.LOWEST_DECLARED_CARD_WINS,
			Trick.ForcedCardRank.NONE
		],
		[
			"%s: кладите старшую — Джокер забирает" % suit_symbol,
			Trick.JokerMode.JOKER_WINS,
			Trick.ForcedCardRank.HIGHEST
		],
		[
			"%s: кладите младшую — Джокер забирает" % suit_symbol,
			Trick.JokerMode.JOKER_WINS,
			Trick.ForcedCardRank.LOWEST
		],
		[
			"%s: кладите старшую — Джокер не забирает" % suit_symbol,
			Trick.JokerMode.NORMAL_CARD_WINS,
			Trick.ForcedCardRank.HIGHEST
		],
		[
			"%s: кладите младшую — Джокер не забирает" % suit_symbol,
			Trick.JokerMode.NORMAL_CARD_WINS,
			Trick.ForcedCardRank.LOWEST
		]
	]
	for condition_data in condition_rows:
		var condition_button := _create_menu_button(
			str(condition_data[0]),
			_on_submit_loopback_test_joker_pressed.bind(condition_data[1], loopback_network_pending_joker_suit, condition_data[2]),
			true
		)
		loopback_network_action_controls.add_child(condition_button)
	loopback_network_action_controls.add_child(_create_menu_button("← Выбрать другую масть", _on_clear_loopback_test_joker_suit_pressed, true))
	_add_loopback_test_joker_cancel_button()


func _on_clear_loopback_test_joker_suit_pressed() -> void:
	loopback_network_pending_joker_suit = -1
	_refresh_loopback_network_status()
	_refresh_steam_p2p_status()


func _add_loopback_test_joker_cancel_button() -> void:
	loopback_network_action_controls.add_child(_create_menu_button("Отменить выбор Джокера", _on_cancel_loopback_test_joker_selection_pressed, true))


func _can_submit_loopback_test_joker() -> bool:
	var network_match = _get_active_network_match()
	if network_match == null:
		return false
	return network_match.can_submit_host_test_joker() if network_match.is_host() else network_match.can_submit_test_joker()


func _is_loopback_test_joker_leading() -> bool:
	var network_match = _get_active_network_match()
	if network_match == null:
		return false
	return network_match.is_host_test_joker_leading() if network_match.is_host() else network_match.is_client_test_joker_leading()


func _reset_loopback_network_joker_selection() -> void:
	loopback_network_joker_selection_open = false
	loopback_network_pending_joker_suit = -1


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
	_add_new_game_history_mode_row()
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


func _add_new_game_history_mode_row() -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	menu_content.add_child(row)

	var label := Label.new()
	label.text = "История"
	label.custom_minimum_size = Vector2(160.0, 38.0)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color(0.91, 0.96, 0.91, 1.0))
	row.add_child(label)

	new_game_history_mode_selector = OptionButton.new()
	new_game_history_mode_selector.name = "NewGameHistoryModeSelector"
	new_game_history_mode_selector.custom_minimum_size = Vector2(0.0, 38.0)
	new_game_history_mode_selector.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	new_game_history_mode_selector.add_theme_font_size_override("font_size", 16)
	new_game_history_mode_selector.add_item(_get_history_mode_label(NetworkHost.HistoryMode.FULL))
	new_game_history_mode_selector.add_item(_get_history_mode_label(NetworkHost.HistoryMode.LAST_TRICK_ONLY))
	new_game_history_mode_selector.selected = match_history_mode
	row.add_child(new_game_history_mode_selector)
	_add_menu_label("В ограниченном режиме журнал показывает только последнюю завершённую взятку и карты текущей взятки.", 14, Color(0.72, 0.85, 0.76, 1.0))


func _start_configured_new_game() -> void:
	for player_index in PLAYER_NAMES.size():
		configured_player_names[player_index] = _sanitize_player_name(new_game_name_inputs[player_index].text, str(PLAYER_NAMES[player_index]))
		var max_avatar_index := CUSTOM_AVATAR_INDEX if player_index == HUMAN_PLAYER_INDEX else BUILT_IN_AVATAR_COUNT - 1
		configured_avatar_indices[player_index] = clampi(new_game_avatar_selectors[player_index].selected, 0, max_avatar_index)

	bot_difficulty = clampi(new_game_bot_difficulty_selector.selected, 0, BOT_DIFFICULTY_COUNT - 1)
	match_history_mode = clampi(
		new_game_history_mode_selector.selected,
		NetworkHost.HistoryMode.FULL,
		NetworkHost.HistoryMode.LAST_TRICK_ONLY
	)
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


func _get_history_mode_label(history_mode: int) -> String:
	return "Только последняя взятка" if history_mode == NetworkHost.HistoryMode.LAST_TRICK_ONLY else "Полная история"


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

	var avatar_row := HBoxContainer.new()
	avatar_row.add_theme_constant_override("separation", 14)
	menu_content.add_child(avatar_row)

	profile_avatar_selector = OptionButton.new()
	profile_avatar_selector.custom_minimum_size = Vector2(0.0, 42.0)
	profile_avatar_selector.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	profile_avatar_selector.add_theme_font_size_override("font_size", 17)
	for avatar_index in HUMAN_AVATAR_COUNT:
		profile_avatar_selector.add_item(_get_avatar_option_label(avatar_index))
	profile_avatar_selector.selected = clampi(configured_avatar_indices[HUMAN_PLAYER_INDEX], 0, CUSTOM_AVATAR_INDEX)
	profile_avatar_selector.item_selected.connect(_on_profile_avatar_selected)
	avatar_row.add_child(profile_avatar_selector)

	var preview_panel := PanelContainer.new()
	preview_panel.custom_minimum_size = Vector2(96.0, 96.0)
	preview_panel.add_theme_stylebox_override(
		"panel",
		_create_flat_style(Color(0.028, 0.073, 0.052, 1.0), Color(0.75, 0.58, 0.2, 1.0), 2, 8, 2)
	)
	avatar_row.add_child(preview_panel)

	var preview_content := Control.new()
	preview_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview_panel.add_child(preview_content)

	profile_avatar_preview = TextureRect.new()
	profile_avatar_preview.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	profile_avatar_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	profile_avatar_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	profile_avatar_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview_content.add_child(profile_avatar_preview)

	profile_avatar_preview_placeholder = Label.new()
	profile_avatar_preview_placeholder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	profile_avatar_preview_placeholder.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	profile_avatar_preview_placeholder.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	profile_avatar_preview_placeholder.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	profile_avatar_preview_placeholder.add_theme_font_size_override("font_size", 14)
	profile_avatar_preview_placeholder.add_theme_color_override("font_color", Color(0.82, 0.9, 0.82, 1.0))
	profile_avatar_preview_placeholder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview_content.add_child(profile_avatar_preview_placeholder)

	profile_avatar_status_label = Label.new()
	profile_avatar_status_label.add_theme_font_size_override("font_size", 14)
	profile_avatar_status_label.add_theme_color_override("font_color", Color(0.72, 0.85, 0.76, 1.0))
	profile_avatar_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	menu_content.add_child(profile_avatar_status_label)
	_update_profile_avatar_status()
	_update_profile_avatar_preview()

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
	if steam_p2p_match != null and steam_p2p_match.is_running():
		network_avatar_texture_cache.clear()
		steam_p2p_match.update_local_profile(
			configured_player_names[HUMAN_PLAYER_INDEX],
			configured_avatar_indices[HUMAN_PLAYER_INDEX],
			_get_local_network_avatar_data()
		)

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
	profile_avatar_file_dialog.use_native_dialog = true
	profile_avatar_file_dialog.display_mode = FileDialog.DISPLAY_THUMBNAILS
	profile_avatar_file_dialog.add_theme_constant_override("thumbnail_size", 128)
	profile_avatar_file_dialog.filters = PackedStringArray(["*.png,*.jpg,*.jpeg,*.webp;Изображения"])
	profile_avatar_file_dialog.file_selected.connect(_on_profile_avatar_file_selected)
	add_child(profile_avatar_file_dialog)


func _create_bug_report_file_dialog() -> void:
	bug_report_file_dialog = FileDialog.new()
	bug_report_file_dialog.name = "BugReportFileDialog"
	bug_report_file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	bug_report_file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	bug_report_file_dialog.use_native_dialog = true
	bug_report_file_dialog.filters = PackedStringArray(["*.%s;Отчёт Project Joker" % BUG_REPORT_FILE_EXTENSION])
	bug_report_file_dialog.file_selected.connect(_on_bug_report_file_selected)
	add_child(bug_report_file_dialog)


func _open_bug_report_file_dialog() -> void:
	if is_bug_report_review_mode:
		return

	if bug_report_file_dialog != null:
		bug_report_file_dialog.popup_centered_ratio(0.75)


func _on_bug_report_file_selected(report_path: String) -> void:
	if _load_bug_report_from_path(report_path):
		is_pause_menu_open = false
		_hide_main_menu()
		_refresh_ui()
		return

	_build_main_menu_content()


func _on_save_bug_report_pressed() -> void:
	if game.current_round.state == Round.State.SETUP:
		if is_instance_valid(bug_report_status_label):
			bug_report_status_label.text = "Сначала начни или продолжи партию."
		return

	var report_directory := _ensure_bug_report_directory()
	if report_directory.is_empty():
		if is_instance_valid(bug_report_status_label):
			bug_report_status_label.text = "Не удалось создать папку для отчётов."
		return

	var description := ""
	if is_instance_valid(bug_report_description_input):
		description = bug_report_description_input.text.strip_edges()

	var timestamp := Time.get_datetime_string_from_system(false, true).replace(":", "-").replace(" ", "_")
	var report_file_name := "ProjectJoker_report_%s.%s" % [timestamp, BUG_REPORT_FILE_EXTENSION]
	var report_path := report_directory.path_join(report_file_name)
	var report_file := FileAccess.open(report_path, FileAccess.WRITE)
	if report_file == null:
		if is_instance_valid(bug_report_status_label):
			bug_report_status_label.text = "Не удалось сохранить файл отчёта."
		return

	var report_data := {
		"format": "project_joker_bug_report",
		"report_version": BUG_REPORT_FORMAT_VERSION,
		"game_version": GAME_VERSION,
		"created_at": Time.get_datetime_string_from_system(false, true),
		"description": description,
		"timeline": bug_report_timeline.duplicate(true),
		"session": _create_session_save_data()
	}
	report_file.store_var(report_data, false)
	_save_bug_report_summary(report_directory, timestamp, description)

	if is_instance_valid(bug_report_status_label):
		bug_report_status_label.text = "Отчёт сохранён: %s\nОтправь разработчику файл .%s и, если можешь, скриншот." % [report_file_name, BUG_REPORT_FILE_EXTENSION]


func _ensure_bug_report_directory() -> String:
	var report_directory := ProjectSettings.globalize_path(BUG_REPORT_DIRECTORY_PATH)
	if DirAccess.make_dir_recursive_absolute(report_directory) != OK:
		return ""

	return report_directory


func _open_bug_report_folder() -> void:
	var report_directory := _ensure_bug_report_directory()
	if report_directory.is_empty():
		if is_instance_valid(bug_report_status_label):
			bug_report_status_label.text = "Не удалось открыть папку отчётов."
		return

	OS.shell_open(report_directory)


func _save_bug_report_summary(report_directory: String, timestamp: String, description: String) -> void:
	var summary_path := report_directory.path_join("ProjectJoker_report_%s.txt" % timestamp)
	var summary_file := FileAccess.open(summary_path, FileAccess.WRITE)
	if summary_file == null:
		return

	var phase_text := phase_label.text if is_instance_valid(phase_label) else "—"
	var trump_text := trump_label.text if is_instance_valid(trump_label) else "—"
	var summary_lines := PackedStringArray([
		"Project Joker · отчёт об ошибке",
		"Версия игры: %s" % GAME_VERSION,
		"Создан: %s" % Time.get_datetime_string_from_system(false, true),
		"Этап: %s" % phase_text,
		"Козырь: %s" % trump_text,
		"Описание: %s" % (description if not description.is_empty() else "не указано"),
		"",
		"Последние действия:",
		"\n".join(recent_actions)
	])
	summary_file.store_string("\n".join(summary_lines))


func _capture_bug_report_timeline(label: String) -> void:
	if is_bug_report_review_mode or game.current_round.state == Round.State.SETUP:
		return

	bug_report_timeline.append({
		"label": label,
		"session": _create_session_save_data()
	})
	while bug_report_timeline.size() > BUG_REPORT_TIMELINE_LIMIT:
		bug_report_timeline.remove_at(0)


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
	_update_profile_avatar_preview()


func _on_profile_avatar_selected(selected_index: int) -> void:
	if selected_index != CUSTOM_AVATAR_INDEX:
		pending_profile_avatar_path = ""
	_update_profile_avatar_status()
	_update_profile_avatar_preview()


func _on_reset_profile_avatar_pressed() -> void:
	pending_profile_avatar_path = ""
	if is_instance_valid(profile_avatar_selector):
		profile_avatar_selector.select(0)
	_update_profile_avatar_status()
	_update_profile_avatar_preview()


func _update_profile_avatar_status() -> void:
	if not is_instance_valid(profile_avatar_status_label):
		return

	if not pending_profile_avatar_path.is_empty():
		profile_avatar_status_label.text = "Личная картинка готова. Нажми «Сохранить профиль», чтобы применить её."
	elif is_instance_valid(profile_avatar_selector) and profile_avatar_selector.selected == CUSTOM_AVATAR_INDEX:
		profile_avatar_status_label.text = "Сначала выбери файл PNG, JPG или WebP."
	else:
		profile_avatar_status_label.text = "Используется один из встроенных авторских аватаров."


func _update_profile_avatar_preview() -> void:
	if (
		not is_instance_valid(profile_avatar_preview)
		or not profile_avatar_preview.is_inside_tree()
		or not is_instance_valid(profile_avatar_preview_placeholder)
	):
		return

	var selected_avatar_index := 0
	if is_instance_valid(profile_avatar_selector):
		selected_avatar_index = clampi(profile_avatar_selector.selected, 0, CUSTOM_AVATAR_INDEX)

	var preview_path := _get_avatar_texture_path_for_index(selected_avatar_index, pending_profile_avatar_path)
	var preview_texture := _load_avatar_texture_from_path(preview_path)
	profile_avatar_preview.texture = preview_texture
	profile_avatar_preview_placeholder.visible = preview_texture == null
	profile_avatar_preview_placeholder.text = "Выбери\nкартинку" if selected_avatar_index == CUSTOM_AVATAR_INDEX else "Аватар\nне найден"


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
	_add_menu_label("Подсчёт очков", 19, Color(0.97, 0.86, 0.55, 1.0))
	_add_menu_label("• Обычная: точный заказ больше 0 — +10 × заказ; недобор — −10 × недобор; перебор — +1 × лишняя взятка; 0/0 — +5.", 15)
	_add_menu_label("• Тёмная: точный заказ больше 0 — +15 × заказ; недобор — −10 × недобор; перебор — +1 × лишняя взятка; 0/0 — +50.", 15)
	_add_menu_label("• Бескозырка: точный заказ больше 0 — +15 × заказ; недобор — −10 × недобор; перебор — +1 × лишняя взятка; 0/0 — +5.", 15)
	_add_menu_label("• Золотая: заказов нет; ноль взяток — −50, иначе +20 за каждую взятку.", 15)
	_add_menu_label("• Мизерная: заказов нет; ноль взяток — +50, иначе −20 за каждую взятку.", 15)
	_add_menu_label("• Важно: при недоборе или переборе очки не складываются с наградой за точный заказ. Например, заказ 2 и взято 3 — это +1, а не +21.", 15, Color(0.72, 0.85, 0.76, 1.0))
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

	var deck_style_label := Label.new()
	deck_style_label.text = "Оформление карт"
	deck_style_label.add_theme_font_size_override("font_size", 18)
	deck_style_label.add_theme_color_override("font_color", Color(0.91, 0.96, 0.91, 1.0))
	menu_content.add_child(deck_style_label)

	var deck_style_selector := OptionButton.new()
	deck_style_selector.add_item("Jumbo · четыре цвета")
	deck_style_selector.add_item("Классическая · четыре цвета")
	deck_style_selector.add_item("Компактная · четыре цвета")
	deck_style_selector.add_item("Jumbo · оригинальная (2 цвета)")
	deck_style_selector.add_item("Простая · первая версия")
	deck_style_selector.add_item("Классическая векторная · Full HD")
	deck_style_selector.selected = card_deck_style
	deck_style_selector.custom_minimum_size = Vector2(0.0, 42.0)
	deck_style_selector.add_theme_font_size_override("font_size", 17)
	deck_style_selector.item_selected.connect(_on_card_deck_style_selected)
	menu_content.add_child(deck_style_selector)

	var deck_style_hint := Label.new()
	deck_style_hint.text = "Выбор сохраняется только на этом устройстве и не меняет карты у других игроков."
	deck_style_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	deck_style_hint.add_theme_font_size_override("font_size", 14)
	deck_style_hint.add_theme_color_override("font_color", Color(0.72, 0.85, 0.76, 1.0))
	menu_content.add_child(deck_style_hint)

	var deck_preview_label := Label.new()
	deck_preview_label.text = "Предпросмотр"
	deck_preview_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	deck_preview_label.add_theme_font_size_override("font_size", 15)
	deck_preview_label.add_theme_color_override("font_color", Color(0.97, 0.86, 0.55, 1.0))
	menu_content.add_child(deck_preview_label)

	card_deck_preview_container = HBoxContainer.new()
	card_deck_preview_container.alignment = BoxContainer.ALIGNMENT_CENTER
	card_deck_preview_container.add_theme_constant_override("separation", 8)
	menu_content.add_child(card_deck_preview_container)
	_refresh_card_deck_preview()

	var table_theme_label := Label.new()
	table_theme_label.text = "Оформление стола"
	table_theme_label.add_theme_font_size_override("font_size", 18)
	table_theme_label.add_theme_color_override("font_color", Color(0.91, 0.96, 0.91, 1.0))
	menu_content.add_child(table_theme_label)

	var felt_selector := OptionButton.new()
	felt_selector.name = "TableFeltThemeSelector"
	for felt_name in TABLE_FELT_NAMES:
		felt_selector.add_item(felt_name)
	felt_selector.selected = table_felt_theme
	felt_selector.custom_minimum_size = Vector2(0.0, 42.0)
	felt_selector.add_theme_font_size_override("font_size", 17)
	felt_selector.item_selected.connect(_on_table_felt_theme_selected)
	menu_content.add_child(felt_selector)

	var surround_selector := OptionButton.new()
	surround_selector.name = "TableSurroundThemeSelector"
	for surround_name in TABLE_SURROUND_NAMES:
		surround_selector.add_item(surround_name)
	surround_selector.selected = table_surround_theme
	surround_selector.custom_minimum_size = Vector2(0.0, 42.0)
	surround_selector.add_theme_font_size_override("font_size", 17)
	surround_selector.item_selected.connect(_on_table_surround_theme_selected)
	menu_content.add_child(surround_selector)

	var table_theme_hint := Label.new()
	table_theme_hint.text = "Сукно и окружение видишь только ты. Выбор применяется сразу, сохраняется на этом устройстве и не меняет столы друзей."
	table_theme_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	table_theme_hint.add_theme_font_size_override("font_size", 14)
	table_theme_hint.add_theme_color_override("font_color", Color(0.72, 0.85, 0.76, 1.0))
	menu_content.add_child(table_theme_hint)

	table_theme_preview_surround = PanelContainer.new()
	table_theme_preview_surround.name = "TableThemePreview"
	table_theme_preview_surround.custom_minimum_size = Vector2(0.0, 126.0)
	menu_content.add_child(table_theme_preview_surround)
	var preview_margin := MarginContainer.new()
	preview_margin.add_theme_constant_override("margin_left", 28)
	preview_margin.add_theme_constant_override("margin_top", 20)
	preview_margin.add_theme_constant_override("margin_right", 28)
	preview_margin.add_theme_constant_override("margin_bottom", 20)
	table_theme_preview_surround.add_child(preview_margin)
	table_theme_preview_felt = Panel.new()
	table_theme_preview_felt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview_margin.add_child(table_theme_preview_felt)
	_refresh_table_theme_preview()

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
	auto_turn_toggle.text = "Автоход: 60 секунд"
	auto_turn_toggle.button_pressed = auto_turn_enabled
	auto_turn_toggle.add_theme_font_size_override("font_size", 18)
	auto_turn_toggle.add_theme_color_override("font_color", Color(0.91, 0.96, 0.91, 1.0))
	auto_turn_toggle.toggled.connect(_on_auto_turn_toggled)
	menu_content.add_child(auto_turn_toggle)
	_add_menu_label("После 2 минут бездействия автоход включится сам и останется активным на следующих ходах. Отключить его можно здесь вручную. В сетевой партии персональные таймеры контролирует хост.", 14, Color(0.72, 0.85, 0.76, 1.0))

	_add_menu_button("Начать обучение заново", _on_tutorial_enable_pressed)
	_add_menu_label("Подсказки не мешают игре и всегда доступны из настроек или меню паузы.", 14, Color(0.72, 0.85, 0.76, 1.0))
	_add_menu_spacer(8.0)
	_add_menu_button("Назад", _return_from_menu_subpage)


func _show_final_session_menu() -> void:
	is_pause_menu_open = false
	menu_overlay.visible = true
	_clear_children(menu_content)
	_add_menu_title("Партия завершена", "Поздравляем — полный цикл из 32 раздач сыгран")
	_add_menu_label(_get_human_final_summary_text(), 18, Color(0.97, 0.86, 0.55, 1.0))
	_add_menu_label(_get_final_results_text(), 16, Color(0.91, 0.96, 0.91, 1.0))
	_add_menu_spacer(10.0)
	_add_menu_button("Открыть статистику", Callable(self, "_show_statistics_menu").bind(true))
	_add_menu_button("Сыграть ещё раз", _on_new_game_pressed, true)
	_add_menu_button("Вернуться в меню", _on_return_to_menu_pressed)


func _show_statistics_menu(return_to_final_menu := false) -> void:
	statistics_return_to_final_menu = return_to_final_menu
	_clear_children(menu_content)
	_add_menu_title("Статистика", "Результаты полностью завершённых локальных партий")

	var completed_games: int = int(local_statistics["completed_games"])
	if completed_games <= 0:
		_add_menu_label("Пока нет завершённых партий. Статистика появится после полного цикла из 32 раздач.", 16, Color(0.72, 0.85, 0.76, 1.0))
	else:
		var wins: int = int(local_statistics["wins"])
		var win_rate := int(round(float(wins) * 100.0 / float(completed_games)))
		_add_menu_label("Сыграно партий: %d" % completed_games, 20, Color(0.97, 0.86, 0.55, 1.0))
		_add_menu_label("Победы: %d (%d%%)" % [wins, win_rate], 18)
		_add_menu_label("Места: 2-е — %d · 3-е — %d · 4-е — %d" % [
			int(local_statistics["second_places"]),
			int(local_statistics["third_places"]),
			int(local_statistics["fourth_places"])
		], 16, Color(0.72, 0.85, 0.76, 1.0))

		if bool(local_statistics["has_best_score"]):
			_add_menu_label("Лучший счёт: %d" % int(local_statistics["best_score"]), 18, Color(0.97, 0.86, 0.55, 1.0))

		_add_menu_spacer(10.0)
		_add_menu_label("Последняя партия", 18, Color(0.97, 0.86, 0.55, 1.0))
		var last_place: int = int(local_statistics["last_place"])
		var last_place_text := _get_place_text(last_place, bool(local_statistics["last_shared_place"]))
		_add_menu_label("%s · счёт %d · точных заказов: %d" % [
			last_place_text,
			int(local_statistics["last_score"]),
			int(local_statistics["last_exact_orders"])
		], 16, Color(0.91, 0.96, 0.91, 1.0))

	_add_menu_spacer(14.0)
	_add_menu_button("Назад", _return_from_statistics_menu, true)


func _return_from_statistics_menu() -> void:
	if statistics_return_to_final_menu:
		_show_final_session_menu()
		return

	_return_from_menu_subpage()


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


func _add_menu_button(label_text: String, callback: Callable, is_primary: bool = false) -> Button:
	var button := _create_menu_button(label_text, callback, is_primary)
	menu_content.add_child(button)
	return button


func _create_menu_button(label_text: String, callback: Callable, is_primary: bool = false) -> Button:
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
	return button


func _on_new_game_pressed() -> void:
	is_pause_menu_open = false
	_delete_saved_session()
	_reset_game_session()
	_hide_main_menu()
	_begin_local_first_turn_roll()


func _begin_local_first_turn_roll() -> void:
	local_first_turn_roll_random.randomize()
	local_first_turn_roll_active = true
	local_first_turn_roll_round = 0
	local_first_turn_roll_contenders.assign([0, 1, 2, 3])
	local_first_turn_roll_values.resize(PLAYER_NAMES.size())
	local_first_turn_roll_values.fill(-1)
	local_first_turn_roll_winner_index = -1
	local_first_turn_roll_generation += 1
	_refresh_ui()


func _on_first_turn_roll_action_pressed() -> void:
	if _is_steam_p2p_main_table_active():
		var network_match = _get_active_network_match()
		if network_match == null:
			return
		if network_match.can_start_first_real_round():
			if network_match.start_first_real_round():
				first_turn_roll_panel.visible = false
				_refresh_steam_p2p_status()
			return
		if network_match.can_submit_first_turn_roll():
			network_match.submit_first_turn_roll()
			_refresh_network_main_table()
		return

	if not local_first_turn_roll_active:
		return
	if local_first_turn_roll_winner_index >= 0:
		local_first_turn_roll_active = false
		first_turn_roll_panel.visible = false
		_start_round()
		return
	if local_first_turn_roll_contenders.has(HUMAN_PLAYER_INDEX):
		_perform_local_first_turn_roll()


func _perform_local_first_turn_roll() -> void:
	if not local_first_turn_roll_active or local_first_turn_roll_winner_index >= 0:
		return
	local_first_turn_roll_round += 1
	local_first_turn_roll_values.fill(-1)
	var highest_value := -1
	var leaders: Array[int] = []
	for player_index in local_first_turn_roll_contenders:
		var roll_value := local_first_turn_roll_random.randi_range(1, 6)
		local_first_turn_roll_values[player_index] = roll_value
		if roll_value > highest_value:
			highest_value = roll_value
			leaders.assign([player_index])
		elif roll_value == highest_value:
			leaders.append(player_index)

	if leaders.size() == 1:
		local_first_turn_roll_winner_index = leaders[0]
		game.dealer_index = posmod(local_first_turn_roll_winner_index - 1, game.players.size())
	else:
		local_first_turn_roll_contenders.assign(leaders)
		if not local_first_turn_roll_contenders.has(HUMAN_PLAYER_INDEX):
			var current_generation := local_first_turn_roll_generation
			call_deferred("_continue_local_bot_first_turn_roll", current_generation)
	_refresh_first_turn_roll_panel()


func _continue_local_bot_first_turn_roll(expected_generation: int) -> void:
	await get_tree().create_timer(FIRST_TURN_ROLL_BOT_REROLL_DELAY_SECONDS).timeout
	if (
		expected_generation == local_first_turn_roll_generation
		and local_first_turn_roll_active
		and local_first_turn_roll_winner_index < 0
		and not local_first_turn_roll_contenders.has(HUMAN_PLAYER_INDEX)
	):
		_perform_local_first_turn_roll()


func _refresh_first_turn_roll_panel(network_state: Dictionary = {}, network_seats: Array = []) -> void:
	var is_network_roll := not network_state.is_empty()
	if not is_network_roll and not local_first_turn_roll_active:
		first_turn_roll_panel.visible = false
		return

	first_turn_roll_panel.visible = true
	round_results_panel.visible = false
	next_round_button.visible = false
	_clear_children(first_turn_roll_grid)

	var roll_round := int(network_state.get("roll_round", 0)) if is_network_roll else local_first_turn_roll_round
	var phase := int(network_state.get("phase", LoopbackNetwork.FirstTurnRollPhase.WAITING)) if is_network_roll else (
		LoopbackNetwork.FirstTurnRollPhase.COMPLETE
		if local_first_turn_roll_winner_index >= 0
		else LoopbackNetwork.FirstTurnRollPhase.WAITING
	)
	var contenders: Array = network_state.get("contenders", []) if is_network_roll else local_first_turn_roll_contenders
	var values: Array = network_state.get("values", []) if is_network_roll else local_first_turn_roll_values
	var submitted: Array = network_state.get("submitted", []) if is_network_roll else []
	var winner_player_index := int(network_state.get("winner_player_index", -1)) if is_network_roll else local_first_turn_roll_winner_index
	var player_names := _get_first_turn_roll_player_names(network_seats if is_network_roll else [])

	first_turn_roll_title.text = "ПЕРЕБРОС ЛИДЕРОВ" if roll_round > 1 and winner_player_index < 0 else "РОЗЫГРЫШ ПЕРВОГО ХОДА"
	first_turn_roll_subtitle.text = "Победитель первым заказывает и начинает игру"
	for player_index in PLAYER_NAMES.size():
		var is_contender := contenders.has(player_index)
		var roll_value := int(values[player_index]) if player_index < values.size() else -1
		var has_submitted := bool(submitted[player_index]) if player_index < submitted.size() else roll_value > 0
		var is_winner := player_index == winner_player_index
		_add_first_turn_roll_player_slot(
			player_names[player_index],
			roll_value,
			is_contender,
			has_submitted,
			is_winner,
			phase
		)

	if winner_player_index >= 0:
		first_turn_roll_status.text = "%s выигрывает и будет первым заказывать и ходить" % player_names[winner_player_index]
	elif phase == LoopbackNetwork.FirstTurnRollPhase.REVEAL:
		first_turn_roll_status.text = "Ничья у лидеров — сейчас будет переброс"
	elif is_network_roll:
		var submitted_count := 0
		for player_index in contenders:
			if player_index < submitted.size() and bool(submitted[player_index]):
				submitted_count += 1
		first_turn_roll_status.text = "Кубики готовы: %d из %d · значения откроются одновременно" % [submitted_count, contenders.size()]
	elif roll_round > 0:
		first_turn_roll_status.text = "Ничья у лидеров — нужен переброс"
	else:
		first_turn_roll_status.text = "Все участники бросают кубики одновременно"

	if is_network_roll:
		var network_match = _get_active_network_match()
		if winner_player_index >= 0:
			first_turn_roll_button.text = "Начать первую раздачу" if network_match != null and network_match.is_host() else "Ждём запуска раздачи хостом"
			first_turn_roll_button.disabled = network_match == null or not network_match.can_start_first_real_round()
		elif phase == LoopbackNetwork.FirstTurnRollPhase.REVEAL:
			first_turn_roll_button.text = "Готовим переброс…"
			first_turn_roll_button.disabled = true
		elif network_match != null and not contenders.has(network_match.get_test_table_viewer_index()):
			first_turn_roll_button.text = "Перебрасывают лидеры · ждём"
			first_turn_roll_button.disabled = true
		elif network_match != null and network_match.can_submit_first_turn_roll():
			first_turn_roll_button.text = "Перебросить кубик" if roll_round > 1 else "Бросить кубик"
			first_turn_roll_button.disabled = false
		else:
			first_turn_roll_button.text = "Кубик брошен ✓ · ждём остальных"
			first_turn_roll_button.disabled = true
	elif winner_player_index >= 0:
		first_turn_roll_button.text = "Начать первую раздачу"
		first_turn_roll_button.disabled = false
	elif local_first_turn_roll_contenders.has(HUMAN_PLAYER_INDEX):
		first_turn_roll_button.text = "Перебросить кубик" if roll_round > 0 else "Бросить кубик"
		first_turn_roll_button.disabled = false
	else:
		first_turn_roll_button.text = "Боты перебрасывают кубики…"
		first_turn_roll_button.disabled = true


func _get_first_turn_roll_player_names(network_seats: Array) -> Array[String]:
	var player_names: Array[String] = []
	player_names.resize(PLAYER_NAMES.size())
	for player_index in PLAYER_NAMES.size():
		player_names[player_index] = game.players[player_index].display_name if player_index < game.players.size() else "Игрок %d" % (player_index + 1)
	for seat_variant in network_seats:
		if not (seat_variant is Dictionary):
			continue
		var seat: Dictionary = seat_variant
		var player_index := int(seat.get("player_index", -1))
		if player_index >= 0 and player_index < player_names.size():
			player_names[player_index] = str(seat.get("display_name", player_names[player_index]))
	return player_names


func _add_first_turn_roll_player_slot(
	player_name: String,
	roll_value: int,
	is_contender: bool,
	has_submitted: bool,
	is_winner: bool,
	phase: int
) -> void:
	var slot := PanelContainer.new()
	slot.custom_minimum_size = Vector2(150.0, 132.0)
	slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var border_color := Color(1.0, 0.79, 0.24, 1.0) if is_winner else Color(0.47, 0.34, 0.12, 0.9) if is_contender else Color(0.2, 0.24, 0.2, 0.72)
	var slot_style := _create_flat_style(
		Color(0.15, 0.13, 0.035, 0.98) if is_winner else Color(0.025, 0.105, 0.065, 0.98),
		border_color,
		3 if is_winner else 1,
		9,
		4 if is_winner else 1
	)
	slot_style.content_margin_left = 8.0
	slot_style.content_margin_top = 8.0
	slot_style.content_margin_right = 8.0
	slot_style.content_margin_bottom = 8.0
	slot.add_theme_stylebox_override("panel", slot_style)
	first_turn_roll_grid.add_child(slot)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 3)
	slot.add_child(content)
	var name_label := Label.new()
	name_label.text = player_name
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.52, 1.0) if is_winner else Color(0.9, 0.96, 0.9, 1.0))
	content.add_child(name_label)

	var dice_view = Dice3DViewResource.new()
	content.add_child(dice_view)
	dice_view.configure(roll_value, is_contender, has_submitted, is_winner)

	var state_label := Label.new()
	state_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	state_label.add_theme_font_size_override("font_size", 13)
	state_label.add_theme_color_override("font_color", Color(0.72, 0.83, 0.73, 1.0))
	if is_winner:
		state_label.text = "ПЕРВЫЙ ХОД"
	elif not is_contender:
		state_label.text = "вне переброса"
	elif has_submitted and roll_value < 0:
		state_label.text = "бросок сделан"
	else:
		state_label.text = "участвует"
	content.add_child(state_label)


func _on_return_to_menu_pressed() -> void:
	_delete_saved_session()
	_reset_game_session()
	_show_main_menu()


func _on_pause_menu_pressed() -> void:
	is_pause_menu_open = true
	menu_overlay.visible = true
	if _is_steam_p2p_main_table_active():
		_build_network_pause_menu_content()
		return
	if is_bug_report_review_mode:
		_build_bug_report_review_menu()
		return

	_build_pause_menu_content()


func _build_pause_menu_content() -> void:
	_clear_children(menu_content)
	_add_menu_title("Пауза", "Текущая локальная партия ждёт твоего решения")
	_add_menu_spacer(18.0)
	_add_menu_button("Продолжить", _resume_current_game, true)
	_add_menu_button("Показать аудиоплеер" if music_player_hidden else "Скрыть аудиоплеер", _on_music_player_visibility_toggle_pressed)
	_add_menu_button("Обучение", _show_tutorial_menu)
	_add_menu_button("Профиль", _show_profile_menu)
	_add_menu_button("Статистика", _show_statistics_menu)
	_add_menu_button("Правила", _show_rules_menu)
	_add_menu_button("Настройки", _show_settings_menu)
	_add_menu_button("Сообщить об ошибке", _show_bug_report_menu)
	_add_menu_button("Завершить партию", _show_end_session_confirmation)


func _build_network_pause_menu_content() -> void:
	_clear_children(menu_content)
	_add_menu_title("Сетевая пауза", "Сетевая раздача продолжается у хоста. Здесь можно безопасно вернуться в комнату или открыть личные настройки.")
	_add_menu_spacer(18.0)
	_add_menu_button("Продолжить", _resume_current_game, true)
	_add_menu_button("Вернуться в Steam-комнату", _return_to_steam_lobby_from_main_table)
	_add_menu_button("Показать аудиоплеер" if music_player_hidden else "Скрыть аудиоплеер", _on_music_player_visibility_toggle_pressed)
	_add_menu_button("Профиль", _show_profile_menu)
	_add_menu_button("Правила", _show_rules_menu)
	_add_menu_button("Настройки", _show_settings_menu)
	_add_menu_label("Расписка и история на столе показывают только публичные данные. Голосование за возврат, чат и реакции будут подключены отдельным сетевым шагом.", 14, Color(0.72, 0.85, 0.76, 1.0))


func _return_to_steam_lobby_from_main_table() -> void:
	_reset_loopback_network_joker_selection()
	steam_p2p_main_table_presentation = false
	steam_p2p_table_presentation = false
	is_pause_menu_open = false
	_show_steam_lobby_menu()


func _show_bug_report_menu() -> void:
	_clear_children(menu_content)
	_add_menu_title("Сообщить об ошибке", "Сохрани текущее состояние партии и отправь файл разработчику")
	_add_menu_label("В отчёт войдут ход раздачи, карты, заказы, история действий, настройки партии и версия игры. Личная музыка и личная картинка в файл не копируются.", 15, Color(0.72, 0.85, 0.76, 1.0))
	_add_menu_spacer(6.0)

	var description_label := Label.new()
	description_label.text = "Что произошло?"
	description_label.add_theme_font_size_override("font_size", 17)
	description_label.add_theme_color_override("font_color", Color(0.91, 0.96, 0.91, 1.0))
	menu_content.add_child(description_label)

	bug_report_description_input = TextEdit.new()
	bug_report_description_input.custom_minimum_size = Vector2(0.0, 118.0)
	bug_report_description_input.placeholder_text = "Например: в бескозырке Джокер не дал выбрать сброс после хода Олега."
	bug_report_description_input.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	bug_report_description_input.add_theme_font_size_override("font_size", 16)
	menu_content.add_child(bug_report_description_input)

	bug_report_status_label = Label.new()
	bug_report_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bug_report_status_label.add_theme_font_size_override("font_size", 14)
	bug_report_status_label.add_theme_color_override("font_color", Color(0.72, 0.85, 0.76, 1.0))
	menu_content.add_child(bug_report_status_label)

	_add_menu_button("Сохранить отчёт", _on_save_bug_report_pressed, true)
	_add_menu_button("Открыть папку отчётов", _open_bug_report_folder)
	_add_menu_button("Назад", _build_pause_menu_content)


func _build_bug_report_review_menu() -> void:
	_clear_children(menu_content)
	_add_menu_title("Просмотр отчёта", "Партия открыта в режиме проверки")
	_add_menu_label("Ходы, заказы и карты заблокированы, чтобы не изменить присланное состояние. Обычное сохранение твоей партии не затрагивается.", 16, Color(0.72, 0.85, 0.76, 1.0))
	_add_menu_spacer(12.0)
	_add_menu_button("Вернуться в главное меню", _close_bug_report_review, true)


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

	var network_match = _get_active_network_match()
	if _is_steam_p2p_main_table_active() and network_match != null and network_match.has_method(&"set_local_auto_turn_enabled"):
		network_match.call(&"set_local_auto_turn_enabled", enabled)
		_reset_turn_reminder()
		_refresh_ui()
		return

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


func _on_card_deck_style_selected(selected_index: int) -> void:
	card_deck_style = clampi(
		selected_index,
		CardArtworkResource.DeckStyle.JUMBO_FOUR_COLOR,
		CardArtworkResource.DeckStyle.VECTOR_CLASSIC
	)
	CardArtworkResource.set_deck_style(card_deck_style)
	_save_persistent_settings()
	_refresh_ui()
	_refresh_card_deck_preview()


func _on_table_felt_theme_selected(selected_index: int) -> void:
	table_felt_theme = clampi(selected_index, TableFeltTheme.GREEN, TableFeltTheme.BURGUNDY)
	_apply_table_theme()
	_save_persistent_settings()


func _on_table_surround_theme_selected(selected_index: int) -> void:
	table_surround_theme = clampi(selected_index, TableSurroundTheme.DARK_GREEN, TableSurroundTheme.WARM_FABRIC)
	_apply_table_theme()
	_save_persistent_settings()


func _refresh_table_theme_preview() -> void:
	if not is_instance_valid(table_theme_preview_surround) or not is_instance_valid(table_theme_preview_felt):
		return
	var surround_style := _create_flat_style(_get_surround_color(), _get_table_rim_color().lightened(0.28), 2, 12, 3)
	surround_style.content_margin_left = 0.0
	surround_style.content_margin_top = 0.0
	surround_style.content_margin_right = 0.0
	surround_style.content_margin_bottom = 0.0
	table_theme_preview_surround.add_theme_stylebox_override("panel", surround_style)
	table_theme_preview_felt.add_theme_stylebox_override(
		"panel",
		_create_flat_style(_get_felt_color(), _get_felt_border_color(), 3, 42, 0)
	)


func _refresh_card_deck_preview() -> void:
	if not is_instance_valid(card_deck_preview_container):
		return
	_clear_children(card_deck_preview_container)
	var preview_cards: Array[Card] = [
		_create_card(Card.Suit.CLUBS, Card.Rank.ACE),
		_create_card(Card.Suit.SPADES, Card.Rank.KING),
		_create_card(Card.Suit.HEARTS, Card.Rank.QUEEN),
		_create_card(Card.Suit.DIAMONDS, Card.Rank.TEN),
		_create_card(Card.Suit.CLUBS, Card.Rank.SIX, true)
	]
	for card in preview_cards:
		var card_view := CardView.new()
		card_view.set_card_size(Vector2(62.0, 90.0))
		card_view.set_card(card)
		card_deck_preview_container.add_child(card_view)


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
	var viewport_size := get_viewport_rect().size
	var popup_left := mini(316, maxi(20, roundi(viewport_size.x - float(popup_size.x) - 20.0)))
	var popup_top := mini(140, maxi(20, roundi(viewport_size.y - float(popup_size.y) - 20.0)))
	music_controls_popup.popup(Rect2i(Vector2i(popup_left, popup_top), popup_size))


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
	var saved_card_deck_style: int = int(config.get_value("display", "card_deck_style", card_deck_style))
	card_deck_style = clampi(
		saved_card_deck_style,
		CardArtworkResource.DeckStyle.JUMBO_FOUR_COLOR,
		CardArtworkResource.DeckStyle.VECTOR_CLASSIC
	)
	table_felt_theme = clampi(
		int(config.get_value("display", "table_felt_theme", table_felt_theme)),
		TableFeltTheme.GREEN,
		TableFeltTheme.BURGUNDY
	)
	table_surround_theme = clampi(
		int(config.get_value("display", "table_surround_theme", table_surround_theme)),
		TableSurroundTheme.DARK_GREEN,
		TableSurroundTheme.WARM_FABRIC
	)
	match_history_mode = clampi(
		int(config.get_value("game", "history_mode", match_history_mode)),
		NetworkHost.HistoryMode.FULL,
		NetworkHost.HistoryMode.LAST_TRICK_ONLY
	)
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
	# Личные файлы лежат вне сборки и могут быть повреждены, перенесены или
	# недоступны на другом устройстве. Никогда не открываем такой трек до меню:
	# при старте используем только одну из трёх встроенных тем.
	if music_track_index >= MUSIC_TRACK_COUNT:
		music_track_index = 0
	_load_local_statistics(config)

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
	config.set_value("game", "history_mode", match_history_mode)
	config.set_value("display", "card_deck_style", card_deck_style)
	config.set_value("display", "table_felt_theme", table_felt_theme)
	config.set_value("display", "table_surround_theme", table_surround_theme)
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
	_save_local_statistics(config)
	config.set_value(
		"display",
		"fullscreen",
		DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	)
	config.save(PERSISTENT_SETTINGS_PATH)


func _load_local_statistics(config: ConfigFile) -> void:
	local_statistics["completed_games"] = maxi(0, int(config.get_value("statistics", "completed_games", 0)))
	local_statistics["wins"] = maxi(0, int(config.get_value("statistics", "wins", 0)))
	local_statistics["second_places"] = maxi(0, int(config.get_value("statistics", "second_places", 0)))
	local_statistics["third_places"] = maxi(0, int(config.get_value("statistics", "third_places", 0)))
	local_statistics["fourth_places"] = maxi(0, int(config.get_value("statistics", "fourth_places", 0)))
	local_statistics["best_score"] = int(config.get_value("statistics", "best_score", 0))
	local_statistics["has_best_score"] = bool(config.get_value("statistics", "has_best_score", false))
	local_statistics["last_place"] = clampi(int(config.get_value("statistics", "last_place", 0)), 0, PLAYER_NAMES.size())
	local_statistics["last_score"] = int(config.get_value("statistics", "last_score", 0))
	local_statistics["last_exact_orders"] = maxi(0, int(config.get_value("statistics", "last_exact_orders", 0)))
	local_statistics["last_shared_place"] = bool(config.get_value("statistics", "last_shared_place", false))


func _save_local_statistics(config: ConfigFile) -> void:
	config.set_value("statistics", "completed_games", int(local_statistics["completed_games"]))
	config.set_value("statistics", "wins", int(local_statistics["wins"]))
	config.set_value("statistics", "second_places", int(local_statistics["second_places"]))
	config.set_value("statistics", "third_places", int(local_statistics["third_places"]))
	config.set_value("statistics", "fourth_places", int(local_statistics["fourth_places"]))
	config.set_value("statistics", "best_score", int(local_statistics["best_score"]))
	config.set_value("statistics", "has_best_score", bool(local_statistics["has_best_score"]))
	config.set_value("statistics", "last_place", int(local_statistics["last_place"]))
	config.set_value("statistics", "last_score", int(local_statistics["last_score"]))
	config.set_value("statistics", "last_exact_orders", int(local_statistics["last_exact_orders"]))
	config.set_value("statistics", "last_shared_place", bool(local_statistics["last_shared_place"]))


func _has_saved_session() -> bool:
	return FileAccess.file_exists(SESSION_SAVE_PATH)


func _save_current_session() -> void:
	if is_bug_report_review_mode or game.current_round.state == Round.State.SETUP or _is_full_game_complete():
		return

	var save_file := FileAccess.open(SESSION_SAVE_PATH, FileAccess.WRITE)
	if save_file == null:
		push_error("Не удалось открыть файл сохранения партии.")
		return

	var save_data := _create_session_save_data()
	save_data["bug_report_timeline"] = bug_report_timeline.duplicate(true)
	save_file.store_var(save_data, false)


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
		"history_mode": match_history_mode,
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
		"pending_joker_card": _serialize_optional_card(pending_joker_card),
		"pending_joker_suit": pending_joker_suit,
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
	var restored := _restore_session_from_data(save_data, true)
	if restored:
		bug_report_timeline = _deserialize_bug_report_timeline(save_data.get("bug_report_timeline", []))
	return restored


func _restore_session_from_data(save_data: Dictionary, persist_settings: bool) -> bool:
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
	match_history_mode = clampi(
		int(save_data.get("history_mode", NetworkHost.HistoryMode.FULL)),
		NetworkHost.HistoryMode.FULL,
		NetworkHost.HistoryMode.LAST_TRICK_ONLY
	)
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
	var pending_joker_data_variant: Variant = save_data.get("pending_joker_card", {})
	pending_joker_card = null
	if pending_joker_data_variant is Dictionary:
		pending_joker_card = _deserialize_optional_card(pending_joker_data_variant)
	pending_joker_suit = clampi(int(save_data.get("pending_joker_suit", -1)), -1, Card.Suit.DIAMONDS)
	_reset_trick_presentation()
	_restore_next_round_button()
	if persist_settings:
		_save_persistent_settings()
	return true


func _load_bug_report_from_path(report_path: String) -> bool:
	var report_file := FileAccess.open(report_path, FileAccess.READ)
	if report_file == null:
		return false

	var report_data_variant: Variant = report_file.get_var(false)
	if not (report_data_variant is Dictionary):
		return false

	var report_data: Dictionary = report_data_variant
	if str(report_data.get("format", "")) != "project_joker_bug_report":
		return false
	if int(report_data.get("report_version", 0)) != BUG_REPORT_FORMAT_VERSION:
		return false

	var session_data_variant: Variant = report_data.get("session", {})
	if not (session_data_variant is Dictionary):
		return false

	_capture_configuration_before_bug_report_review()
	var session_data: Dictionary = session_data_variant
	bug_report_review_timeline = _deserialize_bug_report_timeline(report_data.get("timeline", []))
	bug_report_review_timeline.append({
		"label": "Момент создания отчёта",
		"session": session_data.duplicate(true)
	})
	bug_report_review_index = bug_report_review_timeline.size() - 1
	bug_report_review_description = str(report_data.get("description", "")).strip_edges()
	is_bug_report_review_mode = true
	if not _show_bug_report_timeline_state(bug_report_review_index):
		is_bug_report_review_mode = false
		bug_report_review_timeline.clear()
		bug_report_review_index = -1
		bug_report_review_description = ""
		_restore_configuration_after_bug_report_review()
		return false

	return true


func _deserialize_bug_report_timeline(timeline_data: Variant) -> Array[Dictionary]:
	var timeline: Array[Dictionary] = []
	if not (timeline_data is Array):
		return timeline

	for timeline_item_variant in timeline_data:
		if not (timeline_item_variant is Dictionary):
			continue
		var timeline_item: Dictionary = timeline_item_variant
		var timeline_session_variant: Variant = timeline_item.get("session", {})
		if not (timeline_session_variant is Dictionary):
			continue
		timeline.append({
			"label": str(timeline_item.get("label", "Предыдущее состояние")),
			"session": (timeline_session_variant as Dictionary).duplicate(true)
		})

	return timeline


func _show_bug_report_timeline_state(index: int) -> bool:
	if index < 0 or index >= bug_report_review_timeline.size():
		return false

	var timeline_item: Dictionary = bug_report_review_timeline[index]
	var session_data_variant: Variant = timeline_item.get("session", {})
	if not (session_data_variant is Dictionary):
		return false

	if not _restore_session_from_data(session_data_variant, false):
		return false

	bug_report_review_index = index
	if configured_avatar_indices[HUMAN_PLAYER_INDEX] == CUSTOM_AVATAR_INDEX:
		# Личная картинка автора отчёта не передаётся и не должна подменяться
		# личной картинкой разработчика при просмотре чужого отчёта.
		configured_avatar_indices[HUMAN_PLAYER_INDEX] = 0
	_restore_next_round_button()
	_stop_human_turn_timer()
	if bug_report_review_index == bug_report_review_timeline.size() - 1 and not bug_report_review_description.is_empty():
		recent_actions.append("Описание ошибки: %s" % bug_report_review_description)
	action_text = "Отчёт: %d из %d" % [bug_report_review_index + 1, bug_report_review_timeline.size()]
	_refresh_ui()

	return true


func _on_bug_report_timeline_previous_pressed() -> void:
	_show_bug_report_timeline_state(bug_report_review_index - 1)


func _on_bug_report_timeline_next_pressed() -> void:
	_show_bug_report_timeline_state(bug_report_review_index + 1)


func _capture_configuration_before_bug_report_review() -> void:
	report_restore_player_names = configured_player_names.duplicate()
	report_restore_avatar_indices = configured_avatar_indices.duplicate()
	report_restore_bot_difficulty = bot_difficulty


func _restore_configuration_after_bug_report_review() -> void:
	if report_restore_player_names.size() == PLAYER_NAMES.size():
		configured_player_names = report_restore_player_names.duplicate()
	if report_restore_avatar_indices.size() == PLAYER_NAMES.size():
		configured_avatar_indices = report_restore_avatar_indices.duplicate()
	bot_difficulty = report_restore_bot_difficulty
	report_restore_player_names.clear()
	report_restore_avatar_indices.clear()


func _close_bug_report_review() -> void:
	if not is_bug_report_review_mode:
		return

	is_bug_report_review_mode = false
	is_pause_menu_open = false
	_stop_human_turn_timer()
	_restore_configuration_after_bug_report_review()
	bug_report_review_timeline.clear()
	bug_report_review_index = -1
	bug_report_review_description = ""
	_reset_game_session()
	_show_main_menu()


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
	next_round_button.disabled = is_bug_report_review_mode

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
	sound_streams[SoundEffect.TURN_REMINDER] = _create_procedural_sound(660.0, 990.0, 0.22, 0.26, 0.34)

	for player_number in 3:
		var player := AudioStreamPlayer.new()
		player.name = "SoundEffectPlayer%d" % player_number
		player.bus = &"Master"
		add_child(player)
		sound_players.append(player)

	for player_number in 3:
		var soundpad_player := AudioStreamPlayer.new()
		soundpad_player.name = "SoundpadPlayer%d" % player_number
		soundpad_player.bus = &"Master"
		add_child(soundpad_player)
		soundpad_players.append(soundpad_player)

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


func _play_soundpad_stream(stream: AudioStream) -> void:
	if stream == null or sound_volume_index == 0:
		return

	var soundpad_player := _get_available_soundpad_player()
	if soundpad_player == null:
		return

	soundpad_player.stream = stream
	soundpad_player.play()


func _get_available_soundpad_player() -> AudioStreamPlayer:
	for player in soundpad_players:
		if not player.playing:
			return player

	if soundpad_players.is_empty():
		return null

	var player := soundpad_players[next_soundpad_player_index]
	next_soundpad_player_index = (next_soundpad_player_index + 1) % soundpad_players.size()
	return player


func _apply_sound_volume() -> void:
	var volume_db := _get_sound_volume_db()

	for player in sound_players:
		player.volume_db = volume_db

	for player in soundpad_players:
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
	_reset_turn_reminder()
	local_first_turn_roll_generation += 1
	local_first_turn_roll_active = false
	local_first_turn_roll_round = 0
	local_first_turn_roll_contenders.clear()
	local_first_turn_roll_values.clear()
	local_first_turn_roll_winner_index = -1
	if is_instance_valid(first_turn_roll_panel):
		first_turn_roll_panel.visible = false
	game = Game.new(configured_player_names)
	game_statistics_recorded_for_current_session = false
	statistics_return_to_final_menu = false
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
	bug_report_timeline.clear()
	test_checkpoints.clear()
	pending_test_checkpoint.clear()
	undo_requests_for_current_decision = 0
	is_undo_vote_in_progress = false
	_reset_undo_vote_states()
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
	undo_requests_for_current_decision = 0
	is_undo_vote_in_progress = false
	_reset_undo_vote_states()

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
	if game.current_round.number == 1 and local_first_turn_roll_winner_index >= 0:
		action_text += " Первым заказывает и ходит %s." % game.players[local_first_turn_roll_winner_index].display_name
	_add_history(action_text)
	next_round_button.visible = false
	next_round_button.disabled = false
	_refresh_ui()
	_save_current_session()
	_advance_automatic_actions()


func _advance_automatic_actions() -> void:
	if is_bug_report_review_mode or is_processing_automatic_actions:
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
				is_processing_automatic_actions = false
				_finish_round()
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

	_capture_bug_report_timeline("Перед заказом %s" % game.players[player_index].display_name)
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
	_capture_bug_report_timeline("Перед ходом %s: %s" % [player.display_name, card.get_card_name()])

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
	if is_bug_report_review_mode:
		return

	var cards_were_hidden := _is_dark_round() and not game.cards_are_dealt

	if not game.current_round.can_place_bid(HUMAN_PLAYER_INDEX, bid):
		action_text = "Этот заказ сейчас недоступен."
		_refresh_ui()
		return

	_capture_bug_report_timeline("Перед твоим заказом")
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
	if is_bug_report_review_mode or not _is_human_turn() or not _is_card_available_to_human(card):
		return

	if card.is_joker:
		_capture_bug_report_timeline("Перед выбором условия Джокера")
		pending_joker_card = card
		pending_joker_suit = -1
		action_text = "Выбери условие для Джокера."
		_refresh_ui()
		return

	_capture_bug_report_timeline("Перед твоим ходом: %s" % card.get_card_name())
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
	if is_bug_report_review_mode or pending_joker_card == null or game.active_trick != null:
		return

	_capture_bug_report_timeline("Перед объявлением масти Джокера")
	pending_joker_suit = suit
	action_text = "Выбери условие для %s." % _get_suit_symbol(suit)
	_refresh_ui()


func _on_joker_choice(
	mode: Trick.JokerMode,
	declared_suit: int = -1,
	forced_card_rank: Trick.ForcedCardRank = Trick.ForcedCardRank.NONE
) -> void:
	if is_bug_report_review_mode or pending_joker_card == null:
		return

	var is_leading_joker := game.active_trick == null

	_capture_bug_report_timeline("Перед ходом Джокером")
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
	if _is_steam_p2p_main_table_active():
		var network_match = _get_active_network_match()
		if network_match != null and network_match.has_method(&"request_undo"):
			network_match.call(&"request_undo")
		_refresh_network_main_table()
		return

	if not _can_request_undo():
		return

	undo_requests_for_current_decision += 1
	is_undo_vote_in_progress = true
	is_processing_automatic_actions = true
	_reset_undo_vote_states()
	action_text = "Запрос на возврат хода: боты голосуют…"
	_refresh_ui()
	_process_local_undo_vote()


func _on_submit_network_undo_vote_pressed(approved: bool) -> void:
	var network_match = _get_active_network_match()
	if network_match == null or not network_match.has_method(&"submit_undo_vote"):
		return
	network_match.call(&"submit_undo_vote", approved)
	_refresh_network_main_table()


func _reset_network_table_after_undo_restore() -> void:
	network_round_result_key = ""
	network_round_finish_presentation_key = ""
	network_round_finish_presentation_active = false
	network_collected_trick_key = ""
	network_public_event_stream_key = ""
	network_last_public_event_id = -1
	network_card_event_queue.clear()
	network_card_play_presentation_active = false
	_reset_trick_presentation()


func _process_local_undo_vote() -> void:
	# В одиночной партии все три соперника — локальные боты. Они всегда
	# подтверждают возврат, но делают это по очереди, чтобы галочки у
	# аватаров успели появиться и игрок видел результат голосования.
	for player_index in range(1, game.players.size()):
		await get_tree().create_timer(LOCAL_UNDO_VOTE_INTERVAL_SECONDS).timeout
		undo_vote_states[player_index] = UndoVoteState.APPROVED
		action_text = "%s согласен вернуть ход." % game.players[player_index].display_name
		_refresh_ui()

	await get_tree().create_timer(LOCAL_UNDO_VOTE_RESULT_HOLD_SECONDS).timeout
	var checkpoint: Dictionary = test_checkpoints.pop_back()
	_stop_human_turn_timer()
	game.restore_snapshot(checkpoint["game"])
	_reset_trick_presentation()
	pending_joker_card = null
	pending_joker_suit = -1
	last_trick_text = checkpoint["last_trick_text"]
	action_text = "Боты согласились. Прошлый ход отменён."
	recent_actions = checkpoint["recent_actions"].duplicate()
	bug_report_timeline.clear()
	pending_test_checkpoint = _create_test_checkpoint()
	is_processing_automatic_actions = false
	is_undo_vote_in_progress = false
	_save_current_session()
	_refresh_ui()


func _on_score_sheet_toggle_pressed() -> void:
	is_score_sheet_visible = not is_score_sheet_visible
	_save_current_session()
	_refresh_ui()


func _on_score_sheet_backdrop_gui_input(event: InputEvent) -> void:
	if not is_score_sheet_visible:
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
	is_round_history_visible = not is_round_history_visible
	_save_current_session()
	_refresh_ui()


func _on_hand_sort_by_suit_pressed() -> void:
	if is_bug_report_review_mode or is_processing_automatic_actions:
		return

	hand_sort_mode = HandSortMode.BY_SUIT
	_save_current_session()
	_refresh_ui()


func _on_hand_sort_trumps_left_pressed() -> void:
	if is_bug_report_review_mode or is_processing_automatic_actions:
		return

	hand_sort_mode = HandSortMode.TRUMPS_LEFT
	_save_current_session()
	_refresh_ui()


func _on_next_round_pressed() -> void:
	if _is_steam_p2p_main_table_active():
		_on_start_next_steam_p2p_round_from_table_pressed()
		return

	if is_bug_report_review_mode or not _can_start_next_round():
		return

	_capture_bug_report_timeline("Перед началом следующей раздачи")
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

	# Возврат относится только к решениям текущей раздачи.
	test_checkpoints.clear()
	pending_test_checkpoint.clear()
	undo_requests_for_current_decision = 0
	_reset_undo_vote_states()
	_start_round()


func _on_start_next_steam_p2p_round_from_table_pressed() -> void:
	if steam_p2p_match == null or not steam_p2p_match.is_host():
		return
	if not steam_p2p_match.start_next_scheduled_round():
		return

	_reset_loopback_network_joker_selection()
	network_round_result_key = ""
	network_round_finish_presentation_key = ""
	network_round_finish_presentation_active = false
	_refresh_network_main_table()


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
		var round_score: int = round_scores[player_index]
		var outcome_text := _get_round_order_outcome_text(player.bid, player.tricks_taken, _round_uses_bids())

		if _round_uses_bids():
			result_lines.append("%s: взято %d, %s, %s, счёт %d → %d" % [
				player.display_name,
				player.tricks_taken,
				outcome_text,
				_format_score(round_score),
				player.total_score - round_score,
				player.total_score
			])
		else:
			result_lines.append("%s: взято %d, без заказа, %s, счёт %d → %d" % [
				player.display_name,
				player.tricks_taken,
				_format_score(round_score),
				player.total_score - round_score,
				player.total_score
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
		_record_completed_game_statistics()
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
	if _did_local_joker_win_last_trick(winner_player_index):
		_show_joker_celebration(winner_player_index)
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
	var target_rotation := card_view.rotation
	var source_position: Vector2 = _get_played_card_source_global_position(player_index, card_view.size)
	card_view.pivot_offset = card_view.size * 0.5
	card_view.global_position = source_position
	card_view.rotation = target_rotation + deg_to_rad(_get_card_flight_start_angle(player_index))
	card_view.scale = Vector2(0.78, 0.78)
	card_view.modulate = Color(1.0, 1.0, 1.0, 0.86)
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(card_view, "global_position", target_position, CARD_FLY_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(card_view, "rotation", target_rotation, CARD_FLY_DURATION).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
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


func _get_card_flight_start_angle(relative_slot: int) -> float:
	var start_angles := [-5.0, 7.0, -4.0, -7.0]
	return float(start_angles[clampi(relative_slot, 0, start_angles.size() - 1)])


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
		tween.tween_property(card_view, "rotation", deg_to_rad(float(player_index - winner_player_index) * 4.0), TRICK_COLLECTION_DURATION)
		tween.tween_property(card_view, "scale", Vector2(0.36, 0.36), TRICK_COLLECTION_DURATION)
		tween.tween_property(card_view, "modulate", Color(1.0, 1.0, 1.0, 0.0), TRICK_COLLECTION_DURATION)

	if has_visible_cards:
		await tween.finished

	for card_view in trick_card_views:
		card_view.visible = false
		card_view.rotation = 0.0
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
	_reset_joker_celebration()

	for card_view in trick_card_views:
		card_view.set_winner_highlight(false)
		card_view.visible = false
		card_view.rotation = 0.0
		card_view.scale = Vector2.ONE
		card_view.modulate = Color.WHITE


func _refresh_ui() -> void:
	if _is_steam_p2p_main_table_active():
		_refresh_network_main_table()
		return

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
	_refresh_reaction_controls()
	_refresh_sticker_controls()
	_refresh_soundpad_controls()
	_refresh_chat_controls()
	_refresh_social_action_buttons()
	_refresh_first_turn_roll_panel()


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
	trump_label.text = _format_suit_symbols_for_dark_ui(trump_label.text)
	var should_show_action_label := is_bug_report_review_mode or (
		game.current_round.state == Round.State.PLAYING
		and pending_joker_card == null
		and (
			_get_current_player_index() == HUMAN_PLAYER_INDEX
			or is_trick_presentation_active
		)
	)
	action_label.visible = should_show_action_label
	action_label.text = action_text
	pause_menu_button.disabled = false


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
			player_stats_labels[player_index].text = _get_player_stats_bbcode(bid_text, player.tricks_taken, true)
		else:
			player_stats_labels[player_index].text = _get_player_stats_bbcode("—", player.tricks_taken, false)
		_set_player_score_display(
			player_index,
			player.total_score,
			game.current_round.state == Round.State.FINISHED
		)

	_refresh_bot_card_backs()
	_refresh_player_avatar_badges()
	_refresh_undo_vote_badges()
	_refresh_table_markers()


func _get_player_stats_bbcode(bid_text: String, tricks_taken: int, uses_bids: bool) -> String:
	if uses_bids:
		return (
			"[center][color=#dce8dc]Заказ[/color] "
			+ "[font_size=23][b][color=#ffd65a]%s[/color][/b][/font_size]"
			+ "  [color=#77927f]•[/color]  [color=#dce8dc]Взято[/color] "
			+ "[font_size=23][b][color=#ffffff]%d[/color][/b][/font_size][/center]"
		) % [bid_text, tricks_taken]
	return (
		"[center][color=#dce8dc]Взято[/color] "
		+ "[font_size=23][b][color=#ffffff]%d[/color][/b][/font_size][/center]"
	) % tricks_taken


func _set_player_score_display(player_slot: int, target_score: int, animate_change: bool) -> void:
	if player_slot < 0 or player_slot >= player_score_labels.size():
		return
	while displayed_player_scores.size() <= player_slot:
		displayed_player_scores.append(UNSET_SCORE_DISPLAY)

	var score_label: Label = player_score_labels[player_slot]
	var previous_score := displayed_player_scores[player_slot]
	var active_tween: Tween = player_score_tweens.get(player_slot) as Tween
	if previous_score == UNSET_SCORE_DISPLAY:
		displayed_player_scores[player_slot] = target_score
		_apply_static_player_score_style(score_label, target_score)
		return
	if previous_score == target_score:
		if is_instance_valid(active_tween) and active_tween.is_running():
			return
		_apply_static_player_score_style(score_label, target_score)
		return

	if is_instance_valid(active_tween):
		active_tween.kill()
	player_score_tweens.erase(player_slot)
	if not animate_change:
		displayed_player_scores[player_slot] = target_score
		_apply_static_player_score_style(score_label, target_score)
		return

	var score_delta := target_score - previous_score
	displayed_player_scores[player_slot] = target_score
	var duration := clampf(0.55 + absf(float(score_delta)) * 0.018, 0.65, 1.35)
	var tween := create_tween()
	player_score_tweens[player_slot] = tween
	tween.tween_method(
		_apply_player_score_tween_value.bind(player_slot, score_delta),
		float(previous_score),
		float(target_score),
		duration
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_callback(_finish_player_score_tween.bind(player_slot, target_score))


func _hold_player_score_until_round_result(player_slot: int, fallback_score: int) -> void:
	if player_slot < 0 or player_slot >= player_score_labels.size():
		return
	while displayed_player_scores.size() <= player_slot:
		displayed_player_scores.append(UNSET_SCORE_DISPLAY)
	if displayed_player_scores[player_slot] == UNSET_SCORE_DISPLAY:
		# При подключении уже после завершения раздачи старое значение неизвестно:
		# показываем актуальный счёт без искусственного отсчёта от нуля.
		displayed_player_scores[player_slot] = fallback_score
		_apply_static_player_score_style(player_score_labels[player_slot], fallback_score)


func _apply_player_score_tween_value(value: float, player_slot: int, score_delta: int) -> void:
	if player_slot < 0 or player_slot >= player_score_labels.size():
		return
	var score_label: Label = player_score_labels[player_slot]
	score_label.text = "Счёт: %d   %s" % [roundi(value), _format_score(score_delta)]
	score_label.add_theme_font_size_override("font_size", 21)
	score_label.add_theme_color_override(
		"font_color",
		Color(0.38, 0.94, 0.55, 1.0) if score_delta > 0 else Color(1.0, 0.36, 0.31, 1.0)
	)


func _finish_player_score_tween(player_slot: int, target_score: int) -> void:
	player_score_tweens.erase(player_slot)
	if player_slot < 0 or player_slot >= player_score_labels.size():
		return
	_apply_static_player_score_style(player_score_labels[player_slot], target_score)


func _apply_static_player_score_style(score_label: Label, score: int) -> void:
	score_label.text = "Счёт: %d" % score
	score_label.add_theme_font_size_override("font_size", 19)
	score_label.add_theme_color_override(
		"font_color",
		Color(0.97, 0.84, 0.38, 1.0) if score >= 0 else Color(0.96, 0.42, 0.34, 1.0)
	)


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


func _get_avatar_symbol_for_index(avatar_index: int) -> String:
	match avatar_index:
		0:
			return "★"
		1:
			return "☀"
		2:
			return "☾"
		3:
			return "✦"
	return "•"


func _get_network_avatar_profile(player_index: int) -> Dictionary:
	var network_match = _get_active_network_match()
	if network_match == null:
		return {}
	for seat_variant in network_match.lobby_seats:
		if seat_variant is Dictionary and int((seat_variant as Dictionary).get("player_index", -1)) == player_index:
			return (seat_variant as Dictionary).duplicate(true)
	return {}


func _get_network_player_avatar_symbol(player_index: int) -> String:
	var profile := _get_network_avatar_profile(player_index)
	return _get_avatar_symbol_for_index(int(profile.get("avatar_index", 0)))


func _get_network_player_avatar_texture(player_index: int) -> Texture2D:
	var profile := _get_network_avatar_profile(player_index)
	var avatar_index := clampi(int(profile.get("avatar_index", 0)), 0, CUSTOM_AVATAR_INDEX)
	var avatar_data := str(profile.get("avatar_data", ""))
	var signature := "%d:%d" % [avatar_index, avatar_data.hash()]
	var cached: Dictionary = network_avatar_texture_cache.get(player_index, {})
	if str(cached.get("signature", "")) == signature:
		return cached.get("texture", null) as Texture2D

	var texture: Texture2D
	if avatar_index == CUSTOM_AVATAR_INDEX and not avatar_data.is_empty():
		var image := Image.new()
		if image.load_png_from_buffer(Marshalls.base64_to_raw(avatar_data)) == OK:
			texture = ImageTexture.create_from_image(image)
	else:
		texture = _load_avatar_texture_from_path(_get_avatar_texture_path_for_index(avatar_index))
	network_avatar_texture_cache[player_index] = {"signature": signature, "texture": texture}
	return texture


func _get_local_network_avatar_data() -> String:
	if configured_avatar_indices[HUMAN_PLAYER_INDEX] != CUSTOM_AVATAR_INDEX or custom_profile_avatar_path.is_empty():
		return ""
	var image := Image.load_from_file(ProjectSettings.globalize_path(custom_profile_avatar_path))
	if image == null or image.is_empty():
		return ""
	var largest_side := maxi(image.get_width(), image.get_height())
	if largest_side > 128:
		var resize_scale := 128.0 / float(largest_side)
		image.resize(
			maxi(1, roundi(float(image.get_width()) * resize_scale)),
			maxi(1, roundi(float(image.get_height()) * resize_scale)),
			Image.INTERPOLATE_LANCZOS
		)
	return Marshalls.raw_to_base64(image.save_png_to_buffer())


func _get_player_avatar_texture_path(player_index: int) -> String:
	var avatar_index := configured_avatar_indices[player_index] if player_index >= 0 and player_index < configured_avatar_indices.size() else 0
	var custom_avatar_path := custom_profile_avatar_path if player_index == HUMAN_PLAYER_INDEX else ""
	return _get_avatar_texture_path_for_index(avatar_index, custom_avatar_path)


func _get_avatar_texture_path_for_index(avatar_index: int, custom_avatar_path: String = "") -> String:
	if avatar_index == CUSTOM_AVATAR_INDEX:
		return custom_avatar_path

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
	return _load_avatar_texture_from_path(texture_path)


func _load_avatar_texture_from_path(texture_path: String) -> Texture2D:
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
	undo_vote_states.resize(PLAYER_NAMES.size())
	undo_vote_states.fill(UndoVoteState.NONE)
	var turn_glow_material := _create_avatar_turn_glow_material()
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

		var turn_glow := ColorRect.new()
		turn_glow.visible = false
		turn_glow.z_index = 3
		turn_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		turn_glow.set_anchors_preset(Control.PRESET_FULL_RECT)
		turn_glow.offset_left = -10.0
		turn_glow.offset_top = -10.0
		turn_glow.offset_right = 10.0
		turn_glow.offset_bottom = 10.0
		turn_glow.color = Color.WHITE
		turn_glow.material = turn_glow_material
		avatar_content.add_child(turn_glow)

		var turn_label := Label.new()
		turn_label.visible = false
		turn_label.z_index = 4
		turn_label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
		turn_label.offset_top = -30.0
		turn_label.offset_bottom = -4.0
		turn_label.text = "ХОД"
		turn_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		turn_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		turn_label.add_theme_font_size_override("font_size", 17)
		turn_label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.34, 1.0))
		turn_label.add_theme_color_override("font_outline_color", Color(0.04, 0.03, 0.01, 1.0))
		turn_label.add_theme_constant_override("outline_size", 6)
		turn_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		avatar_content.add_child(turn_label)

		var undo_vote_badge := PanelContainer.new()
		undo_vote_badge.name = "UndoVoteBadge"
		undo_vote_badge.visible = false
		undo_vote_badge.z_index = 5
		undo_vote_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		undo_vote_badge.anchor_left = 1.0
		undo_vote_badge.anchor_top = 1.0
		undo_vote_badge.anchor_right = 1.0
		undo_vote_badge.anchor_bottom = 1.0
		undo_vote_badge.offset_left = -30.0
		undo_vote_badge.offset_top = -30.0
		undo_vote_badge.offset_right = -2.0
		undo_vote_badge.offset_bottom = -2.0
		undo_vote_badge.add_theme_stylebox_override("panel", undo_vote_approved_style)
		var undo_vote_label := Label.new()
		undo_vote_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		undo_vote_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		undo_vote_label.add_theme_font_size_override("font_size", 19)
		undo_vote_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		undo_vote_badge.add_child(undo_vote_label)
		avatar_content.add_child(undo_vote_badge)

		var action_tray := HBoxContainer.new()
		action_tray.name = "PlayerActionTray"
		action_tray.visible = false
		action_tray.modulate.a = 0.0
		action_tray.z_index = 8
		action_tray.mouse_filter = Control.MOUSE_FILTER_PASS
		action_tray.add_theme_constant_override("separation", 4)
		_set_control_layout(action_tray, 0.5, 0.0, 0.5, 0.0, -44.0, -8.0, 44.0, 34.0)
		action_tray.mouse_entered.connect(_on_avatar_mute_hover_entered.bind(player_index))
		action_tray.mouse_exited.connect(_on_avatar_mute_hover_exited.bind(player_index))
		avatar_content.add_child(action_tray)

		var gift_button := Button.new()
		gift_button.name = "PlayerGiftButton"
		gift_button.visible = false
		gift_button.text = "🎁"
		gift_button.tooltip_text = "Отправить подарок"
		gift_button.custom_minimum_size = Vector2(40.0, 40.0)
		gift_button.add_theme_font_size_override("font_size", 18)
		_apply_bare_social_icon_button_style(gift_button)
		gift_button.pressed.connect(_on_avatar_gift_button_pressed.bind(player_index))
		gift_button.mouse_entered.connect(_on_avatar_mute_hover_entered.bind(player_index))
		gift_button.mouse_exited.connect(_on_avatar_mute_hover_exited.bind(player_index))
		action_tray.add_child(gift_button)

		var mute_button := Button.new()
		mute_button.name = "PlayerMuteButton"
		mute_button.visible = false
		mute_button.text = "🔊"
		mute_button.custom_minimum_size = Vector2(40.0, 40.0)
		mute_button.add_theme_font_size_override("font_size", 18)
		_apply_bare_social_icon_button_style(mute_button)
		mute_button.pressed.connect(_on_avatar_mute_button_pressed.bind(player_index))
		mute_button.mouse_entered.connect(_on_avatar_mute_hover_entered.bind(player_index))
		mute_button.mouse_exited.connect(_on_avatar_mute_hover_exited.bind(player_index))
		action_tray.add_child(mute_button)
		badge.mouse_entered.connect(_on_avatar_mute_hover_entered.bind(player_index))
		badge.mouse_exited.connect(_on_avatar_mute_hover_exited.bind(player_index))

		if player_index == HUMAN_PLAYER_INDEX:
			turn_timer_indicator = TurnTimerIndicator.new()
			turn_timer_indicator.visible = false
			turn_timer_indicator.z_index = 2
			avatar_content.add_child(turn_timer_indicator)
		players_container.add_child(badge)
		avatar_badges.append(badge)
		avatar_images.append(avatar_image)
		avatar_labels.append(avatar_label)
		avatar_turn_labels.append(turn_label)
		avatar_turn_glows.append(turn_glow)
		avatar_action_trays.append(action_tray)
		avatar_mute_buttons.append(mute_button)
		avatar_gift_buttons.append(gift_button)
		undo_vote_badges.append(undo_vote_badge)
		undo_vote_labels.append(undo_vote_label)


func _refresh_player_avatar_badges() -> void:
	for player_index in avatar_badges.size():
		var is_current := (
			not is_trick_presentation_active
			and _get_current_player_index() == player_index
			and game.current_round.state != Round.State.FINISHED
		)
		_set_avatar_turn_active(player_index, is_current)
		avatar_badges[player_index].tooltip_text = "Аватар: %s" % game.players[player_index].display_name
		var avatar_texture: Texture2D = _get_player_avatar_texture(player_index)
		avatar_images[player_index].texture = avatar_texture
		avatar_labels[player_index].visible = avatar_texture == null
		avatar_labels[player_index].text = _get_player_avatar_symbol(player_index)
		if player_index < avatar_mute_buttons.size():
			var is_muted := muted_network_player_indices.has(player_index)
			avatar_mute_buttons[player_index].set_meta("network_player_index", player_index)
			avatar_mute_buttons[player_index].text = "🔇" if is_muted else "🔊"
			avatar_mute_buttons[player_index].tooltip_text = (
				"Показывать реакции, подарки и звуки этого игрока"
				if is_muted
				else "Скрыть реакции, подарки и звуки этого игрока"
			)
		if player_index < avatar_gift_buttons.size():
			avatar_gift_buttons[player_index].set_meta("network_player_index", player_index)
			_set_avatar_action_tray_visible(
				player_index,
				player_index != HUMAN_PLAYER_INDEX
				and avatar_mute_hovered_slots.has(player_index)
				and _can_show_reaction_controls(),
			)


func _refresh_avatar_mute_buttons(snapshot: Dictionary, viewer_index: int) -> void:
	var players_by_index := _get_network_players_by_index(snapshot)
	for relative_slot in avatar_mute_buttons.size():
		var mute_button: Button = avatar_mute_buttons[relative_slot]
		var player_index := posmod(viewer_index + relative_slot, PLAYER_NAMES.size())
		var is_self := player_index == viewer_index
		var is_muted := muted_network_player_indices.has(player_index)
		mute_button.set_meta("network_player_index", player_index)
		mute_button.text = "🔇" if is_muted else "🔊"
		mute_button.tooltip_text = (
			"Показывать реакции, подарки и звуки этого игрока только у себя"
			if is_muted
			else "Скрыть реакции, подарки и звуки этого игрока только у себя"
		)
		var should_show_actions := (
			_is_steam_p2p_main_table_active()
			and not is_self
			and avatar_mute_hovered_slots.has(relative_slot)
		)
		if relative_slot < avatar_gift_buttons.size():
			var gift_button: Button = avatar_gift_buttons[relative_slot]
			gift_button.set_meta("network_player_index", player_index)
			should_show_actions = should_show_actions and _can_show_reaction_controls()
			_set_avatar_action_tray_visible(relative_slot, should_show_actions)
		if relative_slot < avatar_badges.size():
			var player_data: Dictionary = players_by_index.get(player_index, {})
			var player_name := str(player_data.get("display_name", "Игрок"))
			avatar_badges[relative_slot].tooltip_text = (
				"%s · реакции, подарки и звук скрыты у тебя"
				if is_muted
				else "%s · наведи для личного мута"
			) % player_name


func _on_avatar_mute_hover_entered(relative_slot: int) -> void:
	if relative_slot == HUMAN_PLAYER_INDEX:
		return
	avatar_action_hide_generations[relative_slot] = int(avatar_action_hide_generations.get(relative_slot, 0)) + 1
	avatar_mute_hovered_slots[relative_slot] = true
	var snapshot := _get_network_main_snapshot()
	if _is_steam_p2p_main_table_active() and not snapshot.is_empty():
		_refresh_avatar_mute_buttons(snapshot, int(snapshot.get("recipient_player_index", 0)))
	else:
		_refresh_player_avatar_badges()


func _on_avatar_mute_hover_exited(relative_slot: int) -> void:
	var hide_generation := int(avatar_action_hide_generations.get(relative_slot, 0)) + 1
	avatar_action_hide_generations[relative_slot] = hide_generation
	call_deferred("_finish_avatar_mute_hover_exit", relative_slot, hide_generation)


func _finish_avatar_mute_hover_exit(relative_slot: int, hide_generation: int) -> void:
	if relative_slot < 0 or relative_slot >= avatar_badges.size() or relative_slot >= avatar_mute_buttons.size():
		return
	var pointer_position := get_viewport().get_mouse_position()
	if (
		avatar_badges[relative_slot].get_global_rect().has_point(pointer_position)
		or (
			relative_slot < avatar_action_trays.size()
			and avatar_action_trays[relative_slot].get_global_rect().has_point(pointer_position)
		)
	):
		return
	await get_tree().create_timer(AVATAR_ACTION_HIDE_DELAY_SECONDS).timeout
	if int(avatar_action_hide_generations.get(relative_slot, -1)) != hide_generation:
		return
	pointer_position = get_viewport().get_mouse_position()
	if (
		avatar_badges[relative_slot].get_global_rect().has_point(pointer_position)
		or (
			relative_slot < avatar_action_trays.size()
			and avatar_action_trays[relative_slot].get_global_rect().has_point(pointer_position)
		)
	):
		return
	avatar_mute_hovered_slots.erase(relative_slot)
	var snapshot := _get_network_main_snapshot()
	if _is_steam_p2p_main_table_active() and not snapshot.is_empty():
		_refresh_avatar_mute_buttons(snapshot, int(snapshot.get("recipient_player_index", 0)))
	else:
		_refresh_player_avatar_badges()


func _on_avatar_mute_button_pressed(relative_slot: int) -> void:
	if relative_slot < 0 or relative_slot >= avatar_mute_buttons.size():
		return
	var player_index := int(avatar_mute_buttons[relative_slot].get_meta("network_player_index", -1))
	if player_index < 0:
		return
	if muted_network_player_indices.has(player_index):
		muted_network_player_indices.erase(player_index)
	else:
		muted_network_player_indices[player_index] = true
		_hide_reaction_bubble()
		_hide_all_sticker_flyers()
		_hide_soundpad_bubble()
	var snapshot := _get_network_main_snapshot()
	if _is_steam_p2p_main_table_active() and not snapshot.is_empty():
		_refresh_avatar_mute_buttons(snapshot, int(snapshot.get("recipient_player_index", 0)))
	else:
		_refresh_player_avatar_badges()


func _set_avatar_action_tray_visible(relative_slot: int, should_show: bool, instant := false) -> void:
	if relative_slot < 0 or relative_slot >= avatar_action_trays.size():
		return
	var tray: HBoxContainer = avatar_action_trays[relative_slot]
	var was_requested := bool(tray.get_meta("actions_requested_visible", false))
	if was_requested == should_show and tray.visible == should_show:
		return
	tray.set_meta("actions_requested_visible", should_show)
	if avatar_action_tray_tweens.has(relative_slot):
		var previous_tween: Tween = avatar_action_tray_tweens[relative_slot] as Tween
		if previous_tween != null and previous_tween.is_valid():
			previous_tween.kill()
		avatar_action_tray_tweens.erase(relative_slot)

	if should_show:
		tray.visible = true
		avatar_gift_buttons[relative_slot].visible = true
		avatar_mute_buttons[relative_slot].visible = true
		if instant:
			tray.position.y = -50.0
			tray.modulate.a = 1.0
			return
		if not was_requested:
			tray.position.y = -8.0
			tray.modulate.a = 0.0
		var show_tween := create_tween().set_parallel(true)
		show_tween.tween_property(tray, "position:y", -50.0, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		show_tween.tween_property(tray, "modulate:a", 1.0, 0.14)
		avatar_action_tray_tweens[relative_slot] = show_tween
		return

	if instant or not tray.visible:
		tray.visible = false
		avatar_gift_buttons[relative_slot].visible = false
		avatar_mute_buttons[relative_slot].visible = false
		tray.position.y = -8.0
		tray.modulate.a = 0.0
		return
	var hide_tween := create_tween().set_parallel(true)
	hide_tween.tween_property(tray, "position:y", -8.0, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	hide_tween.tween_property(tray, "modulate:a", 0.0, 0.1)
	hide_tween.set_parallel(false)
	hide_tween.tween_callback(_finish_avatar_action_tray_hide.bind(relative_slot))
	avatar_action_tray_tweens[relative_slot] = hide_tween


func _finish_avatar_action_tray_hide(relative_slot: int) -> void:
	avatar_action_tray_tweens.erase(relative_slot)
	if relative_slot < 0 or relative_slot >= avatar_action_trays.size():
		return
	var tray: HBoxContainer = avatar_action_trays[relative_slot]
	if bool(tray.get_meta("actions_requested_visible", false)):
		return
	tray.visible = false
	avatar_gift_buttons[relative_slot].visible = false
	avatar_mute_buttons[relative_slot].visible = false


func _on_avatar_gift_button_pressed(relative_slot: int) -> void:
	if relative_slot < 0 or relative_slot >= avatar_gift_buttons.size() or not _can_show_reaction_controls():
		return
	var target_player_index := int(avatar_gift_buttons[relative_slot].get_meta("network_player_index", relative_slot))
	if sticker_picker.visible and sticker_selected_target_index == target_player_index:
		_close_sticker_picker()
		return
	_on_sticker_target_selected(target_player_index)
	if sticker_selected_target_index != target_player_index:
		return
	reaction_picker.visible = false
	soundpad_picker.visible = false
	chat_panel.visible = false
	sticker_picker.visible = true
	_restart_sticker_picker_auto_close()


func _set_avatar_turn_active(player_index: int, is_current: bool) -> void:
	if player_index < 0 or player_index >= avatar_badges.size():
		return
	avatar_badges[player_index].add_theme_stylebox_override(
		"panel",
		active_avatar_badge_style if is_current else avatar_badge_style
	)
	if player_index < avatar_turn_labels.size():
		avatar_turn_labels[player_index].visible = is_current
	if player_index < avatar_turn_glows.size():
		avatar_turn_glows[player_index].visible = is_current


func _create_avatar_turn_glow_material() -> ShaderMaterial:
	var glow_shader := Shader.new()
	glow_shader.code = AVATAR_TURN_GLOW_SHADER_CODE
	var glow_material := ShaderMaterial.new()
	glow_material.shader = glow_shader
	return glow_material


func _place_player_avatar_badge(badge: PanelContainer, player_index: int) -> void:
	match player_index:
		HUMAN_PLAYER_INDEX:
			_set_control_layout(badge, 0.5, 1.0, 0.5, 1.0, -218.0, -402.0, -114.0, -298.0)
		1:
			_set_control_layout(badge, 0.0, 0.0, 0.0, 0.0, 187.0, 348.0, 291.0, 452.0)
		2:
			_set_control_layout(badge, 0.5, 0.0, 0.5, 0.0, -217.0, 74.0, -113.0, 178.0)
		3:
			_set_control_layout(badge, 1.0, 0.0, 1.0, 0.0, -291.0, 348.0, -187.0, 452.0)


func _create_joker_celebration_effect() -> void:
	joker_celebration = Control.new()
	joker_celebration.name = "JokerCelebration"
	joker_celebration.visible = false
	joker_celebration.mouse_filter = Control.MOUSE_FILTER_IGNORE
	joker_celebration.z_index = 92
	_set_control_layout(joker_celebration, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 260.0, 260.0)
	joker_celebration.pivot_offset = Vector2(130.0, 130.0)

	joker_celebration_glow = ColorRect.new()
	joker_celebration_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var glow_shader := Shader.new()
	glow_shader.code = JOKER_CELEBRATION_GLOW_SHADER_CODE
	var glow_material := ShaderMaterial.new()
	glow_material.shader = glow_shader
	joker_celebration_glow.material = glow_material
	_set_control_layout(joker_celebration_glow, 0.0, 0.0, 1.0, 1.0, -18.0, -18.0, 18.0, 18.0)
	joker_celebration.add_child(joker_celebration_glow)

	joker_celebration_shadow = TextureRect.new()
	joker_celebration_shadow.texture = JOKER_CELEBRATION_TEXTURE
	joker_celebration_shadow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	joker_celebration_shadow.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	joker_celebration_shadow.modulate = Color(0.0, 0.0, 0.0, 0.38)
	joker_celebration_shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_set_control_layout(joker_celebration_shadow, 0.0, 0.0, 1.0, 1.0, 9.0, 13.0, 9.0, 13.0)
	joker_celebration.add_child(joker_celebration_shadow)

	joker_celebration_image = TextureRect.new()
	joker_celebration_image.texture = JOKER_CELEBRATION_TEXTURE
	joker_celebration_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	joker_celebration_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	joker_celebration_image.material = _create_social_emoji_shine_material()
	joker_celebration_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_set_control_layout(joker_celebration_image, 0.0, 0.0, 1.0, 1.0, 0.0, 0.0, 0.0, 0.0)
	joker_celebration.add_child(joker_celebration_image)

	joker_celebration_sparkles.clear()
	var sparkle_offsets := [
		Vector2(-104.0, -70.0),
		Vector2(101.0, -82.0),
		Vector2(-118.0, 5.0),
		Vector2(116.0, 14.0),
		Vector2(-84.0, 91.0),
		Vector2(91.0, 96.0),
		Vector2(-27.0, -115.0),
		Vector2(34.0, -108.0)
	]
	for sparkle_index in sparkle_offsets.size():
		var sparkle := Label.new()
		sparkle.text = "✦" if sparkle_index % 2 == 0 else "◆"
		sparkle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		sparkle.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		sparkle.add_theme_font_size_override("font_size", 22 if sparkle_index % 2 == 0 else 14)
		sparkle.add_theme_color_override("font_color", Color(1.0, 0.79, 0.24, 1.0))
		sparkle.add_theme_color_override("font_shadow_color", Color(0.18, 0.07, 0.0, 0.8))
		sparkle.add_theme_constant_override("shadow_offset_x", 2)
		sparkle.add_theme_constant_override("shadow_offset_y", 2)
		sparkle.mouse_filter = Control.MOUSE_FILTER_IGNORE
		sparkle.size = Vector2(32.0, 32.0)
		sparkle.pivot_offset = sparkle.size * 0.5
		sparkle.set_meta("target_offset", sparkle_offsets[sparkle_index])
		joker_celebration.add_child(sparkle)
		joker_celebration_sparkles.append(sparkle)

	players_container.add_child(joker_celebration)


func _show_joker_celebration(relative_slot: int) -> void:
	if (
		not is_instance_valid(joker_celebration)
		or relative_slot < 0
		or relative_slot >= avatar_badges.size()
	):
		return
	if is_instance_valid(joker_celebration_tween):
		joker_celebration_tween.kill()

	var target_position := _get_joker_celebration_position(relative_slot)
	joker_celebration.position = target_position + Vector2(0.0, 28.0)
	joker_celebration.scale = Vector2(0.28, 0.28)
	joker_celebration.rotation = deg_to_rad(-11.0)
	joker_celebration.modulate = Color(1.0, 1.0, 1.0, 0.0)
	joker_celebration.visible = true

	var center := joker_celebration.size * 0.5 - Vector2(16.0, 16.0)
	for sparkle in joker_celebration_sparkles:
		sparkle.position = center
		sparkle.scale = Vector2(0.2, 0.2)
		sparkle.modulate = Color(1.0, 1.0, 1.0, 0.0)

	var shine_material := joker_celebration_image.material as ShaderMaterial
	if shine_material != null:
		shine_material.set_shader_parameter("shine_progress", -0.5)

	joker_celebration_tween = create_tween().set_parallel(true)
	joker_celebration_tween.tween_property(joker_celebration, "position", target_position, 0.34).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	joker_celebration_tween.tween_property(joker_celebration, "scale", Vector2(1.08, 1.08), 0.32).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	joker_celebration_tween.tween_property(joker_celebration, "rotation", deg_to_rad(4.0), 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	joker_celebration_tween.tween_property(joker_celebration, "modulate:a", 1.0, 0.16)
	if shine_material != null:
		joker_celebration_tween.tween_property(shine_material, "shader_parameter/shine_progress", 2.25, 0.62)
	for sparkle in joker_celebration_sparkles:
		var target_offset: Vector2 = sparkle.get_meta("target_offset", Vector2.ZERO)
		joker_celebration_tween.tween_property(sparkle, "position", center + target_offset, 0.48).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		joker_celebration_tween.tween_property(sparkle, "scale", Vector2.ONE, 0.34).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		joker_celebration_tween.tween_property(sparkle, "modulate:a", 1.0, 0.18)
	joker_celebration_tween.set_parallel(false)
	joker_celebration_tween.tween_property(joker_celebration, "scale", Vector2.ONE, 0.13)
	joker_celebration_tween.parallel().tween_property(joker_celebration, "rotation", deg_to_rad(-2.0), 0.13)
	joker_celebration_tween.tween_property(joker_celebration, "rotation", deg_to_rad(2.0), 0.12)
	joker_celebration_tween.tween_property(joker_celebration, "rotation", 0.0, 0.12)
	joker_celebration_tween.tween_interval(0.58)
	joker_celebration_tween.tween_property(joker_celebration, "modulate:a", 0.0, 0.28)
	joker_celebration_tween.parallel().tween_property(joker_celebration, "scale", Vector2(0.82, 0.82), 0.28)
	joker_celebration_tween.parallel().tween_property(joker_celebration, "position", target_position + Vector2(0.0, -18.0), 0.28)
	joker_celebration_tween.tween_callback(_finish_joker_celebration)


func _get_joker_celebration_position(relative_slot: int) -> Vector2:
	var badge_center := avatar_badges[relative_slot].get_global_rect().get_center()
	var seat_offset := Vector2(0.0, -178.0)
	if relative_slot == 2:
		seat_offset = Vector2(0.0, 174.0)
	var desired_center := badge_center + seat_offset
	var viewport_size := get_viewport_rect().size
	var half_size := joker_celebration.size * 0.5
	desired_center.x = clampf(desired_center.x, half_size.x + 12.0, viewport_size.x - half_size.x - 12.0)
	desired_center.y = clampf(desired_center.y, half_size.y + 12.0, viewport_size.y - half_size.y - 12.0)
	return desired_center - half_size


func _finish_joker_celebration() -> void:
	joker_celebration_tween = null
	if is_instance_valid(joker_celebration):
		joker_celebration.visible = false


func _reset_joker_celebration() -> void:
	if is_instance_valid(joker_celebration_tween):
		joker_celebration_tween.kill()
	joker_celebration_tween = null
	if is_instance_valid(joker_celebration):
		joker_celebration.visible = false


func _did_local_joker_win_last_trick(winner_player_index: int) -> bool:
	if game.last_completed_trick_joker_mode != Trick.JokerMode.JOKER_WINS:
		return false
	for card_index in game.last_completed_trick_cards.size():
		if (
			game.last_completed_trick_cards[card_index].is_joker
			and card_index < game.last_completed_trick_played_by.size()
		):
			return game.last_completed_trick_played_by[card_index] == winner_player_index
	return false


func _did_network_joker_win_last_trick(snapshot: Dictionary, winner_player_index: int) -> bool:
	var completed_trick: Dictionary = snapshot.get("last_completed_trick", {})
	if int(completed_trick.get("joker_mode", Trick.JokerMode.NONE)) != Trick.JokerMode.JOKER_WINS:
		return false
	var cards: Array = completed_trick.get("cards", [])
	var played_by: Array = completed_trick.get("played_by", [])
	for card_index in cards.size():
		var card_data: Dictionary = cards[card_index] if cards[card_index] is Dictionary else {}
		if bool(card_data.get("is_joker", false)) and card_index < played_by.size():
			return int(played_by[card_index]) == winner_player_index
	return false


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
		score_sheet_close_button.disabled = false
	score_sheet_toggle_button.text = "📋 Расписка"
	score_sheet_toggle_button.disabled = false
	score_sheet_title.text = "Расписка: %d из %d раздач сыграно · полный план партии" % [round_history.size(), TOTAL_ROUND_COUNT]
	final_results_label.visible = _is_full_game_complete()

	if final_results_label.visible:
		final_results_label.text = _get_final_results_text()
	else:
		final_results_label.text = ""

	if not is_score_sheet_visible:
		return

	_clear_children(score_sheet_grid)
	score_sheet_grid.columns = 1

	var completed_rounds: Dictionary = {}
	for completed_round in round_history:
		completed_rounds[int(completed_round["round_number"])] = completed_round

	var header_row := _create_score_sheet_row()
	_add_score_sheet_cell(header_row, "№", true, false, false, SCORE_SHEET_NUMBER_COLUMN_WIDTH)
	_add_score_sheet_cell(header_row, "Режим", true, false, false, SCORE_SHEET_MODE_COLUMN_WIDTH)
	_add_score_sheet_cell(header_row, "Карт", true, false, false, SCORE_SHEET_CARDS_COLUMN_WIDTH)
	_add_score_sheet_cell(header_row, "Козырь", true, false, false, SCORE_SHEET_TRUMP_COLUMN_WIDTH)
	for player_index in game.players.size():
		_add_score_sheet_player_header(header_row, player_index)
	score_sheet_grid.add_child(header_row)

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

		var score_sheet_row := _create_score_sheet_row()
		_add_score_sheet_cell(score_sheet_row, str(round_number), false, is_current_round, is_future_round, SCORE_SHEET_NUMBER_COLUMN_WIDTH)
		_add_score_sheet_cell(score_sheet_row, str(round_plan["label"]), false, is_current_round, is_future_round, SCORE_SHEET_MODE_COLUMN_WIDTH)
		_add_score_sheet_cell(score_sheet_row, str(int(round_plan["cards_per_player"])), false, is_current_round, is_future_round, SCORE_SHEET_CARDS_COLUMN_WIDTH)
		_add_score_sheet_cell(score_sheet_row, trump_name, false, is_current_round, is_future_round, SCORE_SHEET_TRUMP_COLUMN_WIDTH)

		for player_index in game.players.size():
			var result_cells := PackedStringArray(["—", "—", "—"])
			if has_completed_round:
				var result_round_record: Dictionary = completed_rounds[round_number]
				var player_results: Array = result_round_record["players"]
				var player_result: Dictionary = player_results[player_index]
				var bid_text := str(player_result["bid"]) if bool(result_round_record["uses_bids"]) else "—"
				result_cells = PackedStringArray([
					bid_text,
					str(player_result["tricks_taken"]),
					_format_score(int(player_result["round_score"]))
				])
			elif is_current_round:
				var player := game.players[player_index]
				var current_bid_text := str(player.bid) if bool(round_plan["uses_bids"]) and player.bid >= 0 else "—"
				result_cells = PackedStringArray([current_bid_text, str(player.tricks_taken), "…"])

			_add_score_sheet_player_group(score_sheet_row, player_index, result_cells, is_current_round, is_future_round)

		score_sheet_grid.add_child(score_sheet_row)

	var total_row := _create_score_sheet_row()
	_add_score_sheet_cell(total_row, "Итого", false, false, false, SCORE_SHEET_NUMBER_COLUMN_WIDTH, true)
	_add_score_sheet_cell(total_row, "", false, false, false, SCORE_SHEET_MODE_COLUMN_WIDTH, true)
	_add_score_sheet_cell(total_row, "", false, false, false, SCORE_SHEET_CARDS_COLUMN_WIDTH, true)
	_add_score_sheet_cell(total_row, "", false, false, false, SCORE_SHEET_TRUMP_COLUMN_WIDTH, true)
	for player_index in game.players.size():
		_add_score_sheet_player_group(
			total_row,
			player_index,
			PackedStringArray(["", "", "Счёт: %d" % game.players[player_index].total_score]),
			false,
			false,
			true
		)
	score_sheet_grid.add_child(total_row)


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


func _create_score_sheet_row() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 4)
	return row


func _add_score_sheet_player_header(row: HBoxContainer, player_index: int, display_name: String = "") -> void:
	var group := PanelContainer.new()
	group.custom_minimum_size = Vector2(SCORE_SHEET_PLAYER_GROUP_WIDTH, 70.0)
	group.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	group.add_theme_stylebox_override("panel", _create_score_sheet_player_group_style(player_index, true))

	var group_content := VBoxContainer.new()
	group_content.add_theme_constant_override("separation", 2)
	group.add_child(group_content)

	var name_label := Label.new()
	name_label.text = display_name if not display_name.is_empty() else game.players[player_index].display_name
	name_label.custom_minimum_size = Vector2(SCORE_SHEET_PLAYER_GROUP_WIDTH, 24.0)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.add_theme_color_override("font_color", Color(0.98, 0.88, 0.58, 1.0))
	group_content.add_child(name_label)

	var columns_row := HBoxContainer.new()
	columns_row.add_theme_constant_override("separation", 4)
	group_content.add_child(columns_row)
	_add_score_sheet_cell(columns_row, "Заказ", true, false, false, SCORE_SHEET_BID_COLUMN_WIDTH)
	_add_score_sheet_cell(columns_row, "Взято", true, false, false, SCORE_SHEET_TRICKS_COLUMN_WIDTH)
	_add_score_sheet_cell(columns_row, "Δ счёта", true, false, false, SCORE_SHEET_SCORE_COLUMN_WIDTH)
	row.add_child(group)


func _add_score_sheet_player_group(
	row: HBoxContainer,
	player_index: int,
	cell_texts: PackedStringArray,
	is_current_round: bool,
	is_future_round: bool,
	is_total_row := false
) -> void:
	var group := PanelContainer.new()
	group.custom_minimum_size = Vector2(SCORE_SHEET_PLAYER_GROUP_WIDTH, 48.0 if is_total_row else 42.0)
	group.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	group.add_theme_stylebox_override("panel", _create_score_sheet_player_group_style(player_index, false, is_total_row))

	var group_content := HBoxContainer.new()
	group_content.add_theme_constant_override("separation", 4)
	group.add_child(group_content)
	_add_score_sheet_cell(group_content, cell_texts[0], false, is_current_round, is_future_round, SCORE_SHEET_BID_COLUMN_WIDTH, is_total_row)
	_add_score_sheet_cell(group_content, cell_texts[1], false, is_current_round, is_future_round, SCORE_SHEET_TRICKS_COLUMN_WIDTH, is_total_row)
	_add_score_sheet_cell(group_content, cell_texts[2], false, is_current_round, is_future_round, SCORE_SHEET_SCORE_COLUMN_WIDTH, is_total_row)
	row.add_child(group)


func _create_score_sheet_player_group_style(player_index: int, is_header: bool, is_total_row := false) -> StyleBoxFlat:
	var backgrounds: Array[Color] = [
		Color(0.024, 0.105, 0.066, 0.78),
		Color(0.03, 0.072, 0.11, 0.78),
		Color(0.09, 0.055, 0.095, 0.78),
		Color(0.09, 0.072, 0.032, 0.78)
	]
	var background_color: Color = backgrounds[player_index % backgrounds.size()]
	if is_header:
		background_color = background_color.lightened(0.16)
	elif is_total_row:
		background_color = background_color.lightened(0.08)

	var border_color := Color(0.78, 0.62, 0.24, 0.88 if is_header or is_total_row else 0.42)
	var style := _create_flat_style(background_color, border_color, 1, 4, 0)
	style.content_margin_left = 3.0
	style.content_margin_top = 2.0
	style.content_margin_right = 3.0
	style.content_margin_bottom = 2.0
	return style


func _add_score_sheet_cell(
	parent: Container,
	text: String,
	is_header := false,
	is_current_round := false,
	is_future_round := false,
	minimum_width := 82.0,
	is_total_row := false
) -> void:
	var cell := Label.new()
	cell.custom_minimum_size = Vector2(minimum_width, 48.0 if is_header or is_total_row else 42.0)
	cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cell.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cell.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cell.autowrap_mode = 2
	cell.text = text
	cell.add_theme_font_size_override("font_size", 14 if is_header else 13)

	if is_header:
		cell.add_theme_color_override("font_color", Color(0.97, 0.86, 0.55))
	elif is_total_row:
		cell.add_theme_font_size_override("font_size", 15)
		cell.add_theme_color_override("font_color", Color(0.96, 0.42, 0.34) if text.contains("-") else Color(0.97, 0.84, 0.38))
	elif is_current_round:
		cell.add_theme_color_override("font_color", Color(1.0, 0.83, 0.34))
	elif is_future_round:
		cell.add_theme_color_override("font_color", Color(0.48, 0.64, 0.54))
	else:
		cell.add_theme_color_override("font_color", Color(0.86, 0.94, 0.87))

	parent.add_child(cell)


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
	var standings := _get_final_standings()
	var result_lines := PackedStringArray()
	result_lines.append("Итоги партии")

	for standing_index in standings.size():
		var standing: Dictionary = standings[standing_index]
		var place: int = int(standing["place"])
		var shares_place: bool = bool(standing["shares_place"])
		var place_prefix := "🏆" if place == 1 and not shares_place else "🤝" if shares_place else "•"
		var place_text := _get_place_text(place, shares_place)

		result_lines.append("%s %s: %s — %d очк. · %d вз. · точных заказов: %d" % [
			place_prefix,
			place_text,
			standing["name"],
			standing["score"],
			standing["tricks_taken"],
			standing["exact_orders"]
		])

	return "\n".join(result_lines)


func _get_final_standings() -> Array[Dictionary]:
	var standings: Array[Dictionary] = []

	for player in game.players:
		standings.append({
			"player_id": player.player_id,
			"name": player.display_name,
			"score": player.total_score,
			"tricks_taken": _get_total_tricks_for_player(player.player_id),
			"exact_orders": player.exact_orders_completed,
			"place": 0,
			"shares_place": false
		})

	standings.sort_custom(func(left: Dictionary, right: Dictionary) -> bool:
		if left["score"] != right["score"]:
			return left["score"] > right["score"]

		return left["exact_orders"] > right["exact_orders"]
	)

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
		standing["place"] = place
		standing["shares_place"] = shares_place

	return standings


func _get_human_final_standing() -> Dictionary:
	for standing in _get_final_standings():
		if int(standing["player_id"]) == HUMAN_PLAYER_INDEX:
			return standing

	return {}


func _get_human_final_summary_text() -> String:
	var standing := _get_human_final_standing()
	if standing.is_empty():
		return "Твой итог: результат пока недоступен."

	return "Твой результат: %s · счёт %d · точных заказов: %d" % [
		_get_place_text(int(standing["place"]), bool(standing["shares_place"])),
		int(standing["score"]),
		int(standing["exact_orders"])
	]


func _record_completed_game_statistics() -> void:
	if game_statistics_recorded_for_current_session:
		return

	var standing := _get_human_final_standing()
	if standing.is_empty():
		return

	game_statistics_recorded_for_current_session = true
	var place: int = clampi(int(standing["place"]), 1, PLAYER_NAMES.size())
	var score: int = int(standing["score"])
	local_statistics["completed_games"] = int(local_statistics["completed_games"]) + 1

	match place:
		1:
			local_statistics["wins"] = int(local_statistics["wins"]) + 1
		2:
			local_statistics["second_places"] = int(local_statistics["second_places"]) + 1
		3:
			local_statistics["third_places"] = int(local_statistics["third_places"]) + 1
		_:
			local_statistics["fourth_places"] = int(local_statistics["fourth_places"]) + 1

	if not bool(local_statistics["has_best_score"]) or score > int(local_statistics["best_score"]):
		local_statistics["best_score"] = score
		local_statistics["has_best_score"] = true

	local_statistics["last_place"] = place
	local_statistics["last_score"] = score
	local_statistics["last_exact_orders"] = int(standing["exact_orders"])
	local_statistics["last_shared_place"] = bool(standing["shares_place"])
	_save_persistent_settings()


func _get_place_text(place: int, shares_place := false) -> String:
	if place <= 0:
		return "место не определено"

	var place_text := "%d-е место" % place
	if shares_place:
		place_text += " (ничья)"
	return place_text


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
	if match_history_mode == NetworkHost.HistoryMode.LAST_TRICK_ONLY:
		history_label.text = _format_suit_symbols_for_light_ui("\n".join(_get_restricted_local_history_lines()))
		call_deferred("_scroll_round_history_to_bottom")
		return
	if recent_actions.is_empty():
		history_label.text = "Ход раздачи: —"
		return

	history_label.text = _format_suit_symbols_for_light_ui("Ход раздачи\n%s" % "\n".join(recent_actions))
	call_deferred("_scroll_round_history_to_bottom")


func _get_restricted_local_history_lines() -> PackedStringArray:
	var lines := PackedStringArray(["Последняя взятка"])
	if game.last_completed_trick_cards.is_empty():
		lines.append("Завершённых взяток пока нет.")
	else:
		if game.last_trick_winner_index >= 0 and game.last_trick_winner_index < game.players.size():
			lines.append("Забрал: %s" % game.players[game.last_trick_winner_index].display_name)
		for card_index in mini(game.last_completed_trick_cards.size(), game.last_completed_trick_played_by.size()):
			var player_index: int = game.last_completed_trick_played_by[card_index]
			if player_index >= 0 and player_index < game.players.size():
				lines.append("%s — %s" % [
					game.players[player_index].display_name,
					game.last_completed_trick_cards[card_index].get_card_name()
				])

	lines.append("")
	lines.append("Текущая взятка")
	if game.active_trick == null or game.active_trick.played_cards.is_empty():
		lines.append("На столе пока нет карт.")
	else:
		for card_index in mini(game.active_trick.played_cards.size(), game.active_trick.played_by.size()):
			var player_index: int = game.active_trick.played_by[card_index]
			if player_index >= 0 and player_index < game.players.size():
				lines.append("%s — %s" % [
					game.players[player_index].display_name,
					game.active_trick.played_cards[card_index].get_card_name()
				])
	return lines


func _refresh_round_history_panel() -> void:
	round_history_panel.visible = is_round_history_visible
	round_history_toggle_button.text = "Последняя взятка" if match_history_mode == NetworkHost.HistoryMode.LAST_TRICK_ONLY else "История"
	round_history_toggle_button.tooltip_text = (
		"Скрыть последнюю взятку" if is_round_history_visible else "Показать последнюю взятку"
	) if match_history_mode == NetworkHost.HistoryMode.LAST_TRICK_ONLY else (
		"Скрыть историю" if is_round_history_visible else "Показать историю"
	)
	round_history_toggle_button.disabled = false


func _refresh_round_results() -> void:
	var round_is_finished := game.current_round.state == Round.State.FINISHED
	round_results_panel.visible = round_is_finished

	if not round_is_finished:
		round_results_title.text = "ИТОГИ РАЗДАЧИ"
		round_results_label.text = ""
		return

	var full_game_complete := _is_full_game_complete()
	round_results_title.text = "ИТОГИ ПАРТИИ" if full_game_complete else "ИТОГИ РАЗДАЧИ"
	round_results_label.text = (
		_format_final_standings_bbcode(_get_final_standings())
		if full_game_complete
		else _get_local_round_result_bbcode()
	)
	var plain_text := (
		_get_final_results_text().trim_prefix("Итоги партии\n")
		if full_game_complete
		else round_results_label.get_parsed_text()
	)
	_fit_round_results_panel(plain_text)


func _fit_round_results_panel(plain_text: String) -> void:
	var result_lines := plain_text.split("\n", false)
	var content_font: Font = round_results_label.get_theme_font("normal_font")
	var widest_line := 0.0
	for result_line in result_lines:
		widest_line = maxf(
			widest_line,
			content_font.get_string_size(
				str(result_line),
				HORIZONTAL_ALIGNMENT_LEFT,
				-1.0,
				20
			).x
		)

	var parent_width := ROUND_RESULTS_PANEL_MAX_WIDTH + 80.0
	var parent_control := round_results_panel.get_parent_control()
	if is_instance_valid(parent_control) and parent_control.size.x > 0.0:
		parent_width = parent_control.size.x
	var maximum_width := minf(
		ROUND_RESULTS_PANEL_MAX_WIDTH,
		maxf(ROUND_RESULTS_PANEL_MIN_WIDTH, parent_width - 80.0)
	)
	var panel_width := clampf(
		ceilf(widest_line + ROUND_RESULTS_PANEL_HORIZONTAL_PADDING),
		ROUND_RESULTS_PANEL_MIN_WIDTH,
		maximum_width
	)
	var row_count := maxi(1, result_lines.size())
	var panel_height := ROUND_RESULTS_PANEL_FIXED_HEIGHT + row_count * ROUND_RESULTS_PANEL_ROW_HEIGHT
	_set_control_layout(
		round_results_panel,
		0.5,
		0.0,
		0.5,
		0.0,
		-panel_width * 0.5,
		ROUND_RESULTS_PANEL_TOP,
		panel_width * 0.5,
		ROUND_RESULTS_PANEL_TOP + panel_height
	)


func _get_local_round_result_bbcode() -> String:
	if round_history.is_empty():
		return action_text.trim_prefix("Раздача завершена.\n")
	var completed_round: Dictionary = round_history.back()
	var uses_bids := bool(completed_round.get("uses_bids", true))
	var player_results: Array = completed_round.get("players", [])
	var result_lines: PackedStringArray = []
	for player_index in game.players.size():
		var player := game.players[player_index]
		var player_result: Dictionary = player_results[player_index] if player_index < player_results.size() and player_results[player_index] is Dictionary else {}
		var round_score := int(player_result.get("round_score", 0))
		result_lines.append(_format_round_result_bbcode(
			player.display_name,
			int(player_result.get("bid", player.bid)),
			int(player_result.get("tricks_taken", player.tricks_taken)),
			round_score,
			player.total_score,
			uses_bids
		))
	return "\n".join(result_lines)


func _scroll_round_history_to_bottom() -> void:
	var scroll_bar: VScrollBar = round_history_scroll.get_v_scroll_bar()
	round_history_scroll.scroll_vertical = int(scroll_bar.max_value)


func _refresh_bid_controls() -> void:
	_clear_children(bid_controls)

	if is_bug_report_review_mode:
		_add_bug_report_timeline_controls()
		return

	if (
		is_processing_automatic_actions
		or game.current_round.state != Round.State.BIDDING
		or game.current_round.current_player_index != HUMAN_PLAYER_INDEX
	):
		return

	for bid in game.current_round.cards_per_player + 1:
		var bid_button := Button.new()
		bid_button.text = "Заказать %d" % bid
		bid_button.custom_minimum_size = Vector2(104.0, 40.0)
		_apply_table_action_button_style(bid_button)
		bid_button.disabled = not game.current_round.can_place_bid(HUMAN_PLAYER_INDEX, bid)
		bid_button.pressed.connect(_on_bid_pressed.bind(bid))
		bid_controls.add_child(bid_button)


func _add_bug_report_timeline_controls() -> void:
	if bug_report_review_timeline.is_empty():
		return

	var previous_button := Button.new()
	previous_button.text = "← Предыдущее"
	previous_button.custom_minimum_size = Vector2(150.0, 40.0)
	_apply_table_action_button_style(previous_button)
	previous_button.disabled = bug_report_review_index <= 0
	previous_button.pressed.connect(_on_bug_report_timeline_previous_pressed)
	bid_controls.add_child(previous_button)

	var state_label := Label.new()
	var timeline_item: Dictionary = bug_report_review_timeline[bug_report_review_index]
	state_label.text = "%d/%d · %s" % [
		bug_report_review_index + 1,
		bug_report_review_timeline.size(),
		str(timeline_item.get("label", "Состояние"))
	]
	state_label.custom_minimum_size = Vector2(250.0, 40.0)
	state_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	state_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	state_label.clip_text = true
	state_label.tooltip_text = state_label.text
	state_label.add_theme_font_size_override("font_size", 15)
	state_label.add_theme_color_override("font_color", Color(0.92, 0.87, 0.66, 1.0))
	bid_controls.add_child(state_label)

	var next_button := Button.new()
	next_button.text = "Следующее →"
	next_button.custom_minimum_size = Vector2(150.0, 40.0)
	_apply_table_action_button_style(next_button)
	next_button.disabled = bug_report_review_index >= bug_report_review_timeline.size() - 1
	next_button.pressed.connect(_on_bug_report_timeline_next_pressed)
	bid_controls.add_child(next_button)


func _refresh_joker_controls() -> void:
	_clear_children(joker_controls)

	if pending_joker_card == null:
		# Верхний слой выбора Джокера не должен перекрывать обычные кнопки,
		# когда игрок ещё не выбирает его условие.
		joker_controls.visible = false
		joker_controls.mouse_filter = Control.MOUSE_FILTER_IGNORE
		return

	joker_controls.visible = true
	joker_controls.mouse_filter = Control.MOUSE_FILTER_IGNORE if is_bug_report_review_mode else Control.MOUSE_FILTER_STOP
	_place_joker_controls()

	if game.active_trick == null:
		if pending_joker_suit < 0:
			for suit in Card.Suit.values():
				_add_joker_suit_button("Объявить %s" % _get_suit_symbol(suit), suit)
			_add_joker_cancel_button()
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
		_add_joker_cancel_button()
	else:
		_add_joker_choice_button("Джокер забирает", Trick.JokerMode.JOKER_WINS)
		_add_joker_choice_button("Сбросить Джокер (не забирает)", Trick.JokerMode.NORMAL_CARD_WINS)
		_add_joker_cancel_button()


func _place_joker_controls() -> void:
	var is_leading_joker_choice := pending_joker_card != null and game.active_trick == null

	if is_leading_joker_choice:
		joker_controls.columns = 1
		_set_control_layout(joker_controls, 0.0, 1.0, 0.0, 1.0, 64.0, -510.0, 444.0, -128.0)
		return

	joker_controls.columns = 3
	_set_control_layout(joker_controls, 0.5, 1.0, 0.5, 1.0, -390.0, -270.0, 390.0, -218.0)


func _refresh_hand() -> void:
	_clear_children(hand_container)

	if _is_dark_round() and not game.cards_are_dealt:
		var hidden_cards_label := Label.new()
		hidden_cards_label.text = "Карты будут сданы после того, как все игроки сделают заказ."
		hidden_cards_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hidden_cards_label.add_theme_font_size_override("font_size", 16)
		hand_container.add_child(hidden_cards_label)
		return

	var human_player := game.players[HUMAN_PLAYER_INDEX]
	var displayed_cards := _sort_cards_for_display(human_player.hand, game.current_round.trump, hand_sort_mode)

	for display_index in displayed_cards.size():
		var card: Card = displayed_cards[display_index]
		var card_view := CardView.new()
		card_view.set_card(card)
		card_view.set_hand_presentation(display_index, displayed_cards.size())
		card_view.set_interactive(
			true,
			is_bug_report_review_mode or not _is_human_turn() or not _is_card_available_to_human(card) or pending_joker_card != null
		)
		card_view.card_pressed.connect(_on_card_pressed)
		hand_container.add_child(card_view)


func _refresh_hand_sort_controls() -> void:
	hand_sort_by_suit_button.disabled = is_bug_report_review_mode or is_processing_automatic_actions or hand_sort_mode == HandSortMode.BY_SUIT
	hand_sort_trumps_left_button.disabled = is_bug_report_review_mode or is_processing_automatic_actions or hand_sort_mode == HandSortMode.TRUMPS_LEFT


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
	undo_button.disabled = not _can_request_undo()
	undo_button.tooltip_text = (
		"За это решение можно запросить ещё %d возврат(а)." % (UNDO_REQUESTS_PER_DECISION_LIMIT - undo_requests_for_current_decision)
		if not undo_button.disabled
		else "Возврат сейчас недоступен. На одно твоё решение даётся не больше двух запросов."
	)


func _can_request_undo() -> bool:
	return (
		not is_bug_report_review_mode
		and not is_processing_automatic_actions
		and not is_undo_vote_in_progress
		and not test_checkpoints.is_empty()
		and undo_requests_for_current_decision < UNDO_REQUESTS_PER_DECISION_LIMIT
		and game.current_round.state != Round.State.FINISHED
	)


func _reset_undo_vote_states() -> void:
	undo_vote_states.resize(PLAYER_NAMES.size())
	undo_vote_states.fill(UndoVoteState.NONE)
	_refresh_undo_vote_badges()


func _refresh_undo_vote_badges() -> void:
	for player_index in undo_vote_badges.size():
		var vote_state: int = undo_vote_states[player_index] if player_index < undo_vote_states.size() else UndoVoteState.NONE
		var vote_badge := undo_vote_badges[player_index]
		vote_badge.visible = player_index != HUMAN_PLAYER_INDEX and vote_state != UndoVoteState.NONE
		if not vote_badge.visible:
			continue

		var is_approved := vote_state == UndoVoteState.APPROVED
		vote_badge.add_theme_stylebox_override("panel", undo_vote_approved_style if is_approved else undo_vote_rejected_style)
		undo_vote_labels[player_index].text = "✓" if is_approved else "✕"
		undo_vote_labels[player_index].add_theme_color_override(
			"font_color",
			Color(0.9, 1.0, 0.86, 1.0) if is_approved else Color(1.0, 0.9, 0.86, 1.0)
		)
		vote_badge.tooltip_text = "Согласен вернуть ход" if is_approved else "Не согласен вернуть ход"


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

		var stats_label := RichTextLabel.new()
		stats_label.bbcode_enabled = true
		stats_label.fit_content = true
		stats_label.scroll_active = false
		stats_label.custom_minimum_size = Vector2(0.0, 32.0)
		stats_label.add_theme_font_size_override("normal_font_size", 17)
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
		card_view.set_table_presentation(player_index)
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

			if not _add_card_back_artwork(card_back):
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

		if not _add_card_back_artwork(card_back):
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
	deck_trump_panel.position = Vector2(54.0, 20.0)
	deck_trump_panel.size = Vector2(64.0, 96.0)
	deck_trump_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	deck_trump_panel.add_theme_stylebox_override("panel", deck_trump_card_style)

	deck_trump_artwork = TextureRect.new()
	deck_trump_artwork.set_anchors_preset(Control.PRESET_FULL_RECT)
	deck_trump_artwork.offset_left = 4.0
	deck_trump_artwork.offset_top = 4.0
	deck_trump_artwork.offset_right = -4.0
	deck_trump_artwork.offset_bottom = -4.0
	deck_trump_artwork.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	deck_trump_artwork.stretch_mode = TextureRect.STRETCH_SCALE
	deck_trump_artwork.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	deck_trump_artwork.mouse_filter = Control.MOUSE_FILTER_IGNORE
	deck_trump_artwork.visible = false
	deck_trump_panel.add_child(deck_trump_artwork)

	deck_trump_label = Label.new()
	deck_trump_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	deck_trump_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	deck_trump_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	deck_trump_panel.add_child(deck_trump_label)
	deck_visual.add_child(deck_trump_panel)

	deck_caption_label = Label.new()
	deck_caption_label.position = Vector2(-48.0, 120.0)
	deck_caption_label.size = Vector2(220.0, 24.0)
	deck_caption_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	deck_caption_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
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
		var trump_texture: Texture2D = CardArtworkResource.get_face_texture(trump_card)
		deck_trump_artwork.texture = trump_texture
		deck_trump_artwork.visible = trump_texture != null
		deck_trump_label.visible = trump_texture == null
		deck_trump_label.text = trump_card.get_card_name()
		deck_trump_label.add_theme_font_size_override("font_size", 17)
		deck_trump_label.add_theme_color_override(
			"font_color",
			Color(0.74, 0.08, 0.06, 1.0) if trump_card.suit == Card.Suit.HEARTS or trump_card.suit == Card.Suit.DIAMONDS else Color(0.08, 0.08, 0.07, 1.0)
		)
		deck_trump_panel.tooltip_text = "Открытая карта определяет козырь."
		deck_caption_label.text = (
			"Открытый Джокер · бескозырка"
			if trump_card.is_joker
			else "Открытый козырь · в колоде: %d" % game.deck.cards_left()
		)
		return

	var trump_name := game.current_round.get_trump_name()
	var scheduled_trump_texture: Texture2D = CardArtworkResource.get_scheduled_trump_texture(game.current_round.trump)
	deck_trump_artwork.texture = scheduled_trump_texture
	deck_trump_artwork.visible = scheduled_trump_texture != null
	deck_trump_label.visible = scheduled_trump_texture == null
	deck_trump_label.text = "—" if game.current_round.trump == Round.TrumpSuit.NONE else trump_name
	deck_trump_label.add_theme_font_size_override("font_size", 32)
	deck_trump_label.add_theme_color_override("font_color", Color(0.08, 0.08, 0.07, 1.0))
	deck_trump_panel.tooltip_text = "Козырь задан правилами этой раздачи."
	deck_caption_label.text = "Без козыря" if game.current_round.trump == Round.TrumpSuit.NONE else "Козырь задан: %s" % trump_name


func _add_card_back_artwork(card_back: Control) -> bool:
	var back_texture: Texture2D = CardArtworkResource.get_back_texture()
	if back_texture == null:
		return false

	var texture_rect := TextureRect.new()
	texture_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	texture_rect.offset_left = 2.0
	texture_rect.offset_top = 2.0
	texture_rect.offset_right = -2.0
	texture_rect.offset_bottom = -2.0
	texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_rect.stretch_mode = TextureRect.STRETCH_SCALE
	texture_rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	texture_rect.texture = back_texture
	texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card_back.add_child(texture_rect)
	return true


func _create_table_markers() -> void:
	dealer_marker = _create_table_marker("D", "Сдающий", dealer_marker_style, 18)
	lead_marker = _create_table_marker("Заход", "Начинает текущую взятку", lead_marker_style, 14)
	players_container.add_child(dealer_marker)
	players_container.add_child(lead_marker)


func _create_social_controls_container() -> void:
	social_controls_container = VBoxContainer.new()
	social_controls_container.name = "SocialControls"
	social_controls_container.alignment = BoxContainer.ALIGNMENT_CENTER
	social_controls_container.add_theme_constant_override("separation", 2)
	social_controls_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	social_controls_container.z_index = 30
	_set_control_layout(
		social_controls_container,
		0.5,
		1.0,
		0.5,
		1.0,
		112.0,
		-438.0,
		156.0,
		-314.0
	)
	players_container.add_child(social_controls_container)


func _create_chat_controls() -> void:
	chat_toggle_button = Button.new()
	chat_toggle_button.name = "ChatToggleButton"
	chat_toggle_button.text = "💬"
	chat_toggle_button.tooltip_text = "Открыть чат стола"
	chat_toggle_button.visible = false
	chat_toggle_button.z_index = 30
	chat_toggle_button.mouse_filter = Control.MOUSE_FILTER_STOP
	chat_toggle_button.custom_minimum_size = Vector2(44.0, 40.0)
	chat_toggle_button.add_theme_font_size_override("font_size", 22)
	_apply_bare_social_icon_button_style(chat_toggle_button)
	chat_toggle_button.pressed.connect(_on_chat_toggle_pressed)
	social_controls_container.add_child(chat_toggle_button)

	chat_panel = PanelContainer.new()
	chat_panel.name = "NetworkChatPanel"
	chat_panel.visible = false
	chat_panel.z_index = 33
	chat_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var chat_style := _create_flat_style(Color(0.012, 0.05, 0.035, 0.985), Color(0.63, 0.47, 0.16, 0.96), 2, 10, 4)
	chat_style.content_margin_left = 12.0
	chat_style.content_margin_top = 10.0
	chat_style.content_margin_right = 12.0
	chat_style.content_margin_bottom = 10.0
	chat_panel.add_theme_stylebox_override("panel", chat_style)
	_set_control_layout(chat_panel, 0.5, 1.0, 0.5, 1.0, 168.0, -598.0, 558.0, -314.0)
	players_container.add_child(chat_panel)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 7)
	chat_panel.add_child(content)

	var header := HBoxContainer.new()
	content.add_child(header)
	var title := Label.new()
	title.text = "ЧАТ СТОЛА"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 17)
	title.add_theme_color_override("font_color", Color(1.0, 0.84, 0.42, 1.0))
	header.add_child(title)
	var close_button := Button.new()
	close_button.text = "×"
	close_button.tooltip_text = "Закрыть чат"
	close_button.custom_minimum_size = Vector2(32.0, 28.0)
	close_button.add_theme_font_size_override("font_size", 22)
	_apply_bare_social_icon_button_style(close_button)
	close_button.pressed.connect(_close_chat_panel)
	header.add_child(close_button)

	chat_messages_scroll = ScrollContainer.new()
	chat_messages_scroll.name = "ChatMessagesScroll"
	chat_messages_scroll.custom_minimum_size = Vector2(0.0, 166.0)
	chat_messages_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	chat_messages_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(chat_messages_scroll)
	chat_messages_container = VBoxContainer.new()
	chat_messages_container.name = "ChatMessages"
	chat_messages_container.custom_minimum_size = Vector2(340.0, 0.0)
	chat_messages_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	chat_messages_container.add_theme_constant_override("separation", 5)
	chat_messages_scroll.add_child(chat_messages_container)

	var input_row := HBoxContainer.new()
	input_row.add_theme_constant_override("separation", 7)
	content.add_child(input_row)
	chat_input = LineEdit.new()
	chat_input.name = "ChatInput"
	chat_input.placeholder_text = "Сообщение всем игрокам…"
	chat_input.max_length = NetworkHost.CHAT_MESSAGE_MAX_LENGTH
	chat_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	chat_input.custom_minimum_size = Vector2(0.0, 38.0)
	chat_input.add_theme_font_size_override("font_size", 15)
	chat_input.text_submitted.connect(_on_chat_text_submitted)
	input_row.add_child(chat_input)
	chat_send_button = Button.new()
	chat_send_button.name = "ChatSendButton"
	chat_send_button.text = "Отправить"
	chat_send_button.custom_minimum_size = Vector2(94.0, 38.0)
	chat_send_button.add_theme_font_size_override("font_size", 14)
	_apply_table_action_button_style(chat_send_button)
	chat_send_button.pressed.connect(_on_chat_send_pressed)
	input_row.add_child(chat_send_button)

	chat_status_label = Label.new()
	chat_status_label.text = "До %d символов · не чаще одного сообщения в секунду" % NetworkHost.CHAT_MESSAGE_MAX_LENGTH
	chat_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	chat_status_label.add_theme_font_size_override("font_size", 12)
	chat_status_label.add_theme_color_override("font_color", Color(0.68, 0.8, 0.7, 1.0))
	content.add_child(chat_status_label)
	_refresh_network_chat_log()


func _can_show_network_chat() -> bool:
	return _is_steam_p2p_main_table_active() and not _get_network_main_snapshot().is_empty()


func _on_chat_toggle_pressed() -> void:
	if not _can_show_network_chat():
		return
	if chat_panel.visible:
		_close_chat_panel()
		return
	reaction_picker.visible = false
	_close_sticker_picker()
	soundpad_picker.visible = false
	chat_panel.visible = true
	chat_unread_count = 0
	_refresh_chat_controls()
	chat_input.grab_focus()
	call_deferred("_scroll_network_chat_to_bottom")


func _close_chat_panel() -> void:
	if is_instance_valid(chat_panel):
		chat_panel.visible = false
	_refresh_chat_controls()


func _on_chat_text_submitted(_submitted_text: String) -> void:
	_on_chat_send_pressed()


func _on_chat_send_pressed() -> void:
	if not _can_show_network_chat() or not is_instance_valid(chat_input):
		return
	var message := chat_input.text.replace("\r", " ").replace("\n", " ").replace("\t", " ").strip_edges()
	if message.is_empty():
		chat_status_label.text = "Введите сообщение."
		return
	var now := Time.get_ticks_msec()
	if now < chat_next_send_milliseconds:
		chat_status_label.text = "Слишком быстро — подождите секунду."
		return
	if _submit_network_social_action({"kind": "chat", "message": message}):
		chat_input.clear()
		chat_next_send_milliseconds = now + CHAT_LOCAL_SEND_COOLDOWN_MILLISECONDS
		chat_status_label.text = "Сообщение отправлено."
	else:
		chat_status_label.text = "Сообщение не отправлено: сетевой стол пока недоступен."


func _rebuild_network_chat_messages(events: Array, snapshot: Dictionary) -> void:
	network_chat_messages.clear()
	var players_by_index := _get_network_players_by_index(snapshot)
	for event_variant in events:
		if not (event_variant is Dictionary):
			continue
		var event: Dictionary = event_variant
		if str(event.get("kind", "")) != "chat":
			continue
		var actor_player_index := int(event.get("actor_player_index", -1))
		var player_name := "Игрок %d" % (actor_player_index + 1)
		if players_by_index.has(actor_player_index):
			player_name = str((players_by_index[actor_player_index] as Dictionary).get("display_name", player_name))
		_append_network_chat_message(event, player_name, false)
	chat_unread_count = 0
	_refresh_network_chat_log()


func _append_network_chat_message(event: Dictionary, player_name: String, refresh_log := true) -> void:
	var event_id := int(event.get("event_id", -1))
	for message_data in network_chat_messages:
		if int(message_data.get("event_id", -2)) == event_id:
			return
	network_chat_messages.append({
		"event_id": event_id,
		"actor_player_index": int(event.get("actor_player_index", -1)),
		"player_name": player_name,
		"message": str(event.get("message", ""))
	})
	while network_chat_messages.size() > CHAT_VISIBLE_MESSAGE_LIMIT:
		network_chat_messages.pop_front()
	if refresh_log:
		_refresh_network_chat_log()


func _refresh_network_chat_log() -> void:
	if not is_instance_valid(chat_messages_container):
		return
	_clear_children(chat_messages_container)
	if network_chat_messages.is_empty():
		var empty_label := Label.new()
		empty_label.text = "Сообщений пока нет."
		empty_label.add_theme_font_size_override("font_size", 14)
		empty_label.add_theme_color_override("font_color", Color(0.66, 0.78, 0.68, 1.0))
		chat_messages_container.add_child(empty_label)
		return
	for message_data in network_chat_messages:
		var message_label := Label.new()
		message_label.text = "%s: %s" % [
			str(message_data.get("player_name", "Игрок")),
			str(message_data.get("message", ""))
		]
		message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		message_label.add_theme_font_size_override("font_size", 14)
		message_label.add_theme_color_override("font_color", Color(0.91, 0.96, 0.91, 1.0))
		chat_messages_container.add_child(message_label)
	call_deferred("_scroll_network_chat_to_bottom")


func _scroll_network_chat_to_bottom() -> void:
	if not is_instance_valid(chat_messages_scroll):
		return
	await get_tree().process_frame
	if is_instance_valid(chat_messages_scroll):
		chat_messages_scroll.scroll_vertical = roundi(chat_messages_scroll.get_v_scroll_bar().max_value)


func _refresh_chat_controls() -> void:
	if not is_instance_valid(chat_toggle_button) or not is_instance_valid(chat_panel):
		return
	var can_show := _can_show_network_chat()
	chat_toggle_button.visible = can_show
	if not can_show:
		chat_panel.visible = false
	chat_toggle_button.text = "💬" if chat_unread_count <= 0 else "💬 %d" % chat_unread_count
	chat_toggle_button.tooltip_text = (
		"Чат стола · новых сообщений: %d" % chat_unread_count
		if chat_unread_count > 0
		else "Открыть чат стола"
	)
	if is_instance_valid(chat_input):
		chat_input.editable = can_show
	if is_instance_valid(chat_send_button):
		chat_send_button.disabled = not can_show


func _get_social_emoji_texture(symbol: String) -> Texture2D:
	if social_emoji_texture_cache.has(symbol):
		return social_emoji_texture_cache[symbol] as Texture2D
	var texture_path := str(FLUENT_EMOJI_TEXTURE_PATHS.get(symbol, ""))
	if texture_path.is_empty():
		return null
	var texture := ResourceLoader.load(texture_path, "Texture2D") as Texture2D
	if texture != null:
		social_emoji_texture_cache[symbol] = texture
	return texture


func _create_social_emoji_shine_material() -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = SOCIAL_EMOJI_SHINE_SHADER_CODE
	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("shine_progress", -0.5)
	return material


func _apply_bare_social_icon_button_style(button: Button) -> void:
	button.flat = true
	for state_name in [&"normal", &"hover", &"pressed", &"focus", &"disabled"]:
		button.add_theme_stylebox_override(state_name, StyleBoxEmpty.new())
	button.add_theme_color_override("icon_normal_color", Color.WHITE)
	button.add_theme_color_override("icon_hover_color", Color(1.15, 1.15, 1.08))
	button.add_theme_color_override("icon_pressed_color", Color(0.9, 0.82, 0.68))
	button.add_theme_color_override("font_hover_color", Color(1.0, 0.88, 0.48))
	button.add_theme_color_override("font_pressed_color", Color(0.92, 0.79, 0.4))
	button.mouse_entered.connect(_on_bare_social_icon_hover.bind(button, true))
	button.mouse_exited.connect(_on_bare_social_icon_hover.bind(button, false))


func _on_bare_social_icon_hover(button: Button, hovered: bool) -> void:
	if not is_instance_valid(button):
		return
	button.pivot_offset = button.size * 0.5
	button.scale = Vector2(1.1, 1.1) if hovered and not button.disabled else Vector2.ONE


func _create_reaction_controls() -> void:
	reaction_toggle_button = Button.new()
	reaction_toggle_button.text = "☺"
	reaction_toggle_button.tooltip_text = "Реакции за столом"
	reaction_toggle_button.visible = false
	reaction_toggle_button.z_index = 30
	reaction_toggle_button.mouse_filter = Control.MOUSE_FILTER_STOP
	reaction_toggle_button.custom_minimum_size = Vector2(44.0, 40.0)
	reaction_toggle_button.add_theme_font_size_override("font_size", 24)
	_apply_bare_social_icon_button_style(reaction_toggle_button)
	reaction_toggle_button.pressed.connect(_on_reaction_toggle_pressed)
	social_controls_container.add_child(reaction_toggle_button)

	reaction_picker = PanelContainer.new()
	reaction_picker.visible = false
	reaction_picker.z_index = 30
	reaction_picker.mouse_filter = Control.MOUSE_FILTER_STOP
	reaction_picker.add_theme_stylebox_override(
		"panel",
		_create_flat_style(Color(0.012, 0.075, 0.045, 0.96), Color(0.64, 0.47, 0.14, 0.96), 2, 10, 5)
	)
	_set_control_layout(reaction_picker, 0.5, 1.0, 0.5, 1.0, 168.0, -454.0, 492.0, -256.0)

	var reaction_grid := GridContainer.new()
	reaction_grid.columns = 5
	reaction_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reaction_grid.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	reaction_grid.add_theme_constant_override("h_separation", 4)
	reaction_grid.add_theme_constant_override("v_separation", 4)
	reaction_picker.add_child(reaction_grid)
	var reaction_tooltips := {
		"😄": "Смех",
		"😂": "До слёз",
		"🤣": "Катаюсь от смеха",
		"😍": "В восторге",
		"😘": "Воздушный поцелуй",
		"😎": "Круто",
		"🤔": "Задумался",
		"👏": "Аплодисменты",
		"😮": "Удивление",
		"😢": "Грусть",
		"😡": "Злюсь",
		"🤬": "Очень злюсь",
		"😈": "Коварный план",
		"🤡": "Ну ты клоун",
		"🤦": "Рукалицо",
		"🤷": "Не знаю",
		"👍": "Одобряю",
		"👎": "Не одобряю",
		"🔥": "Огонь",
		"🖕": "Средний палец"
	}
	for reaction in NetworkHost.NETWORK_REACTIONS:
		var reaction_button := Button.new()
		var reaction_texture := _get_social_emoji_texture(reaction)
		reaction_button.text = reaction if reaction_texture == null else ""
		reaction_button.icon = reaction_texture
		reaction_button.expand_icon = reaction_texture != null
		reaction_button.tooltip_text = str(reaction_tooltips.get(reaction, "Отправить реакцию"))
		reaction_button.custom_minimum_size = Vector2(56.0, 42.0)
		reaction_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		reaction_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		reaction_button.add_theme_font_size_override("font_size", 24)
		reaction_button.add_theme_constant_override("icon_max_width", 34)
		_apply_bare_social_icon_button_style(reaction_button)
		reaction_button.pressed.connect(_on_reaction_selected.bind(reaction))
		reaction_grid.add_child(reaction_button)
	players_container.add_child(reaction_picker)

	reaction_bubble = PanelContainer.new()
	reaction_bubble.visible = false
	reaction_bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE
	reaction_bubble.z_index = 31
	reaction_bubble.add_theme_stylebox_override(
		"panel",
		StyleBoxEmpty.new()
	)
	_set_control_layout(reaction_bubble, 0.5, 1.0, 0.5, 1.0, -48.0, -514.0, 48.0, -418.0)
	reaction_bubble.pivot_offset = Vector2(48.0, 48.0)

	var reaction_visual_root := Control.new()
	reaction_visual_root.custom_minimum_size = Vector2(82.0, 82.0)
	reaction_visual_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	reaction_bubble.add_child(reaction_visual_root)

	reaction_bubble_shadow = TextureRect.new()
	reaction_bubble_shadow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	reaction_bubble_shadow.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	reaction_bubble_shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	reaction_bubble_shadow.modulate = Color(0.0, 0.0, 0.0, 0.34)
	_set_control_layout(reaction_bubble_shadow, 0.0, 0.0, 1.0, 1.0, 5.0, 7.0, 5.0, 7.0)
	reaction_visual_root.add_child(reaction_bubble_shadow)

	reaction_bubble_image = TextureRect.new()
	reaction_bubble_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	reaction_bubble_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	reaction_bubble_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	reaction_bubble_image.material = _create_social_emoji_shine_material()
	_set_control_layout(reaction_bubble_image, 0.0, 0.0, 1.0, 1.0, 0.0, 0.0, 0.0, 0.0)
	reaction_visual_root.add_child(reaction_bubble_image)

	reaction_bubble_label = Label.new()
	reaction_bubble_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	reaction_bubble_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	reaction_bubble_label.add_theme_font_size_override("font_size", 42)
	reaction_bubble_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_set_control_layout(reaction_bubble_label, 0.0, 0.0, 1.0, 1.0, 0.0, 0.0, 0.0, 0.0)
	reaction_visual_root.add_child(reaction_bubble_label)
	players_container.add_child(reaction_bubble)


func _on_reaction_toggle_pressed() -> void:
	if not _can_show_reaction_controls() or (not _is_steam_p2p_main_table_active() and not _is_social_action_ready(SocialAction.REACTION)):
		return

	_close_sticker_picker()
	soundpad_picker.visible = false
	chat_panel.visible = false
	reaction_picker.visible = not reaction_picker.visible


func _on_reaction_selected(reaction: String) -> void:
	if not _can_show_reaction_controls():
		return
	if _is_steam_p2p_main_table_active():
		if not _try_consume_social_action(SocialAction.REACTION):
			return
		reaction_picker.visible = false
		_submit_network_social_action({"kind": "reaction", "reaction": reaction})
		return
	if not _try_consume_social_action(SocialAction.REACTION):
		return

	reaction_picker.visible = false
	_show_reaction_bubble(reaction, HUMAN_PLAYER_INDEX)


func _show_reaction_bubble(reaction: String, relative_slot: int) -> void:
	if (
		not is_instance_valid(reaction_bubble)
		or relative_slot < 0
		or relative_slot >= avatar_badges.size()
	):
		return
	var reaction_texture := _get_social_emoji_texture(reaction)
	reaction_bubble_image.texture = reaction_texture
	reaction_bubble_image.visible = reaction_texture != null
	reaction_bubble_shadow.texture = reaction_texture
	reaction_bubble_shadow.visible = reaction_texture != null
	reaction_bubble_label.text = reaction
	reaction_bubble_label.visible = reaction_texture == null
	reaction_bubble.visible = true
	reaction_bubble.modulate = Color.WHITE
	reaction_bubble.scale = Vector2(0.58, 0.58)
	reaction_bubble.rotation = deg_to_rad(-9.0)
	var badge_rect := avatar_badges[relative_slot].get_global_rect()
	reaction_bubble.global_position = badge_rect.get_center() - reaction_bubble.size * 0.5 + Vector2(0.0, -64.0)

	if is_instance_valid(reaction_bubble_tween):
		reaction_bubble_tween.kill()

	var start_position: Vector2 = reaction_bubble.position
	var shine_material := reaction_bubble_image.material as ShaderMaterial
	if shine_material != null:
		shine_material.set_shader_parameter("shine_progress", -0.5)
	reaction_bubble_tween = create_tween().set_parallel(true)
	reaction_bubble_tween.tween_property(reaction_bubble, "position", start_position + Vector2(0.0, -18.0), 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	reaction_bubble_tween.tween_property(reaction_bubble, "scale", Vector2(1.12, 1.12), 0.26).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	reaction_bubble_tween.tween_property(reaction_bubble, "rotation", deg_to_rad(4.0), 0.26).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if shine_material != null:
		reaction_bubble_tween.tween_property(shine_material, "shader_parameter/shine_progress", 2.25, 0.5)
	reaction_bubble_tween.set_parallel(false)
	reaction_bubble_tween.tween_property(reaction_bubble, "scale", Vector2.ONE, 0.12)
	reaction_bubble_tween.parallel().tween_property(reaction_bubble, "rotation", 0.0, 0.12)
	reaction_bubble_tween.tween_interval(0.45)
	reaction_bubble_tween.tween_property(reaction_bubble, "modulate:a", 0.0, 0.22)
	reaction_bubble_tween.parallel().tween_property(reaction_bubble, "position", start_position + Vector2(0.0, -30.0), 0.22)
	reaction_bubble_tween.tween_callback(_hide_reaction_bubble)


func _hide_reaction_bubble() -> void:
	if is_instance_valid(reaction_bubble):
		reaction_bubble.visible = false


func _can_show_reaction_controls() -> bool:
	if _is_steam_p2p_main_table_active():
		var snapshot := _get_network_main_snapshot()
		var round_data: Dictionary = snapshot.get("round", {})
		return (
			not snapshot.is_empty()
			and int(round_data.get("state", Round.State.SETUP)) != Round.State.SETUP
			and (menu_overlay == null or not menu_overlay.visible)
		)
	return (
		not is_bug_report_review_mode
		and game.current_round.state != Round.State.SETUP
		and (menu_overlay == null or not menu_overlay.visible)
	)


func _refresh_reaction_controls() -> void:
	if not is_instance_valid(reaction_toggle_button) or not is_instance_valid(reaction_picker):
		return

	var can_show_controls := _can_show_reaction_controls()
	reaction_toggle_button.visible = can_show_controls
	if not can_show_controls:
		reaction_picker.visible = false
		_hide_reaction_bubble()


func _create_sticker_controls() -> void:
	sticker_toggle_button = Button.new()
	sticker_toggle_button.text = "🎁"
	sticker_toggle_button.tooltip_text = "Стикеры игрокам"
	sticker_toggle_button.visible = false
	sticker_toggle_button.z_index = 30
	sticker_toggle_button.mouse_filter = Control.MOUSE_FILTER_STOP
	sticker_toggle_button.custom_minimum_size = Vector2(64.0, 50.0)
	sticker_toggle_button.add_theme_font_size_override("font_size", 16)
	sticker_toggle_button.add_theme_stylebox_override(
		"normal",
		_create_flat_style(Color(0.08, 0.085, 0.15, 0.98), Color(0.65, 0.54, 0.92, 1.0), 2, 8, 3)
	)
	sticker_toggle_button.pressed.connect(_on_sticker_toggle_pressed)
	social_controls_container.add_child(sticker_toggle_button)

	sticker_picker = PanelContainer.new()
	sticker_picker.visible = false
	sticker_picker.z_index = 31
	sticker_picker.mouse_filter = Control.MOUSE_FILTER_STOP
	sticker_picker.add_theme_stylebox_override(
		"panel",
		_create_flat_style(Color(0.03, 0.045, 0.1, 0.97), Color(0.65, 0.54, 0.92, 0.96), 2, 10, 5)
	)
	sticker_picker.gui_input.connect(_on_sticker_picker_gui_input)
	sticker_picker.mouse_entered.connect(_restart_sticker_picker_auto_close)
	_set_control_layout(sticker_picker, 0.5, 1.0, 0.5, 1.0, 168.0, -401.0, 510.0, -309.0)

	sticker_picker_auto_close_timer = Timer.new()
	sticker_picker_auto_close_timer.one_shot = true
	sticker_picker_auto_close_timer.wait_time = STICKER_PICKER_IDLE_CLOSE_SECONDS
	sticker_picker_auto_close_timer.timeout.connect(_close_sticker_picker)
	sticker_picker.add_child(sticker_picker_auto_close_timer)

	var sticker_layout := VBoxContainer.new()
	sticker_layout.add_theme_constant_override("separation", 6)
	sticker_picker.add_child(sticker_layout)

	var sticker_header := HBoxContainer.new()
	sticker_header.add_theme_constant_override("separation", 4)
	sticker_layout.add_child(sticker_header)

	var sticker_header_spacer := Control.new()
	sticker_header_spacer.custom_minimum_size = Vector2(32.0, 26.0)
	sticker_header.add_child(sticker_header_spacer)

	sticker_picker_title = Label.new()
	sticker_picker_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sticker_picker_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sticker_picker_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sticker_picker_title.add_theme_font_size_override("font_size", 15)
	sticker_picker_title.add_theme_color_override("font_color", Color(0.94, 0.91, 1.0, 1.0))
	sticker_header.add_child(sticker_picker_title)

	sticker_picker_close_button = Button.new()
	sticker_picker_close_button.text = "×"
	sticker_picker_close_button.tooltip_text = "Закрыть"
	sticker_picker_close_button.custom_minimum_size = Vector2(32.0, 26.0)
	sticker_picker_close_button.add_theme_font_size_override("font_size", 18)
	sticker_picker_close_button.pressed.connect(_close_sticker_picker)
	sticker_header.add_child(sticker_picker_close_button)

	sticker_picker_content = VBoxContainer.new()
	sticker_picker_content.add_theme_constant_override("separation", 6)
	sticker_layout.add_child(sticker_picker_content)
	players_container.add_child(sticker_picker)

	sticker_flyers.clear()
	sticker_flyer_labels.clear()
	sticker_flyer_images.clear()
	sticker_flyer_shadows.clear()
	sticker_flyer_tweens.clear()
	for _player_index in PLAYER_NAMES.size():
		var flyer := PanelContainer.new()
		flyer.visible = false
		flyer.size = Vector2(72.0, 72.0)
		flyer.pivot_offset = flyer.size * 0.5
		flyer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		flyer.z_index = 32
		flyer.add_theme_stylebox_override(
			"panel",
			StyleBoxEmpty.new()
		)

		var flyer_visual_root := Control.new()
		flyer_visual_root.custom_minimum_size = Vector2(62.0, 62.0)
		flyer_visual_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
		flyer.add_child(flyer_visual_root)

		var flyer_shadow := TextureRect.new()
		flyer_shadow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		flyer_shadow.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		flyer_shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		flyer_shadow.modulate = Color(0.0, 0.0, 0.0, 0.34)
		_set_control_layout(flyer_shadow, 0.0, 0.0, 1.0, 1.0, 5.0, 7.0, 5.0, 7.0)
		flyer_visual_root.add_child(flyer_shadow)

		var flyer_image := TextureRect.new()
		flyer_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		flyer_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		flyer_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
		flyer_image.visible = false
		flyer_image.material = _create_social_emoji_shine_material()
		_set_control_layout(flyer_image, 0.0, 0.0, 1.0, 1.0, 0.0, 0.0, 0.0, 0.0)
		flyer_visual_root.add_child(flyer_image)

		var flyer_label := Label.new()
		flyer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		flyer_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		flyer_label.add_theme_font_size_override("font_size", 31)
		flyer_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_set_control_layout(flyer_label, 0.0, 0.0, 1.0, 1.0, 0.0, 0.0, 0.0, 0.0)
		flyer_visual_root.add_child(flyer_label)
		players_container.add_child(flyer)
		sticker_flyers.append(flyer)
		sticker_flyer_images.append(flyer_image)
		sticker_flyer_shadows.append(flyer_shadow)
		sticker_flyer_labels.append(flyer_label)


func _on_sticker_toggle_pressed() -> void:
	if not _can_show_reaction_controls() or (not _is_steam_p2p_main_table_active() and not _is_social_action_ready(SocialAction.STICKER)):
		return

	reaction_picker.visible = false
	soundpad_picker.visible = false
	chat_panel.visible = false
	sticker_selected_target_index = -1
	_build_sticker_target_picker()
	sticker_picker.visible = not sticker_picker.visible
	if sticker_picker.visible:
		_restart_sticker_picker_auto_close()
	else:
		sticker_picker_auto_close_timer.stop()


func _on_sticker_picker_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion or event is InputEventMouseButton:
		_restart_sticker_picker_auto_close()


func _restart_sticker_picker_auto_close() -> void:
	if (
		is_instance_valid(sticker_picker)
		and sticker_picker.visible
		and is_instance_valid(sticker_picker_auto_close_timer)
	):
		sticker_picker_auto_close_timer.start(STICKER_PICKER_IDLE_CLOSE_SECONDS)


func _close_sticker_picker() -> void:
	if is_instance_valid(sticker_picker_auto_close_timer):
		sticker_picker_auto_close_timer.stop()
	if is_instance_valid(sticker_picker):
		sticker_picker.visible = false
	sticker_selected_target_index = -1


func _build_sticker_target_picker() -> void:
	_clear_children(sticker_picker_content)
	sticker_picker_title.text = "Кому отправить стикер?"
	_set_control_layout(sticker_picker, 0.5, 1.0, 0.5, 1.0, 168.0, -401.0, 510.0, -309.0)

	var target_row := HBoxContainer.new()
	target_row.alignment = BoxContainer.ALIGNMENT_CENTER
	target_row.add_theme_constant_override("separation", 4)
	sticker_picker_content.add_child(target_row)
	var player_names_by_index: Dictionary = {}
	var viewer_index := HUMAN_PLAYER_INDEX
	if _is_steam_p2p_main_table_active():
		var snapshot := _get_network_main_snapshot()
		viewer_index = int(snapshot.get("recipient_player_index", -1))
		player_names_by_index = _get_network_players_by_index(snapshot)
	for player_index in range(PLAYER_NAMES.size()):
		if player_index == viewer_index:
			continue
		var target_name := game.players[player_index].display_name
		if player_names_by_index.has(player_index):
			target_name = str((player_names_by_index[player_index] as Dictionary).get("display_name", target_name))
		var target_button := Button.new()
		target_button.text = target_name.left(8)
		target_button.custom_minimum_size = Vector2(80.0, 38.0)
		target_button.add_theme_font_size_override("font_size", 14)
		target_button.pressed.connect(_on_sticker_target_selected.bind(player_index))
		target_row.add_child(target_button)


func _on_sticker_target_selected(player_index: int) -> void:
	if _is_steam_p2p_main_table_active():
		var snapshot := _get_network_main_snapshot()
		if player_index < 0 or player_index >= PLAYER_NAMES.size() or player_index == int(snapshot.get("recipient_player_index", -1)):
			return
	elif player_index <= HUMAN_PLAYER_INDEX or player_index >= game.players.size():
		return

	sticker_selected_target_index = player_index
	_build_sticker_choice_picker()


func _build_sticker_choice_picker() -> void:
	_clear_children(sticker_picker_content)
	var target_name := game.players[sticker_selected_target_index].display_name
	if _is_steam_p2p_main_table_active():
		var players_by_index := _get_network_players_by_index(_get_network_main_snapshot())
		if players_by_index.has(sticker_selected_target_index):
			target_name = str((players_by_index[sticker_selected_target_index] as Dictionary).get("display_name", target_name))
	sticker_picker_title.text = "Что отправить %s?" % target_name.left(12)
	_set_control_layout(sticker_picker, 0.5, 1.0, 0.5, 1.0, 168.0, -430.0, 494.0, -280.0)

	var sticker_scroll := ScrollContainer.new()
	sticker_scroll.custom_minimum_size = Vector2(0.0, 88.0)
	sticker_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sticker_picker_content.add_child(sticker_scroll)

	var sticker_grid_center := CenterContainer.new()
	sticker_grid_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sticker_grid_center.custom_minimum_size = Vector2(0.0, 84.0)
	sticker_scroll.add_child(sticker_grid_center)

	var sticker_grid := GridContainer.new()
	sticker_grid.columns = 5
	sticker_grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	sticker_grid.add_theme_constant_override("h_separation", 4)
	sticker_grid.add_theme_constant_override("v_separation", 4)
	sticker_grid_center.add_child(sticker_grid)
	var stickers := _get_network_available_stickers() if _is_steam_p2p_main_table_active() else _get_available_stickers()
	for sticker in stickers:
		var sticker_button := Button.new()
		var sticker_texture: Texture2D = sticker.get("texture", null) as Texture2D
		sticker_button.text = str(sticker.get("symbol", "")) if sticker_texture == null else ""
		sticker_button.icon = sticker_texture
		sticker_button.expand_icon = sticker_texture != null
		sticker_button.tooltip_text = str(sticker.get("tooltip", "Отправить стикер"))
		sticker_button.custom_minimum_size = Vector2(58.0, 42.0)
		sticker_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		sticker_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		sticker_button.alignment = HORIZONTAL_ALIGNMENT_CENTER
		sticker_button.add_theme_font_size_override("font_size", 23)
		sticker_button.add_theme_constant_override("icon_max_width", 40)
		_apply_bare_social_icon_button_style(sticker_button)
		sticker_button.pressed.connect(_on_sticker_selected.bind(sticker))
		sticker_grid.add_child(sticker_button)


func _get_builtin_stickers() -> Array[Dictionary]:
	var stickers: Array[Dictionary] = [
		{"symbol": "🍫", "tooltip": "Шоколад"},
		{"symbol": "☕", "tooltip": "Кофе"},
		{"symbol": "🍺", "tooltip": "Пиво"},
		{"symbol": "💋", "tooltip": "Поцелуй"},
		{"symbol": "♥", "tooltip": "Сердечко"},
		{"symbol": "🌹", "tooltip": "Роза"},
		{"symbol": "🍰", "tooltip": "Тортик"},
		{"symbol": "🧸", "tooltip": "Мишка"},
		{"symbol": "🏆", "tooltip": "Кубок"},
		{"symbol": "💩", "tooltip": "Сюрприз"}
	]
	for sticker in stickers:
		sticker["texture"] = _get_social_emoji_texture(str(sticker.get("symbol", "")))
	return stickers


func _get_available_stickers() -> Array[Dictionary]:
	var stickers := _get_builtin_stickers()
	var sticker_directory: DirAccess = DirAccess.open("res://Assets/Stickers")
	if sticker_directory == null:
		return stickers

	for file_name in sticker_directory.get_files():
		var file_extension := file_name.get_extension().to_lower()
		if file_extension not in PackedStringArray(["png", "webp", "jpg", "jpeg"]):
			continue

		var sticker_path := "res://Assets/Stickers/%s" % file_name
		var sticker_texture: Texture2D = ResourceLoader.load(sticker_path, "Texture2D") as Texture2D
		if sticker_texture == null:
			continue

		stickers.append({
			"symbol": "",
			"tooltip": file_name.get_basename(),
			"texture": sticker_texture
		})

	return stickers


func _get_network_available_stickers() -> Array[Dictionary]:
	return _get_builtin_stickers()


func _get_builtin_sticker_by_symbol(symbol: String) -> Dictionary:
	for sticker in _get_builtin_stickers():
		if str(sticker.get("symbol", "")) == symbol:
			return sticker
	return {"symbol": symbol, "tooltip": "Подарок"}


func _on_sticker_selected(sticker: Dictionary) -> void:
	if sticker_selected_target_index < 0 or sticker_selected_target_index >= PLAYER_NAMES.size():
		return
	var target_player_index := sticker_selected_target_index
	if _is_steam_p2p_main_table_active():
		if not _try_consume_social_action(SocialAction.STICKER):
			return
		_close_sticker_picker()
		_submit_network_social_action({
			"kind": "sticker",
			"target_player_index": target_player_index,
			"sticker": str(sticker.get("symbol", ""))
		})
		return
	if not _try_consume_social_action(SocialAction.STICKER):
		return

	_close_sticker_picker()
	_show_sticker_flyer(sticker, HUMAN_PLAYER_INDEX, target_player_index)


func _show_sticker_flyer(sticker: Dictionary, source_player_index: int, target_player_index: int) -> void:
	if (
		source_player_index < 0
		or source_player_index >= avatar_badges.size()
		or target_player_index < 0
		or target_player_index >= avatar_badges.size()
		or target_player_index >= sticker_flyers.size()
	):
		return

	var flyer := sticker_flyers[target_player_index]
	var flyer_image := sticker_flyer_images[target_player_index]
	var flyer_shadow := sticker_flyer_shadows[target_player_index]
	var flyer_label := sticker_flyer_labels[target_player_index]
	var sticker_texture: Texture2D = sticker.get("texture", null) as Texture2D
	if sticker_texture == null:
		sticker_texture = _get_social_emoji_texture(str(sticker.get("symbol", "")))
	flyer_image.texture = sticker_texture
	flyer_image.visible = sticker_texture != null
	flyer_shadow.texture = sticker_texture
	flyer_shadow.visible = sticker_texture != null
	flyer_label.visible = sticker_texture == null
	flyer_label.text = str(sticker.get("symbol", ""))
	flyer.visible = true
	flyer.modulate = Color.WHITE
	flyer.scale = Vector2(0.54, 0.54)
	flyer.rotation = deg_to_rad(-10.0)

	var existing_tween: Tween = sticker_flyer_tweens.get(target_player_index) as Tween
	if is_instance_valid(existing_tween):
		existing_tween.kill()

	var flyer_size := flyer.size
	var source_center := avatar_badges[source_player_index].get_global_rect().get_center()
	var target_center := avatar_badges[target_player_index].get_global_rect().get_center()
	flyer.global_position = source_center - flyer_size * 0.5

	var shine_material := flyer_image.material as ShaderMaterial
	if shine_material != null:
		shine_material.set_shader_parameter("shine_progress", -0.5)
	var flyer_tween := create_tween().set_parallel(true)
	sticker_flyer_tweens[target_player_index] = flyer_tween
	flyer_tween.tween_property(flyer, "global_position", target_center - flyer_size * 0.5, STICKER_FLY_DURATION).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	flyer_tween.tween_property(flyer, "scale", Vector2(1.14, 1.14), 0.42).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	flyer_tween.tween_property(flyer, "rotation", deg_to_rad(4.0), 0.42).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if shine_material != null:
		flyer_tween.tween_property(shine_material, "shader_parameter/shine_progress", 2.25, 0.55)
	flyer_tween.set_parallel(false)
	flyer_tween.tween_property(flyer, "scale", Vector2.ONE, 0.16)
	flyer_tween.parallel().tween_property(flyer, "rotation", 0.0, 0.16)
	flyer_tween.tween_interval(STICKER_HOLD_DURATION)
	flyer_tween.tween_property(flyer, "modulate:a", 0.0, 0.22)
	flyer_tween.parallel().tween_property(flyer, "scale", Vector2(0.82, 0.82), 0.22)
	flyer_tween.tween_callback(_hide_sticker_flyer.bind(target_player_index))


func _hide_sticker_flyer(target_player_index: int) -> void:
	if target_player_index >= 0 and target_player_index < sticker_flyers.size():
		sticker_flyers[target_player_index].visible = false
	sticker_flyer_tweens.erase(target_player_index)


func _hide_all_sticker_flyers() -> void:
	for tween_variant in sticker_flyer_tweens.values():
		var flyer_tween := tween_variant as Tween
		if is_instance_valid(flyer_tween):
			flyer_tween.kill()
	sticker_flyer_tweens.clear()
	for flyer in sticker_flyers:
		flyer.visible = false


func _refresh_sticker_controls() -> void:
	if not is_instance_valid(sticker_toggle_button) or not is_instance_valid(sticker_picker):
		return

	var can_show_controls := _can_show_reaction_controls()
	# Подарок выбирается прямо с аватарки получателя.
	sticker_toggle_button.visible = false
	if not can_show_controls:
		_close_sticker_picker()
		_hide_all_sticker_flyers()


func _create_soundpad_controls() -> void:
	soundpad_sounds = _load_soundpad_sounds()

	soundpad_toggle_button = Button.new()
	soundpad_toggle_button.text = "🔊"
	soundpad_toggle_button.tooltip_text = "Саундпад"
	soundpad_toggle_button.visible = false
	soundpad_toggle_button.z_index = 30
	soundpad_toggle_button.mouse_filter = Control.MOUSE_FILTER_STOP
	soundpad_toggle_button.custom_minimum_size = Vector2(44.0, 40.0)
	soundpad_toggle_button.add_theme_font_size_override("font_size", 22)
	_apply_bare_social_icon_button_style(soundpad_toggle_button)
	soundpad_toggle_button.pressed.connect(_on_soundpad_toggle_pressed)
	social_controls_container.add_child(soundpad_toggle_button)

	soundpad_picker = PanelContainer.new()
	soundpad_picker.visible = false
	soundpad_picker.z_index = 31
	soundpad_picker.mouse_filter = Control.MOUSE_FILTER_STOP
	soundpad_picker.add_theme_stylebox_override(
		"panel",
		_create_flat_style(Color(0.09, 0.035, 0.09, 0.97), Color(0.89, 0.51, 0.82, 0.96), 2, 10, 5)
	)
	_set_control_layout(soundpad_picker, 0.5, 1.0, 0.5, 1.0, 168.0, -451.0, 486.0, -259.0)

	var soundpad_layout := VBoxContainer.new()
	soundpad_layout.add_theme_constant_override("separation", 6)
	soundpad_picker.add_child(soundpad_layout)

	var soundpad_header := HBoxContainer.new()
	soundpad_header.add_theme_constant_override("separation", 4)
	soundpad_layout.add_child(soundpad_header)

	soundpad_picker_back_button = Button.new()
	soundpad_picker_back_button.text = "←"
	soundpad_picker_back_button.tooltip_text = "Выбрать другой язык"
	soundpad_picker_back_button.custom_minimum_size = Vector2(32.0, 26.0)
	soundpad_picker_back_button.add_theme_font_size_override("font_size", 18)
	soundpad_picker_back_button.visible = false
	soundpad_picker_back_button.pressed.connect(_build_soundpad_category_picker)
	soundpad_header.add_child(soundpad_picker_back_button)

	soundpad_picker_title = Label.new()
	soundpad_picker_title.text = "Саундпад"
	soundpad_picker_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	soundpad_picker_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	soundpad_picker_title.add_theme_font_size_override("font_size", 16)
	soundpad_picker_title.add_theme_color_override("font_color", Color(1.0, 0.89, 0.97, 1.0))
	soundpad_header.add_child(soundpad_picker_title)

	soundpad_picker_content = VBoxContainer.new()
	soundpad_picker_content.add_theme_constant_override("separation", 6)
	soundpad_layout.add_child(soundpad_picker_content)
	players_container.add_child(soundpad_picker)

	soundpad_bubble = PanelContainer.new()
	soundpad_bubble.visible = false
	soundpad_bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE
	soundpad_bubble.z_index = 32
	soundpad_bubble.pivot_offset = Vector2(27.0, 27.0)
	soundpad_bubble.add_theme_stylebox_override(
		"panel",
		_create_flat_style(Color(0.12, 0.055, 0.14, 0.96), Color(0.98, 0.63, 0.89, 1.0), 2, 20, 5)
	)
	_set_control_layout(soundpad_bubble, 0.5, 1.0, 0.5, 1.0, -190.0, -430.0, -136.0, -376.0)

	soundpad_bubble_label = Label.new()
	soundpad_bubble_label.text = "🔊"
	soundpad_bubble_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	soundpad_bubble_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	soundpad_bubble_label.add_theme_font_size_override("font_size", 26)
	soundpad_bubble.add_child(soundpad_bubble_label)
	players_container.add_child(soundpad_bubble)


func _on_soundpad_toggle_pressed() -> void:
	if not _can_show_reaction_controls() or not _is_social_action_ready(SocialAction.SOUNDPAD):
		return

	reaction_picker.visible = false
	_close_sticker_picker()
	chat_panel.visible = false
	soundpad_selected_category_id = ""
	_build_soundpad_category_picker()
	soundpad_picker.visible = not soundpad_picker.visible


func _build_soundpad_category_picker() -> void:
	_clear_children(soundpad_picker_content)
	soundpad_picker_back_button.visible = false

	if soundpad_sounds.is_empty():
		soundpad_picker_title.text = "Саундпад пока пуст"
		var empty_label := Label.new()
		empty_label.text = "Добавь OGG, WAV или MP3 в папку языка внутри Assets/Soundboard и перезапусти игру."
		empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.add_theme_font_size_override("font_size", 14)
		soundpad_picker_content.add_child(empty_label)
		_resize_soundpad_picker(76.0)
		return

	soundpad_picker_title.text = "Саундпад · выбери язык"
	var soundpad_grid := GridContainer.new()
	soundpad_grid.columns = 2
	soundpad_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	soundpad_grid.add_theme_constant_override("h_separation", 5)
	soundpad_grid.add_theme_constant_override("v_separation", 5)
	soundpad_picker_content.add_child(soundpad_grid)
	var categories := _get_soundpad_categories()
	for category in categories:
		var category_id := str(category.get("id", "root"))
		var category_button := Button.new()
		category_button.text = str(category.get("label", "Общее"))
		category_button.tooltip_text = "%d звуков" % int(category.get("count", 0))
		category_button.custom_minimum_size = Vector2(148.0, 40.0)
		category_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		category_button.add_theme_font_size_override("font_size", 14)
		category_button.pressed.connect(_on_soundpad_category_selected.bind(category_id))
		soundpad_grid.add_child(category_button)

	var category_rows: int = ceili(float(categories.size()) / 2.0)
	var content_height: float = float(category_rows * 40 + maxi(0, category_rows - 1) * 5)
	_resize_soundpad_picker(content_height)


func _on_soundpad_category_selected(category_id: String) -> void:
	soundpad_selected_category_id = category_id
	_build_soundpad_sound_picker()


func _build_soundpad_sound_picker() -> void:
	_clear_children(soundpad_picker_content)
	soundpad_picker_back_button.visible = true
	soundpad_picker_title.text = "Саундпад · %s" % _get_soundpad_category_label(soundpad_selected_category_id)

	var soundpad_scroll := ScrollContainer.new()
	soundpad_scroll.custom_minimum_size = Vector2(0.0, 134.0)
	soundpad_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	soundpad_picker_content.add_child(soundpad_scroll)

	var soundpad_grid := GridContainer.new()
	soundpad_grid.columns = 2
	soundpad_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	soundpad_grid.add_theme_constant_override("h_separation", 5)
	soundpad_grid.add_theme_constant_override("v_separation", 5)
	soundpad_scroll.add_child(soundpad_grid)
	for sound_data in soundpad_sounds:
		if str(sound_data.get("category", "root")) != soundpad_selected_category_id:
			continue

		var sound_button := Button.new()
		var sound_title := str(sound_data.get("title", "Звук"))
		sound_button.text = "🔊 %s" % _shorten_soundpad_title(sound_title)
		sound_button.tooltip_text = sound_title
		sound_button.custom_minimum_size = Vector2(148.0, 40.0)
		sound_button.add_theme_font_size_override("font_size", 14)
		sound_button.pressed.connect(_on_soundpad_selected.bind(sound_data))
		soundpad_grid.add_child(sound_button)

	_resize_soundpad_picker(134.0)


func _resize_soundpad_picker(content_height: float) -> void:
	var picker_width := 318.0
	var picker_height := 32.0 + content_height
	var picker_center_y := -355.0
	_set_control_layout(
		soundpad_picker,
		0.5,
		1.0,
		0.5,
		1.0,
		168.0,
		picker_center_y - picker_height * 0.5,
		168.0 + picker_width,
		picker_center_y + picker_height * 0.5
	)


func _load_soundpad_sounds() -> Array[Dictionary]:
	var sounds: Array[Dictionary] = []
	var soundpad_directory: DirAccess = DirAccess.open("res://Assets/Soundboard")
	if soundpad_directory == null:
		return sounds

	_append_soundpad_sounds_from_directory(sounds, "root", "res://Assets/Soundboard")
	for directory_name in soundpad_directory.get_directories():
		_append_soundpad_sounds_from_directory(
			sounds,
			directory_name.to_lower(),
			"res://Assets/Soundboard/%s" % directory_name
		)

	sounds.sort_custom(func(left: Dictionary, right: Dictionary) -> bool:
		var left_category := str(left.get("category", "root"))
		var right_category := str(right.get("category", "root"))
		var left_category_order := _get_soundpad_category_order(left_category)
		var right_category_order := _get_soundpad_category_order(right_category)
		if left_category_order != right_category_order:
			return left_category_order < right_category_order
		if left_category != right_category:
			return left_category.naturalnocasecmp_to(right_category) < 0
		return str(left.get("title", "")).naturalnocasecmp_to(str(right.get("title", ""))) < 0
	)
	if sounds.is_empty():
		return _load_soundpad_sounds_from_manifest()
	_save_soundpad_manifest(sounds)
	return sounds


func _append_soundpad_sounds_from_directory(
	sounds: Array[Dictionary],
	category_id: String,
	directory_path: String
) -> void:
	var soundpad_directory: DirAccess = DirAccess.open(directory_path)
	if soundpad_directory == null:
		return

	for file_name in soundpad_directory.get_files():
		var file_extension := file_name.get_extension().to_lower()
		if file_extension not in PackedStringArray(["ogg", "wav", "mp3"]):
			continue

		var sound_path := "%s/%s" % [directory_path, file_name]
		# В экспортированной PCK рядом с исходным файлом может не быть
		# служебного .import-файла. Ресурс при этом уже упакован Godot,
		# поэтому проверяем именно возможность загрузить AudioStream.
		var sound_stream: AudioStream = ResourceLoader.load(sound_path, "AudioStream") as AudioStream
		if sound_stream == null or sound_stream.get_length() > MAX_SOUNDPAD_CLIP_DURATION_SECONDS:
			continue

		# В редакторе и локальной версии дополнительно не даём случайно
		# добавить слишком тяжёлый исходный файл. В PCK эта проверка
		# необязательна: достаточно успешно загруженного ресурса выше.
		var sound_file: FileAccess = FileAccess.open(sound_path, FileAccess.READ)
		if sound_file != null:
			var file_size: int = sound_file.get_length()
			sound_file.close()
			if file_size > MAX_SOUNDPAD_FILE_SIZE_BYTES:
				continue

		sounds.append({
			"title": file_name.get_basename(),
			"category": category_id,
			"path": sound_path,
			"stream": sound_stream
		})


func _load_soundpad_sounds_from_manifest() -> Array[Dictionary]:
	var sounds: Array[Dictionary] = []
	for sound_path in SoundpadManifest.PATHS:
		if sound_path.is_empty():
			continue

		var sound_stream: AudioStream = ResourceLoader.load(sound_path, "AudioStream") as AudioStream
		if sound_stream == null or sound_stream.get_length() > MAX_SOUNDPAD_CLIP_DURATION_SECONDS:
			continue

		var sound_file: FileAccess = FileAccess.open(sound_path, FileAccess.READ)
		if sound_file != null:
			var file_size: int = sound_file.get_length()
			sound_file.close()
			if file_size > MAX_SOUNDPAD_FILE_SIZE_BYTES:
				continue

		var category_id := "root"
		if sound_path.get_base_dir() != "res://Assets/Soundboard":
			category_id = sound_path.get_base_dir().get_file().to_lower()
		sounds.append({
			"title": sound_path.get_file().get_basename(),
			"category": category_id,
			"path": sound_path,
			"stream": sound_stream
		})

	sounds.sort_custom(func(left: Dictionary, right: Dictionary) -> bool:
		var left_category := str(left.get("category", "root"))
		var right_category := str(right.get("category", "root"))
		var left_category_order := _get_soundpad_category_order(left_category)
		var right_category_order := _get_soundpad_category_order(right_category)
		if left_category_order != right_category_order:
			return left_category_order < right_category_order
		if left_category != right_category:
			return left_category.naturalnocasecmp_to(right_category) < 0
		return str(left.get("title", "")).naturalnocasecmp_to(str(right.get("title", ""))) < 0
	)
	return sounds


func _save_soundpad_manifest(sounds: Array[Dictionary]) -> void:
	var paths: PackedStringArray = []
	for sound_data in sounds:
		var sound_path := str(sound_data.get("path", ""))
		if not sound_path.is_empty():
			paths.append(sound_path)

	if paths.is_empty():
		return

	var manifest_source := "extends RefCounted\n\nconst PATHS: PackedStringArray = [\n"
	for sound_path in paths:
		var escaped_sound_path := sound_path.replace("\\", "\\\\").replace("\"", "\\\"")
		manifest_source += "\t\"%s\",\n" % escaped_sound_path
	manifest_source += "]\n"

	var existing_manifest_source := ""
	if FileAccess.file_exists(SOUNDPAD_MANIFEST_SCRIPT_PATH):
		existing_manifest_source = FileAccess.get_file_as_string(SOUNDPAD_MANIFEST_SCRIPT_PATH)
	if existing_manifest_source == manifest_source:
		return

	var manifest_file := FileAccess.open(SOUNDPAD_MANIFEST_SCRIPT_PATH, FileAccess.WRITE)
	if manifest_file != null:
		manifest_file.store_string(manifest_source)
		manifest_file.close()


func _get_soundpad_categories() -> Array[Dictionary]:
	var categories: Array[Dictionary] = []
	var category_counts: Dictionary = {}
	for sound_data in soundpad_sounds:
		var category_id := str(sound_data.get("category", "root"))
		category_counts[category_id] = int(category_counts.get(category_id, 0)) + 1

	for category_id_variant in category_counts:
		var category_id := str(category_id_variant)
		categories.append({
			"id": category_id,
			"label": _get_soundpad_category_label(category_id),
			"count": int(category_counts[category_id])
		})

	categories.sort_custom(func(left: Dictionary, right: Dictionary) -> bool:
		var left_id := str(left.get("id", "root"))
		var right_id := str(right.get("id", "root"))
		var left_order := _get_soundpad_category_order(left_id)
		var right_order := _get_soundpad_category_order(right_id)
		if left_order != right_order:
			return left_order < right_order
		return str(left.get("label", "")).naturalnocasecmp_to(str(right.get("label", ""))) < 0
	)
	return categories


func _get_soundpad_category_label(category_id: String) -> String:
	match category_id:
		"root":
			return "Общее"
		"ua":
			return "Українська"
		"pl":
			return "Polski"
		"ru":
			return "Русский"
		"en":
			return "English"
		"kz":
			return "Қазақша"
		"by":
			return "Беларуская"
		"other":
			return "Другие"

	return category_id.replace("_", " ").capitalize()


func _get_soundpad_category_order(category_id: String) -> int:
	match category_id:
		"root":
			return 0
		"ua":
			return 1
		"pl":
			return 2
		"ru":
			return 3
		"en":
			return 4
		"kz":
			return 5
		"by":
			return 6
		"other":
			return 7

	return 8


func _shorten_soundpad_title(title: String) -> String:
	if title.length() <= MAX_SOUNDPAD_TITLE_LENGTH:
		return title

	return "%s…" % title.left(MAX_SOUNDPAD_TITLE_LENGTH - 1)


func _on_soundpad_selected(sound_data: Dictionary) -> void:
	if not _can_show_reaction_controls():
		return

	var sound_stream: AudioStream = sound_data.get("stream", null) as AudioStream
	if sound_stream == null:
		return
	if _is_steam_p2p_main_table_active():
		var sound_id := str(sound_data.get("path", ""))
		if sound_id.is_empty() or sound_id not in SoundpadManifest.PATHS or not _try_consume_social_action(SocialAction.SOUNDPAD):
			return
		soundpad_picker.visible = false
		_submit_network_social_action({"kind": "soundpad", "sound_id": sound_id})
		return
	if not _try_consume_social_action(SocialAction.SOUNDPAD):
		return

	soundpad_picker.visible = false
	_play_soundpad_stream(sound_stream)
	_show_soundpad_bubble()
	_add_history("Ты включил звук «%s»." % str(sound_data.get("title", "Звук")))
	_refresh_history()


func _show_soundpad_bubble() -> void:
	if not is_instance_valid(soundpad_bubble):
		return

	if is_instance_valid(soundpad_bubble_tween):
		soundpad_bubble_tween.kill()

	soundpad_bubble.visible = true
	soundpad_bubble.modulate = Color.WHITE
	soundpad_bubble.scale = Vector2(0.82, 0.82)
	soundpad_bubble_tween = create_tween()
	soundpad_bubble_tween.tween_property(soundpad_bubble, "scale", Vector2(1.12, 1.12), 0.18).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	soundpad_bubble_tween.tween_property(soundpad_bubble, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	soundpad_bubble_tween.tween_interval(SOUNDPAD_BUBBLE_DISPLAY_DURATION)
	soundpad_bubble_tween.tween_property(soundpad_bubble, "modulate:a", 0.0, 0.22)
	soundpad_bubble_tween.tween_callback(_hide_soundpad_bubble)


func _hide_soundpad_bubble() -> void:
	if is_instance_valid(soundpad_bubble):
		soundpad_bubble.visible = false


func _refresh_soundpad_controls() -> void:
	if not is_instance_valid(soundpad_toggle_button) or not is_instance_valid(soundpad_picker):
		return

	var can_show_controls := _can_show_reaction_controls()
	soundpad_toggle_button.visible = can_show_controls
	if not can_show_controls:
		soundpad_picker.visible = false
		_hide_soundpad_bubble()


func _try_consume_social_action(action: SocialAction) -> bool:
	if not _is_social_action_ready(action):
		_refresh_social_action_buttons()
		return false

	var uses: int = int(social_action_uses.get(action, 0)) + 1
	if uses >= SOCIAL_ACTION_USE_LIMIT:
		social_action_uses[action] = 0
		social_action_cooldown_until[action] = Time.get_ticks_msec() + roundi(SOCIAL_ACTION_COOLDOWN_SECONDS * 1000.0)
	else:
		social_action_uses[action] = uses

	_refresh_social_action_buttons()
	return true


func _is_social_action_ready(action: SocialAction) -> bool:
	return _get_social_action_cooldown_remaining(action) <= 0.0


func _get_social_action_cooldown_remaining(action: SocialAction) -> float:
	var cooldown_until: int = int(social_action_cooldown_until.get(action, 0))
	var remaining_milliseconds: int = maxi(0, cooldown_until - Time.get_ticks_msec())
	return float(remaining_milliseconds) / 1000.0


func _get_social_action_uses_remaining(action: SocialAction) -> int:
	if not _is_social_action_ready(action):
		return 0

	return maxi(0, SOCIAL_ACTION_USE_LIMIT - int(social_action_uses.get(action, 0)))


func _get_social_action_status_text(action_name: String, action: SocialAction) -> String:
	var cooldown_remaining := _get_social_action_cooldown_remaining(action)
	if cooldown_remaining > 0.0:
		var total_seconds := ceili(cooldown_remaining)
		return "%s: перезарядка %d:%02d" % [action_name, total_seconds / 60, total_seconds % 60]

	return "%s: осталось %d из %d" % [
		action_name,
		_get_social_action_uses_remaining(action),
		SOCIAL_ACTION_USE_LIMIT
	]


func _refresh_social_action_buttons() -> void:
	if is_instance_valid(reaction_toggle_button):
		var reaction_ready := _is_social_action_ready(SocialAction.REACTION)
		reaction_toggle_button.disabled = not reaction_ready
		reaction_toggle_button.text = "☺"
		reaction_toggle_button.modulate = Color.WHITE if reaction_ready else Color(1.0, 1.0, 1.0, 0.34)
		reaction_toggle_button.tooltip_text = _get_social_action_status_text("Эмоции", SocialAction.REACTION)
		if not reaction_ready and is_instance_valid(reaction_picker):
			reaction_picker.visible = false

	if is_instance_valid(sticker_toggle_button):
		var sticker_ready := _is_social_action_ready(SocialAction.STICKER)
		sticker_toggle_button.disabled = not sticker_ready
		sticker_toggle_button.text = "🎁"
		sticker_toggle_button.modulate = Color.WHITE if sticker_ready else Color(1.0, 1.0, 1.0, 0.34)
		sticker_toggle_button.tooltip_text = _get_social_action_status_text("Стикеры", SocialAction.STICKER)
		if not sticker_ready and is_instance_valid(sticker_picker):
			_close_sticker_picker()

	if is_instance_valid(soundpad_toggle_button):
		var soundpad_ready := _is_social_action_ready(SocialAction.SOUNDPAD)
		soundpad_toggle_button.disabled = not soundpad_ready
		soundpad_toggle_button.text = "🔊"
		soundpad_toggle_button.modulate = Color.WHITE if soundpad_ready else Color(1.0, 1.0, 1.0, 0.34)
		soundpad_toggle_button.tooltip_text = (
			"Саундпад: добавь звуки в Assets/Soundboard"
			if soundpad_sounds.is_empty()
			else _get_social_action_status_text("Саундпад", SocialAction.SOUNDPAD)
		)
		if not soundpad_ready and is_instance_valid(soundpad_picker):
			soundpad_picker.visible = false


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
				_set_control_layout(marker, 0.5, 1.0, 0.5, 1.0, -258.0, -408.0, -222.0, -372.0)
			1:
				_set_control_layout(marker, 0.0, 0.0, 0.0, 0.0, 514.0, 360.0, 550.0, 396.0)
			2:
				_set_control_layout(marker, 0.5, 0.0, 0.5, 0.0, -218.0, 196.0, -182.0, 232.0)
			3:
				_set_control_layout(marker, 1.0, 0.0, 1.0, 0.0, -542.0, 360.0, -506.0, 396.0)
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
			_set_control_layout(panel, 0.5, 1.0, 0.5, 1.0, -107.0, -397.0, 105.0, -307.0)
		1:
			_set_control_layout(panel, 0.0, 0.0, 0.0, 0.0, 298.0, 355.0, 500.0, 445.0)
		2:
			_set_control_layout(panel, 0.5, 0.0, 0.5, 0.0, -106.0, 80.0, 106.0, 170.0)
		3:
			_set_control_layout(panel, 1.0, 0.0, 1.0, 0.0, -500.0, 355.0, -298.0, 445.0)


func _place_trick_slot(panel: Control, player_index: int) -> void:
	match player_index:
		HUMAN_PLAYER_INDEX:
			_set_control_layout(panel, 0.5, 0.0, 0.5, 0.0, -54.0, 430.0, 54.0, 562.0)
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
	_apply_table_action_button_style(suit_button)
	suit_button.disabled = is_bug_report_review_mode
	suit_button.mouse_filter = Control.MOUSE_FILTER_IGNORE if is_bug_report_review_mode else Control.MOUSE_FILTER_STOP
	suit_button.z_index = 1

	if suit < 0:
		suit_button.pressed.connect(_on_joker_suit_reset)
	else:
		suit_button.pressed.connect(_on_joker_suit_pressed.bind(suit))

	joker_controls.add_child(suit_button)


func _on_joker_suit_reset() -> void:
	if is_bug_report_review_mode:
		return

	pending_joker_suit = -1
	action_text = "Выбери объявляемую масть для Джокера."
	_refresh_ui()


func _add_joker_cancel_button() -> void:
	var cancel_button := Button.new()
	cancel_button.text = "← Назад к картам"
	cancel_button.custom_minimum_size = Vector2(0.0, 44.0)
	cancel_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_table_action_button_style(cancel_button)
	cancel_button.disabled = is_bug_report_review_mode
	cancel_button.mouse_filter = Control.MOUSE_FILTER_IGNORE if is_bug_report_review_mode else Control.MOUSE_FILTER_STOP
	cancel_button.z_index = 1
	cancel_button.pressed.connect(_on_cancel_pending_joker_selection_pressed)
	joker_controls.add_child(cancel_button)


func _on_cancel_pending_joker_selection_pressed() -> void:
	if is_bug_report_review_mode or pending_joker_card == null:
		return
	pending_joker_card = null
	pending_joker_suit = -1
	action_text = "Выбери карту для хода."
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
	_apply_table_action_button_style(choice_button)
	choice_button.disabled = is_bug_report_review_mode
	choice_button.mouse_filter = Control.MOUSE_FILTER_IGNORE if is_bug_report_review_mode else Control.MOUSE_FILTER_STOP
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
		not is_bug_report_review_mode
		and not is_processing_automatic_actions
		and game.current_round.state == Round.State.PLAYING
		and _get_current_player_index() == HUMAN_PLAYER_INDEX
	)


func _process(delta: float) -> void:
	steam_bridge.process_callbacks()
	_refresh_social_action_buttons()
	_process_turn_reminder(delta)

	if not turn_timer_active or not auto_turn_enabled:
		return

	if not _is_human_decision_pending():
		_stop_human_turn_timer()
		return

	turn_timer_remaining = maxf(0.0, turn_timer_remaining - delta)
	_refresh_turn_timer_indicator()

	if is_zero_approx(turn_timer_remaining):
		_resolve_human_turn_timeout()


func _process_turn_reminder(delta: float) -> void:
	var decision_key := _get_local_turn_reminder_decision_key()
	if decision_key.is_empty():
		_reset_turn_reminder()
		return
	if decision_key != turn_reminder_decision_key:
		turn_reminder_decision_key = decision_key
		turn_reminder_elapsed_seconds = 0.0
		turn_reminder_was_played = false
		turn_reminder_play_count = 0
		turn_reminder_next_sound_seconds = TURN_REMINDER_DELAY_SECONDS
	turn_reminder_elapsed_seconds += delta
	_refresh_turn_timer_indicator()
	if (
		not _is_steam_p2p_main_table_active()
		and turn_reminder_elapsed_seconds >= INACTIVITY_AUTO_TURN_DELAY_SECONDS
		and not turn_timer_active
	):
		auto_turn_enabled = true
		_save_persistent_settings()
		_start_human_turn_timer()
	if turn_reminder_elapsed_seconds < turn_reminder_next_sound_seconds:
		return
	turn_reminder_was_played = true
	turn_reminder_play_count += 1
	turn_reminder_next_sound_seconds = (
		floorf(turn_reminder_elapsed_seconds / TURN_REMINDER_DELAY_SECONDS) + 1.0
	) * TURN_REMINDER_DELAY_SECONDS
	_play_sound(SoundEffect.TURN_REMINDER)


func _get_local_turn_reminder_decision_key() -> String:
	if _is_steam_p2p_main_table_active():
		if network_card_play_presentation_active or network_round_finish_presentation_active:
			return ""
		var snapshot := _get_network_main_snapshot()
		if snapshot.is_empty():
			return ""
		var undo_state: Dictionary = snapshot.get("undo_state", {})
		if bool(undo_state.get("pending", false)):
			return ""
		var round_data: Dictionary = snapshot.get("round", {})
		var state := int(round_data.get("state", Round.State.SETUP))
		if state != Round.State.BIDDING and state != Round.State.PLAYING:
			return ""
		var active_trick: Dictionary = snapshot.get("active_trick", {})
		var recipient_player_index := int(snapshot.get("recipient_player_index", -1))
		var active_player_index := _get_network_table_active_player_index(round_data, active_trick)
		if recipient_player_index < 0 or active_player_index != recipient_player_index:
			return ""
		var played_cards: Array = active_trick.get("played_cards", [])
		return "network:%d:%d:%d:%d:%d:%d" % [
			int(snapshot.get("round_number", 0)),
			state,
			active_player_index,
			int(round_data.get("bids_made", 0)),
			int(round_data.get("tricks_played", 0)),
			played_cards.size()
		]

	if not _is_human_decision_pending() or local_first_turn_roll_active:
		return ""
	var active_trick_size := game.active_trick.played_cards.size() if game.active_trick != null else 0
	return "local:%d:%d:%d:%d:%d" % [
		game.current_round.number,
		game.current_round.state,
		game.current_round.bids_made,
		game.current_round.tricks_played,
		active_trick_size
	]


func _reset_turn_reminder() -> void:
	turn_reminder_decision_key = ""
	turn_reminder_elapsed_seconds = 0.0
	turn_reminder_was_played = false
	turn_reminder_play_count = 0
	turn_reminder_next_sound_seconds = TURN_REMINDER_DELAY_SECONDS
	if _is_steam_p2p_main_table_active() and is_instance_valid(turn_timer_indicator):
		turn_timer_indicator.visible = false


func _is_human_decision_pending() -> bool:
	return (
		not is_bug_report_review_mode
		and not is_processing_automatic_actions
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

	if _is_steam_p2p_main_table_active():
		var current_decision_key := _get_local_turn_reminder_decision_key()
		var network_countdown_delay := 0.0 if auto_turn_enabled else INACTIVITY_AUTO_TURN_DELAY_SECONDS
		var should_show_network_timer := (
			not current_decision_key.is_empty()
			and current_decision_key == turn_reminder_decision_key
			and turn_reminder_elapsed_seconds >= network_countdown_delay
		)
		turn_timer_indicator.visible = should_show_network_timer
		if should_show_network_timer:
			turn_timer_indicator.set_time_remaining(
				maxf(
					0.0,
					AUTO_TURN_DURATION_SECONDS
					- (turn_reminder_elapsed_seconds - network_countdown_delay)
				),
				AUTO_TURN_DURATION_SECONDS
			)
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
		if game.current_round.round_type == Round.RoundType.GOLDEN:
			return _select_golden_lead_card(legal_cards, game.current_round.trump)
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

	# После перебора точный заказ уже не вернуть, поэтому выгоднее продолжать
	# собирать взятки: перебор приносит очки, недобор оставляет штраф.
	return player.bid != player.tricks_taken


func _select_golden_lead_card(cards: Array[Card], trump: Round.TrumpSuit) -> Card:
	var joker := _get_joker_from_cards(cards)
	if joker != null:
		return joker

	for card in cards:
		if not card.is_joker and card.suit == trump and card.rank == Card.Rank.ACE:
			return card
	for card in cards:
		if not card.is_joker and card.suit != trump and card.rank == Card.Rank.ACE:
			return card

	var non_trumps: Array[Card] = []
	var trumps: Array[Card] = []
	for card in cards:
		if card.is_joker:
			continue
		if card.suit == trump:
			trumps.append(card)
		else:
			non_trumps.append(card)
	# Без гарантированной старшей карты не дарим козырного короля неизвестному
	# тузу: сначала выпускаем младшую некозырную карту и сохраняем силу.
	if not non_trumps.is_empty():
		return _select_card_by_strength(non_trumps, false)
	return _select_card_by_strength(trumps, false)


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


func _format_suit_symbols_for_dark_ui(plain_text: String) -> String:
	var safe_text := plain_text.replace("[", "[lb]")
	safe_text = safe_text.replace("♥", "[color=#ff5148][b]♥[/b][/color]")
	safe_text = safe_text.replace("♦", "[color=#ff5148][b]♦[/b][/color]")
	# На тёмном сукне чёрный центр сохраняем читаемым светлой окантовкой.
	safe_text = safe_text.replace("♣", "[outline_size=2][outline_color=#e9e3cf][color=#101512][b]♣[/b][/color][/outline_color][/outline_size]")
	safe_text = safe_text.replace("♠", "[outline_size=2][outline_color=#e9e3cf][color=#101512][b]♠[/b][/color][/outline_color][/outline_size]")
	return safe_text


func _format_suit_symbols_for_light_ui(plain_text: String) -> String:
	var safe_text := plain_text.replace("[", "[lb]")
	safe_text = safe_text.replace("♥", "[color=#c91f2a][b]♥[/b][/color]")
	safe_text = safe_text.replace("♦", "[color=#c91f2a][b]♦[/b][/color]")
	safe_text = safe_text.replace("♣", "[color=#111411][b]♣[/b][/color]")
	safe_text = safe_text.replace("♠", "[color=#111411][b]♠[/b][/color]")
	return safe_text


func _get_round_type_display_name(round_type: int) -> String:
	match round_type:
		Round.RoundType.DARK:
			return "Тёмная"
		Round.RoundType.NO_TRUMP:
			return "Бескозырка"
		Round.RoundType.GOLDEN:
			return "Золотая"
		Round.RoundType.MISERE:
			return "Мизерная"
	return "Обычная"


func _get_network_scheduled_trump_text(mode_name: String, round_data: Dictionary) -> String:
	var scheduled_trump := int(round_data.get("trump", Round.TrumpSuit.NONE))
	if scheduled_trump == Round.TrumpSuit.NONE:
		return "%s: козырей нет" % mode_name
	return "%s: козырь %s (по расписанию)" % [mode_name, _get_trump_name_from_suit(scheduled_trump)]


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
	return _round_type_uses_bids(game.current_round.round_type)


func _round_type_uses_bids(round_type: int) -> bool:
	return (
		round_type == Round.RoundType.NORMAL
		or round_type == Round.RoundType.DARK
		or round_type == Round.RoundType.NO_TRUMP
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
	undo_requests_for_current_decision = 0
	_reset_undo_vote_states()


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
	assert(suited_trick.can_play_card(player, joker), "Джокер должен быть доступен даже при наличии обычной масти захода.")
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

	var alternative_player := Player.new(1, "Козырь или Джокер")
	var alternative_trump := _create_card(Card.Suit.HEARTS, Card.Rank.TEN)
	var alternative_joker := _create_card(Card.Suit.CLUBS, Card.Rank.SEVEN, true)
	var alternative_leader := Player.new(0, "Заход в пику")
	var alternative_lead := _create_card(Card.Suit.SPADES, Card.Rank.NINE)
	alternative_player.receive_card(alternative_trump)
	alternative_player.receive_card(alternative_joker)
	alternative_leader.receive_card(alternative_lead)
	var alternative_trick := Trick.new()
	alternative_trick.setup(0, 2, Round.TrumpSuit.HEARTS)
	assert(alternative_trick.play_card(alternative_leader, alternative_lead), "Проверка: заход в отсутствующую масть должен быть сыгран.")
	assert(alternative_trick.can_play_card(alternative_player, alternative_trump), "При отсутствии масти обычный козырь должен быть доступен.")
	assert(alternative_trick.can_play_card(alternative_player, alternative_joker), "При отсутствии масти Джокер должен оставаться альтернативой козырю.")

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
	response_player.bid = 1
	response_player.tricks_taken = 2
	assert(_bot_wants_trick(response_player), "Проверка бота: после перебора обычный и сложный бот должны продолжать брать взятки.")

	assert(test_game.start_round(9, Round.RoundType.GOLDEN, Round.TrumpSuit.CLUBS), "Проверка бота: золотая раздача должна запускаться.")
	assert(_bot_wants_trick(game.players[_get_current_player_index()]), "Проверка бота: в золотой раздаче бот должен стремиться брать взятки.")
	var unsafe_trump_king := _create_card(Card.Suit.CLUBS, Card.Rank.KING)
	var safe_low_lead := _create_card(Card.Suit.HEARTS, Card.Rank.SIX)
	var golden_leads: Array[Card] = [unsafe_trump_king, safe_low_lead]
	assert(
		_select_golden_lead_card(golden_leads, Round.TrumpSuit.CLUBS) == safe_low_lead,
		"Проверка бота: без козырного туза сложный бот не должен дарить козырного короля."
	)
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


func _run_network_snapshot_checks() -> void:
	var test_game := Game.new(["Игрок 1", "Игрок 2", "Игрок 3", "Игрок 4"])
	assert(
		test_game.start_round(2, Round.RoundType.GOLDEN, Round.TrumpSuit.CLUBS),
		"Проверка сети: тестовая раздача должна запускаться."
	)

	var lead_player_index := test_game.current_round.current_player_index
	var lead_card: Card = _select_non_joker_card_by_strength(test_game.players[lead_player_index].hand, false)
	var lead_played := false
	if lead_card == null:
		lead_card = test_game.players[lead_player_index].hand[0]
		lead_played = test_game.play_card(lead_player_index, lead_card, Trick.JokerMode.JOKER_WINS)
	else:
		lead_played = test_game.play_card(lead_player_index, lead_card)
	assert(
		lead_played,
		"Проверка сети: публичная карта должна быть сыграна."
	)

	var recipient_player_index := (lead_player_index + 1) % test_game.players.size()
	var player_snapshot: Dictionary = NetworkSnapshot.create_player_snapshot(test_game, recipient_player_index, 7)
	assert(
		NetworkSnapshot.is_player_snapshot_safe(player_snapshot, recipient_player_index),
		"Проверка сети: клиентский снимок не должен содержать закрытые карты соперников."
	)
	assert(
		player_snapshot["private_hand"].size() == test_game.players[recipient_player_index].hand.size(),
		"Проверка сети: игрок должен получить все карты только своей руки."
	)
	assert(
		player_snapshot["active_trick"]["played_cards"].size() == 1,
		"Проверка сети: сыгранная карта должна быть видна всем игрокам."
	)

	for player_data: Dictionary in player_snapshot["players"]:
		assert(
			not player_data.has("hand") and not player_data.has("cards"),
			"Проверка сети: в публичных данных игрока не должно быть его карт."
		)

	var host_snapshot: Dictionary = NetworkSnapshot.create_host_snapshot(test_game, 7)
	assert(
		host_snapshot["deck_cards"].size() == test_game.deck.cards_left(),
		"Проверка сети: хост должен хранить остаток общей колоды."
	)
	assert(
		host_snapshot["private_hands"].size() == test_game.players.size(),
		"Проверка сети: хост должен хранить закрытые руки всех игроков."
	)


func _run_local_match_host_checks() -> void:
	var test_game := Game.new(["Игрок 1", "Игрок 2", "Игрок 3", "Игрок 4"])
	assert(
		test_game.start_round(2, Round.RoundType.NORMAL, Round.TrumpSuit.CLUBS),
		"Проверка хоста: тестовая раздача должна запускаться."
	)

	var host = NetworkHost.new(test_game)
	var first_bidder_index := test_game.current_round.current_player_index
	var first_bid := NetworkCommand.new(
		NetworkCommand.Type.BID,
		first_bidder_index,
		test_game.round_number,
		host.revision,
		{"bid": 1}
	)
	var first_bid_result: Dictionary = host.apply_command(first_bid)
	assert(first_bid_result["accepted"], "Проверка хоста: допустимый заказ должен приниматься.")
	assert(host.revision == 1, "Проверка хоста: после принятой команды должна вырасти ревизия.")

	var stale_bid := NetworkCommand.new(
		NetworkCommand.Type.BID,
		test_game.current_round.current_player_index,
		test_game.round_number,
		0,
		{"bid": 0}
	)
	var stale_bid_result: Dictionary = host.apply_command(stale_bid)
	assert(
		not stale_bid_result["accepted"] and stale_bid_result["reason"] == "outdated_revision",
		"Проверка хоста: устаревшая команда не должна менять партию."
	)

	while test_game.current_round.state == Round.State.BIDDING:
		var bidder_index := test_game.current_round.current_player_index
		var bid_command := NetworkCommand.new(
			NetworkCommand.Type.BID,
			bidder_index,
			test_game.round_number,
			host.revision,
			{"bid": 0}
		)
		var bid_result: Dictionary = host.apply_command(bid_command)
		assert(bid_result["accepted"], "Проверка хоста: очередь допустимых заказов должна приниматься.")

	var lead_player_index := test_game.current_round.current_player_index
	var lead_card: Card
	for hand_card in test_game.players[lead_player_index].hand:
		if not hand_card.is_joker:
			lead_card = hand_card
			break
	assert(lead_card != null, "Проверка хоста: у заходящего должна быть обычная карта.")
	var play_command := NetworkCommand.new(
		NetworkCommand.Type.PLAY_CARD,
		lead_player_index,
		test_game.round_number,
		host.revision,
		{"card_key": "joker" if lead_card.is_joker else "%d_%d" % [lead_card.suit, lead_card.rank]}
	)
	var play_result: Dictionary = host.apply_command(play_command)
	assert(play_result["accepted"], "Проверка хоста: допустимый ход должен приниматься.")

	var rejected_play := NetworkCommand.new(
		NetworkCommand.Type.PLAY_CARD,
		lead_player_index,
		test_game.round_number,
		host.revision,
		{"card_key": "joker" if lead_card.is_joker else "%d_%d" % [lead_card.suit, lead_card.rank]}
	)
	var rejected_play_result: Dictionary = host.apply_command(rejected_play)
	assert(
		not rejected_play_result["accepted"] and rejected_play_result["reason"] == "rule_rejected",
		"Проверка хоста: игрок не может сходить второй раз вне очереди."
	)

	var player_snapshots := host.create_all_player_snapshots()
	assert(player_snapshots.size() == 4, "Проверка хоста: каждый игрок должен получить свой снимок.")
	for player_index in player_snapshots.size():
		assert(
			NetworkSnapshot.is_player_snapshot_safe(player_snapshots[player_index], player_index),
			"Проверка хоста: каждому игроку отправляется только безопасный снимок."
		)


func _run_network_special_round_checks() -> void:
	_run_network_joker_command_check()
	_run_network_dark_round_check()
	_run_network_no_trump_check()


func _run_network_joker_command_check() -> void:
	var test_game := Game.new(["Игрок 1", "Игрок 2", "Игрок 3", "Игрок 4"])
	assert(
		test_game.start_round(2, Round.RoundType.NORMAL, Round.TrumpSuit.CLUBS),
		"Проверка сети: обычная раздача для Джокера должна запускаться."
	)
	var host = NetworkHost.new(test_game)
	while test_game.current_round.state == Round.State.BIDDING:
		var bidder_index := test_game.current_round.current_player_index
		var bid_command := NetworkCommand.new(
			NetworkCommand.Type.BID,
			bidder_index,
			test_game.round_number,
			host.revision,
			{"bid": 0}
		)
		assert(host.apply_command(bid_command)["accepted"], "Проверка сети: заказ для Джокера должен приниматься.")

	var leader_index := test_game.current_round.current_player_index
	for player in test_game.players:
		player.hand.clear()
	test_game.players[leader_index].receive_card(_create_card(Card.Suit.CLUBS, Card.Rank.SEVEN, true))
	test_game.players[(leader_index + 1) % 4].receive_card(_create_card(Card.Suit.HEARTS, Card.Rank.SIX))
	test_game.players[(leader_index + 2) % 4].receive_card(_create_card(Card.Suit.DIAMONDS, Card.Rank.SIX))
	test_game.players[(leader_index + 3) % 4].receive_card(_create_card(Card.Suit.SPADES, Card.Rank.SIX))

	var joker_command := NetworkCommand.new(
		NetworkCommand.Type.PLAY_CARD,
		leader_index,
		test_game.round_number,
		host.revision,
		{
			"card_key": "joker",
			"joker_mode": Trick.JokerMode.HIGHEST_DECLARED_CARD_WINS,
			"declared_suit": Card.Suit.SPADES,
			"forced_card_rank": Trick.ForcedCardRank.HIGHEST
		}
	)
	assert(
		host.apply_command(joker_command)["accepted"],
		"Проверка сети: ведущий должен принять Джокера с объявленной мастью и условием."
	)
	assert(
		test_game.active_trick.joker_mode == Trick.JokerMode.HIGHEST_DECLARED_CARD_WINS,
		"Проверка сети: условие Джокера должно попасть в состояние ведущего."
	)
	assert(
		test_game.active_trick.declared_suit == Card.Suit.SPADES,
		"Проверка сети: объявленная масть Джокера должна сохраниться у ведущего."
	)


func _run_network_dark_round_check() -> void:
	var test_game := Game.new(["Игрок 1", "Игрок 2", "Игрок 3", "Игрок 4"])
	assert(
		test_game.start_round(2, Round.RoundType.DARK, Round.TrumpSuit.CLUBS, false),
		"Проверка сети: тёмная раздача должна запускаться без карт на руках."
	)
	var host = NetworkHost.new(test_game)
	assert(not test_game.cards_are_dealt, "Проверка сети: тёмные карты не должны быть розданы до заказов.")

	while test_game.current_round.state == Round.State.BIDDING:
		var bidder_index := test_game.current_round.current_player_index
		var bid_command := NetworkCommand.new(
			NetworkCommand.Type.BID,
			bidder_index,
			test_game.round_number,
			host.revision,
			{"bid": 0}
		)
		assert(host.apply_command(bid_command)["accepted"], "Проверка сети: тёмный заказ должен приниматься ведущим.")

	assert(test_game.cards_are_dealt, "Проверка сети: после последнего тёмного заказа карты должны раздаваться.")
	for player_index in test_game.players.size():
		var player_snapshot := host.create_player_snapshot(player_index)
		assert(
			player_snapshot["private_hand"].size() == 2,
			"Проверка сети: игрок должен получить только свою руку после тёмных заказов."
		)


func _run_network_no_trump_check() -> void:
	var test_game := Game.new(["Игрок 1", "Игрок 2", "Игрок 3", "Игрок 4"])
	assert(
		test_game.start_round(2, Round.RoundType.NO_TRUMP, Round.TrumpSuit.NONE),
		"Проверка сети: бескозырная раздача должна запускаться."
	)
	var host = NetworkHost.new(test_game)
	while test_game.current_round.state == Round.State.BIDDING:
		var bidder_index := test_game.current_round.current_player_index
		var bid_command := NetworkCommand.new(
			NetworkCommand.Type.BID,
			bidder_index,
			test_game.round_number,
			host.revision,
			{"bid": 0}
		)
		assert(host.apply_command(bid_command)["accepted"], "Проверка сети: бескозырный заказ должен приниматься ведущим.")

	var leader_index := test_game.current_round.current_player_index
	var joker_player_index := (leader_index + 1) % 4
	for player in test_game.players:
		player.hand.clear()
	test_game.players[leader_index].receive_card(_create_card(Card.Suit.CLUBS, Card.Rank.SIX))
	test_game.players[joker_player_index].receive_card(_create_card(Card.Suit.CLUBS, Card.Rank.SEVEN, true))
	test_game.players[joker_player_index].receive_card(_create_card(Card.Suit.CLUBS, Card.Rank.ACE))
	test_game.players[(leader_index + 2) % 4].receive_card(_create_card(Card.Suit.HEARTS, Card.Rank.SIX))
	test_game.players[(leader_index + 3) % 4].receive_card(_create_card(Card.Suit.DIAMONDS, Card.Rank.SIX))

	var lead_command := NetworkCommand.new(
		NetworkCommand.Type.PLAY_CARD,
		leader_index,
		test_game.round_number,
		host.revision,
		{"card_key": "0_0"}
	)
	assert(host.apply_command(lead_command)["accepted"], "Проверка сети: заход в бескозырке должен приниматься ведущим.")

	var joker_command := NetworkCommand.new(
		NetworkCommand.Type.PLAY_CARD,
		joker_player_index,
		test_game.round_number,
		host.revision,
		{"card_key": "joker", "joker_mode": Trick.JokerMode.JOKER_WINS}
	)
	assert(
		host.apply_command(joker_command)["accepted"],
		"Проверка сети: в бескозырке Джокер должен быть допустим даже при наличии масти захода."
	)


func _run_session_save_checks() -> void:
	var original_game := game
	var test_names: Array[String] = ["Тест 1", "Тест 2", "Тест 3", "Тест 4"]
	var test_game := Game.new(test_names)
	assert(test_game.start_round(2, Round.RoundType.NORMAL, Round.TrumpSuit.CLUBS), "Проверка сохранения: тестовая раздача должна запускаться.")
	test_game.current_round.start_playing_without_bids()
	game = test_game

	var leader_index := test_game.current_round.current_player_index
	var leading_card: Card = null
	for candidate_card in test_game.players[leader_index].hand:
		if not candidate_card.is_joker:
			leading_card = candidate_card
			break
	if leading_card == null:
		leading_card = _create_card(Card.Suit.CLUBS, Card.Rank.SIX)
		test_game.players[leader_index].receive_card(leading_card)
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
