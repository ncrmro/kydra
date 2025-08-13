# Security policies for Kydra OS systems
{ config, pkgs, lib, ... }:

{
  # Secure boot configuration (requires manual setup)
  boot = {
    loader = {
      systemd-boot = {
        enable = true;
        editor = false; # Disable boot entry editing
      };
      efi.canTouchEfiVariables = true;
    };
    
    # TPM support for disk encryption
    initrd = {
      systemd.enable = true;
      luks.devices = {
        root = {
          # Configure per-system
          # device = "/dev/disk/by-uuid/...";
          preLVM = true;
        };
      };
    };
  };

  # Firewall defaults
  networking.firewall = {
    enable = true;
    allowPing = false;
    logReversePathDrops = true;
    extraCommands = ''
      # Drop invalid packets
      iptables -A INPUT -m conntrack --ctstate INVALID -j DROP
      
      # Rate limiting for SSH
      iptables -A INPUT -p tcp --dport 22 -m conntrack --ctstate NEW -m recent --set
      iptables -A INPUT -p tcp --dport 22 -m conntrack --ctstate NEW -m recent --update --seconds 60 --hitcount 4 -j DROP
    '';
  };

  # Security kernel parameters
  boot.kernel.sysctl = {
    # Network security
    "net.ipv4.ip_forward" = lib.mkDefault 0;
    "net.ipv4.conf.all.send_redirects" = 0;
    "net.ipv4.conf.default.send_redirects" = 0;
    "net.ipv4.conf.all.accept_redirects" = 0;
    "net.ipv4.conf.default.accept_redirects" = 0;
    "net.ipv4.conf.all.accept_source_route" = 0;
    "net.ipv4.conf.default.accept_source_route" = 0;
    
    # Protection against various attacks
    "net.ipv4.conf.all.log_martians" = 1;
    "net.ipv4.conf.default.log_martians" = 1;
    "net.ipv4.icmp_echo_ignore_broadcasts" = 1;
    "net.ipv4.icmp_ignore_bogus_error_responses" = 1;
    "net.ipv4.tcp_syncookies" = 1;
  };

  # Fail2ban for intrusion prevention
  services.fail2ban = {
    enable = true;
    maxretry = 3;
    bantime = "1h";
    bantime-increment.enable = true;
  };

  # System hardening
  security = {
    # Disable coredumps
    pam.loginLimits = [
      { domain = "*"; type = "hard"; item = "core"; value = "0"; }
    ];
    
    # AppArmor support
    apparmor = {
      enable = true;
      killUnconfinedConfinables = true;
    };
  };

  # Automatic security updates
  system.autoUpgrade = {
    enable = lib.mkDefault true;
    dates = "04:00";
    allowReboot = lib.mkDefault false;
    channel = "https://nixos.org/channels/nixos-23.11";
  };
}