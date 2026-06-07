# NS-SCENES-V1-95 — Evidence Pack

## 1. Gate 0 complet

```text
pwd
/Users/karim/Project/pokemonProject
```

```text
git branch --show-current
main
```

```text
git status --short --untracked-files=all
```

Sortie vide.

```text
git diff --stat
```

Sortie vide.

```text
git diff --name-only
```

Sortie vide.

```text
git log --oneline -n 15
35415a41 feat(map_editor): smooth left sidebar transitions & refactored narrative studio quick actions
0f1cce5c Merge branch 'feature/stabilize-sidebar'
cf774aef ui: stabilize World Explorer sidebar width and card ordering in Narrative Studio
cdd653e5 feat(narrative): auto-commit changes
50d3ca85 remove failures
48d6398d ui: collapse project explorer accordions by default and fix tests
4dbebbfe feat(narrative): auto-commit changes
76a312ec feat(narrative): auto-commit changes
9c5db6f0 feat(narrative): auto-commit changes
eb05d109 feat(narrative): auto-commit changes
3e767d80 feat(narrative): auto-commit changes
3a3689df feat(narrative): auto-commit changes
12e52f7a update selbrume
1ac4186f update selbrume
a085d128 feat(narrative): auto-commit changes
```

## 2. Fichiers lus

```text
AGENTS.md
agent_rules.md
reports/narrativeStudio/scenes/road_map_scenes.md
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/ns_scenes_v1_94_bis_cinematic_path_studio_water_fidelity_fix.md
reports/narrativeStudio/scenes/ns_scenes_v1_94_bis_evidence_pack.md
reports/narrativeStudio/scenes/ns_scenes_v1_94_cinematic_map_backdrop_layer_fidelity_renderer_v0.md
reports/narrativeStudio/scenes/ns_scenes_v1_94_evidence_pack.md
reports/narrativeStudio/scenes/ns_scenes_v1_92_cinematic_actor_display_preview_renderer_v0.md
reports/narrativeStudio/scenes/ns_scenes_v1_91_cinematic_actor_display_preview_read_model_v0.md
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_viewport_transform.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_layer_render_plan.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_layer_renderer.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_actor_display_preview_overlay.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart
packages/map_editor/test/cinematic_builder_workspace_test.dart
packages/map_editor/test/cinematics_library_workspace_test.dart
packages/map_core/lib/src/read_models/cinematic_actor_display_preview_model.dart
packages/map_core/lib/src/read_models/cinematic_map_backdrop_preview_model.dart
```

## 3. Notes sub-agents / passes specialisees

```text
A Current Backdrop / Viewport Audit:
- fit-map calcule par fittedCinematicMapBackdropRect.
- mini-map sur 55x55 car toute la map est reduite dans le viewport.
- actor overlay devait partager la meme frame que le backdrop.

B Framing Model Design:
- Option E retenue.
- fitMap conserve, scene ajoute, zoom local clamp 1.0..4.0.

C Focus Sources:
- selectedStep.actorId si acteur renderable.
- sinon bbox acteurs renderable.
- sinon centre map.

D Painter / Clip / Transform:
- une frame map clippee commune.
- background, acteurs V1-92, foreground V1-94 dans le meme Stack.

E UI / UX:
- controles simples : Carte entiere, Vue scene, zoom -, reset, zoom +, badge.
- wording runtime interdit evite.

F Tests / Visual Gate / Anti-scope:
- tests RED/GREEN, non-mutation, Path Studio/eau, alignement acteurs, Visual Gate.

G Product Reviewer:
- screenshot final montre eau, Vue scene, zoom, timeline et inspector.
```

## 4. RED test output

Commande initiale avant implementation :

```text
cd packages/map_editor
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --plain-name 'renders scene framing mode zoomed beyond full map fit'
```

Sortie RED :

```text
Expected: exactly one matching candidate
Actual: Found 0 widgets with text "Carte entière"
```

Interpretation : le test echouait bien parce que les controles V1-95 n'existaient pas encore.

## 5. GREEN test output

```text
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --plain-name 'renders scene framing mode zoomed beyond full map fit'
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/cinematic_builder_workspace_test.dart
00:01 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/cinematic_builder_workspace_test.dart
00:01 +0: renders scene framing mode zoomed beyond full map fit
00:02 +0: renders scene framing mode zoomed beyond full map fit
00:03 +0: renders scene framing mode zoomed beyond full map fit
00:03 +1: renders scene framing mode zoomed beyond full map fit
00:03 +1: All tests passed!
```

```text
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --plain-name 'uses Path Studio center pattern when a path layer references its base preset'
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/cinematic_builder_workspace_test.dart
00:01 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/cinematic_builder_workspace_test.dart
00:01 +0: uses Path Studio center pattern when a path layer references its base preset
00:02 +0: uses Path Studio center pattern when a path layer references its base preset
00:02 +1: uses Path Studio center pattern when a path layer references its base preset
00:02 +1: All tests passed!
```

```text
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart
00:25 +174: captures V1-84 cinematic map backdrop preview when requested
00:25 +174: captures V1-85 cinematic map backdrop visual primitives when requested
00:25 +175: captures V1-85 cinematic map backdrop visual primitives when requested
00:25 +175: captures V1-86 cinematic map backdrop visual composition when requested
00:25 +176: captures V1-86 cinematic map backdrop visual composition when requested
00:25 +176: captures V1-88 cinematic map backdrop real tile renderer when requested
00:25 +177: captures V1-88 cinematic map backdrop real tile renderer when requested
00:25 +177: captures V1-92 cinematic actor display preview renderer when requested
00:25 +178: captures V1-92 cinematic actor display preview renderer when requested
00:25 +178: captures V1-94 cinematic extended map backdrop visual gate when requested
00:25 +179: captures V1-94 cinematic extended map backdrop visual gate when requested
00:25 +179: captures V1-95 cinematic backdrop framing zoom controls when requested
00:25 +180: captures V1-95 cinematic backdrop framing zoom controls when requested
00:25 +180: All tests passed!
```

```text
flutter test --reporter=compact test/cinematics_library_workspace_test.dart
00:06 +17: adds an actor facing block from builder and refreshes summary
00:06 +17: keeps legacy bridge out of canonical builder shell
00:06 +18: keeps legacy bridge out of canonical builder shell
00:06 +18: edits metadata and deletes only unused canonicals
00:06 +19: edits metadata and deletes only unused canonicals
00:06 +19: captures V1-89 real tile backdrop integration screenshot when requested
00:06 +20: captures V1-89 real tile backdrop integration screenshot when requested
00:06 +20: captures V1-38 Cinematics Library screenshot when requested
00:06 +21: captures V1-38 Cinematics Library screenshot when requested
00:06 +21: All tests passed!
```

```text
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --plain-name 'captures V1-95 cinematic backdrop framing zoom controls when requested' --dart-define=NS_SCENES_V1_95_CAPTURE_CINEMATIC_BACKDROP_FRAMING_ZOOM_CONTROLS=true
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/cinematic_builder_workspace_test.dart
00:01 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/cinematic_builder_workspace_test.dart
00:01 +0: captures V1-95 cinematic backdrop framing zoom controls when requested
00:02 +0: captures V1-95 cinematic backdrop framing zoom controls when requested
00:02 +1: captures V1-95 cinematic backdrop framing zoom controls when requested
00:02 +1: All tests passed!
```

## 6. Core non-regression output

```text
dart test --reporter=compact test/cinematic_actor_display_preview_model_test.dart
00:00 +23: CinematicActorDisplayPreviewModel reports orphan initial placement
00:00 +24: CinematicActorDisplayPreviewModel reports orphan initial placement
00:00 +24: CinematicActorDisplayPreviewModel keeps model pure without Flutter Flame runtime imports
00:00 +25: CinematicActorDisplayPreviewModel keeps model pure without Flutter Flame runtime imports
00:00 +25: All tests passed!
```

```text
dart test --reporter=compact test/cinematic_map_backdrop_preview_model_test.dart
00:00 +17: CinematicMapBackdropPreviewModel builds viewport recommendation without Flutter or Flame
00:00 +18: CinematicMapBackdropPreviewModel builds viewport recommendation without Flutter or Flame
00:00 +18: CinematicMapBackdropPreviewModel does not require runtime state
00:00 +19: CinematicMapBackdropPreviewModel does not require runtime state
00:00 +19: All tests passed!
```

```text
dart test --reporter=compact test/cinematic_stage_map_source_catalog_test.dart
00:00 +5: CinematicStageMapSourceCatalog uses event id as fallback label only when title is empty
00:00 +6: CinematicStageMapSourceCatalog uses event id as fallback label only when title is empty
00:00 +6: CinematicStageMapSourceCatalog handles empty entity and event lists
00:00 +7: CinematicStageMapSourceCatalog handles empty entity and event lists
00:00 +7: All tests passed!
```

```text
dart test --reporter=compact test/cinematic_asset_test.dart
00:00 +12: CinematicAsset requires stable id and readable title
00:00 +13: CinematicAsset requires stable id and readable title
00:00 +13: CinematicAsset does not import Flutter, Flame, runtime, or editor packages
00:00 +14: CinematicAsset does not import Flutter, Flame, runtime, or editor packages
00:00 +14: All tests passed!
```

```text
dart test --reporter=compact test/project_manifest_cinematics_test.dart
00:00 +7: ProjectManifest cinematics integration keeps scenarios and scenes independent from cinematics
00:00 +8: ProjectManifest cinematics integration keeps scenarios and scenes independent from cinematics
00:00 +8: ProjectManifest cinematics integration rejects invalid cinematics JSON shape
00:00 +9: ProjectManifest cinematics integration rejects invalid cinematics JSON shape
00:00 +9: All tests passed!
```

```text
dart analyze
Analyzing map_core...
No issues found!
```

## 7. Analyze outputs

Analyse ciblee editor :

```text
dart analyze lib/src/ui/canvas/cinematics/cinematic_backdrop_preview_framing.dart lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart lib/src/ui/canvas/cinematics/cinematic_map_backdrop_render_pass.dart lib/src/ui/design_system/pokemap_dashboard_primitives.dart test/cinematic_builder_workspace_test.dart
Analyzing cinematic_backdrop_preview_framing.dart, cinematic_builder_workspace.dart, cinematic_map_backdrop_preview_panel.dart, cinematic_map_backdrop_render_pass.dart, pokemap_dashboard_primitives.dart, cinematic_builder_workspace_test.dart...
No issues found!
```

Analyse globale editor :

```text
flutter analyze
345 issues found. (ran in 2.8s)
```

Erreurs bloquantes hors lot :

```text
lib/src/application/services/pokemon_sdk_move_catalog_converter.dart: undefined_named_parameter / undefined_class / undefined_identifier autour de PokemonMoveAimedTarget, PokemonMoveFlags, PokemonMoveBattleStageMod, PokemonMoveStatus et champs PSDK.
lib/src/application/use_cases/sync_pokemon_sdk_moves_catalog_use_case.dart: fetchPokemonSdkStudioProjectPayload undefined.
test/application/services/pokemon_sdk_move_catalog_converter_test.dart: getters et types Pokemon SDK attendus non definis.
test/application/use_cases/sync_pokemon_sdk_moves_catalog_use_case_test.dart: getters/params Pokemon SDK attendus non definis.
```

## 8. Nouveau fichier complet

`packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_backdrop_preview_framing.dart`

```dart
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:map_core/map_core.dart';

import 'cinematic_map_backdrop_viewport_transform.dart';

enum CinematicBackdropPreviewFramingMode {
  fitMap,
  scene,
}

@immutable
final class CinematicBackdropPreviewFramingState {
  const CinematicBackdropPreviewFramingState({
    this.mode = CinematicBackdropPreviewFramingMode.fitMap,
    this.zoom = 1,
  });

  static const minZoom = 1.0;
  static const maxZoom = 4.0;
  static const zoomStep = 0.25;

  final CinematicBackdropPreviewFramingMode mode;
  final double zoom;

  double get clampedZoom => clampZoom(zoom);

  CinematicBackdropPreviewFramingState copyWith({
    CinematicBackdropPreviewFramingMode? mode,
    double? zoom,
  }) {
    return CinematicBackdropPreviewFramingState(
      mode: mode ?? this.mode,
      zoom: zoom ?? this.zoom,
    );
  }

  static double clampZoom(double value) {
    if (!value.isFinite) {
      return minZoom;
    }
    return value.clamp(minZoom, maxZoom).toDouble();
  }
}

@immutable
final class CinematicBackdropPreviewFocus {
  const CinematicBackdropPreviewFocus({
    required this.tileCenter,
    required this.reason,
    this.actorId,
  });

  final Offset tileCenter;
  final String reason;
  final String? actorId;
}

@immutable
final class CinematicBackdropPreviewFramingResult {
  const CinematicBackdropPreviewFramingResult({
    required this.mode,
    required this.zoom,
    required this.focus,
    required this.transform,
  });

  final CinematicBackdropPreviewFramingMode mode;
  final double zoom;
  final CinematicBackdropPreviewFocus focus;
  final CinematicMapBackdropViewportTransform transform;
}

CinematicBackdropPreviewFocus resolveCinematicBackdropPreviewFocus({
  required int mapWidth,
  required int mapHeight,
  CinematicActorDisplayPreviewModel? actorDisplayPreviewModel,
  CinematicTimelineStep? selectedStep,
}) {
  final safeMapWidth = math.max(1, mapWidth);
  final safeMapHeight = math.max(1, mapHeight);
  final selectedActorId = selectedStep?.actorId;
  if (selectedActorId != null && actorDisplayPreviewModel != null) {
    final actor = actorDisplayPreviewModel.actorById(selectedActorId);
    if (_hasResolvedActorTile(actor, safeMapWidth, safeMapHeight)) {
      return CinematicBackdropPreviewFocus(
        tileCenter: _actorTileCenter(actor!),
        reason: 'selectedActor',
        actorId: actor.actorId,
      );
    }
  }

  final actors = actorDisplayPreviewModel?.actors.where((actor) {
    return _hasResolvedActorTile(actor, safeMapWidth, safeMapHeight);
  }).toList();
  if (actors != null && actors.isNotEmpty) {
    var minX = actors.first.position.x!.toDouble();
    var maxX = minX + 1;
    var minY = actors.first.position.y!.toDouble();
    var maxY = minY + 1;
    for (final actor in actors.skip(1)) {
      final x = actor.position.x!.toDouble();
      final y = actor.position.y!.toDouble();
      minX = math.min(minX, x);
      maxX = math.max(maxX, x + 1);
      minY = math.min(minY, y);
      maxY = math.max(maxY, y + 1);
    }
    return CinematicBackdropPreviewFocus(
      tileCenter: Offset((minX + maxX) / 2, (minY + maxY) / 2),
      reason: 'actorBounds',
    );
  }

  return CinematicBackdropPreviewFocus(
    tileCenter: Offset(safeMapWidth / 2, safeMapHeight / 2),
    reason: 'mapCenter',
  );
}

CinematicBackdropPreviewFramingResult resolveCinematicBackdropPreviewFraming({
  required Size viewportSize,
  required Size mapPixelSize,
  required int mapWidth,
  required int mapHeight,
  required CinematicBackdropPreviewFramingState state,
  required CinematicBackdropPreviewFocus focus,
}) {
  if (viewportSize.isEmpty ||
      !viewportSize.isFinite ||
      mapPixelSize.width <= 0 ||
      mapPixelSize.height <= 0 ||
      mapWidth <= 0 ||
      mapHeight <= 0) {
    return CinematicBackdropPreviewFramingResult(
      mode: state.mode,
      zoom: state.clampedZoom,
      focus: focus,
      transform: CinematicMapBackdropViewportTransform(
        frame: Rect.zero,
        mapWidth: mapWidth,
        mapHeight: mapHeight,
      ),
    );
  }

  final fitFrame = fittedCinematicMapBackdropRect(
    availableSize: viewportSize,
    mapPixelSize: mapPixelSize,
  );
  if (state.mode == CinematicBackdropPreviewFramingMode.fitMap ||
      fitFrame.isEmpty) {
    return CinematicBackdropPreviewFramingResult(
      mode: CinematicBackdropPreviewFramingMode.fitMap,
      zoom: CinematicBackdropPreviewFramingState.minZoom,
      focus: focus,
      transform: CinematicMapBackdropViewportTransform(
        frame: fitFrame,
        mapWidth: mapWidth,
        mapHeight: mapHeight,
      ),
    );
  }

  final fitScale = fitFrame.width / mapPixelSize.width;
  final tilePixelWidth = mapPixelSize.width / mapWidth;
  final tilePixelHeight = mapPixelSize.height / mapHeight;
  const targetSceneTileWidth = 22.0;
  const targetSceneTileHeight = 14.0;
  final sceneBaseScale = math.max(
    viewportSize.width / (targetSceneTileWidth * tilePixelWidth),
    viewportSize.height / (targetSceneTileHeight * tilePixelHeight),
  );
  final scale = math.max(fitScale, sceneBaseScale) * state.clampedZoom;
  final frameSize = Size(
    mapPixelSize.width * scale,
    mapPixelSize.height * scale,
  );
  final focusTile = Offset(
    focus.tileCenter.dx.clamp(0.0, mapWidth.toDouble()).toDouble(),
    focus.tileCenter.dy.clamp(0.0, mapHeight.toDouble()).toDouble(),
  );
  final focusPixel = Offset(
    focusTile.dx * tilePixelWidth,
    focusTile.dy * tilePixelHeight,
  );
  final desiredLeft = viewportSize.width / 2 - focusPixel.dx * scale;
  final desiredTop = viewportSize.height / 2 - focusPixel.dy * scale;
  final frame = Rect.fromLTWH(
    _clampFrameOffset(desiredLeft, viewportSize.width, frameSize.width),
    _clampFrameOffset(desiredTop, viewportSize.height, frameSize.height),
    frameSize.width,
    frameSize.height,
  );
  return CinematicBackdropPreviewFramingResult(
    mode: CinematicBackdropPreviewFramingMode.scene,
    zoom: state.clampedZoom,
    focus: focus,
    transform: CinematicMapBackdropViewportTransform(
      frame: frame,
      mapWidth: mapWidth,
      mapHeight: mapHeight,
    ),
  );
}

bool _hasResolvedActorTile(
  CinematicActorDisplayPreviewActor? actor,
  int mapWidth,
  int mapHeight,
) {
  final x = actor?.position.x;
  final y = actor?.position.y;
  if (actor == null || !actor.isRenderable || x == null || y == null) {
    return false;
  }
  return x >= 0 && y >= 0 && x < mapWidth && y < mapHeight;
}

Offset _actorTileCenter(CinematicActorDisplayPreviewActor actor) {
  return Offset(actor.position.x! + 0.5, actor.position.y! + 0.5);
}

double _clampFrameOffset(
  double desired,
  double viewportExtent,
  double frameExtent,
) {
  if (frameExtent <= viewportExtent) {
    return (viewportExtent - frameExtent) / 2;
  }
  return desired.clamp(viewportExtent - frameExtent, 0.0).toDouble();
}
```

## 9. Code modifie — Builder state

`packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart`

```diff
+import 'cinematic_backdrop_preview_framing.dart';
...
+  CinematicBackdropPreviewFramingState _backdropFramingState =
+      const CinematicBackdropPreviewFramingState();
...
+      _backdropFramingState = const CinematicBackdropPreviewFramingState();
...
+                                backdropFramingState: _backdropFramingState,
+                                onBackdropFramingModeChanged: (mode) {
+                                  setState(() {
+                                    _backdropFramingState =
+                                        _backdropFramingState.copyWith(
+                                      mode: mode,
+                                    );
+                                  });
+                                },
+                                onBackdropFramingZoomChanged: (zoom) {
+                                  setState(() {
+                                    _backdropFramingState =
+                                        _backdropFramingState.copyWith(
+                                      zoom: zoom,
+                                    );
+                                  });
+                                },
...
+  final CinematicBackdropPreviewFramingState backdropFramingState;
+  final ValueChanged<CinematicBackdropPreviewFramingMode>
+      onBackdropFramingModeChanged;
+  final ValueChanged<double> onBackdropFramingZoomChanged;
...
+              framingState: backdropFramingState,
+              selectedStep: selectedStep,
+              onFramingModeChanged: onBackdropFramingModeChanged,
+              onFramingZoomChanged: onBackdropFramingZoomChanged,
```

## 10. Code modifie — Preview panel controls et transform partage

`packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart`

```dart
class _BackdropFramingControls extends StatelessWidget {
  const _BackdropFramingControls({
    required this.state,
    required this.compact,
    this.onModeChanged,
    this.onZoomChanged,
  });

  final CinematicBackdropPreviewFramingState state;
  final bool compact;
  final ValueChanged<CinematicBackdropPreviewFramingMode>? onModeChanged;
  final ValueChanged<double>? onZoomChanged;

  @override
  Widget build(BuildContext context) {
    final isSceneMode = state.mode == CinematicBackdropPreviewFramingMode.scene;
    final zoom = state.clampedZoom;
    final canAdjustZoom = isSceneMode && onZoomChanged != null;
    final buttonSize = compact ? 28.0 : 30.0;
    return Wrap(
      key: const ValueKey('cinematic-builder-map-backdrop-framing-controls'),
      spacing: compact ? 6 : 8,
      runSpacing: compact ? 5 : 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        PokeMapSegmentedTabs(
          tabs: [
            PokeMapSegmentedTab(
              key: const ValueKey(
                'cinematic-builder-map-backdrop-fit-map-mode',
              ),
              label: 'Carte entière',
              icon: CupertinoIcons.map,
              selected:
                  state.mode == CinematicBackdropPreviewFramingMode.fitMap,
              onTap: onModeChanged == null
                  ? null
                  : () {
                      onModeChanged!(
                        CinematicBackdropPreviewFramingMode.fitMap,
                      );
                    },
            ),
            PokeMapSegmentedTab(
              key: const ValueKey(
                'cinematic-builder-map-backdrop-scene-mode',
              ),
              label: 'Vue scène',
              icon: CupertinoIcons.viewfinder,
              selected: isSceneMode,
              onTap: onModeChanged == null
                  ? null
                  : () {
                      onModeChanged!(
                        CinematicBackdropPreviewFramingMode.scene,
                      );
                    },
            ),
          ],
        ),
        PokeMapIconButton(
          key: const ValueKey('cinematic-builder-map-backdrop-zoom-out'),
          tooltip: 'Zoom -',
          size: buttonSize,
          variant: PokeMapIconButtonVariant.soft,
          onPressed: canAdjustZoom &&
                  zoom > CinematicBackdropPreviewFramingState.minZoom
              ? () {
                  onZoomChanged!(
                    CinematicBackdropPreviewFramingState.clampZoom(
                      zoom - CinematicBackdropPreviewFramingState.zoomStep,
                    ),
                  );
                }
              : null,
          icon: const Icon(CupertinoIcons.minus),
        ),
        PokeMapIconButton(
          key: const ValueKey('cinematic-builder-map-backdrop-zoom-reset'),
          tooltip: 'Réinitialiser le zoom',
          size: buttonSize,
          variant: PokeMapIconButtonVariant.soft,
          onPressed: canAdjustZoom &&
                  zoom != CinematicBackdropPreviewFramingState.minZoom
              ? () {
                  onZoomChanged!(
                    CinematicBackdropPreviewFramingState.minZoom,
                  );
                }
              : null,
          icon: const Icon(CupertinoIcons.arrow_counterclockwise),
        ),
        PokeMapIconButton(
          key: const ValueKey('cinematic-builder-map-backdrop-zoom-in'),
          tooltip: 'Zoom +',
          size: buttonSize,
          variant: PokeMapIconButtonVariant.soft,
          onPressed: canAdjustZoom &&
                  zoom < CinematicBackdropPreviewFramingState.maxZoom
              ? () {
                  onZoomChanged!(
                    CinematicBackdropPreviewFramingState.clampZoom(
                      zoom + CinematicBackdropPreviewFramingState.zoomStep,
                    ),
                  );
                }
              : null,
          icon: const Icon(CupertinoIcons.plus),
        ),
        PokeMapBadge(
          key: const ValueKey('cinematic-builder-map-backdrop-zoom-label'),
          label: 'Zoom ${zoom.toStringAsFixed(2)}×',
          variant: isSceneMode
              ? PokeMapBadgeVariant.info
              : PokeMapBadgeVariant.neutral,
        ),
      ],
    );
  }
}
```

Frame partagee dans les branches bitmap/layer :

```dart
final focus = resolveCinematicBackdropPreviewFocus(
  mapWidth: plan.mapWidth,
  mapHeight: plan.mapHeight,
  actorDisplayPreviewModel: actorDisplayPreviewModel,
  selectedStep: selectedStep,
);
final framing = resolveCinematicBackdropPreviewFraming(
  viewportSize: constraints.biggest,
  mapPixelSize: Size(plan.pixelWidth, plan.pixelHeight),
  mapWidth: plan.mapWidth,
  mapHeight: plan.mapHeight,
  state: framingState,
  focus: focus,
);

return RepaintBoundary(
  key: const ValueKey(
    'cinematic-builder-map-backdrop-bitmap-viewport',
  ),
  child: ClipRRect(
    borderRadius: BorderRadius.circular(6),
    child: ClipRect(
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned.fromRect(
            rect: framing.transform.frame,
            child: SizedBox(
              key: const ValueKey(
                'cinematic-builder-map-backdrop-map-frame',
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  CustomPaint(...),
                  if (actorDisplayPreviewModel != null)
                    CinematicActorDisplayPreviewOverlay(...),
                  CustomPaint(...foreground...),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  ),
);
```

## 11. Code modifie — Render pass Path Studio/eau

`packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_render_pass.dart`

```diff
 enum CinematicMapBackdropRenderPass {
   terrain,
   path,
   surface,
   placedBackground,
   tileBackground,
   tileForeground,
   placedForeground,
 }

 extension CinematicMapBackdropRenderPassX on CinematicMapBackdropRenderPass {
   int get order => switch (this) {
         CinematicMapBackdropRenderPass.terrain => 0,
-        CinematicMapBackdropRenderPass.path => 1,
-        CinematicMapBackdropRenderPass.tileBackground => 2,
+        CinematicMapBackdropRenderPass.tileBackground => 1,
+        CinematicMapBackdropRenderPass.path => 2,
         CinematicMapBackdropRenderPass.surface => 3,
         CinematicMapBackdropRenderPass.placedBackground => 4,
         CinematicMapBackdropRenderPass.tileForeground => 5,
         CinematicMapBackdropRenderPass.placedForeground => 6,
       };
 }
```

## 12. Code modifie — Design system segmented tab keys

`packages/map_editor/lib/src/ui/design_system/pokemap_dashboard_primitives.dart`

```diff
 class PokeMapSegmentedTab {
   const PokeMapSegmentedTab({
+    this.key,
     required this.label,
     required this.selected,
     this.icon,
     this.onTap,
   });

+  final Key? key;
   final String label;
   final bool selected;
   final IconData? icon;
   final VoidCallback? onTap;
 }

 class _PokeMapSegmentedTabButton extends StatelessWidget {
-  const _PokeMapSegmentedTabButton({required this.tab});
+  _PokeMapSegmentedTabButton({required this.tab}) : super(key: tab.key);

   final PokeMapSegmentedTab tab;
...
       child: GestureDetector(
+        behavior: HitTestBehavior.opaque,
         onTap: enabled ? tab.onTap : null,
```

## 13. Tests V1-95 ajoutes

`packages/map_editor/test/cinematic_builder_workspace_test.dart`

```dart
testWidgets('renders scene framing mode zoomed beyond full map fit',
    (tester) async {
  _setLargeSurface(tester, _referenceTimelineSurfaceSize);
  final fixture = await _largeBackdropFixture();

  await _pumpBuilder(
    tester,
    _entry(fixture.project, fixture.asset.id),
    asset: fixture.asset,
    stageMapSourceCatalog: _stageMapSourceCatalog(mapData: fixture.mapData),
    backdropPreviewModel: fixture.backdropModel,
    backdropLayerRenderPlan: fixture.layerPlan,
  );

  expect(find.text('Carte entière'), findsOneWidget);
  expect(find.text('Vue scène'), findsOneWidget);
  expect(find.text('Zoom 1.00×'), findsOneWidget);

  final viewportFinder = find.byKey(
    const ValueKey('cinematic-builder-map-backdrop-bitmap-viewport'),
  );
  final frameFinder = find.byKey(
    const ValueKey('cinematic-builder-map-backdrop-map-frame'),
  );
  final viewportRect = tester.getRect(viewportFinder);
  final fitFrameRect = tester.getRect(frameFinder);
  expect(fitFrameRect.width, lessThanOrEqualTo(viewportRect.width + 0.5));
  expect(fitFrameRect.height, lessThanOrEqualTo(viewportRect.height + 0.5));

  await tester.tap(
    find.byKey(
      const ValueKey('cinematic-builder-map-backdrop-scene-mode'),
    ),
  );
  await tester.pumpAndSettle();

  final sceneFrameRect = tester.getRect(frameFinder);
  expect(sceneFrameRect.width, greaterThan(viewportRect.width));
  expect(sceneFrameRect.height, greaterThan(viewportRect.height));
  expect(find.text('Timeline par pistes'), findsOneWidget);
});

testWidgets(
    'zooms in and resets cinematic backdrop framing without mutating project or map',
    (tester) async {
  _setLargeSurface(tester, _referenceTimelineSurfaceSize);
  final fixture = await _largeBackdropFixture();
  final beforeProject = fixture.project.toJson();
  final beforeMapData = fixture.mapData.toJson();

  await _pumpBuilder(
    tester,
    _entry(fixture.project, fixture.asset.id),
    asset: fixture.asset,
    stageMapSourceCatalog: _stageMapSourceCatalog(mapData: fixture.mapData),
    backdropPreviewModel: fixture.backdropModel,
    backdropLayerRenderPlan: fixture.layerPlan,
  );

  await tester.tap(
    find.byKey(
      const ValueKey('cinematic-builder-map-backdrop-scene-mode'),
    ),
  );
  await tester.pumpAndSettle();
  final frameFinder = find.byKey(
    const ValueKey('cinematic-builder-map-backdrop-map-frame'),
  );
  final sceneFrameRect = tester.getRect(frameFinder);

  await tester.tap(
    find.byKey(const ValueKey('cinematic-builder-map-backdrop-zoom-in')),
  );
  await tester.pumpAndSettle();

  expect(find.text('Zoom 1.25×'), findsOneWidget);
  final zoomedFrameRect = tester.getRect(frameFinder);
  expect(zoomedFrameRect.width, greaterThan(sceneFrameRect.width));

  await tester.tap(
    find.byKey(const ValueKey('cinematic-builder-map-backdrop-zoom-reset')),
  );
  await tester.pumpAndSettle();

  expect(find.text('Zoom 1.00×'), findsOneWidget);
  final resetFrameRect = tester.getRect(frameFinder);
  expect(resetFrameRect.width, closeTo(sceneFrameRect.width, 1));
  expect(fixture.project.toJson(), beforeProject);
  expect(fixture.mapData.toJson(), beforeMapData);
});

testWidgets('keeps actor placeholders aligned after scene framing zoom',
    (tester) async {
  _setLargeSurface(tester, _referenceTimelineSurfaceSize);
  final tilesetImage = await _makeTestTilesetImage();
  final asset = _actorDisplayPreviewCinematic();
  final project = _project(cinematics: [asset]).copyWith(
    settings: const ProjectSettings(tileWidth: 8, tileHeight: 8),
    tilesets: const [
      ProjectTilesetEntry(
        id: 'lab_tiles',
        name: 'Lab tiles',
        relativePath: 'assets/tilesets/lab.png',
      ),
    ],
  );
  final stageMapData = _stageMapDataWithActorDisplayFixtures();
  final backdropModel = buildCinematicMapBackdropPreviewModel(
    asset: asset,
    stageMap: project.maps.single,
    mapData: stageMapData,
  );
  final layerPlan = buildCinematicMapBackdropLayerRenderPlan(
    mapData: stageMapData,
    manifest: project,
    tilesets: {
      'lab_tiles': CinematicResolvedTilesetAsset.available(
        tilesetId: 'lab_tiles',
        image: tilesetImage,
        tileWidth: 8,
        tileHeight: 8,
      ),
    },
  );
  final actorDisplayPreviewModel = buildCinematicActorDisplayPreviewModel(
    cinematic: asset,
    project: project,
    stageMap: project.maps.single,
    mapData: stageMapData,
    stageMapSourceCatalog: _stageMapSourceCatalog(mapData: stageMapData),
  );

  await _pumpBuilder(
    tester,
    _entry(project, 'cinematic_actor_display_preview'),
    asset: asset,
    stageMapSourceCatalog: _stageMapSourceCatalog(mapData: stageMapData),
    backdropPreviewModel: backdropModel,
    backdropLayerRenderPlan: layerPlan,
    actorDisplayPreviewModel: actorDisplayPreviewModel,
  );

  await tester.tap(
    find.byKey(
      const ValueKey('cinematic-builder-map-backdrop-scene-mode'),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(
    find.byKey(const ValueKey('cinematic-builder-map-backdrop-zoom-in')),
  );
  await tester.pumpAndSettle();

  final mapFrameRect = tester.getRect(
    find.byKey(const ValueKey('cinematic-builder-map-backdrop-map-frame')),
  );
  final actorRect = tester.getRect(
    find.byKey(
      const ValueKey('cinematic-builder-actor-display-actor-actor_lysa'),
    ),
  );
  final expectedAnchor = Offset(
    mapFrameRect.left + (8.5 * mapFrameRect.width / 12),
    mapFrameRect.top + (4 * mapFrameRect.height / 10),
  );
  expect(actorRect.center.dx, closeTo(expectedAnchor.dx, 1));
  expect(actorRect.bottom, closeTo(expectedAnchor.dy, 1));
});

test('resolves cinematic backdrop focus from selected actor before fallbacks',
    () {
  final model = CinematicActorDisplayPreviewModel(
    status: CinematicActorDisplayPreviewStatus.ready,
    summary: '2 actor(s)',
    actors: [
      _focusPreviewActor('actor_player', x: 1, y: 2),
      _focusPreviewActor('actor_lysa', x: 8, y: 3),
    ],
    diagnostics: const [],
  );
  final selectedStep = _actorDisplayPreviewCinematic()
      .timeline
      .steps
      .firstWhere((step) => step.id == 'step_face_lysa');

  final selectedFocus = resolveCinematicBackdropPreviewFocus(
    mapWidth: 12,
    mapHeight: 10,
    actorDisplayPreviewModel: model,
    selectedStep: selectedStep,
  );
  expect(selectedFocus.reason, 'selectedActor');
  expect(selectedFocus.actorId, 'actor_lysa');
  expect(selectedFocus.tileCenter, const Offset(8.5, 3.5));

  final actorBoundsFocus = resolveCinematicBackdropPreviewFocus(
    mapWidth: 12,
    mapHeight: 10,
    actorDisplayPreviewModel: model,
  );
  expect(actorBoundsFocus.reason, 'actorBounds');
  expect(actorBoundsFocus.tileCenter, const Offset(5, 3));

  final mapCenterFocus = resolveCinematicBackdropPreviewFocus(
    mapWidth: 12,
    mapHeight: 10,
  );
  expect(mapCenterFocus.reason, 'mapCenter');
  expect(mapCenterFocus.tileCenter, const Offset(6, 5));
});
```

Visual Gate test :

```dart
testWidgets(
    'captures V1-95 cinematic backdrop framing zoom controls when requested',
    (tester) async {
  if (!const bool.fromEnvironment(
    'NS_SCENES_V1_95_CAPTURE_CINEMATIC_BACKDROP_FRAMING_ZOOM_CONTROLS',
  )) {
    return;
  }

  _setLargeSurface(tester, _referenceTimelineSurfaceSize);
  await _loadScreenshotFonts();
  final fixture = await _largePathStudioWaterBackdropFixture();

  await _pumpBuilder(
    tester,
    _entry(fixture.project, fixture.asset.id),
    asset: fixture.asset,
    stageMapSourceCatalog: _stageMapSourceCatalog(mapData: fixture.mapData),
    backdropPreviewModel: fixture.backdropModel,
    backdropLayerRenderPlan: fixture.layerPlan,
    surfaceSize: _referenceTimelineSurfaceSize,
  );

  await tester.tap(
    find.byKey(
      const ValueKey('cinematic-builder-map-backdrop-scene-mode'),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(
    find.byKey(const ValueKey('cinematic-builder-map-backdrop-zoom-in')),
  );
  await tester.pumpAndSettle();

  final pathInstructions = fixture.layerPlan.instructions
      .where((instruction) => instruction.sourceFamily == 'path')
      .toList();
  expect(pathInstructions, isNotEmpty);
  expect(
    find.byKey(const ValueKey('cinematic-builder-map-backdrop-bitmap')),
    findsOneWidget,
  );
  expect(find.text('Carte entière'), findsOneWidget);
  expect(find.text('Vue scène'), findsOneWidget);
  expect(find.text('Zoom 1.25×'), findsOneWidget);
  expect(find.text('Timeline par pistes'), findsOneWidget);
  expect(find.text('Lecture en cours'), findsNothing);
  expect(tester.takeException(), isNull);

  final screenshotFile = File(
    '../../reports/narrativeStudio/scenes/screenshots/'
    'ns_scenes_v1_95_cinematic_backdrop_preview_framing_zoom_controls_v0.png',
  );
  screenshotFile.parent.createSync(recursive: true);
  await expectLater(
    find.byKey(const ValueKey('cinematic-builder-workspace')),
    matchesGoldenFile(screenshotFile.absolute.path),
  );

  expect(screenshotFile.existsSync(), isTrue);
});
```

## 14. Fixtures V1-95 ajoutees

```dart
CinematicActorDisplayPreviewActor _focusPreviewActor(
  String actorId, {
  required int x,
  required int y,
}) {
  return CinematicActorDisplayPreviewActor(
    actorId: actorId,
    label: actorId,
    role: null,
    bindingStatus: CinematicActorDisplayBindingStatus.cinematicOnly,
    bindingKind: CinematicActorBindingKind.cinematicOnly,
    bindingSourceId: actorId,
    bindingSourceLabel: actorId,
    position: CinematicActorPreviewPosition(
      status: CinematicActorPreviewPositionStatus.resolved,
      sourceKind: CinematicActorPreviewPositionSourceKind.movementTarget,
      x: x,
      y: y,
      sourceId: actorId,
      sourceLabel: actorId,
    ),
    appearance: const CinematicActorPreviewAppearance(
      status: CinematicActorPreviewAppearanceStatus.placeholderOnly,
    ),
    direction: CinematicActorPreviewDirection.south,
    directionSource: CinematicActorPreviewDirectionSource.fallback,
    renderHint: CinematicActorPreviewRenderHint.placeholder,
    diagnostics: const [],
  );
}

MapData _stageMapDataWithLargePathStudioWaterBackdrop() {
  final waterCells = List<bool>.filled(55 * 55, true);
  return _stageMapData(
    entities: const <MapEntity>[],
    events: const <MapEventDefinition>[],
  ).copyWith(
    size: const GridSize(width: 55, height: 55),
    layers: [
      MapLayer.tile(
        id: 'large_ground',
        name: 'Large ground',
        tilesetId: 'neutral_tiles',
        tiles: List<int>.filled(55 * 55, 5),
      ),
      MapLayer.path(
        id: 'large_water_path_layer',
        name: 'Large water path',
        presetId: 'water_base',
        cells: waterCells,
      ),
    ],
  );
}
```

## 15. Visual Gate proof

```text
ls -l reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_95_cinematic_backdrop_preview_framing_zoom_controls_v0.png
-rw-r--r--  1 karim  staff  255831 Jun  7 14:11 reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_95_cinematic_backdrop_preview_framing_zoom_controls_v0.png
```

```text
file reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_95_cinematic_backdrop_preview_framing_zoom_controls_v0.png
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_95_cinematic_backdrop_preview_framing_zoom_controls_v0.png: PNG image data, 1663 x 926, 8-bit/color RGBA, non-interlaced
```

```text
shasum -a 256 reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_95_cinematic_backdrop_preview_framing_zoom_controls_v0.png
3a2ee1eef54a8c7a4342d137733484cd734625a71f4b90d441c0140ad1d3cff9  reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_95_cinematic_backdrop_preview_framing_zoom_controls_v0.png
```

## 16. Checks anti-scope outputs

```text
git diff --name-only -- packages/map_runtime packages/map_gameplay packages/map_battle examples selbrume
```

Sortie vide.

```text
rg -n "package:flame|GameWidget|FlameGame|PlayableMapGame|RuntimeMapGame|CameraComponent|MapLayersComponent|PlayerComponent|OverworldActorComponent|Component|GameState|SceneCinematicRuntimeAwaitableAdapter|map_runtime" packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_backdrop_preview_framing.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_render_pass.dart packages/map_editor/lib/src/ui/design_system/pokemap_dashboard_primitives.dart || true
```

Sortie vide.

```text
rg -n "startPlayback|stopPlayback|playbackTimeMs|currentTimeMs|isPlaying|Timer\(|Ticker|AnimationController|seek|scrub|scrubber" packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_backdrop_preview_framing.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_render_pass.dart packages/map_editor/lib/src/ui/design_system/pokemap_dashboard_primitives.dart || true
```

Sortie vide.

```text
rg -n "CharacterSprite|ActorSprite|ImageProvider|AssetImage|rootBundle|actorSprite|characterSprite|drawImageRect.*actor|actor.*drawImageRect" packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_backdrop_preview_framing.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_render_pass.dart packages/map_editor/lib/src/ui/design_system/pokemap_dashboard_primitives.dart || true
```

Sortie vide.

```text
rg -n "MapCanvas\(|MapGridPainter\(" packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_backdrop_preview_framing.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_render_pass.dart packages/map_editor/lib/src/ui/design_system/pokemap_dashboard_primitives.dart packages/map_editor/test/cinematic_builder_workspace_test.dart || true
```

Sortie vide.

```text
rg -n "readAsBytes|instantiateImageCodec|decodeImageFromList|File\(" packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_backdrop_preview_framing.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_render_pass.dart packages/map_editor/lib/src/ui/design_system/pokemap_dashboard_primitives.dart || true
```

Sortie vide.

```text
rg -n "Selbrume|selbrume|Lysa|lysa|Mael|Maël|mael|port_brisants|bourg_selbrume|marais|phare" packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_backdrop_preview_framing.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_render_pass.dart packages/map_editor/lib/src/ui/design_system/pokemap_dashboard_primitives.dart || true
```

Sortie vide.

```text
git diff -U0 -- packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_backdrop_preview_framing.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_render_pass.dart packages/map_editor/lib/src/ui/design_system/pokemap_dashboard_primitives.dart | rg -n "Color\(0x|Colors\." || true
```

Sortie vide.

```text
rg -n "gpt-image-2|image_generation|generate image|AI image|image model" packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_backdrop_preview_framing.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_render_pass.dart packages/map_editor/lib/src/ui/design_system/pokemap_dashboard_primitives.dart packages/map_editor/test/cinematic_builder_workspace_test.dart || true
```

Sortie vide.

## 17. Roadmaps

`reports/narrativeStudio/scenes/road_map_scenes.md` :

```text
NS-SCENES-V1-95 — Cinematic Backdrop Preview Framing / Zoom Controls V0 | DONE
NS-SCENES-V1-96 — Cinematic Actor Display Preview Sprite Resolver Prep Contract | TODO
```

`reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md` :

```text
Prochain lot exact recommande : NS-SCENES-V1-96 — Cinematic Actor Display Preview Sprite Resolver Prep Contract
V1-95 DONE : controles framing/zoom locaux, scene plus lisible que fit map, non-mutation, focus/fallback, acteurs placeholders alignes, Path Studio/eau visible, timeline/transports preserves, screenshot V1-95.
```

## 18. Auto-review critique Q1-Q30

1. map_runtime modifie ? Non.
2. map_gameplay/map_battle/examples modifies ? Non.
3. selbrume modifie ? Non.
4. Flame importe ? Non.
5. map_runtime importe ? Non.
6. PlayableMapGame utilise ? Non.
7. GameState utilise ? Non.
8. MapCanvas complet branche ? Non.
9. MapGridPainter brut instancie ? Non.
10. Playback ajoute ? Non.
11. currentTimeMs/playbackTimeMs/isPlaying ajoutes ? Non.
12. actorMove execute ? Non.
13. pathfinding/collision ajoutes ? Non.
14. sprite acteur final rendu ? Non.
15. mode Carte entiere ajoute ? Oui.
16. mode Vue scene ajoute ? Oui.
17. zoom controls locaux ajoutes ? Oui.
18. persistence zoom evitee ? Oui.
19. eau Path Studio V1-94 bis preservee ? Oui.
20. Actor Display V1-92 preserve ? Oui.
21. acteurs placeholders gardes ? Oui.
22. transports disabled gardes ? Oui.
23. timeline preservee ? Oui.
24. duration editor et resize encore couverts ? Oui par suite Builder complete.
25. mouse probe encore couvert ? Oui par suite Builder complete.
26. pickers mapEntity/mapEvent encore couverts ? Oui par suite Builder complete.
27. picker Character Library encore couvert ? Oui par suite Builder complete.
28. Visual Gate prouve une preview plus lisible ? Oui : Vue scene active, zoom 1.25x, eau visible, timeline/inspector visibles.
29. Evidence Pack complet sans placeholders ? Oui : code nouveau complet, modifications et sorties de validation incluses.
30. Prochain lot exact recommande ? `NS-SCENES-V1-96 — Cinematic Actor Display Preview Sprite Resolver Prep Contract`.

## 19. Limites et risques restants

- `flutter analyze` global editor reste rouge sur dette Pokemon SDK hors lot.
- La vue scene n'est pas une camera runtime exacte; c'est volontaire.
- Les sprites acteurs finaux restent placeholders V1-92 jusqu'au lot V1-96+.
- Le zoom/framing est local et non persistant; c'est volontaire pour V0.

## 20. Commandes finales

```text
git diff --check
```

Sortie vide.

```text
git diff --stat
 .../cinematics/cinematic_builder_workspace.dart    |  32 ++
 .../cinematic_map_backdrop_preview_panel.dart      | 463 ++++++++++++++++-----
 .../cinematic_map_backdrop_render_pass.dart        |   4 +-
 .../pokemap_dashboard_primitives.dart              |   5 +-
 .../test/cinematic_builder_workspace_test.dart     | 419 ++++++++++++++++++-
 .../scenes/road_map_scene_builder_authoring.md     |  27 +-
 reports/narrativeStudio/scenes/road_map_scenes.md  |  35 +-
 7 files changed, 851 insertions(+), 134 deletions(-)
```

Note : `git diff --stat` ne liste pas les fichiers non suivis. Ils sont visibles dans le status final ci-dessous.

```text
git diff --name-only
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_render_pass.dart
packages/map_editor/lib/src/ui/design_system/pokemap_dashboard_primitives.dart
packages/map_editor/test/cinematic_builder_workspace_test.dart
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md
```

```text
git status --short --untracked-files=all
 M packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
 M packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart
 M packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_render_pass.dart
 M packages/map_editor/lib/src/ui/design_system/pokemap_dashboard_primitives.dart
 M packages/map_editor/test/cinematic_builder_workspace_test.dart
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_backdrop_preview_framing.dart
?? reports/narrativeStudio/scenes/ns_scenes_v1_95_cinematic_backdrop_preview_framing_zoom_controls_v0.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_95_evidence_pack.md
?? reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_95_cinematic_backdrop_preview_framing_zoom_controls_v0.png
```
