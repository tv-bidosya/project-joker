extends SceneTree


const LoopbackNetwork = preload("res://Scripts/core/LoopbackNetworkTest.gd")
const TEST_TIMEOUT_SECONDS := 15.0
const TEST_PORT := 24570


var host
var clients: Array = []
var elapsed_seconds := 0.0
var round_started := false
var joker_sent := false
var follower_card_sent := false
var third_card_sent := false
var host_first_trick_card_sent := false
var second_trick_lead_sent := false
var second_trick_response_sent := false
var second_trick_third_card_sent := false
var second_trick_host_card_sent := false


func _init() -> void:
	host = LoopbackNetwork.new()
	root.add_child(host)
	assert(host.start_host(TEST_PORT), "Проверка ENet-Джокера: хост не смог запуститься.")

	for player_index in range(1, 4):
		var client = LoopbackNetwork.new()
		clients.append(client)
		root.add_child(client)
		assert(client.start_client(player_index, TEST_PORT), "Проверка ENet-Джокера: клиент %d не смог подключиться." % (player_index + 1))


func _process(delta: float) -> bool:
	elapsed_seconds += delta
	if host.is_lobby_full() and not round_started:
		assert(host.start_test_round(true), "Проверка ENet-Джокера: не удалось начать раздачу с Джокером у первого игрока.")
		round_started = true

	if round_started and _are_all_clients_ready():
		_submit_next_bid_if_needed()
		if host.match_host.revision == 4 and _all_clients_received_revision(4) and not joker_sent:
			var leading_client = clients[0]
			if not leading_client.can_submit_test_joker() or not leading_client.is_client_test_joker_leading():
				return false
			assert(
				leading_client.submit_test_joker_choice(
					Trick.JokerMode.JOKER_WINS,
					Card.Suit.DIAMONDS,
					Trick.ForcedCardRank.HIGHEST
				),
				"Проверка ENet-Джокера: клиент не смог отправить условие Джокера хосту."
			)
			joker_sent = true

		if joker_sent and host.match_host.revision == 5 and host._snapshot_acknowledged_by_player.size() == 3 and not follower_card_sent:
			var follower_client = clients[1]
			if not follower_client.can_submit_test_card():
				return false
			var available_cards: Array[Dictionary] = follower_client.get_available_test_cards()
			assert(not available_cards.is_empty(), "Проверка ENet-Джокера: следующий игрок должен получить допустимую обычную карту после Джокера.")
			assert(follower_client.submit_test_card(str(available_cards[0].get("card_key", ""))), "Проверка ENet-Джокера: следующий игрок не смог отправить допустимую карту после Джокера.")
			follower_card_sent = true

		if follower_card_sent and host.match_host.revision == 6 and _all_clients_received_revision(6) and not third_card_sent:
			var active_trick: Trick = host.match_host.game.active_trick
			assert(active_trick != null, "Проверка ENet-Джокера: после первого хода должна существовать активная взятка.")
			assert(active_trick.played_cards.size() == 2 and active_trick.played_cards[0].is_joker, "Проверка ENet-Джокера: на столе должны лежать Джокер и ответная карта.")
			assert(active_trick.joker_mode == Trick.JokerMode.JOKER_WINS, "Проверка ENet-Джокера: хост не сохранил режим Джокер забирает.")
			assert(active_trick.declared_suit == Card.Suit.DIAMONDS, "Проверка ENet-Джокера: хост не сохранил объявленную масть.")
			assert(active_trick.forced_card_rank == Trick.ForcedCardRank.HIGHEST, "Проверка ENet-Джокера: хост не сохранил требование старшей карты.")
			for client in clients:
				var snapshot: Dictionary = client.client_snapshot
				var public_trick: Dictionary = snapshot.get("active_trick", {})
				assert(int(snapshot.get("revision", -1)) == 6, "Проверка ENet-Джокера: клиент не получил свежий снимок стола.")
				assert(public_trick.get("played_cards", []).size() == 2, "Проверка ENet-Джокера: клиент должен увидеть Джокера и ответную карту на общем столе.")
				assert(int(public_trick.get("joker_mode", Trick.JokerMode.NONE)) == Trick.JokerMode.JOKER_WINS, "Проверка ENet-Джокера: клиент не получил режим Джокера.")
				assert(int(public_trick.get("declared_suit", -1)) == Card.Suit.DIAMONDS, "Проверка ENet-Джокера: клиент не получил объявленную масть.")
			var third_client = clients[2]
			var third_available_cards: Array[Dictionary] = third_client.get_available_test_cards()
			assert(not third_available_cards.is_empty(), "Проверка ENet-Джокера: третьему игроку не выдан допустимый ответ на условие Джокера.")
			assert(third_client.submit_test_card(str(third_available_cards[0].get("card_key", ""))), "Проверка ENet-Джокера: третий игрок не смог ответить на условие Джокера.")
			third_card_sent = true

		if third_card_sent and host.match_host.revision == 7 and _all_clients_received_revision(7) and not host_first_trick_card_sent:
			var host_available_cards: Array[Dictionary] = host.get_available_host_test_cards()
			assert(not host_available_cards.is_empty(), "Проверка ENet-Джокера: хосту не выдан допустимый ответ на условие Джокера.")
			assert(host.submit_host_test_card(str(host_available_cards[0].get("card_key", ""))), "Проверка ENet-Джокера: хост не смог завершить особую взятку.")
			host_first_trick_card_sent = true

		if host_first_trick_card_sent and host.match_host.revision == 8 and _all_clients_received_revision(8) and not second_trick_lead_sent:
			var game_after_first_trick: Game = host.match_host.game
			assert(game_after_first_trick.current_round.state == Round.State.PLAYING and game_after_first_trick.current_round.tricks_played == 1, "Проверка ENet-Джокера: после особой взятки должна начаться следующая.")
			assert(game_after_first_trick.last_trick_winner_index == 1, "Проверка ENet-Джокера: ведущий Джокер в режиме «забирает» должен выиграть взятку.")
			assert(game_after_first_trick.current_round.lead_player_index == 1, "Проверка ENet-Джокера: следующую взятку должен начать победитель.")
			assert(game_after_first_trick.players[1].tricks_taken == 1, "Проверка ENet-Джокера: хост не учёл взятку победителю.")
			var next_leader = clients[0]
			var next_leader_cards: Array[Dictionary] = next_leader.get_available_test_cards()
			assert(not next_leader_cards.is_empty(), "Проверка ENet-Джокера: победитель не получил ход в следующей взятке.")
			assert(next_leader.submit_test_card(str(next_leader_cards[0].get("card_key", ""))), "Проверка ENet-Джокера: победитель не смог начать следующую взятку.")
			second_trick_lead_sent = true

		if second_trick_lead_sent and host.match_host.revision == 9 and _all_clients_received_revision(9) and not second_trick_response_sent:
			var second_client = clients[1]
			var second_client_cards: Array[Dictionary] = second_client.get_available_test_cards()
			assert(not second_client_cards.is_empty(), "Проверка ENet-Джокера: следующему игроку не выдан допустимый ответ второй взятки.")
			assert(second_client.submit_test_card(str(second_client_cards[0].get("card_key", ""))), "Проверка ENet-Джокера: следующий игрок не смог ответить во второй взятке.")
			second_trick_response_sent = true

		if second_trick_response_sent and host.match_host.revision == 10 and _all_clients_received_revision(10) and not second_trick_third_card_sent:
			var third_client = clients[2]
			var second_third_cards: Array[Dictionary] = third_client.get_available_test_cards()
			assert(not second_third_cards.is_empty(), "Проверка ENet-Джокера: третьему игроку не выдан допустимый ответ второй взятки.")
			assert(third_client.submit_test_card(str(second_third_cards[0].get("card_key", ""))), "Проверка ENet-Джокера: третий игрок не смог ответить во второй взятке.")
			second_trick_third_card_sent = true

		if second_trick_third_card_sent and host.match_host.revision == 11 and _all_clients_received_revision(11) and not second_trick_host_card_sent:
			var host_second_cards: Array[Dictionary] = host.get_available_host_test_cards()
			assert(not host_second_cards.is_empty(), "Проверка ENet-Джокера: хосту не выдан последний ответ второй взятки.")
			assert(host.submit_host_test_card(str(host_second_cards[0].get("card_key", ""))), "Проверка ENet-Джокера: хост не смог завершить раздачу.")
			second_trick_host_card_sent = true

		if second_trick_host_card_sent and host.match_host.revision == 12 and _all_clients_received_revision(12):
			var completed_game: Game = host.match_host.game
			assert(completed_game.current_round.state == Round.State.FINISHED, "Проверка ENet-Джокера: хост не завершил раздачу после последней взятки.")
			assert(completed_game.current_round.tricks_played == 2, "Проверка ENet-Джокера: хост не учёл обе взятки раздачи.")
			var total_taken_tricks := 0
			for player in completed_game.players:
				total_taken_tricks += player.tricks_taken
				var expected_score := ScoreCalculator.calculate_round_score(completed_game.current_round.round_type, player.bid, player.tricks_taken)
				assert(player.total_score == expected_score, "Проверка ENet-Джокера: хост неверно посчитал итоговый счёт игрока.")
			assert(total_taken_tricks == 2, "Проверка ENet-Джокера: сумма взяток игроков должна совпадать с числом взяток раздачи.")
			for client in clients:
				var snapshot: Dictionary = client.client_snapshot
				var public_players: Array = snapshot.get("players", [])
				var public_round: Dictionary = snapshot.get("round", {})
				assert(int(snapshot.get("revision", -1)) == 12, "Проверка ENet-Джокера: клиент не получил финальный снимок раздачи.")
				assert(int(public_round.get("state", -1)) == Round.State.FINISHED and int(public_round.get("tricks_played", -1)) == 2, "Проверка ENet-Джокера: клиент не получил завершение раздачи и число взяток.")
				assert(public_players.size() == 4, "Проверка ENet-Джокера: клиент не получил публичный итог всех игроков.")
				for player_index in public_players.size():
					var public_player: Dictionary = public_players[player_index]
					var host_player: Player = completed_game.players[player_index]
					assert(int(public_player.get("tricks_taken", -1)) == host_player.tricks_taken, "Проверка ENet-Джокера: клиент получил неверное число взяток игрока.")
					assert(int(public_player.get("total_score", -9999)) == host_player.total_score, "Проверка ENet-Джокера: клиент получил неверный итоговый счёт игрока.")
			print("Four-seat loopback ENet Joker full-round test passed.")
			quit(0)
			return true

	if elapsed_seconds >= TEST_TIMEOUT_SECONDS:
		var client_diagnostics: Array[String] = []
		for client in clients:
			client_diagnostics.append("место %d: ревизия %d, в_полёте=%s, %s" % [
				client.client_player_index + 1,
				int(client.client_snapshot.get("revision", -1)),
				str(client.client_command_in_flight),
				client.status_text.replace("\n", " | ")
			])
		push_error("Проверка ENet-Джокера не завершилась. Хост: %s. Клиенты: %s" % [host.status_text.replace("\n", " | "), " || ".join(client_diagnostics)])
		quit(1)
		return true

	return false


func _are_all_clients_ready() -> bool:
	for client_index in clients.size():
		var client = clients[client_index]
		if not client.client_seat_confirmed or not client.client_snapshot_is_safe:
			return false
		assert(client.client_player_index == client_index + 1, "Проверка ENet-Джокера: клиент получил неверное место.")
		if host.match_host.revision <= 4:
			assert(client.client_private_hand_size == 2, "Проверка ENet-Джокера: клиент должен получить только две личные карты.")
	return true


func _all_clients_received_revision(revision: int) -> bool:
	for client in clients:
		if int(client.client_snapshot.get("revision", -1)) < revision or client.client_command_in_flight:
			return false
	return true


func _submit_next_bid_if_needed() -> void:
	for client in clients:
		if client.can_submit_test_bid():
			var available_bids: Array[int] = client.get_available_test_bids()
			assert(not available_bids.is_empty(), "Проверка ENet-Джокера: у клиента нет допустимого заказа.")
			assert(client.submit_test_bid(available_bids[0]), "Проверка ENet-Джокера: клиент не смог отправить заказ.")
			return
	if host.can_submit_host_test_bid():
		var available_bids: Array[int] = host.get_available_host_test_bids()
		assert(not available_bids.is_empty(), "Проверка ENet-Джокера: у хоста нет допустимого заказа.")
		assert(host.submit_host_test_bid(available_bids[0]), "Проверка ENet-Джокера: хост не смог подтвердить заказ.")
