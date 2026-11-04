class_name Room
extends RefCounted
## One match room: lobby members, seat assignment and the authoritative
## RulesEngine. Pure logic, no sockets: peers are plain integer ids.
##
## Clients only send intents (see handle_intent); every view built here is
## filtered so a player sees their own cards and nothing else that is hidden.
##
## Only response windows (challenge, block, challenge of a block) have a
## deadline: tick() makes the players who have not answered pass once it is
## reached. A player's own turn, an influence loss and an Embaixador exchange
## wait indefinitely.

const MAX_NAME_LENGTH: int = 16
## Deadline value while no response window is open.
const NO_DEADLINE: int = -1

var code: String = ""
## Peer id of the host, who may start the match.
var host: int = -1
## Join order: {"peer": int, "name": String, "seat": int} ("seat" is -1 in the lobby).
var members: Array[Dictionary] = []
var started: bool = false
var engine: RulesEngine = null

var _rng: RandomNumberGenerator
## Returns the current time in milliseconds; injectable so tests do not sleep.
var _clock: Callable
var _response_ms: int = 0
## Clock time (ms) at which the open response window times out, or NO_DEADLINE.
var _deadline_ms: int = NO_DEADLINE


## [param clock] returns milliseconds (default: the engine's tick counter);
## [param response_seconds] is how long a response window stays open.
func _init(room_code: String, rng: RandomNumberGenerator, clock: Callable = Callable(),
		response_seconds: float = RulesConfig.RESPONSE_SECONDS) -> void:
	code = room_code
	_rng = rng
	_clock = clock if clock.is_valid() else Time.get_ticks_msec
	_response_ms = int(round(response_seconds * 1000.0))


## Adds [param peer] to the lobby. Returns {"ok", "error"}.
## Errors: match_started, room_full, already_joined, invalid_name.
func join(peer: int, display_name: String) -> Dictionary:
	if started:
		return {"ok": false, "error": "match_started"}
	if members.size() >= RulesConfig.MAX_PLAYERS:
		return {"ok": false, "error": "room_full"}
	if _member_index(peer) != -1:
		return {"ok": false, "error": "already_joined"}
	var clean: String = display_name.strip_edges().left(MAX_NAME_LENGTH)
	if clean.is_empty():
		return {"ok": false, "error": "invalid_name"}
	members.append({"peer": peer, "name": clean, "seat": -1})
	if host == -1:
		host = peer
	return {"ok": true, "error": ""}


## Starts the match; only the host may, with 2-6 players present.
## Returns {"ok", "error", "events"}.
func start(peer: int) -> Dictionary:
	if started:
		return {"ok": false, "error": "match_started", "events": []}
	if peer != host:
		return {"ok": false, "error": "not_host", "events": []}
	var new_engine := RulesEngine.new()
	var result: Dictionary = new_engine.setup(members.size(), _rng)
	if not result.ok:
		return result
	for seat in range(members.size()):
		members[seat].seat = seat
	engine = new_engine
	started = true
	_deadline_ms = NO_DEADLINE
	return result


## Applies one in-game intent from [param peer]. Intent shapes:
## {"type": "action", "action": String, "target": int (optional)},
## {"type": "pass"}, {"type": "challenge"}, {"type": "block", "character": String},
## {"type": "lose_influence", "card_index": int}, {"type": "exchange", "keep": Array}.
## Returns the engine's {"ok", "error", "events"}; malformed intents are
## rejected with invalid_intent and change nothing.
func handle_intent(peer: int, intent: Dictionary) -> Dictionary:
	var result: Dictionary = _apply_intent(peer, intent)
	if result.ok:
		_update_deadline(result.events)
	return result


## Makes every player who has not answered the open response window pass once
## its deadline is reached ([param now_ms] on the room's clock). The window then
## closes through the normal engine path. Returns {"events": Array}: a
## "response_timeout" {"player": seat} per straggler followed by the engine's
## own events; empty when there is no open window or the deadline is not
## reached yet.
func tick(now_ms: int) -> Dictionary:
	var events: Array = []
	if not started or _deadline_ms == NO_DEADLINE or now_ms < _deadline_ms \
			or engine.state.window.is_empty():
		return {"events": events}
	var stragglers: Array = []
	for seat: int in engine.state.window.eligible:
		if not engine.state.window.passed.has(seat):
			stragglers.append(seat)
	for seat: int in stragglers:
		events.append({"type": "response_timeout", "player": seat})
		var result: Dictionary = engine.pass_response(seat)
		events.append_array(result.events)
	_update_deadline(events)
	return {"events": events}


func _apply_intent(peer: int, intent: Dictionary) -> Dictionary:
	if not started:
		return _reject("match_not_started")
	var index: int = _member_index(peer)
	if index == -1:
		return _reject("not_in_room")
	var seat: int = members[index].seat

	match intent.get("type"):
		"action":
			if not intent.get("action") is String:
				return _reject("invalid_intent")
			var target: Variant = intent.get("target", -1)
			if not target is int:
				return _reject("invalid_intent")
			return engine.submit_action(seat, intent.action, target)
		"pass":
			return engine.pass_response(seat)
		"challenge":
			return engine.challenge(seat)
		"block":
			if not intent.get("character") is String:
				return _reject("invalid_intent")
			return engine.block(seat, intent.character)
		"lose_influence":
			if not intent.get("card_index") is int:
				return _reject("invalid_intent")
			return engine.choose_influence_to_lose(seat, intent.card_index)
		"exchange":
			if not intent.get("keep") is Array:
				return _reject("invalid_intent")
			return engine.choose_exchange(seat, intent.keep)
	return _reject("invalid_intent")


## Takes the room back to the lobby after a finished match so the same members
## can start another; a no-op once that has happened. Returns {"ok", "error"}
## (match_not_over while a match is still being played).
func return_to_lobby(peer: int) -> Dictionary:
	if _member_index(peer) == -1:
		return {"ok": false, "error": "not_in_room"}
	if not started:
		return {"ok": true, "error": ""}
	if engine.state.phase != RulesEngine.PHASE_GAME_OVER:
		return {"ok": false, "error": "match_not_over"}
	_reset_to_lobby()
	return {"ok": true, "error": ""}


## Removes [param peer]. Returns {"aborted": bool, "empty": bool}: a player
## leaving a match still in progress aborts it (MVP; no reconnection), a player
## leaving a finished match does not, and the host passes to the next member
## when the host leaves the lobby.
func remove(peer: int) -> Dictionary:
	var index: int = _member_index(peer)
	if index == -1:
		return {"aborted": false, "empty": members.is_empty()}
	members.remove_at(index)
	if peer == host and not members.is_empty():
		host = members[0].peer
	var match_running: bool = started and engine.state.phase != RulesEngine.PHASE_GAME_OVER
	if started and not match_running:
		# Seats no longer line up with members once someone left a finished match.
		_reset_to_lobby()
	return {"aborted": match_running, "empty": members.is_empty()}


## The lobby as every member sees it.
func lobby_view() -> Dictionary:
	var names: Array = []
	for member: Dictionary in members:
		names.append(member.name)
	return {"code": code, "host": host, "names": names, "started": started}


## The match as seen by [param peer]: public table state plus that peer's own
## hand. Other players' face-down cards and the Court deck contents are never
## included; an Embaixador exchange shows the drawn cards only to the drawer.
func view_for(peer: int) -> Dictionary:
	var index: int = _member_index(peer)
	var state: Dictionary = engine.state
	var players: Array = []
	for player: Dictionary in state.players:
		players.append({
			"id": player.id,
			"name": members[player.id].name,
			"coins": player.coins,
			"influence": player.hand.size(),
			"revealed": player.revealed.duplicate(),
			"alive": player.alive,
		})

	var view: Dictionary = {
		"phase": state.phase,
		"current_player": state.current_player,
		"winner": state.winner,
		"treasury": state.treasury,
		"deck_count": state.deck.size(),
		"loser": state.loser,
		"players": players,
		"you": {"seat": members[index].seat, "hand": state.players[members[index].seat].hand.duplicate()},
		"window": {},
		"pending_action": state.pending_action.duplicate(true),
		"exchange": {},
		"standings": [],
	}
	if state.phase == RulesEngine.PHASE_GAME_OVER:
		view.standings = _standings()
	if not state.window.is_empty():
		view.window = state.window.duplicate(true)
		if _deadline_ms != NO_DEADLINE:
			view.window.total_seconds = _response_ms / 1000.0
			view.window.seconds_left = maxf(0.0, (_deadline_ms - _now()) / 1000.0)
	if not state.exchange.is_empty():
		view.exchange = {"player": state.exchange.player}
		if state.exchange.player == members[index].seat:
			view.exchange.drawn = state.exchange.drawn.duplicate()
	return view


## The finishing order of a finished match, winner first: one entry per seat
## with {"seat", "name", "rank" (1 = winner), "cards"} where cards are every
## card the player ended with (the winner's remaining hand is shown too, since
## nothing is secret once the match is over).
func _standings() -> Array:
	var state: Dictionary = engine.state
	var order: Array = [state.winner]
	var exiled: Array = state.elimination_order.duplicate()
	exiled.reverse()
	order.append_array(exiled)
	var standings: Array = []
	for index in range(order.size()):
		var seat: int = order[index]
		var player: Dictionary = state.players[seat]
		standings.append({
			"seat": seat,
			"name": members[seat].name,
			"rank": index + 1,
			"cards": player.revealed + player.hand,
		})
	return standings


## Seat of [param peer], or -1 when they are not seated.
func seat_of(peer: int) -> int:
	var index: int = _member_index(peer)
	return -1 if index == -1 else members[index].seat


## Forgets the finished match: the members stay, the seats and engine go.
## A member who has not pressed "return to lobby" yet is still counted by
## start() (MVP decision: no readiness check).
func _reset_to_lobby() -> void:
	started = false
	engine = null
	_deadline_ms = NO_DEADLINE
	for member: Dictionary in members:
		member.seat = -1


## A new window gets a fresh deadline; no open window means no deadline. Called
## with the events of every engine step.
func _update_deadline(events: Array) -> void:
	if engine.state.window.is_empty():
		_deadline_ms = NO_DEADLINE
		return
	for event: Dictionary in events:
		if event.get("type") == "window_opened":
			_deadline_ms = _now() + _response_ms
			return


func _now() -> int:
	return int(_clock.call())


func _member_index(peer: int) -> int:
	for index in range(members.size()):
		if members[index].peer == peer:
			return index
	return -1


func _reject(error: String) -> Dictionary:
	return {"ok": false, "error": error, "events": []}
