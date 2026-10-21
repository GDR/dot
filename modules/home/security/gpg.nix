# GPG & GPG-Agent configuration
{ config, lib, pkgs, ... }@args:

let
  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
  pinentryTouchId = pkgs.pinentry-touchid or (pkgs.callPackage ../../../pkgs/pinentry-touchid { });

  clavisModuleEnabled = isDarwin && (lib.my.shouldEnableModule { inherit config; modulePath = "home.security.clavis"; });
  enabledUsers = lib.filterAttrs (_: u: u.enable) (config.hostUsers or { });
  hasHigherPrioritySshAgent =
    clavisModuleEnabled
    || lib.any (u: (isDarwin && (u.clavisAgent.enable or false)) || (u.bitwardenSshAgent.enable or false)) (lib.attrValues enabledUsers);
in
lib.my.mkModuleV2 args {
  description = "GPG key agent and pinentry configuration";
  platforms = [ "linux" "darwin" ];

  extraOptions = {
    enableSshSupport = lib.mkOption {
      type = lib.types.nullOr lib.types.bool;
      default = null;
      description = "Enable GPG agent SSH support (defaults to false when Clavis or Bitwarden SSH agent is active)";
    };
  };

  module = cfg: {
    allSystems = {
      programs.gpg.enable = true;
      home.packages = [ pkgs.gnupg ];

      services.gpg-agent = {
        enable = true;
        enableSshSupport = if cfg.enableSshSupport != null then cfg.enableSshSupport else !hasHigherPrioritySshAgent;
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
