"""Deterministic, locally derived Beta-7 calibration reference metadata."""

from __future__ import annotations

import csv
from datetime import datetime
import io
import math
from pathlib import Path
from tempfile import TemporaryDirectory

from analysis.calibration_report import read_calibration_manifest

from .assignment import Assignment
from .diagnostics import DiagnosticReport


FIELDNAMES = (
    "session_id", "repetition", "sport", "condition",
    "reference_distance_cm", "reference_pushes", "marker_status",
    "target_pace", "activation_status", "active_factor", "hrmax_bpm",
)
_CONDITIONS = ("skate_only",) * 5 + ("puck_stickhandling",) * 5
_PACES = ("slow", "fast", "normal", "slow", "fast") * 2


class CalibrationReferenceError(ValueError):
    """A generated reference cannot satisfy the fixed Beta-7 contract."""

    def __init__(self, code: str):
        self.code = code
        super().__init__(code)


def _validated_factor(value: object) -> float:
    if isinstance(value, bool) or not isinstance(value, (int, float)):
        raise CalibrationReferenceError("invalid_factor")
    try:
        factor = float(value)
    except (OverflowError, ValueError):
        raise CalibrationReferenceError("invalid_factor") from None
    if not math.isfinite(factor) or not 0.50 <= factor <= 1.50:
        raise CalibrationReferenceError("invalid_factor")
    return factor


def _validate_contract(assignment: Assignment, diagnostics: DiagnosticReport) -> float:
    if assignment.protocol != "calibration":
        raise CalibrationReferenceError("not_calibration")
    if diagnostics.status != "pass" or diagnostics.codes:
        raise CalibrationReferenceError("diagnostics_not_pass")
    if (
        diagnostics.schema_version != 12
        or assignment.fit_schema != 12
        or diagnostics.protocol != assignment.protocol
        or diagnostics.surface != assignment.surface
        or diagnostics.product_id != assignment.product_id
        or diagnostics.manual_shift_count != 10
        or diagnostics.calibration_reference_distance_cm != 2000
        or diagnostics.calibration_skate_only_runs != 5
        or diagnostics.calibration_stickhandling_runs != 5
    ):
        raise CalibrationReferenceError("contract_mismatch")
    try:
        session_start = datetime.fromisoformat(diagnostics.session_start)
    except (TypeError, ValueError):
        raise CalibrationReferenceError("invalid_session_start") from None
    if session_start.tzinfo is None:
        raise CalibrationReferenceError("invalid_session_start")
    return _validated_factor(diagnostics.personal_calibration_factor)


def build_calibration_reference(
    assignment: Assignment,
    diagnostics: DiagnosticReport,
) -> bytes:
    """Return an analysis-valid ten-row CSV without a persistent intermediate."""
    factor = _validate_contract(assignment, diagnostics)
    stream = io.StringIO(newline="")
    writer = csv.DictWriter(stream, fieldnames=FIELDNAMES, lineterminator="\n")
    writer.writeheader()
    for index, (condition, pace) in enumerate(zip(_CONDITIONS, _PACES), start=1):
        writer.writerow({
            "session_id": diagnostics.session_start,
            "repetition": index,
            "sport": assignment.surface,
            "condition": condition,
            "reference_distance_cm": 2000,
            "reference_pushes": "",
            "marker_status": "valid",
            "target_pace": pace,
            "activation_status": "",
            "active_factor": format(factor, ".15g"),
            "hrmax_bpm": "",
        })
    try:
        data = stream.getvalue().encode("utf-8")
    except UnicodeError:
        raise CalibrationReferenceError("generated_reference_invalid") from None

    try:
        with TemporaryDirectory() as directory:
            path = Path(directory) / "calibration_reference.csv"
            path.write_bytes(data)
            normalized = read_calibration_manifest(path)
    except (OSError, UnicodeError, ValueError):
        raise CalibrationReferenceError("generated_reference_invalid") from None
    if (
        len(normalized) != 10
        or [row["condition"] for row in normalized] != list(_CONDITIONS)
        or [row["target_pace"] for row in normalized] != list(_PACES)
        or {row["sport"] for row in normalized} != {assignment.surface}
        or {row["reference_distance_cm"] for row in normalized} != {2000}
        or {row["active_factor"] for row in normalized} != {factor}
    ):
        raise CalibrationReferenceError("generated_reference_invalid")
    return data
