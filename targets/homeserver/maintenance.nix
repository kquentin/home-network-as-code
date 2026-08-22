{ ... }:

{
  boot.tmp.cleanOnBoot = true;

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
}
