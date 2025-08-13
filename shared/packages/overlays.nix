# Package overlays for Kydra OS
{ config, pkgs, lib, ... }:

{
  nixpkgs.overlays = [
    # Custom overlay for Kydra-specific packages
    (final: prev: {
      kydra-tools = prev.buildEnv {
        name = "kydra-tools";
        paths = with prev; [
          # Network tools
          nmap
          tcpdump
          iperf3
          mtr
          
          # System tools
          lsof
          strace
          iotop
          nethogs
          
          # Backup tools
          restic
          rclone
          borgbackup
          
          # Monitoring
          prometheus-node-exporter
          
          # Security tools
          age
          sops
        ];
      };

      # Custom backup wrapper
      kydra-backup = prev.writeShellScriptBin "kydra-backup" ''
        #!/bin/bash
        set -e
        
        BACKUP_TYPE=''${1:-incremental}
        BACKUP_TARGET=''${2:-/var/lib/backup}
        
        case $BACKUP_TYPE in
          full)
            echo "Starting full backup to $BACKUP_TARGET"
            # Full backup logic here
            ;;
          incremental)
            echo "Starting incremental backup to $BACKUP_TARGET"
            # Incremental backup logic here
            ;;
          *)
            echo "Usage: kydra-backup [full|incremental] [target]"
            exit 1
            ;;
        esac
      '';
    })
  ];
}