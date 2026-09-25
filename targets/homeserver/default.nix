{ ... }:

{
  imports = [
    ../../modules/homenet.nix

    ./disko.nix
    ./network.nix
    ./maintenance.nix
    ./services/restic.nix
    ./services/vaultwarden.nix
    ./hardware-configuration.nix
    ./services/changedetection.nix
  ];

  networking.hostName = "homeserver";
  time.timeZone = "Europe/Paris";
  system.stateVersion = "26.05";

  homenet.domain = "home.internal";
  homenet.tunnelAddress = "10.100.0.1";

  sops.defaultSopsFile = ../../secrets/homeserver.yaml;

  # not empty by default. The default is [ /etc/ssh/ssh_host_rsa_key ].
  # activation would derive a PGP key from the RSA host key, for nothing.
  # this repository's secrets have age recipients only.
  sops.gnupg.sshKeyPaths = [ ];

  # enableRedistributableFirmware would pull every redistributable blob.
  # for hardware this machine does not have.
  hardware.cpu.amd.updateMicrocode = true;
}
