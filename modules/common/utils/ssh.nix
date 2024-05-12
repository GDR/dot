{ config, options, lib, pkgs, ... }: with lib;
let
  cfg = config.modules.utils.ssh;
in
{
  options.modules.utils.ssh = with types; {
    enable = mkOption {
      default = false;
      type = types.bool;
    };
  };

  config = mkIf cfg.enable {
    services.openssh = {
      enable = true;
    };
    systemd.services.fetchGithubKeys = {
      description = "Fetch GitHub SSH keys";
      after = [ "network.target" ];
      serviceConfig = {
        Type = "oneshot";
        User = "root";
        ExecStart = ''
          ${pkgs.curl}/bin/curl -s https://github.com/gdr.keys > /etc/ssh/authorized_keys
        '';
      };
    };
    systemd.timers.fetchGithubKeys = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "5min";
        OnUnitActiveSec = "5min";
      };
    };
  };
}
