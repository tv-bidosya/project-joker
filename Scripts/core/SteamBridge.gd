class_name SteamBridge
extends RefCounted


const STEAM_SINGLETON_NAME := &"Steam"
const TEST_APP_ID := 480


var _initialization_attempted := false
var _initialized := false
var _initialization_status := -1
var _initialization_verbal := ""
var _persona_name := ""
var _active_app_id := 0


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
		diagnostics["message"] = "Steam-клиент успешно инициализирован для локальной проверки. Лобби и сетевые действия пока не запускаются."
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

	return get_diagnostics()


func _get_steam_api() -> Object:
	if not Engine.has_singleton(STEAM_SINGLETON_NAME):
		return null
	return Engine.get_singleton(STEAM_SINGLETON_NAME)


func _get_app_id_file_paths() -> PackedStringArray:
	var executable_directory := OS.get_executable_path().get_base_dir()
	return PackedStringArray([
		"res://steam_appid.txt",
		executable_directory.path_join("steam_appid.txt")
	])
