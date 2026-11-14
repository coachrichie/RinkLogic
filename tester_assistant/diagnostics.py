"""Local inspection of an unchanged Garmin Connect Original export."""

from __future__ import annotations

from dataclasses import dataclass
import hashlib
import math
from pathlib import Path, PurePosixPath, PureWindowsPath
import stat
from tempfile import TemporaryDirectory
from typing import Mapping
import zipfile

from analysis.shift_pilot import load_pilot_fit
from .assignment import Assignment, AssignmentError


_MAX_FIT_BYTES = 64 * 1024 * 1024
_ARCHIVE_SUFFIXES = frozenset({".zip", ".7z", ".rar", ".tar", ".gz", ".bz2", ".xz"})
_EXECUTABLE_SUFFIXES = frozenset({".exe", ".bat", ".cmd", ".com", ".ps1", ".sh", ".msi", ".scr", ".js", ".vbs"})


class DiagnosticError(ValueError):
    """Safe validation failure, identified by a stable machine-readable code."""

    def __init__(self, code: str):
        self.code = code
        super().__init__(code)


@dataclass(frozen=True, slots=True)
class DiagnosticReport:
    """Only selected file metadata and session aggregates, never FIT records."""

    status: str
    codes: tuple[str, ...]
    original_sha256: str
    fit_sha256: str
    original_name: str
    fit_member_name: str | None
    schema_version: int
    session_start: str
    duration_minutes: float
    manual_shift_count: int
    estimated_distance_m: float | None
    personal_calibration_factor: float | None
    heart_rate_available: bool
    expected_prg_sha256: str
    surface: str = ""
    protocol: str = ""
    product_id: str = ""
    calibration_reference_distance_cm: int | None = None
    calibration_skate_only_runs: int | None = None
    calibration_stickhandling_runs: int | None = None

    def safe_summary(self) -> dict[str, object]:
        """Return only fields safe for local confirmation and later opt-in sharing."""
        return {
            "status": self.status,
            "codes": list(self.codes),
            "schema_version": self.schema_version,
            "duration_minutes": self.duration_minutes,
            "manual_shift_count": self.manual_shift_count,
            "estimated_distance_m": self.estimated_distance_m,
            "personal_calibration_factor": self.personal_calibration_factor,
            "heart_rate_available": self.heart_rate_available,
            "surface": self.surface,
            "protocol": self.protocol,
            "product_id": self.product_id,
            "calibration_reference_distance_cm": self.calibration_reference_distance_cm,
            "calibration_skate_only_runs": self.calibration_skate_only_runs,
            "calibration_stickhandling_runs": self.calibration_stickhandling_runs,
        }


def _hash_original(path: Path) -> tuple[str, int]:
    digest = hashlib.sha256()
    size = 0
    try:
        with path.open("rb") as source:
            for chunk in iter(lambda: source.read(1024 * 1024), b""):
                size += len(chunk)
                digest.update(chunk)
    except OSError:
        raise DiagnosticError("unreadable_input") from None
    if size == 0:
        raise DiagnosticError("empty_input")
    return digest.hexdigest(), size


def _validate_member(info: zipfile.ZipInfo) -> None:
    name = info.filename
    normalized = name.replace("\\", "/")
    path = PurePosixPath(normalized)
    if (
        not name
        or "\x00" in name
        or normalized.startswith("/")
        or PureWindowsPath(name).is_absolute()
        or ":" in normalized
        or any(part in ("", ".", "..") for part in normalized.split("/") if part != "" or not info.is_dir())
        or ".." in path.parts
    ):
        raise DiagnosticError("zip_unsafe_member_name")
    mode = info.external_attr >> 16
    file_type = stat.S_IFMT(mode)
    if mode and file_type not in (0, stat.S_IFDIR if info.is_dir() else stat.S_IFREG):
        raise DiagnosticError("zip_unsafe_member_type")
    if info.is_dir():
        return
    suffix = path.suffix.lower()
    if suffix in _ARCHIVE_SUFFIXES:
        raise DiagnosticError("zip_nested_archive")
    if suffix in _EXECUTABLE_SUFFIXES:
        raise DiagnosticError("zip_executable_member")


def _read_zip_fit(path: Path) -> tuple[bytes, str]:
    try:
        with zipfile.ZipFile(path) as archive:
            members = archive.infolist()
            for member in members:
                _validate_member(member)
            fits = [member for member in members
                    if not member.is_dir() and PurePosixPath(member.filename).suffix.lower() == ".fit"]
            if not fits:
                raise DiagnosticError("zip_no_fit")
            if len(fits) != 1:
                raise DiagnosticError("zip_multiple_fit")
            if any(not member.is_dir() and member not in fits for member in members):
                raise DiagnosticError("zip_unexpected_member")
            member = fits[0]
            if member.file_size > _MAX_FIT_BYTES:
                raise DiagnosticError("fit_too_large")
            with archive.open(member) as source:
                data = source.read(_MAX_FIT_BYTES + 1)
            if len(data) > _MAX_FIT_BYTES:
                raise DiagnosticError("fit_too_large")
            if not data:
                raise DiagnosticError("empty_fit")
            return data, member.filename
    except DiagnosticError:
        raise
    except NotImplementedError:
        raise DiagnosticError("unsupported_zip_compression") from None
    except (OSError, EOFError, RuntimeError, ValueError, zipfile.BadZipFile, zipfile.LargeZipFile):
        raise DiagnosticError("corrupt_zip") from None


def _finite_nonnegative(value: object) -> float | None:
    if value is None:
        return None
    if isinstance(value, bool) or not isinstance(value, (int, float)):
        raise DiagnosticError("invalid_metric")
    try:
        number = float(value)
    except OverflowError:
        raise DiagnosticError("invalid_metric") from None
    if not math.isfinite(number) or number < 0:
        raise DiagnosticError("invalid_metric")
    return number


def _calibration_factor(value: object) -> float:
    if value is None:
        raise DiagnosticError("calibration_factor_missing")
    if isinstance(value, bool) or not isinstance(value, (int, float)):
        raise DiagnosticError("calibration_factor_invalid")
    try:
        factor = float(value)
    except OverflowError:
        raise DiagnosticError("calibration_factor_invalid") from None
    if not math.isfinite(factor) or factor < 0:
        raise DiagnosticError("calibration_factor_invalid")
    if not 0.50 <= factor <= 1.50:
        raise DiagnosticError("calibration_factor_out_of_range")
    return factor


def _report_from_pilot(
    pilot: object, original_name: str, original_sha256: str,
    fit_sha256: str, fit_member_name: str | None, assignment: Assignment,
) -> DiagnosticReport:
    if not isinstance(pilot, Mapping):
        raise DiagnosticError("parser_error")
    if type(pilot.get("schema_version")) is not int or pilot["schema_version"] != 12:
        raise DiagnosticError("schema_mismatch")
    start = pilot.get("session_start")
    if not isinstance(start, str) or not start.strip():
        raise DiagnosticError("missing_session_start")
    duration_ms = pilot.get("duration_ms")
    if isinstance(duration_ms, bool) or not isinstance(duration_ms, (int, float)):
        raise DiagnosticError("invalid_duration")
    try:
        duration_ms = float(duration_ms)
    except OverflowError:
        raise DiagnosticError("invalid_duration") from None
    if not math.isfinite(duration_ms) or duration_ms <= 0:
        raise DiagnosticError("invalid_duration")
    push_metrics = pilot.get("push_metrics")
    if not isinstance(push_metrics, Mapping):
        raise DiagnosticError("parser_error")
    manual_shifts = push_metrics.get("manual_shifts")
    if not isinstance(manual_shifts, list):
        raise DiagnosticError("parser_error")
    distance = _finite_nonnegative(push_metrics.get("estimated_distance_m"))
    if assignment.protocol == "calibration":
        if len(manual_shifts) != 10:
            raise DiagnosticError("calibration_lap_count")
        factor = _calibration_factor(pilot.get("personal_calibration_factor"))
        reference_distance_cm = 2000
        skate_only_runs = 5
        stickhandling_runs = 5
    else:
        factor = _finite_nonnegative(pilot.get("personal_calibration_factor"))
        reference_distance_cm = None
        skate_only_runs = None
        stickhandling_runs = None
    records = pilot.get("records")
    if not isinstance(records, list):
        raise DiagnosticError("parser_error")
    heart_rate_available = False
    for record in records:
        if not isinstance(record, Mapping):
            raise DiagnosticError("parser_error")
        heart_rate = record.get("heart_rate")
        if heart_rate is not None:
            heart_rate_available |= _finite_nonnegative(heart_rate) is not None
    return DiagnosticReport(
        status="pass", codes=(), original_sha256=original_sha256,
        fit_sha256=fit_sha256, original_name=original_name,
        fit_member_name=fit_member_name, schema_version=12,
        session_start=start, duration_minutes=duration_ms / 60000,
        manual_shift_count=len(manual_shifts), estimated_distance_m=distance,
        personal_calibration_factor=factor,
        heart_rate_available=heart_rate_available,
        expected_prg_sha256=assignment.expected_prg_sha256,
        surface=assignment.surface, protocol=assignment.protocol,
        product_id=assignment.product_id,
        calibration_reference_distance_cm=reference_distance_cm,
        calibration_skate_only_runs=skate_only_runs,
        calibration_stickhandling_runs=stickhandling_runs,
    )


def inspect_original(path: Path, assignment: Assignment) -> DiagnosticReport:
    """Validate, hash, and locally decode one assignment-bound original export."""
    path = Path(path)
    try:
        assignment.validate_original_name(path.name)
    except AssignmentError:
        code = ("unsupported_extension" if path.suffix.lower() not in (".fit", ".zip")
                else "original_name_mismatch")
        raise DiagnosticError(code) from None

    original_sha256, original_size = _hash_original(path)
    if path.suffix == ".fit":
        if original_size > _MAX_FIT_BYTES:
            raise DiagnosticError("fit_too_large")
        try:
            pilot = load_pilot_fit(path)
        except Exception:
            raise DiagnosticError("parser_error") from None
        return _report_from_pilot(pilot, path.name, original_sha256,
                                  original_sha256, None, assignment)

    fit_data, member_name = _read_zip_fit(path)
    fit_sha256 = hashlib.sha256(fit_data).hexdigest()
    with TemporaryDirectory() as directory:
        fit_path = Path(directory) / "member.fit"
        fit_path.write_bytes(fit_data)
        try:
            pilot = load_pilot_fit(fit_path)
        except Exception:
            raise DiagnosticError("parser_error") from None
    return _report_from_pilot(pilot, path.name, original_sha256,
                              fit_sha256, member_name, assignment)
