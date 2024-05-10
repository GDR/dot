{
  description = "Example Darwin system flake";

  inputs = {
    # Basic url
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    # Darwin
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    # Home manager
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # Hardware
    hardware.url = "github:nixos/nixos-hardware";
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs, home-manager }:
    let
      inherit (nix-darwin.lib) darwinSystem;
      inherit (inputs.nixpkgs.lib) attrValues makeOverridable optionalAttrs singleton;

      nixpkgsConfig = {
        config = { allowUnfree = true; };
      };

      lib = nixpkgs.lib.extend (lib: _: {
        my = import ./lib { inherit inputs lib; };
      });

      modules = import ./modules { inherit inputs lib; nixpkgs = nixpkgsConfig; };

      forAllSystems = nixpkgs.lib.genAttrs [
        "aarch64-linux"
        "i686-linux"
        "x86_64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ];
    in
    rec
    {
      inherit lib modules;

      packages = forAllSystems (system:
        let pkgs = nixpkgs.legacyPackages.${system};
        in import ./pkgs { inherit pkgs; }
      );

      # Build darwin flake using:
      # $ darwin-rebuild build --flake .#mac-italy
      darwinConfigurations.mac-italy = nix-darwin.lib.darwinSystem {
        specialArgs = {
          inherit self inputs;
        };
        modules = [ ./hosts/mac-italy ] ++ (modules.modules);
      };

      nixosConfigurations = {
        thinkpad-germany = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit self inputs; };
          modules = (modules.modules) ++ [
            ./hosts/thinkpad-germany
          ];
        };
      };

      # Expose the package set, including overlays, for convenience.
      darwinPackages = self.darwinConfigurations."mac-italy".pkgs;
    };
}
