"""Synthetic assignment data shared by tester-assistant tests."""


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
