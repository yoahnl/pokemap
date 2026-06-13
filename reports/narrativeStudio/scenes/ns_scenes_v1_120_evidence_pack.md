# NS-SCENES-V1-120 — Evidence Pack

## Verdict

```text
NS-SCENES-V1-120 : DONE.
Click-to-seek : actif.
Drag-to-scrub : actif.
Selection Cursor : préservé.
Mouse Time Probe : inspection-only.
Playback Playhead : cible seek/scrub.
Preview frame : mise à jour via plan.frameAt.
ProjectManifest / CinematicAsset / MapData : non mutés.
Runtime / Flame / GameState : non touchés.
map_core : non modifié.
Visual Gate : créée.
V1-121 : Cinematic Fade Preview Playback V0 recommandé, non démarré.
```

## Gate 0 complet

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
Sortie : <vide>
```

```bash
git diff --stat
```

```text
Sortie : <vide>
```

```bash
git diff --name-only
```

```text
Sortie : <vide>
```

```bash
git log --oneline -n 10
```

```text
e87152f2 docs(narrativeStudio): add cinematic preview playback scrub seek prep contract and evidence pack
1706e6d3 feat(narrativeStudio): add cinematic playback preview fallback diagnostics and polish
c1692b7d feat(narrativeStudio): integrate cinematic actor walking animation renderer and fix actor move destination isolation
f99e235c feat: cinematic actor walking animation frame resolver v1.115
0ed41a86 docs: mise à jour rapports et roadmaps v1.114
a6b197c0 docs: préparation contrat animation marche acteur cinematic v1.114
2dff3a1e feat: cinematic actor playback smooth motion v1.113
d41f7f22 feat: cinematic actor move preview playback v1.112
e41f5874 update selbrume
e9972298 Add cinematic preview transport UI
```

Etat dirty initial : aucun. `selbrume/project.json` n'etait pas dirty.

## Regles lues

- `AGENTS.md` ;
- `agent_rules.md` ;
- `codex_rule.md` ;
- `skills/README.md` ;
- `skills/using-superpowers/SKILL.md` ;
- `skills/test-driven-development/SKILL.md` ;
- `skills/verification-before-completion/SKILL.md` ;
- `skills/writing-plans/SKILL.md`.

Absent :

- `codex_rules.md`.

Conflit documente : `codex_rule.md` demande des commentaires, le prompt V1-120 les interdit. Decision : aucun commentaire Dart ajoute.

## Fichiers modifies

```text
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
packages/map_editor/test/cinematic_builder_workspace_test.dart
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md
```

## Fichiers crees

```text
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_120_cinematic_preview_playback_scrub_seek_ui_v0.png
reports/narrativeStudio/scenes/ns_scenes_v1_120_cinematic_preview_playback_scrub_seek_ui_v0.md
reports/narrativeStudio/scenes/ns_scenes_v1_120_evidence_pack.md
```

Pour le PNG binaire, la preuve de contenu est fournie par `file` et `shasum -a 256`.

## Zones modifiees / hunks pertinents

### `cinematic_builder_workspace.dart`

```text
349:  bool _resumePlaybackAfterScrub = false;
438:  void _setPlaybackTimeWithoutSetState(...)
451:  void _seekPlayback(...)
470:  void _beginPlaybackScrub(...)
485:  void _updatePlaybackScrub(...)
498:  void _endPlaybackScrub(...)
513:  void _cancelPlaybackScrub(...)
788:  onPlaybackSeekRequested -> _seekPlayback(...)
791:  onPlaybackScrubStart -> _beginPlaybackScrub(...)
796:  onPlaybackScrubUpdate -> _updatePlaybackScrub(...)
801:  onPlaybackScrubEnd -> _endPlaybackScrub(...)
803:  onPlaybackScrubCancel -> _cancelPlaybackScrub(...)
4342: Semantics label 'Prévisualiser ce moment'
4348: axe temporel onTapUp -> onPlaybackSeekRequested
4541: class _TimelinePlaybackPlayhead extends StatefulWidget
4654: Tooltip 'Glisser pour parcourir'
4656: Semantics label 'Tête de lecture'
4951: fond de piste Semantics 'Prévisualiser ce moment'
4955: fond de piste onTapUp -> onPlaybackSeekRequested
```

Preuve de click-to-seek :

- `_TimelineAxis.onTapUp` appelle `onPlaybackSeekRequested` ;
- `_TimelineTrackRow` background `onTapUp` appelle `onPlaybackSeekRequested` ;
- `_TimelineStepCard` garde sa selection de bloc.

Preuve de drag-to-scrub :

- `_TimelinePlaybackPlayheadState` memorise `_dragStartTimeMs` et `_dragStartGlobalX` ;
- `onHorizontalDragStart/Update/End/Cancel` pilotent les callbacks scrub ;
- la ligne verticale du Playhead est `IgnorePointer`.

### `cinematic_builder_workspace_test.dart`

```text
6769: V1-120 clicking timeline axis seeks playback without changing selection
6844: V1-120 clicking timeline bars keeps selection as the only block action
6878: V1-120 clicking empty timeline background seeks playback
6920: V1-120 dragging playback playhead scrubs actor preview without creating mouse probe
6994: V1-120 dragging playback playhead clamps to timeline bounds
7053: V1-120 dragging playback playhead pauses then resumes active preview
7115: V1-120 clear probe stop and reset keep probe and playback roles separated
7186: V1-120 exposes no-code seek and scrub labels
7229: captures V1-120 cinematic preview playback scrub seek ui visual gate
18273: _playbackTimeMsFromLabel(...)
18290: _placeTimelineProbeAt(...)
```

## Preuves comportementales par tests

Click axe :

```text
V1-120 clicking timeline axis seeks playback without changing selection
```

Prouve :

- temps autour de 500 ms ;
- acteur avance ;
- `selectedStepId` stable ;
- aucun Mouse Time Probe cree ;
- aucune mutation project/asset/mapData.

Click fond vide :

```text
V1-120 clicking empty timeline background seeks playback
```

Prouve :

- temps autour de 2500 ms ;
- selection auteur stable ;
- aucun Mouse Time Probe cree ;
- aucun `onProjectChanged`.

Click barre :

```text
V1-120 clicking timeline bars keeps selection as the only block action
```

Prouve :

- selection du bloc ;
- temps playback reste `0 ms / 3 s` ;
- aucun probe ;
- aucune mutation.

Drag Playhead :

```text
V1-120 dragging playback playhead scrubs actor preview without creating mouse probe
V1-120 dragging playback playhead clamps to timeline bounds
V1-120 dragging playback playhead pauses then resumes active preview
```

Prouve :

- scrub vers 500 ms ;
- acteur avance ;
- clamp a 0 et totalDurationMs ;
- pause pendant drag en lecture active ;
- reprise apres release ;
- aucun probe cree.

Mouse Time Probe :

```text
V1-120 clear probe stop and reset keep probe and playback roles separated
```

Prouve :

- clear probe ne reset pas playback ;
- Stop/Reset reset playback mais ne clear pas probe ;
- roles `Repère` et `Lecture` restent distincts.

Non-mutation :

Les tests V1-120 utilisent :

```text
expect(projectChangeCount, 0)
expect(project.toJson(), beforeProject/before)
expect(asset.toJson(), beforeAsset)
expect(mapData.toJson(), beforeMapData)
```

## Tests RED exacts

Commande initiale :

```bash
cd packages/map_editor
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --name "V1-120"
```

Sortie RED observee avant implementation :

```text
Expected playback time around 500 ms after axis click, but the label stayed at 0 ms / 1 s.
Expected actor preview anchor to move after scrub, but the anchor stayed at the initial position.
The active preview resume expectation was not yet satisfied before the drag implementation.
Exit code: 1
```

Corrections de tests pendant durcissement :

```text
Expected: <0>
Actual: <3000>
Test: V1-120 dragging playback playhead clamps to timeline bounds
Correction: repositionner le handle a 1000 ms avant le drag gauche.
```

```text
A SemanticsHandle was active at the end of the test.
Test: V1-120 exposes no-code seek and scrub labels
Correction: inspecter les widgets Semantics directement.
```

## Sorties exactes tests map_editor

```bash
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --name "V1-120"
```

```text
00:08 +9: All tests passed!
```

```bash
flutter test --reporter=compact --update-goldens --dart-define=NS_SCENES_V1_120_CAPTURE_CINEMATIC_PREVIEW_PLAYBACK_SCRUB_SEEK_UI=true test/cinematic_builder_workspace_test.dart --plain-name "captures V1-120 cinematic preview playback scrub seek ui visual gate"
```

```text
00:03 +1: All tests passed!
```

```bash
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --name "V1-118"
```

```text
00:03 +4: All tests passed!
```

```bash
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --name "V1-117"
```

```text
00:04 +7: All tests passed!
```

```bash
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --name "V1-117-bis"
```

```text
00:02 +1: All tests passed!
```

```bash
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --name "V1-116"
```

```text
00:04 +4: All tests passed!
```

```bash
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart
```

```text
00:46 +245: All tests passed!
```

```bash
flutter test --reporter=compact test/cinematics_library_workspace_test.dart test/cinematic_stage_point_preview_overlay_test.dart
```

```text
00:07 +26: All tests passed!
```

```bash
flutter test --reporter=compact test/cinematic_playback_preview_fallback_summary_test.dart
```

```text
00:01 +5: All tests passed!
```

## Sorties exactes tests map_core

```bash
dart test --reporter=compact test/cinematic_preview_playback_plan_test.dart
```

```text
00:00 +12: All tests passed!
```

```bash
dart test --reporter=compact test/cinematic_timeline_time_layout_read_model_test.dart
```

```text
00:00 +4: All tests passed!
```

```bash
dart test --reporter=compact test/cinematic_actor_display_preview_model_test.dart
```

```text
00:00 +27: All tests passed!
```

## Analyse et build

```bash
cd packages/map_core
dart analyze
```

```text
Analyzing map_core...
No issues found!
```

```bash
cd packages/map_editor
flutter analyze --no-fatal-infos lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart test/cinematic_builder_workspace_test.dart test/cinematics_library_workspace_test.dart
```

```text
Analyzing 4 items...
37 issues found. (ran in 2.1s)
Exit code: 0
```

Les 37 issues sont des infos `prefer_const_*`, non fatales avec `--no-fatal-infos`.

```bash
flutter build macos --debug
```

```text
Building macOS application...
✓ Built build/macos/Build/Products/Debug/map_editor.app
```

## Visual Gate

```bash
ls -lh reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_120_cinematic_preview_playback_scrub_seek_ui_v0.png
```

```text
-rw-r--r--  1 karim  staff   225K Jun 13 21:12 reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_120_cinematic_preview_playback_scrub_seek_ui_v0.png
```

```bash
file reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_120_cinematic_preview_playback_scrub_seek_ui_v0.png
```

```text
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_120_cinematic_preview_playback_scrub_seek_ui_v0.png: PNG image data, 1663 x 926, 8-bit/color RGBA, non-interlaced
```

```bash
shasum -a 256 reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_120_cinematic_preview_playback_scrub_seek_ui_v0.png
```

```text
dc8726bc6a8fc3143e1d7552025a9412d643da91952bf15d2535ff9d7273a2f8  reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_120_cinematic_preview_playback_scrub_seek_ui_v0.png
```

## Roadmaps

Roadmaps mises a jour :

- `road_map_scenes.md` : V1-120 DONE, V1-121 recommande ;
- `road_map_scene_builder_authoring.md` : V1-120 DONE, V1-121 recommande.

Verification intermediaire :

```bash
rg -n "Prochain lot exact recommande|Prochain lot exact recommandé|NS-SCENES-V1-120 — Cinematic Preview Playback Scrub / Seek UI V0|NS-SCENES-V1-121 — Cinematic Fade Preview Playback V0" reports/narrativeStudio/scenes/road_map_scenes.md reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
```

```text
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md:9:## Prochain lot exact recommande
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md:12:NS-SCENES-V1-121 — Cinematic Fade Preview Playback V0
reports/narrativeStudio/scenes/road_map_scenes.md:188:## Prochain lot exact recommande
reports/narrativeStudio/scenes/road_map_scenes.md:190:`NS-SCENES-V1-121 — Cinematic Fade Preview Playback V0`
```

## Incident de runner documente

Une tentative intermediaire a lance plusieurs commandes Flutter en parallele. Deux executions ont echoue sur des erreurs de build/cache natives (`NativeAssetsManifest` / `objective_c.dylib`) dues a la concurrence de runner, pas au code produit. Les commandes ont ensuite ete relancees sequentiellement et sont passees.

## Checks finaux

Les commandes finales ci-dessous doivent rester la source de cloture apres creation de ce pack.

```bash
git diff --check
```

```text
Sortie : <vide>
```

```bash
git diff --stat
```

```text
 .../cinematics/cinematic_builder_workspace.dart    | 576 +++++++++++++-----
 .../test/cinematic_builder_workspace_test.dart     | 676 ++++++++++++++++++++-
 .../scenes/road_map_scene_builder_authoring.md     |  37 +-
 reports/narrativeStudio/scenes/road_map_scenes.md  |  42 +-
 4 files changed, 1117 insertions(+), 214 deletions(-)
```

```bash
git diff --name-only
```

```text
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
packages/map_editor/test/cinematic_builder_workspace_test.dart
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md
```

```bash
git status --short --untracked-files=all
```

```text
 M packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
 M packages/map_editor/test/cinematic_builder_workspace_test.dart
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_120_cinematic_preview_playback_scrub_seek_ui_v0.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_120_evidence_pack.md
?? reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_120_cinematic_preview_playback_scrub_seek_ui_v0.png
```

```bash
git diff --unified=0 | rg -n "package:flame|GameState|PlayableMapGame|SceneRuntimeExecutor|CinematicRuntimeAdapter|map_runtime|map_gameplay|Timer\\.periodic|Future\\.delayed|Stream\\.periodic|DateTime\\.now|RouteSegment|pathfinding|collision|V1-121" || true
```

```text
1332:+NS-SCENES-V1-121 — Cinematic Fade Preview Playback V0
1334:+| NS-SCENES-V1-120 | Cinematic Preview Playback Scrub / Seek UI V0 | editor / preview-sandbox | Implémenter le click-to-seek sur axe/fond vide et le drag-to-scrub du Playback Playhead dans le Cinematic Builder, en gardant Selection Cursor, Mouse Time Probe et Playback Playhead séparés. | Pas de V1-121, fade preview, runtime, Flame, GameState, map_core, pathfinding, collision, persistance playbackTimeMs, mutation projet ou nouveau moteur playback. | `cinematic_builder_workspace.dart`, tests Builder, Visual Gate, rapport, Evidence Pack, roadmaps. | Tests V1-120, regressions V1-118/V1-117/V1-117-bis/V1-116, Builder complet, Library/overlay, fallback summary, core ciblé, analyse ciblée, build macOS debug. | Fusionner Repère et Lecture ; faire seeker les barres ; muter les données projet ; rendre le drag fragile en lecture active. | DONE : click-to-seek axe/fond, barres selection-only, drag `Lecture`, preview acteur/animation mise à jour, non-mutation et anti-scope confirmés. | V1-119 |
1344:+Limites : aucun fade preview, runtime, Flame, GameState, map_core, pathfinding, collision ou V1-121 n'a ete demarre. La capture reste issue du harness test.
1346:+Prochain lot recommande : `NS-SCENES-V1-121 — Cinematic Fade Preview Playback V0`.
1352:+Suite historique : V1-120 a ete realise ; le prochain lot global actuel est `NS-SCENES-V1-121 — Cinematic Fade Preview Playback V0`.
1355:+Suite historique : V1-119 a ete realise en documentaire ; V1-120 a ete realise ; le prochain lot global actuel est `NS-SCENES-V1-121 — Cinematic Fade Preview Playback V0`.
1358:+Suite historique : V1-118 a ete realise ; V1-119 a ete realise ; V1-120 a ete realise ; le prochain lot global actuel est `NS-SCENES-V1-121 — Cinematic Fade Preview Playback V0`.
1361:+Suite historique : V1-118 a ete realise ; V1-119 a ete realise ; V1-120 a ete realise ; le prochain lot global actuel est `NS-SCENES-V1-121 — Cinematic Fade Preview Playback V0`.
1364:+Suite historique : V1-117 puis V1-118 ont ete realises ; V1-119 a ete realise ; V1-120 a ete realise ; le prochain lot global actuel est `NS-SCENES-V1-121 — Cinematic Fade Preview Playback V0`.
1367:+Suite historique : V1-116, V1-117 et V1-118 ont ete realises ; V1-119 a ete realise ; V1-120 a ete realise ; le prochain lot global actuel est `NS-SCENES-V1-121 — Cinematic Fade Preview Playback V0`.
1370:+Suite historique : V1-116, V1-117 et V1-118 ont ete realises ; V1-119 a ete realise ; V1-120 a ete realise ; le prochain lot global actuel est `NS-SCENES-V1-121 — Cinematic Fade Preview Playback V0`.
1373:+Suite historique : V1-114, V1-115, V1-116, V1-117 et V1-118 ont ete realises ; V1-119 a ete realise ; V1-120 a ete realise ; le prochain lot global actuel est `NS-SCENES-V1-121 — Cinematic Fade Preview Playback V0`.
1376:+Historique avant V1-113 : V1-112 recommandait de corriger la précision visuelle du playback acteur. Cette limite a ete traitée par V1-113 ; la suite historique V1-114 a ete realisee, puis V1-115, V1-116, V1-117 et V1-118 ont ferme la chaîne d'animation preview actuelle. V1-119 a ete realise ; V1-120 a ete realise ; le prochain lot global actuel est `NS-SCENES-V1-121 — Cinematic Fade Preview Playback V0`.
1379:+Limites historiques au moment de V1-111 : actor overlay playback non démarré ; aucun scrubber, seek, runtime, Flame, GameState ou persistance. Cette limite a ete traitée par V1-112, puis la fluidité sub-tile par V1-113 ; la suite historique V1-114 a ete realisee, puis V1-115, V1-116, V1-117 et V1-118 ont ferme la chaîne d'animation preview actuelle. V1-119 a ete realise ; V1-120 a ete realise ; le prochain lot global actuel est `NS-SCENES-V1-121 — Cinematic Fade Preview Playback V0`.
1385:+| NS-SCENES-V1-120 — Cinematic Preview Playback Scrub / Seek UI V0 | DONE | Implémenter le click-to-seek sur axe/fond vide et le drag-to-scrub du Playback Playhead dans le Cinematic Builder, en gardant Selection Cursor, Mouse Time Probe et Playback Playhead séparés, sans mutation projet, runtime, Flame, GameState ni map_core. |
1388:+`NS-SCENES-V1-121 — Cinematic Fade Preview Playback V0`
1391:+Raison : V1-120 a livre le seek/scrub preview editor-only. Le prochain verrou naturel est de faire prévisualiser les blocs Fondu pendant la lecture locale, sans runtime, Flame, GameState, map_core, nouvelle interpolation acteur ou mutation de projet.
1395:+22. `NS-SCENES-V1-121 — Cinematic Fade Preview Playback V0` (recommande, non demarre)
1407:+Limites : la Visual Gate reste une capture de harness test. Les IDs techniques encore présents dans les métadonnées historiques ne sont pas le workflow principal du seek/scrub. Aucun fade playback, runtime, Flame, GameState, map_core, pathfinding, collision ou V1-121 n'a ete demarre.
1409:+Prochain lot recommande : `NS-SCENES-V1-121 — Cinematic Fade Preview Playback V0`.
1415:+Suite historique : V1-120 a ete realise ; le prochain lot global actuel est `NS-SCENES-V1-121 — Cinematic Fade Preview Playback V0`.
1418:+Suite historique : V1-119 a ete realise en documentaire ; V1-120 a ete realise ; le prochain lot global actuel est `NS-SCENES-V1-121 — Cinematic Fade Preview Playback V0`.
1421:+Suite historique : V1-118 a ete realise ; V1-119 a ete realise ; V1-120 a ete realise ; le prochain lot global actuel est `NS-SCENES-V1-121 — Cinematic Fade Preview Playback V0`.
1424:+Suite historique : V1-118 a ete realise ; V1-119 a ete realise ; V1-120 a ete realise ; le prochain lot global actuel est `NS-SCENES-V1-121 — Cinematic Fade Preview Playback V0`.
1427:+Suite historique : V1-117 puis V1-118 sont realises ; V1-119 a ete realise ; V1-120 a ete realise ; le prochain lot global actuel est `NS-SCENES-V1-121 — Cinematic Fade Preview Playback V0`.
1430:+Suite historique : V1-116, V1-117 et V1-118 ont ete realises ; V1-119 a ete realise ; V1-120 a ete realise ; le prochain lot global actuel est `NS-SCENES-V1-121 — Cinematic Fade Preview Playback V0`.
1433:+Suite historique : V1-116, V1-117 et V1-118 ont ete realises ; V1-119 a ete realise ; V1-120 a ete realise ; le prochain lot global actuel est `NS-SCENES-V1-121 — Cinematic Fade Preview Playback V0`.
1436:+Suite historique : V1-114, V1-115, V1-116, V1-117 et V1-118 ont ete realises ; V1-119 a ete realise ; V1-120 a ete realise ; le prochain lot global actuel est `NS-SCENES-V1-121 — Cinematic Fade Preview Playback V0`.
1439:+Limites historiques au moment de V1-111 : aucun actor overlay playback n'était branché ; aucun scrubber, seek timeline, runtime, Flame, GameState, pathfinding, collision, animation de marche ou persistance du temps n'avait été ajouté. Le branchement acteur a été traité par V1-112, puis la fluidité sub-tile par V1-113 ; la suite historique V1-114 a ete realisee, puis V1-115, V1-116, V1-117 et V1-118 ont ferme la chaîne d'animation preview actuelle. V1-119 a ete realise ; V1-120 a ete realise ; le prochain lot global actuel est `NS-SCENES-V1-121 — Cinematic Fade Preview Playback V0`.

Interpretation : sortie documentaire uniquement dans les roadmaps ; aucune occurrence dans le code produit ajoute.
```

```bash
rg -n "playbackTimeMs|seek|scrub|frameAt|activeStepIds|timelineItem|runtime|probe" packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart || true
```

```text
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart:410:  int _playbackTimeMs(CinematicPreviewPlaybackPlan plan) {
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart:451:  void _seekPlayback(
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart:545:    final playbackFrame = playbackPlan.frameAt(playbackTimeMs);
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart:776:                                  onTimelineProbeChanged: (probe) {
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart:4659:                    'Temps de lecture ${_shortTimeLabel(widget.playbackTimeMs)}',
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart:4880:  return plan.totalDurationMs > 0 && plan.timelineItems.isNotEmpty;

Interpretation : occurrences internes/cles de test/helper. Le label visible `runtime` a ete retire du Builder (`Statut lecture` remplace `Statut runtime`) et le test V1-120 verifie `find.textContaining('runtime') == findsNothing`.
```

```bash
git diff --name-only -- packages/map_core packages/map_runtime packages/map_gameplay packages/map_battle examples/playable_runtime_host assets selbrume
```

```text
Sortie : <vide>
```

```bash
find reports/narrativeStudio/scenes/screenshots -maxdepth 1 -name '*v1_121*' -print
```

```text
Sortie : <vide>
```

## Confirmation anti-scope

- Aucun `packages/map_core` modifie.
- Aucun `packages/map_runtime` modifie.
- Aucun `packages/map_gameplay` modifie.
- Aucun `packages/map_battle` modifie.
- Aucun `examples/playable_runtime_host` modifie.
- Aucun `assets` modifie.
- Aucun `selbrume` modifie.
- Aucun screenshot V1-121 cree.
- V1-121 recommande, non demarre.
