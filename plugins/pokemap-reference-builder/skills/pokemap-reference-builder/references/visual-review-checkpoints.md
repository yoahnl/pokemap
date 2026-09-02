# Visual review checkpoints

## Before mutation

Review the decoded blueprint over the reference:

- map crop and dimensions;
- central composition and viewport padding;
- forest mass, path topology, water topology, and building footprints;
- intended entrances and exits;
- unresolved or custom assets.

For an assisted V2 analysis, require both semantic overlays, the analysis reports, the spatial lint, and a comparison report built from same-crop reference and candidate images. Correct seed profiles when the reference overlay itself is wrong. Never compensate for a bad reference mask by degrading the candidate mask, and never substitute semantic agreement for rendered fidelity.

## Surface checkpoint

Require coherent base ground and forest masses. Reject exposed black edges, incomplete tree sides, repeated stamps that read as a grid, or a forest implemented as unrelated decoration.

## Network checkpoint

Require continuous paths, correct turns and junctions, river water rather than ocean water, and complete banks. If a border system appears without an approved border layer, remove it before continuing.

## Structure checkpoint

Check native scale, entrances, orientation, occlusion, and anchor alignment for every building, gate, bridge, torii, stair, and monument.

Reject a structure asset that bakes terrain, water or network geometry together with its props across a large repeated footprint. Split it into native terrain or Smart Tile materials plus small reusable props before continuing.

## Decoration checkpoint

Check density, negative space, variety, palette, and gameplay readability. Decorations may enrich the approved layout but must not move its main masses.

## Navigation checkpoint

Check collision against visible obstacles, entrance activation cells, reciprocal connections, arrival clearance, and Player-scale traversal.

## Final verdict

Automated validation and a successful render prove structural health only. Do not publish a V2 score without comparable image evidence. A candidate is eligible for human review only when its combined score and each visual axis reach at least 80, with no hard spatial failure. Even then, mark the blueprint verified only after the user accepts the visual result and any required Player route has been exercised.
