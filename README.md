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

## Deploying

Hosts are addressed by flake output:

```sh
nixos-rebuild switch --flake github:kquentin/homelab#homeserver
```

`system.autoUpgrade` runs the same thing nightly.
