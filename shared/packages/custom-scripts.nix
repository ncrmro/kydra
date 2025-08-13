# Custom scripts and utilities for Kydra OS
{ config, pkgs, lib, ... }:

{
  environment.systemPackages = with pkgs; [
    # System maintenance scripts
    (writeShellScriptBin "kydra-update" ''
      #!/bin/bash
      set -e
      echo "Updating Kydra OS system..."
      sudo nixos-rebuild switch --flake /etc/nixos#$(hostname)
      echo "System updated successfully"
    '')

    (writeShellScriptBin "kydra-backup-check" ''
      #!/bin/bash
      echo "Checking backup status..."
      systemctl status backup.service || true
      journalctl -u backup.service --since "24 hours ago" --no-pager
    '')

    (writeShellScriptBin "kydra-status" ''
      #!/bin/bash
      echo "=== Kydra OS System Status ==="
      echo "Hostname: $(hostname)"
      echo "Uptime: $(uptime)"
      echo "NixOS Generation: $(nixos-version)"
      echo "Disk Usage:"
      df -h / /boot 2>/dev/null || true
      echo "Memory Usage:"
      free -h
      echo "Load Average:"
      cat /proc/loadavg
    '')

    (writeShellScriptBin "kydra-logs" ''
      #!/bin/bash
      SERVICE=''${1:-}
      if [ -z "$SERVICE" ]; then
        echo "Usage: kydra-logs <service-name>"
        echo "Available services:"
        systemctl list-units --type=service --state=running | grep kydra || true
        exit 1
      fi
      journalctl -u "$SERVICE" -f
    '')
  ];
}