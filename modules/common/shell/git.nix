{ config, options, pkgs, lib, ... }: with lib;
let
  cfg = config.modules.common.shell.git;
in
{
  options.modules.common.shell.git = with types; {
    enable = mkOption {
      default = false;
      type = types.bool;
    };
  };

  config = mkIf cfg.enable {
    home.programs = {
      git = {
        enable = true;
        userName = "Damir Garifullin";
        userEmail = "gosugdr@gmail.com";
        extraConfig = {
          core.editor = "nvim";

          # Auto setup remote branch if not exists
          push = { autoSetupRemote = true; };

          gpg = {
            format = "ssh";
          };

          commit = {
            gpgsign = true;
            gpg.program = "gpg";
          };
        };
      };
    };
  };
}
