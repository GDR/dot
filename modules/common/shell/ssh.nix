{ config, options, pkgs, lib, system, ... }: with lib;
let
  mod = lib.my.modulePath [ "common" "shell" "ssh" ] config;
  cfg = mod.cfg;
  mkModule = lib.my.mkModule system;

  # Fetch the authorized keys file
  authorizedKeysFile = pkgs.fetchurl {
    url = "https://github.com/gdr.keys";
    sha256 = "sha256-DcE0zt+znkeNc+Jbq5EMmHS6QUcG9P88m7ZEnun2JTk=";
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
      home.packages = [
        pkgs.charon-key
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
        includes = [
          "~/.ssh/config.d/*"
        ];
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
      home.programs.ssh = {
        enable = true;
        matchBlocks = {
          "*" = {
            identityFile = config.security-keys.signingkey;
          };
        };
      };

      # Create a wrapper script for charon-key in a secure location
      environment.etc."ssh/charon-key-wrapper" = {
        text = ''
          #!/bin/sh
          exec ${pkgs.charon-key}/bin/charon-key --usernames gdr --quiet "$@"
        '';
        mode = "0755";
        user = "root";
        group = "root";
      };

      services.openssh = {
        enable = true;
        settings = {
          PermitRootLogin = "no";
          PasswordAuthentication = true;
          AuthorizedKeysCommand = "/etc/ssh/charon-key-wrapper";
          AuthorizedKeysCommandUser = "nobody";
        };
        extraConfig = ''
          AllowUsers dgarifullin
        '';
      };
    };
  });
}
