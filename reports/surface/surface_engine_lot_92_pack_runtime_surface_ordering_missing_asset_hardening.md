# Lot 92-pack — Runtime Surface Ordering / Regression / Missing Asset Hardening V0

## 1. Résumé exécutif honnête

Lot 92-pack durcit le runtime Surface par des tests de non-régression ciblés. Aucun code de production n'a été modifié : les comportements attendus existaient déjà après les Lots 89 à 91, mais ils n'étaient pas verrouillés avec assez de précision.

Ajouts principaux :

- tests pixels pour l'ordre de rendu `terrain/path -> surface -> tile -> entities -> collision overlay`;
- test explicite que `SurfaceLayer` reste absent du foreground pass;
- tests visibilité/opacité Surface;
- tests de skip sans crash pour image manquante, catalogue incomplet, source hors atlas;
- tests de chargement disque contrôlant les erreurs `AssetNotFoundException` quand le manifest ne déclare pas le tileset requis ou quand le PNG manque.

Le Lot 91 était encore non suivi au Gate 0. Il est traité comme changement préexistant dans ce rapport.

## 2. Périmètre

Inclus :

- `packages/map_runtime/test/surface/surface_runtime_test_support.dart`
- `packages/map_runtime/test/surface/surface_runtime_ordering_test.dart`
- `packages/map_runtime/test/surface/surface_runtime_missing_assets_test.dart`
- rapport Lot 92-pack.

Exclus :

- aucune modification `map_core`;
- aucune modification `map_editor`;
- aucune modification `map_gameplay`;
- aucune modification `map_battle`;
- aucune modification `MapLayersComponent`;
- aucune feature gameplay;
- aucune nouvelle clock runtime;
- aucun changement JSON volontaire.

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

Changements préexistants au Lot 92-pack :

```text
packages/map_runtime/test/surface/surface_runtime_golden_slice_test.dart
reports/surface/surface_engine_lot_91_runtime_surface_golden_slice_e2e.md
```

## 4. Audit runtime Surface actuel

Commandes d'audit lancées :

```bash
rg -n "SurfaceLayer|resolveSurfaceRuntimeRenderInstructions|_paintSurfaceLayer|MapLayersComponent|renderPass|background|foreground|_paintTerrainLayer|_paintPathLayer|_paintTileLayer|_paintEntities|showCollisionOverlay" packages/map_runtime/lib packages/map_runtime/test
rg -n "loadRuntimeMapBundle|loadTilesetImagesById|RuntimeMapBundle|tilesetAbsolutePathsById|surface_runtime_golden_slice|surface_runtime_renderer_test" packages/map_runtime/lib packages/map_runtime/test
rg -n "ProjectSurfaceCatalog|ProjectSurfacePreset|ProjectSurfaceAnimation|ProjectSurfaceAtlas|SurfaceRuntimeRenderInstruction|containsSourceRect|RuntimeTilesetImage" packages/map_runtime/lib packages/map_runtime/test packages/map_core/lib
```

Fichiers inspectés :

- `packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart`
- `packages/map_runtime/lib/src/surface/surface_runtime_resolver.dart`
- `packages/map_runtime/lib/src/infrastructure/runtime_tileset_image.dart`
- `packages/map_runtime/lib/src/infrastructure/tile_image_loader.dart`
- `packages/map_runtime/lib/src/application/load_runtime_map_bundle.dart`
- `packages/map_runtime/test/surface/surface_runtime_renderer_test.dart`
- `packages/map_runtime/test/surface/surface_runtime_golden_slice_test.dart`
- `packages/map_runtime/test/runtime_manifest_tilesets_surface_layer_test.dart`

Constats :

- Le resolver Surface runtime est pur et skippe les références incomplètes.
- `_paintSurfaceLayer` consomme des `SurfaceRuntimeRenderInstruction`.
- Le renderer vérifie l'image manquante et `containsSourceRect`.
- Le loader disque ne vérifie pas l'existence physique du PNG pendant `loadRuntimeMapBundle`; l'erreur PNG arrive pendant `loadTilesetImagesById`.
- Un tileset Surface requis mais absent de `ProjectManifest.tilesets` déclenche `AssetNotFoundException` pendant `loadRuntimeMapBundle`.

## 5. Audit ordre de rendu

Ordre actuel exact en background pass dans `MapLayersComponent.render` :

```text
terrain
path
surface
tile
entities
collision overlay si showCollisionOverlay = true
```

Ordre actuel en foreground pass :

```text
foreground tile layers
foreground entities
```

Surface n'est pas rendue en foreground V0. C'est volontaire : les surfaces sont des overlays de sol et restent sous les tile layers décoratifs/foreground et sous les entités.

## 6. Audit golden slice Lot 91

Le Lot 91 ajoute un test disque réel non suivi au moment du Gate 0 :

```text
packages/map_runtime/test/surface/surface_runtime_golden_slice_test.dart
```

Ce test écrit un PNG réel, un `project.json`, une map JSON, charge via `loadRuntimeMapBundle`, charge l'image via `loadTilesetImagesById`, rend `MapLayersComponent`, puis vérifie rouge à elapsed `0` et bleu après `update(0.1)`.

Lot 92-pack ne modifie pas ce fichier, mais `flutter test test/surface` le relance et confirme qu'il reste vert.

## 7. Architecture retenue

Architecture de hardening retenue :

- ajouter un helper test-only pour éviter de dupliquer la construction de `RuntimeMapBundle`, `ProjectSurfaceCatalog`, `RuntimeTilesetImage` et lecture pixel;
- créer un test d'ordre de rendu dédié;
- créer un test assets/catalogue manquants dédié;
- ne pas modifier le renderer tant que les tests ne révèlent pas de bug.

Aucune API runtime publique n'a été ajoutée.

## 8. Tests ordre de rendu

Fichier :

```text
packages/map_runtime/test/surface/surface_runtime_ordering_test.dart
```

Tests ajoutés :

- `renders SurfaceLayer above terrain and path in background pass`
- `renders TileLayer above SurfaceLayer in background pass`
- `renders project element entities above SurfaceLayer`
- `renders collision overlay above SurfaceLayer when enabled`
- `keeps SurfaceLayer out of foreground pass`
- `respects SurfaceLayer visibility and opacity`

## 9. Tests visibilité / opacité

Le test `respects SurfaceLayer visibility and opacity` couvre :

- `isVisible=false` -> pixel transparent;
- `opacity=0` -> pixel transparent;
- `opacity=0.5` -> alpha strictement entre `0` et `255`.

La validation du modèle (`opacity < 0` ou `> 1`) reste dans `map_core`; ce lot ne duplique pas cette logique.

## 10. Tests assets manquants / catalogue incomplet

Fichier :

```text
packages/map_runtime/test/surface/surface_runtime_missing_assets_test.dart
```

Tests ajoutés :

- image Surface absente de `tileImagesByTilesetId` -> surface skip, tile layer rouge continue;
- preset manquant -> pixel transparent;
- animation manquante -> pixel transparent;
- atlas manquant -> pixel transparent;
- source hors atlas -> pixel transparent;
- tileset requis absent du manifest -> `AssetNotFoundException` contrôlée dans `loadRuntimeMapBundle`;
- PNG Surface absent du disque -> `AssetNotFoundException` contrôlée dans `loadTilesetImagesById`.

Aucun fallback debug jaune runtime n'est dessiné dans ces cas.

## 11. Golden slice complémentaire

Le golden slice Lot 91 est relancé dans `flutter test test/surface`, qui inclut maintenant :

- resolver;
- collector;
- renderer;
- ordering;
- missing assets;
- golden slice disque réel.

Je n'ai pas modifié le fichier Lot 91 pour éviter de mélanger changements préexistants et changements Lot 92-pack.

## 12. Implémentation

Fichiers créés :

- `surface_runtime_test_support.dart` : helpers test-only pour créer un bundle, un catalogue Surface minimal, une image runtime en mémoire, rendre un composant et lire un pixel.
- `surface_runtime_ordering_test.dart` : tests pixels de l'ordre de rendu.
- `surface_runtime_missing_assets_test.dart` : tests pixels et disque réel pour assets/références manquants.

Aucun fichier de production modifié.

## 13. Tests lancés

Commande :

```bash
cd packages/map_runtime && flutter test test/surface/surface_runtime_ordering_test.dart
```

Sortie :

```text
00:01 +0: loading /Users/karim/Project/pokemonProject/packages/map_runtime/test/surface/surface_runtime_ordering_test.dart
00:01 +0: Surface runtime ordering hardening renders SurfaceLayer above terrain and path in background pass
00:01 +1: Surface runtime ordering hardening renders SurfaceLayer above terrain and path in background pass
00:01 +1: Surface runtime ordering hardening renders TileLayer above SurfaceLayer in background pass
00:01 +2: Surface runtime ordering hardening renders TileLayer above SurfaceLayer in background pass
00:01 +2: Surface runtime ordering hardening renders project element entities above SurfaceLayer
00:01 +3: Surface runtime ordering hardening renders project element entities above SurfaceLayer
00:01 +3: Surface runtime ordering hardening renders collision overlay above SurfaceLayer when enabled
00:01 +4: Surface runtime ordering hardening renders collision overlay above SurfaceLayer when enabled
00:01 +4: Surface runtime ordering hardening keeps SurfaceLayer out of foreground pass
00:01 +5: Surface runtime ordering hardening keeps SurfaceLayer out of foreground pass
00:01 +5: Surface runtime ordering hardening respects SurfaceLayer visibility and opacity
00:01 +6: Surface runtime ordering hardening respects SurfaceLayer visibility and opacity
00:01 +6: All tests passed!
```

Commande :

```bash
cd packages/map_runtime && flutter test test/surface/surface_runtime_missing_assets_test.dart
```

Sortie :

```text
00:01 +0: loading /Users/karim/Project/pokemonProject/packages/map_runtime/test/surface/surface_runtime_missing_assets_test.dart
00:01 +0: Surface runtime missing asset hardening skips missing Surface tileset image and keeps other layers rendering
00:01 +1: Surface runtime missing asset hardening skips missing Surface tileset image and keeps other layers rendering
00:01 +1: Surface runtime missing asset hardening skips incomplete Surface catalog references without debug fallback
00:01 +2: Surface runtime missing asset hardening skips incomplete Surface catalog references without debug fallback
00:01 +2: Surface runtime missing asset hardening reports a controlled error when manifest omits a required tileset
00:02 +2: Surface runtime missing asset hardening reports a controlled error when manifest omits a required tileset
00:02 +3: Surface runtime missing asset hardening reports a controlled error when manifest omits a required tileset
00:02 +3: Surface runtime missing asset hardening reports a controlled error when the Surface PNG is missing
00:02 +4: Surface runtime missing asset hardening reports a controlled error when the Surface PNG is missing
00:02 +4: All tests passed!
```

Commande :

```bash
cd packages/map_runtime && flutter test test/surface
```

Sortie finale :

```text
00:01 +27: All tests passed!
```

Commande :

```bash
cd packages/map_runtime && flutter test test/runtime_manifest_tilesets_surface_layer_test.dart
```

Sortie :

```text
00:01 +0: runtime manifest tileset collection with SurfaceLayer collects Surface atlas tilesets through the runtime manifest path
00:01 +1: runtime manifest tileset collection with SurfaceLayer collects Surface atlas tilesets through the runtime manifest path
00:01 +1: All tests passed!
```

Commande :

```bash
cd packages/map_runtime && flutter test test/map_layers_component_render_pass_test.dart
```

Sortie :

```text
00:01 +0: MapLayersComponent project-element entity render pass keeps default entities in the background pass
00:01 +1: MapLayersComponent project-element entity render pass keeps default entities in the background pass
00:01 +1: MapLayersComponent project-element entity render pass moves flagged props to the foreground pass
00:01 +2: MapLayersComponent project-element entity render pass moves flagged props to the foreground pass
00:01 +2: All tests passed!
```

Analyse ciblée :

```bash
cd packages/map_runtime && flutter analyze test/surface/surface_runtime_test_support.dart test/surface/surface_runtime_ordering_test.dart test/surface/surface_runtime_missing_assets_test.dart test/surface/surface_runtime_golden_slice_test.dart
```

Sortie :

```text
Analyzing 4 items...

No issues found! (ran in 1.4s)
```

## 14. Résultats

Résultats :

- tests ordering : verts, 6 tests;
- tests missing assets : verts, 4 tests;
- suite `test/surface` : verte, 27 tests;
- tileset collection Surface manifest : vert;
- render pass MapLayersComponent : vert;
- analyse ciblée : clean.

## 15. Fichiers créés

Lot 92-pack :

```text
packages/map_runtime/test/surface/surface_runtime_test_support.dart
packages/map_runtime/test/surface/surface_runtime_ordering_test.dart
packages/map_runtime/test/surface/surface_runtime_missing_assets_test.dart
reports/surface/surface_engine_lot_92_pack_runtime_surface_ordering_missing_asset_hardening.md
```

Préexistants au Gate 0, non créés par Lot 92-pack :

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

Commandes lancées :

```bash
pwd
git branch --show-current
git status --short --untracked-files=all
git diff --stat
git log --oneline -n 10
rg -n "SurfaceLayer|resolveSurfaceRuntimeRenderInstructions|_paintSurfaceLayer|MapLayersComponent|renderPass|background|foreground|_paintTerrainLayer|_paintPathLayer|_paintTileLayer|_paintEntities|showCollisionOverlay" packages/map_runtime/lib packages/map_runtime/test
rg -n "loadRuntimeMapBundle|loadTilesetImagesById|RuntimeMapBundle|tilesetAbsolutePathsById|surface_runtime_golden_slice|surface_runtime_renderer_test" packages/map_runtime/lib packages/map_runtime/test
rg -n "ProjectSurfaceCatalog|ProjectSurfacePreset|ProjectSurfaceAnimation|ProjectSurfaceAtlas|SurfaceRuntimeRenderInstruction|containsSourceRect|RuntimeTilesetImage" packages/map_runtime/lib packages/map_runtime/test packages/map_core/lib
dart format test/surface/surface_runtime_test_support.dart test/surface/surface_runtime_ordering_test.dart test/surface/surface_runtime_missing_assets_test.dart
flutter test test/surface/surface_runtime_ordering_test.dart
flutter test test/surface/surface_runtime_missing_assets_test.dart
flutter test test/surface
flutter test test/runtime_manifest_tilesets_surface_layer_test.dart
flutter test test/map_layers_component_render_pass_test.dart
flutter analyze test/surface/surface_runtime_test_support.dart test/surface/surface_runtime_ordering_test.dart test/surface/surface_runtime_missing_assets_test.dart test/surface/surface_runtime_golden_slice_test.dart
```

## 19. Git status final

Commande :

```bash
git status --short --untracked-files=all
```

Sortie :

```text
?? packages/map_runtime/test/surface/surface_runtime_golden_slice_test.dart
?? packages/map_runtime/test/surface/surface_runtime_missing_assets_test.dart
?? packages/map_runtime/test/surface/surface_runtime_ordering_test.dart
?? packages/map_runtime/test/surface/surface_runtime_test_support.dart
?? reports/surface/surface_engine_lot_91_runtime_surface_golden_slice_e2e.md
?? reports/surface/surface_engine_lot_92_pack_runtime_surface_ordering_missing_asset_hardening.md
```

Changements préexistants :

```text
?? packages/map_runtime/test/surface/surface_runtime_golden_slice_test.dart
?? reports/surface/surface_engine_lot_91_runtime_surface_golden_slice_e2e.md
```

Changements du Lot 92-pack :

```text
?? packages/map_runtime/test/surface/surface_runtime_missing_assets_test.dart
?? packages/map_runtime/test/surface/surface_runtime_ordering_test.dart
?? packages/map_runtime/test/surface/surface_runtime_test_support.dart
?? reports/surface/surface_engine_lot_92_pack_runtime_surface_ordering_missing_asset_hardening.md
```

Commande :

```bash
git diff --stat
```

Sortie :

```text

```

Note : tous les fichiers du Lot 92-pack sont non suivis, donc `git diff --stat` n'affiche aucune ligne.

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

### `packages/map_runtime/test/surface/surface_runtime_test_support.dart`

```dart
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/application/runtime_map_bundle.dart';
import 'package:map_runtime/src/infrastructure/runtime_tileset_image.dart';
import 'package:map_runtime/src/presentation/flame/map_layers_component.dart';

const int surfaceTestTileSize = 32;

RuntimeMapBundle surfaceTestBundle({
  required MapData map,
  ProjectSurfaceCatalog? surfaceCatalog,
  List<ProjectTilesetEntry> tilesets = const <ProjectTilesetEntry>[
    ProjectTilesetEntry(
      id: 'surface-water',
      name: 'Surface Water',
      relativePath: 'tilesets/surface-water.png',
    ),
    ProjectTilesetEntry(
      id: 'base',
      name: 'Base',
      relativePath: 'tilesets/base.png',
    ),
    ProjectTilesetEntry(
      id: 'entity',
      name: 'Entity',
      relativePath: 'tilesets/entity.png',
    ),
  ],
  List<ProjectTerrainPreset> terrainPresets = const <ProjectTerrainPreset>[],
  List<ProjectPathPreset> pathPresets = const <ProjectPathPreset>[],
  List<ProjectElementEntry> elements = const <ProjectElementEntry>[],
}) {
  return RuntimeMapBundle(
    manifest: ProjectManifest(
      name: 'Surface Runtime Test',
      maps: const <ProjectMapEntry>[],
      tilesets: tilesets,
      settings: const ProjectSettings(
        tileWidth: surfaceTestTileSize,
        tileHeight: surfaceTestTileSize,
        displayScale: 1,
      ),
      terrainPresets: terrainPresets,
      pathPresets: pathPresets,
      elements: elements,
      surfaceCatalog: surfaceCatalog ?? surfaceTestCatalog(),
    ),
    map: map,
    projectRootDirectory: '/tmp/surface-runtime-test',
    tilesetAbsolutePathsById: const <String, String>{},
  );
}

MapData surfaceTestMap({
  required List<MapLayer> layers,
  List<MapEntity> entities = const <MapEntity>[],
}) {
  return MapData(
    id: 'surface-test',
    name: 'Surface Test',
    size: const GridSize(width: 1, height: 1),
    layers: layers,
    entities: entities,
  );
}

SurfaceLayer surfaceTestLayer({
  bool isVisible = true,
  double opacity = 1,
  String surfacePresetId = 'water',
}) {
  return SurfaceLayer(
    id: 'surfaces',
    name: 'Surfaces',
    isVisible: isVisible,
    opacity: opacity,
    placements: [
      SurfaceCellPlacement(
        x: 0,
        y: 0,
        surfacePresetId: surfacePresetId,
      ),
    ],
  );
}

ProjectSurfaceCatalog surfaceTestCatalog({
  bool includeAtlas = true,
  bool includeAnimation = true,
  bool includePreset = true,
  int atlasColumns = 1,
  int sourceColumn = 0,
  String atlasTilesetId = 'surface-water',
  String animationId = 'water-loop',
}) {
  return ProjectSurfaceCatalog(
    atlases: [
      if (includeAtlas)
        ProjectSurfaceAtlas(
          id: 'water-atlas',
          name: 'Water Atlas',
          tilesetId: atlasTilesetId,
          geometry: SurfaceAtlasGeometry(
            tileSize: SurfaceAtlasTileSize(
              width: surfaceTestTileSize,
              height: surfaceTestTileSize,
            ),
            gridSize: SurfaceAtlasGridSize(columns: atlasColumns, rows: 1),
          ),
        ),
    ],
    animations: [
      if (includeAnimation)
        ProjectSurfaceAnimation(
          id: animationId,
          name: 'Water Loop',
          timeline: SurfaceAnimationTimeline(
            frames: [
              SurfaceAnimationFrame(
                tileRef: SurfaceAtlasTileRef(
                  atlasId: 'water-atlas',
                  column: sourceColumn,
                  row: 0,
                ),
                durationMs: 100,
              ),
            ],
          ),
        ),
    ],
    presets: [
      if (includePreset)
        ProjectSurfacePreset(
          id: 'water',
          name: 'Water',
          variantAnimations: SurfaceVariantAnimationRefSet(
            refs: [
              SurfaceVariantAnimationRef(
                role: SurfaceVariantRole.isolated,
                animationId: animationId,
              ),
            ],
          ),
        ),
    ],
  );
}

ProjectElementEntry surfaceTestElement({
  String id = 'entity-prop',
  String tilesetId = 'entity',
}) {
  return ProjectElementEntry(
    id: id,
    name: id,
    tilesetId: tilesetId,
    categoryId: '',
    frames: const [
      TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 0)),
    ],
  );
}

Future<RuntimeTilesetImage> runtimeTilesetImage(List<Color> colors) async {
  final image = await uiImageFromTileColors(colors);
  return RuntimeTilesetImage(
    images: [image],
    chunks: [
      RuntimeTilesetChunk(
        top: 0,
        height: surfaceTestTileSize,
        width: colors.length * surfaceTestTileSize,
      ),
    ],
    width: colors.length * surfaceTestTileSize,
    height: surfaceTestTileSize,
  );
}

Future<ui.Image> uiImageFromTileColors(List<Color> colors) {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  for (var i = 0; i < colors.length; i++) {
    canvas.drawRect(
      Rect.fromLTWH(
        (i * surfaceTestTileSize).toDouble(),
        0,
        surfaceTestTileSize.toDouble(),
        surfaceTestTileSize.toDouble(),
      ),
      Paint()..color = colors[i],
    );
  }
  return recorder.endRecording().toImage(
        colors.length * surfaceTestTileSize,
        surfaceTestTileSize,
      );
}

Future<ui.Image> renderSurfaceTestComponent(MapLayersComponent component) {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  component.render(canvas);
  return recorder.endRecording().toImage(
        surfaceTestTileSize,
        surfaceTestTileSize,
      );
}

Future<List<int>> pixelAt(ui.Image image, int x, int y) async {
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  final offset = (y * image.width + x) * 4;
  return [
    data!.getUint8(offset),
    data.getUint8(offset + 1),
    data.getUint8(offset + 2),
    data.getUint8(offset + 3),
  ];
}

List<int> rgba(int red, int green, int blue, int alpha) {
  return [red, green, blue, alpha];
}
```

### `packages/map_runtime/test/surface/surface_runtime_ordering_test.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/presentation/flame/map_layers_component.dart';

import 'surface_runtime_test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Surface runtime ordering hardening', () {
    test('renders SurfaceLayer above terrain and path in background pass',
        () async {
      final component = MapLayersComponent(
        bundle: surfaceTestBundle(
          map: surfaceTestMap(
            layers: [
              const MapLayer.terrain(
                id: 'terrain',
                name: 'Terrain',
                terrains: [TerrainType.grass],
              ),
              const MapLayer.path(
                id: 'path',
                name: 'Path',
                cells: [true],
              ),
              surfaceTestLayer(),
            ],
          ),
        ),
        tileImagesByTilesetId: {
          'surface-water': await runtimeTilesetImage([const Color(0xFF0000FF)]),
        },
      );

      final image = await renderSurfaceTestComponent(component);

      expect(await pixelAt(image, 16, 16), rgba(0, 0, 255, 255));
    });

    test('renders TileLayer above SurfaceLayer in background pass', () async {
      final component = MapLayersComponent(
        bundle: surfaceTestBundle(
          map: surfaceTestMap(
            layers: [
              surfaceTestLayer(),
              const MapLayer.tile(
                id: 'tile',
                name: 'Tile',
                tilesetId: 'base',
                tiles: [1],
              ),
            ],
          ),
        ),
        tileImagesByTilesetId: {
          'surface-water': await runtimeTilesetImage([const Color(0xFF0000FF)]),
          'base': await runtimeTilesetImage([const Color(0xFFFF0000)]),
        },
      );

      final image = await renderSurfaceTestComponent(component);

      expect(await pixelAt(image, 16, 16), rgba(255, 0, 0, 255));
    });

    test('renders project element entities above SurfaceLayer', () async {
      final component = MapLayersComponent(
        bundle: surfaceTestBundle(
          elements: [surfaceTestElement()],
          map: surfaceTestMap(
            layers: [surfaceTestLayer()],
            entities: const [
              MapEntity(
                id: 'entity',
                kind: MapEntityKind.custom,
                pos: GridPos(x: 0, y: 0),
                editorVisual: MapEntityEditorVisual(
                  elementId: 'entity-prop',
                ),
              ),
            ],
          ),
        ),
        tileImagesByTilesetId: {
          'surface-water': await runtimeTilesetImage([const Color(0xFF0000FF)]),
          'entity': await runtimeTilesetImage([const Color(0xFF800080)]),
        },
      );

      final image = await renderSurfaceTestComponent(component);

      expect(await pixelAt(image, 16, 16), rgba(128, 0, 128, 255));
    });

    test('renders collision overlay above SurfaceLayer when enabled', () async {
      final component = MapLayersComponent(
        bundle: surfaceTestBundle(
          map: surfaceTestMap(
            layers: [
              surfaceTestLayer(),
              const MapLayer.collision(
                id: 'collision',
                name: 'Collision',
                collisions: [true],
              ),
            ],
          ),
        ),
        tileImagesByTilesetId: {
          'surface-water': await runtimeTilesetImage([const Color(0xFF0000FF)]),
        },
        showCollisionOverlay: true,
      );

      final image = await renderSurfaceTestComponent(component);
      final pixel = await pixelAt(image, 16, 16);

      expect(pixel[0], greaterThan(0));
      expect(pixel[1], greaterThan(0));
      expect(pixel[2], lessThan(255));
      expect(pixel[3], 255);
    });

    test('keeps SurfaceLayer out of foreground pass', () async {
      final component = MapLayersComponent(
        bundle: surfaceTestBundle(
          map: surfaceTestMap(layers: [surfaceTestLayer()]),
        ),
        tileImagesByTilesetId: {
          'surface-water': await runtimeTilesetImage([const Color(0xFF0000FF)]),
        },
        renderPass: MapLayerRenderPass.foreground,
      );

      final image = await renderSurfaceTestComponent(component);

      expect(await pixelAt(image, 16, 16), rgba(0, 0, 0, 0));
    });

    test('respects SurfaceLayer visibility and opacity', () async {
      final invisible = MapLayersComponent(
        bundle: surfaceTestBundle(
          map: surfaceTestMap(
            layers: [surfaceTestLayer(isVisible: false)],
          ),
        ),
        tileImagesByTilesetId: {
          'surface-water': await runtimeTilesetImage([const Color(0xFF0000FF)]),
        },
      );
      expect(
        await pixelAt(await renderSurfaceTestComponent(invisible), 16, 16),
        rgba(0, 0, 0, 0),
      );

      final transparent = MapLayersComponent(
        bundle: surfaceTestBundle(
          map: surfaceTestMap(
            layers: [surfaceTestLayer(opacity: 0)],
          ),
        ),
        tileImagesByTilesetId: {
          'surface-water': await runtimeTilesetImage([const Color(0xFF0000FF)]),
        },
      );
      expect(
        await pixelAt(await renderSurfaceTestComponent(transparent), 16, 16),
        rgba(0, 0, 0, 0),
      );

      final halfOpacity = MapLayersComponent(
        bundle: surfaceTestBundle(
          map: surfaceTestMap(
            layers: [surfaceTestLayer(opacity: 0.5)],
          ),
        ),
        tileImagesByTilesetId: {
          'surface-water': await runtimeTilesetImage([const Color(0xFF0000FF)]),
        },
      );
      final halfOpacityPixel = await pixelAt(
        await renderSurfaceTestComponent(halfOpacity),
        16,
        16,
      );
      expect(halfOpacityPixel[3], greaterThan(0));
      expect(halfOpacityPixel[3], lessThan(255));
    });
  });
}
```

### `packages/map_runtime/test/surface/surface_runtime_missing_assets_test.dart`

```dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/application/load_runtime_map_bundle.dart';
import 'package:map_runtime/src/infrastructure/tile_image_loader.dart';
import 'package:map_runtime/src/presentation/flame/map_layers_component.dart';
import 'package:path/path.dart' as p;

import 'surface_runtime_test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Surface runtime missing asset hardening', () {
    test('skips missing Surface tileset image and keeps other layers rendering',
        () async {
      final component = MapLayersComponent(
        bundle: surfaceTestBundle(
          map: surfaceTestMap(
            layers: [
              surfaceTestLayer(),
              const MapLayer.tile(
                id: 'tile',
                name: 'Tile',
                tilesetId: 'base',
                tiles: [1],
              ),
            ],
          ),
        ),
        tileImagesByTilesetId: {
          'base': await runtimeTilesetImage([const Color(0xFFFF0000)]),
        },
      );

      final image = await renderSurfaceTestComponent(component);

      expect(await pixelAt(image, 16, 16), rgba(255, 0, 0, 255));
    });

    test('skips incomplete Surface catalog references without debug fallback',
        () async {
      final cases = <String, ProjectSurfaceCatalog>{
        'missing preset': surfaceTestCatalog(includePreset: false),
        'missing animation': surfaceTestCatalog(includeAnimation: false),
        'missing atlas': surfaceTestCatalog(includeAtlas: false),
        'source outside atlas': surfaceTestCatalog(
          atlasColumns: 1,
          sourceColumn: 2,
        ),
      };

      for (final entry in cases.entries) {
        final component = MapLayersComponent(
          bundle: surfaceTestBundle(
            surfaceCatalog: entry.value,
            map: surfaceTestMap(layers: [surfaceTestLayer()]),
          ),
          tileImagesByTilesetId: {
            'surface-water':
                await runtimeTilesetImage([const Color(0xFFFFFF00)]),
          },
        );

        final image = await renderSurfaceTestComponent(component);

        expect(
          await pixelAt(image, 16, 16),
          rgba(0, 0, 0, 0),
          reason: entry.key,
        );
      }
    });

    test('reports a controlled error when manifest omits a required tileset',
        () async {
      final projectRoot =
          await Directory.systemTemp.createTemp('pokemap_surface_missing_');
      addTearDown(() async {
        if (await projectRoot.exists()) {
          await projectRoot.delete(recursive: true);
        }
      });
      await _writeDiskProject(
        projectRoot,
        tilesets: const <ProjectTilesetEntry>[],
      );

      expect(
        () => loadRuntimeMapBundle(
          projectFilePath: p.join(projectRoot.path, 'project.json'),
          mapId: 'surface-test',
        ),
        throwsA(isA<AssetNotFoundException>()),
      );
    });

    test('reports a controlled error when the Surface PNG is missing',
        () async {
      final projectRoot =
          await Directory.systemTemp.createTemp('pokemap_surface_missing_png_');
      addTearDown(() async {
        if (await projectRoot.exists()) {
          await projectRoot.delete(recursive: true);
        }
      });
      await _writeDiskProject(
        projectRoot,
        tilesets: const [
          ProjectTilesetEntry(
            id: 'surface-water',
            name: 'Surface Water',
            relativePath: 'assets/tilesets/missing-water.png',
          ),
        ],
      );

      final bundle = await loadRuntimeMapBundle(
        projectFilePath: p.join(projectRoot.path, 'project.json'),
        mapId: 'surface-test',
      );

      expect(
        () => loadTilesetImagesById(bundle.tilesetAbsolutePathsById),
        throwsA(isA<AssetNotFoundException>()),
      );
    });
  });
}

Future<void> _writeDiskProject(
  Directory projectRoot, {
  required List<ProjectTilesetEntry> tilesets,
}) async {
  await _writeProjectJson(
    projectRoot,
    ProjectManifest(
      name: 'Surface Missing Asset Test',
      maps: const [
        ProjectMapEntry(
          id: 'surface-test',
          name: 'Surface Test',
          relativePath: 'maps/surface-test.json',
        ),
      ],
      tilesets: tilesets,
      settings: const ProjectSettings(
        tileWidth: surfaceTestTileSize,
        tileHeight: surfaceTestTileSize,
        displayScale: 1,
      ),
      surfaceCatalog: surfaceTestCatalog(),
    ),
  );
  await _writeMapJson(
    projectRoot,
    surfaceTestMap(layers: [surfaceTestLayer()]),
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
```

### `reports/surface/surface_engine_lot_92_pack_runtime_surface_ordering_missing_asset_hardening.md`

Le présent fichier est le rapport créé pour le lot. Pour éviter une récursion infinie, son contenu complet n'est pas dupliqué dans lui-même.

Fichiers supprimés : aucun.

## 22. Limites restantes

- Ces tests restent des tests de composant/runtime ciblés, pas un smoke `PlayableMapGame`.
- Les cas multi-atlas et multi-map ne sont pas couverts ici.
- L'ordre de rendu est verrouillé par pixels sur une cellule `1 x 1`; cela suffit pour les priorités de pass, mais pas pour tous les cas visuels de maps complexes.
- Les erreurs assets disque sont vérifiées comme exceptions contrôlées; il n'y a pas de diagnostic utilisateur/runtime enrichi, volontairement hors périmètre.

## 23. Auto-critique

Le lot est utile parce qu'il transforme des comportements implicites en garde-fous tests. Il n'améliore pas l'architecture runtime et ne rend pas le renderer plus intelligent. C'est assumé : le renderer fonctionne déjà, et le risque principal était maintenant la régression.

Le helper test-only ajoute un petit point de maintenance, mais il évite de recopier des dizaines de lignes de fixture dans chaque test Surface runtime. Il reste local au dossier `test/surface` et ne crée aucune API production.

## 24. Regard critique sur le prompt

Le prompt combine deux lots, mais leur point commun est net : durcissement runtime après golden slice. Le périmètre reste cohérent.

Le seul point délicat est l'exigence de "sorties exactes" et "contenu complet" dans un rapport qui se crée lui-même. Comme pour les lots précédents, le rapport ne peut pas se recopier récursivement; il inclut donc le contenu complet des fichiers de test créés et documente cette exception.

## Auto-review obligatoire

- Est-ce que l'ordre terrain/path/surface/tile/entities est testé ? Oui.
- Est-ce que les surfaces restent background-only en V0 ? Oui.
- Est-ce que tile layer au-dessus de surface est testé ? Oui.
- Est-ce que foreground pass ignore SurfaceLayer ? Oui.
- Est-ce que isVisible=false est testé ? Oui.
- Est-ce que opacity=0 est testé ? Oui.
- Est-ce que missing image ne crashe pas ? Oui.
- Est-ce que catalogue incomplet ne crashe pas ? Oui.
- Est-ce qu'aucun fallback debug jaune runtime n'est dessiné ? Oui.
- Est-ce que le golden slice Lot 91 reste vert ? Oui.
- Est-ce que MapLayersComponent reste vert ? Oui.
- Est-ce que map_core est inchangé ? Oui.
- Est-ce que map_editor est inchangé ? Oui.
- Est-ce qu'un Lot 92-bis est nécessaire ? Non pour ce durcissement; un futur lot peut viser un smoke `PlayableMapGame` si besoin.
