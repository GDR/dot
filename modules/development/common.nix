{ config, options, pkgs, lib, ... }: with lib;
let
  cfg = config.modules.development.common;
in {
  options.modules.development.common = with types; {
    enable = mkOption {
      default = false;
      type = types.bool;
    };
  };

  config = mkIf cfg.enable {
    user.packages = with pkgs; [
      nil
      gnumake
      nodejs
      nodePackages.pnpm
      nodePackages."@nestjs/cli"
    ];
  };
}
