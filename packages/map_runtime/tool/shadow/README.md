# Selbrume Shadow Screenshot Harness

This directory contains manual visual-gate tools for PokeMap shadow work.

The harness is intentionally outside `test/` so it does not run in normal
package test suites or CI by accident. It is a reproducible screenshot capture
tool, not a golden comparison test.

## Run

From the `map_runtime` package:

```bash
cd /Users/karim/Project/pokemonProject/packages/map_runtime
SHADOW_SCREENSHOT_PREFIX=shadow65 \
SHADOW_SCREENSHOT_OUTPUT_DIR=/Users/karim/Project/pokemonProject/reports/shadows/screenshots \
SELBRUME_PROJECT_PATH=/Users/karim/Desktop/selbrume/project.json \
flutter test tool/shadow/selbrume_shadow_capture_test.dart --plain-name "selbrume shadow screenshot harness"
```

## Environment

The harness supports these environment variables:

```text
SELBRUME_PROJECT_PATH
SHADOW_SCREENSHOT_OUTPUT_DIR
SHADOW_SCREENSHOT_PREFIX
```

Defaults:

```text
SELBRUME_PROJECT_PATH=/Users/karim/Desktop/selbrume/project.json
SHADOW_SCREENSHOT_OUTPUT_DIR=/Users/karim/Project/pokemonProject/reports/shadows/screenshots
SHADOW_SCREENSHOT_PREFIX=shadow65
```

## Outputs

With the default prefix, the harness writes:

```text
reports/shadows/screenshots/shadow65_selbrume_overview.png
reports/shadows/screenshots/shadow65_contact_ledge_1_<elementId>.png
...
reports/shadows/screenshots/shadow65_contact_ledge_10_<elementId>.png
reports/shadows/shadow_lot_65_capture_index.tsv
reports/shadows/shadow_lot_65_capture_manifest.json
```

The TSV records capture coordinates, element ids, runtime instruction geometry,
family/profile metadata, opacity, and screenshot paths. The manifest records
the run configuration, counts, screenshot paths, file sizes, and SHA-256 hashes.

## Limits

This V0 harness captures the current runtime output and asserts the expected
Selbrume shadow inventory:

```text
staticInstructions = 10
contactLedge = 10
genericProjection = 0
```

It does not compare pixels against a golden baseline, and it should not block
normal test suites. A future lot can turn these captures into a reviewed golden
slice once the team wants a stricter visual regression gate.
