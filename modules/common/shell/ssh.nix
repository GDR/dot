{ config, options, pkgs, lib, system, ... }: with lib;
let
  cfg = config.modules.common.shell.ssh;
  mkModule = lib.my.mkModule system;

  # Fetch the authorized keys file
  authorizedKeysFile = pkgs.fetchurl {
    url = "https://github.com/gdr.keys";
    sha256 = "sha256-15L1KA6Iu4lB//M+NYuyvPTTKg6Da8YQkstBI/Oc87A=";
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
            user = "dgarifullin";
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
