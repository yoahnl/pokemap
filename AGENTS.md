# Repository Guidelines

PokeMap/Avelune is a Dart/Flutter monorepo for a Pokemon-like no-code fangame
editor, runtime and battle stack. The goal is playable RPG creation. Work in
small scoped changes, respect package boundaries, and prove results.

This file is the entry point that Codex and Claude Code load automatically.
It holds the invariants and routes to detailed references, which are **not**
loaded automatically: open the ones your task triggers (section 5) before
editing. Their criteria stay mandatory for those tasks.

## 1. Priority

1. Direct user request.
2. Nearest `AGENTS.md` in the edited tree.
3. This file, then the references it routes to.
4. User-referenced specs, roadmaps, reports or lot files.
5. Local skills: `skills/README.md`, then the selected `skills/<name>/SKILL.md`.
6. MCP, docs and tooling guidance.
7. Default agent behavior.

On conflict, follow the stricter safe rule and report it. Skills never override
user instructions, these rules, Git safety, package boundaries or the roadmap.
Use the smallest relevant set of skills, reread the selected `SKILL.md` rather
than relying on memory, and adapt conservatively, reporting it, when a skill
assumes unavailable tooling.

## 2. Repository shape

No workspace orchestrator (`melos.yaml` absent): run commands per package.

| Path | Role |
|---|---|
| `packages/map_core` | Shared contracts, JSON models, validation. Pure Dart. |
| `packages/map_gameplay` | Pure overworld decisions. Pure Dart. |
| `packages/map_battle` | Battle mechanics. Pure Dart. |
| `packages/map_runtime` | Flutter + Flame runtime integration. |
| `packages/map_editor` | Desktop authoring UI and editor use cases. |
| `examples/playable_runtime_host` | Runtime host and smoke fixtures. |

Preserve the public barrels `lib/<package>.dart` of `map_core`, `map_gameplay`,
`map_battle` and `map_runtime` when adding exported API.

## 3. Invariants

- **Git:** read-only unless the user explicitly asks. No add, commit (amend
  included), push, reset, restore, stash, rebase, merge, tag, rm, branch or
  worktree changes, checkout/switch that changes files, or destructive cleanup
  of tracked work. Check the working tree before and after.
- **Pre-existing work:** never hide, overwrite, revert or claim changes made
  before the task or by another session; report ambiguous attribution.
- **Honest validation:** no claim without a command that actually ran with a
  known result. Not run, interrupted, timed out or unknown is not a success.
  No fake tests, invented totals or deleting code to stage a RED phase.
- **Boundaries:** pure Dart packages stay Flutter/Flame-free; gameplay rules
  never hide in Flame components; the editor does not couple to runtime
  internals; PokeMap owns its data (external formats are never runtime needs).
- **Project and game compatibility:** valid authoring projects, maps and games
  exported from Avelune Studio `0.3.31+331` onward stay readable and playable
  by later Players. A format or persisted-behavior change to them needs a
  tested reader or deterministic conversion; a failure never overwrites or
  resets the original. Player progression saves follow section 4 instead.
- **Renderer and provider independence:** integrate replaceable providers
  through Avelune-owned contracts and adapters; vendor types stay inside
  adapters; the host owns simulation and story clocks.
- **Incremental authoring:** a local edit costs work bounded by the changed
  data and its dependencies: no full project load, global validation or
  rebuild per edit (targets: 100 ms feedback, 500 ms durable save).
- **No-code UI:** editor UI uses design-system widgets and theme tokens, never
  hardcoded colors. Maps use native terrain, paths, Borders and trees.
- **MCP parity:** a change to authoring behavior, project data, editor
  commands, validation, import/export, rendering or playtest assesses PokeMap
  MCP parity before completion.
- **Processes and QA artifacts:** stop only harnesses your run owns, never by
  process name. Disposable QA artifacts live only under
  `/Users/karim/Library/Caches/AveluneQA/<task>` and are removed before closing.
- **Tracking:** record every task in the Notion cockpit (existing domain,
  `TO REVIEW`, never `DONE` by an agent). Never grow the frozen beta scope.
- **Docs and code style:** zero new Markdown by default and never at the root;
  no code comments, DartDoc or TODO unless the user asks.

## 4. Player progression saves

Policy decided by Yoahn on 2026-11-08; it replaces the former cumulative
guarantee for saved games.

- Backward compatibility of player progression saves (position, party,
  inventory, facts and progression, for example) is not guaranteed during the
  current development phase. Format or semantic changes may make older saves
  incompatible. A historical migration or legacy reader is not required unless
  explicitly requested.
- Saving and resuming with the currently supported format must stay reliable
  and tested. Keep a save format version distinct from the application version
  and identify contract breaks, including semantic ones.
- An unsupported format is reported clearly, without overwriting, deleting or
  silently converting the original file, and without automatically replacing
  the playthrough with a new one.
- Restoring a compatibility guarantee requires an explicit decision and a new
  reference version; it does not automatically promise to resume saves
  abandoned before that reference.
- This suspension covers progression saves only. It does not revoke the
  compatibility of authoring projects, maps or exported games, it is not a
  request to break working saves, and it does not remove existing codecs,
  migrations, fixtures or tests; retiring legacy code needs its own targeted,
  justified change that keeps current-format and data-preservation tests.
- Announce a save break to the affected testers: they may have to restart.

## 5. Read before editing

| When the task… | Read first |
|---|---|
| edits files or runs commands | `agent_rules.md` §1–8 |
| runs `flutter test`, starts processes or creates QA environments | `agent_rules.md` §9–10 |
| writes a report or Markdown, runs codegen, touches CI, Notion or beta tickets | `agent_rules.md` §11–15 |
| changes an editor/Studio interaction, save, autosave or undo path | [policies](documentation/architecture/product_and_architecture_policies.md) §Incremental authoring |
| changes a project, map, package or exported-game format, export or Player loading | policies §Compatibility |
| changes the player save format or save/load | section 4 above, then the current-format save/load tests |
| touches rendering, 3D, providers, scenes, cameras or asset lifecycle | policies §Renderer independence |
| changes editor UI, map construction, schemas or package boundaries | policies §Product rules |
| works on fangame mechanics (party, items, battles, saves, story…) | policies §Mechanics, then only the relevant `FG-*` sections of `pokemap_roadmap_mecaniques_fangame.md` |
| uses Flame APIs or needs PSDK parity | policies §Flame and PSDK |
| authors projects, uses the PokeMap MCP or needs MCP parity | `skills/using-pokemap-mcp/SKILL.md` |
| builds 3D reliefs or maps from a reference | `skills/authoring-pokemap-3d-reliefs`, `skills/creating-pokemap-maps-from-reference` |
| debugs a failure / adds behavior / claims completion | `systematic-debugging` / `test-driven-development` / `verification-before-completion` skills |

Open only the triggered sections, not whole files. Clients do not all load
nested instruction files: before editing under a directory, check for a nearer
`AGENTS.md`.

## 6. Working method

- Start from `git status --short --untracked-files=all`; for mechanics, name
  the `FG-*` lot.
- Inspect the relevant files, contracts and tests; widen the analysis when the
  impact justifies it, without a systematic global audit.
- Make a coherent, bounded change; report out-of-scope problems instead of
  fixing them silently.
- Use sub-agents only for an independent investigation or a justified review;
  no number of roles is imposed. A second pass by the same agent is not an
  independent review.
- Add or adapt tests when behavior changes. Choose validations from the
  affected contracts and consumers, without artificial tests or a ceremonial
  application build for a documentation change.
- Do not add comments to code unless explicitly asked.
- Deliver the essential changes, the commands actually run with their results,
  the checks not run and the limits. Do not systematically reproduce full
  sources, diffs and logs in the answer; keep useful evidence accessible to
  the reviewer.
- No report file per lot or per task: the chat answer is the report. Create a
  persistent report only when explicitly asked. Preserve pre-existing work and
  the Git write restrictions.
- Before closing: stop owned processes, remove owned QA artifacts, run
  `bash tools/scripts/check_markdown_hygiene.sh` when Markdown changed, and
  update Notion.

## 7. Validation

```bash
cd packages/map_core && dart test && dart analyze
cd packages/map_gameplay && dart test && dart analyze
cd packages/map_battle && dart test && dart analyze
cd packages/map_runtime && flutter test && flutter analyze
cd packages/map_editor && flutter test && flutter analyze
cd examples/playable_runtime_host && flutter test && flutter analyze
```

Runtime smoke checks for player-loop or battle/runtime work:
`packages/map_runtime/test/phase_a_golden_battle_slice_smoke_test.dart` and
`examples/playable_runtime_host/test/phase_a_golden_slice_launch_test.dart`.

## 8. Maintenance

Keep this file an entry point of about 8 KiB: Codex truncates project
instructions at `project_doc_max_bytes` (32 KiB by default). Put details in
the routed references, never by raising that limit. The map of former sections
is at the end of the policies document. After editing, check `wc -c AGENTS.md`
and that every routed reference still exists.
