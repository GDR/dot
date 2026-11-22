#!/usr/bin/env python3
"""Idempotently merge the agentic PreToolUse Bash hook into ~/.claude/settings.json."""

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
