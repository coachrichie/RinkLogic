"""Display-independent, local workflow for a Beta-7 tester return bundle."""

from __future__ import annotations

from dataclasses import dataclass, replace
from enum import Enum
from pathlib import Path
from typing import Mapping

from .assignment import Assignment
from .bundle import BundleResult, build_return_bundle
from .diagnostics import DiagnosticError, DiagnosticReport, inspect_original
from .questionnaire import FeedbackAnswers, validate_answers


class WizardStep(Enum):
    ASSIGNMENT = "assignment"
    EXPORT = "export"
    DIAGNOSTICS = "diagnostics"
    QUESTIONNAIRE = "questionnaire"
    RETURN = "return"


_DIAGNOSTIC_CODES = frozenset({
    "unreadable_input", "empty_input", "zip_unsafe_member_name",
    "zip_unsafe_member_type", "zip_nested_archive", "zip_executable_member",
    "zip_no_fit", "zip_multiple_fit", "zip_unexpected_member", "fit_too_large",
    "empty_fit", "unsupported_zip_compression", "corrupt_zip", "invalid_metric",
    "parser_error", "schema_mismatch", "missing_session_start", "invalid_duration",
    "unsupported_extension", "original_name_mismatch",
})

_SUMMARIES = {
    "ready_for_assignment": "Bitte wähle deinen Testauftrag aus.",
    "assignment_loaded": "Testauftrag geprüft. Bitte wähle den Originalexport aus.",
    "assignment_invalid": "Der Testauftrag konnte nicht geprüft werden.",
    "step_blocked": "Dieser Schritt ist noch nicht verfügbar.",
    "diagnostics_passed": "Originalexport geprüft. Bitte kontrolliere die Diagnose.",
    "diagnostics_failed": "Der Originalexport konnte nicht geprüft werden.",
    "diagnostics_blocked": "Bitte wähle einen gültigen Originalexport aus.",
    "questionnaire_ready": "Bitte beantworte die Fragen zum Test.",
    "answers_invalid": "Bitte prüfe deine Antworten.",
    "answers_valid": "Antworten geprüft. Das Rückgabepaket kann erstellt werden.",
    "bundle_failed": "Das Rückgabepaket konnte nicht erstellt werden.",
    "bundle_created": "Rückgabepaket erstellt. Bitte sende es bewusst über den privaten Kanal.",
}


@dataclass(frozen=True, slots=True)
class WizardState:
    """Read-only view of the current local wizard, with safe status text."""

    step: WizardStep = WizardStep.ASSIGNMENT
    assignment_path: Path | None = None
    assignment: Assignment | None = None
    original_path: Path | None = None
    diagnostics: DiagnosticReport | None = None
    diagnostic_code: str | None = None
    answers: FeedbackAnswers | None = None
    bundle: BundleResult | None = None
    status_key: str = "ready_for_assignment"
    status_summary: str = _SUMMARIES["ready_for_assignment"]


class BetaTestController:
    """Own transitions and validation; callers own all display and browser actions."""

    def __init__(self) -> None:
        self._state = WizardState()

    def state_snapshot(self) -> WizardState:
        return self._state

    def _status(self, key: str) -> WizardState:
        self._state = replace(self._state, status_key=key, status_summary=_SUMMARIES[key])
        return self._state

    def load_assignment(self, path: str | Path | None) -> WizardState:
        if path is None:
            return self._state
        try:
            selected = Path(path)
            assignment = Assignment.load(selected)
        except Exception:
            self._state = WizardState()
            return self._status("assignment_invalid")
        self._state = WizardState(step=WizardStep.EXPORT,
                                  assignment_path=selected, assignment=assignment)
        return self._status("assignment_loaded")

    def select_original(self, path: str | Path | None) -> WizardState:
        if path is None:
            return self._state
        if self._state.assignment is None:
            return self._status("step_blocked")
        self._state = replace(self._state, step=WizardStep.EXPORT,
                              original_path=None,
                              diagnostics=None, diagnostic_code=None, answers=None,
                              bundle=None)
        try:
            selected = Path(path)
        except Exception:
            self._state = replace(self._state, diagnostic_code="diagnostic_error")
            return self._status("diagnostics_failed")
        self._state = replace(self._state, original_path=selected)
        try:
            report = inspect_original(selected, self._state.assignment)
        except DiagnosticError as exc:
            code = exc.code if exc.code in _DIAGNOSTIC_CODES else "diagnostic_error"
            self._state = replace(self._state, diagnostic_code=code)
            return self._status("diagnostics_failed")
        except Exception:
            self._state = replace(self._state, diagnostic_code="diagnostic_error")
            return self._status("diagnostics_failed")
        if report.status != "pass" or report.codes:
            self._state = replace(self._state, diagnostic_code="diagnostic_error")
            return self._status("diagnostics_failed")
        self._state = replace(self._state, step=WizardStep.DIAGNOSTICS,
                              diagnostics=report)
        return self._status("diagnostics_passed")

    def continue_to_questionnaire(self) -> WizardState:
        if self._state.step != WizardStep.DIAGNOSTICS or self._state.diagnostics is None:
            return self._status("diagnostics_blocked" if self._state.step == WizardStep.DIAGNOSTICS
                                else "step_blocked")
        self._state = replace(self._state, step=WizardStep.QUESTIONNAIRE)
        return self._status("questionnaire_ready")

    def submit_answers(self, raw: Mapping[str, object]) -> WizardState:
        if self._state.step != WizardStep.QUESTIONNAIRE:
            return self._status("step_blocked")
        self._state = replace(self._state, answers=None, bundle=None)
        try:
            answers = validate_answers(raw)
        except Exception:
            return self._status("answers_invalid")
        self._state = replace(self._state, answers=answers)
        return self._status("answers_valid")

    def create_bundle(self, destination: str | Path | None) -> WizardState:
        if destination is None:
            return self._state
        state = self._state
        if (state.step != WizardStep.QUESTIONNAIRE or state.assignment is None
                or state.original_path is None or state.diagnostics is None
                or state.answers is None):
            return self._status("step_blocked")
        try:
            result = build_return_bundle(
                original_path=state.original_path,
                assignment=state.assignment,
                diagnostics=state.diagnostics,
                answers=state.answers,
                destination_dir=Path(destination),
            )
        except Exception:
            return self._status("bundle_failed")
        self._state = replace(self._state, step=WizardStep.RETURN, bundle=result)
        return self._status("bundle_created")

    def return_email(self) -> str | None:
        """Return the validated mailbox only after a local bundle exists."""
        if self._state.bundle is None or self._state.assignment is None:
            return None
        return self._state.assignment.return_email

    def reset(self) -> WizardState:
        """Forget controller state without touching any selected or generated file."""
        self._state = WizardState()
        return self._state
