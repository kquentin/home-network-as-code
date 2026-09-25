# home network as code

The home network runs an always-on NixOS server and a Kubernetes lab on Debian, both behind an OpenWrt router, `outpost`, which segments the house into VLANs and serves netboot.

| | Runs | |
|---|---|---|
| [`targets/homeserver/`](targets/homeserver/) | NixOS | Vaultwarden, changedetection-io |
| [`targets/lab/`](targets/lab/) | Debian + Kubernetes | a kubeadm cluster, configured with Ansible |
| [`provisioning/`](provisioning/) | - | how a bare machine becomes one of those |

Every machine except the `outpost` is an HP T620 thin client. `main` (10.10.10.0/24) holds the workstations and the server, `lab` (10.10.30.0/24) the cluster nodes. Remote access enters through WireGuard on the server, and leads to the server alone.

## The server

Nothing listens on the LAN but SSH and WireGuard.

Services bind to `127.0.0.1` and are published inside the tunnel by nginx, with a certificate signed by the house's own authority:

- Vaultwarden on `vaultwarden.home.internal`
- changedetection-io on `changedetection.home.internal`

A device reaches them once it is a WireGuard peer and trusts [`keys/certificate-authority.crt`](keys/certificate-authority.crt): [`provisioning/`](provisioning/).

Adding one is a single file under [`targets/homeserver/services/`](targets/homeserver/services/). It declares the service, the port it answers on, and what of it is worth keeping, which restic ships to Backblaze B2.

Secrets are committed encrypted with [sops](https://github.com/getsops/sops).

## Usage

```sh
nixos-rebuild switch --flake github:kquentin/home-network-as-code#homeserver --refresh
```

`--refresh` because Nix caches the resolved revision for an hour, and would otherwise rebuild the commit you just replaced. `system.autoUpgrade` runs the same command nightly, rebooting between 04:00 and 07:00 if the kernel moved.

Installing a machine that has nothing on it yet is a different procedure:
[`provisioning/`](provisioning/).
