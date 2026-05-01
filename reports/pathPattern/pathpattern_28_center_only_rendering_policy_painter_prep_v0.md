# Lot PathPattern-28 — Center-only Rendering Policy / Painter Prep V0

## 1. Résumé exécutif

Ce lot implémente une opération pure de résolution visuelle `PathPattern` dans `map_core`, utilisable plus tard par painter editor/runtime sans toucher au painter lui-même.  
La politique center-only est maintenant explicite et testée: `centerPattern` est utilisé pour `cross`, pour tout variant manquant, pour mapping vide, et pour les presets sans variants legacy.

## 2. Audit initial

### Commandes exécutées avant modification

```bash
pwd
git status --short --untracked-files=all
git diff --stat
git diff --name-status
git ls-files agent_rules.md
git ls-files reports/pathPattern/pathpattern_27_new_path_save_flow_v0.md
```

### Sortie exacte

```text
/Users/karim/Project/pokemonProject
agent_rules.md
reports/pathPattern/pathpattern_27_new_path_save_flow_v0.md
```

### Fichiers inspectés (scope demandé)

- `AGENTS.md`
- `agent_rules.md`
- `packages/map_core/lib/src/models/path_center_pattern.dart`
- `packages/map_core/lib/src/operations/path_center_pattern_resolver.dart`
- `packages/map_core/lib/src/models/project_manifest.dart`
- `packages/map_core/lib/src/models/project_path_pattern_preset.dart`
- `packages/map_core/lib/src/models/enums.dart`
- `packages/map_core/lib/src/operations/project_path_preset_center_pattern_adapter.dart`
- `packages/map_editor/lib/src/features/path_studio/path_studio_new_path_build_request.dart`
- `packages/map_editor/lib/src/features/path_studio/path_studio_save_flow.dart`
- `packages/map_editor/test/path_pattern/path_studio_new_path_save_flow_test.dart`
- `packages/map_core/test/path_center_pattern_resolver_test.dart`
- `packages/map_core/lib/map_core.dart`

### Établissement demandé (état réel avant modif)

- `PathCenterPattern` est résolu par `resolvePathCenterPatternCell(...)` avec `localX = mapX % width` et `localY = mapY % height`, et rejet des coordonnées négatives via `ArgumentError`.
- `TerrainPathVariant` est défini dans `enums.dart` avec variantes legacy (`end*`, `corner*`, `tee*`, etc.) et `cross`.
- `ProjectPathPreset` stocke les mappings via `variants: List<PathPresetVariantMapping>`.
- `PathPresetVariantMapping` contient `variant` + `frames: List<TilesetVisualFrame>`.
- `ProjectPathPatternPreset` référence son preset legacy par `basePathPresetId`.
- Un helper de lookup variant existe déjà localement dans `project_path_preset_center_pattern_adapter.dart` (`_findVariantMapping` privé), mais rien de canonique exporté pour la future résolution painter.
- Les frames legacy et center sont représentées par `TilesetVisualFrame` (ordre, `durationMs`, `tilesetId` override portés par le modèle).
- Un variant manquant s’identifie par absence de mapping dans `basePathPreset.variants`; un mapping vide est possible (pas de garde stricte dans le modèle Freezed).
- L’emplacement correct pour une opération pure partagée editor/runtime est `packages/map_core/lib/src/operations/`.

## 3. Décision center-only

Décision appliquée:

- `PathPattern` peut fonctionner en center-only.
- `resolvedVariant == cross` force `centerPattern`.
- variant legacy présent et non vide: utilisé.
- variant legacy absent ou vide: fallback `centerPattern`.
- aucun fallback persistant n’est écrit dans les modèles.

## 4. Politique de résolution

Nouvelle API pure:

- `resolvePathPatternVisual(...)`
- entrée: `ProjectPathPatternPreset`, `ProjectPathPreset`, `TerrainPathVariant`, `mapX`, `mapY`
- sortie: `PathPatternVisualResolution`

Sortie structurée:

- kind: `centerPattern` ou `legacyVariant`
- variant résolu demandé
- coordonnées map
- coordonnées locales center (`centerLocalX/Y`) quand center
- `frames` immuable

## 5. Traitement TerrainPathVariant.cross

Règle implémentée et testée:

- `cross` ignore même un mapping legacy présent.
- rendu via `centerPattern`.

## 6. Traitement variants manquants

Règles implémentées et testées:

- mapping absent -> fallback center.
- mapping présent mais `frames.isEmpty` -> fallback center.
- aucun mapping synthétique généré.

## 7. API créée

- `packages/map_core/lib/src/operations/path_pattern_visual_resolution.dart`
  - `PathPatternVisualResolutionKind`
  - `PathPatternVisualResolution`
  - `resolvePathPatternVisual(...)`
- export public ajouté:
  - `packages/map_core/lib/map_core.dart`
  - `export 'src/operations/path_pattern_visual_resolution.dart';`

## 8. Tests ajoutés

- `packages/map_core/test/path_pattern_visual_resolution_test.dart`
  - center-only 1x1
  - répétition 2x2 A/B/C/D
  - priorité variant configuré
  - fallback variant manquant
  - `cross` toujours center
  - conservation ordre/duration/tileset override center
  - conservation ordre/duration/tileset override legacy
  - coordonnées négatives rejetées
  - mapping vide fallback center

## 9. Fichiers créés

- `packages/map_core/lib/src/operations/path_pattern_visual_resolution.dart`
- `packages/map_core/test/path_pattern_visual_resolution_test.dart`
- `reports/pathPattern/pathpattern_28_center_only_rendering_policy_painter_prep_v0.md`

## 10. Fichiers modifiés

- `packages/map_core/lib/map_core.dart`

## 11. Fichiers supprimés

- Aucun.

## 12. Comportements préservés

- `resolvePathCenterPatternCell(...)` inchangé.
- `ProjectManifest` inchangé.
- codecs inchangés.
- flows PathStudio / save in-memory lot 27 inchangés.
- aucun painter/runtime/gameplay/battle touché.

## 13. Tests exécutés

### `packages/map_core`

```bash
dart test test/path_pattern_visual_resolution_test.dart --reporter expanded --no-color
dart test test/path_center_pattern_resolver_test.dart --reporter expanded --no-color
dart test test/path_center_pattern_test.dart --reporter expanded --no-color
dart test test/project_path_pattern_preset_test.dart --reporter expanded --no-color
dart test test/project_manifest_path_pattern_preset_operations_test.dart --reporter expanded --no-color
dart test test/project_manifest_path_pattern_presets_test.dart --reporter expanded --no-color
dart test test/project_path_pattern_preset_json_codec_test.dart --reporter expanded --no-color
dart test test/project_path_pattern_preset_json_golden_test.dart --reporter expanded --no-color
dart analyze lib/src/operations lib/src/models test/path_pattern_visual_resolution_test.dart
dart test --reporter expanded --no-color
```

### `packages/map_editor` (régression minimale demandée)

```bash
flutter test test/path_pattern/path_studio_new_path_save_flow_test.dart --reporter expanded
flutter test test/path_pattern/path_studio_panel_test.dart --reporter expanded
flutter test test/path_pattern/path_studio_new_path_build_request_test.dart --reporter expanded
flutter analyze lib/src/features/path_studio test/path_pattern
```

## 14. Résultats des validations

- Tous les tests ciblés exécutés ci-dessus passent.
- `dart analyze ...` ciblé (map_core) passe.
- `flutter analyze ...` ciblé (map_editor path_pattern) passe.
- Régression large `dart test --reporter expanded --no-color` dans `packages/map_core` passe (`All tests passed!`).

## 15. git status final

```bash
git status --short --untracked-files=all
```

```text
 M packages/map_core/lib/map_core.dart
?? packages/map_core/lib/src/operations/path_pattern_visual_resolution.dart
?? packages/map_core/test/path_pattern_visual_resolution_test.dart
?? reports/pathPattern/pathpattern_28_center_only_rendering_policy_painter_prep_v0.md
```

## 16. git diff --stat

```bash
git diff --stat
```

```text
 packages/map_core/lib/map_core.dart | 1 +
 1 file changed, 1 insertion(+)
```

## 17. git diff --name-status

```bash
git diff --name-status
```

```text
M	packages/map_core/lib/map_core.dart
```

## 18. Evidence Pack

### A. Git initial

```text
/Users/karim/Project/pokemonProject
agent_rules.md
reports/pathPattern/pathpattern_27_new_path_save_flow_v0.md
```

### B. Git final

```text
 M packages/map_core/lib/map_core.dart
?? packages/map_core/lib/src/operations/path_pattern_visual_resolution.dart
?? packages/map_core/test/path_pattern_visual_resolution_test.dart
?? reports/pathPattern/pathpattern_28_center_only_rendering_policy_painter_prep_v0.md
```

### C. `git diff --stat` final

```text
 packages/map_core/lib/map_core.dart | 1 +
 1 file changed, 1 insertion(+)
```

### D. `git diff --name-status` final

```text
M	packages/map_core/lib/map_core.dart
```

### E. Contenu complet des fichiers créés

#### `packages/map_core/lib/src/operations/path_pattern_visual_resolution.dart`

```dart
import '../models/enums.dart';
import '../models/project_manifest.dart';
import '../models/project_path_pattern_preset.dart';
import 'path_center_pattern_resolver.dart';

enum PathPatternVisualResolutionKind {
  centerPattern,
  legacyVariant,
}

final class PathPatternVisualResolution {
  PathPatternVisualResolution({
    required this.kind,
    required this.resolvedVariant,
    required this.mapX,
    required this.mapY,
    required this.centerLocalX,
    required this.centerLocalY,
    required List<TilesetVisualFrame> frames,
  }) : frames = List<TilesetVisualFrame>.unmodifiable(frames);

  final PathPatternVisualResolutionKind kind;
  final TerrainPathVariant resolvedVariant;
  final int mapX;
  final int mapY;
  final int? centerLocalX;
  final int? centerLocalY;
  final List<TilesetVisualFrame> frames;

  bool get usesCenterPattern =>
      kind == PathPatternVisualResolutionKind.centerPattern;
  bool get usesLegacyVariant =>
      kind == PathPatternVisualResolutionKind.legacyVariant;
}

PathPatternVisualResolution resolvePathPatternVisual({
  required ProjectPathPatternPreset pathPatternPreset,
  required ProjectPathPreset basePathPreset,
  required TerrainPathVariant resolvedVariant,
  required int mapX,
  required int mapY,
}) {
  if (mapX < 0) {
    throw ArgumentError.value(
      mapX,
      'mapX',
      'PathPattern mapX must be non-negative.',
    );
  }
  if (mapY < 0) {
    throw ArgumentError.value(
      mapY,
      'mapY',
      'PathPattern mapY must be non-negative.',
    );
  }

  if (resolvedVariant != TerrainPathVariant.cross) {
    final legacyMapping = _findVariantMapping(
      basePathPreset: basePathPreset,
      variant: resolvedVariant,
    );
    if (legacyMapping != null && legacyMapping.frames.isNotEmpty) {
      return PathPatternVisualResolution(
        kind: PathPatternVisualResolutionKind.legacyVariant,
        resolvedVariant: resolvedVariant,
        mapX: mapX,
        mapY: mapY,
        centerLocalX: null,
        centerLocalY: null,
        frames: legacyMapping.frames,
      );
    }
  }

  final centerResolution = resolvePathCenterPatternCell(
    pattern: pathPatternPreset.centerPattern,
    mapX: mapX,
    mapY: mapY,
  );
  return PathPatternVisualResolution(
    kind: PathPatternVisualResolutionKind.centerPattern,
    resolvedVariant: resolvedVariant,
    mapX: mapX,
    mapY: mapY,
    centerLocalX: centerResolution.localX,
    centerLocalY: centerResolution.localY,
    frames: centerResolution.cell.frames,
  );
}

PathPresetVariantMapping? _findVariantMapping({
  required ProjectPathPreset basePathPreset,
  required TerrainPathVariant variant,
}) {
  for (final mapping in basePathPreset.variants) {
    if (mapping.variant == variant) {
      return mapping;
    }
  }
  return null;
}
```

#### `packages/map_core/test/path_pattern_visual_resolution_test.dart`

```dart
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('resolvePathPatternVisual center-only 1x1', () {
    test('uses center pattern for multiple variants when no mapping exists',
        () {
      final preset = _pathPatternPreset(centerPattern: _singleCellPattern());
      final base = _basePathPreset(variants: const []);

      final variants = [
        TerrainPathVariant.endNorth,
        TerrainPathVariant.cornerNE,
        TerrainPathVariant.isolated,
      ];
      for (final variant in variants) {
        final resolution = resolvePathPatternVisual(
          pathPatternPreset: preset,
          basePathPreset: base,
          resolvedVariant: variant,
          mapX: 7,
          mapY: 3,
        );
        expect(resolution.kind, PathPatternVisualResolutionKind.centerPattern);
        expect(resolution.resolvedVariant, variant);
        expect(resolution.centerLocalX, 0);
        expect(resolution.centerLocalY, 0);
        expect(resolution.frames.single.source,
            const TilesetSourceRect(x: 10, y: 0));
      }
    });
  });

  group('resolvePathPatternVisual center-only 2x2 repetition', () {
    test('repeats A/B/C/D by map coordinates', () {
      final preset = _pathPatternPreset(centerPattern: _twoByTwoPattern());
      final base = _basePathPreset(variants: const []);

      _expectCenter(preset, base,
          mapX: 0, mapY: 0, expectedSourceX: 0, expectedSourceY: 0);
      _expectCenter(preset, base,
          mapX: 1, mapY: 0, expectedSourceX: 1, expectedSourceY: 0);
      _expectCenter(preset, base,
          mapX: 0, mapY: 1, expectedSourceX: 0, expectedSourceY: 1);
      _expectCenter(preset, base,
          mapX: 1, mapY: 1, expectedSourceX: 1, expectedSourceY: 1);
      _expectCenter(preset, base,
          mapX: 2, mapY: 0, expectedSourceX: 0, expectedSourceY: 0);
      _expectCenter(preset, base,
          mapX: 3, mapY: 1, expectedSourceX: 1, expectedSourceY: 1);
    });
  });

  group('resolvePathPatternVisual configured variant', () {
    test('uses legacy variant frames when mapping exists', () {
      final preset = _pathPatternPreset(centerPattern: _singleCellPattern());
      final base = _basePathPreset(
        variants: [
          PathPresetVariantMapping(
            variant: TerrainPathVariant.endNorth,
            frames: const [
              TilesetVisualFrame(
                tilesetId: 'variant-tileset',
                source: TilesetSourceRect(x: 30, y: 5),
                durationMs: 90,
              ),
            ],
          ),
        ],
      );

      final resolution = resolvePathPatternVisual(
        pathPatternPreset: preset,
        basePathPreset: base,
        resolvedVariant: TerrainPathVariant.endNorth,
        mapX: 4,
        mapY: 2,
      );

      expect(resolution.kind, PathPatternVisualResolutionKind.legacyVariant);
      expect(resolution.centerLocalX, isNull);
      expect(resolution.centerLocalY, isNull);
      expect(resolution.frames.single.tilesetId, 'variant-tileset');
      expect(resolution.frames.single.source,
          const TilesetSourceRect(x: 30, y: 5));
      expect(resolution.frames.single.durationMs, 90);
    });
  });

  group('resolvePathPatternVisual missing variant', () {
    test('falls back to center pattern', () {
      final preset = _pathPatternPreset(centerPattern: _singleCellPattern());
      final base = _basePathPreset(variants: const []);

      final resolution = resolvePathPatternVisual(
        pathPatternPreset: preset,
        basePathPreset: base,
        resolvedVariant: TerrainPathVariant.cornerNE,
        mapX: 0,
        mapY: 0,
      );

      expect(resolution.kind, PathPatternVisualResolutionKind.centerPattern);
      expect(resolution.frames.single.source,
          const TilesetSourceRect(x: 10, y: 0));
    });
  });

  group('resolvePathPatternVisual cross policy', () {
    test('always uses center pattern even when cross mapping exists', () {
      final preset = _pathPatternPreset(centerPattern: _singleCellPattern());
      final base = _basePathPreset(
        variants: [
          PathPresetVariantMapping(
            variant: TerrainPathVariant.cross,
            frames: const [
              TilesetVisualFrame(source: TilesetSourceRect(x: 99, y: 99)),
            ],
          ),
        ],
      );

      final resolution = resolvePathPatternVisual(
        pathPatternPreset: preset,
        basePathPreset: base,
        resolvedVariant: TerrainPathVariant.cross,
        mapX: 2,
        mapY: 2,
      );

      expect(resolution.kind, PathPatternVisualResolutionKind.centerPattern);
      expect(resolution.frames.single.source,
          const TilesetSourceRect(x: 10, y: 0));
    });
  });

  group('resolvePathPatternVisual frame metadata', () {
    test('keeps frame order, duration and tileset override on center fallback',
        () {
      final preset = _pathPatternPreset(
        centerPattern: PathCenterPattern(
          size: PathCenterPatternSize(width: 1, height: 1),
          cells: [
            PathCenterPatternCell(
              localX: 0,
              localY: 0,
              frames: const [
                TilesetVisualFrame(
                  tilesetId: 'override-a',
                  source: TilesetSourceRect(x: 1, y: 2),
                  durationMs: 80,
                ),
                TilesetVisualFrame(
                  tilesetId: 'override-b',
                  source: TilesetSourceRect(x: 3, y: 4),
                  durationMs: 120,
                ),
              ],
            ),
          ],
        ),
      );
      final base = _basePathPreset(variants: const []);

      final resolution = resolvePathPatternVisual(
        pathPatternPreset: preset,
        basePathPreset: base,
        resolvedVariant: TerrainPathVariant.teeNorth,
        mapX: 0,
        mapY: 0,
      );

      expect(resolution.kind, PathPatternVisualResolutionKind.centerPattern);
      expect(resolution.frames.length, 2);
      expect(resolution.frames[0].tilesetId, 'override-a');
      expect(resolution.frames[0].source, const TilesetSourceRect(x: 1, y: 2));
      expect(resolution.frames[0].durationMs, 80);
      expect(resolution.frames[1].tilesetId, 'override-b');
      expect(resolution.frames[1].source, const TilesetSourceRect(x: 3, y: 4));
      expect(resolution.frames[1].durationMs, 120);
    });

    test('keeps frame order, duration and tileset override on legacy variant',
        () {
      final preset = _pathPatternPreset(centerPattern: _singleCellPattern());
      final base = _basePathPreset(
        variants: [
          PathPresetVariantMapping(
            variant: TerrainPathVariant.cornerSE,
            frames: const [
              TilesetVisualFrame(
                tilesetId: 'legacy-a',
                source: TilesetSourceRect(x: 7, y: 8),
                durationMs: 70,
              ),
              TilesetVisualFrame(
                tilesetId: 'legacy-b',
                source: TilesetSourceRect(x: 9, y: 10),
                durationMs: 110,
              ),
            ],
          ),
        ],
      );

      final resolution = resolvePathPatternVisual(
        pathPatternPreset: preset,
        basePathPreset: base,
        resolvedVariant: TerrainPathVariant.cornerSE,
        mapX: 6,
        mapY: 6,
      );

      expect(resolution.kind, PathPatternVisualResolutionKind.legacyVariant);
      expect(resolution.frames.length, 2);
      expect(resolution.frames[0].tilesetId, 'legacy-a');
      expect(resolution.frames[0].source, const TilesetSourceRect(x: 7, y: 8));
      expect(resolution.frames[0].durationMs, 70);
      expect(resolution.frames[1].tilesetId, 'legacy-b');
      expect(resolution.frames[1].source, const TilesetSourceRect(x: 9, y: 10));
      expect(resolution.frames[1].durationMs, 110);
    });
  });

  group('resolvePathPatternVisual invalid coordinates', () {
    test('rejects negative coordinates', () {
      final preset = _pathPatternPreset(centerPattern: _singleCellPattern());
      final base = _basePathPreset(
        variants: [
          PathPresetVariantMapping(
            variant: TerrainPathVariant.endSouth,
            frames: const [
              TilesetVisualFrame(source: TilesetSourceRect(x: 1, y: 1)),
            ],
          ),
        ],
      );

      expect(
        () => resolvePathPatternVisual(
          pathPatternPreset: preset,
          basePathPreset: base,
          resolvedVariant: TerrainPathVariant.endSouth,
          mapX: -1,
          mapY: 0,
        ),
        throwsArgumentError,
      );
      expect(
        () => resolvePathPatternVisual(
          pathPatternPreset: preset,
          basePathPreset: base,
          resolvedVariant: TerrainPathVariant.endSouth,
          mapX: 0,
          mapY: -1,
        ),
        throwsArgumentError,
      );
    });
  });

  group('resolvePathPatternVisual empty mapping frames', () {
    test('falls back to center pattern when mapping has no frames', () {
      final preset = _pathPatternPreset(centerPattern: _singleCellPattern());
      final base = _basePathPreset(
        variants: [
          PathPresetVariantMapping(
            variant: TerrainPathVariant.endWest,
            frames: const [],
          ),
        ],
      );

      final resolution = resolvePathPatternVisual(
        pathPatternPreset: preset,
        basePathPreset: base,
        resolvedVariant: TerrainPathVariant.endWest,
        mapX: 4,
        mapY: 4,
      );

      expect(resolution.kind, PathPatternVisualResolutionKind.centerPattern);
      expect(resolution.frames.single.source,
          const TilesetSourceRect(x: 10, y: 0));
    });
  });
}

void _expectCenter(
  ProjectPathPatternPreset pathPatternPreset,
  ProjectPathPreset basePathPreset, {
  required int mapX,
  required int mapY,
  required int expectedSourceX,
  required int expectedSourceY,
}) {
  final resolution = resolvePathPatternVisual(
    pathPatternPreset: pathPatternPreset,
    basePathPreset: basePathPreset,
    resolvedVariant: TerrainPathVariant.cornerNW,
    mapX: mapX,
    mapY: mapY,
  );
  expect(resolution.kind, PathPatternVisualResolutionKind.centerPattern);
  expect(
    resolution.frames.single.source,
    TilesetSourceRect(x: expectedSourceX, y: expectedSourceY),
  );
}

ProjectPathPatternPreset _pathPatternPreset({
  required PathCenterPattern centerPattern,
}) {
  return ProjectPathPatternPreset(
    id: 'pattern',
    name: 'Pattern',
    basePathPresetId: 'base',
    centerPattern: centerPattern,
  );
}

ProjectPathPreset _basePathPreset({
  required List<PathPresetVariantMapping> variants,
}) {
  return ProjectPathPreset(
    id: 'base',
    name: 'Base',
    tilesetId: 'base-tileset',
    variants: variants,
  );
}

PathCenterPattern _singleCellPattern() {
  return PathCenterPattern(
    size: PathCenterPatternSize(width: 1, height: 1),
    cells: [
      PathCenterPatternCell(
        localX: 0,
        localY: 0,
        frames: const [
          TilesetVisualFrame(
            source: TilesetSourceRect(x: 10, y: 0),
          ),
        ],
      ),
    ],
  );
}

PathCenterPattern _twoByTwoPattern() {
  return PathCenterPattern(
    size: PathCenterPatternSize(width: 2, height: 2),
    cells: [
      PathCenterPatternCell(
        localX: 0,
        localY: 0,
        frames: const [
          TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 0)),
        ],
      ),
      PathCenterPatternCell(
        localX: 1,
        localY: 0,
        frames: const [
          TilesetVisualFrame(source: TilesetSourceRect(x: 1, y: 0)),
        ],
      ),
      PathCenterPatternCell(
        localX: 0,
        localY: 1,
        frames: const [
          TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 1)),
        ],
      ),
      PathCenterPatternCell(
        localX: 1,
        localY: 1,
        frames: const [
          TilesetVisualFrame(source: TilesetSourceRect(x: 1, y: 1)),
        ],
      ),
    ],
  );
}
```

### F. Diff complet réel des fichiers modifiés

#### `packages/map_core/lib/map_core.dart`

```diff
diff --git a/packages/map_core/lib/map_core.dart b/packages/map_core/lib/map_core.dart
index e156046f..ff32106b 100644
--- a/packages/map_core/lib/map_core.dart
+++ b/packages/map_core/lib/map_core.dart
@@ -34,6 +34,7 @@ export 'src/operations/map_path.dart';
 export 'src/operations/map_terrain.dart';
 export 'src/operations/map_terrain_autotile.dart';
 export 'src/operations/path_center_pattern_resolver.dart';
+export 'src/operations/path_pattern_visual_resolution.dart';
 export 'src/operations/project_path_preset_center_pattern_adapter.dart';
 export 'src/operations/project_path_pattern_preset_json_codec.dart';
 export 'src/operations/project_json_migrations.dart';
```

### G. Sorties complètes des tests ciblés principaux

#### `packages/map_core`

```text
00:00 +0: loading test/path_pattern_visual_resolution_test.dart
00:00 +0: resolvePathPatternVisual center-only 1x1 uses center pattern for multiple variants when no mapping exists
00:00 +1: resolvePathPatternVisual center-only 2x2 repetition repeats A/B/C/D by map coordinates
00:00 +2: resolvePathPatternVisual configured variant uses legacy variant frames when mapping exists
00:00 +3: resolvePathPatternVisual missing variant falls back to center pattern
00:00 +4: resolvePathPatternVisual cross policy always uses center pattern even when cross mapping exists
00:00 +5: resolvePathPatternVisual frame metadata keeps frame order, duration and tileset override on center fallback
00:00 +6: resolvePathPatternVisual frame metadata keeps frame order, duration and tileset override on legacy variant
00:00 +7: resolvePathPatternVisual invalid coordinates rejects negative coordinates
00:00 +8: resolvePathPatternVisual empty mapping frames falls back to center pattern when mapping has no frames
00:00 +9: All tests passed!
```

#### `packages/map_editor`

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_new_path_save_flow_test.dart
00:00 +0: applyNewPathBuildRequestToManifest ajoute basePathPreset et pathPatternPreset en fin de liste
00:00 +1: applyNewPathBuildRequestToManifest préserve les entrées existantes inchangées
00:00 +2: applyNewPathBuildRequestToManifest ne mute pas le manifest source
00:00 +3: applyNewPathBuildRequestToManifest collision base path id lève une erreur
00:00 +4: applyNewPathBuildRequestToManifest collision path pattern id lève une erreur
00:00 +5: applyNewPathBuildRequestToManifest conserve une couverture partielle des variants telle quelle
00:00 +6: applyNewPathBuildRequestToManifest n ajoute aucun variant manquant
00:00 +7: applyNewPathBuildRequestToManifest n ajoute jamais cross automatiquement
00:00 +8: All tests passed!
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart
00:00 +0: PathStudioPanel renders a dark empty state when no PathPattern preset exists
00:00 +1: PathStudioPanel lists presets and updates summary and inspector selection
00:01 +2: PathStudioPanel selected saved preset shows read-only center and inspector detail
00:01 +3: PathStudioPanel saved preset uses image-backed thumbnail when tileset exists
00:01 +4: PathStudioPanel saved preset missing image falls back to readable source label
00:01 +5: PathStudioPanel saved preset with missing base path shows diagnostic
00:01 +6: PathStudioPanel filters presets locally and clears selection on no result
00:01 +7: PathStudioPanel creates a new path draft without legacy base presets
00:01 +8: PathStudioPanel new path draft does not force existing legacy path choices
00:02 +9: PathStudioPanel new path draft can select a project tileset
00:02 +10: PathStudioPanel new path draft stays usable when the project has no tileset
00:02 +11: PathStudioPanel assigns a tileset tile to the 1x1 active cell
00:02 +12: PathStudioPanel missing tileset image keeps the logical picker fallback
00:03 +13: PathStudioPanel image-backed tileset picker assigns the active cell
00:03 +14: PathStudioPanel image-backed picker fills all 2x2 cells and supports clear
00:03 +15: PathStudioPanel assigns independent tiles to all 2x2 center cells
00:04 +16: PathStudioPanel replaces and clears the active cell tile
00:04 +17: PathStudioPanel changing tileset clears configured center cells
00:04 +18: PathStudioPanel resizes the new path draft to 2x2 and selects a cell
00:05 +19: PathStudioPanel edits new path draft name and keeps save disabled
00:05 +20: PathStudioPanel new path save status explains missing path variant mapping
00:05 +21: PathStudioPanel new path with complete center stays disabled without callback
00:05 +22: PathStudioPanel new path with variants partiels enables save when callback exists
00:05 +23: PathStudioPanel new path save updates parent manifest and selects saved preset
00:05 +24: PathStudioPanel legacy save request is prepared but disabled without callback
00:05 +25: PathStudioPanel legacy save updates parent manifest and panel exits draft state
00:06 +26: PathStudioPanel legacy duplicate proposed id blocks save
00:06 +27: PathStudioPanel secondary legacy flow changes inherited structure locally
00:06 +28: PathStudioPanel empty new path name shows a local diagnostic
00:06 +29: PathStudioPanel new path variants can be selected assigned and cleared with picker
00:06 +30: PathStudioPanel all variants configured clears variant diagnostic but save stays disabled
00:07 +31: PathStudioPanel secondary legacy flow reports missing existing paths
00:07 +32: All tests passed!
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_new_path_build_request_test.dart
00:00 +0: PathStudioNewPathBuildPlan variants partiels produisent un warning non bloquant
00:00 +1: PathStudioNewPathBuildPlan tous les variants configurés suppriment le warning partiel
00:00 +2: PathStudioNewPathBuildPlan zéro variant configuré autorise la requête avec warning fort
00:00 +3: PathStudioNewPathBuildPlan cross est exclu et documenté en warning
00:00 +4: PathStudioNewPathBuildPlan nom manquant est bloquant
00:00 +5: PathStudioNewPathBuildPlan tileset manquant est bloquant
00:00 +6: PathStudioNewPathBuildPlan centre incomplet est bloquant
00:00 +7: PathStudioNewPathBuildPlan collision id base path est bloquante
00:00 +8: PathStudioNewPathBuildPlan collision id path pattern est bloquante
00:00 +9: PathStudioNewPathBuildPlan build request construit les deux presets sans muter le manifest
00:00 +10: PathStudioNewPathBuildPlan basePathPreset inclut seulement les variants configurés
00:00 +11: All tests passed!
Analyzing 2 items...
No issues found! (ran in 2.3s)
```

### H. Ligne finale exacte des grosses régressions

- `packages/map_core` (`dart test --reporter expanded --no-color`): `00:02 +1122: All tests passed!`
- `packages/map_editor` régression minimale: `All tests passed!` sur les 3 suites + `No issues found! (ran in 2.3s)` pour `flutter analyze`.

### I. Sortie analyze ciblée

```text
Analyzing 3 items...
No issues found!
```

## 19. Auto-review

- Ce qui est prouvé:
  - politique center-only explicite en opération pure.
  - répétition 2x2 validée sur coordonnées map.
  - fallback center pour variant manquant et mapping vide.
  - `cross` forcé center.
  - conservation des métadonnées de frame center/legacy.
  - API exportée via `map_core.dart`.
- Ce qui n’est pas couvert dans ce lot:
  - aucune intégration painter/runtime (explicitement hors scope).
  - aucun changement d’UI Path Studio (hors scope).

## 20. Critique du prompt

- Le prompt est cohérent et précis sur le scope technique, les non-objectifs et la politique produit.
- Point de tension mineur: la section historique de règles globales contient parfois des contraintes très larges de workflow (skills/worktree) qui dépassent ce lot ciblé; l’interprétation retenue reste le plus petit chemin sûr conforme à ta demande explicite.
- Les contraintes “Git lecture seule” et “pas de mutation ProjectManifest” sont respectées.

## 21. Conclusion

Le Lot PathPattern-28 est implémenté côté `map_core` selon la politique center-only V0, testé et exporté pour usage futur painter/runtime, sans toucher au painter, runtime, UI, manifest persistant ni codecs.

## Checklist finale

- [x] Audit initial réalisé.
- [x] AGENTS.md et agent_rules.md lus.
- [x] Ancienne roadmap Tall Grass ignorée.
- [x] Aucun faux test.
- [x] Aucun provider inventé.
- [x] Aucun repository/service ajouté.
- [x] Aucun fichier projet écrit.
- [x] Aucun FileProjectRepository utilisé.
- [x] ProjectManifest non modifié.
- [x] Codecs PathPattern non modifiés.
- [x] Aucun generated file.
- [x] Aucun build_runner.
- [x] Politique center-only explicitement implémentée.
- [x] CenterPattern utilisé quand aucun variant n’est configuré.
- [x] CenterPattern utilisé quand le variant résolu est manquant.
- [x] TerrainPathVariant.cross utilise toujours centerPattern.
- [x] Variant configuré utilise ses frames legacy.
- [x] Aucune génération de mapping vide.
- [x] Aucun fallback persistant ajouté au modèle.
- [x] Répétition 2×2 testée.
- [x] Coordonnées négatives testées.
- [x] API exportée si nécessaire au futur painter/runtime.
- [x] Tests ciblés passent.
- [x] Régressions pertinentes passent ou échecs documentés.
- [x] Analyze ciblé passe.
- [x] Rapport final complet créé.
- [x] Auto-review faite.
- [x] Critique du prompt faite.
