{ config, lib, ... }:

let
  tailscale = "${config.services.tailscale.package}/bin/tailscale";
  tailnetHostName = "${config.networking.hostName}.${config.homenet.tailnetDomain}";
  publish =
    service:
    "${tailscale} serve --bg --https=${toString service.tailnetPort} ${toString service.localPort}";
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

  options.homenet.tailnetDomain = lib.mkOption {
    type = lib.types.str;
    description = ''
      The tailnet's DNS domain.
    '';
  };

  options.homenet.publish = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule (service: {
        options = {
          tailnetPort = lib.mkOption {
            type = lib.types.port;
            description = "Port the service answers on, under HTTPS, on the tailnet.";
          };

          localPort = lib.mkOption {
            type = lib.types.port;
            description = "Port the service itself listens on, in the clear, on 127.0.0.1.";
          };

          url = lib.mkOption {
            type = lib.types.str;
            default = "https://${tailnetHostName}:${toString service.config.tailnetPort}";
            description = "The address clients use, for services that need to state their own.";
          };
        };
      })
    );
    default = { };
    description = ''
      Services published on the tailnet.
    '';
  };

  config = lib.mkIf (config.homenet.publish != { }) {
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
        ${lib.concatLines (map publish (lib.attrValues config.homenet.publish))}
      '';
    };
  };
}
