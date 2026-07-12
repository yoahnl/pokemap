# PokeMap authoring contract

## Source of truth

- Project catalog: `selbrume/project.json` (`ProjectManifest`).
- Maps: `selbrume/maps/*.json` (`MapData`).
- Shared models: `packages/map_core/lib/src/models/`.
- Editor session: `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`.
- Deterministic Selbrume precedent: `packages/map_editor/tool/generate_selbrume_canonical_maps.dart`.
- Runtime proof: `packages/map_runtime/test/selbrume_map_catalog_integrity_test.dart` and `selbrume_map_render_smoke_test.dart`.

Do not make Desktop folders, complete reference renders, Tiled, or another editor a runtime dependency.

## Authored data

Use `PathLayer` for connected terrain such as roads and water, `TileLayer` for authored tile data, `EnvironmentLayer` for procedural natural masses, and `MapPlacedElement` for editable landmarks and props. Preserve entities, triggers, gameplay zones, events, warps, connections, metadata, layer order, collisions, and lighting unless the brief explicitly changes them.

Store `pokemapPlacementOrigin` in `MapPlacedElement.properties`:

- `authored`: deliberate landmark or hand-adjustment;
- `tile_index`: derived from positive tile patterns;
- `environment`: generated from a persisted Environment area.

Legacy placements without the marker are authored. Loading a map must not silently migrate or re-index them.

## Environment

Persist the preset in `ProjectManifest.environmentPresets`. Persist each area mask, seed, target tile layer, parameters, and `generatedPlacementIds`. Generate with the existing Environment use cases in `packages/map_editor/lib/src/application/use_cases/`; do not implement a second random scatterer. Protect route cells plus at least one cell around exits, doors, warps, interactions, and large footprints.

## Required proof

1. Generator/authoring command is deterministic and has a check-only mode.
2. Project and every changed map decode and validate.
3. A disposable-copy test opens through `EditorNotifier.loadMap`, changes an unrelated value, saves, reloads, and proves authored/tile-index/Environment placements persist.
4. Runtime catalog, render, collision, and traversal checks pass for changed maps.
5. Captures are grid-off and include overview, player-scale routes, landmarks, exits, and collision overlay.

The generic asset audit proposes filesystem candidates; it does not silently rewrite `project.json`. Remove an approved stale catalog entry in the same project change, rerun the graph, then apply only the reviewed hash. Pass identical test/reference root labels to dry-run and apply.

Run package commands from their own directories. Prefer focused tests first, then `flutter test`, `flutter analyze`, and the relevant editor/runtime builds.
