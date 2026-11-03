class_name TableScreen
extends Control
## The match table: every player, my own cards, the action menu or the prompt
## the match is waiting on, and the event log. It renders the per-player view
## the server sends (Room.view_for) and only emits intents; it holds no rules.

signal intent_chosen(intent: Dictionary)

## Beyond this many log lines the oldest are dropped.
const MAX_LOG_LINES: int = 60

var _view: Dictionary = {}
var _needs_my_answer: bool = false
var _selected_action: String = ""
var _exchange_picks: Array[int] = []
var _log_lines: Array[String] = []

var _header: Label
var _banner: Label
var _players_row: HFlowContainer
var _prompt_text: Label
var _prompt_buttons: HFlowContainer
var _hand_label: Label
var _hand_row: HBoxContainer
var _log: RichTextLabel
var _toast: Label


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 16)
	scroll.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	margin.add_child(column)

	_header = UiKit.label("", 24, UiKit.MUTED)
	column.add_child(_header)
	_banner = UiKit.label("", 28, UiKit.GOLD_TEXT, true)
	column.add_child(_banner)
	_players_row = HFlowContainer.new()
	_players_row.add_theme_constant_override("h_separation", 12)
	_players_row.add_theme_constant_override("v_separation", 12)
	column.add_child(_players_row)

	var prompt_panel := UiKit.panel(UiKit.PANEL_RAISED, UiKit.GOLD, 2)
	column.add_child(prompt_panel)
	var prompt_column := VBoxContainer.new()
	prompt_column.add_theme_constant_override("separation", 10)
	prompt_panel.add_child(prompt_column)
	_prompt_text = UiKit.label("")
	prompt_column.add_child(_prompt_text)
	_prompt_buttons = HFlowContainer.new()
	_prompt_buttons.add_theme_constant_override("h_separation", 10)
	_prompt_buttons.add_theme_constant_override("v_separation", 10)
	prompt_column.add_child(_prompt_buttons)
	_toast = UiKit.label("", 20, UiKit.DANGER)
	prompt_column.add_child(_toast)

	_hand_label = UiKit.label(UiText.YOUR_CARDS, 20, UiKit.MUTED)
	column.add_child(_hand_label)
	_hand_row = HBoxContainer.new()
	_hand_row.add_theme_constant_override("separation", 12)
	column.add_child(_hand_row)

	_log = RichTextLabel.new()
	_log.fit_content = true
	_log.scroll_active = false
	_log.custom_minimum_size = Vector2(0, 120)
	column.add_child(_log)


## Forgets the previous match (view, log, half-made choices) before the next one.
func reset() -> void:
	_view = {}
	_log_lines.clear()
	_selected_action = ""
	_exchange_picks.clear()
	_needs_my_answer = false


## Sets the room code shown in the header.
func set_room_code(code: String) -> void:
	_header.text = UiText.ROOM_CODE % code


## Renders [param view] (Room.view_for) and appends [param events] to the log.
func apply_update(view: Dictionary, events: Array) -> void:
	_view = view
	_toast.text = ""
	_toast.visible = false
	# Any update means the state moved on, so a half-made action choice is void.
	_selected_action = ""
	if view.phase != RulesEngine.PHASE_AWAITING_EXCHANGE:
		_exchange_picks.clear()
	for event: Dictionary in events:
		var line: String = _describe(event)
		if not line.is_empty():
			_log_lines.append(line)
	while _log_lines.size() > MAX_LOG_LINES:
		_log_lines.pop_front()
	_render()


## Shows a server error code under the prompt.
func show_error(code: String) -> void:
	_toast.text = UiText.error(code)
	_toast.visible = true
	if not _view.is_empty():
		_render()


func _render() -> void:
	_render_players()
	_render_prompt()
	_banner.text = _banner_text()
	_render_hand()
	_log.text = "\n".join(_log_lines)


func _banner_text() -> String:
	if _view.phase == RulesEngine.PHASE_GAME_OVER:
		return UiText.GAME_OVER % _name(_view.winner)
	if not _view.players[_me()].alive:
		return UiText.SPECTATOR_BANNER
	if _view.phase == RulesEngine.PHASE_AWAITING_ACTION and _view.current_player == _me():
		return UiText.YOUR_TURN
	if _needs_my_answer:
		return UiText.YOUR_ANSWER
	return UiText.WAITING_FOR % _name(_view.current_player)


func _render_players() -> void:
	UiKit.clear(_players_row)
	for player: Dictionary in _view.players:
		var is_turn: bool = player.id == _view.current_player and player.alive
		var panel := UiKit.panel(UiKit.PANEL, UiKit.GOLD if is_turn else Color(0, 0, 0, 0), 3)
		panel.custom_minimum_size = Vector2(200, 0)
		if not player.alive:
			panel.modulate = Color(1, 1, 1, 0.55)
		_players_row.add_child(panel)
		var column := VBoxContainer.new()
		column.add_theme_constant_override("separation", 6)
		panel.add_child(column)
		var title: String = player.name + (UiText.YOU_SUFFIX if player.id == _me() else "")
		column.add_child(UiKit.label(title, 22, UiKit.GOLD_TEXT if is_turn else UiKit.TEXT))
		column.add_child(UiKit.label(UiText.COINS % player.coins, 20, UiKit.MUTED))
		if not player.alive:
			column.add_child(UiKit.label(UiText.EXILED, 18, UiKit.DANGER))
		var cards := HBoxContainer.new()
		cards.add_theme_constant_override("separation", 6)
		column.add_child(cards)
		for _hidden in range(player.influence):
			cards.add_child(UiKit.card("", true))
		for revealed: String in player.revealed:
			cards.add_child(UiKit.card(revealed, true))


func _render_hand() -> void:
	UiKit.clear(_hand_row)
	_hand_label.visible = not _view.you.hand.is_empty()
	for character: String in _view.you.hand:
		_hand_row.add_child(UiKit.card(character))


func _render_prompt() -> void:
	UiKit.clear(_prompt_buttons)
	var me: int = _me()
	var window: Dictionary = _view.window
	var pending: Dictionary = _view.pending_action
	if not _view.players[me].alive and _view.phase != RulesEngine.PHASE_GAME_OVER:
		_needs_my_answer = false
		_prompt_text.text = UiText.SPECTATING
		return
	var response_open: bool = not window.is_empty() and window.eligible.has(me) \
			and not window.passed.has(me)
	_needs_my_answer = response_open \
			or (_view.phase == RulesEngine.PHASE_AWAITING_INFLUENCE_LOSS and _view.loser == me) \
			or (_view.phase == RulesEngine.PHASE_AWAITING_EXCHANGE and _view.exchange.player == me)

	match _view.phase:
		RulesEngine.PHASE_GAME_OVER:
			_prompt_text.text = UiText.GAME_OVER % _name(_view.winner)
		RulesEngine.PHASE_AWAITING_INFLUENCE_LOSS:
			if _view.loser == me:
				_prompt_text.text = UiText.LOSE_PROMPT
				for index in range(_view.you.hand.size()):
					var choice: int = index
					var button := UiKit.button(UiText.character(_view.you.hand[index]))
					button.pressed.connect(func() -> void:
							intent_chosen.emit({"type": "lose_influence", "card_index": choice}))
					_prompt_buttons.add_child(button)
			else:
				_prompt_text.text = UiText.WAITING_FOR % _name(_view.loser)
		RulesEngine.PHASE_AWAITING_EXCHANGE:
			if _view.exchange.player == me and _view.exchange.has("drawn"):
				_render_exchange_prompt()
			else:
				_prompt_text.text = UiText.WAITING_FOR % _name(_view.exchange.player)
		RulesEngine.PHASE_AWAITING_CHALLENGE, RulesEngine.PHASE_AWAITING_BLOCK_CHALLENGE:
			if response_open:
				_prompt_text.text = _claim_prompt(window, pending)
				_add_intent_button(UiText.CHALLENGE, {"type": "challenge"})
				_add_intent_button(UiText.PASS, {"type": "pass"})
			else:
				_prompt_text.text = UiText.WAITING_RESPONSES
		RulesEngine.PHASE_AWAITING_BLOCK:
			if response_open:
				_render_block_prompt(pending, me)
			else:
				_prompt_text.text = UiText.WAITING_RESPONSES
		RulesEngine.PHASE_AWAITING_ACTION:
			if _view.current_player == me:
				_render_action_menu(me)
			else:
				_prompt_text.text = UiText.WAITING_FOR % _name(_view.current_player)


func _render_action_menu(me: int) -> void:
	var coins: int = _view.players[me].coins
	if not _selected_action.is_empty():
		_prompt_text.text = UiText.PICK_TARGET % UiText.action(_selected_action)
		for player: Dictionary in _view.players:
			if player.alive and player.id != me:
				var target: int = player.id
				var button := UiKit.button(player.name)
				button.pressed.connect(func() -> void:
						intent_chosen.emit({"type": "action", "action": _selected_action, "target": target}))
				_prompt_buttons.add_child(button)
		var cancel := UiKit.button(UiText.CANCEL)
		cancel.pressed.connect(func() -> void:
				_selected_action = ""
				_render())
		_prompt_buttons.add_child(cancel)
		return

	_prompt_text.text = UiText.CHOOSE_ACTION
	for action: String in RulesConfig.ACTIONS:
		var definition: Dictionary = RulesConfig.ACTIONS[action]
		var caption: String = UiText.action(action)
		if definition.cost > 0:
			caption += " (%d)" % definition.cost
		var button := UiKit.button(caption)
		var forced_coup: bool = coins >= RulesConfig.FORCED_COUP_COINS and action != RulesConfig.GOLPE
		button.disabled = coins < int(definition.cost) or forced_coup
		var chosen: String = action
		button.pressed.connect(func() -> void:
				if RulesConfig.ACTIONS[chosen].targeted:
					_selected_action = chosen
					_render()
				else:
					intent_chosen.emit({"type": "action", "action": chosen}))
		_prompt_buttons.add_child(button)


func _render_block_prompt(pending: Dictionary, me: int) -> void:
	var against: String = UiText.AGAINST_YOU if pending.target == me else ""
	_prompt_text.text = UiText.BLOCK_PROMPT % [_name(pending.actor), UiText.action(pending.action), against]
	var blockers: Array = RulesConfig.BLOCKS[pending.action].blockers
	for character: String in blockers:
		_add_intent_button(UiText.BLOCK_AS % UiText.character(character),
				{"type": "block", "character": character})
	_add_intent_button(UiText.PASS, {"type": "pass"})


func _render_exchange_prompt() -> void:
	var pool: Array = _view.you.hand + _view.exchange.drawn
	var keep_count: int = _view.you.hand.size()
	_prompt_text.text = UiText.EXCHANGE_PROMPT % keep_count
	var confirm := UiKit.button(UiText.CONFIRM)
	confirm.disabled = _exchange_picks.size() != keep_count
	confirm.pressed.connect(func() -> void:
			intent_chosen.emit({"type": "exchange", "keep": _exchange_picks.duplicate()}))
	for index in range(pool.size()):
		var pool_index: int = index
		var button := UiKit.button(UiText.character(pool[index]))
		button.toggle_mode = true
		button.button_pressed = _exchange_picks.has(pool_index)
		button.toggled.connect(func(on: bool) -> void:
				if on and not _exchange_picks.has(pool_index):
					_exchange_picks.append(pool_index)
				elif not on:
					_exchange_picks.erase(pool_index)
				confirm.disabled = _exchange_picks.size() != keep_count)
		_prompt_buttons.add_child(button)
	_prompt_buttons.add_child(confirm)


func _claim_prompt(window: Dictionary, pending: Dictionary) -> String:
	var claimant: String = _name(window.claimant)
	var claim: String = UiText.character(window.claim)
	if _view.phase == RulesEngine.PHASE_AWAITING_BLOCK_CHALLENGE:
		return UiText.BLOCK_CLAIM_PROMPT % [claimant, claim]
	return UiText.CLAIM_PROMPT % [claimant, claim, UiText.action(pending.action)]


func _add_intent_button(caption: String, intent: Dictionary) -> void:
	var button := UiKit.button(caption)
	button.pressed.connect(func() -> void: intent_chosen.emit(intent))
	_prompt_buttons.add_child(button)


func _me() -> int:
	return _view.you.seat


func _name(seat: int) -> String:
	if seat < 0 or seat >= _view.players.size():
		return "?"
	return _view.players[seat].name


## One log line for [param event], or "" for events that are not worth showing.
func _describe(event: Dictionary) -> String:
	match event.type:
		"action_declared":
			return "%s usa %s." % [_name(event.actor), UiText.action(event.action)]
		"challenge_declared":
			return "%s contesta %s." % [_name(event.challenger), _name(event.claimant)]
		"challenge_lost":
			return "%s mostrou %s: a contestação falhou." % [_name(event.claimant), UiText.character(event.card)]
		"challenge_won":
			return "%s estava blefando." % _name(event.claimant)
		"block_declared":
			return "%s bloqueia como %s." % [_name(event.blocker), UiText.character(event.character)]
		"influence_lost":
			return "%s perdeu %s." % [_name(event.player), UiText.character(event.card)]
		"player_eliminated":
			return "%s foi exilado." % _name(event.player)
		"coins_stolen":
			return "%s roubou %d moeda(s) de %s." % [_name(event.to), event.amount, _name(event.from)]
		"action_failed":
			return "A ação falhou."
		"block_failed":
			return "O bloqueio falhou."
		"action_dropped":
			return "A ação perdeu o alvo."
		"exchange_started":
			return "%s troca cartas com o baralho." % _name(event.player)
		"game_over":
			return UiText.GAME_OVER % _name(event.winner)
	return ""
