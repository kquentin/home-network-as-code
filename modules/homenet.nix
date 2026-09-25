{ config, lib, ... }:

let
  domain = config.homenet.domain;
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

  options.homenet.domain = lib.mkOption {
    type = lib.types.str;
    description = ''
      The domain services are named under, the only one the house's certificate authority can sign.
    '';
  };

  options.homenet.tunnelAddress = lib.mkOption {
    type = lib.types.str;
    description = ''
      The server's address inside the WireGuard tunnel, the only one services answer on.
    '';
  };

  options.homenet.publish = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule (
        { name, config, ... }: {
          options = {
            localPort = lib.mkOption {
              type = lib.types.port;
              description = "Port the service itself listens on, in the clear, on 127.0.0.1.";
            };

            hostName = lib.mkOption {
              type = lib.types.str;
              default = "${name}.${domain}";
              description = "The name the service answers to, inside the tunnel.";
            };

            url = lib.mkOption {
              type = lib.types.str;
              default = "https://${config.hostName}";
              description = "The address clients use, for services that need to state their own.";
            };
          };
        }
      )
    );
    default = { };
    description = ''
      Services published inside the tunnel.
    '';
  };

  config = lib.mkIf (config.homenet.publish != { }) {
    sops.secrets.tls-key = {
      owner = config.services.nginx.user;
      restartUnits = [ "nginx.service" ];
    };

    services.nginx = {
      enable = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;

      virtualHosts = lib.mapAttrs' (
        _: service:
        lib.nameValuePair service.hostName {
          listenAddresses = [ config.homenet.tunnelAddress ];
          onlySSL = true;
          sslCertificate = ../keys/services.crt;
          sslCertificateKey = config.sops.secrets.tls-key.path;
          locations."/" = {
            proxyPass = "http://127.0.0.1:${toString service.localPort}";
            proxyWebsockets = true;
            # ntfy streams its messages: buffered, they would wait in nginx.
            extraConfig = "proxy_buffering off;";
          };
        }
      ) config.homenet.publish;
    };

    # nginx cannot bind the tunnel address before the tunnel exists.
    systemd.services.nginx = {
      wants = [ "wireguard-wg0.service" ];
      after = [ "wireguard-wg0.service" ];
    };
  };
}
