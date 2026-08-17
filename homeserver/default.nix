{ ... }:

{
  imports = [
    ../modules/homenet.nix

    ./disko.nix
    ./services/restic.nix
    ./services/vaultwarden.nix
    ./hardware-configuration.nix
    ./services/changedetection.nix
  ];

  networking.hostName = "homeserver";
  time.timeZone = "Europe/Paris";
  system.stateVersion = "26.05";

  # Decrypted at activation with an age key derived from the host's SSH key, into
  # /run/secrets. Nothing here is placed by hand, and nothing survives a reboot.
  sops.defaultSopsFile = ../secrets/homeserver.yaml;

  # age only. Left alone, activation would also derive a GnuPG key from the RSA
  # host key and import it, for nothing.
  sops.gnupg.sshKeyPaths = [ ];

  # Enabled on its own rather than through enableRedistributableFirmware
  hardware.cpu.amd.updateMicrocode = true;

  boot.loader.grub = {
    enable = true;
    devices = [ "/dev/sda" ];
    configurationLimit = 5;
  };
  boot.tmp.cleanOnBoot = true;

  zramSwap.enable = true;

  services.journald.extraConfig = "SystemMaxUse=200M";

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };
  nix.optimise.automatic = true;

  system.autoUpgrade = {
    enable = true;
    flake = "github:kquentin/home-network-as-code#homeserver";
    allowReboot = true;
    rebootWindow = {
      lower = "04:00";
      upper = "07:00";
    };
    runGarbageCollection = true;
  };

  # Services bind to 127.0.0.1 and are reached through homenet.serve.
  # Nothing but SSH needs a port open on the LAN.
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 ];
    trustedInterfaces = [ "tailscale0" ];
  };

  services.tailscale = {
    enable = true;
    openFirewall = true;
    # Enables net.ipv4.ip_forward, without it packets for the lab are dropped.
    # --accept-dns=false keeps the router's resolver, adblock and DoH included.
    useRoutingFeatures = "server";
    extraSetFlags = [
      "--advertise-routes=10.10.10.0/24,10.10.30.0/24"
      "--accept-dns=false"
    ];
  };
}
