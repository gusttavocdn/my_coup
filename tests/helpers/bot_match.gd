class_name BotMatch
extends RefCounted
## Test helper: plays one whole match through RoomRegistry with random bots
## that only use their own per-player view, checking the rules' invariants
## after every step. Deterministic for a given (player_count, seed).

const MAX_STEPS: int = 4000
const CHALLENGE_CHANCE: float = 0.2
const BLOCK_CHANCE: float = 0.4

## Filled by play(): counters of event types seen, e.g. {"challenge_declared": 3}.
var event_counts: Dictionary = {}
## Problems found; empty when the match was clean.
var failures: Array[String] = []
var steps: int = 0
var finished: bool = false
var room: Room

var _bot: RandomNumberGenerator


## Plays a match of [param player_count] players to its end.
func play(player_count: int, seed_value: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	_bot = RandomNumberGenerator.new()
	_bot.seed = seed_value * 100 + player_count
	var registry := RoomRegistry.new(rng)

	registry.handle(1, {"type": "create_room", "name": "P1"})
	var code: String = registry.room_of(1).code
	for peer in range(2, player_count + 1):
		registry.handle(peer, {"type": "join_room", "code": code, "name": "P%d" % peer})
	var started: Array[Dictionary] = registry.handle(1, {"type": "start_match"})
	room = registry.room_of(1)
	_count_events(started)

	while steps < MAX_STEPS and room.engine.state.phase != RulesEngine.PHASE_GAME_OVER:
		steps += 1
		var sent: bool = false
		for peer in _shuffled_peers(player_count):
			var intent: Dictionary = _intent(room.view_for(peer), _bot)
			if intent.is_empty():
				continue
			var outgoing: Array[Dictionary] = registry.handle(peer, intent)
			for item: Dictionary in outgoing:
				if item.message.type == "error":
					failures.append("step %d: peer %d intent %s rejected: %s" % [steps, peer, intent, item.message.error])
			_count_events(outgoing)
			sent = true
			break
		if not sent:
			failures.append("step %d: nobody can act in phase %s" % [steps, room.engine.state.phase])
			return
		_check_invariants()
		if not failures.is_empty():
			return

	finished = room.engine.state.phase == RulesEngine.PHASE_GAME_OVER
	if not finished:
		failures.append("match did not finish in %d steps" % MAX_STEPS)
		return
	_check_end(player_count)


func _check_invariants() -> void:
	var state: Dictionary = room.engine.state
	var coins: int = state.treasury
	var cards: int = state.deck.size()
	for player: Dictionary in state.players:
		coins += player.coins
		cards += player.hand.size() + player.revealed.size()
	if not state.exchange.is_empty():
		cards += state.exchange.drawn.size()
	if coins != RulesConfig.TOTAL_COINS:
		failures.append("step %d: coins total %d" % [steps, coins])
	if cards != RulesConfig.CHARACTERS.size() * RulesConfig.COPIES_PER_CHARACTER:
		failures.append("step %d: cards total %d" % [steps, cards])


func _check_end(player_count: int) -> void:
	var state: Dictionary = room.engine.state
	var alive: int = 0
	for player: Dictionary in state.players:
		if player.alive:
			alive += 1
	if alive != 1 or not state.players[state.winner].alive:
		failures.append("end: %d players alive, winner %d" % [alive, state.winner])
	if state.elimination_order.size() != player_count - 1:
		failures.append("end: %d eliminations for %d players" % [state.elimination_order.size(), player_count])
	var standings: Array = room.view_for(1).standings
	if standings.size() != player_count or standings[0].seat != state.winner:
		failures.append("end: bad standings")


func _count_events(outgoing: Array[Dictionary]) -> void:
	for item: Dictionary in outgoing:
		if item.to != 1 or item.message.type != "update":
			continue
		for event: Dictionary in item.message.events:
			event_counts[event.type] = int(event_counts.get(event.type, 0)) + 1


func _shuffled_peers(player_count: int) -> Array:
	var peers: Array = range(1, player_count + 1)
	for index in range(peers.size() - 1, 0, -1):
		var other: int = _bot.randi_range(0, index)
		var swap: int = peers[index]
		peers[index] = peers[other]
		peers[other] = swap
	return peers


## The intent a bot with [param view] would send now, or {} when it has nothing to do.
func _intent(view: Dictionary, bot: RandomNumberGenerator) -> Dictionary:
	var me: int = view.you.seat
	if not view.players[me].alive:
		return {}
	var window: Dictionary = view.window
	var response_open: bool = not window.is_empty() and window.eligible.has(me) \
			and not window.passed.has(me)

	match view.phase:
		RulesEngine.PHASE_AWAITING_INFLUENCE_LOSS:
			if view.loser == me:
				return {"type": "lose_influence", "card_index": bot.randi_range(0, view.you.hand.size() - 1)}
		RulesEngine.PHASE_AWAITING_EXCHANGE:
			if view.exchange.player == me and view.exchange.has("drawn"):
				var pool_size: int = view.you.hand.size() + view.exchange.drawn.size()
				var indices: Array = range(pool_size)
				var keep: Array = []
				for _pick in range(view.you.hand.size()):
					keep.append(indices.pop_at(bot.randi_range(0, indices.size() - 1)))
				return {"type": "exchange", "keep": keep}
		RulesEngine.PHASE_AWAITING_CHALLENGE, RulesEngine.PHASE_AWAITING_BLOCK_CHALLENGE:
			if response_open:
				return {"type": "challenge"} if bot.randf() < CHALLENGE_CHANCE else {"type": "pass"}
		RulesEngine.PHASE_AWAITING_BLOCK:
			if response_open:
				if bot.randf() < BLOCK_CHANCE:
					var blockers: Array = RulesConfig.BLOCKS[view.pending_action.action].blockers
					return {"type": "block", "character": blockers[bot.randi_range(0, blockers.size() - 1)]}
				return {"type": "pass"}
		RulesEngine.PHASE_AWAITING_ACTION:
			if view.current_player == me:
				return _action(view, bot)
	return {}


func _action(view: Dictionary, bot: RandomNumberGenerator) -> Dictionary:
	var me: int = view.you.seat
	var coins: int = view.players[me].coins
	var targets: Array = []
	for player: Dictionary in view.players:
		if player.alive and player.id != me:
			targets.append(player.id)
	var choices: Array = []
	for action: String in RulesConfig.ACTIONS:
		if coins >= RulesConfig.FORCED_COUP_COINS and action != RulesConfig.GOLPE:
			continue
		if coins >= int(RulesConfig.ACTIONS[action].cost):
			choices.append(action)
	var picked: String = choices[bot.randi_range(0, choices.size() - 1)]
	var intent: Dictionary = {"type": "action", "action": picked}
	if RulesConfig.ACTIONS[picked].targeted:
		intent.target = targets[bot.randi_range(0, targets.size() - 1)]
	return intent
