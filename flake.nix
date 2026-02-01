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

  outputs = inputs@{ self, nixpkgs, nix-darwin, home-manager, nix-homebrew, nixvim, hardware, vscode-server, charon-key, ... }:
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
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };
          customPkgs = import ./pkgs { inherit pkgs lib system; };
        in
        customPkgs // {
          charon-key = charon-key.packages.${system}.default;
        }
      );

      devShells = forAllSystems (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          pre-commit-hooks = import ./pre-commit.nix { inherit pkgs; };
        in
        {
          default = pkgs.mkShell {
            buildInputs = with pkgs; [
              nixpkgs-fmt
              pre-commit
              direnv
            ];
            shellHook = ''
              if [ -f .envrc ]; then
                direnv allow 2>/dev/null
              fi
              pre-commit install -f --hook-type pre-commit >/dev/null 2>&1
            '';
          };
        }
      );

      # Host configurations
      darwinConfigurations.mac-brightstar = flakeHelpers.mkDarwinConfiguration ./hosts/mac-brightstar;
      # darwinConfigurations.mac-blackstar = flakeHelpers.mkDarwinConfiguration ./hosts/mac-blackstar;
      # nixosConfigurations.nix-germany = flakeHelpers.mkNixosConfiguration ./hosts/nix-germany;
      nixosConfigurations.nix-goldstar = flakeHelpers.mkNixosConfiguration ./hosts/nix-goldstar;

      templates = {
        python = {
          path = ./templates/python;
          description = "A template for a Python project using poetry";
        };
      };
    };
}
