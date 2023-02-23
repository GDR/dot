{ config, options, pkgs, lib, ... }: with lib;
let
  cfg = config.modules.shell.common;
in {
  options.modules.shell.common = with types; {
    enable = mkOption {
      default = false;
      type = types.bool;
    };
  };

  config = mkIf cfg.enable {
    user.packages = with pkgs; [
      acpi
      exa
      xorg.xbacklight
      tmux
    ];
  };
}
