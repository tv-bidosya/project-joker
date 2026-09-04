extends Node

const Server = preload("res://Scripts/server/WebSocketGameServer.gd")

var server


func _ready() -> void:
	server = Server.new()
	var result: int = server.start(_read_port_argument(), "0.0.0.0", _read_account_database_argument(), _read_match_database_argument())
	if result != OK:
		get_tree().quit(result)
		return
	while server.is_running():
		server.poll()
		OS.delay_msec(5)


func _exit_tree() -> void:
	if server != null:
		server.stop()


func _read_port_argument() -> int:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--port="):
			return clampi(int(argument.trim_prefix("--port=")), 1024, 65535)
	return Server.DEFAULT_PORT


func _read_account_database_argument() -> String:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--account-db="):
			return argument.trim_prefix("--account-db=").strip_edges()
	return ""


func _read_match_database_argument() -> String:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--match-db="):
			return argument.trim_prefix("--match-db=").strip_edges()
	return ""
