# NS-SCENES-V1-83 — Cinematic Map Backdrop Preview Read Model V0

## 1. Resume executif

V1-83 construit la projection testable du decor.

V1-83 ne rend toujours pas la map dans l'interface.

Le lot implemente un read model pur `map_core`, `CinematicMapBackdropPreviewModel`, construit depuis `CinematicAsset.mapId`, un `ProjectMapEntry` resolu et une `MapData` deja chargee par l'appelant. Il expose les statuts de disponibilite, les diagnostics, les informations lisibles de map, les couches visuelles projetables et une recommandation de viewport sans Flutter, Flame, renderer, runtime, playback ou pathfinding.

## 2. Gate 0

- Branche : `main`.
- Working tree initial : propre avant le lot.
- Dernier commit observe : `c76550a6 feat(narrative): update cinematic workspaces, tests, and roadmap reports (NS-SCENES-V1-82)`.
- Instruction directe : implementer V1-83 avec rapport, evidence pack, roadmaps et tests.
- Scope retenu : `packages/map_core` + rapports/roadmaps uniquement.

## 3. Fichiers lus

- `packages/map_core/lib/src/models/cinematic_asset.dart`
- `packages/map_core/lib/src/models/project_manifest.dart`
- `packages/map_core/lib/src/models/map_data.dart`
- `packages/map_core/lib/src/models/map_layer.dart`
- `packages/map_core/lib/src/read_models/cinematic_stage_map_source_catalog.dart`
- `packages/map_core/test/cinematic_stage_map_source_catalog_test.dart`
- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`
- Prompt V1-83 fourni par Karim.

## 4. Synthese des sub-agents et arbitrages

- Goodall : recommande un read model `map_core` hand-written, `@immutable`, listes non modifiables, export public dans `map_core.dart`.
- Noether : confirme que `MapData.layers` est la source visuelle ; inclure tile/terrain/path/surface/object/environment, exclure collision/entities/events/triggers/warps/gameplayZones.
- Pauli : confirme la purete du contrat, la separation viewport en valeurs Dart et le risque principal : ne pas charger la map ni les assets depuis core.
- Kuhn : confirme les tests attendus et les scans anti-scope : pas de package editor/runtime, pas de Flutter/Flame, pas de disk loading, pas de playback.

Arbitrage final : le builder public prend `asset`, `stageMap`, `mapData`, une liste optionnelle de tilesets disponibles et une taille de viewport pure. `tilesetUnavailable` est terminal uniquement si l'appelant fournit explicitement `availableTilesetIds`.

## 5. Design Gate — Cinematic Map Backdrop Preview Read Model V0

1. Decision V1-82 implementee : Option E, read model avant renderer.
2. Pourquoi un read model avant renderer : il stabilise les statuts, diagnostics et donnees projetables avant toute UI.
3. Pourquoi `map_core` : le contrat est pur, testable et partageable sans dependance editor/runtime.
4. Pourquoi aucun chargement disque : core ne connait ni filesystem projet ni cache editor.
5. Source canonique : `CinematicAsset.mapId`.
6. Role de `ProjectMapEntry` : label humain et `relativePath` resolu depuis le manifest.
7. Role de `MapData` : snapshot deja charge contenant taille et layers.
8. `stageContext.backdropMode.none` : decor volontairement desactive.
9. `projectMap` sans `mapId` : `missingStageMap`.
10. `mapId` absent du manifest : `stageMapUnknown`.
11. `ProjectMapEntry` sans `MapData` : `mapDataUnavailable`.
12. `MapData.id` different : `mapDataMismatch`.
13. Tileset manquant : `tilesetUnavailable` seulement si la liste disponible est fournie.
14. Couches incluses : tile, terrain, path, surface, object, environment.
15. Couches exclues : collision.
16. Objets gameplay exclus : entities, events, triggers, warps, gameplayZones, connections.
17. Acteurs exclus : aucun actor/player runtime n'est rendu ou projete.
18. Diagnostics : code + severite + message + sourceId optionnel.
19. Labels : nom humain puis fallback id.
20. Dimensions : summary stable `width x height tuiles`.
21. Viewport recommendation : mode, zoom, center, reason.
22. Zoom : calcule depuis viewport pur si fourni, sinon zoom 1 centre map.
23. Pas de Flutter `Size`/`BuildContext` : `CinematicMapBackdropViewportSize`.
24. Pas de Flame Camera : center/zoom en unites de grille.
25. `CinematicAsset.mapId` reste l'unique ancre stage map.
26. `stageContext` ne recoit pas de `mapId`.
27. Pas d'UI : V1-83 est un lot core/read-model.
28. Pas de renderer : V1-84 le fera.
29. Pas de runtime : le decor preview est sandbox authoring.
30. Prochain lot exact recommande : `NS-SCENES-V1-84 — Cinematic Map Backdrop Preview Renderer V0`.

## 6. Scope realise

- Ajout de `packages/map_core/lib/src/read_models/cinematic_map_backdrop_preview_model.dart`.
- Export public depuis `packages/map_core/lib/map_core.dart`.
- Ajout de `packages/map_core/test/cinematic_map_backdrop_preview_model_test.dart`.
- Mise a jour des deux roadmaps scenes.
- Ajout du present rapport et de l'evidence pack V1-83.

## 7. Contrat V1-82 implemente

Le contrat V1-82 demandait une projection avant rendu. V1-83 le materialise avec :

- `backdropMode` lu depuis `CinematicStageContext`.
- `mapId` lu depuis `CinematicAsset`.
- `ProjectMapEntry` utilise pour le label et le chemin projet.
- `MapData` utilise pour dimensions et couches visuelles.
- Aucun couplage vers renderer, widget, Flame, runtime, image ou playback.

## 8. Modele `CinematicMapBackdropPreviewModel`

Le modele expose :

- `status`
- `mapId`
- `mapLabel`
- `mapRelativePath`
- `mapDataId`
- `sizeSummary`
- `viewportRecommendation`
- `layers`
- `diagnostics`
- `isAvailable`

Les listes sont rendues non modifiables pour eviter les mutations accidentelles du read model.

## 9. Statuts et diagnostics

Statuts livres :

- `backdropDisabled`
- `missingStageMap`
- `stageMapUnknown`
- `mapDataUnavailable`
- `mapDataMismatch`
- `tilesetUnavailable`
- `available`

Diagnostics livres :

- `mapBackdropDisabled`
- `mapBackdropRequiresStageMap`
- `mapBackdropStageMapUnknown`
- `mapBackdropMapDataUnavailable`
- `mapBackdropMapDataMismatch`
- `mapBackdropTilesetMissing`
- `mapBackdropLayerUnsupported`

## 10. Layers visuels

Inclus :

- `TileLayer`
- `TerrainLayer`
- `PathLayer`
- `SurfaceLayer`
- `ObjectLayer`
- `EnvironmentLayer`

Exclus :

- `CollisionLayer`
- `MapData.entities`
- `MapData.events`
- `MapData.triggers`
- `MapData.warps`
- `MapData.gameplayZones`

## 11. Viewport recommendation

Sans viewport fourni, le modele retourne `centerMap`, zoom `1`, centre map.

Avec viewport fourni, le modele retourne `fitMap`, centre map et un zoom calcule en unites de grille, borne entre `0.1` et `4.0`. Aucune classe Flutter ou Flame n'est importee.

## 12. TDD RED/GREEN

RED initial :

```text
dart test --reporter=compact test/cinematic_map_backdrop_preview_model_test.dart
Failed to load ... Method not found: 'buildCinematicMapBackdropPreviewModel'
```

GREEN final :

```text
dart test --reporter=compact test/cinematic_map_backdrop_preview_model_test.dart
00:00 +15: All tests passed!
```

## 13. Code genere dans ce lot

Export public ajoute :

```dart
export 'src/read_models/cinematic_map_backdrop_preview_model.dart';
```

Enums principaux ajoutes :

```dart
enum CinematicMapBackdropPreviewStatus {
  backdropDisabled,
  missingStageMap,
  stageMapUnknown,
  mapDataUnavailable,
  mapDataMismatch,
  tilesetUnavailable,
  available,
}

enum CinematicMapBackdropLayerKind {
  tile,
  terrain,
  path,
  surface,
  object,
  environment,
}

enum CinematicMapBackdropViewportMode {
  fitMap,
  centerMap,
  centerActor,
  centerTarget,
}
```

Builder public ajoute :

```dart
CinematicMapBackdropPreviewModel buildCinematicMapBackdropPreviewModel({
  required CinematicAsset asset,
  required ProjectMapEntry? stageMap,
  required MapData? mapData,
  Set<String>? availableTilesetIds,
  CinematicMapBackdropViewportSize? viewportSize,
}) {
  // Statuts dans l'ordre :
  // backdropDisabled -> missingStageMap -> stageMapUnknown
  // -> mapDataUnavailable -> mapDataMismatch
  // -> tilesetUnavailable -> available.
}
```

Projection de layer representative :

```dart
if (layer is TileLayer) {
  final tilesetId =
      layer.tilesetId?._trimmedOrNull ?? mapData.tilesetId._trimmedOrNull;
  layers.add(
    CinematicMapBackdropLayerPreview(
      id: layer.id,
      label: _labelOrId(layer.name, layer.id),
      kind: CinematicMapBackdropLayerKind.tile,
      visible: layer.isVisible,
      opacity: layer.opacity,
      summary: '${layer.tiles.length} tuile(s)',
      renderRefs: [
        'tileCells:${layer.tiles.length}',
        if (tilesetId != null) 'tileset:$tilesetId',
      ],
    ),
  );
}
```

Viewport pur ajoute :

```dart
final zoom = math
    .min(
      viewportSize.width / mapData.size.width,
      viewportSize.height / mapData.size.height,
    )
    .clamp(0.1, 4.0)
    .toDouble();
```

Tests ajoutes :

```text
builds available cinematic map backdrop preview model from project map and map data
returns backdrop disabled when backdrop mode is none
returns missing stage map when project map backdrop has no map id
returns stage map unknown when map id has no project map entry
returns map data unavailable when stage map has no map data
returns map data mismatch when map data id differs from stage map
returns tileset unavailable when tileset ids are provided and missing
does not diagnose tileset missing when available tilesets are not provided
projects visual layers from map data
excludes entities events triggers warps and gameplay zones from visual layers
builds human map label from project map entry
falls back to map id when label is missing
builds size summary from map dimensions
builds viewport recommendation without Flutter or Flame
does not require runtime state
```

## 14. Commandes et resultats

Core :

```text
cd packages/map_core && dart test --reporter=compact test/cinematic_map_backdrop_preview_model_test.dart
00:00 +15: All tests passed!
```

```text
cd packages/map_core && dart test --reporter=compact test/cinematic_stage_map_source_catalog_test.dart
00:00 +7: All tests passed!
```

```text
cd packages/map_core && dart test --reporter=compact test/cinematic_asset_test.dart
00:00 +14: All tests passed!
```

```text
cd packages/map_core && dart test --reporter=compact test/project_manifest_cinematics_test.dart
00:00 +9: All tests passed!
```

```text
cd packages/map_core && dart analyze
No issues found!
```

Editor :

```text
cd packages/map_editor && flutter test --reporter=compact test/cinematics_library_workspace_test.dart
00:05 +14: All tests passed!
```

```text
cd packages/map_editor && flutter test --reporter=compact test/cinematic_builder_workspace_test.dart
00:25 +140 -1: Some tests failed.
```

Failure observee : le test `lists timeline steps in order with read-only details` attend zero `CupertinoTextField` dans `cinematic-builder-inspector-placeholder`, mais un champ `Nom de l'acteur` existe maintenant dans l'expansible acteurs. Cette failure est hors scope V1-83 et correspond au pouvoir de renommage acteur demande precedemment.

```text
cd packages/map_editor && flutter analyze
344 issues found.
```

Les premieres erreurs concernent la dette Pokemon SDK existante dans `pokemon_sdk_move_catalog_converter.dart` et `sync_pokemon_sdk_moves_catalog_use_case.dart`, sans lien avec V1-83.

## 15. Anti-scope

Scans core modifies :

```text
git diff --name-only -- packages/map_editor packages/map_runtime packages/map_gameplay packages/map_battle examples selbrume
<aucune sortie>
```

```text
rg package:flutter|package:flame|GameWidget|FlameGame|PlayableMapGame|RuntimeMapGame|CameraComponent|Component|GameState|SceneCinematicRuntimeAwaitableAdapter|map_runtime ...
<aucune sortie>
```

```text
rg Widget|BuildContext|CustomPainter|Canvas|paint\(|renderBackdrop|Renderer|Painter|Sprite|TilesetImage|ImageProvider ...
<aucune sortie>
```

```text
rg startPlayback|stopPlayback|playback|currentTimeMs|playbackTimeMs|isPlaying|Timer\(|Ticker|AnimationController|seek|scrub|scrubber ...
<aucune sortie>
```

```text
rg stageContext.*mapId|CinematicStageContext\([^\)]*mapId|mapId.*stageContext ...
<aucune sortie>
```

```text
rg selbrume|mael|maël|lysa|port_brisants|bourg_selbrume|phare|brume|marais ...
<aucune sortie>
```

```text
rg gpt-image-2|image_generation|generate image|AI image|image model ...
<aucune sortie>
```

## 16. Roadmap

- `road_map_scenes.md` : V1-83 passe DONE, V1-84 devient le prochain lot recommande.
- `road_map_scene_builder_authoring.md` : V1-83 passe DONE, V1-84 est ajoute en TODO.

## 17. Limites connues

- Pas de map rendue dans le Builder.
- Pas de renderer UI.
- Pas de chargement tileset image.
- Pas de chargement fichier depuis `map_core`.
- Pas de runtime/Flame.
- Pas de playback ou seek.
- Pas d'acteurs rendus.
- Pas de collision/pathfinding/warps/gameplay overlay.
- Test editor Builder rouge sur une regression/attente hors scope V1-83.
- `flutter analyze` global `map_editor` reste rouge sur dette Pokemon SDK preexistante.

## 18. Prochain lot recommande

`NS-SCENES-V1-84 — Cinematic Map Backdrop Preview Renderer V0`

Objectif : brancher ce read model dans le Cinematic Builder pour afficher un decor map sandbox read-only, en respectant les proportions preview/timeline demandees par Karim, sans runtime, Flame, playback, acteurs rendus ni pathfinding.
