# Git configuration - reads user info and signing key from hostUsers
# Cross-platform system module (Linux + Darwin)
{ config, pkgs, lib, ... }: with lib;
let
  isDarwin = pkgs.stdenv.isDarwin;
  homeDir = if isDarwin then "/Users" else "/home";

  cfg = config.systemAll.shell.git;

  # Get enabled users
  enabledUsers = filterAttrs (_: u: u.enable) config.hostUsers;

  # Build key path from key config (public key for signing)
  keyPath = userName: key:
    let
      keyExt = {
        "rsa" = "id_rsa";
        "ed25519" = "id_ed25519";
        "ecdsa" = "id_ecdsa";
      }.${key.type};
    in
    "${homeDir}/${userName}/.ssh/${key.name}_${keyExt}.pub";

  # Get default git signing key for a user (key with "git" in purpose)
  getGitKey = user:
    let
      keys = user.keys or [ ];
      # First try to find a key with "git" purpose that's default
      gitKeys = filter (k: elem "git" (k.purpose or [ ])) keys;
      defaultGitKey = findFirst (k: k.isDefault or false) null gitKeys;
    in
    if defaultGitKey != null then defaultGitKey
    else if gitKeys != [ ] then head gitKeys
    else null;

  # Build Git config for a user
  mkUserGitConfig = userName: userCfg:
    let
      gitKey = getGitKey userCfg;
      signingKeyPath = if gitKey != null then keyPath userName gitKey else null;
    in
    {
      programs.git = {
        enable = true;

        signing = mkIf (signingKeyPath != null) {
          key = signingKeyPath;
          signByDefault = true;
        };

        settings = {
          user = {
            name = userCfg.fullName;
            email = userCfg.email;
          };
          core.editor = cfg.editor;
          push.autoSetupRemote = true;
          init.defaultBranch = "main";
          gpg.format = "ssh";
        };
      };
    };
in
{
  options.systemAll.shell.git = {
    enable = mkEnableOption "Git configuration (reads from hostUsers)";

    editor = mkOption {
      type = types.str;
      default = "nvim";
      description = "Default Git editor";
    };
  };

  config = mkIf cfg.enable {
    # Configure Git for each enabled user
    home-manager.users = mapAttrs
      (userName: userCfg:
        mkUserGitConfig userName userCfg
      )
      enabledUsers;
  };
}
