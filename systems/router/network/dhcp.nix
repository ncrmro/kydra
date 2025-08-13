# DHCP server configuration for router
{ config, pkgs, lib, ... }:

{
  # DHCP server configuration
  services.dnsmasq = {
    enable = true;
    settings = {
      # Interface to serve DHCP on
      interface = "enp2s0";
      bind-interfaces = true;
      
      # DHCP range and lease time
      dhcp-range = [
        "192.168.1.100,192.168.1.200,255.255.255.0,24h"
      ];
      
      # Default gateway
      dhcp-option = [
        "option:router,192.168.1.1"
        "option:dns-server,192.168.1.1"
        "option:netmask,255.255.255.0"
        "option:broadcast,192.168.1.255"
        "option:ntp-server,192.168.1.1"
      ];
      
      # Static IP assignments
      dhcp-host = [
        "aa:bb:cc:dd:ee:01,nas,192.168.1.10,24h"
        "aa:bb:cc:dd:ee:02,desktop,192.168.1.50,24h"
        # Add more static assignments as needed
      ];
      
      # Domain name
      domain = "kydra.local";
      expand-hosts = true;
      
      # DNS settings
      no-hosts = false;
      addn-hosts = "/etc/hosts.dnsmasq";
      
      # Cache settings
      cache-size = 1000;
      neg-ttl = 60;
      
      # Security settings
      bogus-priv = true;
      domain-needed = true;
      
      # Logging
      log-queries = false;
      log-dhcp = true;
      
      # Performance
      dns-forward-max = 150;
      
      # DHCP authoritative
      dhcp-authoritative = true;
      
      # Lease file
      dhcp-leasefile = "/var/lib/dhcp/dnsmasq.leases";
    };
  };

  # Custom hosts file for local DNS resolution
  environment.etc."hosts.dnsmasq".text = ''
    # Kydra local network hosts
    192.168.1.1     router.kydra.local router
    192.168.1.10    nas.kydra.local nas
    192.168.1.50    desktop.kydra.local desktop
    
    # Add more local hosts as needed
  '';

  # DHCP lease monitoring script
  systemd.services.dhcp-monitor = {
    description = "DHCP lease monitor";
    wantedBy = [ "multi-user.target" ];
    after = [ "dnsmasq.service" ];
    
    serviceConfig = {
      Type = "simple";
      Restart = "always";
      RestartSec = "30s";
    };
    
    script = ''
      #!/bin/bash
      LEASE_FILE="/var/lib/dhcp/dnsmasq.leases"
      LOG_FILE="/var/log/dhcp-monitor.log"
      
      while true; do
        if [ -f "$LEASE_FILE" ]; then
          # Log current leases periodically
          LEASE_COUNT=$(wc -l < "$LEASE_FILE")
          echo "$(date): Active DHCP leases: $LEASE_COUNT" >> "$LOG_FILE"
          
          # Check for suspicious activity (too many requests from same MAC)
          if [ -f "$LEASE_FILE" ]; then
            awk '{print $2}' "$LEASE_FILE" | sort | uniq -c | while read count mac; do
              if [ "$count" -gt 5 ]; then
                echo "$(date): WARNING: MAC $mac has $count leases" >> "$LOG_FILE"
              fi
            done
          fi
        fi
        
        sleep 300  # Check every 5 minutes
      done
    '';
  };

  # DHCP lease backup
  systemd.services.dhcp-backup = {
    description = "Backup DHCP leases";
    serviceConfig = {
      Type = "oneshot";
      User = "root";
    };
    
    script = ''
      #!/bin/bash
      LEASE_FILE="/var/lib/dhcp/dnsmasq.leases"
      BACKUP_DIR="/var/backup/dhcp"
      
      mkdir -p "$BACKUP_DIR"
      
      if [ -f "$LEASE_FILE" ]; then
        cp "$LEASE_FILE" "$BACKUP_DIR/dnsmasq.leases.$(date +%Y%m%d)"
        
        # Keep only last 30 days of backups
        find "$BACKUP_DIR" -name "dnsmasq.leases.*" -mtime +30 -delete
      fi
    '';
  };

  # Timer for DHCP backup
  systemd.timers.dhcp-backup = {
    description = "Backup DHCP leases daily";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
    };
  };

  # Create necessary directories
  systemd.tmpfiles.rules = [
    "d /var/lib/dhcp 0755 dnsmasq dnsmasq -"
    "d /var/backup/dhcp 0755 root root -"
    "d /var/log 0755 root root -"
  ];

  # Network interface configuration for DHCP
  networking.interfaces.enp2s0 = {
    ipv4.addresses = [{
      address = "192.168.1.1";
      prefixLength = 24;
    }];
  };

  # Enable IP forwarding for DHCP clients
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
  };
}