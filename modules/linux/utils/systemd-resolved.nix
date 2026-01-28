{ config, options, pkgs, lib, ... }: with lib;
let
  mod = lib.my.modulePath [ "linux" "utils" "systemd-resolved" ] config;
  cfg = mod.cfg;
in
{

  options.modules.linux.utils.systemd-resolved = with types; {
    enable = mkOption {
      default = false;
      type = types.bool;
    };
  };

  config = mkIf cfg.enable {
    networking.nameservers = [ "1.1.1.1#one.one.one.one" "1.0.0.1#one.one.one.one" ];

    services.resolved = {
      enable = true;
      dnssec = "true";
      domains = [ "~." ];
      fallbackDns = [ "1.1.1.1#one.one.one.one" "1.0.0.1#one.one.one.one" ];
      dnsovertls = "true";
    };
  };
}
