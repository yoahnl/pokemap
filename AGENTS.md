# Repository Guidelines

## Overview
- This repo is a Dart/Flutter monorepo for a Pokemon-style editor/runtime/battle stack.
- There is no workspace orchestrator (`melos.yaml` is absent): run commands package-by-package.
- Main package graph:
  - `packages/map_core` (pure Dart models/serialization/validation) -> base contract package.
  - `packages/map_gameplay` (pure Dart overworld logic) -> depends on `map_core`.
  - `packages/map_battle` (pure Dart battle engine) -> independent from Flutter.
  - `packages/map_runtime` (Flutter + Flame runtime) -> depends on `map_core`, `map_gameplay`, `map_battle`.
  - `packages/map_editor` (Flutter desktop authoring app) -> depends on `map_core`.
  - `examples/playable_runtime_host` (host app) -> depends on `map_runtime`, `map_gameplay`, `map_core`.

## Architecture Boundaries
- Keep package responsibilities isolated; do not move domain logic across packages unless explicitly requested.
- Keep pure Dart packages (`map_core`, `map_gameplay`, `map_battle`) free of Flutter/Flame imports.
- Treat `map_core` JSON models and operations as shared contracts; schema changes usually require coordinated updates in editor/runtime/tests.
- `map_runtime` is the integration layer (Flame rendering + runtime battle handoff + save/load seams).
- `map_editor` is an authoring tool; avoid coupling it directly to runtime rendering internals.

## High-Signal Directories
- `packages/`: source of truth for libraries/apps.
- `examples/playable_runtime_host/golden_battle_slice/`: versioned runtime fixture (`project.json`, `runtime_host_launch_save.json`, assets/maps/data).
- `packages/map_editor/test/fixtures/manual_pokemon_import_pack_10/`: versioned import fixture pack.
- `reports/`: many tracked engineering reports; modify only when the task explicitly asks.
- `docs/`: mostly gitignored; only canonical combat docs are tracked:
  - `docs/combat/battle-canonical-state-v3.1.md`
  - `docs/combat/battle-roadmap-canonical-v3.1.md`

## Working Style
- Keep changes minimal and scoped to the impacted package(s).
- Match existing style and naming in touched files.
- Preserve public API barrels when needed:
  - `packages/map_core/lib/map_core.dart`
  - `packages/map_gameplay/lib/map_gameplay.dart`
  - `packages/map_battle/lib/map_battle.dart`
  - `packages/map_runtime/lib/map_runtime.dart`
- Do not rewrite broad report/fixture/data areas as part of unrelated code tasks.

## Code Generation
- Regenerate code only in the package you changed, and include generated outputs required by tracked sources.
- `packages/map_core` (Freezed + JSON):
  - `dart run build_runner build --delete-conflicting-outputs`
- `packages/map_editor` (Riverpod generator + Freezed):
  - `flutter pub run build_runner build --delete-conflicting-outputs`
- `packages/map_runtime` (Freezed):
  - `flutter pub run build_runner build --delete-conflicting-outputs`
- Avoid unrelated generated-file churn.

## Validation Matrix
- Prefer targeted tests first, then broaden if needed.
- Pure Dart packages:
  - `cd packages/map_core && dart test`
  - `cd packages/map_gameplay && dart test`
  - `cd packages/map_battle && dart test`
- Flutter packages/apps:
  - `cd packages/map_runtime && flutter test`
  - `cd packages/map_editor && flutter test`
  - `cd examples/playable_runtime_host && flutter test`
- Static analysis:
  - Pure Dart: `dart analyze`
  - Flutter: `flutter analyze`
- Runtime smoke checks commonly used in this repo:
  - `cd packages/map_runtime && flutter test test/phase_a_golden_battle_slice_smoke_test.dart`
  - `cd examples/playable_runtime_host && flutter test test/phase_a_golden_slice_launch_test.dart`

## Scripts and Utilities
- Coverage/report wrappers at repo level:
  - `scripts/generate_phase_a_battle_coverage.sh`
  - `scripts/generate_phase_b_scaffold_pack_coverage.sh`
- Tool entrypoints:
  - `packages/map_editor/tool/export_embedded_pokemon_moves_bootstrap.dart`
  - `packages/map_runtime/tool/phase_a_battle_coverage.dart`
  - `packages/map_runtime/tool/phase_b_scaffold_pack_coverage.dart`
- Some scripts/docs use `/opt/homebrew/bin/flutter`; prefer `flutter` from `PATH` unless a task explicitly requires a fixed binary.

## File Hygiene
- Do not add new `.dart_tool/`, `build/`, or cache artifacts unless explicitly required.
- Avoid lockfile churn unless dependency updates are part of the task.
- Note: the repository currently contains a few historically tracked generated artifacts (notably under `packages/map_gameplay/.dart_tool/` and `packages/map_gameplay/build/`). Do not modify or clean these unless the task is explicitly a hygiene cleanup.
- `pubspec.lock` is currently tracked in some app/package directories (for example `packages/map_editor`, `packages/map_gameplay`, `examples/playable_runtime_host`); keep changes intentional.

## Notes for Agents
- Check for deeper `AGENTS.md` files before editing in subdirectories (none found during this audit, but always re-check).
- Before structural changes, read the nearest `pubspec.yaml` and, when present, package `README.md`.
- Respect `.gitignore` rules and existing tracked/untracked boundaries (especially docs and large fixture/report areas).
