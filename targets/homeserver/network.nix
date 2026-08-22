{ ... }:

{
  # Services bind to 127.0.0.1 and are reached through homenet.publish.
  # None of them needs a port on the LAN.
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 ];
    trustedInterfaces = [ "tailscale0" ];
  };

  services.tailscale = {
    enable = true;
    # openFirewall open UDP 41641 with SSH, the only port on the LAN.
    openFirewall = true;
    useRoutingFeatures = "server";
    extraSetFlags = [
      # Enables net.ipv4.ip_forward, without it packets for the lab are dropped.
      "--advertise-routes=10.10.10.0/24,10.10.30.0/24"
      # --accept-dns=false keeps the router's resolver, adblock and DoH included.
      "--accept-dns=false"
    ];
  };
}
