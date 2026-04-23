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

run_core_script() {
	local script_path="$1"

	if [[ ! -f "$script_path" ]]; then
		log "Skipping missing script: $script_path"
		return 0
	fi

	chmod +x "$script_path"
	log "Running $(basename "$script_path")"
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

	log "Starting Debian provisioning"
	# apt-get update
	# apt-get dist-upgrade -y
	apt-get install -y "${BASE_PACKAGES[@]}"

	bootstrap_env_file

	run_core_script "$SCRIPTS_DIR/ssh_gen.sh"
	run_core_script "$SCRIPTS_DIR/gpg_gen.sh"
	run_core_script "$SCRIPTS_DIR/git-config.sh"

	run_modules

	log "Provisioning complete"
}

main "$@"