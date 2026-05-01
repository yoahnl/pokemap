# Lot PathPattern-35 — Animated Water Golden Slice V0

## 1. Résumé exécutif

Lot 35 réalisé comme golden slice end-to-end sur le cas canonique eau 2x2 animée.

Résultat:

- manifest rechargé depuis JSON utilisé dans les tests;
- rendu éditeur validé sur répétition spatiale A/B/C/D et changement temporel;
- rendu runtime validé sur répétition spatiale A/B/C/D et changement temporel;
- `durationMs`, `tilesetId` override, `cross`, variants partiels conservés;
- aucun code de production modifié.

## 2. Audit initial

### Commandes audit initial exécutées

```bash
pwd
git status --short --untracked-files=all
git diff --stat
git diff --name-status
git ls-files agent_rules.md
git ls-files reports/pathPattern/pathpattern_34_save_reload_json_regression_v0.md
git ls-files packages/map_core/test/fixtures/path_pattern/project_manifest_pathpattern_animated_2x2.json
```

Sortie:

```text
/Users/karim/Project/pokemonProject
agent_rules.md
reports/pathPattern/pathpattern_34_save_reload_json_regression_v0.md
packages/map_core/test/fixtures/path_pattern/project_manifest_pathpattern_animated_2x2.json
```

### Fichiers inspectés

- `packages/map_core/test/fixtures/path_pattern/project_manifest_pathpattern_animated_2x2.json`
- `packages/map_core/test/project_manifest_path_pattern_save_reload_test.dart`
- `packages/map_editor/test/path_pattern/path_pattern_editor_reload_regression_test.dart`
- `packages/map_editor/test/map_grid_painter_test.dart`
- `packages/map_runtime/test/path_pattern_runtime_reload_regression_test.dart`
- `packages/map_runtime/test/map_layers_component_path_pattern_render_test.dart`
- `packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart`
- `packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart`
- `packages/map_editor/lib/src/features/path_pattern/path_pattern_editor_render_resolution.dart`
- `packages/map_runtime/lib/src/presentation/flame/path_pattern_runtime_render_resolution.dart`
- `AGENTS.md`
- `agent_rules.md`

### Établissements audit (obligatoires)

- La fixture Lot 34 existe déjà et couvre exactement le cas data requis.
- Aucun besoin de créer une deuxième fixture quasi identique.
- `MapGridPainter` consomme `editorEntityAnimationMs` et passe par `resolvePathPatternEditorRenderResolution`.
- `MapLayersComponent` consomme `_animElapsed` via `update(...)` et passe par `resolvePathPatternRuntimeRenderResolution`.
- Les tests existants couvraient déjà:
  - spatial 2x2 statique;
  - animation mono-cellule;
  - fallback/résolveur;
  mais pas un golden slice unique "fixture JSON + spatial + temporel + override" sur éditeur et runtime.

## 3. Fixture golden utilisée ou créée

Fixture réutilisée:

- `packages/map_core/test/fixtures/path_pattern/project_manifest_pathpattern_animated_2x2.json`

Décision:

- réutilisation sans duplication;
- aucune nouvelle fixture créée.

## 4. Données eau animée 2x2

Manifest (depuis fixture):

- `ProjectPathPreset` `water-base`
  - variants partiels (`endNorth`, `cross`)
  - `cross` présent
- `ProjectPathPatternPreset` `water-pattern`
  - centerPattern 2x2
  - 2 frames par cellule
  - durées:
    - A: 100 / 150
    - B: 100 / 150
    - C: 200 / 250
    - D: 200 / 250
  - override `tilesetId` sur D frame 2: `tileset-water-fx`

Couleurs synthétiques utilisées en rendu:

- frame 0: A rouge, B vert, C bleu, D jaune
- frame suivante: A magenta, B cyan, C orange, D blanc (via override `tileset-water-fx`)

## 5. Test map_core golden slice

Fichier créé:

- `packages/map_core/test/path_pattern_water_animated_golden_slice_test.dart`

Ce test prouve:

1. la fixture se décode;
2. la fixture est en format canonique 2 espaces + newline;
3. le roundtrip conserve `water-base` et `water-pattern`;
4. centerPattern 2x2 conservé;
5. cellules multi-frames conservées;
6. `durationMs` conservés;
7. `cross` conservé;
8. variants partiels conservés;
9. variant absent non généré;
10. `tilesetId` override conservé.

## 6. Test éditeur golden slice

Fichier créé:

- `packages/map_editor/test/path_pattern/path_pattern_water_animated_editor_golden_slice_test.dart`

Chemin testé:

- fixture JSON -> `ProjectManifest.fromJson`
- `MapData` PathLayer 4x2 (`water-base`)
- `MapGridPainter.paint(...)` (chemin production)
- images tileset synthétiques (`tileset-main`, `tileset-water-fx`)
- rendu à `elapsedMs = 0`
- rendu à `elapsedMs = 220`
- vérification pixels:
  - A/B/C/D
  - répétition spatiale 2x2
  - changement temporel
  - D frame suivante via override (blanc)

## 7. Test runtime golden slice

Fichier créé:

- `packages/map_runtime/test/path_pattern_water_animated_runtime_golden_slice_test.dart`

Chemin testé:

- fixture JSON -> `ProjectManifest.fromJson`
- `RuntimeMapBundle` + `MapData` PathLayer 4x2 (`water-base`)
- `MapLayersComponent.render(...)` (chemin production)
- `MapLayersComponent.update(0.22)` pour progression temporelle
- `RuntimeTilesetImage` synthétiques (`tileset-main`, `tileset-water-fx`)
- vérification pixels:
  - A/B/C/D
  - répétition spatiale 2x2
  - changement temporel
  - D frame suivante via override (blanc)

## 8. Gestion elapsedMs

Éditeur:

- `MapGridPainter` alimenté via `editorEntityAnimationMs`.
- frame 0: `elapsedMs = 0`.
- frame suivante: `elapsedMs = 220`.

Runtime:

- `MapLayersComponent` alimenté via `_animElapsed`.
- frame 0: rendu direct sans update.
- frame suivante: `component.update(0.22)` puis rendu.

Pourquoi 220 ms:

- A/B passent en frame 2 après 100 ms.
- C/D passent en frame 2 après 200 ms.
- 220 ms garantit frame 2 sur les 4 cellules.

## 9. Gestion tilesetId override

Couverture:

- map_core: conservation roundtrip JSON (`tileset-water-fx` sur D frame 2).
- éditeur golden: D frame suivante lue depuis `tileset-water-fx` (pixel blanc).
- runtime golden: D frame suivante lue depuis `tileset-water-fx` (pixel blanc).

## 10. Code de production modifié ou non

Aucun fichier de production modifié.

## 11. Fichiers créés

- `packages/map_core/test/path_pattern_water_animated_golden_slice_test.dart`
- `packages/map_editor/test/path_pattern/path_pattern_water_animated_editor_golden_slice_test.dart`
- `packages/map_runtime/test/path_pattern_water_animated_runtime_golden_slice_test.dart`
- `reports/pathPattern/pathpattern_35_animated_water_golden_slice_v0.md`

## 12. Fichiers modifiés

Aucun fichier existant modifié hors créations du lot.

## 13. Fichiers supprimés

Aucun.

## 14. Tests exécutés

### map_core

```bash
dart test test/path_pattern_water_animated_golden_slice_test.dart --reporter expanded --no-color
dart test test/project_manifest_path_pattern_save_reload_test.dart --reporter expanded --no-color
dart test test/path_pattern_visual_resolution_test.dart --reporter expanded --no-color
dart analyze lib/src/models lib/src/operations test/path_pattern_water_animated_golden_slice_test.dart
dart test --reporter expanded --no-color
```

### map_editor

```bash
flutter test test/path_pattern/path_pattern_water_animated_editor_golden_slice_test.dart --reporter expanded
flutter test test/path_pattern/path_pattern_editor_reload_regression_test.dart --reporter expanded
flutter test test/path_pattern/path_pattern_editor_render_resolution_test.dart --reporter expanded
flutter test test/map_grid_painter_test.dart --reporter expanded
flutter analyze lib/src/features/path_pattern lib/src/features/path_studio test/path_pattern
```

### map_runtime

```bash
flutter test test/path_pattern_water_animated_runtime_golden_slice_test.dart --reporter expanded
flutter test test/path_pattern_runtime_reload_regression_test.dart --reporter expanded
flutter test test/path_pattern_runtime_render_resolution_test.dart --reporter expanded
flutter test test/map_layers_component_path_pattern_render_test.dart --reporter expanded
```

## 15. Résultats des validations

- Tous les tests ciblés Lot 35: PASS.
- `dart analyze` ciblé: PASS.
- `flutter analyze` ciblé: PASS.
- Régression large `map_core`: PASS.
  - Ligne finale exacte: `00:02 +1127: All tests passed!`

## 16. git status final

```text
?? packages/map_core/test/path_pattern_water_animated_golden_slice_test.dart
?? packages/map_editor/test/path_pattern/path_pattern_water_animated_editor_golden_slice_test.dart
?? packages/map_runtime/test/path_pattern_water_animated_runtime_golden_slice_test.dart
?? reports/pathPattern/pathpattern_35_animated_water_golden_slice_v0.md
```

## 17. git diff --stat

```text
(aucune sortie: uniquement fichiers non suivis)
```

## 18. git diff --name-status

```text
(aucune sortie: uniquement fichiers non suivis)
```

## 19. Evidence Pack

### 19.1 git status initial

```text
(aucune entrée détectée lors de l’audit initial)
```

### 19.2 git status final

```text
?? packages/map_core/test/path_pattern_water_animated_golden_slice_test.dart
?? packages/map_editor/test/path_pattern/path_pattern_water_animated_editor_golden_slice_test.dart
?? packages/map_runtime/test/path_pattern_water_animated_runtime_golden_slice_test.dart
?? reports/pathPattern/pathpattern_35_animated_water_golden_slice_v0.md
```

### 19.3 git diff --stat final

```text
(aucune sortie: uniquement fichiers non suivis)
```

### 19.4 git diff --name-status final

```text
(aucune sortie: uniquement fichiers non suivis)
```

### 19.5 Contenu complet des fichiers créés

#### `packages/map_core/test/path_pattern_water_animated_golden_slice_test.dart`

```dart
import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('PathPattern water animated golden slice', () {
    test('fixture JSON se décode et reste canonique', () {
      final raw = _fixtureRaw();
      final manifest = ProjectManifest.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
      const encoder = JsonEncoder.withIndent('  ');
      final pretty = '${encoder.convert(jsonDecode(raw) as Object?)}\n';

      expect(raw, pretty);
      expect(manifest.pathPresets, hasLength(1));
      expect(manifest.pathPatternPresets, hasLength(1));
    });

    test('roundtrip conserve eau 2x2 animée, variants partiels, cross et override',
        () {
      final manifest = ProjectManifest.fromJson(
        jsonDecode(_fixtureRaw()) as Map<String, dynamic>,
      );
      final roundtripped = ProjectManifest.fromJson(
        jsonDecode(jsonEncode(manifest.toJson())) as Map<String, dynamic>,
      );

      final base = roundtripped.pathPresets.singleWhere(
        (preset) => preset.id == 'water-base',
      );
      expect(base.surfaceKind, PathSurfaceKind.water);
      expect(base.variants, hasLength(2));
      expect(
        base.variants.any((variant) => variant.variant == TerrainPathVariant.endNorth),
        isTrue,
      );
      expect(
        base.variants.any((variant) => variant.variant == TerrainPathVariant.cross),
        isTrue,
      );
      expect(
        base.variants.any((variant) => variant.variant == TerrainPathVariant.cornerNE),
        isFalse,
      );

      final cross = base.variants.singleWhere(
        (variant) => variant.variant == TerrainPathVariant.cross,
      );
      expect(cross.frames.single.source, const TilesetSourceRect(x: 7, y: 7));
      expect(cross.frames.single.durationMs, isNull);

      final pattern = roundtripped.pathPatternPresets.singleWhere(
        (preset) => preset.id == 'water-pattern',
      );
      expect(pattern.basePathPresetId, 'water-base');
      expect(pattern.centerPattern.size, PathCenterPatternSize(width: 2, height: 2));

      final cells = pattern.centerPattern.cells;
      expect(cells.map((cell) => [cell.localX, cell.localY]).toList(), [
        [0, 0],
        [1, 0],
        [0, 1],
        [1, 1],
      ]);
      expect(cells.every((cell) => cell.frames.length >= 2), isTrue);

      expect(cells[0].frames[0].durationMs, 100);
      expect(cells[0].frames[1].durationMs, 150);
      expect(cells[1].frames[0].durationMs, 100);
      expect(cells[1].frames[1].durationMs, 150);
      expect(cells[2].frames[0].durationMs, 200);
      expect(cells[2].frames[1].durationMs, 250);
      expect(cells[3].frames[0].durationMs, 200);
      expect(cells[3].frames[1].durationMs, 250);
      expect(cells[3].frames[1].tilesetId, 'tileset-water-fx');
    });
  });
}

String _fixtureRaw() {
  return File(
    'test/fixtures/path_pattern/project_manifest_pathpattern_animated_2x2.json',
  ).readAsStringSync();
}
```

#### `packages/map_editor/test/path_pattern/path_pattern_water_animated_editor_golden_slice_test.dart`

```dart
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/models/path_autotile_set.dart';
import 'package:map_editor/src/ui/canvas/map_canvas.dart';

void main() {
  test('golden slice eau 2x2 animée depuis JSON dans MapGridPainter', () async {
    final manifest = ProjectManifest.fromJson(
      jsonDecode(_fixtureRaw()) as Map<String, dynamic>,
    );
    const map = MapData(
      id: 'water_golden',
      name: 'Water Golden',
      size: GridSize(width: 4, height: 2),
      layers: <MapLayer>[
        PathLayer(
          id: 'path_main',
          name: 'Path',
          presetId: 'water-base',
          cells: <bool>[
            true,
            true,
            true,
            true,
            true,
            true,
            true,
            true,
          ],
        ),
      ],
    );

    final mainImage = await _createTilesetImage(
      row0: const [
        ui.Color(0xFFFF0000),
        ui.Color(0xFF00FF00),
        ui.Color(0xFF0000FF),
        ui.Color(0xFFFFFF00),
      ],
      row1: const [
        ui.Color(0xFFFF00FF),
        ui.Color(0xFF00FFFF),
        ui.Color(0xFFFFA500),
        ui.Color(0xFF444444),
      ],
    );
    final fxImage = await _createTilesetImage(
      row0: const [
        ui.Color(0xFF111111),
        ui.Color(0xFF111111),
        ui.Color(0xFF111111),
        ui.Color(0xFF111111),
      ],
      row1: const [
        ui.Color(0xFF111111),
        ui.Color(0xFF111111),
        ui.Color(0xFF111111),
        ui.Color(0xFFFFFFFF),
      ],
    );

    final frame0 = await _render(
      map: map,
      manifest: manifest,
      imagesById: {
        'tileset-main': mainImage,
        'tileset-water-fx': fxImage,
      },
      elapsedMs: 0,
    );
    final frame1 = await _render(
      map: map,
      manifest: manifest,
      imagesById: {
        'tileset-main': mainImage,
        'tileset-water-fx': fxImage,
      },
      elapsedMs: 220,
    );

    await _expectRgb(frame0, 8, 8,
        redExpected: 255, greenExpected: 0, blueExpected: 0, label: 'frame0 A');
    await _expectRgb(frame0, 24, 8,
        redExpected: 0, greenExpected: 255, blueExpected: 0, label: 'frame0 B');
    await _expectRgb(frame0, 8, 24,
        redExpected: 0, greenExpected: 0, blueExpected: 255, label: 'frame0 C');
    await _expectRgb(frame0, 24, 24,
        redExpected: 255, greenExpected: 255, blueExpected: 0, label: 'frame0 D');
    await _expectRgb(frame0, 40, 8,
        redExpected: 255,
        greenExpected: 0,
        blueExpected: 0,
        label: 'frame0 A repeat');
    await _expectRgb(frame0, 56, 24,
        redExpected: 255,
        greenExpected: 255,
        blueExpected: 0,
        label: 'frame0 D repeat');

    await _expectRgb(frame1, 8, 8,
        redExpected: 255, greenExpected: 0, blueExpected: 255, label: 'frame1 A');
    await _expectRgb(frame1, 24, 8,
        redExpected: 0, greenExpected: 255, blueExpected: 255, label: 'frame1 B');
    await _expectRgb(frame1, 8, 24,
        redExpected: 255, greenExpected: 165, blueExpected: 0, label: 'frame1 C');
    await _expectRgb(frame1, 24, 24,
        redExpected: 255,
        greenExpected: 255,
        blueExpected: 255,
        label: 'frame1 D override');
    await _expectRgb(frame1, 40, 8,
        redExpected: 255,
        greenExpected: 0,
        blueExpected: 255,
        label: 'frame1 A repeat');
    await _expectRgb(frame1, 56, 24,
        redExpected: 255,
        greenExpected: 255,
        blueExpected: 255,
        label: 'frame1 D repeat');

    frame0.dispose();
    frame1.dispose();
    mainImage.dispose();
    fxImage.dispose();
  });
}

Future<ui.Image> _render({
  required MapData map,
  required ProjectManifest manifest,
  required Map<String, ui.Image> imagesById,
  required int elapsedMs,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  MapGridPainter(
    map: map,
    zoom: 1,
    offset: ui.Offset.zero,
    tileWidth: 16,
    tileHeight: 16,
    tilesetImagesById: imagesById,
    sourceTileWidth: 16,
    sourceTileHeight: 16,
    tilesPerRowById: const <String, int>{
      'tileset-main': 4,
      'tileset-water-fx': 4,
    },
    warps: const <MapWarp>[],
    gameplayZones: const <MapGameplayZone>[],
    connectionLabelsByDirection: const <MapConnectionDirection, String>{},
    pathAutotileSetsByPresetId: const <String, PathAutotileSet>{},
    terrainPresetsByType: const <TerrainType, ProjectTerrainPreset>{},
    project: manifest,
    editorEntityAnimationMs: elapsedMs,
  ).paint(canvas, const ui.Size(64, 32));

  final picture = recorder.endRecording();
  final image = await picture.toImage(64, 32);
  picture.dispose();
  return image;
}

Future<void> _expectRgb(
  ui.Image image,
  int x,
  int y, {
  required int redExpected,
  required int greenExpected,
  required int blueExpected,
  required String label,
}) async {
  final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  final offset = ((y * image.width) + x) * 4;
  final red = bytes!.getUint8(offset);
  final green = bytes.getUint8(offset + 1);
  final blue = bytes.getUint8(offset + 2);

  final color = '($red,$green,$blue)';
  expect(red, redExpected, reason: '$label red $color');
  expect(green, greenExpected, reason: '$label green $color');
  expect(blue, blueExpected, reason: '$label blue $color');
}

Future<ui.Image> _createTilesetImage({
  required List<ui.Color> row0,
  required List<ui.Color> row1,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.drawRect(
    const ui.Rect.fromLTWH(0, 0, 64, 32),
    ui.Paint()..color = const ui.Color(0xFF000000),
  );

  for (var x = 0; x < row0.length; x += 1) {
    canvas.drawRect(
      ui.Rect.fromLTWH((x * 16).toDouble(), 0, 16, 16),
      ui.Paint()..color = row0[x],
    );
    canvas.drawRect(
      ui.Rect.fromLTWH((x * 16).toDouble(), 16, 16, 16),
      ui.Paint()..color = row1[x],
    );
  }
  final picture = recorder.endRecording();
  final image = await picture.toImage(64, 32);
  picture.dispose();
  return image;
}

String _fixtureRaw() {
  return File(
    '../map_core/test/fixtures/path_pattern/project_manifest_pathpattern_animated_2x2.json',
  ).readAsStringSync();
}
```

#### `packages/map_runtime/test/path_pattern_water_animated_runtime_golden_slice_test.dart`

```dart
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/application/runtime_map_bundle.dart';
import 'package:map_runtime/src/infrastructure/runtime_tileset_image.dart';
import 'package:map_runtime/src/presentation/flame/map_layers_component.dart';

import 'surface/surface_runtime_test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('golden slice eau 2x2 animée depuis JSON dans MapLayersComponent',
      () async {
    final manifest = ProjectManifest.fromJson(
      jsonDecode(_fixtureRaw()) as Map<String, dynamic>,
    );
    const map = MapData(
      id: 'runtime_water_golden',
      name: 'Runtime Water Golden',
      size: GridSize(width: 4, height: 2),
      layers: <MapLayer>[
        PathLayer(
          id: 'path_main',
          name: 'Path',
          presetId: 'water-base',
          cells: <bool>[
            true,
            true,
            true,
            true,
            true,
            true,
            true,
            true,
          ],
        ),
      ],
    );

    final bundle = RuntimeMapBundle(
      manifest: manifest,
      map: map,
      projectRootDirectory: '/tmp/runtime-water-golden',
      tilesetAbsolutePathsById: const <String, String>{},
    );

    final component = MapLayersComponent(
      bundle: bundle,
      tileImagesByTilesetId: {
        'tileset-main': await _runtimeTilesetImage(
          row0: const [
            Color(0xFFFF0000),
            Color(0xFF00FF00),
            Color(0xFF0000FF),
            Color(0xFFFFFF00),
          ],
          row1: const [
            Color(0xFFFF00FF),
            Color(0xFF00FFFF),
            Color(0xFFFFA500),
            Color(0xFF444444),
          ],
        ),
        'tileset-water-fx': await _runtimeTilesetImage(
          row0: const [
            Color(0xFF111111),
            Color(0xFF111111),
            Color(0xFF111111),
            Color(0xFF111111),
          ],
          row1: const [
            Color(0xFF111111),
            Color(0xFF111111),
            Color(0xFF111111),
            Color(0xFFFFFFFF),
          ],
        ),
      },
    );

    final frame0 = await _renderComponent(component, 128, 64);
    await _expectPixel(frame0, 16, 16, rgba(255, 0, 0, 255));
    await _expectPixel(frame0, 48, 16, rgba(0, 255, 0, 255));
    await _expectPixel(frame0, 16, 48, rgba(0, 0, 255, 255));
    await _expectPixel(frame0, 48, 48, rgba(255, 255, 0, 255));
    await _expectPixel(frame0, 80, 16, rgba(255, 0, 0, 255));
    await _expectPixel(frame0, 112, 48, rgba(255, 255, 0, 255));

    component.update(0.22);
    final frame1 = await _renderComponent(component, 128, 64);
    await _expectPixel(frame1, 16, 16, rgba(255, 0, 255, 255));
    await _expectPixel(frame1, 48, 16, rgba(0, 255, 255, 255));
    await _expectPixel(frame1, 16, 48, rgba(255, 165, 0, 255));
    await _expectPixel(frame1, 48, 48, rgba(255, 255, 255, 255));
    await _expectPixel(frame1, 80, 16, rgba(255, 0, 255, 255));
    await _expectPixel(frame1, 112, 48, rgba(255, 255, 255, 255));

    frame0.dispose();
    frame1.dispose();
  });
}

Future<void> _expectPixel(ui.Image image, int x, int y, List<int> expected) async {
  expect(await pixelAt(image, x, y), expected);
}

Future<ui.Image> _renderComponent(
  MapLayersComponent component,
  int width,
  int height,
) {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  component.render(canvas);
  return recorder.endRecording().toImage(width, height);
}

Future<RuntimeTilesetImage> _runtimeTilesetImage({
  required List<Color> row0,
  required List<Color> row1,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);

  for (var x = 0; x < row0.length; x += 1) {
    canvas.drawRect(
      Rect.fromLTWH((x * 16).toDouble(), 0, 16, 16),
      Paint()..color = row0[x],
    );
    canvas.drawRect(
      Rect.fromLTWH((x * 16).toDouble(), 16, 16, 16),
      Paint()..color = row1[x],
    );
  }

  final image = await recorder.endRecording().toImage(64, 32);
  return RuntimeTilesetImage(
    images: [image],
    chunks: const [
      RuntimeTilesetChunk(
        top: 0,
        height: 32,
        width: 64,
      ),
    ],
    width: 64,
    height: 32,
  );
}

String _fixtureRaw() {
  return File(
    '../map_core/test/fixtures/path_pattern/project_manifest_pathpattern_animated_2x2.json',
  ).readAsStringSync();
}
```

### 19.6 Contenu complet des fixtures JSON créées ou modifiées

```text
Aucune fixture créée ou modifiée dans ce lot.
Fixture réutilisée: packages/map_core/test/fixtures/path_pattern/project_manifest_pathpattern_animated_2x2.json
```

### 19.7 Diff complet réel des fichiers modifiés

```text
A packages/map_core/test/path_pattern_water_animated_golden_slice_test.dart
A packages/map_editor/test/path_pattern/path_pattern_water_animated_editor_golden_slice_test.dart
A packages/map_runtime/test/path_pattern_water_animated_runtime_golden_slice_test.dart
A reports/pathPattern/pathpattern_35_animated_water_golden_slice_v0.md
```

### 19.8 Sorties complètes des tests ciblés principaux

#### map_core — golden slice

```text
00:00 +0: loading test/path_pattern_water_animated_golden_slice_test.dart
00:00 +0: PathPattern water animated golden slice fixture JSON se décode et reste canonique
00:00 +1: PathPattern water animated golden slice roundtrip conserve eau 2x2 animée, variants partiels, cross et override
00:00 +2: All tests passed!
```

#### map_editor — golden slice

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_pattern_water_animated_editor_golden_slice_test.dart
00:00 +0: golden slice eau 2x2 animée depuis JSON dans MapGridPainter
00:00 +1: All tests passed!
```

#### map_runtime — golden slice

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_runtime/test/path_pattern_water_animated_runtime_golden_slice_test.dart
00:00 +0: golden slice eau 2x2 animée depuis JSON dans MapLayersComponent
00:00 +1: All tests passed!
```

#### Régressions complémentaires (commandes demandées)

```text
00:00 +0: loading test/project_manifest_path_pattern_save_reload_test.dart
00:00 +3: All tests passed!

00:00 +0: loading test/path_pattern_visual_resolution_test.dart
00:00 +9: All tests passed!

00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_pattern_editor_reload_regression_test.dart
00:00 +1: All tests passed!

00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_pattern_editor_render_resolution_test.dart
00:00 +8: All tests passed!

00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/map_grid_painter_test.dart
00:00 +7: All tests passed!

00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_runtime/test/path_pattern_runtime_reload_regression_test.dart
00:00 +1: All tests passed!

00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_runtime/test/path_pattern_runtime_render_resolution_test.dart
00:00 +9: All tests passed!

00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_runtime/test/map_layers_component_path_pattern_render_test.dart
00:00 +3: All tests passed!
```

### 19.9 Ligne finale exacte grosse régression

```text
00:02 +1127: All tests passed!
```

### 19.10 Sorties analyze ciblées

```text
Analyzing models, operations, path_pattern_water_animated_golden_slice_test.dart...
No issues found!
```

```text
Analyzing 3 items...
No issues found! (ran in 2.3s)
```

## 20. Auto-review

### Prouvé

- Golden slice eau 2x2 animé depuis fixture JSON dans renderer éditeur réel (`MapGridPainter`).
- Golden slice eau 2x2 animé depuis fixture JSON dans renderer runtime réel (`MapLayersComponent`).
- Répétition spatiale A/B/C/D et changement temporel validés dans les deux environnements.
- `tilesetId` override réellement rendu (pixel blanc sur D frame suivante).
- Régressions existantes PathPattern conservées.

### Limites

- Vérification pixel synthétique (assets générés en test), pas asset production.
- Pas de nouvelles fonctionnalités; uniquement caractérisation/régression.

## 21. Critique du prompt

- Prompt précis, scope strict et cohérent avec un lot de stabilisation.
- Le niveau de preuve demandé (JSON -> renderer réel) est pertinent pour verrouiller les refactors futurs.
- Point sensible bien géré: éviter duplication de fixture (réutilisation de la fixture Lot 34).

## 22. Conclusion

Le lot 35 est validé sur le périmètre demandé: une eau PathPattern center-only 2x2 animée est figée en golden slice depuis manifest JSON rechargé, avec preuves renderer éditeur/runtime, conservation data (durées, override, `cross`, variants partiels), sans modification de production.

## Checklist finale

- [x] Audit initial réalisé.
- [x] AGENTS.md et agent_rules.md lus.
- [x] Ancienne roadmap Tall Grass ignorée.
- [x] Aucun faux test.
- [x] Aucun provider inventé.
- [x] Aucun repository/service ajouté.
- [x] Aucun save disque applicatif.
- [x] Aucun FileProjectRepository utilisé.
- [x] Aucun ProjectManifest modifié sauf bug réel documenté.
- [x] Aucun map_core production modifié sauf bug réel documenté.
- [x] Aucun runtime production modifié sauf bug réel documenté.
- [x] Aucun editor production modifié sauf bug réel documenté.
- [x] Aucun generated file.
- [x] Aucun build_runner.
- [x] Fixture eau animée 2×2 utilisée ou créée.
- [x] Manifest rechargé depuis JSON utilisé dans les tests.
- [x] CenterPattern 2×2 testé.
- [x] Animation frame 0 testée.
- [x] Animation frame suivante testée.
- [x] Répétition spatiale A/B/C/D testée.
- [x] Rendu éditeur golden slice testé.
- [x] Rendu runtime golden slice testé.
- [x] durationMs conservé.
- [x] tilesetId override couvert.
- [x] cross préservé.
- [x] variants partiels conservés.
- [x] Aucun variant manquant généré.
- [x] Tests ciblés passent.
- [x] Régression large map_core passe ou échec documenté.
- [x] Analyze ciblé passe.
- [x] Rapport final complet créé.
- [x] Auto-review faite.
- [x] Critique du prompt faite.
