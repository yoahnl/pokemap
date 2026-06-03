# NS-SCENES-V1-62 — Cinematic Timeline Mouse Time Probe / Playhead Drag V0

Date : 2026-06-03  
Statut : DONE  
Lot precedent : `NS-SCENES-V1-61 — Cinematic Timeline Mouse Playhead / Scrub Prep Contract`  
Prochain lot recommande : `NS-SCENES-V1-63 — Cinematic Timeline Mouse Probe Polish / Boundary Snap Prep V0`

## 1. Resume executif

V1-62 rend le repere temporel de la timeline cinematic deplacable a la souris. Le Cinematic Builder accepte maintenant un click ou un drag sur l'axe/fond temporel, convertit la position X en temps local, clamp entre `0` et `totalDurationMs`, puis affiche un repere vertical unique et le badge `Repere : <temps>`.

Phrase canonique :

```text
V1-62 rend le repere temporel deplacable a la souris.
V1-62 ne joue toujours pas la cinematique.
```

Le comportement reste strictement editor-only : aucune lecture, aucun seek runtime, aucun scrubber runtime, aucun drag de blocs, aucune mutation `ProjectManifest`.

## 2. Gate 0

Commande executee depuis la racine avant modification V1-62 :

```bash
pwd && git branch --show-current && git status --short --untracked-files=all && git diff --stat && git diff --name-only && git log --oneline -n 15
```

Sortie exacte :

```text
/Users/karim/Project/pokemonProject
main
044155fc feat(narrative): add cinematic timeline mouse playhead scrub prep contract (NS-SCENES-V1-61)
32f92c54 feat(narrative): add cinematic timeline keyboard navigation polish help overlay v0 (NS-SCENES-V1-60)
ede69519 feat(narrative): add cinematic timeline lane vertical navigation v0 (NS-SCENES-V1-59)
e1e83cd9 feat(narrative): add cinematic timeline lane vertical navigation prep contract (NS-SCENES-V1-58)
26958d88 feat(narrative): add cinematic timeline keyboard navigation selection polish v0 (NS-SCENES-V1-57)
af8a3bf9 feat(narrative): add cinematic timeline bar geometry duration scale correction v0 (NS-SCENES-V1-56)
16a888b1 feat(narrative): add cinematic timeline visual polish density pass and interaction polish hover details v0 (NS-SCENES-V1-54-V1-55)
13f423c1 feat(narrative): add cinematic timeline transport controls placeholder v0 (NS-SCENES-V1-53)
df27cccb feat(narrative): add cinematic timeline selection cursor playhead placeholder v0 (NS-SCENES-V1-52)
8ce1a417 feat(narrative): add cinematic actor movement inspector polish and timeline time axis bar layout v0 (NS-SCENES-V1-50-V1-51)
7d6c94cf feat(narrative): add cinematic actor movement block v0 (NS-SCENES-V1-49)
77d12c69 feat(narrative): add cinematic timeline lane grouping v0 (NS-SCENES-V1-48)
aaa9028f feat(narrative): add cinematic actor movement block v0 prep contract (NS-SCENES-V1-47)
7a4404f6 feat(narrative): add cinematic actor references actor facing v0 (NS-SCENES-V1-46)
c68990a7 feat(narrative): add cinematic wait fade camera basic blocks evidence closure (NS-SCENES-V1-45-BIS)
```

Interpretation : les sorties `git status --short --untracked-files=all`, `git diff --stat` et `git diff --name-only` etaient vides avant V1-62.

## 3. Fichiers lus

Inventaire :

```text
AGENTS.md
agent_rules.md
skills/README.md
skills/test-driven-development/SKILL.md
skills/verification-before-completion/SKILL.md
skills/writing-plans/SKILL.md
reports/narrativeStudio/scenes/road_map_scenes.md
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/ns_scenes_v1_61_cinematic_timeline_mouse_playhead_scrub_prep_contract.md
reports/narrativeStudio/scenes/ns_scenes_v1_60_cinematic_timeline_keyboard_navigation_polish_help_overlay_v0.md
reports/narrativeStudio/scenes/ns_scenes_v1_60_evidence_pack.md
reports/narrativeStudio/scenes/ns_scenes_v1_59_cinematic_timeline_lane_vertical_navigation_v0.md
reports/narrativeStudio/scenes/ns_scenes_v1_56_cinematic_timeline_bar_geometry_duration_scale_correction_v0.md
reports/narrativeStudio/scenes/ns_scenes_v1_52_cinematic_timeline_selection_cursor_playhead_placeholder_v0.md
reports/narrativeStudio/scenes/ns_scenes_v1_51_cinematic_timeline_time_axis_bar_layout_v0.md
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
packages/map_editor/lib/src/ui/design_system/pokemap_card.dart
packages/map_editor/lib/src/ui/design_system/pokemap_badge.dart
packages/map_editor/test/cinematic_builder_workspace_test.dart
packages/map_editor/test/cinematics_library_workspace_test.dart
packages/map_core/lib/src/read_models/cinematic_timeline_time_layout_read_model.dart
packages/map_core/lib/src/read_models/cinematic_timeline_lane_read_model.dart
packages/map_core/test/cinematic_timeline_time_layout_read_model_test.dart
packages/map_core/test/cinematic_timeline_lane_read_model_test.dart
```

## 4. Design Gate — Cinematic Timeline Mouse Time Probe / Playhead Drag V0

1. Contrat V1-61 implemente : Option B, `Mouse Time Probe` local, sans playback.
2. `selectedStepId` vit dans l'etat local du Builder et continue de piloter selection, preview placeholder et inspecteur.
3. `timelineProbeTimeMs` est ajoute dans `_CinematicBuilderWorkspaceState`.
4. Il reste editor-local pour ne pas polluer `ProjectManifest`, `CinematicAsset`, le core ou le runtime.
5. Le click probe est initie par l'axe temporel et le fond des lanes.
6. Le drag probe est initie par les memes zones axe/fond.
7. Les barres gardent leur propre `onTap` de selection et ne recoivent aucun drag authoring.
8. La position souris est convertie en temps par `localX / pixelsPerMs`.
9. L'origine X commune V1-56 est respectee car les handlers sont poses dans le contenu temporel, pas dans la colonne pistes.
10. Le scroll horizontal est pris en compte par la position locale du viewport scrollable et teste avec une timeline longue.
11. Le temps est clamp entre `0` et `totalDurationMs`.
12. Aucun snap n'est code en V0 pour garder une souris fluide.
13. Le badge affiche `Repere : <temps>` quand `timelineProbeTimeMs` existe.
14. Un seul repere vertical est visible : probe prioritaire, sinon curseur de selection, sinon rien.
15. Selectionner une barre clear le probe.
16. Toute navigation clavier qui selectionne un bloc clear le probe via `onStepSelected`.
17. L'inspecteur reste stable pendant le probe car `selectedStepId` ne change pas.
18. La preview sandbox affiche seulement `Repere temporel : <temps>` et `Preview reelle a venir.`
19. Hover V1-55 reste local aux barres et ne definit pas le probe.
20. Aide clavier V1-60 reste accessible et non transformee en aide souris.
21. Transports V1-53 restent disabled.
22. Non-mutation `ProjectManifest` prouvee par tests `toJson()` et compteur de changement.
23. Pas de playback : aucun callback de lecture, timer ou etat `isPlaying`.
24. Pas de seek runtime : aucune API runtime n'est appelee.
25. Pas de drag/drop de blocs : aucun `Draggable`, `DragTarget` ou mutation temporelle de barre.
26. Pas de resize/reorder : les barres restent une projection derivee.
27. Visual Gate produite : `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_62_cinematic_timeline_mouse_time_probe_playhead_drag_v0.png`.
28. Prochain lot exact recommande : `NS-SCENES-V1-63 — Cinematic Timeline Mouse Probe Polish / Boundary Snap Prep V0`.

## 5. Scope realise

Scope code : `cinematic_builder_workspace.dart` et `cinematic_builder_workspace_test.dart`.

Scope fonctionnel : etat local `timelineProbeTimeMs`, click/drag axe/fond, conversion X -> temps, clamp, badge `Repere`, repere vertical unique, preview sandbox informative, clear du probe sur selection bloc/clavier et tests de non-mutation.

## 6. Contrat V1-61 implemente

Le contrat V1-61 est implemente sans elargissement : le probe est local, non persiste, separe de `selectedStepId`, separe du playback runtime, et limite a un repere vertical V0.

## 7. Etat local timelineProbeTimeMs

`_timelineProbeTimeMs` vit dans `_CinematicBuilderWorkspaceState`. Il est remis a `null` lors d'une selection de bloc, d'une navigation clavier ou d'un changement de cinematic selectionnee. Il n'est pas present dans `map_core`, les diagnostics, les operations authoring ou le JSON.

## 8. Zones interactives click / drag

`_TimelineAxis` et `_TimelineTrackRow` acceptent `onTapDown`, `onPanStart` et `onPanUpdate`. Les barres restent au-dessus du fond et conservent leur selection existante.

## 9. Conversion souris -> temps

La conversion est centralisee dans `_timelineProbeTimeMsFromLocalX`. Elle part du `localX` dans le contenu temporel, borne la position a la largeur utile, divise par `pixelsPerMs`, puis retourne un entier clamp. La prise en compte du scroll horizontal est testee en scrollant le viewport temporel avant clic.

## 10. Clamp 0..totalDurationMs

Le test de drag verifie le clamp gauche a `0 ms` et le clamp droit a la duree totale de la fixture. Aucun temps negatif ou superieur a la duree totale ne peut etre rendu par le probe.

## 11. Repere visuel et badge Repere

Quand `_timelineProbeTimeMs` existe, le badge de statut temporel affiche `Repere : <temps>` et `_TimelineTimeProbeCursor` rend une ligne verticale distincte. Quand le probe est clear, le badge redevient `Selection : <temps>` si un bloc est selectionne.

## 12. Relation avec selectedStepId

Deplacer le probe ne modifie pas `selectedStepId`. Le test principal verifie que la carte selectionnee et l'inspecteur restent sur le bloc initial pendant le placement du repere souris.

## 13. Relation avec keyboard navigation

La navigation clavier existante reste locale a la timeline. Comme elle appelle `onStepSelected`, elle clear automatiquement le probe et restaure le curseur de selection derive du bloc cible.

## 14. Relation avec preview sandbox

La preview sandbox affiche une information locale :

```text
Repere temporel : <temps>
Preview reelle a venir.
```

Elle n'interpole pas la camera, ne joue pas d'acteur, ne declenche pas FX/son et ne mute aucun bloc.

## 15. Relation avec hover/help/transport

Hover details restent temporaires. L'aide clavier compacte reste disponible. Les boutons Reset / Play / Stop restent disabled et ne deviennent pas fonctionnels apres placement du probe.

## 16. Restrictions anti-playback / anti-runtime / anti-editor temporel

V1-62 n'ajoute pas de playback, timer, `Ticker`, `AnimationController`, `isPlaying`, `currentTimeMs`, `playbackTimeMs`, seek runtime, scrubber runtime, transport actif, drag de blocs, resize, reorder ou persistance temporelle.

## 17. Legacy bridge policy inchangee

Les Cinematic bridges legacy restent exclus du Builder canonique. V1-62 ne modifie pas la policy `ScenarioAsset`, `CinematicAsset`, runtime adapter ou Scene Runtime.

## 18. Design system

Le rendu ajoute utilise `PokeMapBadge`, `PokeMapCard` deja en place et `context.pokeMapColors`. Aucune couleur hardcodee n'est ajoutee dans le widget modifie.

## 19. Tests ajoutes ou modifies

Tests ajoutes :

```text
sets a local timeline time probe from mouse interaction without changing selection
drags local timeline time probe and clamps to boundaries
clears local time probe when selecting blocks or using keyboard
time probe accounts for horizontal scroll offset
dragging a timeline block does not move or resize it
captures V1-62 cinematic timeline mouse time probe when requested
```

Test existant adapte : `shows a non-interactive selection cursor on selected block start`, car l'axe devient maintenant une zone probe V1-62.

## 20. Visual Gate

Capture produite :

```text
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_62_cinematic_timeline_mouse_time_probe_playhead_drag_v0.png
```

Preuve fichier :

```text
-rw-r--r--  1 karim  staff  232005 Jun  3 03:07 reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_62_cinematic_timeline_mouse_time_probe_playhead_drag_v0.png
PNG image data, 1663 x 926, 8-bit/color RGBA, non-interlaced
69cd75174fc642ce10c6dd6f55c75a356c2b6322  reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_62_cinematic_timeline_mouse_time_probe_playhead_drag_v0.png
```

Observation visuelle : `Repere : 750 ms` est visible, le repere vertical est affiche, la preview sandbox indique le repere temporel, l'inspecteur reste sur le bloc selectionne et les transports restent disabled.

## 21. Commandes executees

Commandes principales :

```bash
cd packages/map_editor && flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --plain-name 'sets a local timeline time probe from mouse interaction without changing selection'
cd packages/map_editor && flutter test --reporter=compact test/cinematic_builder_workspace_test.dart
cd packages/map_editor && flutter test --reporter=compact test/cinematics_library_workspace_test.dart
cd packages/map_core && dart test test/cinematic_timeline_time_layout_read_model_test.dart
cd packages/map_core && dart test test/cinematic_timeline_lane_read_model_test.dart
cd packages/map_core && dart analyze
cd packages/map_editor && flutter analyze --no-fatal-infos lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart test/cinematic_builder_workspace_test.dart
cd packages/map_editor && flutter test --update-goldens --dart-define=NS_SCENES_V1_62_CAPTURE_CINEMATIC_TIMELINE_MOUSE_TIME_PROBE=true --reporter=compact test/cinematic_builder_workspace_test.dart
```

Les sorties detaillees sont dans l'Evidence Pack V1-62.

## 22. Resultats des tests

Resultats GREEN :

```text
Test cible probe : All tests passed!
Suite Builder : 00:11 +52: All tests passed!
Suite Library : 00:05 +10: All tests passed!
Core time layout : 00:00 +4: All tests passed!
Core lane layout : 00:00 +2: All tests passed!
Visual Gate : 00:09 +52: All tests passed!
```

## 23. Analyze

Resultats :

```text
cd packages/map_core && dart analyze
Analyzing map_core...
No issues found!

cd packages/map_editor && flutter analyze --no-fatal-infos lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart test/cinematic_builder_workspace_test.dart
Analyzing 2 items...
No issues found! (ran in 1.3s)
```

## 24. Checks anti-scope

Checks effectues : diff runtime/gameplay/battle/examples vide, recherches anti-runtime vides, recherches anti-playback/seek/core persistence/design colors/image IA/Selbrume conformes. La seule sortie anti-drag contient des assertions de test negatives autour de `resize` / `reorder`, pas de capability active.

## 25. Fichiers crees

```text
reports/narrativeStudio/scenes/ns_scenes_v1_62_cinematic_timeline_mouse_time_probe_playhead_drag_v0.md
reports/narrativeStudio/scenes/ns_scenes_v1_62_evidence_pack.md
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_62_cinematic_timeline_mouse_time_probe_playhead_drag_v0.png
```

## 26. Fichiers modifies

```text
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
packages/map_editor/test/cinematic_builder_workspace_test.dart
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md
```

## 27. Roadmaps mises a jour

Les roadmaps marquent V1-62 comme DONE, documentent le scope realise, les limites, la preuve et recommandent V1-63 comme prochain lot exact. V1-63 n'est pas demarre.

## 28. Limites connues

V1-62 ne fait pas de snap, ne ferme pas le probe par Escape et ne propose pas encore de polish de bord/threshold. Ces sujets appartiennent au lot V1-63 recommande.

## 29. Non-objectifs confirmes

Non-objectifs confirmes : pas de playback, pas de seek runtime, pas de scrubber runtime, pas de transport fonctionnel, pas de drag/resize/reorder de blocs, pas de mutation JSON, pas de runtime, pas de build_runner, pas d'image IA, pas de donnees Selbrume.

## 30. Evidence Pack

Evidence Pack :

```text
reports/narrativeStudio/scenes/ns_scenes_v1_62_evidence_pack.md
```

Il contient Gate 0, RED/GREEN, sorties de commandes, preuve Visual Gate, checks anti-scope et hunks complets des fichiers suivis modifies.

## 31. Auto-review critique

1. map_runtime modifie ? Non.
2. map_gameplay/map_battle/examples modifies ? Non.
3. Modele JSON modifie ? Non.
4. build_runner lance ? Non.
5. Playback ajoute ? Non.
6. Timer ajoute ? Non.
7. `isPlaying/currentTimeMs/playbackTimeMs` ajoutes ? Non.
8. Seek runtime ajoute ? Non.
9. Scrubber runtime ajoute ? Non.
10. Transports rendus fonctionnels ? Non.
11. Drag de bloc ajoute ? Non.
12. Resize ajoute ? Non.
13. Reorder ajoute ? Non.
14. Nouvelle capability authoring ajoutee ? Non, seulement une inspection temporelle locale.
15. `timelineProbeTimeMs` local editor-only ? Oui.
16. Probe non persiste ? Oui.
17. Click axe/fond definit un repere ? Oui.
18. Drag axe/fond deplace le repere ? Oui.
19. Origine X prise en compte ? Oui.
20. Scroll horizontal pris en compte ? Oui, teste.
21. Temps clamp ? Oui.
22. Selection barre clear le probe ? Oui.
23. Navigation clavier clear le probe ? Oui.
24. Inspecteur stable pendant probe ? Oui.
25. Preview sandbox non runtime ? Oui.
26. Hover/help/transport preserves ? Oui.
27. `ProjectManifest` non mute ? Oui.
28. Design system respecte ? Oui.
29. Visual Gate prouve le repere souris ? Oui.
30. Evidence Pack sans placeholder ? Oui.
31. Prochain lot exact recommande ? `NS-SCENES-V1-63 — Cinematic Timeline Mouse Probe Polish / Boundary Snap Prep V0`.

## 32. Recommandation pour le prochain lot

Prochain lot exact recommande :

```text
NS-SCENES-V1-63 — Cinematic Timeline Mouse Probe Polish / Boundary Snap Prep V0
```

Justification : V1-62 donne le geste souris local. Le prochain travail utile est de cadrer le polish du probe, les bords, le snap eventuel et les edge cases de scroll, sans encore transformer la timeline en playback ou en editeur temporel.
