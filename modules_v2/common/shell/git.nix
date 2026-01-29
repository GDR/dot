{ config, pkgs, lib, system, _modulePath, ... }: with lib;
let
  mkModule = lib.my.mkModule system;
  modulePath = _modulePath;
  moduleTags = [ "shell" "core" ];

  pathParts = splitString "." modulePath;
  cfg = foldl (acc: part: acc.${part}) config.modules pathParts;
in
{
  meta = lib.my.mkModuleMeta {
    tags = moduleTags;
    description = "Git version control";
  };

  options = lib.my.mkModuleOptions modulePath {
    enable = mkOption {
      default = false;
      type = types.bool;
    };
    userName = mkOption {
      type = types.str;
      description = "Git user name";
    };
    userEmail = mkOption {
      type = types.str;
      description = "Git user email";
    };
    signingKey = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Path to SSH signing key (public key)";
    };
  };

  config =
    let
      shouldEnable = lib.my.shouldEnableModule { inherit config modulePath moduleTags; };
    in
    mkIf shouldEnable (mkModule {
      allSystems.home.programs.git = {
        enable = true;
        settings = {
          user = {
            name = cfg.userName;
            email = cfg.userEmail;
          } // optionalAttrs (cfg.signingKey != null) {
            signingkey = cfg.signingKey;
          };
          core.editor = "nvim";
          push.autoSetupRemote = true;
          gpg.format = "ssh";
          commit = {
            gpgsign = true;
            gpg.program = "gpg";
          };
        };
      };
    });
}
