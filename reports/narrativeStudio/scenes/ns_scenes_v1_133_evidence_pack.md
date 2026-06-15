# NS-SCENES-V1-133 — Evidence Pack

## Statut

```text
NS-SCENES-V1-133 : DONE.
Roadmap headers : alignes vers V1-134.
Prochain lot recommande : NS-SCENES-V1-134 — Cinematic Camera Geometry Preview UI V0.
Aucun screenshot.
V1-134 non demarre.
```

## Gate 0

```bash
pwd
```

```text
/Users/karim/Project/pokemonProject
```

```bash
git branch --show-current
```

```text
main
```

```bash
git status --short --untracked-files=all
```

```text
<vide>
```

```bash
git diff --stat
```

```text
<vide>
```

```bash
git diff --name-only
```

```text
<vide>
```

```bash
git log --oneline -n 10
```

```text
d4e0b28b NS-SCENES-V1-132 — Cinematic Camera Target Zoom Editor UI V0
882c2c23 NS-SCENES-V1-131 — Cinematic Camera Target Zoom Core Model V0
a7bb9b42 update selbrume
4c3040a3 update selbrume
47660d78 NS-SCENES-V1-130 — Cinematic Camera Target Zoom Authoring Prep Contract
2344303e update selbrume
3edcfe36 Allow deeper cinematic timeline zoom out
6bb457a4 Polish cinematic emote dropdowns
f16314fe NS-SCENES-V1-129 — Cinematic Emote Preview Playback UI V0
6da6410f NS-SCENES-V1-128 — Cinematic Emote Block Editor UI V0
```

## Regles lues

Fichiers lus :

- `AGENTS.md`
- `agent_rules.md`
- `codex_rule.md`
- `skills/README.md`
- `skills/using-superpowers/SKILL.md`
- `skills/test-driven-development/SKILL.md`
- `skills/verification-before-completion/SKILL.md`
- `skills/writing-plans/SKILL.md`

`codex_rules.md` : absent. Le fichier existant `codex_rule.md` a ete applique.

## Preconditions V1-131 / V1-132

V1-131 confirme par recherche locale :

```text
packages/map_core/lib/src/authoring/cinematic_authoring_operations.dart:173:enum CinematicCameraTargetKind
packages/map_core/lib/src/authoring/cinematic_authoring_operations.dart:179:enum CinematicCameraZoomPreset
packages/map_core/lib/src/authoring/cinematic_authoring_operations.dart:185:final class CinematicCameraTargetBinding
packages/map_core/lib/src/authoring/cinematic_authoring_operations.dart:250:final class CinematicTimelineCameraFocusBinding
packages/map_core/lib/src/authoring/cinematic_authoring_operations.dart:1290:CinematicTimelineBasicBlockStepResult addCinematicTimelineCameraFocusStep
```

V1-132 confirme par recherche locale :

```text
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart:cinematic-builder-camera-mode-focus
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart:cinematic-builder-camera-target-sceneCenter
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart:cinematic-builder-camera-target-actor
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart:cinematic-builder-camera-target-stagePoint
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart:cinematic-builder-camera-zoom-medium
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart:Cadrage configuré, preview réelle à venir.
```

## Fichiers crees

- `reports/narrativeStudio/scenes/ns_scenes_v1_133_cinematic_camera_geometry_playback_state_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_133_evidence_pack.md`

## Fichiers modifies

- `packages/map_core/lib/src/read_models/cinematic_preview_playback_plan.dart`
- `packages/map_core/test/cinematic_preview_playback_plan_test.dart`
- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`

## Fichiers supprimes

```text
<aucun>
```

## Sections modifiees — read model

### Diagnostics playback camera

```dart
enum CinematicPreviewPlaybackDiagnosticCode {
  cinematicPreviewPlaybackUnsupportedStep,
  cinematicPreviewPlaybackActorMissing,
  cinematicPreviewPlaybackActorInitialPoseMissing,
  cinematicPreviewPlaybackMoveDestinationMissing,
  cinematicPreviewPlaybackManualPathMissing,
  cinematicPreviewPlaybackManualPathPointMissing,
  cinematicPreviewPlaybackManualPathZeroLength,
  cinematicPreviewPlaybackZeroDurationStep,
  cinematicPreviewPlaybackTimelineEmpty,
  cinematicPreviewPlaybackStageContextMissing,
  cinematicPreviewPlaybackMapUnavailable,
  cinematicPreviewPlaybackCameraUnsupported,
  cinematicPreviewPlaybackCameraTargetMissing,
  cinematicPreviewPlaybackCameraTargetKindUnsupported,
  cinematicPreviewPlaybackCameraTargetActorMissing,
  cinematicPreviewPlaybackCameraTargetActorUnknown,
  cinematicPreviewPlaybackCameraTargetActorWithoutPosition,
  cinematicPreviewPlaybackCameraTargetStagePointMissing,
  cinematicPreviewPlaybackCameraTargetStagePointUnknown,
  cinematicPreviewPlaybackCameraTargetStagePointOutOfMap,
  cinematicPreviewPlaybackCameraTargetStageMapMissing,
  cinematicPreviewPlaybackCameraZoomPresetMissing,
  cinematicPreviewPlaybackCameraZoomPresetUnsupported,
  cinematicPreviewPlaybackFadeUnsupported,
  cinematicPreviewPlaybackEmoteActorMissing,
  cinematicPreviewPlaybackEmoteActorUnknown,
  cinematicPreviewPlaybackEmoteMissing,
  cinematicPreviewPlaybackEmoteUnknown,
}
```

### Stage bounds read model

```dart
@immutable
final class CinematicPreviewPlaybackStageBounds {
  const CinematicPreviewPlaybackStageBounds({
    required this.width,
    required this.height,
  })  : assert(width > 0),
        assert(height > 0);

  final double width;
  final double height;

  double get centerX => width / 2;
  double get centerY => height / 2;

  bool containsPoint(double x, double y) {
    return x >= 0 && x < width && y >= 0 && y < height;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CinematicPreviewPlaybackStageBounds &&
          other.width == width &&
          other.height == height;

  @override
  int get hashCode => Object.hash(width, height);
}
```

### Camera geometry model

```dart
@immutable
final class CinematicCameraPlaybackGeometry {
  CinematicCameraPlaybackGeometry.available({
    required this.targetKind,
    required this.targetLabel,
    this.actorId,
    this.stagePointId,
    required this.centerX,
    required this.centerY,
    required this.zoomPreset,
    List<CinematicPreviewPlaybackDiagnostic> diagnostics = const [],
  })  : isAvailable = true,
        diagnostics =
            List<CinematicPreviewPlaybackDiagnostic>.unmodifiable(diagnostics);

  CinematicCameraPlaybackGeometry.unavailable({
    this.targetKind,
    this.targetLabel,
    this.actorId,
    this.stagePointId,
    this.zoomPreset,
    List<CinematicPreviewPlaybackDiagnostic> diagnostics = const [],
  })  : isAvailable = false,
        centerX = null,
        centerY = null,
        diagnostics =
            List<CinematicPreviewPlaybackDiagnostic>.unmodifiable(diagnostics);

  const CinematicCameraPlaybackGeometry.none()
      : isAvailable = false,
        targetKind = null,
        targetLabel = null,
        actorId = null,
        stagePointId = null,
        centerX = null,
        centerY = null,
        zoomPreset = null,
        diagnostics = const <CinematicPreviewPlaybackDiagnostic>[];

  final bool isAvailable;
  final CinematicCameraTargetKind? targetKind;
  final String? targetLabel;
  final String? actorId;
  final String? stagePointId;
  final double? centerX;
  final double? centerY;
  final CinematicCameraZoomPreset? zoomPreset;
  final List<CinematicPreviewPlaybackDiagnostic> diagnostics;
}
```

### Camera pose integration

```dart
final CinematicCameraPlaybackGeometry geometry;
```

```dart
cameraPose = _cameraPoseFor(
  item: item,
  mode: plan._cameraModes[item.stepId],
  focusBinding: plan._cameraFocusBindings[item.stepId],
  actorPosesById: posesByActorId,
  stagePointsById: plan._stagePointsById,
  stageBounds: plan._stageBounds,
  clampedTimeMs: clampedTimeMs,
);
```

### Focus geometry resolver

```dart
CinematicCameraPlaybackGeometry _cameraGeometryFor({
  required CinematicPreviewPlaybackTimelineItem item,
  required CinematicTimelineCameraMode? mode,
  required CinematicTimelineCameraFocusBinding? focusBinding,
  required Map<String, CinematicActorPlaybackPose> actorPosesById,
  required Map<String, CinematicStagePoint> stagePointsById,
  required CinematicPreviewPlaybackStageBounds? stageBounds,
}) {
  if (mode != CinematicTimelineCameraMode.focus) {
    return const CinematicCameraPlaybackGeometry.none();
  }
  final staticDiagnostics = _cameraGeometryDiagnostics(item.diagnostics);
  if (focusBinding == null) {
    return CinematicCameraPlaybackGeometry.unavailable(
      diagnostics: staticDiagnostics,
    );
  }
  final target = focusBinding.target;
  final zoomPreset = focusBinding.zoomPreset;
  switch (target.kind) {
    case CinematicCameraTargetKind.sceneCenter:
      if (stageBounds == null) {
        return CinematicCameraPlaybackGeometry.unavailable(
          targetKind: CinematicCameraTargetKind.sceneCenter,
          targetLabel: _cameraTargetLabel(target),
          zoomPreset: zoomPreset,
          diagnostics: [
            ...staticDiagnostics,
            _cameraTargetStageMapMissingDiagnostic(item.stepId),
          ],
        );
      }
      return CinematicCameraPlaybackGeometry.available(
        targetKind: CinematicCameraTargetKind.sceneCenter,
        targetLabel: _cameraTargetLabel(target),
        centerX: stageBounds.centerX,
        centerY: stageBounds.centerY,
        zoomPreset: zoomPreset,
        diagnostics: staticDiagnostics,
      );
    case CinematicCameraTargetKind.actor:
      final actorId = target.actorId;
      if (actorId == null || actorId.isEmpty) {
        return CinematicCameraPlaybackGeometry.unavailable(
          targetKind: CinematicCameraTargetKind.actor,
          targetLabel: _cameraTargetLabel(target),
          zoomPreset: zoomPreset,
          diagnostics: [
            ...staticDiagnostics,
            _cameraTargetActorMissingDiagnostic(item.stepId),
          ],
        );
      }
      final pose = actorPosesById[actorId];
      if (pose == null) {
        return CinematicCameraPlaybackGeometry.unavailable(
          targetKind: CinematicCameraTargetKind.actor,
          actorId: actorId,
          targetLabel: _cameraTargetLabel(target),
          zoomPreset: zoomPreset,
          diagnostics: [
            ...staticDiagnostics,
            _cameraTargetActorUnknownDiagnostic(item.stepId, actorId),
          ],
        );
      }
      if (!pose.hasPosition) {
        return CinematicCameraPlaybackGeometry.unavailable(
          targetKind: CinematicCameraTargetKind.actor,
          actorId: actorId,
          targetLabel: pose.actorLabel ?? _cameraTargetLabel(target),
          zoomPreset: zoomPreset,
          diagnostics: [
            ...staticDiagnostics,
            _cameraTargetActorWithoutPositionDiagnostic(item.stepId, actorId),
          ],
        );
      }
      return CinematicCameraPlaybackGeometry.available(
        targetKind: CinematicCameraTargetKind.actor,
        actorId: actorId,
        targetLabel: pose.actorLabel ?? _cameraTargetLabel(target),
        centerX: pose.x!,
        centerY: pose.y!,
        zoomPreset: zoomPreset,
        diagnostics: staticDiagnostics,
      );
    case CinematicCameraTargetKind.stagePoint:
      final stagePointId = target.stagePointId;
      if (stagePointId == null || stagePointId.isEmpty) {
        return CinematicCameraPlaybackGeometry.unavailable(
          targetKind: CinematicCameraTargetKind.stagePoint,
          targetLabel: _cameraTargetLabel(target),
          zoomPreset: zoomPreset,
          diagnostics: [
            ...staticDiagnostics,
            _cameraTargetStagePointMissingDiagnostic(item.stepId),
          ],
        );
      }
      final point = stagePointsById[stagePointId];
      if (point == null) {
        return CinematicCameraPlaybackGeometry.unavailable(
          targetKind: CinematicCameraTargetKind.stagePoint,
          stagePointId: stagePointId,
          targetLabel: _cameraTargetLabel(target),
          zoomPreset: zoomPreset,
          diagnostics: [
            ...staticDiagnostics,
            _cameraTargetStagePointUnknownDiagnostic(
              item.stepId,
              stagePointId,
            ),
          ],
        );
      }
      if (stageBounds != null && !stageBounds.containsPoint(point.x, point.y)) {
        return CinematicCameraPlaybackGeometry.unavailable(
          targetKind: CinematicCameraTargetKind.stagePoint,
          stagePointId: stagePointId,
          targetLabel: point.label,
          zoomPreset: zoomPreset,
          diagnostics: [
            ...staticDiagnostics,
            _cameraTargetStagePointOutOfMapDiagnostic(
              item.stepId,
              stagePointId,
            ),
          ],
        );
      }
      return CinematicCameraPlaybackGeometry.available(
        targetKind: CinematicCameraTargetKind.stagePoint,
        stagePointId: stagePointId,
        targetLabel: point.label,
        centerX: point.x,
        centerY: point.y,
        zoomPreset: zoomPreset,
        diagnostics: staticDiagnostics,
      );
  }
}
```

## Tests ajoutes

Tests V1-133 ajoutes dans `packages/map_core/test/cinematic_preview_playback_plan_test.dart` :

- `V1-133 camera focus scene center exposes geometry when stage bounds are available`
- `V1-133 camera focus scene center reports unavailable geometry when bounds are missing`
- `V1-133 camera focus actor resolves geometry from active actor pose`
- `V1-133 camera focus actor consumes actorMove playback pose`
- `V1-133 camera focus actor reports missing pose for unavailable actor position`
- `V1-133 camera focus stage point resolves geometry from stage point`
- `V1-133 camera focus stage point reports unknown stage point`
- `V1-133 camera focus stage point reports out of map when bounds are available`
- `V1-133 reset and hold do not expose target geometry`
- `V1-133 invalid camera metadata remains diagnostic and non-crashing`

Helper ajoute :

```dart
CinematicTimelineStep _cameraFocusStep({
  required String id,
  required CinematicCameraTargetBinding target,
  required CinematicCameraZoomPreset zoomPreset,
  int durationMs = 500,
}) {
  final metadata = <String, String>{
    cinematicTimelineCameraModeMetadataKey:
        CinematicTimelineCameraMode.focus.name,
    cinematicTimelineCameraTargetKindMetadataKey: target.kind.name,
    cinematicTimelineCameraZoomPresetMetadataKey: zoomPreset.name,
    if (target.actorId != null)
      cinematicTimelineCameraTargetActorIdMetadataKey: target.actorId!,
    if (target.stagePointId != null)
      cinematicTimelineCameraTargetStagePointIdMetadataKey:
          target.stagePointId!,
  };
  return CinematicTimelineStep(
    id: id,
    kind: CinematicTimelineStepKind.camera,
    durationMs: durationMs,
    metadata: metadata,
  );
}
```

## Tests RED

```bash
cd packages/map_core
dart test --reporter=compact test/cinematic_preview_playback_plan_test.dart --name "V1-133"
```

Lignes exactes determinantes de l'echec initial :

```text
Failed to load "test/cinematic_preview_playback_plan_test.dart":
test/cinematic_preview_playback_plan_test.dart:476:28: Error: Couldn't find constructor 'CinematicPreviewPlaybackStageBounds'.
test/cinematic_preview_playback_plan_test.dart:476:9: Error: No named parameter with the name 'stageBounds'.
test/cinematic_preview_playback_plan_test.dart:528:16: Error: Member not found: 'cinematicPreviewPlaybackCameraTargetStageMapMissing'.
test/cinematic_preview_playback_plan_test.dart:522:31: Error: The getter 'geometry' isn't defined for the type 'CinematicCameraPlaybackPose'.
test/cinematic_preview_playback_plan_test.dart:579:48: Error: The method 'copyWith' isn't defined for the type 'CinematicAsset'.
```

Note test : `copyWith` etait une erreur de fixture de test, corrigee avant implementation produit.

## Tests GREEN

```bash
cd packages/map_core
dart test --reporter=compact test/cinematic_preview_playback_plan_test.dart --name "V1-133"
```

```text
00:00 +10: All tests passed!
```

```bash
cd packages/map_core
dart test --reporter=compact test/cinematic_preview_playback_plan_test.dart --name "V1-131"
```

```text
00:00 +1: All tests passed!
```

```bash
cd packages/map_core
dart test --reporter=compact test/cinematic_preview_playback_plan_test.dart --name "V1-124"
```

```text
No tests ran.
No tests match regular expression "V1-124".
```

Le filtre V1-124 concerne `map_editor`; la regression UI consommatrice a ete lancee separement.

```bash
cd packages/map_core
dart test --reporter=compact test/cinematic_authoring_operations_test.dart test/cinematic_diagnostics_test.dart test/cinematic_asset_test.dart test/cinematic_preview_playback_plan_test.dart
```

Ligne de resultat :

```text
00:00 +185: All tests passed!
```

```bash
cd packages/map_core
dart analyze lib/src/read_models/cinematic_preview_playback_plan.dart test/cinematic_preview_playback_plan_test.dart
```

```text
Analyzing cinematic_preview_playback_plan.dart, cinematic_preview_playback_plan_test.dart...
No issues found!
```

```bash
cd packages/map_editor
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --name "V1-124"
```

Lignes de resultat :

```text
Got dependencies!
31 packages have newer versions incompatible with dependency constraints.
Try `flutter pub outdated` for more information.
00:04 +7: All tests passed!
```

## Roadmaps

`road_map_scenes.md` :

```text
| NS-SCENES-V1-133 — Cinematic Camera Geometry Playback State V0 | DONE | Etat de geometrie camera derive ajoute cote read model playback : target sceneCenter/actor/stagePoint resolue, centre scene/tile expose quand disponible, zoom preset conserve comme intention symbolique, diagnostics honnetes, sans renderer UI, runtime, Flame, GameState, screenshot ni mutation viewport. |
| NS-SCENES-V1-134 — Cinematic Camera Geometry Preview UI V0 | RECOMMANDÉ | Brancher l'etat geometrique V1-133 dans la preview editor-only : cadre/cible/cadrage visuel base sur la geometrie derivee, sans runtime, Flame, GameState ni mutation viewport editor. |
```

`road_map_scene_builder_authoring.md` :

```text
NS-SCENES-V1-134 — Cinematic Camera Geometry Preview UI V0
```

## Non-objectifs verifies

Non presents dans le diff produit :

- `package:flame`
- `GameState`
- `PlayableMapGame`
- `CameraComponent`
- `map_runtime`
- `map_gameplay`
- `map_battle`
- `CinematicBackdropPreviewFramingState`

## Checks finaux

```bash
git diff --check
```

```text
<vide>
```

```bash
git diff --stat
```

```text
 .../cinematic_preview_playback_plan.dart           | 540 ++++++++++++++++++++-
 .../test/cinematic_preview_playback_plan_test.dart | 430 +++++++++++++++-
 .../scenes/road_map_scene_builder_authoring.md     |  65 ++-
 reports/narrativeStudio/scenes/road_map_scenes.md  |  66 ++-
 4 files changed, 1030 insertions(+), 71 deletions(-)
```

```bash
git diff --name-only
```

```text
packages/map_core/lib/src/read_models/cinematic_preview_playback_plan.dart
packages/map_core/test/cinematic_preview_playback_plan_test.dart
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md
```

```bash
git status --short --untracked-files=all
```

```text
 M packages/map_core/lib/src/read_models/cinematic_preview_playback_plan.dart
 M packages/map_core/test/cinematic_preview_playback_plan_test.dart
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_133_cinematic_camera_geometry_playback_state_v0.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_133_evidence_pack.md
```

```bash
git diff --name-only -- packages/map_editor packages/map_runtime packages/map_gameplay packages/map_battle examples/playable_runtime_host assets selbrume pubspec.yaml
```

```text
<vide>
```

```bash
find reports/narrativeStudio/scenes/screenshots -maxdepth 1 -name '*v1_133*' -print
find reports/narrativeStudio/scenes/screenshots -maxdepth 1 -name '*v1_134*' -print
```

```text
<vide>
<vide>
```

## Auto-review independante

- Camera ne rend rien visuellement : OK.
- Viewport editor non modifie : OK.
- Coordonnees en espace scene/tile, pas pixels ecran : OK.
- Target actor consomme `actorPosesById` deja calcule : OK.
- Target stagePoint consomme `stageContext.stagePoints` : OK.
- `sceneCenter` sans bounds produit un diagnostic, pas de fallback `0,0` : OK.
- Zoom reste un preset symbolique : OK.
- `focus` garde `isSupported == false` pour ne pas faire mentir l'UI : OK.
- Runtime/Flame/GameState/Selbrume non touches : OK.
- Aucune Visual Gate V1-133/V1-134 creee : OK.

## Critique du prompt

Le prompt demande un test "camera focus actor follows actorMove playback pose over time". Le time layout actuel est lineaire : un bloc camera ne peut pas chevaucher un bloc `actorMove`. L'adaptation retenue teste que la camera consomme la pose acteur deja calculee apres un `actorMove`, ce qui respecte l'architecture actuelle sans creer une timeline parallele.

Le prompt mentionne `cameraGeometryUnavailable`. Le read model playback possedait deja `cinematicPreviewPlaybackCameraUnsupported` pour le statut visuel camera ; V1-133 ajoute des diagnostics cibles/zoom plus precis et conserve ce statut visuel pour eviter de presenter une vraie preview.

## Addendum UX post-lot demande par Karim

Karim a explicitement demande, apres V1-133, trois ajustements ergonomiques dans l'inspecteur du Cinematic Builder :

- compacter les controles camera/duree sous forme de dropdowns ;
- retirer du flux principal les informations techniques restantes du bloc selectionne, ou les ranger dans un accordéon bas de panneau.
- remplacer les grilles de boutons du deplacement acteur par des dropdowns pour clarifier le profil de destination logique et le repere d'arrivee.

Interpretation retenue :

- les controles utiles restent visibles ;
- les details read-only sont conserves dans un accordéon `Details techniques` ferme par defaut ;
- les libelles `Parametres V0`, `Bloc`, `Duree / Edition en millisecondes` et la guidance de bornes sont masques pour les blocs basiques ;
- aucun modele core, aucune geometrie camera, aucune preview reelle et aucun runtime ne sont ajoutes.

Fichiers modifies par cet addendum UX :

```text
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
packages/map_editor/test/cinematic_builder_workspace_test.dart
reports/narrativeStudio/scenes/ns_scenes_v1_133_cinematic_camera_geometry_playback_state_v0.md
reports/narrativeStudio/scenes/ns_scenes_v1_133_evidence_pack.md
```

Zones code modifiees :

```text
_DurationPresetControls
_DurationEditorControls
_BasicBlockControls
_CameraModeControls
_ActorMoveControls
_MovementTargetPicker
_SelectedStepTechnicalDetailsAccordion
_SelectedStepTechnicalDetails
```

RED ActorMove avant implementation dropdown :

```bash
cd packages/map_editor
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --name "binds actor movement destination|V1-117-bis changing one actorMove destination|adds edits and removes actor movement authoring block"
```

Sortie utile :

```text
Expected: exactly one matching candidate
  Actual: _TextWidgetFinder:<Found 0 widgets with text "Point final du déplacement": []>
Bad state: No element
00:05 +0 -3: Some tests failed.
```

GREEN ActorMove apres implementation dropdown :

```bash
cd packages/map_editor
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --name "binds actor movement destination|V1-117-bis changing one actorMove destination|adds edits and removes actor movement authoring block"
```

Sortie utile :

```text
00:06 +3: All tests passed!
```

Regression finale combinee apres correction de l'info `prefer_null_aware_operators` :

```bash
cd packages/map_editor
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --name "V1-132|renders a derived time axis with proportional bars|shows hover details without selecting or moving cursor|selects a step locally and updates read-only inspector|shows lane grouping V0 without enabling actor movement|adds and edits wait fade and camera basic blocks|binds actor movement destination|V1-117-bis changing one actorMove destination|adds edits and removes actor movement authoring block"
```

Sortie utile :

```text
00:07 +19: All tests passed!
```

Tests / regressions lances :

```bash
cd packages/map_editor
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --name "V1-132|renders a derived time axis with proportional bars|shows hover details without selecting or moving cursor|selects a step locally and updates read-only inspector|shows lane grouping V0 without enabling actor movement|adds and edits wait fade and camera basic blocks"
```

Sortie utile :

```text
00:08 +16: All tests passed!
```

Analyse ciblee relancee apres polish :

```bash
cd packages/map_editor
flutter analyze --no-fatal-infos lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart test/cinematic_builder_workspace_test.dart
```

Sortie utile :

```text
Analyzing 2 items...
35 issues found. (ran in 1.5s)
```

Interpretation : commande en exit code `0`, uniquement des infos `prefer_const_*` non fatales deja presentes dans ces fichiers volumineux ; aucun nouvel error/warning bloquant.

Note de scope :

Cet addendum est volontairement attribue a une demande de Karim et ne transforme pas V1-133 en lot UI renderer. Il documente seulement le polish editor-only effectue dans la foulee.
