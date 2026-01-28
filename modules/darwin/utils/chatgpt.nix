{ config, options, lib, pkgs, ... }: with lib;
let
  mod = lib.my.modulePath [ "darwin" "utils" "chatgpt" ] config;
  cfg = mod.cfg;
in
{

  options.modules.darwin.utils.chatgpt = with types; {
    enable = mkOption {
      default = false;
      type = types.bool;
    };
  };

  config = mkIf cfg.enable {
    homebrew = {
      casks = [
        "chatgpt"
      ];
    };
  };
}
