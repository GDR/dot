# Cursor IDE - AI-powered code editor
{ config, pkgs, lib, system, _modulePath, ... }: with lib;
let
  mkModule = lib.my.mkModule system;
  modulePath = _modulePath;
  moduleTags = [ "editors-ui" ];

  pathParts = splitString "." modulePath;
  cfg = foldl (acc: part: acc.${part}) config.modules pathParts;
in
{
  meta = lib.my.mkModuleMeta {
    tags = moduleTags;
    platforms = [ "linux" "darwin" ];
    description = "Cursor IDE - AI-powered code editor";
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
      nixosSystems.home.packages = [ pkgs.code-cursor ];
      darwinSystems.homebrew.casks = [ "cursor" ];
    });
}
