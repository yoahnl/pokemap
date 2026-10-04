# Exterior layer model

## Coordinate contract

- Origin is the top-left map cell.
- `x` increases to the right and `y` increases downward.
- Every map and asset cell is 32 px.
- Geometry must remain inside `[0, widthCells)` and `[0, heightCells)`.
- A placement origin is the top-left cell of its footprint.
- An asset anchor is expressed in local cells inside its footprint.

## Families

### Surface

Large natural masses: base ground, meadow, forest coverage, sand, snow, or other area semantics. Forest is a surface-level intent even when Environment Studio produces individual tree placements.

### Network

Connected topology: roads, paths, rivers, stairs, rails, bridges, and junctions. Preserve centerlines, widths, endpoints, crossings, and connections before choosing tiles.

For a river, set `constraints.waterBodyType` to `river`. Bind only a river preset or material whose live catalog and source provenance confirm river water and banks.

### Border

An explicit edge system such as a fence, wall, cliff line, or approved decorative border. A layer cannot advance beyond `proposed` without `constraints.explicitApproval: true`.

Do not use this family merely because a surface or network needs a visual edge. Prefer the canonical surface or Smart Tile transition when it owns that edge.

### Structure

Buildings, gates, shrines, torii, bridges, monuments, platforms, and other authored multi-cell objects. Record footprint, entrance cell, occlusion expectations, and anchor.

### Decoration

Trees, bushes, rocks, flowers, lamps, signs, mailboxes, stumps, and small props. Decorations must not repair incorrect surface or network geometry.

### Navigation

Collision, traversal zones, entrances, exits, connections, and behaviors. Navigation follows the accepted visual layout and must not be used to disguise a wrong footprint.

## Statuses

- `proposed`: decoded from the reference but not approved.
- `approved`: geometry and binding choice accepted for mutation.
- `applied`: canonical PokeMap receipt confirms the mutation.
- `verified`: validation, render, and required human review passed.

Approved and later layers require at least one concrete binding. Resource IDs must come from the current PokeMap catalog.

## Geometry forms

- `cells`: explicit cell set for masks and painted regions.
- `polygon`: closed area outline, later rasterized or masked.
- `polyline`: ordered network centerline.
- `placement`: origin and footprint for one structure or prop.
- `connection`: endpoint pair and traversal metadata.

Prefer the smallest semantic geometry that preserves intent. Do not expand every polygon into thousands of cells during visual decoding if the target action accepts a mask or area.

## Placement and assembly contract

Choose an asset's role before judging its placement. Separate its contact with the ground, the cells requiring support, its visible extent, its collision and its draw order. A canopy, roof or elevated bridge can overhang another region while its actual support remains elsewhere. Validate every known support cell against the permitted material and intended level; one valid anchor does not prove the whole footprint fits. If support is hidden or undeclared, keep the verdict unknown rather than inventing a footprint.

Terrain level is a design annotation until a current native contract expresses it. Source layer and draw priority describe rendering, not physical elevation. Water appearance, terrain tags, movement conditions and collision are different evidence. A zero terrain tag does not establish dry ground.

Use the following decisions as the plugin's review procedure. Their visual examples are qualitative observations, not universally measured laws. The [portable knowledge reference](map-assembly-patterns.json) preserves exceptions, confidence, provenance and counterexamples. Its proposed annotation names are not native PokeMap schema fields.

| Pattern | Placement decision | Exception or missing evidence | Native example |
|---|---|---|---|
| `SUPPORT` | Check every known ground-support cell against the asset's compatible material and level. A terrestrial trunk cannot take root in open water. | Sand-compatible palms and aquatic plants have different support requirements. Hidden contact stays unknown. | `TREE-12`, `WATER-ROCK-21` |
| `OCCLUSION` | Place by ground contact, then review canopy, roof and shadow overhang and draw order. | Visible overlap alone does not establish a support or collision conflict. Canopy/building overlap still needs visual review. | `TREE-12` |
| `RELIEF` | Define plateau regions and intended levels first; derive exposed rims, sides, front faces and feet from their contour. | A cropped upper region can remain unknown. Source priority is not height. | `CLIFF-140` |
| `CORNER` | Match straight edges, concave and convex corners, faces and feet within one compatible material and visual height. Inspect every junction. | A rotated sprite or a corner from another family may not have the needed perspective. | `CLIFF-140` |
| `STAIR` | Reserve an opening in the contour; align stair width and orientation, then keep both upper and lower landings clear. | A decorative stair or a destination outside the capture does not prove traversal. | `STAIR-140` |
| `CASCADE` | Join upper water, crest, falling surface, cliff opening and lower receiving water; compare widths and contact pixels. | A decorative fountain has another recipe. Frame zero does not prove animation or field-move behavior. | `CASCADE-100` |
| `BRIDGE` | For a crossing, connect two compatible landings with end caps, deck and side pieces. Preserve the water below and declare the intended route. | Branches, piers and elevated supports need their own support/depth model. A screen rectangle is not a ground-support mask. | `BRIDGE-97` |
| `DOCK` | Attach one end to land and close the other deliberately in water; define the walkable deck and its end. | Do not force a second bank. A boat or fishing interaction is not implied by the image. | `DOCK-21` |
| `MODULE` | Identify compatible connection ends, corners, repeatable pieces and end caps before decoration. | A module or collection is not necessarily a complete placeable object. | `CLIFF-140`, `BRIDGE-97`, `DOCK-21` |
| `VEGETATION` | Choose background mass, edge, isolated tree, garden or crop role; form the contour and closures before density and variation. | Dense regular background trees, gardens and crops can be intentional. A lower forest closure is not an isolated tree. | `TREE-12` |
| `CLEARANCE` | Reserve required entrance approaches, spawn/arrival spaces, landings and routes before placing blockers. Use the actual player footprint and movement conditions. | Decorative buildings and deliberate story blockers need declared intent. Unknown behavior remains unknown; no universal two-cell width. | `STAIR-140`, `BRIDGE-97`, `DOCK-21` |
| `WATER_OBJECT` | Select an emerged, floating, submerged or shoreline variant with the right contact treatment. | Neither all rocks nor all vegetation share one water rule. A land rock is not automatically a water rock. | `WATER-ROCK-21` |
| `BIOME` | Match support material and plant/rock family to the requested region, and review transitions. | Story, style and specific assets can justify exceptions; do not invent a universal climate rule. | — |
| `COMPOSITION` | Keep intended open spaces and useful approaches around landmarks; decorate after proportions and circulation are accepted. | Open sea, broad plateaus and deliberate crowded scenes need no automatic filling quota. | — |
| `INTENT` | Record what is known, inferred and deliberately exceptional before judging a contact or route. | Demo props, cropped areas and missing events do not establish a best practice or a playable map. | — |

### Read an example without importing it

Each `nativeAssemblies` entry uses zero-based 32 px map cells and source layers 0–2. `contextRegionCells` and `focusRegionCells` are `[x, y, width, height]`; `focusLayers` rows start at the focus origin. `sourceCell` identifies one checked tile, and `focusAssetTrace` links the excerpt's nonzero IDs through `nativePack.assetSources` to source hashes and atlas rectangles or autotile quarters.

The seven examples are source observations, not executable templates. `TREE-12` is the southern closure of a forest mass, not a complete isolated tree. The pack has no events; source priorities, passage bits and terrain tags do not certify PokeMap collisions, physical height, door behavior or Player traversal. All source IDs must be replaced with reviewed live bindings during actual authoring. The source artwork and complete maps are not bundled, and the examples do not change the skill's asset provenance gates.

### Build and review in order

1. Define terrain regions, intended levels, required entrances/exits and their access reservations.
2. Assemble contours, oriented corners, faces, feet and intentional openings.
3. Connect water, stairs, bridges, docks and waterfalls with their distinct landing/contact requirements.
4. Place buildings and vegetation masses from known anchors/supports; close their boundaries and preserve access reservations.
5. Add secondary decoration on compatible support without filling intentional open space by default.
6. Review junctions at native scale, then validate navigation with the actual movement scenario and Player routes.

The present blueprint lint rasterizes full placement rectangles and semantic masks. It does not check a separate ground-support footprint, and network component counts do not establish useful endpoint access. Treat these as diagnostic limits; never relabel masks to hide a conflict or call missing support/landing checks passed.
