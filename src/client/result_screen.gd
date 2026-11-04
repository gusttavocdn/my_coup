class_name ResultScreen
extends Control
## The end-of-match screen: a winner banner, every player in finishing order
## (rank, avatar, name, the cards they ended with) and a button back to the
## lobby. Renders the "standings" of the final view (Room.view_for) and only
## emits a signal.

signal return_pressed

## Widest the standings column grows, in pixels.
const MAX_WIDTH: float = 720.0

var _banner: VBoxContainer
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
	# Wide windows keep the standings in a readable column.
	var fit_width := func() -> void:
		var side: int = maxi(16, int((size.x - MAX_WIDTH) / 2.0))
		margin.add_theme_constant_override("margin_left", side)
		margin.add_theme_constant_override("margin_right", side)
	resized.connect(fit_width)
	fit_width.call()
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	margin.add_child(column)

	var caption := UiKit.label(UiText.RESULT_TITLE.to_upper(), 12, UiKit.GOLD_TEXT)
	caption.add_theme_font_override("font", UiKit.font(false, 600, 3))
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(caption)
	_banner = VBoxContainer.new()
	_banner.add_theme_constant_override("separation", 6)
	column.add_child(_banner)
	_rows = VBoxContainer.new()
	_rows.add_theme_constant_override("separation", 10)
	column.add_child(_rows)
	var back := UiKit.button(UiText.BACK_TO_LOBBY)
	back.pressed.connect(func() -> void: return_pressed.emit())
	column.add_child(back)
	_error = UiKit.label("", 20, UiKit.DANGER_DARK)
	_error.visible = false
	column.add_child(_error)


## Shows a server error code under the button.
func show_error(code: String) -> void:
	_error.text = UiText.error(code)
	_error.visible = true


## Shows the standings of [param view], a final view with phase game_over.
func show_result(view: Dictionary) -> void:
	_error.visible = false
	UiKit.clear(_banner)
	var winner: Dictionary = view.players[view.winner]
	var avatar_row := HBoxContainer.new()
	avatar_row.alignment = BoxContainer.ALIGNMENT_CENTER
	var avatar := AvatarView.new(int(winner.id), 96)
	avatar.ring = AvatarView.Ring.TURN
	avatar_row.add_child(avatar)
	_banner.add_child(avatar_row)
	var crown := UiKit.label(UiText.WINNER_CAPTION, 12, UiKit.GOLD_TEXT)
	crown.add_theme_font_override("font", UiKit.font(false, 600, 3))
	crown.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.add_child(crown)
	var winner_name := UiKit.label(String(winner.name).to_upper(), 36, UiKit.INK, true)
	winner_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.add_child(winner_name)

	UiKit.clear(_rows)
	for entry: Dictionary in view.standings:
		_rows.add_child(_standing_row(entry, view))


func _standing_row(entry: Dictionary, view: Dictionary) -> Control:
	var is_winner: bool = entry.rank == 1
	var panel := UiKit.panel(UiKit.PANEL, UiKit.GOLD if is_winner else UiKit.BORDER, 3 if is_winner else 1)
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 12)
	panel.add_child(line)
	var rank := UiKit.label(UiText.RANK % entry.rank, 24, UiKit.GOLD_TEXT if is_winner else UiKit.MUTED, true)
	rank.autowrap_mode = TextServer.AUTOWRAP_OFF
	rank.custom_minimum_size = Vector2(52, 0)
	rank.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	line.add_child(rank)
	var avatar := AvatarView.new(int(entry.seat), 52)
	avatar.ring = AvatarView.Ring.TURN if is_winner else AvatarView.Ring.PLAIN
	avatar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	line.add_child(avatar)
	var title: String = entry.name
	if entry.seat == view.you.seat:
		title += UiText.YOU_SUFFIX
	var name_label := UiKit.label(title, 22, UiKit.INK)
	name_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	line.add_child(name_label)
	var cards := HBoxContainer.new()
	cards.add_theme_constant_override("separation", 8)
	line.add_child(cards)
	for character: String in entry.cards:
		cards.add_child(UiKit.card(character, true))
	return panel
