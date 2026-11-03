class_name ResultScreen
extends Control
## The end-of-match screen: the winner, every player in finishing order with
## the cards they ended with, and a button back to the lobby. Renders the
## "standings" of the final view (Room.view_for) and only emits a signal.

signal return_pressed

var _winner: Label
var _rows: VBoxContainer
var _error: Label


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 16)
	scroll.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	margin.add_child(column)

	column.add_child(UiKit.label(UiText.RESULT_TITLE, 24, UiKit.MUTED))
	_winner = UiKit.label("", 34, UiKit.GOLD)
	column.add_child(_winner)
	_rows = VBoxContainer.new()
	_rows.add_theme_constant_override("separation", 10)
	column.add_child(_rows)
	var back := UiKit.button(UiText.BACK_TO_LOBBY)
	back.pressed.connect(func() -> void: return_pressed.emit())
	column.add_child(back)
	_error = UiKit.label("", 20, UiKit.DANGER)
	_error.visible = false
	column.add_child(_error)


## Shows a server error code under the button.
func show_error(code: String) -> void:
	_error.text = UiText.error(code)
	_error.visible = true


## Shows the standings of [param view], a final view with phase game_over.
func show_result(view: Dictionary) -> void:
	_error.visible = false
	_winner.text = UiText.GAME_OVER % view.players[view.winner].name
	UiKit.clear(_rows)
	for entry: Dictionary in view.standings:
		var is_winner: bool = entry.rank == 1
		var panel := UiKit.panel(UiKit.PANEL, UiKit.GOLD if is_winner else Color(0, 0, 0, 0), 3)
		_rows.add_child(panel)
		var line := HFlowContainer.new()
		line.add_theme_constant_override("h_separation", 14)
		panel.add_child(line)
		var title: String = UiText.RANK % entry.rank + "  " + entry.name
		if entry.seat == view.you.seat:
			title += UiText.YOU_SUFFIX
		if is_winner:
			title += UiText.WINNER_SUFFIX
		var name_label := UiKit.label(title, 24, UiKit.GOLD if is_winner else UiKit.TEXT)
		name_label.custom_minimum_size = Vector2(260, 0)
		line.add_child(name_label)
		var cards := HBoxContainer.new()
		cards.add_theme_constant_override("separation", 8)
		line.add_child(cards)
		for character: String in entry.cards:
			cards.add_child(UiKit.card(character, true))
