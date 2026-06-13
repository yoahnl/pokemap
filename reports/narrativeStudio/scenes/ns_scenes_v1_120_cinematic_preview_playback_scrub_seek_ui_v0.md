# NS-SCENES-V1-120 — Cinematic Preview Playback Scrub / Seek UI V0

## Resume executif

Statut : **DONE**.

V1-120 implemente le seek/scrub preview-only du Cinematic Builder :

- clic sur l'axe temporel : deplace la lecture ;
- clic sur le fond vide d'une piste : deplace la lecture ;
- clic sur une barre : conserve le comportement de selection du bloc, sans seek ;
- drag du Playback Playhead `Lecture` : scrubbe la preview ;
- drag pendant Play : pause pendant le drag puis reprend au release si la lecture etait active ;
- `Selection Cursor`, `Mouse Time Probe` et `Playback Playhead` restent separes ;
- aucune mutation de `ProjectManifest`, `CinematicAsset`, `MapData`, manual paths ou destinations actorMove ;
- aucun runtime, Flame, GameState, map_core, pathfinding, collision ou V1-121.

Visual Gate :

```text
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_120_cinematic_preview_playback_scrub_seek_ui_v0.png
```

Prochain lot recommande, non demarre :

```text
NS-SCENES-V1-121 — Cinematic Fade Preview Playback V0
```

## Gate 0

Commandes initiales capturees avant implementation :

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

Etat dirty initial : aucun fichier dirty, aucun `selbrume/project.json` dirty.

## Regles lues

Fichiers lus et appliques :

- `AGENTS.md` ;
- `agent_rules.md` ;
- `codex_rule.md` ;
- `skills/README.md` ;
- `skills/using-superpowers/SKILL.md` ;
- `skills/test-driven-development/SKILL.md` ;
- `skills/verification-before-completion/SKILL.md` ;
- `skills/writing-plans/SKILL.md`.

Fichier attendu absent :

- `codex_rules.md`.

Conflit detecte : `codex_rule.md` demande d'ajouter un maximum de commentaires utiles, mais le prompt V1-120 interdit explicitement tout commentaire dans le code. J'ai suivi le prompt V1-120, plus specifique pour ce lot : aucun commentaire Dart n'a ete ajoute.

## Fichiers lus

Rapports recents lus : V1-109, V1-110, V1-111, V1-112, V1-113, V1-116, V1-117, V1-117-bis, V1-118, V1-119 et Evidence Pack V1-119.

Rapports timeline/probe/transport lus : V1-51, V1-52, V1-53, V1-61, V1-62, V1-63, V1-64, V1-65, V1-66, V1-68, V1-69, V1-70.

Fichiers core lus en lecture seule :

- `packages/map_core/lib/src/read_models/cinematic_preview_playback_plan.dart` ;
- `packages/map_core/lib/src/read_models/cinematic_timeline_time_layout_read_model.dart` ;
- `packages/map_core/lib/src/read_models/cinematic_actor_display_preview_model.dart` ;
- `packages/map_core/lib/src/models/cinematic_asset.dart` ;
- `packages/map_core/lib/map_core.dart`.

Fichiers editor lus :

- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart` ;
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart` ;
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_preview_playback_actor_overlay_adapter.dart` ;
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_actor_display_preview_overlay.dart` ;
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_manual_path_preview_overlay.dart` ;
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_viewport_transform.dart` ;
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart` ;
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_playback_preview_fallback_summary.dart`.

Tests lus :

- `packages/map_editor/test/cinematic_builder_workspace_test.dart` ;
- `packages/map_editor/test/cinematics_library_workspace_test.dart` ;
- `packages/map_editor/test/cinematic_stage_point_preview_overlay_test.dart` ;
- `packages/map_editor/test/cinematic_playback_preview_fallback_summary_test.dart` ;
- `packages/map_core/test/cinematic_preview_playback_plan_test.dart` ;
- `packages/map_core/test/cinematic_timeline_time_layout_read_model_test.dart` ;
- `packages/map_core/test/cinematic_actor_display_preview_model_test.dart`.

## Rappel V1-119

V1-119 a retenu `Option C — Click-to-seek + drag Playback Playhead controle`.

Separation non negociable :

- `Selection Cursor` : bloc inspecte/edite ;
- `Mouse Time Probe` : repere temporel local d'inspection ;
- `Playback Playhead` : temps courant de lecture preview.

La hierarchie de hit-test gardee par V1-120 :

1. TextField / controles / boutons ;
2. Resize handle ;
3. Timeline bar ;
4. Playback Playhead handle ;
5. Timeline axis ;
6. Timeline background vide ;
7. Mouse Time Probe existant.

## Decision d'implementation

Le seek/scrub reste entierement local au Builder :

- le controller playback existant reste la seule source locale de temps ;
- aucune nouvelle boucle `Timer.periodic`, `Future.delayed`, `Stream.periodic` ou `DateTime.now` ;
- aucun second moteur playback ;
- aucun changement `map_core`.

## Etat local playback / controller

Zones modifiees :

- `_setPlaybackTimeWithoutSetState` ;
- `_seekPlayback` ;
- `_beginPlaybackScrub` ;
- `_updatePlaybackScrub` ;
- `_endPlaybackScrub` ;
- `_cancelPlaybackScrub` ;
- `_resumePlaybackAfterScrub`.

Impact :

- seek en pause : met a jour la frame et reste en pause ;
- seek en lecture : repositionne et continue ;
- scrub en pause : met a jour la frame et reste en pause ;
- scrub en lecture : pause pendant le drag, reprend au release ;
- Stop/Reset remettent le temps a zero sans changer la selection ni le probe.

## Conversion timeline -> temps

Le code reutilise le layout existant :

- `CinematicTimelineTimeLayoutReadModel` ;
- `playbackPlan.totalDurationMs` ;
- `timeLayout.blocks` ;
- `_timelineContentWidth(...)` ;
- `_resolveTimelineProbeSnap(...)`.

Le resultat du snap est transmis au playback, sans ecrire dans `_timelineProbeTimeMs`.

## Snapping

Snap V0 conserve :

- 0 ms ;
- totalDurationMs ;
- block.startMs ;
- block.endMs.

Le seuil reste celui du probe existant. Aucun snap aux ticks, frames d'animation, waypoints, collisions ou runtime.

## Click-to-seek

Zones modifiees :

- `_TimelineAxis` : `onTapUp` appelle `onPlaybackSeekRequested` ;
- `_TimelineTrackRow` background : `onTapUp` appelle `onPlaybackSeekRequested` ;
- `_TimelineStepCard` reste prioritaire pour la selection.

Preuve test :

- `V1-120 clicking timeline axis seeks playback without changing selection` ;
- `V1-120 clicking empty timeline background seeks playback` ;
- `V1-120 clicking timeline bars keeps selection as the only block action`.

## Drag-to-scrub

Zones modifiees :

- `_TimelinePlaybackPlayhead` devient stateful ;
- le handle `Lecture` capture les drags horizontaux ;
- la ligne verticale est en `IgnorePointer`, donc elle n'intercepte plus le Mouse Time Probe ;
- `onHorizontalDragDown` memorise le vrai point de depart pour eviter l'ecart du seuil de drag Flutter.

Preuve test :

- `V1-120 dragging playback playhead scrubs actor preview without creating mouse probe` ;
- `V1-120 dragging playback playhead clamps to timeline bounds` ;
- `V1-120 dragging playback playhead pauses then resumes active preview`.

## Comportement pendant Play

Au debut du drag :

- la lecture active est memorisee ;
- le controller est stoppe localement ;
- le statut visible devient `Lecture en pause`.

Au release :

- la lecture reprend uniquement si elle etait active avant le drag et si le temps n'est pas a la fin.

Preuve :

```text
V1-120 dragging playback playhead pauses then resumes active preview
```

## Comportement pendant Pause

Un seek ou un scrub met a jour la frame preview, l'acteur et le playhead, mais garde `Lecture en pause`.

Preuve :

```text
V1-120 clicking timeline axis seeks playback without changing selection
V1-120 dragging playback playhead scrubs actor preview without creating mouse probe
```

## Stop / Reset

Stop/Reset :

- `isPlaybackPlaying = false` ;
- temps local remis a 0 ;
- selection auteur preservee ;
- Mouse Time Probe preserve.

Preuve :

```text
V1-120 clear probe stop and reset keep probe and playback roles separated
```

## Selection Cursor

Le seek ne change pas `selectedStepId`.

Preuve :

- l'inspecteur reste sur `move_direct` apres seek axe ;
- la selection `step_face` reste selectionnee apres seek fond vide ;
- le clic barre selectionne `step_face` et ne modifie pas le temps playback.

## Mouse Time Probe

Le probe reste inspection-only :

- un click-to-seek ne cree pas de `time-probe-cursor` ;
- un drag du Playhead ne cree pas de probe ;
- clear probe ne reset pas le playback time ;
- Stop/Reset ne clear pas le probe ;
- les interactions probe existantes utilisent toujours le drag souris via `_placeTimelineProbeAt` dans les tests.

## Preview update actor / animation / fallbacks

Le seek/scrub met a jour la preview via le plan existant et les couches V1-112 a V1-118 :

- actor position depuis `plan.frameAt(...)` ;
- frame d'animation via le renderer/resolver deja branche ;
- fallback details V1-118 conserves.

Preuves :

- ancrage acteur Lysa avance apres seek/scrub dans les tests V1-120 ;
- regressions V1-118, V1-117, V1-116 relancees et vertes.

## Wording / semantics / accessibilite

Labels visibles/no-code :

- `Lecture` ;
- `Prévisualiser ce moment` ;
- `Lire depuis ce moment` ;
- `Glisser pour parcourir` ;
- `Tête de lecture` ;
- `Déplacer la lecture` ;
- `Temps de lecture`.

Test :

```text
V1-120 exposes no-code seek and scrub labels
```

Labels interdits absents du workflow principal :

- `playbackTimeMs` ;
- `seek` ;
- `scrub` ;
- `frameAt` ;
- `activeStepIds` ;
- `timelineItem` ;
- `probe` ;
- `runtime`.

Limite honnete : la capture de harness montre encore des IDs/metadonnees historiques dans l'inspecteur (`move_direct`, `actorMove`, metadata). Ce n'est pas le workflow principal du seek/scrub, mais ce n'est pas encore une UI finale 100% no-code pour toutes les sections de l'inspecteur.

## Non-mutation

Tests V1-120 comparent les snapshots JSON avant/apres :

- `project.toJson()` ;
- `asset.toJson()` ;
- `mapData.toJson()`.

Ils couvrent la non-mutation de `ProjectManifest`, `CinematicAsset`, `MapData`, manual paths et destinations actorMove pour les fixtures concernees. Aucun `onProjectChanged` n'est appele par seek/scrub.

## Non-objectifs confirmes

Non demarres :

- V1-121 ;
- fade preview ;
- camera preview ;
- runtime cinematic playback ;
- Flame ;
- PlayableMapGame ;
- GameState ;
- SceneRuntimeExecutor ;
- CinematicRuntimeAdapter ;
- map_runtime ;
- map_gameplay ;
- pathfinding ;
- collision ;
- route recalculation ;
- manual path recalculation ;
- nouveau playback engine ;
- persistance `playbackTimeMs` ;
- mutation Selbrume ;
- changement `map_core`.

## Hygiene de diff

Fichiers modifies :

- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart` : implementation locale seek/scrub et callbacks timeline ;
- `packages/map_editor/test/cinematic_builder_workspace_test.dart` : tests RED/GREEN V1-120, helpers de test probe/playback ;
- `reports/narrativeStudio/scenes/road_map_scenes.md` : V1-120 DONE, V1-121 recommande ;
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md` : V1-120 DONE, V1-121 recommande.

Fichiers crees :

- `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_120_cinematic_preview_playback_scrub_seek_ui_v0.png` ;
- `reports/narrativeStudio/scenes/ns_scenes_v1_120_cinematic_preview_playback_scrub_seek_ui_v0.md` ;
- `reports/narrativeStudio/scenes/ns_scenes_v1_120_evidence_pack.md`.

Confirmation :

- aucun reformat global lance ;
- aucune modification `map_core`, `map_runtime`, `map_gameplay`, `map_battle`, `examples`, `assets`, `selbrume` ;
- aucun commentaire Dart ajoute, conformement au prompt V1-120.

## Tests RED

Tests ajoutes avant implementation et observes rouges :

```bash
cd packages/map_editor
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --name "V1-120"
```

Sortie RED observee :

```text
Expected playback time around 500 ms after axis click, but the label stayed at 0 ms / 1 s.
Expected actor preview anchor to move after scrub, but the anchor stayed at the initial position.
The active preview resume expectation was not yet satisfied before the drag implementation.
Exit code: 1
```

Pendant le durcissement des tests, deux erreurs de tests ont aussi ete corrigees :

```text
V1-120 dragging playback playhead clamps to timeline bounds
Expected: <0>
Actual: <3000>
Cause: test started the second drag while the handle was clipped at the right edge.
Correction: repositionner le playhead a 1000 ms avant de tester le clamp gauche.
```

```text
V1-120 exposes no-code seek and scrub labels
A SemanticsHandle was active at the end of the test.
Correction: verifier les widgets Semantics directement sans ensureSemantics().
```

## Tests GREEN

Tests V1-120 presents :

- `V1-120 clicking timeline axis seeks playback without changing selection` ;
- `V1-120 clicking timeline bars keeps selection as the only block action` ;
- `V1-120 clicking empty timeline background seeks playback` ;
- `V1-120 dragging playback playhead scrubs actor preview without creating mouse probe` ;
- `V1-120 dragging playback playhead clamps to timeline bounds` ;
- `V1-120 dragging playback playhead pauses then resumes active preview` ;
- `V1-120 clear probe stop and reset keep probe and playback roles separated` ;
- `V1-120 exposes no-code seek and scrub labels` ;
- `captures V1-120 cinematic preview playback scrub seek ui visual gate`.

## Tests executes

```bash
cd packages/map_editor
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

Depuis `packages/map_core` :

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

## Analyse statique

Depuis `packages/map_core` :

```bash
dart analyze
```

```text
Analyzing map_core...
No issues found!
```

Depuis `packages/map_editor` :

```bash
flutter analyze --no-fatal-infos lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart test/cinematic_builder_workspace_test.dart test/cinematics_library_workspace_test.dart
```

```text
Analyzing 4 items...
37 issues found. (ran in 2.1s)
Exit code: 0
```

Nature des issues : uniquement des infos `prefer_const_constructors` / `prefer_const_literals_to_create_immutables`, non fatales avec `--no-fatal-infos`. Elles existaient dans des zones historiques et ne bloquent pas V1-120.

## Build macOS debug

Depuis `packages/map_editor` :

```bash
flutter build macos --debug
```

```text
Building macOS application...
✓ Built build/macos/Build/Products/Debug/map_editor.app
```

## Visual Gate

Capture :

```text
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_120_cinematic_preview_playback_scrub_seek_ui_v0.png
```

Verification visuelle : Cinematic Builder ouvert, timeline visible, Playback Playhead `Lecture` a 502 ms, preview visible, acteur Lysa visible a une position avancee, transport visible, statut `Lecture en pause`, Selection Cursor distinct, aucun Mouse Time Probe cree par le seek standard, aucun label runtime/Flame/GameState/V1-121.

Commandes :

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

## Checks anti-scope

Les checks finaux complets sont reproduits dans l'Evidence Pack. Points clefs :

- aucun fichier sous `packages/map_core`, `packages/map_runtime`, `packages/map_gameplay`, `packages/map_battle`, `examples/playable_runtime_host`, `assets`, `selbrume` n'est modifie ;
- aucun screenshot V1-121 cree ;
- les occurrences `V1-121` sont documentaires dans les rapports/roadmaps ;
- les termes techniques `seek/scrub/probe/playbackTimeMs` restent des identifiants de code/test, pas des labels visibles principaux.

## Roadmaps mises a jour

- `reports/narrativeStudio/scenes/road_map_scenes.md` : V1-120 ajoute comme DONE, prochain lot global V1-121 ;
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md` : V1-120 ajoute comme DONE, prochain lot global V1-121.

## Git final

Les sorties finales exactes apres creation des rapports sont dans l'Evidence Pack V1-120.

## Sub-agents / passes

- Sub-agent Audit / Architecture : PASS. V1-120 est coherent avec V1-119 et ne requiert pas de changement `map_core`.
- Sub-agent Implementation : PASS. Implementation locale au Builder, pas de runtime, pas de second moteur playback.
- Sub-agent Tests : PASS. RED observe, V1-120 vert, regressions V1-118/V1-117/V1-117-bis/V1-116 vertes, Builder complet vert.
- Sub-agent Build / Validation : PASS. `dart analyze` map_core vert, analyse ciblee map_editor sortie 0 avec infos non fatales, build macOS debug vert.
- Sub-agent Critique finale : PASS avec limites notees ci-dessous.

## Risques restants

- Le click-to-seek est accessible via tooltip/semantics, mais il pourrait beneficier plus tard d'une affordance visuelle plus explicite.
- Le handle `Lecture` est confortable en test, mais son confort tactile reel sur trackpad/souris doit etre revalide en usage long.
- Le Mouse Time Probe reste disponible par drag ; l'ancienne interaction de simple clic sur axe est maintenant le seek standard, ce qui est volontaire dans V1-120 mais peut meriter un rappel UX.
- La capture de harness affiche encore des IDs/metadonnees historiques dans l'inspecteur.

## Auto-critique

- Decouvrabilite click-to-seek : correcte mais discrete ; pas de bis obligatoire, mais un polish futur pourrait rendre l'axe plus explicite.
- Confort drag playhead : le hit target est plus large que la ligne et le label `Lecture` aide ; usage reel a verifier.
- Separation Selection / Repere / Lecture : preservee par tests ; le fait que le probe soit maintenant plutot un drag que le clic standard est a surveiller.
- Comportement pendant Play : un peu subtil, mais teste et coherent avec V1-119.
- Flakiness controller : tests evitent les attentes longues sauf regressions existantes ; V1-120 utilise surtout seek direct et drags bornes.
- Preservation Mouse Probe : couverte par tests anciens et V1-120.
- Bis recommande : non, sauf si Karim souhaite ensuite une meilleure affordance visuelle du seek ou une UI inspecteur moins technique.

## Verdict final

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

