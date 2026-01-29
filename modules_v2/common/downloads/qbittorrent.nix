# qBittorrent torrent client
{ config, pkgs, lib, system, _modulePath, ... }: with lib;
let
  mkModule = lib.my.mkModule system config;
  modulePath = _modulePath;
  moduleTags = [ "downloads" ];

  pathParts = splitString "." modulePath;
  cfg = foldl (acc: part: acc.${part}) config.modules pathParts;
in
{
  meta = lib.my.mkModuleMeta {
    tags = moduleTags;
    platforms = [ "linux" "darwin" ];
    description = "qBittorrent torrent client";
  };

  options = lib.my.mkModuleOptions modulePath {
    enable = mkOption {
      default = false;
      type = types.bool;
    };
  };

  config = mkIf cfg.enable (mkModule {
    nixosSystems.home.packages = [ pkgs.qbittorrent ];
    darwinSystems.homebrew.casks = [ "qbittorrent" ];
  });
}
