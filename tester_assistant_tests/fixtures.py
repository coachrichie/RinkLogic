"""Synthetic assignment data shared by tester-assistant tests."""

def beta7_original_name(
    suffix: str = "fit", *, surface: str = "inline", protocol: str = "calibration",
) -> str:
    return f"TDEMO1-R1-001_2026-10-24_{surface}_{protocol}_original.{suffix}"


def beta6_original_name(suffix: str = "fit") -> str:
    """Compatibility alias while remaining suites migrate to Beta 7 naming."""
    return beta7_original_name(suffix)


def pilot_result(
    *, manual_shift_count: int = 10, personal_calibration_factor: object = 1.12,
) -> dict[str, object]:
    """A complete parser-shaped, synthetic schema-12 session."""
    manual_shifts = [
        {"at_ms": (index + 1) * 10000, "duration_seconds": 10,
         "duration_minutes": 1 / 6, "pushes": 3,
         "estimated_distance_cm": None, "estimated_distance_m": 20,
         "short_pushes": 0, "coverage_percent": 100}
        for index in range(manual_shift_count)
    ]
    return {
        "schema_version": 12,
        "session_start": "2026-10-24 18:00:00+00:00",
        "duration_ms": 180000,
        "records": [{"type": "record", "heart_rate": 142}],
        "manual_boundaries": [
            {"at_ms": (index + 1) * 10000,
             "state": "ice" if index % 2 == 0 else "bench"}
            for index in range(manual_shift_count)
        ],
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
        "personal_calibration_factor": personal_calibration_factor,
        "push_metrics": {"estimated_distance_m": 345.5,
                         "manual_shifts": manual_shifts},
        "phase_intervals": [],
    }


def beta7_assignment_dict() -> dict[str, object]:
    """Return a complete synthetic Beta-7 assignment without writing private data."""
    return {
        "contract_version": 2,
        "tester_id": "TDEMO1",
        "assignment_id": "TDEMO1-R1-001",
        "release_id": "RL-B7-20261028-3059786",
        "app_version": "0.2.0-beta.7",
        "internal_version": 7,
        "fit_schema": 12,
        "model_id": "profile_height_v1+local_known_distance_v1",
        "product_id": "venu2plus",
        "surface": "inline",
        "protocol": "calibration",
        "expected_prg_sha256": "0" * 64,
        "upload_url": "https://example.invalid/private-upload",
        "consent_version": "beta6-consent-2026-10-23",
    }


def beta6_assignment_dict() -> dict[str, object]:
    """Compatibility alias while remaining suites migrate to Beta 7 naming."""
    return beta7_assignment_dict()
