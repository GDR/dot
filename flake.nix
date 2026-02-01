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

      # Helper to wrap a module file and filter out 'meta' attribute
      # NixOS modules don't allow arbitrary top-level attributes
      # Accept all possible module arguments and forward them
      # computedModulePath is passed for modules_v2 modules
      wrapModuleFile = filePath: computedModulePath: { config ? null, options ? null, pkgs ? null, lib ? null, system ? null, inputs ? null, overlays ? null, home-manager ? null, hardware ? null, nixpkgs ? null, ... }@args:
        let
          # Import the actual module with all arguments plus computed path
          originalModule = import filePath (args // { _modulePath = computedModulePath; });
          # Filter out meta - keep everything else
          filtered = lib.filterAttrs (name: _: name != "meta") originalModule;
        in
        filtered;

      # Compute module path from file path for modules_v2
      # e.g., "/path/to/modules_v2/common/core/htop.nix" -> "common.core.htop"
      # e.g., "/path/to/modules_v2/common/core/htop/htop.nix" -> "common.core.htop" (dedup)
      computeModulePath = filePath:
        let
          pathStr = toString filePath;
          # Check if this is a modules_v2 module
          isModulesV2 = lib.hasInfix "modules_v2/" pathStr;
          # Extract path after modules_v2/
          afterModulesV2 = lib.last (lib.splitString "modules_v2/" pathStr);
          # Remove .nix and split into parts
          withoutNix = lib.removeSuffix ".nix" afterModulesV2;
          parts = lib.splitString "/" withoutNix;
          # If last two parts are the same (e.g., htop/htop), deduplicate
          fileName = lib.last parts;
          parentDir = if lib.length parts >= 2 then lib.elemAt parts (lib.length parts - 2) else null;
          dedupedParts =
            if parentDir == fileName
            then lib.init parts  # Remove last element
            else parts;
          modulePath = lib.concatStringsSep "." dedupedParts;
        in
        if isModulesV2 then modulePath else null;

      mkConfigurationModules = lib.concatMap
        (moduleDirPath:
          let
            moduleDir = import moduleDirPath { inherit inputs lib overlays; };
            modules = moduleDir.modules or [ ];
          in
          # Wrap each module file to filter meta
          map
            (filePath:
              if builtins.isString filePath then
              # Return a function that wraps the module
                wrapModuleFile filePath (computeModulePath filePath)
              else
                filePath
            )
            modules
        );

      mkDarwinConfiguration = host-config:
        let
          system = "aarch64-darwin";
          # Build registry during import time (not module evaluation time)
          modulesV2Registry = (import ./lib/modules_v2/registry.nix { inherit lib; }).moduleRegistry or { modules = [ ]; };
        in
        nix-darwin.lib.darwinSystem {
          inherit system;
          specialArgs = {
            inherit self inputs lib overlays system vscode-server;
            modulesV2Registry = modulesV2Registry;
          };
          modules = [ host-config ]
            ++ [
            home-manager.darwinModules.home-manager
            nixvim.nixDarwinModules.nixvim
          ]
            ++ mkConfigurationModules [
            ./modules_v2/common
          ]
            ++ [
            ./modules_v2/_systemAll
            ./modules_v2/_systemDarwin
          ]
            ++ [
            # Import foundational modules separately (not package modules)
            ./lib/modules_v2/tags.nix
            ./lib/modules_v2/user.nix
          ];
        };

      mkNixosConfiguration = host-config:
        let
          system = "x86_64-linux";
          # Build registry during import time (not module evaluation time)
          modulesV2Registry = (import ./lib/modules_v2/registry.nix { inherit lib; }).moduleRegistry or { modules = [ ]; };
        in
        nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = {
            inherit self inputs lib overlays system hardware;
            modulesV2Registry = modulesV2Registry;
          };
          modules = [ host-config ]
            ++ [
            # Core NixOS modules from inputs
            home-manager.nixosModules.home-manager
            nixvim.nixosModules.nixvim
            vscode-server.nixosModules.default
          ]
            ++ mkConfigurationModules [
            ./modules_v2/common
          ]
            ++ [
            ./modules_v2/_systemAll
            ./modules_v2/_systemLinux
          ]
            ++ [
            # Import foundational modules separately (not package modules)
            ./lib/modules_v2/tags.nix
            ./lib/modules_v2/user.nix
          ];
        };
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

      # Temporarily disabled for testing - will re-enable after migration
      darwinConfigurations.mac-brightstar = mkDarwinConfiguration ./hosts/mac-brightstar;
      # darwinConfigurations.mac-blackstar = mkDarwinConfiguration ./hosts/mac-blackstar;
      # nixosConfigurations.nix-germany = mkNixosConfiguration ./hosts/nix-germany;
      nixosConfigurations.nix-goldstar = mkNixosConfiguration ./hosts/nix-goldstar;

      templates = {
        python = {
          path = ./templates/python;
          description = "A template for a Python project using poetry";
        };
      };
    };
}
