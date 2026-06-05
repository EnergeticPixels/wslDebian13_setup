#!/usr/bin/env bash
set -euo pipefail

log() {
	printf '[%s] %s\n' "$(date +'%Y-%m-%d %H:%M:%S')" "$*"
}

if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
	echo "This script must run as root. Use: sudo bash scripts/video_editor_openshot_install.sh" >&2
	exit 1
fi

log "Updating apt index for OpenShot installation"
apt-get update
log "Installing OpenShot"
apt-get install -y openshot-qt

if command -v openshot-qt >/dev/null 2>&1; then
	log "OpenShot installed: $(openshot-qt --version | head -n 1)"
else
	echo "OpenShot installation verification failed: command not found" >&2
	exit 1
fi
