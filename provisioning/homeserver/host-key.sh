#!/usr/bin/env bash
# give a machine its identity and print the age recipient.

set -euo pipefail

host=${1}
destination=${HOME}/homenet-keys/${host}/etc/ssh

mkdir -p "${destination}"
ssh-keygen -q -t ed25519 -N "" -C "${host}" -f "${destination}/ssh_host_ed25519_key"

nix shell nixpkgs#ssh-to-age -c ssh-to-age -i "${destination}/ssh_host_ed25519_key.pub"
