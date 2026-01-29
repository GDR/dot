# KeePassXC password manager
{ config, pkgs, lib, system, _modulePath, ... }: with lib;
let
  mkModule = lib.my.mkModule system config;
  modulePath = _modulePath;
  moduleTags = [ "security" ];

  pathParts = splitString "." modulePath;
  cfg = foldl (acc: part: acc.${part}) config.modules pathParts;
in
{
  meta = lib.my.mkModuleMeta {
    tags = moduleTags;
    platforms = [ "linux" "darwin" ];
    description = "KeePassXC password manager";
  };

  options = lib.my.mkModuleOptions modulePath {
    enable = mkOption {
      default = false;
      type = types.bool;
    };
  };

  config = mkIf cfg.enable (mkModule {
    nixosSystems.home.packages = [ pkgs.keepassxc ];
    darwinSystems.homebrew.casks = [ "keepassxc" ];
  });
}
