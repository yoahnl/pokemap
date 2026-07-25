# PokeMap authoring contract

## Source of truth

- Use the selected PokeMap project's `project.json` and `maps/*.json`.
- Read shared schemas in `packages/map_core/lib/src/models/`.
- Use `EditorNotifier` for a real editor load/save/reload proof.
- Use existing deterministic map generators and runtime smoke tests as patterns.

Desktop source folders, screenshots, Tiled, RPG Maker, or another editor may provide
references. They must never become runtime dependencies.

## Choose the authoring mode

| Mode | Collision/gameplay rule |
|---|---|
| `rebuild-existing` | Preserve entities, triggers, zones, events, warps, connections, IDs, and collisions unless the user explicitly scopes changes. |
| `new` | Design collisions and navigation from the approved floor plan, then prove required routes. There is no legacy collision contract to “freeze.” |

Stop when requested visuals conflict with a protected gameplay contract. Request a
separate decision instead of moving gameplay data silently.

## Native data responsibilities

Use:

- `TileLayer` for authored repeatable tile data;
- `PathLayer` and surfaces for connected terrain;
- `EnvironmentLayer` for eligible procedural natural masses;
- `MapPlacedElement` for independently bounded architecture, landmarks, and props;
- collision/gameplay layers for gameplay truth, never visual camouflage.

Keep floors, paths, normal walls, corners, door openings, roofs, props, foreground
occluders, and effects separable enough to edit. A single placed element covering the
whole map is not native modular authoring, even though its JSON is technically editable.

Store `pokemapPlacementOrigin` in placement properties when generated:

- `authored`: deliberate landmark or hand adjustment;
- `tile_index`: derived from positive tile patterns;
- `environment`: generated from a persisted Environment area.

Legacy placements without the marker remain authored.

## Grid and atlas semantics

Read `settings.tileWidth`, `settings.tileHeight`, and `settings.displayScale`; do not
conflate native grid dimensions with runtime pixels.

For tile layers, verify the engine's one-based atlas tile convention: serialized tile
ID `0` means empty, so atlas cell index `N` is normally serialized as `N + 1`.
Prove this through the actual renderer; an off-by-one error can look like a scale or
spacing problem.

Every tile and collision array must contain exactly `mapWidth × mapHeight` entries.
Every placed element frame must resolve to a known project element and tileset.

## Placement bounds and map edges

Compute each placed element's maximum frame footprint. Require:

```text
0 <= x
0 <= y
x + width  <= map.width
y + height <= map.height
```

Do not rely on renderer clipping. Reject an ordinary placed element that covers all four
map edges; use modular parts. Allow a full-canvas element only for a deliberately
approved backdrop whose exception is recorded by element ID.

Run the one-cell padded-canvas proof from `map-quality-gates.md`.

## Collision and navigation

For a rebuild, compare protected collision and gameplay data before/after. For a new
map, author collision footprints from ground contact and validate them.

Require:

- exactly one intended collision truth for runtime;
- correct grid length and boolean values;
- walkable entry/exit cells;
- four-directional reachability from the primary entry to every required target;
- clear approach cells for doors, warps, and interactions;
- explicit justification for disconnected walkable components.

Never infer collision from opaque reference pixels.

## Environment

Persist presets, area masks, seeds, target layers, parameters, and generated placement
IDs. Use the existing Environment use cases in `map_editor`; do not add an independent
random scatterer. Exclude routes, landmarks, doors, exits, interactions, and their safety
buffers. Regenerate twice and compare generated IDs, elements, and positions.

## Required proof

1. Deterministic authoring command with a check-only mode when generated.
2. Project and changed maps decode and validate.
3. Editor load, unrelated edit, save, reload preserves authored data.
4. Structural validator passes explicit entries and targets.
5. Runtime catalog, asset loading, render, collision, and traversal checks pass.
6. Capture pack satisfies `visual-acceptance.md`.

Run package commands from their own directories. Prefer focused tests, then the relevant
package test/analyze commands required by repository instructions.
