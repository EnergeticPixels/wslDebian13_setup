#!/usr/bin/env bash
set -euo pipefail

log() {
	printf '[%s] %s\n' "$(date +'%Y-%m-%d %H:%M:%S')" "$*"
}

if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
	echo "This script must run as root. Use: sudo bash scripts/frontend_apps_install.sh" >&2
	exit 1
fi

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
FRONTEND_LIB="$SCRIPT_DIR/lib/frontend_apps.sh"
VIDEO_EDITOR_SCRIPT="$SCRIPT_DIR/video_editor_install.sh"

if [[ ! -f "$FRONTEND_LIB" ]]; then
	echo "Missing helper library: $FRONTEND_LIB" >&2
	exit 1
fi

# shellcheck source=/dev/null
source "$FRONTEND_LIB"
load_frontend_apps_env

log "=== Front-end Creative Apps Installation Starting ==="
log "INKSCAPE_ENABLE=$INKSCAPE_ENABLE"
log "GIMP_ENABLE=$GIMP_ENABLE"
log "BLENDER_ENABLE=$BLENDER_ENABLE"
log "AUDACITY_ENABLE=$AUDACITY_ENABLE"
log "VIDEO_EDITOR=$VIDEO_EDITOR"

if [[ "$INKSCAPE_ENABLE" == "false" && "$GIMP_ENABLE" == "false" && "$BLENDER_ENABLE" == "false" && "$AUDACITY_ENABLE" == "false" && "$VIDEO_EDITOR" == "none" ]]; then
	log "All front-end creative apps are disabled. Skipping installation."
	exit 0
fi

if [[ "$INKSCAPE_ENABLE" == "true" ]]; then
	log "Installing Inkscape"
	bash "$SCRIPT_DIR/inkscape_install.sh"
fi

if [[ "$GIMP_ENABLE" == "true" ]]; then
	log "Installing GIMP"
	bash "$SCRIPT_DIR/gimp_install.sh"
fi

if [[ "$BLENDER_ENABLE" == "true" ]]; then
	log "Installing Blender"
	bash "$SCRIPT_DIR/blender_install.sh"
fi

if [[ "$AUDACITY_ENABLE" == "true" ]]; then
	log "Installing Audacity"
	bash "$SCRIPT_DIR/audacity_install.sh"
fi

if [[ "$VIDEO_EDITOR" != "none" ]]; then
	if [[ ! -f "$VIDEO_EDITOR_SCRIPT" ]]; then
		echo "Missing video editor dispatcher: $VIDEO_EDITOR_SCRIPT" >&2
		exit 1
	fi

	log "Installing configured video editor: $VIDEO_EDITOR"
	bash "$VIDEO_EDITOR_SCRIPT"
else
	log "VIDEO_EDITOR=none. Skipping video editor installation."
fi

log "=== Front-end Creative Apps Installation Complete ==="
