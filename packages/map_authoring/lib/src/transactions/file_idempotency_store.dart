import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

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

typedef FileIdempotencyDecodeWorkerRunner = Future<T> Function<T>(
  T Function() operation,
);

final class FileIdempotencyDecodeDiagnostics {
  const FileIdempotencyDecodeDiagnostics({
    required this.localOperations,
    required this.workerOperations,
    required this.workerFailures,
  });

  final int localOperations;
  final int workerOperations;
  final int workerFailures;
}

final class FileIdempotencyDecodeExecutor {
  FileIdempotencyDecodeExecutor({
    this.offloadThresholdBytes = defaultOffloadThresholdBytes,
    FileIdempotencyDecodeWorkerRunner? workerRunner,
  }) : _workerRunner = workerRunner ?? _runFileIdempotencyDecodeWorker {
    if (offloadThresholdBytes < 0) {
      throw ArgumentError.value(
        offloadThresholdBytes,
        'offloadThresholdBytes',
        'must not be negative',
      );
    }
  }

  static const int defaultOffloadThresholdBytes = 1024 * 1024;

  final int offloadThresholdBytes;
  final FileIdempotencyDecodeWorkerRunner _workerRunner;

  var _localOperations = 0;
  var _workerOperations = 0;
  var _workerFailures = 0;

  FileIdempotencyDecodeDiagnostics get diagnostics =>
      FileIdempotencyDecodeDiagnostics(
        localOperations: _localOperations,
        workerOperations: _workerOperations,
        workerFailures: _workerFailures,
      );

  Future<_FileIdempotencyDecodeResult> _decode(Uint8List bytes) async {
    if (bytes.length < offloadThresholdBytes) {
      _localOperations++;
      return _decodeFileIdempotencyEvents(bytes);
    }
    final transferred = TransferableTypedData.fromList([bytes]);
    _workerOperations++;
    try {
      return await _workerRunner(
        () => _decodeFileIdempotencyEvents(
          transferred.materialize().asUint8List(),
        ),
      );
    } on Object {
      _workerFailures++;
      rethrow;
    }
  }
}

Future<T> _runFileIdempotencyDecodeWorker<T>(T Function() operation) =>
    Isolate.run(operation);

final class _FileIdempotencyDecodeResult {
  const _FileIdempotencyDecodeResult({
    required this.indexes,
    required this.eventCount,
  });

  final Map<String, _IndexedIdempotencyRecord> indexes;
  final int eventCount;
}

final class FileIdempotencyStoreDiagnostics {
  const FileIdempotencyStoreDiagnostics({
    required this.indexedRecords,
    required this.materializedRecords,
  });

  final int indexedRecords;
  final int materializedRecords;
}

final class _IndexedIdempotencyRecord {
  const _IndexedIdempotencyRecord({
    required this.scope,
    required this.payloadFingerprint,
    required this.operationId,
    required this.status,
    required this.createdAt,
    required this.expiresAt,
    required this.lineStart,
    required this.lineEnd,
  });

  factory _IndexedIdempotencyRecord.fromRecord(
    AuthoringIdempotencyRecord record, {
    required int lineStart,
    required int lineEnd,
  }) =>
      _IndexedIdempotencyRecord(
        scope: record.scope,
        payloadFingerprint: record.payloadFingerprint,
        operationId: record.operationId,
        status: record.status,
        createdAt: record.createdAt,
        expiresAt: record.expiresAt,
        lineStart: lineStart,
        lineEnd: lineEnd,
      );

  final AuthoringIdempotencyScope scope;
  final String payloadFingerprint;
  final String operationId;
  final AuthoringIdempotencyStatus status;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final int lineStart;
  final int lineEnd;

  bool matches(AuthoringIdempotencyRecord record) =>
      record.scope.storageKey == scope.storageKey &&
      record.payloadFingerprint == payloadFingerprint &&
      record.operationId == operationId &&
      record.status == status &&
      record.createdAt == createdAt &&
      record.expiresAt == expiresAt;
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
    FileIdempotencyDecodeExecutor? decodeExecutor,
  })  : _file = File(filePath),
        _lockFile = File('$filePath.lock'),
        _compactionFile = File('$filePath.compact'),
        _backupFile = File('$filePath.backup'),
        _onFullRead = onFullRead,
        _performanceObserver = performanceObserver,
        _decodeExecutor = decodeExecutor ?? FileIdempotencyDecodeExecutor();

  final File _file;
  final File _lockFile;
  final File _compactionFile;
  final File _backupFile;
  final void Function()? _onFullRead;
  Map<String, _IndexedIdempotencyRecord> _cachedIndexes = {};
  AuthoringFileSnapshot? _cachedSnapshot;
  bool _cacheInitialized = false;
  var _materializedRecords = 0;
  final AuthoringPerformanceObserver? _performanceObserver;
  final FileIdempotencyDecodeExecutor _decodeExecutor;

  FileIdempotencyStoreDiagnostics get diagnostics =>
      FileIdempotencyStoreDiagnostics(
        indexedRecords: _cachedIndexes.length,
        materializedRecords: _materializedRecords,
      );

  @override
  Future<AuthoringIdempotencyRecord?> read(AuthoringIdempotencyScope scope) {
    return _withLock(() async {
      final indexes = await _readIndexUnlocked();
      final indexed = indexes[scope.storageKey];
      return indexed == null ? null : _materializeRecord(indexed);
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
      final indexes = await _readIndexUnlocked();
      final existing = indexes[pendingRecord.scope.storageKey];
      if (existing != null) {
        return AuthoringIdempotencyReservation(
          acquired: false,
          record: await _materializeRecord(existing),
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
      final indexes = await _readIndexUnlocked();
      final existing = indexes[completedRecord.scope.storageKey];
      if (existing == null ||
          existing.payloadFingerprint != completedRecord.payloadFingerprint ||
          existing.operationId != completedRecord.operationId) {
        throw const IdempotencyStoreException(
          'idempotency.completion_conflict',
          'The durable reservation cannot be completed safely.',
        );
      }
      if (existing.status == AuthoringIdempotencyStatus.completed) {
        final materialized = await _materializeRecord(existing);
        if (canonicalAuthoringJson(materialized.receipt!.toJson()) !=
            canonicalAuthoringJson(completedRecord.receipt!.toJson())) {
          throw const IdempotencyStoreException(
            'idempotency.completion_conflict',
            'A different receipt already completed this reservation.',
          );
        }
        return materialized;
      }
      await _appendUnlocked([_putEvent(completedRecord)]);
      return completedRecord;
    });
  }

  @override
  Future<int> pruneExpired(DateTime now) {
    return _withLock(() async {
      final utcNow = now.toUtc();
      final indexes = await _readIndexUnlocked();
      final expired = indexes.values
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
        final records = <String, AuthoringIdempotencyRecord>{};
        for (final indexed in _cachedIndexes.values) {
          records[indexed.scope.storageKey] = await _materializeRecord(indexed);
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

  Future<Map<String, _IndexedIdempotencyRecord>> _readIndexUnlocked() async {
    final snapshot = await AuthoringFileSnapshot.capture(_file);
    if (_cacheInitialized && snapshot == _cachedSnapshot) {
      return Map<String, _IndexedIdempotencyRecord>.of(_cachedIndexes);
    }
    _onFullRead?.call();
    if (snapshot == null) {
      _cachedIndexes = {};
      _cachedSnapshot = null;
      _cacheInitialized = true;
      return {};
    }
    _performanceObserver?.incrementCounter(
      AuthoringPerformanceCounterName.filesystemRead,
    );
    final bytes = await _file.readAsBytes();
    late final _FileIdempotencyDecodeResult decoded;
    try {
      decoded = await _decodeExecutor._decode(bytes);
    } on Object {
      throw const IdempotencyStoreException(
        'idempotency.store_corrupt',
        'The durable idempotency store contains an invalid event.',
      );
    }
    _performanceObserver?.incrementCounter(
      AuthoringPerformanceCounterName.jsonDecode,
      by: decoded.eventCount,
    );
    final indexes = decoded.indexes;
    _cachedIndexes = Map<String, _IndexedIdempotencyRecord>.of(indexes);
    _cachedSnapshot = snapshot;
    _cacheInitialized = true;
    return indexes;
  }

  Future<AuthoringIdempotencyRecord> _materializeRecord(
    _IndexedIdempotencyRecord indexed,
  ) async {
    _performanceObserver?.incrementCounter(
      AuthoringPerformanceCounterName.filesystemRead,
    );
    final reader = await _file.open();
    try {
      await reader.setPosition(indexed.lineStart);
      final bytes = await reader.read(indexed.lineEnd - indexed.lineStart);
      if (bytes.length != indexed.lineEnd - indexed.lineStart) {
        throw const FormatException();
      }
      _performanceObserver?.incrementCounter(
        AuthoringPerformanceCounterName.jsonDecode,
      );
      final decoded = jsonDecode(utf8.decode(bytes));
      if (decoded is! Map) throw const FormatException();
      final record = _recordFromPutEvent(Map<String, dynamic>.from(decoded));
      if (!indexed.matches(record)) throw const FormatException();
      _materializedRecords++;
      return record;
    } on FormatException {
      throw const IdempotencyStoreException(
        'idempotency.store_corrupt',
        'The durable idempotency store contains an invalid event.',
      );
    } finally {
      await reader.close();
    }
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
    final indexes = Map<String, _IndexedIdempotencyRecord>.of(_cachedIndexes);
    try {
      var offset = await writer.length();
      for (final event in events) {
        final lineBytes = utf8.encode('${jsonEncode(event)}\n');
        await writer.writeFrom(lineBytes);
        _applyIndexedEvent(
          indexes,
          Map<String, dynamic>.from(event),
          lineStart: offset,
          lineEnd: offset + lineBytes.length - 1,
        );
        offset += lineBytes.length;
      }
      await writer.flush();
    } finally {
      await writer.close();
    }
    if (_cacheInitialized) {
      _cachedIndexes = indexes;
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
    final indexes = <String, _IndexedIdempotencyRecord>{};
    try {
      var offset = 0;
      for (final key in orderedKeys) {
        final event = _putEvent(records[key]!);
        final lineBytes = utf8.encode('${jsonEncode(event)}\n');
        await writer.writeFrom(lineBytes);
        _applyIndexedEvent(
          indexes,
          Map<String, dynamic>.from(event),
          lineStart: offset,
          lineEnd: offset + lineBytes.length - 1,
        );
        offset += lineBytes.length;
      }
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
    _cachedIndexes = indexes;
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

void _applyIndexedEvent(
  Map<String, _IndexedIdempotencyRecord> indexes,
  Map<String, dynamic> event, {
  required int lineStart,
  required int lineEnd,
}) {
  if (event['schemaVersion'] != 1) throw const FormatException();
  switch (event['event']) {
    case 'put':
      final record = _recordFromPutEvent(event);
      indexes[record.scope.storageKey] = _IndexedIdempotencyRecord.fromRecord(
        record,
        lineStart: lineStart,
        lineEnd: lineEnd,
      );
      return;
    case 'remove':
      final rawScope = event['scope'];
      if (rawScope is! Map) throw const FormatException();
      final scope = AuthoringIdempotencyScope.fromJson(
        Map<String, dynamic>.from(rawScope),
      );
      indexes.remove(scope.storageKey);
      return;
    default:
      throw const FormatException();
  }
}

AuthoringIdempotencyRecord _recordFromPutEvent(
  Map<String, dynamic> event,
) {
  if (event['schemaVersion'] != 1 || event['event'] != 'put') {
    throw const FormatException();
  }
  final rawRecord = event['record'];
  if (rawRecord is! Map) throw const FormatException();
  return AuthoringIdempotencyRecord.fromJson(
    Map<String, dynamic>.from(rawRecord),
  );
}

_FileIdempotencyDecodeResult _decodeFileIdempotencyEvents(Uint8List bytes) {
  final indexes = <String, _IndexedIdempotencyRecord>{};
  var lineStart = 0;
  var eventCount = 0;
  for (var index = 0; index < bytes.length; index++) {
    if (bytes[index] != 0x0a) continue;
    if (lineStart != index) {
      final decoded = jsonDecode(utf8.decoder.convert(bytes, lineStart, index));
      if (decoded is! Map) throw const FormatException();
      _applyIndexedEvent(
        indexes,
        Map<String, dynamic>.from(decoded),
        lineStart: lineStart,
        lineEnd: index,
      );
      eventCount++;
    }
    lineStart = index + 1;
  }
  return _FileIdempotencyDecodeResult(
    indexes: indexes,
    eventCount: eventCount,
  );
}
