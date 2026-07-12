# Reference brief — `map_port_brisants`

## Evidence

- Map ID: `map_port_brisants`
- Reference role: `reference-only` (never a runtime underlay)
- Reference file: `ChatGPT Image Jun 6, 2026, 07_10_04 PM.png`
- Reference SHA-256: `25fdc9419850028a6e79787ac53dd8e34dcf457ed2d90c1126b5e9b60ecfb219`
- Dimensions: `1448×1086`
- Asset inventory: `reference_inventory.json`
- Inventory SHA-256 / count: `a9f6d61f724a79db7cf45234e4c073045299ed6067bf99280f2e170e01f03237` / 1 image
- Inventory strict result: 0 duplicate, 0 decode error, 0 warning, 0 missing provenance, 0 unapproved provenance
- Runtime candidate status: `candidate_pending_owner_approval`

## Composition zones

| Zone | Approximate bounds | Visual purpose | Traversable? | Asset decision |
|---|---|---|---|---|
| Northern wooded threshold | `x=5–44`, `y=0–8` | Forest wall, village connection and harbor-master silhouette | Yes through the protected five-cell north corridor | Environment clusters/trees plus generated architecture |
| Western rocky coast | `x=0–7`, `y=0–20` | Natural coastal boundary and strong island identity | No outside the authored land edge | Generated continuous coast, foam and small rocks |
| Residential/civic quarter | `x=7–39`, `y=3–11` | Houses, harbor master, enclosed gardens and readable hierarchy | Yes on the pavement network and door approaches | Generated normalized buildings/gardens; native `pavement_path` |
| Market and central square | `x=7–38`, `y=9–18` | Fish market, chandlery, story meeting space and nest clue | Yes; narrative zones remain clear | Generated market/props/gardens; preserved narrative anchors |
| Quays and harbor basin | `x=5–39`, `y=18–33` | Three walkable piers, boats and working-port activity | Piers yes, open sea no | Generated docks/boats/working props; animated water path |
| Eastern peninsula | `x=38–44`, `y=4–24` | Vegetal frame, shore turn and lateral visual closure | Yes only on the authored path/land | Environment tree curtain plus generated coast/foam |

## Landmarks and silhouettes

| Priority | Landmark | Approximate position | Footprint/anchor | Decision | Gameplay contract |
|---|---|---|---|---|---|
| P0 | Harbor-master building | north-center | 8×6 cells, bottom-center | Generated gap, normalized to the project grid | North connection approach stays open |
| P0 | Harbor basin and three piers | lower half | modular 12×4, 9×9 and 5×9 dock sprites | Generated gap | Piers remain walkable; surrounding sea remains blocked |
| P0 | Large fishing boat | `(0,22)` | 10×5 cells | Generated gap; preserves `pe_port_bateau` | Existing story/runtime identifier retained |
| P0 | Chandlery/hangar | `(31,11)` | 8×6 cells | Generated gap; preserves `pe_port_hangar` | Existing story/runtime identifier retained |
| P0 | Wingull nest | `(7,9)` | 2×2 cells, decorative interaction | Generated genuine narrative gap | `pe_port_nid_goelise` and `tr_port_nest` retained |
| P1 | Fish market and working props | center-west and docks | 2×2 to 8×6 cells | Generated only where the project catalog had no matching visual | No obstruction of protected routes/interactions |
| P1 | Rocky coast and foam | west/east edges | continuous coast plus modular overlays | Generated gap after legacy coast assets failed the target silhouette | Open water stays blocked; coast reads naturally |
| P1 | Forest wall | north/east | Environment-generated clusters and trees | Existing Environment workflow reused | Deterministic IDs/seeds; exit corridor excluded |

## Navigation and protected cells

- Player route: north connection → civic road → central square → three quay approaches; all anchors are connected by the native pavement mask.
- Entrances/exits/connections: north connection to `map_bourg_selbrume`, offset `0`; protected trigger area `(26,0)` size `5×4`.
- Door and warp approaches: all visible building doors retain at least one clear approach cell; this map has no warp.
- Interaction anchors: Lysa `(26,16)`, Soline `(39,10)`, fishermen `(13,17)`, nest `(7,9)`.
- Environment exclusions and buffers: no Environment placement intersects the north corridor, story zones, doors or quay approaches.
- Foreground occlusion: north/east Environment trees use backdrop/overhead target layers; architecture and docks stay in structures.
- Collision proof cells: left pier `(10,25)`, center pier `(22,27)` and right pier `(34,27)` are passable; open sea `(15,27)` is blocked.

## Asset decisions

| Visual need | Existing candidates checked | Decision | Provenance | Output/evidence | Justification |
|---|---|---|---|---|---|
| Grass | Existing project grass plus user-supplied grass image | Reuse exact owner source and build deterministic 8×8 variants | `owner_supplied_exact_asset` | Source SHA `410c9dac…8780`; ground atlas SHA `444251b7…617` | User explicitly selected this grass |
| Pavement roads | Existing `pavement_path` preset/tileset and temporary pavement copies | Reuse the native preset; delete both redundant copies | `existing_project_path_preset` | 382 active path cells; `paintAfterTileLayerId=l_tile_port_ref_base` | Keeps roads editable and avoids duplicate art |
| Architecture | Legacy Port assets and supplied visual references | Generate five isolated normalized buildings | built-in `image_gen`, user-requested derivation | Sprite atlas/provenance entry contracts | Legacy silhouettes/scale did not match the selected Port reference |
| Docks and boats | `ponton_selbrume`, legacy boat/Port atlases | Generate normalized dock and fishing-boat family | built-in `image_gen`, user-requested derivation | Sprite atlas/provenance entry contracts | Genuine visual gap for the working harbor composition |
| Forest/gardens | Existing Environment system and supplied visual references | Generate only missing tree/cluster/garden visuals; place forest through Environment | built-in `image_gen`; deterministic Environment | 11 generated Environment placements | Reuses project authoring workflow instead of hand-placing the forest wall |
| Coast/foam/rocks | Legacy coast assets and early modular candidates | Generate continuous natural coast, foam overlays and small rocks | built-in `image_gen`, user-requested derivation | Sprite atlas/provenance entry contracts | Needed to match the natural rocky shoreline requested by the owner |
| Small working-port props/nest | Existing general props and narrative contract | Generate compact harbor-specific gaps only | built-in `image_gen`, user-requested derivation | Sprite atlas/provenance entry contracts | Required density and the reserved nest clue were absent |
| Water | Existing open-sea family and the rejected first Port animation | Deterministic Port-specific animated path atlas | procedural pixel art, same accepted palette | Water atlas SHA `61399414…56f6` | Owner requested a more organic animation without changing the color |

The generated source sheets, exact hashes, prompt briefs/summaries, alpha-removal method and normalized atlas rectangles are recorded in `selbrume/assets/provenance/selbrume_port_reference_v3.json`.

## Environment plan

| Layer/area | Target layer | Preset | Seed | Eligible cells | Protected mask | Result |
|---|---|---|---:|---:|---|---|
| `env_port_ref_clusters` | `l_tile_port_ref_backdrop` | `env_selbrume_port_clusters_v3` | 1347375700 | 4 | north corridor/buildings/story zones | 4 stable cluster placements |
| `env_port_ref_north_trees` | `l_tile_port_ref_backdrop` | `env_selbrume_port_trees_v3` | 1347375701 | 3 | north corridor/buildings/story zones | 3 stable tree placements |
| `env_port_ref_east_trees` | `l_tile_port_ref_overhead` | `env_selbrume_port_trees_v3` | 1347375702 | 4 | east route/coast/quay approach | 4 stable tree placements |

Two consecutive generations and a clean `--check` produce byte-identical map/project outputs and the same 11 generated placement IDs.

## Water contract

- Contexts present: open sea, rocky coast, foam, rocks, docks, boat wake and walkable pier underlay; no marsh or isolated pool is required on this map.
- Animation: 8 frames, 256×256 px (8×8 cells) per frame, 180 ms per frame, 1.44 s loop.
- Motion: persistent broken curved wavelets, progressive crest brightness, restrained darker underside and at most one-pixel local drift; the base texture never scrolls globally.
- Palette: accepted blue base retained; only layered dark/mid/bright ripple values were added.
- Spatial loop: first/last columns and rows match exactly for every frame.
- Temporal evidence: all eight adjacent transitions, including frame 7→0, are non-zero and remain below mean-delta 1; diagonal-crest and crest-shadow regression gates pass.
- Context composite: overview capture includes water against both coasts, all docks, three boats, rocks and foam.

## Technical preservation

- Preserved: 3 entities, 4 triggers, 2 gameplay zones, no event/warp additions, north connection to `map_bourg_selbrume`.
- Preserved IDs: `pe_port_bateau`, `pe_port_hangar`, `pe_port_nid_goelise`, `zone_port_entry`, `zone_port_center`, `tr_port_rival_scene`, `tr_port_nest`.
- Layer model: 11 native layers; editable pavement and animated water are `PathLayer`s, forest massing is authored through `EnvironmentLayer`s, visuals remain project elements/tile layers.
- Reference image: hash-locked evidence only; `runtimeUnderlay=false`.
- Real round-trip: `FileProjectRepository`, `FileMapRepository` and `EditorNotifier` load/save/reload all ten maps and retain all 722 placements.
- Validation: generator write/check, model validation, collision/navigation contracts, atlas decode/dimensions, runtime render and deterministic rebuild tests.

## Comparable capture set

| Capture | Viewport | Scale | Lighting/time | Grid | SHA-256 / comparison |
|---|---|---:|---|---|---|
| Overview | full 45×34 map, 1440×1088 | 32 px/cell | neutral, animation frame 0 | off | `4d1bc78e…d57e`; reference/current composition |
| Collision | same full-map viewport | 32 px/cell | neutral, animation frame 0 | off | `b502df85…5939`; traversal and blocking |
| Water loop | 256×256 source enlarged to 512×512 | 2× nearest-neighbor | 8 frames × 180 ms | n/a | `7c093940…a5a`; motion, palette and loop |

The three reviewed artifacts are durable evidence in this directory:

- `map_port_brisants_overview.png`;
- `map_port_brisants_collision.png`;
- `water_organic.gif`.

The deterministic capture harness can reproduce the two full-map images; the GIF is a nearest-neighbor QA presentation of the eight-frame runtime atlas.

## Visual review

| Axis | Score (1–5) | Evidence / remaining deviation |
|---|---:|---|
| Composition | 3.5/5 strict | Major target zones are present; the protected reciprocal north connection remains centered instead of moving north-east |
| Style coherence | 4.5/5 | Unified pixel-art palette, scale and outlines across architecture, props, coast and vegetation |
| Navigation readability | 4.2/5 | Native pavement clearly links entry, square, buildings and all quay approaches |
| Place identity | 4.5/5 | Harbor master, working docks, boats, fish market, rocky coast and forest wall read immediately |
| Finish | 4.0/5 | Natural coast, layered foam, dense props, deterministic Environment and organic water loop are present |

The owner explicitly approved the overall visual direction before the final native-pavement and organic-water adjustments. The runtime candidate intentionally remains `candidate_pending_owner_approval` until the final capture is approved; the strict reference-composition gate is not claimed as a perfect reproduction.
