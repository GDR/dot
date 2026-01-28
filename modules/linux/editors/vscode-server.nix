{ config, options, pkgs, lib, ... }: with lib;
let
  mod = lib.my.modulePath [ "common" "editors" "vscode-server" ] config;
  cfg = mod.cfg;
in
{
  options.modules.common.editors.vscode-server = with types; {
    enable = mkOption {
      default = false;
      type = types.bool;
    };
  };

  config = mkIf cfg.enable {
    services.vscode-server.enable = true;
    programs.nix-ld.enable = true;
  };
}
