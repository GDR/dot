"""Unit and integration tests for detached_repo_sync."""

from __future__ import annotations

import contextlib
import io
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import tempfile
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parent))
import detached_repo_sync as drs  # noqa: E402


SCRIPT_PATH = Path(__file__).resolve().with_name("detached_repo_sync.py")


class BaseDetachedRepoTest(unittest.TestCase):
    def setUp(self) -> None:
        self._tmp = tempfile.TemporaryDirectory()
        self.root = Path(self._tmp.name).resolve(strict=True)
        self.home_dir = self.root / "home"
        self.home_dir.mkdir(parents=True, exist_ok=True)
        self.state_dir = self.home_dir / ".local" / "state" / "detached-repos"
        self.remote_dir = self.root / "remote.git"
        self.work_dir = self.root / "upstream-work"
        self.cfg_dir = self.root / "cfg"
        self.cfg_dir.mkdir(parents=True, exist_ok=True)

    def tearDown(self) -> None:
        self._tmp.cleanup()

    def git_env(self) -> dict[str, str]:
        env = os.environ.copy()
        env.update(
            {
                "HOME": str(self.home_dir),
                "GIT_CONFIG_NOSYSTEM": "1",
                "GIT_CONFIG_GLOBAL": "/dev/null",
                "GIT_AUTHOR_NAME": "Test Author",
                "GIT_AUTHOR_EMAIL": "author@example.invalid",
                "GIT_COMMITTER_NAME": "Test Committer",
                "GIT_COMMITTER_EMAIL": "committer@example.invalid",
                "GIT_TERMINAL_PROMPT": "0",
            }
        )
        return env

    def git(self, args: list[str], cwd: Path | None = None) -> subprocess.CompletedProcess[str]:
        cmd = ["git"]
        if cwd is not None:
            cmd.extend(["-C", str(cwd)])
        cmd.extend(args)
        proc = subprocess.run(
            cmd,
            env=self.git_env(),
            capture_output=True,
            text=True,
            check=False,
        )
        if proc.returncode != 0:
            raise AssertionError(
                f"git command failed: {' '.join(cmd)}\nstdout: {proc.stdout}\nstderr: {proc.stderr}"
            )
        return proc

    def init_remote_with_skills(
        self,
        skills: dict[str, dict[str, str]] | None = None,
        extra_files: dict[str, str] | None = None,
        branch: str = "main",
    ) -> None:
        self.git(["init", "--bare", f"--initial-branch={branch}", str(self.remote_dir)])
        self.git(["clone", str(self.remote_dir), str(self.work_dir)])
        self.git(["checkout", "-B", branch], cwd=self.work_dir)
        skills = skills or {
            "alpha": {"SKILL.md": "# Alpha\n"},
            "beta": {"SKILL.md": "# Beta\n"},
        }
        for skill_name, files in skills.items():
            sdir = self.work_dir / "skills" / skill_name
            sdir.mkdir(parents=True, exist_ok=True)
            for fname, content in files.items():
                fpath = sdir / fname
                fpath.parent.mkdir(parents=True, exist_ok=True)
                fpath.write_text(content, encoding="utf-8")
        if extra_files:
            for rel, content in extra_files.items():
                fpath = self.work_dir / rel
                fpath.parent.mkdir(parents=True, exist_ok=True)
                fpath.write_text(content, encoding="utf-8")
        self.git(["add", "-A"], cwd=self.work_dir)
        self.git(["commit", "-m", "initial commit"], cwd=self.work_dir)
        self.git(["push", "-u", "origin", branch], cwd=self.work_dir)

    def commit_upstream_file(self, rel_path: str, content: str, message: str = "update") -> str:
        target = self.work_dir / rel_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content, encoding="utf-8")
        self.git(["add", "-A"], cwd=self.work_dir)
        self.git(["commit", "-m", message], cwd=self.work_dir)
        self.git(["push", "origin", "HEAD"], cwd=self.work_dir)
        return self.git(["rev-parse", "HEAD"], cwd=self.work_dir).stdout.strip()

    def write_config(self, payload: dict, filename: str = "repo.json") -> Path:
        path = self.cfg_dir / filename
        path.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
        return path

    def default_config_dict(self, **overrides: object) -> dict:
        cfg: dict = {
            "name": "agentic",
            "homeDir": str(self.home_dir),
            "repoDir": "Workspaces/gdr/agentic",
            "pullUrl": str(self.remote_dir),
            "pushUrl": "ssh://example.invalid/gdr/agentic.git",
            "branch": "main",
            "stateDir": "~/.local/state/detached-repos",
            "fanout": [
                {
                    "from": "skills",
                    "into": [".agents/skills", ".claude/skills"],
                    "requireFile": "SKILL.md",
                }
            ],
            "links": [],
        }
        cfg.update(overrides)
        return cfg

    def run_cli_inproc(self, argv: list[str]) -> tuple[int, str, str]:
        stdout = io.StringIO()
        stderr = io.StringIO()
        old_home = os.environ.get("HOME")
        os.environ["HOME"] = str(self.home_dir)
        try:
            with contextlib.redirect_stdout(stdout), contextlib.redirect_stderr(stderr):
                try:
                    rc = drs.main(argv)
                except SystemExit as exc:
                    rc = int(exc.code) if exc.code is not None else 0
        finally:
            if old_home is None:
                os.environ.pop("HOME", None)
            else:
                os.environ["HOME"] = old_home
        return rc, stdout.getvalue(), stderr.getvalue()

    def run_cli_subproc(
        self,
        argv: list[str],
        env: dict[str, str] | None = None,
    ) -> subprocess.CompletedProcess[str]:
        bin_path = os.environ.get("DETACHED_REPO_SYNC_BIN")
        if bin_path:
            cmd = [bin_path, *argv]
        else:
            cmd = [sys.executable, "-B", str(SCRIPT_PATH), *argv]
        run_env = self.git_env() if env is None else env
        return subprocess.run(cmd, env=run_env, capture_output=True, text=True, check=False)


class DetachedRepoSyncTests(BaseDetachedRepoTest):
    def test_t01_cli_missing_invalid_args_and_missing_config(self) -> None:
        rc_no_args, _, err_no_args = self.run_cli_inproc([])
        self.assertEqual(rc_no_args, 2)
        self.assertIn("usage:", err_no_args)

        rc_bad_cmd, _, err_bad_cmd = self.run_cli_inproc(["bogus", "foo.json"])
        self.assertEqual(rc_bad_cmd, 2)
        self.assertIn("invalid choice", err_bad_cmd)

        missing_cfg = self.cfg_dir / "missing.json"
        rc_missing, _, err_missing = self.run_cli_inproc(["status", str(missing_cfg)])
        self.assertEqual(rc_missing, 1)
        self.assertIn("cannot read config", err_missing)

    def test_t02_config_invalid_json_missing_fields_unsafe_name_path_traversal(self) -> None:
        bad_json = self.cfg_dir / "bad.json"
        bad_json.write_text("{not valid json", encoding="utf-8")
        rc, _, err = self.run_cli_inproc(["bootstrap", str(bad_json)])
        self.assertEqual(rc, 1)
        self.assertIn("invalid JSON", err)

        invalid_configs = [
            {"repoDir": "repo", "pullUrl": "https://example.invalid/r.git"},
            {"name": "ok", "pullUrl": "https://example.invalid/r.git"},
            {"name": "ok", "repoDir": "repo"},
            {"name": "../evil", "repoDir": "repo", "pullUrl": "https://example.invalid/r.git"},
            {"name": "a/b", "repoDir": "repo", "pullUrl": "https://example.invalid/r.git"},
            {
                "name": "ok",
                "homeDir": str(self.home_dir),
                "repoDir": "repo",
                "pullUrl": "https://example.invalid/r.git",
                "fanout": [{"from": "../outside", "into": [".agents/skills"]}],
            },
            {
                "name": "ok",
                "homeDir": str(self.home_dir),
                "repoDir": "repo",
                "pullUrl": "https://example.invalid/r.git",
                "links": [{"from": "a/../../outside", "to": ".file"}],
            },
        ]
        for idx, payload in enumerate(invalid_configs):
            cfg_path = self.write_config(payload, f"invalid_{idx}.json")
            rc, _, err = self.run_cli_inproc(["link", str(cfg_path)])
            self.assertEqual(rc, 1, f"expected rc=1 for invalid config #{idx}: {payload}")
            self.assertIn("error:", err)
        self.assertFalse((self.home_dir / "repo").exists())

    def test_t03_config_path_resolution_against_home_dir(self) -> None:
        other_home = self.root / "custom-home"
        other_home.mkdir()
        cfg_path = self.write_config(
            {
                "name": "sample",
                "homeDir": str(other_home),
                "repoDir": "Workspaces/repo",
                "pullUrl": str(self.remote_dir),
                "fanout": [{"from": "skills", "into": [".agents/skills", "~/alt/skills"]}],
                "links": [{"from": "README.md", "to": "~/.config/sample-readme.md"}],
            }
        )
        cfg = drs.load_config(cfg_path)
        self.assertEqual(cfg.home_dir, other_home.resolve())
        self.assertEqual(cfg.repo_dir, other_home.resolve() / "Workspaces" / "repo")
        self.assertEqual(cfg.branch, "main")
        self.assertEqual(
            cfg.state_dir,
            other_home.resolve() / ".local" / "state" / "detached-repos",
        )
        self.assertEqual(
            cfg.fanout[0].into_dirs,
            (
                other_home.resolve() / ".agents" / "skills",
                other_home.resolve() / "alt" / "skills",
            ),
        )
        self.assertEqual(
            cfg.links[0].to_path,
            other_home.resolve() / ".config" / "sample-readme.md",
        )

    def test_t04_bootstrap_fresh_clone_creates_parents_pushurl_and_links(self) -> None:
        self.init_remote_with_skills()
        cfg_path = self.write_config(self.default_config_dict())
        rc, _, err = self.run_cli_inproc(["bootstrap", str(cfg_path)])
        self.assertEqual(rc, 0, err)

        repo_dir = self.home_dir / "Workspaces" / "gdr" / "agentic"
        self.assertTrue((repo_dir / ".git").is_dir())
        pushurl = self.git(["config", "--get", "remote.origin.pushurl"], cwd=repo_dir).stdout.strip()
        self.assertEqual(pushurl, "ssh://example.invalid/gdr/agentic.git")

        for into_rel in (".agents/skills", ".claude/skills"):
            into_dir = self.home_dir / into_rel
            self.assertTrue(into_dir.is_dir())
            self.assertFalse(into_dir.is_symlink())
            self.assertEqual(
                (into_dir / "alpha").resolve(strict=True),
                (repo_dir / "skills" / "alpha").resolve(strict=True),
            )
            self.assertEqual(
                (into_dir / "beta").resolve(strict=True),
                (repo_dir / "skills" / "beta").resolve(strict=True),
            )

    def test_t05_bootstrap_offline_unreachable_warns_and_exits_zero(self) -> None:
        cfg_path = self.write_config(
            self.default_config_dict(pullUrl=f"file://{self.root / 'nonexistent-remote.git'}")
        )
        rc, _, err = self.run_cli_inproc(["bootstrap", str(cfg_path)])
        self.assertEqual(rc, 0)
        self.assertIn("warning:", err)
        repo_dir = self.home_dir / "Workspaces" / "gdr" / "agentic"
        self.assertFalse(repo_dir.exists())

    def test_t06_bootstrap_idempotent_rerun_and_pushurl_update_unset(self) -> None:
        self.init_remote_with_skills()
        cfg_path = self.write_config(self.default_config_dict())
        rc1, _, _ = self.run_cli_inproc(["bootstrap", str(cfg_path)])
        self.assertEqual(rc1, 0)

        repo_dir = self.home_dir / "Workspaces" / "gdr" / "agentic"
        local_note = repo_dir / "local-wip.txt"
        local_note.write_text("keep me\n", encoding="utf-8")

        cfg_updated = self.write_config(
            self.default_config_dict(pushUrl="ssh://example.invalid/gdr/new-agentic.git"),
            "repo_updated.json",
        )
        rc2, _, _ = self.run_cli_inproc(["bootstrap", str(cfg_updated)])
        self.assertEqual(rc2, 0)
        pushurl = self.git(["config", "--get", "remote.origin.pushurl"], cwd=repo_dir).stdout.strip()
        self.assertEqual(pushurl, "ssh://example.invalid/gdr/new-agentic.git")
        self.assertEqual(local_note.read_text(encoding="utf-8"), "keep me\n")

        cfg_null = self.write_config(self.default_config_dict(pushUrl=None), "repo_null.json")
        rc3, _, err3 = self.run_cli_inproc(["bootstrap", str(cfg_null)])
        self.assertEqual(rc3, 0, err3)
        res = subprocess.run(
            ["git", "-C", str(repo_dir), "config", "--get-all", "remote.origin.pushurl"],
            env=self.git_env(),
            capture_output=True,
            text=True,
            check=False,
        )
        self.assertNotEqual(res.returncode, 0)

        # Re-running with pushUrl=None when already unset must remain clean and exit 0.
        rc4, _, err4 = self.run_cli_inproc(["bootstrap", str(cfg_null)])
        self.assertEqual(rc4, 0)
        self.assertEqual(err4, "")

    def test_t07_bootstrap_preexisting_nonempty_dir_file_or_broken_symlink_not_clobbered(self) -> None:
        self.init_remote_with_skills()
        repo_dir = self.home_dir / "Workspaces" / "gdr" / "agentic"
        repo_dir.mkdir(parents=True, exist_ok=True)
        keep_file = repo_dir / "important.txt"
        keep_file.write_text("user data\n", encoding="utf-8")

        cfg_path = self.write_config(self.default_config_dict())
        rc, _, err = self.run_cli_inproc(["bootstrap", str(cfg_path)])
        self.assertEqual(rc, 0)
        self.assertIn("warning:", err)
        self.assertEqual(keep_file.read_text(encoding="utf-8"), "user data\n")
        self.assertFalse((repo_dir / ".git").exists())

        # File at repoDir
        file_repo = self.home_dir / "file-repo"
        file_repo.write_text("plain file\n", encoding="utf-8")
        cfg_file = self.write_config(
            self.default_config_dict(repoDir=str(file_repo)),
            "file_repo.json",
        )
        rc_file, _, err_file = self.run_cli_inproc(["bootstrap", str(cfg_file)])
        self.assertEqual(rc_file, 0)
        self.assertIn("warning:", err_file)
        self.assertEqual(file_repo.read_text(encoding="utf-8"), "plain file\n")

        # Broken symlink at repoDir
        broken_repo = self.home_dir / "broken-repo"
        broken_repo.symlink_to(self.root / "does-not-exist")
        cfg_sym = self.write_config(
            self.default_config_dict(repoDir=str(broken_repo)),
            "broken_repo.json",
        )
        rc_sym, _, err_sym = self.run_cli_inproc(["bootstrap", str(cfg_sym)])
        self.assertEqual(rc_sym, 0)
        self.assertIn("warning:", err_sym)
        self.assertTrue(broken_repo.is_symlink())

    def test_t08_bootstrap_empty_dir_inside_parent_git_repo(self) -> None:
        self.init_remote_with_skills()
        parent_repo = self.home_dir / "Workspaces"
        parent_repo.mkdir(parents=True, exist_ok=True)
        self.git(["init", str(parent_repo)])
        (parent_repo / "README.md").write_text("parent\n", encoding="utf-8")
        self.git(["add", "README.md"], cwd=parent_repo)
        self.git(["commit", "-m", "parent init"], cwd=parent_repo)

        nested_empty = parent_repo / "gdr" / "agentic"
        nested_empty.mkdir(parents=True, exist_ok=True)
        self.assertFalse(drs.is_git_repo(nested_empty))

        cfg_path = self.write_config(self.default_config_dict())
        rc, _, err = self.run_cli_inproc(["bootstrap", str(cfg_path)])
        self.assertEqual(rc, 0, err)
        self.assertTrue(drs.is_git_repo(nested_empty))
        self.assertTrue((self.home_dir / ".agents" / "skills" / "alpha").is_symlink())

    def test_t09_pull_fast_forwards_clean_tracked_branch_and_links_new_skill(self) -> None:
        self.init_remote_with_skills()
        cfg_path = self.write_config(self.default_config_dict())
        self.assertEqual(self.run_cli_inproc(["bootstrap", str(cfg_path)])[0], 0)

        new_sha = self.commit_upstream_file("skills/gamma/SKILL.md", "# Gamma\n", "add gamma")
        rc, _, err = self.run_cli_inproc(["pull", str(cfg_path)])
        self.assertEqual(rc, 0, err)

        repo_dir = self.home_dir / "Workspaces" / "gdr" / "agentic"
        head_sha = self.git(["rev-parse", "HEAD"], cwd=repo_dir).stdout.strip()
        self.assertEqual(head_sha, new_sha)
        self.assertTrue((self.home_dir / ".agents" / "skills" / "gamma").is_symlink())
        self.assertTrue((self.home_dir / ".claude" / "skills" / "gamma").is_symlink())

    def test_t10_pull_already_up_to_date_noop(self) -> None:
        self.init_remote_with_skills()
        cfg_path = self.write_config(self.default_config_dict())
        self.assertEqual(self.run_cli_inproc(["bootstrap", str(cfg_path)])[0], 0)

        repo_dir = self.home_dir / "Workspaces" / "gdr" / "agentic"
        before_sha = self.git(["rev-parse", "HEAD"], cwd=repo_dir).stdout.strip()
        rc, out, err = self.run_cli_inproc(["pull", str(cfg_path)])
        self.assertEqual(rc, 0)
        self.assertEqual(out, "")
        self.assertEqual(err, "")
        after_sha = self.git(["rev-parse", "HEAD"], cwd=repo_dir).stdout.strip()
        self.assertEqual(before_sha, after_sha)

    def test_t11_pull_skips_silently_on_dirty_staged_and_unstaged(self) -> None:
        self.init_remote_with_skills()
        cfg_path = self.write_config(self.default_config_dict())
        self.assertEqual(self.run_cli_inproc(["bootstrap", str(cfg_path)])[0], 0)

        repo_dir = self.home_dir / "Workspaces" / "gdr" / "agentic"
        before_sha = self.git(["rev-parse", "HEAD"], cwd=repo_dir).stdout.strip()

        # Unstaged modification
        skill_file = repo_dir / "skills" / "alpha" / "SKILL.md"
        skill_file.write_text("# Alpha local edit\n", encoding="utf-8")
        self.commit_upstream_file("skills/gamma/SKILL.md", "# Gamma\n", "add gamma")

        rc, out, err = self.run_cli_inproc(["pull", str(cfg_path)])
        self.assertEqual(rc, 0)
        self.assertEqual(out, "")
        self.assertEqual(err, "")
        self.assertEqual(self.git(["rev-parse", "HEAD"], cwd=repo_dir).stdout.strip(), before_sha)
        self.assertEqual(skill_file.read_text(encoding="utf-8"), "# Alpha local edit\n")

        # Staged modification
        self.git(["add", "skills/alpha/SKILL.md"], cwd=repo_dir)
        rc2, out2, err2 = self.run_cli_inproc(["pull", str(cfg_path)])
        self.assertEqual(rc2, 0)
        self.assertEqual(out2, "")
        self.assertEqual(err2, "")
        self.assertEqual(self.git(["rev-parse", "HEAD"], cwd=repo_dir).stdout.strip(), before_sha)

    def test_t12_pull_skips_silently_on_untracked_file(self) -> None:
        self.init_remote_with_skills()
        cfg_path = self.write_config(self.default_config_dict())
        self.assertEqual(self.run_cli_inproc(["bootstrap", str(cfg_path)])[0], 0)

        repo_dir = self.home_dir / "Workspaces" / "gdr" / "agentic"
        before_sha = self.git(["rev-parse", "HEAD"], cwd=repo_dir).stdout.strip()
        untracked = repo_dir / "skills" / "local-draft" / "SKILL.md"
        untracked.parent.mkdir(parents=True, exist_ok=True)
        untracked.write_text("# Draft\n", encoding="utf-8")

        self.commit_upstream_file("skills/gamma/SKILL.md", "# Gamma\n", "add gamma")
        rc, out, err = self.run_cli_inproc(["pull", str(cfg_path)])
        self.assertEqual(rc, 0)
        self.assertEqual(out, "")
        self.assertEqual(err, "")
        self.assertEqual(self.git(["rev-parse", "HEAD"], cwd=repo_dir).stdout.strip(), before_sha)
        self.assertEqual(untracked.read_text(encoding="utf-8"), "# Draft\n")
        # link still runs against local working tree
        self.assertTrue((self.home_dir / ".agents" / "skills" / "local-draft").is_symlink())

    def test_t13_pull_skips_silently_on_wrong_branch_or_detached_head(self) -> None:
        self.init_remote_with_skills()
        cfg_path = self.write_config(self.default_config_dict())
        self.assertEqual(self.run_cli_inproc(["bootstrap", str(cfg_path)])[0], 0)

        repo_dir = self.home_dir / "Workspaces" / "gdr" / "agentic"
        base_sha = self.git(["rev-parse", "HEAD"], cwd=repo_dir).stdout.strip()
        self.commit_upstream_file("skills/gamma/SKILL.md", "# Gamma\n", "add gamma")

        # Wrong branch
        self.git(["checkout", "-b", "feature"], cwd=repo_dir)
        rc, out, err = self.run_cli_inproc(["pull", str(cfg_path)])
        self.assertEqual(rc, 0)
        self.assertEqual(out, "")
        self.assertEqual(err, "")
        self.assertEqual(
            self.git(["symbolic-ref", "--short", "HEAD"], cwd=repo_dir).stdout.strip(),
            "feature",
        )
        self.assertEqual(self.git(["rev-parse", "HEAD"], cwd=repo_dir).stdout.strip(), base_sha)

        # Detached HEAD
        self.git(["checkout", "--detach", base_sha], cwd=repo_dir)
        rc2, out2, err2 = self.run_cli_inproc(["pull", str(cfg_path)])
        self.assertEqual(rc2, 0)
        self.assertEqual(out2, "")
        self.assertEqual(err2, "")
        self.assertEqual(self.git(["rev-parse", "HEAD"], cwd=repo_dir).stdout.strip(), base_sha)

    def test_t14_pull_skips_silently_when_local_ahead(self) -> None:
        self.init_remote_with_skills()
        cfg_path = self.write_config(self.default_config_dict())
        self.assertEqual(self.run_cli_inproc(["bootstrap", str(cfg_path)])[0], 0)

        repo_dir = self.home_dir / "Workspaces" / "gdr" / "agentic"
        local_skill = repo_dir / "skills" / "local-only" / "SKILL.md"
        local_skill.parent.mkdir(parents=True, exist_ok=True)
        local_skill.write_text("# Local\n", encoding="utf-8")
        self.git(["add", "-A"], cwd=repo_dir)
        self.git(["commit", "-m", "local ahead commit"], cwd=repo_dir)
        ahead_sha = self.git(["rev-parse", "HEAD"], cwd=repo_dir).stdout.strip()

        rc, out, err = self.run_cli_inproc(["pull", str(cfg_path)])
        self.assertEqual(rc, 0)
        self.assertEqual(out, "")
        self.assertEqual(err, "")
        self.assertEqual(self.git(["rev-parse", "HEAD"], cwd=repo_dir).stdout.strip(), ahead_sha)
        self.assertTrue((self.home_dir / ".agents" / "skills" / "local-only").is_symlink())

    def test_t15_pull_skips_silently_on_diverged_branch(self) -> None:
        self.init_remote_with_skills()
        cfg_path = self.write_config(self.default_config_dict())
        self.assertEqual(self.run_cli_inproc(["bootstrap", str(cfg_path)])[0], 0)

        repo_dir = self.home_dir / "Workspaces" / "gdr" / "agentic"
        (repo_dir / "skills" / "alpha" / "SKILL.md").write_text("# Local diverged\n", encoding="utf-8")
        self.git(["add", "-A"], cwd=repo_dir)
        self.git(["commit", "-m", "local diverge"], cwd=repo_dir)
        local_sha = self.git(["rev-parse", "HEAD"], cwd=repo_dir).stdout.strip()

        self.commit_upstream_file("skills/alpha/SKILL.md", "# Remote diverged\n", "remote diverge")

        rc, out, err = self.run_cli_inproc(["pull", str(cfg_path)])
        self.assertEqual(rc, 0)
        self.assertEqual(out, "")
        self.assertEqual(err, "")
        self.assertEqual(self.git(["rev-parse", "HEAD"], cwd=repo_dir).stdout.strip(), local_sha)
        self.assertEqual(
            (repo_dir / "skills" / "alpha" / "SKILL.md").read_text(encoding="utf-8"),
            "# Local diverged\n",
        )

    def test_t16_pull_offline_warns_exits_zero_and_still_links(self) -> None:
        self.init_remote_with_skills()
        cfg_path = self.write_config(self.default_config_dict())
        self.assertEqual(self.run_cli_inproc(["bootstrap", str(cfg_path)])[0], 0)

        repo_dir = self.home_dir / "Workspaces" / "gdr" / "agentic"
        self.git(
            ["remote", "set-url", "origin", f"file://{self.root / 'offline.git'}"],
            cwd=repo_dir,
        )
        # Add a new local skill that should still be linked despite offline fetch warning.
        local_skill = repo_dir / "skills" / "offline-added" / "SKILL.md"
        local_skill.parent.mkdir(parents=True, exist_ok=True)
        local_skill.write_text("# Offline\n", encoding="utf-8")

        rc, _, err = self.run_cli_inproc(["pull", str(cfg_path)])
        self.assertEqual(rc, 0)
        self.assertIn("warning:", err)
        self.assertTrue((self.home_dir / ".agents" / "skills" / "offline-added").is_symlink())

    def test_t17_pull_when_repo_missing_delegates_to_bootstrap(self) -> None:
        self.init_remote_with_skills()
        cfg_path = self.write_config(self.default_config_dict())
        rc, _, err = self.run_cli_inproc(["pull", str(cfg_path)])
        self.assertEqual(rc, 0, err)
        repo_dir = self.home_dir / "Workspaces" / "gdr" / "agentic"
        self.assertTrue(drs.is_git_repo(repo_dir))
        self.assertTrue((self.home_dir / ".agents" / "skills" / "alpha").is_symlink())

    def test_t18_link_fanout_require_file_multiple_real_target_dirs(self) -> None:
        self.init_remote_with_skills(
            skills={
                "valid-skill": {"SKILL.md": "# Valid\n"},
                "incomplete-skill": {"notes.md": "no skill md\n"},
            },
            extra_files={
                "skills/.gitkeep": "",
                "skills/README.md": "readme\n",
            },
        )
        cfg_path = self.write_config(self.default_config_dict())
        self.assertEqual(self.run_cli_inproc(["bootstrap", str(cfg_path)])[0], 0)

        for into_rel in (".agents/skills", ".claude/skills"):
            into_dir = self.home_dir / into_rel
            self.assertTrue(into_dir.is_dir())
            self.assertFalse(into_dir.is_symlink())
            self.assertTrue((into_dir / "valid-skill").is_symlink())
            self.assertFalse((into_dir / "incomplete-skill").exists())
            self.assertFalse((into_dir / ".gitkeep").exists())
            self.assertFalse((into_dir / "README.md").exists())

    def test_t19_link_fanout_without_require_file_and_direct_links(self) -> None:
        self.init_remote_with_skills(
            skills={"alpha": {"SKILL.md": "# Alpha\n"}},
            extra_files={
                "rules/.gitkeep": "",
                "rules/style.md": "style\n",
                "README.md": "# Repo Readme\n",
            },
        )
        cfg_path = self.write_config(
            self.default_config_dict(
                fanout=[
                    {
                        "from": "rules",
                        "into": [".agents/rules"],
                        "requireFile": None,
                    }
                ],
                links=[
                    {
                        "from": "README.md",
                        "to": ".agents/AGENTIC_README.md",
                    }
                ],
            )
        )
        self.assertEqual(self.run_cli_inproc(["bootstrap", str(cfg_path)])[0], 0)

        rules_into = self.home_dir / ".agents" / "rules"
        self.assertTrue((rules_into / "style.md").is_symlink())
        self.assertFalse((rules_into / ".gitkeep").exists())
        self.assertTrue((self.home_dir / ".agents" / "AGENTIC_README.md").is_symlink())

        manifest = json.loads((self.state_dir / "agentic.json").read_text(encoding="utf-8"))
        recorded_tos = {item["to"] for item in manifest["links"]}
        self.assertIn(str(rules_into / "style.md"), recorded_tos)
        self.assertIn(str(self.home_dir / ".agents" / "AGENTIC_README.md"), recorded_tos)

    def test_t20_link_preserves_existing_regular_file_and_real_dir(self) -> None:
        self.init_remote_with_skills()
        agents_dir = self.home_dir / ".agents" / "skills"
        agents_dir.mkdir(parents=True, exist_ok=True)
        existing_file = agents_dir / "alpha"
        existing_file.write_text("user file\n", encoding="utf-8")
        existing_dir = agents_dir / "beta"
        existing_dir.mkdir()
        (existing_dir / "custom.txt").write_text("user dir\n", encoding="utf-8")

        cfg_path = self.write_config(self.default_config_dict())
        rc, _, err = self.run_cli_inproc(["bootstrap", str(cfg_path)])
        self.assertEqual(rc, 0)
        self.assertIn("preserving existing non-symlink path", err)
        self.assertFalse(existing_file.is_symlink())
        self.assertEqual(existing_file.read_text(encoding="utf-8"), "user file\n")
        self.assertFalse(existing_dir.is_symlink())
        self.assertEqual((existing_dir / "custom.txt").read_text(encoding="utf-8"), "user dir\n")

        manifest = json.loads((self.state_dir / "agentic.json").read_text(encoding="utf-8"))
        recorded_tos = {item["to"] for item in manifest["links"]}
        self.assertNotIn(str(existing_file), recorded_tos)
        self.assertNotIn(str(existing_dir), recorded_tos)
        self.assertIn(str(self.home_dir / ".claude" / "skills" / "alpha"), recorded_tos)

    def test_t21_link_preserves_existing_foreign_symlink(self) -> None:
        self.init_remote_with_skills()
        foreign_target = self.root / "foreign-alpha"
        foreign_target.mkdir()
        (foreign_target / "SKILL.md").write_text("# Foreign\n", encoding="utf-8")

        agents_dir = self.home_dir / ".agents" / "skills"
        agents_dir.mkdir(parents=True, exist_ok=True)
        foreign_link = agents_dir / "alpha"
        foreign_link.symlink_to(foreign_target)

        cfg_path = self.write_config(self.default_config_dict())
        rc, _, err = self.run_cli_inproc(["bootstrap", str(cfg_path)])
        self.assertEqual(rc, 0)
        self.assertIn("preserving foreign symlink", err)
        self.assertEqual(foreign_link.resolve(strict=True), foreign_target.resolve(strict=True))

        manifest = json.loads((self.state_dir / "agentic.json").read_text(encoding="utf-8"))
        recorded_tos = {item["to"] for item in manifest["links"]}
        self.assertNotIn(str(foreign_link), recorded_tos)

    def test_t22_link_preserves_target_into_when_symlink_or_file(self) -> None:
        self.init_remote_with_skills()
        external_dir = self.root / "external-skills-dir"
        external_dir.mkdir()
        agents_parent = self.home_dir / ".agents"
        agents_parent.mkdir(parents=True, exist_ok=True)
        sym_into = agents_parent / "skills"
        sym_into.symlink_to(external_dir)

        claude_parent = self.home_dir / ".claude"
        claude_parent.mkdir(parents=True, exist_ok=True)
        file_into = claude_parent / "skills"
        file_into.write_text("not a dir\n", encoding="utf-8")

        third_into = self.home_dir / ".third" / "skills"
        cfg_path = self.write_config(
            self.default_config_dict(
                fanout=[
                    {
                        "from": "skills",
                        "into": [".agents/skills", ".claude/skills", str(third_into)],
                        "requireFile": "SKILL.md",
                    }
                ]
            )
        )
        rc, _, err = self.run_cli_inproc(["bootstrap", str(cfg_path)])
        self.assertEqual(rc, 0)
        self.assertIn("is a symlink; skipping", err)
        self.assertIn("not a real directory; skipping", err)
        self.assertTrue(sym_into.is_symlink())
        self.assertEqual(list(external_dir.iterdir()), [])
        self.assertEqual(file_into.read_text(encoding="utf-8"), "not a dir\n")
        self.assertTrue((third_into / "alpha").is_symlink())

    def test_t23_link_prunes_stale_manifest_symlinks_on_delete_or_missing_require_file(self) -> None:
        self.init_remote_with_skills()
        cfg_path = self.write_config(self.default_config_dict())
        self.assertEqual(self.run_cli_inproc(["bootstrap", str(cfg_path)])[0], 0)

        agents_dir = self.home_dir / ".agents" / "skills"
        unrelated_target = self.root / "unrelated-skill"
        unrelated_target.mkdir()
        unrelated_link = agents_dir / "unrelated"
        unrelated_link.symlink_to(unrelated_target)
        real_file = agents_dir / "keep.txt"
        real_file.write_text("keep\n", encoding="utf-8")

        # Upstream deletes beta and removes SKILL.md from alpha.
        self.git(["rm", "-r", "skills/beta", "skills/alpha/SKILL.md"], cwd=self.work_dir)
        alpha_dir = self.work_dir / "skills" / "alpha"
        alpha_dir.mkdir(parents=True, exist_ok=True)
        (alpha_dir / "notes.md").write_text("only notes\n", encoding="utf-8")
        self.git(["add", "-A"], cwd=self.work_dir)
        self.git(["commit", "-m", "remove beta and alpha SKILL.md"], cwd=self.work_dir)
        self.git(["push", "origin", "HEAD"], cwd=self.work_dir)

        rc, _, err = self.run_cli_inproc(["pull", str(cfg_path)])
        self.assertEqual(rc, 0, err)
        self.assertFalse((agents_dir / "beta").is_symlink())
        self.assertFalse((agents_dir / "alpha").is_symlink())
        self.assertFalse((self.home_dir / ".claude" / "skills" / "beta").is_symlink())
        self.assertTrue(unrelated_link.is_symlink())
        self.assertEqual(real_file.read_text(encoding="utf-8"), "keep\n")

    def test_t24_link_does_not_prune_if_user_replaced_managed_symlink(self) -> None:
        self.init_remote_with_skills()
        cfg_path = self.write_config(self.default_config_dict())
        self.assertEqual(self.run_cli_inproc(["bootstrap", str(cfg_path)])[0], 0)

        agents_dir = self.home_dir / ".agents" / "skills"
        # Replace alpha symlink with a foreign symlink
        foreign_target = self.root / "user-custom-alpha"
        foreign_target.mkdir()
        (agents_dir / "alpha").unlink()
        (agents_dir / "alpha").symlink_to(foreign_target)

        # Replace beta symlink with a real file
        (agents_dir / "beta").unlink()
        (agents_dir / "beta").write_text("user local skill file\n", encoding="utf-8")

        # Delete both upstream
        self.git(["rm", "-r", "skills/alpha", "skills/beta"], cwd=self.work_dir)
        (self.work_dir / "README.md").write_text("empty skills\n", encoding="utf-8")
        self.git(["add", "-A"], cwd=self.work_dir)
        self.git(["commit", "-m", "delete skills"], cwd=self.work_dir)
        self.git(["push", "origin", "HEAD"], cwd=self.work_dir)

        rc, _, _ = self.run_cli_inproc(["pull", str(cfg_path)])
        self.assertEqual(rc, 0)
        self.assertTrue((agents_dir / "alpha").is_symlink())
        self.assertEqual((agents_dir / "alpha").resolve(strict=True), foreign_target.resolve())
        self.assertFalse((agents_dir / "beta").is_symlink())
        self.assertEqual((agents_dir / "beta").read_text(encoding="utf-8"), "user local skill file\n")

    def test_t25_link_corrupt_manifest_recovery_and_rejects_escaping_repo_symlink(self) -> None:
        self.init_remote_with_skills()
        cfg_path = self.write_config(self.default_config_dict())
        self.assertEqual(self.run_cli_inproc(["bootstrap", str(cfg_path)])[0], 0)

        # Corrupt manifest
        manifest_path = self.state_dir / "agentic.json"
        manifest_path.write_text("{corrupt", encoding="utf-8")

        # Create a symlink inside repo/skills pointing outside repoDir
        outside_skill = self.root / "outside-evil-skill"
        outside_skill.mkdir()
        (outside_skill / "SKILL.md").write_text("# Outside\n", encoding="utf-8")
        repo_dir = self.home_dir / "Workspaces" / "gdr" / "agentic"
        (repo_dir / "skills" / "escape-skill").symlink_to(outside_skill)

        rc, _, err = self.run_cli_inproc(["link", str(cfg_path)])
        self.assertEqual(rc, 0)
        self.assertIn("malformed manifest", err)
        self.assertIn("escapes repoDir", err)
        self.assertFalse((self.home_dir / ".agents" / "skills" / "escape-skill").exists())
        self.assertTrue((self.home_dir / ".agents" / "skills" / "alpha").is_symlink())

    def test_t26_status_and_wrapper_integration_with_empty_path(self) -> None:
        self.init_remote_with_skills()
        cfg_path = self.write_config(self.default_config_dict())

        # Uncloned status via wrapper/CLI with stripped PATH
        stripped_env = {"HOME": str(self.home_dir), "PATH": ""}
        res_uncloned = self.run_cli_subproc(
            ["status", "--json", str(cfg_path)],
            env=stripped_env if os.environ.get("DETACHED_REPO_SYNC_BIN") else self.git_env(),
        )
        self.assertEqual(res_uncloned.returncode, 0, res_uncloned.stderr)
        data_uncloned = json.loads(res_uncloned.stdout)
        self.assertFalse(data_uncloned["exists"])
        self.assertEqual(data_uncloned["upstreamState"], "uncloned")

        # Bootstrap via wrapper with stripped PATH
        res_boot = self.run_cli_subproc(
            ["bootstrap", str(cfg_path)],
            env=stripped_env if os.environ.get("DETACHED_REPO_SYNC_BIN") else self.git_env(),
        )
        self.assertEqual(res_boot.returncode, 0, res_boot.stderr)

        # Human-readable text status
        res_text = self.run_cli_subproc(
            ["status", str(cfg_path)],
            env=stripped_env if os.environ.get("DETACHED_REPO_SYNC_BIN") else self.git_env(),
        )
        self.assertEqual(res_text.returncode, 0, res_text.stderr)
        self.assertIn("upstreamState: up-to-date", res_text.stdout)

        # Behind + dirty + broken link status
        self.commit_upstream_file("skills/gamma/SKILL.md", "# Gamma\n", "add gamma")
        repo_dir = self.home_dir / "Workspaces" / "gdr" / "agentic"
        self.git(["fetch", "--quiet", "origin", "main"], cwd=repo_dir)
        (repo_dir / "skills" / "alpha" / "SKILL.md").write_text("# Dirty\n", encoding="utf-8")
        # Create a dangling symlink recorded in manifest by deleting target dir locally
        for p in (repo_dir / "skills" / "beta").iterdir():
            p.unlink()
        (repo_dir / "skills" / "beta").rmdir()

        res_dirty = self.run_cli_subproc(
            ["status", "--json", str(cfg_path)],
            env=stripped_env if os.environ.get("DETACHED_REPO_SYNC_BIN") else self.git_env(),
        )
        self.assertEqual(res_dirty.returncode, 0, res_dirty.stderr)
        data_dirty = json.loads(res_dirty.stdout)
        self.assertTrue(data_dirty["exists"])
        self.assertTrue(data_dirty["isGitRepo"])
        self.assertTrue(data_dirty["dirty"])
        self.assertEqual(data_dirty["upstreamState"], "behind")
        self.assertEqual(data_dirty["behind"], 1)
        self.assertEqual(data_dirty["managedCount"], 4)
        self.assertEqual(data_dirty["healthyCount"], 2)
        self.assertEqual(len(data_dirty["brokenLinks"]), 2)

        # Verify wrapper exports CA cert paths when DETACHED_REPO_SYNC_BIN is set
        bin_path = os.environ.get("DETACHED_REPO_SYNC_BIN")
        if bin_path:
            wrapper_text = Path(bin_path).read_text(encoding="utf-8")
            for var_name in ("GIT_SSL_CAINFO", "SSL_CERT_FILE"):
                match = re.search(rf"^{var_name}=['\"]?([^'\"\s]+)['\"]?$", wrapper_text, re.MULTILINE)
                self.assertIsNotNone(match, f"missing {var_name} definition in wrapper")
                assert match is not None
                self.assertIn(f"export {var_name}", wrapper_text)
                self.assertTrue(Path(match.group(1)).is_file(), f"missing cert file {match.group(1)}")

    def test_t27_link_does_not_prune_when_into_or_ancestor_becomes_symlink(self) -> None:
        self.init_remote_with_skills()
        cfg_path = self.write_config(self.default_config_dict())
        self.assertEqual(self.run_cli_inproc(["bootstrap", str(cfg_path)])[0], 0)

        repo_dir = self.home_dir / "Workspaces" / "gdr" / "agentic"
        agents_skills = self.home_dir / ".agents" / "skills"
        self.assertTrue((agents_skills / "alpha").is_symlink())

        # Replace `into` (.agents/skills) with a symlink to an external directory
        # that happens to contain a symlink pointing inside repoDir.
        external_vault = self.root / "external-skills-vault"
        external_vault.mkdir()
        (external_vault / "alpha").symlink_to(repo_dir / "skills" / "alpha")
        for child in list(agents_skills.iterdir()):
            child.unlink()
        agents_skills.rmdir()
        agents_skills.symlink_to(external_vault)

        rc, _, err = self.run_cli_inproc(["link", str(cfg_path)])
        self.assertEqual(rc, 0, err)
        self.assertIn("is a symlink; skipping", err)
        self.assertIn("skipping prune under non-real/symlinked parent", err)
        self.assertTrue((external_vault / "alpha").is_symlink())
        self.assertEqual(
            (external_vault / "alpha").resolve(strict=True),
            (repo_dir / "skills" / "alpha").resolve(strict=True),
        )

        # Also verify ancestor becoming a symlink (.claude -> external_parent)
        # does not prune inside external_parent/skills when upstream deletes beta.
        claude_dir = self.home_dir / ".claude"
        external_claude = self.root / "external-claude"
        (external_claude / "skills").mkdir(parents=True)
        (external_claude / "skills" / "beta").symlink_to(repo_dir / "skills" / "beta")
        for child in list((claude_dir / "skills").iterdir()):
            child.unlink()
        (claude_dir / "skills").rmdir()
        claude_dir.rmdir()
        claude_dir.symlink_to(external_claude)

        self.git(["rm", "-r", "skills/beta"], cwd=self.work_dir)
        self.git(["commit", "-m", "remove beta"], cwd=self.work_dir)
        self.git(["push", "origin", "HEAD"], cwd=self.work_dir)

        rc2, _, err2 = self.run_cli_inproc(["pull", str(cfg_path)])
        self.assertEqual(rc2, 0, err2)
        self.assertIn("skipping prune under non-real/symlinked parent", err2)
        self.assertTrue((external_claude / "skills" / "beta").is_symlink())

    def test_t28_pull_single_branch_clone_switched_to_second_branch(self) -> None:
        self.init_remote_with_skills(branch="main")
        self.git(["checkout", "-b", "other"], cwd=self.work_dir)
        self.git(["push", "-u", "origin", "other"], cwd=self.work_dir)
        self.git(["checkout", "main"], cwd=self.work_dir)

        repo_dir = self.home_dir / "Workspaces" / "gdr" / "agentic"
        repo_dir.parent.mkdir(parents=True, exist_ok=True)
        self.git(
            ["clone", "--single-branch", "--branch", "main", str(self.remote_dir), str(repo_dir)]
        )
        # Switch the single-branch clone onto `other` matching remote `other` at base commit.
        self.git(["fetch", "origin", "other:refs/heads/other"], cwd=repo_dir)
        self.git(["checkout", "other"], cwd=repo_dir)

        # Push a new commit to remote `other`.
        self.git(["checkout", "other"], cwd=self.work_dir)
        new_other_sha = self.commit_upstream_file("skills/gamma/SKILL.md", "# Gamma\n", "add gamma")

        cfg_path = self.write_config(self.default_config_dict(branch="other"))
        rc, _, err = self.run_cli_inproc(["pull", str(cfg_path)])
        self.assertEqual(rc, 0, err)
        self.assertEqual(self.git(["rev-parse", "HEAD"], cwd=repo_dir).stdout.strip(), new_other_sha)
        self.assertTrue((self.home_dir / ".agents" / "skills" / "gamma").is_symlink())
        self.assertTrue((self.home_dir / ".claude" / "skills" / "gamma").is_symlink())

    def test_t29_pull_skips_revert_sequencer_and_unreadable_repodir(self) -> None:
        self.init_remote_with_skills()
        cfg_path = self.write_config(self.default_config_dict())
        self.assertEqual(self.run_cli_inproc(["bootstrap", str(cfg_path)])[0], 0)

        repo_dir = self.home_dir / "Workspaces" / "gdr" / "agentic"
        before_sha = self.git(["rev-parse", "HEAD"], cwd=repo_dir).stdout.strip()
        self.commit_upstream_file("skills/gamma/SKILL.md", "# Gamma\n", "add gamma")

        # REVERT_HEAD marker blocks fast-forward
        revert_head = repo_dir / ".git" / "REVERT_HEAD"
        revert_head.write_text(f"{before_sha}\n", encoding="utf-8")
        try:
            rc1, _, err1 = self.run_cli_inproc(["pull", str(cfg_path)])
            self.assertEqual(rc1, 0, err1)
            self.assertEqual(self.git(["rev-parse", "HEAD"], cwd=repo_dir).stdout.strip(), before_sha)
        finally:
            revert_head.unlink(missing_ok=True)

        # sequencer directory marker blocks fast-forward
        seq_dir = repo_dir / ".git" / "sequencer"
        seq_dir.mkdir()
        try:
            rc2, _, err2 = self.run_cli_inproc(["pull", str(cfg_path)])
            self.assertEqual(rc2, 0, err2)
            self.assertEqual(self.git(["rev-parse", "HEAD"], cwd=repo_dir).stdout.strip(), before_sha)
        finally:
            seq_dir.rmdir()

        # Unreadable non-git repoDir warns and exits 0 (skip chmod check if running as uid 0)
        if os.geteuid() != 0:
            locked_dir = self.home_dir / "locked-repo"
            locked_dir.mkdir()
            locked_dir.chmod(0o000)
            try:
                cfg_locked = self.write_config(
                    self.default_config_dict(repoDir=str(locked_dir)),
                    "locked.json",
                )
                rc3, _, err3 = self.run_cli_inproc(["pull", str(cfg_locked)])
                self.assertEqual(rc3, 0)
                self.assertIn("cannot inspect repoDir", err3)
            finally:
                locked_dir.chmod(0o755)

    def test_t30_bug_d1_rejects_leading_dash_urls_and_passes_double_dash(self) -> None:
        self.init_remote_with_skills()
        for field in ("pullUrl", "pushUrl"):
            for bad_url in ("-evil", " -evil"):
                cfg_path = self.write_config(
                    self.default_config_dict(**{field: bad_url}),
                    f"bad_{field}_{bad_url.strip()}.json",
                )
                rc, _, err = self.run_cli_inproc(["bootstrap", str(cfg_path)])
                self.assertEqual(rc, 1, f"expected rc=1 for {field}={bad_url!r}")
                self.assertIn("error:", err)

        # Verify ensure_remotes handles missing origin and updates pullUrl/pushUrl safely with --
        repo_dir = self.home_dir / "Workspaces" / "gdr" / "agentic"
        self.git(["clone", str(self.remote_dir), str(repo_dir)])
        self.git(["remote", "remove", "origin"], cwd=repo_dir)
        cfg_ok = self.write_config(self.default_config_dict())
        rc_ok, _, err_ok = self.run_cli_inproc(["bootstrap", str(cfg_ok)])
        self.assertEqual(rc_ok, 0, err_ok)
        self.assertEqual(
            self.git(["remote", "get-url", "origin"], cwd=repo_dir).stdout.strip(),
            str(self.remote_dir),
        )
        self.assertEqual(
            self.git(["config", "--get", "remote.origin.pushurl"], cwd=repo_dir).stdout.strip(),
            "ssh://example.invalid/gdr/agentic.git",
        )

    def test_t31_bug_d2_skips_symlinked_ancestors_under_home_but_allows_above_home(self) -> None:
        self.init_remote_with_skills(
            skills={"alpha": {"SKILL.md": "# Alpha\n"}},
            extra_files={"rules/r.md": "# Rule\n"},
        )
        # Put home_dir under a symlinked ancestor *above* home_dir (simulating /var -> /private/var)
        real_parent = self.root / "real-var"
        real_parent.mkdir()
        sym_parent = self.root / "sym-var"
        sym_parent.symlink_to(real_parent)
        sym_home = sym_parent / "home"
        sym_home.mkdir()

        ext_dir = self.root / "external-tool"
        ext_dir.mkdir()
        # Pre-existing symlinked ancestor under homeDir for fanout (.agents -> external)
        (sym_home / ".agents").symlink_to(ext_dir)
        # Pre-existing symlinked dst_parent for links (.direct-dir -> external)
        (sym_home / ".direct-dir").symlink_to(ext_dir)
        # Pre-existing symlinked intermediate ancestor for links (.config -> external)
        (sym_home / ".config").symlink_to(ext_dir)

        cfg_path = self.write_config(
            self.default_config_dict(
                homeDir=str(sym_home),
                fanout=[
                    {
                        "from": "skills",
                        "into": [".agents/skills", ".claude/skills"],
                        "requireFile": "SKILL.md",
                    }
                ],
                links=[
                    {"from": "rules/r.md", "to": ".direct-dir/r.md"},
                    {"from": "rules/r.md", "to": ".config/sub/r.md"},
                    {"from": "rules/r.md", "to": ".real-dir/r.md"},
                ],
            )
        )
        rc, _, err = self.run_cli_inproc(["bootstrap", str(cfg_path)])
        self.assertEqual(rc, 0, err)
        self.assertIn("traverses symlink", err)
        # Must NOT write into external-tool via any symlinked parent/ancestor
        self.assertEqual(list(ext_dir.iterdir()), [])
        # Real targets strictly under symlinked above-home ancestor MUST succeed
        self.assertTrue((sym_home / ".claude" / "skills" / "alpha").is_symlink())
        self.assertTrue((sym_home / ".real-dir" / "r.md").is_symlink())

        # Also verify pruning does not traverse a later-symlinked links parent
        real_links_dir = sym_home / ".real-dir"
        (ext_dir / "r.md").symlink_to((sym_home / "Workspaces" / "gdr" / "agentic" / "rules" / "r.md").resolve())
        (real_links_dir / "r.md").unlink()
        real_links_dir.rmdir()
        real_links_dir.symlink_to(ext_dir)

        cfg_no_links = self.write_config(
            self.default_config_dict(
                homeDir=str(sym_home),
                fanout=[{"from": "skills", "into": [".claude/skills"], "requireFile": "SKILL.md"}],
                links=[],
            ),
            "no_links.json",
        )
        rc2, _, err2 = self.run_cli_inproc(["link", str(cfg_no_links)])
        self.assertEqual(rc2, 0, err2)
        self.assertIn("skipping prune under non-real/symlinked parent", err2)
        self.assertTrue((ext_dir / "r.md").is_symlink())

    def test_t32_bug_d3_skips_hidden_fanout_entries_and_prunes_stale_hidden_manifest(self) -> None:
        self.init_remote_with_skills(
            skills={
                "alpha": {"SKILL.md": "# Alpha\n"},
                ".hidden-skill": {"SKILL.md": "# Hidden\n"},
            },
            extra_files={
                "rules/.DS_Store": "junk",
                "rules/style.md": "# Style\n",
            },
        )
        repo_dir = self.home_dir / "Workspaces" / "gdr" / "agentic"
        cfg_path = self.write_config(
            self.default_config_dict(
                fanout=[
                    {"from": "skills", "into": [".agents/skills"], "requireFile": "SKILL.md"},
                    {"from": "rules", "into": [".agents/rules"], "requireFile": None},
                ]
            )
        )
        # Seed a stale manifest entry and symlink for .hidden-skill as if left by older version
        self.assertEqual(self.run_cli_inproc(["bootstrap", str(cfg_path)])[0], 0)
        stale_hidden = self.home_dir / ".agents" / "skills" / ".hidden-skill"
        stale_hidden.symlink_to(repo_dir / "skills" / ".hidden-skill")
        m_path = self.state_dir / "agentic.json"
        m_data = json.loads(m_path.read_text(encoding="utf-8"))
        m_data["links"].append(
            {
                "to": str(stale_hidden),
                "from": str((repo_dir / "skills" / ".hidden-skill").resolve()),
            }
        )
        m_path.write_text(json.dumps(m_data), encoding="utf-8")

        rc, _, err = self.run_cli_inproc(["link", str(cfg_path)])
        self.assertEqual(rc, 0, err)
        self.assertTrue((self.home_dir / ".agents" / "skills" / "alpha").is_symlink())
        self.assertTrue((self.home_dir / ".agents" / "rules" / "style.md").is_symlink())
        self.assertFalse(stale_hidden.exists() or stale_hidden.is_symlink())
        self.assertFalse((self.home_dir / ".agents" / "rules" / ".DS_Store").exists())

    def test_t33_gap_a1_pull_unborn_branch_resolves_head_and_links(self) -> None:
        self.init_remote_with_skills(skills={"alpha": {"SKILL.md": "# Alpha\n"}})
        repo_dir = self.home_dir / "Workspaces" / "gdr" / "agentic"
        repo_dir.parent.mkdir(parents=True, exist_ok=True)
        self.git(["init", "-b", "main", str(repo_dir)])
        self.git(["remote", "add", "origin", str(self.remote_dir)], cwd=repo_dir)

        cfg_path = self.write_config(self.default_config_dict())
        rc, _, err = self.run_cli_inproc(["pull", str(cfg_path)])
        self.assertEqual(rc, 0, err)
        head_proc = subprocess.run(
            ["git", "-C", str(repo_dir), "rev-parse", "--verify", "HEAD"],
            env=self.git_env(),
            capture_output=True,
            text=True,
            check=False,
        )
        self.assertEqual(head_proc.returncode, 0)
        self.assertTrue((self.home_dir / ".agents" / "skills" / "alpha").is_symlink())

    def test_t34_gap_a2_pull_remote_missing_configured_branch_warns_and_links(self) -> None:
        self.init_remote_with_skills(branch="master")
        repo_dir = self.home_dir / "Workspaces" / "gdr" / "agentic"
        repo_dir.parent.mkdir(parents=True, exist_ok=True)
        self.git(["clone", "--branch", "master", str(self.remote_dir), str(repo_dir)])

        cfg_path = self.write_config(self.default_config_dict(branch="main"))
        rc, _, err = self.run_cli_inproc(["pull", str(cfg_path)])
        self.assertEqual(rc, 0)
        self.assertIn("warning:", err)
        self.assertTrue((self.home_dir / ".agents" / "skills" / "alpha").is_symlink())

    def test_t35_gap_a3_pull_nonempty_nongit_broken_symlink_and_empty_repodir(self) -> None:
        self.init_remote_with_skills()

        # 1. Non-empty non-git dir preserved
        nongit = self.home_dir / "nongit-repo"
        nongit.mkdir(parents=True)
        (nongit / "keep.txt").write_text("keep\n", encoding="utf-8")
        cfg_ng = self.write_config(self.default_config_dict(repoDir=str(nongit)), "ng.json")
        rc1, _, err1 = self.run_cli_inproc(["pull", str(cfg_ng)])
        self.assertEqual(rc1, 0)
        self.assertIn("not a git repository; skipping pull", err1)
        self.assertEqual((nongit / "keep.txt").read_text(encoding="utf-8"), "keep\n")

        # 2. Broken symlink preserved
        broken = self.home_dir / "broken-sym-repo"
        broken.symlink_to(self.root / "missing-target")
        cfg_br = self.write_config(self.default_config_dict(repoDir=str(broken)), "br.json")
        rc2, _, err2 = self.run_cli_inproc(["pull", str(cfg_br)])
        self.assertEqual(rc2, 0)
        self.assertIn("not a git repository; skipping pull", err2)
        self.assertTrue(broken.is_symlink())

        # 3. Empty dir delegates to bootstrap, clones, and links
        empty_dir = self.home_dir / "empty-repo"
        empty_dir.mkdir()
        cfg_em = self.write_config(self.default_config_dict(repoDir=str(empty_dir)), "em.json")
        rc3, _, err3 = self.run_cli_inproc(["pull", str(cfg_em)])
        self.assertEqual(rc3, 0, err3)
        self.assertTrue(drs.is_git_repo(empty_dir))
        self.assertTrue((self.home_dir / ".agents" / "skills" / "alpha").is_symlink())

    def test_t36_gap_a4_pull_symlinked_repodir_fast_forwards_and_links(self) -> None:
        self.init_remote_with_skills()
        real_repo = self.root / "real-agentic-checkout"
        self.git(["clone", "--branch", "main", str(self.remote_dir), str(real_repo)])
        sym_repo = self.home_dir / "Workspaces" / "gdr" / "agentic"
        sym_repo.parent.mkdir(parents=True, exist_ok=True)
        sym_repo.symlink_to(real_repo)

        new_sha = self.commit_upstream_file("skills/gamma/SKILL.md", "# Gamma\n", "add gamma")
        cfg_path = self.write_config(self.default_config_dict())
        rc, _, err = self.run_cli_inproc(["pull", str(cfg_path)])
        self.assertEqual(rc, 0, err)
        self.assertEqual(self.git(["rev-parse", "HEAD"], cwd=real_repo).stdout.strip(), new_sha)
        link = self.home_dir / ".agents" / "skills" / "gamma"
        self.assertTrue(link.is_symlink())
        self.assertEqual(link.resolve(strict=True), (real_repo / "skills" / "gamma").resolve(strict=True))

    def test_t37_gap_a5_pull_force_pushed_remote_and_pushurl_drift_repair(self) -> None:
        self.init_remote_with_skills()
        cfg_path = self.write_config(self.default_config_dict())
        self.assertEqual(self.run_cli_inproc(["bootstrap", str(cfg_path)])[0], 0)

        repo_dir = self.home_dir / "Workspaces" / "gdr" / "agentic"
        local_sha = self.git(["rev-parse", "HEAD"], cwd=repo_dir).stdout.strip()

        # Drift pushurl locally
        self.git(["config", "--unset-all", "remote.origin.pushurl"], cwd=repo_dir)

        # Force-push rewritten history to upstream remote
        self.git(["commit", "--amend", "-m", "rewritten root"], cwd=self.work_dir)
        self.git(["push", "--force", "origin", "main"], cwd=self.work_dir)

        rc, _, err = self.run_cli_inproc(["pull", str(cfg_path)])
        self.assertEqual(rc, 0, err)
        # Local history preserved on force-push divergence
        self.assertEqual(self.git(["rev-parse", "HEAD"], cwd=repo_dir).stdout.strip(), local_sha)
        # pushUrl drift repaired during pull
        self.assertEqual(
            self.git(["config", "--get", "remote.origin.pushurl"], cwd=repo_dir).stdout.strip(),
            "ssh://example.invalid/gdr/agentic.git",
        )

    def test_t38_gap_a6_link_destination_collision_keeps_first_target(self) -> None:
        self.init_remote_with_skills(
            skills={"a": {"SKILL.md": "# A\n"}},
            extra_files={"other/doc.md": "# Other\n"},
        )
        repo_dir = self.home_dir / "Workspaces" / "gdr" / "agentic"
        cfg_path = self.write_config(
            self.default_config_dict(
                fanout=[{"from": "skills", "into": [".agents/skills"], "requireFile": "SKILL.md"}],
                links=[{"from": "other/doc.md", "to": ".agents/skills/a"}],
            )
        )
        rc, _, err = self.run_cli_inproc(["bootstrap", str(cfg_path)])
        self.assertEqual(rc, 0)
        self.assertIn("destination collision", err)
        dst = self.home_dir / ".agents" / "skills" / "a"
        self.assertEqual(dst.resolve(strict=True), (repo_dir / "skills" / "a").resolve(strict=True))

    def test_t39_gap_a7_link_rejects_escaping_requirefile_and_links_from_symlinks(self) -> None:
        self.init_remote_with_skills()
        outside = self.root / "outside.md"
        outside.write_text("# Secret\n", encoding="utf-8")

        repo_dir = self.home_dir / "Workspaces" / "gdr" / "agentic"
        self.git(["clone", str(self.remote_dir), str(repo_dir)])
        esc_dir = repo_dir / "skills" / "esc-req"
        esc_dir.mkdir(parents=True)
        (esc_dir / "SKILL.md").symlink_to(outside)
        (repo_dir / "esc-link.md").symlink_to(outside)

        cfg_path = self.write_config(
            self.default_config_dict(links=[{"from": "esc-link.md", "to": ".agents/esc.md"}])
        )
        rc, _, err = self.run_cli_inproc(["link", str(cfg_path)])
        self.assertEqual(rc, 0)
        self.assertIn("requireFile resolves outside repoDir", err)
        self.assertIn("resolves outside repoDir", err)
        self.assertFalse((self.home_dir / ".agents" / "skills" / "esc-req").exists())
        self.assertFalse((self.home_dir / ".agents" / "esc.md").exists())

    def test_t40_gap_a8_link_adopts_manual_relative_symlink_and_prunes_later(self) -> None:
        self.init_remote_with_skills()
        cfg_path = self.write_config(self.default_config_dict())
        self.assertEqual(self.run_cli_inproc(["bootstrap", str(cfg_path)])[0], 0)

        repo_dir = self.home_dir / "Workspaces" / "gdr" / "agentic"
        agents_skills = self.home_dir / ".agents" / "skills"
        manual_link = agents_skills / "alpha"
        manual_link.unlink()
        # Recreate as a relative symlink pointing inside repoDir
        manual_link.symlink_to(os.path.relpath(repo_dir / "skills" / "alpha", agents_skills))

        rc1, _, err1 = self.run_cli_inproc(["link", str(cfg_path)])
        self.assertEqual(rc1, 0, err1)
        manifest = json.loads((self.state_dir / "agentic.json").read_text(encoding="utf-8"))
        self.assertIn(str(manual_link), {x["to"] for x in manifest["links"]})

        # Remove alpha locally and re-run link -> adopted relative symlink must be pruned
        for p in (repo_dir / "skills" / "alpha").iterdir():
            p.unlink()
        (repo_dir / "skills" / "alpha").rmdir()
        rc2, _, err2 = self.run_cli_inproc(["link", str(cfg_path)])
        self.assertEqual(rc2, 0, err2)
        self.assertFalse(manual_link.exists() or manual_link.is_symlink())

    def test_t41_gap_a9_links_file_or_broken_symlink_parent_and_broken_from(self) -> None:
        self.init_remote_with_skills(extra_files={"rules/r.md": "# Rule\n"})
        repo_dir = self.home_dir / "Workspaces" / "gdr" / "agentic"
        self.git(["clone", str(self.remote_dir), str(repo_dir)])
        (repo_dir / "rules" / "broken.md").symlink_to(self.root / "missing-src")

        file_parent = self.home_dir / "file-parent"
        file_parent.write_text("not a dir\n", encoding="utf-8")
        broken_parent = self.home_dir / "broken-parent"
        broken_parent.symlink_to(self.root / "missing-dir")

        cfg_path = self.write_config(
            self.default_config_dict(
                fanout=[],
                links=[
                    {"from": "rules/r.md", "to": "file-parent/r.md"},
                    {"from": "rules/r.md", "to": "broken-parent/r.md"},
                    {"from": "rules/broken.md", "to": ".agents/broken.md"},
                    {"from": "rules/missing.md", "to": ".agents/missing.md"},
                ],
            )
        )
        rc, _, err = self.run_cli_inproc(["link", str(cfg_path)])
        self.assertEqual(rc, 0)
        self.assertIn("is not a directory; skipping", err)
        self.assertIn("symlink to non-directory; skipping", err)
        self.assertEqual(file_parent.read_text(encoding="utf-8"), "not a dir\n")
        self.assertTrue(broken_parent.is_symlink())
        self.assertFalse((self.home_dir / ".agents" / "broken.md").is_symlink())
        self.assertFalse((self.home_dir / ".agents" / "missing.md").is_symlink())

    def test_t42_gap_a10_load_manifest_recovers_from_corrupt_types(self) -> None:
        self.init_remote_with_skills()
        cfg_path = self.write_config(self.default_config_dict())
        self.assertEqual(self.run_cli_inproc(["bootstrap", str(cfg_path)])[0], 0)

        m_path = self.state_dir / "agentic.json"
        for bad_payload in (
            [],
            {"links": "bad"},
            {"links": [123]},
            {"links": [{"to": 1, "from": 2}]},
        ):
            m_path.write_text(json.dumps(bad_payload), encoding="utf-8")
            rc, _, err = self.run_cli_inproc(["link", str(cfg_path)])
            self.assertEqual(rc, 0, f"failed recovery for {bad_payload!r}: {err}")
            self.assertIn("ignoring manifest", err)
            repaired = json.loads(m_path.read_text(encoding="utf-8"))
            self.assertEqual(repaired["version"], 1)
            self.assertEqual(len(repaired["links"]), 4)

    def test_t43_gap_a11_status_all_upstream_states_and_missing_links(self) -> None:
        self.init_remote_with_skills()
        repo_dir = self.home_dir / "Workspaces" / "gdr" / "agentic"
        cfg_path = self.write_config(self.default_config_dict())

        # 1. not-git
        repo_dir.mkdir(parents=True)
        (repo_dir / "x.txt").write_text("x", encoding="utf-8")
        rc, out, _ = self.run_cli_inproc(["status", "--json", str(cfg_path)])
        self.assertEqual(rc, 0)
        self.assertEqual(json.loads(out)["upstreamState"], "not-git")

        # 2. unborn
        (repo_dir / "x.txt").unlink()
        self.git(["init", "-b", "main", str(repo_dir)])
        rc, out, _ = self.run_cli_inproc(["status", "--json", str(cfg_path)])
        self.assertEqual(rc, 0)
        self.assertEqual(json.loads(out)["upstreamState"], "unborn")

        # 3. no-upstream (local commit, no origin fetch yet)
        (repo_dir / "skills" / "alpha").mkdir(parents=True)
        (repo_dir / "skills" / "alpha" / "SKILL.md").write_text("# Local\n", encoding="utf-8")
        self.git(["add", "-A"], cwd=repo_dir)
        self.git(["commit", "-m", "local init"], cwd=repo_dir)
        rc, out, _ = self.run_cli_inproc(["status", "--json", str(cfg_path)])
        self.assertEqual(rc, 0)
        self.assertEqual(json.loads(out)["upstreamState"], "no-upstream")

        # Clean up and bootstrap properly for ahead / diverged / detached / missingLinks
        for root_p, dirs, files in os.walk(repo_dir, topdown=False):
            for fn in files:
                (Path(root_p) / fn).unlink()
            for dn in dirs:
                (Path(root_p) / dn).rmdir()
        repo_dir.rmdir()
        self.assertEqual(self.run_cli_inproc(["bootstrap", str(cfg_path)])[0], 0)

        # 4. ahead
        (repo_dir / "local.txt").write_text("ahead\n", encoding="utf-8")
        self.git(["add", "local.txt"], cwd=repo_dir)
        self.git(["commit", "-m", "ahead"], cwd=repo_dir)
        rc, out, _ = self.run_cli_inproc(["status", "--json", str(cfg_path)])
        d_ahead = json.loads(out)
        self.assertEqual(d_ahead["upstreamState"], "ahead")
        self.assertEqual(d_ahead["ahead"], 1)

        # 5. diverged
        self.commit_upstream_file("remote.txt", "remote\n", "remote advance")
        self.git(["fetch", "--quiet", "origin", "main"], cwd=repo_dir)
        rc, out, _ = self.run_cli_inproc(["status", "--json", str(cfg_path)])
        d_div = json.loads(out)
        self.assertEqual(d_div["upstreamState"], "diverged")
        self.assertEqual(d_div["ahead"], 1)
        self.assertEqual(d_div["behind"], 1)

        # 6. detached + missingLinks (replace managed symlink with regular file)
        self.git(["checkout", "--detach", "HEAD"], cwd=repo_dir)
        alpha_link = self.home_dir / ".agents" / "skills" / "alpha"
        alpha_link.unlink()
        alpha_link.write_text("replaced\n", encoding="utf-8")
        rc, out, _ = self.run_cli_inproc(["status", "--json", str(cfg_path)])
        d_det = json.loads(out)
        self.assertTrue(d_det["detached"])
        self.assertIn(str(alpha_link), d_det["missingLinks"])


if __name__ == "__main__":
    unittest.main()
