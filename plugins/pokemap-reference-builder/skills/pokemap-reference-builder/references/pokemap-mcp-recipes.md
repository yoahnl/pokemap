# PokeMap MCP recipes

Always begin with live discovery. Action IDs below are current canonical families, not permission to skip `pokemap_describe` or resource queries.

## Project lifecycle

1. `pokemap_workspace` with `open` and the absolute project root.
2. `pokemap_query` for the target map, project revision, relevant catalogs, and current placements.
3. `pokemap_validate` before mutation.
4. `pokemap_plan` with the current revision and a unique idempotency key.
5. Inspect the returned plan and confirmation contract.
6. `pokemap_apply` with a unique operation ID.
7. Requery, validate, render, then close the workspace.

Open a fresh handle when a previous handle expired. A revision mismatch requires a requery and a new plan.

## Surfaces and forest

Use `environment.attach_to_tile_layer`, `environment.area_create`, `environment.mask_paint`, and `environment.generate_apply` or the equivalent current Environment actions.

Forest is authored as a natural area with an approved Environment preset and mask. Do not replace it with ad hoc repeated placements when the requested surface behavior is available. Query Environment presets first and verify HGSS/DS provenance.

## Paths and rivers

Use `smart_tile.layer.create` and one `smart_tile.cell.paint` gesture containing the approved cell set, or a current pattern action when the geometry genuinely repeats.

Select presets and materials from the live Smart Tile catalogs. For a river, verify that the binding is a river water and bank set. Resource names containing ocean are an immediate rejection signal, but a non-ocean name is not sufficient proof by itself.

## Explicit borders

Use `border_layer.*` only for a separately approved border layer. Typical operations are feature or stroke creation followed by materialization. Never auto-create a border because an earlier reconstruction looked unfinished.

## Structures and decorations

Resolve element IDs from the live catalog and use `placed_element.batch_place` for a reviewed batch. Keep source assets reusable; map-specific elements belong in a map-specific asset folder only when they are genuinely unique.

For a missing asset, import the validated PNG with `asset.import`, then create or update the canonical tileset and element resources through available actions before placement.

## Navigation

Use `collision_layer.replace_region` for a reviewed bounded collision update. Preserve collision outside the region. Use placed-element behaviors or the current canonical connection actions for entrances and traversal.

Validate both activation semantics and arrival cells for warps. A visually correct entrance is not proof of a traversable route.

## Evidence per family

Capture:

- starting and ending revisions;
- plan ID and operation ID;
- receipt action IDs;
- validation result;
- render path and dimensions;
- unresolved warnings;
- human visual verdict.

Structural success remains `applied`, not `verified`, until the required visual or Player review passes.
