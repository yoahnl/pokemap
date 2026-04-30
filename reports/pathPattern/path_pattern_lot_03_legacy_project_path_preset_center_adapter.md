# Lot PathPattern-3 — Legacy ProjectPathPreset Center Adapter V0

## 1. Verdict

Lot validé.

Ce lot ajoute un adaptateur pur et non persistant :

```text
ProjectPathPreset legacy -> PathCenterPattern 1x1
```

Le variant utilisé par défaut est `TerrainPathVariant.cross`, conformément à la preuve du Lot 0 : l'intérieur d'une zone pleine legacy résout vers `cross`, pas vers `isolated`.

Aucun modèle persistant, aucun JSON, aucune génération, aucune UI, aucun runtime, aucun gameplay et aucun battle package n'ont été modifiés.

## 2. Audit initial

Commandes initiales exécutées :

```bash
pwd
git status --short --untracked-files=all
git diff --stat
rg -n "class ProjectPathPreset|class PathPresetVariantMapping|enum TerrainPathVariant|enum PathSurfaceKind|TilesetVisualFrame|PathCenterPattern|TerrainPathVariant.cross|variantMappings|pathPresets|create.*PathPreset|PathAutotileSet" packages/map_core/lib packages/map_core/test packages/map_editor/lib
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

Exit code : `1`. Le binaire `ctx` n'est pas dans le PATH, mais le MCP Context Mode a été utilisé pour les recherches et les sorties volumineuses.

Stats Context Mode :

```text
962.4K tokens saved  ·  80.6% reduction  ·  21h 17m

Without context-mode  |████████████████████████████████████████| 4.6 MB
With context-mode     |████████░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░| 907.1 KB

3.7 MB kept out of your conversation. Never entered context.

154 calls

  ctx_batch_execute         48 calls    2.7 MB saved
  ctx_search                15 calls  382.9 KB saved
  ctx_execute               63 calls  382.5 KB saved
  ctx_execute_file          15 calls  142.1 KB saved
  ctx_fetch_and_index        3 calls   40.6 KB saved
  ctx_stats                 10 calls   29.4 KB saved

v1.0.103
```

Réponses d'audit :

1. `ProjectPathPreset` est défini dans `packages/map_core/lib/src/models/project_manifest.dart`.
2. `ProjectPathPreset` contient `id`, `name`, `surfaceKind`, `categoryId`, `tilesetId`, `variants`, `sortOrder`.
3. `PathPresetVariantMapping` est défini dans le même fichier.
4. Le champ `variant` de `PathPresetVariantMapping` porte le `TerrainPathVariant`.
5. Le champ `frames` de `PathPresetVariantMapping` porte les frames visuelles.
6. Le champ `tilesetId` de `ProjectPathPreset` porte le tileset global du preset.
7. `TilesetVisualFrame.tilesetId` peut porter un override par frame ; une valeur vide reste une valeur vide.
8. La preuve que le centre intérieur legacy est `cross` est dans `packages/map_core/test/map_terrain_autotile_characterization_test.dart`, test `full 3x3 block center is cross and edges receive border fill`.
9. `TerrainPathVariant.cross` existe toujours dans `packages/map_core/lib/src/models/enums.dart`.
10. La façon la plus sûre de créer un `PathCenterPattern` 1x1 est de chercher le mapping `cross`, vérifier que ses frames ne sont pas vides, puis créer une cellule unique `(0,0)` avec ces frames exactes.

Structure réelle inspectée :

```dart
@freezed
class ProjectPathPreset with _$ProjectPathPreset {
  const factory ProjectPathPreset({
    required String id,
    required String name,
    @Default(PathSurfaceKind.path) PathSurfaceKind surfaceKind,
    String? categoryId,
    @Default('') String tilesetId,
    @Default([]) List<PathPresetVariantMapping> variants,
    @Default(0) int sortOrder,
  }) = _ProjectPathPreset;

  factory ProjectPathPreset.fromJson(Map<String, dynamic> json) =>
      _$ProjectPathPresetFromJson(json);
}

@freezed
class PathPresetVariantMapping with _$PathPresetVariantMapping {
  @JsonSerializable(explicitToJson: true)
  const factory PathPresetVariantMapping({
    required TerrainPathVariant variant,

    /// Au moins une frame ; rendu éditeur / autotile = première frame.
    required List<TilesetVisualFrame> frames,
  }) = _PathPresetVariantMapping;

  factory PathPresetVariantMapping.fromJson(Map<String, dynamic> json) =>
      _$PathPresetVariantMappingFromJson(jsonCoerceLegacySourceToFrames(json));
}
```

## 3. Structure réelle de ProjectPathPreset

`ProjectPathPreset` est un modèle Freezed existant. Il n'a pas été modifié.

Champs utiles pour ce lot :

```text
id              -> identifiant legacy du preset
name            -> nom legacy du preset
surfaceKind     -> famille visuelle du path
categoryId      -> catégorie optionnelle
tilesetId       -> tileset par défaut du preset
variants        -> mappings TerrainPathVariant -> frames
sortOrder       -> ordre d'affichage legacy
```

## 4. Structure réelle de PathPresetVariantMapping

`PathPresetVariantMapping` contient :

```text
variant -> TerrainPathVariant
frames  -> List<TilesetVisualFrame>
```

Le modèle n'empêche pas au niveau constructeur de créer un mapping avec `frames: []`, donc l'adaptateur vérifie explicitement ce cas et rejette le mapping.

## 5. API ajoutée

Fichier créé :

```text
packages/map_core/lib/src/operations/project_path_preset_center_pattern_adapter.dart
```

API :

```dart
final class LegacyProjectPathPresetCenterPatternView {
  const LegacyProjectPathPresetCenterPatternView({
    required this.presetId,
    required this.presetName,
    required this.defaultTilesetId,
    required this.surfaceKind,
    required this.sourceVariant,
    required this.centerPattern,
    this.categoryId,
    required this.sortOrder,
  });

  final String presetId;
  final String presetName;
  final String defaultTilesetId;
  final PathSurfaceKind surfaceKind;
  final TerrainPathVariant sourceVariant;
  final PathCenterPattern centerPattern;
  final String? categoryId;
  final int sortOrder;
}
```

```dart
LegacyProjectPathPresetCenterPatternView
    createLegacyProjectPathPresetCenterPatternView({
  required ProjectPathPreset preset,
  TerrainPathVariant centerVariant = TerrainPathVariant.cross,
})
```

Export ajouté :

```dart
export 'src/operations/project_path_preset_center_pattern_adapter.dart';
```

## 6. Pourquoi cross est le défaut

Le Lot 0 a prouvé que l'intérieur d'un bloc plein résout vers :

```text
TerrainPathVariant.cross
```

La preuve reste couverte par :

```text
packages/map_core/test/map_terrain_autotile_characterization_test.dart
```

Test :

```text
map_terrain_autotile characterization cardinal path shapes full 3x3 block center is cross and edges receive border fill
```

Donc l'adaptateur utilise par défaut :

```dart
TerrainPathVariant.cross
```

## 7. Pourquoi isolated n'est pas le défaut

`isolated` représente une cellule active sans voisin cardinal dans la caractérisation legacy.

Le test ajouté force la distinction :

```text
isolated -> source.x = 1
cross    -> source.x = 99
adapter  -> source.x = 99
```

Ce test empêche l'adaptateur de retomber par erreur sur `isolated`.

## 8. Gestion tileset global / frame override

Décision V0 :

```text
defaultTilesetId = preset.tilesetId
frames conservées telles quelles
frame.tilesetId vide reste vide
frame.tilesetId non vide reste l'override de frame
```

L'adaptateur ne résout pas le tileset effectif. Ce sera la responsabilité d'un renderer ou d'une couche de présentation ultérieure.

## 9. Tests lancés

### TDD RED

Commande :

```bash
cd packages/map_core && dart test test/project_path_preset_center_pattern_adapter_test.dart --reporter expanded
```

Sortie :

```text
00:00 +0: loading test/project_path_preset_center_pattern_adapter_test.dart
00:00 +0 -1: loading test/project_path_preset_center_pattern_adapter_test.dart [E]
  Failed to load "test/project_path_preset_center_pattern_adapter_test.dart":
  test/project_path_preset_center_pattern_adapter_test.dart:22:20: Error: Method not found: 'createLegacyProjectPathPresetCenterPatternView'.
        final view = createLegacyProjectPathPresetCenterPatternView(
                     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  test/project_path_preset_center_pattern_adapter_test.dart:52:20: Error: Method not found: 'createLegacyProjectPathPresetCenterPatternView'.
        final view = createLegacyProjectPathPresetCenterPatternView(
                     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  test/project_path_preset_center_pattern_adapter_test.dart:73:20: Error: Method not found: 'createLegacyProjectPathPresetCenterPatternView'.
        final view = createLegacyProjectPathPresetCenterPatternView(
                     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  test/project_path_preset_center_pattern_adapter_test.dart:97:20: Error: Method not found: 'createLegacyProjectPathPresetCenterPatternView'.
        final view = createLegacyProjectPathPresetCenterPatternView(
                     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  test/project_path_preset_center_pattern_adapter_test.dart:121:20: Error: Method not found: 'createLegacyProjectPathPresetCenterPatternView'.
        final view = createLegacyProjectPathPresetCenterPatternView(
                     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  test/project_path_preset_center_pattern_adapter_test.dart:145:15: Error: Method not found: 'createLegacyProjectPathPresetCenterPatternView'.
          () => createLegacyProjectPathPresetCenterPatternView(preset: preset),
                ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  test/project_path_preset_center_pattern_adapter_test.dart:161:15: Error: Method not found: 'createLegacyProjectPathPresetCenterPatternView'.
          () => createLegacyProjectPathPresetCenterPatternView(preset: preset),
                ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  test/project_path_preset_center_pattern_adapter_test.dart:180:20: Error: Method not found: 'createLegacyProjectPathPresetCenterPatternView'.
        final view = createLegacyProjectPathPresetCenterPatternView(
                     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  test/project_path_preset_center_pattern_adapter_test.dart:204:17: Error: Method not found: 'createLegacyProjectPathPresetCenterPatternView'.
        final a = createLegacyProjectPathPresetCenterPatternView(preset: preset);
                  ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  test/project_path_preset_center_pattern_adapter_test.dart:205:17: Error: Method not found: 'LegacyProjectPathPresetCenterPatternView'.
        final b = LegacyProjectPathPresetCenterPatternView(
                  ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  test/project_path_preset_center_pattern_adapter_test.dart:215:17: Error: Method not found: 'createLegacyProjectPathPresetCenterPatternView'.
        final c = createLegacyProjectPathPresetCenterPatternView(
                  ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
00:00 +0 -1: Some tests failed.
```

### Test ciblé Lot 3

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

### Régression Lot 2

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

### Régression Lot 1

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

### Régression Lot 0

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

Commandes :

```bash
cd packages/map_core && dart test
cd packages/map_core && dart test --reporter compact
```

Ligne finale exacte :

```text
00:02 +1059: All tests passed!
```

## 10. Analyze

Commande :

```bash
cd packages/map_core && dart analyze lib/src/operations/project_path_preset_center_pattern_adapter.dart test/project_path_preset_center_pattern_adapter_test.dart
```

Sortie :

```text
Analyzing project_path_preset_center_pattern_adapter.dart, project_path_preset_center_pattern_adapter_test.dart...
No issues found!
```

## 11. Non-objectifs confirmés

Confirmé :

```text
- aucune UI créée ;
- aucun studio d'édition créé ;
- aucun modèle persistant créé ;
- aucun changement ProjectPathPreset ;
- aucun changement TerrainPathVariant ;
- aucun changement ProjectManifest ;
- aucun JSON ajouté ;
- aucun fichier generated ajouté ;
- aucun build_runner lancé ;
- aucun runtime modifié ;
- aucun gameplay modifié ;
- aucun battle package modifié ;
- aucun traitement de transparence ajouté ;
- aucune résolution temporelle de frames ;
- aucune intégration painter ;
- aucun save flow.
```

Vérification de couplage accidentel :

```bash
rg -n "map_runtime|map_gameplay|map_battle|ProjectManifest|toJson|fromJson|build_runner|Freezed|transparentColor" packages/map_core/lib/src/operations/project_path_preset_center_pattern_adapter.dart packages/map_core/test/project_path_preset_center_pattern_adapter_test.dart
```

Sortie :

```text
```

Exit code : `1`, donc aucun résultat.

## 12. Limites restantes

L'adaptateur choisit le premier mapping dont `variant == centerVariant`. Il ne diagnostique pas les doublons de variant dans un preset legacy.

L'adaptateur ne résout pas le tileset effectif d'une frame. Il expose seulement `defaultTilesetId` et conserve les overrides de frames.

L'adaptateur ne branche pas encore le motif sur le resolver legacy ni sur le painter. C'est volontaire pour garder ce lot pur.

## 13. Git status final

```text
 M packages/map_core/lib/map_core.dart
?? packages/map_core/lib/src/operations/project_path_preset_center_pattern_adapter.dart
?? packages/map_core/test/project_path_preset_center_pattern_adapter_test.dart
?? reports/pathPattern/path_pattern_lot_03_legacy_project_path_preset_center_adapter.md
```

## 14. Prochain lot recommandé

Prochain lot recommandé :

```text
PathPattern-4 — Tileset Transparent Color V0
```

ou, si on veut encore réduire le risque avant la transparence :

```text
PathPattern-4-bis — Center Adapter Diagnostics V0
```

## Evidence Pack

### Fichiers créés / modifiés / supprimés

Créés :

```text
packages/map_core/lib/src/operations/project_path_preset_center_pattern_adapter.dart
packages/map_core/test/project_path_preset_center_pattern_adapter_test.dart
reports/pathPattern/path_pattern_lot_03_legacy_project_path_preset_center_adapter.md
```

Modifié :

```text
packages/map_core/lib/map_core.dart
```

Supprimés :

```text
aucun
```

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

### Contenu complet — packages/map_core/lib/src/operations/project_path_preset_center_pattern_adapter.dart

```dart
import '../models/enums.dart';
import '../models/path_center_pattern.dart';
import '../models/project_manifest.dart';

/// Non-persistent view of a legacy path preset as a center pattern.
final class LegacyProjectPathPresetCenterPatternView {
  const LegacyProjectPathPresetCenterPatternView({
    required this.presetId,
    required this.presetName,
    required this.defaultTilesetId,
    required this.surfaceKind,
    required this.sourceVariant,
    required this.centerPattern,
    this.categoryId,
    required this.sortOrder,
  });

  final String presetId;
  final String presetName;
  final String defaultTilesetId;
  final PathSurfaceKind surfaceKind;
  final TerrainPathVariant sourceVariant;
  final PathCenterPattern centerPattern;
  final String? categoryId;
  final int sortOrder;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is LegacyProjectPathPresetCenterPatternView &&
            presetId == other.presetId &&
            presetName == other.presetName &&
            defaultTilesetId == other.defaultTilesetId &&
            surfaceKind == other.surfaceKind &&
            sourceVariant == other.sourceVariant &&
            centerPattern == other.centerPattern &&
            categoryId == other.categoryId &&
            sortOrder == other.sortOrder;
  }

  @override
  int get hashCode {
    return Object.hash(
      presetId,
      presetName,
      defaultTilesetId,
      surfaceKind,
      sourceVariant,
      centerPattern,
      categoryId,
      sortOrder,
    );
  }
}

/// Adapts a legacy [ProjectPathPreset] center mapping to a local 1x1 pattern.
LegacyProjectPathPresetCenterPatternView
    createLegacyProjectPathPresetCenterPatternView({
  required ProjectPathPreset preset,
  TerrainPathVariant centerVariant = TerrainPathVariant.cross,
}) {
  final mapping = _findVariantMapping(preset, centerVariant);
  if (mapping == null) {
    throw ArgumentError.value(
      centerVariant,
      'centerVariant',
      'ProjectPathPreset does not contain center variant $centerVariant.',
    );
  }
  if (mapping.frames.isEmpty) {
    throw ArgumentError.value(
      centerVariant,
      'centerVariant',
      'ProjectPathPreset center variant $centerVariant has no frames.',
    );
  }

  return LegacyProjectPathPresetCenterPatternView(
    presetId: preset.id,
    presetName: preset.name,
    defaultTilesetId: preset.tilesetId,
    surfaceKind: preset.surfaceKind,
    sourceVariant: centerVariant,
    centerPattern: PathCenterPattern(
      size: PathCenterPatternSize(width: 1, height: 1),
      cells: [
        PathCenterPatternCell(
          localX: 0,
          localY: 0,
          frames: mapping.frames,
        ),
      ],
    ),
    categoryId: preset.categoryId,
    sortOrder: preset.sortOrder,
  );
}

PathPresetVariantMapping? _findVariantMapping(
  ProjectPathPreset preset,
  TerrainPathVariant variant,
) {
  for (final mapping in preset.variants) {
    if (mapping.variant == variant) {
      return mapping;
    }
  }
  return null;
}
```

### Contenu complet — packages/map_core/test/project_path_preset_center_pattern_adapter_test.dart

```dart
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('createLegacyProjectPathPresetCenterPatternView', () {
    test('uses cross by default and creates a 1x1 center pattern', () {
      final isolatedFrames = [_frame(1)];
      final crossFrames = [_frame(99)];
      final preset = _preset(
        variants: [
          PathPresetVariantMapping(
            variant: TerrainPathVariant.isolated,
            frames: isolatedFrames,
          ),
          PathPresetVariantMapping(
            variant: TerrainPathVariant.cross,
            frames: crossFrames,
          ),
        ],
      );

      final view = createLegacyProjectPathPresetCenterPatternView(
        preset: preset,
      );

      expect(view.presetId, 'legacy-water');
      expect(view.presetName, 'Legacy Water');
      expect(view.defaultTilesetId, 'main_tileset');
      expect(view.surfaceKind, PathSurfaceKind.water);
      expect(view.categoryId, 'water-category');
      expect(view.sortOrder, 7);
      expect(view.sourceVariant, TerrainPathVariant.cross);
      expect(
        view.centerPattern.size,
        PathCenterPatternSize(width: 1, height: 1),
      );
      expect(view.centerPattern.cellAt(0, 0).frames, crossFrames);
      expect(view.centerPattern.cellAt(0, 0).frames, isNot(isolatedFrames));
    });

    test('does not assume isolated is the center', () {
      final preset = _preset(
        variants: [
          PathPresetVariantMapping(
            variant: TerrainPathVariant.isolated,
            frames: [_frame(1)],
          ),
          PathPresetVariantMapping(
            variant: TerrainPathVariant.cross,
            frames: [_frame(99)],
          ),
        ],
      );

      final view = createLegacyProjectPathPresetCenterPatternView(
        preset: preset,
      );

      expect(view.centerPattern.cellAt(0, 0).frames.single.source.x, 99);
    });

    test('can adapt an explicit variant for debug or compatibility', () {
      final preset = _preset(
        variants: [
          PathPresetVariantMapping(
            variant: TerrainPathVariant.isolated,
            frames: [_frame(1)],
          ),
          PathPresetVariantMapping(
            variant: TerrainPathVariant.cross,
            frames: [_frame(99)],
          ),
        ],
      );

      final view = createLegacyProjectPathPresetCenterPatternView(
        preset: preset,
        centerVariant: TerrainPathVariant.isolated,
      );

      expect(view.sourceVariant, TerrainPathVariant.isolated);
      expect(view.centerPattern.cellAt(0, 0).frames.single.source.x, 1);
    });

    test('preserves frame order and durations', () {
      final crossFrames = [
        _frame(10, durationMs: 80),
        _frame(11, durationMs: 120),
        _frame(12, durationMs: 160),
      ];
      final preset = _preset(
        variants: [
          PathPresetVariantMapping(
            variant: TerrainPathVariant.cross,
            frames: crossFrames,
          ),
        ],
      );

      final view = createLegacyProjectPathPresetCenterPatternView(
        preset: preset,
      );

      final frames = view.centerPattern.cellAt(0, 0).frames;
      expect(frames.map((frame) => frame.source.x), [10, 11, 12]);
      expect(frames.map((frame) => frame.durationMs), [80, 120, 160]);
    });

    test('exposes global tileset id and preserves frame tileset overrides', () {
      final crossFrames = [
        _frame(10),
        _frame(11, tilesetId: 'override_tileset'),
      ];
      final preset = _preset(
        tilesetId: 'main_tileset',
        variants: [
          PathPresetVariantMapping(
            variant: TerrainPathVariant.cross,
            frames: crossFrames,
          ),
        ],
      );

      final view = createLegacyProjectPathPresetCenterPatternView(
        preset: preset,
      );

      final frames = view.centerPattern.cellAt(0, 0).frames;
      expect(view.defaultTilesetId, 'main_tileset');
      expect(frames, crossFrames);
      expect(frames[0].tilesetId, '');
      expect(frames[1].tilesetId, 'override_tileset');
      expect(identical(frames[0], crossFrames[0]), isTrue);
      expect(identical(frames[1], crossFrames[1]), isTrue);
    });

    test('rejects missing center variant', () {
      final preset = _preset(
        variants: [
          PathPresetVariantMapping(
            variant: TerrainPathVariant.isolated,
            frames: [_frame(1)],
          ),
        ],
      );

      expect(
        () => createLegacyProjectPathPresetCenterPatternView(preset: preset),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects empty center variant frames', () {
      final preset = _preset(
        variants: [
          PathPresetVariantMapping(
            variant: TerrainPathVariant.cross,
            frames: const [],
          ),
        ],
      );

      expect(
        () => createLegacyProjectPathPresetCenterPatternView(preset: preset),
        throwsA(isA<ArgumentError>()),
      );
    });

    test(
      'does not mutate the source preset and copies frame lists into pattern',
      () {
        final crossFrames = [_frame(99)];
        final preset = _preset(
          variants: [
            PathPresetVariantMapping(
              variant: TerrainPathVariant.cross,
              frames: crossFrames,
            ),
          ],
        );
        final beforeVariants = List<PathPresetVariantMapping>.from(
          preset.variants,
        );

        final view = createLegacyProjectPathPresetCenterPatternView(
          preset: preset,
        );
        crossFrames.add(_frame(100));

        expect(preset.variants, beforeVariants);
        expect(view.centerPattern.cellAt(0, 0).frames.length, 1);
        expect(view.centerPattern.cellAt(0, 0).frames.single.source.x, 99);
      },
    );

    test('view has value equality and hashCode', () {
      final preset = _preset(
        variants: [
          PathPresetVariantMapping(
            variant: TerrainPathVariant.cross,
            frames: [_frame(99)],
          ),
          PathPresetVariantMapping(
            variant: TerrainPathVariant.isolated,
            frames: [_frame(1)],
          ),
        ],
      );

      final a = createLegacyProjectPathPresetCenterPatternView(preset: preset);
      final b = LegacyProjectPathPresetCenterPatternView(
        presetId: a.presetId,
        presetName: a.presetName,
        defaultTilesetId: a.defaultTilesetId,
        surfaceKind: a.surfaceKind,
        sourceVariant: a.sourceVariant,
        centerPattern: a.centerPattern,
        categoryId: a.categoryId,
        sortOrder: a.sortOrder,
      );
      final c = createLegacyProjectPathPresetCenterPatternView(
        preset: preset,
        centerVariant: TerrainPathVariant.isolated,
      );

      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(c));
    });
  });
}

ProjectPathPreset _preset({
  required List<PathPresetVariantMapping> variants,
  String tilesetId = 'main_tileset',
}) {
  return ProjectPathPreset(
    id: 'legacy-water',
    name: 'Legacy Water',
    surfaceKind: PathSurfaceKind.water,
    categoryId: 'water-category',
    tilesetId: tilesetId,
    variants: variants,
    sortOrder: 7,
  );
}

TilesetVisualFrame _frame(
  int sourceX, {
  int? durationMs,
  String tilesetId = '',
}) {
  return TilesetVisualFrame(
    tilesetId: tilesetId,
    source: TilesetSourceRect(x: sourceX, y: 0),
    durationMs: durationMs,
  );
}
```

### Contenu complet — packages/map_core/lib/map_core.dart

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
index 6561b522..ca514c2b 100644
--- a/packages/map_core/lib/map_core.dart
+++ b/packages/map_core/lib/map_core.dart
@@ -32,6 +32,7 @@ export 'src/operations/map_path.dart';
 export 'src/operations/map_terrain.dart';
 export 'src/operations/map_terrain_autotile.dart';
 export 'src/operations/path_center_pattern_resolver.dart';
+export 'src/operations/project_path_preset_center_pattern_adapter.dart';
 export 'src/operations/tile_visual_frame_timeline.dart';
 export 'src/operations/tile_visual_frame_vertical_atlas.dart';
 export 'src/operations/path_variant_vertical_atlas_mapping.dart';
```

### Diff complet — packages/map_core/lib/src/operations/project_path_preset_center_pattern_adapter.dart

```diff
diff --git a/packages/map_core/lib/src/operations/project_path_preset_center_pattern_adapter.dart b/packages/map_core/lib/src/operations/project_path_preset_center_pattern_adapter.dart
new file mode 100644
index 00000000..71338a76
--- /dev/null
+++ b/packages/map_core/lib/src/operations/project_path_preset_center_pattern_adapter.dart
@@ -0,0 +1,109 @@
+import '../models/enums.dart';
+import '../models/path_center_pattern.dart';
+import '../models/project_manifest.dart';
+
+/// Non-persistent view of a legacy path preset as a center pattern.
+final class LegacyProjectPathPresetCenterPatternView {
+  const LegacyProjectPathPresetCenterPatternView({
+    required this.presetId,
+    required this.presetName,
+    required this.defaultTilesetId,
+    required this.surfaceKind,
+    required this.sourceVariant,
+    required this.centerPattern,
+    this.categoryId,
+    required this.sortOrder,
+  });
+
+  final String presetId;
+  final String presetName;
+  final String defaultTilesetId;
+  final PathSurfaceKind surfaceKind;
+  final TerrainPathVariant sourceVariant;
+  final PathCenterPattern centerPattern;
+  final String? categoryId;
+  final int sortOrder;
+
+  @override
+  bool operator ==(Object other) {
+    return identical(this, other) ||
+        other is LegacyProjectPathPresetCenterPatternView &&
+            presetId == other.presetId &&
+            presetName == other.presetName &&
+            defaultTilesetId == other.defaultTilesetId &&
+            surfaceKind == other.surfaceKind &&
+            sourceVariant == other.sourceVariant &&
+            centerPattern == other.centerPattern &&
+            categoryId == other.categoryId &&
+            sortOrder == other.sortOrder;
+  }
+
+  @override
+  int get hashCode {
+    return Object.hash(
+      presetId,
+      presetName,
+      defaultTilesetId,
+      surfaceKind,
+      sourceVariant,
+      centerPattern,
+      categoryId,
+      sortOrder,
+    );
+  }
+}
+
+/// Adapts a legacy [ProjectPathPreset] center mapping to a local 1x1 pattern.
+LegacyProjectPathPresetCenterPatternView
+    createLegacyProjectPathPresetCenterPatternView({
+  required ProjectPathPreset preset,
+  TerrainPathVariant centerVariant = TerrainPathVariant.cross,
+}) {
+  final mapping = _findVariantMapping(preset, centerVariant);
+  if (mapping == null) {
+    throw ArgumentError.value(
+      centerVariant,
+      'centerVariant',
+      'ProjectPathPreset does not contain center variant $centerVariant.',
+    );
+  }
+  if (mapping.frames.isEmpty) {
+    throw ArgumentError.value(
+      centerVariant,
+      'centerVariant',
+      'ProjectPathPreset center variant $centerVariant has no frames.',
+    );
+  }
+
+  return LegacyProjectPathPresetCenterPatternView(
+    presetId: preset.id,
+    presetName: preset.name,
+    defaultTilesetId: preset.tilesetId,
+    surfaceKind: preset.surfaceKind,
+    sourceVariant: centerVariant,
+    centerPattern: PathCenterPattern(
+      size: PathCenterPatternSize(width: 1, height: 1),
+      cells: [
+        PathCenterPatternCell(
+          localX: 0,
+          localY: 0,
+          frames: mapping.frames,
+        ),
+      ],
+    ),
+    categoryId: preset.categoryId,
+    sortOrder: preset.sortOrder,
+  );
+}
+
+PathPresetVariantMapping? _findVariantMapping(
+  ProjectPathPreset preset,
+  TerrainPathVariant variant,
+) {
+  for (final mapping in preset.variants) {
+    if (mapping.variant == variant) {
+      return mapping;
+    }
+  }
+  return null;
+}
```

### Diff complet — packages/map_core/test/project_path_preset_center_pattern_adapter_test.dart

```diff
diff --git a/packages/map_core/test/project_path_preset_center_pattern_adapter_test.dart b/packages/map_core/test/project_path_preset_center_pattern_adapter_test.dart
new file mode 100644
index 00000000..f00f0873
--- /dev/null
+++ b/packages/map_core/test/project_path_preset_center_pattern_adapter_test.dart
@@ -0,0 +1,257 @@
+import 'package:map_core/map_core.dart';
+import 'package:test/test.dart';
+
+void main() {
+  group('createLegacyProjectPathPresetCenterPatternView', () {
+    test('uses cross by default and creates a 1x1 center pattern', () {
+      final isolatedFrames = [_frame(1)];
+      final crossFrames = [_frame(99)];
+      final preset = _preset(
+        variants: [
+          PathPresetVariantMapping(
+            variant: TerrainPathVariant.isolated,
+            frames: isolatedFrames,
+          ),
+          PathPresetVariantMapping(
+            variant: TerrainPathVariant.cross,
+            frames: crossFrames,
+          ),
+        ],
+      );
+
+      final view = createLegacyProjectPathPresetCenterPatternView(
+        preset: preset,
+      );
+
+      expect(view.presetId, 'legacy-water');
+      expect(view.presetName, 'Legacy Water');
+      expect(view.defaultTilesetId, 'main_tileset');
+      expect(view.surfaceKind, PathSurfaceKind.water);
+      expect(view.categoryId, 'water-category');
+      expect(view.sortOrder, 7);
+      expect(view.sourceVariant, TerrainPathVariant.cross);
+      expect(
+        view.centerPattern.size,
+        PathCenterPatternSize(width: 1, height: 1),
+      );
+      expect(view.centerPattern.cellAt(0, 0).frames, crossFrames);
+      expect(view.centerPattern.cellAt(0, 0).frames, isNot(isolatedFrames));
+    });
+
+    test('does not assume isolated is the center', () {
+      final preset = _preset(
+        variants: [
+          PathPresetVariantMapping(
+            variant: TerrainPathVariant.isolated,
+            frames: [_frame(1)],
+          ),
+          PathPresetVariantMapping(
+            variant: TerrainPathVariant.cross,
+            frames: [_frame(99)],
+          ),
+        ],
+      );
+
+      final view = createLegacyProjectPathPresetCenterPatternView(
+        preset: preset,
+      );
+
+      expect(view.centerPattern.cellAt(0, 0).frames.single.source.x, 99);
+    });
+
+    test('can adapt an explicit variant for debug or compatibility', () {
+      final preset = _preset(
+        variants: [
+          PathPresetVariantMapping(
+            variant: TerrainPathVariant.isolated,
+            frames: [_frame(1)],
+          ),
+          PathPresetVariantMapping(
+            variant: TerrainPathVariant.cross,
+            frames: [_frame(99)],
+          ),
+        ],
+      );
+
+      final view = createLegacyProjectPathPresetCenterPatternView(
+        preset: preset,
+        centerVariant: TerrainPathVariant.isolated,
+      );
+
+      expect(view.sourceVariant, TerrainPathVariant.isolated);
+      expect(view.centerPattern.cellAt(0, 0).frames.single.source.x, 1);
+    });
+
+    test('preserves frame order and durations', () {
+      final crossFrames = [
+        _frame(10, durationMs: 80),
+        _frame(11, durationMs: 120),
+        _frame(12, durationMs: 160),
+      ];
+      final preset = _preset(
+        variants: [
+          PathPresetVariantMapping(
+            variant: TerrainPathVariant.cross,
+            frames: crossFrames,
+          ),
+        ],
+      );
+
+      final view = createLegacyProjectPathPresetCenterPatternView(
+        preset: preset,
+      );
+
+      final frames = view.centerPattern.cellAt(0, 0).frames;
+      expect(frames.map((frame) => frame.source.x), [10, 11, 12]);
+      expect(frames.map((frame) => frame.durationMs), [80, 120, 160]);
+    });
+
+    test('exposes global tileset id and preserves frame tileset overrides', () {
+      final crossFrames = [
+        _frame(10),
+        _frame(11, tilesetId: 'override_tileset'),
+      ];
+      final preset = _preset(
+        tilesetId: 'main_tileset',
+        variants: [
+          PathPresetVariantMapping(
+            variant: TerrainPathVariant.cross,
+            frames: crossFrames,
+          ),
+        ],
+      );
+
+      final view = createLegacyProjectPathPresetCenterPatternView(
+        preset: preset,
+      );
+
+      final frames = view.centerPattern.cellAt(0, 0).frames;
+      expect(view.defaultTilesetId, 'main_tileset');
+      expect(frames, crossFrames);
+      expect(frames[0].tilesetId, '');
+      expect(frames[1].tilesetId, 'override_tileset');
+      expect(identical(frames[0], crossFrames[0]), isTrue);
+      expect(identical(frames[1], crossFrames[1]), isTrue);
+    });
+
+    test('rejects missing center variant', () {
+      final preset = _preset(
+        variants: [
+          PathPresetVariantMapping(
+            variant: TerrainPathVariant.isolated,
+            frames: [_frame(1)],
+          ),
+        ],
+      );
+
+      expect(
+        () => createLegacyProjectPathPresetCenterPatternView(preset: preset),
+        throwsA(isA<ArgumentError>()),
+      );
+    });
+
+    test('rejects empty center variant frames', () {
+      final preset = _preset(
+        variants: [
+          PathPresetVariantMapping(
+            variant: TerrainPathVariant.cross,
+            frames: const [],
+          ),
+        ],
+      );
+
+      expect(
+        () => createLegacyProjectPathPresetCenterPatternView(preset: preset),
+        throwsA(isA<ArgumentError>()),
+      );
+    });
+
+    test(
+      'does not mutate the source preset and copies frame lists into pattern',
+      () {
+        final crossFrames = [_frame(99)];
+        final preset = _preset(
+          variants: [
+            PathPresetVariantMapping(
+              variant: TerrainPathVariant.cross,
+              frames: crossFrames,
+            ),
+          ],
+        );
+        final beforeVariants = List<PathPresetVariantMapping>.from(
+          preset.variants,
+        );
+
+        final view = createLegacyProjectPathPresetCenterPatternView(
+          preset: preset,
+        );
+        crossFrames.add(_frame(100));
+
+        expect(preset.variants, beforeVariants);
+        expect(view.centerPattern.cellAt(0, 0).frames.length, 1);
+        expect(view.centerPattern.cellAt(0, 0).frames.single.source.x, 99);
+      },
+    );
+
+    test('view has value equality and hashCode', () {
+      final preset = _preset(
+        variants: [
+          PathPresetVariantMapping(
+            variant: TerrainPathVariant.cross,
+            frames: [_frame(99)],
+          ),
+          PathPresetVariantMapping(
+            variant: TerrainPathVariant.isolated,
+            frames: [_frame(1)],
+          ),
+        ],
+      );
+
+      final a = createLegacyProjectPathPresetCenterPatternView(preset: preset);
+      final b = LegacyProjectPathPresetCenterPatternView(
+        presetId: a.presetId,
+        presetName: a.presetName,
+        defaultTilesetId: a.defaultTilesetId,
+        surfaceKind: a.surfaceKind,
+        sourceVariant: a.sourceVariant,
+        centerPattern: a.centerPattern,
+        categoryId: a.categoryId,
+        sortOrder: a.sortOrder,
+      );
+      final c = createLegacyProjectPathPresetCenterPatternView(
+        preset: preset,
+        centerVariant: TerrainPathVariant.isolated,
+      );
+
+      expect(a, b);
+      expect(a.hashCode, b.hashCode);
+      expect(a, isNot(c));
+    });
+  });
+}
+
+ProjectPathPreset _preset({
+  required List<PathPresetVariantMapping> variants,
+  String tilesetId = 'main_tileset',
+}) {
+  return ProjectPathPreset(
+    id: 'legacy-water',
+    name: 'Legacy Water',
+    surfaceKind: PathSurfaceKind.water,
+    categoryId: 'water-category',
+    tilesetId: tilesetId,
+    variants: variants,
+    sortOrder: 7,
+  );
+}
+
+TilesetVisualFrame _frame(
+  int sourceX, {
+  int? durationMs,
+  String tilesetId = '',
+}) {
+  return TilesetVisualFrame(
+    tilesetId: tilesetId,
+    source: TilesetSourceRect(x: sourceX, y: 0),
+    durationMs: durationMs,
+  );
+}
```

## Auto-review

- Ai-je utilisé `cross` par défaut ? Oui, `centerVariant = TerrainPathVariant.cross`.
- Ai-je évité `isolated` comme défaut ? Oui, `isolated` est seulement possible via paramètre explicite.
- Ai-je gardé l'adapter pur ? Oui, il lit un preset et retourne une vue non persistante.
- Ai-je évité ProjectManifest ? Oui, aucune modification du modèle manifest.
- Ai-je évité ProjectPathPreset modification ? Oui.
- Ai-je évité JSON/generated/build_runner ? Oui.
- Ai-je évité runtime/gameplay/battle ? Oui.
- Ai-je testé tileset global et overrides ? Oui, `main_tileset`, frame vide, et `override_tileset`.

## Critique du prompt

- Ambiguïté mineure : le prompt demande une liste complète de fichiers créés/modifiés et le rapport lui-même est un fichier créé. Le rapport liste son propre chemin, mais n'embarque pas son propre contenu pour éviter une récursion de document.
- Décision prise : si plusieurs mappings ont le même `TerrainPathVariant`, l'adaptateur prend le premier. Aucun diagnostic de doublon n'était demandé dans ce lot.
- Point à valider avant Lot 4 : décider si le prochain lot doit vraiment traiter la transparence ou si un lot de diagnostics sur les doublons/variants manquants doit passer avant.
