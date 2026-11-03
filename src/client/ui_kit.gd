class_name UiKit
extends RefCounted
## Shared look of the client, from the design canvas "Cartas e moedas": a light
## lavender scene, ink text, gold ornaments, Cinzel titles over Source Sans 3
## body text. One Theme for every screen, plus small widget factories. Buttons
## are at least MIN_TOUCH high so touch works; nothing relies on hover.

# Palette (design tokens)
const BACKGROUND: Color = Color("f7f5fb")
const PANEL: Color = Color("ffffff")
const PANEL_RAISED: Color = Color("f1eef7")
const BORDER: Color = Color("d8d4e0")
const INK: Color = Color("1b1b26")
const TEXT: Color = Color("1b1b26")
const MUTED: Color = Color("6b6880")
const CREAM: Color = Color("f6efdd")
const GOLD: Color = Color("e0b24a")
const GOLD_TEXT: Color = Color("9a6f1f")
const GOLD_DARK: Color = Color("7a5a14")
const DANGER: Color = Color("d8483a")
const DANGER_DARK: Color = Color("b02e22")

## Per-character card colors: frame, title, panel fill, panel label and text,
## and the title's size and letter spacing (at the 300x420 design size).
const CARD_STYLE: Dictionary = {
	"duque": {"frame": Color("e0b24a"), "title": Color("3a2866"), "panel": Color("241740"),
			"label": Color("e0b24a"), "text": Color("f6efdd"), "title_size": 28, "spacing": 5},
	"assassino": {"frame": Color("d8483a"), "title": Color("b02e22"), "panel": Color("16151a"),
			"label": Color("f2a59b"), "text": Color("f6efdd"), "title_size": 28, "spacing": 4},
	"capitao": {"frame": Color("6fb8d0"), "title": Color("1b3f5e"), "panel": Color("10263b"),
			"label": Color("6fb8d0"), "text": Color("eef6f9"), "title_size": 30, "spacing": 5},
	"embaixador": {"frame": Color("7fd0b4"), "title": Color("1e5448"), "panel": Color("12362f"),
			"label": Color("7fd0b4"), "text": Color("eff8f4"), "title_size": 23, "spacing": 3},
	"condessa": {"frame": Color("e88faf"), "title": Color("6e2140"), "panel": Color("4a1428"),
			"label": Color("f8a9c4"), "text": Color("fbeff3"), "title_size": 28, "spacing": 4},
}

## Windows at least this wide (pixels) keep a UI scale of 1.0.
const WIDE_WINDOW: float = 1000.0
## Narrow windows scale so this many layout pixels span their width.
const REFERENCE_WIDTH: float = 720.0
const MIN_SCALE: float = 0.5
const MIN_TOUCH: float = 56.0
const BASE_FONT_SIZE: int = 20
const CARD_WIDTH: float = 120.0
const SMALL_CARD_WIDTH: float = 72.0

const _TITLE_FONT: String = "res://assets/fonts/Cinzel-Variable.ttf"
const _BODY_FONT: String = "res://assets/fonts/SourceSans3-Variable.ttf"
## OpenType tag of the weight axis ("wght").
const _WEIGHT_TAG: int = 0x77676874

static var _fonts: Dictionary = {}
static var _textures: Dictionary = {}


## The texture at [param path], kept alive for the whole session. Textures drawn
## from a Control's _draw() must be held somewhere: the canvas only stores their
## RIDs, and a texture whose last reference is a local variable is freed before
## it is painted (it then shows up white).
static func texture(path: String) -> Texture2D:
	if not _textures.has(path):
		var loaded: Texture2D = load(path) as Texture2D
		if loaded == null:
			return null
		_textures[path] = loaded
	return _textures[path]


## Cinzel (titles, names) or Source Sans 3 (body) at the given weight, with
## extra letter spacing in pixels. Cached.
static func font(title: bool, weight: int, spacing: int = 0) -> FontVariation:
	var key: String = "%s/%d/%d" % ["t" if title else "b", weight, spacing]
	if not _fonts.has(key):
		var made := FontVariation.new()
		made.base_font = load(_TITLE_FONT if title else _BODY_FONT)
		made.variation_opentype = {_WEIGHT_TAG: weight}
		made.spacing_glyph = spacing
		_fonts[key] = made
	return _fonts[key]


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
	theme.default_font = font(false, 400)
	theme.default_font_size = BASE_FONT_SIZE
	theme.set_font("font", "Button", font(false, 600))
	theme.set_color("font_color", "Label", TEXT)
	theme.set_color("default_color", "RichTextLabel", TEXT)
	theme.set_color("font_color", "Button", INK)
	theme.set_color("font_hover_color", "Button", INK)
	theme.set_color("font_pressed_color", "Button", INK)
	theme.set_color("font_hover_pressed_color", "Button", INK)
	theme.set_color("font_focus_color", "Button", INK)
	theme.set_color("font_disabled_color", "Button", MUTED)
	theme.set_color("font_color", "LineEdit", INK)
	theme.set_color("caret_color", "LineEdit", GOLD_TEXT)
	theme.set_stylebox("normal", "Button", box(PANEL, BORDER, 2, 12))
	theme.set_stylebox("hover", "Button", box(PANEL_RAISED, GOLD, 2, 12))
	theme.set_stylebox("pressed", "Button", box(GOLD, GOLD, 2, 12))
	theme.set_stylebox("hover_pressed", "Button", box(GOLD.lightened(0.1), GOLD, 2, 12))
	theme.set_stylebox("focus", "Button", box(Color(0, 0, 0, 0), GOLD_TEXT, 2, 12))
	theme.set_stylebox("disabled", "Button", box(PANEL_RAISED, BORDER, 1, 12))
	theme.set_stylebox("normal", "LineEdit", box(PANEL, BORDER, 2, 10))
	theme.set_stylebox("focus", "LineEdit", box(PANEL, GOLD, 2, 10))
	theme.set_stylebox("panel", "PanelContainer", box(PANEL, BORDER, 1, 14))
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


## A label in body text; [param title] switches to Cinzel (bold).
static func label(text: String, size: int = BASE_FONT_SIZE, color: Color = TEXT, title: bool = false) -> Label:
	var made := Label.new()
	made.text = text
	made.add_theme_font_size_override("font_size", size)
	made.add_theme_color_override("font_color", color)
	if title:
		made.add_theme_font_override("font", font(true, 700, 2))
	made.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return made


## A panel with the given fill and an optional border.
static func panel(fill: Color = PANEL, border: Color = BORDER, border_width: int = 1) -> PanelContainer:
	var made := PanelContainer.new()
	made.add_theme_stylebox_override("panel", box(fill, border, border_width, 14))
	return made


## A card showing [param character]; an empty string draws the back (hidden card).
static func card(character: String, small: bool = false) -> CardView:
	return CardView.new(character, SMALL_CARD_WIDTH if small else CARD_WIDTH)


## [param raw] as BBCode: every occurrence of a key of [param tags] is wrapped in
## its [open, close] pair (longest key first, empty keys ignored) and everything
## else is escaped, so a player named "b" or "[x]" cannot break the markup.
static func mark(raw: String, tags: Dictionary) -> String:
	var keys: Array = []
	for key: String in tags:
		if not key.is_empty():
			keys.append(key)
	keys.sort_custom(func(first: String, second: String) -> bool: return first.length() > second.length())
	var marked: String = ""
	var plain: String = ""
	var index: int = 0
	while index < raw.length():
		var matched: String = ""
		for key: String in keys:
			if raw.substr(index, key.length()) == key:
				matched = key
				break
		if matched.is_empty():
			plain += raw[index]
			index += 1
		else:
			marked += plain.replace("[", "[lb]")
			plain = ""
			marked += tags[matched][0] + matched.replace("[", "[lb]") + tags[matched][1]
			index += matched.length()
	return marked + plain.replace("[", "[lb]")


## Removes and frees every child of [param container].
static func clear(container: Node) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()
