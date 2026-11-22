# Core Home Manager module for detached Git repository sync and fanout
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.detachedRepos;
  activeRepos = lib.filterAttrs (_: r: r.enable) cfg.repos;

  isLinux = pkgs.stdenv.hostPlatform.isLinux;
  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;

  syncPkg = pkgs.detached-repo-sync;
  syncBin = lib.getExe syncPkg;

  homeDir = config.home.homeDirectory;
  stateDir = "${config.xdg.stateHome}/detached-repos";

  resolveHomePath =
    raw:
    if raw == "~" then
      homeDir
    else if lib.hasPrefix "~/" raw then
      "${homeDir}/${lib.removePrefix "~/" raw}"
    else if lib.hasPrefix "/" raw then
      raw
    else
      "${homeDir}/${lib.removePrefix "./" raw}";

  resolveWatchPaths =
    repoDir: subpaths:
    if subpaths == [ ] then
      [ repoDir ]
    else
      map (
        sub:
        let
          clean = lib.removePrefix "./" sub;
        in
        if clean == "" || clean == "." then repoDir else "${repoDir}/${clean}"
      ) subpaths;

  resolvedPaths = lib.mapAttrs (_: r: resolveHomePath r.path) activeRepos;

  configFiles = lib.mapAttrs (
    name: r:
    pkgs.writeText "detached-repo-${name}.json" (
      builtins.toJSON {
        inherit name homeDir stateDir;
        repoDir = resolvedPaths.${name};
        inherit (r)
          pullUrl
          pushUrl
          branch
          ;
        fanout = map (f: {
          inherit (f)
            from
            into
            requireFile
            recursive
            ;
        }) r.fanout;
        links = map (l: {
          inherit (l)
            from
            to
            ;
        }) r.links;
      }
    )
  ) activeRepos;

  fanoutSubmodule = lib.types.submodule {
    options = {
      from = lib.mkOption {
        type = lib.types.str;
        description = "Source directory relative to repository root.";
      };
      into = lib.mkOption {
        type = lib.types.nonEmptyListOf lib.types.str;
        description = "Target directories (relative to home.homeDirectory, ~/, or absolute).";
      };
      requireFile = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Optional filename required inside each fanout subdirectory (e.g. \"SKILL.md\").";
      };
      recursive = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Recursively discover leaf subdirectories matching requireFile and flatten into target directories.";
      };
    };
  };

  linkSubmodule = lib.types.submodule {
    options = {
      from = lib.mkOption {
        type = lib.types.str;
        description = "Source path relative to repository root.";
      };
      to = lib.mkOption {
        type = lib.types.str;
        description = "Target symlink path (relative to home.homeDirectory, ~/, or absolute).";
      };
    };
  };

  repoSubmodule = lib.types.submodule {
    options = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Whether synchronization and fan-out for this repository are enabled.";
      };
      pullUrl = lib.mkOption {
        type = lib.types.str;
        description = "Git clone/fetch URL for the repository.";
      };
      pushUrl = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Optional Git push URL configured as remote.origin.pushurl.";
      };
      path = lib.mkOption {
        type = lib.types.str;
        description = "Checkout path (relative to home.homeDirectory, ~/, or absolute).";
      };
      branch = lib.mkOption {
        type = lib.types.str;
        default = "main";
        description = "Tracked branch for fast-forward pulls.";
      };
      autoPull = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Whether to run periodic fast-forward pulls.";
      };
      interval = lib.mkOption {
        type = lib.types.ints.positive;
        default = 300;
        description = "Periodic pull interval in seconds.";
      };
      watch = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Whether to watch repository paths and re-run link on change.";
      };
      watchSubpaths = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Repository-relative subpaths to watch (empty watches repo root).";
      };
      fanout = lib.mkOption {
        type = lib.types.listOf fanoutSubmodule;
        default = [ ];
        description = "Directory fan-out rules mapping subdirectories into real target directories.";
      };
      links = lib.mkOption {
        type = lib.types.listOf linkSubmodule;
        default = [ ];
        description = "Direct symlink rules from repo-relative paths to target paths.";
      };
    };
  };
in
{
  options.programs.detachedRepos.repos = lib.mkOption {
    type = lib.types.attrsOf repoSubmodule;
    default = { };
    description = "Detached Git repositories synchronized and fanned out into the user's home directory.";
  };

  config = lib.mkIf (activeRepos != { }) {
    assertions =
      (lib.mapAttrsToList (name: _: {
        assertion =
          name != "" && name != "." && name != ".." && !(lib.hasInfix "/" name) && !(lib.hasInfix "\\" name);
        message = "programs.detachedRepos.repos.${name}: invalid repository name '${name}'.";
      }) activeRepos)
      ++ (lib.mapAttrsToList (name: r: {
        assertion = r.path != "" && lib.hasPrefix "/" resolvedPaths.${name};
        message = "programs.detachedRepos.repos.${name}.path must resolve to a non-empty absolute path.";
      }) activeRepos)
      ++ (lib.mapAttrsToList (name: r: {
        assertion = lib.all (
          sub: sub != "" && !(lib.hasPrefix "/" sub) && !(lib.elem ".." (lib.splitString "/" sub))
        ) r.watchSubpaths;
        message = "programs.detachedRepos.repos.${name}.watchSubpaths entries must be relative subpaths without '..'.";
      }) activeRepos)
      ++ (lib.mapAttrsToList (name: r: {
        assertion = lib.all (f: !f.recursive || (f.requireFile != null && f.requireFile != "")) r.fanout;
        message = "programs.detachedRepos.repos.${name}.fanout entries with recursive = true must set requireFile.";
      }) activeRepos);

    home.packages = [ syncPkg ];

    # Bootstrap after writeBoundary so target config files exist, and before OS watchers reload
    home.activation.detachedReposBootstrap =
      lib.hm.dag.entryBetween [ "reloadSystemd" "setupLaunchAgents" ] [ "writeBoundary" ]
        (
          lib.concatMapStringsSep "\n" (
            name:
            let
              configFile = configFiles.${name};
            in
            ''
              run ${lib.escapeShellArg syncBin} bootstrap ${lib.escapeShellArg "${configFile}"} || warnEcho "detached-repo-sync bootstrap failed for ${name}; continuing"
            ''
          ) (lib.attrNames activeRepos)
        );

    systemd.user = lib.mkIf isLinux {
      services = lib.mkMerge [
        (lib.mapAttrs' (
          name: _:
          lib.nameValuePair "detached-repo-${name}-pull" {
            Unit.Description = "Pull and link detached repository ${name}";
            Service = {
              Type = "oneshot";
              ExecStart = "${syncBin} pull ${configFiles.${name}}";
            };
          }
        ) (lib.filterAttrs (_: r: r.autoPull) activeRepos))

        (lib.mapAttrs' (
          name: _:
          lib.nameValuePair "detached-repo-${name}-link" {
            Unit.Description = "Relink fan-out for detached repository ${name}";
            Service = {
              Type = "oneshot";
              ExecStart = "${syncBin} link ${configFiles.${name}}";
            };
          }
        ) (lib.filterAttrs (_: r: r.watch) activeRepos))
      ];

      timers = lib.mapAttrs' (
        name: r:
        lib.nameValuePair "detached-repo-${name}-pull" {
          Unit.Description = "Periodic pull timer for detached repository ${name}";
          Timer = {
            OnBootSec = "1m";
            OnUnitActiveSec = "${toString r.interval}s";
            Unit = "detached-repo-${name}-pull.service";
          };
          Install.WantedBy = [ "timers.target" ];
        }
      ) (lib.filterAttrs (_: r: r.autoPull) activeRepos);

      paths = lib.mapAttrs' (
        name: r:
        lib.nameValuePair "detached-repo-${name}-link" {
          Unit.Description = "Watch paths for detached repository ${name}";
          Path = {
            PathChanged = resolveWatchPaths resolvedPaths.${name} r.watchSubpaths;
            Unit = "detached-repo-${name}-link.service";
          };
          Install.WantedBy = [ "paths.target" ];
        }
      ) (lib.filterAttrs (_: r: r.watch) activeRepos);
    };

    launchd.agents = lib.mkIf isDarwin (
      lib.mapAttrs' (
        name: r:
        let
          subcommand = if r.autoPull then "pull" else "link";
        in
        lib.nameValuePair "detached-repo-${name}" {
          enable = true;
          config = {
            ProgramArguments = [
              syncBin
              subcommand
              "${configFiles.${name}}"
            ];
            RunAtLoad = true;
            KeepAlive = false;
            ProcessType = "Background";
          }
          // lib.optionalAttrs r.autoPull {
            StartInterval = r.interval;
          }
          // lib.optionalAttrs r.watch {
            WatchPaths = resolveWatchPaths resolvedPaths.${name} r.watchSubpaths;
            ThrottleInterval = 2;
          };
        }
      ) (lib.filterAttrs (_: r: r.autoPull || r.watch) activeRepos)
    );
  };
}
