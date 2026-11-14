import subprocess
import unittest
from pathlib import Path
from tempfile import TemporaryDirectory

from scripts.release_audit import (
    audit_repository,
    list_history_paths,
    list_local_sensitive_candidates,
)


def run_git(root: Path, *args: str) -> str:
    result = subprocess.run(
        ["git", *args],
        cwd=root,
        check=True,
        capture_output=True,
        text=True,
    )
    return result.stdout.strip()


def initialize_repository(root: Path) -> None:
    run_git(root, "init")
    run_git(root, "config", "user.name", "Release Audit Test")
    run_git(root, "config", "user.email", "audit@example.invalid")


class ReleaseAuditTests(unittest.TestCase):
    def test_direct_script_execution_resolves_repository_policy_import(self):
        repository_root = Path(__file__).resolve().parents[2]
        script = repository_root / "scripts" / "release_audit.py"
        with TemporaryDirectory() as temporary_directory:
            root = Path(temporary_directory)
            initialize_repository(root)
            result = subprocess.run(
                ["python", str(script)],
                cwd=root,
                check=False,
                capture_output=True,
                text=True,
            )

        self.assertIn(result.returncode, (0, 1))
        self.assertNotIn("ModuleNotFoundError", result.stderr)

    def test_deleted_unicode_private_fit_remains_a_history_violation(self):
        with TemporaryDirectory() as temporary_directory:
            root = Path(temporary_directory)
            initialize_repository(root)
            private_file = root / "analysis" / "private" / "Übung.fit"
            private_file.parent.mkdir(parents=True)
            private_file.write_bytes(b"synthetic private fixture")
            run_git(root, "add", "-f", "--", "analysis/private/Übung.fit")
            run_git(root, "commit", "-m", "add private fixture")
            run_git(root, "rm", "--", "analysis/private/Übung.fit")
            run_git(root, "commit", "-m", "remove private fixture")

            self.assertIn("analysis/private/Übung.fit", list_history_paths(root))
            self.assertIn(
                "history-path: analysis/private/Übung.fit", audit_repository(root)
            )

    def test_ignored_sensitive_candidates_are_reported_by_name_only(self):
        with TemporaryDirectory() as temporary_directory:
            root = Path(temporary_directory)
            initialize_repository(root)
            (root / ".gitignore").write_text(
                ".env*\nwatch-v2/bin/\n", encoding="utf-8"
            )
            (root / ".env.production").write_text(
                "SECRET_VALUE=must-not-appear", encoding="utf-8"
            )
            generated = root / "watch-v2" / "bin" / "app.prg"
            generated.parent.mkdir(parents=True)
            generated.write_bytes(b"must-not-appear")

            candidates = list_local_sensitive_candidates(root)

            self.assertEqual(candidates, [".env.production", "watch-v2/bin/app.prg"])
            self.assertNotIn("must-not-appear", "\n".join(candidates))

    def test_absolute_workstation_path_reports_commit_and_file_not_value(self):
        with TemporaryDirectory() as temporary_directory:
            root = Path(temporary_directory)
            initialize_repository(root)
            (root / "config.txt").write_text(
                "workspace=C:\\Users\\example\\private-project\n", encoding="utf-8"
            )
            run_git(root, "add", "config.txt")
            run_git(root, "commit", "-m", "add workstation path")
            commit = run_git(root, "rev-parse", "HEAD")

            findings = audit_repository(root)

            self.assertIn(f"absolute-path: {commit}:config.txt", findings)
            self.assertNotIn("private-project", "\n".join(findings))

    def test_absolute_path_rule_does_not_report_its_own_pattern_definition(self):
        with TemporaryDirectory() as temporary_directory:
            root = Path(temporary_directory)
            initialize_repository(root)
            scanner = root / "scripts" / "release_audit.py"
            scanner.parent.mkdir(parents=True)
            scanner.write_text(
                'ABSOLUTE_PATH_PATTERN = r"([A-Za-z]:\\\\Users\\\\|/Users/|/home/)"\n',
                encoding="utf-8",
            )
            scanner_test = root / "scripts" / "tests" / "test_release_audit.py"
            scanner_test.parent.mkdir(parents=True)
            scanner_test.write_text(
                'fixture = "C:\\Users\\example\\private-project"\n',
                encoding="utf-8",
            )
            run_git(
                root,
                "add",
                "scripts/release_audit.py",
                "scripts/tests/test_release_audit.py",
            )
            run_git(root, "commit", "-m", "add scanner")

            self.assertEqual(audit_repository(root), [])

    def test_known_assistant_privacy_test_paths_are_narrowly_exempt(self):
        with TemporaryDirectory() as temporary_directory:
            root = Path(temporary_directory)
            initialize_repository(root)
            bundle = root / "tester_assistant_tests" / "test_bundle.py"
            questionnaire = root / "tester_assistant_tests" / "test_questionnaire.py"
            bundle.parent.mkdir(parents=True)
            bundle.write_text(
                'fixture = "path=/home/tester/run.fit"\n'
                'byte_fixture = b"run,note\\n1,/home/tester/run.fit\\n"\n',
                encoding="utf-8",
            )
            questionnaire.write_text(
                'fixture = r"C:\\Users\\Tester\\Documents\\original.fit"\n',
                encoding="utf-8",
            )
            run_git(root, "add", "tester_assistant_tests")
            run_git(root, "commit", "-m", "add synthetic privacy fixtures")

            self.assertEqual(audit_repository(root), [])

    def test_other_absolute_path_in_privacy_test_file_is_still_reported(self):
        with TemporaryDirectory() as temporary_directory:
            root = Path(temporary_directory)
            initialize_repository(root)
            fixture = root / "tester_assistant_tests" / "test_bundle.py"
            fixture.parent.mkdir(parents=True)
            fixture.write_text(
                'fixture = r"C:\\Users\\RealPerson\\private.fit"\n',
                encoding="utf-8",
            )
            run_git(root, "add", "tester_assistant_tests/test_bundle.py")
            run_git(root, "commit", "-m", "add leaked path")
            commit = run_git(root, "rev-parse", "HEAD")

            self.assertIn(
                f"absolute-path: {commit}:tester_assistant_tests/test_bundle.py",
                audit_repository(root),
            )

    def test_allowed_fixture_does_not_hide_real_path_on_same_line(self):
        with TemporaryDirectory() as temporary_directory:
            root = Path(temporary_directory)
            initialize_repository(root)
            fixture = root / "tester_assistant_tests" / "test_bundle.py"
            fixture.parent.mkdir(parents=True)
            fixture.write_text(
                'fixtures = "/home/tester/run.fit C:\\Users\\RealPerson\\private.fit"\n',
                encoding="utf-8",
            )
            run_git(root, "add", "tester_assistant_tests/test_bundle.py")
            run_git(root, "commit", "-m", "mix fixture and leaked path")
            commit = run_git(root, "rev-parse", "HEAD")

            self.assertIn(
                f"absolute-path: {commit}:tester_assistant_tests/test_bundle.py",
                audit_repository(root),
            )

    def test_allowed_fixture_path_with_suffix_extension_is_reported(self):
        with TemporaryDirectory() as temporary_directory:
            root = Path(temporary_directory)
            initialize_repository(root)
            fixture = root / "tester_assistant_tests" / "test_bundle.py"
            fixture.parent.mkdir(parents=True)
            fixture.write_text(
                'posix = "/home/tester/run.fit/private.fit"\n'
                'windows = r"C:\\Users\\Tester\\run.fit\\private.fit"\n',
                encoding="utf-8",
            )
            run_git(root, "add", "tester_assistant_tests/test_bundle.py")
            run_git(root, "commit", "-m", "extend synthetic fixture paths")
            commit = run_git(root, "rev-parse", "HEAD")

            self.assertIn(
                f"absolute-path: {commit}:tester_assistant_tests/test_bundle.py",
                audit_repository(root),
            )

    def test_allowed_fixture_path_with_prefix_extension_is_reported(self):
        with TemporaryDirectory() as temporary_directory:
            root = Path(temporary_directory)
            initialize_repository(root)
            fixture = root / "tester_assistant_tests" / "test_bundle.py"
            fixture.parent.mkdir(parents=True)
            fixture.write_text(
                'posix = "/private/home/tester/run.fit"\n'
                'windows = r"private-C:\\Users\\Tester\\run.fit"\n',
                encoding="utf-8",
            )
            run_git(root, "add", "tester_assistant_tests/test_bundle.py")
            run_git(root, "commit", "-m", "prefix synthetic fixture paths")
            commit = run_git(root, "rev-parse", "HEAD")

            self.assertIn(
                f"absolute-path: {commit}:tester_assistant_tests/test_bundle.py",
                audit_repository(root),
            )

    def test_allowed_fixture_path_with_punctuation_or_space_extension_is_reported(self):
        source_lines = (
            'fixture = "/home/tester/run.fit?private"\n',
            'fixture = "/home/tester/run.fit#private"\n',
            'fixture = "/home/tester/run.fit private"\n',
            'fixture = r"C:\\Users\\Tester\\run.fit?private"\n',
            'fixture = r"C:\\Users\\Tester\\run.fit#private"\n',
            'fixture = r"C:\\Users\\Tester\\run.fit private"\n',
        )
        for source_line in source_lines:
            with self.subTest(source_line=source_line), TemporaryDirectory() as temporary_directory:
                root = Path(temporary_directory)
                initialize_repository(root)
                fixture = root / "tester_assistant_tests" / "test_bundle.py"
                fixture.parent.mkdir(parents=True)
                fixture.write_text(source_line, encoding="utf-8")
                run_git(root, "add", "tester_assistant_tests/test_bundle.py")
                run_git(root, "commit", "-m", "extend fixture with punctuation")
                commit = run_git(root, "rev-parse", "HEAD")

                self.assertIn(
                    f"absolute-path: {commit}:tester_assistant_tests/test_bundle.py",
                    audit_repository(root),
                )


if __name__ == "__main__":
    unittest.main()
