# NS-SCENES-V1-110 — Evidence Pack

## Verdict

```text
NS-SCENES-V1-110 : DONE.
Playback Plan : implémenté dans map_core.
Frames déterministes : disponibles.
actorMove direct/manual path : supportés côté plan pur.
Transport UI : non démarré.
Ticker : absent.
Runtime / Flame / GameState : non touchés.
Aucun map_editor.
Aucun screenshot.
V1-111 recommandé, non démarré.
```

## Gate 0 Complet

Lot exécuté :

```text
NS-SCENES-V1-110 — Cinematic Preview Playback Plan Read Model V0
```

Type :

```text
core / read-model / pure Dart / no UI
```

Interdits respectés :

- pas de `map_editor` ;
- pas de `map_runtime` ;
- pas de `map_gameplay` ;
- pas de `map_battle` ;
- pas de `examples/playable_runtime_host` ;
- pas de transport actif ;
- pas de Play/Pause/Stop/Reset actif ;
- pas de ticker/timer ;
- pas de Flutter/Flame/runtime/GameState ;
- pas de screenshot / Visual Gate ;
- pas de V1-111.

## Règles Lues

```text
AGENTS.md
agent_rules.md
codex_rule.md
skills/using-superpowers/SKILL.md
skills/test-driven-development/SKILL.md
/Users/karim/.codex/skills/dart-add-unit-test/SKILL.md
skills/verification-before-completion/SKILL.md
```

`codex_rules.md` :

```text
Absent dans le repo au moment de l'audit.
```

## État Git Initial

Commandes demandées :

```bash
pwd
git branch --show-current
git status --short --untracked-files=all
git diff --stat
git diff --name-only
git log --oneline -n 10
```

Sorties observées au début du lot :

```text
/Users/karim/Project/pokemonProject
main
```

`git status --short --untracked-files=all` :

```text
Sortie : <vide>
```

`git diff --stat` :

```text
Sortie : <vide>
```

`git diff --name-only` :

```text
Sortie : <vide>
```

`git log --oneline -n 10` :

```text
8cf3b6f6 docs: préparation contrat preview/playback cinematic v1.109
3ed90377 fix: corrections tests et rapports v1.108
4670f42c update selbrume
caaa7f65 feat: cinematic manual path drawing UI et rapports v1.108
b54e1cd3 docs: ajout rapports v1.107 bis (nettoyage JSON et hardening)
ecb0d64b feat: cinematic manual path core model et tests
550e6364 docs: mise à jour roadmaps et ajout rapports v1.106
73be9440 feat: cinematic builder UX simplification et rapports
d93136a5 refactor: UI cinematic builder workspace et tests
1444a60f update selbrume
```

## Fichiers Lus

Rapports :

- `reports/narrativeStudio/scenes/ns_scenes_v1_108_cinematic_manual_path_drawing_ui_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_108_evidence_pack.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_109_cinematic_preview_playback_prep_contract.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_109_evidence_pack.md`
- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_51_cinematic_timeline_time_axis_bar_layout_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_52_cinematic_timeline_selection_cursor_playhead_placeholder_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_53_cinematic_timeline_transport_controls_placeholder_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_61_cinematic_timeline_mouse_playhead_scrub_prep_contract.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_62_cinematic_timeline_mouse_time_probe_playhead_drag_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_67_cinematic_timeline_duration_editing_resize_prep_contract.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_68_cinematic_timeline_duration_inspector_editing_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_69_cinematic_timeline_duration_resize_handles_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_107_cinematic_manual_path_core_model_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_107_bis_cinematic_manual_path_evidence_json_cleanup_hardening.md`

Code :

- `packages/map_core/lib/src/models/cinematic_asset.dart`
- `packages/map_core/lib/src/authoring/cinematic_authoring_operations.dart`
- `packages/map_core/lib/src/diagnostics/cinematic_diagnostics.dart`
- `packages/map_core/lib/src/read_models/cinematic_actor_display_preview_model.dart`
- `packages/map_core/lib/src/read_models/cinematic_timeline_lane_read_model.dart`
- `packages/map_core/lib/src/read_models/cinematic_timeline_time_layout_read_model.dart`
- `packages/map_core/lib/map_core.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_manual_path_preview_overlay.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_actor_display_preview_overlay.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_viewport_transform.dart`

Tests :

- `packages/map_core/test/cinematic_asset_test.dart`
- `packages/map_core/test/cinematic_authoring_operations_test.dart`
- `packages/map_core/test/cinematic_diagnostics_test.dart`
- `packages/map_core/test/cinematic_actor_display_preview_model_test.dart`
- `packages/map_core/test/cinematic_timeline_lane_read_model_test.dart`
- `packages/map_core/test/cinematic_timeline_time_layout_read_model_test.dart`

## Fichiers Modifiés

```text
packages/map_core/lib/map_core.dart
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md
```

Zones modifiées :

- `packages/map_core/lib/map_core.dart` : ajout de l'export public `cinematic_preview_playback_plan.dart`.
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md` : V1-110 passe DONE, V1-111 devient le prochain lot.
- `reports/narrativeStudio/scenes/road_map_scenes.md` : V1-110 passe DONE, V1-111 devient le prochain lot.

## Fichiers Créés

```text
packages/map_core/lib/src/read_models/cinematic_preview_playback_plan.dart
packages/map_core/test/cinematic_preview_playback_plan_test.dart
reports/narrativeStudio/scenes/ns_scenes_v1_110_cinematic_preview_playback_plan_read_model_v0.md
reports/narrativeStudio/scenes/ns_scenes_v1_110_evidence_pack.md
```

Tailles :

```text
1314 packages/map_core/lib/src/read_models/cinematic_preview_playback_plan.dart
594 packages/map_core/test/cinematic_preview_playback_plan_test.dart
```

Empreintes :

```text
dbd29e6079230cb5231275a6ab3203d667a0b86416321904e872bb37abf8412f  packages/map_core/lib/src/read_models/cinematic_preview_playback_plan.dart
1aabb7a606582ce18c25333da7b182888c327fca5c01665a3a4f847870e3c8bf  packages/map_core/test/cinematic_preview_playback_plan_test.dart
```

## Code Généré — Inventaire Complet

Fichier :

```text
packages/map_core/lib/src/read_models/cinematic_preview_playback_plan.dart
```

API publique :

```text
10: enum CinematicPreviewPlaybackDiagnosticSeverity
16: enum CinematicPreviewPlaybackDiagnosticCode
32: enum CinematicActorPlaybackPoseSource
41: enum CinematicPreviewPlaybackPointSource
48: enum CinematicFadePlaybackMode
55: final class CinematicPreviewPlaybackDiagnostic
100: final class CinematicPreviewPlaybackCapabilities
144: final class CinematicPreviewPlaybackPoint
171: final class CinematicActorPlaybackPose
243: final class CinematicPreviewActorTrack
276: final class CinematicPreviewPlaybackTimelineItem
355: final class CinematicFadePlaybackState
379: final class CinematicCameraPlaybackPose
400: final class CinematicPreviewPlaybackFrame
459: final class CinematicPreviewPlaybackPlan
503: CinematicPreviewPlaybackPlan buildCinematicPreviewPlaybackPlan(...)
693: CinematicPreviewPlaybackFrame evaluateCinematicPreviewPlaybackFrame(...)
```

Structures privées :

```text
1276: final class _ActorMovePlaybackPlan
1293: final class _RouteSegment
1306: final class _RouteInterpolation
```

Extrait du code généré public :

```dart
enum CinematicPreviewPlaybackDiagnosticSeverity {
  info,
  warning,
  error,
}

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
  cinematicPreviewPlaybackFadeUnsupported,
}

@immutable
final class CinematicPreviewPlaybackPlan {
  const CinematicPreviewPlaybackPlan({
    required this.cinematicId,
    required this.totalDurationMs,
    required this.timelineItems,
    required this.actorTracks,
    required this.diagnostics,
    required this.capabilities,
    required this._actorMovePlans,
    required this._faceDirections,
    required this._fadeModes,
  });

  final String cinematicId;
  final int totalDurationMs;
  final List<CinematicPreviewPlaybackTimelineItem> timelineItems;
  final List<CinematicPreviewActorTrack> actorTracks;
  final List<CinematicPreviewPlaybackDiagnostic> diagnostics;
  final CinematicPreviewPlaybackCapabilities capabilities;

  CinematicPreviewPlaybackFrame frameAt(int timeMs) =>
      evaluateCinematicPreviewPlaybackFrame(this, timeMs: timeMs);
}

CinematicPreviewPlaybackPlan buildCinematicPreviewPlaybackPlan({
  required CinematicAsset cinematic,
  CinematicActorDisplayPreviewModel? actorDisplayPreviewModel,
  Map<String, CinematicPreviewPlaybackPoint> resolvedMovementTargets = const {},
});

CinematicPreviewPlaybackFrame evaluateCinematicPreviewPlaybackFrame(
  CinematicPreviewPlaybackPlan plan, {
  required int timeMs,
});
```

Hunks principaux :

```diff
+export 'src/read_models/cinematic_preview_playback_plan.dart';
```

```text
Nouveau read model :
- imports purs Dart/meta/map_core internes uniquement ;
- diagnostics playback preview ;
- capabilities ;
- points purs x/y ;
- poses acteurs ;
- timeline items ;
- fade state ;
- camera placeholder ;
- frame ;
- plan ;
- builder ;
- evaluator ;
- helpers interpolation route/manual path.
```

## Tests Créés — Inventaire

Fichier :

```text
packages/map_core/test/cinematic_preview_playback_plan_test.dart
```

Tests :

```text
6: empty cinematic produces an empty plan and timeline diagnostic
34: derives timeline items and clamps frame time deterministically
97: uses actor display preview position before stageContext placement
144: reports missing initial pose without fake zero fallback
172: actorFace changes facing and wait preserves the pose
188: direct actorMove interpolates linearly and reaches destination
208: direct actorMove missing destination produces diagnostic
233: manual actorMove interpolates through waypoints by distance
252: manual actorMove reports missing path and missing waypoint
285: manual actorMove with all zero-length segments stays deterministic
316: fade returns fade state and camera remains an unsupported placeholder
360: unsupported steps produce no-code diagnostics
```

## Sorties Exactes — Tests Ciblés

Commande :

```bash
cd packages/map_core
dart test --reporter=compact test/cinematic_preview_playback_plan_test.dart
```

Sortie finale stable :

```text
00:00 +12: All tests passed!
```

Commande :

```bash
dart test --reporter=compact test/cinematic_timeline_time_layout_read_model_test.dart
```

Sortie finale stable :

```text
00:00 +4: All tests passed!
```

Commande :

```bash
dart test --reporter=compact test/cinematic_actor_display_preview_model_test.dart
```

Sortie finale stable :

```text
00:00 +27: All tests passed!
```

Commande :

```bash
dart test --reporter=compact test/cinematic_asset_test.dart
```

Sortie finale stable :

```text
00:00 +21: All tests passed!
```

Commande :

```bash
dart test --reporter=compact test/cinematic_authoring_operations_test.dart
```

Sortie finale stable :

```text
00:00 +67: All tests passed!
```

Commande :

```bash
dart test --reporter=compact test/cinematic_diagnostics_test.dart
```

Sortie finale stable :

```text
00:00 +53: All tests passed!
```

## Sortie Exacte — Analyse

Commande :

```bash
cd packages/map_core
dart analyze
```

Sortie exacte :

```text
Analyzing map_core...
No issues found!
```

## Sortie Exacte — Suite Complète map_core

Commande :

```bash
cd packages/map_core
dart test --reporter=compact
```

Sortie finale stable :

```text
00:05 +2496: All tests passed!
```

## Build

Commande de build applicatif :

```text
Non lancée : ce lot ne modifie que map_core, package Dart pur sans build applicatif Flutter.
```

Validation alternative lancée :

```text
dart analyze
dart test --reporter=compact
```

Résultat :

```text
No issues found!
00:05 +2496: All tests passed!
```

## Checks Anti-Scope

Commande :

```bash
rg -n "Flutter|dart:ui|Material|Widget|BuildContext|Flame|GameState|PlayableMapGame|Timer|Ticker|AnimationController|Future\.delayed|Stream|DateTime\.now|CustomPainter" packages/map_core/lib/src/read_models/cinematic_preview_playback_plan.dart packages/map_core/test/cinematic_preview_playback_plan_test.dart
```

Sortie :

```text
Sortie : <vide>
```

## Roadmaps

Roadmaps mises à jour :

- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`

V1-110 est DONE. Le prochain lot recommandé est :

```text
NS-SCENES-V1-111 — Cinematic Preview Playback Transport UI V0
```

## Git Final

Les sorties ci-dessous ont été actualisées après création des rapports.

`git diff --check` :

```text
Sortie : <vide>
```

`git diff --stat` :

```text
 packages/map_core/lib/map_core.dart                  |  1 +
 .../scenes/road_map_scene_builder_authoring.md       | 17 +++++++++++++++--
 reports/narrativeStudio/scenes/road_map_scenes.md    | 20 +++++++++++++++++---
 3 files changed, 33 insertions(+), 5 deletions(-)
```

Note : les fichiers non suivis ne sont pas inclus par `git diff --stat`; ils sont listés dans `git status --short --untracked-files=all`.

`git diff --name-only` :

```text
packages/map_core/lib/map_core.dart
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md
```

`git status --short --untracked-files=all` :

```text
 M packages/map_core/lib/map_core.dart
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? packages/map_core/lib/src/read_models/cinematic_preview_playback_plan.dart
?? packages/map_core/test/cinematic_preview_playback_plan_test.dart
?? reports/narrativeStudio/scenes/ns_scenes_v1_110_cinematic_preview_playback_plan_read_model_v0.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_110_evidence_pack.md
```

## Checks Anti-Scope Git Finaux

`git diff --name-only -- packages/map_editor packages/map_runtime packages/map_gameplay packages/map_battle examples/playable_runtime_host` :

```text
Sortie : <vide>
```

`git diff --name-only -- examples/playable_runtime_host/macos/Runner.xcodeproj/project.pbxproj packages/map_editor/macos/Runner.xcodeproj/project.pbxproj` :

```text
Sortie : <vide>
```

`find reports/narrativeStudio/scenes/screenshots -maxdepth 1 -name '*v1_110*' -print` :

```text
Sortie : <vide>
```

## Confirmations Anti-Scope

- Aucun `map_editor` modifié.
- Aucun runtime/Flame/playback UI ajouté.
- Aucun `GameState` / `PlayableMapGame` touché.
- Aucun screenshot créé.
- V1-111 non démarré.

## Sub-Agents / Passes Séparées

```text
Sub-agent Audit / Architecture : PASS.
Sub-agent Implémentation : PASS.
Sub-agent Tests : PASS.
Sub-agent Build / Validation : PASS.
Sub-agent Critique finale : PASS avec limites documentées.
```

## Risques Restants

- La caméra reste unsupported en V0.
- Le fade est volontairement simple.
- Le plan ne promet pas la vérité runtime.
- L'UI V1-111 devra choisir comment afficher diagnostics/capabilities sans donner l'impression que tout est jouable visuellement.

## Auto-Critique

Le lot est bien borné et les tests couvrent les cas principaux, y compris les erreurs. La partie manual path est suffisamment encadrée pour V0 : pas de coordonnées libres, pas de destination injectée dans les waypoints, et les segments nuls ne crashent pas. La prochaine zone à surveiller est la consommation UI du plan, surtout la distinction entre Selection Cursor, Mouse Probe et Playback Playhead.
