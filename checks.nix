{
  self,
  inputs,
  pkgs,
  lib,
  system,
}:

let
  user = "dgarifullin";
  hasPackage =
    expectedName: packages:
    lib.any (
      package:
      let
        pname = package.pname or (builtins.parseDrvName (package.name or "")).name;
      in
      pname == expectedName || (package.name or "") == expectedName
    ) packages;

  neovimConfig = inputs.nvim-nix.checks.${system}.neovim-config;
  moduleRegistry = (import ./modules/_core/registry.nix { inherit lib inputs; }).moduleRegistry;

  dslUnitTests =
    let
      schema = lib.my.buildFeatureOptionTree {
        featureCatalog = moduleRegistry.features;
        knownModulePaths = map (m: m.path) moduleRegistry.allModules;
      };
      forwardTree =
        optTree: schemaTree:
        lib.concatMapAttrs (
          k: v:
          if lib.isOption v then
            if k == "enable" then
              { }
            else
              let
                gOpt = optTree.${k};
                explicitlySet = gOpt.isDefined && gOpt.highestPrio < 1500;
              in
              {
                ${k} = lib.mkIf explicitlySet (lib.mkOverride 1100 gOpt.value);
              }
          else
            { ${k} = forwardTree optTree.${k} v; }
        ) schemaTree;

      evalDsl =
        extraMod:
        lib.evalModules {
          modules = [
            (
              { options, ... }:
              {
                options.modules = schema;
                options.hostUsers = lib.mkOption {
                  type = lib.types.attrsOf (
                    lib.types.submoduleWith {
                      modules = [
                        {
                          options.modules = lib.mkOption {
                            type = lib.types.submoduleWith {
                              modules = [
                                {
                                  options = schema;
                                  config = forwardTree options.modules schema;
                                }
                              ];
                            };
                            default = { };
                          };
                        }
                      ];
                    }
                  );
                  default = { };
                };
              }
            )
            extraMod
          ];
        };

      forwardingEval = evalDsl {
        modules.home.shell.git.editor = "helix";
        modules.home.terminal.ghostty.dotfilesLive = true;
        modules.home.utils.detached-repos.repos.notes = {
          pullUrl = "https://example.com/notes.git";
          path = "notes";
        };
        hostUsers.u1.modules.home.cli.htop.enable = true;
        hostUsers.u2.modules.home.shell.git.editor = lib.mkDefault "kak";
      };

      typoEval =
        builtins.tryEval
          (evalDsl {
            hostUsers.u.modules.home.nonexistent.enable = true;
          }).config.hostUsers.u.modules.home;

      syntheticMap = {
        "home.a" = {
          requires = [ "home.b" ];
          platforms = [
            "linux"
            "darwin"
          ];
          cascade = true;
        };
        "home.b" = {
          requires = [ "home.c" ];
          platforms = [
            "linux"
            "darwin"
          ];
          cascade = true;
        };
        "home.c" = {
          requires = [ ];
          platforms = [
            "linux"
            "darwin"
          ];
          cascade = true;
        };
        "home.req" = {
          requires = [ "home.utils.obsidian" ];
          platforms = [
            "linux"
            "darwin"
          ];
          cascade = true;
        };
        "home.utils.obsidian" = {
          requires = [ ];
          platforms = [
            "linux"
            "darwin"
          ];
          cascade = true;
        };
        "home.desktop.hyprland" = {
          requires = [ ];
          platforms = [ "linux" ];
          cascade = false;
        };
      };
      syntheticCatalog = lib.mapAttrsToList (path: meta: meta // { inherit path; }) syntheticMap;
      syntheticCfg = {
        hostUsers.bob.modules = {
          home.a.enable = true;
          home.b.enable = false;
          home.req.enable = true;
          home.utils.enable = false;
          home.desktop.enable = true;
        };
      };
      enabledBob = lib.my.computeEnabledFeatureSetForUser {
        cfg = syntheticCfg;
        userName = "bob";
        catalog = syntheticCatalog;
        hostPlatform = "linux";
      };
    in
    assert forwardingEval.config.hostUsers.u1.modules.home.shell.git.editor == "helix";
    assert forwardingEval.config.hostUsers.u1.modules.home.terminal.ghostty.dotfilesLive == true;
    assert forwardingEval.config.hostUsers.u1.modules.home.utils.detached-repos.repos ? notes;
    assert forwardingEval.config.hostUsers.u2.modules.home.shell.git.editor == "kak";
    assert !typoEval.success;
    assert enabledBob ? "home.a";
    assert !(enabledBob ? "home.b");
    assert !(enabledBob ? "home.c");
    assert enabledBob ? "home.utils.obsidian";
    assert !(enabledBob ? "home.desktop.hyprland");
    pkgs.runCommand "dsl-unit-tests" { } "touch $out";

  detachedRepoSyncTests =
    pkgs.runCommand "detached-repo-sync-tests"
      {
        nativeBuildInputs = [
          pkgs.python3
          pkgs.git
          pkgs.detached-repo-sync
        ];
        PYTHONDONTWRITEBYTECODE = "1";
        DETACHED_REPO_SYNC_BIN = lib.getExe pkgs.detached-repo-sync;
      }
      ''
        python3 -B -m unittest discover \
          -s "${./pkgs/detached-repo-sync}" \
          -t "${./pkgs/detached-repo-sync}" \
          -p "test_*.py" \
          -v
        touch "$out"
      '';

  commonChecks = {
    dsl-unit-tests = dslUnitTests;
    detached-repo-sync-tests = detachedRepoSyncTests;
    neovim-config = neovimConfig;
  };
in
if system == "x86_64-linux" then
  let
    goldHm = self.nixosConfigurations.nix-goldstar.config.home-manager.users.${user};
    goldHome = goldHm.home;
  in
  commonChecks
  // {
    nix-goldstar-toplevel =
      assert builtins.isString self.nixosConfigurations.nix-goldstar.config.system.build.toplevel.drvPath;
      pkgs.runCommand "nix-goldstar-toplevel-check" { } "touch $out";

    nix-oldstar-toplevel =
      assert builtins.isString self.nixosConfigurations.nix-oldstar.config.system.build.toplevel.drvPath;
      pkgs.runCommand "nix-oldstar-toplevel-check" { } "touch $out";

    mcp-config-generation =
      let
        mcpFile = goldHome.file.".gemini/antigravity/mcp_config.json" or null;
        mcpJson = if mcpFile != null then builtins.fromJSON mcpFile.text else { };
      in
      assert goldHome.file ? ".gemini/antigravity/mcp_config.json";
      assert mcpJson ? mcpServers.nixos;
      assert mcpJson ? mcpServers.ghidra;
      pkgs.runCommand "mcp-config-generation-check" { } "touch $out";

    agentic-detached-repos =
      let
        goldEnabled = self.nixosConfigurations.nix-goldstar.config._enabledFeatureSets.${user};
        oldHm = self.nixosConfigurations.nix-oldstar.config.home-manager.users.${user};
        oldEnabled = self.nixosConfigurations.nix-oldstar.config._enabledFeatureSets.${user};
        skillsFile = goldHome.file.".gemini/config/skills.json" or null;
        skillsJson = if skillsFile != null then builtins.fromJSON skillsFile.text else { };
        agenticLinkExec =
          builtins.head
            goldHm.systemd.user.services."detached-repo-agentic-link".Service.ExecStart;
        agenticCfgJsonPath = builtins.elemAt (lib.splitString " " agenticLinkExec) 2;
      in
      # nix-goldstar: agentic active, utils.detached-repos not cascaded
      assert goldEnabled ? "home.ai-tools.agentic";
      assert !(goldEnabled ? "home.utils.detached-repos");
      assert builtins.attrNames goldHm.programs.detachedRepos.repos == [ "agentic" ];
      assert goldHm.programs.detachedRepos.repos.agentic.pullUrl == "https://github.com/GDR/agentic.git";
      assert goldHm.programs.detachedRepos.repos.agentic.pushUrl == "git@github.com:GDR/agentic.git";
      assert goldHm.programs.detachedRepos.repos.agentic.path == "Workspaces/gdr/agentic";
      assert goldHm.programs.detachedRepos.repos.agentic.branch == "main";
      assert goldHm.programs.detachedRepos.repos.agentic.autoPull;
      assert goldHm.programs.detachedRepos.repos.agentic.interval == 300;
      assert goldHm.programs.detachedRepos.repos.agentic.watch;
      assert
        goldHm.programs.detachedRepos.repos.agentic.watchSubpaths == [
          "rules"
          "skills"
          "skills/design"
          "skills/git"
        ];
      assert (builtins.head goldHm.programs.detachedRepos.repos.agentic.fanout).recursive == true;
      assert
        goldHm.programs.detachedRepos.repos.agentic.links == [
          {
            from = "rules/AGENTS.md";
            to = ".gemini/config/AGENTS.md";
          }
          {
            from = "rules/AGENTS.md";
            to = ".claude/CLAUDE.md";
          }
          {
            from = "rules/AGENTS.md";
            to = ".codex/AGENTS.md";
          }
          {
            from = "rules/AGENTS.md";
            to = ".config/opencode/AGENTS.md";
          }
          {
            from = "rules/AGENTS.md";
            to = ".gemini/GEMINI.md";
          }
        ];
      assert hasPackage "detached-repo-sync" goldHome.packages;
      assert !(goldHome.file ? ".gemini/config/AGENTS.md");
      assert goldHome.file ? ".gemini/config/skills.json";
      assert
        skillsJson == {
          inherits = [
            { path = "/home/${user}/Workspaces/gdr/agentic/skills.json"; }
          ];
        };
      assert goldHm.home.activation ? detachedReposBootstrap;
      assert
        goldHm.home.activation.detachedReposBootstrap.before == [
          "reloadSystemd"
          "setupLaunchAgents"
        ];
      assert goldHm.home.activation.detachedReposBootstrap.after == [ "writeBoundary" ];
      assert goldHm.systemd.user.services ? "detached-repo-agentic-pull";
      assert goldHm.systemd.user.services ? "detached-repo-agentic-link";
      assert goldHm.systemd.user.timers ? "detached-repo-agentic-pull";
      assert goldHm.systemd.user.paths ? "detached-repo-agentic-link";
      assert
        (goldHm.systemd.user.timers."detached-repo-agentic-pull".Timer.Unit or "")
        == "detached-repo-agentic-pull.service";
      assert
        (goldHm.systemd.user.paths."detached-repo-agentic-link".Path.Unit or "")
        == "detached-repo-agentic-link.service";
      assert
        (goldHm.systemd.user.paths."detached-repo-agentic-link".Path.PathChanged or [ ]) == [
          "/home/${user}/Workspaces/gdr/agentic/rules"
          "/home/${user}/Workspaces/gdr/agentic/skills"
          "/home/${user}/Workspaces/gdr/agentic/skills/design"
          "/home/${user}/Workspaces/gdr/agentic/skills/git"
        ];
      # nix-oldstar: agentic and detached-repos disabled with zero footprint
      assert !(oldEnabled ? "home.ai-tools.agentic");
      assert !(oldEnabled ? "home.utils.detached-repos");
      assert !(oldHm.home.file ? ".gemini/config/skills.json");
      assert oldHm.programs.detachedRepos.repos == { };
      assert !(hasPackage "detached-repo-sync" oldHm.home.packages);
      assert !(oldHm.home.activation ? detachedReposBootstrap);
      assert
        !(lib.any (k: lib.hasPrefix "detached-repo" k) (builtins.attrNames oldHm.systemd.user.services));
      assert
        !(lib.any (k: lib.hasPrefix "detached-repo" k) (builtins.attrNames oldHm.systemd.user.timers));
      assert
        !(lib.any (k: lib.hasPrefix "detached-repo" k) (builtins.attrNames oldHm.systemd.user.paths));
      pkgs.runCommand "agentic-detached-repos-check"
        {
          nativeBuildInputs = [ pkgs.python3 ];
        }
        ''
          python3 -c '
          import json
          data = json.load(open("${agenticCfgJsonPath}", encoding="utf-8"))
          assert data["fanout"][0]["recursive"] is True, data
          expected_links = [
              {"from": "rules/AGENTS.md", "to": ".gemini/config/AGENTS.md"},
              {"from": "rules/AGENTS.md", "to": ".claude/CLAUDE.md"},
              {"from": "rules/AGENTS.md", "to": ".codex/AGENTS.md"},
              {"from": "rules/AGENTS.md", "to": ".config/opencode/AGENTS.md"},
              {"from": "rules/AGENTS.md", "to": ".gemini/GEMINI.md"},
          ]
          assert data["links"] == expected_links, data
          '
          touch "$out"
        '';

    multi-user-isolation =
      let
        testHost = self.nixosConfigurations.nix-goldstar.extendModules {
          modules = [
            {
              hostUsers.bob = {
                enable = true;
                modules = {
                  home.cli.htop.enable = true;
                  home.games.soundpad.enable = true;
                };
              };
            }
          ];
        };
        bobHm = testHost.config.home-manager.users.bob;
        bobPkgs = bobHm.home.packages;
        bobFiles = bobHm.home.file;
        bobGroups = testHost.config.users.users.bob.extraGroups or [ ];
        dgarifullinHm = testHost.config.home-manager.users.${user};
        dgarifullinPkgs = dgarifullinHm.home.packages;
        dgarifullinFiles = dgarifullinHm.home.file;
        dgarifullinGroups = testHost.config.users.users.${user}.extraGroups or [ ];
      in
      # bob receives htop
      assert hasPackage "htop" bobPkgs;
      # bob receives pamixer/pavucontrol (via transitive requires audio) and ydotool group (via soundpad)
      assert hasPackage "pamixer" bobPkgs;
      assert hasPackage "pavucontrol" bobPkgs;
      assert (lib.elem "ydotool" bobGroups);
      # bob does NOT receive telegram-desktop, google-antigravity-ide, .gemini/antigravity/mcp_config.json, docker group, or detached-repos/agentic
      assert !(hasPackage "telegram-desktop" bobPkgs);
      assert !(hasPackage "google-antigravity" bobPkgs);
      assert !(hasPackage "detached-repo-sync" bobPkgs);
      assert !(bobFiles ? ".gemini/antigravity/mcp_config.json");
      assert !(bobFiles ? ".gemini/config/skills.json");
      assert !(lib.elem "docker" bobGroups);
      assert bobHm.programs.detachedRepos.repos == { };
      assert !(bobHm.home.activation ? detachedReposBootstrap);
      assert
        !(lib.any (k: lib.hasPrefix "detached-repo" k) (builtins.attrNames bobHm.systemd.user.services));
      assert
        !(lib.any (k: lib.hasPrefix "detached-repo" k) (builtins.attrNames bobHm.systemd.user.timers));
      assert
        !(lib.any (k: lib.hasPrefix "detached-repo" k) (builtins.attrNames bobHm.systemd.user.paths));
      # dgarifullin retains all of their packages, configs, groups, and agentic detached-repo wiring
      assert hasPackage "htop" dgarifullinPkgs;
      assert hasPackage "telegram-desktop" dgarifullinPkgs;
      assert hasPackage "detached-repo-sync" dgarifullinPkgs;
      assert (dgarifullinFiles ? ".gemini/antigravity/mcp_config.json");
      assert (dgarifullinFiles ? ".gemini/config/skills.json");
      assert (lib.elem "docker" dgarifullinGroups);
      assert dgarifullinHm.programs.detachedRepos.repos ? agentic;
      assert dgarifullinHm.home.activation ? detachedReposBootstrap;
      assert dgarifullinHm.systemd.user.services ? "detached-repo-agentic-pull";
      assert dgarifullinHm.systemd.user.timers ? "detached-repo-agentic-pull";
      assert dgarifullinHm.systemd.user.paths ? "detached-repo-agentic-link";
      pkgs.runCommand "multi-user-isolation-check" { } "touch $out";

    system-tier-opt-out =
      let
        testHost = self.nixosConfigurations.nix-oldstar.extendModules {
          modules = [
            {
              modules.system.all = {
                enable = true;
                # Clear host-level explicit enable so fonts activates purely via tier cascade
                fonts.enable = lib.mkForce null;
                sops.enable = lib.mkForce false;
              };
            }
          ];
        };
      in
      assert !(hasPackage "sops" testHost.config.environment.systemPackages);
      assert testHost.config.fonts.packages != [ ];
      assert hasPackage "hack-font" testHost.config.fonts.packages;
      pkgs.runCommand "system-tier-opt-out-check" { } "touch $out";

    module-platform-merge =
      assert hasPackage "ripgrep" goldHome.packages;
      assert hasPackage "wl-clipboard" goldHome.packages;
      assert hasPackage "google-antigravity-ide-with-basic-store" goldHome.packages;
      assert goldHm.programs.antigravity-cli.enable;
      assert !(goldHome.file ? ".gemini/config/AGENTS.md");
      pkgs.runCommand "module-platform-merge-check" { } "touch $out";

    detached-repos-edge-cases =
      let
        mkBobLinux =
          reposAttr:
          (self.nixosConfigurations.nix-goldstar.extendModules {
            modules = [
              {
                hostUsers.bob = {
                  enable = true;
                  modules.home.utils.detached-repos = {
                    enable = true;
                    repos = reposAttr;
                  };
                };
              }
            ];
          }).config.home-manager.users.bob;

        mkBobDarwin =
          reposAttr:
          (self.darwinConfigurations.mac-brightstar.extendModules {
            modules = [
              {
                hostUsers.bob = {
                  enable = true;
                  modules.home.utils.detached-repos = {
                    enable = true;
                    repos = reposAttr;
                  };
                };
              }
            ];
          }).config.home-manager.users.bob;

        watchEmptyLinux = mkBobLinux {
          w = {
            pullUrl = "https://example.com/w.git";
            path = "Workspaces/w";
            watch = true;
            watchSubpaths = [ ];
          };
        };
        watchEmptyDarwin = mkBobDarwin {
          w = {
            pullUrl = "https://example.com/w.git";
            path = "Workspaces/w";
            watch = true;
            watchSubpaths = [ ];
          };
        };
        bootstrapOnlyLinux = mkBobLinux {
          boot = {
            pullUrl = "https://example.com/b.git";
            path = "Workspaces/b";
            autoPull = false;
            watch = false;
          };
        };
        bootstrapOnlyDarwin = mkBobDarwin {
          boot = {
            pullUrl = "https://example.com/b.git";
            path = "Workspaces/b";
            autoPull = false;
            watch = false;
          };
        };
        darwinWatchOnly = mkBobDarwin {
          wonly = {
            pullUrl = "https://example.com/wo.git";
            path = "Workspaces/wo";
            autoPull = false;
            watch = true;
            watchSubpaths = [ "skills" ];
          };
        };
        darwinPullOnly = mkBobDarwin {
          ponly = {
            pullUrl = "https://example.com/po.git";
            path = "Workspaces/po";
            autoPull = true;
            interval = 120;
            watch = false;
            watchSubpaths = [ ];
          };
        };
        linksRepoLinux = mkBobLinux {
          linkrepo = {
            pullUrl = "https://example.com/l.git";
            path = "Workspaces/l";
            autoPull = false;
            watch = true;
            links = [
              {
                from = "rules/r.md";
                to = ".agents/rules/r.md";
              }
            ];
          };
        };
        agenticOverrideLinux =
          (self.nixosConfigurations.nix-goldstar.extendModules {
            modules = [
              {
                home-manager.users.${user}.programs.detachedRepos.repos.agentic.path = lib.mkForce "/srv/agentic";
              }
            ];
          }).config.home-manager.users.${user};
        agenticOverrideDarwin =
          (self.darwinConfigurations.mac-brightstar.extendModules {
            modules = [
              {
                home-manager.users.${user}.programs.detachedRepos.repos.agentic.path = lib.mkForce "/srv/agentic";
              }
            ];
          }).config.home-manager.users.${user};
        badAssertionsHm = mkBobLinux {
          "a/b" = {
            pullUrl = "https://example.com/bad.git";
            path = "";
            watchSubpaths = [ "../outside" ];
          };
        };
        badIntervalEval =
          builtins.tryEval
            (mkBobLinux {
              badint = {
                pullUrl = "https://example.com/badint.git";
                path = "Workspaces/badint";
                interval = 0;
              };
            }).programs.detachedRepos.repos.badint.interval;

        badRecursiveHm = mkBobLinux {
          badrec = {
            pullUrl = "https://example.com/badrec.git";
            path = "Workspaces/badrec";
            fanout = [
              {
                from = "skills";
                into = [ ".agents/skills" ];
                recursive = true;
              }
            ];
          };
        };
        badRecursiveMsgs = map (a: a.message) (lib.filter (a: !a.assertion) badRecursiveHm.assertions);
        failedMsgs = map (a: a.message) (lib.filter (a: !a.assertion) badAssertionsHm.assertions);
        linksCfgJsonPath = builtins.elemAt (lib.splitString " " (
          builtins.head linksRepoLinux.systemd.user.services."detached-repo-linkrepo-link".Service.ExecStart
        )) 2;
      in
      # GAP-B1: watch = true, watchSubpaths = [] falls back to [ repoDir ]
      assert
        (watchEmptyLinux.systemd.user.paths."detached-repo-w-link".Path.PathChanged or [ ]) == [
          "/home/bob/Workspaces/w"
        ];
      assert
        (watchEmptyDarwin.launchd.agents."detached-repo-w".config.WatchPaths or [ ]) == [
          "/Users/bob/Workspaces/w"
        ];
      assert (watchEmptyDarwin.launchd.agents."detached-repo-w".config.ThrottleInterval or null) == 2;
      # GAP-B2: autoPull = false, watch = false -> bootstrap-only
      assert hasPackage "detached-repo-sync" bootstrapOnlyLinux.home.packages;
      assert bootstrapOnlyLinux.home.activation ? detachedReposBootstrap;
      assert
        !(lib.any (k: lib.hasPrefix "detached-repo" k) (
          builtins.attrNames bootstrapOnlyLinux.systemd.user.services
        ));
      assert
        !(lib.any (k: lib.hasPrefix "detached-repo" k) (
          builtins.attrNames bootstrapOnlyLinux.systemd.user.timers
        ));
      assert
        !(lib.any (k: lib.hasPrefix "detached-repo" k) (
          builtins.attrNames bootstrapOnlyLinux.systemd.user.paths
        ));
      assert hasPackage "detached-repo-sync" bootstrapOnlyDarwin.home.packages;
      assert bootstrapOnlyDarwin.home.activation ? detachedReposBootstrap;
      assert
        !(lib.any (k: lib.hasPrefix "detached-repo" k) (
          builtins.attrNames bootstrapOnlyDarwin.launchd.agents
        ));
      # GAP-B3: Darwin watchOnly & pullOnly
      assert
        builtins.elemAt darwinWatchOnly.launchd.agents."detached-repo-wonly".config.ProgramArguments 1
        == "link";
      assert (darwinWatchOnly.launchd.agents."detached-repo-wonly".config.StartInterval or null) == null;
      assert darwinWatchOnly.launchd.agents."detached-repo-wonly".config.ThrottleInterval == 2;
      assert
        darwinWatchOnly.launchd.agents."detached-repo-wonly".config.WatchPaths == [
          "/Users/bob/Workspaces/wo/skills"
        ];
      assert
        builtins.elemAt darwinPullOnly.launchd.agents."detached-repo-ponly".config.ProgramArguments 1
        == "pull";
      assert darwinPullOnly.launchd.agents."detached-repo-ponly".config.StartInterval == 120;
      assert (darwinPullOnly.launchd.agents."detached-repo-ponly".config.WatchPaths or null) == null;
      assert
        (darwinPullOnly.launchd.agents."detached-repo-ponly".config.ThrottleInterval or null) == null;
      # GAP-B5: agentic.nix path override updates skills.json + watcher paths
      assert
        builtins.fromJSON agenticOverrideLinux.home.file.".gemini/config/skills.json".text == {
          inherits = [ { path = "/srv/agentic/skills.json"; } ];
        };
      assert
        agenticOverrideLinux.systemd.user.paths."detached-repo-agentic-link".Path.PathChanged == [
          "/srv/agentic/rules"
          "/srv/agentic/skills"
          "/srv/agentic/skills/design"
          "/srv/agentic/skills/git"
        ];
      assert
        builtins.fromJSON agenticOverrideDarwin.home.file.".gemini/config/skills.json".text == {
          inherits = [ { path = "/srv/agentic/skills.json"; } ];
        };
      assert
        agenticOverrideDarwin.launchd.agents."detached-repo-agentic".config.WatchPaths == [
          "/srv/agentic/rules"
          "/srv/agentic/skills"
          "/srv/agentic/skills/design"
          "/srv/agentic/skills/git"
        ];
      # GAP-B6: HM assertions & interval = 0 rejection
      assert builtins.length failedMsgs == 3;
      assert lib.any (m: lib.hasInfix "invalid repository name" m) failedMsgs;
      assert lib.any (m: lib.hasInfix "non-empty absolute path" m) failedMsgs;
      assert lib.any (m: lib.hasInfix "watchSubpaths" m) failedMsgs;
      assert builtins.length badRecursiveMsgs == 1;
      assert lib.any (m: lib.hasInfix "must set requireFile" m) badRecursiveMsgs;
      assert !badIntervalEval.success;
      # GAP-B4: non-empty links serialized into generated config JSON
      pkgs.runCommand "detached-repos-edge-cases-check"
        {
          nativeBuildInputs = [ pkgs.python3 ];
        }
        ''
          python3 -c '
          import json
          data = json.load(open("${linksCfgJsonPath}", encoding="utf-8"))
          assert data["links"] == [{"from": "rules/r.md", "to": ".agents/rules/r.md"}], data
          '
          touch "$out"
        '';
  }
else if system == "aarch64-darwin" then
  let
    macHm = self.darwinConfigurations.mac-brightstar.config.home-manager.users.${user};
    macHome = macHm.home;
  in
  commonChecks
  // {
    mac-brightstar-toplevel =
      assert builtins.isString
        self.darwinConfigurations.mac-brightstar.config.system.build.toplevel.drvPath;
      pkgs.runCommand "mac-brightstar-toplevel-check" { } "touch $out";

    learnharness-config-generation =
      assert macHm.programs.learnharness.enable;
      assert hasPackage "learnharness" macHome.packages;
      assert macHome.activation ? learnharnessSettings;
      assert macHm.programs.learnharness.models.strong.id == "gemini-4-argon";
      pkgs.runCommand "learnharness-config-generation-check" { } "touch $out";

    agentic-detached-repos =
      let
        macEnabled = self.darwinConfigurations.mac-brightstar.config._enabledFeatureSets.${user};
        skillsFile = macHome.file.".gemini/config/skills.json" or null;
        skillsJson = if skillsFile != null then builtins.fromJSON skillsFile.text else { };
        agentCfg = macHm.launchd.agents."detached-repo-agentic".config or { };
      in
      assert macEnabled ? "home.ai-tools.agentic";
      assert !(macEnabled ? "home.utils.detached-repos");
      assert builtins.attrNames macHm.programs.detachedRepos.repos == [ "agentic" ];
      assert hasPackage "detached-repo-sync" macHome.packages;
      assert !(macHome.file ? ".gemini/config/AGENTS.md");
      assert macHome.file ? ".gemini/config/skills.json";
      assert
        skillsJson == {
          inherits = [
            { path = "/Users/${user}/Workspaces/gdr/agentic/skills.json"; }
          ];
        };
      assert (builtins.head macHm.programs.detachedRepos.repos.agentic.fanout).recursive == true;
      assert
        macHm.programs.detachedRepos.repos.agentic.links == [
          {
            from = "rules/AGENTS.md";
            to = ".gemini/config/AGENTS.md";
          }
          {
            from = "rules/AGENTS.md";
            to = ".claude/CLAUDE.md";
          }
          {
            from = "rules/AGENTS.md";
            to = ".codex/AGENTS.md";
          }
          {
            from = "rules/AGENTS.md";
            to = ".config/opencode/AGENTS.md";
          }
          {
            from = "rules/AGENTS.md";
            to = ".gemini/GEMINI.md";
          }
        ];
      assert macHm.home.activation ? detachedReposBootstrap;
      assert
        macHm.home.activation.detachedReposBootstrap.before == [
          "reloadSystemd"
          "setupLaunchAgents"
        ];
      assert macHm.home.activation.detachedReposBootstrap.after == [ "writeBoundary" ];
      assert macHm.launchd.agents ? "detached-repo-agentic";
      assert agentCfg.RunAtLoad or false;
      assert (agentCfg.KeepAlive or true) == false;
      assert (agentCfg.ProcessType or "") == "Background";
      assert (agentCfg.StartInterval or null) == 300;
      assert (agentCfg.ThrottleInterval or null) == 2;
      assert
        (agentCfg.WatchPaths or [ ]) == [
          "/Users/${user}/Workspaces/gdr/agentic/rules"
          "/Users/${user}/Workspaces/gdr/agentic/skills"
          "/Users/${user}/Workspaces/gdr/agentic/skills/design"
          "/Users/${user}/Workspaces/gdr/agentic/skills/git"
        ];
      assert builtins.length (agentCfg.ProgramArguments or [ ]) == 3;
      assert builtins.elemAt (agentCfg.ProgramArguments or [ ]) 1 == "pull";
      pkgs.runCommand "agentic-detached-repos-check" { } "touch $out";

    cascade-child-opt-out =
      let
        testDarwin = self.darwinConfigurations.mac-brightstar.extendModules {
          modules = [
            {
              hostUsers.${user}.modules = {
                home.utils.enable = lib.mkForce true;
                home.utils.raycast.enable = lib.mkForce false;
              };
            }
          ];
        };
        pkgsList = testDarwin.config.home-manager.users.${user}.home.packages;
      in
      # obsidian is enabled via category cascade
      assert hasPackage "obsidian" pkgsList;
      # raycast remains disabled via child opt-out
      assert !(hasPackage "raycast" pkgsList);
      pkgs.runCommand "cascade-child-opt-out-check" { } "touch $out";

    dotfiles-live-global-option =
      let
        testDarwin = self.darwinConfigurations.mac-brightstar.extendModules {
          modules = [
            {
              dotfiles.live = true;
            }
          ];
        };
        ghosttySource = testDarwin.config.home-manager.users.${user}.xdg.configFile."ghostty/config".source;
      in
      assert testDarwin.config.dotfiles.live == true;
      # mkOutOfStoreSymlink wraps the live repo path in an hm_* symlink derivation
      assert lib.isDerivation ghosttySource;
      assert lib.hasPrefix "hm_" (ghosttySource.name or "");
      assert lib.hasInfix
        "/Users/${user}/Workspaces/gdr/dot/modules/home/terminal/ghostty/dotfiles/config"
        (ghosttySource.buildCommand or "");
      pkgs.runCommand "dotfiles-live-global-option-check" { } "touch $out";

    module-platform-merge =
      assert hasPackage "ripgrep" macHome.packages;
      assert !(hasPackage "wl-clipboard" macHome.packages);
      pkgs.runCommand "module-platform-merge-check" { } "touch $out";
  }
else
  { }
