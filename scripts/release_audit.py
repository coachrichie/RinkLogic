"""Redacted release audit for repository history and local boundaries."""

from __future__ import annotations

import os
import subprocess
import sys
from pathlib import Path

try:
    from scripts.repository_policy import find_disallowed_tracked_paths
except ModuleNotFoundError:
    from repository_policy import find_disallowed_tracked_paths


ABSOLUTE_PATH_PATTERN = r"([A-Za-z]:\\Users\\|/Users/|/home/)"
ABSOLUTE_PATH_EXEMPTIONS = {
    "scripts/release_audit.py",
    "scripts/tests/test_release_audit.py",
}


def _run_git(repo_root: Path, *args: str, text: bool = False) -> subprocess.CompletedProcess:
    return subprocess.run(
        ["git", *args],
        cwd=repo_root,
        check=False,
        capture_output=True,
        text=text,
    )


def list_history_paths(repo_root: Path) -> list[str]:
    """Return every path present in any reachable commit without Git quoting."""
    commits_result = _run_git(repo_root, "rev-list", "--all", text=True)
    if commits_result.returncode != 0:
        raise RuntimeError("unable to list reachable commits")

    paths: set[str] = set()
    for commit in commits_result.stdout.splitlines():
        tree_result = _run_git(repo_root, "ls-tree", "-rz", "--name-only", commit)
        if tree_result.returncode != 0:
            raise RuntimeError(f"unable to inspect commit {commit}")
        paths.update(
            os.fsdecode(path) for path in tree_result.stdout.split(b"\0") if path
        )
    return sorted(paths)


def list_local_sensitive_candidates(repo_root: Path) -> list[str]:
    """Return ignored or untracked sensitive names without reading their content."""
    result = _run_git(
        repo_root,
        "status",
        "--porcelain=v1",
        "-z",
        "--ignored",
        "--untracked-files=all",
    )
    if result.returncode != 0:
        raise RuntimeError("unable to inspect ignored and untracked paths")

    paths: list[str] = []
    for record in result.stdout.split(b"\0"):
        if not record or len(record) < 4:
            continue
        status = record[:2]
        if status not in (b"??", b"!!"):
            continue
        paths.append(os.fsdecode(record[3:]))
    return sorted(find_disallowed_tracked_paths(paths))


def _absolute_path_findings(repo_root: Path) -> list[str]:
    commits_result = _run_git(repo_root, "rev-list", "--all", text=True)
    if commits_result.returncode != 0:
        raise RuntimeError("unable to list reachable commits")

    findings: set[str] = set()
    for commit in commits_result.stdout.splitlines():
        grep_result = _run_git(
            repo_root,
            "grep",
            "-I",
            "-l",
            "-E",
            ABSOLUTE_PATH_PATTERN,
            commit,
            "--",
            text=True,
        )
        if grep_result.returncode not in (0, 1):
            raise RuntimeError(f"unable to scan commit {commit}")
        for match in grep_result.stdout.splitlines():
            _, separator, path = match.partition(":")
            if separator and path and path not in ABSOLUTE_PATH_EXEMPTIONS:
                findings.add(f"absolute-path: {commit}:{path}")
    return sorted(findings)


def audit_repository(repo_root: Path) -> list[str]:
    """Return redacted release findings for history and local file names."""
    findings = {
        f"history-path: {path}"
        for path in find_disallowed_tracked_paths(list_history_paths(repo_root))
    }
    findings.update(
        f"local-path: {path}" for path in list_local_sensitive_candidates(repo_root)
    )
    findings.update(_absolute_path_findings(repo_root))
    return sorted(findings)


def main() -> int:
    root_result = _run_git(Path.cwd(), "rev-parse", "--show-toplevel", text=True)
    if root_result.returncode != 0:
        print("Repository release audit: ERROR", file=sys.stderr)
        return 2

    try:
        findings = audit_repository(Path(root_result.stdout.strip()))
    except (OSError, RuntimeError):
        print("Repository release audit: ERROR", file=sys.stderr)
        return 2

    if findings:
        print("Repository release audit: FAIL", file=sys.stderr)
        for finding in findings:
            print(f"- {finding}", file=sys.stderr)
        return 1

    print("Repository release audit: PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
