# NS-SCENES-V1-52 — Cinematic Timeline Selection Cursor / Playhead Placeholder V0

Date : 2026-06-02
Statut propose : DONE
Lot precedent : `NS-SCENES-V1-51 — Cinematic Timeline Time Axis / Bar Layout V0`
Prochain lot recommande : `NS-SCENES-V1-53 — Cinematic Timeline Transport Controls Placeholder V0`

## 1. Resume executif

V1-52 ajoute une aiguille de selection dans la timeline temporelle du Cinematic Builder.

Le curseur est strictement derive de la selection courante et du time layout V1-51 : `selectedStepId` permet de retrouver le `CinematicTimelineTimeBlock`, puis `selectedBlock.startMs` positionne une ligne verticale dans le contenu scrollable.

V1-52 ajoute un repere visuel. V1-52 ne lance pas l'horloge.

Evidence Pack : `reports/narrativeStudio/scenes/ns_scenes_v1_52_evidence_pack.md`.

## 2. Gate 0

Gate 0 execute avant les edits V1-52 :

- repo : `/Users/karim/Project/pokemonProject`
- branche : `main`
- working tree propre avant edits V1-52
- dernier commit : `8ce1a417 feat(narrative): add cinematic actor movement inspector polish and timeline time axis bar layout v0 (NS-SCENES-V1-50-V1-51)`

Sorties exactes dans l'Evidence Pack.

## 3. Fichiers lus

- `AGENTS.md`
- `agent_rules.md`
- `skills/README.md`
- `skills/using-superpowers/SKILL.md`
- `skills/writing-plans/SKILL.md`
- `skills/test-driven-development/SKILL.md`
- `skills/verification-before-completion/SKILL.md`
- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_50_cinematic_actor_movement_inspector_polish_target_labels_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_51_cinematic_timeline_time_axis_bar_layout_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_51_evidence_pack.md`
- `packages/map_core/lib/src/read_models/cinematic_timeline_time_layout_read_model.dart`
- `packages/map_core/lib/src/read_models/cinematic_timeline_lane_read_model.dart`
- `packages/map_core/lib/src/models/cinematic_asset.dart`
- `packages/map_core/lib/map_core.dart`
- `packages/map_core/test/cinematic_timeline_time_layout_read_model_test.dart`
- `packages/map_core/test/cinematic_timeline_lane_read_model_test.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart`
- `packages/map_editor/test/cinematic_builder_workspace_test.dart`
- `packages/map_editor/test/cinematics_library_workspace_test.dart`

## 4. Design Gate — Cinematic Timeline Selection Cursor / Playhead Placeholder V0

1. Le curseur reste calcule cote editor : le read model V1-51 expose deja `blocks` et `startMs`.
2. Aucun helper core n'est ajoute : la logique est un lookup prive simple, sans contrat public supplementaire.
3. `startMs` est recupere via `_selectedTimeBlock(timeLayout, selectedStepId)`.
4. Sans selection, aucun badge et aucun curseur ne sont affiches.
5. Si le step selectionne n'existe plus, le reset existant de `_selectedStepId` reste la source de comportement ; le lookup retourne aussi `null`.
6. Le curseur s'aligne sur `startMs`, pas sur le centre ni `endMs`.
7. `startMs` est retenu car il indique le debut logique stable du bloc selectionne, sans notion de progression runtime.
8. Le mapping pixels utilise le `pixelsPerMs` existant : `contentWidth / totalDurationMs`, borne par `_tickLeft`.
9. Le curseur est affiche via `IgnorePointer`, donc non draggable et non cliquable.
10. L'axe n'a aucun handler de tap ; le test prouve qu'un tap axe ne change pas la selection.
11. Le badge s'appelle par exemple `Selection : 500 ms` ou `Selection : 1.1 s` et ne promet aucun playback.
12. La preview sandbox reste synchronisee par le step selectionne existant.
13. L'inspecteur reste synchronise par le step selectionne existant.
14. Les actions authoring existantes gardent `_selectedStepId` comme avant.
15. Aucun play/pause/stop fonctionnel n'est ajoute.
16. Aucun transport control n'est ajoute dans ce lot.
17. Aucune preview runtime n'est ajoutee.
18. Les tests couvrent absence initiale de curseur, affichage apres selection, alignement start, deplacement sur autre bloc et tap axe sans seek.
19. Visual Gate : screenshot V1-52 en 1663x926.
20. Prochain lot recommande : `NS-SCENES-V1-53 — Cinematic Timeline Transport Controls Placeholder V0`.

## 5. Scope realise

- Badge temporel `Selection : 500 ms` / `Selection : 1.1 s` dans le header de timeline.
- Ligne verticale alignee sur le debut du bloc selectionne.
- Handle decoratif non interactif.
- Curseur masque quand aucune selection n'existe.
- Selection par barre preservee.
- Tap sur axe sans seek.
- Preview sandbox et inspecteur preserves.
- Visual Gate V1-52.
- Roadmaps mises a jour.

## 6. Contrat du curseur V0

Le curseur V0 est un repere visuel authoring :

- derive ;
- local au Builder ;
- non interactif ;
- non persiste ;
- non runtime.

Il ne cree pas `cursorTimeMs`, `playheadTimeMs` ou position courante runtime.

## 7. Calcul du temps selectionne

Contrat implemente :

```text
selectedStepId + timeLayout.blocks -> selectedBlock
selectedBlock.startMs -> badge + cursor x
null -> pas de badge, pas de curseur
```

Le helper prive `_selectedTimeBlock` ne mute rien et n'ajoute aucun modele core.

## 8. UI Cursor / Playhead Placeholder

Le contenu horizontal de la timeline est rendu en `Stack` :

- la colonne axe + lanes reste le contenu principal ;
- le curseur est un overlay `IgnorePointer` ;
- la ligne verticale traverse l'axe et les lanes visibles ;
- le handle est decoratif.

## 9. Badge de selection temporelle

Le badge utilise le libelle :

```text
Selection : 500 ms
```

Il reutilise `_shortTimeLabel`, donc `500 ms`, `1.1 s`, etc. Aucun texte `Lecture`, `Playback`, `Scrubber`, `Temps courant` ou `Position runtime` n'est ajoute.

## 10. Synchronisation preview / inspecteur

La preview sandbox et l'inspecteur restent synchronises via le step selectionne existant. V1-52 n'ajoute pas de champ editable ni de position timeline dans l'inspecteur.

## 11. Compatibilite V1-51

V1-51 reste intact :

- axe temporel visible ;
- ticks visibles ;
- barres proportionnelles ;
- fallback visuel ;
- selection depuis barre ;
- timeline non editable.

## 12. Restrictions anti-playback / anti-scrub

Confirme :

- pas de seek ;
- pas de scrubber ;
- pas de timer ;
- pas de playback ;
- pas de transport fonctionnel ;
- pas de drag cursor ;
- pas de drag/drop blocs ;
- pas de resize ;
- pas de reorder ;
- pas de preview runtime.

## 13. Legacy bridge policy inchangee

Les bridges legacy restent exclus du Builder canonique. V1-52 ne modifie pas `ScenarioAsset` et ne demarre aucune migration.

## 14. Design system

La UI ajoutee utilise uniquement les tokens et primitives existants :

- `context.pokeMapColors`
- `PokeMapBadge`
- `PokeMapPanel`
- `PokeMapCard`

Recherche couleurs hardcodees sur les fichiers UI modifies : sortie vide.

## 15. Tests ajoutes ou modifies

Modifie :

- `packages/map_editor/test/cinematic_builder_workspace_test.dart`

Tests ajoutes :

- `shows a non-interactive selection cursor on selected block start`
- `captures V1-52 timeline selection cursor when requested`

Le test principal couvre :

- pas de badge/curseur sans selection ;
- selection du bloc `step_face` ;
- badge `Selection : 500 ms` ;
- handle visible ;
- curseur aligne sur le bord du bloc selectionne ;
- deplacement du curseur vers `step_move` ;
- badge `Selection : 1.1 s` ;
- tap axe sans changement de selection ;
- absence des libelles `Playback`, `Lecture`, `Scrubber` ;
- non-mutation du projet.

## 16. Visual Gate

Capture :

```text
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_52_cinematic_timeline_selection_cursor_playhead_placeholder_v0.png
```

Preuve image :

```text
PNG 1663 x 926
SHA1 d9c7d17554a2023876f945cb153a89e85881046d
SHA256 a7b0a8b6b99e616f14d516f5e07f9262b40703f15edcd7077bea8ecc0cada72b
```

La capture montre le Builder, la palette, la preview sandbox, la timeline avec barres, le badge `Selection : 500 ms`, le curseur vertical, le handle decoratif et l'inspecteur synchronise.

## 17. Commandes executees

Voir l'Evidence Pack pour les sorties.

Commandes principales :

- `dart test test/cinematic_timeline_time_layout_read_model_test.dart`
- `dart test test/cinematic_timeline_lane_read_model_test.dart`
- `dart analyze`
- `flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --plain-name 'shows a non-interactive selection cursor on selected block start'`
- `flutter test --reporter=compact test/cinematic_builder_workspace_test.dart`
- `flutter test --reporter=compact test/cinematics_library_workspace_test.dart`
- `flutter analyze --no-fatal-infos lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart test/cinematic_builder_workspace_test.dart test/cinematics_library_workspace_test.dart`
- `flutter test --update-goldens --dart-define=NS_SCENES_V1_52_CAPTURE_CINEMATIC_TIMELINE_SELECTION_CURSOR=true --reporter=compact test/cinematic_builder_workspace_test.dart`

## 18. Resultats des tests

Tous les tests cibles relances passent :

- core time layout : `+4`
- core lane read model : `+2`
- builder : `+28`
- library : `+10`

## 19. Analyze

- `map_core` : `No issues found!`
- `map_editor` cible : `No issues found! (ran in 1.1s)`

## 20. Checks anti-scope

Checks documentes dans l'Evidence Pack :

- pas de modification `map_runtime`, `map_gameplay`, `map_battle`, `examples` ;
- aucun runtime dans le code modifie ;
- aucun playback/seek/scrubber/timer dans le code modifie ;
- aucun drag cursor, drag/drop bloc, resize ou reorder ajoute ;
- aucune couleur hardcodee dans les fichiers UI modifies ;
- aucune donnee Selbrume/Mael/Lysa/Port des Brisants dans le code modifie ;
- aucune persistance `cursorTimeMs`/`playheadTimeMs`.

## 21. Fichiers crees

- `reports/narrativeStudio/scenes/ns_scenes_v1_52_cinematic_timeline_selection_cursor_playhead_placeholder_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_52_evidence_pack.md`
- `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_52_cinematic_timeline_selection_cursor_playhead_placeholder_v0.png`

## 22. Fichiers modifies

- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart`
- `packages/map_editor/test/cinematic_builder_workspace_test.dart`
- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`

## 23. Roadmaps mises a jour

- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`

Elles marquent V1-52 DONE et recommandent V1-53.

## 24. Limites connues

- Le curseur n'est pas un playback.
- Le curseur n'est pas draggable.
- L'axe ne permet pas de seek.
- Aucun transport n'est ajoute.
- La preview reste sandbox.

## 25. Non-objectifs confirmes

Non faits : runtime, playback, timer, transport fonctionnel, scrubber, seek, drag/drop, resize, reorder, keyframes, zoom, minimap, pathfinding, coordonnees libres, persistence cursor/playhead/start/end, dialogue/FX/Son authorable, migration legacy, donnees Selbrume.

## 26. Evidence Pack

Annexe : `reports/narrativeStudio/scenes/ns_scenes_v1_52_evidence_pack.md`.

## 27. Auto-review critique

Voir l'Evidence Pack. Verdict : V1-52 est couvert par TDD RED/GREEN, test widget dedie, tests core/editor de non-regression, analyze, Visual Gate et checks anti-scope. Le lot reste une aiguille de selection, pas une horloge.

## 28. Recommandation pour le prochain lot

Un seul prochain lot exact :

```text
NS-SCENES-V1-53 — Cinematic Timeline Transport Controls Placeholder V0
```

Objectif : ajouter des controles visuels reset/play/stop placeholder, non fonctionnels runtime, sans playback, timer, seek, scrubber ni preview reelle.
