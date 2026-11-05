extends GdUnitTestSuite
## Story 016: server limits (room cap, connection caps, message rate, idle cleanup,
## logging) driven with a fake clock and no sockets.

var _now_ms: Array[int] = [0]


func _config(overrides: Dictionary = {}) -> ServerConfig:
	var config := ServerConfig.new()
	for field: String in overrides:
		config.set(field, overrides[field])
	return config


func _registry(config: ServerConfig) -> RoomRegistry:
	_now_ms[0] = 0
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	return RoomRegistry.new(rng, func() -> int: return _now_ms[0], RulesConfig.RESPONSE_SECONDS, config)


func _server(config: ServerConfig) -> GameServer:
	var server: GameServer = auto_free(GameServer.new())
	server.config = config
	return server


func _error_of(messages: Array[Dictionary], peer: int) -> String:
	for item: Dictionary in messages:
		if item.to == peer and item.message.type == "error":
			return item.message.error
	return ""


func _intent() -> Dictionary:
	return {"type": "leave_room"}


func test_room_cap_reached_create_room_answers_server_busy() -> void:
	var registry := _registry(_config({"max_rooms": 2}))
	registry.handle(1, {"type": "create_room", "name": "A"})
	registry.handle(2, {"type": "create_room", "name": "B"})

	var messages: Array[Dictionary] = registry.handle(3, {"type": "create_room", "name": "C"})

	assert_str(_error_of(messages, 3)).is_equal("server_busy")
	assert_int(registry.room_count()).is_equal(2)


func test_room_closed_frees_a_slot_for_new_room() -> void:
	var registry := _registry(_config({"max_rooms": 1}))
	registry.handle(1, {"type": "create_room", "name": "A"})
	registry.disconnect_peer(1)

	var messages: Array[Dictionary] = registry.handle(2, {"type": "create_room", "name": "B"})

	assert_str(_error_of(messages, 2)).is_empty()
	assert_int(registry.room_count()).is_equal(1)


func test_total_cap_reached_connection_refused() -> void:
	var server := _server(_config({"max_connections": 2, "max_connections_per_ip": 5}))
	assert_str(server.admit_connection(1, "10.0.0.1")).is_empty()
	assert_str(server.admit_connection(2, "10.0.0.2")).is_empty()

	assert_str(server.admit_connection(3, "10.0.0.3")).is_equal("server_full")

	server.release_peer(1)
	assert_str(server.admit_connection(3, "10.0.0.3")).is_empty()


func test_ip_cap_reached_third_connection_from_same_ip_refused() -> void:
	var server := _server(_config({"max_connections_per_ip": 2}))
	assert_str(server.admit_connection(1, "10.0.0.1")).is_empty()
	assert_str(server.admit_connection(2, "10.0.0.1")).is_empty()

	assert_str(server.admit_connection(3, "10.0.0.1")).is_equal("too_many_connections_from_ip")
	assert_str(server.admit_connection(4, "10.0.0.2")).is_empty()


func test_rate_limit_exceeded_first_error_then_disconnect_on_repeat() -> void:
	var server := _server(_config({"max_messages_per_second": 2}))
	server.admit_connection(1, "10.0.0.1")
	assert_bool(server.check_message(1, _intent(), 20, 0).ok).is_true()
	assert_bool(server.check_message(1, _intent(), 20, 100).ok).is_true()

	var first: Dictionary = server.check_message(1, _intent(), 20, 200)
	var second: Dictionary = server.check_message(1, _intent(), 20, 300)

	assert_str(first.error).is_equal("rate_limited")
	assert_bool(first.disconnect).is_false()
	assert_bool(second.disconnect).is_true()


func test_rate_limit_window_passes_counter_resets() -> void:
	var server := _server(_config({"max_messages_per_second": 1}))
	server.admit_connection(1, "10.0.0.1")
	assert_bool(server.check_message(1, _intent(), 20, 0).ok).is_true()
	assert_bool(server.check_message(1, _intent(), 20, 500).ok).is_false()

	assert_bool(server.check_message(1, _intent(), 20, 1500).ok).is_true()


func test_strike_expires_after_window_so_late_violation_is_only_an_error() -> void:
	var server := _server(_config({"max_messages_per_second": 1, "rate_strike_window_seconds": 10}))
	server.admit_connection(1, "10.0.0.1")
	server.check_message(1, _intent(), 20, 0)
	assert_bool(server.check_message(1, _intent(), 20, 100).disconnect).is_false()
	server.check_message(1, _intent(), 20, 20000)

	var late: Dictionary = server.check_message(1, _intent(), 20, 20100)

	assert_bool(late.ok).is_false()
	assert_bool(late.disconnect).is_false()


func test_oversized_message_rejected_with_error() -> void:
	var server := _server(_config({"max_message_bytes": 100}))
	server.admit_connection(1, "10.0.0.1")

	var verdict: Dictionary = server.check_message(1, _intent(), 101, 0)

	assert_bool(verdict.ok).is_false()
	assert_str(verdict.error).is_equal("message_too_large")


func test_malformed_message_rejected_with_error() -> void:
	var server := _server(_config())
	server.admit_connection(1, "10.0.0.1")

	var verdict: Dictionary = server.check_message(1, {"name": "no type"}, 20, 0)

	assert_bool(verdict.ok).is_false()
	assert_str(verdict.error).is_equal("invalid_intent")


func test_rate_limited_peer_other_peer_unaffected() -> void:
	var server := _server(_config({"max_messages_per_second": 1}))
	server.admit_connection(1, "10.0.0.1")
	server.admit_connection(2, "10.0.0.2")
	server.check_message(1, _intent(), 20, 0)
	server.check_message(1, _intent(), 20, 10)
	server.check_message(1, _intent(), 20, 20)

	assert_bool(server.check_message(2, _intent(), 20, 30).ok).is_true()


func test_rate_limited_peer_room_of_others_keeps_running() -> void:
	var server := _server(_config({"max_messages_per_second": 1}))
	var registry := _registry(_config())
	server.admit_connection(1, "10.0.0.1")
	server.admit_connection(3, "10.0.0.3")
	registry.handle(1, {"type": "create_room", "name": "A"})
	registry.handle(3, {"type": "create_room", "name": "C"})
	server.check_message(1, _intent(), 20, 0)
	server.check_message(1, _intent(), 20, 10)
	server.check_message(1, _intent(), 20, 20)

	registry.disconnect_peer(1)

	assert_object(registry.room_of(3)).is_not_null()


func test_idle_lobby_removed_after_idle_minutes() -> void:
	var registry := _registry(_config({"idle_minutes": 5}))
	registry.handle(1, {"type": "create_room", "name": "A"})

	_now_ms[0] = 5 * 60 * 1000
	var messages: Array[Dictionary] = registry.tick()

	assert_int(registry.room_count()).is_equal(0)
	assert_object(registry.room_of(1)).is_null()
	assert_str(messages[0].message.reason).is_equal("idle")
	assert_int(messages[0].to).is_equal(1)


func test_active_room_not_removed_before_idle_minutes() -> void:
	var registry := _registry(_config({"idle_minutes": 5}))
	registry.handle(1, {"type": "create_room", "name": "A"})
	_now_ms[0] = 4 * 60 * 1000
	registry.handle(1, {"type": "leave_room"})
	registry.handle(1, {"type": "create_room", "name": "A"})

	_now_ms[0] = 8 * 60 * 1000
	registry.tick()

	assert_int(registry.room_count()).is_equal(1)


func test_finished_match_room_removed_when_members_leave() -> void:
	var registry := _registry(_config())
	registry.handle(1, {"type": "create_room", "name": "A"})
	var code: String = registry.room_of(1).code
	registry.handle(2, {"type": "join_room", "code": code, "name": "B"})
	registry.handle(1, {"type": "start_match"})
	var room: Room = registry.room_of(1)
	room.engine.state.phase = RulesEngine.PHASE_GAME_OVER

	registry.disconnect_peer(1)
	registry.disconnect_peer(2)

	assert_int(registry.room_count()).is_equal(0)


func test_room_events_are_reported_for_the_log() -> void:
	var registry := _registry(_config())
	registry.handle(1, {"type": "create_room", "name": "A"})
	registry.handle(1, {"type": "leave_room"})

	var names: Array = registry.drain_events().map(func(entry: Dictionary) -> String: return entry.event)

	assert_array(names).is_equal(["room_created", "player_joined", "player_left", "room_closed"])
	assert_array(registry.drain_events()).is_empty()


func test_log_line_player_name_is_escaped() -> void:
	var line: String = GameServer.format_log_line("player_joined", {"name": "x\nroom_closed room=ZZZZ"})

	assert_bool(line.contains("\n")).is_false()
	assert_str(line).contains("x\\nroom_closed")


func test_log_line_long_player_text_is_cut() -> void:
	var line: String = GameServer.format_log_line("player_joined", {"name": "a".repeat(500)})

	assert_int(line.length()).is_less(GameServer.LOG_TEXT_LIMIT + 40)


func test_config_cli_overrides_env_overrides_default() -> void:
	var config: ServerConfig = ServerConfig.from_sources(
			PackedStringArray(["--max-rooms=7", "--bind=127.0.0.1"]),
			{"COUP_MAX_ROOMS": "9", "COUP_PORT": "9100", "COUP_IDLE_MINUTES": "oops"})

	assert_int(config.max_rooms).is_equal(7)
	assert_int(config.port).is_equal(9100)
	assert_str(config.bind).is_equal("127.0.0.1")
	assert_int(config.idle_minutes).is_equal(ServerConfig.DEFAULTS.idle_minutes)


func test_config_log_line_lists_every_option() -> void:
	var line: String = ServerConfig.new().to_log_line()

	for field: String in ServerConfig.DEFAULTS:
		assert_str(line).contains("%s=" % field)
