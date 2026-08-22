{ config, lib, ... }:

{
  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [ "changedetection-io" ];

  services.changedetection-io = {
    enable = true;

    listenAddress = "127.0.0.1";
    port = 5000;
    behindProxy = true;
    baseURL = "https://homeserver.tail289b49.ts.net:8444";

    # Both fetchers pull Chromium; off saves its RAM, at the cost of JS-rendered pages.
    webDriverSupport = false;
    playwrightSupport = false;
  };

  homenet.serve.changedetection = {
    https = 8444;
    to = config.services.changedetection-io.port;
  };

  homenet.backup.paths = [ "/var/lib/changedetection-io" ];
}
