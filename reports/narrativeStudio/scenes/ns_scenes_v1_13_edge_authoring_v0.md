# NS-SCENES-V1-13 — Edge Authoring V0

## Résumé exécutif

V1-13 ajoute le premier authoring réel d'edges Scene V1.

Réalisé :

- opération pure `addSceneEdgeDraft` côté `map_core` ;
- source de vérité pure des ports authorables V0 ;
- validation stricte des ports source ;
- dérivation de `SceneEdgeKind` depuis `fromPortId` ;
- mode connexion local côté workspace Scènes ;
- mise à jour en mémoire de `ProjectManifest.scenes` ;
- graph mis à jour après création d'edge ;
- inspecteur read-only mis à jour via les edges entrants/sortants existants ;
- screenshot Visual Gate V1-13 ;
- roadmaps mises à jour.

Le lot ne branche aucun runtime, aucun drag and drop, aucun payload picker, aucune suppression d'edge, aucune Storyline link et aucune donnée produit factice.

## Design / architecture gate

- L'opération pure d'ajout d'edge reste dans `packages/map_core/lib/src/authoring/scene_authoring_operations.dart`, à côté de `createSceneDraftInProject` et `addSceneNodeDraft`.
- Les ports authorables V0 sont exposés par `authorableSceneOutputPortsForNode` / `authorableSceneOutputPortsForKind`.
- Ports V0 :
  - `start.completed` -> `SceneEdgeKind.defaultFlow` ;
  - `condition.true` -> `SceneEdgeKind.conditionTrue` ;
  - `condition.false` -> `SceneEdgeKind.conditionFalse` ;
  - `merge.completed` -> `SceneEdgeKind.defaultFlow`.
- `fromPortId` est toujours explicite.
- `SceneEdge.kind` est dérivé du port, jamais choisi librement par l'UI.
- `end`, `yarnDialogue`, `action`, `battle`, `cinematic`, `branchByOutcome` n'ont aucune sortie authorable V0.
- Les duplicates exacts et le deuxième edge sortant depuis le même `fromNodeId/fromPortId` sont refusés.
- Les self-loops sont refusés en V0.
- L'ID d'edge est stable : `edge_<fromNodeId>_<fromPortId>_<toNodeId>`, avec suffixe numérique en collision.
- Côté editor, le flow est : sélectionner node source -> cliquer un bouton de port -> cliquer un node cible dans le graph -> créer l'edge.
- Le mode connexion reste local et annulable.
- Après création, la sélection reste sur le node source pour permettre de connecter `condition.true` puis `condition.false`.
- Aucun drag and drop, aucune ligne preview, aucun port connectable complexe : V1-13 reste volontairement borné.
- V1-14 pourra ajouter layout authoring sans changer le graph logique ni le runtime.

## Scope réalisé

Core :

- `SceneEdgeDraftCreationResult`.
- `SceneAuthorableOutputPort`.
- `authorableSceneOutputPortsForNode`.
- `authorableSceneOutputPortsForKind`.
- `addSceneEdgeDraft`.
- tests unitaires ports, edge kind dérivé, IDs, collisions, non-mutation, refus invalides.

Editor :

- `SceneEdgeDraftCreator`.
- callback `onAddEdgeDraft` dans `NarrativeWorkspaceCanvas`.
- mode connexion local dans `ScenesWorkspace`.
- toolbar `Connexions` avec boutons de ports.
- état `Connexion en cours`.
- annulation locale.
- clic target via graph existant.
- tests widget edge authoring.

Rapports :

- `road_map_scenes.md` mis à jour.
- `road_map_scene_builder_authoring.md` mis à jour.
- rapport V1-13 créé.
- screenshot V1-13 créé.

## Fichiers créés/modifiés

Créés :

```text
reports/narrativeStudio/scenes/ns_scenes_v1_13_edge_authoring_v0.md
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_13_edge_authoring_v0.png
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

- Pas de nouveau fichier core : `scene_authoring_operations.dart` reste le point d'entrée des opérations authoring Scene.
- Pas de modification de `SceneAsset` ou `ProjectManifest`.
- Pas de modification de `map_runtime`, `map_gameplay`, `map_battle` ou `examples`.
- Les ports V0 sont publics parce que l'UI doit afficher exactement la même source de vérité que l'opération core valide.
- Le callback editor attrape `ArgumentError` et retourne `null`, afin qu'un clic invalide ne crash pas l'UI.
- La création d'edge ne crée pas de `SceneEdgeLayout`; le layout reste séparé et V1-14 traitera sa persistence.
- Les diagnostics `missingRequiredOutput` restent hors scope pour ne pas transformer V1-13 en Diagnostics Expansion.

## Opération core ajoutée

Signature :

```dart
SceneEdgeDraftCreationResult addSceneEdgeDraft(
  SceneAsset scene, {
  required String fromNodeId,
  required String fromPortId,
  required String toNodeId,
  String? label,
})
```

Garanties :

- ne mute pas la scène originale ;
- conserve nodes existants ;
- conserve layout ;
- conserve declared outcomes ;
- conserve tags / metadata / description / storylineId / chapterId ;
- vérifie source et cible ;
- vérifie le port source ;
- dérive `SceneEdgeKind` ;
- refuse les invalides V0 ;
- génère un ID stable.

## Ports supportés

| Source kind | Port | Edge kind |
|---|---|---|
| `start` | `completed` | `defaultFlow` |
| `condition` | `true` | `conditionTrue` |
| `condition` | `false` | `conditionFalse` |
| `merge` | `completed` | `defaultFlow` |

Sans sortie authorable V0 :

```text
end
yarnDialogue
action
battle
cinematic
branchByOutcome
```

## Règles de compatibilité

Autorisé :

```text
start.completed -> condition / merge / end
condition.true -> condition / merge / end
condition.false -> condition / merge / end
merge.completed -> condition / merge / end
```

Refusé :

```text
source inconnue
cible inconnue
port inconnu
source end
source yarnDialogue/action/battle/cinematic/branchByOutcome
self-loop
deuxième edge sortant depuis le même fromNodeId/fromPortId
```

## Intégration editor

`NarrativeWorkspaceCanvas` remplace uniquement la scène cible dans `ProjectManifest.scenes` :

```text
project.scenes[sceneIndex]
-> addSceneEdgeDraft
-> project.copyWith(scenes: scenes)
-> EditorNotifier.applyInMemoryProjectManifest
```

`ScenesWorkspace` ajoute :

- `_PendingSceneConnection` local ;
- `_startConnection` ;
- `_cancelConnection` ;
- `_handleGraphNodeTap` ;
- `_addEdgeDraft`.

Le graph reste le graph existant : un tap sur node cible termine la connexion quand un port est en attente. Aucun drag and drop n'est ajouté.

## Mode connexion UI

État normal :

```text
Connexions
Connecter completed / true / false selon le node sélectionné
```

État pending :

```text
Connexion en cours depuis <source> / <port>. Cliquez un nœud cible.
Annuler
```

Si le port est déjà utilisé :

```text
<port> · connecté
```

Si le node n'a pas de sortie V0 :

```text
Aucune sortie connectable V0.
```

## Écarts au prompt éventuels

- Aucun bouton de suppression d'edge n'a été ajouté. Le prompt global V1-13 interdit la suppression sauf nécessité validée ; elle n'était pas nécessaire au flow.
- Aucun highlight spécifique des cibles possibles n'a été ajouté. Le feedback V0 est le bandeau de connexion pending ; les validations core refusent les cas invalides.
- L'ancien test golden V1-12 a été converti en test fonctionnel, car la toolbar V1-13 change légitimement le rendu général du workspace.
- Deux commandes Flutter lancées en parallèle pendant la vérification ont produit des erreurs de startup lock/native assets. Elles ont été relancées ensuite une par une avec succès.

## Tests exécutés

### RED core attendu

Commande :

```bash
cd packages/map_core && dart test test/scene_authoring_operations_test.dart
```

Résultat exact utile :

```text
Failed to load "test/scene_authoring_operations_test.dart":
test/scene_authoring_operations_test.dart:176:9: Error: Method not found: 'authorableSceneOutputPortsForNode'.
test/scene_authoring_operations_test.dart:207:22: Error: Method not found: 'addSceneEdgeDraft'.
00:00 +0 -1: Some tests failed.
```

### RED editor attendu

Commande :

```bash
cd packages/map_editor && flutter test --reporter=compact test/scenes_workspace_shell_test.dart
```

Résultat exact utile :

```text
The finder "Found 0 widgets with key [<'scenes-connect-port-completed'>]: []" (used in a call to "tap()") could not find any matching widgets.
The finder "Found 0 widgets with key [<'scenes-connect-port-true'>]: []" (used in a call to "tap()") could not find any matching widgets.
Expected: exactly one matching candidate
Actual: _KeyWidgetFinder:<Found 0 widgets with key [<'scenes-edge-no-outputs'>]: []>
00:07 +22 -6: Some tests failed.
```

### Core authoring

Commande :

```bash
cd packages/map_core && dart test test/scene_authoring_operations_test.dart
```

Résultat exact :

```text
00:00 +14: All tests passed!
```

### Core analyze

Commande :

```bash
cd packages/map_core && dart analyze
```

Résultat exact :

```text
Analyzing map_core...
No issues found!
```

### Visual Gate generation

Commande :

```bash
cd packages/map_editor && flutter test --update-goldens --reporter=compact test/scenes_workspace_shell_test.dart
```

Résultat exact :

```text
00:04 +28: All tests passed!
```

### Editor Scenes workspace

Commande :

```bash
cd packages/map_editor && flutter test --reporter=compact test/scenes_workspace_shell_test.dart
```

Résultat exact :

```text
00:05 +28: All tests passed!
```

### Editor overview navigation

Commande :

```bash
cd packages/map_editor && flutter test --reporter=compact test/ui/canvas/narrative_overview_shell_navigation_test.dart
```

Résultat exact :

```text
00:05 +19: All tests passed!
```

### Editor header

Commande :

```bash
cd packages/map_editor && flutter test --reporter=compact test/ui/canvas/narrative_studio_header_test.dart
```

Résultat exact :

```text
00:02 +3: All tests passed!
```

### Editor projection

Commande :

```bash
cd packages/map_editor && flutter test --reporter=compact test/narrative_workspace_projection_test.dart
```

Résultat exact :

```text
00:02 +3: All tests passed!
```

### Editor analyze ciblé

Commande :

```bash
cd packages/map_editor && flutter analyze --no-fatal-infos lib/src/ui/canvas/narrative_workspace_canvas.dart lib/src/ui/canvas/scenes_workspace.dart test/scenes_workspace_shell_test.dart
```

Résultat exact :

```text
Analyzing 3 items...
No issues found! (ran in 2.0s)
```

### Incident de vérification Flutter relancé

Commande concernée lancée trop tôt en parallèle :

```bash
cd packages/map_editor && flutter test --reporter=compact test/narrative_workspace_projection_test.dart
```

Résultat exact utile de l'incident :

```text
Oops; flutter has exited unexpectedly: "PathNotFoundException: Cannot copy file to '/Users/karim/Project/pokemonProject/packages/map_editor/build/unit_test_assets/NativeAssetsManifest.json', path = '/Users/karim/Project/pokemonProject/packages/map_editor/build/native_assets/macos/native_assets.json' (OS Error: No such file or directory, errno = 2)".
```

Action : commande relancée séquentiellement ensuite, résultat `00:02 +3: All tests passed!`.

## Analyze exact

Core :

```text
Analyzing map_core...
No issues found!
```

Editor ciblé :

```text
Analyzing 3 items...
No issues found! (ran in 2.0s)
```

## Visual Gate

Chemin :

```text
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_13_edge_authoring_v0.png
```

Commande utilisée :

```bash
cd packages/map_editor && flutter test --update-goldens --reporter=compact test/scenes_workspace_shell_test.dart
```

Ce qui est visible :

- workspace Scènes ;
- arborescence gauche ;
- scène locale de test `Edge Authoring Test Scene` ;
- palette node V1-12 ;
- toolbar de connexion V1-13 ;
- graph avec edge explicite `node_start.completed -> node_condition` ;
- node source `node_start` sélectionné ;
- inspecteur read-only avec edge sortant ;
- aucune UI runtime ;
- aucun bouton Yarn/Battle/Cinematic actif.

Preuve anti-fake :

- la scène du screenshot est construite dans `packages/map_editor/test/scenes_workspace_shell_test.dart` par `_projectWithEdgeAuthoringScene`.
- aucune fixture produit n'a été ajoutée.
- le code produit ne contient pas `Selbrume Demo` ou `Annonce au port`; le test vérifie seulement leur absence.

## Git status initial

Commande :

```bash
git status --short --untracked-files=all
```

Sortie :

```text
Sortie : <vide>
```

## Git diff --stat initial

Commande :

```bash
git diff --stat
```

Sortie :

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

### git log --oneline -n 10

```text
18046f6a feat(scenes): implement node authoring v0 and update tests
79df007c docs(scenes): add scene graph draft node strategy report
4fbfead4 docs(scenes): add scene builder runtime and authoring roadmap alignment
68df7710 docs(scenes): add runtime execution preparation report
ba6ec6e2 feat(scenes): add scene validation diagnostics and update tests
f9095001 feat(scenes): add minimal scene draft authoring operations and tests
c1bf1c76 feat(scenes): add read-only node inspector and update workspace tests
e3b346c7 feat(scenes): harden graph read-only fallback layout and update tests
d97be401 chore: auto-commit changes
7fcd3c87 chore: auto-commit changes
```

### Fichiers lus

```text
AGENTS.md
agent_rules.md
skills/README.md
reports/narrativeStudio/scenes/road_map_scenes.md
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/ns_scenes_v1_09_scene_validation_diagnostics.md
reports/narrativeStudio/scenes/ns_scenes_v1_10_runtime_execution_prep.md
reports/narrativeStudio/scenes/ns_scenes_v1_10_bis_scene_builder_runtime_roadmap_alignment.md
reports/narrativeStudio/scenes/ns_scenes_v1_11_scene_graph_draft_node_strategy.md
reports/narrativeStudio/scenes/ns_scenes_v1_12_node_authoring_v0.md
packages/map_core/lib/src/models/scene_asset.dart
packages/map_core/lib/src/diagnostics/scene_diagnostics.dart
packages/map_core/lib/src/authoring/scene_authoring_operations.dart
packages/map_core/lib/map_core.dart
packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
packages/map_editor/lib/src/ui/canvas/scenes_workspace.dart
packages/map_editor/lib/src/ui/canvas/scenes/scene_graph_read_only_view.dart
packages/map_editor/lib/src/ui/canvas/scenes/scene_node_read_only_inspector.dart
packages/map_editor/lib/src/features/narrative/application/narrative_workspace_projection.dart
packages/map_editor/test/scenes_workspace_shell_test.dart
```

### Sections modifiées complètes — core operation

```dart
final class SceneEdgeDraftCreationResult {
  const SceneEdgeDraftCreationResult({
    required this.updatedScene,
    required this.createdEdge,
  });

  final SceneAsset updatedScene;
  final SceneEdge createdEdge;
}

final class SceneAuthorableOutputPort {
  const SceneAuthorableOutputPort({
    required this.id,
    required this.label,
    required this.edgeKind,
  });

  final String id;
  final String label;
  final SceneEdgeKind edgeKind;
}

List<SceneAuthorableOutputPort> authorableSceneOutputPortsForNode(
  SceneNode node,
) {
  return authorableSceneOutputPortsForKind(node.kind);
}

List<SceneAuthorableOutputPort> authorableSceneOutputPortsForKind(
  SceneNodeKind kind,
) {
  return switch (kind) {
    SceneNodeKind.start => const [
        SceneAuthorableOutputPort(
          id: 'completed',
          label: 'completed',
          edgeKind: SceneEdgeKind.defaultFlow,
        ),
      ],
    SceneNodeKind.condition => const [
        SceneAuthorableOutputPort(
          id: 'true',
          label: 'true',
          edgeKind: SceneEdgeKind.conditionTrue,
        ),
        SceneAuthorableOutputPort(
          id: 'false',
          label: 'false',
          edgeKind: SceneEdgeKind.conditionFalse,
        ),
      ],
    SceneNodeKind.merge => const [
        SceneAuthorableOutputPort(
          id: 'completed',
          label: 'completed',
          edgeKind: SceneEdgeKind.defaultFlow,
        ),
      ],
    SceneNodeKind.end ||
    SceneNodeKind.yarnDialogue ||
    SceneNodeKind.action ||
    SceneNodeKind.battle ||
    SceneNodeKind.cinematic ||
    SceneNodeKind.branchByOutcome =>
      const <SceneAuthorableOutputPort>[],
  };
}
```

```dart
SceneEdgeDraftCreationResult addSceneEdgeDraft(
  SceneAsset scene, {
  required String fromNodeId,
  required String fromPortId,
  required String toNodeId,
  String? label,
}) {
  final fromNode = _findNodeOrThrow(scene, fromNodeId, 'fromNodeId');
  _findNodeOrThrow(scene, toNodeId, 'toNodeId');

  if (fromNodeId == toNodeId) {
    throw ArgumentError.value(
      toNodeId,
      'toNodeId',
      'Self-loop edges are not supported by Edge Authoring V0.',
    );
  }

  final port = _authorableOutputPortOrThrow(fromNode, fromPortId);
  for (final edge in scene.graph.edges) {
    if (edge.fromNodeId == fromNodeId && edge.fromPortId == fromPortId) {
      throw ArgumentError.value(
        fromPortId,
        'fromPortId',
        'Edge Authoring V0 allows only one outgoing edge per source port.',
      );
    }
  }

  final createdEdge = SceneEdge(
    id: _uniqueEdgeId(
      _edgeIdBase(
        fromNodeId: fromNodeId,
        fromPortId: fromPortId,
        toNodeId: toNodeId,
      ),
      scene.graph.edges.map((edge) => edge.id),
    ),
    fromNodeId: fromNodeId,
    fromPortId: fromPortId,
    toNodeId: toNodeId,
    kind: port.edgeKind,
    label: _trimOptional(label) ?? port.label,
  );

  final updatedScene = SceneAsset(
    id: scene.id,
    name: scene.name,
    description: scene.description,
    storylineId: scene.storylineId,
    chapterId: scene.chapterId,
    tags: scene.tags,
    graph: SceneGraph(
      startNodeId: scene.graph.startNodeId,
      nodes: scene.graph.nodes,
      edges: [...scene.graph.edges, createdEdge],
    ),
    layout: scene.layout,
    declaredOutcomes: scene.declaredOutcomes,
    metadata: scene.metadata,
  );

  return SceneEdgeDraftCreationResult(
    updatedScene: updatedScene,
    createdEdge: createdEdge,
  );
}
```

### Sections modifiées complètes — editor callback

```dart
onAddEdgeDraft: ({
  required String sceneId,
  required String fromNodeId,
  required String fromPortId,
  required String toNodeId,
}) async {
  final project = editor.project;
  if (project == null) {
    return null;
  }
  final sceneIndex =
      project.scenes.indexWhere((scene) => scene.id == sceneId);
  if (sceneIndex < 0) {
    return null;
  }
  try {
    final result = addSceneEdgeDraft(
      project.scenes[sceneIndex],
      fromNodeId: fromNodeId,
      fromPortId: fromPortId,
      toNodeId: toNodeId,
    );
    final scenes = project.scenes.toList(growable: true);
    scenes[sceneIndex] = result.updatedScene;
    editorNotifier.applyInMemoryProjectManifest(
      project.copyWith(scenes: scenes),
      statusMessage: 'Scene edge draft added',
    );
    return result.createdEdge.id;
  } on ArgumentError {
    return null;
  }
},
```

### Sections modifiées complètes — toolbar editor

```dart
class _SceneEdgeDraftToolbar extends StatelessWidget {
  const _SceneEdgeDraftToolbar({
    required this.scene,
    required this.selectedNodeId,
    required this.pendingConnection,
    required this.onStartConnection,
    required this.onCancelConnection,
  });

  final NarrativeSceneSummary scene;
  final String? selectedNodeId;
  final _PendingSceneConnection? pendingConnection;
  final ValueChanged<SceneAuthorableOutputPort> onStartConnection;
  final VoidCallback onCancelConnection;

  @override
  Widget build(BuildContext context) {
    final pending = pendingConnection;
    if (pending != null) {
      return _PendingConnectionBar(
        pending: pending,
        onCancelConnection: onCancelConnection,
      );
    }

    final node = _selectedNode;
    if (node == null) {
      return const SizedBox(
        key: ValueKey('scenes-edge-no-outputs'),
        height: 34,
      );
    }
    final ports = authorableSceneOutputPortsForNode(node);
    if (ports.isEmpty) {
      return const _NoOutputPortsBar();
    }

    final usedPorts = {
      for (final edge in scene.graph.edges)
        if (edge.fromNodeId == node.id) edge.fromPortId,
    };
    final colors = context.pokeMapColors;
    return SizedBox(
      key: const ValueKey('scenes-edge-authoring-toolbar'),
      height: 34,
      child: Row(
        children: [
          Text(
            'Connexions',
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final port in ports)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: PokeMapButton(
                        key: ValueKey('scenes-connect-port-${port.id}'),
                        onPressed: usedPorts.contains(port.id)
                            ? null
                            : () => onStartConnection(port),
                        variant: usedPorts.contains(port.id)
                            ? PokeMapButtonVariant.ghost
                            : PokeMapButtonVariant.secondary,
                        size: PokeMapButtonSize.small,
                        leading: const Icon(CupertinoIcons.link),
                        child: Text(
                          usedPorts.contains(port.id)
                              ? '${port.label} · connecté'
                              : 'Connecter ${port.label}',
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  SceneNode? get _selectedNode {
    final id = selectedNodeId;
    if (id == null) {
      return null;
    }
    for (final node in scene.graph.nodes) {
      if (node.id == id) {
        return node;
      }
    }
    return null;
  }
}
```

### Diff complet road_map_scenes.md et road_map_scene_builder_authoring.md

````diff
diff --git a/reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md b/reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
index 458890a4..f93ed5da 100644
--- a/reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
+++ b/reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
@@ -9,7 +9,7 @@ Le runtime reste indispensable, mais le prochain blocage produit est plus basiqu
 ## Prochain lot exact recommande
 
 ```text
-NS-SCENES-V1-13 — Edge Authoring V0
+NS-SCENES-V1-14 — Layout Authoring V0
 ```
 
 ## Principes
@@ -27,7 +27,7 @@ NS-SCENES-V1-13 — Edge Authoring V0
 |---|---|---|---|---|---|---|---|---|---|
 | NS-SCENES-V1-11 | Scene Graph Draft Node Strategy | doc-only / planning | Definir nodes ajoutables, defaults, ports, payload drafts, restrictions anti-fake refs. | Pas de UI, pas de runtime, pas de model change. | `reports/narrativeStudio/scenes/ns_scenes_v1_11_scene_graph_draft_node_strategy.md`, roadmap. | Non requis hors `git diff --check`. | Trop de doc, ou inversement palette codee trop tot. | DONE : Condition, Merge et Fin ajoutables V0 ; Yarn/Action/Battle/Cinematic/Branch desactives jusqu'aux refs/payloads honnetes. | V1-10-bis. |
 | NS-SCENES-V1-12 | Node Authoring V0 | core / editor | Ajouter palette minimale et creation de nodes draft `condition`, `merge`, `end` dans `ProjectManifest.scenes` en memoire. | Pas de edge authoring avance, pas de pickers refs, pas de runtime, pas de nodes Yarn/Action/Battle/Cinematic/Branch actifs. | `scene_authoring_operations.dart`, `scenes_workspace.dart`, tests Scenes. | Tests core operations + widget palette/add node + no fake refs. | Nodes inutilisables si diagnostics trop faibles ; UI trop proche d'un builder complet. | DONE : nodes V0 ajoutables, selection auto, inspector read-only/draft, nodes desactives honnetes, aucun edge automatique. | V1-11. |
-| NS-SCENES-V1-13 | Edge Authoring V0 | core / editor | Connecter explicitement ports/nodes, creer/supprimer edges simples, valider compatibilite. | Pas de drag complexe, pas de runtime, pas de auto-layout final. | operations core edges, `scene_graph_read_only_view.dart` evolue en graph draft view, tests. | Tests fromPortId, edge kind, incompatibilites, ProjectManifest non touche hors scenes. | Branches implicites, edges invalides, UX de connexion trop lourde. | Edge cree depuis port explicite, diagnostics edge visibles, aucun edge implicite par proximite. | V1-12. |
+| NS-SCENES-V1-13 | Edge Authoring V0 | core / editor | Connecter explicitement ports/nodes, creer des edges simples, valider compatibilite. | Pas de suppression, pas de drag complexe, pas de runtime, pas de auto-layout final. | operations core edges, `scenes_workspace.dart`, tests. | Tests fromPortId, edge kind derive, incompatibilites, ProjectManifest non touche hors scenes. | Branches implicites, edges invalides, UX de connexion trop lourde. | DONE : edge cree depuis port explicite, no duplicate source port, aucun edge implicite par proximite. | V1-12. |
 | NS-SCENES-V1-14 | Layout Authoring V0 | editor | Deplacer nodes et persister `SceneGraphLayout` sans modifier le graph logique. | Pas de runtime, pas de minimap avancee, pas de auto-route edges final. | graph view, layout operations, widget tests. | Tests drag/persist layout, fallback non persiste, runtime data inchangee. | Coupler layout et runtime ; churn de diffs. | Positions stables sauvegardees, layout incomplet reste warning, aucun effet runtime. | V1-13. |
 | NS-SCENES-V1-15 | Scene Runtime Plan V0 | core | Ajouter `SceneRuntimePlan`, intents, builder pur depuis `SceneAsset` valide. | Pas d'execution runtime, pas de Flutter, pas de `ScenarioAsset` auto. | `packages/map_core/lib/src/runtime/scene_runtime_plan.dart`, tests core. | Draft minimal, yarn/battle/cinematic/action intents, diagnostics error bloque, layout ignore. | Figer trop tot un executor ; dupliquer ScenarioRuntime. | Plan pur testable, ignore layout, refuse scenes invalides. | V1-13 ou V1-14. |
 | NS-SCENES-V1-16 | Payload Pickers V0 | editor / core | Remplacer IDs libres par pickers/drafts honnetes : Yarn, cinematic, battle/action refs. | Pas de full editor payload, pas de runtime. | workspace Scenes, inspector draft controls, projection refs. | Tests pickers refs reelles, refs inconnues diagnostic, boutons honnetes. | Faux contenus Selbrume, refs tapees a la main. | Node payloads configurables avec vraies refs ou drafts clairement invalides. | V1-12, V1-15 utile. |
@@ -62,6 +62,16 @@ Decision : V1-12 a code seulement les nodes autorises par V1-11. La palette V0 a
 
 Prochain lot exact : `NS-SCENES-V1-13 — Edge Authoring V0`.
 
+## Mise a jour V1-13
+
+Statut : `NS-SCENES-V1-13 — Edge Authoring V0` est DONE.
+
+Decision : V1-13 ajoute seulement la creation explicite d'edges V0. Les ports authorables sont `start.completed`, `condition.true`, `condition.false` et `merge.completed`. `SceneEdge.kind` est derive du port. Le mode connexion editor est local : node source selectionne, bouton de port, clic sur node cible. La selection reste sur la source apres creation pour connecter les branches d'une condition.
+
+Limites : aucun drag and drop, aucune suppression d'edge, aucune reconnexion avancee, aucune preview line, aucun runtime, aucun StorylineStep link.
+
+Prochain lot exact : `NS-SCENES-V1-14 — Layout Authoring V0`.
+
 ## Selbrume golden slice
 
 Avant le golden slice, il faut au minimum :
diff --git a/reports/narrativeStudio/scenes/road_map_scenes.md b/reports/narrativeStudio/scenes/road_map_scenes.md
index 173d9556..0a8b4e9a 100644
--- a/reports/narrativeStudio/scenes/road_map_scenes.md
+++ b/reports/narrativeStudio/scenes/road_map_scenes.md
@@ -50,7 +50,7 @@ Ces briques sont utiles, mais elles ne constituent pas encore une Scene V1 propr
 | NS-SCENES-V1-10-bis — Scene Builder / Runtime Roadmap Alignment | DONE | Roadmap reconcilee : priorite au Scene Builder Blueprint-like, runtime plan conserve mais decale apres authoring graph minimal. |
 | NS-SCENES-V1-11 — Scene Graph Draft Node Strategy | DONE | Strategie retenue : activer seulement Condition, Merge et Fin en V0 ; garder Start unique et desactiver Yarn/Action/Battle/Cinematic/Branch tant que les refs/payloads ne sont pas honnetes. |
 | NS-SCENES-V1-12 — Node Authoring V0 | DONE | Operation pure `addSceneNodeDraft` et palette editor V0 : ajout Condition / Merge / Fin en memoire, selection auto, aucun edge automatique ni fake ref. |
-| NS-SCENES-V1-13 — Edge Authoring V0 | TODO | Permettre la connexion explicite des ports/nodes avec validation de compatibilite, sans runtime. |
+| NS-SCENES-V1-13 — Edge Authoring V0 | DONE | Operation pure `addSceneEdgeDraft` et UI de connexion V0 : ports explicites start.completed, condition.true/false, merge.completed, edge kind derive, mise a jour memoire sans runtime. |
 | NS-SCENES-V1-14 — Layout Authoring V0 | TODO | Permettre le deplacement des nodes et la persistence de `SceneGraphLayout`, sans impact runtime. |
 | NS-SCENES-V1-15 — Scene Runtime Plan V0 | TODO | Ajouter un modele pur `SceneRuntimePlan` / intents dans `map_core`, compiler `SceneAsset` valide en plan executable sans layout ni Flutter. |
 | NS-SCENES-V1-16 — Payload Pickers V0 | TODO | Ajouter les pickers Yarn, cinematic, battle/action refs et limiter les IDs libres. |
@@ -62,9 +62,45 @@ Ces briques sont utiles, mais elles ne constituent pas encore une Scene V1 propr
 
 ## Prochain lot recommande
 
-`NS-SCENES-V1-13 — Edge Authoring V0`
+`NS-SCENES-V1-14 — Layout Authoring V0`
 
-Raison : V1-12 permet maintenant de poser des nodes draft honnetes dans une SceneAsset. Le prochain blocage Blueprint-like est la connexion explicite des ports : creer des edges avec `fromPortId`, valider les kinds compatibles, et garder les nodes Yarn/Action/Battle/Cinematic/Branch desactives tant que leurs payloads/pickers ne sont pas prets.
+Raison : V1-13 permet maintenant de creer des edges explicites entre nodes V0 avec validation de ports. Le prochain blocage Blueprint-like est la persistence controlee de `SceneGraphLayout` via un deplacement de nodes, sans rendre le layout utile au runtime.
+
+## Decisions V1-13
+
+- Operation pure ajoutee : `addSceneEdgeDraft(SceneAsset, fromNodeId, fromPortId, toNodeId, label?)`.
+- Source de verite pure ajoutee : `authorableSceneOutputPortsForNode` / `authorableSceneOutputPortsForKind`.
+- Ports supportes V0 :
+  - `start.completed` -> `SceneEdgeKind.defaultFlow` ;
+  - `condition.true` -> `SceneEdgeKind.conditionTrue` ;
+  - `condition.false` -> `SceneEdgeKind.conditionFalse` ;
+  - `merge.completed` -> `SceneEdgeKind.defaultFlow`.
+- `fromPortId` est toujours explicite et `edge.kind` est derive du port, jamais choisi librement par l'utilisateur.
+- `end`, `yarnDialogue`, `action`, `battle`, `cinematic` et `branchByOutcome` ne proposent aucune sortie authorable V0.
+- Les edges depuis source inconnue, vers cible inconnue, depuis port inconnu, depuis `end`, depuis node source desactive, les self-loops et le deuxieme edge sortant depuis un meme `fromNodeId/fromPortId` sont refuses.
+- Les IDs d'edge sont stables : `edge_<fromNodeId>_<fromPortId>_<toNodeId>` avec suffixe numerique en collision.
+- Cote editor, le mode connexion est local : selection node source -> bouton port -> clic node cible -> mise a jour en memoire de `ProjectManifest.scenes`.
+- Apres creation, la selection reste sur le node source pour permettre de connecter `condition.true` puis `condition.false`.
+- Aucun edge automatique, aucun drag and drop, aucune suppression/reconnexion avancee, aucun runtime.
+
+## Limites V1-13
+
+- Pas de layout authoring interactif.
+- Pas de suppression d'edge.
+- Pas de preview line pendant le mode connexion.
+- Pas de ports graphiques connectables complexes.
+- Pas de diagnostics `missingRequiredOutput`; ils restent pour Diagnostics Expansion.
+- Pas de Yarn/Action/Battle/Cinematic/Branch authoring actif.
+
+## Tests V1-13
+
+- `cd packages/map_core && dart test test/scene_authoring_operations_test.dart`
+- `cd packages/map_core && dart analyze`
+- `cd packages/map_editor && flutter test --reporter=compact test/scenes_workspace_shell_test.dart`
+- `cd packages/map_editor && flutter test --reporter=compact test/ui/canvas/narrative_overview_shell_navigation_test.dart`
+- `cd packages/map_editor && flutter test --reporter=compact test/ui/canvas/narrative_studio_header_test.dart`
+- `cd packages/map_editor && flutter test --reporter=compact test/narrative_workspace_projection_test.dart`
+- `cd packages/map_editor && flutter analyze --no-fatal-infos lib/src/ui/canvas/narrative_workspace_canvas.dart lib/src/ui/canvas/scenes_workspace.dart test/scenes_workspace_shell_test.dart`
 
 ## Decisions V1-12
 
````

## Auto-review critique

Ce qui est prouvé :

- ports V0 définis côté core ;
- edge kind dérivé du port ;
- source/target inconnus refusés ;
- port inconnu refusé ;
- edge depuis `end` refusé ;
- source kind désactivé refusé ;
- self-loop refusé ;
- deuxième edge depuis même source port refusé ;
- ID stable et collision suffixée ;
- objet original non muté ;
- `ProjectManifest.scenes` mis à jour en mémoire côté editor ;
- edge visible dans le graph ;
- inspector affiche les edges entrants/sortants mis à jour ;
- mode connexion annulable ;
- Storylines reste sélectionnable ;
- aucune donnée produit interdite dans le code.

Ce qui n'est pas fait :

- pas de suppression d'edge ;
- pas de reconnexion ;
- pas de drag line ;
- pas de layout authoring ;
- pas de diagnostics missing outputs ;
- pas de payload picker ;
- pas de runtime.

Risque résiduel :

- l'UX de connexion est volontairement simple : elle repose sur un état texte et le clic cible, pas encore sur des ports visuels.
- les cycles complexes ne sont pas bloqués par l'authoring V0 ; c'est cohérent avec les lots diagnostics futurs.

## Regard critique sur le prompt

Le prompt est bien borné et force le bon garde-fou : edge explicite par port, pas par proximité visuelle. La seule tension est la mention historique de suppression d'edges dans la roadmap authoring ; le prompt V1-13 actuel interdit cette extension sauf nécessité validée, donc elle a été exclue.

## Git status final

Commande :

```bash
git status --short --untracked-files=all
```

Sortie :

```text
 M packages/map_core/lib/src/authoring/scene_authoring_operations.dart
 M packages/map_core/test/scene_authoring_operations_test.dart
 M packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
 M packages/map_editor/lib/src/ui/canvas/scenes_workspace.dart
 M packages/map_editor/test/scenes_workspace_shell_test.dart
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_13_edge_authoring_v0.md
?? reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_13_edge_authoring_v0.png
```

## Git diff --stat final

Commande :

```bash
git diff --stat
```

Sortie :

```text
 .../src/authoring/scene_authoring_operations.dart  | 198 ++++++++++++++
 .../test/scene_authoring_operations_test.dart      | 304 +++++++++++++++++++++
 .../src/ui/canvas/narrative_workspace_canvas.dart  |  33 +++
 .../lib/src/ui/canvas/scenes_workspace.dart        | 296 +++++++++++++++++++-
 .../test/scenes_workspace_shell_test.dart          | 279 ++++++++++++++++++-
 .../scenes/road_map_scene_builder_authoring.md     |  14 +-
 reports/narrativeStudio/scenes/road_map_scenes.md  |  42 ++-
```

## Git diff --name-only final

Commande :

```bash
git diff --name-only
```

Sortie :

```text
packages/map_core/lib/src/authoring/scene_authoring_operations.dart
packages/map_core/test/scene_authoring_operations_test.dart
packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
packages/map_editor/lib/src/ui/canvas/scenes_workspace.dart
packages/map_editor/test/scenes_workspace_shell_test.dart
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md
```

## Git diff --check final

Commande :

```bash
git diff --check
```

Sortie :

```text
Sortie : <vide>
```
