#!/usr/bin/env bash
set -euo pipefail

log() {
	printf '[%s] %s\n' "$(date +'%Y-%m-%d %H:%M:%S')" "$*"
}

if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
	echo "This script must run as root. Use: sudo bash scripts/video_editor_davinci_install.sh" >&2
	exit 1
fi

log "Attempting DaVinci Resolve installation from available community package sources"
apt-get update

candidate_package=""
for package_name in davinci-resolve davinci-resolve-studio; do
	candidate_version="$(apt-cache policy "$package_name" | awk '/Candidate:/ {print $2}')"
	if [[ -n "$candidate_version" && "$candidate_version" != "(none)" ]]; then
		candidate_package="$package_name"
		break
	fi
done

if [[ -z "$candidate_package" ]]; then
	log "No installable apt package found for DaVinci Resolve."
	log "Expected community package names checked: davinci-resolve, davinci-resolve-studio"
	log "Skipping DaVinci installation. If desired, add a supported community repository and re-run this script."
	exit 0
fi

log "Installing DaVinci package: $candidate_package"
apt-get install -y "$candidate_package"

if command -v resolve >/dev/null 2>&1; then
	log "DaVinci Resolve installed: command 'resolve' is available"
elif [[ -x "/opt/resolve/bin/resolve" ]]; then
	log "DaVinci Resolve installed at /opt/resolve/bin/resolve"
else
	echo "DaVinci Resolve installation verification failed: runtime executable not found" >&2
	exit 1
fi
