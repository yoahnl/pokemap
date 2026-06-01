# NS-SCENES-V1-50 — Cinematic Actor Movement Inspector Polish / Target Labels V0

Date : 2026-06-02  
Statut proposé : DONE  
Lot précédent : `NS-SCENES-V1-49 — Cinematic Actor Movement Block V0`  
Prochain lot recommandé : `NS-SCENES-V1-51 — Cinematic Timeline Time Axis / Bar Layout V0`

## 1. Résumé exécutif

`NS-SCENES-V1-50` ferme le trou UX volontairement laissé par V1-49 : `actorMove` reste strictement V0, mais devient lisible et utilisable par une personne normale.

Le lot ajoute :

- édition no-code du label et de la description des cibles de déplacement ;
- suppression de cible libre ;
- suppression bloquée et expliquée quand une cible est utilisée par un bloc `Déplacement acteur` ;
- labels actorMove dérivés dans le read model/UI ;
- résumé humain dans l'inspecteur actorMove ;
- clarification du chemin direct verrouillé ;
- champs texte tokenisés dans le thème PokeMap ;
- Visual Gate V1-50.

Le lot n'ajoute ni runtime, ni pathfinding, ni coordonnées libres, ni timeline en barres.

## 2. Gate 0

Commande : `pwd`  
Résultat :

```text
/Users/karim/Project/pokemonProject
```

Commande : `git branch --show-current`  
Résultat :

```text
main
```

Commande : `git status --short --untracked-files=all` avant edits  
Résultat : sortie vide.

Commande : `git diff --stat` avant edits  
Résultat : sortie vide.

Commande : `git diff --name-only` avant edits  
Résultat : sortie vide.

Commande : `git log --oneline -n 15` avant edits  
Résultat :

```text
7d6c94cf feat(narrative): add cinematic actor movement block v0 (NS-SCENES-V1-49)
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
```

## 3. Fichiers lus

Instructions et contexte :

```text
AGENTS.md
agent_rules.md
skills/README.md
pokemap_roadmap_mecaniques_fangame.md
reports/narrativeStudio/scenes/road_map_scenes.md
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/ns_scenes_v1_47_cinematic_actor_movement_block_v0_prep_contract.md
reports/narrativeStudio/scenes/ns_scenes_v1_48_cinematic_timeline_lane_grouping_v0.md
reports/narrativeStudio/scenes/ns_scenes_v1_49_cinematic_actor_movement_block_v0.md
/Users/karim/.codex/attachments/415d4425-3b62-4342-8892-d7b3ef27e907/pasted-text.txt
```

Core :

```text
packages/map_core/lib/src/models/cinematic_asset.dart
packages/map_core/lib/src/authoring/cinematic_authoring_operations.dart
packages/map_core/lib/src/diagnostics/cinematic_diagnostics.dart
packages/map_core/lib/src/read_models/cinematic_timeline_lane_read_model.dart
packages/map_core/lib/src/read_models/cinematics_library_read_model.dart
packages/map_core/lib/map_core.dart
packages/map_core/test/cinematic_asset_test.dart
packages/map_core/test/cinematic_authoring_operations_test.dart
packages/map_core/test/cinematic_diagnostics_test.dart
packages/map_core/test/cinematic_timeline_lane_read_model_test.dart
packages/map_core/test/cinematics_library_read_model_test.dart
```

Editor :

```text
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart
packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
packages/map_editor/test/cinematic_builder_workspace_test.dart
packages/map_editor/test/cinematics_library_workspace_test.dart
```

## 4. Design Gate — Cinematic Actor Movement Inspector Polish / Target Labels V0

1. `CinematicMovementTargetRef` contenait déjà `targetId`, `label` et `description`.
2. L'édition du label ne nécessitait pas de changement modèle.
3. L'édition de description ne nécessitait pas de changement modèle.
4. `updateCinematicMovementTarget` existait déjà.
5. L'opération n'a pas été étendue côté modèle ; elle a été exposée côté UI et couverte par tests renforcés.
6. Les labels vides sont refusés côté opération pure et côté champ UI avant callback.
7. Les labels par défaut restent générés par les opérations existantes (`Cible` avec suffixes déterministes).
8. `targetId` est affiché seulement comme information secondaire discrète dans la carte cible.
9. L'usage d'une cible est calculé depuis les steps `actorMove` qui pointent vers son `targetId`.
10. Une cible utilisée ne peut pas être supprimée.
11. Message retenu : `Cette cible est utilisée par un bloc Déplacement acteur.`
12. Le label humain actorMove est dérivé depuis acteur + cible : `Professor → Centre scène`.
13. Quand `actorId` ou `targetId` changent, le label affiché se recalcule ; le `step.label` persistant n'est pas réécrit.
14. Le label ne devient pas une source runtime car `targetId` reste la référence stable.
15. Le picker cible continue d'utiliser les boutons existants mais affiche labels lisibles ; les IDs restent hors expérience principale.
16. Le picker acteur conserve les labels visibles des `requiredActors`.
17. `pathMode` est affiché comme `Chemin direct verrouillé`.
18. Les presets durée existants sont conservés : 500, 1000, 1500, 2000, 3000 ms.
19. `Marche` / `Course` restent des intentions visuelles, avec texte explicite `Intention visuelle, sans vitesse runtime.`
20. La timeline par lanes reste compatible : la projection pure fournit le label dérivé.
21. Le lot ne fait pas time axis/bar layout/playhead, car V1-50 est un polish de lisibilité actorMove, pas un lot timeline visuel.
22. Visual Gate produite : `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_50_cinematic_actor_movement_inspector_polish_target_labels_v0.png`.

## 5. Scope réalisé

- `CinematicTimelineLaneReadModel` affiche désormais un label dérivé pour `actorMove`.
- La palette `Cibles de déplacement` édite label et description.
- La suppression d'une cible libre passe par `removeCinematicMovementTarget`.
- Une cible utilisée affiche un bouton de suppression disabled et un message clair.
- L'inspecteur actorMove montre un titre dérivé et un résumé humain.
- La preview sandbox utilise aussi le titre dérivé.
- Les badges cible longs sont compactés pour éviter les débordements visuels.
- Les champs texte de cible utilisent les tokens du thème PokeMap.
- Les roadmaps V1 sont mises à jour vers V1-51.

## 6. Labels de cibles

Les labels sont éditables sans changer le JSON. Le `targetId` reste conservé et stable. La description est éditable parce que le modèle la supportait déjà.

La modification d'une cible met à jour :

- la palette ;
- le picker cible ;
- la timeline par lanes ;
- la preview sandbox ;
- l'inspecteur actorMove ;
- le résumé humain.

Le `step.label` existant n'est pas réécrit. Le test vérifie que `Déplacement Professor` reste persistant pendant que l'UI affiche `Professor → Centre du plateau`.

## 7. Opérations core ajoutées ou réutilisées

Réutilisées :

```text
updateCinematicMovementTarget
removeCinematicMovementTarget
addCinematicTimelineActorMoveStep
updateCinematicTimelineActorMoveStep
buildCinematicTimelineLaneReadModel
```

Ajout principal côté core : helper de label dérivé dans le read model lane.

## 8. Suppression / protection des cibles utilisées

La suppression d'une cible libre est exposée dans le Builder.

Une cible utilisée :

- reste visible ;
- affiche `Utilisée` ;
- garde un bouton supprimer disabled ;
- affiche `Cette cible est utilisée par un bloc Déplacement acteur.`

La protection core existante reste la barrière finale.

## 9. Résumé humain actorMove

Exemples produits :

```text
Professor marche vers Centre scène en 1000 ms.
Rival court vers Sortie en 2000 ms.
```

Le verbe vient de `movementMode` :

```text
walk -> marche
run -> court
```

## 10. UI Cibles de déplacement

Chaque cible affiche :

- label principal ;
- description ;
- `targetId` secondaire ;
- badge `Utilisée` ou `Libre` ;
- champ label ;
- champ description ;
- action enregistrer ;
- action supprimer.

Les champs texte utilisent `context.pokeMapColors` et ne hardcodent aucune couleur.

## 11. UI Actor Move Inspector

L'inspecteur affiche :

- titre dérivé ;
- acteur lisible ;
- cible lisible ;
- durée ;
- metadata ;
- statut authoring ;
- résumé humain ;
- chemin direct verrouillé ;
- intention visuelle sans vitesse runtime ;
- pickers acteur/cible ;
- presets durée ;
- boutons Marche/Course ;
- danger zone de suppression du step authoring-owned.

## 12. UI Timeline par pistes

La timeline garde les lanes dérivées V1-48.

Pour `actorMove`, la carte affiche maintenant le label dérivé `Acteur → Cible`, avec badges durée, acteur, cible, mode et direct. Les badges longs sont compactés pour éviter les débordements, mais les titres et résumés gardent le label complet.

## 13. Compatibilité V1-49

Préservé :

```text
Ajouter un brouillon
Ajouter Attente
Ajouter Fondu
Ajouter Caméra
Ajouter acteur requis
Ajouter Orientation acteur
Ajouter cible
Ajouter Déplacement acteur
Update actorMove actor
Update actorMove target
Update actorMove duration
Update actorMove movementMode
Remove actorMove
Timeline lanes
Library summary
Bridge legacy exclusion
```

## 14. Restrictions anti-pathfinding / anti-runtime

Non ajouté :

```text
map_runtime
map_gameplay
map_battle
examples
PlayableMapGame
SceneRuntimeExecutor
SceneEventRuntimeHook
SceneCinematicRuntimeAwaitableAdapter
coordonnées x/y
pathfinding
collision
MapEntity/Event binding runtime
drag/drop
reorder
time axis
bar layout
playhead
transport controls
preview runtime
```

## 15. Legacy bridge policy inchangée

`ScenarioAsset` et les bridges legacy restent exclus du Builder canonique. V1-50 ne change pas la Library bridge policy et ne migre aucun legacy.

## 16. Design system

UI editor modifiée avec :

```text
PokeMapPanel
PokeMapCard
PokeMapBadge
PokeMapButton
PokeMapIconTile
context.pokeMapColors
```

Aucun `Color(0x...)` ou `Colors.*` n'a été ajouté dans les widgets de feature.

## 17. Tests ajoutés ou modifiés

Core :

- update target label/description avec trim ;
- non-mutation du projet source ;
- préservation `targetId`, timeline, actors, metadata ;
- cible utilisée non supprimable ;
- label actorMove dérivé dans le read model lane ;
- label affiché mis à jour après renommage de cible sans réécrire `step.label`.

Editor :

- résumé humain actorMove ;
- titre timeline `Professor → Centre scène` ;
- chemin direct verrouillé ;
- intention visuelle sans vitesse runtime ;
- cible utilisée non supprimable ;
- renommage label/description ;
- label vide refusé côté UI ;
- suppression cible libre ;
- capture V1-50 conditionnelle.

## 18. Visual Gate

Fichier :

```text
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_50_cinematic_actor_movement_inspector_polish_target_labels_v0.png
```

Preuve fichier :

```text
-rw-r--r--  1 karim  staff   186K Jun  2 00:07 reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_50_cinematic_actor_movement_inspector_polish_target_labels_v0.png
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_50_cinematic_actor_movement_inspector_polish_target_labels_v0.png: PNG image data, 1280 x 860, 8-bit/color RGBA, non-interlaced
7650e7404d15db681e1a04a3490a4296ba4a41e834f7c8abc70058f60dd9c1ab  reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_50_cinematic_actor_movement_inspector_polish_target_labels_v0.png
```

Commande de génération :

```text
cd packages/map_editor && flutter test --update-goldens --dart-define=NS_SCENES_V1_50_CAPTURE_CINEMATIC_ACTOR_MOVEMENT_POLISH=true test/cinematic_builder_workspace_test.dart --plain-name 'captures V1-50 actor movement target polish screenshot when requested'
00:00 +0: captures V1-50 actor movement target polish screenshot when requested
00:01 +1: All tests passed!
```

## 19. Commandes exécutées

```text
cd packages/map_core && dart test test/cinematic_authoring_operations_test.dart test/cinematic_timeline_lane_read_model_test.dart
cd packages/map_editor && flutter test --reporter=compact test/cinematic_builder_workspace_test.dart
cd packages/map_editor && flutter test --reporter=compact test/cinematics_library_workspace_test.dart
cd packages/map_core && dart test test/cinematic_asset_test.dart test/cinematic_authoring_operations_test.dart test/cinematic_diagnostics_test.dart test/cinematic_timeline_lane_read_model_test.dart
cd packages/map_core && dart analyze lib/src/read_models/cinematic_timeline_lane_read_model.dart test/cinematic_asset_test.dart test/cinematic_authoring_operations_test.dart test/cinematic_diagnostics_test.dart test/cinematic_timeline_lane_read_model_test.dart
cd packages/map_editor && flutter test --reporter=compact test/cinematic_builder_workspace_test.dart test/cinematics_library_workspace_test.dart
cd packages/map_editor && flutter analyze lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart lib/src/ui/canvas/narrative_workspace_canvas.dart test/cinematic_builder_workspace_test.dart test/cinematics_library_workspace_test.dart
git diff --name-only -- packages/map_runtime packages/map_gameplay packages/map_battle examples
git diff --check
git diff --stat
git diff --name-only
git status --short --untracked-files=all
```

## 20. Résultats des tests

Core final :

```text
00:00 +53: All tests passed!
```

Editor final :

```text
00:05 +33: All tests passed!
```

Visual Gate :

```text
00:01 +1: All tests passed!
```

## 21. Analyze

Core :

```text
Analyzing cinematic_timeline_lane_read_model.dart, cinematic_asset_test.dart, cinematic_authoring_operations_test.dart, cinematic_diagnostics_test.dart, cinematic_timeline_lane_read_model_test.dart...
No issues found!
```

Editor :

```text
Analyzing 5 items...
No issues found! (ran in 1.8s)
```

## 22. Checks anti-scope

Commande :

```text
git diff --name-only -- packages/map_runtime packages/map_gameplay packages/map_battle examples
```

Résultat : sortie vide.

Commande :

```text
git diff --check
```

Résultat : sortie vide.

## 23. Fichiers créés

```text
reports/narrativeStudio/scenes/ns_scenes_v1_50_cinematic_actor_movement_inspector_polish_target_labels_v0.md
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_50_cinematic_actor_movement_inspector_polish_target_labels_v0.png
```

## 24. Fichiers modifiés

```text
packages/map_core/lib/src/read_models/cinematic_timeline_lane_read_model.dart
packages/map_core/test/cinematic_authoring_operations_test.dart
packages/map_core/test/cinematic_timeline_lane_read_model_test.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart
packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
packages/map_editor/test/cinematic_builder_workspace_test.dart
packages/map_editor/test/cinematics_library_workspace_test.dart
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md
```

## 25. Roadmaps mises à jour

Mises à jour :

```text
reports/narrativeStudio/scenes/road_map_scenes.md
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
```

Contenu ajouté :

- ligne V1-50 DONE ;
- section `Mise a jour V1-50` ;
- prochain lot exact V1-51.

## 26. Limites connues

- Les cibles restent authoring-only.
- Les labels longs de badge sont compactés dans la timeline pour préserver le layout.
- Le Builder ne fournit pas encore de time axis, bar layout, playhead ou transport controls.
- La preview reste sandbox.
- Les cibles ne portent aucune position map ou coordonnée libre.

## 27. Non-objectifs confirmés

Confirmé non fait :

```text
runtime playback
pathfinding
coordonnées x/y
MapEntity/Event runtime binding
time axis
bar layout proportionnel
playhead
transport controls
drag/drop
reorder
dialogue cinematic
FX/Son authorable
données Selbrume/Mael/Lysa/Port
```

## 28. Evidence Pack

Diff stat final avant ajout de ce rapport :

```text
 .../cinematic_timeline_lane_read_model.dart        |  23 +-
 .../test/cinematic_authoring_operations_test.dart  |  61 ++-
 .../cinematic_timeline_lane_read_model_test.dart   |   1 +
 .../cinematics/cinematic_builder_workspace.dart    | 431 +++++++++++++++++++--
 .../cinematics/cinematics_library_workspace.dart   |  18 +
 .../src/ui/canvas/narrative_workspace_canvas.dart  |  54 +++
 .../test/cinematic_builder_workspace_test.dart     | 225 ++++++++++-
 .../test/cinematics_library_workspace_test.dart    |  28 ++
 .../scenes/road_map_scene_builder_authoring.md     |  17 +-
 reports/narrativeStudio/scenes/road_map_scenes.md  |  23 +-
 10 files changed, 843 insertions(+), 38 deletions(-)
```

Diff name-only final avant ajout de ce rapport :

```text
packages/map_core/lib/src/read_models/cinematic_timeline_lane_read_model.dart
packages/map_core/test/cinematic_authoring_operations_test.dart
packages/map_core/test/cinematic_timeline_lane_read_model_test.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart
packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
packages/map_editor/test/cinematic_builder_workspace_test.dart
packages/map_editor/test/cinematics_library_workspace_test.dart
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md
```

Statut git final après ajout du rapport et de la capture :

```text
 M packages/map_core/lib/src/read_models/cinematic_timeline_lane_read_model.dart
 M packages/map_core/test/cinematic_authoring_operations_test.dart
 M packages/map_core/test/cinematic_timeline_lane_read_model_test.dart
 M packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
 M packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart
 M packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
 M packages/map_editor/test/cinematic_builder_workspace_test.dart
 M packages/map_editor/test/cinematics_library_workspace_test.dart
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_50_cinematic_actor_movement_inspector_polish_target_labels_v0.md
?? reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_50_cinematic_actor_movement_inspector_polish_target_labels_v0.png
```

Décisions de diff :

- `cinematic_timeline_lane_read_model.dart` : label actorMove dérivé dans la projection pure.
- `cinematic_builder_workspace.dart` : callbacks target update/remove, carte cible éditable, champs tokenisés, résumé inspector, titres dérivés timeline/preview, callbacks UI.
- `cinematics_library_workspace.dart` et `narrative_workspace_canvas.dart` : propagation des callbacks vers les opérations core.
- tests core/editor : preuves de trim, non-mutation, cible utilisée protégée, label dérivé, UI polish et capture.
- roadmaps : V1-50 DONE et V1-51 recommandé.

## 29. Auto-review critique

1. V1-50 a-t-il modifié `map_runtime` ? Non.
2. V1-50 a-t-il modifié `map_gameplay`, `map_battle` ou `examples` ? Non.
3. V1-50 a-t-il modifié le modèle JSON ? Non.
4. Si oui, pourquoi ? Non applicable.
5. V1-50 a-t-il lancé `build_runner` ? Non.
6. V1-50 a-t-il ajouté une position `x/y` libre ? Non.
7. V1-50 a-t-il ajouté du pathfinding ? Non.
8. V1-50 a-t-il ajouté un binding runtime vers `MapEntity` ou `Event` ? Non.
9. V1-50 a-t-il ajouté du drag/drop ? Non.
10. V1-50 a-t-il ajouté du réordonnancement ? Non.
11. V1-50 a-t-il ajouté un time axis ou bar layout ? Non.
12. V1-50 a-t-il ajouté une preview runtime ? Non.
13. Les labels cible sont-ils éditables sans ID libre ? Oui.
14. Les cibles utilisées sont-elles protégées ? Oui.
15. L'inspecteur actorMove est-il plus lisible ? Oui.
16. Wait/Fade/Camera restent-ils fonctionnels ? Oui, tests Builder conservés.
17. ActorFace reste-t-il fonctionnel ? Oui, tests Builder/Library conservés.
18. ActorMove reste-t-il fonctionnel ? Oui.
19. Les lanes V1-48 restent-elles fonctionnelles ? Oui.
20. Les steps non-owned restent-ils protégés ? Oui.
21. Le design system est-il respecté ? Oui, tokens et primitives PokeMap.
22. La Visual Gate prouve-t-elle le polish ? Oui : cible renommée, champs éditables, inspecteur résumé/titre dérivé.
23. L'Evidence Pack est-il complet sans placeholders ? Oui.
24. Prochain lot exact recommandé ? `NS-SCENES-V1-51 — Cinematic Timeline Time Axis / Bar Layout V0`.

## 30. Recommandation pour le prochain lot

`NS-SCENES-V1-51 — Cinematic Timeline Time Axis / Bar Layout V0`

Objectif : commencer la transformation visuelle de la timeline en barres horizontales lisibles, sans drag/drop, sans runtime et sans reordonnancement.
