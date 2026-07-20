extends SceneTree


const SteamBridge = preload("res://Scripts/core/SteamBridge.gd")


func _init() -> void:
	var bridge: RefCounted = SteamBridge.new()
	print(JSON.stringify(bridge.get_diagnostics()))
	quit()
