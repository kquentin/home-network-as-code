{ config, lib, ... }:

{
  nixpkgs.config.allowUnfreePredicate =
    package: builtins.elem (lib.getName package) [ "changedetection-io" ];

  services.changedetection-io = {
    enable = true;

    listenAddress = "127.0.0.1";
    port = 5000;
    behindProxy = true;
    baseURL = config.homenet.publish.changedetection.url;

    # both fetchers pull Chromium.
    # set them on false saves RAM, at the cost of JS-rendered pages.
    webDriverSupport = false;
    playwrightSupport = false;
  };

  homenet.publish.changedetection = {
    localPort = config.services.changedetection-io.port;
  };

  homenet.backup.paths = [ "/var/lib/changedetection-io" ];
}
