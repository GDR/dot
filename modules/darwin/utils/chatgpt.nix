{ config, options, lib, pkgs, ... }: with lib;
let
  cfg = config.modules.darwin.utils.chatgpt;
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
