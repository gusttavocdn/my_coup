class_name ClientMain
extends Control
## Root of the game client: owns the network link and switches between the
## lobby and the match table. It forwards screen intents to the server and
## server messages to the screens. Launch with `-- --url=ws://host:port` to
## change the default server address.

var _net: ClientNet
var _lobby: LobbyScreen
var _table: TableScreen
var _result: ResultScreen
var _queued_intent: Dictionary = {}


func _ready() -> void:
	theme = UiKit.build_theme()
	UiKit.fit_scale(get_window())
	get_window().size_changed.connect(func() -> void: UiKit.fit_scale(get_window()))
	var backdrop := ColorRect.new()
	backdrop.color = UiKit.BACKGROUND
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)

	_net = ClientNet.new()
	_net.name = "GameServer"
	add_child(_net)
	_net.connected.connect(_on_connected)
	_net.connection_failed.connect(_on_connection_failed)
	_net.connection_lost.connect(_on_connection_lost)
	_net.message_received.connect(_on_message)

	_lobby = LobbyScreen.new()
	_lobby.set_anchors_preset(Control.PRESET_FULL_RECT)
	_lobby.default_url = _url_from_args()
	add_child(_lobby)
	_lobby.create_pressed.connect(func(url: String, player_name: String) -> void:
			_send_when_connected(url, {"type": "create_room", "name": player_name}))
	_lobby.join_pressed.connect(func(url: String, player_name: String, code: String) -> void:
			_send_when_connected(url, {"type": "join_room", "name": player_name, "code": code}))
	_lobby.start_pressed.connect(func() -> void: _send_online({"type": "start_match"}))
	_lobby.leave_pressed.connect(func() -> void: _send_online({"type": "leave_room"}))

	_table = TableScreen.new()
	_table.visible = false
	add_child(_table)
	_table.intent_chosen.connect(_send_online)

	_result = ResultScreen.new()
	_result.visible = false
	add_child(_result)
	_result.return_pressed.connect(func() -> void: _send_online({"type": "return_to_lobby"}))


## Sends [param intent] when the link is up; a dropped link was already reported.
func _send_online(intent: Dictionary) -> void:
	if _net.is_online():
		_net.send(intent)


func _send_when_connected(url: String, intent: Dictionary) -> void:
	if _net.is_online():
		_net.send(intent)
		return
	_queued_intent = intent
	_lobby.set_status(UiText.CONNECTING)
	if _net.connect_to(url) != OK:
		_on_connection_failed()


func _on_connected() -> void:
	if not _queued_intent.is_empty():
		_net.send(_queued_intent)
		_queued_intent = {}


func _on_connection_failed() -> void:
	_queued_intent = {}
	_lobby.set_status(UiText.CONNECTION_FAILED, true)


func _on_connection_lost() -> void:
	_show_lobby()
	_lobby.set_status(UiText.CONNECTION_LOST, true)


func _on_message(message: Dictionary) -> void:
	match message.type:
		"room":
			_table.reset()
			_table.set_room_code(message.code)
			_table.visible = false
			_result.visible = false
			_lobby.visible = true
			_lobby.show_room(message, _net.peer_id())
		"update":
			var over: bool = message.view.phase == RulesEngine.PHASE_GAME_OVER
			_lobby.visible = false
			_table.visible = not over
			_result.visible = over
			_table.apply_update(message.view, message.events)
			if over:
				_result.show_result(message.view)
		"error":
			if _result.visible:
				_result.show_error(message.error)
			elif _table.visible:
				_table.show_error(message.error)
			else:
				_lobby.set_status(UiText.error(message.error), true)
		"match_aborted":
			_show_lobby()
			_lobby.set_status(UiText.MATCH_ABORTED, true)
		"left":
			_show_lobby()


func _show_lobby() -> void:
	_table.reset()
	_table.visible = false
	_result.visible = false
	_lobby.visible = true
	_lobby.show_connect()


func _url_from_args() -> String:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--url="):
			return argument.trim_prefix("--url=")
	return "ws://127.0.0.1:%d" % GameServer.DEFAULT_PORT
