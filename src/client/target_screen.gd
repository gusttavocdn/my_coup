class_name TargetScreen
extends Control
## The "escolher alvo" screen of the design: a dimmed overlay above the table with
## a header pill (the action and its cost), my cards, the coin projection, the
## prompt, one large avatar per living opponent and the Cancelar / confirm row.
## It only collects the target: it emits [signal confirmed] and holds no rules.

signal confirmed(target: int)
signal cancelled

const DESIGN: Vector2 = Vector2(390, 844)
## Verb phrases of the prompt, the confirm button and the header per targeted action.
const PROMPTS: Dictionary = {
	"assassinar": "Escolha quem assassinar",
	"extorquir": "Escolha quem extorquir",
	"golpe": "Escolha em quem dar o golpe",
}
const CONFIRMS: Dictionary = {
	"assassinar": "Assassinar %s",
	"extorquir": "Extorquir %s",
	"golpe": "Dar o golpe em %s",
}
const NO_TARGET_YET: String = "Escolha um alvo"
const INFLUENCE_ONE: String = "1 influência"
const INFLUENCE_MANY: String = "%d influências"
const COINS_COST: String = "−%d moedas"

var _action: String = ""
var _view: Dictionary = {}
var _selected: int = -1


## Opens the screen for [param action] over the table described by [param view].
func setup(action: String, view: Dictionary) -> void:
	_action = action
	_view = view
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	resized.connect(_render)
	_render()


## The chosen opponent's seat, or -1 while nothing is selected.
func selected_target() -> int:
	return _selected


## Picks [param seat] as the target (a tap on its avatar does the same).
func select(seat: int) -> void:
	_selected = seat
	_render()


func _render() -> void:
	if _action.is_empty() or size.x < 50.0:
		return
	UiKit.clear(self)
	var unit: float = clampf(minf(size.x / DESIGN.x, size.y / DESIGN.y), 0.6, 1.5)
	var dim := ColorRect.new()
	dim.color = Color(0.97, 0.96, 0.99, 0.94)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)

	var column := VBoxContainer.new()
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# Wide windows keep the phone-sized column in the middle.
	var side: float = maxf(0.0, (size.x - 460 * unit) / 2.0)
	column.offset_left = side
	column.offset_right = -side
	column.offset_top = 22 * unit
	column.offset_bottom = -22 * unit
	column.add_theme_constant_override("separation", int(round(8 * unit)))
	add_child(column)

	column.add_child(_centered(_header_pill(unit)))
	column.add_child(_hand_area(unit))
	var cost: int = int(RulesConfig.ACTIONS[_action].cost)
	if cost > 0:
		var coins: int = int(_view.players[_view.you.seat].coins)
		column.add_child(_centered(_projection_pill(coins, coins - cost, unit)))
	column.add_child(_centered(_prompt(unit)))
	column.add_child(_avatar_row(unit))
	column.add_child(_button_row(unit))


func _centered(child: Control) -> Control:
	var holder := HBoxContainer.new()
	holder.alignment = BoxContainer.ALIGNMENT_CENTER
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(child)
	return holder


func _header_pill(unit: float) -> Control:
	var pill := PanelContainer.new()
	var style: StyleBoxFlat = UiKit.box(UiKit.PANEL, UiKit.DANGER, 2, 999)
	style.content_margin_left = 10 * unit
	style.content_margin_right = 18 * unit
	style.content_margin_top = 8 * unit
	style.content_margin_bottom = 8 * unit
	pill.add_theme_stylebox_override("panel", style)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", int(round(10 * unit)))
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	pill.add_child(row)
	var disc := PanelContainer.new()
	var disc_style: StyleBoxFlat = UiKit.box(Color("34313d"), UiKit.DANGER, 2, 999)
	disc_style.set_content_margin_all(7 * unit)
	disc.add_theme_stylebox_override("panel", disc_style)
	var icon := TextureRect.new()
	icon.texture = UiKit.texture("res://assets/arte/design/medalhao_%s.svg" % ActionBar.ICONS[_action])
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2.ONE * 22 * unit
	disc.add_child(icon)
	row.add_child(disc)
	var name_label := UiKit.label(UiText.action(_action).to_upper(), int(round(15 * unit)), UiKit.INK, true)
	name_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	row.add_child(name_label)
	var cost: int = int(RulesConfig.ACTIONS[_action].cost)
	var cost_text: String = COINS_COST % cost if cost > 0 else "+%d moedas" % int(RulesConfig.ACTIONS[_action].amount)
	var cost_label := UiKit.label(cost_text, int(round(14 * unit)), UiKit.GOLD_TEXT)
	cost_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	row.add_child(cost_label)
	return pill


## My cards, tilted, in the free space between the header and the prompt.
func _hand_area(unit: float) -> Control:
	var area := Control.new()
	area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	area.custom_minimum_size = Vector2(0, 150 * unit)
	area.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var hand: Array = _view.you.hand
	var card_width: float = 110 * unit
	var step: float = card_width * 0.82
	var total: float = card_width + step * maxi(hand.size() - 1, 0)
	var tilts: Array[float] = [-7.0, 6.0]
	for index in range(hand.size()):
		var card := CardView.new(hand[index], card_width)
		card.modulate = Color(1, 1, 1, 0.8)
		card.rotation_degrees = tilts[mini(index, 1)]
		card.mouse_filter = Control.MOUSE_FILTER_IGNORE
		# Anchored to the area's center once it has a size.
		var slot: int = index
		area.resized.connect(func() -> void:
				card.position = Vector2((area.size.x - total) / 2.0 + slot * step,
						(area.size.y - card.size.y) / 2.0 + slot * 8 * unit))
		area.add_child(card)
	return area


func _projection_pill(from: int, to: int, unit: float) -> Control:
	var pill := PanelContainer.new()
	pill.add_theme_stylebox_override("panel", UiKit.box(UiKit.PANEL, UiKit.BORDER, 1, 999))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", int(round(8 * unit)))
	pill.add_child(row)
	var coin := TextureRect.new()
	coin.texture = UiKit.texture(CoinPill.COIN)
	coin.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	coin.custom_minimum_size = Vector2.ONE * 18 * unit
	row.add_child(coin)
	for part: String in ["%d" % from, "→", "%d" % to]:
		var color: Color = UiKit.MUTED if part == "→" else UiKit.GOLD_DARK
		var label := UiKit.label(part, int(round(16 * unit)), color)
		label.autowrap_mode = TextServer.AUTOWRAP_OFF
		row.add_child(label)
	return pill


func _prompt(unit: float) -> Control:
	var label := UiKit.label(String(PROMPTS[_action]).to_upper(), int(round(21 * unit)), UiKit.INK, true)
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label


func _avatar_row(unit: float) -> Control:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", int(round(12 * unit)))
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var me: int = _view.you.seat
	for player: Dictionary in _view.players:
		if player.alive and player.id != me:
			row.add_child(_avatar_slot(player, unit))
	var holder := MarginContainer.new()
	holder.add_theme_constant_override("margin_top", int(round(10 * unit)))
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(row)
	return holder


func _avatar_slot(player: Dictionary, unit: float) -> Control:
	var seat: int = player.id
	var picked: bool = seat == _selected
	var diameter: float = maxf(76 * unit, 60.0)
	var slot_width: float = maxf(104 * unit, 80.0)
	var slot := Control.new()
	slot.custom_minimum_size = Vector2(slot_width, diameter + 52 * unit)

	var stack := VBoxContainer.new()
	stack.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	stack.add_theme_constant_override("separation", int(round(5 * unit)))
	stack.alignment = BoxContainer.ALIGNMENT_BEGIN
	stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(stack)

	var avatar_row := HBoxContainer.new()
	avatar_row.alignment = BoxContainer.ALIGNMENT_CENTER
	avatar_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var avatar := AvatarView.new(seat, diameter)
	avatar.ring = AvatarView.Ring.TARGET if picked else AvatarView.Ring.PLAIN
	avatar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	avatar_row.add_child(avatar)
	stack.add_child(avatar_row)

	var name_label := UiKit.label(String(player.name).to_upper(), int(round(13 * unit)),
			UiKit.DANGER_DARK if picked else UiKit.INK, true)
	name_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_child(name_label)
	var count: int = int(player.influence)
	var influence := UiKit.label(INFLUENCE_ONE if count == 1 else INFLUENCE_MANY % count, int(round(12 * unit)), UiKit.MUTED)
	influence.autowrap_mode = TextServer.AUTOWRAP_OFF
	influence.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	influence.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_child(influence)

	var hit := Button.new()
	hit.flat = true
	hit.focus_mode = Control.FOCUS_NONE
	hit.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for state: String in ["normal", "hover", "pressed", "disabled", "focus", "hover_pressed"]:
		hit.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	hit.pressed.connect(func() -> void: select(seat))
	slot.add_child(hit)
	return slot


func _button_row(unit: float) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", int(round(10 * unit)))
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var touch: float = maxf(52 * unit, UiKit.touch_height())

	var cancel := UiKit.button(UiText.CANCEL)
	cancel.custom_minimum_size = Vector2(112 * unit, touch)
	cancel.add_theme_font_size_override("font_size", int(round(15 * unit)))
	cancel.pressed.connect(func() -> void: cancelled.emit())
	row.add_child(cancel)

	var confirm := UiKit.button(NO_TARGET_YET)
	confirm.custom_minimum_size = Vector2(0, touch)
	confirm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	confirm.add_theme_font_size_override("font_size", int(round(16 * unit)))
	var fill: StyleBoxFlat = UiKit.box(UiKit.DANGER, UiKit.DANGER, 0, 12)
	var muted: StyleBoxFlat = UiKit.box(Color("c9c6d4"), Color("c9c6d4"), 0, 12)
	for state: String in ["normal", "hover", "pressed", "focus"]:
		confirm.add_theme_stylebox_override(state, fill)
	confirm.add_theme_stylebox_override("disabled", muted)
	confirm.add_theme_color_override("font_color", Color.WHITE)
	confirm.add_theme_color_override("font_hover_color", Color.WHITE)
	confirm.add_theme_color_override("font_pressed_color", Color.WHITE)
	confirm.add_theme_color_override("font_disabled_color", Color.WHITE)
	if _selected >= 0:
		confirm.text = CONFIRMS[_action] % _view.players[_selected].name
	else:
		confirm.disabled = true
	var chosen: int = _selected
	confirm.pressed.connect(func() -> void: confirmed.emit(chosen))
	row.add_child(confirm)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", int(round(16 * unit)))
	margin.add_theme_constant_override("margin_right", int(round(16 * unit)))
	margin.add_theme_constant_override("margin_top", int(round(8 * unit)))
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(row)
	return margin
