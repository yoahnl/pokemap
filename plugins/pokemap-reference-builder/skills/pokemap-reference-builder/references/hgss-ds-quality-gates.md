# HGSS/DS quality gates

## Provenance

Accept only:

- `hgss_ds` for an asset traced to the Nintendo DS/HGSS PSDK source set;
- `custom_hgss_compatible` for a newly authored asset reviewed against named HGSS/DS references.

Reject GBA, FireRed/LeafGreen, Ruby/Sapphire/Emerald, ambiguous internet sheets, and mixed sheets without per-resource provenance.

The local PSDK visual oracle is `Data/Tiled` in the configured Pokémon SDK test project. Inspect actual source cells and metadata; filenames or palette resemblance alone are not proof.

## Grid and raster

- Logical cell: 32 × 32 px.
- Asset canvas: integer cell footprint multiplied by 32.
- No fractional resampling.
- Nearest-neighbor only for an explicitly approved integer enlargement.
- Preserve crisp alpha edges; do not bake checkerboards, guide colors, grid lines, or debug backgrounds.
- Shadows use real alpha transparency, not opaque gray rectangles.
- Do not ship unused giant atlases as one placeable asset.

## Visual coherence

Match the selected HGSS/DS references for:

- palette temperature and saturation;
- outline contrast;
- top-down projection and roof perspective;
- light direction;
- shadow softness and opacity;
- pixel density per 32 px cell;
- footprint and entrance scale relative to the Player.

Custom work may add new architecture or props, but it must look native beside the selected source assets at 100% scale.

## Exterior-specific checks

- Forests form coherent masses with complete lateral tree pieces and no black viewport edges.
- Paths have continuous, correctly oriented transitions and plausible junction widths.
- Rivers use river interiors and banks; ocean tiles are invalid for rivers and ponds unless explicitly requested.
- Water edges close cleanly at convex and concave corners.
- Torii, buildings, doors, bridges, and stairs use believable DS-scale footprints.
- No Smart Border is allowed unless a dedicated border layer was approved.

## Approval views

Show assets at native 100% scale and at an integer zoom with smoothing disabled. Show map checkpoints both without editor grid obstruction and, when useful, with the 32 px grid for alignment review.
