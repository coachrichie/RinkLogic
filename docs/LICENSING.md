# Licensing RinkLogic

RinkLogic uses two licenses with explicit file-level scope.

## Software — Apache-2.0

Source code, Monkey C application files, Python analysis tools, tests, scripts,
build configuration, continuous-integration configuration, schemas, and other
software-oriented files are licensed under the Apache License 2.0. The full
text is available in [`LICENSE`](../LICENSE) and
[`LICENSES/Apache-2.0.txt`](../LICENSES/Apache-2.0.txt).

## Documentation and project media — CC-BY-4.0

Original Markdown and HTML documentation and the project-owned logos,
backgrounds, launcher icons, and other PNG media are licensed under Creative
Commons Attribution 4.0 International. The full legal code is available in
[`LICENSES/CC-BY-4.0.txt`](../LICENSES/CC-BY-4.0.txt).

Required attribution:

> RinkLogic by Richard Dominik Haimerl Schwarzwaldau, licensed under CC BY 4.0.

When sharing adapted documentation or media, identify that changes were made
and do not imply endorsement by the rights holder.

## Machine-readable scope

[`REUSE.toml`](../REUSE.toml) records the file patterns, copyright holder, and
SPDX identifiers `Apache-2.0` and `CC-BY-4.0`. Run `python -m reuse lint` after
installing [`requirements-dev.txt`](../requirements-dev.txt) to validate the
mapping.

## Garmin and third-party exclusions

These licenses do not grant rights in Garmin names, logos, trademarks,
documentation, Connect IQ SDK files, simulator files, or other Garmin Program
Materials. Those materials are not redistributed through this repository and
remain subject to Garmin's terms.

Third-party dependencies remain under their own licenses and are described in
[`THIRD_PARTY.md`](THIRD_PARTY.md). A dependency used from an external package
manager is not relicensed merely because RinkLogic refers to it.
