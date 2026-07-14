import 'package:map_core/map_core.dart';

enum NarrativeEventRegistryPersistenceStatus {
  committed,
  recovered,
  noOp,
  staleRevision,
  staleUndo,
  rejected,
  unsupportedRegistry,
  invalidRegistry,
  blocked,
  recoveryRequired,
  ioFailure,
}

enum NarrativeEventRegistryJournalState { prepared, committed, recovered }

enum NarrativeEventRegistryWriteCheckpoint {
  beforeBackup,
  afterBackup,
  afterJournalPrepared,
  afterTempWrite,
  afterTempFlush,
  beforeRename,
  afterRename,
  afterHashVerify,
  beforeCommitted,
  afterCommittedBeforeCleanup,
}

typedef NarrativeEventRegistryFaultInjector = Future<void> Function(
  NarrativeEventRegistryWriteCheckpoint checkpoint,
);

final class NarrativeEventRegistryWriteRequest {
  NarrativeEventRegistryWriteRequest._({
    required String projectPath,
    required String operationId,
    required String expectedProjectRevision,
    required this.authoringContext,
    required this.authoringResult,
    required this.previousRegistry,
    required this.nextRegistry,
    required this.mutation,
    required List<String> eventIds,
  })  : projectPath = _identity(projectPath, 'projectPath'),
        operationId = _operationIdentity(operationId),
        expectedProjectRevision =
            _identity(expectedProjectRevision, 'expectedProjectRevision'),
        eventIds = _eventIds(eventIds);

  factory NarrativeEventRegistryWriteRequest.fromAuthoringResult({
    required String projectPath,
    required String operationId,
    required String expectedProjectRevision,
    required NarrativeEventAuthoringContext context,
    required NarrativeEventAuthoringResult result,
  }) {
    if (result.status != NarrativeEventAuthoringStatus.applied ||
        result.nextRegistry == null) {
      throw ArgumentError.value(
        result.status,
        'result',
        'must be an applied authoring result',
      );
    }
    if (expectedProjectRevision != result.expectedRevision) {
      throw ArgumentError.value(
        expectedProjectRevision,
        'expectedProjectRevision',
        'must match the authoring result revision',
      );
    }
    final verification = verifyNarrativeEventAuthoringResult(
      context: context,
      result: result,
    );
    if (verification != null) {
      throw ArgumentError.value(
        result,
        'result',
        '${verification.code}: ${verification.message}',
      );
    }
    final changedEventIds = _changedEventIds(
      result.previousRegistry,
      result.nextRegistry!,
    );
    if (changedEventIds.length != 1 ||
        changedEventIds.single != result.eventId) {
      throw ArgumentError.value(
        result,
        'result',
        'must change exactly the Event described by the authoring result',
      );
    }
    return NarrativeEventRegistryWriteRequest._(
      projectPath: projectPath,
      operationId: operationId,
      expectedProjectRevision: expectedProjectRevision,
      authoringContext: context,
      authoringResult: result,
      previousRegistry: result.previousRegistry,
      nextRegistry: result.nextRegistry!,
      mutation: result.mutation.name,
      eventIds: changedEventIds,
    );
  }

  final String projectPath;
  final String operationId;
  final String expectedProjectRevision;
  final NarrativeEventAuthoringContext authoringContext;
  final NarrativeEventAuthoringResult authoringResult;
  final NarrativeEventRegistry? previousRegistry;
  final NarrativeEventRegistry nextRegistry;
  final String mutation;
  final List<String> eventIds;
}

List<String> _changedEventIds(
  NarrativeEventRegistry? previous,
  NarrativeEventRegistry next,
) {
  final previousById = {
    for (final record in previous?.records ?? const <NarrativeEventRecord>[])
      record.id: record,
  };
  final nextById = {for (final record in next.records) record.id: record};
  final ids = {...previousById.keys, ...nextById.keys}.where((id) {
    final before = previousById[id];
    final after = nextById[id];
    return canonicalizeNarrativeEventJson(before?.toJson()) !=
        canonicalizeNarrativeEventJson(after?.toJson());
  }).toList()
    ..sort(compareNarrativeEventUtf16);
  return List.unmodifiable(ids);
}

final class NarrativeEventRegistryPersistenceResult {
  NarrativeEventRegistryPersistenceResult({
    required this.status,
    required String code,
    required String message,
    this.beforeRevision,
    this.afterRevision,
    this.journal,
    this.undoEntry,
  })  : code = _identity(code, 'code'),
        message = _identity(message, 'message');

  final NarrativeEventRegistryPersistenceStatus status;
  final String code;
  final String message;
  final String? beforeRevision;
  final String? afterRevision;
  final NarrativeEventRegistryWriteJournal? journal;
  final NarrativeEventRegistryUndoEntry? undoEntry;

  bool get succeeded =>
      status == NarrativeEventRegistryPersistenceStatus.committed ||
      status == NarrativeEventRegistryPersistenceStatus.recovered ||
      status == NarrativeEventRegistryPersistenceStatus.noOp;
}

final class NarrativeEventRegistryWriteJournal {
  NarrativeEventRegistryWriteJournal({
    required this.schemaVersion,
    required String operationId,
    required String projectPath,
    required String journalPath,
    required String beforeHash,
    required String expectedAfterHash,
    required String tempPath,
    required String backupPath,
    required this.state,
    required this.preparedAt,
    this.committedAt,
    this.recoveredAt,
    required List<String> eventIds,
    required String mutation,
    required String previousRegistryHash,
    required String nextRegistryHash,
    required this.previousRegistry,
    required this.nextRegistry,
  })  : operationId = _operationIdentity(operationId),
        projectPath = _identity(projectPath, 'projectPath'),
        journalPath = _identity(journalPath, 'journalPath'),
        beforeHash = _identity(beforeHash, 'beforeHash'),
        expectedAfterHash = _identity(expectedAfterHash, 'expectedAfterHash'),
        tempPath = _identity(tempPath, 'tempPath'),
        backupPath = _identity(backupPath, 'backupPath'),
        eventIds = _eventIds(eventIds),
        mutation = _identity(mutation, 'mutation'),
        previousRegistryHash =
            _identity(previousRegistryHash, 'previousRegistryHash'),
        nextRegistryHash = _identity(nextRegistryHash, 'nextRegistryHash') {
    if (schemaVersion != 1) {
      throw ArgumentError.value(schemaVersion, 'schemaVersion');
    }
    _validateHash(beforeHash, 'beforeHash');
    _validateHash(expectedAfterHash, 'expectedAfterHash');
    _validateHash(previousRegistryHash, 'previousRegistryHash');
    _validateHash(nextRegistryHash, 'nextRegistryHash');
    if (previousRegistryHash != _registryHash(previousRegistry) ||
        nextRegistryHash != _registryHash(nextRegistry)) {
      throw ArgumentError('Registry hashes must match embedded registries.');
    }
    _validateJournalLifecycle(
      state: state,
      preparedAt: preparedAt,
      committedAt: committedAt,
      recoveredAt: recoveredAt,
    );
  }

  factory NarrativeEventRegistryWriteJournal.fromJson(
    Map<String, Object?> json,
  ) {
    _expectExactFields(
      json,
      const {
        'schemaVersion',
        'operationId',
        'projectPath',
        'journalPath',
        'beforeHash',
        'expectedAfterHash',
        'tempPath',
        'backupPath',
        'state',
        'preparedAt',
        'committedAt',
        'recoveredAt',
        'eventIds',
        'mutation',
        'previousRegistryHash',
        'nextRegistryHash',
        'previousRegistry',
        'nextRegistry',
      },
      required: const {
        'schemaVersion',
        'operationId',
        'projectPath',
        'journalPath',
        'beforeHash',
        'expectedAfterHash',
        'tempPath',
        'backupPath',
        'state',
        'preparedAt',
        'eventIds',
        'mutation',
        'previousRegistryHash',
        'nextRegistryHash',
        'previousRegistry',
        'nextRegistry',
      },
    );
    final rawEventIds = _strings(json, 'eventIds');
    final journal = NarrativeEventRegistryWriteJournal(
      schemaVersion: _integer(json, 'schemaVersion'),
      operationId: _string(json, 'operationId'),
      projectPath: _string(json, 'projectPath'),
      journalPath: _string(json, 'journalPath'),
      beforeHash: _string(json, 'beforeHash'),
      expectedAfterHash: _string(json, 'expectedAfterHash'),
      tempPath: _string(json, 'tempPath'),
      backupPath: _string(json, 'backupPath'),
      state: _journalState(_string(json, 'state')),
      preparedAt: _dateTime(json, 'preparedAt'),
      committedAt: _optionalDateTime(json, 'committedAt'),
      recoveredAt: _optionalDateTime(json, 'recoveredAt'),
      eventIds: rawEventIds,
      mutation: _string(json, 'mutation'),
      previousRegistryHash: _string(json, 'previousRegistryHash'),
      nextRegistryHash: _string(json, 'nextRegistryHash'),
      previousRegistry: _registry(json['previousRegistry']),
      nextRegistry: _registry(json['nextRegistry']),
    );
    if (!_stringListsEqual(rawEventIds, journal.eventIds)) {
      throw const FormatException(
        'eventIds must be unique and canonically sorted.',
      );
    }
    return journal;
  }

  final int schemaVersion;
  final String operationId;
  final String projectPath;
  final String journalPath;
  final String beforeHash;
  final String expectedAfterHash;
  final String tempPath;
  final String backupPath;
  final NarrativeEventRegistryJournalState state;
  final DateTime preparedAt;
  final DateTime? committedAt;
  final DateTime? recoveredAt;
  final List<String> eventIds;
  final String mutation;
  final String previousRegistryHash;
  final String nextRegistryHash;
  final NarrativeEventRegistry? previousRegistry;
  final NarrativeEventRegistry? nextRegistry;

  NarrativeEventRegistryWriteJournal withState(
    NarrativeEventRegistryJournalState nextState,
    DateTime timestamp,
  ) {
    return NarrativeEventRegistryWriteJournal(
      schemaVersion: schemaVersion,
      operationId: operationId,
      projectPath: projectPath,
      journalPath: journalPath,
      beforeHash: beforeHash,
      expectedAfterHash: expectedAfterHash,
      tempPath: tempPath,
      backupPath: backupPath,
      state: nextState,
      preparedAt: preparedAt,
      committedAt: nextState == NarrativeEventRegistryJournalState.committed ||
              (nextState == NarrativeEventRegistryJournalState.recovered &&
                  committedAt != null)
          ? committedAt ?? timestamp
          : committedAt,
      recoveredAt: nextState == NarrativeEventRegistryJournalState.recovered
          ? timestamp
          : recoveredAt,
      eventIds: eventIds,
      mutation: mutation,
      previousRegistryHash: previousRegistryHash,
      nextRegistryHash: nextRegistryHash,
      previousRegistry: previousRegistry,
      nextRegistry: nextRegistry,
    );
  }

  Map<String, Object?> toJson() => {
        'schemaVersion': schemaVersion,
        'operationId': operationId,
        'projectPath': projectPath,
        'journalPath': journalPath,
        'beforeHash': beforeHash,
        'expectedAfterHash': expectedAfterHash,
        'tempPath': tempPath,
        'backupPath': backupPath,
        'state': state.name,
        'preparedAt': preparedAt.toUtc().toIso8601String(),
        if (committedAt != null)
          'committedAt': committedAt!.toUtc().toIso8601String(),
        if (recoveredAt != null)
          'recoveredAt': recoveredAt!.toUtc().toIso8601String(),
        'eventIds': eventIds,
        'mutation': mutation,
        'previousRegistryHash': previousRegistryHash,
        'nextRegistryHash': nextRegistryHash,
        'previousRegistry': previousRegistry?.toJson(),
        'nextRegistry': nextRegistry?.toJson(),
      };
}

final class NarrativeEventRegistryUndoEntry {
  NarrativeEventRegistryUndoEntry({
    required this.schemaVersion,
    required String operationId,
    required String projectPath,
    required String beforeRevision,
    required String afterRevision,
    required this.previousRegistry,
    required this.nextRegistry,
    required String previousRegistryHash,
    required String nextRegistryHash,
    required List<String> eventIds,
    required this.createdAt,
  })  : operationId = _operationIdentity(operationId),
        projectPath = _identity(projectPath, 'projectPath'),
        beforeRevision = _identity(beforeRevision, 'beforeRevision'),
        afterRevision = _identity(afterRevision, 'afterRevision'),
        previousRegistryHash =
            _identity(previousRegistryHash, 'previousRegistryHash'),
        nextRegistryHash = _identity(nextRegistryHash, 'nextRegistryHash'),
        eventIds = _eventIds(eventIds) {
    if (schemaVersion != 1) {
      throw ArgumentError.value(schemaVersion, 'schemaVersion');
    }
    _validateHash(beforeRevision, 'beforeRevision');
    _validateHash(afterRevision, 'afterRevision');
    _validateHash(previousRegistryHash, 'previousRegistryHash');
    _validateHash(nextRegistryHash, 'nextRegistryHash');
    if (previousRegistryHash != _registryHash(previousRegistry) ||
        nextRegistryHash != _registryHash(nextRegistry)) {
      throw ArgumentError('Registry hashes must match embedded registries.');
    }
    if (!createdAt.isUtc) {
      throw ArgumentError.value(createdAt, 'createdAt', 'must be UTC');
    }
  }

  factory NarrativeEventRegistryUndoEntry.fromJson(
    Map<String, Object?> json,
  ) {
    _expectExactFields(
      json,
      const {
        'schemaVersion',
        'operationId',
        'projectPath',
        'beforeRevision',
        'afterRevision',
        'previousRegistryHash',
        'nextRegistryHash',
        'previousRegistry',
        'nextRegistry',
        'eventIds',
        'createdAt',
      },
      required: const {
        'schemaVersion',
        'operationId',
        'projectPath',
        'beforeRevision',
        'afterRevision',
        'previousRegistryHash',
        'nextRegistryHash',
        'previousRegistry',
        'nextRegistry',
        'eventIds',
        'createdAt',
      },
    );
    final rawEventIds = _strings(json, 'eventIds');
    final entry = NarrativeEventRegistryUndoEntry(
      schemaVersion: _integer(json, 'schemaVersion'),
      operationId: _string(json, 'operationId'),
      projectPath: _string(json, 'projectPath'),
      beforeRevision: _string(json, 'beforeRevision'),
      afterRevision: _string(json, 'afterRevision'),
      previousRegistry: _registry(json['previousRegistry']),
      nextRegistry: _registry(json['nextRegistry']),
      previousRegistryHash: _string(json, 'previousRegistryHash'),
      nextRegistryHash: _string(json, 'nextRegistryHash'),
      eventIds: rawEventIds,
      createdAt: _dateTime(json, 'createdAt'),
    );
    if (!_stringListsEqual(rawEventIds, entry.eventIds)) {
      throw const FormatException(
        'eventIds must be unique and canonically sorted.',
      );
    }
    return entry;
  }

  final int schemaVersion;
  final String operationId;
  final String projectPath;
  final String beforeRevision;
  final String afterRevision;
  final NarrativeEventRegistry? previousRegistry;
  final NarrativeEventRegistry? nextRegistry;
  final String previousRegistryHash;
  final String nextRegistryHash;
  final List<String> eventIds;
  final DateTime createdAt;

  Map<String, Object?> toJson() => {
        'schemaVersion': schemaVersion,
        'operationId': operationId,
        'projectPath': projectPath,
        'beforeRevision': beforeRevision,
        'afterRevision': afterRevision,
        'previousRegistryHash': previousRegistryHash,
        'nextRegistryHash': nextRegistryHash,
        'previousRegistry': previousRegistry?.toJson(),
        'nextRegistry': nextRegistry?.toJson(),
        'eventIds': eventIds,
        'createdAt': createdAt.toUtc().toIso8601String(),
      };
}

void _validateJournalLifecycle({
  required NarrativeEventRegistryJournalState state,
  required DateTime preparedAt,
  required DateTime? committedAt,
  required DateTime? recoveredAt,
}) {
  if (!preparedAt.isUtc ||
      committedAt?.isUtc == false ||
      recoveredAt?.isUtc == false) {
    throw ArgumentError('Journal timestamps must be UTC.');
  }
  if (committedAt?.isBefore(preparedAt) == true ||
      recoveredAt?.isBefore(preparedAt) == true ||
      (committedAt != null &&
          recoveredAt != null &&
          recoveredAt.isBefore(committedAt))) {
    throw ArgumentError('Journal timestamps are not monotonic.');
  }
  final lifecycleValid = switch (state) {
    NarrativeEventRegistryJournalState.prepared =>
      committedAt == null && recoveredAt == null,
    NarrativeEventRegistryJournalState.committed =>
      committedAt != null && recoveredAt == null,
    NarrativeEventRegistryJournalState.recovered => recoveredAt != null,
  };
  if (!lifecycleValid) {
    throw ArgumentError('Journal state and timestamps are inconsistent.');
  }
}

void _validateHash(String value, String name) {
  if (!RegExp(r'^sha256:[0-9a-f]{64}$').hasMatch(value)) {
    throw ArgumentError.value(value, name, 'must be a SHA-256 fingerprint');
  }
}

String _registryHash(NarrativeEventRegistry? registry) {
  return narrativeEventBytesFingerprint(
    canonicalizeNarrativeEventJsonUtf8(registry?.toJson()),
  );
}

void _expectExactFields(
  Map<String, Object?> json,
  Set<String> allowed, {
  required Set<String> required,
}) {
  final unknown = json.keys.where((key) => !allowed.contains(key)).toList();
  final missing = required.where((key) => !json.containsKey(key)).toList();
  if (unknown.isNotEmpty || missing.isNotEmpty) {
    throw FormatException(
      'Unexpected fields: ${unknown.join(', ')}; missing fields: ${missing.join(', ')}.',
    );
  }
}

bool _stringListsEqual(List<String> left, List<String> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}

String _identity(String value, String name) {
  if (value.isEmpty || value.trim() != value) {
    throw ArgumentError.value(value, name, 'must be non-empty and trimmed');
  }
  return value;
}

String _operationIdentity(String value) {
  final operationId = _identity(value, 'operationId');
  if (operationId.length > 96 ||
      !RegExp(r'^[A-Za-z0-9][A-Za-z0-9_-]*$').hasMatch(operationId)) {
    throw ArgumentError.value(value, 'operationId', 'must be path-safe');
  }
  return operationId;
}

List<String> _eventIds(List<String> values) {
  final result = <String>[];
  final seen = <String>{};
  for (final value in values) {
    final id = _identity(value, 'eventId');
    if (seen.add(id)) result.add(id);
  }
  result.sort(compareNarrativeEventUtf16);
  return List.unmodifiable(result);
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

List<String> _strings(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! List || value.any((item) => item is! String)) {
    throw FormatException('$key must be a string list.');
  }
  return value.cast<String>();
}

DateTime _dateTime(Map<String, Object?> json, String key) {
  return DateTime.parse(_string(json, key)).toUtc();
}

DateTime? _optionalDateTime(Map<String, Object?> json, String key) {
  if (!json.containsKey(key)) return null;
  return _dateTime(json, key);
}

NarrativeEventRegistryJournalState _journalState(String value) {
  return NarrativeEventRegistryJournalState.values.firstWhere(
    (state) => state.name == value,
    orElse: () => throw FormatException('Unknown journal state: $value.'),
  );
}

NarrativeEventRegistry? _registry(Object? value) {
  if (value == null) return null;
  final decoded = decodeNarrativeEventRegistry(value);
  return decoded.when(
    absent: () => null,
    decoded: (registry) => registry,
    unsupported: (_, diagnostics) =>
        throw FormatException(diagnostics.join(' ')),
    invalid: (_, diagnostics) => throw FormatException(diagnostics.join(' ')),
  );
}
