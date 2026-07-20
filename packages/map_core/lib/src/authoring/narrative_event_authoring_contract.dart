import 'package:meta/meta.dart' show immutable;

import '../catalogs/narrative_event_project_catalog.dart';
import '../models/narrative_event_definition.dart';
import '../models/narrative_event_registry.dart';
import '../operations/narrative_event_canonical_json.dart';
import '../operations/narrative_event_registry_codec.dart';
import '../read_models/narrative_event_navigation_intent.dart';
import '../read_models/narrative_dependency_index.dart';
import '../read_models/narrative_event_source_index.dart';

enum NarrativeEventAuthoringStatus {
  applied,
  noOp,
  rejected,
  staleRevision,
  unsupportedRegistry,
  invalidRegistry,
}

enum NarrativeEventAuthoringMutation {
  createDraft,
  duplicate,
  delete,
  unpublish,
  selectSource,
  replaceSource,
  removeSource,
  rename,
  setConditions,
  setScene,
  removeScene,
  setReusePolicy,
  setPriority,
  setOrder,
  publish,
  activate,
  deactivate,
}

@immutable
final class NarrativeEventDeletionPreview {
  NarrativeEventDeletionPreview({
    required String eventId,
    required List<NarrativeDependencyUsage> consumers,
  })  : eventId = _identity(eventId, 'eventId'),
        consumers = List.unmodifiable(consumers);

  final String eventId;
  final List<NarrativeDependencyUsage> consumers;

  bool get canDelete => consumers.isEmpty;
}

@immutable
final class NarrativeEventAuthoringDiagnostic {
  NarrativeEventAuthoringDiagnostic({
    required String code,
    required String message,
    String? path,
  })  : code = _identity(code, 'code'),
        message = _identity(message, 'message'),
        path = path == null ? null : _identity(path, 'path');

  final String code;
  final String message;
  final String? path;
}

enum NarrativeEventSourceAuthoringOrigin {
  canonicalSpatial,
  legacyCompatibilitySpatial,
  sceneOutcome,
  battleOutcome,
  legacyScenarioOutcome,
  unresolvedReference,
}

@immutable
final class NarrativeEventAuthoringContextIssue {
  NarrativeEventAuthoringContextIssue({
    required this.status,
    required String code,
    required String message,
  })  : code = _identity(code, 'code'),
        message = _identity(message, 'message') {
    if (status == NarrativeEventAuthoringStatus.applied ||
        status == NarrativeEventAuthoringStatus.noOp) {
      throw ArgumentError.value(status, 'status', 'must describe a rejection');
    }
  }

  final NarrativeEventAuthoringStatus status;
  final String code;
  final String message;
}

@immutable
final class NarrativeEventAuthoringContext {
  NarrativeEventAuthoringContext({
    required this.registryState,
    required String revision,
    required this.catalog,
    required this.sourceIndex,
    required String manifestHash,
    required Map<String, String> mapHashes,
  })  : revision = _identity(revision, 'revision'),
        manifestHash = _identity(manifestHash, 'manifestHash'),
        mapHashes = Map.unmodifiable(mapHashes.map(
          (key, value) => MapEntry(
            _identity(key, 'mapHashes key'),
            _identity(value, 'mapHashes value'),
          ),
        ));

  final EventRegistryDecodeResult registryState;
  final String revision;
  final NarrativeEventProjectCatalog catalog;
  final NarrativeEventSourceIndexBuildResult sourceIndex;
  final String manifestHash;
  final Map<String, String> mapHashes;

  NarrativeEventRegistry? get registryOrNull => registryState.registryOrNull;

  NarrativeEventAuthoringContextIssue? inspect(String expectedRevision) {
    final registryIssue =
        registryState.when<NarrativeEventAuthoringContextIssue?>(
      absent: () => null,
      decoded: (_) => null,
      unsupported: (_, diagnostics) => NarrativeEventAuthoringContextIssue(
        status: NarrativeEventAuthoringStatus.unsupportedRegistry,
        code: 'unsupportedRegistry',
        message: 'Cette version des événements n’est pas prise en charge.',
      ),
      invalid: (_, diagnostics) => NarrativeEventAuthoringContextIssue(
        status: NarrativeEventAuthoringStatus.invalidRegistry,
        code: 'invalidRegistry',
        message: 'Les données d’événements du projet sont invalides.',
      ),
    );
    if (registryIssue != null) return registryIssue;
    final registry = registryOrNull;
    if (registry != null) {
      try {
        narrativeEventRegistryFingerprint(registry);
      } on FormatException {
        return NarrativeEventAuthoringContextIssue(
          status: NarrativeEventAuthoringStatus.invalidRegistry,
          code: 'invalidRegistry',
          message: 'Les données d’événements du projet ne sont pas canoniques.',
        );
      }
    }
    final revisionValue = expectedRevision.trim();
    if (revisionValue.isEmpty || revisionValue != revision) {
      return NarrativeEventAuthoringContextIssue(
        status: NarrativeEventAuthoringStatus.staleRevision,
        code: 'staleRevision',
        message: 'Le projet a changé depuis le début de cette opération.',
      );
    }
    if (catalog.manifestHash != manifestHash ||
        !_stringMapEquals(catalog.mapHashes, mapHashes) ||
        !_catalogMatchesRegistry() ||
        !_sourceIndexMatchesRegistry()) {
      return NarrativeEventAuthoringContextIssue(
        status: NarrativeEventAuthoringStatus.rejected,
        code: 'staleCatalog',
        message: 'Le catalogue Event ne correspond plus au projet actuel.',
      );
    }
    return null;
  }

  bool _catalogMatchesRegistry() {
    if (catalog.proposedRecords.isNotEmpty) return false;
    final records = registryOrNull?.records ?? const <NarrativeEventRecord>[];
    if (catalog.events.length != records.length) return false;
    final byId = {for (final event in catalog.events) event.record.id: event};
    if (byId.length != records.length) return false;
    for (final record in records) {
      final event = byId[record.id];
      if (event == null || event.proposed || event.record != record) {
        return false;
      }
    }
    return true;
  }

  bool _sourceIndexMatchesRegistry() {
    final expectedRecords = [
      for (final record
          in registryOrNull?.records ?? const <NarrativeEventRecord>[])
        if (record.definitionOrNull != null && record.enabledOrNull == true)
          record,
    ];
    final actualRecords = <String, NarrativeEventRecord>{};
    for (final source in sourceIndex.index.sources) {
      for (final record in sourceIndex.index.recordsFor(source)) {
        if (record.definitionOrNull?.source != source ||
            actualRecords.containsKey(record.id)) {
          return false;
        }
        actualRecords[record.id] = record;
      }
    }
    if (actualRecords.length != expectedRecords.length) return false;
    for (final record in expectedRecords) {
      if (actualRecords[record.id] != record) return false;
    }
    final expectedConflicts = <String, Set<String>>{};
    for (final record in expectedRecords) {
      final definition = record.definitionOrNull!;
      final key =
          '${canonicalizeNarrativeEventJson(definition.source.toJson())}'
          '|${definition.priority}|${definition.order}';
      expectedConflicts.putIfAbsent(key, () => <String>{}).add(record.id);
    }
    expectedConflicts.removeWhere((_, ids) => ids.length < 2);
    final actualConflicts = <String, Set<String>>{};
    for (final conflict in sourceIndex.conflicts) {
      final key = '${canonicalizeNarrativeEventJson(conflict.source.toJson())}'
          '|${conflict.priority}|${conflict.order}';
      if (actualConflicts.containsKey(key)) return false;
      actualConflicts[key] = {for (final record in conflict.records) record.id};
    }
    if (actualConflicts.length != expectedConflicts.length) return false;
    for (final entry in expectedConflicts.entries) {
      if (!_stringSetEquals(actualConflicts[entry.key], entry.value)) {
        return false;
      }
    }
    return true;
  }
}

@immutable
final class NarrativeEventSourceImpactPreview {
  NarrativeEventSourceImpactPreview({
    this.currentSourceSentence,
    this.nextSourceSentence,
    this.currentMapId,
    this.nextMapId,
    this.currentOrigin,
    this.nextOrigin,
    this.currentNavigation,
    this.nextNavigation,
    List<String> diagnosticsLikelyToChange = const [],
    required this.physicalSourceDeleted,
    required this.structuralUnpublish,
  }) : diagnosticsLikelyToChange = List.unmodifiable(diagnosticsLikelyToChange);

  final String? currentSourceSentence;
  final String? nextSourceSentence;
  final String? currentMapId;
  final String? nextMapId;
  final NarrativeEventSourceAuthoringOrigin? currentOrigin;
  final NarrativeEventSourceAuthoringOrigin? nextOrigin;
  final NarrativeEditorDestination? currentNavigation;
  final NarrativeEditorDestination? nextNavigation;
  final List<String> diagnosticsLikelyToChange;
  final bool physicalSourceDeleted;
  final bool structuralUnpublish;
}

@immutable
final class NarrativeEventAuthoringResult {
  NarrativeEventAuthoringResult._({
    required this.status,
    required this.mutation,
    required this.previousRegistry,
    required this.nextRegistry,
    required this.previousRecord,
    required this.nextRecord,
    required this.expectedRevision,
    required this.conceptualNextRevision,
    required List<NarrativeEventAuthoringDiagnostic> diagnostics,
    required this.impactPreview,
    required this.deletionPreview,
    required this.undoable,
    required this.metadataOnly,
  }) : diagnostics = List.unmodifiable(diagnostics);

  factory NarrativeEventAuthoringResult.applied({
    required NarrativeEventAuthoringMutation mutation,
    required NarrativeEventRegistry? previousRegistry,
    required NarrativeEventRegistry nextRegistry,
    required NarrativeEventRecord? previousRecord,
    required NarrativeEventRecord? nextRecord,
    required String expectedRevision,
    NarrativeEventSourceImpactPreview? impactPreview,
    NarrativeEventDeletionPreview? deletionPreview,
    bool metadataOnly = false,
    List<NarrativeEventAuthoringDiagnostic> diagnostics = const [],
  }) {
    late final String nextRevision;
    try {
      nextRevision = narrativeEventRegistryFingerprint(nextRegistry);
    } on FormatException {
      return NarrativeEventAuthoringResult._(
        status: NarrativeEventAuthoringStatus.rejected,
        mutation: mutation,
        previousRegistry: previousRegistry,
        nextRegistry: null,
        previousRecord: previousRecord,
        nextRecord: previousRecord,
        expectedRevision: expectedRevision,
        conceptualNextRevision: null,
        diagnostics: [
          NarrativeEventAuthoringDiagnostic(
            code: 'invalidProjectedRegistry',
            message:
                'La modification produirait des données qui ne peuvent pas être enregistrées.',
          ),
        ],
        impactPreview: impactPreview,
        deletionPreview: deletionPreview,
        undoable: false,
        metadataOnly: false,
      );
    }
    return NarrativeEventAuthoringResult._(
      status: NarrativeEventAuthoringStatus.applied,
      mutation: mutation,
      previousRegistry: previousRegistry,
      nextRegistry: nextRegistry,
      previousRecord: previousRecord,
      nextRecord: nextRecord,
      expectedRevision: expectedRevision,
      conceptualNextRevision: nextRevision,
      diagnostics: diagnostics,
      impactPreview: impactPreview,
      deletionPreview: deletionPreview,
      undoable: true,
      metadataOnly: metadataOnly,
    );
  }

  factory NarrativeEventAuthoringResult.noOp({
    required NarrativeEventAuthoringMutation mutation,
    required NarrativeEventRegistry? registry,
    required NarrativeEventRecord? record,
    required String expectedRevision,
    NarrativeEventSourceImpactPreview? impactPreview,
    NarrativeEventDeletionPreview? deletionPreview,
    List<NarrativeEventAuthoringDiagnostic> diagnostics = const [],
  }) {
    return NarrativeEventAuthoringResult._(
      status: NarrativeEventAuthoringStatus.noOp,
      mutation: mutation,
      previousRegistry: registry,
      nextRegistry: null,
      previousRecord: record,
      nextRecord: record,
      expectedRevision: expectedRevision,
      conceptualNextRevision: null,
      diagnostics: diagnostics,
      impactPreview: impactPreview,
      deletionPreview: deletionPreview,
      undoable: false,
      metadataOnly: false,
    );
  }

  factory NarrativeEventAuthoringResult.rejected({
    required NarrativeEventAuthoringStatus status,
    required NarrativeEventAuthoringMutation mutation,
    required NarrativeEventRegistry? registry,
    required NarrativeEventRecord? record,
    required String expectedRevision,
    required String code,
    required String message,
    String? path,
    NarrativeEventSourceImpactPreview? impactPreview,
    NarrativeEventDeletionPreview? deletionPreview,
  }) {
    if (status == NarrativeEventAuthoringStatus.applied ||
        status == NarrativeEventAuthoringStatus.noOp) {
      throw ArgumentError.value(status, 'status', 'must describe a rejection');
    }
    return NarrativeEventAuthoringResult._(
      status: status,
      mutation: mutation,
      previousRegistry: registry,
      nextRegistry: null,
      previousRecord: record,
      nextRecord: record,
      expectedRevision: expectedRevision,
      conceptualNextRevision: null,
      diagnostics: [
        NarrativeEventAuthoringDiagnostic(
          code: code,
          message: message,
          path: path,
        ),
      ],
      impactPreview: impactPreview,
      deletionPreview: deletionPreview,
      undoable: false,
      metadataOnly: false,
    );
  }

  final NarrativeEventAuthoringStatus status;
  final NarrativeEventAuthoringMutation mutation;
  final NarrativeEventRegistry? previousRegistry;
  final NarrativeEventRegistry? nextRegistry;
  final NarrativeEventRecord? previousRecord;
  final NarrativeEventRecord? nextRecord;
  final String expectedRevision;
  final String? conceptualNextRevision;
  final List<NarrativeEventAuthoringDiagnostic> diagnostics;
  final NarrativeEventSourceImpactPreview? impactPreview;
  final NarrativeEventDeletionPreview? deletionPreview;
  final bool undoable;
  final bool metadataOnly;

  String? get rejectionCode =>
      diagnostics.isEmpty ? null : diagnostics.first.code;
  String? get humanReason =>
      diagnostics.isEmpty ? null : diagnostics.first.message;
  String? get eventId => nextRecord?.id ?? previousRecord?.id;
}

String narrativeEventRegistryFingerprint(NarrativeEventRegistry registry) {
  return 'sha256:${narrativeEventCanonicalSha256(registry.toJson())}';
}

NarrativeEventAuthoringResult? rejectNarrativeEventAuthoringContextIssue({
  required NarrativeEventAuthoringContext context,
  required String expectedRevision,
  required NarrativeEventAuthoringMutation mutation,
  NarrativeEventRecord? record,
}) {
  final issue = context.inspect(expectedRevision);
  if (issue == null) return null;
  return NarrativeEventAuthoringResult.rejected(
    status: issue.status,
    mutation: mutation,
    registry: context.registryOrNull,
    record: record,
    expectedRevision: expectedRevision,
    code: issue.code,
    message: issue.message,
  );
}

bool _stringMapEquals(Map<String, String> left, Map<String, String> right) {
  if (identical(left, right)) return true;
  if (left.length != right.length) return false;
  for (final entry in left.entries) {
    if (right[entry.key] != entry.value) return false;
  }
  return true;
}

bool _stringSetEquals(Set<String>? left, Set<String> right) {
  if (left == null || left.length != right.length) return false;
  return left.containsAll(right);
}

String _identity(String value, String name) {
  if (value.isEmpty || value.trim() != value) {
    throw ArgumentError.value(value, name, 'must be non-empty and trimmed');
  }
  return value;
}
