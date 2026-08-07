{ pkgs, ... }:

{
  imports = [
    ./disko.nix
    ./hardware-configuration.nix
  ];

  # The machine rebuilds itself from this flake, so it must be able to read one.
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # Hardware comes from hardware-configuration.nix, generated on the machine.
  # No linux-firmware either: 770 MB of the 15 GB disk.
  # Microcode is the part worth keeping, since it carries the Spectre-class mitigations.
  hardware.cpu.amd.updateMicrocode = true;

  boot.loader.grub = {
    enable = true;
    devices = [ "/dev/sda" ];
    configurationLimit = 5;
  };
  boot.tmp.cleanOnBoot = true;

  time.timeZone = "Europe/Paris";
  system.stateVersion = "26.05";

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };
  nix.optimise.automatic = true;

  documentation.nixos.enable = false;
  documentation.doc.enable = false;

  zramSwap.enable = true;

  services.journald.extraConfig = "SystemMaxUse=200M";

  networking.hostName = "homeserver";
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 ];
    trustedInterfaces = [ "tailscale0" ];
  };

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "prohibit-password";
    };
  };

  users.users.root.openssh.authorizedKeys.keyFiles = [ ../keys/admin.pub ];

  environment.systemPackages = with pkgs; [
    restic
    sqlite
  ];

  services.tailscale = {
    enable = true;
    openFirewall = true;
    # Enables net.ipv4.ip_forward without it packets for the lab are dropped.
    # --accept-dns=false keeps the router's resolver, adblock and DoH included.
    useRoutingFeatures = "server";
    extraSetFlags = [
      "--advertise-routes=10.10.10.0/24,10.10.30.0/24"
      "--accept-dns=false"
    ];
  };

  services.vaultwarden = {
    enable = true;

    backupDir = "/var/backup/vaultwarden";

    environmentFile = "/var/lib/secrets/vaultwarden.env";

    config = {
      DOMAIN = "https://homeserver.tail289b49.ts.net";

      ROCKET_ADDRESS = "127.0.0.1";
      ROCKET_PORT = 8222;

      # The account exists. Nobody on the tailnet needs to create another.
      SIGNUPS_ALLOWED = false;
    };
  };

  services.restic.backups.vaultwarden = {
    initialize = true;

    passwordFile = "/var/lib/secrets/restic-password";
    environmentFile = "/var/lib/secrets/restic-s3.env";

    paths = [ "/var/backup/vaultwarden" ];

    timerConfig = null;

    pruneOpts = [
      "--keep-daily 7"
      "--keep-weekly 5"
      "--keep-monthly 12"
    ];

    checkOpts = [ "--read-data-subset=10%" ];
  };

  systemd.services.backup-vaultwarden.onSuccess = [ "restic-backups-vaultwarden.service" ];

  system.autoUpgrade = {
    enable = true;
    flake = "github:kquentin/homelab#homeserver";
    allowReboot = true;
    rebootWindow = {
      lower = "04:00";
      upper = "07:00";
    };
    runGarbageCollection = true;
  };

}
