class_name WebViewport
extends RefCounted
## The one place the client asks the browser about the phone's viewport: the
## safe-area insets (notch, rounded corners, home indicator), the height the
## on-screen keyboard covers, and full screen. The numbers come from
## window.coupInsets, defined by web/shell.html. Outside a Web export every
## inset is zero and full screen is not offered, so desktop is unchanged.
## Every JavaScriptBridge call is guarded by OS.has_feature("web").


## Safe-area insets in layout pixels: x = left, y = top, z = right, w = bottom.
static func safe_area() -> Vector4:
	var raw: PackedFloat64Array = _read()
	return Vector4(raw[3], raw[0], raw[1], raw[2]) / UiKit.layout_scale


## Height in layout pixels the on-screen keyboard covers at the bottom (0 when closed).
static func keyboard_height() -> float:
	return _read()[4] / UiKit.layout_scale


## True where the browser allows full screen and the page is not in it yet.
static func can_fullscreen() -> bool:
	if not OS.has_feature("web"):
		return false
	return bool(JavaScriptBridge.eval("!!(document.fullscreenEnabled && !document.fullscreenElement)", true))


## Enters full screen. Call it from a button press (a user gesture), or the browser refuses.
static func enter_fullscreen() -> void:
	if OS.has_feature("web"):
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)


## [top, right, bottom, left, keyboard] in CSS pixels.
static func _read() -> PackedFloat64Array:
	if not OS.has_feature("web"):
		return PackedFloat64Array([0.0, 0.0, 0.0, 0.0, 0.0])
	var raw: String = str(JavaScriptBridge.eval("window.coupInsets ? window.coupInsets() : '0,0,0,0,0'", true))
	var parts: PackedFloat64Array = raw.split_floats(",")
	if parts.size() != 5:
		return PackedFloat64Array([0.0, 0.0, 0.0, 0.0, 0.0])
	return parts
