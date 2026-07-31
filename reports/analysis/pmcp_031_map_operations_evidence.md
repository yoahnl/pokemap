# PMCP-031 — Layers, Regions, and Atomic Operation Batches Evidence Pack

Date: 2026-07-31  
Lot: PMCP-031  
Phase: 4 — Map authoring  
Baseline: `35bc8e0d6 feat(authoring): add canonical map lifecycle`

## Verdict

PMCP-031 now exposes `map.apply_operations` as one bounded, revision-checked,
idempotent, undoable mutation. A request can manage every `MapLayer` kind and
compose strict cell, region, shape, clipboard, and transform operations in
memory before one projected-state validation and one map-resource change.

Fresh evidence:

- focused `map_authoring` contract and transaction tests: `+11: All tests passed!`;
- complete `map_authoring` suite: `+196: All tests passed!`;
- focused `map_core` adapted-operation suite: `+55: All tests passed!`;
- analyzer: `No issues found!`;
- formatter: `Formatted 104 files (0 changed)`;
- `git diff --check`: exit 0, no output.

With the documented limits below, PMCP-031 can be proposed as `DONE`.

## Initial audit

The lot started from a clean tree immediately after PMCP-030. The baseline
already supplied the canonical lifecycle adapter, mutation dispatcher,
revision/CAS planning, recoverable journal, authorization, audit, history, and
undo. The audit identified these reusable `map_core` primitives:

- `addMapLayer`, `renameMapLayer`, `removeMapLayer`, `moveMapLayer`,
  `reorderMapLayers`, visibility, and opacity operations;
- native Smart Tile layer creation and material storage;
- typed tile, collision, terrain, path, and sparse surface representations;
- immutable `MapData` copies and `MapValidator` projected-state validation.

The missing surface was exactly the lot scope: no compact layer/region batch,
no request-local clipboard, no general shapes/transforms, and no single atomic
map change binding those operations to Phase 3 transaction guarantees.

Initial Git state:

```text
clean at 35bc8e0d6 feat(authoring): add canonical map lifecycle
```

## Success criteria and design decisions

The implementation uses these explicit rules:

1. A batch contains 1–256 operations and targets a map of at most 1,000,000
   cells.
2. Operations are applied only to immutable in-memory `MapData` values.
3. Any malformed or semantically invalid operation is wrapped as
   `map.operation_invalid` with its stable index and kind; no draft exists and
   therefore no disk write is possible.
4. The complete projected map is validated once before producing a change set.
5. A valid batch emits exactly one map resource change and one bounded diff
   summary, so Phase 3 produces one receipt/history/undo entry.
6. Cell payloads are never copied into the receipt. At most 64 operation
   summaries and 64 touched layer IDs are exposed.
7. Copy/cut/paste uses a request-local named clipboard. No mutable global or
   cross-request clipboard state exists.
8. Region operations refuse clipping and out-of-bounds coordinates. Odd
   in-place quarter-turns require square selections so map/layer dimensions and
   every non-cell reference remain unchanged.

## Implemented surface

### Layer lifecycle

`MapLayerOperations` supports:

- `layer.add` for tile, collision, terrain, path, surface, Smart Tile, object,
  environment, and border layers;
- `layer.rename`, `layer.remove`/`layer.delete`, `layer.move`, and
  `layer.reorder`;
- `layer.set_visibility`, `layer.set_opacity`, and typed `layer.clear`.

Clearing preserves layer metadata. Object-layer clear also removes placed
elements owned by that layer; Smart Tile clear preserves preset, palette, seed,
and edge-lattice dimensions while clearing authored lattice values.

### Cell, region, shape, and clipboard operations

`MapRegionOperations` supports:

- paint, erase, exact stamp, rectangle fill, flood fill, and replace;
- Bresenham line, polyline, outlined/filled rectangle, and
  outlined/filled polygon;
- named copy, cut, paste, direct move, in-place rotate, and horizontal/vertical
  flip.

The dense adapter is typed for tile (`int`), collision/path (`bool`), terrain
(`TerrainType` name), sparse surface (preset ID or null), and Smart Tile cell
materials (material ID or null). Object, environment, and border layers reject
cell-addressed operations and remain available through lifecycle/domain actions.

### Atomic action integration

`MapOperationsActions` registers `map.apply_operations` in the canonical map
mutation dispatcher. It reuses the existing local mutation session, so direct
API and JSONL callers receive the same plan, confirmation, revision, journal,
receipt, history, audit, and undo behavior as PMCP-030 without a second write
path.

## TDD evidence

### RED — missing region and batch contracts

```text
cd packages/map_authoring
dart test test/domains/maps/region_operations_test.dart \
  test/domains/maps/map_operations_batch_test.dart
```

Initial result: exit 1. The tests failed to load because
`MapRegionOperations`, `MapRegionClipboard`, `MapLayerOperations`, and
`MapOperationsActions` did not exist.

### GREEN — focused behavior and transaction proof

```text
cd packages/map_authoring
dart test test/domains/maps/region_operations_test.dart \
  test/domains/maps/map_operations_batch_test.dart
```

Final result: exit 0, `+11: All tests passed!`.

The focused suite proves:

- paint/stamp/fill/flood/replace and all requested shape families;
- copy/cut/paste/move/rotate/flip with map dimensions, layer ID, and warp
  references preserved;
- typed values across every cell-addressable layer kind;
- out-of-bounds and non-square odd-rotation refusal;
- lifecycle coverage across all nine `MapLayer` runtime kinds;
- one compact change set for a complete multi-layer fixture;
- invalid operation index reporting and original-map immutability;
- one real transaction receipt and one undo restoring the exact map pre-image;
- invalid real transaction planning leaves the map file byte-identical.

## Named review passes

No sub-agent was spawned because the active repository/session instruction
forbids delegation unless the user explicitly requests it. The required
independent review evidence was performed as named local passes:

### Pass A — contract and scope audit: PASS

Compared the implementation against every PMCP-031 scope and done criterion.
All requested operation families are represented, and later semantic/domain
work remains separated into PMCP-032 through PMCP-035.

### Pass B — atomicity and transaction audit: PASS

Confirmed that operation engines receive no write port, mutate only immutable
in-memory values, and return one `AuthoringResourceChange`. A real local session
test proves one apply receipt and one history undo for the entire batch.

### Pass C — bounds and payload audit: PASS

Confirmed strict unknown-field rejection, exact stamp lengths, typed values,
map/layer dimensions, no implicit clipping, 256-operation and 1,000,000-cell
bounds, and receipt summaries without cell arrays.

### Pass D — reference-preservation audit: PASS

Transform tests prove `MapData.size`, the target layer identity, and authored
warp references remain unchanged. Layer removal still relies on complete
projected validation, which rejects dangling layer references before a draft is
returned.

### Pass E — package-boundary and regression audit: PASS

All implementation remains pure Dart inside `map_authoring`, depends only on
public `map_core`, and introduces no Flutter/Flame/editor dependency. The full
package-boundary suite is included in the 196 passing `map_authoring` tests.

## File inventory and precise zones

Modified:

- `packages/map_authoring/lib/map_authoring.dart`
  - exports the public layer, region, and batch contracts.
- `packages/map_authoring/lib/src/domains/maps/map_mutation_dispatcher.dart`
  - registers the new canonical `map.apply_operations` descriptor/builder.

Created:

- `packages/map_authoring/lib/src/domains/maps/layer_actions.dart`
  - shared step result and lifecycle engine for all layer kinds.
- `packages/map_authoring/lib/src/domains/maps/region_operations.dart`
  - strict dense/sparse cell adapter, shapes, clipboard, and transforms.
- `packages/map_authoring/lib/src/domains/maps/map_operations_batch.dart`
  - bounded request contract, all-or-nothing orchestration, validation, compact
    diff, and mutation draft.
- `packages/map_authoring/test/domains/maps/region_operations_test.dart`
  - region, shape, clipboard, transform, typing, and bounds tests.
- `packages/map_authoring/test/domains/maps/map_operations_batch_test.dart`
  - descriptor, full fixture, lifecycle, compactness, rejection, receipt, and
    undo tests.
- `reports/analysis/pmcp_031_map_operations_evidence.md`
  - this evidence pack.
- `reports/analysis/pmcp_031_created_files_full_content.md`
  - exact full content of the five created production/test files above. The two
    mutually-referential report files are deliberately excluded to avoid a
    recursive artifact.

The exact created code/test contents are preserved in the companion appendix.
No generated file, dependency, lockfile, roadmap status, or unrelated package
was modified.

## Verification commands and exact results

### Complete authoring suite

```text
cd packages/map_authoring
dart test
```

Result: exit 0, `+196: All tests passed!`.

### Static analysis

```text
cd packages/map_authoring
dart analyze
```

Result: exit 0, `No issues found!`.

### Formatting

```text
cd packages/map_authoring
dart format --output=none --set-exit-if-changed lib test bin
```

Result: exit 0, `Formatted 104 files (0 changed)`.

### Adapted map-core operations

```text
cd packages/map_core
dart test test/surface_layer_placements_test.dart \
  test/smart_tiles/smart_tile_layer_operations_test.dart \
  test/environment_layer_map_layer_integration_test.dart \
  test/border/border_layer_operations_test.dart
```

Result: exit 0, `+55: All tests passed!`.

### Repository diff hygiene

```text
git diff --check
```

Result: exit 0, no output.

No code generation was required.

## Git state

Initial state:

```text
clean at 35bc8e0d6 feat(authoring): add canonical map lifecycle
```

Expected lot-only state immediately before staging:

```text
 M packages/map_authoring/lib/map_authoring.dart
 M packages/map_authoring/lib/src/domains/maps/map_mutation_dispatcher.dart
?? packages/map_authoring/lib/src/domains/maps/layer_actions.dart
?? packages/map_authoring/lib/src/domains/maps/map_operations_batch.dart
?? packages/map_authoring/lib/src/domains/maps/region_operations.dart
?? packages/map_authoring/test/domains/maps/map_operations_batch_test.dart
?? packages/map_authoring/test/domains/maps/region_operations_test.dart
?? reports/analysis/pmcp_031_created_files_full_content.md
?? reports/analysis/pmcp_031_map_operations_evidence.md
```

No unrelated pre-existing change was present or absorbed.

## Critique finale, risks, and non-goals

- The named clipboard exists only during one batch. Cross-request clipboard
  persistence is intentionally absent because it would introduce mutable
  session state and stale-revision ambiguity.
- Odd in-place quarter-turn rotation is intentionally square-only. A future UI
  may model non-square rotation as an explicit copy into a swapped-dimension
  destination, but silent cropping is refused.
- `changedCellCount` is a cumulative per-operation count; repeated edits of the
  same cell may count more than once. This is a bounded workload signal, not a
  unique-cell metric.
- Raw tile IDs remain available in this low-level batch contract. PMCP-032 adds
  the normal semantic preset-based terrain/path/surface/autotile workflow.
- Environment and border content generation, spatial objects, world graph, and
  rendering remain outside this lot and are assigned to PMCP-033–PMCP-035.
- The action is available through the direct API and existing writable JSONL
  worker. MCP transport remains a later phase and is not claimed.

Roadmap files were not edited because the user requested implementation and
per-lot commits, not roadmap status mutation. The next dependency-ready lot is
PMCP-032 — semantic terrain, path, surface, and autotile authoring.
