# Visual acceptance

## Comparable capture protocol

Record map ID, camera origin, viewport in cells, render scale, lighting preset, animation timestamp, and grid state. Compare reference/current/new side by side. A different crop, zoom, grid overlay, or light state invalidates the comparison.

## Five-axis rubric

Score every axis from 1 to 5 and require at least 4 on each:

| Axis | PASS evidence |
|---|---|
| Composition | Major masses, negative space, zones, shoreline, and landmark hierarchy match the reference intent. |
| Style coherence | Palette, pixel density, outlines, shadows, scale, and animation belong to one visual family. |
| Navigation readability | Entrances, exits, paths, hazards, interactions, and blocked cells are visually honest at player scale. |
| Place identity | The map communicates its named biome/location without editor labels. |
| Finish | No seams, debug voids, accidental overlaps, floating props, naked repeated texture, or unexplained empty staging fields. |

Human approval owns artistic acceptance. Hashes and tests prove reproducibility, not beauty.

## Reference brief checklist

- Divide the image into named zones and record their approximate proportions.
- List required landmarks, repeated families, silhouettes, foreground occluders, and narrative reservations.
- Draw the player route and protected approaches before placing scenery.
- Classify every need as reuse, normalize/import, Environment palette, or genuine new-asset gap.
- Keep the complete image and annotated sheets reference-only.

## Water family gate

Review open sea, coast/foam, isolated pools, inner/outer corners, docks/rocks, and marsh basins in context. Require opposite edges to tile and consistent frame dimensions/order/duration. Compute mean absolute RGBA pixel delta for every adjacent frame pair; require the last-to-first delta to be no greater than `max(1.5 × median(adjacent deltas), p95(adjacent deltas))`. Never approve water as a naked swatch; composite it with shore, rocks, reeds, and structures.

## Cleanup gate

The usage report must identify exact referrers and current hashes. Review `delete` entries line by line. Apply only when the manifest hash and every candidate file hash still match; rerun load/render tests and the dry run afterward.
