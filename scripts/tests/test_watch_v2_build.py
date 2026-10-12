import json
import shutil
import subprocess
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]


class WatchV2BuildConfigurationTests(unittest.TestCase):
    def describe(self, model, export=False, unit_test=False):
        shell = shutil.which("pwsh") or shutil.which("powershell")
        self.assertIsNotNone(shell)
        args = [
            shell, "-NoProfile", "-ExecutionPolicy", "Bypass", "-File",
            str(ROOT / "scripts" / "watch-v2-build.ps1"),
            "-Device", "venu2plus", "-DistanceModel", model,
            "-DescribeConfiguration",
        ]
        if export:
            args.append("-ExportPackage")
        if unit_test:
            args.append("-UnitTest")
        return subprocess.run(
            args,
            cwd=ROOT,
            capture_output=True,
            text=True,
            check=False,
        )

    def test_all_distance_modes_select_isolated_jungles_and_artifacts(self):
        expected = {
            "Fixed": ("watch-v2/monkey.jungle", "ShiftSenseV2.prg"),
            "ProfileHeight": (
                "watch-v2/monkey-profile-test.jungle",
                "RinkLogic-profile-test.prg",
            ),
            "CalibratedProfile": (
                "watch-v2/monkey-calibrated-profile-test.jungle",
                "RinkLogic-calibrated-profile-test.prg",
            ),
        }
        for model, (jungle, artifact) in expected.items():
            with self.subTest(model=model):
                result = self.describe(model)
                self.assertEqual(result.returncode, 0, result.stderr)
                config = json.loads(result.stdout)
                self.assertEqual(config["distanceModel"], model)
                self.assertEqual(config["jungle"], jungle)
                self.assertEqual(config["artifact"], artifact)
                self.assertFalse(config["exportPackage"])

    def test_calibrated_export_uses_versioned_iq_name(self):
        result = self.describe("CalibratedProfile", export=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        config = json.loads(result.stdout)
        self.assertTrue(config["exportPackage"])
        self.assertEqual(config["artifact"], "RinkLogic-0.2.0-beta.4.iq")

    def test_export_rejects_non_calibrated_modes(self):
        for model in ["Fixed", "ProfileHeight"]:
            with self.subTest(model=model):
                result = self.describe(model, export=True)
                self.assertNotEqual(result.returncode, 0)

    def test_export_rejects_unit_test_combination(self):
        result = self.describe("CalibratedProfile", export=True, unit_test=True)
        self.assertNotEqual(result.returncode, 0)

    def test_unsupported_distance_model_is_rejected(self):
        result = self.describe("Unsupported")
        self.assertNotEqual(result.returncode, 0)


if __name__ == "__main__":
    unittest.main()
