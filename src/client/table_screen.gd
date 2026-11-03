class_name TableScreen
extends Control
## The match table of the design: an immersive scene with a minimal HUD. It
## renders the per-player view the server sends (Room.view_for) and only emits
## intents; it holds no rules. Wide windows follow the desktop board (1440x900),
## narrow ones the phone board (390x844); both are laid out from the same pieces
## and rebuilt on every update or resize.
##
## Response, loss and exchange prompts still use plain buttons in a card at the
## bottom (a stopgap until the reaction and loss screens replace them).

signal intent_chosen(intent: Dictionary)
signal leave_requested

## Beyond this many log lines the oldest are dropped.
const MAX_LOG_LINES: int = 60
## Windows narrower than this use the phone layout.
const NARROW_WIDTH: float = 900.0
const WIDE_DESIGN: Vector2 = Vector2(1440, 900)
const NARROW_DESIGN: Vector2 = Vector2(390, 844)

var _view: Dictionary = {}
var _needs_my_answer: bool = false
var _selected_action: String = ""
var _exchange_picks: Array[int] = []
var _log_lines: Array[String] = []
var _toast_text: String = ""
var _awaiting_server: bool = false
var _target_screen: TargetScreen

var _stage: Control
var _prompt_text: Label
var _prompt_buttons: HFlowContainer


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_stage = Control.new()
	_stage.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_stage)
	resized.connect(_render)


## Forgets the previous match (view, log, half-made choices) before the next one.
func reset() -> void:
	_view = {}
	_log_lines.clear()
	_close_target_screen()
	_exchange_picks.clear()
	_needs_my_answer = false
	_toast_text = ""


## Kept for the client's API; the room code is not shown on the table.
func set_room_code(_code: String) -> void:
	pass


## Renders [param view] (Room.view_for) and appends [param events] to the log.
func apply_update(view: Dictionary, events: Array) -> void:
	_view = view
	_toast_text = ""
	_awaiting_server = false
	# Any update means the state moved on, so a half-made action choice is void.
	_close_target_screen()
	if view.phase != RulesEngine.PHASE_AWAITING_EXCHANGE:
		_exchange_picks.clear()
	for event: Dictionary in events:
		var line: String = _describe(event)
		if not line.is_empty():
			_log_lines.append(line)
	while _log_lines.size() > MAX_LOG_LINES:
		_log_lines.pop_front()
	_render()


## Shows a server error code above the actions.
func show_error(code: String) -> void:
	_toast_text = UiText.error(code)
	_awaiting_server = false
	if not _view.is_empty():
		_render()


func _render() -> void:
	if _stage == null or _view.is_empty() or size.x < 50.0:
		return
	UiKit.clear(_stage)
	var narrow: bool = size.x < NARROW_WIDTH
	var design: Vector2 = NARROW_DESIGN if narrow else WIDE_DESIGN
	var unit: float = clampf(minf(size.x / design.x, size.y / design.y), 0.5, 1.8)
	var vscale: float = size.y / design.y
	var me: int = _view.you.seat
	var my_player: Dictionary = _view.players[me]

	_needs_my_answer = _compute_needs_my_answer()
	_add_corner_buttons(unit)
	_add_opponents(narrow, unit, me)
	_add_last_action(narrow, unit, vscale)
	_add_hand(narrow, unit, vscale, my_player)
	_add_bottom(narrow, unit, vscale, my_player)


func _compute_needs_my_answer() -> bool:
	var me: int = _view.you.seat
	var window: Dictionary = _view.window
	var response_open: bool = not window.is_empty() and window.eligible.has(me) and not window.passed.has(me)
	return response_open \
			or (_view.phase == RulesEngine.PHASE_AWAITING_INFLUENCE_LOSS and _view.loser == me) \
			or (_view.phase == RulesEngine.PHASE_AWAITING_EXCHANGE and _view.exchange.player == me)


# --- corner buttons -----------------------------------------------------

func _add_corner_buttons(unit: float) -> void:
	var diameter: float = 44 * unit
	var menu := _round_button("res://assets/arte/design/icone_menu.svg", diameter)
	menu.position = Vector2(12 * unit, 12 * unit)
	menu.pressed.connect(_open_menu)
	_stage.add_child(menu)
	var rules := _round_button("res://assets/arte/design/icone_regras.svg", diameter)
	rules.position = Vector2(size.x - diameter - 12 * unit, 12 * unit)
	rules.pressed.connect(func() -> void: add_child(RulesSheet.rules()))
	_stage.add_child(rules)


func _round_button(icon_path: String, diameter: float) -> Button:
	var button := Button.new()
	button.icon = UiKit.texture(icon_path)
	button.expand_icon = true
	button.custom_minimum_size = Vector2.ONE * diameter
	button.size = Vector2.ONE * diameter
	button.add_theme_constant_override("icon_max_width", int(diameter * 0.45))
	for state in ["normal", "pressed", "focus"]:
		button.add_theme_stylebox_override(state, UiKit.box(UiKit.PANEL, UiKit.BORDER, 2, 999))
	button.add_theme_stylebox_override("hover", UiKit.box(UiKit.PANEL_RAISED, UiKit.GOLD, 2, 999))
	return button


func _open_menu() -> void:
	var sheet := RulesSheet.menu()
	sheet.leave_requested.connect(func() -> void: leave_requested.emit())
	add_child(sheet)


# --- opponents ----------------------------------------------------------

func _add_opponents(narrow: bool, unit: float, me: int) -> void:
	var others: Array = []
	for step in range(1, _view.players.size()):
		others.append(_view.players[(me + step) % _view.players.size()])
	var op_unit: float = unit * (0.74 if narrow else 1.0)
	var width: float = 130 * op_unit
	var gap: float = (14 if narrow else 150) * unit
	var total: float = others.size() * width + (others.size() - 1) * gap
	if total > size.x * 0.92:
		op_unit *= size.x * 0.92 / total
		width = 130 * op_unit
		gap *= size.x * 0.92 / total
		total = others.size() * width + (others.size() - 1) * gap
	var left: float = (size.x - total) / 2.0
	var top: float = (62 if narrow else 22) * unit
	for index in range(others.size()):
		var player: Dictionary = others[index]
		var view := OpponentView.new()
		view.setup(player, int(player.id), player.id == _view.current_player and player.alive, op_unit)
		view.position = Vector2(left + index * (width + gap), top)
		_stage.add_child(view)


# --- last action --------------------------------------------------------

func _add_last_action(narrow: bool, unit: float, vscale: float) -> void:
	var caption_y: float = (170 if narrow else 215) * vscale
	var caption := UiKit.label(UiText.LAST_ACTION, int(round(11 * unit * (1.2 if narrow else 1.0))), UiKit.GOLD_TEXT)
	caption.add_theme_font_override("font", UiKit.font(false, 600, 3))
	caption.autowrap_mode = TextServer.AUTOWRAP_OFF
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.position = Vector2(0, caption_y)
	caption.size = Vector2(size.x, 20 * unit)
	_stage.add_child(caption)

	var headline := RichTextLabel.new()
	headline.bbcode_enabled = true
	headline.fit_content = true
	headline.scroll_active = false
	headline.mouse_filter = Control.MOUSE_FILTER_IGNORE
	headline.add_theme_font_override("normal_font", UiKit.font(true, 700, 1))
	headline.add_theme_font_size_override("normal_font_size", int(round((17 if narrow else 28) * unit * (1.15 if narrow else 1.0))))
	headline.add_theme_color_override("default_color", UiKit.INK)
	headline.text = _headline_bbcode()
	headline.position = Vector2(size.x * 0.05, caption_y + 24 * unit)
	headline.size = Vector2(size.x * 0.9, 40 * unit)
	_stage.add_child(headline)

	var pills := HBoxContainer.new()
	pills.add_theme_constant_override("separation", int(round(10 * unit)))
	pills.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var pill_size: int = int(round(14 * unit * (1.2 if narrow else 1.0)))
	pills.add_child(CoinPill.new(int(_view.treasury), UiText.TREASURY, pill_size))
	pills.add_child(CoinPill.new(int(_view.deck_count), UiText.DECK, pill_size))
	_stage.add_child(pills)
	var pills_size: Vector2 = pills.get_combined_minimum_size()
	pills.size = pills_size
	pills.position = Vector2((size.x - pills_size.x) / 2.0, caption_y + (24 + (44 if narrow else 56)) * unit)


func _headline_bbcode() -> String:
	var line: String = _log_lines.back() if not _log_lines.is_empty() else UiText.MATCH_STARTED
	var tags: Dictionary = {}
	for id: String in UiText.CHARACTER_NAMES:
		tags[UiText.character(id)] = ["[color=#%s]" % UiKit.CARD_STYLE[id].title.to_html(false), "[/color]"]
	return "[center]%s[/center]" % UiKit.mark(line, tags)


# --- my cards -----------------------------------------------------------

func _add_hand(narrow: bool, unit: float, vscale: float, my_player: Dictionary) -> void:
	var card_width: float = (160 if narrow else 220) * unit
	var cards: Array = []
	for character: String in _view.you.hand:
		cards.append([character, false])
	for character: String in my_player.revealed:
		cards.append([character, true])
	var step: float = card_width * 0.86
	var total: float = card_width + step * (cards.size() - 1)
	var left: float = (size.x - total) / 2.0
	var top: float = (300 if narrow else 365) * vscale
	var tilts: Array[float] = [-6.0, 5.0]
	for index in range(cards.size()):
		var card := CardView.new(cards[index][0], card_width)
		card.lost = cards[index][1]
		card.position = Vector2(left + index * step, top - index * 14 * unit)
		card.rotation_degrees = tilts[mini(index, 1)]
		_stage.add_child(card)


# --- bottom: title, actions or prompt, coins, log ------------------------

func _add_bottom(narrow: bool, unit: float, vscale: float, my_player: Dictionary) -> void:
	var title: String = ""
	var sub: String = ""
	var me: int = _view.you.seat
	var show_actions: bool = false
	var exiled: bool = not my_player.alive and _view.phase != RulesEngine.PHASE_GAME_OVER
	if exiled:
		title = UiText.SPECTATOR_TITLE
		sub = UiText.SPECTATING
	elif _needs_my_answer:
		title = UiText.YOUR_ANSWER_TITLE
	elif _view.phase == RulesEngine.PHASE_AWAITING_ACTION and _view.current_player == me:
		title = UiText.YOUR_TURN_TITLE
		sub = UiText.CHOOSE_ACTION_SUB
		show_actions = _selected_action.is_empty() and not _awaiting_server
	else:
		title = UiText.TURN_OF % String(_name(_view.current_player)).to_upper()
		sub = UiText.WAITING_SUB

	var title_y: float = (592 if narrow else 700) * vscale
	var title_label := UiKit.label(title, int(round((24 if narrow else 28) * unit * (1.2 if narrow else 1.0))), UiKit.INK, true)
	title_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.position = Vector2(0, title_y)
	title_label.size = Vector2(size.x, 40 * unit)
	_stage.add_child(title_label)
	if not sub.is_empty():
		var sub_label := UiKit.label(sub, int(round(15 * unit * (1.15 if narrow else 1.0))), UiKit.MUTED)
		sub_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		sub_label.position = Vector2(size.x * 0.05, title_y + 38 * unit)
		sub_label.size = Vector2(size.x * 0.9, 26 * unit)
		_stage.add_child(sub_label)

	var bar_y: float = title_y + (74 if narrow else 78) * unit
	if show_actions:
		_add_action_bar(narrow, unit, bar_y, int(my_player.coins))
	elif not exiled and _needs_my_answer:
		_add_prompt_card(unit)
	if not _toast_text.is_empty():
		var toast := UiKit.label(_toast_text, int(round(16 * unit)), UiKit.DANGER_DARK)
		toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		toast.position = Vector2(size.x * 0.05, title_y - (100 if narrow else 28) * unit)
		toast.size = Vector2(size.x * 0.9, 24 * unit)
		_stage.add_child(toast)
	_add_coins_and_log(narrow, unit, title_y, int(my_player.coins))


func _add_action_bar(narrow: bool, unit: float, bar_y: float, coins: int) -> void:
	var bar := ActionBar.new()
	bar.setup(coins, unit * (0.95 if narrow else 1.0), narrow)
	bar.action_chosen.connect(_on_action_chosen)
	var bar_size: Vector2 = bar.get_combined_minimum_size()
	if bar_size.x <= size.x:
		bar.size = bar_size
		bar.position = Vector2((size.x - bar_size.x) / 2.0, bar_y)
		_stage.add_child(bar)
		return
	# Wider than the screen (phones): the bar scrolls sideways.
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(0, bar_y)
	scroll.size = Vector2(size.x, bar_size.y + 8 * unit)
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.add_child(bar)
	_stage.add_child(scroll)


func _on_action_chosen(action: String) -> void:
	_toast_text = ""
	if RulesConfig.ACTIONS[action].targeted:
		_open_target_screen(action)
	else:
		# Until the server answers, the bar is gone: a second tap would only be rejected.
		_awaiting_server = true
		intent_chosen.emit({"type": "action", "action": action})
		_render()


func _open_target_screen(action: String) -> void:
	_close_target_screen()
	_selected_action = action
	_target_screen = TargetScreen.new()
	add_child(_target_screen)
	_target_screen.setup(action, _view)
	_target_screen.cancelled.connect(_close_target_screen)
	_target_screen.confirmed.connect(func(target: int) -> void:
			var chosen: String = _selected_action
			_close_target_screen()
			_awaiting_server = true
			intent_chosen.emit({"type": "action", "action": chosen, "target": target})
			_render())


func _close_target_screen() -> void:
	_selected_action = ""
	if _target_screen != null and is_instance_valid(_target_screen):
		_target_screen.queue_free()
	_target_screen = null


func _add_coins_and_log(narrow: bool, unit: float, title_y: float, coins: int) -> void:
	if narrow:
		var pill := CoinPill.new(coins, "", int(round(26 * unit)))
		_stage.add_child(pill)
		var pill_size: Vector2 = pill.get_combined_minimum_size()
		pill.size = pill_size
		pill.position = Vector2((size.x - pill_size.x) / 2.0, title_y - 62 * unit)
		var log_button := UiKit.button(UiText.LOG_BUTTON)
		log_button.size = Vector2(110 * unit, 44 * unit)
		log_button.position = Vector2(12 * unit, size.y - 56 * unit)
		log_button.add_theme_font_size_override("font_size", int(round(15 * unit)))
		log_button.pressed.connect(func() -> void: add_child(RulesSheet.log_sheet(_log_lines, _player_names())))
		_stage.add_child(log_button)
		return

	var log_panel := LogPanel.new()
	log_panel.show_lines(_log_lines, _player_names(), 3, int(round(14 * unit)), true)
	log_panel.set_content_width(310 * unit - 30)
	_stage.add_child(log_panel)
	var log_size: Vector2 = log_panel.get_combined_minimum_size()
	log_panel.size = log_size
	log_panel.position = Vector2(24 * unit, size.y - log_size.y - 30 * unit)

	var coins_card := UiKit.panel(UiKit.PANEL, UiKit.BORDER, 1)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", int(round(4 * unit)))
	coins_card.add_child(column)
	var coins_title := UiKit.label(UiText.YOUR_COINS_TITLE, int(round(11 * unit)), UiKit.MUTED)
	coins_title.autowrap_mode = TextServer.AUTOWRAP_OFF
	column.add_child(coins_title)
	var amount := CoinPill.new(coins, "", int(round(28 * unit)))
	column.add_child(amount)
	var hint := UiKit.label(UiText.COUP_HINT % RulesConfig.ACTIONS[RulesConfig.GOLPE].cost, int(round(12 * unit)), UiKit.MUTED)
	hint.autowrap_mode = TextServer.AUTOWRAP_OFF
	column.add_child(hint)
	_stage.add_child(coins_card)
	var card_size: Vector2 = coins_card.get_combined_minimum_size()
	coins_card.size = card_size
	coins_card.position = Vector2(size.x - card_size.x - 24 * unit, size.y - card_size.y - 30 * unit)


# --- stopgap prompt card ---------------------------------------------------

func _add_prompt_card(unit: float) -> void:
	var card := UiKit.panel(UiKit.PANEL_RAISED, UiKit.GOLD, 2)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", int(round(8 * unit)))
	card.add_child(column)
	_prompt_text = UiKit.label("", int(round(18 * unit)), UiKit.INK)
	column.add_child(_prompt_text)
	_prompt_buttons = HFlowContainer.new()
	_prompt_buttons.add_theme_constant_override("h_separation", int(round(8 * unit)))
	_prompt_buttons.add_theme_constant_override("v_separation", int(round(8 * unit)))
	column.add_child(_prompt_buttons)
	_fill_prompt()
	# On wide screens keep clear of the log card (left) and the coin card (right).
	var width: float = minf(size.x * 0.92, 980 * unit) if size.x < NARROW_WIDTH else size.x - 2 * 350 * unit
	# Wrapping text and buttons need a width to be measured against.
	_prompt_text.custom_minimum_size = Vector2(width - 40 * unit, 0)
	_prompt_buttons.custom_minimum_size = Vector2(width - 40 * unit, 0)
	card.custom_minimum_size = Vector2(width, 0)
	_stage.add_child(card)
	var card_size: Vector2 = card.get_combined_minimum_size()
	card.size = Vector2(width, card_size.y)
	card.position = Vector2((size.x - width) / 2.0, size.y - card_size.y - 70 * unit)


func _fill_prompt() -> void:
	var me: int = _view.you.seat
	var window: Dictionary = _view.window
	var pending: Dictionary = _view.pending_action
	var response_open: bool = not window.is_empty() and window.eligible.has(me) and not window.passed.has(me)
	match _view.phase:
		RulesEngine.PHASE_AWAITING_INFLUENCE_LOSS:
			_prompt_text.text = UiText.LOSE_PROMPT
			for index in range(_view.you.hand.size()):
				var choice: int = index
				var button := UiKit.button(UiText.character(_view.you.hand[index]))
				button.pressed.connect(func() -> void:
						intent_chosen.emit({"type": "lose_influence", "card_index": choice}))
				_prompt_buttons.add_child(button)
		RulesEngine.PHASE_AWAITING_EXCHANGE:
			_render_exchange_prompt()
		RulesEngine.PHASE_AWAITING_CHALLENGE, RulesEngine.PHASE_AWAITING_BLOCK_CHALLENGE:
			if response_open:
				_prompt_text.text = _claim_prompt(window, pending)
				_add_intent_button(UiText.CHALLENGE, {"type": "challenge"})
				_add_intent_button(UiText.PASS, {"type": "pass"})
		RulesEngine.PHASE_AWAITING_BLOCK:
			if response_open:
				_render_block_prompt(pending, me)


func _render_block_prompt(pending: Dictionary, me: int) -> void:
	var against: String = UiText.AGAINST_YOU if pending.target == me else ""
	_prompt_text.text = UiText.BLOCK_PROMPT % [_name(pending.actor), UiText.action(pending.action), against]
	var blockers: Array = RulesConfig.BLOCKS[pending.action].blockers
	for character: String in blockers:
		_add_intent_button(UiText.BLOCK_AS % UiText.character(character), {"type": "block", "character": character})
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


# --- helpers ---------------------------------------------------------------

func _name(seat: int) -> String:
	if seat < 0 or seat >= _view.players.size():
		return "?"
	return _view.players[seat].name


func _player_names() -> Array:
	var names: Array = []
	for player: Dictionary in _view.players:
		names.append(player.name)
	return names


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
