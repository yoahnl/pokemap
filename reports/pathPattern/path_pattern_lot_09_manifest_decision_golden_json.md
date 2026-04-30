# PathPattern-9 — Manifest Decision / Golden JSON V0

## 1. Verdict

Lot accepté.

Le lot ajoute deux fixtures golden JSON pour `ProjectPathPatternPreset` et un test de caractérisation associé. Il documente aussi la décision recommandée pour le futur manifest : ajouter une liste root-level `pathPatternPresets` dans un prochain lot, sans migrer automatiquement les anciens `pathPresets`.

`ProjectManifest` n'a pas été modifié dans ce lot.

## 2. Audit initial

Commandes initiales :

```bash
pwd
git status --short --untracked-files=all
git diff --stat
rg -n "ProjectPathPatternPreset|encodeProjectPathPatternPreset|decodeProjectPathPatternPreset|ProjectManifest|pathPresets|surfaceCatalog|ProjectSurfaceCatalog|golden|fixture|fixtures|jsonEncode|JsonEncoder|project_path_pattern|pathPattern" packages/map_core/lib packages/map_core/test reports/pathPattern
```

Sortie `pwd` :

```text
/Users/karim/Project/pokemonProject
```

`git status --short --untracked-files=all` initial :

```text
 M packages/map_core/lib/map_core.dart
?? packages/map_core/lib/src/operations/project_path_pattern_preset_json_codec.dart
?? packages/map_core/test/project_path_pattern_preset_json_codec_test.dart
?? reports/pathPattern/path_pattern_lot_08_project_path_pattern_preset_json_codec.md
```

`git diff --stat` initial :

```text
 packages/map_core/lib/map_core.dart | 1 +
 1 file changed, 1 insertion(+)
```

Context Mode :

```text
ctx shell absent.
MCP context-mode présent.
ctx_stats: 1.4M tokens saved, 83.0% reduction, v1.0.103.
```

Réponses d'audit :

1. `ProjectPathPatternPreset` vit dans `packages/map_core/lib/src/models/project_path_pattern_preset.dart`.
2. Son codec JSON externe vit dans `packages/map_core/lib/src/operations/project_path_pattern_preset_json_codec.dart`.
3. Le Lot 8 teste déjà un JSON minimal 1x1, un JSON complet 2x2, la canonicalisation de `transparentColor`, les overrides `tilesetId`, `durationMs` null/non-null et les JSON invalides.
4. Un dossier de fixtures golden existe déjà dans `packages/map_core/test/fixtures/surface_catalog_json/`.
5. La convention de nommage existante utilise des fichiers descriptifs en snake_case avec suffixe de version, par exemple `minimal_water_surface_catalog_v0.json`.
6. Les tests golden existants lisent les fichiers avec `dart:io`, décodent via `jsonDecode`, comparent les maps issues du codec, vérifient le roundtrip, puis vérifient un pretty JSON à 2 espaces avec newline final.
7. `SurfaceCatalog` a été intégré à `ProjectManifest` via un champ `surfaceCatalog` avec `@JsonKey(fromJson: ..., toJson: ...)`, acceptant absence/null comme catalogue vide et réencodant toujours le champ.
8. `ProjectManifest` contient déjà des listes de presets root-level : `terrainPresets` et `pathPresets`.
9. La stratégie manifest la plus sûre pour PathPattern V0 est `ProjectManifest.pathPatternPresets: List<ProjectPathPatternPreset>` au prochain lot, sans catalogue dédié au départ.
10. Les tests à relancer sont le golden Lot 9, les régressions Lots 8 et 7, les régressions PathPattern core, les trois previews `map_editor`, l'analyse ciblée et le test complet `map_core`.

## 3. Fichiers créés / modifiés / supprimés

Créés :

```text
packages/map_core/test/fixtures/path_pattern/project_path_pattern_preset_minimal_1x1.json
packages/map_core/test/fixtures/path_pattern/project_path_pattern_preset_complete_2x2.json
packages/map_core/test/project_path_pattern_preset_json_golden_test.dart
reports/pathPattern/path_pattern_lot_09_manifest_decision_golden_json.md
```

Modifiés par ce lot :

```text
aucun fichier de production
```

Supprimés :

```text
aucun
```

Note d'état :

```text
Le worktree contenait déjà les fichiers du Lot 8 avant ce lot.
```

## 4. Fixtures golden créées

Fixtures créées :

```text
packages/map_core/test/fixtures/path_pattern/project_path_pattern_preset_minimal_1x1.json
packages/map_core/test/fixtures/path_pattern/project_path_pattern_preset_complete_2x2.json
```

Conventions appliquées :

- JSON à 2 espaces ;
- ordre des clés identique au codec ;
- newline final ;
- fixtures nues, sans wrapper manifest ;
- `sortOrder` présent ;
- `durationMs: null` explicitement présent quand la frame Dart vaut `null`, car `TilesetVisualFrame.toJson()` encode ce champ.

## 5. Format golden minimal

Contenu complet :

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

Décisions :

- `transparentColor` absent ;
- `categoryId` absent ;
- `centerPattern` 1x1 ;
- une seule frame ;
- `durationMs` explicitement null.

## 6. Format golden complet

Contenu complet :

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
            "tilesetId": "override_tileset",
            "source": {
              "x": 1,
              "y": 0,
              "width": 1,
              "height": 1
            },
            "durationMs": 110
          }
        ]
      },
      {
        "localX": 1,
        "localY": 0,
        "frames": [
          {
            "tilesetId": "",
            "source": {
              "x": 2,
              "y": 0,
              "width": 1,
              "height": 1
            },
            "durationMs": 120
          }
        ]
      },
      {
        "localX": 0,
        "localY": 1,
        "frames": [
          {
            "tilesetId": "",
            "source": {
              "x": 3,
              "y": 0,
              "width": 1,
              "height": 1
            },
            "durationMs": 130
          }
        ]
      },
      {
        "localX": 1,
        "localY": 1,
        "frames": [
          {
            "tilesetId": "",
            "source": {
              "x": 4,
              "y": 0,
              "width": 1,
              "height": 1
            },
            "durationMs": 140
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

Décisions :

- cellules en row-major : `(0,0)`, `(1,0)`, `(0,1)`, `(1,1)` ;
- `transparentColor` canonique `f05ba1` ;
- `categoryId` présent ;
- `sortOrder` présent ;
- `tilesetId` override présent sur une frame ;
- durations non-null présentes ;
- ordre des frames conservé.

## 7. Tests golden

Test créé :

```text
packages/map_core/test/project_path_pattern_preset_json_golden_test.dart
```

Comportements testés :

- decode golden minimal ;
- encode golden minimal ;
- decode golden complet ;
- encode golden complet ;
- roundtrip de chaque fixture ;
- formatage canonique à 2 espaces avec newline final.

Contenu complet du test :

```dart
import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectPathPatternPreset JSON golden samples', () {
    test('minimal 1x1 golden decodes to the expected preset', () {
      final preset = decodeProjectPathPatternPreset(
        _readFixtureJson('project_path_pattern_preset_minimal_1x1.json'),
      );

      expect(preset.id, 'water-1x1');
      expect(preset.name, 'Water 1x1');
      expect(preset.basePathPresetId, 'legacy-water');
      expect(preset.sortOrder, 0);
      expect(preset.transparentColor, isNull);
      expect(preset.categoryId, isNull);
      expect(preset.centerPattern.size,
          PathCenterPatternSize(width: 1, height: 1));
      final cell = preset.centerPattern.cellAt(0, 0);
      expect(cell.frames.single.source, const TilesetSourceRect(x: 1, y: 2));
      expect(cell.frames.single.durationMs, isNull);
    });

    test('minimal 1x1 golden matches encode output', () {
      final preset = ProjectPathPatternPreset(
        id: 'water-1x1',
        name: 'Water 1x1',
        basePathPresetId: 'legacy-water',
        centerPattern: _minimalCenterPattern(),
      );

      expect(
        encodeProjectPathPatternPreset(preset),
        _readFixtureJson('project_path_pattern_preset_minimal_1x1.json'),
      );
    });

    test('complete 2x2 golden decodes to the expected preset', () {
      final preset = decodeProjectPathPatternPreset(
        _readFixtureJson('project_path_pattern_preset_complete_2x2.json'),
      );

      expect(preset.id, 'water-sea-2x2');
      expect(preset.name, 'Mer 2x2');
      expect(preset.basePathPresetId, 'legacy-water');
      expect(preset.sortOrder, 12);
      expect(preset.transparentColor,
          TilesetTransparentColor.fromHexRgb('f05ba1'));
      expect(preset.categoryId, 'water');
      expect(preset.centerPattern.size,
          PathCenterPatternSize(width: 2, height: 2));
      expect(
        preset.centerPattern.cells
            .map((cell) => [cell.localX, cell.localY])
            .toList(),
        [
          [0, 0],
          [1, 0],
          [0, 1],
          [1, 1],
        ],
      );
      final firstFrames = preset.centerPattern.cellAt(0, 0).frames;
      expect(firstFrames[0].source, const TilesetSourceRect(x: 0, y: 0));
      expect(firstFrames[0].durationMs, 100);
      expect(firstFrames[1].tilesetId, 'override_tileset');
      expect(firstFrames[1].source, const TilesetSourceRect(x: 1, y: 0));
      expect(firstFrames[1].durationMs, 110);
      expect(preset.centerPattern.cellAt(1, 0).frames.single.durationMs, 120);
      expect(preset.centerPattern.cellAt(0, 1).frames.single.durationMs, 130);
      expect(preset.centerPattern.cellAt(1, 1).frames.single.durationMs, 140);
    });

    test('complete 2x2 golden matches encode output', () {
      expect(
        encodeProjectPathPatternPreset(_completePreset()),
        _readFixtureJson('project_path_pattern_preset_complete_2x2.json'),
      );
    });

    test('goldens roundtrip through decode and encode', () {
      for (final name in _fixtureNames) {
        final fixture = _readFixtureJson(name);
        final preset = decodeProjectPathPatternPreset(fixture);

        expect(encodeProjectPathPatternPreset(preset), fixture, reason: name);
      }
    });

    test('goldens use two-space canonical formatting with final newline', () {
      for (final name in _fixtureNames) {
        final raw = _readFixture(name);
        final decoded = jsonDecode(raw) as Object?;
        const encoder = JsonEncoder.withIndent('  ');
        final pretty = _withTrailingNewline(encoder.convert(decoded));

        expect(raw.endsWith('\n'), isTrue, reason: name);
        expect(pretty, raw, reason: name);
      }
    });
  });
}

const _fixtureNames = [
  'project_path_pattern_preset_minimal_1x1.json',
  'project_path_pattern_preset_complete_2x2.json',
];

String _fixturePath(String name) => 'test/fixtures/path_pattern/$name';

String _readFixture(String name) => File(_fixturePath(name)).readAsStringSync();

Map<String, dynamic> _readFixtureJson(String name) {
  return jsonDecode(_readFixture(name)) as Map<String, dynamic>;
}

String _withTrailingNewline(String value) {
  if (value.endsWith('\n')) {
    return value;
  }
  return '$value\n';
}

ProjectPathPatternPreset _completePreset() {
  return ProjectPathPatternPreset(
    id: 'water-sea-2x2',
    name: 'Mer 2x2',
    basePathPresetId: 'legacy-water',
    centerPattern: _completeCenterPattern(),
    transparentColor: TilesetTransparentColor.fromHexRgb('f05ba1'),
    categoryId: 'water',
    sortOrder: 12,
  );
}

PathCenterPattern _minimalCenterPattern() {
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

PathCenterPattern _completeCenterPattern() {
  return PathCenterPattern(
    size: PathCenterPatternSize(width: 2, height: 2),
    cells: [
      PathCenterPatternCell(
        localX: 0,
        localY: 0,
        frames: [
          _frame(0, 0, durationMs: 100),
          _frame(1, 0, tilesetId: 'override_tileset', durationMs: 110),
        ],
      ),
      PathCenterPatternCell(
        localX: 1,
        localY: 0,
        frames: [_frame(2, 0, durationMs: 120)],
      ),
      PathCenterPatternCell(
        localX: 0,
        localY: 1,
        frames: [_frame(3, 0, durationMs: 130)],
      ),
      PathCenterPatternCell(
        localX: 1,
        localY: 1,
        frames: [_frame(4, 0, durationMs: 140)],
      ),
    ],
  );
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

## 8. Décision manifest : options A/B/C/D

### Option A — Ajouter `ProjectManifest.pathPatternPresets`

Description :

```text
Ajouter une liste root-level :
pathPatternPresets: List<ProjectPathPatternPreset>
```

Avantages :

- simple ;
- cohérent avec `terrainPresets` et `pathPresets` ;
- accès direct côté editor ;
- adapté au concept produit : ce sont des presets projet ;
- plus facile à tester par une intégration manifest ciblée.

Risques :

- modification `ProjectManifest` ;
- génération Freezed/JSON nécessaire dans le lot dédié ;
- anciens projets sans champ à gérer ;
- diagnostics nécessaires pour `basePathPresetId` manquant.

### Option B — Créer un `ProjectPathPatternCatalog`

Description :

```text
Créer un catalogue dédié :
pathPatternCatalog: { "presets": [...] }
```

Avantages :

- extensible ;
- pourrait porter metadata, diagnostics ou catégories dédiées plus tard ;
- proche du style `ProjectSurfaceCatalog`.

Risques :

- trop lourd pour V0 ;
- ajoute un concept alors qu'une simple liste suffit ;
- risque de dupliquer les ambitions Surface au lieu de garder Path Studio simple.

### Option C — Garder PathPattern hors manifest pour l'instant

Description :

```text
Conserver uniquement fixtures, tests ou état temporaire editor.
```

Avantages :

- aucun risque sur `project.json` ;
- utile pour prototyper une UI locale.

Risques :

- pas de persistance réelle ;
- bloque le save flow ;
- dette editor rapide ;
- impossible de partager proprement les presets entre sessions.

### Option D — Étendre `ProjectPathPreset` directement

Description :

```text
Ajouter centerPattern directement dans ProjectPathPreset.
```

Avantages :

- un seul modèle de preset path.

Risques :

- risque JSON legacy élevé ;
- mélange ancien/nouveau ;
- rollback plus difficile ;
- contraire aux décisions des Lots 0 et 7 ;
- oblige à traiter les vieux presets comme s'ils avaient toujours eu un centre pattern.

## 9. Recommandation manifest V0

Recommandation : Option A au prochain lot.

Forme cible :

```text
ProjectManifest.pathPatternPresets: List<ProjectPathPatternPreset>
```

Contrat recommandé pour le Lot 10 :

- décoder les anciens manifests sans `pathPatternPresets` comme `[]` ;
- encoder `pathPatternPresets` de manière stable ;
- ne pas migrer automatiquement les `pathPresets` legacy ;
- ne pas supprimer `ProjectPathPreset` ;
- ne pas changer `PathLayer` immédiatement ;
- ne pas brancher le painter ni l'UI dans le lot manifest ;
- ajouter des tests manifest ciblés similaires à l'intégration `surfaceCatalog`.

Pourquoi Option A est suffisante :

```text
Le besoin V0 est seulement de persister une liste de presets projet qui référencent un preset path legacy par id. Un catalogue dédié n'apporte pas encore de valeur concrète.
```

Pourquoi Option B est trop lourde maintenant :

```text
Le modèle PathPattern n'a pas encore diagnostics, catégories dédiées, assets multiples ou opérations catalogue. Créer un catalogue maintenant ajouterait surtout de la surface API.
```

## 10. Ce qui reste à décider au Lot 10

Points à fermer :

- `pathPatternPresets` doit-il être encodé même vide ?
- le champ doit-il être `@Default([])` ou requis avec helper JSON custom ?
- quels tests garantissent que les anciens manifests sans champ restent valides ?
- faut-il ajouter des helpers d'opérations manifest tout de suite ou dans un lot 11 ?
- où diagnostiquer `basePathPresetId` absent ?
- comment relier plus tard l'UI Path Studio aux `pathPresets` legacy ?

## 11. Tests lancés

### Test ciblé golden Lot 9

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

Ligne finale exacte :

```text
00:01 +1089: All tests passed!
```

## 12. Analyze

Commande :

```bash
cd packages/map_core && dart analyze test/project_path_pattern_preset_json_golden_test.dart
```

Sortie complète :

```text
Analyzing project_path_pattern_preset_json_golden_test.dart...
No issues found!
```

## 13. Non-objectifs confirmés

Confirmé :

- pas de modification `ProjectManifest` ;
- pas d'intégration manifest ;
- pas de migration JSON ;
- pas de fichiers generated ;
- pas de build_runner ;
- pas de Freezed ;
- pas de `toJson` / `fromJson` dans `ProjectPathPatternPreset` ;
- pas de modification `ProjectPathPreset` ;
- pas de modification `TerrainPathVariant` ;
- pas de modification `PathLayer` ;
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

Contrôle de couplage sur les fichiers Lot 9 :

```bash
rg -n "ProjectManifest|ProjectPathPreset\\b|TerrainPathVariant|PathLayer|map_runtime|map_gameplay|map_battle|build_runner|Freezed|freezed|TSX|TMX|Mistral|PixelLab|Widget|Flutter|tall grass|TallGrass" packages/map_core/test/project_path_pattern_preset_json_golden_test.dart packages/map_core/test/fixtures/path_pattern
```

Sortie complète :

```text
```

## 14. Limites restantes

- `ProjectPathPatternPreset` n'est pas encore intégré au manifest.
- Les golden JSON sont des fixtures de preset nu, pas de `project.json`.
- Aucun diagnostic ne vérifie encore que `basePathPresetId` existe.
- Aucun helper manifest n'existe encore pour lire/upsert/remove `pathPatternPresets`.
- Le test complet `map_editor` n'a pas été lancé, car ce lot ne modifie pas `map_editor`; les trois tests `test/path_pattern` demandés ont été lancés.

## 15. Git status final

Commande :

```bash
git status --short --untracked-files=all
```

Sortie complète finale :

```text
 M packages/map_core/lib/map_core.dart
?? packages/map_core/lib/src/operations/project_path_pattern_preset_json_codec.dart
?? packages/map_core/test/fixtures/path_pattern/project_path_pattern_preset_complete_2x2.json
?? packages/map_core/test/fixtures/path_pattern/project_path_pattern_preset_minimal_1x1.json
?? packages/map_core/test/project_path_pattern_preset_json_codec_test.dart
?? packages/map_core/test/project_path_pattern_preset_json_golden_test.dart
?? reports/pathPattern/path_pattern_lot_08_project_path_pattern_preset_json_codec.md
?? reports/pathPattern/path_pattern_lot_09_manifest_decision_golden_json.md
```

## 16. Prochain lot recommandé

Prochain lot recommandé :

```text
PathPattern-10 — ProjectManifest PathPattern Integration V0
```

Objectif recommandé :

- ajouter `pathPatternPresets: List<ProjectPathPatternPreset>` au manifest ;
- décoder absence/null comme liste vide si une stratégie JSON custom est retenue ;
- encoder de manière stable ;
- ne pas migrer automatiquement les anciens `pathPresets` ;
- ne pas toucher à l'UI, au painter, au runtime ou au gameplay.

## Evidence Pack

### Diff complet réel — fichiers Lot 9

Les fichiers Lot 9 sont des ajouts complets. Leur contenu intégral est donné dans les sections 5, 6 et 7 ci-dessus. Le diff réel de ces fichiers correspond à l'ajout de ces lignes depuis un fichier inexistant.

### Git diff stat final

Commande :

```bash
git diff --stat
```

Sortie :

```text
 packages/map_core/lib/map_core.dart | 1 +
 1 file changed, 1 insertion(+)
```

Note :

```text
git diff --stat ne liste pas les fichiers non suivis. Les fichiers ajoutés par les Lots 8 et 9 apparaissent dans git status.
```

## Auto-review

- Ai-je gardé `ProjectManifest` intact ? Oui.
- Ai-je évité generated/build_runner/Freezed ? Oui.
- Ai-je évité toJson/fromJson dans le modèle ? Oui.
- Ai-je créé des golden JSON stables ? Oui.
- Ai-je testé encode/decode/roundtrip ? Oui.
- Ai-je comparé les options manifest ? Oui, Options A/B/C/D.
- Ai-je évité UI/canvas/runtime/gameplay/battle ? Oui.
- Ai-je évité TSX/TMX ? Oui.
- Ai-je évité tall grass ? Oui.

## Critique du prompt

- Le prompt demande une décision manifest sans intégrer le manifest : j'ai donc recommandé l'Option A pour le Lot 10 sans modifier `ProjectManifest`.
- Les fixtures proposées correspondent au format réel actuel de `TilesetVisualFrame.toJson()`, avec `durationMs: null` explicitement présent.
- L'ordre des champs suit l'ordre du codec Lot 8 : `id`, `name`, `basePathPresetId`, `centerPattern`, optionnels, `sortOrder`.
- `sortOrder` reste obligatoire dans les fixtures et le codec, conformément au Lot 8.
- Avant intégration manifest, il faut valider si `pathPatternPresets` doit être encodé vide et comment traiter `null`.
