"""Deterministic Beta-7 calibration-reference generation."""

from dataclasses import replace
import csv
import io
import math
from pathlib import Path
import tempfile
import unittest

from analysis.calibration_report import read_calibration_manifest
from tester_assistant.assignment import Assignment
from tester_assistant.calibration_reference import (
    CalibrationReferenceError,
    build_calibration_reference,
)
from tester_assistant.diagnostics import DiagnosticReport
from tester_assistant_tests.fixtures import beta7_assignment_dict, beta7_original_name


FIELDNAMES = [
    "session_id", "repetition", "sport", "condition",
    "reference_distance_cm", "reference_pushes", "marker_status",
    "target_pace", "activation_status", "active_factor", "hrmax_bpm",
]
CONDITIONS = ["skate_only"] * 5 + ["puck_stickhandling"] * 5
PACES = ["slow", "fast", "normal", "slow", "fast"] * 2


class CalibrationReferenceTests(unittest.TestCase):
    def setUp(self):
        self.assignment = Assignment.from_dict(beta7_assignment_dict())
        self.diagnostics = DiagnosticReport(
            status="pass", codes=(), original_sha256="1" * 64,
            fit_sha256="2" * 64, original_name=beta7_original_name(),
            fit_member_name=None, schema_version=12,
            session_start="2026-10-24 18:00:00+00:00",
            duration_minutes=3.0, manual_shift_count=10,
            estimated_distance_m=200.0, personal_calibration_factor=1.12,
            heart_rate_available=True,
            expected_prg_sha256=self.assignment.expected_prg_sha256,
            surface="inline", protocol="calibration", product_id="venu2plus",
            calibration_reference_distance_cm=2000,
            calibration_skate_only_runs=5,
            calibration_stickhandling_runs=5,
        )

    def test_builds_exact_utf8_analysis_columns_and_ten_ordered_rows(self):
        data = build_calibration_reference(self.assignment, self.diagnostics)
        text = data.decode("utf-8")
        rows = list(csv.DictReader(io.StringIO(text)))
        self.assertEqual(text.splitlines()[0].split(","), FIELDNAMES)
        self.assertEqual(len(rows), 10)
        self.assertEqual([int(row["repetition"]) for row in rows], list(range(1, 11)))
        self.assertEqual([row["condition"] for row in rows], CONDITIONS)
        self.assertEqual([row["target_pace"] for row in rows], PACES)
        for row in rows:
            self.assertEqual(row["session_id"], self.diagnostics.session_start)
            self.assertEqual(row["sport"], "inline")
            self.assertEqual(row["reference_distance_cm"], "2000")
            self.assertEqual(row["reference_pushes"], "")
            self.assertEqual(row["marker_status"], "valid")
            self.assertEqual(row["activation_status"], "")
            self.assertEqual(row["active_factor"], "1.12")
            self.assertEqual(row["hrmax_bpm"], "")

    def test_generated_bytes_are_accepted_and_normalized_by_analysis_parser(self):
        data = build_calibration_reference(self.assignment, self.diagnostics)
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "reference.csv"
            path.write_bytes(data)
            rows = read_calibration_manifest(path)
        self.assertEqual(len(rows), 10)
        self.assertEqual([row["condition"] for row in rows], CONDITIONS)
        self.assertEqual([row["target_pace"] for row in rows], PACES)
        self.assertEqual({row["sport"] for row in rows}, {"inline"})
        self.assertEqual({row["reference_distance_cm"] for row in rows}, {2000})
        self.assertEqual({row["active_factor"] for row in rows}, {1.12})
        self.assertTrue(all(row["reference_pushes"] is None for row in rows))
        self.assertTrue(all(row["hrmax_bpm"] is None for row in rows))

    def test_keeps_ice_and_inline_profiles_separate(self):
        values = beta7_assignment_dict()
        values["surface"] = "ice"
        assignment = Assignment.from_dict(values)
        diagnostics = replace(self.diagnostics, surface="ice")
        rows = list(csv.DictReader(io.StringIO(
            build_calibration_reference(assignment, diagnostics).decode("utf-8"))))
        self.assertEqual({row["sport"] for row in rows}, {"ice"})

    def test_preserves_valid_binary64_factors_exactly_through_csv_roundtrip(self):
        factors = (
            1.234567890123456,
            1.000000000000001,
            math.nextafter(1.5, 0.0),
        )
        for factor in factors:
            with self.subTest(factor=factor):
                diagnostics = replace(
                    self.diagnostics, personal_calibration_factor=factor)
                rows = list(csv.DictReader(io.StringIO(
                    build_calibration_reference(
                        self.assignment, diagnostics).decode("utf-8"))))
                self.assertEqual({float(row["active_factor"]) for row in rows}, {factor})

    def test_rejects_noncalibration_nonpassing_or_unbound_diagnostics(self):
        smoke_values = beta7_assignment_dict()
        smoke_values["protocol"] = "smoke"
        smoke = Assignment.from_dict(smoke_values)
        cases = (
            (smoke, replace(self.diagnostics, protocol="smoke")),
            (self.assignment, replace(self.diagnostics, status="fail")),
            (self.assignment, replace(self.diagnostics, codes=("bad",))),
            (self.assignment, replace(self.diagnostics, surface="ice")),
            (self.assignment, replace(self.diagnostics, personal_calibration_factor=None)),
        )
        for assignment, diagnostics in cases:
            with self.subTest(assignment=assignment.protocol, diagnostics=diagnostics):
                with self.assertRaises(CalibrationReferenceError):
                    build_calibration_reference(assignment, diagnostics)


if __name__ == "__main__":
    unittest.main()
