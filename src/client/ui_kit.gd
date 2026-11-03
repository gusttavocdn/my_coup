class_name UiKit
extends RefCounted
## Shared look of the client: Renaissance-intrigue palette (warm and dark),
## one Theme for every screen and the card widget. Buttons are at least
## MIN_TOUCH high so touch works; nothing relies on hover.

const BACKGROUND: Color = Color("1a1412")
const PANEL: Color = Color("2b211c")
const PANEL_RAISED: Color = Color("3a2c24")
const GOLD: Color = Color("d4a24c")
const TEXT: Color = Color("f2e6d0")
const MUTED: Color = Color("a8957c")
const DANGER: Color = Color("c4533f")
const CARD_BACK: Color = Color("4a3426")
const CARD_COLORS: Dictionary = {
	"duque": Color("6b3fa0"),
	"assassino": Color("3a3a3a"),
	"capitao": Color("2f6fa8"),
	"embaixador": Color("3c8a5b"),
	"condessa": Color("a8402f"),
}

## Windows at least this wide (pixels) keep a UI scale of 1.0.
const WIDE_WINDOW: float = 1000.0
## Narrow windows scale so this many layout pixels span their width.
const REFERENCE_WIDTH: float = 720.0
const MIN_SCALE: float = 0.5
const MIN_TOUCH: float = 56.0
const BASE_FONT_SIZE: int = 22
const CARD_SIZE: Vector2 = Vector2(120, 150)
const SMALL_CARD_SIZE: Vector2 = Vector2(84, 100)


## Scales the whole UI to [param window]: 1.0 on wide windows, and in
## proportion to the width on narrow (phone) ones so the layout designed for
## REFERENCE_WIDTH fills the screen with readable text. Connect it to
## Window.size_changed as well as calling it once.
static func fit_scale(window: Window) -> void:
	var width: float = window.size.x
	window.content_scale_factor = 1.0 if width >= WIDE_WINDOW else maxf(width / REFERENCE_WIDTH, MIN_SCALE)


## The one Theme every screen uses; set it on the root control.
static func build_theme() -> Theme:
	var theme := Theme.new()
	theme.default_font_size = BASE_FONT_SIZE
	theme.set_color("font_color", "Label", TEXT)
	theme.set_color("default_color", "RichTextLabel", TEXT)
	theme.set_color("font_color", "Button", TEXT)
	theme.set_color("font_hover_color", "Button", TEXT)
	theme.set_color("font_pressed_color", "Button", BACKGROUND)
	theme.set_color("font_disabled_color", "Button", MUTED)
	theme.set_color("font_color", "LineEdit", TEXT)
	theme.set_stylebox("normal", "Button", box(PANEL_RAISED, GOLD, 2, 10))
	theme.set_stylebox("hover", "Button", box(PANEL_RAISED.lightened(0.12), GOLD, 2, 10))
	theme.set_stylebox("pressed", "Button", box(GOLD, GOLD, 2, 10))
	theme.set_stylebox("hover_pressed", "Button", box(GOLD.lightened(0.1), GOLD, 2, 10))
	theme.set_color("font_hover_pressed_color", "Button", BACKGROUND)
	theme.set_color("font_focus_color", "Button", TEXT)
	theme.set_stylebox("focus", "Button", box(Color(0, 0, 0, 0), TEXT, 2, 10))
	theme.set_stylebox("disabled", "Button", box(PANEL, MUTED.darkened(0.5), 1, 10))
	theme.set_stylebox("normal", "LineEdit", box(PANEL, MUTED, 1, 8))
	theme.set_stylebox("panel", "PanelContainer", box(PANEL, Color(0, 0, 0, 0), 0, 12))
	return theme


## A rounded rectangle style.
static func box(fill: Color, border: Color, border_width: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	style.set_content_margin_all(12)
	return style


## A touch-sized button.
static func button(text: String) -> Button:
	var made := Button.new()
	made.text = text
	made.custom_minimum_size = Vector2(0, MIN_TOUCH)
	return made


static func label(text: String, size: int = BASE_FONT_SIZE, color: Color = TEXT) -> Label:
	var made := Label.new()
	made.text = text
	made.add_theme_font_size_override("font_size", size)
	made.add_theme_color_override("font_color", color)
	made.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return made


## A panel with the given fill and an optional border.
static func panel(fill: Color = PANEL, border: Color = Color(0, 0, 0, 0), border_width: int = 0) -> PanelContainer:
	var made := PanelContainer.new()
	made.add_theme_stylebox_override("panel", box(fill, border, border_width, 12))
	return made


## A card showing [param character]; an empty string draws the back (hidden card).
static func card(character: String, small: bool = false) -> PanelContainer:
	var hidden: bool = character.is_empty()
	var fill: Color = CARD_BACK if hidden else CARD_COLORS.get(character, PANEL_RAISED)
	var style := box(fill, GOLD, 2, 12)
	style.set_content_margin_all(4)
	var made := PanelContainer.new()
	made.add_theme_stylebox_override("panel", style)
	made.custom_minimum_size = SMALL_CARD_SIZE if small else CARD_SIZE
	var text: String = "?" if hidden else UiText.character(character)
	var caption := label(text, 14 if small else 18, TEXT if not hidden else MUTED)
	caption.autowrap_mode = TextServer.AUTOWRAP_OFF
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	caption.size_flags_vertical = Control.SIZE_EXPAND_FILL
	made.add_child(caption)
	return made


## Removes and frees every child of [param container].
static func clear(container: Node) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()
