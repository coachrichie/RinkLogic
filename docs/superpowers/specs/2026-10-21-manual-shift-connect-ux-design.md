# Manual Shift and Garmin Connect UX Design

Date: 2026-10-21

## Status

Approved product direction. This design records the decisions derived from the
first real Schema-10 hardware and Garmin Connect observations. It contains no
private FIT payloads.

## Problem

The watch correctly records manual shift toggles, heart rate, and the three
completion pages. Garmin Connect does not preserve the same product semantics:

- Fifteen manual shifts appear as thirty-one native laps: fifteen On-Ice
  phases, fifteen Bench phases, and a Garmin-generated trailing lap.
- The developer string field containing `On-Ice` or `Bench` is present in FIT
  but is not reliably visible as a useful row label in Garmin Connect.
- A session without manual toggles can show native pseudo-laps even though it
  contains no valid ShiftSense shift.
- Estimated distance is visible only in Connect IQ developer fields while
  Garmin's native `total_distance` remains `0.0`.

The UI must therefore distinguish ShiftSense's manual-shift truth from Garmin's
technical lap representation and must never present estimated distance as a
measured native distance.

## Product invariants

1. A ShiftSense shift exists only after a manual transition into On-Ice.
2. The manual `shift_count` is authoritative. Native Garmin lap count is never
   used as the number of shifts.
3. Automatic proposals remain diagnostic only. They do not change live state,
   summary values, or visible shift counts.
4. `On-Ice`, `Bench`, and `No Shift` are distinct states. Before the first
   manual marker the session is `No Shift`, not `Bench`.
5. Phase-derived values are unavailable when there are no manual shifts. They
   are represented as missing, not as zero and not as the complete activity
   duration.
6. Every distance value produced by the motion model is explicitly marked as
   estimated or experimental. Missing motion data is `--`, never `0.0 m`.
7. One physical key press performs one phase transition immediately. There is
   no confirmation dialog, second press, toast, or temporary acknowledgement.

## Watch live UI

The existing direct-control interaction remains unchanged:

- Lower key from `NO SHIFT` starts the first On-Ice interval.
- Each later lower-key press toggles immediately between `ON ICE` and `BENCH`.
- The persistent state label and the shift counter are the complete feedback.
- Text remains the primary signal; color is supplementary.
- The app continues to ignore taps for shift control so an accidental screen
  touch cannot create a marker.

The motion page uses a persistent heading or label containing `EXP.` or
`EXPERIMENTAL`. The approximation symbol remains useful but is not the only
quality disclosure.

## Watch completion UI

The completion flow keeps its existing low-friction paging. No page requires a
confirmation action.

When one or more manual shifts exist:

- the phase page is labelled `MANUAL SHIFTS`;
- Shift count, Time on Ice, and Bench Time are displayed;
- the shift-statistics page displays average duration, longest duration, and
  average shift heart rate when available.

When no manual shift exists:

- the phase page displays `NO MANUAL SHIFTS`;
- phase count remains `0`;
- Time on Ice, Bench Time, average shift, longest shift, and average shift HR
  display `--`;
- total activity duration and activity-level HR remain valid and visible.

A separate motion page may display detected pushes, estimated distance, and
sensor coverage, but the entire page must be labelled experimental. It must not
replace any activity or HR summary page.

## FIT and Garmin Connect semantics

### Authoritative fields

The developer session field `shift_count` is the sole user-facing shift count.
`time_on_ice` and `bench_time` are valid only when at least one manual shift was
recorded. With zero shifts, those phase-derived fields are written as FIT
invalid/missing.

Each completed On-Ice interval may carry shift duration, shift HR, pushes,
coverage, and estimated shift distance. Bench intervals must not carry values
whose labels call them shifts.

### Native laps

Garmin controls the native lap list and may append a final technical lap.
ShiftSense cannot treat the number of rows in that list as a product metric.
Only rows containing valid ShiftSense On-Ice developer metrics are semantic
shift rows. Bench or trailing native rows remain technical phase/container
rows and are excluded from all counts and comparisons.

The preferred Connect presentation is On-Ice-centric: user-facing shift
comparisons use only On-Ice rows. Exact Bench intervals remain reconstructable
from adjacent manual boundary timestamps and session duration, while total
Bench Time remains a separate session value. If the Garmin UI exposes technical
rows that cannot be hidden, their custom fields must remain empty rather than
showing shift duration, shift distance, shift HR, or push values.

The Phase string remains in FIT for local parsers, but the product does not
depend on Garmin Connect rendering that string as a visible row name.

### Distance

Connect IQ summary and chart labels use `Estimated distance` plus an explicit
experimental/approximation marker. The native Garmin distance card is not an
accepted output surface because observed `total_distance` is `0.0` despite the
developer-field native mapping. No acceptance test compares the model estimate
with the native Garmin distance field.

## Error and missing-data behavior

- Missing HR remains `--`; it is never converted to zero.
- Missing or insufficient motion coverage yields missing pushes and distance.
- A session saved before the first manual shift creates no semantic phase lap.
- A session stopped during On-Ice closes that manual shift once.
- A session stopped on Bench does not create an additional semantic shift.
- Save retries do not duplicate phase or shift rows.

## Acceptance criteria

1. One lower-key press changes the persistent phase state immediately, with no
   confirmation UI or second action.
2. Fifteen manually started shifts produce `Manual Shifts = 15` on the watch,
   in FIT, and in the Connect IQ activity summary.
3. Bench phases and Garmin's trailing lap do not increase the authoritative
   shift count.
4. Only the fifteen On-Ice rows in that session contain valid shift-specific
   developer metrics.
5. A session without manual markers reports `Manual Shifts = 0` and missing
   phase-derived times and shift statistics.
6. Native pseudo-laps in a zero-marker session contain no valid ShiftSense
   shift metrics and are ignored by local reports.
7. Before the first marker the watch reads `NO SHIFT`; after each marker it
   reads either `ON ICE` or `BENCH` without relying on color alone.
8. Every displayed model distance is visibly estimated/experimental.
9. Missing motion data displays `--`, never a measured-looking zero.
10. Tests derive shift count from the developer summary field, never from the
    native lap-row count.

## Non-goals

- No automatic shift detection becomes authoritative.
- No new calibration flow is added to the start page.
- No attempt is made to rename Garmin's native lap UI.
- No claim is made that the distance model is validated or GPS-derived.
- No private FIT file is committed, published, or embedded in test fixtures.
