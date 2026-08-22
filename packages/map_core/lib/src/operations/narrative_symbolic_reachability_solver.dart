import 'package:meta/meta.dart' show immutable;

import '../models/map_data.dart';
import '../models/enums.dart';
import '../models/narrative_event_definition.dart';
import '../models/narrative_event_source_ref.dart';
import '../models/narrative_command_descriptor.dart';
import '../models/narrative_value.dart';
import '../models/project_manifest.dart';
import '../models/scene_asset.dart';
import '../models/scene_consequence.dart';
import '../models/storyline_asset.dart';
import '../models/world_rule.dart';
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
    Set<String> badgeIds = const <String>{},
    Set<FieldAbility> unlockedFieldAbilities = const <FieldAbility>{},
    Set<String> emittedOutcomeKeys = const <String>{},
    Set<String> executedEventIds = const <String>{},
    Set<String> assignedDraftFields = const <String>{},
    List<NarrativeSymbolicProvenance> provenance =
        const <NarrativeSymbolicProvenance>[],
    this.indeterminate = false,
  })  : factValues = Map.unmodifiable(factValues),
        assignedDraftFields = Set.unmodifiable(assignedDraftFields),
        completedStepIds = Set.unmodifiable(completedStepIds),
        consumedEventIds = Set.unmodifiable(consumedEventIds),
        badgeIds = Set.unmodifiable(badgeIds),
        unlockedFieldAbilities = Set.unmodifiable(unlockedFieldAbilities),
        emittedOutcomeKeys = Set.unmodifiable(emittedOutcomeKeys),
        executedEventIds = Set.unmodifiable(executedEventIds),
        provenance = List.unmodifiable(provenance);

  final Map<String, NarrativeValue> factValues;
  final Set<String> completedStepIds;
  final Set<String> consumedEventIds;
  final Set<String> badgeIds;
  final Set<FieldAbility> unlockedFieldAbilities;
  final Set<String> emittedOutcomeKeys;
  final Set<String> executedEventIds;

  /// The pre-session draft fields a traversed interaction has bound on this
  /// path. Nothing else can assign one, which is what makes a draft guard
  /// provable from the graph rather than unknowable.
  final Set<String> assignedDraftFields;

  final List<NarrativeSymbolicProvenance> provenance;
  final bool indeterminate;

  NarrativeSymbolicState copyWith({
    Map<String, NarrativeValue>? factValues,
    Set<String>? completedStepIds,
    Set<String>? consumedEventIds,
    Set<String>? badgeIds,
    Set<FieldAbility>? unlockedFieldAbilities,
    Set<String>? emittedOutcomeKeys,
    Set<String>? executedEventIds,
    Set<String>? assignedDraftFields,
    List<NarrativeSymbolicProvenance>? provenance,
    bool? indeterminate,
  }) =>
      NarrativeSymbolicState(
        factValues: factValues ?? this.factValues,
        completedStepIds: completedStepIds ?? this.completedStepIds,
        consumedEventIds: consumedEventIds ?? this.consumedEventIds,
        badgeIds: badgeIds ?? this.badgeIds,
        unlockedFieldAbilities:
            unlockedFieldAbilities ?? this.unlockedFieldAbilities,
        emittedOutcomeKeys: emittedOutcomeKeys ?? this.emittedOutcomeKeys,
        executedEventIds: executedEventIds ?? this.executedEventIds,
        assignedDraftFields: assignedDraftFields ?? this.assignedDraftFields,
        provenance: provenance ?? this.provenance,
        indeterminate: indeterminate ?? this.indeterminate,
      );

  bool hasTrueFact(String factId) {
    final value = factValues[factId];
    return value?.kind == NarrativeValueKind.boolean && value!.boolValue;
  }

  static final Expando<String> _semanticKeyCache =
      Expando<String>('narrative-symbolic-semantic-key');

  /// Memoized only inside the isolate using this state. Keeping the cache in
  /// an Expando avoids transferring every potentially large key with the
  /// validation report when the worker isolate exits.
  String get semanticKey => _semanticKeyCache[this] ??= _buildSemanticKey();

  String _buildSemanticKey() {
    final facts = factValues.entries.toList()
      ..sort((left, right) => left.key.compareTo(right.key));
    return <String>[
      for (final entry in facts)
        '${entry.key}=${entry.value.kind.wireName}:${entry.value.toJson()}',
      'steps=${_sorted(completedStepIds).join(',')}',
      'consumed=${_sorted(consumedEventIds).join(',')}',
      'badges=${_sorted(badgeIds).join(',')}',
      'field=${unlockedFieldAbilities.map((value) => value.moveId).toList()..sort()}',
      'outcomes=${_sorted(emittedOutcomeKeys).join(',')}',
      'executed=${_sorted(executedEventIds).join(',')}',
      'draft=${_sorted(assignedDraftFields).join(',')}',
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
    List<NarrativeSymbolicState>? evidenceStates,
    List<NarrativeSymbolicFactEvidenceComponent> independentFactComponents =
        const <NarrativeSymbolicFactEvidenceComponent>[],
  })  : terminalStates = List.unmodifiable(terminalStates),
        exploredStates = List.unmodifiable(exploredStates),
        issues = List.unmodifiable(issues),
        reachableSceneIds = Set.unmodifiable(reachableSceneIds),
        evidenceStates = List.unmodifiable(
          evidenceStates ??
              <NarrativeSymbolicState>[
                ...exploredStates,
                ...terminalStates,
              ],
        ),
        independentFactComponents =
            List.unmodifiable(independentFactComponents);

  final NarrativeSymbolicVerdict verdict;
  final List<NarrativeSymbolicState> terminalStates;
  final List<NarrativeSymbolicState> exploredStates;
  final List<NarrativeSymbolicIssue> issues;
  final Set<String> reachableSceneIds;
  final int exploredStateCount;
  final List<NarrativeSymbolicState> evidenceStates;
  final List<NarrativeSymbolicFactEvidenceComponent> independentFactComponents;

  bool canSatisfyAllTrueFacts(Set<String> factIds) {
    final requiredFromMainComponent = {...factIds};
    var compatibleMainStates = evidenceStates.toList(growable: false);
    for (final component in independentFactComponents) {
      final requiredFromComponent =
          requiredFromMainComponent.intersection(component.factIds);
      if (requiredFromComponent.isNotEmpty) {
        final compatibleMainKeys = <String>{};
        for (final state in component.states) {
          if (!requiredFromComponent.every(state.hasTrueFact)) continue;
          compatibleMainKeys.addAll(
            component.compatibleMainStateKeysByStateKey[state.semanticKey] ??
                const <String>{},
          );
        }
        if (compatibleMainKeys.isEmpty) return false;
        compatibleMainStates = compatibleMainStates
            .where(
              (state) => compatibleMainKeys.contains(state.semanticKey),
            )
            .toList(growable: false);
        if (compatibleMainStates.isEmpty) return false;
      }
      requiredFromMainComponent.removeAll(component.factIds);
    }
    return compatibleMainStates.any(
      (state) => requiredFromMainComponent.every(state.hasTrueFact),
    );
  }

  Set<String> get trueFactIds => {
        for (final state in evidenceStates)
          for (final entry in state.factValues.entries)
            if (entry.value.kind == NarrativeValueKind.boolean &&
                entry.value.boolValue)
              entry.key,
        for (final component in independentFactComponents)
          for (final state in component.states)
            for (final entry in state.factValues.entries)
              if (entry.value.kind == NarrativeValueKind.boolean &&
                  entry.value.boolValue)
                entry.key,
      };

  Set<String> get completedStepIds => {
        for (final state in evidenceStates) ...state.completedStepIds,
        for (final component in independentFactComponents)
          for (final state in component.states) ...state.completedStepIds,
      };
}

/// Compact proof for one storyline component that was proven independent from
/// the main story and every other component.
///
/// A query may choose one state from each component without materializing the
/// Cartesian product of all side-quest branches.
@immutable
final class NarrativeSymbolicFactEvidenceComponent {
  NarrativeSymbolicFactEvidenceComponent({
    required Set<String> factIds,
    required List<NarrativeSymbolicState> states,
    required Map<String, Set<String>> compatibleMainStateKeysByStateKey,
  })  : factIds = Set.unmodifiable(factIds),
        states = List.unmodifiable(states),
        compatibleMainStateKeysByStateKey =
            _freezeSharedCompatibilitySets(compatibleMainStateKeysByStateKey);

  final Set<String> factIds;
  final List<NarrativeSymbolicState> states;
  final Map<String, Set<String>> compatibleMainStateKeysByStateKey;
}

Map<String, Set<String>> _freezeSharedCompatibilitySets(
  Map<String, Set<String>> values,
) {
  final frozenBySource = Map<Set<String>, Set<String>>.identity();
  return Map.unmodifiable({
    for (final entry in values.entries)
      entry.key: frozenBySource.putIfAbsent(
        entry.value,
        () => Set.unmodifiable(entry.value),
      ),
  });
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
  final preSessionSceneId = project.newGame.preSessionSceneId;
  if (preSessionSceneId != null && scenesById.containsKey(preSessionSceneId)) {
    final result = solveNarrativeSceneSymbolically(
      scenesById[preSessionSceneId]!,
      initialState: initial,
      explorationBudget: remainingBudget,
      commandCatalog: catalog,
      eventId: 'newGame.preSessionSceneId',
    );
    exploredCount += result.exploredStateCount;
    remainingBudget -= result.exploredStateCount;
    explored.addAll(result.exploredStates);
    issues.addAll(result.issues);
    reachableSceneIds.add(preSessionSceneId);
    frontier = result.terminalStates;
  }

  final definitions = <NarrativeEventDefinition>[
    for (final record
        in project.eventRegistry?.records ?? const <NarrativeEventRecord>[])
      if (record.enabledOrNull == true && record.definitionOrNull != null)
        record.definitionOrNull!,
  ]..sort((left, right) {
      return _compareNarrativeDefinitions(left, right);
    });
  List<NarrativeSymbolicState> exploreDefinitions(
    List<NarrativeEventDefinition> batch,
    List<NarrativeSymbolicState> seeds, {
    List<NarrativeSymbolicState>? eventBoundaryStates,
  }) {
    var batchFrontier = seeds;
    final seen = <String>{};
    final eventBoundaryStateKeys = eventBoundaryStates == null
        ? null
        : {
            for (final state in eventBoundaryStates) state.semanticKey,
          };

    void addEventBoundaryState(NarrativeSymbolicState state) {
      if (eventBoundaryStates == null ||
          !eventBoundaryStateKeys!.add(state.semanticKey)) {
        return;
      }
      eventBoundaryStates.add(state);
    }

    var progress = true;
    while (progress && batchFrontier.isNotEmpty) {
      progress = false;
      final nextFrontier = <NarrativeSymbolicState>[];
      final nextFrontierKeys = <String>{};

      void addNextFrontierState(NarrativeSymbolicState state) {
        if (nextFrontierKeys.add(state.semanticKey)) {
          nextFrontier.add(state);
        }
      }

      for (final state in batchFrontier) {
        final stateKey = state.semanticKey;
        if (!seen.add(stateKey)) {
          addNextFrontierState(state);
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
          addNextFrontierState(state.copyWith(indeterminate: true));
          continue;
        }
        final candidates = <NarrativeEventDefinition>[];
        for (final definition in batch) {
          if (state.executedEventIds.contains(definition.id)) continue;
          final scene = scenesById[definition.sceneId];
          if (scene == null || _isDisabledOptionalScene(project, scene)) {
            continue;
          }
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
          addNextFrontierState(state);
          continue;
        }
        progress = true;
        // Candidate definitions are already sorted by runtime priority/order.
        // Executing every eligible sibling here explores permutations of the
        // same authored Events (A→B and B→A) even when their resulting semantic
        // state is identical. Execute the canonical next Event only; its Scene
        // still forks every exclusive route.
        final definition = candidates.first;
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
          addNextFrontierState(eventState);
        }
        for (final terminal in result.terminalStates) {
          final boundaryState =
              _applyStorylineOutcomeEffects(project, terminal);
          if (eventBoundaryStates != null) {
            addEventBoundaryState(boundaryState);
          }
          addNextFrontierState(boundaryState);
        }
      }
      batchFrontier = nextFrontier;
    }
    return batchFrontier;
  }

  final optionalDefinitionsByStoryline =
      <String, List<NarrativeEventDefinition>>{};
  final mandatoryDefinitions = <NarrativeEventDefinition>[];
  for (final definition in definitions) {
    final scene = scenesById[definition.sceneId];
    if (scene == null || !_isOptionalScene(project, scene)) {
      mandatoryDefinitions.add(definition);
      continue;
    }
    optionalDefinitionsByStoryline
        .putIfAbsent(scene.storylineId!, () => <NarrativeEventDefinition>[])
        .add(definition);
  }
  final optionalBatches = optionalDefinitionsByStoryline.values
      .map((definitions) => [...definitions])
      .toList();
  var mergedOptionalBatch = true;
  while (mergedOptionalBatch) {
    mergedOptionalBatch = false;
    for (var leftIndex = 0;
        leftIndex < optionalBatches.length && !mergedOptionalBatch;
        leftIndex++) {
      final leftFootprint = _narrativeBatchFootprint(
        project: project,
        definitions: optionalBatches[leftIndex],
        scenesById: scenesById,
      );
      for (var rightIndex = leftIndex + 1;
          rightIndex < optionalBatches.length;
          rightIndex++) {
        final rightFootprint = _narrativeBatchFootprint(
          project: project,
          definitions: optionalBatches[rightIndex],
          scenesById: scenesById,
        );
        if (!_narrativeBatchesAreCoupled(
          leftFootprint,
          rightFootprint,
        )) {
          continue;
        }
        optionalBatches[leftIndex]
          ..addAll(optionalBatches[rightIndex])
          ..sort(_compareNarrativeDefinitions);
        optionalBatches.removeAt(rightIndex);
        mergedOptionalBatch = true;
        break;
      }
    }
  }
  var promotedOptionalBatch = true;
  while (promotedOptionalBatch) {
    promotedOptionalBatch = false;
    final mandatoryFootprint = _narrativeBatchFootprint(
      project: project,
      definitions: mandatoryDefinitions,
      scenesById: scenesById,
    );
    for (var index = 0; index < optionalBatches.length; index++) {
      final optionalFootprint = _narrativeBatchFootprint(
        project: project,
        definitions: optionalBatches[index],
        scenesById: scenesById,
      );
      if (!_optionalBatchMustJoinMandatory(
        optionalFootprint,
        mandatoryFootprint,
      )) {
        continue;
      }
      mandatoryDefinitions
        ..addAll(optionalBatches.removeAt(index))
        ..sort(_compareNarrativeDefinitions);
      promotedOptionalBatch = true;
      break;
    }
  }

  final mandatoryEvidenceStates = <NarrativeSymbolicState>[
    ...frontier,
  ];
  final mandatoryTerminals = exploreDefinitions(
    mandatoryDefinitions,
    frontier,
    eventBoundaryStates: mandatoryEvidenceStates,
  );
  terminals.addAll(mandatoryTerminals);
  for (final terminal in mandatoryTerminals) {
    _addUniqueState(mandatoryEvidenceStates, terminal);
  }
  final independentFactComponents = <NarrativeSymbolicFactEvidenceComponent>[];
  final allEventBoundaryStates = <NarrativeSymbolicState>[
    ...mandatoryEvidenceStates,
  ];
  final mainProvenanceIndex =
      _NarrativeProvenanceDescendantIndex(mandatoryEvidenceStates);
  optionalBatches.sort((left, right) {
    final leftId = scenesById[left.first.sceneId]?.storylineId ?? '';
    final rightId = scenesById[right.first.sceneId]?.storylineId ?? '';
    return leftId.compareTo(rightId);
  });
  for (final batch in optionalBatches) {
    final projectedSeeds = _projectSymbolicSeeds(
      project: project,
      definitions: batch,
      scenesById: scenesById,
      states: mandatoryEvidenceStates,
    );
    final seeds = projectedSeeds.states;
    final footprint = _narrativeBatchFootprint(
      project: project,
      definitions: batch,
      scenesById: scenesById,
    );
    final optionalBoundaryStates = <NarrativeSymbolicState>[...seeds];
    final optionalTerminals = exploreDefinitions(
      batch,
      seeds,
      eventBoundaryStates: optionalBoundaryStates,
    );
    terminals.addAll(optionalTerminals);
    for (final state in optionalBoundaryStates) {
      _addUniqueState(allEventBoundaryStates, state);
    }
    final batchEventIds = batch.map((definition) => definition.id).toSet();
    final compatibleMainKeysBySeedStateKey = <String, Set<String>>{
      for (final seed in seeds)
        seed.semanticKey: {
          for (final origin
              in projectedSeeds.originsBySeedStateKey[seed.semanticKey] ??
                  const <NarrativeSymbolicState>[])
            ...mainProvenanceIndex.descendantStateKeys(origin.provenance),
        },
    };
    final componentWrites = _NarrativeComponentWrites.from(
      footprint.writes,
      batchEventIds,
    );
    final compatibleMainKeysByAgreementKey = <String, Set<String>>{};
    for (final seed in seeds) {
      compatibleMainKeysByAgreementKey
          .putIfAbsent(
            componentWrites.agreementKey(seed),
            () => <String>{},
          )
          .addAll(
            compatibleMainKeysBySeedStateKey[seed.semanticKey] ??
                const <String>{},
          );
    }
    independentFactComponents.add(
      NarrativeSymbolicFactEvidenceComponent(
        factIds: {
          for (final write in footprint.writes)
            if (write.startsWith('fact:')) write.substring('fact:'.length),
        },
        states: optionalBoundaryStates,
        compatibleMainStateKeysByStateKey: {
          for (final state in optionalBoundaryStates)
            state.semanticKey: compatibleMainKeysByAgreementKey[
                    componentWrites.agreementKey(state)] ??
                const <String>{},
        },
      ),
    );
  }

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
    final states = allEventBoundaryStates;
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
    evidenceStates: mandatoryEvidenceStates,
    independentFactComponents: independentFactComponents,
  );
}

final class _ProjectedSymbolicSeeds {
  _ProjectedSymbolicSeeds({
    required List<NarrativeSymbolicState> states,
    required Map<String, List<NarrativeSymbolicState>> originsBySeedStateKey,
  })  : states = List.unmodifiable(states),
        originsBySeedStateKey =
            Map<String, List<NarrativeSymbolicState>>.unmodifiable({
          for (final entry in originsBySeedStateKey.entries)
            entry.key: List<NarrativeSymbolicState>.unmodifiable(entry.value),
        });

  final List<NarrativeSymbolicState> states;
  final Map<String, List<NarrativeSymbolicState>> originsBySeedStateKey;
}

_ProjectedSymbolicSeeds _projectSymbolicSeeds({
  required ProjectManifest project,
  required List<NarrativeEventDefinition> definitions,
  required Map<String, SceneAsset> scenesById,
  required List<NarrativeSymbolicState> states,
}) {
  final relevantFactIds = <String>{};
  final relevantStepIds = <String>{};
  final relevantConsumedEventIds = <String>{};
  final relevantOutcomeKeys = <String>{};
  final definitionIds = definitions.map((definition) => definition.id).toSet();

  for (final definition in definitions) {
    _collectEventConditionReads(
      definition.conditionExpression,
      factIds: relevantFactIds,
      consumedEventIds: relevantConsumedEventIds,
    );
    definition.source.when(
      entityInteract: (_, __) {},
      triggerEnter: (_, __) {},
      mapEnter: (_) {},
      outcomeReceived: (outcome) {
        if (outcome.producerKind == NarrativeOutcomeProducerKind.scene) {
          relevantOutcomeKeys.add(
            _outcomeKey(outcome.producerId, outcome.outcomeId),
          );
        }
      },
    );
    final scene = scenesById[definition.sceneId];
    if (scene == null) continue;
    for (final node in scene.graph.nodes) {
      final payload = node.payload;
      if (payload is! SceneConditionPayload) continue;
      final source = payload.conditionSource;
      if (source == null) continue;
      switch (source.sourceKind) {
        case SceneConditionSourceKind.newGameDraft:
          break;
        case SceneConditionSourceKind.fact:
        case SceneConditionSourceKind.factLikeStoryFlag:
          relevantFactIds.add(source.sourceId);
        case SceneConditionSourceKind.storyStepCompletion:
          relevantStepIds.add(source.sourceId);
        case SceneConditionSourceKind.consumedEvent:
          relevantConsumedEventIds.add(source.sourceId);
        case SceneConditionSourceKind.storyStepActive:
        case SceneConditionSourceKind.inventoryItem:
        case SceneConditionSourceKind.partyState:
        case SceneConditionSourceKind.trainerDefeated:
        case SceneConditionSourceKind.dialogueOutcome:
        case SceneConditionSourceKind.battleOutcome:
        case SceneConditionSourceKind.scriptVariable:
        case SceneConditionSourceKind.worldState:
          break;
      }
    }
  }

  // Preserve every dimension that can change physical reachability. Optional
  // storylines are solved independently, but their seed must still represent
  // main-story gates such as a passage opened by a Fact or completed step.
  for (final rule in project.worldRules) {
    switch (rule.source.kind) {
      case WorldRuleSourceKind.fact:
        relevantFactIds.add(rule.source.sourceId);
      case WorldRuleSourceKind.storyStepCompletion:
        relevantStepIds.add(rule.source.sourceId);
      case WorldRuleSourceKind.consumedEvent:
        relevantConsumedEventIds.add(rule.source.sourceId);
    }
  }

  String projectionKey(NarrativeSymbolicState state) {
    final facts = <String>[
      for (final factId in relevantFactIds)
        if (state.factValues[factId] case final value?)
          '$factId=${value.kind.wireName}:${value.toJson()}',
    ]..sort();
    final steps = state.completedStepIds.intersection(relevantStepIds).toList()
      ..sort();
    final consumed = state.consumedEventIds
        .intersection(relevantConsumedEventIds)
        .toList()
      ..sort();
    final outcomes = state.emittedOutcomeKeys
        .intersection(relevantOutcomeKeys)
        .toList()
      ..sort();
    final executed = state.executedEventIds.intersection(definitionIds).toList()
      ..sort();
    final badges = state.badgeIds.toList()..sort();
    final fieldAbilities = state.unlockedFieldAbilities
        .map((ability) => ability.moveId)
        .toList()
      ..sort();
    return <String>[
      ...facts,
      'steps=${steps.join(',')}',
      'consumed=${consumed.join(',')}',
      'outcomes=${outcomes.join(',')}',
      'executed=${executed.join(',')}',
      'badges=${badges.join(',')}',
      'field=${fieldAbilities.join(',')}',
      'indeterminate=${state.indeterminate}',
    ].join('|');
  }

  final byProjection = <String, NarrativeSymbolicState>{};
  final originsByProjection = <String, List<NarrativeSymbolicState>>{};
  final originKeysByProjection = <String, Set<String>>{};
  for (final state in states) {
    final key = projectionKey(state);
    final origins = originsByProjection.putIfAbsent(
      key,
      () => <NarrativeSymbolicState>[],
    );
    final originKeys = originKeysByProjection.putIfAbsent(
      key,
      () => <String>{},
    );
    if (originKeys.add(state.semanticKey)) {
      origins.add(state);
    }
    final existing = byProjection[key];
    if (existing == null || existing.indeterminate && !state.indeterminate) {
      byProjection[key] = state;
    }
  }
  return _ProjectedSymbolicSeeds(
    states: byProjection.values.toList(growable: false),
    originsBySeedStateKey: {
      for (final entry in byProjection.entries)
        entry.value.semanticKey:
            originsByProjection[entry.key] ?? const <NarrativeSymbolicState>[],
    },
  );
}

void _collectEventConditionReads(
  NarrativeEventConditionExpression expression, {
  required Set<String> factIds,
  required Set<String> consumedEventIds,
}) {
  switch (expression) {
    case NarrativeEventConditionLeaf(:final condition):
      condition.whenTyped(
        fact: (factId, _, __) => factIds.add(factId),
        narrativeEventConsumed: (eventId, _) => consumedEventIds.add(eventId),
      );
    case NarrativeEventConditionAll(:final children):
    case NarrativeEventConditionAny(:final children):
      for (final child in children) {
        _collectEventConditionReads(
          child,
          factIds: factIds,
          consumedEventIds: consumedEventIds,
        );
      }
    case NarrativeEventConditionNot(:final child):
      _collectEventConditionReads(
        child,
        factIds: factIds,
        consumedEventIds: consumedEventIds,
      );
  }
}

int _compareNarrativeDefinitions(
  NarrativeEventDefinition left,
  NarrativeEventDefinition right,
) {
  final priority = right.priority.compareTo(left.priority);
  if (priority != 0) return priority;
  final order = left.order.compareTo(right.order);
  return order != 0 ? order : left.id.compareTo(right.id);
}

final class _NarrativeBatchFootprint {
  const _NarrativeBatchFootprint({
    required this.reads,
    required this.writes,
  });

  final Set<String> reads;
  final Set<String> writes;
}

_NarrativeBatchFootprint _narrativeBatchFootprint({
  required ProjectManifest project,
  required List<NarrativeEventDefinition> definitions,
  required Map<String, SceneAsset> scenesById,
}) {
  final reads = <String>{};
  final writes = <String>{};
  final sceneIds = definitions.map((definition) => definition.sceneId).toSet();

  for (final definition in definitions) {
    final factIds = <String>{};
    final consumedEventIds = <String>{};
    _collectEventConditionReads(
      definition.conditionExpression,
      factIds: factIds,
      consumedEventIds: consumedEventIds,
    );
    reads.addAll(factIds.map((id) => 'fact:$id'));
    reads.addAll(consumedEventIds.map((id) => 'consumed:$id'));
    definition.source.when(
      entityInteract: (_, __) {},
      triggerEnter: (_, __) {},
      mapEnter: (_) {},
      outcomeReceived: (outcome) {
        if (outcome.producerKind == NarrativeOutcomeProducerKind.scene) {
          reads.add(
            'outcome:${_outcomeKey(outcome.producerId, outcome.outcomeId)}',
          );
        }
      },
    );
    if (definition.reusePolicy == NarrativeEventReusePolicy.oneShot) {
      writes.add('consumed:${definition.id}');
    }

    final scene = scenesById[definition.sceneId];
    if (scene == null) continue;
    for (final node in scene.graph.nodes) {
      switch (node.payload) {
        case SceneConditionPayload(:final conditionSource):
          final source = conditionSource;
          if (source == null) continue;
          switch (source.sourceKind) {
            case SceneConditionSourceKind.newGameDraft:
              break;
            case SceneConditionSourceKind.fact:
            case SceneConditionSourceKind.factLikeStoryFlag:
              reads.add('fact:${source.sourceId}');
            case SceneConditionSourceKind.storyStepCompletion:
              reads.add('step:${source.sourceId}');
            case SceneConditionSourceKind.consumedEvent:
              reads.add('consumed:${source.sourceId}');
            case SceneConditionSourceKind.storyStepActive:
            case SceneConditionSourceKind.inventoryItem:
            case SceneConditionSourceKind.partyState:
            case SceneConditionSourceKind.trainerDefeated:
            case SceneConditionSourceKind.dialogueOutcome:
            case SceneConditionSourceKind.battleOutcome:
            case SceneConditionSourceKind.scriptVariable:
            case SceneConditionSourceKind.worldState:
              break;
          }
        case SceneActionPayload(:final consequence):
          switch (consequence) {
            case SceneSetFactConsequence(:final factId):
              writes.add('fact:$factId');
            case SceneCompleteStoryStepConsequence(:final stepId):
              writes.add('step:$stepId');
            case SceneMarkEventConsumedConsequence(:final eventId):
              writes.add('consumed:$eventId');
            case SceneAwardBadgeConsequence(:final badgeId):
              writes.add('badge:$badgeId');
            case SceneUnlockFieldAbilityConsequence(:final ability):
              writes.add('field:${ability.moveId}');
            case SceneSetNpcPresenceConsequence(
                :final mapId,
                :final entityId,
              ):
              writes.add('npc:$mapId:$entityId');
            case SceneGiveItemConsequence():
            case SceneTakeItemConsequence():
            case SceneGiveMoneyConsequence():
            case SceneGivePokemonConsequence():
            case SceneGiveConfiguredStarterConsequence():
            case SceneHealPartyConsequence():
            case SceneFinishGameConsequence():
            case null:
              break;
          }
        case SceneEndPayload(:final sceneOutcomeId):
          if (sceneOutcomeId != null) {
            writes.add('outcome:${_outcomeKey(scene.id, sceneOutcomeId)}');
          }
        case _:
          break;
      }
    }
  }

  for (final storyline in project.storylines) {
    for (final link in storyline.sceneLinks) {
      final sceneId = link.sceneRef?.targetId;
      if (sceneId == null || !sceneIds.contains(sceneId)) continue;
      for (final outcome in link.outcomeLinks) {
        for (final effect in outcome.effects) {
          switch (effect.type) {
            case StorylineEffectType.completeStep:
              writes.add('step:${effect.targetId}');
            case StorylineEffectType.emitFact:
              writes.add('fact:${effect.targetId}');
            case StorylineEffectType.activateStep:
            case StorylineEffectType.unlockStoryline:
            case StorylineEffectType.setWorldRule:
            case StorylineEffectType.affectRelationship:
              break;
          }
        }
      }
    }
  }

  return _NarrativeBatchFootprint(
    reads: Set.unmodifiable(reads),
    writes: Set.unmodifiable(writes),
  );
}

bool _narrativeBatchesAreCoupled(
  _NarrativeBatchFootprint left,
  _NarrativeBatchFootprint right,
) {
  final leftRelevant = {...left.reads, ...left.writes};
  final rightRelevant = {...right.reads, ...right.writes};
  return _setsIntersect(left.writes, rightRelevant) ||
      _setsIntersect(right.writes, leftRelevant);
}

bool _optionalBatchMustJoinMandatory(
  _NarrativeBatchFootprint optional,
  _NarrativeBatchFootprint mandatory,
) {
  return _setsIntersect(
    optional.writes,
    {...mandatory.reads, ...mandatory.writes},
  );
}

bool _setsIntersect(Set<String> left, Set<String> right) =>
    left.any(right.contains);

final class _NarrativeComponentWrites {
  _NarrativeComponentWrites({
    required this.factIds,
    required this.stepIds,
    required this.consumedEventIds,
    required this.badgeIds,
    required this.outcomeKeys,
    required this.fieldAbilityIds,
    required this.executedEventIds,
  });

  factory _NarrativeComponentWrites.from(
    Set<String> writes,
    Set<String> executedEventIds,
  ) {
    Set<String> ids(String prefix) => {
          for (final write in writes)
            if (write.startsWith(prefix)) write.substring(prefix.length),
        };

    return _NarrativeComponentWrites(
      factIds: ids('fact:'),
      stepIds: ids('step:'),
      consumedEventIds: ids('consumed:'),
      badgeIds: ids('badge:'),
      outcomeKeys: ids('outcome:'),
      fieldAbilityIds: ids('field:'),
      executedEventIds: executedEventIds,
    );
  }

  final Set<String> factIds;
  final Set<String> stepIds;
  final Set<String> consumedEventIds;
  final Set<String> badgeIds;
  final Set<String> outcomeKeys;
  final Set<String> fieldAbilityIds;
  final Set<String> executedEventIds;

  String agreementKey(NarrativeSymbolicState state) {
    return NarrativeSymbolicState(
      factValues: {
        for (final entry in state.factValues.entries)
          if (!factIds.contains(entry.key)) entry.key: entry.value,
      },
      completedStepIds: state.completedStepIds.difference(stepIds),
      consumedEventIds: state.consumedEventIds.difference(consumedEventIds),
      badgeIds: state.badgeIds.difference(badgeIds),
      unlockedFieldAbilities: {
        for (final ability in state.unlockedFieldAbilities)
          if (!fieldAbilityIds.contains(ability.moveId)) ability,
      },
      emittedOutcomeKeys: state.emittedOutcomeKeys.difference(outcomeKeys),
      executedEventIds: state.executedEventIds.difference(executedEventIds),
    ).semanticKey;
  }
}

final class _NarrativeProvenanceDescendantIndex {
  _NarrativeProvenanceDescendantIndex(
    Iterable<NarrativeSymbolicState> mainStates,
  ) {
    for (final state in mainStates) {
      final stateKey = state.semanticKey;
      var node = _root;
      node.descendantStateKeys.add(stateKey);
      for (final entry in state.provenance) {
        node = node.children.putIfAbsent(
          _provenanceEntryKey(entry),
          _NarrativeProvenanceIndexNode.new,
        );
        node.descendantStateKeys.add(stateKey);
      }
    }
  }

  final _NarrativeProvenanceIndexNode _root = _NarrativeProvenanceIndexNode();

  Set<String> descendantStateKeys(
    Iterable<NarrativeSymbolicProvenance> provenance,
  ) {
    var node = _root;
    for (final entry in provenance) {
      final next = node.children[_provenanceEntryKey(entry)];
      if (next == null) return const <String>{};
      node = next;
    }
    return node.descendantStateKeys;
  }
}

final class _NarrativeProvenanceIndexNode {
  final Map<String, _NarrativeProvenanceIndexNode> children = {};
  final Set<String> descendantStateKeys = {};
}

String _provenanceEntryKey(NarrativeSymbolicProvenance entry) {
  final buffer = StringBuffer();
  void writeField(String? value) {
    final resolved = value ?? '';
    buffer
      ..write(resolved.length)
      ..write(':')
      ..write(resolved);
  }

  writeField(entry.sceneId);
  writeField(entry.nodeId);
  writeField(entry.eventId);
  writeField(entry.description);
  return buffer.toString();
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
  // A pre-session interaction with a result binding is the ONLY thing that
  // assigns a draft field, and reaching this node means it completed — so on
  // this path the field is set. That is what turns a draft guard from
  // unknowable into decided.
  final boundField = payload.preSessionInteraction?.resultBinding?.field;
  if (boundField != null) {
    next = next.copyWith(
      assignedDraftFields: <String>{...next.assignedDraftFields, boundField.name},
    );
  }
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
      case SceneHealPartyConsequence():
      case SceneSetNpcPresenceConsequence():
      case SceneFinishGameConsequence():
        break;
      case SceneAwardBadgeConsequence(:final badgeId):
        next = next.copyWith(badgeIds: {...next.badgeIds, badgeId});
      case SceneUnlockFieldAbilityConsequence(:final ability):
        next = next.copyWith(
          unlockedFieldAbilities: {
            ...next.unlockedFieldAbilities,
            ability,
          },
        );
    }
  }

  final interactive = payload.interactiveCommand;
  final commandId = interactive?.kind.name ?? payload.actionKind;
  if (payload.preSessionInteraction == null &&
      (interactive == null && consequence == null || interactive != null)) {
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
    case SceneNodeKind.presentationCinematic:
      return edges
          .where((edge) =>
              edge.fromPortId == 'completed' &&
              edge.kind == SceneEdgeKind.presentationCompleted)
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
    case SceneConditionSourceKind.newGameDraft:
      // Decided by the graph: assigned upstream is true, never assigned is
      // false. Both are answers, so neither leaves the path indeterminate.
      return _boolConditionValue(
        source,
        state.assignedDraftFields.contains(source.sourceId),
      );
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
