# SSH client configuration - reads keys and config from hostUsers
# User-level module (per-user SSH config)
{ lib, config, pkgs, ... }@args:

let
  # Get enabled users
  enabledUsers = lib.filterAttrs (_: u: u.enable) (config.hostUsers or { });

  # Convert SSH array to matchBlocks attrs format
  sshArrayToMatchBlocks = userName: sshArray:
    let
      # Convert a single SSH host entry to a settings block
      # Uses upstream OpenSSH directive names as required by programs.ssh.settings
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
        } // entry.extraOptions;
    in
    # Convert array to attrs: [{ host = "*"; ... }] -> { "*" = { ... }; }
    lib.listToAttrs (map
      (entry: {
        name = entry.host;
        value = sshEntryToSettingsBlock entry;
      })
      sshArray);

  # Build SSH config for a user
  mkUserSSHConfig = pkgs: userName: userCfg:
    let
      sshArray = userCfg.ssh or [ ];
      includes = userCfg.sshIncludes or [ "~/.ssh/config.d/*" ];
      baseSettings = sshArrayToMatchBlocks userName sshArray;

      homePrefix = if pkgs.stdenv.isDarwin then "/Users" else "/home";

      # Bitwarden SSH Agent integration
      bwCfg = userCfg.bitwardenSshAgent or { };
      bwEnabled = bwCfg.enable or false;
      defaultBwSocket =
        if pkgs.stdenv.isDarwin
        then "~/Library/Containers/com.bitwarden.desktop/Data/.bitwarden-ssh-agent.sock"
        else "~/.bitwarden/ssh-agent.sock";
      bwSocket = if (bwCfg.socketPath or null != null) then bwCfg.socketPath else defaultBwSocket;

      # GPG SSH Agent integration
      gpgEnabled = lib.my.shouldEnableModule { inherit config; modulePath = "home.security.gpg"; };
      gpgSocket = "${homePrefix}/${userName}/.gnupg/S.gpg-agent.ssh";

      agentSocket =
        if bwEnabled then bwSocket
        else if gpgEnabled then gpgSocket
        else null;

      agentEnabled = bwEnabled || gpgEnabled;

      # Find default key for user if present
      userKeys = userCfg.keys or [ ];
      defaultKey = lib.findFirst (k: k.isDefault or false) null userKeys;
      defaultIdentityFile =
        if defaultKey != null
        then "~/.ssh/${defaultKey.name}_${defaultKey.type}"
        else null;

      baseControlSettings = {
        "*" = {
          ControlMaster = "auto";
          ControlPath = "~/.ssh/sockets/%r@%h:%p";
          ControlPersist = "3m";
          IdentitiesOnly = "yes";
        } // lib.optionalAttrs (defaultIdentityFile != null) {
          IdentityFile = defaultIdentityFile;
        };
      };

      # Inject ControlMaster & IdentityAgent into '*' host setting if enabled
      settings =
        if agentEnabled then
          lib.recursiveUpdate (lib.recursiveUpdate baseControlSettings { "*" = { IdentityAgent = agentSocket; }; }) baseSettings
        else
          lib.recursiveUpdate baseControlSettings baseSettings;

      # Write declared public keys to ~/.ssh/<name>_id_<type>.pub
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

      # Pre-activation: remove regular file ~/.ssh/config so Home Manager can recreate the symlink with fresh config
      home.activation.removeOldSshConfig = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
        sshConfig="$HOME/.ssh/config"
        if [ -f "$sshConfig" ] && [ ! -L "$sshConfig" ]; then
          rm -f "$sshConfig"
        fi
      '';

      # SSH refuses symlinks to world-readable Nix store files.
      # Replace the symlink with a proper copy at 0600 after each switch.
      # Also ensure ~/.ssh/sockets exists for ControlMaster multiplexing.
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
in
lib.my.mkModuleV2 args {
  description = "SSH client configuration (reads keys and config from hostUsers)";

  module = _: {
    allSystems = {
      # Apply config to all enabled users
      home-manager.users = lib.mapAttrs (mkUserSSHConfig pkgs) enabledUsers;
    };
  };
}
