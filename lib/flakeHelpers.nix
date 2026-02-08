# Flake helper functions for building Darwin and NixOS configurations
# These are extracted from flake.nix to keep it clean and declarative
{ inputs, lib, self, overlays }:

let
  inherit (inputs) nixpkgs nix-darwin home-manager nixvim vscode-server hardware charon-key;

  # Helper to wrap a module file and filter out 'meta' attribute
  # NixOS modules don't allow arbitrary top-level attributes
  # Accept all possible module arguments and forward them
  # computedModulePath is passed for modules modules
  wrapModuleFile = filePath: computedModulePath: { config ? null, options ? null, pkgs ? null, lib ? null, system ? null, inputs ? null, overlays ? null, home-manager ? null, hardware ? null, nixpkgs ? null, ... }@args:
    let
      # Import the actual module with all arguments plus computed path
      originalModule = import filePath (args // { _modulePath = computedModulePath; });
      # Filter out meta - keep everything else
      filtered = lib.filterAttrs (name: _: name != "meta") originalModule;
    in
    filtered;

  # Compute module path from file path for modules
  # e.g., "/path/to/modules/home/cli/htop.nix" -> "home.cli.htop"
  # e.g., "/path/to/modules/home/cli/htop/htop.nix" -> "home.cli.htop" (dedup)
  computeModulePath = filePath:
    let
      pathStr = toString filePath;
      # Check if this is a modules module
      isModulePath = lib.hasInfix "modules/" pathStr;
      # Extract path after modules/
      afterModules = lib.last (lib.splitString "modules/" pathStr);
      # Remove .nix and split into parts
      withoutNix = lib.removeSuffix ".nix" afterModules;
      parts = lib.splitString "/" withoutNix;
      # If last two parts are the same (e.g., htop/htop), deduplicate
      fileName = lib.last parts;
      parentDir = if lib.length parts >= 2 then lib.elemAt parts (lib.length parts - 2) else null;
      dedupedParts =
        if parentDir == fileName
        then lib.init parts # Remove last element
        else parts;
      modulePath = lib.concatStringsSep "." dedupedParts;
    in
    if isModulePath then modulePath else null;

  # Process module directories (like modules/home) that have a default.nix
  # exporting a .modules list
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

  # Wrap system modules (systems/all, systems/darwin, systems/linux)
  # These get auto-discovered and wrapped to receive _modulePath
  mkSystemModules = moduleDirPath:
    let
      moduleTree = lib.my.recursiveDirs moduleDirPath;
      moduleFiles = lib.my.flattenModules moduleTree;
    in
    map
      (filePath:
        wrapModuleFile filePath (computeModulePath filePath)
      )
      moduleFiles;

  # Build registry during import time (not module evaluation time)
  modulesRegistry = (import ../modules/_core/registry.nix { inherit lib; }).moduleRegistry or { modules = [ ]; };

in
{
  inherit wrapModuleFile computeModulePath mkConfigurationModules mkSystemModules;

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
        nixvim.nixDarwinModules.nixvim
        charon-key.darwinModules.default
      ]
        ++ mkConfigurationModules [
        ../modules/home
      ]
        ++ mkSystemModules ../modules/systems/all
        ++ mkSystemModules ../modules/systems/darwin
        ++ [
        # Import foundational modules separately (not package modules)
        ../modules/_core/user.nix
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
        nixvim.nixosModules.nixvim
        vscode-server.nixosModules.default
        charon-key.nixosModules.default
      ]
        ++ mkConfigurationModules [
        ../modules/home
      ]
        ++ mkSystemModules ../modules/systems/all
        ++ mkSystemModules ../modules/systems/linux
        ++ [
        # Import foundational modules separately (not package modules)
        ../modules/_core/user.nix
      ];
    };
}
