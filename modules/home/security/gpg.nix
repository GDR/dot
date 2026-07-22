# GPG & GPG-Agent configuration
{ lib, pkgs, ... }@args:

lib.my.mkModuleV2 args {
  description = "GPG key agent and pinentry configuration";
  platforms = [ "linux" "darwin" ];

  module = {
    allSystems = {
      programs.gpg.enable = true;

      services.gpg-agent = {
        enable = true;
        enableSshSupport = true;
        defaultCacheTtl = 600;
        maxCacheTtl = 7200;
        defaultCacheTtlSsh = 600;
        maxCacheTtlSsh = 7200;
      };
    };

    darwinSystems = {
      services.gpg-agent = {
        pinentry.package = pkgs.pinentry_mac;
      };
    };

    nixosSystems = {
      services.gpg-agent = {
        pinentry.package = pkgs.pinentry-curses;
      };
    };
  };
}
