# NixOS installer, booted over the network into RAM. 
# Its only job is to be SSH-reachable so nixos-anywhere can take over

{ modulesPath, ... }:

{
  imports = [
    "${modulesPath}/installer/netboot/netboot.nix"
    "${modulesPath}/profiles/minimal.nix"
  ];

  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "prohibit-password";
  };

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPkjDD9+nKBBoYhZrZPmAq1hKB9G5JMvxdiVedXZGylS kollaros.quentin@mailfence.com"
  ];

  system.stateVersion = "26.05";
}
