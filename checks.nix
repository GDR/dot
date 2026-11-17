{ self, inputs, pkgs, lib, system }:

let
  user = "dgarifullin";
  hasPackage = expectedName: packages:
    lib.any
      (package:
        let
          pname = package.pname or (builtins.parseDrvName (package.name or "")).name;
        in
        pname == expectedName || (package.name or "") == expectedName
      )
      packages;

  neovimConfig = inputs.nvim-nix.checks.${system}.neovim-config;
  moduleRegistry = (import ./modules/_core/registry.nix { inherit lib inputs; }).moduleRegistry;

  dslUnitTests =
    let
      schema = lib.my.buildFeatureOptionTree {
        featureCatalog = moduleRegistry.features;
        knownModulePaths = map (m: m.path) moduleRegistry.allModules;
      };
      forwardTree = cond: priority: skipEnable: optTree: schemaTree:
        lib.concatMapAttrs
          (k: v:
            if lib.isOption v then
              if skipEnable && k == "enable" then { }
              else
                let
                  gOpt = optTree.${k};
                  explicitlySet = gOpt.isDefined && gOpt.highestPrio < 1500;
                in
                { ${k} = lib.mkIf (cond && explicitlySet) (lib.mkOverride priority gOpt.value); }
            else
              { ${k} = forwardTree cond priority skipEnable optTree.${k} v; }
          )
          schemaTree;

      evalDsl = extraMod: lib.evalModules {
        modules = [
          ({ options, ... }: {
            options.modules = schema;
            options.profileModules = schema;
            options.hostUsers = lib.mkOption {
              type = lib.types.attrsOf (lib.types.submoduleWith {
                modules = [
                  ({ config, ... }: {
                    options.inheritProfiles = lib.mkEnableOption "inherit profiles";
                    options.modules = lib.mkOption {
                      type = lib.types.submoduleWith {
                        modules = [
                          {
                            options = schema;
                            config = lib.mkMerge [
                              (forwardTree true 1100 true options.modules schema)
                              (forwardTree config.inheritProfiles 1050 false options.profileModules schema)
                            ];
                          }
                        ];
                      };
                      default = { };
                    };
                  })
                ];
              });
              default = { };
            };
          })
          extraMod
        ];
      };

      forwardingEval = evalDsl {
        modules.home.shell.git.editor = "helix";
        modules.home.terminal.ghostty.dotfilesLive = true;
        hostUsers.u1.modules.home.cli.htop.enable = true;
        hostUsers.u2.modules.home.shell.git.editor = lib.mkDefault "kak";
      };

      typoEval = builtins.tryEval
        (evalDsl {
          hostUsers.u.modules.home.nonexistent.enable = true;
        }).config.hostUsers.u.modules.home;

      syntheticMap = {
        "home.a" = { requires = [ "home.b" ]; platforms = [ "linux" "darwin" ]; cascade = true; };
        "home.b" = { requires = [ "home.c" ]; platforms = [ "linux" "darwin" ]; cascade = true; };
        "home.c" = { requires = [ ]; platforms = [ "linux" "darwin" ]; cascade = true; };
        "home.req" = { requires = [ "home.utils.obsidian" ]; platforms = [ "linux" "darwin" ]; cascade = true; };
        "home.utils.obsidian" = { requires = [ ]; platforms = [ "linux" "darwin" ]; cascade = true; };
        "home.desktop.hyprland" = { requires = [ ]; platforms = [ "linux" ]; cascade = false; };
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
    assert forwardingEval.config.hostUsers.u2.modules.home.shell.git.editor == "kak";
    assert !typoEval.success;
    assert enabledBob ? "home.a";
    assert !(enabledBob ? "home.b");
    assert !(enabledBob ? "home.c");
    assert enabledBob ? "home.utils.obsidian";
    assert !(enabledBob ? "home.desktop.hyprland");
    pkgs.runCommand "dsl-unit-tests" { } "touch $out";

  commonChecks = {
    dsl-unit-tests = dslUnitTests;
    neovim-config = neovimConfig;
  };
in
if system == "x86_64-linux" then
  let
    goldHome = self.nixosConfigurations.nix-goldstar.config.home-manager.users.${user}.home;
  in
  commonChecks // {
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
        bobPkgs = testHost.config.home-manager.users.bob.home.packages;
        bobFiles = testHost.config.home-manager.users.bob.home.file;
        bobGroups = testHost.config.users.users.bob.extraGroups or [ ];
        dgarifullinPkgs = testHost.config.home-manager.users.${user}.home.packages;
        dgarifullinFiles = testHost.config.home-manager.users.${user}.home.file;
        dgarifullinGroups = testHost.config.users.users.${user}.extraGroups or [ ];
      in
      # bob receives htop
      assert hasPackage "htop" bobPkgs;
      # bob receives pamixer/pavucontrol (via transitive requires audio) and ydotool group (via soundpad)
      assert hasPackage "pamixer" bobPkgs;
      assert hasPackage "pavucontrol" bobPkgs;
      assert (lib.elem "ydotool" bobGroups);
      # bob does NOT receive telegram-desktop, google-antigravity-ide, .gemini/antigravity/mcp_config.json, or docker group
      assert !(hasPackage "telegram-desktop" bobPkgs);
      assert !(hasPackage "google-antigravity" bobPkgs);
      assert !(bobFiles ? ".gemini/antigravity/mcp_config.json");
      assert !(lib.elem "docker" bobGroups);
      # dgarifullin retains all of their packages, configs, and groups
      assert hasPackage "htop" dgarifullinPkgs;
      assert hasPackage "telegram-desktop" dgarifullinPkgs;
      assert (dgarifullinFiles ? ".gemini/antigravity/mcp_config.json");
      assert (lib.elem "docker" dgarifullinGroups);
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
      assert goldHome.file ? ".gemini/config/AGENTS.md";
      pkgs.runCommand "module-platform-merge-check" { } "touch $out";
  }
else if system == "aarch64-darwin" then
  let
    macHome = self.darwinConfigurations.mac-brightstar.config.home-manager.users.${user}.home;
  in
  commonChecks // {
    mac-brightstar-toplevel =
      assert builtins.isString self.darwinConfigurations.mac-brightstar.config.system.build.toplevel.drvPath;
      pkgs.runCommand "mac-brightstar-toplevel-check" { } "touch $out";

    learnharness-config-generation =
      let
        brightstarHm = self.darwinConfigurations.mac-brightstar.config.home-manager.users.${user};
      in
      assert brightstarHm.programs.learnharness.enable;
      assert hasPackage "learnharness" brightstarHm.home.packages;
      assert brightstarHm.home.activation ? learnharnessSettings;
      assert brightstarHm.programs.learnharness.models.strong.id == "gemini-4-argon";
      pkgs.runCommand "learnharness-config-generation-check" { } "touch $out";

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
      assert lib.hasInfix "/Users/${user}/Workspaces/gdr/dot/modules/home/terminal/ghostty/dotfiles/config" (ghosttySource.buildCommand or "");
      pkgs.runCommand "dotfiles-live-global-option-check" { } "touch $out";

    module-platform-merge =
      assert hasPackage "ripgrep" macHome.packages;
      assert !(hasPackage "wl-clipboard" macHome.packages);
      pkgs.runCommand "module-platform-merge-check" { } "touch $out";
  }
else
  { }
