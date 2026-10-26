# SSH client configuration - reads keys and config from hostUsers
# User-level module (per-user SSH config)
{ lib, ... }:

let
  # Convert SSH array to matchBlocks attrs format
  sshArrayToMatchBlocks = userName: sshArray:
    let
      sshEntryToSettingsBlock = entry:
        lib.optionalAttrs (entry.user != null)
          {
            User = entry.user;
          } // lib.optionalAttrs (entry.identityFile != null) {
          IdentityFile = entry.identityFile;
        } // lib.optionalAttrs (entry.forwardAgent != null) {
          ForwardAgent = entry.forwardAgent;
        } // lib.optionalAttrs (entry.port != null) {
          Port = entry.port;
        } // lib.optionalAttrs (entry.hostname != null) {
          Hostname = entry.hostname;
        } // (entry.extraConfig or { });
    in
    lib.listToAttrs (map
      (entry: {
        name = entry.host;
        value = sshEntryToSettingsBlock entry;
      })
      sshArray);
in
lib.my.mkFeature {
  description = "SSH client configuration (reads keys and config from hostUsers)";

  homeModule = { config, osConfig, pkgs, lib, userName, ... }:
    let
      userCfg = osConfig.hostUsers.${userName} or { };
      sshArray = userCfg.ssh or [ ];
      includes = userCfg.sshIncludes or [ "~/.ssh/config.d/*" ];
      baseSettings = sshArrayToMatchBlocks userName sshArray;

      isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
      homePrefix = if isDarwin then "/Users" else "/home";

      # Clavis SSH Agent integration (macOS-only; guard against home.security.enable cascade on Linux)
      clavisModuleEnabled = lib.my.isFeatureEnabledForUser {
        config = osConfig;
        inherit userName;
        modulePath = "home.security.clavis";
      };
      clavisCfg = userCfg.clavisAgent or { };
      clavisEnabled = isDarwin && ((clavisCfg.enable or false) || clavisModuleEnabled);
      defaultClavisSocket = "${homePrefix}/${userName}/.ssh/clavis.sock";
      clavisSocket = if (clavisCfg.socketPath or null != null) then clavisCfg.socketPath else defaultClavisSocket;

      # Bitwarden SSH Agent integration
      bwCfg = userCfg.bitwardenSshAgent or { };
      bwEnabled = bwCfg.enable or false;
      defaultBwSocket =
        if isDarwin
        then "~/Library/Containers/com.bitwarden.desktop/Data/.bitwarden-ssh-agent.sock"
        else "~/.bitwarden/ssh-agent.sock";
      bwSocket = if (bwCfg.socketPath or null != null) then bwCfg.socketPath else defaultBwSocket;

      agentSocket =
        if clavisEnabled then clavisSocket
        else if bwEnabled then bwSocket
        else null;

      agentEnabled = clavisEnabled || bwEnabled;

      # Find default key for user if present
      userKeys = userCfg.keys or [ ];
      defaultKey = lib.findFirst (k: k.isDefault or false) null userKeys;
      defaultIdentityFile =
        if defaultKey != null
        then "~/.ssh/${defaultKey.name}_${defaultKey.type}"
        else null;

      baseControlSettings = {
        "*" = {
          IdentitiesOnly = if agentEnabled then "no" else "yes";
          AddKeysToAgent = if agentEnabled then "no" else "yes";
        } // lib.optionalAttrs (defaultIdentityFile != null) {
          IdentityFile = defaultIdentityFile;
        };
        "github.com" = {
          AddressFamily = "inet";
        };
      };

      settings =
        if agentEnabled then
          lib.recursiveUpdate (lib.recursiveUpdate baseControlSettings { "*" = { IdentityAgent = agentSocket; }; }) baseSettings
        else
          lib.recursiveUpdate baseControlSettings baseSettings;

      pubKeyFiles = lib.listToAttrs (map
        (key: {
          name = ".ssh/${key.name}_id_${key.type}.pub";
          value = {
            text = key.publicKey;
          };
        })
        (builtins.filter (k: (k.publicKey or null) != null) (userCfg.keys or [ ])));
    in
    {
      programs.ssh = {
        enable = true;
        enableDefaultConfig = false;
        settings = settings;
        includes = includes;
      };

      home.file = pubKeyFiles;

      home.sessionVariables = lib.optionalAttrs agentEnabled {
        SSH_AUTH_SOCK = agentSocket;
      };

      programs.zsh.envExtra = lib.mkIf agentEnabled ''
        if [ -z "''${SSH_CONNECTION-}" ]; then
          export SSH_AUTH_SOCK="${agentSocket}"
        fi
      '';

      home.activation.setLaunchdSshAuthSock = lib.mkIf (isDarwin && agentEnabled) (
        lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          /bin/launchctl setenv SSH_AUTH_SOCK "${agentSocket}" || true
        ''
      );

      home.activation.removeOldSshConfig = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
        sshConfig="$HOME/.ssh/config"
        if [ -f "$sshConfig" ] && [ ! -L "$sshConfig" ]; then
          rm -f "$sshConfig"
        fi
      '';

      home.activation.fixSshConfigPerms = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        mkdir -p "$HOME/.ssh/sockets"
        chmod 700 "$HOME/.ssh/sockets"
        sshConfig="$HOME/.ssh/config"
        if [ -L "$sshConfig" ]; then
          target=$(readlink "$sshConfig")
          rm "$sshConfig"
          cp "$target" "$sshConfig"
          chmod 600 "$sshConfig"
        fi
      '';
    };
}
