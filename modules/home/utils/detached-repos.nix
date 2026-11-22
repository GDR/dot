# Detached Git repositories — reusable auto-sync and fanout feature
{ lib, ... }:

lib.my.mkFeature {
  description = "Detached Git repositories with auto-sync and fanout";
  # Opt-in only: host-level `home.utils.enable = true` must not activate empty/arbitrary repos
  cascade = false;

  extraOptions = {
    repos = lib.mkOption {
      type = lib.types.attrsOf lib.types.anything;
      default = { };
      description = "Detached repository specifications forwarded to programs.detachedRepos.repos.";
      example = {
        notes = {
          pullUrl = "https://github.com/example/notes.git";
          path = "Documents/notes";
        };
      };
    };
  };

  homeModule =
    { lib, featureCfg, ... }:
    {
      programs.detachedRepos.repos = lib.mkIf ((featureCfg.repos or { }) != { }) featureCfg.repos;
    };
}
