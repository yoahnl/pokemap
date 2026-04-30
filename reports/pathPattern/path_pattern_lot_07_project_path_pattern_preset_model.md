# Lot PathPattern-7 — ProjectPathPatternPreset Model V0

## 1. Verdict

Accepté.

Le lot ajoute un modèle projet non persistant :

```text
ProjectPathPatternPreset =
  basePathPresetId
  + centerPattern
  + transparentColor optionnelle
  + metadata légère
```

Le modèle reste non branché : pas de `ProjectManifest`, pas de JSON, pas de codec, pas de génération, pas d'UI, pas de runtime, pas de gameplay.

## 2. Audit initial

Commandes initiales :

```bash
pwd
git status --short --untracked-files=all
git diff --stat
rg -n "ProjectPathPatternPreset|PathCenterPattern|TilesetTransparentColor|ProjectPathPreset|PathSurfaceKind|basePathPreset|pathPattern|path pattern|ProjectSurfacePreset|ProjectManifest|pathPresets" packages/map_core/lib packages/map_core/test packages/map_editor/lib packages/map_editor/test
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
ctx CLI absent: command -v ctx a retourné un code 1.
MCP context-mode disponible.
ctx_stats: 1.4M tokens saved · 83.0% reduction · 22h 56m · 178 calls · v1.0.103.
```

AGENTS additionnels :

```text
Aucun AGENTS.md plus profond trouvé sous packages/.
```

Réponses d'audit :

1. `PathCenterPattern` et `PathCenterPatternCell` vivent dans `packages/map_core/lib/src/models/path_center_pattern.dart`.
2. `TilesetTransparentColor` vit dans `packages/map_core/lib/src/models/tileset_transparent_color.dart`.
3. `ProjectPathPreset` est défini dans `packages/map_core/lib/src/models/project_manifest.dart` avec `id`, `name`, `surfaceKind`, `categoryId`, `tilesetId`, `variants`, `sortOrder`. Ses mappings sont des `PathPresetVariantMapping` avec `variant` et `frames`.
4. `ProjectPathPatternPreset` référence `ProjectPathPreset` par id pour éviter d'embarquer un modèle legacy complet, éviter la duplication des bords/coins/jonctions, et garder la future validation d'existence au niveau manifest/diagnostics.
5. Le nouveau modèle est placé dans `packages/map_core/lib/src/models/project_path_pattern_preset.dart`.
6. `PathSurfaceKind` n'est pas inclus en V0 : il reste porté par le `ProjectPathPreset` legacy référencé.
7. `defaultTilesetId` n'est pas inclus en V0 : `ProjectPathPreset.tilesetId` reste la source du tileset global et les frames peuvent déjà porter des overrides.
8. Tests relancés : test ciblé Lot 7, régressions PathPattern core Lots 0 à 4, régressions preview editor Lots 4-bis à 6, analyse ciblée et `map_core` complet.

## 3. Fichiers créés / modifiés / supprimés

Créés :

```text
packages/map_core/lib/src/models/project_path_pattern_preset.dart
packages/map_core/test/project_path_pattern_preset_test.dart
reports/pathPattern/path_pattern_lot_07_project_path_pattern_preset_model.md
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

```dart
final class ProjectPathPatternPreset {
  factory ProjectPathPatternPreset({
    required String id,
    required String name,
    required String basePathPresetId,
    required PathCenterPattern centerPattern,
    TilesetTransparentColor? transparentColor,
    String? categoryId,
    int sortOrder = 0,
  });

  final String id;
  final String name;
  final String basePathPresetId;
  final PathCenterPattern centerPattern;
  final TilesetTransparentColor? transparentColor;
  final String? categoryId;
  final int sortOrder;

  bool get hasTransparentColor;
  bool get usesSingleCellCenter;
  bool get usesMultiCellCenter;
}
```

Le type est exporté par `packages/map_core/lib/map_core.dart`.

## 5. Décision basePathPresetId

`basePathPresetId` est une référence vers un `ProjectPathPreset` legacy existant.

Décision V0 :

```text
- stocker seulement l'id ;
- ne pas résoudre l'id ;
- ne pas vérifier l'existence du preset ;
- ne pas embarquer ProjectPathPreset ;
- laisser la validation d'existence aux futurs diagnostics/manifest operations.
```

## 6. Décision exclusion surfaceKind / defaultTilesetId

`surfaceKind` est exclu car `ProjectPathPreset.surfaceKind` existe déjà. Le dupliquer créerait deux sources de vérité.

`defaultTilesetId` / `tilesetId` est exclu car `ProjectPathPreset.tilesetId` reste le tileset global. `PathCenterPattern` contient des `TilesetVisualFrame`, et ces frames peuvent porter un `tilesetId` override. Le futur presenter/renderer devra recevoir le tileset effectif en amont.

## 7. Décision transparentColor optionnelle

`transparentColor` est optionnelle :

```text
null autorisé
pas de couleur par défaut
pas de hardcode f05ba1
pas d'application de transparence dans ce modèle
```

## 8. Validations

Le constructeur rejette :

```text
id.trim().isEmpty
name.trim().isEmpty
basePathPresetId.trim().isEmpty
```

Les valeurs non blank sont stockées telles qu'elles ont été fournies. Exemple testé :

```text
id = " water " -> stocké " water "
name = " Water " -> stocké " Water "
basePathPresetId = " legacy-water " -> stocké " legacy-water "
```

`categoryId` reste souple en V0.

`sortOrder` accepte n'importe quel `int` et vaut `0` par défaut.

## 9. Helpers

Helpers ajoutés :

```dart
bool get hasTransparentColor => transparentColor != null;
bool get usesSingleCellCenter => centerPattern.isSingleCell;
bool get usesMultiCellCenter => centerPattern.isMultiCell;
```

Ils sont utiles aux futurs read models et à la future UI, sans ajouter de logique métier complexe.

## 10. Tests lancés

### Test rouge TDD initial

Commande :

```bash
cd packages/map_core && dart test test/project_path_pattern_preset_test.dart --reporter expanded --no-color
```

Sortie :

```text
00:00 +0: loading test/project_path_pattern_preset_test.dart
00:00 +0 -1: loading test/project_path_pattern_preset_test.dart [E]
  Failed to load "test/project_path_pattern_preset_test.dart":
  test/project_path_pattern_preset_test.dart:9:22: Error: Method not found: 'ProjectPathPatternPreset'.
        final preset = ProjectPathPatternPreset(
                       ^^^^^^^^^^^^^^^^^^^^^^^^
  test/project_path_pattern_preset_test.dart:32:22: Error: Method not found: 'ProjectPathPatternPreset'.
        final preset = ProjectPathPatternPreset(
                       ^^^^^^^^^^^^^^^^^^^^^^^^
  test/project_path_pattern_preset_test.dart:58:15: Error: Method not found: 'ProjectPathPatternPreset'.
          () => ProjectPathPatternPreset(
                ^^^^^^^^^^^^^^^^^^^^^^^^
  test/project_path_pattern_preset_test.dart:67:15: Error: Method not found: 'ProjectPathPatternPreset'.
          () => ProjectPathPatternPreset(
                ^^^^^^^^^^^^^^^^^^^^^^^^
  test/project_path_pattern_preset_test.dart:76:15: Error: Method not found: 'ProjectPathPatternPreset'.
          () => ProjectPathPatternPreset(
                ^^^^^^^^^^^^^^^^^^^^^^^^
  test/project_path_pattern_preset_test.dart:85:15: Error: Method not found: 'ProjectPathPatternPreset'.
          () => ProjectPathPatternPreset(
                ^^^^^^^^^^^^^^^^^^^^^^^^
  test/project_path_pattern_preset_test.dart:94:15: Error: Method not found: 'ProjectPathPatternPreset'.
          () => ProjectPathPatternPreset(
                ^^^^^^^^^^^^^^^^^^^^^^^^
  test/project_path_pattern_preset_test.dart:103:15: Error: Method not found: 'ProjectPathPatternPreset'.
          () => ProjectPathPatternPreset(
                ^^^^^^^^^^^^^^^^^^^^^^^^
  test/project_path_pattern_preset_test.dart:114:22: Error: Method not found: 'ProjectPathPatternPreset'.
        final preset = ProjectPathPatternPreset(
                       ^^^^^^^^^^^^^^^^^^^^^^^^
  test/project_path_pattern_preset_test.dart:127:20: Error: Method not found: 'ProjectPathPatternPreset'.
        final base = ProjectPathPatternPreset(
                     ^^^^^^^^^^^^^^^^^^^^^^^^
00:00 +0 -1: Some tests failed.
```

### Test ciblé Lot 7

Commande :

```bash
cd packages/map_core && dart test test/project_path_pattern_preset_test.dart --reporter expanded --no-color
```

Sortie :

```text
00:00 +0: loading test/project_path_pattern_preset_test.dart
00:00 +0: ProjectPathPatternPreset creates a minimal preset with defaults
00:00 +1: ProjectPathPatternPreset creates a complete preset with a 2x2 center pattern
00:00 +2: ProjectPathPatternPreset rejects blank identity fields
00:00 +3: ProjectPathPatternPreset validates with trim but stores original strings
00:00 +4: ProjectPathPatternPreset supports value equality and stable hashCode
00:00 +5: All tests passed!
```

### Régressions PathPattern core

Commande :

```bash
cd packages/map_core && dart test test/tileset_transparent_color_test.dart --reporter expanded --no-color
```

Sortie :

```text
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

Commande :

```bash
cd packages/map_core && dart test test/project_path_preset_center_pattern_adapter_test.dart --reporter expanded --no-color
```

Sortie :

```text
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

Commande :

```bash
cd packages/map_core && dart test test/path_center_pattern_resolver_test.dart --reporter expanded --no-color
```

Sortie :

```text
00:00 +0: resolvePathCenterPatternCell 1x1 always resolves to the single local cell
00:00 +1: resolvePathCenterPatternCell 2x2 uses absolute map coordinates modulo pattern size
00:00 +2: resolvePathCenterPatternCell rectangular 3x2 does not assume square patterns
00:00 +3: resolvePathCenterPatternCell invalid coordinates rejects negative map coordinates
00:00 +4: PathCenterPatternCellResolution keeps map coordinates, local coordinates, and selected cell
00:00 +5: PathCenterPatternCellResolution uses value equality and stable hashCode
00:00 +6: All tests passed!
```

Commande :

```bash
cd packages/map_core && dart test test/path_center_pattern_test.dart --reporter expanded --no-color
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

Commande :

```bash
cd packages/map_core && dart test test/map_terrain_autotile_characterization_test.dart --reporter expanded --no-color
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

### Régressions preview map_editor

Commande :

```bash
cd packages/map_editor && flutter test test/path_pattern/path_center_pattern_animated_preview_renderer_test.dart --no-pub --reporter expanded
```

Sortie :

```text
Waiting for another flutter command to release the startup lock...
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_center_pattern_animated_preview_renderer_test.dart
00:00 +0: renderPathCenterPatternAnimatedPreviewPng keeps a single-frame 1x1 pattern stable across elapsed time
00:00 +1: renderPathCenterPatternAnimatedPreviewPng loops two explicit-duration frames for a 1x1 pattern
00:00 +2: renderPathCenterPatternAnimatedPreviewPng resolves independent 2x2 cell timelines
00:00 +3: renderPathCenterPatternAnimatedPreviewPng uses map_core default duration for null frame durations
00:00 +4: renderPathCenterPatternAnimatedPreviewPng rejects non-positive frame durations
00:00 +5: renderPathCenterPatternAnimatedPreviewPng applies optional transparentColor before composing preview
00:00 +6: renderPathCenterPatternAnimatedPreviewPng keeps transparent-color-looking pixels opaque when color is null
00:00 +7: renderPathCenterPatternAnimatedPreviewPng rejects source rects outside the tileset image
00:00 +8: renderPathCenterPatternAnimatedPreviewPng rejects non-1x1 source rects in V0
00:00 +9: renderPathCenterPatternAnimatedPreviewPng rejects invalid PNG bytes
00:00 +10: renderPathCenterPatternAnimatedPreviewPng rejects negative elapsedMs and non-positive tile dimensions
00:00 +11: All tests passed!
```

Commande :

```bash
cd packages/map_editor && flutter test test/path_pattern/path_center_pattern_static_preview_renderer_test.dart --no-pub --reporter expanded
```

Sortie :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_center_pattern_static_preview_renderer_test.dart
00:00 +0: renderPathCenterPatternStaticPreviewPng renders a 1x1 preview from the first frame source tile
00:00 +1: renderPathCenterPatternStaticPreviewPng renders a 2x2 preview in local cell positions
00:00 +2: renderPathCenterPatternStaticPreviewPng applies optional transparentColor before composing preview
00:00 +3: renderPathCenterPatternStaticPreviewPng keeps transparent-color-looking pixels opaque when color is null
00:00 +4: renderPathCenterPatternStaticPreviewPng rejects source rects outside the tileset image
00:00 +5: renderPathCenterPatternStaticPreviewPng rejects non-1x1 source rects in V0
00:00 +6: renderPathCenterPatternStaticPreviewPng rejects invalid PNG bytes
00:00 +7: renderPathCenterPatternStaticPreviewPng rejects non-positive tile dimensions
00:00 +8: All tests passed!
```

Commande :

```bash
cd packages/map_editor && flutter test test/path_pattern/tileset_transparent_color_processor_test.dart --no-pub --reporter expanded
```

Sortie :

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

### Test complet map_core

Commande :

```bash
cd packages/map_core && dart test --no-color --reporter expanded
```

Ligne finale exacte :

```text
00:01 +1074: All tests passed!
```

Suite complète `map_editor` :

```text
Non lancée. Ce lot modifie uniquement `map_core`; les régressions preview ciblées côté `map_editor` ont été lancées.
```

## 11. Analyze

Commande :

```bash
cd packages/map_core && dart analyze lib/src/models/project_path_pattern_preset.dart test/project_path_pattern_preset_test.dart
```

Sortie :

```text
Analyzing project_path_pattern_preset.dart, project_path_pattern_preset_test.dart...
No issues found!
```

## 12. Non-objectifs confirmés

Confirmé :

```text
pas de Path Studio UI
pas de nouvelle UI
pas de widget Flutter
pas de preview nouvelle
pas de canvas rendering
pas de painter integration
pas de runtime
pas de gameplay
pas de MapGameplayZone
pas de ProjectManifest
pas de JSON
pas de codec
pas de generated files
pas de build_runner
pas de Freezed
pas de modification ProjectPathPreset
pas de modification TerrainPathVariant
pas de modification PathLayer
pas de modification map_runtime
pas de modification map_gameplay
pas de modification map_battle
pas de TSX
pas de TMX
pas de Mistral
pas de PixelLab
pas de save flow
pas de modification des images sources
pas de création de fichiers PNG sur disque
pas de manifest integration
pas de hautes herbes dans ce lot
```

## 13. Limites restantes

Limites V0 :

```text
- basePathPresetId n'est pas résolu ;
- l'existence du ProjectPathPreset référencé n'est pas vérifiée ;
- surfaceKind et tilesetId restent lus indirectement via le preset legacy ;
- aucun JSON externe n'existe encore ;
- ProjectManifest ne contient pas encore de liste PathPattern ;
- aucun read model editor n'expose ce modèle ;
- aucune UI ne permet encore de créer ou sauvegarder ce preset.
```

## 14. Git status final

Commande :

```bash
git status --short --untracked-files=all
```

Sortie :

```text
 M packages/map_core/lib/map_core.dart
?? packages/map_core/lib/src/models/project_path_pattern_preset.dart
?? packages/map_core/test/project_path_pattern_preset_test.dart
?? reports/pathPattern/path_pattern_lot_07_project_path_pattern_preset_model.md
```

## 15. Prochain lot recommandé

Prochain lot recommandé :

```text
PathPattern-8 — ProjectPathPatternPreset JSON Codec V0
```

Une option plus prudente serait un mini-lot de décision JSON/manifest avant le codec, mais le modèle V0 est maintenant suffisamment fermé pour écrire un codec externe sans modifier `ProjectManifest`.

## Evidence Pack

### Contenu complet — packages/map_core/lib/src/models/project_path_pattern_preset.dart

```dart
import 'path_center_pattern.dart';
import 'tileset_transparent_color.dart';

/// Project-level path preset extension whose center can be a local pattern.
final class ProjectPathPatternPreset {
  factory ProjectPathPatternPreset({
    required String id,
    required String name,
    required String basePathPresetId,
    required PathCenterPattern centerPattern,
    TilesetTransparentColor? transparentColor,
    String? categoryId,
    int sortOrder = 0,
  }) {
    _validateNonBlank(id, 'id');
    _validateNonBlank(name, 'name');
    _validateNonBlank(basePathPresetId, 'basePathPresetId');

    return ProjectPathPatternPreset._(
      id: id,
      name: name,
      basePathPresetId: basePathPresetId,
      centerPattern: centerPattern,
      transparentColor: transparentColor,
      categoryId: categoryId,
      sortOrder: sortOrder,
    );
  }

  const ProjectPathPatternPreset._({
    required this.id,
    required this.name,
    required this.basePathPresetId,
    required this.centerPattern,
    required this.transparentColor,
    required this.categoryId,
    required this.sortOrder,
  });

  final String id;
  final String name;
  final String basePathPresetId;
  final PathCenterPattern centerPattern;
  final TilesetTransparentColor? transparentColor;
  final String? categoryId;
  final int sortOrder;

  bool get hasTransparentColor => transparentColor != null;

  bool get usesSingleCellCenter => centerPattern.isSingleCell;

  bool get usesMultiCellCenter => centerPattern.isMultiCell;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ProjectPathPatternPreset &&
            id == other.id &&
            name == other.name &&
            basePathPresetId == other.basePathPresetId &&
            centerPattern == other.centerPattern &&
            transparentColor == other.transparentColor &&
            categoryId == other.categoryId &&
            sortOrder == other.sortOrder;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      name,
      basePathPresetId,
      centerPattern,
      transparentColor,
      categoryId,
      sortOrder,
    );
  }
}

void _validateNonBlank(String value, String name) {
  if (value.trim().isEmpty) {
    throw ArgumentError.value(
      value,
      name,
      'ProjectPathPatternPreset $name must not be blank.',
    );
  }
}
```

### Contenu complet — packages/map_core/test/project_path_pattern_preset_test.dart

```dart
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectPathPatternPreset', () {
    test('creates a minimal preset with defaults', () {
      final centerPattern = _singleCellCenterPattern();

      final preset = ProjectPathPatternPreset(
        id: 'water-1x1',
        name: 'Water 1x1',
        basePathPresetId: 'legacy-water',
        centerPattern: centerPattern,
      );

      expect(preset.id, 'water-1x1');
      expect(preset.name, 'Water 1x1');
      expect(preset.basePathPresetId, 'legacy-water');
      expect(preset.centerPattern, centerPattern);
      expect(preset.transparentColor, isNull);
      expect(preset.categoryId, isNull);
      expect(preset.sortOrder, 0);
      expect(preset.hasTransparentColor, isFalse);
      expect(preset.usesSingleCellCenter, isTrue);
      expect(preset.usesMultiCellCenter, isFalse);
    });

    test('creates a complete preset with a 2x2 center pattern', () {
      final centerPattern = _twoByTwoCenterPattern();
      final transparentColor = TilesetTransparentColor.fromHexRgb('f05ba1');

      final preset = ProjectPathPatternPreset(
        id: 'water-sea-2x2',
        name: 'Mer 2x2',
        basePathPresetId: 'legacy-water',
        centerPattern: centerPattern,
        transparentColor: transparentColor,
        categoryId: 'water',
        sortOrder: 12,
      );

      expect(preset.id, 'water-sea-2x2');
      expect(preset.name, 'Mer 2x2');
      expect(preset.basePathPresetId, 'legacy-water');
      expect(preset.centerPattern, centerPattern);
      expect(preset.transparentColor, transparentColor);
      expect(preset.categoryId, 'water');
      expect(preset.sortOrder, 12);
      expect(preset.hasTransparentColor, isTrue);
      expect(preset.usesSingleCellCenter, isFalse);
      expect(preset.usesMultiCellCenter, isTrue);
    });

    test('rejects blank identity fields', () {
      final centerPattern = _singleCellCenterPattern();

      expect(
        () => ProjectPathPatternPreset(
          id: '',
          name: 'Water',
          basePathPresetId: 'legacy-water',
          centerPattern: centerPattern,
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => ProjectPathPatternPreset(
          id: '   ',
          name: 'Water',
          basePathPresetId: 'legacy-water',
          centerPattern: centerPattern,
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => ProjectPathPatternPreset(
          id: 'water',
          name: '',
          basePathPresetId: 'legacy-water',
          centerPattern: centerPattern,
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => ProjectPathPatternPreset(
          id: 'water',
          name: '   ',
          basePathPresetId: 'legacy-water',
          centerPattern: centerPattern,
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => ProjectPathPatternPreset(
          id: 'water',
          name: 'Water',
          basePathPresetId: '',
          centerPattern: centerPattern,
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => ProjectPathPatternPreset(
          id: 'water',
          name: 'Water',
          basePathPresetId: '   ',
          centerPattern: centerPattern,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('validates with trim but stores original strings', () {
      final preset = ProjectPathPatternPreset(
        id: ' water ',
        name: ' Water ',
        basePathPresetId: ' legacy-water ',
        centerPattern: _singleCellCenterPattern(),
      );

      expect(preset.id, ' water ');
      expect(preset.name, ' Water ');
      expect(preset.basePathPresetId, ' legacy-water ');
    });

    test('supports value equality and stable hashCode', () {
      final base = ProjectPathPatternPreset(
        id: 'water',
        name: 'Water',
        basePathPresetId: 'legacy-water',
        centerPattern: _singleCellCenterPattern(),
        transparentColor: TilesetTransparentColor.fromHexRgb('f05ba1'),
        categoryId: 'water',
        sortOrder: 1,
      );

      expect(
        base,
        ProjectPathPatternPreset(
          id: 'water',
          name: 'Water',
          basePathPresetId: 'legacy-water',
          centerPattern: _singleCellCenterPattern(),
          transparentColor: TilesetTransparentColor.fromHexRgb('#F05BA1'),
          categoryId: 'water',
          sortOrder: 1,
        ),
      );
      expect(
        base.hashCode,
        ProjectPathPatternPreset(
          id: 'water',
          name: 'Water',
          basePathPresetId: 'legacy-water',
          centerPattern: _singleCellCenterPattern(),
          transparentColor: TilesetTransparentColor.fromHexRgb('f05ba1'),
          categoryId: 'water',
          sortOrder: 1,
        ).hashCode,
      );
      expect(
        base,
        isNot(
          ProjectPathPatternPreset(
            id: 'water-2',
            name: 'Water',
            basePathPresetId: 'legacy-water',
            centerPattern: _singleCellCenterPattern(),
            transparentColor: TilesetTransparentColor.fromHexRgb('f05ba1'),
            categoryId: 'water',
            sortOrder: 1,
          ),
        ),
      );
      expect(
        base,
        isNot(
          ProjectPathPatternPreset(
            id: 'water',
            name: 'Water 2',
            basePathPresetId: 'legacy-water',
            centerPattern: _singleCellCenterPattern(),
            transparentColor: TilesetTransparentColor.fromHexRgb('f05ba1'),
            categoryId: 'water',
            sortOrder: 1,
          ),
        ),
      );
      expect(
        base,
        isNot(
          ProjectPathPatternPreset(
            id: 'water',
            name: 'Water',
            basePathPresetId: 'legacy-water-2',
            centerPattern: _singleCellCenterPattern(),
            transparentColor: TilesetTransparentColor.fromHexRgb('f05ba1'),
            categoryId: 'water',
            sortOrder: 1,
          ),
        ),
      );
      expect(
        base,
        isNot(
          ProjectPathPatternPreset(
            id: 'water',
            name: 'Water',
            basePathPresetId: 'legacy-water',
            centerPattern: _twoByTwoCenterPattern(),
            transparentColor: TilesetTransparentColor.fromHexRgb('f05ba1'),
            categoryId: 'water',
            sortOrder: 1,
          ),
        ),
      );
      expect(
        base,
        isNot(
          ProjectPathPatternPreset(
            id: 'water',
            name: 'Water',
            basePathPresetId: 'legacy-water',
            centerPattern: _singleCellCenterPattern(),
            transparentColor: TilesetTransparentColor.fromHexRgb('0000ff'),
            categoryId: 'water',
            sortOrder: 1,
          ),
        ),
      );
      expect(
        base,
        isNot(
          ProjectPathPatternPreset(
            id: 'water',
            name: 'Water',
            basePathPresetId: 'legacy-water',
            centerPattern: _singleCellCenterPattern(),
            transparentColor: TilesetTransparentColor.fromHexRgb('f05ba1'),
            categoryId: 'water-2',
            sortOrder: 1,
          ),
        ),
      );
      expect(
        base,
        isNot(
          ProjectPathPatternPreset(
            id: 'water',
            name: 'Water',
            basePathPresetId: 'legacy-water',
            centerPattern: _singleCellCenterPattern(),
            transparentColor: TilesetTransparentColor.fromHexRgb('f05ba1'),
            categoryId: 'water',
            sortOrder: 2,
          ),
        ),
      );
    });
  });
}

PathCenterPattern _singleCellCenterPattern() {
  return PathCenterPattern(
    size: PathCenterPatternSize(width: 1, height: 1),
    cells: [
      PathCenterPatternCell(
        localX: 0,
        localY: 0,
        frames: [_frame(0, 0)],
      ),
    ],
  );
}

PathCenterPattern _twoByTwoCenterPattern() {
  return PathCenterPattern(
    size: PathCenterPatternSize(width: 2, height: 2),
    cells: [
      PathCenterPatternCell(localX: 0, localY: 0, frames: [_frame(0, 0)]),
      PathCenterPatternCell(localX: 1, localY: 0, frames: [_frame(1, 0)]),
      PathCenterPatternCell(localX: 0, localY: 1, frames: [_frame(0, 1)]),
      PathCenterPatternCell(localX: 1, localY: 1, frames: [_frame(1, 1)]),
    ],
  );
}

TilesetVisualFrame _frame(int x, int y) {
  return TilesetVisualFrame(source: TilesetSourceRect(x: x, y: y));
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
export 'src/models/project_path_pattern_preset.dart';
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
export 'src/operations/project_json_migrations.dart';
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

### Diffs complets

`packages/map_core/lib/map_core.dart`

```diff
diff --git a/packages/map_core/lib/map_core.dart b/packages/map_core/lib/map_core.dart
index bb50f991..734686d2 100644
--- a/packages/map_core/lib/map_core.dart
+++ b/packages/map_core/lib/map_core.dart
@@ -12,6 +12,7 @@ export 'src/models/map_gameplay_zone_payloads.dart';
 export 'src/models/map_layer.dart';
 export 'src/models/map_metadata.dart';
 export 'src/models/path_center_pattern.dart';
+export 'src/models/project_path_pattern_preset.dart';
 export 'src/models/project_manifest.dart';
 export 'src/models/save_data.dart';
 export 'src/models/game_state.dart';
```

`packages/map_core/lib/src/models/project_path_pattern_preset.dart`

```diff
diff --git a/packages/map_core/lib/src/models/project_path_pattern_preset.dart b/packages/map_core/lib/src/models/project_path_pattern_preset.dart
new file mode 100644
index 00000000..035e1cc7
--- /dev/null
+++ b/packages/map_core/lib/src/models/project_path_pattern_preset.dart
@@ -0,0 +1,89 @@
+import 'path_center_pattern.dart';
+import 'tileset_transparent_color.dart';
+
+/// Project-level path preset extension whose center can be a local pattern.
+final class ProjectPathPatternPreset {
+  factory ProjectPathPatternPreset({
+    required String id,
+    required String name,
+    required String basePathPresetId,
+    required PathCenterPattern centerPattern,
+    TilesetTransparentColor? transparentColor,
+    String? categoryId,
+    int sortOrder = 0,
+  }) {
+    _validateNonBlank(id, 'id');
+    _validateNonBlank(name, 'name');
+    _validateNonBlank(basePathPresetId, 'basePathPresetId');
+
+    return ProjectPathPatternPreset._(
+      id: id,
+      name: name,
+      basePathPresetId: basePathPresetId,
+      centerPattern: centerPattern,
+      transparentColor: transparentColor,
+      categoryId: categoryId,
+      sortOrder: sortOrder,
+    );
+  }
+
+  const ProjectPathPatternPreset._({
+    required this.id,
+    required this.name,
+    required this.basePathPresetId,
+    required this.centerPattern,
+    required this.transparentColor,
+    required this.categoryId,
+    required this.sortOrder,
+  });
+
+  final String id;
+  final String name;
+  final String basePathPresetId;
+  final PathCenterPattern centerPattern;
+  final TilesetTransparentColor? transparentColor;
+  final String? categoryId;
+  final int sortOrder;
+
+  bool get hasTransparentColor => transparentColor != null;
+
+  bool get usesSingleCellCenter => centerPattern.isSingleCell;
+
+  bool get usesMultiCellCenter => centerPattern.isMultiCell;
+
+  @override
+  bool operator ==(Object other) {
+    return identical(this, other) ||
+        other is ProjectPathPatternPreset &&
+            id == other.id &&
+            name == other.name &&
+            basePathPresetId == other.basePathPresetId &&
+            centerPattern == other.centerPattern &&
+            transparentColor == other.transparentColor &&
+            categoryId == other.categoryId &&
+            sortOrder == other.sortOrder;
+  }
+
+  @override
+  int get hashCode {
+    return Object.hash(
+      id,
+      name,
+      basePathPresetId,
+      centerPattern,
+      transparentColor,
+      categoryId,
+      sortOrder,
+    );
+  }
+}
+
+void _validateNonBlank(String value, String name) {
+  if (value.trim().isEmpty) {
+    throw ArgumentError.value(
+      value,
+      name,
+      'ProjectPathPatternPreset $name must not be blank.',
+    );
+  }
+}
```

Le diff complet de `packages/map_core/test/project_path_pattern_preset_test.dart` correspond au contenu complet affiché ci-dessus, avec création depuis `/dev/null`.

## No accidental coupling

Commande :

```bash
cd packages/map_core && rg -n "ProjectManifest|ProjectPathPreset\\b|toJson|fromJson|freezed|Freezed|map_runtime|map_gameplay|map_battle|PathLayer|TerrainPathVariant|TSX|TMX|Mistral|PixelLab|tall grass|TallGrass" lib/src/models/project_path_pattern_preset.dart test/project_path_pattern_preset_test.dart
```

Sortie :

```text
```

## Auto-review

- Ai-je gardé le modèle non persistant ? Oui.
- Ai-je évité ProjectManifest ? Oui.
- Ai-je évité ProjectPathPreset modification ? Oui.
- Ai-je évité JSON/generated/build_runner ? Oui.
- Ai-je évité Freezed ? Oui.
- Ai-je évité runtime/gameplay/battle ? Oui.
- Ai-je évité UI/canvas ? Oui.
- Ai-je évité TSX/TMX ? Oui.
- Ai-je évité tall grass ? Oui.
- Ai-je justifié basePathPresetId ? Oui.

## Critique du prompt

- Ambiguïté mineure : `categoryId` blank pouvait être accepté ou rejeté selon convention. Décision V0 : laisser souple, comme champ metadata optionnel.
- Choix de noms : les noms proposés ont été conservés.
- Aucun désaccord avec l'exclusion `surfaceKind` / `defaultTilesetId`.
- Décisions à valider avant codec JSON / manifest : forme exacte du JSON externe, encodage du `PathCenterPattern`, stratégie d'évolution si `basePathPresetId` pointe vers un preset supprimé.
