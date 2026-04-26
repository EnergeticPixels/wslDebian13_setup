#!/usr/bin/env bash
set -euo pipefail

# If invoked via sudo as root, re-run as the original user so keys are
# generated in the user's keyring instead of /root.
if [[ "${EUID:-$(id -u)}" -eq 0 && -n "${SUDO_USER:-}" && "${GPG_GEN_REEXEC_AS_USER:-0}" != "1" ]]; then
  export GPG_GEN_REEXEC_AS_USER=1
  exec sudo -u "$SUDO_USER" -H bash "$0" "$@"
fi

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/gpg_batch.sh
source "$SCRIPT_DIR/lib/gpg_batch.sh"

load_repo_env
require_env_vars GIT_NAME GIT_EMAIL GPG_EXPIRATION

uid="$GIT_NAME <$GIT_EMAIL>"

prompt_for_gpg_passphrase() {
  local pass1 pass2

  while true; do
    read -r -s -p "Enter GPG passphrase: " pass1
    echo ""
    read -r -s -p "Confirm GPG passphrase: " pass2
    echo ""

    if [[ -z "$pass1" ]]; then
      echo "GPG passphrase cannot be empty." >&2
      continue
    fi

    if [[ "$pass1" != "$pass2" ]]; then
      echo "Passphrases do not match. Try again." >&2
      continue
    fi

    GPG_PASSPHRASE="$pass1"
    break
  done
}

gpg_with_passphrase() {
  printf '%s\n' "$GPG_PASSPHRASE" | gpg --batch --pinentry-mode loopback --passphrase-fd 0 "$@"
}

prompt_for_gpg_passphrase

# Generate a signing-capable Ed25519 primary key using interactive pinentry.
gpg_with_passphrase --quick-generate-key "$uid" ed25519 sign "$GPG_EXPIRATION"

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

GPG_FPR="$({
  gpg --batch --with-colons --list-secret-keys 2>/dev/null || true
} | awk -F: -v email="$GIT_EMAIL" '
  $1 == "sec" {
    current_keyid = $5
    next
  }
  $1 == "fpr" && current_keyid != "" {
    fpr_by_keyid[current_keyid] = $10
    next
  }
  $1 == "uid" && current_keyid != "" {
    if (index($10, email) > 0) {
      print fpr_by_keyid[current_keyid]
      exit
    }
  }
')"

if [[ -z "$GPG_FPR" ]]; then
  GPG_FPR="$({
    gpg --batch --with-colons --list-secret-keys 2>/dev/null || true
  } | awk -F: '$1 == "fpr" { print $10; exit }')"
fi

if [[ -z "$GPG_FPR" ]]; then
  echo "Unable to locate the generated GPG key fingerprint. Verify .env values and gpg installation." >&2
  exit 1
fi

# Ensure there is an encryption subkey for provider workflows.
has_encrypt_subkey="$({
  gpg --batch --with-colons --list-secret-keys "$GPG_FPR" 2>/dev/null || true
} | awk -F: '$1 == "ssb" && index($12, "e") > 0 { found=1 } END { print found+0 }')"

if [[ "$has_encrypt_subkey" -eq 0 ]]; then
  gpg_with_passphrase --quick-add-key "$GPG_FPR" cv25519 encrypt "$GPG_EXPIRATION"
fi

unset GPG_PASSPHRASE

# 5. Output Public Keys
echo "-------------------------------------------------------"
echo "SETUP COMPLETE locally."
echo "-------------------------------------------------------"
echo "GPG PUBLIC KEY (Add to all providers):"
exported=0

if [[ -n "$GPG_FPR" ]]; then
  if gpg --armor --export "$GPG_FPR"; then
    exported=1
  fi
fi

if [[ "$exported" -eq 0 && -n "$GIT_EMAIL" ]]; then
  if gpg --armor --export "$GIT_EMAIL"; then
    exported=1
  fi
fi

if [[ "$exported" -eq 0 && -n "$GPG_KEY_ID" ]]; then
  if gpg --armor --export "$GPG_KEY_ID"; then
    exported=1
  fi
fi

if [[ "$exported" -eq 0 ]]; then
  echo "Unable to export a GPG public key. Available secret keys:" >&2
  gpg --list-secret-keys >&2 || true
  exit 1
fi

echo ""
echo "GITHUB SSH PUBLIC KEY (Paste into GitHub Settings):"
if [[ -f "$HOME/.ssh/id_github.pub" ]]; then
  cat "$HOME/.ssh/id_github.pub"
else
  echo "No GitHub SSH key found at $HOME/.ssh/id_github.pub"
fi
echo ""
echo "-------------------------------------------------------"