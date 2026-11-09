"""Synthetic end-to-end evidence for the offline Beta-7 tester workflow."""

from __future__ import annotations

import hashlib
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch
import zipfile

from analysis.calibration_report import read_calibration_manifest
from tester_assistant.controller import BetaTestController, WizardStep
from tester_assistant.questionnaire import QUESTION_IDS
from tester_assistant_tests.fixtures import pilot_result


SYNTHETIC_PRG_SHA256 = "A" * 64


def _assignment(*, tester_id: str, product_id: str, surface: str,
                protocol: str = "calibration") -> dict[str, object]:
    return {
        "contract_version": 2,
        "tester_id": tester_id,
        "assignment_id": f"{tester_id}-R1-001",
        "release_id": "RL-B7-20261107-7FEF470",
        "app_version": "0.2.0-beta.7",
        "internal_version": 7,
        "fit_schema": 12,
        "model_id": "profile_height_v1+local_known_distance_v1",
        "product_id": product_id,
        "surface": surface,
        "protocol": protocol,
        # Assignments bind the extracted device-specific PRG, not the IQ
        # container hash documented for the coordinator.
        "expected_prg_sha256": SYNTHETIC_PRG_SHA256,
        "upload_url": "https://example.invalid/private-return",
        "consent_version": "beta6-consent-2026-10-23",
    }


def _answers() -> dict[str, object]:
    return {
        **{question_id: 4 for question_id in QUESTION_IDS[:9]},
        "priority_improvement": "Kalibrierungsstatus deutlicher anzeigen.",
    }


class Beta7SyntheticEndToEndTests(unittest.TestCase):
    def setUp(self) -> None:
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name)

    def _run_flow(self, *, tester_id: str, product_id: str, surface: str,
                  protocol: str = "calibration", manual_shift_count: int = 10,
                  factor: object = 1.125) -> tuple[Path, bytes]:
        values = _assignment(tester_id=tester_id, product_id=product_id,
                             surface=surface, protocol=protocol)
        assignment_path = self.root / f"{tester_id}-{protocol}-assignment.json"
        assignment_path.write_text(json.dumps(values), encoding="utf-8")
        original_bytes = f"synthetic-{surface}-{protocol}-original".encode("ascii")
        original = self.root / (
            f"{values['assignment_id']}_2026-10-24_{surface}_{protocol}_original.fit"
        )
        original.write_bytes(original_bytes)
        destination = self.root / f"{tester_id}-{protocol}-return"
        destination.mkdir()

        controller = BetaTestController()
        # The FIT decoder is the only business-logic boundary replaced. Network
        # mocks are tripwires proving the local workflow never attempts a call.
        with (
            patch("tester_assistant.diagnostics.load_pilot_fit", return_value=pilot_result(
                manual_shift_count=manual_shift_count,
                personal_calibration_factor=factor,
            )),
            patch("socket.create_connection", side_effect=AssertionError("network call"))
                as connect,
            patch("urllib.request.urlopen", side_effect=AssertionError("network call"))
                as urlopen,
        ):
            self.assertEqual(controller.load_assignment(assignment_path).step,
                             WizardStep.EXPORT)
            self.assertEqual(controller.select_original(original).step,
                             WizardStep.DIAGNOSTICS)
            self.assertEqual(controller.continue_to_questionnaire().step,
                             WizardStep.QUESTIONNAIRE)
            self.assertEqual(len(_answers()), 10)
            controller.submit_answers(_answers())
            state = controller.create_bundle(destination)
            self.assertEqual(state.step, WizardStep.RETURN)
            self.assertIsNotNone(state.bundle)
            self.assertEqual(controller.upload_url(), values["upload_url"])
            connect.assert_not_called()
            urlopen.assert_not_called()

        return state.bundle.path, original_bytes  # type: ignore[union-attr]

    def _assert_archive_hashes(self, archive: zipfile.ZipFile) -> None:
        listed: dict[str, str] = {}
        for line in archive.read("SHA256SUMS.txt").decode("ascii").splitlines():
            digest, member = line.split("  ", 1)
            listed[member] = digest
        expected_members = set(archive.namelist()) - {"SHA256SUMS.txt"}
        self.assertEqual(set(listed), expected_members)
        for member, digest in listed.items():
            self.assertEqual(hashlib.sha256(archive.read(member)).hexdigest(), digest)

    def test_ice_and_inline_calibrations_are_isolated_and_analysis_valid(self):
        cases = (
            ("TICE01", "venu2plus", "ice"),
            ("TINL01", "fr255s", "inline"),
        )
        for tester_id, product_id, surface in cases:
            with self.subTest(surface=surface, product_id=product_id):
                bundle, original_bytes = self._run_flow(
                    tester_id=tester_id, product_id=product_id, surface=surface)
                assignment_id = f"{tester_id}-R1-001"
                original_name = (
                    f"{assignment_id}_2026-10-24_{surface}_calibration_original.fit"
                )
                reference_name = f"reference/{assignment_id}_calibration_reference.csv"
                expected = {
                    "manifest.json", "diagnostics.json", "feedback.json",
                    "SHA256SUMS.txt", f"original/{original_name}", reference_name,
                }
                with zipfile.ZipFile(bundle) as archive:
                    self.assertEqual(set(archive.namelist()), expected)
                    self.assertEqual(archive.read(f"original/{original_name}"),
                                     original_bytes)
                    self._assert_archive_hashes(archive)
                    reference = archive.read(reference_name)
                    manifest = json.loads(archive.read("manifest.json"))
                reference_path = self.root / f"{tester_id}-reference.csv"
                reference_path.write_bytes(reference)
                rows = read_calibration_manifest(reference_path)
                self.assertEqual(len(rows), 10)
                self.assertEqual({row["sport"] for row in rows}, {surface})
                self.assertEqual([row["reference_distance_cm"] for row in rows],
                                 [2000] * 10)
                self.assertEqual([row["condition"] for row in rows],
                                 ["skate_only"] * 5 + ["puck_stickhandling"] * 5)
                self.assertEqual([row["target_pace"] for row in rows],
                                 ["slow", "fast", "normal", "slow", "fast"] * 2)
                self.assertEqual(manifest["surface"], surface)
                self.assertEqual(manifest["product_id"], product_id)

    def test_normal_training_bundle_has_no_calibration_reference(self):
        bundle, original_bytes = self._run_flow(
            tester_id="TTRN01", product_id="fenix9pro51mm", surface="ice",
            protocol="normal-training", manual_shift_count=3, factor=None,
        )
        original_name = (
            "TTRN01-R1-001_2026-10-24_ice_normal-training_original.fit"
        )
        expected = {
            "manifest.json", "diagnostics.json", "feedback.json",
            "SHA256SUMS.txt", f"original/{original_name}",
        }
        with zipfile.ZipFile(bundle) as archive:
            self.assertEqual(set(archive.namelist()), expected)
            self.assertEqual(archive.read(f"original/{original_name}"), original_bytes)
            self.assertFalse(any(name.startswith("reference/")
                                 for name in archive.namelist()))
            self._assert_archive_hashes(archive)


if __name__ == "__main__":
    unittest.main()
