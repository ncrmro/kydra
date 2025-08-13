# Router system configuration
{ config, pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./network/firewall.nix
    ./network/dhcp.nix
    ./network/vpn.nix
  ];

  # System identification
  networking.hostName = "router";
  networking.hostId = "abcdef12"; # Generate unique ID per system

  # Enable IP forwarding for routing
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
  };

  # Network interfaces configuration
  networking = {
    useDHCP = false;
    
    # WAN interface (external)
    interfaces.enp1s0 = {
      useDHCP = true; # Get IP from ISP
    };
    
    # LAN interface (internal)
    interfaces.enp2s0 = {
      ipv4.addresses = [{
        address = "192.168.1.1";
        prefixLength = 24;
      }];
    };

    # Enable NAT
    nat = {
      enable = true;
      externalInterface = "enp1s0";
      internalInterfaces = [ "enp2s0" "wg0" ];
    };

    # Wireless configuration (if applicable)
    wireless = {
      enable = false; # Set to true if using WiFi
      # interfaces = [ "wlp3s0" ];
    };
  };

  # DNS server
  services.dnsmasq = {
    enable = true;
    settings = {
      # Upstream DNS servers
      server = [
        "1.1.1.1"
        "1.0.0.1"
        "8.8.8.8"
        "8.8.4.4"
      ];
      
      # Local domain
      domain = "kydra.local";
      expand-hosts = true;
      
      # Cache settings
      cache-size = 1000;
      
      # Local network DNS
      address = [
        "/router.kydra.local/192.168.1.1"
        "/nas.kydra.local/192.168.1.10"
        "/desktop.kydra.local/192.168.1.100"
      ];
      
      # DHCP range is configured in dhcp.nix
    };
  };

  # Network Time Protocol
  services.ntp = {
    enable = true;
    servers = [
      "0.pool.ntp.org"
      "1.pool.ntp.org"
      "2.pool.ntp.org"
      "3.pool.ntp.org"
    ];
  };

  # Enable monitoring
  kydra.monitoring.enable = true;

  # Enable backup client
  kydra.backup-client.enable = true;

  # Traffic monitoring and QoS
  services.vnstat = {
    enable = true;
  };

  # System packages for router functionality
  environment.systemPackages = with pkgs; [
    iptables
    iproute2
    tcpdump
    nmap
    iperf3
    mtr
    dig
    whois
    kydra-tools
    vnstat
  ];

  # Disable unnecessary services for a router
  services.xserver.enable = false;
  sound.enable = false;
  
  # Enable SSH for remote management
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
      AllowUsers = [ "kydra" ];
    };
  };

  # Logging configuration
  services.rsyslog = {
    enable = true;
    defaultConfig = ''
      # Log network events
      kern.*                          /var/log/kernel.log
      daemon.*                        /var/log/daemon.log
      *.info;mail.none;authpriv.none;cron.none    /var/log/messages
    '';
  };

  # Automatic system maintenance
  system.autoUpgrade = {
    enable = true;
    dates = "04:00";
    allowReboot = false; # Don't auto-reboot a router
  };
}