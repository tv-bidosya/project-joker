extends SceneTree

const ServerProtocolVersion := 3
var client: ENetMultiplayerPeer
var deadline_msec := 0
var ping_sent := false
var directory_sent := false
var pong_received := false


func _init() -> void:
	client = ENetMultiplayerPeer.new()
	var result := client.create_client(_read_host_argument(), _read_port_argument())
	if result != OK:
		push_error("REMOTE_ENET_CONNECT_START_FAILED %s" % error_string(result))
		quit(1)
		return
	deadline_msec = Time.get_ticks_msec() + 8000
	process_frame.connect(_poll)


func _poll() -> void:
	client.poll()
	if Time.get_ticks_msec() >= deadline_msec:
		push_error("REMOTE_ENET_SMOKE_TIMEOUT")
		client.close()
		quit(1)
		return
	if client.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED:
		push_error("REMOTE_ENET_DISCONNECTED")
		quit(1)
		return
	if client.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED and not ping_sent:
		_send({"type": "ping"})
		ping_sent = true
	while client.get_available_packet_count() > 0:
		var parsed: Variant = JSON.parse_string(client.get_packet().get_string_from_utf8())
		if not (parsed is Dictionary):
			continue
		var message: Dictionary = parsed
		match str(message.get("type", "")):
			"pong":
				pong_received = true
				if not directory_sent:
					_send({"type": "directory_request", "protocol_version": ServerProtocolVersion})
					directory_sent = true
			"directory_state":
				assert(pong_received)
				assert(int(message.get("protocol_version", -1)) == ServerProtocolVersion)
				assert(message.get("lobbies", []) is Array)
				print("REMOTE_ENET_SMOKE_PASS")
				client.close()
				quit()


func _send(message: Dictionary) -> void:
	client.set_target_peer(1)
	assert(client.put_packet(JSON.stringify(message).to_utf8_buffer()) == OK)
	client.set_target_peer(0)


func _read_host_argument() -> String:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--host="):
			return argument.trim_prefix("--host=")
	return "127.0.0.1"


func _read_port_argument() -> int:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--port="):
			return clampi(int(argument.trim_prefix("--port=")), 1024, 65535)
	return 8765