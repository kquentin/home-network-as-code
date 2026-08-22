{ config, lib, pkgs, ... }:

{
  sops.secrets.restic-password = { };
  sops.secrets.restic-repository = { };
  sops.secrets.restic-b2-key-id = { };
  sops.secrets.restic-b2-key = { };

  # The repository URL is a secret like the rest: it names the bucket.
  sops.templates.restic-env.content = ''
    RESTIC_REPOSITORY=${config.sops.placeholder.restic-repository}
    AWS_ACCESS_KEY_ID=${config.sops.placeholder.restic-b2-key-id}
    AWS_SECRET_ACCESS_KEY=${config.sops.placeholder.restic-b2-key}
  '';

  services.restic.backups.homeserver = {
    initialize = true;

    passwordFile = config.sops.secrets.restic-password.path;
    environmentFile = config.sops.templates.restic-env.path;

    paths = config.homenet.backup.paths;

    timerConfig = null;

    # Retention covers every snapshot of this host at once. The default also
    # groups by path list, so adding a directory would start a second history.
    pruneOpts = [
      "--group-by host"
      "--keep-daily 7"
      "--keep-weekly 5"
      "--keep-monthly 12"
    ];

    checkOpts = [ "--read-data-subset=10%" ];
  };

  systemd.services = lib.genAttrs config.homenet.backup.triggeredBy (_: {
    onSuccess = [ "restic-backups-homeserver.service" ];
  });

  environment.systemPackages = [ pkgs.restic ];
}
