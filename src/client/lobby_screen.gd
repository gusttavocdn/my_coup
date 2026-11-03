class_name LobbyScreen
extends CenterContainer
## Lobby: connect, create or join a room by code, see who is in it and (as
## host) start the match. It only emits signals; ClientMain talks to the server.

signal create_pressed(url: String, player_name: String)
signal join_pressed(url: String, player_name: String, code: String)
signal start_pressed
signal leave_pressed

var default_url: String = "ws://127.0.0.1:9080"

var _connect_box: VBoxContainer
var _room_box: VBoxContainer
var _url_edit: LineEdit
var _name_edit: LineEdit
var _code_edit: LineEdit
var _room_title: Label
var _members: VBoxContainer
var _start_button: Button
var _status: Label


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var card := UiKit.panel(UiKit.PANEL, UiKit.GOLD, 2)
	card.custom_minimum_size = Vector2(520, 0)
	add_child(card)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	card.add_child(column)
	var title := UiKit.label(UiText.TITLE, 40, UiKit.GOLD)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)

	_connect_box = VBoxContainer.new()
	_connect_box.add_theme_constant_override("separation", 10)
	column.add_child(_connect_box)
	_url_edit = _field(UiText.SERVER_LABEL, default_url)
	_name_edit = _field(UiText.NAME_LABEL, "")
	_code_edit = _field(UiText.CODE_LABEL, "")
	_code_edit.max_length = RoomRegistry.CODE_LENGTH
	var create := UiKit.button(UiText.CREATE_ROOM)
	create.pressed.connect(func() -> void: create_pressed.emit(_url_edit.text, _name_edit.text))
	_connect_box.add_child(create)
	var join := UiKit.button(UiText.JOIN_ROOM)
	join.pressed.connect(func() -> void: join_pressed.emit(_url_edit.text, _name_edit.text, _code_edit.text))
	_connect_box.add_child(join)

	_room_box = VBoxContainer.new()
	_room_box.add_theme_constant_override("separation", 10)
	_room_box.visible = false
	column.add_child(_room_box)
	_room_title = UiKit.label("", 30, UiKit.GOLD)
	_room_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_room_box.add_child(_room_title)
	_members = VBoxContainer.new()
	_room_box.add_child(_members)
	_start_button = UiKit.button(UiText.START_MATCH)
	_start_button.pressed.connect(func() -> void: start_pressed.emit())
	_room_box.add_child(_start_button)
	var leave := UiKit.button(UiText.LEAVE_ROOM)
	leave.pressed.connect(func() -> void: leave_pressed.emit())
	_room_box.add_child(leave)

	_status = UiKit.label("", 20, UiKit.MUTED)
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(_status)


## Shows the connect/create/join form.
func show_connect() -> void:
	_connect_box.visible = true
	_room_box.visible = false
	set_status("")


## Shows the room [param lobby] (a RoomRegistry "room" message); [param my_peer]
## decides whether the Start button is offered.
func show_room(lobby: Dictionary, my_peer: int) -> void:
	_connect_box.visible = false
	_room_box.visible = true
	_room_title.text = UiText.ROOM_CODE % lobby.code
	UiKit.clear(_members)
	for index in range(lobby.names.size()):
		var line: String = "%d. %s" % [index + 1, lobby.names[index]]
		_members.add_child(UiKit.label(line))
	var is_host: bool = lobby.host == my_peer
	_start_button.visible = is_host
	set_status("" if is_host else UiText.WAITING_HOST)


## Shows a status or error line under the form.
func set_status(text: String, is_error: bool = false) -> void:
	_status.text = text
	_status.add_theme_color_override("font_color", UiKit.DANGER if is_error else UiKit.MUTED)


func _field(caption: String, value: String) -> LineEdit:
	_connect_box.add_child(UiKit.label(caption, 18, UiKit.MUTED))
	var edit := LineEdit.new()
	edit.text = value
	edit.custom_minimum_size = Vector2(0, UiKit.MIN_TOUCH)
	_connect_box.add_child(edit)
	return edit
