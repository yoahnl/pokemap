import 'dart:convert';
import 'dart:io';

import '../ports/idempotency_store.dart';
import '../support/authoring_file_snapshot.dart';
import '../support/authoring_fingerprint.dart';
import '../support/authoring_performance_observer.dart';

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
  FileIdempotencyStore({
    required String filePath,
    void Function()? onFullRead,
    AuthoringPerformanceObserver? performanceObserver,
  }) : _file = File(filePath),
       _lockFile = File('$filePath.lock'),
       _compactionFile = File('$filePath.compact'),
       _backupFile = File('$filePath.backup'),
       _onFullRead = onFullRead,
       _performanceObserver = performanceObserver;

  final File _file;
  final File _lockFile;
  final File _compactionFile;
  final File _backupFile;
  final void Function()? _onFullRead;
  Map<String, AuthoringIdempotencyRecord> _cachedRecords = {};
  AuthoringFileSnapshot? _cachedSnapshot;
  bool _cacheInitialized = false;
  final AuthoringPerformanceObserver? _performanceObserver;

  @override
  Future<AuthoringIdempotencyRecord?> read(AuthoringIdempotencyScope scope) {
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
    _performanceObserver?.incrementCounter(
      AuthoringPerformanceCounterName.filesystemMetadata,
    );
    _performanceObserver?.incrementCounter(
      AuthoringPerformanceCounterName.filesystemWrite,
    );
    RandomAccessFile? lock;
    try {
      await _requireSafePaths();
      lock = await _lockFile.open(mode: FileMode.append);
      await lock.lock(FileLock.exclusive);
      await _requireSafePaths();
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

  Future<void> _requireSafePaths() async {
    final metadataParents = <Directory>[];
    final hasMetadataRoot = _file.uri.pathSegments.contains('.pokemap');
    var current = _file.parent;
    while (true) {
      metadataParents.add(current);
      if (!hasMetadataRoot || _directoryName(current) == '.pokemap') break;
      final parent = current.parent;
      if (parent.path == current.path) {
        throw const IdempotencyStoreException(
          'idempotency.path_unsafe',
          'The durable idempotency metadata path is unsafe.',
        );
      }
      current = parent;
    }
    for (final directory in metadataParents.reversed) {
      var type = await FileSystemEntity.type(
        directory.path,
        followLinks: false,
      );
      if (type == FileSystemEntityType.notFound) {
        await directory.create();
        type = await FileSystemEntity.type(directory.path, followLinks: false);
      }
      if (type != FileSystemEntityType.directory) {
        throw const IdempotencyStoreException(
          'idempotency.path_unsafe',
          'The durable idempotency metadata path is unsafe.',
        );
      }
    }
    for (final file in [_file, _lockFile, _compactionFile, _backupFile]) {
      final type = await FileSystemEntity.type(file.path, followLinks: false);
      if (type != FileSystemEntityType.notFound &&
          type != FileSystemEntityType.file) {
        throw const IdempotencyStoreException(
          'idempotency.path_unsafe',
          'The durable idempotency metadata path is unsafe.',
        );
      }
    }
  }

  Future<Map<String, AuthoringIdempotencyRecord>> _readUnlocked() async {
    final snapshot = await AuthoringFileSnapshot.capture(_file);
    if (_cacheInitialized && snapshot == _cachedSnapshot) {
      return Map<String, AuthoringIdempotencyRecord>.of(_cachedRecords);
    }
    _onFullRead?.call();
    if (snapshot == null) {
      _cachedRecords = {};
      _cachedSnapshot = null;
      _cacheInitialized = true;
      return {};
    }
    _performanceObserver?.incrementCounter(
      AuthoringPerformanceCounterName.filesystemRead,
    );
    final bytes = await _file.readAsBytes();
    final records = <String, AuthoringIdempotencyRecord>{};
    var lineStart = 0;
    for (var index = 0; index < bytes.length; index++) {
      if (bytes[index] != 0x0a) continue;
      final lineBytes = bytes.sublist(lineStart, index);
      lineStart = index + 1;
      if (lineBytes.isEmpty) continue;
      try {
        _performanceObserver?.incrementCounter(
          AuthoringPerformanceCounterName.jsonDecode,
        );
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
    _cachedRecords = Map<String, AuthoringIdempotencyRecord>.of(records);
    _cachedSnapshot = snapshot;
    _cacheInitialized = true;
    return records;
  }

  Future<void> _appendUnlocked(List<Map<String, Object?>> events) async {
    _performanceObserver?.incrementCounter(
      AuthoringPerformanceCounterName.filesystemWrite,
    );
    _performanceObserver?.incrementCounter(
      AuthoringPerformanceCounterName.jsonEncode,
      by: events.length,
    );
    final writer = await _file.open(mode: FileMode.append);
    try {
      await writer.writeString(
        events.map(jsonEncode).map((line) => '$line\n').join(),
      );
      await writer.flush();
    } finally {
      await writer.close();
    }
    if (_cacheInitialized) {
      final records = Map<String, AuthoringIdempotencyRecord>.of(
        _cachedRecords,
      );
      for (final event in events) {
        _applyEvent(records, Map<String, dynamic>.from(event));
      }
      _cachedRecords = records;
      _cachedSnapshot = await AuthoringFileSnapshot.capture(_file);
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
    _performanceObserver?.incrementCounter(
      AuthoringPerformanceCounterName.filesystemWrite,
    );
    _performanceObserver?.incrementCounter(
      AuthoringPerformanceCounterName.jsonEncode,
      by: records.length,
    );
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
    _cachedRecords = Map<String, AuthoringIdempotencyRecord>.of(records);
    _cachedSnapshot = await AuthoringFileSnapshot.capture(_file);
    _cacheInitialized = true;
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

String _directoryName(Directory directory) {
  final segments = directory.uri.pathSegments
      .where((segment) => segment.isNotEmpty)
      .toList(growable: false);
  return segments.isEmpty ? '' : segments.last;
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
