# Agentic — shared AI skills and rules repository sync, fanout, and harness wiring
{ lib, ... }:

lib.my.mkFeature {
  description = "Shared agentic skills and rules repository sync, fanout, and harness wiring";

  homeModule =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      repoPath = config.programs.detachedRepos.repos.agentic.path;
      resolvedRepoPath =
        if repoPath == "~" then
          config.home.homeDirectory
        else if lib.hasPrefix "/" repoPath then
          repoPath
        else if lib.hasPrefix "~/" repoPath then
          "${config.home.homeDirectory}/${lib.removePrefix "~/" repoPath}"
        else
          "${config.home.homeDirectory}/${lib.removePrefix "./" repoPath}";

      mkCommitSkillGate =
        harness:
        pkgs.writeShellScript "agentic-commit-skill-gate-${harness}" ''
          script="${resolvedRepoPath}/hooks/commit_skill_gate.py"
          if [ -f "$script" ]; then
            exec "${lib.getExe pkgs.python3}" -B "$script" --harness "${harness}"
          fi
          ${lib.optionalString (harness == "antigravity") ''printf '{"decision":"allow"}\n' ''}
        '';

      antigravityCommitGate = mkCommitSkillGate "antigravity";
      claudeCommitGate = mkCommitSkillGate "claude";

      # Idempotently inject/update our PreToolUse Bash matcher in ~/.claude/settings.json
      # without clobbering user settings or interactive Claude Code state.
      mergeClaudeHooksScript = ./scripts/merge_claude_hooks.py;
    in
    {
      programs.detachedRepos.repos.agentic = {
        pullUrl = "https://github.com/GDR/agentic.git";
        pushUrl = "git@github.com:GDR/agentic.git";
        path = "Workspaces/gdr/agentic";
        branch = "main";
        autoPull = true;
        interval = 300;
        watch = true;
        watchSubpaths = [
          "rules"
          "skills"
          "skills/design"
          "skills/git"
          "skills/security"
        ];
        fanout = [
          {
            from = "skills";
            into = [
              ".agents/skills"
              ".claude/skills"
            ];
            requireFile = "SKILL.md";
            recursive = true;
          }
        ];
        links = [
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
      };

      home.file.".gemini/config/skills.json".text = builtins.toJSON {
        inherits = [
          { path = "${resolvedRepoPath}/skills.json"; }
        ];
      };

      home.file.".gemini/config/hooks.json".text = builtins.toJSON {
        commit-skill-gate = {
          PreToolUse = [
            {
              matcher = "run_command";
              hooks = [
                {
                  type = "command";
                  command = "${antigravityCommitGate}";
                  timeout = 10;
                }
              ];
            }
          ];
        };
      };

      home.activation.agenticClaudeHooks = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        run ${lib.escapeShellArg (lib.getExe pkgs.python3)} -B ${lib.escapeShellArg "${mergeClaudeHooksScript}"} ${lib.escapeShellArg "${config.home.homeDirectory}/.claude/settings.json"} ${lib.escapeShellArg "${claudeCommitGate}"} || warnEcho "agenticClaudeHooks merge failed; continuing"
      '';
    };
}
