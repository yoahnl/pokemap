# NS-SCENES-V1-123 — Cinematic Camera Playback State Read Model V0

## 1. Resume executif

V1-123 est DONE.

Le playback preview expose maintenant un vrai etat camera pur cote `map_core` via `CinematicPreviewPlaybackFrame.cameraPose`.

Le modele fournit :

- `isActive` ;
- `isSupported` ;
- `supported` en compatibilite avec l'ancien placeholder ;
- `activeStepId` ;
- `mode` ;
- `progress` clamp entre `0.0` et `1.0` ;
- `diagnostics`.

Le lot ne rend rien visuellement. Il ne modifie ni Cinematic Builder UI, ni viewport editor, ni runtime, ni Flame, ni GameState.

## 2. Gate 0

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

Etat initial avant implementation : branche `main`, working tree propre selon l'audit initial du lot. Aucun `selbrume/project.json` dirty n'a ete observe.

`codex_rules.md` a ete demande par le prompt mais est absent :

```text
sed: codex_rules.md: No such file or directory
```

## 3. Fichiers lus

Regles et skills :

- `AGENTS.md`
- `agent_rules.md`
- `codex_rule.md`
- `codex_rules.md` : absent
- `skills/README.md`
- `skills/using-superpowers/SKILL.md`
- `skills/test-driven-development/SKILL.md`
- `skills/verification-before-completion/SKILL.md`
- `skills/writing-plans/SKILL.md`

Rapports et roadmaps consultes :

- `reports/narrativeStudio/scenes/ns_scenes_v1_110_cinematic_preview_playback_plan_read_model_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_111_cinematic_preview_playback_transport_ui_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_120_cinematic_preview_playback_scrub_seek_ui_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_121_cinematic_fade_preview_playback_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_121_evidence_pack.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_122_cinematic_camera_preview_playback_prep_contract.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_122_evidence_pack.md`
- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`

Fichiers core/editor consultes :

- `packages/map_core/lib/src/read_models/cinematic_preview_playback_plan.dart`
- `packages/map_core/lib/src/read_models/cinematic_timeline_time_layout_read_model.dart`
- `packages/map_core/lib/src/read_models/cinematic_actor_display_preview_model.dart`
- `packages/map_core/lib/src/read_models/cinematic_map_backdrop_preview_model.dart`
- `packages/map_core/lib/src/models/cinematic_asset.dart`
- `packages/map_core/lib/src/authoring/cinematic_authoring_operations.dart`
- `packages/map_core/lib/map_core.dart`
- `packages/map_core/test/cinematic_preview_playback_plan_test.dart`
- `packages/map_core/test/cinematic_timeline_time_layout_read_model_test.dart`
- `packages/map_core/test/cinematic_actor_display_preview_model_test.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_viewport_transform.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_fade_preview_overlay.dart`

## 4. Rappel V1-122

V1-122 a retenu Option F : separer le read model de la future UI/renderer camera.

Regle conservee :

```text
Editor Viewport != Cinematic Camera != Runtime Camera
```

## 5. Audit du modele Camera existant

Verdict : modele partiellement suffisant, support V0 borne.

Constats :

- `CinematicTimelineStepKind.camera` existe.
- Les blocs Camera V0 portent deja `durationMs`.
- Les modes persistables viennent de `cinematicTimelineCameraModeMetadataKey`.
- Les modes existants sont `CinematicTimelineCameraMode.reset` et `CinematicTimelineCameraMode.hold`.
- Avant V1-123, `CinematicPreviewPlaybackFrame.cameraPose` etait un placeholder nullable avec seulement `supported` et `activeStepId`.
- Les cameras etaient systematiquement marquees unsupported, et `supportsCamera` valait `false`.
- Aucun champ fiable de centre, zoom, pan, target ou follow actor n'est expose aujourd'hui pour promettre un cadrage visuel.

## 6. Decision d'architecture

Le choix le plus petit et coherent est d'etendre `CinematicCameraPlaybackPose` dans le fichier read model existant, sans nouveau fichier.

Raisons :

- l'export public `map_core.dart` exporte deja `cinematic_preview_playback_plan.dart` ;
- `frameAt(timeMs)` est deja la source de verite du playback preview ;
- la timeline derivee existante fournit deja start/end/duree ;
- aucun modele runtime ou UI n'est necessaire.

## 7. Modele camera playback state

Zone modifiee : `CinematicCameraPlaybackPose`.

Hunk pertinent :

```diff
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
}
```

## 8. Semantique Camera V0

- Aucun bloc Camera actif : `CinematicCameraPlaybackPose.inactive()`.
- Bloc Camera actif avec mode `reset` ou `hold` : `isActive == true`, `isSupported == true`, `mode` renseigne.
- Bloc Camera actif avec mode manquant ou inconnu : `isActive == true`, `isSupported == false`, diagnostics presents.
- Apres la fin du bloc Camera : retour a `inactive`.
- Aucun effet persistant n'est invente.
- Aucun centre/zoom/follow actor n'est invente.

## 9. Diagnostics camera

Le code existant est reutilise :

```text
cinematicPreviewPlaybackCameraUnsupported
```

Messages no-code :

- `Cadrage caméra incomplet.`
- `Caméra non prévisualisée dans cette version.`

## 10. Progression temporelle

La progression utilise le layout derive existant via `CinematicPreviewPlaybackTimelineItem`.

Hunk pertinent :

```diff
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
```

La meme helper sert aussi au fade, ce qui evite deux calculs divergents.

## 11. Relation fade / actor / seek

- `fadeState` continue de fonctionner.
- `actorPoses` ne sont pas modifies par la camera.
- `frameAt(timeMs)` reste deterministe.
- Seek/scrub futur peut consommer `frameAt(timeMs)` sans etat persistant.

## 12. Non-objectifs confirmes

Non demarres :

- V1-124 ;
- UI camera ;
- renderer camera ;
- overlay camera ;
- mutation viewport editor ;
- runtime ;
- Flame ;
- GameState ;
- screenshot ;
- Visual Gate.

## 13. Hygiene de diff

Fichiers modifies :

- `packages/map_core/lib/src/read_models/cinematic_preview_playback_plan.dart`
- `packages/map_core/test/cinematic_preview_playback_plan_test.dart`
- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`

Fichiers crees :

- `reports/narrativeStudio/scenes/ns_scenes_v1_123_cinematic_camera_playback_state_read_model_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_123_evidence_pack.md`

Aucun reformat global. Aucun fichier sous `packages/map_editor`, `packages/map_runtime`, `packages/map_gameplay`, `packages/map_battle`, `examples/playable_runtime_host`, `assets` ou `selbrume` n'a ete modifie.

## 14. Code genere

Cette section ajoute explicitement le code Dart genere/modifie pour V1-123.

### 14.1 Etat camera preview

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
```

### 14.2 Frame playback avec cameraPose non nullable

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

### 14.3 Helpers camera/progression

Fichier : `packages/map_core/lib/src/read_models/cinematic_preview_playback_plan.dart`

```dart
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

### 14.4 Tests V1-123 ajoutes

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

### 14.5 Non-regression fade mise a jour

Fichier : `packages/map_core/test/cinematic_preview_playback_plan_test.dart`

```dart
test('fade returns fade state alongside camera playback state', () {
  final plan = buildCinematicPreviewPlaybackPlan(
    cinematic: CinematicAsset(
      id: 'cinematic_fx',
      title: 'FX cinematic',
      timeline: CinematicTimeline(
        steps: [
          CinematicTimelineStep(
            id: 'fade_out',
            kind: CinematicTimelineStepKind.fade,
            durationMs: 1000,
            metadata: const {
              cinematicTimelineFadeModeMetadataKey: 'fadeOut',
            },
          ),
          CinematicTimelineStep(
            id: 'camera_hold',
            kind: CinematicTimelineStepKind.camera,
            durationMs: 500,
            metadata: const {
              cinematicTimelineCameraModeMetadataKey: 'hold',
            },
          ),
        ],
      ),
    ),
  );

  final fadeFrame = plan.frameAt(500);
  final cameraFrame = plan.frameAt(1200);

  expect(fadeFrame.fadeState, isNotNull);
  expect(fadeFrame.fadeState!.mode, CinematicFadePlaybackMode.fadeOut);
  expect(fadeFrame.fadeState!.opacity, closeTo(0.5, 0.001));
  expect(cameraFrame.cameraPose.isActive, isTrue);
  expect(cameraFrame.cameraPose.isSupported, isTrue);
  expect(cameraFrame.cameraPose.mode, CinematicTimelineCameraMode.hold);
  expect(plan.capabilities.supportsFade, isTrue);
  expect(plan.capabilities.supportsCamera, isTrue);
  expect(plan.capabilities.hasUnsupportedSteps, isFalse);
  expect(
    cameraFrame.visibleDiagnostics.map((diagnostic) => diagnostic.code),
    isNot(
      contains(
        CinematicPreviewPlaybackDiagnosticCode
            .cinematicPreviewPlaybackCameraUnsupported,
      ),
    ),
  );
});
```

## 15. Tests RED

Tests ajoutes avant implementation :

- `V1-123 camera block produces active playback state`
- `V1-123 camera playback state exposes clamped progress`
- `V1-123 unsupported camera mode produces diagnostic without crashing`

Resultat RED : echec attendu, le modele ne possedait pas encore `isActive`, `isSupported`, `mode`, `progress` et `diagnostics`, et `cameraPose` etait nullable.

## 16. Tests GREEN

Tests V1-123 finaux :

- etat actif avec `reset` ;
- progression clamp avant/pendant/apres ;
- mode inconnu diagnostique sans crash ;
- mode manquant diagnostique et non-mutation de l'asset ;
- blocs camera consecutifs avec frontiere deterministe ;
- non-regression fade + camera state.

## 17. Tests executes

Commande :

```bash
cd packages/map_core && dart test --reporter=compact test/cinematic_preview_playback_plan_test.dart
```

Resultat exact final :

```text
00:00 +17: All tests passed!
```

Commande :

```bash
cd packages/map_core && dart test --reporter=compact test/cinematic_timeline_time_layout_read_model_test.dart
```

Resultat exact final :

```text
00:00 +4: All tests passed!
```

Commande :

```bash
cd packages/map_core && dart test --reporter=compact test/cinematic_actor_display_preview_model_test.dart
```

Resultat exact final :

```text
00:00 +27: All tests passed!
```

Commande :

```bash
cd packages/map_core && dart test --reporter=compact
```

Resultat exact final :

```text
00:05 +2501: All tests passed!
```

Regressions editor :

```bash
cd packages/map_editor && flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --name "V1-121"
```

```text
00:03 +5: All tests passed!
```

```bash
cd packages/map_editor && flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --name "V1-120"
```

```text
00:04 +9: All tests passed!
```

Note : un premier lancement parallele de V1-121 a echoue avant execution des tests sur `build/native_assets/macos/objective_c.dylib` manquant. La relance sequentielle a passe ; l'echec est classe environnement/concurrence native assets, non regression produit.

## 18. Analyse statique

Commande :

```bash
cd packages/map_core && dart analyze
```

Sortie :

```text
Analyzing map_core...
No issues found!
```

## 19. Build non lance

Build non lance : aucun fichier editor/runtime n'a ete modifie. La validation alternative est :

- suite complete `map_core` ;
- `dart analyze` `map_core` ;
- regressions ciblees Builder V1-120/V1-121.

## 20. Checks anti-scope

Avant creation des rapports, les anti-scope code etaient vides :

```bash
git diff --unified=0 | rg -n "package:flutter|package:flame|GameState|PlayableMapGame|SceneRuntimeExecutor|CinematicRuntimeAdapter|map_runtime|map_gameplay|BuildContext|Widget|CameraComponent|Timer\.periodic|Future\.delayed|Stream\.periodic|DateTime\.now|V1-124" || true
```

Sortie :

```text
<vide>
```

```bash
git diff --name-only -- packages/map_editor
```

Sortie :

```text
<vide>
```

```bash
git diff --name-only -- packages/map_editor packages/map_runtime packages/map_gameplay packages/map_battle examples/playable_runtime_host assets selbrume
```

Sortie :

```text
<vide>
```

```bash
find reports/narrativeStudio/scenes/screenshots -maxdepth 1 -name '*v1_123*' -print
find reports/narrativeStudio/scenes/screenshots -maxdepth 1 -name '*v1_124*' -print
```

Sortie :

```text
<vide>
```

## 21. Roadmaps mises a jour

Roadmaps mises a jour :

- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`

V1-123 est marque DONE. Prochain lot recommande :

```text
NS-SCENES-V1-124 — Cinematic Camera Preview Playback UI V0
```

V1-124 n'est pas demarre.

## 22. git diff --check/stat/name-only/status final

Etat avant creation des rapports :

```bash
git diff --stat
```

```text
.../cinematic_preview_playback_plan.dart           | 145 ++++++++++++---
.../test/cinematic_preview_playback_plan_test.dart | 206 ++++++++++++++++++++-
.../scenes/road_map_scene_builder_authoring.md     |  41 ++--
reports/narrativeStudio/scenes/road_map_scenes.md  |  46 +++--
4 files changed, 372 insertions(+), 66 deletions(-)
```

Commandes finales post-rapport :

```bash
git diff --check
```

Sortie :

```text
<vide>
```

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

Note : les deux rapports V1-123 sont non suivis et apparaissent dans `git status`, pas dans `git diff --name-only` tant qu'aucune commande Git d'ecriture n'est lancee.

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

## 23. Risques restants

- Les blocs Camera V0 ne portent pas encore de centre/zoom/target fiable.
- V1-124 pourra afficher un etat no-code et un cadre/diagnostic, mais pas un cadrage riche sans enrichissement authoring futur.
- Les modes autres que `reset`/`hold` restent unsupported volontairement.

## 24. Auto-critique

L'etat camera est suffisant pour demarrer V1-124 proprement, car l'UI future peut savoir si une camera est active, quel step la pilote, sa progression et si elle est supportee.

Le modele Camera existant reste pauvre : il ne permet pas d'exposer honnêtement `centerX`, `centerY`, `zoom`, `targetKind` ou `targetId`.

Les diagnostics sont assez utiles pour une UI V0, mais ils devront probablement etre enrichis quand les blocs Camera authoring porteront des donnees de cadrage.

La progression temporelle est robuste aux bornes grace au layout derive et au clamp, avec tests sur debut, milieu, fin et blocs consecutifs.

Un bis n'est pas recommande pour V1-123 : la prochaine etape naturelle est V1-124 UI, en gardant les limites visibles.

## 25. Verdict final

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
```

## 26. Prochain lot recommande

```text
NS-SCENES-V1-124 — Cinematic Camera Preview Playback UI V0
```
