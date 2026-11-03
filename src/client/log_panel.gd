class_name LogPanel
extends PanelContainer
## The "REGISTRO" card of the design: the latest events, newest last, with the
## acting player's name in bold. On phones the same card is shown as a sheet.

var _lines: RichTextLabel
var _title: Label


func _init() -> void:
	add_theme_stylebox_override("panel", UiKit.box(UiKit.PANEL, UiKit.BORDER, 1, 14))
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	add_child(column)
	_title = UiKit.label(UiText.LOG_TITLE, 12, UiKit.GOLD_TEXT, true)
	_title.autowrap_mode = TextServer.AUTOWRAP_OFF
	column.add_child(_title)
	_lines = RichTextLabel.new()
	_lines.bbcode_enabled = true
	_lines.fit_content = true
	_lines.scroll_active = false
	_lines.custom_minimum_size = Vector2(0, 20)
	_lines.add_theme_font_size_override("normal_font_size", 14)
	_lines.add_theme_font_size_override("bold_font_size", 14)
	_lines.add_theme_font_override("bold_font", UiKit.font(false, 600))
	column.add_child(_lines)


## Gives the text a width, so the card's height can be measured before layout.
func set_content_width(width: float) -> void:
	_lines.custom_minimum_size.x = width


## Hides or shows the "REGISTRO" heading (a sheet already has its own title).
func set_title_visible(shown: bool) -> void:
	_title.visible = shown


## Shows the last [param count] of [param lines]; names in [param names] are bolded.
func show_lines(lines: Array[String], names: Array, count: int, font_size: int = 14, compact: bool = false) -> void:
	_lines.add_theme_font_size_override("normal_font_size", font_size)
	_lines.add_theme_font_size_override("bold_font_size", font_size)
	var shown: Array[String] = []
	for line: String in lines.slice(maxi(0, lines.size() - count)):
		var tags: Dictionary = {}
		for player_name: String in names:
			tags[player_name] = ["[b]", "[/b]"]
		shown.append(UiKit.mark(line, tags))
	if compact:
		# Height from the line count: a fit_content label measured before layout reports too much.
		_lines.fit_content = false
		_lines.custom_minimum_size.y = maxi(1, shown.size()) * (font_size + 8)
	_lines.text = "\n".join(shown) if not shown.is_empty() else UiText.NO_LOG_YET
