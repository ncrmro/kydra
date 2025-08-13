{
  description = "Kydra OS Desktop Configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager }:
    {
      nixosConfigurations.desktop = nixpkgs.lib.nixosSystem {
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
          
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.kydra = import ./home.nix;
          }
        ];
      };
    };
}