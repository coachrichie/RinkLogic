# RinkLogic Multi-Device Beta Design

**Date:** 2026-10-24  
**Status:** Approved 2026-10-25  
**Target release:** `0.2.0-beta.7`  
**Predecessor:** `0.2.0-beta.6`, verified in Garmin Developer Portal on 2026-10-24

**UI addendum:**
[`2026-10-25-rinklogic-guided-multisport-calibration-ui-design.md`](2026-10-25-rinklogic-guided-multisport-calibration-ui-design.md)
defines the revised start and calibration flow required before the multi-device
beta is exported.

## Intent

RinkLogic shall move from a Venu 2 Plus-only beta to one signed Connect IQ
beta package for the mainstream Garmin watch families released in the Venu 2
generation and later. The expansion must preserve the already tested hockey
recording, manual shift workflow, personal calibration, estimated distance and
Garmin Connect FIT fields. A device may only enter the downloadable beta ring
after its build, input path and representative layout class have passed.

The purpose of the staged release is to give remote testers access without
claiming compatibility that has only been declared in `manifest.xml` but not
exercised in the simulator or on hardware.

## Goals

- Ship one `.iq` beta package under the existing beta AppID and signing key.
- Support every Venu generation from Venu 2 onward, including S and Plus
  variants, with Venu X1 following in the special-format ring.
- Add current mainstream Forerunner, fēnix, epix, vívoactive, Enduro, MARQ and
  Instinct AMOLED families.
- Preserve the full Beta 6 feature set and FIT schema on every supported model.
- Support both touch-first two-button watches and button-first multisport
  watches without changing the training semantics.
- Make device coverage reproducible through a checked-in compatibility matrix
  and automated compile/test commands.
- Keep unsupported or unverified devices out of the manifest until their gate
  is satisfied.

## Non-goals

- No cloud upload or global user-data model.
- No automatic collection of tester FIT files; testers continue to send them
  manually.
- No redesign of the distance model or calibration mathematics.
- No public production-store release in this work; this remains a beta app.
- No promise that every historical Connect IQ watch is supported.
- No reduction of the current app to fit the 96 KB Instinct 2 memory limit.

## Constraints

- The existing AppID `4c7d5f9e-2b48-4f0d-a691-3b1c8e7f2a64` and long-term
  developer signing key remain unchanged.
- The application keeps `minApiLevel="4.1.6"` unless a verified API dependency
  forces a higher floor.
- The current `watch-v2` code and schema-12 FIT contract are the source of
  truth.
- Garmin compatibility is controlled by explicit `<iq:product>` entries. The
  Developer Portal cannot add devices that are absent from the signed package.
- Device declarations alone are insufficient: layouts, controls, memory and
  sensor behavior must be validated.
- Raw motion data can vary by device and firmware. Missing or invalid motion
  samples must not invent distance; manual shift recording and normal activity
  saving must remain usable.

## Approaches considered

### 1. Declare every available watch immediately

Add all installed SDK watch IDs to the manifest and export one package. This
maximizes the nominal Store device count quickly, but exposes users to untested
layouts, low-memory failures and device-specific input or sensor behavior. It
was rejected because a successful package export would be mistaken for proven
runtime compatibility.

### 2. Maintain separate beta apps per device family

Create Venu, Forerunner and outdoor-watch beta listings. This isolates failures
but fragments the AppID, signing and tester workflow, and complicates FIT field
comparison across releases. It was rejected because one product and one data
contract are more valuable for this beta.

### 3. One app, staged compatibility rings — selected

Use one manifest and one `.iq` package, but only promote device IDs after
representative compile, unit, layout and input checks. First cover mainstream
round AMOLED and MIP watches with adequate memory; then add unusual geometry or
constrained-memory devices through dedicated overlays. This approach was
approved on 2026-10-24.

## Compatibility rings

### Ring 1A — Venu baseline

These models are the first mandatory gate because the request explicitly
requires all Venu 2 and later watches:

- `venu2`, `venu2s`, `venu2plus`
- `venu3`, `venu3s`
- `venu441mm`, `venu445mm`

Venu X1 is intentionally in Ring 2 because its `448x486` rectangular display
is a separate layout class.

### Ring 1B — mainstream round AMOLED

- vívoactive: `vivoactive5`, `vivoactive6`
- Forerunner: `fr165`, `fr165m`, `fr265`, `fr265s`, `fr965`, `fr970`,
  `fr57042mm`, `fr57047mm`
- epix: `epix2`, `epix2pro42mm`, `epix2pro47mm`, `epix2pro51mm`
- fēnix AMOLED: `fenix843mm`, `fenix847mm`, `fenixe`, `fenix943mm`,
  `fenix947mm`, `fenix9pro43mm`, `fenix9pro47mm`, `fenix9pro51mm`
- rugged/luxury AMOLED: `instinct3amoled45mm`, `instinct3amoled50mm`,
  `marq2`

### Ring 1C — mainstream round MIP

- Forerunner: `fr255`, `fr255s`, `fr255m`, `fr255sm`, `fr955`
- fēnix 7: `fenix7`, `fenix7s`, `fenix7x`, `fenix7pro`, `fenix7spro`,
  `fenix7xpro`, `fenix7pronowifi`, `fenix7xpronowifi`
- fēnix 8 Solar: `fenix8solar47mm`, `fenix8solar51mm`
- fēnix 9 Solar: `fenix9prosolar47mm`, `fenix9prosolar51mm`
- `enduro3`

### Ring 2 — special geometry or constrained memory

- `venux1`: rectangular AMOLED layout.
- `instinct3solar45mm`: `176x176` semi-octagonal MIP layout and 128 KB
  watch-app memory.
- Other current watches may enter Ring 2 after an explicit demand and the same
  validation gates.

### Explicitly excluded from this release

- Instinct 2/2S/2X: Connect IQ 3.4.x, semi-octagonal 156–176 px displays and
  only 96 KB watch-app memory. Supporting them requires a deliberately reduced
  product variant and is not a safe manifest-only change.
- Edge, GPSMAP, Montana, Oregon and other non-watch products.
- Historical watches predating the chosen Venu 2 generation baseline.

## Architecture

### Manifest and packaging

`watch-v2/manifest.xml` remains the single product manifest. Ring 1 product IDs
are added only after their validation gate passes. The Connect IQ exporter then
builds the product-specific binaries into one signed `.iq` archive. Release
metadata records the exact manifest list, file size and SHA-256 hash.

### Display adaptation

The existing proportional drawing code remains the default. Device resources
are grouped by display class rather than model:

- AMOLED round: 360, 390, 416 and 454 px.
- MIP round: 218, 240, 260 and 280 px.
- Special-format overlays: rectangular 448x486 and semi-octagonal 176x176.

Where a generic screen does not fit, a resource or layout helper override is
added for the display class. Business logic, analytics and FIT writers remain
shared. Tests must stop assuming only a 416x416 drawing context.

### Input adaptation

Actions remain semantic and consistent:

- Ready screen: training start and menu/calibration access.
- Recording: one action marks the shift boundary; a separate action opens the
  stop/save flow.
- Summary: previous, next and exit.

Touch delegates remain available on touch watches. Physical-key delegates must
cover two-button and five-button devices. Model-specific help text may differ,
but the recording state machine must not.

### Sensor and distance behavior

Each device build compiles against the same `MotionSource` capability checks.
At runtime, unavailable or invalid raw sensor data is reported as unavailable
instead of being converted into a fabricated distance. Manual shifts, heart
rate and FIT saving continue to operate. A tester diagnostic record captures
device identifier, app version, motion-source availability and calibration
state for manual inclusion with the FIT submission.

## Validation gates

A product ID can be added to the release manifest only when all applicable
checks pass:

1. Production build succeeds with the long-term signing key.
2. The complete Monkey C unit suite passes on one representative model for its
   API/display/input class.
3. Ready, calibration, live pages, stop/save and all three summary pages fit in
   the simulator without clipped critical text.
4. Button-only navigation can start, mark shifts, stop, save and exit without
   touch.
5. FIT session, lap and record fields keep their schema-12 IDs, types and
   units. Native total-distance population is deferred and does not gate Beta
   7; Garmin Connect may continue to show 0.00 km.
6. Missing motion data fails safely while manual recording still works.
7. At least one real-device smoke test is completed for each substantially new
   hardware class before that class is described as hardware-verified.

Representative simulator devices should minimize redundant runs while covering
all meaningful classes: Venu 2S, Venu 3, Venu 4 45 mm, Forerunner 255S,
Forerunner 955, fēnix 7X, fēnix 8 AMOLED, epix Pro 51 mm and Instinct 3 AMOLED.

## Release sequence

1. Add a machine-readable device matrix and tests that compare it with the
   manifest.
2. Make drawing tests resolution-parametric and add button-only flow tests.
3. Validate and add Ring 1A.
4. Validate and add Ring 1B.
5. Validate and add Ring 1C.
6. Export and sign `0.2.0-beta.7`; verify its declared devices and hash before
   Developer Portal upload.
7. Upload as a new version of the existing beta listing and verify signature,
   version and compatible-device count in the portal.
8. Run representative hardware smoke tests, collecting FIT files manually.
9. Address Ring 2 in a later beta without blocking Ring 1 tester access.

## Documentation and tester operations

- Update README, development guide, release notes and device-install checklist
  with the exact supported list and the distinction between simulator-verified
  and hardware-verified.
- Keep the compatibility matrix as the authoritative coverage record.
- Link this work to the separate `RinkLogic – Beta-Test-Automatisierung` chat,
  which owns the remote tester workflow. It must not silently broaden the app's
  data collection or add cloud infrastructure.

## Success criteria

- Garmin accepts the signed Beta 7 package under the existing beta listing.
- The Portal shows all Ring 1 product families as compatible.
- The current Venu 2 Plus workflow and FIT output remain regression-clean.
- Each display/input class has an inspectable simulator result and recorded
  verification status.
- Testers on at least one Venu, one Forerunner and one fēnix/epix device can
  install the beta, complete a session and manually return a usable FIT file.

