# RinkLogic Schema 8 Consolidation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Publish a reviewed RinkLogic schema-8 test candidate with a safe profile-model test build and synchronized public documentation.

**Architecture:** Preserve the release distance model while adding an explicit source-path build variant for profile validation. Extend the existing FIT writer and parser with unique schema-8 fields under Garmin's allocation limits, then update the canonical documentation and showcase through reviewed pull requests.

**Tech Stack:** Monkey C / Connect IQ SDK, FIT developer fields, Python unittest, PowerShell build scripts, GitHub Actions.

**Spec:** `docs/superpowers/specs/2026-10-11-rinklogic-schema8-consolidation.md`

## Global Constraints

- `coachrichie/RinkLogic` is the sole public application repository.
- Release mode is `:fixed`; only the named profile-test build uses `:profile_height`.
- No personal FIT data, health data, developer keys, or generated binaries enter Git.
- Existing field IDs are never reinterpreted.
- At most 34 active developer fields and 16 active session fields.
- The approximate factor `0.752` is not a production default.

## Review Focus

- Missing, NaN, and boundary profile heights must select the fixed fallback.
- A normal build must not accidentally select the profile model.
- Shifts longer than 254 seconds must remain representable through field 99.
- Raw push candidates must not be confused with accepted pushes.
- Schema 4-7 activities must remain parseable after schema 8 is introduced.

---

### Task 1: Port and expose the bounded profile model

**Files:**
- Modify: `watch-v2/source/shifts/DistanceEstimator.mc`
- Create: `watch-v2/source-config/fixed/DistanceModelConfig.mc`
- Create: `watch-v2/source-config/profile-test/DistanceModelConfig.mc`
- Modify: `watch-v2/monkey.jungle`
- Create: `watch-v2/monkey-profile-test.jungle`
- Modify: `scripts/watch-v2-build.ps1`
- Test: `watch-v2/tests/DistanceEstimatorTest.mc`
- Test: `watch-v2/tests/StartFlowTest.mc`

**Interfaces:**
- Consumes: `DistanceModelConfig.mode() as Lang.Symbol`.
- Produces: fixed default build and explicit `-DistanceModel ProfileHeight` build.

- [ ] Port the four independently reviewed profile-model commits.
- [ ] Add a failing build-selection regression test.
- [ ] Split the config source paths and add the explicit build switch.
- [ ] Run fixed and profile-test simulator suites and builds.
- [ ] Commit the task.

### Task 2: Consolidate schema 8 and diagnostics

**Files:**
- Modify: `watch-v2/source/recording/ShadowFitWriter.mc`
- Modify: `watch-v2/source/recording/RecordingCoordinator.mc`
- Modify: `watch-v2/source/shifts/PushDetector.mc`
- Modify: `watch-v2/source/shifts/DistanceEstimator.mc`
- Modify: `watch-v2/resources/fitfields.xml`
- Modify: `shared/schema/hockey-fit-schema.json`
- Modify: localized string resources
- Test: `watch-v2/tests/PushDetectorTest.mc`
- Test: `watch-v2/tests/ShadowFitWriterTest.mc`
- Test: `analysis/tests/test_connect_summary_layout.py`

**Interfaces:**
- Consumes: push detector dictionaries and shift summaries.
- Produces: schema 8 fields 96-100, restored diagnostic fields 44-45, 34 active fields, 16 session fields.

- [ ] Preserve the previously tested schema-8 draft in Git and port it.
- [ ] Add failing tests for registry/writer name parity, allocation limits, lap duration 99, candidate count 100, and unchanged fixed distance constants.
- [ ] Implement the minimal writer/detector/parser changes.
- [ ] Run targeted tests and the complete suites.
- [ ] Commit the task.

### Task 3: Parser compatibility and public chronicle

**Files:**
- Modify: `analysis/shift_pilot.py`
- Modify: `analysis/tests/test_shift_pilot.py`
- Modify: `docs/DEVELOPMENT.md`
- Modify: `docs/data/FIT-SCHEMA.md`
- Modify: `docs/testing/player-profile-distance-validation.md`

**Interfaces:**
- Consumes: schema-8 registry names and lap field 99.
- Produces: schema 4-8 parsing and privacy-safe release/test documentation.

- [ ] Add failing parser cases for schema 8 long shifts and candidate diagnostics.
- [ ] Implement compatibility and derived shortest/longest/median values.
- [ ] Port the verified October 10 chronicle entry.
- [ ] Run Python tests, both Connect IQ suites/builds, policy audit, and diff checks.
- [ ] Commit the task.

### Task 4: Publish and synchronize the showcase

**Files:**
- Modify in `AI-Built-Garmin-Hockey-App`: `README.md`, `docs/BETA_STATUS.md`, and `content/linkedin/article.md`.

**Interfaces:**
- Consumes: merged RinkLogic commit and verified claims.
- Produces: public links and accurate open-source status without accuracy overclaiming.

- [ ] Update the showcase on a feature branch.
- [ ] Run all showcase publication checks.
- [ ] Create and merge reviewed GitHub pull requests.
- [ ] Verify public clones and CI.

### Task 5: Retire the private GitHub repository

**Files:** None in the public repositories.

**Interfaces:**
- Consumes: verified public RinkLogic and showcase commits.
- Produces: deletion of `coachrichie/ShiftSense-Hockey-App`; local private data remains untouched.

- [ ] Confirm the public repositories contain every approved deliverable.
- [ ] Close the superseded private PR without merging.
- [ ] Delete the exact private GitHub repository.
- [ ] Verify it is no longer accessible and report retained local worktrees separately.
