# Firewall configuration for router
{ config, pkgs, lib, ... }:

{
  # Advanced firewall configuration
  networking.firewall = {
    enable = true;
    
    # Allow basic services
    allowedTCPPorts = [
      22    # SSH
      53    # DNS
      67    # DHCP
      80    # HTTP (for router management)
      443   # HTTPS (for router management)
      51820 # WireGuard
      9100  # Node Exporter
    ];
    
    allowedUDPPorts = [
      53    # DNS
      67    # DHCP
      68    # DHCP client
      123   # NTP
      51820 # WireGuard
    ];

    # Custom firewall rules
    extraCommands = ''
      # Flush existing rules
      iptables -F
      iptables -X
      iptables -t nat -F
      iptables -t nat -X
      iptables -t mangle -F
      iptables -t mangle -X

      # Default policies
      iptables -P INPUT DROP
      iptables -P FORWARD DROP
      iptables -P OUTPUT ACCEPT

      # Allow loopback
      iptables -A INPUT -i lo -j ACCEPT
      iptables -A OUTPUT -o lo -j ACCEPT

      # Allow established and related connections
      iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
      iptables -A FORWARD -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

      # Allow ICMP (ping) with rate limiting
      iptables -A INPUT -p icmp --icmp-type echo-request -m limit --limit 5/sec -j ACCEPT
      iptables -A FORWARD -p icmp --icmp-type echo-request -m limit --limit 5/sec -j ACCEPT

      # Allow SSH from LAN with rate limiting
      iptables -A INPUT -i enp2s0 -p tcp --dport 22 -m conntrack --ctstate NEW -m recent --set
      iptables -A INPUT -i enp2s0 -p tcp --dport 22 -m conntrack --ctstate NEW -m recent --update --seconds 60 --hitcount 4 -j DROP
      iptables -A INPUT -i enp2s0 -p tcp --dport 22 -j ACCEPT

      # Allow DNS queries from LAN
      iptables -A INPUT -i enp2s0 -p udp --dport 53 -j ACCEPT
      iptables -A INPUT -i enp2s0 -p tcp --dport 53 -j ACCEPT

      # Allow DHCP from LAN
      iptables -A INPUT -i enp2s0 -p udp --dport 67 -j ACCEPT

      # Allow NTP from LAN
      iptables -A INPUT -i enp2s0 -p udp --dport 123 -j ACCEPT

      # Allow WireGuard
      iptables -A INPUT -p udp --dport 51820 -j ACCEPT

      # Allow monitoring from LAN
      iptables -A INPUT -i enp2s0 -p tcp --dport 9100 -j ACCEPT

      # Forward traffic from LAN to WAN
      iptables -A FORWARD -i enp2s0 -o enp1s0 -j ACCEPT

      # Forward traffic from WireGuard to LAN and WAN
      iptables -A FORWARD -i wg0 -o enp2s0 -j ACCEPT
      iptables -A FORWARD -i wg0 -o enp1s0 -j ACCEPT
      iptables -A FORWARD -i enp2s0 -o wg0 -j ACCEPT

      # NAT rules
      iptables -t nat -A POSTROUTING -o enp1s0 -j MASQUERADE
      iptables -t nat -A POSTROUTING -o wg0 -j MASQUERADE

      # Port forwarding examples (uncomment and modify as needed)
      # iptables -t nat -A PREROUTING -i enp1s0 -p tcp --dport 80 -j DNAT --to-destination 192.168.1.10:80
      # iptables -t nat -A PREROUTING -i enp1s0 -p tcp --dport 443 -j DNAT --to-destination 192.168.1.10:443

      # DDoS protection
      iptables -A INPUT -p tcp --dport 22 -m connlimit --connlimit-above 3 -j REJECT
      iptables -A INPUT -p tcp --syn -m limit --limit 1/s --limit-burst 3 -j ACCEPT
      iptables -A INPUT -p tcp --syn -j DROP

      # Block common attack patterns
      iptables -A INPUT -m string --string "GET /" --algo bm -j DROP
      iptables -A INPUT -m string --string "POST /" --algo bm -j DROP
      iptables -A INPUT -p tcp --dport 23 -j DROP  # Telnet
      iptables -A INPUT -p tcp --dport 135 -j DROP # RPC
      iptables -A INPUT -p tcp --dport 445 -j DROP # SMB
      iptables -A INPUT -p tcp --dport 1433 -j DROP # SQL Server
      iptables -A INPUT -p tcp --dport 3389 -j DROP # RDP

      # Log dropped packets
      iptables -A INPUT -j LOG --log-prefix "INPUT-DROP: " --log-level 4
      iptables -A FORWARD -j LOG --log-prefix "FORWARD-DROP: " --log-level 4
    '';

    # Rules to run when stopping firewall
    extraStopCommands = ''
      iptables -F
      iptables -X
      iptables -t nat -F
      iptables -t nat -X
      iptables -t mangle -F
      iptables -t mangle -X
      iptables -P INPUT ACCEPT
      iptables -P FORWARD ACCEPT
      iptables -P OUTPUT ACCEPT
    '';
  };

  # Fail2ban for additional protection
  services.fail2ban = {
    enable = true;
    jails = {
      ssh = {
        enabled = true;
        filter = "sshd";
        action = "iptables[name=SSH, port=ssh, protocol=tcp]";
        logpath = "/var/log/auth.log";
        maxretry = 3;
        bantime = 3600;
        findtime = 600;
      };
    };
  };

  # Network monitoring
  services.vnstat = {
    enable = true;
  };
}