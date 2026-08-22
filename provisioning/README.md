# provisioning

How a machine with nothing on it becomes one of the hosts ?

The router hands out an iPXE binary over TFTP. `boot.ipxe`, baked into it, chains to an installer over HTTP. That installer only makes the machine reachable over SSH, what turns it into a host comes after: `nixos-anywhere` for the homeserver, Ansible for the lab.

| | |
|---|---|
| `boot.ipxe` | what the iPXE binary runs, for machines on either VLAN |
| `homeserver/` | the NixOS installer image |
| `lab/` | the Debian installer, not written yet |

The VLAN decides the OS: `boot.ipxe` matches the gateway the DHCP handed out against each VLAN's, and chains to that VLAN's installer. Nothing to choose at boot, no list of MAC addresses to keep, and a gateway it does not know drops to the iPXE shell rather than guessing.

## The host key comes first

A machine cannot be given secrets it has no key to read, and its key does not exist until it is installed.

So it is made beforehand and carried in:

```sh
./provisioning/homeserver/host-key.sh homeserver
```

That writes an `--extra-files` tree under `~/homenet-keys/<machine>`, mirroring
the target root, and prints the age recipient to add to `.sops.yaml`. The keys
live outside this repository on purpose: a `.gitignore` does not stop `git add
-f`, and Nix copies a flake's whole directory into the world-readable store when
it is evaluated outside git. The one key is
sshd's identity and, once converted, what decrypts `secrets/homeserver.yaml` at
every boot.

## NixOS

Build the artefacts and stage them on the router:

```sh
build=.#nixosConfigurations.netboot.config.system.build

nix build "${build}.kernel" -o result-kernel
nix build "${build}.netbootRamdisk" -o result-initrd
nix build "${build}.netbootIpxeScript" -o result-script
nix build .#ipxe -o result-ipxe

scp -O result-ipxe/snp.efi root@outpost:/srv/tftp/ipxe-nixos-snp.efi
scp -O result-ipxe/undionly.kpxe root@outpost:/srv/tftp/ipxe-nixos.kpxe
scp -O result-kernel/bzImage result-initrd/initrd result-script/netboot.ipxe root@outpost:/tmp/netboot/
```

`scp -O` because dropbear on the router ships no SFTP server. The bootloader goes
over TFTP but the 440 MB initrd cannot, so the router serves that over HTTP from
a tmpfs, for the duration of the install only.

Then, once the machine has booted the installer:

```sh
nix run github:nix-community/nixos-anywhere -- \
  --flake .#homeserver --extra-files ~/homenet-keys/homeserver root@10.10.10.10
```

## Debian

Nothing serves it yet.
