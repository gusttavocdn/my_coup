class_name TableScreen
extends Control
## The match table of the design: an immersive scene with a minimal HUD. It
## renders the per-player view the server sends (Room.view_for) and only emits
## intents; it holds no rules. Wide windows follow the desktop board (1440x900),
## narrow ones the phone board (390x844); both are laid out from the same pieces
## and rebuilt on every update or resize.
##
## Answers that need a full screen (target, reaction, influence loss, exchange)
## are overlays owned here: opened when the server's view asks for them and
## closed when it moves on.

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
var _loss_cause: String = ""
## Set while a Golpe or an Assassinar aimed at me is in play, for the loss screen.
var _declared_cause: String = ""
var _toast: Control
var _log_lines: Array[String] = []
var _toast_text: String = ""
var _awaiting_server: bool = false
var _target_screen: TargetScreen
var _reaction: ReactionScreen
var _fresh_update: bool = false

var _stage: Control
var _loss_screen: InfluenceLossScreen
var _exchange_screen: ExchangeScreen


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
	_close_reaction()
	_close_answer_screens()
	_loss_cause = ""
	_declared_cause = ""
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
	if view.phase != RulesEngine.PHASE_AWAITING_INFLUENCE_LOSS:
		_loss_cause = ""
	for event: Dictionary in events:
		_note_loss_cause(event, view.you.seat)
		var line: String = _describe(event)
		if not line.is_empty():
			_log_lines.append(line)
	while _log_lines.size() > MAX_LOG_LINES:
		_log_lines.pop_front()
	_fresh_update = true
	_render()
	_fresh_update = false


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
	_sync_reaction()
	_sync_answer_screens()
	_place_toast(unit)


## True while I may still answer an open challenge, block or block-challenge window.
func _response_open() -> bool:
	var me: int = _view.you.seat
	var window: Dictionary = _view.window
	return not window.is_empty() and window.eligible.has(me) and not window.passed.has(me)


## Shows the reaction screen while a response is open, refreshing its countdown
## on every server update (not on a mere resize), and drops it otherwise.
func _sync_reaction() -> void:
	if not _response_open():
		_close_reaction()
		return
	if _reaction == null or not is_instance_valid(_reaction):
		_reaction = ReactionScreen.new()
		add_child(_reaction)
		_reaction.setup(_view)
		_reaction.responded.connect(func(intent: Dictionary) -> void: intent_chosen.emit(intent))
	elif _fresh_update:
		_reaction.update_view(_view)


func _close_reaction() -> void:
	if _reaction != null and is_instance_valid(_reaction):
		_reaction.queue_free()
	_reaction = null


## A red-bordered pill with the last server error, above every overlay.
func _place_toast(unit: float) -> void:
	if _toast != null and is_instance_valid(_toast):
		_toast.queue_free()
	_toast = null
	if _toast_text.is_empty():
		return
	var pill := UiKit.panel(UiKit.PANEL_RAISED, UiKit.DANGER, 2)
	pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var label := UiKit.label(_toast_text, int(round(16 * unit)), UiKit.DANGER_DARK)
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	pill.add_child(label)
	add_child(pill)
	var pill_size: Vector2 = pill.get_combined_minimum_size()
	pill.size = pill_size
	pill.position = Vector2((size.x - pill_size.x) / 2.0, 70 * unit)
	_toast = pill


## Remembers why I lost an influence when the events say so (a challenge).
func _note_loss_cause(event: Dictionary, me: int) -> void:
	if event.type == "challenge_lost" and event.challenger == me:
		_loss_cause = "Sua contestação contra %s falhou." % _name(event.claimant)
	elif event.type == "challenge_won" and event.claimant == me:
		_loss_cause = "Você foi pego blefando."
	elif event.type == "action_declared" and event.target == me:
		match event.action:
			"assassinar":
				_declared_cause = "%s assassinou você." % _name(event.actor)
			"golpe":
				_declared_cause = "%s deu um golpe de estado em você." % _name(event.actor)
	elif event.type == "turn_started":
		_declared_cause = ""


## Opens the loss or exchange screen when the match waits for me to choose, and
## drops them as soon as the view says otherwise.
func _sync_answer_screens() -> void:
	var me: int = _view.you.seat
	var needs_loss: bool = _view.phase == RulesEngine.PHASE_AWAITING_INFLUENCE_LOSS and _view.loser == me
	var needs_exchange: bool = _view.phase == RulesEngine.PHASE_AWAITING_EXCHANGE and _view.exchange.player == me
	if needs_loss and (_loss_screen == null or not is_instance_valid(_loss_screen)):
		_loss_screen = InfluenceLossScreen.new()
		add_child(_loss_screen)
		_loss_screen.setup(_view, _loss_cause if not _loss_cause.is_empty() else _declared_cause)
		_loss_screen.chosen.connect(func(index: int) -> void:
				intent_chosen.emit({"type": "lose_influence", "card_index": index}))
	elif not needs_loss:
		_close_loss_screen()
	if needs_exchange and (_exchange_screen == null or not is_instance_valid(_exchange_screen)):
		_exchange_screen = ExchangeScreen.new()
		add_child(_exchange_screen)
		_exchange_screen.setup(_view)
		_exchange_screen.confirmed.connect(func(keep: Array) -> void:
				intent_chosen.emit({"type": "exchange", "keep": keep}))
	elif not needs_exchange:
		_close_exchange_screen()


func _close_loss_screen() -> void:
	if _loss_screen != null and is_instance_valid(_loss_screen):
		_loss_screen.queue_free()
	_loss_screen = null


func _close_exchange_screen() -> void:
	if _exchange_screen != null and is_instance_valid(_exchange_screen):
		_exchange_screen.queue_free()
	_exchange_screen = null


func _close_answer_screens() -> void:
	_close_loss_screen()
	_close_exchange_screen()


func _compute_needs_my_answer() -> bool:
	var me: int = _view.you.seat
	return _response_open() \
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
		"response_timeout":
			return "%s não respondeu a tempo." % _name(event.player)
		"game_over":
			return UiText.GAME_OVER % _name(event.winner)
	return ""
