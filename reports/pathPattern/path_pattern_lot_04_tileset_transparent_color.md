# Lot PathPattern-4 — Tileset Transparent Color V0

## 1. Verdict

Lot validé.

Ce lot ajoute un value object pur `TilesetTransparentColor` dans `map_core`. Il représente une couleur RGB configurable utilisable plus tard comme couleur transparente de tileset.

Le modèle :

```text
- valide red / green / blue dans 0..255 ;
- parse les hex RGB avec ou sans # ;
- retourne un hex canonique lowercase sans # ;
- compare des pixels RGB ;
- compare des entiers ARGB 32 bits en ignorant l'alpha ;
- reste indépendant de Flutter, dart:ui, images, PNG, JSON, runtime et gameplay.
```

## 2. Audit initial

Commandes initiales exécutées :

```bash
pwd
git status --short --untracked-files=all
git diff --stat
rg -n "transparent|transparency|transparentColor|f05ba1|Color|ARGB|RGB|TilesetTransparentColor|TilesetVisualFrame|TilesetSourceRect|tileset" packages/map_core/lib packages/map_core/test packages/map_editor/lib packages/map_editor/test
```

Sortie `pwd` :

```text
/Users/karim/Project/pokemonProject
```

Sortie `git status --short --untracked-files=all` initiale :

```text
```

Sortie `git diff --stat` initiale :

```text
```

Context Mode :

```text
command -v ctx
```

Sortie :

```text
```

Exit code : `1`. Le binaire `ctx` n'est pas dans le PATH, mais le MCP Context Mode a été utilisé pour l'audit et les sorties volumineuses.

Stats Context Mode :

```text
1.1M tokens saved  ·  81.8% reduction  ·  21h 31m

Without context-mode  |████████████████████████████████████████| 5.1 MB
With context-mode     |███████░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░| 942.1 KB

4.1 MB kept out of your conversation. Never entered context.

158 calls

  ctx_batch_execute         49 calls    3.1 MB saved
  ctx_execute               65 calls  436.2 KB saved
  ctx_search                15 calls  416.4 KB saved
  ctx_execute_file          15 calls  154.6 KB saved
  ctx_fetch_and_index        3 calls   44.2 KB saved
  ctx_stats                 11 calls   35.6 KB saved

v1.0.103
```

Réponses d'audit :

1. Aucun modèle `TilesetTransparentColor` existant n'a été trouvé avant ce lot.
2. Aucune notion `transparentColor` active dans `map_core` n'a été identifiée avant ce lot.
3. Aucun hardcode exact `f05ba1` n'a été identifié dans l'audit initial.
4. Le bon emplacement est `packages/map_core/lib/src/models/tileset_transparent_color.dart`, car le modèle est un value object pur, portable, sans dépendance image.
5. Le traitement PNG est hors lot parce qu'il implique des bytes, decode/encode d'image, et probablement une dépendance editor/applicative. Le contrat du lot demande seulement une représentation RGB pure.
6. Tests existants à relancer : `project_path_preset_center_pattern_adapter_test.dart`, `path_center_pattern_resolver_test.dart`, `path_center_pattern_test.dart`, `map_terrain_autotile_characterization_test.dart`, puis tout `map_core`.

## 3. Fichiers créés / modifiés / supprimés

Créés :

```text
packages/map_core/lib/src/models/tileset_transparent_color.dart
packages/map_core/test/tileset_transparent_color_test.dart
reports/pathPattern/path_pattern_lot_04_tileset_transparent_color.md
```

Modifié :

```text
packages/map_core/lib/map_core.dart
```

Supprimés :

```text
aucun
```

## 4. API ajoutée

Fichier :

```text
packages/map_core/lib/src/models/tileset_transparent_color.dart
```

API :

```dart
final class TilesetTransparentColor {
  factory TilesetTransparentColor({
    required int red,
    required int green,
    required int blue,
  });

  factory TilesetTransparentColor.fromHexRgb(String value);

  final int red;
  final int green;
  final int blue;

  String toHexRgb();

  bool matchesRgb({
    required int red,
    required int green,
    required int blue,
  });

  bool matchesArgb32(int argb);
}
```

Export ajouté :

```dart
export 'src/models/tileset_transparent_color.dart';
```

## 5. Décision sur format hex

Le format accepté est strictement RGB 24 bits :

```text
f05ba1
F05BA1
#f05ba1
#F05BA1
```

Le format canonique retourné par `toHexRgb()` est :

```text
lowercase
6 caractères
sans #
```

Exemples testés :

```text
#F05BA1 -> f05ba1
red=0 green=0 blue=255 -> 0000ff
```

Formats rejetés :

```text
''
'#'
'f05ba'
'f05ba11'
'gggggg'
'#gggggg'
'f05ba1ff'
'0xF05BA1'
```

## 6. Décision sur absence d'alpha dans le modèle

Le modèle ne contient pas d'alpha.

Raison :

```text
La couleur transparente est une clé RGB de tileset, pas une couleur de rendu.
Ajouter alpha maintenant mélangerait le modèle pur avec des préoccupations d'image.
```

## 7. Décision sur matchesArgb32 et alpha ignoré

`matchesArgb32(int argb)` masque les 24 bits RGB bas :

```dart
final rgb = argb & 0x00ffffff;
```

L'alpha est ignoré volontairement.

Exemples testés :

```text
0xFFF05BA1 -> true
0x00F05BA1 -> true
0x80F05BA1 -> true
0xFF0000FF -> false
```

## 8. Pourquoi le traitement PNG est hors lot

Le traitement PNG requiert :

```text
- lecture de bytes ;
- décodage image ;
- mutation en mémoire d'un buffer ;
- choix de dépendance image ;
- intégration preview ou editor.
```

Ce lot reste volontairement dans `map_core`, sans `dart:ui`, sans Flutter et sans dépendance image. L'application réelle de la transparence sera un lot ultérieur.

## 9. Tests lancés

### TDD RED

Commande :

```bash
cd packages/map_core && dart test test/tileset_transparent_color_test.dart --reporter expanded
```

Sortie :

```text
00:00 +0: loading test/tileset_transparent_color_test.dart
00:00 +0 -1: loading test/tileset_transparent_color_test.dart [E]
  Failed to load "test/tileset_transparent_color_test.dart":
  test/tileset_transparent_color_test.dart:7:21: Error: Method not found: 'TilesetTransparentColor'.
        final color = TilesetTransparentColor(red: 240, green: 91, blue: 161);
                      ^^^^^^^^^^^^^^^^^^^^^^^
  test/tileset_transparent_color_test.dart:16:15: Error: Method not found: 'TilesetTransparentColor'.
          () => TilesetTransparentColor(red: -1, green: 91, blue: 161),
                ^^^^^^^^^^^^^^^^^^^^^^^
  test/tileset_transparent_color_test.dart:20:15: Error: Method not found: 'TilesetTransparentColor'.
          () => TilesetTransparentColor(red: 256, green: 91, blue: 161),
                ^^^^^^^^^^^^^^^^^^^^^^^
  test/tileset_transparent_color_test.dart:24:15: Error: Method not found: 'TilesetTransparentColor'.
          () => TilesetTransparentColor(red: 240, green: -1, blue: 161),
                ^^^^^^^^^^^^^^^^^^^^^^^
  test/tileset_transparent_color_test.dart:28:15: Error: Method not found: 'TilesetTransparentColor'.
          () => TilesetTransparentColor(red: 240, green: 256, blue: 161),
                ^^^^^^^^^^^^^^^^^^^^^^^
  test/tileset_transparent_color_test.dart:32:15: Error: Method not found: 'TilesetTransparentColor'.
          () => TilesetTransparentColor(red: 240, green: 91, blue: -1),
                ^^^^^^^^^^^^^^^^^^^^^^^
  test/tileset_transparent_color_test.dart:36:15: Error: Method not found: 'TilesetTransparentColor'.
          () => TilesetTransparentColor(red: 240, green: 91, blue: 256),
                ^^^^^^^^^^^^^^^^^^^^^^^
  test/tileset_transparent_color_test.dart:45:23: Error: Undefined name 'TilesetTransparentColor'.
          final color = TilesetTransparentColor.fromHexRgb(value);
                        ^^^^^^^^^^^^^^^^^^^^^^^
  test/tileset_transparent_color_test.dart:55:9: Error: Undefined name 'TilesetTransparentColor'.
          TilesetTransparentColor.fromHexRgb('#F05BA1').toHexRgb(),
          ^^^^^^^^^^^^^^^^^^^^^^^
  test/tileset_transparent_color_test.dart:59:9: Error: Method not found: 'TilesetTransparentColor'.
          TilesetTransparentColor(red: 0, green: 0, blue: 255).toHexRgb(),
          ^^^^^^^^^^^^^^^^^^^^^^^
  test/tileset_transparent_color_test.dart:76:17: Error: Undefined name 'TilesetTransparentColor'.
            () => TilesetTransparentColor.fromHexRgb(value),
                  ^^^^^^^^^^^^^^^^^^^^^^^
  test/tileset_transparent_color_test.dart:86:21: Error: Undefined name 'TilesetTransparentColor'.
        final color = TilesetTransparentColor.fromHexRgb('f05ba1');
                      ^^^^^^^^^^^^^^^^^^^^^^^
  test/tileset_transparent_color_test.dart:93:21: Error: Undefined name 'TilesetTransparentColor'.
        final color = TilesetTransparentColor.fromHexRgb('f05ba1');
                      ^^^^^^^^^^^^^^^^^^^^^^^
  test/tileset_transparent_color_test.dart:104:17: Error: Undefined name 'TilesetTransparentColor'.
        final a = TilesetTransparentColor.fromHexRgb('f05ba1');
                  ^^^^^^^^^^^^^^^^^^^^^^^
  test/tileset_transparent_color_test.dart:105:17: Error: Undefined name 'TilesetTransparentColor'.
        final b = TilesetTransparentColor.fromHexRgb('#F05BA1');
                  ^^^^^^^^^^^^^^^^^^^^^^^
  test/tileset_transparent_color_test.dart:106:17: Error: Method not found: 'TilesetTransparentColor'.
        final c = TilesetTransparentColor(red: 0, green: 0, blue: 255);
                  ^^^^^^^^^^^^^^^^^^^^^^^
00:00 +0 -1: Some tests failed.
```

### Test ciblé Lot 4

Commande :

```bash
cd packages/map_core && dart test test/tileset_transparent_color_test.dart --reporter expanded
```

Sortie :

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

### Régression PathPattern Lot 3

Commande :

```bash
cd packages/map_core && dart test test/project_path_preset_center_pattern_adapter_test.dart --reporter expanded
```

Sortie :

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

### Régression PathPattern Lot 2

Commande :

```bash
cd packages/map_core && dart test test/path_center_pattern_resolver_test.dart --reporter expanded
```

Sortie :

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

### Régression PathPattern Lot 1

Commande :

```bash
cd packages/map_core && dart test test/path_center_pattern_test.dart --reporter expanded
```

Sortie :

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

### Régression PathPattern Lot 0

Commande :

```bash
cd packages/map_core && dart test test/map_terrain_autotile_characterization_test.dart --reporter expanded
```

Sortie :

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
cd packages/map_core && dart test
cd packages/map_core && dart test --reporter compact
```

Ligne finale exacte :

```text
00:02 +1067: All tests passed!
```

## 10. Analyze

Commande :

```bash
cd packages/map_core && dart analyze lib/src/models/tileset_transparent_color.dart test/tileset_transparent_color_test.dart
```

Sortie :

```text
Analyzing tileset_transparent_color.dart, tileset_transparent_color_test.dart...
No issues found!
```

## 11. Non-objectifs confirmés

Confirmé :

```text
- aucune UI créée ;
- aucune preview ajoutée ;
- aucun traitement PNG ;
- aucune image source modifiée ;
- aucune image dérivée créée ;
- aucune sauvegarde disque ;
- aucun runtime modifié ;
- aucun gameplay modifié ;
- aucun battle package modifié ;
- aucun ProjectManifest modifié ;
- aucun ProjectPathPreset modifié ;
- aucun JSON ajouté ;
- aucun fichier generated ajouté ;
- aucun build_runner lancé ;
- aucune résolution temporelle de frames ;
- aucune intégration painter ;
- aucun save flow.
```

Vérification de couplage accidentel :

```bash
rg -n "dart:ui|flutter|map_editor|map_runtime|map_gameplay|map_battle|ProjectManifest|ProjectPathPreset|toJson|fromJson|build_runner|Freezed|Uint8List|PNG|png" packages/map_core/lib/src/models/tileset_transparent_color.dart packages/map_core/test/tileset_transparent_color_test.dart
```

Sortie :

```text
```

Exit code : `1`, donc aucun résultat.

## 12. Limites restantes

`TilesetTransparentColor` ne sait pas appliquer la transparence à une image. C'est volontaire.

`matchesArgb32` ignore l'alpha, mais ne valide pas que l'entier d'entrée est dans une plage 32 bits stricte. Il lit uniquement les 24 bits RGB bas, ce qui correspond au contrat V0.

Le modèle n'est pas encore accroché à un tileset, à un preset ou à un manifest.

## 13. Git status final

```text
 M packages/map_core/lib/map_core.dart
?? packages/map_core/lib/src/models/tileset_transparent_color.dart
?? packages/map_core/test/tileset_transparent_color_test.dart
?? reports/pathPattern/path_pattern_lot_04_tileset_transparent_color.md
```

## 14. Prochain lot recommandé

Prochain lot recommandé :

```text
PathPattern-5 — Static Preview V0
```

Option alternative si on veut d'abord utiliser concrètement la couleur :

```text
PathPattern-4-bis — PNG Alpha Processor côté editor
```

## Evidence Pack

### `git diff --stat` final

```text
 packages/map_core/lib/map_core.dart | 1 +
 1 file changed, 1 insertion(+)
```

Note : les fichiers nouvellement créés apparaissent dans `git status --short --untracked-files=all`, pas dans ce `git diff --stat` tant qu'ils ne sont pas indexés.

### `git diff --name-status` final

```text
M	packages/map_core/lib/map_core.dart
```

### Contenu complet — packages/map_core/lib/src/models/tileset_transparent_color.dart

```dart
/// RGB color configured as transparent for a tileset.
final class TilesetTransparentColor {
  factory TilesetTransparentColor({
    required int red,
    required int green,
    required int blue,
  }) {
    _validateChannel(red, 'red');
    _validateChannel(green, 'green');
    _validateChannel(blue, 'blue');
    return TilesetTransparentColor._(red: red, green: green, blue: blue);
  }

  factory TilesetTransparentColor.fromHexRgb(String value) {
    final hex = value.startsWith('#') ? value.substring(1) : value;
    if (hex.length != 6 || !_isHexRgb(hex)) {
      throw ArgumentError.value(
        value,
        'value',
        'TilesetTransparentColor hex RGB must contain exactly '
            '6 hexadecimal characters.',
      );
    }

    return TilesetTransparentColor(
      red: int.parse(hex.substring(0, 2), radix: 16),
      green: int.parse(hex.substring(2, 4), radix: 16),
      blue: int.parse(hex.substring(4, 6), radix: 16),
    );
  }

  const TilesetTransparentColor._({
    required this.red,
    required this.green,
    required this.blue,
  });

  final int red;
  final int green;
  final int blue;

  String toHexRgb() {
    return _toHexChannel(red) + _toHexChannel(green) + _toHexChannel(blue);
  }

  bool matchesRgb({
    required int red,
    required int green,
    required int blue,
  }) {
    return this.red == red && this.green == green && this.blue == blue;
  }

  bool matchesArgb32(int argb) {
    final rgb = argb & 0x00ffffff;
    final red = (rgb >> 16) & 0xff;
    final green = (rgb >> 8) & 0xff;
    final blue = rgb & 0xff;
    return matchesRgb(red: red, green: green, blue: blue);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is TilesetTransparentColor &&
            red == other.red &&
            green == other.green &&
            blue == other.blue;
  }

  @override
  int get hashCode => Object.hash(red, green, blue);
}

void _validateChannel(int value, String name) {
  if (value < 0 || value > 255) {
    throw ArgumentError.value(
      value,
      name,
      'TilesetTransparentColor $name must be between 0 and 255.',
    );
  }
}

bool _isHexRgb(String value) {
  for (var index = 0; index < value.length; index += 1) {
    final codeUnit = value.codeUnitAt(index);
    final isDigit = codeUnit >= 0x30 && codeUnit <= 0x39;
    final isUppercaseHex = codeUnit >= 0x41 && codeUnit <= 0x46;
    final isLowercaseHex = codeUnit >= 0x61 && codeUnit <= 0x66;
    if (!isDigit && !isUppercaseHex && !isLowercaseHex) {
      return false;
    }
  }
  return true;
}

String _toHexChannel(int value) {
  return value.toRadixString(16).padLeft(2, '0');
}
```

### Contenu complet — packages/map_core/test/tileset_transparent_color_test.dart

```dart
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('TilesetTransparentColor construction', () {
    test('accepts RGB components in the 0..255 range', () {
      final color = TilesetTransparentColor(red: 240, green: 91, blue: 161);

      expect(color.red, 240);
      expect(color.green, 91);
      expect(color.blue, 161);
    });

    test('rejects RGB components outside the 0..255 range', () {
      expect(
        () => TilesetTransparentColor(red: -1, green: 91, blue: 161),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => TilesetTransparentColor(red: 256, green: 91, blue: 161),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => TilesetTransparentColor(red: 240, green: -1, blue: 161),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => TilesetTransparentColor(red: 240, green: 256, blue: 161),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => TilesetTransparentColor(red: 240, green: 91, blue: -1),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => TilesetTransparentColor(red: 240, green: 91, blue: 256),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('TilesetTransparentColor hex parsing', () {
    test('accepts lowercase, uppercase, and optional # RGB values', () {
      for (final value in ['f05ba1', 'F05BA1', '#f05ba1', '#F05BA1']) {
        final color = TilesetTransparentColor.fromHexRgb(value);

        expect(color.red, 240);
        expect(color.green, 91);
        expect(color.blue, 161);
      }
    });

    test('returns canonical lowercase RGB without # and with padding', () {
      expect(
        TilesetTransparentColor.fromHexRgb('#F05BA1').toHexRgb(),
        'f05ba1',
      );
      expect(
        TilesetTransparentColor(red: 0, green: 0, blue: 255).toHexRgb(),
        '0000ff',
      );
    });

    test('rejects invalid hex RGB strings', () {
      for (final value in [
        '',
        '#',
        'f05ba',
        'f05ba11',
        'gggggg',
        '#gggggg',
        'f05ba1ff',
        '0xF05BA1',
      ]) {
        expect(
          () => TilesetTransparentColor.fromHexRgb(value),
          throwsA(isA<ArgumentError>()),
          reason: value,
        );
      }
    });
  });

  group('TilesetTransparentColor matching', () {
    test('matches RGB components exactly', () {
      final color = TilesetTransparentColor.fromHexRgb('f05ba1');

      expect(color.matchesRgb(red: 240, green: 91, blue: 161), isTrue);
      expect(color.matchesRgb(red: 240, green: 91, blue: 160), isFalse);
    });

    test('matches ARGB 32-bit values while ignoring alpha', () {
      final color = TilesetTransparentColor.fromHexRgb('f05ba1');

      expect(color.matchesArgb32(0xFFF05BA1), isTrue);
      expect(color.matchesArgb32(0x00F05BA1), isTrue);
      expect(color.matchesArgb32(0x80F05BA1), isTrue);
      expect(color.matchesArgb32(0xFF0000FF), isFalse);
    });
  });

  group('TilesetTransparentColor equality', () {
    test('uses value equality and stable hashCode', () {
      final a = TilesetTransparentColor.fromHexRgb('f05ba1');
      final b = TilesetTransparentColor.fromHexRgb('#F05BA1');
      final c = TilesetTransparentColor(red: 0, green: 0, blue: 255);

      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(c));
    });
  });
}
```

### Contenu complet — packages/map_core/lib/map_core.dart

```dart
library map_core;

export 'src/models/enums.dart';
export 'src/models/geometry.dart';
export 'src/models/tileset.dart';
export 'src/models/tileset_transparent_color.dart';
export 'src/models/map_data.dart';
export 'src/models/element_collision_profile.dart';
export 'src/models/map_entity_payloads.dart';
export 'src/models/map_entity_editor_visual.dart';
export 'src/models/map_gameplay_zone_payloads.dart';
export 'src/models/map_layer.dart';
export 'src/models/map_metadata.dart';
export 'src/models/path_center_pattern.dart';
export 'src/models/project_manifest.dart';
export 'src/models/save_data.dart';
export 'src/models/game_state.dart';
export 'src/models/pokemon_move.dart';
export 'src/models/pokemon_move_accuracy.dart';
export 'src/models/pokemon_move_effect.dart';
export 'src/models/script_asset.dart';
export 'src/models/script_conditions.dart';
export 'src/models/map_event_definition.dart';
export 'src/models/project_trainer.dart';
export 'src/models/scenario_asset.dart';
export 'src/models/visual_frame_json.dart';
export 'src/models/surface.dart';
export 'src/models/surface_catalog.dart';
export 'src/operations/map_resize.dart';
export 'src/operations/map_paint.dart';
export 'src/operations/map_collision.dart';
export 'src/operations/map_path.dart';
export 'src/operations/map_terrain.dart';
export 'src/operations/map_terrain_autotile.dart';
export 'src/operations/path_center_pattern_resolver.dart';
export 'src/operations/project_path_preset_center_pattern_adapter.dart';
export 'src/operations/tile_visual_frame_timeline.dart';
export 'src/operations/tile_visual_frame_vertical_atlas.dart';
export 'src/operations/path_variant_vertical_atlas_mapping.dart';
export 'src/operations/path_preset_vertical_atlas_builder.dart';
export 'src/operations/terrain_path_variant_vertical_atlas_layout.dart';
export 'src/operations/standard_path_preset_vertical_atlas_builder.dart';
export 'src/operations/standard_water_path_preset_vertical_atlas_builder.dart';
export 'src/operations/standard_lava_path_preset_vertical_atlas_builder.dart';
export 'src/operations/standard_ice_path_preset_vertical_atlas_builder.dart';
export 'src/operations/standard_tall_grass_path_preset_vertical_atlas_builder.dart';
export 'src/operations/standard_surface_preset_builder.dart';
export 'src/operations/surface_catalog_diagnostics.dart';
export 'src/operations/surface_catalog_authoring_diagnostics.dart';
export 'src/operations/surface_catalog_diagnostics_summary.dart';
export 'src/operations/surface_catalog_diagnostics_presentation.dart';
export 'src/operations/surface_atlas_json_codec.dart';
export 'src/operations/surface_animation_frame_json_codec.dart';
export 'src/operations/surface_animation_timeline_json_codec.dart';
export 'src/operations/project_surface_animation_json_codec.dart';
export 'src/operations/surface_variant_animation_ref_json_codec.dart';
export 'src/operations/surface_variant_animation_ref_set_json_codec.dart';
export 'src/operations/project_surface_preset_json_codec.dart';
export 'src/operations/project_surface_catalog_json_codec.dart';
export 'src/operations/project_manifest_surface_catalog_operations.dart';
export 'src/operations/surface_studio_read_model.dart';
export 'src/operations/tall_grass_authoring_view.dart';
export 'src/operations/path_animation_rules.dart';
export 'src/operations/element_collision_mask_codec.dart';
export 'src/collision/pixel_rect.dart';
export 'src/collision/player_collision_conventions_v1.dart';
export 'src/operations/map_layers.dart';
export 'src/operations/surface_layer_placements.dart';
export 'src/operations/surface_to_gameplay_zone_generation_assessment.dart';
export 'src/operations/surface_to_gameplay_zone_generation_plan.dart';
export 'src/operations/surface_variant_role_resolver.dart';
export 'src/operations/map_connections.dart';
export 'src/operations/map_entities.dart';
export 'src/operations/map_events.dart';
export 'src/operations/map_placed_elements.dart';
export 'src/operations/map_placed_element_animation.dart';
export 'src/operations/map_entity_collision_footprint.dart';
export 'src/operations/map_triggers.dart';
export 'src/operations/map_warps.dart';
export 'src/operations/map_gameplay_zones.dart';
export 'src/operations/map_map_metadata.dart';
export 'src/operations/game_state_persistence.dart';
export 'src/operations/tileset_library_tree.dart';
export 'src/operations/dialogue_library_tree.dart';
export 'src/operations/project_dialogue_refs.dart';
export 'src/validation/validators.dart';
export 'src/validation/dialogue_validation.dart';
export 'src/validation/entity_editor_visual_validation.dart';
export 'src/exceptions/map_exceptions.dart';
```

### Diff complet — packages/map_core/lib/map_core.dart

```diff
diff --git a/packages/map_core/lib/map_core.dart b/packages/map_core/lib/map_core.dart
index ca514c2b..25305785 100644
--- a/packages/map_core/lib/map_core.dart
+++ b/packages/map_core/lib/map_core.dart
@@ -3,6 +3,7 @@ library map_core;
 export 'src/models/enums.dart';
 export 'src/models/geometry.dart';
 export 'src/models/tileset.dart';
+export 'src/models/tileset_transparent_color.dart';
 export 'src/models/map_data.dart';
 export 'src/models/element_collision_profile.dart';
 export 'src/models/map_entity_payloads.dart';
```

### Diff complet — packages/map_core/lib/src/models/tileset_transparent_color.dart

```diff
diff --git a/packages/map_core/lib/src/models/tileset_transparent_color.dart b/packages/map_core/lib/src/models/tileset_transparent_color.dart
new file mode 100644
index 00000000..f8cd95bd
--- /dev/null
+++ b/packages/map_core/lib/src/models/tileset_transparent_color.dart
@@ -0,0 +1,100 @@
+/// RGB color configured as transparent for a tileset.
+final class TilesetTransparentColor {
+  factory TilesetTransparentColor({
+    required int red,
+    required int green,
+    required int blue,
+  }) {
+    _validateChannel(red, 'red');
+    _validateChannel(green, 'green');
+    _validateChannel(blue, 'blue');
+    return TilesetTransparentColor._(red: red, green: green, blue: blue);
+  }
+
+  factory TilesetTransparentColor.fromHexRgb(String value) {
+    final hex = value.startsWith('#') ? value.substring(1) : value;
+    if (hex.length != 6 || !_isHexRgb(hex)) {
+      throw ArgumentError.value(
+        value,
+        'value',
+        'TilesetTransparentColor hex RGB must contain exactly '
+            '6 hexadecimal characters.',
+      );
+    }
+
+    return TilesetTransparentColor(
+      red: int.parse(hex.substring(0, 2), radix: 16),
+      green: int.parse(hex.substring(2, 4), radix: 16),
+      blue: int.parse(hex.substring(4, 6), radix: 16),
+    );
+  }
+
+  const TilesetTransparentColor._({
+    required this.red,
+    required this.green,
+    required this.blue,
+  });
+
+  final int red;
+  final int green;
+  final int blue;
+
+  String toHexRgb() {
+    return _toHexChannel(red) + _toHexChannel(green) + _toHexChannel(blue);
+  }
+
+  bool matchesRgb({
+    required int red,
+    required int green,
+    required int blue,
+  }) {
+    return this.red == red && this.green == green && this.blue == blue;
+  }
+
+  bool matchesArgb32(int argb) {
+    final rgb = argb & 0x00ffffff;
+    final red = (rgb >> 16) & 0xff;
+    final green = (rgb >> 8) & 0xff;
+    final blue = rgb & 0xff;
+    return matchesRgb(red: red, green: green, blue: blue);
+  }
+
+  @override
+  bool operator ==(Object other) {
+    return identical(this, other) ||
+        other is TilesetTransparentColor &&
+            red == other.red &&
+            green == other.green &&
+            blue == other.blue;
+  }
+
+  @override
+  int get hashCode => Object.hash(red, green, blue);
+}
+
+void _validateChannel(int value, String name) {
+  if (value < 0 || value > 255) {
+    throw ArgumentError.value(
+      value,
+      name,
+      'TilesetTransparentColor $name must be between 0 and 255.',
+    );
+  }
+}
+
+bool _isHexRgb(String value) {
+  for (var index = 0; index < value.length; index += 1) {
+    final codeUnit = value.codeUnitAt(index);
+    final isDigit = codeUnit >= 0x30 && codeUnit <= 0x39;
+    final isUppercaseHex = codeUnit >= 0x41 && codeUnit <= 0x46;
+    final isLowercaseHex = codeUnit >= 0x61 && codeUnit <= 0x66;
+    if (!isDigit && !isUppercaseHex && !isLowercaseHex) {
+      return false;
+    }
+  }
+  return true;
+}
+
+String _toHexChannel(int value) {
+  return value.toRadixString(16).padLeft(2, '0');
+}
```

### Diff complet — packages/map_core/test/tileset_transparent_color_test.dart

```diff
diff --git a/packages/map_core/test/tileset_transparent_color_test.dart b/packages/map_core/test/tileset_transparent_color_test.dart
new file mode 100644
index 00000000..8bf1ac92
--- /dev/null
+++ b/packages/map_core/test/tileset_transparent_color_test.dart
@@ -0,0 +1,113 @@
+import 'package:map_core/map_core.dart';
+import 'package:test/test.dart';
+
+void main() {
+  group('TilesetTransparentColor construction', () {
+    test('accepts RGB components in the 0..255 range', () {
+      final color = TilesetTransparentColor(red: 240, green: 91, blue: 161);
+
+      expect(color.red, 240);
+      expect(color.green, 91);
+      expect(color.blue, 161);
+    });
+
+    test('rejects RGB components outside the 0..255 range', () {
+      expect(
+        () => TilesetTransparentColor(red: -1, green: 91, blue: 161),
+        throwsA(isA<ArgumentError>()),
+      );
+      expect(
+        () => TilesetTransparentColor(red: 256, green: 91, blue: 161),
+        throwsA(isA<ArgumentError>()),
+      );
+      expect(
+        () => TilesetTransparentColor(red: 240, green: -1, blue: 161),
+        throwsA(isA<ArgumentError>()),
+      );
+      expect(
+        () => TilesetTransparentColor(red: 240, green: 256, blue: 161),
+        throwsA(isA<ArgumentError>()),
+      );
+      expect(
+        () => TilesetTransparentColor(red: 240, green: 91, blue: -1),
+        throwsA(isA<ArgumentError>()),
+      );
+      expect(
+        () => TilesetTransparentColor(red: 240, green: 91, blue: 256),
+        throwsA(isA<ArgumentError>()),
+      );
+    });
+  });
+
+  group('TilesetTransparentColor hex parsing', () {
+    test('accepts lowercase, uppercase, and optional # RGB values', () {
+      for (final value in ['f05ba1', 'F05BA1', '#f05ba1', '#F05BA1']) {
+        final color = TilesetTransparentColor.fromHexRgb(value);
+
+        expect(color.red, 240);
+        expect(color.green, 91);
+        expect(color.blue, 161);
+      }
+    });
+
+    test('returns canonical lowercase RGB without # and with padding', () {
+      expect(
+        TilesetTransparentColor.fromHexRgb('#F05BA1').toHexRgb(),
+        'f05ba1',
+      );
+      expect(
+        TilesetTransparentColor(red: 0, green: 0, blue: 255).toHexRgb(),
+        '0000ff',
+      );
+    });
+
+    test('rejects invalid hex RGB strings', () {
+      for (final value in [
+        '',
+        '#',
+        'f05ba',
+        'f05ba11',
+        'gggggg',
+        '#gggggg',
+        'f05ba1ff',
+        '0xF05BA1',
+      ]) {
+        expect(
+          () => TilesetTransparentColor.fromHexRgb(value),
+          throwsA(isA<ArgumentError>()),
+          reason: value,
+        );
+      }
+    });
+  });
+
+  group('TilesetTransparentColor matching', () {
+    test('matches RGB components exactly', () {
+      final color = TilesetTransparentColor.fromHexRgb('f05ba1');
+
+      expect(color.matchesRgb(red: 240, green: 91, blue: 161), isTrue);
+      expect(color.matchesRgb(red: 240, green: 91, blue: 160), isFalse);
+    });
+
+    test('matches ARGB 32-bit values while ignoring alpha', () {
+      final color = TilesetTransparentColor.fromHexRgb('f05ba1');
+
+      expect(color.matchesArgb32(0xFFF05BA1), isTrue);
+      expect(color.matchesArgb32(0x00F05BA1), isTrue);
+      expect(color.matchesArgb32(0x80F05BA1), isTrue);
+      expect(color.matchesArgb32(0xFF0000FF), isFalse);
+    });
+  });
+
+  group('TilesetTransparentColor equality', () {
+    test('uses value equality and stable hashCode', () {
+      final a = TilesetTransparentColor.fromHexRgb('f05ba1');
+      final b = TilesetTransparentColor.fromHexRgb('#F05BA1');
+      final c = TilesetTransparentColor(red: 0, green: 0, blue: 255);
+
+      expect(a, b);
+      expect(a.hashCode, b.hashCode);
+      expect(a, isNot(c));
+    });
+  });
+}
```

## Auto-review

- Ai-je gardé le modèle pur ? Oui, fichier modèle sans dépendance externe.
- Ai-je évité dart:ui / Flutter ? Oui.
- Ai-je évité PNG processing ? Oui.
- Ai-je évité ProjectManifest ? Oui.
- Ai-je évité ProjectPathPreset ? Oui.
- Ai-je évité JSON/generated/build_runner ? Oui.
- Ai-je évité runtime/gameplay/battle ? Oui.
- Ai-je évité le hardcode universel de `f05ba1` ? Oui, `f05ba1` est seulement une valeur de test acceptée comme n'importe quel RGB valide.

## Critique du prompt

- Ambiguïté mineure : `matchesArgb32` ne précise pas si les entiers hors plage 32 bits doivent être rejetés. Décision V0 : lire les 24 bits RGB bas et ignorer le reste, conformément au matching alpha-agnostic.
- Choix de nom : le nom demandé `TilesetTransparentColor` a été conservé.
- Point à valider avant le prochain lot : choisir si l'application de cette couleur doit vivre côté editor avec un processeur PNG, ou être directement intégrée à la première preview statique.
