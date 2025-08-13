# User management for Kydra OS systems
{ config, pkgs, lib, ... }:

{
  # Define users for all systems
  users = {
    mutableUsers = false; # Manage users declaratively
    
    # Default user account
    users.kydra = {
      isNormalUser = true;
      description = "Kydra System Administrator";
      extraGroups = [ "wheel" "networkmanager" "docker" ];
      shell = pkgs.bash;
      openssh.authorizedKeys.keys = [
        # Add SSH public keys here
        # "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5... user@hostname"
      ];
    };

    # System user for services
    users.kydra-service = {
      isSystemUser = true;
      group = "kydra-service";
      description = "Kydra service account";
    };

    groups.kydra-service = {};
  };

  # Sudo configuration
  security.sudo = {
    enable = true;
    extraRules = [
      {
        users = [ "kydra" ];
        commands = [
          {
            command = "ALL";
            options = [ "NOPASSWD" ];
          }
        ];
      }
    ];
  };
}