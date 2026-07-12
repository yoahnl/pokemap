# SEL-MAP-001 — Selbrume Maps & Assets Beta / fondation visuelle de FG-181

## 1. Résumé exécutif

Le lot **SEL-MAP-001 — Selbrume Maps & Assets Beta** est techniquement matérialisé dans un worktree isolé. Le manifeste actif contient exactement dix cartes canoniques et six groupes canoniques. Les dix cartes chargent, se rendent, se connectent et respectent les contrats d'assets et de navigation automatisés.

Le lot livre également dix sorties raster déterministes, dont huit atlas modulaires composés de 138 modules acceptés, un générateur idempotent Task 4 à Task 16, des outils de normalisation/assemblage, cinq suites de contrats runtime, un harnais de capture et 56 preuves visuelles versionnables.

Verdict proposé :

- `SEL-MAP-001` : **DONE technique**, avec polish artistique ultérieur et écart de boucle marine documenté, non bloquants ;
- publication bêta publique : **BLOCKED licence**, car les licences des références historiques ne sont pas documentées ;
- `FG-181` : **PARTIAL**, car ces cartes fournissent sa fondation visuelle mais pas le starter, la capture, le PC, la boutique, le badge, la capacité de terrain ni la mini-fin exigés par son DoD ;
- `FG-180`, `FG-182` et `FG-185` : inchangés.

Le présent lot ne modifie pas la roadmap.

## 2. Périmètre confirmé

Inclus :

- audit des dix cartes historiques ;
- blueprints de production et topologie canonique ;
- création des éléments environnementaux manquants ;
- normalisation et assemblage des atlas sur grille 32 px ;
- construction de dix cartes canoniques ;
- connexions, warps, collisions, couches de placement et réservations narratives inertes ;
- bascule des références actives `Selbrume` et `route 1` vers les IDs canoniques ;
- tests, captures, provenance, builds et Evidence Pack.

Explicitement hors scope :

- dialogues, événements narratifs exécutables, combats, récompenses ou progression ;
- variantes pilotées par des facts, marée dynamique et résolution narrative du phare ;
- migration des anciennes sauvegardes qui stockent `Selbrume` ou `route 1` ;
- suppression des dix JSON historiques ;
- correction des équipes Pokémon P6 ou des animations PathPattern historiques ;
- changement de statut de la roadmap ;
- intégration Git pendant l'implémentation ; le rebase/merge local a été
  autorisé séparément après la validation finale du lot.

## 3. Audit initial et décision d'architecture

### 3.1 État constaté

L'audit initial, consigné dans `selbrume/docs/map_production/legacy_map_inventory.md`, a montré :

- dix entrées actives historiques ;
- deux cartes substantielles : `Selbrume.json` et `route 1.json` ;
- deux squelettes d'intérieur : `house 1.json` et `house 2.json` ;
- six coquilles presque vides ;
- 35 sources raster préexistantes sans provenance/licence vérifiable ;
- des scénarios et cinématiques encore liés aux anciens IDs ;
- deux échecs P6 préexistants sur `Metapod`/`Dratini`.

### 3.2 Contrats préservés

- PokeMap reste propriétaire de ses JSON et de son runtime ; aucun format externe n'est requis.
- Les modèles et validateurs restent dans leurs packages existants ; aucune règle de gameplay n'est déplacée dans Flame.
- Chaque `MapPlacedElement.layerId` vise un `TileLayer` existant. Le runtime
  résout l'atlas depuis le `ProjectElementEntry`; pour les quatre intérieurs,
  le `tilesetId` de la couche correspond aussi à celui de l'élément.
- Les réservations narratives sont des métadonnées inertes, pas de faux événements exécutables.
- Les quatre full-maps `objectif*` et `route_1*` servent uniquement de références et ne deviennent jamais des underlays canoniques.
- Les deux seeds utiles gardent leurs empreintes sémantiques, avec migration explicite de la navigation.

### 3.3 Remise en cause utile du plan brut

Faire « tout d'un coup » sans frontières aurait rendu la provenance, les downgrades et les validations impossibles à auditer. Le chantier a donc été exécuté en seize frontières déterministes, puis matérialisé en une seule sortie Task 16. Cette adaptation conserve le résultat demandé tout en donnant des sentinelles de downgrade, une écriture manifest-last et des tests par frontière.

### 3.4 Écart au plan détecté par la critique finale

Le contrat brut réservait le pattern `pp_selbrume_open_sea_loop` aux couches
d'eau du Port, du Passage et du Phare extérieur. La matérialisation conserve
`nouveau-chemin` sur Bourg, Port et Passage, tandis que le Phare extérieur
utilise encore `dirth_path` pour ses sols secondaires. C'est la cause de sa mer
plus plate. Répartir simultanément mer animée, îlot et chemin dans le contrat
extérieur fixe à deux `PathLayer` demande de repeindre `l_tile_ground`; cette
passe artistique n'a pas été improvisée en fin de lot. L'écart n'affecte ni
chargement, collisions, warps ni traversabilité, mais il reste explicitement
ouvert.

## 4. Git et isolation

État initial :

```text
worktree: /Users/karim/.config/superpowers/worktrees/pokemonProject/codex-selbrume-map-assets-beta
branch: codex/selbrume-map-assets-beta
base HEAD: fdaf4e5ddfb82981353c104c89377f061b207e2e
git status --short --untracked-files=all: aucune sortie
```

Jusqu'à la validation finale décrite par ce rapport, le worktree principal
sale de l'utilisateur n'a pas été modifié et aucune opération Git d'écriture
n'a été exécutée après la création explicitement autorisée du worktree et de sa
branche.

## 5. Catalogue canonique livré

| ID | Taille | Couches | Éléments | Entités | Triggers | Warps | Connexions | Zones |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| `map_bourg_selbrume` | 55×55 | 8 | 306 | 3 | 0 | 1 | 2 | 0 |
| `map_port_brisants` | 45×45 | 8 | 21 | 3 | 4 | 0 | 1 | 2 |
| `map_bois_chaise_brume` | 45×45 | 8 | 12 | 0 | 0 | 0 | 2 | 4 |
| `map_marais_salants` | 45×45 | 8 | 22 | 2 | 7 | 0 | 2 | 6 |
| `map_passage_dames` | 60×24 | 8 | 13 | 0 | 1 | 0 | 2 | 1 |
| `map_phare_exterieur` | 45×45 | 8 | 10 | 0 | 1 | 2 | 1 | 1 |
| `map_phare_interieur` | 36×45 | 7 | 175 | 0 | 1 | 2 | 0 | 2 |
| `map_sommet_phare` | 24×24 | 7 | 23 | 0 | 2 | 1 | 0 | 1 |
| `map_cabane_gardien` | 20×16 | 7 | 50 | 0 | 2 | 2 | 0 | 0 |
| `map_maison_joueur` | 20×16 | 7 | 43 | 1 | 1 | 1 | 0 | 1 |

Topologie :

```text
Maison joueur <warp> Bourg -> Port
                        |
                        +-> Bois -> Marais -> Passage -> Phare extérieur
                                                          |         |
                                                       intérieur   cabane
                                                          |
                                                        sommet
```

Le manifeste actif ne contient plus d'entrée map legacy. Les fichiers legacy restent sur disque, byte-intacts, pour comparaison et historique.

Les quatre intérieurs matérialisent tous le contrat prévu, dans l'ordre :
`l_terrain`, `l_tile_floor`, `l_tile_walls`, `l_tile_furniture`,
`l_tile_overhead`, `l_tile_fx`, `l_collisions`. Ils activent explicitement
`tileLayerOrder: bottom_to_top`; l'éditeur et le runtime conservent l'ordre
historique inversé pour toutes les autres cartes.

## 6. Assets livrés

### 6.1 Sorties finales

| Sortie | Taille | Modules | SHA-256 |
|---|---:|---:|---|
| `selbrume_boat.png` | 160×224 | normalisation d'une source | `b7cde153d5328649a7a43f9e7c63ddb01296d4e400fa4d7cca859f1ae3bd59f1` |
| `selbrume_open_sea_loop.png` | 2048×64 | copie déterministe | `e083a51d5f6c5df36d49bb75bb42613c96a779b07fffc8cb5d8090431f4d4750` |
| `selbrume_port_props.png` | 512×512 | 16 | `b049731e3e7cd0230263c03ea2c4b19eba8a7ac7b2980df18df9f8a7975ff4ca` |
| `selbrume_forest_props.png` | 512×512 | 12 | `5c38c0b372464b7ffc0f7984d7e667c4a6549bd80262b7f46ee46c6f2fae7e89` |
| `selbrume_marsh_props.png` | 512×512 | 23 | `e914dcf28b6cf85fcbc37c17a622e99cf69dd6e1083703958332bc47f0181b78` |
| `selbrume_passage_props.png` | 512×512 | 14 | `73c73c4a8c6d0f2748e4eab46dd74feb29839b08b84a9cade9293f85f5282731` |
| `selbrume_lighthouse_exterior.png` | 512×512 | 13 | `d01765f4ad7406e8df8de1da4998497bc9223e131206d2439b35e7152994faac` |
| `selbrume_lighthouse_interior.png` | 1024×1024 | 25 | `66110d66d7f0c0dfbba293e0d8a18e688e0cb2379c4b117f503c1ab67adbd0df` |
| `selbrume_cabin_interior.png` | 512×512 | 20 | `ea0fa6dfdec99f3b9b03925036790b94789ee218b5a2dbf42606e9ea45cc020b` |
| `selbrume_lighthouse_fx.png` | 512×512 | 15 sorties / 9 éléments logiques | `a7440a14d84d04449f24d20246315db875452056616676c641c25557eca9a9e2` |

Les 138 modules acceptés, dimensions, prompts, références, variantes rejetées et hashes bruts/normalisés sont consignés dans `GENERATED_ASSET_PROMPTS.md`, `ATLAS_LAYOUTS.json` et `ASSET_PROVENANCE.md`.

### 6.2 Animation et alpha

- lumière instable : quatre frames, `160 ms` par frame ;
- étincelles : quatre frames, `120 ms` par frame ;
- brume, faisceau et halo conservent leur alpha partiel ;
- aucun résidu chroma vert n'est détecté dans les 15 sorties FX ;
- le sol bois v4 ne contient aucune ligne ni colonne entièrement transparente ; 30 pixels de bord transparents dispersés subsistent sans trou de plancher.

### 6.3 Blocage juridique

La génération locale ne résout pas la licence des références historiques. Aucun auteur, contrat de licence ou droit de redistribution n'est documenté pour les 35 sources préexistantes. La publication publique reste bloquée jusqu'à preuve vérifiable ou remplacement par des références propres/licenciées.

## 7. Fichiers modifiés — zones exactes

| Fichier | Zone | Raison et impact |
|---|---|---|
| `packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart` | `_usesBottomToTopTileLayerOrder`, `_isExplicitForegroundTileLayerForEditor`, boucles TileLayer et garde placed-element foreground | active l'ordre sérialisé uniquement pour `bottom_to_top`, conserve l'ordre legacy et rend `overhead`/`occlusion` devant les acteurs dans l'éditeur |
| `packages/map_runtime/lib/src/application/runtime_manifest_tilesets.dart` | `addPlacedElementVisualTilesetIds`, fin de `collectAllRuntimeTilesetIds` | collecte les tilesets principaux et overrides de frames des éléments placés ; évite des images manquantes au runtime |
| `packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart` | cache `_cachedVisibleTileLayersInPaintOrder`, `_visibleTileLayersInPaintOrder`, marqueurs foreground, `_paintPlacedElementsForLayer` | même opt-in d'ordre que l'éditeur, prise en charge `overhead`/`occlusion`, opacité couche × instance et skip des instances invisibles |
| `packages/map_runtime/test/map_layers_component_placed_element_render_test.dart` | test ajouté au groupe placed-element | non-régression : une instance à opacité zéro ne rend aucun pixel |
| `packages/map_runtime/test/map_layers_component_render_pass_test.dart` | tests ajoutés après les contrats de passe historiques | prouve `overhead`/`occlusion` en foreground et l'ordre de deux placed-elements en legacy comme en `bottom_to_top` |
| `packages/map_runtime/test/runtime_manifest_tilesets_surface_layer_test.dart` | groupe renommé et test placed-element ajouté | couvre tileset principal, override de frame, ordre de rencontre et déduplication |
| `packages/map_runtime/test/p6_existing_selbrume_loadability_start_map_contract_test.dart` | lignes 13–81 | remplace les IDs historiques par les cartes/spawns canoniques et charge Bourg + Marais |
| `packages/map_runtime/test/p6_selbrume_beta_validator_pass_test.dart` | lignes 9–10 | start map canonique ; attente d'équipe historique volontairement conservée |
| `packages/map_runtime/test/p6_selbrume_first_narrative_interaction_test.dart` | lignes 9–48 | interaction repositionnée sur Bourg canonique |
| `packages/map_runtime/test/p6_selbrume_first_trainer_battle_golden_slice_test.dart` | lignes 13–168 | Grant repositionné sur Marais et request ID canonique ; équipe non réécrite |
| `packages/map_runtime/test/p6_selbrume_initial_party_bag_setup_test.dart` | ligne 10 | start map canonique |
| `packages/map_runtime/test/p6_selbrume_playable_runtime_smoke_test.dart` | lignes 10–11 | boot du Bourg canonique |
| `packages/map_runtime/test/p6_selbrume_route_1_encounter_capture_golden_slice_test.dart` | lignes 11–60 | remplace Route 1 par Marais et vérifie sa connexion au Bois |
| `packages/map_runtime/test/p6_selbrume_save_load_golden_slice_test.dart` | lignes 13–14 | sauvegarde/chargement avec IDs canoniques |
| `packages/map_runtime/tool/shadow/selbrume_shadow_capture_test.dart` | ligne 22 | carte par défaut canonique pour la capture shadow |
| `selbrume/project.json` | catalogue, groupes, dossiers/tilesets/éléments, bindings de scénarios/cinématique | cutover exact vers dix cartes et six groupes, enregistrement des atlas et migration des références actives |

Le diff exact de ces fichiers est reproductible avec :

```bash
git diff -- packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart \
  packages/map_runtime selbrume/project.json
```

Statistique finale de ce diff : 16 fichiers suivis, 10 557 insertions et 454
suppressions. Le volume vient principalement de la sérialisation complète du
manifeste `project.json`, pas d'une refonte des packages.

## 8. Fichiers créés — inventaire contenu-adressé

Les 34 fichiers texte créés hors rapport/annexe représentent 167 892 lignes et
3 130 740 octets. Leur contenu UTF-8 intégral est concaténé, avec marqueurs et
taille source, dans
`reports/gameplay/evidence/fg_181_selbrume_maps/created_text_files_full_content.txt`.
Le rapport et cette annexe restent eux-mêmes directement lisibles. Les 66 PNG
sont fournis byte pour byte ; les dix atlas sont hashés en section 6 et les 56
captures dans `capture_manifest.json`.

Annexe intégrale : 34 fichiers embarqués, 167 997 lignes, 3 136 651 octets,
SHA-256
`21641754a147a9fd9f8d6f439d8c8120f7da9f565df535ea784ba646231abdc4`.

### 8.1 Code, tests, outils et documentation

| Fichier complet | Lignes | Octets | SHA-256 |
|---|---:|---:|---|
| `packages/map_editor/lib/src/application/services/raster_asset_grid_normalizer.dart` | 308 | 8 396 | `5f4bc35443b542d940e24029078edbf6f3f1280dfa8a4bec2e8258963aebb2c8` |
| `packages/map_editor/lib/src/application/services/tileset_atlas_builder.dart` | 245 | 6 943 | `8bf8b75855a9d055b095b56ec223a384a06a7c816b375ff9717c2c9ee5fe8b79` |
| `packages/map_editor/test/map_grid_painter_layer_order_test.dart` | 318 | 9 372 | `4d42d2016642a8a900d3240dd1807c7889324e5951a7b61574971b1be777325b` |
| `packages/map_editor/test/raster_asset_grid_normalizer_test.dart` | 743 | 23 620 | `85319e41246b20c0f0ea26bf466b0e9e8b5dd8b7d4f027cbaf3a3bb74f9ad0e1` |
| `packages/map_editor/test/selbrume_editor_repository_roundtrip_test.dart` | 255 | 9 256 | `770aac17cf0867c1df3271f6faa477cbfc716e05aa99a93a2fc26ffce7b617a0` |
| `packages/map_editor/test/selbrume_project_roundtrip_test.dart` | 8 115 | 254 875 | `8bb50c3efe5ad094f71fb1bf6dc545d14e66a0c6336f82df7a9351eb404fd437` |
| `packages/map_editor/test/tileset_atlas_builder_test.dart` | 706 | 20 713 | `e749477d6838ee13c87639489ca97b6aca405aa27beeee83987cf5f1f86f905b` |
| `packages/map_editor/test/tileset_palette_recommended_layer_test.dart` | 146 | 4 595 | `78dcaea1982a866c056fa038cbf394b8b1e3d8d294f79038c19d1ed27f11e729` |
| `packages/map_editor/tool/build_tileset_atlas.dart` | 297 | 9 448 | `743023954b95b666ea224ccef5081f44db6b4d6ecb5822d21397e7a1cb49ae46` |
| `packages/map_editor/tool/generate_selbrume_canonical_maps.dart` | 11 183 | 356 373 | `d40697c3667bae8f502dc2375ace1a1bc50d6318fdeb172a4934c6ffe3a9d970` |
| `packages/map_editor/tool/normalize_tileset_asset.dart` | 265 | 8 126 | `ed8c7afb8a1b116637f092d5b789a63fb38e2d88c3848d61634c08ad220f389d` |
| `packages/map_runtime/test/selbrume_asset_integrity_contract_test.dart` | 3 491 | 117 584 | `3c4bb977914aefc9a87c4d92379bff9facec6667276e80ad7fa712ed46c5e665` |
| `packages/map_runtime/test/selbrume_interior_layer_contract_test.dart` | 198 | 6 950 | `54e3e30cf13776ef1f196cf571c39bc659e38162de692f13e2859d420c4e6e66` |
| `packages/map_runtime/test/selbrume_map_catalog_integrity_test.dart` | 1 739 | 55 430 | `a9cadf90d4ba6c349419c6a2b238dc26a4aec7542a3854d6cde3d9a3d0e6fa7e` |
| `packages/map_runtime/test/selbrume_map_navigation_contract_test.dart` | 2 112 | 67 111 | `bf3f80a299e32d43f691f7cc16b84755d36f3ccabf96d375dcc1fca634c40be4` |
| `packages/map_runtime/test/selbrume_map_render_smoke_test.dart` | 1 041 | 34 892 | `5c3c8949ca7f5810dc565dd0b9fe1d2a9d17b5d7a87217ae37feba46270d3aa6` |
| `packages/map_runtime/test/support/selbrume_map_test_fixture.dart` | 253 | 8 953 | `41036bb6258498f4eb9b79d4a58f320dc86a00b7109595176fb19be49c02886d` |
| `packages/map_runtime/tool/selbrume_map_capture_test.dart` | 846 | 25 392 | `8a11d99e3d213c22ec61a97177df4292435c4a55661fe4c9b47cb87a0bbe4d98` |
| `selbrume/assets/ASSET_PROVENANCE.md` | 253 | 40 999 | `97b2fb2ade56e7ce9387eebb909e126dbe6c3c087b0d51ef7804d5c54c1fd944` |
| `selbrume/assets/ATLAS_LAYOUTS.json` | 207 | 18 180 | `df9cad1a3ea241822972e78e980975edb0d19095fe800b7f7976ee2df949eb34` |
| `selbrume/assets/GENERATED_ASSET_PROMPTS.md` | 270 | 102 785 | `f5c518079a279906bd7d587d756192957587396c77c6908fda56ebd8a8eb1eef` |
| `selbrume/docs/map_production/legacy_map_inventory.md` | 89 | 7 673 | `4350844f1a27c188991796034cd3419804374fb9cdf76f6372137a51db200d6a` |
| `selbrume/docs/map_production/selbrume_map_blueprints.md` | 905 | 51 929 | `291c51cfe4dd44f2edccaeea1e7e5e736129ced5ce3cc0ad19e742dc1db95eda` |
| `reports/gameplay/evidence/fg_181_selbrume_maps/capture_manifest.json` | 909 | 28 611 | `3a28f9b00d68752bc8a35228e5b135763d7137352af2b0690f86e9be89d993f2` |

### 8.2 Cartes JSON complètes

| Fichier complet | Lignes | Octets | SHA-256 |
|---|---:|---:|---|
| `selbrume/maps/map_bois_chaise_brume.json` | 16 621 | 223 192 | `167d896a23b73cdcfd62ccfc3f19c95e98245470cbcb897dd2a3fbdc45cc381d` |
| `selbrume/maps/map_bourg_selbrume.json` | 29 040 | 433 274 | `b9fdf3a6c06cc9e8f439596a85a06eeaf7ba45ca4a4b1cd7d2b80e7bb7a7cda3` |
| `selbrume/maps/map_cabane_gardien.json` | 3 176 | 48 820 | `b686d509870cdda60810dbb54bce065d14f5f9442193c1ba0c095cb570c8a76a` |
| `selbrume/maps/map_maison_joueur.json` | 3 086 | 46 584 | `e300d40f2a8a9cca2b4755fc9ca7770c13bf843f969140667fd8155f7a99cd65` |
| `selbrume/maps/map_marais_salants.json` | 17 011 | 230 260 | `bc0cf7a77344540b109a3ac24dc46022624fc29d169c998589ff14c32f63864b` |
| `selbrume/maps/map_passage_dames.json` | 11 895 | 156 751 | `6630da6bdfa82a34337c439cc1db36c4cb4713276cff2950da137255680c9f1b` |
| `selbrume/maps/map_phare_exterieur.json` | 16 566 | 218 514 | `3a5dbbf9715a79b5a01893531bfeacfd2ff5adda8d32b50682970ea6e7a55313` |
| `selbrume/maps/map_phare_interieur.json` | 14 187 | 206 701 | `0ab7f3a813d3bdbcef0b4161a592ae52f4e76d6a9ce1c8e288c88672eeca12b9` |
| `selbrume/maps/map_port_brisants.json` | 16 845 | 225 951 | `4061c06d11b863e176dd47e7fa2bd2649e1eb672cfa2d2da27a34c8c83ab8198` |
| `selbrume/maps/map_sommet_phare.json` | 4 571 | 62 487 | `1b9eae347e9aef85e392e7ce2fcf5c96a614476dd093468be92ab67550e43ecb` |

### 8.3 PNG complets

- dix sorties atlas : liste exhaustive et hashes en section 6.1 ; total `3 193 548` octets ;
- 56 preuves visuelles : 10 overviews, 10 collisions et 36 crops ; total `10 736 492` octets ;
- chaque nom, taille en octets et SHA-256 des 56 preuves est listé dans `capture_manifest.json` ;
- aucun fichier temporaire ImageGen ou golden-failure n'est conservé.

### 8.4 Méta-artifacts de preuve

- `reports/gameplay/fg_181_selbrume_map_asset_foundation.md` : le présent
  rapport, dont le contenu complet est directement disponible ici ;
- `reports/gameplay/evidence/fg_181_selbrume_maps/created_text_files_full_content.txt` :
  annexe intégrale décrite et hashée au début de la section 8.

## 9. Tests créés ou modifiés

Couvertures positives : chargement des dix maps, catalogue exact,
connexions/warps, rendu de chaque carte, frame d'asset, round-trip et
idempotence Task 4→16, captures, ordre de couches legacy/opt-in et sélection
no-code du `recommendedLayerId`.

Couvertures négatives : chemins absolus/traversal/symlink, PNG
absent/malformé/RGB, dimensions incohérentes, collision incohérente,
référence legacy non migrable, downgrade de frontière, output existant et
image indécodable.

Garde-fous/non-régressions : seeds fingerprintées, écritures
atomic/manifest-last, aucun underlay interdit, aucun bord de carte ouvert sans
connexion, opacité d'instance, frame override de tileset, fichiers legacy
byte-identiques, comportement d'ordre historique inchangé sans opt-in. La
liste blanche legacy normalise aussi les formes Unicode NFC/NFD afin qu'un nom
historique accentué soit reconnu de façon portable sans élargir le catalogue.

Le vrai round-trip éditeur utilise `FileProjectRepository` et
`FileMapRepository` sur une copie temporaire : charge, sauvegarde et recharge
le manifeste et les dix maps, vérifie l'égalité sémantique et prouve que les
onze fichiers source du worktree restent byte-identiques.

## 10. Commandes et résultats exacts

### 10.1 Génération et intégrité

```bash
dart run packages/map_editor/tool/generate_selbrume_canonical_maps.dart --project-root selbrume --through task16 --write
dart run packages/map_editor/tool/generate_selbrume_canonical_maps.dart --project-root selbrume --through task16 --check
```

Résultat final du check : exit `0`, `Selbrume task16 output is up to date.`

```bash
find selbrume -type f -name '*.json' -print0 | xargs -0 -n1 jq empty
git diff --check
```

Résultats : 3 759 JSON parsés sans erreur ; catalogue actif de 10 maps / 6
groupes ; zéro référence active aux IDs legacy ; 23 fichiers Dart ciblés déjà
formatés ; `git diff --check` sans sortie.

### 10.2 Suites ciblées du lot

```bash
cd packages/map_editor && flutter test --no-pub \
  test/raster_asset_grid_normalizer_test.dart \
  test/tileset_atlas_builder_test.dart \
  test/selbrume_project_roundtrip_test.dart \
  test/selbrume_editor_repository_roundtrip_test.dart \
  test/map_grid_painter_test.dart \
  test/map_grid_painter_layer_order_test.dart \
  test/tileset_palette_recommended_layer_test.dart
```

Exit `0`, `+117`, `All tests passed!`

Deux écarts découverts par la critique ont été fermés : les quatre intérieurs
ont maintenant sept couches exactes, et le round-trip emploie les vrais
repositories fichier. Les cinq attentes historiques Task 8/13/14/15 ont été
alignées sans affaiblir leurs sentinelles ; le gros test générateur passe seul à
`+50`.

```bash
cd packages/map_runtime && flutter test --no-pub \
  test/selbrume_asset_integrity_contract_test.dart \
  test/selbrume_interior_layer_contract_test.dart \
  test/selbrume_map_catalog_integrity_test.dart \
  test/selbrume_map_navigation_contract_test.dart \
  test/selbrume_map_render_smoke_test.dart
```

Exit `0`, `+85`, `All tests passed!`

```bash
cd packages/map_runtime && flutter test --no-pub \
  test/selbrume_interior_layer_contract_test.dart \
  test/map_layers_component_placed_element_render_test.dart \
  test/runtime_manifest_tilesets_surface_layer_test.dart \
  test/map_layers_component_render_pass_test.dart
```

Exit `0`, `+12`, `All tests passed!`. Cette gate prouve notamment deux
placed-elements superposés en ordre legacy puis `bottom_to_top`, ainsi que les
marqueurs `overhead`/`occlusion` en foreground.

```bash
cd packages/map_gameplay && dart test \
  test/placed_elements_collision_test.dart \
  test/runtime_movement_collision_regression_test.dart \
  test/collision_building_golden_slice_test.dart
```

Exit `0`, `+21`, `All tests passed!`

```bash
cd packages/map_runtime && flutter test --no-pub test/phase_a_golden_battle_slice_smoke_test.dart
```

Exit `0`, `+3`, `All tests passed!`

### 10.3 Suites complètes

| Package / commande | Résultat exact |
|---|---|
| `packages/map_core — dart test` | exit `0`, `+2652`, all passed |
| `packages/map_core — dart analyze` | exit `0`, no issues |
| `packages/map_gameplay — dart test` | exit `0`, `+240`, all passed |
| `packages/map_gameplay — dart analyze` | exit `0`, no issues |
| `packages/map_runtime — flutter test --no-pub` | exit `1`, `+1593 -4` (1 597 tests) |
| `packages/map_runtime — flutter analyze --no-pub` | exit `1`, 347 infos, 0 warning, 0 error |
| `packages/map_editor — flutter test --no-pub` | exit `1`, `+2618 -85` |
| `packages/map_editor — flutter analyze --no-pub` | exit `1`, 454 diagnostics : 81 errors, 10 warnings, 363 infos |
| `examples/playable_runtime_host — flutter test --no-pub test/phase_a_golden_slice_launch_test.dart` | exit `0`, `+1`, all passed |
| `examples/playable_runtime_host — flutter test --no-pub` | exit `0`, `+48`, all passed |
| `examples/playable_runtime_host — flutter analyze --no-pub` | exit `1`, une info `prefer_const_constructors` dans `test/runtime_pokedex_loader_test.dart:31` |

Les quatre échecs runtime complets ont été reproduits et correspondent
exactement aux quatre baselines déjà observées :

1. `map_layers_component_path_pattern_render_test.dart:152` : frame bleue attendue, frame rouge initiale reçue ;
2. `path_pattern_water_animated_runtime_golden_slice_test.dart:109` : frame magenta attendue, frame rouge initiale reçue ;
3. `p6_selbrume_beta_validator_pass_test.dart:130` : `metapod` attendu, `dratini` réel ;
4. `p6_selbrume_first_trainer_battle_golden_slice_test.dart:67` : même divergence d'équipe.

Les deux PathPattern concernent des zones non modifiées. Les deux divergences d'équipe existaient avant SEL-MAP-001 et n'ont volontairement pas été maquillées. La relance des huit P6 se termine à `+6 -2`, uniquement sur ces deux attentes d'équipe.

La suite éditeur complète a une baseline historique large (Pokémon SDK/API,
UI/goldens, ombres, Narrative Studio et design system). Aucun des tests
d'ordre, de palette, d'intérieur ou de round-trip Selbrume ne figure dans les
85 échecs. Un golden Storylines lisant le manifeste réel dérive de 0,79 % et
1,06 % ; l'inspection montre la même structure narrative et une dérive de
rasterisation, sans preuve d'une régression map. Les 92 PNG diagnostics produits
par les goldens rouges ont été supprimés après inspection.

## 11. Builds

La commande Flutter standard a été tentée sur les deux applications :

```bash
flutter build macos --release --no-pub
```

Elle échoue dans Flutter beta `3.46.0-0.3.pre`, target `release_unpack_macos`. Le SDK appelle `lipo <binary> -verify_arch arm64 x86_64`, tandis que le `lipo` Xcode installé n'accepte qu'une architecture par vérification. `lipo -info` confirme pourtant que `FlutterMacOS` contient bien `x86_64 arm64`. Ce blocage précède le code produit.

Meilleure validation alternative, en forçant l'architecture active :

```bash
xcodebuild -workspace macos/Runner.xcworkspace -scheme Runner \
  -configuration Release -derivedDataPath build/macos \
  ARCHS=arm64 ONLY_ACTIVE_ARCH=YES CODE_SIGNING_ALLOWED=NO build
```

Résultats :

- runtime host : exit `0`, `** BUILD SUCCEEDED **`, app arm64 produite à `examples/playable_runtime_host/build/macos/Build/Products/Release/playable_runtime_host.app` ;
- editor : exit `0`, `** BUILD SUCCEEDED **`, app arm64 produite à `packages/map_editor/build/macos/Build/Products/Release/map_editor.app`.

Les deux exécutables sont confirmés `Mach-O 64-bit executable arm64` par
`file` et `lipo`; le host est aussi confirmé `ARM64 ... EXECUTE` par
`otool -hv`. Aucun wrapper ou changement SDK temporaire n'est conservé dans le
dépôt. Les DerivedData restent sous `build/`, ignorés par Git.

## 12. QA visuelle

Le harnais `selbrume_map_capture_test.dart` passe (`+1`) et produit :

- 10 overviews ;
- 10 overlays de collision ;
- 36 crops nommés ;
- 56 PNG au total ;
- manifeste SHA-256 `3a28f9b00d68752bc8a35228e5b135763d7137352af2b0690f86e9be89d993f2`.

Les dix overviews et les 21 preuves des quatre intérieurs ont été inspectés en
résolution originale. Aucun sprite manquant, halo chroma, trou noir ou
recouvrement du mobilier par le sol n'a été observé. Les collisions visibles
correspondent aux obstacles et les sorties restent marchables. Les 56 hashes du
manifeste ont été revérifiés contre les fichiers promus.

Le noir visible dans le crop de trappe et certains overlays correspond au
hors-map ou aux cellules que la passe collision ne dessine pas ; les overviews
opaques ne présentent pas ces zones comme des trous de carte.

Polish restant, non bloquant pour la bêta technique :

- joint de plancher d'environ 1 px dans Maison/Cabane ;
- Port et Bois volontairement aérés, avec de grandes zones peu décorées ;
- mer/void autour du phare encore plus plate que l'eau texturée des autres côtes.

## 13. Verdict des passes et sub-agents

| Passe | Verdict |
|---|---|
| Audit / Architecture | **READY** — inventaire legacy, frontières de package, topologie, IDs et non-objectifs documentés |
| Références Task 16 | **READY** — aucune référence legacy active supplémentaire à allowlister ; scénarios/cinématique migrés |
| Implémentation / Générateur | **READY** — Task 4→16, préflights, idempotence, sentinelles de downgrade et manifest-last |
| Assets / Captures | **READY technique** — 138 modules, 10 sorties, 56 preuves ; publication bloquée par licence |
| Tests purs | **READY** — map_core `+2652`, map_gameplay `+240`, analyses vertes |
| Runtime / Editor | **READY pour le lot** — gates Selbrume `+84` runtime et `+117` éditeur ; baselines globales rouges documentées |
| Build / Validation | **READY arm64** — deux apps Release construites par Xcode ; commande Flutter universelle bloquée par le SDK beta |
| Critique finale | **READY technique** — quatre objections initiales closes, annexe 34/34 byte-identique et aucune anomalie bloquante ; écart de mer du phare documenté |

## 14. Limites et risques restants

1. **Licence** : bloque une publication publique, même si la QA technique est verte.
2. **Sauvegardes pré-cutover** : aucune migration des IDs `Selbrume`/`route 1`.
3. **Contenu narratif** : triggers et zones de réservation restent volontairement inertes.
4. **États dynamiques** : portes, marée et lumière disposent de variantes visuelles, mais aucune logique narrative/fact ne les pilote dans ce lot.
5. **Baselines globales** : les suites runtime/editor complètes ne sont pas entièrement vertes ; aucune affirmation contraire n'est faite.
6. **Build universel** : le binaire arm64 est prouvé, pas un `.app` universel arm64+x86_64, à cause de la régression locale Flutter/Xcode.
7. **Performance manuelle** : aucune mesure FPS ou traversée humaine exhaustive n'est revendiquée ; les rendus et navigations sont prouvés par contrats et captures.
8. **Polish visuel** : fines coutures de modules de sol et zones volontairement aérées au Port, au Bois et au sommet ; non bloquant pour la fondation technique, visible dans les captures.
9. **Boucle marine** : le Phare extérieur conserve `dirth_path` sur sa couche secondaire et Bourg utilise encore le preset de base de la boucle ; l'usage « Port/Passage/Phare uniquement » du plan n'est donc pas exact dans cette matérialisation.

## 15. Auto-critique

- Le générateur (11 183 lignes) et son test round-trip (8 115 lignes) sont volumineux. Ils sont déterministes et fortement testés, mais gagneraient à être divisés par domaine/Task dans un lot de maintenance distinct.
- La production automatisée de cartes limite le risque de dérive JSON, mais rend toute retouche manuelle non durable tant qu'elle n'est pas répercutée dans le générateur.
- La QA visuelle est solide pour une fondation bêta, pas une direction artistique finale. Les zones aérées et le joint de sol doivent être traités par une passe artistique dédiée, sans mélanger mécaniques et contenu.
- Le cutover exact simplifie le runtime mais abandonne volontairement la compatibilité des anciennes sauvegardes ; cela doit être accepté ou migré avant une bêta distribuée à des testeurs existants.
- La première critique avait raison de refuser les hosts uniques des intérieurs et le faux round-trip. Les deux points sont maintenant couverts par contrats exacts et repositories réels ; cette reprise a aussi révélé le besoin d'un opt-in d'ordre de couches partagé éditeur/runtime.
- La suite éditeur globale reste rouge à `-85`. Les gates du lot sont vertes, mais ce résultat ne doit pas être présenté comme une santé globale du package.

## 16. Prochaines étapes proposées, non implémentées

1. Obtenir les preuves de licence ou remplacer les 35 références problématiques.
2. Faire une petite passe artistique sur Port, Bois, mer du phare et sol v4.
3. Décider d'une migration de sauvegarde des deux IDs historiques.
4. Réparer séparément les quatre baselines runtime et la baseline Pokémon SDK/editor.
5. Continuer FG-181 par les mécaniques manquantes, sans modifier la fondation map validée.

## 17. État Git à la clôture technique, avant intégration

`git status --short --untracked-files=all` compte 16 fichiers suivis modifiés et
102 fichiers non suivis : 34 sources texte/JSON/Dart/Markdown, le présent
rapport, l'annexe intégrale et 66 PNG. Aucun fichier temporaire ImageGen,
lockfile de validation, `.dart_tool` suivi ou PNG diagnostic de golden ne reste
dans le diff.

À ce point de contrôle, aucun fichier n'était stagé et aucun commit du lot
n'était créé. Le rebase/merge demandé ultérieurement est vérifié et rapporté
dans le handoff final de la tâche.
