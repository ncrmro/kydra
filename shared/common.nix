# Common configuration for all Kydra OS systems
{ config, pkgs, lib, ... }:

{
  # System-wide configuration
  system.stateVersion = "23.11"; # Update as needed

  # Enable flakes
  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store = true;
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
  };

  # Basic networking
  networking = {
    useDHCP = lib.mkDefault false;
    firewall.enable = lib.mkDefault true;
  };

  # Timezone and locale
  time.timeZone = lib.mkDefault "UTC";
  i18n.defaultLocale = lib.mkDefault "en_US.UTF-8";

  # Basic packages available on all systems
  environment.systemPackages = with pkgs; [
    curl
    git
    htop
    vim
    wget
    tree
    tmux
    rsync
  ];

  # Security defaults
  security = {
    rtkit.enable = true;
    polkit.enable = true;
  };

  # Enable SSH by default for remote management
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
  };
}