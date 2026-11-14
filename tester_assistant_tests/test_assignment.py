"""Behavioral contract tests for assignment loading and identity validation."""

import json
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

import tester_assistant.assignment as assignment_module
from tester_assistant.assignment import Assignment, AssignmentError
from tester_assistant_tests.fixtures import beta7_assignment_dict


class AssignmentTests(unittest.TestCase):
    def _release_ids(self):
        loader = getattr(assignment_module, "load_release_device_ids", None)
        self.assertTrue(callable(loader), "Beta-7 device-matrix loader is missing")
        return loader()

    def _valid_assignment(self):
        try:
            return Assignment.from_dict(beta7_assignment_dict())
        except AssignmentError as exc:
            self.fail(f"A valid Beta-7 assignment was rejected: {exc}")

    def test_loads_a_valid_beta7_assignment_and_exposes_immutable_fields(self):
        assignment = self._valid_assignment()

        self.assertEqual(assignment.contract_version, 3)
        self.assertEqual(assignment.tester_id, "TDEMO1")
        self.assertEqual(assignment.assignment_id, "TDEMO1-R1-001")
        self.assertEqual(assignment.release_id, "RL-B7-20261028-3059786")
        self.assertEqual(assignment.app_version, "0.2.0-beta.7")
        self.assertEqual(assignment.internal_version, 7)
        self.assertEqual(assignment.fit_schema, 12)
        self.assertEqual(assignment.model_id, "profile_height_v1+local_known_distance_v1")
        self.assertEqual(assignment.product_id, "venu2plus")
        self.assertEqual(assignment.surface, "inline")
        self.assertEqual(assignment.protocol, "calibration")
        self.assertEqual(assignment.expected_prg_sha256, "0" * 64)
        self.assertEqual(assignment.return_email, "rinklogic@example.invalid")
        self.assertEqual(assignment.consent_version, "beta6-consent-2026-10-23")
        with self.assertRaises((AttributeError, TypeError)):
            assignment.tester_id = "TOTHER"

    def test_loads_exactly_fifty_unique_release_enabled_ring1_devices(self):
        product_ids = self._release_ids()

        self.assertIsInstance(product_ids, frozenset)
        self.assertEqual(len(product_ids), 50)
        for product_id in (
            "venu2plus",
            "venu445mm",
            "fr965",
            "epix2",
            "fenix847mm",
            "fr255s",
            "fenix8solar51mm",
        ):
            with self.subTest(product_id=product_id):
                self.assertIn(product_id, product_ids)

    def test_accepts_assignments_for_representative_amoled_and_mip_devices(self):
        for product_id in (
            "venu445mm",
            "fr965",
            "epix2pro51mm",
            "fenix847mm",
            "fr255s",
            "fenix7x",
        ):
            with self.subTest(product_id=product_id):
                values = beta7_assignment_dict()
                values["product_id"] = product_id
                try:
                    Assignment.from_dict(values)
                except AssignmentError as exc:
                    self.fail(f"Release-enabled Ring-1 device was rejected: {product_id}: {exc}")

    def test_rejects_ring2_deferred_and_unknown_devices(self):
        for product_id in ("venux1", "instinct3solar45mm", "unknown-watch"):
            with self.subTest(product_id=product_id):
                values = beta7_assignment_dict()
                values["product_id"] = product_id
                with self.assertRaises(AssignmentError):
                    Assignment.from_dict(values)

    def test_rejects_duplicate_and_malformed_device_matrix_data(self):
        source = Path(__file__).parents[1] / "watch-v2" / "device-matrix.json"
        base = json.loads(source.read_text(encoding="utf-8"))
        malformed_documents = []

        duplicate = json.loads(json.dumps(base))
        duplicate["devices"][1]["id"] = duplicate["devices"][0]["id"]
        malformed_documents.append(duplicate)

        wrong_schema = json.loads(json.dumps(base))
        wrong_schema["schemaVersion"] = 2
        malformed_documents.append(wrong_schema)

        missing_field = json.loads(json.dumps(base))
        del missing_field["devices"][0]["displayType"]
        malformed_documents.append(missing_field)

        bad_release_ring = json.loads(json.dumps(base))
        bad_release_ring["devices"][0]["ring"] = "Ring2"
        malformed_documents.append(bad_release_ring)

        malformed_documents.extend(([], {"schemaVersion": 1, "devices": "not-a-list"}))

        with tempfile.TemporaryDirectory() as directory:
            matrix_path = Path(directory) / "device-matrix.json"
            for index, document in enumerate(malformed_documents):
                with self.subTest(case=index):
                    matrix_path.write_text(json.dumps(document), encoding="utf-8")
                    with patch.object(
                        assignment_module,
                        "_device_matrix_path",
                        return_value=matrix_path,
                        create=True,
                    ):
                        with self.assertRaises(AssignmentError):
                            self._release_ids()

    def test_loads_the_matrix_from_the_pyinstaller_data_root(self):
        source = Path(__file__).parents[1] / "watch-v2" / "device-matrix.json"
        matrix = json.loads(source.read_text(encoding="utf-8"))
        matrix["devices"][0]["id"] = "packagedvenu2"

        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            packaged_matrix = root / "watch-v2" / "device-matrix.json"
            packaged_matrix.parent.mkdir(parents=True)
            packaged_matrix.write_text(json.dumps(matrix), encoding="utf-8")
            with patch.object(sys, "_MEIPASS", str(root), create=True):
                product_ids = self._release_ids()

        self.assertIn("packagedvenu2", product_ids)
        self.assertNotIn("venu2", product_ids)

    def test_unhashable_enum_values_fail_closed_with_assignment_error(self):
        source = Path(__file__).parents[1] / "watch-v2" / "device-matrix.json"
        base = json.loads(source.read_text(encoding="utf-8"))

        with tempfile.TemporaryDirectory() as directory:
            matrix_path = Path(directory) / "device-matrix.json"
            for field, value in (("ring", []), ("status", {}), ("displayType", [])):
                with self.subTest(field=field):
                    matrix = json.loads(json.dumps(base))
                    matrix["devices"][0][field] = value
                    matrix_path.write_text(json.dumps(matrix), encoding="utf-8")
                    with patch.object(
                        assignment_module,
                        "_device_matrix_path",
                        return_value=matrix_path,
                    ):
                        try:
                            self._release_ids()
                        except AssignmentError:
                            pass
                        except Exception as exc:
                            self.fail(
                                f"Malformed {field} escaped as {type(exc).__name__} instead of AssignmentError"
                            )
                        else:
                            self.fail(f"Malformed {field} was accepted")

    def test_loads_json_from_a_path(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "assignment.json"
            path.write_text(json.dumps(beta7_assignment_dict()), encoding="utf-8")

            try:
                loaded = Assignment.load(path)
            except AssignmentError as exc:
                self.fail(f"A valid Beta-7 assignment file was rejected: {exc}")

        self.assertEqual(loaded.assignment_id, "TDEMO1-R1-001")

    def test_rejects_each_missing_contract_field(self):
        for key in beta7_assignment_dict():
            with self.subTest(missing=key):
                raw = beta7_assignment_dict()
                del raw[key]
                with self.assertRaises(AssignmentError):
                    Assignment.from_dict(raw)

    def test_rejects_unknown_keys(self):
        raw = beta7_assignment_dict()
        raw["upload_url"] = "https://example.invalid/private-upload"
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
                raw = beta7_assignment_dict()
                raw[key] = value
                with self.assertRaises(AssignmentError):
                    Assignment.from_dict(raw)

    def test_rejects_non_beta7_release_identity(self):
        for key, value in (
            ("release_id", "beta5-release"),
            ("app_version", "0.2.0-beta.5"),
            ("internal_version", 5),
            ("fit_schema", 11),
            ("contract_version", 2),
            ("model_id", "fixed_v1"),
            ("consent_version", "beta6-consent-2026-10-22"),
        ):
            with self.subTest(key=key, value=value):
                raw = beta7_assignment_dict()
                raw[key] = value
                with self.assertRaises(AssignmentError):
                    Assignment.from_dict(raw)

    def test_rejects_unsupported_product_surface_and_protocol(self):
        for key, value in (
            ("product_id", "unsupported-watch"),
            ("surface", "rink"),
            ("protocol", "uncontrolled"),
        ):
            with self.subTest(key=key, value=value):
                raw = beta7_assignment_dict()
                raw[key] = value
                with self.assertRaises(AssignmentError):
                    Assignment.from_dict(raw)

    def test_rejects_malformed_installation_sha256(self):
        for value in ("", "abc", "g" * 64, "0" * 63):
            with self.subTest(value=value):
                raw = beta7_assignment_dict()
                raw["expected_prg_sha256"] = value
                with self.assertRaises(AssignmentError):
                    Assignment.from_dict(raw)

    def test_rejects_malformed_or_ambiguous_return_email(self):
        for value in (
            "",
            " rinklogic@example.invalid",
            "rinklogic@example.invalid ",
            "RinkLogic <rinklogic@example.invalid>",
            "one@example.invalid,two@example.invalid",
            "one@example.invalid;two@example.invalid",
            "one@@example.invalid",
            ".rinklogic@example.invalid",
            "rinklogic.@example.invalid",
            "rink..logic@example.invalid",
            "rinklogic@example",
            "rinklogic@-example.invalid",
            "rinklogic@example..invalid",
            "rinklogic@example.invalid\r\nBcc: other@example.invalid",
            f"{'a' * 65}@example.invalid",
            f"a@{'b' * 250}.invalid",
        ):
            with self.subTest(value=value):
                raw = beta7_assignment_dict()
                raw["return_email"] = value
                with self.assertRaises(AssignmentError):
                    Assignment.from_dict(raw)

    def test_accepts_plain_ascii_return_email_forms(self):
        for value in (
            "rinklogic@example.invalid",
            "beta+rink_1@example-test.invalid",
            "operator.o'hara@example.invalid",
        ):
            with self.subTest(value=value):
                raw = beta7_assignment_dict()
                raw["return_email"] = value
                self.assertEqual(Assignment.from_dict(raw).return_email, value)

    def test_rejects_filename_with_nonmatching_assignment_stem(self):
        assignment = self._valid_assignment()

        for name in (
            "TDEMO1-R1-002_2026-10-24_inline_calibration_original.zip",
            "TDEMO1-R1-001_2026-13-24_inline_calibration_original.zip",
            "TDEMO1-R1-001_2026-10-24_ice_calibration_original.zip",
            "TDEMO1-R1-001_2026-10-24_inline_smoke_original.zip",
        ):
            with self.subTest(name=name), self.assertRaises(AssignmentError):
                assignment.validate_original_name(name)

    def test_accepts_supported_original_filename_forms(self):
        assignment = self._valid_assignment()

        assignment.validate_original_name(
            "TDEMO1-R1-001_2026-10-24_inline_calibration_original.zip"
        )
        assignment.validate_original_name(
            "TDEMO1-R1-001_2026-10-24_inline_calibration_original.fit"
        )


if __name__ == "__main__":
    unittest.main()
