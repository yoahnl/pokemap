# PMCP-021 — Full created-file contents

This appendix is part of the PMCP-021 Evidence Pack and reproduces every production and test file created by the lot. Modified files, the evidence report, and this appendix are excluded to avoid recursive or duplicate content.

## `packages/map_authoring/lib/src/ports/idempotency_store.dart`

~~~~~~~~dart
import '../contracts/authoring_receipt.dart';
import '../support/authoring_fingerprint.dart';

enum AuthoringIdempotencyStatus { pending, completed }

/// Durable uniqueness scope for one mutation intent.
///
/// The caller key remains in memory only. Durable JSON stores its fingerprint
/// so operator logs cannot reveal a client-supplied idempotency secret.
final class AuthoringIdempotencyScope {
  AuthoringIdempotencyScope({
    required String actorId,
    required String projectId,
    required String actionId,
    required int actionVersion,
    required String key,
  })  : actorId = _safeIdentity(actorId, 'actorId'),
        projectId = _safeIdentity(projectId, 'projectId'),
        actionId = _actionId(actionId),
        actionVersion = _positiveVersion(actionVersion),
        _rawKey = _nonBlank(key, 'key'),
        keyFingerprint = computeAuthoringJsonFingerprint(
          _nonBlank(key, 'key'),
          logicalName: 'idempotency-key.json',
        );

  AuthoringIdempotencyScope._stored({
    required this.actorId,
    required this.projectId,
    required this.actionId,
    required this.actionVersion,
    required this.keyFingerprint,
  }) : _rawKey = null;

  factory AuthoringIdempotencyScope.fromJson(Map<String, dynamic> json) {
    const keys = {
      'actorId',
      'projectId',
      'actionId',
      'actionVersion',
      'keyFingerprint',
    };
    if (json.keys.any((key) => !keys.contains(key))) {
      throw const FormatException('Unknown idempotency scope field.');
    }
    final actorId = json['actorId'];
    final projectId = json['projectId'];
    final actionId = json['actionId'];
    final actionVersion = json['actionVersion'];
    final keyFingerprint = json['keyFingerprint'];
    if (actorId is! String ||
        projectId is! String ||
        actionId is! String ||
        actionVersion is! int ||
        keyFingerprint is! String) {
      throw const FormatException('Invalid idempotency scope fields.');
    }
    try {
      return AuthoringIdempotencyScope._stored(
        actorId: _safeIdentity(actorId, 'actorId'),
        projectId: _safeIdentity(projectId, 'projectId'),
        actionId: _actionId(actionId),
        actionVersion: _positiveVersion(actionVersion),
        keyFingerprint: _fingerprint(keyFingerprint, 'keyFingerprint'),
      );
    } on ArgumentError catch (error) {
      throw FormatException(error.message.toString());
    }
  }

  final String actorId;
  final String projectId;
  final String actionId;
  final int actionVersion;
  final String? _rawKey;
  final String keyFingerprint;

  String get key =>
      _rawKey ??
      (throw StateError('The raw idempotency key is not durably retained.'));

  bool matchesKey(String value) =>
      keyFingerprint ==
      computeAuthoringJsonFingerprint(
        value,
        logicalName: 'idempotency-key.json',
      );

  String get storageKey => canonicalAuthoringJson(toJson());

  Map<String, Object?> toJson() => {
        'actorId': actorId,
        'projectId': projectId,
        'actionId': actionId,
        'actionVersion': actionVersion,
        'keyFingerprint': keyFingerprint,
      };
}

final class AuthoringIdempotencyRecord {
  AuthoringIdempotencyRecord({
    required this.scope,
    required String payloadFingerprint,
    required String operationId,
    required this.status,
    required DateTime createdAt,
    DateTime? expiresAt,
    AuthoringReceipt? receipt,
  })  : payloadFingerprint =
            _fingerprint(payloadFingerprint, 'payloadFingerprint'),
        operationId = _safeIdentity(operationId, 'operationId'),
        createdAt = createdAt.toUtc(),
        expiresAt = expiresAt?.toUtc(),
        receipt = receipt {
    if (status == AuthoringIdempotencyStatus.pending &&
        (this.expiresAt != null || receipt != null)) {
      throw ArgumentError(
        'A pending idempotency record cannot expire or contain a receipt.',
      );
    }
    if (status == AuthoringIdempotencyStatus.completed &&
        (this.expiresAt == null || receipt == null)) {
      throw ArgumentError(
        'A completed idempotency record requires expiry and a receipt.',
      );
    }
    if (this.expiresAt != null && !this.expiresAt!.isAfter(this.createdAt)) {
      throw ArgumentError.value(
        expiresAt,
        'expiresAt',
        'must be after createdAt',
      );
    }
  }

  factory AuthoringIdempotencyRecord.fromJson(Map<String, dynamic> json) {
    const keys = {
      'scope',
      'payloadFingerprint',
      'operationId',
      'status',
      'createdAtUtc',
      'expiresAtUtc',
      'receipt',
    };
    if (json.keys.any((key) => !keys.contains(key))) {
      throw const FormatException('Unknown idempotency record field.');
    }
    final rawScope = json['scope'];
    final rawReceipt = json['receipt'];
    if (rawScope is! Map || (rawReceipt != null && rawReceipt is! Map)) {
      throw const FormatException('Invalid idempotency record objects.');
    }
    final status = switch (json['status']) {
      'pending' => AuthoringIdempotencyStatus.pending,
      'completed' => AuthoringIdempotencyStatus.completed,
      _ => throw const FormatException('Invalid idempotency record status.'),
    };
    try {
      return AuthoringIdempotencyRecord(
        scope: AuthoringIdempotencyScope.fromJson(
          Map<String, dynamic>.from(rawScope),
        ),
        payloadFingerprint:
            _requiredString(json['payloadFingerprint'], 'payloadFingerprint'),
        operationId: _requiredString(json['operationId'], 'operationId'),
        status: status,
        createdAt: _utcDate(json['createdAtUtc'], 'createdAtUtc'),
        expiresAt: json['expiresAtUtc'] == null
            ? null
            : _utcDate(json['expiresAtUtc'], 'expiresAtUtc'),
        receipt: rawReceipt == null
            ? null
            : AuthoringReceipt.fromJson(
                Map<String, dynamic>.from(rawReceipt),
              ),
      );
    } on ArgumentError catch (error) {
      throw FormatException(error.message.toString());
    }
  }

  final AuthoringIdempotencyScope scope;
  final String payloadFingerprint;
  final String operationId;
  final AuthoringIdempotencyStatus status;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final AuthoringReceipt? receipt;

  Map<String, Object?> toJson() => {
        'scope': scope.toJson(),
        'payloadFingerprint': payloadFingerprint,
        'operationId': operationId,
        'status': status.name,
        'createdAtUtc': createdAt.toIso8601String(),
        if (expiresAt != null) 'expiresAtUtc': expiresAt!.toIso8601String(),
        if (receipt != null) 'receipt': receipt!.toJson(),
      };
}

final class AuthoringIdempotencyReservation {
  const AuthoringIdempotencyReservation({
    required this.acquired,
    required this.record,
  });

  final bool acquired;
  final AuthoringIdempotencyRecord record;
}

abstract interface class IdempotencyStore {
  Future<AuthoringIdempotencyRecord?> read(
    AuthoringIdempotencyScope scope,
  );

  Future<AuthoringIdempotencyReservation> reserve(
    AuthoringIdempotencyRecord pendingRecord,
  );

  Future<AuthoringIdempotencyRecord> complete(
    AuthoringIdempotencyRecord completedRecord,
  );

  Future<int> pruneExpired(DateTime now);
}

String _requiredString(Object? value, String field) {
  if (value is! String) throw FormatException('$field must be a string.');
  return value;
}

DateTime _utcDate(Object? value, String field) {
  final raw = _requiredString(value, field);
  final parsed = DateTime.tryParse(raw);
  if (parsed == null || !parsed.isUtc || !raw.endsWith('Z')) {
    throw FormatException('$field must be a UTC timestamp.');
  }
  return parsed;
}

String _safeIdentity(String value, String field) {
  final normalized = _nonBlank(value, field);
  if (normalized.length > 200 ||
      !RegExp(r'^[a-zA-Z0-9][a-zA-Z0-9_.:-]*$').hasMatch(normalized)) {
    throw ArgumentError.value(
      value,
      field,
      'must be a safe opaque identity',
    );
  }
  return normalized;
}

String _actionId(String value) {
  final normalized = _nonBlank(value, 'actionId');
  if (!RegExp(r'^[a-z][a-zA-Z0-9_]*(?:\.[a-zA-Z0-9_]+)+$')
      .hasMatch(normalized)) {
    throw ArgumentError.value(value, 'actionId', 'must be a dotted action ID');
  }
  return normalized;
}

int _positiveVersion(int value) {
  if (value < 1) {
    throw ArgumentError.value(value, 'actionVersion', 'must be positive');
  }
  return value;
}

String _fingerprint(String value, String field) {
  if (!RegExp(r'^sha256:[0-9a-f]{64}$').hasMatch(value)) {
    throw ArgumentError.value(value, field, 'must be a SHA-256 fingerprint');
  }
  return value;
}

String _nonBlank(String value, String field) {
  final normalized = value.trim();
  if (normalized.isEmpty || normalized != value) {
    throw ArgumentError.value(value, field, 'must be nonblank and trimmed');
  }
  return normalized;
}
~~~~~~~~

## `packages/map_authoring/lib/src/transactions/file_idempotency_store.dart`

~~~~~~~~dart
import 'dart:convert';
import 'dart:io';

import '../ports/idempotency_store.dart';
import '../support/authoring_fingerprint.dart';

final class IdempotencyStoreException implements Exception {
  const IdempotencyStoreException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => 'IdempotencyStoreException($code): $message';
}

/// Locked append-only JSONL implementation of the durable idempotency port.
///
/// A reservation line is flushed before the caller can start applying. If a
/// process stops after that point, the pending record survives and forces
/// recovery instead of permitting a duplicate mutation. A truncated final
/// line is ignored because it was never a fully flushed durable event.
final class FileIdempotencyStore implements IdempotencyStore {
  FileIdempotencyStore({required String filePath})
      : _file = File(filePath),
        _lockFile = File('$filePath.lock'),
        _compactionFile = File('$filePath.compact'),
        _backupFile = File('$filePath.backup');

  final File _file;
  final File _lockFile;
  final File _compactionFile;
  final File _backupFile;

  @override
  Future<AuthoringIdempotencyRecord?> read(
    AuthoringIdempotencyScope scope,
  ) {
    return _withLock(() async {
      final records = await _readUnlocked();
      return records[scope.storageKey];
    });
  }

  @override
  Future<AuthoringIdempotencyReservation> reserve(
    AuthoringIdempotencyRecord pendingRecord,
  ) {
    if (pendingRecord.status != AuthoringIdempotencyStatus.pending) {
      throw ArgumentError.value(
        pendingRecord.status,
        'pendingRecord',
        'reserve requires a pending record',
      );
    }
    return _withLock(() async {
      final records = await _readUnlocked();
      final existing = records[pendingRecord.scope.storageKey];
      if (existing != null) {
        return AuthoringIdempotencyReservation(
          acquired: false,
          record: existing,
        );
      }
      await _appendUnlocked([_putEvent(pendingRecord)]);
      return AuthoringIdempotencyReservation(
        acquired: true,
        record: pendingRecord,
      );
    });
  }

  @override
  Future<AuthoringIdempotencyRecord> complete(
    AuthoringIdempotencyRecord completedRecord,
  ) {
    if (completedRecord.status != AuthoringIdempotencyStatus.completed) {
      throw ArgumentError.value(
        completedRecord.status,
        'completedRecord',
        'complete requires a completed record',
      );
    }
    return _withLock(() async {
      final records = await _readUnlocked();
      final existing = records[completedRecord.scope.storageKey];
      if (existing == null ||
          existing.payloadFingerprint != completedRecord.payloadFingerprint ||
          existing.operationId != completedRecord.operationId) {
        throw const IdempotencyStoreException(
          'idempotency.completion_conflict',
          'The durable reservation cannot be completed safely.',
        );
      }
      if (existing.status == AuthoringIdempotencyStatus.completed) {
        if (canonicalAuthoringJson(existing.receipt!.toJson()) !=
            canonicalAuthoringJson(completedRecord.receipt!.toJson())) {
          throw const IdempotencyStoreException(
            'idempotency.completion_conflict',
            'A different receipt already completed this reservation.',
          );
        }
        return existing;
      }
      await _appendUnlocked([_putEvent(completedRecord)]);
      return completedRecord;
    });
  }

  @override
  Future<int> pruneExpired(DateTime now) {
    return _withLock(() async {
      final utcNow = now.toUtc();
      final records = await _readUnlocked();
      final expired = records.values
          .where(
            (record) =>
                record.status == AuthoringIdempotencyStatus.completed &&
                !utcNow.isBefore(record.expiresAt!),
          )
          .toList(growable: false);
      if (expired.isNotEmpty) {
        await _appendUnlocked([
          for (final record in expired) _removeEvent(record.scope),
        ]);
        for (final record in expired) {
          records.remove(record.scope.storageKey);
        }
        await _compactUnlocked(records);
      }
      return expired.length;
    });
  }

  Future<T> _withLock<T>(Future<T> Function() operation) async {
    RandomAccessFile? lock;
    try {
      await _file.parent.create(recursive: true);
      lock = await _lockFile.open(mode: FileMode.append);
      await lock.lock(FileLock.exclusive);
      await _recoverCompactionUnlocked();
      return await operation();
    } on IdempotencyStoreException {
      rethrow;
    } on Object {
      throw const IdempotencyStoreException(
        'idempotency.store_io',
        'The durable idempotency store could not be accessed safely.',
      );
    } finally {
      if (lock != null) {
        try {
          await lock.unlock();
        } on Object {
          // Closing releases the OS lock even if explicit unlock fails.
        }
        await lock.close();
      }
    }
  }

  Future<Map<String, AuthoringIdempotencyRecord>> _readUnlocked() async {
    if (!await _file.exists()) return {};
    final bytes = await _file.readAsBytes();
    final records = <String, AuthoringIdempotencyRecord>{};
    var lineStart = 0;
    for (var index = 0; index < bytes.length; index++) {
      if (bytes[index] != 0x0a) continue;
      final lineBytes = bytes.sublist(lineStart, index);
      lineStart = index + 1;
      if (lineBytes.isEmpty) continue;
      try {
        final decoded = jsonDecode(utf8.decode(lineBytes));
        if (decoded is! Map) throw const FormatException();
        _applyEvent(records, Map<String, dynamic>.from(decoded));
      } on Object {
        throw const IdempotencyStoreException(
          'idempotency.store_corrupt',
          'The durable idempotency store contains an invalid event.',
        );
      }
    }
    // Bytes after the final newline are an uncommitted partial append. They
    // cannot authorize a replay and are deliberately ignored.
    return records;
  }

  Future<void> _appendUnlocked(List<Map<String, Object?>> events) async {
    final writer = await _file.open(mode: FileMode.append);
    try {
      await writer.writeString(
        events.map(jsonEncode).map((line) => '$line\n').join(),
      );
      await writer.flush();
    } finally {
      await writer.close();
    }
  }

  /// Rewrites only live records after durable tombstones have been flushed.
  ///
  /// The old log is renamed to a backup before the compacted log is promoted.
  /// Recovery can therefore select a complete compacted file or restore the
  /// tombstoned backup after a process stop at either rename boundary.
  Future<void> _compactUnlocked(
    Map<String, AuthoringIdempotencyRecord> records,
  ) async {
    await _deleteIfExists(_compactionFile);
    final orderedKeys = records.keys.toList()..sort();
    final writer = await _compactionFile.open(mode: FileMode.write);
    try {
      await writer.writeString(
        orderedKeys
            .map((key) => jsonEncode(_putEvent(records[key]!)))
            .map((line) => '$line\n')
            .join(),
      );
      await writer.flush();
    } finally {
      await writer.close();
    }

    await _deleteIfExists(_backupFile);
    if (await _file.exists()) {
      await _file.rename(_backupFile.path);
    }
    await _compactionFile.rename(_file.path);
    await _deleteIfExists(_backupFile);
  }

  Future<void> _recoverCompactionUnlocked() async {
    if (await _file.exists()) {
      await _deleteIfExists(_compactionFile);
      await _deleteIfExists(_backupFile);
      return;
    }
    if (await _compactionFile.exists()) {
      await _compactionFile.rename(_file.path);
      await _deleteIfExists(_backupFile);
      return;
    }
    if (await _backupFile.exists()) {
      await _backupFile.rename(_file.path);
    }
  }
}

Future<void> _deleteIfExists(File file) async {
  if (await file.exists()) await file.delete();
}

Map<String, Object?> _putEvent(AuthoringIdempotencyRecord record) => {
      'schemaVersion': 1,
      'event': 'put',
      'record': record.toJson(),
    };

Map<String, Object?> _removeEvent(AuthoringIdempotencyScope scope) => {
      'schemaVersion': 1,
      'event': 'remove',
      'scope': scope.toJson(),
    };

void _applyEvent(
  Map<String, AuthoringIdempotencyRecord> records,
  Map<String, dynamic> event,
) {
  if (event['schemaVersion'] != 1) throw const FormatException();
  switch (event['event']) {
    case 'put':
      final rawRecord = event['record'];
      if (rawRecord is! Map) throw const FormatException();
      final record = AuthoringIdempotencyRecord.fromJson(
        Map<String, dynamic>.from(rawRecord),
      );
      records[record.scope.storageKey] = record;
      return;
    case 'remove':
      final rawScope = event['scope'];
      if (rawScope is! Map) throw const FormatException();
      final scope = AuthoringIdempotencyScope.fromJson(
        Map<String, dynamic>.from(rawScope),
      );
      records.remove(scope.storageKey);
      return;
    default:
      throw const FormatException();
  }
}
~~~~~~~~

## `packages/map_authoring/lib/src/transactions/idempotency_ledger.dart`

~~~~~~~~dart
import 'dart:async';

import '../contracts/authoring_receipt.dart';
import '../contracts/authoring_request.dart';
import '../ports/idempotency_store.dart';
import '../support/authoring_fingerprint.dart';

typedef AuthoringIdempotencyClock = DateTime Function();

final class AuthoringIdempotencyException implements Exception {
  AuthoringIdempotencyException({
    required this.code,
    required this.message,
    Iterable<String> remediation = const [],
  }) : remediation = List.unmodifiable(remediation);

  final String code;
  final String message;
  final List<String> remediation;

  @override
  String toString() => 'AuthoringIdempotencyException($code): $message';
}

/// Reserves a durable mutation identity before invoking an apply callback.
final class AuthoringIdempotencyLedger {
  AuthoringIdempotencyLedger({
    required IdempotencyStore store,
    AuthoringIdempotencyClock? clock,
    this.completedRetention = const Duration(days: 30),
  })  : _store = store,
        _clock = clock ?? _systemClock {
    if (completedRetention <= Duration.zero) {
      throw ArgumentError.value(
        completedRetention,
        'completedRetention',
        'must be positive',
      );
    }
  }

  final IdempotencyStore _store;
  final AuthoringIdempotencyClock _clock;
  final Duration completedRetention;

  Future<AuthoringReceipt> execute({
    required AuthoringIdempotencyScope scope,
    required AuthoringRequest request,
    required String operationId,
    required FutureOr<AuthoringReceipt> Function() apply,
  }) async {
    _requireScopeMatchesRequest(scope, request);
    final now = _clock().toUtc();
    final payloadFingerprint = computeAuthoringJsonFingerprint(
      {
        'parameters': request.parameters,
        'expectedRevision': request.expectedRevision,
        'dryRun': request.dryRun,
        'extensions': request.extensions,
      },
      logicalName: 'idempotency-payload.json',
    );
    final pending = AuthoringIdempotencyRecord(
      scope: scope,
      payloadFingerprint: payloadFingerprint,
      operationId: operationId,
      status: AuthoringIdempotencyStatus.pending,
      createdAt: now,
    );
    final reservation = await _store.reserve(pending);
    if (!reservation.acquired) {
      final existing = reservation.record;
      if (existing.payloadFingerprint != payloadFingerprint) {
        throw AuthoringIdempotencyException(
          code: 'idempotency.payload_conflict',
          message: 'This idempotency key was used with another payload.',
          remediation: const ['Use a new idempotency key for a new mutation.'],
        );
      }
      if (existing.status == AuthoringIdempotencyStatus.completed) {
        return existing.receipt!;
      }
      throw AuthoringIdempotencyException(
        code: 'idempotency.recovery_required',
        message: 'A durable mutation reservation has no final receipt yet.',
        remediation: const [
          'Inspect and recover the pending transaction before retrying.',
        ],
      );
    }

    // Any exception after the flushed reservation intentionally leaves it
    // pending. The caller may already have made a write visible, so deleting
    // the reservation here would make an automatic retry unsafe.
    final receipt = await Future<AuthoringReceipt>.sync(apply);
    _validateReceipt(receipt, request);
    final completed = AuthoringIdempotencyRecord(
      scope: scope,
      payloadFingerprint: payloadFingerprint,
      operationId: operationId,
      status: AuthoringIdempotencyStatus.completed,
      createdAt: now,
      expiresAt: now.add(completedRetention),
      receipt: receipt,
    );
    return (await _store.complete(completed)).receipt!;
  }

  Future<int> pruneExpired() => _store.pruneExpired(_clock().toUtc());
}

void _requireScopeMatchesRequest(
  AuthoringIdempotencyScope scope,
  AuthoringRequest request,
) {
  final key = request.idempotencyKey;
  if (scope.actionId != request.actionId ||
      scope.actionVersion != request.actionVersion ||
      key == null ||
      !scope.matchesKey(key)) {
    throw AuthoringIdempotencyException(
      code: 'idempotency.scope_mismatch',
      message: 'The durable idempotency scope does not match the request.',
      remediation: const ['Rebuild the scope from the mutation request.'],
    );
  }
  if (request.dryRun) {
    throw AuthoringIdempotencyException(
      code: 'idempotency.apply_required',
      message: 'Dry-run planning must not reserve a durable apply key.',
    );
  }
}

void _validateReceipt(AuthoringReceipt receipt, AuthoringRequest request) {
  if (receipt.requestId != request.requestId ||
      receipt.actionId != request.actionId ||
      receipt.actionVersion != request.actionVersion ||
      receipt.status == AuthoringReceiptStatus.planned) {
    throw AuthoringIdempotencyException(
      code: 'idempotency.receipt_invalid',
      message: 'The apply callback returned an incompatible receipt.',
      remediation: const [
        'Recover the pending mutation and rebuild its canonical receipt.',
      ],
    );
  }
}

DateTime _systemClock() => DateTime.now().toUtc();
~~~~~~~~

## `packages/map_authoring/lib/src/transactions/revision_set.dart`

~~~~~~~~dart
import '../contracts/resource_ref.dart';
import '../support/authoring_fingerprint.dart';
import 'change_set.dart';

final class AuthoringResourceRevision {
  AuthoringResourceRevision({
    required this.resource,
    required String? revision,
  }) : revision = _optionalRevision(revision) {
    if (resource.revision != null && resource.revision != this.revision) {
      throw ArgumentError.value(
        resource.revision,
        'resource.revision',
        'must match the explicit resource revision',
      );
    }
  }

  factory AuthoringResourceRevision.fromJson(Map<String, dynamic> json) {
    if (json.keys.any((key) => !const {'resource', 'revision'}.contains(key))) {
      throw const FormatException('Unknown resource revision field.');
    }
    final rawResource = json['resource'];
    if (rawResource is! Map || !json.containsKey('revision')) {
      throw const FormatException(
        'resource must be an object and revision must be present.',
      );
    }
    final rawRevision = json['revision'];
    if (rawRevision != null && rawRevision is! String) {
      throw const FormatException('revision must be a string or null.');
    }
    try {
      return AuthoringResourceRevision(
        resource: AuthoringResourceRef.fromJson(
          Map<String, dynamic>.from(rawResource),
        ),
        revision: rawRevision as String?,
      );
    } on ArgumentError catch (error) {
      throw FormatException(error.message.toString());
    }
  }

  final AuthoringResourceRef resource;

  /// Null is an explicit, compareable "resource is absent" revision.
  final String? revision;

  Map<String, Object?> toJson() => {
        'resource': resource.toJson(),
        'revision': revision,
      };
}

final class AuthoringRevisionConflictEntry {
  const AuthoringRevisionConflictEntry({
    required this.resource,
    required this.expectedKnown,
    required this.expectedRevision,
    required this.currentKnown,
    required this.currentRevision,
  });

  final AuthoringResourceRef resource;
  final bool expectedKnown;
  final String? expectedRevision;
  final bool currentKnown;
  final String? currentRevision;

  Map<String, Object?> toJson() => {
        'resource': resource.toJson(),
        'expectedKnown': expectedKnown,
        'expectedRevision': expectedRevision,
        'currentKnown': currentKnown,
        'currentRevision': currentRevision,
      };
}

final class AuthoringRevisionConflict implements Exception {
  AuthoringRevisionConflict(Iterable<AuthoringRevisionConflictEntry> conflicts)
      : conflicts = List.unmodifiable(conflicts);

  final String code = 'revision.conflict';
  final List<AuthoringRevisionConflictEntry> conflicts;
  final List<String> remediation = const [
    'Reload the touched resources and create a new mutation plan.',
  ];

  @override
  String toString() =>
      'AuthoringRevisionConflict($code): ${conflicts.length} resource(s)';
}

/// Exact expected/current revisions for a touched resource set.
final class AuthoringRevisionSet {
  AuthoringRevisionSet(Iterable<AuthoringResourceRevision> entries)
      : entries = _sortedEntries(entries) {
    final byKey = <String, AuthoringResourceRevision>{};
    for (final entry in this.entries) {
      final key = _resourceKey(entry.resource);
      if (byKey.containsKey(key)) {
        throw ArgumentError.value(
          entry.resource.toJson(),
          'entries',
          'resource revisions must be unique',
        );
      }
      byKey[key] = entry;
    }
    _byKey = Map.unmodifiable(byKey);
    fingerprint = computeAuthoringJsonFingerprint(
      [for (final entry in this.entries) entry.toJson()],
      logicalName: 'revision-set.json',
    );
  }

  factory AuthoringRevisionSet.beforeChangeSet(AuthoringChangeSet changeSet) {
    return AuthoringRevisionSet([
      for (final change in changeSet.changes)
        AuthoringResourceRevision(
          resource: change.resource,
          revision: change.beforeRevision,
        ),
    ]);
  }

  factory AuthoringRevisionSet.afterChangeSet(AuthoringChangeSet changeSet) {
    return AuthoringRevisionSet([
      for (final change in changeSet.changes)
        AuthoringResourceRevision(
          resource: change.resource,
          revision: change.afterRevision,
        ),
    ]);
  }

  factory AuthoringRevisionSet.fromJson(Map<String, dynamic> json) {
    if (json.keys
        .any((key) => !const {'entries', 'fingerprint'}.contains(key))) {
      throw const FormatException('Unknown revision set field.');
    }
    final rawEntries = json['entries'];
    final rawFingerprint = json['fingerprint'];
    if (rawEntries is! List || rawFingerprint is! String) {
      throw const FormatException(
        'entries must be a list and fingerprint must be a string.',
      );
    }
    final set = AuthoringRevisionSet(rawEntries.map((rawEntry) {
      if (rawEntry is! Map) {
        throw const FormatException('revision entry must be an object.');
      }
      return AuthoringResourceRevision.fromJson(
        Map<String, dynamic>.from(rawEntry),
      );
    }));
    if (set.fingerprint != rawFingerprint) {
      throw const FormatException('revision set fingerprint does not match.');
    }
    return set;
  }

  final List<AuthoringResourceRevision> entries;
  late final Map<String, AuthoringResourceRevision> _byKey;
  late final String fingerprint;

  bool contains(AuthoringResourceRef resource) =>
      _byKey.containsKey(_resourceKey(resource));

  String? revisionOf(AuthoringResourceRef resource) =>
      _byKey[_resourceKey(resource)]?.revision;

  void requireMatches(AuthoringRevisionSet current) {
    final conflicts = <AuthoringRevisionConflictEntry>[];
    final keys = {..._byKey.keys, ...current._byKey.keys}.toList()..sort();
    for (final key in keys) {
      final expectedEntry = _byKey[key];
      final currentEntry = current._byKey[key];
      if (expectedEntry == null ||
          currentEntry == null ||
          expectedEntry.revision != currentEntry.revision) {
        conflicts.add(
          AuthoringRevisionConflictEntry(
            resource: expectedEntry?.resource ?? currentEntry!.resource,
            expectedKnown: expectedEntry != null,
            expectedRevision: expectedEntry?.revision,
            currentKnown: currentEntry != null,
            currentRevision: currentEntry?.revision,
          ),
        );
      }
    }
    if (conflicts.isNotEmpty) {
      throw AuthoringRevisionConflict(conflicts);
    }
  }

  T guard<T>(AuthoringRevisionSet current, T Function() mutation) {
    requireMatches(current);
    return mutation();
  }

  Map<String, Object?> toJson() => {
        'entries': [for (final entry in entries) entry.toJson()],
        'fingerprint': fingerprint,
      };
}

List<AuthoringResourceRevision> _sortedEntries(
  Iterable<AuthoringResourceRevision> entries,
) {
  final sorted = entries.toList()
    ..sort((left, right) =>
        _resourceKey(left.resource).compareTo(_resourceKey(right.resource)));
  return List.unmodifiable(sorted);
}

String? _optionalRevision(String? value) {
  if (value != null && !RegExp(r'^sha256:[0-9a-f]{64}$').hasMatch(value)) {
    throw ArgumentError.value(
      value,
      'revision',
      'must be null or a lowercase SHA-256 fingerprint',
    );
  }
  return value;
}

String _resourceKey(AuthoringResourceRef resource) =>
    '${resource.kind}\u0000${resource.id}';
~~~~~~~~

## `packages/map_authoring/test/transactions/idempotency_contract_test.dart`

~~~~~~~~dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:test/test.dart';

void main() {
  group('durable authoring idempotency', () {
    late Directory sandbox;
    late String ledgerPath;
    late DateTime now;

    setUp(() async {
      sandbox = await Directory.systemTemp.createTemp('pokemap_idempotency_');
      addTearDown(() => sandbox.delete(recursive: true));
      ledgerPath = '${sandbox.path}${Platform.pathSeparator}ledger.jsonl';
      now = DateTime.utc(2026, 7, 31, 12);
    });

    test('same scoped key and payload replays one exact receipt after reopen',
        () async {
      final scope = _scope();
      var applyCount = 0;
      final firstRequest = _request(requestId: 'req-first');
      final firstLedger = _ledger(ledgerPath, () => now);

      final first = await firstLedger.execute(
        scope: scope,
        request: firstRequest,
        operationId: 'operation-first',
        apply: () async {
          applyCount++;
          return _receipt(firstRequest, 'receipt-first');
        },
      );

      final reopenedLedger = _ledger(ledgerPath, () => now);
      final retry = await reopenedLedger.execute(
        scope: scope,
        request: _request(requestId: 'req-retry'),
        operationId: 'operation-retry',
        apply: () async {
          applyCount++;
          return _receipt(firstRequest, 'receipt-duplicate');
        },
      );

      expect(applyCount, 1);
      expect(retry.toJson(), first.toJson());
      expect(retry.requestId, 'req-first');
      expect(await File(ledgerPath).exists(), isTrue);
      final durableText = await File(ledgerPath).readAsString();
      expect(durableText, isNot(contains('key-shared')));
      expect(durableText, isNot(contains('workspace:ephemeral')));
    });

    test('same scoped key with a different canonical payload is refused',
        () async {
      final ledger = _ledger(ledgerPath, () => now);
      final firstRequest = _request(requestId: 'req-first');
      await ledger.execute(
        scope: _scope(),
        request: firstRequest,
        operationId: 'operation-first',
        apply: () => _receipt(firstRequest, 'receipt-first'),
      );

      await expectLater(
        () => ledger.execute(
          scope: _scope(),
          request: _request(
            requestId: 'req-conflict',
            parameters: const {'amount': 2},
          ),
          operationId: 'operation-conflict',
          apply: () => throw StateError('must not apply'),
        ),
        throwsA(
          isA<AuthoringIdempotencyException>().having(
            (error) => error.code,
            'code',
            'idempotency.payload_conflict',
          ),
        ),
      );
    });

    test('actor project action version and key each scope reservations',
        () async {
      final ledger = _ledger(ledgerPath, () => now);
      var applies = 0;
      final scopes = [
        _scope(actorId: 'actor-a'),
        _scope(actorId: 'actor-b'),
        _scope(actorId: 'actor-a', projectId: 'project-b'),
        _scope(actorId: 'actor-a', actionVersion: 2, key: 'key-v2'),
        _scope(actorId: 'actor-a', key: 'key-other'),
      ];

      for (var index = 0; index < scopes.length; index++) {
        final scope = scopes[index];
        final request = _request(
          requestId: 'req-$index',
          actionVersion: scope.actionVersion,
          idempotencyKey: scope.key,
        );
        await ledger.execute(
          scope: scope,
          request: request,
          operationId: 'operation-$index',
          apply: () {
            applies++;
            return _receipt(request, 'receipt-$index');
          },
        );
      }

      expect(applies, scopes.length);
    });

    test('pending reservation survives failure and requires recovery',
        () async {
      final ledger = _ledger(ledgerPath, () => now);
      final request = _request(requestId: 'req-pending');
      var applies = 0;

      await expectLater(
        () => ledger.execute(
          scope: _scope(),
          request: request,
          operationId: 'operation-pending',
          apply: () {
            applies++;
            throw StateError('outcome unknown');
          },
        ),
        throwsStateError,
      );

      final reopened = _ledger(ledgerPath, () => now);
      await expectLater(
        () => reopened.execute(
          scope: _scope(),
          request: _request(requestId: 'req-retry'),
          operationId: 'operation-retry',
          apply: () {
            applies++;
            return _receipt(request, 'receipt-unsafe');
          },
        ),
        throwsA(
          isA<AuthoringIdempotencyException>().having(
            (error) => error.code,
            'code',
            'idempotency.recovery_required',
          ),
        ),
      );
      expect(applies, 1);
    });

    test('concurrent retry never invokes the apply callback twice', () async {
      final firstLedger = _ledger(ledgerPath, () => now);
      final secondLedger = _ledger(ledgerPath, () => now);
      final request = _request(requestId: 'req-concurrent');
      final enteredApply = Completer<void>();
      final releaseApply = Completer<void>();
      var applies = 0;

      final first = firstLedger.execute(
        scope: _scope(),
        request: request,
        operationId: 'operation-first',
        apply: () async {
          applies++;
          enteredApply.complete();
          await releaseApply.future;
          return _receipt(request, 'receipt-concurrent');
        },
      );
      await enteredApply.future;

      await expectLater(
        () => secondLedger.execute(
          scope: _scope(),
          request: _request(requestId: 'req-concurrent-retry'),
          operationId: 'operation-second',
          apply: () {
            applies++;
            return _receipt(request, 'receipt-duplicate');
          },
        ),
        throwsA(
          isA<AuthoringIdempotencyException>().having(
            (error) => error.code,
            'code',
            'idempotency.recovery_required',
          ),
        ),
      );
      releaseApply.complete();

      expect((await first).receiptId, 'receipt-concurrent');
      expect(applies, 1);
    });

    test('retention pruning removes expired completed records but not pending',
        () async {
      final store = FileIdempotencyStore(filePath: ledgerPath);
      final ledger = AuthoringIdempotencyLedger(
        store: store,
        clock: () => now,
        completedRetention: const Duration(hours: 1),
      );
      final completedScope = _scope(key: 'completed');
      final completedRequest = _request(
        requestId: 'req-completed',
        idempotencyKey: 'completed',
      );
      await ledger.execute(
        scope: completedScope,
        request: completedRequest,
        operationId: 'operation-completed',
        apply: () => _receipt(completedRequest, 'receipt-completed'),
      );

      final pendingScope = _scope(key: 'pending');
      final pendingRequest = _request(
        requestId: 'req-pending',
        idempotencyKey: 'pending',
      );
      await expectLater(
        () => ledger.execute(
          scope: pendingScope,
          request: pendingRequest,
          operationId: 'operation-pending',
          apply: () => throw StateError('pending'),
        ),
        throwsStateError,
      );
      now = now.add(const Duration(hours: 1));

      expect(await ledger.pruneExpired(), 1);
      expect(await store.read(completedScope), isNull);
      expect(
        (await store.read(pendingScope))?.status,
        AuthoringIdempotencyStatus.pending,
      );
      final compactedLines = await File(ledgerPath)
          .readAsLines()
          .then((lines) => lines.where((line) => line.isNotEmpty).toList());
      expect(compactedLines, hasLength(1));
      expect(compactedLines.single, contains('operation-pending'));
      expect(compactedLines.single, isNot(contains('receipt-completed')));
    });

    test('scope validation rejects path-like identities', () {
      expect(
        () => _scope(projectId: '/Users/private/project'),
        throwsArgumentError,
      );
      expect(
        () => _scope(actorId: r'C:\private\actor'),
        throwsArgumentError,
      );
    });

    test('reopens safely from either interrupted compaction boundary',
        () async {
      final scope = _scope();
      final request = _request(requestId: 'req-recovery');
      final ledger = _ledger(ledgerPath, () => now);
      await ledger.execute(
        scope: scope,
        request: request,
        operationId: 'operation-recovery',
        apply: () => _receipt(request, 'receipt-recovery'),
      );

      await File(ledgerPath).rename('$ledgerPath.backup');
      final backupRecovered = await FileIdempotencyStore(
        filePath: ledgerPath,
      ).read(scope);
      expect(backupRecovered?.receipt?.receiptId, 'receipt-recovery');
      expect(await File('$ledgerPath.backup').exists(), isFalse);

      await File(ledgerPath).copy('$ledgerPath.compact');
      await File(ledgerPath).rename('$ledgerPath.backup');
      final compactRecovered = await FileIdempotencyStore(
        filePath: ledgerPath,
      ).read(scope);
      expect(compactRecovered?.receipt?.receiptId, 'receipt-recovery');
      expect(await File('$ledgerPath.compact').exists(), isFalse);
      expect(await File('$ledgerPath.backup').exists(), isFalse);
    });

    test('reports corrupt durable events without leaking the store path',
        () async {
      await File(ledgerPath).writeAsString('{not-json}\n');

      await expectLater(
        () => FileIdempotencyStore(filePath: ledgerPath).read(_scope()),
        throwsA(
          isA<IdempotencyStoreException>()
              .having(
                (error) => error.code,
                'code',
                'idempotency.store_corrupt',
              )
              .having(
                (error) => error.toString(),
                'safe error',
                isNot(contains(sandbox.path)),
              ),
        ),
      );
    });
  });
}

AuthoringIdempotencyLedger _ledger(
  String filePath,
  DateTime Function() clock,
) {
  return AuthoringIdempotencyLedger(
    store: FileIdempotencyStore(filePath: filePath),
    clock: clock,
    completedRetention: const Duration(days: 30),
  );
}

AuthoringIdempotencyScope _scope({
  String actorId = 'actor-a',
  String projectId = 'project-a',
  int actionVersion = 1,
  String key = 'key-shared',
}) {
  return AuthoringIdempotencyScope(
    actorId: actorId,
    projectId: projectId,
    actionId: 'fixture.increment',
    actionVersion: actionVersion,
    key: key,
  );
}

AuthoringRequest _request({
  required String requestId,
  int actionVersion = 1,
  String idempotencyKey = 'key-shared',
  Map<String, Object?> parameters = const {'amount': 1},
}) {
  return AuthoringRequest(
    requestId: requestId,
    actionId: 'fixture.increment',
    actionVersion: actionVersion,
    workspaceHandle: 'workspace:ephemeral',
    parameters: parameters,
    expectedRevision: _revision('before'),
    idempotencyKey: idempotencyKey,
  );
}

AuthoringReceipt _receipt(AuthoringRequest request, String receiptId) {
  final resource = AuthoringResourceRef(kind: 'project', id: 'project-a');
  return AuthoringReceipt(
    receiptId: receiptId,
    requestId: request.requestId,
    actionId: request.actionId,
    actionVersion: request.actionVersion,
    status: AuthoringReceiptStatus.applied,
    beforeRevision: request.expectedRevision,
    afterRevision: _revision(receiptId),
    createdAtUtc: '2026-07-31T12:00:00.000Z',
    diff: AuthoringDiff([
      AuthoringDiffEntry(
        operation: AuthoringDiffOperation.replace,
        resource: resource,
        path: r'$.value',
        before: 0,
        after: 1,
      ),
    ]),
  );
}

String _revision(String value) => computeAuthoringBytesFingerprint(
      utf8.encode(value),
      logicalName: 'project.json',
    );
~~~~~~~~

## `packages/map_authoring/test/transactions/revision_conflict_test.dart`

~~~~~~~~dart
import 'dart:convert';

import 'package:map_authoring/map_authoring.dart';
import 'package:test/test.dart';

void main() {
  group('AuthoringRevisionSet', () {
    test('is deterministic across input order and JSON round trips', () {
      final mapA = AuthoringResourceRevision(
        resource: AuthoringResourceRef(kind: 'map', id: 'a'),
        revision: _revision('a'),
      );
      final mapB = AuthoringResourceRevision(
        resource: AuthoringResourceRef(kind: 'map', id: 'b'),
        revision: _revision('b'),
      );

      final first = AuthoringRevisionSet([mapB, mapA]);
      final second = AuthoringRevisionSet([mapA, mapB]);
      final decoded = AuthoringRevisionSet.fromJson(first.toJson());

      expect(first.toJson(), second.toJson());
      expect(first.fingerprint, second.fingerprint);
      expect(decoded.toJson(), first.toJson());
      expect(first.entries.map((entry) => entry.resource.id), ['a', 'b']);
    });

    test('supports explicit absent revisions for create and delete CAS', () {
      final create = AuthoringResourceChange(
        resource: AuthoringResourceRef(kind: 'map', id: 'created'),
        storageKey: 'maps/created.json',
        beforeBytes: null,
        afterBytes: utf8.encode('{"id":"created"}'),
      );
      final delete = AuthoringResourceChange(
        resource: AuthoringResourceRef(kind: 'map', id: 'deleted'),
        storageKey: 'maps/deleted.json',
        beforeBytes: utf8.encode('{"id":"deleted"}'),
        afterBytes: null,
      );
      final changes = AuthoringChangeSet(
        changes: [create, delete],
        diff: AuthoringDiff([
          AuthoringDiffEntry(
            operation: AuthoringDiffOperation.add,
            resource: create.resource,
            path: r'$',
            after: const {'id': 'created'},
          ),
          AuthoringDiffEntry(
            operation: AuthoringDiffOperation.remove,
            resource: delete.resource,
            path: r'$',
            before: const {'id': 'deleted'},
          ),
        ]),
      );

      final before = AuthoringRevisionSet.beforeChangeSet(changes);
      final after = AuthoringRevisionSet.afterChangeSet(changes);

      expect(before.revisionOf(create.resource), isNull);
      expect(before.revisionOf(delete.resource), delete.beforeRevision);
      expect(after.revisionOf(create.resource), create.afterRevision);
      expect(after.revisionOf(delete.resource), isNull);
    });

    test('rejects duplicate resources and malformed fingerprints', () {
      final resource = AuthoringResourceRef(kind: 'map', id: 'same');

      expect(
        () => AuthoringRevisionSet([
          AuthoringResourceRevision(
              resource: resource, revision: _revision('a')),
          AuthoringResourceRevision(
              resource: resource, revision: _revision('b')),
        ]),
        throwsArgumentError,
      );
      expect(
        () => AuthoringResourceRevision(
          resource: resource,
          revision: 'not-a-fingerprint',
        ),
        throwsArgumentError,
      );
      expect(
        () => AuthoringResourceRevision(
          resource: AuthoringResourceRef(
            kind: 'map',
            id: 'same',
            revision: _revision('a'),
          ),
          revision: _revision('b'),
        ),
        throwsArgumentError,
      );
    });

    test('blocks mutation callback when any touched revision changed', () {
      final resourceA = AuthoringResourceRef(kind: 'map', id: 'a');
      final resourceB = AuthoringResourceRef(kind: 'map', id: 'b');
      final expected = AuthoringRevisionSet([
        AuthoringResourceRevision(
            resource: resourceA, revision: _revision('a')),
        AuthoringResourceRevision(
            resource: resourceB, revision: _revision('b')),
      ]);
      final current = AuthoringRevisionSet([
        AuthoringResourceRevision(
            resource: resourceA, revision: _revision('a')),
        AuthoringResourceRevision(
          resource: resourceB,
          revision: _revision('externally-changed'),
        ),
      ]);
      var mutations = 0;

      expect(
        () => expected.guard(current, () => mutations++),
        throwsA(
          isA<AuthoringRevisionConflict>()
              .having((error) => error.code, 'code', 'revision.conflict')
              .having(
                (error) => error.conflicts.single.resource.id,
                'resource',
                'b',
              ),
        ),
      );
      expect(mutations, 0);
    });

    test('treats unexpected presence and missing current entries as conflicts',
        () {
      final resource = AuthoringResourceRef(kind: 'map', id: 'new');
      final expectsAbsent = AuthoringRevisionSet([
        AuthoringResourceRevision(resource: resource, revision: null),
      ]);
      final unexpectedlyPresent = AuthoringRevisionSet([
        AuthoringResourceRevision(
          resource: resource,
          revision: _revision('present'),
        ),
      ]);

      expect(
        () => expectsAbsent.requireMatches(unexpectedlyPresent),
        throwsA(isA<AuthoringRevisionConflict>()),
      );
      expect(
        () =>
            unexpectedlyPresent.requireMatches(AuthoringRevisionSet(const [])),
        throwsA(isA<AuthoringRevisionConflict>()),
      );
    });
  });
}

String _revision(String value) => computeAuthoringBytesFingerprint(
      utf8.encode(value),
      logicalName: 'resource.json',
    );
~~~~~~~~
