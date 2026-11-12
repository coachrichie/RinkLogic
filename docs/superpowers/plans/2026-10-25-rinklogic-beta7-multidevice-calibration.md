# RinkLogic Beta 7 Multi-Device Calibration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Deliver a signed `0.2.0-beta.7` Connect IQ package with a guided fixed-20 m ice/inline calibration, separate sport profiles, mandatory sport selection before training, and verified Ring 1 support for mainstream Garmin watch families.

**Architecture:** Keep one watch app, AppID and FIT contract. Add sport-aware storage and routing around the existing calibration controller and distance estimator, replace the crowded setup screens with responsive semantic views, and drive explicit manifest entries from a checked-in device matrix. Device families share business logic while layout and input validation are grouped by display/input class.

**Tech Stack:** Monkey C / Toybox Connect IQ API, XML resources and manifest, PowerShell build orchestration, Python `unittest`, Garmin SDK 9.2.0 simulator/compiler.

**Spec:** `docs/superpowers/specs/2026-10-24-rinklogic-multidevice-beta-design.md` and `docs/superpowers/specs/2026-10-25-rinklogic-guided-multisport-calibration-ui-design.md`

## Global Constraints

- Preserve AppID `4c7d5f9e-2b48-4f0d-a691-3b1c8e7f2a64` and the existing long-term developer signing key.
- Keep `minApiLevel="4.1.6"` unless a verified API requirement forces an approved change.
- Calibration distance is exactly `2000 cm` for ice and inline; there is no distance selector in the watch flow.
- Each sport requires exactly five valid `skate_only` and five valid `puck_stickhandling` runs using pace order `slow, fast, normal, slow, fast`.
- Ice and inline personal factors are stored independently and never substituted for one another.
- Every normal training explicitly selects ice or inline; the last sport is only a preselection, never an implicit confirmation.
- The existing manual-shift workflow, minute-valued RinkLogic fields and schema-12 FIT IDs/types/units remain unchanged. Garmin's native `total_distance` population is deferred and is not a Beta 7 acceptance gate; Garmin Connect may continue to show `0.00 km`.
- Missing motion data must not fabricate distance and must not prevent manual shift recording or safe activity saving.
- No cloud upload, automatic FIT transmission or global user model is introduced.
- English and German user-visible text must come from resources.
- Ring 2 devices (`venux1`, `instinct3solar45mm`) do not block the Ring 1 Beta 7 package.

## Review Focus

- Wrong-sport profile selection: Task 2 tests must prove ice never loads inline calibration and inline never loads ice calibration.
- Interrupted or corrupt legacy migration: Task 1 tests must prove partial writes roll back and a valid Beta 6 profile remains recoverable.
- Boundary noise and unavailable sensors: Task 4 tests must prove duplicate presses and invalid runs do not advance either counter.
- Small MIP and button-only devices: Task 7 tests must exercise critical pages at 218–280 px and complete the flow without touch.
- Manifest/package drift: Task 6 tests must compare Ring 1 matrix entries with the manifest and inspect the exported `.iq` before release.

---

### Task 1: Add transactional sport-specific profile storage

**Files:**
- Modify: `watch-v2/source/calibration/CalibrationProfileStore.mc`
- Modify: `watch-v2/source/calibration/CalibrationStoragePort.mc`
- Create: `watch-v2/source/calibration/SportPreferenceStore.mc`
- Modify: `watch-v2/tests/CalibrationProfileStoreTest.mc`
- Create: `watch-v2/tests/SportPreferenceStoreTest.mc`

**Interfaces:**
- Produces: `CalibrationProfileStore.loadForSport(sport)`, `statuses()`, `activate(candidate)`, `deactivate(sport)`, `snapshot(sport)`, and `restore(sport, snapshot)`.
- Produces: `SportPreferenceStore.load() as Lang.Symbol` and `save(sport) as Lang.Boolean` with `:ice` as the default only when no valid preference exists.
- Consumes later: `StoredDistanceModelConfig`, `ShiftSenseApp`, and `CalibrationActivationWorkflow` use these methods; no later task reads storage keys directly.

- [ ] **Step 1: Write failing storage tests**

Add tests asserting that ice and inline candidates can coexist, `loadForSport(:ice)` and `loadForSport(:inline)` never cross-load, corrupt data in one slot does not invalidate the other, and `statuses()` returns `{ :ice=>Boolean, :inline=>Boolean }`.

- [ ] **Step 2: Write failing migration and rollback tests**

Test one-time migration from `rinklogic.calibration.active.v1` into a version-2 sport map, preservation of the legacy value until verified readback, rollback on write/read/delete failure, and idempotent repeat migration.

- [ ] **Step 3: Run the focused tests and verify RED**

Run:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/watch-v2-build.ps1 -Device venu2plus -DistanceModel PersonalCalibrationBeta -UnitTest -TestName CalibrationProfileStore
```

Expected: FAIL because sport-slot and migration methods do not exist.

- [ ] **Step 4: Implement version-2 sport storage**

Store both compact profiles under `rinklogic.calibration.profiles.v2`, route activation by `candidate[:sport]`, validate each slot independently, and expose opaque snapshots only for activation rollback. Do not delete the legacy key until the version-2 value has been parsed and matched.

- [ ] **Step 5: Implement and test the last-sport preference**

Persist only `"ice"` or `"inline"`; invalid or missing values load as `:ice`. Run the focused `SportPreferenceStore` tests.

- [ ] **Step 6: Run the complete Monkey C suite**

Run:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/watch-v2-build.ps1 -Device venu2plus -DistanceModel PersonalCalibrationBeta -UnitTest
```

Expected: `PASSED (passed=..., failed=0, errors=0)`.

- [ ] **Step 7: Commit**

```powershell
git add watch-v2/source/calibration watch-v2/tests/CalibrationProfileStoreTest.mc watch-v2/tests/SportPreferenceStoreTest.mc
git commit -m "feat: store separate ice and inline calibration profiles"
```

### Task 2: Select the correct distance model and session identity per sport

**Files:**
- Modify: `watch-v2/source/shifts/StoredDistanceModelConfig.mc`
- Modify: `watch-v2/source-config/personal-calibration-beta/DistanceModelConfig.mc`
- Modify: `watch-v2/source/recording/RecordingCoordinator.mc`
- Modify: `watch-v2/source/recording/SessionRecorder.mc`
- Modify: `watch-v2/tests/DistanceEstimatorTest.mc`
- Modify: `watch-v2/tests/StartFlowTest.mc`
- Modify: `watch-v2/tests/CalibrationRecordingTest.mc`

**Interfaces:**
- Consumes: `CalibrationProfileStore.loadForSport(sport)` from Task 1.
- Produces: `StoredDistanceModelConfig.selectSport(sport) as Lang.Boolean` and `selectedSport()`.
- Produces: `RecordingCoordinator.start(sport) as Lang.Boolean` and sport-aware `SessionRecorder.start(sport)`; calibration continues to receive sport in its options.
- Produces: session names that distinguish `RinkLogic Ice Hockey` and `RinkLogic Inline Hockey` without changing Garmin's hockey activity type or schema-12 developer fields.

- [ ] **Step 1: Write failing wrong-sport isolation tests**

Assert that an ice profile changes only an ice estimator, an inline profile changes only an inline estimator, and a missing selected-sport profile uses the scientific baseline even when the other profile exists.

- [ ] **Step 2: Write failing session-start tests**

Assert that `start(:ice)` and `start(:inline)` pass distinct session names, invalid sports fail before creating a session, and calibration options retain the selected sport and `2000` cm reference.

- [ ] **Step 3: Run focused tests and verify RED**

Run the `DistanceEstimator`, sport-start and `CalibrationRecording` test filters on `venu2plus`; expect missing sport-aware APIs.

- [ ] **Step 4: Implement sport selection in stored distance configuration**

Make `selectSport(sport)` clear any prior active profile, load only the requested slot, and fail closed to the base mode when the sport or profile is invalid.

- [ ] **Step 5: Thread sport through recording start**

Validate the sport before creating a FIT session, use sport-specific session names, and leave existing activity type, FIT fields and manual-shift logic unchanged.

- [ ] **Step 6: Run the complete Monkey C suite**

Expected: all existing and new tests pass with no schema regression.

- [ ] **Step 7: Commit**

```powershell
git add watch-v2/source/shifts watch-v2/source-config/personal-calibration-beta watch-v2/source/recording watch-v2/tests
git commit -m "feat: route training distance profiles by sport"
```

### Task 3: Replace the launch controls with a clear menu and sport selector

**Files:**
- Modify: `watch-v2/source/ui/ReadyView.mc`
- Modify: `watch-v2/source/ui/StartMenuView.mc`
- Create: `watch-v2/source/ui/SportSelectionView.mc`
- Modify: `watch-v2/resources/strings/strings.xml`
- Modify: `watch-v2/resources-deu/strings/strings.xml`
- Modify: `watch-v2/tests/ReadyScreenTest.mc`
- Modify: `watch-v2/tests/StartFlowTest.mc`
- Modify: `watch-v2/tests/CalibrationUiTest.mc`

**Interfaces:**
- Produces: `ReadyView.requestContinue()`.
- Produces: `StartMenuView` selections `:training`, `:calibration`, `:exit`, defaulting to `:training`.
- Produces: `SportSelectionView(target, purpose, selectedSport)` where `purpose` is `:training` or `:calibration` and confirmation calls `target.confirmSport(purpose, sport)`.

- [ ] **Step 1: Write failing ready/menu tests**

Assert one dominant `WEITER` action, upper/tap continuation, the three menu entries in order, lower-button cycling, upper-button confirmation and direct touch selection.

- [ ] **Step 2: Write failing sport-selector tests**

Assert only `EIS` and `INLINE` are selectable, the remembered sport is initially selected, lower toggles, upper confirms, touch selects, and invalid purpose/sport values do nothing.

- [ ] **Step 3: Run focused UI tests and verify RED**

Run `ReadyScreen`, `StartFlow` and `CalibrationUi`; expect failures against the old two-action ready screen and two-item menu.

- [ ] **Step 4: Implement semantic launch views**

Use proportional coordinates and resource strings. Preserve heart-rate and both profile-status indicators on Ready while removing separate Start/Menu buttons.

- [ ] **Step 5: Run focused and complete tests**

Expected: new launch tests pass and unrelated live/summary tests remain green.

- [ ] **Step 6: Commit**

```powershell
git add watch-v2/source/ui watch-v2/resources watch-v2/resources-deu watch-v2/tests
git commit -m "feat: add guided start and sport selection menus"
```

### Task 4: Implement the guided fixed-20 m calibration state machine and views

**Files:**
- Modify: `watch-v2/source/calibration/CalibrationController.mc`
- Modify: `watch-v2/source/calibration/CalibrationTypes.mc`
- Delete: `watch-v2/source/ui/CalibrationSetupView.mc`
- Create: `watch-v2/source/ui/CalibrationIntroView.mc`
- Modify: `watch-v2/source/ui/CalibrationRunView.mc`
- Modify: `watch-v2/source/ui/CalibrationSummaryView.mc`
- Modify: `watch-v2/resources/strings/strings.xml`
- Modify: `watch-v2/resources-deu/strings/strings.xml`
- Modify: `watch-v2/tests/CalibrationControllerTest.mc`
- Modify: `watch-v2/tests/CalibrationUiTest.mc`

**Interfaces:**
- Produces: `CalibrationController.configure(sport)` which always sets `referenceDistanceCm` to `2000`.
- Produces: `CalibrationController.progress()` returning selected sport, condition, pace, within-condition index, overall accepted count, status and last rejection reason.
- Produces: rejection symbols `:too_short`, `:too_long`, `:missing_motion`, `:low_coverage`, `:invalid_distance`, `:invalid_ratio`, and `:invalid_marker`; views map these to localized text.
- Produces: `CalibrationIntroView(target, sport)` and explicit run states `:ready`, `:running`, `:accepted`, `:retry`, `:complete`.

- [ ] **Step 1: Write failing fixed-protocol tests**

Assert both sports configure to `2000` cm, exactly five accepted runs per condition, unchanged pace sequence, correct within-condition/overall counts, and ten accepted runs before eligibility.

- [ ] **Step 2: Write failing rejection/progress tests**

Assert duplicate timestamps, durations outside 2–30 seconds, missing motion, coverage below 80%, invalid estimated distance and out-of-range ratio return stable rejection reasons and never increment progress.

- [ ] **Step 3: Write failing interaction tests**

Assert lower-button transitions `ready → running → accepted/retry → ready`, upper opens guarded cancellation before completion, and only an eligible 10/10 review exposes upper-button save.

- [ ] **Step 4: Run focused tests and verify RED**

Run `CalibrationController` and `CalibrationUi`; expect missing progress/reason APIs and the obsolete setup view.

- [ ] **Step 5: Implement the domain state changes**

Keep accepted-run records unchanged, derive counters from accepted runs, expose only stable reason symbols, and preserve median/MAD consistency gates.

- [ ] **Step 6: Implement responsive introduction, run and review views**

Derive every vertical position from `dc.getHeight()`, display sport/condition/count/pace/action in the specified priority, avoid meaning-by-color-only, and use resource strings for English and German.

- [ ] **Step 7: Run focused and complete tests**

Expected: all calibration tests and the full Venu 2 Plus suite pass.

- [ ] **Step 8: Commit**

```powershell
git add watch-v2/source/calibration watch-v2/source/ui watch-v2/resources watch-v2/resources-deu watch-v2/tests
git commit -m "feat: guide ice and inline twenty metre calibration"
```

### Task 5: Wire the application flow and transactional activation

**Files:**
- Modify: `watch-v2/source/ShiftSenseApp.mc`
- Modify: `watch-v2/source/calibration/CalibrationActivationWorkflow.mc`
- Modify: `watch-v2/tests/StartFlowTest.mc`
- Modify: `watch-v2/tests/CalibrationRecordingTest.mc`
- Modify: `watch-v2/tests/CalibrationProfileStoreTest.mc`

**Interfaces:**
- Consumes: all Tasks 1–4 interfaces.
- Produces: app routes `ready → menu → sport selection → training confirmation/live` and `ready → menu → sport selection → calibration intro/run/review/outcome → menu`.
- Produces: `CalibrationActivationWorkflow.activate(candidate)` that snapshots the selected sport slot, persists/read-verifies the candidate, saves the calibration FIT activity, and restores the snapshot if activity save fails.

- [ ] **Step 1: Write failing end-to-end flow tests**

Cover default and remembered sport selection, baseline fallback, calibrated start, cancellation returning to menu, successful calibration returning to menu, and profile-status refresh on Ready.

- [ ] **Step 2: Write failing activation rollback tests**

Assert candidate validation failure performs no writes, storage failure leaves both slots intact, FIT save failure restores the selected prior slot, and repeated save input is idempotent.

- [ ] **Step 3: Run focused tests and verify RED**

Run `StartFlow`, `CalibrationRecording` and activation-related profile tests; expect old routing and save order to fail.

- [ ] **Step 4: Implement app routing**

Create views only through app routing methods, persist the confirmed training sport, inject its distance configuration before coordinator start, and clear pending calibration state on every terminal path.

- [ ] **Step 5: Implement transactional activation**

Limit rollback to the candidate's sport slot and never modify the other sport. Surface storage/save errors through existing recoverable error views.

- [ ] **Step 6: Run the full Monkey C and Python suites**

Run:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/watch-v2-build.ps1 -Device venu2plus -DistanceModel PersonalCalibrationBeta -UnitTest
python -m unittest discover -s scripts/tests -v
```

Expected: all tests pass.

- [ ] **Step 7: Commit**

```powershell
git add watch-v2/source watch-v2/tests
git commit -m "feat: complete sport-aware calibration and training flow"
```

### Task 6: Make device coverage machine-readable and package Beta 7 correctly

**Files:**
- Create: `watch-v2/device-matrix.json`
- Create: `scripts/watch-v2-matrix-build.ps1`
- Modify: `scripts/watch-v2-build.ps1`
- Modify: `scripts/tests/test_watch_v2_build.py`
- Create: `scripts/tests/test_watch_v2_device_matrix.py`
- Modify: `watch-v2/manifest.xml`

**Interfaces:**
- Produces: device-matrix entries `{ id, ring, displayClass, inputClass, representative, status }`.
- Produces: `scripts/watch-v2-matrix-build.ps1 -Ring Ring1 [-UnitTest] [-BuildOnly]` with nonzero exit on any failed product.
- Produces: `watch-v2-build.ps1 -ExportPackage` artifact `RinkLogic-0.2.0-beta.7.iq`; export builds all manifest products and does not silently restrict the package to the representative `-Device`.

- [ ] **Step 1: Write failing matrix/manifest tests**

Assert unique IDs, installed SDK profiles, valid display/input classes, at least one representative per class, exclusion of Ring 2 and Instinct 2 IDs, and exact equality between approved Ring 1 IDs and manifest products.

- [ ] **Step 2: Write failing build-configuration tests**

Update expected beta artifact to `RinkLogic-0.2.0-beta.7.iq`; assert package export uses the multi-product manifest while single-device PRG/unit builds still require `-Device`.

- [ ] **Step 3: Run Python tests and verify RED**

Run:

```powershell
python -m unittest scripts.tests.test_watch_v2_build scripts.tests.test_watch_v2_device_matrix -v
```

Expected: failures for missing matrix, Beta 6 artifact name and manifest mismatch.

- [ ] **Step 4: Add the approved Ring 1 matrix**

Populate all Ring 1A–1C IDs from the approved multi-device specification and encode display/input classes from installed `compiler.json` metadata. Keep Ring 2 entries present but not release-enabled.

- [ ] **Step 5: Implement matrix build orchestration**

Validate paths and SDK profiles, call the existing build script one device at a time, stop on the first failed product, and emit a compact JSON summary suitable for release documentation.

- [ ] **Step 6: Update the manifest and Beta 7 export path**

Add only release-enabled Ring 1 product IDs. Keep AppID, permissions, languages and minimum API unchanged. Ensure `-e` exports the full manifest package with the existing signing key.

- [ ] **Step 7: Run Python tests**

Expected: all build/matrix tests pass.

- [ ] **Step 8: Commit**

```powershell
git add watch-v2/device-matrix.json watch-v2/manifest.xml scripts/watch-v2-build.ps1 scripts/watch-v2-matrix-build.ps1 scripts/tests
git commit -m "build: add verified Garmin Ring 1 device matrix"
```

### Task 7: Validate responsive UI and controls across representative devices

**Files:**
- Modify: `watch-v2/tests/ReadyScreenTest.mc`
- Modify: `watch-v2/tests/CalibrationUiTest.mc`
- Modify: `watch-v2/tests/LiveDialTest.mc`
- Modify: `watch-v2/tests/SessionSummaryViewTest.mc`
- Create: `watch-v2/tests/ResponsiveUiTest.mc`
- Modify: UI implementation files only when a failing representative test proves an incompatibility.

**Interfaces:**
- Consumes: matrix `displayClass`, `inputClass`, and `representative` fields from Task 6.
- Produces: reusable fake drawing contexts for 218, 240, 260, 280, 360, 390, 416 and 454 px round displays.

- [ ] **Step 1: Parameterize drawing-context tests**

Replace 416-only assumptions with width/height inputs and assertions that critical text baselines and action regions remain inside the display.

- [ ] **Step 2: Add button-only flow coverage**

Exercise Ready, three-item menu, both sport selectors, all calibration states, live shift boundaries, stop/save and summary exit without touch.

- [ ] **Step 3: Run representative unit suites**

Run the complete suite on `venu2s`, `venu3`, `venu445mm`, `fr255s`, `fr955`, `fenix7x`, `fenix847mm`, `epix2pro51mm`, and `instinct3amoled45mm`.

Expected: every representative reports zero failed/error tests and stays below its watch-app memory limit.

- [ ] **Step 4: Run simulator visual checks**

Capture the Ready, menus, calibration intro, each calibration state, live pages and three summary pages for one AMOLED and one MIP representative per distinct resolution class. Record clipping, contrast and button behavior in the Beta 7 device matrix.

- [ ] **Step 5: Repair only proven compatibility failures**

Use display-class resource overrides or proportional layout helpers; do not fork analytics, calibration or FIT logic by model.

- [ ] **Step 6: Re-run all representative suites and matrix builds**

Expected: all Ring 1 representatives pass and every Ring 1 production PRG compiles.

- [ ] **Step 7: Commit**

```powershell
git add watch-v2/source/ui watch-v2/tests watch-v2/resources watch-v2/resources-deu
git commit -m "test: verify responsive controls across Garmin watch classes"
```

### Task 8: Finalize documentation, signed artifacts and release evidence

**Files:**
- Create: `docs/releases/0.2.0-beta.7.md`
- Create: `docs/testing/BETA7-DEVICE-MATRIX.md`
- Create: `docs/testing/BETA7-REMOTE-CALIBRATION.md`
- Modify: `docs/DEVELOPMENT.md`
- Modify: `docs/DEVICE-INSTALL-CHECKLIST.md`
- Modify: `README.md`
- Modify: `CONTRIBUTING.md`

**Interfaces:**
- Consumes: test/build summary and device matrix from Tasks 6–7.
- Produces: signed `.prg` representatives and one signed `RinkLogic-0.2.0-beta.7.iq`, each with size and SHA-256 evidence.

- [ ] **Step 1: Update tester and developer documentation**

Document the `WEITER → TRAINING/KALIBRIERUNG/EXIT` flow, mandatory sport selection, fixed measured 20 m course, five runs per condition, pace prompts, separate profiles, manual FIT return, and baseline fallback.

- [ ] **Step 2: Record the exact compatibility status**

For every Ring 1 ID, distinguish compile-verified, simulator-verified and hardware-verified. Do not describe untested models as hardware-verified.

- [ ] **Step 3: Run final automated verification**

Run:

```powershell
python -m unittest discover -s scripts/tests -v
powershell -ExecutionPolicy Bypass -File scripts/watch-v2-matrix-build.ps1 -Ring Ring1 -BuildOnly
powershell -ExecutionPolicy Bypass -File scripts/watch-v2-build.ps1 -Device venu2plus -DistanceModel PersonalCalibrationBeta -UnitTest
```

Expected: zero failures and a complete Ring 1 build summary.

- [ ] **Step 4: Export and audit the signed package**

Run the Beta 7 export with the long-term key, calculate SHA-256, inspect the `.iq` contents against `device-matrix.json`, and confirm the AppID is unchanged. Never print or copy the private key into logs or documentation.

- [ ] **Step 5: Perform Venu 2 Plus hardware acceptance**

Install the representative PRG, verify both sport selections, complete at least one 10-run calibration, save and return to the menu, then record a normal session using the selected profile. Export the original FIT privately and validate schema 12, the Hockey activity type, calorie recording and the minute-valued RinkLogic fields. Native `total_distance` is observed but does not gate Beta 7.

- [ ] **Step 6: Commit release evidence**

```powershell
git add README.md CONTRIBUTING.md docs
git commit -m "docs: prepare RinkLogic beta 7 multi-device release"
```

- [ ] **Step 7: Stop for Developer Portal confirmation**

Present the `.iq` path, version, AppID, supported-device count, size, SHA-256 and verification results. Upload only after action-time user confirmation; then verify Garmin reports `Signature: Verified`, `Version: 0.2.0-beta.7` and the expected compatible devices.

## Self-review record

- Spec coverage: both approved design documents map to Tasks 1–8; Ring 2 remains explicitly deferred.
- Step scan: each task has a failing-test, implementation and verification boundary; release upload is separated from build work.
- Type consistency: sport values are always `:ice`/`:inline`; storage routing, distance configuration, recorder start and UI selection use the same symbols.
- Review focus: all five listed failure classes have an owning test task.
- Proportion: implementation bodies are intentionally omitted; exact interfaces, assertions, commands and release gates are retained.

