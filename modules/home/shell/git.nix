# Git configuration - reads user info and signing key from hostUsers
{ lib, ... }:

lib.my.mkFeature {
  description = "Git configuration (reads from hostUsers)";
  platforms = [ "linux" "darwin" ];

  extraOptions = {
    editor = lib.mkOption {
      type = lib.types.str;
      default = "nvim";
      description = "Default Git editor";
    };
  };

  homeModule = { config, osConfig, pkgs, lib, featureCfg, userName, ... }:
    let
      isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
      homeDir = if isDarwin then "/Users" else "/home";
      userCfg = osConfig.hostUsers.${userName} or { };

      # Build key path from key config (public key for signing)
      keyPath = key:
        let
          keyExt = {
            "rsa" = "id_rsa";
            "ed25519" = "id_ed25519";
            "ecdsa" = "id_ecdsa";
            "ecdsa-sk" = "id_ecdsa_sk";
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

      gitKey = getGitKey userCfg;
      signingKeyPath = if gitKey != null then keyPath gitKey else null;

      clavisModuleEnabled = lib.my.isFeatureEnabledForUser {
        config = osConfig;
        inherit userName;
        modulePath = "home.security.clavis";
      };
      clavisEnabled = isDarwin && ((userCfg.clavisAgent.enable or false) || clavisModuleEnabled);
      bwEnabled = userCfg.bitwardenSshAgent.enable or false;
      hasAgent = clavisEnabled || bwEnabled;

      # Dynamic signing via SSH agent when no static key is specified
      useDynamicSigning = signingKeyPath == null && hasAgent;
    in
    {
      programs.git = {
        enable = true;

        signing = {
          key = if signingKeyPath != null then signingKeyPath else null;
          signByDefault = signingKeyPath != null || useDynamicSigning;
        };

        settings = {
          user = {
            name = userCfg.fullName;
            email = userCfg.email;
          };
          core.editor = featureCfg.editor or "nvim";
          push.autoSetupRemote = true;
          pull.rebase = true;
          init.defaultBranch = "main";
          gpg = {
            format = "ssh";
          } // lib.optionalAttrs useDynamicSigning {
            ssh.defaultKeyCommand = "sh -c 'echo key::$(ssh-add -L | head -1)'";
          };
        };
      };
    };
}
