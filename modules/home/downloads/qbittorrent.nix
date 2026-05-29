# qBittorrent torrent client
{ lib, pkgs, ... }@args:

lib.my.mkModuleV2 args {
  platforms = [ "linux" "darwin" ];
  description = "qBittorrent torrent client";
  module = {
    # nixosSystems: Linux only — on Darwin install via Homebrew cask instead.
    # allSystems would incorrectly include Darwin and break home-manager app alias creation.
    nixosSystems.home.packages = [ pkgs.qbittorrent ];
  };
}
