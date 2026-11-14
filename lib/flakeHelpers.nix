# Flake helper functions for building Darwin and NixOS configurations
# These are extracted from flake.nix to keep it clean and declarative
{ inputs, lib, self, overlays }:

let
  inherit (inputs) nixpkgs nix-darwin home-manager vscode-server hardware charon-key sops-nix;

  # Helper to wrap a module file and pass computed _modulePath
  # Features in modules/home are compiled centrally by the feature compiler in user.nix, returning { }
  # System modules in modules/systems are passed through directly
  wrapModuleFile = filePath: computedModulePath: { config ? null, options ? null, pkgs ? null, lib ? null, system ? null, inputs ? null, overlays ? null, home-manager ? null, hardware ? null, nixpkgs ? null, ... }@args:
    let
      # Import the actual module with all arguments plus computed path
      imported = import filePath;
      originalModule =
        if lib.isFunction imported
        then imported (args // { _modulePath = computedModulePath; })
        else imported;
    in
    if (originalModule._type or "") == "feature" then
    # Features are handled centrally by the feature compiler in user.nix
      { }
    else
      originalModule;

  # Wrap system modules (systems/all, systems/darwin, systems/linux)
  # These get auto-discovered and wrapped to receive _modulePath
  mkSystemModules = moduleDirPath:
    let
      moduleTree = lib.my.recursiveDirs moduleDirPath;
      moduleFiles = lib.my.flattenModules moduleTree;
    in
    map
      (filePath:
        wrapModuleFile filePath (lib.my.computeModulePath filePath)
      )
      moduleFiles;

  # Build registry during import time (not module evaluation time)
  modulesRegistry = (import ../modules/_core/registry.nix { inherit lib inputs; }).moduleRegistry or { modules = [ ]; };

  privateExtension = inputs.private-extension.dotExtension or { };

in
{
  inherit wrapModuleFile mkSystemModules;
  inherit (lib.my) computeModulePath;

  # Build a Darwin (macOS) system configuration
  mkDarwinConfiguration = host-config:
    let
      system = "aarch64-darwin";
    in
    nix-darwin.lib.darwinSystem {
      inherit system;
      specialArgs = {
        inherit self inputs lib overlays system vscode-server;
        modulesRegistry = modulesRegistry;
      };
      modules = [ host-config ]
        ++ [
        home-manager.darwinModules.home-manager
        charon-key.darwinModules.default
        # antigravity-nix exposes only packages/overlays (no darwinModules);
        # google-antigravity* are injected via overlays/additions.nix
      ]
        ++ (privateExtension.systemModules.all or [ ])
        ++ (privateExtension.systemModules.darwin or [ ])
        ++ mkSystemModules ../modules/systems/all
        ++ mkSystemModules ../modules/systems/darwin
        ++ [
        # Import foundational modules separately (not package modules)
        ../modules/_core/user.nix
        ../modules/_core/theme.nix
        ../modules/_core/system.nix
      ];
    };

  # Build a NixOS (Linux) system configuration
  mkNixosConfiguration = host-config:
    let
      system = "x86_64-linux";
    in
    nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = {
        inherit self inputs lib overlays system hardware;
        modulesRegistry = modulesRegistry;
      };
      modules = [ host-config ]
        ++ [
        # Core NixOS modules from inputs
        home-manager.nixosModules.home-manager
        vscode-server.nixosModules.default
        charon-key.nixosModules.default
        sops-nix.nixosModules.sops
      ]
        ++ (privateExtension.systemModules.all or [ ])
        ++ (privateExtension.systemModules.linux or [ ])
        ++ mkSystemModules ../modules/systems/all
        ++ mkSystemModules ../modules/systems/linux
        ++ [
        # Import foundational modules separately (not package modules)
        ../modules/_core/user.nix
        ../modules/_core/theme.nix
        ../modules/_core/system.nix
      ];
    };
}
