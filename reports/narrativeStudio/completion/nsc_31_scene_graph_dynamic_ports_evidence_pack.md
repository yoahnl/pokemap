# Evidence Pack — NSC-31 Graph Scene complet et ports dynamiques

## Résumé exécutif

Le lot **NSC-31 — Graph Scene complet et ports dynamiques** est implémenté et proposé **DONE** sur son périmètre. Le Scene Builder permet désormais de dupliquer les nœuds authorables sans recopier leurs edges, expose les outcomes Dialogue et Combat comme ports réels, conserve le port `completed` des graphes Dialogue legacy, bloque les fins sans outcome lorsqu'une Scene en déclare, et propose une preview sèche avec état d'entrée explicite.

Le contrat runtime centralise les sorties déclarées dans `SceneRuntimePlanIntent.declaredOutputPortIds`; le runtime Combat accepte ainsi les outcomes déclarés au lieu d'une liste codée dans l'exécuteur. `BranchByOutcome` reste volontairement hors scope et bloqué jusqu'à NSC-32.

Ce lot ne change aucun statut FG.

## Scope et critères de réussite

Inclus:

- caractérisation et conservation du routage Dialogue legacy `completed`;
- ports dynamiques Dialogue et Combat dérivés des payloads canoniques;
- création/suppression/déplacement/connexion/déconnexion existants revalidés;
- duplication de Dialogue, Combat, Cinematic, Action, Condition, Merge et End;
- rejet d'un port absent, d'une sortie déjà connectée, d'un nœud inaccessible et d'une fin sans outcome requis;
- preview pure, sans callback ni mutation, avec choix explicite des sorties Condition/Dialogue/Combat;
- composant `SceneGraphEditor` extrait du monolithe workspace;
- intégration no-code et design system dans le Narrative Studio;
- mise à jour contrôlée des goldens affectés.

Hors scope:

- sémantique différée de `BranchByOutcome`, contexte d'exécution et provenance: NSC-32;
- écriture de conséquences dans la preview: NSC-33;
- extraction des outcomes depuis le document Yarn validé: NSC-35;
- sauvegarde d'une Scene awaitable: NSC-32;
- changement de statut FG.

## Audit initial

### Capacités déjà présentes

- `addSceneNodeDraft`, `addSceneLinkedAssetNodeDraft` et `addSceneConsequenceActionNodeDraft` créaient déjà les nœuds supportés.
- `removeSceneNodeDraft`, `updateSceneNodeLayout`, `addSceneEdgeDraft` et `removeSceneEdgeDraft` couvraient déjà suppression, déplacement, connexion et déconnexion.
- `SceneGraphReadOnlyView`, malgré son nom historique, gérait déjà drag, zoom, ports visuels et création d'edge.
- `SceneDiagnostics` diagnostiquait déjà ports manquants, edges dupliqués, nœuds inaccessibles et cycles.
- le builder et l'exécuteur runtime transportaient déjà `expectedOutcomes` Dialogue et `battleDeclaredOutcomes`.

### Écarts réels trouvés

- `authorableSceneOutputPortsForNode` ignorait le payload et revenait à la liste fixe du kind;
- un outcome Dialogue `accept` était explicitement refusé par l'authoring malgré sa présence dans le payload;
- Combat restait limité à `victory/defeat` dans le runtime;
- aucune opération de duplication de nœud n'existait;
- aucune preview sèche à entrées explicites n'existait;
- le graph editable restait composé directement dans `scenes_workspace.dart`;
- une Scene déclarant des outcomes pouvait conserver un End sans outcome avec seulement un warning indirect.

### Risques identifiés

- casser les anciens graphes Dialogue à sortie `completed`;
- recopier les edges pendant une duplication et créer des sorties ambiguës;
- faire exécuter des callbacks réels pendant une preview;
- réimplémenter prématurément `BranchByOutcome`;
- créer une deuxième vérité des ports entre UI, plan et runtime;
- intégrer par erreur les changements Selbrume préexistants au commit.

### État Git initial

Branche `main`, worktree déjà sale. Changements préexistants préservés et exclus du lot:

```text
 M examples/playable_runtime_host/test/selbrume_event_v2_promoted_project_test.dart
A  examples/playable_runtime_host/test/selbrume_lighthouse_retry_integration_test.dart
 M examples/playable_runtime_host/test/selbrume_player_journey_e2e_test.dart
 M packages/map_editor/test/selbrume_canonical_narrative_seed_test.dart
 M packages/map_editor/tool/seed_selbrume_canonical_narrative_content.dart
 M packages/map_runtime/test/selbrume_event_v2_trigger_battle_anchor_integration_test.dart
 M packages/map_runtime/test/selbrume_static_boss_playable_map_game_integration_test.dart
 M selbrume/project.json
?? reports/gameplay/fg_000_narrative_studio_selbrume_readiness_reaudit_2026-07-19.md
```

## Décisions d'architecture

1. Les ports authorables sont dérivés du payload du nœud, jamais d'une liste locale UI.
2. Dialogue conserve toujours `completed` en compatibilité legacy et ajoute les outcomes déclarés distincts.
3. Combat utilise ses `declaredOutcomes`; `victory` et `defeat` conservent leurs kinds historiques, un outcome additionnel utilise `branchOutcome`.
4. `SceneRuntimePlanIntent.declaredOutputPortIds` devient la source runtime des sorties attendues.
5. La duplication copie le payload immutable et le texte, décale le layout de `32,32`, mais ne copie aucun edge.
6. Start et BranchByOutcome ne sont pas duplicables dans ce lot.
7. La preview est pure, synchrone et fail-closed: elle attend une entrée explicite sur Condition/Dialogue/Combat, refuse une sortie inconnue et limite le nombre de pas.
8. End reste le seul émetteur final de l'outcome de Scene; si la Scene déclare des outcomes, chaque End doit en choisir un.
9. `SceneGraphEditor` compose l'ancien canvas éprouvé et les nouvelles commandes avec les primitives/tokens du design system.

## Inventaire complet des fichiers du lot

| Fichier | Zone | Impact |
|---|---|---|
| `packages/map_core/lib/map_core.dart` | export preview | API publique pure. |
| `packages/map_core/lib/src/authoring/scene_authoring_operations.dart` | ports payload-aware, `duplicateSceneNodeDraft` | Authoring dynamique et duplication sûre. |
| `packages/map_core/lib/src/diagnostics/scene_diagnostics.dart` | End requis, ports Combat dynamiques | Validation bloquante cohérente. |
| `packages/map_core/lib/src/runtime/scene_runtime_plan.dart` | `declaredOutputPortIds` | Source unique runtime des ports. |
| `packages/map_core/lib/src/runtime/scene_runtime_executor.dart` | outcomes Combat déclarés | Exécution alignée sur le plan. |
| `packages/map_core/lib/src/runtime/scene_runtime_dry_run_preview.dart` | fichier créé | Preview pure à état explicite. |
| `packages/map_core/test/scene_authoring_operations_test.dart` | ports et duplication | TDD core. |
| `packages/map_core/test/scene_diagnostics_test.dart` | garde End/outcome | Prouve le diagnostic bloquant. |
| `packages/map_core/test/scene_runtime_dry_run_preview_test.dart` | fichier créé | Chemin, attente et sortie inconnue. |
| `packages/map_editor/lib/src/ui/canvas/scenes/scene_graph_editor.dart` | fichier créé | Graph authorable extrait et preview no-code. |
| `packages/map_editor/lib/src/ui/canvas/scenes_workspace.dart` | composition et callback duplication | Intégration workspace. |
| `packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart` | transaction projet duplication | Mutation via frontière existante. |
| `packages/map_editor/test/scene_graph_authoring_test.dart` | fichier créé | Duplication et preview widget. |
| `packages/map_editor/test/scenes_workspace_shell_test.dart` | assertion outcomes dynamiques | Non-régression shell. |
| `packages/map_editor/test/goldens/narrative_studio/scenes/scenes_full_product_route_1672x941.png` | golden | Référence plein produit actualisée. |
| `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_15_bis_edge_selection_deletion_ux_v0.png` | golden | Barre graph/ports actualisés. |
| `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_15_visual_port_connection_ux_v0.png` | golden | Barre graph/ports actualisés. |
| `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_15_wire_anchor_color_code.png` | golden | Barre graph/ports actualisés. |
| `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_17_condition_authoring_v0.png` | golden | Barre graph/ports actualisés. |
| `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_18_fact_registry_v0.png` | golden | Barre graph/ports actualisés. |
| `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_25_bis_dialogue_battle_ports_authoring_v0.png` | golden | Outcomes dynamiques visibles. |
| `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_30_bis_scene_node_deletion_ux_v0.png` | golden | Barre graph actualisée. |
| `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_30_scene_node_payload_editing_v0.png` | golden | Barre graph actualisée. |
| `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_31_scene_consequence_authoring_ui_v0.png` | golden | Barre graph actualisée. |
| `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_39_cinematic_scene_builder_picker_v0.png` | golden | Barre graph actualisée. |
| `reports/narrativeStudio/completion/nsc_31_scene_graph_dynamic_ports_evidence_pack.md` | présent rapport | Traçabilité. |

## Diffs / zones précises

- `scene_authoring_operations.dart`: après `authorableSceneOutputPortsForNode` et après `addSceneNodeDraft`.
- `scene_diagnostics.dart`: enum `SceneDiagnosticCode`, boucle des End, factory des specs Combat.
- `scene_runtime_plan.dart`: getter public après les champs de l'intent.
- `scene_runtime_executor.dart`: branche `startBattle`.
- `scenes_workspace.dart`: typedef/callback duplication, composition `_SelectedSceneSummary`.
- `narrative_workspace_canvas.dart`: callback transactionnel adjacent aux mutations de nœuds.
- les fichiers créés sont reproduits intégralement en annexes.

## Tests et validations

### TDD rouge

```text
dart test test/scene_authoring_operations_test.dart test/scene_runtime_dry_run_preview_test.dart
```

Résultat attendu observé: compilation refusée car `duplicateSceneNodeDraft`, `SceneDryRunInputState`, `SceneDryRunPreviewStatus` et `previewSceneRuntimePath` n'existaient pas.

### Ciblés core

```text
dart test test/scene_authoring_operations_test.dart test/scene_runtime_dry_run_preview_test.dart test/scene_diagnostics_test.dart test/scene_runtime_executor_test.dart
```

Résultat exact après ajout du garde End: **108 tests passés, 0 échec**.

### Ciblés editor

```text
flutter test test/scene_graph_authoring_test.dart
```

Résultat exact: **2 tests passés, 0 échec**.

```text
flutter test --update-goldens test/scenes_workspace_shell_test.dart
```

Résultat exact: **86 tests passés, 0 échec**.

```text
flutter test --update-goldens test/ui/canvas/narrative_studio_workspace_visual_test.dart
```

Résultat exact: **55 tests passés, 0 échec**.

```text
flutter test --update-goldens test/scene_cinematic_picker_test.dart
```

Résultat exact: **suite passée, golden Cinematic actualisé**.

### Suites complètes

```text
cd packages/map_core && dart test
```

Résultat exact: **3 180 tests passés, 0 échec**.

```text
cd packages/map_editor && flutter test -r compact
```

Résultat exact: **3 575 tests passés, 0 échec**, `exit_code: 0`.

### Analyses

```text
cd packages/map_core && dart analyze
```

Résultat exact: `No issues found!`

```text
cd packages/map_editor && flutter analyze
```

Résultat exact: `No issues found! (ran in 5.4s)`.

### Build

```text
cd packages/map_editor && flutter build macos --debug
```

Résultat exact: `✓ Built build/macos/Build/Products/Debug/map_editor.app`.

## Passes séparées exigées par codex_rule.md

La règle supérieure interdisait de créer des sub-agents pour ce tour. Les vérifications ont été réalisées comme passes locales nommées et séparées.

| Passe | Verdict | Détail |
|---|---|---|
| Lovelace — contrat domaine | PASS | Les ports proviennent des payloads et convergent dans le plan; aucun modèle UI parallèle. |
| Peirce — design system / workspace | PASS | Composant extrait, primitives DS, tokens sémantiques, matrices responsive/goldens vertes. |
| Ramanujan — runtime / compatibilité | PASS | Dialogue `completed` préservé, Combat dynamique, preview pure et limites explicites. |
| Tests / Build | PASS | 3 180 core, 3 575 editor, analyses propres, build Debug vert. |
| Critique finale | PASS avec limites documentées | BranchByOutcome et effects preview restent aux lots propriétaires suivants. |

## Auto-critique et risques restants

- `SceneGraphReadOnlyView` conserve un nom historique trompeur bien qu'il soit interactif; le renommer créerait du churn hors scope.
- La preview NSC-31 ne simule pas encore l'avant/après des conséquences; NSC-33 possède explicitement cette responsabilité.
- Un outcome Combat additionnel utilise `SceneEdgeKind.branchOutcome`, choix compatible avec le modèle actuel mais qui devra être revalidé avec le fallback typé NSC-32.
- `completed` reste proposé pour Dialogue même avec des outcomes déclarés afin de relire et reconnecter les graphes legacy. NSC-35 décidera, à partir du document validé, si un nouveau graph doit l'utiliser.
- Le panneau de preview liste tous les nœuds de décision de la Scene, même hors du chemin choisi. C'est volontairement explicite mais une UX progressive pourra masquer les entrées non atteintes après NSC-32.
- Les goldens ont été régénérés uniquement après vérification fonctionnelle des différences; aucun changement Selbrume n'a été absorbé.

## État Git final avant commit

Le commit sera effectué avec `git commit --only` sur l'inventaire NSC-31. Le fichier Lighthouse déjà staged et tous les changements Selbrume préexistants restent hors commit.

## Statut proposé

- **NSC-31: DONE**
- Statuts FG: **inchangés / N/A**
- Prochain lot: **NSC-32 — BranchByOutcome, Merge et End de bout en bout**.

## Annexes — contenu complet des fichiers créés

Le présent Evidence Pack n'est pas reproduit récursivement. Les quatre autres fichiers créés sont reproduits intégralement ci-dessous.

### Annexe A — `scene_runtime_dry_run_preview.dart`

```dart
import 'scene_runtime_plan.dart';

enum SceneDryRunPreviewStatus {
  completed,
  awaitingInput,
  failed,
}

final class SceneDryRunInputState {
  const SceneDryRunInputState({
    this.outputPortByNodeId = const <String, String>{},
  });

  final Map<String, String> outputPortByNodeId;
}

final class SceneDryRunTraceEntry {
  const SceneDryRunTraceEntry({
    required this.nodeId,
    required this.intentKind,
    this.outputPortId,
  });

  final String nodeId;
  final SceneRuntimePlanIntentKind intentKind;
  final String? outputPortId;
}

final class SceneDryRunPreviewResult {
  SceneDryRunPreviewResult({
    required this.status,
    required List<SceneDryRunTraceEntry> trace,
    this.sceneOutcomeId,
    this.awaitingNodeId,
    List<String> acceptedOutputPortIds = const <String>[],
    this.message,
  })  : trace = List<SceneDryRunTraceEntry>.unmodifiable(trace),
        acceptedOutputPortIds =
            List<String>.unmodifiable(acceptedOutputPortIds);

  final SceneDryRunPreviewStatus status;
  final List<SceneDryRunTraceEntry> trace;
  final String? sceneOutcomeId;
  final String? awaitingNodeId;
  final List<String> acceptedOutputPortIds;
  final String? message;
}

SceneDryRunPreviewResult previewSceneRuntimePath(
  SceneRuntimePlan plan, {
  required SceneDryRunInputState input,
  int maxSteps = 100,
}) {
  if (maxSteps < 1) {
    throw ArgumentError.value(maxSteps, 'maxSteps', 'Must be positive.');
  }
  final nodesById = {for (final node in plan.nodes) node.id: node};
  var current = nodesById[plan.startNodeId];
  final trace = <SceneDryRunTraceEntry>[];
  if (current == null) {
    return _failed(trace, 'Start node "${plan.startNodeId}" is missing.');
  }

  for (var step = 0; step < maxSteps; step++) {
    if (current!.intent.kind == SceneRuntimePlanIntentKind.end) {
      trace.add(
        SceneDryRunTraceEntry(
          nodeId: current.id,
          intentKind: current.intent.kind,
        ),
      );
      return SceneDryRunPreviewResult(
        status: SceneDryRunPreviewStatus.completed,
        trace: trace,
        sceneOutcomeId: current.intent.sceneOutcomeId,
      );
    }

    final acceptedPorts = current.intent.declaredOutputPortIds;
    final requiresInput = _requiresExplicitInput(current.intent.kind);
    final explicitPort = input.outputPortByNodeId[current.id];
    if (requiresInput && explicitPort == null) {
      trace.add(
        SceneDryRunTraceEntry(
          nodeId: current.id,
          intentKind: current.intent.kind,
        ),
      );
      return SceneDryRunPreviewResult(
        status: SceneDryRunPreviewStatus.awaitingInput,
        trace: trace,
        awaitingNodeId: current.id,
        acceptedOutputPortIds: acceptedPorts,
        message: 'Choose an explicit output for node "${current.id}".',
      );
    }
    final outputPortId = explicitPort ?? acceptedPorts.single;
    if (!acceptedPorts.contains(outputPortId)) {
      trace.add(
        SceneDryRunTraceEntry(
          nodeId: current.id,
          intentKind: current.intent.kind,
          outputPortId: outputPortId,
        ),
      );
      return _failed(
        trace,
        'Output "$outputPortId" is unknown for node "${current.id}".',
      );
    }
    trace.add(
      SceneDryRunTraceEntry(
        nodeId: current.id,
        intentKind: current.intent.kind,
        outputPortId: outputPortId,
      ),
    );
    final matchingEdges = plan.edges
        .where(
          (edge) =>
              edge.fromNodeId == current!.id && edge.fromPortId == outputPortId,
        )
        .toList(growable: false);
    if (matchingEdges.length != 1) {
      return _failed(
        trace,
        matchingEdges.isEmpty
            ? 'No transition for ${current.id}:$outputPortId.'
            : 'Ambiguous transition for ${current.id}:$outputPortId.',
      );
    }
    current = nodesById[matchingEdges.single.toNodeId];
    if (current == null) {
      return _failed(trace, 'Transition target is missing.');
    }
  }
  return _failed(trace, 'Dry-run exceeded maxSteps=$maxSteps.');
}

bool _requiresExplicitInput(SceneRuntimePlanIntentKind kind) {
  return switch (kind) {
    SceneRuntimePlanIntentKind.evaluateCondition ||
    SceneRuntimePlanIntentKind.showDialogue ||
    SceneRuntimePlanIntentKind.startBattle =>
      true,
    _ => false,
  };
}

SceneDryRunPreviewResult _failed(
  List<SceneDryRunTraceEntry> trace,
  String message,
) {
  return SceneDryRunPreviewResult(
    status: SceneDryRunPreviewStatus.failed,
    trace: trace,
    message: message,
  );
}
```

### Annexe B — `scene_runtime_dry_run_preview_test.dart`

```dart
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('Scene runtime dry-run preview', () {
    test('waits for explicit input then previews the selected dialogue path',
        () {
      final plan = _dialoguePlan();

      final waiting = previewSceneRuntimePath(
        plan,
        input: const SceneDryRunInputState(),
      );
      expect(waiting.status, SceneDryRunPreviewStatus.awaitingInput);
      expect(waiting.awaitingNodeId, 'node_dialogue');
      expect(waiting.acceptedOutputPortIds, ['completed', 'accept', 'leave']);
      expect(waiting.trace.map((entry) => entry.nodeId), [
        'node_start',
        'node_dialogue',
      ]);

      final completed = previewSceneRuntimePath(
        plan,
        input: const SceneDryRunInputState(
          outputPortByNodeId: {'node_dialogue': 'leave'},
        ),
      );
      expect(completed.status, SceneDryRunPreviewStatus.completed);
      expect(completed.sceneOutcomeId, 'left');
      expect(completed.trace.map((entry) => entry.nodeId), [
        'node_start',
        'node_dialogue',
        'node_leave',
      ]);
    });

    test('rejects an explicit output not declared by the node', () {
      final result = previewSceneRuntimePath(
        _dialoguePlan(),
        input: const SceneDryRunInputState(
          outputPortByNodeId: {'node_dialogue': 'unknown'},
        ),
      );

      expect(result.status, SceneDryRunPreviewStatus.failed);
      expect(result.message, contains('unknown'));
    });
  });
}

SceneRuntimePlan _dialoguePlan() {
  return SceneRuntimePlan(
    sceneId: 'scene_preview',
    startNodeId: 'node_start',
    nodes: [
      SceneRuntimePlanNode(
        id: 'node_start',
        kind: SceneNodeKind.start,
        intent: SceneRuntimePlanIntent.start(),
      ),
      SceneRuntimePlanNode(
        id: 'node_dialogue',
        kind: SceneNodeKind.yarnDialogue,
        intent: SceneRuntimePlanIntent.showDialogue(
          dialogueId: 'dialogue_test',
          expectedOutcomes: const ['accept', 'leave'],
        ),
      ),
      SceneRuntimePlanNode(
        id: 'node_accept',
        kind: SceneNodeKind.end,
        intent: SceneRuntimePlanIntent.end(sceneOutcomeId: 'accepted'),
      ),
      SceneRuntimePlanNode(
        id: 'node_leave',
        kind: SceneNodeKind.end,
        intent: SceneRuntimePlanIntent.end(sceneOutcomeId: 'left'),
      ),
    ],
    edges: const [
      SceneRuntimePlanEdge(
        id: 'edge_start_dialogue',
        fromNodeId: 'node_start',
        fromPortId: 'completed',
        toNodeId: 'node_dialogue',
        kind: SceneEdgeKind.defaultFlow,
      ),
      SceneRuntimePlanEdge(
        id: 'edge_accept',
        fromNodeId: 'node_dialogue',
        fromPortId: 'accept',
        toNodeId: 'node_accept',
        kind: SceneEdgeKind.dialogueOutcome,
      ),
      SceneRuntimePlanEdge(
        id: 'edge_leave',
        fromNodeId: 'node_dialogue',
        fromPortId: 'leave',
        toNodeId: 'node_leave',
        kind: SceneEdgeKind.dialogueOutcome,
      ),
    ],
    declaredOutcomes: [
      SceneOutcome(id: 'accepted', label: 'Accepted'),
      SceneOutcome(id: 'left', label: 'Left'),
    ],
  );
}
```

### Annexe C — `scene_graph_editor.dart`

```dart
import 'package:flutter/cupertino.dart';
import 'package:map_core/map_core.dart';

import '../../../features/narrative/application/narrative_workspace_projection.dart';
import '../../../theme/theme.dart';
import '../../design_system/design_system.dart';
import 'scene_graph_read_only_view.dart';

typedef SceneGraphNodeDuplicator = Future<String?> Function(String nodeId);

class SceneGraphEditor extends StatefulWidget {
  const SceneGraphEditor({
    super.key,
    required this.scene,
    this.selectedNodeId,
    this.selectedEdgeId,
    this.onSelectNode,
    this.onSelectEdge,
    this.onUpdateNodeLayout,
    this.onCreateEdgeDraft,
    this.onDuplicateNode,
    this.focusNodeForNodeId,
    this.canDragNodes = true,
  });

  final NarrativeSceneSummary scene;
  final String? selectedNodeId;
  final String? selectedEdgeId;
  final ValueChanged<String>? onSelectNode;
  final ValueChanged<String>? onSelectEdge;
  final SceneNodeLayoutChanged? onUpdateNodeLayout;
  final SceneVisualEdgeDraftCreator? onCreateEdgeDraft;
  final SceneGraphNodeDuplicator? onDuplicateNode;
  final FocusNode Function(String nodeId)? focusNodeForNodeId;
  final bool canDragNodes;

  @override
  State<SceneGraphEditor> createState() => _SceneGraphEditorState();
}

class _SceneGraphEditorState extends State<SceneGraphEditor> {
  final Map<String, String> _outputPortByNodeId = {};
  bool _previewOpen = false;
  SceneDryRunPreviewResult? _preview;

  @override
  void didUpdateWidget(covariant SceneGraphEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scene.id != widget.scene.id ||
        oldWidget.scene.graph != widget.scene.graph) {
      _outputPortByNodeId.clear();
      _preview = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('scene-graph-editor'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildToolbar(),
        if (_previewOpen) ...[
          const SizedBox(height: 8),
          _buildDryRunPanel(context),
        ],
        const SizedBox(height: 8),
        Expanded(
          child: SceneGraphReadOnlyView(
            scene: widget.scene,
            selectedNodeId: widget.selectedNodeId,
            selectedEdgeId: widget.selectedEdgeId,
            focusNodeForNodeId: widget.focusNodeForNodeId,
            onSelectNode: widget.onSelectNode,
            onSelectEdge: widget.onSelectEdge,
            canDragNodes: widget.canDragNodes,
            onCreateEdgeDraft: widget.onCreateEdgeDraft,
            onUpdateNodeLayout: widget.onUpdateNodeLayout,
            expandToFill: true,
          ),
        ),
      ],
    );
  }

  Widget _buildToolbar() {
    final selectedNode = _selectedNode;
    final canDuplicate = selectedNode != null &&
        selectedNode.kind != SceneNodeKind.start &&
        selectedNode.kind != SceneNodeKind.branchByOutcome &&
        widget.onDuplicateNode != null;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        PokeMapButton(
          key: const ValueKey('scene-graph-duplicate-node'),
          onPressed: canDuplicate ? _duplicateSelectedNode : null,
          variant: PokeMapButtonVariant.secondary,
          size: PokeMapButtonSize.small,
          leading: const Icon(CupertinoIcons.doc_on_doc, size: 14),
          child: const Text('Dupliquer le nœud'),
        ),
        PokeMapButton(
          key: const ValueKey('scene-graph-toggle-dry-run'),
          onPressed: () => setState(() => _previewOpen = !_previewOpen),
          variant: _previewOpen
              ? PokeMapButtonVariant.primary
              : PokeMapButtonVariant.secondary,
          size: PokeMapButtonSize.small,
          leading: const Icon(CupertinoIcons.play_arrow_solid, size: 14),
          child: const Text('Prévisualiser le chemin'),
        ),
      ],
    );
  }

  Widget _buildDryRunPanel(BuildContext context) {
    final colors = context.pokeMapColors;
    final decisionNodes = widget.scene.graph.nodes.where(
      (node) =>
          node.kind == SceneNodeKind.condition ||
          node.kind == SceneNodeKind.yarnDialogue ||
          node.kind == SceneNodeKind.battle,
    );
    return PokeMapPanel(
      key: const ValueKey('scene-graph-dry-run-panel'),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'État d’entrée explicite',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          for (final node in decisionNodes) ...[
            Text(
              node.title ?? node.id,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final port in authorableSceneOutputPortsForNode(node))
                  PokeMapButton(
                    key: ValueKey(
                      'scene-graph-preview-input-${node.id}-${port.id}',
                    ),
                    onPressed: () => setState(() {
                      _outputPortByNodeId[node.id] = port.id;
                      _preview = null;
                    }),
                    variant: PokeMapButtonVariant.ghost,
                    size: PokeMapButtonSize.small,
                    isSelected: _outputPortByNodeId[node.id] == port.id,
                    child: Text(port.label),
                  ),
              ],
            ),
            const SizedBox(height: 6),
          ],
          Align(
            alignment: Alignment.centerLeft,
            child: PokeMapButton(
              key: const ValueKey('scene-graph-run-dry-run'),
              onPressed: _runDryPreview,
              variant: PokeMapButtonVariant.successOutline,
              size: PokeMapButtonSize.small,
              child: const Text('Calculer le chemin'),
            ),
          ),
          if (_preview case final preview?) ...[
            const SizedBox(height: 8),
            Text(
              _previewMessage(preview),
              key: const ValueKey('scene-graph-dry-run-result'),
              style: TextStyle(
                color: preview.status == SceneDryRunPreviewStatus.failed
                    ? colors.error
                    : colors.textPrimary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }

  SceneNode? get _selectedNode {
    for (final node in widget.scene.graph.nodes) {
      if (node.id == widget.selectedNodeId) return node;
    }
    return null;
  }

  Future<void> _duplicateSelectedNode() async {
    final node = _selectedNode;
    final duplicate = widget.onDuplicateNode;
    if (node == null || duplicate == null) return;
    final createdId = await duplicate(node.id);
    if (createdId != null) widget.onSelectNode?.call(createdId);
  }

  void _runDryPreview() {
    final scene = SceneAsset(
      id: widget.scene.id,
      name: widget.scene.name,
      description: widget.scene.description,
      storylineId: widget.scene.storylineId,
      chapterId: widget.scene.chapterId,
      tags: widget.scene.tags,
      graph: widget.scene.graph,
      layout: widget.scene.layout,
      declaredOutcomes: widget.scene.outcomeDefinitions,
      metadata: widget.scene.metadata,
    );
    final build = buildSceneRuntimePlan(scene);
    setState(() {
      _preview = build.plan == null
          ? SceneDryRunPreviewResult(
              status: SceneDryRunPreviewStatus.failed,
              trace: const [],
              message: build.diagnostics.isEmpty
                  ? 'La scène ne peut pas être planifiée.'
                  : build.diagnostics.first.message,
            )
          : previewSceneRuntimePath(
              build.plan!,
              input: SceneDryRunInputState(
                outputPortByNodeId: Map.unmodifiable(_outputPortByNodeId),
              ),
            );
    });
  }
}

String _previewMessage(SceneDryRunPreviewResult preview) {
  final path = preview.trace.map((entry) => entry.nodeId).join(' → ');
  return switch (preview.status) {
    SceneDryRunPreviewStatus.completed =>
      'Chemin : $path · outcome : ${preview.sceneOutcomeId ?? 'aucun'}',
    SceneDryRunPreviewStatus.awaitingInput =>
      'Entrée requise pour ${preview.awaitingNodeId}. Chemin : $path',
    SceneDryRunPreviewStatus.failed => preview.message ?? 'Preview impossible.',
  };
}
```

### Annexe D — `scene_graph_authoring_test.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/narrative/application/narrative_workspace_projection.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/canvas/scenes/scene_graph_editor.dart';

void main() {
  testWidgets('duplicates the selected node through the graph editor', (
    tester,
  ) async {
    String? duplicatedNodeId;
    await _pumpEditor(
      tester,
      onDuplicateNode: (nodeId) async {
        duplicatedNodeId = nodeId;
        return 'node_condition_2';
      },
    );

    await tester.tap(find.byKey(const ValueKey('scene-graph-duplicate-node')));
    await tester.pump();

    expect(duplicatedNodeId, 'node_condition');
  });

  testWidgets('previews a path from explicit condition input', (tester) async {
    await _pumpEditor(tester);

    await tester.tap(find.byKey(const ValueKey('scene-graph-toggle-dry-run')));
    await tester.pump();
    await tester.tap(
      find.byKey(
        const ValueKey('scene-graph-preview-input-node_condition-true'),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('scene-graph-run-dry-run')));
    await tester.pump();

    expect(
      find.textContaining('node_start → node_condition → node_end_true'),
      findsOneWidget,
    );
    expect(find.textContaining('outcome : yes'), findsOneWidget);
  });
}

Future<void> _pumpEditor(
  WidgetTester tester, {
  SceneGraphNodeDuplicator? onDuplicateNode,
}) async {
  tester.view.physicalSize = const Size(1200, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: PokeMapTheme.light(),
      darkTheme: PokeMapTheme.dark(),
      themeMode: ThemeMode.dark,
      home: Scaffold(
        body: SceneGraphEditor(
          scene: _summary(),
          selectedNodeId: 'node_condition',
          onDuplicateNode: onDuplicateNode,
        ),
      ),
    ),
  );
  await tester.pump();
}

NarrativeSceneSummary _summary() {
  final graph = SceneGraph(
    startNodeId: 'node_start',
    nodes: [
      SceneNode(id: 'node_start', kind: SceneNodeKind.start),
      SceneNode(
        id: 'node_condition',
        kind: SceneNodeKind.condition,
        title: 'Le port est ouvert',
        payload: SceneConditionPayload(
          conditionSource: SceneConditionSource(
            sourceKind: SceneConditionSourceKind.fact,
            sourceId: 'fact_port_open',
            operator: SceneConditionOperator.equals,
            value: 'true',
          ),
        ),
      ),
      SceneNode(
        id: 'node_end_true',
        kind: SceneNodeKind.end,
        payload: SceneEndPayload(sceneOutcomeId: 'yes'),
      ),
      SceneNode(
        id: 'node_end_false',
        kind: SceneNodeKind.end,
        payload: SceneEndPayload(sceneOutcomeId: 'no'),
      ),
    ],
    edges: [
      SceneEdge(
        id: 'edge_start_condition',
        fromNodeId: 'node_start',
        fromPortId: 'completed',
        toNodeId: 'node_condition',
        kind: SceneEdgeKind.defaultFlow,
      ),
      SceneEdge(
        id: 'edge_true',
        fromNodeId: 'node_condition',
        fromPortId: 'true',
        toNodeId: 'node_end_true',
        kind: SceneEdgeKind.conditionTrue,
      ),
      SceneEdge(
        id: 'edge_false',
        fromNodeId: 'node_condition',
        fromPortId: 'false',
        toNodeId: 'node_end_false',
        kind: SceneEdgeKind.conditionFalse,
      ),
    ],
  );
  final outcomes = [
    SceneOutcome(id: 'yes', label: 'Yes'),
    SceneOutcome(id: 'no', label: 'No'),
  ];
  final scene = SceneAsset(
    id: 'scene_graph_authoring',
    name: 'Graph authoring',
    graph: graph,
    layout: SceneGraphLayout(
      nodeLayouts: [
        SceneNodeLayout(nodeId: 'node_start', x: 24, y: 80),
        SceneNodeLayout(nodeId: 'node_condition', x: 320, y: 80),
        SceneNodeLayout(nodeId: 'node_end_true', x: 620, y: 30),
        SceneNodeLayout(nodeId: 'node_end_false', x: 620, y: 160),
      ],
    ),
    declaredOutcomes: outcomes,
  );
  return NarrativeSceneSummary(
    id: scene.id,
    name: scene.name,
    nodeCount: graph.nodes.length,
    edgeCount: graph.edges.length,
    declaredOutcomeCount: outcomes.length,
    declaredOutcomes: outcomes.map((outcome) => outcome.label).toList(),
    tags: const [],
    graph: graph,
    layout: scene.layout,
    diagnostics: diagnoseScene(scene),
    outcomeDefinitions: outcomes,
  );
}
```
