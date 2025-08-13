# Backup services for NAS system
{ config, pkgs, lib, ... }:

{
  # Backup service for receiving backups from other systems
  systemd.services.backup-server = {
    description = "Kydra backup server";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" "zfs.target" ];

    serviceConfig = {
      Type = "simple";
      User = "kydra-service";
      Group = "kydra-service";
      Restart = "always";
      RestartSec = "10s";
    };

    script = ''
      #!/bin/bash
      set -e
      
      BACKUP_ROOT="/storage/backup"
      
      # Ensure backup directories exist
      mkdir -p "$BACKUP_ROOT"/{desktop,router}
      
      # Set proper permissions
      chown -R kydra-service:kydra-service "$BACKUP_ROOT"
      chmod -R 755 "$BACKUP_ROOT"
      
      echo "Backup server ready at $BACKUP_ROOT"
      
      # Keep the service running
      while true; do
        sleep 60
        # Periodic cleanup of old backups
        find "$BACKUP_ROOT" -type f -mtime +90 -delete 2>/dev/null || true
      done
    '';
  };

  # Automated backup integrity checks
  systemd.services.backup-integrity-check = {
    description = "Backup integrity verification";
    serviceConfig = {
      Type = "oneshot";
      User = "root";
      Group = "root";
    };

    script = ''
      #!/bin/bash
      set -e
      
      BACKUP_ROOT="/storage/backup"
      CHECK_LOG="/var/log/backup-integrity.log"
      
      echo "$(date): Starting backup integrity check" >> "$CHECK_LOG"
      
      # Check ZFS integrity
      zpool scrub storage 2>&1 | tee -a "$CHECK_LOG"
      
      # Check backup completeness
      for system in desktop router; do
        if [ -d "$BACKUP_ROOT/$system" ]; then
          backup_count=$(find "$BACKUP_ROOT/$system" -type f | wc -l)
          echo "$(date): $system has $backup_count backup files" >> "$CHECK_LOG"
        else
          echo "$(date): WARNING: No backups found for $system" >> "$CHECK_LOG"
        fi
      done
      
      # Check disk space
      df -h /storage | tee -a "$CHECK_LOG"
      
      echo "$(date): Backup integrity check completed" >> "$CHECK_LOG"
    '';
  };

  # Timer for backup integrity checks
  systemd.timers.backup-integrity-check = {
    description = "Run backup integrity check";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
      RandomizedDelaySec = "1h";
    };
  };

  # Backup rotation service
  systemd.services.backup-rotation = {
    description = "Backup rotation and cleanup";
    serviceConfig = {
      Type = "oneshot";
      User = "root";
      Group = "root";
    };

    script = ''
      #!/bin/bash
      set -e
      
      BACKUP_ROOT="/storage/backup"
      ROTATION_LOG="/var/log/backup-rotation.log"
      
      echo "$(date): Starting backup rotation" >> "$ROTATION_LOG"
      
      # Rotate old backups
      # Keep daily backups for 30 days
      find "$BACKUP_ROOT" -name "*.daily" -mtime +30 -delete 2>&1 | tee -a "$ROTATION_LOG"
      
      # Keep weekly backups for 12 weeks
      find "$BACKUP_ROOT" -name "*.weekly" -mtime +84 -delete 2>&1 | tee -a "$ROTATION_LOG"
      
      # Keep monthly backups for 12 months
      find "$BACKUP_ROOT" -name "*.monthly" -mtime +365 -delete 2>&1 | tee -a "$ROTATION_LOG"
      
      echo "$(date): Backup rotation completed" >> "$ROTATION_LOG"
    '';
  };

  # Timer for backup rotation
  systemd.timers.backup-rotation = {
    description = "Run backup rotation";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "weekly";
      Persistent = true;
      RandomizedDelaySec = "2h";
    };
  };

  # Remote backup synchronization (optional)
  systemd.services.remote-backup-sync = {
    description = "Sync backups to remote location";
    serviceConfig = {
      Type = "oneshot";
      User = "kydra-service";
      Group = "kydra-service";
    };

    script = ''
      #!/bin/bash
      set -e
      
      BACKUP_ROOT="/storage/backup"
      REMOTE_TARGET="backup@remote.example.com:/remote/backup/"
      SYNC_LOG="/var/log/remote-backup-sync.log"
      
      echo "$(date): Starting remote backup sync" >> "$SYNC_LOG"
      
      # Check if remote target is reachable
      if ping -c 1 remote.example.com >/dev/null 2>&1; then
        ${pkgs.rsync}/bin/rsync -avz --delete \
          --exclude="*.tmp" \
          --exclude="*.partial" \
          "$BACKUP_ROOT/" \
          "$REMOTE_TARGET" 2>&1 | tee -a "$SYNC_LOG"
        
        echo "$(date): Remote backup sync completed successfully" >> "$SYNC_LOG"
      else
        echo "$(date): Remote target unreachable, skipping sync" >> "$SYNC_LOG"
      fi
    '';
  };

  # Timer for remote backup sync (disabled by default)
  systemd.timers.remote-backup-sync = {
    description = "Sync backups to remote location";
    # wantedBy = [ "timers.target" ]; # Uncomment to enable
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
      RandomizedDelaySec = "3h";
    };
  };

  # Log rotation for backup logs
  services.logrotate = {
    enable = true;
    settings = {
      "/var/log/backup-*.log" = {
        frequency = "weekly";
        rotate = 4;
        compress = true;
        delaycompress = true;
        missingok = true;
        notifempty = true;
        create = "644 root root";
      };
    };
  };
}