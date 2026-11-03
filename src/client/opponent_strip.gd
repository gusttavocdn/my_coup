class_name OpponentView
extends Control
## One opponent at the top of the table: avatar (ring marks whose turn it is), a
## small fan of cards behind it (a back per hidden influence, a crossed card per
## lost one), the name in Cinzel and the coin pill.

var _unit: float = 1.0


## Builds the opponent for [param player] (an entry of the view's players) at the
## given [param unit] scale. [param is_turn] rings the avatar in gold.
func setup(player: Dictionary, avatar_index: int, is_turn: bool, unit: float) -> void:
	_unit = unit
	var diameter: float = 76 * unit
	var width: float = 130 * unit
	custom_minimum_size = Vector2(width, diameter + 70 * unit)
	size = custom_minimum_size

	var items: Array = []
	for lost_card: String in player.revealed:
		items.append(lost_card)
	for _hidden in range(player.influence):
		items.append("")
	var fan_angles: Array[float] = [24.0, 9.0]
	for slot in range(mini(items.size(), 2)):
		var card := MiniCard.new(items[slot], unit)
		card.position = Vector2((width + diameter) / 2.0 - (28 - slot * 8) * unit, (-8 + slot * 2) * unit)
		card.rotation_degrees = fan_angles[slot]
		add_child(card)

	var avatar := AvatarView.new(avatar_index, diameter)
	avatar.position = Vector2((width - diameter) / 2.0, 0)
	avatar.ring = AvatarView.Ring.TURN if is_turn else AvatarView.Ring.PLAIN
	avatar.dimmed = not player.alive
	add_child(avatar)

	var name_label := UiKit.label(String(player.name).to_upper(), int(round(14 * unit)), UiKit.INK, true)
	name_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_label.clip_text = true
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.position = Vector2(0, diameter + 6 * unit)
	name_label.size = Vector2(width, 22 * unit)
	name_label.modulate = Color(1, 1, 1, 0.5) if not player.alive else Color.WHITE
	add_child(name_label)

	var pill := CoinPill.new(int(player.coins), "", int(round(15 * unit)))
	add_child(pill)
	var pill_size: Vector2 = pill.get_combined_minimum_size()
	pill.size = pill_size
	pill.position = Vector2((width - pill_size.x) / 2.0, diameter + 34 * unit)
	pill.modulate = Color(1, 1, 1, 0.5) if not player.alive else Color.WHITE


## A small card in the opponent's fan: a back, or a lost card crossed out in red.
class MiniCard extends Control:
	var character: String = ""

	func _init(card_character: String, unit: float) -> void:
		character = card_character
		custom_minimum_size = Vector2(38, 53) * unit
		size = custom_minimum_size
		pivot_offset = size / 2.0
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var s: float = size.x / 44.0
		if character.is_empty():
			draw_texture_rect(UiKit.texture("res://assets/arte/design/carta_mini_verso.svg"), Rect2(Vector2.ZERO, size), false)
			return
		var accent: Color = UiKit.CARD_STYLE.get(character, {}).get("frame", UiKit.GOLD)
		draw_style_box(UiKit.box(Color("f4f1ea"), accent, maxi(1, int(round(2 * s))), int(round(6 * s))), Rect2(Vector2.ZERO, size))
		draw_rect(Rect2(Vector2(1, 1) * s, Vector2(42, 14) * s), accent)
		draw_line(Vector2(6, 20) * s, Vector2(38, 56) * s, UiKit.DANGER, maxf(2.0, 4 * s), true)
		draw_line(Vector2(38, 20) * s, Vector2(6, 56) * s, UiKit.DANGER, maxf(2.0, 4 * s), true)
