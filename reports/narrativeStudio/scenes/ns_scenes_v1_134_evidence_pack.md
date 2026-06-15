# NS-SCENES-V1-134 — Evidence Pack

Lot : `NS-SCENES-V1-134 — Cinematic Camera Geometry Preview UI V0`

Verdict : DONE, sous reserve de la passe finale inscrite en fin de document.

## Gate 0

Commandes initiales :

```bash
pwd
git branch --show-current
git status --short --untracked-files=all
git diff --stat
git diff --name-only
```

Sorties utiles :

```text
/Users/karim/Project/pokemonProject
main
git status --short --untracked-files=all : <vide>
git diff --stat : <vide>
git diff --name-only : <vide>
```

Worktree initial propre. Aucun changement preexistant a isoler.

## Regles lues

Fichiers lus avant modification :

- `AGENTS.md`
- `agent_rules.md`
- `codex_rule.md`
- `skills/README.md`
- `skills/using-superpowers/SKILL.md`
- `skills/test-driven-development/SKILL.md`
- `skills/verification-before-completion/SKILL.md`
- `skills/writing-plans/SKILL.md`

Note : `codex_rules.md` au pluriel n'est pas le fichier canonique local ; le fichier present et lu est `codex_rule.md`.

## Preconditions V1-133 / V1-132

Recherches effectuees :

```bash
rg -n "CinematicCameraPlaybackGeometry|CinematicPreviewPlaybackStageBounds|cameraPose\\.geometry|cinematicPreviewPlaybackCameraTargetStageMapMissing|NS-SCENES-V1-133" packages reports/narrativeStudio/scenes
rg -n "cinematic-builder-camera-mode-focus|cinematic-builder-camera-target-sceneCenter|cinematic-builder-camera-target-actor|cinematic-builder-camera-target-stagePoint|cinematic-builder-camera-zoom-medium|Cadrage configuré, preview réelle à venir" packages/map_editor
```

Resultat : les symboles et keys attendus existent. V1-133 et V1-132 sont presents.

## TDD

Tests RED ajoutes avant implementation :

- `V1-134 renders camera geometry frame when focus geometry is available`
- `V1-134 renders camera target marker at resolved actor pose`
- `V1-134 renders camera target marker at resolved stage point`
- `V1-134 wide medium close produce distinct frame sizes`
- `V1-134 unavailable geometry shows no-code fallback`
- `V1-134 reset and hold keep symbolic camera behavior`
- `V1-134 seek and scrub update camera geometry overlay from playback frame`

Commande RED :

```bash
cd packages/map_editor
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --name "V1-134"
```

Sortie RED caracteristique :

```text
V1-134 renders camera geometry frame when focus geometry is available
Expected: exactly one matching candidate
  Actual: _KeyWidgetFinder:<Found 0 widgets with key [<'cinematic-builder-camera-geometry-overlay'>]: []>
00:08 +1 -6: Some tests failed.
```

## Fichiers crees

- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_camera_geometry_preview_overlay.dart`
- `reports/narrativeStudio/scenes/ns_scenes_v1_134_cinematic_camera_geometry_preview_ui_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_134_evidence_pack.md`
- `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_134_cinematic_camera_geometry_preview_ui_v0.png`

## Fichiers modifies

- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_camera_preview_overlay.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart`
- `packages/map_editor/test/cinematic_builder_workspace_test.dart`
- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`

## Fichiers supprimes

Aucun.

## Code complet du nouveau fichier

Fichier : `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_camera_geometry_preview_overlay.dart`

```dart
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:map_core/map_core.dart';

import '../../../theme/theme.dart';
import '../../design_system/design_system.dart';
import 'cinematic_map_backdrop_viewport_transform.dart';

class CinematicCameraGeometryPreviewOverlay extends StatelessWidget {
  const CinematicCameraGeometryPreviewOverlay({
    super.key,
    required this.cameraPose,
    required this.transform,
    required this.compact,
  });

  final CinematicCameraPlaybackPose cameraPose;
  final CinematicMapBackdropViewportTransform transform;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (!cameraPose.isActive || !transform.isUsable) {
      return const SizedBox.shrink();
    }

    final geometry = cameraPose.geometry;
    if (geometry.isAvailable &&
        geometry.centerX != null &&
        geometry.centerY != null &&
        geometry.zoomPreset != null) {
      return _AvailableCameraGeometryOverlay(
        geometry: geometry,
        transform: transform,
        compact: compact,
      );
    }

    final diagnostics = geometry.diagnostics;
    if (geometry.targetKind == null && diagnostics.isEmpty) {
      return const SizedBox.shrink();
    }

    return _UnavailableCameraGeometryOverlay(
      diagnostics: diagnostics,
      compact: compact,
    );
  }
}

class _AvailableCameraGeometryOverlay extends StatelessWidget {
  const _AvailableCameraGeometryOverlay({
    required this.geometry,
    required this.transform,
    required this.compact,
  });

  final CinematicCameraPlaybackGeometry geometry;
  final CinematicMapBackdropViewportTransform transform;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final tone = PokeMapTone.info.resolve(context);
    final center =
        transform.tileToPreview(geometry.centerX!, geometry.centerY!);
    final frameRect = _cameraFrameRectFor(
      center: center,
      transform: transform,
      zoomPreset: geometry.zoomPreset!,
    );
    final markerSize = compact ? 14.0 : 18.0;
    final labelMaxWidth = compact ? 210.0 : 280.0;
    final labelHeight = compact ? 62.0 : 72.0;
    final labelLeft = math.max(
      transform.frame.left + 6,
      math.min(
        transform.frame.right - labelMaxWidth - 6,
        frameRect.right - labelMaxWidth,
      ),
    );
    final labelTop = math.max(
      transform.frame.top + 6,
      math.min(
        transform.frame.bottom - labelHeight - 6,
        frameRect.bottom - labelHeight,
      ),
    );

    return IgnorePointer(
      key: const ValueKey('cinematic-builder-camera-geometry-overlay'),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned.fromRect(
            rect: frameRect,
            child: DecoratedBox(
              key: const ValueKey('cinematic-builder-camera-geometry-frame'),
              decoration: BoxDecoration(
                color: tone.soft.withValues(alpha: 0.16),
                border: Border.all(
                  color: tone.border,
                  width: compact ? 1.5 : 2,
                ),
                borderRadius: BorderRadius.circular(compact ? 8 : 10),
              ),
            ),
          ),
          Positioned(
            left: center.dx - markerSize / 2,
            top: center.dy - markerSize / 2,
            width: markerSize,
            height: markerSize,
            child: DecoratedBox(
              key: const ValueKey(
                'cinematic-builder-camera-geometry-target-marker',
              ),
              decoration: BoxDecoration(
                color: colors.brandPrimary,
                shape: BoxShape.circle,
                border: Border.all(color: colors.textInverse, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: colors.brandPrimary.withValues(alpha: 0.34),
                    blurRadius: compact ? 8 : 12,
                    spreadRadius: compact ? 1 : 2,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: labelLeft,
            top: labelTop,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: labelMaxWidth),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.surfaceBase.withValues(alpha: 0.9),
                  border: Border.all(color: tone.border),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: compact ? 8 : 10,
                    vertical: compact ? 6 : 8,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        CupertinoIcons.viewfinder,
                        color: tone.icon,
                        size: compact ? 14 : 16,
                      ),
                      SizedBox(width: compact ? 6 : 8),
                      Flexible(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Cadrage affiché, vue non pilotée.',
                              key: const ValueKey(
                                'cinematic-builder-camera-geometry-status',
                              ),
                              style: TextStyle(
                                color: colors.textPrimary,
                                fontSize: compact ? 10 : 11,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _cameraGeometryTargetLabel(geometry),
                              key: const ValueKey(
                                'cinematic-builder-camera-geometry-target-label',
                              ),
                              style: TextStyle(
                                color: tone.text,
                                fontSize: compact ? 10 : 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _cameraGeometryZoomLabel(geometry.zoomPreset!),
                              key: const ValueKey(
                                'cinematic-builder-camera-geometry-zoom-label',
                              ),
                              style: TextStyle(
                                color: colors.textMuted,
                                fontSize: compact ? 9 : 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UnavailableCameraGeometryOverlay extends StatelessWidget {
  const _UnavailableCameraGeometryOverlay({
    required this.diagnostics,
    required this.compact,
  });

  final List<CinematicPreviewPlaybackDiagnostic> diagnostics;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final tone = PokeMapTone.warning.resolve(context);

    return IgnorePointer(
      key: const ValueKey('cinematic-builder-camera-geometry-fallback'),
      child: Align(
        alignment: Alignment.topLeft,
        child: Padding(
          padding: EdgeInsets.all(compact ? 8 : 12),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: compact ? 220 : 300),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: tone.soft,
                border: Border.all(color: tone.border),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 8 : 10,
                  vertical: compact ? 6 : 8,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      CupertinoIcons.exclamationmark_triangle,
                      color: tone.icon,
                      size: compact ? 14 : 16,
                    ),
                    SizedBox(width: compact ? 6 : 8),
                    Flexible(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Cadrage caméra incomplet.',
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: compact ? 10 : 11,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _cameraGeometryFallbackLabel(diagnostics),
                            style: TextStyle(
                              color: tone.text,
                              fontSize: compact ? 10 : 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Rect _cameraFrameRectFor({
  required Offset center,
  required CinematicMapBackdropViewportTransform transform,
  required CinematicCameraZoomPreset zoomPreset,
}) {
  final tileSize = _cameraFrameTileSize(zoomPreset);
  final cellWidth = transform.frame.width / transform.mapWidth;
  final cellHeight = transform.frame.height / transform.mapHeight;
  return Rect.fromCenter(
    center: center,
    width: tileSize.width * cellWidth,
    height: tileSize.height * cellHeight,
  );
}

Size _cameraFrameTileSize(CinematicCameraZoomPreset zoomPreset) {
  return switch (zoomPreset) {
    CinematicCameraZoomPreset.wide => const Size(7, 5),
    CinematicCameraZoomPreset.medium => const Size(5, 3.5),
    CinematicCameraZoomPreset.close => const Size(3, 2.25),
  };
}

String _cameraGeometryTargetLabel(CinematicCameraPlaybackGeometry geometry) {
  final label = geometry.targetLabel?.trim();
  return switch (geometry.targetKind) {
    CinematicCameraTargetKind.sceneCenter => 'Centre de la scène',
    CinematicCameraTargetKind.actor =>
      'Acteur : ${label == null || label.isEmpty ? 'acteur ciblé' : label}',
    CinematicCameraTargetKind.stagePoint =>
      'Repère : ${label == null || label.isEmpty ? 'repère ciblé' : label}',
    null => 'Cible caméra',
  };
}

String _cameraGeometryZoomLabel(CinematicCameraZoomPreset zoomPreset) {
  return switch (zoomPreset) {
    CinematicCameraZoomPreset.wide => 'Plan large',
    CinematicCameraZoomPreset.medium => 'Plan moyen',
    CinematicCameraZoomPreset.close => 'Gros plan',
  };
}

String _cameraGeometryFallbackLabel(
  List<CinematicPreviewPlaybackDiagnostic> diagnostics,
) {
  for (final diagnostic in diagnostics) {
    final label = switch (diagnostic.code) {
      CinematicPreviewPlaybackDiagnosticCode
            .cinematicPreviewPlaybackCameraTargetStageMapMissing =>
        'Impossible de résoudre le centre de scène.',
      CinematicPreviewPlaybackDiagnosticCode
            .cinematicPreviewPlaybackCameraTargetActorMissing =>
        'Choisissez un acteur à cadrer.',
      CinematicPreviewPlaybackDiagnosticCode
            .cinematicPreviewPlaybackCameraTargetActorUnknown =>
        'L’acteur ciblé n’est plus disponible.',
      CinematicPreviewPlaybackDiagnosticCode
            .cinematicPreviewPlaybackCameraTargetActorWithoutPosition =>
        'L’acteur ciblé n’a pas de position dans la preview.',
      CinematicPreviewPlaybackDiagnosticCode
            .cinematicPreviewPlaybackCameraTargetStagePointMissing =>
        'Choisissez un repère à cadrer.',
      CinematicPreviewPlaybackDiagnosticCode
            .cinematicPreviewPlaybackCameraTargetStagePointUnknown =>
        'Ce repère n’existe plus dans la scène.',
      CinematicPreviewPlaybackDiagnosticCode
            .cinematicPreviewPlaybackCameraTargetStagePointOutOfMap =>
        'Ce repère est en dehors de la carte.',
      CinematicPreviewPlaybackDiagnosticCode
            .cinematicPreviewPlaybackCameraZoomPresetMissing =>
        'Choisissez un plan de cadrage.',
      CinematicPreviewPlaybackDiagnosticCode
            .cinematicPreviewPlaybackCameraZoomPresetUnsupported =>
        'Ce plan de cadrage n’est pas supporté.',
      CinematicPreviewPlaybackDiagnosticCode
            .cinematicPreviewPlaybackCameraTargetMissing =>
        'La cible caméra n’est pas disponible.',
      CinematicPreviewPlaybackDiagnosticCode
            .cinematicPreviewPlaybackCameraTargetKindUnsupported =>
        'Cette cible caméra n’est pas supportée.',
      _ => null,
    };
    if (label != null) {
      return label;
    }
  }
  return 'La cible caméra n’est pas disponible.';
}
```

## Hunks produits principaux

### `cinematic_builder_workspace.dart`

```diff
@@
     final playbackPlan = buildCinematicPreviewPlaybackPlan(
       cinematic: widget.asset,
       actorDisplayPreviewModel: widget.actorDisplayPreviewModel,
+      stageBounds: _previewPlaybackStageBoundsFor(widget.backdropPreviewModel),
     );
@@
+  CinematicPreviewPlaybackStageBounds? _previewPlaybackStageBoundsFor(
+    CinematicMapBackdropPreviewModel? model,
+  ) {
+    final width = model?.mapWidth;
+    final height = model?.mapHeight;
+    if (width == null || height == null || width <= 0 || height <= 0) {
+      return null;
+    }
+    return CinematicPreviewPlaybackStageBounds(
+      width: width.toDouble(),
+      height: height.toDouble(),
+    );
+  }
```

### `cinematic_map_backdrop_preview_panel.dart`

```diff
+import 'cinematic_camera_geometry_preview_overlay.dart';
@@
+                                        CinematicCameraGeometryPreviewOverlay(
+                                          cameraPose: cameraPose,
+                                          transform:
+                                              CinematicMapBackdropViewportTransform
+                                                  .fill(
+                                            viewportSize:
+                                                framing.transform.frame.size,
+                                            mapWidth: plan.mapWidth,
+                                            mapHeight: plan.mapHeight,
+                                          ),
+                                          compact: compact,
+                                        ),
@@
+                                        CinematicCameraGeometryPreviewOverlay(
+                                          cameraPose: cameraPose,
+                                          transform: transform,
+                                          compact: compact,
+                                        ),
@@
+                      CinematicCameraGeometryPreviewOverlay(
+                        cameraPose: cameraPose,
+                        transform: CinematicMapBackdropViewportTransform.fill(
+                          viewportSize: Size(
+                            viewportRect.width,
+                            viewportRect.height,
+                          ),
+                          mapWidth: mapWidth,
+                          mapHeight: mapHeight,
+                        ),
+                        compact: compact,
+                      ),
```

### `cinematic_camera_preview_overlay.dart`

```diff
-    final tone = cameraPose.isSupported
+    final hasGeometryPreview = cameraPose.geometry.isAvailable;
+    final tone = cameraPose.isSupported || hasGeometryPreview
         ? PokeMapTone.info.resolve(context)
         : PokeMapTone.warning.resolve(context);
@@
 String _cameraPreviewStatusLabel(CinematicCameraPlaybackPose cameraPose) {
+  if (cameraPose.geometry.isAvailable) {
+    return 'Cadrage affiché, vue non pilotée.';
+  }
   if (cameraPose.isSupported) {
     return 'Cadrage caméra prêt';
   }
```

### Tests V1-134

Sections ajoutees dans `packages/map_editor/test/cinematic_builder_workspace_test.dart` :

- tests V1-134 listés dans la section TDD ;
- capture Visual Gate `captures V1-134 cinematic camera geometry preview ui visual gate` ;
- helper `_pumpCameraGeometryPreviewBuilder` ;
- fixtures `_cameraGeometryPreviewCinematic`, `_cameraGeometryPreviewTwoTargetsCinematic`, `_cameraGeometryFocusMetadata` ;
- helpers `_seekPlaybackToTick`, `_cameraGeometryFrameRect`, `_cameraGeometryMarkerCenter`.

Le hunk de test ajoute aussi l'adaptation de regression V1-132 :

```diff
-    'V1-132 keeps existing camera preview symbolic and unsupported for focus',
+    'V1-132 focus camera remains no-code without raw metadata after geometry preview',
@@
-      expect(find.text('Caméra non prévisualisée dans cette version.'),
-          findsOneWidget);
+      expect(find.text('Cadrage affiché, vue non pilotée.'), findsWidgets);
+      expect(
+        find.text('Caméra non prévisualisée dans cette version.'),
+        findsNothing,
+      );
+      expect(
+        find.byKey(
+          const ValueKey('cinematic-builder-camera-geometry-overlay'),
+        ),
+        findsOneWidget,
+      );
```

## Tests GREEN et regressions

### V1-134

Commande :

```bash
cd packages/map_editor
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --name "V1-134"
```

Sortie finale :

```text
00:05 +8: All tests passed!
```

### Regressions V1-124 / V1-132 / V1-129

Commande :

```bash
cd packages/map_editor
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --name "V1-124|V1-132|V1-129"
```

Sortie finale :

```text
00:10 +22: All tests passed!
```

### Visual Gate

Commande :

```bash
cd packages/map_editor
flutter test --reporter=compact --update-goldens --dart-define=NS_SCENES_V1_134_CAPTURE_CINEMATIC_CAMERA_GEOMETRY_PREVIEW_UI=true test/cinematic_builder_workspace_test.dart --name "captures V1-134"
```

Sortie finale :

```text
00:02 +1: All tests passed!
```

## Analyse ciblee

Commande :

```bash
cd packages/map_editor
flutter analyze --no-fatal-infos lib/src/ui/canvas/cinematics/cinematic_camera_geometry_preview_overlay.dart lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart lib/src/ui/canvas/cinematics/cinematic_camera_preview_overlay.dart test/cinematic_builder_workspace_test.dart
```

Sortie :

```text
Analyzing 5 items...
35 issues found. (ran in 1.0s)
```

Interpretation : commande sortie 0 grace a `--no-fatal-infos`. Les 35 issues sont des infos `prefer_const_constructors` / `prefer_const_literals_to_create_immutables` preexistantes dans `cinematic_builder_workspace.dart` et `cinematic_builder_workspace_test.dart`. Le nouveau fichier overlay n'a plus d'info apres suppression de l'import inutile et remplacement de `withOpacity` par `withValues`.

## Visual Gate

Chemin :

`reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_134_cinematic_camera_geometry_preview_ui_v0.png`

Commandes :

```bash
ls -lh reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_134_cinematic_camera_geometry_preview_ui_v0.png
file reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_134_cinematic_camera_geometry_preview_ui_v0.png
shasum -a 256 reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_134_cinematic_camera_geometry_preview_ui_v0.png
```

Sorties :

```text
-rw-r--r--  1 karim  staff   224K Jun 15 12:36 reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_134_cinematic_camera_geometry_preview_ui_v0.png
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_134_cinematic_camera_geometry_preview_ui_v0.png: PNG image data, 1663 x 926, 8-bit/color RGBA, non-interlaced
01ce3b5de7fd78aeaa549f47866523c5505c14813ccbe03a7e25acf5e3f22ee4  reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_134_cinematic_camera_geometry_preview_ui_v0.png
```

## Roadmaps

Fichiers mis a jour :

- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`

Etat attendu :

- `NS-SCENES-V1-134 — DONE`
- `NS-SCENES-V1-135 — RECOMMANDÉ`
- V1-135 non demarre.

## Anti-scope

Respecte pendant l'implementation :

- aucun fichier `packages/map_core` modifie ;
- aucun fichier `packages/map_runtime`, `packages/map_gameplay`, `packages/map_battle` modifie ;
- aucun fichier `examples/playable_runtime_host` modifie ;
- aucun asset modifie ;
- aucun fichier Selbrume modifie ;
- aucun `pubspec.yaml` modifie ;
- aucune Visual Gate V1-135 creee.

## Auto-review independante

- L'UI consomme `cameraPose.geometry`.
- L'UI ne lit pas directement `camera.targetActorId` ou `camera.targetStagePointId`.
- L'UI ne recalcule pas la geometrie depuis les metadata.
- Le viewport editor n'est pas mute.
- Le cadre est purement visuel et editor-only.
- Les presets restent des tailles de cadre editor-only, pas un zoom runtime.
- Reset/hold ne montrent pas de cadre de geometrie cible.
- Les diagnostics visibles sont no-code.
- Aucune couleur hardcodee n'est ajoutee ; les couleurs viennent des tokens/design-system.
- Aucun runtime/Flame/GameState/Selbrume n'est touche.
- Aucune Visual Gate V1-135 n'est creee.

## Critique du prompt

Le prompt est pertinent et bien borne. La contrainte la plus sensible etait l'interdiction de recalculer la geometrie dans l'UI ; elle a ete respectee en consommant `cameraPose.geometry` et en ne deriveant localement que le rectangle visuel editor-only depuis le centre/preset deja fournis.

Adaptation documentee : la Visual Gate est produite via golden widget test existant, dans la surface claire du harness de tests. C'est le mecanisme deja utilise par les lots UI precedents et il donne une preuve reproductible.

## Verification finale

Commande :

```bash
rg -n "Prochain lot exact recommande|NS-SCENES-V1-134 — Cinematic Camera Geometry Preview UI V0|NS-SCENES-V1-135 — Cinematic Builder V1 Camera Closure / Polish Gate|V1-134.*recommande|recommande.*V1-134" reports/narrativeStudio/scenes/road_map_scenes.md reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
git diff --check
git diff --stat
git diff --name-only
git status --short --untracked-files=all
git diff --name-only -- packages/map_core packages/map_runtime packages/map_gameplay packages/map_battle examples/playable_runtime_host assets selbrume pubspec.yaml
find reports/narrativeStudio/scenes/screenshots -maxdepth 1 -name '*v1_134*' -print
find reports/narrativeStudio/scenes/screenshots -maxdepth 1 -name '*v1_135*' -print
```

Sorties utiles :

```text
reports/narrativeStudio/scenes/road_map_scenes.md:200:| NS-SCENES-V1-134 — Cinematic Camera Geometry Preview UI V0 | DONE | Etat geometrique V1-133 branche dans la preview editor-only : cadre camera passif, marqueur cible, labels no-code et diagnostics lisibles, sans runtime, Flame, GameState ni mutation viewport editor. |
reports/narrativeStudio/scenes/road_map_scenes.md:201:| NS-SCENES-V1-135 — Cinematic Builder V1 Camera Closure / Polish Gate | RECOMMANDÉ | Fermer la sequence camera V1 par un polish/gate cible : cohérence wording, diagnostics restants, preuves UI et non-regression, sans nouveau continent fonctionnel. |
reports/narrativeStudio/scenes/road_map_scenes.md:203:## Prochain lot exact recommande
reports/narrativeStudio/scenes/road_map_scenes.md:205:`NS-SCENES-V1-135 — Cinematic Builder V1 Camera Closure / Polish Gate`
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md:9:## Prochain lot exact recommande
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md:12:NS-SCENES-V1-135 — Cinematic Builder V1 Camera Closure / Polish Gate
git diff --check : <vide>
git diff --name-only -- packages/map_core packages/map_runtime packages/map_gameplay packages/map_battle examples/playable_runtime_host assets selbrume pubspec.yaml : <vide>
find reports/narrativeStudio/scenes/screenshots -maxdepth 1 -name '*v1_134*' -print :
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_134_cinematic_camera_geometry_preview_ui_v0.png
find reports/narrativeStudio/scenes/screenshots -maxdepth 1 -name '*v1_135*' -print : <vide>
```

Diff stat final au moment de cette verification :

```text
 .../cinematics/cinematic_builder_workspace.dart    |  15 +
 .../cinematic_camera_preview_overlay.dart          |  10 +-
 .../cinematic_map_backdrop_preview_panel.dart      |  30 +
 .../test/cinematic_builder_workspace_test.dart     | 605 ++++++++++++++++++++-
 .../scenes/road_map_scene_builder_authoring.md     |  67 ++-
 reports/narrativeStudio/scenes/road_map_scenes.md  |  68 ++-
 6 files changed, 733 insertions(+), 62 deletions(-)
```

Statut Git final au moment de cette verification :

```text
 M packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
 M packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_camera_preview_overlay.dart
 M packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart
 M packages/map_editor/test/cinematic_builder_workspace_test.dart
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_camera_geometry_preview_overlay.dart
?? reports/narrativeStudio/scenes/ns_scenes_v1_134_cinematic_camera_geometry_preview_ui_v0.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_134_evidence_pack.md
?? reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_134_cinematic_camera_geometry_preview_ui_v0.png
```

Verdict final :

`NS-SCENES-V1-134 — DONE.`

`NS-SCENES-V1-135 — recommandé, non démarré.`
