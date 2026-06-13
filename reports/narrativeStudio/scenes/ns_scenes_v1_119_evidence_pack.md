# NS-SCENES-V1-119 — Evidence Pack

## Lot

`NS-SCENES-V1-119 — Cinematic Preview Playback Scrub / Seek Prep Contract`

Type : `doc-only / architecture-review / interaction-contract / UX-contract`.

## Gate 0 complet

Commande :

```bash
pwd && git branch --show-current && git status --short --untracked-files=all && git diff --stat && git diff --name-only && git log --oneline -n 10
```

Sortie :

```text
/Users/karim/Project/pokemonProject
main
1706e6d3 feat(narrativeStudio): add cinematic playback preview fallback diagnostics and polish
c1692b7d feat(narrativeStudio): integrate cinematic actor walking animation renderer and fix actor move destination isolation
f99e235c feat: cinematic actor walking animation frame resolver v1.115
0ed41a86 docs: mise à jour rapports et roadmaps v1.114
a6b197c0 docs: préparation contrat animation marche acteur cinematic v1.114
2dff3a1e feat: cinematic actor playback smooth motion v1.113
d41f7f22 feat: cinematic actor move preview playback v1.112
e41f5874 update selbrume
e9972298 Add cinematic preview transport UI
3411ae0b feat: cinematic preview playback plan read model v1.110
```

Etat dirty initial :

```text
git status --short --untracked-files=all
Sortie : <vide>

git diff --stat
Sortie : <vide>

git diff --name-only
Sortie : <vide>
```

## Regles lues

```text
AGENTS.md : lu
agent_rules.md : lu
codex_rule.md : lu
codex_rules.md : MISSING codex_rules.md
skills/README.md : lu
skills/using-superpowers/SKILL.md : lu
skills/test-driven-development/SKILL.md : lu
skills/verification-before-completion/SKILL.md : lu
```

Contradiction geree :

- `codex_rule.md` demande normalement tests/build pour un lot.
- Le prompt V1-119 interdit explicitement code produit, tests Dart/Flutter nouveaux, packages, screenshots et Visual Gate.
- Interpretation retenue : respecter le scope doc-only strict, ne pas lancer de build package inutile, et verifier par lecture, `git diff --check`, roadmaps et anti-scope.

## Fichiers lus

Rapports playback :

```text
reports/narrativeStudio/scenes/ns_scenes_v1_109_cinematic_preview_playback_prep_contract.md : OK
reports/narrativeStudio/scenes/ns_scenes_v1_110_cinematic_preview_playback_plan_read_model_v0.md : OK
reports/narrativeStudio/scenes/ns_scenes_v1_111_cinematic_preview_playback_transport_ui_v0.md : OK
reports/narrativeStudio/scenes/ns_scenes_v1_112_cinematic_actormove_preview_playback_v0.md : OK
reports/narrativeStudio/scenes/ns_scenes_v1_113_cinematic_actor_playback_smooth_motion_subtile_overlay_polish_v0.md : OK
reports/narrativeStudio/scenes/ns_scenes_v1_116_cinematic_actor_walking_animation_renderer_integration_v0.md : OK
reports/narrativeStudio/scenes/ns_scenes_v1_117_cinematic_actor_animation_cadence_playback_status_polish_v0.md : OK
reports/narrativeStudio/scenes/ns_scenes_v1_117_bis_actor_move_destination_isolation_bugfix_v0.md : OK
reports/narrativeStudio/scenes/ns_scenes_v1_118_cinematic_playback_preview_diagnostics_fallback_detail_polish_v0.md : OK
reports/narrativeStudio/scenes/ns_scenes_v1_118_evidence_pack.md : OK
```

Rapports timeline/probe/transport :

```text
reports/narrativeStudio/scenes/ns_scenes_v1_51_cinematic_timeline_time_axis_bar_layout_v0.md : OK
reports/narrativeStudio/scenes/ns_scenes_v1_52_cinematic_timeline_selection_cursor_playhead_placeholder_v0.md : OK
reports/narrativeStudio/scenes/ns_scenes_v1_53_cinematic_timeline_transport_controls_placeholder_v0.md : OK
reports/narrativeStudio/scenes/ns_scenes_v1_61_cinematic_timeline_mouse_playhead_scrub_prep_contract.md : OK
reports/narrativeStudio/scenes/ns_scenes_v1_62_cinematic_timeline_mouse_time_probe_playhead_drag_v0.md : OK
reports/narrativeStudio/scenes/ns_scenes_v1_63_cinematic_timeline_mouse_probe_polish_boundary_snap_prep_v0.md : OK
reports/narrativeStudio/scenes/ns_scenes_v1_64_cinematic_timeline_mouse_probe_boundary_snap_v0.md : OK
reports/narrativeStudio/scenes/ns_scenes_v1_65_cinematic_timeline_mouse_probe_ux_polish_clear_controls_v0.md : OK
reports/narrativeStudio/scenes/ns_scenes_v1_66_cinematic_timeline_mouse_probe_help_selection_explanation_v0.md : OK
reports/narrativeStudio/scenes/ns_scenes_v1_68_cinematic_timeline_duration_inspector_editing_v0.md : OK
reports/narrativeStudio/scenes/ns_scenes_v1_69_cinematic_timeline_duration_resize_handles_v0.md : OK
reports/narrativeStudio/scenes/ns_scenes_v1_70_cinematic_timeline_duration_validation_diagnostics_polish_v0.md : OK
```

Roadmaps :

```text
reports/narrativeStudio/scenes/road_map_scenes.md : OK
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md : OK
```

Code/tests lus en lecture seule :

```text
packages/map_core/lib/src/read_models/cinematic_preview_playback_plan.dart : OK
packages/map_core/lib/src/read_models/cinematic_timeline_time_layout_read_model.dart : OK
packages/map_core/lib/src/read_models/cinematic_actor_display_preview_model.dart : OK
packages/map_core/lib/src/models/cinematic_asset.dart : OK
packages/map_core/lib/map_core.dart : OK
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart : OK
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart : OK
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_preview_playback_actor_overlay_adapter.dart : OK
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_actor_display_preview_overlay.dart : OK
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_manual_path_preview_overlay.dart : OK
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_viewport_transform.dart : OK
packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart : OK
packages/map_editor/test/cinematic_builder_workspace_test.dart : OK
packages/map_editor/test/cinematics_library_workspace_test.dart : OK
packages/map_core/test/cinematic_preview_playback_plan_test.dart : OK
packages/map_core/test/cinematic_timeline_time_layout_read_model_test.dart : OK
```

## Commandes d'audit executees

### Audit playback/timeline Builder

Commande :

```bash
rg -n "playbackTimeMs|Playback Playhead|Lecture|timelineProbe|Mouse Time Probe|Repère|selectedStepId|Selection|seek|scrub|AnimationController|onTap|onPan|GestureDetector|MouseRegion" packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
```

Sortie utile :

```text
339:  String? _selectedStepId;
340:  int? _timelineProbeTimeMs;
341:  _TimelineProbeSnapHint? _timelineProbeSnapHint;
346:  late final AnimationController _playbackController;
407:  int _playbackTimeMs(CinematicPreviewPlaybackPlan plan) {
462:    final playbackTimeMs = _playbackTimeMs(playbackPlan);
463:    final playbackFrame = playbackPlan.frameAt(playbackTimeMs);
689:                                      _selectedStepId = step.id;
696:                                      _timelineProbeTimeMs = probe.timeMs;
2749:  required int playbackTimeMs,
2791:      ? 'Lecture en cours'
2793:          ? 'Lecture en pause'
3249:    final selectedBlock = _selectedTimeBlock(timeLayout, widget.selectedStepId);
3257:    return GestureDetector(
4194:    return GestureDetector(
4196:      onTapDown: (details) => onTimelineProbeChanged(
4205:      onPanStart: (details) => onTimelineProbeChanged(
4214:      onPanUpdate: (details) => onTimelineProbeChanged(
4332:class _TimelineSelectionCursor extends StatelessWidget {
4435:                        'Lecture',
4478:    final canReturnToStart = canPlay && (playbackTimeMs > 0 || isPlaying);
4607:    return 'Lecture en cours';
4613:    return 'Lecture en pause';
4768:                      onTap: () => onStepSelected(step),
11466:int _timelineProbeTimeMsFromLocalX(
11529:List<_TimelineProbeSnapTarget> _timelineProbeSnapTargets(
```

### Audit layout/snap

Commande :

```bash
rg -n "CinematicTimelineTimeLayoutReadModel|startMs|endMs|visualDurationMs|totalDurationMs|timelineProbe|snap|resize|handle" packages/map_editor/lib/src/ui/canvas/cinematics packages/map_core/lib/src/read_models
```

Sortie utile :

```text
packages/map_core/lib/src/read_models/cinematic_timeline_time_layout_read_model.dart:119:CinematicTimelineTimeLayoutReadModel buildCinematicTimelineTimeLayoutReadModel(
packages/map_core/lib/src/read_models/cinematic_timeline_time_layout_read_model.dart:130:    final startMs = currentMs;
packages/map_core/lib/src/read_models/cinematic_timeline_time_layout_read_model.dart:131:    final endMs = startMs + visualDurationMs;
packages/map_core/lib/src/read_models/cinematic_preview_playback_plan.dart:697:  final clampedTimeMs = timeMs.clamp(0, plan.totalDurationMs).toInt();
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart:2594:const _timelineProbeSnapThresholdPx = 8.0;
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart:4811:  _TimelineDurationResizeDrag? _resizeDrag;
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart:5023:          key: ValueKey('cinematic-builder-duration-resize-handle-$stepId'),
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart:11455:double _timelineContentWidth(int totalDurationMs, double viewportWidth) {
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart:11466:int _timelineProbeTimeMsFromLocalX(
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart:11540:      snapHint: _TimelineProbeSnapHint.timelineStart,
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart:11547:      timeMs: timeLayout.totalDurationMs,
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart:11556:        timeMs: block.startMs,
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart:11564:        timeMs: block.endMs,
```

### Audit tests existants

Commande :

```bash
rg -n "playbackTimeMs|selectedStepId|timelineProbe|ProjectManifest|CinematicAsset|MapData|playhead|Lecture|Repère|seek|scrub" packages/map_editor/test/cinematic_builder_workspace_test.dart packages/map_editor/test/cinematics_library_workspace_test.dart packages/map_core/test/cinematic_preview_playback_plan_test.dart packages/map_core/test/cinematic_timeline_time_layout_read_model_test.dart
```

Sortie utile :

```text
packages/map_editor/test/cinematic_builder_workspace_test.dart:4614:        find.byKey(const ValueKey('cinematic-builder-playback-playhead')),
packages/map_editor/test/cinematic_builder_workspace_test.dart:4617:      expect(find.text('Lecture'), findsWidgets);
packages/map_editor/test/cinematic_builder_workspace_test.dart:4684:      expect(find.text('Lecture en cours'), findsNothing);
packages/map_editor/test/cinematic_builder_workspace_test.dart:11767:      expect(find.text('Lecture en cours'), findsNothing);
packages/map_editor/test/cinematic_builder_workspace_test.dart:12093:    expect(find.text('Lecture en cours'), findsNothing);
packages/map_core/test/cinematic_preview_playback_plan_test.dart:7:      final cinematic = CinematicAsset(
packages/map_core/test/cinematic_timeline_time_layout_read_model_test.dart:100:      final cinematic = CinematicAsset(
```

### Audit roadmaps avant edition

Commande :

```bash
rg -n "Prochain lot exact recommandé|Prochain lot exact recommande|NS-SCENES-V1-119|NS-SCENES-V1-120|NS-SCENES-V1-118" reports/narrativeStudio/scenes/road_map_scenes.md reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
```

Sortie utile :

```text
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md:9:## Prochain lot exact recommande
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md:12:NS-SCENES-V1-119 — Cinematic Preview Playback Scrub / Seek Prep Contract
reports/narrativeStudio/scenes/road_map_scenes.md:186:## Prochain lot exact recommande
reports/narrativeStudio/scenes/road_map_scenes.md:188:`NS-SCENES-V1-119 — Cinematic Preview Playback Scrub / Seek Prep Contract`
```

## Options comparees

- Option A : click-to-seek axe uniquement. Refusee car trop limitee.
- Option B : drag playhead uniquement. Refusee seule car peu ergonomique.
- Option C : click-to-seek axe/fond + drag playhead. Retenue.
- Option D : fusion Mouse Time Probe / Playback Playhead. Refusee pour confusion conceptuelle.
- Option E : scrub partout, y compris barres. Refusee car conflictuel avec selection/resize.

## Decision retenue

```text
Option C — Click-to-seek + drag Playback Playhead controle.
```

Regle structurante :

```text
Selection Cursor = selection auteur.
Mouse Time Probe = inspection-only.
Playback Playhead = temps courant preview et future cible seek/scrub.
```

## Fichiers modifies

```text
reports/narrativeStudio/scenes/road_map_scenes.md
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
```

## Fichiers crees

```text
reports/narrativeStudio/scenes/ns_scenes_v1_119_cinematic_preview_playback_scrub_seek_prep_contract.md
reports/narrativeStudio/scenes/ns_scenes_v1_119_evidence_pack.md
```

## Tests / analyse / build

Tests Dart/Flutter :

```text
Non lances.
Raison : le lot V1-119 est doc-only et interdit les tests nouveaux ainsi que toute modification de package.
```

Analyse Dart/Flutter :

```text
Non lancee.
Raison : aucun fichier Dart/Flutter modifie.
```

Build :

```text
Non lance.
Raison : aucun code produit modifie; validation documentaire par git diff --check et anti-scope.
```

## Git final

Commande :

```bash
git diff --check
```

Sortie :

```text
Sortie : <vide>
```

Commande :

```bash
git diff --stat
```

Sortie :

```text
 .../scenes/road_map_scene_builder_authoring.md     | 35 +++++++++++++------
 reports/narrativeStudio/scenes/road_map_scenes.md  | 40 ++++++++++++++++------
 2 files changed, 54 insertions(+), 21 deletions(-)
```

Commande :

```bash
git diff --name-only
```

Sortie :

```text
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md
```

Commande :

```bash
git status --short --untracked-files=all
```

Sortie :

```text
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_119_cinematic_preview_playback_scrub_seek_prep_contract.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_119_evidence_pack.md
```

Note : `git diff --stat` et `git diff --name-only` ne listent pas les deux rapports V1-119 car ils sont encore non suivis par Git; ils sont visibles dans `git status --short --untracked-files=all`.

## Checks anti-scope

Commande :

```bash
git diff --name-only -- packages/map_core packages/map_editor packages/map_runtime packages/map_gameplay packages/map_battle examples/playable_runtime_host assets selbrume
```

Sortie :

```text
Sortie : <vide>
```

Commande :

```bash
find reports/narrativeStudio/scenes/screenshots -maxdepth 1 -name '*v1_119*' -print
```

Sortie :

```text
Sortie : <vide>
```

Commande :

```bash
find reports/narrativeStudio/scenes/screenshots -maxdepth 1 -name '*v1_120*' -print
```

Sortie :

```text
Sortie : <vide>
```

## Confirmation anti-scope

- Aucun package Dart/Flutter modifie.
- Aucun screenshot cree.
- Aucun runtime ajoute.
- Aucun import Flame ajoute.
- Aucun GameState modifie.
- V1-120 non demarre.

## Verdict

```text
NS-SCENES-V1-119 : DONE documentaire.
Scrub / Seek : contrat cadre.
Selection Cursor : reste selection auteur.
Mouse Time Probe : reste inspection-only.
Playback Playhead : devient futur seek/scrub target.
Runtime / Flame / GameState : non touches.
Aucun code produit modifie.
Aucun screenshot.
V1-120 recommande, non demarre.
```
