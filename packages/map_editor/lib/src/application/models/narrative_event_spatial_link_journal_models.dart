import 'dart:convert';

import 'package:map_core/map_core.dart';

enum NarrativeEventSpatialLinkJournalState {
  prepared,
  mapCommitted,
  eventCommitted,
}

enum NarrativeEventSpatialLinkCleanupMarker { none, requested }

enum NarrativeEventSpatialLinkCheckpoint {
  afterJournalPrepared,
  afterMapTempFlush,
  beforeMapRename,
  afterMapRename,
  afterMapVerified,
  afterCleanupJournalMarked,
  beforeCleanupRename,
  afterCleanupRename,
}

typedef NarrativeEventSpatialLinkFaultInjector = Future<void> Function(
  NarrativeEventSpatialLinkCheckpoint checkpoint,
);

enum NarrativeEventSpatialLinkOperationStatus {
  mapCommitted,
  eventCommitted,
  cleaned,
  recovered,
  noOp,
  conflict,
  blocked,
  ioFailure,
}

enum NarrativeEventSpatialLinkInspectionStatus {
  clear,
  preparedSourceAbsent,
  preparedSourcePresent,
  awaitingEventCommit,
  eventAlreadyLinked,
  cleanupPending,
  cleanupCompleted,
  blocked,
}

final class NarrativeEventSpatialLinkMapCommitRequest {
  NarrativeEventSpatialLinkMapCommitRequest({
    required String projectPath,
    required String projectRevision,
    required String operationId,
    required String eventId,
    required String eventRecordFingerprintBefore,
    required this.beforeMap,
    required this.afterMap,
    required this.source,
    required Map<String, Object?> sourceOwnerJson,
    required String sourceOwnerFingerprint,
  })  : projectPath = _identity(projectPath, 'projectPath'),
        projectRevision = _fingerprint(projectRevision, 'projectRevision'),
        operationId = _operationIdentity(operationId),
        eventId = _identity(eventId, 'eventId'),
        eventRecordFingerprintBefore = _fingerprint(
          eventRecordFingerprintBefore,
          'eventRecordFingerprintBefore',
        ),
        sourceOwnerJson = _canonicalObject(sourceOwnerJson),
        sourceOwnerFingerprint = _fingerprint(
          sourceOwnerFingerprint,
          'sourceOwnerFingerprint',
        ) {
    final sourceMapId = narrativeEventSpatialSourceMapId(source);
    if (sourceMapId == null) {
      throw ArgumentError.value(
        source,
        'source',
        'must be an entityInteract or triggerEnter source',
      );
    }
    if (beforeMap.id != sourceMapId || afterMap.id != sourceMapId) {
      throw ArgumentError.value(
        source,
        'source',
        'must own both map snapshots',
      );
    }
    final computed = narrativeEventBytesFingerprint(
      canonicalizeNarrativeEventJsonUtf8(this.sourceOwnerJson),
    );
    if (computed != this.sourceOwnerFingerprint) {
      throw ArgumentError.value(
        sourceOwnerFingerprint,
        'sourceOwnerFingerprint',
        'must match the canonical owner JSON',
      );
    }
  }

  final String projectPath;
  final String projectRevision;
  final String operationId;
  final String eventId;
  final String eventRecordFingerprintBefore;
  final MapData beforeMap;
  final MapData afterMap;
  final NarrativeEventSourceRef source;
  final Map<String, Object?> sourceOwnerJson;
  final String sourceOwnerFingerprint;
}

final class NarrativeEventSpatialLinkJournal {
  NarrativeEventSpatialLinkJournal({
    required this.schemaVersion,
    required String operationId,
    required String projectPath,
    required String projectRevision,
    required String journalPath,
    required String mapPath,
    required String mapTempPath,
    required String mapId,
    required String eventId,
    required String eventRecordFingerprintBefore,
    required this.source,
    required Map<String, Object?> sourceOwnerJson,
    required String sourceOwnerFingerprint,
    required String beforeMapHash,
    required String afterMapHash,
    required this.state,
    required this.preparedAt,
    this.mapCommittedAt,
    this.eventCommittedAt,
    required this.cleanupMarker,
    this.cleanupRequestedAt,
  })  : operationId = _operationIdentity(operationId),
        projectPath = _identity(projectPath, 'projectPath'),
        projectRevision = _fingerprint(projectRevision, 'projectRevision'),
        journalPath = _identity(journalPath, 'journalPath'),
        mapPath = _identity(mapPath, 'mapPath'),
        mapTempPath = _identity(mapTempPath, 'mapTempPath'),
        mapId = _identity(mapId, 'mapId'),
        eventId = _identity(eventId, 'eventId'),
        eventRecordFingerprintBefore = _fingerprint(
          eventRecordFingerprintBefore,
          'eventRecordFingerprintBefore',
        ),
        sourceOwnerJson = _canonicalObject(sourceOwnerJson),
        sourceOwnerFingerprint = _fingerprint(
          sourceOwnerFingerprint,
          'sourceOwnerFingerprint',
        ),
        beforeMapHash = _fingerprint(beforeMapHash, 'beforeMapHash'),
        afterMapHash = _fingerprint(afterMapHash, 'afterMapHash') {
    if (schemaVersion != 1) {
      throw ArgumentError.value(schemaVersion, 'schemaVersion');
    }
    final sourceMapId = narrativeEventSpatialSourceMapId(source);
    if (sourceMapId == null || sourceMapId != this.mapId) {
      throw ArgumentError.value(source, 'source', 'must own mapId');
    }
    final computedOwnerFingerprint = narrativeEventBytesFingerprint(
      canonicalizeNarrativeEventJsonUtf8(this.sourceOwnerJson),
    );
    if (computedOwnerFingerprint != this.sourceOwnerFingerprint) {
      throw ArgumentError.value(
        sourceOwnerFingerprint,
        'sourceOwnerFingerprint',
        'must match sourceOwnerJson',
      );
    }
    _validateLifecycle(this);
  }

  factory NarrativeEventSpatialLinkJournal.fromJson(
    Map<String, Object?> json,
  ) {
    _expectExactFields(json, const {
      'schemaVersion',
      'operationId',
      'projectPath',
      'projectRevision',
      'journalPath',
      'mapPath',
      'mapTempPath',
      'mapId',
      'eventId',
      'eventRecordFingerprintBefore',
      'source',
      'sourceOwnerJson',
      'sourceOwnerFingerprint',
      'beforeMapHash',
      'afterMapHash',
      'state',
      'preparedAt',
      'mapCommittedAt',
      'eventCommittedAt',
      'cleanupMarker',
      'cleanupRequestedAt',
    });
    return NarrativeEventSpatialLinkJournal(
      schemaVersion: _integer(json, 'schemaVersion'),
      operationId: _string(json, 'operationId'),
      projectPath: _string(json, 'projectPath'),
      projectRevision: _string(json, 'projectRevision'),
      journalPath: _string(json, 'journalPath'),
      mapPath: _string(json, 'mapPath'),
      mapTempPath: _string(json, 'mapTempPath'),
      mapId: _string(json, 'mapId'),
      eventId: _string(json, 'eventId'),
      eventRecordFingerprintBefore:
          _string(json, 'eventRecordFingerprintBefore'),
      source: NarrativeEventSourceRef.fromJson(json['source']),
      sourceOwnerJson: _object(json['sourceOwnerJson'], 'sourceOwnerJson'),
      sourceOwnerFingerprint: _string(json, 'sourceOwnerFingerprint'),
      beforeMapHash: _string(json, 'beforeMapHash'),
      afterMapHash: _string(json, 'afterMapHash'),
      state: _enumByName(
        NarrativeEventSpatialLinkJournalState.values,
        _string(json, 'state'),
        'state',
      ),
      preparedAt: _dateTime(json, 'preparedAt')!,
      mapCommittedAt: _dateTime(json, 'mapCommittedAt'),
      eventCommittedAt: _dateTime(json, 'eventCommittedAt'),
      cleanupMarker: _enumByName(
        NarrativeEventSpatialLinkCleanupMarker.values,
        _string(json, 'cleanupMarker'),
        'cleanupMarker',
      ),
      cleanupRequestedAt: _dateTime(json, 'cleanupRequestedAt'),
    );
  }

  final int schemaVersion;
  final String operationId;
  final String projectPath;
  final String projectRevision;
  final String journalPath;
  final String mapPath;
  final String mapTempPath;
  final String mapId;
  final String eventId;
  final String eventRecordFingerprintBefore;
  final NarrativeEventSourceRef source;
  final Map<String, Object?> sourceOwnerJson;
  final String sourceOwnerFingerprint;
  final String beforeMapHash;
  final String afterMapHash;
  final NarrativeEventSpatialLinkJournalState state;
  final DateTime preparedAt;
  final DateTime? mapCommittedAt;
  final DateTime? eventCommittedAt;
  final NarrativeEventSpatialLinkCleanupMarker cleanupMarker;
  final DateTime? cleanupRequestedAt;

  Map<String, Object?> toJson() => {
        'schemaVersion': schemaVersion,
        'operationId': operationId,
        'projectPath': projectPath,
        'projectRevision': projectRevision,
        'journalPath': journalPath,
        'mapPath': mapPath,
        'mapTempPath': mapTempPath,
        'mapId': mapId,
        'eventId': eventId,
        'eventRecordFingerprintBefore': eventRecordFingerprintBefore,
        'source': source.toJson(),
        'sourceOwnerJson': sourceOwnerJson,
        'sourceOwnerFingerprint': sourceOwnerFingerprint,
        'beforeMapHash': beforeMapHash,
        'afterMapHash': afterMapHash,
        'state': state.name,
        'preparedAt': preparedAt.toUtc().toIso8601String(),
        'mapCommittedAt': mapCommittedAt?.toUtc().toIso8601String(),
        'eventCommittedAt': eventCommittedAt?.toUtc().toIso8601String(),
        'cleanupMarker': cleanupMarker.name,
        'cleanupRequestedAt': cleanupRequestedAt?.toUtc().toIso8601String(),
      };

  NarrativeEventSpatialLinkJournal markMapCommitted(DateTime at) {
    return _copy(
      state: NarrativeEventSpatialLinkJournalState.mapCommitted,
      mapCommittedAt: at.toUtc(),
    );
  }

  NarrativeEventSpatialLinkJournal markEventCommitted(DateTime at) {
    return _copy(
      state: NarrativeEventSpatialLinkJournalState.eventCommitted,
      eventCommittedAt: at.toUtc(),
    );
  }

  NarrativeEventSpatialLinkJournal markCleanupRequested(DateTime at) {
    return _copy(
      cleanupMarker: NarrativeEventSpatialLinkCleanupMarker.requested,
      cleanupRequestedAt: at.toUtc(),
    );
  }

  NarrativeEventSpatialLinkJournal _copy({
    NarrativeEventSpatialLinkJournalState? state,
    DateTime? mapCommittedAt,
    DateTime? eventCommittedAt,
    NarrativeEventSpatialLinkCleanupMarker? cleanupMarker,
    DateTime? cleanupRequestedAt,
  }) {
    return NarrativeEventSpatialLinkJournal(
      schemaVersion: schemaVersion,
      operationId: operationId,
      projectPath: projectPath,
      projectRevision: projectRevision,
      journalPath: journalPath,
      mapPath: mapPath,
      mapTempPath: mapTempPath,
      mapId: mapId,
      eventId: eventId,
      eventRecordFingerprintBefore: eventRecordFingerprintBefore,
      source: source,
      sourceOwnerJson: sourceOwnerJson,
      sourceOwnerFingerprint: sourceOwnerFingerprint,
      beforeMapHash: beforeMapHash,
      afterMapHash: afterMapHash,
      state: state ?? this.state,
      preparedAt: preparedAt,
      mapCommittedAt: mapCommittedAt ?? this.mapCommittedAt,
      eventCommittedAt: eventCommittedAt ?? this.eventCommittedAt,
      cleanupMarker: cleanupMarker ?? this.cleanupMarker,
      cleanupRequestedAt: cleanupRequestedAt ?? this.cleanupRequestedAt,
    );
  }
}

final class NarrativeEventSpatialLinkInspectionIssue {
  const NarrativeEventSpatialLinkInspectionIssue({
    required this.code,
    required this.message,
    this.path,
  });

  final String code;
  final String message;
  final String? path;
}

final class NarrativeEventSpatialLinkInspection {
  NarrativeEventSpatialLinkInspection({
    required this.status,
    this.journal,
    List<NarrativeEventSpatialLinkInspectionIssue> issues = const [],
  }) : issues = List.unmodifiable(issues);

  final NarrativeEventSpatialLinkInspectionStatus status;
  final NarrativeEventSpatialLinkJournal? journal;
  final List<NarrativeEventSpatialLinkInspectionIssue> issues;
}

final class NarrativeEventSpatialLinkOperationResult {
  const NarrativeEventSpatialLinkOperationResult({
    required this.status,
    required this.code,
    required this.message,
    this.journal,
    this.inspection,
  });

  final NarrativeEventSpatialLinkOperationStatus status;
  final String code;
  final String message;
  final NarrativeEventSpatialLinkJournal? journal;
  final NarrativeEventSpatialLinkInspection? inspection;

  bool get succeeded => switch (status) {
        NarrativeEventSpatialLinkOperationStatus.mapCommitted ||
        NarrativeEventSpatialLinkOperationStatus.eventCommitted ||
        NarrativeEventSpatialLinkOperationStatus.cleaned ||
        NarrativeEventSpatialLinkOperationStatus.recovered ||
        NarrativeEventSpatialLinkOperationStatus.noOp =>
          true,
        _ => false,
      };
}

String? narrativeEventSpatialSourceMapId(NarrativeEventSourceRef source) {
  return source.when(
    entityInteract: (mapId, _) => mapId,
    triggerEnter: (mapId, _) => mapId,
    mapEnter: (_) => null,
    outcomeReceived: (_) => null,
  );
}

String narrativeEventRecordCanonicalFingerprint(NarrativeEventRecord record) {
  return narrativeEventBytesFingerprint(
    canonicalizeNarrativeEventJsonUtf8(
      _normalizeJsonValue(record.toJson()),
    ),
  );
}

String narrativeEventSpatialSourceOwnerId(NarrativeEventSourceRef source) {
  return source.when(
    entityInteract: (_, entityId) => entityId,
    triggerEnter: (_, triggerId) => triggerId,
    mapEnter: (_) => throw ArgumentError.value(source, 'source'),
    outcomeReceived: (_) => throw ArgumentError.value(source, 'source'),
  );
}

void _validateLifecycle(NarrativeEventSpatialLinkJournal journal) {
  final timestamps = [
    journal.preparedAt,
    journal.mapCommittedAt,
    journal.eventCommittedAt,
    journal.cleanupRequestedAt,
  ].whereType<DateTime>();
  if (timestamps.any((value) => !value.isUtc)) {
    throw ArgumentError('Journal timestamps must be UTC.');
  }
  if (journal.mapCommittedAt?.isBefore(journal.preparedAt) == true ||
      journal.eventCommittedAt?.isBefore(
            journal.mapCommittedAt ?? journal.preparedAt,
          ) ==
          true ||
      journal.cleanupRequestedAt?.isBefore(journal.preparedAt) == true) {
    throw ArgumentError('Journal timestamps must be monotonic.');
  }
  final lifecycleValid = switch (journal.state) {
    NarrativeEventSpatialLinkJournalState.prepared =>
      journal.mapCommittedAt == null && journal.eventCommittedAt == null,
    NarrativeEventSpatialLinkJournalState.mapCommitted =>
      journal.mapCommittedAt != null && journal.eventCommittedAt == null,
    NarrativeEventSpatialLinkJournalState.eventCommitted =>
      journal.mapCommittedAt != null && journal.eventCommittedAt != null,
  };
  if (!lifecycleValid) {
    throw ArgumentError('Journal state and timestamps are inconsistent.');
  }
  final cleanupValid = switch (journal.cleanupMarker) {
    NarrativeEventSpatialLinkCleanupMarker.none =>
      journal.cleanupRequestedAt == null,
    NarrativeEventSpatialLinkCleanupMarker.requested =>
      journal.cleanupRequestedAt != null &&
          journal.state == NarrativeEventSpatialLinkJournalState.mapCommitted,
  };
  if (!cleanupValid) {
    throw ArgumentError('Journal cleanup marker is inconsistent.');
  }
}

String _identity(String value, String name) {
  if (value.isEmpty || value.trim() != value) {
    throw ArgumentError.value(value, name, 'must be non-empty and trimmed');
  }
  return value;
}

String _operationIdentity(String value) {
  final normalized = _identity(value, 'operationId');
  if (normalized.length > 96 ||
      !RegExp(r'^[A-Za-z0-9][A-Za-z0-9_-]*$').hasMatch(normalized)) {
    throw ArgumentError.value(value, 'operationId', 'must be path-safe');
  }
  return normalized;
}

String _fingerprint(String value, String name) {
  final normalized = _identity(value, name);
  if (!RegExp(r'^sha256:[0-9a-f]{64}$').hasMatch(normalized)) {
    throw ArgumentError.value(value, name, 'must be a SHA-256 fingerprint');
  }
  return normalized;
}

Map<String, Object?> _canonicalObject(Map<String, Object?> value) {
  final decoded = _normalizeJsonValue(value);
  if (decoded is! Map) {
    throw const FormatException('Expected a canonical JSON object.');
  }
  return _deepFreeze(decoded) as Map<String, Object?>;
}

Object? _normalizeJsonValue(Object? value) {
  return decodeNarrativeEventJsonStrict(jsonEncode(value));
}

Object? _deepFreeze(Object? value) {
  if (value is Map) {
    return Map<String, Object?>.unmodifiable({
      for (final entry in value.entries)
        entry.key as String: _deepFreeze(entry.value),
    });
  }
  if (value is List) {
    return List<Object?>.unmodifiable(value.map(_deepFreeze));
  }
  return value;
}

void _expectExactFields(Map<String, Object?> json, Set<String> expected) {
  final unknown = json.keys.where((key) => !expected.contains(key)).toList();
  final missing = expected.where((key) => !json.containsKey(key)).toList();
  if (unknown.isNotEmpty || missing.isNotEmpty) {
    throw FormatException(
      'Unexpected fields: ${unknown.join(', ')}; '
      'missing fields: ${missing.join(', ')}.',
    );
  }
}

String _string(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! String) throw FormatException('$key must be a string.');
  return value;
}

int _integer(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! int) throw FormatException('$key must be an integer.');
  return value;
}

Map<String, Object?> _object(Object? value, String key) {
  if (value is! Map) throw FormatException('$key must be an object.');
  return {
    for (final entry in value.entries) entry.key as String: entry.value,
  };
}

DateTime? _dateTime(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value == null) return null;
  if (value is! String) throw FormatException('$key must be a timestamp.');
  final parsed = DateTime.tryParse(value);
  if (parsed == null || !parsed.isUtc) {
    throw FormatException('$key must be an explicit UTC timestamp.');
  }
  return parsed;
}

T _enumByName<T extends Enum>(List<T> values, String name, String field) {
  for (final value in values) {
    if (value.name == name) return value;
  }
  throw FormatException('Unknown $field: $name.');
}
