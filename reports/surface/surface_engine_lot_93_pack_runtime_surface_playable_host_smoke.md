# Lot 93-pack — Surface Runtime Playable Host Smoke / Real App Integration V0

## 1. Résumé exécutif honnête

Le Lot 93-pack ajoute un smoke test runtime proche host pour les Surfaces.

Le test créé construit un vrai projet temporaire sur disque, écrit un vrai PNG Surface `64x32`, écrit un `project.json` réel et une map JSON réelle contenant un `SurfaceLayer`, charge le tout via `loadRuntimeMapBundle`, puis vérifie deux niveaux :

- `RuntimeMapGame` charge le bundle, monte un `MapLayersComponent`, charge les images runtime depuis les chemins résolus et rend un pixel rouge puis bleu après `update(0.1)`.
- `PlayableMapGame` démarre depuis le même type de projet disque avec un `SurfaceLayer`, exécute `onLoad()` puis un tick sans crash, et reste en phase `overworld`.

Le lot ne modifie pas le code de production. Il ajoute uniquement un test et ce rapport. Le pixel complet via `GameWidget` n'a pas été retenu parce qu'il ajoute la lifecycle Flutter/Flame/caméra au lieu de tester directement le risque de ce lot : chargement disque réel -> bundle runtime -> images -> composant de rendu Surface -> host jouable qui accepte la map.

Conclusion : lot validable. Un Lot 93-bis n'est pas nécessaire pour le périmètre demandé, même si un vrai test `GameWidget` screenshot pourrait être un bonus futur.

## 2. Périmètre

Inclus :

- `packages/map_runtime/test/surface/surface_runtime_playable_host_smoke_test.dart`
- fixture temporaire disque générée pendant le test ;
- vrai PNG de test écrit par le test ;
- chargement via `loadRuntimeMapBundle` ;
- montage `RuntimeMapGame` ;
- smoke `PlayableMapGame`.

Exclus :

- aucun code runtime de production ;
- aucun `map_core` ;
- aucun `map_editor` ;
- aucun `map_gameplay` ;
- aucun `map_battle` ;
- aucun gameplay surf / tall grass ;
- aucune migration ;
- aucune nouvelle clock runtime.

## 3. Gate 0 — status initial

Commande :

```bash
pwd
git branch --show-current
git status --short --untracked-files=all
git diff --stat
git log --oneline -n 10
```

Sortie capturée avant modification :

```text
/Users/karim/Project/pokemonProject
main
?? packages/map_runtime/test/surface/surface_runtime_golden_slice_test.dart
?? packages/map_runtime/test/surface/surface_runtime_missing_assets_test.dart
?? packages/map_runtime/test/surface/surface_runtime_ordering_test.dart
?? packages/map_runtime/test/surface/surface_runtime_test_support.dart
?? reports/surface/surface_engine_lot_91_runtime_surface_golden_slice_e2e.md
?? reports/surface/surface_engine_lot_92_pack_runtime_surface_ordering_missing_asset_hardening.md
```

`git diff --stat` initial :

```text
```

`git log --oneline -n 10` initial :

```text
1f900e67 feat(map_runtime): render surface layers
da2b244d feat(map_runtime): add surface runtime resolver
32fbb0b5 feat(map_editor): improve surface mapping editor
d5561df7 feat(map_editor): edit surface role animation mapping
935a0036 feat(map_editor): animate surface editor previews
fe03b827 feat(map_editor): render surface atlas tile previews
5814f6e9 feat(map): add surface role resolver preview
f8859a06 feat(map_editor): improve surface painter and studio workflow ux
b20287da feat(map_editor): redesign surface studio workflow
f3a37532 feat(map_editor): add surface painter entry flow
```

Changements préexistants au début du lot :

- `packages/map_runtime/test/surface/surface_runtime_golden_slice_test.dart`
- `packages/map_runtime/test/surface/surface_runtime_missing_assets_test.dart`
- `packages/map_runtime/test/surface/surface_runtime_ordering_test.dart`
- `packages/map_runtime/test/surface/surface_runtime_test_support.dart`
- `reports/surface/surface_engine_lot_91_runtime_surface_golden_slice_e2e.md`
- `reports/surface/surface_engine_lot_92_pack_runtime_surface_ordering_missing_asset_hardening.md`

## 4. Audit host runtime

Commandes demandées :

```bash
rg -n "PlayableMapGame|RuntimeMapGame|GameWidget|loadRuntimeMapBundle|loadTilesetImagesById|RuntimeMapBundle|MapLayersComponent|map_runtime" packages examples test
rg -n "surface_runtime_golden_slice|surface_runtime_ordering|surface_runtime_missing_assets|Runtime Surface|SurfaceLayer|surfaceCatalog" packages/map_runtime/test packages/map_runtime/lib examples
rg -n "projectFilePath|projectRootDirectory|projectRoot|project.json|maps/|tilesetAbsolutePathsById|assets/tilesets" packages/map_runtime examples packages/map_core
```

Note : la première commande a été lancée telle quelle et a signalé `rg: test: No such file or directory`, car ce repo n'a pas de dossier `test/` à la racine. Elle a ensuite été relancée proprement sur `packages examples` :

```bash
rg -n "PlayableMapGame|RuntimeMapGame|GameWidget|loadRuntimeMapBundle|loadTilesetImagesById|RuntimeMapBundle|MapLayersComponent|map_runtime" packages examples
```

Constats :

- Le host jouable réel est `examples/playable_runtime_host/lib/main.dart`.
- Ce host appelle `loadRuntimeMapBundle(projectFilePath, mapId)`, puis construit `PlayableMapGame`.
- Le rendu Flutter du host utilise `GameWidget(game: game)`.
- `RuntimeMapGame` est le viewer Flame léger exporté par `map_runtime`, documenté dans le README et utilisé comme niveau stable de rendu read-only.
- `PlayableMapGame` est le host jouable complet : mouvement, état joueur, scripts, battles, overlays, transitions.

## 5. Audit tests existants

Tests et fichiers inspectés :

- `packages/map_runtime/test/playable_map_game_public_getters_test.dart`
- `packages/map_runtime/test/playable_map_game_whiteout_lite_test.dart`
- `packages/map_runtime/test/playable_map_game_input_test.dart`
- `packages/map_runtime/test/surface/surface_runtime_golden_slice_test.dart`
- `packages/map_runtime/test/surface/surface_runtime_ordering_test.dart`
- `packages/map_runtime/test/surface/surface_runtime_missing_assets_test.dart`
- `examples/playable_runtime_host/test/*`

Constats :

- Les tests `PlayableMapGame` existants appellent directement `game.onGameResize(...)` puis `await game.onLoad()`.
- Les tests existants du playable host ne couvrent pas une map Surface.
- Le golden slice Lot 91 charge déjà un vrai projet disque, mais rend directement un `MapLayersComponent`.
- Le Lot 93 devait donc monter d'un cran : tester `RuntimeMapGame` et `PlayableMapGame`.

## 6. Niveau d’intégration retenu

Niveau retenu :

1. `loadRuntimeMapBundle` depuis projet disque réel.
2. `RuntimeMapGame.onLoad()` pour charger les images via le chemin runtime réel et monter `MapLayersComponent`.
3. Rendu pixel du `MapLayersComponent` monté par `RuntimeMapGame`.
4. `PlayableMapGame.onLoad()` + `update(0.1)` pour le smoke host jouable.

Pourquoi pas un screenshot `GameWidget` complet :

- Le premier essai de rendu direct via `RuntimeMapGame.render(canvas)` en test headless a produit un pixel transparent, alors que le composant Surface monté rendait correctement. La cause est la lifecycle caméra/viewport Flame hors `GameWidget`, pas le pipeline Surface.
- Pour garder le signal du test centré sur Surface, le test rend le `MapLayersComponent` réellement monté par `RuntimeMapGame`.
- `PlayableMapGame` est tout de même testé au démarrage/tick, ce qui couvre l'acceptation de `SurfaceLayer` par le host jouable.

## 7. Fixture projet temporaire

Le test crée un dossier temporaire :

```dart
Directory.systemTemp.createTemp('pokemap_surface_host_smoke_')
```

Il écrit :

- `project.json`
- `maps/surface-host-test.json`
- `assets/tilesets/surface-water.png`

Le dossier est supprimé en `addTearDown`.

## 8. Manifest Surface utilisé

Le manifest contient :

- `ProjectSettings(tileWidth: 32, tileHeight: 32, displayScale: 1)`
- un tileset `surface-water`
- une map `surface-host-test`
- un `ProjectSurfaceCatalog` avec :
  - atlas `water-atlas` ;
  - animation `water-loop` ;
  - preset `water`.

## 9. Map Surface utilisée

La map contient :

- taille `1x1` ;
- un `SurfaceLayer` `surfaces` ;
- un placement `(0, 0)` avec `surfacePresetId: water`.

Pour le smoke `PlayableMapGame`, la même map inclut aussi un spawn joueur minimal `player-start`.

## 10. PNG Surface utilisé

Le test écrit un vrai PNG `64x32` :

- colonne/frame 0 : rouge opaque ;
- colonne/frame 1 : bleu opaque ;
- tile size : `32x32`.

Ce PNG force le runtime à passer par la résolution de chemin, le décodage image et la lecture de frame Surface.

## 11. Pipeline host/runtime testé

Pipeline testé :

```text
project.json temporaire réel
→ map JSON réelle
→ SurfaceLayer réel
→ ProjectSurfaceCatalog réel
→ ProjectTilesetEntry.relativePath
→ loadRuntimeMapBundle
→ RuntimeMapGame.onLoad
→ loadTilesetImagesById interne
→ MapLayersComponent monté
→ rendu pixel rouge / bleu
```

Pipeline host jouable testé :

```text
bundle runtime Surface réel
→ PlayableMapGame
→ onGameResize
→ onLoad
→ update(0.1)
→ phase overworld
```

## 12. Rendu/tick testé

Rendu pixel testé :

- avant tick : pixel `(16, 16)` = `[255, 0, 0, 255]` ;
- après `game.update(0.1)` : pixel `(16, 16)` = `[0, 0, 255, 255]`.

Tick host testé :

- `PlayableMapGame.update(0.1)` ;
- `gameStateSnapshot.currentMapId == surface-host-test` ;
- `debugFlowPhaseName == overworld`.

## 13. Tests lancés

Commandes lancées :

```bash
cd packages/map_runtime && flutter test test/surface/surface_runtime_playable_host_smoke_test.dart
cd packages/map_runtime && flutter test test/surface
cd packages/map_runtime && flutter test test/runtime_manifest_tilesets_surface_layer_test.dart
cd packages/map_runtime && flutter test test/map_layers_component_render_pass_test.dart
cd packages/map_runtime && flutter analyze test/surface/surface_runtime_playable_host_smoke_test.dart
```

Un premier lancement du test ciblé a échoué pendant le débogage :

```text
Expected: [255, 0, 0, 255]
  Actual: [0, 0, 0, 0]
```

Correction retenue après analyse : rendre le `MapLayersComponent` monté par `RuntimeMapGame` plutôt que `RuntimeMapGame.render(canvas)` hors lifecycle `GameWidget`.

## 14. Résultats

Test ciblé final :

```text
00:01 +0: Surface runtime playable host smoke loads a disk Surface project through RuntimeMapGame and renders animated pixels
00:01 +1: Surface runtime playable host smoke loads a disk Surface project through RuntimeMapGame and renders animated pixels
00:01 +1: Surface runtime playable host smoke PlayableMapGame starts and ticks with a disk SurfaceLayer project
[runtime] Map loaded: surface-host-test, spawn at (0, 0)
00:01 +2: Surface runtime playable host smoke PlayableMapGame starts and ticks with a disk SurfaceLayer project
00:01 +2: All tests passed!
```

Suite Surface runtime :

```text
00:02 +29: All tests passed!
```

Tileset collection runtime :

```text
00:01 +1: All tests passed!
```

MapLayersComponent render pass :

```text
00:01 +2: All tests passed!
```

Analyse ciblée :

```text
Analyzing surface_runtime_playable_host_smoke_test.dart...
No issues found! (ran in 2.8s)
```

## 15. Fichiers créés

Créés par le Lot 93-pack :

- `packages/map_runtime/test/surface/surface_runtime_playable_host_smoke_test.dart`
- `reports/surface/surface_engine_lot_93_pack_runtime_surface_playable_host_smoke.md`

## 16. Fichiers modifiés

Aucun fichier existant modifié par le Lot 93-pack.

## 17. Fichiers supprimés

Aucun.

## 18. Evidence Pack

Status initial complet : voir section 3.

Status final attendu après création du rapport :

```text
?? packages/map_runtime/test/surface/surface_runtime_golden_slice_test.dart
?? packages/map_runtime/test/surface/surface_runtime_missing_assets_test.dart
?? packages/map_runtime/test/surface/surface_runtime_ordering_test.dart
?? packages/map_runtime/test/surface/surface_runtime_playable_host_smoke_test.dart
?? packages/map_runtime/test/surface/surface_runtime_test_support.dart
?? reports/surface/surface_engine_lot_91_runtime_surface_golden_slice_e2e.md
?? reports/surface/surface_engine_lot_92_pack_runtime_surface_ordering_missing_asset_hardening.md
?? reports/surface/surface_engine_lot_93_pack_runtime_surface_playable_host_smoke.md
```

Diff stat final attendu :

```text
```

Commandes d'audit lancées :

```bash
rg -n "PlayableMapGame|RuntimeMapGame|GameWidget|loadRuntimeMapBundle|loadTilesetImagesById|RuntimeMapBundle|MapLayersComponent|map_runtime" packages examples test
rg -n "PlayableMapGame|RuntimeMapGame|GameWidget|loadRuntimeMapBundle|loadTilesetImagesById|RuntimeMapBundle|MapLayersComponent|map_runtime" packages examples
rg -n "surface_runtime_golden_slice|surface_runtime_ordering|surface_runtime_missing_assets|Runtime Surface|SurfaceLayer|surfaceCatalog" packages/map_runtime/test packages/map_runtime/lib examples
rg -n "projectFilePath|projectRootDirectory|projectRoot|project.json|maps/|tilesetAbsolutePathsById|assets/tilesets" packages/map_runtime examples packages/map_core
```

Commandes de vérification lancées :

```bash
flutter test test/surface/surface_runtime_playable_host_smoke_test.dart
flutter test test/surface
flutter test test/runtime_manifest_tilesets_surface_layer_test.dart
flutter test test/map_layers_component_render_pass_test.dart
flutter analyze test/surface/surface_runtime_playable_host_smoke_test.dart
```

## 19. Git status final

Gate final exécuté après écriture de ce rapport :

```text
?? packages/map_runtime/test/surface/surface_runtime_golden_slice_test.dart
?? packages/map_runtime/test/surface/surface_runtime_missing_assets_test.dart
?? packages/map_runtime/test/surface/surface_runtime_ordering_test.dart
?? packages/map_runtime/test/surface/surface_runtime_playable_host_smoke_test.dart
?? packages/map_runtime/test/surface/surface_runtime_test_support.dart
?? reports/surface/surface_engine_lot_91_runtime_surface_golden_slice_e2e.md
?? reports/surface/surface_engine_lot_92_pack_runtime_surface_ordering_missing_asset_hardening.md
?? reports/surface/surface_engine_lot_93_pack_runtime_surface_playable_host_smoke.md
```

`git diff --stat` final :

```text
```

Recherche de fichiers temporaires :

```text
```

`git diff --check` :

```text
```

Les changements du Lot 93-pack sont uniquement :

- `packages/map_runtime/test/surface/surface_runtime_playable_host_smoke_test.dart`
- `reports/surface/surface_engine_lot_93_pack_runtime_surface_playable_host_smoke.md`

## 20. Périmètre explicitement non touché

Confirmé :

- `map_core` non modifié.
- `map_editor` non modifié.
- `map_gameplay` non modifié.
- `map_battle` non modifié.
- `ProjectManifest` non modifié.
- `surface.dart` non modifié.
- `surface_catalog.dart` non modifié.
- codecs Surface non modifiés.
- aucune migration legacy.
- aucun gameplay surf.
- aucun tall grass encounter.
- aucune nouvelle clock runtime.
- aucun changement JSON volontaire dans les schémas.
- aucun changement Surface Studio.
- aucun changement Surface Painter.

## 21. Contenu complet des fichiers modifiés/créés/supprimés

Le rapport lui-même n'est pas recopié récursivement. Aucun fichier n'a été supprimé.

### `packages/map_runtime/test/surface/surface_runtime_playable_host_smoke_test.dart`

```dart
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/src/presentation/flame/map_layers_component.dart';
import 'package:path/path.dart' as p;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Surface runtime playable host smoke', () {
    test(
      'loads a disk Surface project through RuntimeMapGame and renders animated pixels',
      () async {
        final fixture = await _SurfaceHostFixture.create(
          includePlayerSpawn: false,
        );
        addTearDown(fixture.dispose);

        final bundle = await loadRuntimeMapBundle(
          projectFilePath: fixture.projectFilePath,
          mapId: 'surface-host-test',
        );

        expect(bundle.map.layers.whereType<SurfaceLayer>(), hasLength(1));
        expect(bundle.manifest.surfaceCatalog.presets.single.id, 'water');
        expect(
          bundle.tilesetAbsolutePathsById,
          containsPair('surface-water', fixture.surfaceTilesetPath),
        );

        final game = RuntimeMapGame(bundle: bundle);
        game.onGameResize(Vector2(32, 32));
        await game.onLoad();

        expect(game.world.children.whereType<MapLayersComponent>(), hasLength(1));

        final firstFrame = await _renderRuntimeMapSurface(game);
        expect(await _pixelAt(firstFrame, 16, 16), _rgba(255, 0, 0, 255));

        game.update(0.1);
        final secondFrame = await _renderRuntimeMapSurface(game);
        expect(await _pixelAt(secondFrame, 16, 16), _rgba(0, 0, 255, 255));
      },
    );

    test(
      'PlayableMapGame starts and ticks with a disk SurfaceLayer project',
      () async {
        final fixture = await _SurfaceHostFixture.create(
          includePlayerSpawn: true,
        );
        addTearDown(fixture.dispose);

        final bundle = await loadRuntimeMapBundle(
          projectFilePath: fixture.projectFilePath,
          mapId: 'surface-host-test',
        );
        final game = PlayableMapGame(
          bundle: bundle,
          projectFilePath: fixture.projectFilePath,
        );

        game.onGameResize(Vector2(64, 32));
        await game.onLoad();
        game.update(0.1);

        expect(game.gameStateSnapshot.currentMapId, 'surface-host-test');
        expect(game.debugFlowPhaseName, 'overworld');
      },
    );
  });
}

class _SurfaceHostFixture {
  _SurfaceHostFixture({
    required this.root,
    required this.projectFilePath,
    required this.surfaceTilesetPath,
  });

  final Directory root;
  final String projectFilePath;
  final String surfaceTilesetPath;

  static Future<_SurfaceHostFixture> create({
    required bool includePlayerSpawn,
  }) async {
    final root = await Directory.systemTemp.createTemp(
      'pokemap_surface_host_smoke_',
    );
    final surfaceTilesetPath = await _writeSurfaceTilesetPng(root);
    final manifest = _surfaceProjectManifest();
    final map = _surfaceMap(includePlayerSpawn: includePlayerSpawn);
    final projectFilePath = await _writeProjectJson(root, manifest);
    await _writeMapJson(root, map);

    return _SurfaceHostFixture(
      root: root,
      projectFilePath: projectFilePath,
      surfaceTilesetPath: p.normalize(surfaceTilesetPath),
    );
  }

  Future<void> dispose() async {
    if (await root.exists()) {
      await root.delete(recursive: true);
    }
  }
}

Future<String> _writeSurfaceTilesetPng(Directory projectRoot) async {
  final tilesetFile = File(
    p.join(projectRoot.path, 'assets', 'tilesets', 'surface-water.png'),
  );
  await tilesetFile.parent.create(recursive: true);

  // A real two-frame PNG keeps this test close to the playable host pipeline:
  // the runtime must resolve a project-relative path, decode the image, then
  // let the Surface renderer advance from red to blue through its normal tick.
  final image = img.Image(width: 64, height: 32);
  for (var y = 0; y < 32; y++) {
    for (var x = 0; x < 64; x++) {
      image.setPixel(
        x,
        y,
        x < 32
            ? img.ColorRgba8(255, 0, 0, 255)
            : img.ColorRgba8(0, 0, 255, 255),
      );
    }
  }
  await tilesetFile.writeAsBytes(img.encodePng(image, level: 0));
  return p.normalize(tilesetFile.path);
}

ProjectManifest _surfaceProjectManifest() {
  return ProjectManifest(
    name: 'Surface Runtime Playable Host Smoke',
    maps: const [
      ProjectMapEntry(
        id: 'surface-host-test',
        name: 'Surface Host Test',
        relativePath: 'maps/surface-host-test.json',
      ),
    ],
    tilesets: const [
      ProjectTilesetEntry(
        id: 'surface-water',
        name: 'Surface Water',
        relativePath: 'assets/tilesets/surface-water.png',
      ),
    ],
    settings: const ProjectSettings(
      tileWidth: 32,
      tileHeight: 32,
      displayScale: 1,
    ),
    surfaceCatalog: ProjectSurfaceCatalog(
      atlases: [
        ProjectSurfaceAtlas(
          id: 'water-atlas',
          name: 'Water Atlas',
          tilesetId: 'surface-water',
          geometry: SurfaceAtlasGeometry(
            tileSize: SurfaceAtlasTileSize(width: 32, height: 32),
            gridSize: SurfaceAtlasGridSize(columns: 2, rows: 1),
          ),
        ),
      ],
      animations: [
        ProjectSurfaceAnimation(
          id: 'water-loop',
          name: 'Water Loop',
          timeline: SurfaceAnimationTimeline(
            frames: [
              SurfaceAnimationFrame(
                tileRef: SurfaceAtlasTileRef(
                  atlasId: 'water-atlas',
                  column: 0,
                  row: 0,
                ),
                durationMs: 100,
              ),
              SurfaceAnimationFrame(
                tileRef: SurfaceAtlasTileRef(
                  atlasId: 'water-atlas',
                  column: 1,
                  row: 0,
                ),
                durationMs: 100,
              ),
            ],
          ),
        ),
      ],
      presets: [
        ProjectSurfacePreset(
          id: 'water',
          name: 'Water',
          variantAnimations: SurfaceVariantAnimationRefSet(
            refs: [
              SurfaceVariantAnimationRef(
                role: SurfaceVariantRole.isolated,
                animationId: 'water-loop',
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

MapData _surfaceMap({required bool includePlayerSpawn}) {
  return MapData(
    id: 'surface-host-test',
    name: 'Surface Host Test',
    size: const GridSize(width: 1, height: 1),
    layers: const [
      MapLayer.surface(
        id: 'surfaces',
        name: 'Surfaces',
        placements: [
          SurfaceCellPlacement(x: 0, y: 0, surfacePresetId: 'water'),
        ],
      ),
    ],
    entities: includePlayerSpawn
        ? const [
            MapEntity(
              id: 'player-start',
              name: 'Player Start',
              kind: MapEntityKind.spawn,
              pos: GridPos(x: 0, y: 0),
              blocksMovement: false,
              spawn: MapEntitySpawnData(
                role: EntitySpawnRole.playerStart,
                facing: EntityFacing.south,
              ),
            ),
          ]
        : const [],
    mapMetadata: includePlayerSpawn
        ? const MapMetadata(defaultSpawnId: 'player-start')
        : const MapMetadata(),
  );
}

Future<String> _writeProjectJson(
  Directory projectRoot,
  ProjectManifest manifest,
) async {
  final projectFile = File(p.join(projectRoot.path, 'project.json'));
  await projectFile.writeAsString(
    const JsonEncoder.withIndent('  ').convert(manifest.toJson()),
  );
  return p.normalize(projectFile.path);
}

Future<void> _writeMapJson(Directory projectRoot, MapData map) async {
  final mapFile = File(
    p.join(projectRoot.path, 'maps', 'surface-host-test.json'),
  );
  await mapFile.parent.create(recursive: true);
  await mapFile.writeAsString(
    const JsonEncoder.withIndent('  ').convert(map.toJson()),
  );
}

Future<ui.Image> _renderRuntimeMapSurface(RuntimeMapGame game) {
  final component = game.world.children.whereType<MapLayersComponent>().single;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  // Rendering the mounted MapLayersComponent keeps the smoke deterministic in
  // a headless test while still proving that RuntimeMapGame performed the real
  // runtime image loading and component mount. Full GameWidget/camera rendering
  // is intentionally left out because it is covered by Flutter/Flame lifecycle
  // integration rather than the Surface asset pipeline itself.
  component.render(canvas);
  return recorder.endRecording().toImage(32, 32);
}

Future<List<int>> _pixelAt(ui.Image image, int x, int y) async {
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  final offset = (y * image.width + x) * 4;
  return [
    data!.getUint8(offset),
    data.getUint8(offset + 1),
    data.getUint8(offset + 2),
    data.getUint8(offset + 3),
  ];
}

List<int> _rgba(int red, int green, int blue, int alpha) {
  return [red, green, blue, alpha];
}
```

## 22. Limites restantes

- Pas de capture `GameWidget` complète. Le test rend le `MapLayersComponent` monté par `RuntimeMapGame` pour éviter une instabilité caméra/lifecycle en headless.
- Pas de modification du host exemple : le code app existant utilise déjà `PlayableMapGame`, donc le lot prouve le même chemin par test package.
- Pas de test gameplay Surface : volontairement hors périmètre.

## 23. Auto-critique

Le test est utile et strictement ciblé, mais il n'est pas un vrai test visuel de l'application host complète avec `GameWidget`. Le meilleur compromis a été de tester `RuntimeMapGame` pour le pixel et `PlayableMapGame` pour le démarrage/tick. C'est plus fiable et plus maintenable qu'un screenshot Flutter, mais ça laisse un petit angle mort sur la composition finale Flutter autour du `GameWidget`.

La fixture duplique un peu le golden slice Lot 91. C'est acceptable ici car le test doit rester autonome et lisible, mais si d'autres lots créent encore des fixtures Surface disque, il faudra extraire un support partagé propre.

## 24. Regard critique sur le prompt

Le prompt demande à la fois "host jouable" et "si pixel possible". Le host jouable complet (`PlayableMapGame` + `GameWidget`) rend le pixel plus fragile car la caméra, le joueur et les overlays entrent en jeu. Le prompt a raison de permettre un niveau plus bas justifié : ici, `RuntimeMapGame` donne la preuve pixel, `PlayableMapGame` donne la preuve host, sans ouvrir gameplay ni refonte.

## Auto-review obligatoire

- Est-ce que le test utilise un projet temporaire disque réel ? Oui.
- Est-ce que le host/app runtime le plus proche du réel est testé ? Oui, `PlayableMapGame` est démarré et tické ; `RuntimeMapGame` est utilisé pour le pixel stable.
- Est-ce que le niveau d’intégration retenu est justifié ? Oui.
- Est-ce que SurfaceLayer est présent dans la map testée ? Oui.
- Est-ce que surfaceCatalog est présent dans le manifest testé ? Oui.
- Est-ce qu’un vrai PNG Surface est écrit ? Oui.
- Est-ce que le runtime charge le projet sans crash ? Oui.
- Est-ce que les images Surface sont chargées ? Oui, via `RuntimeMapGame.onLoad()` et pixel rendu.
- Est-ce qu’un rendu pixel est testé ? Oui.
- Est-ce qu’un tick/update est testé ? Oui, `RuntimeMapGame.update(0.1)` et `PlayableMapGame.update(0.1)`.
- Est-ce que les tests Surface runtime restent verts ? Oui.
- Est-ce que map_core est inchangé ? Oui.
- Est-ce que map_editor est inchangé ? Oui.
- Est-ce qu’un Lot 93-bis est nécessaire ? Non pour ce périmètre. Un test `GameWidget` screenshot pourrait être un bonus futur, pas un blocage.
