class_name ClientPreview
extends Control
## Developer harness: shows one client screen fed by the real server-side rules
## (a local RoomRegistry, no sockets), so a screen can be launched and looked at
## directly. Pick the state with `-- --state=<name>`:
## gallery, connect, lobby, turn, waiting, forced, target, challenge, block,
## loss, exchange, exiled, over, result, rules, menu, log.

const SEED: int = 5

var _registry: RoomRegistry


func _ready() -> void:
	theme = UiKit.build_theme()
	UiKit.fit_scale(get_window())
	get_window().size_changed.connect(func() -> void: UiKit.fit_scale(get_window()))
	add_child(SceneBackdrop.new())

	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	_registry = RoomRegistry.new(rng)
	_registry.handle(1, {"type": "create_room", "name": "Ana"})
	var code: String = _registry.room_of(1).code
	_registry.handle(2, {"type": "join_room", "code": code, "name": "Bia"})
	_registry.handle(3, {"type": "join_room", "code": code, "name": "Caio"})

	var state: String = _state_from_args()
	if state == "gallery":
		add_child(_gallery())
		_capture_if_requested()
		return
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
	if state.begins_with("target"):
		# What a tap on a targeted medallion does; "_pick" also taps Bia's avatar.
		table._on_action_chosen(RulesConfig.ASSASSINAR if state.contains("ass") else RulesConfig.EXTORQUIR)
		if state.ends_with("pick"):
			table._target_screen.select(1)
	if state == "rules":
		table.add_child(RulesSheet.rules())
	elif state == "menu":
		table.add_child(RulesSheet.menu())
	elif state == "log":
		var names: Array = []
		for player: Dictionary in room.view_for(1).players:
			names.append(player.name)
		table.add_child(RulesSheet.log_sheet(["Ana usa Renda.", "Bia usa Taxas.", "Caio contesta Bia.", "Bia mostrou Duque: a contestação falhou.", "Caio perdeu Condessa."], names))
	_capture_if_requested()


## Every visual building block side by side: the five cards (plus back, lost,
## glowing and tilted), the six avatars with their rings, coins, type and colors.
func _gallery() -> Control:
	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 18)
	scroll.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	margin.add_child(column)

	column.add_child(UiKit.label("Fundação visual", 30, UiKit.INK, true))
	column.add_child(UiKit.label("Cartas", 18, UiKit.MUTED))
	var cards := HFlowContainer.new()
	cards.add_theme_constant_override("h_separation", 14)
	cards.add_theme_constant_override("v_separation", 14)
	column.add_child(cards)
	for character: String in UiKit.CARD_STYLE:
		cards.add_child(CardView.new(character, 150))
	cards.add_child(CardView.new("", 150))
	var lost := CardView.new("condessa", 150)
	lost.lost = true
	cards.add_child(lost)
	var halo := CardView.new("assassino", 150)
	halo.glow = Color(UiKit.DANGER, 0.55)
	cards.add_child(halo)
	# Containers reset rotation, so a tilted card sits in a fixed-size holder.
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(170, 215)
	var tilted := CardView.new("duque", 150)
	tilted.position = Vector2(10, 4)
	tilted.rotation_degrees = -6.0
	holder.add_child(tilted)
	cards.add_child(holder)

	column.add_child(UiKit.label("Avatares", 18, UiKit.MUTED))
	var avatars := HFlowContainer.new()
	avatars.add_theme_constant_override("h_separation", 16)
	column.add_child(avatars)
	var rings: Array = [AvatarView.Ring.PLAIN, AvatarView.Ring.TURN, AvatarView.Ring.CLAIM,
			AvatarView.Ring.TARGET, AvatarView.Ring.PLAIN, AvatarView.Ring.PLAIN]
	for index in range(AvatarView.NAMES.size()):
		var avatar := AvatarView.new(index, 76)
		avatar.ring = rings[index]
		avatar.dimmed = index == 4
		avatars.add_child(avatar)

	column.add_child(UiKit.label("Moedas e tipografia", 18, UiKit.MUTED))
	var coins := HFlowContainer.new()
	coins.add_theme_constant_override("h_separation", 12)
	column.add_child(coins)
	coins.add_child(CoinPill.new(6))
	coins.add_child(CoinPill.new(32, "Tesouro"))
	coins.add_child(CoinPill.new(9, "Baralho"))
	for path: String in ["res://assets/arte/design/moeda_ouro.svg", "res://assets/arte/design/moeda_prata.svg"]:
		var coin := TextureRect.new()
		coin.texture = load(path)
		coin.custom_minimum_size = Vector2(56, 56)
		coin.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		coin.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		coins.add_child(coin)
	column.add_child(UiKit.label("SUA VEZ", 34, UiKit.INK, true))
	column.add_child(UiKit.label("Escolha uma ação — Source Sans 3", 22, UiKit.INK))
	var buttons := HFlowContainer.new()
	buttons.add_theme_constant_override("h_separation", 12)
	column.add_child(buttons)
	buttons.add_child(UiKit.button("Renda"))
	var disabled := UiKit.button("Golpe de Estado")
	disabled.disabled = true
	buttons.add_child(disabled)
	var swatches := HFlowContainer.new()
	swatches.add_theme_constant_override("h_separation", 8)
	column.add_child(swatches)
	for swatch: Array in [["INK", UiKit.INK], ["GOLD", UiKit.GOLD], ["BORDER", UiKit.BORDER], ["BACKGROUND", UiKit.BACKGROUND],
			["PANEL_RAISED", UiKit.PANEL_RAISED], ["MUTED", UiKit.MUTED], ["DANGER", UiKit.DANGER]]:
		var chip := UiKit.panel(swatch[1], UiKit.BORDER, 1)
		chip.custom_minimum_size = Vector2(110, 40)
		var tag := UiKit.label(swatch[0], 12, UiKit.INK if swatch[1].get_luminance() > 0.45 else Color.WHITE)
		tag.autowrap_mode = TextServer.AUTOWRAP_OFF
		chip.add_child(tag)
		swatches.add_child(chip)
	return scroll


## With `-- --shot=<path>`, saves the viewport (at the window's size) to that
## png after a few frames and quits; used to capture phone-width layouts.
func _capture_if_requested() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--shot="):
			for _frame in range(14):
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
		"turn", "target_ass", "target_ass_pick", "target_ext", "target_ext_pick", "rules", "menu", "log":
			room.engine.state.players[0].coins = 4
		"forced":
			room.engine.state.players[0].coins = 10
		"waiting":
			_collect(events, _registry.handle(1, {"type": "action", "action": "renda"}))
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
