# Nix garbage collection - cross-platform system module
{ lib, ... }@args:

lib.my.mkSystemModuleV2 args {
  namespace = "all";
  description = "Automatic Nix garbage collection";

  extraOptions = {
    olderThan = lib.mkOption {
      type = lib.types.str;
      default = "30d";
      description = "Delete generations older than this";
    };
  };

  module = cfg: {
    nix.gc = {
      automatic = true;
      options = "--delete-older-than ${cfg.olderThan}";
    };
  };

  # Platform-specific scheduling
  moduleLinux = _: {
    nix.gc.dates = "weekly";
  };

  moduleDarwin = _: {
    nix.gc.interval = { Weekday = 0; Hour = 3; Minute = 0; };
  };
}
