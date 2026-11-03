class_name ClientPreview
extends Control
## Developer harness: shows one client screen fed by the real server-side rules
## (a local RoomRegistry, no sockets), so a screen can be launched and looked at
## directly. Pick the state with `-- --state=<name>`:
## connect, lobby, turn, forced, target, challenge, block, loss, exchange,
## exiled, over, result.

const SEED: int = 5

var _registry: RoomRegistry


func _ready() -> void:
	theme = UiKit.build_theme()
	UiKit.fit_scale(get_window())
	get_window().size_changed.connect(func() -> void: UiKit.fit_scale(get_window()))
	var backdrop := ColorRect.new()
	backdrop.color = UiKit.BACKGROUND
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)

	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	_registry = RoomRegistry.new(rng)
	_registry.handle(1, {"type": "create_room", "name": "Ana"})
	var code: String = _registry.room_of(1).code
	_registry.handle(2, {"type": "join_room", "code": code, "name": "Bia"})
	_registry.handle(3, {"type": "join_room", "code": code, "name": "Caio"})

	var state: String = _state_from_args()
	if state == "lobby" or state == "connect":
		var lobby := LobbyScreen.new()
		add_child(lobby)
		if state == "lobby":
			lobby.show_room(_registry.room_of(1).lobby_view(), 1)
		_capture_if_requested()
		return

	var events: Array = _stage(state)
	var room: Room = _registry.room_of(1)
	if state == "result":
		var result := ResultScreen.new()
		add_child(result)
		result.show_result(room.view_for(1))
		_capture_if_requested()
		return
	var table := TableScreen.new()
	add_child(table)
	table.set_room_code(code)
	table.apply_update(room.view_for(1), events)
	if state == "target":
		# Same state a tap on "Extorquir" leaves behind: waiting for a target.
		table._selected_action = RulesConfig.EXTORQUIR
		table._render()
	_capture_if_requested()


## With `-- --shot=<path>`, saves the viewport (at the window's size) to that
## png after a few frames and quits; used to capture phone-width layouts.
func _capture_if_requested() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--shot="):
			for _frame in range(8):
				await get_tree().process_frame
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png(argument.trim_prefix("--shot="))
			get_tree().quit()


## Starts the match and drives it into [param state]; returns the events to log.
func _stage(state: String) -> Array:
	var events: Array = []
	_collect(events, _registry.handle(1, {"type": "start_match"}))
	var room: Room = _registry.room_of(1)
	room.engine.state.players[0].hand = ["duque", "condessa"] as Array[String]
	room.engine.state.players[1].hand = ["capitao", "assassino"] as Array[String]
	room.engine.state.players[2].hand = ["embaixador", "duque"] as Array[String]
	match state:
		"turn", "target":
			room.engine.state.players[0].coins = 4
		"forced":
			room.engine.state.players[0].coins = 10
		"challenge":
			_collect(events, _registry.handle(1, {"type": "action", "action": "renda"}))
			_collect(events, _registry.handle(2, {"type": "action", "action": "taxas"}))
		"block":
			room.engine.state.players[1].coins = 3
			_collect(events, _registry.handle(1, {"type": "action", "action": "renda"}))
			_collect(events, _registry.handle(2, {"type": "action", "action": "assassinar", "target": 0}))
			_collect(events, _registry.handle(1, {"type": "pass"}))
			_collect(events, _registry.handle(3, {"type": "pass"}))
		"loss":
			room.engine.state.players[1].coins = 7
			_collect(events, _registry.handle(1, {"type": "action", "action": "renda"}))
			_collect(events, _registry.handle(2, {"type": "action", "action": "golpe", "target": 0}))
		"exchange":
			room.engine.state.players[0].hand = ["embaixador", "duque"] as Array[String]
			room.engine.state.deck = ["capitao", "assassino"] as Array[String]
			_collect(events, _registry.handle(1, {"type": "action", "action": "trocar"}))
			_collect(events, _registry.handle(2, {"type": "pass"}))
			_collect(events, _registry.handle(3, {"type": "pass"}))
		"exiled":
			room.engine.state.players[0].hand = ["duque"] as Array[String]
			room.engine.state.players[1].coins = 7
			_collect(events, _registry.handle(1, {"type": "action", "action": "renda"}))
			_collect(events, _registry.handle(2, {"type": "action", "action": "golpe", "target": 0}))
			_collect(events, _registry.handle(1, {"type": "lose_influence", "card_index": 0}))
		"over", "result":
			room.engine.state.players[0].coins = 14
			room.engine.state.players[1].hand = ["capitao"] as Array[String]
			room.engine.state.players[2].hand = ["embaixador"] as Array[String]
			_collect(events, _registry.handle(1, {"type": "action", "action": "golpe", "target": 1}))
			_collect(events, _registry.handle(2, {"type": "lose_influence", "card_index": 0}))
			_collect(events, _registry.handle(3, {"type": "action", "action": "renda"}))
			_collect(events, _registry.handle(1, {"type": "action", "action": "golpe", "target": 2}))
			_collect(events, _registry.handle(3, {"type": "lose_influence", "card_index": 0}))
	return events


## Adds the events of peer 1's update message in [param outgoing] to [param events].
func _collect(events: Array, outgoing: Array) -> void:
	for item: Dictionary in outgoing:
		if item.to == 1 and item.message.type == "update":
			events.append_array(item.message.events)


func _state_from_args() -> String:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--state="):
			return argument.trim_prefix("--state=")
	return "turn"
