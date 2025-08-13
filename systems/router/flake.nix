{
  description = "Kydra OS Router Configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    {
      nixosConfigurations.router = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./configuration.nix
          ./hardware-configuration.nix
          ../../shared/common.nix
          ../../shared/users.nix
          ../../shared/security.nix
          ../../shared/packages/custom-scripts.nix
          ../../shared/packages/overlays.nix
          ../../shared/modules/monitoring.nix
          ../../shared/modules/backup-client.nix
          ../../secrets/secrets.nix
          ./network/firewall.nix
          ./network/dhcp.nix
          ./network/vpn.nix
        ];
      };
    };
}