# SSH client configuration - reads keys and config from hostUsers
# User-level module (per-user SSH config)
{ lib, config, ... }@args:

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
  mkUserSSHConfig = userName: userCfg:
    let
      sshArray = userCfg.ssh or [ ];
      includes = userCfg.sshIncludes or [ "~/.ssh/config.d/*" ];
      settings = sshArrayToMatchBlocks userName sshArray;
    in
    {
      programs.ssh = {
        enable = true;
        enableDefaultConfig = false;
        settings = settings;
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
