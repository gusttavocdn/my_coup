extends GdUnitTestSuite
## Story 006: whole matches of 3 to 6 players, played by random bots through the
## server layer, exercise every MVP rule from lobby to result.

const SEEDS: Array[int] = [1, 2, 3, 4]


func test_random_bot_matches_of_three_to_six_players_finish_cleanly() -> void:
	var failures: Array[String] = []
	var unfinished: int = 0

	for player_count in range(3, 7):
		for seed_value in SEEDS:
			var match_run := BotMatch.new()
			match_run.play(player_count, seed_value)
			for failure in match_run.failures:
				failures.append("%d players, seed %d: %s" % [player_count, seed_value, failure])
			if not match_run.finished:
				unfinished += 1

	assert_array(failures).is_empty()
	assert_int(unfinished).is_equal(0)


func test_random_bot_matches_exercise_every_mvp_rule() -> void:
	var seen: Dictionary = {}

	for player_count in range(3, 7):
		for seed_value in SEEDS:
			var match_run := BotMatch.new()
			match_run.play(player_count, seed_value)
			for type: String in match_run.event_counts:
				seen[type] = int(seen.get(type, 0)) + int(match_run.event_counts[type])

	for expected: String in ["challenge_declared", "challenge_lost", "challenge_won", "block_declared",
			"block_failed", "action_failed", "coins_stolen", "exchange_completed", "influence_lost",
			"player_eliminated", "game_over"]:
		assert_bool(seen.has(expected)).override_failure_message("no %s event in 16 matches" % expected).is_true()


func test_same_seed_plays_the_same_match() -> void:
	var first := BotMatch.new()
	var second := BotMatch.new()

	first.play(4, 7)
	second.play(4, 7)

	assert_int(first.steps).is_equal(second.steps)
	assert_dict(first.event_counts).is_equal(second.event_counts)
