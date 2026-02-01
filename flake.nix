{
  inputs = {
    nixpkgs = {
      url = "github:NixOS/nixpkgs/nixos-unstable";

    };
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-homebrew = {
      url = "github:zhaofengli-wip/nix-homebrew";
    };
    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hardware = {
      url = "github:nixos/nixos-hardware";
    };
    vscode-server = {
      url = "github:nix-community/nixos-vscode-server";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    charon-key = {
      url = "github:GDR/charon-key";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ self, nixpkgs, charon-key, ... }:
    let
      lib = nixpkgs.lib.extend (lib: _:
        let hm = inputs.home-manager.lib.hm; in {
          inherit hm;
          my = import ./lib { inherit inputs lib; };
        });

      forAllSystems = nixpkgs.lib.genAttrs [
        "aarch64-darwin"
        "x86_64-linux"
      ];

      overlays = forAllSystems (system: import ./overlays { inherit inputs lib system; });

      # Get flake helpers (mkDarwinConfiguration, mkNixosConfiguration, etc.)
      flakeHelpers = lib.my.mkFlakeHelpers { inherit self overlays; };
    in
    {
      inherit lib;

      packages = forAllSystems (system:
        let
          pkgs = import nixpkgs { inherit system; config.allowUnfree = true; };
        in
        import ./packages.nix { inherit pkgs lib system charon-key; }
      );

      devShells = forAllSystems (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          customPkgs = import ./pkgs { inherit pkgs lib system; };
        in
        import ./devShells.nix { inherit pkgs customPkgs; }
      );

      # Host configurations
      darwinConfigurations.mac-brightstar = flakeHelpers.mkDarwinConfiguration ./hosts/machines/mac-brightstar;
      # darwinConfigurations.mac-blackstar = flakeHelpers.mkDarwinConfiguration ./hosts/machines/mac-blackstar;
      # nixosConfigurations.nix-germany = flakeHelpers.mkNixosConfiguration ./hosts/machines/nix-germany;
      nixosConfigurations.nix-goldstar = flakeHelpers.mkNixosConfiguration ./hosts/machines/nix-goldstar;

      templates = {
        python = {
          path = ./templates/python;
          description = "A template for a Python project using poetry";
        };
      };
    };
}
