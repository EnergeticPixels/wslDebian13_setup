#!/usr/bin/env bash
set -euo pipefail

log() {
	printf '[%s] %s\n' "$(date +'%Y-%m-%d %H:%M:%S')" "$*"
}

if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
	echo "This script must run as root. Use: sudo bash scripts/inkscape_install.sh" >&2
	exit 1
fi

log "Updating apt index for Inkscape installation"
apt-get update
log "Installing Inkscape"
apt-get install -y inkscape

if command -v inkscape >/dev/null 2>&1; then
	log "Inkscape installed: $(inkscape --version | head -n 1)"
else
	echo "Inkscape installation verification failed: command not found" >&2
	exit 1
fi
