#!/usr/bin/env bash
# run on the workstation: give a device its WireGuard identity and print the public key to declare in network.nix.
# the device's configuration stays on the workstation, until it is imported on the device.

set -euo pipefail

name=${1}
address=${2}
endpoint=${3}
repository=$(git -C "$(dirname "${0}")" rev-parse --show-toplevel)
destination=${HOME}/homenet-keys/wireguard

mkdir -p "${destination}"
umask 077

private_key=$(nix shell nixpkgs#wireguard-tools -c wg genkey)
server_public_key=$(cat "${repository}/keys/wireguard.pub")

cat > "${destination}/${name}.conf" <<EOF
[Interface]
PrivateKey = ${private_key}
Address = ${address}/32
DNS = 10.100.0.1

[Peer]
PublicKey = ${server_public_key}
Endpoint = ${endpoint}
AllowedIPs = 10.100.0.0/24
EOF

printf '%s\n' "${private_key}" | nix shell nixpkgs#wireguard-tools -c wg pubkey
