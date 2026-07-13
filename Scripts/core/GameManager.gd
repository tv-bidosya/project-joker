extends Node


const PLAYER_NAMES := ["Андрей", "Олег", "Маша", "Лена"]


var game := Game.new(PLAYER_NAMES)


func _ready() -> void:
	if not game.start_normal_round(2):
		push_error("Не удалось начать раздачу.")
		return

	print("=== Project Joker ===")
	print("Раздача %d, сдающий: %s" % [
		game.current_round.number,
		game.players[game.dealer_index].display_name
	])
	print("Открытая карта: %s; козырь: %s" % [
		game.trump_card.get_card_name(),
		game.current_round.get_trump_name()
	])

	for player in game.players:
		print("%s: %s" % [player.display_name, player.get_hand_text()])

	_place_automatic_bids()
	_play_round_automatically()
	_print_round_result()
	_print_zero_bid_score_checks()


func _place_automatic_bids() -> void:
	print("--- Заказы ---")

	while game.current_round.state == Round.State.BIDDING:
		var player_index := game.current_round.current_player_index
		var bid := _choose_automatic_bid(player_index)

		if not game.place_bid(player_index, bid):
			push_error("Не удалось принять заказ игрока.")
			return

		print("%s заказывает %d" % [game.players[player_index].display_name, bid])


func _play_round_automatically() -> void:
	print("--- Взятки ---")

	while not game.is_round_complete():
		if game.active_trick == null:
			print("Взятка %d начинает %s" % [
				game.current_round.tricks_played + 1,
				game.players[game.current_round.lead_player_index].display_name
			])

		var player_index := _get_current_player_index()
		var player := game.players[player_index]
		var card := _choose_automatic_card(player)

		if card == null:
			push_error("Не найдена допустимая карта для хода.")
			return

		var played_successfully := false

		if card.is_joker:
			var declared_suit := _choose_joker_suit(player)
			played_successfully = game.play_card(
				player_index,
				card,
				Trick.JokerMode.JOKER_WINS,
				declared_suit
			)
		else:
			played_successfully = game.play_card(player_index, card)

		if not played_successfully:
			push_error("Недопустимый ход: %s" % player.display_name)
			return

		print("%s играет %s" % [player.display_name, card.get_card_name()])

		if game.active_trick == null:
			print("Взятку забирает %s" % game.players[game.last_trick_winner_index].display_name)


func _print_round_result() -> void:
	var round_scores := game.finish_round()

	if round_scores.is_empty():
		push_error("Раздача не завершена.")
		return

	print("--- Результат раздачи ---")

	for player_index in game.players.size():
		var player := game.players[player_index]
		print("%s: заказ %d, взято %d, очки за раздачу %d, всего %d" % [
			player.display_name,
			player.bid,
			player.tricks_taken,
			round_scores[player_index],
			player.total_score
		])

	game.advance_dealer()
	print("Следующая раздача: сдаёт %s" % game.players[game.dealer_index].display_name)


func _choose_automatic_bid(player_index: int) -> int:
	var desired_bid := 1 if player_index % 2 == 0 else 0

	if game.current_round.can_place_bid(player_index, desired_bid):
		return desired_bid

	for bid in game.current_round.cards_per_player + 1:
		if game.current_round.can_place_bid(player_index, bid):
			return bid

	return -1


func _get_current_player_index() -> int:
	if game.active_trick == null:
		return game.current_round.lead_player_index

	return game.active_trick.current_player_index


func _choose_automatic_card(player: Player) -> Card:
	for card in player.hand:
		if game.active_trick == null or game.active_trick.can_play_card(player, card):
			return card

	return null


func _choose_joker_suit(player: Player) -> int:
	for card in player.hand:
		if not card.is_joker:
			return card.suit

	return Card.Suit.CLUBS


func _print_zero_bid_score_checks() -> void:
	print("--- Проверка заказа 0 ---")
	print("Обычная: заказ 0, взято 0, очки %d" % ScoreCalculator.calculate_round_score(
		Round.RoundType.NORMAL,
		0,
		0
	))
	print("Тёмная: заказ 0, взято 0, очки %d" % ScoreCalculator.calculate_round_score(
		Round.RoundType.DARK,
		0,
		0
	))
