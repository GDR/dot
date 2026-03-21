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
    vantage = {
      url = "github:GDR/vantage";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "vantage/nixpkgs";
    };
  };

  outputs = inputs@{ self, nixpkgs, charon-key, deploy-rs, ... }:
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
      nixosConfigurations.nix-oldstar = flakeHelpers.mkNixosConfiguration ./hosts/machines/nix-oldstar;
      nixosConfigurations.nix-goldstar = flakeHelpers.mkNixosConfiguration ./hosts/machines/nix-goldstar;

      # ── deploy-rs: remote NixOS deployment ──────────────────────────
      deploy = {
        # Build on the remote host itself (avoids x86_64→aarch64 cross issues)
        remoteBuild = true;

        nodes.nix-oldstar = {
          hostname = "nix-oldstar";
          sshUser = "dgarifullin";
          sshOpts = [ "-t" ]; # allocate TTY so sudo can prompt for password
          profiles.system = {
            user = "root";
            path = deploy-rs.lib.x86_64-linux.activate.nixos
              self.nixosConfigurations.nix-oldstar;
          };
        };

        nodes.nix-goldstar = {
          hostname = "nix-goldstar";
          sshUser = "dgarifullin";
          sshOpts = [ "-t" ]; # allocate TTY so sudo can prompt for password
          profiles.system = {
            user = "root";
            path = deploy-rs.lib.x86_64-linux.activate.nixos
              self.nixosConfigurations.nix-goldstar;
          };
        };
      };

      # Expose the deploy-rs CLI so `nix run .#deploy-rs` works from this flake
      apps = nixpkgs.lib.genAttrs [ "aarch64-darwin" "x86_64-linux" ] (system: {
        deploy-rs = deploy-rs.apps.${system}.default;
      });

      # Checks: verify deploy-rs schema is well-formed (runs on nix flake check)
      checks = nixpkgs.lib.genAttrs [ "x86_64-linux" ] (system:
        deploy-rs.lib.${system}.deployChecks self.deploy
      );

      templates = {
        python = {
          path = ./templates/python;
          description = "A template for a Python project using poetry";
        };
      };
    };
}
