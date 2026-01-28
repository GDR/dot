{ config, options, pkgs, lib, ... }: with lib;
let
  mod = lib.my.modulePath [ "common" "utils" "bazel" ] config;
  cfg = mod.cfg;
in
{

  options.modules.common.utils.bazel = with types; {
    enable = mkOption {
      default = false;
      type = types.bool;
    };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      bazel_7
      bazelisk
      bazel-buildtools
    ];
  };
}
