# NS-SCENES-V1-93 — Cinematic Map Backdrop Layer Fidelity Prep Contract

Statut : `DONE`

Demande : prompt fourni par Karim. Karim a demandé de suspendre le Sprite Resolver Actor Display et de cadrer d'abord la fidélité du décor map, parce que la preview V1-92 reste trop incomplète visuellement côté chemins, terrains, surfaces, environnement et objets placés.

Phrase canonique :

```text
V1-93 prépare la fidélité visuelle complète du décor.
V1-93 ne code toujours pas le renderer.
```

Code généré :

```text
Aucun code Dart/Flutter généré. V1-93 produit uniquement des rapports et met à jour les roadmaps autorisées.
```

## 1. Résumé exécutif

V1-93 conclut que la preview Cinematic Builder actuelle est techniquement utile mais produit-incomplète : V1-89/V1-92 affichent surtout les `TileLayer` bitmap et les placeholders acteurs, tandis que le Map Editor compose la carte avec `TerrainLayer`, `PathLayer`, `TileLayer` en passes arrière/avant, `SurfaceLayer`, ombres, `MapPlacedElement` et plusieurs overlays d'édition à exclure.

L'option retenue pour V1-94 est l'Option E : un plan cinematic multi-layer dédié, editor-only/read-only, qui réutilise seulement des helpers purs ou extractibles du Map Editor, sans importer `MapCanvas`, `MapGridPainter` brut, runtime, Flame ou playback.

Prochain lot exact recommandé :

```text
NS-SCENES-V1-94 — Cinematic Map Backdrop Layer Fidelity Renderer V0
```

Le Sprite Resolver Actor Display est repoussé en :

```text
NS-SCENES-V1-95 — Cinematic Actor Display Preview Sprite Resolver Prep Contract
```

## 2. Gate 0

Commandes exécutées depuis la racine :

```bash
pwd
git branch --show-current
git status --short --untracked-files=all
git diff --stat
git diff --name-only
git log --oneline -n 15
```

Résultats exacts utiles :

```text
/Users/karim/Project/pokemonProject
main
```

`git status --short --untracked-files=all`, `git diff --stat` et `git diff --name-only` n'ont produit aucune sortie au Gate 0.

```text
9c5db6f0 feat(narrative): auto-commit changes
eb05d109 feat(narrative): auto-commit changes
3e767d80 feat(narrative): auto-commit changes
3a3689df feat(narrative): auto-commit changes
12e52f7a update selbrume
1ac4186f update selbrume
a085d128 feat(narrative): auto-commit changes
103cc837 feat(narrative): auto-commit changes
fd10cce7 feat(narrative): auto-commit changes
c730bef3 feat(narrative): auto-commit changes
3b73a8fd feat(narrative): auto-commit changes
587b47f6 update selbrume
50a43df8 feat(narrative): add cinematic map backdrop preview model, tests, and roadmap updates (NS-SCENES-V1-83)
c76550a6 feat(narrative): update cinematic workspaces, tests, and roadmap reports (NS-SCENES-V1-82)
e32d5f2a update screenshot failures for ns_scenes_v1_29_storyline_step_scene_link_v0
```

Note : le working tree était propre au début du lot. Toute modification produite par V1-93 est donc bornée aux fichiers `reports/narrativeStudio/scenes/` autorisés.

## 3. Fichiers lus

Consignes et roadmaps :

- `AGENTS.md`
- `agent_rules.md`
- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`

Rapports précédents :

- `reports/narrativeStudio/scenes/ns_scenes_v1_87_cinematic_map_backdrop_real_tile_rendering_prep_contract.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_88_cinematic_map_backdrop_real_tile_renderer_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_89_cinematic_map_backdrop_real_tile_renderer_integration_fidelity_polish_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_92_cinematic_actor_display_preview_renderer_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_92_evidence_pack.md`

Audit core/editor :

- `packages/map_core/lib/src/models/map_data.dart`
- `packages/map_core/lib/src/models/map_layer.dart`
- `packages/map_core/lib/src/models/project_manifest.dart`
- `packages/map_core/lib/src/models/project_path_pattern_preset.dart`
- `packages/map_core/lib/src/models/environment.dart`
- `packages/map_core/lib/src/models/surface.dart`
- `packages/map_core/lib/src/read_models/cinematic_map_backdrop_preview_model.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_tile_render_plan.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_tile_plan_loader.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_tile_renderer.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_actor_display_preview_overlay.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_viewport_transform.dart`
- `packages/map_editor/lib/src/ui/canvas/map_canvas.dart`
- `packages/map_editor/lib/src/ui/canvas/map_canvas/map_canvas_assets.dart`
- `packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart`
- `packages/map_editor/lib/src/features/surface_painter/surface_layer_static_preview.dart`
- `packages/map_editor/lib/src/features/surface_painter/surface_tile_preview_resolver.dart`
- `packages/map_editor/lib/src/application/use_cases/environment_generator_apply_use_cases.dart`

## 4. Synthèse des sub-agents et arbitrages

Sub-agent A — MapData layer semantics :

`MapData` sépare bien `layers`, `placedElements`, `entities`, events/triggers/warps et gameplay zones. Les `MapLayer` visuels pertinents sont `TileLayer`, `TerrainLayer`, `PathLayer`, `SurfaceLayer`, `ObjectLayer`, `EnvironmentLayer`; `CollisionLayer` reste debug/gameplay et doit être exclu du décor cinematic. A confirme que le plan bitmap actuel ne rend que les `TileLayer`, même si le read model sait projeter plus de familles en primitives.

Sub-agent B — Map Editor rendering parity :

Le Map Editor peint par familles et passes : terrain, path, tile background, surface, ombres, placed elements background, collision/grille/overlays édition, entités background, tile/placed foreground, entités foreground, puis outils/events/triggers/warps/connections. B recommande de ne pas réutiliser `MapGridPainter` brut, mais d'extraire ou reproduire des helpers purs.

Sub-agent C — Asset / catalog resolution :

`CinematicTilesetAssetRegistry` suffit comme cache bas niveau de tileset image, mais pas comme resolver métier. V1-94 a besoin d'un resolver multi-catalogues au-dessus pour transformer terrain/path/surface/placed element/environment en `tilesetId + sourceRect + diagnostics`.

Sub-agent D — Render plan contract :

D recommande l'Option E : `CinematicMapBackdropLayerRenderPlan` dédié, multi-layer, avec instructions typées, `layerIndex + localOrder`, diagnostics et fallback partiel. Le plan actuel `CinematicMapBackdropTileRenderPlan` est sain mais trop `TileLayer`-centric.

Sub-agent E — Runtime / Flame / MapCanvas anti-scope :

E confirme que `PlayableMapGame`, `RuntimeMapGame`, `GameWidget`, `FlameGame`, `CameraComponent`, `MapLayersComponent`, `GameState`, `loadRuntimeMapBundle`, `MapCanvas` et `MapGridPainter` brut sont hors scope. V1-94 doit rester `map_editor` editor-only/read-only.

Sub-agent F — Product / UX fidelity reviewer :

F fixe le seuil produit : la preview doit permettre de reconnaître Selbrume/la vraie map au premier coup d'oeil, en décor statique, avant les sprites acteurs. Les gaps non tolérables sont terrain/paths/placedElements absents, fallback silencieux, transparence cassée, ordre faux, ou wording qui vend un succès global.

Sub-agent G — Tests / Visual Gate / Evidence :

G recommande des fixtures neutres sans Selbrume/Lysa, tests de plan par famille, partial render, diagnostics asset-missing, wiring Library -> Builder, Visual Gate V1-94 dédiée et scans anti-scope/anti-Selbrume sur le diff.

Divergences identifiées :

- C recommande en fin d'audit un lot `Cinematic Multi-Catalog Asset Resolver V0` avec priorité acteurs cinématiques réels d'abord.
- Le prompt de Karim impose explicitement décor d'abord, sprite resolver après V1-94.
- B recommande un `EditorMapRenderPlan` partagé ; D recommande un plan cinematic multi-layer dédié.

Arbitrage final :

- La priorité acteurs d'abord est rejetée pour V1-94. V1-94 doit viser la fidélité backdrop, puis V1-95 préparera les sprites acteurs.
- Le plan peut s'inspirer d'un futur `EditorMapRenderPlan`, mais V1-94 doit livrer un contrat cinematic dédié pour réduire le risque de régression Map Editor.

Option retenue :

```text
Option E — plan cinematic multi-layer dédié + réutilisation de helpers purs du Map Editor.
```

## 5. Pourquoi V1-92 ne suffit pas côté fidélité map

V1-92 affiche les acteurs statiques, mais le décor visible reste celui de V1-89 : un rendu bitmap principalement limité aux `TileLayer`. Les autres familles de la vraie carte restent soit absentes, soit visibles seulement via fallback structurel/primitives.

Concrètement :

- `CinematicMapBackdropTileRenderPlan` parcourt `mapData.layers` et `continue` si le layer n'est pas `TileLayer`.
- Le loader V1-89 collecte les assets des `TileLayer` visibles uniquement.
- Le panel choisit le bitmap si `plan.hasBitmapInstructions`, ce qui remplace le fallback primitives et masque donc les familles non-Tile quand un bitmap tile existe.

Résultat produit : on peut dire "des tiles réelles s'affichent", mais pas encore "le décor projet complet s'affiche".

## 6. Objectif produit de la fidélité backdrop

V1-94 doit transformer la preview en décor statique crédible du projet :

- terrain et paths visibles avec assets réels quand disponibles ;
- tiles arrière/avant dans un ordre proche Map Editor ;
- surfaces résolues via `ProjectSurfaceCatalog` ;
- `MapPlacedElement` rendus via `ProjectElementEntry` ;
- placements générés d'environnement rendus comme `MapPlacedElement`, pas comme masque brut ;
- diagnostics visibles si une famille reste en fallback ;
- acteurs placeholders V1-92 préservés ;
- timeline et transports disabled préservés.

Wording recommandé :

- `Carte du projet (statique)`
- `Sans lecture`
- `Décor projet affiché` seulement si terrain + paths + tiles + éléments placés sont couverts.
- `Rendu partiel` avec diagnostics si une famille manque.

## 7. Pass A — MapData layer semantics

`MapData` contient `layers`, `placedElements`, `entities`, `connections`, `warps`, `triggers`, `gameplayZones` et `events`. Pour le décor cinematic, les sources exploitables sont :

- `TileLayer.tiles`
- `TerrainLayer.terrains`
- `PathLayer.cells` et `presetId`
- `SurfaceLayer.placements`
- `MapPlacedElement` via `layerId`, `elementId`, `pos`, `opacity`
- `EnvironmentLayer.content.generatedPlacementIds`, seulement comme lien vers des `MapPlacedElement`

Layers à rendre :

- `TileLayer`
- `TerrainLayer`
- `PathLayer`
- `SurfaceLayer`
- `MapPlacedElement` attachés aux `TileLayer`
- éventuellement `ObjectLayer` seulement si V1-94 confirme que des `MapPlacedElement.layerId` ciblent réellement ces layers comme décor.

Layers à exclure :

- `CollisionLayer`
- `EnvironmentLayer` comme masque brut
- entities/events/triggers/warps/connections/gameplay zones
- hover, selection, brush, grid d'édition, previews outils

Risque identifié :

Le read model V1-83/V1-85 projette les terrains sans filtrer `TerrainType.none`, alors que `MapGridPainter` ignore ce terrain. V1-94 doit corriger ce point dans son plan de rendu.

## 8. Pass B — Map Editor rendering parity

Pipeline Map Editor observé :

1. `TerrainLayer`
2. `PathLayer`
3. `TileLayer` background
4. `SurfaceLayer`
5. ombres projected/static
6. `MapPlacedElement` background
7. collision/grille/hover/gameplay zones et autres overlays d'édition
8. entities background
9. `TileLayer` foreground
10. `MapPlacedElement` foreground
11. entities foreground
12. sélection/outils/events/triggers/warps/connections/bordure

Pour la preview cinematic, conserver seulement :

```text
terrain -> path -> tileBackground -> surface -> shadows(optional) -> placedBackground -> actors V1-92 -> tileForeground -> placedForeground
```

Helpers réutilisables ou extractibles :

- `buildEditorForegroundTileCellIndicesByLayerId`
- `shouldPaintEditorTileCellInRenderPass`
- `shouldPaintEditorEntityInForegroundPass`
- `entityEditorPickFrame`
- résolution surface `resolveSurfaceTilePreviewInstruction`
- résolution path pattern editor
- résolution terrain preset frame
- instructions d'ombres statiques, si les dépendances restent pures

Dangereux :

- `MapCanvas` complet ;
- `MapGridPainter` brut, `part of map_canvas.dart` ;
- caches locaux sans diagnostics ;
- dépendances `EditorNotifier`, Riverpod, hover/selection/outils.

## 9. Pass C — Asset / catalog resolution

Assets requis :

- `ProjectTilesetEntry.relativePath`, `transparentColor`, tile metrics projet ;
- `ProjectSurfaceCatalog` : preset -> animation -> atlas -> tilesetId + `SurfaceAtlasGeometry.tileSize` ;
- `ProjectElementEntry.frames` pour `MapPlacedElement` et environnement généré ;
- `ProjectTerrainPreset.tilesetId` et variants ;
- `ProjectPathPreset` + `ProjectPathPatternPreset` + center pattern frames ;
- plus tard V1-95 : `ProjectCharacterEntry` pour sprites acteurs.

Conclusion :

`CinematicTilesetAssetRegistry` V1-89 doit rester bas niveau : charger/décoder un tileset image, appliquer `transparentColor`, valider métriques. V1-94 doit ajouter au-dessus un resolver multi-catalogues qui produit des requêtes normalisées :

```text
catalogKind, ownerId, tilesetId, sourceRectPx, destinationRectPx, logicalTileSize, opacity, diagnostics
```

Diagnostics futurs :

- `missingTerrainPreset`
- `missingPathPatternPreset`
- `missingPathBasePreset`
- `missingSurfacePreset`
- `missingSurfaceAnimation`
- `missingSurfaceAtlas`
- `missingElement`
- `missingElementFrame`
- `sourceRectOutOfBounds`
- `transparentColorConflict`

## 10. Pass D — Render plan contract

Le plan actuel :

- contient `CinematicMapBackdropBitmapInstruction` avec `tileId`, `tilesetId`, `sourceRect`, `destinationRect`, `opacity`, `zOrder` ;
- contient `CinematicMapBackdropTileRenderPlan` avec `tilesets`, `instructions`, `diagnostics` ;
- ignore tout layer non-`TileLayer` ;
- incrémente `zOrder` par tuile.

Contrat recommandé V1-94 :

```text
CinematicMapBackdropLayerRenderPlan
  mapWidth/mapHeight/tileWidth/tileHeight
  layers[]
  assets[]
  diagnostics[]
  hasBitmapInstructions

CinematicMapBackdropRenderLayer
  layerId
  label
  kind
  sourceLayerIndex
  pass
  opacity
  instructions[]
  diagnostics[]

CinematicMapBackdropLayerInstruction
  id
  layerId
  kind
  sourceRef
  tilesetId
  sourceRect
  destinationRect
  opacity
  layerOrder
  localOrder
  diagnosticRefs
```

Le painter V1-94 ne doit pas charger. Il ne reçoit que des images déjà résolues et des instructions prêtes à peindre.

## 11. Pass E — Runtime / Flame / MapCanvas anti-scope

Interdits V1-94 :

- `package:map_runtime/map_runtime.dart`
- `package:flame/...`
- `GameWidget`
- `FlameGame`
- `PlayableMapGame`
- `RuntimeMapGame`
- `CameraComponent`
- `MapLayersComponent`
- `PlayerComponent`
- `OverworldActorComponent`
- `GameState`
- `RuntimeMapBundle`
- `loadRuntimeMapBundle`
- `MapCanvas`
- `MapGridPainter` brut/couplé
- `Timer`, `Ticker`, `AnimationController`, playback/scrub/seek

Raison :

La preview cinematic est un outil authoring statique, pas une instance gameplay. Importer runtime ou MapCanvas complet injecterait sélection, outils, état éditeur, input, assets/caches et risques de mutation non nécessaires.

## 12. Pass F — Product / UX fidelity review

Seuil acceptable V1-94 :

- la map doit être reconnaissable comme vraie composition de carte ;
- les familles visuelles majeures doivent apparaître si les assets existent ;
- un fallback doit être nommé, pas silencieux ;
- la timeline et l'inspecteur restent visibles ;
- les acteurs statiques V1-92 ne doivent pas masquer le diagnostic décor.

Gaps tolérables :

- pas de pixel-perfect MapCanvas ;
- animation eau/path figée à une frame statique déterministe ;
- ombres légèrement différentes ou absentes si la silhouette reste lisible ;
- surfaces absentes seulement si la map n'en a pas, avec diagnostic pour future map.

Gaps non tolérables :

- preview majoritairement vide alors que les assets existent ;
- terrain/paths/placedElements absents ;
- transparence magenta visible ;
- ordre de couches faux ;
- données Selbrume hardcodées ;
- passage aux sprites acteurs avant le décor.

## 13. Pass G — Tests / Visual Gate / Evidence

Fixtures V1-94 recommandées :

```text
map_neutral_backdrop_stage
cinematic_neutral_extended_backdrop
tileset_neutral_ground
tileset_neutral_props
terrain_base
path_crossing
tile_ground
surface_marks
object_props
environment_patch
terrain_meadow_test
path_cobble_test
surface_leaf_test
prop_crate_test
environment_area_test
```

Tests requis V1-94 :

- plan multi-layer produit des instructions terrain/path/surface/placedElements ;
- ordre strict des passes ;
- partial render si une famille manque ;
- diagnostics par famille asset manquante ;
- fallback structurel seulement si aucun bitmap exploitable ;
- Library charge les assets étendus et passe le plan au Builder ;
- non-mutation `ProjectManifest` / `MapData` ;
- collisions/events/entities/triggers/warps/gameplay zones exclus ;
- scans anti-Selbrume sur le diff.

Visual Gate future :

```text
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_94_cinematic_extended_map_backdrop_visual_gate_v0.png
```

## 14. Options techniques comparées

Option A — Étendre uniquement TileRenderPlan :

Simple mais fragile. Le contrat et les noms restent centrés tiles ; y mélanger terrain/path/surface/placedElements rendrait les diagnostics et l'ordre de passe opaques.

Option B — Créer un LayerRenderPlan dédié :

Bonne base. Nécessite cependant un resolver multi-catalogues et des helpers purs pour éviter de recopier `MapGridPainter`.

Option C — Extraire un renderer read-only commun :

Fidélité potentiellement forte, mais scope risqué si on extrait directement depuis le painter massif. À réserver à de petits helpers purs.

Option D — Brancher MapCanvas complet :

Rejetée. Trop couplée à Riverpod, édition, sélection, outils, widgets et mutations.

Option E — Hybride recommandé :

Retenue. Plan cinematic multi-layer dédié, helpers purs quand disponibles, registry bas niveau conservé, aucun runtime/Flame/MapCanvas complet.

## 15. Option retenue

Option E est retenue.

V1-94 doit créer/étendre un contrat de rendu cinematic dédié, pas transformer le Builder en clone du Map Editor et pas appeler le runtime. Le rendu doit rester statique, déterministe, testable et diagnostiqué par famille.

## 16. Contrat recommandé V1-94

V1-94 doit :

- introduire un plan de rendu multi-layer ou remplacer progressivement le plan tile-only ;
- produire des instructions bitmap typées ;
- résoudre les catalogues indirects avant paint ;
- préserver partial render ;
- conserver fallback structurel si rien n'est peignable ;
- afficher diagnostics par famille ;
- intégrer le plan dans le Builder/Library sans mutation.

V1-94 ne doit pas :

- importer runtime/Flame ;
- brancher `MapCanvas` ou `MapGridPainter` brut ;
- charger des images dans `build()`/`paint()` ;
- hardcoder Selbrume ;
- démarrer les sprites acteurs ;
- démarrer playback/timeline runtime.

## 17. Layers à rendre en V1-94

Priorité V1-94 :

1. `TerrainLayer` : cellules non-`TerrainType.none`.
2. `PathLayer` : cellules actives, preset/path pattern résolu.
3. `TileLayer` background.
4. `SurfaceLayer` : placements via `ProjectSurfaceCatalog`.
5. `MapPlacedElement` background.
6. `TileLayer` foreground.
7. `MapPlacedElement` foreground.

Optionnel si le contrat reste petit :

- ombres statiques/projetées si helpers déjà purs et assets disponibles.

## 18. Layers explicitement exclus

Exclus du décor V1-94 :

- `CollisionLayer`
- `EnvironmentLayer` mask brut
- `MapEntity` gameplay/NPC/trainer sprites
- events
- triggers
- warps
- connections
- gameplay zones
- grid/hover/selection
- environment brush/cursor
- tool preview
- runtime player/actors

## 19. Contrat d'asset resolution

Le resolver V1-94 doit rester editor-only et produire des résultats immutables.

Entrées :

- `MapData`
- `ProjectManifest`
- paths tileset déjà accessibles côté editor
- registry/cache V1-89 bas niveau

Sorties :

- instructions prêtes à peindre ;
- assets résolus par tileset ;
- diagnostics contextualisés.

Le registry V1-89 reste chargé de :

- vérifier l'entrée tileset ;
- lire le fichier ;
- décoder l'image ;
- appliquer `transparentColor` ;
- valider tile size/empty image.

Le resolver multi-catalogues prend en charge :

- terrain -> preset -> frame ;
- path -> path preset/pattern -> frame ;
- surface -> catalog preset/animation/atlas -> source rect ;
- placed element -> element frame ;
- environment generated placement -> placed element.

## 20. Contrat layer ordering

Ordre canonique futur recommandé :

```text
terrain
path
tileBackground
surface
shadow
placedBackground
actorOverlayV1-92
tileForeground
placedForeground
```

Le foreground split doit s'inspirer de la logique Map Editor/runtime :

- cellules collision : background ;
- cellules non-collision d'un élément multi-cellules : foreground ;
- `TileLayer` explicitement foreground : foreground ;
- actor overlay V1-92 entre background et foreground pour que les éléments hauts puissent repasser devant plus tard.

## 21. Fallbacks et diagnostics futurs

Règle :

```text
Une famille manquante ne doit pas faire disparaître les familles disponibles.
```

Exemples :

- terrain asset manquant -> tiles/path/surface/placedElements restent visibles ;
- surface atlas manquant -> surface en diagnostic ou fallback local ;
- tileset de base manquant -> fallback structurel global autorisé ;
- environment layer sans generated placements -> diagnostic source, pas masque faux.

## 22. Préservation Actor Display V1-92

V1-94 doit conserver :

- `CinematicActorDisplayPreviewModel`
- overlay placeholders statiques ;
- labels courts ;
- direction hints `actorFace` ;
- acteurs non-renderables hors map ;
- `IgnorePointer` overlay ;
- diagnostics acteurs séparés des diagnostics décor.

V1-94 ne doit pas :

- remplacer les placeholders par sprites ;
- charger Character Library sprites ;
- interpoler `actorMove` ;
- ajouter `currentTimeMs` / `playbackTimeMs` / `isPlaying`.

## 23. Préservation timeline / transports / pickers

La timeline par pistes doit rester proportionnée et visible.

Les transports restent disabled/placeholders, sans lecture.

Les pickers stage/map/actors restent authoring-only.

Les diagnostics backdrop ne doivent pas pousser la timeline hors écran ni réintroduire le problème de proportions signalé par Karim.

## 24. Non-objectifs confirmés

V1-93 n'a pas :

- modifié `packages/` ;
- codé de renderer ;
- créé de test ;
- généré de screenshot ;
- modifié Selbrume ;
- lancé runtime ;
- importé Flame ;
- ajouté playback ;
- utilisé image IA ou `gpt-image-2`.

## 25. Tests futurs V1-94

Commandes futures recommandées :

```bash
cd packages/map_core && dart test --reporter=compact test/cinematic_map_backdrop_preview_model_test.dart
cd packages/map_editor && flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --plain-name 'builds extended backdrop bitmap instructions for neutral terrain path surface environment and placed elements'
cd packages/map_editor && flutter test --reporter=compact test/cinematics_library_workspace_test.dart --plain-name 'wires project extended backdrop assets into builder without mutating project data'
cd packages/map_editor && flutter analyze --no-fatal-infos <fichiers V1-94 touchés>
```

Scans futurs recommandés :

```bash
git diff --name-only -- packages/map_runtime packages/map_gameplay packages/map_battle examples selbrume
git diff -- packages/map_editor packages/map_core | rg -n "Selbrume|Lysa|Mael|Maël|bourg_selbrume|port_brisants|package:flame|FlameGame|GameWidget|PlayableMapGame|RuntimeMapGame|GameState|startPlayback|isPlaying|Timer\\(|Ticker|MapCanvas\\(|MapGridPainter\\(|Color\\(0x|Colors\\."
```

## 26. Visual Gate future V1-94

Commande future :

```bash
cd packages/map_editor && flutter test --update-goldens --dart-define=NS_SCENES_V1_94_CAPTURE_CINEMATIC_EXTENDED_MAP_BACKDROP=true --reporter=compact test/cinematic_builder_workspace_test.dart --plain-name 'captures V1-94 cinematic extended map backdrop visual gate when requested'
```

La capture doit montrer :

- décor bitmap étendu ;
- timeline visible ;
- inspecteur visible ;
- `Carte du projet (statique)` ou wording équivalent ;
- `Sans lecture` ;
- aucun runtime/playback ;
- aucune donnée Selbrume hardcodée.

## 27. Roadmaps mises à jour

Roadmaps à jour dans ce lot :

- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`

Changement :

- V1-93 devient `Cinematic Map Backdrop Layer Fidelity Prep Contract` et passe `DONE`.
- V1-94 devient le renderer fidelity backdrop recommandé.
- V1-95 devient le Sprite Resolver Actor Display Prep Contract.

## 28. Commandes exécutées

Commandes principales :

```bash
pwd
git branch --show-current
git status --short --untracked-files=all
git diff --stat
git diff --name-only
git log --oneline -n 15
rg -n "class .*Layer|TileLayer|TerrainLayer|PathLayer|SurfaceLayer|EnvironmentLayer|ObjectLayer|MapPlacedElement|placedElements|EnvironmentLayerContent|EnvironmentAreaMask" packages/map_core/lib/src packages/map_editor/lib/src
rg -n "drawImageRect|paint.*Layer|paintTile|paintTerrain|paintPath|paintSurface|paintEnvironment|paintPlaced|MapGridPainter|MapCanvas" packages/map_editor/lib/src/ui packages/map_editor/lib/src/features
rg -n "ProjectSurfaceCatalog|SurfaceCatalog|surfaceCatalog|surface.*atlas|paintSurfaceLayerAtlasTilePreview" packages/map_core packages/map_editor
rg -n "ProjectPathPatternPreset|pathPattern|path.*preset|resolvePathPatternVisual|PathLayer" packages/map_core packages/map_editor
rg -n "EnvironmentPaletteItem|environmentPalette|environment.*asset|generatedPlacement|EnvironmentLayer" packages/map_core packages/map_editor
rg -n "CinematicMapBackdropTileRenderPlan|CinematicMapBackdropBitmapInstruction|CinematicTilesetAssetRegistry|CinematicMapBackdropTileRenderPainter|tileMetricMismatch|noBitmapInstructions" packages/map_editor/lib/src/ui/canvas/cinematics
rg -n "PlayableMapGame|RuntimeMapGame|GameWidget|FlameGame|CameraComponent|MapLayersComponent|GameState|map_runtime|currentTimeMs|playbackTimeMs|isPlaying" packages/map_editor packages/map_runtime
```

Vérifications finales listées dans l'Evidence Pack.

## 29. Checks anti-scope

Checks attendus après rédaction :

```bash
git diff --name-only -- packages
git diff --check
git diff --stat
git diff --name-only
git status --short --untracked-files=all
```

Résultat attendu pour `git diff --name-only -- packages` :

```text

```

Les termes runtime/Flame/MapCanvas peuvent apparaître uniquement dans non-objectifs, audit anti-scope, options rejetées ou contrat futur.

## 30. Evidence Pack

Evidence Pack :

```text
reports/narrativeStudio/scenes/ns_scenes_v1_93_evidence_pack.md
```

Il contient Gate 0, fichiers lus, synthèses de sub-agents, recherches structurantes, arbitrage, hunks roadmaps, checks anti-scope et statut git final.

## 31. Auto-review critique

1. V1-93 a-t-il modifié du code produit ? Non.
2. V1-93 a-t-il modifié `packages/` ? Non.
3. V1-93 a-t-il créé un test ? Non.
4. V1-93 a-t-il généré un screenshot ? Non.
5. V1-93 a-t-il modifié Selbrume ? Non.
6. V1-93 a-t-il codé un renderer ? Non.
7. V1-93 a-t-il branché MapCanvas ? Non.
8. V1-93 a-t-il utilisé le runtime ? Non.
9. V1-93 a-t-il importé Flame ? Non.
10. V1-93 a-t-il ajouté du playback ? Non.
11. V1-93 a-t-il identifié les layers manquants ? Oui.
12. V1-93 a-t-il identifié terrain/path/surface/environment ? Oui.
13. V1-93 a-t-il identifié les assets/catalogues requis ? Oui.
14. V1-93 a-t-il comparé les options techniques ? Oui.
15. V1-93 a-t-il retenu une option claire ? Oui, Option E.
16. V1-93 a-t-il défini les tests V1-94 ? Oui.
17. V1-93 a-t-il défini la Visual Gate V1-94 ? Oui.
18. V1-93 a-t-il préservé l'Actor Display V1-92 ? Oui, dans le contrat.
19. V1-93 a-t-il mis à jour les roadmaps ? Oui.
20. L'Evidence Pack est-il complet ? Oui, avec les checks finaux documentés.
21. Quel est le prochain lot exact recommandé ? `NS-SCENES-V1-94 — Cinematic Map Backdrop Layer Fidelity Renderer V0`.

## 32. Recommandation pour le prochain lot

```text
NS-SCENES-V1-94 — Cinematic Map Backdrop Layer Fidelity Renderer V0
```

Objectif :

```text
Étendre le renderer backdrop cinematic pour rendre correctement terrain, paths, surfaces, environment via generated placements et placed elements quand les données/assets sont disponibles, sans MapCanvas complet, sans runtime, sans Flame, sans playback, sans mutation projet/map, et en préservant l'Actor Display V1-92.
```

Le lot suivant après V1-94 :

```text
NS-SCENES-V1-95 — Cinematic Actor Display Preview Sprite Resolver Prep Contract
```

Raison :

```text
Les sprites acteurs viendront après la fidélité map, afin d'éviter d'habiller les comédiens avant d'avoir fini le décor.
```
