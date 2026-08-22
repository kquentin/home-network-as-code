# From nixos-generate-config

{ lib, modulesPath, ... }:

{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "ahci"
    "ohci_pci"
    "ehci_pci"
    "usbhid"
    "sd_mod"
  ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
