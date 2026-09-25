{ config, pkgs, ... }:

{
  sops.secrets.vaultwarden-admin-token = { };

  sops.templates.vaultwarden-env.content = ''
    ADMIN_TOKEN=${config.sops.placeholder.vaultwarden-admin-token}
  '';

  services.vaultwarden = {
    enable = true;

    backupDir = "/var/backup/vaultwarden";

    environmentFile = config.sops.templates.vaultwarden-env.path;

    config = {
      DOMAIN = config.homenet.publish.vaultwarden.url;

      ROCKET_ADDRESS = "127.0.0.1";
      ROCKET_PORT = 8222;

      # the account already exists, nobody needs another.
      SIGNUPS_ALLOWED = false;
    };
  };

  homenet.publish.vaultwarden = {
    localPort = config.services.vaultwarden.config.ROCKET_PORT;
  };

  homenet.backup.paths = [ config.services.vaultwarden.backupDir ];
  homenet.backup.triggeredBy = [ "backup-vaultwarden" ];

  environment.systemPackages = [ pkgs.sqlite ];
}
