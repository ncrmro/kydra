# Kydra OS

Built on NixOS, Kydra OS is a complete infrastructure solution configured and versioned using Nix Flakes. This mono-repository contains configurations for desktop workstations, network-attached storage (NAS), and router systems.

## Architecture

### 🖥️ Desktop
- GNOME desktop environment with development tools
- Docker support for containerized applications
- Home Manager for user environment management
- Automated backups to NAS

### 🗄️ NAS (Network Attached Storage)
- ZFS filesystem with automated snapshots and scrubbing
- Samba and NFS file sharing
- Centralized backup server for all systems
- Prometheus monitoring and Grafana dashboards
- Automated backup integrity checks

### 🌐 Router
- DHCP server with static IP assignments
- DNS server with local domain resolution
- WireGuard VPN server for secure remote access
- Advanced firewall with DDoS protection
- Network monitoring and traffic analysis

### 🔒 Shared Security Features
- Secure boot with Lanzaboote and TPM unlock
- Centralized user management
- SOPS-based secret management
- Automated security updates
- AppArmor mandatory access control

## Repository Structure

```
├── README.md
├── flake.nix                    # Root flake for development tools
├── flake.lock
├── systems/
│   ├── desktop/
│   │   ├── flake.nix
│   │   ├── flake.lock
│   │   ├── configuration.nix
│   │   ├── hardware-configuration.nix
│   │   └── home.nix
│   ├── nas/
│   │   ├── flake.nix
│   │   ├── flake.lock
│   │   ├── configuration.nix
│   │   ├── hardware-configuration.nix
│   │   └── services/
│   │       └── backup.nix
│   └── router/
│       ├── flake.nix
│       ├── flake.lock
│       ├── configuration.nix
│       ├── hardware-configuration.nix
│       └── network/
│           ├── firewall.nix
│           ├── dhcp.nix
│           └── vpn.nix
├── shared/
│   ├── common.nix              # Base configuration for all systems
│   ├── users.nix               # User management
│   ├── security.nix            # Security policies
│   ├── packages/
│   │   ├── custom-scripts.nix
│   │   └── overlays.nix
│   └── modules/
│       ├── monitoring.nix
│       └── backup-client.nix
└── secrets/
    ├── .gitattributes
    ├── secrets.nix
    └── keys/
```

## Quick Start

### 1. Development Environment

Enter the development shell with all necessary tools:

```bash
nix develop
```

### 2. System Deployment

Deploy a specific system configuration:

```bash
# Navigate to the system directory
cd systems/desktop

# Build and switch to the configuration
sudo nixos-rebuild switch --flake .

# Or build without switching
nix build .#nixosConfigurations.desktop.config.system.build.toplevel
```

### 3. Secret Management

Initialize secrets management:

```bash
# Generate age key for SOPS
age-keygen -o ~/.config/sops/age/keys.txt

# Edit secrets
sops secrets/secrets.yaml
```

### 4. VPN Setup

Generate WireGuard client configuration:

```bash
# On the router system
wg-add-client mobile 10.0.0.20
```

## System Configuration

### Desktop Setup
1. Update `systems/desktop/hardware-configuration.nix` with your hardware details
2. Modify `systems/desktop/home.nix` for your user preferences
3. Add your SSH public keys to `shared/users.nix`

### NAS Setup
1. Configure ZFS pools in `systems/nas/configuration.nix`
2. Update network settings for your environment
3. Set up backup retention policies in `systems/nas/services/backup.nix`

### Router Setup
1. Configure network interfaces in `systems/router/hardware-configuration.nix`
2. Update DHCP ranges and static assignments in `systems/router/network/dhcp.nix`
3. Set up VPN clients in `systems/router/network/vpn.nix`

## Monitoring

Access monitoring dashboards:
- Grafana: http://nas.kydra.local:3000
- Prometheus: http://nas.kydra.local:9090

## Backup Strategy

- **Desktop**: Automated daily backups to NAS
- **Router**: Configuration backups to NAS
- **NAS**: ZFS snapshots and optional remote sync

## Commands

Kydra OS includes custom management commands:

```bash
kydra-status      # Show system status
kydra-update      # Update system configuration
kydra-backup-check # Check backup status
kydra-logs <service> # View service logs
wg-status         # Show VPN status (router only)
wg-add-client     # Add VPN client (router only)
```

## Security Notes

- All systems use passwordless sudo for the `kydra` user
- SSH access is key-based only
- Secrets are encrypted using SOPS with age
- Firewall rules are restrictive by default
- Automatic security updates are enabled

## Contributing

When modifying configurations:

1. Test changes in a VM first
2. Update documentation for any new features
3. Follow the existing code structure
4. Ensure secrets are properly encrypted

## Support

For issues and questions:
- Check system logs: `journalctl -xe`
- View service status: `systemctl status <service>`
- Monitor resources: `kydra-status`

---

## Development and Deployment Platform

- Github Application to Handle Automated Deployments
- Distributed Deployments
- Centralized LiteLLM
- Preview Environments

---

## UI

Authorize with Github
Create Project namespaces, create service accounts that only certain providers can access.
Create Deploy Environments
