extends SceneTree


const SteamBridge = preload("res://Scripts/core/SteamBridge.gd")


var lobby_probe_bridge: RefCounted
var lobby_probe_elapsed := 0.0
var lobby_probe_ready_sent := false


func _init() -> void:
	var bridge: RefCounted = SteamBridge.new()
	if OS.get_cmdline_user_args().has("--steam-create-lobby-probe"):
		lobby_probe_bridge = bridge
		lobby_probe_bridge.initialize_for_diagnostics()
		lobby_probe_bridge.create_friends_lobby()
		return

	var should_initialize := OS.get_cmdline_user_args().has("--steam-init-probe")
	var diagnostics: Dictionary = bridge.initialize_for_diagnostics() if should_initialize else bridge.get_diagnostics()
	print(JSON.stringify(diagnostics))
	quit()


func _process(delta: float) -> bool:
	if lobby_probe_bridge == null:
		return false

	lobby_probe_elapsed += delta
	lobby_probe_bridge.process_callbacks()
	var lobby_state: Dictionary = lobby_probe_bridge.get_lobby_state()
	if int(lobby_state.get("lobby_id", 0)) > 0:
		if not lobby_probe_ready_sent:
			lobby_probe_bridge.set_local_lobby_ready(true)
			lobby_probe_ready_sent = true
			return false
		if _has_ready_lobby_member(lobby_state):
			print(JSON.stringify(lobby_state))
			lobby_probe_bridge.leave_lobby()
			quit()
			return true
	if lobby_probe_elapsed >= 8.0:
		print(JSON.stringify(lobby_state))
		quit()
		return true
	return false


func _has_ready_lobby_member(lobby_state: Dictionary) -> bool:
	var members: Array = lobby_state.get("members", [])
	for member_variant in members:
		var member: Dictionary = member_variant
		if bool(member.get("ready", false)):
			return true
	return false
