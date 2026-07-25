# Visual acceptance

## Comparable capture protocol

Record map ID, camera origin, viewport in cells, native cell size, runtime display scale,
lighting preset, animation timestamp, and grid state. Compare reference/current/candidate
at the same crop and apparent scale. Different framing invalidates the comparison.

Treat the reference as a comparison of intentions unless exact reproduction was
explicitly requested. Compare zoning, proportions, circulation, hierarchy, palette,
materials, density, and place identity. Do not penalize a deliberate layout change
that improves playability or modular authoring while preserving those intentions.

Always inspect:

1. native grid-off overview;
2. player-scale crop containing a door and representative prop;
3. collision overlay;
4. one-cell padded-canvas proof;
5. actual runtime render;
6. reference/candidate side-by-side.

## Seven-axis rubric

Score every axis from 1 to 5. Require at least 4 on every axis:

| Axis | PASS evidence |
|---|---|
| Composition | Major masses, negative space, zones, and landmark hierarchy communicate the reference intent without requiring pixel-identical placement. |
| Scale coherence | Player, doors, furniture, buildings, vegetation, rails, and vehicles belong to one believable scale system. |
| Style coherence | Palette, pixel density, outlines, material rendering, shadows, and perspective form one visual family. |
| Navigation readability | Entrances, exits, paths, hazards, interactions, and blocked cells are visually honest at player scale. |
| Place identity | The map communicates its named room, town, biome, station, or route without editor labels. |
| Edge independence | No object relies on clipping, no full-map composite replaces normal authoring, and the padded proof is clean. |
| Finish | No seam, debug void, placeholder, accidental overlap, floating prop, naked repeated texture, or unexplained empty staging field. |

Human approval owns artistic acceptance. Tests prove structure and reproducibility, not
beauty. Approval does not automatically waive a failed technical gate.

## Immediate rejection conditions

Reject and rebuild the affected layer when any condition is true:

- a complete reference image appears in runtime data;
- a placed element spans all four map edges without an approved backdrop exception;
- any placement lies outside map bounds;
- the room or scenery works only because the viewport crops it;
- the player cannot plausibly use a door, bed, seat, platform, rail, or vehicle;
- required destinations are unreachable;
- a script preview looks correct but the actual runtime differs;
- black space or an oversized sprite hides unfinished geometry;
- visible art contains magenta/pink chroma fringe or an opaque fake transparency field;
- tile IDs select adjacent atlas cells because empty tile `0` was misinterpreted.

## Scale review

Review the scale board before the map. Check the project scale guide first. If no guide
exists, measure approved reference ratios and document the calculation.

At minimum compare:

- player height against standard door clear height;
- player width against a one-cell passage;
- player against seat, bed, counter, and table;
- player against building entrance and facade;
- player/train/platform and rail gauge for railway maps;
- player/tree trunk/canopy for outdoors.

Do not approve an asset merely because its file dimensions are multiples of the grid.

## Composition review

Describe the map in one sentence before looking at labels. If the sentence does not match
its story role, place identity failed.

Trace the required route with a finger at native scale. If it requires guessing, passes
behind apparently solid art, or disappears into decoration, navigation readability failed.

Blur or thumbnail the image mentally: the main landmark and route should remain distinct.
If small clutter becomes the only hierarchy, composition failed.

## Asset review

Inspect transparent edges on both dark and light neutral backgrounds. Require:

- independently complete silhouette;
- stable anchor and footprint;
- no clipped shadow or antialias halo;
- consistent pixel density;
- no baked text unless explicitly required;
- catalog name that states the object, not `atlas_01`, `asset_12`, or a generation label.

## Water family gate

When water is in scope, review open water, coast/foam, isolated pools, inner/outer corners,
docks/rocks, and marsh basins in context. Require opposite edges to tile and consistent
frame dimensions/order/duration. Check the last-to-first animation transition. Never
approve water as a naked swatch; composite it with its real shore context.

## Cleanup gate

The usage report must identify exact referrers and hashes. Review deletion candidates
line by line. Apply only when manifest and candidate hashes still match, then rerun project
load, render checks, and the dry run. Cleanup is a separate authorized operation.
