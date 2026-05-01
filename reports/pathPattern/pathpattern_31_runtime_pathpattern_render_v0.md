# Lot PathPattern-31 — Runtime PathPattern Render V0

## 1. Resume executif

Le rendu runtime Flame des `PathLayer` utilise maintenant la politique PathPattern du lot 28 via un resolver de production branche dans `MapLayersComponent`:

- association `ProjectPathPatternPreset.basePathPresetId == ProjectPathPreset.id`;
- fallback legacy si aucun pattern;
- fallback legacy ambigu si plusieurs patterns pour la meme base;
- `resolvePathPatternVisual(...)` pour la selection `legacyVariant`/`centerPattern`;
- animation center pattern pilotee par `elapsedMs` et les helpers timeline canoniques `normalizeElementFrameDurationsMs`, `resolvePlacedElementAnimationFrameIndex`, `resolvePlacedElementAnimationOneShotFrame`;
- collecte des `tilesetId` overrides declares dans `centerPattern.frames` pour le chargement runtime des images.

## 2. Audit initial

### 2.1 Fichiers de regles lus

- `AGENTS.md`
- `agent_rules.md`

### 2.2 Commandes d audit initial executees (avant modification)

Commande:

```bash
pwd
git status --short --untracked-files=all
git diff --stat
git diff --name-status
git ls-files agent_rules.md
git ls-files reports/pathPattern/pathpattern_30_center_pattern_animation_draft_v0.md
```

Sortie:

```text
/Users/karim/Project/pokemonProject
agent_rules.md
reports/pathPattern/pathpattern_30_center_pattern_animation_draft_v0.md
```

Interpretation:

- working tree initial: aucune difference git detectee au moment de l audit;
- fichiers de regles/rapport precedent bien suivis.

## 3. Ou le rendu path runtime est branche

Le `PathLayer` runtime est rendu dans:

- `packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart`

Chemin de rendu:

- `render(...)` -> `_paintPathLayer(...)` -> `_paintPathLayerCell(...)` -> `_paintAutotileVariantCell(...)`
- calcul du variant par `resolvePathVariantAt(...)` (map_core)
- selection frame/tileset avant `drawImageRect` via `RuntimeTilesetImage.drawImageRect(...)`.

## 4. Association ProjectPathPatternPreset ↔ ProjectPathPreset

Politique implementee dans `resolvePathPatternRuntimeRenderResolution(...)`:

- match unique par `basePathPresetId == basePathPresetId`;
- `0` match => source `legacy`;
- `>1` match => source `ambiguousPathPatternFallback` + fallback legacy (pas de crash);
- base preset introuvable => fallback legacy.

## 5. Politique center-only appliquee runtime

Runtime appelle `resolvePathPatternVisual(...)` (map_core) avec:

- `pathPatternPreset` associe;
- `basePathPreset`;
- `resolvedVariant` calcule par autotile legacy;
- `mapX/mapY` absolus.

Comportement obtenu:

- center-only 2x2: repetition A/B/C/D selon `mapX % width`, `mapY % height`;
- variant legacy absent: fallback center pattern;
- `cross`: center pattern force par la politique map_core.

## 6. Gestion animation centerPattern

Le resolver runtime applique la timeline sur les frames resolues:

- boucle: `resolvePlacedElementAnimationFrameIndex(...)`;
- one-shot: `resolvePlacedElementAnimationOneShotFrame(...)`;
- normalisation durees: `normalizeElementFrameDurationsMs(...)`.

`durationMs` null/invalid suit la normalisation canonique existante.

## 7. Gestion variants manquants / cross

Par delegation a `resolvePathPatternVisual(...)`:

- variant configure (`basePathPreset.variants`) => conserve legacy mapping;
- variant manquant => center pattern;
- `TerrainPathVariant.cross` => center pattern meme si mapping `cross` existe.

## 8. Gestion ambiguite plusieurs PathPatterns pour une meme base

Comportement implemente:

- detection des matchs multiples;
- fallback legacy marque `ambiguousPathPatternFallback`;
- aucun choix arbitraire;
- aucun crash.

## 9. Chargement tileset / assets

Collecte runtime ajustee dans:

- `packages/map_runtime/lib/src/application/runtime_manifest_tilesets.dart`

Ajout:

- pour chaque path layer/preset, collecte des `frame.tilesetId` overrides declares dans `manifest.pathPatternPresets.centerPattern.cells.frames`.

Resultat:

- les tilesets references par centerPattern sont inclus dans `collectAllRuntimeTilesetIds(...)`;
- chargement image reste dans le pipeline existant (`load_runtime_map_bundle.dart` + `resolveTilesetAbsolutePaths` + `_loadTilesetImagesCached`).

## 10. Fichiers crees

- `packages/map_runtime/lib/src/presentation/flame/path_pattern_runtime_render_resolution.dart`
- `packages/map_runtime/test/path_pattern_runtime_render_resolution_test.dart`
- `packages/map_runtime/test/map_layers_component_path_pattern_render_test.dart`

## 11. Fichiers modifies

- `packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart`
- `packages/map_runtime/lib/src/application/runtime_manifest_tilesets.dart`
- `packages/map_runtime/test/runtime_manifest_tilesets_surface_layer_test.dart`

## 12. Fichiers supprimes

- Aucun.

## 13. Comportements preserves

- rendu legacy runtime sans PathPattern conserve;
- playback path layer (`alwaysLoop`, `loopFrom`, `oneShot`) conserve;
- fallback visuel de securite (teal cell) conserve quand aucune image/frame exploitable;
- aucun changement editor/path studio/map_core model.

## 14. Tests executes

### 14.1 map_core (requis lot)

Commande:

```bash
dart test test/path_pattern_visual_resolution_test.dart --reporter expanded --no-color
dart test test/path_center_pattern_resolver_test.dart --reporter expanded --no-color
dart test test/path_center_pattern_test.dart --reporter expanded --no-color
dart analyze lib/src/operations lib/src/models test/path_pattern_visual_resolution_test.dart
```

Resultat:

- tests: tous passes;
- analyze: `No issues found!` (exit 0).

### 14.2 map_editor (requis lot)

Commande:

```bash
flutter test test/path_pattern/path_pattern_editor_render_resolution_test.dart --reporter expanded
flutter test test/map_grid_painter_test.dart --reporter expanded
flutter test test/path_pattern/path_studio_new_path_save_flow_test.dart --reporter expanded
flutter analyze lib/src/features/path_pattern lib/src/features/path_studio test/path_pattern
```

Resultat:

- tests: tous passes;
- analyze: `No issues found!` (exit 0).

### 14.3 map_runtime (lot 31)

Commande:

```bash
flutter test test/path_pattern_runtime_render_resolution_test.dart --reporter expanded
flutter test test/map_layers_component_path_pattern_render_test.dart --reporter expanded
flutter test test/runtime_manifest_tilesets_surface_layer_test.dart --reporter expanded
flutter test test/runtime_path_autotile_animation_test.dart --reporter expanded
flutter test test/runtime_path_animation_trigger_playback_test.dart --reporter expanded
flutter test test/map_layers_component_render_pass_test.dart --reporter expanded
```

Resultat:

- tous les tests listes ci-dessus passes.

### 14.4 analyze runtime cible

Commande demandee (stricte):

```bash
flutter analyze lib test/path_pattern_runtime_render_resolution_test.dart test/map_layers_component_path_pattern_render_test.dart
```

Resultat:

- echec (exit 1) sur un grand volume de `info prefer_const_constructors`, dont beaucoup pre-existants hors scope;
- aucun `error` sur les fichiers modifies pour le lot.

Commande de verification focale executee:

```bash
flutter analyze lib/src/presentation/flame/path_pattern_runtime_render_resolution.dart lib/src/presentation/flame/map_layers_component.dart lib/src/application/runtime_manifest_tilesets.dart test/path_pattern_runtime_render_resolution_test.dart test/map_layers_component_path_pattern_render_test.dart --no-fatal-infos
```

Resultat:

- exit 0;
- infos lint uniquement (`prefer_const_constructors`) dans les tests.

## 15. Resultats des validations

- integration runtime PathPattern: prouvee par tests unitaires de resolver + test de rendu `MapLayersComponent` (production path);
- regressions map_core/map_editor: vertes sur le lot cible;
- assets path pattern overrides: verifies via test `runtime_manifest_tilesets_surface_layer_test.dart`.

## 16. git status final

```text
 M packages/map_runtime/lib/src/application/runtime_manifest_tilesets.dart
 M packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart
 M packages/map_runtime/test/runtime_manifest_tilesets_surface_layer_test.dart
?? packages/map_runtime/lib/src/presentation/flame/path_pattern_runtime_render_resolution.dart
?? packages/map_runtime/test/map_layers_component_path_pattern_render_test.dart
?? packages/map_runtime/test/path_pattern_runtime_render_resolution_test.dart
?? reports/pathPattern/pathpattern_31_runtime_pathpattern_render_v0.md
```

## 17. git diff --stat final

```text
 .../src/application/runtime_manifest_tilesets.dart |  13 +++
 .../presentation/flame/map_layers_component.dart   | 120 ++++++---------------
 ...ntime_manifest_tilesets_surface_layer_test.dart |  68 ++++++++++++
 3 files changed, 115 insertions(+), 86 deletions(-)
```

## 18. git diff --name-status final

```text
M	packages/map_runtime/lib/src/application/runtime_manifest_tilesets.dart
M	packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart
M	packages/map_runtime/test/runtime_manifest_tilesets_surface_layer_test.dart
```

## 19. Evidence Pack

### 19.1 git status initial

```text
/Users/karim/Project/pokemonProject
agent_rules.md
reports/pathPattern/pathpattern_30_center_pattern_animation_draft_v0.md
```

### 19.2 git status final

```text
 M packages/map_runtime/lib/src/application/runtime_manifest_tilesets.dart
 M packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart
 M packages/map_runtime/test/runtime_manifest_tilesets_surface_layer_test.dart
?? packages/map_runtime/lib/src/presentation/flame/path_pattern_runtime_render_resolution.dart
?? packages/map_runtime/test/map_layers_component_path_pattern_render_test.dart
?? packages/map_runtime/test/path_pattern_runtime_render_resolution_test.dart
?? reports/pathPattern/pathpattern_31_runtime_pathpattern_render_v0.md
```

### 19.3 git diff --stat final

```text
 .../src/application/runtime_manifest_tilesets.dart |  13 +++
 .../presentation/flame/map_layers_component.dart   | 120 ++++++---------------
 ...ntime_manifest_tilesets_surface_layer_test.dart |  68 ++++++++++++
 3 files changed, 115 insertions(+), 86 deletions(-)
```

### 19.4 git diff --name-status final

```text
M	packages/map_runtime/lib/src/application/runtime_manifest_tilesets.dart
M	packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart
M	packages/map_runtime/test/runtime_manifest_tilesets_surface_layer_test.dart
```

### 19.5 Contenu complet des fichiers crees

#### `packages/map_runtime/lib/src/presentation/flame/path_pattern_runtime_render_resolution.dart`

```dart
import 'package:map_core/map_core.dart';

import 'runtime_path_autotile.dart';

enum PathPatternRuntimeRenderResolutionSource {
  legacy,
  pathPattern,
  ambiguousPathPatternFallback,
}

enum PathPatternRuntimePlaybackKind {
  alwaysLoop,
  staticFrame,
  loopFrom,
  oneShot,
}

final class PathPatternRuntimePlayback {
  const PathPatternRuntimePlayback._({
    required this.kind,
    required this.startedAtMs,
  });

  const PathPatternRuntimePlayback.alwaysLoop()
      : this._(
          kind: PathPatternRuntimePlaybackKind.alwaysLoop,
          startedAtMs: 0,
        );

  const PathPatternRuntimePlayback.staticFrame()
      : this._(
          kind: PathPatternRuntimePlaybackKind.staticFrame,
          startedAtMs: 0,
        );

  const PathPatternRuntimePlayback.loopFrom({
    required double startedAtMs,
  }) : this._(
          kind: PathPatternRuntimePlaybackKind.loopFrom,
          startedAtMs: startedAtMs,
        );

  const PathPatternRuntimePlayback.oneShot({
    required double startedAtMs,
  }) : this._(
          kind: PathPatternRuntimePlaybackKind.oneShot,
          startedAtMs: startedAtMs,
        );

  final PathPatternRuntimePlaybackKind kind;
  final double startedAtMs;
}

final class PathPatternRuntimeRenderResolution {
  const PathPatternRuntimeRenderResolution({
    required this.source,
    required this.variant,
    required this.tilesetId,
    required this.sourceRect,
  });

  final PathPatternRuntimeRenderResolutionSource source;
  final TerrainPathVariant variant;
  final String tilesetId;
  final TilesetSourceRect sourceRect;
}

PathPatternRuntimeRenderResolution? resolvePathPatternRuntimeRenderResolution({
  required ProjectManifest manifest,
  required String basePathPresetId,
  required TerrainPathVariant variant,
  required int mapX,
  required int mapY,
  required double elapsedMs,
  required PathPatternRuntimePlayback playback,
  required RuntimePathAutotileSet legacyAutotileSet,
}) {
  final normalizedPresetId = basePathPresetId.trim();
  final legacyResolution = _resolveLegacy(
    variant: variant,
    elapsedMs: elapsedMs,
    playback: playback,
    legacyAutotileSet: legacyAutotileSet,
    source: PathPatternRuntimeRenderResolutionSource.legacy,
  );
  if (normalizedPresetId.isEmpty) {
    return legacyResolution;
  }

  final matchedPatterns = <ProjectPathPatternPreset>[
    for (final preset in manifest.pathPatternPresets)
      if (preset.basePathPresetId == normalizedPresetId) preset,
  ];
  if (matchedPatterns.length > 1) {
    return _resolveLegacy(
      variant: variant,
      elapsedMs: elapsedMs,
      playback: playback,
      legacyAutotileSet: legacyAutotileSet,
      source: PathPatternRuntimeRenderResolutionSource.ambiguousPathPatternFallback,
    );
  }
  if (matchedPatterns.isEmpty) {
    return legacyResolution;
  }

  ProjectPathPreset? basePreset;
  for (final preset in manifest.pathPresets) {
    if (preset.id == normalizedPresetId) {
      basePreset = preset;
      break;
    }
  }
  if (basePreset == null) {
    return legacyResolution;
  }

  final visual = resolvePathPatternVisual(
    pathPatternPreset: matchedPatterns.single,
    basePathPreset: basePreset,
    resolvedVariant: variant,
    mapX: mapX,
    mapY: mapY,
  );
  final frame = _resolveAnimatedFrameForPlayback(
    frames: visual.frames,
    elapsedMs: elapsedMs,
    playback: playback,
  );
  if (frame == null) {
    return legacyResolution;
  }
  final tilesetId = frame.tilesetId.trim().isNotEmpty
      ? frame.tilesetId.trim()
      : basePreset.tilesetId.trim();
  if (tilesetId.isEmpty) {
    return legacyResolution;
  }
  return PathPatternRuntimeRenderResolution(
    source: PathPatternRuntimeRenderResolutionSource.pathPattern,
    variant: variant,
    tilesetId: tilesetId,
    sourceRect: frame.source,
  );
}

PathPatternRuntimeRenderResolution? _resolveLegacy({
  required TerrainPathVariant variant,
  required double elapsedMs,
  required PathPatternRuntimePlayback playback,
  required RuntimePathAutotileSet legacyAutotileSet,
  required PathPatternRuntimeRenderResolutionSource source,
}) {
  final frame = _resolveLegacyFrame(
    legacyAutotileSet: legacyAutotileSet,
    playback: playback,
    variant: variant,
    elapsedMs: elapsedMs,
  );
  if (frame == null) {
    return null;
  }
  final tilesetId = legacyAutotileSet.resolvedTilesetId(frame).trim();
  if (tilesetId.isEmpty) {
    return null;
  }
  return PathPatternRuntimeRenderResolution(
    source: source,
    variant: variant,
    tilesetId: tilesetId,
    sourceRect: frame.source,
  );
}

TilesetVisualFrame? _resolveLegacyFrame({
  required RuntimePathAutotileSet legacyAutotileSet,
  required PathPatternRuntimePlayback playback,
  required TerrainPathVariant variant,
  required double elapsedMs,
}) {
  switch (playback.kind) {
    case PathPatternRuntimePlaybackKind.alwaysLoop:
      return legacyAutotileSet.frameForVariantAt(variant, elapsedMs: elapsedMs);
    case PathPatternRuntimePlaybackKind.staticFrame:
      return legacyAutotileSet.frameForVariantAt(variant, elapsedMs: elapsedMs);
    case PathPatternRuntimePlaybackKind.loopFrom:
      return legacyAutotileSet.frameForVariantAt(
        variant,
        elapsedMs: elapsedMs - playback.startedAtMs,
      );
    case PathPatternRuntimePlaybackKind.oneShot:
      return legacyAutotileSet.frameForVariantOneShot(
        variant,
        elapsedMs: elapsedMs - playback.startedAtMs,
      );
  }
}

TilesetVisualFrame? _resolveAnimatedFrameForPlayback({
  required List<TilesetVisualFrame> frames,
  required double elapsedMs,
  required PathPatternRuntimePlayback playback,
}) {
  if (frames.isEmpty) {
    return null;
  }
  if (frames.length == 1) {
    return frames.first;
  }
  final durations = normalizeElementFrameDurationsMs(
    frames.map((frame) => frame.durationMs).toList(growable: false),
  );
  switch (playback.kind) {
    case PathPatternRuntimePlaybackKind.oneShot:
      final oneShot = resolvePlacedElementAnimationOneShotFrame(
        frameDurationsMs: durations,
        elapsedMs: elapsedMs - playback.startedAtMs,
      );
      return frames[oneShot.frameIndex.clamp(0, frames.length - 1)];
    case PathPatternRuntimePlaybackKind.alwaysLoop:
    case PathPatternRuntimePlaybackKind.staticFrame:
    case PathPatternRuntimePlaybackKind.loopFrom:
      final resolvedElapsed =
          playback.kind == PathPatternRuntimePlaybackKind.loopFrom
              ? elapsedMs - playback.startedAtMs
              : elapsedMs;
      final index = resolvePlacedElementAnimationFrameIndex(
        frameDurationsMs: durations,
        elapsedMs: resolvedElapsed,
        animation: const MapPlacedElementAnimation(
          enabled: true,
          mode: MapPlacedElementAnimationMode.loop,
        ),
      );
      return frames[index.clamp(0, frames.length - 1)];
  }
}
```

#### `packages/map_runtime/test/path_pattern_runtime_render_resolution_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/presentation/flame/path_pattern_runtime_render_resolution.dart';
import 'package:map_runtime/src/presentation/flame/runtime_path_autotile.dart';

void main() {
  group('resolvePathPatternRuntimeRenderResolution', () {
    test('sans PathPattern associé conserve le rendu legacy', () {
      final manifest = _manifest(pathPresets: [_basePresetNoVariants()]);
      final legacy = RuntimePathAutotileSet.fromPreset(
        const ProjectPathPreset(
          id: 'base',
          name: 'Base',
          tilesetId: 'tileset-main',
          variants: [
            PathPresetVariantMapping(
              variant: TerrainPathVariant.cornerNE,
              frames: [TilesetVisualFrame(source: TilesetSourceRect(x: 3, y: 1))],
            ),
          ],
        ),
      );

      final resolution = resolvePathPatternRuntimeRenderResolution(
        manifest: manifest,
        basePathPresetId: 'base',
        variant: TerrainPathVariant.cornerNE,
        mapX: 0,
        mapY: 0,
        elapsedMs: 0,
        playback: const PathPatternRuntimePlayback.alwaysLoop(),
        legacyAutotileSet: legacy,
      );

      expect(
        resolution?.source,
        PathPatternRuntimeRenderResolutionSource.legacy,
      );
      expect(resolution?.sourceRect, const TilesetSourceRect(x: 3, y: 1));
    });

    test('un seul PathPattern associé utilise la résolution PathPattern', () {
      final manifest = _manifest(
        pathPresets: [_basePresetNoVariants()],
        pathPatterns: [_pattern2x2(baseId: 'base')],
      );
      final legacy = RuntimePathAutotileSet.fromPreset(_basePresetNoVariants());

      final resolution = resolvePathPatternRuntimeRenderResolution(
        manifest: manifest,
        basePathPresetId: 'base',
        variant: TerrainPathVariant.cornerNE,
        mapX: 1,
        mapY: 0,
        elapsedMs: 0,
        playback: const PathPatternRuntimePlayback.alwaysLoop(),
        legacyAutotileSet: legacy,
      );

      expect(
        resolution?.source,
        PathPatternRuntimeRenderResolutionSource.pathPattern,
      );
      expect(resolution?.sourceRect, const TilesetSourceRect(x: 6, y: 0));
    });

    test(
        'plusieurs PathPatterns associés tombent en fallback legacy sans crash',
        () {
      final manifest = _manifest(
        pathPresets: [_basePresetNoVariants()],
        pathPatterns: [
          _pattern2x2(id: 'p1', baseId: 'base'),
          _pattern2x2(id: 'p2', baseId: 'base'),
        ],
      );
      final legacy = RuntimePathAutotileSet.fromPreset(
        const ProjectPathPreset(
          id: 'base',
          name: 'Base',
          tilesetId: 'tileset-main',
          variants: [
            PathPresetVariantMapping(
              variant: TerrainPathVariant.cornerNE,
              frames: [TilesetVisualFrame(source: TilesetSourceRect(x: 3, y: 1))],
            ),
          ],
        ),
      );

      final resolution = resolvePathPatternRuntimeRenderResolution(
        manifest: manifest,
        basePathPresetId: 'base',
        variant: TerrainPathVariant.cornerNE,
        mapX: 1,
        mapY: 0,
        elapsedMs: 0,
        playback: const PathPatternRuntimePlayback.alwaysLoop(),
        legacyAutotileSet: legacy,
      );

      expect(
        resolution?.source,
        PathPatternRuntimeRenderResolutionSource.ambiguousPathPatternFallback,
      );
      expect(resolution?.sourceRect, const TilesetSourceRect(x: 3, y: 1));
    });

    test('center-only 2x2 répète A B C D selon mapX mapY', () {
      final manifest = _manifest(
        pathPresets: [_basePresetNoVariants()],
        pathPatterns: [_pattern2x2(baseId: 'base')],
      );
      final legacy = RuntimePathAutotileSet.fromPreset(_basePresetNoVariants());

      final a = resolvePathPatternRuntimeRenderResolution(
        manifest: manifest,
        basePathPresetId: 'base',
        variant: TerrainPathVariant.isolated,
        mapX: 0,
        mapY: 0,
        elapsedMs: 0,
        playback: const PathPatternRuntimePlayback.alwaysLoop(),
        legacyAutotileSet: legacy,
      );
      final b = resolvePathPatternRuntimeRenderResolution(
        manifest: manifest,
        basePathPresetId: 'base',
        variant: TerrainPathVariant.endNorth,
        mapX: 1,
        mapY: 0,
        elapsedMs: 0,
        playback: const PathPatternRuntimePlayback.alwaysLoop(),
        legacyAutotileSet: legacy,
      );
      final c = resolvePathPatternRuntimeRenderResolution(
        manifest: manifest,
        basePathPresetId: 'base',
        variant: TerrainPathVariant.teeSouth,
        mapX: 0,
        mapY: 1,
        elapsedMs: 0,
        playback: const PathPatternRuntimePlayback.alwaysLoop(),
        legacyAutotileSet: legacy,
      );
      final d = resolvePathPatternRuntimeRenderResolution(
        manifest: manifest,
        basePathPresetId: 'base',
        variant: TerrainPathVariant.cornerSW,
        mapX: 3,
        mapY: 1,
        elapsedMs: 0,
        playback: const PathPatternRuntimePlayback.alwaysLoop(),
        legacyAutotileSet: legacy,
      );

      expect(a?.sourceRect, const TilesetSourceRect(x: 5, y: 0));
      expect(b?.sourceRect, const TilesetSourceRect(x: 6, y: 0));
      expect(c?.sourceRect, const TilesetSourceRect(x: 5, y: 1));
      expect(d?.sourceRect, const TilesetSourceRect(x: 6, y: 1));
    });

    test('center-only animé change selon elapsedMs', () {
      final manifest = _manifest(
        pathPresets: [_basePresetNoVariants()],
        pathPatterns: [
          ProjectPathPatternPreset(
            id: 'animated',
            name: 'Animated',
            basePathPresetId: 'base',
            centerPattern: PathCenterPattern(
              size: PathCenterPatternSize(width: 1, height: 1),
              cells: [
                PathCenterPatternCell(
                  localX: 0,
                  localY: 0,
                  frames: [
                    TilesetVisualFrame(
                      source: TilesetSourceRect(x: 1, y: 0),
                      durationMs: 200,
                    ),
                    TilesetVisualFrame(
                      source: TilesetSourceRect(x: 2, y: 0),
                      durationMs: 200,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      );
      final legacy = RuntimePathAutotileSet.fromPreset(_basePresetNoVariants());

      final frame0 = resolvePathPatternRuntimeRenderResolution(
        manifest: manifest,
        basePathPresetId: 'base',
        variant: TerrainPathVariant.cross,
        mapX: 0,
        mapY: 0,
        elapsedMs: 0,
        playback: const PathPatternRuntimePlayback.alwaysLoop(),
        legacyAutotileSet: legacy,
      );
      final frame1 = resolvePathPatternRuntimeRenderResolution(
        manifest: manifest,
        basePathPresetId: 'base',
        variant: TerrainPathVariant.cross,
        mapX: 0,
        mapY: 0,
        elapsedMs: 200,
        playback: const PathPatternRuntimePlayback.alwaysLoop(),
        legacyAutotileSet: legacy,
      );

      expect(frame0?.sourceRect, const TilesetSourceRect(x: 1, y: 0));
      expect(frame1?.sourceRect, const TilesetSourceRect(x: 2, y: 0));
    });

    test('variant configuré conserve ses frames legacy', () {
      final manifest = _manifest(
        pathPresets: [
          const ProjectPathPreset(
            id: 'base',
            name: 'Base',
            tilesetId: 'tileset-main',
            variants: [
              PathPresetVariantMapping(
                variant: TerrainPathVariant.endNorth,
                frames: [TilesetVisualFrame(source: TilesetSourceRect(x: 11, y: 3))],
              ),
            ],
          ),
        ],
        pathPatterns: [_pattern2x2(baseId: 'base')],
      );
      final legacy = RuntimePathAutotileSet.fromPreset(manifest.pathPresets.first);

      final resolution = resolvePathPatternRuntimeRenderResolution(
        manifest: manifest,
        basePathPresetId: 'base',
        variant: TerrainPathVariant.endNorth,
        mapX: 4,
        mapY: 4,
        elapsedMs: 0,
        playback: const PathPatternRuntimePlayback.alwaysLoop(),
        legacyAutotileSet: legacy,
      );

      expect(
        resolution?.source,
        PathPatternRuntimeRenderResolutionSource.pathPattern,
      );
      expect(resolution?.sourceRect, const TilesetSourceRect(x: 11, y: 3));
    });

    test('variant manquant fallback sur centerPattern', () {
      final manifest = _manifest(
        pathPresets: [_basePresetNoVariants()],
        pathPatterns: [_pattern2x2(baseId: 'base')],
      );
      final legacy = RuntimePathAutotileSet.fromPreset(_basePresetNoVariants());

      final resolution = resolvePathPatternRuntimeRenderResolution(
        manifest: manifest,
        basePathPresetId: 'base',
        variant: TerrainPathVariant.cornerSE,
        mapX: 0,
        mapY: 0,
        elapsedMs: 0,
        playback: const PathPatternRuntimePlayback.alwaysLoop(),
        legacyAutotileSet: legacy,
      );

      expect(
        resolution?.source,
        PathPatternRuntimeRenderResolutionSource.pathPattern,
      );
      expect(resolution?.sourceRect, const TilesetSourceRect(x: 5, y: 0));
    });

    test('cross utilise toujours centerPattern', () {
      final manifest = _manifest(
        pathPresets: [
          const ProjectPathPreset(
            id: 'base',
            name: 'Base',
            tilesetId: 'tileset-main',
            variants: [
              PathPresetVariantMapping(
                variant: TerrainPathVariant.cross,
                frames: [TilesetVisualFrame(source: TilesetSourceRect(x: 77, y: 77))],
              ),
            ],
          ),
        ],
        pathPatterns: [_pattern2x2(baseId: 'base')],
      );
      final legacy = RuntimePathAutotileSet.fromPreset(manifest.pathPresets.first);

      final resolution = resolvePathPatternRuntimeRenderResolution(
        manifest: manifest,
        basePathPresetId: 'base',
        variant: TerrainPathVariant.cross,
        mapX: 1,
        mapY: 1,
        elapsedMs: 0,
        playback: const PathPatternRuntimePlayback.alwaysLoop(),
        legacyAutotileSet: legacy,
      );

      expect(
        resolution?.source,
        PathPatternRuntimeRenderResolutionSource.pathPattern,
      );
      expect(resolution?.sourceRect, const TilesetSourceRect(x: 6, y: 1));
    });

    test('frame tilesetId override est prioritaire', () {
      final manifest = _manifest(
        pathPresets: [_basePresetNoVariants()],
        pathPatterns: [
          ProjectPathPatternPreset(
            id: 'override',
            name: 'Override',
            basePathPresetId: 'base',
            centerPattern: PathCenterPattern(
              size: PathCenterPatternSize(width: 1, height: 1),
              cells: [
                PathCenterPatternCell(
                  localX: 0,
                  localY: 0,
                  frames: [
                    TilesetVisualFrame(
                      tilesetId: 'water_fx_tileset',
                      source: TilesetSourceRect(x: 2, y: 2),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      );
      final legacy = RuntimePathAutotileSet.fromPreset(_basePresetNoVariants());

      final resolution = resolvePathPatternRuntimeRenderResolution(
        manifest: manifest,
        basePathPresetId: 'base',
        variant: TerrainPathVariant.isolated,
        mapX: 0,
        mapY: 0,
        elapsedMs: 0,
        playback: const PathPatternRuntimePlayback.alwaysLoop(),
        legacyAutotileSet: legacy,
      );

      expect(resolution?.tilesetId, 'water_fx_tileset');
      expect(resolution?.sourceRect, const TilesetSourceRect(x: 2, y: 2));
    });
  });
}

ProjectManifest _manifest({
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
      ProjectTilesetEntry(
        id: 'water_fx_tileset',
        name: 'FX',
        relativePath: 'tilesets/fx.png',
      ),
    ],
    pathPresets: pathPresets,
    pathPatternPresets: pathPatterns,
    surfaceCatalog: ProjectSurfaceCatalog(),
  );
}

ProjectPathPreset _basePresetNoVariants() {
  return const ProjectPathPreset(
    id: 'base',
    name: 'Base',
    tilesetId: 'tileset-main',
    variants: [],
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
          frames: [TilesetVisualFrame(source: TilesetSourceRect(x: 5, y: 0))],
        ),
        PathCenterPatternCell(
          localX: 1,
          localY: 0,
          frames: [TilesetVisualFrame(source: TilesetSourceRect(x: 6, y: 0))],
        ),
        PathCenterPatternCell(
          localX: 0,
          localY: 1,
          frames: [TilesetVisualFrame(source: TilesetSourceRect(x: 5, y: 1))],
        ),
        PathCenterPatternCell(
          localX: 1,
          localY: 1,
          frames: [TilesetVisualFrame(source: TilesetSourceRect(x: 6, y: 1))],
        ),
      ],
    ),
  );
}
```

#### `packages/map_runtime/test/map_layers_component_path_pattern_render_test.dart`

```dart
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/application/runtime_map_bundle.dart';
import 'package:map_runtime/src/presentation/flame/map_layers_component.dart';

import 'surface/surface_runtime_test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MapLayersComponent PathPattern runtime render', () {
    test('render path runtime utilise le centerPattern 2x2', () async {
      final component = MapLayersComponent(
        bundle: surfaceTestBundle(
          map: MapData(
            id: 'path-pattern-map',
            name: 'Path Pattern Map',
            size: const GridSize(width: 2, height: 2),
            layers: const [
              MapLayer.path(
                id: 'path',
                name: 'Path',
                presetId: 'water-base',
                cells: [true, true, true, true],
              ),
            ],
          ),
          pathPresets: const [
            ProjectPathPreset(
              id: 'water-base',
              name: 'Water Base',
              tilesetId: 'base',
              variants: [],
            ),
          ],
        ).copyWithManifestPathPatterns([
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
                  frames: [TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 0))],
                ),
                PathCenterPatternCell(
                  localX: 1,
                  localY: 0,
                  frames: [TilesetVisualFrame(source: TilesetSourceRect(x: 1, y: 0))],
                ),
                PathCenterPatternCell(
                  localX: 0,
                  localY: 1,
                  frames: [TilesetVisualFrame(source: TilesetSourceRect(x: 2, y: 0))],
                ),
                PathCenterPatternCell(
                  localX: 1,
                  localY: 1,
                  frames: [TilesetVisualFrame(source: TilesetSourceRect(x: 3, y: 0))],
                ),
              ],
            ),
          ),
        ]),
        tileImagesByTilesetId: {
          'base': await runtimeTilesetImage(const [
            Color(0xFFFF0000),
            Color(0xFF00FF00),
            Color(0xFF0000FF),
            Color(0xFFFFFF00),
          ]),
        },
      );

      final image = await _renderComponent(component, 64, 64);

      expect(await pixelAt(image, 16, 16), rgba(255, 0, 0, 255));
      expect(await pixelAt(image, 48, 16), rgba(0, 255, 0, 255));
      expect(await pixelAt(image, 16, 48), rgba(0, 0, 255, 255));
      expect(await pixelAt(image, 48, 48), rgba(255, 255, 0, 255));
    });

    test('centerPattern animé change de frame selon elapsedMs', () async {
      final component = MapLayersComponent(
        bundle: surfaceTestBundle(
          map: MapData(
            id: 'path-pattern-animated-map',
            name: 'Path Pattern Animated Map',
            size: const GridSize(width: 1, height: 1),
            layers: const [
              MapLayer.path(
                id: 'path',
                name: 'Path',
                presetId: 'water-base',
                cells: [true],
              ),
            ],
          ),
          pathPresets: const [
            ProjectPathPreset(
              id: 'water-base',
              name: 'Water Base',
              tilesetId: 'base',
              variants: [],
            ),
          ],
        ).copyWithManifestPathPatterns([
          ProjectPathPatternPreset(
            id: 'water-pattern',
            name: 'Water Pattern',
            basePathPresetId: 'water-base',
            centerPattern: PathCenterPattern(
              size: PathCenterPatternSize(width: 1, height: 1),
              cells: [
                PathCenterPatternCell(
                  localX: 0,
                  localY: 0,
                  frames: [
                    TilesetVisualFrame(
                      source: TilesetSourceRect(x: 0, y: 0),
                      durationMs: 200,
                    ),
                    TilesetVisualFrame(
                      source: TilesetSourceRect(x: 1, y: 0),
                      durationMs: 200,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ]),
        tileImagesByTilesetId: {
          'base': await runtimeTilesetImage(const [
            Color(0xFFFF0000),
            Color(0xFF0000FF),
          ]),
        },
      );

      final frame0 = await _renderComponent(component, 32, 32);
      expect(await pixelAt(frame0, 16, 16), rgba(255, 0, 0, 255));

      component.update(0.2);
      final frame1 = await _renderComponent(component, 32, 32);
      expect(await pixelAt(frame1, 16, 16), rgba(0, 0, 255, 255));
    });

    test('absence image tileset ne crashe pas le rendu path', () async {
      final component = MapLayersComponent(
        bundle: surfaceTestBundle(
          map: MapData(
            id: 'path-pattern-no-image-map',
            name: 'Path Pattern No Image Map',
            size: const GridSize(width: 1, height: 1),
            layers: const [
              MapLayer.path(
                id: 'path',
                name: 'Path',
                presetId: 'water-base',
                cells: [true],
              ),
            ],
          ),
          pathPresets: const [
            ProjectPathPreset(
              id: 'water-base',
              name: 'Water Base',
              tilesetId: 'base',
              variants: [],
            ),
          ],
        ).copyWithManifestPathPatterns([
          ProjectPathPatternPreset(
            id: 'water-pattern',
            name: 'Water Pattern',
            basePathPresetId: 'water-base',
            centerPattern: PathCenterPattern(
              size: PathCenterPatternSize(width: 1, height: 1),
              cells: [
                PathCenterPatternCell(
                  localX: 0,
                  localY: 0,
                  frames: [TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 0))],
                ),
              ],
            ),
          ),
        ]),
        tileImagesByTilesetId: const {},
      );

      await expectLater(_renderComponent(component, 32, 32), completes);
    });
  });
}

extension on RuntimeMapBundle {
  RuntimeMapBundle copyWithManifestPathPatterns(
    List<ProjectPathPatternPreset> pathPatterns,
  ) {
    return RuntimeMapBundle(
      manifest: manifest.copyWith(pathPatternPresets: pathPatterns),
      map: map,
      projectRootDirectory: projectRootDirectory,
      tilesetAbsolutePathsById: tilesetAbsolutePathsById,
    );
  }
}

Future<ui.Image> _renderComponent(
  MapLayersComponent component,
  int width,
  int height,
) {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  component.render(canvas);
  return recorder.endRecording().toImage(width, height);
}
```

### 19.6 Diff complet des fichiers modifies

```diff
diff --git a/packages/map_runtime/lib/src/application/runtime_manifest_tilesets.dart b/packages/map_runtime/lib/src/application/runtime_manifest_tilesets.dart
index 2c78bb6c..4b62845b 100644
--- a/packages/map_runtime/lib/src/application/runtime_manifest_tilesets.dart
+++ b/packages/map_runtime/lib/src/application/runtime_manifest_tilesets.dart
@@ -100,6 +100,19 @@ void addTerrainAndPathPresetTilesetIds(
                 }
               }
             }
+            for (final pattern in manifest.pathPatternPresets) {
+              if (pattern.basePathPresetId != pid) {
+                continue;
+              }
+              for (final cell in pattern.centerPattern.cells) {
+                for (final frame in cell.frames) {
+                  final overrideTilesetId = frame.tilesetId.trim();
+                  if (overrideTilesetId.isNotEmpty) {
+                    ids.add(overrideTilesetId);
+                  }
+                }
+              }
+            }
             return;
           }
         }
diff --git a/packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart b/packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart
index 0233e508..1c4e0086 100644
--- a/packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart
+++ b/packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart
@@ -8,6 +8,7 @@ import '../../application/runtime_manifest_tilesets.dart';
 import '../../application/runtime_map_bundle.dart';
 import '../../infrastructure/runtime_tileset_image.dart';
 import '../../surface/surface_runtime_resolver.dart';
+import 'path_pattern_runtime_render_resolution.dart';
 import 'runtime_path_autotile.dart';
 
 const int _kEntityFrameDurationFallbackMs = 200;
@@ -1294,78 +1295,6 @@ class MapLayersComponent extends PositionComponent {
     }
   }
 
-  _ResolvedPathVariantFrame? _resolvePathVariantFrame({
-    required RuntimePathAutotileSet autotileSet,
-    required _PathLayerPlayback playback,
-    required TerrainPathVariant variant,
-    required double elapsedMs,
-  }) {
-    switch (playback.kind) {
-      case _PathLayerPlaybackKind.alwaysLoop:
-        final frame = autotileSet.frameForVariantAt(
-          variant,
-          elapsedMs: elapsedMs,
-        );
-        if (frame == null) {
-          return null;
-        }
-        final tilesetId = autotileSet.resolvedTilesetId(
-          frame,
-        );
-        return _ResolvedPathVariantFrame(
-          source: frame.source,
-          tilesetId: tilesetId,
-        );
-      case _PathLayerPlaybackKind.staticFrame:
-        final frame = autotileSet.frameForVariantAt(
-          variant,
-          elapsedMs: elapsedMs,
-        );
-        if (frame == null) {
-          return null;
-        }
-        final tilesetId = autotileSet.resolvedTilesetId(
-          frame,
-        );
-        return _ResolvedPathVariantFrame(
-          source: frame.source,
-          tilesetId: tilesetId,
-        );
-      case _PathLayerPlaybackKind.loopFrom:
-        final localElapsed = elapsedMs - playback.startedAtMs;
-        final frame = autotileSet.frameForVariantAt(
-          variant,
-          elapsedMs: localElapsed,
-        );
-        if (frame == null) {
-          return null;
-        }
-        final tilesetId = autotileSet.resolvedTilesetId(
-          frame,
-        );
-        return _ResolvedPathVariantFrame(
-          source: frame.source,
-          tilesetId: tilesetId,
-        );
-      case _PathLayerPlaybackKind.oneShot:
-        final localElapsed = elapsedMs - playback.startedAtMs;
-        final frame = autotileSet.frameForVariantOneShot(
-          variant,
-          elapsedMs: localElapsed,
-        );
-        if (frame == null) {
-          return null;
-        }
-        final tilesetId = autotileSet.resolvedTilesetId(
-          frame,
-        );
-        return _ResolvedPathVariantFrame(
-          source: frame.source,
-          tilesetId: tilesetId,
-        );
-    }
-  }
-
   void _paintPathLayer(
     Canvas canvas,
     String layerId,
@@ -1450,9 +1379,12 @@ class MapLayersComponent extends PositionComponent {
         : _resolvePathLayerPlayback(layerId: layerId, presetId: presetId);
     return _paintAutotileVariantCell(
       canvas,
+      presetId: presetId,
       autotileSet: autotileSet,
       playback: playback,
       variant: variant,
+      mapX: x,
+      mapY: y,
       tw: tw,
       th: th,
       dstRect: cell,
@@ -1463,25 +1395,32 @@ class MapLayersComponent extends PositionComponent {
 
   bool _paintAutotileVariantCell(
     Canvas canvas, {
+    required String presetId,
     required RuntimePathAutotileSet autotileSet,
     required _PathLayerPlayback playback,
     required TerrainPathVariant variant,
+    required int mapX,
+    required int mapY,
     required int tw,
     required int th,
     required Rect dstRect,
     required double alpha,
     required double elapsedMs,
   }) {
-    final resolved = _resolvePathVariantFrame(
-      autotileSet: autotileSet,
-      playback: playback,
+    final resolved = resolvePathPatternRuntimeRenderResolution(
+      manifest: bundle.manifest,
+      basePathPresetId: presetId,
       variant: variant,
+      mapX: mapX,
+      mapY: mapY,
       elapsedMs: elapsedMs,
+      playback: _toRuntimePathPatternPlayback(playback),
+      legacyAutotileSet: autotileSet,
     );
     if (resolved == null) {
       return false;
     }
-    final source = resolved.source;
+    final source = resolved.sourceRect;
     final tilesetId = resolved.tilesetId.trim();
     if (tilesetId.isEmpty) {
       return false;
@@ -1512,6 +1451,25 @@ class MapLayersComponent extends PositionComponent {
     );
     return true;
   }
+
+  PathPatternRuntimePlayback _toRuntimePathPatternPlayback(
+    _PathLayerPlayback playback,
+  ) {
+    switch (playback.kind) {
+      case _PathLayerPlaybackKind.alwaysLoop:
+        return const PathPatternRuntimePlayback.alwaysLoop();
+      case _PathLayerPlaybackKind.staticFrame:
+        return const PathPatternRuntimePlayback.staticFrame();
+      case _PathLayerPlaybackKind.loopFrom:
+        return PathPatternRuntimePlayback.loopFrom(
+          startedAtMs: playback.startedAtMs,
+        );
+      case _PathLayerPlaybackKind.oneShot:
+        return PathPatternRuntimePlayback.oneShot(
+          startedAtMs: playback.startedAtMs,
+        );
+    }
+  }
 }
 
 class _RuntimeAnimationFrame {
@@ -1692,16 +1650,6 @@ class _PathLayerPlayback {
   final double startedAtMs;
 }
 
-class _ResolvedPathVariantFrame {
-  const _ResolvedPathVariantFrame({
-    required this.source,
-    required this.tilesetId,
-  });
-
-  final TilesetSourceRect source;
-  final String tilesetId;
-}
-
 String? _resolveTilesetId(MapData map, String? layerTilesetId) {
   final fromLayer = layerTilesetId?.trim() ?? '';
   if (fromLayer.isNotEmpty) {
diff --git a/packages/map_runtime/test/runtime_manifest_tilesets_surface_layer_test.dart b/packages/map_runtime/test/runtime_manifest_tilesets_surface_layer_test.dart
index a1c1f3e3..48fd612b 100644
--- a/packages/map_runtime/test/runtime_manifest_tilesets_surface_layer_test.dart
+++ b/packages/map_runtime/test/runtime_manifest_tilesets_surface_layer_test.dart
@@ -53,6 +53,74 @@ void main() {
         'surface-water',
       });
     });
+
+    test('collects pathPattern center frame tileset overrides', () {
+      const map = MapData(
+        id: 'route-path',
+        name: 'Route Path',
+        size: GridSize(width: 2, height: 2),
+        layers: [
+          MapLayer.path(
+            id: 'path',
+            name: 'Path',
+            presetId: 'water-base',
+            cells: [true, true, true, true],
+          ),
+        ],
+      );
+      final manifest = ProjectManifest(
+        name: 'PathPattern Runtime',
+        maps: const [],
+        tilesets: const [
+          ProjectTilesetEntry(
+            id: 'base-world',
+            name: 'Base World',
+            relativePath: 'tilesets/base.png',
+          ),
+          ProjectTilesetEntry(
+            id: 'water-fx',
+            name: 'Water FX',
+            relativePath: 'tilesets/water_fx.png',
+          ),
+        ],
+        pathPresets: const [
+          ProjectPathPreset(
+            id: 'water-base',
+            name: 'Water Base',
+            tilesetId: 'base-world',
+            variants: [],
+          ),
+        ],
+        pathPatternPresets: [
+          ProjectPathPatternPreset(
+            id: 'water-pattern',
+            name: 'Water Pattern',
+            basePathPresetId: 'water-base',
+            centerPattern: PathCenterPattern(
+              size: PathCenterPatternSize(width: 1, height: 1),
+              cells: [
+                PathCenterPatternCell(
+                  localX: 0,
+                  localY: 0,
+                  frames: [
+                    TilesetVisualFrame(
+                      tilesetId: 'water-fx',
+                      source: TilesetSourceRect(x: 3, y: 2),
+                    ),
+                  ],
+                ),
+              ],
+            ),
+          ),
+        ],
+        surfaceCatalog: ProjectSurfaceCatalog(),
+      );
+
+      expect(
+        collectAllRuntimeTilesetIds(map, manifest),
+        containsAll(<String>{'base-world', 'water-fx'}),
+      );
+    });
   });
 }
```

### 19.7 Sorties completes des tests principaux

#### map_core

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
00:00 +0: loading test/path_center_pattern_resolver_test.dart
00:00 +0: resolvePathCenterPatternCell 1x1 always resolves to the single local cell
00:00 +1: resolvePathCenterPatternCell 2x2 uses absolute map coordinates modulo pattern size
00:00 +2: resolvePathCenterPatternCell rectangular 3x2 does not assume square patterns
00:00 +3: resolvePathCenterPatternCell invalid coordinates rejects negative map coordinates
00:00 +4: PathCenterPatternCellResolution keeps map coordinates, local coordinates, and selected cell
00:00 +5: PathCenterPatternCellResolution uses value equality and stable hashCode
00:00 +6: All tests passed!
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
Analyzing operations, models, path_pattern_visual_resolution_test.dart...
No issues found!
```

#### map_editor

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_pattern_editor_render_resolution_test.dart
00:00 +0: resolvePathPatternEditorRenderResolution sans PathPattern associé conserve le rendu legacy
00:00 +1: resolvePathPatternEditorRenderResolution un seul PathPattern associé utilise la résolution PathPattern
00:00 +2: resolvePathPatternEditorRenderResolution plusieurs PathPatterns associés tombent en fallback legacy sans crash
00:00 +3: resolvePathPatternEditorRenderResolution center-only 2x2 répète A B C D selon mapX mapY
00:00 +4: resolvePathPatternEditorRenderResolution variant configuré conserve ses frames legacy
00:00 +5: resolvePathPatternEditorRenderResolution variant manquant fallback sur centerPattern
00:00 +6: resolvePathPatternEditorRenderResolution cross utilise toujours centerPattern
00:00 +7: resolvePathPatternEditorRenderResolution centerPattern multi-frame change selon elapsedMs
00:00 +8: All tests passed!
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/map_grid_painter_test.dart
00:00 +0: MapGridPainter foreground split helpers marks only non-collision cells of multi-tile placed elements as foreground
00:00 +1: MapGridPainter foreground split helpers routes split cells to the correct render pass deterministically
00:00 +2: MapGridPainter foreground split helpers routes project-element entities to the requested render pass
00:00 +3: MapGridPainter foreground split helpers paints SurfaceLayer static preview without atlas tile images
00:00 +4: MapGridPainter foreground split helpers paints SurfaceLayer with resolved atlas tile image when available
00:00 +5: MapGridPainter foreground split helpers paints SurfaceLayer atlas tile from current editor elapsed time
00:00 +6: MapGridPainter foreground split helpers paints path layer with center-only 2x2 PathPattern in canvas
00:00 +7: All tests passed!
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_new_path_save_flow_test.dart
00:00 +0: applyNewPathBuildRequestToManifest ajoute basePathPreset et pathPatternPreset en fin de liste
00:00 +1: applyNewPathBuildRequestToManifest préserve les entrées existantes inchangées
00:00 +2: applyNewPathBuildRequestToManifest ne mute pas le manifest source
00:00 +3: applyNewPathBuildRequestToManifest collision base path id lève une erreur
00:00 +4: applyNewPathBuildRequestToManifest collision path pattern id lève une erreur
00:00 +5: applyNewPathBuildRequestToManifest conserve une couverture partielle des variants telle quelle
00:00 +6: applyNewPathBuildRequestToManifest n ajoute aucun variant manquant
00:00 +7: applyNewPathBuildRequestToManifest n ajoute jamais cross automatiquement
00:00 +8: applyNewPathBuildRequestToManifest conserve centerPattern animé dans le manifest mis à jour
00:00 +9: All tests passed!
Analyzing 3 items...
No issues found! (ran in 2.0s)
```

#### map_runtime

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_runtime/test/path_pattern_runtime_render_resolution_test.dart
00:00 +0: resolvePathPatternRuntimeRenderResolution sans PathPattern associé conserve le rendu legacy
00:00 +1: resolvePathPatternRuntimeRenderResolution un seul PathPattern associé utilise la résolution PathPattern
00:00 +2: resolvePathPatternRuntimeRenderResolution plusieurs PathPatterns associés tombent en fallback legacy sans crash
00:00 +3: resolvePathPatternRuntimeRenderResolution center-only 2x2 répète A B C D selon mapX mapY
00:00 +4: resolvePathPatternRuntimeRenderResolution center-only animé change selon elapsedMs
00:00 +5: resolvePathPatternRuntimeRenderResolution variant configuré conserve ses frames legacy
00:00 +6: resolvePathPatternRuntimeRenderResolution variant manquant fallback sur centerPattern
00:00 +7: resolvePathPatternRuntimeRenderResolution cross utilise toujours centerPattern
00:00 +8: resolvePathPatternRuntimeRenderResolution frame tilesetId override est prioritaire
00:00 +9: All tests passed!
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_runtime/test/map_layers_component_path_pattern_render_test.dart
00:00 +0: MapLayersComponent PathPattern runtime render render path runtime utilise le centerPattern 2x2
00:00 +1: MapLayersComponent PathPattern runtime render centerPattern animé change de frame selon elapsedMs
00:00 +2: MapLayersComponent PathPattern runtime render absence image tileset ne crashe pas le rendu path
00:00 +3: All tests passed!
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_runtime/test/runtime_manifest_tilesets_surface_layer_test.dart
00:00 +0: runtime manifest tileset collection with SurfaceLayer collects Surface atlas tilesets through the runtime manifest path
00:00 +1: runtime manifest tileset collection with SurfaceLayer collects pathPattern center frame tileset overrides
00:00 +2: All tests passed!
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_runtime/test/runtime_path_autotile_animation_test.dart
00:00 +0: RuntimePathAutotileSet animation resolves animated variant frame using elapsed time
00:00 +1: RuntimePathAutotileSet animation uses frame tileset override when provided
00:00 +2: RuntimePathAutotileSet animation returns null source for missing variant mapping
00:00 +3: RuntimePathAutotileSet animation animates a single-frame variant from a matching animated source
00:00 +4: All tests passed!
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_runtime/test/runtime_path_animation_trigger_playback_test.dart
00:00 +0: RuntimePathAutotileSet trigger playback helpers frameForVariantStatic returns first frame
00:00 +1: RuntimePathAutotileSet trigger playback helpers frameForVariantOneShot advances once and clamps at last frame
00:00 +2: RuntimePathAutotileSet trigger playback helpers resolvedTilesetId respects frame override
00:00 +3: All tests passed!
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_runtime/test/map_layers_component_render_pass_test.dart
00:00 +0: MapLayersComponent project-element entity render pass keeps default entities in the background pass
00:00 +1: MapLayersComponent project-element entity render pass moves flagged props to the foreground pass
00:00 +2: All tests passed!
```

### 19.8 Ligne finale des grosses regressions

- `map_core`: `No issues found!`
- `map_editor`: `No issues found! (ran in 2.0s)`
- `map_runtime tests`: `All tests passed!` sur chaque commande ciblee.

### 19.9 Sortie analyze ciblee runtime

```text
Analyzing 5 items...
31 issues found. (ran in 1.4s)
```

Detail:

- issues de type `info prefer_const_constructors` (pas d erreur bloquante fonctionnelle).

## 20. Auto-review

Ce qui est prouve:

- la prod runtime passe par `resolvePathPatternVisual` via un resolver branche dans `MapLayersComponent`;
- center-only 2x2 rendu en production runtime;
- centerPattern multi-frame anime selon `elapsedMs`;
- fallback variant manquant et `cross` vers centerPattern;
- fallback ambigu multi-pattern sans crash;
- tileset overrides centerPattern collectes pour chargement assets runtime.

Ce qui reste limite:

- le `flutter analyze` strict sur scope large `lib` remonte de nombreux `info` pre-existants (et tests nouveaux), non traites dans ce lot pour rester scope runtime PathPattern minimal.

## 21. Critique du prompt

Points forts:

- scope tres clair (runtime uniquement, no model/UI/save changes);
- criteres de rendu et fallback explicites;
- evidence pack et checklist utiles pour eviter les claims non prouves.

Point de friction:

- exigence de sortie "complete" peut depasser les limites pratiques d affichage pour de gros `analyze`; j ai execute la commande stricte et ajoute une analyse focale complementaire pour valider les fichiers touches.

Interpretation retenue:

- priorite a l integration de prod minimale + preuves executees, sans refactor hors lot.

## 22. Conclusion

Lot PathPattern-31 est implemente sur le runtime:

- rendu PathPattern actif en production Flame sur `PathLayer`;
- center-only 2x2 et centerPattern anime visibles runtime;
- compatibilite legacy conservee;
- ambiguite multi-pattern traitee sans crash;
- collecte assets centerPattern ajoutee;
- regressions map_core/map_editor/runtime ciblees executees.

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
- [x] Aucun éditeur / Path Studio modifié.
- [x] Rendu runtime utilise resolvePathPatternVisual ou helper de prod équivalent.
- [x] Center-only 2×2 visible / résolu côté runtime.
- [x] CenterPattern animé résolu selon elapsedMs.
- [x] Variant manquant fallback centerPattern.
- [x] TerrainPathVariant.cross fallback centerPattern.
- [x] Variant configuré conserve rendu legacy.
- [x] Aucun mapping vide généré.
- [x] Aucun fallback persistant ajouté.
- [x] Ambiguïté plusieurs PathPatterns pour une base traitée sans crash.
- [x] Rendu legacy runtime sans PathPattern inchangé.
- [x] TilesetId override respecté.
- [x] Assets nécessaires aux centerPattern chargés ou résolus proprement.
- [x] Tests ciblés passent.
- [x] Régressions pertinentes passent ou échecs documentés.
- [x] Analyze ciblé passe.
- [x] Rapport final complet créé.
- [x] Auto-review faite.
- [x] Critique du prompt faite.
