# NS-SCENES-V1-131 — Evidence Pack

## Verdict

`NS-SCENES-V1-131 — Cinematic Camera Target / Zoom Core Model V0` : `DONE`.

V1-132 est recommandé, non démarré :

```text
NS-SCENES-V1-132 — Cinematic Camera Target / Zoom Editor UI V0
```

## Gate 0 — état initial

Commande :

```bash
pwd
git branch --show-current
git status --short --untracked-files=all
git diff --stat
git diff --name-only
git log --oneline -n 10
```

Sortie utile exacte :

```text
/Users/karim/Project/pokemonProject
main
git status --short --untracked-files=all: <vide>
git diff --stat: <vide>
git diff --name-only: <vide>
47660d78 NS-SCENES-V1-130 — Cinematic Camera Target Zoom Authoring Prep Contract
2344303e update selbrume
3edcfe36 Allow deeper cinematic timeline zoom out
6bb457a4 Polish cinematic emote dropdowns
f16314fe NS-SCENES-V1-129 — Cinematic Emote Preview Playback UI V0
```

`codex_rules.md` : absent. Le fichier présent et lu est `codex_rule.md`.

## Fichiers créés

```text
reports/narrativeStudio/scenes/ns_scenes_v1_131_cinematic_camera_target_zoom_core_model_v0.md
reports/narrativeStudio/scenes/ns_scenes_v1_131_evidence_pack.md
```

Le rapport principal contient les sections 1 à 13 demandées :

```text
1. Résumé exécutif.
2. Rappel du contrat V1-130.
3. Audit initial.
4. Décisions d’implémentation.
5. Fichiers modifiés.
6. Modèle ajouté.
7. Opérations pures ajoutées.
8. Diagnostics ajoutés.
9. Backward compatibility JSON.
10. Tests exécutés.
11. Limites restantes.
12. Prochain lot recommandé.
13. Auto-critique finale.
```

Le présent Evidence Pack contient :

```text
Gate 0
fichiers créés/modifiés/supprimés
code généré
tests RED/GREEN
analyses
roadmaps
anti-scope
auto-review
critique du prompt
checks finaux
```

## Fichiers modifiés

```text
packages/map_core/lib/src/authoring/cinematic_authoring_operations.dart
packages/map_core/lib/src/diagnostics/cinematic_diagnostics.dart
packages/map_core/lib/src/read_models/cinematic_preview_playback_plan.dart
packages/map_core/test/cinematic_asset_test.dart
packages/map_core/test/cinematic_authoring_operations_test.dart
packages/map_core/test/cinematic_diagnostics_test.dart
packages/map_core/test/cinematic_preview_playback_plan_test.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md
```

## Fichiers supprimés

```text
<vide>
```

## Code généré — modèle authoring

Fichier : `packages/map_core/lib/src/authoring/cinematic_authoring_operations.dart`

```dart
enum CinematicTimelineCameraMode {
  reset,
  hold,
  focus,
}

enum CinematicCameraTargetKind {
  sceneCenter,
  actor,
  stagePoint,
}

enum CinematicCameraZoomPreset {
  wide,
  medium,
  close,
}

final class CinematicCameraTargetBinding {
  const CinematicCameraTargetBinding._({
    required this.kind,
    this.actorId,
    this.stagePointId,
    this.label,
  });

  factory CinematicCameraTargetBinding.sceneCenter({
    String? label,
  }) {
    return CinematicCameraTargetBinding._(
      kind: CinematicCameraTargetKind.sceneCenter,
      label: _trimOptional(label),
    );
  }

  factory CinematicCameraTargetBinding.actor({
    required String actorId,
    String? label,
  }) {
    return CinematicCameraTargetBinding._(
      kind: CinematicCameraTargetKind.actor,
      actorId: _trimRequired(
        actorId,
        'actorId',
        'Camera actor focus requires an actorId.',
      ),
      label: _trimOptional(label),
    );
  }

  factory CinematicCameraTargetBinding.stagePoint({
    required String stagePointId,
    String? label,
  }) {
    return CinematicCameraTargetBinding._(
      kind: CinematicCameraTargetKind.stagePoint,
      stagePointId: _trimRequired(
        stagePointId,
        'stagePointId',
        'Camera stage point focus requires a stagePointId.',
      ),
      label: _trimOptional(label),
    );
  }

  final CinematicCameraTargetKind kind;
  final String? actorId;
  final String? stagePointId;
  final String? label;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CinematicCameraTargetBinding &&
          other.kind == kind &&
          other.actorId == actorId &&
          other.stagePointId == stagePointId &&
          other.label == label;

  @override
  int get hashCode => Object.hash(kind, actorId, stagePointId, label);
}

final class CinematicTimelineCameraFocusBinding {
  const CinematicTimelineCameraFocusBinding({
    required this.target,
    required this.zoomPreset,
  });

  final CinematicCameraTargetBinding target;
  final CinematicCameraZoomPreset zoomPreset;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CinematicTimelineCameraFocusBinding &&
          other.target == target &&
          other.zoomPreset == zoomPreset;

  @override
  int get hashCode => Object.hash(target, zoomPreset);
}
```

Metadata ajoutées :

```dart
const cinematicTimelineCameraTargetKindMetadataKey = 'camera.targetKind';
const cinematicTimelineCameraTargetActorIdMetadataKey = 'camera.targetActorId';
const cinematicTimelineCameraTargetStagePointIdMetadataKey =
    'camera.targetStagePointId';
const cinematicTimelineCameraZoomPresetMetadataKey = 'camera.zoomPreset';
```

## Code généré — opérations pures

```dart
CinematicTimelineBasicBlockStepResult addCinematicTimelineCameraFocusStep(
  ProjectManifest project, {
  required String cinematicId,
  required CinematicCameraTargetBinding target,
  required CinematicCameraZoomPreset zoomPreset,
  String? afterStepId,
  int? durationMs,
}) {
  return addCinematicTimelineBasicBlockStep(
    project,
    cinematicId: cinematicId,
    blockKind: CinematicTimelineBasicBlockKind.camera,
    afterStepId: afterStepId,
    durationMs: durationMs,
    cameraMode: CinematicTimelineCameraMode.focus,
    cameraFocusBinding: CinematicTimelineCameraFocusBinding(
      target: target,
      zoomPreset: zoomPreset,
    ),
  );
}
```

Signature étendue :

```dart
CinematicTimelineBasicBlockStepResult addCinematicTimelineBasicBlockStep(
  ProjectManifest project, {
  required String cinematicId,
  required CinematicTimelineBasicBlockKind blockKind,
  String? afterStepId,
  int? durationMs,
  CinematicTimelineFadeMode fadeMode = CinematicTimelineFadeMode.fadeIn,
  CinematicTimelineCameraMode cameraMode = CinematicTimelineCameraMode.reset,
  CinematicTimelineCameraFocusBinding? cameraFocusBinding,
})

CinematicTimelineStepUpdateResult updateCinematicTimelineBasicBlockStep(
  ProjectManifest project, {
  required String cinematicId,
  required String stepId,
  int? durationMs,
  CinematicTimelineFadeMode? fadeMode,
  CinematicTimelineCameraMode? cameraMode,
  CinematicTimelineCameraFocusBinding? cameraFocusBinding,
})
```

Nettoyage metadata :

```dart
Map<String, String> _cameraMetadata(
  CinematicTimelineCameraMode mode, {
  CinematicTimelineCameraFocusBinding? focusBinding,
  Map<String, String>? existing,
}) {
  if (mode == CinematicTimelineCameraMode.focus && focusBinding == null) {
    throw ArgumentError('Camera focus mode requires a focus binding.');
  }
  final metadata =
      existing == null ? <String, String>{} : Map<String, String>.of(existing);
  _removeCameraFocusMetadata(metadata);
  metadata[cinematicTimelineCameraModeMetadataKey] = mode.name;
  if (mode != CinematicTimelineCameraMode.focus) {
    return metadata;
  }

  final binding = focusBinding!;
  metadata[cinematicTimelineCameraTargetKindMetadataKey] =
      binding.target.kind.name;
  metadata[cinematicTimelineCameraZoomPresetMetadataKey] =
      binding.zoomPreset.name;
  switch (binding.target.kind) {
    case CinematicCameraTargetKind.sceneCenter:
      break;
    case CinematicCameraTargetKind.actor:
      metadata[cinematicTimelineCameraTargetActorIdMetadataKey] =
          binding.target.actorId!;
      break;
    case CinematicCameraTargetKind.stagePoint:
      metadata[cinematicTimelineCameraTargetStagePointIdMetadataKey] =
          binding.target.stagePointId!;
      break;
  }
  return metadata;
}

void _removeCameraFocusMetadata(Map<String, String> metadata) {
  metadata
    ..remove(cinematicTimelineCameraTargetKindMetadataKey)
    ..remove(cinematicTimelineCameraTargetActorIdMetadataKey)
    ..remove(cinematicTimelineCameraTargetStagePointIdMetadataKey)
    ..remove(cinematicTimelineCameraZoomPresetMetadataKey);
}
```

Validation target :

```dart
void _validateCameraFocusBinding(
  CinematicAsset cinematic,
  CinematicTimelineCameraFocusBinding? binding,
) {
  if (binding == null) {
    throw ArgumentError('Camera focus mode requires a focus binding.');
  }
  switch (binding.target.kind) {
    case CinematicCameraTargetKind.sceneCenter:
      return;
    case CinematicCameraTargetKind.actor:
      _requireActor(cinematic, binding.target.actorId!);
      return;
    case CinematicCameraTargetKind.stagePoint:
      _requireStagePoint(cinematic, binding.target.stagePointId!);
      return;
  }
}
```

## Code généré — helpers metadata

```dart
CinematicTimelineCameraMode? cinematicTimelineCameraModeOf(
  CinematicTimelineStep step,
) {
  if (step.kind != CinematicTimelineStepKind.camera) {
    return null;
  }
  return switch (step.metadata[cinematicTimelineCameraModeMetadataKey]) {
    'reset' => CinematicTimelineCameraMode.reset,
    'hold' => CinematicTimelineCameraMode.hold,
    'focus' => CinematicTimelineCameraMode.focus,
    _ => null,
  };
}

CinematicCameraTargetKind? cinematicTimelineCameraTargetKindOf(
  CinematicTimelineStep step,
) {
  if (step.kind != CinematicTimelineStepKind.camera) {
    return null;
  }
  return switch (step.metadata[cinematicTimelineCameraTargetKindMetadataKey]) {
    'sceneCenter' => CinematicCameraTargetKind.sceneCenter,
    'actor' => CinematicCameraTargetKind.actor,
    'stagePoint' => CinematicCameraTargetKind.stagePoint,
    _ => null,
  };
}

CinematicCameraZoomPreset? cinematicTimelineCameraZoomPresetOf(
  CinematicTimelineStep step,
) {
  if (step.kind != CinematicTimelineStepKind.camera) {
    return null;
  }
  return switch (step.metadata[cinematicTimelineCameraZoomPresetMetadataKey]) {
    'wide' => CinematicCameraZoomPreset.wide,
    'medium' => CinematicCameraZoomPreset.medium,
    'close' => CinematicCameraZoomPreset.close,
    _ => null,
  };
}

CinematicCameraTargetBinding? cinematicTimelineCameraTargetBindingOf(
  CinematicTimelineStep step,
) {
  final kind = cinematicTimelineCameraTargetKindOf(step);
  if (kind == null) {
    return null;
  }
  switch (kind) {
    case CinematicCameraTargetKind.sceneCenter:
      return CinematicCameraTargetBinding.sceneCenter();
    case CinematicCameraTargetKind.actor:
      final actorId = _trimOptional(
          step.metadata[cinematicTimelineCameraTargetActorIdMetadataKey]);
      if (actorId == null) {
        return null;
      }
      return CinematicCameraTargetBinding.actor(actorId: actorId);
    case CinematicCameraTargetKind.stagePoint:
      final stagePointId = _trimOptional(
        step.metadata[cinematicTimelineCameraTargetStagePointIdMetadataKey],
      );
      if (stagePointId == null) {
        return null;
      }
      return CinematicCameraTargetBinding.stagePoint(
          stagePointId: stagePointId);
  }
}

CinematicTimelineCameraFocusBinding? cinematicTimelineCameraFocusBindingOf(
  CinematicTimelineStep step,
) {
  if (cinematicTimelineCameraModeOf(step) !=
      CinematicTimelineCameraMode.focus) {
    return null;
  }
  final target = cinematicTimelineCameraTargetBindingOf(step);
  final zoomPreset = cinematicTimelineCameraZoomPresetOf(step);
  if (target == null || zoomPreset == null) {
    return null;
  }
  return CinematicTimelineCameraFocusBinding(
    target: target,
    zoomPreset: zoomPreset,
  );
}
```

## Code généré — diagnostics

Fichier : `packages/map_core/lib/src/diagnostics/cinematic_diagnostics.dart`

Codes ajoutés :

```dart
cameraTargetMissing,
cameraTargetKindUnsupported,
cameraTargetActorMissing,
cameraTargetActorUnknown,
cameraTargetActorWithoutPosition,
cameraTargetStagePointMissing,
cameraTargetStagePointUnknown,
cameraTargetStagePointOutOfMap,
cameraTargetStageMapMissing,
cameraZoomPresetMissing,
cameraZoomPresetUnsupported,
cameraModeUnsupported,
cameraGeometryUnavailable,
```

Diagnostic principal :

```dart
void _diagnoseCameraStep(
  CinematicAsset cinematic,
  CinematicTimelineStep step, {
  required Set<String> requiredActorIds,
  required List<CinematicDiagnostic> diagnostics,
  int? mapWidth,
  int? mapHeight,
}) {
  final rawMode = step.metadata[cinematicTimelineCameraModeMetadataKey]?.trim();
  final mode = cinematicTimelineCameraModeOf(step);
  if (mode == null) {
    if (rawMode != null && rawMode.isNotEmpty) {
      diagnostics.add(
        CinematicDiagnostic(
          code: CinematicDiagnosticCode.cameraModeUnsupported,
          severity: CinematicDiagnosticSeverity.error,
          message: 'Le mode caméra "$rawMode" n’est pas supporté.',
          cinematicId: cinematic.id,
          stepId: step.id,
          referenceId: rawMode,
          target: CinematicDiagnosticTarget.step,
          suggestedFixLabel:
              'Choisir réinitialiser, maintenir ou cadrer une cible.',
        ),
      );
    }
    return;
  }
  if (mode != CinematicTimelineCameraMode.focus) {
    return;
  }

  final rawTargetKind =
      step.metadata[cinematicTimelineCameraTargetKindMetadataKey]?.trim();
  final targetKind = cinematicTimelineCameraTargetKindOf(step);
  if (rawTargetKind == null || rawTargetKind.isEmpty) {
    diagnostics.add(
      CinematicDiagnostic(
        code: CinematicDiagnosticCode.cameraTargetMissing,
        severity: CinematicDiagnosticSeverity.error,
        message: 'Un cadrage caméra doit choisir une cible.',
        cinematicId: cinematic.id,
        stepId: step.id,
        target: CinematicDiagnosticTarget.reference,
        suggestedFixLabel:
            'Choisir le centre de scène, un acteur ou un repère.',
      ),
    );
  } else if (targetKind == null) {
    diagnostics.add(
      CinematicDiagnostic(
        code: CinematicDiagnosticCode.cameraTargetKindUnsupported,
        severity: CinematicDiagnosticSeverity.error,
        message: 'Le type de cible caméra "$rawTargetKind" n’est pas supporté.',
        cinematicId: cinematic.id,
        stepId: step.id,
        referenceId: rawTargetKind,
        target: CinematicDiagnosticTarget.reference,
        suggestedFixLabel:
            'Choisir le centre de scène, un acteur ou un repère.',
      ),
    );
  } else {
    switch (targetKind) {
      case CinematicCameraTargetKind.sceneCenter:
        break;
      case CinematicCameraTargetKind.actor:
        _diagnoseCameraActorTarget(
          cinematic,
          step,
          requiredActorIds: requiredActorIds,
          diagnostics: diagnostics,
        );
        break;
      case CinematicCameraTargetKind.stagePoint:
        _diagnoseCameraStagePointTarget(
          cinematic,
          step,
          diagnostics: diagnostics,
          mapWidth: mapWidth,
          mapHeight: mapHeight,
        );
        break;
    }
  }

  final rawZoom =
      step.metadata[cinematicTimelineCameraZoomPresetMetadataKey]?.trim();
  final zoomPreset = cinematicTimelineCameraZoomPresetOf(step);
  if (rawZoom == null || rawZoom.isEmpty) {
    diagnostics.add(
      CinematicDiagnostic(
        code: CinematicDiagnosticCode.cameraZoomPresetMissing,
        severity: CinematicDiagnosticSeverity.error,
        message: 'Un cadrage caméra doit choisir un niveau de zoom.',
        cinematicId: cinematic.id,
        stepId: step.id,
        target: CinematicDiagnosticTarget.step,
        suggestedFixLabel: 'Choisir plan large, plan moyen ou gros plan.',
      ),
    );
  } else if (zoomPreset == null) {
    diagnostics.add(
      CinematicDiagnostic(
        code: CinematicDiagnosticCode.cameraZoomPresetUnsupported,
        severity: CinematicDiagnosticSeverity.error,
        message: 'Le zoom caméra "$rawZoom" n’est pas supporté.',
        cinematicId: cinematic.id,
        stepId: step.id,
        referenceId: rawZoom,
        target: CinematicDiagnosticTarget.step,
        suggestedFixLabel: 'Choisir plan large, plan moyen ou gros plan.',
      ),
    );
  }
}
```

Les helpers `_diagnoseCameraActorTarget` et `_diagnoseCameraStagePointTarget` émettent :

```text
cameraTargetActorMissing
cameraTargetActorUnknown
cameraTargetActorWithoutPosition
cameraTargetStagePointMissing
cameraTargetStagePointUnknown
cameraTargetStageMapMissing
cameraTargetStagePointOutOfMap
```

## Code généré — playback symbolique

Fichier : `packages/map_core/lib/src/read_models/cinematic_preview_playback_plan.dart`

```dart
case CinematicTimelineStepKind.camera:
  final cameraMode = _cameraModeOf(step);
  if (cameraMode == null) {
    itemDiagnostics.add(_cameraUnsupportedDiagnostic(step));
    hasUnsupportedSteps = true;
  } else {
    cameraModes[step.id] = cameraMode;
    if (cameraMode == CinematicTimelineCameraMode.focus) {
      itemDiagnostics.add(_cameraUnsupportedDiagnostic(step));
      supported = false;
      hasUnsupportedSteps = true;
    }
  }
```

```dart
return CinematicCameraPlaybackPose(
  isActive: true,
  isSupported: mode != null && item.supported,
  activeStepId: item.stepId,
  mode: mode,
  progress: _timelineItemProgress(item, clampedTimeMs),
  diagnostics: item.diagnostics,
);
```

```dart
CinematicTimelineCameraMode? _cameraModeOf(CinematicTimelineStep step) {
  return cinematicTimelineCameraModeOf(step);
}
```

## Code généré — correction editor compile-only

Fichier : `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart`

```dart
final currentMode = step.metadata[cinematicTimelineCameraModeMetadataKey];
const authorableModes = [
  CinematicTimelineCameraMode.reset,
  CinematicTimelineCameraMode.hold,
];
```

```dart
for (final mode in authorableModes)
  _InlineControlAction(
    label: _cameraModeLabel(mode),
    button: PokeMapButton(
      key: ValueKey('cinematic-builder-camera-mode-${mode.name}'),
      onPressed: () {
        onUpdateBasicBlock(step, cameraMode: mode);
      },
      variant: PokeMapButtonVariant.secondary,
      size: PokeMapButtonSize.small,
      isSelected: currentMode == mode.name,
      leading: const Icon(CupertinoIcons.video_camera),
      child: const SizedBox.shrink(),
    ),
  ),
```

```dart
String _cameraModeLabel(CinematicTimelineCameraMode mode) {
  return switch (mode) {
    CinematicTimelineCameraMode.reset => 'Reset',
    CinematicTimelineCameraMode.hold => 'Hold',
    CinematicTimelineCameraMode.focus => 'Cadrer une cible',
  };
}
```

## Tests RED

Commande :

```bash
cd packages/map_core
dart test --reporter=compact test/cinematic_asset_test.dart test/cinematic_authoring_operations_test.dart test/cinematic_diagnostics_test.dart test/cinematic_preview_playback_plan_test.dart --name "V1-131"
```

Sortie utile exacte avant implémentation :

```text
Failed to load "test/cinematic_asset_test.dart":
test/cinematic_asset_test.dart:92:17: Error: Undefined name 'cinematicTimelineCameraTargetKindMetadataKey'.
test/cinematic_asset_test.dart:106:22: Error: Method not found: 'cinematicTimelineCameraTargetBindingOf'.
test/cinematic_asset_test.dart:109:79: Error: Member not found: 'focus'.

Failed to load "test/cinematic_authoring_operations_test.dart":
Error: Undefined name 'CinematicCameraTargetBinding'.
Error: Undefined name 'CinematicCameraZoomPreset'.
Error: Method not found: 'addCinematicTimelineCameraFocusStep'.
Error: No named parameter with the name 'cameraFocusBinding'.

Failed to load "test/cinematic_diagnostics_test.dart":
Error: Member not found: 'cameraTargetMissing'.
Error: Member not found: 'cameraTargetActorMissing'.
Error: Member not found: 'cameraTargetStagePointUnknown'.
Error: Member not found: 'cameraZoomPresetUnsupported'.
Error: Member not found: 'cameraModeUnsupported'.

Failed to load "test/cinematic_preview_playback_plan_test.dart":
test/cinematic_preview_playback_plan_test.dart:445:65: Error: Member not found: 'focus'.
Some tests failed.
```

## Tests GREEN V1-131

Commande :

```bash
cd packages/map_core
dart test --reporter=compact test/cinematic_asset_test.dart test/cinematic_authoring_operations_test.dart test/cinematic_diagnostics_test.dart test/cinematic_preview_playback_plan_test.dart --name "V1-131"
```

Sortie exacte utile :

```text
00:00 +0: loading test/cinematic_asset_test.dart
00:00 +0: test/cinematic_asset_test.dart: CinematicAsset V1-131 round-trips camera focus metadata through typed helpers
00:00 +1: test/cinematic_asset_test.dart: CinematicAsset V1-131 legacy camera reset and hold remain readable
00:00 +2: loading test/cinematic_authoring_operations_test.dart
00:00 +2: test/cinematic_authoring_operations_test.dart: Cinematic authoring operations V1-131 adds camera focus blocks with typed target bindings
00:00 +3: test/cinematic_authoring_operations_test.dart: Cinematic authoring operations V1-131 updates camera focus and cleans stale camera bindings
00:00 +4: test/cinematic_authoring_operations_test.dart: Cinematic authoring operations V1-131 validates camera focus target bindings
00:00 +5: test/cinematic_diagnostics_test.dart: Cinematic diagnostics V1-131 diagnoses invalid camera focus metadata
00:00 +6: test/cinematic_preview_playback_plan_test.dart: buildCinematicPreviewPlaybackPlan V1-131 camera focus remains symbolic until geometry exists
00:00 +8: All tests passed!
```

## Régressions core

Commande :

```bash
cd packages/map_core
set -o pipefail; dart test --reporter=compact test/cinematic_authoring_operations_test.dart test/cinematic_diagnostics_test.dart test/cinematic_asset_test.dart test/cinematic_preview_playback_plan_test.dart 2>&1 | perl -pe 's/\r/\n/g' | tail -n 8
```

Sortie exacte :

```text
00:00 +172: test/cinematic_authoring_operations_test.dart: Cinematic authoring operations manual paths removeCinematicManualPathWaypointAt removes waypoint at index
00:00 +172: test/cinematic_authoring_operations_test.dart: Cinematic authoring operations manual paths reorderCinematicManualPathWaypoint reorders waypoints
00:00 +173: test/cinematic_authoring_operations_test.dart: Cinematic authoring operations manual paths reorderCinematicManualPathWaypoint reorders waypoints
00:00 +173: test/cinematic_authoring_operations_test.dart: Cinematic authoring operations manual paths setActorMovePathMode updates mode without affecting targets
00:00 +174: test/cinematic_authoring_operations_test.dart: Cinematic authoring operations manual paths setActorMovePathMode updates mode without affecting targets
00:00 +174: test/cinematic_authoring_operations_test.dart: Cinematic authoring operations manual paths clearActorMoveManualPath resets step and deletes path
00:00 +175: test/cinematic_authoring_operations_test.dart: Cinematic authoring operations manual paths clearActorMoveManualPath resets step and deletes path
00:00 +175: All tests passed!
```

## Analyse core

Commande :

```bash
cd packages/map_core
dart analyze lib/src/authoring/cinematic_authoring_operations.dart lib/src/diagnostics/cinematic_diagnostics.dart lib/src/read_models/cinematic_preview_playback_plan.dart test/cinematic_asset_test.dart test/cinematic_authoring_operations_test.dart test/cinematic_diagnostics_test.dart test/cinematic_preview_playback_plan_test.dart
```

Sortie exacte :

```text
Analyzing cinematic_authoring_operations.dart, cinematic_diagnostics.dart, cinematic_preview_playback_plan.dart, cinematic_asset_test.dart, cinematic_authoring_operations_test.dart, cinematic_diagnostics_test.dart, cinematic_preview_playback_plan_test.dart...
No issues found!
```

## Régression editor ciblée

Commande :

```bash
cd packages/map_editor
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --name "V1-124"
```

Sortie exacte utile :

```text
00:04 +0: V1-124 active supported camera shows camera preview overlay
00:06 +1: V1-124 unsupported camera shows no-code camera fallback message
00:06 +2: V1-124 missing camera mode shows Cadrage caméra incomplet
00:06 +3: V1-124 no active camera hides camera overlay before and after step
00:07 +4: V1-124 Play Pause Stop and Reset update camera overlay from playback time
00:07 +5: V1-124 seek and scrub update camera overlay without probe or selection changes
00:07 +6: captures V1-124 cinematic camera preview playback ui visual gate
00:07 +7: All tests passed!
```

## Analyse editor ciblée

Commande :

```bash
cd packages/map_editor
flutter analyze --no-fatal-infos lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart test/cinematic_builder_workspace_test.dart
```

Sortie exacte utile :

```text
Analyzing 2 items...
35 issues found. (ran in 2.0s)
```

Exit code : `0`.

Nature des 35 infos : `prefer_const_constructors` / `prefer_const_literals_to_create_immutables`, préexistantes dans les zones larges analysées et non bloquantes avec `--no-fatal-infos`.

## Roadmaps

Fichiers mis à jour :

```text
reports/narrativeStudio/scenes/road_map_scenes.md
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
```

État attendu :

```text
NS-SCENES-V1-131 — DONE
NS-SCENES-V1-132 — RECOMMANDÉ, non démarré
```

## Anti-scope

Respecté :

- pas de `packages/map_runtime` ;
- pas de `packages/map_gameplay` ;
- pas de `packages/map_battle` ;
- pas de `examples/playable_runtime_host` ;
- pas de `assets` ;
- pas de `selbrume` ;
- pas de `pubspec.yaml` ;
- pas de screenshot V1-131 ;
- pas de runtime, Flame, GameState ;
- pas de géométrie caméra ;
- pas d'UI d'authoring complète Camera Target / Zoom ;
- pas de V1-132.

## Critique du prompt

Le prompt était cohérent avec l'état V1-130. Deux points demandaient adaptation :

1. `cameraGeometryUnavailable` est listé comme diagnostic core, mais V1-131 interdit la géométrie caméra. J'ai ajouté le code diagnostic comme contrat futur, sans l'émettre systématiquement pour ne pas mentir à l'UI.
2. Le prompt demandait des diagnostics comme `cameraTargetActorWithoutPosition`. Les données disponibles permettent seulement un warning basé sur les `initialPlacements`, pas une garantie de rendu final.

## Auto-review indépendante

Vérifications réalisées :

- pas d'UI Camera Target / Zoom complète ;
- pas de géométrie caméra ;
- pas de zoom numérique réel ;
- pas de mutation viewport editor ;
- reset/hold backward-compatible ;
- focus stocké en metadata typée ;
- operations reset/hold nettoient target/zoom ;
- focus actor/stagePoint nettoie les IDs contradictoires ;
- actorMove, movementTargets et manual paths non modifiés par les opérations Camera ;
- diagnostics n'inventent pas de géométrie disponible ;
- read model playback `focus` reste symbolique et unsupported ;
- code généré inclus dans ce rapport.

## Checks finaux

Commande :

```bash
git diff --check
```

Sortie exacte :

```text
<vide>
```

Commande :

```bash
git diff --stat
```

Sortie exacte :

```text
 .../authoring/cinematic_authoring_operations.dart  | 371 ++++++++++++++++++++-
 .../lib/src/diagnostics/cinematic_diagnostics.dart | 354 ++++++++++++++++++--
 .../cinematic_preview_playback_plan.dart           |  18 +-
 packages/map_core/test/cinematic_asset_test.dart   |  89 ++++-
 .../test/cinematic_authoring_operations_test.dart  | 273 +++++++++++++++
 .../map_core/test/cinematic_diagnostics_test.dart  | 209 ++++++++++++
 .../test/cinematic_preview_playback_plan_test.dart |  40 +++
 .../cinematics/cinematic_builder_workspace.dart    |  15 +-
 .../scenes/road_map_scene_builder_authoring.md     |  61 ++--
 reports/narrativeStudio/scenes/road_map_scenes.md  |  62 ++--
 10 files changed, 1386 insertions(+), 106 deletions(-)
```

Note : les deux rapports V1-131 sont des fichiers non suivis au moment du check final ; `git diff --stat` ne liste que les fichiers suivis modifiés.

Commande :

```bash
git diff --name-only
```

Sortie exacte :

```text
packages/map_core/lib/src/authoring/cinematic_authoring_operations.dart
packages/map_core/lib/src/diagnostics/cinematic_diagnostics.dart
packages/map_core/lib/src/read_models/cinematic_preview_playback_plan.dart
packages/map_core/test/cinematic_asset_test.dart
packages/map_core/test/cinematic_authoring_operations_test.dart
packages/map_core/test/cinematic_diagnostics_test.dart
packages/map_core/test/cinematic_preview_playback_plan_test.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md
```

Commande :

```bash
git status --short --untracked-files=all
```

Sortie exacte :

```text
 M packages/map_core/lib/src/authoring/cinematic_authoring_operations.dart
 M packages/map_core/lib/src/diagnostics/cinematic_diagnostics.dart
 M packages/map_core/lib/src/read_models/cinematic_preview_playback_plan.dart
 M packages/map_core/test/cinematic_asset_test.dart
 M packages/map_core/test/cinematic_authoring_operations_test.dart
 M packages/map_core/test/cinematic_diagnostics_test.dart
 M packages/map_core/test/cinematic_preview_playback_plan_test.dart
 M packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_131_cinematic_camera_target_zoom_core_model_v0.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_131_evidence_pack.md
```

Commande :

```bash
git diff --name-only -- packages/map_runtime packages/map_gameplay packages/map_battle examples/playable_runtime_host assets selbrume pubspec.yaml
```

Sortie exacte :

```text
<vide>
```

Commande :

```bash
find reports/narrativeStudio/scenes/screenshots -maxdepth 1 -name '*v1_131*' -print
```

Sortie exacte :

```text
<vide>
```

Commande :

```bash
git diff --unified=0 -- packages/map_core packages/map_editor | rg -n "GameState|PlayableMapGame|package:flame|map_runtime|map_gameplay|activeEmotes|actorEmote|emoteId|manualPathId|centerX|centerY|CameraComponent|Flame" || true
```

Sortie exacte :

```text
<vide>
```
