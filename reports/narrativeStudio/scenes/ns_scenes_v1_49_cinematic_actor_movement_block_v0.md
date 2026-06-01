# NS-SCENES-V1-49 — Cinematic Actor Movement Block V0

Date : 2026-06-01  
Statut propose : DONE  
Lot precedent : `NS-SCENES-V1-48 — Cinematic Timeline Lane Grouping V0`  
Prochain lot propose : `NS-SCENES-V1-50 — Cinematic Actor Movement Inspector Polish / Target Labels V0`

## 1. Resume

Le lot rend `actorMove` authorable dans le Cinematic Builder V0, avec un contrat volontairement borne : acteur requis, cible authoring stable, duree positive, mode `walk` ou `run`, et `pathMode=direct` verrouille. Il n'ajoute ni pathfinding, ni coordonnees libres, ni preview runtime.

## 2. Gate 0

Commande : `pwd`  
Resultat : `/Users/karim/Project/pokemonProject`

Commande : `git branch --show-current`  
Resultat : `main`

Commande : `git status --short --untracked-files=all` avant edits  
Resultat : sortie vide.

Commande : `git diff --stat` avant edits  
Resultat : sortie vide.

Commande : `git diff --name-only` avant edits  
Resultat : sortie vide.

Commande : `git log --oneline -n 15` avant edits

```text
77d12c69 feat(narrative): add cinematic timeline lane grouping v0 (NS-SCENES-V1-48)
aaa9028f feat(narrative): add cinematic actor movement block v0 prep contract (NS-SCENES-V1-47)
7a4404f6 feat(narrative): add cinematic actor references actor facing v0 (NS-SCENES-V1-46)
c68990a7 feat(narrative): add cinematic wait fade camera basic blocks evidence closure (NS-SCENES-V1-45-BIS)
88cb3a54 feat(narrative): add cinematic wait fade camera basic blocks v0 (NS-SCENES-V1-45)
6e66a66d feat(narrative): add cinematic timeline authoring drafts evidence closure (NS-SCENES-V1-44-BIS)
eb0ea9b6 feat(narrative): add cinematic timeline authoring drafts v0 (NS-SCENES-V1-44)
2805560d feat(narrative): add cinematic timeline read-only step inspector evidence closure (NS-SCENES-V1-43-BIS)
6c3b1074 feat(narrative): add cinematic timeline read-only step inspector v0 (NS-SCENES-V1-43)
e95290ce feat(narrative): add cinematic builder v0 shell evidence closure (NS-SCENES-V1-42-BIS)
c9d44fc8 feat(narrative): add cinematic builder v0 shell (NS-SCENES-V1-42)
38f09efa feat(narrative): add cinematic builder v0 scope and runtime playback contract (NS-SCENES-V1-41)
9e1d45d9 feat(narrative): add cinematic runtime adapter v0 bis evidence closure (NS-SCENES-V1-40)
b39d596f feat(narrative): add cinematic runtime adapter v0 (NS-SCENES-V1-40)
eadb0052 chore(reports): add missing screenshot for V1-15 wire anchor color code
```

## 3. Instructions lues

- `AGENTS.md`
- `agent_rules.md`
- `skills/README.md`
- `pokemap_roadmap_mecaniques_fangame.md`
- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_47_cinematic_actor_movement_block_v0_prep_contract.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_48_cinematic_timeline_lane_grouping_v0.md`
- Piece jointe utilisateur : `/Users/karim/.codex/attachments/6f40827f-e91f-494a-999f-074e2db553bd/pasted-text.txt`

## 4. Scope V1-49

Inclus :

- cible de deplacement authoring stable dans `CinematicAsset`;
- operations pures cible add/update/remove;
- operations pures add/update `actorMove`;
- diagnostics acteur/cible/duree/modes;
- projection timeline lane enrichie;
- palette Builder avec section cibles;
- bloc `Déplacement acteur` active seulement si acteur + cible existent;
- inspecteur acteur/cible/duree/marche-course/direct;
- Visual Gate.

Exclus :

- pathfinding;
- coordonnees `x/y`;
- cible map/entity runtime;
- drag/drop;
- reorder;
- preview runtime;
- edition avancee des labels cible dans l'inspecteur;
- donnees Selbrume.

## 5. Reponses Design Gate 21

1. `CinematicTimelineStepKind.actorMove` existait deja.
2. Aucun contrat cible authoring stable n'existait dans `CinematicAsset`; seul `targetId` generique existait sur les steps.
3. Un modele `CinematicMovementTargetRef` a ete ajoute.
4. Les cibles vivent dans `CinematicAsset.movementTargets`, car elles appartiennent au contrat authoring cinematic, pas au layout de timeline ni au runtime.
5. Le JSON change avec un champ optionnel `movementTargets`; absence et `null` restent compatibles vers `[]`.
6. Aucun `build_runner` n'est necessaire : les modeles Cinematic sont manuels.
7. Aucun champ `x`, `y`, coordonnees ou position libre n'est ajoute.
8. Aucun lien `MapEntity`, event runtime ou map picker n'est ajoute.
9. `targetId` est valide contre `movementTargets`.
10. `actorId` est valide contre `requiredActors`.
11. Le bloc est authoring-owned via metadata source/kind/block et helpers.
12. Cles metadata : `authoring.source`, `authoring.kind`, `authoring.block`, `actor.movementMode`, `actor.pathMode`.
13. Champs authorables : `actorId`, `targetId`, `durationMs`, `movementMode`.
14. `pathMode` est `direct` et verrouille.
15. Le read model V1-48 place `actorMove` dans la lane acteur derivee de `actorId` et ajoute badges cible/mode/direct.
16. L'inspecteur update acteur/cible/duree/movementMode par boutons/pickers.
17. Le path mode est affiche comme direct verrouille.
18. Aucun pathfinding n'est branche : metadata direct seulement, aucun resolver.
19. La preview reste sandbox; aucun bouton preview jouable n'est active.
20. La non-regression V1-48 est couverte par tests lane, Builder et Library.
21. Visual Gate : `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_49_cinematic_actor_movement_block_v0.png`.

## 6. Modele et JSON

`CinematicAsset` porte maintenant :

- `movementTargets: List<CinematicMovementTargetRef>`;
- default `[]` quand le champ est absent;
- roundtrip JSON de `targetId`, `label`, `description`;
- equality/hash mis a jour.

`CinematicMovementTargetRef` est volontairement minimal :

- `targetId`;
- `label`;
- `description`;
- pas de position;
- pas de reference runtime.

## 7. Operations Core

Operations cible :

- `addCinematicMovementTarget`;
- `updateCinematicMovementTarget`;
- `removeCinematicMovementTarget`;
- `findCinematicMovementTargetById`.

Operations bloc :

- `addCinematicTimelineActorMoveStep`;
- `updateCinematicTimelineActorMoveStep`;
- `isCinematicTimelineActorMoveStep`;
- `cinematicTimelineActorMovementModeOf`;
- `cinematicTimelineActorPathModeOf`.

Enums :

- `CinematicTimelineActorMovementMode.walk`;
- `CinematicTimelineActorMovementMode.run`;
- `CinematicTimelineActorPathMode.direct`.

La suppression d'une cible utilisee par un `actorMove` est refusee.

## 8. Diagnostics

Nouveaux codes :

- `cinematicActorMoveMissingActorRef`;
- `cinematicActorMoveMissingTargetRef`;
- `cinematicUnknownMovementTargetRef`;
- `cinematicActorMoveInvalidDuration`;
- `cinematicActorMoveInvalidMovementMode`;
- `cinematicActorMoveUnsupportedPathMode`.

La ref acteur inconnue reutilise le diagnostic existant `cinematicUnknownActorRef`.

## 9. Read Model Timeline

`CinematicTimelineLaneStep` expose maintenant :

- `targetId`;
- `targetLabel`.

Pour `actorMove`, les badges montrent :

- `Cible: <label>`;
- `Marche` ou `Course`;
- `Direct`.

Les lanes restent derivees et non persistees.

## 10. UI Builder

Ajouts principaux :

- section palette `Cibles de déplacement`;
- bouton `Ajouter une cible`;
- carte cible avec label lisible;
- bouton `Déplacement acteur` active seulement si au moins un acteur et une cible existent;
- raisons de desactivation explicites;
- inspecteur acteur/cible/duree;
- boutons `Marche` / `Course`;
- `PathMode direct verrouillé`.

Le Builder continue de passer par `CinematicsLibraryWorkspace` et `NarrativeWorkspaceCanvas` pour muter le `ProjectManifest` en memoire.

## 11. Design System

Les widgets ajoutes reutilisent les composants et tokens PokeMap deja presents dans la surface :

- `PokeMapPanel`;
- `PokeMapActionButton`;
- `PokeMapStatusBadge`;
- `context.pokeMapColors`;
- `context.pokeMapTypography`.

La recherche ciblee n'a trouve aucun `Color(`, `Colors.` ou `0x...` dans les fichiers UI modifies.

## 12. Tests Ajoutes ou Etendus

Core :

- JSON `CinematicAsset` avec `movementTargets`;
- compatibilite JSON ancien sans `movementTargets`;
- operations cible;
- operations actorMove;
- suppression cible utilisee refusee;
- diagnostics acteur/cible/modes/duree;
- lane read model actorMove.

Editor :

- bouton actorMove active seulement avec acteur + cible;
- bouton actorMove reste disabled sans acteur;
- add/edit/remove actorMove;
- callback Library;
- screenshot V1-49.

## 13. Visual Gate

Fichier :

```text
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_49_cinematic_actor_movement_block_v0.png
```

Verification fichier :

```text
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_49_cinematic_actor_movement_block_v0.png: PNG image data, 1280 x 860, 8-bit/color RGBA, non-interlaced
a52bcf846d9c84f84666632d902ce1357a03c868faf456b1b33c4639eca0011a  reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_49_cinematic_actor_movement_block_v0.png
-rw-r--r--  1 karim  staff  183755 Jun  1 23:28 reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_49_cinematic_actor_movement_block_v0.png
```

Lecture visuelle : palette acteurs + cibles, bloc `Déplacement acteur`, timeline par lanes, step actorMove selectionne, inspecteur acteur/cible/duree/pathMode/mode mouvement. La preview reste sandbox.

## 14. Roadmaps

Mis a jour :

- `reports/narrativeStudio/scenes/road_map_scenes.md`;
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`.

V1-49 est propose DONE et le prochain lot recommande devient :

```text
NS-SCENES-V1-50 — Cinematic Actor Movement Inspector Polish / Target Labels V0
```

## 15. Non-objectifs Confirmes

- Aucun package `map_runtime` modifie.
- Aucun package `map_gameplay` modifie.
- Aucun package `map_battle` modifie.
- Aucun fichier `examples/` modifie.
- Aucun pathfinding.
- Aucune coordonnee libre.
- Aucune cible runtime map/entity.
- Aucune donnee Selbrume.
- Aucun git write operation.

## 16. RED Tests

Les tests ont ete poses avant l'implementation et ont echoue sur les API attendues :

```text
cd packages/map_core && dart test test/cinematic_asset_test.dart
Echec attendu : CinematicMovementTargetRef / movementTargets absents.

cd packages/map_core && dart test test/cinematic_authoring_operations_test.dart
Echec attendu : operations cible et actorMove absentes.

cd packages/map_core && dart test test/cinematic_diagnostics_test.dart
Echec attendu : diagnostics actorMove absents.

cd packages/map_core && dart test test/cinematic_timeline_lane_read_model_test.dart
Echec attendu : target fields / actorMove badges absents.

cd packages/map_editor && flutter test --reporter=compact test/cinematic_builder_workspace_test.dart
Echec attendu : callbacks mouvement cible absents.
```

## 17. GREEN Tests Intermediaires

Commandes ciblees relancees pendant implementation :

```text
cd packages/map_core && dart test test/cinematic_asset_test.dart
00:00 +5: All tests passed!

cd packages/map_core && dart test test/cinematic_authoring_operations_test.dart
00:00 +32: All tests passed!

cd packages/map_core && dart test test/cinematic_diagnostics_test.dart
00:00 +13: All tests passed!

cd packages/map_core && dart test test/cinematic_timeline_lane_read_model_test.dart
00:00 +2: All tests passed!

cd packages/map_editor && flutter test --reporter=compact test/cinematic_builder_workspace_test.dart
00:03 +20: All tests passed!

cd packages/map_editor && flutter test --update-goldens --dart-define=NS_SCENES_V1_49_CAPTURE_CINEMATIC_ACTOR_MOVEMENT=true --reporter=compact test/cinematic_builder_workspace_test.dart
00:04 +21: All tests passed!

cd packages/map_editor && flutter test --reporter=compact test/cinematics_library_workspace_test.dart
00:03 +10: All tests passed!
```

## 18. Validation Finale Core

Commande complete :

```bash
cd packages/map_core && dart test
```

Resultat :

```text
00:06 +2330: All tests passed!
```

Commande :

```bash
cd packages/map_core && dart test test/cinematic_asset_test.dart test/cinematic_authoring_operations_test.dart test/cinematic_diagnostics_test.dart test/cinematic_timeline_lane_read_model_test.dart test/cinematics_library_read_model_test.dart test/project_manifest_cinematics_test.dart
```

Resultat :

```text
00:00 +61: All tests passed!
```

Commande :

```bash
cd packages/map_core && dart analyze
```

Resultat :

```text
Analyzing map_core...
No issues found!
```

## 19. Validation Finale Editor

Commande :

```bash
cd packages/map_editor && flutter test --reporter=compact test/cinematic_builder_workspace_test.dart test/cinematics_library_workspace_test.dart
```

Resultat :

```text
00:05 +31: All tests passed!
```

Commande globale tentee :

```bash
cd packages/map_editor && flutter test --reporter=compact
```

Resultat :

```text
01:36 +2056 -18: Some tests failed.
```

Signal utile : les tests Cinematic V1-49 restent verts dans la suite ciblee. Les echecs globaux observes sont hors lot, notamment des goldens historiques `storylines` / `scenes` et un `MissingPluginException` macOS UI sur `appkit_ui_element_colors`. Le run global a genere des artefacts `packages/map_editor/test/failures`; ils ont ete nettoyes pour ne pas polluer le diff V1-49.

Commande :

```bash
cd packages/map_editor && flutter analyze --no-fatal-infos lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart lib/src/ui/canvas/narrative_workspace_canvas.dart test/cinematic_builder_workspace_test.dart test/cinematics_library_workspace_test.dart
```

Resultat :

```text
Waiting for another flutter command to release the startup lock...
Analyzing 5 items...
No issues found! (ran in 2.2s)
```

## 20. Format

Commande :

```bash
cd packages/map_core && dart format --set-exit-if-changed lib/src/models/cinematic_asset.dart lib/src/authoring/cinematic_authoring_operations.dart lib/src/diagnostics/cinematic_diagnostics.dart lib/src/read_models/cinematic_timeline_lane_read_model.dart test/cinematic_asset_test.dart test/cinematic_authoring_operations_test.dart test/cinematic_diagnostics_test.dart test/cinematic_timeline_lane_read_model_test.dart
```

Resultat :

```text
Formatted 8 files (0 changed) in 0.04 seconds.
```

Commande :

```bash
cd packages/map_editor && dart format --set-exit-if-changed lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart lib/src/ui/canvas/narrative_workspace_canvas.dart test/cinematic_builder_workspace_test.dart test/cinematics_library_workspace_test.dart
```

Resultat :

```text
Formatted 5 files (0 changed) in 0.04 seconds.
```

## 21. Checks Anti-scope

Commande :

```bash
git diff --name-only -- packages/map_runtime packages/map_gameplay packages/map_battle examples
```

Resultat : sortie vide.

Commande :

```bash
rg -n "Color\(|Colors\.|0x[0-9A-Fa-f]{6,8}" packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart packages/map_editor/test/cinematic_builder_workspace_test.dart packages/map_editor/test/cinematics_library_workspace_test.dart
```

Resultat : sortie vide.

Commande :

```bash
rg -n "pathfinding|Pathfinding|A\*|astar|Bezier|bezier|coordinates|coordonnees|\bx/y\b|positionX|positionY|MapEntity|PlayableMapGame|Flame|map_runtime|map_gameplay|map_battle|Selbrume" packages/map_core/lib/src/models/cinematic_asset.dart packages/map_core/lib/src/authoring/cinematic_authoring_operations.dart packages/map_core/lib/src/diagnostics/cinematic_diagnostics.dart packages/map_core/lib/src/read_models/cinematic_timeline_lane_read_model.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart packages/map_editor/test/cinematic_builder_workspace_test.dart packages/map_editor/test/cinematics_library_workspace_test.dart
```

Resultat : sortie vide.

Commande :

```bash
git diff --check
```

Resultat : sortie vide.

## 22. Fichiers Modifies

Core :

- `packages/map_core/lib/src/models/cinematic_asset.dart`
- `packages/map_core/lib/src/authoring/cinematic_authoring_operations.dart`
- `packages/map_core/lib/src/diagnostics/cinematic_diagnostics.dart`
- `packages/map_core/lib/src/read_models/cinematic_timeline_lane_read_model.dart`

Core tests :

- `packages/map_core/test/cinematic_asset_test.dart`
- `packages/map_core/test/cinematic_authoring_operations_test.dart`
- `packages/map_core/test/cinematic_diagnostics_test.dart`
- `packages/map_core/test/cinematic_timeline_lane_read_model_test.dart`

Editor :

- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart`

Editor tests :

- `packages/map_editor/test/cinematic_builder_workspace_test.dart`
- `packages/map_editor/test/cinematics_library_workspace_test.dart`

Reports :

- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_49_cinematic_actor_movement_block_v0.md`
- `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_49_cinematic_actor_movement_block_v0.png`

## 23. Diff Stat Avant Rapport

Commande :

```bash
git diff --stat
```

Resultat :

```text
 .../authoring/cinematic_authoring_operations.dart  | 452 ++++++++++++++++++++-
 .../lib/src/diagnostics/cinematic_diagnostics.dart | 119 ++++++
 .../map_core/lib/src/models/cinematic_asset.dart   |  60 +++
 .../cinematic_timeline_lane_read_model.dart        |  39 ++
 packages/map_core/test/cinematic_asset_test.dart   |  20 +
 .../test/cinematic_authoring_operations_test.dart  | 386 +++++++++++++++++-
 .../map_core/test/cinematic_diagnostics_test.dart  | 188 +++++++++
 .../cinematic_timeline_lane_read_model_test.dart   |  52 +++
 .../cinematics/cinematic_builder_workspace.dart    | 419 ++++++++++++++++++-
 .../cinematics/cinematics_library_workspace.dart   |  31 ++
 .../src/ui/canvas/narrative_workspace_canvas.dart  |  91 +++++
 .../test/cinematic_builder_workspace_test.dart     | 333 ++++++++++++++-
 .../test/cinematics_library_workspace_test.dart    |  57 ++-
 .../scenes/road_map_scene_builder_authoring.md     |  17 +-
 reports/narrativeStudio/scenes/road_map_scenes.md  |  21 +-
 15 files changed, 2259 insertions(+), 26 deletions(-)
```

## 24. Git Status Attendu Apres Rapport

```text
 M packages/map_core/lib/src/authoring/cinematic_authoring_operations.dart
 M packages/map_core/lib/src/diagnostics/cinematic_diagnostics.dart
 M packages/map_core/lib/src/models/cinematic_asset.dart
 M packages/map_core/lib/src/read_models/cinematic_timeline_lane_read_model.dart
 M packages/map_core/test/cinematic_asset_test.dart
 M packages/map_core/test/cinematic_authoring_operations_test.dart
 M packages/map_core/test/cinematic_diagnostics_test.dart
 M packages/map_core/test/cinematic_timeline_lane_read_model_test.dart
 M packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
 M packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart
 M packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
 M packages/map_editor/test/cinematic_builder_workspace_test.dart
 M packages/map_editor/test/cinematics_library_workspace_test.dart
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_49_cinematic_actor_movement_block_v0.md
?? reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_49_cinematic_actor_movement_block_v0.png
```

## 25. Decisions

- Cible stockee dans `CinematicAsset`, pas dans la timeline step seule, pour permettre validation et picker lisible.
- `targetId` du step reste le lien vers la cible stable.
- `pathMode` reste une metadata authoring verrouillee a `direct`, afin de ne pas promettre une navigation non codee.
- `movementMode` est une intention visuelle, pas une vitesse runtime.
- La suppression d'une cible utilisee est refusee pour eviter les steps orphelins.

## 26. Limites Connues

- Les cibles sont ajoutables avec un label genere; l'edition fine des labels/pickers est reportee a V1-50.
- Le Builder n'execute toujours pas la sequence.
- Les lanes restent une projection lineaire lisible, pas un vrai moteur multi-track.
- Les metadata actorMove restent un contrat authoring V0; un futur player devra les interpreter explicitement.

## 27. Risques

- Le modele `movementTargets` est nouveau : les integrations futures devront conserver sa compatibilite JSON.
- `actorMove` peut maintenant etre authorable, mais pas jouable : l'UI doit rester claire sur la preview sandbox.
- Le prochain polish doit eviter de transformer les cibles en positions libres non diagnostiquables.

## 28. Non-regression V1-48

La lane actorMove derivee de `actorId` conserve le principe V1-48 : les lanes sont calculees depuis la timeline et les acteurs requis. Aucune lane persistante n'a ete ajoutee.

## 29. Non-regression V1-45/V1-46

Les blocs Attente/Fondu/Camera/Orientation acteur restent authorables et leurs tests widget continuent de passer dans la suite Builder.

## 30. Roadmap Status

`NS-SCENES-V1-49 — Cinematic Actor Movement Block V0` peut etre propose DONE avec les preuves ci-dessus.

`NS-SCENES-V1-50 — Cinematic Actor Movement Inspector Polish / Target Labels V0` est recommande comme prochain lot exact.

## 31. Ce qui n'a pas ete fait

- Pas de branchement Flame.
- Pas de `PlayableMapGame`.
- Pas de save/load runtime.
- Pas de mouvement de sprite.
- Pas d'import de package runtime dans core/editor.
- Pas de generation de code.
- Pas de commit.

## 32. Commandes Non Lancees

La suite globale `map_editor` a ete tentee et echoue hors lot, voir section 19.

Commande globale non lancee :

- `cd packages/map_editor && flutter analyze`

Raison : l'analyse ciblee des fichiers modifies passe, et le full `flutter test` a deja confirme une dette globale hors lot sans changer le verdict V1-49.

## 33. Verdict

Le lot V1-49 est ferme proprement : `actorMove` est authorable, diagnostique, affiche dans la timeline par lanes, modifiable depuis l'inspecteur, et borne par un contrat cible stable + direct path mode. Les limites runtime/pathfinding/coordonnees restent intactes.
