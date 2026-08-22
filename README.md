# home network as code

The house's network described in this repository: an always-on NixOS server, and
a Kubernetes lab on Debian.

An OpenWrt router, `outpost`, cuts the house into VLANs and serves the netboot.

| | Runs | |
|---|---|---|
| [`targets/homeserver/`](targets/homeserver/) | NixOS | Vaultwarden, changedetection-io |
| [`targets/lab/`](targets/lab/) | Debian + Kubernetes | not yet built |
| [`provisioning/`](provisioning/) | — | how a bare machine becomes one of those |

Every machine is an HP t620 thin client. `main` (10.10.10.0/24) holds the
workstations and the server, `lab` (10.10.30.0/24) the cluster nodes.

Remote access enters through Tailscale on the server.

## The server

Nothing listens on the LAN but SSH.

Services bind to `127.0.0.1` and are published on the tailnet by `tailscale serve`, which terminates TLS on the machine's tailnet name :

- Vaultwarden on `:8443`
- changedetection-io on `:8444`.

Adding one is a single file under [`targets/homeserver/services/`](targets/homeserver/services/). It declares the service, the port it answers on, and what of it is worth keeping, which restic ships to Backblaze B2.

Secrets are committed encrypted with [sops](https://github.com/getsops/sops).

## Usage

```sh
nixos-rebuild switch --flake github:kquentin/home-network-as-code#homeserver --refresh
```

`--refresh` because Nix caches the resolved revision for an hour, and would otherwise rebuild the commit you just replaced. `system.autoUpgrade` runs the same command nightly, rebooting between 04:00 and 07:00 if the kernel moved.

Installing a machine that has nothing on it yet is a different procedure:
[`provisioning/`](provisioning/).
