import csv
import io
import tempfile
import unittest
from contextlib import redirect_stdout
from pathlib import Path
from unittest.mock import patch

from analysis.calibration_report import (
    build_calibration_report_from_report,
    read_calibration_manifest,
)
from analysis.shift_pilot import main


def normalized_report(shifts):
    return {
        "session_start": "2026-10-05T15:00:00+00:00",
        "push_metrics": {"manual_shifts": shifts},
    }


class CalibrationReportTests(unittest.TestCase):
    def manifest(self, rows):
        handle = tempfile.NamedTemporaryFile(mode="w", suffix=".csv", delete=False,
                                             newline="", encoding="utf-8")
        writer = csv.DictWriter(handle, fieldnames=[
            "session_id", "repetition", "sport", "condition",
            "reference_distance_cm", "reference_pushes", "marker_status",
        ])
        writer.writeheader()
        writer.writerows(rows)
        handle.close()
        self.addCleanup(lambda: Path(handle.name).unlink(missing_ok=True))
        return Path(handle.name)

    def row(self, repetition, condition="skate_only", distance=2500,
            pushes=10, status="valid"):
        return {
            "session_id": "2026-10-05T15:00:00+00:00",
            "repetition": str(repetition), "sport": "inline",
            "condition": condition, "reference_distance_cm": str(distance),
            "reference_pushes": str(pushes), "marker_status": status,
        }

    def test_paired_conditions_are_grouped_and_errors_are_in_metres(self):
        rows = [self.row(1), self.row(2, condition="puck_stickhandling", distance=3000)]
        path = self.manifest(rows)
        manifest = read_calibration_manifest(path)
        report = normalized_report([
            {"at_ms": 1000, "pushes": 10, "estimated_distance_cm": 2600,
             "coverage_percent": 90},
            {"at_ms": 5000, "pushes": 12, "estimated_distance_cm": 3200,
             "coverage_percent": 80},
        ])
        result = build_calibration_report_from_report(report, manifest)
        skate = result["groups"]["inline/skate_only"]
        stick = result["groups"]["inline/puck_stickhandling"]
        self.assertEqual(skate["valid_repetitions"], 1)
        self.assertAlmostEqual(skate["median_distance_error_m"], 1.0)
        self.assertEqual(stick["valid_repetitions"], 1)
        self.assertAlmostEqual(stick["median_distance_error_m"], 2.0)

    def test_unknown_distance_is_invalid_not_zero(self):
        path = self.manifest([self.row(1, distance=2500)])
        result = build_calibration_report_from_report(
            normalized_report([{"at_ms": 1000, "pushes": None,
                               "estimated_distance_cm": None,
                               "coverage_percent": None}]),
            read_calibration_manifest(path),
        )
        trial = result["trials"][0]
        self.assertFalse(trial["valid"])
        self.assertEqual(trial["reason"], "unknown_fit_value")
        self.assertIsNone(trial["distance_error_m"])

    def test_five_valid_repetitions_make_group_eligible(self):
        rows = [self.row(i) for i in range(1, 6)]
        shifts = [{"at_ms": i * 1000, "pushes": 10,
                   "estimated_distance_cm": 2500,
                   "coverage_percent": 100} for i in range(1, 6)]
        result = build_calibration_report_from_report(
            normalized_report(shifts), read_calibration_manifest(self.manifest(rows)))
        self.assertEqual(result["groups"]["inline/skate_only"]["profile_status"], "eligible")
        self.assertEqual(result["profile_status"], "provisional")

    def test_both_conditions_required_for_overall_eligibility(self):
        rows = [self.row(i) for i in range(1, 6)] + [
            self.row(i, condition="puck_stickhandling") for i in range(6, 11)
        ]
        shifts = [{"at_ms": i * 1000, "pushes": 10,
                   "estimated_distance_cm": 2500,
                   "coverage_percent": 90} for i in range(1, 11)]
        result = build_calibration_report_from_report(
            normalized_report(shifts), read_calibration_manifest(self.manifest(rows)))
        self.assertEqual(result["profile_status"], "eligible")

    def test_uncertain_marker_does_not_count_toward_threshold(self):
        rows = [self.row(1, status="uncertain")]
        result = build_calibration_report_from_report(
            normalized_report([{"at_ms": 1000, "pushes": 10,
                               "estimated_distance_cm": 2500,
                               "coverage_percent": 100}]),
            read_calibration_manifest(self.manifest(rows)))
        self.assertFalse(result["trials"][0]["valid"])
        self.assertEqual(result["trials"][0]["reason"], "uncertain_marker")

    def test_blank_independent_push_count_keeps_distance_but_not_push_error(self):
        manifest = read_calibration_manifest(self.manifest([self.row(1, pushes="")]))
        result = build_calibration_report_from_report(normalized_report([
            {"at_ms": 1000, "pushes": 12, "estimated_distance_cm": 2400,
             "coverage_percent": 90},
        ]), manifest)
        self.assertIsNone(manifest[0]["reference_pushes"])
        self.assertTrue(result["trials"][0]["valid"])
        self.assertAlmostEqual(result["trials"][0]["distance_error_m"], -1.0)
        self.assertIsNone(result["trials"][0]["push_error"])
        self.assertIsNone(result["groups"]["inline/skate_only"]["median_push_error"])

    def test_push_summary_uses_only_independent_reference_counts(self):
        manifest = read_calibration_manifest(self.manifest([
            self.row(1, pushes=""), self.row(2, pushes=10),
        ]))
        result = build_calibration_report_from_report(normalized_report([
            {"at_ms": 1000, "pushes": 12, "estimated_distance_cm": 2500,
             "coverage_percent": 90},
            {"at_ms": 2000, "pushes": 12, "estimated_distance_cm": 2500,
             "coverage_percent": 90},
        ]), manifest)
        self.assertEqual(result["groups"]["inline/skate_only"]["median_push_error"], 2)

    def test_zero_or_out_of_range_coverage_is_invalid(self):
        for coverage in (0, -1, 101):
            with self.subTest(coverage=coverage):
                result = build_calibration_report_from_report(normalized_report([
                    {"at_ms": 1000, "pushes": 10, "estimated_distance_cm": 2500,
                     "coverage_percent": coverage},
                ]), read_calibration_manifest(self.manifest([self.row(1)])))
                self.assertFalse(result["trials"][0]["valid"])
                self.assertIsNone(result["trials"][0]["distance_error_m"])
                self.assertEqual(result["groups"]["inline/skate_only"]["valid_repetitions"], 0)

    def test_manifest_session_must_match_fit_session(self):
        manifest = read_calibration_manifest(self.manifest([self.row(1)]))
        with self.assertRaisesRegex(ValueError, "session"):
            build_calibration_report_from_report(
                {**normalized_report([]), "session_start": "2026-10-06 15:00:00+00:00"},
                manifest,
            )

    def test_equivalent_session_timestamps_match(self):
        manifest = read_calibration_manifest(self.manifest([self.row(1)]))
        result = build_calibration_report_from_report(
            {**normalized_report([]), "session_start": "2026-10-05 17:00:00+02:00"},
            manifest,
        )
        self.assertEqual(result["trials"][0]["reason"], "missing_fit_lap")

    def test_missing_fit_session_does_not_join(self):
        manifest = read_calibration_manifest(self.manifest([self.row(1)]))
        with self.assertRaisesRegex(ValueError, "session"):
            build_calibration_report_from_report(
                {**normalized_report([]), "session_start": None}, manifest,
            )

    def test_cli_accepts_calibration_manifest(self):
        output = io.StringIO()
        with patch("analysis.shift_pilot.build_calibration_report",
                   return_value={"profile_status": "ineligible"}), \
             redirect_stdout(output):
            code = main(["activity.fit", "--calibration-manifest", "manifest.csv"])
        self.assertEqual(code, 0)
        self.assertIn("ineligible", output.getvalue())


if __name__ == "__main__":
    unittest.main()
