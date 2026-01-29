# SSH client configuration - reads keys from hostUsers
# Cross-platform system module (Linux + Darwin)
{ config, pkgs, lib, ... }: with lib;
let
  isDarwin = pkgs.stdenv.isDarwin;
  homeDir = if isDarwin then "/Users" else "/home";

  cfg = config.systemAll.shell.ssh;

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
    in
    "${homeDir}/${userName}/.ssh/${key.name}_${keyExt}";

  # Get default key for a user
  getDefaultKey = user:
    let
      keys = user.keys or [ ];
      defaultKey = findFirst (k: k.isDefault or false) null keys;
    in
    if defaultKey != null then defaultKey else (if keys != [ ] then head keys else null);

  # Build SSH config for a user
  mkUserSSHConfig = userName: userCfg:
    let
      defaultKey = getDefaultKey userCfg;
    in
    {
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
  options.systemAll.shell.ssh = {
    enable = mkEnableOption "SSH client configuration (reads keys from hostUsers)";
  };

  config = mkIf cfg.enable {
    # Start SSH agent system-wide (Linux only, Darwin uses Keychain)
    programs.ssh.startAgent = !isDarwin;

    # Configure SSH for each enabled user
    home-manager.users = mapAttrs
      (userName: userCfg:
        mkUserSSHConfig userName userCfg
      )
      enabledUsers;
  };
}
