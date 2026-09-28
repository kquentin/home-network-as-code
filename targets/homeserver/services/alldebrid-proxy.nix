{ config, pkgs, ... }:

let
  proxyAddress = "10.100.1.1";
  vpsAddress = "10.100.1.2";
  proxyPort = 8888;
in
{
  # alldebrid blocks the VPS's address: the VPS reaches its API through the house line.
  # a separate interface keeps the VPS out of the trusted wg0, it reaches the proxy alone.
  networking.wireguard.interfaces.wg1 = {
    ips = [ "${proxyAddress}/30" ];
    privateKeyFile = config.sops.secrets.wireguard-private-key.path;

    peers = [
      {
        name = "vps-1";
        publicKey = "2qziRjooxFHSw7xsB52ZceMMQfQIkFm7dOpwLUukLRY=";
        allowedIPs = [ "${vpsAddress}/32" ];
        # the server dials out, so nothing is forwarded at home.
        endpoint = "178.105.198.229:51820";
        persistentKeepalive = 25;
      }
    ];
  };

  networking.firewall.interfaces.wg1.allowedTCPPorts = [ proxyPort ];

  services.tinyproxy = {
    enable = true;
    settings = {
      Listen = proxyAddress;
      Port = proxyPort;
      Allow = vpsAddress;
      ConnectPort = 443;
      FilterDefaultDeny = true;
      # stremthru refuses to start unless it can read the proxy's public address from an IP checker.
      Filter = pkgs.writeText "alldebrid-domains" ''
        ^api\.alldebrid\.com$
        ^api\.ipify\.org$
      '';
    };
  };

  # the proxy cannot bind its address before the tunnel exists.
  systemd.services.tinyproxy = {
    wants = [ "wireguard-wg1.service" ];
    after = [ "wireguard-wg1.service" ];
  };
}
