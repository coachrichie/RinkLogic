"""Condition-aware local report for ShiftSense 20–30 m calibration trials."""

from __future__ import annotations

import csv
from datetime import datetime
from decimal import Decimal, ROUND_HALF_UP
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
PACES = {"slow", "normal", "fast"}
PACE_ORDER = ["slow", "fast", "normal", "slow", "fast"] * 2
CONDITION_ORDER = ["skate_only"] * 5 + ["puck_stickhandling"] * 5


def _round_four_half_up(value):
    return float(Decimal(str(value)).quantize(Decimal("0.0001"), rounding=ROUND_HALF_UP))


def _relative_mad(values):
    if not values:
        return None
    center = median(values)
    if center <= 0:
        return None
    return median(abs(value - center) for value in values) / center


def _optional_float(value, *, minimum=None, maximum=None):
    try:
        if value is None or str(value).strip() == "":
            return None
        number = float(value)
    except (TypeError, ValueError):
        return None
    if number != number or number in (float("inf"), float("-inf")):
        return None
    if minimum is not None and number < minimum:
        return None
    if maximum is not None and number > maximum:
        return None
    return number


def _average_ranks(values):
    order = sorted(range(len(values)), key=lambda index: values[index])
    ranks = [0.0] * len(values)
    left = 0
    while left < len(order):
        right = left + 1
        while right < len(order) and values[order[right]] == values[order[left]]:
            right += 1
        average_rank = (left + 1 + right) / 2.0
        for position in range(left, right):
            ranks[order[position]] = average_rank
        left = right
    return ranks


def spearman_rho(predictor, outcome):
    """Spearman correlation with average tied ranks; require five pairs."""
    if len(predictor) != len(outcome) or len(predictor) < 5:
        return None
    x_ranks = _average_ranks(predictor)
    y_ranks = _average_ranks(outcome)
    x_mean = mean(x_ranks)
    y_mean = mean(y_ranks)
    numerator = sum((x - x_mean) * (y - y_mean)
                    for x, y in zip(x_ranks, y_ranks))
    x_scale = sum((x - x_mean) ** 2 for x in x_ranks)
    y_scale = sum((y - y_mean) ** 2 for y in y_ranks)
    if x_scale == 0 or y_scale == 0:
        return None
    return numerator / (x_scale * y_scale) ** 0.5


def theil_sen_slope(predictor, outcome):
    """Median finite pairwise slope, or None without predictor variation."""
    if len(predictor) != len(outcome) or len(predictor) < 2:
        return None
    slopes = []
    for left in range(len(predictor)):
        for right in range(left + 1, len(predictor)):
            delta = predictor[right] - predictor[left]
            if delta:
                slope = (outcome[right] - outcome[left]) / delta
                if slope == slope and slope not in (float("inf"), float("-inf")):
                    slopes.append(slope)
    return median(slopes) if slopes else None


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
                    "target_pace": (raw.get("target_pace") or "").strip().lower() or None,
                    "activation_status": (
                        (raw.get("activation_status") or "").strip().lower() or None
                    ),
                    "active_factor": _optional_float(
                        raw.get("active_factor"), minimum=0.50, maximum=1.50),
                    "hrmax_bpm": _optional_float(
                        raw.get("hrmax_bpm"), minimum=1, maximum=255),
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
            if row["target_pace"] is not None and row["target_pace"] not in PACES:
                raise ValueError(f"Invalid target pace on line {line}")
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
    cadence_trials = [trial for trial in valid
                      if trial["cadence_per_min"] is not None
                      and trial["effective_step_length_m"] is not None]
    cadence = [trial["cadence_per_min"] for trial in cadence_trials]
    step_length = [trial["effective_step_length_m"] for trial in cadence_trials]
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
        "spearman_rho": spearman_rho(cadence, step_length),
        "theil_sen_slope": (
            theil_sen_slope(cadence, step_length)
            if len(cadence) >= 5 else None
        ),
    }


def _validate_schema_twelve_manifest(manifest, shifts):
    if [row["repetition"] for row in manifest] != list(range(1, len(manifest) + 1)):
        raise ValueError("Schema 12 calibration repetitions must match FIT lap order")
    if len(shifts) != len(manifest):
        raise ValueError("Schema 12 calibration requires one manifest row per FIT lap")
    valid = [row for row in manifest if row["marker_status"] == "valid"]
    if len(valid) != 10:
        raise ValueError("Schema 12 calibration requires exactly ten valid laps")
    if [row["condition"] for row in valid] != CONDITION_ORDER:
        raise ValueError("Schema 12 calibration condition order is invalid")
    if [row["target_pace"] for row in valid] != PACE_ORDER:
        raise ValueError("Schema 12 calibration pace order is invalid")
    if len({row["sport"] for row in valid}) != 1:
        raise ValueError("Schema 12 calibration requires one sport per session")
    distances = {row["reference_distance_cm"] for row in valid}
    if len(distances) != 1:
        raise ValueError("Schema 12 calibration requires one reference distance per session")
    if next(iter(distances)) not in {2000.0, 2200.0, 2500.0, 3000.0}:
        raise ValueError("Schema 12 reference distance must be 20, 22, 25, or 30 metres")


def _time_above_ninety(records, hrmax):
    if hrmax is None:
        return None
    seconds = 0.0
    observed_intervals = 0
    for current, following in zip(records, records[1:]):
        try:
            start = datetime.fromisoformat(str(current.get("timestamp")).replace("Z", "+00:00"))
            end = datetime.fromisoformat(str(following.get("timestamp")).replace("Z", "+00:00"))
            heart_rate = float(current.get("heart_rate"))
        except (TypeError, ValueError):
            continue
        interval = (end - start).total_seconds()
        if interval <= 0 or not 0 < heart_rate <= 255:
            continue
        observed_intervals += 1
        if heart_rate > 0.90 * hrmax:
            seconds += interval
    return seconds / 60.0 if observed_intervals else None


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
    if report.get("schema_version") == 12:
        _validate_schema_twelve_manifest(manifest, shifts)
    schema_twelve = report.get("schema_version") == 12
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
            "target_pace": row.get("target_pace"),
            "duration_minutes": None, "cadence_per_min": None,
            "effective_step_length_m": None, "baseline_factor": None,
            "baseline_distance_error_m": None,
            "factored_distance_error_m": None,
        }
        if row["marker_status"] != "valid":
            base["reason"] = "uncertain_marker"
        elif shift is None:
            base["reason"] = "missing_fit_lap"
        elif (shift.get("estimated_distance_cm") is None and
              shift.get("estimated_distance_m") is None) or shift.get("pushes") is None:
            base["reason"] = "unknown_fit_value"
        elif schema_twelve and (_optional_float(
                shift.get("duration_minutes"), minimum=0) is None or
                not 2.0 / 60.0 <= float(shift["duration_minutes"]) <= 30.0 / 60.0):
            base["reason"] = "duration_out_of_range"
        elif shift.get("coverage_percent") is None:
            base["reason"] = "unknown_sensor_coverage"
        elif schema_twelve and not 80 <= shift["coverage_percent"] <= 100:
            base["coverage_percent"] = shift["coverage_percent"]
            base["reason"] = "insufficient_sensor_coverage"
        elif not 0 < shift["coverage_percent"] <= 100:
            base["coverage_percent"] = shift["coverage_percent"]
            base["reason"] = "invalid_sensor_coverage"
        elif schema_twelve and shift["pushes"] <= 0:
            base["coverage_percent"] = shift["coverage_percent"]
            base["reason"] = "invalid_push_count"
        else:
            estimated_m = (shift.get("estimated_distance_m") if
                           shift.get("estimated_distance_m") is not None else
                           shift["estimated_distance_cm"] / 100.0)
            ratio = (base["reference_distance_m"] / estimated_m
                     if estimated_m > 0 else None)
            if schema_twelve and (ratio is None or not 0.50 <= ratio <= 1.50):
                base["coverage_percent"] = shift["coverage_percent"]
                base["reason"] = "factor_out_of_range"
                trials.append(base)
                continue
            base["coverage_percent"] = shift["coverage_percent"]
            base["distance_error_m"] = estimated_m - base["reference_distance_m"]
            base["distance_error_percent"] = (
                base["distance_error_m"] / base["reference_distance_m"] * 100.0
            )
            if row["reference_pushes"] is not None:
                base["push_error"] = shift["pushes"] - row["reference_pushes"]
            if shift["pushes"] > 0:
                base["effective_step_length_m"] = (
                    base["reference_distance_m"] / shift["pushes"])
            duration = _optional_float(shift.get("duration_minutes"), minimum=0)
            base["duration_minutes"] = duration
            if duration is not None and duration > 0 and shift["pushes"] > 0:
                base["cadence_per_min"] = shift["pushes"] / duration
            if ratio is not None:
                base["baseline_factor"] = ratio
            base["baseline_distance_error_m"] = (
                estimated_m - base["reference_distance_m"])
            factor = row.get("active_factor")
            if factor is not None:
                base["factored_distance_error_m"] = (
                    estimated_m * factor - base["reference_distance_m"])
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
    valid_factors = [trial["baseline_factor"] for trial in trials
                     if trial["valid"] and trial["baseline_factor"] is not None]
    condition_factors = {
        condition: [trial["baseline_factor"] for trial in trials
                    if trial["valid"] and trial["condition"] == condition and
                    trial["baseline_factor"] is not None]
        for condition in CONDITIONS
    }
    condition_medians = {
        condition: (median(values) if values else None)
        for condition, values in condition_factors.items()
    }
    factor = (_round_four_half_up(median(valid_factors))
              if len(valid_factors) == 10 else None)
    calibration_consistent = factor is not None
    if calibration_consistent:
        calibration_consistent = all(
            len(condition_factors[condition]) == 5 and
            _relative_mad(condition_factors[condition]) <= 0.15
            for condition in CONDITIONS)
    if calibration_consistent:
        left = condition_medians["skate_only"]
        right = condition_medians["puck_stickhandling"]
        midpoint = (left + right) / 2.0
        calibration_consistent = midpoint > 0 and abs(left - right) / midpoint <= 0.15
    if schema_twelve and profile_status == "eligible" and not calibration_consistent:
        profile_status = "inconsistent"

    declared_factors = {row["active_factor"] for row in manifest
                        if row.get("active_factor") is not None}
    fit_factor = report.get("personal_calibration_factor")
    factor_mismatch = None
    if schema_twelve:
        factor_mismatch = not (
            factor is not None and fit_factor is not None and
            len(declared_factors) == 1 and
            abs(next(iter(declared_factors)) - fit_factor) <= 0.00005 and
            abs(factor - fit_factor) <= 0.00005)
        if factor_mismatch:
            profile_status = "inconsistent"
    elif fit_factor is not None and declared_factors:
        factor_mismatch = (len(declared_factors) != 1 or
                           abs(next(iter(declared_factors)) - fit_factor) > 0.00005)
    hrmax_values = {row["hrmax_bpm"] for row in manifest
                    if row.get("hrmax_bpm") is not None}
    hrmax = next(iter(hrmax_values)) if len(hrmax_values) == 1 else None
    baseline_errors = [trial["baseline_distance_error_m"] for trial in trials
                       if trial["valid"] and
                       trial["baseline_distance_error_m"] is not None]
    factored_errors = [trial["factored_distance_error_m"] for trial in trials
                       if trial["valid"] and
                       trial["factored_distance_error_m"] is not None]
    return {
        "profile_status": profile_status,
        "session_start": report.get("session_start"),
        "personal_test_calibration": {
            "factor": factor if calibration_consistent else None,
            "valid_repetition_count": len(valid_factors),
            "condition_medians": {
                key: (_round_four_half_up(value) if value is not None else None)
                for key, value in condition_medians.items()
            },
            "scope": "local_personal_test",
            "population_coefficient": False,
            "automatic_activation": False,
        },
        "trials": trials,
        "groups": summaries,
        "factor_mismatch": factor_mismatch,
        "distance_model_comparison": {
            "baseline_mae_m": (mean(map(abs, baseline_errors))
                               if baseline_errors else None),
            "baseline_bias_m": mean(baseline_errors) if baseline_errors else None,
            "factored_mae_m": (mean(map(abs, factored_errors))
                               if factored_errors else None),
            "factored_bias_m": mean(factored_errors) if factored_errors else None,
        },
        "time_above_90_hrmax_minutes": _time_above_ninety(
            report.get("records", []), hrmax),
        "hrmax_source": "tester_manifest" if hrmax is not None else None,
        "timebase_verification": (
            "not_exported_in_schema_12" if schema_twelve else "not_applicable"),
    }


def build_calibration_report(fit_path: str | Path, manifest_path: str | Path) -> dict:
    from analysis.shift_pilot import load_pilot_fit

    return build_calibration_report_from_report(
        load_pilot_fit(fit_path), read_calibration_manifest(manifest_path)
    )
