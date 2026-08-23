# no swap partition on a 16GB disk, it would cost ~12% of it.
# zramSwap, below, stands in for it.

{ config, ... }:

{
  disko.devices.disk.main = {
    type = "disk";
    device = "/dev/sda";

    content = {
      type = "table";
      format = "msdos";
      partitions = [
        {
          name = "root";
          # the 1 MiB left free is where grub-install embeds core.img on an MBR disk.
          start = "1MiB";
          end = "100%";
          bootable = true;
          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/";
          };
        }
      ];
    };
  };

  boot.loader.grub = {
    enable = true;
    devices = [ config.disko.devices.disk.main.device ];
    configurationLimit = 5;
  };

  zramSwap.enable = true;
}
