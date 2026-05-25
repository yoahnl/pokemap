import 'package:meta/meta.dart' show immutable;

import '../operations/narrative_validator.dart';

enum NarrativeAuthoringDiagnosticCategory {
  scenarioStructure,
  eventSource,
  dialogueReference,
  trainerBattleReference,
  outcomeAuthoring,
  predicateAuthoring,
  runtimeSupport,
  unknown,
}

enum NarrativeAuthoringDiagnosticActionKind {
  inspectScenario,
  selectValidReference,
  declareOutcome,
  emitOutcome,
  addOutcomeReceiver,
  fixPredicate,
  replaceUnsupportedNode,
  noAutomaticFix,
}

@immutable
final class NarrativeAuthoringDiagnosticView {
  const NarrativeAuthoringDiagnosticView({
    required this.technicalKind,
    required this.severity,
    required this.category,
    required this.title,
    required this.message,
    required this.actionHint,
    required this.actionKind,
    required this.path,
    required this.debugTechnicalLabel,
    required this.technicalMessage,
    this.referencedId,
    this.scenarioId,
    this.nodeId,
    this.mapId,
    this.entityId,
  });

  final NarrativeValidationDiagnosticKind technicalKind;
  final NarrativeValidationSeverity severity;
  final NarrativeAuthoringDiagnosticCategory category;
  final String title;
  final String message;
  final String actionHint;
  final NarrativeAuthoringDiagnosticActionKind actionKind;
  final String path;
  final String? referencedId;
  final String? scenarioId;
  final String? nodeId;
  final String? mapId;
  final String? entityId;
  final String debugTechnicalLabel;
  final String technicalMessage;

  bool get hasAutomaticFix => false;
}

List<NarrativeAuthoringDiagnosticView> buildNarrativeAuthoringDiagnosticViews(
  Iterable<NarrativeValidationDiagnostic> diagnostics,
) {
  return List<NarrativeAuthoringDiagnosticView>.unmodifiable(
    diagnostics.map(buildNarrativeAuthoringDiagnosticView),
  );
}

NarrativeAuthoringDiagnosticView buildNarrativeAuthoringDiagnosticView(
  NarrativeValidationDiagnostic diagnostic,
) {
  final template = _templateForDiagnosticKind(diagnostic.kind);
  return NarrativeAuthoringDiagnosticView(
    technicalKind: diagnostic.kind,
    severity: diagnostic.severity,
    category: template.category,
    title: template.title,
    message: template.message,
    actionHint: template.actionHint,
    actionKind: template.actionKind,
    path: diagnostic.path,
    referencedId: diagnostic.referencedId,
    scenarioId: diagnostic.scenarioId,
    nodeId: diagnostic.nodeId,
    mapId: diagnostic.mapId,
    entityId: diagnostic.entityId,
    technicalMessage: diagnostic.message,
    debugTechnicalLabel: _debugTechnicalLabel(diagnostic),
  );
}

_NarrativeAuthoringDiagnosticTemplate _templateForDiagnosticKind(
  NarrativeValidationDiagnosticKind kind,
) {
  return switch (kind) {
    NarrativeValidationDiagnosticKind.declaredOutcomeNeverEmitted =>
      const _NarrativeAuthoringDiagnosticTemplate(
        category: NarrativeAuthoringDiagnosticCategory.outcomeAuthoring,
        title: 'Outcome declared but never emitted',
        message: 'This scenario declares an outcome, but no action emits it. '
            'It cannot continue a narrative branch until it is emitted.',
        actionHint: 'Add an emitOutcome action, or remove the declaration if '
            'the outcome is not needed.',
        actionKind: NarrativeAuthoringDiagnosticActionKind.emitOutcome,
      ),
    NarrativeValidationDiagnosticKind.emitOutcomeNotDeclared =>
      const _NarrativeAuthoringDiagnosticTemplate(
        category: NarrativeAuthoringDiagnosticCategory.outcomeAuthoring,
        title: 'Outcome emitted without declaration',
        message: 'An action emits an outcome that is emitted but is not '
            'declared by this scenario.',
        actionHint: 'Declare this outcome on the scenario, or choose an '
            'existing declared outcome.',
        actionKind: NarrativeAuthoringDiagnosticActionKind.declareOutcome,
      ),
    NarrativeValidationDiagnosticKind
          .visibilityRuleConditionalMissingPredicate =>
      const _NarrativeAuthoringDiagnosticTemplate(
        category: NarrativeAuthoringDiagnosticCategory.predicateAuthoring,
        title: 'Visibility rule has no condition',
        message: 'A conditional visibility rule exists, but no predicate is '
            'defined for it.',
        actionHint: 'Choose a predicate for the visibility rule, or make the '
            'entity always visible.',
        actionKind: NarrativeAuthoringDiagnosticActionKind.fixPredicate,
      ),
    NarrativeValidationDiagnosticKind.worldRulePredicateEmptyRefId =>
      const _NarrativeAuthoringDiagnosticTemplate(
        category: NarrativeAuthoringDiagnosticCategory.predicateAuthoring,
        title: 'Predicate reference is incomplete',
        message:
            'A world rule predicate exists, but its reference id is empty.',
        actionHint: 'Select a valid predicate reference from the predicate '
            'picker.',
        actionKind: NarrativeAuthoringDiagnosticActionKind.fixPredicate,
      ),
    NarrativeValidationDiagnosticKind.scenarioChoiceNodeRuntimeUnsupported =>
      const _NarrativeAuthoringDiagnosticTemplate(
        category: NarrativeAuthoringDiagnosticCategory.runtimeSupport,
        title: 'Choice node is not runtime-supported yet',
        message: 'This choice node is present in the scenario graph, but the '
            'current runtime does not support it yet.',
        actionHint: 'Replace it with a linear V0 flow, or postpone this '
            'branching behavior.',
        actionKind:
            NarrativeAuthoringDiagnosticActionKind.replaceUnsupportedNode,
      ),
    NarrativeValidationDiagnosticKind.scenarioNodeReferencesUnknownNode =>
      const _NarrativeAuthoringDiagnosticTemplate(
        category: NarrativeAuthoringDiagnosticCategory.scenarioStructure,
        title: 'Scenario edge points to a missing node',
        message: 'A scenario edge references a node that does not exist.',
        actionHint: 'Inspect the scenario graph and reconnect the edge to an '
            'existing node.',
        actionKind: NarrativeAuthoringDiagnosticActionKind.inspectScenario,
      ),
    NarrativeValidationDiagnosticKind.scenarioGraphHasUnreachableNode =>
      const _NarrativeAuthoringDiagnosticTemplate(
        category: NarrativeAuthoringDiagnosticCategory.scenarioStructure,
        title: 'Scenario contains an unreachable node',
        message: 'A node exists in the scenario graph but cannot be reached '
            'from the runtime source.',
        actionHint: 'Connect the node to the flow, or remove it if it is not '
            'part of the scenario.',
        actionKind: NarrativeAuthoringDiagnosticActionKind.inspectScenario,
      ),
    NarrativeValidationDiagnosticKind.scenarioGraphHasNoSource =>
      const _NarrativeAuthoringDiagnosticTemplate(
        category: NarrativeAuthoringDiagnosticCategory.eventSource,
        title: 'Scenario has no runtime source',
        message: 'This scenario has no mapEnter, triggerEnter, entityInteract, '
            'or outcomeReceived source node.',
        actionHint: 'Choose a runtime source for this scenario before it can '
            'run.',
        actionKind: NarrativeAuthoringDiagnosticActionKind.selectValidReference,
      ),
    NarrativeValidationDiagnosticKind.openDialogueReferencesUnknownDialogue ||
    NarrativeValidationDiagnosticKind
          .conditionalDialogueReferencesUnknownDialogue =>
      const _NarrativeAuthoringDiagnosticTemplate(
        category: NarrativeAuthoringDiagnosticCategory.dialogueReference,
        title: 'Dialogue reference is invalid',
        message: 'A scenario or conditional dialogue references a dialogue '
            'that is not available in the project.',
        actionHint: 'Select an existing dialogue reference, or create the '
            'missing dialogue before using it.',
        actionKind: NarrativeAuthoringDiagnosticActionKind.selectValidReference,
      ),
    NarrativeValidationDiagnosticKind.startTrainerBattleMissingTrainerId ||
    NarrativeValidationDiagnosticKind
        .startTrainerBattleReferencesUnknownTrainer ||
    NarrativeValidationDiagnosticKind.startTrainerBattleMissingNpcEntityId ||
    NarrativeValidationDiagnosticKind.startTrainerBattleBlankBattleId =>
      const _NarrativeAuthoringDiagnosticTemplate(
        category: NarrativeAuthoringDiagnosticCategory.trainerBattleReference,
        title: 'Trainer battle reference is invalid',
        message: 'A startTrainerBattle action is missing a required trainer, '
            'NPC, or battle reference.',
        actionHint: 'Select a valid trainer battle reference and ensure the '
            'NPC entity and battle id are filled.',
        actionKind: NarrativeAuthoringDiagnosticActionKind.selectValidReference,
      ),
    NarrativeValidationDiagnosticKind
        .sourceEntityInteractReferencesUnknownMap ||
    NarrativeValidationDiagnosticKind
          .sourceEntityInteractReferencesUnknownEntity =>
      const _NarrativeAuthoringDiagnosticTemplate(
        category: NarrativeAuthoringDiagnosticCategory.eventSource,
        title: 'Event source reference is invalid',
        message: 'An entityInteract source references a map or entity that is '
            'not available.',
        actionHint: 'Select a valid map and entity from the event source '
            'picker.',
        actionKind: NarrativeAuthoringDiagnosticActionKind.selectValidReference,
      ),
    NarrativeValidationDiagnosticKind.sourceOutcomeWithoutMatchingEmitOutcome =>
      const _NarrativeAuthoringDiagnosticTemplate(
        category: NarrativeAuthoringDiagnosticCategory.outcomeAuthoring,
        title: 'Outcome receiver has no emitter',
        message: 'An outcomeReceived source exists, but no scenario emits the '
            'same outcome.',
        actionHint: 'Add an emitOutcome action for this outcome, or choose an '
            'outcome that is already emitted.',
        actionKind: NarrativeAuthoringDiagnosticActionKind.emitOutcome,
      ),
    NarrativeValidationDiagnosticKind.emitOutcomeWithoutMatchingSourceOutcome =>
      const _NarrativeAuthoringDiagnosticTemplate(
        category: NarrativeAuthoringDiagnosticCategory.outcomeAuthoring,
        title: 'Outcome has no receiver',
        message: 'A scenario emits an outcome, but no outcomeReceived source '
            'uses it yet.',
        actionHint: 'Add an outcomeReceived source if this outcome should '
            'continue another flow.',
        actionKind: NarrativeAuthoringDiagnosticActionKind.addOutcomeReceiver,
      ),
    NarrativeValidationDiagnosticKind.flagReadNeverProduced ||
    NarrativeValidationDiagnosticKind.setFlagNeverRead ||
    NarrativeValidationDiagnosticKind.stepReadNeverCompleted ||
    NarrativeValidationDiagnosticKind.completeStepNeverRead =>
      _unknownTemplate,
  };
}

String _debugTechnicalLabel(NarrativeValidationDiagnostic diagnostic) {
  final context = <String>[
    diagnostic.kind.name,
    diagnostic.severity.name,
    diagnostic.path,
    if (diagnostic.referencedId != null) 'ref=${diagnostic.referencedId}',
    if (diagnostic.scenarioId != null) 'scenario=${diagnostic.scenarioId}',
    if (diagnostic.nodeId != null) 'node=${diagnostic.nodeId}',
    if (diagnostic.mapId != null) 'map=${diagnostic.mapId}',
    if (diagnostic.entityId != null) 'entity=${diagnostic.entityId}',
  ];
  return context.join(' | ');
}

const _unknownTemplate = _NarrativeAuthoringDiagnosticTemplate(
  category: NarrativeAuthoringDiagnosticCategory.unknown,
  title: 'Narrative diagnostic',
  message: 'The validator reported a narrative diagnostic that does not have a '
      'specific authoring message yet.',
  actionHint:
      'Inspect this diagnostic manually. No automatic fix is available.',
  actionKind: NarrativeAuthoringDiagnosticActionKind.noAutomaticFix,
);

@immutable
final class _NarrativeAuthoringDiagnosticTemplate {
  const _NarrativeAuthoringDiagnosticTemplate({
    required this.category,
    required this.title,
    required this.message,
    required this.actionHint,
    required this.actionKind,
  });

  final NarrativeAuthoringDiagnosticCategory category;
  final String title;
  final String message;
  final String actionHint;
  final NarrativeAuthoringDiagnosticActionKind actionKind;
}
