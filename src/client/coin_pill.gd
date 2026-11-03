class_name CoinPill
extends PanelContainer
## The coin counter pill of the design: a gold coin and a number in a rounded
## white capsule, optionally preceded by a caption ("Tesouro 32", "Baralho 9").

const COIN: String = "res://assets/arte/design/moeda_icone.svg"

## The number shown.
var value: int = 0:
	set(new_value):
		value = new_value
		_refresh()

var _caption: String = ""
var _label: Label


## A pill showing [param amount]; [param caption] ("" for none) goes before the number
## and replaces the coin icon with plain text.
func _init(amount: int = 0, caption: String = "", font_size: int = 16) -> void:
	_caption = caption
	var capsule := UiKit.box(UiKit.PANEL, UiKit.BORDER, 1, 999)
	capsule.set_content_margin_all(0)
	capsule.content_margin_left = 10
	capsule.content_margin_right = 12
	capsule.content_margin_top = 3
	capsule.content_margin_bottom = 3
	add_theme_stylebox_override("panel", capsule)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 5)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(row)
	if caption.is_empty():
		var icon := TextureRect.new()
		icon.texture = UiKit.texture(COIN)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.custom_minimum_size = Vector2.ONE * (font_size + 2)
		row.add_child(icon)
	_label = UiKit.label("", font_size, UiKit.GOLD_DARK)
	_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_label.add_theme_font_override("font", UiKit.font(false, 600))
	row.add_child(_label)
	value = amount


func _refresh() -> void:
	if _label == null:
		return
	_label.text = ("%s %d" % [_caption, value]) if not _caption.is_empty() else str(value)
