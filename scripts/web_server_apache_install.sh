#!/usr/bin/env bash
set -euo pipefail

log() {
	printf '[%s] %s\n' "$(date +'%Y-%m-%d %H:%M:%S')" "$*"
}

if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
	echo "This script must run as root. Use: sudo bash scripts/web_server_apache_install.sh" >&2
	exit 1
fi

log "Installing Apache web server (apache2)."
apt-get install -y apache2

log "Apache installation complete."