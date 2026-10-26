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
documentation/reports/gameplay/fg_<id>_<slug>.md
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
| PokeMap project authoring, MCP usage, or authoring parity | `using-pokemap-mcp` |

For mechanics work, use both the relevant skill and `pokemap_roadmap_mecaniques_fangame.md`.

### PokeMap MCP parity

Any change that adds or alters user-visible authoring behavior, project data, an editor
command, validation, import/export, rendering, or playtest behavior must assess PokeMap MCP
parity before completion. Read `skills/using-pokemap-mcp/SKILL.md` and:

- expose applicable semantics through the canonical `map_authoring` API, not editor internals;
- register discoverable MCP resource and action contracts where applicable;
- prove direct API, JSONL/CLI, editor, and MCP transports with focused tests or justify N/A;
- rebuild and test `tools/pokemap_mcp`, then verify the live `pokemap_describe` catalog;
- treat generic JSON persistence or whole-map save as insufficient proof of semantic support;
- report missing exposure as `PARTIAL` or `BLOCKED`, never silently bypass it with file edits.

For `workspace.path_outside_allowed_roots`, preserve the security boundary: use an absolute
project path under a configured narrow root or request explicit authorization to add one.
Do not broaden access to the home directory or filesystem root as a convenience fix.

---

## 5. Product and Architecture Rules

### Mandatory local and incremental authoring

**This is a blocking architecture and acceptance requirement for Avelune Studio,
the Map Editor and their shared authoring APIs. It is not optional polish.**
Yoahn reaffirmed this requirement on **2026-10-25** because disproportionate
work behind simple interactions was a reason for abandoning the former PokeMap.
Only a direct, explicit user instruction may authorize a bounded exception;
convenience, existing code, deadlines or another workflow do not authorize one.

- A local interaction (toggle, field edit, selection, placement, movement,
  rotation, deletion, brush stroke or undo/redo) must update the affected draft
  and preview incrementally. Its work must be bounded by the changed data and
  their actual dependencies, not unrelated project size or accumulated history.
- Never make a local edit, its first save, autosave or undo/redo trigger a full
  project snapshot/load, traversal of every map or resource, rehash/decode of
  unrelated assets, complete journal replay, global validation, renderer
  reconstruction, export or rebuild. Do not hide that work in a helper or
  require it as a prerequisite to completing the local operation.
- Persist through the canonical authoring boundary using targeted writes to the
  affected storage units. A shared document may require atomic replacement of
  that document; this does not justify loading or rewriting unrelated files.
  Preserve concurrent-write checks, crash safety, undo semantics and protected
  data compatibility. Never bypass these guarantees with an editor-only writer.
  If the current storage or transaction path cannot meet this requirement,
  report the architectural defect and correct the narrow owning boundary.
- Keep integrity and validation proportional to the mutation and its affected
  dependencies. Project-wide validation, export, migration and reconstruction
  belong to explicit operations with visible progress. Necessary initial
  project loading must be measured separately and must not recur per edit or
  be deferred onto the first save. Recovery must be explicit when required;
  routine edits must not silently replay the entire project history.
- An isolate, background queue, debounce, spinner or warm cache does not make
  disproportionate work acceptable. Caches may reduce necessary work, but a
  fast repeated operation does not excuse an expensive first operation.
  Do not acknowledge a durable save before persistence has actually succeeded.
- Before implementing a local authoring change, identify its affected storage
  units, dependency scope and latency budget. Default acceptance targets for a
  simple property edit on a documented representative local project are visible
  feedback within **100 ms** and durable persistence within **500 ms**, for
  both the first operation after opening and repeated operations. These are
  acceptance targets, not claims of existing performance. Any different budget
  requires explicit user agreement; never silently relax it to fit the result.
- Prove the real UI-to-persistence path with focused tests counting relevant
  reads, writes, decodes and invalidations, including added unrelated project
  content/history. Measure first and repeated latency separately, document the
  machine/build mode and verify persisted values after reopening. Use stable
  work-count assertions for regression tests and local timing measurements;
  do not add expensive CI soaks. Preserve API/CLI/MCP semantics and assess parity.
- A working button with excessive or unproven cost is **PARTIAL**, not ready
  for acceptance. Do not claim compliance from a small fixture, a warm-only
  benchmark, debug-only timing or source inspection. Apply this gate to new
  work and touched paths; never imply the whole existing editor is certified.

### Avelune game and save compatibility policy

Yoahn established the compatibility baseline on **2026-10-24**, at Avelune
Studio **0.3.31+331** (`apps/avelune_studio/pubspec.yaml`). This is a product
obligation; this rule alone does not certify implementation.

- Every valid native project and game package exported by Studio at this
  baseline or later must remain readable and playable by all subsequent
  Avelune Player/runtime releases on the platforms supporting that game's
  execution profile. The guarantee is cumulative: later exports acquire the
  same protection. Do not impose a rolling expiry or require a game update or
  re-export merely because the Player application was updated.
- Backward compatibility is mandatory even before `1.0.0`. A Player update
  must preserve protected games and the valid saves created for them, including
  player progression and persisted identities. A newer game may require a newer
  Player when its format or required capabilities are genuinely unknown to an
  older Player; future-format support is not promised.
- Keep application/build versions, game content versions, project/package/save
  formats and required runtime capabilities distinct. Never use release age,
  an exact application version match or a bare numeric format comparison as
  proof of incompatibility. Preserve previously supported capability semantics.
- Any format or persisted-behavior change affecting protected games or saves
  must retain a tested reader or provide an explicit, deterministic conversion
  into the current canonical model. This includes nested schemas and changed
  defaults within an unchanged top-level format. Keep compatibility handling at
  data boundaries rather than scattering legacy branches through gameplay.
- Never silently drop required fields, commands, resources or progression to
  make a game load. Optional presentation degradation is allowed only when the
  contract explicitly defines it and gameplay/save semantics remain intact.
- Validate packages before conversion, preserve original package integrity
  evidence and perform conversions on copies. Save migrations must preserve a
  recoverable original, validate the result and activate it transactionally.
  A failed load, conversion or update must not overwrite, delete or reset a
  game or save, or silently start a new game in place of the existing playthrough.
- For invalid, corrupted, unsafe or genuinely unsupported data, display a clear,
  actionable error identifying the cause and preserve recoverable originals.
  An error message does not satisfy the compatibility obligation for an otherwise
  valid protected game; such a failure is a regression to fix.
- Before shipping a relevant change, verify representative baseline and later
  exports plus existing saves through install/load/Continue, and verify that
  failures and unknown future formats leave original bytes intact. Record the
  exact fixtures, producer versions, commands, results and limits; do not claim
  all historical games are certified from a current-format fixture alone.
- Projects predating this baseline and obsolete internal APIs have no blanket
  compatibility guarantee. Preserve or convert them when explicitly requested
  or already covered by a protected contract; otherwise reject safely. Clean
  internal architecture remains the target, with protected data converted at
  the boundary when needed.

No-code first:

- guided pickers over manual IDs;
- previews over raw data;
- clear labels over engine jargon;
- validations before runtime surprises;
- no forced JSON editing for normal users.

Design system first for `map_editor` UI:

- use only widgets from the PokeMap design system for editor UI primitives such as surfaces, panels, cards, buttons, icon buttons, badges, sidebars, toolbar controls, empty states, and repeated layout blocks;
- if the design system does not provide the needed primitive or variant, create a design-system widget or extend an existing one with focused flexibility before using local/ad hoc UI;
- never hardcode UI colors in feature screens or widgets: no direct `Color(0x...)`, `Colors.*`, or package palette constants for product UI;
- all UI colors must come from design-system/theme tokens such as `PokeMapColorTokens`, `context.pokeMapColors`, or semantic design-system helpers;
- new color values belong only in theme/design-system token definitions, with semantic names and existing light/dark behavior preserved.

Mechanics-first when requested:

```text
exploration -> event/dialogue -> encounter/battle -> reward/progression -> party/bag/PC -> save/story
```

Do not pivot from mechanics to shadows, surfaces, tileset polish, or rendering unless required by the lot.

PokeMap owns its data. Do not make Tiled, RMXP, Pokemon SDK, or other external editors/formats runtime requirements. They can inspire layouts/imports, but PokeMap must author and run its own project data.

Native map construction is mandatory for reconstructions as well as new maps:

- Paint repeatable ground through the native terrain system, and water and roads through connected native paths.
- Author shores, cliffs and relief edges with native Borders, including their contour and corner rules.
- Place complete reusable trees through the Environment/tree system, including their base when it belongs to the tree.
- Keep other objects complete and reusable. Border profile modules remain owned by their native contour; do not assemble terrain or objects from independently placed visual fragments.
- Verify visual fidelity and native editability separately. A matching screenshot alone does not prove that a map uses these systems.

Package boundaries:

- shared contracts and JSON models: `map_core`;
- pure overworld decisions: `map_gameplay`;
- battle mechanics: `map_battle`;
- runtime integration: `map_runtime`;
- authoring UI and editor use cases: `map_editor`;
- gameplay rules must not hide inside Flame components;
- schema changes usually require tests, fixtures, editor/runtime updates and an
  explicit schema-version change where applicable; changes affecting games or
  saves protected by the compatibility baseline require a tested compatibility
  path even before `1.0.0`.

---

## 6. Working Style

Be surgical.

- Change only what the task requires.
- Do not refactor nearby code because it is nearby.
- Match existing naming, style, and test patterns.
- Prefer small lots and characterization tests before model/schema changes.
- If scope is ambiguous, state the assumption and choose the smallest safe interpretation.
- If you find unrelated issues, report them instead of fixing silently.

Implementation flow: inspect the smallest relevant area, define success criteria, add/adjust focused tests when feasible, implement minimally, run targeted verification, then broader checks if risk justifies it.

UI/editor work should stay readable, no-code, validated, and feedback-rich. Do not expose engine internals as the normal workflow.

### Mandatory Notion Traceability

Every PokeMap task carried out through Codex must be recorded in the canonical
Notion product cockpit. This applies to implementation, refactoring, audits,
tests, documentation, product decisions, bug fixes, CI work, and tooling work.

- Before considering a task complete, attach it to exactly one existing grand
  domain and create or update the corresponding Notion ticket in that domain.
- No completed Codex work may exist only in chat, Git, a pull request, or a
  repository report. Notion must contain at least the scope, current status,
  affected files or packages, commands and evidence, result, relevant SHA or
  branch/PR, and known limitations.
- Keep the ticket status synchronized with reality using the cockpit workflow:
  `TODO`, `DOING`, `TO REVIEW`, or `DONE`. Never mark work `DONE` without fresh
  evidence satisfying the ticket criteria.
- Never create a new grand domain silently. If no existing grand domain fits,
  stop and request the user's explicit approval. Create the new domain and its
  first ticket only after that approval.
- If Notion is unavailable, report the tracking blocker explicitly and do not
  treat the task as fully closed until its work has been recorded.
- Notion is the mandatory product-tracking projection. The repository,
  roadmaps, tests, reports, and receipts remain the canonical technical
  evidence.

Ticket lifecycle:

- when an agent finishes implementing and verifying a ticket, move it to `TO REVIEW`, never directly to `DONE`;
- `DONE` is reserved for the user's explicit decision after review, even when every automated criterion is green;
- keep the implementation evidence, readiness, verdict, remaining criteria, commit, and branch fields accurate when moving the ticket to `TO REVIEW`.

### Ticket creation exclusions

Do not create new Notion tickets for:

- creating, decorating, populating, importing, or repairing a specific map, level, interior, route, village, station, port, forest, house, lighthouse, or other level content;
- repairing a bug, regression, failed test, broken workflow, or isolated technical defect.

Map content belongs in the project data and its technical or review evidence, not in the PokeMap product backlog. Bug repairs belong in the existing feature, release, review, or incident context when one exists; do not create a standalone ticket merely to track the repair. If no existing context can hold the work and a new ticket appears necessary, stop and request Yoahn's explicit decision before creating it. Generic authoring capabilities and reusable bug-prevention mechanisms remain ticketable when they are product scope rather than one-off content or repair work.

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

When the user explicitly authorizes both commits and rebases for ticket-by-
ticket delivery, finish every completed ticket with targeted verification, one
scoped commit, then a rebase of the ticket branch onto the designated base
branch. Re-run the relevant verification after the rebase, and never combine
unfinished tickets in that commit. Ticket-by-ticket delivery alone is not Git
write authorization.

---

## 8. Validation

### CI cost discipline

- Keep ordinary CI short and inexpensive.
- Do not add performance soaks, long-running integration journeys, or dedicated
  macOS runners to CI unless the user explicitly requests that exact CI cost.
- Expensive certification journeys run locally by default and remain opt-in;
  their harnesses and receipt validators may be versioned without scheduling
  the journey in GitHub Actions.
- A release workflow must not gain a costly certification dependency merely
  because a local benchmark exists.

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

### Always reap test harnesses (mandatory)

`flutter test` leaks a `flutter_tester` process per suite that outlives the run,
and every abandoned or killed run leaves its compiler and listener behind. They
sit at 0% CPU, so nothing complains — they just take memory. A single day of
work accumulated **501 orphaned `flutter_tester` processes holding 7.6 GB**,
which is what makes later suites crawl and time out, which causes more runs to
be abandoned, which leaks more processes.

After each test run, inspect and reap only leftover harnesses owned by that run.
Record the test runner PID and its descendant PIDs while the run is active.
Before terminating a leftover PID, verify its command and ownership again so a
reused PID or a concurrent session cannot be stopped accidentally. Prefer a
normal termination before escalating to SIGKILL for a confirmed stuck child.

Never use blanket process-name kills for `flutter_tester`,
`frontend_server_aot`, or `flutter_tools.snapshot test`. The same compiler also
belongs to live IDE and `flutter run` sessions: killing it causes
`The Dart compiler exited unexpectedly` and disconnects the application.
A quiet process, an old process, or a familiar executable name is not proof
that it is abandoned. If ownership cannot be proved, leave it running.

Same discipline for MCP servers, which are spawned per session and never
reaped. Kill any older than two hours — no live session is a day old:

```bash
ps -eo pid=,etime=,args= | grep -E '[d]art mcp-server|[n]ode.*pokemap_mcp/dist' | awk '$2 ~ /-|^[0-9]{2,}:/ {print $1}' | xargs -r kill -9
```

Do NOT blanket-kill recent MCP servers: concurrent agent sessions own those, and
killing one breaks another agent's tooling mid-task. Age is the discriminator.

If a suite hangs, suspect a leaked harness before suspecting the test. And check
`Platform.resolvedExecutable`: inside a `flutter test` it resolves to
`flutter_tester`, which accepts a `.js` or script path and then hangs forever
instead of failing — spawn `node` (or the real interpreter) by name.

### Always remove temporary QA artifacts (mandatory)

Every task owns the complete lifecycle of its temporary test artifacts,
wherever it creates them: inside this repository, in sibling project folders,
under `~/Project`, on the Desktop, in application containers, caches or temporary
directories. Moving artifacts outside the repository does not discharge this
obligation. Cleanup is part of completing the task, including failed runs and
resumed interrupted work; it must not depend on Yoahn requesting another purge.

- All disposable Avelune/PokeMap QA artifacts must live under the single
  canonical root `/Users/karim/Library/Caches/AveluneQA/`, with at most one
  reusable child directory per active task. This is mandatory: do not invent
  another test root, dated sibling project or standalone application folder
  under `~/Project`, on the Desktop or elsewhere. FPS, GPU, camera,
  visual-settings and release checks follow the same rule.
- Before creating a QA environment, record its purpose, exact owned paths,
  processes and concrete removal condition in the task state or an existing
  concise receipt. Reuse the canonical task directory across retries and
  resumed turns; do not create a new copy for each run. If a platform or tool
  strictly requires a different build, sandbox or temporary path, record that
  narrow exception and remove its disposable outputs in the same task. Tool
  convenience is not a reason to scatter project or application copies.
- Reuse the environment when possible. Copy only the sources, assets and
  fixtures needed for the check; exclude unrelated builds, `.dart_tool`,
  `node_modules`, caches and project histories. Do not duplicate a complete
  workspace merely to run a focused test.
- After each run, remove superseded outputs and failed attempts immediately;
  cleanup is continuous, not a deferred bulk purge. Do not retain old app
  bundles merely because they have a different name or build date. Before closing
  the task, stop its owned QA apps, servers and harnesses using the ownership
  checks above, then remove disposable project copies, source snapshots, app
  bundles, builds, dependency caches, exports, recordings and repeated captures
  created for that task. Check for open files and active consumers first;
  never interrupt another session or delete its working environment.
- Preserve original projects, source repositories, assets, saves, user-requested
  deliverables, maintained tests and fixtures, and useful unique changes. A
  folder name containing `test` or `QA` is not proof that its contents are
  disposable; a package library or real project is never implicitly a cache.
  Verify the original still exists and retain any useful unique data before
  removing a copy. Do not bypass Git safety or compatibility guarantees.
- Retain only the evidence needed to support the result: concise receipts,
  relevant logs or diffs and selected final captures. Prefer the existing
  canonical evidence location; a small verified archive is acceptable when
  needed. Do not keep gigabytes of environments or frame dumps as evidence,
  replace deleted clutter with another complete backup, or create extra
  Markdown files merely to track cleanup.
- Routine removal of verified disposable artifacts owned by the task is
  authorized as part of the task; do not ask for repeated confirmation. If
  ownership, a unique datum or an active consumer prevents safe cleanup, report
  the exact path, measured size, reason and required decision instead of
  silently retaining it or broadening the deletion scope.
- Verify the removed paths are gone and retained evidence is readable. Report
  the cleanup result and every retained temporary environment with its size,
  owner and concrete removal condition. Measure directory size and SSD free
  space separately; shared APFS storage and concurrent writes can make their
  changes differ. A task with unexplained temporary leftovers is not complete.

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

Reports under `documentation/reports/` are tracked engineering artifacts. Modify them only when the task asks for a report, audit, review, lot closure, or roadmap/status evidence.

### Markdown hygiene (mandatory)

The default documentation budget for a task is **zero new Markdown files**. A
"final report" means the final chat response unless the user explicitly asks
for a persistent report, audit, review, Evidence Pack, roadmap, or plan.

When a persistent Markdown artifact is explicitly required:

- update an existing canonical document when that is sufficient;
- otherwise create one consolidated file, not one file per agent, pass, test,
  phase, or command;
- place durable product/architecture documentation under `documentation/<domain>/`,
  audit and execution evidence under `documentation/reports/<domain>/`, persistent
  implementation plans under `documentation/reports/<domain>/plans/`, cross-domain
  roadmaps under `documentation/reports/roadmap/<domain>/`, and reusable workflows
  under `skills/<skill-name>/`;
- never create plans under `docs/superpowers/` unless the user explicitly asks
  for that exact persistent plan; use the in-session plan mechanism by default;
- never create `*_created_files_full_content.md` or similar source snapshots:
  Git diffs and the source files are the canonical evidence;
- do not create Markdown at the repository root. The root allowlist is
  `AGENTS.md`, `agent_rules.md`, `codex_rule.md`, and
  `pokemap_roadmap_mecaniques_fangame.md`; the existing
  `pokemap_authoring_api_mcp_action_catalog.md` is also retained at root because
  `map_core` consumes that exact repository path;
- run `bash tools/scripts/check_markdown_hygiene.sh` before completion. A
  `POKEMAP_MARKDOWN_MAX_NEW` override is allowed only when the user's request
  explicitly approves a bounded multi-document deliverable.

Quand un prompt demande un rapport, un Evidence Pack, une review, un audit ou une clôture de lot, l'agent doit lire le fichier de règles Codex du repo avant d'écrire le rapport.
Fichier attendu : `codex_rule.md`.
Le rapport doit respecter ces règles, notamment :
- inclure l'audit initial et le verdict des sub-agents/passes ;
- lister tous les fichiers modifiés et les zones pertinentes des fichiers créés ;
- inclure les diffs/zones précises modifiées ;
- documenter les commandes lancées, les résultats exacts de tests et d'analyses ;
- fournir l'état git initial et final ;
- effectuer une auto-critique finale et identifier les risques.


---

## 11. Flame / Runtime Documentation

For Flame APIs, runtime rendering, game loop, components, overlays, input, camera, asset loading, collision, or lifecycle, consult configured Flame docs first when available.

Expected MCP server:

```text
flame_docs
```

If unavailable: say so, inspect installed Flame version in `pubspec.yaml` / lockfile, search existing runtime code for working patterns, and avoid inventing Flame APIs.

PokeMap architecture wins over generic Flame examples: pure Dart packages stay Flutter/Flame-free, and gameplay rules stay out of runtime components.

### PSDK parity sources (on this machine, outside the repository)

Two checkouts are the parity oracle. They are NOT in this repository and never
get committed into it:

```text
/Users/karim/Project/pokemonProject autre dossiers/pokemonsdk-development/
/Users/karim/Project/pokemonProject autre dossiers/pokémon_sdk_test_project/
```

`pokemonsdk-development` is the PSDK engine itself — ~1500 Ruby files. The
directories that answer most questions:

| Path | Answers |
| --- | --- |
| `scripts/5 Battle/01 Scene` | battle scene flow, phase order, transitions |
| `scripts/5 Battle/20 MoveAnimation` | move animation choreography and timing |
| `scripts/5 Battle/04 Logic` | turn resolution and damage application order |
| `scripts/4 Systems` | audio, transitions, shared systems |

`pokémon_sdk_test_project` is a runnable RMXP/PSDK project: `audio/`,
`graphics/`, `Data/` hold the real asset layout and naming, which is what
settles questions a script alone cannot (which file plays when, how a cell zoom
is authored).

Rules:

- For any parity question — animation order, timing, zoom and scale conversions,
  audio triggers, transitions — the **Ruby source is authoritative**. Write the
  reference from it, never from the Dart code, and never from a web article.
  A web search is fine for general game-feel principles; it does not settle
  what PSDK does.
- Quote the Ruby file and line in the ticket or the commit, so the next reader
  can check the claim instead of trusting it.
- Never copy Ruby verbatim into Dart. Never copy code from the Showdown
  client either: it is AGPLv3, and reading it as a choreography reference is
  the only permitted use.
- Assets from the runnable test project MAY be embedded in the engine's
  runtime assets, following the existing precedent: the 181 RMXP animation
  sheets and the battle sound effects under
  `packages/map_runtime/assets/` were imported from it by the tools in
  `packages/map_runtime/tool/`. Yoahn designated these directories as the
  battle asset source on 2026-08-23. Always import through a rerunnable tool
  that records its source, never by hand-copying files.

---

## 12. High-Signal Directories and Hygiene

Use these before broad searches:

```text
packages/
examples/playable_runtime_host/
examples/playable_runtime_host/golden_battle_slice/
packages/map_editor/test/fixtures/
documentation/reports/
documentation/
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

---

## 14. Frozen Beta Backlog

The Notion area `PokeMap — Bêta fonctionnelle` and its grand families 0–11 are a frozen release scope. This rule is the strict default for Codex and overrides the generic expectation to create a ticket when the work is new.

- Never create a new ticket in any beta family.
- Never move or reclassify a post-beta ticket into beta, set `Gate bêta` to true, or create a new beta grand family unless Yoahn explicitly requests that exact scope change.
- Never broaden an existing beta ticket with newly discovered cleanup, hardening, performance work, platform parity, transport parity, polish, compatibility, or future mechanics. Keep the signed beta objective and acceptance criteria unchanged.
- A discovered gap is not automatically a beta blocker. By default, create or update a separate ticket in the matching grand family under `Post Bêta`.
- Never add a dependency from an existing beta ticket to new post-beta work when that would make the post-beta ticket a condition of beta release.
- Existing beta tickets may still be implemented, tested, reviewed, have evidence and status synchronized, and be reduced to their already-signed scope. This freeze forbids scope growth, not completion.
- Changing `Gate bêta`, beta family structure, beta views, beta exit criteria, or the beta dependency graph requires an explicit instruction from Yoahn.
- When classification is uncertain, leave beta untouched, classify the work as post-beta, and report the assumption.

Before creating or updating a Notion ticket:

1. If the ticket already exists in beta, work only within its signed scope.
2. If it is new work, place it in the matching grand family under `Post Bêta`.
3. If no Post Beta family fits, stop and request approval before creating a new grand family.
