#!/usr/bin/env python3
"""Sync and fan-out helper for detached Git repositories."""

from __future__ import annotations

import argparse
from dataclasses import dataclass
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
from typing import Any


class ConfigError(ValueError):
    """Raised when a detached-repo-sync configuration file is invalid."""


@dataclass(frozen=True)
class FanoutRule:
    from_path: Path
    into_dirs: tuple[Path, ...]
    require_file: Path | None


@dataclass(frozen=True)
class LinkRule:
    from_path: Path
    to_path: Path


@dataclass(frozen=True)
class RepoConfig:
    name: str
    home_dir: Path
    repo_dir: Path
    pull_url: str
    push_url: str | None
    branch: str
    state_dir: Path
    fanout: tuple[FanoutRule, ...]
    links: tuple[LinkRule, ...]


def warn(repo_name: str, message: str) -> None:
    print(f"[detached-repo-sync:{repo_name}] warning: {message}", file=sys.stderr)


def error(message: str) -> None:
    print(f"detached-repo-sync: error: {message}", file=sys.stderr)


def resolve_against_home(raw: str, home_dir: Path) -> Path:
    """Resolve raw path against home_dir without dereferencing components under home_dir or the leaf."""
    if raw == "~":
        return home_dir
    if raw.startswith("~/"):
        joined = home_dir / raw[2:]
    else:
        p = Path(os.path.expanduser(raw))
        joined = p if p.is_absolute() else (home_dir / p)
    normalized = Path(os.path.normpath(str(joined)))
    # Re-anchor if an ancestor resolves to home_dir (e.g. /tmp -> /private/tmp),
    # while leaving all components strictly below home_dir unresolved.
    if normalized != home_dir and not normalized.is_relative_to(home_dir):
        parts = normalized.parts
        for idx in range(1, len(parts) + 1):
            prefix = Path(*parts[:idx])
            try:
                if prefix.resolve(strict=False) == home_dir:
                    rel_parts = parts[idx:]
                    return home_dir.joinpath(*rel_parts) if rel_parts else home_dir
            except OSError:
                break
    return normalized


def has_symlink_component(target_dir: Path, home_dir: Path) -> Path | None:
    """Return the first symlink component from home_dir (exclusive) to target_dir (inclusive)."""
    if target_dir.is_relative_to(home_dir):
        cur = home_dir
        for part in target_dir.relative_to(home_dir).parts:
            cur = cur / part
            if cur.is_symlink():
                return cur
    if target_dir.is_symlink():
        return target_dir
    return None


def validate_repo_relative_path(raw: Any, field_name: str) -> Path:
    if not isinstance(raw, str) or not raw or "\x00" in raw:
        raise ConfigError(f"{field_name} must be a non-empty string")
    rel = Path(raw)
    if rel.is_absolute():
        raise ConfigError(f"{field_name} must be relative to repoDir: {raw!r}")
    if ".." in rel.parts:
        raise ConfigError(f"{field_name} must not traverse outside repoDir: {raw!r}")
    return rel


def validate_repo_name(raw: Any) -> str:
    if not isinstance(raw, str) or not raw:
        raise ConfigError("name must be a non-empty string")
    if raw in (".", "..") or "/" in raw or "\\" in raw or "\x00" in raw:
        raise ConfigError(f"unsafe repository name: {raw!r}")
    return raw


def load_config(config_path: Path) -> RepoConfig:
    try:
        raw_text = config_path.read_text(encoding="utf-8")
    except OSError as exc:
        raise ConfigError(f"cannot read config {config_path}: {exc}") from exc

    try:
        data = json.loads(raw_text)
    except json.JSONDecodeError as exc:
        raise ConfigError(f"invalid JSON in {config_path}: {exc}") from exc

    if not isinstance(data, dict):
        raise ConfigError("config root must be a JSON object")

    name = validate_repo_name(data.get("name"))

    raw_home = data.get("homeDir")
    if raw_home is None:
        home_dir = Path(os.path.expanduser("~")).resolve(strict=False)
    elif isinstance(raw_home, str) and raw_home and "\x00" not in raw_home:
        home_dir = Path(os.path.expanduser(raw_home)).resolve(strict=False)
    else:
        raise ConfigError("homeDir must be a non-empty string if provided")

    raw_repo = data.get("repoDir")
    if not isinstance(raw_repo, str) or not raw_repo or "\x00" in raw_repo:
        raise ConfigError("repoDir must be a non-empty string")
    repo_dir = resolve_against_home(raw_repo, home_dir)

    raw_pull_url = data.get("pullUrl")
    if (
        not isinstance(raw_pull_url, str)
        or not raw_pull_url.strip()
        or raw_pull_url.lstrip().startswith("-")
        or "\x00" in raw_pull_url
    ):
        raise ConfigError("pullUrl must be a non-empty string not starting with '-'")
    pull_url = raw_pull_url

    raw_push_url = data.get("pushUrl")
    if raw_push_url is None or raw_push_url == "":
        push_url = None
    elif (
        isinstance(raw_push_url, str)
        and raw_push_url.strip()
        and not raw_push_url.lstrip().startswith("-")
        and "\x00" not in raw_push_url
    ):
        push_url = raw_push_url
    else:
        raise ConfigError("pushUrl must be a non-empty string not starting with '-' or null")

    raw_branch = data.get("branch")
    if raw_branch is None:
        branch = "main"
    elif (
        isinstance(raw_branch, str)
        and raw_branch
        and not raw_branch.startswith("-")
        and "\x00" not in raw_branch
        and not any(ch.isspace() for ch in raw_branch)
    ):
        branch = raw_branch
    else:
        raise ConfigError("branch must be a valid non-empty branch name")

    raw_state_dir = data.get("stateDir")
    if raw_state_dir is None:
        state_dir = resolve_against_home("~/.local/state/detached-repos", home_dir)
    elif isinstance(raw_state_dir, str) and raw_state_dir and "\x00" not in raw_state_dir:
        state_dir = resolve_against_home(raw_state_dir, home_dir)
    else:
        raise ConfigError("stateDir must be a non-empty string if provided")

    raw_fanout = data.get("fanout")
    if raw_fanout is None:
        raw_fanout = []
    if not isinstance(raw_fanout, list):
        raise ConfigError("fanout must be a list")

    fanout_rules: list[FanoutRule] = []
    for idx, item in enumerate(raw_fanout):
        if not isinstance(item, dict):
            raise ConfigError(f"fanout[{idx}] must be an object")
        from_rel = validate_repo_relative_path(item.get("from"), f"fanout[{idx}].from")
        raw_into = item.get("into")
        if not isinstance(raw_into, list) or not raw_into:
            raise ConfigError(f"fanout[{idx}].into must be a non-empty list")
        into_paths: list[Path] = []
        for j, raw_target in enumerate(raw_into):
            if not isinstance(raw_target, str) or not raw_target or "\x00" in raw_target:
                raise ConfigError(f"fanout[{idx}].into[{j}] must be a non-empty string")
            into_paths.append(resolve_against_home(raw_target, home_dir))

        raw_req = item.get("requireFile")
        if raw_req is None or raw_req == "":
            req_rel = None
        else:
            req_rel = validate_repo_relative_path(raw_req, f"fanout[{idx}].requireFile")

        fanout_rules.append(
            FanoutRule(
                from_path=from_rel,
                into_dirs=tuple(into_paths),
                require_file=req_rel,
            )
        )

    raw_links = data.get("links")
    if raw_links is None:
        raw_links = []
    if not isinstance(raw_links, list):
        raise ConfigError("links must be a list")

    link_rules: list[LinkRule] = []
    for idx, item in enumerate(raw_links):
        if not isinstance(item, dict):
            raise ConfigError(f"links[{idx}] must be an object")
        from_rel = validate_repo_relative_path(item.get("from"), f"links[{idx}].from")
        raw_to = item.get("to")
        if not isinstance(raw_to, str) or not raw_to or "\x00" in raw_to:
            raise ConfigError(f"links[{idx}].to must be a non-empty string")
        link_rules.append(
            LinkRule(
                from_path=from_rel,
                to_path=resolve_against_home(raw_to, home_dir),
            )
        )

    return RepoConfig(
        name=name,
        home_dir=home_dir,
        repo_dir=repo_dir,
        pull_url=pull_url,
        push_url=push_url,
        branch=branch,
        state_dir=state_dir,
        fanout=tuple(fanout_rules),
        links=tuple(link_rules),
    )


def run_git(args: list[str], cwd: Path | None = None) -> subprocess.CompletedProcess[str]:
    env = os.environ.copy()
    env["GIT_TERMINAL_PROMPT"] = "0"
    cmd = ["git"]
    if cwd is not None:
        cmd.extend(["-C", str(cwd)])
    cmd.extend(args)
    return subprocess.run(cmd, env=env, capture_output=True, text=True, check=False)


def is_git_repo(repo_dir: Path) -> bool:
    if repo_dir.is_symlink() and not repo_dir.exists():
        return False
    if not repo_dir.is_dir():
        return False
    if not (repo_dir / ".git").exists():
        return False
    res = run_git(["rev-parse", "--show-toplevel"], cwd=repo_dir)
    if res.returncode != 0:
        return False
    try:
        repo_real = repo_dir.resolve(strict=True)
    except OSError:
        return False
    toplevel = Path(res.stdout.strip()).resolve(strict=False)
    return toplevel == repo_real


def ensure_remotes(cfg: RepoConfig, update_pull_url: bool = True) -> None:
    remote_check = run_git(["remote", "get-url", "origin"], cwd=cfg.repo_dir)
    if remote_check.returncode != 0:
        add_res = run_git(["remote", "add", "--", "origin", cfg.pull_url], cwd=cfg.repo_dir)
        if add_res.returncode != 0:
            warn(cfg.name, f"failed to add origin remote: {add_res.stderr.strip()}")
            return
    elif update_pull_url and remote_check.stdout.strip() != cfg.pull_url:
        set_url_res = run_git(
            ["remote", "set-url", "--", "origin", cfg.pull_url],
            cwd=cfg.repo_dir,
        )
        if set_url_res.returncode != 0:
            warn(cfg.name, f"failed to set origin URL: {set_url_res.stderr.strip()}")
            return

    get_res = run_git(["config", "--get-all", "remote.origin.pushurl"], cwd=cfg.repo_dir)
    current_pushurls = (
        [ln.strip() for ln in get_res.stdout.splitlines() if ln.strip()]
        if get_res.returncode == 0
        else []
    )
    if cfg.push_url is not None:
        if current_pushurls != [cfg.push_url]:
            set_res = run_git(
                ["config", "--replace-all", "--", "remote.origin.pushurl", cfg.push_url],
                cwd=cfg.repo_dir,
            )
            if set_res.returncode != 0:
                warn(cfg.name, f"failed to set remote.origin.pushurl: {set_res.stderr.strip()}")
    else:
        if get_res.returncode == 0:
            unset_res = run_git(
                ["config", "--unset-all", "remote.origin.pushurl"],
                cwd=cfg.repo_dir,
            )
            if unset_res.returncode != 0:
                warn(
                    cfg.name,
                    f"failed to unset remote.origin.pushurl: {unset_res.stderr.strip()}",
                )


def direct_symlink_target(link_path: Path) -> Path:
    """Resolve the direct link target without following a final leaf symlink inside the target."""
    raw_target = os.readlink(link_path)
    parent_real = link_path.parent.resolve(strict=False)
    joined = os.path.normpath(os.path.join(str(parent_real), raw_target))
    dirname, basename = os.path.split(joined)
    if not basename:
        return Path(os.path.realpath(dirname))
    return Path(os.path.realpath(dirname)) / basename


def manifest_path_for(cfg: RepoConfig) -> Path:
    return cfg.state_dir / f"{cfg.name}.json"


def normalize_manifest_dst(raw_to: str) -> Path:
    # Keep the recorded destination path unresolved so pruning can detect if a
    # parent directory component was later replaced by a symlink.
    return Path(os.path.normpath(raw_to))


def load_manifest(manifest_path: Path, repo_name: str) -> dict[Path, Path]:
    if not manifest_path.exists() and not manifest_path.is_symlink():
        return {}
    try:
        data = json.loads(manifest_path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        warn(repo_name, f"ignoring unreadable/malformed manifest {manifest_path}: {exc}")
        return {}
    if not isinstance(data, dict):
        warn(repo_name, f"ignoring manifest with invalid root in {manifest_path}")
        return {}
    raw_links = data.get("links")
    if not isinstance(raw_links, list):
        warn(repo_name, f"ignoring manifest with invalid links list in {manifest_path}")
        return {}
    managed: dict[Path, Path] = {}
    for entry in raw_links:
        if not isinstance(entry, dict):
            warn(repo_name, f"ignoring manifest with invalid entry in {manifest_path}")
            return {}
        raw_to = entry.get("to")
        raw_from = entry.get("from")
        if not isinstance(raw_to, str) or not isinstance(raw_from, str):
            warn(repo_name, f"ignoring manifest with invalid link fields in {manifest_path}")
            return {}
        managed[normalize_manifest_dst(raw_to)] = Path(os.path.normpath(raw_from))
    return managed


def write_manifest_atomic(
    manifest_path: Path,
    cfg: RepoConfig,
    repo_real: Path,
    managed: dict[Path, Path],
) -> None:
    manifest_path.parent.mkdir(parents=True, exist_ok=True)
    payload = {
        "version": 1,
        "name": cfg.name,
        "repoDir": str(repo_real),
        "links": [
            {"to": str(dst), "from": str(src)}
            for dst, src in sorted(managed.items(), key=lambda kv: str(kv[0]))
        ],
    }
    encoded = json.dumps(payload, indent=2) + "\n"
    fd, tmp_name = tempfile.mkstemp(
        dir=str(manifest_path.parent),
        prefix=f".{cfg.name}.",
        suffix=".tmp",
    )
    tmp_path = Path(tmp_name)
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as handle:
            handle.write(encoded)
            handle.flush()
            os.fsync(handle.fileno())
        os.replace(tmp_path, manifest_path)
    except Exception:
        try:
            tmp_path.unlink(missing_ok=True)
        except OSError:
            pass
        raise


def link_repo(cfg: RepoConfig) -> int:
    if cfg.repo_dir.is_symlink() and not cfg.repo_dir.exists():
        warn(cfg.name, f"repoDir {cfg.repo_dir} is a broken symlink")
        return 1
    if not cfg.repo_dir.is_dir():
        warn(cfg.name, f"repoDir {cfg.repo_dir} does not exist or is not a directory")
        return 1

    try:
        repo_real = cfg.repo_dir.resolve(strict=True)
    except OSError as exc:
        warn(cfg.name, f"cannot resolve repoDir {cfg.repo_dir}: {exc}")
        return 1

    desired: dict[Path, Path] = {}

    for rule in cfg.fanout:
        src_root = (repo_real / rule.from_path).resolve(strict=False)
        if not src_root.is_relative_to(repo_real):
            warn(cfg.name, f"fanout source {rule.from_path} resolves outside repoDir; skipping")
            continue
        entries: list[tuple[str, Path]] = []
        if src_root.is_dir():
            for entry in sorted(src_root.iterdir(), key=lambda p: p.name):
                if entry.name.startswith("."):
                    continue

                try:
                    entry_real = entry.resolve(strict=True)
                except OSError:
                    warn(cfg.name, f"skipping broken entry {entry}")
                    continue
                if not entry_real.is_relative_to(repo_real):
                    warn(
                        cfg.name,
                        f"skipping {entry}: target {entry_real} escapes repoDir",
                    )
                    continue

                if rule.require_file is not None:
                    if not entry.is_dir():
                        continue
                    req_path = entry / rule.require_file
                    if not req_path.is_file():
                        continue
                    try:
                        req_real = req_path.resolve(strict=True)
                    except OSError:
                        continue
                    if not req_real.is_relative_to(repo_real):
                        warn(
                            cfg.name,
                            f"skipping {entry}: requireFile resolves outside repoDir",
                        )
                        continue

                entries.append((entry.name, entry_real))

        for into_dir in rule.into_dirs:
            sym_comp = has_symlink_component(into_dir, cfg.home_dir)
            if sym_comp is not None:
                if into_dir.is_symlink():
                    warn(cfg.name, f"target directory {into_dir} is a symlink; skipping")
                else:
                    warn(
                        cfg.name,
                        f"target directory {into_dir} traverses symlink {sym_comp}; skipping",
                    )
                continue
            if into_dir.exists() and not into_dir.is_dir():
                warn(cfg.name, f"target directory {into_dir} is not a real directory; skipping")
                continue
            try:
                into_dir.mkdir(parents=True, exist_ok=True)
                into_real = into_dir.resolve(strict=True)
            except OSError as exc:
                warn(cfg.name, f"cannot prepare target directory {into_dir}: {exc}")
                continue

            for entry_name, entry_real in entries:
                dst = into_real / entry_name
                if dst in desired:
                    if desired[dst] != entry_real:
                        warn(cfg.name, f"destination collision for {dst}; keeping first target")
                else:
                    desired[dst] = entry_real

    for link_rule in cfg.links:
        src_candidate = repo_real / link_rule.from_path
        if not src_candidate.exists():
            continue
        try:
            src_real = src_candidate.resolve(strict=True)
        except OSError:
            continue
        if not src_real.is_relative_to(repo_real):
            warn(
                cfg.name,
                f"skipping link {link_rule.from_path}: resolves outside repoDir",
            )
            continue

        dst_parent = link_rule.to_path.parent
        sym_comp = has_symlink_component(dst_parent, cfg.home_dir)
        if sym_comp is not None:
            if dst_parent.is_symlink() and not dst_parent.is_dir():
                warn(cfg.name, f"parent {dst_parent} is a symlink to non-directory; skipping")
            else:
                warn(cfg.name, f"parent {dst_parent} traverses symlink {sym_comp}; skipping")
            continue
        if dst_parent.exists() and not dst_parent.is_dir():
            warn(cfg.name, f"parent {dst_parent} is not a directory; skipping")
            continue
        try:
            dst_parent.mkdir(parents=True, exist_ok=True)
            dst_parent_real = dst_parent.resolve(strict=True)
        except OSError as exc:
            warn(cfg.name, f"cannot prepare parent directory {dst_parent}: {exc}")
            continue

        dst = dst_parent_real / link_rule.to_path.name
        if dst in desired:
            if desired[dst] != src_real:
                warn(cfg.name, f"destination collision for {dst}; keeping first target")
        else:
            desired[dst] = src_real

    m_path = manifest_path_for(cfg)
    old_managed = load_manifest(m_path, cfg.name)
    new_managed: dict[Path, Path] = {}

    for dst, target in sorted(desired.items(), key=lambda kv: str(kv[0])):
        if dst.is_symlink():
            direct = direct_symlink_target(dst)
            if direct == target:
                new_managed[dst] = target
            elif dst in old_managed and direct.is_relative_to(repo_real):
                try:
                    dst.unlink()
                    dst.symlink_to(target)
                    new_managed[dst] = target
                except OSError as exc:
                    warn(cfg.name, f"failed to update managed symlink {dst}: {exc}")
            else:
                warn(
                    cfg.name,
                    f"preserving foreign symlink {dst} -> {os.readlink(dst)}",
                )
        elif dst.exists():
            warn(cfg.name, f"preserving existing non-symlink path {dst}")
        else:
            try:
                dst.symlink_to(target)
                new_managed[dst] = target
            except OSError as exc:
                warn(cfg.name, f"failed to create symlink {dst} -> {target}: {exc}")

    for old_dst in sorted(old_managed.keys(), key=str):
        if old_dst in desired:
            continue
        try:
            if (
                has_symlink_component(old_dst.parent, cfg.home_dir) is not None
                or old_dst.parent.is_symlink()
                or not old_dst.parent.is_dir()
                or old_dst.parent.resolve(strict=True) != old_dst.parent
            ):
                warn(cfg.name, f"skipping prune under non-real/symlinked parent {old_dst.parent}")
                continue
        except OSError:
            continue
        if not old_dst.is_symlink():
            # Already deleted or replaced by a real file/directory: never clobber.
            continue
        direct = direct_symlink_target(old_dst)
        if direct.is_relative_to(repo_real):
            try:
                old_dst.unlink()
            except OSError as exc:
                warn(cfg.name, f"failed to prune stale symlink {old_dst}: {exc}")
        else:
            warn(
                cfg.name,
                f"preserving repointed symlink {old_dst} -> {os.readlink(old_dst)}",
            )

    try:
        write_manifest_atomic(m_path, cfg, repo_real, new_managed)
    except OSError as exc:
        warn(cfg.name, f"failed to write manifest {m_path}: {exc}")
        return 1

    return 0


def bootstrap_repo(cfg: RepoConfig) -> int:
    if is_git_repo(cfg.repo_dir):
        ensure_remotes(cfg)
        return link_repo(cfg)

    if cfg.repo_dir.is_symlink():
        warn(cfg.name, f"repoDir {cfg.repo_dir} is a symlink (not a git repo); skipping")
        return 0
    if cfg.repo_dir.exists() and not cfg.repo_dir.is_dir():
        warn(cfg.name, f"repoDir {cfg.repo_dir} exists as a file; skipping clone and link")
        return 0
    if cfg.repo_dir.is_dir():
        try:
            has_entries = any(cfg.repo_dir.iterdir())
        except OSError as exc:
            warn(cfg.name, f"cannot inspect repoDir {cfg.repo_dir}: {exc}")
            return 0
        if has_entries:
            warn(
                cfg.name,
                f"repoDir {cfg.repo_dir} is a non-empty non-git directory; skipping clone and link",
            )
            return 0

    try:
        cfg.repo_dir.parent.mkdir(parents=True, exist_ok=True)
    except OSError as exc:
        warn(cfg.name, f"failed to create parent directory {cfg.repo_dir.parent}: {exc}")
        return 0

    clone_res = run_git(
        ["clone", "--branch", cfg.branch, "--", cfg.pull_url, str(cfg.repo_dir)]
    )
    if clone_res.returncode != 0:
        detail = clone_res.stderr.strip() or f"exit code {clone_res.returncode}"
        warn(cfg.name, f"clone failed for {cfg.pull_url}: {detail}")
        return 0

    ensure_remotes(cfg)
    return link_repo(cfg)


def has_in_progress_git_op(repo_dir: Path) -> bool:
    gd_res = run_git(["rev-parse", "--git-dir"], cwd=repo_dir)
    if gd_res.returncode != 0:
        return True
    git_dir = Path(gd_res.stdout.strip())
    if not git_dir.is_absolute():
        git_dir = repo_dir / git_dir
    markers = (
        "MERGE_HEAD",
        "rebase-merge",
        "rebase-apply",
        "CHERRY_PICK_HEAD",
        "REVERT_HEAD",
        "sequencer",
        "BISECT_LOG",
    )
    return any((git_dir / marker).exists() for marker in markers)


def pull_repo(cfg: RepoConfig) -> int:
    if not is_git_repo(cfg.repo_dir):
        is_missing = not cfg.repo_dir.exists() and not cfg.repo_dir.is_symlink()
        is_empty_dir = False
        if cfg.repo_dir.is_dir() and not cfg.repo_dir.is_symlink():
            try:
                is_empty_dir = not any(cfg.repo_dir.iterdir())
            except OSError as exc:
                warn(cfg.name, f"cannot inspect repoDir {cfg.repo_dir}: {exc}")
                return 0
        if is_missing or is_empty_dir:
            return bootstrap_repo(cfg)
        warn(cfg.name, f"repoDir {cfg.repo_dir} is not a git repository; skipping pull")
        return 0

    # Repair pushUrl drift without overriding an existing origin fetch URL.
    ensure_remotes(cfg, update_pull_url=False)

    fetch_refspec = f"+refs/heads/{cfg.branch}:refs/remotes/origin/{cfg.branch}"
    fetch_res = run_git(["fetch", "--quiet", "--", "origin", fetch_refspec], cwd=cfg.repo_dir)
    if fetch_res.returncode != 0:
        detail = fetch_res.stderr.strip() or f"exit code {fetch_res.returncode}"
        warn(cfg.name, f"fetch failed (offline or unreachable): {detail}")
        return link_repo(cfg)

    sym_res = run_git(["symbolic-ref", "--quiet", "--short", "HEAD"], cwd=cfg.repo_dir)
    if sym_res.returncode == 0 and sym_res.stdout.strip() == cfg.branch:
        if not has_in_progress_git_op(cfg.repo_dir):
            st_res = run_git(["status", "--porcelain"], cwd=cfg.repo_dir)
            if st_res.returncode == 0 and st_res.stdout.strip() == "":
                upstream_ref = f"refs/remotes/origin/{cfg.branch}"
                up_res = run_git(
                    ["rev-parse", "--verify", "--quiet", upstream_ref],
                    cwd=cfg.repo_dir,
                )
                if up_res.returncode == 0:
                    head_res = run_git(
                        ["rev-parse", "--verify", "--quiet", "HEAD"],
                        cwd=cfg.repo_dir,
                    )
                    if head_res.returncode != 0:
                        merge_res = run_git(
                            ["merge", "--ff-only", "--quiet", upstream_ref],
                            cwd=cfg.repo_dir,
                        )
                        if merge_res.returncode != 0:
                            warn(
                                cfg.name,
                                f"fast-forward merge failed: {merge_res.stderr.strip()}",
                            )
                    else:
                        rev_res = run_git(
                            [
                                "rev-list",
                                "--left-right",
                                "--count",
                                f"HEAD...{upstream_ref}",
                            ],
                            cwd=cfg.repo_dir,
                        )
                        if rev_res.returncode == 0:
                            parts = rev_res.stdout.strip().split()
                            if len(parts) == 2:
                                ahead, behind = int(parts[0]), int(parts[1])
                                if ahead == 0 and behind > 0:
                                    merge_res = run_git(
                                        ["merge", "--ff-only", "--quiet", upstream_ref],
                                        cwd=cfg.repo_dir,
                                    )
                                    if merge_res.returncode != 0:
                                        warn(
                                            cfg.name,
                                            f"fast-forward merge failed: {merge_res.stderr.strip()}",
                                        )

    return link_repo(cfg)


def inspect_manifest_readonly(manifest_path: Path) -> tuple[int, int, list[str], list[str]]:
    if not manifest_path.exists() and not manifest_path.is_symlink():
        return 0, 0, [], []
    try:
        data = json.loads(manifest_path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return 0, 0, [], []
    if not isinstance(data, dict) or not isinstance(data.get("links"), list):
        return 0, 0, [], []

    managed_count = 0
    healthy_count = 0
    broken_links: list[str] = []
    missing_links: list[str] = []

    for entry in data["links"]:
        if not isinstance(entry, dict) or not isinstance(entry.get("to"), str):
            continue
        managed_count += 1
        dst = Path(entry["to"])
        if dst.is_symlink():
            if dst.exists():
                healthy_count += 1
            else:
                broken_links.append(str(dst))
        else:
            missing_links.append(str(dst))

    return managed_count, healthy_count, broken_links, missing_links


def status_repo(cfg: RepoConfig, as_json: bool) -> int:
    git_ok = is_git_repo(cfg.repo_dir)
    path_exists = cfg.repo_dir.exists() or cfg.repo_dir.is_symlink()

    current_branch: str | None = None
    detached = False
    head_sha: str | None = None
    dirty = False
    ahead = 0
    behind = 0
    push_url_actual: str | None = None

    if git_ok:
        sym_res = run_git(["symbolic-ref", "--quiet", "--short", "HEAD"], cwd=cfg.repo_dir)
        if sym_res.returncode == 0:
            current_branch = sym_res.stdout.strip()

        head_res = run_git(["rev-parse", "--verify", "--quiet", "HEAD"], cwd=cfg.repo_dir)
        if head_res.returncode == 0:
            head_sha = head_res.stdout.strip()
            detached = current_branch is None

        st_res = run_git(["status", "--porcelain"], cwd=cfg.repo_dir)
        if st_res.returncode == 0:
            dirty = st_res.stdout.strip() != ""

        push_res = run_git(["config", "--get-all", "remote.origin.pushurl"], cwd=cfg.repo_dir)
        if push_res.returncode == 0 and push_res.stdout.strip():
            push_url_actual = push_res.stdout.strip().splitlines()[0]

        upstream_ref = f"refs/remotes/origin/{cfg.branch}"
        up_res = run_git(["rev-parse", "--verify", "--quiet", upstream_ref], cwd=cfg.repo_dir)
        if head_sha is None:
            upstream_state = "unborn"
        elif up_res.returncode != 0:
            upstream_state = "no-upstream"
        else:
            rev_res = run_git(
                ["rev-list", "--left-right", "--count", f"HEAD...{upstream_ref}"],
                cwd=cfg.repo_dir,
            )
            if rev_res.returncode == 0:
                parts = rev_res.stdout.strip().split()
                if len(parts) == 2:
                    ahead, behind = int(parts[0]), int(parts[1])
            if ahead == 0 and behind == 0:
                upstream_state = "up-to-date"
            elif ahead == 0 and behind > 0:
                upstream_state = "behind"
            elif ahead > 0 and behind == 0:
                upstream_state = "ahead"
            else:
                upstream_state = "diverged"
    else:
        upstream_state = "not-git" if path_exists else "uncloned"

    m_path = manifest_path_for(cfg)
    managed_count, healthy_count, broken_links, missing_links = inspect_manifest_readonly(
        m_path
    )

    payload = {
        "name": cfg.name,
        "repoDir": str(cfg.repo_dir),
        "exists": path_exists,
        "isGitRepo": git_ok,
        "branch": cfg.branch,
        "currentBranch": current_branch,
        "detached": detached,
        "head": head_sha,
        "dirty": dirty,
        "upstreamState": upstream_state,
        "ahead": ahead,
        "behind": behind,
        "pushUrl": push_url_actual,
        "manifestPath": str(m_path),
        "managedCount": managed_count,
        "healthyCount": healthy_count,
        "brokenLinks": broken_links,
        "missingLinks": missing_links,
    }

    if as_json:
        print(json.dumps(payload, indent=2))
    else:
        lines = [
            f"name: {payload['name']}",
            f"repoDir: {payload['repoDir']}",
            f"exists: {payload['exists']}",
            f"isGitRepo: {payload['isGitRepo']}",
            f"branch: {payload['branch']}",
            f"currentBranch: {payload['currentBranch'] or '-'}",
            f"detached: {payload['detached']}",
            f"head: {payload['head'] or '-'}",
            f"dirty: {payload['dirty']}",
            f"upstreamState: {payload['upstreamState']} (ahead={ahead}, behind={behind})",
            f"pushUrl: {payload['pushUrl'] or '-'}",
            f"manifestPath: {payload['manifestPath']}",
            f"links: {healthy_count}/{managed_count} healthy, "
            f"{len(broken_links)} broken, {len(missing_links)} missing",
        ]
        print("\n".join(lines))

    return 0


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="detached-repo-sync",
        description="Sync and fan-out helper for detached Git repositories.",
    )
    subparsers = parser.add_subparsers(dest="command", required=True)

    for cmd in ("bootstrap", "pull", "link"):
        sub = subparsers.add_parser(cmd)
        sub.add_argument("config", type=Path, help="Path to repo JSON config file")

    status_parser = subparsers.add_parser("status")
    status_parser.add_argument("config", type=Path, help="Path to repo JSON config file")
    status_parser.add_argument(
        "--json",
        action="store_true",
        help="Print machine-readable JSON status output",
    )

    return parser


def main(argv: list[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)

    try:
        cfg = load_config(args.config)
    except ConfigError as exc:
        error(str(exc))
        return 1

    if args.command == "bootstrap":
        return bootstrap_repo(cfg)
    if args.command == "pull":
        return pull_repo(cfg)
    if args.command == "link":
        return link_repo(cfg)
    if args.command == "status":
        return status_repo(cfg, as_json=args.json)

    error(f"unknown command: {args.command}")
    return 2


if __name__ == "__main__":
    raise SystemExit(main())
