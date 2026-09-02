extends SceneTree

const RemoteMatch = preload("res://Scripts/core/RemoteEnetMatch.gd")
var client
var created := false
var deadline_msec := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	client = RemoteMatch.new()
	root.add_child(client)
	client.directory_changed.connect(_on_directory_changed)
	client.room_joined.connect(_on_room_joined)
	deadline_msec = Time.get_ticks_msec() + 180000
	assert(client.start_client("130.61.155.173", 8765, "ПК-хост", "", 0))
	while Time.get_ticks_msec() < deadline_msec:
		await process_frame
	client.stop()
	print("REMOTE_LIVE_HOST_DONE")
	quit()


func _on_directory_changed() -> void:
	if created or not client.is_directory_connected():
		return
	created = client.create_lobby("ПК-комната · тест", false, "")


func _on_room_joined() -> void:
	print("REMOTE_LIVE_ROOM_READY id=%d" % client.current_room_id)
