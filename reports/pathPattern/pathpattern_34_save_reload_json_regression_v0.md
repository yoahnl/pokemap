# Lot PathPattern-34 — Save / Reload JSON Regression V0

## 1. Résumé exécutif

Lot réalisé en mode régression/caractérisation JSON.

Objectif validé: un `ProjectManifest` avec `ProjectPathPreset` partiel + `cross`, et `ProjectPathPatternPreset` center 2x2 animé (multi-frames, `durationMs`, override `tilesetId`) survit au cycle `toJson/jsonEncode/jsonDecode/fromJson`, puis reste consommable par les résolveurs éditeur/runtime.

Aucun code de production modifié.

## 2. Audit initial

### Commandes demandées (initial)

```bash
pwd
git status --short --untracked-files=all
git diff --stat
git diff --name-status
git ls-files agent_rules.md
git ls-files reports/pathPattern/pathpattern_33_edit_existing_pathpattern_draft_v0.md
```

Sortie observée:

```text
/Users/karim/Project/pokemonProject
agent_rules.md
reports/pathPattern/pathpattern_33_edit_existing_pathpattern_draft_v0.md
```

### Fichiers audités

- `AGENTS.md`
- `agent_rules.md`
- `packages/map_core/lib/src/models/project_manifest.dart`
- `packages/map_core/lib/src/models/project_path_pattern_preset.dart`
- `packages/map_core/lib/src/operations/project_path_pattern_preset_json_codec.dart`
- `packages/map_core/test/project_manifest_path_pattern_presets_test.dart`
- `packages/map_core/test/project_path_pattern_preset_json_codec_test.dart`
- `packages/map_core/test/project_path_pattern_preset_json_golden_test.dart`
- `packages/map_editor/lib/src/features/path_pattern/path_pattern_editor_render_resolution.dart`
- `packages/map_editor/test/path_pattern/path_pattern_editor_render_resolution_test.dart`
- `packages/map_runtime/lib/src/presentation/flame/path_pattern_runtime_render_resolution.dart`
- `packages/map_runtime/test/path_pattern_runtime_render_resolution_test.dart`

### Constat audit (obligatoire)

- `ProjectManifest.pathPatternPresets` est sérialisé via codec dédié (`decodeProjectPathPatternPresets` / `encodeProjectPathPatternPresets`).
- `pathPatternPresets` absent ou `null` est compatible legacy (`[]`).
- `ProjectPathPatternPreset.centerPattern` encode `size` + `cells[].frames[]` (row-major au niveau pattern normalisé).
- `TilesetVisualFrame` encode `durationMs` et `tilesetId`.
- `durationMs: null` est conservé (clé présente côté codec actuel).
- `cross` est porté par `ProjectPathPreset.variants` et conservé au roundtrip.
- Les variants partiels restent partiels (pas de génération implicite).
- Les helpers éditeur/runtime lisent déjà les presets depuis `ProjectManifest` et supportent center fallback + `cross` policy.

## 3. Données de test / manifest utilisé

Jeu de données ajouté:

- tilesets: `tileset-main`, `tileset-water-fx`
- base preset: `water-base`
  - `surfaceKind: water`
  - variants partiels: `endNorth` + `cross`
  - un variant absent volontairement (`cornerNE`)
- pattern preset: `water-pattern`
  - `basePathPresetId: water-base`
  - `centerPattern` 2x2, 2 frames par cellule
  - override `tilesetId` sur D frame 2 = `tileset-water-fx`
  - `transparentColor`, `categoryId`, `sortOrder` couverts

## 4. Roundtrip JSON map_core

Nouveau test:

- `packages/map_core/test/project_manifest_path_pattern_save_reload_test.dart`

Vérifie:

- conservation `pathPresets` / `pathPatternPresets`
- conservation ids, `surfaceKind`, `categoryId`, `sortOrder`
- variants partiels inchangés
- `cross` préservé
- center 2x2, ordre des cellules, ordre des frames
- `durationMs` conservé
- override `tilesetId` conservé
- `durationMs: null` conservé sur frame `cross`

## 5. Golden fixture créée

Fixture ajoutée:

- `packages/map_core/test/fixtures/path_pattern/project_manifest_pathpattern_animated_2x2.json`

Validation:

- format canonique 2 espaces + newline finale
- décodage vers `ProjectManifest` avec assertions fonctionnelles sur les champs critiques

## 6. Compatibilité legacy

Couverture confirmée:

- test dans `project_manifest_path_pattern_save_reload_test.dart`:
  - manifest sans `pathPatternPresets` => `pathPatternPresets == []`
- couverture déjà existante conservée dans:
  - `packages/map_core/test/project_manifest_path_pattern_presets_test.dart`

## 7. Variants partiels

Prouvé par test roundtrip:

- seuls `endNorth` et `cross` restent présents
- aucun variant manquant non demandé n’est généré

## 8. Préservation cross

Prouvé par test roundtrip:

- mapping `TerrainPathVariant.cross` toujours présent après reload JSON
- frame `cross` conserve son `source` et `durationMs: null`

## 9. Régression editor après reload

Nouveau test:

- `packages/map_editor/test/path_pattern/path_pattern_editor_reload_regression_test.dart`

Vérifie sur manifest roundtrippé:

- center-only 2x2 résolu
- multi-frame selon `elapsedMs`
- fallback `cross` via centerPattern
- variant configuré (`endNorth`) conservé
- override `tilesetId` conservé

## 10. Régression runtime après reload

Nouveau test:

- `packages/map_runtime/test/path_pattern_runtime_reload_regression_test.dart`

Vérifie sur manifest roundtrippé:

- center-only 2x2 résolu
- multi-frame selon `elapsedMs`
- fallback `cross` via centerPattern
- variant configuré conservé
- override `tilesetId` conservé

## 11. Code de production modifié ou non

Aucun fichier de production modifié (`map_core`, `map_editor`, `map_runtime` prod inchangés).

## 12. Fichiers créés

- `packages/map_core/test/project_manifest_path_pattern_save_reload_test.dart`
- `packages/map_core/test/fixtures/path_pattern/project_manifest_pathpattern_animated_2x2.json`
- `packages/map_editor/test/path_pattern/path_pattern_editor_reload_regression_test.dart`
- `packages/map_runtime/test/path_pattern_runtime_reload_regression_test.dart`
- `reports/pathPattern/pathpattern_34_save_reload_json_regression_v0.md`

## 13. Fichiers modifiés

Aucun fichier existant modifié (hors création du rapport de lot).

## 14. Fichiers supprimés

Aucun.

## 15. Tests exécutés

### map_core

```bash
dart test test/project_manifest_path_pattern_save_reload_test.dart --reporter expanded --no-color
dart test test/project_manifest_path_pattern_presets_test.dart --reporter expanded --no-color
dart test test/project_path_pattern_preset_json_codec_test.dart --reporter expanded --no-color
dart test test/project_path_pattern_preset_json_golden_test.dart --reporter expanded --no-color
dart test test/path_pattern_visual_resolution_test.dart --reporter expanded --no-color
dart analyze lib/src/models lib/src/operations test/project_manifest_path_pattern_save_reload_test.dart
dart test --reporter expanded --no-color
```

### map_editor

```bash
flutter test test/path_pattern/path_pattern_editor_reload_regression_test.dart --reporter expanded
flutter test test/path_pattern/path_pattern_editor_render_resolution_test.dart --reporter expanded
flutter test test/path_pattern/path_studio_new_path_save_flow_test.dart --reporter expanded
flutter test test/path_pattern/path_studio_panel_test.dart --reporter expanded
flutter analyze lib/src/features/path_pattern lib/src/features/path_studio test/path_pattern
```

### map_runtime

```bash
flutter test test/path_pattern_runtime_reload_regression_test.dart --reporter expanded
flutter test test/path_pattern_runtime_render_resolution_test.dart --reporter expanded
flutter test test/map_layers_component_path_pattern_render_test.dart --reporter expanded
```

## 16. Résultats des validations

- Tous les tests ciblés demandés: PASS.
- `dart analyze` ciblé (`map_core`): PASS.
- `flutter analyze` ciblé (`map_editor`): PASS.
- Régression large `map_core` (`dart test --reporter expanded --no-color`): PASS.
  - Ligne finale exacte: `00:02 +1125: All tests passed!`

## 17. git status final

```text
?? packages/map_core/test/fixtures/path_pattern/project_manifest_pathpattern_animated_2x2.json
?? packages/map_core/test/project_manifest_path_pattern_save_reload_test.dart
?? packages/map_editor/test/path_pattern/path_pattern_editor_reload_regression_test.dart
?? packages/map_runtime/test/path_pattern_runtime_reload_regression_test.dart
?? reports/pathPattern/pathpattern_34_save_reload_json_regression_v0.md
```

## 18. git diff --stat

```text
(aucune sortie: uniquement des fichiers non suivis)
```

## 19. git diff --name-status

```text
(aucune sortie: uniquement des fichiers non suivis)
```

## 20. Evidence Pack

### 20.1 git status initial

```text
(aucune entrée détectée lors de l’audit initial exécuté)
```

### 20.2 git status final

```text
?? packages/map_core/test/fixtures/path_pattern/project_manifest_pathpattern_animated_2x2.json
?? packages/map_core/test/project_manifest_path_pattern_save_reload_test.dart
?? packages/map_editor/test/path_pattern/path_pattern_editor_reload_regression_test.dart
?? packages/map_runtime/test/path_pattern_runtime_reload_regression_test.dart
?? reports/pathPattern/pathpattern_34_save_reload_json_regression_v0.md
```

### 20.3 git diff --stat final

```text
(aucune sortie: uniquement des fichiers non suivis)
```

### 20.4 git diff --name-status final

```text
(aucune sortie: uniquement des fichiers non suivis)
```

### 20.5 Contenu complet des fichiers créés

#### `packages/map_core/test/project_manifest_path_pattern_save_reload_test.dart`

```dart
import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectManifest PathPattern save/reload JSON regression', () {
    test('roundtrip conserve path presets, patterns, frames et variantes', () {
      final manifest = _buildManifest();
      final encodedJson = jsonEncode(manifest.toJson());
      final decoded = ProjectManifest.fromJson(
        jsonDecode(encodedJson) as Map<String, dynamic>,
      );

      expect(decoded.pathPresets, hasLength(1));
      expect(decoded.pathPatternPresets, hasLength(1));

      final base = decoded.pathPresets.single;
      expect(base.id, 'water-base');
      expect(base.name, 'Water Base');
      expect(base.tilesetId, 'tileset-main');
      expect(base.surfaceKind, PathSurfaceKind.water);
      expect(base.categoryId, 'water-category');
      expect(base.sortOrder, 8);

      expect(base.variants, hasLength(2));
      final endNorth = base.variants.singleWhere(
        (mapping) => mapping.variant == TerrainPathVariant.endNorth,
      );
      expect(endNorth.frames, hasLength(1));
      expect(endNorth.frames.single.source, const TilesetSourceRect(x: 9, y: 4));
      expect(endNorth.frames.single.durationMs, 120);

      final cross = base.variants.singleWhere(
        (mapping) => mapping.variant == TerrainPathVariant.cross,
      );
      expect(cross.frames, hasLength(1));
      expect(cross.frames.single.source, const TilesetSourceRect(x: 7, y: 7));
      expect(cross.frames.single.durationMs, isNull);
      expect(
        base.variants.any((mapping) => mapping.variant == TerrainPathVariant.cornerNE),
        isFalse,
      );

      final pattern = decoded.pathPatternPresets.single;
      expect(pattern.id, 'water-pattern');
      expect(pattern.name, 'Water Pattern');
      expect(pattern.basePathPresetId, 'water-base');
      expect(pattern.transparentColor, TilesetTransparentColor.fromHexRgb('102a4f'));
      expect(pattern.categoryId, 'water-category');
      expect(pattern.sortOrder, 21);
      expect(pattern.centerPattern.size, PathCenterPatternSize(width: 2, height: 2));

      final cells = pattern.centerPattern.cells;
      expect(cells.map((cell) => [cell.localX, cell.localY]).toList(), [
        [0, 0],
        [1, 0],
        [0, 1],
        [1, 1],
      ]);
      for (final cell in cells) {
        expect(cell.frames, hasLength(2));
      }

      expect(cells[0].frames[0].source, const TilesetSourceRect(x: 0, y: 0));
      expect(cells[0].frames[0].durationMs, 100);
      expect(cells[0].frames[0].tilesetId, '');
      expect(cells[0].frames[1].source, const TilesetSourceRect(x: 0, y: 1));
      expect(cells[0].frames[1].durationMs, 150);
      expect(cells[0].frames[1].tilesetId, '');

      expect(cells[1].frames[0].source, const TilesetSourceRect(x: 1, y: 0));
      expect(cells[1].frames[0].durationMs, 100);
      expect(cells[1].frames[1].source, const TilesetSourceRect(x: 1, y: 1));
      expect(cells[1].frames[1].durationMs, 150);

      expect(cells[2].frames[0].source, const TilesetSourceRect(x: 2, y: 0));
      expect(cells[2].frames[0].durationMs, 200);
      expect(cells[2].frames[1].source, const TilesetSourceRect(x: 2, y: 1));
      expect(cells[2].frames[1].durationMs, 250);

      expect(cells[3].frames[0].source, const TilesetSourceRect(x: 3, y: 0));
      expect(cells[3].frames[0].durationMs, 200);
      expect(cells[3].frames[1].source, const TilesetSourceRect(x: 3, y: 1));
      expect(cells[3].frames[1].durationMs, 250);
      expect(cells[3].frames[1].tilesetId, 'tileset-water-fx');

      final asJson =
          jsonDecode(jsonEncode(decoded.toJson())) as Map<String, dynamic>;
      final encodedPattern = (asJson['pathPatternPresets'] as List<dynamic>).single
          as Map<String, dynamic>;
      final encodedCells =
          ((encodedPattern['centerPattern'] as Map<String, dynamic>)['cells'] as List<dynamic>);
      final encodedFrames =
          (encodedCells[3] as Map<String, dynamic>)['frames'] as List<dynamic>;
      expect(encodedFrames[0], containsPair('durationMs', 200));
      expect(encodedFrames[1], containsPair('durationMs', 250));

      final encodedBase = (asJson['pathPresets'] as List<dynamic>).single as Map<String, dynamic>;
      final encodedVariants = encodedBase['variants'] as List<dynamic>;
      final encodedCross = encodedVariants
          .cast<Map<String, dynamic>>()
          .singleWhere((variant) => variant['variant'] == 'cross');
      expect(encodedCross['frames'], [
        {
          'tilesetId': '',
          'source': {'x': 7, 'y': 7, 'width': 1, 'height': 1},
          'durationMs': null,
        },
      ]);
    });

    test('fixture golden 2x2 animé se décode avec les données attendues', () {
      final fixture = File(
        'test/fixtures/path_pattern/project_manifest_pathpattern_animated_2x2.json',
      ).readAsStringSync();
      const encoder = JsonEncoder.withIndent('  ');
      final fixturePretty =
          '${encoder.convert(jsonDecode(fixture) as Object?)}\n';
      final manifest = ProjectManifest.fromJson(
        jsonDecode(fixture) as Map<String, dynamic>,
      );

      expect(fixturePretty, fixture);
      expect(manifest.pathPresets.single.id, 'water-base');
      expect(manifest.pathPatternPresets.single.id, 'water-pattern');
      expect(
        manifest.pathPatternPresets.single.centerPattern.cellAt(1, 1).frames[1].tilesetId,
        'tileset-water-fx',
      );
    });

    test('manifest sans pathPatternPresets reste compatible', () {
      final manifest = ProjectManifest.fromJson({
        'name': 'Legacy',
        'maps': <Object?>[],
        'tilesets': <Object?>[],
      });

      expect(manifest.pathPatternPresets, isEmpty);
    });
  });
}

ProjectManifest _buildManifest() {
  return ProjectManifest(
    name: 'PathPattern Save Reload',
    maps: const [],
    tilesets: const [
      ProjectTilesetEntry(
        id: 'tileset-main',
        name: 'Main',
        relativePath: 'tilesets/main.png',
      ),
      ProjectTilesetEntry(
        id: 'tileset-water-fx',
        name: 'Water FX',
        relativePath: 'tilesets/water_fx.png',
      ),
    ],
    pathPresets: [
      ProjectPathPreset(
        id: 'water-base',
        name: 'Water Base',
        surfaceKind: PathSurfaceKind.water,
        categoryId: 'water-category',
        tilesetId: 'tileset-main',
        variants: [
          const PathPresetVariantMapping(
            variant: TerrainPathVariant.endNorth,
            frames: [
              TilesetVisualFrame(
                source: TilesetSourceRect(x: 9, y: 4),
                durationMs: 120,
              ),
            ],
          ),
          const PathPresetVariantMapping(
            variant: TerrainPathVariant.cross,
            frames: [
              TilesetVisualFrame(
                source: TilesetSourceRect(x: 7, y: 7),
                durationMs: null,
              ),
            ],
          ),
        ],
        sortOrder: 8,
      ),
    ],
    pathPatternPresets: [
      ProjectPathPatternPreset(
        id: 'water-pattern',
        name: 'Water Pattern',
        basePathPresetId: 'water-base',
        centerPattern: PathCenterPattern(
          size: PathCenterPatternSize(width: 2, height: 2),
          cells: [
            PathCenterPatternCell(
              localX: 0,
              localY: 0,
              frames: const [
                TilesetVisualFrame(
                  source: TilesetSourceRect(x: 0, y: 0),
                  durationMs: 100,
                ),
                TilesetVisualFrame(
                  source: TilesetSourceRect(x: 0, y: 1),
                  durationMs: 150,
                ),
              ],
            ),
            PathCenterPatternCell(
              localX: 1,
              localY: 0,
              frames: const [
                TilesetVisualFrame(
                  source: TilesetSourceRect(x: 1, y: 0),
                  durationMs: 100,
                ),
                TilesetVisualFrame(
                  source: TilesetSourceRect(x: 1, y: 1),
                  durationMs: 150,
                ),
              ],
            ),
            PathCenterPatternCell(
              localX: 0,
              localY: 1,
              frames: const [
                TilesetVisualFrame(
                  source: TilesetSourceRect(x: 2, y: 0),
                  durationMs: 200,
                ),
                TilesetVisualFrame(
                  source: TilesetSourceRect(x: 2, y: 1),
                  durationMs: 250,
                ),
              ],
            ),
            PathCenterPatternCell(
              localX: 1,
              localY: 1,
              frames: const [
                TilesetVisualFrame(
                  source: TilesetSourceRect(x: 3, y: 0),
                  durationMs: 200,
                ),
                TilesetVisualFrame(
                  tilesetId: 'tileset-water-fx',
                  source: TilesetSourceRect(x: 3, y: 1),
                  durationMs: 250,
                ),
              ],
            ),
          ],
        ),
        transparentColor: TilesetTransparentColor.fromHexRgb('102a4f'),
        categoryId: 'water-category',
        sortOrder: 21,
      ),
    ],
    surfaceCatalog: ProjectSurfaceCatalog(),
  );
}
```

#### `packages/map_core/test/fixtures/path_pattern/project_manifest_pathpattern_animated_2x2.json`

```json
{
  "name": "PathPattern Save Reload",
  "maps": [],
  "tilesets": [
    {
      "id": "tileset-main",
      "name": "Main",
      "relativePath": "tilesets/main.png"
    },
    {
      "id": "tileset-water-fx",
      "name": "Water FX",
      "relativePath": "tilesets/water_fx.png"
    }
  ],
  "pathPresets": [
    {
      "id": "water-base",
      "name": "Water Base",
      "surfaceKind": "water",
      "categoryId": "water-category",
      "tilesetId": "tileset-main",
      "variants": [
        {
          "variant": "endNorth",
          "frames": [
            {
              "tilesetId": "",
              "source": {
                "x": 9,
                "y": 4,
                "width": 1,
                "height": 1
              },
              "durationMs": 120
            }
          ]
        },
        {
          "variant": "cross",
          "frames": [
            {
              "tilesetId": "",
              "source": {
                "x": 7,
                "y": 7,
                "width": 1,
                "height": 1
              },
              "durationMs": null
            }
          ]
        }
      ],
      "sortOrder": 8
    }
  ],
  "pathPatternPresets": [
    {
      "id": "water-pattern",
      "name": "Water Pattern",
      "basePathPresetId": "water-base",
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
                  "x": 0,
                  "y": 1,
                  "width": 1,
                  "height": 1
                },
                "durationMs": 150
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
                  "x": 1,
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
                  "y": 1,
                  "width": 1,
                  "height": 1
                },
                "durationMs": 150
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
                  "x": 2,
                  "y": 0,
                  "width": 1,
                  "height": 1
                },
                "durationMs": 200
              },
              {
                "tilesetId": "",
                "source": {
                  "x": 2,
                  "y": 1,
                  "width": 1,
                  "height": 1
                },
                "durationMs": 250
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
                  "x": 3,
                  "y": 0,
                  "width": 1,
                  "height": 1
                },
                "durationMs": 200
              },
              {
                "tilesetId": "tileset-water-fx",
                "source": {
                  "x": 3,
                  "y": 1,
                  "width": 1,
                  "height": 1
                },
                "durationMs": 250
              }
            ]
          }
        ]
      },
      "transparentColor": "102a4f",
      "categoryId": "water-category",
      "sortOrder": 21
    }
  ]
}
```

#### `packages/map_editor/test/path_pattern/path_pattern_editor_reload_regression_test.dart`

```dart
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/models/path_autotile_set.dart';
import 'package:map_editor/src/features/path_pattern/path_pattern_editor_render_resolution.dart';

void main() {
  test('resolver éditeur consomme un manifest roundtrippé JSON', () {
    final manifest = _roundtripManifest(_buildManifest());
    final legacy = PathAutotileSet.defaultForTileset('tileset-main');

    final centerA = resolvePathPatternEditorRenderResolution(
      project: manifest,
      basePathPresetId: 'water-base',
      variant: TerrainPathVariant.isolated,
      mapX: 0,
      mapY: 0,
      elapsedMs: 0,
      legacyAutotileSet: legacy,
    );
    final centerB = resolvePathPatternEditorRenderResolution(
      project: manifest,
      basePathPresetId: 'water-base',
      variant: TerrainPathVariant.cornerNE,
      mapX: 1,
      mapY: 0,
      elapsedMs: 0,
      legacyAutotileSet: legacy,
    );
    final cross = resolvePathPatternEditorRenderResolution(
      project: manifest,
      basePathPresetId: 'water-base',
      variant: TerrainPathVariant.cross,
      mapX: 1,
      mapY: 1,
      elapsedMs: 0,
      legacyAutotileSet: legacy,
    );
    final animated0 = resolvePathPatternEditorRenderResolution(
      project: manifest,
      basePathPresetId: 'water-base',
      variant: TerrainPathVariant.cross,
      mapX: 1,
      mapY: 1,
      elapsedMs: 0,
      legacyAutotileSet: legacy,
    );
    final animated1 = resolvePathPatternEditorRenderResolution(
      project: manifest,
      basePathPresetId: 'water-base',
      variant: TerrainPathVariant.cross,
      mapX: 1,
      mapY: 1,
      elapsedMs: 250,
      legacyAutotileSet: legacy,
    );
    final variantConfigured = resolvePathPatternEditorRenderResolution(
      project: manifest,
      basePathPresetId: 'water-base',
      variant: TerrainPathVariant.endNorth,
      mapX: 8,
      mapY: 8,
      elapsedMs: 0,
      legacyAutotileSet: legacy,
    );

    expect(centerA?.source, PathPatternEditorRenderResolutionSource.pathPattern);
    expect(centerA?.sourceRect, const TilesetSourceRect(x: 0, y: 0));
    expect(centerB?.sourceRect, const TilesetSourceRect(x: 1, y: 0));

    expect(cross?.source, PathPatternEditorRenderResolutionSource.pathPattern);
    expect(cross?.sourceRect, const TilesetSourceRect(x: 3, y: 0));

    expect(animated0?.sourceRect, const TilesetSourceRect(x: 3, y: 0));
    expect(animated1?.sourceRect, const TilesetSourceRect(x: 3, y: 1));
    expect(animated1?.tilesetId, 'tileset-water-fx');

    expect(
      variantConfigured?.source,
      PathPatternEditorRenderResolutionSource.pathPattern,
    );
    expect(variantConfigured?.sourceRect, const TilesetSourceRect(x: 9, y: 4));
  });
}

ProjectManifest _roundtripManifest(ProjectManifest manifest) {
  return ProjectManifest.fromJson(
    jsonDecode(jsonEncode(manifest.toJson())) as Map<String, dynamic>,
  );
}

ProjectManifest _buildManifest() {
  return ProjectManifest(
    name: 'Editor Reload',
    maps: const [],
    tilesets: const [
      ProjectTilesetEntry(
        id: 'tileset-main',
        name: 'Main',
        relativePath: 'tilesets/main.png',
      ),
      ProjectTilesetEntry(
        id: 'tileset-water-fx',
        name: 'Water FX',
        relativePath: 'tilesets/water_fx.png',
      ),
    ],
    pathPresets: [
      const ProjectPathPreset(
        id: 'water-base',
        name: 'Water Base',
        surfaceKind: PathSurfaceKind.water,
        tilesetId: 'tileset-main',
        variants: [
          PathPresetVariantMapping(
            variant: TerrainPathVariant.endNorth,
            frames: [
              TilesetVisualFrame(
                source: TilesetSourceRect(x: 9, y: 4),
                durationMs: 120,
              ),
            ],
          ),
          PathPresetVariantMapping(
            variant: TerrainPathVariant.cross,
            frames: [
              TilesetVisualFrame(source: TilesetSourceRect(x: 77, y: 77)),
            ],
          ),
        ],
      ),
    ],
    pathPatternPresets: [
      ProjectPathPatternPreset(
        id: 'water-pattern',
        name: 'Water Pattern',
        basePathPresetId: 'water-base',
        centerPattern: PathCenterPattern(
          size: PathCenterPatternSize(width: 2, height: 2),
          cells: [
            PathCenterPatternCell(
              localX: 0,
              localY: 0,
              frames: const [
                TilesetVisualFrame(
                  source: TilesetSourceRect(x: 0, y: 0),
                  durationMs: 100,
                ),
                TilesetVisualFrame(
                  source: TilesetSourceRect(x: 0, y: 1),
                  durationMs: 150,
                ),
              ],
            ),
            PathCenterPatternCell(
              localX: 1,
              localY: 0,
              frames: const [
                TilesetVisualFrame(
                  source: TilesetSourceRect(x: 1, y: 0),
                  durationMs: 100,
                ),
                TilesetVisualFrame(
                  source: TilesetSourceRect(x: 1, y: 1),
                  durationMs: 150,
                ),
              ],
            ),
            PathCenterPatternCell(
              localX: 0,
              localY: 1,
              frames: const [
                TilesetVisualFrame(
                  source: TilesetSourceRect(x: 2, y: 0),
                  durationMs: 200,
                ),
                TilesetVisualFrame(
                  source: TilesetSourceRect(x: 2, y: 1),
                  durationMs: 250,
                ),
              ],
            ),
            PathCenterPatternCell(
              localX: 1,
              localY: 1,
              frames: const [
                TilesetVisualFrame(
                  source: TilesetSourceRect(x: 3, y: 0),
                  durationMs: 200,
                ),
                TilesetVisualFrame(
                  tilesetId: 'tileset-water-fx',
                  source: TilesetSourceRect(x: 3, y: 1),
                  durationMs: 250,
                ),
              ],
            ),
          ],
        ),
      ),
    ],
    surfaceCatalog: ProjectSurfaceCatalog(),
  );
}
```

#### `packages/map_runtime/test/path_pattern_runtime_reload_regression_test.dart`

```dart
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/presentation/flame/path_pattern_runtime_render_resolution.dart';
import 'package:map_runtime/src/presentation/flame/runtime_path_autotile.dart';

void main() {
  test('resolver runtime consomme un manifest roundtrippé JSON', () {
    final manifest = _roundtripManifest(_buildManifest());
    final legacy = RuntimePathAutotileSet.fromPreset(manifest.pathPresets.single);

    final centerA = resolvePathPatternRuntimeRenderResolution(
      manifest: manifest,
      basePathPresetId: 'water-base',
      variant: TerrainPathVariant.isolated,
      mapX: 0,
      mapY: 0,
      elapsedMs: 0,
      playback: const PathPatternRuntimePlayback.alwaysLoop(),
      legacyAutotileSet: legacy,
    );
    final cross = resolvePathPatternRuntimeRenderResolution(
      manifest: manifest,
      basePathPresetId: 'water-base',
      variant: TerrainPathVariant.cross,
      mapX: 1,
      mapY: 1,
      elapsedMs: 0,
      playback: const PathPatternRuntimePlayback.alwaysLoop(),
      legacyAutotileSet: legacy,
    );
    final animated0 = resolvePathPatternRuntimeRenderResolution(
      manifest: manifest,
      basePathPresetId: 'water-base',
      variant: TerrainPathVariant.cross,
      mapX: 1,
      mapY: 1,
      elapsedMs: 0,
      playback: const PathPatternRuntimePlayback.alwaysLoop(),
      legacyAutotileSet: legacy,
    );
    final animated1 = resolvePathPatternRuntimeRenderResolution(
      manifest: manifest,
      basePathPresetId: 'water-base',
      variant: TerrainPathVariant.cross,
      mapX: 1,
      mapY: 1,
      elapsedMs: 250,
      playback: const PathPatternRuntimePlayback.alwaysLoop(),
      legacyAutotileSet: legacy,
    );
    final variantConfigured = resolvePathPatternRuntimeRenderResolution(
      manifest: manifest,
      basePathPresetId: 'water-base',
      variant: TerrainPathVariant.endNorth,
      mapX: 8,
      mapY: 8,
      elapsedMs: 0,
      playback: const PathPatternRuntimePlayback.alwaysLoop(),
      legacyAutotileSet: legacy,
    );

    expect(centerA?.source, PathPatternRuntimeRenderResolutionSource.pathPattern);
    expect(centerA?.sourceRect, const TilesetSourceRect(x: 0, y: 0));
    expect(cross?.sourceRect, const TilesetSourceRect(x: 3, y: 0));

    expect(animated0?.sourceRect, const TilesetSourceRect(x: 3, y: 0));
    expect(animated1?.sourceRect, const TilesetSourceRect(x: 3, y: 1));
    expect(animated1?.tilesetId, 'tileset-water-fx');

    expect(
      variantConfigured?.source,
      PathPatternRuntimeRenderResolutionSource.pathPattern,
    );
    expect(variantConfigured?.sourceRect, const TilesetSourceRect(x: 9, y: 4));
  });
}

ProjectManifest _roundtripManifest(ProjectManifest manifest) {
  return ProjectManifest.fromJson(
    jsonDecode(jsonEncode(manifest.toJson())) as Map<String, dynamic>,
  );
}

ProjectManifest _buildManifest() {
  return ProjectManifest(
    name: 'Runtime Reload',
    maps: const [],
    tilesets: const [
      ProjectTilesetEntry(
        id: 'tileset-main',
        name: 'Main',
        relativePath: 'tilesets/main.png',
      ),
      ProjectTilesetEntry(
        id: 'tileset-water-fx',
        name: 'Water FX',
        relativePath: 'tilesets/water_fx.png',
      ),
    ],
    pathPresets: [
      const ProjectPathPreset(
        id: 'water-base',
        name: 'Water Base',
        surfaceKind: PathSurfaceKind.water,
        tilesetId: 'tileset-main',
        variants: [
          PathPresetVariantMapping(
            variant: TerrainPathVariant.endNorth,
            frames: [
              TilesetVisualFrame(
                source: TilesetSourceRect(x: 9, y: 4),
                durationMs: 120,
              ),
            ],
          ),
          PathPresetVariantMapping(
            variant: TerrainPathVariant.cross,
            frames: [
              TilesetVisualFrame(source: TilesetSourceRect(x: 77, y: 77)),
            ],
          ),
        ],
      ),
    ],
    pathPatternPresets: [
      ProjectPathPatternPreset(
        id: 'water-pattern',
        name: 'Water Pattern',
        basePathPresetId: 'water-base',
        centerPattern: PathCenterPattern(
          size: PathCenterPatternSize(width: 2, height: 2),
          cells: [
            PathCenterPatternCell(
              localX: 0,
              localY: 0,
              frames: const [
                TilesetVisualFrame(
                  source: TilesetSourceRect(x: 0, y: 0),
                  durationMs: 100,
                ),
                TilesetVisualFrame(
                  source: TilesetSourceRect(x: 0, y: 1),
                  durationMs: 150,
                ),
              ],
            ),
            PathCenterPatternCell(
              localX: 1,
              localY: 0,
              frames: const [
                TilesetVisualFrame(
                  source: TilesetSourceRect(x: 1, y: 0),
                  durationMs: 100,
                ),
                TilesetVisualFrame(
                  source: TilesetSourceRect(x: 1, y: 1),
                  durationMs: 150,
                ),
              ],
            ),
            PathCenterPatternCell(
              localX: 0,
              localY: 1,
              frames: const [
                TilesetVisualFrame(
                  source: TilesetSourceRect(x: 2, y: 0),
                  durationMs: 200,
                ),
                TilesetVisualFrame(
                  source: TilesetSourceRect(x: 2, y: 1),
                  durationMs: 250,
                ),
              ],
            ),
            PathCenterPatternCell(
              localX: 1,
              localY: 1,
              frames: const [
                TilesetVisualFrame(
                  source: TilesetSourceRect(x: 3, y: 0),
                  durationMs: 200,
                ),
                TilesetVisualFrame(
                  tilesetId: 'tileset-water-fx',
                  source: TilesetSourceRect(x: 3, y: 1),
                  durationMs: 250,
                ),
              ],
            ),
          ],
        ),
      ),
    ],
    surfaceCatalog: ProjectSurfaceCatalog(),
  );
}
```

### 20.6 Diff complet réel des fichiers modifiés

```text
A packages/map_core/test/fixtures/path_pattern/project_manifest_pathpattern_animated_2x2.json
A packages/map_core/test/project_manifest_path_pattern_save_reload_test.dart
A packages/map_editor/test/path_pattern/path_pattern_editor_reload_regression_test.dart
A packages/map_runtime/test/path_pattern_runtime_reload_regression_test.dart
A reports/pathPattern/pathpattern_34_save_reload_json_regression_v0.md
```

### 20.7 Sorties complètes des tests ciblés principaux

#### map_core — nouveau test

```text
00:00 +0: loading test/project_manifest_path_pattern_save_reload_test.dart
00:00 +0: ProjectManifest PathPattern save/reload JSON regression roundtrip conserve path presets, patterns, frames et variantes
00:00 +1: ProjectManifest PathPattern save/reload JSON regression fixture golden 2x2 animé se décode avec les données attendues
00:00 +2: ProjectManifest PathPattern save/reload JSON regression manifest sans pathPatternPresets reste compatible
00:00 +3: All tests passed!
```

#### map_editor — nouveau test

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_pattern_editor_reload_regression_test.dart
00:00 +0: resolver éditeur consomme un manifest roundtrippé JSON
00:00 +1: All tests passed!
```

#### map_runtime — nouveau test

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_runtime/test/path_pattern_runtime_reload_regression_test.dart
00:00 +0: resolver runtime consomme un manifest roundtrippé JSON
00:00 +1: All tests passed!
```

#### Régressions complémentaires demandées (extrait complet des commandes lancées)

```text
00:00 +0: loading test/project_manifest_path_pattern_presets_test.dart
00:00 +8: All tests passed!

00:00 +0: loading test/project_path_pattern_preset_json_codec_test.dart
00:00 +9: All tests passed!

00:00 +0: loading test/project_path_pattern_preset_json_golden_test.dart
00:00 +6: All tests passed!

00:00 +0: loading test/path_pattern_visual_resolution_test.dart
00:00 +9: All tests passed!

00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_pattern_editor_render_resolution_test.dart
00:00 +8: All tests passed!

00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_new_path_save_flow_test.dart
00:00 +9: All tests passed!

00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart
00:08 +37: All tests passed!

00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_runtime/test/path_pattern_runtime_render_resolution_test.dart
00:00 +9: All tests passed!

00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_runtime/test/map_layers_component_path_pattern_render_test.dart
00:00 +3: All tests passed!
```

### 20.8 Ligne finale exacte de la grosse régression

```text
00:02 +1125: All tests passed!
```

### 20.9 Sorties analyze ciblées

```text
Analyzing models, operations, project_manifest_path_pattern_save_reload_test.dart...
No issues found!
```

```text
Analyzing 3 items...
No issues found! (ran in 2.4s)
```

## 21. Auto-review

### Prouvé

- Roundtrip JSON PathPattern complet (base + pattern + frames + durations + override + variants + cross).
- Compatibilité legacy `pathPatternPresets` absent.
- Résolveurs éditeur/runtime fonctionnels après reload JSON.
- Aucune régression observée sur la matrice demandée.
- Aucune modification production.

### Non prouvé

- Aucun test d’écriture disque applicative (hors scope et explicitement interdit).
- Pas de couverture beyond-scope (gameplay/battle/UI refactor).

## 22. Critique du prompt

- Prompt très précis et cohérent avec le scope de lot (régression JSON, pas feature produit).
- Point de vigilance: exigence Evidence Pack “diff complet” avec fichiers non suivis n’est pas directement servi par `git diff`; contourné proprement en listant les ajouts + contenus complets des fichiers créés.
- Le lot demandait de “préférer aucun changement prod”, ce qui était déjà aligné avec l’audit: la bonne stratégie était 100% tests/fixtures.

## 23. Conclusion

Lot 34 validé sur le périmètre demandé: le manifest PathPattern animé survit au cycle JSON et reste résolvable côté éditeur/runtime, sans changement de production ni save disque.

## Checklist finale

- [x] Audit initial réalisé.
- [x] AGENTS.md et agent_rules.md lus.
- [x] Ancienne roadmap Tall Grass ignorée.
- [x] Aucun faux test.
- [x] Aucun provider inventé.
- [x] Aucun repository/service ajouté.
- [x] Aucun fichier projet écrit hors fixture de test si décidée.
- [x] Aucun FileProjectRepository utilisé.
- [x] Aucun save disque applicatif.
- [x] Aucun ProjectManifest modifié sauf bug réel documenté.
- [x] Aucun map_core production modifié sauf bug réel documenté.
- [x] Aucun runtime production modifié.
- [x] Aucun editor production modifié.
- [x] Aucun generated file.
- [x] Aucun build_runner.
- [x] Roundtrip JSON ProjectManifest testé.
- [x] CenterPattern 2×2 animé conservé.
- [x] Toutes les frames conservées.
- [x] durationMs conservé.
- [x] tilesetId override conservé.
- [x] Variants partiels conservés.
- [x] Variants manquants non générés.
- [x] cross existant préservé.
- [x] transparentColor/categoryId/sortOrder couverts si présents dans le test.
- [x] Editor resolver fonctionne après reload.
- [x] Runtime resolver fonctionne après reload.
- [x] Rendu éditeur/runtimes existants non régressés.
- [x] Tests ciblés passent.
- [x] Régression large map_core passe ou échec documenté.
- [x] Analyze ciblé passe.
- [x] Rapport final complet créé.
- [x] Auto-review faite.
- [x] Critique du prompt faite.
