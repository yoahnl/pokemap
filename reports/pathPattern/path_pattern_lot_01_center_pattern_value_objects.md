# Lot PathPattern-1 — Center Pattern Value Objects V0

## 1. Verdict

Accepté côté implémentation locale.

Le lot ajoute uniquement les value objects purs et non persistants attendus pour représenter un centre de path multi-cases :

- `PathCenterPatternSize`
- `PathCenterPatternCell`
- `PathCenterPattern`

Le modèle reste volontairement bas niveau. Il ne référence pas `TerrainPathVariant`, `ProjectPathPreset`, `PathSurfaceKind`, `ProjectManifest`, JSON, runtime, gameplay, transparence, ni coordonnées map.

Le test ciblé, la régression du Lot 0, la suite complète `map_core` et l’analyse ciblée passent.

## 2. Audit initial

### Commandes initiales

```bash
pwd
git status --short --untracked-files=all
git diff --stat
rg -n "class TilesetVisualFrame|class TilesetSourceRect|TerrainPathVariant|ProjectPathPreset|PathPresetVariantMapping|PathSurfaceKind|surface|path_pattern|PathCenterPattern" packages/map_core/lib packages/map_core/test
```

### Sortie `pwd`

```text
/Users/karim/Project/pokemonProject
```

### Sortie `git status --short --untracked-files=all` initiale

```text
 M reports/pathPattern/path_pattern_roadmap.md
?? reports/pathPattern/path_pattern_lot_00_center_variant_audit_decision.md
```

Ces deux entrées étaient préexistantes au Lot 1 et n’ont pas été modifiées par ce lot.

### Sortie `git diff --stat` initiale

```text
 reports/pathPattern/path_pattern_roadmap.md | 241 +++++++++++++---------------
 1 file changed, 109 insertions(+), 132 deletions(-)
```

### Context Mode

Le binaire `ctx` n’est pas disponible dans le shell local :

```text
command -v ctx
```

Sortie :

```text

```

Le MCP Context Mode est disponible et a été utilisé pour l’audit large. Stats MCP au moment de l’audit :

```text
775.1K tokens saved  ·  80.0% reduction  ·  20h 35m

Without context-mode  |████████████████████████████████████████| 3.7 MB
With context-mode     |████████░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░| 759.2 KB

3.0 MB kept out of your conversation. Never entered context.

144 calls

  ctx_batch_execute         43 calls    2.1 MB saved
  ctx_search                15 calls  368.5 KB saved
  ctx_execute               61 calls  350.2 KB saved
  ctx_execute_file          15 calls  136.8 KB saved
  ctx_fetch_and_index        3 calls   39.1 KB saved
  ctx_stats                  7 calls   19.5 KB saved

v1.0.103
```

## 3. Fichiers créés / modifiés / supprimés

### Créés

```text
packages/map_core/lib/src/models/path_center_pattern.dart
packages/map_core/test/path_center_pattern_test.dart
reports/pathPattern/path_pattern_lot_01_center_pattern_value_objects.md
```

### Modifiés

```text
packages/map_core/lib/map_core.dart
```

### Supprimés

```text
aucun
```

## 4. Réponses à l’audit

### 4.1 Où est défini `TilesetVisualFrame` ?

`TilesetVisualFrame` est défini dans :

```text
packages/map_core/lib/src/models/project_manifest.dart
```

Emplacement audité :

```text
class TilesetSourceRect : ligne 257
class TilesetVisualFrame : ligne 273
class ProjectPathPreset : ligne 367
class PathPresetVariantMapping : ligne 383
```

### 4.2 Structure exacte de `TilesetVisualFrame`

```dart
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

`TilesetSourceRect` :

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
```

### 4.3 Validation existante de `durationMs` / source rect

Le constructeur Freezed de `TilesetVisualFrame` ne valide pas directement `durationMs`.

La validation de `durationMs` existe via `ProjectValidator` :

```text
packages/map_core/lib/src/validation/validators.dart:26
packages/map_core/lib/src/validation/validators.dart:53
packages/map_core/lib/src/validation/validators.dart:56
```

Le test existant confirme le rejet d’une durée non positive dans un preset path :

```text
packages/map_core/test/path_preset_frames_test.dart
```

Le nouveau modèle ne duplique pas ces validations. Il impose seulement que chaque cellule ait au moins une frame.

### 4.4 Emplacement choisi pour les nouveaux value objects

Fichier choisi :

```text
packages/map_core/lib/src/models/path_center_pattern.dart
```

Justification :

- `map_core` est le bon niveau pour un modèle pur partagé.
- Le modèle représente un concept de données local, pas une opération.
- Aucun besoin de JSON, codec, manifest ou génération.

### 4.5 `path_center_pattern.dart` plutôt que `path_pattern.dart`

Le nom `path_center_pattern.dart` a été choisi car le scope V0 est strictement le centre d’un path. Les bords, coins et jonctions restent hors lot.

### 4.6 Export public

Le fichier est exporté depuis :

```text
packages/map_core/lib/map_core.dart
```

Ajout :

```dart
export 'src/models/path_center_pattern.dart';
```

### 4.7 Tests existants à relancer

Tests retenus :

- `test/path_center_pattern_test.dart` pour le nouveau modèle.
- `test/map_terrain_autotile_characterization_test.dart` pour vérifier que la caractérisation Lot 0 reste stable.
- `dart test` complet dans `packages/map_core`.
- `dart analyze` ciblé sur le nouveau modèle et son test.

## 5. Description de `PathCenterPatternSize`

`PathCenterPatternSize` représente la taille locale du motif.

Contrat :

- `width > 0`
- `height > 0`
- `tileCount = width * height`
- `contains(localX, localY)` indique si une coordonnée locale appartient au motif
- égalité de valeur
- `hashCode` cohérent

Le constructeur public est une factory non `const` pour lancer des `ArgumentError` claires dès la construction.

## 6. Description de `PathCenterPatternCell`

`PathCenterPatternCell` représente une cellule locale du motif.

Contrat :

- `localX >= 0`
- `localY >= 0`
- `frames` non vide
- copie défensive de `frames`
- exposition en liste immuable
- égalité de valeur incluant l’ordre et le contenu des frames

La cellule ne connaît pas la taille de la grille. La validation “hors grille” appartient à `PathCenterPattern`.

## 7. Description de `PathCenterPattern`

`PathCenterPattern` représente un motif local complet.

Contrat :

- `cells` non vide
- toutes les coordonnées locales attendues sont présentes
- aucune cellule manquante
- aucune cellule hors grille
- aucune coordonnée dupliquée
- copie défensive
- exposition en liste immuable
- `cellAt(localX, localY)`
- `isSingleCell`
- `isMultiCell`
- égalité de valeur

Ordre exposé :

```text
row-major
```

Donc une entrée 2×2 est exposée dans cet ordre :

```text
(0,0), (1,0), (0,1), (1,1)
```

Cela rend l’égalité stable même si l’appelant fournit les cellules dans un autre ordre.

## 8. Validation de couverture de grille

Pour une taille :

```text
width = 2
height = 2
```

le modèle exige exactement :

```text
(0,0)
(1,0)
(0,1)
(1,1)
```

Cas rejetés par test :

- liste vide
- cellule manquante
- cellule hors grille
- coordonnée dupliquée
- `cellAt` hors grille

## 9. Immutabilité / copie défensive

Deux niveaux sont protégés :

```text
PathCenterPatternCell.frames
PathCenterPattern.cells
```

Les listes reçues sont copiées avec `List.unmodifiable`.

Les tests vérifient :

- modifier la liste d’entrée après construction ne modifie pas l’objet
- tenter d’ajouter dans la liste exposée lance `UnsupportedError`

## 10. Tests lancés

### 10.1 TDD rouge initial

Commande :

```bash
cd packages/map_core && dart test test/path_center_pattern_test.dart --reporter expanded
```

Sortie :

```text
00:00 +0: loading test/path_center_pattern_test.dart
00:00 +0 -1: loading test/path_center_pattern_test.dart [E]
  Failed to load "test/path_center_pattern_test.dart":
  test/path_center_pattern_test.dart:275:1: Error: Type 'PathCenterPatternCell' not found.
  PathCenterPatternCell _cell(int localX, int localY, {int sourceX = 0}) {
  ^^^^^^^^^^^^^^^^^^^^^
  test/path_center_pattern_test.dart:7:22: Error: Method not found: 'PathCenterPatternSize'.
        final single = PathCenterPatternSize(width: 1, height: 1);
                       ^^^^^^^^^^^^^^^^^^^^^
  test/path_center_pattern_test.dart:8:22: Error: Method not found: 'PathCenterPatternSize'.
        final square = PathCenterPatternSize(width: 2, height: 2);
                       ^^^^^^^^^^^^^^^^^^^^^
  test/path_center_pattern_test.dart:18:15: Error: Method not found: 'PathCenterPatternSize'.
          () => PathCenterPatternSize(width: 0, height: 1),
                ^^^^^^^^^^^^^^^^^^^^^
  test/path_center_pattern_test.dart:22:15: Error: Method not found: 'PathCenterPatternSize'.
          () => PathCenterPatternSize(width: 1, height: 0),
                ^^^^^^^^^^^^^^^^^^^^^
  test/path_center_pattern_test.dart:26:15: Error: Method not found: 'PathCenterPatternSize'.
          () => PathCenterPatternSize(width: -1, height: 1),
                ^^^^^^^^^^^^^^^^^^^^^
  test/path_center_pattern_test.dart:30:15: Error: Method not found: 'PathCenterPatternSize'.
          () => PathCenterPatternSize(width: 1, height: -1),
                ^^^^^^^^^^^^^^^^^^^^^
  test/path_center_pattern_test.dart:36:22: Error: Method not found: 'PathCenterPatternSize'.
        final single = PathCenterPatternSize(width: 1, height: 1);
                       ^^^^^^^^^^^^^^^^^^^^^
  test/path_center_pattern_test.dart:37:22: Error: Method not found: 'PathCenterPatternSize'.
        final square = PathCenterPatternSize(width: 2, height: 2);
                       ^^^^^^^^^^^^^^^^^^^^^
  test/path_center_pattern_test.dart:50:17: Error: Method not found: 'PathCenterPatternSize'.
        final a = PathCenterPatternSize(width: 2, height: 3);
                  ^^^^^^^^^^^^^^^^^^^^^
  test/path_center_pattern_test.dart:51:17: Error: Method not found: 'PathCenterPatternSize'.
        final b = PathCenterPatternSize(width: 2, height: 3);
                  ^^^^^^^^^^^^^^^^^^^^^
  test/path_center_pattern_test.dart:52:17: Error: Method not found: 'PathCenterPatternSize'.
        final c = PathCenterPatternSize(width: 3, height: 2);
                  ^^^^^^^^^^^^^^^^^^^^^
  test/path_center_pattern_test.dart:62:20: Error: Method not found: 'PathCenterPatternCell'.
        final cell = PathCenterPatternCell(
                     ^^^^^^^^^^^^^^^^^^^^^
  test/path_center_pattern_test.dart:75:15: Error: Method not found: 'PathCenterPatternCell'.
          () => PathCenterPatternCell(
                ^^^^^^^^^^^^^^^^^^^^^
  test/path_center_pattern_test.dart:83:15: Error: Method not found: 'PathCenterPatternCell'.
          () => PathCenterPatternCell(
                ^^^^^^^^^^^^^^^^^^^^^
  test/path_center_pattern_test.dart:91:15: Error: Method not found: 'PathCenterPatternCell'.
          () => PathCenterPatternCell(localX: 0, localY: 0, frames: []),
                ^^^^^^^^^^^^^^^^^^^^^
  test/path_center_pattern_test.dart:98:20: Error: Method not found: 'PathCenterPatternCell'.
        final cell = PathCenterPatternCell(
                     ^^^^^^^^^^^^^^^^^^^^^
  test/path_center_pattern_test.dart:111:17: Error: Method not found: 'PathCenterPatternCell'.
        final a = PathCenterPatternCell(
                  ^^^^^^^^^^^^^^^^^^^^^
  test/path_center_pattern_test.dart:116:17: Error: Method not found: 'PathCenterPatternCell'.
        final b = PathCenterPatternCell(
                  ^^^^^^^^^^^^^^^^^^^^^
  test/path_center_pattern_test.dart:121:17: Error: Method not found: 'PathCenterPatternCell'.
        final c = PathCenterPatternCell(
                  ^^^^^^^^^^^^^^^^^^^^^
  test/path_center_pattern_test.dart:137:15: Error: Method not found: 'PathCenterPatternSize'.
          size: PathCenterPatternSize(width: 1, height: 1),
                ^^^^^^^^^^^^^^^^^^^^^
  test/path_center_pattern_test.dart:136:23: Error: Method not found: 'PathCenterPattern'.
        final pattern = PathCenterPattern(
                        ^^^^^^^^^^^^^^^^^
  test/path_center_pattern_test.dart:156:15: Error: Method not found: 'PathCenterPatternSize'.
          size: PathCenterPatternSize(width: 2, height: 2),
                ^^^^^^^^^^^^^^^^^^^^^
  test/path_center_pattern_test.dart:155:23: Error: Method not found: 'PathCenterPattern'.
        final pattern = PathCenterPattern(
                        ^^^^^^^^^^^^^^^^^
  test/path_center_pattern_test.dart:177:15: Error: Method not found: 'PathCenterPatternSize'.
          size: PathCenterPatternSize(width: 2, height: 2),
                ^^^^^^^^^^^^^^^^^^^^^
  test/path_center_pattern_test.dart:176:23: Error: Method not found: 'PathCenterPattern'.
        final pattern = PathCenterPattern(
                        ^^^^^^^^^^^^^^^^^
  test/path_center_pattern_test.dart:189:15: Error: Method not found: 'PathCenterPatternSize'.
          size: PathCenterPatternSize(width: 2, height: 2),
                ^^^^^^^^^^^^^^^^^^^^^
  test/path_center_pattern_test.dart:188:17: Error: Method not found: 'PathCenterPattern'.
        final a = PathCenterPattern(
                  ^^^^^^^^^^^^^^^^^
  test/path_center_pattern_test.dart:198:15: Error: Method not found: 'PathCenterPatternSize'.
          size: PathCenterPatternSize(width: 2, height: 2),
                ^^^^^^^^^^^^^^^^^^^^^
  test/path_center_pattern_test.dart:197:17: Error: Method not found: 'PathCenterPattern'.
        final b = PathCenterPattern(
                  ^^^^^^^^^^^^^^^^^
  test/path_center_pattern_test.dart:207:15: Error: Method not found: 'PathCenterPatternSize'.
          size: PathCenterPatternSize(width: 1, height: 1),
                ^^^^^^^^^^^^^^^^^^^^^
  test/path_center_pattern_test.dart:206:17: Error: Method not found: 'PathCenterPattern'.
        final c = PathCenterPattern(
                  ^^^^^^^^^^^^^^^^^
  test/path_center_pattern_test.dart:221:17: Error: Method not found: 'PathCenterPatternSize'.
            size: PathCenterPatternSize(width: 1, height: 1),
                  ^^^^^^^^^^^^^^^^^^^^^
  test/path_center_pattern_test.dart:220:15: Error: Method not found: 'PathCenterPattern'.
          () => PathCenterPattern(
                ^^^^^^^^^^^^^^^^^
  test/path_center_pattern_test.dart:231:17: Error: Method not found: 'PathCenterPatternSize'.
            size: PathCenterPatternSize(width: 2, height: 2),
                  ^^^^^^^^^^^^^^^^^^^^^
  test/path_center_pattern_test.dart:230:15: Error: Method not found: 'PathCenterPattern'.
          () => PathCenterPattern(
                ^^^^^^^^^^^^^^^^^
  test/path_center_pattern_test.dart:245:17: Error: Method not found: 'PathCenterPatternSize'.
            size: PathCenterPatternSize(width: 1, height: 1),
                  ^^^^^^^^^^^^^^^^^^^^^
  test/path_center_pattern_test.dart:244:15: Error: Method not found: 'PathCenterPattern'.
          () => PathCenterPattern(
                ^^^^^^^^^^^^^^^^^
  test/path_center_pattern_test.dart:255:17: Error: Method not found: 'PathCenterPatternSize'.
            size: PathCenterPatternSize(width: 1, height: 1),
                  ^^^^^^^^^^^^^^^^^^^^^
  test/path_center_pattern_test.dart:254:15: Error: Method not found: 'PathCenterPattern'.
          () => PathCenterPattern(
                ^^^^^^^^^^^^^^^^^
  test/path_center_pattern_test.dart:264:15: Error: Method not found: 'PathCenterPatternSize'.
          size: PathCenterPatternSize(width: 1, height: 1),
                ^^^^^^^^^^^^^^^^^^^^^
  test/path_center_pattern_test.dart:263:23: Error: Method not found: 'PathCenterPattern'.
        final pattern = PathCenterPattern(
                        ^^^^^^^^^^^^^^^^^
  test/path_center_pattern_test.dart:276:10: Error: Method not found: 'PathCenterPatternCell'.
    return PathCenterPatternCell(
           ^^^^^^^^^^^^^^^^^^^^^
00:00 +0 -1: Some tests failed.
```

### 10.2 Test ciblé final

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

### 10.3 Régression Lot 0

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

### 10.4 Suite complète `map_core`

Commande :

```bash
cd packages/map_core && dart test
```

Ligne finale exacte :

```text
00:02 +1044: All tests passed!
```

## 11. Analyze

Commande :

```bash
cd packages/map_core && dart analyze lib/src/models/path_center_pattern.dart test/path_center_pattern_test.dart
```

Sortie :

```text
Analyzing path_center_pattern.dart, path_center_pattern_test.dart...
No issues found!
```

## 12. Non-objectifs confirmés

Confirmé :

- aucune UI créée
- aucune entrée Path Studio créée
- aucun resolver `mapX/mapY`
- aucun adapter `ProjectPathPreset`
- aucune modification `ProjectManifest`
- aucune modification `ProjectPathPreset`
- aucune modification `TerrainPathVariant`
- aucune modification `PathLayer`
- aucun JSON
- aucun codec
- aucun fichier généré
- aucun `build_runner`
- aucune modification runtime
- aucune modification gameplay
- aucune modification battle
- aucun traitement de transparence
- aucune image modifiée
- aucune sauvegarde disque ajoutée

## 13. Limites restantes

- `PathCenterPattern` ne décide pas encore quelle cellule utiliser pour une coordonnée de map.
- `PathCenterPattern` ne sait pas adapter un preset path existant en motif 1×1.
- La validation des frames conserve le contrat existant : le modèle exige une liste non vide, mais la validité détaillée des `TilesetVisualFrame` reste du ressort des validateurs existants.
- Il n’y a pas encore de diagnostic riche ; ce lot utilise volontairement `ArgumentError`.
- Les constructeurs publics sont des factories non `const` afin de garantir les validations et copies défensives.

## 14. Prochain lot recommandé

```text
PathPattern-2 — Center Pattern Resolver V0
```

Objectif recommandé :

```text
résoudre une cellule locale du motif depuis des coordonnées map, probablement via modulo positif.
```

## 15. Evidence Pack — contenus complets des fichiers créés / modifiés

### 15.1 `packages/map_core/lib/src/models/path_center_pattern.dart`

```dart
import 'project_manifest.dart';

/// Local size of a repeated path center pattern.
final class PathCenterPatternSize {
  factory PathCenterPatternSize({
    required int width,
    required int height,
  }) {
    if (width <= 0) {
      throw ArgumentError.value(
        width,
        'width',
        'PathCenterPatternSize width must be positive.',
      );
    }
    if (height <= 0) {
      throw ArgumentError.value(
        height,
        'height',
        'PathCenterPatternSize height must be positive.',
      );
    }
    return PathCenterPatternSize._(width: width, height: height);
  }

  const PathCenterPatternSize._({
    required this.width,
    required this.height,
  });

  final int width;
  final int height;

  int get tileCount => width * height;

  bool contains(int localX, int localY) {
    return localX >= 0 && localY >= 0 && localX < width && localY < height;
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is PathCenterPatternSize &&
            width == other.width &&
            height == other.height;
  }

  @override
  int get hashCode => Object.hash(width, height);
}

/// One local cell of a path center pattern.
final class PathCenterPatternCell {
  factory PathCenterPatternCell({
    required int localX,
    required int localY,
    required List<TilesetVisualFrame> frames,
  }) {
    if (localX < 0) {
      throw ArgumentError.value(
        localX,
        'localX',
        'PathCenterPatternCell localX must be non-negative.',
      );
    }
    if (localY < 0) {
      throw ArgumentError.value(
        localY,
        'localY',
        'PathCenterPatternCell localY must be non-negative.',
      );
    }
    if (frames.isEmpty) {
      throw ArgumentError.value(
        frames,
        'frames',
        'PathCenterPatternCell frames must not be empty.',
      );
    }
    return PathCenterPatternCell._(
      localX: localX,
      localY: localY,
      frames: List.unmodifiable(frames),
    );
  }

  const PathCenterPatternCell._({
    required this.localX,
    required this.localY,
    required this.frames,
  });

  final int localX;
  final int localY;
  final List<TilesetVisualFrame> frames;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is PathCenterPatternCell &&
            localX == other.localX &&
            localY == other.localY &&
            _listEquals(frames, other.frames);
  }

  @override
  int get hashCode => Object.hash(localX, localY, Object.hashAll(frames));
}

/// Complete local pattern used for the fill center of a path surface.
final class PathCenterPattern {
  factory PathCenterPattern({
    required PathCenterPatternSize size,
    required List<PathCenterPatternCell> cells,
  }) {
    if (cells.isEmpty) {
      throw ArgumentError.value(
        cells,
        'cells',
        'PathCenterPattern cells must not be empty.',
      );
    }

    final cellsByIndex = <int, PathCenterPatternCell>{};
    for (final cell in cells) {
      if (!size.contains(cell.localX, cell.localY)) {
        throw ArgumentError.value(
          cell,
          'cells',
          'PathCenterPattern has cell outside size at '
              '${cell.localX},${cell.localY}.',
        );
      }

      final index = _cellIndex(size, cell.localX, cell.localY);
      if (cellsByIndex.containsKey(index)) {
        throw ArgumentError.value(
          cell,
          'cells',
          'PathCenterPattern has duplicate cell at '
              '${cell.localX},${cell.localY}.',
        );
      }
      cellsByIndex[index] = cell;
    }

    final orderedCells = <PathCenterPatternCell>[];
    for (var y = 0; y < size.height; y += 1) {
      for (var x = 0; x < size.width; x += 1) {
        final index = _cellIndex(size, x, y);
        final cell = cellsByIndex[index];
        if (cell == null) {
          throw ArgumentError.value(
            cells,
            'cells',
            'PathCenterPattern has missing cell at $x,$y.',
          );
        }
        orderedCells.add(cell);
      }
    }

    return PathCenterPattern._(
      size: size,
      cells: List.unmodifiable(orderedCells),
      cellsByIndex: Map.unmodifiable(cellsByIndex),
    );
  }

  const PathCenterPattern._({
    required this.size,
    required this.cells,
    required Map<int, PathCenterPatternCell> cellsByIndex,
  }) : _cellsByIndex = cellsByIndex;

  final PathCenterPatternSize size;
  final List<PathCenterPatternCell> cells;
  final Map<int, PathCenterPatternCell> _cellsByIndex;

  bool get isSingleCell => size.tileCount == 1;

  bool get isMultiCell => size.tileCount > 1;

  PathCenterPatternCell cellAt(int localX, int localY) {
    if (!size.contains(localX, localY)) {
      throw ArgumentError.value(
        '$localX,$localY',
        'local coordinate',
        'PathCenterPattern cellAt coordinate is outside size.',
      );
    }
    return _cellsByIndex[_cellIndex(size, localX, localY)]!;
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is PathCenterPattern &&
            size == other.size &&
            _listEquals(cells, other.cells);
  }

  @override
  int get hashCode => Object.hash(size, Object.hashAll(cells));
}

int _cellIndex(PathCenterPatternSize size, int localX, int localY) {
  return localY * size.width + localX;
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (identical(a, b)) {
    return true;
  }
  if (a.length != b.length) {
    return false;
  }
  for (var index = 0; index < a.length; index += 1) {
    if (a[index] != b[index]) {
      return false;
    }
  }
  return true;
}
```

### 15.2 `packages/map_core/test/path_center_pattern_test.dart`

```dart
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('PathCenterPatternSize', () {
    test('accepts 1x1 and 2x2 sizes', () {
      final single = PathCenterPatternSize(width: 1, height: 1);
      final square = PathCenterPatternSize(width: 2, height: 2);

      expect(single.width, 1);
      expect(single.height, 1);
      expect(square.width, 2);
      expect(square.height, 2);
    });

    test('rejects non-positive dimensions', () {
      expect(
        () => PathCenterPatternSize(width: 0, height: 1),
        throwsArgumentError,
      );
      expect(
        () => PathCenterPatternSize(width: 1, height: 0),
        throwsArgumentError,
      );
      expect(
        () => PathCenterPatternSize(width: -1, height: 1),
        throwsArgumentError,
      );
      expect(
        () => PathCenterPatternSize(width: 1, height: -1),
        throwsArgumentError,
      );
    });

    test('reports tile count and coordinate containment', () {
      final single = PathCenterPatternSize(width: 1, height: 1);
      final square = PathCenterPatternSize(width: 2, height: 2);

      expect(single.tileCount, 1);
      expect(square.tileCount, 4);
      expect(single.contains(0, 0), isTrue);
      expect(single.contains(1, 0), isFalse);
      expect(single.contains(0, 1), isFalse);
      expect(square.contains(1, 1), isTrue);
      expect(square.contains(-1, 0), isFalse);
      expect(square.contains(2, 0), isFalse);
    });

    test('uses value equality and stable hashCode', () {
      final a = PathCenterPatternSize(width: 2, height: 3);
      final b = PathCenterPatternSize(width: 2, height: 3);
      final c = PathCenterPatternSize(width: 3, height: 2);

      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(c));
    });
  });

  group('PathCenterPatternCell', () {
    test('accepts non-negative local coordinates and frames', () {
      final cell = PathCenterPatternCell(
        localX: 1,
        localY: 2,
        frames: [_frame(sourceX: 4)],
      );

      expect(cell.localX, 1);
      expect(cell.localY, 2);
      expect(cell.frames, [_frame(sourceX: 4)]);
    });

    test('rejects negative coordinates and empty frames', () {
      expect(
        () => PathCenterPatternCell(
          localX: -1,
          localY: 0,
          frames: [_frame()],
        ),
        throwsArgumentError,
      );
      expect(
        () => PathCenterPatternCell(
          localX: 0,
          localY: -1,
          frames: [_frame()],
        ),
        throwsArgumentError,
      );
      expect(
        () => PathCenterPatternCell(localX: 0, localY: 0, frames: []),
        throwsArgumentError,
      );
    });

    test('defensively copies frames and exposes an immutable list', () {
      final frames = [_frame(sourceX: 1)];
      final cell = PathCenterPatternCell(
        localX: 0,
        localY: 0,
        frames: frames,
      );

      frames.add(_frame(sourceX: 2));

      expect(cell.frames, [_frame(sourceX: 1)]);
      expect(() => cell.frames.add(_frame(sourceX: 3)), throwsUnsupportedError);
    });

    test('uses value equality and stable hashCode', () {
      final a = PathCenterPatternCell(
        localX: 0,
        localY: 1,
        frames: [_frame(sourceX: 7)],
      );
      final b = PathCenterPatternCell(
        localX: 0,
        localY: 1,
        frames: [_frame(sourceX: 7)],
      );
      final c = PathCenterPatternCell(
        localX: 1,
        localY: 0,
        frames: [_frame(sourceX: 7)],
      );

      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(c));
    });
  });

  group('PathCenterPattern 1x1', () {
    test('accepts a complete single-cell grid', () {
      final cell = _cell(0, 0, sourceX: 3);
      final pattern = PathCenterPattern(
        size: PathCenterPatternSize(width: 1, height: 1),
        cells: [cell],
      );

      expect(pattern.cells, [cell]);
      expect(pattern.cellAt(0, 0), cell);
      expect(pattern.isSingleCell, isTrue);
      expect(pattern.isMultiCell, isFalse);
    });
  });

  group('PathCenterPattern 2x2', () {
    test('accepts a complete grid and exposes cells in row-major order', () {
      final topLeft = _cell(0, 0, sourceX: 0);
      final topRight = _cell(1, 0, sourceX: 1);
      final bottomLeft = _cell(0, 1, sourceX: 2);
      final bottomRight = _cell(1, 1, sourceX: 3);

      final pattern = PathCenterPattern(
        size: PathCenterPatternSize(width: 2, height: 2),
        cells: [bottomRight, topLeft, bottomLeft, topRight],
      );

      expect(pattern.cells, [topLeft, topRight, bottomLeft, bottomRight]);
      expect(pattern.cellAt(0, 0), topLeft);
      expect(pattern.cellAt(1, 0), topRight);
      expect(pattern.cellAt(0, 1), bottomLeft);
      expect(pattern.cellAt(1, 1), bottomRight);
      expect(pattern.isSingleCell, isFalse);
      expect(pattern.isMultiCell, isTrue);
    });

    test('defensively copies cells and exposes an immutable list', () {
      final cells = [
        _cell(0, 0, sourceX: 0),
        _cell(1, 0, sourceX: 1),
        _cell(0, 1, sourceX: 2),
        _cell(1, 1, sourceX: 3),
      ];
      final pattern = PathCenterPattern(
        size: PathCenterPatternSize(width: 2, height: 2),
        cells: cells,
      );

      cells[0] = _cell(0, 0, sourceX: 99);

      expect(pattern.cellAt(0, 0), _cell(0, 0, sourceX: 0));
      expect(() => pattern.cells.add(_cell(0, 0)), throwsUnsupportedError);
    });

    test('uses value equality and stable hashCode', () {
      final a = PathCenterPattern(
        size: PathCenterPatternSize(width: 2, height: 2),
        cells: [
          _cell(0, 0, sourceX: 0),
          _cell(1, 0, sourceX: 1),
          _cell(0, 1, sourceX: 2),
          _cell(1, 1, sourceX: 3),
        ],
      );
      final b = PathCenterPattern(
        size: PathCenterPatternSize(width: 2, height: 2),
        cells: [
          _cell(1, 1, sourceX: 3),
          _cell(0, 1, sourceX: 2),
          _cell(1, 0, sourceX: 1),
          _cell(0, 0, sourceX: 0),
        ],
      );
      final c = PathCenterPattern(
        size: PathCenterPatternSize(width: 1, height: 1),
        cells: [_cell(0, 0, sourceX: 0)],
      );

      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(c));
    });
  });

  group('PathCenterPattern invalid grids', () {
    test('rejects an empty cell list', () {
      expect(
        () => PathCenterPattern(
          size: PathCenterPatternSize(width: 1, height: 1),
          cells: [],
        ),
        throwsArgumentError,
      );
    });

    test('rejects a missing cell', () {
      expect(
        () => PathCenterPattern(
          size: PathCenterPatternSize(width: 2, height: 2),
          cells: [
            _cell(0, 0),
            _cell(1, 0),
            _cell(0, 1),
          ],
        ),
        throwsArgumentError,
      );
    });

    test('rejects a cell outside the grid', () {
      expect(
        () => PathCenterPattern(
          size: PathCenterPatternSize(width: 1, height: 1),
          cells: [_cell(0, 0), _cell(1, 0)],
        ),
        throwsArgumentError,
      );
    });

    test('rejects duplicate coordinates', () {
      expect(
        () => PathCenterPattern(
          size: PathCenterPatternSize(width: 1, height: 1),
          cells: [_cell(0, 0, sourceX: 0), _cell(0, 0, sourceX: 1)],
        ),
        throwsArgumentError,
      );
    });

    test('cellAt rejects coordinates outside the grid', () {
      final pattern = PathCenterPattern(
        size: PathCenterPatternSize(width: 1, height: 1),
        cells: [_cell(0, 0)],
      );

      expect(() => pattern.cellAt(-1, 0), throwsArgumentError);
      expect(() => pattern.cellAt(1, 0), throwsArgumentError);
      expect(() => pattern.cellAt(0, 1), throwsArgumentError);
    });
  });
}

PathCenterPatternCell _cell(int localX, int localY, {int sourceX = 0}) {
  return PathCenterPatternCell(
    localX: localX,
    localY: localY,
    frames: [_frame(sourceX: sourceX)],
  );
}

TilesetVisualFrame _frame({int sourceX = 0}) {
  return TilesetVisualFrame(
    source: TilesetSourceRect(x: sourceX, y: 0),
    durationMs: 100,
  );
}
```

### 15.3 `packages/map_core/lib/map_core.dart`

```dart
library map_core;

export 'src/models/enums.dart';
export 'src/models/geometry.dart';
export 'src/models/tileset.dart';
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

## 16. Evidence Pack — diffs complets

### 16.1 `packages/map_core/lib/map_core.dart`

```diff
diff --git a/packages/map_core/lib/map_core.dart b/packages/map_core/lib/map_core.dart
index e0ada9fe..9ae287e9 100644
--- a/packages/map_core/lib/map_core.dart
+++ b/packages/map_core/lib/map_core.dart
@@ -10,6 +10,7 @@ export 'src/models/map_entity_editor_visual.dart';
 export 'src/models/map_gameplay_zone_payloads.dart';
 export 'src/models/map_layer.dart';
 export 'src/models/map_metadata.dart';
+export 'src/models/path_center_pattern.dart';
 export 'src/models/project_manifest.dart';
 export 'src/models/save_data.dart';
 export 'src/models/game_state.dart';
```

### 16.2 `packages/map_core/lib/src/models/path_center_pattern.dart`

```diff
diff --git a/packages/map_core/lib/src/models/path_center_pattern.dart b/packages/map_core/lib/src/models/path_center_pattern.dart
new file mode 100644
index 00000000..2934d8e0
--- /dev/null
+++ b/packages/map_core/lib/src/models/path_center_pattern.dart
@@ -0,0 +1,224 @@
+import 'project_manifest.dart';
+
+/// Local size of a repeated path center pattern.
+final class PathCenterPatternSize {
+  factory PathCenterPatternSize({
+    required int width,
+    required int height,
+  }) {
+    if (width <= 0) {
+      throw ArgumentError.value(
+        width,
+        'width',
+        'PathCenterPatternSize width must be positive.',
+      );
+    }
+    if (height <= 0) {
+      throw ArgumentError.value(
+        height,
+        'height',
+        'PathCenterPatternSize height must be positive.',
+      );
+    }
+    return PathCenterPatternSize._(width: width, height: height);
+  }
+
+  const PathCenterPatternSize._({
+    required this.width,
+    required this.height,
+  });
+
+  final int width;
+  final int height;
+
+  int get tileCount => width * height;
+
+  bool contains(int localX, int localY) {
+    return localX >= 0 && localY >= 0 && localX < width && localY < height;
+  }
+
+  @override
+  bool operator ==(Object other) {
+    return identical(this, other) ||
+        other is PathCenterPatternSize &&
+            width == other.width &&
+            height == other.height;
+  }
+
+  @override
+  int get hashCode => Object.hash(width, height);
+}
+
+/// One local cell of a path center pattern.
+final class PathCenterPatternCell {
+  factory PathCenterPatternCell({
+    required int localX,
+    required int localY,
+    required List<TilesetVisualFrame> frames,
+  }) {
+    if (localX < 0) {
+      throw ArgumentError.value(
+        localX,
+        'localX',
+        'PathCenterPatternCell localX must be non-negative.',
+      );
+    }
+    if (localY < 0) {
+      throw ArgumentError.value(
+        localY,
+        'localY',
+        'PathCenterPatternCell localY must be non-negative.',
+      );
+    }
+    if (frames.isEmpty) {
+      throw ArgumentError.value(
+        frames,
+        'frames',
+        'PathCenterPatternCell frames must not be empty.',
+      );
+    }
+    return PathCenterPatternCell._(
+      localX: localX,
+      localY: localY,
+      frames: List.unmodifiable(frames),
+    );
+  }
+
+  const PathCenterPatternCell._({
+    required this.localX,
+    required this.localY,
+    required this.frames,
+  });
+
+  final int localX;
+  final int localY;
+  final List<TilesetVisualFrame> frames;
+
+  @override
+  bool operator ==(Object other) {
+    return identical(this, other) ||
+        other is PathCenterPatternCell &&
+            localX == other.localX &&
+            localY == other.localY &&
+            _listEquals(frames, other.frames);
+  }
+
+  @override
+  int get hashCode => Object.hash(localX, localY, Object.hashAll(frames));
+}
+
+/// Complete local pattern used for the fill center of a path surface.
+final class PathCenterPattern {
+  factory PathCenterPattern({
+    required PathCenterPatternSize size,
+    required List<PathCenterPatternCell> cells,
+  }) {
+    if (cells.isEmpty) {
+      throw ArgumentError.value(
+        cells,
+        'cells',
+        'PathCenterPattern cells must not be empty.',
+      );
+    }
+
+    final cellsByIndex = <int, PathCenterPatternCell>{};
+    for (final cell in cells) {
+      if (!size.contains(cell.localX, cell.localY)) {
+        throw ArgumentError.value(
+          cell,
+          'cells',
+          'PathCenterPattern has cell outside size at '
+              '${cell.localX},${cell.localY}.',
+        );
+      }
+
+      final index = _cellIndex(size, cell.localX, cell.localY);
+      if (cellsByIndex.containsKey(index)) {
+        throw ArgumentError.value(
+          cell,
+          'cells',
+          'PathCenterPattern has duplicate cell at '
+              '${cell.localX},${cell.localY}.',
+        );
+      }
+      cellsByIndex[index] = cell;
+    }
+
+    final orderedCells = <PathCenterPatternCell>[];
+    for (var y = 0; y < size.height; y += 1) {
+      for (var x = 0; x < size.width; x += 1) {
+        final index = _cellIndex(size, x, y);
+        final cell = cellsByIndex[index];
+        if (cell == null) {
+          throw ArgumentError.value(
+            cells,
+            'cells',
+            'PathCenterPattern has missing cell at $x,$y.',
+          );
+        }
+        orderedCells.add(cell);
+      }
+    }
+
+    return PathCenterPattern._(
+      size: size,
+      cells: List.unmodifiable(orderedCells),
+      cellsByIndex: Map.unmodifiable(cellsByIndex),
+    );
+  }
+
+  const PathCenterPattern._({
+    required this.size,
+    required this.cells,
+    required Map<int, PathCenterPatternCell> cellsByIndex,
+  }) : _cellsByIndex = cellsByIndex;
+
+  final PathCenterPatternSize size;
+  final List<PathCenterPatternCell> cells;
+  final Map<int, PathCenterPatternCell> _cellsByIndex;
+
+  bool get isSingleCell => size.tileCount == 1;
+
+  bool get isMultiCell => size.tileCount > 1;
+
+  PathCenterPatternCell cellAt(int localX, int localY) {
+    if (!size.contains(localX, localY)) {
+      throw ArgumentError.value(
+        '$localX,$localY',
+        'local coordinate',
+        'PathCenterPattern cellAt coordinate is outside size.',
+      );
+    }
+    return _cellsByIndex[_cellIndex(size, localX, localY)]!;
+  }
+
+  @override
+  bool operator ==(Object other) {
+    return identical(this, other) ||
+        other is PathCenterPattern &&
+            size == other.size &&
+            _listEquals(cells, other.cells);
+  }
+
+  @override
+  int get hashCode => Object.hash(size, Object.hashAll(cells));
+}
+
+int _cellIndex(PathCenterPatternSize size, int localX, int localY) {
+  return localY * size.width + localX;
+}
+
+bool _listEquals<T>(List<T> a, List<T> b) {
+  if (identical(a, b)) {
+    return true;
+  }
+  if (a.length != b.length) {
+    return false;
+  }
+  for (var index = 0; index < a.length; index += 1) {
+    if (a[index] != b[index]) {
+      return false;
+    }
+  }
+  return true;
+}
```

### 16.3 `packages/map_core/test/path_center_pattern_test.dart`

```diff
diff --git a/packages/map_core/test/path_center_pattern_test.dart b/packages/map_core/test/path_center_pattern_test.dart
new file mode 100644
index 00000000..c8a2ac72
--- /dev/null
+++ b/packages/map_core/test/path_center_pattern_test.dart
@@ -0,0 +1,288 @@
+import 'package:map_core/map_core.dart';
+import 'package:test/test.dart';
+
+void main() {
+  group('PathCenterPatternSize', () {
+    test('accepts 1x1 and 2x2 sizes', () {
+      final single = PathCenterPatternSize(width: 1, height: 1);
+      final square = PathCenterPatternSize(width: 2, height: 2);
+
+      expect(single.width, 1);
+      expect(single.height, 1);
+      expect(square.width, 2);
+      expect(square.height, 2);
+    });
+
+    test('rejects non-positive dimensions', () {
+      expect(
+        () => PathCenterPatternSize(width: 0, height: 1),
+        throwsArgumentError,
+      );
+      expect(
+        () => PathCenterPatternSize(width: 1, height: 0),
+        throwsArgumentError,
+      );
+      expect(
+        () => PathCenterPatternSize(width: -1, height: 1),
+        throwsArgumentError,
+      );
+      expect(
+        () => PathCenterPatternSize(width: 1, height: -1),
+        throwsArgumentError,
+      );
+    });
+
+    test('reports tile count and coordinate containment', () {
+      final single = PathCenterPatternSize(width: 1, height: 1);
+      final square = PathCenterPatternSize(width: 2, height: 2);
+
+      expect(single.tileCount, 1);
+      expect(square.tileCount, 4);
+      expect(single.contains(0, 0), isTrue);
+      expect(single.contains(1, 0), isFalse);
+      expect(single.contains(0, 1), isFalse);
+      expect(square.contains(1, 1), isTrue);
+      expect(square.contains(-1, 0), isFalse);
+      expect(square.contains(2, 0), isFalse);
+    });
+
+    test('uses value equality and stable hashCode', () {
+      final a = PathCenterPatternSize(width: 2, height: 3);
+      final b = PathCenterPatternSize(width: 2, height: 3);
+      final c = PathCenterPatternSize(width: 3, height: 2);
+
+      expect(a, b);
+      expect(a.hashCode, b.hashCode);
+      expect(a, isNot(c));
+    });
+  });
+
+  group('PathCenterPatternCell', () {
+    test('accepts non-negative local coordinates and frames', () {
+      final cell = PathCenterPatternCell(
+        localX: 1,
+        localY: 2,
+        frames: [_frame(sourceX: 4)],
+      );
+
+      expect(cell.localX, 1);
+      expect(cell.localY, 2);
+      expect(cell.frames, [_frame(sourceX: 4)]);
+    });
+
+    test('rejects negative coordinates and empty frames', () {
+      expect(
+        () => PathCenterPatternCell(
+          localX: -1,
+          localY: 0,
+          frames: [_frame()],
+        ),
+        throwsArgumentError,
+      );
+      expect(
+        () => PathCenterPatternCell(
+          localX: 0,
+          localY: -1,
+          frames: [_frame()],
+        ),
+        throwsArgumentError,
+      );
+      expect(
+        () => PathCenterPatternCell(localX: 0, localY: 0, frames: []),
+        throwsArgumentError,
+      );
+    });
+
+    test('defensively copies frames and exposes an immutable list', () {
+      final frames = [_frame(sourceX: 1)];
+      final cell = PathCenterPatternCell(
+        localX: 0,
+        localY: 0,
+        frames: frames,
+      );
+
+      frames.add(_frame(sourceX: 2));
+
+      expect(cell.frames, [_frame(sourceX: 1)]);
+      expect(() => cell.frames.add(_frame(sourceX: 3)), throwsUnsupportedError);
+    });
+
+    test('uses value equality and stable hashCode', () {
+      final a = PathCenterPatternCell(
+        localX: 0,
+        localY: 1,
+        frames: [_frame(sourceX: 7)],
+      );
+      final b = PathCenterPatternCell(
+        localX: 0,
+        localY: 1,
+        frames: [_frame(sourceX: 7)],
+      );
+      final c = PathCenterPatternCell(
+        localX: 1,
+        localY: 0,
+        frames: [_frame(sourceX: 7)],
+      );
+
+      expect(a, b);
+      expect(a.hashCode, b.hashCode);
+      expect(a, isNot(c));
+    });
+  });
+
+  group('PathCenterPattern 1x1', () {
+    test('accepts a complete single-cell grid', () {
+      final cell = _cell(0, 0, sourceX: 3);
+      final pattern = PathCenterPattern(
+        size: PathCenterPatternSize(width: 1, height: 1),
+        cells: [cell],
+      );
+
+      expect(pattern.cells, [cell]);
+      expect(pattern.cellAt(0, 0), cell);
+      expect(pattern.isSingleCell, isTrue);
+      expect(pattern.isMultiCell, isFalse);
+    });
+  });
+
+  group('PathCenterPattern 2x2', () {
+    test('accepts a complete grid and exposes cells in row-major order', () {
+      final topLeft = _cell(0, 0, sourceX: 0);
+      final topRight = _cell(1, 0, sourceX: 1);
+      final bottomLeft = _cell(0, 1, sourceX: 2);
+      final bottomRight = _cell(1, 1, sourceX: 3);
+
+      final pattern = PathCenterPattern(
+        size: PathCenterPatternSize(width: 2, height: 2),
+        cells: [bottomRight, topLeft, bottomLeft, topRight],
+      );
+
+      expect(pattern.cells, [topLeft, topRight, bottomLeft, bottomRight]);
+      expect(pattern.cellAt(0, 0), topLeft);
+      expect(pattern.cellAt(1, 0), topRight);
+      expect(pattern.cellAt(0, 1), bottomLeft);
+      expect(pattern.cellAt(1, 1), bottomRight);
+      expect(pattern.isSingleCell, isFalse);
+      expect(pattern.isMultiCell, isTrue);
+    });
+
+    test('defensively copies cells and exposes an immutable list', () {
+      final cells = [
+        _cell(0, 0, sourceX: 0),
+        _cell(1, 0, sourceX: 1),
+        _cell(0, 1, sourceX: 2),
+        _cell(1, 1, sourceX: 3),
+      ];
+      final pattern = PathCenterPattern(
+        size: PathCenterPatternSize(width: 2, height: 2),
+        cells: cells,
+      );
+
+      cells[0] = _cell(0, 0, sourceX: 99);
+
+      expect(pattern.cellAt(0, 0), _cell(0, 0, sourceX: 0));
+      expect(() => pattern.cells.add(_cell(0, 0)), throwsUnsupportedError);
+    });
+
+    test('uses value equality and stable hashCode', () {
+      final a = PathCenterPattern(
+        size: PathCenterPatternSize(width: 2, height: 2),
+        cells: [
+          _cell(0, 0, sourceX: 0),
+          _cell(1, 0, sourceX: 1),
+          _cell(0, 1, sourceX: 2),
+          _cell(1, 1, sourceX: 3),
+        ],
+      );
+      final b = PathCenterPattern(
+        size: PathCenterPatternSize(width: 2, height: 2),
+        cells: [
+          _cell(1, 1, sourceX: 3),
+          _cell(0, 1, sourceX: 2),
+          _cell(1, 0, sourceX: 1),
+          _cell(0, 0, sourceX: 0),
+        ],
+      );
+      final c = PathCenterPattern(
+        size: PathCenterPatternSize(width: 1, height: 1),
+        cells: [_cell(0, 0, sourceX: 0)],
+      );
+
+      expect(a, b);
+      expect(a.hashCode, b.hashCode);
+      expect(a, isNot(c));
+    });
+  });
+
+  group('PathCenterPattern invalid grids', () {
+    test('rejects an empty cell list', () {
+      expect(
+        () => PathCenterPattern(
+          size: PathCenterPatternSize(width: 1, height: 1),
+          cells: [],
+        ),
+        throwsArgumentError,
+      );
+    });
+
+    test('rejects a missing cell', () {
+      expect(
+        () => PathCenterPattern(
+          size: PathCenterPatternSize(width: 2, height: 2),
+          cells: [
+            _cell(0, 0),
+            _cell(1, 0),
+            _cell(0, 1),
+          ],
+        ),
+        throwsArgumentError,
+      );
+    });
+
+    test('rejects a cell outside the grid', () {
+      expect(
+        () => PathCenterPattern(
+          size: PathCenterPatternSize(width: 1, height: 1),
+          cells: [_cell(0, 0), _cell(1, 0)],
+        ),
+        throwsArgumentError,
+      );
+    });
+
+    test('rejects duplicate coordinates', () {
+      expect(
+        () => PathCenterPattern(
+          size: PathCenterPatternSize(width: 1, height: 1),
+          cells: [_cell(0, 0, sourceX: 0), _cell(0, 0, sourceX: 1)],
+        ),
+        throwsArgumentError,
+      );
+    });
+
+    test('cellAt rejects coordinates outside the grid', () {
+      final pattern = PathCenterPattern(
+        size: PathCenterPatternSize(width: 1, height: 1),
+        cells: [_cell(0, 0)],
+      );
+
+      expect(() => pattern.cellAt(-1, 0), throwsArgumentError);
+      expect(() => pattern.cellAt(1, 0), throwsArgumentError);
+      expect(() => pattern.cellAt(0, 1), throwsArgumentError);
+    });
+  });
+}
+
+PathCenterPatternCell _cell(int localX, int localY, {int sourceX = 0}) {
+  return PathCenterPatternCell(
+    localX: localX,
+    localY: localY,
+    frames: [_frame(sourceX: sourceX)],
+  );
+}
+
+TilesetVisualFrame _frame({int sourceX = 0}) {
+  return TilesetVisualFrame(
+    source: TilesetSourceRect(x: sourceX, y: 0),
+    durationMs: 100,
+  );
+}
```

## 17. Git status final

Commande :

```bash
git status --short --untracked-files=all
```

Sortie :

```text
 M packages/map_core/lib/map_core.dart
?? packages/map_core/lib/src/models/path_center_pattern.dart
?? packages/map_core/test/path_center_pattern_test.dart
?? reports/pathPattern/path_pattern_lot_01_center_pattern_value_objects.md
```

## 18. Auto-review

- Ai-je gardé le modèle non persistant ? Oui. Aucun id, name, tilesetId global, manifest, codec ou JSON.
- Ai-je évité `ProjectManifest` ? Oui. Aucun fichier manifest modifié.
- Ai-je évité `ProjectPathPreset` ? Oui. Aucun adapter ni modification du preset existant.
- Ai-je évité JSON/generated/build_runner ? Oui. Aucun codec, aucun generated, aucune génération.
- Ai-je évité runtime/gameplay/battle ? Oui. Aucun fichier dans ces packages.
- Ai-je testé 1×1 et 2×2 ? Oui, dans `path_center_pattern_test.dart`.
- Ai-je empêché cellules manquantes, doublons et hors grille ? Oui, par validation constructeur et tests dédiés.

## 19. Critique du prompt

- Ambiguïté : le prompt proposait des constructeurs `const`, mais demandait aussi validation par exceptions et copies défensives. J’ai choisi des factories publiques non `const`, avec constructeurs privés `const`, pour respecter la validation runtime.
- Décision prise : l’ordre exposé par `PathCenterPattern.cells` est row-major, pas l’ordre d’entrée. Cela rend l’égalité stable pour deux motifs équivalents fournis dans des ordres différents.
- Point à valider avant Lot 2 : décider si le resolver doit gérer les coordonnées négatives avec modulo positif ou les rejeter.
- Point à valider avant Lot 2 : décider si la résolution doit utiliser les coordonnées absolues map dès V0, comme recommandé au Lot 0, ou recevoir plus tard un offset de composante peinte.
