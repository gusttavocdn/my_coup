class_name ServerMain
extends Node
## Entry point of the headless match server:
##   godot --headless --path . res://scenes/server.tscn [-- --port=9080 --bind=127.0.0.1]
## Every option is a ServerConfig field (--max-rooms=50) or its COUP_ environment
## variable (COUP_MAX_ROOMS=50); see docs/running-the-server.md.
## "-- --health" does not start a server: it checks that one answers on the
## configured port on 127.0.0.1 and exits 0 (healthy) or 1.
## The scene root is named "Main" so the GameServer node sits at
## /root/Main/GameServer, the same path as on the client; Godot matches RPCs by
## node path.

## Seconds the --health check waits for the server before reporting failure.
const HEALTH_TIMEOUT_SECONDS: float = 3.0

var _server: GameServer
var _health_probe: WebSocketPeer
var _health_waited: float = 0.0
var _health_port: int = 0


func _ready() -> void:
	var config: ServerConfig = ServerConfig.from_sources(OS.get_cmdline_user_args(), _environment())
	if OS.get_cmdline_user_args().has("--health"):
		_start_health_probe(config)
		return
	_server = GameServer.new()
	_server.name = "GameServer"
	_server.config = config
	add_child(_server)
	var error: Error = _server.listen()
	if error != OK:
		push_error("Could not listen on port %d (error %d)" % [config.port, error])
		get_tree().quit(1)
		return
	print("server_started %s" % config.to_log_line())


## A window close request (for example a console close on Windows) closes the
## connections and quits with 0. SIGTERM is NOT turned into this notification by
## Godot 4.7.2 (verified in a container): it ends the process directly, so the
## Dockerfile runs the server under tini; see docs/running-the-server.md.
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST and _server != null:
		print("server_stopping")
		_server.shutdown()
		get_tree().quit(0)


func _process(delta: float) -> void:
	if _health_probe == null:
		return
	_health_probe.poll()
	if _health_probe.get_ready_state() == WebSocketPeer.STATE_OPEN:
		get_tree().quit(0)
		return
	_health_waited += delta
	if _health_waited >= HEALTH_TIMEOUT_SECONDS or _health_probe.get_ready_state() == WebSocketPeer.STATE_CLOSED:
		push_error("health check failed: no answer on 127.0.0.1:%d" % _health_port)
		get_tree().quit(1)


func _start_health_probe(config: ServerConfig) -> void:
	_health_port = config.port
	_health_probe = WebSocketPeer.new()
	if _health_probe.connect_to_url("ws://127.0.0.1:%d" % config.port) != OK:
		get_tree().quit(1)


func _environment() -> Dictionary:
	var env: Dictionary = {}
	for field: String in ServerConfig.DEFAULTS:
		var name: String = "COUP_%s" % field.to_upper()
		if OS.has_environment(name):
			env[name] = OS.get_environment(name)
	return env
