"""Executable contracts for the Beta-7 Windows packaging entry point."""

from __future__ import annotations

import json
import os
from pathlib import Path
import subprocess
from tempfile import TemporaryDirectory
import unittest


ROOT = Path(__file__).resolve().parents[2]
SCRIPT = ROOT / "scripts" / "build-tester-assistant.ps1"
EXAMPLE = ROOT / "docs" / "testing" / "beta-test-assignment.example.json"


def describe(*arguments: str, ci: bool = False) -> subprocess.CompletedProcess[str]:
    env = os.environ.copy()
    if ci:
        env["GITHUB_ACTIONS"] = "true"
    else:
        env.pop("GITHUB_ACTIONS", None)
    return subprocess.run(
        [
            "pwsh",
            "-NoProfile",
            "-File",
            str(SCRIPT),
            "-DescribeConfiguration",
            *arguments,
        ],
        cwd=ROOT,
        env=env,
        capture_output=True,
        text=True,
        check=False,
    )


class BuildTesterAssistantTests(unittest.TestCase):
    def test_describe_reports_pinned_beta7_one_folder_build(self):
        with TemporaryDirectory() as directory:
            result = describe("-OutputDirectory", directory)

        self.assertEqual(result.returncode, 0, result.stderr)
        config = json.loads(result.stdout)
        self.assertEqual(config["python_version"], "3.12")
        self.assertEqual(config["pyinstaller_version"], "6.22.3")
        self.assertEqual(config["entry_point"], "tester_assistant.app:main")
        self.assertEqual(config["mode"], "one-folder-windowed-clean-no-upx")
        self.assertEqual(config["distribution"], "RinkLogic-Beta7-Test-Assistant")
        self.assertEqual(
            config["resources"],
            [
                "tester_assistant/resources/questionnaire.de.json",
                "watch-v2/device-matrix.json",
            ],
        )
        self.assertEqual(config["outputs"], ["build-manifest.json", "SHA256SUMS.txt"])
        self.assertIsNone(config["assignment"])

    def test_default_output_is_outside_the_repository(self):
        result = describe()

        self.assertEqual(result.returncode, 0, result.stderr)
        config = json.loads(result.stdout)
        self.assertFalse(Path(config["output_directory"]).is_relative_to(ROOT))

    def test_output_inside_repository_is_refused_even_in_describe_mode(self):
        result = describe("-OutputDirectory", str(ROOT / "dist"))

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("outside the tracked source tree", result.stderr.lower())

    def test_local_assignment_is_validated_and_only_that_file_is_planned(self):
        with TemporaryDirectory() as directory:
            folder = Path(directory)
            assignment = folder / "assignment.json"
            assignment.write_bytes(EXAMPLE.read_bytes())
            (folder / "private-notes.txt").write_text(
                "must not be included", encoding="utf-8"
            )

            result = describe("-Assignment", str(assignment))

        self.assertEqual(result.returncode, 0, result.stderr)
        config = json.loads(result.stdout)
        self.assertEqual(config["assignment"], str(assignment.resolve()))
        self.assertEqual(
            config["included_files"],
            [
                "tester_assistant/resources/questionnaire.de.json",
                "watch-v2/device-matrix.json",
                "embedded-assignment.json",
            ],
        )
        self.assertNotIn("private-notes", result.stdout)

    def test_invalid_assignment_is_refused(self):
        with TemporaryDirectory() as directory:
            assignment = Path(directory) / "assignment.json"
            assignment.write_text('{"contract_version": 999}', encoding="utf-8")
            result = describe("-Assignment", str(assignment))

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("unsupported assignment", result.stderr.lower())

    def test_ci_accepts_only_no_assignment_or_exact_committed_example(self):
        self.assertEqual(describe(ci=True).returncode, 0)
        self.assertEqual(
            describe("-Assignment", str(EXAMPLE), ci=True).returncode,
            0,
        )
        with TemporaryDirectory() as directory:
            copied_example = Path(directory) / "assignment.json"
            copied_example.write_bytes(EXAMPLE.read_bytes())
            copied = describe("-Assignment", str(copied_example), ci=True)

        self.assertNotEqual(copied.returncode, 0)
        self.assertIn("only the committed synthetic example", copied.stderr.lower())

    def test_requirements_pin_supported_pyinstaller(self):
        requirements = (ROOT / "requirements-packaging.txt").read_text(encoding="utf-8")

        self.assertEqual(
            requirements.splitlines(),
            ["-r requirements-tester-app.txt", "pyinstaller==6.22.3"],
        )

    def test_real_build_refuses_a_dirty_worktree_before_packaging(self):
        probe = ROOT / ".packaging-dirty-probe.txt"
        self.assertFalse(probe.exists())
        try:
            probe.write_text("untracked test probe\n", encoding="utf-8")
            with TemporaryDirectory() as directory:
                result = subprocess.run(
                    [
                        "pwsh",
                        "-NoProfile",
                        "-File",
                        str(SCRIPT),
                        "-OutputDirectory",
                        directory,
                    ],
                    cwd=ROOT,
                    capture_output=True,
                    text=True,
                    check=False,
                )
        finally:
            probe.unlink(missing_ok=True)

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("dirty", result.stderr.lower())

    def test_workflow_tests_every_pr_and_manual_build_never_uploads(self):
        workflow = (ROOT / ".github" / "workflows" / "python-tests.yml").read_text(
            encoding="utf-8"
        )

        self.assertIn("workflow_dispatch:", workflow)
        ordinary, manual = workflow.split("package-assistant:", 1)
        self.assertIn("requirements-packaging.txt", ordinary)
        self.assertIn("tester_assistant_tests", ordinary)
        self.assertIn("test_build_tester_assistant", ordinary)
        self.assertIn("if: github.event_name == 'workflow_dispatch'", manual)
        self.assertIn("--self-check", manual)
        self.assertIn("SHA256SUMS.txt", manual)
        self.assertNotIn("-Assignment", manual)
        self.assertNotIn("upload-artifact", workflow)


if __name__ == "__main__":
    unittest.main()
