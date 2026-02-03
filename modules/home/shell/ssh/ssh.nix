# SSH client configuration - reads keys and config from hostUsers
# User-level module (per-user SSH config)
{ lib, config, ... }@args:

let
  # Get enabled users
  enabledUsers = lib.filterAttrs (_: u: u.enable) (config.hostUsers or { });

  # Convert SSH array to matchBlocks attrs format
  sshArrayToMatchBlocks = userName: sshArray:
    let
      # Convert a single SSH host entry to match block
      sshEntryToMatchBlock = entry:
        let
          baseBlock = lib.optionalAttrs (entry.user != null)
            {
              inherit (entry) user;
            } // lib.optionalAttrs (entry.identityFile != null) {
            inherit (entry) identityFile;
          } // lib.optionalAttrs (entry.forwardAgent != null) {
            inherit (entry) forwardAgent;
          } // lib.optionalAttrs (entry.port != null) {
            inherit (entry) port;
          } // lib.optionalAttrs (entry.hostname != null) {
            inherit (entry) hostname;
          } // lib.optionalAttrs (entry.extraOptions != { }) {
            extraOptions = entry.extraOptions;
          };
        in
        baseBlock;
    in
    # Convert array to attrs: [{ host = "*"; ... }] -> { "*" = { ... }; }
    lib.listToAttrs (map
      (entry: {
        name = entry.host;
        value = sshEntryToMatchBlock entry;
      })
      sshArray);

  # Build SSH config for a user
  mkUserSSHConfig = userName: userCfg:
    let
      sshArray = userCfg.ssh or [ ];
      includes = userCfg.sshIncludes or [ "~/.ssh/config.d/*" ];
      matchBlocks = sshArrayToMatchBlocks userName sshArray;
    in
    {
      programs.ssh = {
        enable = true;
        enableDefaultConfig = false;
        matchBlocks = matchBlocks;
        includes = includes;
      };
    };
in
lib.my.mkModuleV2 args {
  description = "SSH client configuration (reads keys and config from hostUsers)";

  module = _: {
    allSystems = {
      # Apply config to all enabled users
      home-manager.users = lib.mapAttrs mkUserSSHConfig enabledUsers;
    };
  };
}
