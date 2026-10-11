# RinkLogic 0.2.0-beta.4 Distance and Minutes Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a Venu 2 Plus beta that displays every RinkLogic-controlled time value in minutes and carries one locally calibrated, evidence-bounded estimated-distance path through the watch, FIT, and Garmin Connect.

**Architecture:** Keep the fixed and height-only builds unchanged, and add a third source-path build whose config supplies the local `220/292.5` calibration separately from the bounded height prior. Introduce schema 9 with new float-minute IDs instead of reinterpreting seconds, route all displays through one time formatter, and keep all distance surfaces fed by `DistanceEstimator`.

**Tech Stack:** Monkey C / Connect IQ SDK 9.2.0, FIT developer fields, XML resources, Python 3 / pytest, PowerShell, REUSE.

**Spec:** `docs/superpowers/specs/2026-10-11-rinklogic-beta4-distance-minutes-design.md`

## Global Constraints

- The normal release build remains `:fixed` at exactly 125/225 cm; the existing `ProfileHeight` build remains height-only.
- Only the explicit `0.2.0-beta.4` calibrated build applies `220/292.5`; it is local personal calibration, not a population or scientific coefficient.
- Height is valid only from 80 through 250 cm inclusive and is clamped to 0.94–1.06; invalid height uses the exact 125/225 baseline before local calibration.
- Positive model constants use half-up rounding via `floor(value + 0.5)`; weight and BMI never affect distance.
- No GPS, upload, global model/training, automatic calibration activation, or runtime surface selector is added.
- Every RinkLogic-controlled time display uses minutes; internal analytics remain milliseconds.
- Assigned FIT IDs are never reinterpreted. Schema 9 adds IDs 101–109 and remains readable alongside schemas 4–8.
- Active allocation stays at exactly 34 developer fields and 16 session fields.
- Missing motion or time data remains missing/invalid, never a fabricated zero.
- No personal FIT data, health data, developer key, PRG, or IQ package is committed.

## Review Focus

- Missing, NaN, nonnumeric, 79/80, and 250/251 cm heights: exact fixed fallback or documented inclusive profile boundary, followed by calibration only in the calibrated build.
- Build isolation: `Fixed`, `ProfileHeight`, and `CalibratedProfile` must select distinct jungles/artifacts and never leak the beta factor into release output.
- Minute formatting around 0, 59.999 s, 60 s, sub-minute shifts, and sessions over 60 minutes: decimal minutes without clock rollover or negative output.
- Schema compatibility: legacy seconds are converted once, schema-8 fields 98/99 stay minutes, and schema-9 minute fields are not divided by 60 again.
- Field/resource failures: 34/16 allocation is preserved, all nine new labels exist in both locales, and missing float metrics serialize as FIT invalid/NaN rather than zero.

---

### Task 1: Add the isolated calibrated distance build

**Files:**
- Create: `watch-v2/source-config/calibrated-profile-test/DistanceModelConfig.mc`
- Create: `watch-v2/monkey-calibrated-profile-test.jungle`
- Modify: `watch-v2/source-config/fixed/DistanceModelConfig.mc`
- Modify: `watch-v2/source-config/profile-test/DistanceModelConfig.mc`
- Modify: `watch-v2/source/shifts/DistanceEstimator.mc`
- Modify: `watch-v2/source/recording/RecordingCoordinator.mc`
- Modify: `scripts/watch-v2-build.ps1`
- Modify: `scripts/tests/test_watch_v2_build.py`
- Test: `watch-v2/tests/DistanceEstimatorTest.mc`
- Test: `watch-v2/tests/StartFlowTest.mc`

**Interfaces:**
- Consumes: Garmin profile `:heightCm` and `DistanceModelConfig.mode() as Lang.Symbol`.
- Produces: `DistanceModelConfig.personalCalibrationFactor() as Lang.Float`, `DistanceModelConfig.calibrationSource() as Lang.Symbol`, and `DistanceEstimator.configure(modelMode, heightCm, personalFactor, calibrationSource) as Void`.
- Produces: estimator/dashboard dictionaries with distinct `:distanceModelSource` (`:default` or `:profile_height`) and `:distanceCalibrationSource` (`:none` or `:local_known_distance`).
- Produces: `-DistanceModel CalibratedProfile` and optional `-ExportPackage`, selecting `watch-v2/monkey-calibrated-profile-test.jungle`, `RinkLogic-calibrated-profile-test.prg`, or `RinkLogic-0.2.0-beta.4.iq`.

- [ ] **Step 1: Write failing estimator tests for the two-layer model**

Add tests named `calibratedProfileAppliesHeightThenPersonalFactor`, `calibratedProfileUsesExactFixedBaselineForInvalidHeight`, and `calibratedProfileLocksBothProvenanceSources`. Assert calibrated constants/results equivalent to 89/159 cm at 80 cm, 94/169 cm at 180 cm, 100/180 cm at 250 cm, and 94/169 cm for null/NaN/out-of-range height. Assert `:profile_height` only for valid height and `:local_known_distance` for every calibrated-beta case.

- [ ] **Step 2: Run the targeted fixed test binary and verify RED**

Run: `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/watch-v2-build.ps1 -Device venu2plus -UnitTest -TestName calibratedProfileAppliesHeightThenPersonalFactor`

Expected: FAIL because the four-argument configuration and calibration provenance do not exist.

- [ ] **Step 3: Extend the config contract and implement two-stage rounding**

Implement `configure(modelMode, heightCm, personalFactor, calibrationSource)` so fixed ignores profile/calibration, height-only preserves its current exact behavior, and calibrated mode first computes/rounds the bounded baseline and then computes/rounds the local factor. Keep both sources locked before the first shift.

- [ ] **Step 4: Write failing coordinator tests for safe config reads and dashboard propagation**

Cover valid calibrated config, config methods that throw, start called twice, config replacement after start, missing profile, and dashboard propagation of both source symbols.

- [ ] **Step 5: Implement coordinator wiring without changing recording lifecycle behavior**

Read the new config methods before recording starts, fall back to `1.0/:none` on failure, call the four-argument estimator interface once, and copy both provenance fields into the dashboard.

- [ ] **Step 6: Write failing PowerShell selection/export tests**

Extend `test_watch_v2_build.py` to assert all three `-DescribeConfiguration` mappings, that `CalibratedProfile` names the beta-4 IQ only with `-ExportPackage`, and that an unsupported model fails parameter validation.

- [ ] **Step 7: Add the calibrated config, jungle, and export switch**

The calibrated config returns `:calibrated_profile_test`, `220.0 / 292.5`, and `:local_known_distance`. The fixed/profile configs return `1.0` and `:none`. `-ExportPackage` adds the compiler export flag and writes only to ignored `watch-v2/bin/<device>/`.

- [ ] **Step 8: Run task tests for all three modes**

Run:

```powershell
python -m pytest scripts/tests/test_watch_v2_build.py -q
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/watch-v2-build.ps1 -Device venu2plus -UnitTest -DistanceModel Fixed
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/watch-v2-build.ps1 -Device venu2plus -UnitTest -DistanceModel ProfileHeight
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/watch-v2-build.ps1 -Device venu2plus -UnitTest -DistanceModel CalibratedProfile
```

Expected: Python PASS and each simulator summary ends `failed=0, errors=0`.

- [ ] **Step 9: Commit the isolated build**

```powershell
git add watch-v2/source-config watch-v2/monkey-calibrated-profile-test.jungle watch-v2/source/shifts/DistanceEstimator.mc watch-v2/source/recording/RecordingCoordinator.mc watch-v2/tests/DistanceEstimatorTest.mc watch-v2/tests/StartFlowTest.mc scripts/watch-v2-build.ps1 scripts/tests/test_watch_v2_build.py
git commit -m "feat: add calibrated profile distance beta"
```

### Task 2: Format every watch time value as minutes

**Files:**
- Create: `watch-v2/source/ui/HockeyTimeFormatter.mc`
- Modify: `watch-v2/source/ui/LiveView.mc`
- Modify: `watch-v2/source/ui/SessionSummaryView.mc`
- Create: `watch-v2/tests/HockeyTimeFormatterTest.mc`
- Modify: `watch-v2/tests/LiveDialTest.mc`
- Modify: `watch-v2/tests/StartFlowTest.mc`
- Modify: `watch-v2/tests/SessionSummaryViewTest.mc`

**Interfaces:**
- Consumes: millisecond values from the dashboard/session summary.
- Produces: `HockeyTimeFormatter.formatMinutes(milliseconds, decimalPlaces) as Lang.String` returning `--`, `0.0 min`, `1.0 min`, `0.83 min`, or `61.0 min` according to value and requested precision.

- [ ] **Step 1: Write failing formatter boundary tests**

Assert null/negative → `--`; 0 ms → `0.0 min`; 59,999 ms → `1.0 min` at one decimal; 60,000 ms → `1.0 min`; 50,000 ms → `0.83 min` at two decimals; 3,661,000 ms → `61.0 min` without hour rollover.

- [ ] **Step 2: Run the formatter test and verify RED**

Run: `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/watch-v2-build.ps1 -Device venu2plus -UnitTest -TestName hockeyTimeFormatterHandlesMinuteBoundaries`

Expected: FAIL because the formatter does not exist.

- [ ] **Step 3: Implement one integer-safe minute formatter**

Implement `formatMinutes(milliseconds, decimalPlaces)` for precision 1 or 2 using rounded scaled integer minutes, so the watch does not depend on locale decimal separators and always appends ` min`.

- [ ] **Step 4: Replace the LiveView clock strings under failing UI assertions**

Update tests to require one decimal for elapsed/time-on-ice and two decimals for last/average shift. Retain `--` for unknown values and leave HR, cadence, count, and distance formatting untouched.

- [ ] **Step 5: Replace all three summary-page duration strings under failing assertions**

Require one decimal for total duration, ice time, and bench time; require two decimals for average and longest shift. Keep page order, navigation, HR values, and three-page layout unchanged.

- [ ] **Step 6: Run the complete calibrated simulator suite**

Run: `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/watch-v2-build.ps1 -Device venu2plus -UnitTest -DistanceModel CalibratedProfile`

Expected: `PASSED (... failed=0, errors=0)` and no remaining test expectation uses `MM:SS`/`HH:MM:SS` for a RinkLogic time value.

- [ ] **Step 7: Commit minute formatting**

```powershell
git add watch-v2/source/ui watch-v2/tests/HockeyTimeFormatterTest.mc watch-v2/tests/LiveDialTest.mc watch-v2/tests/StartFlowTest.mc watch-v2/tests/SessionSummaryViewTest.mc
git commit -m "feat: display watch time metrics in minutes"
```

### Task 3: Introduce schema 9 minute fields and Connect contributions

**Files:**
- Modify: `watch-v2/source/recording/ShadowFitWriter.mc`
- Modify: `watch-v2/resources/fitfields.xml`
- Modify: `watch-v2/resources/strings/strings.xml`
- Modify: `watch-v2/resources-deu/strings/strings.xml`
- Modify: `shared/schema/hockey-fit-schema.json`
- Modify: `watch-v2/tests/ShadowFitWriterTest.mc`
- Modify: `analysis/tests/test_connect_summary_layout.py`

**Interfaces:**
- Consumes: session-summary millisecond keys `:timeOnIceMs`, `:benchTimeMs`, and `:medianShiftMs`; second buckets `:zoneSeconds` and `:overNinetySeconds`; and existing summary values.
- Produces: schema marker 9 and float-minute session IDs 101–109 exactly as named in the spec.
- Produces: active session IDs `74,78,85,86,96,97,98,101,102,103,104,105,106,107,108,109` and Connect headline order `74,98,78,97,96`.

- [ ] **Step 1: Write failing registry/allocation tests**

Assert registry version 9, field range ending at 109, old IDs 75/76/79–84/89 retained but inactive, IDs 101–109 are `float32/min`, exactly 34 active IDs, exactly 16 active session IDs, and no duplicate field ID/name/scope contract.

- [ ] **Step 2: Write failing writer allocation/value tests**

Assert the writer allocates names/units for 101–109, writes `95,000 ms → 1.583333... min`, preserves zero as `0.0`, writes missing/negative as NaN, writes schema marker 9, and never allocates retired second fields.

- [ ] **Step 3: Run targeted tests and verify RED**

Run:

```powershell
python -m pytest analysis/tests/test_connect_summary_layout.py -q
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/watch-v2-build.ps1 -Device venu2plus -UnitTest -TestName schemaNineWritesMinuteSessionFields
```

Expected: FAIL on schema version/IDs and missing writer fields.

- [ ] **Step 4: Update the registry and writer atomically**

Add IDs 101–109, retire but do not delete/redefine historical IDs, replace their active writer allocations, reuse `millisecondsMinutesOrMissing` for millisecond values, add `secondsMinutesOrMissing` for HR buckets, and leave work/rest, density, HR recovery, distance, per-lap duration, and accepted/raw push semantics unchanged.

- [ ] **Step 5: Write failing localization/contribution tests**

Assert every new `dataLabel` exists in English and German, every new time field uses `ConnectMinutesUnit`, individual shift duration 99 remains in laps, distance 97 is fourth in the activity summary, and all distance labels retain `≈`.

- [ ] **Step 6: Update FIT contributions and localized labels**

Remove Connect contributions for retired second fields, add contributions for 101–109 with precision 1 except median precision 2, and preserve the first three hockey headline metrics.

- [ ] **Step 7: Run task tests in fixed and calibrated builds**

Run the targeted Python test and complete fixed/calibrated simulator suites. Expected: all pass and both builds allocate the same schema-9 fields.

- [ ] **Step 8: Commit schema 9**

```powershell
git add shared/schema/hockey-fit-schema.json watch-v2/source/recording/ShadowFitWriter.mc watch-v2/resources watch-v2/resources-deu watch-v2/tests/ShadowFitWriterTest.mc analysis/tests/test_connect_summary_layout.py
git commit -m "feat: store Connect time metrics in minutes"
```

### Task 4: Make the local parser schema-4-to-9 compatible

**Files:**
- Modify: `analysis/shift_pilot.py`
- Modify: `analysis/tests/test_shift_pilot.py`
- Modify: `analysis/calibration_report.py`
- Modify: `analysis/tests/test_calibration_report.py`

**Interfaces:**
- Consumes: decoded message dictionaries for schema 4–9, including legacy second names, schema-8 fields 98/99, and schema-9 names 101–109.
- Produces: normalized report time keys in minutes, while retaining raw FIT values for audit; derived shortest/longest/median shift minutes come from valid lap field 99 values when present.

- [ ] **Step 1: Write failing schema-9 parser cases**

Create fixtures with all IDs 101–109, NaN values, a zero-minute valid value, three lap-99 durations, distance records/laps/session, and schema marker 9. Assert no minute field is divided again, NaN remains missing, zero remains zero, and shortest/median/longest are derived as 0.50/0.75/1.25 min.

- [ ] **Step 2: Write failing legacy conversion cases**

For schemas 4–7, assert second fields convert exactly once to minutes. For schema 8, assert fields 75/76/79–84/89 convert from seconds while 98/99 remain minutes. Include unknown extra IDs and missing records.

- [ ] **Step 3: Run targeted parser tests and verify RED**

Run: `python -m pytest analysis/tests/test_shift_pilot.py analysis/tests/test_calibration_report.py -q`

Expected: FAIL because schema 9 and the new names are not recognized.

- [ ] **Step 4: Extend field mapping and normalization**

Recognize marker 9, map IDs 101–109, select units from schema/field identity rather than one global conversion, preserve raw values, and expose one normalized minute representation to downstream reports.

- [ ] **Step 5: Keep calibration reports tied to the local known-distance layer**

Update calibration output to identify `220/292.5` as the current personal test factor, never as a population coefficient; do not auto-write the factor back to watch settings or activate it for other users.

- [ ] **Step 6: Run all Python tests**

Run: `python -m pytest -q`

Expected: all tests pass with no warnings caused by schema-9 NaN handling.

- [ ] **Step 7: Commit parser compatibility**

```powershell
git add analysis/shift_pilot.py analysis/calibration_report.py analysis/tests
git commit -m "feat: parse schema 9 minute metrics"
```

### Task 5: Document, build, and verify the beta candidate

**Files:**
- Modify: `docs/data/FIT-SCHEMA.md`
- Modify: `docs/testing/player-profile-distance-validation.md`
- Modify: `docs/testing/20-30m-distance-evaluation.md`
- Modify: `docs/testing/V2-POST-TRAINING-SUMMARY.md`
- Modify: `docs/DEVICE-INSTALL-CHECKLIST.md`
- Modify: `docs/DEVELOPMENT.md`
- Modify: `CHANGELOG.md`

**Interfaces:**
- Consumes: schema-9 registry, the three build modes, automated test output, beta artifact hashes, and the existing 22-m test protocol.
- Produces: reproducible beta build/install record and a tomorrow-ready hardware/Connect checklist; no generated artifact enters Git.

- [ ] **Step 1: Update the canonical schema and evidence boundary documentation**

Document IDs 101–109, 34/16 allocation, all minute precisions, legacy parsing, the two distance layers, half-up order, exact fallback, no BMI/weight factor, no automatic calibration, and no GPS/upload/global model.

- [ ] **Step 2: Update the test and install checklists**

Require on-watch minute values; live/last/total estimated distance; Connect record curve, lap distance, session distance; headline order; schema-9 CRC; local retention of the original FIT; and rollback to beta 3 on `IQ!`, save failure, or missing required fields.

- [ ] **Step 3: Run the complete verification matrix from a clean status**

Run:

```powershell
git diff --check
python -m pytest -q
python scripts/repository_policy.py
python scripts/release_audit.py --repo-root .
python -m reuse lint
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/watch-v2-build.ps1 -Device venu2plus -UnitTest -DistanceModel Fixed
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/watch-v2-build.ps1 -Device venu2plus -UnitTest -DistanceModel ProfileHeight
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/watch-v2-build.ps1 -Device venu2plus -UnitTest -DistanceModel CalibratedProfile
```

Expected: diff clean, Python/policy/audit/REUSE pass, and all three simulator suites report zero failures/errors.

- [ ] **Step 4: Build all PRGs and export the signed beta package**

Run the build script without `-UnitTest` for all three modes, then run calibrated mode with `-ExportPackage`. Verify only ignored paths changed. Compute SHA-256 with `Get-FileHash` for the calibrated PRG and `RinkLogic-0.2.0-beta.4.iq`, and record commit/hash/SDK/device in `docs/DEVELOPMENT.md` without recording the developer-key path.

- [ ] **Step 5: Perform the connected-watch smoke test**

Install the calibrated PRG on the Venu 2 Plus; start a short activity, verify HR, mark one shift, inspect minute and estimated-distance displays, save, open all three conclusion pages, sync to the phone, inspect Connect summary/details/laps/charts, and locally decode the exported FIT for CRC plus schema 9. Record failures precisely; do not mark hardware/Connect complete from simulator evidence.

- [ ] **Step 6: Commit documentation and evidence**

```powershell
git add docs CHANGELOG.md
git commit -m "docs: prepare beta 4 hardware validation"
```

- [ ] **Step 7: Re-run branch verification and request whole-branch review**

Repeat Step 3 on the final commit, confirm `git status --short` is empty, and review the branch diff against the spec. Create a public RinkLogic pull request only after the review has no blocking findings. Do not merge or call the beta validated until the connected-watch and Garmin Connect checks pass.
