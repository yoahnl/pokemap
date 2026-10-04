# Visual review checkpoints

## Before mutation

Review the decoded blueprint over the reference:

- map crop and dimensions;
- central composition and viewport padding;
- forest mass, path topology, water topology, and building footprints;
- intended entrances and exits;
- terrain contacts, level transitions, module junctions and reserved approach spaces;
- unresolved or custom assets.

For an assisted V2 analysis, require both semantic overlays, the analysis reports, the spatial lint, and a comparison report built from same-crop reference and candidate images. Correct seed profiles when the reference overlay itself is wrong. Never compensate for a bad reference mask by degrading the candidate mask, and never substitute semantic agreement for rendered fidelity.

## Surface checkpoint

Require coherent base ground and forest masses. Reject exposed black edges, incomplete forest closures and a forest implemented as unrelated decoration. Compare spacing and repetition with the approved reference and vegetation role: regular background forests, gardens and crops may be intentional; an unintended stamp grid needs repair.

Check ground support separately from the visible canopy. Review forest-body, edge and isolated-tree modules by their role; a lower closure cannot stand in for a complete tree. An overhang above water is not proof that the trunk stands in water. Hidden contact remains unknown.

For relief, inspect the plateau contour, side/front faces, concave/convex corners and feet within the same material and visual height. Check that openings are deliberate and each stair meets clear upper/lower landings. Draw priority is not physical height.

## Network checkpoint

Require continuous paths, correct turns and junctions, river water rather than ocean water, and complete banks. If a border system appears without an approved border layer, remove it before continuing.

At a waterfall, compare upstream water, crest, falling surface and receiving water at each contact, including width and cliff opening. A static image does not verify flow animation or Waterfall/Surf behavior.

## Structure checkpoint

Check native scale, entrances, orientation, occlusion, and anchor alignment for every building, gate, bridge, torii, stair, and monument.

For a crossing bridge, check two landings, both cap rows, repeatable deck/side pieces and the intended route, while preserving water below. For a dock, check one land attachment and a closed water end. Review elevated supports and draw depth separately from screen-space bounds; use the [assembly contract](exterior-layer-model.md#placement-and-assembly-contract) and its source examples.

Reject a structure asset that bakes terrain, water or network geometry together with its props across a large repeated footprint. Split it into native terrain or Smart Tile materials plus small reusable props before continuing.

## Decoration checkpoint

Check density, negative space, variety, palette, and gameplay readability. Decorations may enrich the approved layout but must not move its main masses.

Check the actual support and contact variant for each object, especially aquatic rocks/plants. Preserve entrances, landings and useful open spaces. Do not scatter extra props just to fill a lake, plateau or clearing. Explain any deliberate biome or support exception using the selected asset and project intent.

## Navigation checkpoint

Check collision against visible obstacles, entrance activation cells, reciprocal connections, arrival clearance, and Player-scale traversal.
Verify the required endpoint routes and both approaches to stairs/bridges, plus a dock's declared walkable end. Component counts, source passage bits and tile IDs alone do not establish those routes. Use the actual footprint and movement conditions; unknown cells are not guaranteed walkable.
For every visible room entrance, identify its exact 32 px doorway cell and the approach cell on each side. Overlay the collision grid on the native render: the doorway must be open, the neighboring wall cells must remain blocked, and the opening must coincide with the artwork rather than an invisible gap elsewhere. Walk the actual player from the map entry through the opening into the room and back out; verify any door or curtain animation on both crossings. A grid flood-fill or a successful step from a freshly spawned adjacent cell does not prove that the real approach works. Treat any blocked doorway or route through a visible wall as a failed checkpoint, even after artistic approval.

## Final verdict

Automated validation and a successful render prove structural health only. Do not publish a V2 score without comparable image evidence. A candidate is eligible for human review only when its combined score and each visual axis reach at least 80, with no hard spatial failure. Even then, mark the blueprint verified only after the user accepts the visual result and any required Player route has been exercised.

State which placement/contact checks were inspected manually and which existing tools actually executed. `blueprint_quality.py` tests overlap using full geometry; it cannot distinguish ground support from canopy overhang and does not use `allowsWater`. Keep ambiguous conflicts unresolved rather than hiding them, bypassing hard gates or claiming automatic support certification. The bundled corpus rules' `machineCheckable` label describes a research candidate, not an implemented check. Qualitative annotations and source-native examples do not certify all maps or turn proposed metadata into supported native fields.

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
