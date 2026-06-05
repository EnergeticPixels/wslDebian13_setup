#!/usr/bin/env bash
set -euo pipefail

log() {
	printf '[%s] %s\n' "$(date +'%Y-%m-%d %H:%M:%S')" "$*"
}

if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
	echo "This script must run as root. Use: sudo bash scripts/video_editor_install.sh" >&2
	exit 1
fi

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
FRONTEND_LIB="$SCRIPT_DIR/lib/frontend_apps.sh"
OPENSHOT_SCRIPT="$SCRIPT_DIR/video_editor_openshot_install.sh"
DAVINCI_SCRIPT="$SCRIPT_DIR/video_editor_davinci_install.sh"

if [[ ! -f "$FRONTEND_LIB" ]]; then
	echo "Missing helper library: $FRONTEND_LIB" >&2
	exit 1
fi

# shellcheck source=/dev/null
source "$FRONTEND_LIB"
load_frontend_apps_env

case "$VIDEO_EDITOR" in
	openshot)
		if [[ ! -f "$OPENSHOT_SCRIPT" ]]; then
			echo "Missing installer script: $OPENSHOT_SCRIPT" >&2
			exit 1
		fi
		log "Running OpenShot installer"
		bash "$OPENSHOT_SCRIPT"
		;;
	davinci)
		if [[ ! -f "$DAVINCI_SCRIPT" ]]; then
			echo "Missing installer script: $DAVINCI_SCRIPT" >&2
			exit 1
		fi
		log "Running DaVinci Resolve installer"
		bash "$DAVINCI_SCRIPT"
		;;
	none)
		log "VIDEO_EDITOR=none. Skipping video editor installation."
		;;
	*)
		echo "Invalid VIDEO_EDITOR '$VIDEO_EDITOR'. Supported values: none, openshot, davinci" >&2
		exit 1
		;;
esac
