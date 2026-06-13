# NS-SCENES-V1-117 — Evidence Pack

## Verdict

`NS-SCENES-V1-117 — Cinematic Actor Animation Cadence / Playback Status Polish V0` est implemente.

La cadence walk/run est derivee des poses du playback plan, les statuts visibles sont coherents avec lecture/pause/apercu statique, la Visual Gate est creee, et V1-118 n'est pas demarre.

Reserve de worktree : `selbrume/project.json` est modifie hors perimetre V1-117 pendant la cloture. Il est documente et laisse intact.

## Gate 0 complet

```text
/Users/karim/Project/pokemonProject
main
 M packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
 M packages/map_editor/test/cinematic_builder_workspace_test.dart
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_116_cinematic_actor_walking_animation_renderer_integration_v0.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_116_evidence_pack.md
?? reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_116_cinematic_actor_walking_animation_renderer_integration_v0.png
 .../cinematics/cinematic_builder_workspace.dart    | 135 +++++-
 .../test/cinematic_builder_workspace_test.dart     | 481 +++++++++++++++++++++
 .../scenes/road_map_scene_builder_authoring.md     |  25 +-
 reports/narrativeStudio/scenes/road_map_scenes.md  |  28 +-
 4 files changed, 648 insertions(+), 21 deletions(-)
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
packages/map_editor/test/cinematic_builder_workspace_test.dart
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md
f99e235c feat: cinematic actor walking animation frame resolver v1.115
0ed41a86 docs: mise à jour rapports et roadmaps v1.114
a6b197c0 docs: préparation contrat animation marche acteur cinematic v1.114
2dff3a1e feat: cinematic actor playback smooth motion v1.113
d41f7f22 feat: cinematic actor move preview playback v1.112
e41f5874 update selbrume
e9972298 Add cinematic preview transport UI
3411ae0b feat: cinematic preview playback plan read model v1.110
8cf3b6f6 docs: préparation contrat preview/playback cinematic v1.109
3ed90377 fix: corrections tests et rapports v1.108
```

## Regles lues

- `AGENTS.md`
- `agent_rules.md`
- `codex_rule.md`
- `skills/README.md`
- `skills/using-superpowers/SKILL.md`
- `skills/test-driven-development/SKILL.md`
- `skills/verification-before-completion/SKILL.md`

Absent : `codex_rules.md`.

## Fichiers lus

Rapports V1-110 a V1-116, roadmaps Scenes/Authoring, fichiers core playback/actor display/cinematic asset/project manifest/enums/barrel, fichiers editor resolver/sprite/overlay/builder/backdrop/library, tests resolver/renderer/builder/library/core ciblés.

## Fichiers modifies

- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_actor_walking_animation_preview_resolver.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart`
- `packages/map_editor/test/cinematic_actor_walking_animation_preview_resolver_test.dart`
- `packages/map_editor/test/cinematic_builder_workspace_test.dart`
- `packages/map_editor/test/cinematics_library_workspace_test.dart`
- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`

Hors scope dirty observe : `selbrume/project.json`.

## Fichiers crees

- `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_117_cinematic_actor_animation_cadence_playback_status_polish_v0.png`
- `reports/narrativeStudio/scenes/ns_scenes_v1_117_cinematic_actor_animation_cadence_playback_status_polish_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_117_evidence_pack.md`

## Hunks pertinents

Cadence hint :

```dart
final class CinematicActorAnimationCadenceHint {
  const CinematicActorAnimationCadenceHint({
    required this.actorId,
    required this.velocityTilesPerSecond,
    required this.sampleWindowMs,
  });

  final String actorId;
  final double velocityTilesPerSecond;
  final int sampleWindowMs;
}
```

Vitesse depuis poses playback :

```dart
final previousFrame = playbackPlan.frameAt(
  math.max(0, playbackTimeMs - _actorAnimationCadenceSampleWindowMs),
);

final velocityTilesPerSecond = ((pose.x! - previousPose.x!).abs() +
        (pose.y! - previousPose.y!).abs()) /
    (_actorAnimationCadenceSampleWindowMs / 1000);
```

Cadence bornee :

```dart
final referenceSpeed = switch (kind) {
  CinematicActorWalkingAnimationPreviewKind.run => 4.0,
  CinematicActorWalkingAnimationPreviewKind.walk => 2.0,
  CinematicActorWalkingAnimationPreviewKind.idle ||
  CinematicActorWalkingAnimationPreviewKind.fallback =>
    0.0,
};

final rawFactor = cadenceHint.velocityTilesPerSecond / referenceSpeed;
final cadenceFactor = rawFactor.clamp(0.75, 1.75).toDouble();
return (baseDurationMs / cadenceFactor).round().clamp(60, 260);
```

Statuts no-code :

```dart
final playbackLabel = isPlaybackPlaying
    ? 'Lecture en cours'
    : isPlaybackOverlayActive
        ? 'Lecture en pause'
        : 'Aperçu statique';
final actorAnimationLabel = switch (animationStatus) {
  _PlaybackActorAnimationStatus.partial => 'Animation partielle',
  _PlaybackActorAnimationStatus.ready => 'Animation acteur prête',
  _PlaybackActorAnimationStatus.none => 'Aucun acteur animé',
};
```

## Preuve cadence depuis playback plan

La fonction `_cadenceHintsForPlayback` lit uniquement :

- `playbackPlan.frameAt(playbackTimeMs)`
- `playbackPlan.frameAt(max(0, playbackTimeMs - 100))`
- `actorPoses`

Elle ne lit pas les routes, segments, manual path distances, collisions ou pathfinding.

## Preuve sans recalcul actorMove/manual path

Commande :

```bash
rg -n "sqrt|hypot|RouteSegment|manualPath.*segment|segment.*manualPath|waypoint.*distance|distance.*waypoint|pathfinding|collision" packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_actor_walking_animation_preview_resolver.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_actor_sprite_preview_renderer.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_actor_display_preview_overlay.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart || true
```

Sortie :

```text
<vide>
```

## Preuve badges historiques absents en lecture animee

Commande :

```bash
rg -n "find\\.text\\('Sans lecture'\\), findsWidgets|find\\.text\\('Acteurs statiques'\\), findsWidgets|Acteurs statiques|Sans lecture" packages/map_editor/test/cinematic_builder_workspace_test.dart packages/map_editor/test/cinematics_library_workspace_test.dart packages/map_editor/lib/src/ui/canvas/cinematics || true
```

Sortie :

```text
packages/map_editor/test/cinematic_builder_workspace_test.dart:7503:      expect(find.text('Sans lecture'), findsNothing);
packages/map_editor/test/cinematic_builder_workspace_test.dart:7504:      expect(find.text('Acteurs statiques'), findsNothing);
packages/map_editor/test/cinematic_builder_workspace_test.dart:7512:      expect(find.text('Sans lecture'), findsNothing);
packages/map_editor/test/cinematic_builder_workspace_test.dart:7513:      expect(find.text('Acteurs statiques'), findsNothing);
packages/map_editor/test/cinematic_builder_workspace_test.dart:7541:      expect(find.text('Sans lecture'), findsNothing);
packages/map_editor/test/cinematic_builder_workspace_test.dart:7628:      expect(find.text('Acteurs statiques'), findsNothing);
packages/map_editor/test/cinematic_builder_workspace_test.dart:7629:      expect(find.text('Sans lecture'), findsNothing);
```

Interpretation : seulement des assertions negatives `findsNothing`; aucun affichage produit positif.

## Sorties exactes tests map_editor

```text
$ flutter test --reporter=compact test/cinematic_actor_walking_animation_preview_resolver_test.dart
00:01 +13: All tests passed!

$ flutter test --reporter=compact test/cinematic_actor_sprite_preview_renderer_test.dart
00:02 +21: All tests passed!

$ flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --name "V1-117"
00:04 +6: All tests passed!

$ flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --name "V1-116"
00:04 +4: All tests passed!

$ flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --name "V1-113"
00:04 +5: All tests passed!

$ flutter test --reporter=compact test/cinematic_builder_workspace_test.dart
00:36 +231: All tests passed!

$ flutter test --reporter=compact test/cinematics_library_workspace_test.dart test/cinematic_stage_point_preview_overlay_test.dart
00:11 +26: All tests passed!

$ flutter test --reporter=compact --dart-define=NS_SCENES_V1_117_CAPTURE_CINEMATIC_ACTOR_ANIMATION_CADENCE_STATUS_POLISH=true test/cinematic_builder_workspace_test.dart --name "captures V1-117"
00:06 +1: All tests passed!
```

## Sorties exactes tests map_core

```text
$ dart test --reporter=compact test/cinematic_preview_playback_plan_test.dart
00:00 +12: All tests passed!

$ dart test --reporter=compact test/cinematic_actor_display_preview_model_test.dart
00:00 +27: All tests passed!

$ dart analyze
Analyzing map_core...
No issues found!
```

## Sortie analyse ciblee

```text
$ flutter analyze --no-fatal-infos lib/src/ui/canvas/cinematics/cinematic_actor_walking_animation_preview_resolver.dart lib/src/ui/canvas/cinematics/cinematic_actor_sprite_preview_renderer.dart lib/src/ui/canvas/cinematics/cinematic_actor_display_preview_overlay.dart lib/src/ui/canvas/cinematics/cinematic_preview_playback_actor_overlay_adapter.dart lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart test/cinematic_actor_walking_animation_preview_resolver_test.dart test/cinematic_actor_sprite_preview_renderer_test.dart test/cinematic_builder_workspace_test.dart
Analyzing 9 items...
77 issues found. (ran in 1.8s)
```

Exit code : 0 avec `--no-fatal-infos`.

## Sortie build macOS debug

```text
$ flutter build macos --debug
Building macOS application...
✓ Built build/macos/Build/Products/Debug/map_editor.app
```

## Visual Gate

Fichier :

```text
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_117_cinematic_actor_animation_cadence_playback_status_polish_v0.png
```

Preuves :

```text
$ ls -lh reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_117_cinematic_actor_animation_cadence_playback_status_polish_v0.png
-rw-r--r--  1 karim  staff   222K Jun 13 15:03 reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_117_cinematic_actor_animation_cadence_playback_status_polish_v0.png

$ file reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_117_cinematic_actor_animation_cadence_playback_status_polish_v0.png
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_117_cinematic_actor_animation_cadence_playback_status_polish_v0.png: PNG image data, 1663 x 926, 8-bit/color RGBA, non-interlaced

$ shasum -a 256 reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_117_cinematic_actor_animation_cadence_playback_status_polish_v0.png
3594505406263f083538b2b61177a803940b2c6f9c5fe6012a148404c9a84d55  reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_117_cinematic_actor_animation_cadence_playback_status_polish_v0.png
```

## git diff --check

```text
Sortie : <vide>
```

## git diff --stat

```text
 ...c_actor_walking_animation_preview_resolver.dart |  83 ++-
 .../cinematics/cinematic_builder_workspace.dart    | 279 +++++++-
 .../cinematic_map_backdrop_preview_panel.dart      |  68 +-
 ...or_walking_animation_preview_resolver_test.dart | 184 +++++
 .../test/cinematic_builder_workspace_test.dart     | 775 ++++++++++++++++++++-
 .../test/cinematics_library_workspace_test.dart    |   8 +-
 .../scenes/road_map_scene_builder_authoring.md     |  46 +-
 reports/narrativeStudio/scenes/road_map_scenes.md  |  50 +-
 selbrume/project.json                              |  29 +-
 9 files changed, 1452 insertions(+), 70 deletions(-)
```

## git diff --name-only

```text
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_actor_walking_animation_preview_resolver.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart
packages/map_editor/test/cinematic_actor_walking_animation_preview_resolver_test.dart
packages/map_editor/test/cinematic_builder_workspace_test.dart
packages/map_editor/test/cinematics_library_workspace_test.dart
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md
selbrume/project.json
```

## git status final

```text
 M packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_actor_walking_animation_preview_resolver.dart
 M packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
 M packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart
 M packages/map_editor/test/cinematic_actor_walking_animation_preview_resolver_test.dart
 M packages/map_editor/test/cinematic_builder_workspace_test.dart
 M packages/map_editor/test/cinematics_library_workspace_test.dart
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
 M selbrume/project.json
?? reports/narrativeStudio/scenes/ns_scenes_v1_116_cinematic_actor_walking_animation_renderer_integration_v0.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_116_evidence_pack.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_117_cinematic_actor_animation_cadence_playback_status_polish_v0.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_117_evidence_pack.md
?? reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_116_cinematic_actor_walking_animation_renderer_integration_v0.png
?? reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_117_cinematic_actor_animation_cadence_playback_status_polish_v0.png
```

## Checks anti-scope

```text
$ git diff --unified=0 | rg -n "package:flame|GameState|PlayableMapGame|SceneRuntimeExecutor|CinematicRuntimeAdapter|map_runtime|map_gameplay|Timer\\.periodic|Future\\.delayed|Stream\\.periodic|DateTime\\.now|RouteSegment|pathfinding|collision" || true
Sortie : occurrences documentaires uniquement dans rapports/roadmaps ; aucune occurrence code V1-117.

$ git diff --name-only -- packages/map_core packages/map_runtime packages/map_gameplay packages/map_battle examples/playable_runtime_host assets selbrume
selbrume/project.json

$ find reports/narrativeStudio/scenes/screenshots -maxdepth 1 -name '*v1_118*' -print
Sortie : <vide>
```

Confirmation : aucun fichier `packages/map_core`, `packages/map_runtime`, `packages/map_gameplay`, `packages/map_battle`, `examples/playable_runtime_host` ou `assets` n'est modifie par V1-117. `selbrume/project.json` est dirty hors perimetre et doit etre decide separement.

## V1-118

V1-118 n'est pas demarre.

Prochain lot recommande :

```text
NS-SCENES-V1-118 — Cinematic Playback Preview Diagnostics / Fallback Detail Polish V0
```
