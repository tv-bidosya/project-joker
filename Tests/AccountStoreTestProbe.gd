extends SceneTree

const AccountStoreResource = preload("res://Scripts/server/AccountStore.gd")
const TEST_PATH := "user://account_store_test.json"


func _init() -> void:
	_cleanup_files()
	var store = AccountStoreResource.new()
	assert(store.open(TEST_PATH) == OK)
	assert(store.get_account_count() == 0)

	var created: Dictionary = store.create_account("  Андрей\n", 2)
	assert(bool(created.get("ok", false)))
	var account: Dictionary = created.get("account", {})
	var account_id := str(account.get("account_id", ""))
	var device_token := str(created.get("device_token", ""))
	var recovery_code := str(created.get("recovery_code", ""))
	assert(account_id.begins_with("PJ-") and account_id.length() == 19)
	assert(device_token.length() == 64)
	assert(recovery_code.length() == 39)
	assert(str(account.get("display_name", "")) == "Андрей")
	assert(int(account.get("avatar_index", -1)) == 2)
	assert(not bool(store.authenticate_device_token("wrong").get("ok", false)))
	assert(bool(store.authenticate_device_token(device_token).get("ok", false)))
	var challenge := "test-login-challenge"
	var device_proof := Crypto.new().hmac_digest(
		HashingContext.HASH_SHA256,
		device_token.sha256_text().hex_decode(),
		challenge.to_utf8_buffer()
	).hex_encode()
	assert(bool(store.authenticate_device_proof(account_id, challenge, device_proof).get("ok", false)))
	assert(not bool(store.authenticate_device_proof(account_id, challenge + "-changed", device_proof).get("ok", false)))

	var restored_store = AccountStoreResource.new()
	assert(restored_store.open(TEST_PATH) == OK)
	assert(restored_store.get_account_count() == 1)
	assert(bool(restored_store.authenticate_device_token(device_token).get("ok", false)))
	assert(not bool(restored_store.recover_account(account_id, "WRONG").get("ok", false)))
	var recovered: Dictionary = restored_store.recover_account(account_id.to_lower(), recovery_code.to_lower())
	assert(bool(recovered.get("ok", false)))
	var recovered_token := str(recovered.get("device_token", ""))
	assert(recovered_token.length() == 64 and recovered_token != device_token)
	assert(bool(restored_store.authenticate_device_token(recovered_token).get("ok", false)))

	var updated: Dictionary = restored_store.update_profile(account_id, "Новое имя", 3)
	assert(bool(updated.get("ok", false)))
	assert(str((updated.get("account", {}) as Dictionary).get("display_name", "")) == "Новое имя")
	var xp_grant: Dictionary = restored_store.grant_match_xp(account_id, "match-test-1", 150)
	assert(bool(xp_grant.get("ok", false)) and bool(xp_grant.get("awarded", false)))
	assert(int((xp_grant.get("account", {}) as Dictionary).get("xp", 0)) == 150)
	assert(int((xp_grant.get("account", {}) as Dictionary).get("completed_matches", 0)) == 1)
	var duplicate_xp_grant: Dictionary = restored_store.grant_match_xp(account_id, "match-test-1", 150)
	assert(bool(duplicate_xp_grant.get("ok", false)) and not bool(duplicate_xp_grant.get("awarded", true)))
	assert(int((duplicate_xp_grant.get("account", {}) as Dictionary).get("xp", 0)) == 150)
	var rating_result: Dictionary = restored_store.apply_ranked_match_result(account_id, "ranked-test-1", -24)
	assert(bool(rating_result.get("ok", false)) and bool(rating_result.get("applied", false)))
	assert(int((rating_result.get("account", {}) as Dictionary).get("rating", 0)) == AccountStoreResource.DEFAULT_RATING - 24)
	assert(int((rating_result.get("account", {}) as Dictionary).get("ranked_matches", 0)) == 1)
	var duplicate_rating_result: Dictionary = restored_store.apply_ranked_match_result(account_id, "ranked-test-1", -99)
	assert(bool(duplicate_rating_result.get("ok", false)) and not bool(duplicate_rating_result.get("applied", true)))
	var rotated: Dictionary = restored_store.rotate_recovery_code(account_id)
	assert(bool(rotated.get("ok", false)))
	var rotated_code := str(rotated.get("recovery_code", ""))
	assert(rotated_code.length() == 39 and rotated_code != recovery_code)
	assert(not bool(restored_store.recover_account(account_id, recovery_code).get("ok", false)))
	assert(bool(restored_store.recover_account(account_id, rotated_code).get("ok", false)))
	var xp_restored_store = AccountStoreResource.new()
	assert(xp_restored_store.open(TEST_PATH) == OK)
	var persisted_account: Dictionary = xp_restored_store.get_public_account(account_id)
	assert(int(persisted_account.get("xp", 0)) == 150 and int(persisted_account.get("completed_matches", 0)) == 1)
	assert(int(persisted_account.get("rating", 0)) == AccountStoreResource.DEFAULT_RATING - 24 and int(persisted_account.get("ranked_matches", 0)) == 1)
	assert(not bool(xp_restored_store.grant_match_xp(account_id, "match-test-1", 999).get("awarded", true)))
	var database_file := FileAccess.open(TEST_PATH, FileAccess.READ)
	assert(database_file != null)
	var serialized := database_file.get_as_text()
	assert(device_token not in serialized)
	assert(recovered_token not in serialized)
	assert(recovery_code.replace("-", "") not in serialized)
	assert(rotated_code.replace("-", "") not in serialized)
	print("ACCOUNT_STORE_TEST_PASS")
	_cleanup_files()
	quit()


func _cleanup_files() -> void:
	for suffix in ["", ".tmp", ".bak"]:
		var path: String = TEST_PATH + str(suffix)
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
