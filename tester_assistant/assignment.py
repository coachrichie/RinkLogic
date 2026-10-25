"""Strict immutable contract for a local Beta-6 tester assignment."""

from __future__ import annotations

from dataclasses import dataclass
from datetime import date
import ipaddress
import json
from pathlib import Path
import re
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
_RELEASE_ID = re.compile(r"RL-B6-[0-9]{8}-[A-F0-9]{7}\Z")
_SHA256 = re.compile(r"[0-9a-fA-F]{64}\Z")
_DNS_LABEL = re.compile(r"[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?\Z")


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
    """Validated Beta-6 assignment metadata; never contains tester contact data."""

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

        if type(values["contract_version"]) is not int or values["contract_version"] != 1:
            raise AssignmentError("Unsupported assignment contract version")
        if type(values["internal_version"]) is not int or values["internal_version"] != 6:
            raise AssignmentError("Assignment is not for Beta-6 internal version 6")
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
            "app_version": "0.2.0-beta.6",
            "model_id": "profile_height_v1+local_known_distance_v1",
            "product_id": "venu2plus",
            "consent_version": "beta6-consent-2026-10-23",
        }
        for name, expected in expected_identity.items():
            if values[name] != expected:
                raise AssignmentError(f"Assignment {name} is not the supported Beta-6 value")
        if not _RELEASE_ID.fullmatch(values["release_id"]):  # type: ignore[arg-type]
            raise AssignmentError("Assignment release ID is malformed or not Beta-6")

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
