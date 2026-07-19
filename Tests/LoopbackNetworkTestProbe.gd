extends SceneTree


const LoopbackNetwork = preload("res://Scripts/core/LoopbackNetworkTest.gd")
const TEST_TIMEOUT_SECONDS := 4.0
const TEST_PORT := 24568


var host
var clients: Array = []
var elapsed_seconds := 0.0
var round_started := false


func _init() -> void:
	host = LoopbackNetwork.new()
	root.add_child(host)
	assert(host.start_host(TEST_PORT), "Проверка ENet-лобби: хост не смог запуститься.")

	for player_index in range(1, 4):
		var client = LoopbackNetwork.new()
		clients.append(client)
		root.add_child(client)
		assert(client.start_client(player_index, TEST_PORT), "Проверка ENet-лобби: клиент %d не смог начать подключение." % (player_index + 1))


func _process(delta: float) -> bool:
	elapsed_seconds += delta
	if host.is_lobby_full() and not round_started:
		assert(host.start_test_round(), "Проверка ENet-лобби: хост не смог начать раздачу после подключения всех мест.")
		round_started = true

	if round_started:
		var all_clients_ready := true
		for client_index in clients.size():
			var client = clients[client_index]
			if not client.client_seat_confirmed or not client.client_snapshot_is_safe or client.client_private_hand_size != 2:
				all_clients_ready = false
				break
			assert(client.client_player_index == client_index + 1, "Проверка ENet-лобби: клиент получил неверное место.")
			assert(client.client_snapshot.get("players", []).size() == 4, "Проверка ENet-лобби: клиент должен видеть четыре публичных места.")

		if all_clients_ready and host._snapshot_acknowledged_by_player.size() == 3:
			print("Four-seat loopback ENet lobby test passed.")
			quit(0)
			return true

	if elapsed_seconds >= TEST_TIMEOUT_SECONDS:
		push_error("Проверка ENet-лобби: четыре места не подключились или не получили личные руки за отведённое время.")
		quit(1)
		return true

	return false
