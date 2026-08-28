# Visual review checkpoints

## Before mutation

Review the decoded blueprint over the reference:

- map crop and dimensions;
- central composition and viewport padding;
- forest mass, path topology, water topology, and building footprints;
- intended entrances and exits;
- unresolved or custom assets.

## Surface checkpoint

Require coherent base ground and forest masses. Reject exposed black edges, incomplete tree sides, repeated stamps that read as a grid, or a forest implemented as unrelated decoration.

## Network checkpoint

Require continuous paths, correct turns and junctions, river water rather than ocean water, and complete banks. If a border system appears without an approved border layer, remove it before continuing.

## Structure checkpoint

Check native scale, entrances, orientation, occlusion, and anchor alignment for every building, gate, bridge, torii, stair, and monument.

## Decoration checkpoint

Check density, negative space, variety, palette, and gameplay readability. Decorations may enrich the approved layout but must not move its main masses.

## Navigation checkpoint

Check collision against visible obstacles, entrance activation cells, reciprocal connections, arrival clearance, and Player-scale traversal.

## Final verdict

Automated validation and a successful render prove structural health only. Mark the blueprint verified after the user accepts the visual result and any required Player route has been exercised.
