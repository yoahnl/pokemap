import '../models/narrative_event_definition.dart';
import 'narrative_event_authoring_contract.dart';
import 'narrative_event_authoring_support.dart';
import 'narrative_event_configuration_validation.dart';

NarrativeEventAuthoringResult activateNarrativeEvent({
  required NarrativeEventAuthoringContext context,
  required String expectedRevision,
  required String eventId,
}) {
  final registry = context.registryOrNull;
  final record = findNarrativeEventRecord(registry, eventId);
  final contextRejection = rejectNarrativeEventAuthoringContextIssue(
    context: context,
    expectedRevision: expectedRevision,
    mutation: NarrativeEventAuthoringMutation.activate,
    record: record,
  );
  if (contextRejection != null) return contextRejection;
  if (registry == null || record == null) {
    return _rejectActivation(
      context: context,
      expectedRevision: expectedRevision,
      record: record,
      mutation: NarrativeEventAuthoringMutation.activate,
      code: 'eventMissing',
      message: 'L’événement à activer n’existe pas.',
    );
  }
  final definition = record.definitionOrNull;
  if (definition == null) {
    return _rejectActivation(
      context: context,
      expectedRevision: expectedRevision,
      record: record,
      mutation: NarrativeEventAuthoringMutation.activate,
      code: 'eventNotConfigured',
      message: 'Publiez l’événement avant de l’activer.',
    );
  }
  final validationIssue = _activationValidationIssue(
    context: context,
    definition: definition,
  );
  if (validationIssue != null) {
    return _rejectActivationIssue(
      context: context,
      expectedRevision: expectedRevision,
      record: record,
      mutation: NarrativeEventAuthoringMutation.activate,
      issue: validationIssue,
    );
  }
  for (final active
      in context.sourceIndex.index.recordsFor(definition.source)) {
    if (active.id == definition.id) continue;
    final activeDefinition = active.definitionOrNull!;
    if (activeDefinition.priority == definition.priority &&
        activeDefinition.order == definition.order) {
      return _rejectActivation(
        context: context,
        expectedRevision: expectedRevision,
        record: record,
        mutation: NarrativeEventAuthoringMutation.activate,
        code: 'exactSourceConflict',
        message:
            'L’événement ${active.id} utilise déjà cette source avec la même priorité et le même ordre.',
      );
    }
  }
  if (record.enabledOrNull == true) {
    return NarrativeEventAuthoringResult.noOp(
      mutation: NarrativeEventAuthoringMutation.activate,
      registry: registry,
      record: record,
      expectedRevision: expectedRevision,
    );
  }
  final nextRecord = NarrativeEventRecord.configuredStructurallyUnchecked(
    definition,
    enabled: true,
  );
  final nextRegistry = replaceNarrativeEventRecord(registry, nextRecord);
  return NarrativeEventAuthoringResult.applied(
    mutation: NarrativeEventAuthoringMutation.activate,
    previousRegistry: registry,
    nextRegistry: nextRegistry,
    previousRecord: record,
    nextRecord: nextRecord,
    expectedRevision: expectedRevision,
    diagnostics: [
      NarrativeEventAuthoringDiagnostic(
        code: 'runtimeSupportPending',
        message: 'L’activation est enregistrée côté authoring V2.',
      ),
    ],
  );
}

NarrativeEventAuthoringResult deactivateNarrativeEvent({
  required NarrativeEventAuthoringContext context,
  required String expectedRevision,
  required String eventId,
}) {
  final registry = context.registryOrNull;
  final record = findNarrativeEventRecord(registry, eventId);
  final contextRejection = rejectNarrativeEventAuthoringContextIssue(
    context: context,
    expectedRevision: expectedRevision,
    mutation: NarrativeEventAuthoringMutation.deactivate,
    record: record,
  );
  if (contextRejection != null) return contextRejection;
  if (registry == null || record == null) {
    return _rejectActivation(
      context: context,
      expectedRevision: expectedRevision,
      record: record,
      mutation: NarrativeEventAuthoringMutation.deactivate,
      code: 'eventMissing',
      message: 'L’événement à désactiver n’existe pas.',
    );
  }
  final definition = record.definitionOrNull;
  if (definition == null) {
    return _rejectActivation(
      context: context,
      expectedRevision: expectedRevision,
      record: record,
      mutation: NarrativeEventAuthoringMutation.deactivate,
      code: 'eventNotConfigured',
      message: 'Un brouillon ne peut pas être désactivé.',
    );
  }
  if (record.enabledOrNull == false) {
    return NarrativeEventAuthoringResult.noOp(
      mutation: NarrativeEventAuthoringMutation.deactivate,
      registry: registry,
      record: record,
      expectedRevision: expectedRevision,
    );
  }
  final nextRecord = NarrativeEventRecord.configuredStructurallyUnchecked(
    definition,
    enabled: false,
  );
  final nextRegistry = replaceNarrativeEventRecord(registry, nextRecord);
  return NarrativeEventAuthoringResult.applied(
    mutation: NarrativeEventAuthoringMutation.deactivate,
    previousRegistry: registry,
    nextRegistry: nextRegistry,
    previousRecord: record,
    nextRecord: nextRecord,
    expectedRevision: expectedRevision,
  );
}

NarrativeEventAuthoringDiagnostic? _activationValidationIssue({
  required NarrativeEventAuthoringContext context,
  required NarrativeEventDefinition definition,
}) {
  return validateNarrativeEventAuthoringName(definition.name) ??
      validateNarrativeEventAuthoringInteger(
        value: definition.priority,
        nonNegative: false,
        path: 'priority',
      ) ??
      validateNarrativeEventAuthoringInteger(
        value: definition.order,
        nonNegative: true,
        path: 'order',
      ) ??
      validateNarrativeEventAuthoringSource(
        context: context,
        source: definition.source,
      ) ??
      validateNarrativeEventAuthoringScene(
        context: context,
        sceneId: definition.sceneId,
      ) ??
      validateNarrativeEventAuthoringConditions(
        context: context,
        eventId: definition.id,
        conditions: definition.conditions,
      ) ??
      firstBlockingNarrativeEventCatalogIssue(context);
}

NarrativeEventAuthoringResult _rejectActivationIssue({
  required NarrativeEventAuthoringContext context,
  required String expectedRevision,
  required NarrativeEventRecord record,
  required NarrativeEventAuthoringMutation mutation,
  required NarrativeEventAuthoringDiagnostic issue,
}) {
  return NarrativeEventAuthoringResult.rejected(
    status: NarrativeEventAuthoringStatus.rejected,
    mutation: mutation,
    registry: context.registryOrNull,
    record: record,
    expectedRevision: expectedRevision,
    code: issue.code,
    message: issue.message,
    path: issue.path,
  );
}

NarrativeEventAuthoringResult _rejectActivation({
  required NarrativeEventAuthoringContext context,
  required String expectedRevision,
  required NarrativeEventRecord? record,
  required NarrativeEventAuthoringMutation mutation,
  required String code,
  required String message,
}) {
  return NarrativeEventAuthoringResult.rejected(
    status: NarrativeEventAuthoringStatus.rejected,
    mutation: mutation,
    registry: context.registryOrNull,
    record: record,
    expectedRevision: expectedRevision,
    code: code,
    message: message,
  );
}
