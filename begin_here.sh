#!/usr/bin/env bash
set -euo pipefail

##   This section is for automatic execute rights on setup files in scripts folder
# chmod +x scripts/host/generate_ssh_keys.sh
# chmod +x scripts/host/cleanup_ssh_keys.sh
# echo "Scripts are now executable."

apt-get update
apt-get dist-upgrade -y
apt-get install -y ca-certificates apt-transport-https curl gnupg2 lsb-release git wget build-essential libssl-dev