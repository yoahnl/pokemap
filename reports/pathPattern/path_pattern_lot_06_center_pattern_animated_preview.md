# Lot PathPattern-6 — Path Center Pattern Animated Preview V0

## 1. Verdict

Accepté.

Le lot ajoute une preview PNG animée en mémoire côté `map_editor` :

```text
PathCenterPattern + tileset PNG bytes + elapsedMs -> preview PNG
```

La fonction est pure, ne lit aucun fichier, n'écrit aucun fichier, ne crée pas d'UI, ne touche pas au canvas, ne touche pas au runtime, et ne touche pas au gameplay.

## 2. Audit initial

Commandes initiales :

```bash
pwd
git status --short --untracked-files=all
git diff --stat
rg -n "renderPathCenterPatternStaticPreviewPng|PathCenterPattern|TilesetVisualFrame|TilesetSourceRect|durationMs|resolveTileVisualFrameTimeline|TileVisualFrameTimeline|elapsedMs|applyTilesetTransparentColorToPngBytes|decodePng|encodePng|path_pattern" packages/map_editor/lib packages/map_editor/test packages/map_core/lib packages/map_core/test
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
ctx_stats: 1.4M tokens saved · 83.0% reduction · 22h 41m · 177 calls · v1.0.103.
```

Réponses d'audit :

1. `renderPathCenterPatternStaticPreviewPng` vit dans `packages/map_editor/lib/src/application/services/path_center_pattern_static_preview_renderer.dart`.
2. Oui, une partie du code statique était réutilisable : validation des dimensions, décodage PNG avec transparence optionnelle, création de l'image destination, validation et copie de source rect 1x1.
3. Un resolver de timeline existe déjà dans `packages/map_core/lib/src/operations/tile_visual_frame_timeline.dart`.
4. Son contrat : `resolveTileVisualFrameTimeline(...)` accepte une liste de `TilesetVisualFrame`, un `elapsedMs` double, un mode `staticFrame`, `loop` ou `oneShot`, normalise les durées via `normalizeElementFrameDurationsMs`, puis retourne la frame exacte et son index.
5. `durationMs == null` est normalisé par `normalizeElementFrameDurationsMs` vers `defaultPlacedElementAnimationFrameDurationMs`, actuellement `200`.
6. Règle V0 retenue : `durationMs == null` utilise le fallback canonique `map_core` de 200 ms ; `durationMs <= 0` est rejeté localement par le renderer animé avant délégation.
7. Le renderer animé est placé dans `packages/map_editor/lib/src/application/services/path_center_pattern_animated_preview_renderer.dart`.
8. Un petit helper commun a été créé dans `packages/map_editor/lib/src/application/services/path_center_pattern_preview_compositor.dart`.
9. Tests PathPattern relancés : Lot 6, Lot 5, Lot 4-bis, Lot 4, Lot 3, Lot 2, Lot 1, Lot 0, plus `dart test` complet côté `map_core`.

## 3. Fichiers créés / modifiés / supprimés

Créés :

```text
packages/map_editor/lib/src/application/services/path_center_pattern_animated_preview_renderer.dart
packages/map_editor/lib/src/application/services/path_center_pattern_preview_compositor.dart
packages/map_editor/test/path_pattern/path_center_pattern_animated_preview_renderer_test.dart
reports/pathPattern/path_pattern_lot_06_center_pattern_animated_preview.md
```

Modifiés :

```text
packages/map_editor/lib/src/application/services/path_center_pattern_static_preview_renderer.dart
```

Supprimés :

```text
aucun
```

## 4. API ajoutée

```dart
Uint8List renderPathCenterPatternAnimatedPreviewPng({
  required Uint8List tilesetPngBytes,
  required PathCenterPattern pattern,
  required int tileWidthPx,
  required int tileHeightPx,
  required int elapsedMs,
  TilesetTransparentColor? transparentColor,
})
```

## 5. Règle de résolution des frames

Chaque cellule de `PathCenterPattern` résout sa propre timeline.

Le renderer appelle :

```dart
resolveTileVisualFrameTimeline(
  frames: cell.frames,
  elapsedMs: elapsedMs.toDouble(),
  mode: TileVisualFrameTimelinePlaybackMode.loop,
)
```

Une frame unique reste stable. Plusieurs frames bouclent selon les durées de chaque frame.

## 6. Règle durationMs null

`durationMs == null` suit le contrat existant de `map_core` :

```text
defaultPlacedElementAnimationFrameDurationMs = 200
```

Le test `uses map_core default duration for null frame durations` vérifie :

```text
elapsedMs = 0 -> frame A
elapsedMs = 199 -> frame A
elapsedMs = 200 -> frame B
elapsedMs = 400 -> frame A
```

## 7. Règle elapsedMs

`elapsedMs` est obligatoire et doit être positif ou nul.

```text
elapsedMs < 0 -> ArgumentError
```

## 8. Comportement preview 1×1

Un motif 1x1 avec une frame unique reste stable pour `elapsedMs = 0` et `elapsedMs = 1000`.

Un motif 1x1 avec deux frames explicites de 100 ms et 200 ms boucle :

```text
0   -> A
99  -> A
100 -> B
299 -> B
300 -> A
399 -> A
400 -> B
```

## 9. Comportement preview 2×2

Un motif 2x2 compose quatre cellules locales :

```text
(0,0) -> top-left
(1,0) -> top-right
(0,1) -> bottom-left
(1,1) -> bottom-right
```

Chaque cellule résout sa timeline indépendamment. Le test passe à la seconde frame de chaque cellule à `elapsedMs = 100`.

## 10. Comportement transparentColor

La transparence reste optionnelle.

```text
transparentColor fourni -> applyTilesetTransparentColorToPngBytes appliqué avant composition
transparentColor null -> aucune couleur par défaut, pixels inchangés
```

Aucune couleur n'est hardcodée dans le renderer.

## 11. Erreurs gérées

Le renderer rejette :

```text
tileWidthPx <= 0
tileHeightPx <= 0
elapsedMs < 0
PNG invalide
source.width != 1
source.height != 1
source rect hors image
durationMs <= 0
cellule sans frame, par défense même si PathCenterPatternCell l'empêche déjà
```

## 12. Pourquoi map_editor et pas map_core

`map_core` contient les value objects et le resolver temporel pur.

La preview PNG dépend de `Uint8List`, de `package:image`, du décodage PNG, de l'encodage PNG, et du processeur de transparence editor. Ce traitement reste donc dans `map_editor`.

## 13. Tests lancés

### Test rouge TDD initial

Commande :

```bash
cd packages/map_editor && flutter test test/path_pattern/path_center_pattern_animated_preview_renderer_test.dart --no-pub --reporter expanded
```

Sortie :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_center_pattern_animated_preview_renderer_test.dart
test/path_pattern/path_center_pattern_animated_preview_renderer_test.dart:6:8: Error: Error when reading 'lib/src/application/services/path_center_pattern_animated_preview_renderer.dart': No such file or directory
import 'package:map_editor/src/application/services/path_center_pattern_animated_preview_renderer.dart';
       ^
test/path_pattern/path_center_pattern_animated_preview_renderer_test.dart:27:9: Error: Method not found: 'renderPathCenterPatternAnimatedPreviewPng'.
        renderPathCenterPatternAnimatedPreviewPng(
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
00:00 +0 -1: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_center_pattern_animated_preview_renderer_test.dart [E]
  Failed to load "/Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_center_pattern_animated_preview_renderer_test.dart":
  Compilation failed for testPath=/Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_center_pattern_animated_preview_renderer_test.dart.
00:00 +0 -1: Some tests failed.
```

### Test ciblé Lot 6

Commande :

```bash
cd packages/map_editor && flutter test test/path_pattern/path_center_pattern_animated_preview_renderer_test.dart --no-pub --reporter expanded
```

Sortie :

```text
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

### Régression Lot 5

Commande :

```bash
cd packages/map_editor && flutter test test/path_pattern/path_center_pattern_static_preview_renderer_test.dart --no-pub --reporter expanded
```

Sortie :

```text
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

Sortie :

```text
00:00 +0: applyTilesetTransparentColorToPngBytes returns the same bytes instance when transparentColor is null
00:00 +1: applyTilesetTransparentColorToPngBytes turns matching RGB pixels transparent and preserves others
00:00 +2: applyTilesetTransparentColorToPngBytes matches RGB while ignoring existing alpha
00:00 +3: applyTilesetTransparentColorToPngBytes uses the value object parser case-insensitively
00:00 +4: applyTilesetTransparentColorToPngBytes leaves images without matching pixels unchanged by channel values
00:00 +5: applyTilesetTransparentColorToPngBytes rejects invalid PNG bytes
00:00 +6: All tests passed!
```

### Régression Lot 4

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

### Régression Lot 3

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

### Régression Lot 2

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

### Régression Lot 1

Commande :

```bash
cd packages/map_core && dart test test/path_center_pattern_test.dart --reporter expanded --no-color
```

Sortie :

```text
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

Sortie :

```text
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
00:01 +1069: All tests passed!
```

Suite complète `map_editor` :

```text
Non lancée. Le lot modifie uniquement des services applicatifs isolés et les tests ciblés map_editor plus l'analyse ciblée couvrent les chemins touchés. Les régressions core demandées ont été lancées.
```

## 14. Analyze

Commande :

```bash
cd packages/map_editor && flutter analyze lib/src/application/services/path_center_pattern_animated_preview_renderer.dart test/path_pattern/path_center_pattern_animated_preview_renderer_test.dart
```

Première sortie :

```text
Analyzing 2 items...

   info • Use 'const' for final variables initialized to a constant value • test/path_pattern/path_center_pattern_animated_preview_renderer_test.dart:128:7 • prefer_const_declarations

1 issue found. (ran in 2.0s)
```

Correction appliquée :

```text
final colors = const [...]
-> const colors = [...]
```

Sortie finale :

```text
Analyzing 2 items...

No issues found! (ran in 1.1s)
```

## 15. Non-objectifs confirmés

Confirmé :

```text
pas de Path Studio UI
pas de nouvelle UI
pas de widget Flutter
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
pas de PathPattern persistant
pas de manifest integration
pas de ticker Flutter
pas d'AnimationController
```

## 16. Limites restantes

Limites V0 :

```text
- le renderer reçoit un seul tileset PNG, donc il ignore la résolution effective des tilesetId ;
- source.width/source.height doivent rester 1x1 ;
- aucune preview UI n'est branchée ;
- aucune animation temps réel n'est branchée ;
- les sources multi-tiles restent hors lot ;
- les images ne sont pas lues depuis disque par ce service ;
- le test complet map_editor n'a pas été lancé.
```

## 17. Git status final

Commande :

```bash
git status --short --untracked-files=all
```

Sortie :

```text
 M packages/map_editor/lib/src/application/services/path_center_pattern_static_preview_renderer.dart
?? packages/map_editor/lib/src/application/services/path_center_pattern_animated_preview_renderer.dart
?? packages/map_editor/lib/src/application/services/path_center_pattern_preview_compositor.dart
?? packages/map_editor/test/path_pattern/path_center_pattern_animated_preview_renderer_test.dart
?? reports/pathPattern/path_pattern_lot_06_center_pattern_animated_preview.md
```

## 18. Prochain lot recommandé

Prochain lot recommandé :

```text
PathPattern-7 — ProjectPathPatternPreset Model V0
```

Alternative si l'on veut rester uniquement côté preview avant persistance :

```text
Path Studio Shell V0 peut attendre ; les briques pures sont maintenant assez solides pour modéliser le preset projet minimal.
```

## Evidence Pack

### Contenu complet — packages/map_editor/lib/src/application/services/path_center_pattern_animated_preview_renderer.dart

```dart
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:map_core/map_core.dart';

import 'path_center_pattern_preview_compositor.dart';

const _errorPrefix = 'Path center pattern animated preview';

Uint8List renderPathCenterPatternAnimatedPreviewPng({
  required Uint8List tilesetPngBytes,
  required PathCenterPattern pattern,
  required int tileWidthPx,
  required int tileHeightPx,
  required int elapsedMs,
  TilesetTransparentColor? transparentColor,
}) {
  validatePathCenterPatternPreviewTileDimensions(
    tileWidthPx: tileWidthPx,
    tileHeightPx: tileHeightPx,
    errorPrefix: _errorPrefix,
  );
  if (elapsedMs < 0) {
    throw ArgumentError.value(
      elapsedMs,
      'elapsedMs',
      '$_errorPrefix elapsedMs must be non-negative.',
    );
  }

  final tileset = decodePathCenterPatternPreviewTilesetPng(
    tilesetPngBytes: tilesetPngBytes,
    transparentColor: transparentColor,
    errorPrefix: _errorPrefix,
  );
  final preview = createPathCenterPatternPreviewImage(
    pattern: pattern,
    tileWidthPx: tileWidthPx,
    tileHeightPx: tileHeightPx,
  );

  for (final cell in pattern.cells) {
    if (cell.frames.isEmpty) {
      throw ArgumentError.value(
        cell,
        'pattern',
        '$_errorPrefix cell must contain at least one frame.',
      );
    }
    _validateFrameDurations(cell.frames);
    final resolution = resolveTileVisualFrameTimeline(
      frames: cell.frames,
      elapsedMs: elapsedMs.toDouble(),
      mode: TileVisualFrameTimelinePlaybackMode.loop,
    );
    final frame = resolution.frame;
    if (frame == null) {
      throw ArgumentError.value(
        cell,
        'pattern',
        '$_errorPrefix cell must contain at least one frame.',
      );
    }
    copyPathCenterPatternPreviewFrameTile(
      tileset: tileset,
      preview: preview,
      cell: cell,
      frame: frame,
      tileWidthPx: tileWidthPx,
      tileHeightPx: tileHeightPx,
      errorPrefix: _errorPrefix,
    );
  }

  return img.encodePng(preview);
}

void _validateFrameDurations(List<TilesetVisualFrame> frames) {
  for (final frame in frames) {
    final durationMs = frame.durationMs;
    if (durationMs != null && durationMs <= 0) {
      throw ArgumentError.value(
        durationMs,
        'durationMs',
        '$_errorPrefix frame duration must be positive.',
      );
    }
  }
}
```

### Contenu complet — packages/map_editor/lib/src/application/services/path_center_pattern_preview_compositor.dart

```dart
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:map_core/map_core.dart';

import 'tileset_transparent_color_processor.dart';

void validatePathCenterPatternPreviewTileDimensions({
  required int tileWidthPx,
  required int tileHeightPx,
  required String errorPrefix,
}) {
  if (tileWidthPx <= 0) {
    throw ArgumentError.value(
      tileWidthPx,
      'tileWidthPx',
      '$errorPrefix tileWidthPx must be positive.',
    );
  }
  if (tileHeightPx <= 0) {
    throw ArgumentError.value(
      tileHeightPx,
      'tileHeightPx',
      '$errorPrefix tileHeightPx must be positive.',
    );
  }
}

img.Image decodePathCenterPatternPreviewTilesetPng({
  required Uint8List tilesetPngBytes,
  required TilesetTransparentColor? transparentColor,
  required String errorPrefix,
}) {
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
      '$errorPrefix expected valid PNG bytes.',
    );
  }
  return tileset;
}

img.Image createPathCenterPatternPreviewImage({
  required PathCenterPattern pattern,
  required int tileWidthPx,
  required int tileHeightPx,
}) {
  return img.Image(
    width: pattern.size.width * tileWidthPx,
    height: pattern.size.height * tileHeightPx,
    numChannels: 4,
  );
}

void copyPathCenterPatternPreviewFrameTile({
  required img.Image tileset,
  required img.Image preview,
  required PathCenterPatternCell cell,
  required TilesetVisualFrame frame,
  required int tileWidthPx,
  required int tileHeightPx,
  required String errorPrefix,
}) {
  final source = frame.source;
  if (source.width != 1 || source.height != 1) {
    throw ArgumentError.value(
      source,
      'source',
      '$errorPrefix only supports 1x1 source rects in V0.',
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
      '$errorPrefix source rect is outside tileset image.',
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
```

### Contenu complet — packages/map_editor/lib/src/application/services/path_center_pattern_static_preview_renderer.dart

```dart
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:map_core/map_core.dart';

import 'path_center_pattern_preview_compositor.dart';

const _errorPrefix = 'Path center pattern static preview';

Uint8List renderPathCenterPatternStaticPreviewPng({
  required Uint8List tilesetPngBytes,
  required PathCenterPattern pattern,
  required int tileWidthPx,
  required int tileHeightPx,
  TilesetTransparentColor? transparentColor,
}) {
  validatePathCenterPatternPreviewTileDimensions(
    tileWidthPx: tileWidthPx,
    tileHeightPx: tileHeightPx,
    errorPrefix: _errorPrefix,
  );
  final tileset = decodePathCenterPatternPreviewTilesetPng(
    tilesetPngBytes: tilesetPngBytes,
    transparentColor: transparentColor,
    errorPrefix: _errorPrefix,
  );
  final preview = createPathCenterPatternPreviewImage(
    pattern: pattern,
    tileWidthPx: tileWidthPx,
    tileHeightPx: tileHeightPx,
  );

  for (final cell in pattern.cells) {
    if (cell.frames.isEmpty) {
      throw ArgumentError.value(
        cell,
        'pattern',
        'Path center pattern static preview cell must contain at least one frame.',
      );
    }
    copyPathCenterPatternPreviewFrameTile(
      tileset: tileset,
      preview: preview,
      cell: cell,
      frame: cell.frames.first,
      tileWidthPx: tileWidthPx,
      tileHeightPx: tileHeightPx,
      errorPrefix: _errorPrefix,
    );
  }

  return img.encodePng(preview);
}
```

### Contenu complet — packages/map_editor/test/path_pattern/path_center_pattern_animated_preview_renderer_test.dart

```dart
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/services/path_center_pattern_animated_preview_renderer.dart';

void main() {
  group('renderPathCenterPatternAnimatedPreviewPng', () {
    test('keeps a single-frame 1x1 pattern stable across elapsed time', () {
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
        frames: {
          (0, 0): [_frame(0)],
        },
      );

      final initialPreview = _decodePng(
        renderPathCenterPatternAnimatedPreviewPng(
          tilesetPngBytes: tilesetBytes,
          pattern: pattern,
          tileWidthPx: 2,
          tileHeightPx: 2,
          elapsedMs: 0,
        ),
      );
      final latePreview = _decodePng(
        renderPathCenterPatternAnimatedPreviewPng(
          tilesetPngBytes: tilesetBytes,
          pattern: pattern,
          tileWidthPx: 2,
          tileHeightPx: 2,
          elapsedMs: 1000,
        ),
      );

      _expectSolidRect(
        initialPreview,
        left: 0,
        top: 0,
        width: 2,
        height: 2,
        color: const _Pixel(red: 255, green: 0, blue: 0, alpha: 255),
      );
      _expectSolidRect(
        latePreview,
        left: 0,
        top: 0,
        width: 2,
        height: 2,
        color: const _Pixel(red: 255, green: 0, blue: 0, alpha: 255),
      );
    });

    test('loops two explicit-duration frames for a 1x1 pattern', () {
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
        frames: {
          (0, 0): [
            _frame(0, durationMs: 100),
            _frame(1, durationMs: 200),
          ],
        },
      );

      _expectTopLeftColorAtElapsed(
        tilesetBytes: tilesetBytes,
        pattern: pattern,
        elapsedMs: 0,
        color: const _Pixel(red: 255, green: 0, blue: 0, alpha: 255),
      );
      _expectTopLeftColorAtElapsed(
        tilesetBytes: tilesetBytes,
        pattern: pattern,
        elapsedMs: 99,
        color: const _Pixel(red: 255, green: 0, blue: 0, alpha: 255),
      );
      _expectTopLeftColorAtElapsed(
        tilesetBytes: tilesetBytes,
        pattern: pattern,
        elapsedMs: 100,
        color: const _Pixel(red: 0, green: 0, blue: 255, alpha: 255),
      );
      _expectTopLeftColorAtElapsed(
        tilesetBytes: tilesetBytes,
        pattern: pattern,
        elapsedMs: 299,
        color: const _Pixel(red: 0, green: 0, blue: 255, alpha: 255),
      );
      _expectTopLeftColorAtElapsed(
        tilesetBytes: tilesetBytes,
        pattern: pattern,
        elapsedMs: 300,
        color: const _Pixel(red: 255, green: 0, blue: 0, alpha: 255),
      );
      _expectTopLeftColorAtElapsed(
        tilesetBytes: tilesetBytes,
        pattern: pattern,
        elapsedMs: 399,
        color: const _Pixel(red: 255, green: 0, blue: 0, alpha: 255),
      );
      _expectTopLeftColorAtElapsed(
        tilesetBytes: tilesetBytes,
        pattern: pattern,
        elapsedMs: 400,
        color: const _Pixel(red: 0, green: 0, blue: 255, alpha: 255),
      );
    });

    test('resolves independent 2x2 cell timelines', () {
      const colors = [
        _Pixel(red: 10, green: 0, blue: 0, alpha: 255),
        _Pixel(red: 20, green: 0, blue: 0, alpha: 255),
        _Pixel(red: 0, green: 10, blue: 0, alpha: 255),
        _Pixel(red: 0, green: 20, blue: 0, alpha: 255),
        _Pixel(red: 0, green: 0, blue: 10, alpha: 255),
        _Pixel(red: 0, green: 0, blue: 20, alpha: 255),
        _Pixel(red: 10, green: 10, blue: 0, alpha: 255),
        _Pixel(red: 20, green: 20, blue: 0, alpha: 255),
      ];
      final tilesetBytes = _horizontalTilesetPng(
        tileWidthPx: 2,
        tileHeightPx: 2,
        colors: colors,
      );
      final pattern = _pattern(
        width: 2,
        height: 2,
        frames: {
          (0, 0): [_frame(0, durationMs: 100), _frame(1, durationMs: 100)],
          (1, 0): [_frame(2, durationMs: 100), _frame(3, durationMs: 100)],
          (0, 1): [_frame(4, durationMs: 100), _frame(5, durationMs: 100)],
          (1, 1): [_frame(6, durationMs: 100), _frame(7, durationMs: 100)],
        },
      );

      final initialPreview = _decodePng(
        renderPathCenterPatternAnimatedPreviewPng(
          tilesetPngBytes: tilesetBytes,
          pattern: pattern,
          tileWidthPx: 2,
          tileHeightPx: 2,
          elapsedMs: 0,
        ),
      );
      final secondFramePreview = _decodePng(
        renderPathCenterPatternAnimatedPreviewPng(
          tilesetPngBytes: tilesetBytes,
          pattern: pattern,
          tileWidthPx: 2,
          tileHeightPx: 2,
          elapsedMs: 100,
        ),
      );

      expect(initialPreview.width, 4);
      expect(initialPreview.height, 4);
      _expectQuadrants(
        initialPreview,
        topLeft: colors[0],
        topRight: colors[2],
        bottomLeft: colors[4],
        bottomRight: colors[6],
      );
      _expectQuadrants(
        secondFramePreview,
        topLeft: colors[1],
        topRight: colors[3],
        bottomLeft: colors[5],
        bottomRight: colors[7],
      );
    });

    test('uses map_core default duration for null frame durations', () {
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
        frames: {
          (0, 0): [_frame(0), _frame(1)],
        },
      );

      _expectTopLeftColorAtElapsed(
        tilesetBytes: tilesetBytes,
        pattern: pattern,
        elapsedMs: 0,
        color: const _Pixel(red: 255, green: 0, blue: 0, alpha: 255),
      );
      _expectTopLeftColorAtElapsed(
        tilesetBytes: tilesetBytes,
        pattern: pattern,
        elapsedMs: defaultPlacedElementAnimationFrameDurationMs - 1,
        color: const _Pixel(red: 255, green: 0, blue: 0, alpha: 255),
      );
      _expectTopLeftColorAtElapsed(
        tilesetBytes: tilesetBytes,
        pattern: pattern,
        elapsedMs: defaultPlacedElementAnimationFrameDurationMs,
        color: const _Pixel(red: 0, green: 0, blue: 255, alpha: 255),
      );
      _expectTopLeftColorAtElapsed(
        tilesetBytes: tilesetBytes,
        pattern: pattern,
        elapsedMs: defaultPlacedElementAnimationFrameDurationMs * 2,
        color: const _Pixel(red: 255, green: 0, blue: 0, alpha: 255),
      );
    });

    test('rejects non-positive frame durations', () {
      final tilesetBytes = _horizontalTilesetPng(
        tileWidthPx: 2,
        tileHeightPx: 2,
        colors: const [
          _Pixel(red: 255, green: 0, blue: 0, alpha: 255),
        ],
      );

      expect(
        () => renderPathCenterPatternAnimatedPreviewPng(
          tilesetPngBytes: tilesetBytes,
          pattern: _pattern(
            width: 1,
            height: 1,
            frames: {
              (0, 0): [_frame(0, durationMs: 0)],
            },
          ),
          tileWidthPx: 2,
          tileHeightPx: 2,
          elapsedMs: 0,
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => renderPathCenterPatternAnimatedPreviewPng(
          tilesetPngBytes: tilesetBytes,
          pattern: _pattern(
            width: 1,
            height: 1,
            frames: {
              (0, 0): [_frame(0, durationMs: -1)],
            },
          ),
          tileWidthPx: 2,
          tileHeightPx: 2,
          elapsedMs: 0,
        ),
        throwsA(isA<ArgumentError>()),
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
        frames: {
          (0, 0): [_frame(0)],
        },
      );

      final previewBytes = renderPathCenterPatternAnimatedPreviewPng(
        tilesetPngBytes: tilesetBytes,
        pattern: pattern,
        tileWidthPx: 2,
        tileHeightPx: 1,
        elapsedMs: 0,
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
        frames: {
          (0, 0): [_frame(0)],
        },
      );

      final previewBytes = renderPathCenterPatternAnimatedPreviewPng(
        tilesetPngBytes: tilesetBytes,
        pattern: pattern,
        tileWidthPx: 2,
        tileHeightPx: 1,
        elapsedMs: 0,
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
        frames: {
          (0, 0): [_frame(1)],
        },
      );

      expect(
        () => renderPathCenterPatternAnimatedPreviewPng(
          tilesetPngBytes: tilesetBytes,
          pattern: pattern,
          tileWidthPx: 2,
          tileHeightPx: 2,
          elapsedMs: 0,
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
        frames: {
          (0, 0): [_frame(0, width: 2)],
        },
      );

      expect(
        () => renderPathCenterPatternAnimatedPreviewPng(
          tilesetPngBytes: tilesetBytes,
          pattern: pattern,
          tileWidthPx: 2,
          tileHeightPx: 2,
          elapsedMs: 0,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects invalid PNG bytes', () {
      final pattern = _pattern(
        width: 1,
        height: 1,
        frames: {
          (0, 0): [_frame(0)],
        },
      );

      expect(
        () => renderPathCenterPatternAnimatedPreviewPng(
          tilesetPngBytes: Uint8List.fromList([1, 2, 3]),
          pattern: pattern,
          tileWidthPx: 2,
          tileHeightPx: 2,
          elapsedMs: 0,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects negative elapsedMs and non-positive tile dimensions', () {
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
        frames: {
          (0, 0): [_frame(0)],
        },
      );

      expect(
        () => renderPathCenterPatternAnimatedPreviewPng(
          tilesetPngBytes: tilesetBytes,
          pattern: pattern,
          tileWidthPx: 2,
          tileHeightPx: 2,
          elapsedMs: -1,
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => renderPathCenterPatternAnimatedPreviewPng(
          tilesetPngBytes: tilesetBytes,
          pattern: pattern,
          tileWidthPx: 0,
          tileHeightPx: 2,
          elapsedMs: 0,
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => renderPathCenterPatternAnimatedPreviewPng(
          tilesetPngBytes: tilesetBytes,
          pattern: pattern,
          tileWidthPx: 2,
          tileHeightPx: 0,
          elapsedMs: 0,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}

PathCenterPattern _pattern({
  required int width,
  required int height,
  required Map<(int, int), List<TilesetVisualFrame>> frames,
}) {
  return PathCenterPattern(
    size: PathCenterPatternSize(width: width, height: height),
    cells: [
      for (final entry in frames.entries)
        PathCenterPatternCell(
          localX: entry.key.$1,
          localY: entry.key.$2,
          frames: entry.value,
        ),
    ],
  );
}

TilesetVisualFrame _frame(
  int sourceX, {
  int sourceY = 0,
  int width = 1,
  int height = 1,
  int? durationMs,
}) {
  return TilesetVisualFrame(
    source: TilesetSourceRect(
      x: sourceX,
      y: sourceY,
      width: width,
      height: height,
    ),
    durationMs: durationMs,
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

void _expectTopLeftColorAtElapsed({
  required Uint8List tilesetBytes,
  required PathCenterPattern pattern,
  required int elapsedMs,
  required _Pixel color,
}) {
  final preview = _decodePng(
    renderPathCenterPatternAnimatedPreviewPng(
      tilesetPngBytes: tilesetBytes,
      pattern: pattern,
      tileWidthPx: 2,
      tileHeightPx: 2,
      elapsedMs: elapsedMs,
    ),
  );

  _expectSolidRect(
    preview,
    left: 0,
    top: 0,
    width: 2,
    height: 2,
    color: color,
  );
}

void _expectQuadrants(
  img.Image image, {
  required _Pixel topLeft,
  required _Pixel topRight,
  required _Pixel bottomLeft,
  required _Pixel bottomRight,
}) {
  _expectSolidRect(
    image,
    left: 0,
    top: 0,
    width: 2,
    height: 2,
    color: topLeft,
  );
  _expectSolidRect(
    image,
    left: 2,
    top: 0,
    width: 2,
    height: 2,
    color: topRight,
  );
  _expectSolidRect(
    image,
    left: 0,
    top: 2,
    width: 2,
    height: 2,
    color: bottomLeft,
  );
  _expectSolidRect(
    image,
    left: 2,
    top: 2,
    width: 2,
    height: 2,
    color: bottomRight,
  );
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

### Diffs complets

`packages/map_editor/lib/src/application/services/path_center_pattern_static_preview_renderer.dart`

```diff
diff --git a/packages/map_editor/lib/src/application/services/path_center_pattern_static_preview_renderer.dart b/packages/map_editor/lib/src/application/services/path_center_pattern_static_preview_renderer.dart
index ecc47d5a..f6aa2133 100644
--- a/packages/map_editor/lib/src/application/services/path_center_pattern_static_preview_renderer.dart
+++ b/packages/map_editor/lib/src/application/services/path_center_pattern_static_preview_renderer.dart
@@ -3,7 +3,9 @@ import 'dart:typed_data';
 import 'package:image/image.dart' as img;
 import 'package:map_core/map_core.dart';
 
-import 'tileset_transparent_color_processor.dart';
+import 'path_center_pattern_preview_compositor.dart';
+
+const _errorPrefix = 'Path center pattern static preview';
 
 Uint8List renderPathCenterPatternStaticPreviewPng({
   required Uint8List tilesetPngBytes,
@@ -12,40 +14,20 @@ Uint8List renderPathCenterPatternStaticPreviewPng({
   required int tileHeightPx,
   TilesetTransparentColor? transparentColor,
 }) {
-  if (tileWidthPx <= 0) {
-    throw ArgumentError.value(
-      tileWidthPx,
-      'tileWidthPx',
-      'Path center pattern static preview tileWidthPx must be positive.',
-    );
-  }
-  if (tileHeightPx <= 0) {
-    throw ArgumentError.value(
-      tileHeightPx,
-      'tileHeightPx',
-      'Path center pattern static preview tileHeightPx must be positive.',
-    );
-  }
-
-  final processedTilesetBytes = transparentColor == null
-      ? tilesetPngBytes
-      : applyTilesetTransparentColorToPngBytes(
-          imageBytes: tilesetPngBytes,
-          transparentColor: transparentColor,
-        );
-  final tileset = img.decodePng(processedTilesetBytes);
-  if (tileset == null) {
-    throw ArgumentError.value(
-      tilesetPngBytes,
-      'tilesetPngBytes',
-      'Path center pattern static preview expected valid PNG bytes.',
-    );
-  }
-
-  final preview = img.Image(
-    width: pattern.size.width * tileWidthPx,
-    height: pattern.size.height * tileHeightPx,
-    numChannels: 4,
+  validatePathCenterPatternPreviewTileDimensions(
+    tileWidthPx: tileWidthPx,
+    tileHeightPx: tileHeightPx,
+    errorPrefix: _errorPrefix,
+  );
+  final tileset = decodePathCenterPatternPreviewTilesetPng(
+    tilesetPngBytes: tilesetPngBytes,
+    transparentColor: transparentColor,
+    errorPrefix: _errorPrefix,
+  );
+  final preview = createPathCenterPatternPreviewImage(
+    pattern: pattern,
+    tileWidthPx: tileWidthPx,
+    tileHeightPx: tileHeightPx,
   );
 
   for (final cell in pattern.cells) {
@@ -56,45 +38,15 @@ Uint8List renderPathCenterPatternStaticPreviewPng({
         'Path center pattern static preview cell must contain at least one frame.',
       );
     }
-    final source = cell.frames.first.source;
-    if (source.width != 1 || source.height != 1) {
-      throw ArgumentError.value(
-        source,
-        'source',
-        'Path center pattern static preview only supports 1x1 source rects in V0.',
-      );
-    }
-
-    final sourceX = source.x * tileWidthPx;
-    final sourceY = source.y * tileHeightPx;
-    final sourceRight = sourceX + tileWidthPx;
-    final sourceBottom = sourceY + tileHeightPx;
-    if (sourceX < 0 ||
-        sourceY < 0 ||
-        sourceRight > tileset.width ||
-        sourceBottom > tileset.height) {
-      throw ArgumentError.value(
-        source,
-        'source',
-        'Path center pattern static preview source rect is outside tileset image.',
-      );
-    }
-
-    final destX = cell.localX * tileWidthPx;
-    final destY = cell.localY * tileHeightPx;
-    for (var y = 0; y < tileHeightPx; y += 1) {
-      for (var x = 0; x < tileWidthPx; x += 1) {
-        final pixel = tileset.getPixel(sourceX + x, sourceY + y);
-        preview.setPixelRgba(
-          destX + x,
-          destY + y,
-          pixel.r.toInt(),
-          pixel.g.toInt(),
-          pixel.b.toInt(),
-          pixel.a.toInt(),
-        );
-      }
-    }
+    copyPathCenterPatternPreviewFrameTile(
+      tileset: tileset,
+      preview: preview,
+      cell: cell,
+      frame: cell.frames.first,
+      tileWidthPx: tileWidthPx,
+      tileHeightPx: tileHeightPx,
+      errorPrefix: _errorPrefix,
+    );
   }
 
   return img.encodePng(preview);
```

`packages/map_editor/lib/src/application/services/path_center_pattern_preview_compositor.dart`

```diff
diff --git a/packages/map_editor/lib/src/application/services/path_center_pattern_preview_compositor.dart b/packages/map_editor/lib/src/application/services/path_center_pattern_preview_compositor.dart
new file mode 100644
index 00000000..8f4c6112
--- /dev/null
+++ b/packages/map_editor/lib/src/application/services/path_center_pattern_preview_compositor.dart
@@ -0,0 +1,111 @@
+import 'dart:typed_data';
+
+import 'package:image/image.dart' as img;
+import 'package:map_core/map_core.dart';
+
+import 'tileset_transparent_color_processor.dart';
+
+void validatePathCenterPatternPreviewTileDimensions({
+  required int tileWidthPx,
+  required int tileHeightPx,
+  required String errorPrefix,
+}) {
+  if (tileWidthPx <= 0) {
+    throw ArgumentError.value(
+      tileWidthPx,
+      'tileWidthPx',
+      '$errorPrefix tileWidthPx must be positive.',
+    );
+  }
+  if (tileHeightPx <= 0) {
+    throw ArgumentError.value(
+      tileHeightPx,
+      'tileHeightPx',
+      '$errorPrefix tileHeightPx must be positive.',
+    );
+  }
+}
+
+img.Image decodePathCenterPatternPreviewTilesetPng({
+  required Uint8List tilesetPngBytes,
+  required TilesetTransparentColor? transparentColor,
+  required String errorPrefix,
+}) {
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
+      '$errorPrefix expected valid PNG bytes.',
+    );
+  }
+  return tileset;
+}
+
+img.Image createPathCenterPatternPreviewImage({
+  required PathCenterPattern pattern,
+  required int tileWidthPx,
+  required int tileHeightPx,
+}) {
+  return img.Image(
+    width: pattern.size.width * tileWidthPx,
+    height: pattern.size.height * tileHeightPx,
+    numChannels: 4,
+  );
+}
+
+void copyPathCenterPatternPreviewFrameTile({
+  required img.Image tileset,
+  required img.Image preview,
+  required PathCenterPatternCell cell,
+  required TilesetVisualFrame frame,
+  required int tileWidthPx,
+  required int tileHeightPx,
+  required String errorPrefix,
+}) {
+  final source = frame.source;
+  if (source.width != 1 || source.height != 1) {
+    throw ArgumentError.value(
+      source,
+      'source',
+      '$errorPrefix only supports 1x1 source rects in V0.',
+    );
+  }
+
+  final sourceX = source.x * tileWidthPx;
+  final sourceY = source.y * tileHeightPx;
+  final sourceRight = sourceX + tileWidthPx;
+  final sourceBottom = sourceY + tileHeightPx;
+  if (sourceX < 0 ||
+      sourceY < 0 ||
+      sourceRight > tileset.width ||
+      sourceBottom > tileset.height) {
+    throw ArgumentError.value(
+      source,
+      'source',
+      '$errorPrefix source rect is outside tileset image.',
+    );
+  }
+
+  final destX = cell.localX * tileWidthPx;
+  final destY = cell.localY * tileHeightPx;
+  for (var y = 0; y < tileHeightPx; y += 1) {
+    for (var x = 0; x < tileWidthPx; x += 1) {
+      final pixel = tileset.getPixel(sourceX + x, sourceY + y);
+      preview.setPixelRgba(
+        destX + x,
+        destY + y,
+        pixel.r.toInt(),
+        pixel.g.toInt(),
+        pixel.b.toInt(),
+        pixel.a.toInt(),
+      );
+    }
+  }
+}
```

`packages/map_editor/lib/src/application/services/path_center_pattern_animated_preview_renderer.dart`

```diff
diff --git a/packages/map_editor/lib/src/application/services/path_center_pattern_animated_preview_renderer.dart b/packages/map_editor/lib/src/application/services/path_center_pattern_animated_preview_renderer.dart
new file mode 100644
index 00000000..6072bbcc
--- /dev/null
+++ b/packages/map_editor/lib/src/application/services/path_center_pattern_animated_preview_renderer.dart
@@ -0,0 +1,89 @@
+import 'dart:typed_data';
+
+import 'package:image/image.dart' as img;
+import 'package:map_core/map_core.dart';
+
+import 'path_center_pattern_preview_compositor.dart';
+
+const _errorPrefix = 'Path center pattern animated preview';
+
+Uint8List renderPathCenterPatternAnimatedPreviewPng({
+  required Uint8List tilesetPngBytes,
+  required PathCenterPattern pattern,
+  required int tileWidthPx,
+  required int tileHeightPx,
+  required int elapsedMs,
+  TilesetTransparentColor? transparentColor,
+}) {
+  validatePathCenterPatternPreviewTileDimensions(
+    tileWidthPx: tileWidthPx,
+    tileHeightPx: tileHeightPx,
+    errorPrefix: _errorPrefix,
+  );
+  if (elapsedMs < 0) {
+    throw ArgumentError.value(
+      elapsedMs,
+      'elapsedMs',
+      '$_errorPrefix elapsedMs must be non-negative.',
+    );
+  }
+
+  final tileset = decodePathCenterPatternPreviewTilesetPng(
+    tilesetPngBytes: tilesetPngBytes,
+    transparentColor: transparentColor,
+    errorPrefix: _errorPrefix,
+  );
+  final preview = createPathCenterPatternPreviewImage(
+    pattern: pattern,
+    tileWidthPx: tileWidthPx,
+    tileHeightPx: tileHeightPx,
+  );
+
+  for (final cell in pattern.cells) {
+    if (cell.frames.isEmpty) {
+      throw ArgumentError.value(
+        cell,
+        'pattern',
+        '$_errorPrefix cell must contain at least one frame.',
+      );
+    }
+    _validateFrameDurations(cell.frames);
+    final resolution = resolveTileVisualFrameTimeline(
+      frames: cell.frames,
+      elapsedMs: elapsedMs.toDouble(),
+      mode: TileVisualFrameTimelinePlaybackMode.loop,
+    );
+    final frame = resolution.frame;
+    if (frame == null) {
+      throw ArgumentError.value(
+        cell,
+        'pattern',
+        '$_errorPrefix cell must contain at least one frame.',
+      );
+    }
+    copyPathCenterPatternPreviewFrameTile(
+      tileset: tileset,
+      preview: preview,
+      cell: cell,
+      frame: frame,
+      tileWidthPx: tileWidthPx,
+      tileHeightPx: tileHeightPx,
+      errorPrefix: _errorPrefix,
+    );
+  }
+
+  return img.encodePng(preview);
+}
+
+void _validateFrameDurations(List<TilesetVisualFrame> frames) {
+  for (final frame in frames) {
+    final durationMs = frame.durationMs;
+    if (durationMs != null && durationMs <= 0) {
+      throw ArgumentError.value(
+        durationMs,
+        'durationMs',
+        '$_errorPrefix frame duration must be positive.',
+      );
+    }
+  }
+}
```

Le diff complet du test correspond au fichier complet affiché ci-dessus, avec création depuis `/dev/null`.

## No accidental coupling

Commande :

```bash
rg -n "map_runtime|map_gameplay|map_battle|ProjectManifest|ProjectPathPreset|toJson|fromJson|dart:ui|Image\\.memory|AnimationController|Timer|TSX|TMX|Mistral|PixelLab|MCP" packages/map_editor/lib/src/application/services/path_center_pattern_animated_preview_renderer.dart packages/map_editor/lib/src/application/services/path_center_pattern_preview_compositor.dart packages/map_editor/test/path_pattern/path_center_pattern_animated_preview_renderer_test.dart
```

Sortie :

```text
```

## Auto-review

- Ai-je gardé la preview hors UI ? Oui.
- Ai-je évité le canvas ? Oui.
- Ai-je évité toute lecture/écriture disque ? Oui.
- Ai-je évité map_core pour le traitement image ? Oui.
- Ai-je utilisé elapsedMs ? Oui.
- Ai-je testé les boucles ? Oui.
- Ai-je testé durationMs null ? Oui, avec le fallback `map_core` de 200 ms.
- Ai-je appliqué la transparence uniquement si fournie ? Oui.
- Ai-je évité une couleur par défaut hardcodée ? Oui.
- Ai-je rejeté les PNG invalides ? Oui.
- Ai-je rejeté les source rect hors image ? Oui.

## Critique du prompt

- Ambiguïté : le prompt suggérait `defaultFrameDurationMs = 100` uniquement si aucun resolver existant n'était disponible. L'audit a trouvé un resolver canonique dans `map_core`; la décision appliquée est donc le fallback existant de 200 ms.
- Ambiguïté : le resolver `map_core` normalise aussi les durées invalides. Pour ce lot, le renderer animé rejette explicitement `durationMs <= 0` avant délégation, car le contrat d'erreur du lot le demandait.
- Décision à valider avant le modèle persistant : faut-il conserver ce rejet local de `durationMs <= 0` pour les previews, ou aligner entièrement la preview sur la normalisation du resolver core ?
- Décision à valider avant Path Studio : comment l'UI choisira le tileset effectif quand une frame porte un `tilesetId` override.
