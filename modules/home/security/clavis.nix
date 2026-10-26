{ lib, pkgs ? null, ... }:

lib.my.mkFeature {
  description = "Clavis — macOS Keychain SSH Agent & age plugin with Touch ID";
  platforms = [ "darwin" ];

  homeOptions = {
    autostart = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Automatically start clavis-agent at login via launchd";
    };
    package = lib.mkOption {
      type = lib.types.nullOr lib.types.package;
      default = if pkgs != null && pkgs ? clavis then pkgs.clavis else null;
      description = "Clavis package to install";
    };
  };

  homeModuleDarwin = { pkgs, lib, featureCfg, ... }:
    let
      package = if (featureCfg.package or null) != null then featureCfg.package else pkgs.clavis or null;
    in
    {
      home.packages = lib.optional (package != null) package;

      launchd.agents.clavis-agent = lib.mkIf ((featureCfg.autostart or true) && package != null) {
        enable = true;
        config = {
          ProgramArguments = [ "${package}/bin/clavis-agent" "--daemon" ];
          Label = "com.clavis.agent";
          RunAtLoad = true;
          KeepAlive = false;
          ProcessType = "Interactive";
        };
      };
    };
}
