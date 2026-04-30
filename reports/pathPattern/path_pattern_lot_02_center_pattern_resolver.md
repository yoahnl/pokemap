# Lot PathPattern-2 — Center Pattern Resolver V0

## 1. Verdict

Accepté côté implémentation locale.

Le lot ajoute une opération pure :

```dart
PathCenterPatternCellResolution resolvePathCenterPatternCell({
  required PathCenterPattern pattern,
  required int mapX,
  required int mapY,
})
```

Elle résout :

```text
coordonnées absolues mapX/mapY -> coordonnées locales localX/localY -> cellule du motif
```

Le resolver reste débranché du système legacy. Il ne modifie aucun modèle persistant, aucun manifest, aucun codec, aucun runtime et aucun gameplay.

## 2. Audit initial

### Commandes initiales

```bash
pwd
git status --short --untracked-files=all
git diff --stat
rg -n "PathCenterPattern|PathCenterPatternCell|PathCenterPatternSize|cellAt|mapX|mapY|resolve.*Pattern|resolve.*Center|TileVisualFrameTimeline|resolveTileVisualFrameTimeline" packages/map_core/lib packages/map_core/test
```

### Sortie `pwd`

```text
/Users/karim/Project/pokemonProject
```

### Sortie `git status --short --untracked-files=all` initiale

```text
 M packages/map_core/lib/map_core.dart
?? packages/map_core/lib/src/models/path_center_pattern.dart
?? packages/map_core/test/path_center_pattern_test.dart
?? reports/pathPattern/path_pattern_lot_01_center_pattern_value_objects.md
```

Ces changements correspondent au Lot 1 non commité dans le worktree au début du Lot 2.

### Sortie `git diff --stat` initiale

```text
 packages/map_core/lib/map_core.dart | 1 +
 1 file changed, 1 insertion(+)
```

### Context Mode

Le binaire `ctx` n’est pas disponible dans le shell local :

```bash
command -v ctx
```

Sortie :

```text

```

Le serveur Context Mode est disponible et a été utilisé pour l’audit large. Stats au moment de l’audit :

```text
830.1K tokens saved  ·  80.4% reduction  ·  20h 52m

Without context-mode  |████████████████████████████████████████| 3.9 MB
With context-mode     |████████░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░| 789.4 KB

3.2 MB kept out of your conversation. Never entered context.

146 calls

  ctx_batch_execute         44 calls    2.2 MB saved
  ctx_search                15 calls  379.6 KB saved
  ctx_execute               61 calls  360.7 KB saved
  ctx_execute_file          15 calls  140.9 KB saved
  ctx_fetch_and_index        3 calls   40.3 KB saved
  ctx_stats                  8 calls   23.0 KB saved

v1.0.103
```

## 3. Réponses à l’audit

### 3.1 Où sont définis les types Lot 1 ?

Les types sont définis dans :

```text
packages/map_core/lib/src/models/path_center_pattern.dart
```

Types :

```text
PathCenterPatternSize
PathCenterPatternCell
PathCenterPattern
```

### 3.2 Est-ce que `PathCenterPattern` expose déjà `cellAt(localX, localY)` ?

Oui. `PathCenterPattern.cellAt(localX, localY)` existe et rejette les coordonnées locales hors grille via `ArgumentError`.

### 3.3 Quelle règle d’ordre des cellules est garantie ?

Le Lot 1 normalise l’ordre exposé des cellules en row-major :

```text
(0,0), (1,0), ..., (0,1), (1,1), ...
```

Le resolver s’appuie sur `cellAt` et ne dépend pas de l’ordre d’entrée fourni au constructeur.

### 3.4 Où placer une opération pure de résolution ?

Emplacement choisi :

```text
packages/map_core/lib/src/operations/path_center_pattern_resolver.dart
```

Justification :

- la résolution est une opération pure sur des value objects ;
- elle ne modifie pas le modèle ;
- elle ne nécessite ni rendu ni persistance ;
- elle rejoint les opérations pures déjà présentes dans `packages/map_core/lib/src/operations/`.

### 3.5 Objet résultat ou retour direct cellule ?

Un objet résultat a été créé :

```dart
PathCenterPatternCellResolution
```

Justification :

- conserve `mapX/mapY` pour debug et tests ;
- expose `localX/localY` pour preview et futures UI ;
- retourne la `cell` sans la copier ;
- reste libre de toute frame temporelle ou variant legacy.

### 3.6 Pourquoi les coordonnées négatives sont interdites en V0 ?

Le contrat V0 interdit :

```text
mapX < 0
mapY < 0
```

Raison :

- éviter d’introduire une convention de modulo positif prématurée ;
- garder une API simple et explicite ;
- refléter les coordonnées de map attendues côté editor/runtime existants ;
- repousser le traitement d’éventuels offsets ou coordonnées relatives à un lot dédié.

### 3.7 Tests du Lot 1 relancés

Le test Lot 1 relancé :

```text
packages/map_core/test/path_center_pattern_test.dart
```

## 4. Fichiers créés / modifiés / supprimés

### Créés

```text
packages/map_core/lib/src/operations/path_center_pattern_resolver.dart
packages/map_core/test/path_center_pattern_resolver_test.dart
reports/pathPattern/path_pattern_lot_02_center_pattern_resolver.md
```

### Modifiés

```text
packages/map_core/lib/map_core.dart
```

### Supprimés

```text
aucun
```

## 5. API ajoutée

### `PathCenterPatternCellResolution`

Champs :

```text
mapX
mapY
localX
localY
cell
```

Propriétés :

- égalité de valeur ;
- `hashCode` cohérent ;
- ne copie pas la cellule ;
- ne résout pas les frames ;
- ne contient pas de temps écoulé ;
- ne contient pas de variant legacy.

### `resolvePathCenterPatternCell`

Contrat :

```text
mapX >= 0
mapY >= 0
localX = mapX % pattern.size.width
localY = mapY % pattern.size.height
cell = pattern.cellAt(localX, localY)
```

## 6. Règle de résolution mapX/mapY -> localX/localY

La règle implémentée est le modulo sur coordonnées absolues :

```dart
final localX = mapX % pattern.size.width;
final localY = mapY % pattern.size.height;
```

Exemple 2×2 :

```text
0,0 -> 0,0
1,0 -> 1,0
0,1 -> 0,1
1,1 -> 1,1
2,0 -> 0,0
3,1 -> 1,1
```

Exemple 3×2 :

```text
5,2 -> 2,0
```

## 7. Décision sur coordonnées négatives

Les coordonnées négatives sont rejetées :

```dart
if (mapX < 0) {
  throw ArgumentError.value(
    mapX,
    'mapX',
    'PathCenterPattern mapX must be non-negative.',
  );
}
```

Même logique pour `mapY`.

Il n’y a pas de modulo positif pour coordonnées négatives dans ce lot.

## 8. Décision coordonnées absolues vs relatives

Décision V0 :

```text
coordonnées absolues de map
```

Pas d’origine de composante peinte, pas d’offset de région, pas de scan de zone connectée.

Limite :

```text
si un futur produit veut que chaque zone peinte redémarre son motif à sa propre origine,
il faudra ajouter explicitement un offset dans un lot ultérieur.
```

## 9. Tests lancés

### 9.1 TDD rouge initial

Commande :

```bash
cd packages/map_core && dart test test/path_center_pattern_resolver_test.dart --reporter expanded
```

Sortie :

```text
00:00 +0: loading test/path_center_pattern_resolver_test.dart
00:00 +0 -1: loading test/path_center_pattern_resolver_test.dart [E]
  Failed to load "test/path_center_pattern_resolver_test.dart":
  test/path_center_pattern_resolver_test.dart:52:15: Error: Method not found: 'resolvePathCenterPatternCell'.
          () => resolvePathCenterPatternCell(
                ^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  test/path_center_pattern_resolver_test.dart:60:15: Error: Method not found: 'resolvePathCenterPatternCell'.
          () => resolvePathCenterPatternCell(
                ^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  test/path_center_pattern_resolver_test.dart:68:15: Error: Method not found: 'resolvePathCenterPatternCell'.
          () => resolvePathCenterPatternCell(
                ^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  test/path_center_pattern_resolver_test.dart:82:26: Error: Method not found: 'resolvePathCenterPatternCell'.
        final resolution = resolvePathCenterPatternCell(
                           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  test/path_center_pattern_resolver_test.dart:100:17: Error: Method not found: 'resolvePathCenterPatternCell'.
        final a = resolvePathCenterPatternCell(
                  ^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  test/path_center_pattern_resolver_test.dart:105:17: Error: Method not found: 'PathCenterPatternCellResolution'.
        final b = PathCenterPatternCellResolution(
                  ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  test/path_center_pattern_resolver_test.dart:112:17: Error: Method not found: 'PathCenterPatternCellResolution'.
        final c = PathCenterPatternCellResolution(
                  ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  test/path_center_pattern_resolver_test.dart:134:22: Error: Method not found: 'resolvePathCenterPatternCell'.
    final resolution = resolvePathCenterPatternCell(
                       ^^^^^^^^^^^^^^^^^^^^^^^^^^^^
00:00 +0 -1: Some tests failed.
```

### 9.2 Test ciblé final

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

### 9.3 Régression Lot 1

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

### 9.4 Régression Lot 0

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

### 9.5 Suite complète `map_core`

Commande :

```bash
cd packages/map_core && dart test
```

Ligne finale exacte :

```text
00:02 +1050: All tests passed!
```

## 10. Analyze

Commande :

```bash
cd packages/map_core && dart analyze lib/src/operations/path_center_pattern_resolver.dart test/path_center_pattern_resolver_test.dart
```

Sortie :

```text
Analyzing path_center_pattern_resolver.dart, path_center_pattern_resolver_test.dart...
No issues found!
```

## 11. Non-objectifs confirmés

Confirmé :

- aucune UI créée ;
- aucune entrée studio créée ;
- aucun adapter de preset legacy ;
- aucun branchement sur le variant intérieur legacy ;
- aucune modification du resolver legacy ;
- aucune modification du manifest ;
- aucune modification des presets path existants ;
- aucun JSON ;
- aucun codec ;
- aucun fichier généré ;
- aucun `build_runner` ;
- aucune modification runtime ;
- aucune modification gameplay ;
- aucune modification battle ;
- aucun traitement de transparence ;
- aucune résolution temporelle des frames.

## 12. Limites restantes

- Le resolver n’est pas encore branché au système d’autotile existant.
- Le resolver ne gère pas d’offset de région peinte.
- Les coordonnées négatives sont rejetées, pas normalisées.
- Les frames ne sont pas résolues temporellement.
- Aucun adapter de preset legacy n’existe encore.

## 13. Git status final

Commande :

```bash
git status --short --untracked-files=all
```

Sortie :

```text
 M packages/map_core/lib/map_core.dart
?? packages/map_core/lib/src/models/path_center_pattern.dart
?? packages/map_core/lib/src/operations/path_center_pattern_resolver.dart
?? packages/map_core/test/path_center_pattern_resolver_test.dart
?? packages/map_core/test/path_center_pattern_test.dart
?? reports/pathPattern/path_pattern_lot_01_center_pattern_value_objects.md
?? reports/pathPattern/path_pattern_lot_02_center_pattern_resolver.md
```

## 14. Prochain lot recommandé

```text
PathPattern-3 — Legacy ProjectPathPreset Adapter V0
```

Objectif :

```text
adapter les presets path existants en motif centre 1×1 sans modifier leur modèle ni leur JSON.
```

## 15. Evidence Pack — contenus complets des fichiers créés / modifiés

### 15.1 `packages/map_core/lib/src/operations/path_center_pattern_resolver.dart`

```dart
import '../models/path_center_pattern.dart';

/// Result of resolving a map coordinate into a local center-pattern cell.
final class PathCenterPatternCellResolution {
  const PathCenterPatternCellResolution({
    required this.mapX,
    required this.mapY,
    required this.localX,
    required this.localY,
    required this.cell,
  });

  final int mapX;
  final int mapY;
  final int localX;
  final int localY;
  final PathCenterPatternCell cell;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is PathCenterPatternCellResolution &&
            mapX == other.mapX &&
            mapY == other.mapY &&
            localX == other.localX &&
            localY == other.localY &&
            cell == other.cell;
  }

  @override
  int get hashCode => Object.hash(mapX, mapY, localX, localY, cell);
}

/// Resolves a [PathCenterPattern] cell from absolute map coordinates.
///
/// V0 intentionally rejects negative map coordinates instead of applying
/// positive modulo. Pattern origin is the absolute map origin, not a painted
/// region origin.
PathCenterPatternCellResolution resolvePathCenterPatternCell({
  required PathCenterPattern pattern,
  required int mapX,
  required int mapY,
}) {
  if (mapX < 0) {
    throw ArgumentError.value(
      mapX,
      'mapX',
      'PathCenterPattern mapX must be non-negative.',
    );
  }
  if (mapY < 0) {
    throw ArgumentError.value(
      mapY,
      'mapY',
      'PathCenterPattern mapY must be non-negative.',
    );
  }

  final localX = mapX % pattern.size.width;
  final localY = mapY % pattern.size.height;

  return PathCenterPatternCellResolution(
    mapX: mapX,
    mapY: mapY,
    localX: localX,
    localY: localY,
    cell: pattern.cellAt(localX, localY),
  );
}
```

### 15.2 `packages/map_core/test/path_center_pattern_resolver_test.dart`

```dart
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('resolvePathCenterPatternCell 1x1', () {
    test('always resolves to the single local cell', () {
      final pattern = _pattern(width: 1, height: 1);

      _expectResolution(pattern, mapX: 0, mapY: 0, localX: 0, localY: 0);
      _expectResolution(pattern, mapX: 1, mapY: 0, localX: 0, localY: 0);
      _expectResolution(pattern, mapX: 0, mapY: 1, localX: 0, localY: 0);
      _expectResolution(pattern, mapX: 99, mapY: 42, localX: 0, localY: 0);
    });
  });

  group('resolvePathCenterPatternCell 2x2', () {
    test('uses absolute map coordinates modulo pattern size', () {
      final pattern = _pattern(width: 2, height: 2);

      _expectResolution(pattern, mapX: 0, mapY: 0, localX: 0, localY: 0);
      _expectResolution(pattern, mapX: 1, mapY: 0, localX: 1, localY: 0);
      _expectResolution(pattern, mapX: 0, mapY: 1, localX: 0, localY: 1);
      _expectResolution(pattern, mapX: 1, mapY: 1, localX: 1, localY: 1);
      _expectResolution(pattern, mapX: 2, mapY: 0, localX: 0, localY: 0);
      _expectResolution(pattern, mapX: 3, mapY: 0, localX: 1, localY: 0);
      _expectResolution(pattern, mapX: 2, mapY: 1, localX: 0, localY: 1);
      _expectResolution(pattern, mapX: 3, mapY: 1, localX: 1, localY: 1);
      _expectResolution(pattern, mapX: 4, mapY: 4, localX: 0, localY: 0);
      _expectResolution(pattern, mapX: 5, mapY: 4, localX: 1, localY: 0);
    });
  });

  group('resolvePathCenterPatternCell rectangular 3x2', () {
    test('does not assume square patterns', () {
      final pattern = _pattern(width: 3, height: 2);

      _expectResolution(pattern, mapX: 0, mapY: 0, localX: 0, localY: 0);
      _expectResolution(pattern, mapX: 1, mapY: 0, localX: 1, localY: 0);
      _expectResolution(pattern, mapX: 2, mapY: 0, localX: 2, localY: 0);
      _expectResolution(pattern, mapX: 3, mapY: 0, localX: 0, localY: 0);
      _expectResolution(pattern, mapX: 4, mapY: 1, localX: 1, localY: 1);
      _expectResolution(pattern, mapX: 5, mapY: 1, localX: 2, localY: 1);
      _expectResolution(pattern, mapX: 5, mapY: 2, localX: 2, localY: 0);
    });
  });

  group('resolvePathCenterPatternCell invalid coordinates', () {
    test('rejects negative map coordinates', () {
      final pattern = _pattern(width: 2, height: 2);

      expect(
        () => resolvePathCenterPatternCell(
          pattern: pattern,
          mapX: -1,
          mapY: 0,
        ),
        throwsArgumentError,
      );
      expect(
        () => resolvePathCenterPatternCell(
          pattern: pattern,
          mapX: 0,
          mapY: -1,
        ),
        throwsArgumentError,
      );
      expect(
        () => resolvePathCenterPatternCell(
          pattern: pattern,
          mapX: -1,
          mapY: -1,
        ),
        throwsArgumentError,
      );
    });
  });

  group('PathCenterPatternCellResolution', () {
    test('keeps map coordinates, local coordinates, and selected cell', () {
      final pattern = _pattern(width: 2, height: 2);

      final resolution = resolvePathCenterPatternCell(
        pattern: pattern,
        mapX: 5,
        mapY: 4,
      );

      expect(resolution.mapX, 5);
      expect(resolution.mapY, 4);
      expect(resolution.localX, 1);
      expect(resolution.localY, 0);
      expect(resolution.cell, pattern.cellAt(1, 0));
      expect(resolution.cell.frames.single.source.x, 1);
    });

    test('uses value equality and stable hashCode', () {
      final pattern = _pattern(width: 2, height: 2);
      final cell = pattern.cellAt(1, 0);

      final a = resolvePathCenterPatternCell(
        pattern: pattern,
        mapX: 5,
        mapY: 4,
      );
      final b = PathCenterPatternCellResolution(
        mapX: 5,
        mapY: 4,
        localX: 1,
        localY: 0,
        cell: cell,
      );
      final c = PathCenterPatternCellResolution(
        mapX: 4,
        mapY: 4,
        localX: 0,
        localY: 0,
        cell: pattern.cellAt(0, 0),
      );

      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(c));
    });
  });
}

void _expectResolution(
  PathCenterPattern pattern, {
  required int mapX,
  required int mapY,
  required int localX,
  required int localY,
}) {
  final resolution = resolvePathCenterPatternCell(
    pattern: pattern,
    mapX: mapX,
    mapY: mapY,
  );

  expect(resolution.mapX, mapX);
  expect(resolution.mapY, mapY);
  expect(resolution.localX, localX);
  expect(resolution.localY, localY);
  expect(resolution.cell, pattern.cellAt(localX, localY));
  expect(resolution.cell.frames.single.source.x, _sourceX(localX, localY));
}

PathCenterPattern _pattern({required int width, required int height}) {
  return PathCenterPattern(
    size: PathCenterPatternSize(width: width, height: height),
    cells: [
      for (var y = 0; y < height; y += 1)
        for (var x = 0; x < width; x += 1) _cell(x, y),
    ],
  );
}

PathCenterPatternCell _cell(int localX, int localY) {
  return PathCenterPatternCell(
    localX: localX,
    localY: localY,
    frames: [
      TilesetVisualFrame(
        source: TilesetSourceRect(x: _sourceX(localX, localY), y: 0),
        durationMs: 100,
      ),
    ],
  );
}

int _sourceX(int localX, int localY) => localY * 10 + localX;
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
export 'src/operations/path_center_pattern_resolver.dart';
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
index e0ada9fe..6561b522 100644
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
@@ -30,6 +31,7 @@ export 'src/operations/map_collision.dart';
 export 'src/operations/map_path.dart';
 export 'src/operations/map_terrain.dart';
 export 'src/operations/map_terrain_autotile.dart';
+export 'src/operations/path_center_pattern_resolver.dart';
 export 'src/operations/tile_visual_frame_timeline.dart';
 export 'src/operations/tile_visual_frame_vertical_atlas.dart';
 export 'src/operations/path_variant_vertical_atlas_mapping.dart';
```

Note : l’export `path_center_pattern.dart` provient du Lot 1 déjà présent dans le worktree ; l’export `path_center_pattern_resolver.dart` est l’ajout du Lot 2.

### 16.2 `packages/map_core/lib/src/operations/path_center_pattern_resolver.dart`

```diff
diff --git a/packages/map_core/lib/src/operations/path_center_pattern_resolver.dart b/packages/map_core/lib/src/operations/path_center_pattern_resolver.dart
new file mode 100644
index 00000000..6518b5e3
--- /dev/null
+++ b/packages/map_core/lib/src/operations/path_center_pattern_resolver.dart
@@ -0,0 +1,69 @@
+import '../models/path_center_pattern.dart';
+
+/// Result of resolving a map coordinate into a local center-pattern cell.
+final class PathCenterPatternCellResolution {
+  const PathCenterPatternCellResolution({
+    required this.mapX,
+    required this.mapY,
+    required this.localX,
+    required this.localY,
+    required this.cell,
+  });
+
+  final int mapX;
+  final int mapY;
+  final int localX;
+  final int localY;
+  final PathCenterPatternCell cell;
+
+  @override
+  bool operator ==(Object other) {
+    return identical(this, other) ||
+        other is PathCenterPatternCellResolution &&
+            mapX == other.mapX &&
+            mapY == other.mapY &&
+            localX == other.localX &&
+            localY == other.localY &&
+            cell == other.cell;
+  }
+
+  @override
+  int get hashCode => Object.hash(mapX, mapY, localX, localY, cell);
+}
+
+/// Resolves a [PathCenterPattern] cell from absolute map coordinates.
+///
+/// V0 intentionally rejects negative map coordinates instead of applying
+/// positive modulo. Pattern origin is the absolute map origin, not a painted
+/// region origin.
+PathCenterPatternCellResolution resolvePathCenterPatternCell({
+  required PathCenterPattern pattern,
+  required int mapX,
+  required int mapY,
+}) {
+  if (mapX < 0) {
+    throw ArgumentError.value(
+      mapX,
+      'mapX',
+      'PathCenterPattern mapX must be non-negative.',
+    );
+  }
+  if (mapY < 0) {
+    throw ArgumentError.value(
+      mapY,
+      'mapY',
+      'PathCenterPattern mapY must be non-negative.',
+    );
+  }
+
+  final localX = mapX % pattern.size.width;
+  final localY = mapY % pattern.size.height;
+
+  return PathCenterPatternCellResolution(
+    mapX: mapX,
+    mapY: mapY,
+    localX: localX,
+    localY: localY,
+    cell: pattern.cellAt(localX, localY),
+  );
+}
```

### 16.3 `packages/map_core/test/path_center_pattern_resolver_test.dart`

```diff
diff --git a/packages/map_core/test/path_center_pattern_resolver_test.dart b/packages/map_core/test/path_center_pattern_resolver_test.dart
new file mode 100644
index 00000000..bcfd2e97
--- /dev/null
+++ b/packages/map_core/test/path_center_pattern_resolver_test.dart
@@ -0,0 +1,171 @@
+import 'package:map_core/map_core.dart';
+import 'package:test/test.dart';
+
+void main() {
+  group('resolvePathCenterPatternCell 1x1', () {
+    test('always resolves to the single local cell', () {
+      final pattern = _pattern(width: 1, height: 1);
+
+      _expectResolution(pattern, mapX: 0, mapY: 0, localX: 0, localY: 0);
+      _expectResolution(pattern, mapX: 1, mapY: 0, localX: 0, localY: 0);
+      _expectResolution(pattern, mapX: 0, mapY: 1, localX: 0, localY: 0);
+      _expectResolution(pattern, mapX: 99, mapY: 42, localX: 0, localY: 0);
+    });
+  });
+
+  group('resolvePathCenterPatternCell 2x2', () {
+    test('uses absolute map coordinates modulo pattern size', () {
+      final pattern = _pattern(width: 2, height: 2);
+
+      _expectResolution(pattern, mapX: 0, mapY: 0, localX: 0, localY: 0);
+      _expectResolution(pattern, mapX: 1, mapY: 0, localX: 1, localY: 0);
+      _expectResolution(pattern, mapX: 0, mapY: 1, localX: 0, localY: 1);
+      _expectResolution(pattern, mapX: 1, mapY: 1, localX: 1, localY: 1);
+      _expectResolution(pattern, mapX: 2, mapY: 0, localX: 0, localY: 0);
+      _expectResolution(pattern, mapX: 3, mapY: 0, localX: 1, localY: 0);
+      _expectResolution(pattern, mapX: 2, mapY: 1, localX: 0, localY: 1);
+      _expectResolution(pattern, mapX: 3, mapY: 1, localX: 1, localY: 1);
+      _expectResolution(pattern, mapX: 4, mapY: 4, localX: 0, localY: 0);
+      _expectResolution(pattern, mapX: 5, mapY: 4, localX: 1, localY: 0);
+    });
+  });
+
+  group('resolvePathCenterPatternCell rectangular 3x2', () {
+    test('does not assume square patterns', () {
+      final pattern = _pattern(width: 3, height: 2);
+
+      _expectResolution(pattern, mapX: 0, mapY: 0, localX: 0, localY: 0);
+      _expectResolution(pattern, mapX: 1, mapY: 0, localX: 1, localY: 0);
+      _expectResolution(pattern, mapX: 2, mapY: 0, localX: 2, localY: 0);
+      _expectResolution(pattern, mapX: 3, mapY: 0, localX: 0, localY: 0);
+      _expectResolution(pattern, mapX: 4, mapY: 1, localX: 1, localY: 1);
+      _expectResolution(pattern, mapX: 5, mapY: 1, localX: 2, localY: 1);
+      _expectResolution(pattern, mapX: 5, mapY: 2, localX: 2, localY: 0);
+    });
+  });
+
+  group('resolvePathCenterPatternCell invalid coordinates', () {
+    test('rejects negative map coordinates', () {
+      final pattern = _pattern(width: 2, height: 2);
+
+      expect(
+        () => resolvePathCenterPatternCell(
+          pattern: pattern,
+          mapX: -1,
+          mapY: 0,
+        ),
+        throwsArgumentError,
+      );
+      expect(
+        () => resolvePathCenterPatternCell(
+          pattern: pattern,
+          mapX: 0,
+          mapY: -1,
+        ),
+        throwsArgumentError,
+      );
+      expect(
+        () => resolvePathCenterPatternCell(
+          pattern: pattern,
+          mapX: -1,
+          mapY: -1,
+        ),
+        throwsArgumentError,
+      );
+    });
+  });
+
+  group('PathCenterPatternCellResolution', () {
+    test('keeps map coordinates, local coordinates, and selected cell', () {
+      final pattern = _pattern(width: 2, height: 2);
+
+      final resolution = resolvePathCenterPatternCell(
+        pattern: pattern,
+        mapX: 5,
+        mapY: 4,
+      );
+
+      expect(resolution.mapX, 5);
+      expect(resolution.mapY, 4);
+      expect(resolution.localX, 1);
+      expect(resolution.localY, 0);
+      expect(resolution.cell, pattern.cellAt(1, 0));
+      expect(resolution.cell.frames.single.source.x, 1);
+    });
+
+    test('uses value equality and stable hashCode', () {
+      final pattern = _pattern(width: 2, height: 2);
+      final cell = pattern.cellAt(1, 0);
+
+      final a = resolvePathCenterPatternCell(
+        pattern: pattern,
+        mapX: 5,
+        mapY: 4,
+      );
+      final b = PathCenterPatternCellResolution(
+        mapX: 5,
+        mapY: 4,
+        localX: 1,
+        localY: 0,
+        cell: cell,
+      );
+      final c = PathCenterPatternCellResolution(
+        mapX: 4,
+        mapY: 4,
+        localX: 0,
+        localY: 0,
+        cell: pattern.cellAt(0, 0),
+      );
+
+      expect(a, b);
+      expect(a.hashCode, b.hashCode);
+      expect(a, isNot(c));
+    });
+  });
+}
+
+void _expectResolution(
+  PathCenterPattern pattern, {
+  required int mapX,
+  required int mapY,
+  required int localX,
+  required int localY,
+}) {
+  final resolution = resolvePathCenterPatternCell(
+    pattern: pattern,
+    mapX: mapX,
+    mapY: mapY,
+  );
+
+  expect(resolution.mapX, mapX);
+  expect(resolution.mapY, mapY);
+  expect(resolution.localX, localX);
+  expect(resolution.localY, localY);
+  expect(resolution.cell, pattern.cellAt(localX, localY));
+  expect(resolution.cell.frames.single.source.x, _sourceX(localX, localY));
+}
+
+PathCenterPattern _pattern({required int width, required int height}) {
+  return PathCenterPattern(
+    size: PathCenterPatternSize(width: width, height: height),
+    cells: [
+      for (var y = 0; y < height; y += 1)
+        for (var x = 0; x < width; x += 1) _cell(x, y),
+    ],
+  );
+}
+
+PathCenterPatternCell _cell(int localX, int localY) {
+  return PathCenterPatternCell(
+    localX: localX,
+    localY: localY,
+    frames: [
+      TilesetVisualFrame(
+        source: TilesetSourceRect(x: _sourceX(localX, localY), y: 0),
+        durationMs: 100,
+      ),
+    ],
+  );
+}
+
+int _sourceX(int localX, int localY) => localY * 10 + localX;
```

## 17. Audit no accidental coupling

Commande :

```bash
rg -n "map_runtime|map_gameplay|map_battle|ProjectManifest|ProjectPathPreset|TerrainPathVariant|toJson|fromJson|transparentColor|PathStudio" packages/map_core/lib/src/operations/path_center_pattern_resolver.dart packages/map_core/test/path_center_pattern_resolver_test.dart
```

Sortie :

```text

```

## 18. Auto-review

- Ai-je gardé le resolver pur ? Oui. Il dépend seulement des value objects du Lot 1.
- Ai-je évité `ProjectManifest` ? Oui.
- Ai-je évité `ProjectPathPreset` ? Oui.
- Ai-je évité `TerrainPathVariant` ? Oui.
- Ai-je évité JSON/generated/build_runner ? Oui.
- Ai-je évité runtime/gameplay/battle ? Oui.
- Ai-je testé 1×1, 2×2 et rectangulaire ? Oui.
- Ai-je documenté le choix sur coordonnées négatives ? Oui, elles sont rejetées en V0.

## 19. Critique du prompt

- Ambiguïté faible : le prompt autorisait un retour direct `PathCenterPatternCell`, mais recommandait un objet résultat. J’ai suivi la recommandation.
- Choix de nom : les noms proposés ont été conservés.
- Décision à valider avant Lot 3 : le futur adapter legacy devra décider quel mapping de variant existant alimente le motif centre 1×1, en respectant la caractérisation de l’intérieur plein.
- Décision à valider plus tard : si l’offset par zone peinte devient nécessaire, il devra être explicite et ne doit pas remplacer silencieusement le mode absolu.
