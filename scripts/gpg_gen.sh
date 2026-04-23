#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/gpg_batch.sh
source "$SCRIPT_DIR/lib/gpg_batch.sh"

load_repo_env
require_env_vars GIT_NAME GIT_EMAIL GPG_EXPIRATION

gpg_batch_file="$(mktemp)"
create_gpg_batch_file "$gpg_batch_file"

gpg --batch --generate-key "$gpg_batch_file"
rm -f "$gpg_batch_file"

# Resolve the generated key ID by matching UID email in machine-readable output.
GPG_KEY_ID="$({
  gpg --batch --with-colons --list-secret-keys 2>/dev/null || true
} | awk -F: -v email="$GIT_EMAIL" '
  $1 == "sec" {
    current_keyid = $5
    next
  }
  $1 == "uid" && current_keyid != "" {
    if (index($10, email) > 0) {
      print current_keyid
      exit
    }
  }
')"

if [[ -z "$GPG_KEY_ID" ]]; then
  # Fallback: use first available secret key ID.
  GPG_KEY_ID="$({
    gpg --batch --with-colons --list-secret-keys 2>/dev/null || true
  } | awk -F: '$1 == "sec" { print $5; exit }')"
fi

if [[ -z "$GPG_KEY_ID" ]]; then
  echo "Unable to locate a generated GPG secret key ID. Verify .env values and gpg installation." >&2
  exit 1
fi

# 5. Output Public Keys
echo "-------------------------------------------------------"
echo "SETUP COMPLETE locally."
echo "-------------------------------------------------------"
echo "GPG PUBLIC KEY (Add to all providers):"
gpg --armor --export "$GPG_KEY_ID"
echo ""
echo "GITHUB SSH PUBLIC KEY (Paste into GitHub Settings):"
if [[ -f "$HOME/.ssh/id_github.pub" ]]; then
  cat "$HOME/.ssh/id_github.pub"
else
  echo "No GitHub SSH key found at $HOME/.ssh/id_github.pub"
fi
echo ""
echo "-------------------------------------------------------"