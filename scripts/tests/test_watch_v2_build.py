import json
import shutil
import subprocess
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]


class WatchV2BuildConfigurationTests(unittest.TestCase):
    def test_profile_height_mode_selects_profile_test_jungle(self):
        shell = shutil.which("pwsh") or shutil.which("powershell")
        self.assertIsNotNone(shell)
        result = subprocess.run(
            [
                shell,
                "-NoProfile",
                "-ExecutionPolicy",
                "Bypass",
                "-File",
                str(ROOT / "scripts" / "watch-v2-build.ps1"),
                "-Device",
                "venu2plus",
                "-DistanceModel",
                "ProfileHeight",
                "-DescribeConfiguration",
            ],
            cwd=ROOT,
            capture_output=True,
            text=True,
            check=False,
        )

        self.assertEqual(result.returncode, 0, result.stderr)
        config = json.loads(result.stdout)
        self.assertEqual(config["distanceModel"], "ProfileHeight")
        self.assertEqual(config["jungle"], "watch-v2/monkey-profile-test.jungle")
        self.assertEqual(config["artifact"], "RinkLogic-profile-test.prg")


if __name__ == "__main__":
    unittest.main()
