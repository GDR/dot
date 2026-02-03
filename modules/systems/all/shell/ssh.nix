# SSH client configuration - reads keys from hostUsers
# Cross-platform system module (Linux + Darwin)
{ lib, config, system, ... }@args:

let
  isDarwin = system == "aarch64-darwin" || system == "x86_64-darwin";
  homeDir = if isDarwin then "/Users" else "/home";

  # Get enabled users
  enabledUsers = lib.filterAttrs (_: u: u.enable) config.hostUsers;

  # Build key path from key config
  keyPath = userName: key:
    let
      keyExt = {
        "rsa" = "id_rsa";
        "ed25519" = "id_ed25519";
        "ecdsa" = "id_ecdsa";
        "ecdsa-sk" = "id_ecdsa_sk";
      }.${key.type};
    in
    "${homeDir}/${userName}/.ssh/${key.name}_${keyExt}";

  # Get default key for a user
  getDefaultKey = user:
    let
      keys = user.keys or [ ];
      defaultKey = lib.findFirst (k: k.isDefault or false) null keys;
    in
    if defaultKey != null then defaultKey
    else (if keys != [ ] then lib.head keys else null);

  # Build SSH config for a user
  mkUserSSHConfig = userName: userCfg:
    let
      defaultKey = getDefaultKey userCfg;
      allKeys = userCfg.keys or [ ];
      keyPaths = map (key: keyPath userName key) allKeys;
    in
    {
      programs.ssh = {
        enable = true;
        enableDefaultConfig = false;

        matchBlocks = {
          "*" = {
            extraOptions.AddKeysToAgent = "yes";
          } // lib.optionalAttrs (defaultKey != null) {
            identityFile = keyPath userName defaultKey;
          };
          "github.com" = {
            user = "git";
          } // lib.optionalAttrs (defaultKey != null) {
            identityFile = keyPath userName defaultKey;
          };
        };

        includes = [ "~/.ssh/config.d/*" ];
      } // lib.optionalAttrs isDarwin {
        # macOS Keychain integration
        extraConfig = "UseKeychain yes";
      };
    } // lib.optionalAttrs (isDarwin && keyPaths != [ ]) {
      # Add all keys to macOS Keychain on activation
      home.activation.addKeysToKeychain = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        echo "Adding SSH keys to macOS Keychain..."
        ${lib.concatMapStringsSep "\n" (keyPath: ''
          if [ -f "${keyPath}" ]; then
            ssh-add --apple-use-keychain "${keyPath}" 2>/dev/null || true
          fi
        '') keyPaths}
      '';
    };
in
lib.my.mkSystemModuleV2 args {
  namespace = "all";
  description = "SSH client configuration (reads keys from hostUsers)";

  module = _: {
    home-manager.users = lib.mapAttrs
      (userName: userCfg: mkUserSSHConfig userName userCfg)
      enabledUsers;
  };

  # Linux-only: start SSH agent system-wide (Darwin uses Keychain)
  moduleLinux = _: {
    programs.ssh.startAgent = true;
  };
}
