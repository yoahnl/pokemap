# PokeMap map quality gates

## Contents

1. [Definition of success](#definition-of-success)
2. [Gate A — evidence and scale](#gate-a--evidence-and-scale)
3. [Gate B — functional topology](#gate-b--functional-topology)
4. [Gate C — composition](#gate-c--composition)
5. [Gate D — asset and layer discipline](#gate-d--asset-and-layer-discipline)
6. [Gate E — edge independence](#gate-e--edge-independence)
7. [Gate F — engine proof](#gate-f--engine-proof)
8. [Rules by map type](#rules-by-map-type)
9. [Acceptance matrix](#acceptance-matrix)

## Definition of success

A successful map:

- communicates its place and story role without labels;
- gives the player a readable entrance, route, destination, and exit;
- uses believable relative scale at the project runtime display scale;
- remains editable as native PokeMap layers and elements;
- does not depend on hidden overflow, a fixed crop, or flattened scene art;
- renders consistently in the editor and runtime;
- contains no unexplained void, placeholder, seam, or inaccessible required interaction.

Technical validity is necessary but never sufficient.

## Gate A — evidence and scale

### Required evidence

Read the supplied bibles and the project scale guide. If a scale guide is absent,
derive ratios from the approved player sprite plus at least one accepted map reference.
Record project tile dimensions and runtime display scale separately.

Never treat a 32×32 logical grid as a 32×32 detail budget. Large objects may occupy
several cells and retain richer pixel detail.

### Mandatory scale board

Before map assembly, place on one neutral, grid-off board:

1. the actual player sprite at runtime scale;
2. one standard door;
3. one seat or bed for interiors;
4. one building or tree for outdoors;
5. one rail, platform edge, or vehicle for railway maps;
6. a visible 32×32 native-cell ruler.

Pass only when:

- the player visually fits through the door;
- furniture looks usable by that player, not miniature or gigantic;
- doors across reusable buildings share one visual scale;
- rail gauge, platform furniture, and train body agree;
- the largest asset preserves the same pixel density and outline language;
- no asset was independently resized merely until it “looked okay.”

Use nearest-neighbour scaling only for intentional integer magnification. Otherwise,
replace or redraw at the required native size; do not blur pixel art.

## Gate B — functional topology

Write a graph before placing decoration:

```text
entry -> safe approach -> main decision point -> required destination -> exit
```

Add optional branches only after the required route works.

For every node, record:

- cell or area;
- required clear approach;
- interaction direction;
- occlusion expectation;
- collision footprint;
- connection to the primary entry.

Pass only when:

- every required target is reachable by four-directional movement;
- every entry/exit cell is walkable and visibly signalled;
- a door has at least one clear approach cell on each usable side;
- normal circulation is comfortably wide; one-cell passages are intentional;
- furniture collision follows ground contact, not the whole visible sprite;
- foreground occlusion never disguises a blocked route as open;
- disconnected walkable islands are either removed or explicitly justified.

## Gate C — composition

Divide the reference into named zones and estimate their proportions. Preserve the
hierarchy, not every source pixel.

Use this order:

1. map envelope and playable extents;
2. entrances/exits;
3. major paths and negative space;
4. landmarks and large masses;
5. secondary furniture/vegetation;
6. narrative props;
7. small decoration and effects.

Pass only when:

- the main landmark dominates at the intended viewing scale;
- empty space has a navigation, staging, or breathing purpose;
- repeated assets vary without becoming visual noise;
- silhouettes stay readable at native scale;
- architecture has plausible openings, corners, supports, and roof/wall relationships;
- the map still reads in a thumbnail and at player scale.

Do not compensate for weak composition by adding more props.

## Gate D — asset and layer discipline

Classify every visual need:

| Decision | Meaning |
|---|---|
| `reuse` | Existing asset fits style, scale, footprint, and use. |
| `normalize` | Existing approved source needs transparent cleanup, atlas packing, or a documented redraw at target size. |
| `gap` | No approved candidate satisfies the named need. |

Create gap art only after its target footprint and anchor are fixed. Require transparent
RGBA, no pink/chroma fringe, no baked label, dimensions compatible with project rules,
and a plain-language catalog name.

Recommended bottom-to-top layer intent:

1. base surfaces;
2. paths and transitions;
3. structural floor/wall pieces;
4. rear architecture and wall decor;
5. large furniture/landmarks;
6. small props and narrative objects;
7. foreground/occlusion pieces;
8. lighting/effects;
9. collision and gameplay overlays.

Use a placed element for a coherent object, not for an entire already-furnished map.

## Gate E — edge independence

Map bounds define gameplay extent. They are not Photoshop crop boundaries.

Fail immediately when:

- a placed element extends outside the map;
- a room-sized sprite covers all four edges;
- an oversized wall/roof is made acceptable only by viewport clipping;
- black outside space hides an unfinished or malformed boundary;
- moving the camera or increasing map size reveals stray art;
- the map is correct only at one exact crop.

### Padded-canvas test

Create a disposable proof with one transparent cell added on all four sides and all
placements shifted by one cell. Render it without changing assets.

Pass when:

- every object remains independently complete;
- wall and roof terminations are intentional;
- no hidden overflow appears;
- playable bounds remain understandable without the original crop.

This test is evidence only; do not ship the padded proof.

## Gate F — engine proof

Produce all six artifacts:

| Artifact | Purpose |
|---|---|
| Native overview | Detect seams, voids, repetition, and composition errors. |
| Scale board | Prove player-relative dimensions. |
| Collision overlay | Prove honest footprints and route continuity. |
| Padded-canvas render | Prove edge independence. |
| Actual runtime render | Detect display-scale and renderer differences. |
| Same-crop comparison | Compare reference intent and implemented hierarchy fairly. |

Use identical crop, camera, animation time, lighting, and grid state for comparisons.
A generator/Pillow preview cannot replace the editor or runtime capture.

## Rules by map type

| Map type | Additional required proof |
|---|---|
| Interior | Closed modular envelope, player-sized doors, plausible furniture, clear entrance, intentional foreground wall. |
| Village/city | Connected roads, readable public/private zones, door approaches, landmarks, vegetation that frames rather than randomly blocks. |
| Route/forest | Legible critical path, intentional loops/chokes, encounter vegetation separated from scenery logic, exits protected from clutter. |
| Station/railway | Constant rail gauge, aligned straights/curves/switches, coherent train/platform scale, safe platform circulation. |
| Cave/relief | Paths and cliff borders form continuous systems, stairs land on walkable cells, entrances remain visible and reachable. |

## Acceptance matrix

| Gate | Required result |
|---|---|
| Evidence | Brief complete; no unresolved required `TODO`. |
| Scale | Scale board approved at native and runtime scale. |
| Topology | Validator passes every required entry and target. |
| Composition | Named zones and landmark hierarchy match intent. |
| Assets | No placeholder; every gap decision documented. |
| Edge independence | No overflow/full-canvas composite; padded proof clean. |
| Engine | Editor round-trip and actual runtime render pass. |
| Visual | Every rubric axis ≥4/5 and explicit human approval. |

Any failed gate blocks completion. Record a deliberate exception with owner, scope,
reason, affected artifact, and revisit condition; never silently reinterpret failure as style.
