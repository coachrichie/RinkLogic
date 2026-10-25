"""Window-free contracts for the German beta assistant UI."""

from __future__ import annotations

from dataclasses import replace
from io import StringIO
import json
import unittest
from unittest.mock import patch

from tester_assistant.app import (
    button_state, diagnostic_message, diagnostic_rows, main, privacy_text,
    questionnaire_items, rating_label, step_title, validated_upload_url,
    selection_texts,
    bind_questionnaire_wheel,
)
from tester_assistant.bundle import BundleResult
from tester_assistant.controller import BetaTestController, WizardState, WizardStep
from tester_assistant.diagnostics import DiagnosticReport
from tester_assistant.questionnaire import QUESTION_IDS, validate_answers
from tester_assistant_tests.fixtures import beta6_assignment_dict, beta6_original_name, pilot_result
from pathlib import Path
import tempfile


class AppContractTests(unittest.TestCase):
    def test_five_german_step_titles_follow_workflow(self):
        self.assertEqual([step_title(step) for step in WizardStep], [
            "1. Testauftrag", "2. Originalexport", "3. Diagnose",
            "4. Fragebogen", "5. Rückgabe",
        ])

    def test_questionnaire_has_exactly_ten_numbered_questions_in_resource_order(self):
        items = questionnaire_items()
        self.assertEqual([item[0] for item in items], list(range(1, 11)))
        self.assertEqual([item[1].question_id for item in items], list(QUESTION_IDS))
        self.assertTrue(items[0][1].prompt.startswith("Wie einfach"))
        self.assertTrue(items[-1][1].prompt.startswith("Welche eine Verbesserung"))

    def test_diagnostic_messages_and_rating_labels_are_human_readable(self):
        self.assertIn("Dateiname", diagnostic_message("original_name_mismatch"))
        self.assertIn("nicht", diagnostic_message("unknown_new_code").lower())
        self.assertEqual([rating_label(i) for i in (1, 2, 3, 4, 5, "not_applicable")],
                         ["1", "2", "3", "4", "5", "Nicht zutreffend"])

    def test_privacy_text_warns_before_free_text(self):
        warning = privacy_text()
        for word in ("Namen", "E-Mail-Adressen", "Gesundheitsangaben", "Dritte"):
            self.assertIn(word, warning)

    def test_navigation_and_upload_button_state_are_gated_by_controller_state(self):
        initial = WizardState()
        self.assertFalse(button_state(initial)["next"])
        self.assertFalse(button_state(initial)["open_upload"])
        questionnaire = replace(initial, step=WizardStep.QUESTIONNAIRE)
        self.assertTrue(button_state(questionnaire)["back"])
        self.assertFalse(button_state(questionnaire)["open_upload"])
        bundle = BundleResult(Path("bundle.zip"), "a" * 64, 123, ("feedback.json",))
        final = replace(questionnaire, step=WizardStep.RETURN, bundle=bundle)
        self.assertTrue(button_state(final)["open_upload"])
        self.assertFalse(button_state(final)["next"])

    def test_selection_summary_clears_stale_paths_after_controller_reset(self):
        chosen = replace(WizardState(), assignment_path=Path("assignment.json"),
                         original_path=Path("original.fit"))
        self.assertIn("assignment.json", selection_texts(chosen)["assignment"])
        reset = selection_texts(WizardState())
        self.assertEqual(reset["assignment"], "Kein Testauftrag ausgewählt.")
        self.assertEqual(reset["original"], "Kein Originalexport ausgewählt.")
        self.assertEqual(reset["reference"], "Keine Referenz ausgewählt.")

    def test_diagnostics_uses_unavailable_for_absent_measurements(self):
        report = DiagnosticReport("pass", (), "a" * 64, "b" * 64, "original.fit", None,
                                  12, "2026-10-24 18:00:00+00:00", 3.0, 2, None, None,
                                  False, "c" * 64)
        rows = dict(diagnostic_rows(report))
        for label in ("Original SHA-256", "FIT SHA-256", "Schema", "Beginn",
                      "Dauer", "Manuelle Shifts", "Geschätzte Distanz",
                      "Persönlicher Faktor", "Herzfrequenz"):
            self.assertIn(label, rows)
        self.assertEqual(rows["Geschätzte Distanz"], "Nicht verfügbar")
        self.assertEqual(rows["Persönlicher Faktor"], "Nicht verfügbar")
        self.assertEqual(rows["Herzfrequenz"], "Nicht verfügbar")

    def test_upload_url_is_only_returned_for_existing_bundle_and_https(self):
        self.assertIsNone(validated_upload_url(None, None))
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "bundle.zip"
            bundle = BundleResult(path, "a" * 64, 123, ())
            self.assertIsNone(validated_upload_url(bundle, "https://example.invalid/upload"))
            path.write_bytes(b"synthetic bundle")
            self.assertIsNone(validated_upload_url(bundle, "http://example.invalid/upload"))
            self.assertIsNone(validated_upload_url(bundle, "https://example.invalid@evil.invalid/upload"))
            self.assertEqual(validated_upload_url(bundle, "https://example.invalid/upload"),
                             "https://example.invalid/upload")

    def test_bundle_action_revalidates_current_questionnaire_text(self):
        from tester_assistant.app import BetaTestApp

        class Controller:
            def __init__(self):
                self.checked = None
                self.created = False
                self.state = replace(WizardState(), step=WizardStep.QUESTIONNAIRE,
                                     answers=object())

            def state_snapshot(self):
                return self.state

            def submit_answers(self, answers):
                self.checked = answers
                self.state = replace(self.state, answers=None)
                return self.state

            def create_bundle(self, _destination):
                self.created = True
                return self.state

        controller = Controller()
        app = object.__new__(BetaTestApp)
        app.root = object()
        app.controller = controller
        app.view_step = WizardStep.QUESTIONNAIRE
        app._raw_answers = lambda: {"priority_improvement": "edited value"}
        app._refresh = lambda: None
        with patch("tester_assistant.app.filedialog.askdirectory", return_value="destination"), \
             patch("tester_assistant.app.messagebox.askyesno", return_value=False):
            app._next()
        self.assertEqual(controller.checked, {"priority_improvement": "edited value"})
        self.assertFalse(controller.created)

    def test_rating_controls_produce_validated_integer_answers(self):
        from tester_assistant.app import BetaTestApp

        class Value:
            def __init__(self, value):
                self.value = value

            def get(self, *_args):
                return self.value

        app = object.__new__(BetaTestApp)
        app.rating_vars = {question_id: Value(str(index % 5 + 1))
                           for index, question_id in enumerate(QUESTION_IDS[:9])}
        app.rating_vars[QUESTION_IDS[2]] = Value("Nicht zutreffend")
        app.improvement = Value("Bessere Statusanzeige")
        app.problem_details = Value("")
        raw = app._raw_answers()
        self.assertEqual(raw[QUESTION_IDS[0]], 1)
        self.assertEqual(raw[QUESTION_IDS[2]], "not_applicable")
        self.assertEqual(validate_answers(raw).to_safe_dict(), raw)

    def test_back_next_review_keeps_controller_and_page_in_sync(self):
        from tester_assistant.app import BetaTestApp

        with tempfile.TemporaryDirectory() as directory, \
             patch("tester_assistant.diagnostics.load_pilot_fit", return_value=pilot_result()):
            root = Path(directory)
            assignment = beta6_assignment_dict()
            assignment["protocol"] = "smoke"
            assignment_path = root / "assignment.json"
            assignment_path.write_text(json.dumps(assignment), encoding="utf-8")
            original = root / beta6_original_name().replace("calibration", "smoke")
            original.write_bytes(b"synthetic FIT bytes")
            controller = BetaTestController()
            controller.load_assignment(assignment_path)
            controller.select_original(original)
            controller.continue_to_questionnaire()
            app = object.__new__(BetaTestApp)
            app.controller = controller
            app.view_step = WizardStep.QUESTIONNAIRE
            app._refresh = lambda: None
            app.root = object()

            app._back()
            self.assertEqual(app.view_step, WizardStep.DIAGNOSTICS)
            with patch.object(controller, "continue_to_questionnaire", side_effect=AssertionError("duplicate transition")):
                app._next()
            self.assertEqual(app.view_step, WizardStep.QUESTIONNAIRE)
            self.assertEqual(controller.state_snapshot().status_key, "questionnaire_ready")

            answers = {question_id: 3 for question_id in QUESTION_IDS[:9]}
            answers["priority_improvement"] = "Bessere Statusanzeige"
            controller.submit_answers(answers)
            state = controller.create_bundle(root)
            self.assertEqual(state.step, WizardStep.RETURN)
            app.view_step = WizardStep.RETURN
            with patch("tester_assistant.app.filedialog.askdirectory", side_effect=AssertionError("duplicate bundle prompt")):
                app._back()
                app._next()
            self.assertEqual(app.view_step, WizardStep.RETURN)
            self.assertEqual(controller.state_snapshot().step, WizardStep.RETURN)

    def test_wheel_scrolls_over_questionnaire_children_without_global_binding(self):
        class Widget:
            def __init__(self, *children):
                self.children = children
                self.bindings = {}
                self.scrolls = []

            def bind(self, sequence, callback):
                self.bindings[sequence] = callback

            def bind_all(self, *_args):
                raise AssertionError("global wheel binding would leak")

            def winfo_children(self):
                return self.children

            def yview_scroll(self, amount, unit):
                self.scrolls.append((amount, unit))

        control = Widget()
        nested = Widget(control)
        content = Widget(nested)
        canvas = Widget()
        outside = Widget()
        bind_questionnaire_wheel(canvas, content)
        self.assertNotIn("<MouseWheel>", outside.bindings)
        self.assertIn("<MouseWheel>", control.bindings)
        self.assertIn("<MouseWheel>", canvas.bindings)
        control.bindings["<MouseWheel>"](type("Event", (), {"delta": -120})())
        self.assertEqual(canvas.scrolls, [(1, "units")])

    def test_browser_handoff_requires_bundle_file_and_explicit_confirmation(self):
        from tester_assistant.app import BetaTestApp

        class Controller:
            def __init__(self, bundle):
                self.state = replace(WizardState(), step=WizardStep.RETURN, bundle=bundle)

            def state_snapshot(self):
                return self.state

            def upload_url(self):
                return "https://example.invalid/upload"

        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "bundle.zip"
            bundle = BundleResult(path, "a" * 64, 123, ())
            app = object.__new__(BetaTestApp)
            app.root = object()
            app.controller = Controller(bundle)
            with patch("tester_assistant.app.webbrowser.open") as browser, \
                 patch("tester_assistant.app.messagebox.showerror"):
                app._open_upload()
                browser.assert_not_called()
                path.write_bytes(b"synthetic bundle")
                with patch("tester_assistant.app.messagebox.askyesno", return_value=False):
                    app._open_upload()
                browser.assert_not_called()
                with patch("tester_assistant.app.messagebox.askyesno", return_value=True):
                    app._open_upload()
                browser.assert_called_once_with("https://example.invalid/upload")

    def test_self_check_cli_does_not_create_tk_or_open_network(self):
        output = StringIO()
        with patch("tkinter.Tk", side_effect=AssertionError("Tk created")), \
             patch("webbrowser.open", side_effect=AssertionError("browser opened")), \
             patch("sys.stdout", output):
            self.assertEqual(main(["--self-check"]), 0)
        self.assertIn("self_check", output.getvalue())


if __name__ == "__main__":
    unittest.main()
