# Git configuration - reads user info and signing key from hostUsers
# Cross-platform system module (Linux + Darwin)
{ lib, config, system, ... }@args:

let
  isDarwin = system == "aarch64-darwin" || system == "x86_64-darwin";
  homeDir = if isDarwin then "/Users" else "/home";

  # Get enabled users
  enabledUsers = lib.filterAttrs (_: u: u.enable) config.hostUsers;

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
      gitKeys = lib.filter (k: lib.elem "git" (k.purpose or [ ])) keys;
      defaultGitKey = lib.findFirst (k: k.isDefault or false) null gitKeys;
    in
    if defaultGitKey != null then defaultGitKey
    else if gitKeys != [ ] then lib.head gitKeys
    else null;

  # Build Git config for a user
  mkUserGitConfig = cfg: userName: userCfg:
    let
      gitKey = getGitKey userCfg;
      signingKeyPath = if gitKey != null then keyPath userName gitKey else null;
    in
    {
      programs.git = {
        enable = true;

        signing = lib.mkIf (signingKeyPath != null) {
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
lib.my.mkSystemModuleV2 args {
  namespace = "all";
  description = "Git configuration (reads from hostUsers)";

  extraOptions = {
    editor = lib.mkOption {
      type = lib.types.str;
      default = "nvim";
      description = "Default Git editor";
    };
  };

  module = cfg: {
    home-manager.users = lib.mapAttrs
      (userName: userCfg: mkUserGitConfig cfg userName userCfg)
      enabledUsers;
  };
}
