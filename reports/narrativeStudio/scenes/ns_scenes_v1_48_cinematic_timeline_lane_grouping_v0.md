# NS-SCENES-V1-48 — Cinematic Timeline Lane Grouping V0

## 1. Résumé exécutif

`NS-SCENES-V1-48` est réalisé.

Le Cinematic Builder n'affiche plus un simple déroulé vertical présenté comme read-only. Il affiche une `Timeline par pistes`, construite depuis une projection pure côté `map_core`.

Résultat produit :

```text
les steps restent linéaires ;
les lanes sont dérivées, jamais persistées ;
la lane Caméra existe ;
les lanes Acteur viennent de CinematicAsset.requiredActors ;
les lanes Dialogue, FX, Audio, Transitions, Temps / Global et Autres existent ;
un bloc reste sélectionnable depuis sa lane ;
l'inspecteur et la preview sandbox restent synchronisés ;
Attente, Fondu, Caméra et Orientation acteur restent fonctionnels ;
Déplacement acteur reste verrouillé.
```

Prochain lot recommandé : `NS-SCENES-V1-49 — Cinematic Actor Movement Block V0`.

## 2. Gate 0

Commandes exécutées depuis `/Users/karim/Project/pokemonProject` avant modification :

```text
pwd
/Users/karim/Project/pokemonProject

git branch --show-current
main

git status --short --untracked-files=all

git diff --stat

git diff --name-only

git log --oneline -n 15
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
0fe8fa1f feat(narrative): add cinematic scene builder picker v0 (NS-SCENES-V1-39)
```

Le working tree était propre au début de V1-48.

## 3. Fichiers lus

Instructions et contexte :

```text
AGENTS.md
skills/README.md
skills/using-superpowers/SKILL.md
skills/brainstorming/SKILL.md
skills/writing-plans/SKILL.md
skills/test-driven-development/SKILL.md
skills/verification-before-completion/SKILL.md
reports/narrativeStudio/scenes/road_map_scenes.md
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/ns_scenes_v1_47_cinematic_actor_movement_block_v0_prep_contract.md
```

Core :

```text
packages/map_core/lib/map_core.dart
packages/map_core/lib/src/models/cinematic_asset.dart
packages/map_core/lib/src/authoring/cinematic_authoring_operations.dart
packages/map_core/lib/src/diagnostics/cinematic_diagnostics.dart
packages/map_core/lib/src/read_models/cinematics_library_read_model.dart
packages/map_core/test/cinematic_authoring_operations_test.dart
packages/map_core/test/cinematic_diagnostics_test.dart
packages/map_core/test/cinematic_asset_test.dart
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

## 4. Design Gate — Cinematic Timeline Lane Grouping V0

1. La projection lane doit vivre dans `map_core`, car elle est un contrat pur sur `CinematicAsset`, pas une préférence locale d'affichage.
2. Le read model créé est `CinematicTimelineLaneReadModel`.
3. Elle ne reste pas editor-only : le Builder consomme le contrat core.
4. Lanes V0 supportées : Caméra, Acteur, Dialogue, FX, Audio, Transitions, Temps / Global, Autres.
5. Ordre stable : Caméra, acteurs requis dans l'ordre `requiredActors`, acteurs inconnus rencontrés, Dialogue, FX, Audio, Transitions, Temps / Global, Autres.
6. Les lanes d'acteurs requis vides sont affichées, car elles préparent `actorMove` sans stocker de layout.
7. Les steps sont assignés par `CinematicTimelineStepKind`, et par `actorId` pour `actorMove`, `actorFace` et `actorEmote`.
8. Un `actorId` inconnu devient une lane `Acteur inconnu: <actorId>`, sans crash.
9. L'ordre linéaire global est conservé par `stepIndex`.
10. Le Builder affiche le badge `Ordre linéaire conservé` et ne propose aucun overlap, drag/drop ni reorder.
11. `wait`, `fade`, `camera` et `actorFace` apparaissent dans leurs lanes respectives.
12. `dialogueLine`, `fx`, `shake`, `sound` et `music` apparaissent dans Dialogue, FX et Audio.
13. La sélection locale reste basée sur `step.id`.
14. L'inspecteur reste branché sur le step sélectionné existant.
15. Les actions authoring existantes gardent `afterStepId` basé sur la sélection courante.
16. `actorMove` reste verrouillé parce que V1-48 ne crée pas de cible spatiale ni de bloc mouvement authorable.
17. Il n'y a pas de drag/drop ni reordonnancement pour ne pas faire croire à une vraie timeline multi-track.
18. Il n'y a pas de preview runtime : la zone reste `Aperçu sandbox`.
19. Le test core vérifie que `CinematicAsset.toJson()` reste inchangé après projection.
20. La Visual Gate produite est `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_48_cinematic_timeline_lane_grouping_v0.png`.

## 5. Scope réalisé

```text
read model lane pur ajouté dans map_core ;
export public map_core ajouté ;
Builder branché sur la projection ;
titre remplacé par Timeline par pistes ;
lanes et empty states compacts affichés ;
step cards existantes conservées avec sélection locale ;
overflow des step cards compactes corrigé ;
tests core et editor ajoutés/ajustés ;
Visual Gate générée ;
roadmaps mises à jour.
```

## 6. Contrat Lane Grouping V0

Contrat implémenté :

```text
CinematicTimelineLaneReadModel
  lanes
  stepCount
  estimatedDurationMs
  laneCount
  isEmpty
  laneById(String laneId)

CinematicTimelineLane
  laneId
  laneKind
  label
  sortOrder
  actorId
  actorLabel
  steps
  isEmpty

CinematicTimelineLaneStep
  stepId
  stepIndex
  kind
  label
  durationMs
  actorId
  actorLabel
  isAuthoringOwned
  badges
```

Pureté :

```text
pas de Flutter ;
pas de runtime ;
pas de lecture disque ;
pas de mutation de CinematicAsset ;
sortie déterministe.
```

## 7. Projection lanes / read model

Fichier créé :

```text
packages/map_core/lib/src/read_models/cinematic_timeline_lane_read_model.dart
```

Le build prend un `CinematicAsset` et retourne un `CinematicTimelineLaneReadModel`.

Les lanes système existent même vides. Les lanes acteurs requis existent même vides. Les acteurs inconnus sont ajoutés seulement s'ils apparaissent dans un step acteur.

## 8. Règles de classification des steps

```text
camera -> Caméra
actorMove avec actorId -> Acteur
actorFace avec actorId -> Acteur
actorEmote avec actorId -> Acteur
actorMove/actorFace/actorEmote sans actorId -> Autres
dialogueLine -> Dialogue
fx/shake -> FX
sound/music -> Audio
fade -> Transitions
wait/marker -> Temps / Global
```

## 9. Ordre des lanes

```text
0xx Caméra
1xx Acteurs requis puis acteurs inconnus
200 Dialogue
300 FX
400 Audio
500 Transitions
600 Temps / Global
700 Autres
```

## 10. UI Timeline par pistes

Le Builder remplace :

```text
Déroulé read-only
```

par :

```text
Timeline par pistes
Projection visuelle dérivée du déroulé linéaire
```

Chaque lane affiche :

```text
icône ;
label ;
nombre de steps ;
actorId si lane acteur ;
empty state compact si vide ;
ligne horizontale de blocs si non vide.
```

## 11. Sélection locale depuis les lanes

Les cartes de steps gardent leurs clés :

```text
cinematic-builder-step-card-<stepId>
```

La sélection continue de mettre à jour :

```text
carte sélectionnée ;
preview sandbox ;
inspecteur ;
diagnostics du step.
```

## 12. Compatibilité authoring V1-45 / V1-46

Préservé :

```text
Ajouter un brouillon ;
Attente ;
Fondu ;
Caméra ;
Orientation acteur ;
update durée/mode/direction ;
suppression authoring-owned ;
sélection afterStepId.
```

## 13. ActorMove reste verrouillé

`Déplacement acteur` reste dans la palette verrouillée. Aucun bouton d'ajout `actorMove` n'existe.

Le read model sait classer un `actorMove` existant dans la lane acteur pour compatibilité future, mais V1-48 ne crée aucun step `actorMove`.

## 14. Legacy bridge policy inchangée

Aucun changement sur les bridges legacy. Le Builder reste canonique-only via les règles existantes de la Cinematics Library.

## 15. Design system

Le Builder continue d'utiliser les primitives existantes :

```text
PokeMapPanel
PokeMapCard
PokeMapBadge
PokeMapButton
PokeMapIconTile
context.pokeMapColors
```

Les nouvelles surfaces de lane utilisent les tokens `context.pokeMapColors`, sans couleur hardcodée.

## 16. Tests ajoutés ou modifiés

Créé :

```text
packages/map_core/test/cinematic_timeline_lane_read_model_test.dart
```

Modifié :

```text
packages/map_editor/test/cinematic_builder_workspace_test.dart
```

Tests couverts :

```text
classification des lanes ;
ordre stable ;
acteurs requis vides ;
acteur inconnu ;
stepIndex global ;
non-mutation ;
sélection depuis lane ;
actorMove verrouillé ;
Visual Gate V1-48.
```

## 17. Visual Gate

Chemin :

```text
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_48_cinematic_timeline_lane_grouping_v0.png
```

Preuve :

```text
-rw-r--r--  1 karim  staff  187521 Jun  1 22:51 ../../reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_48_cinematic_timeline_lane_grouping_v0.png
../../reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_48_cinematic_timeline_lane_grouping_v0.png: PNG image data, 1280 x 860, 8-bit/color RGBA, non-interlaced
18a1ae7b81ba0192de0fc074c6275d8a585d2815d469b5dce9f64dcda85981dd  ../../reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_48_cinematic_timeline_lane_grouping_v0.png
```

Lecture visuelle effectuée : la capture montre le Builder, la palette, l'aperçu sandbox, `Timeline par pistes`, lane Caméra, lane Acteur, bloc sélectionné, inspecteur synchronisé et `Déplacement acteur` verrouillé.

## 18. Commandes exécutées

```text
cd packages/map_core && dart test test/cinematic_timeline_lane_read_model_test.dart
cd packages/map_core && dart test test/cinematics_library_read_model_test.dart
cd packages/map_core && dart analyze
cd packages/map_editor && flutter test --reporter=compact test/cinematic_builder_workspace_test.dart
cd packages/map_editor && flutter test --reporter=compact test/cinematics_library_workspace_test.dart
cd packages/map_editor && flutter analyze --no-fatal-infos lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart test/cinematic_builder_workspace_test.dart
cd packages/map_editor && flutter test --update-goldens --dart-define=NS_SCENES_V1_48_CAPTURE_CINEMATIC_TIMELINE_LANES=true --reporter=compact test/cinematic_builder_workspace_test.dart
```

## 19. Résultats des tests

RED initial core :

```text
Failed to load "test/cinematic_timeline_lane_read_model_test.dart":
test/cinematic_timeline_lane_read_model_test.dart:10:25: Error: Method not found: 'buildCinematicTimelineLaneReadModel'.
test/cinematic_timeline_lane_read_model_test.dart:37:35: Error: Undefined name 'CinematicTimelineLaneKind'.
Some tests failed.
```

GREEN core :

```text
dart test test/cinematic_timeline_lane_read_model_test.dart
00:00 +1: All tests passed!

dart test test/cinematics_library_read_model_test.dart
00:00 +4: All tests passed!
```

GREEN editor :

```text
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart
00:02 +17: All tests passed!

flutter test --reporter=compact test/cinematics_library_workspace_test.dart
00:02 +10: All tests passed!
```

Visual Gate :

```text
flutter test --update-goldens --dart-define=NS_SCENES_V1_48_CAPTURE_CINEMATIC_TIMELINE_LANES=true --reporter=compact test/cinematic_builder_workspace_test.dart
00:04 +17: All tests passed!
```

## 20. Analyze

Core :

```text
dart analyze
Analyzing map_core...
No issues found!
```

Editor ciblé :

```text
flutter analyze --no-fatal-infos lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart test/cinematic_builder_workspace_test.dart
Analyzing 2 items...
No issues found! (ran in 1.1s)
```

## 21. Checks anti-scope

Sorties finales :

```text
git diff --name-only -- packages/map_runtime packages/map_gameplay packages/map_battle examples

git diff --unified=0 -- packages/map_core/lib/src/read_models/cinematic_timeline_lane_read_model.dart packages/map_core/test/cinematic_timeline_lane_read_model_test.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart packages/map_editor/test/cinematic_builder_workspace_test.dart reports/narrativeStudio/scenes/road_map_scenes.md reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md reports/narrativeStudio/scenes/ns_scenes_v1_48_cinematic_timeline_lane_grouping_v0.md | rg -n "^\+.*(PlayableMapGame|SceneRuntimeExecutor|SceneEventRuntimeHook|SceneCinematicRuntimeAwaitableAdapter|SceneCinematicRuntimeNoVisualPlayer|GameState|setFact|WorldRule|BattleRuntime|DialogueRuntime)" || true

git diff --unified=0 -- packages/map_core/lib/src/read_models/cinematic_timeline_lane_read_model.dart packages/map_core/test/cinematic_timeline_lane_read_model_test.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart packages/map_editor/test/cinematic_builder_workspace_test.dart reports/narrativeStudio/scenes/road_map_scenes.md reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md reports/narrativeStudio/scenes/ns_scenes_v1_48_cinematic_timeline_lane_grouping_v0.md | rg -ni "^\+.*(selbrume|mael|maël|lysa|port_brisants|bourg_selbrume|phare|brume|marais)" || true
524:+Limites : pas de lane persistante, pas de drag/drop, pas de reordonnancement, pas d'overlap temporel, pas de `actorMove` authorable, pas de preview runtime, pas de modification runtime/gameplay/battle/examples, pas de donnees Selbrume.
```

Interprétation : aucun fichier runtime/gameplay/battle/examples n'est modifié ; aucun terme runtime interdit n'apparaît dans les lignes ajoutées ; la seule occurrence Selbrume ajoutée est une limite explicite.

Commandes anti-scope documentées avec listes réelles :

```text
git diff --name-only -- packages/map_runtime packages/map_gameplay packages/map_battle examples
rg -n "PlayableMapGame|SceneRuntimeExecutor|SceneEventRuntimeHook|SceneCinematicRuntimeAwaitableAdapter|SceneCinematicRuntimeNoVisualPlayer|GameState|setFact|WorldRule|BattleRuntime|DialogueRuntime" packages/map_core/lib/src/read_models/cinematic_timeline_lane_read_model.dart packages/map_core/test/cinematic_timeline_lane_read_model_test.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart packages/map_editor/test/cinematic_builder_workspace_test.dart reports/narrativeStudio/scenes/road_map_scenes.md reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md reports/narrativeStudio/scenes/ns_scenes_v1_48_cinematic_timeline_lane_grouping_v0.md || true
rg -n "selbrume|mael|maël|lysa|port_brisants|bourg_selbrume|phare|brume|marais" packages/map_core/lib/src/read_models/cinematic_timeline_lane_read_model.dart packages/map_core/test/cinematic_timeline_lane_read_model_test.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart packages/map_editor/test/cinematic_builder_workspace_test.dart reports/narrativeStudio/scenes/road_map_scenes.md reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md reports/narrativeStudio/scenes/ns_scenes_v1_48_cinematic_timeline_lane_grouping_v0.md || true
```

## 22. Fichiers créés

```text
packages/map_core/lib/src/read_models/cinematic_timeline_lane_read_model.dart
packages/map_core/test/cinematic_timeline_lane_read_model_test.dart
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_48_cinematic_timeline_lane_grouping_v0.png
reports/narrativeStudio/scenes/ns_scenes_v1_48_cinematic_timeline_lane_grouping_v0.md
```

## 23. Fichiers modifiés

```text
packages/map_core/lib/map_core.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
packages/map_editor/test/cinematic_builder_workspace_test.dart
reports/narrativeStudio/scenes/road_map_scenes.md
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
```

## 24. Roadmaps mises à jour

```text
V1-48 ajouté comme DONE.
Prochain lot exact mis à jour vers V1-49.
Mise à jour V1-48 ajoutée dans les deux roadmaps.
Limites V1-48 documentées : lanes dérivées, pas persistées, pas de drag/drop, pas de runtime.
```

## 25. Limites connues

```text
les lanes ne représentent pas un parallélisme réel ;
les lanes ne sont pas persistées ;
aucun drag/drop ;
aucun reorder ;
aucun overlap temporel ;
aucun actorMove authorable ;
aucune cible spatiale cinematic ;
aucune preview runtime ;
pas de compactage/polish final de densité timeline.
```

## 26. Non-objectifs confirmés

```text
pas de map_runtime ;
pas de map_gameplay ;
pas de map_battle ;
pas d'examples ;
pas de build_runner ;
pas de schema JSON ;
pas de migration ;
pas de Selbrume produit ;
pas de nouvelle donnée narrative finale.
```

## 27. Evidence Pack

Inventaire des nouveaux types core :

```text
CinematicTimelineLaneKind
CinematicTimelineLaneReadModel
CinematicTimelineLane
CinematicTimelineLaneStep
buildCinematicTimelineLaneReadModel(CinematicAsset)
```

Classification core implémentée :

```text
_laneForStep
_laneStepFor
_isActorLaneStep
_actorLaneId
_addLane
```

Hunks documentés des fichiers modifiés :

```diff
packages/map_core/lib/map_core.dart
+export 'src/read_models/cinematic_timeline_lane_read_model.dart';

packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
+final laneReadModel = buildCinematicTimelineLaneReadModel(asset);
+title: 'Timeline par pistes'
+subtitle: 'Projection visuelle dérivée du déroulé linéaire'
+PokeMapBadge(label: '${laneReadModel.laneCount} piste(s)')
+const PokeMapBadge(label: 'Ordre linéaire conservé')
+class _TimelineLaneGroup extends StatelessWidget
+IconData _laneIcon(CinematicTimelineLaneKind laneKind)

packages/map_editor/test/cinematic_builder_workspace_test.dart
+testWidgets('shows lane grouping V0 without enabling actor movement'
+testWidgets('captures V1-48 builder lane grouping screenshot when requested'
+CinematicAsset _laneShowcaseCinematic()
+CinematicAsset _laneVisualGateCinematic()
```

Sorties finales :

```text
flutter analyze --no-fatal-infos lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart test/cinematic_builder_workspace_test.dart
Analyzing 2 items...
No issues found! (ran in 1.2s)

git diff --check

git diff --stat
 packages/map_core/lib/map_core.dart                |   1 +
 .../cinematics/cinematic_builder_workspace.dart    | 156 ++++++++++--
 .../test/cinematic_builder_workspace_test.dart     | 283 ++++++++++++++++++++-
 .../scenes/road_map_scene_builder_authoring.md     |  17 +-
 reports/narrativeStudio/scenes/road_map_scenes.md  |  23 +-
 5 files changed, 437 insertions(+), 43 deletions(-)

git diff --name-only
packages/map_core/lib/map_core.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
packages/map_editor/test/cinematic_builder_workspace_test.dart
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md

git status --short --untracked-files=all
 M packages/map_core/lib/map_core.dart
 M packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
 M packages/map_editor/test/cinematic_builder_workspace_test.dart
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? packages/map_core/lib/src/read_models/cinematic_timeline_lane_read_model.dart
?? packages/map_core/test/cinematic_timeline_lane_read_model_test.dart
?? reports/narrativeStudio/scenes/ns_scenes_v1_48_cinematic_timeline_lane_grouping_v0.md
?? reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_48_cinematic_timeline_lane_grouping_v0.png
```

## 28. Auto-review critique

1. V1-48 a-t-il ajouté une projection pure ? Oui.
2. La projection vit-elle hors Flutter ? Oui, dans `map_core`.
3. Les lanes sont-elles persistées ? Non.
4. `ProjectManifest` ou `CinematicAsset` sont-ils mutés par projection ? Non, test `toJson()` conservé.
5. Les acteurs requis vides sont-ils visibles ? Oui.
6. Les actorId inconnus crashent-ils ? Non.
7. L'ordre linéaire global est-il préservé ? Oui, `stepIndex`.
8. Le Builder sélectionne-t-il depuis une lane ? Oui.
9. L'inspecteur reste-t-il compatible ? Oui.
10. La preview reste-t-elle sandbox ? Oui.
11. Attente/Fondu/Caméra restent-ils fonctionnels ? Oui.
12. Orientation acteur reste-t-elle fonctionnelle ? Oui.
13. `Déplacement acteur` reste-t-il verrouillé ? Oui.
14. Y a-t-il drag/drop ? Non.
15. Y a-t-il reorder ? Non.
16. Y a-t-il preview runtime ? Non.
17. Le design system est-il respecté ? Oui, primitives et tokens existants.
18. Visual Gate produite ? Oui.
19. Roadmaps mises à jour ? Oui.
20. Prochain lot unique recommandé ? `NS-SCENES-V1-49 — Cinematic Actor Movement Block V0`.

## 29. Recommandation pour le prochain lot

Prochain lot exact recommandé :

```text
NS-SCENES-V1-49 — Cinematic Actor Movement Block V0
```

Raison : V1-47 a cadré `actorMove`, V1-48 a rendu la timeline lisible par lanes. Le prochain lot peut donc activer un `actorMove` V0 strictement borné, sans pathfinding, sans drag/drop et sans preview runtime.
