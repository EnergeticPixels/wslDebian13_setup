#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/gpg_batch.sh
source "$SCRIPT_DIR/lib/gpg_batch.sh"

load_repo_env
require_env_vars GIT_EMAIL

target_user=""
target_home="$HOME"

if [[ "$(id -u)" -eq 0 ]]; then
  target_user="${SUDO_USER:-${USER:-}}"
  if [[ -n "$target_user" ]]; then
    target_home="$(getent passwd "$target_user" | cut -d: -f6 || true)"
  fi

  if [[ -z "$target_home" ]]; then
    target_home="$HOME"
  fi
fi

ssh_dir="$target_home/.ssh"
github_key_path="$ssh_dir/id_github"

echo "Generating SSH keys for multiple providers"
mkdir -p "$ssh_dir"
# If running as root, set ownership before changing permissions
if [[ "$(id -u)" -eq 0 && -n "$target_user" ]]; then
  chown "$target_user:$target_user" "$ssh_dir"
fi

chmod 700 "$ssh_dir"

# generate github key
if [ ! -f "$github_key_path" ]; then
  echo "Generating ED25519 SSH key for GitHub..."
  ssh-keygen -t ed25519 -C "$GIT_EMAIL" -f "$github_key_path"
fi

# Follow github key generation method for additional keys here

# Optional: create a reusable GPG batch template from .env values.
if [[ "${GENERATE_GPG_BATCH_TEMPLATE:-false}" == "true" ]]; then
  gpg_template_file="$ssh_dir/gpg_batch"
  create_gpg_batch_file "$gpg_template_file"
  chmod 600 "$gpg_template_file"
  echo "Created GPG batch template at $gpg_template_file"
fi

# create SSH config file to route keys correctly
cat > "$ssh_dir/config" <<EOF
Host linux_gh
  HostName github.com
  User git
  IdentityFile $github_key_path
  IdentitiesOnly yes
EOF

chmod 600 "$ssh_dir/config"

if [[ "$(id -u)" -eq 0 && -n "$target_user" ]]; then
  chown "$target_user:$target_user" "$ssh_dir" "$github_key_path" "$github_key_path.pub" "$ssh_dir/config" 2>/dev/null || true
fi

# Output the public key for GitHub
echo "-------------------------------------------------------"
echo "GITHUB SSH PUBLIC KEY (Paste into GitHub Settings):"
echo "-------------------------------------------------------"
if [[ -f "$github_key_path.pub" ]]; then
  cat "$github_key_path.pub"
else
  echo "Error: SSH public key not found at $github_key_path.pub" >&2
fi
echo "-------------------------------------------------------"
