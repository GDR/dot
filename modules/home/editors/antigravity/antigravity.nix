# Antigravity IDE & standalone Antigravity 2.0
{ lib, ... }:

lib.my.mkFeature {
  description = "Antigravity IDE & standalone Antigravity 2.0";

  extraOptions = {
    rules = lib.mkOption {
      type = lib.types.lines;
      default = ''
        # Global Rules

        ## Communication
        - Direct, no fluff — answer immediately
        - Dense, iterative style

        ## Code Style
        - Comment non-obvious decisions
        - Cite sources when referencing external docs
        - Imperative mood in commit messages
      '';
      description = "Content for ~/.gemini/config/AGENTS.md (global rules).";
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

  homeModule = { pkgs, lib, featureCfg, ... }:
    let
      hasRules = (featureCfg.rules or "") != "";
      hasMcp = (featureCfg.mcpServers or { }) != { };
    in
    {
      programs.antigravity-cli = {
        enable = true;
      };

      home.file = lib.mkMerge [
        (lib.mkIf hasRules {
          ".gemini/config/AGENTS.md".text = featureCfg.rules;
        })
        (lib.mkIf hasMcp {
          ".gemini/antigravity/mcp_config.json".text =
            builtins.toJSON { inherit (featureCfg) mcpServers; };
          ".gemini/config/mcp_config.json".text =
            builtins.toJSON { inherit (featureCfg) mcpServers; };
        })
      ];
    };

  homeModuleLinux = { pkgs, ... }:
    let
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
    in
    {
      home.packages = [
        ideLinux
        antigravityLinux
        pkgs.google-antigravity-cli
        pkgs.mcp-nixos
      ];
    };

  homeModuleDarwin = { pkgs, ... }:
    let
      antigravityWrapper = pkgs.writeShellScriptBin "antigravity" ''
        exec open -a "${pkgs.google-antigravity}/Applications/Antigravity.app" --args --password-store=basic "$@"
      '';

      antigravityIdeWrapper = pkgs.writeShellScriptBin "antigravity-ide" ''
        exec open -a "${pkgs.google-antigravity-ide}/Applications/Antigravity IDE.app" --args --password-store=basic "$@"
      '';
    in
    {
      home.packages = [
        antigravityWrapper
        antigravityIdeWrapper
        pkgs.google-antigravity-ide
        pkgs.google-antigravity
        pkgs.google-antigravity-cli
        pkgs.mcp-nixos
      ];
    };
}
