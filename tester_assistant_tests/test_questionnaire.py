"""Behavioral contract tests for the ten-question beta feedback form."""

import unittest

from tester_assistant.questionnaire import (
    QUESTION_IDS,
    QuestionnaireError,
    load_questions,
    validate_answers,
)


EXPECTED_QUESTIONS = (
    ("installation_ease", "Wie einfach war die Installation der Beta-App?"),
    ("instructions_clarity", "Wie verständlich waren die Testanweisungen?"),
    ("status_readability", "Wie gut waren Status, Version und Hinweise auf der Uhr lesbar?"),
    ("controls_reliability", "Wie zuverlässig funktionierten Tasten und Touch während des Tests?"),
    ("manual_shift_flow", "Wie verständlich und zuverlässig war das manuelle Markieren von Eis- und Bankphasen?"),
    ("calibration_flow", "Wie verständlich war der Kalibrierungsablauf?"),
    ("distance_explanation", "Wie verständlich war die Kennzeichnung der Distanz als experimentelle Schätzung?"),
    ("stability", "Wie stabil lief die App ohne Absturz, IQ!-Fehler oder Datenverlust?"),
    ("export_ease", "Wie einfach war der Export der Originaldatei aus Garmin Connect?"),
    ("priority_improvement", "Welche eine Verbesserung ist für dich am wichtigsten?"),
)


def valid_answers() -> dict[str, object]:
    return {
        **{question_id: 4 for question_id in QUESTION_IDS[:9]},
        "priority_improvement": "Die Statusanzeige könnte kontrastreicher sein.",
    }


class QuestionnaireTests(unittest.TestCase):
    def test_loads_exactly_ten_questions_in_the_required_order_and_wording(self):
        questions = load_questions()

        self.assertEqual(len(questions), 10)
        self.assertEqual(QUESTION_IDS, tuple(question_id for question_id, _ in EXPECTED_QUESTIONS))
        self.assertEqual(
            tuple((question.question_id, question.prompt) for question in questions),
            EXPECTED_QUESTIONS,
        )
        self.assertEqual(len(set(QUESTION_IDS)), 10)
        for question in questions[:9]:
            self.assertEqual(question.choices, (1, 2, 3, 4, 5, "not_applicable"))
        self.assertIsNone(questions[9].choices)
        self.assertIn("Namen", questions[0].privacy_warning)

    def test_validates_and_normalizes_answers_without_contact_fields(self):
        raw = valid_answers()
        raw["stability"] = "  not_applicable  "
        raw["problem_details"] = "  Uhr blieb stehen\r\nund startete neu.  "

        feedback = validate_answers(raw)
        safe = feedback.to_safe_dict()

        self.assertEqual(safe["stability"], "not_applicable")
        self.assertEqual(safe["problem_details"], "Uhr blieb stehen\nund startete neu.")
        self.assertEqual(safe["priority_improvement"], raw["priority_improvement"])
        self.assertEqual(set(safe), set(QUESTION_IDS) | {"problem_details"})
        self.assertNotIn("assignment_id", safe)
        self.assertNotIn("tester_id", safe)
        with self.assertRaises((AttributeError, TypeError)):
            feedback.answers["stability"] = 1

    def test_rejects_missing_answers_and_extra_question_ids(self):
        missing = valid_answers()
        del missing["export_ease"]
        extra = valid_answers()
        extra["contact_email"] = "tester@example.invalid"

        for raw in (missing, extra):
            with self.subTest(raw=raw), self.assertRaises(QuestionnaireError):
                validate_answers(raw)

    def test_rejects_boolean_and_out_of_range_ratings(self):
        for value in (True, False, 0, 6, 1.5, "4"):
            raw = valid_answers()
            raw["installation_ease"] = value
            with self.subTest(value=value), self.assertRaises(QuestionnaireError):
                validate_answers(raw)

    def test_rejects_blank_or_oversized_improvement_and_oversized_details(self):
        for value in ("  \n ", "x" * 501):
            raw = valid_answers()
            raw["priority_improvement"] = value
            with self.subTest(value_length=len(value)), self.assertRaises(QuestionnaireError):
                validate_answers(raw)

        raw = valid_answers()
        raw["problem_details"] = "x" * 1001
        with self.assertRaises(QuestionnaireError):
            validate_answers(raw)

    def test_rejects_problem_details_without_stability_answer(self):
        raw = valid_answers()
        del raw["stability"]
        raw["problem_details"] = "Absturz nach dem Spiel."

        with self.assertRaises(QuestionnaireError):
            validate_answers(raw)

    def test_rejects_nul_and_disallowed_control_characters(self):
        for value in ("Verbesserung\x00", "Fehler\x1bbericht", "Fehler\x7fbericht"):
            raw = valid_answers()
            raw["priority_improvement"] = value
            with self.subTest(value=repr(value)), self.assertRaises(QuestionnaireError):
                validate_answers(raw)

    def test_rejects_nested_objects_and_non_string_details(self):
        raw = valid_answers()
        raw["problem_details"] = {"message": "please interpret me"}
        with self.assertRaises(QuestionnaireError):
            validate_answers(raw)

        raw = valid_answers()
        raw["priority_improvement"] = ["not", "text"]
        with self.assertRaises(QuestionnaireError):
            validate_answers(raw)

    def test_preserves_html_and_windows_paths_as_inert_text(self):
        html = "<script>alert('x')</script>"
        windows_path = r"C:\Users\Tester\Documents\original.fit"
        raw = valid_answers()
        raw["priority_improvement"] = f"{html} {windows_path}"

        safe = validate_answers(raw).to_safe_dict()

        self.assertEqual(safe["priority_improvement"], f"{html} {windows_path}")


if __name__ == "__main__":
    unittest.main()
