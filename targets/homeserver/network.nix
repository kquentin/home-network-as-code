{ config, ... }:

let
  tunnelAddress = config.homenet.tunnelAddress;
in
{
  # services answer only inside the tunnel.
  # the LAN sees SSH and WireGuard, nothing else.
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 ];
    allowedUDPPorts = [ config.networking.wireguard.interfaces.wg0.listenPort ];
    trustedInterfaces = [ "wg0" ];
  };

  sops.secrets.wireguard-private-key = { };

  networking.wireguard.interfaces.wg0 = {
    ips = [ "${tunnelAddress}/24" ];
    listenPort = 51820;
    privateKeyFile = config.sops.secrets.wireguard-private-key.path;

    peers = [
      {
        name = "user-1-phone-1";
        publicKey = "AjHgcbyi3SPEEERNNo2bYw+/j3YdpCU+f9bJIs4L7zA=";
        allowedIPs = [ "10.100.0.2/32" ];
      }
      {
        name = "user-1-laptop-1";
        publicKey = "bEOHO2RzEFGb1NgludkPND5cZ+4fVXwJ9hYr+a/DmgM=";
        allowedIPs = [ "10.100.0.4/32" ];
      }
    ];
  };

  services.dnsmasq = {
    enable = true;
    # the server keeps resolving through the router, not through itself.
    resolveLocalQueries = false;
    settings = {
      listen-address = tunnelAddress;
      bind-interfaces = true;
      address = "/${config.homenet.domain}/${tunnelAddress}";
      # the router answers the rest, adblock and DoH included.
      server = [ "10.10.10.1" ];
      no-resolv = true;
    };
  };

  # the tunnel address exists only once the tunnel is up.
  systemd.services.dnsmasq = {
    wants = [ "wireguard-wg0.service" ];
    after = [ "wireguard-wg0.service" ];
  };
}
