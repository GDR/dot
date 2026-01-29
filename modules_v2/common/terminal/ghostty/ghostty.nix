# Ghostty terminal emulator
{ config, pkgs, lib, system, _modulePath, ... }: with lib;
let
  mkModule = lib.my.mkModule system;
  modulePath = _modulePath;
  moduleTags = [ "terminal" ];

  pathParts = splitString "." modulePath;
  cfg = foldl (acc: part: acc.${part}) config.modules pathParts;
in
{
  meta = lib.my.mkModuleMeta {
    tags = moduleTags;
    description = "Ghostty terminal emulator";
  };

  options = lib.my.mkModuleOptions modulePath {
    enable = mkOption {
      default = false;
      type = types.bool;
    };
  };

  config = let
    shouldEnable = lib.my.shouldEnableModule { inherit config modulePath moduleTags; };
  in mkIf shouldEnable (mkMerge [
    # Package installation (via mkModule alias system)
    (mkModule {
      nixosSystems.home.packages = [ pkgs.ghostty ];
      darwinSystems.homebrew.casks = [ "ghostty" ];
    })

    # Dotfiles symlink (linked to repo for live editing without rebuild)
    {
      home-manager.users = lib.my.mkDotfilesSymlink {
        inherit config;
        path = "ghostty";
        source = ./dotfiles;
      };
    }
  ]);
}
