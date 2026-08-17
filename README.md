# home network as code

An always-on NixOS server and a Kubernetes lab on Debian, described in this
repository. An OpenWrt router, `outpost`, cuts the house into VLANs and serves
the netboot.

| VLAN | Subnet | Holds |
|---|---|---|
| `main` | 10.10.10.0/24 | workstations, `homeserver` |
| `lab` | 10.10.30.0/24 | the Kubernetes nodes |

`main` reaches `lab`, never the reverse. Remote access enters through Tailscale
on `homeserver`, which advertises both subnets.

| | Runs | Built from |
|---|---|---|
| [`homeserver/`](homeserver/) | NixOS 26.05 | this flake, rebuilt nightly by the machine itself |
| [`lab/`](lab/) | Debian + Kubernetes | not yet built |
| [`provisioning/`](provisioning/) | — | how a bare machine becomes one of the above |

The server is an HP t620 thin client, and so is every node of the cluster.

## Layout

| | |
|---|---|
| `flake.nix` | the NixOS machines, and the iPXE binary |
| `homeserver/`, `lab/` | one directory per machine |
| `provisioning/` | netboot, and the installers it hands out |
| `modules/` | what the NixOS machines share |
| `keys/` | the SSH public keys admitted on every host |

## What the server runs

Nothing listens on the LAN but SSH. Services bind to `127.0.0.1` and are
published on the tailnet by `tailscale serve`, which terminates TLS on the
machine's tailnet name.

| Service | Tailnet port | Kept |
|---|---|---|
| Vaultwarden | `:8443` | nightly sqlite dump, to Backblaze B2 via restic |
| changedetection-io | `:8444` | its state directory, in the same repository |

Adding a service is one file under [`homeserver/services/`](homeserver/services/):
it declares the service, the port it is published on (`homenet.serve`) and what
of it is worth keeping (`homenet.backup.paths`). Nothing central to edit.

## Secrets

Nothing secret is in this repository. Three files are placed on the server
before first boot — `nixos-anywhere --extra-files` carries them in — and the
services that read them will not start without:

| File | Read by | Holds |
|---|---|---|
| `/var/lib/secrets/vaultwarden.env` | `services.vaultwarden.environmentFile` | `ADMIN_TOKEN`, and any other setting not fit for the store |
| `/var/lib/secrets/restic-password` | `services.restic.backups.homeserver.passwordFile` | the passphrase the repository was initialised with |
| `/var/lib/secrets/restic-s3.env` | `services.restic.backups.homeserver.environmentFile` | `RESTIC_REPOSITORY`, plus `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` for Backblaze B2 |

All three are `0600 root:root`. Keep `restic-password` somewhere else too:
restic cannot recover a repository without it, so losing it loses every backup.

The tailnet node authenticates from `/var/lib/tailscale/tailscaled.state`,
written once by `tailscale up` and carried across reboots. A reinstall needs a
new authentication, not a copy.

## Deploying

Hosts are addressed by flake output:

```sh
nixos-rebuild switch --flake github:kquentin/home-network-as-code#homeserver --refresh
```

`--refresh` because Nix caches the resolved revision for an hour, and would
otherwise rebuild the commit you just replaced.

`system.autoUpgrade` runs the same thing nightly and passes `--refresh` on its
own, rebooting between 04:00 and 07:00 if the kernel moved.

Provisioning a machine that has nothing on it yet is a different procedure:
[`provisioning/README.md`](provisioning/README.md).
