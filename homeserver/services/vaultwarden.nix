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
      DOMAIN = "https://homeserver.tail289b49.ts.net:8443";

      ROCKET_ADDRESS = "127.0.0.1";
      ROCKET_PORT = 8222;

      # The account exists. Nobody needs to create another.
      SIGNUPS_ALLOWED = false;
    };
  };

  homenet.serve.vaultwarden = {
    https = 8443;
    to = config.services.vaultwarden.config.ROCKET_PORT;
  };

  homenet.backup.paths = [ config.services.vaultwarden.backupDir ];
  homenet.backup.triggeredBy = [ "backup-vaultwarden" ];

  environment.systemPackages = [ pkgs.sqlite ];
}
