extends GdUnitTestSuite
## Story 006: exile, spectators, winner, standings and the way back to the lobby.


func _registry() -> RoomRegistry:
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	return RoomRegistry.new(rng)


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


## A started match of [param count] players (peers 1..count, seats 0..count-1).
func _started(registry: RoomRegistry, count: int) -> Room:
	registry.handle(1, {"type": "create_room", "name": "P1"})
	var code: String = registry.room_of(1).code
	for peer in range(2, count + 1):
		registry.handle(peer, {"type": "join_room", "code": code, "name": "P%d" % peer})
	registry.handle(1, {"type": "start_match"})
	return registry.room_of(1)


func _hand(cards: Array) -> Array[String]:
	var hand: Array[String] = []
	for card: String in cards:
		hand.append(card)
	return hand


# AC-1: exiled players

func test_exiled_player_shows_both_cards_face_up_zero_coins_and_is_skipped() -> void:
	var registry := _registry()
	var room: Room = _started(registry, 3)
	room.engine.state.players[1].hand = _hand(["capitao"])
	room.engine.state.players[1].revealed = _hand(["duque"])
	room.engine.state.players[0].coins = 7
	registry.handle(1, {"type": "action", "action": "golpe", "target": 1})

	var outgoing: Array = registry.handle(2, {"type": "lose_influence", "card_index": 0})

	var shown: Dictionary = _for_peer(outgoing, 3)[0].view.players[1]
	assert_bool(shown.alive).is_false()
	assert_int(shown.influence).is_equal(0)
	assert_int(shown.coins).is_equal(0)
	assert_array(shown.revealed).is_equal(["duque", "capitao"])
	assert_int(room.engine.state.current_player).is_equal(2)
	assert_array(room.engine.state.elimination_order).is_equal([1])


# AC-2: spectators

func test_exiled_player_cannot_act_and_sees_no_hidden_card() -> void:
	var registry := _registry()
	var room: Room = _started(registry, 3)
	room.engine.state.players[0].hand = _hand(["condessa", "condessa"])
	room.engine.state.players[1].hand = _hand(["duque"])
	room.engine.state.players[1].revealed = _hand(["duque"])
	room.engine.state.players[2].hand = _hand(["capitao", "capitao"])
	room.engine.state.deck = _hand(["assassino", "assassino", "assassino"])
	room.engine.state.players[0].coins = 7
	registry.handle(1, {"type": "action", "action": "golpe", "target": 1})
	var seen: Array = _for_peer(registry.handle(2, {"type": "lose_influence", "card_index": 0}), 2)

	for outgoing: Array in [
			registry.handle(3, {"type": "action", "action": "renda"}),
			registry.handle(1, {"type": "action", "action": "taxas"}),
			registry.handle(3, {"type": "pass"})]:
		seen.append_array(_for_peer(outgoing, 2))

	assert_str(_error_of(registry.handle(2, {"type": "action", "action": "renda"}), 2)).is_equal("not_your_turn")
	assert_str(_error_of(registry.handle(2, {"type": "pass"}), 2)).is_not_empty()
	assert_str(_error_of(registry.handle(2, {"type": "challenge"}), 2)).is_not_empty()
	assert_array(room.view_for(2).you.hand).is_empty()
	var text: String = JSON.stringify(seen)
	assert_str(text).not_contains("condessa")
	assert_str(text).not_contains("capitao")


# AC-3: one remaining ends the match for everyone

func test_last_opponent_exiled_ends_match_and_every_client_gets_the_winner() -> void:
	var registry := _registry()
	var room: Room = _started(registry, 2)
	room.engine.state.players[1].hand = _hand(["capitao"])
	room.engine.state.players[0].coins = 7
	registry.handle(1, {"type": "action", "action": "golpe", "target": 1})

	var outgoing: Array = registry.handle(2, {"type": "lose_influence", "card_index": 0})

	for peer in [1, 2]:
		var view: Dictionary = _for_peer(outgoing, peer)[0].view
		assert_str(view.phase).is_equal(RulesEngine.PHASE_GAME_OVER)
		assert_int(view.winner).is_equal(0)
	assert_bool(room.engine.is_game_over()).is_true()


# AC-4: standings

func test_standings_list_winner_first_then_last_exiled_first() -> void:
	var registry := _registry()
	var room: Room = _started(registry, 3)
	room.engine.state.players[0].hand = _hand(["duque", "condessa"])
	room.engine.state.players[1].hand = _hand(["capitao"])
	room.engine.state.players[2].hand = _hand(["embaixador"])
	room.engine.state.players[0].coins = 14
	registry.handle(1, {"type": "action", "action": "golpe", "target": 1})
	registry.handle(2, {"type": "lose_influence", "card_index": 0})
	registry.handle(3, {"type": "action", "action": "renda"})
	registry.handle(1, {"type": "action", "action": "golpe", "target": 2})

	var outgoing: Array = registry.handle(3, {"type": "lose_influence", "card_index": 0})

	var standings: Array = _for_peer(outgoing, 2)[0].view.standings
	assert_array(standings.map(func(entry: Dictionary) -> int: return entry.seat)).is_equal([0, 2, 1])
	assert_array(standings.map(func(entry: Dictionary) -> int: return entry.rank)).is_equal([1, 2, 3])
	assert_array(standings[0].cards).contains_exactly_in_any_order(["duque", "condessa"])
	assert_array(standings[1].cards).is_equal(["embaixador"])
	assert_array(standings[2].cards).is_equal(["capitao"])
	assert_str(standings[0].name).is_equal("P1")


func test_standings_are_empty_while_the_match_is_running() -> void:
	var registry := _registry()
	var room: Room = _started(registry, 3)

	assert_array(room.view_for(1).standings).is_empty()


# AC-5: back to the lobby

func test_returning_from_a_finished_match_reopens_the_same_room_for_a_new_match() -> void:
	var registry := _registry()
	var room: Room = _started(registry, 2)
	room.engine.state.players[1].hand = _hand(["capitao"])
	room.engine.state.players[0].coins = 7
	registry.handle(1, {"type": "action", "action": "golpe", "target": 1})
	registry.handle(2, {"type": "lose_influence", "card_index": 0})
	var code: String = room.code

	var returned: Array = registry.handle(2, {"type": "return_to_lobby"})

	var message: Dictionary = _for_peer(returned, 2)[0]
	assert_str(message.type).is_equal("room")
	assert_str(message.code).is_equal(code)
	assert_array(message.names).is_equal(["P1", "P2"])
	assert_bool(message.started).is_false()
	assert_int(_for_peer(returned, 1).size()).is_equal(0)
	assert_str(_error_of(registry.handle(1, {"type": "return_to_lobby"}), 1)).is_equal("")
	var restarted: Array = registry.handle(1, {"type": "start_match"})
	assert_str(_for_peer(restarted, 2)[0].view.phase).is_equal(RulesEngine.PHASE_AWAITING_ACTION)
	assert_str(registry.room_of(1).code).is_equal(code)


func test_member_leaving_a_finished_match_resets_the_room_without_breaking_views() -> void:
	var registry := _registry()
	var room: Room = _started(registry, 3)
	room.engine.state.players[1].hand = _hand(["capitao"])
	room.engine.state.players[2].hand = _hand(["embaixador"])
	room.engine.state.players[0].coins = 14
	registry.handle(1, {"type": "action", "action": "golpe", "target": 1})
	registry.handle(2, {"type": "lose_influence", "card_index": 0})
	registry.handle(3, {"type": "action", "action": "renda"})
	registry.handle(1, {"type": "action", "action": "golpe", "target": 2})
	registry.handle(3, {"type": "lose_influence", "card_index": 0})

	var outgoing: Array = registry.disconnect_peer(2)

	assert_bool(room.started).is_false()
	assert_str(_for_peer(outgoing, 1)[0].type).is_equal("room")
	assert_array(_for_peer(outgoing, 1)[0].names).is_equal(["P1", "P3"])
	assert_bool(_for_peer(outgoing, 1)[0].started).is_false()
	var restarted: Array = registry.handle(1, {"type": "start_match"})
	assert_int(_for_peer(restarted, 3)[0].view.you.hand.size()).is_equal(2)
	assert_str(_for_peer(restarted, 3)[0].view.players[1].name).is_equal("P3")


func test_return_to_lobby_is_refused_while_a_match_is_running() -> void:
	var registry := _registry()
	_started(registry, 2)

	var outgoing: Array = registry.handle(1, {"type": "return_to_lobby"})

	assert_str(_error_of(outgoing, 1)).is_equal("match_not_over")
	assert_bool(registry.room_of(1).started).is_true()
