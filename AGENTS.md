# Repository Guidelines

## 1. Project Overview

This repository is a Dart/Flutter monorepo for a Pokemon-style editor/runtime/battle stack.

There is no workspace orchestrator: `melos.yaml` is absent. Run commands package-by-package.

Main package graph:

- `packages/map_core`
  - Pure Dart models, serialization, validation.
  - Base contract package.
- `packages/map_gameplay`
  - Pure Dart overworld logic.
  - Depends on `map_core`.
- `packages/map_battle`
  - Pure Dart battle engine.
  - Independent from Flutter.
- `packages/map_runtime`
  - Flutter + Flame runtime.
  - Depends on `map_core`, `map_gameplay`, `map_battle`.
- `packages/map_editor`
  - Flutter desktop authoring app.
  - Depends on `map_core`.
- `examples/playable_runtime_host`
  - Host app.
  - Depends on `map_runtime`, `map_gameplay`, `map_core`.

## 2. Instruction Priority

Follow instructions in this order:

1. Direct user request.
2. This `AGENTS.md`.
3. Deeper `AGENTS.md` files found in subdirectories.
4. Relevant skills and workflow rules.
5. Default agent behavior.

If instructions conflict, stop and state the conflict instead of silently choosing a risky interpretation.

## 3. Architecture Boundaries

Keep package responsibilities isolated.

Do not move domain logic across packages unless explicitly requested.

Pure Dart packages must stay free of Flutter and Flame imports:

- `map_core`
- `map_gameplay`
- `map_battle`

Treat `map_core` JSON models and operations as shared contracts. Schema changes usually require coordinated updates in editor, runtime, fixtures, and tests.

`map_runtime` is the integration layer for:

- Flame rendering;
- runtime battle handoff;
- save/load seams;
- runtime smoke behavior.

`map_editor` is an authoring tool. Avoid coupling it directly to runtime rendering internals.

Preserve public API barrels when needed:

- `packages/map_core/lib/map_core.dart`
- `packages/map_gameplay/lib/map_gameplay.dart`
- `packages/map_battle/lib/map_battle.dart`
- `packages/map_runtime/lib/map_runtime.dart`

## 4. Product Context: PokeMap Surface Engine

PokeMap is evolving from a Flutter map editor into a modern no-code Pokemon-like game creation tool.

The long-term product goal is to let users author:

- maps;
- terrains;
- surfaces;
- NPCs;
- dialogues;
- battles;
- scripts;
- scenes;

without exposing low-level JSON, engine internals, or developer-only concepts.

The active roadmap is the future Surface Engine.

Surface families include:

- water;
- tall grass;
- sand;
- mud;
- ice;
- lava;
- rails;
- roads;
- bridges;
- custom surfaces.

These need cleaner boundaries across:

- visuals;
- animation;
- autotile behavior;
- gameplay;
- runtime integration;
- editor authoring.

Do not make PokeMap depend on Tiled.

Tiled, RMXP, and Pokemon SDK concepts may inspire:

- atlas layout;
- autotile variants;
- animation frames;
- adjacency mapping;

but PokeMap must remain able to author and run its own data.

Water and tall grass may share infrastructure, but they are not the same product case.

Water needs:

- globally synchronized animation;
- robust autotile edges and corners;
- surf gating;
- possible aquatic encounters.

Tall grass needs:

- passability behavior;
- encounters;
- player overlay;
- local rustle animation;
- visual variation.

The migration is intentionally incremental.

Prefer:

- small lots;
- characterization tests;
- pure adapters;
- compatibility checks;
- factual reports;

before persistent model changes.

Do not introduce persistent `SurfaceDefinition`, `surfaceDefinitions`, a unified Surface view, or Surface Engine runtime integration unless the task explicitly asks for that lot.

Legacy surface-related building blocks already exist or are being characterized in `map_core`, including:

- `ProjectTerrainPreset`;
- `ProjectPathPreset`;
- `TerrainLayer`;
- `PathLayer`;
- `TilesetVisualFrame`;
- path/terrain autotile operations;
- timeline helpers;
- legacy surface catalog/adapters/diagnostics/usage views.

## 5. High-Signal Directories

Primary source directories:

- `packages/`
  - Source of truth for libraries and apps.
- `examples/playable_runtime_host/golden_battle_slice/`
  - Versioned runtime fixture.
  - Contains `project.json`, `runtime_host_launch_save.json`, assets, maps, and data.
- `packages/map_editor/test/fixtures/manual_pokemon_import_pack_10/`
  - Versioned import fixture pack.
- `reports/`
  - Tracked engineering reports.
  - Modify only when the task explicitly asks.
- `docs/`
  - Mostly gitignored.
  - Only canonical combat docs are tracked:
    - `docs/combat/battle-canonical-state-v3.1.md`
    - `docs/combat/battle-roadmap-canonical-v3.1.md`

## 6. Working Style

Keep changes minimal and scoped to the impacted package or packages.

Match existing style and naming in touched files.

Do not refactor adjacent code just because it is nearby.

Do not rewrite broad report, fixture, or data areas as part of unrelated code tasks.

Every changed line should trace back to the user request.

When the scope is ambiguous, state the ambiguity and choose the smallest safe interpretation.

When the requested implementation appears larger than necessary, prefer the smaller lower-risk path and explain why.

For Surface Engine lots, keep a conservative posture:

- characterize current behavior before changing it;
- preserve legacy compatibility;
- document weird behavior instead of “fixing” it outside the lot scope;
- avoid speculative abstractions.

## 7. Context Mode Usage

Use Context Mode when an operation may produce large outputs or consume unnecessary context.

Prefer Context Mode for:

- repository-wide searches;
- reading or summarizing many files;
- `git diff`;
- `git log`;
- large `git status` outputs;
- test outputs;
- analyzer outputs;
- build logs;
- generated reports;
- large JSON inspection;
- fixture inspection;
- snapshot inspection.

Do not paste large raw outputs into the conversation when Context Mode can preserve, index, or summarize them.

Summarize only the relevant findings, then mention the command or source that produced them.

Keep exploration and audit responses compact.

Final reports must remain complete and structured.

Final reports must include, when relevant:

- changed files;
- created files;
- deleted files;
- commands run;
- exact test, analyze, and build outcomes;
- known limitations;
- remaining risks;
- self-review or critique.

Context Mode must not be used as an excuse to omit important evidence from the final report.

If Context Mode is unavailable, continue with the normal repo workflow and explicitly say that Context Mode was unavailable.

## 8. Git Safety

Never run Git write operations unless the user explicitly asks for them.

Forbidden operations include:

- `git add`;
- `git commit`;
- `git commit --amend`;
- `git merge`;
- `git rebase`;
- `git push`;
- `git tag`;
- `git stash`;
- `git reset`;
- `git restore`;
- destructive cleanup commands that modify tracked work.

Read-only Git commands are allowed when useful:

- `git status`;
- `git diff`;
- `git log`;
- `git show`;
- `git branch`.

Before making changes, check the working tree with:

```bash
git status --short --untracked-files=all
```

After making changes, report the final working tree with:

```bash
git status --short --untracked-files=all
```

Never hide unrelated pre-existing changes.

If unrelated changes already exist, avoid touching them and mention them in the final report.

## 9. Agent Skills and Review Rituals

### 9.1 Superpowers Skill

Embedded skill: `superpowers:using-superpowers`

Use this when starting work so agents find and invoke relevant skills before responding, clarifying, exploring, or editing.

Subagent exception:

- if dispatched as a subagent for a specific task, skip this skill.

Core rule:

- if there is even a small chance a skill applies, invoke or read the skill first;
- if the invoked skill turns out not to fit, say so briefly and continue with the best workflow.

How to access skills in this Codex repo:

- read the relevant `SKILL.md` from the configured skill path;
- if the advertised path is missing, search for the real local path;
- state the mismatch briefly and continue.

Skill-use flow:

1. Receive the user task.
2. Check whether any skill might apply before taking action.
3. Load the skill content.
4. Announce which skill is being used and why.
5. If the skill has a checklist or strict workflow, follow it.
6. Then respond, clarify, inspect, edit, or verify as appropriate.

Red flags that mean the agent is rationalizing and should stop to check skills:

- “This is just a simple question.”
- “I need more context first.”
- “Let me explore the codebase first.”
- “I can check git/files quickly.”
- “Let me gather information first.”
- “This does not need a formal skill.”
- “I remember this skill.”
- “This does not count as a task.”
- “The skill is overkill.”
- “I will just do this one thing first.”
- “This feels productive.”
- “I know what that means.”

Skill priority when multiple skills apply:

1. Process skills first:
   - brainstorming;
   - planning;
   - systematic debugging;
   - verification.
2. Implementation or domain skills second:
   - frontend;
   - game;
   - Figma;
   - GitHub;
   - package-specific workflows.

Rigid skills, such as TDD and systematic debugging, should be followed closely.

Flexible or pattern skills should be adapted to the repo context.

User instructions define what to do.

Skills guide how to do it.

Do not skip skill workflow just because the user gave a direct implementation request.

### 9.2 Karpathy Guidelines

Embedded skill: `karpathy-guidelines`

Use this when writing, reviewing, or refactoring code and the task benefits from caution around:

- assumptions;
- overcomplication;
- unrelated edits;
- vague success criteria;
- weak verification loops.

Think before coding:

- do not silently choose an interpretation when the request is ambiguous;
- state assumptions explicitly when they affect implementation;
- ask when uncertainty changes scope, data, privacy, API shape, or user-visible behavior;
- present multiple interpretations when more than one is plausible;
- push back when a simpler or lower-risk path better serves the request;
- stop and name confusion rather than coding around it.

Simplicity first:

- write the minimum code that solves the stated problem;
- do not add features beyond what was requested;
- do not create abstractions for single-use code;
- do not add configurability or extension points speculatively;
- do not add error handling for impossible scenarios;
- simplify before proceeding if the implementation feels much larger than the problem.

Surgical changes:

- touch only what the task requires;
- do not refactor adjacent code because it is nearby;
- do not rewrite comments, formatting, or APIs unrelated to the request;
- match the existing style even when a different style seems nicer;
- remove imports, variables, functions, or files made unused by your own change;
- mention unrelated dead code or design issues instead of changing them.

Goal-driven execution:

- convert open-ended work into verifiable success criteria;
- “Add validation” means define invalid inputs, test them, then make the tests pass;
- “Fix the bug” means reproduce it, patch it, and verify the reproduction no longer fails;
- “Refactor X” means confirm behavior before and after with targeted tests or analysis;
- for multi-step tasks, use a short plan with verification signals:
  - inspect affected code;
  - implement the smallest change;
  - run relevant checks.

During code review:

- look first for assumptions that should have been clarified;
- flag over-engineered abstractions or unused flexibility;
- flag drive-by edits outside the requested scope;
- flag missing tests or unclear verification for behavioral changes;
- flag cleanup that removes pre-existing code without a task reason.

### 9.3 Required Review Rituals

Use `systematic-debugging` when a test, analyzer command, parser, serializer, or runtime behavior fails unexpectedly.

Debugging flow:

1. Reproduce first.
2. Inspect the failing path.
3. Make the smallest targeted fix.
4. Verify the fix.

Use `test-driven-development` for new behavior or bug fixes when feasible:

1. Add or adjust a focused failing test.
2. Implement the minimal code.
3. Broaden verification.

Use `verification-before-completion` before claiming work is complete or green.

When reporting verification, include exact commands and exact final outputs, especially full package test totals.

Use `requesting-code-review` or an explicit review stance for substantial changes or when the user asks for a review.

Review findings should lead, with file and line references when available.

## 10. Code Generation

Regenerate code only in the package you changed.

Include generated outputs required by tracked sources.

For `packages/map_core`:

```bash
dart run build_runner build --delete-conflicting-outputs
```

For `packages/map_editor`:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

For `packages/map_runtime`:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

Avoid unrelated generated-file churn.

Do not run build generators globally unless explicitly requested.

## 11. Validation Matrix

Prefer targeted tests first, then broaden if needed.

Pure Dart packages:

```bash
cd packages/map_core && dart test
cd packages/map_gameplay && dart test
cd packages/map_battle && dart test
```

Flutter packages and apps:

```bash
cd packages/map_runtime && flutter test
cd packages/map_editor && flutter test
cd examples/playable_runtime_host && flutter test
```

Static analysis:

```bash
dart analyze
flutter analyze
```

Runtime smoke checks commonly used in this repo:

```bash
cd packages/map_runtime && flutter test test/phase_a_golden_battle_slice_smoke_test.dart
cd examples/playable_runtime_host && flutter test test/phase_a_golden_slice_launch_test.dart
```

For pure Dart packages, use `dart analyze`.

For Flutter packages and apps, use `flutter analyze`.

When tests cannot be run, explain exactly why and what should be run next.

## 12. Scripts and Utilities

Coverage and report wrappers at repo level:

```bash
scripts/generate_phase_a_battle_coverage.sh
scripts/generate_phase_b_scaffold_pack_coverage.sh
```

Tool entrypoints:

```bash
packages/map_editor/tool/export_embedded_pokemon_moves_bootstrap.dart
packages/map_runtime/tool/phase_a_battle_coverage.dart
packages/map_runtime/tool/phase_b_scaffold_pack_coverage.dart
```

Some scripts and docs use:

```bash
/opt/homebrew/bin/flutter
```

Prefer `flutter` from `PATH` unless a task explicitly requires a fixed binary.

## 13. Reports

Reports under `reports/analysis/` are part of the roadmap.

When a task asks for a report, make it factual.

Reports should include:

- inspected files;
- exact commands;
- exact test totals;
- known gaps;
- assumptions;
- limitations;
- evidence for claims.

Avoid unverifiable claims such as memory guarantees without a measured command.

Do not modify reports unless the task explicitly asks for it.

## 14. File Hygiene

Do not add new cache or generated artifacts unless explicitly required.

Avoid adding:

- `.dart_tool/`;
- `build/`;
- temporary files;
- local IDE files;
- machine-specific files.

Avoid lockfile churn unless dependency updates are part of the task.

The repository currently contains a few historically tracked generated artifacts, notably under:

- `packages/map_gameplay/.dart_tool/`;
- `packages/map_gameplay/build/`.

Do not modify or clean these unless the task is explicitly a hygiene cleanup.

`pubspec.lock` is currently tracked in some app/package directories, for example:

- `packages/map_editor`;
- `packages/map_gameplay`;
- `examples/playable_runtime_host`.

Keep lockfile changes intentional.

Respect `.gitignore` rules and existing tracked/untracked boundaries, especially docs and large fixture/report areas.

## 15. Notes for Agents

Check for deeper `AGENTS.md` files before editing in subdirectories.

Before structural changes, read the nearest:

- `pubspec.yaml`;
- package `README.md`, when present.

Before touching a package, understand whether it is:

- pure Dart;
- Flutter;
- runtime;
- editor;
- battle;
- gameplay;
- shared contract.

Do not assume package boundaries from names alone.

When working on a lot, preserve the lot scope.

Do not opportunistically fix unrelated issues.

If you discover unrelated issues, mention them in the final report instead of changing them.

Final responses after code work should include:

- summary of what changed;
- files changed;
- validation commands run;
- exact results;
- limitations or skipped checks;
- final `git status --short --untracked-files=all`;
- self-review for substantial changes.
