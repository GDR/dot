# GPG & GPG-Agent configuration
{ config, lib, pkgs, ... }@args:

let
  pinentryTouchId = pkgs.pinentry-touchid or (pkgs.callPackage ../../../pkgs/pinentry-touchid { });
in
lib.my.mkModuleV2 args {
  description = "GPG key agent and pinentry configuration";
  platforms = [ "linux" "darwin" ];

  module = {
    allSystems = {
      programs.gpg.enable = true;
      home.packages = [ pkgs.gnupg ];

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
      home.packages = [ pinentryTouchId pkgs.pinentry_mac ];

      services.gpg-agent = {
        pinentry.package = pinentryTouchId;
        extraConfig = ''
          pinentry-program ${pinentryTouchId}/bin/pinentry-touchid
        '';
      };

      launchd.user.agents.gpg-agent = {
        command = "${pkgs.gnupg}/bin/gpgconf --launch gpg-agent";
        serviceConfig = {
          RunAtLoad = true;
          KeepAlive = true;
        };
      };
    };

    nixosSystems = {
      services.gpg-agent = {
        pinentry.package = pkgs.pinentry-curses;
      };
    };
  };
}
