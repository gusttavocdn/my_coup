class_name RulesSheet
extends Control
## A modal sheet over the table: either the short rules ("Regras", with each
## character's action and block) or the menu ("Continuar" / "Sair da partida").
## It covers the screen with a dimmed backdrop and frees itself when closed.

signal leave_requested


## The rules sheet.
static func rules() -> RulesSheet:
	var sheet := RulesSheet.new()
	sheet._build_rules()
	return sheet


## The menu sheet.
static func menu() -> RulesSheet:
	var sheet := RulesSheet.new()
	sheet._build_menu()
	return sheet


## A sheet showing the event log (used on phones, where the card has no room).
static func log_sheet(lines: Array[String], names: Array) -> RulesSheet:
	var sheet := RulesSheet.new()
	var content: VBoxContainer = sheet._frame(UiText.LOG_TITLE)
	var log_panel := LogPanel.new()
	log_panel.show_lines(lines, names, 40, 18)
	log_panel.set_title_visible(false)
	content.add_child(log_panel)
	sheet._add_close(content)
	return sheet


var _scroll: ScrollContainer
var _column: VBoxContainer
var _footer: VBoxContainer


func _init() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(0.1, 0.08, 0.16, 0.45)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed:
			queue_free())
	add_child(dim)


func _ready() -> void:
	_fit_height.call_deferred()


## A scroll area has no natural height: after the first layout, give it the
## content's height, capped to the screen.
func _fit_height() -> void:
	if _scroll == null:
		return
	await get_tree().process_frame
	if not is_inside_tree() or not is_instance_valid(_scroll):
		return
	var available: float = get_viewport_rect().size.y * 0.8 - _footer.get_combined_minimum_size().y
	_scroll.custom_minimum_size = Vector2(0, minf(_column.get_combined_minimum_size().y, available))


## Adds the white card with a Cinzel title; returns the column to fill.
func _frame(title: String) -> VBoxContainer:
	var holder := CenterContainer.new()
	holder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(holder)
	var card := UiKit.panel(UiKit.PANEL, UiKit.GOLD, 2)
	card.custom_minimum_size = Vector2(520, 0)
	holder.add_child(card)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 12)
	card.add_child(stack)
	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.scroll_deadzone = int(UiKit.css_to_layout(UiKit.DRAG_SLOP))
	stack.add_child(_scroll)
	# Buttons live outside the scroll area so they never scroll out of reach.
	_footer = VBoxContainer.new()
	_footer.add_theme_constant_override("separation", 8)
	stack.add_child(_footer)
	_column = VBoxContainer.new()
	_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_column.custom_minimum_size = Vector2(480, 0)
	_column.add_theme_constant_override("separation", 12)
	_scroll.add_child(_column)
	_column.add_child(UiKit.label(title, 28, UiKit.INK, true))
	return _column


func _add_close(_column_unused: VBoxContainer) -> void:
	var close := UiKit.button(UiText.CLOSE)
	close.pressed.connect(queue_free)
	_footer.add_child(close)


func _build_rules() -> void:
	var column: VBoxContainer = _frame(UiText.RULES_TITLE)
	for line: String in UiText.RULES_LINES:
		column.add_child(UiKit.label(line, 17, UiKit.INK))
	for character: String in UiKit.CARD_STYLE:
		var style: Dictionary = UiKit.CARD_STYLE[character]
		var text: Dictionary = UiText.CARD_TEXT[character]
		var row := VBoxContainer.new()
		row.add_theme_constant_override("separation", 2)
		column.add_child(row)
		row.add_child(UiKit.label(UiText.character(character).to_upper(), 16, style.title, true))
		row.add_child(UiKit.label("%s: %s" % [text.action[0].capitalize(), " ".join(text.action[1])], 16, UiKit.INK))
		row.add_child(UiKit.label("%s: %s" % [text.block[0].capitalize(), " ".join(text.block[1])], 16, UiKit.MUTED))
	_add_close(column)


func _build_menu() -> void:
	var column: VBoxContainer = _frame(UiText.MENU_TITLE)
	var keep := UiKit.button(UiText.CONTINUE)
	keep.pressed.connect(queue_free)
	column.add_child(keep)
	if WebViewport.can_fullscreen():
		var fullscreen := UiKit.button(UiText.ENTER_FULLSCREEN)
		fullscreen.pressed.connect(func() -> void:
			WebViewport.enter_fullscreen()
			queue_free())
		column.add_child(fullscreen)
	var leave := UiKit.button(UiText.LEAVE_MATCH)
	leave.pressed.connect(func() -> void:
		leave_requested.emit()
		queue_free())
	column.add_child(leave)
