# NS-SCENES-V1-12 — Node Authoring V0

## Résumé exécutif

V1-12 ajoute le premier authoring réel de nodes Scene V1.

Réalisé :

- opération pure `addSceneNodeDraft` côté `map_core` ;
- palette V0 côté `map_editor` ;
- ajout de nodes `condition`, `merge`, `end` uniquement ;
- mise à jour en mémoire de `ProjectManifest.scenes` ;
- sélection automatique du node ajouté ;
- graph et inspecteur mis à jour ;
- nodes non supportés visibles mais désactivés ;
- aucun edge automatique ;
- aucune fake ref.

Le lot ne branche pas runtime, Storylines, Event -> Scene, Yarn/Battle/Cinematic/Action authoring, edge authoring, drag and drop ou layout authoring.

## Design / architecture gate

Décisions :

- L'opération pure reste dans `packages/map_core/lib/src/authoring/scene_authoring_operations.dart`, à côté de `createSceneDraftInProject`.
- `SceneNodeDraftCreationResult` retourne `updatedScene` + `createdNode`.
- Les IDs sont déterministes : `node_condition`, `node_merge`, `node_end_2`, puis suffixe numérique.
- Le layout initial est créé dans `SceneGraphLayout` sans muter le layout existant.
- Position : à droite de `afterNodeId` si son layout existe, sinon à droite du node le plus à droite, sinon fallback par index.
- Les kinds non autorisés V0 sont refusés par `ArgumentError`.
- Les edges, declared outcomes, tags, metadata, storylineId/chapterId, description sont reconstruits à l'identique.
- Côté editor, `NarrativeWorkspaceCanvas` remplace uniquement la scène cible dans `ProjectManifest.scenes`, puis applique le manifest en mémoire via `EditorNotifier.applyInMemoryProjectManifest`.
- La palette est dans le header local du graph, pas dans la sidebar globale.
- Les nodes non supportés sont affichés désactivés avec raison courte.
- Le node ajouté devient sélection locale.
- Aucun edge n'est créé, aucune connexion de port n'est exposée.
- Aucune fake ref : pas de `dialogueId`, `actionKind`, `battleKind`, `cinematicId`, `sourceOutcome` inventé.

## Scope réalisé

Core :

- ajout de `SceneNodeDraftCreationResult` ;
- ajout de `addSceneNodeDraft` ;
- tests unitaires couvrant condition/merge/end, collisions, layout, non mutation, refus des kinds interdits.

Editor :

- callback `onAddNodeDraft` dans `ScenesWorkspace` ;
- mutation mémoire `ProjectManifest.scenes` dans `NarrativeWorkspaceCanvas` ;
- palette `Ajouter un nœud` ;
- sélection automatique du node créé ;
- tests widget pour ajout Condition/Merge/Fin, disabled states, absence d'edge automatique.

Visual gate :

```text
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_12_node_authoring_v0.png
```

Roadmaps :

- V1-12 marqué DONE.
- prochain lot recommandé : `NS-SCENES-V1-13 — Edge Authoring V0`.

## Fichiers créés/modifiés

Créés :

```text
reports/narrativeStudio/scenes/ns_scenes_v1_12_node_authoring_v0.md
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_12_node_authoring_v0.png
```

Modifiés :

```text
packages/map_core/lib/src/authoring/scene_authoring_operations.dart
packages/map_core/test/scene_authoring_operations_test.dart
packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
packages/map_editor/lib/src/ui/canvas/scenes_workspace.dart
packages/map_editor/test/scenes_workspace_shell_test.dart
reports/narrativeStudio/scenes/road_map_scenes.md
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
```

## Décisions techniques

- Pas de nouveau fichier core : l'opération est cohérente avec `scene_authoring_operations.dart`.
- Pas de modification `SceneAsset` / `ProjectManifest`.
- Pas de diagnostics supplémentaires dans V1-12 : `conditionIncomplete` reste pour V1-17 Diagnostics Expansion.
- Les anciens goldens V1-08/V1-09 restent des artefacts historiques ; leurs tests ont été convertis en checks fonctionnels, car l'UI V1-12 ajoute une palette qui change légitimement le rendu.
- `flutter test --update-goldens` a été utilisé pour produire le screenshot V1-12.

## Opération core ajoutée

Signature :

```dart
SceneNodeDraftCreationResult addSceneNodeDraft(
  SceneAsset scene, {
  required SceneNodeKind kind,
  String? title,
  String? afterNodeId,
})
```

Garanties :

- ne mute pas la scène originale ;
- conserve nodes existants ;
- conserve edges existants ;
- conserve declared outcomes ;
- conserve tags / metadata / description / storylineId / chapterId ;
- ajoute un node ;
- ajoute un layout ;
- gère collision d'ID ;
- refuse les kinds hors V0.

## Nodes supportés

| Kind | Payload | Title par défaut | ID de base |
|---|---|---|---|
| `condition` | `SceneConditionPayload()` | `Condition` | `node_condition` |
| `merge` | `SceneMergePayload()` | `Merge` | `node_merge` |
| `end` | `SceneEndPayload()` | `Fin` | `node_end` puis `node_end_2` si `node_end` existe |

## Nodes refusés / désactivés

Refusés côté core et désactivés côté editor :

```text
start
yarnDialogue
action
battle
cinematic
branchByOutcome
```

Raisons UI :

```text
Début — déjà unique
Dialogue — picker requis
Action — registre requis
Combat — picker requis
Cinématique — picker requis
Branche — source requise
```

## Layout initial

Stratégie :

```text
1. Si afterNodeId a un layout : x = source.x + 300, y = source.y.
2. Sinon : même règle depuis le layout le plus à droite.
3. Sinon : x = 24 + nodeCount * 300, y = 80.
```

Le layout est stable, non random, sans timestamp, et ne modifie pas les positions existantes.

## Intégration editor

`ScenesWorkspace` reçoit :

```dart
SceneNodeDraftCreator onAddNodeDraft
```

`NarrativeWorkspaceCanvas` :

- trouve la scène dans `ProjectManifest.scenes` ;
- appelle `addSceneNodeDraft` ;
- remplace uniquement cette scène ;
- applique le manifest en mémoire ;
- retourne `createdNode.id`.

Après ajout :

- le node apparaît dans le graph ;
- le node est sélectionné ;
- l'inspecteur affiche le node ;
- aucun edge n'est créé automatiquement.

## Tests exécutés

### RED core attendu

Commande :

```bash
cd packages/map_core && dart test test/scene_authoring_operations_test.dart
```

Résultat exact utile :

```text
Failed to load "test/scene_authoring_operations_test.dart":
test/scene_authoring_operations_test.dart:102:22: Error: Method not found: 'addSceneNodeDraft'.
...
00:00 +0 -1: Some tests failed.
```

### Tests core

Commande :

```bash
cd packages/map_core && dart test test/scene_authoring_operations_test.dart
```

Résultat exact :

```text
00:00 +7: All tests passed!
```

### Génération visual gate

Commande :

```bash
cd packages/map_editor && flutter test --update-goldens --reporter=compact test/scenes_workspace_shell_test.dart
```

Résultat exact :

```text
00:05 +22: All tests passed!
```

### Tests editor ciblés

Commande :

```bash
cd packages/map_editor && flutter test --reporter=compact test/scenes_workspace_shell_test.dart
```

Résultat exact :

```text
00:05 +22: All tests passed!
```

Commande :

```bash
cd packages/map_editor && flutter test --reporter=compact test/ui/canvas/narrative_overview_shell_navigation_test.dart
```

Résultat exact :

```text
00:05 +19: All tests passed!
```

Commande :

```bash
cd packages/map_editor && flutter test --reporter=compact test/ui/canvas/narrative_studio_header_test.dart
```

Résultat exact :

```text
00:02 +3: All tests passed!
```

Commande :

```bash
cd packages/map_editor && flutter test --reporter=compact test/narrative_workspace_projection_test.dart
```

Résultat exact :

```text
00:01 +3: All tests passed!
```

### Note sur un échec non fonctionnel

Une tentative de lancer trois commandes Flutter en parallèle a échoué sur le startup lock/native assets :

```text
Failed to change install names in LocalFile: '/Users/karim/Project/pokemonProject/packages/map_editor/build/native_assets/macos/objective_c.dylib'
```

Les mêmes tests ont été relancés séquentiellement et passent.

## Analyze exact

Commande :

```bash
cd packages/map_core && dart analyze
```

Résultat exact :

```text
Analyzing map_core...
No issues found!
```

Commande :

```bash
cd packages/map_editor && flutter analyze --no-fatal-infos lib/src/ui/canvas/narrative_workspace_canvas.dart lib/src/ui/canvas/scenes_workspace.dart test/scenes_workspace_shell_test.dart
```

Résultat exact :

```text
Analyzing 3 items...
No issues found! (ran in 1.7s)
```

## Visual gate

Chemin :

```text
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_12_node_authoring_v0.png
```

Commande :

```bash
cd packages/map_editor && flutter test --update-goldens --reporter=compact test/scenes_workspace_shell_test.dart
```

Visible :

- workspace Scènes ;
- palette `Ajouter un nœud` ;
- node Condition ajouté ;
- node ajouté sélectionné ;
- inspecteur affichant ce node ;
- nodes non supportés désactivés ;
- aucun edge automatique ;
- aucune donnée Selbrume produit.

Preuve anti-fake data :

- la scène est une fixture de test locale ;
- aucun seed produit ;
- aucun `dialogueId`, `actionKind`, `battleKind`, `cinematicId`, `sourceOutcome` inventé par le code produit.

## Git status initial

Commande :

```bash
pwd; git branch --show-current; git status --short --untracked-files=all; git diff --stat; git log --oneline -n 10
```

Sortie exacte :

```text
/Users/karim/Project/pokemonProject
main
79df007c docs(scenes): add scene graph draft node strategy report
4fbfead4 docs(scenes): add scene builder runtime and authoring roadmap alignment
68df7710 docs(scenes): add runtime execution preparation report
ba6ec6e2 feat(scenes): add scene validation diagnostics and update tests
f9095001 feat(scenes): add minimal scene draft authoring operations and tests
c1bf1c76 feat(scenes): add read-only node inspector and update workspace tests
e3b346c7 feat(scenes): harden graph read-only fallback layout and update tests
d97be401 chore: auto-commit changes
7fcd3c87 chore: auto-commit changes
6bbff623 scènes workspace shell UI
```

Interprétation :

```text
pwd : /Users/karim/Project/pokemonProject
git branch --show-current : main
git status initial : Sortie : <vide>
git diff --stat initial : Sortie : <vide>
```

## Git status final

```text
 M packages/map_core/lib/src/authoring/scene_authoring_operations.dart
 M packages/map_core/test/scene_authoring_operations_test.dart
 M packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
 M packages/map_editor/lib/src/ui/canvas/scenes_workspace.dart
 M packages/map_editor/test/scenes_workspace_shell_test.dart
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_12_node_authoring_v0.md
?? reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_12_node_authoring_v0.png
```

## Git diff --stat

```text
 .../src/authoring/scene_authoring_operations.dart  | 166 +++++++++++++++++++++
 .../test/scene_authoring_operations_test.dart      |  94 +++++++++++-
 .../src/ui/canvas/narrative_workspace_canvas.dart  |  25 ++++
 .../lib/src/ui/canvas/scenes_workspace.dart        | 159 ++++++++++++++++++++
 .../test/scenes_workspace_shell_test.dart          | 151 +++++++++++++++++--
 .../scenes/road_map_scene_builder_authoring.md     |  12 +-
 reports/narrativeStudio/scenes/road_map_scenes.md  |  28 +++-
 7 files changed, 620 insertions(+), 15 deletions(-)
```

## Git diff --name-only

```text
packages/map_core/lib/src/authoring/scene_authoring_operations.dart
packages/map_core/test/scene_authoring_operations_test.dart
packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
packages/map_editor/lib/src/ui/canvas/scenes_workspace.dart
packages/map_editor/test/scenes_workspace_shell_test.dart
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md
```

## Git diff --check

```text
Sortie : <vide>
```

## Evidence Pack

### pwd

```text
/Users/karim/Project/pokemonProject
```

### git branch --show-current

```text
main
```

### git status initial exact

```text
Sortie : <vide>
```

### git diff --stat initial

```text
Sortie : <vide>
```

### git log --oneline -n 10

```text
79df007c docs(scenes): add scene graph draft node strategy report
4fbfead4 docs(scenes): add scene builder runtime and authoring roadmap alignment
68df7710 docs(scenes): add runtime execution preparation report
ba6ec6e2 feat(scenes): add scene validation diagnostics and update tests
f9095001 feat(scenes): add minimal scene draft authoring operations and tests
c1bf1c76 feat(scenes): add read-only node inspector and update workspace tests
e3b346c7 feat(scenes): harden graph read-only fallback layout and update tests
d97be401 chore: auto-commit changes
7fcd3c87 chore: auto-commit changes
6bbff623 scènes workspace shell UI
```

### Contenu complet des fichiers créés

Fichier créé :

```text
reports/narrativeStudio/scenes/ns_scenes_v1_12_node_authoring_v0.md
```

Contenu complet : le présent document.

Fichier créé :

```text
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_12_node_authoring_v0.png
```

Fichier PNG binaire généré par le test golden V1-12. Chemin, commande et contenu visuel documentés dans la section Visual gate.

### Sections modifiées principales

`scene_authoring_operations.dart` :

- `SceneNodeDraftCreationResult`
- `addSceneNodeDraft`
- `_uniqueNodeId`
- `_isSupportedDraftNodeKind`
- `_nodeIdBaseForKind`
- `_defaultTitleForKind`
- `_layoutForNewNode`
- `_rightMostLayout`

`scenes_workspace.dart` :

- `SceneNodeDraftCreator`
- callback `_addNodeDraft`
- palette `_SceneNodeDraftPalette`
- boutons `_NodeDraftButton`

`narrative_workspace_canvas.dart` :

- callback `onAddNodeDraft` qui remplace uniquement la scène cible dans `ProjectManifest.scenes`.

`scenes_workspace_shell_test.dart` :

- tests d'ajout Condition / Merge / Fin ;
- tests nodes désactivés ;
- visual gate V1-12 ;
- anciens checks visuels V1-08/V1-09 convertis en flows fonctionnels.

### Diff documenté

Les sections modifiées complètes sont listées dans ce rapport. Le fichier PNG binaire est documenté par chemin, commande et visual gate.

### Sorties exactes des tests ciblés

Voir sections `Tests exécutés` et `Analyze exact`.

### Visual gate

Voir section `Visual gate`.

### git status final exact

```text
 M packages/map_core/lib/src/authoring/scene_authoring_operations.dart
 M packages/map_core/test/scene_authoring_operations_test.dart
 M packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
 M packages/map_editor/lib/src/ui/canvas/scenes_workspace.dart
 M packages/map_editor/test/scenes_workspace_shell_test.dart
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_12_node_authoring_v0.md
?? reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_12_node_authoring_v0.png
```

### git diff --stat final

```text
 .../src/authoring/scene_authoring_operations.dart  | 166 +++++++++++++++++++++
 .../test/scene_authoring_operations_test.dart      |  94 +++++++++++-
 .../src/ui/canvas/narrative_workspace_canvas.dart  |  25 ++++
 .../lib/src/ui/canvas/scenes_workspace.dart        | 159 ++++++++++++++++++++
 .../test/scenes_workspace_shell_test.dart          | 151 +++++++++++++++++--
 .../scenes/road_map_scene_builder_authoring.md     |  12 +-
 reports/narrativeStudio/scenes/road_map_scenes.md  |  28 +++-
 7 files changed, 620 insertions(+), 15 deletions(-)
```

### git diff --name-only final

```text
packages/map_core/lib/src/authoring/scene_authoring_operations.dart
packages/map_core/test/scene_authoring_operations_test.dart
packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
packages/map_editor/lib/src/ui/canvas/scenes_workspace.dart
packages/map_editor/test/scenes_workspace_shell_test.dart
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md
```

### git diff --check final

```text
Sortie : <vide>
```

## Auto-review critique

Ce qui est prouvé :

- core operation pure testée ;
- mutation mémoire editor testée ;
- nodes autorisés V0 ajoutables ;
- nodes interdits désactivés/refusés ;
- absence d'edge automatique testée ;
- screenshot V1-12 produit ;
- analyzes ciblés verts.

Ce qui reste hors scope :

- diagnostics `conditionIncomplete` ;
- edge authoring ;
- drag and drop ;
- layout authoring interactif ;
- payload pickers ;
- runtime.

Risque :

- La palette ajoute une rangée visuelle au graph. Elle reste compacte, mais V1-13 devra surveiller l'espace vertical pour garder le graph dominant.

## Regard critique sur le prompt

Le prompt est bien cadré : il force un premier authoring réel sans ouvrir les refs dangereuses. La contrainte la plus importante était anti-fake refs ; elle justifie de garder `Action`, `Yarn`, `Battle`, `Cinematic` et `Branch` désactivés malgré la tentation Blueprint-like.

Le seul point sensible est le visual gate : les anciens goldens V1-08/V1-09 deviennent naturellement obsolètes dès qu'une palette V1-12 apparaît. Les conserver comme comparaisons pixel serait trompeur ; ils ont donc été transformés en flows fonctionnels, et le screenshot V1-12 devient le visual gate actif.
