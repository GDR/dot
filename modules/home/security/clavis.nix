# Clavis — Native macOS Ed25519 Keychain SSH Agent & age plugin with Touch ID
{ lib, pkgs, ... }@args:

lib.my.mkModuleV2 args {
  description = "Clavis — macOS Keychain SSH Agent & age plugin with Touch ID";
  platforms = [ "darwin" ];

  extraOptions = {
    autostart = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Automatically start clavis-agent at login via launchd";
    };
    package = lib.mkOption {
      type = lib.types.nullOr lib.types.package;
      default = pkgs.clavis;
      description = "Clavis package to install";
    };
  };

  module = cfg: {
    darwinSystems = {
      home.packages = lib.optional (cfg.package != null) cfg.package;

      launchd.user.agents.clavis-agent = lib.mkIf (cfg.autostart && cfg.package != null) {
        command = "${cfg.package}/bin/clavis-agent --daemon";
        serviceConfig = {
          Label = "com.clavis.agent";
          RunAtLoad = true;
          KeepAlive = false;
          ProcessType = "Interactive";
        };
      };
    };
  };
}
