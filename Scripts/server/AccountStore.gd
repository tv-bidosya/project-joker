class_name AccountStore

extends RefCounted


const FORMAT_VERSION := 1
const DEFAULT_STORAGE_PATH := "user://server_accounts.json"
const MAX_DISPLAY_NAME_LENGTH := 20
const MAX_DEVICE_TOKENS := 8

var storage_path := DEFAULT_STORAGE_PATH
var last_error := ""
var _accounts: Dictionary = {}
var _account_id_by_device_token_hash: Dictionary = {}


func open(path: String = DEFAULT_STORAGE_PATH) -> Error:
	storage_path = path.strip_edges() if not path.strip_edges().is_empty() else DEFAULT_STORAGE_PATH
	_accounts.clear()
	_account_id_by_device_token_hash.clear()
	last_error = ""
	var absolute_directory := ProjectSettings.globalize_path(storage_path).get_base_dir()
	var directory_error := DirAccess.make_dir_recursive_absolute(absolute_directory)
	if directory_error != OK and directory_error != ERR_ALREADY_EXISTS:
		last_error = "account_directory_unavailable"
		return directory_error
	if not FileAccess.file_exists(storage_path):
		return _save()
	var database_file := FileAccess.open(storage_path, FileAccess.READ)
	if database_file == null:
		last_error = "account_database_unreadable"
		return FileAccess.get_open_error()
	var parsed: Variant = JSON.parse_string(database_file.get_as_text())
	if not (parsed is Dictionary):
		last_error = "account_database_invalid_json"
		return ERR_PARSE_ERROR
	var root: Dictionary = parsed
	if int(root.get("version", 0)) != FORMAT_VERSION or not (root.get("accounts", {}) is Dictionary):
		last_error = "account_database_unsupported"
		return ERR_FILE_UNRECOGNIZED
	for account_id_variant in (root.get("accounts", {}) as Dictionary).keys():
		var account_id := _normalize_account_id(str(account_id_variant))
		var account_variant: Variant = (root.get("accounts", {}) as Dictionary)[account_id_variant]
		if account_id.is_empty() or not (account_variant is Dictionary):
			continue
		var account := _sanitize_loaded_account(account_id, account_variant)
		_accounts[account_id] = account
		_index_device_tokens(account_id, account)
	return OK


func get_account_count() -> int:
	return _accounts.size()


func create_account(display_name: String, avatar_index: int = 0) -> Dictionary:
	var device_token := Crypto.new().generate_random_bytes(32).hex_encode()
	var recovery_code := Crypto.new().generate_random_bytes(16).hex_encode().to_upper()
	var result := create_account_from_verifiers(display_name, avatar_index, device_token.sha256_text(), recovery_code.sha256_text())
	if not bool(result.get("ok", false)):
		return result
	result["device_token"] = device_token
	result["recovery_code"] = _format_recovery_code(recovery_code)
	return result


func create_account_from_verifiers(display_name: String, avatar_index: int, device_token_hash: String, recovery_code_hash: String) -> Dictionary:
	var clean_token_hash := _sanitize_sha256(device_token_hash)
	var clean_recovery_hash := _sanitize_sha256(recovery_code_hash)
	if clean_token_hash.is_empty() or clean_recovery_hash.is_empty():
		return {"ok": false, "error": "invalid_account_verifier"}
	var account_id := _create_unique_account_id()
	var account := {
		"account_id": account_id,
		"display_name": _sanitize_display_name(display_name),
		"avatar_index": maxi(0, avatar_index),
		"xp": 0,
		"completed_matches": 0,
		"created_unix": int(Time.get_unix_time_from_system()),
		"recovery_code_hash": clean_recovery_hash,
		"device_token_hashes": [clean_token_hash]
	}
	_accounts[account_id] = account
	_account_id_by_device_token_hash[clean_token_hash] = account_id
	var save_error := _save()
	if save_error != OK:
		_accounts.erase(account_id)
		_account_id_by_device_token_hash.erase(clean_token_hash)
		return {"ok": false, "error": last_error}
	return {"ok": true, "account": _create_public_account(account)}


func authenticate_device_token(device_token: String) -> Dictionary:
	var clean_token := device_token.strip_edges().to_lower()
	if clean_token.length() != 64:
		return {"ok": false, "error": "invalid_device_token"}
	var account_id := str(_account_id_by_device_token_hash.get(clean_token.sha256_text(), ""))
	if account_id.is_empty() or not _accounts.has(account_id):
		return {"ok": false, "error": "invalid_device_token"}
	return {"ok": true, "account": _create_public_account(_accounts[account_id])}


func authenticate_device_proof(account_id: String, challenge: String, proof: String) -> Dictionary:
	var normalized_id := _normalize_account_id(account_id)
	if normalized_id.is_empty() or challenge.is_empty() or not _accounts.has(normalized_id):
		return {"ok": false, "error": "invalid_device_token"}
	var account: Dictionary = _accounts[normalized_id]
	for token_hash_variant in account.get("device_token_hashes", []):
		if _create_proof(str(token_hash_variant), challenge) == proof.to_lower():
			return {"ok": true, "account": _create_public_account(account)}
	return {"ok": false, "error": "invalid_device_token"}


func recover_account(account_id: String, recovery_code: String) -> Dictionary:
	var normalized_id := _normalize_account_id(account_id)
	var normalized_code := _normalize_recovery_code(recovery_code)
	if normalized_id.is_empty() or normalized_code.length() != 32 or not _accounts.has(normalized_id):
		return {"ok": false, "error": "invalid_recovery_credentials"}
	var account: Dictionary = _accounts[normalized_id]
	if normalized_code.sha256_text() != str(account.get("recovery_code_hash", "")):
		return {"ok": false, "error": "invalid_recovery_credentials"}
	var device_token := Crypto.new().generate_random_bytes(32).hex_encode()
	var token_hash := device_token.sha256_text()
	var token_hashes: Array = (account.get("device_token_hashes", []) as Array).duplicate()
	token_hashes.append(token_hash)
	while token_hashes.size() > MAX_DEVICE_TOKENS:
		var removed_hash := str(token_hashes.pop_front())
		_account_id_by_device_token_hash.erase(removed_hash)
	account["device_token_hashes"] = token_hashes
	_account_id_by_device_token_hash[token_hash] = normalized_id
	if _save() != OK:
		return {"ok": false, "error": last_error}
	return {"ok": true, "account": _create_public_account(account), "device_token": device_token}


func recover_account_with_proof(account_id: String, challenge: String, recovery_proof: String, new_device_token_hash: String) -> Dictionary:
	var normalized_id := _normalize_account_id(account_id)
	var clean_token_hash := _sanitize_sha256(new_device_token_hash)
	if normalized_id.is_empty() or challenge.is_empty() or clean_token_hash.is_empty() or not _accounts.has(normalized_id):
		return {"ok": false, "error": "invalid_recovery_credentials"}
	var account: Dictionary = _accounts[normalized_id]
	if _create_proof(str(account.get("recovery_code_hash", "")), challenge) != recovery_proof.to_lower():
		return {"ok": false, "error": "invalid_recovery_credentials"}
	var token_hashes: Array = (account.get("device_token_hashes", []) as Array).duplicate()
	if not token_hashes.has(clean_token_hash):
		token_hashes.append(clean_token_hash)
	while token_hashes.size() > MAX_DEVICE_TOKENS:
		var removed_hash := str(token_hashes.pop_front())
		_account_id_by_device_token_hash.erase(removed_hash)
	account["device_token_hashes"] = token_hashes
	_account_id_by_device_token_hash[clean_token_hash] = normalized_id
	if _save() != OK:
		return {"ok": false, "error": last_error}
	return {"ok": true, "account": _create_public_account(account)}


func update_profile(account_id: String, display_name: String, avatar_index: int) -> Dictionary:
	var normalized_id := _normalize_account_id(account_id)
	if not _accounts.has(normalized_id):
		return {"ok": false, "error": "account_not_found"}
	var account: Dictionary = _accounts[normalized_id]
	account["display_name"] = _sanitize_display_name(display_name)
	account["avatar_index"] = maxi(0, avatar_index)
	if _save() != OK:
		return {"ok": false, "error": last_error}
	return {"ok": true, "account": _create_public_account(account)}


func rotate_recovery_code(account_id: String) -> Dictionary:
	var normalized_id := _normalize_account_id(account_id)
	if not _accounts.has(normalized_id):
		return {"ok": false, "error": "account_not_found"}
	var recovery_code := Crypto.new().generate_random_bytes(16).hex_encode().to_upper()
	var account: Dictionary = _accounts[normalized_id]
	account["recovery_code_hash"] = recovery_code.sha256_text()
	if _save() != OK:
		return {"ok": false, "error": last_error}
	return {
		"ok": true,
		"account": _create_public_account(account),
		"recovery_code": _format_recovery_code(recovery_code)
	}


func set_recovery_code_hash(account_id: String, recovery_code_hash: String) -> Dictionary:
	var normalized_id := _normalize_account_id(account_id)
	var clean_recovery_hash := _sanitize_sha256(recovery_code_hash)
	if not _accounts.has(normalized_id) or clean_recovery_hash.is_empty():
		return {"ok": false, "error": "invalid_account_verifier"}
	var account: Dictionary = _accounts[normalized_id]
	account["recovery_code_hash"] = clean_recovery_hash
	if _save() != OK:
		return {"ok": false, "error": last_error}
	return {"ok": true, "account": _create_public_account(account)}


func get_public_account(account_id: String) -> Dictionary:
	var normalized_id := _normalize_account_id(account_id)
	if not _accounts.has(normalized_id):
		return {}
	return _create_public_account(_accounts[normalized_id])


func _sanitize_loaded_account(account_id: String, source: Dictionary) -> Dictionary:
	var token_hashes: Array[String] = []
	for token_hash_variant in source.get("device_token_hashes", []):
		var token_hash := str(token_hash_variant).strip_edges().to_lower()
		if token_hash.length() == 64 and not token_hashes.has(token_hash):
			token_hashes.append(token_hash)
	return {
		"account_id": account_id,
		"display_name": _sanitize_display_name(str(source.get("display_name", "Игрок"))),
		"avatar_index": maxi(0, int(source.get("avatar_index", 0))),
		"xp": maxi(0, int(source.get("xp", 0))),
		"completed_matches": maxi(0, int(source.get("completed_matches", 0))),
		"created_unix": maxi(0, int(source.get("created_unix", 0))),
		"recovery_code_hash": str(source.get("recovery_code_hash", "")),
		"device_token_hashes": token_hashes
	}


func _create_public_account(account: Dictionary) -> Dictionary:
	return {
		"account_id": str(account.get("account_id", "")),
		"display_name": str(account.get("display_name", "Игрок")),
		"avatar_index": int(account.get("avatar_index", 0)),
		"xp": int(account.get("xp", 0)),
		"completed_matches": int(account.get("completed_matches", 0)),
		"created_unix": int(account.get("created_unix", 0))
	}


func _index_device_tokens(account_id: String, account: Dictionary) -> void:
	for token_hash_variant in account.get("device_token_hashes", []):
		_account_id_by_device_token_hash[str(token_hash_variant)] = account_id


func _create_unique_account_id() -> String:
	while true:
		var candidate := "PJ-%s" % Crypto.new().generate_random_bytes(8).hex_encode().to_upper()
		if not _accounts.has(candidate):
			return candidate
	return ""


func _sanitize_display_name(value: String) -> String:
	var clean_name := value.replace("\n", " ").replace("\r", " ").strip_edges().left(MAX_DISPLAY_NAME_LENGTH)
	return clean_name if not clean_name.is_empty() else "Игрок"


func _normalize_account_id(value: String) -> String:
	var normalized := value.replace(" ", "").strip_edges().to_upper()
	if normalized.length() != 19 or not normalized.begins_with("PJ-"):
		return ""
	for character in normalized.trim_prefix("PJ-"):
		if character not in "0123456789ABCDEF":
			return ""
	return normalized


func _normalize_recovery_code(value: String) -> String:
	return value.replace("-", "").replace(" ", "").strip_edges().to_upper()


func _sanitize_sha256(value: String) -> String:
	var clean_value := value.strip_edges().to_lower()
	if clean_value.length() != 64:
		return ""
	for character in clean_value:
		if character not in "0123456789abcdef":
			return ""
	return clean_value


func _create_proof(secret_hash: String, challenge: String) -> String:
	var clean_hash := _sanitize_sha256(secret_hash)
	if clean_hash.is_empty() or challenge.is_empty():
		return ""
	return Crypto.new().hmac_digest(
		HashingContext.HASH_SHA256,
		clean_hash.hex_decode(),
		challenge.to_utf8_buffer()
	).hex_encode()


func _format_recovery_code(value: String) -> String:
	var normalized := _normalize_recovery_code(value)
	var parts: Array[String] = []
	for offset in range(0, normalized.length(), 4):
		parts.append(normalized.substr(offset, 4))
	return "-".join(parts)


func _save() -> Error:
	var temporary_path := storage_path + ".tmp"
	var temporary_file := FileAccess.open(temporary_path, FileAccess.WRITE)
	if temporary_file == null:
		last_error = "account_database_unwritable"
		return FileAccess.get_open_error()
	temporary_file.store_string(JSON.stringify({"version": FORMAT_VERSION, "accounts": _accounts}, "\t"))
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
			last_error = "account_database_backup_failed"
			return backup_error
	var rename_error := DirAccess.rename_absolute(absolute_temporary_path, absolute_path)
	if rename_error != OK:
		if FileAccess.file_exists(backup_path):
			DirAccess.rename_absolute(backup_path, absolute_path)
		last_error = "account_database_replace_failed"
		return rename_error
	last_error = ""
	return OK
