# Evidence Pack — NSC-32 Branch, Merge, End et contexte d'exécution

## Résumé exécutif

Le lot **NSC-32 — BranchByOutcome, Merge et End** est implémenté et proposé **DONE**. Un outcome produit par Dialogue, Combat ou Condition est désormais mémorisé dans un `SceneExecutionContext`, peut traverser un ou plusieurs Merge, puis être routé par un Branch vers un port exact ou vers un fallback typé (`exact`, `defaultRoute`, `errorRoute`). Le dry-run et le runtime utilisent le même contrat; l'UI construit le Branch avec des pickers guidés et refuse une source invalide.

Le contexte garde également la provenance des Branch et les nœuds persistants déjà appliqués. La sauvegarde reste volontairement bloquée pendant une Scene awaitable et redevient disponible après End. Aucun statut FG n'est changé par ce lot.

## Scope et critères de réussite

Inclus:

- modèle typé et codec du fallback Branch;
- source Branch guidée vers Condition, Dialogue ou Combat;
- compilation Branch/Merge/End dans le plan runtime;
- mémoire des outcomes par nœud, outcome courant et provenance de routage;
- routage exact, default et error, avec échec fermé si aucune route ne convient;
- parité preview/runtime sur `Dialogue -> Merge -> Branch -> Action -> Merge -> End`;
- non-réexécution d'une conséquence persistante déjà présente dans le contexte;
- diagnostic des sources absentes/inconnues/non productrices d'outcomes;
- duplication et rendu des nœuds Branch;
- checkpoint interdit pendant une attente et autorisé après End;
- compatibilité des anciennes valeurs JSON `blocked`, `defaultRoute`, `errorRoute`.

Hors scope:

- catalogue complet des conséquences et atomicité métier: NSC-33;
- dialecte Yarn complet: NSC-34;
- registry centralisée des commandes: NSC-37;
- builder d'actions/templates: NSC-38;
- sérialisation du contexte au milieu d'une Scene: explicitement interdite par le contrat de checkpoint.

## Audit initial

### Capacités présentes

- Merge existait dans le modèle et suivait déjà `completed`.
- End pouvait déjà émettre un outcome déclaré.
- Dialogue, Combat et Condition exposaient leurs ports dynamiques depuis NSC-31.
- l'activité narrative bloquait déjà la sauvegarde pendant les callbacks awaitables.

### Écarts trouvés

- Branch restait bloqué dans l'authoring et non compilé dans le plan;
- aucun état d'exécution ne survivait au passage par Merge;
- aucune provenance n'expliquait quel outcome avait choisi quelle route;
- la preview ne savait pas interpréter Branch;
- le fallback était une chaîne legacy sans sémantique runtime;
- une conséquence pouvait être rejouée si un contexte d'exécution était repris;
- les diagnostics ne validaient pas la source productrice du Branch;
- deux fixtures runtime historiques avaient une fin Combat silencieuse alors que la Scene déclarait des outcomes.

### État Git initial

Branche `main`, worktree déjà sale. Les changements préexistants ci-dessous sont préservés et exclus du commit:

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

1. `SceneExecutionContext` est immutable et uniquement en mémoire pendant une exécution.
2. Les outcomes sont indexés par ID de nœud afin qu'un Merge n'efface pas la valeur du producteur.
3. Branch référence explicitement son producteur par `sourceNodeId`; il ne dépend pas d'un « dernier outcome » ambigu.
4. Le Branch utilise d'abord une route exacte. Le fallback ne s'active que si cette route manque.
5. Les trois politiques sont des enums; les chaînes legacy sont décodées à la frontière JSON.
6. La provenance contient Branch, source, outcome, port choisi et usage éventuel du fallback.
7. Un nœud de conséquence déjà marqué persistant retourne `completed` sans rappeler l'hôte.
8. Même en cas d'échec ultérieur, le résultat restitue le contexte construit jusque-là.
9. Une Scene awaitable n'est jamais sauvegardée à mi-exécution: le checkpoint stable se situe avant son démarrage ou après End.
10. L'UI dérive les candidats Branch du graph courant et les outcomes des payloads canoniques, sans champ d'ID manuel.

## Inventaire des fichiers du lot

| Fichier | Zone modifiée | Impact |
|---|---|---|
| `packages/map_core/lib/map_core.dart` | export | Expose le contexte public. |
| `packages/map_core/lib/src/models/scene_asset.dart` | fallback Branch | Enum et codec compatible. |
| `packages/map_core/lib/src/runtime/scene_execution_context.dart` | créé | Mémoire, persistance et provenance. |
| `packages/map_core/lib/src/runtime/scene_runtime_plan.dart` | intent Branch | Contrat compilé. |
| `packages/map_core/lib/src/runtime/scene_runtime_plan_builder.dart` | compilation | Branch validé et compilé. |
| `packages/map_core/lib/src/runtime/scene_runtime_executor.dart` | exécution | Routage, contexte, idempotence et erreurs. |
| `packages/map_core/lib/src/runtime/scene_runtime_dry_run_preview.dart` | preview | Parité Branch/Merge et contexte. |
| `packages/map_core/lib/src/diagnostics/scene_diagnostics.dart` | diagnostics | Source et ports graph-aware. |
| `packages/map_core/lib/src/authoring/scene_authoring_operations.dart` | opérations | Création/duplication/ports Branch. |
| `packages/map_core/test/scene_asset_json_test.dart` | codec | Compatibilité des fallbacks. |
| `packages/map_core/test/scene_execution_context_test.dart` | créé | Immutabilité et provenance. |
| `packages/map_core/test/scene_runtime_plan_test.dart` | plan | Compilation Branch. |
| `packages/map_core/test/scene_runtime_executor_test.dart` | runtime | Exact/default/error/idempotence/échec. |
| `packages/map_core/test/scene_runtime_dry_run_preview_test.dart` | preview | Parité des routes. |
| `packages/map_core/test/scene_diagnostics_test.dart` | diagnostics | Sources invalides et fins. |
| `packages/map_core/test/scene_authoring_operations_test.dart` | authoring | Ports et duplication. |
| `packages/map_editor/lib/src/ui/canvas/scenes_workspace.dart` | UI | Pickers source/fallback et création Branch. |
| `packages/map_editor/lib/src/ui/canvas/scenes/scene_graph_read_only_view.dart` | canvas | Ports Branch dynamiques. |
| `packages/map_editor/lib/src/ui/canvas/scenes/scene_node_read_only_inspector.dart` | inspecteur | Fallback lisible. |
| `packages/map_editor/lib/src/ui/canvas/scenes/scene_graph_editor.dart` | commandes | Branch duplicable. |
| `packages/map_editor/test/scenes_workspace_shell_test.dart` | widget | Création guidée Branch. |
| `packages/map_runtime/test/narrative_scene_runtime_execution_test.dart` | fixture | End conforme au contrat outcome. |
| `packages/map_runtime/test/outcome_scene_branch_readiness_test.dart` | readiness | Branch outcome canonique. |
| `packages/map_runtime/test/scene_runtime_state_persistence_gate_test.dart` | checkpoint | Save bloqué puis autorisé. |
| `packages/map_runtime/test/scene_branch_merge_runtime_integration_test.dart` | créé | Vertical preview/runtime accept/refuse. |
| `packages/map_runtime/test/playable_map_game_qualified_outcome_v2_integration_test.dart` | fixture | Outcome explicite sur la fin defeat. |
| `reports/narrativeStudio/completion/nsc_32_branch_merge_end_evidence_pack.md` | créé | Présent rapport. |

## Diffs / zones précises

- modèle: `SceneBranchByOutcomePayload`, enum `SceneBranchOutcomeFallbackPolicy`, `toJson/fromJson`;
- plan: champs `branchSourceNodeId`, `branchFallbackPolicy`, `declaredOutputPortIds`;
- builder: branche `SceneNodeKind.branchByOutcome` et validation du producteur;
- executor: `_branchOutput`, `_recordCallbackOutcome`, `_consequenceCallbackOutput`, propagation du contexte dans `_failed`;
- preview: interprétation Branch/Merge et résultat enrichi du contexte;
- diagnostics/authoring: résolution des ports à partir du graph et du payload source;
- editor: commande Branch activée seulement lorsqu'une source admissible existe, deux dialogues de sélection successifs;
- runtime: fixture verticale et contrôle du checkpoint autour d'un callback suspendu.

## Tests et validations

### TDD et tests ciblés

Les tests ont d'abord échoué sur l'absence de `SceneExecutionContext`, de l'intent Branch et de l'authoring Branch. Après implémentation:

```text
cd packages/map_core && dart test test/scene_runtime_executor_test.dart
```

Résultat final exact: **28 tests passés, 0 échec**.

```text
cd packages/map_editor && flutter test test/scenes_workspace_shell_test.dart
```

Résultat final: **suite passée, 0 échec**.

```text
cd packages/map_runtime && flutter test test/outcome_scene_branch_readiness_test.dart test/scene_runtime_state_persistence_gate_test.dart test/scene_branch_merge_runtime_integration_test.dart test/narrative_scene_runtime_execution_test.dart
```

Résultat exact: **19 tests passés, 0 échec**.

```text
cd packages/map_runtime && flutter test test/playable_map_game_qualified_outcome_v2_integration_test.dart --reporter failures-only
```

Résultat exact: **43 tests passés, 0 échec**.

### Suites complètes

```text
cd packages/map_core && dart test --reporter failures-only
```

Résultat exact: **3 189 tests passés, 0 échec**.

```text
cd packages/map_editor && flutter test --reporter failures-only
```

Résultat exact: **3 576 tests passés, 0 échec**.

```text
cd packages/map_runtime && flutter test --reporter failures-only
```

Résultat exact: **1 831 tests passés, 1 test explicitement ignoré, 0 échec**.

### Analyses et build

```text
cd packages/map_core && dart analyze
```

Résultat exact: `No issues found!`

```text
cd packages/map_editor && flutter analyze
```

Résultat exact: `No issues found!`

```text
cd packages/map_runtime && flutter analyze
```

Résultat exact: `No issues found! (ran in 11.7s)`.

```text
cd packages/map_editor && flutter build macos --debug
```

Résultat exact: `✓ Built build/macos/Build/Products/Debug/map_editor.app`.

## Passes séparées exigées par codex_rule.md

La règle de collaboration active interdisait la création de nouveaux sub-agents. Les audits ont donc été exécutés comme passes locales séparées.

| Passe | Verdict | Contrôle |
|---|---|---|
| Lovelace — domaine | PASS | Contexte immutable, fallback typé, validation fail-closed, compat JSON. |
| Peirce — design system | PASS | Pickers guidés, aucune saisie d'ID, ports issus du domaine, aucun coloris ad hoc. |
| Ramanujan — runtime | PASS | Preview/runtime concordants, provenance exacte, checkpoint stable, 1 831 tests runtime verts. |
| Vérification finale | PASS | Suites complètes, analyses et build macOS verts. |

## Auto-critique et risques restants

- Le contexte n'est pas sérialisé. C'est intentionnel tant que la sauvegarde est bloquée pendant une Scene; une future reprise à mi-Scene exigerait un protocole versionné distinct.
- Le Branch pointe vers un producteur situé n'importe où dans le graph, pas nécessairement dominé structurellement. L'absence d'outcome échoue proprement au runtime, mais une analyse de dominance serait une amélioration possible.
- Les conséquences sont idempotentes par ID de nœud dans une exécution; l'atomicité complète des écritures métier appartient à NSC-33.
- Deux fixtures ont dû expliciter une fin `scene.defeated`; aucun comportement du chemin victoire testé n'a changé.
- Aucun golden n'a été régénéré: la modification UI est couverte par widget test et les goldens complets existants sont restés verts.

## État Git final avant commit

Le commit doit utiliser une sélection de chemins explicite. Les changements Selbrume initiaux restent hors commit, y compris le fichier déjà staged `selbrume_lighthouse_retry_integration_test.dart`.

Statut proposé du lot: **NSC-32 = DONE**.

## Annexe A — contenu complet de `scene_execution_context.dart`

```dart
import 'package:meta/meta.dart' show immutable;

@immutable
final class SceneBranchProvenanceEntry {
  const SceneBranchProvenanceEntry({
    required this.branchNodeId,
    required this.sourceNodeId,
    required this.sourceOutcome,
    required this.routedPortId,
    required this.usedFallback,
  });

  final String branchNodeId;
  final String sourceNodeId;
  final String sourceOutcome;
  final String routedPortId;
  final bool usedFallback;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SceneBranchProvenanceEntry &&
          other.branchNodeId == branchNodeId &&
          other.sourceNodeId == sourceNodeId &&
          other.sourceOutcome == sourceOutcome &&
          other.routedPortId == routedPortId &&
          other.usedFallback == usedFallback;

  @override
  int get hashCode => Object.hash(
        branchNodeId,
        sourceNodeId,
        sourceOutcome,
        routedPortId,
        usedFallback,
      );
}

/// In-memory state carried while one Scene executes.
///
/// This state deliberately is not part of a save file: runtime checkpoints are
/// blocked while a Scene is awaiting host input. Only the state before the
/// Scene starts and the committed state after an End node are persistable.
@immutable
final class SceneExecutionContext {
  SceneExecutionContext({
    Map<String, String> lastOutcomeByNodeId = const <String, String>{},
    this.currentOutcome,
    Set<String> appliedPersistentNodeIds = const <String>{},
    List<SceneBranchProvenanceEntry> branchProvenance =
        const <SceneBranchProvenanceEntry>[],
  })  : lastOutcomeByNodeId = Map<String, String>.unmodifiable(
          lastOutcomeByNodeId,
        ),
        appliedPersistentNodeIds = Set<String>.unmodifiable(
          appliedPersistentNodeIds,
        ),
        branchProvenance = List<SceneBranchProvenanceEntry>.unmodifiable(
          branchProvenance,
        );

  static final SceneExecutionContext empty = SceneExecutionContext();

  final Map<String, String> lastOutcomeByNodeId;
  final String? currentOutcome;
  final Set<String> appliedPersistentNodeIds;
  final List<SceneBranchProvenanceEntry> branchProvenance;

  SceneExecutionContext recordOutcome({
    required String nodeId,
    required String outcome,
  }) {
    return SceneExecutionContext(
      lastOutcomeByNodeId: <String, String>{
        ...lastOutcomeByNodeId,
        nodeId: outcome,
      },
      currentOutcome: outcome,
      appliedPersistentNodeIds: appliedPersistentNodeIds,
      branchProvenance: branchProvenance,
    );
  }

  SceneExecutionContext markPersistentNodeApplied(String nodeId) {
    return SceneExecutionContext(
      lastOutcomeByNodeId: lastOutcomeByNodeId,
      currentOutcome: currentOutcome,
      appliedPersistentNodeIds: <String>{
        ...appliedPersistentNodeIds,
        nodeId,
      },
      branchProvenance: branchProvenance,
    );
  }

  SceneExecutionContext recordBranch(SceneBranchProvenanceEntry entry) {
    return SceneExecutionContext(
      lastOutcomeByNodeId: lastOutcomeByNodeId,
      currentOutcome: entry.sourceOutcome,
      appliedPersistentNodeIds: appliedPersistentNodeIds,
      branchProvenance: <SceneBranchProvenanceEntry>[
        ...branchProvenance,
        entry,
      ],
    );
  }
}
```

## Annexe B — contenu complet de `scene_execution_context_test.dart`

```dart
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('SceneExecutionContext', () {
    test('records outcomes without mutating the previous context', () {
      final initial = SceneExecutionContext.empty;

      final updated = initial.recordOutcome(
        nodeId: 'dialogue_intro',
        outcome: 'accept',
      );

      expect(initial.lastOutcomeByNodeId, isEmpty);
      expect(initial.currentOutcome, isNull);
      expect(updated.lastOutcomeByNodeId, {'dialogue_intro': 'accept'});
      expect(updated.currentOutcome, 'accept');
    });

    test('tracks persistent nodes and branch provenance immutably', () {
      final withOutcome = SceneExecutionContext.empty.recordOutcome(
        nodeId: 'battle_rival',
        outcome: 'victory',
      );
      final withPersistentNode =
          withOutcome.markPersistentNodeApplied('reward_action');
      final completed = withPersistentNode.recordBranch(
        const SceneBranchProvenanceEntry(
          branchNodeId: 'branch_battle',
          sourceNodeId: 'battle_rival',
          sourceOutcome: 'victory',
          routedPortId: 'victory',
          usedFallback: false,
        ),
      );

      expect(withOutcome.appliedPersistentNodeIds, isEmpty);
      expect(withPersistentNode.appliedPersistentNodeIds, {'reward_action'});
      expect(completed.branchProvenance, hasLength(1));
      expect(completed.branchProvenance.single.sourceOutcome, 'victory');
      expect(completed.currentOutcome, 'victory');
    });
  });
}
```

## Annexe C — contenu complet de `scene_branch_merge_runtime_integration_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/src/application/narrative_scene_runtime_execution.dart';

void main() {
  group('Scene BranchByOutcome runtime integration', () {
    test(
        'Dialogue outcome follows the same Merge/Branch/End path in preview '
        'and runtime', () async {
      final scene = _scene();
      final project = _project(scene);
      const initial = GameState(saveId: 'save_branch_merge');

      final preview = previewSceneRuntimePath(
        buildSceneRuntimePlan(scene).plan!,
        input: const SceneDryRunInputState(
          outputPortByNodeId: {'dialogue': 'accept'},
        ),
      );
      final runtime = await executeNarrativeEventScene(
        request: const NarrativeSceneExecutionRequest(
          eventId: 'event_branch_merge',
          sceneId: 'scene_branch_merge',
          executionId: 'execution_branch_merge',
          gameState: initial,
        ),
        project: project,
        mapsById: const <String, MapData>{},
        currentGameState: () => initial,
        callbacks: SceneRuntimeHostCallbacks(
          evaluateCondition: (_) => throw StateError('Unexpected condition'),
          showDialogue: (_) => 'accept',
          startBattle: (_) => throw StateError('Unexpected battle'),
          playCinematic: (_) => throw StateError('Unexpected cinematic'),
        ),
      );

      expect(preview.status, SceneDryRunPreviewStatus.completed);
      expect(preview.sceneOutcomeId, 'scene.accepted');
      expect(preview.context.branchProvenance.single.sourceOutcome, 'accept');
      expect(runtime, isA<NarrativeSceneExecutionCompleted>());
      final completed = runtime as NarrativeSceneExecutionCompleted;
      expect(
        completed.updatedGameState.storyFlags.activeFlags,
        contains('fact_branch_reward'),
      );
      expect(completed.qualifiedOutcomes.single.outcomeId, 'scene.accepted');
    });

    test('refuse reaches a different End without applying accept consequence',
        () async {
      final scene = _scene();
      final project = _project(scene);
      const initial = GameState(saveId: 'save_branch_merge_refuse');

      final runtime = await executeNarrativeEventScene(
        request: const NarrativeSceneExecutionRequest(
          eventId: 'event_branch_merge',
          sceneId: 'scene_branch_merge',
          executionId: 'execution_branch_merge_refuse',
          gameState: initial,
        ),
        project: project,
        mapsById: const <String, MapData>{},
        currentGameState: () => initial,
        callbacks: SceneRuntimeHostCallbacks(
          evaluateCondition: (_) => throw StateError('Unexpected condition'),
          showDialogue: (_) => 'refuse',
          startBattle: (_) => throw StateError('Unexpected battle'),
          playCinematic: (_) => throw StateError('Unexpected cinematic'),
        ),
      ) as NarrativeSceneExecutionCompleted;

      expect(runtime.updatedGameState.storyFlags.activeFlags,
          isNot(contains('fact_branch_reward')));
      expect(runtime.qualifiedOutcomes.single.outcomeId, 'scene.refused');
    });
  });
}

ProjectManifest _project(SceneAsset scene) {
  return ProjectManifest(
    name: 'Branch merge integration',
    maps: const <ProjectMapEntry>[],
    tilesets: const <ProjectTilesetEntry>[],
    dialogues: const [
      ProjectDialogueEntry(
        id: 'dialogue_branch',
        name: 'Branch dialogue',
        relativePath: 'dialogues/dialogue_branch.yarn',
        declaredOutcomes: [
          DialogueDeclaredOutcome(id: 'accept', label: 'Accept'),
          DialogueDeclaredOutcome(id: 'refuse', label: 'Refuse'),
        ],
      ),
    ],
    facts: [
      NarrativeFactDefinition(
        id: 'fact_branch_reward',
        label: 'Branch reward',
      ),
    ],
    scenes: [scene],
    surfaceCatalog: const ProjectSurfaceCatalog.empty(),
  );
}

SceneAsset _scene() {
  return SceneAsset(
    id: 'scene_branch_merge',
    name: 'Branch merge',
    declaredOutcomes: [
      SceneOutcome(id: 'scene.accepted', label: 'Accepted'),
      SceneOutcome(id: 'scene.refused', label: 'Refused'),
      SceneOutcome(id: 'scene.completed', label: 'Completed'),
    ],
    graph: SceneGraph(
      startNodeId: 'start',
      nodes: [
        SceneNode(id: 'start', kind: SceneNodeKind.start),
        SceneNode(
          id: 'dialogue',
          kind: SceneNodeKind.yarnDialogue,
          payload: SceneYarnDialoguePayload(
            dialogueId: 'dialogue_branch',
            expectedOutcomes: const ['accept', 'refuse'],
          ),
        ),
        SceneNode(id: 'merge_before_branch', kind: SceneNodeKind.merge),
        SceneNode(
          id: 'branch',
          kind: SceneNodeKind.branchByOutcome,
          payload: SceneBranchByOutcomePayload(sourceNodeId: 'dialogue'),
        ),
        SceneNode(
          id: 'accept_action',
          kind: SceneNodeKind.action,
          payload: SceneActionPayload.consequence(
            SceneConsequence.setFact(
              factId: 'fact_branch_reward',
              value: true,
            ),
          ),
        ),
        SceneNode(id: 'merge_after_action', kind: SceneNodeKind.merge),
        SceneNode(
          id: 'end_accept',
          kind: SceneNodeKind.end,
          payload: SceneEndPayload(sceneOutcomeId: 'scene.accepted'),
        ),
        SceneNode(
          id: 'end_refuse',
          kind: SceneNodeKind.end,
          payload: SceneEndPayload(sceneOutcomeId: 'scene.refused'),
        ),
        SceneNode(
          id: 'end_completed',
          kind: SceneNodeKind.end,
          payload: SceneEndPayload(sceneOutcomeId: 'scene.completed'),
        ),
      ],
      edges: [
        _edge('start_dialogue', 'start', 'completed', 'dialogue'),
        _edge('dialogue_accept_merge', 'dialogue', 'accept',
            'merge_before_branch', SceneEdgeKind.dialogueOutcome),
        _edge('dialogue_refuse_merge', 'dialogue', 'refuse',
            'merge_before_branch', SceneEdgeKind.dialogueOutcome),
        _edge('dialogue_completed_merge', 'dialogue', 'completed',
            'merge_before_branch'),
        _edge('merge_branch', 'merge_before_branch', 'completed', 'branch'),
        _edge('branch_accept_action', 'branch', 'accept', 'accept_action',
            SceneEdgeKind.branchOutcome),
        _edge('branch_refuse_end', 'branch', 'refuse', 'end_refuse',
            SceneEdgeKind.branchOutcome),
        _edge('branch_completed_end', 'branch', 'completed', 'end_completed',
            SceneEdgeKind.branchOutcome),
        _edge('action_merge', 'accept_action', 'completed',
            'merge_after_action', SceneEdgeKind.actionCompleted),
        _edge('merge_end', 'merge_after_action', 'completed', 'end_accept'),
      ],
    ),
  );
}

SceneEdge _edge(
  String id,
  String from,
  String port,
  String to, [
  SceneEdgeKind kind = SceneEdgeKind.defaultFlow,
]) {
  return SceneEdge(
    id: id,
    fromNodeId: from,
    fromPortId: port,
    toNodeId: to,
    kind: kind,
  );
}
```
