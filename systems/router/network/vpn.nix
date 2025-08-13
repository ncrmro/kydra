# WireGuard VPN configuration for router
{ config, pkgs, lib, ... }:

{
  # WireGuard VPN server
  networking.wireguard = {
    enable = true;
    
    interfaces = {
      wg0 = {
        # Server configuration
        ips = [ "10.0.0.1/24" ];
        listenPort = 51820;
        
        # Server private key (should be in secrets)
        privateKeyFile = config.sops.secrets.wireguard_private_key.path;
        
        # Enable packet forwarding for VPN clients
        postSetup = ''
          ${pkgs.iptables}/bin/iptables -A FORWARD -i wg0 -j ACCEPT
          ${pkgs.iptables}/bin/iptables -A FORWARD -o wg0 -j ACCEPT
          ${pkgs.iptables}/bin/iptables -t nat -A POSTROUTING -s 10.0.0.0/24 -o enp1s0 -j MASQUERADE
          ${pkgs.iptables}/bin/iptables -t nat -A POSTROUTING -s 10.0.0.0/24 -o enp2s0 -j MASQUERADE
        '';
        
        postShutdown = ''
          ${pkgs.iptables}/bin/iptables -D FORWARD -i wg0 -j ACCEPT 2>/dev/null || true
          ${pkgs.iptables}/bin/iptables -D FORWARD -o wg0 -j ACCEPT 2>/dev/null || true
          ${pkgs.iptables}/bin/iptables -t nat -D POSTROUTING -s 10.0.0.0/24 -o enp1s0 -j MASQUERADE 2>/dev/null || true
          ${pkgs.iptables}/bin/iptables -t nat -D POSTROUTING -s 10.0.0.0/24 -o enp2s0 -j MASQUERADE 2>/dev/null || true
        '';
        
        # VPN client configurations
        peers = [
          # Desktop VPN access
          {
            # publicKey = "DESKTOP_PUBLIC_KEY_HERE";
            allowedIPs = [ "10.0.0.10/32" ];
            persistentKeepalive = 25;
          }
          
          # Mobile device VPN access
          {
            # publicKey = "MOBILE_PUBLIC_KEY_HERE";
            allowedIPs = [ "10.0.0.20/32" ];
            persistentKeepalive = 25;
          }
          
          # Laptop VPN access
          {
            # publicKey = "LAPTOP_PUBLIC_KEY_HERE";
            allowedIPs = [ "10.0.0.30/32" ];
            persistentKeepalive = 25;
          }
        ];
      };
    };
  };

  # DNS configuration for VPN clients
  services.dnsmasq.settings = {
    # Listen on WireGuard interface
    interface = [ "enp2s0" "wg0" ];
    
    # DNS for VPN network
    address = [
      "/vpn.kydra.local/10.0.0.1"
    ];
    
    # DHCP for VPN (if needed - usually static)
    dhcp-range = [
      "set:wg0,10.0.0.100,10.0.0.150,255.255.255.0,24h"
    ];
  };

  # WireGuard management scripts
  environment.systemPackages = with pkgs; [
    wireguard-tools
    qrencode
    
    # Script to generate client configurations
    (writeShellScriptBin "wg-add-client" ''
      #!/bin/bash
      set -e
      
      CLIENT_NAME="$1"
      CLIENT_IP="$2"
      
      if [ -z "$CLIENT_NAME" ] || [ -z "$CLIENT_IP" ]; then
        echo "Usage: wg-add-client <client-name> <client-ip>"
        echo "Example: wg-add-client mobile 10.0.0.20"
        exit 1
      fi
      
      # Generate client keys
      CLIENT_PRIVATE=$(wg genkey)
      CLIENT_PUBLIC=$(echo "$CLIENT_PRIVATE" | wg pubkey)
      
      # Get server public key
      SERVER_PUBLIC=$(sudo wg show wg0 public-key)
      
      # Create client configuration
      cat > "/tmp/$CLIENT_NAME.conf" <<EOF
      [Interface]
      PrivateKey = $CLIENT_PRIVATE
      Address = $CLIENT_IP/32
      DNS = 192.168.1.1
      
      [Peer]
      PublicKey = $SERVER_PUBLIC
      Endpoint = YOUR_EXTERNAL_IP:51820
      AllowedIPs = 0.0.0.0/0
      PersistentKeepalive = 25
      EOF
      
      echo "Client configuration saved to /tmp/$CLIENT_NAME.conf"
      echo "Client public key: $CLIENT_PUBLIC"
      echo ""
      echo "Add this peer to the server configuration:"
      echo "{"
      echo "  publicKey = \"$CLIENT_PUBLIC\";"
      echo "  allowedIPs = [ \"$CLIENT_IP/32\" ];"
      echo "  persistentKeepalive = 25;"
      echo "}"
      echo ""
      echo "QR code for mobile devices:"
      qrencode -t ansiutf8 < "/tmp/$CLIENT_NAME.conf"
    '')
    
    # Script to show VPN status
    (writeShellScriptBin "wg-status" ''
      #!/bin/bash
      echo "=== WireGuard VPN Status ==="
      sudo wg show
      echo ""
      echo "=== Connected Clients ==="
      sudo wg show wg0 peers | while read peer; do
        echo "Peer: $peer"
        sudo wg show wg0 latest-handshakes | grep "$peer" || echo "  No recent handshake"
        sudo wg show wg0 transfer | grep "$peer" || echo "  No transfer data"
        echo ""
      done
    '')
    
    # Script to restart VPN
    (writeShellScriptBin "wg-restart" ''
      #!/bin/bash
      echo "Restarting WireGuard VPN..."
      sudo systemctl restart systemd-networkd
      sudo wg-quick down wg0 2>/dev/null || true
      sudo wg-quick up wg0
      echo "WireGuard VPN restarted"
    '')
  ];

  # VPN monitoring service
  systemd.services.vpn-monitor = {
    description = "VPN connection monitor";
    wantedBy = [ "multi-user.target" ];
    after = [ "systemd-networkd.service" ];
    
    serviceConfig = {
      Type = "simple";
      Restart = "always";
      RestartSec = "60s";
    };
    
    script = ''
      #!/bin/bash
      LOG_FILE="/var/log/vpn-monitor.log"
      
      while true; do
        # Check if WireGuard interface is up
        if ip link show wg0 >/dev/null 2>&1; then
          # Count active peers
          PEER_COUNT=$(wg show wg0 peers | wc -l)
          
          # Log status
          echo "$(date): WireGuard up, $PEER_COUNT peers configured" >> "$LOG_FILE"
          
          # Check for recent handshakes (last 5 minutes)
          ACTIVE_PEERS=0
          wg show wg0 latest-handshakes | while read peer timestamp; do
            if [ -n "$timestamp" ]; then
              CURRENT_TIME=$(date +%s)
              TIME_DIFF=$((CURRENT_TIME - timestamp))
              if [ $TIME_DIFF -lt 300 ]; then  # 5 minutes
                ACTIVE_PEERS=$((ACTIVE_PEERS + 1))
              fi
            fi
          done
          
          if [ $ACTIVE_PEERS -gt 0 ]; then
            echo "$(date): $ACTIVE_PEERS active VPN connections" >> "$LOG_FILE"
          fi
        else
          echo "$(date): WARNING - WireGuard interface down" >> "$LOG_FILE"
        fi
        
        sleep 60
      done
    '';
  };

  # VPN log rotation
  services.logrotate.settings."/var/log/vpn-monitor.log" = {
    frequency = "weekly";
    rotate = 4;
    compress = true;
    delaycompress = true;
    missingok = true;
    notifempty = true;
    create = "644 root root";
  };

  # Open firewall for WireGuard
  networking.firewall = {
    allowedUDPPorts = [ 51820 ];
    
    # Allow VPN traffic forwarding
    extraCommands = ''
      # Allow VPN client to client communication
      iptables -A FORWARD -i wg0 -o wg0 -j ACCEPT
      
      # Allow VPN clients to access LAN
      iptables -A FORWARD -i wg0 -o enp2s0 -s 10.0.0.0/24 -d 192.168.1.0/24 -j ACCEPT
      iptables -A FORWARD -i enp2s0 -o wg0 -s 192.168.1.0/24 -d 10.0.0.0/24 -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
    '';
  };
}