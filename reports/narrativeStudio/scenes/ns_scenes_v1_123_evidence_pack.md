# NS-SCENES-V1-123 — Evidence Pack

## Gate 0 complet

Commande :

```bash
pwd
```

Sortie :

```text
/Users/karim/Project/pokemonProject
```

Commande :

```bash
git branch --show-current
```

Sortie :

```text
main
```

Commande :

```bash
git log --oneline -n 10
```

Sortie :

```text
636613af NS-SCENES-V1-122 — Cinematic Camera Preview Playback Prep Contract
d6081a24 NS-SCENES-V1-121 — Cinematic Fade Preview Playback V0
035e3346 ns_scenes_v1_120: add cinematic preview playback scrub seek UI and evidence pack
e87152f2 docs(narrativeStudio): add cinematic preview playback scrub seek prep contract and evidence pack
1706e6d3 feat(narrativeStudio): add cinematic playback preview fallback diagnostics and polish
c1692b7d feat(narrativeStudio): integrate cinematic actor walking animation renderer and fix actor move destination isolation
f99e235c feat: cinematic actor walking animation frame resolver v1.115
0ed41a86 docs: mise à jour rapports et roadmaps v1.114
a6b197c0 docs: préparation contrat animation marche acteur cinematic v1.114
2dff3a1e feat: cinematic actor playback smooth motion v1.113
```

Etat dirty initial : aucun changement suivi ou non suivi observe avant implementation. Aucun `selbrume/project.json` dirty au debut du lot.

## Regles lues

- `AGENTS.md`
- `agent_rules.md`
- `codex_rule.md`
- `skills/README.md`
- `skills/using-superpowers/SKILL.md`
- `skills/test-driven-development/SKILL.md`
- `skills/verification-before-completion/SKILL.md`
- `skills/writing-plans/SKILL.md`

Fichier demande mais absent :

```text
codex_rules.md
```

Sortie :

```text
sed: codex_rules.md: No such file or directory
```

## Passes sub-agent

Sub-agent Audit / Architecture : PASS. Le modele Camera existant est partiellement suffisant pour V0 : `reset`/`hold` + duree suffisent a un etat actif/progress, mais pas a un cadrage visuel riche.

Sub-agent Implementation : PASS. Changement localise dans `cinematic_preview_playback_plan.dart`, sans nouveau fichier core.

Sub-agent Tests : PASS. Tests RED ajoutes puis GREEN, avec cas positif, negatif, boundary, non-mutation et non-regression fade.

Sub-agent Build / Validation : PASS. `dart analyze`, suite `map_core`, tests cibles et regressions Builder passent.

Sub-agent Critique finale : PASS avec limites. Le modele ne promet pas centre/zoom et garde V1-124 non demarre.

## Fichiers modifies

- `packages/map_core/lib/src/read_models/cinematic_preview_playback_plan.dart`
- `packages/map_core/test/cinematic_preview_playback_plan_test.dart`
- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`

## Fichiers crees

- `reports/narrativeStudio/scenes/ns_scenes_v1_123_cinematic_camera_playback_state_read_model_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_123_evidence_pack.md`

Aucun fichier de modele dedie cree.

## Hunks pertinents

`CinematicCameraPlaybackPose` :

```diff
+  final bool isActive;
+  final bool isSupported;
+  final String? activeStepId;
+  final CinematicTimelineCameraMode? mode;
+  final double progress;
+  final List<CinematicPreviewPlaybackDiagnostic> diagnostics;
+
+  bool get supported => isSupported;
```

`frameAt(timeMs)` :

```diff
+  var cameraPose = const CinematicCameraPlaybackPose.inactive();
...
+          cameraPose = _cameraPoseFor(
+            item: item,
+            mode: plan._cameraModes[item.stepId],
+            clampedTimeMs: clampedTimeMs,
+          );
```

Progress :

```diff
+double _timelineItemProgress(
+  CinematicPreviewPlaybackTimelineItem item,
+  int clampedTimeMs,
+)
```

Modes camera :

```diff
+CinematicTimelineCameraMode? _cameraModeOf(CinematicTimelineStep step) {
+  return switch (step.metadata[cinematicTimelineCameraModeMetadataKey]) {
+    'reset' => CinematicTimelineCameraMode.reset,
+    'hold' => CinematicTimelineCameraMode.hold,
+    _ => null,
+  };
+}
```

## Code genere complet

### Modele et helpers camera

Fichier : `packages/map_core/lib/src/read_models/cinematic_preview_playback_plan.dart`

```dart
@immutable
final class CinematicCameraPlaybackPose {
  CinematicCameraPlaybackPose({
    required this.isActive,
    required this.isSupported,
    required this.progress,
    this.activeStepId,
    this.mode,
    List<CinematicPreviewPlaybackDiagnostic> diagnostics = const [],
  }) : diagnostics =
            List<CinematicPreviewPlaybackDiagnostic>.unmodifiable(diagnostics);

  const CinematicCameraPlaybackPose.inactive()
      : isActive = false,
        isSupported = false,
        progress = 0,
        activeStepId = null,
        mode = null,
        diagnostics = const <CinematicPreviewPlaybackDiagnostic>[];

  final bool isActive;
  final bool isSupported;
  final String? activeStepId;
  final CinematicTimelineCameraMode? mode;
  final double progress;
  final List<CinematicPreviewPlaybackDiagnostic> diagnostics;

  bool get supported => isSupported;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CinematicCameraPlaybackPose &&
          other.isActive == isActive &&
          other.isSupported == isSupported &&
          other.activeStepId == activeStepId &&
          other.mode == mode &&
          other.progress == progress &&
          _listEquals(other.diagnostics, diagnostics);

  @override
  int get hashCode => Object.hash(
        isActive,
        isSupported,
        activeStepId,
        mode,
        progress,
        Object.hashAll(diagnostics),
      );
}

CinematicCameraPlaybackPose _cameraPoseFor({
  required CinematicPreviewPlaybackTimelineItem item,
  required CinematicTimelineCameraMode? mode,
  required int clampedTimeMs,
}) {
  // This is preview/read-model state only: V1-123 intentionally describes the
  // cinematic camera timeline without mutating editor viewport pan or zoom.
  return CinematicCameraPlaybackPose(
    isActive: true,
    isSupported: mode != null,
    activeStepId: item.stepId,
    mode: mode,
    progress: _timelineItemProgress(item, clampedTimeMs),
    diagnostics: item.diagnostics,
  );
}

double _timelineItemProgress(
  CinematicPreviewPlaybackTimelineItem item,
  int clampedTimeMs,
) {
  if (item.visualDurationMs <= 0) {
    return 0;
  }
  return ((clampedTimeMs - item.startMs) / item.visualDurationMs)
      .clamp(0.0, 1.0)
      .toDouble();
}

CinematicTimelineCameraMode? _cameraModeOf(CinematicTimelineStep step) {
  // V1-123 only supports the camera modes already persisted by authoring.
  // Unknown values stay unsupported so a future UI can explain them honestly.
  return switch (step.metadata[cinematicTimelineCameraModeMetadataKey]) {
    'reset' => CinematicTimelineCameraMode.reset,
    'hold' => CinematicTimelineCameraMode.hold,
    _ => null,
  };
}

CinematicPreviewPlaybackDiagnostic _cameraUnsupportedDiagnostic(
  CinematicTimelineStep step,
) {
  final hasMode =
      step.metadata.containsKey(cinematicTimelineCameraModeMetadataKey);
  return CinematicPreviewPlaybackDiagnostic(
    code: CinematicPreviewPlaybackDiagnosticCode
        .cinematicPreviewPlaybackCameraUnsupported,
    severity: CinematicPreviewPlaybackDiagnosticSeverity.warning,
    message: hasMode
        ? 'Caméra non prévisualisée dans cette version.'
        : 'Cadrage caméra incomplet.',
    stepId: step.id,
  );
}
```

### Exposition dans la frame playback

Fichier : `packages/map_core/lib/src/read_models/cinematic_preview_playback_plan.dart`

```dart
final class CinematicPreviewPlaybackFrame {
  CinematicPreviewPlaybackFrame({
    required this.timeMs,
    required this.clampedTimeMs,
    required List<String> activeStepIds,
    required List<CinematicActorPlaybackPose> actorPoses,
    this.fadeState,
    CinematicCameraPlaybackPose? cameraPose,
    required List<CinematicPreviewPlaybackDiagnostic> visibleDiagnostics,
  })  : activeStepIds = List<String>.unmodifiable(activeStepIds),
        actorPoses = List<CinematicActorPlaybackPose>.unmodifiable(actorPoses),
        cameraPose =
            cameraPose ?? const CinematicCameraPlaybackPose.inactive(),
        visibleDiagnostics =
            List<CinematicPreviewPlaybackDiagnostic>.unmodifiable(
          visibleDiagnostics,
        );

  final int timeMs;
  final int clampedTimeMs;
  final List<String> activeStepIds;
  final List<CinematicActorPlaybackPose> actorPoses;
  final CinematicFadePlaybackState? fadeState;
  final CinematicCameraPlaybackPose cameraPose;
  final List<CinematicPreviewPlaybackDiagnostic> visibleDiagnostics;
}
```

### Tests V1-123 ajoutes

Fichier : `packages/map_core/test/cinematic_preview_playback_plan_test.dart`

```dart
test('V1-123 camera block produces active playback state', () {
  final plan = buildCinematicPreviewPlaybackPlan(
    cinematic: CinematicAsset(
      id: 'cinematic_camera',
      title: 'Camera cinematic',
      timeline: CinematicTimeline(
        steps: [
          CinematicTimelineStep(
            id: 'camera_reset',
            kind: CinematicTimelineStepKind.camera,
            durationMs: 1000,
            metadata: const {
              cinematicTimelineCameraModeMetadataKey: 'reset',
            },
          ),
        ],
      ),
    ),
  );

  final frame = plan.frameAt(500);

  expect(frame.cameraPose.isActive, isTrue);
  expect(frame.cameraPose.activeStepId, 'camera_reset');
  expect(frame.cameraPose.isSupported, isTrue);
  expect(frame.cameraPose.supported, isTrue);
  expect(frame.cameraPose.mode, CinematicTimelineCameraMode.reset);
  expect(frame.cameraPose.progress, closeTo(0.5, 0.001));
  expect(frame.cameraPose.diagnostics, isEmpty);
  expect(plan.capabilities.supportsCamera, isTrue);
  expect(plan.capabilities.hasUnsupportedSteps, isFalse);
});

test('V1-123 camera playback state exposes clamped progress', () {
  final plan = buildCinematicPreviewPlaybackPlan(
    cinematic: CinematicAsset(
      id: 'cinematic_camera_progress',
      title: 'Camera progress cinematic',
      timeline: CinematicTimeline(
        steps: [
          CinematicTimelineStep(
            id: 'wait',
            kind: CinematicTimelineStepKind.wait,
            durationMs: 200,
          ),
          CinematicTimelineStep(
            id: 'camera_hold',
            kind: CinematicTimelineStepKind.camera,
            durationMs: 1000,
            metadata: const {
              cinematicTimelineCameraModeMetadataKey: 'hold',
            },
          ),
        ],
      ),
    ),
  );

  expect(plan.frameAt(-50).cameraPose.isActive, isFalse);
  expect(plan.frameAt(199).cameraPose.isActive, isFalse);
  expect(plan.frameAt(200).cameraPose.progress, 0);
  expect(plan.frameAt(700).cameraPose.progress, closeTo(0.5, 0.001));
  expect(plan.frameAt(1199).cameraPose.progress, closeTo(0.999, 0.001));
  expect(plan.frameAt(1200).cameraPose.isActive, isFalse);
  expect(plan.frameAt(2000).cameraPose.isActive, isFalse);
});

test('V1-123 unsupported camera mode produces diagnostic without crashing',
    () {
  final plan = buildCinematicPreviewPlaybackPlan(
    cinematic: CinematicAsset(
      id: 'cinematic_camera_unknown',
      title: 'Camera unknown cinematic',
      timeline: CinematicTimeline(
        steps: [
          CinematicTimelineStep(
            id: 'camera_orbit',
            kind: CinematicTimelineStepKind.camera,
            durationMs: 500,
            metadata: const {
              cinematicTimelineCameraModeMetadataKey: 'orbit',
            },
          ),
        ],
      ),
    ),
  );

  final frame = plan.frameAt(250);

  expect(frame.cameraPose.isActive, isTrue);
  expect(frame.cameraPose.activeStepId, 'camera_orbit');
  expect(frame.cameraPose.isSupported, isFalse);
  expect(frame.cameraPose.mode, isNull);
  expect(frame.cameraPose.progress, closeTo(0.5, 0.001));
  expect(
    frame.cameraPose.diagnostics.map((diagnostic) => diagnostic.code),
    contains(
      CinematicPreviewPlaybackDiagnosticCode
          .cinematicPreviewPlaybackCameraUnsupported,
    ),
  );
  expect(plan.capabilities.supportsCamera, isTrue);
  expect(plan.capabilities.hasUnsupportedSteps, isTrue);
});

test('V1-123 missing camera mode stays diagnosed and does not mutate asset',
    () {
  final cinematic = CinematicAsset(
    id: 'cinematic_camera_missing_mode',
    title: 'Camera missing mode cinematic',
    timeline: CinematicTimeline(
      steps: [
        CinematicTimelineStep(
          id: 'camera_missing_mode',
          kind: CinematicTimelineStepKind.camera,
          durationMs: 500,
        ),
      ],
    ),
  );
  final before = cinematic.toJson();

  final plan = buildCinematicPreviewPlaybackPlan(cinematic: cinematic);
  final frame = plan.frameAt(250);

  expect(frame.cameraPose.isActive, isTrue);
  expect(frame.cameraPose.isSupported, isFalse);
  expect(frame.cameraPose.activeStepId, 'camera_missing_mode');
  expect(frame.cameraPose.progress, closeTo(0.5, 0.001));
  expect(
    frame.cameraPose.diagnostics.single.message,
    'Cadrage caméra incomplet.',
  );
  expect(cinematic.toJson(), before);
});

test('V1-123 consecutive camera steps choose deterministic active state',
    () {
  final plan = buildCinematicPreviewPlaybackPlan(
    cinematic: CinematicAsset(
      id: 'cinematic_camera_consecutive',
      title: 'Camera consecutive cinematic',
      timeline: CinematicTimeline(
        steps: [
          CinematicTimelineStep(
            id: 'camera_reset',
            kind: CinematicTimelineStepKind.camera,
            durationMs: 400,
            metadata: const {
              cinematicTimelineCameraModeMetadataKey: 'reset',
            },
          ),
          CinematicTimelineStep(
            id: 'camera_hold',
            kind: CinematicTimelineStepKind.camera,
            durationMs: 600,
            metadata: const {
              cinematicTimelineCameraModeMetadataKey: 'hold',
            },
          ),
        ],
      ),
    ),
  );

  final beforeBoundary = plan.frameAt(399).cameraPose;
  final atBoundary = plan.frameAt(400).cameraPose;
  final nearEnd = plan.frameAt(999).cameraPose;
  final afterEnd = plan.frameAt(1000).cameraPose;

  expect(beforeBoundary.activeStepId, 'camera_reset');
  expect(beforeBoundary.mode, CinematicTimelineCameraMode.reset);
  expect(beforeBoundary.progress, closeTo(0.9975, 0.001));
  expect(atBoundary.activeStepId, 'camera_hold');
  expect(atBoundary.mode, CinematicTimelineCameraMode.hold);
  expect(atBoundary.progress, 0);
  expect(nearEnd.activeStepId, 'camera_hold');
  expect(nearEnd.progress, closeTo(0.998, 0.001));
  expect(afterEnd.isActive, isFalse);
});
```

## Tests RED exacts

Tests ajoutes avant implementation :

```text
V1-123 camera block produces active playback state
V1-123 camera playback state exposes clamped progress
V1-123 unsupported camera mode produces diagnostic without crashing
```

Resultat RED : echec attendu. Les getters `isActive`, `isSupported`, `mode`, `progress` et `diagnostics` n'existaient pas encore sur `CinematicCameraPlaybackPose`, et `cameraPose` etait nullable.

## Tests GREEN exacts

Commande :

```bash
cd packages/map_core && dart test --reporter=compact test/cinematic_preview_playback_plan_test.dart
```

Sortie :

```text
00:00 +17: All tests passed!
```

Commande :

```bash
cd packages/map_core && dart test --reporter=compact test/cinematic_timeline_time_layout_read_model_test.dart
```

Sortie :

```text
00:00 +4: All tests passed!
```

Commande :

```bash
cd packages/map_core && dart test --reporter=compact test/cinematic_actor_display_preview_model_test.dart
```

Sortie :

```text
00:00 +27: All tests passed!
```

Commande :

```bash
cd packages/map_core && dart test --reporter=compact
```

Sortie :

```text
00:05 +2501: All tests passed!
```

## Analyse statique

Commande :

```bash
cd packages/map_core && dart analyze
```

Sortie :

```text
Analyzing map_core...
No issues found!
```

## Regressions map_editor ciblees

Commande :

```bash
cd packages/map_editor && flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --name "V1-121"
```

Sortie :

```text
00:03 +5: All tests passed!
```

Commande :

```bash
cd packages/map_editor && flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --name "V1-120"
```

Sortie :

```text
00:04 +9: All tests passed!
```

Note environnement : le premier lancement parallele de V1-121 a echoue avant tests avec :

```text
Failed to change install names in LocalFile: '/Users/karim/Project/pokemonProject/packages/map_editor/build/native_assets/macos/objective_c.dylib'
error: ... install_name_tool: can't open file ... objective_c.dylib (No such file or directory)
```

La relance sequentielle a passe.

## Build

Build non lance : aucun fichier editor/runtime n'a ete modifie. Validation alternative :

- `dart analyze` dans `packages/map_core` ;
- `dart test --reporter=compact` dans `packages/map_core` ;
- regressions Builder V1-120/V1-121.

## Checks anti-scope avant rapports

Commande :

```bash
git diff --unified=0 | rg -n "package:flutter|package:flame|GameState|PlayableMapGame|SceneRuntimeExecutor|CinematicRuntimeAdapter|map_runtime|map_gameplay|BuildContext|Widget|CameraComponent|Timer\.periodic|Future\.delayed|Stream\.periodic|DateTime\.now|V1-124" || true
```

Sortie :

```text
<vide>
```

Commande :

```bash
git diff --name-only -- packages/map_editor
```

Sortie :

```text
<vide>
```

Commande :

```bash
git diff --name-only -- packages/map_editor packages/map_runtime packages/map_gameplay packages/map_battle examples/playable_runtime_host assets selbrume
```

Sortie :

```text
<vide>
```

Commandes :

```bash
find reports/narrativeStudio/scenes/screenshots -maxdepth 1 -name '*v1_123*' -print
find reports/narrativeStudio/scenes/screenshots -maxdepth 1 -name '*v1_124*' -print
```

Sortie :

```text
<vide>
```

## Roadmaps

Roadmaps alignees :

- `road_map_scenes.md` ajoute V1-123 DONE et recommande V1-124.
- `road_map_scene_builder_authoring.md` ajoute V1-123 DONE et recommande V1-124.

V1-124 reste non demarre.

## Confirmations

- Aucun `packages/map_editor` modifie.
- Aucun `packages/map_runtime` modifie.
- Aucun `packages/map_gameplay` modifie.
- Aucun `packages/map_battle` modifie.
- Aucun `examples/playable_runtime_host` modifie.
- Aucun `assets` modifie.
- Aucun `selbrume` modifie.
- Aucun screenshot cree.
- Aucune Visual Gate creee.
- Aucun runtime, Flame ou GameState touche.

## Git final post-rapport

Commande :

```bash
git diff --check
```

Sortie :

```text
<vide>
```

Commande :

```bash
git diff --stat
```

Sortie :

```text
.../cinematic_preview_playback_plan.dart           | 145 ++++++++++++---
.../test/cinematic_preview_playback_plan_test.dart | 206 ++++++++++++++++++++-
.../scenes/road_map_scene_builder_authoring.md     |  41 ++--
reports/narrativeStudio/scenes/road_map_scenes.md  |  46 +++--
4 files changed, 372 insertions(+), 66 deletions(-)
```

Commande :

```bash
git diff --name-only
```

Sortie :

```text
packages/map_core/lib/src/read_models/cinematic_preview_playback_plan.dart
packages/map_core/test/cinematic_preview_playback_plan_test.dart
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md
```

Note : les rapports V1-123 sont non suivis, donc visibles dans `git status` et non dans `git diff --name-only`.

Commande :

```bash
git status --short --untracked-files=all
```

Sortie :

```text
 M packages/map_core/lib/src/read_models/cinematic_preview_playback_plan.dart
 M packages/map_core/test/cinematic_preview_playback_plan_test.dart
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_123_cinematic_camera_playback_state_read_model_v0.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_123_evidence_pack.md
```

## Anti-scope post-rapport

Commande :

```bash
git diff --unified=0 | rg -n "package:flutter|package:flame|GameState|PlayableMapGame|SceneRuntimeExecutor|CinematicRuntimeAdapter|map_runtime|map_gameplay|BuildContext|Widget|CameraComponent|Timer\.periodic|Future\.delayed|Stream\.periodic|DateTime\.now|V1-124" || true
```

Sortie utile :

```text
Occurrences uniquement documentaires dans les roadmaps : V1-124 recommande/non demarre et GameState cite dans les limites.
```

Commande :

```bash
git diff --name-only -- packages/map_editor
```

Sortie :

```text
<vide>
```

Commande :

```bash
git diff --name-only -- packages/map_editor packages/map_runtime packages/map_gameplay packages/map_battle examples/playable_runtime_host assets selbrume
```

Sortie :

```text
<vide>
```

Commandes :

```bash
find reports/narrativeStudio/scenes/screenshots -maxdepth 1 -name '*v1_123*' -print
find reports/narrativeStudio/scenes/screenshots -maxdepth 1 -name '*v1_124*' -print
```

Sortie :

```text
<vide>
```

## Verdict

```text
NS-SCENES-V1-123 : DONE.
Camera Playback State Read Model : implemente.
frameAt(timeMs) : expose camera state.
activeStepId / progress / supported / diagnostics : presents.
Editor Viewport : non mute.
UI camera : non demarree.
Runtime / Flame / GameState : non touches.
map_editor : non modifie.
Visual Gate / screenshot : absents.
V1-124 : Cinematic Camera Preview Playback UI V0 recommande, non demarre.
```
