# Repository Guidelines

## Overview
- This repository is a Dart/Flutter monorepo for a Pokémon-style map/editor/runtime stack.
- Main packages:
  - `packages/map_core`: shared data models and serialization.
  - `packages/map_gameplay`: pure Dart overworld gameplay logic.
  - `packages/map_battle`: pure Dart battle engine.
  - `packages/map_runtime`: Flutter/Flame runtime for loading and rendering maps.
  - `packages/map_editor`: Flutter desktop editor.
  - `examples/playable_runtime_host`: example app that hosts the runtime.

## Working Style
- Keep changes minimal and scoped to the package(s) directly involved.
- Preserve existing package boundaries; do not move gameplay/editor/runtime concerns across packages unless explicitly requested.
- Match the style already used in the touched package.
- Avoid editing generated or build-output files unless regeneration is part of the task.

## Validation
- Prefer targeted validation for the package you change.
- For pure Dart packages, use `dart test` from the package directory.
- For Flutter packages/apps, use `flutter test` from the package or example directory.
- If you change annotated model classes or Riverpod/Freezed code, regenerate code with the relevant `build_runner` command in that package.

## File Hygiene
- Do not commit `.dart_tool`, `build`, or `pubspec.lock` files unless the task explicitly requires them.
- Respect existing `.gitignore` files at the root and package level.

## Notes for Agents
- Check for deeper `AGENTS.md` files before changing files in subdirectories.
- When unsure, prefer reading the nearest package `README.md` and `pubspec.yaml` before making structural changes.
