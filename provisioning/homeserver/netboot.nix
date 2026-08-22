{ modulesPath, ... }:

{
  imports = [
    "${modulesPath}/profiles/minimal.nix"
    "${modulesPath}/installer/netboot/netboot.nix"
  ];

  system.stateVersion = "26.05";
}
