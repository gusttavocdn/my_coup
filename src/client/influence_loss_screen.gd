class_name InfluenceLossScreen
extends Control
## The "você perde uma influência" screen of the design: an overlay shown while
## I must reveal one of my cards. It names what caused it, lays my cards side by
## side and lets me pick one (raised with a red glow, the other dims); the red
## button reads the consequence ("Revelar Duque") and emits [signal chosen].

signal chosen(card_index: int)

const DESIGN: Vector2 = Vector2(390, 844)
const TITLE: String = "VOCÊ PERDE\nUMA INFLUÊNCIA"
const PICK_HINT: String = "Toque na carta que quer revelar."
const KEEP_FACE_UP: String = "A carta fica virada para cima e sai do jogo."
const NOTHING_PICKED: String = "Escolha uma carta"

var _view: Dictionary = {}
var _cause: String = ""
var _selected: int = -1
var _sent: bool = false


## Opens the screen for [param view] (Room.view_for); [param cause] is a line
## such as "Você foi pego blefando." (empty: derived from the pending action).
func setup(view: Dictionary, cause: String) -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_view = view
	_cause = cause
	resized.connect(_render)
	_render()


## The picked card's index in my hand, or -1.
func selected_index() -> int:
	return _selected


## Picks the card at [param index] (a tap on it does the same).
func select(index: int) -> void:
	if _sent:
		return
	_selected = index
	_render()


## The sentence naming who or what made me lose an influence.
func _cause_text() -> Array:
	if not _cause.is_empty():
		var names: Dictionary = {}
		for player: Dictionary in _view.players:
			names[player.name] = ["[b]", "[/b]"]
		return [_cause, names]
	var pending: Dictionary = _view.pending_action
	var me: int = _view.you.seat
	if not pending.is_empty() and pending.get("target", -1) == me:
		var actor: String = _view.players[pending.actor].name
		match pending.action:
			"assassinar":
				return ["%s assassinou você." % actor, {actor: ["[b]", "[/b]"]}]
			"golpe":
				return ["%s deu um golpe de estado em você." % actor, {actor: ["[b]", "[/b]"]}]
	return ["", {}]


func _render() -> void:
	if _view.is_empty() or size.x < 50.0:
		return
	UiKit.clear(self)
	var unit: float = clampf(minf(size.x / DESIGN.x, size.y / DESIGN.y), 0.6, 1.5)
	var backdrop := ColorRect.new()
	backdrop.color = Color(0.97, 0.96, 0.99, 1.0)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop)

	var column_width: float = minf(size.x, 460 * unit)
	var side: float = (size.x - column_width) / 2.0
	var column := VBoxContainer.new()
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	column.offset_left = side
	column.offset_right = -side
	column.offset_top = 36 * unit
	column.offset_bottom = -24 * unit
	column.add_theme_constant_override("separation", int(round(10 * unit)))
	add_child(column)

	column.add_child(_centered(_badge(unit)))
	var title := UiKit.label(TITLE, int(round(24 * unit)), UiKit.INK, true)
	title.autowrap_mode = TextServer.AUTOWRAP_OFF
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)
	column.add_child(_cause_block(unit, column_width))
	column.add_child(_cards_area(unit))
	column.add_child(_footer(unit))


func _centered(child: Control) -> Control:
	var holder := HBoxContainer.new()
	holder.alignment = BoxContainer.ALIGNMENT_CENTER
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(child)
	return holder


## The round red badge with a crossed card.
func _badge(unit: float) -> Control:
	var badge := LossBadge.new()
	badge.custom_minimum_size = Vector2.ONE * 56 * unit
	return badge


func _cause_block(unit: float, width: float) -> Control:
	var text: RichTextLabel = RichTextLabel.new()
	text.bbcode_enabled = true
	text.fit_content = true
	text.scroll_active = false
	text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text.add_theme_font_size_override("normal_font_size", int(round(15 * unit)))
	text.add_theme_font_size_override("bold_font_size", int(round(15 * unit)))
	text.add_theme_font_override("bold_font", UiKit.font(false, 700))
	text.add_theme_color_override("default_color", UiKit.MUTED)
	text.custom_minimum_size = Vector2(width, 20 * unit)
	var cause: Array = _cause_text()
	var line: String = String(cause[0])
	var body: String = (line + "\n" if not line.is_empty() else "") + PICK_HINT
	var tags: Dictionary = cause[1].duplicate()
	for key: String in tags:
		tags[key] = ["[b][color=#%s]" % UiKit.INK.to_html(false), "[/color][/b]"]
	text.text = "[center]%s[/center]" % UiKit.mark(body, tags)
	return text


## My cards, large and side by side; the chosen one is raised and red-glowing.
func _cards_area(unit: float) -> Control:
	var area := Control.new()
	area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	area.custom_minimum_size = Vector2(0, 190 * unit)
	var hand: Array = _view.you.hand
	var card_width: float = 150 * unit
	var gap: float = 14 * unit
	var total: float = card_width * hand.size() + gap * maxi(hand.size() - 1, 0)
	for index in range(hand.size()):
		var slot: int = index
		var picked: bool = index == _selected
		var card := CardView.new(hand[index], card_width)
		card.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if picked:
			card.glow = Color(UiKit.DANGER, 0.7)
		elif _selected >= 0:
			card.modulate = Color(1, 1, 1, 0.7)
		var hit := Button.new()
		hit.flat = true
		hit.focus_mode = Control.FOCUS_NONE
		hit.size = card.size
		for state: String in ["normal", "hover", "pressed", "disabled", "focus", "hover_pressed"]:
			hit.add_theme_stylebox_override(state, StyleBoxEmpty.new())
		hit.pressed.connect(func() -> void: select(slot))
		area.add_child(card)
		area.add_child(hit)
		area.resized.connect(func() -> void:
				var lift: float = 14 * unit if picked else 0.0
				var origin := Vector2((area.size.x - total) / 2.0 + slot * (card_width + gap),
						(area.size.y - card.size.y) / 2.0 - lift)
				card.position = origin
				hit.position = origin)
	return area


## The "stays face up" hint and the red confirm button.
func _footer(unit: float) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", int(round(10 * unit)))
	var hint := UiKit.label(KEEP_FACE_UP, int(round(13 * unit)), UiKit.MUTED)
	hint.autowrap_mode = TextServer.AUTOWRAP_OFF
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(hint)
	var confirm := UiKit.button(NOTHING_PICKED)
	confirm.custom_minimum_size = Vector2(0, maxf(UiKit.MIN_TOUCH, 56 * unit))
	confirm.add_theme_font_size_override("font_size", int(round(17 * unit)))
	var fill: StyleBoxFlat = UiKit.box(UiKit.DANGER, UiKit.DANGER, 0, 12)
	var muted: StyleBoxFlat = UiKit.box(Color("c9c6d4"), Color("c9c6d4"), 0, 12)
	for state: String in ["normal", "hover", "pressed", "focus"]:
		confirm.add_theme_stylebox_override(state, fill)
	confirm.add_theme_stylebox_override("disabled", muted)
	for slot_name: String in ["font_color", "font_hover_color", "font_pressed_color", "font_disabled_color"]:
		confirm.add_theme_color_override(slot_name, Color.WHITE)
	if _selected >= 0:
		confirm.text = "Revelar %s" % UiText.character(_view.you.hand[_selected])
		var index: int = _selected
		confirm.pressed.connect(func() -> void:
				if _sent:
					return
				_sent = true
				confirm.disabled = true
				chosen.emit(index))
	else:
		confirm.disabled = true
	box.add_child(confirm)
	return box


## A red disc with a card crossed out, the icon of a lost influence.
class LossBadge extends Control:
	func _draw() -> void:
		var center: Vector2 = size / 2.0
		var radius: float = minf(size.x, size.y) / 2.0
		draw_circle(center, radius, Color(UiKit.DANGER, 0.18))
		draw_arc(center, radius - 1.0, 0.0, TAU, 48, UiKit.DANGER, 2.0, true)
		var card := Rect2(center - Vector2(radius * 0.32, radius * 0.45), Vector2(radius * 0.64, radius * 0.9))
		draw_rect(card, Color("f2a59b"), false, maxf(2.0, radius * 0.08))
		draw_line(card.position, card.end, Color("f2a59b"), maxf(2.0, radius * 0.09), true)
