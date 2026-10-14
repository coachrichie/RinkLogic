# Connect Lap Phases and Metre Fields Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Produce a post-Beta-4 candidate whose Garmin Connect laps alternate clearly between `On-Ice` and `Bench`, while record, lap, and session distance are displayed in metres and the 13 October reference data is evaluated as 20 m per run.

**Architecture:** Add a small phase-interval tracker that closes one semantic interval at every manual toggle or save, and write that interval immediately as a FIT lap. Introduce Schema 10 with new metre and string phase fields while retiring—not reinterpreting—the old centimetre and lap-recovery allocations; keep Session field 97 unchanged. Preserve Schema 4–9 parsing and keep Beta 4 untouched as rollback.

**Tech Stack:** Monkey C / Garmin Connect IQ SDK, FIT developer fields and `fitContributions`, Python 3 with `pytest` and `fitdecode`, XML/JSON registries, PowerShell build scripts.

**Spec:** `docs/superpowers/specs/2026-10-13-rinklogic-connect-lap-phases-metres-design.md`

## Global Constraints

- Do not modify or replace the uploaded `0.2.0-beta.4`; no Garmin portal action is part of this plan.
- Existing FIT field IDs retain their original meaning, type, and unit forever.
- Schema 10 uses new IDs 110 (`estimated_distance_m_total`, record float32), 111 (`shift_estimated_distance_m`, lap float32), and 112 (`phase`, lap string with count 8).
- Retire active allocations 63, 66, 93, and 94 in Schema 10; retain their registry history and Schema 4–9 parser support.
- Keep active allocation at or below 34 Developer fields and exactly 16 Session fields.
- Keep Session field 97 as estimated total distance in metres.
- No artificial Bench lap exists before the first manually started shift.
- New activities begin with `On-Ice` and then alternate `Bench`, `On-Ice`, and so on.
- Non-applicable lap values are FIT-invalid, never fabricated zeroes.
- Native Garmin Overview cards are outside Connect-IQ control and must not be presented as an acceptance surface.
- The 13 October reference distance is 2,000 cm per completed run; this correction does not activate calibration automatically.

## Review Focus

- Save before the first shift: create no phase lap and preserve a valid activity.
- Repeated save/retry: close the open interval once and never duplicate the final lap.
- Missing motion or HR during On-Ice: retain phase and duration, but write invalid optional metrics.
- String-field incompatibility or allocation failure: fail optional schema allocation cleanly; do not emit a partly interpretable Schema 10 activity.
- Toggle near save or recovery deadlines: preserve strict phase order and do not let delayed recovery output create extra laps.

---

### Task 1: Correct the 13 October reference contract

**Files:**
- Modify: `docs/testing/20-30m-distance-evaluation.md`
- Modify: `docs/testing/V2-POST-TRAINING-SUMMARY.md`
- Modify: `analysis/tests/test_calibration_report.py`
- Modify: the ignored/private reference CSV only if the user supplies or confirms its exact run rows; never commit personal FIT/CSV data.

**Interfaces:**
- Consumes: existing CSV field `reference_distance_cm`.
- Produces: a documented and tested value of `2000` cm for each 13 October reference run; no runtime calibration change.

- [ ] **Step 1: Write the failing reference-distance test**

Add `test_twenty_metre_reference_error_uses_two_thousand_centimetres` using a temporary reference CSV with `reference_distance_cm=2000` and a synthetic 21.5-m estimate. Assert `reference_distance_m == 20.0` and `distance_error_m == 1.5`. The public protocol, not runtime code, owns the date-specific correction.

- [ ] **Step 2: Run the focused Python test and verify RED**

Run: `python -m pytest analysis/tests/test_calibration_report.py::CalibrationReportTests::test_twenty_metre_reference_error_uses_two_thousand_centimetres -q`

Expected: FAIL because the explicit 20-m regression case is not yet present.

- [ ] **Step 3: Implement the reference correction**

Update the public protocols to say 20 m / 2,000 cm for the 13 October run. Use the existing generic manifest reader unchanged unless the new regression exposes a calculation defect; do not hard-code a date-specific distance in production analysis and do not change `DistanceModel`, `DistanceEstimator`, or the active personal factor in this task.

- [ ] **Step 4: Verify the focused and complete Python tests**

Run: `python -m pytest analysis/tests/test_calibration_report.py -q`

Expected: PASS.

Run: `python -m pytest analysis/tests -q`

Expected: all tests pass.

- [ ] **Step 5: Commit**

```powershell
git add docs/testing/20-30m-distance-evaluation.md docs/testing/V2-POST-TRAINING-SUMMARY.md analysis/tests/test_calibration_report.py
git commit -m "test: correct October reference runs to 20 metres"
```

### Task 2: Add a deterministic semantic phase tracker

**Files:**
- Create: `watch-v2/source/recording/PhaseLapTracker.mc`
- Create: `watch-v2/tests/PhaseLapTrackerTest.mc`

**Interfaces:**
- Consumes: `startShift(atMs)`, `endShift(atMs)`, and `finish(atMs)` timestamps in recording-clock milliseconds.
- Produces: `Lang.Dictionary?` values with `:phase` (`:on_ice` or `:bench`), `:startedAtMs`, `:endedAtMs`, and `:durationMs`; each interval is returned once.

- [ ] **Step 1: Write failing tracker tests**

Add tests named:

- `firstShiftStartsWithoutArtificialBenchLap`
- `endShiftClosesOnIceAndStartsBench`
- `nextShiftClosesBenchAndStartsOnIce`
- `finishClosesOpenOnIceOrBenchExactlyOnce`
- `finishBeforeFirstShiftReturnsNull`
- `duplicateOrBackwardTimestampDoesNotCreateLap`

Assert the exact phase sequence and millisecond durations, including `On-Ice → Bench → On-Ice`.

- [ ] **Step 2: Run the focused Monkey C tests and verify RED**

Run: `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/watch-v2-build.ps1 -Device venu2plus -UnitTest -TestName PhaseLapTracker`

Expected: FAIL because `PhaseLapTracker` does not exist.

- [ ] **Step 3: Implement `PhaseLapTracker`**

Implement:

```text
initialize()
startShift(atMs) as Lang.Dictionary or Null
endShift(atMs) as Lang.Dictionary or Null
finish(atMs) as Lang.Dictionary or Null
```

Reject invalid/backward transitions without changing the last valid state. `finish()` is idempotent.

- [ ] **Step 4: Run focused tests and verify GREEN**

Run the Task 2 focused command.

Expected: all `PhaseLapTracker` tests pass.

- [ ] **Step 5: Commit**

```powershell
git add watch-v2/source/recording/PhaseLapTracker.mc watch-v2/tests/PhaseLapTrackerTest.mc
git commit -m "feat: track alternating on-ice and bench intervals"
```

### Task 3: Define Schema 10 and Connect contribution metadata

**Files:**
- Modify: `shared/schema/hockey-fit-schema.json`
- Modify: `docs/data/FIT-SCHEMA.md`
- Modify: `watch-v2/resources/fitfields.xml`
- Modify: `watch-v2/resources/strings/strings.xml`
- Modify: `watch-v2/resources-deu/strings/strings.xml`
- Modify: `analysis/tests/test_connect_summary_layout.py`

**Interfaces:**
- Consumes: stable historical registry through ID 109.
- Produces: IDs 110/111/112 with the names, scopes, types, and units in Global Constraints; Connect labels for phase and metre distance.

- [ ] **Step 1: Write failing schema and contribution tests**

Extend `test_connect_summary_layout.py` to assert:

- field 63 and 66 are absent from active `fitContributions`,
- field 110 is a chart contribution with unit `m` and precision at least 1,
- field 111 is a lap contribution with unit `m` and precision at least 1,
- field 112 is a visible lap contribution labelled `Phase`,
- summary order remains 74, 98, 78, 97, 96 for the first five contributed summary fields,
- the machine-readable registry contains unique IDs through 112 and preserves historical 63/66/93/94 entries,
- active allocation is at most 34 and Session allocation is exactly 16.

- [ ] **Step 2: Run the focused Python test and verify RED**

Run: `python -m pytest analysis/tests/test_connect_summary_layout.py -q`

Expected: FAIL because Schema 10 fields are absent and cm contributions remain active.

- [ ] **Step 3: Update registry, documentation, XML, and strings**

Register Schema 10 without changing historical definitions. Use localized values `Phase`, `On-Ice`, `Bench`, `Geschätzte Distanz`, and unit `m`. Remove active contribution metadata for retired cm/recovery fields while preserving compatibility documentation.

- [ ] **Step 4: Verify XML/JSON and focused tests**

Run:

```powershell
python -m json.tool shared/schema/hockey-fit-schema.json *> $null
[xml](Get-Content -Raw watch-v2/resources/fitfields.xml) | Out-Null
[xml](Get-Content -Raw watch-v2/resources/strings/strings.xml) | Out-Null
[xml](Get-Content -Raw watch-v2/resources-deu/strings/strings.xml) | Out-Null
python -m pytest analysis/tests/test_connect_summary_layout.py -q
```

Expected: all commands succeed.

- [ ] **Step 5: Commit**

```powershell
git add shared/schema/hockey-fit-schema.json docs/data/FIT-SCHEMA.md watch-v2/resources/fitfields.xml watch-v2/resources/strings/strings.xml watch-v2/resources-deu/strings/strings.xml analysis/tests/test_connect_summary_layout.py
git commit -m "feat: define Schema 10 phase and metre fields"
```

### Task 4: Write immediate phase laps and metre values

**Files:**
- Modify: `watch-v2/source/recording/ShadowFitWriter.mc`
- Modify: `watch-v2/source/recording/SessionRecorder.mc`
- Modify: `watch-v2/tests/ShadowFitWriterTest.mc`

**Interfaces:**
- Consumes: phase dictionaries from `PhaseLapTracker`; optional On-Ice summary fields `:averageHeartRate`, `:pushes`, `:distanceCm`, `:coveragePercent`.
- Produces: `writePhaseLap(interval, metrics) as Lang.Boolean`; Record field 110 in metres; Lap fields 111 in metres and 112 as `On-Ice`/`Bench`.

- [ ] **Step 1: Write failing writer tests**

Add tests named:

- `schemaTenAllocatesMetreAndStringPhaseFieldsWithinLimit`
- `recordDistanceWritesMetresInsteadOfCentimetres`
- `onIceLapWritesPhaseDurationAndMetreDistance`
- `benchLapWritesPhaseAndInvalidOptionalMetrics`
- `missingMotionWritesInvalidMetreDistance`
- `stringAllocationFailurePreventsPartialSchemaActivation`

Assert Schema marker 10, exact IDs/types/units, `22000 cm → 220.0 m`, `714 cm → 7.14 m`, phase strings, invalid optional values, 16 Session fields, and at most 34 total fields.

- [ ] **Step 2: Run focused writer tests and verify RED**

Run: `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/watch-v2-build.ps1 -Device venu2plus -UnitTest -TestName ShadowFitWriter`

Expected: FAIL on missing Schema 10 fields and `writePhaseLap`.

- [ ] **Step 3: Implement Schema 10 writer interfaces**

Change the writer to allocate 110/111/112, set Record distance as `cm / 100.0`, and accept string field count 8 via a focused string-field helper. Replace the delayed shift-lap writer path with `writePhaseLap(interval, metrics)`. Bench passes `null` metrics; On-Ice passes its completed shift metrics. Keep field 97 Session distance unchanged.

- [ ] **Step 4: Verify focused writer tests**

Run the Task 4 focused command.

Expected: all writer tests pass.

- [ ] **Step 5: Commit**

```powershell
git add watch-v2/source/recording/ShadowFitWriter.mc watch-v2/source/recording/SessionRecorder.mc watch-v2/tests/ShadowFitWriterTest.mc
git commit -m "feat: write phase laps and distance metres"
```

### Task 5: Integrate phase laps into recording without duplicates

**Files:**
- Modify: `watch-v2/source/recording/RecordingCoordinator.mc`
- Modify: `watch-v2/source/analytics/SessionAnalytics.mc` only to stop FIT-lap emission; retain in-memory analytics calculations.
- Modify: `watch-v2/tests/StartFlowTest.mc`
- Modify: `watch-v2/tests/SessionAnalyticsTest.mc`
- Modify: `watch-v2/tests/ShadowFitWriterTest.mc`

**Interfaces:**
- Consumes: `PhaseLapTracker` from Task 2 and `SessionRecorder.writePhaseLap(interval, metrics)` from Task 4.
- Produces: immediate semantic FIT laps at manual transitions/save; no later recovery-triggered `addLap()` calls.

- [ ] **Step 1: Write failing coordinator tests**

Add tests named:

- `manualTogglesWriteAlternatingOnIceAndBenchLaps`
- `saveOnIceClosesOneOnIceLap`
- `saveOnBenchClosesOneBenchLap`
- `saveBeforeFirstShiftWritesNoPhaseLap`
- `saveRetryNeverDuplicatesFinalPhaseLap`
- `missingMotionAndHeartRateKeepPhaseAndDuration`
- `recoveryDeadlinesNeverCreateAdditionalLaps`

Assert exact order, count, duration, and optional metric validity.

- [ ] **Step 2: Run focused integration tests and verify RED**

Run: `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/watch-v2-build.ps1 -Device venu2plus -UnitTest -TestName phase`

Expected: FAIL because the coordinator still writes only delayed On-Ice laps.

- [ ] **Step 3: Integrate the tracker**

Instantiate/reset `PhaseLapTracker` with each recording. At every successful manual transition, close the previous semantic interval and write it once. Attach completed shift HR/push metrics only to `On-Ice`. At save, close the current interval before `Session.stop()`. Keep recovery calculation available to local analytics but remove recovery-driven FIT `addLap()` calls.

- [ ] **Step 4: Verify focused and complete Monkey C tests**

Run the Task 5 focused command, then:

`powershell -NoProfile -ExecutionPolicy Bypass -File scripts/watch-v2-build.ps1 -Device venu2plus -UnitTest`

Expected: full suite passes with zero failures/errors.

- [ ] **Step 5: Commit**

```powershell
git add watch-v2/source/recording/RecordingCoordinator.mc watch-v2/source/analytics/SessionAnalytics.mc watch-v2/tests/StartFlowTest.mc watch-v2/tests/SessionAnalyticsTest.mc watch-v2/tests/ShadowFitWriterTest.mc
git commit -m "feat: record alternating semantic phase laps"
```

### Task 6: Decode Schema 10 while preserving Schema 4–9

**Files:**
- Modify: `analysis/shift_pilot.py`
- Modify: `analysis/tests/test_shift_pilot.py`

**Interfaces:**
- Consumes: developer IDs 110/111/112 and historical cm fields.
- Produces: normalized metre distances and ordered phase intervals; public report fields `phase`, `duration_minutes`, and `estimated_distance_m`.

- [ ] **Step 1: Write failing parser tests**

Add tests named:

- `test_schema_ten_reads_record_lap_and_session_metres`
- `test_schema_ten_preserves_on_ice_bench_order`
- `test_schema_ten_bench_optional_values_remain_missing`
- `test_schema_nine_centimetres_still_normalize_to_metres`
- `test_schema_four_through_eight_remain_readable`

Use synthetic message dictionaries with exact IDs/names and assert no double conversion.

- [ ] **Step 2: Run parser tests and verify RED**

Run: `python -m pytest analysis/tests/test_shift_pilot.py -q`

Expected: Schema 10 tests fail while existing compatibility tests remain green.

- [ ] **Step 3: Implement Schema 10 normalization**

Extend `PILOT_FIELD_NAMES`, schema detection, record selection, phase-lap normalization, and distance fallback order. Prefer native metre fields in Schema 10; use historical cm only for older schemas. Never infer Bench distance from adjacent records.

- [ ] **Step 4: Verify parser and complete Python suites**

Run:

```powershell
python -m pytest analysis/tests/test_shift_pilot.py -q
python -m pytest analysis/tests -q
```

Expected: all tests pass.

- [ ] **Step 5: Commit**

```powershell
git add analysis/shift_pilot.py analysis/tests/test_shift_pilot.py
git commit -m "feat: decode Schema 10 phase laps and metre fields"
```

### Task 7: Update the physical and Garmin Connect acceptance protocol

**Files:**
- Modify: `docs/testing/V2-POST-TRAINING-SUMMARY.md`
- Modify: `docs/DEVELOPMENT.md`

**Interfaces:**
- Consumes: verified Schema 10 behavior from Tasks 1–6.
- Produces: a test checklist and rollback record; no code interface. Calendar synchronization remains a separate cross-chat coordination action because the calendar file is not present in this branch.

- [ ] **Step 1: Add explicit acceptance rows**

Document checks for:

- no artificial initial Bench lap,
- strict `On-Ice`/`Bench` alternation,
- duration in minutes for both phases,
- metre chart, On-Ice lap distance, and Session distance,
- Bench optional values absent,
- native Overview explicitly out of scope,
- 20-m reference rows,
- CRC and exact Schema 10 field definitions,
- Beta 4 rollback triggers.

- [ ] **Step 2: Remove contradictory old expectations**

Remove any requirement that Recovery 30/60 appear in the same new Connect lap row, that centimetre fields remain active, or that estimated distance replace native Garmin Overview cards.

- [ ] **Step 3: Verify documentation consistency**

Run:

```powershell
rg -n "22 m|2200|Connect.*Overview.*geschätz|field 63|Feld 63|field 66|Feld 66|Recovery" docs/testing/V2-POST-TRAINING-SUMMARY.md docs/DEVELOPMENT.md
git diff --check
```

Expected: remaining matches are explicitly historical or describe the new limitation; no whitespace errors.

- [ ] **Step 4: Commit**

```powershell
git add docs/testing/V2-POST-TRAINING-SUMMARY.md docs/DEVELOPMENT.md
git commit -m "docs: prepare Schema 10 phase-lap validation"
```

### Task 8: Full verification and candidate packaging

**Files:**
- Modify: `docs/DEVELOPMENT.md` with fresh hashes/results only after successful commands.
- Create only ignored build artifacts under `watch-v2/bin/venu2plus/`; do not upload.

**Interfaces:**
- Consumes: all prior tasks.
- Produces: verified local candidate PRG/IQ, hashes, commit identity, and installation notes.

- [ ] **Step 1: Run all automated validation**

Run:

```powershell
python -m pytest analysis/tests -q
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/watch-v2-build.ps1 -Device venu2plus -UnitTest
python scripts/repository_policy.py
python scripts/release_audit.py --repo-root .
reuse lint
git diff --check
```

Expected: zero failures/errors and clean policy/audit/license checks.

- [ ] **Step 2: Build normal and isolated test candidates**

Use the repository's existing signed build/export scripts and original developer key. Compile the ordinary release configuration and the explicitly isolated experimental configuration. Do not change portal state.

- [ ] **Step 3: Record artifact evidence**

Record commit SHA, SDK version, device, file sizes, and SHA-256 for PRG and IQ in `docs/DEVELOPMENT.md`. State that physical Connect visibility remains unverified until the next device run.

- [ ] **Step 4: Re-run the exact final verification after documentation changes**

Run the complete Step 1 command set again and verify exit code 0 for every command.

- [ ] **Step 5: Commit the evidence**

```powershell
git add docs/DEVELOPMENT.md
git commit -m "docs: record Schema 10 candidate verification"
```

- [ ] **Step 6: Stop before external publication**

Report artifact paths and hashes. Request a separate explicit authorization before installing on the watch or changing the Garmin Developer Center.
