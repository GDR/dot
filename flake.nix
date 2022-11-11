{
  description = "Your new nix config";

  inputs = {
    # Hardware
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    # Nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # Home manager
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # Nur packages
    nur.url = "github:nix-community/NUR";
    # TODO: Add any other flake you might need
    hardware.url = "github:nixos/nixos-hardware";

    hyprland = {
      url = "github:gdr/Hyprland";
    };

    # Shameless plug: looking for a way to nixify your themes and make
    # everything match nicely? Try nix-colors!
    # nix-colors.url = "github:misterio77/nix-colors";
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
      nixosModules = import ./modules/nixos;
      # Reusable home-manager modules you might want to export
      # These are usually stuff you would upstream into home-manager
      homeManagerModules = import ./modules/home;

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

      homeConfigurations = {
        "gdr" = home-manager.lib.homeManagerConfiguration {
          pkgs = legacyPackages.x86_64-linux; # Home-manager requires 'pkgs' instance
          extraSpecialArgs = { inherit inputs; }; # Pass flake inputs to our config
          modules = (builtins.attrValues homeManagerModules) ++ [
            nur.nixosModules.nur
            # > Our main home-manager configuration file <
            ./home
            # Our common nixpkgs config (unfree, overlays, etc)
            (import ./nixpkgs-config.nix { inherit overlays; })
          ];
        };
      };
    };
}
