{
  description = "Kydra OS - NixOS infrastructure mono repo";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, home-manager, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            nixos-rebuild
            home-manager.packages.${system}.default
            git
            age
            ssh-to-age
            sops
          ];
          
          shellHook = ''
            echo "Welcome to Kydra OS development environment"
            echo "Available commands:"
            echo "  nixos-rebuild - Build and switch NixOS configurations"
            echo "  home-manager - Manage user environments"
            echo "  sops - Manage secrets"
          '';
        };

        formatter = pkgs.nixpkgs-fmt;
      }
    ) // {
      # System configurations are defined in their respective flakes
      # Use 'nix build .#nixosConfigurations.desktop.config.system.build.toplevel' to build
      # Or navigate to systems/desktop and run 'nixos-rebuild switch --flake .'
    };
}