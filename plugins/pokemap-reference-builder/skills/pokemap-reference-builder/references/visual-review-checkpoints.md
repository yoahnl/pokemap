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
For every visible room entrance, identify its exact 32 px doorway cell and the approach cell on each side. Overlay the collision grid on the native render: the doorway must be open, the neighboring wall cells must remain blocked, and the opening must coincide with the artwork rather than an invisible gap elsewhere. Walk the actual player from the map entry through the opening into the room and back out; verify any door or curtain animation on both crossings. A grid flood-fill or a successful step from a freshly spawned adjacent cell does not prove that the real approach works. Treat any blocked doorway or route through a visible wall as a failed checkpoint, even after artistic approval.

## Final verdict

Automated validation and a successful render prove structural health only. Do not publish a V2 score without comparable image evidence. A candidate is eligible for human review only when its combined score and each visual axis reach at least 80, with no hard spatial failure. Even then, mark the blueprint verified only after the user accepts the visual result and any required Player route has been exercised.

## Interior floor-and-wall HTML prototype

Use this mode when the owner wants to judge an interior's dimensions, floors, walls, and openings before changing a PokeMap project. Keep the output in an HTML artifact outside the game project. Do not run the exterior blueprint pipeline or treat a prototype screenshot as Player proof.

### Measure before drawing

1. Inspect the supplied reference and the current render at a common apparent scale. Verify the current render belongs to the current map revision if it is used for diagnosis.
2. Mark the useful reference bounds, map width and height in 32 px cells, source pixels per cell, and entrance axis. Do not stretch one axis to hide a mismatch.
3. Trace independent masks for the main floor, any secondary floor such as a storeroom, north and side walls, low south wall, thresholds, windows, and openings. Record wall height, seam and corner geometry, palette samples, and texture rhythm separately.
4. Sample clean material patches rather than objects or shadows. Compare median color and dark/light distribution, then inspect the material at native scale. A matching median cannot compensate for flat planks, tiled-looking repetition, or the wrong perspective.

### Build a reviewable shell

- Use a canvas sized `mapWidth * 32` by `mapHeight * 32`, shown beside the reference. The reference image may appear in the comparison panel but must not be the candidate background.
- Draw the main floor as a repeatable path-like material and each secondary floor as a separate mask. A reserve floor must meet the foot of its wall; clip its tile pattern to its own bounds so no row escapes beneath the border.
- Build north, side, partition, and south walls as conceptually separate modules with joined corners and intentional terminations. Align ceiling supports with partitions. Keep the south wall visibly lower than the north wall and interrupt it for the entrance.
- Treat windows, shutters, and door openings as architectural pieces. Keep furniture, characters, collisions, and decorative props out of this pass unless the owner explicitly includes them.
- For pixel art, draw crisp at native size with a small measured color ramp. Vary plank lengths and joints without a conspicuous repeating grid; give stone a restrained grain rather than identical flat squares. Use shadows only where surfaces contact a wall or threshold.
- Add controls for complete shell, floors only, walls only, and the 32 px grid. Capture a grid-off overview and inspect wall/floor joints at native scale in a real browser.

### Review boundary

Correct the shell before adding objects. Compare room dimensions, the amount of visible floor, wall heights, secondary-floor contact, entrance width, palette, and texture against the reference. Record what was reused and what was redrawn. A user-approved HTML shell is approval of the visual direction, not evidence that the map was integrated, walkable, or rendered identically in Studio and Player.

After shell approval, the next independent pass measures major objects: source bounds, target cell footprint, anchor, perspective, category, wall contact, and access from the entrance. Show those on a separate overlay or HTML revision before native implementation. Preserve the approved shell while doing so.

The Coopérative d’Aohara pass illustrates the gate: 22 × 17 native cells were compared with a roughly 64 px-per-cell reference. The parquet, gray reserve, north wall, side returns, low south wall, and entrance were reviewed without furniture. Feedback caught a reserve tile row escaping its border, a floor that did not begin at the wall, disconnected wall joints, and an overly regular parquet. The corrected HTML shell was accepted before any game-project mutation.
