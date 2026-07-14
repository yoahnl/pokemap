import '../models/narrative_event_definition.dart';
import '../models/narrative_event_registry.dart';
import '../models/narrative_event_source_ref.dart';
import '../operations/narrative_event_canonical_json.dart';
import '../operations/narrative_event_id_generator.dart';
import 'narrative_event_activation_operations.dart';
import 'narrative_event_authoring_contract.dart';
import 'narrative_event_configuration_operations.dart';
import 'narrative_event_draft_operations.dart';
import 'narrative_event_publication_operations.dart';
import 'narrative_event_source_operations_v2.dart';

NarrativeEventAuthoringDiagnostic? verifyNarrativeEventAuthoringResult({
  required NarrativeEventAuthoringContext context,
  required NarrativeEventAuthoringResult result,
}) {
  final contextIssue = context.inspect(result.expectedRevision);
  if (contextIssue != null) {
    return NarrativeEventAuthoringDiagnostic(
      code: contextIssue.code,
      message: contextIssue.message,
    );
  }
  if (result.status != NarrativeEventAuthoringStatus.applied ||
      result.nextRegistry == null ||
      result.nextRecord == null ||
      !_registryEquals(context.registryOrNull, result.previousRegistry)) {
    return _unverified();
  }
  try {
    final replayed = _replay(context, result);
    if (replayed.status != NarrativeEventAuthoringStatus.applied ||
        replayed.mutation != result.mutation ||
        replayed.expectedRevision != result.expectedRevision ||
        !_registryEquals(replayed.previousRegistry, result.previousRegistry) ||
        !_registryEquals(replayed.nextRegistry, result.nextRegistry) ||
        !_recordEquals(replayed.previousRecord, result.previousRecord) ||
        !_recordEquals(replayed.nextRecord, result.nextRecord)) {
      return _unverified();
    }
    return null;
  } on Object {
    return _unverified();
  }
}

NarrativeEventAuthoringResult _replay(
  NarrativeEventAuthoringContext context,
  NarrativeEventAuthoringResult result,
) {
  final nextRecord = result.nextRecord!;
  final nextDraft = nextRecord.draftOrNull;
  return switch (result.mutation) {
    NarrativeEventAuthoringMutation.createDraft => createNarrativeEventDraft(
        context: context,
        expectedRevision: result.expectedRevision,
        name: nextDraft!.name,
        initialSource: nextDraft.source,
        idGenerator: NarrativeEventIdGenerator(
          rawUuidFactory: () => nextRecord.id.substring(4),
        ),
      ),
    NarrativeEventAuthoringMutation.selectSource => selectNarrativeEventSource(
        context: context,
        expectedRevision: result.expectedRevision,
        eventId: nextRecord.id,
        source: _source(nextRecord)!,
      ),
    NarrativeEventAuthoringMutation.replaceSource =>
      replaceNarrativeEventSource(
        context: context,
        expectedRevision: result.expectedRevision,
        eventId: nextRecord.id,
        source: _source(nextRecord)!,
      ),
    NarrativeEventAuthoringMutation.removeSource => removeNarrativeEventSource(
        context: context,
        expectedRevision: result.expectedRevision,
        eventId: nextRecord.id,
      ),
    NarrativeEventAuthoringMutation.rename => renameNarrativeEvent(
        context: context,
        expectedRevision: result.expectedRevision,
        eventId: nextRecord.id,
        name: _name(nextRecord),
      ),
    NarrativeEventAuthoringMutation.setConditions =>
      setNarrativeEventConditions(
        context: context,
        expectedRevision: result.expectedRevision,
        eventId: nextRecord.id,
        conditions: _conditions(nextRecord),
      ),
    NarrativeEventAuthoringMutation.setScene => setNarrativeEventScene(
        context: context,
        expectedRevision: result.expectedRevision,
        eventId: nextRecord.id,
        sceneId: _sceneId(nextRecord)!,
      ),
    NarrativeEventAuthoringMutation.removeScene => removeNarrativeEventScene(
        context: context,
        expectedRevision: result.expectedRevision,
        eventId: nextRecord.id,
      ),
    NarrativeEventAuthoringMutation.setReusePolicy =>
      setNarrativeEventReusePolicy(
        context: context,
        expectedRevision: result.expectedRevision,
        eventId: nextRecord.id,
        reusePolicy: _reusePolicy(nextRecord)!,
      ),
    NarrativeEventAuthoringMutation.setPriority => setNarrativeEventPriority(
        context: context,
        expectedRevision: result.expectedRevision,
        eventId: nextRecord.id,
        priority: _priority(nextRecord),
      ),
    NarrativeEventAuthoringMutation.setOrder => setNarrativeEventOrder(
        context: context,
        expectedRevision: result.expectedRevision,
        eventId: nextRecord.id,
        order: _order(nextRecord),
      ),
    NarrativeEventAuthoringMutation.publish => publishNarrativeEvent(
        context: context,
        expectedRevision: result.expectedRevision,
        eventId: nextRecord.id,
      ),
    NarrativeEventAuthoringMutation.activate => activateNarrativeEvent(
        context: context,
        expectedRevision: result.expectedRevision,
        eventId: nextRecord.id,
      ),
    NarrativeEventAuthoringMutation.deactivate => deactivateNarrativeEvent(
        context: context,
        expectedRevision: result.expectedRevision,
        eventId: nextRecord.id,
      ),
  };
}

NarrativeEventSourceRef? _source(NarrativeEventRecord record) {
  return record.when(
    draft: (draft) => draft.source,
    configured: (definition, _) => definition.source,
  );
}

String _name(NarrativeEventRecord record) {
  return record.when(
    draft: (draft) => draft.name,
    configured: (definition, _) => definition.name,
  );
}

List<NarrativeEventCondition> _conditions(NarrativeEventRecord record) {
  return record.when(
    draft: (draft) => draft.conditions,
    configured: (definition, _) => definition.conditions,
  );
}

String? _sceneId(NarrativeEventRecord record) {
  return record.when(
    draft: (draft) => draft.sceneId,
    configured: (definition, _) => definition.sceneId,
  );
}

NarrativeEventReusePolicy? _reusePolicy(NarrativeEventRecord record) {
  return record.when(
    draft: (draft) => draft.reusePolicy,
    configured: (definition, _) => definition.reusePolicy,
  );
}

int _priority(NarrativeEventRecord record) {
  return record.when(
    draft: (draft) => draft.priority,
    configured: (definition, _) => definition.priority,
  );
}

int _order(NarrativeEventRecord record) {
  return record.when(
    draft: (draft) => draft.order,
    configured: (definition, _) => definition.order,
  );
}

bool _registryEquals(
  NarrativeEventRegistry? left,
  NarrativeEventRegistry? right,
) {
  return canonicalizeNarrativeEventJson(left?.toJson()) ==
      canonicalizeNarrativeEventJson(right?.toJson());
}

bool _recordEquals(NarrativeEventRecord? left, NarrativeEventRecord? right) {
  return canonicalizeNarrativeEventJson(left?.toJson()) ==
      canonicalizeNarrativeEventJson(right?.toJson());
}

NarrativeEventAuthoringDiagnostic _unverified() {
  return NarrativeEventAuthoringDiagnostic(
    code: 'unverifiedAuthoringResult',
    message:
        'Le résultat d’authoring ne correspond pas à une opération valide.',
  );
}
