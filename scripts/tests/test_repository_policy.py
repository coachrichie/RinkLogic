import json
import subprocess
import unittest
from pathlib import Path
from tempfile import TemporaryDirectory

from scripts import repository_policy
from scripts.repository_policy import find_disallowed_tracked_paths


REQUIRED_DOCUMENTS = (
    "README.md",
    "CONTRIBUTING.md",
    "SECURITY.md",
    "ARCHITECTURE.md",
    "CHANGELOG.md",
    "docs/OPEN_SOURCE_READINESS.md",
    "docs/THIRD_PARTY.md",
)
REQUIRED_GITHUB_FILES = (
    ".github/PULL_REQUEST_TEMPLATE.md",
    ".github/ISSUE_TEMPLATE/bug.yml",
    ".github/ISSUE_TEMPLATE/feature.yml",
    ".github/ISSUE_TEMPLATE/hardware-test.yml",
    ".github/ISSUE_TEMPLATE/config.yml",
    ".github/CODEOWNERS",
    ".github/workflows/python-tests.yml",
    ".github/main-branch-protection.json",
    "docs/repository/GITHUB-SETTINGS.md",
)


class RepositoryPolicyTests(unittest.TestCase):
    def test_private_and_generated_paths_are_rejected(self):
        paths = [
            ".secrets/key.der",
            "analysis/private/player.fit",
            "watch/bin/app.prg",
            "watch-v2/bin/app.prg",
            "device.key",
            "watch.log",
        ]

        self.assertEqual(find_disallowed_tracked_paths(paths), paths)

    def test_source_and_public_docs_are_allowed(self):
        paths = [
            "watch-v2/source/ShiftSenseApp.mc",
            "docs/privacy-de.html",
            ".env.example",
        ]

        self.assertEqual(find_disallowed_tracked_paths(paths), [])

    def test_environment_dotfiles_are_rejected(self):
        paths = [".env", ".env.production", ".secrets/token.txt"]

        self.assertEqual(find_disallowed_tracked_paths(paths), paths)

    def test_public_fixture_exception_allows_only_fit(self):
        forbidden = [
            "fixtures/public/developer.key",
            "fixtures/public/certificate.der",
            "fixtures/public/certificate.pem",
            "fixtures/public/application.prg",
            "fixtures/public/watch.log",
        ]

        self.assertEqual(find_disallowed_tracked_paths(forbidden), forbidden)
        self.assertEqual(
            find_disallowed_tracked_paths(["fixtures/public/synthetic.fit"]), []
        )

    def test_real_git_listing_preserves_unicode_private_path(self):
        with TemporaryDirectory() as temporary_directory:
            root = Path(temporary_directory)
            private_file = root / "analysis" / "private" / "Übung.fit"
            private_file.parent.mkdir(parents=True)
            private_file.write_bytes(b"synthetic test content")
            subprocess.run(["git", "init"], cwd=root, check=True, capture_output=True)
            subprocess.run(
                ["git", "config", "user.name", "Policy Test"],
                cwd=root,
                check=True,
            )
            subprocess.run(
                ["git", "config", "user.email", "policy@example.invalid"],
                cwd=root,
                check=True,
            )
            subprocess.run(
                ["git", "add", "-f", "--", "analysis/private/Übung.fit"],
                cwd=root,
                check=True,
            )

            tracked_paths = repository_policy.list_tracked_paths(root)

            self.assertEqual(tracked_paths, ["analysis/private/Übung.fit"])
            self.assertEqual(find_disallowed_tracked_paths(tracked_paths), tracked_paths)

    def test_ignored_untracked_private_file_is_not_part_of_path_input(self):
        self.assertEqual(find_disallowed_tracked_paths([]), [])

    def test_path_matching_is_case_insensitive(self):
        paths = ["ANALYSIS/PRIVATE/Player.FIT", "WATCH-V2/BIN/App.PRG"]

        self.assertEqual(find_disallowed_tracked_paths(paths), paths)

    def test_required_repository_documents_exist(self):
        missing = [path for path in REQUIRED_DOCUMENTS if not Path(path).is_file()]

        self.assertEqual(missing, [])

    def test_open_source_license_files_are_required_and_present(self):
        expected = (
            "LICENSE",
            "NOTICE",
            "LICENSES/Apache-2.0.txt",
            "LICENSES/CC-BY-4.0.txt",
            "REUSE.toml",
            "requirements-dev.txt",
            "docs/LICENSING.md",
        )

        self.assertEqual(repository_policy.OPEN_SOURCE_LICENSE_FILES, expected)
        self.assertEqual(
            repository_policy.find_missing_required_files(Path("."), expected), []
        )

    def test_public_community_files_are_required_and_present(self):
        expected = ("CODE_OF_CONDUCT.md", "SUPPORT.md", "GOVERNANCE.md")

        self.assertEqual(repository_policy.PUBLIC_COMMUNITY_FILES, expected)
        self.assertEqual(
            repository_policy.find_missing_required_files(Path("."), expected), []
        )

    def test_missing_required_document_is_reported(self):
        with TemporaryDirectory() as temporary_directory:
            root = Path(temporary_directory)
            (root / "README.md").write_text("# Test\n", encoding="utf-8")

            self.assertEqual(
                repository_policy.find_missing_required_files(
                    root, ("README.md", "SECURITY.md")
                ),
                ["SECURITY.md"],
            )

    def test_required_github_files_exist(self):
        missing = [path for path in REQUIRED_GITHUB_FILES if not Path(path).is_file()]

        self.assertEqual(missing, [])

    def test_workflow_has_no_secret_dependency(self):
        workflow = Path(".github/workflows/python-tests.yml").read_text(
            encoding="utf-8"
        )

        self.assertIn("python-tests:", workflow)
        self.assertIn(
            'python -m unittest discover -s analysis/tests -p "test_*.py" -v',
            workflow,
        )
        self.assertNotIn("${{ secrets.", workflow)

    def test_workflow_runs_open_source_release_gates(self):
        workflow = Path(".github/workflows/python-tests.yml").read_text(
            encoding="utf-8"
        )

        self.assertIn("python -m pip install -r requirements-dev.txt", workflow)
        self.assertIn(
            'python -m unittest discover -s scripts/tests -p "test_*.py" -v',
            workflow,
        )
        self.assertIn("python scripts/repository_policy.py", workflow)
        self.assertIn("python -m reuse lint", workflow)

    def test_branch_protection_requires_pr_and_disables_destructive_updates(self):
        protection = json.loads(
            Path(".github/main-branch-protection.json").read_text(encoding="utf-8")
        )

        self.assertEqual(
            protection["required_pull_request_reviews"][
                "required_approving_review_count"
            ],
            0,
        )
        self.assertFalse(protection["allow_force_pushes"])
        self.assertFalse(protection["allow_deletions"])


if __name__ == "__main__":
    unittest.main()
