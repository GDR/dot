{
  inputs = {
    nixpkgs = {
      url = "github:NixOS/nixpkgs";
    };
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-homebrew = {
      url = "github:zhaofengli-wip/nix-homebrew";
      inputs.nixpkgs.follows = "nixpkgs";
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
  };

  outputs = inputs@{ self, nixpkgs, nix-darwin, home-manager, nix-homebrew, nixvim, hardware, vscode-server, ... }:
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

      mkConfigurationModules = lib.concatMap
        (module: (import module { inherit inputs lib overlays; }).modules);

      mkDarwinConfiguration = host-config:
        let
          system = "aarch64-darwin";
        in
        nix-darwin.lib.darwinSystem {
          inherit system;
          specialArgs = { inherit self inputs lib overlays system vscode-server; };
          modules = [ host-config ]
            ++ mkConfigurationModules [
            ./modules/common
            ./modules/darwin
          ];
        };

      mkNixosConfiguration = host-config:
        let
          system = "x86_64-linux";
        in
        nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = { inherit self inputs lib overlays system hardware; };
          modules = [ host-config ]
            ++ mkConfigurationModules [
            ./modules/common
            ./modules/linux
          ];
        };
    in
    {
      inherit lib;

      packages = forAllSystems (system:
        let pkgs = nixpkgs.legacyPackages.${system};
        in import ./pkgs { inherit pkgs lib system; }
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
                direnv allow
              fi
              pre-commit install -f --hook-type pre-commit
            '';
          };
        }
      );

      darwinConfigurations.mac-italy = mkDarwinConfiguration ./hosts/mac-italy;
      nixosConfigurations.nix-germany = mkNixosConfiguration ./hosts/nix-germany;

      templates = {
        python = {
          path = ./templates/python;
          description = "A template for a Python project using poetry";
        };
      };
    };
}
