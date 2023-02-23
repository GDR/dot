{ config, options, pkgs, lib, ... }: with lib;
let
  cfg = config.modules.desktop.development.gcc;
in {
  options.modules.desktop.development.gcc = with types; {
    enable = mkOption {
      default = false;
      type = types.bool;
    };
  };

  config = mkIf cfg.enable {
    user.packages = with pkgs; [
      gcc
      clang
      gdb
    ];
  };
}
