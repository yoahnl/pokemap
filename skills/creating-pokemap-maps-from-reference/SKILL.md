---
name: creating-pokemap-maps-from-reference
description: Use when authoring or rebuilding an editable PokeMap map from a supplied screenshot, concept image, full-map render, or visual reference, especially when existing assets must be reused before creating new raster art.
---

# Creating PokeMap Maps From Reference

## Overview

Translate visual intent, not pixels. The result must remain native PokeMap data: editable layers, paths, Environment areas, placed elements, collisions, events, and project-owned assets.

## Non-negotiable gates

- Treat the complete reference image as `reference-only`; never ship it as an underlay or flattened map.
- Inventory hashes, dimensions, alpha usage, duplicates, provenance, and current usage before creating or importing an asset.
- Create raster art only for a named visual gap that no approved project asset can fill. Record source/prompt, hash, license/provenance, footprint, anchor, and collision intent.
- Use Environment for repeated natural masses. Keep landmarks, paths, door approaches, warps, connections, and safety buffers outside its masks.
- Never approve a map from JSON counts alone. Compare grid-off captures at identical viewport, scale, lighting, and animation time.
- Delete assets only from a reviewed usage manifest, then apply the exact hash-locked manifest.

## Workflow

1. Run `scripts/inventory_assets.py` on project and candidate roots. Read `references/pokemap-contract.md` before touching map data.
2. Run `scripts/create_reference_brief.py`. Annotate zones, landmarks, traversable routes, occlusion, water contexts, Environment candidates, and protected cells.
3. Match each visual need to an existing approved element. Write an explicit gap list; generate or normalize only those gaps.
4. Implement deterministically in a generator or focused authoring tool. Preserve gameplay contracts and mark placement origins (`authored`, `tile_index`, `environment`).
5. Build repeated vegetation through persisted Environment presets, masks, and seeds. Regenerate twice and require identical placement IDs, elements, and positions.
6. Treat water as one family: open-sea animation, coast/foam transitions, and marsh water. Test seams and the last-to-first animation transition.
7. Validate through the real editor session (`loadMap -> edit unrelated field -> saveActiveMap -> reload`), runtime loading, collisions, traversal, and two-pass rendering.
8. Score the result with `references/visual-acceptance.md`. Iterate on the largest mismatch; do not hide failures behind technical green.
9. Run `scripts/audit_project_asset_usage.py --dry-run`. Review every deletion candidate before hash-locked apply.

## Quick commands

```bash
python3 skills/creating-pokemap-maps-from-reference/scripts/inventory_assets.py --root <assets> --output <inventory.json> --provenance <provenance.json> --require-approved-provenance --strict
python3 skills/creating-pokemap-maps-from-reference/scripts/create_reference_brief.py --reference <map.png> --map-id <id> --output <brief.md>
python3 skills/creating-pokemap-maps-from-reference/scripts/audit_project_asset_usage.py --project-root <project> --dry-run --manifest <usage.json> --test-root <tests> --reference-root <retained-references>
python3 skills/creating-pokemap-maps-from-reference/scripts/audit_project_asset_usage.py --project-root <project> --apply --manifest <usage.json> --expected-sha256 <reviewed-hash> --test-root <tests> --reference-root <retained-references>
python3 -m unittest skills/creating-pokemap-maps-from-reference/scripts/test_scripts.py -v
```

Stop when provenance, editor losslessness, navigation, or visual review is unresolved. Report the blocker instead of flattening the reference or deleting uncertain files.
