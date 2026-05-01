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

Do not express performative agreement or gratitude. Actions speak louder than words. State facts, show evidence.

---

## 16. Superpowers Workflow Integration

**Core principle:** Skills guide HOW to execute work. User instructions define WHAT to do. When in doubt, invoke relevant skills BEFORE responding.

### 16.1 Skill Invocation Discipline

**Iron Law:** If there is even a 1% chance a skill might apply, you MUST invoke it. Skills override default behavior where they conflict with system prompts, but user instructions (this AGENTS.md, CLAUDE.md, direct requests) always take precedence.

**When to invoke skills:**
- Starting any conversation
- Beginning any task
- Encountering bugs, test failures, or unexpected behavior
- Completing tasks (before claiming success)
- Writing plans or specs
- Requesting or receiving code review
- Executing implementation plans
- Finishing development branches

**Red flags (STOP and check skills):**
- "This is just a simple question"
- "I need more context first"
- "Let me explore the codebase first"
- "I can check git/files quickly"
- "Let me gather information first"
- "This does not need a formal skill"
- "I remember this skill"
- "This does not count as a task"
- "The skill is overkill"
- "I will just do this one thing first"
- "This feels productive"
- "I know what that means"

### 16.2 Process Skills Priority

When multiple skills could apply, follow this order:

1. **Brainstorming** (superpowers:brainstorming) - Before any creative work
2. **Writing Plans** (superpowers:writing-plans) - For multi-step tasks
3. **Systematic Debugging** (superpowers:systematic-debugging) - For any bug or failure
4. **Verification Before Completion** (superpowers:verification-before-completion) - Before claiming success
5. **Requesting Code Review** (superpowers:requesting-code-review) - After completing tasks

### 16.3 Implementation Workflows

#### 16.3.1 Subagent-Driven Development (Recommended)

For execution of implementation plans with independent tasks in the current session:

1. **REQUIRED:** Use superpowers:subagent-driven-development
2. Dispatch one fresh subagent per task
3. Each subagent: implements → tests → commits → self-reviews
4. Two-stage review per task:
   - Stage 1: Spec compliance review
   - Stage 2: Code quality review
5. Fix issues in review loops before proceeding
6. **NEVER:** Skip reviews, proceed with unfixed issues, or dispatch multiple implementers in parallel

**Model selection:** Use the least powerful model that can handle the task:
- 1-2 files, clear spec → fast, cheap model
- Multi-file integration → standard model
- Architecture/design judgment → most capable model

#### 16.3.2 Executing Plans (Parallel Session)

For execution in a separate session:

1. **REQUIRED:** Use superpowers:executing-plans
2. Load and critically review plan first
3. Execute tasks sequentially with verification
4. **REQUIRED:** Use superpowers:finishing-a-development-branch after all tasks

#### 16.3.3 Parallel Investigation

For 3+ independent failures across different subsystems:

1. **REQUIRED:** Use superpowers:dispatching-parallel-agents
2. Identify independent problem domains
3. Create focused agent tasks (one per domain)
4. Dispatch in parallel
5. Review and integrate results
6. Verify no conflicts, run full test suite

### 16.4 Debugging Discipline

**Iron Law:** NO FIXES WITHOUT ROOT CAUSE INVESTIGATION FIRST.

When encountering any bug, test failure, or unexpected behavior:

1. **Phase 1: Root Cause Investigation**
   - Read error messages carefully (complete stack traces)
   - Reproduce consistently (exact steps, happens every time?)
   - Check recent changes (git diff, commits, config changes)
   - Gather evidence in multi-component systems (log at each layer boundary)
   - Trace data flow backward to find origin

2. **Phase 2: Pattern Analysis**
   - Find working examples of similar code
   - Compare against reference implementations
   - Identify all differences, however small
   - Understand dependencies

3. **Phase 3: Hypothesis and Testing**
   - Form single clear hypothesis
   - Test minimally (smallest possible change)
   - Verify before continuing
   - If hypothesis wrong, form NEW hypothesis (don't add fixes)

4. **Phase 4: Implementation**
   - Create failing test case (REQUIRED)
   - Implement single fix addressing root cause
   - Verify fix works
   - If 3+ fixes failed: STOP and question architecture

**Red flags:** Quick fixes, multiple changes at once, skipping test creation, "just try this", proceeding after 2+ failed attempts.

### 16.5 Test-Driven Development

**Iron Law:** NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST.

For any feature or bugfix:

1. **RED:** Write minimal failing test
2. **Verify RED:** Watch it fail for expected reason (not typos)
3. **GREEN:** Write minimal code to pass
4. **Verify GREEN:** Watch it pass, ensure no regressions
5. **REFACTOR:** Clean up (no behavior changes, tests stay green)
6. **Repeat:** Next failing test

**Requirements:**
- One behavior per test
- Clear test names (describe behavior, not implementation)
- Real code (mocks only if unavoidable)
- Watched test fail BEFORE implementing

**Red flags:** Code before test, test passes immediately, tests written after, "I already manually tested", keeping code as "reference".

**If code exists before test:** DELETE IT. Start over with TDD.

### 16.6 Verification Before Completion

**Iron Law:** NO COMPLETION CLAIMS WITHOUT FRESH VERIFICATION EVIDENCE.

Before claiming any status or expressing satisfaction:

1. **IDENTIFY:** What command proves this claim?
2. **RUN:** Execute the FULL command (fresh, complete)
3. **READ:** Full output, check exit code, count failures
4. **VERIFY:** Does output confirm the claim?
   - If NO: State actual status with evidence
   - If YES: State claim WITH evidence
5. **ONLY THEN:** Make the claim

**Gate function applies to:**
- Tests passing claims
- Linter clean claims
- Build succeeds claims
- Bug fixed claims
- Regression test works claims
- Agent completed claims
- Requirements met claims

**Red flags:** "Should work", "I'm confident", "just this once", "Linter passed" (≠ compiler), "Agent said success", "I'm tired".

### 16.7 Code Review Process

#### 16.7.1 Requesting Code Review

After completing tasks, use superpowers:requesting-code-review:

1. Get git SHAs (base and head)
2. Dispatch code-reviewer subagent with context
3. Act on feedback:
   - Fix Critical issues immediately
   - Fix Important issues before proceeding
   - Note Minor issues for later
   - Push back if reviewer is wrong (with reasoning)

#### 16.7.2 Receiving Code Review

Use superpowers:receiving-code-review:

1. **READ** complete feedback without reacting
2. **UNDERSTAND** requirement in own words (or ask)
3. **VERIFY** against codebase reality
4. **EVALUATE** technically sound for THIS codebase?
5. **RESPOND** with technical acknowledgment or reasoned pushback
6. **IMPLEMENT** one item at a time, test each

**Forbidden responses:**
- "You're absolutely right!"
- "Great point!"
- "Let me implement that now" (before verification)
- Any gratitude expression

**Instead:**
- Restate the technical requirement
- Ask clarifying questions
- Push back with technical reasoning if wrong
- Just start working (actions > words)

**If unclear:** STOP. Ask for clarification on ALL unclear items before implementing.

**Implementation order:**
1. Clarify anything unclear FIRST
2. Blocking issues (breaks, security)
3. Simple fixes (typos, imports)
4. Complex fixes (refactoring, logic)
5. Test each fix individually
6. Verify no regressions

**Push back when:**
- Suggestion breaks existing functionality
- Reviewer lacks full context
- Violates YAGNI
- Technically incorrect for this stack
- Conflicts with architectural decisions

### 16.8 Git Worktrees for Isolation

**REQUIRED:** Use superpowers:using-git-worktrees before starting feature work.

Process:
1. Check existing directories (`.worktrees/`, `worktrees/`)
2. Check CLAUDE.md for preference
3. Ask user if ambiguous
4. **CRITICAL:** Verify directory is ignored (git check-ignore) for project-local
5. Create worktree with new branch
6. Run project setup (auto-detect: npm, cargo, pip, go)
7. Verify clean baseline (run tests)
8. Report location and status

**Never:** Create worktree without ignore verification, skip baseline test, proceed with failing tests.

### 16.9 Finishing Development Branch

Use superpowers:finishing-a-development-branch when implementation is complete:

1. **Verify tests pass** (MANDATORY - stop if failing)
2. Determine base branch
3. Present exactly these 4 options:
   ```
   1. Merge back to <base-branch> locally
   2. Push and create a Pull Request
   3. Keep the branch as-is (I'll handle it later)
   4. Discard this work
   ```
4. Execute chosen option
5. Cleanup worktree (for options 1, 2, 4)

**Never:** Proceed with failing tests, merge without verification, delete without confirmation, force-push without request.

### 16.10 Brainstorming Before Implementation

**HARD GATE:** Do NOT invoke any implementation skill, write any code, scaffold any project, or take any implementation action until you have presented a design and the user has approved it.

For ANY creative work (features, components, functionality, behavior changes):

1. Explore project context (files, docs, recent commits)
2. Offer Visual Companion if visual questions ahead
3. Ask clarifying questions (one at a time)
4. Propose 2-3 approaches with trade-offs and recommendation
5. Present design in sections (scaled to complexity)
6. Write design doc to `docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md`
7. Spec self-review (check for placeholders, contradictions, ambiguity, scope)
8. User reviews written spec
9. **ONLY THEN:** Invoke writing-plans skill

**Anti-pattern:** "This is too simple to need a design". Every project goes through this process.

### 16.11 Writing Plans

Use superpowers:writing-plans to create implementation plans:

**Plan structure:**
1. Header with goal, architecture, tech stack
2. File structure (which files created/modified)
3. Bite-sized tasks (2-5 minutes each)
4. Each task: exact file paths, complete code, exact commands with expected output

**Requirements:**
- No placeholders (TBD, TODO, "implement later")
- Exact file paths always
- Complete code in every step
- DRY, YAGNI, TDD, frequent commits

**After plan:**
- Self-review for spec coverage, placeholder scan, type consistency
- User reviews plan
- Offer execution choice (subagent-driven or inline execution)

### 16.12 Execution Options

After plan creation, offer:

**Option 1: Subagent-Driven (recommended)**
- Fresh subagent per task
- Two-stage review (spec compliance → code quality)
- Continuous progress, review checkpoints automatic

**Option 2: Inline Execution**
- Same session execution
- Use superpowers:executing-plans
- Review plan critically first, stop when blocked

**Which approach?**

---

### 16.13 Lot-Specific Workflows

For PathPattern and Surface Engine lots, adapt superpowers workflows to lot methodology:

**Before starting a lot:**
1. Read the roadmap (`reports/pathPattern/path_pattern_roadmap.md`)
2. Check previous lot reports for decisions and constraints
3. Review non-goals confirmed in prior lots
4. Identify dependencies (which lots must be complete first)

**During lot execution:**
1. Follow the 10-point lot report template (Verdict → Audit → Files → Decisions → Non-goals → Tests → Analyze → Git Status → Limits → Next Lot)
2. Use Context Mode for large audits (as shown in lot reports)
3. Document all commands run with exact outputs
4. Never modify files outside lot scope without explicit user consent

**After completing a lot:**
1. Run targeted tests for the lot
2. Run regression tests for dependent lots
3. Run full package tests
4. Include complete Evidence Pack in report

### 16.14 Common Anti-Patterns (from skills)

**Debugging Anti-Patterns:**
- Quick fixes without root cause investigation
- Multiple changes at once
- Skipping test case creation
- Proceeding after 2+ failed fix attempts (question architecture!)
- Assuming you understand without tracing data flow

**TDD Anti-Patterns:**
- Code before test
- Test passes immediately (not watched fail)
- Tests written after implementation
- "I already manually tested"
- Keeping code as "reference" while writing tests

**Verification Anti-Patterns:**
- Claiming success without running verification
- Using "should", "probably", "seems to"
- Expressing satisfaction before verification
- Trusting agent success reports without checking
- Relying on partial verification

**Code Review Anti-Patterns:**
- Performative agreement ("You're absolutely right!")
- Blind implementation without verification
- Batch fixes without testing each
- Avoiding pushback when reviewer is wrong
- Partial implementation of unclear feedback

**Planning Anti-Patterns:**
- Placeholders (TBD, TODO, "implement later")
- Vague steps without exact commands
- Missing file paths
- Incomplete code examples

---

## 17. Project-Specific Superpowers Adaptations

### 17.1 TDD for Dart/Flutter

**RED phase:**
```bash
 # Run specific test
 dart test test/path/to/test.dart
 flutter test test/path/to/test.dart

 # Verify it fails with expected reason
```

**GREEN phase:**
- Write minimal Dart code to pass
- Use `package:test` conventions
- Match existing test patterns in the codebase

**REFACTOR phase:**
- Run full test suite after each refactor
- Use `dart analyze` to catch static issues
- Keep tests green

**Dart-specific tips:**
- Use `expect()` for assertions
- Test both success and error cases
- Use `setUp()` and `tearDown()` for test fixtures
- Mock external dependencies with `package:mockito`

### 17.2 Systematic Debugging for Dart

**Phase 1 adaptations:**
- Use `dart analyze --format json` for static analysis errors
- Use `dart test --reporter expanded` for detailed test output
- Check `pubspec.yaml` for dependency issues
- Use `flutter doctor -v` for environment problems

**Phase 2 (Pattern Analysis):**
- Search existing code with `grep` or `rg`
- Compare with working examples in `packages/map_core/test/`
- Check golden files in `fixtures/` directories

**Phase 3 (Hypothesis):**
- Create minimal reproduction in isolation
- Use `dart pad` for quick experimentation
- Test with `dart run` for scripts

**Phase 4 (Implementation):**
- Create failing test case first
- Run with `dart test --name-only` to verify test name
- Fix and verify

### 17.3 Verification Commands Matrix

| Claim | Package | Command | Success Criteria |
|-------|---------|---------|------------------|
| Tests pass | map_core | `dart test` | All tests pass, 0 failures |
| Tests pass | map_gameplay | `dart test` | All tests pass, 0 failures |
| Tests pass | map_battle | `dart test` | All tests pass, 0 failures |
| Tests pass | map_editor | `flutter test` | All tests pass, 0 failures |
| Tests pass | map_runtime | `flutter test` | All tests pass, 0 failures |
| Static analysis | map_core | `dart analyze` | 0 errors, 0 warnings |
| Static analysis | map_editor | `flutter analyze` | 0 errors, 0 warnings |
| Static analysis | map_runtime | `flutter analyze` | 0 errors, 0 warnings |
| Build runner | map_core | `dart run build_runner build --delete-conflicting-outputs` | Exit code 0 |
| Build runner | map_editor | `flutter pub run build_runner build --delete-conflicting-outputs` | Exit code 0 |

**Always include:** Command used, full output summary, exit code, timestamp.

### 17.4 Git Worktree Integration

**For lot development:**
```bash
 # Create worktree for lot-XX
 mkdir -p .worktrees
git worktree add .worktrees/lot-XX feature/lot-XX-pathpattern
cd .worktrees/lot-XX

 # After completion, cleanup
git worktree remove .worktrees/lot-XX
```

**Verify .worktrees is ignored:**
```bash
  git check-ignore -q .worktrees || echo ".worktrees not ignored - add to .gitignore"
```

### 17.5 Code Review Checklist (Dart-specific)

**Spec Compliance:**
- [ ] Follows lot scope (no out-of-scope changes)
- [ ] Respects non-goals confirmed in prior lots
- [ ] Compatible with existing models (map_core contracts)
- [ ] No breaking changes to public APIs without migration

**Code Quality:**
- [ ] Follows Dart style guide (dart analyze clean)
- [ ] Uses existing naming conventions
- [ ] Proper null safety
- [ ] Immutable where appropriate (final classes, final fields)
- [ ] No unused imports (dart analyze warning)
- [ ] No dead code

**Testing:**
- [ ] Tests added for new functionality
- [ ] Tests pass
- [ ] No regressions in existing tests
- [ ] Tests follow existing patterns

**Documentation:**
- [ ] Report follows lot template
- [ ] Evidence Pack complete
- [ ] Decisions documented
- [ ] Remaining limits identified

---

## 18. Quick Reference: When to Use Which Skill

| Scenario | Primary Skill | Secondary Skills |
|----------|---------------|------------------|
| Starting any task | using-superpowers | - |
| Brainstorming feature | brainstorming | writing-plans |
| Writing implementation plan | writing-plans | - |
| Bug or test failure | systematic-debugging | test-driven-development, verification-before-completion |
| Implementing feature/bugfix | test-driven-development | verification-before-completion, requesting-code-review |
| Completing task | verification-before-completion | requesting-code-review |
| Executing plan (same session) | subagent-driven-development | systematic-debugging, test-driven-development |
| Executing plan (parallel) | executing-plans | finishing-a-development-branch |
| Multiple independent failures | dispatching-parallel-agents | systematic-debugging |
| Requesting review | requesting-code-review | - |
| Receiving review feedback | receiving-code-review | - |
| Finishing branch | finishing-a-development-branch | using-git-worktrees |
| Starting feature work | using-git-worktrees | brainstorming, writing-plans |

---

## 19. Rationalization Prevention

**If you catch yourself thinking these, STOP and invoke relevant skills:**

| Thought | Skill to Invoke | Why |
|---------|----------------|-----|
| "This is just a simple question" | using-superpowers | Check for skills first |
| "I need more context first" | brainstorming | Skills tell you HOW to gather context |
| "Let me explore the codebase first" | using-superpowers | Skills guide exploration |
| "I can check git/files quickly" | using-superpowers | Skills tell you HOW to check |
| "This does not need a formal skill" | using-superpowers | If skill exists, use it |
| "Just try changing X and see if it works" | systematic-debugging | NO FIXES WITHOUT ROOT CAUSE |
| "I'll write tests after" | test-driven-development | NO CODE WITHOUT FAILING TEST |
| "Should work now" | verification-before-completion | RUN THE VERIFICATION |
| "Tests pass, phase complete" | verification-before-completion | Need full verification |
| "I'm confident" | verification-before-completion | Confidence ≠ evidence |
| "Let me implement that now" | receiving-code-review | Verify first, implement second |
| "You're absolutely right!" | receiving-code-review | No performative agreement |

---

**Remember:** The purpose of skills is to prevent the rationalizations that lead to wasted work, bugs, and rework. When in doubt, invoke the skill.

---

## 20. Summary: Integration Complete

This AGENTS.md now integrates the **Superpowers skill system** with the **PokeMap project context**. The integration provides:

### What Was Added:

1. **Section 16 - Superpowers Workflow Integration**
   - Core principles and discipline
   - When to invoke skills
   - Process skills priority
   - Implementation workflows (Subagent-Driven, Executing Plans, Parallel Agents)
   - Debugging discipline (4 phases)
   - Test-Driven Development (RED-GREEN-REFACTOR)
   - Verification Before Completion (Gate Function)
   - Code Review Process (Requesting + Receiving)
   - Git Worktrees for isolation
   - Finishing Development Branch
   - Brainstorming Before Implementation
   - Writing Plans

2. **Section 17 - Project-Specific Adaptations**
   - TDD for Dart/Flutter
   - Systematic Debugging for Dart
   - Verification Commands Matrix
   - Git Worktree Integration
   - Code Review Checklist (Dart-specific)

3. **Section 18 - Quick Reference**
   - When to use which skill (scenario mapping)

4. **Section 19 - Rationalization Prevention**
   - Thought patterns that trigger skill invocation
   - Mapping thoughts to specific skills

### How to Use:

1. **Start every task** by checking if any skill applies (Section 16.1)
2. **Follow the workflows** for your specific scenario (Sections 16.3-16.12)
3. **For PathPattern lots**, use the adaptations in Section 17
4. **When stuck**, consult the Rationalization Prevention table (Section 19)
5. **Verify always** before claiming completion (Section 16.6)

### Key Principles to Remember:

- **Skills override defaults** but user instructions (this file) take precedence
- **1% chance rule:** If there's even a 1% chance a skill applies, invoke it
- **No rationalizations:** When you catch yourself making excuses, STOP and use the skill
- **Evidence before claims:** Always run verification commands before stating success
- **TDD always:** No production code without a failing test first
- **Root cause first:** No fixes without investigating root cause
- **No performative agreement:** Actions > words in code review

### Files Modified:
- `AGENTS.md` (this file): Added Sections 16-20

### Verification:
```bash
# This file passes static analysis
dart analyze AGENTS.md
# Result: No issues found!
```

---

*Last updated: Integration of Superpowers skills from `/skills/` directory*
*Skills integrated: using-superpowers, systematic-debugging, test-driven-development, verification-before-completion, brainstorming, writing-plans, subagent-driven-development, executing-plans, dispatching-parallel-agents, requesting-code-review, receiving-code-review, finishing-a-development-branch, using-git-worktrees, writing-skills*
