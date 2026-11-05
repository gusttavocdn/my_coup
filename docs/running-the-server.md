# Running the match server

The server is the project's server scene run headless:

```bash
godot --headless --path . res://scenes/server.tscn -- --port=9080
```

## Options

Every option is a command-line argument after `--` or an environment variable.
The command line wins over the environment, the environment over the default.
All of them live in `src/server/server_config.gd`; nothing else in the server
hardcodes a limit.

| Option | Environment variable | Default | Meaning |
|---|---|---|---|
| `--port=` | `COUP_PORT` | 9080 | WebSocket port |
| `--bind=` | `COUP_BIND` | `*` | Address to listen on |
| `--max-rooms=` | `COUP_MAX_ROOMS` | 100 | Open rooms; `create_room` answers `server_busy` above it |
| `--max-connections=` | `COUP_MAX_CONNECTIONS` | 400 | Total connections; more are closed with reason `server_full` |
| `--max-connections-per-ip=` | `COUP_MAX_CONNECTIONS_PER_IP` | 8 | Connections per address; reason `too_many_connections_from_ip` |
| `--max-message-bytes=` | `COUP_MAX_MESSAGE_BYTES` | 2048 | Largest accepted intent |
| `--max-messages-per-second=` | `COUP_MAX_MESSAGES_PER_SECOND` | 10 | Intents per client per second |
| `--rate-strike-window-seconds=` | `COUP_RATE_STRIKE_WINDOW_SECONDS` | 10 | A second violation inside this window disconnects the client |
| `--idle-minutes=` | `COUP_IDLE_MINUTES` | 15 | A room with no activity this long is closed (members get `match_aborted`, reason `idle`) |

A client that breaks a message limit (too many, too large, or an intent without
a `type`) gets an `error` message the first time and is disconnected on a repeat
inside the strike window. Other rooms are not affected.

## Logs

One line per event on stdout: `server_started` (with the effective config),
`peer_connected`, `connection_rejected`, `message_rejected`, `room_created`,
`player_joined`, `player_left`, `room_closed`. Text sent by players is escaped and
cut to 64 characters.

## Health and shutdown

`godot --headless --path . res://scenes/server.tscn -- --health --port=9080`
does not start a server: it opens a WebSocket to `127.0.0.1:<port>` and exits 0
if the server answers within 3 seconds, else 1. The `Dockerfile` uses it as its
`HEALTHCHECK`.

Godot 4.7.2 installs no `SIGTERM` handler (checked in a container: no close
request arrives, the process just ends with exit 143). That is fine for this
server, which keeps no state on disk: the OS closes the sockets and clients see a
dropped connection. The one real trap is PID 1: Linux ignores `SIGTERM` for a
PID 1 without a handler, so `docker stop` would wait for its timeout and kill the
server (exit 137). The `Dockerfile` therefore runs the server under `tini`; on
any other host, run it as a normal child of the service manager (or add
`--init` to `docker run`). The `NOTIFICATION_WM_CLOSE_REQUEST` handler in
`ServerMain` only covers a window close (for example a console close on
Windows); it logs `server_stopping` and exits 0.

## Docker and TLS

```bash
docker build -t coup-server .
docker run -d --name coup -p 127.0.0.1:9080:9080 -e COUP_MAX_ROOMS=200 coup-server
```

The container runs as a non-root user. TLS is not terminated by the server:
`deploy/Caddyfile` is an example that gets a certificate for your domain and
forwards `wss://` to `ws://127.0.0.1:9080`.

## Known limits

- **Per-IP cap behind a proxy.** The server sees the proxy's address, not the
  player's, so `max-connections-per-ip` counts the proxy as one client. It only
  protects a server that is reachable directly; behind Caddy, rely on the total
  cap and the message limits, or add a per-IP limit at the proxy.
- The message size limit is checked after Godot has decoded the message; the
  transport's own buffer limits still apply underneath.
- No authentication or DDoS protection: that is the host's or proxy's job.
- The Docker image was built and run (health `healthy`, `docker stop` ends it in
  about a second under tini); the Caddy setup was checked as noted in the story
  016 completion notes.
