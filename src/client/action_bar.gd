class_name ActionBar
extends HBoxContainer
## The row of action medallions of the design: general actions (Renda, Ajuda
## Externa, Golpe de Estado), a divider, then the character actions (Taxar,
## Assassinar, Extorquir, Trocar). Each medallion shows its cost or gain; the
## ones that cannot be paid are grayed out, and with 10+ coins only the Golpe is
## available. Emits the chosen action id; targets are asked for elsewhere.

signal action_chosen(action: String)

const GENERAL: Array[String] = [RulesConfig.RENDA, RulesConfig.AJUDA_EXTERNA, RulesConfig.GOLPE]
const CHARACTER_ACTIONS: Array[String] = [RulesConfig.TAXAS, RulesConfig.ASSASSINAR,
		RulesConfig.EXTORQUIR, RulesConfig.TROCAR]
const ICONS: Dictionary = {
	"renda": "renda", "ajuda_externa": "ajuda", "golpe": "golpe", "taxas": "taxar",
	"assassinar": "assassinar", "extorquir": "extorquir", "trocar": "trocar",
}
## Character whose card colors a character action's medallion.
const OWNER: Dictionary = {
	"taxas": "duque", "assassinar": "assassino", "extorquir": "capitao", "trocar": "embaixador",
}


## Builds the bar for a player with [param coins]; [param unit] scales every size
## and [param narrow] shortens the captions.
func setup(coins: int, unit: float, narrow: bool) -> void:
	UiKit.clear(self)
	add_theme_constant_override("separation", int(round(14 * unit)))
	alignment = BoxContainer.ALIGNMENT_CENTER
	for action in GENERAL:
		add_child(_medallion(action, coins, unit, narrow))
	var divider := ColorRect.new()
	divider.color = UiKit.BORDER
	divider.custom_minimum_size = Vector2(maxf(1.0, 2 * unit), 56 * unit)
	divider.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	add_child(divider)
	for action in CHARACTER_ACTIONS:
		add_child(_medallion(action, coins, unit, narrow))


func _medallion(action: String, coins: int, unit: float, narrow: bool) -> Medallion:
	var definition: Dictionary = RulesConfig.ACTIONS[action]
	var made := Medallion.new()
	made.unit = unit
	made.art = UiKit.texture("res://assets/arte/design/medalhao_%s.svg" % ICONS[action])
	made.badge = _badge(action, definition)
	made.caption = UiText.ACTION_SHORT.get(action, UiText.action(action)) if narrow else UiText.action(action)
	if OWNER.has(action):
		var style: Dictionary = UiKit.CARD_STYLE[OWNER[action]]
		made.fill = style.panel
		made.ring = style.frame
	made.disabled = coins < int(definition.cost) \
			or (coins >= RulesConfig.FORCED_COUP_COINS and action != RulesConfig.GOLPE)
	made.refresh_size()
	# A drag that scrolls the bar sideways also releases over a medallion; that is not a tap.
	made.pressed.connect(func() -> void:
		if not made.dragged:
			action_chosen.emit(action))
	return made


func _badge(action: String, definition: Dictionary) -> String:
	if action == RulesConfig.TROCAR:
		return "2:2"
	if int(definition.cost) > 0:
		return "−%d" % definition.cost
	return "+%d" % definition.amount


## One round action button: dark disc (or the character's colors), icon, a small
## cost/gain badge on its corner and a caption underneath.
class Medallion extends Button:
	var unit: float = 1.0
	var art: Texture2D
	var fill: Color = UiKit.INK
	var ring: Color = UiKit.CREAM
	var badge: String = ""
	var caption: String = ""
	## True when the pointer moved beyond the tap slop since it went down.
	var dragged: bool = false
	var _press_at: Vector2 = Vector2.ZERO

	func _init() -> void:
		flat = true
		focus_mode = Control.FOCUS_NONE
		for state: String in ["normal", "hover", "pressed", "disabled", "focus", "hover_pressed"]:
			add_theme_stylebox_override(state, StyleBoxEmpty.new())

	## Computes the minimum size from the unit, caption and fonts; call after setting them.
	func refresh_size() -> void:
		var diameter: float = 64 * unit
		var caption_width: float = UiKit.font(false, 600).get_string_size(
				caption, HORIZONTAL_ALIGNMENT_LEFT, -1, int(round(13 * unit))).x
		custom_minimum_size = Vector2(
				maxf(maxf(maxf(diameter + 18 * unit, 78 * unit), caption_width + 8 * unit), UiKit.touch_height()),
				maxf(diameter + 34 * unit, UiKit.touch_height()))

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_press_at = event.global_position
			dragged = false
		elif event is InputEventMouseMotion and (event.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
			if event.global_position.distance_to(_press_at) > UiKit.css_to_layout(UiKit.DRAG_SLOP):
				dragged = true

	func _draw() -> void:
		var diameter: float = 64 * unit
		var center := Vector2(size.x / 2.0, diameter / 2.0 + 2 * unit)
		var shown_fill: Color = Color("b9b6c4") if disabled else (fill.darkened(0.25) if button_pressed or is_pressed() else fill)
		var shown_ring: Color = Color("d8d4e0") if disabled else (UiKit.GOLD if is_hovered() or is_pressed() else ring)
		draw_circle(center, diameter / 2.0, shown_fill)
		draw_arc(center, diameter / 2.0 - 1.5 * unit, 0.0, TAU, 48, shown_ring, maxf(2.0, 3 * unit), true)
		if art != null:
			var icon_size: float = diameter * 0.5
			draw_texture_rect(art, Rect2(center - Vector2.ONE * icon_size / 2.0, Vector2.ONE * icon_size), false,
					Color(1, 1, 1, 0.55 if disabled else 1.0))
		if not badge.is_empty():
			var badge_font: FontVariation = UiKit.font(false, 600)
			var font_size: int = int(round(12 * unit))
			var badge_size: Vector2 = badge_font.get_string_size(badge, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
			var pill := Rect2(center + Vector2(diameter * 0.22, diameter * 0.26),
					badge_size + Vector2(10 * unit, 4 * unit))
			draw_style_box(UiKit.box(UiKit.PANEL, UiKit.BORDER, 1, 99), pill)
			draw_string(badge_font, pill.position + Vector2(5 * unit, badge_size.y * 0.85 + 1 * unit), badge,
					HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, UiKit.MUTED if disabled else UiKit.INK)
		draw_string(UiKit.font(false, 600), Vector2(0, diameter + 24 * unit), caption,
				HORIZONTAL_ALIGNMENT_CENTER, size.x, int(round(13 * unit)), UiKit.MUTED if disabled else UiKit.INK)
