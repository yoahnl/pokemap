# PMCP-032 — Semantic Painting and Deterministic Autotile Evidence Pack

Date: 2026-07-31
Lot: PMCP-032
Phase: 4 — Map authoring
Baseline: `c4df673de docs(authoring): normalize PMCP-031 evidence`

## Verdict

PMCP-032 now exposes preset-driven terrain, path, and surface mutation actions
plus renderer-neutral autotile resolve, preview, validate, apply, and regional
rebuild behavior. Normal callers provide typed preset identities and semantic
occupancy; they never need a tileset ID, atlas coordinate, or raw tile value.

Fresh evidence:

- focused semantic/autotile suite: `+12: All tests passed!`;
- complete `map_authoring` suite: `+208: All tests passed!`;
- focused adapted `map_core` suite: `+41: All tests passed!`;
- analyzer: `No issues found!`;
- formatter: `Formatted 111 files (0 changed)`;
- repository diff hygiene: exit 0, no output.

With the explicit model limits below, PMCP-032 can be proposed as `DONE`.

## Initial audit

The lot started from a clean tree after PMCP-031. The audit confirmed that
PokeMap already persists semantic data rather than resolved artwork:

- `TerrainLayer` stores `TerrainType` cells;
- `PathLayer` stores one preset ID, boolean occupancy, properties, animation
  mode, and triggers;
- `SurfaceLayer` stores sparse surface preset IDs;
- `SmartTileLayer` stores preset/material identities and semantic lattices;
- terrain/path/surface/Smart Tile visual roles are derived by pure `map_core`
  resolvers;
- weighted terrain and Smart Tile choices already accept deterministic seed
  inputs.

The missing API surface was preset validation, stable repair guidance, direct
semantic action descriptors, seed-bound bounded artifacts, and integration
with the revisioned/undoable mutation dispatcher.

Initial Git state:

```text
clean at c4df673de docs(authoring): normalize PMCP-031 evidence
```

## Design decisions

1. Semantic mutation actions emit one complete map-resource change through the
   Phase 3/PMCP-030 transaction path.
2. Terrain requests provide a terrain preset ID, which is resolved to the
   persisted `TerrainType`; raw visual frames never enter the request or
   preview.
3. Path paint/fill validates a path preset and assigns its stable ID to the
   layer. Changing a populated layer to another preset is refused unless the
   caller explicitly uses `path.assign_preset`.
4. Surface paint and replacement validate every sparse preset identity against
   the project surface catalog.
5. Autotile resolution remains derived. `resolve`, `preview`, `validate`, and
   `rebuildRegion` return an artifact rather than fossilizing roles/frames in
   map JSON.
6. `autotile.apply` wraps one terrain/path/surface mutation, retains the exact
   semantic change set, and adds the seed-bound resolved artifact to its
   preview.
7. Resolution expands the requested region by a one-cell halo and is capped at
   4,096 cells. Larger maps are resolved in explicit chunks.
8. Artifacts expose semantic typed references only: preset ID, terrain variant
   reference, path role reference, surface animation ID, or Smart Tile
   rule/candidate ID. No tileset or source rectangle is exposed.

## Implemented action surface

### Terrain

- `terrain.paint`
- `terrain.paint_pattern`
- `terrain.erase`
- `terrain.erase_pattern`
- `terrain.fill`
- `terrain.replace`

Every paint/fill/replace input uses project terrain preset IDs. Pattern payloads
are preset-ID grids, not tile-ID grids.

### Path

- `path.paint`
- `path.paint_pattern`
- `path.erase`
- `path.erase_pattern`
- `path.fill`
- `path.assign_preset`
- `path.set_properties`
- `path.set_animation_mode`

Animation mode accepts stable wire values (`always_active`, `triggered`). Path
patterns carry boolean semantic occupancy because the layer-level preset is the
visual source of truth.

### Surface

- `surface.paint`
- `surface.erase`
- `surface.erase_area`
- `surface.clear`
- `surface.replace_placements`

### Autotile

- pure `resolve` and `preview`;
- pure repair-oriented `validate`;
- pure one-cell-halo `rebuildRegion`;
- mutation action `autotile.apply` with an unchanged wrapped semantic change
  set and deterministic preview fingerprint.

The resolver covers Terrain, Path, Surface, and native Smart Tile layers. Path
pattern presets use the existing center-pattern fallback resolver; surface
roles use exact/isolated fallback semantics; Smart Tile choices use the shared
rule/candidate resolver.

## TDD evidence

### RED — missing semantic and autotile contracts

```text
cd packages/map_authoring
dart test test/domains/maps/semantic_painting_test.dart \
  test/domains/maps/autotile_determinism_test.dart
```

Initial result: exit 1. The tests failed to load because `TerrainActions`,
`PathActions`, `SurfaceActions`, `AutotileActions`,
`SemanticAutotileResolver`, and `SemanticAutotileRegion` did not exist.

### GREEN — focused semantic and deterministic proof

```text
cd packages/map_authoring
dart test test/domains/maps/semantic_painting_test.dart \
  test/domains/maps/autotile_determinism_test.dart
```

Final result: exit 0, `+12: All tests passed!`.

The focused suite proves:

- all 20 mutation descriptors are registered canonically;
- terrain fill/pattern/replace/erase uses preset IDs;
- path paint/fill/properties/animation preserves its preset identity;
- surface paint/clear/replacement/area erase validates preset identities;
- every missing preset family produces a stable code and non-empty repair;
- same map, region, and seed produces byte-equivalent artifact JSON and the
  same SHA-256 fingerprint;
- changing the seed changes weighted terrain variant selection;
- a regional rebuild includes exactly the documented one-cell halo;
- autotile artifacts contain neither `tilesetId` nor `sourceRect`;
- `autotile.apply` produces the exact same change bytes and diff as the wrapped
  semantic action while freezing the plan seed in its artifact.

## Named review passes

No sub-agent was spawned because the active session instruction forbids
delegation unless explicitly requested by the user. Independent review was
performed as named local passes:

### Pass A — semantic contract audit: PASS

Compared every PMCP-032 scope item with registered actions and behavior tests.
Terrain, path, surface, and autotile families are covered without moving later
environment/border/spatial/world work into this lot.

### Pass B — determinism audit: PASS

Verified stable y/x traversal, ordered preset fallback, core weighted
selection with the frozen plan seed, deterministic JSON construction, and
artifact fingerprint equality for repeated resolution.

### Pass C — no-raw-asset audit: PASS

Reviewed request schemas, previews, artifacts, and diffs. They contain semantic
IDs, roles, counts, and references only. Tests explicitly reject `tilesetId`
and `sourceRect` in normal output.

### Pass D — failure and repair audit: PASS

Missing terrain/path/surface/Smart Tile presets, variants, roles, animations,
and candidates produce bounded stable diagnostics. Mutation-time missing
presets carry actionable remediation before any draft/write exists.

### Pass E — transaction and boundary audit: PASS

Semantic engines remain pure Dart in `map_authoring`, depend only on public
`map_core`, and return one revisioned map change. Registration reuses the same
authorization, journal, receipt, audit, history, and undo stack already proven
by PMCP-030/031. The package-boundary test is part of the full suite.

## File inventory and precise zones

Modified:

- `packages/map_authoring/lib/map_authoring.dart`
  - exports the semantic action/support/autotile public API.
- `packages/map_authoring/lib/src/domains/maps/map_mutation_dispatcher.dart`
  - registers terrain, path, surface, and autotile mutation descriptors.

Created:

- `packages/map_authoring/lib/src/domains/maps/semantic_map_action_support.dart`
  - strict parameters, shared map pre-image/draft creation, compact layer diff,
    projected validation, and descriptor factory.
- `packages/map_authoring/lib/src/domains/maps/terrain_actions.dart`
  - preset-driven terrain paint/pattern/erase/fill/replace.
- `packages/map_authoring/lib/src/domains/maps/path_actions.dart`
  - path occupancy, preset assignment/conflict policy, properties, and wire
    animation mode.
- `packages/map_authoring/lib/src/domains/maps/surface_actions.dart`
  - sparse surface paint/erase/clear/atomic replacement.
- `packages/map_authoring/lib/src/domains/maps/autotile_actions.dart`
  - semantic artifact, resolver/validator/rebuild, and apply wrapper.
- `packages/map_authoring/test/domains/maps/semantic_painting_test.dart`
  - action contracts, behavior, catalog validation, and repair tests.
- `packages/map_authoring/test/domains/maps/autotile_determinism_test.dart`
  - seed, halo, fingerprint, no-raw-output, and change-set parity tests.
- `reports/analysis/pmcp_032_semantic_painting_evidence.md`
  - this Evidence Pack.
- `reports/analysis/pmcp_032_created_files_full_content.md`
  - exact content of the seven created production/test files. The two report
    files are excluded to avoid recursive content.

No generated file, dependency, lockfile, roadmap status, editor code, runtime
code, or unrelated package was modified.

## Verification commands and exact results

### Complete authoring suite

```text
cd packages/map_authoring
dart test
```

Result: exit 0, `+208: All tests passed!`.

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

Result: exit 0, `Formatted 111 files (0 changed)`.

### Adapted core resolvers

```text
cd packages/map_core
dart test test/terrain_preset_variant_pick_test.dart \
  test/map_terrain_autotile_characterization_test.dart \
  test/path_pattern_visual_resolution_test.dart \
  test/surface_variant_role_resolver_test.dart
```

Result: exit 0, `+41: All tests passed!`.

### Repository diff hygiene

```text
git diff --check
```

Result: exit 0, no output.

No code generation was required.

## Git state

Initial state:

```text
clean at c4df673de docs(authoring): normalize PMCP-031 evidence
```

Expected lot-only state immediately before staging:

```text
 M packages/map_authoring/lib/map_authoring.dart
 M packages/map_authoring/lib/src/domains/maps/map_mutation_dispatcher.dart
?? packages/map_authoring/lib/src/domains/maps/autotile_actions.dart
?? packages/map_authoring/lib/src/domains/maps/path_actions.dart
?? packages/map_authoring/lib/src/domains/maps/semantic_map_action_support.dart
?? packages/map_authoring/lib/src/domains/maps/surface_actions.dart
?? packages/map_authoring/lib/src/domains/maps/terrain_actions.dart
?? packages/map_authoring/test/domains/maps/autotile_determinism_test.dart
?? packages/map_authoring/test/domains/maps/semantic_painting_test.dart
?? reports/analysis/pmcp_032_created_files_full_content.md
?? reports/analysis/pmcp_032_semantic_painting_evidence.md
```

No unrelated pre-existing change was present or absorbed.

## Critique finale, risks, and non-goals

- `TerrainLayer` persists `TerrainType`, not a per-cell terrain preset ID. When
  multiple terrain presets share one type, a later standalone rebuild chooses
  the lexicographically first compatible preset unless the caller supplies a
  preferred ID. `autotile.apply` carries the chosen ID for its own preview.
- Terrain variants do not have authored stable IDs in `map_core`; artifacts
  therefore expose a typed `(presetId, variantIndex)` reference. This is stable
  for a fixed preset revision but changes if variants are reordered.
- Path and surface resolutions are topology-deterministic and do not currently
  consume randomness; the seed remains in the artifact binding for a uniform
  contract. Weighted terrain and Smart Tile selection do consume it.
- Derived autotile roles are intentionally not stored. A rebuild returns an
  artifact, while `autotile.apply` persists only the semantic edit. This keeps
  editor/runtime resolution aligned with existing PokeMap architecture.
- A full-map resolution larger than 4,096 cells must be requested in chunks.
  `autotile.apply` infers the edited rectangle for normal paint/fill calls.
- Pure resolve/preview/validate/rebuild methods are ready for the later MCP
  adapter; only `autotile.apply` is a writable JSONL mutation command today.
- Environment, borders, spatial objects, world graph, and rendering remain the
  next lots and are not claimed here.

Roadmap files were not edited because the user requested implementation and
per-lot commits, not roadmap status mutation. The next dependency-ready lot is
PMCP-033 — deterministic environment and border authoring.
