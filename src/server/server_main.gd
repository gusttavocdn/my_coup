class_name ServerMain
extends Node
## Entry point of the headless match server:
##   godot --headless --path . res://scenes/server.tscn [-- --port=9080]
## The scene root is named "Main" so the GameServer node sits at
## /root/Main/GameServer, the same path as on the client; Godot matches RPCs by
## node path.


func _ready() -> void:
	var server := GameServer.new()
	server.name = "GameServer"
	add_child(server)
	var port: int = _port_from_args()
	var error: Error = server.listen(port)
	if error != OK:
		push_error("Could not listen on port %d (error %d)" % [port, error])
		get_tree().quit(1)
		return
	print("Match server listening on port %d" % port)


func _port_from_args() -> int:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--port="):
			return int(argument.trim_prefix("--port="))
	return GameServer.DEFAULT_PORT
