class_name SceneBackdrop
extends Control
## The table scene behind every screen: the design's lavender landscape,
## switching to its portrait variant on tall (phone) windows and always covering
## the whole control.

const LANDSCAPE: String = "res://assets/arte/design/cenario_paisagem.svg"
const PORTRAIT: String = "res://assets/arte/design/cenario_retrato.svg"

var _picture: TextureRect


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_picture = TextureRect.new()
	_picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_picture.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_picture)
	_picture.texture = UiKit.texture(LANDSCAPE)
	resized.connect(_pick_variant)


func _pick_variant() -> void:
	var path: String = PORTRAIT if size.y > size.x else LANDSCAPE
	if _picture.texture == null or _picture.texture.resource_path != path:
		_picture.texture = UiKit.texture(path)
