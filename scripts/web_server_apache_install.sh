#!/usr/bin/env bash
set -euo pipefail

log() {
	printf '[%s] %s\n' "$(date +'%Y-%m-%d %H:%M:%S')" "$*"
}

if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
	echo "This script must run as root. Use: sudo bash scripts/web_server_apache_install.sh" >&2
	exit 1
fi

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PHP_WEB_LIB="$SCRIPT_DIR/lib/php_web.sh"

if [[ ! -f "$PHP_WEB_LIB" ]]; then
	echo "Missing helper library: $PHP_WEB_LIB" >&2
	exit 1
fi

# shellcheck source=/dev/null
source "$PHP_WEB_LIB"
load_web_stack_env

log "Installing Apache web server (apache2)."
apt-get install -y apache2

if php_is_enabled; then
	validate_php_version
	ensure_php_package_source
	install_versioned_php_packages

	log "Configuring Apache for php-fpm version $PHP_VERSION."
	a2enmod proxy_fcgi setenvif
	a2enconf "php${PHP_VERSION}-fpm"
	systemctl enable --now "php${PHP_VERSION}-fpm"
	systemctl restart apache2
	log "Apache configured with php-fpm version $PHP_VERSION."
else
	log "PHP installation disabled by PHP_ENABLE=false."
fi

log "Apache installation complete."