#!/usr/bin/env bash
set -euo pipefail

if ! command -v log >/dev/null 2>&1; then
	log() {
		printf '[%s] %s\n' "$(date +'%Y-%m-%d %H:%M:%S')" "$*"
	}
fi

load_web_stack_env() {
	local script_dir env_file
	script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
	env_file="$script_dir/../../.env"

	if [[ -f "$env_file" ]]; then
		# shellcheck source=/dev/null
		source "$env_file"
	fi

	# Backward compatibility for lowercase key names.
	if [[ -z "${WEB_SERVER:-}" && -n "${web_server:-}" ]]; then
		WEB_SERVER="$web_server"
	fi
	if [[ -z "${PHP_ENABLE:-}" && -n "${php_enable:-}" ]]; then
		PHP_ENABLE="$php_enable"
	fi
	if [[ -z "${PHP_VERSION:-}" && -n "${php_version:-}" ]]; then
		PHP_VERSION="$php_version"
	fi

	PHP_ENABLE="${PHP_ENABLE:-false}"
	PHP_VERSION="${PHP_VERSION:-7.4}"

	case "$(printf '%s' "$PHP_ENABLE" | tr '[:upper:]' '[:lower:]')" in
		1|true|yes|y|on)
			PHP_ENABLE=true
			;;
		0|false|no|n|off)
			PHP_ENABLE=false
			;;
		*)
			echo "Invalid PHP_ENABLE '$PHP_ENABLE'. Supported values: true/false" >&2
			exit 1
			;;
	esac

	export WEB_SERVER
	export PHP_ENABLE
	export PHP_VERSION
}

validate_php_version() {
	case "$PHP_VERSION" in
		7.4|8.0|8.1|8.2|8.3)
			return 0
			;;
		*)
			echo "Invalid PHP_VERSION '$PHP_VERSION'. Supported values: 7.4, 8.0, 8.1, 8.2, 8.3" >&2
			exit 1
			;;
	esac
}

php_is_enabled() {
	[[ "$PHP_ENABLE" == "true" ]]
}

ensure_sury_php_repo() {
	local keyring repo_file codename
	keyring="/usr/share/keyrings/debsuryorg-archive-keyring.gpg"
	repo_file="/etc/apt/sources.list.d/php.list"
	codename="$(. /etc/os-release && echo "${VERSION_CODENAME:-}")"

	if [[ -z "$codename" ]]; then
		echo "Unable to determine Debian codename for Sury repository setup." >&2
		exit 1
	fi

	if [[ ! -f "$keyring" ]]; then
		log "Installing Sury PHP repository keyring."
		apt-get install -y ca-certificates curl gnupg2
		mkdir -p /usr/share/keyrings
		curl -fsSL https://packages.sury.org/php/apt.gpg | gpg --dearmor -o "$keyring"
	fi

	if [[ ! -f "$repo_file" ]] || ! grep -q "packages.sury.org/php" "$repo_file"; then
		log "Adding Sury PHP repository for Debian codename: $codename"
		echo "deb [signed-by=$keyring] https://packages.sury.org/php/ $codename main" > "$repo_file"
	fi

	apt-get update
}

ensure_php_package_source() {
	local package_name candidate
	package_name="php${PHP_VERSION}-fpm"
	apt-get update
	candidate="$(apt-cache policy "$package_name" | awk '/Candidate:/ {print $2}')"

	if [[ -z "$candidate" || "$candidate" == "(none)" ]]; then
		log "Package $package_name not found in current apt sources. Falling back to Sury PHP repository."
		ensure_sury_php_repo
		candidate="$(apt-cache policy "$package_name" | awk '/Candidate:/ {print $2}')"
	fi

	if [[ -z "$candidate" || "$candidate" == "(none)" ]]; then
		echo "Unable to find package $package_name after configuring repositories." >&2
		exit 1
	fi
}

install_versioned_php_packages() {
	local version_prefix
	version_prefix="php${PHP_VERSION}"

	apt-get install -y \
		"${version_prefix}-fpm" \
		"${version_prefix}-cli" \
		"${version_prefix}-common"
}
