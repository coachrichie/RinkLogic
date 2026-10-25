"""Synthetic assignment data shared by tester-assistant tests."""

def beta6_original_name(suffix: str = "fit") -> str:
    return f"TDEMO1-R1-001_2026-10-24_inline_calibration_original.{suffix}"


def pilot_result() -> dict[str, object]:
    """A complete parser-shaped, synthetic schema-12 session."""
    return {
        "schema_version": 12,
        "session_start": "2026-10-24 18:00:00+00:00",
        "duration_ms": 180000,
        "records": [{"type": "record", "heart_rate": 142}],
        "manual_boundaries": [{"at_ms": 0, "state": "ice"}],
        "proposals": [],
        "valid_motion_seconds": 0,
        "missing_sensor_seconds": 0,
        "uncertain_seconds": 0,
        "fit_write_gap_seconds": 0,
        "evidence_complete": False,
        "proposal_timestamp_resolution_ms": 1,
        "time_metrics_minutes": {},
        "raw_time_fields": {},
        "raw_session": {"type": "session"},
        "personal_calibration_factor": 1.12,
        "push_metrics": {"estimated_distance_m": 345.5, "manual_shifts": [
            {"at_ms": 60000, "duration_seconds": 60, "duration_minutes": 1,
             "pushes": 3, "estimated_distance_cm": None,
             "estimated_distance_m": 100, "short_pushes": 0,
             "coverage_percent": 100},
        ]},
        "phase_intervals": [],
    }


def beta6_assignment_dict() -> dict[str, object]:
    """Return a complete synthetic Beta-6 assignment without writing private data."""
    return {
        "contract_version": 1,
        "tester_id": "TDEMO1",
        "assignment_id": "TDEMO1-R1-001",
        "release_id": "RL-B6-20261023-43694FC",
        "app_version": "0.2.0-beta.6",
        "internal_version": 6,
        "fit_schema": 12,
        "model_id": "profile_height_v1+local_known_distance_v1",
        "product_id": "venu2plus",
        "surface": "inline",
        "protocol": "calibration",
        "expected_prg_sha256": "0" * 64,
        "upload_url": "https://example.invalid/private-upload",
        "consent_version": "beta6-consent-2026-10-23",
    }
