{ config, options, pkgs, lib, ... }: with lib;
let
  cfg = config.modules.common.editors.idea;

  # Override IDEA Ultimate to use system JDK instead of problematic JCEF JDK
  idea-ultimate-fixed = pkgs.jetbrains.idea-ultimate.override {
    jdk = pkgs.jetbrains.jdk; # Use system JDK21 instead of jetbrains-jdk-jcef
  };
in
{
  options.modules.common.editors.idea = with types; {
    enable = mkOption {
      default = false;
      type = types.bool;
    };
  };

  config = mkIf cfg.enable {
    home.packages = [
      idea-ultimate-fixed
    ];
  };
}
