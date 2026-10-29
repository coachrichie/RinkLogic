"""Return-bundle behavior with synthetic, private-free fixtures."""

from dataclasses import replace
import hashlib
import io
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch
import zipfile

from tester_assistant.assignment import Assignment
from tester_assistant.bundle import BundleError, build_return_bundle
from tester_assistant.diagnostics import DiagnosticReport
from tester_assistant.questionnaire import QUESTION_IDS, validate_answers
from tester_assistant_tests.fixtures import beta7_assignment_dict, beta7_original_name


FIT_BYTES = b"synthetic original FIT\x00\x01"


class BundleTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.destination = self.root / "return"
        self.destination.mkdir()
        self.assignment = Assignment.from_dict(beta7_assignment_dict())
        self.original = self.root / beta7_original_name()
        self.original.write_bytes(FIT_BYTES)
        self.diagnostics = self._report()
        self.answers = validate_answers({
            **{question_id: 4 for question_id in QUESTION_IDS[:9]},
            "priority_improvement": "Bessere Statusanzeige gewünscht.",
        })

    def _report(self, *, original=None, original_bytes=FIT_BYTES):
        original = original or self.original
        digest = hashlib.sha256(original_bytes).hexdigest()
        return DiagnosticReport(
            status="pass", codes=(), original_sha256=digest,
            fit_sha256=digest, original_name=original.name,
            fit_member_name=None, schema_version=12,
            session_start="2026-10-24 18:00:00+00:00",
            duration_minutes=3.0, manual_shift_count=10,
            estimated_distance_m=345.5, personal_calibration_factor=1.12,
            heart_rate_available=True,
            expected_prg_sha256=self.assignment.expected_prg_sha256,
            surface=self.assignment.surface, protocol=self.assignment.protocol,
            product_id=self.assignment.product_id,
            calibration_reference_distance_cm=2000,
            calibration_skate_only_runs=5,
            calibration_stickhandling_runs=5,
        )

    def _build(self, **overrides):
        args = dict(original_path=self.original, assignment=self.assignment,
                    diagnostics=self.diagnostics, answers=self.answers,
                    destination_dir=self.destination)
        args.update(overrides)
        return build_return_bundle(**args)

    def _assert_clean_failure(self, code, **overrides):
        before = set(self.destination.iterdir())
        with self.assertRaises(BundleError) as raised:
            self._build(**overrides)
        self.assertEqual(raised.exception.code, code)
        self.assertEqual(set(self.destination.iterdir()), before)

    def test_calibration_bundle_contains_exact_original_and_reference(self):
        result = self._build()
        self.assertEqual(result.path.name,
                         "TDEMO1-R1-001_2026-10-24_inline_calibration_return.zip")
        self.assertEqual(result.sha256, hashlib.sha256(result.path.read_bytes()).hexdigest())
        self.assertEqual(result.byte_size, result.path.stat().st_size)
        expected = {
            "manifest.json", "diagnostics.json", "feedback.json", "SHA256SUMS.txt",
            f"original/{self.original.name}",
            "reference/TDEMO1-R1-001_calibration_reference.csv",
        }
        self.assertEqual(set(result.member_names), expected)
        with zipfile.ZipFile(result.path) as archive:
            self.assertEqual(set(archive.namelist()), expected)
            self.assertEqual(archive.read(f"original/{self.original.name}"), FIT_BYTES)
            reference = archive.read("reference/TDEMO1-R1-001_calibration_reference.csv")
            manifest = json.loads(archive.read("manifest.json"))
            diagnostic = json.loads(archive.read("diagnostics.json"))
            feedback = json.loads(archive.read("feedback.json"))
            sums = archive.read("SHA256SUMS.txt").decode("ascii")
        self.assertEqual(manifest["assignment_id"], self.assignment.assignment_id)
        self.assertEqual(manifest["tester_id"], self.assignment.tester_id)
        self.assertEqual(manifest["original_sha256"], hashlib.sha256(FIT_BYTES).hexdigest())
        self.assertEqual(manifest["calibration_reference_source"],
                         "generated_from_validated_assignment_and_diagnostics")
        self.assertEqual(len(reference.decode("utf-8").splitlines()), 11)
        self.assertEqual(diagnostic["status"], "pass")
        self.assertEqual(feedback["priority_improvement"],
                         "Bessere Statusanzeige gewünscht.")
        self.assertNotIn("assignment_id", feedback)
        self.assertIn(f"{hashlib.sha256(FIT_BYTES).hexdigest()}  original/{self.original.name}\n", sums)
        all_text = json.dumps([manifest, diagnostic, feedback]) + sums
        self.assertNotIn(str(self.root), all_text)
        self.assertNotIn(self.assignment.upload_url, all_text)

    def test_noncalibration_bundle_omits_reference(self):
        values = beta7_assignment_dict()
        values["protocol"] = "smoke"
        assignment = Assignment.from_dict(values)
        original = self.root / self.original.name.replace("calibration", "smoke")
        original.write_bytes(FIT_BYTES)
        report = replace(
            self._report(original=original),
            personal_calibration_factor=None,
            protocol="smoke",
            calibration_reference_distance_cm=None,
            calibration_skate_only_runs=None,
            calibration_stickhandling_runs=None,
        )
        result = self._build(original_path=original, assignment=assignment,
                             diagnostics=report)
        self.assertEqual(result.path.name, "TDEMO1-R1-001_2026-10-24_inline_smoke_return.zip")
        with zipfile.ZipFile(result.path) as archive:
            self.assertFalse(any(name.startswith("reference/") for name in archive.namelist()))
            self.assertEqual(len(archive.namelist()), 5)

    def test_zip_export_is_nested_byte_for_byte_without_repacking(self):
        buffer = io.BytesIO()
        with zipfile.ZipFile(buffer, "w") as archive:
            archive.writestr("activity.fit", FIT_BYTES)
        original = self.root / beta7_original_name("zip")
        original.write_bytes(buffer.getvalue())
        report = replace(self._report(original=original, original_bytes=buffer.getvalue()),
                         fit_sha256=hashlib.sha256(FIT_BYTES).hexdigest(),
                         fit_member_name="activity.fit")
        result = self._build(original_path=original, diagnostics=report)
        with zipfile.ZipFile(result.path) as archive:
            self.assertEqual(archive.read(f"original/{original.name}"), buffer.getvalue())

    def test_rejects_nonpassing_or_identity_mismatched_diagnostics(self):
        cases = (
            (replace(self.diagnostics, status="fail"), "diagnostics_not_pass"),
            (replace(self.diagnostics, original_name="other.fit"), "identity_mismatch"),
            (replace(self.diagnostics, expected_prg_sha256="a" * 64), "identity_mismatch"),
            (replace(self.diagnostics, schema_version=11), "identity_mismatch"),
            (replace(self.diagnostics, surface="ice"), "identity_mismatch"),
            (replace(self.diagnostics, protocol="smoke"), "identity_mismatch"),
            (replace(self.diagnostics, product_id="fenix7"), "identity_mismatch"),
        )
        for report, code in cases:
            with self.subTest(code=code, report=report):
                self._assert_clean_failure(code, diagnostics=report)

    def test_rejects_changed_original_after_inspection(self):
        self.original.write_bytes(b"modified after inspection")
        self._assert_clean_failure("original_changed")

    def test_generated_reference_failure_is_atomic(self):
        self._assert_clean_failure(
            "invalid_calibration_reference",
            diagnostics=replace(self.diagnostics, personal_calibration_factor=None),
        )

    def test_rejects_destination_equal_to_original_or_nested_beneath_it(self):
        self._assert_clean_failure("unsafe_destination", destination_dir=self.original)
        self._assert_clean_failure("unsafe_destination", destination_dir=self.original / "nested")

    def test_existing_output_is_never_overwritten(self):
        target = self.destination / "TDEMO1-R1-001_2026-10-24_inline_calibration_return.zip"
        target.write_bytes(b"previous bundle")
        self._assert_clean_failure("output_exists")
        self.assertEqual(target.read_bytes(), b"previous bundle")

    def test_zip_write_failure_leaves_no_output_or_temporary_file(self):
        with patch("tester_assistant.bundle.zipfile.ZipFile.writestr",
                   side_effect=OSError("secret path C:/private/export.fit")):
            self._assert_clean_failure("bundle_write_failed")

    def test_finalization_failure_after_publication_removes_final_and_temporary(self):
        with patch("tester_assistant.bundle.BundleResult",
                   side_effect=RuntimeError("failure after publication")):
            self._assert_clean_failure("bundle_write_failed")

    def test_rejects_contact_or_local_path_in_feedback_text(self):
        for index, text in enumerate(("Kontakt: person@example.invalid",
                                      r"Log: C:\Users\Tester\run.fit",
                                      "path=/home/tester/run.fit",
                                      "AWS_SECRET_ACCESS_KEY=abc123")):
            with self.subTest(text=text):
                self.destination = self.root / f"feedback-{index}"
                self.destination.mkdir()
                raw = self.answers.to_safe_dict()
                raw["priority_improvement"] = text
                self._assert_clean_failure("unsafe_feedback", answers=validate_answers(raw))

if __name__ == "__main__":
    unittest.main()
