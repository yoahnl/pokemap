# Lot 91 — Runtime Surface Golden Slice / Project Fixture E2E V0

## 1. Résumé exécutif honnête

Lot 91 ajoute une preuve automatisée E2E du pipeline runtime Surface depuis un vrai projet temporaire sur disque.

Le test créé écrit :

- un `project.json` réel via `ProjectManifest.toJson()`;
- une map JSON réelle via `MapData.toJson()`;
- un PNG réel `64 x 32 px` contenant deux frames `32 x 32 px`;
- un `surfaceCatalog` réel avec atlas, animation et preset Surface;
- un `SurfaceLayer` réel avec un placement.

Il charge ensuite le projet avec `loadRuntimeMapBundle`, charge l'image via `loadTilesetImagesById`, instancie `MapLayersComponent`, rend dans un canvas de test, puis vérifie :

- frame 0, centre de tuile = rouge;
- après `component.update(0.1)`, centre de tuile = bleu.

Résultat : le golden slice confirme la chaîne disque réel -> loader runtime -> collecte tileset Surface -> chargement image -> renderer Surface -> animation via `_animElapsed`.

Aucun code de production n'a été modifié. Le test est passé immédiatement contre les Lots 89/90, ce qui confirme que ce lot est une preuve de bout en bout, pas un correctif fonctionnel.

## 2. Périmètre

Inclus :

- test E2E runtime Surface dans `packages/map_runtime`;
- fixture temporaire générée à l'exécution;
- vrai PNG écrit par le test;
- chargement par le loader runtime existant;
- vérification de rendu pixel statique et animé;
- rapport Lot 91.

Exclus :

- aucune feature runtime nouvelle;
- aucun changement `map_core`;
- aucun changement `map_editor`;
- aucun changement gameplay/battle;
- aucune nouvelle clock runtime;
- aucun changement JSON volontaire;
- aucune modification Surface Studio ou Surface Painter.

## 3. Gate 0 — status initial

Commande :

```bash
pwd
```

Sortie :

```text
/Users/karim/Project/pokemonProject
```

Commande :

```bash
git branch --show-current
```

Sortie :

```text
main
```

Commande :

```bash
git status --short --untracked-files=all
```

Sortie :

```text

```

Commande :

```bash
git diff --stat
```

Sortie :

```text

```

Commande :

```bash
git log --oneline -n 10
```

Sortie :

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

Status initial : propre. Aucun changement préexistant.

## 4. Audit loader runtime

Commandes d'audit lancées :

```bash
rg -n "loadRuntimeMapBundle|RuntimeMapBundle|projectRootDirectory|project.json|ProjectManifest|decodeProjectManifest|map json|MapData|fromJson|load.*map|tilesetAbsolutePathsById" packages/map_runtime packages/map_core packages/map_editor
rg -n "RuntimeTilesetImage|loadRuntimeTileset|tilesetAbsolutePathsById|Image|instantiateImageCodec|decodeImage|png|File\(" packages/map_runtime packages/map_core
rg -n "SurfaceLayer|MapLayer.surface|surfaceCatalog|ProjectSurfaceCatalog|SurfaceRuntime|surface_runtime_renderer_test|runtime_manifest_tilesets_surface_layer_test" packages/map_runtime packages/map_core
```

Fichiers inspectés précisément après audit :

- `packages/map_runtime/lib/src/application/load_runtime_map_bundle.dart`
- `packages/map_runtime/lib/src/application/runtime_map_bundle.dart`
- `packages/map_runtime/lib/src/infrastructure/tile_image_loader.dart`
- `packages/map_runtime/lib/src/application/runtime_manifest_tilesets.dart`
- `packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart`
- `packages/map_runtime/test/surface/surface_runtime_renderer_test.dart`
- `packages/map_runtime/test/runtime_manifest_tilesets_surface_layer_test.dart`
- `packages/map_runtime/test/runtime_tileset_image_test.dart`
- `packages/map_core/lib/src/models/project_manifest.dart`
- `packages/map_core/lib/src/models/map_data.dart`
- `packages/map_core/lib/src/models/map_layer.dart`
- `packages/map_core/lib/src/validation/validators.dart`

Constats :

- `loadRuntimeMapBundle` lit `project.json`, applique `migrateProjectManifestJson`, construit `ProjectManifest.fromJson`, valide avec `ProjectValidator.validate`, résout l'entrée map par `mapId`, charge la map JSON avec `loadMapDataFromFile`, collecte les tilesets via `collectAllRuntimeTilesetIds`, puis résout les chemins absolus.
- `RuntimeMapBundle` transporte `manifest`, `map`, `projectRootDirectory` et `tilesetAbsolutePathsById`.
- Le loader ne charge pas directement les images; elles sont chargées par `loadTilesetImagesById`.
- `tile_image_loader.dart` décode un vrai fichier image via `ui.instantiateImageCodec` et construit un `RuntimeTilesetImage`.

## 5. Audit fixture / JSON / image runtime

Le format fiable côté test consiste à utiliser les modèles existants :

- `ProjectManifest(...).toJson()` pour `project.json`;
- `MapData(...).toJson()` pour la map;
- `ProjectSurfaceCatalog` intégré dans le champ `surfaceCatalog` du manifest;
- `ProjectTilesetEntry.relativePath` relatif à la racine projet.

Le test n'écrit pas de JSON à la main pour les modèles principaux. Il encode les objets métier avec `JsonEncoder.withIndent('  ')`.

Le PNG est généré à l'exécution avec `package:image` :

- largeur `64`;
- hauteur `32`;
- colonne 0 rouge;
- colonne 1 bleue.

Cette image réelle permet de tester à la fois le chargement disque, le décodage Flutter et le rendu `RuntimeTilesetImage`.

## 6. Architecture de test retenue

Le test reste volontairement dans un seul fichier :

```text
packages/map_runtime/test/surface/surface_runtime_golden_slice_test.dart
```

Il évite un helper partagé prématuré car la fixture est spécifique au golden slice Lot 91.

Pipeline vérifié :

```text
Directory.systemTemp
→ assets/tilesets/surface-water.png
→ project.json
→ maps/surface-test.json
→ loadRuntimeMapBundle(projectFilePath, mapId)
→ collectAllRuntimeTilesetIds
→ resolveTilesetAbsolutePaths
→ loadTilesetImagesById
→ MapLayersComponent
→ render(canvas)
→ pixel RGBA
```

## 7. Fixture projet temporaire

Le test crée un dossier temporaire :

```dart
await Directory.systemTemp.createTemp('pokemap_surface_runtime_');
```

Nettoyage :

```dart
addTearDown(() async {
  if (await projectRoot.exists()) {
    await projectRoot.delete(recursive: true);
  }
});
```

Fichiers écrits :

```text
project.json
maps/surface-test.json
assets/tilesets/surface-water.png
```

Aucun asset du dépôt n'est utilisé.

## 8. Manifest Surface utilisé

Le manifest contient :

- map `surface-test`;
- tileset `surface-water`;
- settings `32 x 32`, `displayScale = 1`;
- atlas `water-atlas`;
- animation `water-loop`;
- preset `water`.

Le preset associe :

```text
SurfaceVariantRole.isolated -> water-loop
```

Ce cas suffit pour un placement unique isolé.

## 9. Map Surface utilisée

La map contient :

- taille `1 x 1`;
- un `SurfaceLayer`;
- un placement `x = 0`, `y = 0`, `surfacePresetId = water`.

Elle est chargée via `loadMapDataFromFile` indirectement par `loadRuntimeMapBundle`.

## 10. Pipeline runtime testé

Le test vérifie explicitement :

- `bundle.projectRootDirectory`;
- `bundle.manifest.surfaceCatalog.presets.single.id == water`;
- présence d'un `SurfaceLayer` dans `bundle.map.layers`;
- `bundle.tilesetAbsolutePathsById` contient le chemin absolu du PNG Surface;
- `loadTilesetImagesById` charge `surface-water`;
- `MapLayersComponent` rend la surface.

## 11. Rendu pixel testé

Le test rend le composant dans un `ui.PictureRecorder`, convertit en `ui.Image`, puis lit le pixel `(16, 16)` en `rawRgba`.

Attendus :

```text
elapsed 0 ms   -> [255, 0, 0, 255]
elapsed 100 ms -> [0, 0, 255, 255]
```

## 12. Animation testée ou raison de report

Animation testée dans ce lot.

Le test appelle :

```dart
component.update(0.1);
```

Puis il re-render le composant. Le pixel attendu passe de rouge à bleu, ce qui prouve que `_animElapsed` alimente bien la timeline Surface dans un scénario chargé depuis disque.

## 13. Tests lancés

Commande :

```bash
cd packages/map_runtime && flutter test test/surface/surface_runtime_golden_slice_test.dart
```

Sortie finale :

```text
00:01 +1: Surface runtime golden slice loads a disk project and renders an animated SurfaceLayer pixel
00:01 +1: All tests passed!
```

Commande :

```bash
cd packages/map_runtime && flutter test test/surface
```

Sortie finale :

```text
00:01 +17: All tests passed!
```

Commande :

```bash
cd packages/map_runtime && flutter test test/runtime_manifest_tilesets_surface_layer_test.dart
```

Sortie finale :

```text
00:01 +1: runtime manifest tileset collection with SurfaceLayer collects Surface atlas tilesets through the runtime manifest path
00:01 +1: All tests passed!
```

Commande :

```bash
cd packages/map_runtime && flutter test test/map_layers_component_render_pass_test.dart
```

Sortie finale :

```text
00:01 +2: MapLayersComponent project-element entity render pass moves flagged props to the foreground pass
00:01 +2: All tests passed!
```

Analyse ciblée :

```bash
cd packages/map_runtime && flutter analyze test/surface/surface_runtime_golden_slice_test.dart
```

Sortie :

```text
Analyzing surface_runtime_golden_slice_test.dart...

No issues found! (ran in 1.4s)
```

## 14. Résultats

Résultats :

- golden slice E2E : vert;
- suite `test/surface` : verte, 17 tests;
- test collecte manifest Surface : vert;
- test render pass `MapLayersComponent` : vert;
- analyse ciblée : clean.

## 15. Fichiers créés

```text
packages/map_runtime/test/surface/surface_runtime_golden_slice_test.dart
reports/surface/surface_engine_lot_91_runtime_surface_golden_slice_e2e.md
```

## 16. Fichiers modifiés

```text
Aucun fichier existant modifié.
```

## 17. Fichiers supprimés

```text
Aucun.
```

## 18. Evidence Pack

Status initial complet : voir section 3.

Status après création du test, avant rapport :

```text
?? packages/map_runtime/test/surface/surface_runtime_golden_slice_test.dart
```

Diff stat après création du test, avant rapport :

```text

```

Note : `git diff --stat` n'affiche pas les fichiers non suivis. Le Gate final relance la commande requise après création du rapport.

Commandes lancées :

```bash
pwd
git branch --show-current
git status --short --untracked-files=all
git diff --stat
git log --oneline -n 10
rg -n "loadRuntimeMapBundle|RuntimeMapBundle|projectRootDirectory|project.json|ProjectManifest|decodeProjectManifest|map json|MapData|fromJson|load.*map|tilesetAbsolutePathsById" packages/map_runtime packages/map_core packages/map_editor
rg -n "RuntimeTilesetImage|loadRuntimeTileset|tilesetAbsolutePathsById|Image|instantiateImageCodec|decodeImage|png|File\(" packages/map_runtime packages/map_core
rg -n "SurfaceLayer|MapLayer.surface|surfaceCatalog|ProjectSurfaceCatalog|SurfaceRuntime|surface_runtime_renderer_test|runtime_manifest_tilesets_surface_layer_test" packages/map_runtime packages/map_core
dart format test/surface/surface_runtime_golden_slice_test.dart
flutter test test/surface/surface_runtime_golden_slice_test.dart
flutter test test/surface
flutter test test/runtime_manifest_tilesets_surface_layer_test.dart
flutter test test/map_layers_component_render_pass_test.dart
flutter analyze test/surface/surface_runtime_golden_slice_test.dart
```

## 19. Git status final

Commande :

```bash
git status --short --untracked-files=all
```

Sortie :

```text
?? packages/map_runtime/test/surface/surface_runtime_golden_slice_test.dart
?? reports/surface/surface_engine_lot_91_runtime_surface_golden_slice_e2e.md
```

Commande :

```bash
git diff --stat
```

Sortie :

```text

```

Note : les fichiers du Lot 91 sont non suivis, donc `git diff --stat` n'affiche aucune ligne. Le status final ci-dessus liste les deux fichiers du lot.

Commande :

```bash
find . -type f \( -name '_gen_*.py' -o -name 'build_*.py' -o -name '*.tmp' \) -print
```

Sortie :

```text

```

Commande :

```bash
git diff --check
```

Sortie :

```text

```

## 20. Périmètre explicitement non touché

Confirmations :

- `map_core` non modifié;
- `map_editor` non modifié;
- `map_gameplay` non modifié;
- `map_battle` non modifié;
- `ProjectManifest` non modifié;
- `surface.dart` non modifié;
- `surface_catalog.dart` non modifié;
- codecs Surface non modifiés;
- aucune migration legacy;
- aucun gameplay surf;
- aucun tall grass encounter;
- aucune nouvelle clock runtime;
- aucun changement JSON volontaire;
- aucun changement Surface Studio;
- aucun changement Surface Painter.

## 21. Contenu complet des fichiers modifiés/créés/supprimés

### `packages/map_runtime/test/surface/surface_runtime_golden_slice_test.dart`

```dart
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/application/load_runtime_map_bundle.dart';
import 'package:map_runtime/src/infrastructure/tile_image_loader.dart';
import 'package:map_runtime/src/presentation/flame/map_layers_component.dart';
import 'package:path/path.dart' as p;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Surface runtime golden slice', () {
    test(
      'loads a disk project and renders an animated SurfaceLayer pixel',
      () async {
        final projectRoot =
            await Directory.systemTemp.createTemp('pokemap_surface_runtime_');
        addTearDown(() async {
          if (await projectRoot.exists()) {
            await projectRoot.delete(recursive: true);
          }
        });

        final tilesetPath = await _writeSurfaceTilesetPng(projectRoot);
        final manifest = _surfaceProjectManifest();
        final map = _surfaceMap();
        await _writeProjectJson(projectRoot, manifest);
        await _writeMapJson(projectRoot, map);

        final bundle = await loadRuntimeMapBundle(
          projectFilePath: p.join(projectRoot.path, 'project.json'),
          mapId: 'surface-test',
        );

        expect(bundle.projectRootDirectory, p.normalize(projectRoot.path));
        expect(bundle.manifest.surfaceCatalog.presets.single.id, 'water');
        expect(bundle.map.layers.whereType<SurfaceLayer>(), hasLength(1));
        expect(
          bundle.tilesetAbsolutePathsById,
          containsPair('surface-water', p.normalize(tilesetPath)),
        );

        final tileImages = await loadTilesetImagesById(
          bundle.tilesetAbsolutePathsById,
        );
        expect(tileImages, contains('surface-water'));

        final component = MapLayersComponent(
          bundle: bundle,
          tileImagesByTilesetId: tileImages,
        );

        final firstFrame = await _renderComponent(component);
        expect(await _pixelAt(firstFrame, 16, 16), _rgba(255, 0, 0, 255));

        component.update(0.1);
        final secondFrame = await _renderComponent(component);
        expect(await _pixelAt(secondFrame, 16, 16), _rgba(0, 0, 255, 255));
      },
    );
  });
}

Future<String> _writeSurfaceTilesetPng(Directory projectRoot) async {
  final tilesetFile = File(
    p.join(projectRoot.path, 'assets', 'tilesets', 'surface-water.png'),
  );
  await tilesetFile.parent.create(recursive: true);

  // The PNG is intentionally tiny but real: two 32x32 frames in one row. This
  // keeps the test independent from repository assets while still exercising
  // Flutter's image decoder and RuntimeTilesetImage loader.
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
    name: 'Surface Runtime Golden Slice',
    maps: const [
      ProjectMapEntry(
        id: 'surface-test',
        name: 'Surface Test',
        relativePath: 'maps/surface-test.json',
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

MapData _surfaceMap() {
  return const MapData(
    id: 'surface-test',
    name: 'Surface Test',
    size: GridSize(width: 1, height: 1),
    layers: [
      MapLayer.surface(
        id: 'surfaces',
        name: 'Surfaces',
        placements: [
          SurfaceCellPlacement(x: 0, y: 0, surfacePresetId: 'water'),
        ],
      ),
    ],
  );
}

Future<void> _writeProjectJson(
  Directory projectRoot,
  ProjectManifest manifest,
) async {
  final projectFile = File(p.join(projectRoot.path, 'project.json'));
  await projectFile.writeAsString(
    const JsonEncoder.withIndent('  ').convert(manifest.toJson()),
  );
}

Future<void> _writeMapJson(Directory projectRoot, MapData map) async {
  final mapFile = File(p.join(projectRoot.path, 'maps', 'surface-test.json'));
  await mapFile.parent.create(recursive: true);
  await mapFile.writeAsString(
    const JsonEncoder.withIndent('  ').convert(map.toJson()),
  );
}

Future<ui.Image> _renderComponent(MapLayersComponent component) {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
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

### `reports/surface/surface_engine_lot_91_runtime_surface_golden_slice_e2e.md`

Le présent fichier est le rapport créé pour le lot. Pour éviter une récursion infinie, son contenu complet n'est pas dupliqué dans lui-même; le fichier courant constitue son contenu complet.

Fichiers supprimés : aucun.

## 22. Limites restantes

- Le golden slice couvre un placement isolé, pas un grand patch autotile multi-rôles.
- L'image test couvre deux frames sur un seul atlas/tileset; elle ne couvre pas une animation multi-atlas.
- Le test vérifie `MapLayersComponent` directement, pas `PlayableMapGame` complet.
- Le test ne vérifie pas de gameplay surf/tall grass, volontairement hors périmètre.

Ces limites sont cohérentes avec le Lot 91 : preuve E2E runtime Surface depuis disque, sans nouvelle feature.

## 23. Auto-critique

Le test est utile et très ciblé, mais il reste plus proche d'un golden slice loader + renderer que d'un vrai test "jeu lancé" avec `PlayableMapGame`. C'est un choix conservateur : le prompt acceptait `RuntimeMapGame / PlayableMapGame` comme objectif général, mais les critères détaillés demandaient surtout `loadRuntimeMapBundle` + `MapLayersComponent` + pixel. Pour un futur lot, un vrai smoke `PlayableMapGame` aurait du sens si l'initialisation Flame peut rester déterministe et légère.

Le test est passé immédiatement, donc il ne s'agit pas d'un correctif TDD rouge/vert classique. Il caractérise et verrouille une chaîne rendue possible par les Lots 89/90.

## 24. Regard critique sur le prompt

Le prompt est bon sur l'intention : prouver le pipeline complet à partir d'un vrai projet disque. Il est toutefois légèrement ambigu sur le niveau E2E attendu : il cite `RuntimeMapGame / PlayableMapGame`, puis accepte explicitement `loadRuntimeMapBundle` et `MapLayersComponent`. Le choix retenu suit le critère le plus vérifiable et le moins risqué.

L'exigence "contenu complet du rapport dans le rapport" crée une récursion impossible si appliquée littéralement aux fichiers de rapport. Le rapport inclut donc le contenu complet du test créé et considère le fichier courant comme son propre contenu complet.

## Auto-review obligatoire

- Est-ce qu'un projet disque temporaire Surface est créé ? Oui.
- Est-ce que le manifest est chargé via le pipeline runtime réel ? Oui.
- Est-ce que la map Surface est chargée via le pipeline runtime réel ? Oui.
- Est-ce que le tileset PNG réel est écrit et chargé ? Oui.
- Est-ce que le SurfaceLayer est présent dans le bundle runtime ? Oui.
- Est-ce que le tileset Surface est collecté/résolu ? Oui.
- Est-ce qu'un pixel Surface attendu est rendu ? Oui.
- Est-ce que l'animation Surface est testée ? Oui, rouge à elapsed 0 puis bleu après `component.update(0.1)`.
- Est-ce que MapLayersComponent continue de passer ses tests ? Oui.
- Est-ce que map_core est inchangé ? Oui.
- Est-ce que map_editor est inchangé ? Oui.
- Est-ce qu'un Lot 91-bis est nécessaire ? Non pour la preuve demandée; oui seulement si on veut un smoke `PlayableMapGame` complet au lieu du couple loader + renderer.
