"""Local, non-authoritative ShiftSense shadow-pilot FIT evaluation."""

from __future__ import annotations

import argparse
import csv
import json
from datetime import datetime
from pathlib import Path
from statistics import median

from .calibration_report import build_calibration_report


PILOT_FIELD_NAMES = {
    43: "shadow_schema_version",
    44: "motion_mg",
    45: "rotation_dps",
    46: "auto_state",
    47: "auto_confidence",
    48: "event_bits",
    49: "manual_state",
    50: "shadow_schema_version",
    51: "manual_boundary_ms",
    52: "manual_boundary_state",
    53: "sample_seq",
    54: "sample_at_ms",
    55: "auto_boundary_ms",
    56: "auto_boundary_state",
    57: "shift_count",
    58: "time_on_ice",
    59: "bench_time",
    60: "average_shift_duration",
    61: "average_shift_heart_rate",
    62: "push_count_total",
    63: "estimated_distance_cm_total",
    64: "push_cadence_per_min",
    65: "shift_push_count",
    66: "shift_estimated_distance_cm",
    67: "push_count_total",
    68: "estimated_distance_cm_total",
    69: "motion_coverage_percent",
    70: "short_push_count_total",
    71: "shift_short_push_count",
    72: "shift_motion_coverage_percent",
}
STATE_NAMES = {1: "ice", 2: "bench"}


def _datetime(value):
    if value is None:
        return None
    if isinstance(value, datetime):
        return value
    if isinstance(value, str):
        return datetime.fromisoformat(value.replace("Z", "+00:00"))
    raise ValueError(f"Unexpected FIT timestamp: {value!r}")


def _elapsed_ms(timestamp, start):
    if timestamp is None or start is None:
        return None
    return round((_datetime(timestamp) - _datetime(start)).total_seconds() * 1000)


def _ice_time_ms(events, duration_ms):
    total = 0
    opened = None
    for event in sorted(events, key=lambda item: item["at_ms"]):
        if event["state"] == "ice" and opened is None:
            opened = event["at_ms"]
        elif event["state"] == "bench" and opened is not None:
            total += max(0, event["at_ms"] - opened)
            opened = None
    if opened is not None and duration_ms is not None:
        total += max(0, duration_ms - opened)
    return total


def _valid_uint(value, invalid):
    if value is None or value == invalid:
        return None
    number = int(value)
    return number if number >= 0 else None


def _push_metrics(session, records, messages, schema_version):
    empty = {"total_pushes": None, "estimated_distance_cm": None,
             "short_pushes": None, "coverage_percent": None,
             "cadence_latest_per_min": None, "manual_shifts": []}
    if schema_version < 6:
        return empty
    manual_shifts = []
    for lap in messages:
        if lap.get("type") != "lap" or lap.get("manual_boundary_state") != 2:
            continue
        if lap.get("manual_boundary_ms") is None:
            continue
        manual_shifts.append({
            "at_ms": int(lap["manual_boundary_ms"]),
            "pushes": _valid_uint(lap.get("shift_push_count"), 65535),
            "estimated_distance_cm": _valid_uint(
                lap.get("shift_estimated_distance_cm"), 4294967295),
            "short_pushes": _valid_uint(lap.get("shift_short_push_count"), 65535),
            "coverage_percent": _valid_uint(
                lap.get("shift_motion_coverage_percent"), 255),
        })
    cadence = None
    for record in records:
        cadence = _valid_uint(record.get("push_cadence_per_min"), 65535)
    return {
        "total_pushes": _valid_uint(session.get("push_count_total"), 4294967295),
        "estimated_distance_cm": _valid_uint(
            session.get("estimated_distance_cm_total"), 4294967295),
        "short_pushes": _valid_uint(session.get("short_push_count_total"), 4294967295),
        "coverage_percent": _valid_uint(session.get("motion_coverage_percent"), 255),
        "cadence_latest_per_min": cadence,
        "manual_shifts": manual_shifts,
    }


def score_boundaries(references, proposals, duration_ms, tolerance_ms=10000):
    """Match same-direction boundaries once each, nearest error first."""
    pairs = sorted(
        (abs(reference["at_ms"] - proposal["at_ms"]), ri, pi)
        for ri, reference in enumerate(references)
        for pi, proposal in enumerate(proposals)
        if reference["state"] == proposal["state"]
        and abs(reference["at_ms"] - proposal["at_ms"]) <= tolerance_ms
    )
    used_references = set()
    used_proposals = set()
    errors = []
    for error, ri, pi in pairs:
        if ri not in used_references and pi not in used_proposals:
            used_references.add(ri)
            used_proposals.add(pi)
            errors.append(error)
    errors.sort()

    intervals = []
    opened = None
    for event in sorted(references, key=lambda item: item["at_ms"]):
        if event["state"] == "ice" and opened is None:
            opened = event["at_ms"]
        elif event["state"] == "bench" and opened is not None:
            intervals.append((opened, event["at_ms"]))
            opened = None
    if opened is not None and duration_ms is not None:
        intervals.append((opened, duration_ms))
    false_splits = sum(
        proposal["state"] == "bench"
        and any(start <= proposal["at_ms"] < end for start, end in intervals)
        for pi, proposal in enumerate(proposals)
        if pi not in used_proposals
    )
    manual_ice = _ice_time_ms(references, duration_ms)
    auto_ice = _ice_time_ms(proposals, duration_ms)
    p95_index = max(0, (95 * len(errors) + 99) // 100 - 1)
    return {
        "matched": len(errors),
        "references": len(references),
        "proposals": len(proposals),
        "precision": len(errors) / len(proposals) if proposals else 0.0,
        "recall": len(errors) / len(references) if references else 0.0,
        "median_error_ms": median(errors) if errors else None,
        "p95_error_ms": errors[p95_index] if errors else None,
        "boundary_errors_ms": errors,
        "false_splits": false_splits,
        "false_splits_per_hour": (
            false_splits * 3600000 / duration_ms if duration_ms > 0 else None
        ),
        "manual_ice_ms": manual_ice,
        "auto_ice_ms": auto_ice,
        "ice_time_error_ms": abs(manual_ice - auto_ice),
    }


def normalize_messages(messages):
    """Normalize already decoded FIT messages without inventing missing data."""
    messages = list(messages)
    sessions = [m for m in messages if m.get("type") == "session"]
    session = next((m for m in sessions if m.get("shadow_schema_version") in (4, 5, 6)), None)
    if session is None:
        raise ValueError("This activity has no ShiftSense shadow schema 4, 5 or 6 session")
    schema_version = session["shadow_schema_version"]
    start = session.get("start_time")
    records = [m for m in messages if m.get("type") == "record"
               and m.get("shadow_schema_version") == schema_version]
    boundaries = sorted(
        ({"at_ms": int(m["manual_boundary_ms"]),
          "state": STATE_NAMES[m["manual_boundary_state"]]}
         for m in messages if m.get("type") == "lap"
         and m.get("manual_boundary_state") in STATE_NAMES
         and m.get("manual_boundary_ms") is not None),
        key=lambda item: item["at_ms"],
    )

    proposals = sorted(
        ({"at_ms": int(m["auto_boundary_ms"]),
          "state": STATE_NAMES[m["auto_boundary_state"]]}
         for m in messages if m.get("type") == "lap"
         and m.get("auto_boundary_state") in STATE_NAMES
         and m.get("auto_boundary_ms") is not None),
        key=lambda item: item["at_ms"],
    )
    missing = 0
    uncertain = 0
    valid = 0
    timed_rows = []
    fresh_samples = []
    seen_sequences = set()
    for record in records:
        at_ms = _elapsed_ms(record.get("timestamp"), start)
        if at_ms is not None:
            timed_rows.append(at_ms)
        sequence = record.get("sample_seq")
        sample_at = record.get("sample_at_ms")
        fresh = (sequence is not None and sample_at is not None
                 and sequence not in seen_sequences and at_ms is not None
                 and -1500 <= at_ms - sample_at <= 1500)
        if sequence is not None:
            seen_sequences.add(sequence)
        if not fresh:
            continue
        fresh_samples.append((sequence, sample_at))
        motion = record.get("motion_mg")
        if motion is None or motion == 65535:
            missing += 1
        else:
            valid += 1
        if record.get("auto_state") == 3:
            uncertain += 1

    total_elapsed = session.get("total_elapsed_time")
    duration_ms = round(total_elapsed * 1000) if total_elapsed is not None else None
    if duration_ms is None and timed_rows and start is not None:
        duration_ms = max(timed_rows)
    if duration_ms is None and boundaries:
        duration_ms = boundaries[-1]["at_ms"]
    # Sample timestamps drift around whole-second boundaries. Sequence gaps
    # reveal skipped FIT writes; large time gaps also reveal stalled callbacks.
    # Do not count a regular sample in the next integer-second bin as absent.
    if duration_ms is None:
        fit_gaps = None
    elif not fresh_samples:
        fit_gaps = duration_ms // 1000
    else:
        fresh_samples.sort(key=lambda item: item[1])
        fit_gaps = fresh_samples[0][1] // 1000
        fit_gaps += max(0, duration_ms // 1000 - 1 -
                        fresh_samples[-1][1] // 1000)
        for (left_seq, left_at), (right_seq, right_at) in zip(
                fresh_samples, fresh_samples[1:]):
            skipped_sequence = max(0, right_seq - left_seq - 1)
            skipped_time = max(0, (right_at - left_at + 500) // 1000 - 1)
            fit_gaps += max(skipped_sequence, skipped_time)
    return {
        "schema_version": schema_version,
        "session_start": str(start) if start is not None else None,
        "duration_ms": duration_ms,
        "records": records,
        "manual_boundaries": boundaries,
        "proposals": proposals,
        "valid_motion_seconds": valid,
        "missing_sensor_seconds": missing,
        "uncertain_seconds": uncertain,
        "fit_write_gap_seconds": fit_gaps,
        "evidence_complete": fit_gaps == 0 and missing == 0 and valid > 0,
        "proposal_timestamp_resolution_ms": 1,
        "push_metrics": _push_metrics(session, records, messages, schema_version),
    }


def load_pilot_fit(path):
    """CRC-check one user-owned FIT file and decode its schema-4/5/6 fields."""
    import fitdecode
    from fitdecode.types import DevFieldDefinition

    messages = []
    with fitdecode.FitReader(path, check_crc=fitdecode.CrcCheck.RAISE,
                             error_handling=fitdecode.ErrorHandling.RAISE) as reader:
        for frame in reader:
            if not isinstance(frame, fitdecode.FitDataMessage):
                continue
            if frame.name not in ("record", "lap", "session"):
                continue
            message = {"type": frame.name}
            for field in frame.fields:
                name = field.name
                if isinstance(field.field_def, DevFieldDefinition):
                    name = PILOT_FIELD_NAMES.get(field.def_num, name)
                message[name] = field.value
            messages.append(message)
    result = normalize_messages(messages)
    if result["session_start"] is None:
        raise ValueError("ShiftSense FIT session has no start_time")
    if not result["manual_boundaries"]:
        raise ValueError("ShiftSense FIT activity has no manual boundary laps")
    if result["duration_ms"] is None or result["duration_ms"] <= 0:
        raise ValueError("ShiftSense FIT activity has no positive duration")
    return result


def _read_reference_csv(path):
    with open(path, newline="", encoding="utf-8-sig") as stream:
        reader = csv.DictReader(stream)
        if not {"elapsed_ms", "state"}.issubset(reader.fieldnames or []):
            raise ValueError("Reference CSV needs elapsed_ms,state columns")
        events = [{"at_ms": int(row["elapsed_ms"]),
                   "state": row["state"].strip().lower()} for row in reader]
    if any(event["state"] not in ("ice", "bench") for event in events):
        raise ValueError("Reference CSV state must be ice or bench")
    return events


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("fit", nargs="+", type=Path, help="local schema-4/5/6 FIT files")
    parser.add_argument("--reference", action="append", type=Path,
                        help="optional elapsed_ms,state CSV; repeat per FIT file")
    parser.add_argument("--output", type=Path, help="write local JSON report")
    parser.add_argument("--calibration-manifest", type=Path,
                        help="local calibration manifest for one FIT activity")
    args = parser.parse_args(argv)
    if args.calibration_manifest:
        if len(args.fit) != 1:
            parser.error("--calibration-manifest requires exactly one FIT file")
        output = build_calibration_report(args.fit[0], args.calibration_manifest)
        rendered = json.dumps(output, indent=2, ensure_ascii=False)
        if args.output:
            args.output.write_text(rendered + "\n", encoding="utf-8")
        print(rendered)
        return 0
    if args.reference and len(args.reference) != len(args.fit):
        parser.error("provide one --reference CSV for each FIT file")

    sessions = []
    for index, path in enumerate(args.fit):
        report = load_pilot_fit(path)
        refs = (_read_reference_csv(args.reference[index]) if args.reference
                else report["manual_boundaries"])
        if not refs:
            raise ValueError(f"No reference boundaries for {path}")
        score = score_boundaries(refs, report["proposals"], report["duration_ms"])
        sessions.append({"fit": str(path), "duration_ms": report["duration_ms"], "coverage": {
            key: report[key] for key in (
                "valid_motion_seconds", "missing_sensor_seconds",
                "uncertain_seconds", "fit_write_gap_seconds",
                "evidence_complete",
                "proposal_timestamp_resolution_ms")},
                "push_metrics": report["push_metrics"], "score": score})

    matches = sum(item["score"]["matched"] for item in sessions)
    references = sum(item["score"]["references"] for item in sessions)
    proposals = sum(item["score"]["proposals"] for item in sessions)
    errors = sorted(error for item in sessions
                    for error in item["score"]["boundary_errors_ms"])
    false_splits = sum(item["score"]["false_splits"] for item in sessions)
    duration = sum(item["duration_ms"] for item in sessions)
    aggregate = {
        "sessions": len(sessions), "reference_boundaries": references,
        "matched": matches, "proposals": proposals,
        "precision": matches / proposals if proposals else 0.0,
        "recall": matches / references if references else 0.0,
        "median_error_ms": median(errors) if errors else None,
        "false_splits_per_hour": false_splits * 3600000 / duration,
    }
    gate = {
        "at_least_five_sessions": len(sessions) >= 5,
        "at_least_fifty_boundaries": references >= 50,
        "complete_motion_evidence": all(
            item["coverage"]["evidence_complete"] for item in sessions),
        "precision_at_least_90_percent": aggregate["precision"] >= 0.9,
        "recall_at_least_90_percent": aggregate["recall"] >= 0.9,
        "median_error_at_most_10_seconds": errors != [] and median(errors) <= 10000,
        "false_splits_at_most_one_per_hour": aggregate["false_splits_per_hour"] <= 1,
        "saved_recording_confirmed": False,
        "battery_reviewed": False,
        "user_reviewed": False,
    }
    output = {"status": "provisional_not_validated", "aggregate": aggregate,
              "promotion_gate": gate, "sessions": sessions}
    rendered = json.dumps(output, indent=2, ensure_ascii=False)
    if args.output:
        args.output.write_text(rendered + "\n", encoding="utf-8")
    print(rendered)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
