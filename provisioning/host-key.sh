#!/usr/bin/env bash
# Give a machine its identity before it exists.
# Then print the age recipient it converts to.

set -euo pipefail

host=${1}
destination=${HOME}/${host}-secrets/etc/ssh

mkdir -p "${destination}"
ssh-keygen -q -t ed25519 -N "" -C "${host}" -f "${destination}/ssh_host_ed25519_key"

nix shell nixpkgs#ssh-to-age -c ssh-to-age -i "${destination}/ssh_host_ed25519_key.pub"
