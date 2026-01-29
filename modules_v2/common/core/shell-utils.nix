# Essential shell utilities
{ config, pkgs, lib, system, _modulePath, ... }: with lib;
let
  mkModule = lib.my.mkModule system config;
  modulePath = _modulePath;
  moduleTags = [ "core" ];

  pathParts = splitString "." modulePath;
  cfg = foldl (acc: part: acc.${part}) config.modules pathParts;
in
{
  meta = lib.my.mkModuleMeta {
    tags = moduleTags;
    platforms = [ "linux" "darwin" ];
    description = "Essential shell utilities (bat, fzf, wget, direnv)";
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
      allSystems = {
        home.packages = with pkgs; [
          bat
          fzf
          neofetch
          wget
        ];
        programs.direnv = {
          enable = true;
          nix-direnv.enable = true;
        };
      };
    });
}
