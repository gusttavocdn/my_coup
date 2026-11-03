class_name RulesEngine
extends RefCounted
## Pure Coup rules core (stories 001-002): setup, turns, actions, challenges,
## blocks, influence loss, elimination and match end.
##
## All mutators return a Dictionary {"ok": bool, "error": String, "events": Array};
## rejected calls leave the state untouched. Player ids are seat indices.
##
## Turn flow for a character action:
##   submit_action -> challenge window -> (block window -> block challenge
##   window) -> resolution. Windows close when every eligible player has called
##   pass_response(), or earlier when someone challenges or blocks.
##
## Usage:
##   var rng := RandomNumberGenerator.new()
##   rng.seed = 12345
##   var engine := RulesEngine.new()
##   engine.setup(3, rng)
##   engine.submit_action(0, RulesConfig.TAXAS)
##   engine.pass_response(1)
##   engine.pass_response(2)

const PHASE_AWAITING_ACTION: String = "awaiting_action"
const PHASE_AWAITING_CHALLENGE: String = "awaiting_challenge"
const PHASE_AWAITING_BLOCK: String = "awaiting_block"
const PHASE_AWAITING_BLOCK_CHALLENGE: String = "awaiting_block_challenge"
const PHASE_AWAITING_INFLUENCE_LOSS: String = "awaiting_influence_loss"
const PHASE_AWAITING_EXCHANGE: String = "awaiting_exchange"
const PHASE_GAME_OVER: String = "game_over"

## What happens once a pending influence loss has been resolved.
const AFTER_END_TURN: String = "end_turn"
const AFTER_BLOCK_WINDOW: String = "block_window"
const AFTER_ACTION_FAILED: String = "action_failed"
const AFTER_BLOCK_STANDS: String = "block_stands"
const AFTER_BLOCK_FAILS: String = "block_fails"

## Serializable game state:
## players: Array of {id, coins, hand (face down), revealed (face up), alive};
## deck: Array[String]; treasury: int; current_player: int; phase: String;
## pending_action: Dictionary ({} when none; gains "block" when blocked);
## window: {eligible, passed, claimant, claim} of the open response window;
## continuation: String (see AFTER_*); loser: int (-1 when none);
## exchange: {player, drawn} while an Embaixador exchange awaits the player's
## choice ({} otherwise); elimination_order: Array[int] of seats in the order
## they were exiled; winner: int (-1 until the match ends).
var state: Dictionary = {}

var _rng: RandomNumberGenerator


## Starts a match for [param player_count] players, shuffling with [param rng]
## (seed it for deterministic games). Example: engine.setup(4, rng)
func setup(player_count: int, rng: RandomNumberGenerator) -> Dictionary:
	if player_count < RulesConfig.MIN_PLAYERS or player_count > RulesConfig.MAX_PLAYERS:
		return _reject("invalid_player_count")
	_rng = rng

	var deck: Array[String] = []
	for character: String in RulesConfig.CHARACTERS:
		for _copy in range(RulesConfig.COPIES_PER_CHARACTER):
			deck.append(character)
	_shuffle(deck)

	var coins: int = RulesConfig.STARTING_COINS_TWO_PLAYER if player_count == 2 \
			else RulesConfig.STARTING_COINS
	var players: Array = []
	for id in range(player_count):
		var hand: Array[String] = []
		for _card in range(RulesConfig.INFLUENCE_PER_PLAYER):
			hand.append(deck.pop_back())
		var revealed: Array[String] = []
		players.append({"id": id, "coins": coins, "hand": hand, "revealed": revealed, "alive": true})

	state = {
		"players": players,
		"deck": deck,
		"treasury": RulesConfig.TOTAL_COINS - coins * player_count,
		"current_player": 0,
		"phase": PHASE_AWAITING_ACTION,
		"pending_action": {},
		"window": {},
		"continuation": "",
		"exchange": {},
		"loser": -1,
		"elimination_order": [],
		"winner": -1,
	}
	return _ok([{"type": "game_started", "player_count": player_count},
			{"type": "turn_started", "player": 0}])


## Returns "" if the action is legal now, otherwise an error code
## (not_accepting_actions, not_your_turn, unknown_action, must_coup,
## insufficient_coins, invalid_target).
func validate_action(actor: int, action: String, target: int = -1) -> String:
	if state.phase != PHASE_AWAITING_ACTION:
		return "not_accepting_actions"
	if actor != state.current_player:
		return "not_your_turn"
	if not RulesConfig.ACTIONS.has(action):
		return "unknown_action"
	var coins: int = state.players[actor].coins
	if coins >= RulesConfig.FORCED_COUP_COINS and action != RulesConfig.GOLPE:
		return "must_coup"
	var definition: Dictionary = RulesConfig.ACTIONS[action]
	if coins < int(definition.cost):
		return "insufficient_coins"
	if definition.targeted:
		if target < 0 or target >= state.players.size() or target == actor \
				or not state.players[target].alive:
			return "invalid_target"
	return ""


## Declares the current player's action and pays its cost. General actions
## resolve at once; character actions open a challenge window.
## Example: engine.submit_action(0, RulesConfig.EXTORQUIR, 2)
func submit_action(actor: int, action: String, target: int = -1) -> Dictionary:
	var error: String = validate_action(actor, action, target)
	if error != "":
		return _reject(error)

	var definition: Dictionary = RulesConfig.ACTIONS[action]
	var events: Array = []
	_move_coins(actor, -int(definition.cost), events)
	state.pending_action = {
		"actor": actor,
		"action": action,
		"target": target if definition.targeted else -1,
	}
	events.append({"type": "action_declared", "actor": actor, "action": action,
			"target": state.pending_action.target})

	if definition.character == "":
		# General actions carry no claim to challenge; only a block can stop them.
		_open_block_window(events)
	else:
		_open_response_window(PHASE_AWAITING_CHALLENGE, actor, definition.character, events)
	return _ok(events)


## An eligible player lets the open window pass without acting. The window
## closes once every eligible player has passed. Example: engine.pass_response(1)
func pass_response(player_id: int) -> Dictionary:
	var error: String = _check_responder(player_id,
			[PHASE_AWAITING_CHALLENGE, PHASE_AWAITING_BLOCK, PHASE_AWAITING_BLOCK_CHALLENGE])
	if error != "":
		return _reject(error)

	var events: Array = []
	state.window.passed.append(player_id)
	events.append({"type": "response_passed", "player": player_id})
	if state.window.passed.size() == state.window.eligible.size():
		_window_closed(events)
	return _ok(events)


## An eligible player challenges the claim the open window is about (the
## action's character, or a block's character). Example: engine.challenge(2)
func challenge(challenger: int) -> Dictionary:
	var error: String = _check_responder(challenger,
			[PHASE_AWAITING_CHALLENGE, PHASE_AWAITING_BLOCK_CHALLENGE])
	if error != "":
		return _reject(error)

	var events: Array = []
	var window: Dictionary = state.window
	var claimant: int = window.claimant
	var claim: String = window.claim
	var on_action: bool = state.phase == PHASE_AWAITING_CHALLENGE
	events.append({"type": "challenge_declared", "challenger": challenger,
			"claimant": claimant, "claim": claim})
	state.window = {}

	if state.players[claimant].hand.has(claim):
		events.append({"type": "challenge_lost", "challenger": challenger,
				"claimant": claimant, "card": claim})
		_replace_card(claimant, claim, events)
		_require_influence_loss(challenger,
				AFTER_BLOCK_WINDOW if on_action else AFTER_BLOCK_STANDS, events)
	else:
		events.append({"type": "challenge_won", "challenger": challenger,
				"claimant": claimant, "claim": claim})
		_require_influence_loss(claimant,
				AFTER_ACTION_FAILED if on_action else AFTER_BLOCK_FAILS, events)
	return _ok(events)


## An eligible player claims [param character] to block the pending action.
## Example: engine.block(2, RulesConfig.CONDESSA)
func block(player_id: int, character: String) -> Dictionary:
	var error: String = _check_responder(player_id, [PHASE_AWAITING_BLOCK])
	if error != "":
		return _reject(error)
	var block_rule: Dictionary = RulesConfig.BLOCKS[state.pending_action.action]
	if not block_rule.blockers.has(character):
		return _reject("invalid_block_character")

	var events: Array = []
	state.pending_action.block = {"blocker": player_id, "character": character}
	events.append({"type": "block_declared", "blocker": player_id, "character": character})
	_open_response_window(PHASE_AWAITING_BLOCK_CHALLENGE, player_id, character, events)
	return _ok(events)


## The player owing an influence loss picks which face-down card (index into
## their hand) to reveal. Example: engine.choose_influence_to_lose(2, 0)
func choose_influence_to_lose(player_id: int, card_index: int) -> Dictionary:
	if state.phase != PHASE_AWAITING_INFLUENCE_LOSS:
		return _reject("no_influence_loss_pending")
	if player_id != state.loser:
		return _reject("not_your_loss")
	var player: Dictionary = state.players[player_id]
	var hand: Array = player.hand
	if card_index < 0 or card_index >= hand.size():
		return _reject("invalid_card")

	var events: Array = []
	var card: String = hand.pop_at(card_index)
	player.revealed.append(card)
	state.loser = -1
	events.append({"type": "influence_lost", "player": player_id, "card": card})
	if hand.is_empty():
		_move_coins(player_id, -int(player.coins), events)
		player.alive = false
		state.elimination_order.append(player_id)
		events.append({"type": "player_eliminated", "player": player_id})

	var continuation: String = state.continuation
	state.continuation = ""
	if _living_count() == 1:
		_end_turn(events)
		return _ok(events)
	match continuation:
		AFTER_BLOCK_WINDOW:
			_open_block_window(events)
		AFTER_ACTION_FAILED:
			var pending: Dictionary = state.pending_action
			if state.players[pending.actor].alive:
				_move_coins(pending.actor, int(RulesConfig.ACTIONS[pending.action].cost), events)
			events.append({"type": "action_failed", "reason": "challenged"})
			_end_turn(events)
		AFTER_BLOCK_STANDS:
			events.append({"type": "action_failed", "reason": "blocked"})
			_end_turn(events)
		AFTER_BLOCK_FAILS:
			events.append({"type": "block_failed"})
			_resolve_pending(events)
		_:
			_end_turn(events)
	return _ok(events)


## Finishes an Embaixador exchange. [param keep] lists indices into the
## player's hand followed by the drawn cards (hand first, then drawn); it must
## name exactly as many distinct cards as the player has influences. Every
## other card returns to the Court deck, which is reshuffled.
## Example: engine.choose_exchange(0, [0, 2]) keeps hand card 0 and drawn card 0
## (when the hand holds two cards).
func choose_exchange(player_id: int, keep: Array) -> Dictionary:
	if state.phase != PHASE_AWAITING_EXCHANGE:
		return _reject("no_exchange_pending")
	if player_id != state.exchange.player:
		return _reject("not_your_exchange")

	var hand: Array = state.players[player_id].hand
	var pool: Array = hand + state.exchange.drawn
	var chosen: Array = []
	for index: Variant in keep:
		if not index is int or index < 0 or index >= pool.size() or chosen.has(index):
			return _reject("invalid_keep")
		chosen.append(index)
	if chosen.size() != hand.size():
		return _reject("invalid_keep")

	var events: Array = []
	var kept: Array[String] = []
	for index: int in chosen:
		kept.append(pool[index])
	for index in range(pool.size()):
		if not chosen.has(index):
			state.deck.append(pool[index])
	_shuffle(state.deck)
	state.players[player_id].hand = kept
	state.exchange = {}
	events.append({"type": "exchange_completed", "player": player_id})
	_end_turn(events)
	return _ok(events)


## True once one player remains.
func is_game_over() -> bool:
	return state.phase == PHASE_GAME_OVER


## Winner's id, or -1 while the match is running.
func get_winner() -> int:
	return state.winner


func _check_responder(player_id: int, allowed_phases: Array) -> String:
	if not allowed_phases.has(state.phase):
		return "no_response_pending"
	if not state.window.eligible.has(player_id):
		return "not_eligible"
	if state.window.passed.has(player_id):
		return "already_responded"
	return ""


## Opens a window where every living player except [param claimant] may
## challenge [param claim] (or, in the block window, respond to the action).
func _open_response_window(phase: String, claimant: int, claim: String, events: Array) -> void:
	var eligible: Array = []
	for player: Dictionary in state.players:
		if player.alive and player.id != claimant:
			eligible.append(player.id)
	state.phase = phase
	state.window = {"eligible": eligible, "passed": [], "claimant": claimant, "claim": claim}
	events.append({"type": "window_opened", "phase": phase, "claimant": claimant,
			"claim": claim, "eligible": eligible.duplicate()})


func _window_closed(events: Array) -> void:
	var phase: String = state.phase
	state.window = {}
	match phase:
		PHASE_AWAITING_CHALLENGE:
			_open_block_window(events)
		PHASE_AWAITING_BLOCK:
			_resolve_pending(events)
		PHASE_AWAITING_BLOCK_CHALLENGE:
			events.append({"type": "action_failed", "reason": "blocked"})
			_end_turn(events)


## Opens the block window if the pending action can be blocked and someone can
## block it; otherwise resolves the action.
func _open_block_window(events: Array) -> void:
	var pending: Dictionary = state.pending_action
	var block_rule: Dictionary = RulesConfig.BLOCKS.get(pending.action, {})
	if block_rule.is_empty():
		_resolve_pending(events)
		return
	var eligible: Array = []
	if block_rule.target_only:
		if state.players[pending.target].alive:
			eligible.append(pending.target)
	else:
		for player: Dictionary in state.players:
			if player.alive and player.id != pending.actor:
				eligible.append(player.id)
	if eligible.is_empty():
		_resolve_pending(events)
		return
	state.phase = PHASE_AWAITING_BLOCK
	state.window = {"eligible": eligible, "passed": [], "claimant": -1, "claim": ""}
	events.append({"type": "window_opened", "phase": PHASE_AWAITING_BLOCK, "claimant": -1,
			"claim": "", "eligible": eligible.duplicate()})


func _resolve_pending(events: Array) -> void:
	var pending: Dictionary = state.pending_action
	var actor: int = pending.actor
	var target: int = pending.target
	var amount: int = RulesConfig.ACTIONS[pending.action].amount
	state.pending_action = {}
	state.window = {}
	if target != -1 and not state.players[target].alive:
		events.append({"type": "action_dropped", "actor": actor, "action": pending.action})
		_end_turn(events)
		return
	events.append({"type": "action_resolved", "actor": actor, "action": pending.action,
			"target": target})

	match pending.action:
		RulesConfig.RENDA, RulesConfig.AJUDA_EXTERNA, RulesConfig.TAXAS:
			_move_coins(actor, amount, events)
		RulesConfig.EXTORQUIR:
			var stolen: int = mini(amount, state.players[target].coins)
			state.players[target].coins -= stolen
			state.players[actor].coins += stolen
			events.append({"type": "coins_stolen", "from": target, "to": actor, "amount": stolen})
		RulesConfig.TROCAR:
			var drawn: Array[String] = []
			for _card in range(mini(RulesConfig.EXCHANGE_DRAW, state.deck.size())):
				drawn.append(state.deck.pop_back())
			state.exchange = {"player": actor, "drawn": drawn}
			state.phase = PHASE_AWAITING_EXCHANGE
			events.append({"type": "exchange_started", "player": actor, "drawn_count": drawn.size()})
			return
		RulesConfig.GOLPE, RulesConfig.ASSASSINAR:
			_require_influence_loss(target, AFTER_END_TURN, events)
			return
	_end_turn(events)


func _require_influence_loss(player_id: int, continuation: String, events: Array) -> void:
	state.loser = player_id
	state.continuation = continuation
	state.phase = PHASE_AWAITING_INFLUENCE_LOSS
	events.append({"type": "influence_loss_required", "player": player_id})


## Returns [param card] from the player's hand to the Court deck, reshuffles
## the deck and deals the player a random replacement.
func _replace_card(player_id: int, card: String, events: Array) -> void:
	var hand: Array = state.players[player_id].hand
	hand.erase(card)
	state.deck.append(card)
	_shuffle(state.deck)
	hand.append(state.deck.pop_back())
	events.append({"type": "card_replaced", "player": player_id})


func _shuffle(cards: Array) -> void:
	for i in range(cards.size() - 1, 0, -1):
		var j: int = _rng.randi_range(0, i)
		var swap: Variant = cards[i]
		cards[i] = cards[j]
		cards[j] = swap


## Moves coins between a player and the treasury: positive [param delta] is a
## gain (capped by the treasury balance), negative pays into the treasury.
func _move_coins(player_id: int, delta: int, events: Array) -> void:
	var applied: int = mini(delta, state.treasury) if delta > 0 else delta
	state.players[player_id].coins += applied
	state.treasury -= applied
	events.append({"type": "coins_changed", "player": player_id, "delta": applied})


func _living_count() -> int:
	var count: int = 0
	for player: Dictionary in state.players:
		if player.alive:
			count += 1
	return count


func _end_turn(events: Array) -> void:
	state.pending_action = {}
	state.window = {}
	if _living_count() == 1:
		for player: Dictionary in state.players:
			if player.alive:
				state.winner = player.id
		state.phase = PHASE_GAME_OVER
		events.append({"type": "game_over", "winner": state.winner})
		return
	var next: int = state.current_player
	while true:
		next = (next + 1) % state.players.size()
		if state.players[next].alive:
			break
	state.current_player = next
	state.phase = PHASE_AWAITING_ACTION
	events.append({"type": "turn_started", "player": next})


func _ok(events: Array) -> Dictionary:
	return {"ok": true, "error": "", "events": events}


func _reject(error: String) -> Dictionary:
	return {"ok": false, "error": error, "events": []}
