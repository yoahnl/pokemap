# Lot PathPattern-29 — Editor Painter Center-only Rendering V0

## 1. Résumé exécutif

Le rendu PathLayer éditeur utilise maintenant la politique Lot 28 via un helper de production branché dans `MapGridPainter`.  
Un `ProjectPathPatternPreset` center-only 2x2 associé au `ProjectPathPreset` du layer est effectivement rendu dans le canvas (A/B/C/D répétés selon `mapX/mapY`), avec fallback legacy préservé quand il n’y a pas de PathPattern, et fallback legacy non-crash en cas d’ambiguïté (plusieurs PathPatterns pour la même base).

## 2. Audit initial

### Commandes exécutées avant modification

```bash
pwd
git status --short --untracked-files=all
git diff --stat
git diff --name-status
git ls-files agent_rules.md
git ls-files reports/pathPattern/pathpattern_28_center_only_rendering_policy_painter_prep_v0.md
```

### Sortie exacte

```text
/Users/karim/Project/pokemonProject
agent_rules.md
reports/pathPattern/pathpattern_28_center_only_rendering_policy_painter_prep_v0.md
```

### Fichiers inspectés explicitement

- `AGENTS.md`
- `agent_rules.md`
- `packages/map_core/lib/src/operations/path_pattern_visual_resolution.dart`
- `packages/map_core/lib/src/operations/path_center_pattern_resolver.dart`
- `packages/map_core/lib/src/models/project_manifest.dart`
- `packages/map_core/lib/src/models/project_path_pattern_preset.dart`
- `packages/map_core/lib/src/models/enums.dart`
- `packages/map_editor/lib/src/features/path_studio/path_studio_save_flow.dart`
- `packages/map_editor/test/path_pattern/path_studio_new_path_save_flow_test.dart`
- `packages/map_editor/lib/src/ui/canvas/map_canvas.dart`
- `packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart`
- `packages/map_editor/lib/src/application/models/path_autotile_set.dart`
- `packages/map_editor/lib/src/application/services/path_autotile_resolver.dart`
- `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`
- `packages/map_editor/test/map_grid_painter_test.dart`

### Établissement d’architecture demandé

- Rendu `PathLayer` branché dans `MapGridPainter._paintPathLayer(...)`.
- `TerrainPathVariant` calculé par cellule via `resolvePathVariantAt(...)`.
- `ProjectPathPreset` résolu depuis `PathLayer.presetId` -> `pathAutotileSetsByPresetId[presetId]`.
- Transformation `TilesetVisualFrame` -> `drawImageRect` dans `MapGridPainter` (`source.x/y * sourceTileWidth/Height`).
- Images tileset chargées/cachées dans `MapCanvas` via `_TilesetImageCache.loadMany(...)`.
- Rendu éditeur supporte déjà frames animées (boucle via `resolvePlacedElementAnimationFrameIndex`).
- Compat legacy à préserver: voie `PathAutotileSet` existante.
- Association PathPattern <-> base legacy: `ProjectPathPatternPreset.basePathPresetId == ProjectPathPreset.id`.

## 3. Où le rendu path éditeur est branché

- `MapCanvas` construit `MapGridPainter`.
- `MapGridPainter._paintPathLayer` parcourt les cellules du `PathLayer`.
- `MapGridPainter._paintPathLayerCell` calcule le variant `resolvePathVariantAt(...)`.
- Lot 29: `_paintPathLayerCell` appelle désormais `_paintResolvedPathVariantCell`, qui délègue au helper de prod `resolvePathPatternEditorRenderResolution(...)`.

## 4. Association ProjectPathPatternPreset ↔ ProjectPathPreset

Politique V0 implémentée:

- match par `basePathPresetId == PathLayer.presetId`.
- `0` match -> legacy.
- `1` match -> `resolvePathPatternVisual(...)`.
- `>1` match -> fallback legacy explicite (source `ambiguousPathPatternFallback`), sans crash.

## 5. Politique center-only appliquée

Dans le helper de prod `resolvePathPatternEditorRenderResolution(...)`:

- quand un unique PathPattern associé existe, la résolution passe par `map_core.resolvePathPatternVisual(...)`.
- donc center-only 2x2, fallback variant manquant, et priorité `cross -> centerPattern` sont appliqués côté canvas éditeur.

## 6. Gestion variants manquants / cross

- variants manquants: fallback centerPattern via `resolvePathPatternVisual(...)`.
- `TerrainPathVariant.cross`: centerPattern forcé via `resolvePathPatternVisual(...)`.
- variant configuré: frames legacy conservées via `resolvePathPatternVisual(...)`.

## 7. Gestion ambiguïté plusieurs PathPatterns pour une même base

- helper de prod détecte `matchedPatterns.length > 1`.
- ne choisit pas arbitrairement.
- retourne fallback legacy (`ambiguousPathPatternFallback`).
- pas d’exception, pas de crash painter.

## 8. Fichiers créés

- `packages/map_editor/lib/src/features/path_pattern/path_pattern_editor_render_resolution.dart`
- `packages/map_editor/test/path_pattern/path_pattern_editor_render_resolution_test.dart`
- `reports/pathPattern/pathpattern_29_editor_painter_center_only_rendering_v0.md`

## 9. Fichiers modifiés

- `packages/map_editor/lib/src/ui/canvas/map_canvas.dart`
- `packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart`
- `packages/map_editor/test/map_grid_painter_test.dart`

## 10. Fichiers supprimés

- Aucun.

## 11. Comportements préservés

- Rendu legacy sans PathPattern conserve la voie `PathAutotileSet`.
- Aucun changement runtime/Flame/gameplay/battle.
- Aucun changement `ProjectManifest` modèle/codec/stockage.
- Aucun save disque.
- Aucun provider/repository/service ajouté.

## 12. Tests exécutés

### `packages/map_core`

```bash
dart test test/path_pattern_visual_resolution_test.dart --reporter expanded --no-color
dart test test/path_center_pattern_resolver_test.dart --reporter expanded --no-color
dart test test/path_center_pattern_test.dart --reporter expanded --no-color
dart test test/project_path_pattern_preset_test.dart --reporter expanded --no-color
dart test test/project_manifest_path_pattern_preset_operations_test.dart --reporter expanded --no-color
dart test test/project_manifest_path_pattern_presets_test.dart --reporter expanded --no-color
dart analyze lib/src/operations lib/src/models test/path_pattern_visual_resolution_test.dart
```

### `packages/map_editor`

```bash
flutter test test/path_pattern/path_pattern_editor_render_resolution_test.dart --reporter expanded
flutter test test/path_pattern/path_studio_new_path_save_flow_test.dart --reporter expanded
flutter test test/path_pattern/path_studio_new_path_build_request_test.dart --reporter expanded
flutter test test/path_pattern/path_studio_panel_test.dart --reporter expanded
flutter test test/path_pattern/ --reporter expanded
flutter test test/map_grid_painter_test.dart --reporter expanded
flutter analyze lib/src/features/path_studio test/path_pattern
```

## 13. Résultats des validations

- `map_core` tests ciblés: OK (toutes suites vertes).
- `map_core` analyze ciblé: `No issues found!`.
- `map_editor` nouveaux tests Lot 29: OK.
- `map_editor` régressions Path Studio demandées: OK.
- `map_editor` régression globale `test/path_pattern/`: OK.
- `map_editor` test painter réel center-only 2x2: OK.
- `map_editor` analyze ciblé: `No issues found! (ran in 2.2s)`.

## 14. git status final

```bash
git status --short --untracked-files=all
```

```text
 M packages/map_editor/lib/src/ui/canvas/map_canvas.dart
 M packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart
 M packages/map_editor/test/map_grid_painter_test.dart
?? packages/map_editor/lib/src/features/path_pattern/path_pattern_editor_render_resolution.dart
?? packages/map_editor/test/path_pattern/path_pattern_editor_render_resolution_test.dart
?? reports/pathPattern/pathpattern_29_editor_painter_center_only_rendering_v0.md
```

## 15. git diff --stat

```bash
git diff --stat
```

```text
 .../map_editor/lib/src/ui/canvas/map_canvas.dart   |  27 +++
 .../src/ui/canvas/map_canvas/map_grid_painter.dart |  65 ++++---
 .../map_editor/test/map_grid_painter_test.dart     | 195 +++++++++++++++++++++
 3 files changed, 259 insertions(+), 28 deletions(-)
```

## 16. git diff --name-status

```bash
git diff --name-status
```

```text
M	packages/map_editor/lib/src/ui/canvas/map_canvas.dart
M	packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart
M	packages/map_editor/test/map_grid_painter_test.dart
```

## 17. Evidence Pack

### A. `git status` initial

```text
/Users/karim/Project/pokemonProject
agent_rules.md
reports/pathPattern/pathpattern_28_center_only_rendering_policy_painter_prep_v0.md
```

### B. `git status` final

```text
 M packages/map_editor/lib/src/ui/canvas/map_canvas.dart
 M packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart
 M packages/map_editor/test/map_grid_painter_test.dart
?? packages/map_editor/lib/src/features/path_pattern/path_pattern_editor_render_resolution.dart
?? packages/map_editor/test/path_pattern/path_pattern_editor_render_resolution_test.dart
?? reports/pathPattern/pathpattern_29_editor_painter_center_only_rendering_v0.md
```

### C. `git diff --stat` final

```text
 .../map_editor/lib/src/ui/canvas/map_canvas.dart   |  27 +++
 .../src/ui/canvas/map_canvas/map_grid_painter.dart |  65 ++++---
 .../map_editor/test/map_grid_painter_test.dart     | 195 +++++++++++++++++++++
 3 files changed, 259 insertions(+), 28 deletions(-)
```

### D. `git diff --name-status` final

```text
M	packages/map_editor/lib/src/ui/canvas/map_canvas.dart
M	packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart
M	packages/map_editor/test/map_grid_painter_test.dart
```

### E. Contenu complet des fichiers créés

#### `packages/map_editor/lib/src/features/path_pattern/path_pattern_editor_render_resolution.dart`

```dart
import 'package:map_core/map_core.dart';

import '../../application/models/path_autotile_set.dart';

enum PathPatternEditorRenderResolutionSource {
  legacy,
  pathPattern,
  ambiguousPathPatternFallback,
}

final class PathPatternEditorRenderResolution {
  const PathPatternEditorRenderResolution({
    required this.source,
    required this.variant,
    required this.tilesetId,
    required this.sourceRect,
  });

  final PathPatternEditorRenderResolutionSource source;
  final TerrainPathVariant variant;
  final String tilesetId;
  final TilesetSourceRect sourceRect;
}

PathPatternEditorRenderResolution? resolvePathPatternEditorRenderResolution({
  required ProjectManifest? project,
  required String basePathPresetId,
  required TerrainPathVariant variant,
  required int mapX,
  required int mapY,
  required double elapsedMs,
  required PathAutotileSet? legacyAutotileSet,
}) {
  final normalizedPresetId = basePathPresetId.trim();
  if (project == null || normalizedPresetId.isEmpty) {
    return _resolveLegacy(
      variant: variant,
      elapsedMs: elapsedMs,
      legacyAutotileSet: legacyAutotileSet,
      source: PathPatternEditorRenderResolutionSource.legacy,
    );
  }

  final matchedPatterns = <ProjectPathPatternPreset>[
    for (final preset in project.pathPatternPresets)
      if (preset.basePathPresetId == normalizedPresetId) preset,
  ];
  if (matchedPatterns.length > 1) {
    return _resolveLegacy(
      variant: variant,
      elapsedMs: elapsedMs,
      legacyAutotileSet: legacyAutotileSet,
      source:
          PathPatternEditorRenderResolutionSource.ambiguousPathPatternFallback,
    );
  }
  if (matchedPatterns.isEmpty) {
    return _resolveLegacy(
      variant: variant,
      elapsedMs: elapsedMs,
      legacyAutotileSet: legacyAutotileSet,
      source: PathPatternEditorRenderResolutionSource.legacy,
    );
  }

  ProjectPathPreset? basePreset;
  for (final preset in project.pathPresets) {
    if (preset.id == normalizedPresetId) {
      basePreset = preset;
      break;
    }
  }
  if (basePreset == null) {
    return _resolveLegacy(
      variant: variant,
      elapsedMs: elapsedMs,
      legacyAutotileSet: legacyAutotileSet,
      source: PathPatternEditorRenderResolutionSource.legacy,
    );
  }

  final visual = resolvePathPatternVisual(
    pathPatternPreset: matchedPatterns.single,
    basePathPreset: basePreset,
    resolvedVariant: variant,
    mapX: mapX,
    mapY: mapY,
  );
  final frame = _resolveAnimatedFrame(
    frames: visual.frames,
    elapsedMs: elapsedMs,
  );
  if (frame == null) {
    return _resolveLegacy(
      variant: variant,
      elapsedMs: elapsedMs,
      legacyAutotileSet: legacyAutotileSet,
      source: PathPatternEditorRenderResolutionSource.legacy,
    );
  }
  final tilesetId = frame.tilesetId.trim().isNotEmpty
      ? frame.tilesetId.trim()
      : basePreset.tilesetId.trim();
  if (tilesetId.isEmpty) {
    return _resolveLegacy(
      variant: variant,
      elapsedMs: elapsedMs,
      legacyAutotileSet: legacyAutotileSet,
      source: PathPatternEditorRenderResolutionSource.legacy,
    );
  }
  return PathPatternEditorRenderResolution(
    source: PathPatternEditorRenderResolutionSource.pathPattern,
    variant: variant,
    tilesetId: tilesetId,
    sourceRect: frame.source,
  );
}

PathPatternEditorRenderResolution? _resolveLegacy({
  required TerrainPathVariant variant,
  required double elapsedMs,
  required PathAutotileSet? legacyAutotileSet,
  required PathPatternEditorRenderResolutionSource source,
}) {
  if (legacyAutotileSet == null) {
    return null;
  }
  final frame = legacyAutotileSet.frameForVariantAt(
    variant,
    elapsedMs: elapsedMs,
  );
  if (frame == null) {
    return null;
  }
  final tilesetId = frame.tilesetId.trim().isNotEmpty
      ? frame.tilesetId.trim()
      : legacyAutotileSet.tilesetId.trim();
  if (tilesetId.isEmpty) {
    return null;
  }
  return PathPatternEditorRenderResolution(
    source: source,
    variant: variant,
    tilesetId: tilesetId,
    sourceRect: frame.source,
  );
}

TilesetVisualFrame? _resolveAnimatedFrame({
  required List<TilesetVisualFrame> frames,
  required double elapsedMs,
}) {
  if (frames.isEmpty) {
    return null;
  }
  if (frames.length == 1) {
    return frames.first;
  }
  final index = resolvePlacedElementAnimationFrameIndex(
    frameDurationsMs: normalizeElementFrameDurationsMs(
      frames.map((frame) => frame.durationMs).toList(growable: false),
    ),
    elapsedMs: elapsedMs,
    animation: const MapPlacedElementAnimation(
      enabled: true,
      mode: MapPlacedElementAnimationMode.loop,
    ),
  );
  if (index < 0 || index >= frames.length) {
    return frames.first;
  }
  return frames[index];
}
```

#### `packages/map_editor/test/path_pattern/path_pattern_editor_render_resolution_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/models/path_autotile_set.dart';
import 'package:map_editor/src/features/path_pattern/path_pattern_editor_render_resolution.dart';

void main() {
  group('resolvePathPatternEditorRenderResolution', () {
    test('sans PathPattern associé conserve le rendu legacy', () {
      final project = _project(pathPresets: [_basePresetNoVariants()]);
      final legacySet = PathAutotileSet.defaultForTileset('tileset-main');

      final resolution = resolvePathPatternEditorRenderResolution(
        project: project,
        basePathPresetId: 'base',
        variant: TerrainPathVariant.cornerNE,
        mapX: 0,
        mapY: 0,
        elapsedMs: 0,
        legacyAutotileSet: legacySet,
      );

      expect(
        resolution?.source,
        PathPatternEditorRenderResolutionSource.legacy,
      );
      expect(resolution?.sourceRect, const TilesetSourceRect(x: 3, y: 1));
    });

    test('un seul PathPattern associé utilise la résolution PathPattern', () {
      final project = _project(
        pathPresets: [_basePresetNoVariants()],
        pathPatterns: [_pattern2x2(baseId: 'base')],
      );
      final legacySet = PathAutotileSet.defaultForTileset('tileset-main');

      final resolution = resolvePathPatternEditorRenderResolution(
        project: project,
        basePathPresetId: 'base',
        variant: TerrainPathVariant.cornerNE,
        mapX: 1,
        mapY: 0,
        elapsedMs: 0,
        legacyAutotileSet: legacySet,
      );

      expect(
        resolution?.source,
        PathPatternEditorRenderResolutionSource.pathPattern,
      );
      expect(resolution?.sourceRect, const TilesetSourceRect(x: 6, y: 0));
    });

    test(
        'plusieurs PathPatterns associés tombent en fallback legacy sans crash',
        () {
      final project = _project(
        pathPresets: [_basePresetNoVariants()],
        pathPatterns: [
          _pattern2x2(id: 'p1', baseId: 'base'),
          _pattern2x2(id: 'p2', baseId: 'base'),
        ],
      );
      final legacySet = PathAutotileSet.defaultForTileset('tileset-main');

      final resolution = resolvePathPatternEditorRenderResolution(
        project: project,
        basePathPresetId: 'base',
        variant: TerrainPathVariant.cornerNE,
        mapX: 1,
        mapY: 0,
        elapsedMs: 0,
        legacyAutotileSet: legacySet,
      );

      expect(
        resolution?.source,
        PathPatternEditorRenderResolutionSource.ambiguousPathPatternFallback,
      );
      expect(resolution?.sourceRect, const TilesetSourceRect(x: 3, y: 1));
    });

    test('center-only 2x2 répète A B C D selon mapX mapY', () {
      final project = _project(
        pathPresets: [_basePresetNoVariants()],
        pathPatterns: [_pattern2x2(baseId: 'base')],
      );
      final legacySet = PathAutotileSet.defaultForTileset('tileset-main');

      final a = resolvePathPatternEditorRenderResolution(
        project: project,
        basePathPresetId: 'base',
        variant: TerrainPathVariant.isolated,
        mapX: 0,
        mapY: 0,
        elapsedMs: 0,
        legacyAutotileSet: legacySet,
      );
      final b = resolvePathPatternEditorRenderResolution(
        project: project,
        basePathPresetId: 'base',
        variant: TerrainPathVariant.endNorth,
        mapX: 1,
        mapY: 0,
        elapsedMs: 0,
        legacyAutotileSet: legacySet,
      );
      final c = resolvePathPatternEditorRenderResolution(
        project: project,
        basePathPresetId: 'base',
        variant: TerrainPathVariant.teeSouth,
        mapX: 0,
        mapY: 1,
        elapsedMs: 0,
        legacyAutotileSet: legacySet,
      );
      final d = resolvePathPatternEditorRenderResolution(
        project: project,
        basePathPresetId: 'base',
        variant: TerrainPathVariant.cornerSW,
        mapX: 3,
        mapY: 1,
        elapsedMs: 0,
        legacyAutotileSet: legacySet,
      );

      expect(a?.sourceRect, const TilesetSourceRect(x: 5, y: 0));
      expect(b?.sourceRect, const TilesetSourceRect(x: 6, y: 0));
      expect(c?.sourceRect, const TilesetSourceRect(x: 5, y: 1));
      expect(d?.sourceRect, const TilesetSourceRect(x: 6, y: 1));
    });

    test('variant configuré conserve ses frames legacy', () {
      final project = _project(
        pathPresets: [
          _basePreset(
            variants: [
              const PathPresetVariantMapping(
                variant: TerrainPathVariant.endNorth,
                frames: [
                  TilesetVisualFrame(source: TilesetSourceRect(x: 11, y: 3)),
                ],
              ),
            ],
          ),
        ],
        pathPatterns: [_pattern2x2(baseId: 'base')],
      );
      final legacySet = PathAutotileSet.defaultForTileset('tileset-main');

      final resolution = resolvePathPatternEditorRenderResolution(
        project: project,
        basePathPresetId: 'base',
        variant: TerrainPathVariant.endNorth,
        mapX: 4,
        mapY: 4,
        elapsedMs: 0,
        legacyAutotileSet: legacySet,
      );

      expect(
        resolution?.source,
        PathPatternEditorRenderResolutionSource.pathPattern,
      );
      expect(resolution?.sourceRect, const TilesetSourceRect(x: 11, y: 3));
    });

    test('variant manquant fallback sur centerPattern', () {
      final project = _project(
        pathPresets: [_basePresetNoVariants()],
        pathPatterns: [_pattern2x2(baseId: 'base')],
      );
      final legacySet = PathAutotileSet.defaultForTileset('tileset-main');

      final resolution = resolvePathPatternEditorRenderResolution(
        project: project,
        basePathPresetId: 'base',
        variant: TerrainPathVariant.cornerSE,
        mapX: 0,
        mapY: 0,
        elapsedMs: 0,
        legacyAutotileSet: legacySet,
      );

      expect(
        resolution?.source,
        PathPatternEditorRenderResolutionSource.pathPattern,
      );
      expect(resolution?.sourceRect, const TilesetSourceRect(x: 5, y: 0));
    });

    test('cross utilise toujours centerPattern', () {
      final project = _project(
        pathPresets: [
          _basePreset(
            variants: [
              const PathPresetVariantMapping(
                variant: TerrainPathVariant.cross,
                frames: [
                  TilesetVisualFrame(source: TilesetSourceRect(x: 77, y: 77)),
                ],
              ),
            ],
          ),
        ],
        pathPatterns: [_pattern2x2(baseId: 'base')],
      );
      final legacySet = PathAutotileSet.defaultForTileset('tileset-main');

      final resolution = resolvePathPatternEditorRenderResolution(
        project: project,
        basePathPresetId: 'base',
        variant: TerrainPathVariant.cross,
        mapX: 1,
        mapY: 1,
        elapsedMs: 0,
        legacyAutotileSet: legacySet,
      );

      expect(
        resolution?.source,
        PathPatternEditorRenderResolutionSource.pathPattern,
      );
      expect(resolution?.sourceRect, const TilesetSourceRect(x: 6, y: 1));
    });
  });
}

ProjectManifest _project({
  required List<ProjectPathPreset> pathPresets,
  List<ProjectPathPatternPreset> pathPatterns = const [],
}) {
  return ProjectManifest(
    name: 'Project',
    maps: const [],
    tilesets: const [
      ProjectTilesetEntry(
        id: 'tileset-main',
        name: 'Main',
        relativePath: 'tilesets/main.png',
      ),
    ],
    pathPresets: pathPresets,
    pathPatternPresets: pathPatterns,
    surfaceCatalog: ProjectSurfaceCatalog(),
  );
}

ProjectPathPreset _basePresetNoVariants() {
  return _basePreset(variants: const []);
}

ProjectPathPreset _basePreset({
  required List<PathPresetVariantMapping> variants,
}) {
  return ProjectPathPreset(
    id: 'base',
    name: 'Base',
    tilesetId: 'tileset-main',
    variants: variants,
  );
}

ProjectPathPatternPreset _pattern2x2({
  String id = 'pattern',
  required String baseId,
}) {
  return ProjectPathPatternPreset(
    id: id,
    name: 'Pattern',
    basePathPresetId: baseId,
    centerPattern: PathCenterPattern(
      size: PathCenterPatternSize(width: 2, height: 2),
      cells: [
        PathCenterPatternCell(
          localX: 0,
          localY: 0,
          frames: const [
            TilesetVisualFrame(source: TilesetSourceRect(x: 5, y: 0)),
          ],
        ),
        PathCenterPatternCell(
          localX: 1,
          localY: 0,
          frames: const [
            TilesetVisualFrame(source: TilesetSourceRect(x: 6, y: 0)),
          ],
        ),
        PathCenterPatternCell(
          localX: 0,
          localY: 1,
          frames: const [
            TilesetVisualFrame(source: TilesetSourceRect(x: 5, y: 1)),
          ],
        ),
        PathCenterPatternCell(
          localX: 1,
          localY: 1,
          frames: const [
            TilesetVisualFrame(source: TilesetSourceRect(x: 6, y: 1)),
          ],
        ),
      ],
    ),
  );
}
```

### F. Diff complet réel des fichiers modifiés

#### `packages/map_editor/lib/src/ui/canvas/map_canvas.dart`

```diff
diff --git a/packages/map_editor/lib/src/ui/canvas/map_canvas.dart b/packages/map_editor/lib/src/ui/canvas/map_canvas.dart
index 283a80e7..a7c17504 100644
--- a/packages/map_editor/lib/src/ui/canvas/map_canvas.dart
+++ b/packages/map_editor/lib/src/ui/canvas/map_canvas.dart
@@ -15,6 +15,7 @@ import '../../application/models/path_autotile_set.dart';
 import '../../application/services/tileset_transparent_color_processor.dart';
 import '../../features/editor/state/editor_notifier.dart';
 import '../../features/editor/tools/editor_tool.dart';
+import '../../features/path_pattern/path_pattern_editor_render_resolution.dart';
 import '../../features/surface_painter/surface_layer_static_preview.dart';
 import '../../features/surface_painter/surface_tile_preview_resolver.dart';
 import 'entity_editor_element_visual.dart';
@@ -643,6 +644,23 @@ class _MapCanvasState extends ConsumerState<MapCanvas> {
         }
       }
     }
+    if (project != null) {
+      for (final preset in project.pathPatternPresets) {
+        for (final cell in preset.centerPattern.cells) {
+          for (final frame in cell.frames) {
+            final frameTilesetId = frame.tilesetId.trim();
+            if (frameTilesetId.isEmpty || result.containsKey(frameTilesetId)) {
+              continue;
+            }
+            final frameTilesetPath =
+                notifier.getTilesetAbsolutePathById(frameTilesetId);
+            if (frameTilesetPath != null && frameTilesetPath.isNotEmpty) {
+              result[frameTilesetId] = frameTilesetPath;
+            }
+          }
+        }
+      }
+    }
     return result;
   }
@@ -688,6 +706,15 @@ class _MapCanvasState extends ConsumerState<MapCanvas> {
         }
       }
     }
+    if (project != null) {
+      for (final preset in project.pathPatternPresets) {
+        for (final cell in preset.centerPattern.cells) {
+          if (cell.frames.length > 1) {
+            return true;
+          }
+        }
+      }
+    }
     return false;
   }
```

#### `packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart`

```diff
diff --git a/packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart b/packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart
index b407d32e..cbf1c942 100644
--- a/packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart
+++ b/packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart
@@ -1300,10 +1300,13 @@ class MapGridPainter extends CustomPainter {
 
     final elapsedMs = editorEntityAnimationMs.toDouble();
 
-    final painted = _paintAutotileVariantCell(
+    final painted = _paintResolvedPathVariantCell(
       canvas,
-      autotileSet: autotileSet,
+      basePathPresetId: activePathLayer.presetId,
+      legacyAutotileSet: autotileSet,
       variant: variant,
+      mapX: origin.x,
+      mapY: origin.y,
       dstRect: dstRect,
       alpha: 0.66,
       elapsedMs: elapsedMs,
@@ -1644,16 +1647,14 @@ class MapGridPainter extends CustomPainter {
           tileWidth,
           tileHeight,
         );
-        final pathDrawn = autotileSet == null
-            ? false
-            : _paintPathLayerCell(
-                canvas,
-                layer,
-                autotileSet: autotileSet,
-                x: x,
-                y: y,
-                alpha: pathCellAlpha,
-              );
+        final pathDrawn = _paintPathLayerCell(
+          canvas,
+          layer,
+          autotileSet: autotileSet,
+          x: x,
+          y: y,
+          alpha: pathCellAlpha,
+        );
         if (pathDrawn) {
           continue;
         }
@@ -1677,15 +1678,12 @@ class MapGridPainter extends CustomPainter {
   bool _paintPathLayerCell(
     Canvas canvas,
     PathLayer layer, {
-    required PathAutotileSet autotileSet,
+    required PathAutotileSet? autotileSet,
     required int x,
     required int y,
     required double alpha,
   }) {
-    final tilesetId = autotileSet.tilesetId.trim();
-    if (tilesetId.isEmpty) return false;
-    final tilesetImage = tilesetImagesById[tilesetId];
-    if (tilesetImage == null || sourceTileWidth <= 0 || sourceTileHeight <= 0) {
+    if (sourceTileWidth <= 0 || sourceTileHeight <= 0) {
       return false;
     }
 
@@ -1703,20 +1701,26 @@ class MapGridPainter extends CustomPainter {
 
     final elapsedMs = editorEntityAnimationMs.toDouble();
 
-    return _paintAutotileVariantCell(
+    return _paintResolvedPathVariantCell(
       canvas,
-      autotileSet: autotileSet,
+      basePathPresetId: layer.presetId,
+      legacyAutotileSet: autotileSet,
       variant: variant,
+      mapX: x,
+      mapY: y,
       dstRect: dstRect,
       alpha: alpha,
       elapsedMs: elapsedMs,
     );
   }
 
-  bool _paintAutotileVariantCell(
+  bool _paintResolvedPathVariantCell(
     Canvas canvas, {
-    required PathAutotileSet autotileSet,
+    required String basePathPresetId,
+    required PathAutotileSet? legacyAutotileSet,
     required TerrainPathVariant variant,
+    required int mapX,
+    required int mapY,
     required Rect dstRect,
     required double alpha,
     required double elapsedMs,
@@ -1724,15 +1728,20 @@ class MapGridPainter extends CustomPainter {
     if (sourceTileWidth <= 0 || sourceTileHeight <= 0) {
       return false;
     }
-    final source = autotileSet.sourceForVariantAt(
-      variant,
-      elapsedMs: elapsedMs,
-    );
-    if (source == null) return false;
-    final tilesetId = autotileSet.resolvedTilesetIdForVariantAt(
-      variant,
+    final resolved = resolvePathPatternEditorRenderResolution(
+      project: project,
+      basePathPresetId: basePathPresetId,
+      variant: variant,
+      mapX: mapX,
+      mapY: mapY,
       elapsedMs: elapsedMs,
+      legacyAutotileSet: legacyAutotileSet,
     );
+    if (resolved == null) {
+      return false;
+    }
+    final source = resolved.sourceRect;
+    final tilesetId = resolved.tilesetId.trim();
     if (tilesetId.isEmpty) {
       return false;
     }
```

#### `packages/map_editor/test/map_grid_painter_test.dart`

```diff
diff --git a/packages/map_editor/test/map_grid_painter_test.dart b/packages/map_editor/test/map_grid_painter_test.dart
index a98edca7..2fdf8fad 100644
--- a/packages/map_editor/test/map_grid_painter_test.dart
+++ b/packages/map_editor/test/map_grid_painter_test.dart
@@ -321,6 +321,172 @@ void main() {
       image.dispose();
       tilesetImage.dispose();
     });
+
+    test('paints path layer with center-only 2x2 PathPattern in canvas',
+        () async {
+      const map = MapData(
+        id: 'water_map',
+        name: 'Water Map',
+        size: GridSize(width: 4, height: 2),
+        layers: <MapLayer>[
+          PathLayer(
+            id: 'path_main',
+            name: 'Path',
+            presetId: 'water-base',
+            cells: <bool>[
+              true,
+              true,
+              true,
+              true,
+              true,
+              true,
+              true,
+              true,
+            ],
+          ),
+        ],
+      );
+      final project = ProjectManifest(
+        name: 'editor',
+        maps: const <ProjectMapEntry>[],
+        tilesets: const <ProjectTilesetEntry>[
+          ProjectTilesetEntry(
+            id: 'water-tileset',
+            name: 'Water',
+            relativePath: 'tilesets/water.png',
+          ),
+        ],
+        pathPresets: const <ProjectPathPreset>[
+          ProjectPathPreset(
+            id: 'water-base',
+            name: 'Water Base',
+            tilesetId: 'water-tileset',
+            variants: <PathPresetVariantMapping>[],
+          ),
+        ],
+        pathPatternPresets: [
+          ProjectPathPatternPreset(
+            id: 'water-pattern',
+            name: 'Water Pattern',
+            basePathPresetId: 'water-base',
+            centerPattern: PathCenterPattern(
+              size: PathCenterPatternSize(width: 2, height: 2),
+              cells: [
+                PathCenterPatternCell(
+                  localX: 0,
+                  localY: 0,
+                  frames: const [
+                    TilesetVisualFrame(source: TilesetSourceRect(x: 5, y: 0)),
+                  ],
+                ),
+                PathCenterPatternCell(
+                  localX: 1,
+                  localY: 0,
+                  frames: const [
+                    TilesetVisualFrame(source: TilesetSourceRect(x: 6, y: 0)),
+                  ],
+                ),
+                PathCenterPatternCell(
+                  localX: 0,
+                  localY: 1,
+                  frames: const [
+                    TilesetVisualFrame(source: TilesetSourceRect(x: 5, y: 1)),
+                  ],
+                ),
+                PathCenterPatternCell(
+                  localX: 1,
+                  localY: 1,
+                  frames: const [
+                    TilesetVisualFrame(source: TilesetSourceRect(x: 6, y: 1)),
+                  ],
+                ),
+              ],
+            ),
+          ),
+        ],
+        surfaceCatalog: ProjectSurfaceCatalog(),
+      );
+      final tilesetImage = await _testPathPatternTilesetImage();
+      final recorder = ui.PictureRecorder();
+      final canvas = ui.Canvas(recorder);
+
+      MapGridPainter(
+        map: map,
+        zoom: 1,
+        offset: ui.Offset.zero,
+        tileWidth: 16,
+        tileHeight: 16,
+        tilesetImagesById: {'water-tileset': tilesetImage},
+        sourceTileWidth: 16,
+        sourceTileHeight: 16,
+        tilesPerRowById: const <String, int>{'water-tileset': 12},
+        warps: const <MapWarp>[],
+        gameplayZones: const <MapGameplayZone>[],
+        connectionLabelsByDirection: const <MapConnectionDirection, String>{},
+        pathAutotileSetsByPresetId: {
+          'water-base': PathAutotileSet.defaultForTileset('water-tileset'),
+        },
+        terrainPresetsByType: const <TerrainType, ProjectTerrainPreset>{},
+        project: project,
+      ).paint(canvas, const ui.Size(64, 32));
+
+      final picture = recorder.endRecording();
+      final image = await picture.toImage(64, 32);
+      final pixels = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
+
+      void expectPixelColor(
+        int x,
+        int y, {
+        required bool Function(int value) red,
+        required bool Function(int value) green,
+        required bool Function(int value) blue,
+      }) {
+        final offset = ((y * image.width) + x) * 4;
+        expect(red(pixels!.getUint8(offset)), isTrue);
+        expect(green(pixels.getUint8(offset + 1)), isTrue);
+        expect(blue(pixels.getUint8(offset + 2)), isTrue);
+      }
+
+      expectPixelColor(
+        8,
+        8,
+        red: (value) => value > 220,
+        green: (value) => value < 20,
+        blue: (value) => value < 20,
+      );
+      expectPixelColor(
+        24,
+        8,
+        red: (value) => value < 20,
+        green: (value) => value > 220,
+        blue: (value) => value < 20,
+      );
+      expectPixelColor(
+        8,
+        24,
+        red: (value) => value < 20,
+        green: (value) => value < 20,
+        blue: (value) => value > 220,
+      );
+      expectPixelColor(
+        24,
+        24,
+        red: (value) => value > 220,
+        green: (value) => value > 220,
+        blue: (value) => value < 20,
+      );
+      expectPixelColor(
+        40,
+        8,
+        red: (value) => value > 220,
+        green: (value) => value < 20,
+        blue: (value) => value < 20,
+      );
+
+      picture.dispose();
+      image.dispose();
+      tilesetImage.dispose();
+    });
   });
 }
@@ -401,3 +567,32 @@ Future<ui.Image> _testTilesetImage() async {
   picture.dispose();
   return image;
 }
+
+Future<ui.Image> _testPathPatternTilesetImage() async {
+  final recorder = ui.PictureRecorder();
+  final canvas = ui.Canvas(recorder);
+  canvas.drawRect(
+    const ui.Rect.fromLTWH(0, 0, 192, 32),
+    ui.Paint()..color = const ui.Color(0xFF000000),
+  );
+  canvas.drawRect(
+    const ui.Rect.fromLTWH(80, 0, 16, 16),
+    ui.Paint()..color = const ui.Color(0xFFFF0000),
+  );
+  canvas.drawRect(
+    const ui.Rect.fromLTWH(96, 0, 16, 16),
+    ui.Paint()..color = const ui.Color(0xFF00FF00),
+  );
+  canvas.drawRect(
+    const ui.Rect.fromLTWH(80, 16, 16, 16),
+    ui.Paint()..color = const ui.Color(0xFF0000FF),
+  );
+  canvas.drawRect(
+    const ui.Rect.fromLTWH(96, 16, 16, 16),
+    ui.Paint()..color = const ui.Color(0xFFFFFF00),
+  );
+  final picture = recorder.endRecording();
+  final image = await picture.toImage(192, 32);
+  picture.dispose();
+  return image;
+}
```

### G. Sorties complètes des tests ciblés principaux

#### `dart test test/path_pattern_visual_resolution_test.dart --reporter expanded --no-color`

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

#### `flutter test test/path_pattern/path_pattern_editor_render_resolution_test.dart --reporter expanded`

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_pattern_editor_render_resolution_test.dart
00:00 +0: resolvePathPatternEditorRenderResolution sans PathPattern associé conserve le rendu legacy
00:00 +1: resolvePathPatternEditorRenderResolution un seul PathPattern associé utilise la résolution PathPattern
00:00 +2: resolvePathPatternEditorRenderResolution plusieurs PathPatterns associés tombent en fallback legacy sans crash
00:00 +3: resolvePathPatternEditorRenderResolution center-only 2x2 répète A B C D selon mapX mapY
00:00 +4: resolvePathPatternEditorRenderResolution variant configuré conserve ses frames legacy
00:00 +5: resolvePathPatternEditorRenderResolution variant manquant fallback sur centerPattern
00:00 +6: resolvePathPatternEditorRenderResolution cross utilise toujours centerPattern
00:00 +7: All tests passed!
```

#### `flutter test test/map_grid_painter_test.dart --reporter expanded`

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/map_grid_painter_test.dart
00:00 +0: MapGridPainter foreground split helpers marks only non-collision cells of multi-tile placed elements as foreground
00:00 +1: MapGridPainter foreground split helpers routes split cells to the correct render pass deterministically
00:00 +2: MapGridPainter foreground split helpers routes project-element entities to the requested render pass
00:00 +3: MapGridPainter foreground split helpers paints SurfaceLayer static preview without atlas tile images
00:00 +4: MapGridPainter foreground split helpers paints SurfaceLayer with resolved atlas tile image when available
00:00 +5: MapGridPainter foreground split helpers paints SurfaceLayer atlas tile from current editor elapsed time
00:00 +6: MapGridPainter foreground split helpers paints path layer with center-only 2x2 PathPattern in canvas
00:00 +7: All tests passed!
```

### H. Ligne finale exacte des grosses régressions

- `flutter test test/path_pattern/ --reporter expanded` : `00:09 +139: All tests passed!`
- `dart analyze lib/src/operations lib/src/models test/path_pattern_visual_resolution_test.dart` : `No issues found!`
- `flutter analyze lib/src/features/path_studio test/path_pattern` : `No issues found! (ran in 2.2s)`

### I. Sortie analyze ciblée

```text
Analyzing operations, models, path_pattern_visual_resolution_test.dart...
No issues found!

Analyzing 2 items...
No issues found! (ran in 2.2s)
```

## 18. Auto-review

- Preuves solides:
  - helper de prod branché dans le painter;
  - test unit helper couvrant les 7 cas demandés;
  - test canvas réel prouvant la répétition center-only 2x2 visible;
  - régressions Path Studio inchangées et vertes.
- Limites conservées:
  - aucun changement runtime;
  - aucune mutation modèle/map storage;
  - ambiguïté multi-PathPattern traitée par fallback legacy (pas de sélection explicite UI).

## 19. Critique du prompt

- Prompt très précis, testable, avec non-objectifs explicites; il réduit nettement le risque de dérive.
- Le seul point lourd est la contrainte “evidence pack complet” combinée à de grosses suites `flutter test`; interprétation retenue: sorties complètes des tests principaux ciblés + ligne finale exacte des suites volumineuses.

## 20. Conclusion

Le Lot 29 est atteint:

- rendu éditeur PathLayer branché à `resolvePathPatternVisual(...)` via helper de prod;
- center-only 2x2 visible dans le canvas;
- variants manquants et `cross` fallback centerPattern;
- variant configuré conservé;
- legacy sans PathPattern inchangé;
- aucune modification runtime/ProjectManifest/codec;
- tests + analyze demandés exécutés et verts.

## Checklist finale

- [x] Audit initial réalisé.
- [x] AGENTS.md et agent_rules.md lus.
- [x] Ancienne roadmap Tall Grass ignorée.
- [x] Aucun faux test.
- [x] Aucun provider inventé.
- [x] Aucun repository/service ajouté.
- [x] Aucun fichier projet écrit.
- [x] Aucun FileProjectRepository utilisé.
- [x] Aucun ProjectManifest modifié.
- [x] Codecs PathPattern non modifiés.
- [x] Aucun generated file.
- [x] Aucun build_runner.
- [x] Aucun runtime / Flame modifié.
- [x] Rendu éditeur utilise resolvePathPatternVisual ou helper de prod équivalent.
- [x] Center-only 2×2 visible via résolution éditeur.
- [x] Variant manquant fallback centerPattern.
- [x] TerrainPathVariant.cross fallback centerPattern.
- [x] Variant configuré conserve rendu legacy.
- [x] Aucun mapping vide généré.
- [x] Aucun fallback persistant ajouté.
- [x] Ambiguïté plusieurs PathPatterns pour une base traitée sans crash.
- [x] Rendu legacy sans PathPattern inchangé.
- [x] Tests ciblés passent.
- [x] Régressions pertinentes passent ou échecs documentés.
- [x] Analyze ciblé passe.
- [x] Rapport final complet créé.
- [x] Auto-review faite.
- [x] Critique du prompt faite.
