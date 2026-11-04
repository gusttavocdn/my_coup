class_name ServerMain
extends Node
## Entry point of the headless match server:
##   godot --headless --path . res://scenes/server.tscn [-- --port=9080 --bind=127.0.0.1]
## The scene root is named "Main" so the GameServer node sits at
## /root/Main/GameServer, the same path as on the client; Godot matches RPCs by
## node path.


func _ready() -> void:
	var server := GameServer.new()
	server.name = "GameServer"
	add_child(server)
	var port: int = _port_from_args()
	var bind_address: String = _bind_address_from_args()
	var error: Error = server.listen(port, null, bind_address)
	if error != OK:
		push_error("Could not listen on port %d (error %d)" % [port, error])
		get_tree().quit(1)
		return
	print("Match server listening on port %d" % port)
	print("Match server bound to %s" % bind_address)


func _port_from_args() -> int:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--port="):
			return int(argument.trim_prefix("--port="))
	return GameServer.DEFAULT_PORT


func _bind_address_from_args() -> String:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--bind="):
			return argument.trim_prefix("--bind=")
	return "*"
