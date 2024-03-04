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
    in
    rec
    {
      inherit lib modules;

      # Build darwin flake using:
      # $ darwin-rebuild build --flake .#mac-italy
      darwinConfigurations.mac-italy = nix-darwin.lib.darwinSystem {
        modules = [ ./hosts/mac-italy  ] ++ (modules.modules) ++ [
          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
          }
        ];
      };

      # Expose the package set, including overlays, for convenience.
      darwinPackages = self.darwinConfigurations."mac-italy".pkgs;
    };
}
