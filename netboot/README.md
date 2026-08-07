# netboot

Provisioning a bare machine over the network. 
The router hands out an iPXE binary, which fetches a NixOS installer held entirely in RAM.
`nixos-anywhere` then takes over and installs the real system.

Build the artefacts and stage them on the router:

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

The bootloader goes over TFTP but the 440 MB initrd cannot, so the router serves it over HTTP from a tmpfs.
It exists only for the duration of an install. `-O` because dropbear ships no SFTP server.

`boot.ipxe` is baked into the binary. 
A stock iPXE would ask DHCP for a boot file again and be handed itself, forever.

Then, once the machine has booted the installer:

```sh
nix run github:nix-community/nixos-anywhere -- --flake .#homeserver --extra-files ~/homeserver-secrets root@10.10.10.10
```

`--extra-files` carries the secrets from a directory kept outside this repository.
