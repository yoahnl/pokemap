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

## Current Product Context: PokeMap Surface Engine
- PokeMap is evolving from a Flutter map editor into a modern no-code Pokemon-like game creation tool: maps, terrains, surfaces, NPCs, dialogues, battles, scripts, and scenes should be authorable without low-level JSON or engine concepts.
- The active roadmap is the future Surface Engine: water, tall grass, sand, mud, ice, lava, rails, roads, bridges, and custom surfaces need cleaner visual, animation, autotile, gameplay, and runtime boundaries.
- Do not make PokeMap depend on Tiled. Tiled/RMXP/Pokemon SDK concepts may inspire atlas layout, autotile variants, animation frames, and adjacency mapping, but PokeMap must remain able to author and run its own data.
- Important distinction: water and tall grass can share surface infrastructure, but they are not the same product case. Water needs global synchronized animation, robust autotile edges/corners, surf gating, and possible aquatic encounters. Tall grass needs passability, encounters, player overlay, local rustle animation, and visual variation.
- The migration is intentionally incremental. Prefer small lots with characterization tests, pure adapters, reports, and compatibility checks before persistent model changes.
- Do not introduce persistent `SurfaceDefinition`, `surfaceDefinitions`, a unified Surface view, or Surface Engine runtime integration unless a task explicitly asks for that lot.
- Legacy surface-related building blocks already exist or are being characterized in `map_core`: `ProjectTerrainPreset`, `ProjectPathPreset`, `TerrainLayer`, `PathLayer`, `TilesetVisualFrame`, path/terrain autotile operations, timeline helpers, legacy surface catalog/adapters/diagnostics/usage views.
- Reports under `reports/analysis/` are part of this roadmap. When a task asks for a report, make it factual: include inspected files, exact commands, exact test totals, known gaps, and avoid unverifiable claims such as memory guarantees without a measured command.

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

## Agent Skills and Review Rituals
- Embedded skill: `superpowers:using-superpowers`
  - Purpose: use when starting work so agents find and invoke relevant skills before responding, clarifying, exploring, or editing.
  - Subagent exception: if dispatched as a subagent for a specific task, skip this skill.
  - Core rule: if there is even a small chance a skill applies, invoke/read the skill first. If the invoked skill turns out not to fit, say so briefly and continue with the best workflow.
  - Instruction priority:
    1. User and repo instructions (`AGENTS.md`, direct requests) are highest priority.
    2. Superpowers skills guide workflow where they do not conflict with user/repo instructions.
    3. Default agent behavior is lowest priority.
  - How to access skills in this Codex repo: read the relevant `SKILL.md` from the configured skill path. If the advertised path is missing, search for the real local path, state the mismatch briefly, and continue.
  - Skill-use flow:
    1. Receive the user task.
    2. Check whether any skill might apply before taking action.
    3. Load the skill content.
    4. Announce which skill is being used and why.
    5. If the skill has a checklist or strict workflow, follow it.
    6. Then respond, clarify, inspect, edit, or verify as appropriate.
  - Red flags that mean the agent is rationalizing and should stop to check skills:
    - "This is just a simple question."
    - "I need more context first."
    - "Let me explore the codebase first."
    - "I can check git/files quickly."
    - "Let me gather information first."
    - "This does not need a formal skill."
    - "I remember this skill."
    - "This does not count as a task."
    - "The skill is overkill."
    - "I will just do this one thing first."
    - "This feels productive."
    - "I know what that means."
  - Skill priority when multiple skills apply:
    - Use process skills first, such as brainstorming, planning, systematic debugging, or verification.
    - Use implementation/domain skills second, such as frontend, game, Figma, GitHub, or package-specific workflows.
  - Skill types:
    - Rigid skills, such as TDD and systematic debugging, should be followed closely.
    - Flexible/pattern skills should be adapted to the repo context.
  - User instructions define WHAT to do. Skills guide HOW to do it. Do not skip skill workflow just because the user gave a direct implementation request.
- Embedded skill: `karpathy-guidelines`
  - Purpose: use when writing, reviewing, or refactoring code and the task benefits from caution around assumptions, overcomplication, unrelated edits, or vague success criteria.
  - Overview: reduce common LLM coding mistakes: hidden assumptions, bloated implementations, unrelated edits, and weak verification loops. Bias toward caution on non-trivial work; use judgment for obvious one-line changes while still keeping edits focused.
  - Think before coding:
    - Do not silently choose an interpretation when the request is ambiguous.
    - State assumptions explicitly when they affect implementation.
    - Ask when uncertainty changes scope, data, privacy, API shape, or user-visible behavior.
    - Present multiple interpretations when more than one is plausible.
    - Push back when a simpler or lower-risk path better serves the request.
    - Stop and name confusion rather than coding around it.
  - Simplicity first:
    - Write the minimum code that solves the stated problem.
    - Do not add features beyond what was requested.
    - Do not create abstractions for single-use code.
    - Do not add configurability or extension points speculatively.
    - Do not add error handling for impossible scenarios.
    - If the implementation feels much larger than the problem, simplify before proceeding.
  - Surgical changes:
    - Touch only what the task requires.
    - Do not refactor adjacent code because it is nearby.
    - Do not rewrite comments, formatting, or APIs unrelated to the request.
    - Match the existing style even when a different style seems nicer.
    - Remove imports, variables, functions, or files made unused by your own change.
    - Mention unrelated dead code or design issues instead of changing them.
    - Every changed line should trace back to the user's request.
  - Goal-driven execution:
    - Convert open-ended work into verifiable success criteria.
    - "Add validation" means define invalid inputs, test them, then make the tests pass.
    - "Fix the bug" means reproduce it, patch it, and verify the reproduction no longer fails.
    - "Refactor X" means confirm behavior before and after with targeted tests or analysis.
    - For multi-step tasks, use a short plan with verification signals: inspect affected code, implement the smallest change, run relevant checks.
  - Applying during code review:
    - Look first for assumptions that should have been clarified.
    - Flag over-engineered abstractions or unused flexibility.
    - Flag drive-by edits outside the requested scope.
    - Flag missing tests or unclear verification for behavioral changes.
    - Flag cleanup that removes pre-existing code without a task reason.
- Use `systematic-debugging` when a test, analyzer command, parser, serializer, or runtime behavior fails unexpectedly. Reproduce first, inspect the failing path, then make the smallest targeted fix.
- Use `test-driven-development` for new behavior or bug fixes when feasible: add/adjust a focused failing test, implement the minimal code, then broaden verification.
- Use `verification-before-completion` before claiming work is complete or green. Report exact commands and exact final outputs, especially full package test totals.
- Use `requesting-code-review` or an explicit review stance for substantial changes or when the user asks for a review. Findings should lead, with file/line references and severity.
- For Surface Engine lots, keep the agent posture conservative: characterize current behavior before changing it, preserve legacy compatibility, and document weird behavior instead of "fixing" it outside the lot scope.

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
