{ config, ... }:

{
  services.ntfy-sh = {
    enable = true;
    settings = {
      base-url = config.homenet.publish.ntfy.url;
      listen-http = "127.0.0.1:${toString config.homenet.publish.ntfy.localPort}";
      behind-proxy = true;
    };
  };

  homenet.publish.ntfy.localPort = 2586;
}
