# No swap partition: on 16GB it would cost ~12% of the disk.
# zramSwap covers it instead (see homeserver.nix).

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
          # The 1 MiB left free before the partition is where grub-install embeds core.img on an MBR disk. 
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
}
