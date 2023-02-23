{ config, options, pkgs, lib, ... }: with lib;
let
  cfg = config.modules.shell.ssh;
in {
  options.modules.shell.ssh = with types; {
    enable = mkOption {
      default = false;
      type = types.bool;
    };
  };

  config = mkIf cfg.enable {
    services.openssh = {
      enable = true;
      permitRootLogin = "no";
      passwordAuthentication = false;
    };
  };
}
