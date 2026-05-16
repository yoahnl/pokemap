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

If this file conflicts with repository-local safety rules, prefer the stricter rule and report the conflict.

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

## 5. Product Context: PokeMap Catalogues

PokeMap catalogues are broader than a single Pokédex surface.

Think in terms of distinct authoring workspaces for:

- Pokédex;
- Moves;
- Items;
- battle-related data;
- future content catalogues.

Avoid naming, layout, or architecture that permanently locks the product into a single "Pokédex only" concept when the feature actually belongs to broader Pokemon-like catalogues.

The UI must remain no-code friendly:

- clear vocabulary;
- visible previews;
- guided actions;
- minimal manual IDs;
- minimal raw JSON;
- no engine jargon unless explicitly needed.

## 6. Product Context: Environment Studio

Environment Studio is intended to generate organic environments such as forests, coastal vegetation, shrubs, grass clusters, cliffs, or other natural arrangements.

The target workflow is not a separate toy canvas.

Prefer editor-integrated authoring:

- user selects a map area or paints with a brush-like tool;
- user chooses an environment preset;
- user adjusts parameters in an inspector;
- generation happens deterministically on the selected map data.

Generation parameters may include:

- seed;
- density;
- variation;
- edge density;
- minimum spacing in cells;
- tileset or element constraints.

Avoid letting generated elements come from an unrelated tileset when that would break consistency.

Prefer simple, understandable UI over technically clever controls.

A non-technical user should be able to understand what the editor is asking.

## 7. High-Signal Directories

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

## 8. Working Style

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
- document weird behavior instead of "fixing" it outside the lot scope;
- avoid speculative abstractions.

For UI/editor work:

- avoid oversized cards and repetitive titles;
- keep inspector panels readable;
- prioritize previewability;
- favor guided dropdowns and pickers over manual IDs;
- preserve no-code product semantics.

## 9. Context Mode Usage

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
- a complete file inventory that lists every created, modified, deleted, generated, and still-untracked file touched by the task;
- commands run;
- exact test, analyze, and build outcomes;
- known limitations;
- remaining risks;
- self-review or critique.

The file inventory is mandatory for lot reports and implementation reports.

Do not summarize it as "see git status" or rely only on `git diff --stat`, because untracked files do not appear there.

Reconcile the inventory against:

```bash
git status --short --untracked-files=all
```

and, when useful:

```bash
git diff --name-only
```

If a category is empty, explicitly write `Aucun` / `None`.

Lot reports and implementation reports must also include the complete contents of every text/code file created or modified by the task, in fenced code blocks under a clearly named section such as `Code complet des fichiers créés/modifiés`.

Do not replace this with summaries, snippets, diffs, or file paths.

Generated text files are included when they are part of the task output.

Binary assets must be listed with path, size, and hash instead of inlined.

The report file itself does not need to embed a recursive copy of itself; the report is already the complete contents of that file.

Context Mode must not be used as an excuse to omit important evidence from the final report.

If Context Mode is unavailable, continue with the normal repo workflow and explicitly say that Context Mode was unavailable.

## 10. Git Safety

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
- `git checkout` when it changes files or branches;
- `git switch`;
- `git branch` creation, deletion, or rename;
- `git worktree add`;
- `git worktree remove`;
- destructive cleanup commands that modify tracked work.

Read-only Git commands are allowed when useful:

- `git status`;
- `git diff`;
- `git log`;
- `git show`;
- `git branch` without write flags;
- `git worktree list`.

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

Subagents must not run Git write operations.

Subagents must report their final working tree state instead of committing.

Only the user may decide when to commit, amend, merge, rebase, push, tag, stash, reset, restore, switch branches, create branches, or create worktrees.

## 11. Agent Skills and Review Rituals

### 11.1 Superpowers Skill

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

### 11.2 Karpathy Guidelines

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
- "Add validation" means define invalid inputs, test them, then make the tests pass;
- "Fix the bug" means reproduce it, patch it, and verify the reproduction no longer fails;
- "Refactor X" means confirm behavior before and after with targeted tests or analysis;
- for multi-step tasks, use a short plan with verification signals:
    - inspect affected code;
    - implement the smallest change;
    - run relevant checks.

During code review:

- look first for assumptions that should have been been clarified;
- flag over-engineered abstractions or unused flexibility;
- flag drive-by edits outside the requested scope;
- flag missing tests or unclear verification for behavioral changes;
- flag cleanup that removes pre-existing code without a task reason.

### 11.3 Required Review Rituals

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

## 12. Code Generation

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

## 13. Validation Matrix

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

## 14. Scripts and Utilities

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

## 15. Flame MCP Server

This repository uses Flame through `packages/map_runtime` and `examples/playable_runtime_host`.

When working on anything related to Flame, the runtime, rendering, game loop, camera, overlays, input, components, collision, lifecycle, `PositionComponent`, `SpriteComponent`, `SpriteAnimationComponent`, `Component`, `World`, `CameraComponent`, assets, or Flame integration, use the configured Flame MCP server before proposing or implementing changes.

Expected MCP server name:

- `flame_docs`

The Flame MCP server is a documentation source for Flame APIs and tutorials.

It helps prevent invented, outdated, or hallucinated Flame usage.

Required workflow for Flame-related tasks:

1. Use `flame_docs` to search the relevant Flame documentation before implementation.
2. Summarize the documentation findings that matter for the task.
3. Compare the findings with the existing PokeMap runtime architecture.
4. Explain how the proposed implementation respects both:
    - documented Flame behavior;
    - PokeMap package boundaries and architecture.
5. Only then modify code.

Use `flame_docs` especially for:

- Flame component lifecycle;
- `onLoad`, `onMount`, `update`, `render`, removal, and cleanup behavior;
- `PositionComponent`, `SpriteComponent`, and `SpriteAnimationComponent`;
- camera and viewport behavior;
- `World` and component hierarchy;
- Flame overlays and Flutter widget integration;
- collision and hitbox APIs;
- input handling;
- asset loading;
- render ordering and priority behavior;
- runtime performance questions.

Do not use Flame MCP as an excuse to bypass local project architecture.

The MCP documentation can explain Flame, but it does not define PokeMap architecture.

PokeMap rules still take precedence:

- pure Dart packages must not import Flutter or Flame;
- Flame code belongs in `map_runtime`;
- editor code must not couple directly to runtime rendering internals;
- shared contracts belong in `map_core`;
- gameplay rules should not be hidden inside Flame components.

If the Flame MCP server is unavailable:

1. State clearly that `flame_docs` was unavailable.
2. Do not invent Flame APIs.
3. Inspect the installed Flame version in the relevant `pubspec.yaml` and lockfile.
4. Search existing runtime code for working local patterns.
5. Continue with the smallest safe implementation or stop if the missing documentation changes the design risk.

For final implementation reports involving Flame, include:

- whether `flame_docs` was used;
- which Flame topics were searched;
- relevant findings;
- how the implementation aligns with those findings;
- any uncertainty caused by missing or incomplete MCP results.

## 16. Reports

Reports under `reports/analysis/` are part of the roadmap.

When a task asks for a report, make it factual.

Reports should include:

- inspected files;
- complete files created / modified / deleted inventories, including untracked files and generated files;
- complete contents of every text/code file created or modified by the task, not just snippets or diffs;
- exact commands;
- exact test totals;
- known gaps;
- assumptions;
- limitations;
- evidence for claims.

Avoid unverifiable claims such as memory guarantees without a measured command.

Do not modify reports unless the task explicitly asks for it.

## 17. File Hygiene

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

## 18. Notes for Agents

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

Do not express performative agreement or gratitude.

Actions speak louder than words.

State facts, show evidence.

---

## 19. Superpowers Workflow Integration

Core principle: skills guide how to execute work. User instructions define what to do.

When in doubt, invoke relevant skills before responding.

### 19.1 Skill Invocation Discipline

Iron Law: if there is even a 1% chance a skill might apply, invoke it.

Skills override default behavior where they conflict with default agent behavior, but direct user instructions, this `AGENTS.md`, repository safety rules, and deeper `AGENTS.md` files take precedence.

When to invoke skills:

- starting any conversation;
- beginning any task;
- encountering bugs, test failures, or unexpected behavior;
- completing tasks before claiming success;
- writing plans or specs;
- requesting or receiving code review;
- executing implementation plans;
- finishing development branches.

Red flags that mean the agent must stop and check skills:

- "This is just a simple question";
- "I need more context first";
- "Let me explore the codebase first";
- "I can check git/files quickly";
- "Let me gather information first";
- "This does not need a formal skill";
- "I remember this skill";
- "This does not count as a task";
- "The skill is overkill";
- "I will just do this one thing first";
- "This feels productive";
- "I know what that means."

### 19.2 Process Skills Priority

When multiple skills could apply, follow this order:

1. Brainstorming (`superpowers:brainstorming`) before creative work.
2. Writing plans (`superpowers:writing-plans`) for multi-step tasks.
3. Systematic debugging (`superpowers:systematic-debugging`) for any bug or failure.
4. Verification before completion (`superpowers:verification-before-completion`) before claiming success.
5. Requesting code review (`superpowers:requesting-code-review`) after substantial completed work.

### 19.3 Implementation Workflows

#### 19.3.1 Subagent-Driven Development

For execution of implementation plans with independent tasks in the current session:

1. Use `superpowers:subagent-driven-development` when applicable.
2. Dispatch one fresh subagent per task.
3. Each subagent implements, tests, reports final git status, and self-reviews.
4. Each subagent must not run Git write operations.
5. Review each subagent result for:
    - spec compliance;
    - code quality;
    - package boundary compliance;
    - validation evidence.
6. Fix issues in review loops before proceeding.
7. Do not dispatch multiple implementers in parallel unless the task is explicitly a parallel investigation.

Model selection:

- 1-2 files, clear spec: fast, cheap model.
- Multi-file integration: standard model.
- Architecture/design judgment: most capable model.

#### 19.3.2 Executing Plans in a Separate Session

For execution in a separate session:

1. Use `superpowers:executing-plans` when applicable.
2. Load and critically review the plan first.
3. Execute tasks sequentially with verification.
4. Do not run Git write operations unless the user explicitly asks.
5. Use `superpowers:finishing-a-development-branch` only as a reporting and option-selection workflow unless the user explicitly authorizes a Git write operation.

#### 19.3.3 Parallel Investigation

For 3 or more independent failures across different subsystems:

1. Use `superpowers:dispatching-parallel-agents` when applicable.
2. Identify independent problem domains.
3. Create focused agent tasks, one per domain.
4. Dispatch in parallel only for investigation or review, not overlapping implementation.
5. Review and integrate results.
6. Verify no conflicts.
7. Run the relevant test suite.

### 19.4 Debugging Discipline

Iron Law: no fixes without root cause investigation first.

When encountering any bug, test failure, analyzer failure, parser failure, serializer failure, or unexpected runtime behavior:

1. Root cause investigation:
    - read complete error messages and stack traces;
    - reproduce consistently;
    - check recent changes with read-only Git commands;
    - gather evidence at layer boundaries;
    - trace data flow backward to find the origin.
2. Pattern analysis:
    - find working examples of similar code;
    - compare against reference implementations;
    - identify all relevant differences;
    - understand dependencies.
3. Hypothesis and testing:
    - form one clear hypothesis;
    - test minimally;
    - verify before continuing;
    - if the hypothesis is wrong, form a new hypothesis instead of piling on fixes.
4. Implementation:
    - create a failing test case when feasible;
    - implement one targeted fix addressing the root cause;
    - verify the fix;
    - if 3 or more fixes fail, stop and question the architecture or assumptions.

Red flags:

- quick fixes;
- multiple changes at once;
- skipping test creation;
- "just try this";
- proceeding after 2 or more failed attempts without revisiting root cause.

### 19.5 Test-Driven Development

Iron Law: for new behavior or bug fixes, prefer a failing test before production code whenever feasible.

TDD flow:

1. RED:
    - write the minimal failing test;
    - run it;
    - verify it fails for the expected reason.
2. GREEN:
    - write the minimal code to pass;
    - run the test;
    - ensure no regression in the targeted area.
3. REFACTOR:
    - clean up without behavior changes;
    - keep tests green.
4. Repeat for the next behavior.

Requirements:

- one behavior per test;
- clear test names;
- real code over mocks when feasible;
- watched failure before implementation when practical.

If TDD is not feasible, state why and provide another verification strategy.

### 19.6 Verification Before Completion

Iron Law: no completion claims without fresh verification evidence.

Before claiming any status:

1. Identify which command proves the claim.
2. Run the full command.
3. Read the full output.
4. Check exit code and failures.
5. Verify the output supports the claim.
6. State the claim with evidence or state the actual status.

This applies to:

- tests passing;
- analyzer clean;
- build succeeds;
- bug fixed;
- regression test works;
- implementation completed;
- requirements met.

Avoid:

- "should work";
- "probably";
- "seems to";
- relying only on partial verification;
- trusting an agent success report without checking.

### 19.7 Code Review Process

#### 19.7.1 Requesting Code Review

After substantial completed work, use `superpowers:requesting-code-review` or an explicit review stance.

Review should check:

- spec compliance;
- package boundaries;
- hidden architecture drift;
- out-of-scope changes;
- missing tests;
- weak verification;
- UI/product consistency;
- report completeness.

When a code-review subagent is used:

1. Provide exact task context.
2. Provide relevant diffs or file paths.
3. Request findings by severity.
4. Review findings before changing code.
5. Push back when the reviewer is wrong.

#### 19.7.2 Receiving Code Review

Use `superpowers:receiving-code-review` when applicable.

Process:

1. Read complete feedback without reacting.
2. Restate the technical requirement.
3. Verify the claim against codebase reality.
4. Evaluate whether it is technically sound for this codebase.
5. Implement one item at a time.
6. Test each fix.
7. Verify no regressions.

Forbidden responses:

- "You're absolutely right!";
- "Great point!";
- "Let me implement that now" before verification;
- any performative gratitude expression.

Instead:

- state the technical requirement;
- ask clarifying questions when needed;
- push back with technical reasoning when wrong;
- act with evidence.

### 19.8 Git Worktrees

Using Git worktrees is a Git write operation when creating or removing worktrees.

Do not create, remove, or modify worktrees unless the user explicitly asks.

Allowed without explicit permission:

```bash
git worktree list
```

If the user explicitly asks to use a worktree:

1. Check existing directories such as `.worktrees/` and `worktrees/`.
2. Check whether the directory is ignored.
3. Ask for confirmation if the location or branch name is ambiguous.
4. Create the worktree only after explicit permission.
5. Do not commit from the worktree unless the user explicitly asks.
6. Report worktree path and status.

### 19.9 Finishing Development Branch

Use `superpowers:finishing-a-development-branch` as a reporting workflow.

Before presenting branch completion options:

1. Verify tests pass or state exactly what failed.
2. Determine the base branch with read-only commands.
3. Present options without executing Git writes automatically.

Allowed options to present:

```text
1. Merge back to <base-branch> locally
2. Push and create a Pull Request
3. Keep the branch as-is
4. Discard this work
```

Do not execute any option until the user explicitly chooses it.

Never merge, push, delete, reset, restore, stash, or clean without explicit user instruction.

### 19.10 Brainstorming Before Implementation

Do not invoke implementation skills, write code, scaffold a project, or take implementation action until a design has been presented and approved when the task is creative, structural, architectural, or product-facing.

For creative work such as features, components, behavior changes, or UI:

1. Explore project context.
2. Offer visual companion if visual questions matter.
3. Ask clarifying questions only when they materially change scope.
4. Propose 2-3 approaches with trade-offs and a recommendation.
5. Present a design scaled to complexity.
6. Write a design doc only when the user or lot workflow requires it.
7. Self-review the design for placeholders, contradictions, ambiguity, and scope.
8. Wait for approval before implementation.

For tightly scoped mechanical changes, use the smallest safe workflow and still preserve verification.

### 19.11 Writing Plans

Use `superpowers:writing-plans` to create implementation plans when needed.

Plan structure:

1. Goal.
2. Architecture and package boundaries.
3. File structure.
4. Bite-sized tasks.
5. Exact file paths.
6. Commands to run.
7. Expected verification signals.
8. Risks and non-goals.

Requirements:

- no placeholders such as `TBD`, `TODO`, or "implement later";
- exact file paths;
- no speculative scope;
- no Git write operations unless explicitly requested by the user;
- tests and verification included.

After plan:

- self-review for spec coverage;
- scan for placeholders;
- check type and package consistency;
- ask for user review when the plan affects architecture or product behavior.

### 19.12 Execution Options

After plan creation, offer:

Option 1: Subagent-driven execution

- fresh subagent per task;
- review checkpoints;
- no Git write operations;
- final status report.

Option 2: Inline execution

- same session execution;
- use executing-plans workflow;
- review plan critically first;
- stop when blocked.

### 19.13 Lot-Specific Workflows

For PathPattern, Surface Engine, battle, shadow, runtime, or editor lots, adapt superpowers workflows to lot methodology.

Before starting a lot:

1. Read the relevant roadmap or previous report when available.
2. Check previous lot reports for decisions and constraints.
3. Review non-goals confirmed in prior lots.
4. Identify dependencies.

During lot execution:

1. Follow the 10-point lot report template when applicable:
    - Verdict;
    - Audit;
    - Files;
    - Decisions;
    - Non-goals;
    - Tests;
    - Analyze;
    - Git Status;
    - Limits;
    - Next Lot.
2. Use Context Mode for large audits.
3. Document all commands run with exact outputs.
4. List every file created, modified, deleted, generated, and left untracked.
5. Reconcile file inventory with `git status --short --untracked-files=all`.
6. Include the full contents of every text/code file created or modified by the lot.
7. Never modify files outside lot scope without explicit user consent.

After completing a lot:

1. Run targeted tests.
2. Run regression tests for dependent areas.
3. Run full package tests when feasible.
4. Include a complete Evidence Pack.

### 19.14 Common Anti-Patterns

Debugging anti-patterns:

- quick fixes without root cause investigation;
- multiple changes at once;
- skipping test case creation;
- proceeding after repeated failed fixes without revisiting assumptions;
- assuming data flow without tracing it.

TDD anti-patterns:

- code before test when TDD is feasible;
- test passes immediately without proving the bug;
- tests written after implementation and treated as proof;
- "I already manually tested";
- keeping throwaway code as reference.

Verification anti-patterns:

- claiming success without running verification;
- using "should", "probably", or "seems to";
- trusting agent reports without checking;
- relying on partial verification.

Code review anti-patterns:

- performative agreement;
- blind implementation without verification;
- batch fixes without testing each;
- avoiding pushback when reviewer is wrong;
- partial implementation of unclear feedback.

Planning anti-patterns:

- placeholders;
- vague steps;
- missing file paths;
- incomplete verification;
- speculative abstractions.

---

## 20. Project-Specific Superpowers Adaptations

### 20.1 TDD for Dart/Flutter

RED phase:

```bash
dart test test/path/to/test.dart
flutter test test/path/to/test.dart
```

Verify the test fails for the expected reason.

GREEN phase:

- write minimal Dart code to pass;
- use `package:test` conventions;
- match existing test patterns.

REFACTOR phase:

- run the targeted test again;
- run broader tests when risk justifies it;
- use `dart analyze` or `flutter analyze` as appropriate.

Dart-specific tips:

- use `expect()` for assertions;
- test both success and error cases;
- use `setUp()` and `tearDown()` for fixtures;
- avoid mocks unless they reduce coupling to external systems.

### 20.2 Systematic Debugging for Dart

Phase 1 adaptations:

- use `dart analyze --format json` for static analysis errors when useful;
- use `dart test --reporter expanded` for detailed test output;
- check `pubspec.yaml` and lockfiles for dependency issues;
- use `flutter doctor -v` for environment problems.

Phase 2 pattern analysis:

- search existing code with `rg`;
- compare with working examples in test directories;
- check golden files and fixture directories.

Phase 3 hypothesis:

- create minimal reproduction when feasible;
- use `dart run` for scripts;
- keep changes minimal.

Phase 4 implementation:

- create a failing test case first when feasible;
- run the focused test;
- fix and verify.

### 20.3 Verification Commands Matrix

| Claim | Package | Command | Success Criteria |
|-------|---------|---------|------------------|
| Tests pass | map_core | `dart test` | All tests pass, 0 failures |
| Tests pass | map_gameplay | `dart test` | All tests pass, 0 failures |
| Tests pass | map_battle | `dart test` | All tests pass, 0 failures |
| Tests pass | map_editor | `flutter test` | All tests pass, 0 failures |
| Tests pass | map_runtime | `flutter test` | All tests pass, 0 failures |
| Tests pass | playable_runtime_host | `flutter test` | All tests pass, 0 failures |
| Static analysis | map_core | `dart analyze` | 0 errors, 0 warnings |
| Static analysis | map_gameplay | `dart analyze` | 0 errors, 0 warnings |
| Static analysis | map_battle | `dart analyze` | 0 errors, 0 warnings |
| Static analysis | map_editor | `flutter analyze` | 0 errors, 0 warnings |
| Static analysis | map_runtime | `flutter analyze` | 0 errors, 0 warnings |
| Static analysis | playable_runtime_host | `flutter analyze` | 0 errors, 0 warnings |
| Build runner | map_core | `dart run build_runner build --delete-conflicting-outputs` | Exit code 0 |
| Build runner | map_editor | `flutter pub run build_runner build --delete-conflicting-outputs` | Exit code 0 |
| Build runner | map_runtime | `flutter pub run build_runner build --delete-conflicting-outputs` | Exit code 0 |

Always include:

- command used;
- output summary;
- exit code when available;
- package path;
- timestamp when useful.

### 20.4 Git Worktree Integration

Worktree creation and removal are forbidden unless explicitly requested by the user.

For lot development, do not assume worktrees are allowed.

Read-only inspection is allowed:

```bash
git worktree list
```

If the user explicitly requests worktree isolation, use a safe process:

```bash
git worktree list
git check-ignore -q .worktrees || echo ".worktrees not ignored"
```

Then ask or proceed only according to the user's explicit instruction.

Do not create a branch or worktree silently.

### 20.5 Code Review Checklist

Spec compliance:

- [ ] follows lot scope;
- [ ] respects confirmed non-goals;
- [ ] respects package boundaries;
- [ ] avoids breaking public APIs without migration;
- [ ] preserves no-code product semantics when UI/editor is involved.

Code quality:

- [ ] follows Dart style;
- [ ] uses existing naming conventions;
- [ ] respects null safety;
- [ ] uses immutable structures where appropriate;
- [ ] has no unused imports;
- [ ] has no dead code introduced by the task;
- [ ] avoids speculative abstractions.

Testing:

- [ ] tests added for new behavior when feasible;
- [ ] targeted tests pass;
- [ ] relevant regression tests pass or skipped with explanation;
- [ ] tests follow existing patterns.

Documentation and report:

- [ ] report follows the requested template;
- [ ] Evidence Pack is complete;
- [ ] decisions are documented;
- [ ] limitations are explicit;
- [ ] final git status is included.

---

## 21. Quick Reference: When to Use Which Skill

| Scenario | Primary Skill | Secondary Skills |
|----------|---------------|------------------|
| Starting any task | `using-superpowers` | - |
| Brainstorming feature | `brainstorming` | `writing-plans` |
| Writing implementation plan | `writing-plans` | - |
| Bug or test failure | `systematic-debugging` | `test-driven-development`, `verification-before-completion` |
| Implementing feature or bugfix | `test-driven-development` | `verification-before-completion`, `requesting-code-review` |
| Completing task | `verification-before-completion` | `requesting-code-review` |
| Executing plan in same session | `subagent-driven-development` or `executing-plans` | `systematic-debugging`, `test-driven-development` |
| Executing plan in another session | `executing-plans` | `verification-before-completion` |
| Multiple independent failures | `dispatching-parallel-agents` | `systematic-debugging` |
| Requesting review | `requesting-code-review` | - |
| Receiving review feedback | `receiving-code-review` | - |
| Finishing branch | `finishing-a-development-branch` | Git Safety rules |
| Starting feature work | `brainstorming` | `writing-plans`, Git Safety rules |
| Flame runtime work | `using-superpowers` | `flame_docs` MCP, `verification-before-completion` |

---

## 22. Rationalization Prevention

If you catch yourself thinking these, stop and invoke the relevant skill:

| Thought | Skill to Invoke | Why |
|---------|----------------|-----|
| "This is just a simple question" | `using-superpowers` | Check for skills first |
| "I need more context first" | `using-superpowers` | Skills guide context gathering |
| "Let me explore the codebase first" | `using-superpowers` | Skills guide exploration |
| "I can check git/files quickly" | `using-superpowers` | Skills define safe checks |
| "This does not need a formal skill" | `using-superpowers` | If a skill exists, use it |
| "Just try changing X and see if it works" | `systematic-debugging` | No fixes without root cause |
| "I'll write tests after" | `test-driven-development` | Prefer failing test first |
| "Should work now" | `verification-before-completion` | Run verification |
| "Tests pass, phase complete" | `verification-before-completion` | Need fresh evidence |
| "I'm confident" | `verification-before-completion` | Confidence is not evidence |
| "Let me implement that now" | `receiving-code-review` | Verify feedback first |
| "You're absolutely right!" | `receiving-code-review` | No performative agreement |
| "Flame probably has an API for that" | `flame_docs` MCP | Do not invent Flame APIs |

The purpose of skills is to prevent rationalizations that lead to wasted work, bugs, and rework.

When in doubt, invoke the skill.

---

## 23. AGENTS.md Maintenance Notes

This file is a Markdown instruction file.

Do not claim it passes Dart static analysis.

Recommended verification after editing this file:

```bash
git diff -- AGENTS.md
```

Manual checks:

- headings are correctly numbered;
- no internal instruction conflicts remain;
- Git safety rules are consistent;
- Flame MCP usage is documented;
- package boundaries are preserved;
- final workflow still matches the project constraints.

Known intentional constraints:

- Git write operations are forbidden unless the user explicitly asks.
- Subagents must not commit.
- Worktrees must not be created unless the user explicitly asks.
- Flame-related implementation should consult `flame_docs` before design or code.
- Reports must include complete inventories and full contents of modified text/code files when relevant.

Last updated intent:

- integrate Flame MCP usage;
- remove Git write contradictions;
- preserve PokeMap package boundaries;
- keep Superpowers workflows useful without allowing unsafe Git operations.
