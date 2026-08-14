class_name SteamBridge
extends RefCounted


signal lobby_status_changed
signal lobby_joined_successfully
signal lobby_browser_updated


enum LobbyVisibility {
	PRIVATE,
	FRIENDS_ONLY,
	PUBLIC,
}


const STEAM_SINGLETON_NAME := &"Steam"
const TEST_APP_ID := 480
const LOBBY_TYPE_PRIVATE := 0
const LOBBY_TYPE_FRIENDS_ONLY := 1
const LOBBY_TYPE_PUBLIC := 2
const LOBBY_MEMBER_LIMIT := 4
const STEAM_RESULT_OK := 1
const LOBBY_JOIN_RESPONSE_SUCCESS := 1
const LOBBY_COMPARISON_EQUAL := 0
const LOBBY_DISTANCE_WORLDWIDE := 3
const FRIEND_FLAG_IMMEDIATE := 4
const LOBBY_BROWSER_RESULT_LIMIT := 50
const LOBBY_PROTOCOL_VERSION := 6
const LOBBY_STATE_WAITING := "waiting"
const LOBBY_STATE_PLAYING := "playing"
const MATCH_MODE_CLASSIC := "classic"
const MATCH_MODE_TEAMS_2V2 := "teams_2v2"
const P2P_MATCH_CHANNEL := 42
const P2P_SEND_RELIABLE := 2
const MAX_P2P_PACKET_BYTES := 32 * 1024
const MAX_P2P_PACKETS_PER_POLL := 32


var _initialization_attempted := false
var _initialized := false
var _initialization_status := -1
var _initialization_verbal := ""
var _persona_name := ""
var _active_app_id := 0
var _lobby_callbacks_connected := false
var _lobby_id := 0
var _lobby_status := "Steam-комната ещё не создана."
var _local_lobby_ready := false
var _pending_join_source := ""
var _pending_lobby_visibility: LobbyVisibility = LobbyVisibility.FRIENDS_ONLY
var _pending_match_mode := MATCH_MODE_CLASSIC
var _pending_team_one_name := "Команда 1"
var _public_lobbies: Array[Dictionary] = []
var _friend_lobbies: Array[Dictionary] = []
var _friend_lobby_ids: Dictionary = {}
var _known_public_lobby_ids: Dictionary = {}
var _requested_summary_lobby_ids: Dictionary = {}
var _unavailable_lobby_ids: Dictionary = {}
var _lobby_browser_status := "Список комнат ещё не обновлялся."


func is_p2p_transport_available() -> bool:
	var steam_api := _get_steam_api()
	return (
		_initialized
		and steam_api != null
		and steam_api.has_method(&"sendP2PPacket")
		and steam_api.has_method(&"getAvailableP2PPacketSize")
		and steam_api.has_method(&"readP2PPacket")
	)


func is_multiplayer_peer_transport_available() -> bool:
	return _initialized and ClassDB.class_exists("SteamMultiplayerPeer")


func prepare_multiplayer_peer_transport() -> bool:
	if not is_multiplayer_peer_transport_available():
		return false

	var steam_api := _get_steam_api()
	if steam_api != null and steam_api.has_method(&"allowP2PPacketRelay"):
		steam_api.call(&"allowP2PPacketRelay", true)
	return true


func create_multiplayer_peer() -> Object:
	if not is_multiplayer_peer_transport_available():
		return null

	var multiplayer_peer: Object = ClassDB.instantiate("SteamMultiplayerPeer")
	if multiplayer_peer == null:
		return null
	return multiplayer_peer


func prepare_p2p_transport() -> bool:
	if not is_p2p_transport_available():
		return false

	var steam_api := _get_steam_api()
	if steam_api.has_method(&"allowP2PPacketRelay"):
		steam_api.call(&"allowP2PPacketRelay", true)
	return true


func get_local_steam_id() -> int:
	var steam_api := _get_steam_api()
	if not _initialized or steam_api == null or not steam_api.has_method(&"getSteamID"):
		return 0
	return int(steam_api.call(&"getSteamID"))


func is_current_lobby_member(steam_id: int) -> bool:
	if steam_id <= 0 or _lobby_id <= 0:
		return false
	for member in get_lobby_state().get("members", []):
		if member is Dictionary and int(member.get("steam_id", 0)) == steam_id:
			return true
	return false


func send_p2p_match_message(remote_steam_id: int, message: Dictionary) -> bool:
	if not is_p2p_transport_available() or remote_steam_id <= 0:
		return false
	if remote_steam_id == get_local_steam_id() or not is_current_lobby_member(remote_steam_id):
		return false

	var encoded_message := JSON.stringify(message).to_utf8_buffer()
	if encoded_message.is_empty() or encoded_message.size() > MAX_P2P_PACKET_BYTES:
		return false

	var steam_api := _get_steam_api()
	return bool(steam_api.call(&"sendP2PPacket", remote_steam_id, encoded_message, P2P_SEND_RELIABLE, P2P_MATCH_CHANNEL))


func receive_p2p_match_messages() -> Array[Dictionary]:
	var messages: Array[Dictionary] = []
	if not is_p2p_transport_available():
		return messages

	var steam_api := _get_steam_api()
	for _packet_index in range(MAX_P2P_PACKETS_PER_POLL):
		var packet_size := int(steam_api.call(&"getAvailableP2PPacketSize", P2P_MATCH_CHANNEL))
		if packet_size <= 0:
			break
		if packet_size > MAX_P2P_PACKET_BYTES:
			steam_api.call(&"readP2PPacket", packet_size, P2P_MATCH_CHANNEL)
			continue

		var packet_variant: Variant = steam_api.call(&"readP2PPacket", packet_size, P2P_MATCH_CHANNEL)
		if not (packet_variant is Dictionary):
			continue
		var packet: Dictionary = packet_variant
		var remote_steam_id := int(packet.get("steam_id_remote", packet.get("steamIDRemote", 0)))
		if not is_current_lobby_member(remote_steam_id):
			continue

		var data_variant: Variant = packet.get("data", PackedByteArray())
		var packet_bytes := PackedByteArray()
		if data_variant is PackedByteArray:
			packet_bytes = data_variant
		elif data_variant is Array:
			for byte_variant in data_variant:
				packet_bytes.append(int(byte_variant))
		if packet_bytes.is_empty():
			continue

		var parsed_message: Variant = JSON.parse_string(packet_bytes.get_string_from_utf8())
		if parsed_message is Dictionary:
			messages.append({
				"sender_steam_id": remote_steam_id,
				"message": parsed_message
			})

	return messages


func close_p2p_match_sessions() -> void:
	var steam_api := _get_steam_api()
	if steam_api == null or not steam_api.has_method(&"closeP2PChannelWithUser"):
		return
	for member in get_lobby_state().get("members", []):
		if not (member is Dictionary):
			continue
		var member_steam_id := int(member.get("steam_id", 0))
		if member_steam_id > 0 and member_steam_id != get_local_steam_id():
			steam_api.call(&"closeP2PChannelWithUser", member_steam_id, P2P_MATCH_CHANNEL)


func get_diagnostics() -> Dictionary:
	var singleton_available := Engine.has_singleton(STEAM_SINGLETON_NAME)
	var steam_api: Object = Engine.get_singleton(STEAM_SINGLETON_NAME) if singleton_available else null
	var steam_class_available := ClassDB.class_exists(STEAM_SINGLETON_NAME)
	var steam_runtime_available := steam_api != null or steam_class_available
	var app_id_file_paths := _get_app_id_file_paths()
	var app_id_configured := false

	for app_id_path in app_id_file_paths:
		if FileAccess.file_exists(app_id_path):
			app_id_configured = true
			break

	var diagnostics := {
		"runtime_available": steam_runtime_available,
		"singleton_available": singleton_available,
		"class_available": steam_class_available,
		"app_id_configured": app_id_configured,
		"can_initialize": steam_api != null and steam_api.has_method(&"steamInitEx"),
		"initialization_attempted": _initialization_attempted,
		"initialized": _initialized,
		"initialization_status": _initialization_status,
		"initialization_verbal": _initialization_verbal,
		"persona_name": _persona_name,
		"active_app_id": _active_app_id,
	}

	if _initialized:
		diagnostics["message"] = "Steam-клиент успешно инициализирован для локальной проверки. Создание тестовой Steam-комнаты доступно отдельно в инструментах разработчика."
	elif _initialization_attempted:
		diagnostics["message"] = "Steam не подтвердил инициализацию. Проверь, что Steam запущен от того же пользователя Windows и не открыт от другого уровня прав."
	elif not steam_runtime_available:
		diagnostics["message"] = "GodotSteam не найден. Открой проект отдельным редактором GodotSteam, чтобы проверить Steam API."
	elif steam_api == null:
		diagnostics["message"] = "GodotSteam-класс найден, но Steam API не стал доступен как системный объект. Инициализацию пока не выполняем."
	elif not diagnostics["can_initialize"]:
		diagnostics["message"] = "Steam API найден, но нужный метод инициализации недоступен. Проверь совместимость версии GodotSteam."
	elif app_id_configured:
		diagnostics["message"] = "GodotSteam готов к следующей проверке инициализации. App ID найден только локально и не попадёт в Git."
	else:
		diagnostics["message"] = "GodotSteam найден. App ID пока не настроен, поэтому Steam-клиент и лобби намеренно не запускаются."

	return diagnostics


func initialize_for_diagnostics() -> Dictionary:
	var steam_api := _get_steam_api()
	if steam_api == null or not steam_api.has_method(&"steamInitEx"):
		return get_diagnostics()

	if _initialized:
		return get_diagnostics()

	_initialization_attempted = true
	_initialization_status = -1
	_initialization_verbal = ""
	var initialization_response: Variant = steam_api.call(&"steamInitEx", TEST_APP_ID)
	if initialization_response is Dictionary:
		var response: Dictionary = initialization_response
		_initialization_status = int(response.get("status", -1))
		_initialization_verbal = str(response.get("verbal", ""))
	else:
		_initialization_verbal = "Steam вернул неожиданный ответ: %s" % str(initialization_response)

	_initialized = _initialization_status == 0
	if _initialized:
		if steam_api.has_method(&"getPersonaName"):
			_persona_name = str(steam_api.call(&"getPersonaName"))
		if steam_api.has_method(&"getAppID"):
			_active_app_id = int(steam_api.call(&"getAppID"))
		_ensure_lobby_callbacks(steam_api)

	return get_diagnostics()


func process_callbacks() -> void:
	if not _initialized:
		return

	var steam_api := _get_steam_api()
	if steam_api != null and steam_api.has_method(&"run_callbacks"):
		steam_api.call(&"run_callbacks")


func create_friends_lobby() -> Dictionary:
	return create_lobby(LobbyVisibility.FRIENDS_ONLY, MATCH_MODE_CLASSIC)


func create_lobby(
	visibility: int = LobbyVisibility.FRIENDS_ONLY,
	match_mode: String = MATCH_MODE_CLASSIC,
	team_one_name: String = "Команда 1"
) -> Dictionary:
	if not _initialized:
		_lobby_status = "Сначала подключи Steam-клиент."
		lobby_status_changed.emit()
		return get_lobby_state()
	if _lobby_id > 0:
		_lobby_status = "Комната уже создана."
		lobby_status_changed.emit()
		return get_lobby_state()

	var steam_api := _get_steam_api()
	if steam_api == null or not steam_api.has_method(&"createLobby"):
		_lobby_status = "Steam API не предоставляет создание комнат в этой среде."
		lobby_status_changed.emit()
		return get_lobby_state()

	_ensure_lobby_callbacks(steam_api)
	_pending_lobby_visibility = clampi(
		visibility,
		LobbyVisibility.PRIVATE,
		LobbyVisibility.PUBLIC
	)
	_pending_match_mode = match_mode if match_mode == MATCH_MODE_TEAMS_2V2 else MATCH_MODE_CLASSIC
	_pending_team_one_name = _sanitize_team_name(team_one_name, "Команда 1")
	_lobby_status = "Создаём Steam-комнату «%s» на четыре места…" % _get_visibility_label(_pending_lobby_visibility)
	steam_api.call(&"createLobby", _get_steam_lobby_type(_pending_lobby_visibility), LOBBY_MEMBER_LIMIT)
	lobby_status_changed.emit()
	return get_lobby_state()


func request_lobby_browser() -> Dictionary:
	if not _initialized:
		_lobby_browser_status = "Steam не подключён. Запусти игру через Steam и обнови список."
		lobby_browser_updated.emit()
		return get_lobby_browser_state()

	var steam_api := _get_steam_api()
	if steam_api == null:
		_lobby_browser_status = "Steam API недоступен."
		lobby_browser_updated.emit()
		return get_lobby_browser_state()

	_collect_friend_lobby_ids(steam_api)
	if (
		not steam_api.has_method(&"requestLobbyList")
		or not steam_api.has_method(&"addRequestLobbyListStringFilter")
	):
		_lobby_browser_status = "Эта версия Steam API не поддерживает поиск комнат."
		lobby_browser_updated.emit()
		return get_lobby_browser_state()

	steam_api.call(&"addRequestLobbyListStringFilter", "project", "project_joker", LOBBY_COMPARISON_EQUAL)
	steam_api.call(&"addRequestLobbyListStringFilter", "protocol", str(LOBBY_PROTOCOL_VERSION), LOBBY_COMPARISON_EQUAL)
	steam_api.call(&"addRequestLobbyListStringFilter", "state", LOBBY_STATE_WAITING, LOBBY_COMPARISON_EQUAL)
	if steam_api.has_method(&"addRequestLobbyListFilterSlotsAvailable"):
		steam_api.call(&"addRequestLobbyListFilterSlotsAvailable", 1)
	if steam_api.has_method(&"addRequestLobbyListDistanceFilter"):
		steam_api.call(&"addRequestLobbyListDistanceFilter", LOBBY_DISTANCE_WORLDWIDE)
	if steam_api.has_method(&"addRequestLobbyListResultCountFilter"):
		steam_api.call(&"addRequestLobbyListResultCountFilter", LOBBY_BROWSER_RESULT_LIMIT)
	_lobby_browser_status = "Ищем открытые комнаты…"
	steam_api.call(&"requestLobbyList")
	lobby_browser_updated.emit()
	return get_lobby_browser_state()


func request_lobby_summary(lobby_id: int) -> bool:
	var steam_api := _get_steam_api()
	if not _initialized or lobby_id <= 0 or steam_api == null or not steam_api.has_method(&"requestLobbyData"):
		return false
	_unavailable_lobby_ids.erase(lobby_id)
	_requested_summary_lobby_ids[lobby_id] = true
	return bool(steam_api.call(&"requestLobbyData", lobby_id))


func get_lobby_summary(lobby_id: int) -> Dictionary:
	if lobby_id <= 0:
		return {}
	var summary := _create_lobby_summary(lobby_id)
	if summary.is_empty():
		return {
			"lobby_id": lobby_id,
			"available": false,
			"confirmed_missing": _unavailable_lobby_ids.has(lobby_id),
		}
	summary["available"] = true
	return summary


func get_lobby_browser_state() -> Dictionary:
	return {
		"initialized": _initialized,
		"status": _lobby_browser_status,
		"public_lobbies": _public_lobbies.duplicate(true),
		"friend_lobbies": _friend_lobbies.duplicate(true),
	}


func open_lobby_invite_overlay() -> Dictionary:
	if _lobby_id <= 0:
		_lobby_status = "Сначала создай или зайди в Steam-комнату."
		lobby_status_changed.emit()
		return get_lobby_state()

	var steam_api := _get_steam_api()
	if steam_api == null or not steam_api.has_method(&"activateGameOverlayInviteDialog"):
		_lobby_status = "Steam Overlay с приглашениями недоступен в этой среде."
		lobby_status_changed.emit()
		return get_lobby_state()

	steam_api.call(&"activateGameOverlayInviteDialog", _lobby_id)
	_lobby_status = "Steam открыл диалог приглашения для этой комнаты."
	lobby_status_changed.emit()
	return get_lobby_state()


func join_lobby(lobby_id: int, source: String = "Steam") -> Dictionary:
	if not _initialized:
		_lobby_status = "Сначала подключи Steam-клиент."
		lobby_status_changed.emit()
		return get_lobby_state()
	if lobby_id <= 0:
		_lobby_status = "Steam передал некорректный ID комнаты."
		lobby_status_changed.emit()
		return get_lobby_state()
	if _lobby_id == lobby_id:
		_lobby_status = "Ты уже находишься в этой Steam-комнате."
		lobby_status_changed.emit()
		return get_lobby_state()
	if _lobby_id > 0:
		_lobby_status = "Сначала выйди из текущей Steam-комнаты."
		lobby_status_changed.emit()
		return get_lobby_state()

	var steam_api := _get_steam_api()
	if steam_api == null or not steam_api.has_method(&"joinLobby"):
		_lobby_status = "Steam API не предоставляет вход в комнаты в этой среде."
		lobby_status_changed.emit()
		return get_lobby_state()

	_ensure_lobby_callbacks(steam_api)
	_pending_join_source = source
	_lobby_status = "Входим в Steam-комнату по %s…" % source
	steam_api.call(&"joinLobby", lobby_id)
	lobby_status_changed.emit()
	return get_lobby_state()


func join_lobby_from_launch() -> Dictionary:
	var lobby_id := _get_launch_lobby_id()
	if lobby_id <= 0:
		_lobby_status = "Steam не передал ID комнаты при запуске."
		lobby_status_changed.emit()
		return get_lobby_state()
	return join_lobby(lobby_id, "приглашению Steam")


func has_lobby_join_request_from_launch() -> bool:
	return _get_launch_lobby_id() > 0


func set_local_lobby_ready(ready: bool) -> Dictionary:
	if _lobby_id <= 0:
		_lobby_status = "Готовность можно отметить только внутри Steam-комнаты."
		lobby_status_changed.emit()
		return get_lobby_state()

	var steam_api := _get_steam_api()
	if steam_api == null or not steam_api.has_method(&"setLobbyMemberData"):
		_lobby_status = "Steam API не предоставляет отметку готовности в этой среде."
		lobby_status_changed.emit()
		return get_lobby_state()

	_local_lobby_ready = ready
	steam_api.call(&"setLobbyMemberData", _lobby_id, "pj_ready", "1" if ready else "0")
	_lobby_status = "Ты готов к сетевой партии." if ready else "Готовность отменена."
	lobby_status_changed.emit()
	return get_lobby_state()


func set_local_lobby_team(team_id: int) -> Dictionary:
	var state := get_lobby_state()
	if _lobby_id <= 0 or str(state.get("match_mode", MATCH_MODE_CLASSIC)) != MATCH_MODE_TEAMS_2V2:
		return state
	var local_steam_id := get_local_steam_id()
	if local_steam_id == int(state.get("lobby_owner", 0)):
		team_id = 0
	team_id = clampi(team_id, 0, 1)
	var team_size := 0
	for member_variant in state.get("members", []):
		if member_variant is Dictionary:
			var member: Dictionary = member_variant
			if int(member.get("steam_id", 0)) != local_steam_id and int(member.get("team_id", -1)) == team_id:
				team_size += 1
	if team_size >= 2:
		_lobby_status = "В выбранной команде уже два игрока."
		lobby_status_changed.emit()
		return get_lobby_state()
	var steam_api := _get_steam_api()
	if steam_api == null or not steam_api.has_method(&"setLobbyMemberData"):
		return state
	_local_lobby_ready = false
	steam_api.call(&"setLobbyMemberData", _lobby_id, "pj_team", str(team_id))
	steam_api.call(&"setLobbyMemberData", _lobby_id, "pj_ready", "0")
	_lobby_status = "Команда выбрана. Подтверди готовность после настройки комнаты."
	lobby_status_changed.emit()
	return get_lobby_state()


func set_local_lobby_team_name(team_name: String) -> Dictionary:
	var state := get_lobby_state()
	if _lobby_id <= 0 or str(state.get("match_mode", MATCH_MODE_CLASSIC)) != MATCH_MODE_TEAMS_2V2:
		return state
	var local_steam_id := get_local_steam_id()
	var local_team_id := int(state.get("local_team_id", -1))
	var safe_name := _sanitize_team_name(team_name, "Команда %d" % (local_team_id + 1))
	var steam_api := _get_steam_api()
	if steam_api == null:
		return state
	if local_steam_id == int(state.get("lobby_owner", 0)) and local_team_id == 0 and steam_api.has_method(&"setLobbyData"):
		steam_api.call(&"setLobbyData", _lobby_id, "pj_team_0_name", safe_name)
	elif local_team_id == 1 and bool(state.get("local_is_team_captain", false)) and steam_api.has_method(&"setLobbyMemberData"):
		steam_api.call(&"setLobbyMemberData", _lobby_id, "pj_team_name", safe_name)
	else:
		_lobby_status = "Название команды может менять только её капитан."
		lobby_status_changed.emit()
		return get_lobby_state()
	_local_lobby_ready = false
	if steam_api.has_method(&"setLobbyMemberData"):
		steam_api.call(&"setLobbyMemberData", _lobby_id, "pj_ready", "0")
	_lobby_status = "Название команды обновлено."
	lobby_status_changed.emit()
	return get_lobby_state()


func kick_lobby_member(member_steam_id: int) -> Dictionary:
	var state := get_lobby_state()
	var local_steam_id := get_local_steam_id()
	if _lobby_id <= 0 or local_steam_id != int(state.get("lobby_owner", 0)) or member_steam_id <= 0 or member_steam_id == local_steam_id:
		return state
	if str(state.get("match_state", LOBBY_STATE_WAITING)) != LOBBY_STATE_WAITING:
		_lobby_status = "Исключать игроков можно только до начала партии."
		lobby_status_changed.emit()
		return state
	var steam_api := _get_steam_api()
	if steam_api == null or not steam_api.has_method(&"setLobbyData"):
		return state
	var kicked_ids := _parse_steam_id_list(str(steam_api.call(&"getLobbyData", _lobby_id, "pj_kicked_ids")))
	kicked_ids[member_steam_id] = true
	var serialized_ids: PackedStringArray = []
	for kicked_id in kicked_ids.keys():
		serialized_ids.append(str(int(kicked_id)))
	steam_api.call(&"setLobbyData", _lobby_id, "pj_kicked_ids", ",".join(serialized_ids))
	_lobby_status = "Игрок исключён из комнаты."
	lobby_status_changed.emit()
	return get_lobby_state()


func set_fill_empty_seats_with_bots(enabled: bool) -> Dictionary:
	if _lobby_id <= 0:
		_lobby_status = "Ботов можно добавить только внутри Steam-комнаты."
		lobby_status_changed.emit()
		return get_lobby_state()

	var steam_api := _get_steam_api()
	if steam_api == null or not steam_api.has_method(&"setLobbyData"):
		_lobby_status = "Steam API не позволяет изменить состав комнаты в этой среде."
		lobby_status_changed.emit()
		return get_lobby_state()

	var lobby_owner := int(steam_api.call(&"getLobbyOwner", _lobby_id)) if steam_api.has_method(&"getLobbyOwner") else 0
	if lobby_owner != get_local_steam_id():
		_lobby_status = "Заполнять свободные места ботами может только хост."
		lobby_status_changed.emit()
		return get_lobby_state()

	steam_api.call(&"setLobbyData", _lobby_id, "pj_fill_bots", "1" if enabled else "0")
	_lobby_status = "Свободные места заполнены ботами." if enabled else "Боты убраны из свободных мест."
	lobby_status_changed.emit()
	return get_lobby_state()


func set_lobby_bot_difficulty(difficulty: int) -> Dictionary:
	if _lobby_id <= 0:
		_lobby_status = "Сложность сетевых ботов можно выбрать только внутри Steam-комнаты."
		lobby_status_changed.emit()
		return get_lobby_state()

	var steam_api := _get_steam_api()
	if steam_api == null or not steam_api.has_method(&"setLobbyData"):
		_lobby_status = "Steam API не позволяет изменить сложность ботов в этой среде."
		lobby_status_changed.emit()
		return get_lobby_state()

	var lobby_owner := int(steam_api.call(&"getLobbyOwner", _lobby_id)) if steam_api.has_method(&"getLobbyOwner") else 0
	if lobby_owner != get_local_steam_id():
		_lobby_status = "Сложность сетевых ботов может менять только хост."
		lobby_status_changed.emit()
		return get_lobby_state()

	var safe_difficulty := clampi(difficulty, 0, 2)
	steam_api.call(&"setLobbyData", _lobby_id, "pj_bot_difficulty", str(safe_difficulty))
	_lobby_status = "Сложность сетевых ботов обновлена."
	lobby_status_changed.emit()
	return get_lobby_state()


func set_lobby_history_mode(history_mode: int) -> Dictionary:
	if _lobby_id <= 0:
		_lobby_status = "Режим истории можно выбрать только внутри Steam-комнаты."
		lobby_status_changed.emit()
		return get_lobby_state()

	var steam_api := _get_steam_api()
	if steam_api == null or not steam_api.has_method(&"setLobbyData"):
		_lobby_status = "Steam API не позволяет изменить режим истории в этой среде."
		lobby_status_changed.emit()
		return get_lobby_state()

	var lobby_owner := int(steam_api.call(&"getLobbyOwner", _lobby_id)) if steam_api.has_method(&"getLobbyOwner") else 0
	if lobby_owner != get_local_steam_id():
		_lobby_status = "Режим истории матча может менять только хост."
		lobby_status_changed.emit()
		return get_lobby_state()

	var safe_mode := clampi(history_mode, 0, 1)
	steam_api.call(&"setLobbyData", _lobby_id, "pj_history_mode", str(safe_mode))
	_lobby_status = "Режим истории матча обновлён."
	lobby_status_changed.emit()
	return get_lobby_state()


func set_lobby_match_state(match_state: String) -> Dictionary:
	if _lobby_id <= 0:
		return get_lobby_state()
	var safe_state := match_state if match_state in [LOBBY_STATE_WAITING, LOBBY_STATE_PLAYING] else LOBBY_STATE_WAITING
	var steam_api := _get_steam_api()
	if (
		steam_api == null
		or not steam_api.has_method(&"setLobbyData")
		or not steam_api.has_method(&"getLobbyOwner")
		or int(steam_api.call(&"getLobbyOwner", _lobby_id)) != get_local_steam_id()
	):
		return get_lobby_state()
	steam_api.call(&"setLobbyData", _lobby_id, "state", safe_state)
	lobby_status_changed.emit()
	return get_lobby_state()


func leave_lobby() -> Dictionary:
	if _lobby_id <= 0:
		_lobby_status = "Активной Steam-комнаты нет."
		lobby_status_changed.emit()
		return get_lobby_state()

	var steam_api := _get_steam_api()
	if steam_api != null and steam_api.has_method(&"leaveLobby"):
		steam_api.call(&"leaveLobby", _lobby_id)
	_lobby_id = 0
	_local_lobby_ready = false
	_pending_join_source = ""
	_lobby_status = "Ты вышел из Steam-комнаты."
	lobby_status_changed.emit()
	return get_lobby_state()


func get_lobby_state() -> Dictionary:
	var member_count := 0
	var member_limit := LOBBY_MEMBER_LIMIT
	var lobby_owner := 0
	var fill_empty_seats_with_bots := false
	var bot_difficulty := 1
	var history_mode := 0
	var visibility := LobbyVisibility.FRIENDS_ONLY
	var match_state := LOBBY_STATE_WAITING
	var match_mode := MATCH_MODE_CLASSIC
	var team_names := ["Команда 1", "Команда 2"]
	var kicked_ids: Dictionary = {}
	var host_name := ""
	var protocol := 0
	var members: Array[Dictionary] = []
	var steam_api := _get_steam_api()
	if _lobby_id > 0 and steam_api != null:
		if steam_api.has_method(&"getNumLobbyMembers"):
			member_count = int(steam_api.call(&"getNumLobbyMembers", _lobby_id))
		if steam_api.has_method(&"getLobbyMemberLimit"):
			member_limit = int(steam_api.call(&"getLobbyMemberLimit", _lobby_id))
		if steam_api.has_method(&"getLobbyOwner"):
			lobby_owner = int(steam_api.call(&"getLobbyOwner", _lobby_id))
		if steam_api.has_method(&"getLobbyData"):
			fill_empty_seats_with_bots = str(steam_api.call(&"getLobbyData", _lobby_id, "pj_fill_bots")) == "1"
			var saved_bot_difficulty := str(steam_api.call(&"getLobbyData", _lobby_id, "pj_bot_difficulty"))
			if not saved_bot_difficulty.is_empty():
				bot_difficulty = clampi(int(saved_bot_difficulty), 0, 2)
			var saved_history_mode := str(steam_api.call(&"getLobbyData", _lobby_id, "pj_history_mode"))
			if not saved_history_mode.is_empty():
				history_mode = clampi(int(saved_history_mode), 0, 1)
			visibility = clampi(
				int(steam_api.call(&"getLobbyData", _lobby_id, "pj_visibility")),
				LobbyVisibility.PRIVATE,
				LobbyVisibility.PUBLIC
			)
			match_state = str(steam_api.call(&"getLobbyData", _lobby_id, "state"))
			if match_state.is_empty():
				match_state = LOBBY_STATE_WAITING
			match_mode = str(steam_api.call(&"getLobbyData", _lobby_id, "mode"))
			if match_mode != MATCH_MODE_TEAMS_2V2:
				match_mode = MATCH_MODE_CLASSIC
			team_names[0] = _sanitize_team_name(
				str(steam_api.call(&"getLobbyData", _lobby_id, "pj_team_0_name")),
				"Команда 1"
			)
			team_names[1] = _sanitize_team_name(
				str(steam_api.call(&"getLobbyData", _lobby_id, "pj_team_1_name")),
				"Команда 2"
			)
			kicked_ids = _parse_steam_id_list(str(steam_api.call(&"getLobbyData", _lobby_id, "pj_kicked_ids")))
			host_name = str(steam_api.call(&"getLobbyData", _lobby_id, "host_name"))
			protocol = int(steam_api.call(&"getLobbyData", _lobby_id, "protocol"))
		members = _get_lobby_members(steam_api, member_count, lobby_owner)

	var team_counts := [0, 0]
	var team_one_captain_steam_id := 0
	for member_variant in members:
		var member: Dictionary = member_variant
		var team_id := int(member.get("team_id", -1))
		if team_id >= 0 and team_id < 2:
			team_counts[team_id] += 1
		if team_id == 1 and team_one_captain_steam_id <= 0:
			team_one_captain_steam_id = int(member.get("steam_id", 0))
			team_names[1] = _sanitize_team_name(str(member.get("team_name_request", "")), str(team_names[1]))
	var local_steam_id := get_local_steam_id()
	var local_team_id := -1
	for member_variant in members:
		var member: Dictionary = member_variant
		if int(member.get("steam_id", 0)) == local_steam_id:
			local_team_id = int(member.get("team_id", -1))
			break

	return {
		"initialized": _initialized,
		"lobby_id": _lobby_id,
		"status": _lobby_status,
		"member_count": member_count,
		"member_limit": member_limit,
		"lobby_owner": lobby_owner,
		"members": members,
		"local_ready": _local_lobby_ready,
		"fill_empty_seats_with_bots": fill_empty_seats_with_bots,
		"bot_difficulty": bot_difficulty,
		"history_mode": history_mode,
		"match_mode": match_mode,
		"team_names": team_names,
		"team_counts": team_counts,
		"local_team_id": local_team_id,
		"local_is_team_captain": (
			(local_team_id == 0 and local_steam_id == lobby_owner)
			or (local_team_id == 1 and local_steam_id == team_one_captain_steam_id)
		),
		"kicked_steam_ids": kicked_ids.keys(),
		"visibility": visibility,
		"visibility_label": _get_visibility_label(visibility),
		"match_state": match_state,
		"host_name": host_name,
		"protocol": protocol,
		"bot_count": maxi(0, member_limit - member_count) if fill_empty_seats_with_bots else 0,
	}


func _get_steam_api() -> Object:
	if not Engine.has_singleton(STEAM_SINGLETON_NAME):
		return null
	return Engine.get_singleton(STEAM_SINGLETON_NAME)


func _ensure_lobby_callbacks(steam_api: Object) -> void:
	if _lobby_callbacks_connected:
		return

	if steam_api.has_signal(&"lobby_created"):
		steam_api.connect(&"lobby_created", _on_lobby_created)
	if steam_api.has_signal(&"lobby_joined"):
		steam_api.connect(&"lobby_joined", _on_lobby_joined)
	if steam_api.has_signal(&"lobby_chat_update"):
		steam_api.connect(&"lobby_chat_update", _on_lobby_chat_update)
	if steam_api.has_signal(&"lobby_data_update"):
		steam_api.connect(&"lobby_data_update", _on_lobby_data_update)
	if steam_api.has_signal(&"lobby_match_list"):
		steam_api.connect(&"lobby_match_list", _on_lobby_match_list)
	if steam_api.has_signal(&"lobby_invite"):
		steam_api.connect(&"lobby_invite", _on_lobby_invite)
	if steam_api.has_signal(&"join_requested"):
		steam_api.connect(&"join_requested", _on_join_requested)
	if steam_api.has_signal(&"p2p_session_request"):
		steam_api.connect(&"p2p_session_request", _on_p2p_session_request)
	if steam_api.has_signal(&"p2p_session_connect_fail"):
		steam_api.connect(&"p2p_session_connect_fail", _on_p2p_session_connect_fail)
	_lobby_callbacks_connected = true


func _on_lobby_created(result: int, lobby_id: int) -> void:
	if result != STEAM_RESULT_OK:
		_lobby_status = "Steam не создал комнату. Код результата: %d." % result
		lobby_status_changed.emit()
		return

	_lobby_id = lobby_id
	_lobby_status = "Steam-комната «%s» создана. Ожидаем игроков." % _get_visibility_label(_pending_lobby_visibility)
	var steam_api := _get_steam_api()
	if steam_api != null:
		steam_api.call(&"setLobbyData", _lobby_id, "project", "project_joker")
		steam_api.call(&"setLobbyData", _lobby_id, "protocol", str(LOBBY_PROTOCOL_VERSION))
		steam_api.call(&"setLobbyData", _lobby_id, "mode", _pending_match_mode)
		steam_api.call(&"setLobbyData", _lobby_id, "state", LOBBY_STATE_WAITING)
		steam_api.call(&"setLobbyData", _lobby_id, "pj_visibility", str(_pending_lobby_visibility))
		steam_api.call(&"setLobbyData", _lobby_id, "host_name", _persona_name.left(40))
		steam_api.call(&"setLobbyData", _lobby_id, "max_seats", str(LOBBY_MEMBER_LIMIT))
		steam_api.call(&"setLobbyData", _lobby_id, "pj_fill_bots", "0")
		steam_api.call(&"setLobbyData", _lobby_id, "pj_bot_difficulty", "1")
		steam_api.call(&"setLobbyData", _lobby_id, "pj_history_mode", "0")
		steam_api.call(&"setLobbyData", _lobby_id, "pj_team_0_name", _pending_team_one_name)
		steam_api.call(&"setLobbyData", _lobby_id, "pj_team_1_name", "Команда 2")
		steam_api.call(&"setLobbyData", _lobby_id, "pj_kicked_ids", "")
		steam_api.call(&"setLobbyMemberData", _lobby_id, "pj_team", "0" if _pending_match_mode == MATCH_MODE_TEAMS_2V2 else "-1")
		steam_api.call(&"setLobbyMemberData", _lobby_id, "pj_team_name", "")
		steam_api.call(&"setLobbyMemberLimit", _lobby_id, LOBBY_MEMBER_LIMIT)
		steam_api.call(&"setLobbyJoinable", _lobby_id, true)
	lobby_status_changed.emit()


func _on_lobby_joined(lobby_id: int, _permissions: int, _locked: bool, response: int) -> void:
	if response != LOBBY_JOIN_RESPONSE_SUCCESS:
		_lobby_status = "Не удалось войти в Steam-комнату. Код ответа: %d." % response
		lobby_status_changed.emit()
		return

	_lobby_id = lobby_id
	_local_lobby_ready = false
	var steam_api := _get_steam_api()
	if steam_api != null and steam_api.has_method(&"getLobbyData"):
		var kicked_ids := _parse_steam_id_list(str(steam_api.call(&"getLobbyData", _lobby_id, "pj_kicked_ids")))
		if kicked_ids.has(get_local_steam_id()):
			steam_api.call(&"leaveLobby", _lobby_id)
			_lobby_id = 0
			_lobby_status = "Хост исключил тебя из этой комнаты."
			lobby_status_changed.emit()
			return
	if steam_api != null and steam_api.has_method(&"setLobbyMemberData"):
		steam_api.call(&"setLobbyMemberData", _lobby_id, "pj_ready", "0")
		var lobby_owner := int(steam_api.call(&"getLobbyOwner", _lobby_id)) if steam_api.has_method(&"getLobbyOwner") else 0
		var match_mode := str(steam_api.call(&"getLobbyData", _lobby_id, "mode")) if steam_api.has_method(&"getLobbyData") else MATCH_MODE_CLASSIC
		steam_api.call(&"setLobbyMemberData", _lobby_id, "pj_team", "0" if match_mode == MATCH_MODE_TEAMS_2V2 and get_local_steam_id() == lobby_owner else "-1")
		steam_api.call(&"setLobbyMemberData", _lobby_id, "pj_team_name", "")
	var joined_from := _pending_join_source
	_pending_join_source = ""
	_lobby_status = "Ты вошёл в Steam-комнату. Отметь готовность, когда все соберутся." if not joined_from.is_empty() else "Ты находишься в Steam-комнате. Ожидаем игроков."
	lobby_status_changed.emit()
	lobby_joined_successfully.emit()


func _on_lobby_chat_update(lobby_id: int, _changed_id: int, _making_change_id: int, _chat_state: int) -> void:
	if lobby_id == _lobby_id:
		_lobby_status = "Состав Steam-комнаты обновлён."
		lobby_status_changed.emit()


func _on_lobby_data_update(success: int, lobby_id: int, _member_id: int) -> void:
	if success == STEAM_RESULT_OK and lobby_id == _lobby_id:
		var steam_api := _get_steam_api()
		if steam_api != null and steam_api.has_method(&"getLobbyData"):
			var kicked_ids := _parse_steam_id_list(str(steam_api.call(&"getLobbyData", _lobby_id, "pj_kicked_ids")))
			if kicked_ids.has(get_local_steam_id()):
				steam_api.call(&"leaveLobby", _lobby_id)
				_lobby_id = 0
				_local_lobby_ready = false
				_lobby_status = "Хост исключил тебя из комнаты."
				lobby_status_changed.emit()
				return
		lobby_status_changed.emit()
	if _requested_summary_lobby_ids.has(lobby_id) and success != STEAM_RESULT_OK:
		_requested_summary_lobby_ids.erase(lobby_id)
		_unavailable_lobby_ids[lobby_id] = true
		lobby_browser_updated.emit()
	elif success == STEAM_RESULT_OK and (
		_friend_lobby_ids.has(lobby_id)
		or _known_public_lobby_ids.has(lobby_id)
		or _requested_summary_lobby_ids.has(lobby_id)
	):
		_requested_summary_lobby_ids.erase(lobby_id)
		_unavailable_lobby_ids.erase(lobby_id)
		_rebuild_browser_lobbies()
		lobby_browser_updated.emit()


func _on_lobby_match_list(lobbies: Array) -> void:
	_known_public_lobby_ids.clear()
	for lobby_id_variant in lobbies:
		var lobby_id := int(lobby_id_variant)
		if lobby_id > 0:
			_known_public_lobby_ids[lobby_id] = true
	_rebuild_browser_lobbies()
	_lobby_browser_status = "Открытых комнат найдено: %d. Комнат друзей: %d." % [
		_public_lobbies.size(),
		_friend_lobbies.size(),
	]
	lobby_browser_updated.emit()


func _on_lobby_invite(inviter_id: int, _lobby_id_from_invite: int, _game_id: int) -> void:
	var inviter_name := _get_persona_name(inviter_id)
	_lobby_status = "%s пригласил тебя в Steam-комнату. Прими приглашение в Steam." % inviter_name
	lobby_status_changed.emit()


func _on_join_requested(lobby_id: int, _inviter_id: int) -> void:
	join_lobby(lobby_id, "приглашению Steam")


func _on_p2p_session_request(remote_steam_id: int) -> void:
	var steam_api := _get_steam_api()
	if steam_api == null:
		return
	if is_current_lobby_member(remote_steam_id) and steam_api.has_method(&"acceptP2PSessionWithUser"):
		steam_api.call(&"acceptP2PSessionWithUser", remote_steam_id)


func _on_p2p_session_connect_fail(remote_steam_id: int, error_code: int) -> void:
	if is_current_lobby_member(remote_steam_id):
		_lobby_status = "Не удалось установить Steam P2P-связь с %s. Код: %d." % [_get_persona_name(remote_steam_id), error_code]
		lobby_status_changed.emit()


func _get_lobby_members(steam_api: Object, member_count: int, lobby_owner: int) -> Array[Dictionary]:
	var members: Array[Dictionary] = []
	if not steam_api.has_method(&"getLobbyMemberByIndex"):
		return members

	for member_index in range(member_count):
		var member_id := int(steam_api.call(&"getLobbyMemberByIndex", _lobby_id, member_index))
		var is_ready := false
		var team_id := -1
		var team_name_request := ""
		if steam_api.has_method(&"getLobbyMemberData"):
			is_ready = str(steam_api.call(&"getLobbyMemberData", _lobby_id, member_id, "pj_ready")) == "1"
			team_id = int(str(steam_api.call(&"getLobbyMemberData", _lobby_id, member_id, "pj_team")))
			team_name_request = str(steam_api.call(&"getLobbyMemberData", _lobby_id, member_id, "pj_team_name"))
		members.append({
			"steam_id": member_id,
			"name": _get_persona_name(member_id),
			"ready": is_ready,
			"is_owner": member_id == lobby_owner,
			"team_id": team_id,
			"team_name_request": team_name_request,
		})

	return members


func _get_persona_name(steam_id: int) -> String:
	var steam_api := _get_steam_api()
	if steam_api != null and steam_api.has_method(&"getFriendPersonaName"):
		var persona_name := str(steam_api.call(&"getFriendPersonaName", steam_id))
		if not persona_name.is_empty():
			return persona_name
	return "Игрок %d" % steam_id


func _collect_friend_lobby_ids(steam_api: Object) -> void:
	_friend_lobby_ids.clear()
	if (
		not steam_api.has_method(&"getFriendCount")
		or not steam_api.has_method(&"getFriendByIndex")
		or not steam_api.has_method(&"getFriendGamePlayed")
	):
		_friend_lobbies.clear()
		return

	var friend_count := int(steam_api.call(&"getFriendCount", FRIEND_FLAG_IMMEDIATE))
	for friend_index in friend_count:
		var friend_steam_id := int(steam_api.call(&"getFriendByIndex", friend_index, FRIEND_FLAG_IMMEDIATE))
		if friend_steam_id <= 0:
			continue
		var game_info_variant: Variant = steam_api.call(&"getFriendGamePlayed", friend_steam_id)
		if not (game_info_variant is Dictionary):
			continue
		var game_info: Dictionary = game_info_variant
		var friend_lobby_id := _extract_friend_lobby_id(game_info)
		if friend_lobby_id <= 0:
			continue
		_friend_lobby_ids[friend_lobby_id] = _get_persona_name(friend_steam_id)
		if steam_api.has_method(&"requestLobbyData"):
			steam_api.call(&"requestLobbyData", friend_lobby_id)
	_rebuild_browser_lobbies()


func _extract_friend_lobby_id(game_info: Dictionary) -> int:
	for key in ["lobby", "lobby_id", "steam_id_lobby", "steamIDLobby"]:
		if game_info.has(key):
			var lobby_id := int(game_info.get(key, 0))
			if lobby_id > 0:
				return lobby_id
	return 0


func _rebuild_browser_lobbies() -> void:
	_public_lobbies.clear()
	for lobby_id_variant in _known_public_lobby_ids.keys():
		var summary := _create_lobby_summary(int(lobby_id_variant))
		if not summary.is_empty() and str(summary.get("match_state", "")) == LOBBY_STATE_WAITING:
			_public_lobbies.append(summary)

	_friend_lobbies.clear()
	for lobby_id_variant in _friend_lobby_ids.keys():
		var lobby_id := int(lobby_id_variant)
		var summary := _create_lobby_summary(lobby_id)
		if summary.is_empty():
			continue
		summary["friend_name"] = str(_friend_lobby_ids[lobby_id])
		_friend_lobbies.append(summary)
	_sort_lobby_summaries(_public_lobbies)
	_sort_lobby_summaries(_friend_lobbies)


func _sort_lobby_summaries(lobbies: Array[Dictionary]) -> void:
	lobbies.sort_custom(
		func(first: Dictionary, second: Dictionary) -> bool:
			var first_count := int(first.get("member_count", 0))
			var second_count := int(second.get("member_count", 0))
			if first_count != second_count:
				return first_count > second_count
			return int(first.get("lobby_id", 0)) < int(second.get("lobby_id", 0))
	)


func _create_lobby_summary(lobby_id: int) -> Dictionary:
	var steam_api := _get_steam_api()
	if not _initialized or lobby_id <= 0 or steam_api == null or not steam_api.has_method(&"getLobbyData"):
		return {}
	var project_name := str(steam_api.call(&"getLobbyData", lobby_id, "project"))
	var protocol := int(steam_api.call(&"getLobbyData", lobby_id, "protocol"))
	if project_name != "project_joker" or protocol != LOBBY_PROTOCOL_VERSION:
		return {}

	var member_count := int(steam_api.call(&"getNumLobbyMembers", lobby_id)) if steam_api.has_method(&"getNumLobbyMembers") else 0
	var member_limit := int(steam_api.call(&"getLobbyMemberLimit", lobby_id)) if steam_api.has_method(&"getLobbyMemberLimit") else LOBBY_MEMBER_LIMIT
	var visibility := clampi(
		int(steam_api.call(&"getLobbyData", lobby_id, "pj_visibility")),
		LobbyVisibility.PRIVATE,
		LobbyVisibility.PUBLIC
	)
	var match_state := str(steam_api.call(&"getLobbyData", lobby_id, "state"))
	if match_state.is_empty():
		match_state = LOBBY_STATE_WAITING
	return {
		"lobby_id": lobby_id,
		"host_name": str(steam_api.call(&"getLobbyData", lobby_id, "host_name")),
		"member_count": member_count,
		"member_limit": member_limit if member_limit > 0 else LOBBY_MEMBER_LIMIT,
		"visibility": visibility,
		"visibility_label": _get_visibility_label(visibility),
		"match_state": match_state,
		"fill_empty_seats_with_bots": str(steam_api.call(&"getLobbyData", lobby_id, "pj_fill_bots")) == "1",
		"bot_difficulty": clampi(int(steam_api.call(&"getLobbyData", lobby_id, "pj_bot_difficulty")), 0, 2),
		"history_mode": clampi(int(steam_api.call(&"getLobbyData", lobby_id, "pj_history_mode")), 0, 1),
		"match_mode": str(steam_api.call(&"getLobbyData", lobby_id, "mode")),
		"protocol": protocol,
	}


func _sanitize_team_name(team_name: String, fallback: String) -> String:
	var safe_name := team_name.replace("\n", " ").replace("\r", " ").strip_edges().left(24)
	return fallback if safe_name.is_empty() else safe_name


func _parse_steam_id_list(serialized_ids: String) -> Dictionary:
	var result := {}
	for id_text in serialized_ids.split(",", false):
		var steam_id := int(id_text)
		if steam_id > 0:
			result[steam_id] = true
	return result


func _get_steam_lobby_type(visibility: int) -> int:
	match visibility:
		LobbyVisibility.PRIVATE:
			return LOBBY_TYPE_PRIVATE
		LobbyVisibility.PUBLIC:
			return LOBBY_TYPE_PUBLIC
	return LOBBY_TYPE_FRIENDS_ONLY


func _get_visibility_label(visibility: int) -> String:
	match visibility:
		LobbyVisibility.PRIVATE:
			return "по приглашению"
		LobbyVisibility.PUBLIC:
			return "открытая"
	return "только для друзей"


func _get_launch_lobby_id() -> int:
	var argument_lists := [OS.get_cmdline_user_args(), OS.get_cmdline_args()]
	for argument_list_variant in argument_lists:
		var argument_list: PackedStringArray = argument_list_variant
		var lobby_argument_index := argument_list.find("+connect_lobby")
		if lobby_argument_index >= 0 and lobby_argument_index + 1 < argument_list.size():
			var lobby_id := int(argument_list[lobby_argument_index + 1])
			if lobby_id > 0:
				return lobby_id
	return 0


func _get_app_id_file_paths() -> PackedStringArray:
	var executable_directory := OS.get_executable_path().get_base_dir()
	return PackedStringArray([
		"res://steam_appid.txt",
		executable_directory.path_join("steam_appid.txt")
	])
