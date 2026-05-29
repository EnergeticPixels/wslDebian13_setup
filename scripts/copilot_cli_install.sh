#!/usr/bin/env bash
set -euo pipefail

log() {
	printf '[%s] %s\n' "$(date +'%Y-%m-%d %H:%M:%S')" "$*"
}

if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
	echo "This script must run as root. Use: sudo bash scripts/copilot_cli_install.sh" >&2
	exit 1
fi

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/../.env"
INSTALL_URL="https://gh.io/copilot-install"

load_copilot_env() {
	if [[ -f "$ENV_FILE" ]]; then
		# shellcheck source=/dev/null
		source "$ENV_FILE"
	fi

	if [[ -z "${COPILOT_ENABLE:-}" && -n "${copilot_enable:-}" ]]; then
		COPILOT_ENABLE="$copilot_enable"
	fi
	if [[ -z "${COPILOT_VERSION:-}" && -n "${copilot_version:-}" ]]; then
		COPILOT_VERSION="$copilot_version"
	fi

	COPILOT_ENABLE="${COPILOT_ENABLE:-false}"
	COPILOT_VERSION="${COPILOT_VERSION:-latest}"

	case "$(printf '%s' "$COPILOT_ENABLE" | tr '[:upper:]' '[:lower:]')" in
		1|true|yes|y|on)
			COPILOT_ENABLE=true
			;;
		0|false|no|n|off)
			COPILOT_ENABLE=false
			;;
		*)
			echo "Invalid COPILOT_ENABLE '$COPILOT_ENABLE'. Supported values: true/false" >&2
			exit 1
			;;
	esac

	if [[ "$COPILOT_VERSION" != "latest" ]] && [[ ! "$COPILOT_VERSION" =~ ^v[0-9]+\.[0-9]+\.[0-9]+([.-][0-9A-Za-z.-]+)?$ ]]; then
		echo "Invalid COPILOT_VERSION '$COPILOT_VERSION'. Use 'latest' or a tag like v1.0.56" >&2
		exit 1
	fi

	export COPILOT_ENABLE
	export COPILOT_VERSION
}

install_copilot_cli() {
	log "Installing standalone GitHub Copilot CLI from official install script"

	if [[ "$COPILOT_VERSION" == "latest" ]]; then
		curl -fsSL "$INSTALL_URL" | bash
	else
		curl -fsSL "$INSTALL_URL" | VERSION="$COPILOT_VERSION" bash
	fi
}

print_auth_guidance() {
	if [[ -n "${COPILOT_GITHUB_TOKEN:-}" || -n "${GH_TOKEN:-}" || -n "${GITHUB_TOKEN:-}" ]]; then
		log "A Copilot token environment variable is present for this shell session."
	else
		log "To authenticate Copilot CLI, run 'copilot' and use the /login command when prompted."
	fi
}

main() {
	load_copilot_env

	if [[ "$COPILOT_ENABLE" != "true" ]]; then
		log "COPILOT_ENABLE is false. Skipping standalone GitHub Copilot CLI provisioning."
		exit 0
	fi

	if ! command -v curl >/dev/null 2>&1; then
		echo "curl is required to install GitHub Copilot CLI." >&2
		exit 1
	fi

	install_copilot_cli

	if ! command -v copilot >/dev/null 2>&1; then
		echo "GitHub Copilot CLI installation failed: copilot command not found after install." >&2
		exit 1
	fi

	log "Installed GitHub Copilot CLI version: $(copilot --version | head -n 1)"
	print_auth_guidance
	log "Standalone GitHub Copilot CLI provisioning complete."
}

main "$@"
