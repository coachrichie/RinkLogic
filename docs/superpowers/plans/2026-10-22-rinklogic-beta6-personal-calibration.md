# RinkLogic Beta 6 Personal Calibration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Deliver `0.2.0-beta.6` with button-accessible, persistent known-distance calibration, Schema 12 calibration provenance, and a non-distance-affecting cadence/step-length shadow analysis for remote testers.

**Architecture:** Extend the existing Monkey C calibration scaffold with a pure two-condition controller, a fail-closed `Application.Storage` profile store, and a runtime configuration decorator that applies one explicitly activated local factor only to normal recordings. Build Schema 12 from the isolated Schema 11 phase-lap fix by retiring active field 108 and adding new Session field 115, while Python analysis derives cadence relationships from FIT laps plus the private reference form. UI, storage, FIT writing, and offline analytics remain separate units.

**Tech Stack:** Monkey C / Connect IQ SDK 9.2.0, Toybox `WatchUi`, `Application.Storage`, `ActivityRecording` and `FitContributor`; XML FIT contributions; JSON schema registry; Python 3 with pytest/fitdecode; PowerShell build tooling.

**Spec:** `docs/superpowers/specs/2026-10-22-remote-beta-manual-fit-design.md`

## Global Constraints

- Implement in a new isolated RinkLogic worktree created from `codex/beta4-distance-minutes`; do not edit the existing dirty project checkout.
- Integrate isolated commit `500e163` before Schema 12 work; it is the reviewed Schema 11 numeric phase-lap baseline.
- Preserve unrelated user changes and never add `analysis/private/`, original tester FITs, contact data, videos, or signing keys to Git.
- Target app version is `0.2.0-beta.6`, internal version `6`, FIT Schema `12`, initially for Venu 2 Plus.
- The lower ready-screen button starts normal training; the upper button opens `KALIBRIERUNG` / `EXIT`. On that menu, upper cycles and lower confirms; touch may select directly.
- Calibration accepts only Ice/Inline and exactly `2000`, `2200`, `2500`, or `3000` cm.
- Each condition uses the exact pace sequence `slow, fast, normal, slow, fast`, first `skate_only`, then `puck_stickhandling`.
- Per-run gates are duration `2000..30000` ms inclusive, baseline distance `> 0`, pushes `> 0`, coverage `>= 80` and `<= 100`, timebase `measured` or `estimated`, and ratio `0.50..1.50` inclusive.
- Per-condition relative MAD must be `<= 0.15`; relative disagreement between condition medians must be `<= 0.15`; final factor is the median of all ten ratios rounded to four decimals and bounded to `0.50..1.50`.
- Calibration always observes the uncalibrated baseline. Only an explicitly activated valid profile may affect a later normal recording.
- Store at most one active surface-specific profile. Missing, corrupt, unsupported, partial, or out-of-range storage always falls back to the baseline.
- Cadence/step-length analysis is shadow-only in Beta 6 and must not change any watch, Record, Lap, Session, or Garmin Connect distance.
- Schema 12 keeps exactly 34 active developer fields and exactly 16 Session fields. ID 108 retains its historical meaning but is inactive; new ID 115 is `personal_calibration_factor` as Session `float32`; Record ID 73 stores `12`.
- Custom time values shown on the watch or in Garmin Connect use minutes. Internal milliseconds remain allowed for timing and validation.
- No GPS, cloud upload, Activity API, global model training, weight/BMI distance multiplier, or automatic profile activation.

## Review Focus

- Upper/lower/touch input collisions: ready, menu, calibration and live recording must consume only their documented inputs; Task 5 pins every route.
- Power loss or storage exception during activation: the prior valid profile remains intact or no profile is active; Task 3 tests replacement ordering and failures.
- Calibration save succeeds but profile persistence fails: show a storage error, do not report activation, and leave the saved FIT identifiable for quarantine; Task 6 tests this split outcome.
- Field-budget regression: Schema 12 must allocate 34 total and 16 Session fields while 108 is absent and 115 is present; Task 2 tests exact IDs and message types.
- Narrow or constant cadence range: analysis reports correlation as unavailable rather than manufacturing a slope; Task 7 tests ties, zero range, missing data and five-run minimums.

---

### Task 1: Establish the Beta 6 integration baseline

**Files:**
- Add to implementation branch: `docs/superpowers/specs/2026-10-22-remote-beta-manual-fit-design.md`
- Add to implementation branch: `docs/superpowers/plans/2026-10-22-rinklogic-beta6-personal-calibration.md`
- Integrate from commit `500e163`: Schema 11 source, resources, parser tests and documentation listed by that commit

**Interfaces:**
- Consumes: `codex/beta4-distance-minutes` at commit `755be1f`; isolated Schema 11 commit `500e163`; approved spec and this plan.
- Produces: a clean Beta 6 branch containing the approved documents and passing Schema 11 baseline, ready for Schema 12 changes.

- [ ] **Step 1: Create and verify the isolated execution worktree**

Use the worktree skill, start from `codex/beta4-distance-minutes`, confirm `git status --short` is empty, then copy the approved spec and plan into the same relative paths. Do not stage files from the existing dirty checkout.

- [ ] **Step 2: Run the pre-integration suites**

Run:

```powershell
python -m pytest analysis/tests scripts/tests -q
powershell -ExecutionPolicy Bypass -File scripts/watch-v2-build.ps1 -Device venu2plus -DistanceModel CalibratedProfile -UnitTest
```

Expected: Python tests pass; Monkey C ends with `PASSED (passed=<n>, failed=0, errors=0)`.

- [ ] **Step 3: Integrate the reviewed Schema 11 commit**

Run `git cherry-pick 500e163`. Resolve no conflict by discarding Beta 4 behavior; preserve the commit's numeric fields 113/114, 34-field allocation and removal of `nativeNum=9`.

- [ ] **Step 4: Re-run the baseline suites**

Run the commands from Step 2. Expected: both suites pass and Schema 11 tests assert IDs 113/114.

- [ ] **Step 5: Commit the approved documents**

```powershell
git add docs/superpowers/specs/2026-10-22-remote-beta-manual-fit-design.md docs/superpowers/plans/2026-10-22-rinklogic-beta6-personal-calibration.md
git commit -m "docs: add beta 6 calibration specification"
```

### Task 2: Define and write FIT Schema 12

**Files:**
- Modify: `shared/schema/hockey-fit-schema.json`
- Modify: `docs/data/FIT-SCHEMA.md`
- Modify: `watch-v2/source/recording/ShadowFitWriter.mc`
- Modify: `watch-v2/resources/fitfields.xml`
- Modify: `watch-v2/resources/strings/strings.xml`
- Modify: `watch-v2/resources-deu/strings/strings.xml`
- Modify: `watch-v2/tests/ShadowFitWriterTest.mc`
- Modify: `analysis/tests/test_connect_summary_layout.py`

**Interfaces:**
- Consumes: Schema 11 active allocation and activity summary dictionary.
- Produces: `ShadowFitWriter.writeActivitySummary(summary)` consuming optional `summary[:personalCalibrationFactor]`; Schema 12 ID 115 and localized Garmin Connect label; ID 108 inactive.

- [ ] **Step 1: Write failing Schema 12 contract tests**

Add tests named `schemaTwelveReplacesAboveNinetyWithPersonalFactor`, `schemaTwelveKeepsThirtyFourTotalAndSixteenSessionFields`, and `missingPersonalFactorWritesFitInvalid`. Assert Record ID 73 is `12`, ID 108 is never allocated, ID 115 is Session `float32`, a factor `0.7521` is written losslessly within float tolerance, and all Schema 11 phase/distance fields remain.

In `test_connect_summary_layout.py`, assert the registry and `fitfields.xml` contain ID 115 with precision `4`, omit active contribution 108, and retain the three leading summary fields: shifts, average shift minutes and average shift HR.

- [ ] **Step 2: Run focused tests to verify failure**

```powershell
powershell -ExecutionPolicy Bypass -File scripts/watch-v2-build.ps1 -Device venu2plus -DistanceModel CalibratedProfile -UnitTest -TestName schemaTwelveReplacesAboveNinetyWithPersonalFactor
python -m pytest analysis/tests/test_connect_summary_layout.py -q
```

Expected: failures because Schema 12/ID 115 do not exist.

- [ ] **Step 3: Implement the Schema 12 allocation**

Change the writer allocation and summary output only: remove active field 108, add `addField(115, "personal_calibration_factor", DATA_TYPE_FLOAT, MESG_TYPE_SESSION, "factor")`, set Record field 73 to `12`, and write FIT-invalid/NaN unless the optional factor is finite and within `0.50..1.50`. Do not reinterpret ID 108 or change IDs 113/114.

Update registry, docs and localized strings with `Personal calibration factor` / `Persönlicher Kalibrierungsfaktor`; expose it in the activity summary after the existing hockey metrics with precision `4`; keep exactly 34 total and 16 Session fields.

- [ ] **Step 4: Run Schema and full analysis tests**

```powershell
powershell -ExecutionPolicy Bypass -File scripts/watch-v2-build.ps1 -Device venu2plus -DistanceModel CalibratedProfile -UnitTest
python -m pytest analysis/tests -q
```

Expected: all pass with exact Schema 12 counts.

- [ ] **Step 5: Commit**

```powershell
git add shared/schema/hockey-fit-schema.json docs/data/FIT-SCHEMA.md watch-v2/source/recording/ShadowFitWriter.mc watch-v2/resources watch-v2/tests/ShadowFitWriterTest.mc analysis/tests/test_connect_summary_layout.py
git commit -m "feat: add schema 12 calibration factor"
```

### Task 3: Build the pure two-condition calibration model

**Files:**
- Modify: `watch-v2/source/calibration/CalibrationController.mc`
- Modify: `watch-v2/source/calibration/CalibrationTypes.mc`
- Modify: `watch-v2/tests/CalibrationControllerTest.mc`

**Interfaces:**
- Consumes: `configure(sport, referenceDistanceCm)`, monotonic millisecond markers, and metrics `{distanceCm, pushes, coveragePercent, timebase}` from the uncalibrated estimator.
- Produces: `currentCondition()`, `currentPace()`, `startRepetition(atMs)`, `endRepetition(atMs, metrics)`, `candidateProfile()` and `summary()`; candidate contains `{schemaVersion, sport, factor, source, referenceDistanceCm, conditionMedians, validRepetitionCount}`.

- [ ] **Step 1: Replace prototype tests with failing domain tests**

Test exact phase order, pace order, all per-run bounds, monotonic timestamps, repeated invalid runs, automatic transition after five valid runs, ten-run eligibility, median rounding, factor bounds, each condition's relative MAD, cross-condition disagreement, abort and immutability of a returned candidate. Assert rejected runs do not advance condition or pace.

- [ ] **Step 2: Run the focused controller suite and verify failure**

```powershell
powershell -ExecutionPolicy Bypass -File scripts/watch-v2-build.ps1 -Device venu2plus -DistanceModel CalibratedProfile -UnitTest -TestName calibration
```

Expected: existing one-condition controller fails the new assertions.

- [ ] **Step 3: Implement the pure controller**

Use the exact gates and sequence from Global Constraints. Keep UI, FIT writer and storage imports out of the controller. Store no more than ten accepted run summaries; calculate each run's duration minutes, cadence per minute, effective step length in cm and baseline ratio. Implement private `median(values)`, `relativeMad(values)` and four-decimal half-up rounding helpers.

- [ ] **Step 4: Run the focused and complete Monkey C suites**

Run the focused command, then omit `-TestName` for the full suite. Expected: all pass.

- [ ] **Step 5: Commit**

```powershell
git add watch-v2/source/calibration/CalibrationController.mc watch-v2/source/calibration/CalibrationTypes.mc watch-v2/tests/CalibrationControllerTest.mc
git commit -m "feat: compute validated personal calibration"
```

### Task 4: Persist one fail-closed calibration profile

**Files:**
- Create: `watch-v2/source/calibration/CalibrationStoragePort.mc`
- Create: `watch-v2/source/calibration/CalibrationProfileStore.mc`
- Create: `watch-v2/tests/CalibrationProfileStoreTest.mc`

**Interfaces:**
- Consumes: controller candidate dictionaries and a port with `getValue(key)`, `setValue(key, value)`, `deleteValue(key)`.
- Produces: `CalibrationProfileStore.loadActive()`, `activate(candidate)`, and `deactivate()`; `ApplicationCalibrationStoragePort` delegates to `Toybox.Application.Storage` using key `rinklogic.calibration.active.v1`.

- [ ] **Step 1: Write failing storage tests**

Cover valid round-trip, one-profile replacement, deactivation, every missing dictionary key, unsupported schema, invalid sport/source/factor/reference distance, NaN, symbols or arrays in stored data, read/write/delete exceptions and failed replacement preserving the prior valid profile. Assert only the compact profile summary is stored, never raw run arrays.

- [ ] **Step 2: Run the focused tests and verify failure**

Run the Venu 2 Plus unit suite with `-TestName calibrationProfile`. Expected: compile/test failure because the store does not exist.

- [ ] **Step 3: Implement port and store**

Persist schema version `1`, sport string `ice|inline`, factor, source string `local_known_distance`, reference distance, and condition medians. Validate a freshly read copy after `setValue` before treating replacement as successful; exceptions return `false`/`null` and never leak a partial profile.

- [ ] **Step 4: Run focused and complete Monkey C suites**

Expected: all pass; no storage test depends on real device state.

- [ ] **Step 5: Commit**

```powershell
git add watch-v2/source/calibration/CalibrationStoragePort.mc watch-v2/source/calibration/CalibrationProfileStore.mc watch-v2/tests/CalibrationProfileStoreTest.mc
git commit -m "feat: persist personal calibration profile"
```

### Task 5: Apply the stored factor only to normal recordings

**Files:**
- Create: `watch-v2/source/shifts/StoredDistanceModelConfig.mc`
- Create: `watch-v2/source-config/personal-calibration-beta/DistanceModelConfig.mc`
- Create: `watch-v2/monkey-personal-calibration-beta.jungle`
- Modify: `watch-v2/source/recording/RecordingCoordinator.mc`
- Modify: `watch-v2/source/shifts/DistanceEstimator.mc`
- Modify: `watch-v2/tests/DistanceEstimatorTest.mc`
- Modify: `watch-v2/tests/StartFlowTest.mc`

**Interfaces:**
- Consumes: baseline `DistanceModelConfig`, `CalibrationProfileStore.loadActive()`, existing `RecordingCoordinator.setDistanceModelConfig(config)`.
- Produces: `StoredDistanceModelConfig(baseConfig, profileStore)` with `mode()`, `personalCalibrationFactor()`, `calibrationSource()`, `activeProfile()`; coordinator method `setSessionCalibrationFactor(factor)` for a completed calibration candidate.

- [ ] **Step 1: Write failing runtime isolation tests**

Assert no profile preserves the bounded height baseline; a valid profile yields `:calibrated_profile_test` and `:local_known_distance`; normal distance applies height baseline then personal factor with existing half-up ordering; calibration recording bypasses the wrapper; corrupt storage falls back; factor is locked after session start; `setSessionCalibrationFactor` accepts only `0.50..1.50` during calibration and places it in the frozen activity summary.

- [ ] **Step 2: Run targeted tests and verify failure**

Run `-TestName distance` and `-TestName calibrationRecording`. Expected: missing wrapper/session-factor behavior.

- [ ] **Step 3: Implement wrapper, Beta 6 config and coordinator provenance**

The Beta 6 base config uses the existing height-bounded experimental prior but returns no hard-coded personal factor. Normal app wiring wraps it with storage; `startCalibration` keeps the base config. Add `:personalCalibrationFactor` to the frozen summary only for a valid active normal profile or an explicitly accepted calibration candidate.

- [ ] **Step 4: Run complete Monkey C suite**

Expected: all fixed/profile/calibrated legacy tests and new Beta 6 tests pass without changing distance when no profile exists.

- [ ] **Step 5: Commit**

```powershell
git add watch-v2/source/shifts watch-v2/source-config/personal-calibration-beta watch-v2/monkey-personal-calibration-beta.jungle watch-v2/source/recording/RecordingCoordinator.mc watch-v2/tests
git commit -m "feat: apply stored calibration to normal sessions"
```

### Task 6: Implement ready-menu navigation and activation UX

**Files:**
- Create: `watch-v2/source/ui/StartMenuView.mc`
- Modify: `watch-v2/source/ui/ReadyView.mc`
- Modify: `watch-v2/source/ui/CalibrationSetupView.mc`
- Modify: `watch-v2/source/ui/CalibrationRunView.mc`
- Modify: `watch-v2/source/ui/CalibrationSummaryView.mc`
- Modify: `watch-v2/source/ShiftSenseApp.mc`
- Modify: `watch-v2/resources/strings/strings.xml`
- Modify: `watch-v2/resources-deu/strings/strings.xml`
- Modify: `watch-v2/tests/ReadyScreenTest.mc`
- Modify: `watch-v2/tests/CalibrationUiTest.mc`
- Modify: `watch-v2/tests/CalibrationRecordingTest.mc`
- Modify: `watch-v2/tests/StartFlowTest.mc`

**Interfaces:**
- Consumes: controller/profile-store/runtime interfaces from Tasks 3–5.
- Produces: `ShiftSenseApp.requestStartMenu()`, `requestCalibration()`, `reviewCalibration(candidate)`, `activateAndSaveCalibration()`, `discardCalibration()`, `exitApp()`; ready/menu/setup/run/summary input delegates with explicit key maps.

- [ ] **Step 1: Write failing navigation and lifecycle tests**

Assert ready `KEY_ESC` requests training and `KEY_ENTER` opens the menu; ready touch targets are separate; menu upper cycles and lower confirms; Calibration opens without creating a normal session; Exit calls an injected exit target and creates no activity. Test setup choices Ice/Inline and 20/22/25/30 m, exact condition/pace prompts, minutes formatting, invalid-run retry, ten-run review, explicit activate and discard.

Add lifecycle tests for: save failure leaves storage untouched; successful save then successful store shows activation; successful save plus storage failure shows a storage error and does not claim activation; discard removes the pending calibration session and preserves the prior profile.

- [ ] **Step 2: Run UI/start/calibration tests and verify failure**

Run the unit suite separately with `-TestName ready`, `-TestName calibrationUi`, and `-TestName calibrationRecording`. Expected: failures on the new key routes and activation lifecycle.

- [ ] **Step 3: Implement the views and app orchestration**

Keep the ready screen's HR/phone lifecycle intact. Display active surface, factor to four decimals and local source, or `BASELINE` when absent. Setup no longer asks the user to choose one condition; the controller owns both. Summary offers `AKTIVIEREN` and `VERWERFEN` only after a valid candidate.

On activation: set candidate factor on the calibration coordinator, save FIT, then call `CalibrationProfileStore.activate`. If saving fails, do not write storage. If storage fails after save, show a distinct error and state that the FIT must be quarantined. `exitApp()` delegates to `Toybox.System.exit()` only after the menu confirmation path.

- [ ] **Step 4: Run complete Monkey C suite**

Expected: all tests pass, including touch-consumption regressions and live lower/upper controls.

- [ ] **Step 5: Commit**

```powershell
git add watch-v2/source/ui watch-v2/source/ShiftSenseApp.mc watch-v2/resources/strings watch-v2/resources-deu/strings watch-v2/tests
git commit -m "feat: add button-driven calibration workflow"
```

### Task 7: Parse Schema 12 and calculate cadence shadow evidence

**Files:**
- Modify: `analysis/shift_pilot.py`
- Modify: `analysis/calibration_report.py`
- Modify: `analysis/tests/test_shift_pilot.py`
- Modify: `analysis/tests/test_calibration_report.py`
- Modify: `docs/testing/20-30m-distance-evaluation.md`
- Create: `docs/testing/beta6-calibration-reference.csv`

**Interfaces:**
- Consumes: Schema 12 fields, ordered ten calibration laps, and private CSV columns `session_id,repetition,sport,condition,target_pace,reference_distance_cm,reference_pushes,marker_status,activation_status,active_factor,hrmax_bpm`.
- Produces: normalized `personal_calibration_factor`; per-run `duration_minutes`, `cadence_per_min`, `effective_step_length_m`, `baseline_factor`; group `spearman_rho` and `theil_sen_slope`; baseline-versus-factor MAE/bias comparison; optional native-record `time_above_90_hrmax_minutes` with declared HRmax source.

- [ ] **Step 1: Write failing parser and statistics tests**

Cover Schema 4–11 compatibility, Schema 12 factor parsing, absent/invalid factor, exact ten-lap join, pace validation, duration/push missingness, tied ranks, constant cadence, fewer than five valid runs, separate conditions, known positive/negative Spearman examples, median pairwise Theil-Sen slope, mismatch between FIT factor and reference-form active factor, and HR-above-90 time with missing/valid native HR records and missing/valid `hrmax_bpm`.

- [ ] **Step 2: Run focused Python tests and verify failure**

```powershell
python -m pytest analysis/tests/test_shift_pilot.py analysis/tests/test_calibration_report.py -q
```

Expected: failures for Schema 12 and cadence outputs.

- [ ] **Step 3: Implement normalized parsing and dependency-free robust statistics**

Use Python standard-library `statistics`; implement average ranks for ties, Pearson correlation of ranks for Spearman, and median of all finite pair slopes for Theil-Sen. Return `None` for insufficient count or zero predictor range. Integrate native HR records over their actual timestamp intervals and report minutes only when a valid declared HRmax exists. Never impute missing pushes, duration, coverage, reference values, cadence or HRmax.

- [ ] **Step 4: Update protocol and synthetic reference template**

Document the exact pace order, all times in minutes, manual FIT return, private-data boundary, independent push count, activation status and the rule that cadence results are descriptive only. The committed CSV contains headers and synthetic example identifiers only.

- [ ] **Step 5: Run all Python tests**

```powershell
python -m pytest analysis/tests scripts/tests -q
```

Expected: all pass with no network or private-data dependency.

- [ ] **Step 6: Commit**

```powershell
git add analysis docs/testing/20-30m-distance-evaluation.md docs/testing/beta6-calibration-reference.csv
git commit -m "feat: analyze calibration cadence in shadow mode"
```

### Task 8: Package Beta 6 and document the remote test gate

**Files:**
- Modify: `scripts/watch-v2-build.ps1`
- Modify: `scripts/tests/test_watch_v2_build.py`
- Modify: `CHANGELOG.md`
- Modify: `docs/DEVELOPMENT.md`
- Modify: `docs/testing/V2-POST-TRAINING-SUMMARY.md`
- Modify: `docs/privacy-de.html`
- Modify: `docs/privacy-en.html`
- Create: `docs/testing/BETA6-REMOTE-CALIBRATION.md`
- Create: `docs/testing/BETA6-TESTER-CONSENT.md`
- Create: `docs/testing/BETA6-DEVICE-MATRIX.md`
- Create: `docs/releases/0.2.0-beta.6.md`

**Interfaces:**
- Consumes: `PersonalCalibrationBeta` jungle and complete automated test results.
- Produces: `-DistanceModel PersonalCalibrationBeta`, signed `RinkLogic-0.2.0-beta.6.iq`, device PRG, SHA-256 manifest, install/rollback/test instructions.

- [ ] **Step 1: Write failing build-configuration tests**

Assert `PersonalCalibrationBeta` selects `watch-v2/monkey-personal-calibration-beta.jungle`, uses a distinct PRG, exports exactly `RinkLogic-0.2.0-beta.6.iq`, and does not alter Fixed/ProfileHeight/CalibratedProfile mappings. Assert export plus unit test remains rejected.

- [ ] **Step 2: Run build-script tests and verify failure**

Run `python -m pytest scripts/tests/test_watch_v2_build.py -q`. Expected: unsupported new mode.

- [ ] **Step 3: Implement build mode and release documentation**

Add the new validated switch value and artifact names. Document version/internal version, commit, Schema 12, model identifier, supported device, field-108 retirement, field 115, manual FIT return, no cloud/GPS, signing-key continuity, rollback and known native `total_distance` limitation. Create a device matrix that begins with Venu 2 Plus and admits another product only after its exact Garmin product ID comes from the registered tester inventory and its compile/simulator or hardware result is recorded; never guess a product ID. The tester notice and privacy pages must cover pseudonymous ID, HR/motion/FIT processing, optional separately consented video, 90-day pilot retention, seven-day deletion after an applicable withdrawal request, private upload-only transfer and the prohibition on public GitHub/chat submission.

- [ ] **Step 4: Run repository policy and release-audit tests**

```powershell
python -m pytest scripts/tests -q
python scripts/repository_policy.py
python scripts/release_audit.py
```

Expected: all pass and no private/calibration source data is tracked.

- [ ] **Step 5: Commit**

```powershell
git add scripts CHANGELOG.md docs/DEVELOPMENT.md docs/testing docs/releases docs/privacy-de.html docs/privacy-en.html
git commit -m "build: prepare beta 6 calibration release"
```

### Task 9: Complete automated, simulator, hardware and Garmin Connect verification

**Files:**
- Modify after evidence exists: `docs/releases/0.2.0-beta.6.md`
- Modify after evidence exists: `docs/DEVELOPMENT.md`
- Do not track: generated PRG/IQ files, original FIT files, developer key, tester reference forms with real data

**Interfaces:**
- Consumes: release candidate commit and long-term RinkLogic signing key via `SHIFTSENSE_DEVELOPER_KEY`.
- Produces: tested Beta 6 IQ/PRG hashes and a factual go/no-go record; no claim is made before the corresponding evidence exists.

- [ ] **Step 1: Run the complete automated suite**

```powershell
python -m pytest -q
powershell -ExecutionPolicy Bypass -File scripts/watch-v2-build.ps1 -Device venu2plus -DistanceModel PersonalCalibrationBeta -UnitTest
```

Expected: every Python test passes and Monkey C reports zero failures/errors.

- [ ] **Step 2: Build signed device and Store artifacts**

```powershell
powershell -ExecutionPolicy Bypass -File scripts/watch-v2-build.ps1 -Device venu2plus -DistanceModel PersonalCalibrationBeta
powershell -ExecutionPolicy Bypass -File scripts/watch-v2-build.ps1 -Device venu2plus -DistanceModel PersonalCalibrationBeta -ExportPackage
```

Expected: both builds succeed with the existing key pair. Record byte sizes and SHA-256 values; do not commit binaries or the key.

- [ ] **Step 3: Perform Venu 2 Plus interaction smoke test**

Verify after safe disconnect: lower ready button starts normal training; upper opens menu; menu Calibration/Exit routing; Exit creates no activity; HR works; normal shift marking/saving still works; all custom times display minutes; no `IQ!`.

- [ ] **Step 4: Perform known-distance calibration smoke test**

Use a measured allowed distance and complete all ten requested runs. Verify pace/condition progression, invalid-run retry, explicit activation, factor survives app restart, active profile is visible, and a subsequent normal recording uses it. Export both Original FIT files privately.

- [ ] **Step 5: Verify FIT and Garmin Connect**

Decode CRC and exact Schema 12 allocation: 34 total, 16 Session, Record marker 12, no active 108, valid 115, numeric phase fields 113/114, consistent RinkLogic distance at Record/Lap/Session. In Garmin Connect verify Hockey summary/laps and note native `total_distance=0.0` as allowed platform behavior.

- [ ] **Step 6: Run cadence shadow report**

Run the local report with the private reference CSV. Verify the active median factor reproduces, cadence metrics are either numeric or explicitly unavailable, and no shadow value changes FIT/watch distance.

- [ ] **Step 7: Verify the remote and device-matrix gates**

Have one independent tester complete installation, normal recording, calibration, Garmin synchronization and Original FIT export without developer access. Before claiming the full multi-family gate, compile and smoke-test the exact second registered Garmin product from `BETA6-DEVICE-MATRIX.md`; if no second supported family is registered, state that the Venu-only pilot is still below the spec's full rollout gate.

- [ ] **Step 8: Record factual evidence and commit**

Only after Steps 1–6, add commands, counts, commit, hashes, device firmware, observed Connect behavior and any limitations to the release/development docs.

```powershell
git add docs/releases/0.2.0-beta.6.md docs/DEVELOPMENT.md
git commit -m "test: verify beta 6 release candidate"
```

- [ ] **Step 9: Stop at the rollout gate**

Do not upload or distribute if there is data loss, an `IQ!`, signature mismatch, wrong field count, missing RinkLogic distance/factor, automatic activation, a failed rollback, or unresolved private-data exposure. Store upload and remote tester distribution require the already authorized release workflow but must use the exact verified IQ/hash.


