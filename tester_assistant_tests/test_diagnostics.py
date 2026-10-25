"""Original-export inspection, with synthetic content and a parser boundary."""

import hashlib
import io
import stat
import tempfile
import unittest
import zipfile
from pathlib import Path
from unittest.mock import patch

from tester_assistant.assignment import Assignment
from tester_assistant.diagnostics import DiagnosticError, inspect_original
from tester_assistant_tests.fixtures import (
    beta6_assignment_dict,
    beta6_original_name,
    pilot_result,
)


FIT_BYTES = b"synthetic fit bytes\x00\x01"


def zip_bytes(members: list[tuple[str | zipfile.ZipInfo, bytes]]) -> bytes:
    output = io.BytesIO()
    with zipfile.ZipFile(output, "w") as archive:
        for name, data in members:
            archive.writestr(name, data)
    return output.getvalue()


class DiagnosticsTests(unittest.TestCase):
    def setUp(self):
        self.assignment = Assignment.from_dict(beta6_assignment_dict())
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.folder = Path(self.temp.name)

    def original(self, data: bytes, suffix: str = "fit") -> Path:
        path = self.folder / beta6_original_name(suffix)
        path.write_bytes(data)
        return path

    def assert_code(self, path: Path, code: str):
        with self.assertRaises(DiagnosticError) as raised:
            inspect_original(path, self.assignment)
        self.assertEqual(raised.exception.code, code)

    def test_direct_fit_returns_only_safe_aggregate_summary(self):
        path = self.original(FIT_BYTES)
        with patch("tester_assistant.diagnostics.load_pilot_fit", return_value=pilot_result()):
            report = inspect_original(path, self.assignment)

        self.assertEqual(report.status, "pass")
        self.assertEqual(report.codes, ())
        self.assertEqual(report.original_sha256, hashlib.sha256(FIT_BYTES).hexdigest())
        self.assertEqual(report.fit_sha256, report.original_sha256)
        self.assertEqual(report.original_name, path.name)
        self.assertIsNone(report.fit_member_name)
        self.assertEqual(report.schema_version, 12)
        self.assertEqual(report.session_start, "2026-10-24 18:00:00+00:00")
        self.assertEqual(report.duration_minutes, 3)
        self.assertEqual(report.manual_shift_count, 1)
        self.assertEqual(report.estimated_distance_m, 345.5)
        self.assertEqual(report.personal_calibration_factor, 1.12)
        self.assertTrue(report.heart_rate_available)
        summary = report.safe_summary()
        self.assertEqual(report.expected_prg_sha256, "0" * 64)
        self.assertNotIn("expected_prg_sha256", summary)
        self.assertEqual(summary["manual_shift_count"], 1)
        self.assertNotIn("original_name", summary)
        self.assertNotIn("fit_member_name", summary)
        self.assertNotIn("original_sha256", summary)
        self.assertNotIn("fit_sha256", summary)
        self.assertNotIn("session_start", summary)
        self.assertNotIn("records", summary)
        self.assertNotIn("raw_session", summary)
        self.assertNotIn("manual_boundaries", summary)
        self.assertNotIn("upload_url", summary)

    def test_zip_summary_matches_direct_fit_and_keeps_distinct_hashes(self):
        path = self.original(zip_bytes([("Activity.fit", FIT_BYTES)]), "zip")
        seen = []
        def read_temporary_fit(fit_path):
            seen.append(fit_path.read_bytes())
            return pilot_result()
        with patch("tester_assistant.diagnostics.load_pilot_fit", side_effect=read_temporary_fit) as parser:
            report = inspect_original(path, self.assignment)
            self.assertFalse(parser.call_args.args[0].exists())

        self.assertEqual(seen, [FIT_BYTES])
        self.assertEqual(report.fit_member_name, "Activity.fit")
        self.assertEqual(report.original_sha256, hashlib.sha256(path.read_bytes()).hexdigest())
        self.assertEqual(report.fit_sha256, hashlib.sha256(FIT_BYTES).hexdigest())
        self.assertNotEqual(report.original_sha256, report.fit_sha256)
        direct = self.original(FIT_BYTES)
        with patch("tester_assistant.diagnostics.load_pilot_fit", return_value=pilot_result()):
            direct_summary = inspect_original(direct, self.assignment).safe_summary()
        self.assertEqual(report.safe_summary(), direct_summary)

    def test_wrong_filename_fails_before_file_access_or_parsing(self):
        path = self.folder / "TOTHER-R1-001_2026-10-24_inline_calibration_original.fit"
        with patch("tester_assistant.diagnostics.load_pilot_fit") as parser:
            self.assert_code(path, "original_name_mismatch")
            parser.assert_not_called()

    def test_empty_and_unsupported_input_are_rejected(self):
        self.assert_code(self.original(b""), "empty_input")
        path = self.folder / beta6_original_name("exe")
        path.write_bytes(FIT_BYTES)
        self.assert_code(path, "unsupported_extension")

    def test_direct_fit_uses_the_same_64_mib_limit_as_zip_fit(self):
        path = self.original(b"x")
        with path.open("r+b") as output:
            output.truncate(64 * 1024 * 1024)
        with patch("tester_assistant.diagnostics.load_pilot_fit", return_value=pilot_result()):
            self.assertEqual(inspect_original(path, self.assignment).schema_version, 12)
        with path.open("r+b") as output:
            output.truncate(64 * 1024 * 1024 + 1)
        with patch("tester_assistant.diagnostics.load_pilot_fit") as parser:
            self.assert_code(path, "fit_too_large")
            parser.assert_not_called()

    def test_corrupt_zip_and_bad_member_sets_are_rejected(self):
        cases = (
            (b"not a zip", "corrupt_zip"),
            (zip_bytes([("notes.txt", b"text")]), "zip_no_fit"),
            (zip_bytes([("one.fit", FIT_BYTES), ("two.fit", FIT_BYTES)]), "zip_multiple_fit"),
            (zip_bytes([("activity.fit", FIT_BYTES), ("nested.zip", b"zip")]), "zip_nested_archive"),
            (zip_bytes([("activity.fit", FIT_BYTES), ("setup.exe", b"exe")]), "zip_executable_member"),
            (zip_bytes([("activity.fit", FIT_BYTES), ("run.bat", b"bat")]), "zip_executable_member"),
            (zip_bytes([("activity.fit", FIT_BYTES), ("notes.txt", b"text")]), "zip_unexpected_member"),
            (zip_bytes([("/activity.fit", FIT_BYTES)]), "zip_unsafe_member_name"),
            (zip_bytes([("../activity.fit", FIT_BYTES)]), "zip_unsafe_member_name"),
        )
        for data, code in cases:
            with self.subTest(code=code):
                self.assert_code(self.original(data, "zip"), code)

    def test_unsupported_zip_compression_has_stable_code(self):
        data = bytearray(zip_bytes([("activity.fit", FIT_BYTES)]))
        local_header = data.index(b"PK\x03\x04")
        central_header = data.index(b"PK\x01\x02")
        data[local_header + 8:local_header + 10] = (99).to_bytes(2, "little")
        data[central_header + 10:central_header + 12] = (99).to_bytes(2, "little")
        self.assert_code(self.original(bytes(data), "zip"), "unsupported_zip_compression")

    def test_safe_summary_excludes_installation_hash(self):
        path = self.original(FIT_BYTES)
        with patch("tester_assistant.diagnostics.load_pilot_fit", return_value=pilot_result()):
            report = inspect_original(path, self.assignment)
        self.assertEqual(report.expected_prg_sha256, "0" * 64)
        self.assertNotIn("expected_prg_sha256", report.safe_summary())

    def test_zip_member_is_read_without_extracting(self):
        path = self.original(zip_bytes([("activity.fit", FIT_BYTES)]), "zip")
        seen = []
        def read_temporary_fit(fit_path):
            seen.append(fit_path.read_bytes())
            return pilot_result()
        with patch.object(zipfile.ZipFile, "extract", side_effect=AssertionError("extract called")), \
             patch.object(zipfile.ZipFile, "extractall", side_effect=AssertionError("extractall called")), \
             patch("tester_assistant.diagnostics.load_pilot_fit", side_effect=read_temporary_fit) as parser:
            inspect_original(path, self.assignment)
            self.assertFalse(parser.call_args.args[0].exists())
        self.assertEqual(seen, [FIT_BYTES])

    def test_zip_rejects_nonregular_member_even_when_fit_is_present(self):
        symlink = zipfile.ZipInfo("link/")
        symlink.create_system = 3
        symlink.external_attr = (stat.S_IFLNK | 0o777) << 16
        path = self.original(zip_bytes([(symlink, b"elsewhere"),
                                        ("activity.fit", FIT_BYTES)]), "zip")
        self.assert_code(path, "zip_unsafe_member_type")

    def test_parser_error_has_stable_non_sensitive_code(self):
        path = self.original(FIT_BYTES)
        with patch("tester_assistant.diagnostics.load_pilot_fit", side_effect=ValueError("private /path/secret.fit")):
            with self.assertRaises(DiagnosticError) as raised:
                inspect_original(path, self.assignment)
        self.assertEqual(raised.exception.code, "parser_error")
        self.assertNotIn("secret", str(raised.exception))
        self.assertIsNone(raised.exception.__cause__)
        self.assertTrue(raised.exception.__suppress_context__)

    def test_rejects_wrong_schema_and_invalid_aggregate_fields(self):
        changes = (
            ({"schema_version": 11}, "schema_mismatch"),
            ({"session_start": None}, "missing_session_start"),
            ({"duration_ms": -1}, "invalid_duration"),
            ({"duration_ms": float("nan")}, "invalid_duration"),
            ({"duration_ms": 10 ** 1000}, "invalid_duration"),
            ({"personal_calibration_factor": float("inf")}, "invalid_metric"),
            ({"personal_calibration_factor": 10 ** 1000}, "invalid_metric"),
            ({"push_metrics": {"estimated_distance_m": float("nan"), "manual_shifts": []}}, "invalid_metric"),
        )
        path = self.original(FIT_BYTES)
        for overrides, code in changes:
            with self.subTest(overrides=overrides):
                result = pilot_result()
                result.update(overrides)
                with patch("tester_assistant.diagnostics.load_pilot_fit", return_value=result):
                    self.assert_code(path, code)


if __name__ == "__main__":
    unittest.main()
