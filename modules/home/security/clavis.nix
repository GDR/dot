# Clavis — Native macOS Ed25519 Keychain SSH Agent & age plugin with Touch ID
{ lib, pkgs, ... }:

lib.my.mkFeature {
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

  homeModuleDarwin = { lib, featureCfg, ... }: {
    home.packages = lib.optional ((featureCfg.package or null) != null) featureCfg.package;

    launchd.agents.clavis-agent = lib.mkIf ((featureCfg.autostart or true) && (featureCfg.package or null) != null) {
      enable = true;
      config = {
        ProgramArguments = [ "${featureCfg.package}/bin/clavis-agent" "--daemon" ];
        Label = "com.clavis.agent";
        RunAtLoad = true;
        KeepAlive = false;
        ProcessType = "Interactive";
      };
    };
  };
}
