{ config, lib, pkgs, ... }:

{
  services.restic.backups.homeserver = {
    initialize = true;

    passwordFile = "/var/lib/secrets/restic-password";

    # Also carries RESTIC_REPOSITORY, so the bucket name never reaches the store.
    environmentFile = "/var/lib/secrets/restic-s3.env";

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
