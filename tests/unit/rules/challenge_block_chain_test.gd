extends GdUnitTestSuite
## Story 002: challenge and block chain of the Coup rules core.


## Builds a seeded match with the given face-down hands (one Array per seat).
func _engine(player_count: int, hands: Array) -> RulesEngine:
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var engine := RulesEngine.new()
	engine.setup(player_count, rng)
	for seat in range(hands.size()):
		var hand: Array[String] = []
		for card: String in hands[seat]:
			hand.append(card)
		engine.state.players[seat].hand = hand
	return engine


## Gives [param seat] exactly [param coins], taking or returning them via the treasury.
func _set_coins(engine: RulesEngine, seat: int, coins: int) -> void:
	var delta: int = coins - int(engine.state.players[seat].coins)
	engine.state.players[seat].coins = coins
	engine.state.treasury -= delta


func _total_coins(engine: RulesEngine) -> int:
	var total: int = engine.state.treasury
	for player: Dictionary in engine.state.players:
		total += player.coins
	return total


func _total_cards(engine: RulesEngine) -> int:
	var total: int = engine.state.deck.size()
	for player: Dictionary in engine.state.players:
		total += player.hand.size() + player.revealed.size()
	return total


# AC-1: response window for every other living player

func test_taxas_declared_opens_challenge_window_for_other_players() -> void:
	var engine := _engine(3, [["duque", "duque"], ["condessa", "capitao"], ["assassino", "assassino"]])

	engine.submit_action(0, "taxas")

	assert_str(engine.state.phase).is_equal(RulesEngine.PHASE_AWAITING_CHALLENGE)
	assert_array(engine.state.window.eligible).is_equal([1, 2])


func test_all_players_pass_challenge_window_resolves_action() -> void:
	var engine := _engine(3, [["duque", "duque"], ["condessa", "capitao"], ["assassino", "assassino"]])
	engine.submit_action(0, "taxas")

	engine.pass_response(1)
	engine.pass_response(2)

	assert_int(engine.state.players[0].coins).is_equal(5)
	assert_int(engine.state.current_player).is_equal(1)


func test_response_from_claimant_or_repeat_is_rejected() -> void:
	var engine := _engine(3, [["duque", "duque"], ["condessa", "capitao"], ["assassino", "assassino"]])
	engine.submit_action(0, "taxas")
	engine.pass_response(1)

	assert_str(engine.pass_response(0).error).is_equal("not_eligible")
	assert_str(engine.pass_response(1).error).is_equal("already_responded")


# AC-2: challenge outcomes

func test_true_claim_challenged_makes_challenger_lose_and_action_proceed() -> void:
	var engine := _engine(3, [["duque", "duque"], ["condessa", "capitao"], ["assassino", "assassino"]])
	engine.submit_action(0, "taxas")

	engine.challenge(1)

	assert_str(engine.state.phase).is_equal(RulesEngine.PHASE_AWAITING_INFLUENCE_LOSS)
	assert_int(engine.state.loser).is_equal(1)
	assert_int(_total_cards(engine)).is_equal(15)
	engine.choose_influence_to_lose(1, 0)
	assert_int(engine.state.players[0].coins).is_equal(5)
	assert_int(engine.state.players[0].hand.size()).is_equal(2)
	assert_int(_total_cards(engine)).is_equal(15)


func test_bluff_challenged_makes_claimant_lose_and_refunds_cost() -> void:
	var engine := _engine(3, [["capitao", "capitao"], ["condessa", "capitao"], ["assassino", "assassino"]])
	_set_coins(engine, 0, 3)
	engine.submit_action(0, "assassinar", 1)
	assert_int(engine.state.players[0].coins).is_equal(0)

	engine.challenge(2)
	assert_int(engine.state.loser).is_equal(0)
	engine.choose_influence_to_lose(0, 0)

	assert_int(engine.state.players[0].coins).is_equal(3)
	assert_int(engine.state.players[1].hand.size()).is_equal(2)
	assert_int(engine.state.current_player).is_equal(1)
	assert_int(_total_coins(engine)).is_equal(54)


# AC-3 and AC-4: block windows and who may block

func test_ajuda_externa_opens_block_window_for_any_other_player() -> void:
	var engine := _engine(3, [["assassino", "assassino"], ["capitao", "capitao"], ["duque", "duque"]])

	engine.submit_action(0, "ajuda_externa")

	assert_str(engine.state.phase).is_equal(RulesEngine.PHASE_AWAITING_BLOCK)
	assert_array(engine.state.window.eligible).is_equal([1, 2])


func test_ajuda_externa_unblocked_gives_two_coins() -> void:
	var engine := _engine(3, [["assassino", "assassino"], ["capitao", "capitao"], ["duque", "duque"]])
	engine.submit_action(0, "ajuda_externa")

	engine.pass_response(1)
	engine.pass_response(2)

	assert_int(engine.state.players[0].coins).is_equal(4)
	assert_int(engine.state.current_player).is_equal(1)


func test_assassinar_block_window_is_target_only_and_condessa_only() -> void:
	var engine := _engine(3, [["assassino", "duque"], ["condessa", "capitao"], ["duque", "duque"]])
	_set_coins(engine, 0, 3)
	engine.submit_action(0, "assassinar", 1)
	engine.pass_response(1)
	engine.pass_response(2)

	assert_str(engine.state.phase).is_equal(RulesEngine.PHASE_AWAITING_BLOCK)
	assert_array(engine.state.window.eligible).is_equal([1])
	assert_str(engine.block(1, "duque").error).is_equal("invalid_block_character")
	assert_bool(engine.block(1, "condessa").ok).is_true()


func test_extorquir_block_window_is_target_only_with_embaixador_or_capitao() -> void:
	var engine := _engine(3, [["capitao", "duque"], ["embaixador", "capitao"], ["duque", "duque"]])
	engine.submit_action(0, "extorquir", 1)
	engine.pass_response(1)
	engine.pass_response(2)

	assert_array(engine.state.window.eligible).is_equal([1])
	assert_str(engine.pass_response(2).error).is_equal("not_eligible")
	assert_bool(engine.block(1, "capitao").ok).is_true()


# AC-5: block challenge outcomes

func test_true_block_stands_when_unchallenged_and_action_fails() -> void:
	var engine := _engine(3, [["assassino", "duque"], ["condessa", "capitao"], ["duque", "duque"]])
	_set_coins(engine, 0, 3)
	engine.submit_action(0, "assassinar", 1)
	engine.pass_response(1)
	engine.pass_response(2)
	engine.block(1, "condessa")

	engine.pass_response(0)
	engine.pass_response(2)

	assert_int(engine.state.players[1].hand.size()).is_equal(2)
	assert_int(engine.state.current_player).is_equal(1)


func test_bluffed_block_caught_lets_action_proceed() -> void:
	var engine := _engine(3, [["assassino", "duque"], ["capitao", "capitao"], ["duque", "duque"]])
	engine.submit_action(0, "ajuda_externa")
	engine.block(1, "duque")

	engine.challenge(2)
	assert_int(engine.state.loser).is_equal(1)
	engine.choose_influence_to_lose(1, 0)

	assert_int(engine.state.players[0].coins).is_equal(4)
	assert_int(engine.state.current_player).is_equal(1)


func test_true_block_challenged_makes_challenger_lose_and_action_fail() -> void:
	var engine := _engine(3, [["assassino", "duque"], ["condessa", "capitao"], ["duque", "duque"]])
	_set_coins(engine, 0, 3)
	engine.submit_action(0, "assassinar", 1)
	engine.pass_response(1)
	engine.pass_response(2)
	engine.block(1, "condessa")

	engine.challenge(0)
	assert_int(engine.state.loser).is_equal(0)
	engine.choose_influence_to_lose(0, 0)

	assert_int(engine.state.players[1].hand.size()).is_equal(2)
	assert_int(engine.state.current_player).is_equal(1)
	assert_int(_total_cards(engine)).is_equal(15)


# AC-6: coins on blocked versus challenged actions

func test_blocked_action_keeps_its_cost_spent() -> void:
	var engine := _engine(3, [["assassino", "duque"], ["condessa", "capitao"], ["duque", "duque"]])
	_set_coins(engine, 0, 3)
	engine.submit_action(0, "assassinar", 1)
	engine.pass_response(1)
	engine.pass_response(2)
	engine.block(1, "condessa")
	engine.pass_response(0)
	engine.pass_response(2)

	assert_int(engine.state.players[0].coins).is_equal(0)
	assert_int(_total_coins(engine)).is_equal(54)


# AC-7: Assassin double danger

func test_challenging_true_assassin_then_assassination_costs_target_two_influences() -> void:
	var engine := _engine(3, [["assassino", "duque"], ["condessa", "capitao"], ["duque", "duque"]])
	_set_coins(engine, 0, 3)
	engine.submit_action(0, "assassinar", 1)
	engine.pass_response(2)

	engine.challenge(1)
	engine.choose_influence_to_lose(1, 1)
	assert_str(engine.state.phase).is_equal(RulesEngine.PHASE_AWAITING_BLOCK)
	engine.pass_response(1)
	assert_int(engine.state.loser).is_equal(1)
	engine.choose_influence_to_lose(1, 0)

	assert_bool(engine.state.players[1].alive).is_false()
	assert_int(engine.state.current_player).is_equal(2)


func test_bluffed_condessa_block_caught_then_assassination_costs_target_two_influences() -> void:
	var engine := _engine(3, [["assassino", "duque"], ["capitao", "capitao"], ["duque", "duque"]])
	_set_coins(engine, 0, 3)
	engine.submit_action(0, "assassinar", 1)
	engine.pass_response(1)
	engine.pass_response(2)
	engine.block(1, "condessa")

	engine.challenge(0)
	engine.choose_influence_to_lose(1, 0)
	assert_int(engine.state.loser).is_equal(1)
	engine.choose_influence_to_lose(1, 0)

	assert_bool(engine.state.players[1].alive).is_false()
	assert_int(engine.state.players[0].coins).is_equal(0)


# AC-8: elimination mid-chain

func test_action_against_player_eliminated_by_lost_challenge_is_dropped() -> void:
	var engine := _engine(3, [["assassino", "duque"], ["capitao", "condessa"], ["duque", "duque"]])
	_set_coins(engine, 0, 3)
	engine.state.players[1].hand = ["capitao"] as Array[String]
	engine.submit_action(0, "assassinar", 1)
	engine.pass_response(2)

	engine.challenge(1)
	engine.choose_influence_to_lose(1, 0)

	assert_bool(engine.state.players[1].alive).is_false()
	assert_str(engine.state.phase).is_equal(RulesEngine.PHASE_AWAITING_ACTION)
	assert_int(engine.state.current_player).is_equal(2)


func test_lost_challenge_that_eliminates_last_opponent_ends_match() -> void:
	var engine := _engine(2, [["duque", "duque"], ["capitao", "capitao"]])
	engine.state.players[1].hand = ["capitao"] as Array[String]
	engine.submit_action(0, "taxas")

	engine.challenge(1)
	engine.choose_influence_to_lose(1, 0)

	assert_bool(engine.is_game_over()).is_true()
	assert_int(engine.get_winner()).is_equal(0)


# AC-9: challenges before any effect; AC-10: Renda and Golpe have no windows

func test_declared_character_action_has_no_effect_until_windows_close() -> void:
	var engine := _engine(3, [["duque", "duque"], ["condessa", "capitao"], ["assassino", "assassino"]])

	engine.submit_action(0, "taxas")

	assert_int(engine.state.players[0].coins).is_equal(2)
	assert_str(engine.state.pending_action.action).is_equal("taxas")


func test_renda_resolves_without_response_window() -> void:
	var engine := _engine(3, [["duque", "duque"], ["duque", "duque"], ["duque", "duque"]])

	engine.submit_action(0, "renda")

	assert_str(engine.state.phase).is_equal(RulesEngine.PHASE_AWAITING_ACTION)
	assert_int(engine.state.players[0].coins).is_equal(3)


func test_golpe_resolves_without_challenge_or_block_window() -> void:
	var engine := _engine(3, [["duque", "duque"], ["duque", "duque"], ["duque", "duque"]])
	_set_coins(engine, 0, 7)

	engine.submit_action(0, "golpe", 1)

	assert_str(engine.state.phase).is_equal(RulesEngine.PHASE_AWAITING_INFLUENCE_LOSS)
	assert_int(engine.state.loser).is_equal(1)


# AC-11 (story AC "pending choice"): influence lost to a challenge is the owner's choice

func test_lost_challenge_waits_for_owner_to_choose_card() -> void:
	var engine := _engine(3, [["duque", "duque"], ["condessa", "capitao"], ["assassino", "assassino"]])
	engine.submit_action(0, "taxas")
	engine.challenge(1)

	assert_str(engine.choose_influence_to_lose(2, 0).error).is_equal("not_your_loss")
	assert_str(engine.choose_influence_to_lose(1, 9).error).is_equal("invalid_card")
	assert_bool(engine.choose_influence_to_lose(1, 1).ok).is_true()
	assert_str(engine.state.players[1].revealed[0]).is_equal("capitao")
