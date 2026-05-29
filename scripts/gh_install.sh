#!/usr/bin/env bash
set -euo pipefail

log() {
	printf '[%s] %s\n' "$(date +'%Y-%m-%d %H:%M:%S')" "$*"
}

if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
	echo "This script must run as root. Use: sudo bash scripts/gh_install.sh" >&2
	exit 1
fi

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/../.env"

load_gh_env() {
	if [[ -f "$ENV_FILE" ]]; then
		# shellcheck source=/dev/null
		source "$ENV_FILE"
	fi

	if [[ -z "${GH_ENABLE:-}" && -n "${gh_enable:-}" ]]; then
		GH_ENABLE="$gh_enable"
	fi
	if [[ -z "${GH_AUTH_MODE:-}" && -n "${gh_auth_mode:-}" ]]; then
		GH_AUTH_MODE="$gh_auth_mode"
	fi
	if [[ -z "${GH_HOST:-}" && -n "${gh_host:-}" ]]; then
		GH_HOST="$gh_host"
	fi

	GH_ENABLE="${GH_ENABLE:-false}"
	GH_AUTH_MODE="${GH_AUTH_MODE:-none}"
	GH_HOST="${GH_HOST:-github.com}"

	case "$(printf '%s' "$GH_ENABLE" | tr '[:upper:]' '[:lower:]')" in
		1|true|yes|y|on)
			GH_ENABLE=true
			;;
		0|false|no|n|off)
			GH_ENABLE=false
			;;
		*)
			echo "Invalid GH_ENABLE '$GH_ENABLE'. Supported values: true/false" >&2
			exit 1
			;;
	esac

	case "$GH_AUTH_MODE" in
		none|token|device)
			;;
		*)
			echo "Invalid GH_AUTH_MODE '$GH_AUTH_MODE'. Supported values: none, token, device" >&2
			exit 1
			;;
	esac

	export GH_ENABLE
	export GH_AUTH_MODE
	export GH_HOST
}

resolve_target_user() {
	if [[ -n "${SUDO_USER:-}" && "${SUDO_USER:-}" != "root" ]]; then
		TARGET_USER="$SUDO_USER"
		TARGET_HOME="$(getent passwd "$TARGET_USER" | cut -d: -f6 || true)"
		if [[ -z "$TARGET_HOME" ]]; then
			echo "Unable to determine home directory for user $TARGET_USER" >&2
			exit 1
		fi
	else
		TARGET_USER="root"
		TARGET_HOME="/root"
	fi

	export TARGET_USER
	export TARGET_HOME
}

run_as_target_user() {
	local command
	command="$1"

	if [[ "$TARGET_USER" == "root" ]]; then
		bash -lc "$command"
	else
		sudo -u "$TARGET_USER" -H bash -lc "$command"
	fi
}

run_as_target_user_preserve_env() {
	local command env_name
	command="$1"
	env_name="$2"

	if [[ "$TARGET_USER" == "root" ]]; then
		bash -lc "$command"
	else
		sudo --preserve-env="$env_name" -u "$TARGET_USER" -H bash -lc "$command"
	fi
}

ensure_gh_installed() {
	if command -v gh >/dev/null 2>&1; then
		log "GitHub CLI already installed: $(gh --version | head -n 1)"
		return 0
	fi

	log "Installing GitHub CLI from apt repositories"
	apt-get update
	if apt-get install -y gh; then
		return 0
	fi

	log "Default apt source did not provide gh; adding official GitHub CLI apt repository"
	apt-get install -y ca-certificates curl gnupg
	install -d -m 0755 /etc/apt/keyrings
	curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
		| dd of=/etc/apt/keyrings/githubcli-archive-keyring.gpg 2>/dev/null
	chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg

	echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
		> /etc/apt/sources.list.d/github-cli.list

	apt-get update
	apt-get install -y gh
}

print_auth_summary() {
	if run_as_target_user "gh auth status -h '$GH_HOST' >/dev/null 2>&1"; then
		log "gh authentication already configured for host '$GH_HOST' (user: $TARGET_USER)."
	else
		log "gh is installed but not authenticated for host '$GH_HOST' (user: $TARGET_USER)."
		log "Run: sudo -u $TARGET_USER -H gh auth login -h $GH_HOST"
	fi
}

configure_gh_auth() {
	local gh_install_token=""

	if run_as_target_user "gh auth status -h '$GH_HOST' >/dev/null 2>&1"; then
		log "gh authentication already configured for host '$GH_HOST' (user: $TARGET_USER)."
		return 0
	fi

	case "$GH_AUTH_MODE" in
		none)
			log "GH_AUTH_MODE=none. Skipping authentication automation."
			;;
		token)
			if [[ -n "${GH_TOKEN:-}" ]]; then
				gh_install_token="$GH_TOKEN"
			elif [[ -n "${GITHUB_TOKEN:-}" ]]; then
				gh_install_token="$GITHUB_TOKEN"
			else
				echo "GH_AUTH_MODE=token requires GH_TOKEN or GITHUB_TOKEN in the runtime environment." >&2
				return 1
			fi

			export GH_INSTALL_TOKEN="$gh_install_token"
			log "Authenticating gh for host '$GH_HOST' using runtime token (value not logged)."
			run_as_target_user_preserve_env "printf '%s' \"\$GH_INSTALL_TOKEN\" | gh auth login -h '$GH_HOST' --with-token" "GH_INSTALL_TOKEN"
			unset GH_INSTALL_TOKEN

			run_as_target_user "gh auth setup-git -h '$GH_HOST' >/dev/null 2>&1 || true"
			log "gh token authentication completed for host '$GH_HOST' (user: $TARGET_USER)."
			;;
		device)
			if [[ ! -t 0 || ! -t 1 ]]; then
				echo "GH_AUTH_MODE=device requires an interactive terminal. Run scripts/gh_install.sh manually in a terminal." >&2
				return 1
			fi

			log "Starting interactive gh auth flow for host '$GH_HOST' (user: $TARGET_USER)."
			run_as_target_user "gh auth login -h '$GH_HOST'"
			run_as_target_user "gh auth setup-git -h '$GH_HOST' >/dev/null 2>&1 || true"
			log "Interactive gh authentication completed for host '$GH_HOST' (user: $TARGET_USER)."
			;;
		*)
			echo "Invalid GH_AUTH_MODE '$GH_AUTH_MODE'. Supported values: none, token, device" >&2
			return 1
			;;
	esac
}

main() {
	load_gh_env

	if [[ "$GH_ENABLE" != "true" ]]; then
		log "GH_ENABLE is false. Skipping GitHub CLI provisioning."
		exit 0
	fi

	resolve_target_user
	ensure_gh_installed

	if ! command -v gh >/dev/null 2>&1; then
		echo "GitHub CLI installation failed: gh command not found after install." >&2
		exit 1
	fi

	log "Installed GitHub CLI version: $(gh --version | head -n 1)"
	configure_gh_auth
	print_auth_summary
	log "GitHub CLI provisioning complete."
}

main "$@"
