class_name LobbyScreen
extends Control
## Lobby: connect, create or join a room by code, see who is in it and (as
## host) start the match. It only emits signals; ClientMain talks to the server.
## The form scrolls, and its viewport shrinks above the on-screen keyboard so the
## field being typed in stays visible.

## Seconds between two reads of the keyboard height while a field has focus.
const KEYBOARD_POLL_SECONDS: float = 0.15

signal create_pressed(url: String, player_name: String)
signal join_pressed(url: String, player_name: String, code: String)
signal start_pressed
signal leave_pressed

var default_url: String = ServerAddress.default_url()

var _connect_box: VBoxContainer
var _room_box: VBoxContainer
var _url_edit: LineEdit
var _name_edit: LineEdit
var _code_edit: LineEdit
var _room_title: Label
var _members: VBoxContainer
var _start_button: Button
var _status: Label
var _copy_button: Button
var _fullscreen_button: Button
var _code: String = ""
var _scroll: ScrollContainer
var _keyboard: float = 0.0
var _poll_left: float = 0.0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	set_process(OS.has_feature("web"))
	_scroll = ScrollContainer.new()
	_scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.scroll_deadzone = int(UiKit.css_to_layout(UiKit.DRAG_SLOP))
	add_child(_scroll)
	var page := CenterContainer.new()
	page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.add_child(page)
	var card := UiKit.panel(UiKit.PANEL, UiKit.GOLD, 2)
	card.custom_minimum_size = Vector2(520, 0)
	page.add_child(card)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	card.add_child(column)
	column.add_child(_card_fan())
	var title := UiKit.label(UiText.TITLE, 40, UiKit.INK, true)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)
	var tagline := UiKit.label(UiText.TAGLINE, 16, UiKit.MUTED)
	tagline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(tagline)

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
	_fullscreen_button = UiKit.button(UiText.ENTER_FULLSCREEN)
	_fullscreen_button.visible = WebViewport.can_fullscreen()
	_fullscreen_button.pressed.connect(func() -> void:
			WebViewport.enter_fullscreen()
			_fullscreen_button.visible = false)
	_connect_box.add_child(_fullscreen_button)

	_room_box = VBoxContainer.new()
	_room_box.add_theme_constant_override("separation", 10)
	_room_box.visible = false
	column.add_child(_room_box)
	var code_caption := UiKit.label(UiText.CODE_LABEL.to_upper(), 12, UiKit.GOLD_TEXT)
	code_caption.add_theme_font_override("font", UiKit.font(false, 600, 3))
	code_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_room_box.add_child(code_caption)
	_room_title = UiKit.label("", 48, UiKit.INK, true)
	_room_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_room_title.autowrap_mode = TextServer.AUTOWRAP_OFF
	_room_box.add_child(_room_title)
	_copy_button = UiKit.button(UiText.COPY_CODE)
	_copy_button.pressed.connect(func() -> void:
			_copy_code())
	_room_box.add_child(_copy_button)
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
	_fullscreen_button.visible = WebViewport.can_fullscreen()
	set_status("")


## Shows the room [param lobby] (a RoomRegistry "room" message); [param my_peer]
## decides whether the Start button is offered.
func show_room(lobby: Dictionary, my_peer: int) -> void:
	_connect_box.visible = false
	_room_box.visible = true
	_code = lobby.code
	_room_title.text = lobby.code
	_copy_button.text = UiText.COPY_CODE
	UiKit.clear(_members)
	for index in range(lobby.names.size()):
		_members.add_child(_member_row(index, lobby.names[index], index == 0))
	var is_host: bool = lobby.host == my_peer
	_start_button.visible = is_host
	set_status("" if is_host else UiText.WAITING_HOST)


## While a field has focus, shrinks the scroll area to what the on-screen keyboard
## leaves free and scrolls the field into view.
func _process(delta: float) -> void:
	var focused: Control = get_viewport().gui_get_focus_owner()
	var typing: bool = focused is LineEdit and is_ancestor_of(focused)
	_poll_left -= delta
	if _poll_left > 0.0 or not (typing or _keyboard > 0.0):
		return
	_poll_left = KEYBOARD_POLL_SECONDS
	var height: float = WebViewport.keyboard_height() if typing else 0.0
	if not is_equal_approx(height, _keyboard):
		_keyboard = height
		_scroll.offset_bottom = -height
		if typing:
			# The scroll area resizes on the next layout pass.
			_scroll.ensure_control_visible.call_deferred(focused)


## A fan of three cards above the title, the lobby's decoration.
func _card_fan() -> Control:
	var fan := Control.new()
	fan.custom_minimum_size = Vector2(0, 100)
	var layout: Array = [["duque", -12.0, -70.0, 14.0], ["condessa", 0.0, 0.0, 0.0], ["capitao", 12.0, 70.0, 14.0]]
	for entry: Array in layout:
		var card := CardView.new(entry[0], 66)
		card.rotation_degrees = entry[1]
		card.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fan.add_child(card)
		var offset := Vector2(entry[2], entry[3])
		fan.resized.connect(func() -> void:
				card.position = Vector2((fan.size.x - card.size.x) / 2.0, 4) + offset)
	return fan


## One member of the room: avatar, name and a tag for the host (first in the list).
func _member_row(index: int, member_name: String, is_host: bool) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.add_child(AvatarView.new(index, 44))
	var name_label := UiKit.label(member_name, 20, UiKit.INK)
	name_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	name_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(name_label)
	if is_host:
		var tag := UiKit.label(UiText.HOST_TAG, 12, UiKit.GOLD_TEXT)
		tag.autowrap_mode = TextServer.AUTOWRAP_OFF
		tag.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(tag)
	return row


## Shows a status or error line under the form.
func set_status(text: String, is_error: bool = false) -> void:
	_status.text = text
	_status.add_theme_color_override("font_color", UiKit.DANGER if is_error else UiKit.MUTED)


func _copy_code() -> void:
	if OS.has_feature("web"):
		# Async Clipboard API first; embedded or restricted browsers may deny it, so fall back
		# to a hidden textarea + execCommand("copy"), which only needs the click's user activation.
		JavaScriptBridge.eval("""
			(function (text) {
				const legacy = () => {
					const area = document.createElement('textarea');
					area.value = text;
					area.style.position = 'fixed';
					area.style.opacity = '0';
					document.body.appendChild(area);
					area.select();
					try { document.execCommand('copy'); } catch (error) { console.warn('Could not copy room code:', error); }
					document.body.removeChild(area);
					const canvas = document.querySelector('canvas');
					if (canvas) { canvas.focus(); }
				};
				if (navigator.clipboard && navigator.clipboard.writeText) {
					navigator.clipboard.writeText(text).catch(legacy);
				} else {
					legacy();
				}
			})(%s);
		""" % JSON.stringify(_code))
	else:
		DisplayServer.clipboard_set(_code)
	_copy_button.text = UiText.CODE_COPIED


func _field(caption: String, value: String) -> LineEdit:
	_connect_box.add_child(UiKit.label(caption, 18, UiKit.MUTED))
	var edit := LineEdit.new()
	edit.text = value
	UiKit.touch_sized(edit)
	edit.focus_entered.connect(func() -> void:
			_poll_left = 0.0
			_scroll.ensure_control_visible.call_deferred(edit))
	_connect_box.add_child(edit)
	return edit
