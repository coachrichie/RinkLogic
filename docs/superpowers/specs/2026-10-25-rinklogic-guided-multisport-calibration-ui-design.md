# RinkLogic Guided Multi-Sport Calibration UI Design

**Date:** 2026-10-25  
**Status:** Approved 2026-10-25  
**Target:** Next multi-device beta after `0.2.0-beta.6`

## Intent

Replace the hard-to-read Beta 6 calibration setup with one guided 20 m
workflow for ice and inline hockey that can be operated while wearing gloves.
The two sports use the same protocol but store separate personal calibration
profiles. Every normal training explicitly selects its sport before recording
so the correct profile or sport-specific baseline is applied.

## Goals

- Make calibration visibly discoverable from a three-item start menu.
- Use one calibration entry and one fixed 20 m protocol for both sports.
- Store independent ice and inline profiles; never blend their factors.
- Guide exactly five valid runs without stickhandling and five valid runs with
  stickhandling.
- Show condition, within-condition count, overall progress, pace and current
  action on every run screen.
- Use the lower button for run boundaries and the upper button for confirmation
  or saving.
- Save only after ten technically valid and internally consistent runs.
- Return to the three-item start menu after save, discard or cancellation.
- Keep the cadence and effective-step-length measurements required for later
  cadence-model development.

## Non-goals

- No shared personal factor across ice and inline hockey.
- No cloud synchronization or automatic transmission of calibration data.
- No automatic calibration from ordinary training sessions.
- No cadence-dependent distance formula in this UI change. The beta continues
  to activate the robust personal median factor; cadence-rich run data is
  retained for validation and a later model revision.
- No change to the normal training, shift-marking or post-training summary
  semantics.

## Current problems

Beta 6 presents eight sport/distance combinations and then condition, pace,
duration, repetition state and key hints on screens designed with fixed pixel
coordinates. The start menu contains only calibration and exit while normal
training starts through a different path. This makes calibration difficult to
discover and creates inconsistent button meaning.

The controller already requires ten valid runs and divides them into five
`skate_only` followed by five `puck_stickhandling` runs. The redesign preserves
that tested data contract while simplifying its presentation.

## Selected interaction model

### 1. Ready screen

The first screen shows:

- RinkLogic identity;
- heart-rate availability;
- active calibration status (`BASISMODELL` or `KALIBRIERT`);
- one dominant action labelled `WEITER`.

The label is deliberately not `START`, because recording does not begin yet.
Upper button or a tap on the action opens the start menu. No training session
or FIT file is created on this screen.

### 2. Start menu

The menu contains exactly:

1. `TRAINING`
2. `KALIBRIERUNG`
3. `EXIT`

`TRAINING` is selected by default. The lower button moves to the next item and
wraps around. The upper button confirms. Touch selects an item directly. A
selected training item opens the sport selector before entering the existing
confirmation and recording flow.

### 3. Training sport selection

Selecting `TRAINING` displays exactly two choices:

1. `EIS`
2. `INLINE`

The most recently used sport is preselected. The lower button switches the
selection, the upper button confirms, and touch selects directly. Confirmation
loads only the selected sport's active personal profile. If no valid profile
exists for that sport, its scientific baseline is used. The selected sport is
recorded with the session diagnostics so a returned FIT file can be interpreted
correctly.

### 4. Calibration sport selection and introduction

Selecting `KALIBRIERUNG` first displays the same `EIS` / `INLINE` selector.
The selected sport determines which profile slot will be replaced after a
successful calibration. The preparation page then shows:

- `20,00 M GERADE STRECKE`
- selected sport;
- `5 OHNE STICK + 5 MIT STICK`
- `UNTEN: BEGINN / ENDE`
- `OBEN: ABBRECHEN`

The reference distance is fixed at **20.00 m**
(`referenceDistanceCm = 2000`) for both sports. The tester must use a measured
straight course; rink markings may be used only when they actually span 20 m.
No distance choice appears on the watch.

Upper-button cancellation uses a confirmation dialog and returns to the start
menu without changing the active calibration profile.

### 5. Ten-run guided sequence

The condition sequence is fixed:

- accepted runs 1–5: `OHNE STICK`;
- accepted runs 6–10: `MIT STICK`.

Within both five-run blocks, the existing pace order is retained to create
useful cadence variation:

1. `LOCKER`
2. `SCHNELL`
3. `NORMAL`
4. `LOCKER`
5. `SCHNELL`

Each run page shows, in this visual priority:

1. large condition label, for example `OHNE STICK`;
2. large within-condition count, for example `2 / 5`;
3. overall progress, for example `LAUF 2 / 10`;
4. pace prompt;
5. state-specific lower-button instruction.

The state machine is explicit:

- `BEREIT`: lower button starts the run at the goal line;
- `LÄUFT`: lower button ends the run at the near blue line;
- `GÜLTIG`: lower button acknowledges the result and prepares the next run;
- `WIEDERHOLEN`: lower button acknowledges the failed result and presents the
  same condition/count/pace again.

An invalid run never advances either counter. The result screen gives a short,
actionable reason such as `ZU KURZ`, `SENSORDATEN FEHLEN` or `ABWEICHUNG ZU
GROSS`, without exposing internal exception text.

During runs 1–9, the upper button opens a guarded cancellation confirmation;
it does not save an incomplete profile. Touch targets mirror the two actions
without changing button behavior.

### 6. Review and save

After ten valid runs, consistency checks run before a profile can be saved.

The review screen shows:

- `10 / 10 GÜLTIG`;
- selected sport;
- calibration quality (`GUT` or `INKONSISTENT`);
- personal factor;
- separate without-stick and with-stick medians;
- `OBEN: SPEICHERN` when eligible;
- `UNTEN: VERWERFEN` with a confirmation dialog.

If the result is inconsistent, save remains unavailable. The user can repeat
the calibration or discard it. Saving must first persist and read back the
profile, then save the calibration activity. Any failure leaves the previous
profile for the selected sport intact, does not touch the other sport, and
displays a recoverable error.

After successful save, a brief `EIS GESPEICHERT` or `INLINE GESPEICHERT`
outcome appears and then returns to the three-item start menu. The ready screen
subsequently shows the status of both profile slots, for example
`EIS ✓ · INLINE —`.

## Layout rules

- All vertical positions derive from display height; no new fixed absolute Y
  coordinates are allowed.
- Critical condition, count and action text must fit the smallest Ring 1
  display class.
- AMOLED and MIP colors must retain readable contrast; meaning cannot depend on
  color alone.
- German and English strings come from resources rather than inline literals.
- Button hints use semantic wording and may use device-family resource
  overrides where Garmin button labels differ.

## Data and compatibility

- `CalibrationTypes.validReferenceDistance()` continues to accept the 2000 cm
  reference used by this workflow.
- Storage contains independent, versioned `ice` and `inline` profile slots.
- An existing valid Beta 6 single profile is migrated once into the slot named
  by its stored `sport` field; the other slot remains empty. Migration must be
  transactional and keep the original value until the new value reads back.
- The accepted-run records continue to include condition, pace, duration,
  cadence, effective step length, baseline distance, ratio, push count,
  coverage and timebase.
- The activated distance estimator continues to use the robust median personal
  factor in this release. No claim is made that cadence already modifies the
  live step length.
- Calibration FIT metadata identifies the session as calibration, records the
  selected sport and records the 2000 cm reference.
- Normal training loads the factor only from the selected sport's slot. It
  must not fall back to the other sport's personal profile.

## Error and interruption behavior

- Exiting before save never replaces either stored sport profile.
- App restart during calibration treats the candidate as incomplete and keeps
  both previous sport profiles.
- Missing motion coverage repeats the current run instead of silently counting
  it.
- Duplicate or out-of-order boundary presses do not advance progress.
- Saving is idempotent from the review screen and cannot overwrite the other
  sport profile or create duplicate values from repeated input.

## Validation

- Unit tests cover both sport selections, the fixed sequence, condition
  counters, pace prompts, invalid-run retry, guarded cancellation and save
  gate.
- UI tests render every calibration state at representative AMOLED and MIP
  resolutions.
- Input tests verify lower=start/end/acknowledge and upper=confirm/save/cancel.
- Regression tests prove shift marking and FIT schema 12 remain unchanged and
  verify migration of existing single-profile Beta 6 storage.
- Tests prove ice training cannot load an inline profile and inline training
  cannot load an ice profile.
- A Venu 2 Plus hardware test completes one ten-run calibration, saves,
  returns to the start menu and then records a normal training of the selected
  sport using the stored factor.

## Success criteria

- A first-time tester can identify calibration from the start menu without a
  separate instruction sheet.
- At every point the screen clearly states condition, count and next button.
- Exactly five valid runs per condition are required and visible.
- Ice and inline profiles can coexist and are selected explicitly for every
  training.
- No incomplete or inconsistent calibration can overwrite either previous
  profile.
- The new screens fit the approved multi-device Ring 1 display classes.

