extends SceneTree


const SteamBridge = preload("res://Scripts/core/SteamBridge.gd")


func _init() -> void:
	var bridge: RefCounted = SteamBridge.new()
	var should_initialize := OS.get_cmdline_user_args().has("--steam-init-probe")
	var diagnostics: Dictionary = bridge.initialize_for_diagnostics() if should_initialize else bridge.get_diagnostics()
	print(JSON.stringify(diagnostics))
	quit()
