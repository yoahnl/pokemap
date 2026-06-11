# NS-SCENES-V1-108 — Evidence Pack corrigé

## 1. Contexte

Karim a demandé à Codex de corriger les points relevés lors de la revue des changements Gemini V1-108, puis de refaire les rapports.

Ce Evidence Pack remplace l'ancien contenu V1-108 qui contenait :

- des sorties de tests non relancées dans cette passe ;
- des affirmations trop larges sur `map_core` et le package `map_editor` complet ;
- du code d'exemple obsolète avec sentinelles invalides ;
- une clôture Visual Gate non revérifiée après correction.

## 2. Règles lues

Commandes :

```bash
sed -n '1,260p' codex_rule.md
sed -n '1,220p' agent_rules.md
test -f codex_rules.md && sed -n '1,220p' codex_rules.md || printf 'codex_rules.md MISSING\n'
```

Résultat :

```text
codex_rule.md lu.
agent_rules.md lu.
codex_rules.md MISSING
```

Règles appliquées :

- Git en lecture seule.
- Rapport avec audit, preuves, limites et auto-critique.
- Pas d'affirmation de validation sans commande fraîche.
- Ne pas corriger ou nettoyer les artefacts non demandés du worktree.

## 3. État Git initial observé avant réécriture des rapports

Commande :

```bash
pwd && git branch --show-current && git status --short --untracked-files=all && git diff --stat && git diff --name-only && git log --oneline -n 10
```

Sortie :

```text
/Users/karim/Project/pokemonProject
main
 M packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
 M packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart
 M packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart
 M packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
 M packages/map_editor/test/cinematic_builder_workspace_test.dart
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_manual_path_preview_overlay.dart
?? reports/narrativeStudio/scenes/ns_scenes_v1_108_bis_cinematic_manual_path_drawing_ui_evidence_visual_gate_cleanup.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_108_bis_evidence_pack.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_108_cinematic_manual_path_drawing_ui_v0.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_108_evidence_pack.md
?? reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_108_cinematic_manual_path_drawing_ui_v0.png
 .../cinematics/cinematic_builder_workspace.dart    | 478 ++++++++++++++++++-
 .../cinematic_map_backdrop_preview_panel.dart      |  41 ++
 .../cinematics/cinematics_library_workspace.dart   |   3 +
 .../src/ui/canvas/narrative_workspace_canvas.dart  |  24 +
 .../test/cinematic_builder_workspace_test.dart     | 519 ++++++++++++++++++++-
 .../scenes/road_map_scene_builder_authoring.md     |  16 +-
 reports/narrativeStudio/scenes/road_map_scenes.md  |  19 +-
 7 files changed, 1076 insertions(+), 24 deletions(-)
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart
packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
packages/map_editor/test/cinematic_builder_workspace_test.dart
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md
b54e1cd3 docs: ajout rapports v1.107 bis (nettoyage JSON et hardening)
ecb0d64b feat: cinematic manual path core model et tests
550e6364 docs: mise à jour roadmaps et ajout rapports v1.106
73be9440 feat: cinematic builder UX simplification et rapports
d93136a5 refactor: UI cinematic builder workspace et tests
1444a60f update selbrume
50c1bba6 update selbrume
4523a1e0 update selbrume
530bbc33 build(macos): add BUILD-MACOS-01 documentation and roadmap
97509364 doc(narrativeStudio): split V1-104-bis Xcode modifications to BUILD-MACOS-01
```

## 4. Audit / Architecture

### Fichiers relus ou inspectés pendant la correction

- `packages/map_core/lib/src/authoring/cinematic_authoring_operations.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_manual_path_preview_overlay.dart`
- `packages/map_editor/test/cinematic_builder_workspace_test.dart`

### Contrats confirmés

- La Destination finale est portée par l'`actorMove.targetId` et son binding éventuel vers un Repère.
- Les Points de passage d'un trajet manuel sont uniquement `CinematicManualPath.waypointStagePointIds`.
- Le lien `actorMove -> manualPath` reste `CinematicManualPath.ownerActorMoveStepId`.
- Les opérations core existantes doivent être préférées aux mutations UI ad hoc.

## 5. RED — tests ajoutés et échec attendu

Commande :

```bash
cd packages/map_editor
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --name "V1-108"
```

Sortie utile :

```text
Expected: no matching candidates
  Actual: _DescendantWidgetFinder:<Found 1 widget with text "Point 2" descending from widget with widget matching predicate: [...]>
The test description was:
  V1-108 — Cinematic Manual Path Drawing UI V0

Error toggling path mode: Invalid argument(s): A manual path already exists for step "step_move".
LateInitializationError: Local 'latestProject' has not been initialized.
The test description was:
  V1-108 — manual mode reuses an existing path owned by a direct actorMove

00:04 +1 -2: Some tests failed.
```

Interprétation :

- Le picker proposait encore la Destination finale `Point 2`.
- Le passage Manuel échouait quand un path owned existait déjà.

## 6. GREEN — corrections appliquées

### `cinematic_builder_workspace.dart`

Zones modifiées :

```text
_toggleActorMovePathMode
_ActorMoveControls._buildNumberBadge
_ActorMoveControls.build
_ActorMoveControls._destinationStagePointId
```

Décisions :

- En mode `manual`, si aucun path owned n'existe, l'UI appelle `addCinematicManualPathForActorMove`.
- En mode `manual`, si un path owned existe déjà, l'UI appelle `setActorMovePathMode`.
- En mode `direct`, l'UI appelle `clearActorMoveManualPath`.
- Le picker exclut le Repère qui correspond à la Destination finale.
- Le badge utilise `colors.textInverse` au lieu de `Colors.white`.

Extrait significatif :

```dart
if (mode == CinematicTimelineActorPathMode.manual) {
  final context = widget.asset.stageContext ?? CinematicStageContext();
  final ownedPaths = context.manualPaths
      .where((path) => path.ownerActorMoveStepId == step.id)
      .toList(growable: false);
  if (ownedPaths.isEmpty) {
    final result = addCinematicManualPathForActorMove(
      dummyProject,
      cinematicId: widget.asset.id,
      actorMoveStepId: step.id,
    );
    await _updateCinematic(result.cinematic);
  } else {
    final result = setActorMovePathMode(
      dummyProject,
      cinematicId: widget.asset.id,
      stepId: step.id,
      pathMode: CinematicTimelineActorPathMode.manual,
    );
    await _updateCinematic(result.cinematic);
  }
} else {
  final result = clearActorMoveManualPath(
    dummyProject,
    cinematicId: widget.asset.id,
    stepId: step.id,
  );
  await _updateCinematic(result.cinematic);
}
```

Extrait du filtrage Destination :

```dart
final destinationStagePointId = _destinationStagePointId(asset, step);
final availablePoints = [
  for (final point
      in asset.stageContext?.stagePoints ?? const <CinematicStagePoint>[])
    if (point.id != destinationStagePointId) point,
];
```

### `cinematic_map_backdrop_preview_panel.dart`

Zone modifiée :

```text
Stack du rendu layer bitmap.
```

Décision :

- `CinematicManualPathPreviewOverlay` est placé après le painter foreground dans le rendu layer bitmap, pour éviter que le foreground masque le tracé.

### `cinematic_builder_workspace_test.dart`

Tests ajoutés / durcis :

- `V1-108 — Cinematic Manual Path Drawing UI V0` vérifie que `Point 2`, Destination finale, n'est pas proposé dans le menu des Points de passage.
- `V1-108 — manual mode reuses an existing path owned by a direct actorMove` vérifie la réutilisation d'un path owned existant.

## 7. Résultats de tests

### Tests V1-108 ciblés

Commande :

```bash
cd packages/map_editor
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --name "V1-108"
```

Sortie finale :

```text
00:03 +3: All tests passed!
```

Total :

```text
3 tests passés.
```

### Fichier complet Cinematic Builder

Commande :

```bash
cd packages/map_editor
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart
```

Sortie finale :

```text
00:32 +207: All tests passed!
```

Total :

```text
207 tests passés.
```

## 8. Analyse statique ciblée

Commande :

```bash
cd packages/map_editor
flutter analyze --no-fatal-infos lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart lib/src/ui/canvas/cinematics/cinematic_manual_path_preview_overlay.dart test/cinematic_builder_workspace_test.dart
```

Sortie :

```text
Analyzing 4 items...
37 issues found. (ran in 1.3s)
```

Bilan :

- exit code : 0 ;
- 37 diagnostics de niveau info `prefer_const_*` ;
- aucune erreur bloquante ;
- aucun warning bloquant.

## 9. Validation Git

Commande :

```bash
git diff --check
```

Sortie :

```text
<vide>
```

Exit code :

```text
0
```

## 10. Contenu complet du fichier créé

Fichier :

```text
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_manual_path_preview_overlay.dart
```

Contenu :

```dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import '../../../theme/theme.dart';
import 'cinematic_map_backdrop_viewport_transform.dart';

/// Renders the manual path overlay on the overworld canvas.
/// Draws a dashed path line and numbered badges for intermediate waypoints.
/// Part of NS-SCENES-V1-108-bis.
///
/// NOTE: This overlay is purely editor-only. Playback interpolation, pathfinding, and actual
/// runtime movements are explicitly out of scope for this lot.
class CinematicManualPathPreviewOverlay extends StatelessWidget {
  const CinematicManualPathPreviewOverlay({
    super.key,
    required this.asset,
    required this.selectedStep,
    this.actorDisplayPreviewModel,
    this.visualPrimitives = const [],
    required this.transform,
  });

  final CinematicAsset asset;
  final CinematicTimelineStep selectedStep;
  final CinematicActorDisplayPreviewModel? actorDisplayPreviewModel;
  final List<CinematicMapBackdropVisualPrimitive> visualPrimitives;
  final CinematicMapBackdropViewportTransform transform;

  @override
  Widget build(BuildContext context) {
    if (!transform.isUsable) {
      return const SizedBox.shrink();
    }

    final pathMode = cinematicTimelineActorPathModeOf(selectedStep);
    if (pathMode != CinematicTimelineActorPathMode.manual) {
      return const SizedBox.shrink();
    }

    final stageContext = asset.stageContext;
    if (stageContext == null) {
      return const SizedBox.shrink();
    }

    // Resolves the manual path associated with the selected actorMove step.
    // Safe lookup: returns null if no manual path matches the selected step id,
    // avoiding illegal construction of dummy/sentinel CinematicManualPath instances.
    final path = stageContext.manualPaths.cast<CinematicManualPath?>().firstWhere(
      (p) => p?.ownerActorMoveStepId == selectedStep.id,
      orElse: () => null,
    );

    if (path == null) {
      return const SizedBox.shrink();
    }

    final colors = context.pokeMapColors;

    // 1. Resolve departure point
    Offset? departureOffset;
    final actorId = selectedStep.actorId;
    if (actorId != null && actorId.isNotEmpty) {
      final actor = actorDisplayPreviewModel?.actorById(actorId);
      if (actor != null && actor.position.isResolved) {
        departureOffset = Offset(
          actor.position.x!.toDouble(),
          actor.position.y!.toDouble(),
        );
      } else {
        // Fallback to initial placement in stageContext
        for (final placement in stageContext.initialPlacements) {
          if (placement.actorId == actorId) {
            if (placement.stagePointId != null) {
              final sp = stageContext.stagePoints.cast<CinematicStagePoint?>().firstWhere(
                (p) => p?.id == placement.stagePointId,
                orElse: () => null,
              );
              if (sp != null) {
                departureOffset = Offset(sp.x, sp.y);
              }
            } else if (placement.targetId != null) {
              departureOffset = _resolveTargetOffset(
                targetId: placement.targetId!,
                asset: asset,
                actorDisplayPreviewModel: actorDisplayPreviewModel,
                visualPrimitives: visualPrimitives,
              );
            }
            break;
          }
        }
      }
    }

    // 2. Resolve intermediate waypoints
    final waypointOffsets = <Offset>[];
    for (final waypointId in path.waypointStagePointIds) {
      final sp = stageContext.stagePoints.cast<CinematicStagePoint?>().firstWhere(
        (p) => p?.id == waypointId,
        orElse: () => null,
      );
      if (sp != null) {
        waypointOffsets.add(Offset(sp.x, sp.y));
      }
    }

    // 3. Resolve destination point
    Offset? destinationOffset;
    final targetId = selectedStep.targetId;
    if (targetId != null && targetId.isNotEmpty) {
      destinationOffset = _resolveTargetOffset(
        targetId: targetId,
        asset: asset,
        actorDisplayPreviewModel: actorDisplayPreviewModel,
        visualPrimitives: visualPrimitives,
      );
    }

    // Connect the full path in tile coordinates
    final fullPathTiles = <Offset>[];
    if (departureOffset != null) {
      fullPathTiles.add(departureOffset);
    }
    fullPathTiles.addAll(waypointOffsets);
    if (destinationOffset != null) {
      fullPathTiles.add(destinationOffset);
    }

    if (fullPathTiles.length < 2) {
      return const SizedBox.shrink();
    }

    // Convert to preview offsets
    final previewPoints = fullPathTiles
        .map((tileOffset) => transform.tileToPreview(tileOffset.dx, tileOffset.dy))
        .toList();

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Path dashed line
        IgnorePointer(
          child: SizedBox.expand(
            child: CustomPaint(
              painter: _ManualPathLinePainter(
                points: previewPoints,
                color: colors.brandPrimary,
              ),
            ),
          ),
        ),
        // Waypoint badges (1, 2, 3...)
        for (int i = 0; i < waypointOffsets.length; i++) ...[
          _buildWaypointBadge(
            waypointOffsets[i],
            i + 1,
            colors,
          ),
        ],
      ],
    );
  }

  Widget _buildWaypointBadge(Offset tileOffset, int order, PokeMapColorTokens colors) {
    final previewOffset = transform.tileToPreview(tileOffset.dx, tileOffset.dy);
    const size = 18.0;
    return Positioned(
      left: previewOffset.dx - size / 2,
      top: previewOffset.dy - size / 2,
      width: size,
      height: size,
      child: IgnorePointer(
        child: Semantics(
          label: 'Point de passage $order',
          child: Container(
            decoration: BoxDecoration(
              color: colors.brandPrimary,
              shape: BoxShape.circle,
              border: Border.all(color: colors.surfaceBase, width: 1.5),
              boxShadow: [
                BoxShadow(
                  // Avoids hardcoded Colors.black. Uses design token textPrimary with values.
                  color: colors.textPrimary.withValues(alpha: 0.2),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Center(
              child: Text(
                '$order',
                style: TextStyle(
                  // Avoids hardcoded Colors.white. Uses design token textInverse.
                  color: colors.textInverse,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Offset? _resolveTargetOffset({
    required String targetId,
    required CinematicAsset asset,
    required CinematicActorDisplayPreviewModel? actorDisplayPreviewModel,
    required List<CinematicMapBackdropVisualPrimitive> visualPrimitives,
  }) {
    // 1. Resolve from actors if they are bound to this target
    if (actorDisplayPreviewModel != null) {
      for (final actor in actorDisplayPreviewModel.actors) {
        if (actor.position.isResolved &&
            actor.position.sourceKind ==
                CinematicActorPreviewPositionSourceKind.movementTarget &&
            actor.position.sourceId == targetId) {
          if (actor.position.x != null && actor.position.y != null) {
            return Offset(
              actor.position.x!.toDouble(),
              actor.position.y!.toDouble(),
            );
          }
        }
      }
    }

    final stageContext = asset.stageContext;
    if (stageContext == null) {
      return null;
    }

    // Find binding
    CinematicMovementTargetBinding? binding;
    for (final b in stageContext.movementTargetBindings) {
      if (b.targetId == targetId) {
        binding = b;
        break;
      }
    }

    if (binding == null) {
      return null;
    }

    if (binding.kind == CinematicMovementTargetBindingKind.stagePoint) {
      final sp = stageContext.stagePoints.cast<CinematicStagePoint?>().firstWhere(
        (p) => p?.id == binding!.sourceId,
        orElse: () => null,
      );
      if (sp != null) {
        return Offset(sp.x, sp.y);
      }
    } else if (binding.kind == CinematicMovementTargetBindingKind.mapEntity ||
        binding.kind == CinematicMovementTargetBindingKind.mapEvent) {
      final sourceId = binding.sourceId;
      for (final primitive in visualPrimitives) {
        if (primitive.id == sourceId || primitive.source == sourceId) {
          return Offset(primitive.x + 0.5, primitive.y + 0.5);
        }
      }
    }

    return null;
  }
}

class _ManualPathLinePainter extends CustomPainter {
  const _ManualPathLinePainter({
    required this.points,
    required this.color,
  });

  final List<Offset> points;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    for (int i = 0; i < points.length - 1; i++) {
      _drawDashedLine(canvas, points[i], points[i + 1], paint);
    }
  }

  void _drawDashedLine(Canvas canvas, Offset p1, Offset p2, Paint paint) {
    const dashWidth = 5.0;
    const dashSpace = 4.0;
    final dx = p2.dx - p1.dx;
    final dy = p2.dy - p1.dy;
    final distance = math.sqrt(dx * dx + dy * dy);
    if (distance == 0) return;
    final dashCount = (distance / (dashWidth + dashSpace)).floor();
    final xStep = dx / distance;
    final yStep = dy / distance;
    for (int i = 0; i < dashCount; i++) {
      final startDistance = i * (dashWidth + dashSpace);
      final start = Offset(
        p1.dx + xStep * startDistance,
        p1.dy + yStep * startDistance,
      );
      final end = Offset(
        start.dx + xStep * dashWidth,
        start.dy + yStep * dashWidth,
      );
      canvas.drawLine(start, end, paint);
    }
    // Draw small line to the end point if there is left-over distance
    final remainder = distance - (dashCount * (dashWidth + dashSpace));
    if (remainder > dashWidth) {
      final startDistance = dashCount * (dashWidth + dashSpace);
      final start = Offset(
        p1.dx + xStep * startDistance,
        p1.dy + yStep * startDistance,
      );
      final end = Offset(
        start.dx + xStep * dashWidth,
        start.dy + yStep * dashWidth,
      );
      canvas.drawLine(start, end, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ManualPathLinePainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.points.length != points.length ||
        !_listEquals(oldDelegate.points, points);
  }

  bool _listEquals(List<Offset> a, List<Offset> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
```

## 11. Anti-scope

Commandes non relancées pendant cette passe :

- `flutter test` complet de `packages/map_editor` ;
- `dart test` complet de `packages/map_core` ;
- génération de screenshot Visual Gate ;
- build macOS / Xcode.

Raison :

- la demande portait sur la correction post-review et la réécriture des rapports ;
- les validations relancées ciblent les fichiers et comportements modifiés par cette correction.

## 12. Auto-critique

Ce qui est prouvé :

- les deux bugs identifiés en revue sont reproduits en RED puis corrigés ;
- le fichier complet `cinematic_builder_workspace_test.dart` reste vert ;
- l'analyse ciblée ne remonte pas d'erreur bloquante ;
- aucun problème de whitespace n'est détecté par `git diff --check`.

Ce qui n'est pas prouvé :

- la capture Visual Gate n'a pas été régénérée après correction ;
- la suite complète `packages/map_editor` n'a pas été relancée ;
- les rapports restent des fichiers non suivis tant qu'aucun commit n'est demandé.

## 13. État Git final après réécriture des rapports

Commande :

```bash
git diff --check && git diff --stat && git diff --name-only && git status --short --untracked-files=all
```

Sortie `git diff --check` :

```text
<vide>
```

Sortie `git diff --stat` / `git diff --name-only` / `git status` :

```text
 .../cinematics/cinematic_builder_workspace.dart    | 478 ++++++++++++++++++-
 .../cinematic_map_backdrop_preview_panel.dart      |  41 ++
 .../cinematics/cinematics_library_workspace.dart   |   3 +
 .../src/ui/canvas/narrative_workspace_canvas.dart  |  24 +
 .../test/cinematic_builder_workspace_test.dart     | 519 ++++++++++++++++++++-
 .../scenes/road_map_scene_builder_authoring.md     |  16 +-
 reports/narrativeStudio/scenes/road_map_scenes.md  |  19 +-
 7 files changed, 1076 insertions(+), 24 deletions(-)
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart
packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
packages/map_editor/test/cinematic_builder_workspace_test.dart
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md
 M packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
 M packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart
 M packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart
 M packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
 M packages/map_editor/test/cinematic_builder_workspace_test.dart
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_manual_path_preview_overlay.dart
?? reports/narrativeStudio/scenes/ns_scenes_v1_108_bis_cinematic_manual_path_drawing_ui_evidence_visual_gate_cleanup.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_108_bis_evidence_pack.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_108_cinematic_manual_path_drawing_ui_v0.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_108_evidence_pack.md
?? reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_108_cinematic_manual_path_drawing_ui_v0.png
```
