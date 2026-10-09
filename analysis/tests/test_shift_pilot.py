import unittest
from unittest.mock import patch

import fitdecode

from analysis.shift_pilot import load_pilot_fit, normalize_messages, score_boundaries


class PilotReportTests(unittest.TestCase):
    def test_schema_four_with_or_without_summary_fields_remains_readable(self):
        for extra in ({}, {"shift_count": 4, "time_on_ice": 120,
                           "bench_time": 80, "average_shift_duration": 30,
                           "average_shift_heart_rate": 155}):
            report = normalize_messages([
                {"type": "session", "shadow_schema_version": 4,
                 "total_elapsed_time": 200, **extra},
                {"type": "lap", "manual_boundary_ms": 1000,
                 "manual_boundary_state": 1},
            ])
            self.assertEqual(report["schema_version"], 4)
            self.assertIsNone(report["push_metrics"]["total_pushes"])
            self.assertEqual(report["push_metrics"]["manual_shifts"], [])

    def test_schema_five_remains_readable_without_new_fields(self):
        report = normalize_messages([
            {"type": "session", "shadow_schema_version": 5},
            {"type": "record", "shadow_schema_version": 5,
             "motion_mg": 110},
        ])
        self.assertEqual(report["schema_version"], 5)
        self.assertIsNone(report["push_metrics"]["estimated_distance_cm"])

    def test_schema_six_uses_cumulative_session_totals_despite_skipped_records(self):
        start = "2026-09-28T12:00:00+00:00"
        report = normalize_messages([
            {"type": "session", "shadow_schema_version": 6,
             "start_time": start, "total_elapsed_time": 5,
             "push_count_total": 6, "estimated_distance_cm_total": 950,
             "motion_coverage_percent": 72, "short_push_count_total": 4},
            {"type": "record", "shadow_schema_version": 6,
             "timestamp": start, "sample_seq": 1, "sample_at_ms": 0,
             "motion_mg": 200, "push_count_total": 1,
             "estimated_distance_cm_total": 125},
            {"type": "record", "shadow_schema_version": 6,
             "timestamp": "2026-09-28T12:00:04+00:00",
             "sample_seq": 5, "sample_at_ms": 4000,
             "motion_mg": 220, "push_count_total": 6,
             "estimated_distance_cm_total": 950},
            {"type": "lap", "manual_boundary_ms": 0,
             "manual_boundary_state": 1},
            {"type": "lap", "manual_boundary_ms": 5000,
             "manual_boundary_state": 2, "shift_push_count": 6,
             "shift_estimated_distance_cm": 950,
             "shift_short_push_count": 4,
             "shift_motion_coverage_percent": 72},
        ])
        self.assertEqual(report["schema_version"], 6)
        self.assertEqual(report["fit_write_gap_seconds"], 3)
        self.assertEqual(report["push_metrics"]["total_pushes"], 6)
        self.assertEqual(report["push_metrics"]["estimated_distance_cm"], 950)
        self.assertEqual(report["push_metrics"]["short_pushes"], 4)
        self.assertEqual(report["push_metrics"]["manual_shifts"][0]["pushes"], 6)

    def test_missing_gyro_and_coverage_remain_unknown(self):
        report = normalize_messages([
            {"type": "session", "shadow_schema_version": 6,
             "motion_coverage_percent": 255},
            {"type": "record", "shadow_schema_version": 6,
             "rotation_dps": 65535, "push_cadence_per_min": 65535},
            {"type": "lap", "manual_boundary_ms": 1000,
             "manual_boundary_state": 2,
             "shift_motion_coverage_percent": 255},
        ])
        self.assertIsNone(report["push_metrics"]["coverage_percent"])
        self.assertIsNone(report["push_metrics"]["manual_shifts"][0]["coverage_percent"])
        self.assertIsNone(report["push_metrics"]["cadence_latest_per_min"])

    def test_latest_invalid_cadence_does_not_reuse_prior_reading(self):
        report = normalize_messages([
            {"type": "session", "shadow_schema_version": 6},
            {"type": "record", "shadow_schema_version": 6,
             "push_cadence_per_min": 42},
            {"type": "record", "shadow_schema_version": 6,
             "push_cadence_per_min": 65535},
        ])
        self.assertIsNone(report["push_metrics"]["cadence_latest_per_min"])

    def test_auto_lap_cannot_be_mistaken_for_manual_push_shift(self):
        report = normalize_messages([
            {"type": "session", "shadow_schema_version": 6},
            {"type": "lap", "auto_boundary_ms": 2000,
             "auto_boundary_state": 2, "shift_push_count": 0,
             "shift_estimated_distance_cm": 0},
            {"type": "lap", "manual_boundary_ms": 3000,
             "manual_boundary_state": 2, "shift_push_count": 3,
             "shift_estimated_distance_cm": 375},
        ])
        self.assertEqual(len(report["proposals"]), 1)
        self.assertEqual(len(report["push_metrics"]["manual_shifts"]), 1)
        self.assertEqual(report["push_metrics"]["manual_shifts"][0]["pushes"], 3)

    def test_crc_exception_is_not_swallowed(self):
        class BadCrcReader:
            def __init__(self, path, check_crc, error_handling):
                self.assert_crc = check_crc

            def __enter__(self):
                self_case.assertEqual(self.assert_crc, fitdecode.CrcCheck.RAISE)
                raise ValueError("CRC mismatch")

            def __exit__(self, exc_type, exc_value, traceback):
                return False

        self_case = self
        with patch("fitdecode.FitReader", BadCrcReader):
            with self.assertRaisesRegex(ValueError, "CRC mismatch"):
                load_pilot_fit("broken.fit")

    def test_old_activity_is_not_scored_as_zero(self):
        with self.assertRaisesRegex(ValueError, "schema 4"):
            normalize_messages([{"type": "record", "heart_rate": 145}])

    def test_one_proposal_cannot_match_two_references(self):
        score = score_boundaries(
            [{"at_ms": 10000, "state": "ice"},
             {"at_ms": 12000, "state": "bench"}],
            [{"at_ms": 11000, "state": "ice"}], 3600000)
        self.assertEqual(score["matched"], 1)
        self.assertEqual(score["recall"], 0.5)

    def test_opposite_direction_never_matches(self):
        score = score_boundaries(
            [{"at_ms": 10000, "state": "ice"}],
            [{"at_ms": 10000, "state": "bench"}], 3600000)
        self.assertEqual(score["matched"], 0)

    def test_unmatched_bench_inside_manual_shift_is_false_split(self):
        score = score_boundaries(
            [{"at_ms": 10000, "state": "ice"},
             {"at_ms": 50000, "state": "bench"}],
            [{"at_ms": 10000, "state": "ice"},
             {"at_ms": 30000, "state": "bench"},
             {"at_ms": 50000, "state": "bench"}], 3600000)
        self.assertEqual(score["false_splits_per_hour"], 1.0)

    def test_missing_sensor_rows_are_not_validated_as_bench(self):
        report = normalize_messages([
            {"type": "session", "shadow_schema_version": 4},
            {"type": "lap", "manual_boundary_ms": 1000,
             "manual_boundary_state": 1},
            {"type": "record", "shadow_schema_version": 4,
             "auto_state": 3, "motion_mg": None},
        ])
        self.assertEqual(report["valid_motion_seconds"], 0)

    def test_proposals_require_durable_auto_laps_not_transient_bits(self):
        report = normalize_messages([
            {"type": "session", "shadow_schema_version": 4,
             "start_time": "2026-09-23T10:00:00+00:00"},
            {"type": "lap", "manual_boundary_ms": 1000,
             "manual_boundary_state": 1},
            {"type": "lap", "auto_boundary_ms": 900,
             "auto_boundary_state": 1},
            {"type": "record", "shadow_schema_version": 4,
             "timestamp": "2026-09-23T10:00:01+00:00",
             "auto_state": 1, "event_bits": 4, "motion_mg": 220},
            {"type": "record", "shadow_schema_version": 4,
             "timestamp": "2026-09-23T10:00:02+00:00",
             "auto_state": 1, "event_bits": 4, "motion_mg": 220},
        ])
        self.assertEqual(report["proposals"], [{"at_ms": 900, "state": "ice"}])

    def test_rapid_manual_bits_cannot_appear_as_auto_proposal(self):
        report = normalize_messages([
            {"type": "session", "shadow_schema_version": 4,
             "start_time": "2026-09-23T10:00:00+00:00"},
            {"type": "record", "shadow_schema_version": 4,
             "timestamp": "2026-09-23T10:00:02+00:00",
             "event_bits": 4, "motion_mg": 200},
        ])
        self.assertEqual(report["proposals"], [])

    def test_stale_samples_and_unobserved_session_are_not_fresh_motion(self):
        start = "2026-09-23T10:00:00+00:00"
        empty = normalize_messages([{"type": "session", "shadow_schema_version": 4,
                                    "start_time": start, "total_elapsed_time": 60}])
        self.assertEqual(empty["fit_write_gap_seconds"], 60)
        self.assertEqual(empty["valid_motion_seconds"], 0)
        self.assertFalse(empty["evidence_complete"])
        stale = normalize_messages([
            {"type": "session", "shadow_schema_version": 4,
             "start_time": start, "total_elapsed_time": 3},
            {"type": "record", "shadow_schema_version": 4,
             "timestamp": start, "sample_seq": 1, "sample_at_ms": 0,
             "motion_mg": 200},
            {"type": "record", "shadow_schema_version": 4,
             "timestamp": "2026-09-23T10:00:02+00:00",
             "sample_seq": 1, "sample_at_ms": 0, "motion_mg": 200},
        ])
        self.assertEqual(stale["valid_motion_seconds"], 1)
        self.assertGreaterEqual(stale["fit_write_gap_seconds"], 2)
        self.assertFalse(stale["evidence_complete"])

    def test_partial_final_second_is_not_a_whole_missing_second(self):
        report = normalize_messages([
            {"type": "session", "shadow_schema_version": 4,
             "start_time": "2026-09-24T08:55:00+00:00",
             "total_elapsed_time": 2.5},
            {"type": "record", "shadow_schema_version": 4,
             "timestamp": "2026-09-24T08:55:00+00:00",
             "sample_seq": 1, "sample_at_ms": 0, "motion_mg": 200},
            {"type": "record", "shadow_schema_version": 4,
             "timestamp": "2026-09-24T08:55:01+00:00",
             "sample_seq": 2, "sample_at_ms": 1000, "motion_mg": 200},
        ])
        self.assertEqual(report["fit_write_gap_seconds"], 0)
        self.assertTrue(report["evidence_complete"])

    def test_sample_timing_jitter_does_not_create_a_fit_gap(self):
        report = normalize_messages([
            {"type": "session", "shadow_schema_version": 4,
             "start_time": "2026-09-26T12:00:00+00:00",
             "total_elapsed_time": 3},
            {"type": "record", "shadow_schema_version": 4,
             "timestamp": "2026-09-26T12:00:01+00:00",
             "sample_seq": 1, "sample_at_ms": 900, "motion_mg": 200},
            {"type": "record", "shadow_schema_version": 4,
             "timestamp": "2026-09-26T12:00:02+00:00",
             "sample_seq": 2, "sample_at_ms": 2100, "motion_mg": 200},
        ])
        self.assertEqual(report["fit_write_gap_seconds"], 0)
        self.assertTrue(report["evidence_complete"])

    def test_missing_sample_sequence_counts_as_fit_gap_even_with_close_times(self):
        report = normalize_messages([
            {"type": "session", "shadow_schema_version": 4,
             "start_time": "2026-09-26T12:00:00+00:00",
             "total_elapsed_time": 2},
            {"type": "record", "shadow_schema_version": 4,
             "timestamp": "2026-09-26T12:00:00+00:00",
             "sample_seq": 1, "sample_at_ms": 0, "motion_mg": 200},
            {"type": "record", "shadow_schema_version": 4,
             "timestamp": "2026-09-26T12:00:01+00:00",
             "sample_seq": 3, "sample_at_ms": 1100, "motion_mg": 200},
        ])
        self.assertEqual(report["fit_write_gap_seconds"], 1)
        self.assertFalse(report["evidence_complete"])

    def test_missing_manual_laps_block_scoring(self):
        report = normalize_messages([
            {"type": "session", "shadow_schema_version": 4},
            {"type": "record", "shadow_schema_version": 4,
             "motion_mg": 220},
        ])
        self.assertEqual(report["manual_boundaries"], [])


if __name__ == "__main__":
    unittest.main()
