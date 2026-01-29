{ config, options, pkgs, lib, system, ... }: with lib;
let
  mod = lib.my.modulePath [ "common" "vpn" "vless" ] config;
  cfg = mod.cfg;
  mkModule = lib.my.mkModule system;
in
{

  options.modules.common.vpn.vless = with types; {
    enable = mkOption {
      default = false;
      type = types.bool;
      description = "Enable VLESS VPN client (GUI-only)";
    };
  };

  config = mkIf cfg.enable (mkModule {
    common = {
      home.packages = with pkgs; [
        throne
        xray # Nekoray uses xray as backend for VLESS support
      ];
    };
    linux = {
      programs.throne = {
        enable = true;
        tunMode.enable = true;
      };
    };
    darwin = {
      homebrew = {
        casks = [
          "nekoray"
        ];
      };
    };
  });
}
