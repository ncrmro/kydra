# NAS system configuration
{ config, pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./services/backup.nix
  ];

  # System identification
  networking.hostName = "nas";
  networking.hostId = "87654321"; # Generate unique ID per system

  # ZFS configuration
  boot.supportedFilesystems = [ "zfs" ];
  boot.zfs.requestEncryption = true;
  
  # ZFS pools and datasets
  fileSystems."/storage" = {
    device = "storage";
    fsType = "zfs";
  };

  fileSystems."/storage/shares" = {
    device = "storage/shares";
    fsType = "zfs";
  };

  fileSystems."/storage/backup" = {
    device = "storage/backup";
    fsType = "zfs";
  };

  # Samba file sharing
  services.samba = {
    enable = true;
    openFirewall = true;
    settings = {
      global = {
        "workgroup" = "KYDRA";
        "server string" = "Kydra NAS";
        "netbios name" = "nas";
        "security" = "user";
        "map to guest" = "bad user";
        "guest account" = "nobody";
        "guest ok" = "yes";
        "create mask" = "0664";
        "force create mode" = "0664";
        "directory mask" = "0775";
        "force directory mode" = "0775";
      };

      "shares" = {
        "path" = "/storage/shares";
        "browseable" = "yes";
        "read only" = "no";
        "guest ok" = "no";
        "create mask" = "0644";
        "directory mask" = "0755";
        "valid users" = "kydra";
      };

      "backup" = {
        "path" = "/storage/backup";
        "browseable" = "yes";
        "read only" = "no";
        "guest ok" = "no";
        "create mask" = "0600";
        "directory mask" = "0700";
        "valid users" = "kydra";
      };
    };
  };

  # NFS sharing
  services.nfs.server = {
    enable = true;
    exports = ''
      /storage/shares    192.168.1.0/24(rw,sync,no_subtree_check,no_root_squash)
      /storage/backup    192.168.1.0/24(rw,sync,no_subtree_check,root_squash)
    '';
  };

  # SSH server for remote backup
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
      AllowUsers = [ "kydra" "kydra-service" ];
    };
  };

  # Enable monitoring (Prometheus + Grafana)
  kydra.monitoring.enable = true;

  # ZFS auto-scrub
  services.zfs.autoScrub = {
    enable = true;
    interval = "weekly";
  };

  # ZFS auto-snapshot
  services.zfs.autoSnapshot = {
    enable = true;
    flags = "-k -p --utc";
    frequent = 4;   # 15-minute intervals
    hourly = 24;
    daily = 7;
    weekly = 4;
    monthly = 12;
  };

  # Network configuration
  networking = {
    interfaces.enp2s0.ipv4.addresses = [{
      address = "192.168.1.10";
      prefixLength = 24;
    }];
    defaultGateway = "192.168.1.1";
    nameservers = [ "192.168.1.1" "1.1.1.1" ];
  };

  # Firewall configuration
  networking.firewall = {
    allowedTCPPorts = [
      22    # SSH
      139   # Samba
      445   # Samba
      2049  # NFS
      3000  # Grafana
      9090  # Prometheus
      9100  # Node Exporter
    ];
    allowedUDPPorts = [
      137   # NetBIOS
      138   # NetBIOS
    ];
  };

  # System packages
  environment.systemPackages = with pkgs; [
    zfs
    smartmontools
    hdparm
    lm_sensors
    kydra-tools
  ];

  # Smart monitoring
  services.smartd = {
    enable = true;
    autodetect = true;
  };

  # Temperature monitoring
  services.lm-sensors.enable = true;
}