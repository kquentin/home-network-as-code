# provisioning

How a machine with nothing on it becomes one of the hosts. The router hands out
an iPXE binary over TFTP; `boot.ipxe`, baked into that binary, decides what to
chain to next.

The intent is that the VLAN decides the OS. A machine plugged into `lab`
becomes a Debian node, one plugged into `main` gets the NixOS installer, so
there is nothing to choose at boot and no list of MAC addresses to maintain.

In both cases the installer only makes the machine reachable over SSH. What
turns it into a host comes after: `nixos-anywhere` for the server, Ansible for
the lab nodes.

## The host key comes first

A machine cannot be given secrets it has no key to read, and its key does not
exist until it is installed. So the key is made beforehand and carried in:

```sh
./host-key.sh homeserver
```

It writes `~/homeserver-secrets/etc/ssh/ssh_host_ed25519_key` — an `--extra-files`
tree mirroring the target root — and prints the age recipient to put in
`.sops.yaml`. That one key is the whole chain: sshd's identity, and, converted,
what decrypts `secrets/homeserver.yaml` at every boot.

## NixOS

Build the artefacts and stage them on the router. From the root of the
repository, since every command below addresses this flake:

```sh
B=.#nixosConfigurations.netboot.config.system.build

nix build $B.kernel -o result-kernel
nix build $B.netbootRamdisk -o result-initrd
nix build $B.netbootIpxeScript -o result-script
nix build .#ipxe -o result-ipxe

scp -O result-ipxe/snp.efi root@outpost:/srv/tftp/ipxe-nixos-snp.efi
scp -O result-ipxe/undionly.kpxe root@outpost:/srv/tftp/ipxe-nixos.kpxe
scp -O result-kernel/bzImage result-initrd/initrd result-script/netboot.ipxe root@outpost:/tmp/netboot/
```

The bootloader goes over TFTP but the 440 MB initrd cannot, so the router serves
it over HTTP from a tmpfs. It exists only for the duration of an install.

Then, once the machine has booted the installer:

```sh
nix run github:nix-community/nixos-anywhere -- --flake .#homeserver --extra-files ~/homeserver-secrets root@10.10.10.10
```

`--extra-files` carries the secrets from a directory kept outside this
repository.

## Debian

Not in place yet.
