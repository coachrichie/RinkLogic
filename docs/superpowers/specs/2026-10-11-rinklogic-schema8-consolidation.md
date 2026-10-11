# RinkLogic Schema 8 Consolidation Design

## Goal

Consolidate the reviewed evidence-model work, the Garmin Connect schema-8 draft,
the verified hardware-test chronicle, and the public showcase around
`coachrichie/RinkLogic` as the sole public application repository.

## Product behavior

- Release builds keep the existing fixed distance model.
- A separately named profile-test build enables the bounded height-based model
  for controlled validation only.
- Invalid, missing, non-finite, or out-of-range profile height falls back to the
  fixed model before the first shift.
- The profile-test source remains experimental and must not be described as
  scientifically validated.
- Garmin Connect's custom Connect IQ summary begins with shift count, average
  shift duration in decimal minutes, and average shift heart rate.
- Schema 8 adds session fields 96-98 without reinterpreting retired IDs.
- Lap field 99 stores each shift duration as float minutes so shortest, longest,
  and median duration can be derived without the uint8 254-second ceiling.
- Record field 100 stores cumulative raw push candidates. Accepted pushes remain
  separately available, allowing false-positive/false-negative investigation.
- Record motion intensity (44) and rotation (45) are restored for diagnostics.
- Active developer-field allocation is exactly 34; the device limit remains 34.
- Active session-field allocation remains exactly 16.
- The approximate 220/292.5 factor is not a production default.

## Repository consolidation

- Port only relevant validated feature work from the private development
  repository; do not merge its mixed open-source PR as-is.
- Add the October 10 hardware/Connect milestone without FIT files, health data,
  keys, or generated binaries.
- Update the public AI showcase so it links to RinkLogic and no longer says the
  application source will be published later.
- After the RinkLogic and showcase updates are public and verified, delete the
  private GitHub repository `coachrichie/ShiftSense-Hockey-App` as explicitly
  authorized. Local user data and private FIT files are not deleted.

## Validation boundary

The profile model may be activated only in the explicit profile-test artifact.
Promotion to the release build requires held-out population validation for ice,
inline, and combined cohorts under the documented gate.
