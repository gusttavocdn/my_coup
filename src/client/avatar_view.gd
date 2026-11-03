class_name AvatarView
extends Control
## A round player avatar with a state ring: plain (cream), turn (gold),
## claim (red, the player whose claim is being answered) or target (red with a
## crosshair and halo, the player picked as target). Six illustrated avatars.

enum Ring { PLAIN, TURN, CLAIM, TARGET }

const NAMES: Array[String] = ["marina", "rafa", "bia", "caio", "duda", "leo"]
const ART_DIR: String = "res://assets/arte/design/avatar_%s.svg"

## Index into NAMES (wraps around), so a seat number can be used directly.
var avatar: int = 0:
	set(value):
		avatar = value
		queue_redraw()
var ring: Ring = Ring.PLAIN:
	set(value):
		ring = value
		queue_redraw()
## A player who is out of the game: shown faded.
var dimmed: bool = false:
	set(value):
		dimmed = value
		modulate = Color(1, 1, 1, 0.5) if dimmed else Color(1, 1, 1, 1)


## An avatar of [param avatar_index] that is [param diameter] pixels wide.
func _init(avatar_index: int = 0, diameter: float = 76.0) -> void:
	avatar = avatar_index
	custom_minimum_size = Vector2(diameter, diameter)
	size = custom_minimum_size
	mouse_filter = Control.MOUSE_FILTER_PASS


func _draw() -> void:
	var diameter: float = minf(size.x, size.y)
	var center: Vector2 = size / 2.0
	var radius: float = diameter / 2.0
	var ring_width: float = maxf(2.0, diameter * 0.05)
	var ring_color: Color = UiKit.CREAM
	match ring:
		Ring.TURN:
			ring_color = UiKit.GOLD
		Ring.CLAIM, Ring.TARGET:
			ring_color = UiKit.DANGER
	if ring == Ring.CLAIM or ring == Ring.TARGET:
		draw_circle(center, radius + ring_width * 1.2, Color(UiKit.DANGER, 0.22))

	var art: Texture2D = UiKit.texture(ART_DIR % NAMES[posmod(avatar, NAMES.size())])
	var inset: float = ring_width
	draw_texture_rect(art, Rect2(Vector2.ONE * inset, Vector2.ONE * (diameter - 2 * inset)), false)
	draw_arc(center, radius - ring_width / 2.0, 0.0, TAU, 64, ring_color, ring_width, true)

	if ring == Ring.TARGET:
		var aim: float = radius * 0.62
		draw_arc(center, aim, 0.0, TAU, 48, Color(1, 1, 1, 0.9), ring_width * 0.6, true)
		for direction: Vector2 in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
			draw_line(center + direction * (aim - ring_width * 2.0), center + direction * (aim + ring_width * 2.0),
					Color(1, 1, 1, 0.9), ring_width * 0.6, true)
