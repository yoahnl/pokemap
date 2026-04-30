# PathPattern-11 — PathPattern Manifest Operations V0

## 1. Verdict

Lot accepté.

Le lot ajoute des opérations pures `map_core` pour manipuler `ProjectManifest.pathPatternPresets` :

- lecture ;
- remplacement complet ;
- upsert ;
- remove ;
- clear ;
- lookup par id ;
- contains par id.

`ProjectManifest`, les fichiers generated, `ProjectPathPreset`, `PathLayer`, runtime, gameplay, battle, editor UI et canvas restent intacts.

## 2. Audit initial

Commandes initiales :

```bash
pwd
git status --short --untracked-files=all
git diff --stat
rg -n "pathPatternPresets|ProjectPathPatternPreset|ProjectManifest|replace.*Presets|upsert.*Preset|remove.*Preset|clear.*Presets|project_manifest_.*operations|surface.*operations|pathPresets|terrainPresets" packages/map_core/lib packages/map_core/test reports/pathPattern
```

Sortie `pwd` :

```text
/Users/karim/Project/pokemonProject
```

`git status --short --untracked-files=all` initial :

```text
(aucune sortie)
```

`git diff --stat` initial :

```text
(aucune sortie)
```

Context Mode :

```text
ctx shell absent.
Context Mode MCP utilise via ctx_batch_execute pour l'audit initial.
Aucune commande stats dediee n'est exposee par les outils MCP disponibles dans cette session.
```

Réponses d'audit :

1. `ProjectManifest.pathPatternPresets` vit dans `packages/map_core/lib/src/models/project_manifest.dart`.
2. `copyWith(pathPatternPresets: ...)` est généré dans `project_manifest.freezed.dart` depuis le Lot 10.
3. Des opérations pures équivalentes existent pour `surfaceCatalog` dans `packages/map_core/lib/src/operations/project_manifest_surface_catalog_operations.dart`.
4. Aucune opération manifest dédiée aux listes `terrainPresets` / `pathPresets` n'a été trouvée ; les opérations existantes côté map manipulent plutôt les layers.
5. La convention existante utilise des fonctions libres nommées autour de `ProjectManifest` et du champ ciblé, par exemple `replaceProjectManifestSurfaceCatalog`.
6. La validation des doublons d'id existe côté catalogues Surface ; elle utilise des ids exacts et lève `ValidationException`.
7. Les opérations PathPattern sont placées dans `packages/map_core/lib/src/operations/project_manifest_path_pattern_preset_operations.dart`.
8. Les helpers `projectPathPatternPresetById` et `containsProjectPathPatternPreset` ont été ajoutés, car ils seront utiles aux read models editor.
9. `upsert` remplace en place quand l'id exact existe, sinon append en fin de liste.
10. `remove` sur id manquant est un no-op qui retourne un manifest égal mais nouvellement produit par `copyWith`.

## 3. Fichiers créés / modifiés / supprimés

Créés :

```text
packages/map_core/lib/src/operations/project_manifest_path_pattern_preset_operations.dart
packages/map_core/test/project_manifest_path_pattern_preset_operations_test.dart
reports/pathPattern/path_pattern_lot_11_manifest_operations.md
```

Modifiés :

```text
packages/map_core/lib/map_core.dart
```

Supprimés :

```text
aucun
```

## 4. API ajoutée

```dart
List<ProjectPathPatternPreset> readProjectPathPatternPresets(
  ProjectManifest manifest,
)

ProjectPathPatternPreset? projectPathPatternPresetById({
  required ProjectManifest manifest,
  required String presetId,
})

bool containsProjectPathPatternPreset({
  required ProjectManifest manifest,
  required String presetId,
})

ProjectManifest replaceProjectPathPatternPresets({
  required ProjectManifest manifest,
  required List<ProjectPathPatternPreset> presets,
})

ProjectManifest upsertProjectPathPatternPreset({
  required ProjectManifest manifest,
  required ProjectPathPatternPreset preset,
})

ProjectManifest removeProjectPathPatternPreset({
  required ProjectManifest manifest,
  required String presetId,
})

ProjectManifest clearProjectPathPatternPresets(ProjectManifest manifest)
```

## 5. Contrat read

`readProjectPathPatternPresets` retourne `manifest.pathPatternPresets` directement.

Le modèle Freezed expose déjà une liste immuable ; aucune copie supplémentaire n'est faite.

## 6. Contrat replace

`replaceProjectPathPatternPresets` :

- valide les ids uniques exacts ;
- accepte une liste vide ;
- préserve l'ordre fourni ;
- retourne `manifest.copyWith(pathPatternPresets: presets)` ;
- préserve les autres champs du manifest ;
- ne mute pas l'instance source.

## 7. Contrat upsert

`upsertProjectPathPatternPreset` :

- valide que la liste existante ne contient pas de doublons ;
- append en fin si l'id exact n'existe pas ;
- remplace à la même position si l'id exact existe ;
- ne trie pas ;
- ne trim pas l'id ;
- ne compare ni `name`, ni `basePathPresetId`.

## 8. Contrat remove

`removeProjectPathPatternPreset` :

- rejette `presetId` blank via `ArgumentError` ;
- supprime par id exact ;
- préserve l'ordre des autres presets ;
- sur id absent, retourne un manifest égal mais nouvellement produit ;
- si plusieurs presets correspondent à l'id exact demandé, lève `ValidationException`.

## 9. Contrat clear

`clearProjectPathPatternPresets` retourne `manifest.copyWith(pathPatternPresets: const [])`.

La fonction fonctionne aussi sur une liste déjà vide et retourne une nouvelle instance équivalente.

## 10. Contrat lookup helpers

`projectPathPatternPresetById` :

- rejette `presetId` blank via `ArgumentError` ;
- retourne le preset si exactement un id correspond ;
- retourne `null` si absent ;
- lève `ValidationException` si plusieurs presets ont l'id exact demandé.

`containsProjectPathPatternPreset` délègue au lookup et garde les mêmes validations.

## 11. Stratégie validation doublons

Le helper privé `_validateUniqueProjectPathPatternPresetIds` valide les doublons d'id exacts, sans trim.

Conséquence volontaire :

```text
"pattern-a"
" pattern-a "
```

sont deux ids distincts pour les opérations, parce que `ProjectPathPatternPreset` valide avec `trim()` mais stocke la valeur originale.

Message d'erreur :

```text
Duplicate ProjectPathPatternPreset id: <id>
```

## 12. Tests lancés

### Test rouge TDD

Commande :

```bash
cd packages/map_core && dart test test/project_manifest_path_pattern_preset_operations_test.dart --reporter expanded --no-color
```

Sortie complète :

```text
00:00 +0: loading test/project_manifest_path_pattern_preset_operations_test.dart
00:00 +0 -1: loading test/project_manifest_path_pattern_preset_operations_test.dart [E]
  Failed to load "test/project_manifest_path_pattern_preset_operations_test.dart":
  test/project_manifest_path_pattern_preset_operations_test.dart:10:14: Error: Method not found: 'readProjectPathPatternPresets'.
        expect(readProjectPathPatternPresets(empty), isEmpty);
               ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  test/project_manifest_path_pattern_preset_operations_test.dart:11:14: Error: Method not found: 'readProjectPathPatternPresets'.
        expect(readProjectPathPatternPresets(withPresets), [_presetA(), _presetB()]);
               ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  test/project_manifest_path_pattern_preset_operations_test.dart:22:20: Error: Method not found: 'replaceProjectPathPatternPresets'.
        final next = replaceProjectPathPatternPresets(
                     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  test/project_manifest_path_pattern_preset_operations_test.dart:39:23: Error: Method not found: 'replaceProjectPathPatternPresets'.
        final cleared = replaceProjectPathPatternPresets(
                        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  test/project_manifest_path_pattern_preset_operations_test.dart:46:15: Error: Method not found: 'replaceProjectPathPatternPresets'.
          () => replaceProjectPathPatternPresets(
                ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  test/project_manifest_path_pattern_preset_operations_test.dart:57:20: Error: Method not found: 'replaceProjectPathPatternPresets'.
        final next = replaceProjectPathPatternPresets(
                     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  test/project_manifest_path_pattern_preset_operations_test.dart:71:20: Error: Method not found: 'upsertProjectPathPatternPreset'.
        final next = upsertProjectPathPatternPreset(
                     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  test/project_manifest_path_pattern_preset_operations_test.dart:86:20: Error: Method not found: 'upsertProjectPathPatternPreset'.
        final next = upsertProjectPathPatternPreset(
                     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  test/project_manifest_path_pattern_preset_operations_test.dart:101:15: Error: Method not found: 'upsertProjectPathPatternPreset'.
          () => upsertProjectPathPatternPreset(
                ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  test/project_manifest_path_pattern_preset_operations_test.dart:114:20: Error: Method not found: 'removeProjectPathPatternPreset'.
        final next = removeProjectPathPatternPreset(
                     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  test/project_manifest_path_pattern_preset_operations_test.dart:126:20: Error: Method not found: 'removeProjectPathPatternPreset'.
        final next = removeProjectPathPatternPreset(
                     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  test/project_manifest_path_pattern_preset_operations_test.dart:143:15: Error: Method not found: 'removeProjectPathPatternPreset'.
          () => removeProjectPathPatternPreset(
                ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  test/project_manifest_path_pattern_preset_operations_test.dart:150:15: Error: Method not found: 'removeProjectPathPatternPreset'.
          () => removeProjectPathPatternPreset(
                ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  test/project_manifest_path_pattern_preset_operations_test.dart:157:15: Error: Method not found: 'removeProjectPathPatternPreset'.
          () => removeProjectPathPatternPreset(
                ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  test/project_manifest_path_pattern_preset_operations_test.dart:169:23: Error: Method not found: 'clearProjectPathPatternPresets'.
        final cleared = clearProjectPathPatternPresets(original);
                        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  test/project_manifest_path_pattern_preset_operations_test.dart:170:28: Error: Method not found: 'clearProjectPathPatternPresets'.
        final clearedAgain = clearProjectPathPatternPresets(alreadyEmpty);
                             ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  test/project_manifest_path_pattern_preset_operations_test.dart:184:9: Error: Method not found: 'projectPathPatternPresetById'.
          projectPathPatternPresetById(
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  test/project_manifest_path_pattern_preset_operations_test.dart:191:9: Error: Method not found: 'projectPathPatternPresetById'.
          projectPathPatternPresetById(
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  test/project_manifest_path_pattern_preset_operations_test.dart:198:9: Error: Method not found: 'containsProjectPathPatternPreset'.
          containsProjectPathPatternPreset(
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  test/project_manifest_path_pattern_preset_operations_test.dart:205:9: Error: Method not found: 'containsProjectPathPatternPreset'.
          containsProjectPathPatternPreset(
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  test/project_manifest_path_pattern_preset_operations_test.dart:212:15: Error: Method not found: 'projectPathPatternPresetById'.
          () => projectPathPatternPresetById(
                ^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  test/project_manifest_path_pattern_preset_operations_test.dart:227:15: Error: Method not found: 'projectPathPatternPresetById'.
          () => projectPathPatternPresetById(
                ^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  test/project_manifest_path_pattern_preset_operations_test.dart:234:15: Error: Method not found: 'containsProjectPathPatternPreset'.
          () => containsProjectPathPatternPreset(
                ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  test/project_manifest_path_pattern_preset_operations_test.dart:243:24: Error: Method not found: 'upsertProjectPathPatternPreset'.
        final upserted = upsertProjectPathPatternPreset(
                         ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  test/project_manifest_path_pattern_preset_operations_test.dart:247:23: Error: Method not found: 'clearProjectPathPatternPresets'.
        final cleared = clearProjectPathPatternPresets(upserted);
                        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
00:00 +0 -1: Some tests failed.
```

### Test ciblé Lot 11

Commande :

```bash
cd packages/map_core && dart test test/project_manifest_path_pattern_preset_operations_test.dart --reporter expanded --no-color
```

Sortie complète :

```text
00:00 +0: loading test/project_manifest_path_pattern_preset_operations_test.dart
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
00:00 +0: loading test/project_manifest_path_pattern_presets_test.dart
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
00:00 +0: loading test/project_path_pattern_preset_json_golden_test.dart
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
00:00 +0: loading test/project_path_pattern_preset_json_codec_test.dart
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
00:00 +0: loading test/project_path_pattern_preset_test.dart
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

### Test complet map_core

Commande :

```bash
cd packages/map_core && dart test --no-color --reporter expanded
```

Sortie finale capturée via Context Mode :

```text
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
cd packages/map_core && dart analyze lib/src/operations/project_manifest_path_pattern_preset_operations.dart test/project_manifest_path_pattern_preset_operations_test.dart
```

Sortie complète :

```text
Analyzing project_manifest_path_pattern_preset_operations.dart, project_manifest_path_pattern_preset_operations_test.dart...
No issues found!
```

## 14. Non-objectifs confirmés

Confirmé :

- pas de modification `ProjectManifest` ;
- pas de modification `project_manifest.freezed.dart` ;
- pas de modification `project_manifest.g.dart` ;
- pas de build_runner ;
- pas de Freezed ;
- pas de generated files ;
- pas de nouveau codec JSON ;
- pas de modification `ProjectPathPatternPreset` ;
- pas de modification `ProjectPathPreset` ;
- pas de modification `PathLayer` ;
- pas de migration automatique `pathPresets -> pathPatternPresets` ;
- pas de Path Studio UI ;
- pas de nouvelle UI ;
- pas de widget Flutter ;
- pas de preview nouvelle ;
- pas de canvas rendering ;
- pas de painter integration ;
- pas de runtime ;
- pas de gameplay ;
- pas de MapGameplayZone ;
- pas de modification `map_runtime` ;
- pas de modification `map_gameplay` ;
- pas de modification `map_battle` ;
- pas de save flow editor ;
- pas de traitement hautes herbes.

## 15. Limites restantes

- Aucun read model editor n'expose encore ces opérations côté `map_editor`.
- Aucun diagnostic ne vérifie encore que `basePathPresetId` pointe vers un `ProjectPathPreset` existant.
- Les opérations ne trient pas et ne normalisent pas les ids ; c'est volontaire pour préserver les valeurs stockées.
- Le test complet `map_editor` n'a pas été lancé, car ce lot ne modifie pas `map_editor`; les trois tests `test/path_pattern` demandés ont été lancés.

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
?? reports/pathPattern/path_pattern_lot_11_manifest_operations.md
```

## 17. Prochain lot recommandé

Prochain lot recommandé :

```text
PathPattern-12 — PathPattern Editor Read Model V0
```

Objectif recommandé :

- exposer une vue de lecture côté editor ;
- lister les `ProjectPathPatternPreset` ;
- relier chaque preset à son `basePathPresetId` sans modifier encore le painter ;
- préparer le shell Path Studio sans construire une grosse UI.

## Evidence Pack

### Contenu complet — map_core.dart

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
export 'src/operations/project_path_pattern_preset_json_codec.dart';
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
export 'src/operations/project_manifest_path_pattern_preset_operations.dart';
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

### Contenu complet — project_manifest_path_pattern_preset_operations.dart

```dart
import '../exceptions/map_exceptions.dart';
import '../models/project_manifest.dart';
import '../models/project_path_pattern_preset.dart';

/// Returns the manifest PathPattern presets as exposed by [ProjectManifest].
List<ProjectPathPatternPreset> readProjectPathPatternPresets(
  ProjectManifest manifest,
) {
  return manifest.pathPatternPresets;
}

/// Returns the PathPattern preset with [presetId], or `null` when absent.
ProjectPathPatternPreset? projectPathPatternPresetById({
  required ProjectManifest manifest,
  required String presetId,
}) {
  _validatePresetId(presetId);
  ProjectPathPatternPreset? found;
  for (final preset in manifest.pathPatternPresets) {
    if (preset.id != presetId) {
      continue;
    }
    if (found != null) {
      throw ValidationException(
          'Duplicate ProjectPathPatternPreset id: $presetId');
    }
    found = preset;
  }
  return found;
}

/// True when [manifest] contains exactly one PathPattern preset with [presetId].
bool containsProjectPathPatternPreset({
  required ProjectManifest manifest,
  required String presetId,
}) {
  return projectPathPatternPresetById(
        manifest: manifest,
        presetId: presetId,
      ) !=
      null;
}

/// Replaces the full manifest PathPattern preset list.
ProjectManifest replaceProjectPathPatternPresets({
  required ProjectManifest manifest,
  required List<ProjectPathPatternPreset> presets,
}) {
  _validateUniqueProjectPathPatternPresetIds(presets);
  return manifest.copyWith(pathPatternPresets: presets);
}

/// Inserts [preset] or replaces the existing preset with the same exact id.
ProjectManifest upsertProjectPathPatternPreset({
  required ProjectManifest manifest,
  required ProjectPathPatternPreset preset,
}) {
  _validateUniqueProjectPathPatternPresetIds(manifest.pathPatternPresets);
  final next = List<ProjectPathPatternPreset>.from(
    manifest.pathPatternPresets,
    growable: true,
  );
  final index = next.indexWhere((existing) => existing.id == preset.id);
  if (index < 0) {
    next.add(preset);
  } else {
    next[index] = preset;
  }
  return manifest.copyWith(pathPatternPresets: next);
}

/// Removes the preset with [presetId], if present.
ProjectManifest removeProjectPathPatternPreset({
  required ProjectManifest manifest,
  required String presetId,
}) {
  _validatePresetId(presetId);
  _validateDuplicateMatches(manifest.pathPatternPresets, presetId);
  final next = [
    for (final preset in manifest.pathPatternPresets)
      if (preset.id != presetId) preset,
  ];
  return manifest.copyWith(pathPatternPresets: next);
}

/// Clears all manifest PathPattern presets.
ProjectManifest clearProjectPathPatternPresets(ProjectManifest manifest) {
  return manifest.copyWith(pathPatternPresets: const []);
}

void _validateUniqueProjectPathPatternPresetIds(
  List<ProjectPathPatternPreset> presets,
) {
  final seen = <String>{};
  for (final preset in presets) {
    if (!seen.add(preset.id)) {
      throw ValidationException(
        'Duplicate ProjectPathPatternPreset id: ${preset.id}',
      );
    }
  }
}

void _validateDuplicateMatches(
  List<ProjectPathPatternPreset> presets,
  String presetId,
) {
  var count = 0;
  for (final preset in presets) {
    if (preset.id == presetId) {
      count += 1;
      if (count > 1) {
        throw ValidationException(
          'Duplicate ProjectPathPatternPreset id: $presetId',
        );
      }
    }
  }
}

void _validatePresetId(String presetId) {
  if (presetId.trim().isEmpty) {
    throw ArgumentError.value(
      presetId,
      'presetId',
      'ProjectPathPatternPreset id must not be blank.',
    );
  }
}
```

### Contenu complet — project_manifest_path_pattern_preset_operations_test.dart

```dart
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectManifest PathPattern preset operations', () {
    test('read returns the manifest pathPatternPresets in order', () {
      final empty = _manifest();
      final withPresets =
          _manifest(pathPatternPresets: [_presetA(), _presetB()]);

      expect(readProjectPathPatternPresets(empty), isEmpty);
      expect(
          readProjectPathPatternPresets(withPresets), [_presetA(), _presetB()]);
    });

    test('replace swaps the list, preserves other fields, and keeps order', () {
      final pathPreset = _legacyPathPreset();
      final original = _manifest(
        name: 'Original',
        pathPresets: [pathPreset],
        pathPatternPresets: [_presetA()],
      );

      final next = replaceProjectPathPatternPresets(
        manifest: original,
        presets: [_presetB(), _presetC()],
      );

      expect(identical(next, original), isFalse);
      expect(next.pathPatternPresets, [_presetB(), _presetC()]);
      expect(next.name, original.name);
      expect(next.maps, original.maps);
      expect(next.tilesets, original.tilesets);
      expect(next.pathPresets, [pathPreset]);
      expect(next.surfaceCatalog, original.surfaceCatalog);
      expect(original.pathPatternPresets, [_presetA()]);
    });

    test('replace accepts an empty list and rejects duplicate exact ids', () {
      final original = _manifest(pathPatternPresets: [_presetA(), _presetB()]);
      final cleared = replaceProjectPathPatternPresets(
        manifest: original,
        presets: const [],
      );

      expect(cleared.pathPatternPresets, isEmpty);
      expect(
        () => replaceProjectPathPatternPresets(
          manifest: original,
          presets: [_presetA(), _presetA(name: 'Duplicate')],
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('replace treats ids with different whitespace as distinct ids', () {
      final original = _manifest();

      final next = replaceProjectPathPatternPresets(
        manifest: original,
        presets: [_presetA(), _preset(' pattern-a ')],
      );

      expect(next.pathPatternPresets.map((preset) => preset.id), [
        'pattern-a',
        ' pattern-a ',
      ]);
    });

    test('upsert appends a new preset at the end', () {
      final original = _manifest(pathPatternPresets: [_presetA()]);

      final next = upsertProjectPathPatternPreset(
        manifest: original,
        preset: _presetB(),
      );

      expect(next.pathPatternPresets, [_presetA(), _presetB()]);
      expect(original.pathPatternPresets, [_presetA()]);
    });

    test('upsert replaces an existing preset in place', () {
      final original = _manifest(
        pathPatternPresets: [_presetA(), _presetB(), _presetC()],
      );
      final replacement = _presetB(name: 'Pattern B replacement');

      final next = upsertProjectPathPatternPreset(
        manifest: original,
        preset: replacement,
      );

      expect(next.pathPatternPresets, [_presetA(), replacement, _presetC()]);
    });

    test('upsert rejects ambiguous existing duplicate ids', () {
      final original = _manifestUnchecked([
        _presetA(),
        _presetA(name: 'Duplicate A'),
      ]);

      expect(
        () => upsertProjectPathPatternPreset(
          manifest: original,
          preset: _presetA(name: 'Replacement A'),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('remove deletes an existing id and preserves order', () {
      final original = _manifest(
        pathPatternPresets: [_presetA(), _presetB(), _presetC()],
      );

      final next = removeProjectPathPatternPreset(
        manifest: original,
        presetId: 'pattern-b',
      );

      expect(next.pathPatternPresets, [_presetA(), _presetC()]);
      expect(original.pathPatternPresets, [_presetA(), _presetB(), _presetC()]);
    });

    test('remove missing id is a no-op with an equivalent new manifest', () {
      final original = _manifest(pathPatternPresets: [_presetA(), _presetB()]);

      final next = removeProjectPathPatternPreset(
        manifest: original,
        presetId: 'missing',
      );

      expect(identical(next, original), isFalse);
      expect(next.pathPatternPresets, [_presetA(), _presetB()]);
      expect(next, original);
    });

    test('remove rejects blank ids and duplicate matching ids', () {
      final original = _manifestUnchecked([
        _presetA(),
        _presetA(name: 'Duplicate A'),
      ]);

      expect(
        () => removeProjectPathPatternPreset(
          manifest: _manifest(),
          presetId: '',
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => removeProjectPathPatternPreset(
          manifest: _manifest(),
          presetId: '   ',
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => removeProjectPathPatternPreset(
          manifest: original,
          presetId: 'pattern-a',
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('clear removes all path pattern presets without mutating original',
        () {
      final original = _manifest(pathPatternPresets: [_presetA(), _presetB()]);
      final alreadyEmpty = _manifest();

      final cleared = clearProjectPathPatternPresets(original);
      final clearedAgain = clearProjectPathPatternPresets(alreadyEmpty);

      expect(cleared.pathPatternPresets, isEmpty);
      expect(clearedAgain.pathPatternPresets, isEmpty);
      expect(original.pathPatternPresets, [_presetA(), _presetB()]);
      expect(identical(cleared, original), isFalse);
      expect(identical(clearedAgain, alreadyEmpty), isFalse);
    });

    test('lookup helpers find exact ids, report missing ids, and reject blanks',
        () {
      final manifest = _manifest(pathPatternPresets: [_presetA(), _presetB()]);

      expect(
        projectPathPatternPresetById(
          manifest: manifest,
          presetId: 'pattern-a',
        ),
        _presetA(),
      );
      expect(
        projectPathPatternPresetById(
          manifest: manifest,
          presetId: 'missing',
        ),
        isNull,
      );
      expect(
        containsProjectPathPatternPreset(
          manifest: manifest,
          presetId: 'pattern-b',
        ),
        isTrue,
      );
      expect(
        containsProjectPathPatternPreset(
          manifest: manifest,
          presetId: 'missing',
        ),
        isFalse,
      );
      expect(
        () => projectPathPatternPresetById(
          manifest: manifest,
          presetId: ' ',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('lookup helpers reject duplicate exact ids', () {
      final manifest = _manifestUnchecked([
        _presetA(),
        _presetA(name: 'Duplicate A'),
      ]);

      expect(
        () => projectPathPatternPresetById(
          manifest: manifest,
          presetId: 'pattern-a',
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => containsProjectPathPatternPreset(
          manifest: manifest,
          presetId: 'pattern-a',
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('operations keep pathPatternPresets JSON stable', () {
      final upserted = upsertProjectPathPatternPreset(
        manifest: _manifest(),
        preset: _presetA(),
      );
      final cleared = clearProjectPathPatternPresets(upserted);

      expect(upserted.toJson()['pathPatternPresets'], [
        encodeProjectPathPatternPreset(_presetA()),
      ]);
      expect(cleared.toJson()['pathPatternPresets'], <Object?>[]);
    });
  });
}

ProjectManifest _manifest({
  String name = 'Project',
  List<ProjectPathPreset> pathPresets = const [],
  List<ProjectPathPatternPreset> pathPatternPresets = const [],
}) {
  return ProjectManifest(
    name: name,
    maps: const [],
    tilesets: const [
      ProjectTilesetEntry(
        id: 'outdoor',
        name: 'Outdoor',
        relativePath: 'tilesets/outdoor.png',
      ),
    ],
    pathPresets: pathPresets,
    pathPatternPresets: pathPatternPresets,
    surfaceCatalog: ProjectSurfaceCatalog(),
  );
}

ProjectManifest _manifestUnchecked(List<ProjectPathPatternPreset> presets) {
  return ProjectManifest.fromJson({
    'name': 'Unchecked',
    'maps': <Object?>[],
    'tilesets': <Object?>[],
    'pathPatternPresets': [
      for (final preset in presets) encodeProjectPathPatternPreset(preset),
    ],
  });
}

ProjectPathPreset _legacyPathPreset() {
  return ProjectPathPreset(
    id: 'legacy-water',
    name: 'Legacy Water',
    surfaceKind: PathSurfaceKind.water,
    tilesetId: 'outdoor',
    variants: [
      PathPresetVariantMapping(
        variant: TerrainPathVariant.cross,
        frames: [
          TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 0)),
        ],
      ),
    ],
  );
}

ProjectPathPatternPreset _presetA({String name = 'Pattern A'}) {
  return _preset('pattern-a', name: name, sortOrder: 1);
}

ProjectPathPatternPreset _presetB({String name = 'Pattern B'}) {
  return _preset('pattern-b', name: name, sortOrder: 2);
}

ProjectPathPatternPreset _presetC({String name = 'Pattern C'}) {
  return _preset('pattern-c', name: name, sortOrder: 3);
}

ProjectPathPatternPreset _preset(
  String id, {
  String? name,
  int sortOrder = 0,
}) {
  return ProjectPathPatternPreset(
    id: id,
    name: name ?? id,
    basePathPresetId: 'legacy-water',
    centerPattern: PathCenterPattern(
      size: PathCenterPatternSize(width: 1, height: 1),
      cells: [
        PathCenterPatternCell(
          localX: 0,
          localY: 0,
          frames: [
            TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 0)),
          ],
        ),
      ],
    ),
    sortOrder: sortOrder,
  );
}
```

### Diff complet réel — map_core.dart

```diff
diff --git a/packages/map_core/lib/map_core.dart b/packages/map_core/lib/map_core.dart
index ed08ac63..e156046f 100644
--- a/packages/map_core/lib/map_core.dart
+++ b/packages/map_core/lib/map_core.dart
@@ -61,6 +61,7 @@ export 'src/operations/surface_variant_animation_ref_set_json_codec.dart';
 export 'src/operations/project_surface_preset_json_codec.dart';
 export 'src/operations/project_surface_catalog_json_codec.dart';
 export 'src/operations/project_manifest_surface_catalog_operations.dart';
+export 'src/operations/project_manifest_path_pattern_preset_operations.dart';
 export 'src/operations/surface_studio_read_model.dart';
 export 'src/operations/tall_grass_authoring_view.dart';
 export 'src/operations/path_animation_rules.dart';
```

### Diff complet réel — project_manifest_path_pattern_preset_operations.dart

```diff
diff --git a/packages/map_core/lib/src/operations/project_manifest_path_pattern_preset_operations.dart b/packages/map_core/lib/src/operations/project_manifest_path_pattern_preset_operations.dart
new file mode 100644
index 00000000..ecdd781e
--- /dev/null
+++ b/packages/map_core/lib/src/operations/project_manifest_path_pattern_preset_operations.dart
@@ -0,0 +1,129 @@
+import '../exceptions/map_exceptions.dart';
+import '../models/project_manifest.dart';
+import '../models/project_path_pattern_preset.dart';
+
+/// Returns the manifest PathPattern presets as exposed by [ProjectManifest].
+List<ProjectPathPatternPreset> readProjectPathPatternPresets(
+  ProjectManifest manifest,
+) {
+  return manifest.pathPatternPresets;
+}
+
+/// Returns the PathPattern preset with [presetId], or `null` when absent.
+ProjectPathPatternPreset? projectPathPatternPresetById({
+  required ProjectManifest manifest,
+  required String presetId,
+}) {
+  _validatePresetId(presetId);
+  ProjectPathPatternPreset? found;
+  for (final preset in manifest.pathPatternPresets) {
+    if (preset.id != presetId) {
+      continue;
+    }
+    if (found != null) {
+      throw ValidationException(
+          'Duplicate ProjectPathPatternPreset id: $presetId');
+    }
+    found = preset;
+  }
+  return found;
+}
+
+/// True when [manifest] contains exactly one PathPattern preset with [presetId].
+bool containsProjectPathPatternPreset({
+  required ProjectManifest manifest,
+  required String presetId,
+}) {
+  return projectPathPatternPresetById(
+        manifest: manifest,
+        presetId: presetId,
+      ) !=
+      null;
+}
+
+/// Replaces the full manifest PathPattern preset list.
+ProjectManifest replaceProjectPathPatternPresets({
+  required ProjectManifest manifest,
+  required List<ProjectPathPatternPreset> presets,
+}) {
+  _validateUniqueProjectPathPatternPresetIds(presets);
+  return manifest.copyWith(pathPatternPresets: presets);
+}
+
+/// Inserts [preset] or replaces the existing preset with the same exact id.
+ProjectManifest upsertProjectPathPatternPreset({
+  required ProjectManifest manifest,
+  required ProjectPathPatternPreset preset,
+}) {
+  _validateUniqueProjectPathPatternPresetIds(manifest.pathPatternPresets);
+  final next = List<ProjectPathPatternPreset>.from(
+    manifest.pathPatternPresets,
+    growable: true,
+  );
+  final index = next.indexWhere((existing) => existing.id == preset.id);
+  if (index < 0) {
+    next.add(preset);
+  } else {
+    next[index] = preset;
+  }
+  return manifest.copyWith(pathPatternPresets: next);
+}
+
+/// Removes the preset with [presetId], if present.
+ProjectManifest removeProjectPathPatternPreset({
+  required ProjectManifest manifest,
+  required String presetId,
+}) {
+  _validatePresetId(presetId);
+  _validateDuplicateMatches(manifest.pathPatternPresets, presetId);
+  final next = [
+    for (final preset in manifest.pathPatternPresets)
+      if (preset.id != presetId) preset,
+  ];
+  return manifest.copyWith(pathPatternPresets: next);
+}
+
+/// Clears all manifest PathPattern presets.
+ProjectManifest clearProjectPathPatternPresets(ProjectManifest manifest) {
+  return manifest.copyWith(pathPatternPresets: const []);
+}
+
+void _validateUniqueProjectPathPatternPresetIds(
+  List<ProjectPathPatternPreset> presets,
+) {
+  final seen = <String>{};
+  for (final preset in presets) {
+    if (!seen.add(preset.id)) {
+      throw ValidationException(
+        'Duplicate ProjectPathPatternPreset id: ${preset.id}',
+      );
+    }
+  }
+}
+
+void _validateDuplicateMatches(
+  List<ProjectPathPatternPreset> presets,
+  String presetId,
+) {
+  var count = 0;
+  for (final preset in presets) {
+    if (preset.id == presetId) {
+      count += 1;
+      if (count > 1) {
+        throw ValidationException(
+          'Duplicate ProjectPathPatternPreset id: $presetId',
+        );
+      }
+    }
+  }
+}
+
+void _validatePresetId(String presetId) {
+  if (presetId.trim().isEmpty) {
+    throw ArgumentError.value(
+      presetId,
+      'presetId',
+      'ProjectPathPatternPreset id must not be blank.',
+    );
+  }
+}
```

### Diff complet réel — project_manifest_path_pattern_preset_operations_test.dart

```diff
diff --git a/packages/map_core/test/project_manifest_path_pattern_preset_operations_test.dart b/packages/map_core/test/project_manifest_path_pattern_preset_operations_test.dart
new file mode 100644
index 00000000..3a4acb1f
--- /dev/null
+++ b/packages/map_core/test/project_manifest_path_pattern_preset_operations_test.dart
@@ -0,0 +1,344 @@
+import 'package:map_core/map_core.dart';
+import 'package:test/test.dart';
+
+void main() {
+  group('ProjectManifest PathPattern preset operations', () {
+    test('read returns the manifest pathPatternPresets in order', () {
+      final empty = _manifest();
+      final withPresets =
+          _manifest(pathPatternPresets: [_presetA(), _presetB()]);
+
+      expect(readProjectPathPatternPresets(empty), isEmpty);
+      expect(
+          readProjectPathPatternPresets(withPresets), [_presetA(), _presetB()]);
+    });
+
+    test('replace swaps the list, preserves other fields, and keeps order', () {
+      final pathPreset = _legacyPathPreset();
+      final original = _manifest(
+        name: 'Original',
+        pathPresets: [pathPreset],
+        pathPatternPresets: [_presetA()],
+      );
+
+      final next = replaceProjectPathPatternPresets(
+        manifest: original,
+        presets: [_presetB(), _presetC()],
+      );
+
+      expect(identical(next, original), isFalse);
+      expect(next.pathPatternPresets, [_presetB(), _presetC()]);
+      expect(next.name, original.name);
+      expect(next.maps, original.maps);
+      expect(next.tilesets, original.tilesets);
+      expect(next.pathPresets, [pathPreset]);
+      expect(next.surfaceCatalog, original.surfaceCatalog);
+      expect(original.pathPatternPresets, [_presetA()]);
+    });
+
+    test('replace accepts an empty list and rejects duplicate exact ids', () {
+      final original = _manifest(pathPatternPresets: [_presetA(), _presetB()]);
+      final cleared = replaceProjectPathPatternPresets(
+        manifest: original,
+        presets: const [],
+      );
+
+      expect(cleared.pathPatternPresets, isEmpty);
+      expect(
+        () => replaceProjectPathPatternPresets(
+          manifest: original,
+          presets: [_presetA(), _presetA(name: 'Duplicate')],
+        ),
+        throwsA(isA<ValidationException>()),
+      );
+    });
+
+    test('replace treats ids with different whitespace as distinct ids', () {
+      final original = _manifest();
+
+      final next = replaceProjectPathPatternPresets(
+        manifest: original,
+        presets: [_presetA(), _preset(' pattern-a ')],
+      );
+
+      expect(next.pathPatternPresets.map((preset) => preset.id), [
+        'pattern-a',
+        ' pattern-a ',
+      ]);
+    });
+
+    test('upsert appends a new preset at the end', () {
+      final original = _manifest(pathPatternPresets: [_presetA()]);
+
+      final next = upsertProjectPathPatternPreset(
+        manifest: original,
+        preset: _presetB(),
+      );
+
+      expect(next.pathPatternPresets, [_presetA(), _presetB()]);
+      expect(original.pathPatternPresets, [_presetA()]);
+    });
+
+    test('upsert replaces an existing preset in place', () {
+      final original = _manifest(
+        pathPatternPresets: [_presetA(), _presetB(), _presetC()],
+      );
+      final replacement = _presetB(name: 'Pattern B replacement');
+
+      final next = upsertProjectPathPatternPreset(
+        manifest: original,
+        preset: replacement,
+      );
+
+      expect(next.pathPatternPresets, [_presetA(), replacement, _presetC()]);
+    });
+
+    test('upsert rejects ambiguous existing duplicate ids', () {
+      final original = _manifestUnchecked([
+        _presetA(),
+        _presetA(name: 'Duplicate A'),
+      ]);
+
+      expect(
+        () => upsertProjectPathPatternPreset(
+          manifest: original,
+          preset: _presetA(name: 'Replacement A'),
+        ),
+        throwsA(isA<ValidationException>()),
+      );
+    });
+
+    test('remove deletes an existing id and preserves order', () {
+      final original = _manifest(
+        pathPatternPresets: [_presetA(), _presetB(), _presetC()],
+      );
+
+      final next = removeProjectPathPatternPreset(
+        manifest: original,
+        presetId: 'pattern-b',
+      );
+
+      expect(next.pathPatternPresets, [_presetA(), _presetC()]);
+      expect(original.pathPatternPresets, [_presetA(), _presetB(), _presetC()]);
+    });
+
+    test('remove missing id is a no-op with an equivalent new manifest', () {
+      final original = _manifest(pathPatternPresets: [_presetA(), _presetB()]);
+
+      final next = removeProjectPathPatternPreset(
+        manifest: original,
+        presetId: 'missing',
+      );
+
+      expect(identical(next, original), isFalse);
+      expect(next.pathPatternPresets, [_presetA(), _presetB()]);
+      expect(next, original);
+    });
+
+    test('remove rejects blank ids and duplicate matching ids', () {
+      final original = _manifestUnchecked([
+        _presetA(),
+        _presetA(name: 'Duplicate A'),
+      ]);
+
+      expect(
+        () => removeProjectPathPatternPreset(
+          manifest: _manifest(),
+          presetId: '',
+        ),
+        throwsA(isA<ArgumentError>()),
+      );
+      expect(
+        () => removeProjectPathPatternPreset(
+          manifest: _manifest(),
+          presetId: '   ',
+        ),
+        throwsA(isA<ArgumentError>()),
+      );
+      expect(
+        () => removeProjectPathPatternPreset(
+          manifest: original,
+          presetId: 'pattern-a',
+        ),
+        throwsA(isA<ValidationException>()),
+      );
+    });
+
+    test('clear removes all path pattern presets without mutating original',
+        () {
+      final original = _manifest(pathPatternPresets: [_presetA(), _presetB()]);
+      final alreadyEmpty = _manifest();
+
+      final cleared = clearProjectPathPatternPresets(original);
+      final clearedAgain = clearProjectPathPatternPresets(alreadyEmpty);
+
+      expect(cleared.pathPatternPresets, isEmpty);
+      expect(clearedAgain.pathPatternPresets, isEmpty);
+      expect(original.pathPatternPresets, [_presetA(), _presetB()]);
+      expect(identical(cleared, original), isFalse);
+      expect(identical(clearedAgain, alreadyEmpty), isFalse);
+    });
+
+    test('lookup helpers find exact ids, report missing ids, and reject blanks',
+        () {
+      final manifest = _manifest(pathPatternPresets: [_presetA(), _presetB()]);
+
+      expect(
+        projectPathPatternPresetById(
+          manifest: manifest,
+          presetId: 'pattern-a',
+        ),
+        _presetA(),
+      );
+      expect(
+        projectPathPatternPresetById(
+          manifest: manifest,
+          presetId: 'missing',
+        ),
+        isNull,
+      );
+      expect(
+        containsProjectPathPatternPreset(
+          manifest: manifest,
+          presetId: 'pattern-b',
+        ),
+        isTrue,
+      );
+      expect(
+        containsProjectPathPatternPreset(
+          manifest: manifest,
+          presetId: 'missing',
+        ),
+        isFalse,
+      );
+      expect(
+        () => projectPathPatternPresetById(
+          manifest: manifest,
+          presetId: ' ',
+        ),
+        throwsA(isA<ArgumentError>()),
+      );
+    });
+
+    test('lookup helpers reject duplicate exact ids', () {
+      final manifest = _manifestUnchecked([
+        _presetA(),
+        _presetA(name: 'Duplicate A'),
+      ]);
+
+      expect(
+        () => projectPathPatternPresetById(
+          manifest: manifest,
+          presetId: 'pattern-a',
+        ),
+        throwsA(isA<ValidationException>()),
+      );
+      expect(
+        () => containsProjectPathPatternPreset(
+          manifest: manifest,
+          presetId: 'pattern-a',
+        ),
+        throwsA(isA<ValidationException>()),
+      );
+    });
+
+    test('operations keep pathPatternPresets JSON stable', () {
+      final upserted = upsertProjectPathPatternPreset(
+        manifest: _manifest(),
+        preset: _presetA(),
+      );
+      final cleared = clearProjectPathPatternPresets(upserted);
+
+      expect(upserted.toJson()['pathPatternPresets'], [
+        encodeProjectPathPatternPreset(_presetA()),
+      ]);
+      expect(cleared.toJson()['pathPatternPresets'], <Object?>[]);
+    });
+  });
+}
+
+ProjectManifest _manifest({
+  String name = 'Project',
+  List<ProjectPathPreset> pathPresets = const [],
+  List<ProjectPathPatternPreset> pathPatternPresets = const [],
+}) {
+  return ProjectManifest(
+    name: name,
+    maps: const [],
+    tilesets: const [
+      ProjectTilesetEntry(
+        id: 'outdoor',
+        name: 'Outdoor',
+        relativePath: 'tilesets/outdoor.png',
+      ),
+    ],
+    pathPresets: pathPresets,
+    pathPatternPresets: pathPatternPresets,
+    surfaceCatalog: ProjectSurfaceCatalog(),
+  );
+}
+
+ProjectManifest _manifestUnchecked(List<ProjectPathPatternPreset> presets) {
+  return ProjectManifest.fromJson({
+    'name': 'Unchecked',
+    'maps': <Object?>[],
+    'tilesets': <Object?>[],
+    'pathPatternPresets': [
+      for (final preset in presets) encodeProjectPathPatternPreset(preset),
+    ],
+  });
+}
+
+ProjectPathPreset _legacyPathPreset() {
+  return ProjectPathPreset(
+    id: 'legacy-water',
+    name: 'Legacy Water',
+    surfaceKind: PathSurfaceKind.water,
+    tilesetId: 'outdoor',
+    variants: [
+      PathPresetVariantMapping(
+        variant: TerrainPathVariant.cross,
+        frames: [
+          TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 0)),
+        ],
+      ),
+    ],
+  );
+}
+
+ProjectPathPatternPreset _presetA({String name = 'Pattern A'}) {
+  return _preset('pattern-a', name: name, sortOrder: 1);
+}
+
+ProjectPathPatternPreset _presetB({String name = 'Pattern B'}) {
+  return _preset('pattern-b', name: name, sortOrder: 2);
+}
+
+ProjectPathPatternPreset _presetC({String name = 'Pattern C'}) {
+  return _preset('pattern-c', name: name, sortOrder: 3);
+}
+
+ProjectPathPatternPreset _preset(
+  String id, {
+  String? name,
+  int sortOrder = 0,
+}) {
+  return ProjectPathPatternPreset(
+    id: id,
+    name: name ?? id,
+    basePathPresetId: 'legacy-water',
+    centerPattern: PathCenterPattern(
+      size: PathCenterPatternSize(width: 1, height: 1),
+      cells: [
+        PathCenterPatternCell(
+          localX: 0,
+          localY: 0,
+          frames: [
+            TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 0)),
+          ],
+        ),
+      ],
+    ),
+    sortOrder: sortOrder,
+  );
+}
```

## Auto-review

- Ai-je gardé `ProjectManifest` intact ? Oui.
- Ai-je évité generated/build_runner/Freezed ? Oui.
- Ai-je évité migration legacy ? Oui.
- Ai-je préservé `ProjectPathPreset` ? Oui.
- Ai-je préservé `PathLayer` ? Oui.
- Ai-je validé les doublons ? Oui.
- Ai-je préservé l'ordre ? Oui.
- Ai-je évité UI/canvas/runtime/gameplay/battle ? Oui.
- Ai-je évité TSX/TMX ? Oui.
- Ai-je évité tall grass ? Oui.

## Critique du prompt

- Ambiguïté rencontrée : `remove` sur id manquant peut retourner la même instance ou une nouvelle instance équivalente. J'ai retenu une nouvelle instance via `copyWith`, car le contrat général du lot demande aux opérations d'écriture de retourner un nouveau `ProjectManifest`.
- Décision sur remove missing : no-op équivalent, nouvelle instance.
- Décision sur duplicate ids : `replace` et `upsert` valident toute la liste ; `remove` et lookup rejettent les doublons de l'id demandé.
- Décision sur lookup helpers : ajoutés, car utiles et peu coûteux.
- À valider avant read model editor / shell Path Studio : le read model doit-il exposer aussi les diagnostics de `basePathPresetId` manquant, ou rester purement affichage liste dans un premier temps.
