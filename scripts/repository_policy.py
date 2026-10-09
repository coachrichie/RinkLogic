"""Repository privacy and generated-artifact policy checks."""

from __future__ import annotations

import os
import subprocess
import sys
from collections.abc import Iterable, Sequence
from pathlib import Path


DISALLOWED_PREFIXES = (
    ".secrets/",
    "analysis/private/",
    "fixtures/private/",
    "watch/tests/fixtures/private/",
    "watch/bin/",
    "watch-v2/bin/",
)
DISALLOWED_SUFFIXES = (".fit", ".prg", ".der", ".pem", ".key", ".log")
PUBLIC_FIXTURE_PREFIXES = ("fixtures/public/", "watch/tests/fixtures/public/")
OPEN_SOURCE_LICENSE_FILES = (
    "LICENSE",
    "NOTICE",
    "LICENSES/Apache-2.0.txt",
    "LICENSES/CC-BY-4.0.txt",
    "REUSE.toml",
    "requirements-dev.txt",
    "docs/LICENSING.md",
)
PUBLIC_COMMUNITY_FILES = ("CODE_OF_CONDUCT.md", "SUPPORT.md", "GOVERNANCE.md")
REQUIRED_DOCUMENTS = (
    "README.md",
    "CONTRIBUTING.md",
    "SECURITY.md",
    "ARCHITECTURE.md",
    "CHANGELOG.md",
    "docs/OPEN_SOURCE_READINESS.md",
    "docs/THIRD_PARTY.md",
    ".github/PULL_REQUEST_TEMPLATE.md",
    ".github/ISSUE_TEMPLATE/bug.yml",
    ".github/ISSUE_TEMPLATE/feature.yml",
    ".github/ISSUE_TEMPLATE/hardware-test.yml",
    ".github/ISSUE_TEMPLATE/config.yml",
    ".github/CODEOWNERS",
    ".github/workflows/python-tests.yml",
    ".github/main-branch-protection.json",
    "docs/repository/GITHUB-SETTINGS.md",
) + OPEN_SOURCE_LICENSE_FILES + PUBLIC_COMMUNITY_FILES


def normalize_repo_path(path: str) -> str:
    """Return a case-insensitive repository path without losing leading dots."""
    normalized = path.replace("\\", "/")
    if normalized.startswith("./"):
        normalized = normalized[2:]
    return normalized.lower()


def list_tracked_paths(repo_root: Path) -> list[str]:
    """Return Git-tracked paths without quoting or Unicode loss."""
    result = subprocess.run(
        ["git", "ls-files", "-z"],
        cwd=repo_root,
        check=False,
        capture_output=True,
    )
    if result.returncode != 0:
        raise RuntimeError("unable to list tracked files")
    return [os.fsdecode(path) for path in result.stdout.split(b"\0") if path]


def find_disallowed_tracked_paths(paths: Iterable[str]) -> list[str]:
    """Return tracked paths that violate repository privacy boundaries."""
    violations: list[str] = []
    for original_path in paths:
        path = normalize_repo_path(original_path)
        name = path.rsplit("/", 1)[-1]
        in_public_fixtures = path.startswith(PUBLIC_FIXTURE_PREFIXES)
        is_public_fit_fixture = in_public_fixtures and path.endswith(".fit")
        is_environment_file = name == ".env" or (
            name.startswith(".env.") and name != ".env.example"
        )
        is_disallowed = (
            path.startswith(DISALLOWED_PREFIXES)
            or is_environment_file
            or (path.endswith(DISALLOWED_SUFFIXES) and not is_public_fit_fixture)
        )
        if is_disallowed:
            violations.append(original_path)
    return violations


def find_missing_required_files(
    repo_root: Path, required_paths: Iterable[str]
) -> list[str]:
    """Return required repository-relative files that do not exist."""
    return [path for path in required_paths if not (repo_root / path).is_file()]


def main(argv: Sequence[str] | None = None) -> int:
    """Check Git-tracked paths and return a process-style exit code."""
    del argv
    root_result = subprocess.run(
        ["git", "rev-parse", "--show-toplevel"],
        check=False,
        capture_output=True,
        text=True,
    )
    if root_result.returncode != 0:
        print("Repository policy: ERROR (unable to list tracked files)", file=sys.stderr)
        return 2

    repo_root = Path(root_result.stdout.strip())
    try:
        tracked_paths = list_tracked_paths(repo_root)
    except (OSError, RuntimeError):
        print("Repository policy: ERROR (unable to list tracked files)", file=sys.stderr)
        return 2

    violations = find_disallowed_tracked_paths(tracked_paths)
    missing = find_missing_required_files(repo_root, REQUIRED_DOCUMENTS)
    if violations or missing:
        print("Repository policy: FAIL", file=sys.stderr)
        for path in violations:
            print(f"- {path}", file=sys.stderr)
        for path in missing:
            print(f"- missing: {path}", file=sys.stderr)
        return 1

    print("Repository policy: PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
