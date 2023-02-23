{ config, options, pkgs, lib, ... }: with lib;
let
  cfg = config.modules.shell.acpi;
in {
  options.modules.shell.acpi = with types; {
    enable = mkOption {
      default = false;
      type = types.bool;
    };
  };

  config = mkIf cfg.enable {
    user.packages = with pkgs; [  ];
  };
}
