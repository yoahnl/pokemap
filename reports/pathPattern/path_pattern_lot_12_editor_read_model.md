# PathPattern-12 — PathPattern Editor Read Model V0

## 1. Verdict

Lot accepté.

Le lot ajoute un read model pur côté `map_editor` pour préparer une future UI Path Studio sans créer d'UI, sans widget, sans provider, sans controller, sans génération PNG et sans modification `map_core`.

Le read model expose :

- un summary global ;
- une liste de card models dans l'ordre source ;
- les statuts `ready`, `needsReview`, `blocked` ;
- les issues `missingBasePathPreset`, `duplicatePathPatternId`, `duplicateBasePathPresetId` ;
- les compteurs centre, frames, animation et couleur transparente ;
- les labels de surface legacy.

## 2. Audit initial

Commandes initiales :

```bash
pwd
git status --short --untracked-files=all
git diff --stat
rg -n "ReadModel|read model|Presenter|Presentation|SurfaceStudioReadModel|surface_studio_read_model|PathPattern|pathPatternPresets|ProjectPathPatternPreset|ProjectPathPreset|pathPresets|projectPathPatternPresetById|readProjectPathPatternPresets|containsProjectPathPatternPreset" packages/map_editor/lib packages/map_editor/test packages/map_core/lib packages/map_core/test reports/pathPattern
```

Sortie `pwd` :

```text
/Users/karim/Project/pokemonProject
```

`git status --short --untracked-files=all` initial :

```text
 M packages/map_core/lib/map_core.dart
?? packages/map_core/lib/src/operations/project_manifest_path_pattern_preset_operations.dart
?? packages/map_core/test/project_manifest_path_pattern_preset_operations_test.dart
?? reports/pathPattern/path_pattern_lot_11_manifest_operations.md
```

Ces entrées étaient présentes au démarrage du Lot 12 et correspondent au Lot 11 déjà réalisé dans le worktree.

`git diff --stat` initial :

```text
 packages/map_core/lib/map_core.dart | 1 +
 1 file changed, 1 insertion(+)
```

Context Mode :

```text
ctx shell absent.
Context Mode MCP utilisé via ctx_batch_execute pour l'audit initial et ctx_execute pour le test complet map_core.
ctx_doctor:
- Runtimes: 7/11 (64%) — javascript, shell, python, ruby, rust, php, perl
- Performance: NORMAL — install Bun for 3-5x speed boost
- Server test: PASS
- FTS5 / SQLite: PASS — native module works
- Hook script: PASS — /opt/homebrew/lib/node_modules/context-mode/hooks/pretooluse.mjs
- Version: v1.0.103
```

Réponses d'audit :

1. Convention de read model côté `map_editor` : pas de convention unique trouvée côté éditeur, mais des presenters purs existent dans `packages/map_editor/lib/src/features/surface_painter/`. Côté `map_core`, `surface_studio_read_model.dart` montre le style read-only immuable avec listes défensives.
2. Emplacement retenu : `packages/map_editor/lib/src/features/path_studio/path_pattern_editor_read_model.dart`.
3. Choix entre `application/services`, `application/models` et `features/path_studio` : `features/path_studio` est le plus cohérent, car le modèle prépare une feature future Path Studio et ne traite ni image ni persistance.
4. Les `ProjectPathPatternPreset` sont récupérés via `readProjectPathPatternPresets(manifest)`.
5. Le lien `basePathPresetId` est résolu par index exact sur `manifest.pathPresets`.
6. Base introuvable : issue `missingBasePathPreset`, statut `blocked`, nom/label base à `null`.
7. Id PathPattern dupliqué : chaque card concernée reçoit `duplicatePathPatternId`, statut `blocked`.
8. Id legacy `ProjectPathPreset` dupliqué : chaque card qui référence cet id reçoit `duplicateBasePathPresetId`, statut `blocked`.
9. Infos minimales d'une future carte : id, name, basePathPresetId, nom base, label surface, taille `WxH`, nombre de cellules, nombre de frames, cellules animées, couleur transparente, status, issues.
10. Pas de preview PNG dans ce lot : le read model ne reçoit pas de bytes image ni de tileset ; les renderers PNG des Lots 5/6 restent séparés.

## 3. Fichiers créés / modifiés / supprimés

Créés :

```text
packages/map_editor/lib/src/features/path_studio/path_pattern_editor_read_model.dart
packages/map_editor/test/path_pattern/path_pattern_editor_read_model_test.dart
reports/pathPattern/path_pattern_lot_12_editor_read_model.md
```

Modifiés par ce lot :

```text
aucun fichier existant
```

Supprimés :

```text
aucun
```

## 4. API ajoutée

```dart
PathPatternEditorReadModel createPathPatternEditorReadModel({
  required ProjectManifest manifest,
})
```

Types ajoutés :

```dart
PathPatternEditorReadModel
PathPatternEditorSummary
PathPatternPresetCardModel
PathPatternPresetReadinessStatus
PathPatternPresetIssueCode
```

## 5. Structure du read model

`PathPatternEditorReadModel` contient :

- `summary` : les compteurs globaux ;
- `presets` : les cards, dans l'ordre de `manifest.pathPatternPresets`.

La liste `presets` est convertie en `List.unmodifiable`.

## 6. Structure des card models

Chaque `PathPatternPresetCardModel` expose :

- `id`, `name`, `basePathPresetId` ;
- `basePathPresetName` et `basePathSurfaceKindLabel`, `null` si base absente ou ambiguë ;
- `centerPatternLabel`, `centerWidth`, `centerHeight`, `centerCellCount` ;
- `centerFrameCount` et `animatedCellCount` ;
- `transparentColorHex` ;
- `status` ;
- `issues`.

La liste `issues` est convertie en `List.unmodifiable`.

## 7. Structure du summary

`PathPatternEditorSummary` expose :

- `totalCount` ;
- `readyCount` ;
- `issueCount` ;
- `multiCellCenterCount` ;
- `transparentColorCount` ;
- `missingBasePathPresetCount` ;
- `duplicatePathPatternIdCount` ;
- `duplicateBasePathPresetIdCount`.

Décision `issueCount` :

```text
nombre de cards ayant au moins une issue
```

## 8. Stratégie de résolution basePathPresetId

Le read model construit un index :

```text
manifest.pathPresets : id exact -> List<ProjectPathPreset>
```

Résolution :

- 0 match : `missingBasePathPreset`, statut `blocked`, base name/label `null` ;
- 1 match : nom et label surface exposés ;
- plusieurs matches : `duplicateBasePathPresetId`, statut `blocked`, base name/label `null`.

Aucun trim, aucune comparaison par `name`.

## 9. Stratégie duplicate PathPattern ids

Le read model compte les ids exacts de `manifest.pathPatternPresets`.

Si un id apparaît plusieurs fois, chaque card concernée reçoit `duplicatePathPatternId`.

Décision duplicate count :

```text
duplicatePathPatternIdCount = nombre de presets concernés par un doublon
```

Exemple :

```text
[A, A, B] -> duplicatePathPatternIdCount = 2
```

## 10. Stratégie duplicate legacy path ids

Si `manifest.pathPresets` contient plusieurs `ProjectPathPreset` avec le même id exact, chaque PathPattern qui référence cet id reçoit `duplicateBasePathPresetId`.

Décision duplicate legacy count :

```text
duplicateBasePathPresetIdCount = nombre de cards PathPattern concernées
```

## 11. Labels

`centerPatternLabel` utilise le symbole `×` :

```text
1×1
2×2
3×2
```

`basePathSurfaceKindLabel` utilise des labels français simples :

```text
path -> Chemin
road -> Route
water -> Eau
tallGrass -> Hautes herbes
ice -> Glace
lava -> Lave
swamp -> Marais
rails -> Rails
bridge -> Pont
special -> Spécial
custom -> Personnalisé
```

## 12. Tests lancés

### Test rouge TDD

Commande :

```bash
cd packages/map_editor && flutter test test/path_pattern/path_pattern_editor_read_model_test.dart --no-pub --reporter expanded
```

Sortie complète après correction de fixture :

```text
test/path_pattern/path_pattern_editor_read_model_test.dart:3:8: Error: Error when reading 'lib/src/features/path_studio/path_pattern_editor_read_model.dart': No such file or directory
import 'package:map_editor/src/features/path_studio/path_pattern_editor_read_model.dart';
       ^
test/path_pattern/path_pattern_editor_read_model_test.dart:8:25: Error: Method not found: 'createPathPatternEditorReadModel'.
      final readModel = createPathPatternEditorReadModel(
                        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
test/path_pattern/path_pattern_editor_read_model_test.dart:24:25: Error: Method not found: 'createPathPatternEditorReadModel'.
      final readModel = createPathPatternEditorReadModel(
                        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
test/path_pattern/path_pattern_editor_read_model_test.dart:55:27: Error: Undefined name 'PathPatternPresetReadinessStatus'.
      expect(card.status, PathPatternPresetReadinessStatus.ready);
                          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
test/path_pattern/path_pattern_editor_read_model_test.dart:60:25: Error: Method not found: 'createPathPatternEditorReadModel'.
      final readModel = createPathPatternEditorReadModel(
                        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
test/path_pattern/path_pattern_editor_read_model_test.dart:82:27: Error: Undefined name 'PathPatternPresetReadinessStatus'.
      expect(card.status, PathPatternPresetReadinessStatus.ready);
                          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
test/path_pattern/path_pattern_editor_read_model_test.dart:89:25: Error: Method not found: 'createPathPatternEditorReadModel'.
      final readModel = createPathPatternEditorReadModel(
                        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
test/path_pattern/path_pattern_editor_read_model_test.dart:102:27: Error: Undefined name 'PathPatternPresetReadinessStatus'.
      expect(card.status, PathPatternPresetReadinessStatus.blocked);
                          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
test/path_pattern/path_pattern_editor_read_model_test.dart:104:9: Error: Undefined name 'PathPatternPresetIssueCode'.
        PathPatternPresetIssueCode.missingBasePathPreset,
        ^^^^^^^^^^^^^^^^^^^^^^^^^^
test/path_pattern/path_pattern_editor_read_model_test.dart:114:25: Error: Method not found: 'createPathPatternEditorReadModel'.
      final readModel = createPathPatternEditorReadModel(
                        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
test/path_pattern/path_pattern_editor_read_model_test.dart:126:29: Error: Undefined name 'PathPatternPresetReadinessStatus'.
        expect(card.status, PathPatternPresetReadinessStatus.blocked);
                            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
test/path_pattern/path_pattern_editor_read_model_test.dart:129:20: Error: Undefined name 'PathPatternPresetIssueCode'.
          contains(PathPatternPresetIssueCode.duplicatePathPatternId),
                   ^^^^^^^^^^^^^^^^^^^^^^^^^^
test/path_pattern/path_pattern_editor_read_model_test.dart:138:25: Error: Method not found: 'createPathPatternEditorReadModel'.
      final readModel = createPathPatternEditorReadModel(
                        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
test/path_pattern/path_pattern_editor_read_model_test.dart:154:27: Error: Undefined name 'PathPatternPresetReadinessStatus'.
      expect(card.status, PathPatternPresetReadinessStatus.blocked);
                          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
test/path_pattern/path_pattern_editor_read_model_test.dart:156:9: Error: Undefined name 'PathPatternPresetIssueCode'.
        PathPatternPresetIssueCode.duplicateBasePathPresetId,
        ^^^^^^^^^^^^^^^^^^^^^^^^^^
test/path_pattern/path_pattern_editor_read_model_test.dart:165:25: Error: Method not found: 'createPathPatternEditorReadModel'.
      final readModel = createPathPatternEditorReadModel(
                        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
test/path_pattern/path_pattern_editor_read_model_test.dart:180:25: Error: Method not found: 'createPathPatternEditorReadModel'.
      final readModel = createPathPatternEditorReadModel(
                        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
test/path_pattern/path_pattern_editor_read_model_test.dart:193:27: Error: Undefined name 'PathPatternPresetReadinessStatus'.
      expect(card.status, PathPatternPresetReadinessStatus.blocked);
                          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
test/path_pattern/path_pattern_editor_read_model_test.dart:195:9: Error: Undefined name 'PathPatternPresetIssueCode'.
        PathPatternPresetIssueCode.missingBasePathPreset,
        ^^^^^^^^^^^^^^^^^^^^^^^^^^
test/path_pattern/path_pattern_editor_read_model_test.dart:201:25: Error: Method not found: 'createPathPatternEditorReadModel'.
      final readModel = createPathPatternEditorReadModel(
                        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
test/path_pattern/path_pattern_editor_read_model_test.dart:226:25: Error: Method not found: 'createPathPatternEditorReadModel'.
      final readModel = createPathPatternEditorReadModel(
                        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
test/path_pattern/path_pattern_editor_read_model_test.dart:239:11: Error: Undefined name 'PathPatternPresetIssueCode'.
          PathPatternPresetIssueCode.missingBasePathPreset,
          ^^^^^^^^^^^^^^^^^^^^^^^^^^
00:00 +0 -1: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_pattern_editor_read_model_test.dart [E]
  Failed to load "/Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_pattern_editor_read_model_test.dart":
  Compilation failed for testPath=/Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_pattern_editor_read_model_test.dart
00:00 +0 -1: Some tests failed.
```

### Test ciblé Lot 12

Commande :

```bash
cd packages/map_editor && flutter test test/path_pattern/path_pattern_editor_read_model_test.dart --no-pub --reporter expanded
```

Sortie complète :

```text
00:00 +0: createPathPatternEditorReadModel empty manifest exposes an empty summary and no cards
00:00 +1: createPathPatternEditorReadModel ready 1x1 preset exposes list card details
00:00 +2: createPathPatternEditorReadModel ready 2x2 transparent animated preset exposes counts
00:00 +3: createPathPatternEditorReadModel missing basePathPresetId blocks the card
00:00 +4: createPathPatternEditorReadModel duplicate PathPattern ids block every affected card
00:00 +5: createPathPatternEditorReadModel duplicate legacy base path preset ids block referencing cards
00:00 +6: createPathPatternEditorReadModel preserves manifest pathPatternPresets order
00:00 +7: createPathPatternEditorReadModel matches basePathPresetId exactly without trimming
00:00 +8: createPathPatternEditorReadModel summary counts ready, blocked, duplicates, and multi-cell presets
00:00 +9: createPathPatternEditorReadModel read model and card lists are immutable defensive copies
00:00 +10: All tests passed!
```

### Régressions preview map_editor

Commandes :

```bash
cd packages/map_editor && flutter test test/path_pattern/path_center_pattern_animated_preview_renderer_test.dart --no-pub --reporter expanded
cd packages/map_editor && flutter test test/path_pattern/path_center_pattern_static_preview_renderer_test.dart --no-pub --reporter expanded
cd packages/map_editor && flutter test test/path_pattern/tileset_transparent_color_processor_test.dart --no-pub --reporter expanded
```

Sorties complètes :

```text
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

### Régression Lot 11

Commande :

```bash
cd packages/map_core && dart test test/project_manifest_path_pattern_preset_operations_test.dart --reporter expanded --no-color
```

Sortie complète :

```text
00:00 +0: ProjectManifest PathPattern preset operations read returns the manifest pathPatternPresets in order
00:00 +1: ProjectManifest PathPattern preset operations replace swaps the list, preserves other fields, and keeps order
00:00 +2: ProjectManifest PathPattern preset operations replace accepts an empty list and rejects duplicate exact ids
00:00 +3: ProjectManifest PathPattern preset operations replace treats ids with different whitespace as distinct ids
00:00 +4: ProjectManifest PathPattern preset operations upsert appends a new preset at the end
00:00 +5: ProjectManifest PathPattern preset operations upsert replaces an existing preset in place
00:00 +6: ProjectManifest PathPattern preset operations upsert rejects ambiguous existing duplicate ids
00:00 +7: ProjectManifest PathPattern preset operations remove deletes an existing id and preserves order
00:00 +8: ProjectManifest PathPattern preset operations remove missing id is a no-op with an equivalent new manifest
00:00 +9: ProjectManifest PathPattern preset operations remove rejects blank ids and duplicate matching ids
00:00 +10: ProjectManifest PathPattern preset operations clear removes all path pattern presets without mutating original
00:00 +11: ProjectManifest PathPattern preset operations lookup helpers find exact ids, report missing ids, and reject blanks
00:00 +12: ProjectManifest PathPattern preset operations lookup helpers reject duplicate exact ids
00:00 +13: ProjectManifest PathPattern preset operations operations keep pathPatternPresets JSON stable
00:00 +14: All tests passed!
```

### Régression Lot 10

Commande :

```bash
cd packages/map_core && dart test test/project_manifest_path_pattern_presets_test.dart --reporter expanded --no-color
```

Sortie complète :

```text
00:00 +0: ProjectManifest pathPatternPresets decodes old manifests without pathPatternPresets as empty
00:00 +1: ProjectManifest pathPatternPresets decodes pathPatternPresets null as empty
00:00 +2: ProjectManifest pathPatternPresets decodes and encodes empty pathPatternPresets stably
00:00 +3: ProjectManifest pathPatternPresets decodes the Lot 9 minimal golden through ProjectManifest
00:00 +4: ProjectManifest pathPatternPresets decodes the Lot 9 complete golden through ProjectManifest
00:00 +5: ProjectManifest pathPatternPresets roundtrips manifest pathPatternPresets without changing order
00:00 +6: ProjectManifest pathPatternPresets does not migrate legacy pathPresets into pathPatternPresets
00:00 +7: ProjectManifest pathPatternPresets rejects invalid pathPatternPresets payloads
00:00 +8: All tests passed!
```

### Régression Lot 9

Commande :

```bash
cd packages/map_core && dart test test/project_path_pattern_preset_json_golden_test.dart --reporter expanded --no-color
```

Sortie complète :

```text
00:00 +0: ProjectPathPatternPreset JSON golden samples minimal 1x1 golden decodes to the expected preset
00:00 +1: ProjectPathPatternPreset JSON golden samples minimal 1x1 golden matches encode output
00:00 +2: ProjectPathPatternPreset JSON golden samples complete 2x2 golden decodes to the expected preset
00:00 +3: ProjectPathPatternPreset JSON golden samples complete 2x2 golden matches encode output
00:00 +4: ProjectPathPatternPreset JSON golden samples goldens roundtrip through decode and encode
00:00 +5: ProjectPathPatternPreset JSON golden samples goldens use two-space canonical formatting with final newline
00:00 +6: All tests passed!
```

### Régression Lot 8

Commande :

```bash
cd packages/map_core && dart test test/project_path_pattern_preset_json_codec_test.dart --reporter expanded --no-color
```

Sortie complète :

```text
00:00 +0: ProjectPathPatternPreset JSON codec encodes a minimal preset
00:00 +1: ProjectPathPatternPreset JSON codec decodes a minimal preset
00:00 +2: ProjectPathPatternPreset JSON codec roundtrips a minimal preset
00:00 +3: ProjectPathPatternPreset JSON codec encodes a complete 2x2 preset in row-major cell order
00:00 +4: ProjectPathPatternPreset JSON codec roundtrips a complete 2x2 preset
00:00 +5: ProjectPathPatternPreset JSON codec canonicalizes transparentColor after decode and encode
00:00 +6: ProjectPathPatternPreset JSON codec roundtrips frame tileset overrides
00:00 +7: ProjectPathPatternPreset JSON codec roundtrips null and non-null frame durations
00:00 +8: ProjectPathPatternPreset JSON codec rejects invalid JSON
00:00 +9: All tests passed!
```

### Régression Lot 7

Commande :

```bash
cd packages/map_core && dart test test/project_path_pattern_preset_test.dart --reporter expanded --no-color
```

Sortie complète :

```text
00:00 +0: ProjectPathPatternPreset creates a minimal preset with defaults
00:00 +1: ProjectPathPatternPreset creates a complete preset with a 2x2 center pattern
00:00 +2: ProjectPathPatternPreset rejects blank identity fields
00:00 +3: ProjectPathPatternPreset validates with trim but stores original strings
00:00 +4: ProjectPathPatternPreset supports value equality and stable hashCode
00:00 +5: All tests passed!
```

### Régressions PathPattern core

Commandes :

```bash
cd packages/map_core && dart test test/tileset_transparent_color_test.dart --reporter expanded --no-color
cd packages/map_core && dart test test/project_path_preset_center_pattern_adapter_test.dart --reporter expanded --no-color
cd packages/map_core && dart test test/path_center_pattern_resolver_test.dart --reporter expanded --no-color
cd packages/map_core && dart test test/path_center_pattern_test.dart --reporter expanded --no-color
cd packages/map_core && dart test test/map_terrain_autotile_characterization_test.dart --reporter expanded --no-color
```

Sorties complètes :

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

```text
00:00 +0: resolvePathCenterPatternCell 1x1 always resolves to the single local cell
00:00 +1: resolvePathCenterPatternCell 2x2 uses absolute map coordinates modulo pattern size
00:00 +2: resolvePathCenterPatternCell rectangular 3x2 does not assume square patterns
00:00 +3: resolvePathCenterPatternCell invalid coordinates rejects negative map coordinates
00:00 +4: PathCenterPatternCellResolution keeps map coordinates, local coordinates, and selected cell
00:00 +5: PathCenterPatternCellResolution uses value equality and stable hashCode
00:00 +6: All tests passed!
```

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

Sortie finale capturée via Context Mode :

```text
00:01 +1082: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 3. order of atlases preserved
00:01 +1083: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 4. order of animations preserved
00:01 +1084: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 5. order of presets preserved
00:01 +1085: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 6. exposed lists are unmodifiable: add throws
00:01 +1086: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 7. defensive copy: atlases source mutated after build
00:01 +1087: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 8. defensive copy: animations source mutated after build
00:01 +1088: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 9. defensive copy: presets source mutated after build
00:01 +1089: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 10. duplicate atlas id throws ValidationException
00:01 +1090: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 11. duplicate animation id throws ValidationException
00:01 +1091: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 12. duplicate preset id throws ValidationException
00:01 +1092: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 13. same id string across collections is allowed; lookups
00:01 +1093: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 14. atlasById returns instance when present
00:01 +1094: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 15. atlasById null when absent
00:01 +1095: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 16. animationById returns instance when present
00:01 +1096: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 17. animationById null when absent
00:01 +1097: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 18. presetById returns instance when present
00:01 +1098: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 19. presetById null when absent
00:01 +1099: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 20. containsAtlas delegates to lookup
00:01 +1100: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 21. containsAnimation delegates to lookup
00:01 +1101: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 22. containsPreset delegates to lookup
00:01 +1102: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 23. lookups use exact id string (no trim) — atlas
00:01 +1103: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 24. does not resolve missing animationId on preset; no error
00:01 +1104: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 25. value equality: same content same order: == and hashCode
00:01 +1105: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 26. value inequality: different atlas order
00:01 +1106: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 27. value inequality: different animation order
00:01 +1107: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 28. value inequality: different preset order
00:01 +1108: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 29. value inequality: different content
00:01 +1109: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 30. public surface export: ProjectSurfaceCatalog from map_core
00:01 +1110: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 31. ProjectManifest: surfaceCatalog key; no split surface keys (Lot 33 → 49)
00:01 +1111: All tests passed!
```

Ligne finale exacte :

```text
00:01 +1111: All tests passed!
```

## 13. Analyze

Commande :

```bash
cd packages/map_editor && flutter analyze lib/src/features/path_studio/path_pattern_editor_read_model.dart test/path_pattern/path_pattern_editor_read_model_test.dart
```

Sortie complète :

```text
Analyzing 2 items...                                            
No issues found! (ran in 1.7s)
```

Audit no accidental coupling :

```bash
cd packages/map_editor && rg -n "package:image|dart:io|package:flutter/widgets|package:flutter/material|map_runtime|map_gameplay|map_battle|renderPathCenterPatternStaticPreviewPng|renderPathCenterPatternAnimatedPreviewPng|Image\\.memory|MemoryImage|Provider|Notifier|Controller" lib/src/features/path_studio/path_pattern_editor_read_model.dart test/path_pattern/path_pattern_editor_read_model_test.dart
```

Sortie complète :

```text
(aucune sortie)
```

## 14. Non-objectifs confirmés

Confirmé :

- pas de Path Studio UI ;
- pas de nouvelle UI ;
- pas de widget Flutter ;
- pas de provider Riverpod ;
- pas de notifier ;
- pas de controller ;
- pas de save flow ;
- pas de modification `ProjectManifest` ;
- pas de modification `map_core` par ce lot ;
- pas de modification generated ;
- pas de build_runner ;
- pas de JSON ;
- pas de codec ;
- pas de migration ;
- pas de painter integration ;
- pas de canvas rendering ;
- pas de runtime ;
- pas de gameplay ;
- pas de MapGameplayZone ;
- pas de modification `map_runtime` ;
- pas de modification `map_gameplay` ;
- pas de modification `map_battle` ;
- pas de preview PNG générée ;
- pas de lecture de fichiers image ;
- pas d'écriture disque ;
- pas de traitement hautes herbes.

## 15. Limites restantes

- Le read model ne crée pas de preview PNG et ne résout aucun tileset effectif.
- `needsReview` existe pour l'UI future, mais les issues V0 sont toutes bloquantes.
- Le read model ne vérifie pas l'existence des images tileset ni les overrides `tilesetId`.
- Le test complet `map_editor` n'a pas été lancé ; ce lot est limité à un read model pur et les tests `test/path_pattern` demandés plus l'analyze ciblé ont été lancés.

## 16. Git status final

Commande :

```bash
git status --short --untracked-files=all
```

Sortie complète :

```text
 M packages/map_core/lib/map_core.dart
?? packages/map_core/lib/src/operations/project_manifest_path_pattern_preset_operations.dart
?? packages/map_core/test/project_manifest_path_pattern_preset_operations_test.dart
?? packages/map_editor/lib/src/features/path_studio/path_pattern_editor_read_model.dart
?? packages/map_editor/test/path_pattern/path_pattern_editor_read_model_test.dart
?? reports/pathPattern/path_pattern_lot_11_manifest_operations.md
?? reports/pathPattern/path_pattern_lot_12_editor_read_model.md
```

Les entrées `packages/map_core/...` et le rapport Lot 11 étaient déjà présentes au démarrage du Lot 12.

## 17. Prochain lot recommandé

Prochain lot recommandé :

```text
PathPattern-13 — Path Studio Shell V0
```

Objectif recommandé :

- créer un shell UI minimal, sans painter et sans save flow ;
- consommer `createPathPatternEditorReadModel` ;
- afficher la liste et les statuts sans encore éditer les presets.

## Evidence Pack

### Contenu complet — path_pattern_editor_read_model.dart

```dart
import 'package:map_core/map_core.dart';

enum PathPatternPresetReadinessStatus {
  ready,
  needsReview,
  blocked,
}

enum PathPatternPresetIssueCode {
  missingBasePathPreset,
  duplicatePathPatternId,
  duplicateBasePathPresetId,
}

final class PathPatternEditorReadModel {
  PathPatternEditorReadModel({
    required this.summary,
    required List<PathPatternPresetCardModel> presets,
  }) : presets = List<PathPatternPresetCardModel>.unmodifiable(presets);

  final PathPatternEditorSummary summary;
  final List<PathPatternPresetCardModel> presets;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is PathPatternEditorReadModel &&
            summary == other.summary &&
            _listEquals(presets, other.presets);
  }

  @override
  int get hashCode => Object.hash(summary, Object.hashAll(presets));
}

final class PathPatternEditorSummary {
  const PathPatternEditorSummary({
    required this.totalCount,
    required this.readyCount,
    required this.issueCount,
    required this.multiCellCenterCount,
    required this.transparentColorCount,
    required this.missingBasePathPresetCount,
    required this.duplicatePathPatternIdCount,
    required this.duplicateBasePathPresetIdCount,
  });

  final int totalCount;
  final int readyCount;
  final int issueCount;
  final int multiCellCenterCount;
  final int transparentColorCount;
  final int missingBasePathPresetCount;
  final int duplicatePathPatternIdCount;
  final int duplicateBasePathPresetIdCount;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is PathPatternEditorSummary &&
            totalCount == other.totalCount &&
            readyCount == other.readyCount &&
            issueCount == other.issueCount &&
            multiCellCenterCount == other.multiCellCenterCount &&
            transparentColorCount == other.transparentColorCount &&
            missingBasePathPresetCount == other.missingBasePathPresetCount &&
            duplicatePathPatternIdCount == other.duplicatePathPatternIdCount &&
            duplicateBasePathPresetIdCount ==
                other.duplicateBasePathPresetIdCount;
  }

  @override
  int get hashCode => Object.hash(
        totalCount,
        readyCount,
        issueCount,
        multiCellCenterCount,
        transparentColorCount,
        missingBasePathPresetCount,
        duplicatePathPatternIdCount,
        duplicateBasePathPresetIdCount,
      );
}

final class PathPatternPresetCardModel {
  PathPatternPresetCardModel({
    required this.id,
    required this.name,
    required this.basePathPresetId,
    required this.basePathPresetName,
    required this.basePathSurfaceKindLabel,
    required this.centerPatternLabel,
    required this.centerWidth,
    required this.centerHeight,
    required this.centerCellCount,
    required this.centerFrameCount,
    required this.animatedCellCount,
    required this.transparentColorHex,
    required this.status,
    required List<PathPatternPresetIssueCode> issues,
  }) : issues = List<PathPatternPresetIssueCode>.unmodifiable(issues);

  final String id;
  final String name;
  final String basePathPresetId;
  final String? basePathPresetName;
  final String? basePathSurfaceKindLabel;
  final String centerPatternLabel;
  final int centerWidth;
  final int centerHeight;
  final int centerCellCount;
  final int centerFrameCount;
  final int animatedCellCount;
  final String? transparentColorHex;
  final PathPatternPresetReadinessStatus status;
  final List<PathPatternPresetIssueCode> issues;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is PathPatternPresetCardModel &&
            id == other.id &&
            name == other.name &&
            basePathPresetId == other.basePathPresetId &&
            basePathPresetName == other.basePathPresetName &&
            basePathSurfaceKindLabel == other.basePathSurfaceKindLabel &&
            centerPatternLabel == other.centerPatternLabel &&
            centerWidth == other.centerWidth &&
            centerHeight == other.centerHeight &&
            centerCellCount == other.centerCellCount &&
            centerFrameCount == other.centerFrameCount &&
            animatedCellCount == other.animatedCellCount &&
            transparentColorHex == other.transparentColorHex &&
            status == other.status &&
            _listEquals(issues, other.issues);
  }

  @override
  int get hashCode => Object.hash(
        id,
        name,
        basePathPresetId,
        basePathPresetName,
        basePathSurfaceKindLabel,
        centerPatternLabel,
        centerWidth,
        centerHeight,
        centerCellCount,
        centerFrameCount,
        animatedCellCount,
        transparentColorHex,
        status,
        Object.hashAll(issues),
      );
}

PathPatternEditorReadModel createPathPatternEditorReadModel({
  required ProjectManifest manifest,
}) {
  final pathPatternPresets = readProjectPathPatternPresets(manifest);
  final pathPatternIdCounts = _countPathPatternPresetIds(pathPatternPresets);
  final basePathPresetsById = _indexBasePathPresets(manifest.pathPresets);

  final cards = <PathPatternPresetCardModel>[];
  for (final preset in pathPatternPresets) {
    final issues = <PathPatternPresetIssueCode>[];
    if ((pathPatternIdCounts[preset.id] ?? 0) > 1) {
      issues.add(PathPatternPresetIssueCode.duplicatePathPatternId);
    }

    ProjectPathPreset? basePathPreset;
    final basePathMatches = basePathPresetsById[preset.basePathPresetId];
    if (basePathMatches == null || basePathMatches.isEmpty) {
      issues.add(PathPatternPresetIssueCode.missingBasePathPreset);
    } else if (basePathMatches.length > 1) {
      issues.add(PathPatternPresetIssueCode.duplicateBasePathPresetId);
    } else {
      basePathPreset = basePathMatches.single;
    }

    cards.add(
      PathPatternPresetCardModel(
        id: preset.id,
        name: preset.name,
        basePathPresetId: preset.basePathPresetId,
        basePathPresetName: basePathPreset?.name,
        basePathSurfaceKindLabel: basePathPreset == null
            ? null
            : _pathSurfaceKindLabel(basePathPreset.surfaceKind),
        centerPatternLabel: _centerPatternLabel(preset.centerPattern),
        centerWidth: preset.centerPattern.size.width,
        centerHeight: preset.centerPattern.size.height,
        centerCellCount: preset.centerPattern.cells.length,
        centerFrameCount: _centerFrameCount(preset.centerPattern),
        animatedCellCount: _animatedCellCount(preset.centerPattern),
        transparentColorHex: preset.transparentColor?.toHexRgb(),
        status: _statusForIssues(issues),
        issues: issues,
      ),
    );
  }

  return PathPatternEditorReadModel(
    summary: _summaryForCards(cards),
    presets: cards,
  );
}

Map<String, int> _countPathPatternPresetIds(
  List<ProjectPathPatternPreset> presets,
) {
  final counts = <String, int>{};
  for (final preset in presets) {
    counts[preset.id] = (counts[preset.id] ?? 0) + 1;
  }
  return counts;
}

Map<String, List<ProjectPathPreset>> _indexBasePathPresets(
  List<ProjectPathPreset> presets,
) {
  final byId = <String, List<ProjectPathPreset>>{};
  for (final preset in presets) {
    byId.putIfAbsent(preset.id, () => []).add(preset);
  }
  return byId;
}

String _centerPatternLabel(PathCenterPattern pattern) {
  return '${pattern.size.width}×${pattern.size.height}';
}

int _centerFrameCount(PathCenterPattern pattern) {
  return pattern.cells.fold(
    0,
    (total, cell) => total + cell.frames.length,
  );
}

int _animatedCellCount(PathCenterPattern pattern) {
  return pattern.cells.where((cell) => cell.frames.length > 1).length;
}

PathPatternPresetReadinessStatus _statusForIssues(
  List<PathPatternPresetIssueCode> issues,
) {
  if (issues.isEmpty) {
    return PathPatternPresetReadinessStatus.ready;
  }
  if (issues.any(_isBlockingIssue)) {
    return PathPatternPresetReadinessStatus.blocked;
  }
  return PathPatternPresetReadinessStatus.needsReview;
}

bool _isBlockingIssue(PathPatternPresetIssueCode issue) {
  return switch (issue) {
    PathPatternPresetIssueCode.missingBasePathPreset => true,
    PathPatternPresetIssueCode.duplicatePathPatternId => true,
    PathPatternPresetIssueCode.duplicateBasePathPresetId => true,
  };
}

PathPatternEditorSummary _summaryForCards(
  List<PathPatternPresetCardModel> cards,
) {
  return PathPatternEditorSummary(
    totalCount: cards.length,
    readyCount: cards
        .where((card) => card.status == PathPatternPresetReadinessStatus.ready)
        .length,
    issueCount: cards.where((card) => card.issues.isNotEmpty).length,
    multiCellCenterCount: cards
        .where((card) => card.centerWidth > 1 || card.centerHeight > 1)
        .length,
    transparentColorCount:
        cards.where((card) => card.transparentColorHex != null).length,
    missingBasePathPresetCount: cards
        .where(
          (card) => card.issues.contains(
            PathPatternPresetIssueCode.missingBasePathPreset,
          ),
        )
        .length,
    duplicatePathPatternIdCount: cards
        .where(
          (card) => card.issues.contains(
            PathPatternPresetIssueCode.duplicatePathPatternId,
          ),
        )
        .length,
    duplicateBasePathPresetIdCount: cards
        .where(
          (card) => card.issues.contains(
            PathPatternPresetIssueCode.duplicateBasePathPresetId,
          ),
        )
        .length,
  );
}

String _pathSurfaceKindLabel(PathSurfaceKind surfaceKind) {
  return switch (surfaceKind) {
    PathSurfaceKind.path => 'Chemin',
    PathSurfaceKind.road => 'Route',
    PathSurfaceKind.water => 'Eau',
    PathSurfaceKind.tallGrass => 'Hautes herbes',
    PathSurfaceKind.ice => 'Glace',
    PathSurfaceKind.lava => 'Lave',
    PathSurfaceKind.swamp => 'Marais',
    PathSurfaceKind.rails => 'Rails',
    PathSurfaceKind.bridge => 'Pont',
    PathSurfaceKind.special => 'Spécial',
    PathSurfaceKind.custom => 'Personnalisé',
  };
}

bool _listEquals<T>(List<T> left, List<T> right) {
  if (left.length != right.length) {
    return false;
  }
  for (var i = 0; i < left.length; i += 1) {
    if (left[i] != right[i]) {
      return false;
    }
  }
  return true;
}
```

### Contenu complet — path_pattern_editor_read_model_test.dart

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/path_studio/path_pattern_editor_read_model.dart';

void main() {
  group('createPathPatternEditorReadModel', () {
    test('empty manifest exposes an empty summary and no cards', () {
      final readModel = createPathPatternEditorReadModel(
        manifest: _manifest(),
      );

      expect(readModel.presets, isEmpty);
      expect(readModel.summary.totalCount, 0);
      expect(readModel.summary.readyCount, 0);
      expect(readModel.summary.issueCount, 0);
      expect(readModel.summary.multiCellCenterCount, 0);
      expect(readModel.summary.transparentColorCount, 0);
      expect(readModel.summary.missingBasePathPresetCount, 0);
      expect(readModel.summary.duplicatePathPatternIdCount, 0);
      expect(readModel.summary.duplicateBasePathPresetIdCount, 0);
    });

    test('ready 1x1 preset exposes list card details', () {
      final readModel = createPathPatternEditorReadModel(
        manifest: _manifest(
          pathPresets: [_legacyPathPreset(id: 'legacy-water')],
          pathPatternPresets: [
            _pathPatternPreset(
              id: 'water-1x1',
              name: 'Water 1x1',
              basePathPresetId: 'legacy-water',
              pattern: _singleCellPattern(),
            ),
          ],
        ),
      );

      expect(readModel.summary.totalCount, 1);
      expect(readModel.summary.readyCount, 1);
      expect(readModel.summary.issueCount, 0);

      final card = readModel.presets.single;
      expect(card.id, 'water-1x1');
      expect(card.name, 'Water 1x1');
      expect(card.basePathPresetId, 'legacy-water');
      expect(card.basePathPresetName, 'Legacy Water');
      expect(card.basePathSurfaceKindLabel, 'Eau');
      expect(card.centerPatternLabel, '1×1');
      expect(card.centerWidth, 1);
      expect(card.centerHeight, 1);
      expect(card.centerCellCount, 1);
      expect(card.centerFrameCount, 1);
      expect(card.animatedCellCount, 0);
      expect(card.transparentColorHex, isNull);
      expect(card.status, PathPatternPresetReadinessStatus.ready);
      expect(card.issues, isEmpty);
    });

    test('ready 2x2 transparent animated preset exposes counts', () {
      final readModel = createPathPatternEditorReadModel(
        manifest: _manifest(
          pathPresets: [_legacyPathPreset(id: 'legacy-water')],
          pathPatternPresets: [
            _pathPatternPreset(
              id: 'sea-2x2',
              basePathPresetId: 'legacy-water',
              pattern: _twoByTwoPattern(animatedTopLeft: true),
              transparentColor: TilesetTransparentColor.fromHexRgb('f05ba1'),
            ),
          ],
        ),
      );

      final card = readModel.presets.single;
      expect(card.centerPatternLabel, '2×2');
      expect(card.centerWidth, 2);
      expect(card.centerHeight, 2);
      expect(card.centerCellCount, 4);
      expect(card.centerFrameCount, 5);
      expect(card.animatedCellCount, 1);
      expect(card.transparentColorHex, 'f05ba1');
      expect(card.status, PathPatternPresetReadinessStatus.ready);
      expect(readModel.summary.readyCount, 1);
      expect(readModel.summary.multiCellCenterCount, 1);
      expect(readModel.summary.transparentColorCount, 1);
    });

    test('missing basePathPresetId blocks the card', () {
      final readModel = createPathPatternEditorReadModel(
        manifest: _manifest(
          pathPresets: [_legacyPathPreset(id: 'legacy-water')],
          pathPatternPresets: [
            _pathPatternPreset(
              id: 'missing-base',
              basePathPresetId: 'missing',
            ),
          ],
        ),
      );

      final card = readModel.presets.single;
      expect(card.status, PathPatternPresetReadinessStatus.blocked);
      expect(card.issues, [
        PathPatternPresetIssueCode.missingBasePathPreset,
      ]);
      expect(card.basePathPresetName, isNull);
      expect(card.basePathSurfaceKindLabel, isNull);
      expect(readModel.summary.readyCount, 0);
      expect(readModel.summary.issueCount, 1);
      expect(readModel.summary.missingBasePathPresetCount, 1);
    });

    test('duplicate PathPattern ids block every affected card', () {
      final readModel = createPathPatternEditorReadModel(
        manifest: _manifest(
          pathPresets: [_legacyPathPreset(id: 'legacy-water')],
          pathPatternPresets: [
            _pathPatternPreset(id: 'duplicate'),
            _pathPatternPreset(id: 'duplicate', name: 'Duplicate 2'),
          ],
        ),
      );

      expect(readModel.presets, hasLength(2));
      for (final card in readModel.presets) {
        expect(card.status, PathPatternPresetReadinessStatus.blocked);
        expect(
          card.issues,
          contains(PathPatternPresetIssueCode.duplicatePathPatternId),
        );
      }
      expect(readModel.summary.readyCount, 0);
      expect(readModel.summary.issueCount, 2);
      expect(readModel.summary.duplicatePathPatternIdCount, 2);
    });

    test('duplicate legacy base path preset ids block referencing cards', () {
      final readModel = createPathPatternEditorReadModel(
        manifest: _manifest(
          pathPresets: [
            _legacyPathPreset(id: 'legacy-water', name: 'Water A'),
            _legacyPathPreset(id: 'legacy-water', name: 'Water B'),
          ],
          pathPatternPresets: [
            _pathPatternPreset(
              id: 'ambiguous-base',
              basePathPresetId: 'legacy-water',
            ),
          ],
        ),
      );

      final card = readModel.presets.single;
      expect(card.status, PathPatternPresetReadinessStatus.blocked);
      expect(card.issues, [
        PathPatternPresetIssueCode.duplicateBasePathPresetId,
      ]);
      expect(card.basePathPresetName, isNull);
      expect(card.basePathSurfaceKindLabel, isNull);
      expect(readModel.summary.issueCount, 1);
      expect(readModel.summary.duplicateBasePathPresetIdCount, 1);
    });

    test('preserves manifest pathPatternPresets order', () {
      final readModel = createPathPatternEditorReadModel(
        manifest: _manifest(
          pathPresets: [_legacyPathPreset(id: 'legacy-water')],
          pathPatternPresets: [
            _pathPatternPreset(id: 'a'),
            _pathPatternPreset(id: 'b'),
            _pathPatternPreset(id: 'c'),
          ],
        ),
      );

      expect(readModel.presets.map((card) => card.id), ['a', 'b', 'c']);
    });

    test('matches basePathPresetId exactly without trimming', () {
      final readModel = createPathPatternEditorReadModel(
        manifest: _manifest(
          pathPresets: [_legacyPathPreset(id: 'legacy-water')],
          pathPatternPresets: [
            _pathPatternPreset(
              id: 'whitespace-base',
              basePathPresetId: ' legacy-water ',
            ),
          ],
        ),
      );

      final card = readModel.presets.single;
      expect(card.status, PathPatternPresetReadinessStatus.blocked);
      expect(card.issues, [
        PathPatternPresetIssueCode.missingBasePathPreset,
      ]);
      expect(readModel.summary.missingBasePathPresetCount, 1);
    });

    test('summary counts ready, blocked, duplicates, and multi-cell presets',
        () {
      final readModel = createPathPatternEditorReadModel(
        manifest: _manifest(
          pathPresets: [_legacyPathPreset(id: 'legacy-water')],
          pathPatternPresets: [
            _pathPatternPreset(id: 'ready', pattern: _twoByTwoPattern()),
            _pathPatternPreset(
              id: 'missing-base',
              basePathPresetId: 'missing',
            ),
            _pathPatternPreset(id: 'duplicate'),
            _pathPatternPreset(id: 'duplicate', name: 'Duplicate 2'),
          ],
        ),
      );

      expect(readModel.summary.totalCount, 4);
      expect(readModel.summary.readyCount, 1);
      expect(readModel.summary.issueCount, 3);
      expect(readModel.summary.multiCellCenterCount, 1);
      expect(readModel.summary.missingBasePathPresetCount, 1);
      expect(readModel.summary.duplicatePathPatternIdCount, 2);
      expect(readModel.summary.duplicateBasePathPresetIdCount, 0);
    });

    test('read model and card lists are immutable defensive copies', () {
      final readModel = createPathPatternEditorReadModel(
        manifest: _manifest(
          pathPresets: [_legacyPathPreset(id: 'legacy-water')],
          pathPatternPresets: [_pathPatternPreset(id: 'ready')],
        ),
      );

      expect(
        () => readModel.presets.add(readModel.presets.single),
        throwsUnsupportedError,
      );
      expect(
        () => readModel.presets.single.issues.add(
          PathPatternPresetIssueCode.missingBasePathPreset,
        ),
        throwsUnsupportedError,
      );
    });
  });
}

ProjectManifest _manifest({
  List<ProjectPathPreset> pathPresets = const [],
  List<ProjectPathPatternPreset> pathPatternPresets = const [],
}) {
  return ProjectManifest(
    name: 'Project',
    maps: const [],
    tilesets: const [],
    pathPresets: pathPresets,
    pathPatternPresets: pathPatternPresets,
    surfaceCatalog: ProjectSurfaceCatalog(),
  );
}

ProjectPathPreset _legacyPathPreset({
  required String id,
  String name = 'Legacy Water',
  PathSurfaceKind surfaceKind = PathSurfaceKind.water,
}) {
  return ProjectPathPreset(
    id: id,
    name: name,
    surfaceKind: surfaceKind,
  );
}

ProjectPathPatternPreset _pathPatternPreset({
  required String id,
  String? name,
  String basePathPresetId = 'legacy-water',
  PathCenterPattern? pattern,
  TilesetTransparentColor? transparentColor,
}) {
  return ProjectPathPatternPreset(
    id: id,
    name: name ?? id,
    basePathPresetId: basePathPresetId,
    centerPattern: pattern ?? _singleCellPattern(),
    transparentColor: transparentColor,
  );
}

PathCenterPattern _singleCellPattern() {
  return PathCenterPattern(
    size: PathCenterPatternSize(width: 1, height: 1),
    cells: [
      PathCenterPatternCell(
        localX: 0,
        localY: 0,
        frames: [_frame(0)],
      ),
    ],
  );
}

PathCenterPattern _twoByTwoPattern({bool animatedTopLeft = false}) {
  return PathCenterPattern(
    size: PathCenterPatternSize(width: 2, height: 2),
    cells: [
      PathCenterPatternCell(
        localX: 0,
        localY: 0,
        frames: animatedTopLeft ? [_frame(0), _frame(1)] : [_frame(0)],
      ),
      PathCenterPatternCell(
        localX: 1,
        localY: 0,
        frames: [_frame(2)],
      ),
      PathCenterPatternCell(
        localX: 0,
        localY: 1,
        frames: [_frame(3)],
      ),
      PathCenterPatternCell(
        localX: 1,
        localY: 1,
        frames: [_frame(4)],
      ),
    ],
  );
}

TilesetVisualFrame _frame(int sourceX) {
  return TilesetVisualFrame(
    source: TilesetSourceRect(x: sourceX, y: 0),
  );
}
```

### Diff complet réel — path_pattern_editor_read_model.dart

```diff
diff --git a/packages/map_editor/lib/src/features/path_studio/path_pattern_editor_read_model.dart b/packages/map_editor/lib/src/features/path_studio/path_pattern_editor_read_model.dart
new file mode 100644
index 00000000..40475d0d
--- /dev/null
+++ b/packages/map_editor/lib/src/features/path_studio/path_pattern_editor_read_model.dart
@@ -0,0 +1,328 @@
+import 'package:map_core/map_core.dart';
+
+enum PathPatternPresetReadinessStatus {
+  ready,
+  needsReview,
+  blocked,
+}
+
+enum PathPatternPresetIssueCode {
+  missingBasePathPreset,
+  duplicatePathPatternId,
+  duplicateBasePathPresetId,
+}
+
+final class PathPatternEditorReadModel {
+  PathPatternEditorReadModel({
+    required this.summary,
+    required List<PathPatternPresetCardModel> presets,
+  }) : presets = List<PathPatternPresetCardModel>.unmodifiable(presets);
+
+  final PathPatternEditorSummary summary;
+  final List<PathPatternPresetCardModel> presets;
+
+  @override
+  bool operator ==(Object other) {
+    return identical(this, other) ||
+        other is PathPatternEditorReadModel &&
+            summary == other.summary &&
+            _listEquals(presets, other.presets);
+  }
+
+  @override
+  int get hashCode => Object.hash(summary, Object.hashAll(presets));
+}
+
+final class PathPatternEditorSummary {
+  const PathPatternEditorSummary({
+    required this.totalCount,
+    required this.readyCount,
+    required this.issueCount,
+    required this.multiCellCenterCount,
+    required this.transparentColorCount,
+    required this.missingBasePathPresetCount,
+    required this.duplicatePathPatternIdCount,
+    required this.duplicateBasePathPresetIdCount,
+  });
+
+  final int totalCount;
+  final int readyCount;
+  final int issueCount;
+  final int multiCellCenterCount;
+  final int transparentColorCount;
+  final int missingBasePathPresetCount;
+  final int duplicatePathPatternIdCount;
+  final int duplicateBasePathPresetIdCount;
+
+  @override
+  bool operator ==(Object other) {
+    return identical(this, other) ||
+        other is PathPatternEditorSummary &&
+            totalCount == other.totalCount &&
+            readyCount == other.readyCount &&
+            issueCount == other.issueCount &&
+            multiCellCenterCount == other.multiCellCenterCount &&
+            transparentColorCount == other.transparentColorCount &&
+            missingBasePathPresetCount == other.missingBasePathPresetCount &&
+            duplicatePathPatternIdCount == other.duplicatePathPatternIdCount &&
+            duplicateBasePathPresetIdCount ==
+                other.duplicateBasePathPresetIdCount;
+  }
+
+  @override
+  int get hashCode => Object.hash(
+        totalCount,
+        readyCount,
+        issueCount,
+        multiCellCenterCount,
+        transparentColorCount,
+        missingBasePathPresetCount,
+        duplicatePathPatternIdCount,
+        duplicateBasePathPresetIdCount,
+      );
+}
+
+final class PathPatternPresetCardModel {
+  PathPatternPresetCardModel({
+    required this.id,
+    required this.name,
+    required this.basePathPresetId,
+    required this.basePathPresetName,
+    required this.basePathSurfaceKindLabel,
+    required this.centerPatternLabel,
+    required this.centerWidth,
+    required this.centerHeight,
+    required this.centerCellCount,
+    required this.centerFrameCount,
+    required this.animatedCellCount,
+    required this.transparentColorHex,
+    required this.status,
+    required List<PathPatternPresetIssueCode> issues,
+  }) : issues = List<PathPatternPresetIssueCode>.unmodifiable(issues);
+
+  final String id;
+  final String name;
+  final String basePathPresetId;
+  final String? basePathPresetName;
+  final String? basePathSurfaceKindLabel;
+  final String centerPatternLabel;
+  final int centerWidth;
+  final int centerHeight;
+  final int centerCellCount;
+  final int centerFrameCount;
+  final int animatedCellCount;
+  final String? transparentColorHex;
+  final PathPatternPresetReadinessStatus status;
+  final List<PathPatternPresetIssueCode> issues;
+
+  @override
+  bool operator ==(Object other) {
+    return identical(this, other) ||
+        other is PathPatternPresetCardModel &&
+            id == other.id &&
+            name == other.name &&
+            basePathPresetId == other.basePathPresetId &&
+            basePathPresetName == other.basePathPresetName &&
+            basePathSurfaceKindLabel == other.basePathSurfaceKindLabel &&
+            centerPatternLabel == other.centerPatternLabel &&
+            centerWidth == other.centerWidth &&
+            centerHeight == other.centerHeight &&
+            centerCellCount == other.centerCellCount &&
+            centerFrameCount == other.centerFrameCount &&
+            animatedCellCount == other.animatedCellCount &&
+            transparentColorHex == other.transparentColorHex &&
+            status == other.status &&
+            _listEquals(issues, other.issues);
+  }
+
+  @override
+  int get hashCode => Object.hash(
+        id,
+        name,
+        basePathPresetId,
+        basePathPresetName,
+        basePathSurfaceKindLabel,
+        centerPatternLabel,
+        centerWidth,
+        centerHeight,
+        centerCellCount,
+        centerFrameCount,
+        animatedCellCount,
+        transparentColorHex,
+        status,
+        Object.hashAll(issues),
+      );
+}
+
+PathPatternEditorReadModel createPathPatternEditorReadModel({
+  required ProjectManifest manifest,
+}) {
+  final pathPatternPresets = readProjectPathPatternPresets(manifest);
+  final pathPatternIdCounts = _countPathPatternPresetIds(pathPatternPresets);
+  final basePathPresetsById = _indexBasePathPresets(manifest.pathPresets);
+
+  final cards = <PathPatternPresetCardModel>[];
+  for (final preset in pathPatternPresets) {
+    final issues = <PathPatternPresetIssueCode>[];
+    if ((pathPatternIdCounts[preset.id] ?? 0) > 1) {
+      issues.add(PathPatternPresetIssueCode.duplicatePathPatternId);
+    }
+
+    ProjectPathPreset? basePathPreset;
+    final basePathMatches = basePathPresetsById[preset.basePathPresetId];
+    if (basePathMatches == null || basePathMatches.isEmpty) {
+      issues.add(PathPatternPresetIssueCode.missingBasePathPreset);
+    } else if (basePathMatches.length > 1) {
+      issues.add(PathPatternPresetIssueCode.duplicateBasePathPresetId);
+    } else {
+      basePathPreset = basePathMatches.single;
+    }
+
+    cards.add(
+      PathPatternPresetCardModel(
+        id: preset.id,
+        name: preset.name,
+        basePathPresetId: preset.basePathPresetId,
+        basePathPresetName: basePathPreset?.name,
+        basePathSurfaceKindLabel: basePathPreset == null
+            ? null
+            : _pathSurfaceKindLabel(basePathPreset.surfaceKind),
+        centerPatternLabel: _centerPatternLabel(preset.centerPattern),
+        centerWidth: preset.centerPattern.size.width,
+        centerHeight: preset.centerPattern.size.height,
+        centerCellCount: preset.centerPattern.cells.length,
+        centerFrameCount: _centerFrameCount(preset.centerPattern),
+        animatedCellCount: _animatedCellCount(preset.centerPattern),
+        transparentColorHex: preset.transparentColor?.toHexRgb(),
+        status: _statusForIssues(issues),
+        issues: issues,
+      ),
+    );
+  }
+
+  return PathPatternEditorReadModel(
+    summary: _summaryForCards(cards),
+    presets: cards,
+  );
+}
+
+Map<String, int> _countPathPatternPresetIds(
+  List<ProjectPathPatternPreset> presets,
+) {
+  final counts = <String, int>{};
+  for (final preset in presets) {
+    counts[preset.id] = (counts[preset.id] ?? 0) + 1;
+  }
+  return counts;
+}
+
+Map<String, List<ProjectPathPreset>> _indexBasePathPresets(
+  List<ProjectPathPreset> presets,
+) {
+  final byId = <String, List<ProjectPathPreset>>{};
+  for (final preset in presets) {
+    byId.putIfAbsent(preset.id, () => []).add(preset);
+  }
+  return byId;
+}
+
+String _centerPatternLabel(PathCenterPattern pattern) {
+  return '${pattern.size.width}×${pattern.size.height}';
+}
+
+int _centerFrameCount(PathCenterPattern pattern) {
+  return pattern.cells.fold(
+    0,
+    (total, cell) => total + cell.frames.length,
+  );
+}
+
+int _animatedCellCount(PathCenterPattern pattern) {
+  return pattern.cells.where((cell) => cell.frames.length > 1).length;
+}
+
+PathPatternPresetReadinessStatus _statusForIssues(
+  List<PathPatternPresetIssueCode> issues,
+) {
+  if (issues.isEmpty) {
+    return PathPatternPresetReadinessStatus.ready;
+  }
+  if (issues.any(_isBlockingIssue)) {
+    return PathPatternPresetReadinessStatus.blocked;
+  }
+  return PathPatternPresetReadinessStatus.needsReview;
+}
+
+bool _isBlockingIssue(PathPatternPresetIssueCode issue) {
+  return switch (issue) {
+    PathPatternPresetIssueCode.missingBasePathPreset => true,
+    PathPatternPresetIssueCode.duplicatePathPatternId => true,
+    PathPatternPresetIssueCode.duplicateBasePathPresetId => true,
+  };
+}
+
+PathPatternEditorSummary _summaryForCards(
+  List<PathPatternPresetCardModel> cards,
+) {
+  return PathPatternEditorSummary(
+    totalCount: cards.length,
+    readyCount: cards
+        .where((card) => card.status == PathPatternPresetReadinessStatus.ready)
+        .length,
+    issueCount: cards.where((card) => card.issues.isNotEmpty).length,
+    multiCellCenterCount: cards
+        .where((card) => card.centerWidth > 1 || card.centerHeight > 1)
+        .length,
+    transparentColorCount:
+        cards.where((card) => card.transparentColorHex != null).length,
+    missingBasePathPresetCount: cards
+        .where(
+          (card) => card.issues.contains(
+            PathPatternPresetIssueCode.missingBasePathPreset,
+          ),
+        )
+        .length,
+    duplicatePathPatternIdCount: cards
+        .where(
+          (card) => card.issues.contains(
+            PathPatternPresetIssueCode.duplicatePathPatternId,
+          ),
+        )
+        .length,
+    duplicateBasePathPresetIdCount: cards
+        .where(
+          (card) => card.issues.contains(
+            PathPatternPresetIssueCode.duplicateBasePathPresetId,
+          ),
+        )
+        .length,
+  );
+}
+
+String _pathSurfaceKindLabel(PathSurfaceKind surfaceKind) {
+  return switch (surfaceKind) {
+    PathSurfaceKind.path => 'Chemin',
+    PathSurfaceKind.road => 'Route',
+    PathSurfaceKind.water => 'Eau',
+    PathSurfaceKind.tallGrass => 'Hautes herbes',
+    PathSurfaceKind.ice => 'Glace',
+    PathSurfaceKind.lava => 'Lave',
+    PathSurfaceKind.swamp => 'Marais',
+    PathSurfaceKind.rails => 'Rails',
+    PathSurfaceKind.bridge => 'Pont',
+    PathSurfaceKind.special => 'Spécial',
+    PathSurfaceKind.custom => 'Personnalisé',
+  };
+}
+
+bool _listEquals<T>(List<T> left, List<T> right) {
+  if (left.length != right.length) {
+    return false;
+  }
+  for (var i = 0; i < left.length; i += 1) {
+    if (left[i] != right[i]) {
+      return false;
+    }
+  }
+  return true;
+}
```

## Auto-review

- Ai-je évité toute UI ? Oui.
- Ai-je évité provider/notifier/controller ? Oui.
- Ai-je évité PNG/preview generation ? Oui.
- Ai-je évité mutation `ProjectManifest` ? Oui.
- Ai-je évité map_core modifications ? Oui pour le Lot 12.
- Ai-je détecté missing base preset ? Oui.
- Ai-je détecté duplicate PathPattern ids ? Oui.
- Ai-je détecté duplicate legacy base ids ? Oui.
- Ai-je préservé l'ordre ? Oui.
- Ai-je évité runtime/gameplay/battle ? Oui.
- Ai-je évité tall grass ? Oui.

## Critique du prompt

- Ambiguïté rencontrée : `issueCount` pouvait représenter le nombre total d'issues ou le nombre de cards en issue. J'ai retenu le nombre de cards avec au moins une issue, plus utile pour une liste UI.
- Choix d'emplacement : l'emplacement demandé `features/path_studio` a été retenu.
- Décision duplicate count : les compteurs de doublons représentent les cards concernées, pas le nombre d'ids distincts.
- Décision labels : labels français simples pour `PathSurfaceKind`.
- Décision avant Path Studio Shell : valider si le shell doit afficher seulement les cards ou aussi un bandeau de diagnostics global dès V0.
