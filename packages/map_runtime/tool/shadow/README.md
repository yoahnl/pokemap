# Selbrume Shadow Screenshot Harness

This directory contains manual visual-gate tools for PokeMap shadow work.

The harness is intentionally outside `test/` so it does not run in normal
package test suites or CI by accident. It is a reproducible screenshot capture
tool, not a golden comparison test.

## Run capture only

From the `map_runtime` package:

```bash
cd /Users/karim/Project/pokemonProject/packages/map_runtime
SHADOW_SCREENSHOT_PREFIX=shadow67 \
SHADOW_SCREENSHOT_OUTPUT_DIR=/Users/karim/Project/pokemonProject/reports/shadows/screenshots \
SELBRUME_PROJECT_PATH=/Users/karim/Desktop/selbrume/project.json \
flutter test tool/shadow/selbrume_shadow_capture_test.dart --plain-name "selbrume shadow screenshot harness"
```

## Run capture + baseline comparison

Shadow baseline comparison is optional and manually invoked. In V0 it is
informative for image hashes: structural invariants can fail the test, but
pixel/hash differences are reported without failing.

```bash
cd /Users/karim/Project/pokemonProject/packages/map_runtime
SHADOW_SCREENSHOT_PREFIX=shadow67 \
SHADOW_SCREENSHOT_OUTPUT_DIR=/Users/karim/Project/pokemonProject/reports/shadows/screenshots \
SELBRUME_PROJECT_PATH=/Users/karim/Desktop/selbrume/project.json \
SHADOW_COMPARE_BASELINE=true \
SHADOW_BASELINE_DIR=/Users/karim/Project/pokemonProject/reports/shadows/baselines/selbrume_shadow_v1 \
SHADOW_BASELINE_COMPARE_OUTPUT_JSON=/Users/karim/Project/pokemonProject/reports/shadows/shadow_lot_67_baseline_compare.json \
SHADOW_BASELINE_COMPARE_OUTPUT_TSV=/Users/karim/Project/pokemonProject/reports/shadows/shadow_lot_67_baseline_compare.tsv \
flutter test tool/shadow/selbrume_shadow_capture_test.dart --plain-name "selbrume shadow screenshot harness"
```

## Environment

The harness supports these environment variables:

```text
SELBRUME_PROJECT_PATH
SHADOW_SCREENSHOT_OUTPUT_DIR
SHADOW_SCREENSHOT_PREFIX
SHADOW_COMPARE_BASELINE
SHADOW_BASELINE_DIR
SHADOW_BASELINE_COMPARE_OUTPUT_JSON
SHADOW_BASELINE_COMPARE_OUTPUT_TSV
```

Defaults:

```text
SELBRUME_PROJECT_PATH=/Users/karim/Desktop/selbrume/project.json
SHADOW_SCREENSHOT_OUTPUT_DIR=/Users/karim/Project/pokemonProject/reports/shadows/screenshots
SHADOW_SCREENSHOT_PREFIX=shadow65
SHADOW_COMPARE_BASELINE=false
```

## Outputs

With a `shadow67` prefix, the harness writes:

```text
reports/shadows/screenshots/shadow67_selbrume_overview.png
reports/shadows/screenshots/shadow67_contact_ledge_1_<elementId>.png
...
reports/shadows/screenshots/shadow67_contact_ledge_10_<elementId>.png
reports/shadows/shadow_lot_67_capture_index.tsv
reports/shadows/shadow_lot_67_capture_manifest.json
```

The TSV records capture coordinates, element ids, runtime instruction geometry,
family/profile metadata, opacity, and screenshot paths. The manifest records
the run configuration, counts, screenshot paths, file sizes, and SHA-256 hashes.

When `SHADOW_COMPARE_BASELINE=true`, the harness also writes:

```text
reports/shadows/shadow_lot_67_baseline_compare.json
reports/shadows/shadow_lot_67_baseline_compare.tsv
```

The baseline V1 lives under:

```text
reports/shadows/baselines/selbrume_shadow_v1/
```

## Baseline comparison V0

Blocking invariants:

```text
staticInstructions = 10
contactLedge = 10
genericProjection = 0
capture count = 11
baseline manifest exists
baseline/current screenshots exist
all expected contact element ids are present
baseline/current dimensions match
```

Informative only:

```text
SHA-256 mismatch
file size mismatch
pixel content changes
```

Statuses in the comparison TSV/JSON:

```text
match
pixel-diff-informative
dimension-mismatch-fail
missing-baseline-fail
missing-current-fail
structure-fail
```

V0 deliberately does not implement automatic baseline updates. To update a
baseline, regenerate current screenshots, review them visually, then copy them
over the baseline in an explicit follow-up lot with a report explaining why the
visual change is intended.

## Limits

This V0 harness captures the current runtime output and asserts the expected
Selbrume shadow inventory:

```text
staticInstructions = 10
contactLedge = 10
genericProjection = 0
```

It does not compare pixels against a golden baseline, and it should not block
normal test suites. Baseline comparison is manually invoked and remains
non-blocking for pixel/hash differences until a stricter visual regression gate
is explicitly designed and approved.
