{
  description = "homelab";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { nixpkgs, disko, ... }:
    {
      nixosConfigurations.homeserver = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          disko.nixosModules.disko
          ./homeserver
        ];
      };

      # Installer booted over the network into RAM. 
      # Produces the kernel, the initrd and an iPXE script under config.system.build.
      nixosConfigurations.netboot = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [ ./netboot/netboot.nix ];
      };

      # Chains straight to the router's HTTP server. 
      # A stock iPXE would ask DHCP for a boot file again and be handed this very binary, forever.
      packages.x86_64-linux.ipxe =
        nixpkgs.legacyPackages.x86_64-linux.ipxe.override
          {
            embedScript = ./netboot/boot.ipxe;
          };
    };
}
