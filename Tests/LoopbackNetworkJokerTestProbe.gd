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

		if follower_card_sent and host.match_host.revision == 6 and host._snapshot_acknowledged_by_player.size() == 3:
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
			print("Four-seat loopback ENet Joker command test passed.")
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
