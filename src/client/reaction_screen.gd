class_name ReactionScreen
extends Control
## The "reagir" screen of the design: an overlay above the table shown while I
## may still answer an open response window (challenge, block or challenge of a
## block). A draining bar and "RESPONDA EM Ns" count down locally from the last
## [code]window.seconds_left[/code] the server sent; the server's auto-pass
## update is what removes the screen, so nothing is sent when time runs out.
## It only emits intents ([signal responded]) and holds no rules.

signal responded(intent: Dictionary)

const DESIGN: Vector2 = Vector2(390, 844)
## Last seconds in which the countdown turns urgent.
const URGENT_SECONDS: float = 3.0
## "quer <verb> você" per targeted action.
const VERBS: Dictionary = {
	"assassinar": "assassinar",
	"extorquir": "extorquir",
	"golpe": "dar o golpe em",
}
const OPEN_ACTION_PHRASES: Dictionary = {
	"ajuda_externa": "pegar a ajuda externa",
	"renda": "pegar a renda",
	"taxas": "taxar",
	"trocar": "trocar cartas",
}
## "Bloquear com a Condessa": the article of each character.
const ARTICLES: Dictionary = {
	"duque": "o", "assassino": "o", "capitao": "o", "embaixador": "o", "condessa": "a",
}

## Stops the local countdown (screenshots, tests).
var frozen: bool = false

var _view: Dictionary = {}
var _seconds_left: float = 0.0
var _total_seconds: float = 8.0
var _sent: bool = false
var _bar_fill: ColorRect
var _bar_back: ColorRect
var _timer_label: Label
var _buttons: Array[Button] = []
var _unit: float = 1.0


## Opens the screen for the window described by [param view] (Room.view_for).
func setup(view: Dictionary) -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	resized.connect(_render)
	update_view(view)


## Takes a fresh server view: restarts the countdown from its remaining time.
func update_view(view: Dictionary) -> void:
	_view = view
	var window: Dictionary = view.window
	_seconds_left = float(window.get("seconds_left", 0.0))
	_total_seconds = maxf(0.1, float(window.get("total_seconds", RulesConfig.RESPONSE_SECONDS)))
	_sent = false
	_render()


## Seconds still left on the local countdown.
func seconds_left() -> float:
	return _seconds_left


## Sets the local countdown (previews and tests).
func set_seconds_left(seconds: float) -> void:
	_seconds_left = seconds
	_refresh_timer()


func _process(delta: float) -> void:
	if frozen or _view.is_empty():
		return
	_seconds_left = maxf(0.0, _seconds_left - delta)
	_refresh_timer()


# --- what the window is about ----------------------------------------------

## Everything the screen shows about the open window, read from the view.
func _context() -> Dictionary:
	var me: int = _view.you.seat
	var window: Dictionary = _view.window
	var pending: Dictionary = _view.pending_action
	var action: String = pending.action
	var definition: Dictionary = RulesConfig.ACTIONS[action]
	var at_me: bool = definition.targeted and pending.target == me
	var context: Dictionary = {
		"claimant": window.claimant, "claim": window.claim, "blockers": [], "can_challenge": true,
		"headline": "", "tags": {}, "accept": "",
	}
	match _view.phase:
		RulesEngine.PHASE_AWAITING_BLOCK_CHALLENGE:
			var blocker: String = _name(window.claimant)
			var claimed: String = UiText.character(window.claim)
			context.headline = "%s bloqueia como %s" % [blocker, claimed]
			context.tags = {claimed: _title_tag(window.claim)}
			context.accept = "o bloqueio vale"
		RulesEngine.PHASE_AWAITING_BLOCK:
			context.claimant = pending.actor
			context.claim = definition.character
			context.can_challenge = false
			context.blockers = RulesConfig.BLOCKS.get(action, {}).get("blockers", [])
			context.headline = _action_line(pending, definition, at_me, context.tags)
			context.accept = _accept_hint(pending, definition, at_me)
		_:
			context.headline = _action_line(pending, definition, at_me, context.tags) if at_me \
					else "%s declara %s" % [_name(window.claimant), UiText.character(window.claim)]
			if not at_me:
				context.tags = {UiText.character(window.claim): _title_tag(window.claim)}
			context.accept = _accept_hint(pending, definition, at_me)
	return context


## "Marina quer assassinar você" (the verb gets the action's accent color).
func _action_line(pending: Dictionary, definition: Dictionary, at_me: bool, tags: Dictionary) -> String:
	var actor: String = _name(pending.actor)
	if definition.targeted:
		var verb: String = VERBS.get(pending.action, UiText.action(pending.action).to_lower())
		tags[verb] = _accent_tag()
		return "%s quer %s %s" % [actor, verb, "você" if at_me else _name(pending.target)]
	var phrase: String = OPEN_ACTION_PHRASES.get(pending.action, UiText.action(pending.action).to_lower())
	tags[phrase] = _accent_tag()
	return "%s quer %s" % [actor, phrase]


func _accept_hint(pending: Dictionary, definition: Dictionary, at_me: bool) -> String:
	var actor: String = _name(pending.actor)
	if at_me:
		match pending.action:
			"assassinar", "golpe":
				return "perder 1 influência"
			"extorquir":
				return "perder até %d moedas" % int(definition.amount)
	match pending.action:
		"taxas", "ajuda_externa", "renda":
			return "%s ganha %d moedas" % [actor, int(definition.amount)]
		"trocar":
			return "%s troca cartas" % actor
	return "a ação segue"


func _accent_tag() -> Array:
	return ["[color=#%s]" % UiKit.DANGER_DARK.to_html(false), "[/color]"]


func _title_tag(character: String) -> Array:
	return ["[color=#%s]" % UiKit.CARD_STYLE[character].title.to_html(false), "[/color]"]


func _name(seat: int) -> String:
	if seat < 0 or seat >= _view.players.size():
		return "?"
	return _view.players[seat].name


# --- drawing ------------------------------------------------------------

func _render() -> void:
	if _view.is_empty() or size.x < 50.0:
		return
	UiKit.clear(self)
	_buttons.clear()
	var unit: float = clampf(minf(size.x / DESIGN.x, size.y / DESIGN.y), 0.6, 1.5)
	_unit = unit
	var context: Dictionary = _context()
	var column_width: float = minf(size.x, 460 * unit)

	var dim := ColorRect.new()
	dim.color = Color(0.97, 0.96, 0.99, 1.0)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)

	_bar_back = ColorRect.new()
	_bar_back.color = Color("e4e0ec")
	_bar_back.position = Vector2.ZERO
	_bar_back.size = Vector2(size.x, maxf(6.0, 6 * unit))
	_bar_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_bar_back)
	_bar_fill = ColorRect.new()
	_bar_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bar_back.add_child(_bar_fill)

	var side: float = (size.x - column_width) / 2.0
	var column := VBoxContainer.new()
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	column.offset_left = side
	column.offset_right = -side
	column.offset_top = 28 * unit
	column.offset_bottom = -22 * unit
	column.add_theme_constant_override("separation", int(round(8 * unit)))
	add_child(column)

	column.add_child(_strip(unit, context.claimant))
	column.add_child(_heading(unit, column_width, context))
	if not String(context.claim).is_empty():
		column.add_child(_claim_block(unit, context))
	column.add_child(_hand_area(unit, context.blockers))
	column.add_child(_actions(unit, context))
	_refresh_timer()


## Opponents along the top; the one being answered is ringed in red.
func _strip(unit: float, claimant: int) -> Control:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", int(round(14 * unit)))
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var me: int = _view.you.seat
	for player: Dictionary in _view.players:
		if player.id == me:
			continue
		var is_claimant: bool = player.id == claimant
		var item := VBoxContainer.new()
		item.custom_minimum_size = Vector2(80 * unit, 0)
		item.add_theme_constant_override("separation", int(round(3 * unit)))
		item.modulate = Color(1, 1, 1, 1.0 if is_claimant else 0.6)
		var avatar_row := HBoxContainer.new()
		avatar_row.alignment = BoxContainer.ALIGNMENT_CENTER
		var avatar := AvatarView.new(int(player.id), 56 * unit)
		avatar.ring = AvatarView.Ring.CLAIM if is_claimant else AvatarView.Ring.PLAIN
		avatar.dimmed = not player.alive
		avatar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		avatar_row.add_child(avatar)
		item.add_child(avatar_row)
		var name_label := UiKit.label(String(player.name).to_upper(), int(round(12 * unit)),
				UiKit.DANGER_DARK if is_claimant else UiKit.INK, true)
		name_label.autowrap_mode = TextServer.AUTOWRAP_OFF
		name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		item.add_child(name_label)
		var pill_row := HBoxContainer.new()
		pill_row.alignment = BoxContainer.ALIGNMENT_CENTER
		pill_row.add_child(CoinPill.new(int(player.coins), "", int(round(13 * unit))))
		item.add_child(pill_row)
		row.add_child(item)
	return row


## "RESPONDA EM Ns" and the headline that says who does what.
func _heading(unit: float, width: float, context: Dictionary) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", int(round(4 * unit)))
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_timer_label = UiKit.label("", int(round(11 * unit)), UiKit.DANGER_DARK)
	_timer_label.add_theme_font_override("font", UiKit.font(false, 600, 3))
	_timer_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_timer_label)
	var headline := RichTextLabel.new()
	headline.bbcode_enabled = true
	headline.fit_content = true
	headline.scroll_active = false
	headline.mouse_filter = Control.MOUSE_FILTER_IGNORE
	headline.add_theme_font_override("normal_font", UiKit.font(true, 700, 1))
	headline.add_theme_font_size_override("normal_font_size", int(round(19 * unit)))
	headline.add_theme_color_override("default_color", UiKit.INK)
	headline.custom_minimum_size = Vector2(width, 28 * unit)
	headline.text = "[center]%s[/center]" % UiKit.mark(context.headline, context.tags)
	box.add_child(headline)
	return box


## "<name> afirma ter" and the claimed card, large, tilted and glowing.
func _claim_block(unit: float, context: Dictionary) -> Control:
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", int(round(6 * unit)))
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var caption := UiKit.label("%s afirma ter" % _name(context.claimant), int(round(12 * unit)), UiKit.MUTED)
	caption.autowrap_mode = TextServer.AUTOWRAP_OFF
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(caption)
	var card_width: float = 120 * unit
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(0, card_width * CardView.DESIGN_SIZE.y / CardView.DESIGN_SIZE.x + 14 * unit)
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var card := CardView.new(context.claim, card_width)
	card.glow = Color(UiKit.CARD_STYLE[context.claim].frame, 0.7)
	card.rotation_degrees = 4.0
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(card)
	holder.resized.connect(func() -> void:
			card.position = Vector2((holder.size.x - card.size.x) / 2.0, 6 * unit))
	box.add_child(holder)
	return box


## My cards in the free space; a card I could block with is raised and glowing.
func _hand_area(unit: float, blockers: Array) -> Control:
	var area := Control.new()
	area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	area.custom_minimum_size = Vector2(0, 110 * unit)
	area.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var hand: Array = _view.you.hand
	var card_width: float = 92 * unit
	var step: float = card_width * 0.84
	var total: float = card_width + step * maxi(hand.size() - 1, 0)
	var tilts: Array[float] = [-7.0, 6.0]
	for index in range(hand.size()):
		var character: String = hand[index]
		var card := CardView.new(character, card_width)
		var raised: bool = blockers.has(character)
		card.rotation_degrees = tilts[mini(index, 1)]
		card.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if raised:
			card.glow = Color(UiKit.CARD_STYLE[character].frame, 0.75)
		else:
			card.modulate = Color(1, 1, 1, 0.85)
		var slot: int = index
		area.resized.connect(func() -> void:
				var lift: float = 16 * unit if raised else 0.0
				card.position = Vector2((area.size.x - total) / 2.0 + slot * step,
						(area.size.y - card.size.y) / 2.0 + slot * 6 * unit - lift))
		area.add_child(card)
	return area


## Block buttons (one per character that could stop it), then Desafiar / Aceitar.
func _actions(unit: float, context: Dictionary) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", int(round(10 * unit)))
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var touch: float = maxf(UiKit.touch_height(), 52 * unit)
	for character: String in context.blockers:
		box.add_child(_block_button(character, unit, touch))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", int(round(10 * unit)))
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if context.can_challenge:
		var hint: String = "%s não tem %s" % [_name(context.claimant), UiText.character(context.claim)]
		row.add_child(_choice_button("Desafiar", hint, UiKit.DANGER, {"type": "challenge"}, unit, touch))
	row.add_child(_choice_button("Aceitar", context.accept, Color("a9a6b8"), {"type": "pass"}, unit, touch))
	box.add_child(row)
	return box


func _block_button(character: String, unit: float, touch: float) -> Button:
	var style: Dictionary = UiKit.CARD_STYLE[character]
	var button := Button.new()
	button.custom_minimum_size = Vector2(0, touch)
	button.focus_mode = Control.FOCUS_NONE
	var normal: StyleBoxFlat = UiKit.box(style.frame, style.frame, 0, 12)
	var pressed: StyleBoxFlat = UiKit.box(Color(style.frame).darkened(0.15), style.frame, 0, 12)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", normal)
	button.add_theme_stylebox_override("focus", normal)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("disabled", UiKit.box(Color("c9c6d4"), Color("c9c6d4"), 0, 12))
	var ink: Color = Color("2a0e1b")
	for slot_name: String in ["font_color", "font_hover_color", "font_pressed_color", "font_disabled_color"]:
		button.add_theme_color_override(slot_name, ink)
	button.add_theme_font_size_override("font_size", int(round(17 * unit)))
	button.text = "Bloquear com %s %s" % [ARTICLES.get(character, "o"), UiText.character(character)]
	button.icon = UiKit.texture("res://assets/arte/design/icone_%s_bloqueio.svg" % character)
	button.expand_icon = true
	button.add_theme_constant_override("icon_max_width", int(round(22 * unit)))
	button.pressed.connect(_send.bind({"type": "block", "character": character}))
	_buttons.append(button)
	return button


## A white button with a title and a smaller subtitle under it.
func _choice_button(title: String, subtitle: String, border: Color, intent: Dictionary, unit: float,
		touch: float) -> Button:
	var button := Button.new()
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.custom_minimum_size = Vector2(0, touch)
	button.focus_mode = Control.FOCUS_NONE
	var normal: StyleBoxFlat = UiKit.box(UiKit.PANEL, border, 2, 12)
	var pressed: StyleBoxFlat = UiKit.box(Color("efecf6"), border, 2, 12)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", pressed)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("focus", normal)
	button.add_theme_stylebox_override("disabled", UiKit.box(Color("f1eff6"), Color("d8d4e0"), 2, 12))
	var stack := VBoxContainer.new()
	stack.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	stack.add_theme_constant_override("separation", 0)
	stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var title_label := UiKit.label(title, int(round(15 * unit)), UiKit.INK)
	title_label.add_theme_font_override("font", UiKit.font(false, 600))
	title_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_child(title_label)
	var sub_label := UiKit.label(subtitle, int(round(11 * unit)), UiKit.MUTED)
	sub_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	sub_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	sub_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_child(sub_label)
	button.add_child(stack)
	button.pressed.connect(_send.bind(intent))
	_buttons.append(button)
	return button


## One answer per window: the buttons lock until the server's update arrives.
func _send(intent: Dictionary) -> void:
	if _sent:
		return
	_sent = true
	for button: Button in _buttons:
		button.disabled = true
	responded.emit(intent)


## Redraws the bar and the "RESPONDA EM Ns" label; the last seconds are urgent.
func _refresh_timer() -> void:
	if _timer_label == null or not is_instance_valid(_timer_label):
		return
	var urgent: bool = _seconds_left <= URGENT_SECONDS
	_timer_label.text = "RESPONDA EM %ds" % int(ceil(_seconds_left))
	_timer_label.add_theme_color_override("font_color", UiKit.DANGER_DARK if urgent else UiKit.GOLD_TEXT)
	_timer_label.add_theme_font_size_override("font_size", int(round(_unit * (16 if urgent else 11))))
	_bar_fill.color = UiKit.DANGER if urgent else UiKit.GOLD
	_bar_fill.size = Vector2(_bar_back.size.x * clampf(_seconds_left / _total_seconds, 0.0, 1.0), _bar_back.size.y)
