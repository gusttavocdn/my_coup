extends GdUnitTestSuite
## Story 010: server-side deadline of response windows, driven with a fake clock.

const TOTAL_MS: int = 8000

var _now_ms: Array[int] = [0]


func _registry() -> RoomRegistry:
	_now_ms[0] = 0
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	# Idle cleanup is covered by limits_test.gd; here the clock jumps far ahead on purpose.
	var config := ServerConfig.new()
	config.idle_minutes = 1000000
	return RoomRegistry.new(rng, func() -> int: return _now_ms[0], RulesConfig.RESPONSE_SECONDS, config)


## A started 3-player match (peers 1..3 = seats 0..2) with seat 0 to act.
func _started(registry: RoomRegistry) -> Room:
	registry.handle(1, {"type": "create_room", "name": "P1"})
	var code: String = registry.room_of(1).code
	for peer in [2, 3]:
		registry.handle(peer, {"type": "join_room", "code": code, "name": "P%d" % peer})
	registry.handle(1, {"type": "start_match"})
	var room: Room = registry.room_of(1)
	room.engine.state.current_player = 0
	room.engine.state.players[0].coins = 3
	return room


func _event_types(messages: Array[Dictionary], peer: int) -> Array:
	for item: Dictionary in messages:
		if item.to == peer:
			return item.message.events.map(func(event: Dictionary) -> String: return event.type)
	return []


func _timeouts(messages: Array[Dictionary], peer: int) -> Array:
	for item: Dictionary in messages:
		if item.to == peer:
			return item.message.events.filter(func(event: Dictionary) -> bool: return event.type == "response_timeout") \
					.map(func(event: Dictionary) -> int: return event.player)
	return []


func test_response_time_is_data_driven() -> void:
	assert_float(RulesConfig.RESPONSE_SECONDS).is_equal(8.0)


func test_nobody_responds_everyone_passes_at_the_deadline() -> void:
	var registry := _registry()
	var room := _started(registry)
	registry.handle(1, {"type": "action", "action": "taxas"})
	assert_str(room.engine.state.phase).is_equal(RulesEngine.PHASE_AWAITING_CHALLENGE)

	_now_ms[0] = TOTAL_MS - 1
	assert_array(registry.tick()).is_empty()

	_now_ms[0] = TOTAL_MS
	var messages: Array[Dictionary] = registry.tick()

	assert_array(_timeouts(messages, 1)).is_equal([1, 2])
	assert_int(messages.size()).is_equal(3)
	assert_dict(room.view_for(1).window).is_empty()
	assert_int(room.engine.state.current_player).is_equal(1)
	assert_int(room.engine.state.players[0].coins).is_equal(6)


func test_player_who_answered_is_not_timed_out() -> void:
	var registry := _registry()
	var room := _started(registry)
	registry.handle(1, {"type": "action", "action": "taxas"})
	_now_ms[0] = 3000
	registry.handle(2, {"type": "pass"})

	_now_ms[0] = TOTAL_MS
	var messages: Array[Dictionary] = registry.tick()

	assert_array(_timeouts(messages, 1)).is_equal([2])
	assert_int(room.engine.state.current_player).is_equal(1)


func test_follow_up_window_gets_a_fresh_deadline() -> void:
	var registry := _registry()
	var room := _started(registry)
	registry.handle(1, {"type": "action", "action": "assassinar", "target": 1})
	_now_ms[0] = TOTAL_MS
	registry.tick()
	# The challenge window closed into the target's block window.
	assert_str(room.engine.state.phase).is_equal(RulesEngine.PHASE_AWAITING_BLOCK)
	assert_float(room.view_for(2).window.seconds_left).is_equal(8.0)

	_now_ms[0] = TOTAL_MS + 1
	assert_array(registry.tick()).is_empty()

	_now_ms[0] = 2 * TOTAL_MS
	registry.tick()
	assert_dict(room.view_for(1).window).is_empty()


func test_view_carries_remaining_time_only_while_a_window_is_open() -> void:
	var registry := _registry()
	var room := _started(registry)
	assert_dict(room.view_for(1).window).is_empty()

	registry.handle(1, {"type": "action", "action": "taxas"})
	_now_ms[0] = 3000
	var window: Dictionary = room.view_for(2).window
	assert_float(window.total_seconds).is_equal(8.0)
	assert_float(window.seconds_left).is_equal(5.0)


func test_challenge_before_the_deadline_ends_the_window_and_the_deadline() -> void:
	var registry := _registry()
	var room := _started(registry)
	room.engine.state.players[0].hand = ["duque", "condessa"] as Array[String]
	registry.handle(1, {"type": "action", "action": "taxas"})
	_now_ms[0] = 3000
	registry.handle(2, {"type": "challenge"})
	assert_dict(room.engine.state.window).is_empty()

	_now_ms[0] = 10 * TOTAL_MS
	assert_array(registry.tick()).is_empty()


func test_tick_outside_a_window_is_a_no_op() -> void:
	var registry := _registry()
	var room := _started(registry)
	_now_ms[0] = 100 * TOTAL_MS
	assert_array(registry.tick()).is_empty()

	registry.handle(1, {"type": "action", "action": "renda"})
	_now_ms[0] = 200 * TOTAL_MS
	assert_array(registry.tick()).is_empty()
	assert_int(room.engine.state.current_player).is_equal(1)


func test_own_turn_never_times_out() -> void:
	var registry := _registry()
	var room := _started(registry)
	_now_ms[0] = 1000 * TOTAL_MS
	assert_array(registry.tick()).is_empty()
	assert_int(room.engine.state.current_player).is_equal(0)
