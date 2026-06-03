# NS-SCENES-V1-65 — Cinematic Timeline Mouse Probe UX Polish / Clear Controls V0

Date : 2026-06-03
Statut : DONE
Type : editor / UX polish / interaction locale non persistante
Lot precedent : `NS-SCENES-V1-64 — Cinematic Timeline Mouse Probe Boundary Snap V0`
Prochain lot recommande : `NS-SCENES-V1-66 — Cinematic Timeline Mouse Probe Help / Selection Explanation V0`

## 1. Resume executif

V1-65 polit l'experience du repere temporel souris du Cinematic Builder. Le but est de rendre l'etat `Repere` clair et reversible pour un utilisateur no-code : ajouter un controle explicite `Effacer le repère`, revenir au curseur de selection quand un bloc est selectionne, et garder le probe strictement editor-only.

Ce lot ne cree aucun playback, aucun seek runtime, aucun scrubber runtime, aucun transport fonctionnel, aucun drag/resize/reorder de blocs et aucune mutation `ProjectManifest`.

## 2. Gate 0

Commande executee depuis la racine avant toute modification V1-65 :

```bash
pwd && git branch --show-current && git status --short --untracked-files=all && git diff --stat && git diff --name-only && git log --oneline -n 15
```

Sortie exacte :

```text
/Users/karim/Project/pokemonProject
main
95e79063 feat(narrative): add cinematic timeline mouse probe boundary snap v0 (NS-SCENES-V1-64)
86004392 feat(narrative): add cinematic timeline mouse probe polish boundary snap prep v0 (NS-SCENES-V1-63)
79414165 feat(narrative): add cinematic timeline mouse time probe playhead drag v0 (NS-SCENES-V1-62)
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
```

Interpretation : `git status --short --untracked-files=all`, `git diff --stat` et `git diff --name-only` n'ont rien imprime. Le working tree etait propre avant V1-65 ; V1-64 est deja committe en tete locale.

## 3. Fichiers lus

- `AGENTS.md`
- `agent_rules.md`
- `skills/README.md`
- `skills/test-driven-development/SKILL.md`
- `skills/verification-before-completion/SKILL.md`
- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_64_cinematic_timeline_mouse_probe_boundary_snap_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_64_evidence_pack.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_63_cinematic_timeline_mouse_probe_polish_boundary_snap_prep_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_62_cinematic_timeline_mouse_time_probe_playhead_drag_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_62_evidence_pack.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_60_cinematic_timeline_keyboard_navigation_polish_help_overlay_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_59_cinematic_timeline_lane_vertical_navigation_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_56_cinematic_timeline_bar_geometry_duration_scale_correction_v0.md`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart`
- `packages/map_editor/lib/src/ui/design_system/pokemap_card.dart`
- `packages/map_editor/lib/src/ui/design_system/pokemap_badge.dart`
- `packages/map_editor/test/cinematic_builder_workspace_test.dart`
- `packages/map_editor/test/cinematics_library_workspace_test.dart`
- `packages/map_core/lib/src/read_models/cinematic_timeline_time_layout_read_model.dart`
- `packages/map_core/lib/src/read_models/cinematic_timeline_lane_read_model.dart`
- `packages/map_core/test/cinematic_timeline_time_layout_read_model_test.dart`
- `packages/map_core/test/cinematic_timeline_lane_read_model_test.dart`

## 4. Design Gate — Cinematic Timeline Mouse Probe UX Polish / Clear Controls V0

1. Comportement V1-64 actuel : click/drag cree un repere local, snap aux bords/blocs si proche, badge `Repère : <temps> · <hint>`, clear implicite sur selection bloc et navigation clavier.
2. Ambiguite no-code : `Repère` peut ressembler a une selection ou a un debut de playback, surtout quand la selection reste ailleurs.
3. `timelineProbeTimeMs` vit dans `_CinematicBuilderWorkspaceState`, etat local editor-only.
4. `timelineProbeSnapHint` vit au meme endroit, local et non persiste.
5. Effacer sans modifier `selectedStepId` : remettre seulement `timelineProbeTimeMs` et `timelineProbeSnapHint` a `null`.
6. Effacer sans modifier `ProjectManifest` : ne pas appeler `onProjectChanged`, operations authoring ou mutation asset.
7. Controle UI ajoute : un bouton compact `Effacer le repère` visible seulement quand un probe existe.
8. Ce controle ne doit pas etre Reset transport car Reset est un placeholder playback disabled ; le clear du probe est une action d'inspection locale.
9. Libelle exact retenu : `Effacer le repère`.
10. Placement : dans l'en-tete de timeline, pres des actions locales, pas dans les transports. Une tentative dans la ligne de badges sortait du viewport sur la surface de reference.
11. Surcharge de badges : le bouton apparait uniquement quand le probe est actif, et reste compact.
12. Escape : oui, a implementer si local au handler clavier de timeline.
13. Protection TextFields : Escape n'est gere que par le `Focus` local de timeline ; les TextFields ne doivent pas donner le focus timeline.
14. Apres clear avec bloc selectionne : badge `Sélection : <temps>` et curseur de selection reviennent.
15. Apres clear sans bloc selectionne : aucun repere probe, aucun badge `Repère`, pas de faux curseur.
16. Selection vs repere : selection = bloc/inspecteur ; repere = inspection temporelle locale.
17. Preview sandbox : garder informative, sans runtime ni interpolation.
18. Snap V1-64 preserve : clear retire le hint, mais le prochain click/drag peut snapper de nouveau.
19. Drag probe V1-62 preserve : le clear ne desactive aucun handler.
20. Navigation clavier V1-57/V1-59 preservee : selection clavier continue de clear le probe implicitement.
21. Hover V1-55 preserve : hover ne definit pas le probe et reste informatif.
22. Aide clavier V1-60 preservee : pas de refonte de l'aide.
23. Transports disabled V1-53 preserves : Reset/Play/Stop restent `onPressed = null`.
24. Non-mutation `ProjectManifest` : tests `project.toJson()` et compteur `onProjectChanged`.
25. Pas de playback : aucun etat de lecture, timer ou callback runtime.
26. Pas de seek runtime : le temps reste local et n'est transmis a aucun runtime.
27. Pas de drag/drop de blocs : aucun handler de bloc n'est ajoute ou modifie pour deplacer une barre.
28. Visual Gate : capture Flutter du Builder avec probe actif, bouton `Effacer le repère`, selection/inspecteur/transports stables.
29. Prochain lot exact recommande : `NS-SCENES-V1-66 — Cinematic Timeline Mouse Probe Help / Selection Explanation V0`.

## 5. Implementation

Fichiers modifies :

- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart`
- `packages/map_editor/test/cinematic_builder_workspace_test.dart`
- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_65_cinematic_timeline_mouse_probe_ux_polish_clear_controls_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_65_evidence_pack.md`
- `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_65_cinematic_timeline_mouse_probe_ux_polish_clear_controls_v0.png`

Changements produit :

- ajout d'un callback local `onTimelineProbeCleared` ;
- clear strict de `_timelineProbeTimeMs` et `_timelineProbeSnapHint` ;
- bouton design-system `Effacer le repère` visible seulement quand un probe existe ;
- micro-explication compacte `Repère local : inspection uniquement.` visible quand le probe est actif ;
- handler `Escape` borne au `Focus` local de la timeline ;
- aucun appel authoring, transport, runtime ou mutation `ProjectManifest`.

## 6. RED test

Commande :

```bash
cd packages/map_editor && flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --plain-name 'clears local timeline time probe without changing selected block'
```

Sortie RED avant implementation :

```text
Expected: exactly one matching candidate
  Actual: _KeyWidgetFinder:<Found 0 widgets with key [<'cinematic-builder-clear-time-probe-button'>]: []>
   Which: means none were found but one was expected

The test description was:
  clears local timeline time probe without changing selected block
00:03 +0 -1: Some tests failed.
```

Interpretation : le test demandait un controle explicite de clear ; l'UI V1-64 ne l'avait pas.

## 7. Ajustement de placement

Une premiere implementation du bouton dans la ligne de badges a cree un controle hors zone cliquable sur la surface de reference :

```text
Warning: A call to tap() with finder "Found 1 widget with key [<'cinematic-builder-clear-time-probe-button'>]" derived an Offset (2281.5, 459.3) that would not hit test on the specified widget. Maybe the widget is actually off-screen...
```

Decision : le controle est place dans l'en-tete du panneau timeline, a cote de `Ajouter un brouillon`. Il reste contextuel, visible et clairement separe des controles Reset/Play/Stop.

## 8. GREEN tests cibles

Commande :

```bash
cd packages/map_editor && flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --plain-name 'clears local timeline time probe without changing selected block'
```

Sortie :

```text
00:02 +1: clears local timeline time probe without changing selected block
00:02 +1: All tests passed!
```

Commande complementaire :

```bash
cd packages/map_editor && flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --name 'clears local time probe with Escape|keeps local time probe when Escape|clears local time probe without selection|keeps hover help'
```

Sortie :

```text
00:02 +1: clears local time probe with Escape while timeline has focus
00:03 +2: keeps local time probe when Escape targets a text field
00:03 +3: clears local time probe without selection and can snap again
00:03 +7: keeps hover help and disabled transports after snapped probe
00:03 +7: All tests passed!
```

## 9. Visual Gate

Commande officielle :

```bash
cd packages/map_editor && flutter test --update-goldens --dart-define=NS_SCENES_V1_65_CAPTURE_CINEMATIC_TIMELINE_MOUSE_PROBE_CLEAR_CONTROLS=true --reporter=compact test/cinematic_builder_workspace_test.dart
```

Sortie finale :

```text
00:08 +64: captures V1-64 cinematic timeline mouse probe snap when requested
00:08 +65: captures V1-65 cinematic timeline mouse probe clear controls when requested
00:08 +65: All tests passed!
```

Capture :

```text
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_65_cinematic_timeline_mouse_probe_ux_polish_clear_controls_v0.png
```

Preuve fichier :

```text
PNG image data, 1663 x 926, 8-bit/color RGBA, non-interlaced
SHA-256 843d41c0bcb12c9cb9809d3212efc4a25db63317a9159744d6c90f7161c2f033
```

## 10. Tests et analyses

Suite Library :

```bash
cd packages/map_editor && flutter test --reporter=compact test/cinematics_library_workspace_test.dart
```

Resultat :

```text
00:03 +10: captures V1-38 Cinematics Library screenshot when requested
00:03 +10: All tests passed!
```

Core non-regression :

```bash
cd packages/map_core && dart test --reporter=compact test/cinematic_timeline_time_layout_read_model_test.dart test/cinematic_timeline_lane_read_model_test.dart
```

Resultat :

```text
00:00 +6: All tests passed!
```

Analyse core :

```bash
cd packages/map_core && dart analyze
```

Resultat :

```text
Analyzing map_core...
No issues found!
```

Analyse cible editor :

```bash
cd packages/map_editor && flutter analyze lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart test/cinematic_builder_workspace_test.dart
```

Resultat :

```text
Analyzing 2 items...
No issues found! (ran in 2.8s)
```

Analyse globale editor :

```bash
cd packages/map_editor && flutter analyze
```

Resultat : echec preexistant hors lot avec `344 issues found`. Les erreurs bloquantes remontent notamment de :

```text
lib/src/application/services/pokemon_sdk_move_catalog_converter.dart
lib/src/application/use_cases/sync_pokemon_sdk_moves_catalog_use_case.dart
```

Ces fichiers ne sont pas modifies par V1-65.

## 11. Couverture comportementale

- Clear bouton avec bloc selectionne : retour `Sélection : 500 ms`, curseur de selection visible.
- Clear bouton sans bloc selectionne : aucun badge `Repère`, aucun badge `Sélection`, aucun curseur.
- Probe actif : micro-explication compacte `Repère local : inspection uniquement.` visible sans overflow.
- Clear retire le snap hint : `Repère : 500 ms · début bloc` disparait et le prochain click peut snapper de nouveau.
- Escape clear seulement quand la timeline a le focus.
- Escape depuis un champ texte ne clear pas le probe.
- Selection bloc et navigation clavier continuent de clear implicitement le probe.
- Hover details et aide clavier restent disponibles apres clear.
- Reset/Play/Stop restent disabled et ne deviennent pas des actions de clear.
- `ProjectManifest` reste stable via `project.toJson()` et compteur `onProjectChanged`.

## 12. Anti-scope

V1-65 ne modifie pas :

- `packages/map_runtime`
- `packages/map_gameplay`
- `packages/map_battle`
- `examples/playable_runtime_host`
- `packages/map_core`

V1-65 n'ajoute pas :

- playback, timer, ticker, `AnimationController`, `isPlaying`, `currentTimeMs` ou `playbackTimeMs` ;
- seek runtime, scrubber runtime ou transport fonctionnel ;
- drag/drop, resize, reorder ou edition temporelle de blocs ;
- changement JSON/core/model ou build_runner ;
- image IA, `gpt-image-2` ou asset genere ;
- donnees Selbrume/Mael/Lysa/Port Brisants.

## 13. Roadmaps

- `reports/narrativeStudio/scenes/road_map_scenes.md` : V1-65 passe DONE, prochain lot V1-66.
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md` : V1-65 passe DONE, V1-66 ajoute comme TODO.

## 14. Limites connues

Le bouton `Effacer le repère` est un controle local d'inspection. Il n'est pas un transport, ne repositionne pas une lecture et ne prepare aucun seek runtime. L'aide locale actuelle explique la navigation clavier, mais ne detaille pas encore assez la difference entre `Selection` et `Repere` : c'est le prochain lot V1-66.
