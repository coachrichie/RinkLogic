"""Private, atomic return bundles for an inspected beta original export."""

from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime
import hashlib
import json
import os
from pathlib import Path
import re
import tempfile
import zipfile

from .assignment import Assignment, AssignmentError
from .diagnostics import DiagnosticReport
from .questionnaire import FeedbackAnswers, QuestionnaireError, validate_answers


_MAX_REFERENCE_BYTES = 1024 * 1024
_UNSAFE_TEXT = re.compile(
    r"(?:[A-Za-z]:[\\/]|\\\\[^\\\s]+\\|"
    r"(?:^|[\s,;\"'])/(?:[^\s/]+/)*[^\s/]+|"
    r"[\w.+-]+@[\w.-]+\.[A-Za-z]{2,}|"
    r"\bTraceback \(most recent call last\)|"
    r"\b(?:OPENAI_API_KEY|HOME|USERPROFILE|APPDATA|PATH)\s*=|"
    r"\$\{?[A-Za-z_][A-Za-z_0-9]*\}?|"
    r"%[A-Za-z_][A-Za-z_0-9]*%|"
    r"\+\d[\d ()-]{7,}\d)"
)


class BundleError(ValueError):
    """Safe failure identified by a stable machine-readable code."""

    def __init__(self, code: str):
        self.code = code
        super().__init__(code)


@dataclass(frozen=True, slots=True)
class BundleResult:
    path: Path
    sha256: str
    byte_size: int
    member_names: tuple[str, ...]


def _json_bytes(value: object) -> bytes:
    try:
        return (json.dumps(value, ensure_ascii=False, sort_keys=True, indent=2,
                           allow_nan=False) + "\n").encode("utf-8")
    except (TypeError, ValueError, UnicodeError):
        raise BundleError("invalid_payload") from None


def _session_day(value: str) -> str:
    try:
        day = datetime.fromisoformat(value).date().isoformat()
    except (TypeError, ValueError):
        raise BundleError("invalid_session_start") from None
    return day


def _validate_feedback(answers: FeedbackAnswers) -> dict[str, object]:
    try:
        feedback = validate_answers(answers.to_safe_dict()).to_safe_dict()
    except (AttributeError, QuestionnaireError, TypeError, ValueError):
        raise BundleError("invalid_feedback") from None
    if any(isinstance(value, str) and _UNSAFE_TEXT.search(value)
           for value in feedback.values()):
        raise BundleError("unsafe_feedback")
    return feedback


def _read_original(path: Path, expected_sha256: str) -> bytes:
    try:
        data = path.read_bytes()
    except OSError:
        raise BundleError("original_unreadable") from None
    if hashlib.sha256(data).hexdigest() != expected_sha256:
        raise BundleError("original_changed")
    return data


def _read_reference(path: Path | None, assignment_id: str) -> bytes:
    if path is None:
        raise BundleError("reference_missing")
    path = Path(path)
    if path.name != f"{assignment_id}_calibration_reference.csv":
        raise BundleError("reference_name_mismatch")
    try:
        with path.open("rb") as source:
            data = source.read(_MAX_REFERENCE_BYTES + 1)
    except OSError:
        raise BundleError("reference_missing") from None
    if len(data) > _MAX_REFERENCE_BYTES:
        raise BundleError("reference_too_large")
    try:
        text = data.decode("utf-8-sig")
    except UnicodeError:
        raise BundleError("unsafe_reference") from None
    if "\x00" in text or _UNSAFE_TEXT.search(text):
        raise BundleError("unsafe_reference")
    return data


def _archive_info(name: str) -> zipfile.ZipInfo:
    info = zipfile.ZipInfo(name, date_time=(1980, 1, 1, 0, 0, 0))
    info.compress_type = zipfile.ZIP_DEFLATED
    info.external_attr = 0o600 << 16
    return info


def build_return_bundle(
    original_path: Path,
    assignment: Assignment,
    diagnostics: DiagnosticReport,
    answers: FeedbackAnswers,
    destination_dir: Path,
    calibration_reference: Path | None = None,
) -> BundleResult:
    """Build and exclusively publish one assignment-bound local return ZIP."""
    original_path = Path(original_path)
    destination_dir = Path(destination_dir)
    original_resolved = original_path.resolve()
    destination_resolved = destination_dir.resolve()
    if (destination_resolved == original_resolved
            or original_resolved in destination_resolved.parents):
        raise BundleError("unsafe_destination")
    if not destination_dir.is_dir():
        raise BundleError("invalid_destination")

    try:
        assignment.validate_original_name(original_path.name)
    except AssignmentError:
        raise BundleError("identity_mismatch") from None
    if diagnostics.status != "pass" or diagnostics.codes:
        raise BundleError("diagnostics_not_pass")
    if (diagnostics.original_name != original_path.name
            or diagnostics.expected_prg_sha256 != assignment.expected_prg_sha256
            or diagnostics.schema_version != assignment.fit_schema):
        raise BundleError("identity_mismatch")

    day = _session_day(diagnostics.session_start)
    name = (f"{assignment.assignment_id}_{day}_{assignment.surface}_"
            f"{assignment.protocol}_return.zip")
    output_path = destination_dir / name
    if output_path.exists() or output_path.is_symlink():
        raise BundleError("output_exists")

    feedback = _validate_feedback(answers)
    original_data = _read_original(original_path, diagnostics.original_sha256)
    reference_data = (_read_reference(calibration_reference, assignment.assignment_id)
                      if assignment.protocol == "calibration" else None)

    manifest = {
        "contract_version": assignment.contract_version,
        "tester_id": assignment.tester_id,
        "assignment_id": assignment.assignment_id,
        "release_id": assignment.release_id,
        "app_version": assignment.app_version,
        "internal_version": assignment.internal_version,
        "fit_schema": assignment.fit_schema,
        "model_id": assignment.model_id,
        "product_id": assignment.product_id,
        "surface": assignment.surface,
        "protocol": assignment.protocol,
        "consent_version": assignment.consent_version,
        "session_date": day,
        "original_name": original_path.name,
        "original_sha256": diagnostics.original_sha256,
        "original_byte_size": len(original_data),
        "fit_sha256": diagnostics.fit_sha256,
        "expected_prg_sha256": assignment.expected_prg_sha256,
    }
    diagnostic_data = {"session_start": diagnostics.session_start,
                       **diagnostics.safe_summary()}
    members: list[tuple[str, bytes]] = [
        ("manifest.json", _json_bytes(manifest)),
        ("diagnostics.json", _json_bytes(diagnostic_data)),
        ("feedback.json", _json_bytes(feedback)),
        (f"original/{original_path.name}", original_data),
    ]
    if reference_data is not None:
        members.append((f"reference/{assignment.assignment_id}_calibration_reference.csv",
                        reference_data))
    checksums = "".join(
        f"{hashlib.sha256(data).hexdigest()}  {member_name}\n"
        for member_name, data in members
    ).encode("ascii")
    members.insert(3, ("SHA256SUMS.txt", checksums))

    temporary_path: Path | None = None
    published = False
    try:
        descriptor, temporary_name = tempfile.mkstemp(
            prefix=f".{name}.", suffix=".tmp", dir=destination_dir)
        temporary_path = Path(temporary_name)
        with os.fdopen(descriptor, "wb") as target:
            with zipfile.ZipFile(target, mode="w", allowZip64=True) as archive:
                for member_name, data in members:
                    archive.writestr(_archive_info(member_name), data)
        bundle_data = temporary_path.read_bytes()
        bundle_sha256 = hashlib.sha256(bundle_data).hexdigest()
        bundle_size = len(bundle_data)
        try:
            os.link(temporary_path, output_path)
        except FileExistsError:
            raise BundleError("output_exists") from None
        published = True
        temporary_path.unlink()
        temporary_path = None
        return BundleResult(output_path, bundle_sha256, bundle_size,
                            tuple(member_name for member_name, _ in members))
    except BundleError:
        raise
    except Exception:
        raise BundleError("bundle_write_failed") from None
    finally:
        if temporary_path is not None:
            if published:
                output_path.unlink(missing_ok=True)
            temporary_path.unlink(missing_ok=True)
