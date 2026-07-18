class_name LoopbackNetworkTest

extends Node


# Временный ENet-полигон для двух окон на одном компьютере. Он не является
# частью обычной партии и не использует Steam.
const HOST_ADDRESS := "127.0.0.1"
const HOST_PORT := 24567
const CLIENT_PLAYER_INDEX := 1
const NetworkHost = preload("res://Scripts/core/LocalMatchHost.gd")
const NetworkCommand = preload("res://Scripts/core/MatchCommand.gd")
const NetworkSnapshot = preload("res://Scripts/core/MatchStateSnapshot.gd")


enum Mode {
	NONE,
	HOST,
	CLIENT
}


signal status_changed


var mode: Mode = Mode.NONE
var peer: ENetMultiplayerPeer
var match_host
var status_text := "Сеть не запущена."
var client_snapshot: Dictionary = {}
var client_snapshot_is_safe := false
var client_private_hand_size := 0
var client_test_bid_sent := false
var client_test_bid_accepted := false
var client_test_card_sent := false
var client_test_card_accepted := false
var client_last_command_reason := ""
var _hello_sent := false
var _connected_client_peer_id := 0


func start_host() -> bool:
	stop()
	peer = ENetMultiplayerPeer.new()
	var result := peer.create_server(HOST_PORT, 1)
	if result != OK:
		peer = null
		_set_status("Не удалось открыть локальный порт %d (ошибка %d)." % [HOST_PORT, result])
		return false

	var test_game := Game.new(["Хост", "Клиент", "Бот 1", "Бот 2"])
	# В тестовой раздаче сдаёт хост, поэтому клиент с индексом 1 всегда
	# делает первый заказ. Это позволяет проверить реальную команду без ботов.
	test_game.dealer_index = 0
	if not test_game.start_round(2, Round.RoundType.NORMAL, Round.TrumpSuit.CLUBS):
		peer.close()
		peer = null
		_set_status("Не удалось создать тестовую раздачу.")
		return false

	match_host = NetworkHost.new(test_game)
	mode = Mode.HOST
	_set_status("Хост запущен: 127.0.0.1:%d. Ожидание второго окна." % HOST_PORT)
	return true


func start_client() -> bool:
	stop()
	peer = ENetMultiplayerPeer.new()
	var result := peer.create_client(HOST_ADDRESS, HOST_PORT)
	if result != OK:
		peer = null
		_set_status("Не удалось начать подключение к хосту (ошибка %d)." % result)
		return false

	mode = Mode.CLIENT
	_set_status("Клиент подключается к 127.0.0.1:%d…" % HOST_PORT)
	return true


func stop() -> void:
	if peer != null:
		peer.close()
	peer = null
	match_host = null
	mode = Mode.NONE
	client_snapshot.clear()
	client_snapshot_is_safe = false
	client_private_hand_size = 0
	client_test_bid_sent = false
	client_test_bid_accepted = false
	client_test_card_sent = false
	client_test_card_accepted = false
	client_last_command_reason = ""
	_hello_sent = false
	_connected_client_peer_id = 0
	_set_status("Сеть остановлена.")


func is_running() -> bool:
	return mode != Mode.NONE and peer != null


func is_host() -> bool:
	return mode == Mode.HOST


func is_client() -> bool:
	return mode == Mode.CLIENT


func can_submit_test_bid() -> bool:
	if not is_client() or not client_snapshot_is_safe or client_test_bid_sent:
		return false

	var round_data: Dictionary = client_snapshot.get("round", {})
	return (
		int(round_data.get("state", -1)) == Round.State.BIDDING
		and int(round_data.get("current_player_index", -1)) == CLIENT_PLAYER_INDEX
	)


func submit_test_bid() -> bool:
	if not can_submit_test_bid():
		_set_status("Тестовый заказ сейчас недоступен: дождись безопасного снимка и своей очереди.")
		return false

	var command := NetworkCommand.new(
		NetworkCommand.Type.BID,
		CLIENT_PLAYER_INDEX,
		int(client_snapshot.get("round_number", 0)),
		int(client_snapshot.get("revision", 0)),
		{"bid": 1}
	)
	if not _send_message({
		"type": "match_command",
		"command": command.to_dictionary()
	}, 1):
		_set_status("Не удалось отправить тестовый заказ хосту.")
		return false

	client_test_bid_sent = true
	_set_status("Тестовый заказ 1 отправлен хосту. Жду проверки…")
	return true


func can_submit_test_card() -> bool:
	if not is_client() or not client_snapshot_is_safe or client_test_card_sent:
		return false

	var round_data: Dictionary = client_snapshot.get("round", {})
	return (
		int(round_data.get("state", -1)) == Round.State.PLAYING
		and int(round_data.get("current_player_index", -1)) == CLIENT_PLAYER_INDEX
		and not get_test_playable_cards().is_empty()
	)


func get_test_playable_cards() -> Array[Dictionary]:
	var playable_cards: Array[Dictionary] = []
	for card_data_variant in client_snapshot.get("private_hand", []):
		if not (card_data_variant is Dictionary):
			continue
		var card_data: Dictionary = card_data_variant
		# Условие Джокера — отдельный будущий этап. Здесь выбираем обычную
		# карту, чтобы проверить именно сетевой путь стандартного хода.
		if not bool(card_data.get("is_joker", false)):
			playable_cards.append(card_data.duplicate(true))
	return playable_cards


func submit_test_card(card_key: String) -> bool:
	if not can_submit_test_card():
		_set_status("Тестовый ход сейчас недоступен: дождись своей очереди после заказов.")
		return false

	var card_is_available := false
	for card_data in get_test_playable_cards():
		if str(card_data.get("card_key", "")) == card_key:
			card_is_available = true
			break
	if not card_is_available:
		_set_status("Этой карты нет среди допустимых тестовых ходов.")
		return false

	var command := NetworkCommand.new(
		NetworkCommand.Type.PLAY_CARD,
		CLIENT_PLAYER_INDEX,
		int(client_snapshot.get("round_number", 0)),
		int(client_snapshot.get("revision", 0)),
		{"card_key": card_key}
	)
	if not _send_message({
		"type": "match_command",
		"command": command.to_dictionary()
	}, 1):
		_set_status("Не удалось отправить тестовый ход хосту.")
		return false

	client_test_card_sent = true
	_set_status("Тестовый ход отправлен хосту. Жду проверки…")
	return true


func _process(_delta: float) -> void:
	if peer == null:
		return

	# Этот peer используется напрямую, без MultiplayerAPI сцены. Поэтому
	# соединение и входящие пакеты нужно обновлять вручную каждый кадр.
	peer.poll()

	if mode == Mode.CLIENT:
		_process_client_connection()

	while peer != null and peer.get_available_packet_count() > 0:
		var sender_peer_id := peer.get_packet_peer()
		var packet_text := peer.get_packet().get_string_from_utf8()
		var packet_data: Variant = JSON.parse_string(packet_text)
		if not (packet_data is Dictionary):
			continue
		_handle_message(packet_data, sender_peer_id)


func _process_client_connection() -> void:
	var connection_status := peer.get_connection_status()
	if connection_status == MultiplayerPeer.CONNECTION_DISCONNECTED:
		_set_status("Клиент не подключился: хост не найден или уже закрыт.")
		return
	if connection_status != MultiplayerPeer.CONNECTION_CONNECTED or _hello_sent:
		return

	_hello_sent = _send_message({
		"type": "hello",
		"requested_player_index": CLIENT_PLAYER_INDEX
	}, 1)
	if _hello_sent:
		_set_status("Клиент подключён. Запрашиваю персональный снимок…")


func _handle_message(message: Dictionary, sender_peer_id: int) -> void:
	var message_type := str(message.get("type", ""))
	if mode == Mode.HOST and message_type == "hello":
		_handle_host_hello(sender_peer_id)
		return
	if mode == Mode.HOST and message_type == "match_command":
		_handle_host_command(message, sender_peer_id)
		return
	if mode == Mode.CLIENT and message_type == "player_snapshot":
		_handle_client_snapshot(message)
		return
	if mode == Mode.CLIENT and message_type == "command_result":
		_handle_client_command_result(message)


func _handle_host_hello(sender_peer_id: int) -> void:
	if match_host == null:
		return

	_connected_client_peer_id = sender_peer_id
	var snapshot: Dictionary = match_host.create_player_snapshot(CLIENT_PLAYER_INDEX)
	if _send_message({
		"type": "player_snapshot",
		"player_index": CLIENT_PLAYER_INDEX,
		"snapshot": snapshot
	}, sender_peer_id):
		_set_status("Клиент подключён. Отправлен его безопасный снимок ревизии %d." % match_host.revision)


func _handle_host_command(message: Dictionary, sender_peer_id: int) -> void:
	if match_host == null:
		return

	var result: Dictionary
	var command_data: Variant = message.get("command", {})
	if sender_peer_id != _connected_client_peer_id or not (command_data is Dictionary):
		result = {
			"accepted": false,
			"reason": "invalid_network_command",
			"revision": match_host.revision
		}
	else:
		var command = NetworkCommand.from_dictionary(command_data)
		if command.player_index != CLIENT_PLAYER_INDEX:
			result = {
				"accepted": false,
				"reason": "wrong_client_player",
				"revision": match_host.revision
			}
		else:
			result = match_host.apply_command(command)
			if bool(result.get("accepted", false)) and command.type == NetworkCommand.Type.BID:
				_complete_test_bot_bids()

	_send_message({
		"type": "command_result",
		"command_type": int(command_data.get("type", NetworkCommand.Type.INVALID)),
		"accepted": bool(result.get("accepted", false)),
		"reason": str(result.get("reason", "unknown")),
		"revision": int(result.get("revision", match_host.revision)),
		"snapshot": match_host.create_player_snapshot(CLIENT_PLAYER_INDEX)
	}, sender_peer_id)

	if bool(result.get("accepted", false)):
		if int(command_data.get("type", NetworkCommand.Type.INVALID)) == NetworkCommand.Type.BID:
			_set_status("Хост принял тестовый заказ клиента: 1. Временные боты завершили заказы. Ревизия %d." % match_host.revision)
		else:
			_set_status("Хост принял тестовый ход клиента. Ревизия %d." % match_host.revision)
	else:
		_set_status("Хост отклонил тестовую команду: %s." % str(result.get("reason", "unknown")))


func _complete_test_bot_bids() -> void:
	if match_host == null:
		return

	while match_host.game.current_round.state == Round.State.BIDDING:
		var bot_player_index: int = match_host.game.current_round.current_player_index
		var bot_command := NetworkCommand.new(
			NetworkCommand.Type.BID,
			bot_player_index,
			match_host.game.round_number,
			match_host.revision,
			{"bid": 0}
		)
		var bot_result: Dictionary = match_host.apply_command(bot_command)
		if not bool(bot_result.get("accepted", false)):
			break


func _handle_client_snapshot(message: Dictionary) -> void:
	var snapshot_data: Variant = message.get("snapshot", {})
	if not _store_client_snapshot(snapshot_data):
		_set_status("Клиент получил повреждённый снимок.")
		return
	if client_snapshot_is_safe:
		_set_status("Клиент получил безопасный снимок: своя рука — %d карт, ревизия %d." % [
			client_private_hand_size,
			int(client_snapshot.get("revision", -1))
		])
	else:
		_set_status("Ошибка: клиент получил небезопасный снимок.")


func _handle_client_command_result(message: Dictionary) -> void:
	client_last_command_reason = str(message.get("reason", "unknown"))
	var snapshot_data: Variant = message.get("snapshot", {})
	if not _store_client_snapshot(snapshot_data):
		_set_status("Клиент получил ответ хоста без корректного снимка.")
		return

	var accepted := bool(message.get("accepted", false)) and client_snapshot_is_safe
	var command_type := int(message.get("command_type", NetworkCommand.Type.INVALID))
	if command_type == NetworkCommand.Type.BID:
		client_test_bid_accepted = accepted
	elif command_type == NetworkCommand.Type.PLAY_CARD:
		client_test_card_accepted = accepted

	if accepted and command_type == NetworkCommand.Type.BID:
		_set_status("Хост принял заказ 1. Боты завершили заказы; выбери карту. Безопасный снимок ревизии %d." % int(client_snapshot.get("revision", -1)))
	elif accepted and command_type == NetworkCommand.Type.PLAY_CARD:
		_set_status("Хост принял выбранную карту. Получен безопасный снимок ревизии %d." % int(client_snapshot.get("revision", -1)))
	else:
		_set_status("Хост отклонил заказ: %s." % client_last_command_reason)


func _store_client_snapshot(snapshot_data: Variant) -> bool:
	if not (snapshot_data is Dictionary):
		return false

	client_snapshot = snapshot_data.duplicate(true)
	client_snapshot_is_safe = NetworkSnapshot.is_player_snapshot_safe(client_snapshot, CLIENT_PLAYER_INDEX)
	var private_hand: Array = client_snapshot.get("private_hand", [])
	client_private_hand_size = private_hand.size()
	return true


func _send_message(message: Dictionary, target_peer_id: int) -> bool:
	if peer == null:
		return false

	peer.set_target_peer(target_peer_id)
	var result := peer.put_packet(JSON.stringify(message).to_utf8_buffer())
	peer.set_target_peer(0)
	return result == OK


func _set_status(new_status: String) -> void:
	if status_text == new_status:
		return
	status_text = new_status
	status_changed.emit()
