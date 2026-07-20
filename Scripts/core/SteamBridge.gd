class_name SteamBridge
extends RefCounted


const STEAM_SINGLETON_NAME := &"Steam"


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
	}

	if not steam_runtime_available:
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


func _get_app_id_file_paths() -> PackedStringArray:
	var executable_directory := OS.get_executable_path().get_base_dir()
	return PackedStringArray([
		"res://steam_appid.txt",
		executable_directory.path_join("steam_appid.txt")
	])
