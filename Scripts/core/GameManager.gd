extends Control


const PLAYER_NAMES := ["Андрей", "Олег", "Маша", "Лена"]
const HUMAN_PLAYER_INDEX := 0
const NORMAL_ROUND_COUNT := 13
const DARK_ROUND_COUNT := 5
const NO_TRUMP_ROUND_COUNT := 4
const GOLDEN_ROUND_COUNT := 5
const MISERE_ROUND_COUNT := 5


@onready var phase_label: Label = %PhaseLabel
@onready var trump_label: Label = %TrumpLabel
@onready var players_container: GridContainer = %PlayersContainer
@onready var table_label: Label = %TableLabel
@onready var trick_slots: GridContainer = %TrickSlots
@onready var action_label: Label = %ActionLabel
@onready var history_label: Label = %HistoryLabel
@onready var bid_controls: HBoxContainer = %BidControls
@onready var joker_controls: GridContainer = %JokerControls
@onready var hand_container: HBoxContainer = %HandContainer
@onready var undo_button: Button = %UndoButton
@onready var next_round_button: Button = %NextRoundButton


var game := Game.new(PLAYER_NAMES)
var player_labels: Array[Label] = []
var trick_card_labels: Array[Label] = []
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
var test_checkpoints: Array[Dictionary] = []
var pending_test_checkpoint: Dictionary = {}


func _ready() -> void:
	_run_joker_rule_checks()
	_run_score_rule_checks()
	_run_dark_round_checks()
	_run_no_trump_round_checks()
	_run_no_bid_round_checks()
	_create_player_panels()
	_create_trick_slots()
	undo_button.pressed.connect(_on_undo_pressed)
	next_round_button.pressed.connect(_on_next_round_pressed)
	_start_round()


func _start_round() -> void:
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
	_advance_automatic_actions()


func _advance_automatic_actions() -> void:
	if is_processing_automatic_actions:
		return

	is_processing_automatic_actions = true

	while true:
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
			await get_tree().create_timer(0.45).timeout
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

			if not _play_automatic_card():
				is_processing_automatic_actions = false
				_refresh_ui()
				return

			_refresh_ui()
			await get_tree().create_timer(0.65).timeout
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
	return true


func _play_automatic_card() -> bool:
	var player_index := _get_current_player_index()
	var player := game.players[player_index]
	var card := _choose_automatic_card(player)

	if card == null:
		action_text = "Автоматический игрок не нашёл допустимую карту."
		return false

	var played_successfully := false

	if card.is_joker:
		played_successfully = game.play_card(
			player_index,
			card,
			Trick.JokerMode.JOKER_WINS,
			_choose_joker_suit(player)
		)
	else:
		played_successfully = game.play_card(player_index, card)

	if not played_successfully:
		action_text = "Недопустимый автоматический ход."
		return false

	_record_play(player.display_name, card)
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

	_record_play("Ты", card)
	_refresh_ui()
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

	_record_play("Ты", pending_joker_card)
	if is_leading_joker:
		_add_history(_get_joker_declaration_text(mode, declared_suit, forced_card_rank))
	pending_joker_card = null
	pending_joker_suit = -1
	_refresh_ui()
	_advance_automatic_actions()


func _on_undo_pressed() -> void:
	if is_processing_automatic_actions or test_checkpoints.is_empty():
		return

	var checkpoint: Dictionary = test_checkpoints.pop_back()
	game.restore_snapshot(checkpoint["game"])
	pending_joker_card = null
	pending_joker_suit = -1
	last_trick_text = checkpoint["last_trick_text"]
	action_text = "Тест: возвращено к началу прошлого твоего решения."
	recent_actions = checkpoint["recent_actions"].duplicate()
	pending_test_checkpoint = _create_test_checkpoint()
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
	else:
		next_round_button.text = "Следующая раздача"
		_add_history("Раздача завершена. Следующим сдаёт %s." % game.players[(game.dealer_index + 1) % game.players.size()].display_name)

	_refresh_ui()


func _record_play(player_name: String, card: Card) -> void:
	_add_history("%s сыграл %s." % [player_name, card.get_card_name()])

	if game.active_trick == null:
		last_trick_text = "%s сыграл %s. Взятку забирает %s." % [
			player_name,
			card.get_card_name(),
			game.players[game.last_trick_winner_index].display_name
		]
		_add_history("Взятку забирает %s." % game.players[game.last_trick_winner_index].display_name)
	else:
		last_trick_text = _get_active_trick_text()


func _refresh_ui() -> void:
	_refresh_header()
	_refresh_player_panels()
	_refresh_table()
	_refresh_history()
	_refresh_bid_controls()
	_refresh_joker_controls()
	_refresh_hand()
	_refresh_undo_button()


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
	else:
		trump_label.text = "Открыта %s · козырь %s" % [
			game.trump_card.get_card_name(),
			game.current_round.get_trump_name()
		]
	action_label.text = action_text


func _refresh_player_panels() -> void:
	for player_index in game.players.size():
		var player := game.players[player_index]
		var is_current := _get_current_player_index() == player_index and game.current_round.state != Round.State.FINISHED
		var marker := "▶ " if is_current else ""
		var person_label := " (ты)" if player_index == HUMAN_PLAYER_INDEX else ""
		var hand_text := "скрыто" if _is_dark_round() and not game.cards_are_dealt else str(player.hand.size())

		if _round_uses_bids():
			var bid_text := "—" if player.bid < 0 else str(player.bid)
			player_labels[player_index].text = "%s%s%s\nКарт: %s | Заказ: %s\nВзято: %d | Очки: %d" % [
				marker,
				player.display_name,
				person_label,
				hand_text,
				bid_text,
				player.tricks_taken,
				player.total_score
			]
		else:
			player_labels[player_index].text = "%s%s%s\nКарт: %s\nВзято: %d | Очки: %d" % [
				marker,
				player.display_name,
				person_label,
				hand_text,
				player.tricks_taken,
				player.total_score
			]


func _refresh_table() -> void:
	if game.active_trick == null:
		table_label.text = last_trick_text
	else:
		table_label.text = _get_active_trick_text()

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
		var card_text := card.get_card_name() if card != null else "—"
		trick_card_labels[player_index].text = "%s\n%s" % [
			game.players[player_index].display_name,
			card_text
		]


func _refresh_history() -> void:
	if recent_actions.is_empty():
		history_label.text = "Последние действия: —"
		return

	history_label.text = "Последние действия\n%s" % "\n".join(recent_actions)


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
		return

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

	for card in human_player.hand:
		var card_button := Button.new()
		card_button.custom_minimum_size = Vector2(80, 112)
		card_button.text = card.get_card_name()
		card_button.tooltip_text = card.get_card_name()
		card_button.add_theme_font_size_override("font_size", 21)
		card_button.disabled = not _is_human_turn() or not _is_card_available_to_human(card) or pending_joker_card != null

		if card.suit == Card.Suit.HEARTS or card.suit == Card.Suit.DIAMONDS:
			card_button.add_theme_color_override("font_color", Color(0.8, 0.08, 0.08))

		card_button.pressed.connect(_on_card_pressed.bind(card))
		hand_container.add_child(card_button)


func _refresh_undo_button() -> void:
	undo_button.disabled = (
		is_processing_automatic_actions
		or test_checkpoints.is_empty()
		or game.current_round.state == Round.State.FINISHED
	)


func _create_player_panels() -> void:
	for player_name in PLAYER_NAMES:
		var panel := PanelContainer.new()
		panel.custom_minimum_size = Vector2(180, 78)

		var label := Label.new()
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 16)
		panel.add_child(label)
		players_container.add_child(panel)
		player_labels.append(label)


func _create_trick_slots() -> void:
	for player_name in PLAYER_NAMES:
		var panel := PanelContainer.new()
		panel.custom_minimum_size = Vector2(220, 72)

		var label := Label.new()
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 18)
		panel.add_child(label)
		trick_slots.add_child(panel)
		trick_card_labels.append(label)


func _add_joker_suit_button(label: String, suit: int) -> void:
	var suit_button := Button.new()
	suit_button.text = label

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
	var desired_bid := 1 if player_index % 2 == 0 else 0

	if game.current_round.can_place_bid(player_index, desired_bid):
		return desired_bid

	for bid in game.current_round.cards_per_player + 1:
		if game.current_round.can_place_bid(player_index, bid):
			return bid

	return -1


func _choose_automatic_card(player: Player) -> Card:
	for card in player.hand:
		if not card.is_joker and (game.active_trick == null or game.active_trick.can_play_card(player, card)):
			return card

	for card in player.hand:
		if card.is_joker and (game.active_trick == null or game.active_trick.can_play_card(player, card)):
			return card

	return null


func _choose_joker_suit(player: Player) -> int:
	for card in player.hand:
		if not card.is_joker:
			return card.suit

	return Card.Suit.CLUBS


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

	if recent_actions.size() > 6:
		recent_actions.remove_at(0)


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


func _create_card(suit: Card.Suit, rank: Card.Rank, is_joker := false) -> Card:
	var card := Card.new()
	card.suit = suit
	card.rank = rank
	card.is_joker = is_joker
	return card


func _clear_children(container: Container) -> void:
	for child in container.get_children():
		child.queue_free()
