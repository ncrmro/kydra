# Desktop system configuration
{ config, pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  # System identification
  networking.hostName = "desktop";
  networking.hostId = "12345678"; # Generate unique ID per system

  # Desktop environment
  services.xserver = {
    enable = true;
    displayManager.gdm.enable = true;
    desktopManager.gnome.enable = true;
  };

  # Audio
  sound.enable = true;
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Bluetooth
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  # Printing
  services.printing.enable = true;

  # Desktop packages
  environment.systemPackages = with pkgs; [
    firefox
    vscode
    gimp
    libreoffice
    vlc
    discord
    slack
    zoom-us
    thunderbird
    kydra-tools
  ];

  # Enable monitoring
  kydra.monitoring.enable = true;

  # Enable backup client
  kydra.backup-client.enable = true;

  # Graphics drivers (example for NVIDIA)
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.opengl = {
    enable = true;
    driSupport = true;
    driSupport32Bit = true;
  };

  # Docker for development
  virtualisation.docker.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Automatic garbage collection
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };
}