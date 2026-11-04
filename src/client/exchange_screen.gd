class_name ExchangeScreen
extends Control
## The Embaixador exchange screen, in the style of the loss screen: the pool of
## cards (my hand plus the two drawn) face up; tap to choose exactly as many as
## I have influences, then "Confirmar troca" sends the indices into that pool
## (hand first, then drawn) through [signal confirmed].

signal confirmed(keep: Array)

const DESIGN: Vector2 = Vector2(390, 844)
const TITLE: String = "TROCA DO EMBAIXADOR"
const PICK_PROMPT: String = "Escolha %d carta(s) para ficar com você."
const COUNTER: String = "%d de %d escolhidas"
const CONFIRM: String = "Confirmar troca"
const OWN_CARD: String = "SUA"
const NEW_CARD: String = "NOVA"

var _view: Dictionary = {}
var _picks: Array[int] = []
var _sent: bool = false


## Opens the screen for [param view] (Room.view_for) while I owe an exchange.
func setup(view: Dictionary) -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_view = view
	resized.connect(_render)
	_render()


## Takes a fresh server view while the screen is already open: nothing is
## chosen and the button is live again.
func update_view(view: Dictionary) -> void:
	_view = view
	_picks.clear()
	_sent = false
	_render()


## The chosen pool indices, in the order they were picked.
func picks() -> Array[int]:
	return _picks.duplicate()


## Toggles the card at pool [param index] (a tap on it does the same); a card
## beyond the allowed count is ignored until another one is put back.
func toggle(index: int) -> void:
	if _sent:
		return
	if _picks.has(index):
		_picks.erase(index)
	elif _picks.size() < _keep_count():
		_picks.append(index)
	_render()


func _keep_count() -> int:
	return _view.you.hand.size()


func _pool() -> Array:
	return _view.you.hand + _view.exchange.drawn


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
	column.offset_top = 40 * unit
	column.offset_bottom = -24 * unit
	column.add_theme_constant_override("separation", int(round(10 * unit)))
	add_child(column)

	var title := UiKit.label(TITLE, int(round(22 * unit)), UiKit.INK, true)
	title.autowrap_mode = TextServer.AUTOWRAP_OFF
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)
	var prompt := UiKit.label(PICK_PROMPT % _keep_count(), int(round(15 * unit)), UiKit.MUTED)
	prompt.autowrap_mode = TextServer.AUTOWRAP_OFF
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(prompt)
	column.add_child(_cards_area(unit, column_width))
	column.add_child(_footer(unit))


## The pool in one row; chosen cards are raised and glow gold.
func _cards_area(unit: float, width: float) -> Control:
	var area := Control.new()
	area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	area.custom_minimum_size = Vector2(0, 170 * unit)
	var pool: Array = _pool()
	var gap: float = 10 * unit
	var card_width: float = minf(110 * unit, (width - gap * 3) / 4.0)
	var total: float = card_width * pool.size() + gap * maxi(pool.size() - 1, 0)
	var own_count: int = _view.you.hand.size()
	for index in range(pool.size()):
		var slot: int = index
		var picked: bool = _picks.has(index)
		var card := CardView.new(pool[index], card_width)
		card.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if picked:
			card.glow = Color(UiKit.GOLD, 0.8)
		elif _picks.size() == _keep_count():
			card.modulate = Color(1, 1, 1, 0.7)
		var caption := UiKit.label(OWN_CARD if index < own_count else NEW_CARD, int(round(11 * unit)),
				UiKit.GOLD_TEXT if picked else UiKit.MUTED)
		caption.autowrap_mode = TextServer.AUTOWRAP_OFF
		caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		caption.size = Vector2(card_width, 16 * unit)
		caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var hit := Button.new()
		hit.flat = true
		hit.focus_mode = Control.FOCUS_NONE
		hit.size = card.size + Vector2(0, 20 * unit)
		for state: String in ["normal", "hover", "pressed", "disabled", "focus", "hover_pressed"]:
			hit.add_theme_stylebox_override(state, StyleBoxEmpty.new())
		hit.pressed.connect(func() -> void: toggle(slot))
		area.add_child(card)
		area.add_child(caption)
		area.add_child(hit)
		area.resized.connect(func() -> void:
				var lift: float = 14 * unit if picked else 0.0
				var origin := Vector2((area.size.x - total) / 2.0 + slot * (card_width + gap),
						(area.size.y - card.size.y) / 2.0 - lift)
				card.position = origin
				caption.position = origin + Vector2(0, card.size.y + 4 * unit)
				hit.position = origin)
	return area


func _footer(unit: float) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", int(round(10 * unit)))
	var counter := UiKit.label(COUNTER % [_picks.size(), _keep_count()], int(round(13 * unit)), UiKit.MUTED)
	counter.autowrap_mode = TextServer.AUTOWRAP_OFF
	counter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(counter)
	var confirm := UiKit.button(CONFIRM)
	confirm.custom_minimum_size = Vector2(0, maxf(UiKit.touch_height(), 56 * unit))
	confirm.add_theme_font_size_override("font_size", int(round(17 * unit)))
	var fill: StyleBoxFlat = UiKit.box(UiKit.GOLD, UiKit.GOLD, 0, 12)
	var muted: StyleBoxFlat = UiKit.box(Color("c9c6d4"), Color("c9c6d4"), 0, 12)
	for state: String in ["normal", "hover", "pressed", "focus"]:
		confirm.add_theme_stylebox_override(state, fill)
	confirm.add_theme_stylebox_override("disabled", muted)
	for slot_name: String in ["font_color", "font_hover_color", "font_pressed_color"]:
		confirm.add_theme_color_override(slot_name, UiKit.INK)
	confirm.add_theme_color_override("font_disabled_color", Color.WHITE)
	confirm.disabled = _picks.size() != _keep_count()
	confirm.pressed.connect(func() -> void:
			if _sent:
				return
			_sent = true
			confirm.disabled = true
			confirmed.emit(_picks.duplicate()))
	box.add_child(confirm)
	return box
