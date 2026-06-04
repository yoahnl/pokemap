# NS-SCENES-V1-70 — Cinematic Timeline Duration Validation / Diagnostics Polish V0

## 1. Résumé exécutif

V1-70 est implemente a la demande de Karim via le prompt du lot. Le Cinematic Builder rend maintenant les regles de duree comprehensibles : bornes min/max visibles, pas de 100 ms explicite, erreurs inline plus claires, feedback compact quand une duree atteint une borne et explication honnete des blocs non editables.

La timeline ne gagne aucune nouvelle puissance : `durationMs` reste la seule valeur temporelle persistante, `startMs/endMs` restent derives, les transports restent disabled et aucun playback/seek/scrub/runtime n'est ajoute.

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
875404af feat(narrative): add cinematic timeline duration resize handles v0 (NS-SCENES-V1-69)
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
```

Le working tree etait propre au Gate 0.

## 3. Fichiers lus

Instructions et prompt : `AGENTS.md`, `agent_rules.md`, `skills/README.md`, `skills/test-driven-development/SKILL.md`, `skills/verification-before-completion/SKILL.md`, prompt V1-70.

Roadmaps et rapports : `reports/narrativeStudio/scenes/road_map_scenes.md`, `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`, rapports/evidence packs V1-69, rapport V1-68 et rapport V1-67.

Core : `cinematic_diagnostics.dart`, `cinematic_authoring_operations.dart`, read models timeline time/lane et tests associes.

Editor : `cinematic_builder_workspace.dart`, `cinematic_builder_workspace_test.dart`, `cinematics_library_workspace_test.dart`.

## 4. Design Gate — Cinematic Timeline Duration Validation / Diagnostics Polish V0

1. V1-68 fournit edition inspecteur, presets, +/-100, validation et clear probe ; V1-69 fournit resize droit, snap 100 ms, clamp min/max, selectedStepId preserve et transports disabled.
2. Les messages trop peu clairs etaient `Saisissez une durée en ms.`, `Durée numérique requise.` et `Minimum : X ms.`, plus l'absence d'aide min/max/pas.
3. L'aide min/max/pas vit dans la section `Durée`, juste sous le titre, avant le champ.
4. Wording wait/fade/camera/actorFace : `Bornes : 100–30000 ms · pas 100 ms`.
5. Wording actorMove : `Bornes : 200–30000 ms · pas 100 ms`.
6. Saisie vide : `Saisis une durée en millisecondes.`
7. Saisie non entiere : `Utilise un nombre entier de millisecondes.`
8. Sous minimum : `Minimum pour ce bloc : X ms.`
9. Au-dessus maximum : `Maximum : 30000 ms.`
10. Feedback clamp resize : `Minimum atteint : X ms` ou `Maximum atteint : 30000 ms`.
11. Le feedback clamp est local dans les controles de duree de l'inspecteur.
12. Bloc non editable : `Durée non éditable — bloc en lecture seule.` ; marker draft : `Durée non éditable — brouillon sans effet moteur.`
13. Oui, diagnostics core renforces pour durees persistentes invalides.
14. Les fallbacks volontaires sans `durationMs` ne sont pas diagnostiques ; seuls les `durationMs` persistants invalides le sont, sauf actorMove qui a son contrat authoring propre.
15. Les diagnostics reutilisent les constantes et `validateCinematicTimelineDurationMs` est verrouille par test.
16. Le resize V1-69 est preserve : meme handle droit, memes callbacks, meme clamp et meme clear probe.
17. L'inspecteur V1-68 est preserve : champ, presets et boutons gardent les memes callbacks.
18. Le probe souris est preserve : invalide ne le clear pas ; mutation acceptee via edition/resize le clear comme avant.
19. Hover/help/navigation/transports restent couverts par la suite Builder existante et les tests V1-69 conserves.
20. Aucun `startMs/endMs` persiste : pas de modele modifie, checks anti-scope et tests JSON existants.
21. Pas de timeline libre : aucun drag de bloc, lane persistante, reorder ou overlap authorable.
22. Pas de playback : aucun timer/ticker/isPlaying/currentTimeMs/playbackTimeMs.
23. Visual Gate : `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_70_cinematic_timeline_duration_validation_diagnostics_polish_v0.png`.
24. Prochain lot exact recommande : `NS-SCENES-V1-71 — Cinematic Stage / Map Context Prep Contract`.

## 5. Scope réalisé

V1-70 ajoute le polish UX duration dans l'inspecteur, renforce les diagnostics core duree et ajoute les tests widget/core associes.

## 6. Problème UX après V1-69

Apres V1-69, la duree etait editable et redimensionnable, mais les bornes, le pas et la raison des refus n'etaient pas assez explicites. V1-70 corrige cette lecture no-code sans toucher au modele temporel.

## 7. Aide min/max/pas 100 ms

L'inspecteur affiche `Bornes : 100–30000 ms · pas 100 ms` pour les blocs editables standard et `Bornes : 200–30000 ms · pas 100 ms` pour `actorMove`.

## 8. Messages d’erreur de saisie

Les erreurs inline sont maintenant :

```text
Saisis une durée en millisecondes.
Utilise un nombre entier de millisecondes.
Minimum pour ce bloc : 100 ms.
Minimum pour ce bloc : 200 ms.
Maximum : 30000 ms.
```

Une saisie invalide ne mute pas `ProjectManifest`, ne change pas `durationMs` et preserve la selection.

## 9. Feedback min/max resize

Quand la duree courante arrive a une borne, l'inspecteur affiche localement :

```text
Minimum atteint : 100 ms
Minimum atteint : 200 ms
Maximum atteint : 30000 ms
```

Le feedback repose sur la valeur selectionnee apres edition ou resize ; pas de snackbar, toast, modal ou timer.

## 10. Blocs non éditables

Les marker drafts sans effet moteur affichent `Durée non éditable — brouillon sans effet moteur.`. Les blocs non-owned ou non geres par le Builder V0 affichent `Durée non éditable — bloc en lecture seule.`. Les handles restent absents sur ces blocs.

## 11. Diagnostics core durée

`diagnoseCinematicAsset` verifie maintenant les durees persistentes authoring-owned avec les bornes authoring :

- blocs basic/actorFace : `100..30000 ms` ;
- actorMove : `200..30000 ms` ;
- autres steps avec duree non authoring : non negatif seulement, pour ne pas casser les fallbacks visuels volontaires.

## 12. Relation avec V1-68

L'edition inspecteur V1-68 reste la source UI principale. Les callbacks, presets et increments existants sont conserves.

## 13. Relation avec V1-69

Le resize droit V1-69 reste borne et lisible. V1-70 ajoute seulement l'explication visible du clamp.

## 14. Relation avec probe / hover / aides / transports

Une saisie invalide ne clear pas le probe. Une mutation acceptee continue de clear le probe. Hover details, aide clavier, aide repere et transports disabled restent couverts par la suite Builder.

## 15. Restrictions anti-timeline libre / anti-playback / anti-runtime

Confirme : pas de `map_runtime`, pas de `map_gameplay`, pas de `map_battle`, pas d'examples, pas de playback/timer/transport fonctionnel, pas de seek/scrub, pas de drag/reorder, pas de nouvelle persistance temporelle.

## 16. Legacy bridge policy inchangée

Les bridges legacy restent hors Builder canonique. V1-70 ne modifie pas les policies de bridge cinematic.

## 17. Design system

La nouvelle UI reutilise les widgets existants et `context.pokeMapColors`. Recherche `Color(` / `Colors.` / `0xFF` / `0xff` sur les fichiers UI modifies : sortie vide.

## 18. Tests ajoutés ou modifiés

Core :

- `diagnoses wait duration below minimum`
- `diagnoses actorMove duration below minimum`
- `diagnoses duration above maximum`
- `does not diagnose missing duration when fallback is allowed`
- `does not diagnose marker draft without duration as duration error`
- `diagnostics use the same bounds as authoring validation`

Editor :

- `shows duration validation guidance and rejects invalid duration without mutation`
- `shows actorMove specific minimum duration guidance`
- `shows maximum duration guidance`
- `shows non editable duration reason for marker draft`
- `shows non editable duration reason for non-owned step`
- `shows inline error for empty duration input`
- `shows inline error for non integer duration input`
- `shows inline error above maximum`
- `shows resize minimum clamp feedback`
- `shows resize maximum clamp feedback`
- Visual Gate V1-70

## 19. Visual Gate

Capture produite :

```text
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_70_cinematic_timeline_duration_validation_diagnostics_polish_v0.png
```

Preuve fichier :

```text
-rw-r--r--  1 karim  staff  224570 Jun  4 00:26 reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_70_cinematic_timeline_duration_validation_diagnostics_polish_v0.png
PNG image data, 1663 x 926, 8-bit/color RGBA, non-interlaced
5e9841cc0e31be8dcf2b03f6c5303a74c8a4e0aadc863d885b5065955bfc9cfc
```

## 20. Commandes exécutées

Commandes principales :

```bash
cd packages/map_editor && flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --plain-name 'shows duration validation guidance and rejects invalid duration without mutation'
cd packages/map_editor && flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --name 'duration validation guidance|actorMove specific minimum|maximum duration guidance|non editable duration reason|inline error|resize minimum clamp feedback|resize maximum clamp feedback'
cd packages/map_core && dart test --reporter=compact test/cinematic_diagnostics_test.dart
cd packages/map_core && dart test --reporter=compact test/cinematic_authoring_operations_test.dart
cd packages/map_core && dart test --reporter=compact test/cinematic_timeline_time_layout_read_model_test.dart
cd packages/map_core && dart test --reporter=compact test/cinematic_timeline_lane_read_model_test.dart
cd packages/map_core && dart analyze
cd packages/map_editor && flutter test --reporter=compact test/cinematic_builder_workspace_test.dart
cd packages/map_editor && flutter test --reporter=compact test/cinematics_library_workspace_test.dart
cd packages/map_editor && flutter test --update-goldens --dart-define=NS_SCENES_V1_70_CAPTURE_CINEMATIC_TIMELINE_DURATION_VALIDATION=true --reporter=compact test/cinematic_builder_workspace_test.dart
cd packages/map_editor && flutter analyze --no-fatal-infos lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart test/cinematic_builder_workspace_test.dart
cd packages/map_editor && flutter analyze
```

## 21. Résultats des tests

Tests verts :

```text
map_editor targeted V1-70: 00:04 +10: All tests passed!
map_editor builder full: 00:13 +93: All tests passed!
map_editor library: 00:04 +10: All tests passed!
map_editor Visual Gate: 00:13 +93: All tests passed!
map_core diagnostics: 00:00 +19: All tests passed!
map_core authoring operations: 00:00 +34: All tests passed!
map_core time layout: 00:00 +4: All tests passed!
map_core lane read model: 00:00 +2: All tests passed!
```

## 22. Analyze

Analyse core :

```text
Analyzing map_core...
No issues found!
```

Analyse cible editor :

```text
Analyzing 2 items...
No issues found! (ran in 1.8s)
```

Analyse globale editor :

```text
Analyzing map_editor...
344 issues found. (ran in 3.1s)
```

La sortie globale reste rouge sur dette preexistante hors lot, notamment `pokemon_sdk_move_catalog_converter.dart` et `sync_pokemon_sdk_moves_catalog_use_case.dart`.

## 23. Checks anti-scope

Resultats :

```text
git diff --name-only -- packages/map_runtime packages/map_gameplay packages/map_battle examples
<vide>

anti-runtime
<vide>

anti-playback / timer / transport fonctionnel
<vide>

anti-seek/scrubber runtime
packages/map_editor/test/cinematic_builder_workspace_test.dart:1489:    expect(find.text('seek'), findsNothing);
packages/map_editor/test/cinematic_builder_workspace_test.dart:1490:    expect(find.text('scrub'), findsNothing);

anti-drag de bloc / timeline libre
packages/map_editor/test/cinematic_builder_workspace_test.dart:1807:  testWidgets('snap chooses nearest semantic target when boundaries overlap',
packages/map_editor/test/cinematic_builder_workspace_test.dart:2074:  testWidgets('dragging a timeline block does not move or resize it',
packages/map_editor/test/cinematic_builder_workspace_test.dart:2109:    expect(find.text('reorder'), findsNothing);

anti-couleurs hardcodees
<vide>

anti-image IA
<vide>

anti-Selbrume
<vide>
```

Les occurrences `seek/scrub/reorder` sont des assertions negatives existantes.

## 24. Fichiers créés

```text
reports/narrativeStudio/scenes/ns_scenes_v1_70_cinematic_timeline_duration_validation_diagnostics_polish_v0.md
reports/narrativeStudio/scenes/ns_scenes_v1_70_evidence_pack.md
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_70_cinematic_timeline_duration_validation_diagnostics_polish_v0.png
```

## 25. Fichiers modifiés

```text
packages/map_core/lib/src/diagnostics/cinematic_diagnostics.dart
packages/map_core/test/cinematic_diagnostics_test.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
packages/map_editor/test/cinematic_builder_workspace_test.dart
reports/narrativeStudio/scenes/road_map_scenes.md
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
```

## 26. Roadmaps mises à jour

`road_map_scenes.md` et `road_map_scene_builder_authoring.md` marquent V1-70 DONE et recommandent V1-71 comme prochain lot exact.

## 27. Limites connues

`flutter analyze` global `map_editor` reste rouge sur dette Pokemon SDK hors lot. Aucune correction hors scope n'a ete faite.

## 28. Non-objectifs confirmés

Pas de nouveau bloc cinematic, pas de dialogue/FX/son, pas de map context, pas de actor binding map, pas de preview reelle, pas de playback, pas de timer, pas de transport fonctionnel, pas de drag/reorder, pas de timeline libre, pas de `startMs/endMs` persistants, pas de runtime/gameplay/battle/examples, pas d'image IA.

## 29. Evidence Pack

Annexe creee : `reports/narrativeStudio/scenes/ns_scenes_v1_70_evidence_pack.md`.

## 30. Auto-review critique

1. map_runtime modifie ? Non.
2. map_gameplay/map_battle/examples modifies ? Non.
3. Modele JSON modifie ? Non.
4. build_runner lance ? Non.
5. Playback ajoute ? Non.
6. Timer ajoute ? Non.
7. isPlaying/currentTimeMs/playbackTimeMs ajoutes ? Non.
8. Seek runtime ajoute ? Non.
9. Scrubber runtime ajoute ? Non.
10. Transport controls fonctionnels ? Non.
11. Drag de bloc ajoute ? Non.
12. Resize supplementaire ajoute ? Non.
13. Reorder ajoute ? Non.
14. startMs/endMs persistants ajoutes ? Non.
15. Bornes V1-68 changees ? Non.
16. Pas 100 ms V1-69 change ? Non.
17. Aide min/max visible ? Oui.
18. Erreurs de saisie claires ? Oui.
19. Feedback clamp resize clair ? Oui.
20. Blocs non editables expliques ? Oui.
21. Diagnostics core duree coherents ? Oui.
22. Resize V1-69 fonctionnel ? Oui.
23. Inspecteur V1-68 fonctionnel ? Oui.
24. Hover/probe/aides/transports preserves ? Oui.
25. Design system respecte ? Oui.
26. Visual Gate probante ? Oui.
27. Evidence Pack complet ? Oui.
28. Prochain lot recommande ? `NS-SCENES-V1-71 — Cinematic Stage / Map Context Prep Contract`.

## 31. Recommandation pour le prochain lot

`NS-SCENES-V1-71 — Cinematic Stage / Map Context Prep Contract`

Objectif : cadrer map cible, decor, acteurs, bindings, positions initiales et cibles map-aware avant toute preview cinematic reelle.
