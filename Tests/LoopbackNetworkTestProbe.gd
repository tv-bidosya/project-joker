extends SceneTree


const LoopbackNetwork = preload("res://Scripts/core/LoopbackNetworkTest.gd")
const TEST_TIMEOUT_SECONDS := 3.0


var host
var client
var elapsed_seconds := 0.0


func _init() -> void:
	host = LoopbackNetwork.new()
	client = LoopbackNetwork.new()
	root.add_child(host)
	root.add_child(client)

	assert(host.start_host(), "Проверка ENet: хост не смог запуститься.")
	assert(client.start_client(), "Проверка ENet: клиент не смог начать подключение.")


func _process(delta: float) -> bool:
	elapsed_seconds += delta
	if client.client_snapshot_is_safe and not client.client_test_bid_sent:
		assert(client.client_private_hand_size == 2, "Проверка ENet: клиент должен получить только свою тестовую руку.")
		assert(client.client_snapshot.get("players", []).size() == 4, "Проверка ENet: клиент должен видеть публичные места всех игроков.")
		assert(client.can_submit_test_bid(), "Проверка ENet: после первого снимка клиент должен быть первым заказчиком.")
		assert(client.submit_test_bid(), "Проверка ENet: клиент должен отправить тестовый заказ.")

	if client.client_test_bid_accepted and not client.client_test_card_sent:
		assert(int(client.client_snapshot.get("revision", -1)) == 4, "Проверка ENet: заказ клиента и три заказа ботов должны увеличить ревизию до 4.")
		var public_players: Array = client.client_snapshot.get("players", [])
		assert(int(public_players[1].get("bid", -1)) == 1, "Проверка ENet: клиент должен увидеть свой подтверждённый заказ.")
		assert(client.can_submit_test_card(), "Проверка ENet: после завершения заказов клиент должен ходить первым.")
		var playable_cards: Array[Dictionary] = client.get_test_playable_cards()
		assert(client.submit_test_card(str(playable_cards[0].get("card_key", ""))), "Проверка ENet: клиент должен отправить допустимую карту.")

	if client.client_test_card_accepted:
		assert(int(client.client_snapshot.get("revision", -1)) == 5, "Проверка ENet: принятый ход картой должен увеличить ревизию до 5.")
		assert(client.client_private_hand_size == 1, "Проверка ENet: после хода у клиента должна остаться одна карта.")
		var active_trick: Dictionary = client.client_snapshot.get("active_trick", {})
		assert(active_trick.get("played_cards", []).size() == 1, "Проверка ENet: сыгранная карта должна стать видна на общем столе.")
		print("Loopback ENet bid and card test passed.")
		quit(0)
		return true

	if elapsed_seconds >= TEST_TIMEOUT_SECONDS:
		push_error("Проверка ENet: клиент не получил подтверждение тестового хода за отведённое время.")
		quit(1)
		return true

	return false
