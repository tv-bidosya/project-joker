class_name SteamP2PMatch

extends LoopbackNetworkTest


# Транспорт той же тестовой раздачи, что проверена через локальный ENet,
# но поверх SteamMultiplayerPeer. Игровые правила, снимки и проверка команд
# остаются в LoopbackNetworkTest / LocalMatchHost: здесь меняется только доставка.
const MatchHost = preload("res://Scripts/core/LocalMatchHost.gd")
const MatchCommand = preload("res://Scripts/core/MatchCommand.gd")


const BOT_ACTION_DELAY_SECONDS := 0.65


var steam_bridge: RefCounted
var host_steam_id := 0
var local_steam_id := 0
var lobby_id := 0
var steam_multiplayer_peer: Object
var _transport_active := false
var _fill_empty_seats_with_bots := false
var _local_bot_player_indices: Array[int] = []
var _expected_remote_player_count := 0
var _bot_action_delay_seconds := 0.0
var _join_request_attempt_count := 0
var _steam_peer_connection_reported := false
var _connected_remote_peer_ids: Dictionary = {}
var _steam_peer_wait_seconds := 0.0
var _outbound_flush_pending := false
var _steam_id_by_peer_id: Dictionary = {}
var _player_index_by_steam_id: Dictionary = {}
var _reconnecting_player_indices: Dictionary = {}


func start_first_real_round() -> bool:
	if not super.start_first_real_round():
		return false
	_set_status("Steam P2P: начата первая обычная раздача. Хост раздал по одной карте и ждёт подтверждение личных рук.")
	return true


func start_next_scheduled_round() -> bool:
	if not super.start_next_scheduled_round():
		return false
	_set_status("Steam P2P: хост начал следующую раздачу и отправляет каждому только его закрытую руку.")
	return true


func start_from_current_lobby(bridge: RefCounted, fill_empty_seats_with_bots: bool = false) -> bool:
	stop()
	steam_bridge = bridge
	if steam_bridge == null:
		_set_status("Steam P2P недоступен: мост Steam не создан.")
		return false
	if not steam_bridge.is_multiplayer_peer_transport_available():
		_set_status("Steam P2P недоступен: в установленном GodotSteam нет SteamMultiplayerPeer.")
		return false
	if not steam_bridge.prepare_multiplayer_peer_transport():
		_set_status("Steam P2P не удалось подготовить для этой Steam-комнаты.")
		return false

	var lobby_state: Dictionary = steam_bridge.get_lobby_state()
	lobby_id = int(lobby_state.get("lobby_id", 0))
	var members: Array = lobby_state.get("members", [])
	host_steam_id = int(lobby_state.get("lobby_owner", 0))
	local_steam_id = steam_bridge.get_local_steam_id()
	if lobby_id <= 0 or host_steam_id <= 0 or local_steam_id <= 0:
		_set_status("Steam P2P можно подготовить только внутри подключённой Steam-комнаты.")
		return false
	var expected_member_count := members.size() if fill_empty_seats_with_bots else PLAYER_COUNT
	if members.size() != expected_member_count or expected_member_count < 1 or expected_member_count > PLAYER_COUNT or not _are_all_members_ready(members):
		var requirement_text := "хотя бы один участник и боты на свободных местах" if fill_empty_seats_with_bots else "четыре участника комнаты"
		_set_status("Для Steam P2P нужны %s с отметкой «готов»." % requirement_text)
		return false

	_fill_empty_seats_with_bots = fill_empty_seats_with_bots
	_expected_remote_player_count = members.size() - 1
	_local_bot_player_indices.clear()
	if _fill_empty_seats_with_bots:
		for player_index in range(members.size(), PLAYER_COUNT):
			_local_bot_player_indices.append(player_index)
	_transport_active = true
	if local_steam_id == host_steam_id:
		_start_as_host()
	else:
		_start_as_client()
	return _transport_active


func stop() -> void:
	_detach_steam_multiplayer_peer()
	if steam_multiplayer_peer != null and steam_multiplayer_peer.has_method(&"close"):
		steam_multiplayer_peer.call(&"close")
	steam_multiplayer_peer = null
	_transport_active = false
	host_steam_id = 0
	local_steam_id = 0
	lobby_id = 0
	_fill_empty_seats_with_bots = false
	_local_bot_player_indices.clear()
	_expected_remote_player_count = 0
	_bot_action_delay_seconds = 0.0
	_join_request_attempt_count = 0
	_steam_peer_connection_reported = false
	_connected_remote_peer_ids.clear()
	_steam_id_by_peer_id.clear()
	_player_index_by_steam_id.clear()
	_reconnecting_player_indices.clear()
	_steam_peer_wait_seconds = 0.0
	_outbound_flush_pending = false
	steam_bridge = null
	super.stop()


func is_running() -> bool:
	return _transport_active and mode != Mode.NONE


func get_test_table_snapshot() -> Dictionary:
	var snapshot: Dictionary = super.get_test_table_snapshot()
	return _append_reconnect_state(snapshot)


func is_match_paused_for_reconnect() -> bool:
	if is_host():
		return not _reconnecting_player_indices.is_empty()
	if is_client():
		return not _get_snapshot_reconnecting_player_indices().is_empty()
	return false


func _process(delta: float) -> void:
	if not is_running() or steam_bridge == null or steam_multiplayer_peer == null:
		return

	# SteamMultiplayerPeer получает системные события Steam отдельно от игрового
	# цикла. Явно опрашиваем его и ждём peer_connected, а не только формального
	# CONNECTION_CONNECTED: последний появляется до завершения обмена peer ID.
	steam_multiplayer_peer.call(&"poll")
	# SteamMultiplayerPeer складывает пакеты в транспорт отдельно от обычного
	# MultiplayerAPI. Автоматический опрос SceneTree уже мог пройти раньше в
	# этом кадре, поэтому обрабатываем входящие RPC сразу после poll(). Иначе
	# публичное событие хоста могло ждать следующего исходящего пакета клиента.
	get_tree().get_multiplayer().poll()
	_steam_peer_wait_seconds += delta
	_refresh_connected_remote_peers()

	if mode == Mode.CLIENT:
		_process_client_join_request(delta)
	elif mode == Mode.HOST:
		_process_snapshot_delivery(delta)
		_process_host_undo_vote()

	if mode == Mode.HOST:
		_process_local_bots(delta)


func is_lobby_full() -> bool:
	return is_host() and _confirmed_client_peers_by_player.size() == _expected_remote_player_count


func can_start_test_round() -> bool:
	return is_lobby_full() and not lobby_round_started and match_host != null


func _send_message(message: Dictionary, target_peer_id: int) -> bool:
	if steam_multiplayer_peer == null or not is_running():
		return false

	if mode == Mode.CLIENT:
		_receive_client_message.rpc_id(1, message)
	else:
		_receive_host_message.rpc_id(target_peer_id, message)
	_schedule_outbound_transport_flush()
	return true


func _schedule_outbound_transport_flush() -> void:
	if _outbound_flush_pending:
		return
	_outbound_flush_pending = true
	call_deferred("_flush_outbound_transport")


func _flush_outbound_transport() -> void:
	_outbound_flush_pending = false
	if not is_running() or steam_multiplayer_peer == null:
		return
	# RPC ставит пакет в очередь SteamMultiplayerPeer. Явный poll в конце
	# текущего кадра выталкивает его сразу, не дожидаясь нового игрового хода.
	steam_multiplayer_peer.call(&"poll")
	get_tree().get_multiplayer().poll()


@rpc("any_peer", "reliable")
func _receive_client_message(message: Dictionary) -> void:
	if mode != Mode.HOST:
		return
	var sender_peer_id := multiplayer.get_remote_sender_id()
	if not _is_valid_sender(sender_peer_id):
		return
	_handle_message(message, sender_peer_id)


@rpc("authority", "reliable")
func _receive_host_message(message: Dictionary) -> void:
	if mode != Mode.CLIENT:
		return
	var sender_peer_id := multiplayer.get_remote_sender_id()
	if not _is_valid_sender(sender_peer_id):
		return
	_handle_message(message, sender_peer_id)


func _handle_host_join_request(message: Dictionary, sender_peer_id: int) -> void:
	if not _is_valid_sender(sender_peer_id):
		return
	_set_status("Steam P2P-хост получил запрос места через SteamMultiplayerPeer.")
	super._handle_host_join_request(message, sender_peer_id)


func _handle_host_seat_ack(message: Dictionary, sender_peer_id: int) -> void:
	super._handle_host_seat_ack(message, sender_peer_id)
	var player_index := int(_connected_player_by_peer.get(sender_peer_id, -1))
	if lobby_round_started and _confirmed_client_peers_by_player.has(player_index):
		_snapshot_acknowledged_by_player.erase(player_index)
		_send_player_snapshot(player_index)
		_set_status("Steam P2P: место %d переподключилось. Отправляю свежий личный снимок." % (player_index + 1))


func _handle_host_match_command(message: Dictionary, sender_peer_id: int) -> void:
	var command_data: Variant = message.get("command", {})
	var requested_type := int((command_data as Dictionary).get("type", NetworkCommand.Type.INVALID)) if command_data is Dictionary else NetworkCommand.Type.INVALID
	if requested_type != NetworkCommand.Type.SOCIAL_ACTION and is_match_paused_for_reconnect():
		if match_host != null:
			_send_command_result(sender_peer_id, false, "player_reconnecting", match_host.revision)
		return
	super._handle_host_match_command(message, sender_peer_id)


func _assign_client_player_index(sender_peer_id: int, requested_player_index: int) -> int:
	var sender_steam_id := _remember_steam_id_for_peer(sender_peer_id)
	if sender_steam_id <= 0:
		return -1

	if _player_index_by_steam_id.has(sender_steam_id):
		var assigned_player_index := int(_player_index_by_steam_id[sender_steam_id])
		var active_peer_id := int(_connected_client_peers_by_player.get(assigned_player_index, 0))
		if active_peer_id > 0 and active_peer_id != sender_peer_id:
			return -1
		_connected_client_peers_by_player[assigned_player_index] = sender_peer_id
		_connected_player_by_peer[sender_peer_id] = assigned_player_index
		_reconnecting_player_indices.erase(assigned_player_index)
		return assigned_player_index

	var assigned_player_index := super._assign_client_player_index(sender_peer_id, requested_player_index)
	if assigned_player_index >= FIRST_CLIENT_PLAYER_INDEX:
		_player_index_by_steam_id[sender_steam_id] = assigned_player_index
	return assigned_player_index


func _remember_steam_id_for_peer(peer_id: int) -> int:
	if _steam_id_by_peer_id.has(peer_id):
		return int(_steam_id_by_peer_id[peer_id])
	if steam_multiplayer_peer == null or not steam_multiplayer_peer.has_method(&"get_steam_id_for_peer_id"):
		return 0
	var steam_id := int(steam_multiplayer_peer.call(&"get_steam_id_for_peer_id", peer_id))
	if steam_id > 0:
		_steam_id_by_peer_id[peer_id] = steam_id
	return steam_id


func _append_reconnect_state(snapshot: Dictionary) -> Dictionary:
	if snapshot.is_empty():
		return snapshot
	snapshot["reconnecting_player_indices"] = _get_reconnecting_player_indices()
	return snapshot


func _get_reconnecting_player_indices() -> Array[int]:
	var player_indices: Array[int] = []
	for player_index_variant in _reconnecting_player_indices.keys():
		player_indices.append(int(player_index_variant))
	player_indices.sort()
	return player_indices


func _get_snapshot_reconnecting_player_indices() -> Array[int]:
	var player_indices: Array[int] = []
	if not client_snapshot_is_safe:
		return player_indices
	var reconnecting_data: Variant = client_snapshot.get("reconnecting_player_indices", [])
	if not (reconnecting_data is Array):
		return player_indices
	for player_index_variant in reconnecting_data:
		var player_index := int(player_index_variant)
		if player_index >= FIRST_CLIENT_PLAYER_INDEX and player_index < PLAYER_COUNT:
			player_indices.append(player_index)
	return player_indices


func _send_current_player_snapshots() -> void:
	for player_index_variant in _confirmed_client_peers_by_player:
		_send_player_snapshot(int(player_index_variant))


func _send_player_snapshot(player_index: int) -> void:
	if match_host == null or not _connected_client_peers_by_player.has(player_index):
		return

	var client_peer_id := int(_connected_client_peers_by_player[player_index])
	var snapshot := _append_reconnect_state(match_host.create_player_snapshot(player_index))
	var was_sent := _send_message({
		"type": "player_snapshot",
		"snapshot": snapshot
	}, client_peer_id)
	if not was_sent and not _snapshot_delivery_queue.has(player_index):
		_snapshot_delivery_queue.append(player_index)


func can_submit_test_bid() -> bool:
	return not is_match_paused_for_reconnect() and super.can_submit_test_bid()


func can_submit_test_card() -> bool:
	return not is_match_paused_for_reconnect() and super.can_submit_test_card()


func can_submit_test_joker() -> bool:
	return not is_match_paused_for_reconnect() and super.can_submit_test_joker()


func can_submit_host_test_bid() -> bool:
	return not is_match_paused_for_reconnect() and super.can_submit_host_test_bid()


func can_submit_host_test_card() -> bool:
	return not is_match_paused_for_reconnect() and super.can_submit_host_test_card()


func can_submit_host_test_joker() -> bool:
	return not is_match_paused_for_reconnect() and super.can_submit_host_test_joker()


func _start_as_host() -> void:
	if not _configure_multiplayer_peer_as_host():
		_transport_active = false
		return

	var player_names := ["Хост", "Игрок 2", "Игрок 3", "Игрок 4"]
	for bot_offset in _local_bot_player_indices.size():
		var player_index := _local_bot_player_indices[bot_offset]
		player_names[player_index] = "Бот %d" % (bot_offset + 1)
	var test_game := Game.new(player_names)
	test_game.dealer_index = HOST_PLAYER_INDEX
	match_host = MatchHost.new(test_game)
	match_host.set_automatic_undo_approver_indices(_local_bot_player_indices)
	mode = Mode.HOST
	_rebuild_host_lobby_seats()
	var status_tail := "и %d локальных ботов" % _local_bot_player_indices.size() if _fill_empty_seats_with_bots else "из комнаты"
	_set_status("Steam P2P-хост подготовлен через SteamMultiplayerPeer. Ждём подключения %d игроков %s." % [_expected_remote_player_count, status_tail])


func _start_as_client() -> void:
	if not _configure_multiplayer_peer_as_client():
		_transport_active = false
		return

	mode = Mode.CLIENT
	client_requested_player_index = FIRST_CLIENT_PLAYER_INDEX
	_join_request_sent = false
	_join_request_retry_seconds = 1.0
	_set_status("Подключаемся к Steam P2P-хосту комнаты через SteamMultiplayerPeer…")


func _process_client_join_request(delta: float) -> void:
	if client_player_index >= FIRST_CLIENT_PLAYER_INDEX:
		return
	if not _is_steam_host_ready():
		_set_status(_get_waiting_for_host_status())
		return
	if not _steam_peer_connection_reported:
		_steam_peer_connection_reported = true
		_set_status("Steam P2P: соединение с хостом установлено. Запрашиваем место за столом…")
	_join_request_retry_seconds += delta
	if _join_request_sent and _join_request_retry_seconds < 1.0:
		return

	var join_request_was_sent := _send_message({
		"type": "join_request",
		"protocol_version": PROTOCOL_VERSION,
		"requested_player_index": client_requested_player_index
	}, 1)
	_join_request_attempt_count += 1
	if join_request_was_sent:
		_join_request_sent = true
		_join_request_retry_seconds = 0.0
		_set_status("Steam P2P: запрос места отправлен хосту (попытка %d)." % _join_request_attempt_count)
	else:
		_set_status("Steam P2P: Steam не принял запрос места (попытка %d)." % _join_request_attempt_count)


func _is_valid_sender(sender_peer_id: int) -> bool:
	if sender_peer_id <= 0 or steam_bridge == null or steam_multiplayer_peer == null:
		return false
	if steam_multiplayer_peer.has_method(&"get_steam_id_for_peer_id"):
		var sender_steam_id := int(steam_multiplayer_peer.call(&"get_steam_id_for_peer_id", sender_peer_id))
		if sender_steam_id <= 0 or not steam_bridge.is_current_lobby_member(sender_steam_id):
			return false
	if mode == Mode.CLIENT:
		return sender_peer_id == 1
	return sender_peer_id != 1


func _is_steam_host_ready() -> bool:
	if not _is_steam_peer_connected():
		return false
	if _connected_remote_peer_ids.has(1):
		return true
	if steam_multiplayer_peer != null and steam_multiplayer_peer.has_method(&"get_peer_id_for_steam_id"):
		return int(steam_multiplayer_peer.call(&"get_peer_id_for_steam_id", host_steam_id)) == 1
	return false


func _refresh_connected_remote_peers() -> void:
	if steam_multiplayer_peer == null:
		return
	var multiplayer_api := get_tree().get_multiplayer()
	for peer_id in multiplayer_api.get_peers():
		_connected_remote_peer_ids[int(peer_id)] = true


func _get_waiting_for_host_status() -> String:
	if not _is_steam_peer_connected():
		return "Steam P2P: создаём защищённое соединение с хостом через Steam…"

	var known_peer_ids: Array[String] = []
	for peer_id in _connected_remote_peer_ids.keys():
		known_peer_ids.append(str(peer_id))
	var peer_list := ", ".join(known_peer_ids) if not known_peer_ids.is_empty() else "пока нет"
	return "Steam P2P: транспорт готов, ждём подтверждение хоста (peer_connected: %s)." % peer_list


func _configure_multiplayer_peer_as_host() -> bool:
	if not _create_steam_multiplayer_peer():
		_set_status("Steam P2P: не удалось создать SteamMultiplayerPeer.")
		return false

	var result := int(steam_multiplayer_peer.call(&"host_with_lobby", lobby_id))
	if result != OK:
		_set_status("Steam P2P: не удалось открыть хост через Steam-комнату (ошибка %d)." % result)
		steam_multiplayer_peer = null
		return false
	_attach_steam_multiplayer_peer()
	return true


func _configure_multiplayer_peer_as_client() -> bool:
	if not _create_steam_multiplayer_peer():
		_set_status("Steam P2P: не удалось создать SteamMultiplayerPeer.")
		return false

	var result := int(steam_multiplayer_peer.call(&"connect_to_lobby", lobby_id))
	if result != OK:
		_set_status("Steam P2P: не удалось подключиться к Steam-комнате (ошибка %d)." % result)
		steam_multiplayer_peer = null
		return false
	_attach_steam_multiplayer_peer()
	return true


func _create_steam_multiplayer_peer() -> bool:
	var peer_variant: Variant = steam_bridge.create_multiplayer_peer()
	if not (peer_variant is MultiplayerPeer):
		steam_multiplayer_peer = null
		return false
	steam_multiplayer_peer = peer_variant
	return true


func _attach_steam_multiplayer_peer() -> void:
	if steam_multiplayer_peer is MultiplayerPeer:
		var multiplayer_api := get_tree().get_multiplayer()
		if not multiplayer_api.peer_connected.is_connected(_on_steam_peer_connected):
			multiplayer_api.peer_connected.connect(_on_steam_peer_connected)
		if not multiplayer_api.peer_disconnected.is_connected(_on_steam_peer_disconnected):
			multiplayer_api.peer_disconnected.connect(_on_steam_peer_disconnected)
		multiplayer_api.multiplayer_peer = steam_multiplayer_peer


func _detach_steam_multiplayer_peer() -> void:
	var multiplayer_api := get_tree().get_multiplayer()
	if multiplayer_api.peer_connected.is_connected(_on_steam_peer_connected):
		multiplayer_api.peer_connected.disconnect(_on_steam_peer_connected)
	if multiplayer_api.peer_disconnected.is_connected(_on_steam_peer_disconnected):
		multiplayer_api.peer_disconnected.disconnect(_on_steam_peer_disconnected)
	if steam_multiplayer_peer is MultiplayerPeer and multiplayer_api.multiplayer_peer == steam_multiplayer_peer:
		multiplayer_api.multiplayer_peer = OfflineMultiplayerPeer.new()


func _on_steam_peer_connected(peer_id: int) -> void:
	_connected_remote_peer_ids[peer_id] = true
	_remember_steam_id_for_peer(peer_id)
	if mode == Mode.CLIENT and peer_id == 1:
		_set_status("Steam P2P: хост подтвердил соединение. Запрашиваем место за столом…")


func _on_steam_peer_disconnected(peer_id: int) -> void:
	_connected_remote_peer_ids.erase(peer_id)
	var disconnected_player_index := int(_connected_player_by_peer.get(peer_id, -1))
	_steam_id_by_peer_id.erase(peer_id)
	if mode == Mode.HOST and disconnected_player_index >= FIRST_CLIENT_PLAYER_INDEX:
		_connected_player_by_peer.erase(peer_id)
		_connected_client_peers_by_player.erase(disconnected_player_index)
		_confirmed_client_peers_by_player.erase(disconnected_player_index)
		_snapshot_acknowledged_by_player.erase(disconnected_player_index)
		_snapshot_delivery_queue.erase(disconnected_player_index)
		_reconnecting_player_indices[disconnected_player_index] = true
		_rebuild_host_lobby_seats()
		_broadcast_lobby_state()
		_send_current_player_snapshots()
		_set_status("Steam P2P: место %d переподключается. Игра приостановлена." % (disconnected_player_index + 1))
		return
	if mode == Mode.CLIENT and peer_id == 1:
		if client_player_index >= FIRST_CLIENT_PLAYER_INDEX:
			client_requested_player_index = client_player_index
		client_player_index = -1
		client_seat_confirmed = false
		client_snapshot.clear()
		client_snapshot_is_safe = false
		client_private_hand_size = 0
		_join_request_sent = false
		_join_request_retry_seconds = 1.0
		_set_status("Steam P2P: связь с хостом потеряна. Ожидаем повторного подключения…")


func _is_steam_peer_connected() -> bool:
	if steam_multiplayer_peer == null or not steam_multiplayer_peer.has_method(&"get_connection_status"):
		return false
	return int(steam_multiplayer_peer.call(&"get_connection_status")) == MultiplayerPeer.CONNECTION_CONNECTED


func _are_all_members_ready(members: Array) -> bool:
	for member_variant in members:
		if not (member_variant is Dictionary) or not bool(member_variant.get("ready", false)):
			return false
	return true


func _rebuild_host_lobby_seats() -> void:
	lobby_seats.clear()
	for player_index in PLAYER_COUNT:
		var is_host_player := player_index == HOST_PLAYER_INDEX
		var is_local_bot := _local_bot_player_indices.has(player_index)
		var seat_reserved_for_reconnect := _player_index_by_steam_id.values().has(player_index)
		var is_reconnecting := _reconnecting_player_indices.has(player_index)
		var is_assigned := is_host_player or is_local_bot or _connected_client_peers_by_player.has(player_index) or seat_reserved_for_reconnect
		var is_confirmed := is_host_player or is_local_bot or _confirmed_client_peers_by_player.has(player_index)
		var bot_number := _local_bot_player_indices.find(player_index) + 1
		var display_name := "Хост" if is_host_player else ("Бот %d" % bot_number if is_local_bot else "Игрок %d" % (player_index + 1))
		lobby_seats.append({
			"player_index": player_index,
			"display_name": display_name,
			"is_host": is_host_player,
			"is_bot": is_local_bot,
			"assigned": is_assigned,
			"confirmed": is_confirmed,
			"reconnecting": is_reconnecting
		})


func _process_local_bots(delta: float) -> void:
	if not _fill_empty_seats_with_bots or not lobby_round_started or match_host == null or is_match_paused_for_reconnect() or match_host.is_undo_vote_pending():
		return

	_bot_action_delay_seconds = maxf(0.0, _bot_action_delay_seconds - delta)
	if _bot_action_delay_seconds > 0.0:
		return

	var bot_player_index := _get_active_local_bot_player_index()
	if bot_player_index < 0:
		return

	if _submit_local_bot_action(bot_player_index):
		_bot_action_delay_seconds = BOT_ACTION_DELAY_SECONDS


func _get_active_local_bot_player_index() -> int:
	if match_host == null or match_host.game.current_round == null:
		return -1

	var round: Round = match_host.game.current_round
	if round.state == Round.State.BIDDING and _local_bot_player_indices.has(round.current_player_index):
		return round.current_player_index
	if round.state == Round.State.PLAYING:
		var active_player_index := _get_host_current_playing_player_index()
		if _local_bot_player_indices.has(active_player_index):
			return active_player_index
	return -1


func _submit_local_bot_action(player_index: int) -> bool:
	if match_host == null or match_host.game.current_round == null:
		return false

	var round: Round = match_host.game.current_round
	var command: MatchCommand
	if round.state == Round.State.BIDDING:
		var bot_bid := _get_local_bot_bid(player_index, round)
		if bot_bid < 0:
			return false
		command = MatchCommand.new(
			MatchCommand.Type.BID,
			player_index,
			match_host.game.round_number,
			match_host.revision,
			{"bid": bot_bid}
		)
	else:
		var bot_payload := _get_local_bot_card_payload(player_index)
		if bot_payload.is_empty():
			return false
		command = MatchCommand.new(
			MatchCommand.Type.PLAY_CARD,
			player_index,
			match_host.game.round_number,
			match_host.revision,
			bot_payload
		)

	var result: Dictionary = match_host.apply_command(command)
	if not bool(result.get("accepted", false)):
		_set_status("Локальный бот не смог сделать действие: %s." % str(result.get("reason", "unknown")))
		return false

	_queue_player_snapshots_for_delivery()
	var action_text := "заказал %d" % int(command.payload.get("bid", 0)) if command.type == MatchCommand.Type.BID else "сыграл карту"
	_set_status("Бот %d %s. Ревизия %d отправляется подключённому игроку." % [player_index - 1, action_text, match_host.revision])
	return true


func _get_local_bot_bid(player_index: int, round: Round) -> int:
	for bid in range(round.cards_per_player + 1):
		if round.can_place_bid(player_index, bid):
			return bid
	return -1


func _get_local_bot_card_payload(player_index: int) -> Dictionary:
	if match_host == null or player_index < 0 or player_index >= match_host.game.players.size():
		return {}

	var player: Player = match_host.game.players[player_index]
	for card in player.hand:
		if card.is_joker:
			continue
		if match_host.game.active_trick != null and not match_host.game.active_trick.can_play_card(player, card):
			continue
		return {"card_key": _get_card_key(card)}

	for card in player.hand:
		if not card.is_joker:
			continue
		if match_host.game.active_trick != null and not match_host.game.active_trick.can_play_card(player, card):
			continue
		var is_leading := match_host.game.active_trick == null
		return {
			"card_key": "joker",
			"joker_mode": Trick.JokerMode.JOKER_WINS,
			"declared_suit": Card.Suit.CLUBS if is_leading else -1,
			"forced_card_rank": Trick.ForcedCardRank.NONE
		}
	return {}
