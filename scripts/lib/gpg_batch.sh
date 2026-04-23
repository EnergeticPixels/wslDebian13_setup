#!/usr/bin/env bash

load_repo_env() {
  local helper_dir repo_root env_file
  helper_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
  repo_root="$(cd -- "$helper_dir/../.." && pwd)"
  env_file="${1:-$repo_root/.env}"

  if [[ ! -f "$env_file" ]]; then
    echo "Missing .env file at $env_file" >&2
    return 1
  fi

  # Export loaded values so child processes (gpg/ssh-keygen) can use them.
  set -a
  # shellcheck disable=SC1090
  source "$env_file"
  set +a
}

require_env_vars() {
  local missing=0
  local var_name

  for var_name in "$@"; do
    if [[ -z "${!var_name:-}" ]]; then
      echo "Required environment variable is missing: $var_name" >&2
      missing=1
    fi
  done

  return "$missing"
}

create_gpg_batch_file() {
  local output_file="${1:?output file path is required}"

  cat > "$output_file" <<EOF
Key-Type: EDDSA
Key-Curve: ed25519
Key-Usage: sign
Subkey-Type: ECDH
Subkey-Curve: Curve25519
Subkey-Usage: encrypt
Name-Real: $GIT_NAME
Name-Email: $GIT_EMAIL
Expire-Date: $GPG_EXPIRATION
%commit
EOF
}