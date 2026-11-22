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
      mergeClaudeHooksScript = pkgs.writeText "agentic-merge-claude-hooks.py" ''
        import json
        import os
        import sys
        import tempfile
        from pathlib import Path

        MARKER = "agentic-commit-skill-gate-claude"


        def main() -> int:
            if len(sys.argv) != 3:
                print("usage: merge <settings.json> <gate-command>", file=sys.stderr)
                return 1

            target = Path(sys.argv[1])
            gate_cmd = sys.argv[2]

            if target.is_symlink():
                print(f"warning: {target} is a symlink; skipping Claude hook merge", file=sys.stderr)
                return 0

            data = {}
            if target.exists():
                if not target.is_file():
                    print(f"warning: {target} is not a regular file; skipping Claude hook merge", file=sys.stderr)
                    return 0
                try:
                    loaded = json.loads(target.read_text(encoding="utf-8"))
                except (OSError, json.JSONDecodeError) as exc:
                    print(f"warning: failed to parse {target}: {exc}; skipping Claude hook merge", file=sys.stderr)
                    return 0
                if not isinstance(loaded, dict):
                    print(f"warning: {target} top-level JSON is not an object; skipping", file=sys.stderr)
                    return 0
                data = loaded

            hooks = data.get("hooks")
            if hooks is None:
                hooks = {}
            elif not isinstance(hooks, dict):
                print(f"warning: {target} hooks field is not an object; skipping", file=sys.stderr)
                return 0

            pre_tool_use = hooks.get("PreToolUse")
            if pre_tool_use is None:
                pre_tool_use = []
            elif not isinstance(pre_tool_use, list):
                print(f"warning: {target} hooks.PreToolUse is not a list; skipping", file=sys.stderr)
                return 0

            cleaned = []
            for entry in pre_tool_use:
                if not isinstance(entry, dict):
                    cleaned.append(entry)
                    continue
                inner_hooks = entry.get("hooks")
                if not isinstance(inner_hooks, list):
                    cleaned.append(entry)
                    continue
                kept_hooks = [
                    h
                    for h in inner_hooks
                    if not (isinstance(h, dict) and MARKER in str(h.get("command", "")))
                ]
                if kept_hooks:
                    updated_entry = dict(entry)
                    updated_entry["hooks"] = kept_hooks
                    cleaned.append(updated_entry)

            cleaned.append(
                {
                    "matcher": "Bash",
                    "hooks": [
                        {
                            "type": "command",
                            "command": gate_cmd,
                            "timeout": 10,
                        }
                    ],
                }
            )

            new_hooks = dict(hooks)
            new_hooks["PreToolUse"] = cleaned
            new_data = dict(data)
            new_data["hooks"] = new_hooks

            if target.exists() and new_data == data:
                return 0

            target.parent.mkdir(parents=True, exist_ok=True)
            rendered = json.dumps(new_data, indent=2) + "\n"
            fd, tmp_name = tempfile.mkstemp(prefix=".settings.", dir=target.parent)
            try:
                with os.fdopen(fd, "w", encoding="utf-8") as fh:
                    fh.write(rendered)
                os.chmod(tmp_name, 0o644)
                os.replace(tmp_name, target)
            except OSError:
                if os.path.exists(tmp_name):
                    os.unlink(tmp_name)
                raise
            return 0


        if __name__ == "__main__":
            raise SystemExit(main())
      '';
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
