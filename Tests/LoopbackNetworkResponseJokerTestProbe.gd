extends SceneTree


const LoopbackNetwork = preload("res://Scripts/core/LoopbackNetworkTest.gd")
const TEST_TIMEOUT_SECONDS := 15.0
const TEST_PORT := 24571


var host
var clients: Array = []
var elapsed_seconds := 0.0
var round_started := false
var lead_card_sent := false
var response_joker_sent := false
var third_card_sent := false
var host_card_sent := false
var response_joker_mode: Trick.JokerMode = Trick.JokerMode.NORMAL_CARD_WINS


func _init() -> void:
	if OS.get_cmdline_user_args().has("--response-joker-wins"):
		response_joker_mode = Trick.JokerMode.JOKER_WINS
	host = LoopbackNetwork.new()
	root.add_child(host)
	assert(host.start_host(TEST_PORT), "Проверка ENet-ответа Джокером: хост не смог запуститься.")

	for player_index in range(1, 4):
		var client = LoopbackNetwork.new()
		clients.append(client)
		root.add_child(client)
		assert(client.start_client(player_index, TEST_PORT), "Проверка ENet-ответа Джокером: клиент %d не смог подключиться." % (player_index + 1))


func _process(delta: float) -> bool:
	elapsed_seconds += delta
	if host.is_lobby_full() and not round_started:
		assert(host.start_test_round_with_response_joker(), "Проверка ENet-ответа Джокером: не удалось подготовить Джокер у следующего игрока.")
		round_started = true

	if round_started and _are_all_clients_ready():
		_submit_next_bid_if_needed()
		if host.match_host.revision == 4 and _all_clients_received_revision(4) and not lead_card_sent:
			var leading_client = clients[0]
			var available_cards: Array[Dictionary] = leading_client.get_available_test_cards()
			assert(not available_cards.is_empty(), "Проверка ENet-ответа Джокером: у первого игрока нет обычной карты для захода.")
			assert(leading_client.submit_test_card(str(available_cards[0].get("card_key", ""))), "Проверка ENet-ответа Джокером: первый игрок не смог сделать обычный заход.")
			lead_card_sent = true

		if lead_card_sent and host.match_host.revision == 5 and _all_clients_received_revision(5) and not response_joker_sent:
			var response_client = clients[1]
			assert(response_client.can_submit_test_joker(), "Проверка ENet-ответа Джокером: следующий игрок не получил доступный Джокер.")
			assert(not response_client.is_client_test_joker_leading(), "Проверка ENet-ответа Джокером: Джокер ошибочно считается первым ходом.")
			assert(
				response_client.submit_test_joker_choice(response_joker_mode),
				"Проверка ENet-ответа Джокером: не удалось отправить выбранный вариант ответа Джокером."
			)
			response_joker_sent = true

		if response_joker_sent and host.match_host.revision == 6 and _all_clients_received_revision(6) and not third_card_sent:
			var third_client = clients[2]
			var available_cards: Array[Dictionary] = third_client.get_available_test_cards()
			assert(not available_cards.is_empty(), "Проверка ENet-ответа Джокером: третьему игроку не выдан допустимый ответ.")
			assert(third_client.submit_test_card(str(available_cards[0].get("card_key", ""))), "Проверка ENet-ответа Джокером: третий игрок не смог ответить.")
			third_card_sent = true

		if third_card_sent and host.match_host.revision == 7 and _all_clients_received_revision(7) and not host_card_sent:
			var available_cards: Array[Dictionary] = host.get_available_host_test_cards()
			assert(not available_cards.is_empty(), "Проверка ENet-ответа Джокером: у хоста нет допустимого ответа.")
			assert(host.submit_host_test_card(str(available_cards[0].get("card_key", ""))), "Проверка ENet-ответа Джокером: хост не смог завершить взятку.")
			host_card_sent = true

		if host_card_sent and host.match_host.revision == 8 and _all_clients_received_revision(8):
			var game: Game = host.match_host.game
			assert(game.current_round.state == Round.State.PLAYING and game.current_round.tricks_played == 1, "Проверка ENet-ответа Джокером: после четырёх ходов должна завершиться одна взятка.")
			assert(game.last_completed_trick_cards.size() == 4, "Проверка ENet-ответа Джокером: хост не сохранил четыре карты взятки.")
			assert(game.last_completed_trick_cards[1].is_joker, "Проверка ENet-ответа Джокером: второй картой должен быть Джокер.")
			assert(game.last_completed_trick_joker_mode == response_joker_mode, "Проверка ENet-ответа Джокером: хост не сохранил выбранный режим ответа Джокером.")
			for client in clients:
				var snapshot: Dictionary = client.client_snapshot
				var last_trick: Dictionary = snapshot.get("last_completed_trick", {})
				assert(last_trick.get("cards", []).size() == 4, "Проверка ENet-ответа Джокером: клиент не увидел четыре карты завершённой взятки.")
				assert(bool(last_trick.get("cards", [])[1].get("is_joker", false)), "Проверка ENet-ответа Джокером: клиент не увидел Джокер на второй позиции.")
				assert(int(last_trick.get("joker_mode", Trick.JokerMode.NONE)) == response_joker_mode, "Проверка ENet-ответа Джокером: клиент не получил выбранный режим Джокера.")
			print("Four-seat loopback ENet response Joker test passed: %s." % ["wins" if response_joker_mode == Trick.JokerMode.JOKER_WINS else "discard"])
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
		push_error("Проверка ENet-ответа Джокером не завершилась. Хост: %s. Клиенты: %s" % [host.status_text.replace("\n", " | "), " || ".join(client_diagnostics)])
		quit(1)
		return true

	return false


func _are_all_clients_ready() -> bool:
	for client_index in clients.size():
		var client = clients[client_index]
		if not client.client_seat_confirmed or not client.client_snapshot_is_safe:
			return false
		assert(client.client_player_index == client_index + 1, "Проверка ENet-ответа Джокером: клиент получил неверное место.")
		if host.match_host.revision <= 4:
			assert(client.client_private_hand_size == 2, "Проверка ENet-ответа Джокером: клиент должен получить только две личные карты.")
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
			assert(not available_bids.is_empty(), "Проверка ENet-ответа Джокером: у клиента нет допустимого заказа.")
			assert(client.submit_test_bid(available_bids[0]), "Проверка ENet-ответа Джокером: клиент не смог отправить заказ.")
			return
	if host.can_submit_host_test_bid():
		var available_bids: Array[int] = host.get_available_host_test_bids()
		assert(not available_bids.is_empty(), "Проверка ENet-ответа Джокером: у хоста нет допустимого заказа.")
		assert(host.submit_host_test_bid(available_bids[0]), "Проверка ENet-ответа Джокером: хост не смог подтвердить заказ.")
