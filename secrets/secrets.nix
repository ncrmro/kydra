# Secrets management for Kydra OS
{ config, pkgs, lib, ... }:

{
  # SOPS configuration for secret management
  sops = {
    defaultSopsFile = ./secrets.yaml;
    age.keyFile = "/var/lib/sops-age/keys.txt";
    
    secrets = {
      # SSH keys
      ssh_host_rsa_key = {
        sopsFile = ./keys/ssh_host_rsa_key.age;
        path = "/etc/ssh/ssh_host_rsa_key";
        mode = "0600";
        owner = "root";
        group = "root";
      };
      
      ssh_host_ed25519_key = {
        sopsFile = ./keys/ssh_host_ed25519_key.age;
        path = "/etc/ssh/ssh_host_ed25519_key";
        mode = "0600";
        owner = "root";
        group = "root";
      };
      
      # Wireguard keys
      wireguard_private_key = {
        sopsFile = ./keys/wireguard_private_key.age;
        owner = "systemd-network";
        group = "systemd-network";
        mode = "0600";
      };
      
      # Database passwords
      grafana_admin_password = {
        sopsFile = ./keys/grafana_admin_password.age;
        path = "/var/lib/grafana/admin_password";
        owner = "grafana";
        group = "grafana";
        mode = "0600";
      };
      
      # Backup encryption keys
      backup_encryption_key = {
        sopsFile = ./keys/backup_encryption_key.age;
        owner = "root";
        group = "root";
        mode = "0600";
      };
    };
  };

  # Ensure age key directory exists
  systemd.tmpfiles.rules = [
    "d /var/lib/sops-age 0700 root root -"
  ];
}