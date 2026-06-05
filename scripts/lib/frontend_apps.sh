#!/usr/bin/env bash
set -euo pipefail

if ! command -v log >/dev/null 2>&1; then
	log() {
		printf '[%s] %s\n' "$(date +'%Y-%m-%d %H:%M:%S')" "$*"
	}
fi

normalize_boolean_value() {
	local raw_value normalized
	raw_value="$1"
	normalized="$(printf '%s' "$raw_value" | tr '[:upper:]' '[:lower:]')"

	case "$normalized" in
		1|true|yes|y|on)
			echo "true"
			;;
		0|false|no|n|off)
			echo "false"
			;;
		*)
			echo ""
			;;
	esac
}

validate_video_editor() {
	case "$VIDEO_EDITOR" in
		none|openshot|davinci)
			return 0
			;;
		*)
			echo "Invalid VIDEO_EDITOR '$VIDEO_EDITOR'. Supported values: none, openshot, davinci" >&2
			exit 1
			;;
	esac
}

load_frontend_apps_env() {
	local script_dir env_file normalized
	script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
	env_file="$script_dir/../../.env"

	if [[ -f "$env_file" ]]; then
		# shellcheck source=/dev/null
		source "$env_file"
	fi

	if [[ -z "${INKSCAPE_ENABLE:-}" && -n "${inkscape_enable:-}" ]]; then
		INKSCAPE_ENABLE="$inkscape_enable"
	fi
	if [[ -z "${GIMP_ENABLE:-}" && -n "${gimp_enable:-}" ]]; then
		GIMP_ENABLE="$gimp_enable"
	fi
	if [[ -z "${BLENDER_ENABLE:-}" && -n "${blender_enable:-}" ]]; then
		BLENDER_ENABLE="$blender_enable"
	fi
	if [[ -z "${AUDACITY_ENABLE:-}" && -n "${audacity_enable:-}" ]]; then
		AUDACITY_ENABLE="$audacity_enable"
	fi
	if [[ -z "${VIDEO_EDITOR:-}" && -n "${video_editor:-}" ]]; then
		VIDEO_EDITOR="$video_editor"
	fi

	INKSCAPE_ENABLE="${INKSCAPE_ENABLE:-false}"
	GIMP_ENABLE="${GIMP_ENABLE:-false}"
	BLENDER_ENABLE="${BLENDER_ENABLE:-false}"
	AUDACITY_ENABLE="${AUDACITY_ENABLE:-false}"
	VIDEO_EDITOR="${VIDEO_EDITOR:-none}"

	normalized="$(normalize_boolean_value "$INKSCAPE_ENABLE")"
	if [[ -z "$normalized" ]]; then
		echo "Invalid INKSCAPE_ENABLE '$INKSCAPE_ENABLE'. Supported values: true/false" >&2
		exit 1
	fi
	INKSCAPE_ENABLE="$normalized"

	normalized="$(normalize_boolean_value "$GIMP_ENABLE")"
	if [[ -z "$normalized" ]]; then
		echo "Invalid GIMP_ENABLE '$GIMP_ENABLE'. Supported values: true/false" >&2
		exit 1
	fi
	GIMP_ENABLE="$normalized"

	normalized="$(normalize_boolean_value "$BLENDER_ENABLE")"
	if [[ -z "$normalized" ]]; then
		echo "Invalid BLENDER_ENABLE '$BLENDER_ENABLE'. Supported values: true/false" >&2
		exit 1
	fi
	BLENDER_ENABLE="$normalized"

	normalized="$(normalize_boolean_value "$AUDACITY_ENABLE")"
	if [[ -z "$normalized" ]]; then
		echo "Invalid AUDACITY_ENABLE '$AUDACITY_ENABLE'. Supported values: true/false" >&2
		exit 1
	fi
	AUDACITY_ENABLE="$normalized"

	VIDEO_EDITOR="$(printf '%s' "$VIDEO_EDITOR" | tr '[:upper:]' '[:lower:]')"
	validate_video_editor

	export INKSCAPE_ENABLE
	export GIMP_ENABLE
	export BLENDER_ENABLE
	export AUDACITY_ENABLE
	export VIDEO_EDITOR
}
