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
    nix-wrapper-modules = {
      url = "github:BirdeeHub/nix-wrapper-modules";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hardware = {
      url = "github:nixos/nixos-hardware";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    vscode-server = {
      url = "github:nix-community/nixos-vscode-server";
    };
    charon-key = {
      url = "github:GDR/charon-key";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    antigravity-nix = {
      url = "github:jacopone/antigravity-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nvim-nix = {
      url = "github:GDR/nvim.nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nix-wrapper-modules.follows = "nix-wrapper-modules";
    };

    clavis = {
      url = "github:gdr/clavis";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    private-extension = {
      url = "path:./extensions/empty";
    };

    learnharness = {
      url = "github:GDR/learnharness";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    agentic = {
      url = "github:GDR/agentic";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      charon-key,
      learnharness,
      ...
    }:
    let
      lib = nixpkgs.lib.extend (
        lib: _:
        let
          hm = inputs.home-manager.lib.hm;
        in
        {
          inherit hm;
          my = import ./lib { inherit inputs lib; };
        }
      );

      forAllSystems = nixpkgs.lib.genAttrs [
        "aarch64-darwin"
        "x86_64-linux"
      ];

      overlays = forAllSystems (system: import ./overlays { inherit inputs lib system; });

      # Get flake helpers (mkDarwinConfiguration, mkNixosConfiguration, etc.)
      flakeHelpers = lib.my.mkFlakeHelpers { inherit self overlays; };

      pkgsFor =
        system:
        import nixpkgs {
          inherit system;
          overlays = overlays.${system}.list;
          config = flakeHelpers.nixpkgsConfig;
        };
    in
    {
      inherit lib;

      formatter = forAllSystems (system: (pkgsFor system).nixfmt-tree);

      packages = forAllSystems (
        system:
        import ./packages.nix {
          pkgs = pkgsFor system;
          inherit
            lib
            system
            charon-key
            learnharness
            ;
        }
      );

      devShells = forAllSystems (
        system:
        import ./devShells.nix {
          pkgs = pkgsFor system;
        }
      );

      checks = forAllSystems (
        system:
        import ./checks.nix {
          inherit
            self
            inputs
            lib
            system
            ;
          pkgs = pkgsFor system;
        }
      );

      # Host configurations
      darwinConfigurations.mac-brightstar = flakeHelpers.mkDarwinConfiguration ./hosts/machines/mac-brightstar;
      nixosConfigurations.nix-oldstar = flakeHelpers.mkNixosConfiguration ./hosts/machines/nix-oldstar;
      nixosConfigurations.nix-goldstar = flakeHelpers.mkNixosConfiguration ./hosts/machines/nix-goldstar;

      templates = {
        python = {
          path = ./templates/python;
          description = "A template for a Python project using poetry";
        };
        tex = {
          path = ./templates/tex;
          description = "A template for a LaTeX document using texlive";
        };
      };
    };
}
