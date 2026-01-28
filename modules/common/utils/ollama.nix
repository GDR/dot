{ config, options, pkgs, lib, system, ... }: with lib;
let
  mod = lib.my.modulePath [ "common" "utils" "ollama" ] config;
  cfg = mod.cfg;
  mkModule = lib.my.mkModule system;
in
{

  options.modules.common.utils.ollama = with types; {
    enable = mkOption {
      default = false;
      type = types.bool;
    };
  };

  config = mkIf cfg.enable (mkModule {
    darwin = {
      homebrew.casks = [
        "ollama"
      ];
    };
    linux = {
      services.ollama = {
        enable = true;
        port = 11434;
        host = "0.0.0.0";
      };
    };
  });
}
