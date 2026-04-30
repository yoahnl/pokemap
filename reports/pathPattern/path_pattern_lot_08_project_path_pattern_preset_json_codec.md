# PathPattern-8 — ProjectPathPatternPreset JSON Codec V0

## 1. Verdict

Lot accepté.

Le lot ajoute un codec JSON externe pour `ProjectPathPatternPreset` :

- `encodeProjectPathPatternPreset(ProjectPathPatternPreset preset)`
- `decodeProjectPathPatternPreset(Map<String, dynamic> json)`

Le modèle `ProjectPathPatternPreset` reste sans `toJson` / `fromJson`.
`ProjectManifest` n'est pas modifié.
Aucun fichier généré n'a été créé.
Aucun branchement UI, canvas, runtime, gameplay ou battle n'a été ajouté.

## 2. Audit initial

Commandes initiales :

```text
pwd
git status --short --untracked-files=all
git diff --stat
rg -n "ProjectPathPatternPreset|PathCenterPattern|PathCenterPatternCell|PathCenterPatternSize|TilesetTransparentColor|TilesetVisualFrame|TilesetSourceRect|encode.*Path|decode.*Path|Json|json|toJson|fromJson|visual_frame_json|surface_.*json_codec|project_surface.*json_codec" packages/map_core/lib packages/map_core/test
```

Résultats initiaux :

```text
/Users/karim/Project/pokemonProject
```

`git status --short --untracked-files=all` initial :

```text
```

`git diff --stat` initial :

```text
```

Context Mode :

```text
ctx shell absent.
MCP context-mode présent.
ctx_stats: 1.4M tokens saved, 83.0% reduction, v1.0.103.
```

Réponses d'audit :

1. `ProjectPathPatternPreset` vit dans `packages/map_core/lib/src/models/project_path_pattern_preset.dart`.
2. `PathCenterPatternSize`, `PathCenterPatternCell` et `PathCenterPattern` vivent dans `packages/map_core/lib/src/models/path_center_pattern.dart`.
3. `TilesetTransparentColor` vit dans `packages/map_core/lib/src/models/tileset_transparent_color.dart`.
4. `TilesetVisualFrame` vit dans `packages/map_core/lib/src/models/project_manifest.dart`.
5. Le JSON réel de `TilesetVisualFrame` est le format généré existant :

```dart
{
  'tilesetId': instance.tilesetId,
  'source': instance.source.toJson(),
  'durationMs': instance.durationMs,
}
```

6. Le JSON réel de `TilesetSourceRect` est :

```dart
{
  'x': instance.x,
  'y': instance.y,
  'width': instance.width,
  'height': instance.height,
}
```

7. `packages/map_core/lib/src/models/visual_frame_json.dart` existe, mais sert à migrer l'ancien champ `source` vers `frames`; ce n'est pas un encodeur/décodeur général de `TilesetVisualFrame`.
8. Les codecs Surface récents vivent côté `operations`, sont externes aux modèles, utilisent `ValidationException`, tolèrent les clés inconnues, omettent les optionnels `null` à l'encodage, et gardent `sortOrder` présent dans le JSON.
9. Le codec PathPattern reste externe pour garder `ProjectPathPatternPreset` pur et éviter Freezed/build_runner/generated.
10. Les tests PathPattern à relancer sont le test Lot 8, la régression Lot 7, les régressions core Lots 0 à 4, et les trois régressions preview côté editor.

## 3. Fichiers créés / modifiés / supprimés

Créés :

```text
packages/map_core/lib/src/operations/project_path_pattern_preset_json_codec.dart
packages/map_core/test/project_path_pattern_preset_json_codec_test.dart
reports/pathPattern/path_pattern_lot_08_project_path_pattern_preset_json_codec.md
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
Map<String, dynamic> encodeProjectPathPatternPreset(
  ProjectPathPatternPreset preset,
)

ProjectPathPatternPreset decodeProjectPathPatternPreset(
  Map<String, dynamic> json,
)
```

Le codec expose uniquement ces deux fonctions publiques.
Les encodeurs/décodeurs de `PathCenterPattern`, `PathCenterPatternSize`, `PathCenterPatternCell`, `TilesetTransparentColor` et `TilesetVisualFrame` sont privés.

## 5. Format JSON retenu

Format minimal :

```json
{
  "id": "water-1x1",
  "name": "Water 1x1",
  "basePathPresetId": "legacy-water",
  "centerPattern": {
    "size": {
      "width": 1,
      "height": 1
    },
    "cells": [
      {
        "localX": 0,
        "localY": 0,
        "frames": [
          {
            "tilesetId": "",
            "source": {
              "x": 1,
              "y": 2,
              "width": 1,
              "height": 1
            },
            "durationMs": null
          }
        ]
      }
    ]
  },
  "sortOrder": 0
}
```

Format complet testé :

```json
{
  "id": "water-sea-2x2",
  "name": "Mer 2x2",
  "basePathPresetId": "legacy-water",
  "centerPattern": {
    "size": {
      "width": 2,
      "height": 2
    },
    "cells": [
      {
        "localX": 0,
        "localY": 0,
        "frames": [
          {
            "tilesetId": "",
            "source": {
              "x": 0,
              "y": 0,
              "width": 1,
              "height": 1
            },
            "durationMs": 100
          },
          {
            "tilesetId": "",
            "source": {
              "x": 1,
              "y": 0,
              "width": 1,
              "height": 1
            },
            "durationMs": 110
          }
        ]
      }
    ]
  },
  "transparentColor": "f05ba1",
  "categoryId": "water",
  "sortOrder": 12
}
```

## 6. Décision champs obligatoires / optionnels

Champs obligatoires au décodage :

```text
id
name
basePathPresetId
centerPattern
sortOrder
```

Champs optionnels :

```text
transparentColor
categoryId
```

Décisions :

- `sortOrder` est obligatoire dans le JSON PathPattern V0, même si le modèle Dart a un défaut `0`.
- `transparentColor` est encodé seulement si non-null.
- `categoryId` est encodé seulement si non-null.
- `categoryId: ''` est encodé, car il est non-null.
- les clés inconnues ne sont pas réémises.

## 7. Décision centerPattern JSON

`centerPattern` encode :

```text
size.width
size.height
cells[]
```

Les cellules sont encodées dans l'ordre exposé par `PathCenterPattern.cells`.
Cet ordre est déjà normalisé row-major par le modèle du Lot 1.

Au décodage, le codec reconstruit :

```text
PathCenterPatternSize
PathCenterPatternCell
PathCenterPattern
```

Les validations existantes gardent les garanties de grille :

- taille positive ;
- cellules non vides ;
- grille complète ;
- pas de doublons ;
- pas de cellule hors grille ;
- frames non vides.

## 8. Décision frame JSON

Le codec réutilise le format généré existant de `TilesetVisualFrame`.

Encodage :

```dart
frame.toJson()
```

Décodage :

```dart
TilesetVisualFrame.fromJson(normalized)
```

Le codec normalise seulement les maps dynamiques en `Map<String, dynamic>` pour éviter un échec de cast sur les maps imbriquées.

Comportement documenté par test :

- `tilesetId: ''` est conservé ;
- `tilesetId: 'override_tileset'` est conservé ;
- `durationMs: null` reste présent dans le JSON généré ;
- `durationMs: 100` est conservé ;
- `source.width` et `source.height` sont encodés explicitement.

## 9. Décision transparentColor JSON

Format retenu :

```json
"transparentColor": "f05ba1"
```

Encodage :

```dart
preset.transparentColor!.toHexRgb()
```

Décodage :

```dart
TilesetTransparentColor.fromHexRgb(value)
```

`"#F05BA1"` est accepté au décodage via le value object, puis réencodé en canonique :

```text
f05ba1
```

## 10. Erreurs / validations

Le codec utilise `ValidationException` pour les erreurs de forme JSON :

- champ requis manquant ;
- mauvais type évident ;
- `centerPattern` sans `size` ;
- `centerPattern` sans `cells` ;
- `size` sans `width` ou `height` ;
- cellule sans `localX`, `localY` ou `frames` ;
- `frames` non-list ;
- frame sans `source` ;
- `transparentColor` invalide.

Les validations métier déjà présentes restent portées par les value objects.

## 11. Tests lancés

### Test ciblé Lot 8

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

### Régressions preview map_editor

Commandes :

```bash
cd packages/map_editor && flutter test test/path_pattern/path_center_pattern_animated_preview_renderer_test.dart --no-pub --reporter expanded
cd packages/map_editor && flutter test test/path_pattern/path_center_pattern_static_preview_renderer_test.dart --no-pub --reporter expanded
cd packages/map_editor && flutter test test/path_pattern/tileset_transparent_color_processor_test.dart --no-pub --reporter expanded
```

Sorties complètes :

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
00:01 +1083: All tests passed!
```

## 12. Analyze

Commande :

```bash
cd packages/map_core && dart analyze lib/src/operations/project_path_pattern_preset_json_codec.dart test/project_path_pattern_preset_json_codec_test.dart
```

Sortie complète :

```text
Analyzing project_path_pattern_preset_json_codec.dart, project_path_pattern_preset_json_codec_test.dart...
No issues found!
```

## 13. Non-objectifs confirmés

Confirmé :

- pas d'intégration manifest ;
- pas de migration JSON ;
- pas de golden sample JSON ;
- pas de build_runner ;
- pas de Freezed ;
- pas de fichier généré ;
- pas de `toJson` / `fromJson` ajouté à `ProjectPathPatternPreset` ;
- pas de modification de `ProjectPathPatternPreset` ;
- pas de modification de `ProjectPathPreset` ;
- pas de modification de `TerrainPathVariant` ;
- pas de modification de `PathLayer` ;
- pas d'UI ;
- pas de widget ;
- pas de preview nouvelle ;
- pas de canvas ;
- pas de painter integration ;
- pas de runtime ;
- pas de gameplay ;
- pas de battle ;
- pas de save flow ;
- pas de traitement hautes herbes.

Contrôle de couplage :

```bash
rg -n "ProjectManifest|ProjectPathPreset\\b|TerrainPathVariant|PathLayer|map_runtime|map_gameplay|map_battle|build_runner|Freezed|freezed|TSX|TMX|Mistral|PixelLab|Widget|Flutter|tall grass|TallGrass" packages/map_core/lib/src/operations/project_path_pattern_preset_json_codec.dart packages/map_core/test/project_path_pattern_preset_json_codec_test.dart
```

Sortie complète :

```text
```

## 14. Limites restantes

- Le codec ne branche pas `ProjectPathPatternPreset` dans un manifest.
- Le codec ne vérifie pas que `basePathPresetId` existe réellement.
- Le codec ne résout pas le tileset effectif des frames.
- Aucun golden JSON canonique n'est ajouté dans ce lot.
- Le format JSON n'a pas encore de migration.
- Le test complet `map_editor` n'a pas été lancé, car ce lot ne modifie pas `map_editor`; les trois tests `test/path_pattern` demandés ont été lancés.

## 15. Git status final

Commande :

```bash
git status --short --untracked-files=all
```

Sortie complète :

```text
 M packages/map_core/lib/map_core.dart
?? packages/map_core/lib/src/operations/project_path_pattern_preset_json_codec.dart
?? packages/map_core/test/project_path_pattern_preset_json_codec_test.dart
?? reports/pathPattern/path_pattern_lot_08_project_path_pattern_preset_json_codec.md
```

## 16. Prochain lot recommandé

Prochain lot recommandé :

```text
PathPattern-9 — Manifest Decision / Golden JSON
```

Objectif recommandé :

- décider si le codec entre dans une fixture JSON canonique avant l'intégration manifest ;
- ajouter un ou plusieurs samples JSON stables si le format est validé ;
- ne pas brancher l'UI tant que le point manifest/golden n'est pas fermé.

## Evidence Pack

### Contenu complet — packages/map_core/lib/src/operations/project_path_pattern_preset_json_codec.dart

```dart
// JSON codec manuel — [ProjectPathPatternPreset].
//
// Prépare une future persistance PathPattern sans branchement manifeste et
// sans ajouter toJson/fromJson au modèle. Le codec réutilise le format généré
// existant de TilesetVisualFrame pour éviter un second schéma de frame.

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

### Contenu complet — packages/map_core/test/project_path_pattern_preset_json_codec_test.dart

```dart
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectPathPatternPreset JSON codec', () {
    test('encodes a minimal preset', () {
      final preset = ProjectPathPatternPreset(
        id: 'water-1x1',
        name: 'Water 1x1',
        basePathPresetId: 'legacy-water',
        centerPattern: _singleCellPattern(),
      );

      final json = encodeProjectPathPatternPreset(preset);

      expect(json['id'], 'water-1x1');
      expect(json['name'], 'Water 1x1');
      expect(json['basePathPresetId'], 'legacy-water');
      expect(json['sortOrder'], 0);
      expect(json, isNot(contains('transparentColor')));
      expect(json, isNot(contains('categoryId')));
      expect(json['centerPattern'], {
        'size': {'width': 1, 'height': 1},
        'cells': [
          {
            'localX': 0,
            'localY': 0,
            'frames': [
              _frame(1, 2).toJson(),
            ],
          },
        ],
      });
    });

    test('decodes a minimal preset', () {
      final preset = decodeProjectPathPatternPreset({
        'id': 'water-1x1',
        'name': 'Water 1x1',
        'basePathPresetId': 'legacy-water',
        'sortOrder': 0,
        'centerPattern': {
          'size': {'width': 1, 'height': 1},
          'cells': [
            {
              'localX': 0,
              'localY': 0,
              'frames': [
                _frame(1, 2).toJson(),
              ],
            },
          ],
        },
      });

      expect(preset.id, 'water-1x1');
      expect(preset.name, 'Water 1x1');
      expect(preset.basePathPresetId, 'legacy-water');
      expect(preset.transparentColor, isNull);
      expect(preset.categoryId, isNull);
      expect(preset.sortOrder, 0);
      expect(preset.centerPattern, _singleCellPattern());
    });

    test('roundtrips a minimal preset', () {
      final preset = ProjectPathPatternPreset(
        id: 'water-1x1',
        name: 'Water 1x1',
        basePathPresetId: 'legacy-water',
        centerPattern: _singleCellPattern(),
      );

      expect(
        decodeProjectPathPatternPreset(encodeProjectPathPatternPreset(preset)),
        preset,
      );
    });

    test('encodes a complete 2x2 preset in row-major cell order', () {
      final preset = ProjectPathPatternPreset(
        id: 'water-sea-2x2',
        name: 'Mer 2x2',
        basePathPresetId: 'legacy-water',
        centerPattern: _twoByTwoPattern(),
        transparentColor: TilesetTransparentColor.fromHexRgb('f05ba1'),
        categoryId: 'water',
        sortOrder: 12,
      );

      final json = encodeProjectPathPatternPreset(preset);
      final centerPattern = json['centerPattern'] as Map<String, dynamic>;
      final cells = centerPattern['cells'] as List<dynamic>;

      expect(json['transparentColor'], 'f05ba1');
      expect(json['categoryId'], 'water');
      expect(json['sortOrder'], 12);
      expect(
        cells
            .map(
              (dynamic cell) => [
                (cell as Map<String, dynamic>)['localX'],
                cell['localY'],
              ],
            )
            .toList(),
        [
          [0, 0],
          [1, 0],
          [0, 1],
          [1, 1],
        ],
      );
      expect(
        ((cells[0] as Map<String, dynamic>)['frames'] as List<dynamic>)
            .map((dynamic frame) => (frame as Map<String, dynamic>)['source'])
            .toList(),
        [
          {'x': 0, 'y': 0, 'width': 1, 'height': 1},
          {'x': 1, 'y': 0, 'width': 1, 'height': 1},
        ],
      );
    });

    test('roundtrips a complete 2x2 preset', () {
      final preset = ProjectPathPatternPreset(
        id: 'water-sea-2x2',
        name: 'Mer 2x2',
        basePathPresetId: 'legacy-water',
        centerPattern: _twoByTwoPattern(),
        transparentColor: TilesetTransparentColor.fromHexRgb('f05ba1'),
        categoryId: 'water',
        sortOrder: 12,
      );

      expect(
        decodeProjectPathPatternPreset(encodeProjectPathPatternPreset(preset)),
        preset,
      );
    });

    test('canonicalizes transparentColor after decode and encode', () {
      final preset = decodeProjectPathPatternPreset({
        'id': 'water-sea-2x2',
        'name': 'Mer 2x2',
        'basePathPresetId': 'legacy-water',
        'sortOrder': 12,
        'transparentColor': '#F05BA1',
        'centerPattern': _encodedSingleCellPattern(),
      });

      expect(
        encodeProjectPathPatternPreset(preset)['transparentColor'],
        'f05ba1',
      );
    });

    test('roundtrips frame tileset overrides', () {
      final preset = ProjectPathPatternPreset(
        id: 'water-animated',
        name: 'Water animated',
        basePathPresetId: 'legacy-water',
        centerPattern: PathCenterPattern(
          size: PathCenterPatternSize(width: 1, height: 1),
          cells: [
            PathCenterPatternCell(
              localX: 0,
              localY: 0,
              frames: [
                _frame(0, 0),
                _frame(1, 0, tilesetId: 'override_tileset'),
              ],
            ),
          ],
        ),
      );

      final roundtripped = decodeProjectPathPatternPreset(
        encodeProjectPathPatternPreset(preset),
      );
      final frames = roundtripped.centerPattern.cellAt(0, 0).frames;

      expect(frames[0].tilesetId, '');
      expect(frames[1].tilesetId, 'override_tileset');
    });

    test('roundtrips null and non-null frame durations', () {
      final preset = ProjectPathPatternPreset(
        id: 'water-duration',
        name: 'Water duration',
        basePathPresetId: 'legacy-water',
        centerPattern: PathCenterPattern(
          size: PathCenterPatternSize(width: 1, height: 1),
          cells: [
            PathCenterPatternCell(
              localX: 0,
              localY: 0,
              frames: [
                _frame(0, 0),
                _frame(1, 0, durationMs: 100),
              ],
            ),
          ],
        ),
      );

      final json = encodeProjectPathPatternPreset(preset);
      final frames = ((((json['centerPattern'] as Map<String, dynamic>)['cells']
              as List<dynamic>)
          .single as Map<String, dynamic>)['frames']) as List<dynamic>;
      final roundtripped = decodeProjectPathPatternPreset(json);
      final decodedFrames = roundtripped.centerPattern.cellAt(0, 0).frames;

      expect(frames[0], containsPair('durationMs', null));
      expect(frames[1], containsPair('durationMs', 100));
      expect(decodedFrames[0].durationMs, isNull);
      expect(decodedFrames[1].durationMs, 100);
    });

    test('rejects invalid JSON', () {
      for (final json in [
        _validJson()..remove('id'),
        _validJson()..remove('name'),
        _validJson()..remove('basePathPresetId'),
        _validJson()..remove('centerPattern'),
        _validJson()..remove('sortOrder'),
        _validJson()
          ..['centerPattern'] = {
            'cells': [],
          },
        _validJson()
          ..['centerPattern'] = {
            'size': {'width': 1, 'height': 1},
          },
        _validJson()
          ..['centerPattern'] = {
            'size': {'height': 1},
            'cells': [],
          },
        _validJson()
          ..['centerPattern'] = {
            'size': {'width': 1},
            'cells': [],
          },
        _validJson()
          ..['centerPattern'] = {
            'size': {'width': 1, 'height': 1},
            'cells': [
              {
                'localY': 0,
                'frames': [_frame(0, 0).toJson()],
              },
            ],
          },
        _validJson()
          ..['centerPattern'] = {
            'size': {'width': 1, 'height': 1},
            'cells': [
              {
                'localX': 0,
                'frames': [_frame(0, 0).toJson()],
              },
            ],
          },
        _validJson()
          ..['centerPattern'] = {
            'size': {'width': 1, 'height': 1},
            'cells': [
              {'localX': 0, 'localY': 0},
            ],
          },
        _validJson()
          ..['centerPattern'] = {
            'size': {'width': 1, 'height': 1},
            'cells': [
              {'localX': 0, 'localY': 0, 'frames': 'not-list'},
            ],
          },
        _validJson()..['transparentColor'] = 'not-hex',
      ]) {
        expect(
          () => decodeProjectPathPatternPreset(json),
          throwsA(anyOf(isA<ValidationException>(), isA<ArgumentError>())),
          reason: json.toString(),
        );
      }
    });
  });
}

PathCenterPattern _singleCellPattern() {
  return PathCenterPattern(
    size: PathCenterPatternSize(width: 1, height: 1),
    cells: [
      PathCenterPatternCell(
        localX: 0,
        localY: 0,
        frames: [_frame(1, 2)],
      ),
    ],
  );
}

PathCenterPattern _twoByTwoPattern() {
  return PathCenterPattern(
    size: PathCenterPatternSize(width: 2, height: 2),
    cells: [
      PathCenterPatternCell(
        localX: 1,
        localY: 1,
        frames: [_frame(3, 0, durationMs: 130)],
      ),
      PathCenterPatternCell(
        localX: 0,
        localY: 1,
        frames: [_frame(2, 0, durationMs: 120)],
      ),
      PathCenterPatternCell(
        localX: 1,
        localY: 0,
        frames: [_frame(1, 0, durationMs: 110)],
      ),
      PathCenterPatternCell(
        localX: 0,
        localY: 0,
        frames: [
          _frame(0, 0, durationMs: 100),
          _frame(1, 0, durationMs: 110),
        ],
      ),
    ],
  );
}

Map<String, dynamic> _encodedSingleCellPattern() {
  return {
    'size': {'width': 1, 'height': 1},
    'cells': [
      {
        'localX': 0,
        'localY': 0,
        'frames': [_frame(1, 2).toJson()],
      },
    ],
  };
}

Map<String, dynamic> _validJson() {
  return {
    'id': 'water-1x1',
    'name': 'Water 1x1',
    'basePathPresetId': 'legacy-water',
    'sortOrder': 0,
    'centerPattern': _encodedSingleCellPattern(),
  };
}

TilesetVisualFrame _frame(
  int x,
  int y, {
  String tilesetId = '',
  int? durationMs,
}) {
  return TilesetVisualFrame(
    tilesetId: tilesetId,
    source: TilesetSourceRect(x: x, y: y),
    durationMs: durationMs,
  );
}
```

### Diff complet réel

`packages/map_core/lib/map_core.dart` :

```diff
diff --git a/packages/map_core/lib/map_core.dart b/packages/map_core/lib/map_core.dart
index 734686d2..ed08ac63 100644
--- a/packages/map_core/lib/map_core.dart
+++ b/packages/map_core/lib/map_core.dart
@@ -35,6 +35,7 @@ export 'src/operations/map_terrain.dart';
 export 'src/operations/map_terrain_autotile.dart';
 export 'src/operations/path_center_pattern_resolver.dart';
 export 'src/operations/project_path_preset_center_pattern_adapter.dart';
+export 'src/operations/project_path_pattern_preset_json_codec.dart';
 export 'src/operations/project_json_migrations.dart';
 export 'src/operations/tile_visual_frame_timeline.dart';
 export 'src/operations/tile_visual_frame_vertical_atlas.dart';
```

Les deux fichiers créés sont ajoutés intégralement dans les sections de contenu complet ci-dessus. Leur diff d'ajout correspond à ces lignes ajoutées depuis un fichier inexistant.

## Auto-review

- Ai-je gardé le codec externe ? Oui.
- Ai-je évité toJson/fromJson dans le modèle ? Oui.
- Ai-je évité ProjectManifest ? Oui pour toute modification et intégration; l'import `project_manifest.dart` reste nécessaire car `TilesetVisualFrame` et `TilesetSourceRect` y vivent déjà.
- Ai-je évité ProjectPathPreset modification ? Oui.
- Ai-je évité generated/build_runner/Freezed ? Oui.
- Ai-je évité runtime/gameplay/battle ? Oui.
- Ai-je évité UI/canvas ? Oui.
- Ai-je réutilisé ou respecté le format TilesetVisualFrame existant ? Oui, via `frame.toJson()` et `TilesetVisualFrame.fromJson(...)`.
- Ai-je testé JSON minimal, complet et invalides ? Oui.

## Critique du prompt

- Le prompt demande `sortOrder` obligatoire dans le JSON V0, alors que certains codecs Surface récents tolèrent son absence et retombent à `0`. J'ai suivi le contrat du lot PathPattern-8.
- Le prompt interdit toute intégration manifest, mais les types `TilesetVisualFrame` et `TilesetSourceRect` vivent actuellement dans `project_manifest.dart`; le codec importe donc ce fichier pour ces value objects uniquement.
- Le prompt demande un codec externe sans créer de format frame concurrent; la stratégie retenue est de déléguer aux méthodes générées existantes de `TilesetVisualFrame`.
- Avant le Lot 9, il faut valider si on veut d'abord des golden JSON samples ou une décision d'intégration manifest.
