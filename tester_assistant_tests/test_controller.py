"""Wizard transitions using synthetic assignments and parser-shaped FIT data."""

from __future__ import annotations

import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

from tester_assistant.controller import BetaTestController, WizardStep
from tester_assistant.questionnaire import QUESTION_IDS
from tester_assistant_tests.fixtures import (
    beta6_assignment_dict, beta6_original_name, pilot_result,
)


class ControllerTests(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name)
        self.assignment_path = self.root / "assignment.json"
        self.assignment_path.write_text(json.dumps(beta6_assignment_dict()), encoding="utf-8")
        self.original = self.root / beta6_original_name()
        self.original.write_bytes(b"synthetic FIT bytes")
        self.destination = self.root / "return"
        self.destination.mkdir()
        self.parser = patch("tester_assistant.diagnostics.load_pilot_fit", return_value=pilot_result())
        self.parser.start()
        self.addCleanup(self.parser.stop)
        self.controller = BetaTestController()

    def _answers(self):
        return {
            **{question_id: 4 for question_id in QUESTION_IDS[:9]},
            "priority_improvement": "Bessere Statusanzeige gewünscht.",
        }

    def _reach_questionnaire(self):
        self.controller.load_assignment(self.assignment_path)
        self.controller.select_original(self.original)
        self.controller.continue_to_questionnaire()

    def test_initial_state_and_step_gates(self):
        self.assertEqual(self.controller.state_snapshot().step, WizardStep.ASSIGNMENT)
        self.assertEqual(self.controller.select_original(self.original).step, WizardStep.ASSIGNMENT)
        self.assertEqual(self.controller.submit_answers(self._answers()).step, WizardStep.ASSIGNMENT)
        self.assertEqual(self.controller.create_bundle(self.destination).step, WizardStep.ASSIGNMENT)
        self.assertIsNone(self.controller.return_email())
        self.assertEqual(list(self.destination.iterdir()), [])

    def test_successful_validation_visits_each_step_and_builds_bundle(self):
        self.assertEqual(self.controller.load_assignment(self.assignment_path).step, WizardStep.EXPORT)
        self.assertEqual(self.controller.select_original(self.original).step, WizardStep.DIAGNOSTICS)
        self.assertEqual(self.controller.continue_to_questionnaire().step, WizardStep.QUESTIONNAIRE)
        self.controller.submit_answers(self._answers())
        state = self.controller.create_bundle(self.destination)
        self.assertEqual(state.step, WizardStep.RETURN)
        self.assertEqual(state.bundle.path.read_bytes()[:2], b"PK")
        self.assertEqual(self.controller.return_email(), "rinklogic@example.invalid")

    def test_failed_diagnostic_is_safe_and_blocks_progress(self):
        self.controller.load_assignment(self.assignment_path)
        bad_original = self.root / "C-Users-secret_original.fit"
        bad_original.write_bytes(b"private content")
        state = self.controller.select_original(bad_original)
        self.assertEqual(state.step, WizardStep.EXPORT)
        self.assertEqual(state.diagnostic_code, "original_name_mismatch")
        self.assertIsNone(state.diagnostics)
        self.assertEqual(state.status_key, "diagnostics_failed")
        self.assertNotIn(str(self.root), state.status_summary)
        self.assertEqual(self.controller.continue_to_questionnaire().step, WizardStep.EXPORT)
        self.assertEqual(self.controller.state_snapshot().status_key, "step_blocked")
        self.assertEqual(self.controller.create_bundle(self.destination).step, WizardStep.EXPORT)
        self.assertEqual(list(self.destination.iterdir()), [])

    def test_unexpected_diagnostic_exception_is_redacted(self):
        self.controller.load_assignment(self.assignment_path)
        with patch("tester_assistant.controller.inspect_original",
                   side_effect=RuntimeError("secret C:/private/activity.fit")):
            state = self.controller.select_original(self.original)
        self.assertEqual(state.diagnostic_code, "diagnostic_error")
        self.assertNotIn("secret", repr(state))
        self.assertNotIn("C:/private/activity.fit", repr(state))

    def test_calibration_reference_is_generated_only_for_calibration(self):
        self._reach_questionnaire()
        self.controller.submit_answers(self._answers())
        state = self.controller.create_bundle(self.destination)
        self.assertEqual(state.step, WizardStep.RETURN)

        smoke = beta6_assignment_dict()
        smoke["protocol"] = "smoke"
        self.assignment_path.write_text(json.dumps(smoke), encoding="utf-8")
        smoke_original = self.root / beta6_original_name().replace("calibration", "smoke")
        smoke_original.write_bytes(b"synthetic smoke FIT")
        self.controller.load_assignment(self.assignment_path)
        self.controller.select_original(smoke_original)
        self.controller.continue_to_questionnaire()
        self.controller.submit_answers(self._answers())
        self.assertEqual(self.controller.create_bundle(self.destination).step, WizardStep.RETURN)

    def test_none_cancellations_are_exact_no_ops(self):
        self._reach_questionnaire()
        self.controller.submit_answers(self._answers())
        before = self.controller.state_snapshot()
        for action in (self.controller.load_assignment, self.controller.select_original,
                       self.controller.create_bundle):
            self.assertEqual(action(None), before)
            self.assertEqual(self.controller.state_snapshot(), before)

    def test_replacing_assignment_clears_every_downstream_value(self):
        self._reach_questionnaire()
        self.controller.submit_answers(self._answers())
        self.controller.create_bundle(self.destination)
        second = self.root / "second.json"
        second.write_text(json.dumps(beta6_assignment_dict()), encoding="utf-8")
        state = self.controller.load_assignment(second)
        self.assertEqual(state.step, WizardStep.EXPORT)
        self.assertEqual(state.assignment_path, second)
        self.assertIsNone(state.original_path)
        self.assertIsNone(state.diagnostics)
        self.assertIsNone(state.answers)
        self.assertIsNone(state.bundle)
        self.assertIsNone(state.diagnostic_code)

    def test_replacing_original_invalidates_diagnostics_answers_and_bundle(self):
        self._reach_questionnaire()
        self.controller.submit_answers(self._answers())
        self.controller.create_bundle(self.destination)
        other = self.root / beta6_original_name("zip")
        other.write_bytes(b"not a ZIP")
        state = self.controller.select_original(other)
        self.assertEqual(state.step, WizardStep.EXPORT)
        self.assertEqual(state.diagnostic_code, "corrupt_zip")
        self.assertIsNone(state.diagnostics)
        self.assertIsNone(state.answers)
        self.assertIsNone(state.bundle)
        self.assertIsNone(self.controller.return_email())

    def test_invalid_replacement_path_clears_earlier_bundle_state(self):
        self._reach_questionnaire()
        self.controller.submit_answers(self._answers())
        self.controller.create_bundle(self.destination)
        state = self.controller.select_original(object())
        self.assertEqual(state.step, WizardStep.EXPORT)
        self.assertEqual(state.diagnostic_code, "diagnostic_error")
        self.assertIsNone(state.original_path)
        self.assertIsNone(state.diagnostics)
        self.assertIsNone(state.answers)
        self.assertIsNone(state.bundle)
        self.assertIsNone(self.controller.return_email())

    def test_correcting_blocked_input_then_retrying_succeeds(self):
        self.controller.load_assignment(self.assignment_path)
        invalid = self.root / "wrong.fit"
        invalid.write_bytes(b"invalid")
        failed = self.controller.select_original(invalid)
        self.assertEqual(failed.step, WizardStep.EXPORT)
        self.assertEqual(failed.diagnostic_code, "original_name_mismatch")
        retried = self.controller.select_original(self.original)
        self.assertEqual(retried.step, WizardStep.DIAGNOSTICS)
        self.assertIsNone(retried.diagnostic_code)
        self.controller.continue_to_questionnaire()
        bad_answers = self._answers()
        bad_answers["installation_ease"] = 9
        self.assertEqual(self.controller.submit_answers(bad_answers).status_key,
                         "answers_invalid")
        self.assertIsNone(self.controller.state_snapshot().answers)
        self.assertIsNotNone(self.controller.submit_answers(self._answers()).answers)

    def test_reset_and_restart_leave_existing_files_untouched(self):
        self._reach_questionnaire()
        self.controller.submit_answers(self._answers())
        bundle = self.controller.create_bundle(self.destination).bundle.path
        before = bundle.read_bytes()
        self.controller.reset()
        state = self.controller.state_snapshot()
        self.assertEqual(state.step, WizardStep.ASSIGNMENT)
        self.assertIsNone(state.assignment_path)
        self.assertIsNone(state.original_path)
        self.assertIsNone(state.diagnostics)
        self.assertIsNone(state.answers)
        self.assertIsNone(state.bundle)
        restarted = BetaTestController()
        self.assertEqual(restarted.state_snapshot().step, WizardStep.ASSIGNMENT)
        self.assertEqual(bundle.read_bytes(), before)
        self.assertEqual(sorted(self.destination.iterdir()), [bundle])


if __name__ == "__main__":
    unittest.main()
