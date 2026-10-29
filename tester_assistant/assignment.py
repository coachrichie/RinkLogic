"""Strict immutable contract for a local Beta-7 tester assignment."""

from __future__ import annotations

from dataclasses import dataclass
from datetime import date
import ipaddress
import json
from pathlib import Path
import re
import sys
from typing import Mapping
from urllib.parse import urlsplit


class AssignmentError(ValueError):
    """Raised when an assignment or original filename violates its contract."""


_FIELD_NAMES = frozenset(
    {
        "contract_version",
        "tester_id",
        "assignment_id",
        "release_id",
        "app_version",
        "internal_version",
        "fit_schema",
        "model_id",
        "product_id",
        "surface",
        "protocol",
        "expected_prg_sha256",
        "upload_url",
        "consent_version",
    }
)
_SURFACES = frozenset({"ice", "inline"})
_PROTOCOLS = frozenset({"smoke", "calibration", "controlled-shifts", "normal-training"})
_TESTER_ID = re.compile(r"T[A-Z0-9]{5}\Z")
_ASSIGNMENT_ID = re.compile(r"(?P<tester>T[A-Z0-9]{5})-R[0-4]-[0-9]{3}\Z")
_RELEASE_ID = re.compile(r"RL-B7-[0-9]{8}-[A-F0-9]{7}\Z")
_SHA256 = re.compile(r"[0-9a-fA-F]{64}\Z")
_DNS_LABEL = re.compile(r"[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?\Z")
_PRODUCT_ID = re.compile(r"[a-z0-9]+\Z")
_DEVICE_FIELD_NAMES = frozenset(
    {
        "id",
        "ring",
        "displayClass",
        "inputClass",
        "representative",
        "status",
        "displayType",
        "width",
        "height",
    }
)
_RING1 = frozenset({"Ring1A", "Ring1B", "Ring1C"})


def _device_matrix_path() -> Path:
    """Resolve only the authoritative source or bundled Watch device matrix."""
    bundled_root = getattr(sys, "_MEIPASS", None)
    if bundled_root is not None:
        return Path(bundled_root) / "watch-v2" / "device-matrix.json"
    return Path(__file__).resolve().parents[1] / "watch-v2" / "device-matrix.json"


def load_release_device_ids() -> frozenset[str]:
    """Return the validated Beta-7 release-enabled Ring-1 product IDs."""
    try:
        with _device_matrix_path().open("r", encoding="utf-8") as source:
            raw = json.load(source)
    except (OSError, UnicodeError, json.JSONDecodeError) as exc:
        raise AssignmentError("Watch device matrix is not readable valid JSON") from exc

    if not isinstance(raw, Mapping) or set(raw) != {"schemaVersion", "devices"}:
        raise AssignmentError("Watch device matrix has an invalid structure")
    if type(raw["schemaVersion"]) is not int or raw["schemaVersion"] != 1:
        raise AssignmentError("Watch device matrix schema is unsupported")

    devices = raw["devices"]
    if not isinstance(devices, list):
        raise AssignmentError("Watch device matrix devices must be a list")

    all_ids: set[str] = set()
    release_ids: set[str] = set()
    for entry in devices:
        if not isinstance(entry, Mapping) or set(entry) != _DEVICE_FIELD_NAMES:
            raise AssignmentError("Watch device matrix contains a malformed entry")

        product_id = entry["id"]
        if not isinstance(product_id, str) or _PRODUCT_ID.fullmatch(product_id) is None:
            raise AssignmentError("Watch device matrix contains an invalid product ID")
        if product_id in all_ids:
            raise AssignmentError("Watch device matrix contains duplicate product IDs")
        all_ids.add(product_id)

        ring = entry["ring"]
        status = entry["status"]
        if ring not in _RING1 | {"Ring2"} or status not in {"release-enabled", "deferred"}:
            raise AssignmentError("Watch device matrix contains an invalid ring or status")
        if (ring in _RING1) != (status == "release-enabled"):
            raise AssignmentError("Watch device matrix ring and release status disagree")

        for name in ("displayClass", "inputClass"):
            value = entry[name]
            if not isinstance(value, str) or not value or value != value.strip():
                raise AssignmentError("Watch device matrix contains invalid display metadata")
        if type(entry["representative"]) is not bool:
            raise AssignmentError("Watch device matrix representative flag is invalid")
        if entry["displayType"] not in {"amoled", "mip"}:
            raise AssignmentError("Watch device matrix display type is invalid")
        for name in ("width", "height"):
            if type(entry[name]) is not int or entry[name] <= 0:
                raise AssignmentError("Watch device matrix dimensions are invalid")

        if status == "release-enabled":
            release_ids.add(product_id)

    if len(release_ids) != 50:
        raise AssignmentError("Watch device matrix must contain exactly 50 Ring-1 devices")
    return frozenset(release_ids)


def _is_valid_upload_host(host: str) -> bool:
    """Accept valid IP literals and DNS names, rejecting malformed host characters."""
    if ":" in host:
        try:
            return ipaddress.ip_address(host).version == 6
        except ValueError:
            return False

    try:
        return ipaddress.ip_address(host).version == 4
    except ValueError:
        pass

    try:
        ascii_host = host.encode("idna").decode("ascii")
    except UnicodeError:
        return False
    if ascii_host.endswith("."):
        ascii_host = ascii_host[:-1]
    if not ascii_host or len(ascii_host) > 253:
        return False
    return all(_DNS_LABEL.fullmatch(label) for label in ascii_host.split("."))


@dataclass(frozen=True, slots=True)
class Assignment:
    """Validated Beta-7 assignment metadata; never contains tester contact data."""

    contract_version: int
    tester_id: str
    assignment_id: str
    release_id: str
    app_version: str
    internal_version: int
    fit_schema: int
    model_id: str
    product_id: str
    surface: str
    protocol: str
    expected_prg_sha256: str
    upload_url: str
    consent_version: str

    def __post_init__(self) -> None:
        values = {name: getattr(self, name) for name in _FIELD_NAMES}
        self._validate_values(values)

    @classmethod
    def load(cls, path: Path) -> Assignment:
        """Load and validate a UTF-8 JSON assignment from disk."""
        try:
            with Path(path).open("r", encoding="utf-8") as source:
                raw = json.load(source)
        except (OSError, UnicodeError, json.JSONDecodeError) as exc:
            raise AssignmentError("Assignment file is not readable valid JSON") from exc
        if not isinstance(raw, Mapping):
            raise AssignmentError("Assignment JSON must be an object")
        return cls.from_dict(raw)

    @classmethod
    def from_dict(cls, raw: Mapping[str, object]) -> Assignment:
        """Build an assignment only when every required field is recognized."""
        if not isinstance(raw, Mapping):
            raise AssignmentError("Assignment must be a mapping")
        keys = set(raw)
        missing = _FIELD_NAMES - keys
        unknown = keys - _FIELD_NAMES
        if missing:
            raise AssignmentError("Assignment is missing required fields")
        if unknown:
            raise AssignmentError("Assignment contains unknown fields")
        try:
            return cls(**{name: raw[name] for name in _FIELD_NAMES})  # type: ignore[arg-type]
        except TypeError as exc:
            raise AssignmentError("Assignment fields have an invalid structure") from exc

    def validate_original_name(self, name: str) -> None:
        """Require the original export filename stem to match this assignment."""
        if not isinstance(name, str) or not name or Path(name).name != name:
            raise AssignmentError("Original filename must be a single filename")
        pattern = re.compile(
            rf"{re.escape(self.assignment_id)}_"
            rf"(?P<day>[0-9]{{4}}-[0-9]{{2}}-[0-9]{{2}})_"
            rf"{re.escape(self.surface)}_{re.escape(self.protocol)}_original\.(?:zip|fit)\Z",
        )
        match = pattern.fullmatch(name)
        if match is None:
            raise AssignmentError("Original filename does not match assignment identity")
        try:
            parsed_day = date.fromisoformat(match.group("day"))
        except ValueError as exc:
            raise AssignmentError("Original filename contains an invalid date") from exc
        if parsed_day.isoformat() != match.group("day"):
            raise AssignmentError("Original filename date is not canonical")

    @staticmethod
    def _validate_values(values: Mapping[str, object]) -> None:
        if set(values) != _FIELD_NAMES:
            raise AssignmentError("Assignment fields do not match the contract")

        for name in _FIELD_NAMES - {"contract_version", "internal_version", "fit_schema"}:
            value = values[name]
            if not isinstance(value, str) or not value or value != value.strip():
                raise AssignmentError(f"Assignment field {name} must be a non-empty string")
            if any(ord(char) < 32 or ord(char) == 127 for char in value):
                raise AssignmentError(f"Assignment field {name} contains control characters")

        if type(values["contract_version"]) is not int or values["contract_version"] != 2:
            raise AssignmentError("Unsupported assignment contract version")
        if type(values["internal_version"]) is not int or values["internal_version"] != 7:
            raise AssignmentError("Assignment is not for Beta-7 internal version 7")
        if type(values["fit_schema"]) is not int or values["fit_schema"] != 12:
            raise AssignmentError("Assignment is not for FIT schema 12")

        tester_id = values["tester_id"]
        assignment_id = values["assignment_id"]
        if not _TESTER_ID.fullmatch(tester_id):  # type: ignore[arg-type]
            raise AssignmentError("Tester ID is malformed")
        assignment_match = _ASSIGNMENT_ID.fullmatch(assignment_id)  # type: ignore[arg-type]
        if assignment_match is None or assignment_match.group("tester") != tester_id:
            raise AssignmentError("Assignment ID is malformed or belongs to another tester")

        expected_identity = {
            "app_version": "0.2.0-beta.7",
            "model_id": "profile_height_v1+local_known_distance_v1",
            "consent_version": "beta6-consent-2026-10-23",
        }
        for name, expected in expected_identity.items():
            if values[name] != expected:
                raise AssignmentError(f"Assignment {name} is not the supported Beta-7 value")
        if not _RELEASE_ID.fullmatch(values["release_id"]):  # type: ignore[arg-type]
            raise AssignmentError("Assignment release ID is malformed or not Beta-7")
        if values["product_id"] not in load_release_device_ids():
            raise AssignmentError("Assignment product_id is not a release-enabled Ring-1 device")

        if values["surface"] not in _SURFACES:
            raise AssignmentError("Assignment surface is unsupported")
        if values["protocol"] not in _PROTOCOLS:
            raise AssignmentError("Assignment protocol is unsupported")
        if not _SHA256.fullmatch(values["expected_prg_sha256"]):  # type: ignore[arg-type]
            raise AssignmentError("Expected PRG SHA-256 is malformed")

        upload_url = values["upload_url"]
        try:
            parsed_url = urlsplit(upload_url)  # type: ignore[arg-type]
            parsed_url.port
        except ValueError as exc:
            raise AssignmentError("Upload URL is malformed") from exc
        if (
            parsed_url.scheme.lower() != "https"
            or not parsed_url.hostname
            or not _is_valid_upload_host(parsed_url.hostname)
            or any(char.isspace() for char in upload_url)  # type: ignore[union-attr]
            or parsed_url.username is not None
            or parsed_url.password is not None
            or parsed_url.fragment
        ):
            raise AssignmentError("Upload URL must be an HTTPS URL with a host")
