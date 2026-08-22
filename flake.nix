{
  description = "Home network as code";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { nixpkgs, disko, sops-nix, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};

      host =
        modules:
        nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [ ./modules/base.nix ] ++ modules;
        };
    in
    {
      # The server and its installer, and nothing else.
      # The router runs OpenWrt, the lab nodes Debian.
      nixosConfigurations = {
        homeserver = host [
          disko.nixosModules.disko
          sops-nix.nixosModules.sops
          ./homeserver
        ];

        netboot = host [ ./provisioning/homeserver/netboot.nix ];
      };

      # Handed to every machine that boots from the network.
      # A stock iPXE would ask DHCP for a boot file again. The embedded script breaks the loop.
      packages.${system}.ipxe = pkgs.ipxe.override { embedScript = ./provisioning/boot.ipxe; };

      formatter.${system} = pkgs.nixfmt;
    };
}
