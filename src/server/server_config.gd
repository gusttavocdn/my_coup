class_name ServerConfig
extends RefCounted
## Every tunable of the match server, in one place. Precedence: command-line
## option (after "--", for example --max-rooms=50) over environment variable
## (COUP_MAX_ROOMS=50) over the default below. Option and variable names are
## derived from the field name, so a new field needs no extra wiring.

const DEFAULT_PORT: int = 9080

## Field name -> default. The default's type is the type the option is parsed to.
const DEFAULTS: Dictionary = {
	"port": DEFAULT_PORT,
	"bind": "*",
	"max_rooms": 100,
	"max_connections": 400,
	"max_connections_per_ip": 8,
	"max_message_bytes": 2048,
	"max_messages_per_second": 10,
	"rate_strike_window_seconds": 10,
	"idle_minutes": 15,
}

var port: int = DEFAULTS.port
var bind: String = DEFAULTS.bind
var max_rooms: int = DEFAULTS.max_rooms
var max_connections: int = DEFAULTS.max_connections
## Counts the peer address the socket layer sees: behind a reverse proxy that is
## the proxy's address, so this cap only protects a server exposed directly.
var max_connections_per_ip: int = DEFAULTS.max_connections_per_ip
var max_message_bytes: int = DEFAULTS.max_message_bytes
var max_messages_per_second: int = DEFAULTS.max_messages_per_second
## A second violation inside this window disconnects the client.
var rate_strike_window_seconds: int = DEFAULTS.rate_strike_window_seconds
## A room with no activity for this long is closed.
var idle_minutes: int = DEFAULTS.idle_minutes


## Builds the config from [param args] (user arguments such as "--port=9000") and
## [param env] (environment variable name -> value). Unparsable numbers keep the default.
static func from_sources(args: PackedStringArray, env: Dictionary) -> ServerConfig:
	var config := ServerConfig.new()
	for field: String in DEFAULTS:
		var value: Variant = _lookup(field, args, env)
		if value == null:
			continue
		if typeof(DEFAULTS[field]) == TYPE_INT:
			if not String(value).is_valid_int():
				continue
			config.set(field, int(value))
		else:
			config.set(field, String(value))
	return config


## One log line with every effective value.
func to_log_line() -> String:
	var parts: PackedStringArray = []
	for field: String in DEFAULTS:
		parts.append("%s=%s" % [field, str(get(field))])
	return " ".join(parts)


static func _lookup(field: String, args: PackedStringArray, env: Dictionary) -> Variant:
	var prefix: String = "--%s=" % field.replace("_", "-")
	for argument: String in args:
		if argument.begins_with(prefix):
			return argument.trim_prefix(prefix)
	return env.get("COUP_%s" % field.to_upper())
