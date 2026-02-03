# macOS-specific SSH configuration (Keychain integration, Touch ID)
# Darwin-only system module
{ lib, config, system, ... }@args:

let
  # Get enabled users
  enabledUsers = lib.filterAttrs (_: u: u.enable) (config.hostUsers or { });

  # Build macOS SSH config for a user
  mkUserDarwinSSHConfig = userName: userCfg:
    let
      allKeys = userCfg.keys or [ ];
    in
    lib.optionalAttrs (allKeys != [ ]) {
      # macOS Keychain integration
      programs.ssh.extraConfig = "UseKeychain yes";

      # Remove keys from SSH agent on activation to force Touch ID prompt each time
      # With AddKeysToAgent=no, SSH will prompt for passphrase (Touch ID) instead of using cached keys
      home.activation.clearSSHAgent = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        # Clear SSH agent to force fresh authentication (Touch ID) each time
        ssh-add -D 2>/dev/null || true
      '';
    };
in
lib.my.mkSystemModuleV2 args {
  namespace = "darwin";
  description = "macOS-specific SSH configuration (Keychain integration, Touch ID)";

  module = _: {
    home-manager.users = lib.mapAttrs mkUserDarwinSSHConfig enabledUsers;
  };
}

