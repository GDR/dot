# Bitwarden - secure password manager
# https://mynixos.com/nixpkgs/package/bitwarden-desktop
{ config, pkgs, lib, system, _modulePath, ... }: with lib;
let
  mkModule = lib.my.mkModule system config;
  modulePath = _modulePath;
  moduleTags = [ "security" ];
in
{
  meta = lib.my.mkModuleMeta {
    tags = moduleTags;
    platforms = [ "linux" "darwin" ];
    description = "Bitwarden password manager";
  };

  options = lib.my.mkModuleOptions modulePath {
    enable = mkOption {
      default = false;
      type = types.bool;
    };
  };

  config =
    let
      shouldEnable = lib.my.shouldEnableModule { inherit config modulePath moduleTags; };
    in
    mkIf shouldEnable (mkModule {
      nixosSystems.home.packages = [ pkgs.bitwarden-desktop ];
      darwinSystems.homebrew.casks = [ "bitwarden" ];
    });
}
