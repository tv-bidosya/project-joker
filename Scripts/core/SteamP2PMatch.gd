class_name SteamP2PMatch

extends LoopbackNetworkTest


# Транспорт той же тестовой раздачи, что проверена через локальный ENet,
# но поверх SteamMultiplayerPeer. Игровые правила, снимки и проверка команд
# остаются в LoopbackNetworkTest / LocalMatchHost: здесь меняется только доставка.
const MatchHost = preload("res://Scripts/core/LocalMatchHost.gd")
const MatchCommand = preload("res://Scripts/core/MatchCommand.gd")


const BOT_ACTION_DELAY_SECONDS := 0.65
const HUMAN_AUTO_TURN_INACTIVITY_SECONDS := 90.0
const HUMAN_AUTO_TURN_COUNTDOWN_SECONDS := 45.0
const HUMAN_AUTO_TURN_SYNC_INTERVAL_SECONDS := 1.0
const NEXT_ROUND_AUTO_START_SECONDS := 30.0
const NEXT_ROUND_COUNTDOWN_SYNC_INTERVAL_SECONDS := 1.0
const BOT_DIFFICULTY_EASY := 0
const BOT_DIFFICULTY_NORMAL := 1
const BOT_DIFFICULTY_HARD := 2


var steam_bridge: RefCounted
var host_steam_id := 0
var local_steam_id := 0
var lobby_id := 0
var steam_multiplayer_peer: Object
var _transport_active := false
var _fill_empty_seats_with_bots := false
var _local_bot_player_indices: Array[int] = []
var _temporary_bot_player_indices: Dictionary = {}
var _bot_difficulty := BOT_DIFFICULTY_NORMAL
var _expected_remote_player_count := 0
var _bot_action_delay_seconds := 0.0
var _human_auto_turn_decision_key := ""
var _human_auto_turn_elapsed_seconds := 0.0
var _human_auto_turn_sync_elapsed_seconds := 0.0
var _human_auto_turn_enabled_by_player: Dictionary = {}
var _next_round_auto_start_elapsed_seconds := 0.0
var _next_round_countdown_sync_elapsed_seconds := 0.0
var _join_request_attempt_count := 0
var _steam_peer_connection_reported := false
var _connected_remote_peer_ids: Dictionary = {}
var _steam_peer_wait_seconds := 0.0
var _outbound_flush_pending := false
var _steam_id_by_peer_id: Dictionary = {}
var _player_index_by_steam_id: Dictionary = {}
var _reconnecting_player_indices: Dictionary = {}
var _bot_random := RandomNumberGenerator.new()
var _local_display_name := "Игрок"
var _local_auto_turn_enabled := false
var _local_avatar_index := 0
var _local_avatar_data := ""
var _history_mode := MatchHost.HistoryMode.FULL


func _init() -> void:
	_bot_random.randomize()


func start_first_real_round() -> bool:
	if not super.start_first_real_round():
		return false
	_reset_next_round_auto_start()
	_set_status("Steam P2P: начата первая обычная раздача. Хост раздал по одной карте и ждёт подтверждение личных рук.")
	return true


func start_next_scheduled_round() -> bool:
	if not super.start_next_scheduled_round():
		return false
	_reset_next_round_auto_start()
	_set_status("Steam P2P: хост начал следующую раздачу и отправляет каждому только его закрытую руку.")
	return true


func start_from_current_lobby(
	bridge: RefCounted,
	fill_empty_seats_with_bots: bool = false,
	bot_difficulty: int = BOT_DIFFICULTY_NORMAL,
	local_display_name: String = "Игрок",
	local_auto_turn_enabled: bool = false,
	local_avatar_index: int = 0,
	local_avatar_data: String = "",
	history_mode: int = MatchHost.HistoryMode.FULL
) -> bool:
	stop()
	steam_bridge = bridge
	_local_auto_turn_enabled = local_auto_turn_enabled
	_local_display_name = _sanitize_network_display_name(local_display_name)
	if _local_display_name.is_empty():
		_local_display_name = "Игрок"
	_local_avatar_index = clampi(local_avatar_index, 0, 4)
	_local_avatar_data = local_avatar_data if local_avatar_data.length() <= MAX_NETWORK_AVATAR_DATA_LENGTH else ""
	_history_mode = clampi(history_mode, MatchHost.HistoryMode.FULL, MatchHost.HistoryMode.LAST_TRICK_ONLY)
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
	_bot_difficulty = clampi(bot_difficulty, BOT_DIFFICULTY_EASY, BOT_DIFFICULTY_HARD)
	_expected_remote_player_count = members.size() - 1
	_local_bot_player_indices.clear()
	_temporary_bot_player_indices.clear()
	if _fill_empty_seats_with_bots:
		for player_index in range(members.size(), PLAYER_COUNT):
			_local_bot_player_indices.append(player_index)
	_transport_active = true
	if local_steam_id == host_steam_id:
		_start_as_host()
		_avatar_index_by_player[HOST_PLAYER_INDEX] = _local_avatar_index
		_avatar_data_by_player[HOST_PLAYER_INDEX] = _local_avatar_data
		_rebuild_host_lobby_seats()
		_set_player_auto_turn_enabled(HOST_PLAYER_INDEX, _local_auto_turn_enabled, false)
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
	_temporary_bot_player_indices.clear()
	_bot_difficulty = BOT_DIFFICULTY_NORMAL
	_expected_remote_player_count = 0
	_bot_action_delay_seconds = 0.0
	_human_auto_turn_decision_key = ""
	_human_auto_turn_elapsed_seconds = 0.0
	_human_auto_turn_sync_elapsed_seconds = 0.0
	_human_auto_turn_enabled_by_player.clear()
	_reset_next_round_auto_start()
	_join_request_attempt_count = 0
	_steam_peer_connection_reported = false
	_connected_remote_peer_ids.clear()
	_steam_id_by_peer_id.clear()
	_player_index_by_steam_id.clear()
	_reconnecting_player_indices.clear()
	_steam_peer_wait_seconds = 0.0
	_outbound_flush_pending = false
	_local_display_name = "Игрок"
	_local_auto_turn_enabled = false
	_local_avatar_index = 0
	_local_avatar_data = ""
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


func get_reconnecting_player_indices() -> Array[int]:
	return _get_reconnecting_player_indices() if is_host() else _get_snapshot_reconnecting_player_indices()


func get_temporary_bot_player_indices() -> Array[int]:
	if is_host():
		return _get_temporary_bot_player_indices()
	var player_indices: Array[int] = []
	if not client_snapshot_is_safe:
		return player_indices
	for player_index_variant in client_snapshot.get("temporary_bot_player_indices", []):
		player_indices.append(int(player_index_variant))
	return player_indices


func set_bot_difficulty(difficulty: int) -> void:
	_bot_difficulty = clampi(difficulty, BOT_DIFFICULTY_EASY, BOT_DIFFICULTY_HARD)


func _get_effective_local_bot_difficulty(player_index: int) -> int:
	# Временная замена отвечает за уже начатую партию живого игрока и всегда
	# играет максимально осмысленно, независимо от сложности обычных ботов.
	if _temporary_bot_player_indices.has(player_index):
		return BOT_DIFFICULTY_HARD
	return _bot_difficulty


func update_local_display_name(display_name: String) -> bool:
	return update_local_profile(display_name, _local_avatar_index, _local_avatar_data)


func update_local_profile(display_name: String, avatar_index: int, avatar_data: String = "") -> bool:
	var sanitized_name := _sanitize_network_display_name(display_name)
	if sanitized_name.is_empty():
		return false
	_local_display_name = sanitized_name
	_local_avatar_index = clampi(avatar_index, 0, 4)
	_local_avatar_data = avatar_data if avatar_data.length() <= MAX_NETWORK_AVATAR_DATA_LENGTH else ""
	return super.update_local_profile(sanitized_name, _local_avatar_index, _local_avatar_data)


func set_local_auto_turn_enabled(enabled: bool) -> bool:
	_local_auto_turn_enabled = enabled
	if is_host():
		_set_player_auto_turn_enabled(HOST_PLAYER_INDEX, enabled, false)
		return true
	if not is_client() or client_player_index < FIRST_CLIENT_PLAYER_INDEX:
		return false
	client_snapshot["recipient_auto_turn_enabled"] = enabled
	return _send_message({
		"type": "auto_turn_preference",
		"player_index": client_player_index,
		"enabled": enabled
	}, 1)


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
		_process_first_turn_roll(delta)
		_process_snapshot_delivery(delta)
		_process_host_undo_vote()

	if mode == Mode.HOST:
		_process_local_bots(delta)
		_process_human_auto_turn(delta)
		_process_next_round_auto_start(delta)


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
	var player_index := int(_connected_player_by_peer.get(sender_peer_id, -1))
	if player_index >= FIRST_CLIENT_PLAYER_INDEX:
		_set_player_auto_turn_enabled(player_index, bool(message.get("auto_turn_enabled", false)), false)


func _handle_message(message: Dictionary, sender_peer_id: int) -> void:
	if mode == Mode.HOST and str(message.get("type", "")) == "auto_turn_preference":
		_handle_host_auto_turn_preference(message, sender_peer_id)
		return
	super._handle_message(message, sender_peer_id)


func _handle_host_auto_turn_preference(message: Dictionary, sender_peer_id: int) -> void:
	var player_index := int(_connected_player_by_peer.get(sender_peer_id, -1))
	if player_index < FIRST_CLIENT_PLAYER_INDEX or int(message.get("player_index", -1)) != player_index:
		return
	_set_player_auto_turn_enabled(player_index, bool(message.get("enabled", false)), true)


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
		_restore_temporary_bot_for_reconnect(assigned_player_index)
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
	snapshot["temporary_bot_player_indices"] = _get_temporary_bot_player_indices()
	var recipient_player_index := int(snapshot.get("recipient_player_index", -1))
	if is_host():
		snapshot["recipient_auto_turn_enabled"] = _human_auto_turn_enabled_by_player.has(recipient_player_index)
		var active_auto_turn_player_index := _get_active_human_player_index()
		var active_auto_turn_enabled := (
			active_auto_turn_player_index >= 0
			and _human_auto_turn_enabled_by_player.has(active_auto_turn_player_index)
		)
		snapshot["active_auto_turn_player_index"] = active_auto_turn_player_index if active_auto_turn_enabled else -1
		snapshot["active_auto_turn_total_seconds"] = HUMAN_AUTO_TURN_COUNTDOWN_SECONDS
		snapshot["active_auto_turn_remaining_seconds"] = (
			maxf(0.0, HUMAN_AUTO_TURN_COUNTDOWN_SECONDS - _human_auto_turn_elapsed_seconds)
			if active_auto_turn_enabled
			else 0.0
		)
		snapshot["next_round_auto_start_total_seconds"] = NEXT_ROUND_AUTO_START_SECONDS
		snapshot["next_round_auto_start_remaining_seconds"] = _get_next_round_auto_start_remaining_seconds()
	elif not snapshot.has("recipient_auto_turn_enabled"):
		snapshot["recipient_auto_turn_enabled"] = _local_auto_turn_enabled
	return snapshot


func _process_next_round_auto_start(delta: float) -> void:
	if not can_start_next_scheduled_round():
		_reset_next_round_auto_start()
		return

	_next_round_auto_start_elapsed_seconds = minf(
		NEXT_ROUND_AUTO_START_SECONDS,
		_next_round_auto_start_elapsed_seconds + maxf(0.0, delta)
	)
	_next_round_countdown_sync_elapsed_seconds += maxf(0.0, delta)
	if _next_round_countdown_sync_elapsed_seconds >= NEXT_ROUND_COUNTDOWN_SYNC_INTERVAL_SECONDS:
		_next_round_countdown_sync_elapsed_seconds = fmod(
			_next_round_countdown_sync_elapsed_seconds,
			NEXT_ROUND_COUNTDOWN_SYNC_INTERVAL_SECONDS
		)
		_send_current_player_snapshots()

	if _next_round_auto_start_elapsed_seconds < NEXT_ROUND_AUTO_START_SECONDS:
		return
	start_next_scheduled_round()


func _get_next_round_auto_start_remaining_seconds() -> float:
	if not can_start_next_scheduled_round():
		return 0.0
	return maxf(0.0, NEXT_ROUND_AUTO_START_SECONDS - _next_round_auto_start_elapsed_seconds)


func _reset_next_round_auto_start() -> void:
	_next_round_auto_start_elapsed_seconds = 0.0
	_next_round_countdown_sync_elapsed_seconds = 0.0


func _get_reconnecting_player_indices() -> Array[int]:
	var player_indices: Array[int] = []
	for player_index_variant in _reconnecting_player_indices.keys():
		player_indices.append(int(player_index_variant))
	player_indices.sort()
	return player_indices


func _get_temporary_bot_player_indices() -> Array[int]:
	var player_indices: Array[int] = []
	for player_index_variant in _temporary_bot_player_indices.keys():
		player_indices.append(int(player_index_variant))
	player_indices.sort()
	return player_indices


func replace_reconnecting_player_with_bot(player_index: int) -> bool:
	if not is_host() or match_host == null or not _reconnecting_player_indices.has(player_index):
		return false
	if player_index < FIRST_CLIENT_PLAYER_INDEX or player_index >= PLAYER_COUNT:
		return false

	if not _local_bot_player_indices.has(player_index):
		_local_bot_player_indices.append(player_index)
		_local_bot_player_indices.sort()
	_temporary_bot_player_indices[player_index] = true
	_reconnecting_player_indices.erase(player_index)
	match_host.set_automatic_undo_approver_indices(_local_bot_player_indices)
	if (
		first_turn_roll_phase == FirstTurnRollPhase.WAITING
		and first_turn_roll_contenders.has(player_index)
		and not first_turn_roll_submitted[player_index]
	):
		_record_first_turn_roll(player_index, false)
	_rebuild_host_lobby_seats()
	_broadcast_lobby_state()
	_send_current_player_snapshots()
	_set_status("Steam P2P: место %d временно занял бот. Игрок вернётся на своё место после переподключения." % (player_index + 1))
	return true


func _restore_temporary_bot_for_reconnect(player_index: int) -> void:
	if not _temporary_bot_player_indices.has(player_index):
		return
	_temporary_bot_player_indices.erase(player_index)
	_local_bot_player_indices.erase(player_index)
	if match_host != null:
		match_host.set_automatic_undo_approver_indices(_local_bot_player_indices)


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

	var player_names := [_local_display_name, "Игрок 2", "Игрок 3", "Игрок 4"]
	for bot_offset in _local_bot_player_indices.size():
		var player_index := _local_bot_player_indices[bot_offset]
		player_names[player_index] = "Бот %d" % (bot_offset + 1)
	var test_game := Game.new(player_names)
	match_host = MatchHost.new(test_game)
	match_host.set_history_mode(_history_mode)
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
		"requested_player_index": client_requested_player_index,
		"display_name": _local_display_name,
		"auto_turn_enabled": _local_auto_turn_enabled,
		"avatar_index": _local_avatar_index,
		"avatar_data": _local_avatar_data
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
		var is_temporary_bot := _temporary_bot_player_indices.has(player_index)
		var seat_reserved_for_reconnect := _player_index_by_steam_id.values().has(player_index)
		var is_reconnecting := _reconnecting_player_indices.has(player_index)
		var is_assigned := is_host_player or is_local_bot or _connected_client_peers_by_player.has(player_index) or seat_reserved_for_reconnect
		var is_confirmed := is_host_player or is_local_bot or _confirmed_client_peers_by_player.has(player_index)
		var bot_number := _local_bot_player_indices.find(player_index) + 1
		var stored_player_name: String = (
			match_host.game.players[player_index].display_name
			if match_host != null and player_index < match_host.game.players.size()
			else _local_display_name if is_host_player else "Игрок %d" % (player_index + 1)
		)
		var display_name: String = (
			"%s · временный бот" % stored_player_name
			if is_temporary_bot
			else "Бот %d" % bot_number
			if is_local_bot
			else stored_player_name
		)
		lobby_seats.append({
			"player_index": player_index,
			"display_name": display_name,
			"is_host": is_host_player,
			"is_bot": is_local_bot,
			"is_temporary_bot": is_temporary_bot,
			"assigned": is_assigned,
			"confirmed": is_confirmed,
			"reconnecting": is_reconnecting,
			"avatar_index": int(_avatar_index_by_player.get(player_index, 0)),
			"avatar_data": str(_avatar_data_by_player.get(player_index, ""))
		})


func _process_local_bots(delta: float) -> void:
	if _local_bot_player_indices.is_empty() or not lobby_round_started or match_host == null or is_match_paused_for_reconnect() or match_host.is_undo_vote_pending():
		return

	_bot_action_delay_seconds = maxf(0.0, _bot_action_delay_seconds - delta)
	if _bot_action_delay_seconds > 0.0:
		return

	var bot_player_index := _get_active_local_bot_player_index()
	if bot_player_index < 0:
		return

	if _submit_local_bot_action(bot_player_index):
		_bot_action_delay_seconds = BOT_ACTION_DELAY_SECONDS


func _get_automatic_first_turn_roll_player_indices() -> Array[int]:
	var automatic_players: Array[int] = []
	automatic_players.assign(_local_bot_player_indices)
	for player_index_variant in _temporary_bot_player_indices:
		var player_index := int(player_index_variant)
		if not automatic_players.has(player_index):
			automatic_players.append(player_index)
	return automatic_players


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


func _process_human_auto_turn(delta: float) -> void:
	var player_index := _get_active_human_player_index()
	if player_index < 0:
		_reset_human_auto_turn()
		return

	var decision_key := _get_human_auto_turn_decision_key(player_index)
	if decision_key != _human_auto_turn_decision_key:
		_human_auto_turn_decision_key = decision_key
		_human_auto_turn_elapsed_seconds = 0.0
		return

	_human_auto_turn_elapsed_seconds += delta
	var auto_turn_is_enabled := _human_auto_turn_enabled_by_player.has(player_index)
	if auto_turn_is_enabled:
		_human_auto_turn_sync_elapsed_seconds += maxf(0.0, delta)
		if _human_auto_turn_sync_elapsed_seconds >= HUMAN_AUTO_TURN_SYNC_INTERVAL_SECONDS:
			_human_auto_turn_sync_elapsed_seconds = fmod(
				_human_auto_turn_sync_elapsed_seconds,
				HUMAN_AUTO_TURN_SYNC_INTERVAL_SECONDS
			)
			_queue_player_snapshots_for_delivery()
	var timeout_seconds := HUMAN_AUTO_TURN_COUNTDOWN_SECONDS if auto_turn_is_enabled else HUMAN_AUTO_TURN_INACTIVITY_SECONDS
	if _human_auto_turn_elapsed_seconds < timeout_seconds:
		return

	if not auto_turn_is_enabled:
		_set_player_auto_turn_enabled(player_index, true, true)
		_human_auto_turn_decision_key = decision_key
		return

	if _submit_local_bot_action(player_index, true):
		_reset_human_auto_turn()


func _get_active_human_player_index() -> int:
	if (
		not is_host()
		or not lobby_round_started
		or match_host == null
		or match_host.game.current_round == null
		or is_match_paused_for_reconnect()
		or match_host.is_undo_vote_pending()
	):
		return -1

	var round: Round = match_host.game.current_round
	var player_index := -1
	if round.state == Round.State.BIDDING:
		player_index = round.current_player_index
	elif round.state == Round.State.PLAYING:
		player_index = _get_host_current_playing_player_index()
	if player_index < 0:
		return -1

	var automatic_players := _get_automatic_first_turn_roll_player_indices()
	return -1 if automatic_players.has(player_index) else player_index


func _get_human_auto_turn_decision_key(player_index: int) -> String:
	var round: Round = match_host.game.current_round
	var active_trick_size: int = match_host.game.active_trick.played_cards.size() if match_host.game.active_trick != null else 0
	return "%d:%d:%d:%d:%d:%d" % [
		match_host.game.round_number,
		round.state,
		player_index,
		round.bids_made,
		round.tricks_played,
		active_trick_size
	]


func _reset_human_auto_turn() -> void:
	_human_auto_turn_decision_key = ""
	_human_auto_turn_elapsed_seconds = 0.0
	_human_auto_turn_sync_elapsed_seconds = 0.0


func _set_player_auto_turn_enabled(player_index: int, enabled: bool, announce: bool) -> void:
	if player_index < 0 or player_index >= PLAYER_COUNT:
		return
	if enabled:
		_human_auto_turn_enabled_by_player[player_index] = true
	else:
		_human_auto_turn_enabled_by_player.erase(player_index)
	_reset_human_auto_turn()
	if lobby_round_started:
		_queue_player_snapshots_for_delivery()
	if announce and match_host != null and player_index < match_host.game.players.size():
		var player_name: String = str(match_host.game.players[player_index].display_name)
		if enabled:
			_set_status("У игрока %s включён автоход на 45 секунд." % player_name)
		else:
			_set_status("Игрок %s отключил автоход. Следующая AFK-проверка начнётся с 1 минуты 30 секунд." % player_name)


func _submit_local_bot_action(player_index: int, is_human_timeout: bool = false) -> bool:
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
	if is_human_timeout:
		var player_name: String = str(match_host.game.players[player_index].display_name)
		_set_status("У игрока %s закончился 45-секундный таймер — выполнен автоход: %s." % [player_name, action_text])
	else:
		_set_status("Бот %d %s. Ревизия %d отправляется подключённому игроку." % [player_index - 1, action_text, match_host.revision])
	return true


func _get_local_bot_bid(player_index: int, round: Round) -> int:
	var valid_bids: Array[int] = []
	for bid in range(round.cards_per_player + 1):
		if round.can_place_bid(player_index, bid):
			valid_bids.append(bid)
	if valid_bids.is_empty():
		return -1

	if round.round_type == Round.RoundType.DARK:
		var valid_dark_bids: Array[int] = []
		for valid_bid in valid_bids:
			if valid_bid >= 2 and valid_bid <= 4:
				valid_dark_bids.append(valid_bid)
		if not valid_dark_bids.is_empty():
			return valid_dark_bids[_bot_random.randi_range(0, valid_dark_bids.size() - 1)]

	var effective_difficulty := _get_effective_local_bot_difficulty(player_index)
	if effective_difficulty == BOT_DIFFICULTY_EASY:
		return valid_bids[0]

	var player: Player = match_host.game.players[player_index]
	var estimate := _estimate_local_bot_bid(player, round)
	if effective_difficulty == BOT_DIFFICULTY_HARD:
		estimate = _estimate_hard_local_bot_bid(player, round, estimate)
	var selected_bid := valid_bids[0]
	for valid_bid in valid_bids:
		if absi(valid_bid - estimate) < absi(selected_bid - estimate):
			selected_bid = valid_bid
	return selected_bid


func _estimate_local_bot_bid(player: Player, round: Round) -> int:
	var estimate := 0
	var trump_cards := 0
	var high_non_trump_cards := 0

	for card in player.hand:
		if card.is_joker:
			estimate += 1
			continue
		if round.trump != Round.TrumpSuit.NONE and card.suit == round.trump:
			trump_cards += 1
			if card.rank >= Card.Rank.TEN:
				estimate += 1
		elif card.rank == Card.Rank.ACE or card.rank == Card.Rank.KING:
			high_non_trump_cards += 1

	estimate += floori(float(high_non_trump_cards) / 2.0)
	if trump_cards >= 3 and estimate == 0:
		estimate = 1
	return clampi(estimate, 0, round.cards_per_player)


func _estimate_hard_local_bot_bid(player: Player, round: Round, base_estimate: int) -> int:
	var estimate := base_estimate
	var aces := 0
	var high_trumps := 0

	for card in player.hand:
		if card.is_joker:
			continue
		if card.rank == Card.Rank.ACE:
			aces += 1
		if round.trump != Round.TrumpSuit.NONE and card.suit == round.trump and card.rank >= Card.Rank.JACK:
			high_trumps += 1

	if aces >= 2:
		estimate += 1
	if high_trumps >= 2:
		estimate += 1
	return clampi(estimate, 0, round.cards_per_player)


func _get_local_bot_card_payload(player_index: int) -> Dictionary:
	if match_host == null or player_index < 0 or player_index >= match_host.game.players.size():
		return {}

	var player: Player = match_host.game.players[player_index]
	var legal_cards: Array[Card] = []
	for card in player.hand:
		if match_host.game.active_trick != null and not match_host.game.active_trick.can_play_card(player, card):
			continue
		legal_cards.append(card)
	if legal_cards.is_empty():
		return {}

	var selected_card := _choose_local_bot_card(
		player,
		legal_cards,
		_get_effective_local_bot_difficulty(player_index)
	)
	if selected_card == null:
		return {}
	if not selected_card.is_joker:
		return {"card_key": _get_card_key(selected_card)}

	var joker_mode := _choose_local_bot_joker_mode(player)
	var is_leading := match_host.game.active_trick == null
	return {
		"card_key": "joker",
		"joker_mode": joker_mode,
		"declared_suit": _choose_local_bot_joker_suit(player, joker_mode == Trick.JokerMode.NORMAL_CARD_WINS) if is_leading else -1,
		"forced_card_rank": Trick.ForcedCardRank.NONE
	}


func _choose_local_bot_card(player: Player, legal_cards: Array[Card], difficulty := -1) -> Card:
	var effective_difficulty: int = _bot_difficulty if difficulty < 0 else difficulty
	if effective_difficulty == BOT_DIFFICULTY_EASY:
		return legal_cards[_bot_random.randi_range(0, legal_cards.size() - 1)]
	if effective_difficulty == BOT_DIFFICULTY_HARD:
		return _choose_hard_local_bot_card(player, legal_cards)

	var wants_trick := _local_bot_wants_trick(player)
	if match_host.game.active_trick == null:
		if match_host.game.current_round.round_type == Round.RoundType.MISERE:
			return _select_local_bot_misere_lead_card(player, legal_cards)
		if wants_trick:
			var safe_regular_lead := _select_safe_local_bot_lead_card(player, legal_cards)
			if safe_regular_lead != null:
				return safe_regular_lead
			return _get_local_bot_joker(legal_cards)
		var low_lead_card := _select_local_bot_non_joker_by_strength(legal_cards, false)
		return low_lead_card if low_lead_card != null else legal_cards[0]

	if wants_trick:
		var weakest_winner := _select_local_bot_weakest_winner(legal_cards)
		if weakest_winner != null:
			return weakest_winner
		var taking_joker := _get_local_bot_joker(legal_cards)
		if taking_joker != null and _should_local_bot_spend_joker(player, legal_cards):
			return taking_joker
		var weakest_loser := _select_local_bot_weakest_loser(legal_cards)
		if weakest_loser != null:
			return weakest_loser
		return _select_local_bot_card_by_strength(legal_cards, true)

	if _should_local_bot_shed_high_card_in_misere(legal_cards):
		return _select_local_bot_non_joker_by_strength(legal_cards, true)
	var discarding_joker := _get_local_bot_joker(legal_cards)
	if discarding_joker != null:
		return discarding_joker
	return _select_local_bot_card_by_strength(legal_cards, false)


func _choose_hard_local_bot_card(player: Player, legal_cards: Array[Card]) -> Card:
	var wants_trick := _local_bot_wants_trick(player)
	if match_host.game.active_trick == null:
		if match_host.game.current_round.round_type == Round.RoundType.GOLDEN:
			return _select_golden_local_bot_lead_card(legal_cards, match_host.game.current_round.trump)
		if match_host.game.current_round.round_type == Round.RoundType.MISERE:
			return _select_local_bot_misere_lead_card(player, legal_cards)
		var regular_lead := (
			_select_safe_local_bot_lead_card(player, legal_cards)
			if wants_trick
			else _select_local_bot_non_joker_by_strength(legal_cards, false)
		)
		return regular_lead if regular_lead != null else _get_local_bot_joker(legal_cards)

	if wants_trick:
		var weakest_winner := _select_local_bot_weakest_winner(legal_cards)
		if weakest_winner != null:
			return weakest_winner
		var taking_joker := _get_local_bot_joker(legal_cards)
		if taking_joker != null and _should_local_bot_spend_joker(player, legal_cards):
			return taking_joker
		var weakest_loser := _select_local_bot_weakest_loser(legal_cards)
		if weakest_loser != null:
			return weakest_loser
		return _select_local_bot_card_by_strength(legal_cards, true)

	if _should_local_bot_shed_high_card_in_misere(legal_cards):
		return _select_local_bot_non_joker_by_strength(legal_cards, true)
	var weakest_loser := _select_local_bot_weakest_loser(legal_cards)
	if weakest_loser != null:
		return weakest_loser
	var discarding_joker := _get_local_bot_joker(legal_cards)
	if discarding_joker != null:
		return discarding_joker
	return _select_local_bot_card_by_strength(legal_cards, false)


func _local_bot_wants_trick(player: Player) -> bool:
	match match_host.game.current_round.round_type:
		Round.RoundType.GOLDEN:
			return true
		Round.RoundType.MISERE:
			return false
	return player.bid != player.tricks_taken


func _should_local_bot_spend_joker(player: Player, legal_cards: Array[Card]) -> bool:
	if match_host.game.current_round.round_type == Round.RoundType.GOLDEN:
		return true
	if player.tricks_taken > player.bid:
		return true

	var regular_cards := 0
	for card in legal_cards:
		if not card.is_joker:
			regular_cards += 1
	if regular_cards == 0:
		return true

	var tricks_still_needed := maxi(0, player.bid - player.tricks_taken)
	return tricks_still_needed > 0 and player.hand.size() <= tricks_still_needed


func _select_local_bot_misere_lead_card(player: Player, cards: Array[Card]) -> Card:
	var regular_cards: Array[Card] = []
	var safely_coverable_cards: Array[Card] = []
	var cards_with_live_suit: Array[Card] = []
	for card in cards:
		if card.is_joker:
			continue
		regular_cards.append(card)
		var unseen_ranks := _get_local_bot_unseen_regular_ranks(player, card.suit)
		if not unseen_ranks.is_empty():
			cards_with_live_suit.append(card)
		for unseen_rank in unseen_ranks:
			if unseen_rank > card.rank:
				safely_coverable_cards.append(card)
				break

	if not safely_coverable_cards.is_empty():
		return _select_local_bot_card_by_strength(safely_coverable_cards, true)
	if not cards_with_live_suit.is_empty():
		return _select_local_bot_card_by_strength(cards_with_live_suit, false)
	if not regular_cards.is_empty():
		return _select_local_bot_card_by_strength(regular_cards, false)
	return _get_local_bot_joker(cards)


func _get_local_bot_unseen_regular_ranks(player: Player, suit: int) -> Array[int]:
	var known_ranks: Dictionary = {}
	for card in match_host.game.played_cards_this_round:
		if not card.is_joker and card.suit == suit:
			known_ranks[card.rank] = true
	for card in player.hand:
		if not card.is_joker and card.suit == suit:
			known_ranks[card.rank] = true

	var unseen_ranks: Array[int] = []
	for rank in Card.Rank.values():
		if suit == Card.Suit.CLUBS and rank == Card.Rank.SEVEN:
			continue
		if not known_ranks.has(rank):
			unseen_ranks.append(rank)
	return unseen_ranks


func _select_safe_local_bot_lead_card(player: Player, cards: Array[Card]) -> Card:
	var regular_cards: Array[Card] = []
	var guaranteed_winners: Array[Card] = []
	for card in cards:
		if card.is_joker:
			continue
		regular_cards.append(card)
		var has_unseen_higher_card := false
		for unseen_rank in _get_local_bot_unseen_regular_ranks(player, card.suit):
			if unseen_rank > card.rank:
				has_unseen_higher_card = true
				break
		if not has_unseen_higher_card:
			guaranteed_winners.append(card)

	if not guaranteed_winners.is_empty():
		return _select_local_bot_card_by_strength(guaranteed_winners, false)
	if not regular_cards.is_empty():
		return _select_local_bot_card_by_strength(regular_cards, false)
	return null


func _select_golden_local_bot_lead_card(cards: Array[Card], trump: Round.TrumpSuit) -> Card:
	var joker := _get_local_bot_joker(cards)
	if joker != null:
		return joker
	for card in cards:
		if not card.is_joker and card.suit == trump and card.rank == Card.Rank.ACE:
			return card
	for card in cards:
		if not card.is_joker and card.suit != trump and card.rank == Card.Rank.ACE:
			return card

	var non_trumps: Array[Card] = []
	var trumps: Array[Card] = []
	for card in cards:
		if card.is_joker:
			continue
		if card.suit == trump:
			trumps.append(card)
		else:
			non_trumps.append(card)
	if not non_trumps.is_empty():
		return _select_local_bot_card_by_strength(non_trumps, false)
	return _select_local_bot_card_by_strength(trumps, false)


func _select_local_bot_weakest_winner(legal_cards: Array[Card]) -> Card:
	var winning_cards: Array[Card] = []
	for card in legal_cards:
		if not card.is_joker and _would_local_bot_card_win(card):
			winning_cards.append(card)
	return _select_local_bot_card_by_strength(winning_cards, false)


func _select_local_bot_weakest_loser(legal_cards: Array[Card]) -> Card:
	var losing_cards: Array[Card] = []
	for card in legal_cards:
		if not card.is_joker and not _would_local_bot_card_win(card):
			losing_cards.append(card)
	return _select_local_bot_card_by_strength(losing_cards, false)


func _would_local_bot_card_win(card: Card) -> bool:
	if card.is_joker or match_host.game.active_trick == null:
		return false

	var active_trick: Trick = match_host.game.active_trick
	var simulated_trick := Trick.new()
	simulated_trick.player_count = active_trick.played_cards.size() + 1
	simulated_trick.trump = active_trick.trump
	simulated_trick.lead_suit = active_trick.lead_suit
	simulated_trick.joker_mode = active_trick.joker_mode
	simulated_trick.declared_suit = active_trick.declared_suit
	simulated_trick.forced_card_rank = active_trick.forced_card_rank
	simulated_trick.played_cards.assign(active_trick.played_cards)
	simulated_trick.played_by.assign(active_trick.played_by)
	simulated_trick.played_cards.append(card)
	simulated_trick.played_by.append(-1)
	return simulated_trick.get_winner_index() == -1


func _should_local_bot_shed_high_card_in_misere(legal_cards: Array[Card]) -> bool:
	if (
		match_host.game.current_round.round_type != Round.RoundType.MISERE
		or match_host.game.active_trick == null
		or match_host.game.active_trick.played_cards.size() != match_host.game.players.size() - 1
		or _get_local_bot_joker(legal_cards) != null
	):
		return false

	var has_regular_card := false
	for card in legal_cards:
		if card.is_joker:
			continue
		has_regular_card = true
		if not _would_local_bot_card_win(card):
			return false
	return has_regular_card


func _get_local_bot_joker(cards: Array[Card]) -> Card:
	for card in cards:
		if card.is_joker:
			return card
	return null


func _select_local_bot_non_joker_by_strength(cards: Array[Card], choose_highest: bool) -> Card:
	var regular_cards: Array[Card] = []
	for card in cards:
		if not card.is_joker:
			regular_cards.append(card)
	return _select_local_bot_card_by_strength(regular_cards, choose_highest)


func _select_local_bot_card_by_strength(cards: Array[Card], choose_highest: bool) -> Card:
	var selected_card: Card
	for card in cards:
		if selected_card == null:
			selected_card = card
			continue
		var card_strength := _get_local_bot_card_strength(card)
		var selected_strength := _get_local_bot_card_strength(selected_card)
		var replaces_selected := card_strength > selected_strength if choose_highest else card_strength < selected_strength
		if replaces_selected:
			selected_card = card
	return selected_card


func _get_local_bot_card_strength(card: Card) -> int:
	if card.is_joker:
		return 100
	var strength := int(card.rank)
	if match_host.game.current_round.trump != Round.TrumpSuit.NONE and card.suit == match_host.game.current_round.trump:
		strength += 20
	if match_host.game.active_trick != null and card.suit == match_host.game.active_trick.lead_suit:
		strength += 10
	return strength


func _choose_local_bot_joker_mode(player: Player) -> Trick.JokerMode:
	if _bot_difficulty == BOT_DIFFICULTY_EASY:
		return Trick.JokerMode.JOKER_WINS if _bot_random.randi_range(0, 1) == 0 else Trick.JokerMode.NORMAL_CARD_WINS
	return Trick.JokerMode.JOKER_WINS if _local_bot_wants_trick(player) else Trick.JokerMode.NORMAL_CARD_WINS


func _choose_local_bot_joker_suit(player: Player, prefer_rare_suit: bool) -> int:
	if _bot_difficulty == BOT_DIFFICULTY_EASY:
		return _bot_random.randi_range(Card.Suit.CLUBS, Card.Suit.DIAMONDS)

	var suit_counts: Array[int] = [0, 0, 0, 0]
	for card in player.hand:
		if not card.is_joker:
			suit_counts[card.suit] += 1

	var selected_suit := Card.Suit.CLUBS
	for suit in Card.Suit.values():
		if prefer_rare_suit:
			if suit_counts[suit] < suit_counts[selected_suit]:
				selected_suit = suit
		elif suit_counts[suit] > suit_counts[selected_suit]:
			selected_suit = suit
	return selected_suit
