#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/../.env"

log() {
	printf '[%s] %s\n' "$(date +'%Y-%m-%d %H:%M:%S')" "$*"
}

# Load optional configuration from repo .env.
if [[ -f "$ENV_FILE" ]]; then
	# shellcheck source=/dev/null
	source "$ENV_FILE"
fi

# Backward compatibility for lowercase key names.
if [[ -z "${NEOVIM_VERSION:-}" && -n "${neovim_version:-}" ]]; then
	NEOVIM_VERSION="$neovim_version"
fi

NEOVIM_VERSION="${NEOVIM_VERSION:-0.12.0}"

if [[ ! "$NEOVIM_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
	echo "Invalid NEOVIM_VERSION '$NEOVIM_VERSION'. Expected format like 0.12.0" >&2
	exit 1
fi

if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
	echo "This script must run as root. Use: sudo bash scripts/neovim_install.sh" >&2
	exit 1
fi

case "$(dpkg --print-architecture)" in
	amd64)
		NVIM_ARCH="x86_64"
		;;
	arm64)
		NVIM_ARCH="arm64"
		;;
	*)
		echo "Unsupported architecture: $(dpkg --print-architecture). Supported: amd64, arm64" >&2
		exit 1
		;;
esac

BASE_URL="https://github.com/neovim/neovim/releases/download/v${NEOVIM_VERSION}"
ARCHIVE_NAME="nvim-linux-${NVIM_ARCH}.tar.gz"
ARCHIVE_URL="$BASE_URL/$ARCHIVE_NAME"
RELEASE_API_URL="https://api.github.com/repos/neovim/neovim/releases/tags/v${NEOVIM_VERSION}"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

log "Installing prerequisites"
apt-get update
apt-get install -y curl ca-certificates tar

log "Downloading Neovim ${NEOVIM_VERSION} for ${NVIM_ARCH}"
curl -fL "$ARCHIVE_URL" -o "$TMP_DIR/$ARCHIVE_NAME"

log "Fetching expected checksum from release metadata"
expected_sha256="$(
	curl -fsSL "$RELEASE_API_URL" |
	awk -v asset_name="$ARCHIVE_NAME" '
		$0 ~ "\"name\"[[:space:]]*:[[:space:]]*\"" asset_name "\"" {
			search_window=120
			next
		}
		search_window > 0 && $0 ~ /"digest"[[:space:]]*:[[:space:]]*"sha256:[0-9a-f]{64}"/ {
			line=$0
			sub(/^.*"sha256:/, "", line)
			sub(/".*/, "", line)
			print line
			exit
		}
		search_window > 0 { search_window-- }
	'
)"

if [[ ! "$expected_sha256" =~ ^[0-9a-f]{64}$ ]]; then
	echo "Unable to determine checksum for $ARCHIVE_NAME from $RELEASE_API_URL" >&2
	exit 1
fi

log "Verifying checksum"
actual_sha256="$(sha256sum "$TMP_DIR/$ARCHIVE_NAME" | awk '{print $1}')"

if [[ "$actual_sha256" != "$expected_sha256" ]]; then
	echo "Checksum mismatch for $ARCHIVE_NAME" >&2
	echo "Expected: $expected_sha256" >&2
	echo "Actual:   $actual_sha256" >&2
	exit 1
fi

INSTALL_ROOT="/opt"
VERSIONED_DIR="$INSTALL_ROOT/nvim-linux-${NVIM_ARCH}-${NEOVIM_VERSION}"
ACTIVE_LINK="$INSTALL_ROOT/nvim"

log "Extracting archive to $VERSIONED_DIR"
rm -rf "$VERSIONED_DIR"
mkdir -p "$VERSIONED_DIR"
tar -xzf "$TMP_DIR/$ARCHIVE_NAME" -C "$VERSIONED_DIR" --strip-components=1

ln -sfn "$VERSIONED_DIR" "$ACTIVE_LINK"
ln -sfn "$ACTIVE_LINK/bin/nvim" /usr/local/bin/nvim

log "Neovim $(nvim --version | head -n 1) installed successfully"
