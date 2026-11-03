class_name RoomRegistry
extends RefCounted
## Owns every Room and turns client intents into outgoing messages.
##
## handle() is the whole server brain: it takes one intent from one peer and
## returns the messages to send, as [{"to": peer_id, "message": Dictionary}].
## No sockets are involved, so it is testable without a network.
##
## Lobby intents: {"type": "create_room", "name"}, {"type": "join_room", "code",
## "name"}, {"type": "start_match"}, {"type": "leave_room"}, {"type":
## "return_to_lobby"} (after a finished match). In-game intents are documented
## on Room.handle_intent.
##
## Server -> client messages: {"type": "error", "error"}, {"type": "room", ...
## lobby view}, {"type": "update", "events", "view"}, {"type": "match_aborted"},
## {"type": "left"} (confirms leave_room to the leaver).

## Characters room codes are drawn from (no easily confused letters).
const CODE_ALPHABET: String = "ABCDEFGHJKLMNPQRSTUVWXYZ"
const CODE_LENGTH: int = 4

var _rooms: Dictionary = {}
var _room_of_peer: Dictionary = {}
var _rng: RandomNumberGenerator


func _init(rng: RandomNumberGenerator) -> void:
	_rng = rng


## Applies [param intent] from [param peer]; see the class comment.
func handle(peer: int, intent: Dictionary) -> Array[Dictionary]:
	match intent.get("type"):
		"create_room":
			return _create_room(peer, intent)
		"join_room":
			return _join_room(peer, intent)
		"start_match":
			return _start_match(peer)
		"return_to_lobby":
			return _return_to_lobby(peer)
		"leave_room":
			var messages: Array[Dictionary] = disconnect_peer(peer)
			messages.append(_to(peer, {"type": "left"}))
			return messages
	return _in_game_intent(peer, intent)


## Removes a peer that left or dropped. An abandoned started match is aborted
## for everyone still in it.
func disconnect_peer(peer: int) -> Array[Dictionary]:
	var room: Room = room_of(peer)
	if room == null:
		return []
	var outcome: Dictionary = room.remove(peer)
	_room_of_peer.erase(peer)
	var messages: Array[Dictionary] = []
	if outcome.aborted:
		for member: Dictionary in room.members:
			messages.append(_to(member.peer, {"type": "match_aborted", "reason": "player_left"}))
			_room_of_peer.erase(member.peer)
		_rooms.erase(room.code)
		return messages
	if outcome.empty:
		_rooms.erase(room.code)
		return messages
	messages.append_array(_lobby_messages(room))
	return messages


## The room [param peer] is in, or null.
func room_of(peer: int) -> Room:
	var code: Variant = _room_of_peer.get(peer)
	return null if code == null else _rooms.get(code)


## Number of open rooms.
func room_count() -> int:
	return _rooms.size()


func _create_room(peer: int, intent: Dictionary) -> Array[Dictionary]:
	if room_of(peer) != null:
		return [_error(peer, "already_in_room")]
	if not intent.get("name") is String:
		return [_error(peer, "invalid_intent")]
	var room := Room.new(_new_code(), _rng)
	var joined: Dictionary = room.join(peer, intent.name)
	if not joined.ok:
		return [_error(peer, joined.error)]
	_rooms[room.code] = room
	_room_of_peer[peer] = room.code
	return _lobby_messages(room)


func _join_room(peer: int, intent: Dictionary) -> Array[Dictionary]:
	if room_of(peer) != null:
		return [_error(peer, "already_in_room")]
	if not intent.get("code") is String or not intent.get("name") is String:
		return [_error(peer, "invalid_intent")]
	var room: Room = _rooms.get(intent.code.to_upper())
	if room == null:
		return [_error(peer, "room_not_found")]
	var joined: Dictionary = room.join(peer, intent.name)
	if not joined.ok:
		return [_error(peer, joined.error)]
	_room_of_peer[peer] = room.code
	return _lobby_messages(room)


## Only the sender goes back to the lobby view; the others keep reading their
## result screen until they press the button themselves.
func _return_to_lobby(peer: int) -> Array[Dictionary]:
	var room: Room = room_of(peer)
	if room == null:
		return [_error(peer, "not_in_room")]
	var result: Dictionary = room.return_to_lobby(peer)
	if not result.ok:
		return [_error(peer, result.error)]
	var message: Dictionary = room.lobby_view()
	message.type = "room"
	return [_to(peer, message)]


func _start_match(peer: int) -> Array[Dictionary]:
	var room: Room = room_of(peer)
	if room == null:
		return [_error(peer, "not_in_room")]
	var result: Dictionary = room.start(peer)
	if not result.ok:
		return [_error(peer, result.error)]
	return _update_messages(room, result.events)


func _in_game_intent(peer: int, intent: Dictionary) -> Array[Dictionary]:
	var room: Room = room_of(peer)
	if room == null:
		return [_error(peer, "not_in_room")]
	var result: Dictionary = room.handle_intent(peer, intent)
	if not result.ok:
		return [_error(peer, result.error)]
	return _update_messages(room, result.events)


func _lobby_messages(room: Room) -> Array[Dictionary]:
	var messages: Array[Dictionary] = []
	for member: Dictionary in room.members:
		var message: Dictionary = room.lobby_view()
		message.type = "room"
		messages.append(_to(member.peer, message))
	return messages


## One update per member, each carrying that member's own filtered view.
func _update_messages(room: Room, events: Array) -> Array[Dictionary]:
	var messages: Array[Dictionary] = []
	for member: Dictionary in room.members:
		messages.append(_to(member.peer, {
			"type": "update",
			"events": events,
			"view": room.view_for(member.peer),
		}))
	return messages


func _new_code() -> String:
	while true:
		var code: String = ""
		for _letter in range(CODE_LENGTH):
			code += CODE_ALPHABET[_rng.randi_range(0, CODE_ALPHABET.length() - 1)]
		if not _rooms.has(code):
			return code
	return ""


func _to(peer: int, message: Dictionary) -> Dictionary:
	return {"to": peer, "message": message}


func _error(peer: int, error: String) -> Dictionary:
	return _to(peer, {"type": "error", "error": error})
