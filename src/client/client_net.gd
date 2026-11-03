class_name ClientNet
extends Node
## Client side of the WebSocket link. Name this node "GameServer" and add it at
## the same tree path as the server's GameServer node: Godot matches RPCs by
## node path and method name. The server is always peer 1.

signal connected
signal connection_failed
signal connection_lost
## Emitted for every message the server sends (see RoomRegistry for the shapes).
signal message_received(message: Dictionary)

var _socket: WebSocketMultiplayerPeer


func _ready() -> void:
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)


## Connects to [param url] (for example "ws://127.0.0.1:9080"). Returns OK when
## the attempt started; connected / connection_failed report the outcome.
func connect_to(url: String) -> Error:
	if _socket != null:
		_socket.close()
	_socket = WebSocketMultiplayerPeer.new()
	var error: Error = _socket.create_client(url)
	if error != OK:
		return error
	multiplayer.multiplayer_peer = _socket
	return OK


## True while the link to the server is up.
func is_online() -> bool:
	return _socket != null and _socket.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED


## This client's peer id on the server.
func peer_id() -> int:
	return multiplayer.get_unique_id()


## Sends one intent to the server (see RoomRegistry for the shapes).
func send(intent: Dictionary) -> void:
	send_intent.rpc_id(1, intent)


func _on_connected_to_server() -> void:
	connected.emit()


func _on_connection_failed() -> void:
	connection_failed.emit()


func _on_server_disconnected() -> void:
	connection_lost.emit()


## Client to server. The client only calls it; the server implements it.
@rpc("any_peer", "call_remote", "reliable")
func send_intent(_intent: Dictionary) -> void:
	pass


## Server to client: the handler for every server message.
@rpc("authority", "call_remote", "reliable")
func receive_message(message: Dictionary) -> void:
	message_received.emit(message)
