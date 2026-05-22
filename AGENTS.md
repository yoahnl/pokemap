# Repository Guidelines

## 1. Purpose and Priority

PokeMap is a Dart/Flutter monorepo for a Pokemon-like no-code fangame editor/runtime/battle stack. The goal is playable RPG creation: maps, NPCs, dialogues, encounters, battles, progression, items, events, saves, and runtime playability.

Keep work practical: small scoped changes, package boundaries, explicit roadmap lots, tests, and evidence.

Instruction priority:

1. Direct user request.
2. Nearest `AGENTS.md` in the edited directory tree.
3. This root `AGENTS.md`.
4. User-referenced specs, roadmaps, reports, or lot files.
5. Local skills in `skills/`: skim `skills/README.md`, then read the selected `skills/<skill-name>/SKILL.md`.
6. MCP/docs/tooling guidance.
7. Default agent behavior.

If instructions conflict, follow the stricter safe rule and report the conflict.

---

## 2. Repository Shape

No workspace orchestrator is present: `melos.yaml` is absent. Run commands package by package.

| Path | Role | Boundary |
|---|---|---|
| `packages/map_core` | Models, serialization, validation, pure operations | Pure Dart. No Flutter/Flame. |
| `packages/map_gameplay` | Pure overworld/gameplay logic | Pure Dart. Depends on `map_core`. |
| `packages/map_battle` | Battle engine | Pure Dart. Independent from Flutter. |
| `packages/map_runtime` | Flutter + Flame runtime | Rendering, battle handoff, save/load, overlays. |
| `packages/map_editor` | Flutter desktop authoring app | No-code authoring. Do not couple to runtime internals. |
| `examples/playable_runtime_host` | Runtime host and smoke fixtures | Runtime/gameplay/core integration. |

Preserve public barrels when adding exported API:

```text
packages/map_core/lib/map_core.dart
packages/map_gameplay/lib/map_gameplay.dart
packages/map_battle/lib/map_battle.dart
packages/map_runtime/lib/map_runtime.dart
```

---

## 3. Gameplay Mechanics Roadmap

For any fangame-mechanics task, read first:

```text
pokemap_roadmap_mecaniques_fangame.md
```

Expected location: repository root. If missing, search once; if still missing, say so and do not invent roadmap status.

Mechanics work includes:

```text
new game, starter flow, party, PC/boxes, bag/items, shops,
healing, save/load gameplay, encounters, capture, trainer battles,
XP, level-up, move learning, evolution, rewards, badges, money,
field moves, hazards, story/event commands, runtime menus,
project playability validation, golden-slice runtime flow.
```

Before mechanics work: identify the relevant `FG-*` lot/gap, state it in the plan/report, and respect its done criteria.

After mechanics work: report whether each relevant lot remains `TODO`, `PARTIAL`, `BLOCKED`, or can be proposed as `DONE`. Never mark `DONE` without fresh proof: files changed, commands run, exact results, final git status, and known limits.

Update the roadmap only when the task explicitly asks. Otherwise, propose the status update in the final report. Prefer gameplay reports under:

```text
reports/gameplay/fg_<id>_<slug>.md
```

When the user asks about fangame readiness, mechanics beat visual polish unless the current mechanic directly depends on visuals.

---

## 4. Local Skills

Use root-level `skills/` as a workflow library when it materially applies.

Recommended index:

```text
skills/README.md
```

Skill usage:

1. Skim `skills/README.md` to choose the skill.
2. Read the selected `skills/<skill-name>/SKILL.md` before applying it.
3. Do not rely on memory; skills can change.
4. Use the smallest relevant set of skills; no ceremonial skill usage.
5. If a skill assumes unavailable tooling, adapt conservatively and report the limitation.
6. Skills never override user instructions, nearer `AGENTS.md`, Git safety, package boundaries, or the mechanics roadmap.

Common triggers:

| Situation | Skill to check |
|---|---|
| Unsure which skill applies | `using-superpowers` |
| Feature/design exploration | `brainstorming` |
| Multi-step implementation plan | `writing-plans` |
| Execute existing plan | `executing-plans` or `subagent-driven-development` |
| Parallel independent investigation | `dispatching-parallel-agents` |
| Bug/test/analyzer/parser/serializer failure | `systematic-debugging` |
| New behavior or bug fix with feasible focused test | `test-driven-development` |
| Before claiming completion | `verification-before-completion` |
| Substantial change or risky next lot | `requesting-code-review` |
| Review feedback | `receiving-code-review` |
| Branch/worktree flow explicitly requested | `using-git-worktrees` or `finishing-a-development-branch` |
| Creating or editing skills | `writing-skills` |

For mechanics work, use both the relevant skill and `pokemap_roadmap_mecaniques_fangame.md`.

---

## 5. Product and Architecture Rules

No-code first:

- guided pickers over manual IDs;
- previews over raw data;
- clear labels over engine jargon;
- validations before runtime surprises;
- no forced JSON editing for normal users.

Mechanics-first when requested:

```text
exploration -> event/dialogue -> encounter/battle -> reward/progression -> party/bag/PC -> save/story
```

Do not pivot from mechanics to shadows, surfaces, tileset polish, or rendering unless required by the lot.

PokeMap owns its data. Do not make Tiled, RMXP, Pokemon SDK, or other external editors/formats runtime requirements. They can inspire layouts/imports, but PokeMap must author and run its own project data.

Package boundaries:

- shared contracts and JSON models: `map_core`;
- pure overworld decisions: `map_gameplay`;
- battle mechanics: `map_battle`;
- runtime integration: `map_runtime`;
- authoring UI and editor use cases: `map_editor`;
- gameplay rules must not hide inside Flame components;
- schema changes usually require tests, fixtures, editor/runtime updates, and migration awareness.

---

## 6. Working Style

Be surgical.

- Change only what the task requires.
- Do not refactor nearby code because it is nearby.
- Match existing naming, style, and test patterns.
- Prefer small lots and characterization tests before model/schema changes.
- Preserve legacy behavior unless the task explicitly changes it.
- If scope is ambiguous, state the assumption and choose the smallest safe interpretation.
- If you find unrelated issues, report them instead of fixing silently.

Implementation flow: inspect the smallest relevant area, define success criteria, add/adjust focused tests when feasible, implement minimally, run targeted verification, then broader checks if risk justifies it.

UI/editor work should stay readable, no-code, validated, and feedback-rich. Do not expose engine internals as the normal workflow.

---

## 7. Git Safety

Never run Git write operations unless the user explicitly asks.

Forbidden without explicit instruction:

```text
git add, git commit, git commit --amend, git merge, git rebase,
git push, git tag, git stash, git reset, git restore,
git checkout/switch when it changes files or branches,
git branch creation/deletion/rename,
git worktree add/remove,
destructive cleanup that modifies tracked work.
```

Allowed read-only commands:

```bash
git status --short --untracked-files=all
git diff
git diff --name-only
git log
git show
git branch
git worktree list
```

Before editing, check the working tree when available. After editing, report final working tree. Never hide unrelated pre-existing changes.

---

## 8. Validation

Run commands from the relevant package directory.

Pure Dart:

```bash
cd packages/map_core && dart test && dart analyze
cd packages/map_gameplay && dart test && dart analyze
cd packages/map_battle && dart test && dart analyze
```

Flutter:

```bash
cd packages/map_runtime && flutter test && flutter analyze
cd packages/map_editor && flutter test && flutter analyze
cd examples/playable_runtime_host && flutter test && flutter analyze
```

Runtime smoke checks for player loop or battle/runtime work:

```bash
cd packages/map_runtime && flutter test test/phase_a_golden_battle_slice_smoke_test.dart
cd examples/playable_runtime_host && flutter test test/phase_a_golden_slice_launch_test.dart
```

When tests cannot be run, explain why and list the next command to run. Do not claim green status without fresh command evidence.

---

## 9. Code Generation

Regenerate code only in the package you changed:

```bash
cd packages/map_core && dart run build_runner build --delete-conflicting-outputs
cd packages/map_editor && flutter pub run build_runner build --delete-conflicting-outputs
cd packages/map_runtime && flutter pub run build_runner build --delete-conflicting-outputs
```

Avoid unrelated generated-file churn. Do not run global generators unless explicitly requested.

---

## 10. Reports and Evidence

Normal code-task final reports should include: summary, files changed, commands run, exact results or skipped-check reason, known limitations, and final git status.

Roadmap lots, implementation reports, reviews, or audits should also include: relevant lot IDs, file inventory, decisions/non-goals, exact final test/analyze/build lines, risks, and recommended next lot/status update.

Do not invent measurements, memory guarantees, coverage percentages, or test totals. For large outputs, summarize the useful signal and preserve the exact command.

Reports under `reports/` are tracked engineering artifacts. Modify them only when the task asks for a report, audit, review, lot closure, or roadmap/status evidence.

---

## 11. Flame / Runtime Documentation

For Flame APIs, runtime rendering, game loop, components, overlays, input, camera, asset loading, collision, or lifecycle, consult configured Flame docs first when available.

Expected MCP server:

```text
flame_docs
```

If unavailable: say so, inspect installed Flame version in `pubspec.yaml` / lockfile, search existing runtime code for working patterns, and avoid inventing Flame APIs.

PokeMap architecture wins over generic Flame examples: pure Dart packages stay Flutter/Flame-free, and gameplay rules stay out of runtime components.

---

## 12. High-Signal Directories and Hygiene

Use these before broad searches:

```text
packages/
examples/playable_runtime_host/
examples/playable_runtime_host/golden_battle_slice/
packages/map_editor/test/fixtures/
reports/
docs/combat/
skills/
```

Do not add cache, local, or generated artifacts unless required:

```text
.dart_tool/
build/
temporary scripts
local IDE files
machine-specific paths
lockfiles unrelated to dependency work
```

Do not clean or rewrite historically tracked generated/cache-like artifacts unless the task explicitly asks for hygiene cleanup.

---

## 13. Maintenance

This is a Markdown instruction file. Do not claim it passes Dart static analysis.

Recommended checks after editing it:

```bash
wc -l AGENTS.md
git diff -- AGENTS.md
```

Manual checks:

- mechanics roadmap referenced;
- `skills/README.md` and `skills/<skill-name>/SKILL.md` usage documented;
- Git write operations still forbidden without explicit instruction;
- package boundaries clear;
- validation commands package-scoped;
- Flame docs rule preserved;
- file concise enough for agents to read.
