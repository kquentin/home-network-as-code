# homelab

A home network segmented into VLANs on an OpenWrt router, with a NixOS server and a Kubernetes lab behind it. 
Every machine is described here and rebuilds itself from this repository.

## Network

| VLAN | Subnet | Holds |
|---|---|---|
| `main` | 10.10.10.0/24 | workstations, homeserver |
| `lab` | 10.10.30.0/24 | the Kubernetes nodes |

`main` reaches `lab`, never the reverse. 
Remote access goes through Tailscale on the homeserver, which advertises both internal subnets.

## Layout

| | |
|---|---|
| `homeserver/` | the always-on server |
| `lab/` | the Kubernetes cluster |
| `netboot/` | a NixOS installer served over the network, to provision a bare machine |
| `keys/` | the SSH public keys admitted on every host |

## Secrets

The credentials live on the machine and have to exist before the services that read them start:

| File | Read by | Holds |
|---|---|---|
| `/var/lib/secrets/vaultwarden.env` | `services.vaultwarden.environmentFile` | `ADMIN_TOKEN`, and any other setting not fit for the store |
| `/var/lib/secrets/restic-password` | `services.restic.backups.vaultwarden.passwordFile` | the passphrase the repository was initialised with |
| `/var/lib/secrets/restic-s3.env` | `services.restic.backups.vaultwarden.environmentFile` | `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` for Backblaze B2 |

All three are `0600 root:root`.
Keep `restic-password` somewhere else too: restic cannot recover a repository without it, so losing it loses every backup.

The tailnet node authenticates from `/var/lib/tailscale/tailscaled.state`, written once by `tailscale up` and carried across reboots.
A reinstall needs a new authentication, not a copy.

## Deploying

Hosts are addressed by flake output:

```sh
nixos-rebuild switch --flake github:kquentin/homelab#homeserver --refresh
```

`--refresh` because Nix caches the resolved revision for an hour, and would otherwise rebuild the commit you just replaced.

`system.autoUpgrade` runs the same thing nightly, and passes `--refresh` on its own.
