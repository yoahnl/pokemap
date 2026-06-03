# NS-SCENES-V1-68 — Cinematic Timeline Duration Inspector Editing V0

Date : 2026-06-03
Statut : DONE
Type : editor / authoring
Lot precedent : `NS-SCENES-V1-67 — Cinematic Timeline Duration Editing / Resize Prep Contract`
Prochain lot recommande : `NS-SCENES-V1-69 — Cinematic Timeline Duration Resize Handles V0`
Demande : lot lance par Karim via le prompt V1-68.

## Resume

V1-68 ajoute l'edition no-code de `durationMs` depuis l'inspecteur du Cinematic Builder pour les blocs authoring-owned supportes : `wait`, `fade`, `camera`, `actorFace` et `actorMove`.

Phrase canonique : V1-68 modifie seulement `durationMs`. V1-68 ne cree ni timeline libre, ni resize souris, ni playback.

## Gate 0

Commande executee depuis la racine avant toute modification V1-68 :

```bash
pwd
git branch --show-current
git status --short --untracked-files=all
git diff --stat
git diff --name-only
git log --oneline -n 15
```

Sortie utile :

```text
/Users/karim/Project/pokemonProject
main
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
df27cccb feat(narrative): add cinematic timeline selection cursor playhead placeholder v0 (NS-SCENES-V1-52)
```

Interpretation : `git status --short --untracked-files=all`, `git diff --stat` et `git diff --name-only` n'ont rien imprime. Le working tree etait propre avant V1-68.

## Implementation

- Ajout des bornes authoring dans `map_core` :
  - min 100 ms pour `wait`, `fade`, `camera`, `actorFace`;
  - min 200 ms pour `actorMove`;
  - max 30000 ms pour tous.
- Ajout du helper core `validateCinematicTimelineDurationMs(...)`, qui refuse duree vide/non entiere via l'UI et refuse aussi `NaN`, `Infinity`, decimal, sous-minimum et sur-maximum quand appele directement.
- Extension de `updateCinematicTimelineActorFacingStep(...)` avec `durationMs`, pour sortir `actorFace` du fallback visuel uniquement quand l'utilisateur choisit une duree explicite.
- Ajout du controle inspecteur `Duree` :
  - champ numerique en ms ;
  - presets `100`, `250`, `500`, `1000`, `1500`, `2000`, `3000` ;
  - boutons `-100 ms` / `+100 ms` bornes ;
  - validation inline sans mutation si la saisie est invalide.
- Apres une edition acceptee, le Builder preserve `selectedStepId` et efface `timelineProbeTimeMs` / `timelineProbeSnapHint`, ce qui ferme aussi l'aide/clear du probe.
- Les TextFields restent des zones de saisie locales ; les tests clavier existants continuent de proteger les raccourcis timeline.

## Tests RED

RED core :

```bash
cd packages/map_core && dart test test/cinematic_authoring_operations_test.dart
```

Echec attendu :

```text
Error: No named parameter with the name 'durationMs'.
Context: Found this candidate, but the arguments don't match.
CinematicTimelineStepUpdateResult updateCinematicTimelineActorFacingStep(
```

RED Flutter :

```bash
cd packages/map_editor && flutter test --plain-name "adds and edits wait fade and camera basic blocks" --reporter=compact test/cinematic_builder_workspace_test.dart
```

Echec attendu :

```text
Bad state: No element
WidgetController.ensureVisible
```

Interpretation : le champ `cinematic-builder-duration-ms-field` n'existait pas encore.

## Tests GREEN

Commandes executees :

```bash
cd packages/map_core && dart test test/cinematic_authoring_operations_test.dart
cd packages/map_core && dart analyze
cd packages/map_editor && flutter test --name "adds and edits wait fade and camera basic blocks|adds and edits actor facing with actor picker and direction|adds edits and removes actor movement authoring block|clears local time probe after accepted duration edit" --reporter=compact test/cinematic_builder_workspace_test.dart
cd packages/map_editor && flutter test --update-goldens --dart-define=NS_SCENES_V1_68_CAPTURE_CINEMATIC_TIMELINE_DURATION_INSPECTOR=true --reporter=compact test/cinematic_builder_workspace_test.dart
cd packages/map_editor && flutter analyze lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart lib/src/ui/canvas/narrative_workspace_canvas.dart test/cinematic_builder_workspace_test.dart test/cinematics_library_workspace_test.dart
cd packages/map_editor && flutter test --reporter=compact test/cinematic_builder_workspace_test.dart test/cinematics_library_workspace_test.dart
```

Resultats :

- Core authoring : `+34`, `All tests passed!`
- `map_core` analyze : `No issues found!`
- Flutter cibles V1-68 : `+4`, `All tests passed!`
- Visual Gate / suite Builder : `+70`, `All tests passed!`
- Analyse cible editor : `No issues found!`
- Builder + Library sans define : `+80`, `All tests passed!`

Commandes globales tentees :

```bash
cd packages/map_editor && flutter analyze
cd packages/map_editor && flutter test --reporter=compact
```

Resultats :

```text
344 issues found.
+2105 -18: Some tests failed.
```

Interpretation : echecs globaux preexistants/hors lot. `flutter analyze` reste rouge notamment sur `pokemon_sdk_move_catalog_converter.dart` et `sync_pokemon_sdk_moves_catalog_use_case.dart`. `flutter test` complet reste rouge sur des goldens hors lot, avec artefacts de failure V1-29/V1-35/Storylines generes puis nettoyes pour ne pas polluer le diff V1-68.

## Visual Gate

Commande demandee :

```bash
cd packages/map_editor && flutter test --update-goldens --dart-define=NS_SCENES_V1_68_CAPTURE_CINEMATIC_TIMELINE_DURATION_INSPECTOR=true --reporter=compact test/cinematic_builder_workspace_test.dart
```

Capture produite :

```text
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_68_cinematic_timeline_duration_inspector_editing_v0.png
```

Verification visuelle : le champ `700` ms est visible dans l'inspecteur, la selection actorFace est preservee, la timeline garde les proportions V1-56/V1-67, et les transports restent disabled.

## Checks anti-scope

Commande :

```bash
rg -n "onHorizontalDrag|onPanUpdate|Draggable|DragTarget|resize|Resize|startMs|endMs|currentTimeMs|playbackTimeMs|isPlaying|seek|scrub|scrubber|startPlayback|Timer\\(|AnimationController" <fichiers modifies>
```

Resultat utile :

- Les occurrences `startMs` / `endMs` sont celles du layout derive existant et des tests historiques.
- Les occurrences `onPanUpdate` sont celles du probe souris local V1-62, deja existantes.
- Les occurrences `resize`, `seek`, `scrub` dans les tests sont des assertions negatives ou le test historique qui garantit qu'un drag de bloc ne resize pas.
- Aucun nouveau playback, seek runtime, scrubber runtime, drag de bloc, resize handle, `currentTimeMs`, `playbackTimeMs`, `isPlaying`, timer runtime ou `AnimationController`.

Commande couleurs :

```bash
rg -n "Color\\(0x|Colors\\." packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
```

Resultat : aucune occurrence. Les nouveaux styles utilisent `context.pokeMapColors` et les widgets design-system.

## Fichiers modifies

- `packages/map_core/lib/src/authoring/cinematic_authoring_operations.dart`
- `packages/map_core/test/cinematic_authoring_operations_test.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart`
- `packages/map_editor/test/cinematic_builder_workspace_test.dart`
- `packages/map_editor/test/cinematics_library_workspace_test.dart`
- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`

## Fichiers crees

- `reports/narrativeStudio/scenes/ns_scenes_v1_68_cinematic_timeline_duration_inspector_editing_v0.md`
- `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_68_cinematic_timeline_duration_inspector_editing_v0.png`

## Limites

- Pas de resize souris : ce sera V1-69.
- Pas de drag/reorder de bloc, pas de changement de lane.
- Pas de playback, seek runtime, scrubber runtime ou preview runtime.
- Pas de persistance `startMs` / `endMs`; ces valeurs restent derivees par le read model.
- Les blocs non authoring-owned restent non editables.

## Etat git final observe

```text
 M packages/map_core/lib/src/authoring/cinematic_authoring_operations.dart
 M packages/map_core/test/cinematic_authoring_operations_test.dart
 M packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
 M packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart
 M packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
 M packages/map_editor/test/cinematic_builder_workspace_test.dart
 M packages/map_editor/test/cinematics_library_workspace_test.dart
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
 M selbrume/project.json
?? reports/narrativeStudio/scenes/ns_scenes_v1_68_cinematic_timeline_duration_inspector_editing_v0.md
?? reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_68_cinematic_timeline_duration_inspector_editing_v0.png
```

Note : `selbrume/project.json` est apparu modifie pendant la session, hors patch V1-68. Le diff ajoute des acteurs/cibles/steps sur `cinematic_uwu`. Il est laisse intact car il peut provenir d'une sauvegarde applicative externe.

## Verdict

V1-68 est DONE. Le Builder permet maintenant d'editer `durationMs` depuis l'inspecteur de facon no-code et bornee, avec validation core, Visual Gate, tests cibles et roadmaps mises a jour.
