# PathPattern-10 — ProjectManifest PathPattern Integration V0

## 1. Verdict

Lot accepté.

`ProjectManifest` expose maintenant un champ root-level `pathPatternPresets` qui encode et décode des `ProjectPathPatternPreset` via le codec JSON externe du Lot 8. Les anciens manifests sans champ décodent en liste vide, `pathPatternPresets: null` décode aussi en liste vide, et l'encodage écrit toujours `pathPatternPresets`, même quand la liste est vide.

Aucune migration automatique depuis `pathPresets` n'a été ajoutée.

## 2. Audit initial

Commandes initiales :

```bash
pwd
git status --short --untracked-files=all
git diff --stat
rg -n "class ProjectManifest|ProjectManifest\(|terrainPresets|pathPresets|surfaceCatalog|pathPatternPresets|JsonKey|fromJson|toJson|ProjectPathPatternPreset|encodeProjectPathPatternPreset|decodeProjectPathPatternPreset|ProjectSurfaceCatalog|surfaceCatalog" packages/map_core/lib packages/map_core/test
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

Reponses d'audit :

1. `ProjectManifest` est defini dans `packages/map_core/lib/src/models/project_manifest.dart`.
2. Les champs root-level les plus proches sont `terrainPresets`, `pathPresets` et `surfaceCatalog`.
3. `terrainPresets` et `pathPresets` sont des listes Freezed/JsonSerializable avec `@Default([])` et encodage direct via `toJson()` des items.
4. `surfaceCatalog` est integre avec `@JsonKey(fromJson: _projectSurfaceCatalogFromJson, toJson: _projectSurfaceCatalogToJson)` pour accepter absence/null comme catalogue vide et rejeter les mauvais types via `ValidationException`.
5. La strategie retenue pour `pathPatternPresets` est une liste root-level avec codec de liste externe, proche de `pathPresets` pour la forme et proche de `surfaceCatalog` pour la tolerance absence/null.
6. Il existe un cycle d'import potentiel : `ProjectManifest` importe le codec PathPattern, et le codec importe `project_manifest.dart` pour `TilesetVisualFrame` / `TilesetSourceRect`.
7. Solution minimale retenue : ne pas refactorer `TilesetVisualFrame`; conserver le cycle existant et le verifier par `build_runner`, test cible et analyze. Ces commandes passent.
8. Des fonctions de liste ont ete ajoutees dans `project_path_pattern_preset_json_codec.dart` : `encodeProjectPathPatternPresets` et `decodeProjectPathPatternPresets`.
9. `pathPatternPresets` est encode meme quand la liste est vide, pour stabiliser le champ root-level.
10. Les tests a risque etaient les tests de serialization manifest, les golden PathPattern et le test complet `map_core`.

## 3. Fichiers crees / modifies / supprimes

Crees :

```text
packages/map_core/test/project_manifest_path_pattern_presets_test.dart
```

Modifies manuellement :

```text
packages/map_core/lib/src/models/project_manifest.dart
packages/map_core/lib/src/operations/project_path_pattern_preset_json_codec.dart
```

Modifies par generation :

```text
packages/map_core/lib/src/models/project_manifest.freezed.dart
packages/map_core/lib/src/models/project_manifest.g.dart
```

Supprimes :

```text
aucun
```

## 4. API / modele manifest ajoute

Champ ajoute dans `ProjectManifest` :

```dart
@Default([])
@JsonKey(
  name: 'pathPatternPresets',
  fromJson: decodeProjectPathPatternPresets,
  toJson: encodeProjectPathPatternPresets,
)
List<ProjectPathPatternPreset> pathPatternPresets,
```

Le champ est place juste apres `pathPresets`, ce qui le garde proche du modele legacy qu'il reference sans modifier `ProjectPathPreset`.

## 5. Strategie codec de liste

Fonctions ajoutees :

```dart
List<Map<String, dynamic>> encodeProjectPathPatternPresets(
  List<ProjectPathPatternPreset> presets,
)

List<ProjectPathPatternPreset> decodeProjectPathPatternPresets(Object? json)
```

Contrat :

- `null` -> `[]` ;
- liste vide -> `[]` ;
- liste valide -> decode item par item avec `decodeProjectPathPatternPreset` ;
- non-list -> `ValidationException` ;
- item non-map -> `ValidationException` ;
- ordre preserve a l'encodage et au decodage.

## 6. Decision old manifest absent field

Decision : un manifest ancien sans `pathPatternPresets` decode avec `pathPatternPresets == []`.

Raison : les anciens projets doivent rester compatibles et aucun `ProjectPathPreset` legacy ne doit etre transforme automatiquement.

## 7. Decision null / empty list

Decision :

- `pathPatternPresets: null` decode comme `[]` ;
- `pathPatternPresets: []` decode comme `[]` ;
- `ProjectManifest(... pathPatternPresets: [])` encode avec le champ `pathPatternPresets: []`.

Raison : champ root-level stable, lisible dans les diffs projet, et explicite sur le support PathPattern.

## 8. Decision no legacy migration

Decision : aucune migration automatique `pathPresets -> pathPatternPresets`.

Preuve testee : un manifest avec `pathPresets` legacy non vide mais sans `pathPatternPresets` garde `pathPatternPresets == []`.

## 9. Generated files

Commande lancee :

```bash
cd packages/map_core && dart run build_runner build --delete-conflicting-outputs
```

Sortie complete :

```text
  Generating the build script.
  Reading the asset graph.
  Checking for updates.
  Updating the asset graph.
  Building, incremental build.
  0s freezed on 168 inputs; lib/map_core.dart
W SDK language version 3.10.0 is newer than `analyzer` language version 3.9.0. Run `dart pub upgrade`.
  0s freezed on 168 inputs: 1 no-op; lib/src/collision/pixel_rect.dart
  2s freezed on 168 inputs: 3 skipped, 1 same, 1 no-op; spent 1s analyzing; lib/src/models/enums.dart
  3s freezed on 168 inputs: 10 skipped, 1 output, 8 same, 4 no-op; spent 2s analyzing; lib/src/models/scenario_asset.dart
  3s freezed on 168 inputs: 133 skipped, 1 output, 10 same, 24 no-op; spent 2s analyzing
  0s json_serializable on 336 inputs; lib/map_core.dart
  1s json_serializable on 336 inputs: 1 no-op; lib/map_core.freezed.dart
W json_serializable on lib/src/models/element_collision_profile.dart:
  The version constraint "^4.8.1" on json_annotation allows versions before 4.9.0 which is not allowed.
  2s json_serializable on 336 inputs: 28 skipped, 1 output, 7 same, 3 no-op; spent 2s analyzing; lib/src/models/project_manifest.freezed.dart
  3s json_serializable on 336 inputs: 119 skipped, 1 output, 10 same, 53 no-op; spent 3s analyzing; test/dialogue_library_tree_test.freezed.dart
  4s json_serializable on 336 inputs: 181 skipped, 1 output, 10 same, 115 no-op; spent 4s analyzing; test/surface_studio_read_model_test.freezed.dart
  5s json_serializable on 336 inputs: 196 skipped, 1 output, 10 same, 129 no-op; spent 4s analyzing
  0s source_gen:combining_builder on 336 inputs; lib/map_core.dart
  0s source_gen:combining_builder on 336 inputs: 306 skipped, 1 output, 10 same, 19 no-op
  Running the post build.
  Writing the asset graph.
  Built with build_runner in 9s; wrote 33 outputs.
```

Fichiers generated modifies :

```text
packages/map_core/lib/src/models/project_manifest.freezed.dart
packages/map_core/lib/src/models/project_manifest.g.dart
```

Aucun autre fichier generated suivi n'a ete modifie.

## 10. Tests lances

### Test rouge TDD

Commande :

```bash
cd packages/map_core && dart test test/project_manifest_path_pattern_presets_test.dart --reporter expanded --no-color
```

Sortie complete :

```text
00:00 +0: loading test/project_manifest_path_pattern_presets_test.dart
00:00 +0 -1: loading test/project_manifest_path_pattern_presets_test.dart [E]
  Failed to load "test/project_manifest_path_pattern_presets_test.dart":
  test/project_manifest_path_pattern_presets_test.dart:82:9: Error: No named parameter with the name 'pathPatternPresets'.
          pathPatternPresets: [minimal, complete],
          ^^^^^^^^^^^^^^^^^^
  lib/src/models/project_manifest.dart:59:11: Context: Found this candidate, but the arguments don't match.
    factory ProjectManifest({
            ^
  test/project_manifest_path_pattern_presets_test.dart:12:23: Error: The getter 'pathPatternPresets' isn't defined for the type 'ProjectManifest'.
   - 'ProjectManifest' is from 'package:map_core/src/models/project_manifest.dart' ('lib/src/models/project_manifest.dart').
  Try correcting the name to the name of an existing getter, or defining a getter or field named 'pathPatternPresets'.
        expect(manifest.pathPatternPresets, isEmpty);
                        ^^^^^^^^^^^^^^^^^^
  test/project_manifest_path_pattern_presets_test.dart:21:23: Error: The getter 'pathPatternPresets' isn't defined for the type 'ProjectManifest'.
   - 'ProjectManifest' is from 'package:map_core/src/models/project_manifest.dart' ('lib/src/models/project_manifest.dart').
  Try correcting the name to the name of an existing getter, or defining a getter or field named 'pathPatternPresets'.
        expect(manifest.pathPatternPresets, isEmpty);
                        ^^^^^^^^^^^^^^^^^^
  test/project_manifest_path_pattern_presets_test.dart:30:23: Error: The getter 'pathPatternPresets' isn't defined for the type 'ProjectManifest'.
   - 'ProjectManifest' is from 'package:map_core/src/models/project_manifest.dart' ('lib/src/models/project_manifest.dart').
  Try correcting the name to the name of an existing getter, or defining a getter or field named 'pathPatternPresets'.
        expect(manifest.pathPatternPresets, isEmpty);
                        ^^^^^^^^^^^^^^^^^^
  test/project_manifest_path_pattern_presets_test.dart:45:23: Error: The getter 'pathPatternPresets' isn't defined for the type 'ProjectManifest'.
   - 'ProjectManifest' is from 'package:map_core/src/models/project_manifest.dart' ('lib/src/models/project_manifest.dart').
  Try correcting the name to the name of an existing getter, or defining a getter or field named 'pathPatternPresets'.
        expect(manifest.pathPatternPresets, [expected]);
                        ^^^^^^^^^^^^^^^^^^
  test/project_manifest_path_pattern_presets_test.dart:58:23: Error: The getter 'pathPatternPresets' isn't defined for the type 'ProjectManifest'.
   - 'ProjectManifest' is from 'package:map_core/src/models/project_manifest.dart' ('lib/src/models/project_manifest.dart').
  Try correcting the name to the name of an existing getter, or defining a getter or field named 'pathPatternPresets'.
        expect(manifest.pathPatternPresets, [expected]);
                        ^^^^^^^^^^^^^^^^^^
  test/project_manifest_path_pattern_presets_test.dart:59:23: Error: The getter 'pathPatternPresets' isn't defined for the type 'ProjectManifest'.
   - 'ProjectManifest' is from 'package:map_core/src/models/project_manifest.dart' ('lib/src/models/project_manifest.dart').
  Try correcting the name to the name of an existing getter, or defining a getter or field named 'pathPatternPresets'.
        expect(manifest.pathPatternPresets.single.transparentColor,
                        ^^^^^^^^^^^^^^^^^^
  test/project_manifest_path_pattern_presets_test.dart:62:18: Error: The getter 'pathPatternPresets' isn't defined for the type 'ProjectManifest'.
   - 'ProjectManifest' is from 'package:map_core/src/models/project_manifest.dart' ('lib/src/models/project_manifest.dart').
  Try correcting the name to the name of an existing getter, or defining a getter or field named 'pathPatternPresets'.
          manifest.pathPatternPresets.single.centerPattern.size,
                   ^^^^^^^^^^^^^^^^^^
  test/project_manifest_path_pattern_presets_test.dart:90:22: Error: The getter 'pathPatternPresets' isn't defined for the type 'ProjectManifest'.
   - 'ProjectManifest' is from 'package:map_core/src/models/project_manifest.dart' ('lib/src/models/project_manifest.dart').
  Try correcting the name to the name of an existing getter, or defining a getter or field named 'pathPatternPresets'.
        expect(decoded.pathPatternPresets, [minimal, complete]);
                       ^^^^^^^^^^^^^^^^^^
  test/project_manifest_path_pattern_presets_test.dart:99:23: Error: The getter 'pathPatternPresets' isn't defined for the type 'ProjectManifest'.
   - 'ProjectManifest' is from 'package:map_core/src/models/project_manifest.dart' ('lib/src/models/project_manifest.dart').
  Try correcting the name to the name of an existing getter, or defining a getter or field named 'pathPatternPresets'.
        expect(manifest.pathPatternPresets, isEmpty);
                        ^^^^^^^^^^^^^^^^^^
00:00 +0 -1: Some tests failed.
```

### Test cible manifest Lot 10

Commande :

```bash
cd packages/map_core && dart test test/project_manifest_path_pattern_presets_test.dart --reporter expanded --no-color
```

Sortie complete :

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

### Regression Lot 9

Commande :

```bash
cd packages/map_core && dart test test/project_path_pattern_preset_json_golden_test.dart --reporter expanded --no-color
```

Sortie complete :

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

### Regression Lot 8

Commande :

```bash
cd packages/map_core && dart test test/project_path_pattern_preset_json_codec_test.dart --reporter expanded --no-color
```

Sortie complete :

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

### Regression Lot 7

Commande :

```bash
cd packages/map_core && dart test test/project_path_pattern_preset_test.dart --reporter expanded --no-color
```

Sortie complete :

```text
00:00 +0: loading test/project_path_pattern_preset_test.dart
00:00 +0: ProjectPathPatternPreset creates a minimal preset with defaults
00:00 +1: ProjectPathPatternPreset creates a complete preset with a 2x2 center pattern
00:00 +2: ProjectPathPatternPreset rejects blank identity fields
00:00 +3: ProjectPathPatternPreset validates with trim but stores original strings
00:00 +4: ProjectPathPatternPreset supports value equality and stable hashCode
00:00 +5: All tests passed!
```

### Regressions PathPattern core

Commandes :

```bash
cd packages/map_core && dart test test/tileset_transparent_color_test.dart --reporter expanded --no-color
cd packages/map_core && dart test test/project_path_preset_center_pattern_adapter_test.dart --reporter expanded --no-color
cd packages/map_core && dart test test/path_center_pattern_resolver_test.dart --reporter expanded --no-color
cd packages/map_core && dart test test/path_center_pattern_test.dart --reporter expanded --no-color
cd packages/map_core && dart test test/map_terrain_autotile_characterization_test.dart --reporter expanded --no-color
```

Sorties completes :

#### tileset_transparent_color_test

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

#### project_path_preset_center_pattern_adapter_test

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

#### path_center_pattern_resolver_test

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

#### path_center_pattern_test

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

#### map_terrain_autotile_characterization_test

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

### Regressions preview map_editor

Commandes :

```bash
cd packages/map_editor && flutter test test/path_pattern/path_center_pattern_animated_preview_renderer_test.dart --no-pub --reporter expanded
cd packages/map_editor && flutter test test/path_pattern/path_center_pattern_static_preview_renderer_test.dart --no-pub --reporter expanded
cd packages/map_editor && flutter test test/path_pattern/tileset_transparent_color_processor_test.dart --no-pub --reporter expanded
```

Sorties completes :

#### path_center_pattern_animated_preview_renderer_test

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

#### path_center_pattern_static_preview_renderer_test

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

#### tileset_transparent_color_processor_test

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

Sortie finale capturee via Context Mode :

```text
00:01 +1073: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 8. defensive copy: animations source mutated after build
00:01 +1074: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 9. defensive copy: presets source mutated after build
00:01 +1075: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 10. duplicate atlas id throws ValidationException
00:01 +1076: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 11. duplicate animation id throws ValidationException
00:01 +1077: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 12. duplicate preset id throws ValidationException
00:01 +1078: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 13. same id string across collections is allowed; lookups
00:01 +1079: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 14. atlasById returns instance when present
00:01 +1080: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 15. atlasById null when absent
00:01 +1081: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 16. animationById returns instance when present
00:01 +1082: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 17. animationById null when absent
00:01 +1083: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 18. presetById returns instance when present
00:01 +1084: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 19. presetById null when absent
00:01 +1085: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 20. containsAtlas delegates to lookup
00:01 +1086: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 21. containsAnimation delegates to lookup
00:01 +1087: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 22. containsPreset delegates to lookup
00:01 +1088: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 23. lookups use exact id string (no trim) — atlas
00:01 +1089: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 24. does not resolve missing animationId on preset; no error
00:01 +1090: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 25. value equality: same content same order: == and hashCode
00:01 +1091: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 26. value inequality: different atlas order
00:01 +1092: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 27. value inequality: different animation order
00:01 +1093: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 28. value inequality: different preset order
00:01 +1094: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 29. value inequality: different content
00:01 +1095: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 30. public surface export: ProjectSurfaceCatalog from map_core
00:01 +1096: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 31. ProjectManifest: surfaceCatalog key; no split surface keys (Lot 33 → 49)
00:01 +1097: All tests passed!
```

Ligne finale exacte :

```text
00:01 +1097: All tests passed!
```

## 11. Analyze

Commande :

```bash
cd packages/map_core && dart analyze lib/src/models/project_manifest.dart lib/src/operations/project_path_pattern_preset_json_codec.dart test/project_manifest_path_pattern_presets_test.dart
```

Sortie complete :

```text
Analyzing project_manifest.dart, project_path_pattern_preset_json_codec.dart, project_manifest_path_pattern_presets_test.dart...
No issues found!
```

## 12. Non-objectifs confirmes

Confirme :

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
- pas de migration automatique des anciens `pathPresets` ;
- pas de suppression de `ProjectPathPreset` ;
- pas de modification de `PathLayer` ;
- pas de `ProjectPathPatternCatalog` ;
- pas de nouvelle feature editor.

## 13. Limites restantes

- Aucun helper manifest `read / replace / upsert / remove / clear` n'existe encore pour `pathPatternPresets`.
- Aucun diagnostic ne verifie encore que `basePathPresetId` reference un `ProjectPathPreset` existant.
- Le painter, le canvas, l'UI et le runtime ne consomment pas encore `pathPatternPresets`.
- Le test complet `map_editor` n'a pas ete lance, car ce lot ne modifie pas `map_editor`; les trois tests `test/path_pattern` demandes ont ete lances.
- Le cycle d'import autour de `ProjectManifest` / codec PathPattern reste documente; il est accepte par analyze et tests, mais un futur lot pourrait extraire les types visuels si un refactor cible est decide.

## 14. Git status final

Commande :

```bash
git status --short --untracked-files=all
```

Sortie complete finale :

```text
 M packages/map_core/lib/src/models/project_manifest.dart
 M packages/map_core/lib/src/models/project_manifest.freezed.dart
 M packages/map_core/lib/src/models/project_manifest.g.dart
 M packages/map_core/lib/src/operations/project_path_pattern_preset_json_codec.dart
?? packages/map_core/test/project_manifest_path_pattern_presets_test.dart
?? reports/pathPattern/path_pattern_lot_10_project_manifest_path_pattern_integration.md
```

## 15. Prochain lot recommande

Prochain lot recommande :

```text
PathPattern-11 — PathPattern Manifest Operations V0
```

Objectif : ajouter les operations pures `read / replace / upsert / remove / clear pathPatternPresets`, sans UI, sans runtime, sans painter.

## Evidence Pack

### git diff --stat actuel

Commande :

```bash
git diff --stat
```

Sortie :

```text
 .../map_core/lib/src/models/project_manifest.dart  |  9 ++++
 .../lib/src/models/project_manifest.freezed.dart   | 61 +++++++++++++++++++++-
 .../lib/src/models/project_manifest.g.dart         |  5 ++
 .../project_path_pattern_preset_json_codec.dart    | 38 ++++++++++++--
 4 files changed, 109 insertions(+), 4 deletions(-)
```

### git diff --name-status actuel

Commande :

```bash
git diff --name-status
```

Sortie :

```text
M	packages/map_core/lib/src/models/project_manifest.dart
M	packages/map_core/lib/src/models/project_manifest.freezed.dart
M	packages/map_core/lib/src/models/project_manifest.g.dart
M	packages/map_core/lib/src/operations/project_path_pattern_preset_json_codec.dart
```

### Contenu complet — project_manifest.dart

```dart
// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';
import 'element_collision_profile.dart';
import 'enums.dart';
import 'project_trainer.dart';
import 'project_path_pattern_preset.dart';
import 'scenario_asset.dart';
import 'script_asset.dart';
import 'surface_catalog.dart';
import 'visual_frame_json.dart';

import '../exceptions/map_exceptions.dart';
import '../operations/project_path_pattern_preset_json_codec.dart';
import '../operations/project_surface_catalog_json_codec.dart';

part 'project_manifest.freezed.dart';
part 'project_manifest.g.dart';

/// JSON → [ProjectSurfaceCatalog] pour [ProjectManifest.surfaceCatalog] (Lot 49).
/// Clé absente ou `null` : catalogue vide. Non-map : [ValidationException].
ProjectSurfaceCatalog _projectSurfaceCatalogFromJson(Object? json) {
  if (json == null) {
    return ProjectSurfaceCatalog();
  }
  if (json is! Map) {
    throw const ValidationException('surfaceCatalog must be a JSON object');
  }
  return decodeProjectSurfaceCatalog(
    Map<String, Object?>.from(json),
  );
}

Map<String, Object?> _projectSurfaceCatalogToJson(
  ProjectSurfaceCatalog catalog,
) {
  return encodeProjectSurfaceCatalog(catalog);
}

Object? _readDefaultPlayerCharacterId(Map json, String _) {
  return json['defaultPlayerCharacterId'] ?? json['playerCharacterId'];
}

const Map<String, String> _defaultPokemonCatalogFiles = <String, String>{
  'moves': 'data/pokemon/catalogs/moves.json',
  'abilities': 'data/pokemon/catalogs/abilities.json',
  'items': 'data/pokemon/catalogs/items.json',
  'types': 'data/pokemon/catalogs/types.json',
  'growth_rates': 'data/pokemon/catalogs/growth_rates.json',
  'natures': 'data/pokemon/catalogs/natures.json',
  'egg_groups': 'data/pokemon/catalogs/egg_groups.json',
  'habitats': 'data/pokemon/catalogs/habitats.json',
  'encounter_rules': 'data/pokemon/catalogs/encounter_rules.json',
  'generations': 'data/pokemon/catalogs/generations.json',
  'version_groups': 'data/pokemon/catalogs/version_groups.json',
};

@freezed
class ProjectManifest with _$ProjectManifest {
  @JsonSerializable(explicitToJson: true)
  factory ProjectManifest({
    required String name,
    @Default(ProjectVersion.v1) ProjectVersion version,
    required List<ProjectMapEntry> maps,
    @Default([]) List<ProjectMapGroup> groups,
    @Default([]) List<ProjectTilesetFolder> tilesetFolders,
    required List<ProjectTilesetEntry> tilesets,
    @Default([]) List<ProjectElementCategory> elementCategories,
    @Default([]) List<ProjectElementEntry> elements,
    @Default([]) List<ProjectPresetCategory> terrainCategories,
    @Default([]) List<ProjectPresetCategory> pathCategories,
    @Default([]) List<ProjectTerrainPreset> terrainPresets,
    @Default([]) List<ProjectPathPreset> pathPresets,
    @Default([])
    @JsonKey(
      name: 'pathPatternPresets',
      fromJson: decodeProjectPathPatternPresets,
      toJson: encodeProjectPathPatternPresets,
    )
    List<ProjectPathPatternPreset> pathPatternPresets,
    @Default([]) List<ProjectEncounterTable> encounterTables,
    @Default([]) List<ProjectDialogueFolder> dialogueFolders,
    @Default([]) List<ProjectDialogueEntry> dialogues,
    @Default([]) List<ProjectScriptEntry> scripts,
    @Default([]) List<ScenarioAsset> scenarios,
    @Default([]) List<ProjectTrainerEntry> trainers,
    @Default([]) List<ProjectCharacterEntry> characters,
    @Default(ProjectSettings()) ProjectSettings settings,
    @Default(ProjectPokemonConfig()) ProjectPokemonConfig pokemon,
    @Default({}) Map<String, dynamic> globalProperties,
    @JsonKey(
      name: 'surfaceCatalog',
      fromJson: _projectSurfaceCatalogFromJson,
      toJson: _projectSurfaceCatalogToJson,
    )
    required ProjectSurfaceCatalog surfaceCatalog,
  }) = _ProjectManifest;

  factory ProjectManifest.fromJson(Map<String, dynamic> json) =>
      _$ProjectManifestFromJson(json);
}

@freezed
class ProjectPokemonConfig with _$ProjectPokemonConfig {
  @JsonSerializable(explicitToJson: true)
  const factory ProjectPokemonConfig({
    @Default(true) bool enabled,
    @Default('data/pokemon') String dataRoot,
    @Default('data/pokemon/species') String speciesDir,
    @Default('data/pokemon/learnsets') String learnsetsDir,
    @Default('data/pokemon/evolutions') String evolutionsDir,
    @Default('data/pokemon/media') String mediaDir,
    @Default(_defaultPokemonCatalogFiles) Map<String, String> catalogFiles,
  }) = _ProjectPokemonConfig;

  factory ProjectPokemonConfig.fromJson(Map<String, dynamic> json) =>
      _$ProjectPokemonConfigFromJson(json);
}

@freezed
class ProjectSettings with _$ProjectSettings {
  @JsonSerializable(explicitToJson: true)
  const factory ProjectSettings({
    @Default(16) int tileWidth,
    @Default(16) int tileHeight,
    @Default(2.0) double displayScale,
    @Default(20) int defaultMapWidth,
    @Default(15) int defaultMapHeight,
    @JsonKey(
      name: 'defaultPlayerCharacterId',
      readValue: _readDefaultPlayerCharacterId,
    )
    String? defaultPlayerCharacterId,

    /// Clé API Mistral pour les fonctions IA de l’éditeur (Dialogue Studio, etc.).
    ///
    /// Stockée dans `project.json` : penser au risque de fuite si le dépôt est public ;
    /// l’environnement `MISTRAL_API_KEY` reste un repli sans persistance projet.
    @JsonKey(name: 'mistralApiKey', includeIfNull: false) String? mistralApiKey,
  }) = _ProjectSettings;

  factory ProjectSettings.fromJson(Map<String, dynamic> json) =>
      _$ProjectSettingsFromJson(json);
}

@freezed
class ProjectMapGroup with _$ProjectMapGroup {
  const factory ProjectMapGroup({
    required String id,
    required String name,
    required MapGroupType type,
    String? parentGroupId,
    @Default(0) int sortOrder,
    @Default([]) List<String> tags,
    @Default({}) Map<String, dynamic> properties,
  }) = _ProjectMapGroup;

  factory ProjectMapGroup.fromJson(Map<String, dynamic> json) =>
      _$ProjectMapGroupFromJson(json);
}

@freezed
class ProjectMapEntry with _$ProjectMapEntry {
  const factory ProjectMapEntry({
    required String id,
    required String name,
    required String relativePath,
    String? groupId,
    @Default(MapRole.exterior) MapRole role,
    @Default(0) int sortOrder,
  }) = _ProjectMapEntry;

  factory ProjectMapEntry.fromJson(Map<String, dynamic> json) =>
      _$ProjectMapEntryFromJson(json);
}

@freezed
class ProjectDialogueFolder with _$ProjectDialogueFolder {
  const factory ProjectDialogueFolder({
    required String id,
    required String name,
    String? parentFolderId,
    @Default(0) int sortOrder,
  }) = _ProjectDialogueFolder;

  factory ProjectDialogueFolder.fromJson(Map<String, dynamic> json) =>
      _$ProjectDialogueFolderFromJson(json);
}

@freezed
class ProjectDialogueEntry with _$ProjectDialogueEntry {
  @JsonSerializable(explicitToJson: true)
  const factory ProjectDialogueEntry({
    required String id,
    required String name,

    /// Chemin relatif à la racine projet, ex. `dialogues/mon_id.yarn`.
    required String relativePath,
    @Default([]) List<String> tags,
    @Default('') String description,

    /// Nœud Yarn (ou autre) suggéré par défaut dans l'éditeur ; l'entité peut surcharger via [DialogueRef.startNode].
    String? defaultStartNode,

    /// Dossier dans [ProjectManifest.dialogueFolders] (bibliothèque scripts) ; null = racine.
    String? folderId,
    @Default(0) int sortOrder,
  }) = _ProjectDialogueEntry;

  factory ProjectDialogueEntry.fromJson(Map<String, dynamic> json) =>
      _$ProjectDialogueEntryFromJson(json);
}

@freezed
class ProjectTilesetFolder with _$ProjectTilesetFolder {
  const factory ProjectTilesetFolder({
    required String id,
    required String name,
    String? parentFolderId,
    @Default(0) int sortOrder,
  }) = _ProjectTilesetFolder;

  factory ProjectTilesetFolder.fromJson(Map<String, dynamic> json) =>
      _$ProjectTilesetFolderFromJson(json);
}

@freezed
class ProjectTilesetEntry with _$ProjectTilesetEntry {
  const factory ProjectTilesetEntry({
    required String id,
    required String name,
    required String relativePath,
    @Default(TilesetScope.global) TilesetScope scope,
    String? groupId,

    /// Dossier de la bibliothèque tilesets (hiérarchie dédiée, distincte des groupes de carte).
    String? folderId,
    @Default(0) int sortOrder,
    @Default(false) bool isWorldTileset,
    @Default([]) List<TilesetElementGroup> elementGroups,
    @Default([]) List<TilesetPaletteEntry> paletteEntries,
  }) = _ProjectTilesetEntry;

  factory ProjectTilesetEntry.fromJson(Map<String, dynamic> json) =>
      _$ProjectTilesetEntryFromJson(json);
}

@freezed
class TilesetPaletteEntry with _$TilesetPaletteEntry {
  @JsonSerializable(explicitToJson: true)
  const factory TilesetPaletteEntry({
    required String id,
    @Default('') String name,
    @Default(PaletteCategory.uncategorized) PaletteCategory category,

    /// Au moins une frame ; l'éditeur n'affiche pour l'instant que la première.
    required List<TilesetVisualFrame> frames,
    String? recommendedLayerId,
  }) = _TilesetPaletteEntry;

  factory TilesetPaletteEntry.fromJson(Map<String, dynamic> json) =>
      _$TilesetPaletteEntryFromJson(jsonCoerceLegacySourceToFrames(json));
}

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

/// Une frame d'animation ou l'unique frame d'un visuel statique dans un tileset.
///
/// [tilesetId] vide = utiliser le tileset du contexte parent (élément, preset, entrée palette).
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

@freezed
class TilesetElementGroup with _$TilesetElementGroup {
  const factory TilesetElementGroup({
    required String id,
    required String name,
    String? parentGroupId,
    @Default(0) int sortOrder,
  }) = _TilesetElementGroup;

  factory TilesetElementGroup.fromJson(Map<String, dynamic> json) =>
      _$TilesetElementGroupFromJson(json);
}

@freezed
class ProjectElementCategory with _$ProjectElementCategory {
  const factory ProjectElementCategory({
    required String id,
    required String name,
    String? parentCategoryId,
    @Default(0) int sortOrder,
  }) = _ProjectElementCategory;

  factory ProjectElementCategory.fromJson(Map<String, dynamic> json) =>
      _$ProjectElementCategoryFromJson(json);
}

@freezed
class ProjectElementEntry with _$ProjectElementEntry {
  @JsonSerializable(explicitToJson: true)
  const factory ProjectElementEntry({
    required String id,
    required String name,
    required String tilesetId,
    required String categoryId,
    String? tilesetGroupId,

    /// Au moins une frame ; le canvas map_editor anime les entités qui référencent cet élément via toutes les frames (durées `durationMs` ou fallback) ; autres usages éditeur (pinceau, etc.) = première frame.
    required List<TilesetVisualFrame> frames,
    @Default(ElementPresetKind.generic) ElementPresetKind presetKind,
    ElementCollisionProfile? collisionProfile,
    String? groupId,
    String? recommendedLayerId,
    @Default([]) List<String> tags,
    @Default(0) int sortOrder,
  }) = _ProjectElementEntry;

  factory ProjectElementEntry.fromJson(Map<String, dynamic> json) =>
      _$ProjectElementEntryFromJson(jsonCoerceLegacySourceToFrames(json));
}

@freezed
class ProjectTerrainPreset with _$ProjectTerrainPreset {
  const factory ProjectTerrainPreset({
    required String id,
    required String name,
    required TerrainType terrainType,
    String? categoryId,
    @Default('') String tilesetId,
    @Default([]) List<TerrainPresetVariant> variants,
    @Default(0) int sortOrder,
  }) = _ProjectTerrainPreset;

  factory ProjectTerrainPreset.fromJson(Map<String, dynamic> json) =>
      _$ProjectTerrainPresetFromJson(json);
}

@freezed
class TerrainPresetVariant with _$TerrainPresetVariant {
  @JsonSerializable(explicitToJson: true)
  const factory TerrainPresetVariant({
    /// Au moins une frame ; rendu éditeur = première frame.
    required List<TilesetVisualFrame> frames,
    @Default(1) int weight,
  }) = _TerrainPresetVariant;

  factory TerrainPresetVariant.fromJson(Map<String, dynamic> json) =>
      _$TerrainPresetVariantFromJson(jsonCoerceLegacySourceToFrames(json));
}

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

@freezed
class PathAnimationTriggerRule with _$PathAnimationTriggerRule {
  @JsonSerializable(explicitToJson: true)
  const factory PathAnimationTriggerRule({
    @Default('') String id,
    @Default(true) bool enabled,
    @Default(PathAnimationTriggerType.onStep) PathAnimationTriggerType trigger,
    @Default(PathAnimationPlaybackMode.restartOnTrigger)
    PathAnimationPlaybackMode mode,
    @Default(PathAnimationActivationScope.wholeLayer)
    PathAnimationActivationScope scope,
  }) = _PathAnimationTriggerRule;

  factory PathAnimationTriggerRule.fromJson(Map<String, dynamic> json) =>
      _$PathAnimationTriggerRuleFromJson(json);
}

@freezed
class ProjectPresetCategory with _$ProjectPresetCategory {
  const factory ProjectPresetCategory({
    required String id,
    required String name,
    String? parentCategoryId,
    @Default(0) int sortOrder,
  }) = _ProjectPresetCategory;

  factory ProjectPresetCategory.fromJson(Map<String, dynamic> json) =>
      _$ProjectPresetCategoryFromJson(json);
}

// ---------------------------------------------------------------------------
// ProjectEncounterEntry / ProjectEncounterTable
// ---------------------------------------------------------------------------

/// Entrée pondérée dans une table de rencontres.
@freezed
class ProjectEncounterEntry with _$ProjectEncounterEntry {
  const factory ProjectEncounterEntry({
    /// Identifiant de l'espèce (string libre — sans Pokédex intégré pour l'instant).
    required String speciesId,
    required int minLevel,
    required int maxLevel,

    /// Poids relatif d'apparition (entier positif ; plus élevé = plus fréquent).
    @Default(1) int weight,
  }) = _ProjectEncounterEntry;

  factory ProjectEncounterEntry.fromJson(Map<String, dynamic> json) =>
      _$ProjectEncounterEntryFromJson(json);
}

/// Table de rencontres réutilisable au niveau projet.
///
/// Une [MapGameplayZone] peut y faire référence via [MapGameplayZone.encounterTableId].
/// Le runtime choisit une entrée au tirage pondéré et déclenche le système de combat.
@freezed
class ProjectEncounterTable with _$ProjectEncounterTable {
  @JsonSerializable(explicitToJson: true)
  const factory ProjectEncounterTable({
    required String id,
    required String name,
    required EncounterKind encounterKind,
    @Default([]) List<ProjectEncounterEntry> entries,
    @Default([]) List<String> tags,
  }) = _ProjectEncounterTable;

  factory ProjectEncounterTable.fromJson(Map<String, dynamic> json) =>
      _$ProjectEncounterTableFromJson(json);
}

extension TilesetVisualFrameListX on List<TilesetVisualFrame> {
  TilesetVisualFrame get primaryFrame {
    if (isEmpty) {
      throw StateError('At least one TilesetVisualFrame is required');
    }
    return first;
  }

  TilesetSourceRect get primarySource => primaryFrame.source;
}

@freezed
class ProjectScriptEntry with _$ProjectScriptEntry {
  @JsonSerializable(explicitToJson: true)
  const factory ProjectScriptEntry({
    required String id,
    required String name,
    required ScriptAsset asset,
    @Default([]) List<String> tags,
  }) = _ProjectScriptEntry;

  factory ProjectScriptEntry.fromJson(Map<String, dynamic> json) =>
      _$ProjectScriptEntryFromJson(json);
}

@freezed
class ProjectCharacterEntry with _$ProjectCharacterEntry {
  @JsonSerializable(explicitToJson: true)
  const factory ProjectCharacterEntry({
    required String id,
    required String name,
    required String tilesetId,
    @Default(1) int frameWidth,
    @Default(2) int frameHeight,
    @Default([]) List<CharacterAnimation> animations,
    @Default([]) List<String> tags,
    @Default(0) int sortOrder,
  }) = _ProjectCharacterEntry;

  factory ProjectCharacterEntry.fromJson(Map<String, dynamic> json) =>
      _$ProjectCharacterEntryFromJson(json);
}

@freezed
class CharacterAnimation with _$CharacterAnimation {
  @JsonSerializable(explicitToJson: true)
  const factory CharacterAnimation({
    required CharacterAnimationState state,
    required EntityFacing direction,
    @Default([]) List<CharacterAnimationFrame> frames,
  }) = _CharacterAnimation;

  factory CharacterAnimation.fromJson(Map<String, dynamic> json) =>
      _$CharacterAnimationFromJson(json);
}

@freezed
class CharacterAnimationFrame with _$CharacterAnimationFrame {
  @JsonSerializable(explicitToJson: true)
  const factory CharacterAnimationFrame({
    required TilesetSourceRect source,
    @Default(150) int durationMs,
  }) = _CharacterAnimationFrame;

  factory CharacterAnimationFrame.fromJson(Map<String, dynamic> json) =>
      _$CharacterAnimationFrameFromJson(json);
}

```

### Contenu complet — project_path_pattern_preset_json_codec.dart

```dart
// JSON codec manuel — [ProjectPathPatternPreset].
//
// Persistance PathPattern externe au modèle : aucune méthode toJson/fromJson
// sur [ProjectPathPatternPreset]. Le codec réutilise le format généré existant
// de TilesetVisualFrame pour éviter un second schéma de frame.

import '../exceptions/map_exceptions.dart';
import '../models/path_center_pattern.dart';
import '../models/project_manifest.dart';
import '../models/project_path_pattern_preset.dart';
import '../models/tileset_transparent_color.dart';

Map<String, dynamic> _stringKeyMapFrom(Object mapLike) {
  final map = mapLike as Map<dynamic, dynamic>;
  return Map<String, dynamic>.from(
    map.map(
      (dynamic key, dynamic value) => MapEntry(
        key is String ? key : key.toString(),
        value,
      ),
    ),
  );
}

Object? _valueForRequiredKey(
  Map<String, dynamic> json,
  String key,
  String errorPrefix,
) {
  if (!json.containsKey(key)) {
    throw ValidationException('$errorPrefix is required');
  }
  return json[key];
}

String _requiredString(
  Map<String, dynamic> json,
  String key,
  String fieldKey,
) {
  final value = _valueForRequiredKey(json, key, fieldKey);
  if (value is! String) {
    throw ValidationException('$fieldKey must be a non-null String');
  }
  return value;
}

int _requiredInt(
  Map<String, dynamic> json,
  String key,
  String fieldKey,
) {
  final value = _valueForRequiredKey(json, key, fieldKey);
  if (value is! int) {
    throw ValidationException('$fieldKey must be an int');
  }
  return value;
}

Map<String, dynamic> _requiredMap(
  Map<String, dynamic> json,
  String key,
  String fieldKey,
) {
  final value = _valueForRequiredKey(json, key, fieldKey);
  if (value is! Map) {
    throw ValidationException('$fieldKey must be an Object');
  }
  return _stringKeyMapFrom(value);
}

List<dynamic> _requiredList(
  Map<String, dynamic> json,
  String key,
  String fieldKey,
) {
  final value = _valueForRequiredKey(json, key, fieldKey);
  if (value is! List) {
    throw ValidationException('$fieldKey must be a List');
  }
  return value;
}

String? _optionalString(
  Map<String, dynamic> json,
  String key,
  String fieldKey,
) {
  if (!json.containsKey(key)) {
    return null;
  }
  final value = json[key];
  if (value == null) {
    return null;
  }
  if (value is! String) {
    throw ValidationException('$fieldKey must be a String or null');
  }
  return value;
}

/// Encodes a [ProjectPathPatternPreset] using the external PathPattern V0 JSON.
Map<String, dynamic> encodeProjectPathPatternPreset(
  ProjectPathPatternPreset preset,
) {
  final out = <String, dynamic>{
    'id': preset.id,
    'name': preset.name,
    'basePathPresetId': preset.basePathPresetId,
    'centerPattern': _encodePathCenterPattern(preset.centerPattern),
    'sortOrder': preset.sortOrder,
  };
  if (preset.transparentColor != null) {
    out['transparentColor'] = preset.transparentColor!.toHexRgb();
  }
  if (preset.categoryId != null) {
    out['categoryId'] = preset.categoryId;
  }
  return out;
}

/// Decodes a [ProjectPathPatternPreset] from the external PathPattern V0 JSON.
ProjectPathPatternPreset decodeProjectPathPatternPreset(
  Map<String, dynamic> json,
) {
  final transparentColorHex = _optionalString(
    json,
    'transparentColor',
    'ProjectPathPatternPreset.transparentColor',
  );

  return ProjectPathPatternPreset(
    id: _requiredString(json, 'id', 'ProjectPathPatternPreset.id'),
    name: _requiredString(json, 'name', 'ProjectPathPatternPreset.name'),
    basePathPresetId: _requiredString(
      json,
      'basePathPresetId',
      'ProjectPathPatternPreset.basePathPresetId',
    ),
    centerPattern: _decodePathCenterPattern(
      _requiredMap(
        json,
        'centerPattern',
        'ProjectPathPatternPreset.centerPattern',
      ),
    ),
    transparentColor: transparentColorHex == null
        ? null
        : _decodeTransparentColor(transparentColorHex),
    categoryId: _optionalString(
      json,
      'categoryId',
      'ProjectPathPatternPreset.categoryId',
    ),
    sortOrder: _requiredInt(
      json,
      'sortOrder',
      'ProjectPathPatternPreset.sortOrder',
    ),
  );
}

/// Encodes a manifest-level list of PathPattern presets.
List<Map<String, dynamic>> encodeProjectPathPatternPresets(
  List<ProjectPathPatternPreset> presets,
) {
  return [
    for (final preset in presets) encodeProjectPathPatternPreset(preset),
  ];
}

/// Decodes a manifest-level list of PathPattern presets.
///
/// Missing or `null` manifest fields are interpreted as an empty list so old
/// project manifests stay compatible.
List<ProjectPathPatternPreset> decodeProjectPathPatternPresets(Object? json) {
  if (json == null) {
    return const [];
  }
  if (json is! List) {
    throw const ValidationException('pathPatternPresets must be a List');
  }

  final presets = <ProjectPathPatternPreset>[];
  for (var index = 0; index < json.length; index += 1) {
    final item = json[index];
    if (item is! Map) {
      throw ValidationException('pathPatternPresets[$index] must be an Object');
    }
    presets.add(decodeProjectPathPatternPreset(_stringKeyMapFrom(item)));
  }
  return presets;
}

Map<String, dynamic> _encodePathCenterPattern(PathCenterPattern pattern) {
  return <String, dynamic>{
    'size': _encodePathCenterPatternSize(pattern.size),
    'cells': <Object?>[
      for (final cell in pattern.cells) _encodePathCenterPatternCell(cell),
    ],
  };
}

PathCenterPattern _decodePathCenterPattern(Map<String, dynamic> json) {
  final cellsRaw = _requiredList(
    json,
    'cells',
    'PathCenterPattern.cells',
  );

  final cells = <PathCenterPatternCell>[];
  for (var index = 0; index < cellsRaw.length; index += 1) {
    final item = cellsRaw[index];
    if (item is! Map) {
      throw ValidationException(
          'PathCenterPattern.cells[$index] must be an Object');
    }
    cells.add(
      _decodePathCenterPatternCell(_stringKeyMapFrom(item), index),
    );
  }

  return PathCenterPattern(
    size: _decodePathCenterPatternSize(
      _requiredMap(json, 'size', 'PathCenterPattern.size'),
    ),
    cells: cells,
  );
}

Map<String, dynamic> _encodePathCenterPatternSize(
  PathCenterPatternSize size,
) {
  return <String, dynamic>{
    'width': size.width,
    'height': size.height,
  };
}

PathCenterPatternSize _decodePathCenterPatternSize(
  Map<String, dynamic> json,
) {
  return PathCenterPatternSize(
    width: _requiredInt(json, 'width', 'PathCenterPattern.size.width'),
    height: _requiredInt(json, 'height', 'PathCenterPattern.size.height'),
  );
}

Map<String, dynamic> _encodePathCenterPatternCell(
  PathCenterPatternCell cell,
) {
  return <String, dynamic>{
    'localX': cell.localX,
    'localY': cell.localY,
    'frames': <Object?>[
      for (final frame in cell.frames) _encodeTilesetVisualFrame(frame),
    ],
  };
}

PathCenterPatternCell _decodePathCenterPatternCell(
  Map<String, dynamic> json,
  int cellIndex,
) {
  final framesRaw = _requiredList(
    json,
    'frames',
    'PathCenterPattern.cells[$cellIndex].frames',
  );
  final frames = <TilesetVisualFrame>[];
  for (var index = 0; index < framesRaw.length; index += 1) {
    final item = framesRaw[index];
    if (item is! Map) {
      throw ValidationException(
        'PathCenterPattern.cells[$cellIndex].frames[$index] must be an Object',
      );
    }
    frames.add(
      _decodeTilesetVisualFrame(_stringKeyMapFrom(item), cellIndex, index),
    );
  }

  return PathCenterPatternCell(
    localX: _requiredInt(
      json,
      'localX',
      'PathCenterPattern.cells[$cellIndex].localX',
    ),
    localY: _requiredInt(
      json,
      'localY',
      'PathCenterPattern.cells[$cellIndex].localY',
    ),
    frames: frames,
  );
}

Map<String, dynamic> _encodeTilesetVisualFrame(TilesetVisualFrame frame) {
  return frame.toJson();
}

TilesetVisualFrame _decodeTilesetVisualFrame(
  Map<String, dynamic> json,
  int cellIndex,
  int frameIndex,
) {
  final source = _valueForRequiredKey(
    json,
    'source',
    'PathCenterPattern.cells[$cellIndex].frames[$frameIndex].source',
  );
  if (source is! Map) {
    throw ValidationException(
      'PathCenterPattern.cells[$cellIndex].frames[$frameIndex].source '
      'must be an Object',
    );
  }

  final normalized = Map<String, dynamic>.from(json);
  normalized['source'] = _stringKeyMapFrom(source);

  try {
    return TilesetVisualFrame.fromJson(normalized);
  } on Object catch (error) {
    throw ValidationException(
      'PathCenterPattern.cells[$cellIndex].frames[$frameIndex] '
      'must be a TilesetVisualFrame JSON object: $error',
    );
  }
}

TilesetTransparentColor _decodeTransparentColor(String value) {
  try {
    return TilesetTransparentColor.fromHexRgb(value);
  } on ArgumentError catch (error) {
    throw ValidationException(
      'ProjectPathPatternPreset.transparentColor must be an RGB hex string: '
      '$error',
    );
  }
}

```

### Contenu complet — project_manifest_path_pattern_presets_test.dart

```dart
import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectManifest pathPatternPresets', () {
    test('decodes old manifests without pathPatternPresets as empty', () {
      final manifest = ProjectManifest.fromJson(_baseManifestJson());

      expect(manifest.pathPatternPresets, isEmpty);
      expect(manifest.toJson(), containsPair('pathPatternPresets', []));
    });

    test('decodes pathPatternPresets null as empty', () {
      final manifest = ProjectManifest.fromJson(
        _baseManifestJson(pathPatternPresets: null),
      );

      expect(manifest.pathPatternPresets, isEmpty);
    });

    test('decodes and encodes empty pathPatternPresets stably', () {
      final manifest = ProjectManifest.fromJson(
        _baseManifestJson(pathPatternPresets: <Object?>[]),
      );
      final json = manifest.toJson();

      expect(manifest.pathPatternPresets, isEmpty);
      expect(json.containsKey('pathPatternPresets'), isTrue);
      expect(json['pathPatternPresets'], <Object?>[]);
    });

    test('decodes the Lot 9 minimal golden through ProjectManifest', () {
      final fixture = _readPathPatternFixture(
        'project_path_pattern_preset_minimal_1x1.json',
      );
      final expected = decodeProjectPathPatternPreset(fixture);

      final manifest = ProjectManifest.fromJson(
        _baseManifestJson(pathPatternPresets: [fixture]),
      );

      expect(manifest.pathPatternPresets, [expected]);
    });

    test('decodes the Lot 9 complete golden through ProjectManifest', () {
      final fixture = _readPathPatternFixture(
        'project_path_pattern_preset_complete_2x2.json',
      );
      final expected = decodeProjectPathPatternPreset(fixture);

      final manifest = ProjectManifest.fromJson(
        _baseManifestJson(pathPatternPresets: [fixture]),
      );

      expect(manifest.pathPatternPresets, [expected]);
      expect(manifest.pathPatternPresets.single.transparentColor,
          TilesetTransparentColor.fromHexRgb('f05ba1'));
      expect(
        manifest.pathPatternPresets.single.centerPattern.size,
        PathCenterPatternSize(width: 2, height: 2),
      );
    });

    test('roundtrips manifest pathPatternPresets without changing order', () {
      final minimal = decodeProjectPathPatternPreset(
        _readPathPatternFixture(
          'project_path_pattern_preset_minimal_1x1.json',
        ),
      );
      final complete = decodeProjectPathPatternPreset(
        _readPathPatternFixture(
          'project_path_pattern_preset_complete_2x2.json',
        ),
      );
      final manifest = ProjectManifest(
        name: 'PathPattern manifest',
        maps: const [],
        tilesets: const [],
        pathPatternPresets: [minimal, complete],
        surfaceCatalog: ProjectSurfaceCatalog(),
      );

      final decoded = ProjectManifest.fromJson(
        jsonDecode(jsonEncode(manifest.toJson())) as Map<String, dynamic>,
      );

      expect(decoded.pathPatternPresets, [minimal, complete]);
    });

    test('does not migrate legacy pathPresets into pathPatternPresets', () {
      final manifest = ProjectManifest.fromJson(
        _baseManifestJson(pathPresets: [_legacyPathPresetJson()]),
      );

      expect(manifest.pathPresets, hasLength(1));
      expect(manifest.pathPatternPresets, isEmpty);
    });

    test('rejects invalid pathPatternPresets payloads', () {
      for (final payload in <Object?>[
        'not-list',
        [123],
        [
          <String, Object?>{
            'id': 'broken',
            'name': 'Broken',
            'basePathPresetId': 'legacy-water',
            'sortOrder': 0,
          },
        ],
      ]) {
        expect(
          () => ProjectManifest.fromJson(
            _baseManifestJson(pathPatternPresets: payload),
          ),
          throwsA(isA<ValidationException>()),
          reason: payload.toString(),
        );
      }
    });
  });
}

const _absent = Object();

Map<String, dynamic> _baseManifestJson({
  Object? pathPatternPresets = _absent,
  List<Object?> pathPresets = const [],
}) {
  final json = <String, dynamic>{
    'name': 'PathPattern manifest',
    'maps': <Object?>[],
    'tilesets': <Object?>[],
    'pathPresets': pathPresets,
  };
  if (!identical(pathPatternPresets, _absent)) {
    json['pathPatternPresets'] = pathPatternPresets;
  }
  return json;
}

Map<String, dynamic> _readPathPatternFixture(String name) {
  return jsonDecode(
    File('test/fixtures/path_pattern/$name').readAsStringSync(),
  ) as Map<String, dynamic>;
}

Map<String, dynamic> _legacyPathPresetJson() {
  return <String, dynamic>{
    'id': 'legacy-water',
    'name': 'Legacy Water',
    'surfaceKind': 'water',
    'tilesetId': 'outdoor',
    'variants': [
      <String, dynamic>{
        'variant': 'cross',
        'frames': [
          <String, dynamic>{
            'tilesetId': '',
            'source': <String, dynamic>{
              'x': 0,
              'y': 0,
              'width': 1,
              'height': 1,
            },
            'durationMs': null,
          },
        ],
      },
    ],
    'sortOrder': 0,
  };
}

```

### Diff complet reel — sources modifiees manuellement

```diff
diff --git a/packages/map_core/lib/src/models/project_manifest.dart b/packages/map_core/lib/src/models/project_manifest.dart
index 9782f75c..660487d8 100644
--- a/packages/map_core/lib/src/models/project_manifest.dart
+++ b/packages/map_core/lib/src/models/project_manifest.dart
@@ -4,12 +4,14 @@ import 'package:freezed_annotation/freezed_annotation.dart';
 import 'element_collision_profile.dart';
 import 'enums.dart';
 import 'project_trainer.dart';
+import 'project_path_pattern_preset.dart';
 import 'scenario_asset.dart';
 import 'script_asset.dart';
 import 'surface_catalog.dart';
 import 'visual_frame_json.dart';
 
 import '../exceptions/map_exceptions.dart';
+import '../operations/project_path_pattern_preset_json_codec.dart';
 import '../operations/project_surface_catalog_json_codec.dart';
 
 part 'project_manifest.freezed.dart';
@@ -69,6 +71,13 @@ class ProjectManifest with _$ProjectManifest {
     @Default([]) List<ProjectPresetCategory> pathCategories,
     @Default([]) List<ProjectTerrainPreset> terrainPresets,
     @Default([]) List<ProjectPathPreset> pathPresets,
+    @Default([])
+    @JsonKey(
+      name: 'pathPatternPresets',
+      fromJson: decodeProjectPathPatternPresets,
+      toJson: encodeProjectPathPatternPresets,
+    )
+    List<ProjectPathPatternPreset> pathPatternPresets,
     @Default([]) List<ProjectEncounterTable> encounterTables,
     @Default([]) List<ProjectDialogueFolder> dialogueFolders,
     @Default([]) List<ProjectDialogueEntry> dialogues,
diff --git a/packages/map_core/lib/src/operations/project_path_pattern_preset_json_codec.dart b/packages/map_core/lib/src/operations/project_path_pattern_preset_json_codec.dart
index a3ca29e8..a3ff9c98 100644
--- a/packages/map_core/lib/src/operations/project_path_pattern_preset_json_codec.dart
+++ b/packages/map_core/lib/src/operations/project_path_pattern_preset_json_codec.dart
@@ -1,8 +1,8 @@
 // JSON codec manuel — [ProjectPathPatternPreset].
 //
-// Prépare une future persistance PathPattern sans branchement manifeste et
-// sans ajouter toJson/fromJson au modèle. Le codec réutilise le format généré
-// existant de TilesetVisualFrame pour éviter un second schéma de frame.
+// Persistance PathPattern externe au modèle : aucune méthode toJson/fromJson
+// sur [ProjectPathPatternPreset]. Le codec réutilise le format généré existant
+// de TilesetVisualFrame pour éviter un second schéma de frame.
 
 import '../exceptions/map_exceptions.dart';
 import '../models/path_center_pattern.dart';
@@ -160,6 +160,38 @@ ProjectPathPatternPreset decodeProjectPathPatternPreset(
   );
 }
 
+/// Encodes a manifest-level list of PathPattern presets.
+List<Map<String, dynamic>> encodeProjectPathPatternPresets(
+  List<ProjectPathPatternPreset> presets,
+) {
+  return [
+    for (final preset in presets) encodeProjectPathPatternPreset(preset),
+  ];
+}
+
+/// Decodes a manifest-level list of PathPattern presets.
+///
+/// Missing or `null` manifest fields are interpreted as an empty list so old
+/// project manifests stay compatible.
+List<ProjectPathPatternPreset> decodeProjectPathPatternPresets(Object? json) {
+  if (json == null) {
+    return const [];
+  }
+  if (json is! List) {
+    throw const ValidationException('pathPatternPresets must be a List');
+  }
+
+  final presets = <ProjectPathPatternPreset>[];
+  for (var index = 0; index < json.length; index += 1) {
+    final item = json[index];
+    if (item is! Map) {
+      throw ValidationException('pathPatternPresets[$index] must be an Object');
+    }
+    presets.add(decodeProjectPathPatternPreset(_stringKeyMapFrom(item)));
+  }
+  return presets;
+}
+
 Map<String, dynamic> _encodePathCenterPattern(PathCenterPattern pattern) {
   return <String, dynamic>{
     'size': _encodePathCenterPatternSize(pattern.size),
```

### Diff complet reel — test cree

```diff
diff --git a/packages/map_core/test/project_manifest_path_pattern_presets_test.dart b/packages/map_core/test/project_manifest_path_pattern_presets_test.dart
new file mode 100644
index 00000000..3915c5cf
--- /dev/null
+++ b/packages/map_core/test/project_manifest_path_pattern_presets_test.dart
@@ -0,0 +1,176 @@
+import 'dart:convert';
+import 'dart:io';
+
+import 'package:map_core/map_core.dart';
+import 'package:test/test.dart';
+
+void main() {
+  group('ProjectManifest pathPatternPresets', () {
+    test('decodes old manifests without pathPatternPresets as empty', () {
+      final manifest = ProjectManifest.fromJson(_baseManifestJson());
+
+      expect(manifest.pathPatternPresets, isEmpty);
+      expect(manifest.toJson(), containsPair('pathPatternPresets', []));
+    });
+
+    test('decodes pathPatternPresets null as empty', () {
+      final manifest = ProjectManifest.fromJson(
+        _baseManifestJson(pathPatternPresets: null),
+      );
+
+      expect(manifest.pathPatternPresets, isEmpty);
+    });
+
+    test('decodes and encodes empty pathPatternPresets stably', () {
+      final manifest = ProjectManifest.fromJson(
+        _baseManifestJson(pathPatternPresets: <Object?>[]),
+      );
+      final json = manifest.toJson();
+
+      expect(manifest.pathPatternPresets, isEmpty);
+      expect(json.containsKey('pathPatternPresets'), isTrue);
+      expect(json['pathPatternPresets'], <Object?>[]);
+    });
+
+    test('decodes the Lot 9 minimal golden through ProjectManifest', () {
+      final fixture = _readPathPatternFixture(
+        'project_path_pattern_preset_minimal_1x1.json',
+      );
+      final expected = decodeProjectPathPatternPreset(fixture);
+
+      final manifest = ProjectManifest.fromJson(
+        _baseManifestJson(pathPatternPresets: [fixture]),
+      );
+
+      expect(manifest.pathPatternPresets, [expected]);
+    });
+
+    test('decodes the Lot 9 complete golden through ProjectManifest', () {
+      final fixture = _readPathPatternFixture(
+        'project_path_pattern_preset_complete_2x2.json',
+      );
+      final expected = decodeProjectPathPatternPreset(fixture);
+
+      final manifest = ProjectManifest.fromJson(
+        _baseManifestJson(pathPatternPresets: [fixture]),
+      );
+
+      expect(manifest.pathPatternPresets, [expected]);
+      expect(manifest.pathPatternPresets.single.transparentColor,
+          TilesetTransparentColor.fromHexRgb('f05ba1'));
+      expect(
+        manifest.pathPatternPresets.single.centerPattern.size,
+        PathCenterPatternSize(width: 2, height: 2),
+      );
+    });
+
+    test('roundtrips manifest pathPatternPresets without changing order', () {
+      final minimal = decodeProjectPathPatternPreset(
+        _readPathPatternFixture(
+          'project_path_pattern_preset_minimal_1x1.json',
+        ),
+      );
+      final complete = decodeProjectPathPatternPreset(
+        _readPathPatternFixture(
+          'project_path_pattern_preset_complete_2x2.json',
+        ),
+      );
+      final manifest = ProjectManifest(
+        name: 'PathPattern manifest',
+        maps: const [],
+        tilesets: const [],
+        pathPatternPresets: [minimal, complete],
+        surfaceCatalog: ProjectSurfaceCatalog(),
+      );
+
+      final decoded = ProjectManifest.fromJson(
+        jsonDecode(jsonEncode(manifest.toJson())) as Map<String, dynamic>,
+      );
+
+      expect(decoded.pathPatternPresets, [minimal, complete]);
+    });
+
+    test('does not migrate legacy pathPresets into pathPatternPresets', () {
+      final manifest = ProjectManifest.fromJson(
+        _baseManifestJson(pathPresets: [_legacyPathPresetJson()]),
+      );
+
+      expect(manifest.pathPresets, hasLength(1));
+      expect(manifest.pathPatternPresets, isEmpty);
+    });
+
+    test('rejects invalid pathPatternPresets payloads', () {
+      for (final payload in <Object?>[
+        'not-list',
+        [123],
+        [
+          <String, Object?>{
+            'id': 'broken',
+            'name': 'Broken',
+            'basePathPresetId': 'legacy-water',
+            'sortOrder': 0,
+          },
+        ],
+      ]) {
+        expect(
+          () => ProjectManifest.fromJson(
+            _baseManifestJson(pathPatternPresets: payload),
+          ),
+          throwsA(isA<ValidationException>()),
+          reason: payload.toString(),
+        );
+      }
+    });
+  });
+}
+
+const _absent = Object();
+
+Map<String, dynamic> _baseManifestJson({
+  Object? pathPatternPresets = _absent,
+  List<Object?> pathPresets = const [],
+}) {
+  final json = <String, dynamic>{
+    'name': 'PathPattern manifest',
+    'maps': <Object?>[],
+    'tilesets': <Object?>[],
+    'pathPresets': pathPresets,
+  };
+  if (!identical(pathPatternPresets, _absent)) {
+    json['pathPatternPresets'] = pathPatternPresets;
+  }
+  return json;
+}
+
+Map<String, dynamic> _readPathPatternFixture(String name) {
+  return jsonDecode(
+    File('test/fixtures/path_pattern/$name').readAsStringSync(),
+  ) as Map<String, dynamic>;
+}
+
+Map<String, dynamic> _legacyPathPresetJson() {
+  return <String, dynamic>{
+    'id': 'legacy-water',
+    'name': 'Legacy Water',
+    'surfaceKind': 'water',
+    'tilesetId': 'outdoor',
+    'variants': [
+      <String, dynamic>{
+        'variant': 'cross',
+        'frames': [
+          <String, dynamic>{
+            'tilesetId': '',
+            'source': <String, dynamic>{
+              'x': 0,
+              'y': 0,
+              'width': 1,
+              'height': 1,
+            },
+            'durationMs': null,
+          },
+        ],
+      },
+    ],
+    'sortOrder': 0,
+  };
+}
```

### Diff complet reel — generated files

```diff
diff --git a/packages/map_core/lib/src/models/project_manifest.freezed.dart b/packages/map_core/lib/src/models/project_manifest.freezed.dart
index 85e72bae..d70ca0ed 100644
--- a/packages/map_core/lib/src/models/project_manifest.freezed.dart
+++ b/packages/map_core/lib/src/models/project_manifest.freezed.dart
@@ -37,6 +37,12 @@ mixin _$ProjectManifest {
   List<ProjectTerrainPreset> get terrainPresets =>
       throw _privateConstructorUsedError;
   List<ProjectPathPreset> get pathPresets => throw _privateConstructorUsedError;
+  @JsonKey(
+      name: 'pathPatternPresets',
+      fromJson: decodeProjectPathPatternPresets,
+      toJson: encodeProjectPathPatternPresets)
+  List<ProjectPathPatternPreset> get pathPatternPresets =>
+      throw _privateConstructorUsedError;
   List<ProjectEncounterTable> get encounterTables =>
       throw _privateConstructorUsedError;
   List<ProjectDialogueFolder> get dialogueFolders =>
@@ -88,6 +94,11 @@ abstract class $ProjectManifestCopyWith<$Res> {
       List<ProjectPresetCategory> pathCategories,
       List<ProjectTerrainPreset> terrainPresets,
       List<ProjectPathPreset> pathPresets,
+      @JsonKey(
+          name: 'pathPatternPresets',
+          fromJson: decodeProjectPathPatternPresets,
+          toJson: encodeProjectPathPatternPresets)
+      List<ProjectPathPatternPreset> pathPatternPresets,
       List<ProjectEncounterTable> encounterTables,
       List<ProjectDialogueFolder> dialogueFolders,
       List<ProjectDialogueEntry> dialogues,
@@ -135,6 +146,7 @@ class _$ProjectManifestCopyWithImpl<$Res, $Val extends ProjectManifest>
     Object? pathCategories = null,
     Object? terrainPresets = null,
     Object? pathPresets = null,
+    Object? pathPatternPresets = null,
     Object? encounterTables = null,
     Object? dialogueFolders = null,
     Object? dialogues = null,
@@ -196,6 +208,10 @@ class _$ProjectManifestCopyWithImpl<$Res, $Val extends ProjectManifest>
           ? _value.pathPresets
           : pathPresets // ignore: cast_nullable_to_non_nullable
               as List<ProjectPathPreset>,
+      pathPatternPresets: null == pathPatternPresets
+          ? _value.pathPatternPresets
+          : pathPatternPresets // ignore: cast_nullable_to_non_nullable
+              as List<ProjectPathPatternPreset>,
       encounterTables: null == encounterTables
           ? _value.encounterTables
           : encounterTables // ignore: cast_nullable_to_non_nullable
@@ -285,6 +301,11 @@ abstract class _$$ProjectManifestImplCopyWith<$Res>
       List<ProjectPresetCategory> pathCategories,
       List<ProjectTerrainPreset> terrainPresets,
       List<ProjectPathPreset> pathPresets,
+      @JsonKey(
+          name: 'pathPatternPresets',
+          fromJson: decodeProjectPathPatternPresets,
+          toJson: encodeProjectPathPatternPresets)
+      List<ProjectPathPatternPreset> pathPatternPresets,
       List<ProjectEncounterTable> encounterTables,
       List<ProjectDialogueFolder> dialogueFolders,
       List<ProjectDialogueEntry> dialogues,
@@ -332,6 +353,7 @@ class __$$ProjectManifestImplCopyWithImpl<$Res>
     Object? pathCategories = null,
     Object? terrainPresets = null,
     Object? pathPresets = null,
+    Object? pathPatternPresets = null,
     Object? encounterTables = null,
     Object? dialogueFolders = null,
     Object? dialogues = null,
@@ -393,6 +415,10 @@ class __$$ProjectManifestImplCopyWithImpl<$Res>
           ? _value._pathPresets
           : pathPresets // ignore: cast_nullable_to_non_nullable
               as List<ProjectPathPreset>,
+      pathPatternPresets: null == pathPatternPresets
+          ? _value._pathPatternPresets
+          : pathPatternPresets // ignore: cast_nullable_to_non_nullable
+              as List<ProjectPathPatternPreset>,
       encounterTables: null == encounterTables
           ? _value._encounterTables
           : encounterTables // ignore: cast_nullable_to_non_nullable
@@ -458,6 +484,11 @@ class _$ProjectManifestImpl implements _ProjectManifest {
       final List<ProjectPresetCategory> pathCategories = const [],
       final List<ProjectTerrainPreset> terrainPresets = const [],
       final List<ProjectPathPreset> pathPresets = const [],
+      @JsonKey(
+          name: 'pathPatternPresets',
+          fromJson: decodeProjectPathPatternPresets,
+          toJson: encodeProjectPathPatternPresets)
+      final List<ProjectPathPatternPreset> pathPatternPresets = const [],
       final List<ProjectEncounterTable> encounterTables = const [],
       final List<ProjectDialogueFolder> dialogueFolders = const [],
       final List<ProjectDialogueEntry> dialogues = const [],
@@ -483,6 +514,7 @@ class _$ProjectManifestImpl implements _ProjectManifest {
         _pathCategories = pathCategories,
         _terrainPresets = terrainPresets,
         _pathPresets = pathPresets,
+        _pathPatternPresets = pathPatternPresets,
         _encounterTables = encounterTables,
         _dialogueFolders = dialogueFolders,
         _dialogues = dialogues,
@@ -590,6 +622,19 @@ class _$ProjectManifestImpl implements _ProjectManifest {
     return EqualUnmodifiableListView(_pathPresets);
   }
 
+  final List<ProjectPathPatternPreset> _pathPatternPresets;
+  @override
+  @JsonKey(
+      name: 'pathPatternPresets',
+      fromJson: decodeProjectPathPatternPresets,
+      toJson: encodeProjectPathPatternPresets)
+  List<ProjectPathPatternPreset> get pathPatternPresets {
+    if (_pathPatternPresets is EqualUnmodifiableListView)
+      return _pathPatternPresets;
+    // ignore: implicit_dynamic_type
+    return EqualUnmodifiableListView(_pathPatternPresets);
+  }
+
   final List<ProjectEncounterTable> _encounterTables;
   @override
   @JsonKey()
@@ -677,7 +722,7 @@ class _$ProjectManifestImpl implements _ProjectManifest {
 
   @override
   String toString() {
-    return 'ProjectManifest(name: $name, version: $version, maps: $maps, groups: $groups, tilesetFolders: $tilesetFolders, tilesets: $tilesets, elementCategories: $elementCategories, elements: $elements, terrainCategories: $terrainCategories, pathCategories: $pathCategories, terrainPresets: $terrainPresets, pathPresets: $pathPresets, encounterTables: $encounterTables, dialogueFolders: $dialogueFolders, dialogues: $dialogues, scripts: $scripts, scenarios: $scenarios, trainers: $trainers, characters: $characters, settings: $settings, pokemon: $pokemon, globalProperties: $globalProperties, surfaceCatalog: $surfaceCatalog)';
+    return 'ProjectManifest(name: $name, version: $version, maps: $maps, groups: $groups, tilesetFolders: $tilesetFolders, tilesets: $tilesets, elementCategories: $elementCategories, elements: $elements, terrainCategories: $terrainCategories, pathCategories: $pathCategories, terrainPresets: $terrainPresets, pathPresets: $pathPresets, pathPatternPresets: $pathPatternPresets, encounterTables: $encounterTables, dialogueFolders: $dialogueFolders, dialogues: $dialogues, scripts: $scripts, scenarios: $scenarios, trainers: $trainers, characters: $characters, settings: $settings, pokemon: $pokemon, globalProperties: $globalProperties, surfaceCatalog: $surfaceCatalog)';
   }
 
   @override
@@ -703,6 +748,8 @@ class _$ProjectManifestImpl implements _ProjectManifest {
                 .equals(other._terrainPresets, _terrainPresets) &&
             const DeepCollectionEquality()
                 .equals(other._pathPresets, _pathPresets) &&
+            const DeepCollectionEquality()
+                .equals(other._pathPatternPresets, _pathPatternPresets) &&
             const DeepCollectionEquality()
                 .equals(other._encounterTables, _encounterTables) &&
             const DeepCollectionEquality()
@@ -740,6 +787,7 @@ class _$ProjectManifestImpl implements _ProjectManifest {
         const DeepCollectionEquality().hash(_pathCategories),
         const DeepCollectionEquality().hash(_terrainPresets),
         const DeepCollectionEquality().hash(_pathPresets),
+        const DeepCollectionEquality().hash(_pathPatternPresets),
         const DeepCollectionEquality().hash(_encounterTables),
         const DeepCollectionEquality().hash(_dialogueFolders),
         const DeepCollectionEquality().hash(_dialogues),
@@ -784,6 +832,11 @@ abstract class _ProjectManifest implements ProjectManifest {
           final List<ProjectPresetCategory> pathCategories,
           final List<ProjectTerrainPreset> terrainPresets,
           final List<ProjectPathPreset> pathPresets,
+          @JsonKey(
+              name: 'pathPatternPresets',
+              fromJson: decodeProjectPathPatternPresets,
+              toJson: encodeProjectPathPatternPresets)
+          final List<ProjectPathPatternPreset> pathPatternPresets,
           final List<ProjectEncounterTable> encounterTables,
           final List<ProjectDialogueFolder> dialogueFolders,
           final List<ProjectDialogueEntry> dialogues,
@@ -829,6 +882,12 @@ abstract class _ProjectManifest implements ProjectManifest {
   @override
   List<ProjectPathPreset> get pathPresets;
   @override
+  @JsonKey(
+      name: 'pathPatternPresets',
+      fromJson: decodeProjectPathPatternPresets,
+      toJson: encodeProjectPathPatternPresets)
+  List<ProjectPathPatternPreset> get pathPatternPresets;
+  @override
   List<ProjectEncounterTable> get encounterTables;
   @override
   List<ProjectDialogueFolder> get dialogueFolders;
diff --git a/packages/map_core/lib/src/models/project_manifest.g.dart b/packages/map_core/lib/src/models/project_manifest.g.dart
index 35254760..f3a8c8a4 100644
--- a/packages/map_core/lib/src/models/project_manifest.g.dart
+++ b/packages/map_core/lib/src/models/project_manifest.g.dart
@@ -57,6 +57,9 @@ _$ProjectManifestImpl _$$ProjectManifestImplFromJson(
                   (e) => ProjectPathPreset.fromJson(e as Map<String, dynamic>))
               .toList() ??
           const [],
+      pathPatternPresets: json['pathPatternPresets'] == null
+          ? const []
+          : decodeProjectPathPatternPresets(json['pathPatternPresets']),
       encounterTables: (json['encounterTables'] as List<dynamic>?)
               ?.map((e) =>
                   ProjectEncounterTable.fromJson(e as Map<String, dynamic>))
@@ -120,6 +123,8 @@ Map<String, dynamic> _$$ProjectManifestImplToJson(
       'pathCategories': instance.pathCategories.map((e) => e.toJson()).toList(),
       'terrainPresets': instance.terrainPresets.map((e) => e.toJson()).toList(),
       'pathPresets': instance.pathPresets.map((e) => e.toJson()).toList(),
+      'pathPatternPresets':
+          encodeProjectPathPatternPresets(instance.pathPatternPresets),
       'encounterTables':
           instance.encounterTables.map((e) => e.toJson()).toList(),
       'dialogueFolders':
```

## Auto-review

- Ai-je garde la migration legacy interdite ? Oui.
- Ai-je preserve `ProjectPathPreset` ? Oui.
- Ai-je preserve `PathLayer` ? Oui.
- Ai-je evite `ProjectPathPatternCatalog` ? Oui.
- Ai-je teste les anciens manifests sans champ ? Oui.
- Ai-je teste null / empty ? Oui.
- Ai-je teste les fixtures Lot 9 via manifest ? Oui.
- Ai-je evite UI/canvas/runtime/gameplay/battle ? Oui.
- Ai-je controle les generated files ? Oui : seuls `project_manifest.freezed.dart` et `project_manifest.g.dart` changent.

## Critique du prompt

- Ambiguite : `pathPatternPresets: null` etait demande "si techniquement possible"; la solution custom `fromJson` le rend possible, donc ce comportement est teste.
- Decision prise sur null : `null` decode comme `[]`.
- Decision prise sur encodage liste vide : `toJson()` encode toujours `pathPatternPresets: []`.
- Import cycle : le cycle potentiel est conserve pour eviter un refactor de `TilesetVisualFrame`; `build_runner`, analyze et tests passent avec ce choix.
- Decision a valider avant les operations manifest : faut-il conserver les operations en fonctions libres simples, sur le modele des operations `surfaceCatalog`, ou introduire un petit service applicatif plus tard cote editor.
