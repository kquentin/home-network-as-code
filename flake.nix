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
    in
    {
      nixosConfigurations.homeserver = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          ./modules/base.nix
          disko.nixosModules.disko
          sops-nix.nixosModules.sops
          ./targets/homeserver
        ];
      };

      # handed to every machine that boots from the network.
      # only the BIOS binary: every machine here boots grub off an MBR disk.
      packages.${system}.ipxe = pkgs.ipxe.override {
        embedScript = ./provisioning/boot.ipxe;
        enableDefaultPlatformTargets = false;
        additionalTargets."bin/undionly.kpxe" = null;
        firmwareBinary = "undionly.kpxe";
      };

      formatter.${system} = pkgs.nixfmt;
    };
}
