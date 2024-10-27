{ config, options, pkgs, lib, system, ... }: with lib;
let
  cfg = config.modules.common.shell.ssh;
  mkModule = lib.my.mkModule system;

  # Fetch the authorized keys file
  authorizedKeysFile = pkgs.fetchurl {
    url = "https://github.com/gdr.keys";
    sha256 = "sha256-VUm1uR2PWacLZFqw5XkzSg/R0TlIXHV4zJTs5gg5yIs=";
  };
in
{
  options.modules.common.shell.ssh = with types; {
    enable = mkOption {
      default = false;
      type = types.bool;
    };
    server.enable = mkOption {
      default = false;
      type = types.bool;
    };
  };

  config = mkIf cfg.enable (mkModule {
    common = {
      openssh.authorizedKeys.keyFiles = [
        authorizedKeysFile
      ];
      home.programs.ssh = {
        enable = true;
        addKeysToAgent = "yes";
        matchBlocks = {
          "*" = {
            identityFile = config.security-keys.signingkey;
          };
          "github.com" = {
            user = "gdr";
          };
          "nix-germany" = {
            host = "10.0.10.61";
          };
        };
      };
    };
    darwin = {
      home.programs.ssh = {
        extraConfig = ''
          UseKeychain yes
        '';
      };
    };
    linux = {
      services.openssh = {
        enable = true;
        settings = {
          PermitRootLogin = "no";
          PasswordAuthentication = false;
        };
        extraConfig = ''
          AllowUsers dgarifullin
        '';
      };
    };
  });
}
