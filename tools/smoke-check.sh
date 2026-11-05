#!/usr/bin/env bash
# Smoke check after a publish: the page and its PWA files answer, then two real
# game clients (host creates a room, guest joins it) talk to the match server.
# Prints one PASS/FAIL line per check and exits 0 only when every check passed.
#
#   tools/smoke-check.sh https://play.example.com
#   tools/smoke-check.sh http://127.0.0.1:8000 ws://127.0.0.1:9080     # local run
#
# The second argument is the match server URL; by default it is derived from the
# page URL the way the game does it (https -> wss://same-host, http -> ws://host:9080).
# Needs curl and the pinned Godot (GODOT_BIN, PATH or engine.path in project.yaml).
set -uo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
page_url="${1:-${COUP_PUBLIC_URL:-}}"
if [[ -z "$page_url" ]]; then
	printf '%s\n' "usage: tools/smoke-check.sh <page-url> [ws-url]   (or set COUP_PUBLIC_URL)" >&2
	exit 2
fi
page_url="${page_url%/}"
ws_url="${2:-}"
if [[ -z "$ws_url" ]]; then
	host_part="${page_url#*://}"
	if [[ "$page_url" == https://* ]]; then
		ws_url="wss://${host_part}"
	else
		ws_url="ws://${host_part%%:*}:9080"
	fi
fi

godot_bin="${GODOT_BIN:-}"
if [[ -z "$godot_bin" ]] && command -v godot >/dev/null 2>&1; then
	godot_bin="godot"
fi
if [[ -z "$godot_bin" ]]; then
	godot_bin="$(awk '
	/^engine:[[:space:]]*$/ { in_engine = 1; next }
	in_engine && /^[^[:space:]#]/ { exit }
	in_engine && /^[[:space:]]+path:[[:space:]]*/ {
		sub(/^[[:space:]]+path:[[:space:]]*/, "")
		sub(/[[:space:]]+#.*/, "")
		gsub(/^"|"$/, "")
		print
		exit
	}
' "$project_root/project.yaml")"
fi
if [[ "$godot_bin" =~ ^[A-Za-z]:/ ]] && command -v cygpath >/dev/null 2>&1; then
	godot_bin="$(cygpath -u "$godot_bin")"
fi
if [[ "$godot_bin" =~ _win64\.exe$ ]] && [[ -x "${godot_bin%.exe}_console.exe" ]]; then
	godot_bin="${godot_bin%.exe}_console.exe"
fi

failures=0
pass() { printf 'PASS  %s\n' "$1"; }
fail() { printf 'FAIL  %s\n' "$1"; failures=$((failures + 1)); }

# 1. The page and the PWA files.
for path in /index.html /index.manifest.json /index.service.worker.js /index.wasm /index.pck; do
	status="$(curl -sS -o /dev/null -I -w '%{http_code}' --max-time 20 "$page_url$path" 2>/dev/null || true)"
	if [[ "$status" == "200" ]]; then
		pass "GET $path -> 200"
	else
		fail "GET $path -> ${status:-no answer}"
	fi
done

# 2. Two game clients: the host creates a room, the guest joins it.
if ! command -v "$godot_bin" >/dev/null 2>&1; then
	fail "Godot not found (set GODOT_BIN); cannot run the two-client check"
else
	workdir="$(mktemp -d)"
	host_log="$workdir/host.log"
	run_client() {
		"$godot_bin" --headless --path "$project_root" -s res://tools/smoke_client.gd -- --url="$ws_url" "$@" 2>&1
	}
	run_client --role=host >"$host_log" &
	host_pid=$!
	code=""
	for _ in $(seq 1 60); do
		code="$(grep -o 'CODE=[A-Z]*' "$host_log" 2>/dev/null | head -1 | cut -d= -f2 || true)"
		[[ -n "$code" ]] && break
		kill -0 "$host_pid" 2>/dev/null || break
		sleep 0.5
	done
	if [[ -z "$code" ]]; then
		fail "host could not create a room at $ws_url: $(grep -E 'SMOKE_FAIL' "$host_log" | head -1)"
		kill "$host_pid" 2>/dev/null || true
	else
		guest_out="$(run_client --role=guest --code="$code")"
		guest_status=$?
		wait "$host_pid"
		host_status=$?
		if [[ $guest_status -eq 0 && $host_status -eq 0 ]]; then
			pass "room $code: host created it and guest joined over $ws_url"
		else
			fail "room $code: guest exit $guest_status ($(grep -E 'SMOKE_(OK|FAIL)' <<<"$guest_out" | head -1)); host exit $host_status ($(grep -E 'SMOKE_(OK|FAIL)' "$host_log" | head -1))"
		fi
	fi
	rm -rf "$workdir"
fi

if [[ $failures -eq 0 ]]; then
	printf 'SMOKE CHECK PASSED (%s)\n' "$page_url"
	exit 0
fi
printf 'SMOKE CHECK FAILED: %d check(s) (%s)\n' "$failures" "$page_url"
exit 1
