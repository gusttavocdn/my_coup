#!/usr/bin/env bash
# Builds the web client and the match server image, ships both to the host over
# SSH, (re)starts the stack and runs the smoke check. Safe to run twice in a row:
# a release directory and a server image that are already on the host are not sent
# again, the "current" symlink switch is atomic, and `docker compose up -d` leaves an
# unchanged stack alone.
#
#   COUP_DEPLOY_HOST=deploy@203.0.113.10 COUP_DOMAIN=play.example.com tools/publish.sh
#   tools/publish.sh --dry-run          # print what would run, change nothing
#
# Environment (nothing secret lives in the repository; SSH uses your key or agent):
#   COUP_DEPLOY_HOST   user@host of the VPS (required)
#   COUP_DOMAIN        public host name, DNS already pointing at the VPS (required)
#   COUP_DEPLOY_DIR    directory on the VPS, default /opt/coup
#   COUP_SSH_OPTS      extra ssh/scp options, for example "-i ~/.ssh/coup"
# The VPS needs Docker with the compose plugin and ports 80/443 open (docs/hosting.md).
set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
dry_run=0
for argument in "$@"; do
	case "$argument" in
		--dry-run) dry_run=1 ;;
		*) printf 'unknown option: %s\n' "$argument" >&2; exit 2 ;;
	esac
done

host="${COUP_DEPLOY_HOST:-}"
domain="${COUP_DOMAIN:-}"
deploy_dir="${COUP_DEPLOY_DIR:-/opt/coup}"
ssh_opts="${COUP_SSH_OPTS:-}"
if [[ -z "$host" || -z "$domain" ]]; then
	printf '%s\n' "Set COUP_DEPLOY_HOST (user@host) and COUP_DOMAIN (public host name). See docs/hosting.md." >&2
	exit 2
fi

# run prints each step and executes it unless this is a dry run.
run() {
	printf '+ %s\n' "$*"
	if [[ $dry_run -eq 0 ]]; then
		"$@"
	fi
}
# remote runs one command line on the host.
remote() {
	# shellcheck disable=SC2086
	run ssh $ssh_opts "$host" "$1"
}

cd "$project_root"

# 1. Web client (the PowerShell build also applies the PWA patch; the .sh build does not).
printf '== 1/6 web build\n'
if command -v powershell.exe >/dev/null 2>&1; then
	run powershell.exe -NoProfile -ExecutionPolicy Bypass -File tools/build-web.ps1
elif command -v pwsh >/dev/null 2>&1; then
	run pwsh -NoProfile -File tools/build-web.ps1
else
	printf '%s\n' "PowerShell not found: tools/build-web.ps1 applies the PWA patch that the installable app needs." >&2
	exit 1
fi

# 2. Server image, built locally from the story 016 Dockerfile.
printf '== 2/6 server image\n'
run docker build -t coup-server:latest .

# 3. Host directories and the deploy files.
printf '== 3/6 deploy files\n'
remote "mkdir -p '$deploy_dir/site/releases'"
# shellcheck disable=SC2086
run scp $ssh_opts deploy/docker-compose.yml deploy/Caddyfile "$host:$deploy_dir/"
remote "printf 'COUP_DOMAIN=%s\n' '$domain' > '$deploy_dir/.env'"

# 4. Client release: named by its content, so an unchanged build is not sent again.
printf '== 4/6 client release\n'
if [[ $dry_run -eq 1 ]]; then
	release="RELEASE-ID-FROM-BUILD-CONTENT"
else
	release="$(cat build/web/index.html build/web/index.js build/web/index.pck build/web/index.wasm | md5sum | cut -c1-12)"
fi
printf 'release %s\n' "$release"
# shellcheck disable=SC2086
if [[ $dry_run -eq 1 ]] || ! ssh $ssh_opts "$host" "test -d '$deploy_dir/site/releases/$release'"; then
	printf '+ tar czf - -C build/web . | ssh %s "mkdir -p releases/%s && tar xzf - -C releases/%s"\n' "$host" "$release" "$release"
	if [[ $dry_run -eq 0 ]]; then
		# shellcheck disable=SC2086
		tar czf - -C build/web . | ssh $ssh_opts "$host" \
			"set -e; d='$deploy_dir/site/releases/$release'; rm -rf \"\$d.partial\"; mkdir -p \"\$d.partial\"; tar xzf - -C \"\$d.partial\"; mv \"\$d.partial\" \"\$d\""
	fi
else
	printf 'release %s is already on the host, not sent again\n' "$release"
fi
# ln -sfn replaces the link in one step; the previous release stays for a quick rollback.
remote "cd '$deploy_dir/site' && ln -sfn 'releases/$release' current.new && mv -T current.new current && ls -1dt releases/* | tail -n +4 | xargs -r rm -rf"

# 5. Server image on the host, only when it changed, then (re)start the stack.
printf '== 5/6 server image and stack\n'
if [[ $dry_run -eq 1 ]]; then
	printf '+ docker save coup-server:latest | gzip | ssh %s "gunzip | docker load"   (skipped when the image id matches)\n' "$host"
else
	local_id="$(docker image inspect --format '{{.Id}}' coup-server:latest)"
	# shellcheck disable=SC2086
	remote_id="$(ssh $ssh_opts "$host" "docker image inspect --format '{{.Id}}' coup-server:latest 2>/dev/null || true")"
	if [[ "$local_id" == "$remote_id" ]]; then
		printf 'server image already on the host, not sent again\n'
	else
		# shellcheck disable=SC2086
		docker save coup-server:latest | gzip | ssh $ssh_opts "$host" 'gunzip | docker load'
	fi
fi
remote "cd '$deploy_dir' && docker compose up -d --remove-orphans"

# 6. Smoke check; the first run may need a few seconds for the certificate.
printf '== 6/6 smoke check\n'
if [[ $dry_run -eq 1 ]]; then
	printf '+ tools/smoke-check.sh https://%s\n' "$domain"
	exit 0
fi
for attempt in 1 2 3 4 5; do
	if bash tools/smoke-check.sh "https://$domain"; then
		printf 'PUBLISHED https://%s (release %s)\n' "$domain" "$release"
		exit 0
	fi
	printf 'smoke check failed (attempt %d of 5), retrying in 15 s\n' "$attempt"
	sleep 15
done
printf 'PUBLISH FAILED: the smoke check never passed for https://%s\n' "$domain" >&2
exit 1
