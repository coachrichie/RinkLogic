import csv
import io
import tempfile
import unittest
from contextlib import redirect_stdout
from pathlib import Path
from unittest.mock import patch

import analysis.calibration_report as calibration_report

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
            "target_pace", "reference_distance_cm", "reference_pushes",
            "marker_status", "activation_status", "active_factor", "hrmax_bpm",
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
            "condition": condition, "target_pace": "normal",
            "reference_distance_cm": str(distance), "reference_pushes": str(pushes),
            "marker_status": status, "activation_status": "activated",
            "active_factor": "1.0", "hrmax_bpm": "200",
        }

    def schema_twelve_fixture(self, estimated_m=25.0):
        paces = ["slow", "fast", "normal", "slow", "fast"] * 2
        conditions = ["skate_only"] * 5 + ["puck_stickhandling"] * 5
        rows = []
        for repetition, (condition, pace) in enumerate(zip(conditions, paces), 1):
            row = self.row(repetition, condition=condition)
            row["target_pace"] = pace
            rows.append(row)
        shifts = [{"at_ms": index * 10000, "duration_minutes": 0.2,
                   "pushes": 10, "estimated_distance_m": estimated_m,
                   "coverage_percent": 100}
                  for index in range(1, 11)]
        report = normalized_report(shifts)
        report.update({"schema_version": 12, "personal_calibration_factor": 1.0,
                       "records": []})
        return rows, shifts, report

    def test_dependency_free_robust_statistics_handle_ties_and_degenerate_inputs(self):
        self.assertAlmostEqual(calibration_report.spearman_rho(
            [1, 2, 2, 4, 5], [1, 2, 2, 4, 5]), 1.0)
        self.assertAlmostEqual(calibration_report.spearman_rho(
            [1, 2, 3, 4, 5], [5, 4, 3, 2, 1]), -1.0)
        self.assertIsNone(calibration_report.spearman_rho(
            [1, 1, 1, 1, 1], [1, 2, 3, 4, 5]))
        self.assertIsNone(calibration_report.spearman_rho(
            [1, 2, 3, 4], [1, 2, 3, 4]))
        self.assertAlmostEqual(calibration_report.theil_sen_slope(
            [1, 2, 3], [2, 4, 7]), 2.5)
        self.assertIsNone(calibration_report.theil_sen_slope(
            [1, 1, 1], [2, 3, 4]))

    def test_schema_twelve_requires_exact_ordered_ten_lap_calibration(self):
        paces = ["slow", "fast", "normal", "slow", "fast"] * 2
        conditions = ["skate_only"] * 5 + ["puck_stickhandling"] * 5
        rows = []
        for repetition, (condition, pace) in enumerate(zip(conditions, paces), 1):
            row = self.row(repetition, condition=condition)
            row["target_pace"] = pace
            rows.append(row)
        shifts = [
            {"at_ms": index * 60000, "duration_minutes": duration,
             "pushes": pushes, "estimated_distance_m": 25.0,
             "coverage_percent": 100}
            for index, (duration, pushes) in enumerate(
                zip([0.5, 0.25, 1/3, 0.5, 0.25] * 2,
                    [8, 9, 10, 11, 12] * 2), 1)
        ]
        report = normalized_report(shifts)
        report.update({"schema_version": 12, "personal_calibration_factor": 1.0,
                       "records": []})
        result = build_calibration_report_from_report(
            report, read_calibration_manifest(self.manifest(rows)))
        self.assertEqual(len(result["trials"]), 10)
        self.assertEqual(result["trials"][0]["duration_minutes"], 0.5)
        self.assertEqual(result["trials"][0]["cadence_per_min"], 16.0)
        self.assertEqual(result["trials"][0]["effective_step_length_m"], 3.125)
        self.assertEqual(result["trials"][0]["baseline_factor"], 1.0)
        self.assertIn("spearman_rho", result["groups"]["inline/skate_only"])
        self.assertIn("theil_sen_slope", result["groups"]["inline/puck_stickhandling"])
        self.assertFalse(result["factor_mismatch"])
        self.assertEqual(result["distance_model_comparison"], {
            "baseline_mae_m": 0.0, "baseline_bias_m": 0.0,
            "factored_mae_m": 0.0, "factored_bias_m": 0.0,
        })

    def test_schema_twelve_rejects_wrong_count_and_pace_order(self):
        rows = [self.row(i, condition=(
            "skate_only" if i <= 5 else "puck_stickhandling"))
                for i in range(1, 11)]
        for row in rows:
            row["target_pace"] = "slow"
        report = normalized_report([{} for _ in range(10)])
        report["schema_version"] = 12
        with self.assertRaisesRegex(ValueError, "pace order"):
            build_calibration_report_from_report(
                report, read_calibration_manifest(self.manifest(rows)))
        with self.assertRaisesRegex(ValueError, "exactly ten"):
            build_calibration_report_from_report(
                {**report, "push_metrics": {"manual_shifts": [{} for _ in range(9)]}},
                read_calibration_manifest(self.manifest(rows[:-1])))

    def test_schema_twelve_joins_discarded_retry_but_counts_ten_valid_laps(self):
        paces = ["slow", "fast", "normal", "slow", "fast"] * 2
        conditions = ["skate_only"] * 5 + ["puck_stickhandling"] * 5
        rows = []
        retry = self.row(1, condition="skate_only", status="uncertain")
        retry["target_pace"] = "slow"
        rows.append(retry)
        for lap_index, (condition, pace) in enumerate(zip(conditions, paces), 2):
            row = self.row(lap_index, condition=condition)
            row["target_pace"] = pace
            rows.append(row)
        shifts = [{"at_ms": index * 10000, "duration_minutes": 0.2,
                   "pushes": 10, "estimated_distance_m": 25.0,
                   "coverage_percent": 100}
                  for index in range(1, 12)]
        report = normalized_report(shifts)
        report.update({"schema_version": 12, "personal_calibration_factor": 1.0,
                       "records": []})
        result = build_calibration_report_from_report(
            report, read_calibration_manifest(self.manifest(rows)))
        self.assertEqual(len(result["trials"]), 11)
        self.assertFalse(result["trials"][0]["valid"])
        self.assertEqual(sum(trial["valid"] for trial in result["trials"]), 10)

    def test_missing_duration_or_pushes_are_not_imputed_for_cadence(self):
        report = normalized_report([
            {"at_ms": 1000, "duration_minutes": None, "pushes": 10,
             "estimated_distance_m": 25.0, "coverage_percent": 90},
            {"at_ms": 2000, "duration_minutes": 0.5, "pushes": None,
             "estimated_distance_m": 25.0, "coverage_percent": 90},
        ])
        result = build_calibration_report_from_report(
            report, read_calibration_manifest(self.manifest([self.row(1), self.row(2)])))
        self.assertIsNone(result["trials"][0]["cadence_per_min"])
        self.assertIsNone(result["trials"][1]["cadence_per_min"])

    def test_fit_and_reference_form_factor_mismatch_is_reported(self):
        row = self.row(1)
        row["active_factor"] = "1.1"
        report = normalized_report([])
        report["personal_calibration_factor"] = 1.2
        result = build_calibration_report_from_report(
            report, read_calibration_manifest(self.manifest([row])))
        self.assertTrue(result["factor_mismatch"])

    def test_time_above_ninety_uses_declared_hrmax_and_actual_record_intervals(self):
        row = self.row(1)
        report = normalized_report([])
        report["records"] = [
            {"timestamp": "2026-10-05T15:00:00+00:00", "heart_rate": 181},
            {"timestamp": "2026-10-05T15:00:30+00:00", "heart_rate": 170},
            {"timestamp": "2026-10-05T15:01:30+00:00", "heart_rate": 190},
        ]
        result = build_calibration_report_from_report(
            report, read_calibration_manifest(self.manifest([row])))
        self.assertEqual(result["time_above_90_hrmax_minutes"], 0.5)
        self.assertEqual(result["hrmax_source"], "tester_manifest")
        row["hrmax_bpm"] = ""
        missing = build_calibration_report_from_report(
            report, read_calibration_manifest(self.manifest([row])))
        self.assertIsNone(missing["time_above_90_hrmax_minutes"])
        self.assertIsNone(missing["hrmax_source"])

    def test_declared_hrmax_does_not_turn_missing_native_records_into_zero(self):
        result = build_calibration_report_from_report(
            normalized_report([]),
            read_calibration_manifest(self.manifest([self.row(1)])))
        self.assertIsNone(result["time_above_90_hrmax_minutes"])
        self.assertEqual(result["hrmax_source"], "tester_manifest")

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

    def test_twenty_metre_reference_error_uses_two_thousand_centimetres(self):
        manifest = read_calibration_manifest(self.manifest([self.row(1, distance=2000)]))
        result = build_calibration_report_from_report(normalized_report([
            {"at_ms": 1000, "pushes": 10, "estimated_distance_cm": 2150,
             "coverage_percent": 90},
        ]), manifest)
        trial = result["trials"][0]
        self.assertAlmostEqual(trial["reference_distance_m"], 20.0)
        self.assertAlmostEqual(trial["distance_error_m"], 1.5)

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

    def test_report_reconstructs_beta_six_factor_as_local_personal_test_only(self):
        rows, _, report = self.schema_twelve_fixture(estimated_m=20.0)
        result = build_calibration_report_from_report(
            report, read_calibration_manifest(self.manifest(rows)))
        calibration = result["personal_test_calibration"]
        self.assertEqual(calibration["factor"], 1.25)
        self.assertEqual(calibration["valid_repetition_count"], 10)
        self.assertEqual(calibration["condition_medians"], {
            "skate_only": 1.25, "puck_stickhandling": 1.25,
        })
        self.assertEqual(calibration["scope"], "local_personal_test")
        self.assertFalse(calibration["population_coefficient"])
        self.assertFalse(calibration["automatic_activation"])

    def test_schema_twelve_rechecks_runtime_run_gates(self):
        rows, shifts, report = self.schema_twelve_fixture()
        invalid_cases = [
            ("duration_minutes", 0.02, "duration_out_of_range"),
            ("duration_minutes", 0.51, "duration_out_of_range"),
            ("coverage_percent", 79, "insufficient_sensor_coverage"),
            ("pushes", 0, "invalid_push_count"),
            ("estimated_distance_m", 60.0, "factor_out_of_range"),
        ]
        for field, value, reason in invalid_cases:
            with self.subTest(field=field, value=value):
                candidate = [dict(shift) for shift in shifts]
                candidate[0][field] = value
                case_report = {**report, "push_metrics": {"manual_shifts": candidate}}
                result = build_calibration_report_from_report(
                    case_report, read_calibration_manifest(self.manifest(rows)))
                self.assertFalse(result["trials"][0]["valid"])
                self.assertEqual(result["trials"][0]["reason"], reason)
                self.assertNotEqual(result["profile_status"], "eligible")

    def test_schema_twelve_marks_fit_timebase_as_not_independently_verifiable(self):
        rows, _, report = self.schema_twelve_fixture()
        result = build_calibration_report_from_report(
            report, read_calibration_manifest(self.manifest(rows)))
        self.assertEqual(result["timebase_verification"], "not_exported_in_schema_12")

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
