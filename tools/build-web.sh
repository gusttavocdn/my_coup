#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
preset="$project_root/export_presets.cfg"
output_dir="$project_root/build/web"
output_html="$output_dir/index.html"
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

if [[ ! -f "$preset" ]]; then
	printf '%s\n' "Missing export_presets.cfg. Restore the committed Web preset before building." >&2
	exit 1
fi
if ! grep -Eq '^name="Web"[[:space:]]*$' "$preset" || ! grep -Eq '^platform="Web"[[:space:]]*$' "$preset"; then
	printf '%s\n' "export_presets.cfg does not contain a Web export preset." >&2
	exit 1
fi
if ! command -v "$godot_bin" >/dev/null 2>&1; then
	printf '%s\n' "Godot 4.7.2 was not found on PATH or at engine.path in project.yaml. Set GODOT_BIN to the pinned Godot 4.7.2 editor executable." >&2
	exit 1
fi
version="$($godot_bin --version 2>&1)"
if [[ ! "$version" =~ ^4\.7\.2 ]]; then
	printf 'Expected Godot 4.7.2 to match the installed Web export templates; found %q. Set GODOT_BIN to the pinned editor.\n' "$version" >&2
	exit 1
fi

mkdir -p "$output_dir"
if ! "$godot_bin" --headless --path "$project_root" --export-release Web "$output_html"; then
	printf '%s\n' "Godot Web export failed. Install the 4.7.2 export templates in Editor > Manage Export Templates > Download and Install, then retry." >&2
	exit 1
fi
for file in index.html index.wasm index.pck index.js; do
	if [[ ! -f "$output_dir/$file" ]]; then
		printf 'Web export did not produce %s. Install the 4.7.2 export templates in Editor > Manage Export Templates > Download and Install, then retry.\n' "$file" >&2
		exit 1
	fi
done
printf 'Web export ready: %s\n' "$output_dir"
