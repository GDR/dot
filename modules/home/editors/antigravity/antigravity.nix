# Antigravity IDE & standalone Antigravity 2.0
# Tracks latest via the upstream antigravity-nix flake (auto-updates 3x/week).
#
# On NixOS without a keyring daemon (typical on bare Hyprland), Electron's default
# credential backend silently fails — auth tokens are never saved, so every launch
# looks like a fresh install: no login, no conversation history.
# --password-store=basic tells Electron to store credentials as plain text inside
# the app's --user-data-dir (~/.antigravity-ide), which persists normally.
#
# Config management: when enabled, also manages ~/.gemini/config/ files
# (AGENTS.md rules, skills.json for external skills like caveman)
# and ~/.gemini/antigravity/mcp_config.json (global MCP servers).
{ lib, pkgs, config, system, ... }@args:

let
  isDarwin = system == "aarch64-darwin" || system == "x86_64-darwin";
  isLinux = system == "aarch64-linux" || system == "x86_64-linux";

  # Wrap Linux binaries to force plain-text credential storage.
  ideLinux = pkgs.symlinkJoin {
    name = "google-antigravity-ide-with-basic-store";
    paths = [ pkgs.google-antigravity-ide ];
    buildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/antigravity-ide \
        --add-flags "--password-store=basic" \
        --add-flags "--force-color-profile=srgb"
    '';
  };

  antigravityLinux = pkgs.symlinkJoin {
    name = "google-antigravity-with-basic-store";
    paths = [ pkgs.google-antigravity ];
    buildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/antigravity \
        --add-flags "--password-store=basic" \
        --add-flags "--force-color-profile=srgb"
    '';
  };

  antigravityIdeWrapper = pkgs.writeShellScriptBin "antigravity-ide" ''
    exec "${pkgs.google-antigravity-ide}/Applications/Antigravity IDE.app/Contents/MacOS/Antigravity IDE" "$@"
  '';

  # Read cfg lazily via config.modules — not through the cfg parameter
  # to avoid infinite recursion (cfg evaluation triggers module re-evaluation)
  modulePath = args._modulePath;
  pathParts = lib.splitString "." modulePath;
  cfg = lib.foldl' (acc: part: acc.${part} or { }) config.modules pathParts;

  allSkillPaths = (cfg.skillPaths or [ ])
    ++ lib.optional (cfg.cavemanEnable or false) "${pkgs.caveman-skills}";

  hasRules = (cfg.rules or "") != "";
  hasSkills = allSkillPaths != [ ];
  hasMcp = (cfg.mcpServers or { }) != { };

  skillsJson = builtins.toJSON {
    entries = map (p: { path = p; }) allSkillPaths;
  };

  enabledUsers = lib.filterAttrs (_: u: u.enable) (config.hostUsers or { });
in
lib.my.mkModuleV2 args {
  description = "Antigravity IDE & standalone Antigravity 2.0";

  extraOptions = {
    rules = lib.mkOption {
      type = lib.types.lines;
      default = ''
        # Global Rules

        ## Communication
        - Direct, no fluff — answer immediately
        - Dense, iterative style
        - Always use caveman ultra mode (see caveman skill)

        ## Code Style
        - Comment non-obvious decisions
        - Cite sources when referencing external docs
        - Imperative mood in commit messages
      '';
      description = "Content for ~/.gemini/config/AGENTS.md (global rules).";
    };

    skillPaths = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Absolute paths to external skill directories for skills.json.";
    };

    cavemanEnable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Add caveman skills (pkgs.caveman-skills) to skill paths.";
    };

    mcpServers = lib.mkOption {
      type = lib.types.attrsOf lib.types.anything;
      default = { };
      description = "MCP servers written to ~/.gemini/antigravity/mcp_config.json (global, all workspaces).";
      example = {
        ghidra = {
          command = "bridge-mcp-ghidra";
          args = [ ];
          env.GHIDRA_MCP_URL = "http://nix-oldstar:8089";
        };
      };
    };
  };

  # module without cfg parameter — avoids the recursion entirely.
  # Package installation doesn't depend on cfg values.
  module = {
    nixosSystems.home.packages = [
      ideLinux
      antigravityLinux
      pkgs.google-antigravity-cli
    ];

    darwinSystems.home.packages = [
      antigravityIdeWrapper
      pkgs.google-antigravity-ide
      pkgs.google-antigravity
      pkgs.google-antigravity-cli
    ];
  };

  # Config file management via systemModule — reads cfg lazily from config.modules
  systemModule = {
    allSystems = lib.mkMerge [
      (lib.mkIf hasRules {
        home-manager.users = lib.mapAttrs
          (_: _: {
            home.file.".gemini/config/AGENTS.md".text = cfg.rules;
          })
          enabledUsers;
      })
      (lib.mkIf hasSkills {
        home-manager.users = lib.mapAttrs
          (_: _: {
            home.file.".gemini/config/skills.json".text = skillsJson;
          })
          enabledUsers;
      })
      (lib.mkIf hasMcp {
        home-manager.users = lib.mapAttrs
          (_: _: {
            # Global MCP config — applies to all workspaces in Antigravity
            home.file.".gemini/antigravity/mcp_config.json".text =
              builtins.toJSON { mcpServers = cfg.mcpServers; };
          })
          enabledUsers;
      })
    ];
  };
}
