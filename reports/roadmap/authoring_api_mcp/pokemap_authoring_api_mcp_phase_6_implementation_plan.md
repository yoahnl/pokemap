# PokeMap Authoring API — Phase 6 Implementation Plan

> Phase: **6 — Runtime, playtest et distribution**
> Lots: **PMCP-070 → PMCP-072**
> Execution: current branch, one verified commit per lot, no push
> Initial Git state: `main` at `b13d74aa9 feat(authoring): add battle progression authoring`

## Goal and exit contract

Phase 6 proves the path from an identified authoring snapshot to the production
runtime and then to deterministic distribution bytes. It does not add MCP
transport or migrate the editor. Public contracts remain pure Dart and
path-free; platform resource ownership stays in runtime/host adapters.

The phase exits only when:

- a playtest session freezes a `sha256:` project revision, scenario, and seed;
- its save/checkpoint and temporary artifacts cannot mutate production data;
- start, pause, resume, command, snapshot, diff, screenshot, and stop are typed;
- PokeMap Eval commands use one shared production dispatcher;
- long jobs have ordered events, bounded cancellation, and explicit retry;
- readiness diagnostics cite evidence and never apply fixes automatically;
- package build, inspect, and verification agree on the exact archive digest;
- the public Authoring API can construct the Golden Slice fixture without raw
  JSON editing.

## Architectural decisions

- `map_authoring` owns protocol-neutral contracts and ports only.
- `map_runtime` adapts runtime drivers to those contracts.
- `examples/playable_runtime_host` adapts PokeMap Eval and owns temporary I/O.
- `map_distribution` remains the authority for package bytes and inspection.
- Project revision checks run at start and across session boundaries; drift is
  a failure, not a warning.
- PokeMap Eval's serialized in-memory repository is the sandbox save authority.
- No capability is advertised from catalog presence alone.
- `FG-180` through `FG-184` remain `DONE`; `FG-185` remains `PARTIAL` unless
  fresh release evidence closes its external signing and human-walkthrough
  gates. This plan does not edit the mechanics roadmap.

## Lot PMCP-070 — Ports de playtest et session sandboxée

1. Add strict immutable playtest contracts and the `PlaytestPort` boundary.
2. Add the runtime session adapter with ordered events, revision guards,
   pause/resume, snapshots/diffs, artifacts, receipt, and idempotent cleanup.
3. Extract one PokeMap Eval command dispatcher shared by scenarios and API runs.
4. Add an Eval driver wrapper with tree-digest checks, seeded factory input,
   in-memory save authority, capture sandbox, and recursive cleanup.
5. Verify focused tests, full touched-package tests/analyzers, evidence report,
   then commit as `feat(authoring): add sandboxed playtest sessions`.

## Lot PMCP-071 — Commandes manquantes, jobs et artefacts

1. Extend the reviewed command catalog and shared dispatcher for the runtime
   player, services, battle choices, and explicit battle-start paths that have
   production consumers.
2. Expand state/assertion evidence for Scene, outcome, and visual observations.
3. Add pure job/artifact contracts plus a bounded runtime job service exposing
   get/events/cancel/retry with stable event order.
4. Prove commands are non-opaque and cancellation releases worker resources.
5. Verify and commit as `feat(eval): add runtime jobs and artifacts`.

## Lot PMCP-072 — Readiness, Golden Slice et package identique

1. Add readiness actions that aggregate validators and return planned fixes
   only; every release diagnostic cites a stable evidence reference.
2. Add distribution actions for build/inspect/verify and a release receipt
   binding source revision, package digest, installed digest, and gates.
3. Extend `GamePackageBuilder` with explicit archive identity evidence without
   changing deterministic package bytes.
4. Build a Golden Slice fixture through public authoring operations and execute
   the production runtime smoke path plus the regression matrix.
5. Verify and commit as `feat(authoring): prove runtime package identity`.

## Dirty-worktree protocol

The initial workspace already contains an unstaged host lockfile change, an
untracked `.superpowers` prototype, and an untracked UI evidence report. Each
lot stages explicit paths only, runs `git diff --cached --check`, and reports
the final status. No roadmap status is changed automatically.
