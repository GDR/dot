# Flake helper functions for building Darwin and NixOS configurations
# These are extracted from flake.nix to keep it clean and declarative
{ inputs, lib, self, overlays }:

let
  inherit (inputs) nixpkgs nix-darwin home-manager nixvim vscode-server hardware;

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
  # e.g., "/path/to/modules_v2/home/core/htop.nix" -> "home.core.htop"
  # e.g., "/path/to/modules_v2/home/core/htop/htop.nix" -> "home.core.htop" (dedup)
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
        then lib.init parts # Remove last element
        else parts;
      modulePath = lib.concatStringsSep "." dedupedParts;
    in
    if isModulesV2 then modulePath else null;

  # Process module directories (like modules_v2/home) that have a default.nix
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
  modulesV2Registry = (import ./modules_v2/registry.nix { inherit lib; }).moduleRegistry or { modules = [ ]; };

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
        modulesV2Registry = modulesV2Registry;
      };
      modules = [ host-config ]
        ++ [
        home-manager.darwinModules.home-manager
        nixvim.nixDarwinModules.nixvim
      ]
        ++ mkConfigurationModules [
        ../modules_v2/home
      ]
        ++ mkSystemModules ../modules_v2/systems/all
        ++ mkSystemModules ../modules_v2/systems/darwin
        ++ [
        # Import foundational modules separately (not package modules)
        ./modules_v2/user.nix
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
        ../modules_v2/home
      ]
        ++ mkSystemModules ../modules_v2/systems/all
        ++ mkSystemModules ../modules_v2/systems/linux
        ++ [
        # Import foundational modules separately (not package modules)
        ./modules_v2/user.nix
      ];
    };
}

