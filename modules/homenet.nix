{ config, lib, ... }:

let
  cfg = config.homenet.serve;
  tailscale = "${config.services.tailscale.package}/bin/tailscale";
  publish = s: "${tailscale} serve --bg --https=${toString s.https} ${toString s.to}";
in
{
  options.homenet.backup.paths = lib.mkOption {
    type = lib.types.listOf lib.types.path;
    default = [ ];
    description = ''
      Directories worth keeping.
    '';
  };

  options.homenet.backup.triggeredBy = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [ ];
    description = ''
      Services whose success starts the backup.
    '';
  };

  options.homenet.serve = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule {
        options = {
          https = lib.mkOption {
            type = lib.types.port;
            description = "Port on the tailnet name, HTTPS.";
          };
          to = lib.mkOption {
            type = lib.types.port;
            description = "Port the service listens on, in the clear, on 127.0.0.1.";
          };
        };
      }
    );
    default = { };
    description = ''
      Services published on the tailnet.
    '';
  };

  config = lib.mkIf (cfg != { }) {
    # `tailscale serve` writes to the daemon's state, it is not declarative.
    systemd.services.tailscale-serve = {
      wantedBy = [ "multi-user.target" ];
      wants = [ "tailscaled.service" ];
      after = [
        "tailscaled.service"
        "tailscaled-set.service"
      ];

      serviceConfig.Type = "oneshot";

      script = ''
        ${tailscale} serve reset
        ${lib.concatLines (map publish (lib.attrValues cfg))}
      '';
    };
  };
}
