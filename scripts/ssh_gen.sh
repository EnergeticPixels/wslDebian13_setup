#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/gpg_batch.sh
source "$SCRIPT_DIR/lib/gpg_batch.sh"

load_repo_env
require_env_vars GIT_EMAIL

echo "Generating SSH keys for multiple providers"
mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

# generate github key
if [ ! -f "$HOME/.ssh/id_github" ]; then
  echo "Generating ED25519 SSH key for GitHub..."
  ssh-keygen -t ed25519 -C "$GIT_EMAIL" -f "$HOME/.ssh/id_github" -N ''
fi

# Follow github key generation method for additional keys here

# Optional: create a reusable GPG batch template from .env values.
if [[ "${GENERATE_GPG_BATCH_TEMPLATE:-false}" == "true" ]]; then
  gpg_template_file="$HOME/.ssh/gpg_batch"
  create_gpg_batch_file "$gpg_template_file"
  chmod 600 "$gpg_template_file"
  echo "Created GPG batch template at $gpg_template_file"
fi

# create SSH config file to route keys correctly
cat > "$HOME/.ssh/config" <<EOF
Host github.com
  HostName github.com
  User git
  IdentityFile $HOME/.ssh/id_github
  IdentitiesOnly yes
EOF
