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
