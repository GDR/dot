{ config, options, pkgs, lib, ... }: with lib;
let
  cfg = config.modules.common.utils.bazel;
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
