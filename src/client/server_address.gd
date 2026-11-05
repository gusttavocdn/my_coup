class_name ServerAddress
extends RefCounted
## Resolves the match server URL for a browser page or desktop launch.


## Returns the page-derived WebSocket address on Web, otherwise the local server.
static func default_url() -> String:
	if OS.has_feature("web"):
		var window: JavaScriptObject = JavaScriptBridge.get_interface("window")
		var location: JavaScriptObject = window.location
		var page_url: JavaScriptObject = JavaScriptBridge.create_object("URL", location.href)
		var override: Variant = page_url.searchParams.get("server")
		if override != null and not String(override).is_empty():
			return String(override)
		# Published over HTTPS the reverse proxy serves the page and the match server on
		# the same origin (deploy/Caddyfile), so wss:// uses the page's own host and port.
		if String(location.protocol) == "https:":
			return "wss://%s" % String(location.host)
		return "ws://%s:%d" % [String(location.hostname), GameServer.DEFAULT_PORT]
	return "ws://127.0.0.1:%d" % GameServer.DEFAULT_PORT


## Applies the desktop --url= override while retaining the platform default.
static func from_user_args(arguments: PackedStringArray) -> String:
	for argument in arguments:
		if argument.begins_with("--url="):
			return argument.trim_prefix("--url=")
	return default_url()
