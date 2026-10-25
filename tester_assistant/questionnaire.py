"""Offline, resource-backed beta feedback questions and safe answer validation."""

from __future__ import annotations

from dataclasses import dataclass
import json
from importlib import resources
from types import MappingProxyType
from typing import Mapping


class QuestionnaireError(ValueError):
    """Raised when questionnaire resources or answers violate the contract."""


@dataclass(frozen=True, slots=True)
class QuestionDefinition:
    """An immutable question definition loaded from the bundled German resource."""

    question_id: str
    prompt: str
    choices: tuple[int | str, ...] | None
    min_length: int | None = None
    max_length: int | None = None
    privacy_warning: str = ""


@dataclass(frozen=True, slots=True)
class FeedbackAnswers:
    """Validated questionnaire answers, containing no assignment/contact identity."""

    answers: Mapping[str, object]

    def to_safe_dict(self) -> dict[str, object]:
        """Return plain JSON-compatible data with free text left uninterpreted."""
        return dict(self.answers)


QUESTION_IDS = (
    "installation_ease",
    "instructions_clarity",
    "status_readability",
    "controls_reliability",
    "manual_shift_flow",
    "calibration_flow",
    "distance_explanation",
    "stability",
    "export_ease",
    "priority_improvement",
)
_RATING_CHOICES: tuple[int | str, ...] = (1, 2, 3, 4, 5, "not_applicable")
_OPTIONAL_ANSWER_ID = "problem_details"


def _load_resource() -> tuple[tuple[QuestionDefinition, ...], str]:
    try:
        raw = json.loads(
            resources.files("tester_assistant.resources")
            .joinpath("questionnaire.de.json")
            .read_text(encoding="utf-8")
        )
    except (OSError, UnicodeError, json.JSONDecodeError, ModuleNotFoundError) as exc:
        raise QuestionnaireError("Questionnaire resource is unavailable or invalid") from exc

    if not isinstance(raw, dict) or set(raw) != {
        "schema_version", "privacy_warning", "questions", "optional_answers"
    }:
        raise QuestionnaireError("Questionnaire resource has an invalid schema")
    if type(raw["schema_version"]) is not int or raw["schema_version"] != 1:
        raise QuestionnaireError("Questionnaire resource version is unsupported")
    warning = raw["privacy_warning"]
    if not isinstance(warning, str) or not warning.strip():
        raise QuestionnaireError("Questionnaire privacy warning is missing")
    raw_questions = raw["questions"]
    if not isinstance(raw_questions, list) or len(raw_questions) != len(QUESTION_IDS):
        raise QuestionnaireError("Questionnaire must define exactly ten questions")

    questions: list[QuestionDefinition] = []
    for index, item in enumerate(raw_questions):
        expected_id = QUESTION_IDS[index]
        if not isinstance(item, dict) or item.get("id") != expected_id:
            raise QuestionnaireError("Questionnaire IDs are invalid or out of order")
        question_id = item["id"]
        prompt = item.get("prompt")
        if not isinstance(prompt, str) or not prompt.strip():
            raise QuestionnaireError("Question prompt is missing")
        choices = item.get("choices")
        if index < 9:
            if set(item) != {"id", "prompt", "choices"} or choices != list(_RATING_CHOICES):
                raise QuestionnaireError("Rating question schema is invalid")
            frozen_choices = _RATING_CHOICES
            minimum = maximum = None
        else:
            if (
                set(item) != {"id", "prompt", "choices", "min_length", "max_length"}
                or choices is not None
                or type(item.get("min_length")) is not int
                or item["min_length"] != 3
                or type(item.get("max_length")) is not int
                or item["max_length"] != 500
            ):
                raise QuestionnaireError("Free-text question schema is invalid")
            frozen_choices = None
            minimum, maximum = 3, 500
        questions.append(QuestionDefinition(
            question_id, prompt, frozen_choices, minimum, maximum, warning
        ))

    optional = raw["optional_answers"]
    if optional != {
        _OPTIONAL_ANSWER_ID: {
            "question_id": "stability", "type": "string", "max_length": 1000
        }
    }:
        raise QuestionnaireError("Optional answer schema is invalid")
    return tuple(questions), warning


_QUESTIONS, _PRIVACY_WARNING = _load_resource()


def load_questions() -> tuple[QuestionDefinition, ...]:
    """Return the validated, ordered immutable questionnaire definitions."""
    return _QUESTIONS


def _normalized_text(value: object, field: str, maximum: int) -> str:
    if not isinstance(value, str):
        raise QuestionnaireError(f"{field} must be text")
    normalized = value.replace("\r\n", "\n").replace("\r", "\n").strip()
    if len(normalized) > maximum:
        raise QuestionnaireError(f"{field} is too long")
    if any((ord(char) < 32 and char != "\n") or ord(char) == 127 for char in normalized):
        raise QuestionnaireError(f"{field} contains control characters")
    return normalized


def validate_answers(raw: Mapping[str, object]) -> FeedbackAnswers:
    """Validate answer fields and preserve free text as inert JSON string data."""
    if not isinstance(raw, Mapping):
        raise QuestionnaireError("Answers must be a mapping")
    keys = set(raw)
    required = set(QUESTION_IDS)
    missing = required - keys
    extra = keys - required - {_OPTIONAL_ANSWER_ID}
    if missing or extra:
        raise QuestionnaireError("Answers have missing or unknown fields")
    if _OPTIONAL_ANSWER_ID in keys and "stability" not in keys:
        raise QuestionnaireError("Problem details require the stability answer")

    cleaned: dict[str, object] = {}
    for question_id in QUESTION_IDS[:9]:
        value = raw[question_id]
        if isinstance(value, str):
            value = _normalized_text(value, question_id, 20)
        if type(value) is int and 1 <= value <= 5:
            cleaned[question_id] = value
        elif value == "not_applicable" and isinstance(value, str):
            cleaned[question_id] = value
        else:
            raise QuestionnaireError(f"{question_id} must be a rating from 1 to 5 or not_applicable")

    improvement = _normalized_text(raw["priority_improvement"], "priority_improvement", 500)
    if len(improvement) < 3:
        raise QuestionnaireError("priority_improvement must contain at least 3 characters")
    cleaned["priority_improvement"] = improvement

    if _OPTIONAL_ANSWER_ID in keys:
        details = _normalized_text(raw[_OPTIONAL_ANSWER_ID], _OPTIONAL_ANSWER_ID, 1000)
        cleaned[_OPTIONAL_ANSWER_ID] = details

    return FeedbackAnswers(MappingProxyType(cleaned))
