# NS-SCENES-V1-07 — Node Inspector Read-only

## Résumé exécutif

Verdict : DONE.

Le workspace Scènes affiche maintenant un inspecteur read-only du node sélectionné. La sélection reste locale à l'UI, part du `startNodeId` si disponible, se recalcule au changement de scène, et ne modifie jamais `ProjectManifest`.

Le lot reste strictement read-only : aucun authoring, aucun drag and drop, aucun formulaire, aucun runtime, aucun `StorylineStep.sceneLinkIds`, aucune fixture produit.

## Design gate / décision UI

- Sélection node : clic sur une card node réelle dans `SceneGraphReadOnlyView`.
- Sélection par défaut : `startNodeId` si présent, sinon premier node réel.
- Reset : changement de scène = recalcul local du node sélectionné.
- Placement : inspecteur local à droite du graph dans la zone centrale Scènes, proche de la direction cible Scene Builder.
- Contenu : kind, id, title, description, payload summary, edges entrants/sortants.
- Read-only : badge `Lecture seule`, aucun `TextField`, aucun bouton sauver/supprimer/dupliquer.
- Design system : `PokeMapInspectorPanel`, `PokeMapCard`, `PokeMapIconTile`, `PokeMapTone`, `context.pokeMapColors`.

## Scope réalisé

- Sélection locale de node ajoutée au workspace Scènes.
- Highlight visuel local du node sélectionné dans le graph read-only.
- Nouveau widget `SceneNodeReadOnlyInspector`.
- Payload summaries par kind.
- Résumé read-only des edges entrants/sortants.
- Tests widget V1-07 ajoutés.
- Visual Gate V1-07 produit.
- Roadmap mise à jour.

## Fichiers créés/modifiés

Créés :

- `packages/map_editor/lib/src/ui/canvas/scenes/scene_node_read_only_inspector.dart`
- `reports/narrativeStudio/scenes/ns_scenes_v1_07_node_inspector_read_only.md`
- `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_07_node_inspector_read_only.png`

Modifiés :

- `packages/map_editor/lib/src/ui/canvas/scenes_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/scenes/scene_graph_read_only_view.dart`
- `packages/map_editor/test/scenes_workspace_shell_test.dart`
- `reports/narrativeStudio/scenes/road_map_scenes.md`

## Décisions techniques

- `ScenesWorkspace` conserve `_selectedSceneId` et ajoute `_selectedNodeId`.
- `SceneGraphReadOnlyView` reçoit `selectedNodeId` et `onSelectNode`.
- Les nodes restent des cards read-only ; le clic ne fait qu'émettre l'id local.
- `SceneNodeReadOnlyInspector` lit uniquement `scene.graph.nodes`, `scene.graph.edges` et `node.payload`.
- Les payloads sont rendus par pattern matching sur les classes `Scene*Payload`.

## Sélection locale de node

- Auto-selection : `startNodeId` quand il existe.
- Fallback : premier node réel.
- Changement de scène : sélection recalculée.
- Mutation : aucune écriture dans `ProjectManifest`, `SceneAsset`, `SceneGraph` ou `SceneGraphLayout`.

## Payload summaries

Couverture :

- `start` : type, notes, sortie attendue.
- `end` : sceneOutcomeId, notes.
- `yarnDialogue` : dialogueId, yarnNodeName, expectedOutcomes, speakerHints.
- `condition` : conditionLabel, conditionRef, conditionDraft, true/false.
- `action` : actionKind, parameters, completed.
- `battle` : battleKind, trainerId, battleTemplateId, npcEntityId, declaredOutcomes, victory/defeat.
- `cinematic` : cinematicId, completed.
- `branchByOutcome` : sourceNodeId, sourceOutcomeSetRef, fallbackPolicy.
- `merge` : label, notes.

## Edges entrants/sortants

L'inspecteur affiche :

- edges entrants : edge id, kind, node source, selected node, fromPortId ;
- edges sortants : edge id, kind, selected node, node cible, fromPortId.

Les edges ne sont pas éditables et aucun port connectable n'est créé.

## Écarts au prompt éventuels

- Aucun diagnostic avancé ajouté : réservé à un lot dédié.
- Pas de résolution de référence Yarn, battle ou cinematic : l'inspecteur affiche uniquement les ids réels.
- Le prochain lot recommandé reste l'authoring minimal, avec prudence sur diagnostics ensuite.

## Tests exécutés

Rouge TDD :

```text
cd packages/map_editor && flutter test --reporter=compact test/scenes_workspace_shell_test.dart --plain-name 'selects real graph nodes and shows read-only inspector'
Expected: exactly one matching candidate
Actual: _KeyWidgetFinder:<Found 0 widgets with key [<'scene-node-read-only-inspector'>]: []>
```

Tests verts :

```text
cd packages/map_editor && flutter test --reporter=compact test/scenes_workspace_shell_test.dart
00:03 +12: All tests passed!
```

```text
cd packages/map_editor && flutter test --reporter=compact test/ui/canvas/narrative_overview_shell_navigation_test.dart
00:05 +19: All tests passed!
```

```text
cd packages/map_editor && flutter test --reporter=compact test/ui/canvas/narrative_studio_header_test.dart
00:02 +3: All tests passed!
```

```text
cd packages/map_editor && flutter test --reporter=compact test/narrative_workspace_projection_test.dart
00:01 +3: All tests passed!
```

## Résultats exacts

```text
00:01 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/scenes_workspace_shell_test.dart
00:01 +0: NS-SCENES-V1-07 node inspector read-only Narrative Studio exposes a real Scenes navigation entry
00:02 +1: NS-SCENES-V1-07 node inspector read-only Narrative Studio exposes a real Scenes navigation entry
00:02 +1: NS-SCENES-V1-07 node inspector read-only shows an honest empty state when ProjectManifest.scenes is empty
00:02 +2: NS-SCENES-V1-07 node inspector read-only shows an honest empty state when ProjectManifest.scenes is empty
00:02 +2: NS-SCENES-V1-07 node inspector read-only disabled actions do not mutate ProjectManifest
00:02 +3: NS-SCENES-V1-07 node inspector read-only disabled actions do not mutate ProjectManifest
00:02 +3: NS-SCENES-V1-07 node inspector read-only shows real SceneAsset data in the read-only tree and summary
00:02 +4: NS-SCENES-V1-07 node inspector read-only shows real SceneAsset data in the read-only tree and summary
00:02 +4: NS-SCENES-V1-07 node inspector read-only selects real graph nodes and shows read-only inspector
00:02 +5: NS-SCENES-V1-07 node inspector read-only selects real graph nodes and shows read-only inspector
00:02 +5: NS-SCENES-V1-07 node inspector read-only shows battle payload summary in read-only inspector
00:02 +6: NS-SCENES-V1-07 node inspector read-only shows battle payload summary in read-only inspector
00:02 +6: NS-SCENES-V1-07 node inspector read-only scene change recalculates local selected node
00:02 +7: NS-SCENES-V1-07 node inspector read-only scene change recalculates local selected node
00:02 +7: NS-SCENES-V1-07 node inspector read-only uses a derived layout for scenes with incomplete layout
00:02 +8: NS-SCENES-V1-07 node inspector read-only uses a derived layout for scenes with incomplete layout
00:02 +8: NS-SCENES-V1-07 node inspector read-only uses bounded derived layout for cyclic and disconnected graph
00:03 +9: NS-SCENES-V1-07 node inspector read-only uses bounded derived layout for cyclic and disconnected graph
00:03 +9: NS-SCENES-V1-07 node inspector read-only local scene selection updates summary without mutating project
00:03 +10: NS-SCENES-V1-07 node inspector read-only local scene selection updates summary without mutating project
00:03 +10: NS-SCENES-V1-07 node inspector read-only Storylines workspace remains selectable
00:03 +11: NS-SCENES-V1-07 node inspector read-only Storylines workspace remains selectable
00:03 +11: NS-SCENES-V1-07 node inspector read-only writes V1-07 visual gate screenshot
00:03 +12: NS-SCENES-V1-07 node inspector read-only writes V1-07 visual gate screenshot
00:03 +12: All tests passed!
```

## Analyze exact

```text
cd packages/map_editor && flutter analyze --no-fatal-infos lib/src/ui/canvas/scenes_workspace.dart lib/src/ui/canvas/scenes/scene_graph_read_only_view.dart lib/src/ui/canvas/scenes/scene_node_read_only_inspector.dart lib/src/features/narrative/application/narrative_workspace_projection.dart test/scenes_workspace_shell_test.dart test/ui/canvas/narrative_overview_shell_navigation_test.dart test/ui/canvas/narrative_studio_header_test.dart test/narrative_workspace_projection_test.dart
Analyzing 8 items...
No issues found! (ran in 2.0s)
```

## Visual Gate

Chemin :

```text
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_07_node_inspector_read_only.png
```

Commande :

```text
cd packages/map_editor && flutter test --update-goldens --reporter=compact test/scenes_workspace_shell_test.dart --plain-name 'writes V1-07 visual gate screenshot'
00:02 +1: All tests passed!
```

Visible : workspace Scènes, arborescence gauche, scène locale de test sélectionnée, graph read-only central, node Yarn sélectionné, inspecteur read-only visible, payload Yarn visible, edges entrants/sortants, actions non mutantes.

Preuve anti-fake : la scène vient uniquement de la fixture locale du test `scenes_workspace_shell_test.dart`.

## Git status initial

```text
pwd
/Users/karim/Project/pokemonProject

git branch --show-current
main

git status --short --untracked-files=all
Sortie : <vide>

git diff --stat
Sortie : <vide>

git log --oneline -n 10
e3b346c7 feat(scenes): harden graph read-only fallback layout and update tests
d97be401 chore: auto-commit changes
7fcd3c87 chore: auto-commit changes
6bbff623 scènes workspace shell UI
3253c8d5 chore: auto-commit changes
e75b3876 chore: auto-commit changes
00bcaa4d chore: auto-commit changes
a85fc3c4 docs(scenes): add scene system audit and roadmap v1.0.0
af6c491b feat(storylines): update structure layout and tests v1.1.1
04cce3b7 feat(storylines): add structure layout chapter/step readability v1.1.0
```

## Git status final

```text
 M packages/map_editor/lib/src/ui/canvas/scenes/scene_graph_read_only_view.dart
 M packages/map_editor/lib/src/ui/canvas/scenes_workspace.dart
 M packages/map_editor/test/scenes_workspace_shell_test.dart
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? packages/map_editor/lib/src/ui/canvas/scenes/scene_node_read_only_inspector.dart
?? reports/narrativeStudio/scenes/ns_scenes_v1_07_node_inspector_read_only.md
?? reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_07_node_inspector_read_only.png
```

## Git diff --stat

```text
 .../canvas/scenes/scene_graph_read_only_view.dart  | 129 ++++++++-----
 .../lib/src/ui/canvas/scenes_workspace.dart        | 110 +++++++++--
 .../test/scenes_workspace_shell_test.dart          | 203 ++++++++++++++++++---
 reports/narrativeStudio/scenes/road_map_scenes.md  |  22 ++-
 4 files changed, 380 insertions(+), 84 deletions(-)
```

## Git diff --name-only

```text
packages/map_editor/lib/src/ui/canvas/scenes/scene_graph_read_only_view.dart
packages/map_editor/lib/src/ui/canvas/scenes_workspace.dart
packages/map_editor/test/scenes_workspace_shell_test.dart
reports/narrativeStudio/scenes/road_map_scenes.md
```

## Git diff --check

```text
Sortie : <vide>
```

## Evidence Pack

Fichiers lus : tous les fichiers obligatoires existaient.

Commandes principales :

```text
pwd
git branch --show-current
git status --short --untracked-files=all
git diff --stat
git log --oneline -n 10
flutter test --reporter=compact test/scenes_workspace_shell_test.dart --plain-name 'selects real graph nodes and shows read-only inspector'
flutter test --update-goldens --reporter=compact test/scenes_workspace_shell_test.dart --plain-name 'writes V1-07 visual gate screenshot'
flutter test --reporter=compact test/scenes_workspace_shell_test.dart
flutter test --reporter=compact test/ui/canvas/narrative_overview_shell_navigation_test.dart
flutter test --reporter=compact test/ui/canvas/narrative_studio_header_test.dart
flutter test --reporter=compact test/narrative_workspace_projection_test.dart
flutter analyze --no-fatal-infos <fichiers ciblés V1-07>
rg "Color\(0x|Colors\." packages/map_editor/lib/src/ui/canvas/scenes_workspace.dart packages/map_editor/lib/src/ui/canvas/scenes packages/map_editor/test/scenes_workspace_shell_test.dart
rg "fakeScenes|demoScenes|hardcodedSceneList|Annonce au port|Selbrume Demo|Maël|Lysa|Port des Brisants|La brume du phare|Le Goélise" packages/map_editor/lib/src/ui/canvas/scenes_workspace.dart packages/map_editor/lib/src/ui/canvas/scenes packages/map_editor/lib/src/features/narrative/application/narrative_workspace_projection.dart
git status --short --untracked-files=all
git diff --stat
git diff --name-only
git diff --check
```

Recherches :

```text
rg "Color\(0x|Colors\." packages/map_editor/lib/src/ui/canvas/scenes_workspace.dart packages/map_editor/lib/src/ui/canvas/scenes packages/map_editor/test/scenes_workspace_shell_test.dart
Sortie : <vide>

rg "fakeScenes|demoScenes|hardcodedSceneList|Annonce au port|Selbrume Demo|Maël|Lysa|Port des Brisants|La brume du phare|Le Goélise" packages/map_editor/lib/src/ui/canvas/scenes_workspace.dart packages/map_editor/lib/src/ui/canvas/scenes packages/map_editor/lib/src/features/narrative/application/narrative_workspace_projection.dart
Sortie : <vide>
```

Sections modifiées complètes :

```text
scene_graph_read_only_view.dart : signature SceneGraphReadOnlyView enrichie avec selectedNodeId/onSelectNode ; _SceneGraphNodeCard devient cliquable et affiche un highlight local.
scenes_workspace.dart : état local _selectedNodeId, calcul startNodeId/premier node, reset au changement de scène, layout graph + inspector droit.
scene_node_read_only_inspector.dart : nouveau widget complet d'inspection read-only.
scenes_workspace_shell_test.dart : tests V1-07 pour sélection, payload Yarn, payload Battle, edges entrants/sortants, reset et visual gate.
road_map_scenes.md : V1-07 DONE, prochain lot V1-08.
```

## Auto-review critique

- L'inspecteur reste strictement read-only.
- Le placement à droite du graph colle à l'intention cible sans construire le Scene Builder complet.
- Les payload summaries affichent les ids bruts ; c'est volontaire tant que les lots de résolution de références ne sont pas faits.
- Les tests couvrent Yarn et Battle, mais pas tous les payload kinds ; les autres kinds passent par le même switch UI.

## Regard critique sur le prompt

Le prompt est clair. Le seul choix produit notable est le prochain lot : l'authoring minimal est possible, mais un lot de diagnostics pourrait aussi être utile juste après. Recommandation conservée : V1-08 Authoring Minimal Scene Draft, avec diagnostics à garder proches.
