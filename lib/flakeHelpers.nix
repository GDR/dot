# Flake helper functions for building Darwin and NixOS configurations
# These are extracted from flake.nix to keep it clean and declarative
{
  inputs,
  lib,
  self,
  overlays,
}:

let
  inherit (inputs)
    nixpkgs
    nix-darwin
    home-manager
    vscode-server
    hardware
    charon-key
    sops-nix
    ;

  # Helper to wrap a system module file and pass computed _modulePath while preserving functionArgs and _file
  # System modules in modules/systems are passed through directly
  wrapModuleFile =
    filePath: computedModulePath:
    let
      imported = import filePath;
      attachFile =
        mod: if lib.isAttrs mod && !(mod ? _file) then mod // { _file = toString filePath; } else mod;
      defaultModuleArgs = {
        config = true;
        options = true;
        pkgs = true;
        lib = true;
        system = true;
        inputs = true;
        overlays = true;
        home-manager = true;
        hardware = true;
        nixpkgs = true;
      };
    in
    if lib.isFunction imported then
      lib.setFunctionArgs (args: attachFile (imported (args // { _modulePath = computedModulePath; }))) (
        defaultModuleArgs // (builtins.removeAttrs (lib.functionArgs imported) [ "_modulePath" ])
      )
    else
      attachFile imported;

  # Wrap system modules (systems/all, systems/darwin, systems/linux)
  # These get auto-discovered and wrapped to receive _modulePath
  mkSystemModules =
    moduleDirPath:
    let
      moduleTree = lib.my.recursiveDirs moduleDirPath;
      moduleFiles = lib.my.flattenModules moduleTree;
    in
    map (filePath: wrapModuleFile filePath (lib.my.computeModulePath filePath)) moduleFiles;

  # Build registry during import time (not module evaluation time)
  modulesRegistry =
    (import ../modules/_core/registry.nix { inherit lib inputs; }).moduleRegistry or {
      modules = [ ];
    };

  privateExtension = inputs.private-extension.dotExtension or { };

  nixpkgsConfig = {
    allowUnfree = true;
    nvidia.acceptLicense = true;
    # bitwarden-desktop (2026.x) still depends on electron_39, which nixpkgs
    # marks as EOL/insecure. Allow it explicitly until nixpkgs bumps the
    # bitwarden-desktop recipe to a newer electron version.
    permittedInsecurePackages = [ "electron-39.8.10" ];
  };

  resolveHostSpec =
    defaultSystem: spec:
    if
      builtins.isAttrs spec
      && !(spec ? _file)
      && !(spec ? options)
      && !(spec ? config)
      && spec ? hostConfig
    then
      {
        hostConfig = spec.hostConfig;
        system = spec.system or defaultSystem;
      }
    else
      {
        hostConfig = spec;
        system = defaultSystem;
      };

in
{
  inherit wrapModuleFile mkSystemModules nixpkgsConfig;
  inherit (lib.my) computeModulePath;

  # Build a Darwin (macOS) system configuration (accepts path/module or { hostConfig, system? })
  mkDarwinConfiguration =
    hostSpec:
    let
      resolved = resolveHostSpec "aarch64-darwin" hostSpec;
      inherit (resolved) hostConfig system;
    in
    nix-darwin.lib.darwinSystem {
      inherit system;
      specialArgs = {
        inherit
          self
          inputs
          lib
          overlays
          system
          ;
        modulesRegistry = modulesRegistry;
      };
      modules = [
        hostConfig
        {
          nixpkgs = {
            config = nixpkgsConfig;
            overlays = overlays.${system}.list;
          };
        }
        home-manager.darwinModules.home-manager
        charon-key.darwinModules.default
        sops-nix.darwinModules.sops
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

  # Build a NixOS (Linux) system configuration (accepts path/module or { hostConfig, system? })
  mkNixosConfiguration =
    hostSpec:
    let
      resolved = resolveHostSpec "x86_64-linux" hostSpec;
      inherit (resolved) hostConfig system;
    in
    nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = {
        inherit
          self
          inputs
          lib
          overlays
          system
          hardware
          ;
        modulesRegistry = modulesRegistry;
      };
      modules = [
        hostConfig
        {
          nixpkgs = {
            config = nixpkgsConfig;
            overlays = overlays.${system}.list;
          };
        }
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
