class_name CardView
extends Control
## One playing card, drawn from the design canvas: a character face (frame,
## Cinzel name, faceted portrait, action and block rows) or the card back.
## Everything is laid out in the design's 300x420 space and scaled to the
## control's width, so one widget serves the hand, the opponents and the result.
##
## States: [member lost] dims the card and crosses it out (an influence already
## lost), [member glow] adds a colored halo (selected, claimed, can block). Tilt a
## card with the control's own rotation_degrees.

const DESIGN_SIZE: Vector2 = Vector2(300, 420)
const ART_DIR: String = "res://assets/arte/design/"
const RIM: Color = Color("d8d4e0")
const BACK_OUTER: Color = Color("1b1b26")
const BACK_INNER: Color = Color("262636")
const BACK_GOLD: Color = Color("c9a24a")

## Character id ("duque", "assassino", "capitao", "embaixador", "condessa"), or
## "" for the card back.
var character: String = "":
	set(value):
		character = value
		_refresh()
## An influence already lost: dimmed and crossed out.
var lost: bool = false:
	set(value):
		lost = value
		modulate = Color(1, 1, 1, 0.6) if lost else Color(1, 1, 1, 1)
		_overlay.queue_redraw()
## Halo color; fully transparent means no halo.
var glow: Color = Color(0, 0, 0, 0):
	set(value):
		glow = value
		queue_redraw()

var _portrait_mask: Panel
var _portrait: TextureRect
var _portrait_frame: Panel
var _overlay: Control


## A card of [param card_character] ("" = back) that is [param width] wide; the
## height follows the design's proportions.
func _init(card_character: String = "", width: float = 120.0) -> void:
	custom_minimum_size = Vector2(width, width * DESIGN_SIZE.y / DESIGN_SIZE.x)
	size = custom_minimum_size
	mouse_filter = Control.MOUSE_FILTER_PASS

	_portrait_mask = Panel.new()
	_portrait_mask.clip_children = CanvasItem.CLIP_CHILDREN_ONLY
	_portrait_mask.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_portrait_mask)
	_portrait = TextureRect.new()
	_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_portrait_mask.add_child(_portrait)
	_portrait_frame = Panel.new()
	_portrait_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_portrait_frame)
	_overlay = Control.new()
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.draw.connect(_draw_overlay)
	add_child(_overlay)
	character = card_character
	pivot_offset = size / 2.0


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		pivot_offset = size / 2.0
		_layout()


func _layout() -> void:
	if _portrait_mask == null:
		return
	var scale_factor: float = size.x / DESIGN_SIZE.x
	var rect := Rect2(Vector2(24, 64) * scale_factor, Vector2(252, 209) * scale_factor)
	var radius: int = int(round(10 * scale_factor))
	for panel: Panel in [_portrait_mask, _portrait_frame]:
		panel.position = rect.position
		panel.size = rect.size
	_portrait.size = rect.size
	_portrait_mask.add_theme_stylebox_override("panel", UiKit.box(Color.WHITE, Color(0, 0, 0, 0), 0, radius))
	var accent: Color = _style().get("frame", UiKit.GOLD)
	_portrait_frame.add_theme_stylebox_override("panel",
			UiKit.box(Color(0, 0, 0, 0), accent, maxi(1, int(round(3 * scale_factor))), radius))
	_overlay.position = Vector2.ZERO
	_overlay.size = size
	queue_redraw()


func _refresh() -> void:
	if _portrait == null:
		return
	var face: bool = UiKit.CARD_STYLE.has(character)
	_portrait_mask.visible = face
	_portrait_frame.visible = face
	if face:
		_portrait.texture = UiKit.texture("%sretrato_%s.svg" % [ART_DIR, character])
	_layout()


func _style() -> Dictionary:
	return UiKit.CARD_STYLE.get(character, {})


func _draw() -> void:
	var scale_factor: float = size.x / DESIGN_SIZE.x
	if glow.a > 0.0:
		var halo := UiKit.box(Color.WHITE, Color(0, 0, 0, 0), 0, int(round(18 * scale_factor)))
		halo.shadow_color = glow
		halo.shadow_size = int(round(26 * scale_factor))
		draw_style_box(halo, Rect2(Vector2.ZERO, size))
	if not UiKit.CARD_STYLE.has(character):
		_draw_back(scale_factor)
	else:
		_draw_face(scale_factor)


func _draw_back(scale_factor: float) -> void:
	var outer := UiKit.box(BACK_OUTER, Color(0, 0, 0, 0), 0, int(round(18 * scale_factor)))
	draw_style_box(outer, Rect2(Vector2.ZERO, size))
	var inner := UiKit.box(BACK_INNER, BACK_GOLD, maxi(1, int(round(2 * scale_factor))), int(round(12 * scale_factor)))
	draw_style_box(inner, Rect2(Vector2(10, 10) * scale_factor, Vector2(280, 400) * scale_factor))
	# The canvas tiles a 36 px diamond lattice behind the rosette; SVG patterns are not rendered.
	var lattice: Color = Color("3a3a52")
	for column in range(7):
		for row in range(11):
			var origin: Vector2 = Vector2(12 + column * 36, 12 + row * 36)
			var diamond := PackedVector2Array()
			for corner: Vector2 in [Vector2(18, 0), Vector2(36, 18), Vector2(18, 36), Vector2(0, 18), Vector2(18, 0)]:
				diamond.append((origin + corner) * scale_factor)
			draw_polyline(diamond, lattice, maxf(1.0, 2 * scale_factor), true)
			draw_circle((origin + Vector2(18, 18)) * scale_factor, 2.5 * scale_factor, lattice)
	var art: Texture2D = UiKit.texture(ART_DIR + "verso.svg")
	draw_texture_rect(art, Rect2(Vector2(12, 12) * scale_factor, Vector2(276, 396) * scale_factor), false)


func _draw_face(scale_factor: float) -> void:
	var style: Dictionary = _style()
	var accent: Color = style.frame
	var outer := UiKit.box(Color.WHITE, RIM, maxi(1, int(round(2 * scale_factor))), int(round(18 * scale_factor)))
	outer.shadow_color = Color(0.1, 0.08, 0.2, 0.16)
	outer.shadow_size = int(round(7 * scale_factor))
	outer.shadow_offset = Vector2(0, 3 * scale_factor)
	draw_style_box(outer, Rect2(Vector2.ZERO, size))
	var frame := UiKit.box(Color.WHITE, accent, maxi(1, int(round(3 * scale_factor))), int(round(12 * scale_factor)))
	draw_style_box(frame, Rect2(Vector2(11, 11) * scale_factor, Vector2(278, 398) * scale_factor))

	var spacing_px: int = int(round(float(style.spacing) * scale_factor))
	var title_font: FontVariation = UiKit.font(true, 700, spacing_px)
	# spacing_glyph also trails the last letter, so shift half of it back to stay centered.
	draw_string(title_font, Vector2(spacing_px * 0.5, 56 * scale_factor), UiText.character(character).to_upper(),
			HORIZONTAL_ALIGNMENT_CENTER, size.x, int(round(float(style.title_size) * scale_factor)), style.title)

	var panel := UiKit.box(style.panel, accent, maxi(1, int(round(3 * scale_factor))), int(round(10 * scale_factor)))
	draw_style_box(panel, Rect2(Vector2(24, 285) * scale_factor, Vector2(252, 112) * scale_factor))
	draw_line(Vector2(34, 341) * scale_factor, Vector2(266, 341) * scale_factor,
			Color(accent, 0.5), maxf(1.0, 2 * scale_factor))
	var text: Dictionary = UiText.CARD_TEXT[character]
	_draw_row(text.action, 294.0, 303.0, 309.0, 318.0, 327.0, "%sicone_%s_acao.svg" % [ART_DIR, character], scale_factor, style)
	_draw_row(text.block, 350.0, 365.0, 365.0, 383.0, 383.0, "%sicone_%s_bloqueio.svg" % [ART_DIR, character], scale_factor, style)


## One panel row: icon at [param icon_y], label and one or two description lines.
func _draw_row(row: Array, icon_y: float, label_y_two: float, label_y_one: float, first_y: float,
		single_y: float, icon_path: String, scale_factor: float, style: Dictionary) -> void:
	var icon: Texture2D = UiKit.texture(icon_path)
	draw_texture_rect(icon, Rect2(Vector2(34, icon_y) * scale_factor, Vector2(38, 38) * scale_factor), false)
	var lines: Array = row[1]
	var label_font: FontVariation = UiKit.font(false, 600, int(round(2 * scale_factor)))
	var body_font: FontVariation = UiKit.font(false, 400)
	var label_size: int = int(round(11 * scale_factor))
	var body_size: int = int(round(13 * scale_factor))
	var left: float = 82 * scale_factor
	if lines.size() == 1:
		draw_string(label_font, Vector2(left, label_y_one * scale_factor), row[0], HORIZONTAL_ALIGNMENT_LEFT, -1, label_size, style.label)
		draw_string(body_font, Vector2(left, single_y * scale_factor), lines[0], HORIZONTAL_ALIGNMENT_LEFT, -1, body_size, style.text)
	else:
		draw_string(label_font, Vector2(left, label_y_two * scale_factor), row[0], HORIZONTAL_ALIGNMENT_LEFT, -1, label_size, style.label)
		draw_string(body_font, Vector2(left, first_y * scale_factor), lines[0], HORIZONTAL_ALIGNMENT_LEFT, -1, body_size, style.text)
		draw_string(body_font, Vector2(left, (first_y + 14) * scale_factor), lines[1], HORIZONTAL_ALIGNMENT_LEFT, -1, body_size, style.text)


func _draw_overlay() -> void:
	if not lost:
		return
	var scale_factor: float = size.x / DESIGN_SIZE.x
	var width: float = maxf(2.0, 8 * scale_factor)
	_overlay.draw_line(Vector2(40, 80) * scale_factor, Vector2(260, 340) * scale_factor, UiKit.DANGER, width, true)
	_overlay.draw_line(Vector2(260, 80) * scale_factor, Vector2(40, 340) * scale_factor, UiKit.DANGER, width, true)
