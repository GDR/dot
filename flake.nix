{
  description = "Your new nix config";

  inputs = {
    # Hardware
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    # Nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-unstable.url = "nixpkgs/nixos-unstable"; 

    # Home manager
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # Nur packages
    nur.url = "github:nix-community/NUR";
    hardware.url = "github:nixos/nixos-hardware";
  };

  outputs = { nur, nixpkgs, home-manager, ... }@inputs:
    let
      forAllSystems = nixpkgs.lib.genAttrs [
        "aarch64-linux"
        "i686-linux"
        "x86_64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ];
    in
    rec {
      legacyPackages = forAllSystems (system:
        import nixpkgs {
          inherit system;
          overlays = with overlays; [ additions modifications ];
          config.allowUnfree = true;
        }
      );

      packages = forAllSystems (system:
        import ./pkgs { pkgs = legacyPackages.${system}; }
      );
     
      devShells = forAllSystems (system: {
        default = import ./shell.nix { pkgs = legacyPackages.${system}; };
      });

      # Your custom packages and modifications, exported as overlays
      overlays = import ./overlays;
      # Reusable nixos modules you might want to export
      # These are usually stuff you would upstream into nixpkgs
      nixosModules = import ./modules;

      nixosConfigurations = {
        Nix-Germany = nixpkgs.lib.nixosSystem {
          pkgs = legacyPackages."x86_64-linux";
          system = "x86_64-linux";
          specialArgs = { inherit inputs; }; # Pass flake inputs to our config
          modules = (builtins.attrValues nixosModules) ++ [
            # > Our main nixos configuration file <
            ./hosts/nix-germany/configuration.nix
            # Our common nixpkgs config (unfree, overlays, etc)
            (import ./nixpkgs-config.nix { inherit overlays; })
          ];
        };
      };
    };
}
