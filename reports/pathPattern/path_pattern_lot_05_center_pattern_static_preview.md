# PathPattern-5 — Path Center Pattern Static Preview V0

## 1. Verdict

Lot accepté côté implémentation.

Le lot ajoute un renderer PNG statique pur côté `map_editor` :

```text
PathCenterPattern + tileset PNG bytes -> preview PNG statique
```

La fonction compose une image de destination en mémoire, utilise uniquement la première frame de chaque cellule, applique la transparence optionnelle via le processeur du Lot 4-bis, puis réencode la preview en PNG. Aucun fichier image n’est lu ou écrit.

## 2. Audit initial

### Commandes initiales

```bash
pwd
git status --short --untracked-files=all
git diff --stat
rg -n "PathCenterPattern|TilesetVisualFrame|TilesetSourceRect|applyTilesetTransparentColorToPngBytes|decodePng|encodePng|copyCrop|draw|blit|setPixel|tileWidth|tileHeight|Image.memory|MemoryImage|path_pattern" packages/map_editor/lib packages/map_editor/test packages/map_core/lib packages/map_core/test
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

1. Où vivent `PathCenterPattern` et `PathCenterPatternCell` ?

Dans :

```text
packages/map_core/lib/src/models/path_center_pattern.dart
```

`PathCenterPatternCell` contient `localX`, `localY` et `frames`. `PathCenterPattern` expose `size`, `cells`, `cellAt(localX, localY)` et normalise les cellules en row-major.

2. Où vivent `TilesetVisualFrame` et `TilesetSourceRect` ?

Dans :

```text
packages/map_core/lib/src/models/project_manifest.dart
```

Définition inspectée :

```dart
@freezed
class TilesetSourceRect with _$TilesetSourceRect {
  const factory TilesetSourceRect({
    required int x,
    required int y,
    @Default(1) int width,
    @Default(1) int height,
  }) = _TilesetSourceRect;

  factory TilesetSourceRect.fromJson(Map<String, dynamic> json) =>
      _$TilesetSourceRectFromJson(json);
}

@freezed
class TilesetVisualFrame with _$TilesetVisualFrame {
  @JsonSerializable(explicitToJson: true)
  const factory TilesetVisualFrame({
    @Default('') String tilesetId,
    required TilesetSourceRect source,

    /// Millisecondes d'affichage pour le futur lecteur ; null = statique / défaut moteur.
    int? durationMs,
  }) = _TilesetVisualFrame;

  factory TilesetVisualFrame.fromJson(Map<String, dynamic> json) =>
      _$TilesetVisualFrameFromJson(json);
}
```

3. Quelle est la sémantique actuelle de `TilesetSourceRect` : coordonnées en tuiles ou pixels ?

Coordonnées en tuiles. Les usages existants multiplient `source.x/source.y/source.width/source.height` par la taille de tuile.

Exemples audités :

```text
packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart:1490:    final sourceX = source.x * tw;
packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart:1491:    final sourceY = source.y * th;
packages/map_runtime/lib/src/presentation/flame/placed_element_occlusion_patch_component.dart:123:    final srcLeft = frame.source.x * tw;
packages/map_runtime/lib/src/presentation/flame/placed_element_occlusion_patch_component.dart:124:    final srcTop = frame.source.y * th;
packages/map_editor/lib/src/ui/widgets/element_collision_triple_mask_editor.dart:131:    final srcLeft = widget.source.x * widget.tileWidth;
packages/map_editor/lib/src/ui/widgets/element_collision_triple_mask_editor.dart:132:    final srcTop = widget.source.y * widget.tileHeight;
packages/map_editor/lib/src/ui/widgets/element_collision_triple_mask_editor.dart:560:      source.x * tileWidth.toDouble(),
packages/map_editor/lib/src/ui/widgets/element_collision_triple_mask_editor.dart:561:      source.y * tileHeight.toDouble(),
packages/map_editor/lib/src/ui/widgets/element_collision_triple_mask_editor.dart:562:      source.width * tileWidth.toDouble(),
```

Décision du lot : le renderer convertit donc la source en pixels avec :

```text
sourcePxX = source.x * tileWidthPx
sourcePxY = source.y * tileHeightPx
sourcePxWidth = source.width * tileWidthPx
sourcePxHeight = source.height * tileHeightPx
```

4. Où vit `applyTilesetTransparentColorToPngBytes` ?

Dans :

```text
packages/map_editor/lib/src/application/services/tileset_transparent_color_processor.dart
```

5. Le package `image` est-il déjà disponible ?

Oui. `packages/map_editor/pubspec.yaml` contient :

```text
image: ^4.2.0
```

`packages/map_editor/pubspec.lock` résout :

```text
version: "4.8.0"
```

6. Où placer proprement le générateur de preview statique ?

Dans :

```text
packages/map_editor/lib/src/application/services/path_center_pattern_static_preview_renderer.dart
```

Justification : la preview manipule des bytes PNG et `package:image`, donc elle appartient à `map_editor`, pas à `map_core`.

7. Quelle limite V0 appliquer aux source rect width/height ?

V0 accepte uniquement :

```text
source.width == 1
source.height == 1
```

Les sources multi-tiles sont rejetées par `ArgumentError`.

8. Quels tests PathPattern doivent être relancés ?

```text
packages/map_editor/test/path_pattern/path_center_pattern_static_preview_renderer_test.dart
packages/map_editor/test/path_pattern/tileset_transparent_color_processor_test.dart
packages/map_core/test/tileset_transparent_color_test.dart
packages/map_core/test/project_path_preset_center_pattern_adapter_test.dart
packages/map_core/test/path_center_pattern_resolver_test.dart
packages/map_core/test/path_center_pattern_test.dart
packages/map_core/test/map_terrain_autotile_characterization_test.dart
```

## 3. Fichiers créés / modifiés / supprimés

### Créés

```text
packages/map_editor/lib/src/application/services/path_center_pattern_static_preview_renderer.dart
packages/map_editor/test/path_pattern/path_center_pattern_static_preview_renderer_test.dart
reports/pathPattern/path_pattern_lot_05_center_pattern_static_preview.md
```

### Modifiés

```text
```

### Supprimés

```text
```

## 4. API ajoutée

Fichier :

```text
packages/map_editor/lib/src/application/services/path_center_pattern_static_preview_renderer.dart
```

API :

```dart
Uint8List renderPathCenterPatternStaticPreviewPng({
  required Uint8List tilesetPngBytes,
  required PathCenterPattern pattern,
  required int tileWidthPx,
  required int tileHeightPx,
  TilesetTransparentColor? transparentColor,
})
```

## 5. Sémantique TilesetSourceRect retenue

`TilesetSourceRect` est traité comme une source en coordonnées de tuiles.

Le renderer calcule :

```dart
final sourceX = source.x * tileWidthPx;
final sourceY = source.y * tileHeightPx;
```

Puis copie exactement `tileWidthPx × tileHeightPx` pixels vers :

```dart
final destX = cell.localX * tileWidthPx;
final destY = cell.localY * tileHeightPx;
```

Limite V0 :

```text
source.width == 1 && source.height == 1
```

## 6. Comportement preview 1×1

Test couvert :

```text
tileset 2 tiles horizontales, tile 0 rouge, tile 1 bleue
pattern 1×1 source.x = 1
preview 2×2 bleue opaque
```

Le test vérifie :

```text
preview.width == 2
preview.height == 2
tous les pixels == bleu alpha 255
```

## 7. Comportement preview 2×2

Test couvert :

```text
tile 0 = rouge
tile 1 = vert
tile 2 = bleu
tile 3 = jaune
```

Pattern :

```text
(0,0) -> rouge
(1,0) -> vert
(0,1) -> bleu
(1,1) -> jaune
```

Le test vérifie chaque quadrant de la preview `4×4`.

## 8. Comportement transparentColor

Si `transparentColor` est fourni, le renderer appelle :

```dart
applyTilesetTransparentColorToPngBytes(...)
```

avant de composer la preview.

Test couvert :

```text
#F05BA1 alpha 255 -> #F05BA1 alpha 0
#0000FF alpha 255 -> #0000FF alpha 255
```

Si `transparentColor == null`, aucun traitement de transparence n’est appliqué.

Test couvert :

```text
#F05BA1 alpha 255 reste #F05BA1 alpha 255
```

## 9. Erreurs gérées

Le renderer lance `ArgumentError` pour :

```text
- tileWidthPx <= 0 ;
- tileHeightPx <= 0 ;
- PNG invalide ;
- source rect hors image ;
- source.width != 1 ou source.height != 1 ;
- cellule sans frame, même si PathCenterPatternCell empêche déjà ce cas.
```

## 10. Pourquoi map_editor et pas map_core

`map_core` contient les value objects purs :

```text
PathCenterPattern
PathCenterPatternCell
TilesetVisualFrame
TilesetSourceRect
TilesetTransparentColor
```

Le renderer statique :

```text
- manipule Uint8List de PNG ;
- dépend de package:image ;
- compose des pixels en mémoire ;
- servira une preview editor.
```

Il reste donc dans `map_editor`.

## 11. Tests lancés

### TDD rouge initial

Commande :

```bash
cd packages/map_editor && flutter test test/path_pattern/path_center_pattern_static_preview_renderer_test.dart --no-pub --reporter expanded
```

Sortie :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_center_pattern_static_preview_renderer_test.dart
00:00 +0 -1: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_center_pattern_static_preview_renderer_test.dart [E]
  Failed to load "/Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_center_pattern_static_preview_renderer_test.dart":
  Compilation failed for testPath=/Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_center_pattern_static_preview_renderer_test.dart: test/path_pattern/path_center_pattern_static_preview_renderer_test.dart:6:8: Error: Error when reading 'lib/src/application/services/path_center_pattern_static_preview_renderer.dart': No such file or directory
  import 'package:map_editor/src/application/services/path_center_pattern_static_preview_renderer.dart';
         ^
  test/path_pattern/path_center_pattern_static_preview_renderer_test.dart:27:28: Error: Method not found: 'renderPathCenterPatternStaticPreviewPng'.
        final previewBytes = renderPathCenterPatternStaticPreviewPng(
                             ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  test/path_pattern/path_center_pattern_static_preview_renderer_test.dart:69:28: Error: Method not found: 'renderPathCenterPatternStaticPreviewPng'.
        final previewBytes = renderPathCenterPatternStaticPreviewPng(
                             ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  test/path_pattern/path_center_pattern_static_preview_renderer_test.dart:126:28: Error: Method not found: 'renderPathCenterPatternStaticPreviewPng'.
        final previewBytes = renderPathCenterPatternStaticPreviewPng(
                             ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  test/path_pattern/path_center_pattern_static_preview_renderer_test.dart:158:28: Error: Method not found: 'renderPathCenterPatternStaticPreviewPng'.
        final previewBytes = renderPathCenterPatternStaticPreviewPng(
                             ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  test/path_pattern/path_center_pattern_static_preview_renderer_test.dart:189:15: Error: Method not found: 'renderPathCenterPatternStaticPreviewPng'.
          () => renderPathCenterPatternStaticPreviewPng(
                ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  test/path_pattern/path_center_pattern_static_preview_renderer_test.dart:217:15: Error: Method not found: 'renderPathCenterPatternStaticPreviewPng'.
          () => renderPathCenterPatternStaticPreviewPng(
                ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  test/path_pattern/path_center_pattern_static_preview_renderer_test.dart:237:15: Error: Method not found: 'renderPathCenterPatternStaticPreviewPng'.
          () => renderPathCenterPatternStaticPreviewPng(
                ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  test/path_pattern/path_center_pattern_static_preview_renderer_test.dart:264:15: Error: Method not found: 'renderPathCenterPatternStaticPreviewPng'.
          () => renderPathCenterPatternStaticPreviewPng(
                ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  test/path_pattern/path_center_pattern_static_preview_renderer_test.dart:273:15: Error: Method not found: 'renderPathCenterPatternStaticPreviewPng'.
          () => renderPathCenterPatternStaticPreviewPng(
                ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  .
00:00 +0 -1: Some tests failed.
```

### Test ciblé Lot 5

Commande :

```bash
cd packages/map_editor && flutter test test/path_pattern/path_center_pattern_static_preview_renderer_test.dart --no-pub --reporter expanded
```

Sortie complète :

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

### Régression Lot 4-bis

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
00:02 +1069: All tests passed!
```

Suite complète `map_editor` non lancée : ce lot n’ajoute aucun widget, aucun wiring app, aucun provider, et les vérifications ciblées couvrent le service ajouté et sa dépendance directe Lot 4-bis.

## 12. Analyze

Commande :

```bash
cd packages/map_editor && flutter analyze lib/src/application/services/path_center_pattern_static_preview_renderer.dart test/path_pattern/path_center_pattern_static_preview_renderer_test.dart
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
- pas de widget Flutter ;
- pas de canvas rendering ;
- pas de painter integration ;
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
- pas de save flow ;
- pas de modification des images sources ;
- pas de création de fichiers PNG sur disque ;
- pas de preview animée dans ce lot.
```

## 14. Limites restantes

Limites V0 :

```text
- première frame uniquement ;
- sources multi-tiles rejetées ;
- un seul PNG de tileset en entrée ;
- tilesetId des frames non résolu ;
- aucune preview UI ;
- aucun cache ;
- aucune animation ;
- aucun rendu canvas/runtime.
```

## 15. Git status final

Statut final :

```text
?? packages/map_editor/lib/src/application/services/path_center_pattern_static_preview_renderer.dart
?? packages/map_editor/test/path_pattern/path_center_pattern_static_preview_renderer_test.dart
?? reports/pathPattern/path_pattern_lot_05_center_pattern_static_preview.md
```

## 16. Prochain lot recommandé

Prochain lot recommandé :

```text
PathPattern-6 — Path Center Pattern Animated Preview V0
```

Alternative possible si on veut voir la brique dans l’app plus tôt :

```text
PathPattern-11 — Path Studio Shell V0
```

Mais techniquement, le prochain lot naturel après une preview statique est l’animation.

## Evidence Pack

### Contenu complet — path_center_pattern_static_preview_renderer.dart

```dart
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:map_core/map_core.dart';

import 'tileset_transparent_color_processor.dart';

Uint8List renderPathCenterPatternStaticPreviewPng({
  required Uint8List tilesetPngBytes,
  required PathCenterPattern pattern,
  required int tileWidthPx,
  required int tileHeightPx,
  TilesetTransparentColor? transparentColor,
}) {
  if (tileWidthPx <= 0) {
    throw ArgumentError.value(
      tileWidthPx,
      'tileWidthPx',
      'Path center pattern static preview tileWidthPx must be positive.',
    );
  }
  if (tileHeightPx <= 0) {
    throw ArgumentError.value(
      tileHeightPx,
      'tileHeightPx',
      'Path center pattern static preview tileHeightPx must be positive.',
    );
  }

  final processedTilesetBytes = transparentColor == null
      ? tilesetPngBytes
      : applyTilesetTransparentColorToPngBytes(
          imageBytes: tilesetPngBytes,
          transparentColor: transparentColor,
        );
  final tileset = img.decodePng(processedTilesetBytes);
  if (tileset == null) {
    throw ArgumentError.value(
      tilesetPngBytes,
      'tilesetPngBytes',
      'Path center pattern static preview expected valid PNG bytes.',
    );
  }

  final preview = img.Image(
    width: pattern.size.width * tileWidthPx,
    height: pattern.size.height * tileHeightPx,
    numChannels: 4,
  );

  for (final cell in pattern.cells) {
    if (cell.frames.isEmpty) {
      throw ArgumentError.value(
        cell,
        'pattern',
        'Path center pattern static preview cell must contain at least one frame.',
      );
    }
    final source = cell.frames.first.source;
    if (source.width != 1 || source.height != 1) {
      throw ArgumentError.value(
        source,
        'source',
        'Path center pattern static preview only supports 1x1 source rects in V0.',
      );
    }

    final sourceX = source.x * tileWidthPx;
    final sourceY = source.y * tileHeightPx;
    final sourceRight = sourceX + tileWidthPx;
    final sourceBottom = sourceY + tileHeightPx;
    if (sourceX < 0 ||
        sourceY < 0 ||
        sourceRight > tileset.width ||
        sourceBottom > tileset.height) {
      throw ArgumentError.value(
        source,
        'source',
        'Path center pattern static preview source rect is outside tileset image.',
      );
    }

    final destX = cell.localX * tileWidthPx;
    final destY = cell.localY * tileHeightPx;
    for (var y = 0; y < tileHeightPx; y += 1) {
      for (var x = 0; x < tileWidthPx; x += 1) {
        final pixel = tileset.getPixel(sourceX + x, sourceY + y);
        preview.setPixelRgba(
          destX + x,
          destY + y,
          pixel.r.toInt(),
          pixel.g.toInt(),
          pixel.b.toInt(),
          pixel.a.toInt(),
        );
      }
    }
  }

  return img.encodePng(preview);
}
```

### Contenu complet — path_center_pattern_static_preview_renderer_test.dart

```dart
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/services/path_center_pattern_static_preview_renderer.dart';

void main() {
  group('renderPathCenterPatternStaticPreviewPng', () {
    test('renders a 1x1 preview from the first frame source tile', () {
      final tilesetBytes = _horizontalTilesetPng(
        tileWidthPx: 2,
        tileHeightPx: 2,
        colors: const [
          _Pixel(red: 255, green: 0, blue: 0, alpha: 255),
          _Pixel(red: 0, green: 0, blue: 255, alpha: 255),
        ],
      );
      final pattern = _pattern(
        width: 1,
        height: 1,
        sources: const {
          (0, 0): TilesetSourceRect(x: 1, y: 0),
        },
      );

      final previewBytes = renderPathCenterPatternStaticPreviewPng(
        tilesetPngBytes: tilesetBytes,
        pattern: pattern,
        tileWidthPx: 2,
        tileHeightPx: 2,
      );
      final preview = _decodePng(previewBytes);

      expect(preview.width, 2);
      expect(preview.height, 2);
      _expectSolidRect(
        preview,
        left: 0,
        top: 0,
        width: 2,
        height: 2,
        color: const _Pixel(red: 0, green: 0, blue: 255, alpha: 255),
      );
    });

    test('renders a 2x2 preview in local cell positions', () {
      final tilesetBytes = _horizontalTilesetPng(
        tileWidthPx: 2,
        tileHeightPx: 2,
        colors: const [
          _Pixel(red: 255, green: 0, blue: 0, alpha: 255),
          _Pixel(red: 0, green: 255, blue: 0, alpha: 255),
          _Pixel(red: 0, green: 0, blue: 255, alpha: 255),
          _Pixel(red: 255, green: 255, blue: 0, alpha: 255),
        ],
      );
      final pattern = _pattern(
        width: 2,
        height: 2,
        sources: const {
          (0, 0): TilesetSourceRect(x: 0, y: 0),
          (1, 0): TilesetSourceRect(x: 1, y: 0),
          (0, 1): TilesetSourceRect(x: 2, y: 0),
          (1, 1): TilesetSourceRect(x: 3, y: 0),
        },
      );

      final previewBytes = renderPathCenterPatternStaticPreviewPng(
        tilesetPngBytes: tilesetBytes,
        pattern: pattern,
        tileWidthPx: 2,
        tileHeightPx: 2,
      );
      final preview = _decodePng(previewBytes);

      expect(preview.width, 4);
      expect(preview.height, 4);
      _expectSolidRect(
        preview,
        left: 0,
        top: 0,
        width: 2,
        height: 2,
        color: const _Pixel(red: 255, green: 0, blue: 0, alpha: 255),
      );
      _expectSolidRect(
        preview,
        left: 2,
        top: 0,
        width: 2,
        height: 2,
        color: const _Pixel(red: 0, green: 255, blue: 0, alpha: 255),
      );
      _expectSolidRect(
        preview,
        left: 0,
        top: 2,
        width: 2,
        height: 2,
        color: const _Pixel(red: 0, green: 0, blue: 255, alpha: 255),
      );
      _expectSolidRect(
        preview,
        left: 2,
        top: 2,
        width: 2,
        height: 2,
        color: const _Pixel(red: 255, green: 255, blue: 0, alpha: 255),
      );
    });

    test('applies optional transparentColor before composing preview', () {
      final tilesetBytes = _customImagePng(2, 1, (image) {
        image.setPixelRgba(0, 0, 240, 91, 161, 255);
        image.setPixelRgba(1, 0, 0, 0, 255, 255);
      });
      final pattern = _pattern(
        width: 1,
        height: 1,
        sources: const {
          (0, 0): TilesetSourceRect(x: 0, y: 0),
        },
      );

      final previewBytes = renderPathCenterPatternStaticPreviewPng(
        tilesetPngBytes: tilesetBytes,
        pattern: pattern,
        tileWidthPx: 2,
        tileHeightPx: 1,
        transparentColor: TilesetTransparentColor.fromHexRgb('f05ba1'),
      );
      final preview = _decodePng(previewBytes);

      expect(
        _pixelAt(preview, 0, 0),
        const _Pixel(red: 240, green: 91, blue: 161, alpha: 0),
      );
      expect(
        _pixelAt(preview, 1, 0),
        const _Pixel(red: 0, green: 0, blue: 255, alpha: 255),
      );
    });

    test('keeps transparent-color-looking pixels opaque when color is null',
        () {
      final tilesetBytes = _customImagePng(2, 1, (image) {
        image.setPixelRgba(0, 0, 240, 91, 161, 255);
        image.setPixelRgba(1, 0, 0, 0, 255, 255);
      });
      final pattern = _pattern(
        width: 1,
        height: 1,
        sources: const {
          (0, 0): TilesetSourceRect(x: 0, y: 0),
        },
      );

      final previewBytes = renderPathCenterPatternStaticPreviewPng(
        tilesetPngBytes: tilesetBytes,
        pattern: pattern,
        tileWidthPx: 2,
        tileHeightPx: 1,
      );
      final preview = _decodePng(previewBytes);

      expect(
        _pixelAt(preview, 0, 0),
        const _Pixel(red: 240, green: 91, blue: 161, alpha: 255),
      );
    });

    test('rejects source rects outside the tileset image', () {
      final tilesetBytes = _horizontalTilesetPng(
        tileWidthPx: 2,
        tileHeightPx: 2,
        colors: const [
          _Pixel(red: 255, green: 0, blue: 0, alpha: 255),
        ],
      );
      final pattern = _pattern(
        width: 1,
        height: 1,
        sources: const {
          (0, 0): TilesetSourceRect(x: 1, y: 0),
        },
      );

      expect(
        () => renderPathCenterPatternStaticPreviewPng(
          tilesetPngBytes: tilesetBytes,
          pattern: pattern,
          tileWidthPx: 2,
          tileHeightPx: 2,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects non-1x1 source rects in V0', () {
      final tilesetBytes = _horizontalTilesetPng(
        tileWidthPx: 2,
        tileHeightPx: 2,
        colors: const [
          _Pixel(red: 255, green: 0, blue: 0, alpha: 255),
          _Pixel(red: 0, green: 0, blue: 255, alpha: 255),
        ],
      );
      final pattern = _pattern(
        width: 1,
        height: 1,
        sources: const {
          (0, 0): TilesetSourceRect(x: 0, y: 0, width: 2),
        },
      );

      expect(
        () => renderPathCenterPatternStaticPreviewPng(
          tilesetPngBytes: tilesetBytes,
          pattern: pattern,
          tileWidthPx: 2,
          tileHeightPx: 2,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects invalid PNG bytes', () {
      final pattern = _pattern(
        width: 1,
        height: 1,
        sources: const {
          (0, 0): TilesetSourceRect(x: 0, y: 0),
        },
      );

      expect(
        () => renderPathCenterPatternStaticPreviewPng(
          tilesetPngBytes: Uint8List.fromList([1, 2, 3]),
          pattern: pattern,
          tileWidthPx: 2,
          tileHeightPx: 2,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects non-positive tile dimensions', () {
      final tilesetBytes = _horizontalTilesetPng(
        tileWidthPx: 2,
        tileHeightPx: 2,
        colors: const [
          _Pixel(red: 255, green: 0, blue: 0, alpha: 255),
        ],
      );
      final pattern = _pattern(
        width: 1,
        height: 1,
        sources: const {
          (0, 0): TilesetSourceRect(x: 0, y: 0),
        },
      );

      expect(
        () => renderPathCenterPatternStaticPreviewPng(
          tilesetPngBytes: tilesetBytes,
          pattern: pattern,
          tileWidthPx: 0,
          tileHeightPx: 2,
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => renderPathCenterPatternStaticPreviewPng(
          tilesetPngBytes: tilesetBytes,
          pattern: pattern,
          tileWidthPx: 2,
          tileHeightPx: 0,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}

PathCenterPattern _pattern({
  required int width,
  required int height,
  required Map<(int, int), TilesetSourceRect> sources,
}) {
  return PathCenterPattern(
    size: PathCenterPatternSize(width: width, height: height),
    cells: [
      for (final entry in sources.entries)
        PathCenterPatternCell(
          localX: entry.key.$1,
          localY: entry.key.$2,
          frames: [
            TilesetVisualFrame(source: entry.value),
          ],
        ),
    ],
  );
}

Uint8List _horizontalTilesetPng({
  required int tileWidthPx,
  required int tileHeightPx,
  required List<_Pixel> colors,
}) {
  return _customImagePng(colors.length * tileWidthPx, tileHeightPx, (image) {
    for (var tileX = 0; tileX < colors.length; tileX += 1) {
      final color = colors[tileX];
      for (var y = 0; y < tileHeightPx; y += 1) {
        for (var x = 0; x < tileWidthPx; x += 1) {
          image.setPixelRgba(
            tileX * tileWidthPx + x,
            y,
            color.red,
            color.green,
            color.blue,
            color.alpha,
          );
        }
      }
    }
  });
}

Uint8List _customImagePng(
  int width,
  int height,
  void Function(img.Image image) paint,
) {
  final image = img.Image(width: width, height: height, numChannels: 4);
  paint(image);
  return img.encodePng(image);
}

img.Image _decodePng(Uint8List imageBytes) {
  final image = img.decodePng(imageBytes);
  expect(image, isNotNull);
  return image!;
}

void _expectSolidRect(
  img.Image image, {
  required int left,
  required int top,
  required int width,
  required int height,
  required _Pixel color,
}) {
  for (var y = top; y < top + height; y += 1) {
    for (var x = left; x < left + width; x += 1) {
      expect(_pixelAt(image, x, y), color);
    }
  }
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

### Diff complet réel — path_center_pattern_static_preview_renderer.dart

```diff
diff --git a/packages/map_editor/lib/src/application/services/path_center_pattern_static_preview_renderer.dart b/packages/map_editor/lib/src/application/services/path_center_pattern_static_preview_renderer.dart
new file mode 100644
index 00000000..ecc47d5a
--- /dev/null
+++ b/packages/map_editor/lib/src/application/services/path_center_pattern_static_preview_renderer.dart
@@ -0,0 +1,101 @@
+import 'dart:typed_data';
+
+import 'package:image/image.dart' as img;
+import 'package:map_core/map_core.dart';
+
+import 'tileset_transparent_color_processor.dart';
+
+Uint8List renderPathCenterPatternStaticPreviewPng({
+  required Uint8List tilesetPngBytes,
+  required PathCenterPattern pattern,
+  required int tileWidthPx,
+  required int tileHeightPx,
+  TilesetTransparentColor? transparentColor,
+}) {
+  if (tileWidthPx <= 0) {
+    throw ArgumentError.value(
+      tileWidthPx,
+      'tileWidthPx',
+      'Path center pattern static preview tileWidthPx must be positive.',
+    );
+  }
+  if (tileHeightPx <= 0) {
+    throw ArgumentError.value(
+      tileHeightPx,
+      'tileHeightPx',
+      'Path center pattern static preview tileHeightPx must be positive.',
+    );
+  }
+
+  final processedTilesetBytes = transparentColor == null
+      ? tilesetPngBytes
+      : applyTilesetTransparentColorToPngBytes(
+          imageBytes: tilesetPngBytes,
+          transparentColor: transparentColor,
+        );
+  final tileset = img.decodePng(processedTilesetBytes);
+  if (tileset == null) {
+    throw ArgumentError.value(
+      tilesetPngBytes,
+      'tilesetPngBytes',
+      'Path center pattern static preview expected valid PNG bytes.',
+    );
+  }
+
+  final preview = img.Image(
+    width: pattern.size.width * tileWidthPx,
+    height: pattern.size.height * tileHeightPx,
+    numChannels: 4,
+  );
+
+  for (final cell in pattern.cells) {
+    if (cell.frames.isEmpty) {
+      throw ArgumentError.value(
+        cell,
+        'pattern',
+        'Path center pattern static preview cell must contain at least one frame.',
+      );
+    }
+    final source = cell.frames.first.source;
+    if (source.width != 1 || source.height != 1) {
+      throw ArgumentError.value(
+        source,
+        'source',
+        'Path center pattern static preview only supports 1x1 source rects in V0.',
+      );
+    }
+
+    final sourceX = source.x * tileWidthPx;
+    final sourceY = source.y * tileHeightPx;
+    final sourceRight = sourceX + tileWidthPx;
+    final sourceBottom = sourceY + tileHeightPx;
+    if (sourceX < 0 ||
+        sourceY < 0 ||
+        sourceRight > tileset.width ||
+        sourceBottom > tileset.height) {
+      throw ArgumentError.value(
+        source,
+        'source',
+        'Path center pattern static preview source rect is outside tileset image.',
+      );
+    }
+
+    final destX = cell.localX * tileWidthPx;
+    final destY = cell.localY * tileHeightPx;
+    for (var y = 0; y < tileHeightPx; y += 1) {
+      for (var x = 0; x < tileWidthPx; x += 1) {
+        final pixel = tileset.getPixel(sourceX + x, sourceY + y);
+        preview.setPixelRgba(
+          destX + x,
+          destY + y,
+          pixel.r.toInt(),
+          pixel.g.toInt(),
+          pixel.b.toInt(),
+          pixel.a.toInt(),
+        );
+      }
+    }
+  }
+
+  return img.encodePng(preview);
+}
```

### Diff complet réel — path_center_pattern_static_preview_renderer_test.dart

```diff
diff --git a/packages/map_editor/test/path_pattern/path_center_pattern_static_preview_renderer_test.dart b/packages/map_editor/test/path_pattern/path_center_pattern_static_preview_renderer_test.dart
new file mode 100644
index 00000000..44d33c6d
--- /dev/null
+++ b/packages/map_editor/test/path_pattern/path_center_pattern_static_preview_renderer_test.dart
@@ -0,0 +1,401 @@
+import 'dart:typed_data';
+
+import 'package:flutter_test/flutter_test.dart';
+import 'package:image/image.dart' as img;
+import 'package:map_core/map_core.dart';
+import 'package:map_editor/src/application/services/path_center_pattern_static_preview_renderer.dart';
+
+void main() {
+  group('renderPathCenterPatternStaticPreviewPng', () {
+    test('renders a 1x1 preview from the first frame source tile', () {
+      final tilesetBytes = _horizontalTilesetPng(
+        tileWidthPx: 2,
+        tileHeightPx: 2,
+        colors: const [
+          _Pixel(red: 255, green: 0, blue: 0, alpha: 255),
+          _Pixel(red: 0, green: 0, blue: 255, alpha: 255),
+        ],
+      );
+      final pattern = _pattern(
+        width: 1,
+        height: 1,
+        sources: const {
+          (0, 0): TilesetSourceRect(x: 1, y: 0),
+        },
+      );
+
+      final previewBytes = renderPathCenterPatternStaticPreviewPng(
+        tilesetPngBytes: tilesetBytes,
+        pattern: pattern,
+        tileWidthPx: 2,
+        tileHeightPx: 2,
+      );
+      final preview = _decodePng(previewBytes);
+
+      expect(preview.width, 2);
+      expect(preview.height, 2);
+      _expectSolidRect(
+        preview,
+        left: 0,
+        top: 0,
+        width: 2,
+        height: 2,
+        color: const _Pixel(red: 0, green: 0, blue: 255, alpha: 255),
+      );
+    });
+
+    test('renders a 2x2 preview in local cell positions', () {
+      final tilesetBytes = _horizontalTilesetPng(
+        tileWidthPx: 2,
+        tileHeightPx: 2,
+        colors: const [
+          _Pixel(red: 255, green: 0, blue: 0, alpha: 255),
+          _Pixel(red: 0, green: 255, blue: 0, alpha: 255),
+          _Pixel(red: 0, green: 0, blue: 255, alpha: 255),
+          _Pixel(red: 255, green: 255, blue: 0, alpha: 255),
+        ],
+      );
+      final pattern = _pattern(
+        width: 2,
+        height: 2,
+        sources: const {
+          (0, 0): TilesetSourceRect(x: 0, y: 0),
+          (1, 0): TilesetSourceRect(x: 1, y: 0),
+          (0, 1): TilesetSourceRect(x: 2, y: 0),
+          (1, 1): TilesetSourceRect(x: 3, y: 0),
+        },
+      );
+
+      final previewBytes = renderPathCenterPatternStaticPreviewPng(
+        tilesetPngBytes: tilesetBytes,
+        pattern: pattern,
+        tileWidthPx: 2,
+        tileHeightPx: 2,
+      );
+      final preview = _decodePng(previewBytes);
+
+      expect(preview.width, 4);
+      expect(preview.height, 4);
+      _expectSolidRect(
+        preview,
+        left: 0,
+        top: 0,
+        width: 2,
+        height: 2,
+        color: const _Pixel(red: 255, green: 0, blue: 0, alpha: 255),
+      );
+      _expectSolidRect(
+        preview,
+        left: 2,
+        top: 0,
+        width: 2,
+        height: 2,
+        color: const _Pixel(red: 0, green: 255, blue: 0, alpha: 255),
+      );
+      _expectSolidRect(
+        preview,
+        left: 0,
+        top: 2,
+        width: 2,
+        height: 2,
+        color: const _Pixel(red: 0, green: 0, blue: 255, alpha: 255),
+      );
+      _expectSolidRect(
+        preview,
+        left: 2,
+        top: 2,
+        width: 2,
+        height: 2,
+        color: const _Pixel(red: 255, green: 255, blue: 0, alpha: 255),
+      );
+    });
+
+    test('applies optional transparentColor before composing preview', () {
+      final tilesetBytes = _customImagePng(2, 1, (image) {
+        image.setPixelRgba(0, 0, 240, 91, 161, 255);
+        image.setPixelRgba(1, 0, 0, 0, 255, 255);
+      });
+      final pattern = _pattern(
+        width: 1,
+        height: 1,
+        sources: const {
+          (0, 0): TilesetSourceRect(x: 0, y: 0),
+        },
+      );
+
+      final previewBytes = renderPathCenterPatternStaticPreviewPng(
+        tilesetPngBytes: tilesetBytes,
+        pattern: pattern,
+        tileWidthPx: 2,
+        tileHeightPx: 1,
+        transparentColor: TilesetTransparentColor.fromHexRgb('f05ba1'),
+      );
+      final preview = _decodePng(previewBytes);
+
+      expect(
+        _pixelAt(preview, 0, 0),
+        const _Pixel(red: 240, green: 91, blue: 161, alpha: 0),
+      );
+      expect(
+        _pixelAt(preview, 1, 0),
+        const _Pixel(red: 0, green: 0, blue: 255, alpha: 255),
+      );
+    });
+
+    test('keeps transparent-color-looking pixels opaque when color is null',
+        () {
+      final tilesetBytes = _customImagePng(2, 1, (image) {
+        image.setPixelRgba(0, 0, 240, 91, 161, 255);
+        image.setPixelRgba(1, 0, 0, 0, 255, 255);
+      });
+      final pattern = _pattern(
+        width: 1,
+        height: 1,
+        sources: const {
+          (0, 0): TilesetSourceRect(x: 0, y: 0),
+        },
+      );
+
+      final previewBytes = renderPathCenterPatternStaticPreviewPng(
+        tilesetPngBytes: tilesetBytes,
+        pattern: pattern,
+        tileWidthPx: 2,
+        tileHeightPx: 1,
+      );
+      final preview = _decodePng(previewBytes);
+
+      expect(
+        _pixelAt(preview, 0, 0),
+        const _Pixel(red: 240, green: 91, blue: 161, alpha: 255),
+      );
+    });
+
+    test('rejects source rects outside the tileset image', () {
+      final tilesetBytes = _horizontalTilesetPng(
+        tileWidthPx: 2,
+        tileHeightPx: 2,
+        colors: const [
+          _Pixel(red: 255, green: 0, blue: 0, alpha: 255),
+        ],
+      );
+      final pattern = _pattern(
+        width: 1,
+        height: 1,
+        sources: const {
+          (0, 0): TilesetSourceRect(x: 1, y: 0),
+        },
+      );
+
+      expect(
+        () => renderPathCenterPatternStaticPreviewPng(
+          tilesetPngBytes: tilesetBytes,
+          pattern: pattern,
+          tileWidthPx: 2,
+          tileHeightPx: 2,
+        ),
+        throwsA(isA<ArgumentError>()),
+      );
+    });
+
+    test('rejects non-1x1 source rects in V0', () {
+      final tilesetBytes = _horizontalTilesetPng(
+        tileWidthPx: 2,
+        tileHeightPx: 2,
+        colors: const [
+          _Pixel(red: 255, green: 0, blue: 0, alpha: 255),
+          _Pixel(red: 0, green: 0, blue: 255, alpha: 255),
+        ],
+      );
+      final pattern = _pattern(
+        width: 1,
+        height: 1,
+        sources: const {
+          (0, 0): TilesetSourceRect(x: 0, y: 0, width: 2),
+        },
+      );
+
+      expect(
+        () => renderPathCenterPatternStaticPreviewPng(
+          tilesetPngBytes: tilesetBytes,
+          pattern: pattern,
+          tileWidthPx: 2,
+          tileHeightPx: 2,
+        ),
+        throwsA(isA<ArgumentError>()),
+      );
+    });
+
+    test('rejects invalid PNG bytes', () {
+      final pattern = _pattern(
+        width: 1,
+        height: 1,
+        sources: const {
+          (0, 0): TilesetSourceRect(x: 0, y: 0),
+        },
+      );
+
+      expect(
+        () => renderPathCenterPatternStaticPreviewPng(
+          tilesetPngBytes: Uint8List.fromList([1, 2, 3]),
+          pattern: pattern,
+          tileWidthPx: 2,
+          tileHeightPx: 2,
+        ),
+        throwsA(isA<ArgumentError>()),
+      );
+    });
+
+    test('rejects non-positive tile dimensions', () {
+      final tilesetBytes = _horizontalTilesetPng(
+        tileWidthPx: 2,
+        tileHeightPx: 2,
+        colors: const [
+          _Pixel(red: 255, green: 0, blue: 0, alpha: 255),
+        ],
+      );
+      final pattern = _pattern(
+        width: 1,
+        height: 1,
+        sources: const {
+          (0, 0): TilesetSourceRect(x: 0, y: 0),
+        },
+      );
+
+      expect(
+        () => renderPathCenterPatternStaticPreviewPng(
+          tilesetPngBytes: tilesetBytes,
+          pattern: pattern,
+          tileWidthPx: 0,
+          tileHeightPx: 2,
+        ),
+        throwsA(isA<ArgumentError>()),
+      );
+      expect(
+        () => renderPathCenterPatternStaticPreviewPng(
+          tilesetPngBytes: tilesetBytes,
+          pattern: pattern,
+          tileWidthPx: 2,
+          tileHeightPx: 0,
+        ),
+        throwsA(isA<ArgumentError>()),
+      );
+    });
+  });
+}
+
+PathCenterPattern _pattern({
+  required int width,
+  required int height,
+  required Map<(int, int), TilesetSourceRect> sources,
+}) {
+  return PathCenterPattern(
+    size: PathCenterPatternSize(width: width, height: height),
+    cells: [
+      for (final entry in sources.entries)
+        PathCenterPatternCell(
+          localX: entry.key.$1,
+          localY: entry.key.$2,
+          frames: [
+            TilesetVisualFrame(source: entry.value),
+          ],
+        ),
+    ],
+  );
+}
+
+Uint8List _horizontalTilesetPng({
+  required int tileWidthPx,
+  required int tileHeightPx,
+  required List<_Pixel> colors,
+}) {
+  return _customImagePng(colors.length * tileWidthPx, tileHeightPx, (image) {
+    for (var tileX = 0; tileX < colors.length; tileX += 1) {
+      final color = colors[tileX];
+      for (var y = 0; y < tileHeightPx; y += 1) {
+        for (var x = 0; x < tileWidthPx; x += 1) {
+          image.setPixelRgba(
+            tileX * tileWidthPx + x,
+            y,
+            color.red,
+            color.green,
+            color.blue,
+            color.alpha,
+          );
+        }
+      }
+    }
+  });
+}
+
+Uint8List _customImagePng(
+  int width,
+  int height,
+  void Function(img.Image image) paint,
+) {
+  final image = img.Image(width: width, height: height, numChannels: 4);
+  paint(image);
+  return img.encodePng(image);
+}
+
+img.Image _decodePng(Uint8List imageBytes) {
+  final image = img.decodePng(imageBytes);
+  expect(image, isNotNull);
+  return image!;
+}
+
+void _expectSolidRect(
+  img.Image image, {
+  required int left,
+  required int top,
+  required int width,
+  required int height,
+  required _Pixel color,
+}) {
+  for (var y = top; y < top + height; y += 1) {
+    for (var x = left; x < left + width; x += 1) {
+      expect(_pixelAt(image, x, y), color);
+    }
+  }
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
rg -n "map_runtime|map_gameplay|map_battle|ProjectManifest|ProjectPathPreset|toJson|fromJson|build_runner|Freezed|dart:ui|Image\.memory|MemoryImage|File\(|writeAsBytes|readAsBytes" packages/map_editor/lib/src/application/services/path_center_pattern_static_preview_renderer.dart packages/map_editor/test/path_pattern/path_center_pattern_static_preview_renderer_test.dart
```

Sortie :

```text
```

### Context Mode

`ctx` CLI n’est pas disponible dans le shell :

```text
command -v ctx; echo exit:$?
exit:1
```

Le MCP Context Mode disponible a été utilisé. Statistiques MCP :

```text
1.4M tokens saved  ·  83.1% reduction  ·  22h 19m
Without context-mode  |████████████████████████████████████████| 6.3 MB
With context-mode     |███████░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░| 1.1 MB
5.3 MB kept out of your conversation. Never entered context.
175 calls
ctx_batch_execute         58 calls    4.1 MB saved
ctx_execute               71 calls  513.2 KB saved
ctx_search                15 calls  453.3 KB saved
ctx_execute_file          15 calls  168.3 KB saved
ctx_fetch_and_index        3 calls   48.1 KB saved
ctx_stats                 13 calls   45.6 KB saved
v1.0.103
```

## Auto-review

- Ai-je gardé la preview hors UI ? Oui.
- Ai-je évité le canvas ? Oui.
- Ai-je évité toute lecture/écriture disque ? Oui.
- Ai-je évité `map_core` pour le traitement image ? Oui.
- Ai-je utilisé la première frame seulement ? Oui.
- Ai-je appliqué la transparence uniquement si fournie ? Oui.
- Ai-je évité une couleur par défaut hardcodée ? Oui.
- Ai-je rejeté les PNG invalides ? Oui.
- Ai-je rejeté les source rect hors image ? Oui.

## Critique du prompt

- Ambiguïté rencontrée : le prompt demandait de rejeter une cellule sans frame, mais `PathCenterPatternCell` interdit déjà `frames` vide. J’ai conservé un garde défensif dans le renderer.
- Sémantique confirmée de `TilesetSourceRect` : coordonnées en tuiles, pas pixels.
- Décision à valider avant preview animée : le prochain renderer devra probablement partager une petite routine de copie source->destination ou intégrer une résolution de frame temporelle sans dupliquer la validation source rect.
