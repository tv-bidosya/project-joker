class_name SteamBridge
extends RefCounted


signal lobby_status_changed


const STEAM_SINGLETON_NAME := &"Steam"
const TEST_APP_ID := 480
const LOBBY_TYPE_FRIENDS_ONLY := 1
const LOBBY_MEMBER_LIMIT := 4
const STEAM_RESULT_OK := 1
const LOBBY_JOIN_RESPONSE_SUCCESS := 1


var _initialization_attempted := false
var _initialized := false
var _initialization_status := -1
var _initialization_verbal := ""
var _persona_name := ""
var _active_app_id := 0
var _lobby_callbacks_connected := false
var _lobby_id := 0
var _lobby_status := "Steam-комната ещё не создана."


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


func leave_lobby() -> Dictionary:
	if _lobby_id <= 0:
		_lobby_status = "Активной Steam-комнаты нет."
		lobby_status_changed.emit()
		return get_lobby_state()

	var steam_api := _get_steam_api()
	if steam_api != null and steam_api.has_method(&"leaveLobby"):
		steam_api.call(&"leaveLobby", _lobby_id)
	_lobby_id = 0
	_lobby_status = "Ты вышел из тестовой Steam-комнаты."
	lobby_status_changed.emit()
	return get_lobby_state()


func get_lobby_state() -> Dictionary:
	var member_count := 0
	var member_limit := LOBBY_MEMBER_LIMIT
	var lobby_owner := 0
	var steam_api := _get_steam_api()
	if _lobby_id > 0 and steam_api != null:
		if steam_api.has_method(&"getNumLobbyMembers"):
			member_count = int(steam_api.call(&"getNumLobbyMembers", _lobby_id))
		if steam_api.has_method(&"getLobbyMemberLimit"):
			member_limit = int(steam_api.call(&"getLobbyMemberLimit", _lobby_id))
		if steam_api.has_method(&"getLobbyOwner"):
			lobby_owner = int(steam_api.call(&"getLobbyOwner", _lobby_id))

	return {
		"initialized": _initialized,
		"lobby_id": _lobby_id,
		"status": _lobby_status,
		"member_count": member_count,
		"member_limit": member_limit,
		"lobby_owner": lobby_owner,
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

	if _lobby_id == 0:
		_lobby_id = lobby_id
	_lobby_status = "Ты находишься в Steam-комнате. Ожидаем игроков."
	lobby_status_changed.emit()


func _on_lobby_chat_update(lobby_id: int, _changed_id: int, _making_change_id: int, _chat_state: int) -> void:
	if lobby_id == _lobby_id:
		_lobby_status = "Состав Steam-комнаты обновлён."
		lobby_status_changed.emit()


func _on_lobby_data_update(success: int, lobby_id: int, _member_id: int) -> void:
	if success == STEAM_RESULT_OK and lobby_id == _lobby_id:
		lobby_status_changed.emit()


func _get_app_id_file_paths() -> PackedStringArray:
	var executable_directory := OS.get_executable_path().get_base_dir()
	return PackedStringArray([
		"res://steam_appid.txt",
		executable_directory.path_join("steam_appid.txt")
	])
