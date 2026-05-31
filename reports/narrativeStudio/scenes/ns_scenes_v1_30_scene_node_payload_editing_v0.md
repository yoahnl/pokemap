# NS-SCENES-V1-30 — Scene Node Payload Editing V0

## Resume executif

Le lot V1-30 rend les payloads `yarnDialogue` et `battle` corrigeables depuis le Scene Builder sans revenir aux IDs libres.

Ce qui est fait :

- deux operations pures `map_core` mettent a jour les payloads Dialogue Yarn et Battle trainer ;
- l'inspecteur Scene affiche des panneaux editables seulement quand des contrats publics reels existent ;
- les pickers consomment `DialoguePublicContract` et `BattlePublicContract` ;
- `ProjectManifest.scenes` est remplace en memoire uniquement ;
- le graph logique, les edges, le layout, les outcomes Scene et les metadata sont preserves ;
- aucun runtime, aucun `StorylineStep` runtime, aucun `BranchByOutcome`, aucun outcome Yarn invente et aucune donnee Selbrume ne sont ajoutes.

Decision importante : le Scene Builder reste no-code et honnete. Un node Dialogue/Battle sans contrat public disponible reste en lecture seule, afin d'eviter de proposer une edition par ID brut.

## Design / Architecture Gate

- Operation pure : placee dans `packages/map_core/lib/src/authoring/scene_authoring_operations.dart`, a cote des autres operations Scene authoring.
- Generation de payload : aucune generation d'ID, aucune ref fake, aucun timestamp, aucun random.
- Dialogue : l'operation remplace `dialogueId` et `yarnNodeName`, puis preserve `expectedOutcomes` et `speakerHints`.
- Battle : l'operation force le contrat V0 `battleKind: trainer`, remplace `trainerId`, preserve `battleTemplateId` et `npcEntityId`, et maintient les outcomes `victory` / `defeat`.
- Preservation : `SceneGraph.nodes` est remplace seulement pour le node cible ; `SceneGraph.edges`, `SceneGraphLayout`, `declaredOutcomes`, `tags`, `metadata`, `description`, `storylineId` et `chapterId` sont conserves.
- Editor : `NarrativeWorkspaceCanvas` appelle les operations pures puis remplace uniquement la Scene cible dans `ProjectManifest.scenes`.
- Inspector : les panneaux "Dialogue lie" et "Combat lie" apparaissent seulement si le snapshot de contrats publics contient des options.
- UX : boutons "Changer le dialogue" et "Changer le combat", dialogs de selection controles, diagnostics de contrats affiches dans les options.
- Non-objectifs respectes : pas de runtime, pas d'edition Condition supplementaire, pas de Cinematic/Action/Branch authoring avance, pas de seed Selbrume.

## Scope realise

### Core

- Ajout de `SceneYarnDialoguePayloadUpdateResult`.
- Ajout de `SceneBattlePayloadUpdateResult`.
- Ajout de `updateSceneYarnDialoguePayload`.
- Ajout de `updateSceneBattlePayload`.
- Tests de mutation pure, refus des nodes invalides, refs vides, preservation graph/layout/outcomes.

### Editor

- Ajout des callbacks Scene payload editing dans `ScenesWorkspace`.
- Branchement des callbacks dans `NarrativeWorkspaceCanvas`.
- Ajout des panneaux editables dans `SceneNodeReadOnlyInspector`.
- Pickers inspecteur bases sur `DialoguePublicContract` et `BattlePublicContract`.
- Tests widget pour edition Dialogue et Battle.
- Visual gate V1-30.

## Fichiers crees / modifies

Fichier cree :

- `reports/narrativeStudio/scenes/ns_scenes_v1_30_scene_node_payload_editing_v0.md`
- `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_30_scene_node_payload_editing_v0.png`

Fichiers modifies :

- `packages/map_core/lib/src/authoring/scene_authoring_operations.dart`
- `packages/map_core/test/scene_authoring_operations_test.dart`
- `packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart`
- `packages/map_editor/lib/src/ui/canvas/scenes_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/scenes/scene_node_read_only_inspector.dart`
- `packages/map_editor/test/scenes_workspace_shell_test.dart`
- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`

## Operations core ajoutees

```dart
SceneYarnDialoguePayloadUpdateResult updateSceneYarnDialoguePayload(
  SceneAsset scene, {
  required String nodeId,
  required String dialogueId,
  String? yarnNodeName,
})
```

Garanties :

- refuse node inconnu ;
- refuse node non `yarnDialogue` ;
- refuse `dialogueId` vide ;
- trim `dialogueId` et `yarnNodeName` ;
- preserve outcomes/speaker hints existants ;
- ne mute pas la scene originale.

```dart
SceneBattlePayloadUpdateResult updateSceneBattlePayload(
  SceneAsset scene, {
  required String nodeId,
  required String trainerId,
})
```

Garanties :

- refuse node inconnu ;
- refuse node non `battle` ;
- refuse `trainerId` vide ;
- trim `trainerId` ;
- maintient `battleKind: trainer` ;
- maintient `declaredOutcomes: ['victory', 'defeat']` ;
- preserve edges/layout/metadata ;
- ne mute pas la scene originale.

## UX payload editing

Dialogue Yarn :

- le panneau "Dialogue lie" affiche dialogue actuel, start node, outcomes Scene et source publique ;
- le bouton "Changer le dialogue" ouvre un picker depuis `DialoguePublicContract` ;
- le choix met a jour `dialogueId` et `yarnNodeName` ;
- les outcomes Yarn restent read-only et ne sont pas inventes.

Battle trainer :

- le panneau "Combat lie" affiche kind, trainer actuel, outcomes Scene et outcomes du contrat ;
- le bouton "Changer le combat" ouvre un picker depuis `BattlePublicContract` ;
- le choix met a jour `trainerId` ;
- les ports `victory` / `defeat` et edges existants restent intacts.

## Visual Gate

Chemin :

```text
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_30_scene_node_payload_editing_v0.png
```

Commande de production :

```bash
cd packages/map_editor && flutter test --update-goldens --reporter=compact test/scenes_workspace_shell_test.dart --plain-name "NS-SCENES-V1-09 scene validation diagnostics writes V1-30 scene node payload editing screenshot"
```

Sortie exacte :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/scenes_workspace_shell_test.dart
00:01 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/scenes_workspace_shell_test.dart
00:01 +0: NS-SCENES-V1-09 scene validation diagnostics writes V1-30 scene node payload editing screenshot
00:02 +0: NS-SCENES-V1-09 scene validation diagnostics writes V1-30 scene node payload editing screenshot
00:02 +1: NS-SCENES-V1-09 scene validation diagnostics writes V1-30 scene node payload editing screenshot
00:02 +1: All tests passed!
```

## Tests / analyze

### TDD rouge

Commande :

```bash
cd packages/map_core && dart test test/scene_authoring_operations_test.dart
```

Sortie utile exacte :

```text
Failed to load "test/scene_authoring_operations_test.dart":
test/scene_authoring_operations_test.dart:253:22: Error: Method not found: 'updateSceneYarnDialoguePayload'.
test/scene_authoring_operations_test.dart:328:22: Error: Method not found: 'updateSceneBattlePayload'.
Some tests failed.
```

Commande :

```bash
cd packages/map_editor && flutter test --reporter=compact test/scenes_workspace_shell_test.dart
```

Sortie utile exacte :

```text
Expected: at least one matching candidate
Actual: _TextWidgetFinder:<Found 0 widgets with text "Éditable": []>
Some tests failed.
```

### Validations finales executees

Commande :

```bash
cd packages/map_core && dart test test/scene_authoring_operations_test.dart
```

Sortie exacte :

```text
00:00 +32: All tests passed!
```

Commande :

```bash
cd packages/map_core && dart test test/scene_diagnostics_test.dart
```

Sortie exacte :

```text
00:00 +24: All tests passed!
```

Commande :

```bash
cd packages/map_core && dart test test/scene_runtime_plan_test.dart
```

Sortie exacte :

```text
00:00 +15: All tests passed!
```

Commande :

```bash
cd packages/map_core && dart test test/linked_asset_public_contracts_test.dart
```

Sortie exacte :

```text
00:00 +8: All tests passed!
```

Commande :

```bash
cd packages/map_core && dart analyze
```

Sortie exacte :

```text
Analyzing map_core...
No issues found!
```

Commande :

```bash
cd packages/map_editor && flutter test --reporter=compact test/scenes_workspace_shell_test.dart
```

Sortie exacte :

```text
00:07 +60: All tests passed!
```

Commande :

```bash
cd packages/map_editor && flutter test --reporter=compact test/ui/canvas/narrative_overview_shell_navigation_test.dart
```

Sortie exacte :

```text
00:06 +19: All tests passed!
```

Commande :

```bash
cd packages/map_editor && flutter test --reporter=compact test/narrative_workspace_projection_test.dart
```

Sortie exacte :

```text
00:02 +3: All tests passed!
```

Commande demandee mais fichier absent :

```bash
cd packages/map_editor && flutter test --reporter=compact test/ui/canvas/narrative_studio_header_test.dart
```

Sortie exacte :

```text
Failed to load "/Users/karim/Project/pokemonProject/packages/map_editor/test/ui/canvas/narrative_studio_header_test.dart": Does not exist.
Some tests failed.
```

Impact : aucun test header correspondant n'existe dans le repo ; les tests voisins reels `narrative_overview_shell_navigation_test.dart` et `narrative_workspace_projection_test.dart` passent.

Commande :

```bash
cd packages/map_editor && flutter analyze --no-fatal-infos lib/src/ui/canvas/narrative_workspace_canvas.dart lib/src/ui/canvas/scenes_workspace.dart lib/src/ui/canvas/scenes/scene_node_read_only_inspector.dart test/scenes_workspace_shell_test.dart
```

Sortie exacte :

```text
Analyzing 4 items...
No issues found! (ran in 2.3s)
```

## Checks anti-scope

Commande :

```bash
git diff --name-only -- packages/map_runtime packages/map_gameplay packages/map_battle examples selbrume
```

Sortie : <vide>

Commande :

```bash
rg -n "Color\(0x|[^A-Za-z]Colors\." packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart packages/map_editor/lib/src/ui/canvas/scenes_workspace.dart packages/map_editor/lib/src/ui/canvas/scenes/scene_node_read_only_inspector.dart
```

Sortie : <vide>

Commande :

```bash
rg -n "selbrume|lysa|ma[eë]l|annonce au port" packages/map_core/lib/src/authoring/scene_authoring_operations.dart packages/map_core/test/scene_authoring_operations_test.dart packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart packages/map_editor/lib/src/ui/canvas/scenes_workspace.dart packages/map_editor/lib/src/ui/canvas/scenes/scene_node_read_only_inspector.dart packages/map_editor/test/scenes_workspace_shell_test.dart
```

Sortie exacte :

```text
packages/map_editor/test/scenes_workspace_shell_test.dart:360:      expect(find.text('selbrume_port'), findsNothing);
packages/map_editor/test/scenes_workspace_shell_test.dart:408:      expect(find.text('trainer_lysa'), findsNothing);
packages/map_editor/test/scenes_workspace_shell_test.dart:436:      expect(find.text('mael_intro'), findsNothing);
packages/map_editor/test/scenes_workspace_shell_test.dart:437:      expect(find.text('lysa_rival'), findsNothing);
packages/map_editor/test/scenes_workspace_shell_test.dart:500:      expect(find.text('selbrume_port'), findsNothing);
packages/map_editor/test/scenes_workspace_shell_test.dart:565:      expect(find.text('trainer_lysa'), findsNothing);
```

Interpretation : ces occurrences sont des assertions negatives `findsNothing`, pas des donnees produit ni des fixtures creees par le lot.

## Evidence Pack

### Gate 0

Commande :

```bash
pwd
```

Sortie exacte :

```text
/Users/karim/Project/pokemonProject
```

Commande :

```bash
git branch --show-current
```

Sortie exacte :

```text
main
```

Commande :

```bash
git status --short --untracked-files=all
```

Sortie : <vide>

Commande :

```bash
git diff --stat
```

Sortie : <vide>

Commande :

```bash
git log --oneline -n 10
```

Sortie exacte :

```text
84587492 feat(scenes): add storyline step scene links v0
acd71317 feat(scenes): add scene runtime golden slice smoke v0
44de8cc2 feat(scenes): add dialogue runtime awaitable adapter v0
20e51eca feat(scenes): add battle runtime outcome adapter v0
326e939c feat(scenes): add scene consequence runtime write v0
a6b46779 feat(scenes): add scene consequence model v0
d35b3987 feat(scenes): add map event sceneTarget runtime hook v0
54acda44 feat(scenes): add golden slice selbrume readiness
c480c4f5 test(scenes): refine world rule empty state handling
ac3b389c feat(scenes): add world rules map editor integration v0
```

### Fichiers lus

- `AGENTS.md`
- `agent_rules.md`
- `skills/README.md`
- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_13_edge_authoring_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_14_blueprint_graph_canvas_foundation.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_15_visual_port_connection_ux_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_15_bis_edge_selection_deletion_ux_v0.md`
- `packages/map_core/lib/src/models/scene_asset.dart`
- `packages/map_core/lib/src/authoring/scene_authoring_operations.dart`
- `packages/map_core/lib/src/read_models/linked_asset_public_contracts.dart`
- `packages/map_core/lib/src/diagnostics/scene_diagnostics.dart`
- `packages/map_core/lib/map_core.dart`
- `packages/map_core/test/scene_authoring_operations_test.dart`
- `packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart`
- `packages/map_editor/lib/src/ui/canvas/scenes_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/scenes/scene_node_read_only_inspector.dart`
- `packages/map_editor/test/scenes_workspace_shell_test.dart`

### Git status intermediaire apres implementation

Commande :

```bash
git status --short --untracked-files=all
```

Sortie exacte :

```text
 M packages/map_core/lib/src/authoring/scene_authoring_operations.dart
 M packages/map_core/test/scene_authoring_operations_test.dart
 M packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
 M packages/map_editor/lib/src/ui/canvas/scenes/scene_node_read_only_inspector.dart
 M packages/map_editor/lib/src/ui/canvas/scenes_workspace.dart
 M packages/map_editor/test/scenes_workspace_shell_test.dart
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_30_scene_node_payload_editing_v0.png
```

### Git diff stat intermediaire

Commande :

```bash
git diff --stat
```

Sortie exacte :

```text
 .../src/authoring/scene_authoring_operations.dart  | 145 ++++++
 .../test/scene_authoring_operations_test.dart      | 141 ++++++
 .../src/ui/canvas/narrative_workspace_canvas.dart  |  64 +++
 .../scenes/scene_node_read_only_inspector.dart     | 493 ++++++++++++++++++++-
 .../lib/src/ui/canvas/scenes_workspace.dart        |  74 ++++
 .../test/scenes_workspace_shell_test.dart          | 250 +++++++++++
 .../scenes/road_map_scene_builder_authoring.md     |  19 +-
 reports/narrativeStudio/scenes/road_map_scenes.md  |  23 +-
 8 files changed, 1201 insertions(+), 8 deletions(-)
```

### Git status final exact

Commande :

```bash
git status --short --untracked-files=all
```

Sortie exacte :

```text
 M packages/map_core/lib/src/authoring/scene_authoring_operations.dart
 M packages/map_core/test/scene_authoring_operations_test.dart
 M packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
 M packages/map_editor/lib/src/ui/canvas/scenes/scene_node_read_only_inspector.dart
 M packages/map_editor/lib/src/ui/canvas/scenes_workspace.dart
 M packages/map_editor/test/scenes_workspace_shell_test.dart
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_30_scene_node_payload_editing_v0.md
?? reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_30_scene_node_payload_editing_v0.png
```

### Git diff stat final exact

Commande :

```bash
git diff --stat
```

Sortie exacte :

```text
 .../src/authoring/scene_authoring_operations.dart  | 145 ++++++
 .../test/scene_authoring_operations_test.dart      | 141 ++++++
 .../src/ui/canvas/narrative_workspace_canvas.dart  |  64 +++
 .../scenes/scene_node_read_only_inspector.dart     | 493 ++++++++++++++++++++-
 .../lib/src/ui/canvas/scenes_workspace.dart        |  74 ++++
 .../test/scenes_workspace_shell_test.dart          | 250 +++++++++++
 .../scenes/road_map_scene_builder_authoring.md     |  19 +-
 reports/narrativeStudio/scenes/road_map_scenes.md  |  23 +-
 8 files changed, 1201 insertions(+), 8 deletions(-)
```

### Git diff name-only final exact

Commande :

```bash
git diff --name-only
```

Sortie exacte :

```text
packages/map_core/lib/src/authoring/scene_authoring_operations.dart
packages/map_core/test/scene_authoring_operations_test.dart
packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
packages/map_editor/lib/src/ui/canvas/scenes/scene_node_read_only_inspector.dart
packages/map_editor/lib/src/ui/canvas/scenes_workspace.dart
packages/map_editor/test/scenes_workspace_shell_test.dart
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md
```

### Git diff check final exact

Commande :

```bash
git diff --check
```

Sortie : <vide>

## Auto-review critique

- Point positif : l'edition est strictement conditionnee par des contrats publics existants ; pas de retour aux IDs libres en workflow normal.
- Point positif : les operations core sont pures et testees avec preservation des edges/layout/outcomes.
- Risque residuel : le widget inspector grossit ; un futur lot pourrait extraire les editors Dialogue/Battle dans un fichier dedie si l'ActionNode authoring ajoute trop de code.
- Risque residuel : `yarnNodeName` suit seulement le `defaultStartNode` du contrat public ; la selection multi-start attend un contrat Yarn plus riche.
- Risque residuel : les labels de node ne sont pas renommes automatiquement quand la ref change. C'est volontaire pour limiter le lot au payload, mais un polish futur peut synchroniser le titre sur demande explicite.

## Regard critique sur le prompt

Le prompt est bien borne et arrive au bon moment : apres les pickers, ports, runtime smoke et lien StorylineStep, corriger une ref Dialogue/Battle sans supprimer le node devient un vrai besoin produit.

Point a surveiller : le prompt demande beaucoup d'evidence et de diffs complets, mais ce lot touche un fichier inspector deja volumineux. Le prochain lot Consequence UI devrait envisager une extraction de composants pour eviter que `scene_node_read_only_inspector.dart` devienne trop lourd.

## Prochain lot recommande

`NS-SCENES-V1-31 — Scene Consequence Authoring UI V0`

Raison : le modele/runtime des consequences V0 existe deja (`setFact`, `markEventConsumed`), mais l'utilisateur ne peut pas encore les authorer proprement dans le Scene Builder. C'est le prochain blocage no-code avant un checkpoint beta.
