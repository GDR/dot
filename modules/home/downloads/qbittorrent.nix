# qBittorrent torrent client
{ lib, pkgs, ... }@args:

lib.my.mkModuleV2 args {
  platforms = [ "linux" "darwin" ];
  description = "qBittorrent torrent client";
  module = {
    allSystems.home.packages = [ pkgs.qbittorrent ];
  };
}
