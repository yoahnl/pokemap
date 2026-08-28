---
name: pokemap-reference-builder
description: Decode an exterior map reference image into reviewable semantic layers, create correctly sized missing assets when needed, and reconstruct an editable map through the canonical PokeMap MCP. Use for exterior-map reference reconstruction, not interiors or flattened background imports.
---

# PokeMap Reference Builder

Convert a visual reference into an editable PokeMap composition. The reference guides geometry and visual hierarchy; it is never imported as a runtime background.

## Required inputs

Obtain or infer:

- the attached reference image;
- the absolute PokeMap project root;
- the target map ID or approval to create one;
- map width and height in 32 px cells.

If map dimensions are not explicit, propose them from the reference and viewport goal, then obtain approval before mutation. This workflow supports exterior maps only.

## Start with capability discovery

Call `pokemap_describe` before opening the project. Require the live catalog to expose the action families needed by the approved blueprint. At minimum, ordinary exterior reconstruction needs Environment, Smart Tiles, placed elements, collisions, rendering, and validation.

Do not translate a missing action into direct JSON edits. Report the MCP parity gap and stop that family. A transport failure is not evidence that the server contract is absent; retry with a fresh configured PokeMap MCP transport before concluding that the capability is missing.

## Decode before authoring

Inspect the reference visually and create a semantic blueprint before any PokeMap mutation. Read [the layer model](references/exterior-layer-model.md), then use `scripts/blueprint_tool.py init` and fill the resulting JSON.

Classify geometry into these families:

1. `surface` for ground masses and forest coverage;
2. `network` for paths, rivers, stairs, and other connected lines;
3. `border` only for an explicitly approved border system;
4. `structure` for buildings, gates, bridges, and monuments;
5. `decoration` for trees, rocks, flowers, signs, and props;
6. `navigation` for collision, entrances, exits, warps, and traversal zones.

Every layer begins as `proposed`. Show the blueprint summary and unresolved bindings. Do not advance it to `approved` without human review.

## Visual and provenance invariants

Read [the HGSS/DS quality gates](references/hgss-ds-quality-gates.md) before binding assets or creating a missing asset.

- Native cell size is exactly 32 px.
- Accepted provenance is `hgss_ds` or `custom_hgss_compatible`.
- Reject GBA assets and ambiguous mixed-generation sheets.
- Forests use the canonical Environment capability as the natural-surface implementation. If the live product semantics do not satisfy the requested Surface Studio behavior, stop instead of substituting a repeated tree grid.
- Rivers use river water and river banks, never ocean water.
- Do not create or apply Smart Borders unless the blueprint contains a separately approved `border` layer.
- Use nearest-neighbor scaling only when an approved custom asset requires an integer scale. Never use fractional scaling or smoothing.

## Missing asset workshop

When no existing HGSS/DS resource satisfies an approved structure or prop:

1. Declare the footprint in cells with `scripts/asset_contract.py init`.
2. Keep the candidate under `<project>/.pokemap/authoring/reference-builder/<operation-id>/assets/`.
3. Produce or import a PNG whose dimensions are exactly `widthCells * 32` by `heightCells * 32`.
4. Record anchor, local collision cells, HGSS/DS style references, and alpha policy.
5. Run `scripts/asset_contract.py validate`.
6. Show the candidate at native scale and an integer zoom for approval.
7. Import it only after approval through the canonical `asset.import` or `asset.replace` action.

If image generation is available, it may produce a candidate inside that exact canvas. Generation does not grant approval and must not invent a different footprint.

## Apply one family at a time

Read [the MCP recipes](references/pokemap-mcp-recipes.md) before mutation.

For every family:

1. reopen the absolute project and query the current revision;
2. resolve resource IDs from live catalogs rather than guessing names;
3. plan against the current revision;
4. inspect the plan and required confirmation;
5. apply with a unique operation ID;
6. requery and validate;
7. render the map;
8. compare the render with the reference and the approved blueprint;
9. mark the family `verified` only after human visual acceptance.

Recommended checkpoints are surfaces, networks plus any explicit borders, structures, decorations, then navigation. Do not stack later families on a visibly rejected checkpoint.

## Safety boundaries

- Stage generated files inside the target project authoring folder, never `/tmp` or a broad allowed root.
- Do not broaden MCP access to the home directory or filesystem root.
- Back up the mutable project before the first mutation.
- Preserve unrelated project content and existing map behavior.
- Requery after any revision mismatch and rebuild the plan.
- Use the editor or Player for final visual and interaction review; structural validation alone is insufficient.

Read [the review checkpoints](references/visual-review-checkpoints.md) before claiming completion.
