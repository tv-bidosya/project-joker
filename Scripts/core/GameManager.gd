extends Control


const PLAYER_NAMES := ["Андрей", "Олег", "Маша", "Лена"]
const HUMAN_PLAYER_INDEX := 0
const NORMAL_ROUND_COUNT := 13


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
@onready var next_round_button: Button = %NextRoundButton


var game := Game.new(PLAYER_NAMES)
var player_labels: Array[Label] = []
var trick_card_labels: Array[Label] = []
var pending_joker_card: Card
var last_trick_text := "Взятка ещё не началась"
var action_text := "Подготовка партии"
var recent_actions := PackedStringArray()
var normal_round_index := 0
var is_processing_automatic_actions := false


func _ready() -> void:
	_run_joker_rule_checks()
	_create_player_panels()
	_create_trick_slots()
	next_round_button.pressed.connect(_on_next_round_pressed)
	_start_round()


func _start_round() -> void:
	pending_joker_card = null
	last_trick_text = "Взятка ещё не началась"
	recent_actions.clear()

	var cards_per_player := _get_cards_per_player_for_current_round()
	var trump := _get_trump_for_current_round()

	if not game.start_round(cards_per_player, Round.RoundType.NORMAL, trump):
		action_text = "Не удалось начать раздачу."
		_refresh_ui()
		return

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

	if not game.place_bid(player_index, bid):
		action_text = "Ошибка автоматического заказа."
		return false

	action_text = "%s заказывает %d." % [game.players[player_index].display_name, bid]
	_add_history(action_text)
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
	if not game.place_bid(HUMAN_PLAYER_INDEX, bid):
		action_text = "Этот заказ сейчас недоступен."
		_refresh_ui()
		return

	action_text = "Ты заказываешь %d." % bid
	_add_history(action_text)
	_refresh_ui()
	_advance_automatic_actions()


func _on_card_pressed(card: Card) -> void:
	if not _is_human_turn() or not _is_card_available_to_human(card):
		return

	if card.is_joker:
		pending_joker_card = card
		action_text = "Выбери условие для Джокера."
		_refresh_ui()
		return

	if not game.play_card(HUMAN_PLAYER_INDEX, card):
		action_text = "Эту карту сейчас играть нельзя."
		_refresh_ui()
		return

	_record_play("Ты", card)
	_refresh_ui()
	_advance_automatic_actions()


func _on_joker_choice(mode: Trick.JokerMode, declared_suit: int = -1) -> void:
	if pending_joker_card == null:
		return

	if not game.play_card(HUMAN_PLAYER_INDEX, pending_joker_card, mode, declared_suit):
		action_text = "Условие Джокера не удалось применить."
		pending_joker_card = null
		_refresh_ui()
		return

	_record_play("Ты", pending_joker_card)
	pending_joker_card = null
	_refresh_ui()
	_advance_automatic_actions()


func _on_next_round_pressed() -> void:
	if normal_round_index >= NORMAL_ROUND_COUNT - 1:
		return

	game.advance_dealer()
	normal_round_index += 1
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
		result_lines.append("%s: заказ %d, взято %d, очки %d" % [
			player.display_name,
			player.bid,
			player.tricks_taken,
			round_scores[player_index]
		])

	action_text = "Раздача завершена.\n%s" % "\n".join(result_lines)
	next_round_button.visible = true

	if normal_round_index >= NORMAL_ROUND_COUNT - 1:
		next_round_button.text = "Обычная серия завершена"
		next_round_button.disabled = true
		_add_history("Обычная серия из 13 раздач завершена.")
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


func _refresh_header() -> void:
	match game.current_round.state:
		Round.State.BIDDING:
			phase_label.text = "Раздача %d/%d · заказ взяток" % [normal_round_index + 1, NORMAL_ROUND_COUNT]
		Round.State.PLAYING:
			phase_label.text = "Раздача %d/%d · розыгрыш взяток" % [normal_round_index + 1, NORMAL_ROUND_COUNT]
		Round.State.FINISHED:
			phase_label.text = "Раздача %d/%d · завершена" % [normal_round_index + 1, NORMAL_ROUND_COUNT]
		_:
			phase_label.text = "Этап: подготовка"

	if game.trump_card == null:
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
		var bid_text := "—" if player.bid < 0 else str(player.bid)

		player_labels[player_index].text = "%s%s%s\nКарт: %d | Заказ: %s\nВзято: %d | Очки: %d" % [
			marker,
			player.display_name,
			person_label,
			player.hand.size(),
			bid_text,
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
		for suit in Card.Suit.values():
			_add_joker_choice_button("%s: Джокер забирает" % _get_suit_symbol(suit), Trick.JokerMode.JOKER_WINS, suit)
			_add_joker_choice_button("%s: старшая забирает" % _get_suit_symbol(suit), Trick.JokerMode.HIGHEST_DECLARED_CARD_WINS, suit)
			_add_joker_choice_button("%s: младшая забирает" % _get_suit_symbol(suit), Trick.JokerMode.LOWEST_DECLARED_CARD_WINS, suit)
	else:
		_add_joker_choice_button("Джокер забирает", Trick.JokerMode.JOKER_WINS)
		_add_joker_choice_button("Сбросить: младшая масть забирает", Trick.JokerMode.LOWEST_DECLARED_CARD_WINS)


func _refresh_hand() -> void:
	_clear_children(hand_container)

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


func _add_joker_choice_button(label: String, mode: Trick.JokerMode, declared_suit: int = -1) -> void:
	var choice_button := Button.new()
	choice_button.text = label
	choice_button.pressed.connect(_on_joker_choice.bind(mode, declared_suit))
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

	return "Текущая взятка\n%s" % "   •   ".join(play_texts)


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
	if normal_round_index < 8:
		return normal_round_index + 1

	return 9


func _get_trump_for_current_round() -> Round.TrumpSuit:
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


func _create_card(suit: Card.Suit, rank: Card.Rank, is_joker := false) -> Card:
	var card := Card.new()
	card.suit = suit
	card.rank = rank
	card.is_joker = is_joker
	return card


func _clear_children(container: Container) -> void:
	for child in container.get_children():
		child.queue_free()
