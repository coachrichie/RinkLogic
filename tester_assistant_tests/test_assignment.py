"""Behavioral contract tests for assignment loading and identity validation."""

import json
import tempfile
import unittest
from pathlib import Path

from tester_assistant.assignment import Assignment, AssignmentError
from tester_assistant_tests.fixtures import beta6_assignment_dict


class AssignmentTests(unittest.TestCase):
    def test_loads_a_valid_beta6_assignment_and_exposes_immutable_fields(self):
        assignment = Assignment.from_dict(beta6_assignment_dict())

        self.assertEqual(assignment.contract_version, 1)
        self.assertEqual(assignment.tester_id, "TDEMO1")
        self.assertEqual(assignment.assignment_id, "TDEMO1-R1-001")
        self.assertEqual(assignment.release_id, "RL-B6-20261023-43694FC")
        self.assertEqual(assignment.app_version, "0.2.0-beta.6")
        self.assertEqual(assignment.internal_version, 6)
        self.assertEqual(assignment.fit_schema, 12)
        self.assertEqual(assignment.model_id, "profile_height_v1+local_known_distance_v1")
        self.assertEqual(assignment.product_id, "venu2plus")
        self.assertEqual(assignment.surface, "inline")
        self.assertEqual(assignment.protocol, "calibration")
        self.assertEqual(assignment.expected_prg_sha256, "0" * 64)
        self.assertEqual(assignment.upload_url, "https://example.invalid/private-upload")
        self.assertEqual(assignment.consent_version, "beta6-consent-2026-10-23")
        with self.assertRaises((AttributeError, TypeError)):
            assignment.tester_id = "TOTHER"

    def test_loads_json_from_a_path(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "assignment.json"
            path.write_text(json.dumps(beta6_assignment_dict()), encoding="utf-8")

            loaded = Assignment.load(path)

        self.assertEqual(loaded.assignment_id, "TDEMO1-R1-001")

    def test_rejects_each_missing_contract_field(self):
        for key in beta6_assignment_dict():
            with self.subTest(missing=key):
                raw = beta6_assignment_dict()
                del raw[key]
                with self.assertRaises(AssignmentError):
                    Assignment.from_dict(raw)

    def test_rejects_unknown_keys(self):
        raw = beta6_assignment_dict()
        raw["upload_urll"] = raw["upload_url"]
        with self.assertRaises(AssignmentError):
            Assignment.from_dict(raw)

    def test_rejects_malformed_pseudonymous_ids(self):
        for key, value in (
            ("tester_id", "tester-1"),
            ("tester_id", "T1234"),
            ("assignment_id", "TOTHER-R1-001"),
            ("assignment_id", "TDEMO1-R5-001"),
            ("assignment_id", "TDEMO1-R1-1"),
        ):
            with self.subTest(key=key, value=value):
                raw = beta6_assignment_dict()
                raw[key] = value
                with self.assertRaises(AssignmentError):
                    Assignment.from_dict(raw)

    def test_rejects_non_beta6_release_identity(self):
        for key, value in (
            ("release_id", "beta5-release"),
            ("app_version", "0.2.0-beta.5"),
            ("internal_version", 5),
            ("fit_schema", 11),
            ("model_id", "fixed_v1"),
            ("consent_version", "beta6-consent-2026-10-22"),
        ):
            with self.subTest(key=key, value=value):
                raw = beta6_assignment_dict()
                raw[key] = value
                with self.assertRaises(AssignmentError):
                    Assignment.from_dict(raw)

    def test_rejects_unsupported_product_surface_and_protocol(self):
        for key, value in (
            ("product_id", "venu3"),
            ("surface", "rink"),
            ("protocol", "uncontrolled"),
        ):
            with self.subTest(key=key, value=value):
                raw = beta6_assignment_dict()
                raw[key] = value
                with self.assertRaises(AssignmentError):
                    Assignment.from_dict(raw)

    def test_rejects_malformed_installation_sha256(self):
        for value in ("", "abc", "g" * 64, "0" * 63):
            with self.subTest(value=value):
                raw = beta6_assignment_dict()
                raw["expected_prg_sha256"] = value
                with self.assertRaises(AssignmentError):
                    Assignment.from_dict(raw)

    def test_rejects_non_https_upload_url(self):
        for value in (
            "http://example.invalid/upload",
            "",
            "https:///missing-host",
            "https://example.invalid:bad/upload",
        ):
            with self.subTest(value=value):
                raw = beta6_assignment_dict()
                raw["upload_url"] = value
                with self.assertRaises(AssignmentError):
                    Assignment.from_dict(raw)

    def test_rejects_filename_with_nonmatching_assignment_stem(self):
        assignment = Assignment.from_dict(beta6_assignment_dict())

        for name in (
            "TDEMO1-R1-002_2026-10-24_inline_calibration_original.zip",
            "TDEMO1-R1-001_2026-13-24_inline_calibration_original.zip",
            "TDEMO1-R1-001_2026-10-24_ice_calibration_original.zip",
            "TDEMO1-R1-001_2026-10-24_inline_smoke_original.zip",
        ):
            with self.subTest(name=name), self.assertRaises(AssignmentError):
                assignment.validate_original_name(name)

    def test_accepts_supported_original_filename_forms(self):
        assignment = Assignment.from_dict(beta6_assignment_dict())

        assignment.validate_original_name(
            "TDEMO1-R1-001_2026-10-24_inline_calibration_original.zip"
        )
        assignment.validate_original_name(
            "TDEMO1-R1-001_2026-10-24_inline_calibration_original.fit"
        )


if __name__ == "__main__":
    unittest.main()
