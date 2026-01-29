# SSH client configuration - reads keys from hostUsers
{ config, pkgs, lib, system, _modulePath, ... }: with lib;
let
  mkModule = lib.my.mkModule system;
  modulePath = _modulePath;
  moduleTags = [ "shell" "core" ];
  
  pathParts = splitString "." modulePath;
  cfg = foldl (acc: part: acc.${part}) config.modules pathParts;

  isDarwin = system == "aarch64-darwin" || system == "x86_64-darwin";
  homeDir = if isDarwin then "/Users" else "/home";

  # Get enabled users
  enabledUsers = filterAttrs (_: u: u.enable) config.hostUsers;

  # Build key path from key config
  # e.g., { name = "goldstar"; type = "rsa"; } -> ~/.ssh/goldstar_id_rsa
  keyPath = userName: key: 
    let
      keyExt = {
        "rsa" = "id_rsa";
        "ed25519" = "id_ed25519";
        "ecdsa" = "id_ecdsa";
      }.${key.type};
    in "${homeDir}/${userName}/.ssh/${key.name}_${keyExt}";

  # Get default key for a user
  getDefaultKey = user:
    let
      keys = user.keys or [];
      defaultKey = findFirst (k: k.isDefault or false) null keys;
    in if defaultKey != null then defaultKey else (if keys != [] then head keys else null);

  # Check if key is for SSH (purpose contains "ssh")
  isSSHKey = key: elem "ssh" (key.purpose or [ "git" "ssh" ]);

  # Build SSH config for a user
  mkUserSSHConfig = userName: userCfg:
    let
      defaultKey = getDefaultKey userCfg;
      sshKeys = filter isSSHKey (userCfg.keys or []);
    in {
      programs.ssh = {
        enable = true;
        
        matchBlocks = {
          # Default identity for all hosts
          "*" = mkIf (defaultKey != null) {
            identityFile = keyPath userName defaultKey;
            extraOptions.AddKeysToAgent = "yes";
          };
          # GitHub config
          "github.com" = {
            user = "git";
          } // optionalAttrs (defaultKey != null) {
            identityFile = keyPath userName defaultKey;
          };
        };
        
        includes = [ "~/.ssh/config.d/*" ];
      } // optionalAttrs isDarwin {
        extraConfig = "UseKeychain yes";
      };
    };
in
{
  options.modules.common.shell.ssh = {
    enable = mkOption {
      default = false;
      type = types.bool;
      description = "Enable SSH client configuration";
    };
  };

  config = let
    shouldEnable = lib.my.shouldEnableModule { inherit config modulePath moduleTags; };
  in mkIf shouldEnable {
    # Configure SSH for each enabled user
    home-manager.users = mapAttrs (userName: userCfg: 
      mkUserSSHConfig userName userCfg
    ) enabledUsers;
  };
}
