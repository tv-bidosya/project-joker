extends SceneTree


const LoopbackNetwork = preload("res://Scripts/core/LoopbackNetworkTest.gd")
const LocalMatchHost = preload("res://Scripts/core/LocalMatchHost.gd")
const MatchCommand = preload("res://Scripts/core/MatchCommand.gd")
const TEST_TIMEOUT_SECONDS := 15.0
const TEST_PORT := 24568


var host
var clients: Array = []
var elapsed_seconds := 0.0
var round_started := false
var social_actions_checked := false


func _init() -> void:
	_verify_authoritative_undo_vote()
	host = LoopbackNetwork.new()
	root.add_child(host)
	assert(host.start_host(TEST_PORT), "Проверка ENet-лобби: хост не смог запуститься.")

	for player_index in range(1, 4):
		var client = LoopbackNetwork.new()
		clients.append(client)
		root.add_child(client)
		assert(client.start_client(player_index, TEST_PORT), "Проверка ENet-лобби: клиент %d не смог начать подключение." % (player_index + 1))


func _verify_authoritative_undo_vote() -> void:
	var game := Game.new(["Хост", "Игрок 2", "Бот 1", "Бот 2"])
	game.dealer_index = 0
	assert(game.start_round(1, Round.RoundType.NORMAL, Round.TrumpSuit.CLUBS), "Проверка возврата: не удалось начать раздачу.")
	var match_host := LocalMatchHost.new(game)
	match_host.record_current_round_started()
	match_host.set_automatic_undo_approver_indices([2, 3])
	var acting_player_index := game.current_round.current_player_index
	var bid_command := MatchCommand.new(
		MatchCommand.Type.BID,
		acting_player_index,
		game.round_number,
		match_host.revision,
		{"bid": 0}
	)
	assert(bool(match_host.apply_command(bid_command).get("accepted", false)), "Проверка возврата: хост не принял исходный заказ.")
	assert(match_host.can_player_request_undo(acting_player_index), "Проверка возврата: автор своего заказа должен иметь право запросить откат.")
	var request_command := MatchCommand.new(
		MatchCommand.Type.UNDO_REQUEST,
		acting_player_index,
		game.round_number,
		match_host.revision
	)
	assert(bool(match_host.apply_command(request_command).get("accepted", false)), "Проверка возврата: запрос не принят хостом.")
	var requester_snapshot := match_host.create_player_snapshot(acting_player_index)
	assert(bool(requester_snapshot.get("undo_state", {}).get("pending", false)), "Проверка возврата: голосование должно быть открыто до голоса хоста.")
	var host_vote_command := MatchCommand.new(
		MatchCommand.Type.UNDO_VOTE,
		0,
		game.round_number,
		match_host.revision,
		{"approved": true}
	)
	assert(bool(match_host.apply_command(host_vote_command).get("accepted", false)), "Проверка возврата: голос хоста не принят.")
	assert(game.players[acting_player_index].bid == -1, "Проверка возврата: исходный заказ должен быть отменён после единогласного голоса.")
	assert(int(match_host.create_player_snapshot(acting_player_index).get("table_state_reset_id", 0)) == 1, "Проверка возврата: клиент должен получить новый идентификатор состояния стола.")


func _process(delta: float) -> bool:
	elapsed_seconds += delta
	if host.is_lobby_full() and not round_started:
		assert(host.start_test_round(), "Проверка ENet-лобби: хост не смог начать раздачу после подключения всех мест.")
		round_started = true

	if round_started:
		var all_clients_ready := true
		for client_index in clients.size():
			var client = clients[client_index]
			if not client.client_seat_confirmed or not client.client_snapshot_is_safe:
				all_clients_ready = false
				break
			assert(client.client_player_index == client_index + 1, "Проверка ENet-лобби: клиент получил неверное место.")
			assert(client.client_snapshot.get("players", []).size() == 4, "Проверка ENet-лобби: клиент должен видеть четыре публичных места.")
			if host.match_host.revision == 0:
				assert(client.client_private_hand_size == 2, "Проверка ENet-лобби: до первого действия клиент должен получить две карты.")

		if all_clients_ready:
			for client in clients:
				if client.can_submit_test_bid():
					var available_bids: Array[int] = client.get_available_test_bids()
					assert(not available_bids.is_empty(), "Проверка ENet-лобби: у активного клиента должен быть допустимый заказ.")
					assert(client.submit_test_bid(available_bids[0]), "Проверка ENet-лобби: клиент не смог отправить заказ хосту.")

			if host.can_submit_host_test_bid():
				var host_available_bids: Array[int] = host.get_available_host_test_bids()
				assert(not host_available_bids.is_empty(), "Проверка ENet-лобби: у хоста должен быть допустимый финальный заказ.")
				assert(host.submit_host_test_bid(host_available_bids[0]), "Проверка ENet-лобби: хост не смог подтвердить свой заказ.")

			if host.match_host.revision < 8:
				if host.can_submit_host_test_card():
					var host_available_cards: Array[Dictionary] = host.get_available_host_test_cards()
					assert(not host_available_cards.is_empty(), "Проверка ENet-лобби: у хоста должна быть допустимая обычная карта.")
					assert(host.submit_host_test_card(str(host_available_cards[0].get("card_key", ""))), "Проверка ENet-лобби: хост не смог отправить обычный ход.")

				for client in clients:
					if client.can_submit_test_card():
						var available_cards: Array[Dictionary] = client.get_available_test_cards()
						assert(not available_cards.is_empty(), "Проверка ENet-лобби: у активного клиента должна быть допустимая обычная карта.")
						assert(client.submit_test_card(str(available_cards[0].get("card_key", ""))), "Проверка ENet-лобби: клиент не смог отправить обычный ход хосту.")

			if host.match_host.revision == 8 and host.match_host.game.current_round.state == Round.State.PLAYING and host.match_host.game.current_round.tricks_played == 1 and not social_actions_checked:
				for _action_index in 3:
					assert(host.submit_social_action({"kind": "reaction", "reaction": "👏"}), "Проверка ENet-лобби: хост должен отправить три разрешённые эмоции.")
				assert(not host.submit_social_action({"kind": "reaction", "reaction": "👏"}), "Проверка ENet-лобби: четвёртая эмоция должна ждать перезарядки.")
				social_actions_checked = true

			if host.match_host.revision == 8 and host.match_host.game.current_round.state == Round.State.PLAYING and host.match_host.game.current_round.tricks_played == 1 and host._snapshot_acknowledged_by_player.size() == 3 and social_actions_checked:
				assert(host.match_host.public_table_events.size() == 7, "Проверка ENet-лобби: хост должен сохранить четыре сыгранные карты и три публичные эмоции.")
				for client in clients:
					assert(int(client.client_snapshot.get("revision", -1)) == 8, "Проверка ENet-лобби: клиент должен получить обновление после завершённой взятки.")
					assert(int(client.client_snapshot.get("round", {}).get("state", -1)) == Round.State.PLAYING, "Проверка ENet-лобби: после четырёх заказов должен начаться розыгрыш.")
					assert(client.client_snapshot.get("last_completed_trick", {}).get("cards", []).size() == 4, "Проверка ENet-лобби: клиент должен увидеть четыре публичные карты завершённой взятки.")
					assert(client.client_snapshot.get("public_table_events", []).size() == 7, "Проверка ENet-лобби: клиент должен получить публичные события карт и эмоций.")
				print("Four-seat loopback ENet lobby bid and play test passed.")
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
		push_error("Проверка ENet-лобби не завершилась. Хост: %s. Клиенты: %s" % [host.status_text.replace("\n", " | "), " || ".join(client_diagnostics)])
		quit(1)
		return true

	return false
