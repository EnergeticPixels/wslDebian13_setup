#!/usr/bin/env bash
set -euo pipefail

log() {
	printf '[%s] %s\n' "$(date +'%Y-%m-%d %H:%M:%S')" "$*"
}

if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
	echo "This script must run as root. Use: sudo bash scripts/blender_install.sh" >&2
	exit 1
fi

log "Updating apt index for Blender installation"
apt-get update
log "Installing Blender"
apt-get install -y blender

if command -v blender >/dev/null 2>&1; then
	log "Blender installed: $(blender --version | head -n 1)"
else
	echo "Blender installation verification failed: command not found" >&2
	exit 1
fi
