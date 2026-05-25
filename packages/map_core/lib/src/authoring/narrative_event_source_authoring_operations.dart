import 'package:meta/meta.dart' show immutable;

import '../read_models/narrative_reference_picker_read_models.dart';
import 'narrative_scenario_authoring_draft.dart';

enum NarrativeEventSourceAuthoringDiagnosticSeverity {
  error,
  warning,
}

enum NarrativeEventSourceAuthoringDiagnosticKind {
  missingSourceReference,
  sourceOptionNotFound,
  unsupportedEventSourceKind,
}

@immutable
final class NarrativeEventSourceAuthoringDiagnostic {
  const NarrativeEventSourceAuthoringDiagnostic({
    required this.severity,
    required this.kind,
    required this.message,
    required this.path,
    this.referencedId,
  });

  final NarrativeEventSourceAuthoringDiagnosticSeverity severity;
  final NarrativeEventSourceAuthoringDiagnosticKind kind;
  final String message;
  final String path;
  final String? referencedId;
}

NarrativeScenarioAuthoringSourceDraft
    createNarrativeScenarioAuthoringSourceDraftFromEventSourceOption(
  NarrativeEventSourcePickerOption option,
) {
  return switch (option.sourceKind) {
    NarrativeEventSourceKind.mapEnter =>
      NarrativeScenarioAuthoringSourceDraft.mapEnter(
        mapId: option.mapId.trim(),
      ),
    NarrativeEventSourceKind.triggerEnter =>
      NarrativeScenarioAuthoringSourceDraft.triggerEnter(
        mapId: option.mapId.trim(),
        triggerId: option.triggerId.trim(),
      ),
    NarrativeEventSourceKind.entityInteract =>
      NarrativeScenarioAuthoringSourceDraft.entityInteract(
        mapId: option.mapId.trim(),
        entityId: option.entityId.trim(),
      ),
    NarrativeEventSourceKind.outcomeReceived =>
      NarrativeScenarioAuthoringSourceDraft.outcomeReceived(
        outcomeId: option.outcomeId.trim(),
      ),
  };
}

String narrativeEventSourceIdForAuthoringSourceDraft(
  NarrativeScenarioAuthoringSourceDraft source,
) {
  return switch (source.kind) {
    NarrativeScenarioAuthoringSourceKind.mapEnter =>
      'mapEnter:${source.mapId.trim()}',
    NarrativeScenarioAuthoringSourceKind.triggerEnter =>
      'triggerEnter:${source.mapId.trim()}:${source.triggerId.trim()}',
    NarrativeScenarioAuthoringSourceKind.entityInteract =>
      'entityInteract:${source.mapId.trim()}:${source.entityId.trim()}',
    NarrativeScenarioAuthoringSourceKind.outcomeReceived =>
      'outcomeReceived:${source.outcomeId.trim()}',
  };
}

NarrativeEventSourcePickerOption?
    findNarrativeEventSourcePickerOptionForAuthoringSourceDraft(
  NarrativeScenarioAuthoringSourceDraft source,
  Iterable<NarrativeEventSourcePickerOption> options,
) {
  final expectedSourceId =
      narrativeEventSourceIdForAuthoringSourceDraft(source);
  for (final option in options) {
    if (option.sourceId.trim() == expectedSourceId) {
      return option;
    }
  }
  return null;
}

List<NarrativeEventSourceAuthoringDiagnostic>
    validateNarrativeScenarioAuthoringSourceDraftAgainstEventSourceOptions(
  NarrativeScenarioAuthoringSourceDraft source,
  Iterable<NarrativeEventSourcePickerOption> options,
) {
  final diagnostics = <NarrativeEventSourceAuthoringDiagnostic>[];
  _collectMissingReferenceDiagnostics(source, diagnostics);
  if (diagnostics.isNotEmpty) {
    return List<NarrativeEventSourceAuthoringDiagnostic>.unmodifiable(
      diagnostics,
    );
  }

  final option = findNarrativeEventSourcePickerOptionForAuthoringSourceDraft(
    source,
    options,
  );
  if (option == null) {
    final sourceId = narrativeEventSourceIdForAuthoringSourceDraft(source);
    diagnostics.add(
      NarrativeEventSourceAuthoringDiagnostic(
        severity: NarrativeEventSourceAuthoringDiagnosticSeverity.error,
        kind: NarrativeEventSourceAuthoringDiagnosticKind.sourceOptionNotFound,
        message: 'No selectable event source option matches "$sourceId".',
        path: 'source',
        referencedId: sourceId,
      ),
    );
  }

  return List<NarrativeEventSourceAuthoringDiagnostic>.unmodifiable(
    diagnostics,
  );
}

NarrativeScenarioAuthoringDraft replaceNarrativeScenarioAuthoringDraftSource(
  NarrativeScenarioAuthoringDraft draft,
  NarrativeScenarioAuthoringSourceDraft source,
) {
  return NarrativeScenarioAuthoringDraft(
    scenarioId: draft.scenarioId,
    name: draft.name,
    description: draft.description,
    scope: draft.scope,
    source: source,
    actions: draft.actions,
    declaredOutcomes: draft.declaredOutcomes,
    metadata: draft.metadata,
  );
}

void _collectMissingReferenceDiagnostics(
  NarrativeScenarioAuthoringSourceDraft source,
  List<NarrativeEventSourceAuthoringDiagnostic> diagnostics,
) {
  switch (source.kind) {
    case NarrativeScenarioAuthoringSourceKind.mapEnter:
      _requireReference(source.mapId, path: 'source.mapId', diagnostics);
    case NarrativeScenarioAuthoringSourceKind.triggerEnter:
      _requireReference(source.mapId, path: 'source.mapId', diagnostics);
      _requireReference(
          source.triggerId, path: 'source.triggerId', diagnostics);
    case NarrativeScenarioAuthoringSourceKind.entityInteract:
      _requireReference(source.mapId, path: 'source.mapId', diagnostics);
      _requireReference(source.entityId, path: 'source.entityId', diagnostics);
    case NarrativeScenarioAuthoringSourceKind.outcomeReceived:
      _requireReference(
          source.outcomeId, path: 'source.outcomeId', diagnostics);
  }
}

void _requireReference(
  String value,
  List<NarrativeEventSourceAuthoringDiagnostic> diagnostics, {
  required String path,
}) {
  if (value.trim().isNotEmpty) {
    return;
  }
  diagnostics.add(
    NarrativeEventSourceAuthoringDiagnostic(
      severity: NarrativeEventSourceAuthoringDiagnosticSeverity.error,
      kind: NarrativeEventSourceAuthoringDiagnosticKind.missingSourceReference,
      message: 'Event source reference is required.',
      path: path,
    ),
  );
}
