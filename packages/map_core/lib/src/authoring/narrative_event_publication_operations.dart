import '../models/narrative_event_definition.dart';
import 'narrative_event_authoring_contract.dart';
import 'narrative_event_authoring_support.dart';
import 'narrative_event_configuration_validation.dart';

NarrativeEventAuthoringResult publishNarrativeEvent({
  required NarrativeEventAuthoringContext context,
  required String expectedRevision,
  required String eventId,
}) {
  final registry = context.registryOrNull;
  final record = findNarrativeEventRecord(registry, eventId);
  final contextRejection = rejectNarrativeEventAuthoringContextIssue(
    context: context,
    expectedRevision: expectedRevision,
    mutation: NarrativeEventAuthoringMutation.publish,
    record: record,
  );
  if (contextRejection != null) return contextRejection;
  if (registry == null || record == null) {
    return _rejectPublication(
      context: context,
      expectedRevision: expectedRevision,
      record: record,
      code: 'eventMissing',
      message: 'L’événement à publier n’existe pas.',
    );
  }
  final draft = record.draftOrNull;
  if (draft == null) {
    return _rejectPublication(
      context: context,
      expectedRevision: expectedRevision,
      record: record,
      code: 'eventNotDraft',
      message: 'Seul un brouillon peut être publié.',
    );
  }
  final requiredIssue = _requiredPublicationIssue(draft);
  if (requiredIssue != null) {
    return _rejectPublicationIssue(
      context: context,
      expectedRevision: expectedRevision,
      record: record,
      issue: requiredIssue,
    );
  }
  final validationIssue = _publicationValidationIssue(
    context: context,
    draft: draft,
  );
  if (validationIssue != null) {
    return _rejectPublicationIssue(
      context: context,
      expectedRevision: expectedRevision,
      record: record,
      issue: validationIssue,
    );
  }
  final definition = NarrativeEventDefinition(
    id: draft.id,
    name: draft.name,
    source: draft.source!,
    conditions: draft.conditions,
    sceneId: draft.sceneId!,
    reusePolicy: draft.reusePolicy!,
    priority: draft.priority,
    order: draft.order,
  );
  final nextRecord = NarrativeEventRecord.configuredStructurallyUnchecked(
    definition,
    enabled: false,
  );
  final nextRegistry = replaceNarrativeEventRecord(registry, nextRecord);
  return NarrativeEventAuthoringResult.applied(
    mutation: NarrativeEventAuthoringMutation.publish,
    previousRegistry: registry,
    nextRegistry: nextRegistry,
    previousRecord: record,
    nextRecord: nextRecord,
    expectedRevision: expectedRevision,
    diagnostics: [
      NarrativeEventAuthoringDiagnostic(
        code: 'runtimeSupportPending',
        message:
            'L’événement est publié mais reste désactivé pour le runtime V2.',
      ),
    ],
  );
}

NarrativeEventAuthoringDiagnostic? _requiredPublicationIssue(
  NarrativeEventDraft draft,
) {
  if (draft.source == null) {
    return NarrativeEventAuthoringDiagnostic(
      code: 'sourceRequired',
      message: 'Choisissez une source avant de publier cet événement.',
      path: 'source',
    );
  }
  if (draft.sceneId == null) {
    return NarrativeEventAuthoringDiagnostic(
      code: 'sceneRequired',
      message: 'Choisissez une Scene avant de publier cet événement.',
      path: 'sceneId',
    );
  }
  if (draft.reusePolicy == null) {
    return NarrativeEventAuthoringDiagnostic(
      code: 'reusePolicyRequired',
      message: 'Choisissez le comportement de cet événement avant publication.',
      path: 'reusePolicy',
    );
  }
  return null;
}

NarrativeEventAuthoringDiagnostic? _publicationValidationIssue({
  required NarrativeEventAuthoringContext context,
  required NarrativeEventDraft draft,
}) {
  return validateNarrativeEventAuthoringName(draft.name) ??
      validateNarrativeEventAuthoringInteger(
        value: draft.priority,
        nonNegative: false,
        path: 'priority',
      ) ??
      validateNarrativeEventAuthoringInteger(
        value: draft.order,
        nonNegative: true,
        path: 'order',
      ) ??
      validateNarrativeEventAuthoringSource(
        context: context,
        source: draft.source!,
      ) ??
      validateNarrativeEventAuthoringScene(
        context: context,
        sceneId: draft.sceneId!,
      ) ??
      validateNarrativeEventAuthoringConditions(
        context: context,
        eventId: draft.id,
        conditions: draft.conditions,
      ) ??
      firstBlockingNarrativeEventCatalogIssue(context);
}

NarrativeEventAuthoringResult _rejectPublicationIssue({
  required NarrativeEventAuthoringContext context,
  required String expectedRevision,
  required NarrativeEventRecord record,
  required NarrativeEventAuthoringDiagnostic issue,
}) {
  return NarrativeEventAuthoringResult.rejected(
    status: NarrativeEventAuthoringStatus.rejected,
    mutation: NarrativeEventAuthoringMutation.publish,
    registry: context.registryOrNull,
    record: record,
    expectedRevision: expectedRevision,
    code: issue.code,
    message: issue.message,
    path: issue.path,
  );
}

NarrativeEventAuthoringResult _rejectPublication({
  required NarrativeEventAuthoringContext context,
  required String expectedRevision,
  required NarrativeEventRecord? record,
  required String code,
  required String message,
}) {
  return NarrativeEventAuthoringResult.rejected(
    status: NarrativeEventAuthoringStatus.rejected,
    mutation: NarrativeEventAuthoringMutation.publish,
    registry: context.registryOrNull,
    record: record,
    expectedRevision: expectedRevision,
    code: code,
    message: message,
  );
}
