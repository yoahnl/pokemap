# NS-SCENES-V1-117 — Cinematic Actor Animation Cadence / Playback Status Polish V0

## 1. Resume executif

Verdict fonctionnel : `NS-SCENES-V1-117` est implemente cote editor-only.

Le lot polit deux points visibles herites de V1-116 :

- la cadence walk/run est maintenant ajustee par une vitesse observee depuis deux frames du `CinematicPreviewPlaybackPlan` ;
- les statuts de preview ne disent plus `Sans lecture` / `Acteurs statiques` pendant une lecture animee active.

Le scope reste celui demande : pas de runtime, pas de Flame, pas de GameState, pas de `map_core`, pas de recalcul de route actorMove/manual path et pas de V1-118 demarre.

Note de worktree : `selbrume/project.json` est apparu modifie pendant la cloture finale, hors patches V1-117. Il est documente dans les checks finaux et laisse intact pour ne pas ecraser un changement utilisateur/externe.

## 2. Gate 0

Commande initiale :

```bash
pwd
git branch --show-current
git status --short --untracked-files=all
git diff --stat
git diff --name-only
git log --oneline -n 10
```

Sorties capturees au debut du lot :

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

Fichiers de regles lus :

- `AGENTS.md`
- `agent_rules.md`
- `codex_rule.md`
- `skills/README.md`
- `skills/using-superpowers/SKILL.md`
- `skills/test-driven-development/SKILL.md`
- `skills/verification-before-completion/SKILL.md`

Fichier absent documente : `codex_rules.md`.

Passes realisees : TDD RED, implementation minimale, GREEN cible, non-regressions, Visual Gate, anti-scope, rapports/roadmaps.

Sub-agents : aucun sub-agent lance. La verification a ete faite en passes locales separees.

## 3. Fichiers lus

Rapports recents audites :

- `reports/narrativeStudio/scenes/ns_scenes_v1_110_cinematic_preview_playback_plan_read_model_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_111_cinematic_preview_playback_transport_ui_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_112_cinematic_actormove_preview_playback_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_113_cinematic_actor_playback_smooth_motion_subtile_overlay_polish_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_114_cinematic_actor_walking_animation_prep_contract.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_115_cinematic_actor_walking_animation_frame_resolver_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_115_evidence_pack.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_116_cinematic_actor_walking_animation_renderer_integration_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_116_evidence_pack.md`
- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`

Fichiers core lus en lecture seule :

- `packages/map_core/lib/src/read_models/cinematic_preview_playback_plan.dart`
- `packages/map_core/lib/src/read_models/cinematic_actor_display_preview_model.dart`
- `packages/map_core/lib/src/authoring/cinematic_authoring_operations.dart`
- `packages/map_core/lib/src/models/cinematic_asset.dart`
- `packages/map_core/lib/src/models/project_manifest.dart`
- `packages/map_core/lib/src/models/enums.dart`
- `packages/map_core/lib/map_core.dart`

Fichiers editor et tests lus :

- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_actor_walking_animation_preview_resolver.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_actor_sprite_preview_plan.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_actor_sprite_preview_resolver.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_actor_sprite_preview_renderer.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_actor_display_preview_overlay.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_preview_playback_actor_overlay_adapter.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_viewport_transform.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart`
- `packages/map_editor/test/cinematic_actor_walking_animation_preview_resolver_test.dart`
- `packages/map_editor/test/cinematic_actor_sprite_preview_renderer_test.dart`
- `packages/map_editor/test/cinematic_builder_workspace_test.dart`
- `packages/map_editor/test/cinematics_library_workspace_test.dart`
- `packages/map_core/test/cinematic_preview_playback_plan_test.dart`
- `packages/map_core/test/cinematic_actor_display_preview_model_test.dart`

## 4. Rappel V1-116

V1-116 a branche le resolver V1-115 au rendu preview : les acteurs pouvaient enfin afficher des frames `idle`, `walk`, `run` ou `fallback` pendant le playback editor-only.

Deux limites restaient visibles :

- la cadence restait trop time-based et pouvait etre deconnectee de la vitesse de deplacement ;
- les badges historiques pouvaient encore afficher `Acteurs statiques` ou `Sans lecture` pendant une lecture active.

## 5. Probleme cadence / vitesse

La cadence ne devait pas recalculer le chemin. Le mouvement reste la responsabilite du playback plan pur deja livre par V1-110.

Decision : observer la vitesse depuis deux poses deja calculees :

```text
current frame = playbackPlan.frameAt(playbackTimeMs)
previous frame = playbackPlan.frameAt(max(0, playbackTimeMs - 100))
velocity = (abs(dx) + abs(dy)) / 0.1
```

Pas de `sqrt`, `hypot`, distance de waypoint, `RouteSegment`, pathfinding ou collision.

## 6. Probleme statuts / badges

Les anciens labels etaient trop historiques :

- `Sans lecture`
- `Acteurs statiques`

Ils ont ete remplaces par des statuts no-code calcules depuis l'etat de playback et la qualite de resolution animation :

- `Aperçu statique`
- `Lecture en cours`
- `Lecture en pause`
- `Animation acteur prête`
- `Animation partielle`
- `Aucun acteur animé`

## 7. Decision d'architecture cadence

Le modele ajoute est un hint optionnel cote editor :

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

Le resolver V1-115 continue de fonctionner sans hint. Avec hint, seule la duree effective des frames walk/run est ajustee.

## 8. Calcul de vitesse observee

Code ajoute dans `cinematic_builder_workspace.dart` :

```dart
Map<String, CinematicActorAnimationCadenceHint> _cadenceHintsForPlayback({
  required CinematicPreviewPlaybackPlan playbackPlan,
  required CinematicPreviewPlaybackFrame? playbackFrame,
  required int playbackTimeMs,
}) {
  if (playbackFrame == null || playbackTimeMs <= 0) {
    return const {};
  }

  final previousFrame = playbackPlan.frameAt(
    math.max(0, playbackTimeMs - _actorAnimationCadenceSampleWindowMs),
  );

  final hints = <String, CinematicActorAnimationCadenceHint>{};
  for (final pose in playbackFrame.actorPoses) {
    if (!pose.hasPosition) {
      continue;
    }
    final previousPose = previousFrame.actorPoseById(pose.actorId);
    if (previousPose == null || !previousPose.hasPosition) {
      continue;
    }

    final velocityTilesPerSecond = ((pose.x! - previousPose.x!).abs() +
            (pose.y! - previousPose.y!).abs()) /
        (_actorAnimationCadenceSampleWindowMs / 1000);
    if (!velocityTilesPerSecond.isFinite || velocityTilesPerSecond < 0) {
      continue;
    }
    hints[pose.actorId] = CinematicActorAnimationCadenceHint(
      actorId: pose.actorId,
      velocityTilesPerSecond: velocityTilesPerSecond,
      sampleWindowMs: _actorAnimationCadenceSampleWindowMs,
    );
  }
  return hints;
}
```

## 9. Cadence factor et bornes

Code ajoute dans `cinematic_actor_walking_animation_preview_resolver.dart` :

```dart
final rawFactor = cadenceHint.velocityTilesPerSecond / referenceSpeed;
final cadenceFactor = rawFactor.clamp(0.75, 1.75).toDouble();
return (baseDurationMs / cadenceFactor).round().clamp(60, 260);
```

References :

- walk : `2.0 tiles/s`
- run : `4.0 tiles/s`
- facteur borne : `0.75..1.75`
- frame duration bornee : `60..260 ms`

## 10. Integration resolver / renderer

Le builder cree maintenant une resolution de plan sprite qui transporte aussi l'etat animation :

```dart
final spritePreviewResolution = isPlaybackOverlayActive
    ? _resolvePlaybackActorSpritePreviewPlan(
        basePlan: widget.actorSpritePreviewPlan,
        displayModel: playbackActorOverlayModel?.displayModel ??
            widget.actorDisplayPreviewModel,
        playbackFrame: playbackFrame,
        playbackTimeMs: playbackTimeMs,
        isPlaybackPlaying: _isPlaybackPlaying,
        timelineSteps: widget.asset.timeline.steps,
        characters: widget.characters,
        cadenceHintsByActorId: cadenceHintsByActorId,
      )
    : _PlaybackActorSpritePreviewResolution(
        plan: widget.actorSpritePreviewPlan,
        animationStatus: _hasReadyActorSprite(widget.actorSpritePreviewPlan)
            ? _PlaybackActorAnimationStatus.ready
            : _PlaybackActorAnimationStatus.none,
      );
```

Le renderer ne calcule pas de route. Il consomme seulement le `sourceTileRect` resolu.

## 11. Statuts et wording final

Code ajoute :

```dart
CinematicPlaybackPreviewStatus _playbackPreviewStatusFor({
  required bool isPlaybackOverlayActive,
  required bool isPlaybackPlaying,
  required _PlaybackActorAnimationStatus animationStatus,
}) {
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
  return CinematicPlaybackPreviewStatus(
    playbackLabel: playbackLabel,
    playbackTone: playbackTone,
    actorAnimationLabel: actorAnimationLabel,
    actorAnimationTone: actorAnimationTone,
  );
}
```

Le panneau `CinematicMapBackdropPreviewPanel` expose `CinematicPlaybackPreviewStatus` et remplace les badges fixes par ces labels calcules.

## 12. Diagnostics animation synthetiques

Le statut utilisateur reste volontairement court :

- `Animation acteur prête` si au moins une frame walk/run non fallback est rendue ;
- `Animation partielle` si un acteur bouge mais retombe sur fallback/placeholder ;
- `Aucun acteur animé` si aucun acteur ne peut etre anime.

Les details techniques restent dans les tests/diagnostics, pas comme workflow principal.

## 13. Pause / Stop / Reset

Pause : la frame reste stable car le calcul depend de `playbackTimeMs`, pas du temps systeme.

Stop/Reset : le playhead revient a `0`, donc le resolver retombe sur idle/fallback comme attendu.

Aucun `Timer.periodic`, `Future.delayed`, `Stream.periodic`, `DateTime.now` ou `AnimationController` supplementaire n'a ete ajoute pour la cadence.

## 14. Manual path

Manual path continue de passer par les poses du playback plan. V1-117 compare seulement deux poses deja calculees ; il ne lit pas les distances de waypoints et ne segmente pas le chemin.

Test ajoute : `V1-117 manual path playback uses cadence hint without mutating waypoints`.

## 15. Non-objectifs confirmes

Non-objectifs respectes dans le code V1-117 :

- pas de runtime cinematic playback ;
- pas de Flame ;
- pas de GameState ;
- pas de `map_core` ;
- pas de `map_runtime`, `map_gameplay`, `map_battle` ;
- pas de pathfinding/collision ;
- pas de recalcul de route actorMove/manual path ;
- pas de V1-118.

Reserve de worktree : `selbrume/project.json` est modifie en dehors de ces patches et apparait dans les checks finaux.

## 16. Hygiene de diff

Fichiers modifies pour V1-117 :

- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_actor_walking_animation_preview_resolver.dart` : hint cadence optionnel et facteur borne.
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart` : calcul de vitesse depuis poses playback, statut animation, passage du plan sprite anime.
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart` : modele de statut visible, remplacement des badges fixes.
- `packages/map_editor/test/cinematic_actor_walking_animation_preview_resolver_test.dart` : tests cadence resolver.
- `packages/map_editor/test/cinematic_builder_workspace_test.dart` : tests V1-117 et Visual Gate.
- `packages/map_editor/test/cinematics_library_workspace_test.dart` : alignement des anciens labels.
- `reports/narrativeStudio/scenes/road_map_scenes.md` : V1-117 DONE, V1-118 recommande.
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md` : V1-117 DONE, V1-118 recommande.

Fichiers crees :

- `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_117_cinematic_actor_animation_cadence_playback_status_polish_v0.png`
- `reports/narrativeStudio/scenes/ns_scenes_v1_117_cinematic_actor_animation_cadence_playback_status_polish_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_117_evidence_pack.md`

Aucun reformat global lance.

## 17. Tests ajoutes/modifies

Resolver :

- `without cadence hint keeps V1-115 time-based cadence`
- `cadence hint speeds up fast walk and slows down slow walk`
- `cadence hint clamps fast movement and ignores zero velocity`
- `cadence hint remains stable and does not affect stationary idle actor`

Builder :

- `V1-117 fast actorMove uses playback velocity cadence for rendered frame`
- `V1-117 run playback advances sprite cadence faster than walk`
- `V1-117 playback status chips stay coherent during active and paused animation`
- `V1-117 fallback animation status is partial and stop returns idle`
- `V1-117 manual path playback uses cadence hint without mutating waypoints`
- `captures V1-117 cinematic actor animation cadence playback status polish visual gate`

## 18. Tests executes

RED avant implementation :

```text
flutter test --reporter=compact test/cinematic_actor_walking_animation_preview_resolver_test.dart
Echec attendu : CinematicActorAnimationCadenceHint et le parametre cadenceHint n'existaient pas.

flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --name "V1-117"
Echec attendu : frame rapide non avancee, statuts "Aperçu statique"/"Animation partielle" absents, manual path encore en premiere frame.
```

GREEN final :

```text
flutter test --reporter=compact test/cinematic_actor_walking_animation_preview_resolver_test.dart
00:01 +13: All tests passed!

flutter test --reporter=compact test/cinematic_actor_sprite_preview_renderer_test.dart
00:02 +21: All tests passed!

flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --name "V1-117"
00:04 +6: All tests passed!

flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --name "V1-116"
00:04 +4: All tests passed!

flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --name "V1-113"
00:04 +5: All tests passed!

flutter test --reporter=compact test/cinematic_builder_workspace_test.dart
00:36 +231: All tests passed!

flutter test --reporter=compact test/cinematics_library_workspace_test.dart test/cinematic_stage_point_preview_overlay_test.dart
00:11 +26: All tests passed!
```

Core cible :

```text
dart test --reporter=compact test/cinematic_preview_playback_plan_test.dart
00:00 +12: All tests passed!

dart test --reporter=compact test/cinematic_actor_display_preview_model_test.dart
00:00 +27: All tests passed!

dart analyze
Analyzing map_core...
No issues found!
```

## 19. Analyse statique

Commande :

```bash
flutter analyze --no-fatal-infos \
  lib/src/ui/canvas/cinematics/cinematic_actor_walking_animation_preview_resolver.dart \
  lib/src/ui/canvas/cinematics/cinematic_actor_sprite_preview_renderer.dart \
  lib/src/ui/canvas/cinematics/cinematic_actor_display_preview_overlay.dart \
  lib/src/ui/canvas/cinematics/cinematic_preview_playback_actor_overlay_adapter.dart \
  lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart \
  lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart \
  test/cinematic_actor_walking_animation_preview_resolver_test.dart \
  test/cinematic_actor_sprite_preview_renderer_test.dart \
  test/cinematic_builder_workspace_test.dart
```

Sortie :

```text
Analyzing 9 items...
77 issues found. (ran in 1.8s)
```

Interpretation : sortie 0 grace a `--no-fatal-infos`; les 77 issues sont des infos non fatales existantes, pas des warnings/errors bloquants.

## 20. Build macOS debug

Commande :

```bash
flutter build macos --debug
```

Sortie :

```text
Building macOS application...
✓ Built build/macos/Build/Products/Debug/map_editor.app
```

## 21. Visual Gate avec ls/file/shasum

Capture :

```text
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_117_cinematic_actor_animation_cadence_playback_status_polish_v0.png
```

Commande de verification :

```bash
flutter test --reporter=compact --dart-define=NS_SCENES_V1_117_CAPTURE_CINEMATIC_ACTOR_ANIMATION_CADENCE_STATUS_POLISH=true test/cinematic_builder_workspace_test.dart --name "captures V1-117"
```

Sortie :

```text
00:06 +1: All tests passed!
```

Preuve fichier :

```text
$ ls -lh reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_117_cinematic_actor_animation_cadence_playback_status_polish_v0.png
-rw-r--r--  1 karim  staff   222K Jun 13 15:03 reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_117_cinematic_actor_animation_cadence_playback_status_polish_v0.png

$ file reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_117_cinematic_actor_animation_cadence_playback_status_polish_v0.png
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_117_cinematic_actor_animation_cadence_playback_status_polish_v0.png: PNG image data, 1663 x 926, 8-bit/color RGBA, non-interlaced

$ shasum -a 256 reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_117_cinematic_actor_animation_cadence_playback_status_polish_v0.png
3594505406263f083538b2b61177a803940b2c6f9c5fe6012a148404c9a84d55  reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_117_cinematic_actor_animation_cadence_playback_status_polish_v0.png
```

Inspection visuelle : Cinematic Builder ouvert, preview visible, timeline visible, playback non nul, acteur en mouvement, ligne manual path visible, badges de trajet visibles, `Lecture en cours` et `Animation acteur prête` visibles, pas de `Sans lecture` ni `Acteurs statiques`.

## 22. Checks anti-scope

Diff grep :

```bash
git diff --unified=0 | rg -n "package:flame|GameState|PlayableMapGame|SceneRuntimeExecutor|CinematicRuntimeAdapter|map_runtime|map_gameplay|Timer\\.periodic|Future\\.delayed|Stream\\.periodic|DateTime\\.now|RouteSegment|pathfinding|collision" || true
```

Sortie : occurrences documentaires dans les roadmaps/rapports V1-116/V1-117 uniquement ; aucune occurrence code V1-117.

Recherche code cible :

```bash
rg -n "sqrt|hypot|RouteSegment|manualPath.*segment|segment.*manualPath|waypoint.*distance|distance.*waypoint|pathfinding|collision" packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_actor_walking_animation_preview_resolver.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_actor_sprite_preview_renderer.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_actor_display_preview_overlay.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart || true
```

Sortie :

```text
<vide>
```

Verification labels :

```bash
rg -n "find\\.text\\('Sans lecture'\\), findsWidgets|find\\.text\\('Acteurs statiques'\\), findsWidgets|Acteurs statiques|Sans lecture" packages/map_editor/test/cinematic_builder_workspace_test.dart packages/map_editor/test/cinematics_library_workspace_test.dart packages/map_editor/lib/src/ui/canvas/cinematics || true
```

Sortie exacte :

```text
packages/map_editor/test/cinematic_builder_workspace_test.dart:7503:      expect(find.text('Sans lecture'), findsNothing);
packages/map_editor/test/cinematic_builder_workspace_test.dart:7504:      expect(find.text('Acteurs statiques'), findsNothing);
packages/map_editor/test/cinematic_builder_workspace_test.dart:7512:      expect(find.text('Sans lecture'), findsNothing);
packages/map_editor/test/cinematic_builder_workspace_test.dart:7513:      expect(find.text('Acteurs statiques'), findsNothing);
packages/map_editor/test/cinematic_builder_workspace_test.dart:7541:      expect(find.text('Sans lecture'), findsNothing);
packages/map_editor/test/cinematic_builder_workspace_test.dart:7628:      expect(find.text('Acteurs statiques'), findsNothing);
packages/map_editor/test/cinematic_builder_workspace_test.dart:7629:      expect(find.text('Sans lecture'), findsNothing);
```

Interpretation : les seules occurrences restantes sont des assertions negatives `findsNothing`.

Anti-scope path :

```bash
git diff --name-only -- packages/map_core packages/map_runtime packages/map_gameplay packages/map_battle examples/playable_runtime_host assets selbrume
```

Sortie de cloture actuelle :

```text
selbrume/project.json
```

Interpretation : ce fichier est hors perimetre V1-117 et n'a pas ete modifie par les patches de code/rapport. Il est laisse intact par securite.

```bash
find reports/narrativeStudio/scenes/screenshots -maxdepth 1 -name '*v1_118*' -print
```

Sortie :

```text
<vide>
```

## 23. Roadmaps mises a jour

Fichiers :

- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`

Mises a jour :

- V1-117 ajoute/marque DONE ;
- les sections historiques V1-114 a V1-116 ne pointent plus vers V1-117 comme prochain lot ;
- le prochain lot global recommande est `NS-SCENES-V1-118 — Cinematic Playback Preview Diagnostics / Fallback Detail Polish V0`.

Justification du prochain lot : V1-117 ferme la cadence et les statuts principaux ; le prochain risque utilisateur est le detail honnete des fallbacks/diagnostics de preview, avant scrub/seek.

## 24. git diff --check/stat/name-only/status final

Sorties finales a jour apres creation des rapports :

```text
$ git diff --check
Sortie : <vide>

$ git diff --stat
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

$ git diff --name-only
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_actor_walking_animation_preview_resolver.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart
packages/map_editor/test/cinematic_actor_walking_animation_preview_resolver_test.dart
packages/map_editor/test/cinematic_builder_workspace_test.dart
packages/map_editor/test/cinematics_library_workspace_test.dart
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md
selbrume/project.json

$ git status --short --untracked-files=all
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

## 25. Risques restants

- La cadence est une heuristique de preview, pas une animation runtime definitive.
- Les bornes `0.75..1.75` et `60..260 ms` sont prudentes ; elles evitent l'effet hysterique mais pourront etre ajustees apres feedback visuel.
- Les diagnostics de fallback restent synthetiques ; V1-118 est recommande pour expliquer les cas partiels sans exposer les details techniques comme workflow principal.
- `selbrume/project.json` est dirty hors perimetre ; il faut decider separement s'il doit etre conserve ou revert.

## 26. Auto-critique

La cadence parait plus naturelle car elle suit une vitesse observee au lieu de seulement tourner au temps brut. La correction reste heuristique, volontairement : elle ne pretend pas resoudre une animation runtime ni analyser une distance de route. Les bornes sont conservatrices et probablement preferables pour eviter une animation nerveuse sur petits deltas. Les statuts sont enfin coherents avec l'etat de lecture et ne contredisent plus la preview active.

Le scope n'a pas derive vers un moteur d'animation. L'absence de progression distance-based complete est acceptable pour V1-117 puisque la source de verite reste le playback plan. Je recommande V1-118 sur diagnostics/fallbacks, pas encore scrub/seek, car l'utilisateur verra davantage les cas `Animation partielle` avant d'avoir besoin d'un scrubber.

Bis non recommande pour V1-117 cote code. Une decision separee est necessaire pour `selbrume/project.json`.

## 27. Verdict final

```text
NS-SCENES-V1-117 : DONE.
Animation cadence polish : actif.
Cadence derivee des poses playback : oui.
Route actorMove/manual path recalculee : non.
Playback status polish : actif.
Badges contradictoires en lecture animee : corriges.
Deplacement sub-tile : conserve.
Runtime / Flame / GameState : non touches.
map_core : non modifie par V1-117.
Visual Gate : creee.
V1-118 : recommande, non demarre.
```

Reserve : le worktree contient `selbrume/project.json` modifie hors perimetre V1-117.

## 28. Prochain lot recommande

```text
NS-SCENES-V1-118 — Cinematic Playback Preview Diagnostics / Fallback Detail Polish V0
```
