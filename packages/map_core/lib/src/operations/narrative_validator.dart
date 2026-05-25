import 'package:meta/meta.dart' show immutable;

import '../models/map_data.dart';
import '../models/map_entity_payloads.dart';
import '../models/project_manifest.dart';
import '../models/scenario_asset.dart';
import '../models/script_conditions.dart';

const String _sourceMapEnter = 'sourceMapEnter';
const String _sourceTriggerEnter = 'sourceTriggerEnter';
const String _sourceEntityInteract = 'sourceEntityInteract';
const String _sourceOutcome = 'sourceOutcome';
const String _actionOpenDialogue = 'openDialogue';
const String _actionSetFlag = 'setFlag';
const String _actionEmitOutcome = 'emitOutcome';
const String _actionStartTrainerBattle = 'startTrainerBattle';
const String _actionCompleteStep = 'completeStep';
const String _battleIdParam = 'battleId';
const String _stepIdParam = 'stepId';

const Set<String> _sourceKinds = {
  _sourceMapEnter,
  _sourceTriggerEnter,
  _sourceEntityInteract,
  _sourceOutcome,
};

enum NarrativeValidationSeverity {
  error,
  warning,
}

enum NarrativeValidationDiagnosticKind {
  scenarioNodeReferencesUnknownNode,
  scenarioGraphHasUnreachableNode,
  scenarioGraphHasNoSource,
  openDialogueReferencesUnknownDialogue,
  startTrainerBattleMissingTrainerId,
  startTrainerBattleReferencesUnknownTrainer,
  startTrainerBattleMissingNpcEntityId,
  startTrainerBattleBlankBattleId,
  sourceEntityInteractReferencesUnknownMap,
  sourceEntityInteractReferencesUnknownEntity,
  sourceOutcomeWithoutMatchingEmitOutcome,
  emitOutcomeWithoutMatchingSourceOutcome,
  declaredOutcomeNeverEmitted,
  emitOutcomeNotDeclared,
  conditionalDialogueReferencesUnknownDialogue,
  visibilityRuleConditionalMissingPredicate,
  worldRulePredicateEmptyRefId,
  scenarioChoiceNodeRuntimeUnsupported,
  flagReadNeverProduced,
  setFlagNeverRead,
  stepReadNeverCompleted,
  completeStepNeverRead,
}

@immutable
final class NarrativeValidationDiagnostic {
  const NarrativeValidationDiagnostic({
    required this.severity,
    required this.kind,
    required this.message,
    required this.path,
    this.referencedId,
    this.scenarioId,
    this.nodeId,
    this.mapId,
    this.entityId,
  });

  final NarrativeValidationSeverity severity;
  final NarrativeValidationDiagnosticKind kind;
  final String message;
  final String path;
  final String? referencedId;
  final String? scenarioId;
  final String? nodeId;
  final String? mapId;
  final String? entityId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NarrativeValidationDiagnostic &&
          other.severity == severity &&
          other.kind == kind &&
          other.message == message &&
          other.path == path &&
          other.referencedId == referencedId &&
          other.scenarioId == scenarioId &&
          other.nodeId == nodeId &&
          other.mapId == mapId &&
          other.entityId == entityId;

  @override
  int get hashCode => Object.hash(
        severity,
        kind,
        message,
        path,
        referencedId,
        scenarioId,
        nodeId,
        mapId,
        entityId,
      );
}

@immutable
final class NarrativeValidationReport {
  NarrativeValidationReport({
    required List<NarrativeValidationDiagnostic> diagnostics,
  }) {
    _diagnostics =
        List<NarrativeValidationDiagnostic>.unmodifiable(diagnostics);
  }

  late final List<NarrativeValidationDiagnostic> _diagnostics;

  List<NarrativeValidationDiagnostic> get diagnostics => _diagnostics;

  int get count => _diagnostics.length;

  int get errorCount => _diagnostics
      .where((d) => d.severity == NarrativeValidationSeverity.error)
      .length;

  int get warningCount => _diagnostics
      .where((d) => d.severity == NarrativeValidationSeverity.warning)
      .length;

  bool get hasDiagnostics => _diagnostics.isNotEmpty;

  bool get hasErrors => errorCount > 0;

  List<NarrativeValidationDiagnostic> byKind(
    NarrativeValidationDiagnosticKind kind,
  ) {
    return List<NarrativeValidationDiagnostic>.unmodifiable(
      _diagnostics.where((d) => d.kind == kind),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NarrativeValidationReport &&
          _diagnosticsEqualInOrder(_diagnostics, other._diagnostics);

  @override
  int get hashCode => Object.hashAll(_diagnostics);
}

NarrativeValidationReport diagnoseNarrativeProject(
  ProjectManifest manifest, {
  Iterable<MapData> maps = const [],
}) {
  final diagnostics = <NarrativeValidationDiagnostic>[];
  final knownDialogueIds = _nonBlankIds(manifest.dialogues.map((d) => d.id));
  final knownTrainerIds = _nonBlankIds(manifest.trainers.map((t) => t.id));
  final knownMapIds = _nonBlankIds(manifest.maps.map((m) => m.id))
    ..addAll(_nonBlankIds(maps.map((m) => m.id)));
  final mapsById = <String, MapData>{
    for (final map in maps)
      if (map.id.trim().isNotEmpty) map.id.trim(): map,
  };

  final emittedOutcomes = <String, List<_NarrativeRef>>{};
  final consumedOutcomes = <String, List<_NarrativeRef>>{};
  final producedFlags = <String, List<_NarrativeRef>>{};
  final readFlags = <String, List<_NarrativeRef>>{};
  final completedSteps = <String, List<_NarrativeRef>>{};
  final readSteps = <String, List<_NarrativeRef>>{};

  for (final map in mapsById.values) {
    _collectMapDiagnostics(
      map: map,
      knownDialogueIds: knownDialogueIds,
      producedFlags: producedFlags,
      readFlags: readFlags,
      completedSteps: completedSteps,
      readSteps: readSteps,
      diagnostics: diagnostics,
    );
  }

  for (final scenario in manifest.scenarios) {
    _collectScenarioDiagnostics(
      scenario: scenario,
      knownDialogueIds: knownDialogueIds,
      knownTrainerIds: knownTrainerIds,
      knownMapIds: knownMapIds,
      mapsById: mapsById,
      emittedOutcomes: emittedOutcomes,
      consumedOutcomes: consumedOutcomes,
      producedFlags: producedFlags,
      readFlags: readFlags,
      completedSteps: completedSteps,
      readSteps: readSteps,
      diagnostics: diagnostics,
    );
  }

  _collectOutcomeMismatchDiagnostics(
    emittedOutcomes: emittedOutcomes,
    consumedOutcomes: consumedOutcomes,
    diagnostics: diagnostics,
  );
  _collectReadWriteMismatchDiagnostics(
    produced: producedFlags,
    read: readFlags,
    producedNeverReadKind: NarrativeValidationDiagnosticKind.setFlagNeverRead,
    readNeverProducedKind:
        NarrativeValidationDiagnosticKind.flagReadNeverProduced,
    producedNeverReadMessage: (id) => 'Flag "$id" is set but never read.',
    readNeverProducedMessage: (id) => 'Flag "$id" is read but never set.',
    diagnostics: diagnostics,
  );
  _collectReadWriteMismatchDiagnostics(
    produced: completedSteps,
    read: readSteps,
    producedNeverReadKind:
        NarrativeValidationDiagnosticKind.completeStepNeverRead,
    readNeverProducedKind:
        NarrativeValidationDiagnosticKind.stepReadNeverCompleted,
    producedNeverReadMessage: (id) => 'Step "$id" is completed but never read.',
    readNeverProducedMessage: (id) => 'Step "$id" is read but never completed.',
    diagnostics: diagnostics,
  );

  diagnostics.sort(_compareDiagnostics);
  return NarrativeValidationReport(diagnostics: diagnostics);
}

void _collectMapDiagnostics({
  required MapData map,
  required Set<String> knownDialogueIds,
  required Map<String, List<_NarrativeRef>> producedFlags,
  required Map<String, List<_NarrativeRef>> readFlags,
  required Map<String, List<_NarrativeRef>> completedSteps,
  required Map<String, List<_NarrativeRef>> readSteps,
  required List<NarrativeValidationDiagnostic> diagnostics,
}) {
  final mapId = map.id.trim();
  for (final entity in map.entities) {
    final entityId = entity.id.trim();
    final npc = entity.npc;
    if (npc == null) {
      continue;
    }
    final basePath = 'maps.$mapId.entities.$entityId';
    final visibilityRule = npc.visibilityRule;
    final visibilityPredicate = visibilityRule?.predicate;
    if (visibilityRule != null &&
        visibilityRule.mode != MapEntityNpcVisibilityMode.always &&
        visibilityPredicate == null) {
      diagnostics.add(
        NarrativeValidationDiagnostic(
          severity: NarrativeValidationSeverity.error,
          kind: NarrativeValidationDiagnosticKind
              .visibilityRuleConditionalMissingPredicate,
          message: 'NPC "$entityId" has a conditional visibility rule without '
              'a predicate.',
          path: '$basePath.visibilityRule.predicate',
          mapId: mapId,
          entityId: entityId,
        ),
      );
    }
    if (visibilityPredicate != null) {
      _collectWorldRulePredicateDiagnostics(
        visibilityPredicate,
        path: '$basePath.visibilityRule.predicate',
        mapId: mapId,
        entityId: entityId,
        diagnostics: diagnostics,
      );
      _collectRuntimePredicateReads(
        visibilityPredicate,
        ref: _NarrativeRef(
          path: '$basePath.visibilityRule.predicate',
          mapId: mapId,
          entityId: entityId,
        ),
        readFlags: readFlags,
        readSteps: readSteps,
      );
    }
    for (var i = 0; i < npc.conditionalDialogues.length; i++) {
      final conditional = npc.conditionalDialogues[i];
      final path = '$basePath.conditionalDialogues.$i';
      _collectWorldRulePredicateDiagnostics(
        conditional.when,
        path: '$path.when',
        mapId: mapId,
        entityId: entityId,
        diagnostics: diagnostics,
      );
      _collectRuntimePredicateReads(
        conditional.when,
        ref: _NarrativeRef(
          path: '$path.when',
          mapId: mapId,
          entityId: entityId,
        ),
        readFlags: readFlags,
        readSteps: readSteps,
      );
      final dialogueId = conditional.dialogue.dialogueId.trim();
      if (dialogueId.isNotEmpty && !knownDialogueIds.contains(dialogueId)) {
        diagnostics.add(
          NarrativeValidationDiagnostic(
            severity: NarrativeValidationSeverity.error,
            kind: NarrativeValidationDiagnosticKind
                .conditionalDialogueReferencesUnknownDialogue,
            message:
                'Conditional dialogue references unknown dialogue "$dialogueId".',
            path: '$path.dialogue.dialogueId',
            referencedId: dialogueId,
            mapId: mapId,
            entityId: entityId,
          ),
        );
      }
    }
  }
}

void _collectScenarioDiagnostics({
  required ScenarioAsset scenario,
  required Set<String> knownDialogueIds,
  required Set<String> knownTrainerIds,
  required Set<String> knownMapIds,
  required Map<String, MapData> mapsById,
  required Map<String, List<_NarrativeRef>> emittedOutcomes,
  required Map<String, List<_NarrativeRef>> consumedOutcomes,
  required Map<String, List<_NarrativeRef>> producedFlags,
  required Map<String, List<_NarrativeRef>> readFlags,
  required Map<String, List<_NarrativeRef>> completedSteps,
  required Map<String, List<_NarrativeRef>> readSteps,
  required List<NarrativeValidationDiagnostic> diagnostics,
}) {
  final scenarioId = scenario.id.trim();
  final nodeIds = _nonBlankIds(scenario.nodes.map((node) => node.id));
  final sourceNodeIds = <String>{};
  final declaredOutcomeRefs = <String, List<_NarrativeRef>>{};
  final emittedOutcomeRefs = <String, List<_NarrativeRef>>{};

  for (var i = 0; i < scenario.declaredOutcomes.length; i++) {
    _addRef(
      declaredOutcomeRefs,
      scenario.declaredOutcomes[i],
      _NarrativeRef(
        path: 'scenarios.$scenarioId.declaredOutcomes.$i',
        scenarioId: scenarioId,
      ),
    );
  }
  final declaredOutcomeIds = declaredOutcomeRefs.keys.toSet();

  if (scenario.activationCondition != null) {
    _collectScriptConditionReads(
      scenario.activationCondition!,
      ref: _NarrativeRef(
        path: 'scenarios.$scenarioId.activationCondition',
        scenarioId: scenarioId,
      ),
      readFlags: readFlags,
    );
  }

  for (final node in scenario.nodes) {
    final nodeId = node.id.trim();
    final actionKind = _actionKind(node);
    final ref = _NarrativeRef(
      path: 'scenarios.$scenarioId.nodes.$nodeId',
      scenarioId: scenarioId,
      nodeId: nodeId,
    );
    if (node.type == ScenarioNodeType.reference &&
        _sourceKinds.contains(actionKind)) {
      sourceNodeIds.add(nodeId);
    }
    if (node.type == ScenarioNodeType.choice) {
      diagnostics.add(
        NarrativeValidationDiagnostic(
          severity: NarrativeValidationSeverity.warning,
          kind: NarrativeValidationDiagnosticKind
              .scenarioChoiceNodeRuntimeUnsupported,
          message: 'Choice node "$nodeId" is not supported by the scenario '
              'runtime yet.',
          path: '${ref.path}.type',
          scenarioId: scenarioId,
          nodeId: nodeId,
        ),
      );
    }
    if (node.payload.condition != null) {
      _collectScriptConditionReads(
        node.payload.condition!,
        ref: _NarrativeRef(
          path: '${ref.path}.payload.condition',
          scenarioId: scenarioId,
          nodeId: nodeId,
        ),
        readFlags: readFlags,
      );
    }
    _collectNodeReferenceDiagnostics(
      scenarioId: scenarioId,
      node: node,
      nodeId: nodeId,
      actionKind: actionKind,
      ref: ref,
      knownDialogueIds: knownDialogueIds,
      knownTrainerIds: knownTrainerIds,
      knownMapIds: knownMapIds,
      mapsById: mapsById,
      emittedOutcomes: emittedOutcomes,
      emittedOutcomeRefs: emittedOutcomeRefs,
      consumedOutcomes: consumedOutcomes,
      producedFlags: producedFlags,
      completedSteps: completedSteps,
      declaredOutcomeIds: declaredOutcomeIds,
      diagnostics: diagnostics,
    );
  }

  if (sourceNodeIds.isEmpty) {
    diagnostics.add(
      NarrativeValidationDiagnostic(
        severity: NarrativeValidationSeverity.error,
        kind: NarrativeValidationDiagnosticKind.scenarioGraphHasNoSource,
        message: 'Scenario "$scenarioId" has no runtime source node.',
        path: 'scenarios.$scenarioId.nodes',
        scenarioId: scenarioId,
      ),
    );
  }

  _collectGraphDiagnostics(
    scenario: scenario,
    scenarioId: scenarioId,
    nodeIds: nodeIds,
    sourceNodeIds: sourceNodeIds,
    diagnostics: diagnostics,
  );
  _collectDeclaredOutcomeDiagnostics(
    declaredOutcomeRefs: declaredOutcomeRefs,
    emittedOutcomeRefs: emittedOutcomeRefs,
    diagnostics: diagnostics,
  );
}

void _collectNodeReferenceDiagnostics({
  required String scenarioId,
  required ScenarioNode node,
  required String nodeId,
  required String actionKind,
  required _NarrativeRef ref,
  required Set<String> knownDialogueIds,
  required Set<String> knownTrainerIds,
  required Set<String> knownMapIds,
  required Map<String, MapData> mapsById,
  required Map<String, List<_NarrativeRef>> emittedOutcomes,
  required Map<String, List<_NarrativeRef>> emittedOutcomeRefs,
  required Map<String, List<_NarrativeRef>> consumedOutcomes,
  required Map<String, List<_NarrativeRef>> producedFlags,
  required Map<String, List<_NarrativeRef>> completedSteps,
  required Set<String> declaredOutcomeIds,
  required List<NarrativeValidationDiagnostic> diagnostics,
}) {
  if (node.type == ScenarioNodeType.dialogue ||
      actionKind == _actionOpenDialogue) {
    final dialogueId = node.binding.dialogueId?.trim() ?? '';
    if (dialogueId.isNotEmpty && !knownDialogueIds.contains(dialogueId)) {
      diagnostics.add(
        NarrativeValidationDiagnostic(
          severity: NarrativeValidationSeverity.error,
          kind: NarrativeValidationDiagnosticKind
              .openDialogueReferencesUnknownDialogue,
          message: 'Node "$nodeId" references unknown dialogue "$dialogueId".',
          path: '${ref.path}.binding.dialogueId',
          referencedId: dialogueId,
          scenarioId: scenarioId,
          nodeId: nodeId,
        ),
      );
    }
  }

  switch (actionKind) {
    case _sourceEntityInteract:
      _collectSourceEntityInteractDiagnostics(
        node: node,
        nodeId: nodeId,
        ref: ref,
        knownMapIds: knownMapIds,
        mapsById: mapsById,
        diagnostics: diagnostics,
      );
    case _sourceOutcome:
      _addRef(consumedOutcomes, node.binding.outcomeId, ref);
    case _actionEmitOutcome:
      final outcomeId = node.binding.outcomeId?.trim() ?? '';
      _addRef(emittedOutcomes, outcomeId, ref);
      _addRef(emittedOutcomeRefs, outcomeId, ref);
      if (outcomeId.isNotEmpty && !declaredOutcomeIds.contains(outcomeId)) {
        diagnostics.add(
          NarrativeValidationDiagnostic(
            severity: NarrativeValidationSeverity.warning,
            kind: NarrativeValidationDiagnosticKind.emitOutcomeNotDeclared,
            message: 'Outcome "$outcomeId" is emitted but not declared by '
                'scenario "$scenarioId".',
            path: '${ref.path}.binding.outcomeId',
            referencedId: outcomeId,
            scenarioId: scenarioId,
            nodeId: nodeId,
          ),
        );
      }
    case _actionSetFlag:
      _addRef(producedFlags, node.binding.flagName, ref);
    case _actionCompleteStep:
      _addRef(completedSteps, node.payload.params[_stepIdParam], ref);
    case _actionStartTrainerBattle:
      _collectTrainerBattleDiagnostics(
        node: node,
        nodeId: nodeId,
        ref: ref,
        knownTrainerIds: knownTrainerIds,
        diagnostics: diagnostics,
      );
  }
}

void _collectWorldRulePredicateDiagnostics(
  MapEntityRuntimePredicate predicate, {
  required String path,
  required String mapId,
  required String entityId,
  required List<NarrativeValidationDiagnostic> diagnostics,
}) {
  if (predicate.refId.trim().isNotEmpty) {
    return;
  }
  diagnostics.add(
    NarrativeValidationDiagnostic(
      severity: NarrativeValidationSeverity.error,
      kind: NarrativeValidationDiagnosticKind.worldRulePredicateEmptyRefId,
      message: 'World rule predicate "${predicate.kind.name}" has an empty '
          'refId.',
      path: '$path.refId',
      mapId: mapId,
      entityId: entityId,
    ),
  );
}

void _collectSourceEntityInteractDiagnostics({
  required ScenarioNode node,
  required String nodeId,
  required _NarrativeRef ref,
  required Set<String> knownMapIds,
  required Map<String, MapData> mapsById,
  required List<NarrativeValidationDiagnostic> diagnostics,
}) {
  final mapId = node.binding.mapId?.trim() ?? '';
  final entityId = node.binding.entityId?.trim() ?? '';
  if (mapId.isNotEmpty && !knownMapIds.contains(mapId)) {
    diagnostics.add(
      NarrativeValidationDiagnostic(
        severity: NarrativeValidationSeverity.error,
        kind: NarrativeValidationDiagnosticKind
            .sourceEntityInteractReferencesUnknownMap,
        message:
            'Source entityInteract node "$nodeId" references unknown map "$mapId".',
        path: '${ref.path}.binding.mapId',
        referencedId: mapId,
        scenarioId: ref.scenarioId,
        nodeId: ref.nodeId,
        mapId: mapId,
        entityId: entityId.isEmpty ? null : entityId,
      ),
    );
    return;
  }
  final map = mapsById[mapId];
  if (map == null || entityId.isEmpty) {
    return;
  }
  final entityExists =
      map.entities.any((entity) => entity.id.trim() == entityId);
  if (!entityExists) {
    diagnostics.add(
      NarrativeValidationDiagnostic(
        severity: NarrativeValidationSeverity.error,
        kind: NarrativeValidationDiagnosticKind
            .sourceEntityInteractReferencesUnknownEntity,
        message: 'Source entityInteract node "$nodeId" references unknown '
            'entity "$entityId" on map "$mapId".',
        path: '${ref.path}.binding.entityId',
        referencedId: entityId,
        scenarioId: ref.scenarioId,
        nodeId: ref.nodeId,
        mapId: mapId,
        entityId: entityId,
      ),
    );
  }
}

void _collectTrainerBattleDiagnostics({
  required ScenarioNode node,
  required String nodeId,
  required _NarrativeRef ref,
  required Set<String> knownTrainerIds,
  required List<NarrativeValidationDiagnostic> diagnostics,
}) {
  final trainerId = node.binding.trainerId?.trim() ?? '';
  final npcEntityId = node.binding.entityId?.trim() ?? '';
  if (trainerId.isEmpty) {
    diagnostics.add(
      NarrativeValidationDiagnostic(
        severity: NarrativeValidationSeverity.error,
        kind: NarrativeValidationDiagnosticKind
            .startTrainerBattleMissingTrainerId,
        message: 'startTrainerBattle node "$nodeId" has no trainerId.',
        path: '${ref.path}.binding.trainerId',
        scenarioId: ref.scenarioId,
        nodeId: ref.nodeId,
      ),
    );
  } else if (!knownTrainerIds.contains(trainerId)) {
    diagnostics.add(
      NarrativeValidationDiagnostic(
        severity: NarrativeValidationSeverity.error,
        kind: NarrativeValidationDiagnosticKind
            .startTrainerBattleReferencesUnknownTrainer,
        message:
            'startTrainerBattle node "$nodeId" references unknown trainer "$trainerId".',
        path: '${ref.path}.binding.trainerId',
        referencedId: trainerId,
        scenarioId: ref.scenarioId,
        nodeId: ref.nodeId,
      ),
    );
  }
  if (npcEntityId.isEmpty) {
    diagnostics.add(
      NarrativeValidationDiagnostic(
        severity: NarrativeValidationSeverity.error,
        kind: NarrativeValidationDiagnosticKind
            .startTrainerBattleMissingNpcEntityId,
        message: 'startTrainerBattle node "$nodeId" has no npcEntityId.',
        path: '${ref.path}.binding.entityId',
        scenarioId: ref.scenarioId,
        nodeId: ref.nodeId,
      ),
    );
  }
  if (node.payload.params.containsKey(_battleIdParam) &&
      (node.payload.params[_battleIdParam]?.trim() ?? '').isEmpty) {
    diagnostics.add(
      NarrativeValidationDiagnostic(
        severity: NarrativeValidationSeverity.error,
        kind: NarrativeValidationDiagnosticKind.startTrainerBattleBlankBattleId,
        message: 'startTrainerBattle node "$nodeId" has a blank battleId.',
        path: '${ref.path}.payload.params.$_battleIdParam',
        scenarioId: ref.scenarioId,
        nodeId: ref.nodeId,
      ),
    );
  }
}

void _collectGraphDiagnostics({
  required ScenarioAsset scenario,
  required String scenarioId,
  required Set<String> nodeIds,
  required Set<String> sourceNodeIds,
  required List<NarrativeValidationDiagnostic> diagnostics,
}) {
  final outgoing = <String, List<String>>{};
  for (final edge in scenario.edges) {
    final edgeId = edge.id.trim();
    final fromNodeId = edge.fromNodeId.trim();
    final toNodeId = edge.toNodeId.trim();
    if (fromNodeId.isNotEmpty && !nodeIds.contains(fromNodeId)) {
      diagnostics.add(_unknownNodeDiagnostic(
        scenarioId: scenarioId,
        edgeId: edgeId,
        fieldName: 'fromNodeId',
        referencedId: fromNodeId,
      ));
    }
    if (toNodeId.isNotEmpty && !nodeIds.contains(toNodeId)) {
      diagnostics.add(_unknownNodeDiagnostic(
        scenarioId: scenarioId,
        edgeId: edgeId,
        fieldName: 'toNodeId',
        referencedId: toNodeId,
      ));
    }
    if (nodeIds.contains(fromNodeId) && nodeIds.contains(toNodeId)) {
      outgoing.putIfAbsent(fromNodeId, () => <String>[]).add(toNodeId);
    }
  }

  final seeds = sourceNodeIds.isNotEmpty
      ? sourceNodeIds
      : {
          if (nodeIds.contains(scenario.entryNodeId.trim()))
            scenario.entryNodeId.trim(),
        };
  final reachable = <String>{};
  final queue = <String>[...seeds];
  while (queue.isNotEmpty) {
    final current = queue.removeAt(0);
    if (!reachable.add(current)) {
      continue;
    }
    queue.addAll(outgoing[current] ?? const <String>[]);
  }

  for (final nodeId in nodeIds) {
    if (!reachable.contains(nodeId)) {
      diagnostics.add(
        NarrativeValidationDiagnostic(
          severity: NarrativeValidationSeverity.warning,
          kind:
              NarrativeValidationDiagnosticKind.scenarioGraphHasUnreachableNode,
          message: 'Scenario "$scenarioId" has unreachable node "$nodeId".',
          path: 'scenarios.$scenarioId.nodes.$nodeId',
          referencedId: nodeId,
          scenarioId: scenarioId,
          nodeId: nodeId,
        ),
      );
    }
  }
}

NarrativeValidationDiagnostic _unknownNodeDiagnostic({
  required String scenarioId,
  required String edgeId,
  required String fieldName,
  required String referencedId,
}) {
  return NarrativeValidationDiagnostic(
    severity: NarrativeValidationSeverity.error,
    kind: NarrativeValidationDiagnosticKind.scenarioNodeReferencesUnknownNode,
    message: 'Scenario "$scenarioId" edge "$edgeId" references unknown node '
        '"$referencedId".',
    path: 'scenarios.$scenarioId.edges.$edgeId.$fieldName',
    referencedId: referencedId,
    scenarioId: scenarioId,
  );
}

void _collectOutcomeMismatchDiagnostics({
  required Map<String, List<_NarrativeRef>> emittedOutcomes,
  required Map<String, List<_NarrativeRef>> consumedOutcomes,
  required List<NarrativeValidationDiagnostic> diagnostics,
}) {
  for (final entry in consumedOutcomes.entries) {
    if (emittedOutcomes.containsKey(entry.key)) {
      continue;
    }
    for (final ref in entry.value) {
      diagnostics.add(
        NarrativeValidationDiagnostic(
          severity: NarrativeValidationSeverity.warning,
          kind: NarrativeValidationDiagnosticKind
              .sourceOutcomeWithoutMatchingEmitOutcome,
          message: 'Outcome "${entry.key}" is consumed but never emitted.',
          path: '${ref.path}.binding.outcomeId',
          referencedId: entry.key,
          scenarioId: ref.scenarioId,
          nodeId: ref.nodeId,
        ),
      );
    }
  }
  for (final entry in emittedOutcomes.entries) {
    if (consumedOutcomes.containsKey(entry.key)) {
      continue;
    }
    for (final ref in entry.value) {
      diagnostics.add(
        NarrativeValidationDiagnostic(
          severity: NarrativeValidationSeverity.warning,
          kind: NarrativeValidationDiagnosticKind
              .emitOutcomeWithoutMatchingSourceOutcome,
          message: 'Outcome "${entry.key}" is emitted but never consumed.',
          path: '${ref.path}.binding.outcomeId',
          referencedId: entry.key,
          scenarioId: ref.scenarioId,
          nodeId: ref.nodeId,
        ),
      );
    }
  }
}

void _collectDeclaredOutcomeDiagnostics({
  required Map<String, List<_NarrativeRef>> declaredOutcomeRefs,
  required Map<String, List<_NarrativeRef>> emittedOutcomeRefs,
  required List<NarrativeValidationDiagnostic> diagnostics,
}) {
  for (final entry in declaredOutcomeRefs.entries) {
    if (emittedOutcomeRefs.containsKey(entry.key)) {
      continue;
    }
    for (final ref in entry.value) {
      diagnostics.add(
        NarrativeValidationDiagnostic(
          severity: NarrativeValidationSeverity.warning,
          kind: NarrativeValidationDiagnosticKind.declaredOutcomeNeverEmitted,
          message: 'Outcome "${entry.key}" is declared but never emitted.',
          path: ref.path,
          referencedId: entry.key,
          scenarioId: ref.scenarioId,
        ),
      );
    }
  }
}

void _collectReadWriteMismatchDiagnostics({
  required Map<String, List<_NarrativeRef>> produced,
  required Map<String, List<_NarrativeRef>> read,
  required NarrativeValidationDiagnosticKind producedNeverReadKind,
  required NarrativeValidationDiagnosticKind readNeverProducedKind,
  required String Function(String id) producedNeverReadMessage,
  required String Function(String id) readNeverProducedMessage,
  required List<NarrativeValidationDiagnostic> diagnostics,
}) {
  for (final entry in read.entries) {
    if (produced.containsKey(entry.key)) {
      continue;
    }
    for (final ref in entry.value) {
      diagnostics.add(
        NarrativeValidationDiagnostic(
          severity: NarrativeValidationSeverity.warning,
          kind: readNeverProducedKind,
          message: readNeverProducedMessage(entry.key),
          path: ref.path,
          referencedId: entry.key,
          scenarioId: ref.scenarioId,
          nodeId: ref.nodeId,
          mapId: ref.mapId,
          entityId: ref.entityId,
        ),
      );
    }
  }
  for (final entry in produced.entries) {
    if (read.containsKey(entry.key)) {
      continue;
    }
    for (final ref in entry.value) {
      diagnostics.add(
        NarrativeValidationDiagnostic(
          severity: NarrativeValidationSeverity.warning,
          kind: producedNeverReadKind,
          message: producedNeverReadMessage(entry.key),
          path: ref.path,
          referencedId: entry.key,
          scenarioId: ref.scenarioId,
          nodeId: ref.nodeId,
          mapId: ref.mapId,
          entityId: ref.entityId,
        ),
      );
    }
  }
}

void _collectScriptConditionReads(
  ScriptCondition condition, {
  required _NarrativeRef ref,
  required Map<String, List<_NarrativeRef>> readFlags,
}) {
  switch (condition.type) {
    case ScriptConditionType.flagIsSet:
    case ScriptConditionType.flagIsUnset:
      _addRef(readFlags, condition.params[ScriptConditionParams.flagName], ref);
    case ScriptConditionType.allOf:
    case ScriptConditionType.anyOf:
    case ScriptConditionType.not:
    case ScriptConditionType.variableEquals:
    case ScriptConditionType.variableGreaterThan:
    case ScriptConditionType.variableLessThan:
    case ScriptConditionType.fieldAbilityUnlocked:
    case ScriptConditionType.partyHasMove:
    case ScriptConditionType.partyHasUsableMove:
    case ScriptConditionType.eventIsConsumed:
    case ScriptConditionType.playerOnMap:
      break;
  }
  for (var i = 0; i < condition.children.length; i++) {
    _collectScriptConditionReads(
      condition.children[i],
      ref: ref.withPath('${ref.path}.children.$i'),
      readFlags: readFlags,
    );
  }
}

void _collectRuntimePredicateReads(
  MapEntityRuntimePredicate predicate, {
  required _NarrativeRef ref,
  required Map<String, List<_NarrativeRef>> readFlags,
  required Map<String, List<_NarrativeRef>> readSteps,
}) {
  switch (predicate.kind) {
    case MapEntityRuntimePredicateKind.storyFlagSet:
    case MapEntityRuntimePredicateKind.storyFlagUnset:
      _addRef(readFlags, predicate.refId, ref);
    case MapEntityRuntimePredicateKind.stepCompleted:
    case MapEntityRuntimePredicateKind.stepNotCompleted:
      _addRef(readSteps, predicate.refId, ref);
    case MapEntityRuntimePredicateKind.chapterCompleted:
    case MapEntityRuntimePredicateKind.chapterNotCompleted:
    case MapEntityRuntimePredicateKind.cutsceneCompleted:
    case MapEntityRuntimePredicateKind.cutsceneNotCompleted:
      break;
  }
}

void _addRef(
  Map<String, List<_NarrativeRef>> target,
  String? rawId,
  _NarrativeRef ref,
) {
  final id = rawId?.trim() ?? '';
  if (id.isEmpty) {
    return;
  }
  target.putIfAbsent(id, () => <_NarrativeRef>[]).add(ref);
}

Set<String> _nonBlankIds(Iterable<String> ids) {
  return {
    for (final id in ids)
      if (id.trim().isNotEmpty) id.trim(),
  };
}

String _actionKind(ScenarioNode node) => node.payload.actionKind?.trim() ?? '';

int _compareDiagnostics(
  NarrativeValidationDiagnostic a,
  NarrativeValidationDiagnostic b,
) {
  return _compareValues([
    a.severity.index.compareTo(b.severity.index),
    a.kind.name.compareTo(b.kind.name),
    a.path.compareTo(b.path),
    (a.referencedId ?? '').compareTo(b.referencedId ?? ''),
    (a.scenarioId ?? '').compareTo(b.scenarioId ?? ''),
    (a.nodeId ?? '').compareTo(b.nodeId ?? ''),
    (a.mapId ?? '').compareTo(b.mapId ?? ''),
    (a.entityId ?? '').compareTo(b.entityId ?? ''),
  ]);
}

int _compareValues(List<int> values) {
  for (final value in values) {
    if (value != 0) {
      return value;
    }
  }
  return 0;
}

bool _diagnosticsEqualInOrder(
  List<NarrativeValidationDiagnostic> a,
  List<NarrativeValidationDiagnostic> b,
) {
  if (a.length != b.length) {
    return false;
  }
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) {
      return false;
    }
  }
  return true;
}

@immutable
final class _NarrativeRef {
  const _NarrativeRef({
    required this.path,
    this.scenarioId,
    this.nodeId,
    this.mapId,
    this.entityId,
  });

  final String path;
  final String? scenarioId;
  final String? nodeId;
  final String? mapId;
  final String? entityId;

  _NarrativeRef withPath(String nextPath) {
    return _NarrativeRef(
      path: nextPath,
      scenarioId: scenarioId,
      nodeId: nodeId,
      mapId: mapId,
      entityId: entityId,
    );
  }
}
