extends GdUnitTestSuite
## Story 003: Embaixador exchange and challenge-win reshuffle.


## Builds a match whose hands are [param hands] and whose next draws are
## [param draws] (in draw order); every other card of the 15 forms the rest of
## the Court deck, so the card multiset stays intact.
func _engine(player_count: int, hands: Array, draws: Array, seed_value: int = 3) -> RulesEngine:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var engine := RulesEngine.new()
	engine.setup(player_count, rng)

	var remaining: Array[String] = []
	for character: String in RulesConfig.CHARACTERS:
		for _copy in range(RulesConfig.COPIES_PER_CHARACTER):
			remaining.append(character)
	for seat in range(hands.size()):
		var hand: Array[String] = []
		for card: String in hands[seat]:
			hand.append(card)
			remaining.erase(card)
		engine.state.players[seat].hand = hand
	for card: String in draws:
		remaining.erase(card)
	var deck: Array[String] = remaining
	for index in range(draws.size() - 1, -1, -1):
		deck.append(draws[index])
	engine.state.deck = deck
	return engine


## All cards in play (deck, hands, revealed) sorted, to compare against the full set.
func _all_cards_sorted(engine: RulesEngine) -> Array:
	var cards: Array = engine.state.deck.duplicate()
	for player: Dictionary in engine.state.players:
		cards.append_array(player.hand)
		cards.append_array(player.revealed)
	cards.sort()
	return cards


func _full_set_sorted() -> Array:
	var cards: Array = []
	for character: String in RulesConfig.CHARACTERS:
		for _copy in range(RulesConfig.COPIES_PER_CHARACTER):
			cards.append(character)
	cards.sort()
	return cards


## Player 0 declares Trocar and nobody challenges; returns the engine awaiting the exchange.
func _declared_exchange(draws: Array) -> RulesEngine:
	var engine := _engine(3, [["embaixador", "duque"], ["condessa", "capitao"], ["assassino", "assassino"]], draws)
	engine.submit_action(0, "trocar")
	engine.pass_response(1)
	engine.pass_response(2)
	return engine


# AC-1: draw 2 and keep any combination

func test_trocar_unchallenged_draws_two_cards_from_court_deck() -> void:
	var engine := _engine(3, [["embaixador", "duque"], ["condessa", "capitao"], ["assassino", "assassino"]],
			["capitao", "embaixador"])
	var deck_before: int = engine.state.deck.size()
	engine.submit_action(0, "trocar")

	engine.pass_response(1)
	engine.pass_response(2)

	assert_str(engine.state.phase).is_equal(RulesEngine.PHASE_AWAITING_EXCHANGE)
	assert_array(engine.state.exchange.drawn).is_equal(["capitao", "embaixador"])
	assert_int(engine.state.deck.size()).is_equal(deck_before - 2)


func test_exchange_can_keep_both_drawn_cards() -> void:
	var engine := _declared_exchange(["capitao", "embaixador"])

	var result: Dictionary = engine.choose_exchange(0, [2, 3])

	assert_bool(result.ok).is_true()
	assert_array(engine.state.players[0].hand).is_equal(["capitao", "embaixador"])
	assert_int(engine.state.current_player).is_equal(1)


func test_exchange_can_keep_original_hand_and_return_both_drawn() -> void:
	var engine := _declared_exchange(["capitao", "embaixador"])

	engine.choose_exchange(0, [0, 1])

	assert_array(engine.state.players[0].hand).is_equal(["embaixador", "duque"])


func test_exchange_can_mix_one_hand_card_and_one_drawn_card() -> void:
	var engine := _declared_exchange(["capitao", "embaixador"])

	engine.choose_exchange(0, [1, 3])

	assert_array(engine.state.players[0].hand).is_equal(["duque", "embaixador"])


# AC-2: keep exactly as many cards as influences

func test_player_with_one_influence_keeps_exactly_one_card() -> void:
	var engine := _engine(3, [["embaixador"], ["condessa", "capitao"], ["assassino", "assassino"]],
			["capitao", "duque"])
	engine.submit_action(0, "trocar")
	engine.pass_response(1)
	engine.pass_response(2)

	assert_str(engine.choose_exchange(0, [0, 1]).error).is_equal("invalid_keep")
	assert_bool(engine.choose_exchange(0, [2]).ok).is_true()
	assert_array(engine.state.players[0].hand).is_equal(["duque"])


func test_exchange_rejects_wrong_count_duplicates_and_out_of_range_indices() -> void:
	var engine := _declared_exchange(["capitao", "embaixador"])

	assert_str(engine.choose_exchange(0, [0]).error).is_equal("invalid_keep")
	assert_str(engine.choose_exchange(0, [0, 0]).error).is_equal("invalid_keep")
	assert_str(engine.choose_exchange(0, [0, 4]).error).is_equal("invalid_keep")
	assert_str(engine.choose_exchange(0, [-1, 1]).error).is_equal("invalid_keep")
	assert_str(engine.state.phase).is_equal(RulesEngine.PHASE_AWAITING_EXCHANGE)


func test_exchange_rejects_other_player_and_wrong_phase() -> void:
	var engine := _declared_exchange(["capitao", "embaixador"])

	assert_str(engine.choose_exchange(1, [0, 1]).error).is_equal("not_your_exchange")
	engine.choose_exchange(0, [0, 1])
	assert_str(engine.choose_exchange(0, [0, 1]).error).is_equal("no_exchange_pending")


# AC-3 and AC-7: returned cards shuffled into the deck, nothing duplicated or lost

func test_exchange_keeps_all_fifteen_cards_in_play() -> void:
	var engine := _declared_exchange(["capitao", "embaixador"])
	var in_play: Array = _all_cards_sorted(engine) + engine.state.exchange.drawn
	in_play.sort()
	assert_array(in_play).is_equal(_full_set_sorted())

	engine.choose_exchange(0, [2, 1])

	assert_array(_all_cards_sorted(engine)).is_equal(_full_set_sorted())


func test_exchange_returns_unkept_cards_to_court_deck() -> void:
	var engine := _declared_exchange(["capitao", "embaixador"])
	var deck_before: int = engine.state.deck.size()

	engine.choose_exchange(0, [2, 3])

	assert_int(engine.state.deck.size()).is_equal(deck_before + 2)


func test_exchange_with_same_seed_gives_same_deck_order() -> void:
	var first := _engine(3, [["embaixador", "duque"], ["condessa", "capitao"], ["assassino", "assassino"]],
			["capitao", "embaixador"], 11)
	var second := _engine(3, [["embaixador", "duque"], ["condessa", "capitao"], ["assassino", "assassino"]],
			["capitao", "embaixador"], 11)
	for engine: RulesEngine in [first, second]:
		engine.submit_action(0, "trocar")
		engine.pass_response(1)
		engine.pass_response(2)
		engine.choose_exchange(0, [0, 2])

	assert_array(first.state.deck).is_equal(second.state.deck)


# AC-4: challenge-win reshuffle

func test_challenge_won_with_true_claim_replaces_shown_card_with_random_one() -> void:
	var engine := _engine(3, [["embaixador", "duque"], ["condessa", "capitao"], ["assassino", "assassino"]],
			["capitao", "embaixador"])
	var deck_before: int = engine.state.deck.size()
	engine.submit_action(0, "trocar")

	engine.challenge(1)

	assert_int(engine.state.players[0].hand.size()).is_equal(2)
	assert_int(engine.state.deck.size()).is_equal(deck_before)
	assert_array(_all_cards_sorted(engine)).is_equal(_full_set_sorted())
	assert_int(engine.state.loser).is_equal(1)


func test_challenge_won_reshuffle_can_return_the_same_character() -> void:
	# Court deck holds only the shown character, so the redraw must be that card.
	var engine := _engine(2, [["embaixador", "duque"], ["condessa", "capitao"]], [])
	engine.state.deck = ["embaixador"] as Array[String]
	engine.submit_action(0, "trocar")

	engine.challenge(1)

	assert_array(engine.state.players[0].hand).contains_exactly_in_any_order(["duque", "embaixador"])


# AC-5: bluffed Embaixador

func test_bluffed_embaixador_challenged_draws_no_cards_and_claimant_loses() -> void:
	var engine := _engine(3, [["duque", "duque"], ["condessa", "capitao"], ["assassino", "assassino"]],
			["capitao", "embaixador"])
	var deck_before: int = engine.state.deck.size()
	engine.submit_action(0, "trocar")

	engine.challenge(1)

	assert_int(engine.state.loser).is_equal(0)
	engine.choose_influence_to_lose(0, 0)
	assert_int(engine.state.deck.size()).is_equal(deck_before)
	assert_int(engine.state.players[0].hand.size()).is_equal(1)
	assert_str(engine.state.phase).is_equal(RulesEngine.PHASE_AWAITING_ACTION)
	assert_int(engine.state.current_player).is_equal(1)


func test_trocar_cannot_be_blocked() -> void:
	var engine := _engine(3, [["embaixador", "duque"], ["condessa", "capitao"], ["assassino", "assassino"]],
			["capitao", "embaixador"])
	engine.submit_action(0, "trocar")

	engine.pass_response(1)
	engine.pass_response(2)

	assert_str(engine.state.phase).is_equal(RulesEngine.PHASE_AWAITING_EXCHANGE)
