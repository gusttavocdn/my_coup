class_name GameServer
extends Node
## WebSocket front end of the match server. Add it to the scene tree under the
## same node path on the server and on each client (RPCs match by path), call
## listen() on the server, and have clients send intents with send_intent.rpc_id(1, ...).
##
## All game logic lives in RoomRegistry; this node moves messages and applies the
## connection and message limits of ServerConfig. The limit decisions
## (admit_connection, check_message) are pure and take the current time, so they
## are testable without sockets.

const DEFAULT_PORT: int = ServerConfig.DEFAULT_PORT

## WebSocket close codes sent with a refusal (4000-4999 is the private range).
const CLOSE_SERVER_FULL: int = 4001
const CLOSE_TOO_MANY_FROM_IP: int = 4002
const CLOSE_RATE_LIMITED: int = 4003

## Longest piece of player-sent text written to a log line.
const LOG_TEXT_LIMIT: int = 64

var registry: RoomRegistry
var config: ServerConfig = ServerConfig.new()

var _socket: WebSocketMultiplayerPeer
var _ip_of_peer: Dictionary = {}
var _connections_of_ip: Dictionary = {}
## peer -> {"second_start_ms": int, "count": int, "strike_ms": int} (strike_ms -1: none yet)
var _traffic_of_peer: Dictionary = {}


## Starts listening for WebSocket clients on [param port] and [param bind_address]
## (default: the values in [member config]). Returns OK or the engine's Error code.
func listen(port: int = -1, rng: RandomNumberGenerator = null, bind_address: String = "") -> Error:
	var listen_port: int = port if port >= 0 else config.port
	var listen_address: String = bind_address if bind_address != "" else config.bind
	var seeded: RandomNumberGenerator = rng if rng != null else RandomNumberGenerator.new()
	if rng == null:
		seeded.randomize()
	registry = RoomRegistry.new(seeded, Callable(), RulesConfig.RESPONSE_SECONDS, config)
	_socket = WebSocketMultiplayerPeer.new()
	var error: Error = _socket.create_server(listen_port, listen_address)
	if error != OK:
		return error
	multiplayer.multiplayer_peer = _socket
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	return OK


## Closes every connection and the listening socket.
func shutdown() -> void:
	if _socket != null:
		_socket.close()


## Decides whether a new connection is accepted. Returns "" to accept, else the
## close reason ("server_full" or "too_many_connections_from_ip"); an accepted
## peer is counted until release_peer().
func admit_connection(peer: int, ip: String) -> String:
	if _ip_of_peer.size() >= config.max_connections:
		return "server_full"
	if int(_connections_of_ip.get(ip, 0)) >= config.max_connections_per_ip:
		return "too_many_connections_from_ip"
	_ip_of_peer[peer] = ip
	_connections_of_ip[ip] = int(_connections_of_ip.get(ip, 0)) + 1
	_traffic_of_peer[peer] = {"second_start_ms": 0, "count": 0, "strike_ms": -1}
	return ""


## Forgets a peer's connection and message counters.
func release_peer(peer: int) -> void:
	var ip: String = _ip_of_peer.get(peer, "")
	if _ip_of_peer.erase(peer):
		var left: int = int(_connections_of_ip.get(ip, 1)) - 1
		if left <= 0:
			_connections_of_ip.erase(ip)
		else:
			_connections_of_ip[ip] = left
	_traffic_of_peer.erase(peer)


## Checks one incoming intent of [param size_bytes] from [param peer] at [param now_ms].
## Returns {"ok": bool, "error": String, "disconnect": bool}. The first violation
## (too many messages per second, too large, or no "type") gets an error; a second
## one within rate_strike_window_seconds also asks for a disconnect.
func check_message(peer: int, intent: Dictionary, size_bytes: int, now_ms: int) -> Dictionary:
	var traffic: Dictionary = _traffic_of_peer.get(peer, {})
	if traffic.is_empty():
		return {"ok": false, "error": "invalid_intent", "disconnect": true}
	var violation: String = ""
	if now_ms - int(traffic.second_start_ms) >= 1000:
		traffic.second_start_ms = now_ms
		traffic.count = 0
	traffic.count = int(traffic.count) + 1
	if int(traffic.count) > config.max_messages_per_second:
		violation = "rate_limited"
	elif size_bytes > config.max_message_bytes:
		violation = "message_too_large"
	elif not intent.get("type") is String:
		violation = "invalid_intent"
	if violation == "":
		return {"ok": true, "error": "", "disconnect": false}
	var previous: int = int(traffic.strike_ms)
	var repeat: bool = previous != -1 and now_ms - previous < config.rate_strike_window_seconds * 1000
	traffic.strike_ms = now_ms
	return {"ok": false, "error": violation, "disconnect": repeat}


## Client to server: one intent (see RoomRegistry). Runs on the server only.
@rpc("any_peer", "call_remote", "reliable")
func send_intent(intent: Dictionary) -> void:
	if not multiplayer.is_server():
		return
	var peer: int = multiplayer.get_remote_sender_id()
	var verdict: Dictionary = check_message(peer, intent, var_to_bytes(intent).size(), Time.get_ticks_msec())
	if not verdict.ok:
		_log("message_rejected", {"peer": peer, "reason": verdict.error, "disconnect": verdict.disconnect})
		receive_message.rpc_id(peer, {"type": "error", "error": verdict.error})
		if verdict.disconnect:
			_close_peer(peer, CLOSE_RATE_LIMITED, verdict.error)
		return
	_deliver(registry.handle(peer, intent))


## Server to client: one message (see RoomRegistry). The server only sends it;
## the client implements the handler.
@rpc("authority", "call_remote", "reliable")
func receive_message(_message: Dictionary) -> void:
	pass


func _process(_delta: float) -> void:
	if registry != null:
		_deliver(registry.tick())


func _on_peer_connected(peer: int) -> void:
	var ip: String = _socket.get_peer(peer).get_connected_host()
	var refusal: String = admit_connection(peer, ip)
	if refusal != "":
		_log("connection_rejected", {"peer": peer, "ip": ip, "reason": refusal})
		var code: int = CLOSE_SERVER_FULL if refusal == "server_full" else CLOSE_TOO_MANY_FROM_IP
		_close_peer(peer, code, refusal)
		return
	_log("peer_connected", {"peer": peer, "ip": ip})


func _on_peer_disconnected(peer: int) -> void:
	release_peer(peer)
	_deliver(registry.disconnect_peer(peer))


func _close_peer(peer: int, code: int, reason: String) -> void:
	var socket_peer: WebSocketPeer = _socket.get_peer(peer)
	if socket_peer != null:
		socket_peer.close(code, reason)


func _deliver(outgoing: Array[Dictionary]) -> void:
	for item: Dictionary in outgoing:
		receive_message.rpc_id(item.to, item.message)
	for entry: Dictionary in registry.drain_events():
		var event: String = entry.event
		entry.erase("event")
		_log(event, entry)


## One log line: "event key=value ...". Text sent by players is escaped and cut
## to LOG_TEXT_LIMIT characters, so it cannot forge or break a log line.
func _log(event: String, fields: Dictionary) -> void:
	print(format_log_line(event, fields))


## The text of one log line (see _log); public so a test can check the escaping.
static func format_log_line(event: String, fields: Dictionary) -> String:
	var parts: PackedStringArray = [event]
	for key: String in fields:
		var value: String = str(fields[key]).c_escape()
		if value.length() > LOG_TEXT_LIMIT:
			value = value.substr(0, LOG_TEXT_LIMIT) + "..."
		parts.append("%s=%s" % [key, value])
	return " ".join(parts)
