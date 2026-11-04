class_name GameServer
extends Node
## WebSocket front end of the match server. Add it to the scene tree under the
## same node path on the server and on each client (RPCs match by path), call
## listen() on the server, and have clients send intents with send_intent.rpc_id(1, ...).
##
## All game logic lives in RoomRegistry; this node only moves messages.

const DEFAULT_PORT: int = 9080

var registry: RoomRegistry

var _socket: WebSocketMultiplayerPeer


## Starts listening for WebSocket clients on [param port] (all interfaces).
## Returns OK or the engine's Error code.
func listen(port: int = DEFAULT_PORT, rng: RandomNumberGenerator = null) -> Error:
	var seeded: RandomNumberGenerator = rng if rng != null else RandomNumberGenerator.new()
	if rng == null:
		seeded.randomize()
	registry = RoomRegistry.new(seeded)
	_socket = WebSocketMultiplayerPeer.new()
	var error: Error = _socket.create_server(port)
	if error != OK:
		return error
	multiplayer.multiplayer_peer = _socket
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	return OK


## Client to server: one intent (see RoomRegistry). Runs on the server only.
@rpc("any_peer", "call_remote", "reliable")
func send_intent(intent: Dictionary) -> void:
	if not multiplayer.is_server():
		return
	_deliver(registry.handle(multiplayer.get_remote_sender_id(), intent))


## Server to client: one message (see RoomRegistry). The server only sends it;
## the client implements the handler.
@rpc("authority", "call_remote", "reliable")
func receive_message(_message: Dictionary) -> void:
	pass


func _process(_delta: float) -> void:
	if registry != null:
		_deliver(registry.tick())


func _on_peer_disconnected(peer: int) -> void:
	_deliver(registry.disconnect_peer(peer))


func _deliver(outgoing: Array[Dictionary]) -> void:
	for item: Dictionary in outgoing:
		receive_message.rpc_id(item.to, item.message)
