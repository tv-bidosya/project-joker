class_name SteamBridge
extends RefCounted


signal lobby_status_changed
signal lobby_joined_successfully


const STEAM_SINGLETON_NAME := &"Steam"
const TEST_APP_ID := 480
const LOBBY_TYPE_FRIENDS_ONLY := 1
const LOBBY_MEMBER_LIMIT := 4
const STEAM_RESULT_OK := 1
const LOBBY_JOIN_RESPONSE_SUCCESS := 1
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
	_lobby_status = "Создаём закрытую Steam-комнату на четыре места…"
	steam_api.call(&"createLobby", LOBBY_TYPE_FRIENDS_ONLY, LOBBY_MEMBER_LIMIT)
	lobby_status_changed.emit()
	return get_lobby_state()


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
	_lobby_status = "Ты вышел из тестовой Steam-комнаты."
	lobby_status_changed.emit()
	return get_lobby_state()


func get_lobby_state() -> Dictionary:
	var member_count := 0
	var member_limit := LOBBY_MEMBER_LIMIT
	var lobby_owner := 0
	var members: Array[Dictionary] = []
	var steam_api := _get_steam_api()
	if _lobby_id > 0 and steam_api != null:
		if steam_api.has_method(&"getNumLobbyMembers"):
			member_count = int(steam_api.call(&"getNumLobbyMembers", _lobby_id))
		if steam_api.has_method(&"getLobbyMemberLimit"):
			member_limit = int(steam_api.call(&"getLobbyMemberLimit", _lobby_id))
		if steam_api.has_method(&"getLobbyOwner"):
			lobby_owner = int(steam_api.call(&"getLobbyOwner", _lobby_id))
		members = _get_lobby_members(steam_api, member_count, lobby_owner)

	return {
		"initialized": _initialized,
		"lobby_id": _lobby_id,
		"status": _lobby_status,
		"member_count": member_count,
		"member_limit": member_limit,
		"lobby_owner": lobby_owner,
		"members": members,
		"local_ready": _local_lobby_ready,
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
	_lobby_status = "Закрытая Steam-комната создана. Ожидаем игроков."
	var steam_api := _get_steam_api()
	if steam_api != null:
		steam_api.call(&"setLobbyData", _lobby_id, "project", "project_joker")
		steam_api.call(&"setLobbyData", _lobby_id, "protocol", "1")
		steam_api.call(&"setLobbyData", _lobby_id, "mode", "prototype")
		steam_api.call(&"setLobbyData", _lobby_id, "max_seats", str(LOBBY_MEMBER_LIMIT))
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
	if steam_api != null and steam_api.has_method(&"setLobbyMemberData"):
		steam_api.call(&"setLobbyMemberData", _lobby_id, "pj_ready", "0")
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
		lobby_status_changed.emit()


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
		if steam_api.has_method(&"getLobbyMemberData"):
			is_ready = str(steam_api.call(&"getLobbyMemberData", _lobby_id, member_id, "pj_ready")) == "1"
		members.append({
			"steam_id": member_id,
			"name": _get_persona_name(member_id),
			"ready": is_ready,
			"is_owner": member_id == lobby_owner,
		})

	return members


func _get_persona_name(steam_id: int) -> String:
	var steam_api := _get_steam_api()
	if steam_api != null and steam_api.has_method(&"getFriendPersonaName"):
		var persona_name := str(steam_api.call(&"getFriendPersonaName", steam_id))
		if not persona_name.is_empty():
			return persona_name
	return "Игрок %d" % steam_id


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
