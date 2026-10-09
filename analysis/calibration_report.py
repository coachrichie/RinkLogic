"""Condition-aware local report for ShiftSense 20–30 m calibration trials."""

from __future__ import annotations

import csv
from datetime import datetime
from math import ceil
from pathlib import Path
from statistics import mean, median, stdev


FIELDS = {
    "session_id", "repetition", "sport", "condition",
    "reference_distance_cm", "reference_pushes", "marker_status",
}
SPORTS = {"ice", "inline"}
CONDITIONS = {"skate_only", "puck_stickhandling"}
MARKER_STATUSES = {"valid", "uncertain", "missing", "duplicate", "delayed"}


def read_calibration_manifest(path: str | Path) -> list[dict]:
    """Read and validate user-owned calibration metadata; keep units explicit."""
    with Path(path).open(newline="", encoding="utf-8-sig") as stream:
        reader = csv.DictReader(stream)
        if not FIELDS.issubset(reader.fieldnames or set()):
            missing = sorted(FIELDS - set(reader.fieldnames or set()))
            raise ValueError("Calibration manifest missing columns: " + ", ".join(missing))
        rows = []
        seen = set()
        for line, raw in enumerate(reader, start=2):
            try:
                row = {
                    "session_id": raw["session_id"].strip(),
                    "repetition": int(raw["repetition"]),
                    "sport": raw["sport"].strip().lower(),
                    "condition": raw["condition"].strip().lower(),
                    "reference_distance_cm": int(raw["reference_distance_cm"]),
                    "reference_pushes": (
                        int(raw["reference_pushes"])
                        if raw["reference_pushes"] and raw["reference_pushes"].strip()
                        else None
                    ),
                    "marker_status": raw["marker_status"].strip().lower(),
                }
            except (TypeError, ValueError) as exc:
                raise ValueError(f"Invalid calibration manifest line {line}") from exc
            if not row["session_id"] or row["repetition"] <= 0:
                raise ValueError(f"Invalid session/repetition on line {line}")
            if row["sport"] not in SPORTS or row["condition"] not in CONDITIONS:
                raise ValueError(f"Invalid sport or condition on line {line}")
            if (row["reference_distance_cm"] <= 0 or
                    (row["reference_pushes"] is not None and row["reference_pushes"] < 0)):
                raise ValueError(f"Invalid reference values on line {line}")
            if row["marker_status"] not in MARKER_STATUSES:
                raise ValueError(f"Invalid marker status on line {line}")
            key = (row["session_id"], row["repetition"])
            if key in seen:
                raise ValueError(f"Duplicate session/repetition on line {line}")
            seen.add(key)
            rows.append(row)
    return rows


def _p95(values):
    if not values:
        return None
    return sorted(values)[max(0, ceil(len(values) * 0.95) - 1)]


def _group_summary(trials):
    valid = [trial for trial in trials if trial["valid"]]
    errors = [trial["distance_error_m"] for trial in valid]
    absolute = [abs(error) for error in errors]
    percent = [trial["distance_error_percent"] for trial in valid]
    push_errors = [trial["push_error"] for trial in valid
                   if trial["push_error"] is not None]
    status = "eligible" if len(valid) >= 5 else ("provisional" if valid else "ineligible")
    return {
        "profile_status": status,
        "valid_repetitions": len(valid),
        "invalid_repetitions": len(trials) - len(valid),
        "median_distance_error_m": median(errors) if errors else None,
        "mean_distance_error_m": mean(errors) if errors else None,
        "stdev_distance_error_m": stdev(errors) if len(errors) > 1 else None,
        "p95_absolute_distance_error_m": _p95(absolute),
        "median_distance_error_percent": median(percent) if percent else None,
        "median_push_error": median(push_errors) if push_errors else None,
        "mean_coverage_percent": mean(
            [trial["coverage_percent"] for trial in valid]
        ) if valid else None,
    }


def build_calibration_report_from_report(report: dict, manifest: list[dict]) -> dict:
    """Join local manifest rows to ordered manual FIT shift metrics."""
    fit_session = report.get("session_start")
    if manifest:
        try:
            fit_start = datetime.fromisoformat(fit_session)
            if fit_start.tzinfo is None:
                raise ValueError("timezone missing")
            for row in manifest:
                reference_start = datetime.fromisoformat(row["session_id"])
                if reference_start.tzinfo is None or reference_start != fit_start:
                    raise ValueError("Calibration session does not match FIT session")
        except (TypeError, ValueError) as exc:
            raise ValueError("Calibration session does not match FIT session") from exc
    shifts = report.get("push_metrics", {}).get("manual_shifts", [])
    trials = []
    for row in manifest:
        index = row["repetition"] - 1
        shift = shifts[index] if 0 <= index < len(shifts) else None
        base = {
            "session_id": row["session_id"], "repetition": row["repetition"],
            "sport": row["sport"], "condition": row["condition"],
            "reference_distance_m": row["reference_distance_cm"] / 100.0,
            "reference_pushes": row["reference_pushes"],
            "coverage_percent": None, "valid": False,
            "distance_error_m": None, "distance_error_percent": None,
            "push_error": None, "reason": None,
        }
        if row["marker_status"] != "valid":
            base["reason"] = "uncertain_marker"
        elif shift is None:
            base["reason"] = "missing_fit_lap"
        elif shift.get("estimated_distance_cm") is None or shift.get("pushes") is None:
            base["reason"] = "unknown_fit_value"
        elif shift.get("coverage_percent") is None:
            base["reason"] = "unknown_sensor_coverage"
        elif not 0 < shift["coverage_percent"] <= 100:
            base["coverage_percent"] = shift["coverage_percent"]
            base["reason"] = "invalid_sensor_coverage"
        else:
            estimated_m = shift["estimated_distance_cm"] / 100.0
            base["coverage_percent"] = shift["coverage_percent"]
            base["distance_error_m"] = estimated_m - base["reference_distance_m"]
            base["distance_error_percent"] = (
                base["distance_error_m"] / base["reference_distance_m"] * 100.0
            )
            if row["reference_pushes"] is not None:
                base["push_error"] = shift["pushes"] - row["reference_pushes"]
            base["valid"] = True
        trials.append(base)

    groups = {}
    for trial in trials:
        key = f"{trial['sport']}/{trial['condition']}"
        groups.setdefault(key, []).append(trial)
    summaries = {key: _group_summary(value) for key, value in groups.items()}
    valid_count = sum(item["valid_repetitions"] for item in summaries.values())
    sports = {trial["sport"] for trial in trials}
    if sports and all(
        all(summaries.get(f"{sport}/{condition}", {}).get("profile_status") == "eligible"
            for condition in CONDITIONS)
        for sport in sports
    ):
        profile_status = "eligible"
    elif valid_count:
        profile_status = "provisional"
    else:
        profile_status = "ineligible"
    return {
        "profile_status": profile_status,
        "session_start": report.get("session_start"),
        "trials": trials,
        "groups": summaries,
    }


def build_calibration_report(fit_path: str | Path, manifest_path: str | Path) -> dict:
    from analysis.shift_pilot import load_pilot_fit

    return build_calibration_report_from_report(
        load_pilot_fit(fit_path), read_calibration_manifest(manifest_path)
    )
