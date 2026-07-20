# NSC-54 — Solveur symbolique narratif corrélé — Evidence Pack

## Résumé exécutif

NSC-54 introduit un solveur pur qui conserve les Facts, Steps, Events consommés, outcomes, branches et provenance dans des états séparés. Deux choix mutuellement exclusifs ne sont donc plus fusionnés en une fausse preuve. Le résultat distingue `pass`, `fail` et `indeterminate` ; cycle, chemin sans sortie, budget dépassé et commande sans backend prouvé restent explicites. Le Validator agrège ce verdict et bloque désormais une conjonction de conditions individuellement possibles mais collectivement impossible.

**Verdict proposé : DONE.**

## Scope et audit initial

- État Git initial : branche `main`, HEAD `18db13b7 feat(narrative): add world state simulator`, arbre propre.
- Contrats inspectés : Scene graph, Event V2 expression tree, command catalog NSC-37, conséquences typées, Storyline outcome effects et reachability historique du Validator.
- Risque principal : l’ancien parcours stockait des unions de valeurs possibles et pouvait combiner des effets issus de branches incompatibles.
- Non-objectifs : aucune atteignabilité de grille ou collision n’est calculée ici ; elle appartient à NSC-56. Les diagnostics historiques sont conservés pendant la migration afin de ne pas perdre leur couverture legacy.

## Passes locales équivalentes aux sub-agents

Les sub-agents sont interdits par le mode actif ; les passes de `codex_rule.md` ont été réalisées localement et séparément.

| Passe | Verdict |
|---|---|
| Audit / Architecture | PASS — solveur, états et verdicts restent purs dans map_core. |
| Implémentation | PASS — chaque branche possède un état/provenance, les états équivalents convergent par clé sémantique. |
| Tests | PASS — 45 tests ciblés Validator/solveur/adapter sont verts. |
| Build / Validation | PASS — `dart analyze` ne remonte aucune issue. |
| Critique finale | PASS — optionalité, budget et backends inconnus échouent de façon conservative sans faux pass. |

## Inventaire complet des fichiers modifiés

| Fichier | Zone précise et impact |
|---|---|
| `packages/map_core/lib/map_core.dart` | Export public du solveur symbolique. |
| `packages/map_core/lib/src/operations/narrative_symbolic_reachability_solver.dart` | États corrélés, BFS borné, provenance, convergence, Event expressions et verdicts. |
| `packages/map_core/lib/src/operations/narrative_project_validator.dart` | Rapport enrichi par `narrativelySolvable`, diagnostics corrélés et gate anti-conjonction impossible. |
| `packages/map_core/lib/src/authoring/narrative_validator_authoring_adapter.dart` | Vue auteur des issues symboliques et de leur provenance, sans quick-fix inventé. |
| `packages/map_core/test/narrative_symbolic_reachability_solver_test.dart` | Branches exclusives, convergence, cycle, no-exit, budget, commande inconnue, quête optionnelle et intégration Validator. |
| `packages/map_core/test/narrative_validator_authoring_adapter_test.dart` | Mapping d’une indétermination symbolique avec provenance. |
| `docs/superpowers/plans/2026-07-20-nsc-54-symbolic-reachability.md` | Micro-plan TDD et gate. |
| `reports/narrativeStudio/completion/nsc_54_symbolic_reachability_evidence_pack.md` | Présent rapport. |

## Décisions et zones précises

- La clé sémantique inclut valeurs de Facts typés, Steps terminés, Events consommés, outcomes émis, Events déjà explorés et statut indéterminé.
- Les choix Dialogue, Condition, Battle et Branch-by-outcome engendrent des états distincts ; une convergence ne fusionne que des états réellement identiques.
- Les conséquences Fact/Step/Event sont appliquées au chemin courant uniquement.
- Les expressions Event `all/any/not` sont évaluées contre chaque état corrélé.
- Toute condition non modélisée et toute commande sans descriptor/backend publiable produisent `indeterminate`, jamais `pass`.
- Les issues d’une Side Quest active restent visibles mais ne changent pas le verdict du parcours obligatoire.
- Le Validator conserve les diagnostics legacy, ajoute le rapport symbolique et émet une erreur dédiée lorsque des Facts ne sont jamais vrais ensemble.

## Tests et preuves

- Branches exclusives : A possible, B possible, A+B impossible.
- Convergence : deux branches qui produisent le même état convergent en un terminal.
- Réfutations : cycle et chemin sans sortie.
- Indéterminations : budget dépassé et action legacy sans backend.
- Optionalité : Side Quest active cassée visible mais non bloquante.
- Validator : diagnostic `narrativeMutuallyExclusiveRequirements` et verdict `fail`.
- Adapter : titre, chemin et provenance, sans réparation automatique.

## Commandes et résultats exacts

```text
cd packages/map_core
/opt/homebrew/bin/dart test test/narrative_symbolic_reachability_solver_test.dart test/narrative_project_validator_test.dart test/narrative_validator_authoring_adapter_test.dart
All tests passed! (+45)

/opt/homebrew/bin/dart analyze
No issues found!

git diff --check
aucune sortie
```

Le test initial a échoué en phase rouge avec les symboles du solveur absents. Deux erreurs exhaustives de compilation (import du backend puis nouveaux variants StorylineEffect) ont été corrigées avant le premier passage vert.

## État Git final avant commit

- Seuls les fichiers NSC-54 listés ci-dessus sont modifiés ou créés.
- Aucun artefact généré ou fichier hors scope n’est inclus.
- `git diff --check` est propre.

## Limites conservées et risques

- Le solveur explore les Events V2 et le starter New Game ; la reachability des Map Events legacy reste couverte par les diagnostics historiques pendant cette phase de migration.
- Les commandes inventaire/récompense sont considérées comme transitions supportées mais leur état métier n’entre pas encore dans la clé symbolique.
- Une source d’outcome Battle/legacy extérieure à une Scene est indéterminée tant qu’aucun contrat de preuve ne la fournit.
- Le budget par défaut est borné ; les projets trop combinatoires obtiennent honnêtement `indeterminate`.

## Auto-critique

L’algorithme privilégie la sûreté : il peut produire une indétermination là où une analyse spécialisée future prouverait un chemin. C’est volontairement préférable à un faux succès. La coexistence temporaire avec le solveur historique augmente la surface de code, mais le verdict corrélé est déjà attaché au rapport et bloque les faux positifs ciblés ; NSC-57 deviendra l’unique agrégateur multidimensionnel.

## Prochaine étape

NSC-55 — terminalité, défaite et politique de retry explicite, sans heuristique de label.

## Contenu complet des fichiers créés

Le présent rapport ne peut pas s’inclure récursivement ; tous les autres fichiers créés sont reproduits ci-dessous.

<details>
<summary>Contenu complet — docs/superpowers/plans/2026-07-20-nsc-54-symbolic-reachability.md</summary>

```markdown
# NSC-54 — Solveur symbolique narratif corrélé

## Objectif

Produire une preuve conservative de solvabilité qui garde chaque branche dans un état distinct et ne transforme jamais une feature inconnue ou un budget dépassé en succès.

## Frontières

- Le solveur est pur et vit dans `map_core`.
- Les Facts, Steps, Events consommés, outcomes et événements exécutés composent la clé d’état.
- Une branche Dialogue, Condition, Battle ou Outcome conserve sa provenance.
- Une commande sans descriptor/backend publiable produit `indeterminate`.
- Une quête secondaire active peut échouer sans bloquer le parcours obligatoire, mais son issue reste visible.
- Les diagnostics historiques restent présents pendant la migration ; le verdict corrélé devient un gate supplémentaire du Validator.

## Plan TDD

1. Prouver que deux branches exclusives ne satisfont pas artificiellement A et B.
2. Prouver la convergence d’états identiques.
3. Tester cycle, chemin sans sortie, budget et commande inconnue.
4. Tester une quête secondaire active non bloquante.
5. Explorer les Events V2 et leurs expressions avec état/provenance.
6. Exposer pass/fail/indeterminate dans le rapport projet.
7. Adapter les diagnostics auteur et exécuter le gate core.

## Gate

Le Validator refuse une conjonction impossible, expose un résultat reproductible et distingue explicitement preuve, réfutation et indétermination.
```
</details>
<details>
<summary>Contenu complet — packages/map_core/lib/src/operations/narrative_symbolic_reachability_solver.dart</summary>

```dart
import 'package:meta/meta.dart' show immutable;

import '../models/map_data.dart';
import '../models/narrative_event_definition.dart';
import '../models/narrative_event_source_ref.dart';
import '../models/narrative_command_descriptor.dart';
import '../models/narrative_value.dart';
import '../models/project_manifest.dart';
import '../models/scene_asset.dart';
import '../models/scene_consequence.dart';
import '../models/storyline_asset.dart';
import '../read_models/narrative_command_catalog.dart';

enum NarrativeSymbolicVerdict { pass, fail, indeterminate }

enum NarrativeSymbolicIssueCode {
  cycleDetected,
  pathWithoutExit,
  budgetExceeded,
  unsupportedCondition,
  unsupportedCommand,
  mutuallyExclusiveRequirements,
}

@immutable
final class NarrativeSymbolicProvenance {
  const NarrativeSymbolicProvenance({
    required this.sceneId,
    required this.nodeId,
    required this.description,
    this.eventId,
  });

  final String sceneId;
  final String nodeId;
  final String? eventId;
  final String description;
}

@immutable
final class NarrativeSymbolicIssue {
  NarrativeSymbolicIssue({
    required this.code,
    required this.verdict,
    required this.message,
    required this.sceneId,
    this.nodeId,
    this.eventId,
    this.optional = false,
    List<NarrativeSymbolicProvenance> provenance =
        const <NarrativeSymbolicProvenance>[],
  }) : provenance = List.unmodifiable(provenance);

  final NarrativeSymbolicIssueCode code;
  final NarrativeSymbolicVerdict verdict;
  final String message;
  final String sceneId;
  final String? nodeId;
  final String? eventId;
  final bool optional;
  final List<NarrativeSymbolicProvenance> provenance;
}

@immutable
final class NarrativeSymbolicState {
  NarrativeSymbolicState({
    Map<String, NarrativeValue> factValues = const <String, NarrativeValue>{},
    Set<String> completedStepIds = const <String>{},
    Set<String> consumedEventIds = const <String>{},
    Set<String> emittedOutcomeKeys = const <String>{},
    Set<String> executedEventIds = const <String>{},
    List<NarrativeSymbolicProvenance> provenance =
        const <NarrativeSymbolicProvenance>[],
    this.indeterminate = false,
  })  : factValues = Map.unmodifiable(factValues),
        completedStepIds = Set.unmodifiable(completedStepIds),
        consumedEventIds = Set.unmodifiable(consumedEventIds),
        emittedOutcomeKeys = Set.unmodifiable(emittedOutcomeKeys),
        executedEventIds = Set.unmodifiable(executedEventIds),
        provenance = List.unmodifiable(provenance);

  final Map<String, NarrativeValue> factValues;
  final Set<String> completedStepIds;
  final Set<String> consumedEventIds;
  final Set<String> emittedOutcomeKeys;
  final Set<String> executedEventIds;
  final List<NarrativeSymbolicProvenance> provenance;
  final bool indeterminate;

  NarrativeSymbolicState copyWith({
    Map<String, NarrativeValue>? factValues,
    Set<String>? completedStepIds,
    Set<String>? consumedEventIds,
    Set<String>? emittedOutcomeKeys,
    Set<String>? executedEventIds,
    List<NarrativeSymbolicProvenance>? provenance,
    bool? indeterminate,
  }) =>
      NarrativeSymbolicState(
        factValues: factValues ?? this.factValues,
        completedStepIds: completedStepIds ?? this.completedStepIds,
        consumedEventIds: consumedEventIds ?? this.consumedEventIds,
        emittedOutcomeKeys: emittedOutcomeKeys ?? this.emittedOutcomeKeys,
        executedEventIds: executedEventIds ?? this.executedEventIds,
        provenance: provenance ?? this.provenance,
        indeterminate: indeterminate ?? this.indeterminate,
      );

  bool hasTrueFact(String factId) {
    final value = factValues[factId];
    return value?.kind == NarrativeValueKind.boolean && value!.boolValue;
  }

  String get semanticKey {
    final facts = factValues.entries.toList()
      ..sort((left, right) => left.key.compareTo(right.key));
    return <String>[
      for (final entry in facts)
        '${entry.key}=${entry.value.kind.wireName}:${entry.value.toJson()}',
      'steps=${_sorted(completedStepIds).join(',')}',
      'consumed=${_sorted(consumedEventIds).join(',')}',
      'outcomes=${_sorted(emittedOutcomeKeys).join(',')}',
      'executed=${_sorted(executedEventIds).join(',')}',
      'indeterminate=$indeterminate',
    ].join('|');
  }
}

@immutable
final class NarrativeSymbolicReachabilityReport {
  NarrativeSymbolicReachabilityReport({
    required this.verdict,
    required List<NarrativeSymbolicState> terminalStates,
    required List<NarrativeSymbolicState> exploredStates,
    required List<NarrativeSymbolicIssue> issues,
    required Set<String> reachableSceneIds,
    required this.exploredStateCount,
  })  : terminalStates = List.unmodifiable(terminalStates),
        exploredStates = List.unmodifiable(exploredStates),
        issues = List.unmodifiable(issues),
        reachableSceneIds = Set.unmodifiable(reachableSceneIds);

  final NarrativeSymbolicVerdict verdict;
  final List<NarrativeSymbolicState> terminalStates;
  final List<NarrativeSymbolicState> exploredStates;
  final List<NarrativeSymbolicIssue> issues;
  final Set<String> reachableSceneIds;
  final int exploredStateCount;

  bool canSatisfyAllTrueFacts(Set<String> factIds) => terminalStates.any(
        (state) => factIds.every(state.hasTrueFact),
      );

  Set<String> get trueFactIds => {
        for (final state in [...exploredStates, ...terminalStates])
          for (final entry in state.factValues.entries)
            if (entry.value.kind == NarrativeValueKind.boolean &&
                entry.value.boolValue)
              entry.key,
      };

  Set<String> get completedStepIds => {
        for (final state in [...exploredStates, ...terminalStates])
          ...state.completedStepIds,
      };
}

NarrativeSymbolicReachabilityReport solveNarrativeSceneSymbolically(
  SceneAsset scene, {
  NarrativeSymbolicState? initialState,
  int explorationBudget = 4096,
  NarrativeCommandCatalog? commandCatalog,
  String? eventId,
}) {
  if (explorationBudget < 1) {
    throw ArgumentError.value(
      explorationBudget,
      'explorationBudget',
      'must be positive',
    );
  }
  final nodesById = {for (final node in scene.graph.nodes) node.id: node};
  final outgoing = <String, List<SceneEdge>>{};
  for (final edge in scene.graph.edges) {
    outgoing.putIfAbsent(edge.fromNodeId, () => <SceneEdge>[]).add(edge);
  }
  for (final edges in outgoing.values) {
    edges.sort((left, right) => left.id.compareTo(right.id));
  }
  final catalog = commandCatalog ?? NarrativeCommandCatalog.canonical();
  final startState = initialState ?? NarrativeSymbolicState();
  final pending = <_SceneCursor>[
    _SceneCursor(
      nodeId: scene.graph.startNodeId,
      state: startState,
      pathKeys: const <String>{},
    ),
  ];
  final seen = <String>{};
  final terminals = <NarrativeSymbolicState>[];
  final explored = <NarrativeSymbolicState>[];
  final issues = <NarrativeSymbolicIssue>[];
  final issueKeys = <String>{};
  var exploredCount = 0;

  void addIssue(NarrativeSymbolicIssue issue) {
    final key = '${issue.code.name}|${issue.sceneId}|${issue.nodeId}|'
        '${issue.eventId}|${issue.verdict.name}';
    if (issueKeys.add(key)) issues.add(issue);
  }

  while (pending.isNotEmpty) {
    if (exploredCount >= explorationBudget) {
      final cursor = pending.last;
      addIssue(
        NarrativeSymbolicIssue(
          code: NarrativeSymbolicIssueCode.budgetExceeded,
          verdict: NarrativeSymbolicVerdict.indeterminate,
          message:
              'Le budget symbolique de $explorationBudget états est dépassé.',
          sceneId: scene.id,
          nodeId: cursor.nodeId,
          eventId: eventId,
          provenance: cursor.state.provenance,
        ),
      );
      break;
    }
    final cursor = pending.removeLast();
    final stateKey = '${cursor.nodeId}|${cursor.state.semanticKey}';
    if (cursor.pathKeys.contains(stateKey)) {
      addIssue(
        NarrativeSymbolicIssue(
          code: NarrativeSymbolicIssueCode.cycleDetected,
          verdict: NarrativeSymbolicVerdict.fail,
          message: 'Un cycle ne rejoint aucun nœud de fin prouvé.',
          sceneId: scene.id,
          nodeId: cursor.nodeId,
          eventId: eventId,
          provenance: cursor.state.provenance,
        ),
      );
      continue;
    }
    if (!seen.add(stateKey)) continue;
    exploredCount++;
    explored.add(cursor.state);
    final node = nodesById[cursor.nodeId];
    if (node == null) {
      addIssue(
        NarrativeSymbolicIssue(
          code: NarrativeSymbolicIssueCode.pathWithoutExit,
          verdict: NarrativeSymbolicVerdict.fail,
          message: 'Le chemin référence un nœud absent.',
          sceneId: scene.id,
          nodeId: cursor.nodeId,
          eventId: eventId,
          provenance: cursor.state.provenance,
        ),
      );
      continue;
    }

    var nextState = cursor.state;
    if (node.payload case final SceneActionPayload payload) {
      nextState = _applyAction(
        state: nextState,
        scene: scene,
        node: node,
        payload: payload,
        catalog: catalog,
        eventId: eventId,
        addIssue: addIssue,
      );
    }
    if (node.payload case SceneEndPayload(:final sceneOutcomeId)) {
      final outcomeState = sceneOutcomeId == null
          ? nextState
          : nextState.copyWith(
              emittedOutcomeKeys: {
                ...nextState.emittedOutcomeKeys,
                _outcomeKey(scene.id, sceneOutcomeId),
              },
              provenance: [
                ...nextState.provenance,
                NarrativeSymbolicProvenance(
                  sceneId: scene.id,
                  nodeId: node.id,
                  eventId: eventId,
                  description: 'Outcome émis : $sceneOutcomeId.',
                ),
              ],
            );
      _addUniqueState(terminals, outcomeState);
      continue;
    }

    final edges = _traversableEdges(
      node,
      outgoing[node.id] ?? const <SceneEdge>[],
      nextState,
      onIndeterminateCondition: (message) {
        nextState = nextState.copyWith(indeterminate: true);
        addIssue(
          NarrativeSymbolicIssue(
            code: NarrativeSymbolicIssueCode.unsupportedCondition,
            verdict: NarrativeSymbolicVerdict.indeterminate,
            message: message,
            sceneId: scene.id,
            nodeId: node.id,
            eventId: eventId,
            provenance: nextState.provenance,
          ),
        );
      },
    );
    if (edges.isEmpty) {
      addIssue(
        NarrativeSymbolicIssue(
          code: NarrativeSymbolicIssueCode.pathWithoutExit,
          verdict: NarrativeSymbolicVerdict.fail,
          message: 'Le chemin atteint « ${node.id} » sans sortie terminale.',
          sceneId: scene.id,
          nodeId: node.id,
          eventId: eventId,
          provenance: nextState.provenance,
        ),
      );
      continue;
    }
    final nextPath = {...cursor.pathKeys, stateKey};
    for (final edge in edges.reversed) {
      final branched = nextState.copyWith(
        provenance: [
          ...nextState.provenance,
          NarrativeSymbolicProvenance(
            sceneId: scene.id,
            nodeId: node.id,
            eventId: eventId,
            description: _edgeProvenance(node, edge),
          ),
        ],
      );
      pending.add(
        _SceneCursor(
          nodeId: edge.toNodeId,
          state: branched,
          pathKeys: nextPath,
        ),
      );
    }
  }

  return NarrativeSymbolicReachabilityReport(
    verdict: _verdict(issues, terminals),
    terminalStates: terminals,
    exploredStates: explored,
    issues: issues,
    reachableSceneIds: {scene.id},
    exploredStateCount: exploredCount,
  );
}

NarrativeSymbolicReachabilityReport solveNarrativeSymbolicReachability(
  ProjectManifest project, {
  required List<MapData> maps,
  int explorationBudget = 16384,
  NarrativeCommandCatalog? commandCatalog,
}) {
  if (explorationBudget < 1) {
    throw ArgumentError.value(
      explorationBudget,
      'explorationBudget',
      'must be positive',
    );
  }
  final initialFacts = <String, NarrativeValue>{
    for (final fact in project.facts) fact.id: fact.initialValue,
    ...project.newGame.resolvedInitialFactValues,
  };
  final initial = NarrativeSymbolicState(factValues: initialFacts);
  final scenesById = {for (final scene in project.scenes) scene.id: scene};
  final mapsById = {for (final map in maps) map.id: map};
  final catalog = commandCatalog ?? NarrativeCommandCatalog.canonical();
  final issues = <NarrativeSymbolicIssue>[];
  final explored = <NarrativeSymbolicState>[];
  final terminals = <NarrativeSymbolicState>[];
  final reachableSceneIds = <String>{};
  var exploredCount = 0;
  var remainingBudget = explorationBudget;

  List<NarrativeSymbolicState> frontier = [initial];
  final starterSceneId = project.newGame.starterSelectionSceneId;
  if (starterSceneId != null && scenesById.containsKey(starterSceneId)) {
    final result = solveNarrativeSceneSymbolically(
      scenesById[starterSceneId]!,
      initialState: initial,
      explorationBudget: remainingBudget,
      commandCatalog: catalog,
      eventId: 'newGame.starterSelectionSceneId',
    );
    exploredCount += result.exploredStateCount;
    remainingBudget -= result.exploredStateCount;
    explored.addAll(result.exploredStates);
    issues.addAll(result.issues);
    reachableSceneIds.add(starterSceneId);
    frontier = result.terminalStates;
  }

  final definitions = <NarrativeEventDefinition>[
    for (final record
        in project.eventRegistry?.records ?? const <NarrativeEventRecord>[])
      if (record.enabledOrNull == true && record.definitionOrNull != null)
        record.definitionOrNull!,
  ]..sort((left, right) {
      final priority = right.priority.compareTo(left.priority);
      return priority != 0 ? priority : left.order.compareTo(right.order);
    });
  final seen = <String>{};
  var progress = true;
  while (progress && frontier.isNotEmpty) {
    progress = false;
    final nextFrontier = <NarrativeSymbolicState>[];
    for (final state in frontier) {
      final stateKey = state.semanticKey;
      if (!seen.add(stateKey)) {
        _addUniqueState(nextFrontier, state);
        continue;
      }
      if (remainingBudget < 1) {
        issues.add(
          NarrativeSymbolicIssue(
            code: NarrativeSymbolicIssueCode.budgetExceeded,
            verdict: NarrativeSymbolicVerdict.indeterminate,
            message:
                'Le budget symbolique global de $explorationBudget états est dépassé.',
            sceneId: '',
            provenance: state.provenance,
          ),
        );
        _addUniqueState(nextFrontier, state.copyWith(indeterminate: true));
        continue;
      }
      final candidates = <NarrativeEventDefinition>[];
      for (final definition in definitions) {
        if (state.executedEventIds.contains(definition.id)) continue;
        final scene = scenesById[definition.sceneId];
        if (scene == null || _isDisabledOptionalScene(project, scene)) continue;
        final source = _sourceEligibility(
          definition.source,
          state,
          mapsById,
        );
        final conditions = _eventExpressionValue(
          definition.conditionExpression,
          state,
        );
        if (source == false || conditions == false) continue;
        if (source == null || conditions == null) {
          issues.add(
            NarrativeSymbolicIssue(
              code: NarrativeSymbolicIssueCode.unsupportedCondition,
              verdict: NarrativeSymbolicVerdict.indeterminate,
              message:
                  'L’éligibilité de l’Event ${definition.id} dépend d’une feature non prouvée.',
              sceneId: definition.sceneId,
              eventId: definition.id,
              provenance: state.provenance,
            ),
          );
        }
        candidates.add(definition);
      }
      if (candidates.isEmpty) {
        _addUniqueState(nextFrontier, state);
        continue;
      }
      progress = true;
      for (final definition in candidates) {
        final scene = scenesById[definition.sceneId]!;
        var eventState = state.copyWith(
          executedEventIds: {...state.executedEventIds, definition.id},
          consumedEventIds:
              definition.reusePolicy == NarrativeEventReusePolicy.oneShot
                  ? {...state.consumedEventIds, definition.id}
                  : state.consumedEventIds,
        );
        final source = _sourceEligibility(
          definition.source,
          state,
          mapsById,
        );
        final conditions = _eventExpressionValue(
          definition.conditionExpression,
          state,
        );
        if (source == null || conditions == null) {
          eventState = eventState.copyWith(indeterminate: true);
        }
        final result = solveNarrativeSceneSymbolically(
          scene,
          initialState: eventState,
          explorationBudget: remainingBudget,
          commandCatalog: catalog,
          eventId: definition.id,
        );
        exploredCount += result.exploredStateCount;
        remainingBudget -= result.exploredStateCount;
        explored.addAll(result.exploredStates);
        reachableSceneIds.add(scene.id);
        final optional = _isOptionalScene(project, scene);
        issues.addAll([
          for (final issue in result.issues)
            NarrativeSymbolicIssue(
              code: issue.code,
              verdict: issue.verdict,
              message: issue.message,
              sceneId: issue.sceneId,
              nodeId: issue.nodeId,
              eventId: issue.eventId,
              optional: optional,
              provenance: issue.provenance,
            ),
        ]);
        if (result.terminalStates.isEmpty && optional) {
          _addUniqueState(nextFrontier, eventState);
        }
        for (final terminal in result.terminalStates) {
          _addUniqueState(
            nextFrontier,
            _applyStorylineOutcomeEffects(project, terminal),
          );
        }
      }
    }
    frontier = nextFrontier;
  }
  terminals.addAll(frontier);

  for (final definition in definitions) {
    final requiredTrueFacts = <String>{};
    for (final condition in definition.conditions) {
      condition.whenTyped(
        fact: (factId, operator, expectedValue) {
          if (operator == NarrativeFactOperator.equals &&
              expectedValue.kind == NarrativeValueKind.boolean &&
              expectedValue.boolValue) {
            requiredTrueFacts.add(factId);
          }
        },
        narrativeEventConsumed: (_, __) {},
      );
    }
    if (requiredTrueFacts.length < 2) continue;
    final states = [...explored, ...terminals];
    final individuallyPossible = requiredTrueFacts.every(
      (factId) => states.any((state) => state.hasTrueFact(factId)),
    );
    final jointlyPossible = states.any(
      (state) => requiredTrueFacts.every(state.hasTrueFact),
    );
    if (individuallyPossible && !jointlyPossible) {
      issues.add(
        NarrativeSymbolicIssue(
          code: NarrativeSymbolicIssueCode.mutuallyExclusiveRequirements,
          verdict: NarrativeSymbolicVerdict.fail,
          message:
              'L’Event ${definition.id} exige des Facts possibles séparément mais jamais ensemble.',
          sceneId: definition.sceneId,
          eventId: definition.id,
        ),
      );
    }
  }

  return NarrativeSymbolicReachabilityReport(
    verdict: _verdict(
      issues.where((issue) => !issue.optional).toList(growable: false),
      terminals,
    ),
    terminalStates: terminals,
    exploredStates: explored,
    issues: _deduplicateIssues(issues),
    reachableSceneIds: reachableSceneIds,
    exploredStateCount: exploredCount,
  );
}

NarrativeSymbolicState _applyAction({
  required NarrativeSymbolicState state,
  required SceneAsset scene,
  required SceneNode node,
  required SceneActionPayload payload,
  required NarrativeCommandCatalog catalog,
  required String? eventId,
  required void Function(NarrativeSymbolicIssue) addIssue,
}) {
  var next = state;
  final consequence = payload.consequence;
  if (consequence != null) {
    switch (consequence) {
      case SceneSetFactConsequence(:final factId, :final narrativeValue):
        next = next.copyWith(
          factValues: {...next.factValues, factId: narrativeValue},
        );
      case SceneCompleteStoryStepConsequence(:final stepId):
        next = next.copyWith(
          completedStepIds: {...next.completedStepIds, stepId},
        );
      case SceneMarkEventConsumedConsequence(:final eventId):
        next = next.copyWith(
          consumedEventIds: {...next.consumedEventIds, eventId},
        );
      case SceneGiveItemConsequence():
      case SceneTakeItemConsequence():
      case SceneGiveMoneyConsequence():
      case SceneGivePokemonConsequence():
      case SceneGiveConfiguredStarterConsequence():
        break;
    }
  }

  final interactive = payload.interactiveCommand;
  final commandId = interactive?.kind.name ?? payload.actionKind;
  if (interactive == null && consequence == null || interactive != null) {
    final descriptor = commandId == null ? null : catalog.byId(commandId);
    final expectedBackend = interactive == null
        ? null
        : NarrativeCommandBackend.interactiveRuntimeCommand;
    if (descriptor == null ||
        !descriptor.isPublishable ||
        expectedBackend != null && descriptor.backend != expectedBackend) {
      final marked = next.copyWith(indeterminate: true);
      addIssue(
        NarrativeSymbolicIssue(
          code: NarrativeSymbolicIssueCode.unsupportedCommand,
          verdict: NarrativeSymbolicVerdict.indeterminate,
          message:
              'La commande « ${commandId ?? 'inconnue'} » ne possède pas de backend publiable prouvé.',
          sceneId: scene.id,
          nodeId: node.id,
          eventId: eventId,
          provenance: marked.provenance,
        ),
      );
      next = marked;
    }
  }
  return next;
}

List<SceneEdge> _traversableEdges(
  SceneNode node,
  List<SceneEdge> edges,
  NarrativeSymbolicState state, {
  required void Function(String message) onIndeterminateCondition,
}) {
  switch (node.kind) {
    case SceneNodeKind.end:
      return const [];
    case SceneNodeKind.start:
    case SceneNodeKind.merge:
      return edges
          .where((edge) =>
              edge.fromPortId == 'completed' &&
              edge.kind == SceneEdgeKind.defaultFlow)
          .toList(growable: false);
    case SceneNodeKind.action:
      return edges
          .where((edge) =>
              edge.kind == SceneEdgeKind.defaultFlow ||
              edge.kind == SceneEdgeKind.actionCompleted ||
              edge.kind == SceneEdgeKind.blocked)
          .toList(growable: false);
    case SceneNodeKind.cinematic:
      return edges
          .where((edge) =>
              edge.fromPortId == 'completed' &&
              edge.kind == SceneEdgeKind.cinematicCompleted)
          .toList(growable: false);
    case SceneNodeKind.battle:
      return edges
          .where((edge) =>
              edge.kind == SceneEdgeKind.battleVictory ||
              edge.kind == SceneEdgeKind.battleDefeat)
          .toList(growable: false);
    case SceneNodeKind.yarnDialogue:
      final payload = node.payload as SceneYarnDialoguePayload;
      return edges
          .where((edge) =>
              edge.fromPortId == 'completed' ||
              payload.expectedOutcomes.contains(edge.fromPortId))
          .toList(growable: false);
    case SceneNodeKind.branchByOutcome:
      return edges
          .where((edge) => edge.kind == SceneEdgeKind.branchOutcome)
          .toList(growable: false);
    case SceneNodeKind.condition:
      final source = (node.payload as SceneConditionPayload).conditionSource;
      final value = _sceneConditionValue(source, state);
      if (value == null) {
        onIndeterminateCondition(
          'La condition de Scene « ${node.id} » n’est pas prouvée par le solveur.',
        );
      }
      return edges
          .where((edge) =>
              value != false && edge.kind == SceneEdgeKind.conditionTrue ||
              value != true && edge.kind == SceneEdgeKind.conditionFalse)
          .toList(growable: false);
  }
}

bool? _sceneConditionValue(
  SceneConditionSource? source,
  NarrativeSymbolicState state,
) {
  if (source == null) return null;
  switch (source.sourceKind) {
    case SceneConditionSourceKind.fact:
    case SceneConditionSourceKind.factLikeStoryFlag:
      final actual = state.factValues[source.sourceId];
      if (actual == null) return null;
      try {
        return actual.matches(
          source.resolvedFactOperator,
          source.resolvedExpectedFactValue,
        );
      } on Object {
        return null;
      }
    case SceneConditionSourceKind.storyStepCompletion:
      final completed = state.completedStepIds.contains(source.sourceId);
      return _boolConditionValue(source, completed);
    case SceneConditionSourceKind.consumedEvent:
      final consumed = state.consumedEventIds.contains(source.sourceId);
      return _boolConditionValue(source, consumed);
    case SceneConditionSourceKind.storyStepActive:
    case SceneConditionSourceKind.inventoryItem:
    case SceneConditionSourceKind.partyState:
    case SceneConditionSourceKind.trainerDefeated:
    case SceneConditionSourceKind.dialogueOutcome:
    case SceneConditionSourceKind.battleOutcome:
    case SceneConditionSourceKind.scriptVariable:
    case SceneConditionSourceKind.worldState:
      return null;
  }
}

bool? _boolConditionValue(SceneConditionSource source, bool actual) =>
    switch (source.operator) {
      SceneConditionOperator.isTrue => actual,
      SceneConditionOperator.isFalse => !actual,
      SceneConditionOperator.equals => switch (source.value) {
          'true' || SceneConditionValues.completed => actual,
          'false' || SceneConditionValues.notCompleted => !actual,
          _ => null,
        },
    };

bool? _eventExpressionValue(
  NarrativeEventConditionExpression expression,
  NarrativeSymbolicState state,
) {
  switch (expression) {
    case NarrativeEventConditionLeaf(:final condition):
      return condition.whenTyped(
        fact: (factId, operator, expectedValue) {
          final actual = state.factValues[factId];
          if (actual == null) return null;
          try {
            return actual.matches(operator, expectedValue);
          } on Object {
            return null;
          }
        },
        narrativeEventConsumed: (eventId, expectedValue) =>
            state.consumedEventIds.contains(eventId) == expectedValue,
      );
    case NarrativeEventConditionAll(:final children):
      final values = [
        for (final child in children) _eventExpressionValue(child, state),
      ];
      if (values.contains(false)) return false;
      return values.contains(null) ? null : true;
    case NarrativeEventConditionAny(:final children):
      final values = [
        for (final child in children) _eventExpressionValue(child, state),
      ];
      if (values.contains(true)) return true;
      return values.contains(null) ? null : false;
    case NarrativeEventConditionNot(:final child):
      final value = _eventExpressionValue(child, state);
      return value == null ? null : !value;
  }
}

bool? _sourceEligibility(
  NarrativeEventSourceRef source,
  NarrativeSymbolicState state,
  Map<String, MapData> mapsById,
) =>
    source.when(
      entityInteract: (mapId, entityId) =>
          mapsById[mapId]?.entities.any((entity) => entity.id == entityId) ==
          true,
      triggerEnter: (mapId, triggerId) =>
          mapsById[mapId]?.triggers.any((trigger) => trigger.id == triggerId) ==
          true,
      mapEnter: mapsById.containsKey,
      outcomeReceived: (outcome) {
        if (outcome.producerKind != NarrativeOutcomeProducerKind.scene) {
          return null;
        }
        return state.emittedOutcomeKeys.contains(
          _outcomeKey(outcome.producerId, outcome.outcomeId),
        );
      },
    );

NarrativeSymbolicState _applyStorylineOutcomeEffects(
  ProjectManifest project,
  NarrativeSymbolicState state,
) {
  var next = state;
  for (final storyline in project.storylines) {
    for (final link in storyline.sceneLinks) {
      final sceneId = link.sceneRef?.targetId;
      if (sceneId == null) continue;
      for (final outcome in link.outcomeLinks) {
        if (!state.emittedOutcomeKeys.contains(
          _outcomeKey(sceneId, outcome.outcomeId),
        )) {
          continue;
        }
        for (final effect in outcome.effects) {
          switch (effect.type) {
            case StorylineEffectType.activateStep:
            case StorylineEffectType.unlockStoryline:
            case StorylineEffectType.setWorldRule:
            case StorylineEffectType.affectRelationship:
              break;
            case StorylineEffectType.completeStep:
              next = next.copyWith(
                completedStepIds: {...next.completedStepIds, effect.targetId},
              );
            case StorylineEffectType.emitFact:
              next = next.copyWith(
                factValues: {
                  ...next.factValues,
                  effect.targetId: NarrativeValue.boolean(
                    effect.value?.trim().toLowerCase() != 'false',
                  ),
                },
              );
          }
        }
      }
    }
  }
  return next;
}

bool _isOptionalScene(ProjectManifest project, SceneAsset scene) {
  final storyline = project.storylines
      .where((storyline) => storyline.id == scene.storylineId)
      .firstOrNull;
  return storyline?.type == StorylineType.sideQuest;
}

bool _isDisabledOptionalScene(ProjectManifest project, SceneAsset scene) {
  final storyline = project.storylines
      .where((storyline) => storyline.id == scene.storylineId)
      .firstOrNull;
  return storyline?.type == StorylineType.sideQuest &&
      (storyline?.status == StorylineStatus.disabled ||
          storyline?.status == StorylineStatus.archived);
}

NarrativeSymbolicVerdict _verdict(
  List<NarrativeSymbolicIssue> issues,
  List<NarrativeSymbolicState> terminals,
) {
  if (issues.any(
    (issue) => issue.verdict == NarrativeSymbolicVerdict.indeterminate,
  )) {
    return NarrativeSymbolicVerdict.indeterminate;
  }
  if (issues.any((issue) => issue.verdict == NarrativeSymbolicVerdict.fail) ||
      terminals.isEmpty) {
    return NarrativeSymbolicVerdict.fail;
  }
  return NarrativeSymbolicVerdict.pass;
}

String _edgeProvenance(SceneNode node, SceneEdge edge) {
  final isExclusive = node.kind == SceneNodeKind.condition ||
      node.kind == SceneNodeKind.yarnDialogue ||
      node.kind == SceneNodeKind.battle ||
      node.kind == SceneNodeKind.branchByOutcome;
  return '${isExclusive ? 'Branche exclusive' : 'Transition'} '
      '${edge.fromPortId} → ${edge.toNodeId}.';
}

void _addUniqueState(
  List<NarrativeSymbolicState> target,
  NarrativeSymbolicState state,
) {
  if (!target.any((candidate) => candidate.semanticKey == state.semanticKey)) {
    target.add(state);
  }
}

List<NarrativeSymbolicIssue> _deduplicateIssues(
  List<NarrativeSymbolicIssue> issues,
) {
  final seen = <String>{};
  return [
    for (final issue in issues)
      if (seen.add(
        '${issue.code.name}|${issue.sceneId}|${issue.nodeId}|'
        '${issue.eventId}|${issue.optional}',
      ))
        issue,
  ];
}

String _outcomeKey(String sceneId, String outcomeId) =>
    '$sceneId\u001f$outcomeId';

List<String> _sorted(Set<String> values) => values.toList()..sort();

final class _SceneCursor {
  const _SceneCursor({
    required this.nodeId,
    required this.state,
    required this.pathKeys,
  });

  final String nodeId;
  final NarrativeSymbolicState state;
  final Set<String> pathKeys;
}
```
</details>
<details>
<summary>Contenu complet — packages/map_core/test/narrative_symbolic_reachability_solver_test.dart</summary>

```dart
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('Narrative symbolic reachability solver', () {
    test('keeps mutually exclusive branches correlated', () {
      final report = solveNarrativeSceneSymbolically(
        _choiceScene(
          leftConsequence: SceneConsequence.setFact(
            factId: 'fact_a',
            value: true,
          ),
          rightConsequence: SceneConsequence.setFact(
            factId: 'fact_b',
            value: true,
          ),
        ),
      );

      expect(report.verdict, NarrativeSymbolicVerdict.pass);
      expect(report.terminalStates, hasLength(2));
      expect(report.canSatisfyAllTrueFacts({'fact_a'}), isTrue);
      expect(report.canSatisfyAllTrueFacts({'fact_b'}), isTrue);
      expect(report.canSatisfyAllTrueFacts({'fact_a', 'fact_b'}), isFalse);
      expect(
        report.terminalStates.every(
          (state) => state.provenance.any(
            (entry) => entry.description.contains('Branche exclusive'),
          ),
        ),
        isTrue,
      );
    });

    test('converges equivalent branch states without losing provenance', () {
      final report = solveNarrativeSceneSymbolically(
        _choiceScene(
          leftConsequence: SceneConsequence.setFact(
            factId: 'fact_done',
            value: true,
          ),
          rightConsequence: SceneConsequence.setFact(
            factId: 'fact_done',
            value: true,
          ),
          converge: true,
        ),
      );

      expect(report.verdict, NarrativeSymbolicVerdict.pass);
      expect(report.terminalStates, hasLength(1));
      expect(report.canSatisfyAllTrueFacts({'fact_done'}), isTrue);
    });

    test('reports a cycle as fail with reproducible provenance', () {
      final scene = SceneAsset(
        id: 'scene_cycle',
        name: 'Cycle',
        graph: SceneGraph(
          startNodeId: 'start',
          nodes: [
            SceneNode(id: 'start', kind: SceneNodeKind.start),
            SceneNode(id: 'merge', kind: SceneNodeKind.merge),
          ],
          edges: [
            _edge('start_merge', 'start', 'completed', 'merge'),
            _edge('merge_cycle', 'merge', 'completed', 'merge'),
          ],
        ),
      );

      final report = solveNarrativeSceneSymbolically(scene);

      expect(report.verdict, NarrativeSymbolicVerdict.fail);
      expect(
        report.issues.single.code,
        NarrativeSymbolicIssueCode.cycleDetected,
      );
      expect(report.issues.single.sceneId, 'scene_cycle');
      expect(report.issues.single.nodeId, 'merge');
    });

    test('reports a path with no exit as fail', () {
      final scene = SceneAsset(
        id: 'scene_no_exit',
        name: 'No exit',
        graph: SceneGraph(
          startNodeId: 'start',
          nodes: [
            SceneNode(id: 'start', kind: SceneNodeKind.start),
            SceneNode(
              id: 'action',
              kind: SceneNodeKind.action,
              payload: SceneActionPayload.consequence(
                SceneConsequence.setFact(factId: 'fact_done', value: true),
              ),
            ),
          ],
          edges: [_edge('start_action', 'start', 'completed', 'action')],
        ),
      );

      final report = solveNarrativeSceneSymbolically(scene);

      expect(report.verdict, NarrativeSymbolicVerdict.fail);
      expect(
        report.issues.single.code,
        NarrativeSymbolicIssueCode.pathWithoutExit,
      );
    });

    test('budget exhaustion is indeterminate and never pass', () {
      final nodes = <SceneNode>[
        SceneNode(id: 'start', kind: SceneNodeKind.start),
        for (var index = 0; index < 8; index++)
          SceneNode(id: 'merge_$index', kind: SceneNodeKind.merge),
        SceneNode(id: 'end', kind: SceneNodeKind.end),
      ];
      final edges = <SceneEdge>[
        _edge('edge_start', 'start', 'completed', 'merge_0'),
        for (var index = 0; index < 7; index++)
          _edge(
            'edge_$index',
            'merge_$index',
            'completed',
            'merge_${index + 1}',
          ),
        _edge('edge_end', 'merge_7', 'completed', 'end'),
      ];

      final report = solveNarrativeSceneSymbolically(
        SceneAsset(
          id: 'scene_budget',
          name: 'Budget',
          graph: SceneGraph(
            startNodeId: 'start',
            nodes: nodes,
            edges: edges,
          ),
        ),
        explorationBudget: 4,
      );

      expect(report.verdict, NarrativeSymbolicVerdict.indeterminate);
      expect(
        report.issues.single.code,
        NarrativeSymbolicIssueCode.budgetExceeded,
      );
    });

    test('unknown legacy command backend is indeterminate', () {
      final scene = SceneAsset(
        id: 'scene_unknown_command',
        name: 'Unknown command',
        graph: SceneGraph(
          startNodeId: 'start',
          nodes: [
            SceneNode(id: 'start', kind: SceneNodeKind.start),
            SceneNode(
              id: 'unknown',
              kind: SceneNodeKind.action,
              payload: SceneActionPayload(actionKind: 'custom_script'),
            ),
            SceneNode(id: 'end', kind: SceneNodeKind.end),
          ],
          edges: [
            _edge('start_unknown', 'start', 'completed', 'unknown'),
            _edge('unknown_end', 'unknown', 'completed', 'end'),
          ],
        ),
      );

      final report = solveNarrativeSceneSymbolically(scene);

      expect(report.verdict, NarrativeSymbolicVerdict.indeterminate);
      expect(
        report.issues.single.code,
        NarrativeSymbolicIssueCode.unsupportedCommand,
      );
    });

    test('a broken active side quest does not fail the mandatory project', () {
      const optionalEventId = 'evt_019abcde-5400-7000-8000-000000000003';
      final mainScene = _linearScene('scene_main');
      final optionalScene = SceneAsset(
        id: 'scene_optional',
        name: 'Optional',
        storylineId: 'story_optional',
        graph: SceneGraph(
          startNodeId: 'start',
          nodes: [
            SceneNode(id: 'start', kind: SceneNodeKind.start),
          ],
        ),
      );
      final project = ProjectManifest(
        name: 'Optional quest',
        maps: const [
          ProjectMapEntry(
            id: 'map_port',
            name: 'Port',
            relativePath: 'maps/port.json',
          ),
        ],
        tilesets: const [],
        scenes: [mainScene, optionalScene],
        storylines: [
          StorylineAsset(
            id: 'story_optional',
            type: StorylineType.sideQuest,
            status: StorylineStatus.active,
            title: 'Optional',
          ),
        ],
        eventRegistry: NarrativeEventRegistry(
          schemaVersion: 1,
          mode: EventSystemMode.v2Only,
          records: [
            NarrativeEventRecord.configuredStructurallyUnchecked(
              NarrativeEventDefinition(
                id: optionalEventId,
                name: 'Optional broken path',
                source: NarrativeEventSourceRef.mapEnter('map_port'),
                conditions: const [],
                sceneId: 'scene_optional',
                reusePolicy: NarrativeEventReusePolicy.oneShot,
                priority: 0,
                order: 0,
              ),
              enabled: true,
            ),
          ],
          legacyClaims: const [],
        ),
        newGame: const ProjectNewGameConfig(
          enabled: true,
          starterSelectionSceneId: 'scene_main',
        ),
      );
      const map = MapData(
        id: 'map_port',
        name: 'Port',
        size: GridSize(width: 8, height: 8),
      );

      final report = solveNarrativeSymbolicReachability(
        project,
        maps: const [map],
      );

      expect(report.verdict, NarrativeSymbolicVerdict.pass);
      expect(report.reachableSceneIds, contains('scene_main'));
      expect(report.reachableSceneIds, contains('scene_optional'));
      expect(report.issues.single.optional, isTrue);
      expect(
        report.issues.single.code,
        NarrativeSymbolicIssueCode.pathWithoutExit,
      );
    });

    test('project validator rejects a conjunction built from exclusive paths',
        () {
      const producerEventId = 'evt_019abcde-5400-7000-8000-000000000001';
      const consumerEventId = 'evt_019abcde-5400-7000-8000-000000000002';
      final map = const MapData(
        id: 'map_port',
        name: 'Port',
        size: GridSize(width: 8, height: 8),
      );
      final project = ProjectManifest(
        name: 'Correlated validation',
        maps: const [
          ProjectMapEntry(
            id: 'map_port',
            name: 'Port',
            relativePath: 'maps/port.json',
          ),
        ],
        tilesets: const [],
        facts: [
          NarrativeFactDefinition(id: 'fact_a', label: 'A'),
          NarrativeFactDefinition(id: 'fact_b', label: 'B'),
        ],
        scenes: [
          _choiceScene(
            leftConsequence: SceneConsequence.setFact(
              factId: 'fact_a',
              value: true,
            ),
            rightConsequence: SceneConsequence.setFact(
              factId: 'fact_b',
              value: true,
            ),
          ),
          _linearScene('scene_consumer'),
        ],
        eventRegistry: NarrativeEventRegistry(
          schemaVersion: 1,
          mode: EventSystemMode.v2Only,
          records: [
            NarrativeEventRecord.configuredStructurallyUnchecked(
              NarrativeEventDefinition(
                id: producerEventId,
                name: 'Choose',
                source: NarrativeEventSourceRef.mapEnter('map_port'),
                conditions: const [],
                sceneId: 'scene_choice',
                reusePolicy: NarrativeEventReusePolicy.oneShot,
                priority: 10,
                order: 0,
              ),
              enabled: true,
            ),
            NarrativeEventRecord.configuredStructurallyUnchecked(
              NarrativeEventDefinition(
                id: consumerEventId,
                name: 'Impossible consumer',
                source: NarrativeEventSourceRef.mapEnter('map_port'),
                conditions: [
                  NarrativeEventCondition.fact('fact_a', true),
                  NarrativeEventCondition.fact('fact_b', true),
                ],
                sceneId: 'scene_consumer',
                reusePolicy: NarrativeEventReusePolicy.oneShot,
                priority: 0,
                order: 1,
              ),
              enabled: true,
            ),
          ],
          legacyClaims: const [],
        ),
      );

      final symbolic = solveNarrativeSymbolicReachability(
        project,
        maps: [map],
      );
      final validation = validateNarrativeProject(project, maps: [map]);

      expect(symbolic.verdict, NarrativeSymbolicVerdict.fail);
      expect(
        symbolic.issues.map((issue) => issue.code),
        contains(NarrativeSymbolicIssueCode.mutuallyExclusiveRequirements),
      );
      expect(
        validation.byCode('narrativeMutuallyExclusiveRequirements'),
        hasLength(1),
      );
      expect(validation.narrativelySolvable, NarrativeSymbolicVerdict.fail);
      expect(validation.isPlayable, isFalse);
    });
  });
}

SceneAsset _choiceScene({
  required SceneConsequence leftConsequence,
  required SceneConsequence rightConsequence,
  bool converge = false,
}) {
  return SceneAsset(
    id: 'scene_choice',
    name: 'Choice',
    graph: SceneGraph(
      startNodeId: 'start',
      nodes: [
        SceneNode(id: 'start', kind: SceneNodeKind.start),
        SceneNode(
          id: 'choice',
          kind: SceneNodeKind.yarnDialogue,
          payload: SceneYarnDialoguePayload(
            dialogueId: 'dialogue_choice',
            expectedOutcomes: const ['left', 'right'],
          ),
        ),
        SceneNode(
          id: 'left',
          kind: SceneNodeKind.action,
          payload: SceneActionPayload.consequence(leftConsequence),
        ),
        SceneNode(
          id: 'right',
          kind: SceneNodeKind.action,
          payload: SceneActionPayload.consequence(rightConsequence),
        ),
        if (converge) SceneNode(id: 'merge', kind: SceneNodeKind.merge),
        SceneNode(id: 'end', kind: SceneNodeKind.end),
      ],
      edges: [
        _edge('start_choice', 'start', 'completed', 'choice'),
        SceneEdge(
          id: 'choice_left',
          fromNodeId: 'choice',
          fromPortId: 'left',
          toNodeId: 'left',
          kind: SceneEdgeKind.dialogueOutcome,
        ),
        SceneEdge(
          id: 'choice_right',
          fromNodeId: 'choice',
          fromPortId: 'right',
          toNodeId: 'right',
          kind: SceneEdgeKind.dialogueOutcome,
        ),
        _edge(
          'left_next',
          'left',
          'completed',
          converge ? 'merge' : 'end',
          kind: SceneEdgeKind.actionCompleted,
        ),
        _edge(
          'right_next',
          'right',
          'completed',
          converge ? 'merge' : 'end',
          kind: SceneEdgeKind.actionCompleted,
        ),
        if (converge) _edge('merge_end', 'merge', 'completed', 'end'),
      ],
    ),
  );
}

SceneAsset _linearScene(String id) => SceneAsset(
      id: id,
      name: id,
      graph: SceneGraph(
        startNodeId: 'start',
        nodes: [
          SceneNode(id: 'start', kind: SceneNodeKind.start),
          SceneNode(id: 'end', kind: SceneNodeKind.end),
        ],
        edges: [_edge('start_end', 'start', 'completed', 'end')],
      ),
    );

SceneEdge _edge(
  String id,
  String from,
  String port,
  String to, {
  SceneEdgeKind kind = SceneEdgeKind.defaultFlow,
}) =>
    SceneEdge(
      id: id,
      fromNodeId: from,
      fromPortId: port,
      toNodeId: to,
      kind: kind,
    );
```
</details>
