# provisioning

How a machine with nothing on it becomes one of the hosts ?

| | |
|---|---|
| [`boot.ipxe`](boot.ipxe) | what a machine booting from the network runs |
| [`homeserver/`](homeserver/) | the key it has to be given before it exists |
| [`lab/`](lab/) | the preseed the three lab machines install from |

`boot.ipxe` tells the VLANs apart.

Nothing to choose at boot, no list of MAC addresses to keep.

## The host key comes first

A machine cannot be given secrets it has no key to read, and its key does not exist until it is installed.

So it is made beforehand and carried in:

```sh
./provisioning/homeserver/host-key.sh homeserver
```

That writes an `--extra-files` tree under `~/homenet-keys/<machine>`, mirroring the target root, and prints the age recipient to add to `.sops.yaml`.

The keys live outside this repository on purpose: Nix copies a flake's whole directory into the world-readable store.

## The admin key

The same file, [`keys/admin.pub`](../keys/admin.pub), copied two different ways.

| | reads it | gets it from |
|---|---|---|
| NixOS | the installer, so `nixos-anywhere` can connect | GitHub, injected into the initramfs by `boot.ipxe` |
| Debian | the installed system, on the preseed's last line | the router, over HTTP |

## NixOS

```sh
nix run github:nix-community/nixos-anywhere -- \
  --flake .#homeserver --extra-files ~/homenet-keys/homeserver root@10.10.10.10
```

The same command whether the machine already runs Linux or not. `nixos-anywhere` uploads a kexec image over the SSH connection it has and jumps into it.

A bare machine has no SSH to jump from, so it boots from the network first: `F12`, and nothing to build or stage. `boot.ipxe` boots the generic installer and hands it [`keys/admin.pub`](../keys/admin.pub) as a second initrd, which iPXE assembles out of that one file.

## Debian

One preseed installs the three lab machines.

They have to be set to boot in legacy BIOS. The recipe lays down a single MBR partition, and no swap, which the kubelet refuses to start beside.

```sh
scp -O provisioning/lab/preseed.cfg keys/admin.pub root@outpost:/tmp/netboot/
```

Then, one machine at a time: `F12`. [`targets/lab/`](../targets/lab/) takes over.
