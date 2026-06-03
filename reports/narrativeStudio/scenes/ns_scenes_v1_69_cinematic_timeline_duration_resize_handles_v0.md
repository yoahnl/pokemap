# NS-SCENES-V1-69 — Cinematic Timeline Duration Resize Handles V0

## 1. Résumé exécutif

V1-69 est implemente. Le Cinematic Builder affiche maintenant une poignee de resize uniquement sur le bord droit de la barre selectionnee quand le step est editable et authoring-owned. Le drag modifie seulement `durationMs`, reutilise les operations V1-68, quantifie au pas de 100 ms, applique les bornes existantes et recalcule la timeline derivee sans persister `startMs` / `endMs`.

Le lot ne cree pas de timeline libre : pas de drag du bloc entier, pas de bord gauche draggable, pas de changement de lane, pas de reorder, pas de playback, pas de seek runtime.

## 2. Gate 0

Commande `pwd` :

```text
/Users/karim/Project/pokemonProject
```

Commande `git branch --show-current` :

```text
main
```

Commande `git status --short --untracked-files=all` :

```text
<vide>
```

Commande `git diff --stat` :

```text
<vide>
```

Commande `git diff --name-only` :

```text
<vide>
```

Commande `git log --oneline -n 15` :

```text
263233b4 feat(narrative): add cinematic timeline duration inspector editing v0 (NS-SCENES-V1-68)
c8bb19a2 feat(narrative): add cinematic timeline duration editing resize prep contract (NS-SCENES-V1-67)
e67e71c7 feat(narrative): add cinematic timeline mouse probe help selection explanation v0 (NS-SCENES-V1-66)
46cc0eb4 feat(narrative): add cinematic timeline mouse probe UX polish clear controls v0 (NS-SCENES-V1-65)
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
```

Le working tree etait propre au Gate 0. `selbrume/project.json` n'etait pas modifie.

## 3. Fichiers lus

Fichiers d'instructions et roadmap : `AGENTS.md`, `agent_rules.md`, `reports/narrativeStudio/scenes/road_map_scenes.md`, `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`.

Rapports precedents lus : V1-68, V1-67, V1-66, V1-65, V1-64, V1-62, V1-56 et V1-51.

Core lu : `packages/map_core/lib/src/authoring/cinematic_authoring_operations.dart`, `packages/map_core/lib/src/read_models/cinematic_timeline_time_layout_read_model.dart`, `packages/map_core/lib/src/read_models/cinematic_timeline_lane_read_model.dart` et leurs tests cibles.

Editor lu : `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart`, `packages/map_editor/test/cinematic_builder_workspace_test.dart`, `packages/map_editor/test/cinematics_library_workspace_test.dart`.

## 4. Design Gate — Cinematic Timeline Duration Resize Handles V0

1. Decision implementee : Option C V1-67/V1-68, inspecteur d'abord puis resize droit comme autre entree vers `durationMs`.
2. `durationMs` vit dans le `CinematicTimelineStep`; `startMs` et `endMs` restent derives par le read model.
3. Operations reutilisees : `onUpdateBasicBlockStep`, `onUpdateActorFacingStep`, `onUpdateActorMoveStep`.
4. Blocs avec handle : `wait`, `fade`, `camera`, `actorFace`, `actorMove` authoring-owned et selectionnes.
5. Blocs sans handle : non-owned, legacy bridge, `dialogueLine`, `sound`, `music`, `shake`, `fx`, `actorEmote`, marker draft sans duree explicite.
6. Detection : helper existant de type authoring step et checks `isCinematicTimelineBasicBlockStep`, `isCinematicTimelineActorFacingStep`, `isCinematicTimelineActorMoveStep`.
7. Placement : `Positioned(right: 0)` dans la `Stack` de la barre selectionnee.
8. Visibilite : selection uniquement, pour limiter le bruit visuel et le hit testing.
9. Corps de barre non draggable : le `GestureDetector` horizontal n'est attache qu'au handle.
10. Bord gauche non draggable : aucune cle ni gesture de resize gauche n'est creee.
11. Conversion : `deltaMs = deltaX / pixelsPerMs`.
12. Origine V1-56 preservee : le calcul reutilise `pixelsPerMs` du layout courant.
13. Quantification : arrondi au multiple de 100 ms le plus proche.
14. Clamp : min existant, min 200 ms pour `actorMove`, max `cinematicTimelineMaximumDurationMs`.
15. Selection preservee : aucune mutation de `selectedStepId`; le callback update conserve le step cible.
16. Probe clear : apres mutation acceptee, `_timelineProbeTimeMs` et `_timelineProbeSnapHint` repassent a `null`.
17. Inspecteur preserve : le champ duree V1-68 lit le step mis a jour et affiche la nouvelle valeur.
18. Probe souris hors handle : les gestures de probe restent sur axe/fond, le handle consomme son drag.
19. Snap probe preserve : aucune modification de la logique de snap; le probe est seulement efface apres resize accepte.
20. Aide repere preservee : elle disparait avec le probe apres resize accepte.
21. Hover details preserves : test widget dedie apres resize.
22. Navigation clavier preservee : test ArrowRight apres resize.
23. Transports preserves : boutons Reset / Play / Stop restent disabled.
24. Drag cancel : code de cancel restaure la duree initiale si une duree intermediaire avait ete appliquee; le chemin Flutter cancel reste non teste car fragile.
25. `startMs/endMs` derives : tests JSON du step cible et anti-scope read model.
26. Pas de timeline libre : aucun champ de position/lane/ordre n'est modifie.
27. Pas de playback : aucun timer, ticker, etat `isPlaying` ou transport actif.
28. Pas de seek runtime : seules assertions negatives mentionnent seek/scrub.
29. Visual Gate : `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_69_cinematic_timeline_duration_resize_handles_v0.png`.
30. Prochain lot recommande : `NS-SCENES-V1-70 — Cinematic Timeline Duration Validation / Diagnostics Polish V0`.

## 5. Scope réalisé

Le widget de timeline sait redimensionner une barre editable par son bord droit. Le resultat visible est immediat : largeur de la barre, position des blocs suivants, total derive, selection et inspecteur se synchronisent via le projet mis a jour en memoire.

## 6. Contrat V1-67 / V1-68 implémenté

Le resize ne devient pas un nouveau modele temporel. Il appelle les memes callbacks de mutation que l'inspecteur V1-68, donc le garde-fou authoring/core reste la source de verite.

## 7. Handle droit de durée

Le handle a la cle `cinematic-builder-duration-resize-handle-$stepId`, un tooltip `Ajuster la durée`, un curseur `SystemMouseCursors.resizeLeftRight`, une largeur de hit target de 16 px et une decoration basee sur `context.pokeMapColors`.

## 8. Blocs éditables / non éditables

Editables : basic blocks authoring-owned (`wait`, `fade`, `camera`), `actorFace`, `actorMove`.

Non editables pour ce lot : bloc non-owned, marker draft, audio/dialogue/fx/legacy bridge et tout bloc qui n'a pas le contrat authoring V1-68.

## 9. Conversion deltaX -> deltaMs

Le drag stocke `startGlobalX` et la duree initiale. Chaque update calcule `initialDurationMs + (currentGlobalX - startGlobalX) / pixelsPerMs`.

## 10. Quantification 100 ms

Le helper local `_quantizeDurationMs` applique `(durationMs / 100).round() * 100`.

## 11. Clamp min/max

Le helper `_durationResizeCandidateMs` clamp entre le minimum du bloc et `cinematicTimelineMaximumDurationMs`. `actorMove` garde son minimum specifique de 200 ms.

## 12. Drag start / update / end / cancel

Start : creation de `_TimelineDurationResizeDrag`.

Update : calcul, quantification, clamp, puis callback de mutation si la valeur change.

End : efface l'etat local de resize.

Cancel : restaure la duree initiale si la valeur appliquee differait.

## 13. Recalcul timeline dérivée

La suite des barres se recale via `buildCinematicTimelineTimeLayoutReadModel`. Aucun `startMs` ni `endMs` n'est stocke dans le JSON.

## 14. Relation avec selectedStepId

Le resize ne change pas la selection. Les tests verifient que le step selectionne reste `step_face` ou `step_move` apres drag.

## 15. Relation avec probe souris

Un resize accepte efface le probe local et donc masque le badge `Repere`, le bouton `Effacer le repère` et l'aide repere.

## 16. Relation avec inspecteur V1-68

Apres resize, le champ `cinematic-builder-actor-facing-duration-ms-field` affiche la nouvelle valeur.

## 17. Relation avec hover / aides / transports

Hover details et navigation clavier restent fonctionnels apres resize. Les transports restent disabled (`onPressed == null`) et aucun label de playback n'apparait.

## 18. Restrictions anti-drag de bloc / anti-timeline libre / anti-playback

Aucune gesture de drag n'est attachee au corps de la barre. Aucun `Draggable`, `DragTarget`, reorder, move step, lane persistante, timer, ticker, playback, seek runtime ou scrubber runtime n'est ajoute.

## 19. Legacy bridge policy inchangée

Les bridges legacy restent hors Builder canonique. V1-69 ne modifie pas les policies de Cinematic bridge ni le runtime.

## 20. Design system

La nouvelle UI utilise `PokeMapCard`, `Tooltip`, `MouseRegion` et `context.pokeMapColors`. Recherche `Color(` / `Colors.` / `0xFF` sur le fichier UI modifiee : sortie vide.

## 21. Tests ajoutés ou modifiés

Tests ajoutes dans `packages/map_editor/test/cinematic_builder_workspace_test.dart` :

- `resizes selected cinematic block duration from right handle`
- `shows right resize handle for selected editable authoring-owned block`
- `hides resize handle for non-owned block`
- `hides resize handle for marker draft`
- `dragging right handle decreases duration`
- `duration clamps to minimum`
- `duration clamps to maximum`
- `duration snaps to 100 ms increments`
- `left edge is not draggable`
- `hover details remain functional after resize`
- `keyboard navigation remains functional after resize`
- Visual Gate V1-69 conditionnee par `NS_SCENES_V1_69_CAPTURE_CINEMATIC_TIMELINE_DURATION_RESIZE`

## 22. Visual Gate

Capture produite :

```text
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_69_cinematic_timeline_duration_resize_handles_v0.png
```

Preuve fichier :

```text
-rw-r--r--  1 karim  staff  224491 Jun  3 23:21 reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_69_cinematic_timeline_duration_resize_handles_v0.png
PNG image data, 1663 x 926, 8-bit/color RGBA, non-interlaced
795a4363fb3f6f6f4b8692de6015826af01b8173b4510fc528722d9fb4f01995
```

## 23. Commandes exécutées

Commandes principales executees :

```bash
cd packages/map_editor && flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --plain-name 'resizes selected cinematic block duration from right handle'
cd packages/map_editor && flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --name 'right resize handle|non-owned block|marker draft|right handle decreases|duration clamps|duration snaps|left edge is not draggable|hover details remain functional after resize|keyboard navigation remains functional after resize'
cd packages/map_core && dart test --reporter=compact test/cinematic_authoring_operations_test.dart
cd packages/map_core && dart test --reporter=compact test/cinematic_timeline_time_layout_read_model_test.dart
cd packages/map_core && dart test --reporter=compact test/cinematic_timeline_lane_read_model_test.dart
cd packages/map_core && dart analyze
cd packages/map_editor && flutter test --reporter=compact test/cinematic_builder_workspace_test.dart
cd packages/map_editor && flutter test --reporter=compact test/cinematics_library_workspace_test.dart
cd packages/map_editor && flutter test --update-goldens --dart-define=NS_SCENES_V1_69_CAPTURE_CINEMATIC_TIMELINE_DURATION_RESIZE=true --reporter=compact test/cinematic_builder_workspace_test.dart
cd packages/map_editor && flutter analyze --no-fatal-infos lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart test/cinematic_builder_workspace_test.dart
cd packages/map_editor && flutter analyze
```

## 24. Résultats des tests

RED obligatoire obtenu avant implementation : le test ne trouvait aucun handle `cinematic-builder-duration-resize-handle-*`.

GREEN :

```text
Primary resize test: All tests passed!
V1-69 targeted group: 00:03 +10: All tests passed!
map_core authoring operations: 00:00 +34: All tests passed!
map_core time layout read model: 00:00 +4: All tests passed!
map_core lane read model: 00:00 +2: All tests passed!
Builder full suite: 00:10 +82: All tests passed!
Library suite: 00:04 +10: All tests passed!
Visual Gate suite: 00:13 +82: All tests passed!
```

## 25. Analyze

`map_core` :

```text
Analyzing map_core...
No issues found!
```

Analyse cible editor :

```text
Analyzing 2 items...
No issues found! (ran in 2.2s)
```

Analyse globale `map_editor` :

```text
344 issues found. (ran in 3.1s)
```

Les premieres erreurs sont dans les services Pokemon SDK (`pokemon_sdk_move_catalog_converter.dart`, `sync_pokemon_sdk_moves_catalog_use_case.dart`) et preexistent au lot.

## 26. Checks anti-scope

Sorties significatives :

```text
git diff --name-only -- packages/map_runtime packages/map_gameplay packages/map_battle examples
<vide>

anti-runtime rg
<vide>

anti-playback/timer rg
<vide>

anti-couleurs hardcodees rg
<vide>

anti-image IA rg
<vide>

anti-Selbrume code/test rg
<vide>
```

Les occurrences `seek`, `scrub`, `reorder` restantes sont uniquement des assertions negatives dans les tests. Les occurrences `startMs/endMs` sont dans l'affichage/read-model existant, pas dans un modele persiste.

## 27. Fichiers créés

```text
reports/narrativeStudio/scenes/ns_scenes_v1_69_cinematic_timeline_duration_resize_handles_v0.md
reports/narrativeStudio/scenes/ns_scenes_v1_69_evidence_pack.md
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_69_cinematic_timeline_duration_resize_handles_v0.png
```

## 28. Fichiers modifiés

```text
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
packages/map_editor/test/cinematic_builder_workspace_test.dart
reports/narrativeStudio/scenes/road_map_scenes.md
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
```

## 29. Roadmaps mises à jour

`road_map_scenes.md` passe V1-69 a DONE et recommande V1-70.

`road_map_scene_builder_authoring.md` passe V1-69 a DONE, ajoute V1-70 comme prochain lot exact et conserve V1-72 comme backlog scroll/visibility.

## 30. Limites connues

Le chemin `cancel` est implemente mais pas isole par un test widget dedie, car la synthese de cancel Flutter est plus fragile que le chemin drag/end. Le comportement est documente et le drag/end est largement couvert.

L'analyse globale `map_editor` reste rouge a cause d'une dette preexistante hors scope.

## 31. Non-objectifs confirmés

Non ajoutes : runtime cinematic, preview reelle, playback, seek runtime, scrubber runtime, timer, ticker, drag/drop de bloc, reorder, lane persistante, `startMs/endMs` persistants, image IA, donnees Selbrume, changement `map_core`.

## 32. Evidence Pack

Annexe : `reports/narrativeStudio/scenes/ns_scenes_v1_69_evidence_pack.md`.

## 33. Auto-review critique

Points positifs : le resize reutilise la mutation V1-68, les tests couvrent augmentation, diminution, min, max, snap, non-owned, marker, inspecteur, probe, transports, hover et clavier.

Risque surveille : les updates de drag appellent la mutation a chaque palier de 100 ms; cela reste acceptable en V0 sur une timeline locale, mais un lot futur peut debouncer si les projets deviennent tres longs.

## 34. Recommandation pour le prochain lot

Prochain lot exact recommande :

```text
NS-SCENES-V1-70 — Cinematic Timeline Duration Validation / Diagnostics Polish V0
```

Raison : V1-69 termine l'entree souris de duree. La suite utile est de polir les messages, les cas de clamp min/max, les diagnostics et le feedback no-code sans elargir le modele temporel.
