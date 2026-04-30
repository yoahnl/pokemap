# PathPattern-4-bis — PNG Alpha Processor côté editor V0

## 1. Verdict

Lot accepté côté implémentation.

Le lot ajoute un processeur PNG pur côté `map_editor` :

```text
Uint8List imageBytes + TilesetTransparentColor? transparentColor
-> Uint8List PNG transformé en mémoire
```

La fonction ne lit aucun fichier, n’écrit aucun fichier, ne modifie aucune image source et ne définit aucune couleur par défaut. `transparentColor == null` retourne la même instance de bytes.

## 2. Audit initial

### Commandes initiales

```bash
pwd
git status --short --untracked-files=all
git diff --stat
rg -n "image:|package:image|decodePng|encodePng|instantiateImageCodec|decodeImageFromList|Uint8List|transparentColor|TilesetTransparentColor|Image.memory|MemoryImage|png|PNG" packages/map_editor/pubspec.yaml packages/map_editor/lib packages/map_editor/test packages/map_core/lib packages/map_core/test
```

### Sorties initiales

```text
/Users/karim/Project/pokemonProject
```

`git status --short --untracked-files=all` initial :

```text
```

`git diff --stat` initial :

```text
```

### Réponses d’audit

1. Le package `image` est-il déjà disponible dans `map_editor` ?

Oui. `packages/map_editor/pubspec.yaml` contient :

```text
19:  image: ^4.2.0
```

`packages/map_editor/pubspec.lock` résout actuellement :

```text
  image:
    dependency: "direct main"
    description:
      name: image
      sha256: f9881ff4998044947ec38d098bc7c8316ae1186fa786eddffdb867b9bc94dfce
      url: "https://pub.dev"
    source: hosted
    version: "4.8.0"
```

2. Existe-t-il déjà un helper image / PNG ?

Il existe déjà des usages de `package:image` côté `map_editor`, notamment :

```text
packages/map_editor/lib/src/application/use_cases/project_tileset_use_cases.dart:3:import 'package:image/image.dart' as img;
packages/map_editor/test/project_tileset_use_cases_test.dart:4:import 'package:image/image.dart' as img;
```

`project_tileset_use_cases.dart` utilise `img.decodeImage(bytes)` pour valider une image importée. Le test `project_tileset_use_cases_test.dart` utilise `img.encodePng(image)` pour construire des fixtures temporaires.

3. Existe-t-il déjà une logique de transparence d’image ?

Non. Les occurrences `transparentColor` actives côté chantier PathPattern existaient dans `map_core` via `TilesetTransparentColor`, mais aucun processeur PNG ne transformait encore des bytes d’image.

4. Où placer proprement le processeur PNG ?

Dans :

```text
packages/map_editor/lib/src/application/services/tileset_transparent_color_processor.dart
```

Le service est applicatif côté editor : il manipule des bytes PNG et dépend de `package:image`.

5. Faut-il ajouter une dépendance ?

Non. `image` est déjà une dépendance directe de `map_editor`; aucun `pubspec.yaml` ou `pubspec.lock` n’a été modifié.

6. Si oui, pourquoi cette dépendance est-elle nécessaire et limitée à `map_editor` ?

Non applicable : aucune dépendance ajoutée. La dépendance existante reste limitée à `map_editor`.

7. Pourquoi ne pas mettre ce processeur dans `map_core` ?

`map_core` doit rester un package Dart pur de modèles et opérations de domaine. Le value object `TilesetTransparentColor` y vit déjà sans Flutter, sans bytes PNG et sans décodage image. Le décodage/encodage PNG est un détail applicatif/editor et dépend de `package:image`, donc il reste côté `map_editor`.

8. Quels tests PathPattern doivent être relancés ?

Les régressions relancées :

```text
packages/map_core/test/tileset_transparent_color_test.dart
packages/map_core/test/project_path_preset_center_pattern_adapter_test.dart
packages/map_core/test/path_center_pattern_resolver_test.dart
packages/map_core/test/path_center_pattern_test.dart
packages/map_core/test/map_terrain_autotile_characterization_test.dart
```

## 3. Fichiers créés / modifiés / supprimés

### Créés

```text
packages/map_editor/lib/src/application/services/tileset_transparent_color_processor.dart
packages/map_editor/test/path_pattern/tileset_transparent_color_processor_test.dart
reports/pathPattern/path_pattern_lot_04_bis_png_alpha_processor.md
```

### Modifiés

```text
```

### Supprimés

```text
```

## 4. Dépendances utilisées ou ajoutées

Dépendance utilisée :

```text
package:image/image.dart
```

Aucune dépendance ajoutée. `packages/map_editor/pubspec.yaml` contenait déjà :

```text
image: ^4.2.0
```

Résolution actuelle dans `packages/map_editor/pubspec.lock` :

```text
version: "4.8.0"
```

`flutter pub get` n’a pas été lancé, car aucun fichier de dépendance n’a changé.

## 5. API ajoutée

Fichier :

```text
packages/map_editor/lib/src/application/services/tileset_transparent_color_processor.dart
```

API :

```dart
Uint8List applyTilesetTransparentColorToPngBytes({
  required Uint8List imageBytes,
  required TilesetTransparentColor? transparentColor,
})
```

## 6. Comportement transparentColor null

Si `transparentColor == null`, la fonction retourne directement `imageBytes`.

Le test vérifie explicitement :

```dart
expect(identical(result, imageBytes), isTrue);
expect(result, imageBytes);
```

Il n’y a donc pas de couleur par défaut et aucun traitement PNG inutile.

## 7. Comportement pixel matching

Pour chaque pixel du PNG décodé :

```text
si pixel RGB == transparentColor RGB
-> alpha = 0
```

Le RGB est conservé. Exemple testé :

```text
#F05BA1 alpha 255 -> #F05BA1 alpha 0
#0000FF alpha 255 -> #0000FF alpha 255
```

## 8. Comportement alpha existant

Le matching ignore l’alpha existant parce qu’il utilise `TilesetTransparentColor.matchesRgb(...)`.

Exemple testé :

```text
#F05BA1 alpha 128 -> #F05BA1 alpha 0
#0000FF alpha 128 -> #0000FF alpha 128
```

Les pixels non matching conservent leur alpha.

## 9. Comportement PNG invalide

Si `img.decodePng(imageBytes)` retourne `null`, la fonction lance :

```dart
ArgumentError.value(
  imageBytes,
  'imageBytes',
  'Tileset transparent color processor expected valid PNG bytes.',
)
```

Le test utilise :

```dart
Uint8List.fromList([1, 2, 3])
```

et vérifie `ArgumentError`.

## 10. Pourquoi map_editor et pas map_core

`map_core` garde uniquement le value object pur `TilesetTransparentColor`.

Le processeur PNG :

```text
- dépend de package:image ;
- manipule Uint8List de PNG ;
- décode et réencode une image ;
- sert les futures previews / workflows editor.
```

Ce n’est pas un contrat de domaine core. Il reste donc dans `map_editor`.

## 11. Tests lancés

### TDD rouge initial

Commande :

```bash
cd packages/map_editor && flutter test test/path_pattern/tileset_transparent_color_processor_test.dart --no-pub --reporter expanded
```

Sortie :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/tileset_transparent_color_processor_test.dart
00:00 +0 -1: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/tileset_transparent_color_processor_test.dart [E]
  Failed to load "/Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/tileset_transparent_color_processor_test.dart":
  Compilation failed for testPath=/Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/tileset_transparent_color_processor_test.dart: test/path_pattern/tileset_transparent_color_processor_test.dart:6:8: Error: Error when reading 'lib/src/application/services/tileset_transparent_color_processor.dart': No such file or directory
  import 'package:map_editor/src/application/services/tileset_transparent_color_processor.dart';
         ^
  test/path_pattern/tileset_transparent_color_processor_test.dart:16:22: Error: Method not found: 'applyTilesetTransparentColorToPngBytes'.
        final result = applyTilesetTransparentColorToPngBytes(
                       ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  test/path_pattern/tileset_transparent_color_processor_test.dart:31:22: Error: Method not found: 'applyTilesetTransparentColorToPngBytes'.
        final result = applyTilesetTransparentColorToPngBytes(
                       ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  test/path_pattern/tileset_transparent_color_processor_test.dart:47:22: Error: Method not found: 'applyTilesetTransparentColorToPngBytes'.
        final result = applyTilesetTransparentColorToPngBytes(
                       ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  test/path_pattern/tileset_transparent_color_processor_test.dart:63:22: Error: Method not found: 'applyTilesetTransparentColorToPngBytes'.
        final result = applyTilesetTransparentColorToPngBytes(
                       ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  test/path_pattern/tileset_transparent_color_processor_test.dart:79:22: Error: Method not found: 'applyTilesetTransparentColorToPngBytes'.
        final result = applyTilesetTransparentColorToPngBytes(
                       ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  test/path_pattern/tileset_transparent_color_processor_test.dart:91:15: Error: Method not found: 'applyTilesetTransparentColorToPngBytes'.
          () => applyTilesetTransparentColorToPngBytes(
                ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  .
00:00 +0 -1: Some tests failed.
```

### Test ciblé Lot 4-bis

Commande :

```bash
cd packages/map_editor && flutter test test/path_pattern/tileset_transparent_color_processor_test.dart --no-pub --reporter expanded
```

Sortie complète :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/tileset_transparent_color_processor_test.dart
00:00 +0: applyTilesetTransparentColorToPngBytes returns the same bytes instance when transparentColor is null
00:00 +1: applyTilesetTransparentColorToPngBytes turns matching RGB pixels transparent and preserves others
00:00 +2: applyTilesetTransparentColorToPngBytes matches RGB while ignoring existing alpha
00:00 +3: applyTilesetTransparentColorToPngBytes uses the value object parser case-insensitively
00:00 +4: applyTilesetTransparentColorToPngBytes leaves images without matching pixels unchanged by channel values
00:00 +5: applyTilesetTransparentColorToPngBytes rejects invalid PNG bytes
00:00 +6: All tests passed!
```

### Régression Lot 4 map_core

Commande :

```bash
cd packages/map_core && dart test test/tileset_transparent_color_test.dart --reporter expanded --no-color
```

Sortie complète :

```text
00:00 +0: loading test/tileset_transparent_color_test.dart
00:00 +0: TilesetTransparentColor construction accepts RGB components in the 0..255 range
00:00 +1: TilesetTransparentColor construction rejects RGB components outside the 0..255 range
00:00 +2: TilesetTransparentColor hex parsing accepts lowercase, uppercase, and optional # RGB values
00:00 +3: TilesetTransparentColor hex parsing returns canonical lowercase RGB without # and with padding
00:00 +4: TilesetTransparentColor hex parsing rejects invalid hex RGB strings
00:00 +5: TilesetTransparentColor matching matches RGB components exactly
00:00 +6: TilesetTransparentColor matching matches ARGB 32-bit values while ignoring alpha
00:00 +7: TilesetTransparentColor equality uses value equality and stable hashCode
00:00 +8: All tests passed!
```

### Régression Lot 3

Commande :

```bash
cd packages/map_core && dart test test/project_path_preset_center_pattern_adapter_test.dart --reporter expanded --no-color
```

Sortie complète :

```text
00:00 +0: loading test/project_path_preset_center_pattern_adapter_test.dart
00:00 +0: createLegacyProjectPathPresetCenterPatternView uses cross by default and creates a 1x1 center pattern
00:00 +1: createLegacyProjectPathPresetCenterPatternView does not assume isolated is the center
00:00 +2: createLegacyProjectPathPresetCenterPatternView can adapt an explicit variant for debug or compatibility
00:00 +3: createLegacyProjectPathPresetCenterPatternView preserves frame order and durations
00:00 +4: createLegacyProjectPathPresetCenterPatternView exposes global tileset id and preserves frame tileset overrides
00:00 +5: createLegacyProjectPathPresetCenterPatternView rejects missing center variant
00:00 +6: createLegacyProjectPathPresetCenterPatternView rejects empty center variant frames
00:00 +7: createLegacyProjectPathPresetCenterPatternView does not mutate the source preset and copies frame lists into pattern
00:00 +8: createLegacyProjectPathPresetCenterPatternView view has value equality and hashCode
00:00 +9: All tests passed!
```

### Régression Lot 2

Commande :

```bash
cd packages/map_core && dart test test/path_center_pattern_resolver_test.dart --reporter expanded --no-color
```

Sortie complète :

```text
00:00 +0: loading test/path_center_pattern_resolver_test.dart
00:00 +0: resolvePathCenterPatternCell 1x1 always resolves to the single local cell
00:00 +1: resolvePathCenterPatternCell 2x2 uses absolute map coordinates modulo pattern size
00:00 +2: resolvePathCenterPatternCell rectangular 3x2 does not assume square patterns
00:00 +3: resolvePathCenterPatternCell invalid coordinates rejects negative map coordinates
00:00 +4: PathCenterPatternCellResolution keeps map coordinates, local coordinates, and selected cell
00:00 +5: PathCenterPatternCellResolution uses value equality and stable hashCode
00:00 +6: All tests passed!
```

### Régression Lot 1

Commande :

```bash
cd packages/map_core && dart test test/path_center_pattern_test.dart --reporter expanded --no-color
```

Sortie complète :

```text
00:00 +0: loading test/path_center_pattern_test.dart
00:00 +0: PathCenterPatternSize accepts 1x1 and 2x2 sizes
00:00 +1: PathCenterPatternSize rejects non-positive dimensions
00:00 +2: PathCenterPatternSize reports tile count and coordinate containment
00:00 +3: PathCenterPatternSize uses value equality and stable hashCode
00:00 +4: PathCenterPatternCell accepts non-negative local coordinates and frames
00:00 +5: PathCenterPatternCell rejects negative coordinates and empty frames
00:00 +6: PathCenterPatternCell defensively copies frames and exposes an immutable list
00:00 +7: PathCenterPatternCell uses value equality and stable hashCode
00:00 +8: PathCenterPattern 1x1 accepts a complete single-cell grid
00:00 +9: PathCenterPattern 2x2 accepts a complete grid and exposes cells in row-major order
00:00 +10: PathCenterPattern 2x2 defensively copies cells and exposes an immutable list
00:00 +11: PathCenterPattern 2x2 uses value equality and stable hashCode
00:00 +12: PathCenterPattern invalid grids rejects an empty cell list
00:00 +13: PathCenterPattern invalid grids rejects a missing cell
00:00 +14: PathCenterPattern invalid grids rejects a cell outside the grid
00:00 +15: PathCenterPattern invalid grids rejects duplicate coordinates
00:00 +16: PathCenterPattern invalid grids cellAt rejects coordinates outside the grid
00:00 +17: All tests passed!
```

### Régression Lot 0

Commande :

```bash
cd packages/map_core && dart test test/map_terrain_autotile_characterization_test.dart --reporter expanded --no-color
```

Sortie complète :

```text
00:00 +0: loading test/map_terrain_autotile_characterization_test.dart
00:00 +0: map_terrain_autotile characterization mask table documents the public mask-to-variant mapping
00:00 +1: map_terrain_autotile characterization mask table rejects masks outside the current four-bit range
00:00 +2: map_terrain_autotile characterization cardinal path shapes isolated active cell resolves to isolated
00:00 +3: map_terrain_autotile characterization cardinal path shapes horizontal line resolves center and both ends distinctly
00:00 +4: map_terrain_autotile characterization cardinal path shapes vertical line resolves center and both ends distinctly
00:00 +5: map_terrain_autotile characterization cardinal path shapes four cardinal L joins resolve to the matching corner variants
00:00 +6: map_terrain_autotile characterization cardinal path shapes four T joins resolve to the current tee variants
00:00 +7: map_terrain_autotile characterization cardinal path shapes four-way intersection resolves to cross
00:00 +8: map_terrain_autotile characterization cardinal path shapes full 3x3 block center is cross and edges receive border fill
00:00 +9: map_terrain_autotile characterization diagonal-aware interior corners single missing diagonal with all cardinals present creates inner corners
00:00 +10: map_terrain_autotile characterization diagonal-aware interior corners multiple missing diagonals keep the all-cardinal cell as cross
00:00 +11: map_terrain_autotile characterization map edges and out-of-map neighbors non-corner edge cells can be promoted to cross
00:00 +12: map_terrain_autotile characterization map edges and out-of-map neighbors map corner cells keep corner variants when two map edges touch
00:00 +13: map_terrain_autotile characterization map edges and out-of-map neighbors single-edge corner replacements turn some corner variants into ends
00:00 +14: map_terrain_autotile characterization inactive cells and invalid inputs inactive current cell is not checked before resolving neighbors
00:00 +15: map_terrain_autotile characterization inactive cells and invalid inputs coordinates outside the grid throw validation errors
00:00 +16: map_terrain_autotile characterization inactive cells and invalid inputs empty sizes and incomplete grids throw validation errors
00:00 +17: map_terrain_autotile characterization inactive cells and invalid inputs extra path cells beyond map bounds are tolerated and ignored
00:00 +18: map_terrain_autotile characterization terrain resolver parity terrain autotile uses the selected terrain type as the matcher
00:00 +19: map_terrain_autotile characterization terrain resolver parity terrain resolver has the same inactive-current-cell behavior
00:00 +20: map_terrain_autotile characterization terrain resolver parity terrain validation rejects incomplete grids and out-of-bounds positions
00:00 +21: All tests passed!
```

### Test complet map_core

Commande :

```bash
cd packages/map_core && dart test --no-color --reporter expanded
```

Ligne finale exacte :

```text
00:01 +1067: All tests passed!
```

## 12. Analyze

Commande :

```bash
cd packages/map_editor && flutter analyze lib/src/application/services/tileset_transparent_color_processor.dart test/path_pattern/tileset_transparent_color_processor_test.dart
```

Sortie complète :

```text
Analyzing 2 items...                                            
No issues found! (ran in 1.8s)
```

## 13. Non-objectifs confirmés

Confirmé :

```text
- pas de Path Studio UI ;
- pas de nouvelle UI ;
- pas de preview ;
- pas de canvas rendering ;
- pas de runtime ;
- pas de gameplay ;
- pas de MapGameplayZone ;
- pas de ProjectManifest ;
- pas de JSON ;
- pas de codec ;
- pas de generated files ;
- pas de build_runner ;
- pas de Freezed ;
- pas de modification ProjectPathPreset ;
- pas de modification TerrainPathVariant ;
- pas de modification PathLayer ;
- pas de modification map_runtime ;
- pas de modification map_gameplay ;
- pas de modification map_battle ;
- pas de TSX ;
- pas de TMX ;
- pas de Mistral ;
- pas de PixelLab ;
- pas de MCP ;
- pas de résolution temporelle des frames ;
- pas de painter integration ;
- pas de save flow ;
- pas de modification des images sources ;
- pas de création de fichiers PNG sur disque.
```

Le fichier image fourni par l’utilisateur :

```text
/Users/karim/Desktop/assets/Tiled/Assets/TECH-Nature-animations.png
```

n’a pas été lu ni modifié. Les tests construisent des PNG en mémoire.

## 14. Limites restantes

Le processeur existe, mais il n’est pas encore branché :

```text
- aucune preview statique ;
- aucune preview animée ;
- aucune UI Path Studio ;
- aucun cache image ;
- aucune application automatique aux tilesets projet ;
- aucun rendu canvas ;
- aucun runtime.
```

La fonction réencode toujours un nouveau PNG quand `transparentColor` est non null, même si aucun pixel ne matche. C’est acceptable pour V0 et testé par comparaison des canaux après décodage, pas par identité des bytes.

## 15. Git status final

Statut après création du rapport :

```text
?? packages/map_editor/lib/src/application/services/tileset_transparent_color_processor.dart
?? packages/map_editor/test/path_pattern/tileset_transparent_color_processor_test.dart
?? reports/pathPattern/path_pattern_lot_04_bis_png_alpha_processor.md
```

## 16. Prochain lot recommandé

Prochain lot recommandé :

```text
PathPattern-5 — Path Center Pattern Static Preview V0
```

Objectif recommandé :

```text
Utiliser PathCenterPattern + applyTilesetTransparentColorToPngBytes pour afficher une preview statique en mémoire, sans Path Studio complet.
```

## Evidence Pack

### Contenu complet — tileset_transparent_color_processor.dart

```dart
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:map_core/map_core.dart';

Uint8List applyTilesetTransparentColorToPngBytes({
  required Uint8List imageBytes,
  required TilesetTransparentColor? transparentColor,
}) {
  if (transparentColor == null) {
    return imageBytes;
  }

  final image = img.decodePng(imageBytes);
  if (image == null) {
    throw ArgumentError.value(
      imageBytes,
      'imageBytes',
      'Tileset transparent color processor expected valid PNG bytes.',
    );
  }

  for (var y = 0; y < image.height; y += 1) {
    for (var x = 0; x < image.width; x += 1) {
      final pixel = image.getPixel(x, y);
      final red = pixel.r.toInt();
      final green = pixel.g.toInt();
      final blue = pixel.b.toInt();

      if (transparentColor.matchesRgb(red: red, green: green, blue: blue)) {
        image.setPixelRgba(x, y, red, green, blue, 0);
      }
    }
  }

  return img.encodePng(image);
}
```

### Contenu complet — tileset_transparent_color_processor_test.dart

```dart
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/services/tileset_transparent_color_processor.dart';

void main() {
  group('applyTilesetTransparentColorToPngBytes', () {
    test('returns the same bytes instance when transparentColor is null', () {
      final imageBytes = _pngBytes([
        const _Pixel(red: 240, green: 91, blue: 161, alpha: 255),
        const _Pixel(red: 0, green: 0, blue: 255, alpha: 255),
      ]);

      final result = applyTilesetTransparentColorToPngBytes(
        imageBytes: imageBytes,
        transparentColor: null,
      );

      expect(identical(result, imageBytes), isTrue);
      expect(result, imageBytes);
    });

    test('turns matching RGB pixels transparent and preserves others', () {
      final imageBytes = _pngBytes([
        const _Pixel(red: 240, green: 91, blue: 161, alpha: 255),
        const _Pixel(red: 0, green: 0, blue: 255, alpha: 255),
      ]);

      final result = applyTilesetTransparentColorToPngBytes(
        imageBytes: imageBytes,
        transparentColor: TilesetTransparentColor.fromHexRgb('f05ba1'),
      );
      final image = _decodePng(result);

      expect(_pixelAt(image, 0, 0),
          const _Pixel(red: 240, green: 91, blue: 161, alpha: 0));
      expect(_pixelAt(image, 1, 0),
          const _Pixel(red: 0, green: 0, blue: 255, alpha: 255));
    });

    test('matches RGB while ignoring existing alpha', () {
      final imageBytes = _pngBytes([
        const _Pixel(red: 240, green: 91, blue: 161, alpha: 128),
        const _Pixel(red: 0, green: 0, blue: 255, alpha: 128),
      ]);

      final result = applyTilesetTransparentColorToPngBytes(
        imageBytes: imageBytes,
        transparentColor: TilesetTransparentColor.fromHexRgb('f05ba1'),
      );
      final image = _decodePng(result);

      expect(_pixelAt(image, 0, 0),
          const _Pixel(red: 240, green: 91, blue: 161, alpha: 0));
      expect(_pixelAt(image, 1, 0),
          const _Pixel(red: 0, green: 0, blue: 255, alpha: 128));
    });

    test('uses the value object parser case-insensitively', () {
      final imageBytes = _pngBytes([
        const _Pixel(red: 240, green: 91, blue: 161, alpha: 255),
        const _Pixel(red: 0, green: 0, blue: 255, alpha: 255),
      ]);

      final result = applyTilesetTransparentColorToPngBytes(
        imageBytes: imageBytes,
        transparentColor: TilesetTransparentColor.fromHexRgb('#F05BA1'),
      );
      final image = _decodePng(result);

      expect(_pixelAt(image, 0, 0),
          const _Pixel(red: 240, green: 91, blue: 161, alpha: 0));
      expect(_pixelAt(image, 1, 0),
          const _Pixel(red: 0, green: 0, blue: 255, alpha: 255));
    });

    test('leaves images without matching pixels unchanged by channel values',
        () {
      final imageBytes = _pngBytes([
        const _Pixel(red: 0, green: 255, blue: 0, alpha: 64),
        const _Pixel(red: 0, green: 0, blue: 255, alpha: 128),
      ]);

      final result = applyTilesetTransparentColorToPngBytes(
        imageBytes: imageBytes,
        transparentColor: TilesetTransparentColor.fromHexRgb('f05ba1'),
      );
      final image = _decodePng(result);

      expect(_pixelAt(image, 0, 0),
          const _Pixel(red: 0, green: 255, blue: 0, alpha: 64));
      expect(_pixelAt(image, 1, 0),
          const _Pixel(red: 0, green: 0, blue: 255, alpha: 128));
    });

    test('rejects invalid PNG bytes', () {
      expect(
        () => applyTilesetTransparentColorToPngBytes(
          imageBytes: Uint8List.fromList([1, 2, 3]),
          transparentColor: TilesetTransparentColor.fromHexRgb('f05ba1'),
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}

Uint8List _pngBytes(List<_Pixel> pixels) {
  final image = img.Image(width: pixels.length, height: 1, numChannels: 4);
  for (var x = 0; x < pixels.length; x += 1) {
    final pixel = pixels[x];
    image.setPixelRgba(x, 0, pixel.red, pixel.green, pixel.blue, pixel.alpha);
  }
  return img.encodePng(image);
}

img.Image _decodePng(Uint8List imageBytes) {
  final image = img.decodePng(imageBytes);
  expect(image, isNotNull);
  return image!;
}

_Pixel _pixelAt(img.Image image, int x, int y) {
  final pixel = image.getPixel(x, y);
  return _Pixel(
    red: pixel.r.toInt(),
    green: pixel.g.toInt(),
    blue: pixel.b.toInt(),
    alpha: pixel.a.toInt(),
  );
}

final class _Pixel {
  const _Pixel({
    required this.red,
    required this.green,
    required this.blue,
    required this.alpha,
  });

  final int red;
  final int green;
  final int blue;
  final int alpha;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is _Pixel &&
            other.red == red &&
            other.green == green &&
            other.blue == blue &&
            other.alpha == alpha;
  }

  @override
  int get hashCode => Object.hash(red, green, blue, alpha);

  @override
  String toString() {
    return '_Pixel(red: $red, green: $green, blue: $blue, alpha: $alpha)';
  }
}
```

### Diff complet réel — tileset_transparent_color_processor.dart

```diff
diff --git a/packages/map_editor/lib/src/application/services/tileset_transparent_color_processor.dart b/packages/map_editor/lib/src/application/services/tileset_transparent_color_processor.dart
new file mode 100644
index 00000000..0a85a498
--- /dev/null
+++ b/packages/map_editor/lib/src/application/services/tileset_transparent_color_processor.dart
@@ -0,0 +1,37 @@
+import 'dart:typed_data';
+
+import 'package:image/image.dart' as img;
+import 'package:map_core/map_core.dart';
+
+Uint8List applyTilesetTransparentColorToPngBytes({
+  required Uint8List imageBytes,
+  required TilesetTransparentColor? transparentColor,
+}) {
+  if (transparentColor == null) {
+    return imageBytes;
+  }
+
+  final image = img.decodePng(imageBytes);
+  if (image == null) {
+    throw ArgumentError.value(
+      imageBytes,
+      'imageBytes',
+      'Tileset transparent color processor expected valid PNG bytes.',
+    );
+  }
+
+  for (var y = 0; y < image.height; y += 1) {
+    for (var x = 0; x < image.width; x += 1) {
+      final pixel = image.getPixel(x, y);
+      final red = pixel.r.toInt();
+      final green = pixel.g.toInt();
+      final blue = pixel.b.toInt();
+
+      if (transparentColor.matchesRgb(red: red, green: green, blue: blue)) {
+        image.setPixelRgba(x, y, red, green, blue, 0);
+      }
+    }
+  }
+
+  return img.encodePng(image);
+}
```

### Diff complet réel — tileset_transparent_color_processor_test.dart

```diff
diff --git a/packages/map_editor/test/path_pattern/tileset_transparent_color_processor_test.dart b/packages/map_editor/test/path_pattern/tileset_transparent_color_processor_test.dart
new file mode 100644
index 00000000..738e2caa
--- /dev/null
+++ b/packages/map_editor/test/path_pattern/tileset_transparent_color_processor_test.dart
@@ -0,0 +1,165 @@
+import 'dart:typed_data';
+
+import 'package:flutter_test/flutter_test.dart';
+import 'package:image/image.dart' as img;
+import 'package:map_core/map_core.dart';
+import 'package:map_editor/src/application/services/tileset_transparent_color_processor.dart';
+
+void main() {
+  group('applyTilesetTransparentColorToPngBytes', () {
+    test('returns the same bytes instance when transparentColor is null', () {
+      final imageBytes = _pngBytes([
+        const _Pixel(red: 240, green: 91, blue: 161, alpha: 255),
+        const _Pixel(red: 0, green: 0, blue: 255, alpha: 255),
+      ]);
+
+      final result = applyTilesetTransparentColorToPngBytes(
+        imageBytes: imageBytes,
+        transparentColor: null,
+      );
+
+      expect(identical(result, imageBytes), isTrue);
+      expect(result, imageBytes);
+    });
+
+    test('turns matching RGB pixels transparent and preserves others', () {
+      final imageBytes = _pngBytes([
+        const _Pixel(red: 240, green: 91, blue: 161, alpha: 255),
+        const _Pixel(red: 0, green: 0, blue: 255, alpha: 255),
+      ]);
+
+      final result = applyTilesetTransparentColorToPngBytes(
+        imageBytes: imageBytes,
+        transparentColor: TilesetTransparentColor.fromHexRgb('f05ba1'),
+      );
+      final image = _decodePng(result);
+
+      expect(_pixelAt(image, 0, 0),
+          const _Pixel(red: 240, green: 91, blue: 161, alpha: 0));
+      expect(_pixelAt(image, 1, 0),
+          const _Pixel(red: 0, green: 0, blue: 255, alpha: 255));
+    });
+
+    test('matches RGB while ignoring existing alpha', () {
+      final imageBytes = _pngBytes([
+        const _Pixel(red: 240, green: 91, blue: 161, alpha: 128),
+        const _Pixel(red: 0, green: 0, blue: 255, alpha: 128),
+      ]);
+
+      final result = applyTilesetTransparentColorToPngBytes(
+        imageBytes: imageBytes,
+        transparentColor: TilesetTransparentColor.fromHexRgb('f05ba1'),
+      );
+      final image = _decodePng(result);
+
+      expect(_pixelAt(image, 0, 0),
+          const _Pixel(red: 240, green: 91, blue: 161, alpha: 0));
+      expect(_pixelAt(image, 1, 0),
+          const _Pixel(red: 0, green: 0, blue: 255, alpha: 128));
+    });
+
+    test('uses the value object parser case-insensitively', () {
+      final imageBytes = _pngBytes([
+        const _Pixel(red: 240, green: 91, blue: 161, alpha: 255),
+        const _Pixel(red: 0, green: 0, blue: 255, alpha: 255),
+      ]);
+
+      final result = applyTilesetTransparentColorToPngBytes(
+        imageBytes: imageBytes,
+        transparentColor: TilesetTransparentColor.fromHexRgb('#F05BA1'),
+      );
+      final image = _decodePng(result);
+
+      expect(_pixelAt(image, 0, 0),
+          const _Pixel(red: 240, green: 91, blue: 161, alpha: 0));
+      expect(_pixelAt(image, 1, 0),
+          const _Pixel(red: 0, green: 0, blue: 255, alpha: 255));
+    });
+
+    test('leaves images without matching pixels unchanged by channel values',
+        () {
+      final imageBytes = _pngBytes([
+        const _Pixel(red: 0, green: 255, blue: 0, alpha: 64),
+        const _Pixel(red: 0, green: 0, blue: 255, alpha: 128),
+      ]);
+
+      final result = applyTilesetTransparentColorToPngBytes(
+        imageBytes: imageBytes,
+        transparentColor: TilesetTransparentColor.fromHexRgb('f05ba1'),
+      );
+      final image = _decodePng(result);
+
+      expect(_pixelAt(image, 0, 0),
+          const _Pixel(red: 0, green: 255, blue: 0, alpha: 64));
+      expect(_pixelAt(image, 1, 0),
+          const _Pixel(red: 0, green: 0, blue: 255, alpha: 128));
+    });
+
+    test('rejects invalid PNG bytes', () {
+      expect(
+        () => applyTilesetTransparentColorToPngBytes(
+          imageBytes: Uint8List.fromList([1, 2, 3]),
+          transparentColor: TilesetTransparentColor.fromHexRgb('f05ba1'),
+        ),
+        throwsA(isA<ArgumentError>()),
+      );
+    });
+  });
+}
+
+Uint8List _pngBytes(List<_Pixel> pixels) {
+  final image = img.Image(width: pixels.length, height: 1, numChannels: 4);
+  for (var x = 0; x < pixels.length; x += 1) {
+    final pixel = pixels[x];
+    image.setPixelRgba(x, 0, pixel.red, pixel.green, pixel.blue, pixel.alpha);
+  }
+  return img.encodePng(image);
+}
+
+img.Image _decodePng(Uint8List imageBytes) {
+  final image = img.decodePng(imageBytes);
+  expect(image, isNotNull);
+  return image!;
+}
+
+_Pixel _pixelAt(img.Image image, int x, int y) {
+  final pixel = image.getPixel(x, y);
+  return _Pixel(
+    red: pixel.r.toInt(),
+    green: pixel.g.toInt(),
+    blue: pixel.b.toInt(),
+    alpha: pixel.a.toInt(),
+  );
+}
+
+final class _Pixel {
+  const _Pixel({
+    required this.red,
+    required this.green,
+    required this.blue,
+    required this.alpha,
+  });
+
+  final int red;
+  final int green;
+  final int blue;
+  final int alpha;
+
+  @override
+  bool operator ==(Object other) {
+    return identical(this, other) ||
+        other is _Pixel &&
+            other.red == red &&
+            other.green == green &&
+            other.blue == blue &&
+            other.alpha == alpha;
+  }
+
+  @override
+  int get hashCode => Object.hash(red, green, blue, alpha);
+
+  @override
+  String toString() {
+    return '_Pixel(red: $red, green: $green, blue: $blue, alpha: $alpha)';
+  }
+}
```

### Vérification no accidental coupling

Commande :

```bash
rg -n "map_runtime|map_gameplay|map_battle|ProjectManifest|ProjectPathPreset|toJson|fromJson|build_runner|Freezed|dart:ui|Image\.memory|MemoryImage|File\(|writeAsBytes|readAsBytes" packages/map_editor/lib/src/application/services/tileset_transparent_color_processor.dart packages/map_editor/test/path_pattern/tileset_transparent_color_processor_test.dart
```

Sortie :

```text
```

### Context Mode

`ctx` CLI n’est pas disponible dans le shell :

```text
command -v ctx
```

a retourné une sortie vide et un code de sortie `1`.

Le MCP Context Mode disponible a été utilisé. Statistiques MCP :

```text
1.3M tokens saved  ·  82.8% reduction  ·  21h 50m
Without context-mode  |████████████████████████████████████████| 5.8 MB
With context-mode     |███████░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░| 1018.1 KB
4.8 MB kept out of your conversation. Never entered context.
166 calls
ctx_batch_execute         53 calls    3.6 MB saved
ctx_execute               68 calls  481.1 KB saved
ctx_search                15 calls  444.5 KB saved
ctx_execute_file          15 calls  165.0 KB saved
ctx_fetch_and_index        3 calls   47.1 KB saved
ctx_stats                 12 calls   41.4 KB saved
v1.0.103
```

## Auto-review

- Ai-je gardé le traitement côté `map_editor` ? Oui.
- Ai-je évité `map_core` pour le PNG ? Oui.
- Ai-je évité toute écriture disque ? Oui.
- Ai-je évité une couleur par défaut hardcodée ? Oui. Les tests utilisent `f05ba1` comme donnée d’entrée, jamais comme défaut implicite.
- Ai-je conservé les RGB ? Oui, testé sur pixel matching et non matching.
- Ai-je conservé l’alpha des pixels non matching ? Oui, testé avec alpha `128` et `64`.
- Ai-je rejeté les PNG invalides ? Oui, `ArgumentError` testé.
- Ai-je évité runtime/gameplay/battle ? Oui, vérifié par audit `rg`.

## Critique du prompt

- Ambiguïté mineure : `transparentColor null` demandait “mêmes bytes ou bytes équivalents”, avec préférence pour la même instance. J’ai choisi la même instance pour éviter tout décodage inutile.
- Choix de dépendance image : aucune nouvelle dépendance ajoutée, car `image` était déjà direct main dans `map_editor`.
- Décision à valider avant la preview statique : le futur lot devra décider si le processeur est appelé à chaque rendu, mis en cache par tileset/couleur, ou prétraité dans un read model editor.
