import json
import os
import unittest
import xml.etree.ElementTree as ET
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
MATRIX_PATH = ROOT / "watch-v2" / "device-matrix.json"
MANIFEST_PATH = ROOT / "watch-v2" / "manifest.xml"


class WatchV2DeviceMatrixTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.matrix = json.loads(MATRIX_PATH.read_text(encoding="utf-8"))
        appdata = Path(os.environ["APPDATA"])
        cls.devices_root = appdata / "Garmin" / "ConnectIQ" / "Devices"

    def test_ids_are_unique(self):
        ids = [entry["id"] for entry in self.matrix["devices"]]
        self.assertEqual(len(ids), len(set(ids)))

    def test_all_matrix_ids_are_installed_when_sdk_profiles_are_available(self):
        if not self.devices_root.is_dir():
            self.skipTest("Garmin Connect IQ device profiles are not installed")
        ids = [entry["id"] for entry in self.matrix["devices"]]
        for device_id in ids:
            with self.subTest(device=device_id):
                self.assertTrue((self.devices_root / device_id / "compiler.json").is_file())

    def test_classes_statuses_and_representatives_are_valid(self):
        allowed_displays = {
            "amoled-small", "amoled-medium", "amoled-large",
            "mip-small", "mip-medium", "mip-large", "special-rect", "special-mip",
        }
        allowed_inputs = {"touch-two-button", "button-five"}
        release_classes = set()
        represented = set()
        for entry in self.matrix["devices"]:
            self.assertIn(entry["displayClass"], allowed_displays)
            self.assertIn(entry["inputClass"], allowed_inputs)
            self.assertIn(entry["status"], {"release-enabled", "deferred"})
            if entry["status"] == "release-enabled":
                release_classes.add(entry["displayClass"])
                if entry["representative"]:
                    represented.add(entry["displayClass"])
        self.assertEqual(release_classes, represented)

    def test_ring_one_exactly_matches_manifest(self):
        enabled = {
            entry["id"] for entry in self.matrix["devices"]
            if entry["ring"].startswith("Ring1") and entry["status"] == "release-enabled"
        }
        root = ET.parse(MANIFEST_PATH).getroot()
        ns = {"iq": "http://www.garmin.com/xml/connectiq"}
        manifest_ids = {
            node.attrib["id"] for node in root.findall(".//iq:product", ns)
        }
        self.assertEqual(enabled, manifest_ids)
        self.assertNotIn("venux1", manifest_ids)
        self.assertNotIn("instinct3solar45mm", manifest_ids)
        self.assertFalse(any(device.startswith("instinct2") for device in manifest_ids))

    def test_matrix_metadata_matches_installed_profiles(self):
        if not self.devices_root.is_dir():
            self.skipTest("Garmin Connect IQ device profiles are not installed")
        for entry in self.matrix["devices"]:
            profile = json.loads(
                (self.devices_root / entry["id"] / "compiler.json").read_text(encoding="utf-8")
            )
            with self.subTest(device=entry["id"]):
                self.assertEqual(entry["width"], profile["resolution"]["width"])
                self.assertEqual(entry["height"], profile["resolution"]["height"])
                self.assertEqual(entry["displayType"], profile["displayType"])


if __name__ == "__main__":
    unittest.main()
