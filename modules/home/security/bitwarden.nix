# Bitwarden - secure password manager
{ lib, ... }:

lib.my.mkFeature {
  description = "Bitwarden password manager";

  extraOptions = {
    sshAgent = {
      enable = lib.mkEnableOption "Bitwarden Desktop SSH Agent integration";
      socketPath = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Custom Bitwarden SSH Agent socket path. If null, uses platform default.";
      };
    };
  };

  homeModule = { pkgs, ... }: {
    home.packages = [ pkgs.bitwarden-desktop ];
  };
}
