#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="$SCRIPT_DIR/scripts"
MODULES_DIR="$SCRIPT_DIR/modules"

BASE_PACKAGES=(
	ca-certificates
	apt-transport-https
	curl
	gnupg2
	lsb-release
	git
	wget
	build-essential
	libssl-dev
)

log() {
	printf '[%s] %s\n' "$(date +'%Y-%m-%d %H:%M:%S')" "$*"
}

require_root() {
	if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
		echo "This script must run as root. Use: sudo bash begin_here.sh" >&2
		exit 1
	fi
}

bootstrap_env_file() {
	local env_file="$SCRIPT_DIR/.env"
	local env_sample_file="$SCRIPT_DIR/.env.sample"

	if [[ ! -f "$env_file" && -f "$env_sample_file" ]]; then
		cp "$env_sample_file" "$env_file"
		log "Created $env_file from .env.sample. Update values before key generation if needed."
	fi
}

setup_logging() {
	local target_user target_home log_dir timestamp log_file_name latest_log_path

	target_user="${SUDO_USER:-}"
	target_home="$HOME"

	if [[ -n "$target_user" ]]; then
		target_home="$(getent passwd "$target_user" | cut -d: -f6 || true)"
	fi

	if [[ -z "$target_home" ]]; then
		target_home="$HOME"
	fi

	log_dir="$target_home/.debian_build/logs"
	timestamp="$(date +'%Y%m%d_%H%M%S')"
	LOG_FILE="$log_dir/provision_${timestamp}.log"
	log_file_name="$(basename "$LOG_FILE")"
	latest_log_path="$log_dir/latest.log"

	mkdir -p "$log_dir"
	touch "$LOG_FILE"
	ln -sfn "$log_file_name" "$latest_log_path"

	if [[ "${EUID:-$(id -u)}" -eq 0 && -n "$target_user" ]]; then
		chown "$target_user:$target_user" "$log_dir" "$LOG_FILE" "$latest_log_path" 2>/dev/null || true
	fi

	exec > >(tee -a "$LOG_FILE") 2>&1
	log "Writing detailed log to $LOG_FILE"
}

run_core_script() {
	local script_path="$1"
	local script_name
	script_name="$(basename "$script_path")"

	if [[ ! -f "$script_path" ]]; then
		log "Skipping missing script: $script_path"
		return 0
	fi

	chmod +x "$script_path"
	log "Running $script_name"

	# User-level configuration scripts should run as the invoking sudo user
	# so files are created in that user's home directory instead of /root.
	if [[ "${EUID:-$(id -u)}" -eq 0 && -n "${SUDO_USER:-}" ]]; then
		case "$script_name" in
			ssh_gen.sh|gpg_gen.sh|git-config.sh)
				sudo -u "$SUDO_USER" -H bash "$script_path"
				return
				;;
		esac
	fi

	bash "$script_path"
}

run_modules() {
	if [[ ! -d "$MODULES_DIR" ]]; then
		log "No modules directory found at $MODULES_DIR (this is expected until you add plugins)."
		return 0
	fi

	shopt -s nullglob
	local module_script
	for module_script in "$MODULES_DIR"/*.sh; do
		chmod +x "$module_script"
		log "Running module $(basename "$module_script")"
		bash "$module_script"
	done
	shopt -u nullglob
}

main() {
	require_root
	export DEBIAN_FRONTEND=noninteractive
	setup_logging

	log "Starting Debian provisioning"
	# apt-get update
	# apt-get dist-upgrade -y
	apt-get install -y "${BASE_PACKAGES[@]}"

	bootstrap_env_file
	log "Starting multiplexer setup (tmux)"
	run_core_script "$SCRIPTS_DIR/tmux_install.sh"
	log "Completed multiplexer setup (tmux)"

	run_core_script "$SCRIPTS_DIR/ssh_gen.sh"
	run_core_script "$SCRIPTS_DIR/gpg_gen.sh"
	run_core_script "$SCRIPTS_DIR/git-config.sh"

	run_modules

	log "Provisioning complete"
}

main "$@"