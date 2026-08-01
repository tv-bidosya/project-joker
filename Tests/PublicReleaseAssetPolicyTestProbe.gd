extends SceneTree


const PrivateSoundpadManifest = preload("res://Assets/Soundboard/soundpad_manifest.gd")
const PublicSoundpadManifest = preload("res://Assets/PublicSoundboard/public_soundpad_manifest.gd")


func _init() -> void:
	assert(not PrivateSoundpadManifest.PATHS.is_empty(), "Closed friend builds must keep their current soundpad manifest")
	for sound_path in PrivateSoundpadManifest.PATHS:
		assert(sound_path.begins_with("res://Assets/Soundboard/"))
	for sound_path in PublicSoundpadManifest.PATHS:
		assert(sound_path.begins_with("res://Assets/PublicSoundboard/"))
		assert(FileAccess.file_exists(sound_path))
		assert(sound_path not in PrivateSoundpadManifest.PATHS)
	assert(FileAccess.file_exists("res://Docs/PublicReleaseAssetPolicy.md"))
	assert(FileAccess.file_exists("res://Docs/PublicSoundpadSources.md"))
	assert(FileAccess.file_exists("res://THIRD_PARTY_NOTICES.md"))
	print("PUBLIC_RELEASE_ASSET_POLICY_TEST_PASS")
	quit()
