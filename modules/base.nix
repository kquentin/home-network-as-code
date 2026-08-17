{ ... }:

{
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "prohibit-password";
    };
  };

  users.users.root.openssh.authorizedKeys.keyFiles = [ ../keys/admin.pub ];

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  documentation.nixos.enable = false;
  documentation.doc.enable = false;
}
