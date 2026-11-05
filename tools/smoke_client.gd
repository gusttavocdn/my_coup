extends SceneTree
## One side of the post-publish smoke check (tools/smoke-check.sh). Connects to the
## match server with the game's own ClientNet, then:
##   --role=host   creates a room, prints "CODE=XXXX", waits for a second player
##   --role=guest  joins the room given by --code=XXXX
## Prints "SMOKE_OK <role>" and exits 0 on success; prints "SMOKE_FAIL <reason>"
## and exits 1 on an error, a refused connection or after the timeout.
##   godot --headless --path . -s res://tools/smoke_client.gd -- --url=wss://host --role=host

## Seconds to wait for the whole exchange before failing.
const TIMEOUT_SECONDS: float = 25.0

var _net: ClientNet
var _role: String = "host"
var _code: String = ""
var _elapsed: float = 0.0
var _done: bool = false
var _started: bool = false
var _url: String = ""


func _initialize() -> void:
	var url: String = ServerAddress.default_url()
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--url="):
			url = argument.trim_prefix("--url=")
		elif argument.begins_with("--role="):
			_role = argument.trim_prefix("--role=")
		elif argument.begins_with("--code="):
			_code = argument.trim_prefix("--code=")
	# Godot matches RPCs by node path: the client node sits at /root/Main/GameServer.
	var main := Node.new()
	main.name = "Main"
	root.add_child(main)
	_net = ClientNet.new()
	_net.name = "GameServer"
	main.add_child(_net)
	_net.connected.connect(_on_connected)
	_net.connection_failed.connect(_finish.bind(false, "connection failed"))
	_net.connection_lost.connect(_finish.bind(false, "connection lost"))
	_net.message_received.connect(_on_message)
	_url = url


func _process(delta: float) -> bool:
	# The node's multiplayer API only exists once the tree has run a frame, so the
	# connection starts here and not in _initialize.
	if not _started:
		_started = true
		var error: Error = _net.connect_to(_url)
		if error != OK:
			_finish(false, "could not start the connection (error %d) to %s" % [error, _url])
	_elapsed += delta
	if not _done and _elapsed >= TIMEOUT_SECONDS:
		_finish(false, "timeout after %d s" % int(TIMEOUT_SECONDS))
	return _done


func _on_connected() -> void:
	if _role == "host":
		_net.send({"type": "create_room", "name": "SmokeHost"})
	else:
		_net.send({"type": "join_room", "code": _code, "name": "SmokeGuest"})


func _on_message(message: Dictionary) -> void:
	if message.get("type") == "error":
		_finish(false, "server error: %s" % message.get("error"))
		return
	if message.get("type") != "room":
		return
	if _role == "host":
		print("CODE=%s" % message.code)
		if message.names.size() >= 2:
			_finish(true, "host saw the guest join")
	elif message.names.size() >= 2:
		_finish(true, "guest joined room %s" % message.code)


func _finish(ok: bool, reason: String) -> void:
	if _done:
		return
	_done = true
	if ok:
		print("SMOKE_OK %s: %s" % [_role, reason])
	else:
		print("SMOKE_FAIL %s: %s" % [_role, reason])
	quit(0 if ok else 1)
