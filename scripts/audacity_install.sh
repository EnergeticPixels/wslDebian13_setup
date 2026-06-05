#!/usr/bin/env bash
set -euo pipefail

log() {
	printf '[%s] %s\n' "$(date +'%Y-%m-%d %H:%M:%S')" "$*"
}

if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
	echo "This script must run as root. Use: sudo bash scripts/audacity_install.sh" >&2
	exit 1
fi

log "Updating apt index for Audacity installation"
apt-get update
log "Installing Audacity"
apt-get install -y audacity

if command -v audacity >/dev/null 2>&1; then
	log "Audacity installed: $(audacity --version | head -n 1)"
else
	echo "Audacity installation verification failed: command not found" >&2
	exit 1
fi
