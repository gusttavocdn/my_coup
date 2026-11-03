extends GdUnitTestSuite
## Story 004: rooms, intents and hidden-state views of the match server.
## Drives RoomRegistry directly (no sockets) with simulated clients.


func _registry() -> RoomRegistry:
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	return RoomRegistry.new(rng)


## Messages in [param outgoing] addressed to [param peer].
func _for_peer(outgoing: Array, peer: int) -> Array:
	var found: Array = []
	for item: Dictionary in outgoing:
		if item.to == peer:
			found.append(item.message)
	return found


func _error_of(outgoing: Array, peer: int) -> String:
	for message: Dictionary in _for_peer(outgoing, peer):
		if message.type == "error":
			return message.error
	return ""


## Peer 1 creates a room and peers 2..count join it; returns the room code.
func _lobby(registry: RoomRegistry, count: int) -> String:
	registry.handle(1, {"type": "create_room", "name": "P1"})
	var code: String = registry.room_of(1).code
	for peer in range(2, count + 1):
		registry.handle(peer, {"type": "join_room", "code": code, "name": "P%d" % peer})
	return code


## A started match of [param count] players (peers 1..count, seats 0..count-1).
func _started(registry: RoomRegistry, count: int) -> Room:
	_lobby(registry, count)
	registry.handle(1, {"type": "start_match"})
	return registry.room_of(1)


# AC-2: create, join by code, 2-6 players

func test_create_room_returns_short_code_to_host() -> void:
	var registry := _registry()

	var outgoing: Array = registry.handle(1, {"type": "create_room", "name": "Ana"})

	var message: Dictionary = _for_peer(outgoing, 1)[0]
	assert_str(message.type).is_equal("room")
	assert_int(message.code.length()).is_equal(RoomRegistry.CODE_LENGTH)
	assert_int(message.host).is_equal(1)
	assert_array(message.names).is_equal(["Ana"])


func test_join_by_code_is_case_insensitive_and_updates_every_member() -> void:
	var registry := _registry()
	registry.handle(1, {"type": "create_room", "name": "Ana"})
	var code: String = registry.room_of(1).code

	var outgoing: Array = registry.handle(2, {"type": "join_room", "code": code.to_lower(), "name": "Bia"})

	assert_array(_for_peer(outgoing, 1)[0].names).is_equal(["Ana", "Bia"])
	assert_array(_for_peer(outgoing, 2)[0].names).is_equal(["Ana", "Bia"])


func test_seventh_join_is_refused_with_room_full() -> void:
	var registry := _registry()
	var code: String = _lobby(registry, 6)

	var outgoing: Array = registry.handle(7, {"type": "join_room", "code": code, "name": "P7"})

	assert_str(_error_of(outgoing, 7)).is_equal("room_full")
	assert_int(registry.room_of(1).members.size()).is_equal(6)


func test_join_unknown_code_or_second_room_is_refused() -> void:
	var registry := _registry()
	registry.handle(1, {"type": "create_room", "name": "Ana"})

	assert_str(_error_of(registry.handle(2, {"type": "join_room", "code": "ZZZZ", "name": "Bia"}), 2)) \
			.is_equal("room_not_found")
	assert_str(_error_of(registry.handle(1, {"type": "create_room", "name": "Ana"}), 1)) \
			.is_equal("already_in_room")


# AC-3: host starts with 2-6 players; no late joins

func test_only_host_can_start_and_needs_at_least_two_players() -> void:
	var registry := _registry()
	registry.handle(1, {"type": "create_room", "name": "Ana"})
	assert_str(_error_of(registry.handle(1, {"type": "start_match"}), 1)).is_equal("invalid_player_count")
	registry.handle(2, {"type": "join_room", "code": registry.room_of(1).code, "name": "Bia"})

	assert_str(_error_of(registry.handle(2, {"type": "start_match"}), 2)).is_equal("not_host")
	assert_bool(registry.room_of(1).started).is_false()
	registry.handle(1, {"type": "start_match"})
	assert_bool(registry.room_of(1).started).is_true()


func test_join_after_start_is_refused() -> void:
	var registry := _registry()
	var room: Room = _started(registry, 3)

	var outgoing: Array = registry.handle(4, {"type": "join_room", "code": room.code, "name": "Late"})

	assert_str(_error_of(outgoing, 4)).is_equal("match_started")


# AC-4: server runs the rules engine; AC-5: per-player filtered views

func test_start_sends_each_player_their_own_hand_and_only_counts_for_others() -> void:
	var registry := _registry()
	var room: Room = _started(registry, 3)

	var view: Dictionary = room.view_for(2)

	assert_int(view.you.seat).is_equal(1)
	assert_array(view.you.hand).is_equal(room.engine.state.players[1].hand)
	assert_int(view.players[0].influence).is_equal(2)
	assert_bool(view.players[0].has("hand")).is_false()
	assert_int(view.deck_count).is_equal(9)
	assert_int(view.players[1].coins).is_equal(2)


func test_no_opponent_hand_or_deck_card_ever_appears_in_a_players_messages() -> void:
	var registry := _registry()
	var room: Room = _started(registry, 3)
	# Peer 1 holds duque; peer 2 holds the only visible copies of condessa and the
	# third copy sits in the deck. Nothing in this script reveals or claims condessa.
	room.engine.state.players[0].hand = ["duque", "duque"] as Array[String]
	room.engine.state.players[1].hand = ["condessa", "condessa"] as Array[String]
	room.engine.state.players[2].hand = ["capitao", "capitao"] as Array[String]
	room.engine.state.deck = ["assassino", "assassino", "condessa"] as Array[String]

	var seen_by_peer_one: Array = []
	var seen_by_peer_two: Array = []
	for outgoing: Array in [
			registry.handle(1, {"type": "action", "action": "renda"}),
			registry.handle(2, {"type": "action", "action": "renda"}),
			registry.handle(3, {"type": "action", "action": "ajuda_externa"}),
			registry.handle(1, {"type": "pass"}),
			registry.handle(2, {"type": "pass"})]:
		seen_by_peer_one.append_array(_for_peer(outgoing, 1))
		seen_by_peer_two.append_array(_for_peer(outgoing, 2))

	assert_str(JSON.stringify(seen_by_peer_one)).not_contains("condessa")
	assert_str(JSON.stringify(seen_by_peer_one)).not_contains("capitao")
	assert_str(JSON.stringify(seen_by_peer_two)).contains("condessa")


func test_exchange_drawn_cards_are_shown_only_to_the_drawing_player() -> void:
	var registry := _registry()
	var room: Room = _started(registry, 3)
	room.engine.state.players[0].hand = ["embaixador", "duque"] as Array[String]
	room.engine.state.deck = ["capitao", "assassino"] as Array[String]
	registry.handle(1, {"type": "action", "action": "trocar"})
	registry.handle(2, {"type": "pass"})
	registry.handle(3, {"type": "pass"})

	assert_array(room.view_for(1).exchange.drawn).is_equal(["assassino", "capitao"])
	assert_bool(room.view_for(2).exchange.has("drawn")).is_false()
	assert_int(room.view_for(2).exchange.player).is_equal(0)


# AC-6: intents validated by the server

func test_out_of_turn_and_malformed_intents_are_rejected_without_changing_state() -> void:
	var registry := _registry()
	var room: Room = _started(registry, 3)
	var before: String = JSON.stringify(room.engine.state)

	assert_str(_error_of(registry.handle(2, {"type": "action", "action": "renda"}), 2)).is_equal("not_your_turn")
	assert_str(_error_of(registry.handle(1, {"type": "action", "action": 5}), 1)).is_equal("invalid_intent")
	assert_str(_error_of(registry.handle(1, {"type": "action", "action": "golpe", "target": "x"}), 1)) \
			.is_equal("invalid_intent")
	assert_str(_error_of(registry.handle(1, {"type": "fly"}), 1)).is_equal("invalid_intent")
	assert_str(_error_of(registry.handle(1, {"type": "action", "action": "golpe", "target": 1}), 1)) \
			.is_equal("insufficient_coins")
	assert_str(_error_of(registry.handle(99, {"type": "action", "action": "renda"}), 99)).is_equal("not_in_room")
	assert_str(JSON.stringify(room.engine.state)).is_equal(before)


func test_intent_before_the_match_starts_is_rejected() -> void:
	var registry := _registry()
	_lobby(registry, 2)

	var outgoing: Array = registry.handle(1, {"type": "action", "action": "renda"})

	assert_str(_error_of(outgoing, 1)).is_equal("match_not_started")


# AC-7: response windows wait for every eligible player; others are ignored

func test_window_waits_for_every_eligible_player_and_rejects_the_claimant() -> void:
	var registry := _registry()
	var room: Room = _started(registry, 3)
	registry.handle(1, {"type": "action", "action": "taxas"})
	var before: String = JSON.stringify(room.engine.state)

	assert_str(_error_of(registry.handle(1, {"type": "pass"}), 1)).is_equal("not_eligible")
	assert_str(JSON.stringify(room.engine.state)).is_equal(before)
	registry.handle(2, {"type": "pass"})
	assert_str(room.engine.state.phase).is_equal(RulesEngine.PHASE_AWAITING_CHALLENGE)
	registry.handle(3, {"type": "pass"})
	assert_str(room.engine.state.phase).is_equal(RulesEngine.PHASE_AWAITING_ACTION)
	assert_int(room.engine.state.players[0].coins).is_equal(5)


# AC-8: disconnects do not crash the room

func test_disconnect_in_lobby_passes_host_and_keeps_room() -> void:
	var registry := _registry()
	_lobby(registry, 3)

	var outgoing: Array = registry.disconnect_peer(1)

	assert_int(registry.room_of(2).host).is_equal(2)
	assert_array(_for_peer(outgoing, 2)[0].names).is_equal(["P2", "P3"])
	assert_int(registry.room_count()).is_equal(1)


func test_disconnect_during_match_aborts_it_for_everyone_left() -> void:
	var registry := _registry()
	_started(registry, 3)

	var outgoing: Array = registry.disconnect_peer(2)

	assert_str(_for_peer(outgoing, 1)[0].type).is_equal("match_aborted")
	assert_str(_for_peer(outgoing, 3)[0].type).is_equal("match_aborted")
	assert_int(registry.room_count()).is_equal(0)
	assert_object(registry.room_of(1)).is_null()


func test_leave_room_confirms_to_the_leaver() -> void:
	var registry := _registry()
	_lobby(registry, 2)

	var outgoing: Array = registry.handle(2, {"type": "leave_room"})

	assert_str(_for_peer(outgoing, 2)[0].type).is_equal("left")
	assert_array(_for_peer(outgoing, 1)[0].names).is_equal(["P1"])
	assert_object(registry.room_of(2)).is_null()


func test_leaving_a_finished_match_does_not_abort_it() -> void:
	var registry := _registry()
	var room: Room = _started(registry, 2)
	room.engine.state.phase = RulesEngine.PHASE_GAME_OVER

	var outgoing: Array = registry.disconnect_peer(2)

	assert_int(_for_peer(outgoing, 1).size()).is_equal(1)
	assert_str(_for_peer(outgoing, 1)[0].type).is_equal("room")
	assert_int(registry.room_count()).is_equal(1)


func test_last_player_leaving_removes_the_room() -> void:
	var registry := _registry()
	registry.handle(1, {"type": "create_room", "name": "Ana"})

	registry.disconnect_peer(1)

	assert_int(registry.room_count()).is_equal(0)


# AC-9: two simulated clients play a scripted match to completion

func test_two_clients_play_scripted_match_and_final_views_match_the_rules_engine() -> void:
	var registry := _registry()
	var room: Room = _started(registry, 2)
	var latest: Dictionary = {1: room.view_for(1), 2: room.view_for(2)}
	var turns: int = 0

	while latest[1].phase != RulesEngine.PHASE_GAME_OVER and turns < 300:
		turns += 1
		var sent: bool = false
		for peer: int in [1, 2]:
			var intent: Dictionary = _scripted_intent(latest[peer])
			if intent.is_empty():
				continue
			var outgoing: Array = registry.handle(peer, intent)
			assert_str(_error_of(outgoing, peer)).is_equal("")
			for item: Dictionary in outgoing:
				latest[item.to] = item.message.view
			sent = true
			break
		assert_bool(sent).is_true()

	assert_str(latest[1].phase).is_equal(RulesEngine.PHASE_GAME_OVER)
	assert_int(latest[1].winner).is_equal(room.engine.get_winner())
	for peer: int in [1, 2]:
		for seat in range(2):
			var shown: Dictionary = latest[peer].players[seat]
			var truth: Dictionary = room.engine.state.players[seat]
			assert_int(shown.coins).is_equal(truth.coins)
			assert_array(shown.revealed).is_equal(truth.revealed)
			assert_bool(shown.alive).is_equal(truth.alive)


## A tiny client policy: Renda until 7 coins, then Golpe the other player;
## always give up the first card when owed an influence loss.
func _scripted_intent(view: Dictionary) -> Dictionary:
	var me: int = view.you.seat
	if view.phase == RulesEngine.PHASE_AWAITING_INFLUENCE_LOSS and view.loser == me:
		return {"type": "lose_influence", "card_index": 0}
	if view.phase == RulesEngine.PHASE_AWAITING_ACTION and view.current_player == me:
		if view.players[me].coins >= 7:
			return {"type": "action", "action": "golpe", "target": 1 - me}
		return {"type": "action", "action": "renda"}
	return {}
