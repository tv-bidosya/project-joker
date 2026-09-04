class_name MatchStore

extends RefCounted


const FORMAT_VERSION := 1
const DEFAULT_STORAGE_PATH := "user://server_matches.json"
const MAX_COMPLETED_MATCHES := 500

var storage_path := DEFAULT_STORAGE_PATH
var last_error := ""
var _rooms: Array[Dictionary] = []
var _completed_matches: Array[Dictionary] = []


func open(path: String = DEFAULT_STORAGE_PATH) -> Error:
	storage_path = path.strip_edges() if not path.strip_edges().is_empty() else DEFAULT_STORAGE_PATH
	_rooms.clear()
	_completed_matches.clear()
	last_error = ""
	var absolute_directory := ProjectSettings.globalize_path(storage_path).get_base_dir()
	var directory_error := DirAccess.make_dir_recursive_absolute(absolute_directory)
	if directory_error != OK and directory_error != ERR_ALREADY_EXISTS:
		last_error = "match_directory_unavailable"
		return directory_error
	if not FileAccess.file_exists(storage_path):
		return save([], [])
	var database_file := FileAccess.open(storage_path, FileAccess.READ)
	if database_file == null:
		last_error = "match_database_unreadable"
		return FileAccess.get_open_error()
	var parsed: Variant = JSON.parse_string(database_file.get_as_text())
	if not (parsed is Dictionary):
		last_error = "match_database_invalid_json"
		return ERR_PARSE_ERROR
	var root: Dictionary = parsed
	if int(root.get("version", 0)) != FORMAT_VERSION or not (root.get("rooms", []) is Array) or not (root.get("completed_matches", []) is Array):
		last_error = "match_database_unsupported"
		return ERR_FILE_UNRECOGNIZED
	for room_variant in root.get("rooms", []):
		if room_variant is Dictionary:
			_rooms.append((room_variant as Dictionary).duplicate(true))
	for match_variant in root.get("completed_matches", []):
		if match_variant is Dictionary:
			_completed_matches.append((match_variant as Dictionary).duplicate(true))
	while _completed_matches.size() > MAX_COMPLETED_MATCHES:
		_completed_matches.pop_front()
	return OK


func get_rooms() -> Array[Dictionary]:
	return _rooms.duplicate(true)


func get_completed_matches() -> Array[Dictionary]:
	return _completed_matches.duplicate(true)


func save(rooms: Array, completed_matches: Array) -> Error:
	_rooms.clear()
	_completed_matches.clear()
	for room_variant in rooms:
		if room_variant is Dictionary:
			_rooms.append((room_variant as Dictionary).duplicate(true))
	for match_variant in completed_matches:
		if match_variant is Dictionary:
			_completed_matches.append((match_variant as Dictionary).duplicate(true))
	while _completed_matches.size() > MAX_COMPLETED_MATCHES:
		_completed_matches.pop_front()
	var temporary_path := storage_path + ".tmp"
	var temporary_file := FileAccess.open(temporary_path, FileAccess.WRITE)
	if temporary_file == null:
		last_error = "match_database_unwritable"
		return FileAccess.get_open_error()
	temporary_file.store_string(JSON.stringify({
		"version": FORMAT_VERSION,
		"saved_unix": int(Time.get_unix_time_from_system()),
		"rooms": _rooms,
		"completed_matches": _completed_matches
	}, "\t"))
	temporary_file.flush()
	temporary_file = null
	var absolute_path := ProjectSettings.globalize_path(storage_path)
	var absolute_temporary_path := ProjectSettings.globalize_path(temporary_path)
	var backup_path := absolute_path + ".bak"
	if FileAccess.file_exists(backup_path):
		DirAccess.remove_absolute(backup_path)
	if FileAccess.file_exists(absolute_path):
		var backup_error := DirAccess.rename_absolute(absolute_path, backup_path)
		if backup_error != OK:
			last_error = "match_database_backup_failed"
			return backup_error
	var rename_error := DirAccess.rename_absolute(absolute_temporary_path, absolute_path)
	if rename_error != OK:
		if FileAccess.file_exists(backup_path):
			DirAccess.rename_absolute(backup_path, absolute_path)
		last_error = "match_database_replace_failed"
		return rename_error
	last_error = ""
	return OK
