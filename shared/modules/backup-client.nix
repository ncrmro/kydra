# Backup client module for Kydra OS systems
{ config, pkgs, lib, ... }:

with lib;

let
  cfg = config.kydra.backup-client;
in

{
  options.kydra.backup-client = {
    enable = mkEnableOption "Kydra backup client";

    backupServer = mkOption {
      type = types.str;
      default = "nas.local";
      description = "Hostname or IP of the backup server";
    };

    backupPath = mkOption {
      type = types.str;
      default = "/var/lib/backup";
      description = "Local path for backup data";
    };

    schedule = mkOption {
      type = types.str;
      default = "daily";
      description = "Backup schedule (systemd timer format)";
    };

    excludePaths = mkOption {
      type = types.listOf types.str;
      default = [
        "/tmp/*"
        "/var/tmp/*"
        "/var/cache/*"
        "/nix/store/*"
        "*.tmp"
        "*.cache"
      ];
      description = "Paths to exclude from backup";
    };

    includePaths = mkOption {
      type = types.listOf types.str;
      default = [
        "/home"
        "/etc"
        "/var/lib"
        "/root"
      ];
      description = "Paths to include in backup";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      restic
      rclone
    ];

    # Backup service
    systemd.services.backup = {
      description = "Kydra system backup";
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];

      serviceConfig = {
        Type = "oneshot";
        User = "root";
        Group = "root";
        ExecStart = pkgs.writeShellScript "backup-script" ''
          #!/bin/bash
          set -e
          
          BACKUP_DATE=$(date +%Y%m%d_%H%M%S)
          BACKUP_NAME="kydra-$(hostname)-$BACKUP_DATE"
          
          echo "Starting backup: $BACKUP_NAME"
          
          # Create backup directory if it doesn't exist
          mkdir -p ${cfg.backupPath}
          
          # Generate exclude file
          EXCLUDE_FILE=$(mktemp)
          ${concatMapStringsSep "\n" (path: "echo '${path}' >> $EXCLUDE_FILE") cfg.excludePaths}
          
          # Perform backup using rsync
          ${pkgs.rsync}/bin/rsync -avz --delete \
            --exclude-from="$EXCLUDE_FILE" \
            ${concatStringsSep " " cfg.includePaths} \
            ${cfg.backupPath}/
          
          # Cleanup
          rm -f "$EXCLUDE_FILE"
          
          echo "Backup completed: $BACKUP_NAME"
          
          # Send backup to server if configured
          if ping -c 1 ${cfg.backupServer} >/dev/null 2>&1; then
            echo "Syncing to backup server..."
            ${pkgs.rsync}/bin/rsync -avz --delete \
              ${cfg.backupPath}/ \
              kydra-service@${cfg.backupServer}:/backup/$(hostname)/
            echo "Sync to backup server completed"
          else
            echo "Warning: Backup server ${cfg.backupServer} not reachable"
          fi
        '';
      };
    };

    # Backup timer
    systemd.timers.backup = {
      description = "Run backup service";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = cfg.schedule;
        Persistent = true;
        RandomizedDelaySec = "30m";
      };
    };

    # Ensure backup directory exists
    systemd.tmpfiles.rules = [
      "d ${cfg.backupPath} 0700 root root -"
    ];
  };
}