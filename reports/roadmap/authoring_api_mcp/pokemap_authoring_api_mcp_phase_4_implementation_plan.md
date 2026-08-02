# PokeMap Authoring API — Phase 4 Implementation Plan

> Phase: **4 — Maps de bout en bout**
> Lots: **PMCP-030 → PMCP-035**
> Execution: current `main` branch, one verified commit per lot, no push
> Initial Git state: clean at `1e3d8787a feat(authoring): add mutation history and undo`

## Goal and exit contract

Phase 4 exposes map authoring through the protocol-neutral API built in phases
1–3. A structured request must be able to plan, preview, validate, apply,
recover, and undo a complete map workflow without importing Flutter or editor
infrastructure into `map_authoring`.

The phase is complete only when fresh tests prove all of the following:

- map lifecycle changes preserve exact pre-images and write the manifest and
  map documents through one recoverable transaction;
- every write has a structured diff, a revision-bound preview, a receipt, and
  an undo path;
- layer and bounded region operations batch atomically and preserve layer
  dimensions;
- semantic terrain, path, surface, and autotile requests are deterministic for
  the same seed and refuse missing presets with repair guidance;
- environment and border generation is deterministic, local, diagnosed, and
  refuses unpublished or invalid blueprint state;
- placed elements, entities, triggers, gameplay zones, and collision expose
  typed mutations plus effective-collision provenance and reachability checks;
- warps and bidirectional connections update both maps in one recoverable
  transaction, and the world graph is deterministic;
- rendering is accessed through a port and is always tied to a saved snapshot
  revision; the pure package does not depend on Flutter or Flame;
- the JSONL worker exposes the same plan/apply contracts without returning
  canonical filesystem paths.

## Architecture decisions

- `map_authoring` remains pure Dart and depends only on `map_core`.
- Domain handlers build immutable `AuthoringMutationDraft` values from one
  `ProjectSnapshot`; only the Phase 3 secure executor receives a write gateway.
- Exact snapshot bytes are retained under path-free resource identities so
  compare-and-swap uses real disk pre-images rather than re-encoded objects.
- Map documents use the editor-compatible two-space JSON representation.
  Manifest writes merge typed fields into the original JSON object so unknown
  top-level project fields survive lifecycle operations.
- Public resource references stay typed and path-free. Safe manifest-owned
  relative paths remain private transaction storage keys.
- A local mutation session captures the authorized canonical root behind
  opaque project/workspace handles and composes the Phase 3 journal,
  idempotency, audit, history, confirmation, recovery, and undo services.
- Rendering uses an injected `MapRenderPort`; the default pure adapter returns
  a deterministic render model, while Flutter/Flame adapters remain outside
  `map_authoring`.

## Verification and review passes

Sub-agent delegation is disabled by the active repository/session rules. Each
lot therefore records five separate local passes required by `codex_rule.md`:

1. **Audit / Architecture** — boundaries, contracts, and dependency review;
2. **Implementation** — scoped diff review against the lot exit criteria;
3. **Tests** — RED/GREEN, guards, failure cases, and non-regression;
4. **Build / Validation** — focused tests, package suite, analyzer, formatter,
   and JSONL executable smoke where relevant;
5. **Critique finale** — durability, determinism, security, overclaim, and
   remaining-risk review.

## PMCP-030 — Canonical map lifecycle

- Add lifecycle handlers for create, save, rename, duplicate, delete, and
  resize, plus dependency and resize-impact preflights.
- Add a generic map mutation dispatcher and local secure mutation session.
- Add JSONL `plan`, `confirm`, `apply`, `undo`, and `recover` commands while
  retaining the read-only worker mode used by Phase 2.
- Prove manifest+map crash recovery, reference protection, receipt/history,
  create/resize undo, legacy path ownership, and editor-compatible encoding.
- Evidence: `reports/analysis/pmcp_030_map_lifecycle_evidence.md` plus created
  content appendix.
- Commit: `feat(authoring): add canonical map lifecycle`

## PMCP-031 — Layers, regions, and operation batches

- Add lifecycle support for every `MapLayer` kind and a bounded
  `map.apply_operations` batch.
- Support paint, erase, stamp, fill, replace, flood fill, line, polyline,
  rectangle, polygon, clipboard move/copy/cut/paste, rotate, and flip where the
  layer semantics allow them.
- Apply the complete batch in memory, validate once, and emit one map change,
  one receipt, and one undo entry; any invalid operation rejects the full
  batch.
- Evidence: `reports/analysis/pmcp_031_map_operations_evidence.md` plus appendix.
- Commit: `feat(authoring): add atomic map operation batches`

## PMCP-032 — Terrain, paths, surfaces, and autotile

- Add typed semantic operations using project preset IDs instead of raw tile
  coordinates in the normal workflow.
- Freeze the generation seed in the plan and prove preview/apply determinism.
- Diagnose missing presets with stable codes and repair suggestions.
- Evidence: `reports/analysis/pmcp_032_semantic_painting_evidence.md` plus
  appendix.
- Commit: `feat(authoring): add semantic map painting`

## PMCP-033 — Environment and borders

- Add deterministic environment areas, masks, generation, placements, and
  manual overrides.
- Add border stroke, feature, blueprint link/relink, materialization, resize,
  diagnostics, readiness, and preview operations by adapting `map_core`.
- Bind every generated preview to revision and seed and prove local-halo
  behavior.
- Evidence: `reports/analysis/pmcp_033_environment_border_evidence.md` plus
  appendix.
- Commit: `feat(authoring): add environment and border actions`

## PMCP-034 — Spatial objects and effective collision

- Add typed CRUD and atomic batch moves for placed elements, entities, NPCs,
  triggers, gameplay zones, and collision layers.
- Add effective-collision inspection with source provenance, walkability, and
  deterministic reachability diagnostics.
- Refuse incompatible payloads and out-of-bounds batches before mutation.
- Evidence: `reports/analysis/pmcp_034_spatial_collision_evidence.md` plus
  appendix.
- Commit: `feat(authoring): add spatial map authoring`

## PMCP-035 — Warps, connections, world graph, and rendering

- Add warp/connection CRUD plus reciprocal/bidirectional two-map plans.
- Add deterministic graph inspection, connected/disconnected sets,
  consistency validation, and pathfinding.
- Add alignment preview and revision-bound map/region/layer render requests
  through `MapRenderPort`, including optional collision/entity/warp overlays.
- Explicitly report that no global authored `worldLayout` exists.
- Evidence: `reports/analysis/pmcp_035_world_graph_render_evidence.md` plus
  appendix.
- Commit: `feat(authoring): add world graph and map rendering`

## Final phase validation

From `packages/map_authoring`:

```bash
dart test
dart analyze
dart format --output=none --set-exit-if-changed lib test bin
dart run bin/pokemap_authoring.dart \
  --root ../../examples/playable_runtime_host </dev/null
```

Run focused `map_core`, `map_editor`, and `map_runtime` checks whenever a lot
changes or adapts their public contracts. Record exact results and final Git
status in the PMCP-035 evidence pack; do not update roadmap status without an
explicit request.
