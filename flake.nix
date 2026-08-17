{
  description = "Home network as code: OpenWrt router, NixOS server, Kubernetes lab";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { nixpkgs, disko, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};

      # Only the NixOS machines. The router runs OpenWrt, the lab nodes Debian.
      host =
        modules:
        nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [ ./modules/base.nix ] ++ modules;
        };
    in
    {
      nixosConfigurations = {
        homeserver = host [
          disko.nixosModules.disko

          ./homeserver
        ];

        netboot = host [ ./provisioning/nixos ];
      };

      # A stock iPXE would ask DHCP for a boot file again and be handed this very
      # binary, forever. The embedded script is what breaks the loop.
      packages.${system}.ipxe = pkgs.ipxe.override { embedScript = ./provisioning/boot.ipxe; };

      formatter.${system} = pkgs.nixfmt;
    };
}
