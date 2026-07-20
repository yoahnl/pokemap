# Provenance des assets Selbrume

## Statut de publication

Inventaire établi le 2026-07-11 sur les 35 fichiers présents dans `selbrume/assets/tilesets/`. Aucun auteur, générateur, modèle, dépôt source, contrat de licence ou permission de redistribution n'est documenté pour ces sources préexistantes. Pour chaque ligne existante, les cellules `source references` et `license status` conservent donc littéralement les mentions exigées par le plan. La publication bêta publique reste bloquée tant qu'une preuve vérifiable n'est pas attachée.

Les rôles sont des classifications fonctionnelles internes et ne constituent pas une attribution. `objectif*` et `route_1*` restent strictement `reference-only` et ne peuvent pas devenir des underlays canoniques.

## Kit Border Studio — falaise Selbrume à deux étages V2

- Date : `2026-07-18`.
- Statut : `approved` pour l'usage projet ; intention de collision
  `visual_only_no_collision`.
- Générateur : workflow built-in `imagegen`; le modèle exact n'est pas exposé
  par l'outil et n'est donc pas inventé.
- Références visuelles : `cliff.png` et le crop vertical de la côte de la carte
  objectif, utilisés uniquement pour le langage de pierre, l'échelle, les deux
  étages et la lumière haut-gauche. Aucun pixel de carte n'est utilisé comme
  underlay.
- Planche brute active : `raw-two-tier-sheet-v4.png`, SHA-256
  `a03924a707298ef86cb164f207b58794b9a9e23a7f5dcd62a79d3113ef999f63`;
  elle contient exactement 24 composants 4-connexes à la tolérance chroma 48.
- Transformations déterministes : flood-fill du fond `#FF00FF`, tri 4×6 par
  centroïdes, trim, quantification nearest-colour vers huit couleurs, alpha
  binaire, normalisation de tons par rôle, mise aux bounds/anchors cardinaux,
  padding 32×32 et assemblage atlas 6×4.
- Sources finales : les 24 PNG sous
  `assets/sources/border_studio/two_tier_cliff_v2/`; les hashes, bounds,
  anchors, orientations et ratios de tons individuels sont dans
  `assets/provenance/selbrume_two_tier_cliff_v2.json`.
- Atlas final : `assets/tilesets/falaises_selbrume_deux_etages_v2.png`,
  SHA-256
  `93077ce9e26c7d867493f0baf0bd2e4ce90816f8760fdf8f6846279f8d5a3471`.
- Manifeste de provenance : SHA-256
  `3dc614d1736393ba3cedd34057a1bd014a3b8a0bfe88de7361578bd96bc0ddc1`.
- Licence déclarée pour les sorties générées :
  `project-owned generated asset`. Cette déclaration ne modifie pas le statut
  non vérifié des 35 sources préexistantes inventoriées ci-dessous.

## Sources préexistantes — inventaire exhaustif (35)

| relative path | role | author/generator | tool/model | date | source references | license status | transformations | sha256 |
|---|---|---|---|---|---|---|---|---|
| `selbrume/assets/tilesets/arbre_pixellab.png` | legacy vegetation or ground-cover reference | not documented | not documented | not documented | source: pre-existing repository; origin not documented | license status: unverified | none documented | `65f21fa7c2b5445f914c6eb4340da40236e418757e2dff49509a7540cc52ee11` |
| `selbrume/assets/tilesets/bateau_selbrume.png` | exact local source for planned transparent padding to selbrume_boat.png | not documented | not documented | not documented | source: pre-existing repository; origin not documented | license status: unverified | none documented | `465b20078cefb5cfbcd1347d0891e51275977930ae18952b2c3f824a81104678` |
| `selbrume/assets/tilesets/beach_tile.png` | legacy water or shoreline surface reference | not documented | not documented | not documented | source: pre-existing repository; origin not documented | license status: unverified | none documented | `d0f6e413e66a87bf5703c054dd44bbc1e0bca83b9c8b6ffb2653cb738edc1b16` |
| `selbrume/assets/tilesets/beach_wave.jpg` | legacy water or shoreline surface reference | not documented | not documented | not documented | source: pre-existing repository; origin not documented | license status: unverified | none documented | `b7836ea35ecbcf9135686c28008e15d91d1c29c563338d7dda8ea0d6ba62c2c7` |
| `selbrume/assets/tilesets/big_water_rock.png` | legacy water or shoreline surface reference | not documented | not documented | not documented | source: pre-existing repository; origin not documented | license status: unverified | none documented | `6da9ebead677728305f6cb4b1c17c122cdd89ed6862bd3828f308fd670b7f4d1` |
| `selbrume/assets/tilesets/bosquet_fleurs.png` | legacy vegetation or ground-cover reference | not documented | not documented | not documented | source: pre-existing repository; origin not documented | license status: unverified | none documented | `bf3bdc5bee1491ec58bdfaf77603ada10906859f5ae63540d9c0edbf56bc36b2` |
| `selbrume/assets/tilesets/cliff.png` | legacy rock, cliff or coastal-material reference | not documented | not documented | not documented | source: pre-existing repository; origin not documented | license status: unverified | none documented | `5ec4a402e7a8dffa69b70d7358a6863f7598811218e102e18fe31387733cab53` |
| `selbrume/assets/tilesets/deep_water.png` | legacy water or shoreline surface reference | not documented | not documented | not documented | source: pre-existing repository; origin not documented | license status: unverified | none documented | `c58861c764958e995876dcab10d18d09575c6c175cb1a14d70970f00486f9e0a` |
| `selbrume/assets/tilesets/dirt_path.png` | legacy path or pavement reference | not documented | not documented | not documented | source: pre-existing repository; origin not documented | license status: unverified | none documented | `92338102be7f8db43581f6bbceeb74d88cf412da473035638dec33ae0233d2ff` |
| `selbrume/assets/tilesets/fleurs_elements.png` | legacy vegetation or ground-cover reference | not documented | not documented | not documented | source: pre-existing repository; origin not documented | license status: unverified | none documented | `274b45817e28167bae23a4f9ad9926be735a4324c10043bb4d2207ecaa21acd9` |
| `selbrume/assets/tilesets/fleurs_selbrume_de_toure_es.png` | legacy vegetation or ground-cover reference | not documented | not documented | not documented | source: pre-existing repository; origin not documented | license status: unverified | none documented | `7d3e54416818bda8b7749b6acea581d73c9c9d16b6551b6256033e9d08c78078` |
| `selbrume/assets/tilesets/grant.png` | legacy character sprite; outside environment-generation scope | not documented | not documented | not documented | source: pre-existing repository; origin not documented | license status: unverified | none documented | `0087e0f1374bb21f42e1aab2d42168276737cb7d521c6717c6d9a265c353165f` |
| `selbrume/assets/tilesets/grass_elements.png` | legacy vegetation or ground-cover reference | not documented | not documented | not documented | source: pre-existing repository; origin not documented | license status: unverified | none documented | `19693cc74f0b73e874a4c6d31b91508d5a14517d9675ac706ebadeb23e70df13` |
| `selbrume/assets/tilesets/grass_soft_flowers.png` | legacy vegetation or ground-cover reference | not documented | not documented | not documented | source: pre-existing repository; origin not documented | license status: unverified | none documented | `ef7260328bc6b85de74d6969f6b282fba0d90d7bde1dc98b771f97a7d206fad5` |
| `selbrume/assets/tilesets/grass_sprite.png` | legacy vegetation or ground-cover reference | not documented | not documented | not documented | source: pre-existing repository; origin not documented | license status: unverified | none documented | `208f2d4952c861a27a55d2aae4c60e56a6cfac93cdfcaf11561f2f94bba6d68f` |
| `selbrume/assets/tilesets/gros_sol_herbre.png` | legacy vegetation or ground-cover reference | not documented | not documented | not documented | source: pre-existing repository; origin not documented | license status: unverified | none documented | `5862b060ed3e43aea123c45500710e8f2dca79e7d56d6c32d1ed5f56e3425957` |
| `selbrume/assets/tilesets/haute_herbe.png` | legacy vegetation or ground-cover reference | not documented | not documented | not documented | source: pre-existing repository; origin not documented | license status: unverified | none documented | `1e765c68e84ffe25a8e9c9b2192d0a61cb1092a15f1fe3a7b51a963bf6987a0f` |
| `selbrume/assets/tilesets/lyra.png` | legacy character sprite; outside environment-generation scope | not documented | not documented | not documented | source: pre-existing repository; origin not documented | license status: unverified | none documented | `4a550a95da748b4b1dc254fbbb16ab9f95ce6582ec30329feb730595c4f43cb3` |
| `selbrume/assets/tilesets/mael.png` | legacy character sprite; outside environment-generation scope | not documented | not documented | not documented | source: pre-existing repository; origin not documented | license status: unverified | none documented | `4781448211f9885f52056f02904d7f6c5c00ddf380f53ed2ffc619e74c071c6b` |
| `selbrume/assets/tilesets/mountain_elements_paths.png` | legacy rock, cliff or coastal-material reference | not documented | not documented | not documented | source: pre-existing repository; origin not documented | license status: unverified | none documented | `af25d45da8b0ca4dc6a49218c0779bb02c210b84b99d82f9220f860b508b56e0` |
| `selbrume/assets/tilesets/new_pavement_new.png` | legacy path or pavement reference | not documented | not documented | not documented | source: pre-existing repository; origin not documented | license status: unverified | none documented | `d33cb49f4c2822aae66fb31286dd6588f1ab003debed575c98ad4dd551f5f805` |
| `selbrume/assets/tilesets/objectif.png` | reference-only full-map composition; forbidden as canonical underlay | not documented | not documented | not documented | source: pre-existing repository; origin not documented | license status: unverified | none documented | `0afc4d15218c94643a6ed7d5e3eeed61509e8b3c1566fb7449107d06b2f6c3c5` |
| `selbrume/assets/tilesets/objectif_1.png` | reference-only full-map composition; forbidden as canonical underlay | not documented | not documented | not documented | source: pre-existing repository; origin not documented | license status: unverified | none documented | `0afc4d15218c94643a6ed7d5e3eeed61509e8b3c1566fb7449107d06b2f6c3c5` |
| `selbrume/assets/tilesets/pavement_path.png` | legacy path or pavement reference | not documented | not documented | not documented | source: pre-existing repository; origin not documented | license status: unverified | none documented | `bc23b8cdd0578d1129ffdab4114f2f2657df68c6c242f6b03f0c664916281ded` |
| `selbrume/assets/tilesets/ponton_selbrume.png` | legacy pontoon reference and temporary port element | not documented | not documented | not documented | source: pre-existing repository; origin not documented | license status: unverified | none documented | `3ccdece08c4961ccdc23d903213b1064d7086585740fbb0c27a715b639efc21c` |
| `selbrume/assets/tilesets/rocks.png` | legacy rock, cliff or coastal-material reference | not documented | not documented | not documented | source: pre-existing repository; origin not documented | license status: unverified | none documented | `90c425bd733a98dcefefa97b22315fff3fc1a9ae0da418bd42889328e5f6af97` |
| `selbrume/assets/tilesets/route_1.png` | reference-only full-map composition; forbidden as canonical underlay | not documented | not documented | not documented | source: pre-existing repository; origin not documented | license status: unverified | none documented | `daf118db2cfbe6445755379607847dd85f316a869f3613783f7503e4c8822d1a` |
| `selbrume/assets/tilesets/route_1_1.png` | reference-only full-map composition; forbidden as canonical underlay | not documented | not documented | not documented | source: pre-existing repository; origin not documented | license status: unverified | none documented | `92e061651fa693ea9f938f1c0d2d2aa010c8b95977e59deced424dc8443af0f3` |
| `selbrume/assets/tilesets/selbrume_all_sprite.png` | legacy Selbrume architecture, palette and scale reference | not documented | not documented | not documented | source: pre-existing repository; origin not documented | license status: unverified | none documented | `f08b770e83d2c89acb4d3c210d2b98372897139ee5b1ae72d23ffe6a3eb9975e` |
| `selbrume/assets/tilesets/selbrume_open_sea_true_loop.png` | exact local source for planned registered open-sea loop | not documented | not documented | not documented | source: pre-existing repository; origin not documented | license status: unverified | none documented | `e083a51d5f6c5df36d49bb75bb42613c96a779b07fffc8cb5d8090431f4d4750` |
| `selbrume/assets/tilesets/small_water_rock.png` | legacy water or shoreline surface reference | not documented | not documented | not documented | source: pre-existing repository; origin not documented | license status: unverified | none documented | `b1b36e7b31adcd36b1fb1e1783f89554ce5bbaf5031f522850b81e80bfa91412` |
| `selbrume/assets/tilesets/timi.png` | legacy character sprite; outside environment-generation scope | not documented | not documented | not documented | source: pre-existing repository; origin not documented | license status: unverified | none documented | `569e7e27acf6e32af577dbb0e6eec0771f66f8fb7f4620697dd71bc93615c67d` |
| `selbrume/assets/tilesets/vova.png` | legacy character sprite; outside environment-generation scope | not documented | not documented | not documented | source: pre-existing repository; origin not documented | license status: unverified | none documented | `6a805f21eaebdb3cba5692acc731b5dccf1e2bdeae9830cf6340237034c06daa` |
| `selbrume/assets/tilesets/water_edge.png` | legacy water or shoreline surface reference | not documented | not documented | not documented | source: pre-existing repository; origin not documented | license status: unverified | none documented | `732bfbde23cffdf3ba9fcd25c1b342e9cc91760b074463507b339969b3b655a6` |
| `selbrume/assets/tilesets/water_edge_only.png` | legacy water or shoreline surface reference | not documented | not documented | not documented | source: pre-existing repository; origin not documented | license status: unverified | none documented | `4e608bc84db6e48b5998ceba347d952ed839521b73f72d11298586d601f0e2c9` |

## Sorties prévues — statut courant (10)

Dix sorties déterministes existent désormais : `selbrume_boat.png`, `selbrume_open_sea_loop.png`, `selbrume_port_props.png`, `selbrume_forest_props.png`, `selbrume_marsh_props.png`, `selbrume_passage_props.png`, `selbrume_lighthouse_exterior.png`, `selbrume_lighthouse_interior.png`, `selbrume_cabin_interior.png` et `selbrume_lighthouse_fx.png`. Leurs lignes consignent les transformations et hashes effectivement vérifiés. Aucune ligne ne prétend qu'un modèle exact, un auteur ou une licence existe sans preuve.

| relative path | role | author/generator | tool/model | date | source references | license status | transformations | sha256 |
|---|---|---|---|---|---|---|---|---|
| `selbrume/assets/tilesets/selbrume_boat.png` | normalized boat element | local deterministic derivation; original author not documented | `dart run tool/normalize_tileset_asset.dart`; `package:image`; anchor `bottom-center`; resize `none`; no image model | 2026-07-11 | `selbrume/assets/tilesets/bateau_selbrume.png` (source SHA-256 `465b20078cefb5cfbcd1347d0891e51275977930ae18952b2c3f824a81104678`) | license status: unverified; redistribution permission not_available; public beta publication blocked | decoded RGBA source 154×194; padded transparently to 160×224 at offset (3,30), without trim, resize or stretching; source pixels preserved byte-for-byte after decode; 5,964 padding pixels verified alpha 0 | `b7cde153d5328649a7a43f9e7c63ddb01296d4e400fa4d7cca859f1ae3bd59f1` |
| `selbrume/assets/tilesets/selbrume_open_sea_loop.png` | registered animated open-sea terrain | local deterministic filesystem copy; original author not documented | `cp -n`; byte-preserving copy; no image model | 2026-07-11 | `selbrume/assets/tilesets/selbrume_open_sea_true_loop.png` (source SHA-256 `e083a51d5f6c5df36d49bb75bb42613c96a779b07fffc8cb5d8090431f4d4750`) | license status: unverified; redistribution permission not_available; public beta publication blocked | byte-preserving RGBA 2048×64 copy; `cmp -s` exit 0; source and output SHA-256 both `e083a51d5f6c5df36d49bb75bb42613c96a779b07fffc8cb5d8090431f4d4750` | `e083a51d5f6c5df36d49bb75bb42613c96a779b07fffc8cb5d8090431f4d4750` |
| `selbrume/assets/tilesets/selbrume_port_props.png` | port modular atlas | generated locally with built-in `imagegen`; exact generator model not reported by the tool | built-in `imagegen`; `remove_chroma_key.py`; PokeMap raster normalizer and atlas builder | 2026-07-11 | `objectif.png`; `selbrume_all_sprite.png`; `ponton_selbrume.png`; `bateau_selbrume.png`; exact per-module prompts and raw hashes in `GENERATED_ASSET_PROMPTS.md` | license status: unverified because reference-source licenses and a redistribution proof are not documented; public beta publication remains blocked | 16 separate built-in calls/edits; green chroma removed with auto-key/soft matte/despill; each module normalized with proportional `contain-nearest` to its exact grid rectangle; deterministic 16×16-cell RGBA atlas assembly | `b049731e3e7cd0230263c03ea2c4b19eba8a7ac7b2980df18df9f8a7975ff4ca` |
| `selbrume/assets/tilesets/selbrume_forest_props.png` | forest modular atlas | generated locally with built-in `imagegen`; exact generator model not reported by the tool | built-in `imagegen`; `remove_chroma_key.py`; PokeMap raster normalizer and atlas builder | 2026-07-11 | `arbre_pixellab.png`; `fleurs_selbrume_de_toure_es.png`; `route_1.png`; exact per-module prompts and raw hashes in `GENERATED_ASSET_PROMPTS.md` | license status: unverified because reference-source licenses and a redistribution proof are not documented; public beta publication remains blocked | 12 separate built-in calls/edits; magenta chroma removed with auto-key/soft matte/despill; `el_selbrume_bois_tronc_tombe` received one `--edge-contract 1` correction; each module normalized with proportional `contain-nearest`; deterministic 16×16-cell RGBA atlas assembly | `5c38c0b372464b7ffc0f7984d7e667c4a6549bd80262b7f46ee46c6f2fae7e89` |
| `selbrume/assets/tilesets/selbrume_marsh_props.png` | salt-marsh modular atlas | generated locally with built-in `imagegen`; exact generator model not reported by the tool | built-in `imagegen`; `remove_chroma_key.py`; PokeMap raster normalizer and atlas builder | 2026-07-11 | `route_1_1.png`; `fleurs_selbrume_de_toure_es.png`; `mountain_elements_paths.png`; exact per-module prompts and raw hashes in `GENERATED_ASSET_PROMPTS.md` | license status: unverified because reference-source licenses and a redistribution proof are not documented; public beta publication remains blocked | 23 accepted built-in outputs/edits plus rejected geometry/art-direction attempts; magenta chroma removed with auto-key/soft matte/despill; each module normalized with proportional `contain-nearest`; deterministic 16×16-cell RGBA atlas assembly; all dimensions and chroma-residual checks passed | `e914dcf28b6cf85fcbc37c17a622e99cf69dd6e1083703958332bc47f0181b78` |
| `selbrume/assets/tilesets/selbrume_passage_props.png` | tidal-causeway modular atlas | generated locally with built-in `imagegen`; exact generator model not reported by the tool | built-in `imagegen`; `remove_chroma_key.py`; PokeMap raster normalizer and atlas builder | 2026-07-11 | `route_1_1.png`; `water_edge_only.png`; `mountain_elements_paths.png`; exact per-module prompts and raw hashes in `GENERATED_ASSET_PROMPTS.md` | license status: unverified because reference-source licenses and a redistribution proof are not documented; public beta publication remains blocked | 14 accepted built-in outputs/edits; initial barrier output rejected for wrong chroma and corrected by an image edit; green chroma removed with auto-key/soft matte/despill; modules normalized with proportional `contain-nearest`; fog bank preserves intentional partial alpha; deterministic 16×16-cell RGBA atlas assembly; all dimensions and chroma-residual checks passed | `73c73c4a8c6d0f2748e4eab46dd74feb29839b08b84a9cade9293f85f5282731` |
| `selbrume/assets/tilesets/selbrume_lighthouse_exterior.png` | lighthouse-exterior modular atlas | generated locally with built-in `imagegen`; exact generator model not reported by the tool | built-in `imagegen`; `remove_chroma_key.py`; PokeMap raster normalizer and atlas builder | 2026-07-12 | `objectif.png`; `selbrume_all_sprite.png`; `mountain_elements_paths.png`; exact per-module prompts and raw hashes in `GENERATED_ASSET_PROMPTS.md` | license status: unverified because reference-source licenses and a redistribution proof are not documented; public beta publication remains blocked | 13 accepted built-in outputs/edits; door and window variants derived from their accepted base states; green chroma removed with auto-key/soft matte/despill; every module normalized with proportional `contain-nearest` to its exact grid rectangle; deterministic 16×16-cell RGBA atlas assembly; visual atlas inspection and byte-identical rebuild passed | `d01765f4ad7406e8df8de1da4998497bc9223e131206d2439b35e7152994faac` |
| `selbrume/assets/tilesets/selbrume_lighthouse_interior.png` | lighthouse-interior and summit modular atlas | generated locally with built-in `imagegen`; exact generator model not reported by the tool | built-in `imagegen`; `remove_chroma_key.py`; PokeMap raster normalizer and atlas builder | 2026-07-12 | `selbrume_all_sprite.png`; `mountain_elements_paths.png`; exterior atlas used as an accepted style reference for selected calls; exact per-module prompts and raw hashes in `GENERATED_ASSET_PROMPTS.md` | license status: unverified because reference-source licenses and a redistribution proof are not documented; public beta publication remains blocked | 25 accepted module outputs plus two collision-alignment edits; green chroma removed with auto-key/soft matte/despill; every module normalized with proportional `contain-nearest`; east wall and vertical railing verified opaque at every intended cell center; summit horizontal parapet collision restricted to its visible lower rail and lantern collision to visible coarse cells; deterministic 32×32-cell RGBA atlas assembly; visual atlas inspection passed | `66110d66d7f0c0dfbba293e0d8a18e688e0cb2379c4b117f503c1ab67adbd0df` |
| `selbrume/assets/tilesets/selbrume_cabin_interior.png` | cabin and player-house modular atlas | generated locally with built-in `imagegen`; exact generator model not reported by the tool | built-in `imagegen`; `remove_chroma_key.py`; PokeMap raster normalizer and atlas builder | 2026-07-12 | `selbrume_all_sprite.png`; exact per-module prompts and raw hashes in `GENERATED_ASSET_PROMPTS.md` | license status: unverified because the reference-source license and a redistribution proof are not documented; public beta publication remains blocked | 20 accepted modules plus two rejected wall attempts and three rejected floor-seam corrections before accepted floor v4; green chroma removed with auto-key/soft matte/despill; each module normalized with proportional `contain-nearest`; floor v4 uses an exact-square visible patch with no fully transparent edge row/column; deterministic 16×16-cell RGBA atlas assembly; all module rectangles and chroma-residual checks passed | `ea0fa6dfdec99f3b9b03925036790b94789ee218b5a2dbf42606e9ea45cc020b` |
| `selbrume/assets/tilesets/selbrume_lighthouse_fx.png` | lighthouse and mist FX atlas | generated locally with built-in `imagegen`; exact generator model not reported by the tool | built-in `imagegen`; `remove_chroma_key.py`; PokeMap raster normalizer and atlas builder | 2026-07-12 | `water_edge_only.png`; `selbrume_open_sea_true_loop.png`; exact per-module prompts and raw hashes in `GENERATED_ASSET_PROMPTS.md` | license status: unverified because reference-source licenses and a redistribution proof are not documented; public beta publication remains blocked | 15 accepted built-in outputs/edits representing nine logical FX elements; green chroma removed with auto-key/soft matte/despill; modules normalized with proportional `contain-nearest` and center anchor; partial alpha preserved for fog, beam and halo; four-frame unstable-light and spark loops assembled at 160 ms and 120 ms per frame by the manifest; deterministic 16×16-cell RGBA atlas assembly; all dimensions and chroma-residual checks plus visual atlas inspection passed | `a7440a14d84d04449f24d20246315db875452056616676c641c25557eca9a9e2` |
| `selbrume/assets/tilesets/falaises_selbrume_pierres_chaine_v1.png` | 16-stone Border Studio chain atlas | generated locally with built-in `imagegen`; exact generator model not reported by the tool | built-in `imagegen`; deterministic chroma threshold, nearest-neighbour palette quantization, PokeMap raster normalizer and atlas builder | 2026-07-17 | `cliff.png` and `objectif.png`, visual style/composition references only; exact prompts and all three generation passes are recorded in `GENERATED_ASSET_PROMPTS.md`; no reference crop or underlay | license status: unverified because reference-source licenses and a redistribution proof are not documented; public beta publication remains blocked | the first 4×4 sheet and corrective 2×2 sheet are retained as superseded provenance; a final original 4×4 replacement sheet rebuilt all 16 entries; deterministic RGB chroma threshold, binary alpha, nearest-neighbour normalization and eight-colour stone-only quantization; 16 unique 32×32 RGBA modules, bottom-center anchor `(16,29)`; deterministic 4×4 atlas assembly; collision intent `visual_only_no_collision` | `357d8a242d688102a0d1cc6f8d1aa54cc5e76f15a21b60cf3692003a21169119` |

## Composants normalisés acceptés — `ts_selbrume_port_props`

Chaque hash ci-dessous porte sur le PNG RGBA final normalisé utilisé par l'atlas, pas sur la sortie brute du modèle. Les sorties brutes acceptées et les raisons de rejet des variantes précédentes sont consignées dans `GENERATED_ASSET_PROMPTS.md`.

| module id | normalized size | normalized sha256 |
|---|---:|---|
| `el_selbrume_port_quai_droit` | 128×64 | `920279bdd893f1efe24bad3f35a009d4c83902ad5c1b1f852838d5b2f9629a99` |
| `el_selbrume_port_quai_angle` | 96×96 | `e7491f80b352f6a876726fd95257371e7eed7f0a85267872e4ac27b97651521a` |
| `el_selbrume_port_quai_t` | 128×96 | `4d81dee6f24321c0f35ecf58b580325067c5f705f5d3ec2af1c36efaea9f98c8` |
| `el_selbrume_port_quai_fin` | 96×96 | `947215db2a8ef5aa12cd0be9522163cf31295314efaed2c0e9aff6de2513acf1` |
| `el_selbrume_port_escalier_quai` | 96×64 | `ff04728bdb70030b26cb6643e4b1c42db85bdc4c69c56a2534752ba174d1ab53` |
| `el_selbrume_port_brise_lames` | 192×96 | `8197d52e5c79fe6846571b96664048ed711d0636f85a400178d48a31f190fe97` |
| `el_selbrume_port_hangar` | 192×160 | `95b875c121a6da012a207244b8e1ef754afd1b3a95287f929ed1fa124e491c56` |
| `el_selbrume_port_bollard` | 32×64 | `f3f76be567a683c98e9faaa1f3e865b4c0fa81033f09da9072a22ee0559f6f51` |
| `el_selbrume_port_corde` | 64×32 | `0a91bb92cd78d95448482cffc937a20b0cc7f0e3a16f246b488b4ad939d8d905` |
| `el_selbrume_port_filets` | 96×64 | `4dd131376b1a142e18e366d0af52c2f34ff92f20e7095f571c95824d9d9d28c0` |
| `el_selbrume_port_caisses` | 96×64 | `c22e12b49f87549157c9c2b28b1a1da559862c042d8ab6b5f6d677c9d654d231` |
| `el_selbrume_port_tonneaux` | 64×64 | `cb1923ba6105a5da46305e845ae536bc580ffd44afbcf64cf4f482587d28c160` |
| `el_selbrume_port_bouees` | 64×64 | `4c99701f046d001c5df9934775fe164d7b35434c8704365bf39a5cd4f507e868` |
| `el_selbrume_port_nid_vide` | 64×64 | `9e3d6aaefd2d3e9a6bb7ffcfdeae0c508006aa0b641a11eec0b7828e9bd377c2` |
| `el_selbrume_port_nid_brillant` | 64×64 | `78f7392c202d425298f1626c847e20f6c2c01b35123d0c52f0278da818eef43e` |
| `el_selbrume_port_panneau` | 64×64 | `46671615d6073001f809d42ce3ee0e37382e4dbca500225f8cb424610d043c09` |

## Composants normalisés acceptés — `ts_selbrume_forest_props`

| module id | normalized size | normalized sha256 |
|---|---:|---|
| `el_selbrume_bois_pin_grand` | 192×256 | `6fbcebbeef8d6ae7da0be5e83ace67dbc0b19c08d9a51d835111f53591342ba7` |
| `el_selbrume_bois_pin_moyen` | 160×224 | `dc7decf12fedf1ad12b30f9f8ef2040724519d7150d79f193e405782fd2ff018` |
| `el_selbrume_bois_pin_petit` | 128×192 | `aa396c5f1ca4bb3e23b3abc6dad9c2684790faf91c534cc25c8edee2887c641e` |
| `el_selbrume_bois_buisson_1` | 96×64 | `82559fbe9a3df62d86277edb40774a426959e01d286d594c639913f3dd4c6149` |
| `el_selbrume_bois_buisson_2` | 96×64 | `32954d2a867ccaab69706b0a9f40b38c4712206efc84af2c57989926dbd564d8` |
| `el_selbrume_bois_fougere` | 64×32 | `7ec57d7d6287adb2e44eef830e01c28c38507d62e3b6c4a5e9a056a2304f8147` |
| `el_selbrume_bois_souche` | 64×64 | `c4355c1652722b92ff0915b738f6b13c24ac8259c5267a5ff877772b3cb95cde` |
| `el_selbrume_bois_tronc_tombe` | 128×64 | `6a3c2578d0d3879cd5fc3e1ebaa8686fc5fcbde3f0f004f9514db85fb14beb4f` |
| `el_selbrume_bois_ronces` | 96×64 | `07efb918d13f8e2bcb072d9b8da692e5375fbbebd3218d9453b1c748916d8ad8` |
| `el_selbrume_bois_aiguilles_sol` | 64×32 | `73ee55f79ef889ef87220110fa77bad31f554e33a874830f2db9402e081552ba` |
| `el_selbrume_bois_banc` | 96×64 | `8039908cd39dfa6d667739ab93f2bef6313cf4d9d8891e7d5ad5c260cb69cc7d` |
| `el_selbrume_bois_panneau` | 64×64 | `1ebc5e0e37df4c7077c955fa1667aae81830654987d2fa2999bb24e021ea77a5` |

## Composants normalisés acceptés — `ts_selbrume_marsh_props`

| module id | normalized size | normalized sha256 |
|---|---:|---|
| `el_selbrume_marais_cabane_paludier` | 160×160 | `9778c9cd2da4ab5dbae3aaf713e08b4b2016124eb3965684e9cff8aa29982778` |
| `el_selbrume_marais_passerelle_h` | 128×64 | `30883654f0994b69e437a884f57cfedbb8d7fad9fd5f484f186ec213c2a5863c` |
| `el_selbrume_marais_passerelle_v` | 64×128 | `f0b53f773f28b32486779fffb43b883a8f3cbf54835d7dd4114eb913aca0eae4` |
| `el_selbrume_marais_passerelle_angle` | 96×96 | `0b06e351d37bf9ec5f8492bc1ac0b48f5319002e52d0d40c8ae416766c0e3560` |
| `el_selbrume_marais_ecluse_fermee` | 96×64 | `239a9d77bd50ce905e39368fb697e1cb5f438b4eac0db9209686772815d32b85` |
| `el_selbrume_marais_ecluse_ouverte` | 96×64 | `3c2b671ba7074a6c918a2dbd8db108aa5b3a0a27122143f9e87936e11ba1e119` |
| `el_selbrume_marais_roseaux_1` | 64×64 | `311af290c766658195cf166a01291b0d8b533c5cfb1beaf416c403c421dadac0` |
| `el_selbrume_marais_roseaux_2` | 96×96 | `fab386889d76e92145895522501263b889d1a489aaffbc162d3ab5816e0a409f` |
| `el_selbrume_marais_roseaux_3` | 64×96 | `54bd585775bd03c7f36ac81e616145e5767a12cb55d04937ef8a5e31f012d15c` |
| `el_selbrume_marais_sel_petit` | 32×32 | `f1366df20fa29fd37ef215e1104fe2e1d558b7e933692dd1cfa47dd9abb67932` |
| `el_selbrume_marais_sel_moyen` | 64×32 | `7dc6aa286b5dc41629ddb8239ab1f9ef7766894c1924156a36d466d9b7462079` |
| `el_selbrume_marais_sel_grand` | 96×64 | `86095d09a81d03acec4783ade5b3c74799a915e3822c73a47a2122114f93b090` |
| `el_selbrume_marais_rateau` | 64×64 | `df54347dcce23ab894885902a03a7092dbd8991ba1b361387f0a556552895430` |
| `el_selbrume_indice_verre` | 32×32 | `7aac6519346a966cac37625cbece917004a8faf291481654a8b741bf358647cb` |
| `el_selbrume_indice_traces_electriques` | 64×32 | `f5d045fcf4f33c5153023d840d675bec42001038a60df8e6785a2d943ec0b448` |
| `el_selbrume_indice_repere_lentille` | 32×32 | `497aed038bf9b0265f56f5f3c24a30cf3a7b1b3d3531689a2161c8d58e4dd64c` |
| `el_selbrume_cristal_1` | 32×32 | `05cde60c473ffee0d833f844c637651f745001508d9f1accb7b060fb535c2e43` |
| `el_selbrume_cristal_2` | 32×32 | `c6d20e6a8eb96a2c7d930ea062aaa230ccd992e94f96a6fc969e2451266f08ca` |
| `el_selbrume_cristal_3` | 32×32 | `68a4e45a737fd724f824624c9bd0e139ec9fb0dcb1a9ed6fa7ee3093879a1958` |
| `el_selbrume_marais_passerelle_t` | 128×96 | `63357399e59209d2ada62d545e4a1e6ec47eeba697432bbaa2aacc9ed5b9010d` |
| `el_selbrume_marais_roseaux_4` | 64×64 | `4a48e412e4cf05c549166cfbb2f4af2e9398aba30a862e8614291948ec01b7e9` |
| `el_selbrume_marais_roseaux_5` | 96×64 | `72f23abccfa5a641c828f5b5defaecff5927f46405025a4397d161e6bc108cb0` |
| `el_selbrume_marais_roseaux_6` | 64×96 | `c343ad019a784d75b2af8574550aa1c0ad52ed1b35e89315dd0e692f9d7b369c` |

## Composants normalisés acceptés — `ts_selbrume_passage_props`

| module id | normalized size | normalized sha256 |
|---|---:|---|
| `el_selbrume_passage_barriere_fermee` | 128×96 | `b4b31f5bf7cc8715f7ac4e1f0f67b577c1a06230f93737ec18177fb86f53ae92` |
| `el_selbrume_passage_barriere_ouverte` | 128×96 | `5201caf00a6f838b7de00a45577674b8b9a2a659bf03a7782d73c21a92cf1ceb` |
| `el_selbrume_passage_borne` | 32×64 | `b07f4dfb7b83fa10e8f4b7ca24ef8d4ec45fe854c17c229e6e73ac27ef338736` |
| `el_selbrume_passage_panneau` | 64×64 | `24f4a208340b5ef9704ba018bbdc892fd570329e23e8ae52e470a50d6cbaf851` |
| `el_selbrume_passage_chaussee_humide` | 128×64 | `bb7aefcc98aef4b1cfe50eac74ff5c2f42e213c29812a77d4cb2ecb529b79276` |
| `el_selbrume_passage_ecume_h` | 128×32 | `962846e6c440a5638842cfc150f644efdfc8563f573884b0ccd39306d5b2bb2e` |
| `el_selbrume_passage_ecume_v` | 32×128 | `d5ec3aff31cc7c16917827effd2fbdce670c1bab7f719265c3e45664b0a6e4d3` |
| `el_selbrume_passage_algues` | 96×32 | `6038f5d1a31a53f42f53c15ddc208a405ac96ca834a24eac3cd5942af2f10f44` |
| `el_selbrume_passage_balanes` | 64×32 | `5b65b194021292f6d3896f7e395ec7fae1ea14121f9342b42f89e754da53d0d8` |
| `el_selbrume_passage_bois_flotte` | 96×64 | `1fca9344734855157deaa833b3e062d9f99778a8a3487271a24bab48ba1f5186` |
| `el_selbrume_passage_marches` | 96×64 | `c6297ffb11b66604c1b2d6110512ee8e31e097fb0f7038006932120241d2767a` |
| `el_selbrume_passage_chaussee_seche` | 192×96 | `a7cacca41a619eaab5defcb8ebc44fc3c43d941ca03e0777898f0021f6914ff0` |
| `el_selbrume_passage_flaques` | 96×64 | `8b9e1434058912cb8d49fad790f562120a112223eb2dc77ab0d5de658b2fabec` |
| `el_selbrume_passage_banc_brume` | 256×128 | `deb58e17f41790e401793f18c9dd709bc86abfc88d5ff7497cfb77655f712754` |

## Composants normalisés acceptés — `ts_selbrume_lighthouse_exterior`

| module id | normalized size | normalized sha256 |
|---|---:|---|
| `el_selbrume_phare_batiment` | 256×320 | `9f4bae36782683f65db2abaa1728a4a5320c851c86e649a2cf5c46297763230e` |
| `el_selbrume_cabane_facade` | 160×160 | `1d90cff803b4eda3ab207365ea1286db8a7cad2fadb0bbcb4e23433aaf603b94` |
| `el_selbrume_phare_porte_fermee` | 64×96 | `9ed8c07dafeaca551344079d5bbef914322020fb4f28d259768e32dc60b4da65` |
| `el_selbrume_phare_porte_ouverte` | 64×96 | `ca9e80222442c64eb73059e2e982579dac44159739067c4d6e3ec11ed8224bed` |
| `el_selbrume_cabane_porte_fermee` | 64×64 | `292b838a431504e857f8c54cb7af06808d14d2c0106e44f2ad545a61023f7e43` |
| `el_selbrume_cabane_porte_ouverte` | 64×64 | `7aeffecde1fe08bbe41c0f1d178ae437aa033731dd8b1fd376f47ca36a64e714` |
| `el_selbrume_phare_fenetre_sombre` | 64×64 | `4a2453b968d6417032f111c84ae946f8cad05933908c8e35c5e4696833749ec8` |
| `el_selbrume_phare_fenetre_lumineuse` | 64×64 | `169c2a44eb2f2070996dc7aca15ae28b7d0b85abc99bb3ad7d5e9fc60b260a21` |
| `el_selbrume_phare_rambarde` | 128×64 | `81a6c1c543aa208c9fd65dee22fb470b6e994f8dbbcf8d1059be2b9cbf1997db` |
| `el_selbrume_phare_fondation` | 256×64 | `acfc498862d985d85035e0581caf8c6a9201ade140ec64ed97763f3af4b59d91` |
| `el_selbrume_phare_panneau` | 64×64 | `73f40b1e690ffaebe53accfc35c9b36de4c929505fb6e646ab77ec153066b487` |
| `el_selbrume_phare_debris` | 96×64 | `76943ee9f344ce9ab7ccde898ef6cd33e9c79f99e4ff6530d71e854b8e55d4bb` |
| `el_selbrume_phare_marches` | 96×64 | `8a0be30a643d61e0349add68afa1a6a29f06ec198bb11d6846c06e792f198558` |

## Composants normalisés acceptés — `ts_selbrume_lighthouse_interior`

| module id | normalized size | normalized sha256 |
|---|---:|---|
| `el_selbrume_phare_sol_pierre` | 128×128 | `c071b240e79bb7dff62bd550048c999987dd76d1b8e6c31fcffd78414ea43fd0` |
| `el_selbrume_phare_sol_bois` | 128×128 | `48486bca89f743738ddb638a44396aa757ced3d9d854a599d3f7f79c47add1ea` |
| `el_selbrume_phare_mur_n` | 128×64 | `7d5115dcfd928f6fd534d474c30b54f362726d9f34095e5e8c9d68be0839817e` |
| `el_selbrume_phare_mur_s` | 128×64 | `f9589d5e005f49384468b6e47143dd12ef1d18e489348479567c4f31e933bb01` |
| `el_selbrume_phare_mur_e` | 64×128 | `891b996c5628ab0880c4ac56d5d949b2c1c2f8e5e1bc4b5564209983c81e6000` |
| `el_selbrume_phare_mur_o` | 64×128 | `5189b8cb4cd5a4a085713967176e4ea2b0440636865c9d6f44c66e0bab61c9b4` |
| `el_selbrume_phare_coin_no` | 64×64 | `19511a1e36eefdf94247ac9161835a723f986aeb0daa24031943cb5f9920bbc9` |
| `el_selbrume_phare_coin_ne` | 64×64 | `ac3cfb4f478a20843b45de21d7639a50e8b195fb8f0034772cfa990dc51be69b` |
| `el_selbrume_phare_coin_so` | 64×64 | `7f769f05083b00fcda08e4961656d33e0e56a1bd54c7d7cee2cf4ac9c5b290ef` |
| `el_selbrume_phare_coin_se` | 64×64 | `5f651b6679669f6af6d86d922119e1dd3b68ec2d6ad079f5522006ab11bf0d77` |
| `el_selbrume_phare_escalier_haut` | 96×96 | `52378acf72b7f8665f864aecf99840fdc8467c4d679df3b9040cdf01d5203b38` |
| `el_selbrume_phare_escalier_bas` | 96×96 | `05db791b288433549cdd838095bcdcc9d041e9095220393ec4a20469b1237f45` |
| `el_selbrume_phare_rambarde_h` | 128×32 | `461056568a6271ae8a612b0c1b6cc3b7d740e49df6656165ca89a72c0b867d92` |
| `el_selbrume_phare_rambarde_v` | 32×128 | `649af773c48c631272f653fb435986abb004e0a0eabb5a2cedddea915aeb989e` |
| `el_selbrume_phare_plancher_brise` | 96×96 | `d208b9a80a6d37331e2fa1c59464bf890a366a066f5f211d59e5dc7f7a9fe653` |
| `el_selbrume_phare_mecanisme` | 160×160 | `02fc45aa2a5c5a99a2e29d9004aeb6773c880ec02463fe8d20d4f7f91715a719` |
| `el_selbrume_phare_machinerie` | 96×96 | `1dff6ef884055b025a7811b50d452eca5f4ecfcfb187105bab39945b89f16f6e` |
| `el_selbrume_phare_bureau_note` | 64×64 | `3b62fe3396bc65a5f6ae5661988d61956a72e8f53e3687e09176b41f6a05fd8a` |
| `el_selbrume_phare_caisses_debris` | 96×64 | `e88c8926e2ffc2d967bb1c5950b53ac1b705de33d3efc756929f0c9aab8d5aeb` |
| `el_selbrume_phare_fenetre_interieure` | 64×64 | `fe42fc6aae8ada649c961fbcde3d3914eccae3f7bf4014982659df9c12e30a25` |
| `el_selbrume_phare_trappe` | 64×64 | `1b46d480be19dd7b1a503620fcb69ab43beff8a5f3d68c16ce6df70e242e2afc` |
| `el_selbrume_sommet_plateforme` | 192×192 | `cd79719852fc9795bdbc154f8a67fcf6059edecbabf98baca5c5d96fd7ce3c45` |
| `el_selbrume_sommet_parapet_h` | 128×64 | `fedb0d9a6c38a9a4ca7e8e89439368514df31e99238a28bf82365332a1eff797` |
| `el_selbrume_sommet_parapet_v` | 64×128 | `d5fcbf658696802617493645b210596da879a3cf2d03583ca76d608461371d22` |
| `el_selbrume_sommet_lanterne` | 160×160 | `1fbcbb60233f5ac4d98ef81199ac7f6e5fdee7b4237656e30f901b78fe8d462e` |

## Composants normalisés acceptés — `ts_selbrume_cabin_interior`

| module id | normalized size | normalized sha256 |
|---|---:|---|
| `el_selbrume_cabane_sol_bois` | 128×128 | `e7d2edf8bbd8ebc3f552cb8bb95b253b2aab6c84d09e6f7e39d5f7f01dca57e7` |
| `el_selbrume_cabane_mur_n` | 128×64 | `27afb61260096b515aa62db430cc1ac6d464433a22c92eadd8140496ab4ec06a` |
| `el_selbrume_cabane_mur_cote` | 64×128 | `c7eb64b2e65693ff519ce68e4911bf438dc2e47621f383e7625931af24cea408` |
| `el_selbrume_cabane_lit` | 64×96 | `8a8dccf6c2647d4d9656d7f278da1ae07eba6ff63c00a7953b2f12efcde3e7cb` |
| `el_selbrume_cabane_table_carnet_ferme` | 64×64 | `cb457da95853df4276e685d64bf2d849e45077dd67bcdad8003f9f5a57ce98e4` |
| `el_selbrume_cabane_table_carnet_ouvert` | 64×64 | `7e05bc7b38791ed132d8b852fb276250850cd45dc48ae6f3c3d7b10547098399` |
| `el_selbrume_cabane_poele` | 64×96 | `9da51a01da3a4a41557b4de01e4b419eb3751cd52f20fc273ccdd05acc53babd` |
| `el_selbrume_cabane_etagere` | 64×96 | `003f0ba28df0715d0ec6c2b9747f1f06282d15371a9a5515d2d7fe54dd96f8fb` |
| `el_selbrume_cabane_coffre` | 64×64 | `09d976116aaea17f1e9bebfdd5672b799ad32f73daf5e8d683c90af8f947d590` |
| `el_selbrume_cabane_carte` | 64×64 | `abe983f97b6e49991123b4ec4c21b4c6440ab9ab0e0320b3cf2f5bda0d94071b` |
| `el_selbrume_cabane_cle` | 32×32 | `60bddab5b8caa1d8d5ac908a6cb2042b46b3bfc9955b2e1d33dabac11515c41b` |
| `el_selbrume_cabane_outils` | 64×64 | `ba3b0f896662ce8d69d0a5d3752834050810e208e74db8370775150f0386555f` |
| `el_selbrume_cabane_lanterne` | 32×64 | `3983a9d6b1c2950ef411dfb44ef306b07a836863b5eac70704df8ded82fdbc1c` |
| `el_selbrume_cabane_porte_secondaire_fermee` | 64×96 | `b25cc97449fd2b485134b94264e1422708d1631be8d57d984a18467619dcebf8` |
| `el_selbrume_cabane_porte_secondaire_ouverte` | 64×96 | `56e0860220ae68ccc56d1d50cef216e9759a19897412bcb2046444442a209671` |
| `el_selbrume_maison_lit` | 64×96 | `c5eb910378ba57361bd56eb342fba9752b6f86116cd44357146581b53798a67f` |
| `el_selbrume_maison_bureau` | 64×64 | `a51185ccfa38d5e5b999f7a6351bf7449254baa410345751592e5f48045f55a8` |
| `el_selbrume_maison_tapis` | 96×64 | `e0ae5102eb13729064e2aedc5f915edbc1c3711b37d07562b08324acd60e02b8` |
| `el_selbrume_cabane_porte_principale` | 64×96 | `fa56cf6510f594e1b80931523db8b41db694ec4945dd29fd5be5365ae7e09209` |
| `el_selbrume_cabane_chaise` | 32×64 | `8866182d874d6df6d483890905a7fdab08743e835ceea8b9d4cdf731e234743d` |

## Composants normalisés acceptés — `ts_selbrume_lighthouse_fx`

| module id | normalized size | normalized sha256 |
|---|---:|---|
| `el_selbrume_fx_brume_basse` | 256×128 | `4b6057a297964139e13dff7beea1d52ca1f170d19b7884c1521036a0abe5d331` |
| `el_selbrume_fx_banc_brume` | 256×128 | `b31030e31ac50a5fdbec399d50cd2bc5be59b880f6aa251359cba9a45d287f9b` |
| `el_selbrume_fx_faisceau` | 256×64 | `fd8ccf6c6bdc50f8ffd6db004d1e48af298e18f3774d4bca882e3d2539243492` |
| `el_selbrume_fx_fenetre_lumineuse` | 64×64 | `f94bc385e6232e3bef254f55c5e9367d9107a75895318dd307aa76ae5b20bb83` |
| `el_selbrume_fx_halo` | 128×128 | `b3e97450f87b9cf1cef69ca9a1954e43f67cb5dcf91ad86689095de73d921ec4` |
| `el_selbrume_fx_lumiere_eteinte` | 128×128 | `4ae8ceb881aeda27007b800d20d2f08c7bbf305b82d1b868e959605012feebec` |
| `el_selbrume_fx_lumiere_stabilisee` | 128×128 | `d281f2a0c93927b2884d2be705caf60cac195e25d06f2b15e6b3a5426be105ab` |
| `el_selbrume_fx_lumiere_instable_f1` | 128×128 | `cd5f3554a366d7a6b053177a12e24960066749bb82bc58f1f7a7ca43860ffd7f` |
| `el_selbrume_fx_lumiere_instable_f2` | 128×128 | `3f428e57b46473d017b2cab990f4328e67d7e4b1f55af19e30b01917c6161646` |
| `el_selbrume_fx_lumiere_instable_f3` | 128×128 | `e2b70af05f42e976ce06571195c285e35551b4780d52bbe7652469b89868a80a` |
| `el_selbrume_fx_lumiere_instable_f4` | 128×128 | `afe07da2268bdebde5779c195135e0ce4925bbfec06e64e0498fc9b4c849d287` |
| `el_selbrume_fx_etincelle_f1` | 64×64 | `e79097e8e818c3b62d111ff4359cc513f6ec69dcbae48adc8110bf023d056d29` |
| `el_selbrume_fx_etincelle_f2` | 64×64 | `46ac34e761887e8001cdca28d5314d18da9aeff75b1cd8dfa5d5e1a877a51b81` |
| `el_selbrume_fx_etincelle_f3` | 64×64 | `a9c6edb9dc502d2b5d734362bbf424632db0fec1e4288531739339a2e2a7d278` |
| `el_selbrume_fx_etincelle_f4` | 64×64 | `48f1e54ce291cbf680c26e0a9c7b4104e21dde086ebc3306326fc6cbb62fe2d5` |

## Composants normalisés acceptés — `ts_selbrume_cliff_stone_chain_v1`

Les hashes source bruts et les bornes opaques complètes figurent dans
`assets/provenance/selbrume_stone_chain_v1.json`.

| module id | normalized size | normalized sha256 | opaque footprint |
|---|---:|---|---:|
| `stone_chain_primary_01` | 32×32 | `2f3c5366cc73cf01f57c61325110c1c0baab74a74bb97a5952a34878a7e24042` | 19×14 |
| `stone_chain_primary_02` | 32×32 | `4741272c269393eb62f7e5620d98ce02eac5aa4bef8a8213be524356e1dca109` | 18×17 |
| `stone_chain_primary_03` | 32×32 | `bdea3083425bf04ab2c1ddc791ccb90dc05ffb6d154b646daae8029a7590449f` | 18×17 |
| `stone_chain_primary_04` | 32×32 | `fc95cdc584d1135e09f45503e194e106b9382afc2b1221c582c25231c49b22a6` | 19×14 |
| `stone_chain_primary_05` | 32×32 | `bf87e03db1d6659d59ce94db4e33444da03622fff21c19652f72def6e7044c2c` | 17×17 |
| `stone_chain_secondary_01` | 32×32 | `9994db7ee24e3eb0d50f78129c023b04ba40b01c25963d480a4b21e52608f564` | 14×14 |
| `stone_chain_secondary_02` | 32×32 | `ab62cd6e5fe840ecee4810286e689345ef896f99a339ee3d3dd944cc4dcc2b77` | 14×14 |
| `stone_chain_secondary_03` | 32×32 | `a2d52328c737c86944a08ad926b4578eb63e001f2bc298920e2322a2346d9a32` | 14×13 |
| `stone_chain_secondary_04` | 32×32 | `53a51aa9a5afefdfe363da00cfe776ebe2cfcc39b0205fa3e052f764ab0d60eb` | 14×10 |
| `stone_chain_filler_01` | 32×32 | `e7bc8c42f3757cf021bb19d1f9dadf948579199974bb5fd0d6a0a617f893a800` | 6×6 |
| `stone_chain_filler_02` | 32×32 | `cff0bd9da5c55139d0f4aafbcfc6b132ef0b3a53304c36a933af26d1381a578a` | 7×6 |
| `stone_chain_filler_03` | 32×32 | `0e92cd0331c5f5ae7e8508927e23e823bb6f19bd3924d2e600279d90e6c15b26` | 6×5 |
| `stone_chain_corner_01` | 32×32 | `c3a2242aa2ca870e199acc56af7b031b637bf2388ae7d79bf8d41a401f21896f` | 17×15 |
| `stone_chain_corner_02` | 32×32 | `460406aaf0cad860ab4f57206278cdf1cd607ca63cec1ed5e9eb6a32849404f6` | 17×14 |
| `stone_chain_cap_01` | 32×32 | `de1b79ee167b02d1d851df75d09ac8d5cf666f867c80a50db963b36b51c67202` | 8×8 |
| `stone_chain_cap_02` | 32×32 | `5f484f25fa374f1806f4aca178791117f854f203ee286f92f03f2fe7de96e638` | 7×6 |

## Snapshots publiés — `ts_selbrume_cliff_two_tier_v2`

Les 24 snapshots immuables de la révision publiée sont des copies
byte-identiques des 24 sources V2. Le manifeste
`assets/provenance/selbrume_two_tier_cliff_v2.json` enregistre pour chacun le
chemin source, le chemin snapshot et le SHA-256 partagé. Le builder ne produit
ces entrées dérivées que si le fichier snapshot existe réellement, suit la
forme `borders/snapshots/<sha256>/frame_0000.png` et correspond en octets à une
source V2 acceptée. Ces 24 paires sont les seuls nouveaux doublons autorisés par
le gate post-publication.

## Procédure d'acceptation et de remplacement des états planifiés

1. Générer chaque module, état ou frame dans un appel built-in `imagegen` séparé, avec le prompt final reconstruit exactement depuis `GENERATED_ASSET_PROMPTS.md`; aucun générateur tiers ou fallback CLI n'est implicite.
2. Consigner après l'appel : date ISO-8601 réelle, outil et modèle réellement rapportés, références locales dans leur ordre, couleur chroma, chemin de sortie brute et SHA-256 de cette sortie.
3. Retirer le chroma, inspecter l'alpha et les franges, puis normaliser proportionnellement sur grille 32 px. Consigner séparément les hashes source, détouré et normalisé; ne jamais recopier le hash d'une étape vers une autre.
4. Assembler chaque atlas avec `ATLAS_LAYOUTS.json`; enregistrer la commande, les 154 hashes historiques et les 24 hashes V2 de composants acceptés, ainsi que le SHA-256 de chaque atlas final.
5. Remplacer `not_generated` et `not_available` uniquement par des valeurs observées. Une sortie rejetée reste hors projet et sa raison est enregistrée dans le registre de prompts.
6. Obtenir une preuve de licence ou permission de redistribution applicable au fichier final. Sans preuve, conserver `license status: unverified` et le blocage de publication publique, même si la QA technique est verte.
