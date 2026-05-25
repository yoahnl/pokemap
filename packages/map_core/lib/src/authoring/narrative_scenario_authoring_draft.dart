import 'package:meta/meta.dart' show immutable;

import '../models/scenario_asset.dart';

const String _sourceMapEnter = 'sourceMapEnter';
const String _sourceTriggerEnter = 'sourceTriggerEnter';
const String _sourceEntityInteract = 'sourceEntityInteract';
const String _sourceOutcome = 'sourceOutcome';
const String _actionSetFlag = 'setFlag';
const String _actionCompleteStep = 'completeStep';
const String _actionEmitOutcome = 'emitOutcome';
const String _actionStartTrainerBattle = 'startTrainerBattle';
const String _stepIdParam = 'stepId';
const String _battleIdParam = 'battleId';

enum NarrativeScenarioAuthoringSourceKind {
  mapEnter,
  triggerEnter,
  entityInteract,
  outcomeReceived,
}

enum NarrativeScenarioAuthoringActionKind {
  setFlag,
  completeStep,
  emitOutcome,
  startTrainerBattle,
}

enum NarrativeScenarioAuthoringDraftDiagnosticSeverity {
  error,
  warning,
}

enum NarrativeScenarioAuthoringDraftDiagnosticKind {
  emptyScenarioId,
  emptyScenarioName,
  missingSource,
  missingSourceReference,
  emptyActionReference,
  emitOutcomeNotDeclared,
  declaredOutcomeNeverEmitted,
  unsupportedDraftShape,
}

@immutable
final class NarrativeScenarioAuthoringDraft {
  NarrativeScenarioAuthoringDraft({
    required this.scenarioId,
    required this.name,
    this.description = '',
    this.scope = ScenarioScope.localEventFlow,
    required this.source,
    required List<NarrativeScenarioAuthoringActionDraft> actions,
    required List<String> declaredOutcomes,
    Map<String, String> metadata = const {},
  })  : actions =
            List<NarrativeScenarioAuthoringActionDraft>.unmodifiable(actions),
        declaredOutcomes = List<String>.unmodifiable(declaredOutcomes),
        metadata = Map<String, String>.unmodifiable(metadata);

  final String scenarioId;
  final String name;
  final String description;
  final ScenarioScope scope;
  final NarrativeScenarioAuthoringSourceDraft? source;
  final List<NarrativeScenarioAuthoringActionDraft> actions;
  final List<String> declaredOutcomes;
  final Map<String, String> metadata;
}

@immutable
final class NarrativeScenarioAuthoringSourceDraft {
  const NarrativeScenarioAuthoringSourceDraft.mapEnter({
    required this.mapId,
  })  : kind = NarrativeScenarioAuthoringSourceKind.mapEnter,
        triggerId = '',
        entityId = '',
        outcomeId = '';

  const NarrativeScenarioAuthoringSourceDraft.triggerEnter({
    required this.mapId,
    required this.triggerId,
  })  : kind = NarrativeScenarioAuthoringSourceKind.triggerEnter,
        entityId = '',
        outcomeId = '';

  const NarrativeScenarioAuthoringSourceDraft.entityInteract({
    required this.mapId,
    required this.entityId,
  })  : kind = NarrativeScenarioAuthoringSourceKind.entityInteract,
        triggerId = '',
        outcomeId = '';

  const NarrativeScenarioAuthoringSourceDraft.outcomeReceived({
    required this.outcomeId,
  })  : kind = NarrativeScenarioAuthoringSourceKind.outcomeReceived,
        mapId = '',
        triggerId = '',
        entityId = '';

  final NarrativeScenarioAuthoringSourceKind kind;
  final String mapId;
  final String triggerId;
  final String entityId;
  final String outcomeId;
}

@immutable
final class NarrativeScenarioAuthoringActionDraft {
  const NarrativeScenarioAuthoringActionDraft.setFlag({
    required this.flagName,
  })  : kind = NarrativeScenarioAuthoringActionKind.setFlag,
        stepId = '',
        outcomeId = '',
        battleId = '',
        trainerId = '',
        npcEntityId = '';

  const NarrativeScenarioAuthoringActionDraft.completeStep({
    required this.stepId,
  })  : kind = NarrativeScenarioAuthoringActionKind.completeStep,
        flagName = '',
        outcomeId = '',
        battleId = '',
        trainerId = '',
        npcEntityId = '';

  const NarrativeScenarioAuthoringActionDraft.emitOutcome({
    required this.outcomeId,
  })  : kind = NarrativeScenarioAuthoringActionKind.emitOutcome,
        flagName = '',
        stepId = '',
        battleId = '',
        trainerId = '',
        npcEntityId = '';

  const NarrativeScenarioAuthoringActionDraft.startTrainerBattle({
    required this.trainerId,
    required this.battleId,
    this.npcEntityId = '',
  })  : kind = NarrativeScenarioAuthoringActionKind.startTrainerBattle,
        flagName = '',
        stepId = '',
        outcomeId = '';

  final NarrativeScenarioAuthoringActionKind kind;
  final String flagName;
  final String stepId;
  final String outcomeId;
  final String battleId;
  final String trainerId;
  final String npcEntityId;
}

@immutable
final class NarrativeScenarioAuthoringDraftDiagnostic {
  const NarrativeScenarioAuthoringDraftDiagnostic({
    required this.severity,
    required this.kind,
    required this.message,
    required this.path,
    this.referencedId,
  });

  final NarrativeScenarioAuthoringDraftDiagnosticSeverity severity;
  final NarrativeScenarioAuthoringDraftDiagnosticKind kind;
  final String message;
  final String path;
  final String? referencedId;
}

List<NarrativeScenarioAuthoringDraftDiagnostic>
    validateNarrativeScenarioAuthoringDraft(
  NarrativeScenarioAuthoringDraft draft,
) {
  final diagnostics = <NarrativeScenarioAuthoringDraftDiagnostic>[];
  final declaredOutcomeIds = _dedupeTrimmed(draft.declaredOutcomes).toSet();
  final emittedOutcomeIds = <String>{};

  if (draft.scenarioId.trim().isEmpty) {
    diagnostics.add(
      const NarrativeScenarioAuthoringDraftDiagnostic(
        severity: NarrativeScenarioAuthoringDraftDiagnosticSeverity.error,
        kind: NarrativeScenarioAuthoringDraftDiagnosticKind.emptyScenarioId,
        message: 'Scenario id is required.',
        path: 'scenarioId',
      ),
    );
  }
  if (draft.name.trim().isEmpty) {
    diagnostics.add(
      const NarrativeScenarioAuthoringDraftDiagnostic(
        severity: NarrativeScenarioAuthoringDraftDiagnosticSeverity.error,
        kind: NarrativeScenarioAuthoringDraftDiagnosticKind.emptyScenarioName,
        message: 'Scenario name is required.',
        path: 'name',
      ),
    );
  }

  final source = draft.source;
  if (source == null) {
    diagnostics.add(
      const NarrativeScenarioAuthoringDraftDiagnostic(
        severity: NarrativeScenarioAuthoringDraftDiagnosticSeverity.error,
        kind: NarrativeScenarioAuthoringDraftDiagnosticKind.missingSource,
        message: 'A scenario authoring draft requires one runtime source.',
        path: 'source',
      ),
    );
  } else {
    _validateSource(source, diagnostics);
  }

  for (var index = 0; index < draft.actions.length; index++) {
    final action = draft.actions[index];
    _validateAction(
      action,
      source: source,
      index: index,
      diagnostics: diagnostics,
    );
    final emittedOutcomeId = action.outcomeId.trim();
    if (action.kind == NarrativeScenarioAuthoringActionKind.emitOutcome &&
        emittedOutcomeId.isNotEmpty) {
      emittedOutcomeIds.add(emittedOutcomeId);
      if (!declaredOutcomeIds.contains(emittedOutcomeId)) {
        diagnostics.add(
          NarrativeScenarioAuthoringDraftDiagnostic(
            severity: NarrativeScenarioAuthoringDraftDiagnosticSeverity.warning,
            kind: NarrativeScenarioAuthoringDraftDiagnosticKind
                .emitOutcomeNotDeclared,
            message: 'Outcome "$emittedOutcomeId" is emitted but not declared.',
            path: 'actions[$index].outcomeId',
            referencedId: emittedOutcomeId,
          ),
        );
      }
    }
  }

  for (final declaredOutcomeId in declaredOutcomeIds) {
    if (!emittedOutcomeIds.contains(declaredOutcomeId)) {
      diagnostics.add(
        NarrativeScenarioAuthoringDraftDiagnostic(
          severity: NarrativeScenarioAuthoringDraftDiagnosticSeverity.warning,
          kind: NarrativeScenarioAuthoringDraftDiagnosticKind
              .declaredOutcomeNeverEmitted,
          message: 'Declared outcome "$declaredOutcomeId" is never emitted.',
          path: 'declaredOutcomes',
          referencedId: declaredOutcomeId,
        ),
      );
    }
  }

  return List<NarrativeScenarioAuthoringDraftDiagnostic>.unmodifiable(
    diagnostics,
  );
}

ScenarioAsset compileNarrativeScenarioAuthoringDraftToScenarioAsset(
  NarrativeScenarioAuthoringDraft draft,
) {
  final blockingDiagnostics = validateNarrativeScenarioAuthoringDraft(draft)
      .where((diagnostic) =>
          diagnostic.severity ==
          NarrativeScenarioAuthoringDraftDiagnosticSeverity.error)
      .toList(growable: false);
  if (blockingDiagnostics.isNotEmpty) {
    throw StateError(
      'Cannot compile invalid narrative scenario authoring draft: '
      '${blockingDiagnostics.map((diagnostic) => diagnostic.path).join(', ')}',
    );
  }

  final scenarioId = draft.scenarioId.trim();
  final source = draft.source!;
  final nodes = <ScenarioNode>[
    ScenarioNode(
      id: _startNodeId(scenarioId),
      type: ScenarioNodeType.start,
      title: 'Start',
      position: const ScenarioNodePosition(x: 0, y: 0),
    ),
    _compileSourceNode(scenarioId, source),
  ];

  for (var index = 0; index < draft.actions.length; index++) {
    nodes.add(
      _compileActionNode(
        scenarioId: scenarioId,
        index: index,
        action: draft.actions[index],
        source: source,
      ),
    );
  }

  nodes.add(
    ScenarioNode(
      id: _endNodeId(scenarioId),
      type: ScenarioNodeType.end,
      title: 'End',
      position: ScenarioNodePosition(
        x: _nodeX(draft.actions.length + 2),
        y: 0,
      ),
    ),
  );

  return ScenarioAsset(
    id: scenarioId,
    name: draft.name.trim(),
    description: draft.description.trim(),
    scope: draft.scope,
    entryNodeId: _startNodeId(scenarioId),
    declaredOutcomes: _dedupeTrimmed(draft.declaredOutcomes),
    nodes: nodes,
    edges: _compileLinearEdges(
      scenarioId: scenarioId,
      actionCount: draft.actions.length,
    ),
    metadata: draft.metadata,
  );
}

void _validateSource(
  NarrativeScenarioAuthoringSourceDraft source,
  List<NarrativeScenarioAuthoringDraftDiagnostic> diagnostics,
) {
  switch (source.kind) {
    case NarrativeScenarioAuthoringSourceKind.mapEnter:
      _requireSourceRef(
        source.mapId,
        path: 'source.mapId',
        label: 'mapId',
        diagnostics: diagnostics,
      );
    case NarrativeScenarioAuthoringSourceKind.triggerEnter:
      _requireSourceRef(
        source.mapId,
        path: 'source.mapId',
        label: 'mapId',
        diagnostics: diagnostics,
      );
      _requireSourceRef(
        source.triggerId,
        path: 'source.triggerId',
        label: 'triggerId',
        diagnostics: diagnostics,
      );
    case NarrativeScenarioAuthoringSourceKind.entityInteract:
      _requireSourceRef(
        source.mapId,
        path: 'source.mapId',
        label: 'mapId',
        diagnostics: diagnostics,
      );
      _requireSourceRef(
        source.entityId,
        path: 'source.entityId',
        label: 'entityId',
        diagnostics: diagnostics,
      );
    case NarrativeScenarioAuthoringSourceKind.outcomeReceived:
      _requireSourceRef(
        source.outcomeId,
        path: 'source.outcomeId',
        label: 'outcomeId',
        diagnostics: diagnostics,
      );
  }
}

void _validateAction(
  NarrativeScenarioAuthoringActionDraft action, {
  required NarrativeScenarioAuthoringSourceDraft? source,
  required int index,
  required List<NarrativeScenarioAuthoringDraftDiagnostic> diagnostics,
}) {
  switch (action.kind) {
    case NarrativeScenarioAuthoringActionKind.setFlag:
      _requireActionRef(
        action.flagName,
        path: 'actions[$index].flagName',
        label: 'flagName',
        diagnostics: diagnostics,
      );
    case NarrativeScenarioAuthoringActionKind.completeStep:
      _requireActionRef(
        action.stepId,
        path: 'actions[$index].stepId',
        label: 'stepId',
        diagnostics: diagnostics,
      );
    case NarrativeScenarioAuthoringActionKind.emitOutcome:
      _requireActionRef(
        action.outcomeId,
        path: 'actions[$index].outcomeId',
        label: 'outcomeId',
        diagnostics: diagnostics,
      );
    case NarrativeScenarioAuthoringActionKind.startTrainerBattle:
      _requireActionRef(
        action.trainerId,
        path: 'actions[$index].trainerId',
        label: 'trainerId',
        diagnostics: diagnostics,
      );
      _requireActionRef(
        action.battleId,
        path: 'actions[$index].battleId',
        label: 'battleId',
        diagnostics: diagnostics,
      );
      final explicitNpcEntityId = action.npcEntityId.trim();
      final sourceNpcEntityId =
          source?.kind == NarrativeScenarioAuthoringSourceKind.entityInteract
              ? source?.entityId.trim() ?? ''
              : '';
      if (explicitNpcEntityId.isEmpty && sourceNpcEntityId.isEmpty) {
        _requireActionRef(
          '',
          path: 'actions[$index].npcEntityId',
          label: 'npcEntityId',
          diagnostics: diagnostics,
        );
      }
  }
}

void _requireSourceRef(
  String value, {
  required String path,
  required String label,
  required List<NarrativeScenarioAuthoringDraftDiagnostic> diagnostics,
}) {
  if (value.trim().isNotEmpty) {
    return;
  }
  diagnostics.add(
    NarrativeScenarioAuthoringDraftDiagnostic(
      severity: NarrativeScenarioAuthoringDraftDiagnosticSeverity.error,
      kind:
          NarrativeScenarioAuthoringDraftDiagnosticKind.missingSourceReference,
      message: 'Source reference "$label" is required.',
      path: path,
    ),
  );
}

void _requireActionRef(
  String value, {
  required String path,
  required String label,
  required List<NarrativeScenarioAuthoringDraftDiagnostic> diagnostics,
}) {
  if (value.trim().isNotEmpty) {
    return;
  }
  diagnostics.add(
    NarrativeScenarioAuthoringDraftDiagnostic(
      severity: NarrativeScenarioAuthoringDraftDiagnosticSeverity.error,
      kind: NarrativeScenarioAuthoringDraftDiagnosticKind.emptyActionReference,
      message: 'Action reference "$label" is required.',
      path: path,
    ),
  );
}

ScenarioNode _compileSourceNode(
  String scenarioId,
  NarrativeScenarioAuthoringSourceDraft source,
) {
  final binding = switch (source.kind) {
    NarrativeScenarioAuthoringSourceKind.mapEnter => ScenarioNodeBinding(
        mapId: source.mapId.trim(),
      ),
    NarrativeScenarioAuthoringSourceKind.triggerEnter => ScenarioNodeBinding(
        mapId: source.mapId.trim(),
        triggerId: source.triggerId.trim(),
      ),
    NarrativeScenarioAuthoringSourceKind.entityInteract => ScenarioNodeBinding(
        mapId: source.mapId.trim(),
        entityId: source.entityId.trim(),
      ),
    NarrativeScenarioAuthoringSourceKind.outcomeReceived => ScenarioNodeBinding(
        outcomeId: source.outcomeId.trim(),
      ),
  };
  return ScenarioNode(
    id: _sourceNodeId(scenarioId),
    type: ScenarioNodeType.reference,
    title: _sourceTitle(source.kind),
    position: ScenarioNodePosition(x: _nodeX(1), y: 0),
    binding: binding,
    payload: ScenarioNodePayload(
      actionKind: _sourceActionKind(source.kind),
    ),
  );
}

ScenarioNode _compileActionNode({
  required String scenarioId,
  required int index,
  required NarrativeScenarioAuthoringActionDraft action,
  required NarrativeScenarioAuthoringSourceDraft source,
}) {
  final position = ScenarioNodePosition(x: _nodeX(index + 2), y: 0);
  switch (action.kind) {
    case NarrativeScenarioAuthoringActionKind.setFlag:
      return ScenarioNode(
        id: _actionNodeId(scenarioId, index),
        type: ScenarioNodeType.action,
        title: 'Set flag',
        position: position,
        binding: ScenarioNodeBinding(flagName: action.flagName.trim()),
        payload: const ScenarioNodePayload(actionKind: _actionSetFlag),
      );
    case NarrativeScenarioAuthoringActionKind.completeStep:
      return ScenarioNode(
        id: _actionNodeId(scenarioId, index),
        type: ScenarioNodeType.action,
        title: 'Complete step',
        position: position,
        payload: ScenarioNodePayload(
          actionKind: _actionCompleteStep,
          params: {_stepIdParam: action.stepId.trim()},
        ),
      );
    case NarrativeScenarioAuthoringActionKind.emitOutcome:
      return ScenarioNode(
        id: _actionNodeId(scenarioId, index),
        type: ScenarioNodeType.action,
        title: 'Emit outcome',
        position: position,
        binding: ScenarioNodeBinding(outcomeId: action.outcomeId.trim()),
        payload: const ScenarioNodePayload(actionKind: _actionEmitOutcome),
      );
    case NarrativeScenarioAuthoringActionKind.startTrainerBattle:
      final npcEntityId = action.npcEntityId.trim().isNotEmpty
          ? action.npcEntityId.trim()
          : source.entityId.trim();
      return ScenarioNode(
        id: _actionNodeId(scenarioId, index),
        type: ScenarioNodeType.action,
        title: 'Start trainer battle',
        position: position,
        binding: ScenarioNodeBinding(
          trainerId: action.trainerId.trim(),
          entityId: npcEntityId,
        ),
        payload: ScenarioNodePayload(
          actionKind: _actionStartTrainerBattle,
          params: {_battleIdParam: action.battleId.trim()},
        ),
      );
  }
}

List<ScenarioEdge> _compileLinearEdges({
  required String scenarioId,
  required int actionCount,
}) {
  final edges = <ScenarioEdge>[
    ScenarioEdge(
      id: '${scenarioId}__edge_start_to_source',
      fromNodeId: _startNodeId(scenarioId),
      toNodeId: _sourceNodeId(scenarioId),
      order: 0,
    ),
  ];

  if (actionCount == 0) {
    edges.add(
      ScenarioEdge(
        id: '${scenarioId}__edge_source_to_end',
        fromNodeId: _sourceNodeId(scenarioId),
        toNodeId: _endNodeId(scenarioId),
        order: 1,
      ),
    );
    return List<ScenarioEdge>.unmodifiable(edges);
  }

  edges.add(
    ScenarioEdge(
      id: '${scenarioId}__edge_source_to_action_0',
      fromNodeId: _sourceNodeId(scenarioId),
      toNodeId: _actionNodeId(scenarioId, 0),
      order: 1,
    ),
  );

  for (var index = 0; index < actionCount; index++) {
    final isLast = index == actionCount - 1;
    edges.add(
      ScenarioEdge(
        id: isLast
            ? '${scenarioId}__edge_action_${index}_to_end'
            : '${scenarioId}__edge_action_${index}_to_action_${index + 1}',
        fromNodeId: _actionNodeId(scenarioId, index),
        toNodeId: isLast
            ? _endNodeId(scenarioId)
            : _actionNodeId(scenarioId, index + 1),
        order: index + 2,
      ),
    );
  }

  return List<ScenarioEdge>.unmodifiable(edges);
}

String _sourceActionKind(NarrativeScenarioAuthoringSourceKind kind) {
  return switch (kind) {
    NarrativeScenarioAuthoringSourceKind.mapEnter => _sourceMapEnter,
    NarrativeScenarioAuthoringSourceKind.triggerEnter => _sourceTriggerEnter,
    NarrativeScenarioAuthoringSourceKind.entityInteract =>
      _sourceEntityInteract,
    NarrativeScenarioAuthoringSourceKind.outcomeReceived => _sourceOutcome,
  };
}

String _sourceTitle(NarrativeScenarioAuthoringSourceKind kind) {
  return switch (kind) {
    NarrativeScenarioAuthoringSourceKind.mapEnter => 'Map enter',
    NarrativeScenarioAuthoringSourceKind.triggerEnter => 'Trigger enter',
    NarrativeScenarioAuthoringSourceKind.entityInteract => 'Entity interact',
    NarrativeScenarioAuthoringSourceKind.outcomeReceived => 'Outcome received',
  };
}

List<String> _dedupeTrimmed(Iterable<String> values) {
  final out = <String>[];
  final seen = <String>{};
  for (final rawValue in values) {
    final value = rawValue.trim();
    if (value.isEmpty || !seen.add(value)) {
      continue;
    }
    out.add(value);
  }
  return List<String>.unmodifiable(out);
}

String _startNodeId(String scenarioId) => '${scenarioId}__start';

String _sourceNodeId(String scenarioId) => '${scenarioId}__source';

String _actionNodeId(String scenarioId, int index) =>
    '${scenarioId}__action_$index';

String _endNodeId(String scenarioId) => '${scenarioId}__end';

double _nodeX(int index) => index * 240;
