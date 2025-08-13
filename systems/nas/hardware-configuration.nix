# Hardware configuration for NAS system
{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  # Boot configuration
  boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  # Root filesystem
  fileSystems."/" = {
    device = "/dev/disk/by-uuid/REPLACE-WITH-ACTUAL-ROOT-UUID";
    fsType = "ext4";
  };

  # Boot partition
  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/REPLACE-WITH-ACTUAL-BOOT-UUID";
    fsType = "vfat";
  };

  # ZFS pool configuration
  # Note: ZFS pools are managed by ZFS, not in hardware-configuration.nix
  # The actual pool creation should be done manually:
  # zpool create -f storage raidz2 /dev/disk/by-id/...

  # Swap configuration
  swapDevices = [
    { device = "/dev/disk/by-uuid/REPLACE-WITH-ACTUAL-SWAP-UUID"; }
  ];

  # Network interfaces
  networking.useDHCP = lib.mkDefault false;
  networking.interfaces.enp2s0.useDHCP = lib.mkDefault false;

  # CPU configuration
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  # Enable hardware features for NAS
  hardware.enableRedistributableFirmware = true;
}