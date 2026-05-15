#!/usr/bin/env bash
set -euo pipefail

log() {
	printf '[%s] %s\n' "$(date +'%Y-%m-%d %H:%M:%S')" "$*"
}

if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
	echo "This script must run as root. Use: sudo bash scripts/web_server_install.sh" >&2
	exit 1
fi

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/../.env"
APACHE_SCRIPT="$SCRIPT_DIR/web_server_apache_install.sh"
NGINX_SCRIPT="$SCRIPT_DIR/web_server_nginx_install.sh"

# Load optional configuration from repo .env.
if [[ -f "$ENV_FILE" ]]; then
	# shellcheck source=/dev/null
	source "$ENV_FILE"
fi

# Backward compatibility for lowercase key names.
if [[ -z "${WEB_SERVER:-}" && -n "${web_server:-}" ]]; then
	WEB_SERVER="$web_server"
fi

if [[ -z "${WEB_SERVER:-}" ]]; then
	log "WEB_SERVER is not set in .env. Skipping web server installation."
	exit 0
fi

web_server_choice="$(printf '%s' "$WEB_SERVER" | tr '[:upper:]' '[:lower:]')"

case "$web_server_choice" in
	apache)
		if [[ ! -f "$APACHE_SCRIPT" ]]; then
			echo "Missing installer script: $APACHE_SCRIPT" >&2
			exit 1
		fi

		log "Running Apache installer script."
		bash "$APACHE_SCRIPT"
		;;
	nginx)
		if [[ ! -f "$NGINX_SCRIPT" ]]; then
			echo "Missing installer script: $NGINX_SCRIPT" >&2
			exit 1
		fi

		log "Running Nginx installer script."
		bash "$NGINX_SCRIPT"
		;;
	*)
		echo "Invalid WEB_SERVER '$WEB_SERVER'. Supported values: apache, nginx" >&2
		exit 1
		;;
esac

log "Web server provisioning complete via installer: $web_server_choice"