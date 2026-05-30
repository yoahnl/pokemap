# NS-SCENES-V1-24 — Scene Runtime Plan V0

## 1. Résumé du lot

`NS-SCENES-V1-24` ajoute le premier plan runtime pur de Scene V1 dans `map_core`.

Le flux livré reste volontairement borné :

```text
SceneAsset
-> buildSceneRuntimePlan(scene)
-> SceneRuntimePlanBuildResult
```

Le lot ne lance aucune scène. Il ne branche pas `MapEventPage.sceneTarget` au runtime. Il ne crée pas de `SceneRuntimeExecutor`. Il ne promeut pas `ScenarioAsset`.

## 2. Rappel du scope

Réalisé :

- modèle pur `SceneRuntimePlan` ;
- modèle `SceneRuntimePlanNode` ;
- modèle `SceneRuntimePlanIntent` ;
- modèle `SceneRuntimePlanEdge` ;
- modèle `SceneRuntimePlanDiagnostic` ;
- modèle `SceneRuntimePlanBuildResult` ;
- builder pur `buildSceneRuntimePlan(SceneAsset)` ;
- export public via `map_core.dart` ;
- tests map_core ciblés ;
- roadmaps mises à jour.

Non-objectifs respectés :

- pas de runtime Scene ;
- pas de `SceneRuntimeExecutor` ;
- pas de modification `map_runtime` ;
- pas de modification `map_editor` hors roadmaps/rapport ;
- pas de `ScenarioRuntimeExecutor` modifié ;
- pas d’Event -> Scene runtime trigger ;
- pas de `StorylineStep.sceneLinkIds` ;
- pas de migration `ScenarioAsset` ;
- pas de fake refs/outcomes ;
- pas de données Selbrume.

## 3. Gate 0 complet

Commande exécutée depuis la racine :

```bash
pwd
git branch --show-current
git status --short --untracked-files=all
git diff --stat
git diff --name-only
git log --oneline -n 10
```

Sorties exactes :

```text
/Users/karim/Project/pokemonProject
main
git status initial :
Sortie : <vide>
git diff --stat initial :
Sortie : <vide>
git diff --name-only initial :
Sortie : <vide>
540d5377 feat(scenes): add event page scene link V0
a2e14b19 docs(scenes): add V1-23 architecture decision and roadmap updates
9e85a187 feat(scenes): add payload pickers for linked assets,workdir:/Users/karim/Project/pokemonProject
e3325807 feat(scenes): add linked asset contracts and scene V0 node deletion
d170d0da docs(scenes): add linked-asset contracts audit and update roadmaps
48f3d520 docs(scenes): add checkpoint narrative studio direction and update roadmaps
c9a3d6e2 docs(scenes): add roadmap checkpoint correction and roadmap updates
23fc0436 chore(selbrume): update project scene condition metadata
4d25c19b Fix scene graph zoom scaling
3f9e2671 refactor(editor): route narrative modes to empty inspector
```

## 4. Changements préexistants vs changements du lot

Changements préexistants :

```text
Sortie : <vide>
```

Changements introduits par `NS-SCENES-V1-24` :

```text
packages/map_core/lib/map_core.dart
packages/map_core/lib/src/runtime/scene_runtime_plan.dart
packages/map_core/lib/src/runtime/scene_runtime_plan_builder.dart
packages/map_core/test/scene_runtime_plan_test.dart
reports/narrativeStudio/scenes/road_map_scenes.md
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/ns_scenes_v1_24_scene_runtime_plan_v0.md
```

## 5. Fichiers créés/modifiés

Fichiers créés :

```text
packages/map_core/lib/src/runtime/scene_runtime_plan.dart
packages/map_core/lib/src/runtime/scene_runtime_plan_builder.dart
packages/map_core/test/scene_runtime_plan_test.dart
reports/narrativeStudio/scenes/ns_scenes_v1_24_scene_runtime_plan_v0.md
```

Fichiers modifiés :

```text
packages/map_core/lib/map_core.dart
reports/narrativeStudio/scenes/road_map_scenes.md
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
```

## 6. Fichiers lus

Instructions et prompt :

```text
AGENTS.md
agent_rules.md
skills/README.md
/Users/karim/.codex/attachments/14752553-1000-44d3-87aa-56c8e0298ed2/pasted-text.txt
/Users/karim/.codex/plugins/cache/openai-curated/superpowers/fef63ecf/skills/test-driven-development/SKILL.md
/Users/karim/.codex/plugins/cache/openai-curated/superpowers/fef63ecf/skills/verification-before-completion/SKILL.md
```

Rapports et roadmaps :

```text
reports/narrativeStudio/scenes/road_map_scenes.md
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/ns_scenes_v1_23_bis_event_to_scene_link_v0.md
reports/narrativeStudio/scenes/ns_scenes_v1_23_event_to_scene_trigger_prep.md
reports/narrativeStudio/scenes/ns_scenes_v1_22_payload_pickers_v0.md
reports/narrativeStudio/scenes/ns_scenes_v1_21_linked_asset_contracts_v0.md
```

Core :

```text
packages/map_core/lib/src/models/scene_asset.dart
packages/map_core/lib/src/diagnostics/scene_diagnostics.dart
packages/map_core/lib/src/diagnostics/event_scene_link_diagnostics.dart
packages/map_core/lib/src/read_models/linked_asset_public_contracts.dart
packages/map_core/lib/src/authoring/scene_authoring_operations.dart
packages/map_core/lib/map_core.dart
packages/map_core/lib/src/models/map_event_definition.dart
packages/map_core/lib/src/operations/map_events.dart
packages/map_core/test/scene_authoring_operations_test.dart
packages/map_core/test/scene_diagnostics_test.dart
```

Runtime lu en audit seulement :

```text
packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_models.dart
packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart
packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
```

Chemins obligatoires absents :

```text
Sortie : <vide>
```

## 7. Design retenu

Le plan runtime V0 est un read model pur de compilation structurelle. Il vit dans `map_core/lib/src/runtime/` et ne dépend que de `SceneAsset` et des diagnostics Scene existants.

API publique :

```dart
SceneRuntimePlanBuildResult buildSceneRuntimePlan(SceneAsset scene)
```

Décisions :

- `SceneAsset` reste le modèle canonique authoring ;
- le builder ne lit pas `ProjectManifest` ;
- le builder ne lit pas le disque ;
- le builder ne parse pas Yarn ;
- le builder n’importe pas `map_battle` ;
- le builder n’importe pas Flutter/Flame/runtime ;
- le builder ignore `SceneGraphLayout` ;
- le builder ne crée aucun edge implicite ;
- le builder ne corrige pas la scène ;
- le builder retourne des diagnostics au lieu de lancer une exécution.

## 8. Modèle SceneRuntimePlan

Modèles ajoutés :

```text
SceneRuntimePlan
SceneRuntimePlanNode
SceneRuntimePlanIntent
SceneRuntimePlanEdge
SceneRuntimePlanDiagnostic
SceneRuntimePlanBuildResult
SceneRuntimePlanIntentKind
SceneRuntimePlanDiagnosticSeverity
SceneRuntimePlanDiagnosticCode
```

Le plan expose :

```text
sceneId
startNodeId
nodes
edges
declaredOutcomes
```

`SceneRuntimePlanBuildResult.canBuild` vaut `true` uniquement si `plan != null` et si aucun diagnostic runtime-plan de sévérité `error` n’est présent.

## 9. Intents V0 supportés

Mapping livré :

| SceneNodeKind | Intent V0 | Décision |
|---|---|---|
| `start` | `start` | entrée logique du plan |
| `end` | `end` | arrêt logique, expose `sceneOutcomeId` si présent |
| `condition` | `evaluateCondition` | expose `SceneConditionSource`, n’évalue rien |
| `merge` | `merge` | no-op logique |
| `yarnDialogue` | `showDialogue` | expose `dialogueId`, `yarnNodeName`, `expectedOutcomes` du payload uniquement |
| `battle` | `startBattle` | expose `battleKind`, `trainerId`, `battleTemplateId`, `npcEntityId`, outcomes du payload uniquement |
| `cinematic` | `playCinematic` | expose `cinematicId`, diagnostic warning bridgeOnly |

## 10. Nodes unsupported / deferred

`action` :

```text
diagnostic : unsupportedAction
severity : error
plan : null
raison : pas encore de contrat runtime public Action/Consequence V0
```

`branchByOutcome` :

```text
diagnostic : unsupportedBranchByOutcome
severity : error
plan : null
raison : mappings outcome -> edge encore futurs
```

## 11. Edges et ordre déterministe

Les edges du plan copient les champs logiques existants :

```text
id
fromNodeId
fromPortId
toNodeId
kind
label
```

Ordre retenu : ordre persistant de `SceneGraph.nodes` et `SceneGraph.edges`. Aucun ordre issu du layout n’est utilisé.

## 12. Diagnostics et build result

Codes runtime-plan V0 :

```text
planBuildBlockedBySceneDiagnostics
unsupportedAction
unsupportedBranchByOutcome
cinematicBridgeOnly
```

Décisions severity :

- erreur `diagnoseScene(scene)` -> `planBuildBlockedBySceneDiagnostics`, `error`, `plan == null` ;
- `ActionNode` -> `unsupportedAction`, `error`, `plan == null` ;
- `BranchByOutcomeNode` -> `unsupportedBranchByOutcome`, `error`, `plan == null` ;
- `CinematicNode` -> `cinematicBridgeOnly`, `warning`, plan possible.

## 13. Réutilisation de diagnoseScene

Le builder appelle `diagnoseScene(scene)` au début.

Toute erreur Scene est réexposée en diagnostic runtime-plan avec :

```text
sourceSceneDiagnosticCode
nodeId
edgeId
sceneId
```

Le builder ne duplique pas les règles de `scene_diagnostics.dart`.

Note : les cas `startNodeId` manquant ou inconnu sont actuellement empêchés par les invariants publics de `SceneGraph`. Aucun changement de `SceneAsset` n’a été fait pour fabriquer des scènes invalides hors modèle.

## 14. Pourquoi le layout est ignoré

`SceneGraphLayout` est un état editor-only. Le runtime futur doit lire uniquement le graph logique : nodes, payloads et edges. Les tests comparent deux scènes au même graph mais avec layouts différents et obtiennent le même plan.

## 15. Pourquoi aucun runtime n’a été codé

Ce lot prépare uniquement la compilation. L’exécution réelle demande encore :

- diagnostic expansion ;
- validation cross-project ;
- executor runtime ;
- callbacks dialogue/battle/cinematic/action ;
- stratégie d’outcomes runtime ;
- intégration Event -> Scene runtime.

Ces points appartiennent aux lots futurs.

## 16. Pourquoi aucun ScenarioAsset n’a été promu

Le plan part de `SceneAsset` et ne convertit pas vers `ScenarioAsset`. Les fichiers `ScenarioRuntimeExecutor` et `PlayableMapGame` ont été lus seulement pour audit. Aucun fichier `map_runtime` n’est modifié.

## 17. Pourquoi aucune donnée Selbrume n’a été créée

Les tests utilisent uniquement des IDs neutres :

```text
scene_test
node_start
node_dialogue
node_battle
node_end
dialogue_test
trainer_test
battle_test
cinematic_test
```

Aucune donnée Selbrume, Maël, Lysa, Port des Brisants ou rival n’est ajoutée.

## 18. Tests exécutés avec sorties exactes

### RED phase TDD

Commande :

```bash
cd packages/map_core && dart test test/scene_runtime_plan_test.dart
```

Sortie utile :

```text
Failed to load "test/scene_runtime_plan_test.dart":
test/scene_runtime_plan_test.dart:9:22: Error: Method not found: 'buildSceneRuntimePlan'.
...
test/scene_runtime_plan_test.dart:17:44: Error: Undefined name 'SceneRuntimePlanIntentKind'.
...
Some tests failed.
```

### GREEN phase ciblée

Commande :

```bash
cd packages/map_core && dart test test/scene_runtime_plan_test.dart
```

Sortie exacte utile :

```text
00:00 +0: loading test/scene_runtime_plan_test.dart
00:00 +0: Scene runtime plan V0 builds a pure plan for a minimal valid start to end scene
00:00 +1: Scene runtime plan V0 builds a pure plan for a minimal valid start to end scene
00:00 +1: Scene runtime plan V0 ignores SceneGraphLayout when building the plan
00:00 +2: Scene runtime plan V0 ignores SceneGraphLayout when building the plan
00:00 +2: Scene runtime plan V0 preserves deterministic node and edge order from SceneGraph
00:00 +3: Scene runtime plan V0 preserves deterministic node and edge order from SceneGraph
00:00 +3: Scene runtime plan V0 scene diagnostics errors block plan building cleanly
00:00 +4: Scene runtime plan V0 scene diagnostics errors block plan building cleanly
00:00 +4: Scene runtime plan V0 condition nodes become evaluateCondition intents
00:00 +5: Scene runtime plan V0 condition nodes become evaluateCondition intents
00:00 +5: Scene runtime plan V0 merge nodes become merge intents
00:00 +6: Scene runtime plan V0 merge nodes become merge intents
00:00 +6: Scene runtime plan V0 yarn dialogue payload becomes showDialogue intent without outcomes invented
00:00 +7: Scene runtime plan V0 yarn dialogue payload becomes showDialogue intent without outcomes invented
00:00 +7: Scene runtime plan V0 battle payload becomes startBattle intent without importing battle runtime
00:00 +8: Scene runtime plan V0 battle payload becomes startBattle intent without importing battle runtime
00:00 +8: Scene runtime plan V0 cinematic payload becomes playCinematic intent with bridge warning
00:00 +9: Scene runtime plan V0 cinematic payload becomes playCinematic intent with bridge warning
00:00 +9: Scene runtime plan V0 action nodes produce unsupported diagnostics and no plan
00:00 +10: Scene runtime plan V0 action nodes produce unsupported diagnostics and no plan
00:00 +10: Scene runtime plan V0 branchByOutcome nodes produce unsupported diagnostics and no plan
00:00 +11: Scene runtime plan V0 branchByOutcome nodes produce unsupported diagnostics and no plan
00:00 +11: Scene runtime plan V0 does not mutate the original SceneAsset
00:00 +12: Scene runtime plan V0 does not mutate the original SceneAsset
00:00 +12: All tests passed!
```

## 19. Analyze avec sortie exacte

Commande :

```bash
cd packages/map_core && dart analyze
```

Sortie :

```text
Analyzing map_core...
No issues found!
```

## 20. git diff --check

Commande :

```bash
git diff --check
```

Sortie :

```text
Sortie : <vide>
```

## 21. git diff --stat

Sortie finale :

```text
 packages/map_core/lib/map_core.dart                 |  2 ++
 .../scenes/road_map_scene_builder_authoring.md      | 18 ++++++++++++++++--
 reports/narrativeStudio/scenes/road_map_scenes.md   | 21 ++++++++++++++++++---
 3 files changed, 36 insertions(+), 5 deletions(-)
```

Note : `git diff --stat` ne liste pas les fichiers non trackés tant qu’ils ne sont pas stagés. Le `git status final` les liste explicitement.

## 22. git diff --name-only

Sortie finale :

```text
packages/map_core/lib/map_core.dart
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md
```

## 23. git status final exact

Sortie finale :

```text
 M packages/map_core/lib/map_core.dart
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? packages/map_core/lib/src/runtime/scene_runtime_plan.dart
?? packages/map_core/lib/src/runtime/scene_runtime_plan_builder.dart
?? packages/map_core/test/scene_runtime_plan_test.dart
?? reports/narrativeStudio/scenes/ns_scenes_v1_24_scene_runtime_plan_v0.md
```

## 24. Evidence Pack

### Contenu complet : packages/map_core/lib/src/runtime/scene_runtime_plan.dart

Le fichier contient :

```text
SceneRuntimePlanIntentKind
SceneRuntimePlanDiagnosticSeverity
SceneRuntimePlanDiagnosticCode
SceneRuntimePlan
SceneRuntimePlanNode
SceneRuntimePlanIntent
SceneRuntimePlanEdge
SceneRuntimePlanDiagnostic
SceneRuntimePlanBuildResult
```

Sections complètes ajoutées :

```dart
enum SceneRuntimePlanIntentKind {
  start,
  end,
  evaluateCondition,
  merge,
  showDialogue,
  startBattle,
  playCinematic,
}

enum SceneRuntimePlanDiagnosticCode {
  planBuildBlockedBySceneDiagnostics,
  unsupportedAction,
  unsupportedBranchByOutcome,
  cinematicBridgeOnly,
}
```

### Contenu complet : packages/map_core/lib/src/runtime/scene_runtime_plan_builder.dart

```dart
SceneRuntimePlanBuildResult buildSceneRuntimePlan(SceneAsset scene) {
  final diagnostics = <SceneRuntimePlanDiagnostic>[];
  final sceneDiagnostics = diagnoseScene(scene);

  for (final diagnostic in sceneDiagnostics.diagnostics) {
    if (diagnostic.severity != SceneDiagnosticSeverity.error) {
      continue;
    }
    diagnostics.add(
      SceneRuntimePlanDiagnostic(
        code: SceneRuntimePlanDiagnosticCode.planBuildBlockedBySceneDiagnostics,
        severity: SceneRuntimePlanDiagnosticSeverity.error,
        message: 'La scène ne peut pas être compilée: ${diagnostic.message}',
        sceneId: scene.id,
        nodeId: diagnostic.nodeId,
        edgeId: diagnostic.edgeId,
        sourceSceneDiagnosticCode: diagnostic.code,
      ),
    );
  }

  for (final node in scene.graph.nodes) {
    switch (node.kind) {
      case SceneNodeKind.action:
        diagnostics.add(
          SceneRuntimePlanDiagnostic(
            code: SceneRuntimePlanDiagnosticCode.unsupportedAction,
            severity: SceneRuntimePlanDiagnosticSeverity.error,
            message: 'ActionNode n’a pas encore de contrat runtime public V0.',
            sceneId: scene.id,
            nodeId: node.id,
          ),
        );
      case SceneNodeKind.branchByOutcome:
        diagnostics.add(
          SceneRuntimePlanDiagnostic(
            code: SceneRuntimePlanDiagnosticCode.unsupportedBranchByOutcome,
            severity: SceneRuntimePlanDiagnosticSeverity.error,
            message: 'BranchByOutcome attend un mapping outcome -> edge futur.',
            sceneId: scene.id,
            nodeId: node.id,
          ),
        );
      case SceneNodeKind.cinematic:
        diagnostics.add(
          SceneRuntimePlanDiagnostic(
            code: SceneRuntimePlanDiagnosticCode.cinematicBridgeOnly,
            severity: SceneRuntimePlanDiagnosticSeverity.warning,
            message:
                'CinematicNode est compilé comme intent déclaratif bridgeOnly.',
            sceneId: scene.id,
            nodeId: node.id,
          ),
        );
      case SceneNodeKind.start:
      case SceneNodeKind.end:
      case SceneNodeKind.yarnDialogue:
      case SceneNodeKind.condition:
      case SceneNodeKind.battle:
      case SceneNodeKind.merge:
        break;
    }
  }

  final hasBlockingDiagnostic = diagnostics.any(
    (diagnostic) =>
        diagnostic.severity == SceneRuntimePlanDiagnosticSeverity.error,
  );
  if (hasBlockingDiagnostic) {
    return SceneRuntimePlanBuildResult(
      plan: null,
      diagnostics: diagnostics,
    );
  }

  return SceneRuntimePlanBuildResult(
    plan: SceneRuntimePlan(
      sceneId: scene.id,
      startNodeId: scene.graph.startNodeId,
      nodes: [
        for (final node in scene.graph.nodes)
          SceneRuntimePlanNode(
            id: node.id,
            kind: node.kind,
            title: node.title,
            description: node.description,
            intent: _runtimeIntentForNode(node),
          ),
      ],
      edges: [
        for (final edge in scene.graph.edges)
          SceneRuntimePlanEdge(
            id: edge.id,
            fromNodeId: edge.fromNodeId,
            fromPortId: edge.fromPortId,
            toNodeId: edge.toNodeId,
            kind: edge.kind,
            label: edge.label,
          ),
      ],
      declaredOutcomes: scene.declaredOutcomes,
    ),
    diagnostics: diagnostics,
  );
}
```

### Tests créés

Le fichier `packages/map_core/test/scene_runtime_plan_test.dart` couvre :

```text
build plan for minimal valid start -> end scene
layout ignored
deterministic nodes
deterministic edges
scene diagnostics errors block plan
condition -> evaluateCondition
merge -> merge
end -> end
yarnDialogue -> showDialogue without invented outcomes
battle -> startBattle without map_battle import
cinematic -> playCinematic with bridge warning
action -> unsupported error
branchByOutcome -> unsupported error
SceneAsset not mutated
```

### Diff complet : packages/map_core/lib/map_core.dart

```diff
 export 'src/read_models/narrative_reference_picker_read_models.dart';
 export 'src/read_models/linked_asset_public_contracts.dart';
+export 'src/runtime/scene_runtime_plan.dart';
+export 'src/runtime/scene_runtime_plan_builder.dart';
 export 'src/projection/world_rule_projection.dart';
```

### Diff complet : roadmaps

Sections modifiées :

```text
road_map_scenes.md
- V1-24 marqué DONE.
- Prochain lot recommandé changé vers V1-25.
- Decisions V1-24 ajoutées.

road_map_scene_builder_authoring.md
- Prochain lot exact recommandé changé vers V1-25.
- Ligne V1-24 enrichie avec statut DONE.
- Mise à jour V1-24 ajoutée.
```

## 25. Auto-review critique

- Est-ce que j’ai modifié map_runtime ? Non.
- Est-ce que j’ai modifié map_editor ? Non, hors aucun fichier editor. Roadmaps seulement.
- Est-ce que j’ai modifié map_battle ? Non.
- Est-ce que j’ai modifié map_gameplay ? Non.
- Est-ce que j’ai créé un SceneRuntimeExecutor ? Non.
- Est-ce que j’ai exécuté une Scene ? Non.
- Est-ce que j’ai branché Event -> Scene runtime ? Non.
- Est-ce que j’ai branché StorylineStep.sceneLinkIds ? Non.
- Est-ce que j’ai promu ScenarioAsset comme modèle final ? Non.
- Est-ce que j’ai inventé des outcomes Yarn ? Non. Les outcomes dialogue restent ceux du payload, donc vides si le payload est vide.
- Est-ce que j’ai inventé des fake refs ? Non. Les tests utilisent uniquement des refs neutres explicitement posées dans les payloads.
- Est-ce que j’ai créé des données Selbrume ? Non.
- Est-ce que le plan ignore bien SceneGraphLayout ? Oui, prouvé par test.
- Est-ce que le builder est pur et déterministe ? Oui : entrée `SceneAsset`, pas d’I/O, ordre issu du graph persistant.
- Est-ce que SceneAsset reste non muté ? Oui, prouvé par test JSON avant/après.
- Est-ce que le prochain lot reste bien V1-25 et n’a pas été démarré ? Oui.

## 26. Limites et prochain lot recommandé

Limites connues :

- validation cross-project volontairement absente : pas de résolution `dialogueId`, trainer, cinematic bridge, fact ou world rule dans `ProjectManifest` ;
- `ActionNode` reste unsupported ;
- `BranchByOutcomeNode` reste unsupported ;
- `CinematicNode` est seulement un intent déclaratif avec warning bridgeOnly ;
- ports requis, unreachable, cycles, refs inconnues et outcomes non mappés restent pour le prochain lot ;
- les scènes malformées avec start manquant/inconnu ne peuvent pas être construites via l’API publique actuelle de `SceneGraph`, donc le builder les couvre seulement indirectement via `diagnoseScene` si un tel objet existe un jour.

Prochain lot recommandé :

```text
NS-SCENES-V1-25 — Diagnostics / Validator Expansion
```
