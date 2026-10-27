import 'local_authoring_payload.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:io';

import '../ports/project_file_reader.dart';
import '../ports/transaction_file_gateway.dart';
import '../support/authoring_fingerprint.dart';
import '../support/authoring_performance_observer.dart';
import 'transaction_journal.dart';
import 'authoring_payload.dart';

/// Project-local filesystem adapter with atomic-per-file replacement.
///
/// Multi-file atomicity is deliberately not claimed. The journal and retained
/// staged payloads make the ordered sequence recoverable after any completed
/// filesystem call.
final class LocalTransactionFileGateway
    implements
        TransactionFileGateway,
        StreamingTransactionFileGateway,
        TransactionStagedArtifactProbe {
  LocalTransactionFileGateway._(
    this._projectRoot,
    this._performanceObserver,
    this._expectedProjectRoot,
    this._transactionNamespace,
  );

  static Future<LocalTransactionFileGateway> open({
    required String projectRoot,
    AuthoringPerformanceObserver? performanceObserver,
    String? expectedProjectRoot,
    String? transactionNamespace,
  }) async {
    if (transactionNamespace != null &&
        !RegExp(r'^[a-zA-Z0-9][a-zA-Z0-9_.-]{0,119}$')
            .hasMatch(transactionNamespace)) {
      throw ArgumentError.value(transactionNamespace, 'transactionNamespace');
    }
    try {
      final directory = Directory(projectRoot);
      if ((await directory.stat()).type != FileSystemEntityType.directory) {
        throw const TransactionFileGatewayException(
          'transaction.project_directory_required',
          'The transaction project root is not a directory.',
        );
      }
      final canonicalRoot = await directory.resolveSymbolicLinks();
      if (expectedProjectRoot != null &&
          (canonicalRoot != expectedProjectRoot ||
              await FileSystemEntity.type(projectRoot, followLinks: false) !=
                  FileSystemEntityType.directory)) {
        throw const TransactionFileGatewayException(
            'transaction.project_root_changed',
            'The reserved project root changed.');
      }
      return LocalTransactionFileGateway._(
        canonicalRoot,
        performanceObserver,
        expectedProjectRoot,
        transactionNamespace,
      );
    } on TransactionFileGatewayException {
      rethrow;
    } on Object {
      throw const TransactionFileGatewayException(
        'transaction.project_unavailable',
        'The transaction project root is unavailable.',
      );
    }
  }

  final String _projectRoot;
  final String? _expectedProjectRoot;
  final String? _transactionNamespace;
  final AuthoringPerformanceObserver? _performanceObserver;

  Future<LocalTransactionFileGateway> inNamespace(String namespace) => open(
      projectRoot: _projectRoot,
      expectedProjectRoot: _expectedProjectRoot,
      performanceObserver: _performanceObserver,
      transactionNamespace: namespace);

  @override
  Future<T> withExclusiveWriteLock<T>(Future<T> Function() operation) =>
      withLocalProjectWriteQueue(
          _projectRoot, () => _withFilesystemWriteLock(operation));

  Future<T> _withFilesystemWriteLock<T>(Future<T> Function() operation) async {
    late final RandomAccessFile lock;
    try {
      await _requireExpectedProjectRoot();
      final internalRoot = await _ensureInternalRoot(scoped: false);
      lock = await File(_join(internalRoot.path, 'write.lock')).open(
        mode: FileMode.append,
      );
      final queueSpan = _performanceObserver?.startSpan(
        AuthoringPerformanceSpanName.saveQueue,
      );
      try {
        await lock.lock(FileLock.exclusive);
      } finally {
        queueSpan?.finish();
      }
    } on TransactionFileGatewayException {
      rethrow;
    } on Object {
      throw const TransactionFileGatewayException(
        'transaction.io',
        'The project transaction lock failed safely.',
      );
    }
    try {
      return await operation();
    } finally {
      try {
        await lock.unlock();
      } on Object {
        // Closing still releases the process lock.
      }
      await lock.close();
    }
  }

  @override
  Future<List<int>?> readResource(String storageKey) {
    _performanceObserver?.incrementCounter(
      AuthoringPerformanceCounterName.filesystemRead,
    );
    return _guardIo(() async {
      final file = await _resourceFile(storageKey, createParents: false);
      final type = await FileSystemEntity.type(file.path, followLinks: false);
      if (type == FileSystemEntityType.notFound) return null;
      if (type != FileSystemEntityType.file) {
        throw const TransactionFileGatewayException(
          'transaction.resource_not_regular',
          'A transaction resource is not a regular file.',
        );
      }
      final beforeStat = await file.stat();
      final bytes = await file.readAsBytes();
      _observeBytes(AuthoringPerformanceCounterName.gatewayResourceReadBytes,
          bytes.length);
      final afterStat = await file.stat();
      if (beforeStat.type != FileSystemEntityType.file ||
          afterStat.type != FileSystemEntityType.file ||
          beforeStat.modified != afterStat.modified ||
          beforeStat.size != afterStat.size) {
        throw const TransactionFileGatewayException(
          'transaction.resource_changed_during_read',
          'A transaction resource changed while it was read.',
        );
      }
      return List<int>.unmodifiable(bytes);
    });
  }

  @override
  Future<String?> readResourceRevision(String storageKey) => _guardIo(() async {
        final file = await _resourceFile(storageKey, createParents: false);
        if (!await file.exists()) return null;
        return (await _inspectFile(file, storageKey)).resourceRevision;
      });

  @override
  Future<AuthoringPayload?> captureResourcePayload(String storageKey) =>
      _guardIo(() async {
        final file = await _resourceFile(storageKey, createParents: false);
        if (!await file.exists()) return null;
        final before = await _inspectFile(file, storageKey);
        return captureAuthoringPayload(
            storageKey: storageKey,
            chunks: _readFile(
                file, AuthoringPerformanceCounterName.gatewayResourceReadBytes),
            byteLength: before.byteLength,
            resourceRevision: before.resourceRevision);
      });

  @override
  Future<void> stagePayload(
          {required String operationId,
          required String storageKey,
          required TransactionPayloadKind kind,
          required List<int>? bytes}) =>
      stageAuthoringPayload(
          operationId: operationId,
          storageKey: storageKey,
          kind: kind,
          payload: bytes == null
              ? null
              : AuthoringPayload.inline(bytes, storageKey: storageKey));

  @override
  Future<void> stageAuthoringPayload(
          {required String operationId,
          required String storageKey,
          required TransactionPayloadKind kind,
          required AuthoringPayload? payload}) =>
      _guardIo(() async {
        if (payload != null && payload.storageKey != storageKey) {
          throw const TransactionFileGatewayException(
              'transaction.stage_conflict',
              'The payload belongs to another resource.');
        }
        final paths = await _payloadPaths(operationId, storageKey, kind,
            createOperation: true);
        if (await paths.descriptor.exists()) {
          final existing = await readStagedPayload(
              operationId: operationId, storageKey: storageKey, kind: kind);
          if (existing.revision != payload?.resourceRevision ||
              existing.payload?.byteLength != payload?.byteLength) {
            throw const TransactionFileGatewayException(
                'transaction.stage_conflict',
                'A different payload is already staged for this transaction.');
          }
          return;
        }
        if (payload == null) {
          await _deleteIfExists(paths.payload);
        } else {
          await _writePayloadAtomic(paths.payload, payload,
              suffix: '${kind.name}.payload');
        }
        await _writeAtomic(
            paths.descriptor,
            utf8.encode(jsonEncode({
              'schemaVersion': 1,
              'storageKey': storageKey,
              'kind': kind.name,
              'present': payload != null,
              'revision': payload?.resourceRevision,
              'byteLength': payload?.byteLength,
            })),
            suffix: '${kind.name}.descriptor',
            counterName: AuthoringPerformanceCounterName
                .gatewayDescriptorCompletedWriteInputBytes);
      });

  @override
  Future<bool> hasStagedArtifacts({
    required String operationId,
    required TransactionPayloadKind kind,
    required Iterable<String> storageKeys,
  }) =>
      _guardIo(() async {
        final directory = await _operationDirectory(operationId, create: false);
        final allowed = <String>{_join(directory.path, 'journal.json')};
        final selected = <String>{};
        for (final storageKey in storageKeys) {
          for (final payloadKind in TransactionPayloadKind.values) {
            final paths = await _payloadPaths(
              operationId,
              storageKey,
              payloadKind,
              createOperation: false,
            );
            final artifacts = {
              paths.descriptor.path,
              paths.payload.path,
              '${paths.descriptor.path}.${payloadKind.name}.descriptor.tmp',
              '${paths.payload.path}.${payloadKind.name}.payload.tmp',
            };
            allowed.addAll(artifacts);
            if (payloadKind == kind) selected.addAll(artifacts);
          }
        }
        var observed = 0;
        await for (final entity in directory.list(followLinks: false)) {
          observed++;
          final name = entity.uri.pathSegments.last;
          if (selected.contains(entity.path) ||
              name.contains('.${kind.name}.')) {
            return true;
          }
          if (observed > allowed.length ||
              !allowed.contains(entity.path) ||
              entity is! File) {
            throw const TransactionFileGatewayException(
              'transaction.artifact_invalid',
              'The transaction contains unexpected preparation artifacts.',
            );
          }
        }
        return false;
      });

  @override
  Future<TransactionStagedPayload> readStagedPayload({
    required String operationId,
    required String storageKey,
    required TransactionPayloadKind kind,
  }) {
    _performanceObserver?.incrementCounter(
      AuthoringPerformanceCounterName.filesystemRead,
    );
    return _guardIo(() async {
      final paths = await _payloadPaths(
        operationId,
        storageKey,
        kind,
        createOperation: false,
      );
      if (!await paths.descriptor.exists()) {
        throw const TransactionFileGatewayException(
          'transaction.stage_missing',
          'A required staged transaction payload is missing.',
        );
      }
      try {
        _performanceObserver?.incrementCounter(
          AuthoringPerformanceCounterName.jsonDecode,
        );
        final decoded = jsonDecode(await paths.descriptor.readAsString());
        if (decoded is! Map) throw const FormatException();
        final descriptor = Map<String, dynamic>.from(decoded);
        const keys = {
          'schemaVersion',
          'storageKey',
          'kind',
          'present',
          'revision',
          'byteLength',
        };
        if (descriptor.keys.any((key) => !keys.contains(key)) ||
            descriptor['schemaVersion'] != 1 ||
            descriptor['storageKey'] != storageKey ||
            descriptor['kind'] != kind.name ||
            descriptor['present'] is! bool) {
          throw const FormatException();
        }
        final present = descriptor['present']! as bool;
        final rawRevision = descriptor['revision'];
        final rawLength = descriptor['byteLength'];
        if ((rawRevision != null && rawRevision is! String) ||
            (rawLength != null && rawLength is! int)) {
          throw const FormatException();
        }
        if ((present && (rawRevision == null || rawLength == null)) ||
            (!present &&
                (rawRevision != null ||
                    rawLength != null ||
                    await paths.payload.exists()))) {
          throw const FormatException();
        }
        AuthoringPayload? source;
        if (present) {
          source = await _readVerifiedStagedFile(paths.payload, storageKey,
              rawLength as int, rawRevision as String);
        }
        final payload = TransactionStagedPayload.withPayload(
            storageKey: storageKey, payload: source);
        return payload;
      } on TransactionFileGatewayException {
        rethrow;
      } on Object {
        throw const TransactionFileGatewayException(
          'transaction.stage_corrupt',
          'A staged transaction payload failed verification.',
        );
      }
    });
  }

  @override
  Future<void> promoteStaged({
    required String operationId,
    required String storageKey,
    required TransactionPayloadKind kind,
    required String? expectedCurrentRevision,
  }) {
    _performanceObserver?.incrementCounter(
      AuthoringPerformanceCounterName.filesystemWrite,
    );
    return _guardIo(() async {
      final currentRevision = await readResourceRevision(storageKey);
      if (currentRevision != expectedCurrentRevision) {
        throw const TransactionFileGatewayException(
          'transaction.revision_conflict',
          'A resource changed immediately before transaction promotion.',
        );
      }
      final staged = await readStagedPayload(
        operationId: operationId,
        storageKey: storageKey,
        kind: kind,
      );
      final target = await _resourceFile(storageKey, createParents: true);
      if (staged.payload == null) {
        await _deleteIfExists(target);
      } else {
        final token = _resourceToken(storageKey);
        final temporary = File('${target.path}.pokemap-$operationId-$token');
        await _deleteIfExists(temporary);
        await _writePayloadAtomic(temporary, staged.payload!,
            suffix: 'promote');
        final temporaryRevision = (await _inspectFile(temporary, storageKey,
                expectedStagedRevision: staged.revision))
            .resourceRevision;
        if (temporaryRevision != staged.revision) {
          await _deleteIfExists(temporary);
          throw const TransactionFileGatewayException(
              'transaction.stage_corrupt',
              'The verified promotion payload changed before replacement.');
        }
        await temporary.rename(target.path);
      }
      final promotedRevision = staged.payload == null
          ? await readResourceRevision(storageKey)
          : (await _inspectFile(target, storageKey,
                  expectedStagedRevision: staged.revision))
              .resourceRevision;
      if (promotedRevision != staged.revision) {
        throw const TransactionFileGatewayException(
          'transaction.promotion_unverified',
          'The promoted resource revision could not be verified.',
        );
      }
    });
  }

  @override
  Future<void> writeJournal(AuthoringTransactionJournal journal) {
    _performanceObserver?.incrementCounter(
      AuthoringPerformanceCounterName.filesystemWrite,
    );
    _performanceObserver?.incrementCounter(
      AuthoringPerformanceCounterName.jsonEncode,
    );
    return _guardIo(() async {
      final directory = await _operationDirectory(
        journal.operationId,
        create: true,
      );
      await _writeAtomic(
        File(_join(directory.path, 'journal.json')),
        utf8.encode(jsonEncode(journal.toJson())),
        suffix: 'journal',
        counterName: AuthoringPerformanceCounterName
            .gatewayJournalCompletedWriteInputBytes,
      );
      _performanceObserver?.incrementCounter(
          AuthoringPerformanceCounterName.journalCompletedWrites);
    });
  }

  @override
  Future<AuthoringTransactionJournal?> readJournal(String operationId) {
    _performanceObserver?.incrementCounter(
      AuthoringPerformanceCounterName.filesystemRead,
    );
    return _guardIo(() async {
      final directory = await _operationDirectory(operationId, create: false);
      final journalFile = File(_join(directory.path, 'journal.json'));
      if (!await journalFile.exists()) return null;
      try {
        _performanceObserver?.incrementCounter(
          AuthoringPerformanceCounterName.jsonDecode,
        );
        final decoded = jsonDecode(await journalFile.readAsString());
        if (decoded is! Map) throw const FormatException();
        final journal = AuthoringTransactionJournal.fromJson(
          Map<String, dynamic>.from(decoded),
        );
        if (journal.operationId != _safeOperationId(operationId)) {
          throw const FormatException();
        }
        return journal;
      } on Object {
        throw const TransactionFileGatewayException(
          'transaction.journal_corrupt',
          'A transaction journal failed strict verification.',
        );
      }
    });
  }

  @override
  Future<List<AuthoringTransactionJournal>> listJournals() {
    _performanceObserver?.incrementCounter(
      AuthoringPerformanceCounterName.filesystemMetadata,
    );
    return _guardIo(() async {
      final root = await _ensureInternalRoot(create: false);
      final journals = <AuthoringTransactionJournal>[];
      if (!await root.exists()) return journals;
      await for (final entity in root.list(followLinks: false)) {
        if (entity is! Directory) continue;
        final operationId =
            entity.uri.pathSegments.where((segment) => segment.isNotEmpty).last;
        if (!_operationPattern.hasMatch(operationId)) continue;
        final journal = await readJournal(operationId);
        if (journal != null) journals.add(journal);
      }
      journals.sort(
        (left, right) => left.operationId.compareTo(right.operationId),
      );
      return List.unmodifiable(journals);
    });
  }

  @override
  Future<void> deleteTransaction(String operationId) {
    _performanceObserver?.incrementCounter(
      AuthoringPerformanceCounterName.filesystemWrite,
    );
    return _guardIo(() async {
      final directory = await _operationDirectory(operationId, create: false);
      final type = await FileSystemEntity.type(
        directory.path,
        followLinks: false,
      );
      if (type == FileSystemEntityType.notFound) return;
      if (type != FileSystemEntityType.directory) {
        throw const TransactionFileGatewayException(
          'transaction.artifact_invalid',
          'Transaction artifacts are not a safe directory.',
        );
      }
      await directory.delete(recursive: true);
    });
  }

  Future<Directory> _ensureInternalRoot(
      {bool scoped = true, bool create = true}) async {
    var current = Directory(_projectRoot);
    for (final segment in [
      '.pokemap',
      'authoring',
      'transactions',
      if (scoped && _transactionNamespace != null) _transactionNamespace
    ]) {
      final next = Directory(_join(current.path, segment));
      final type = await FileSystemEntity.type(next.path, followLinks: false);
      if (type == FileSystemEntityType.notFound) {
        if (create) await next.create();
      } else if (type != FileSystemEntityType.directory) {
        throw const TransactionFileGatewayException(
          'transaction.internal_path_invalid',
          'The internal transaction directory is unsafe.',
        );
      }
      current = next;
    }
    return current;
  }

  Future<Directory> _operationDirectory(
    String operationId, {
    required bool create,
  }) async {
    final safeId = _safeOperationId(operationId);
    final root = await _ensureInternalRoot(create: create);
    final directory = Directory(_join(root.path, safeId));
    final type = await FileSystemEntity.type(
      directory.path,
      followLinks: false,
    );
    if (type == FileSystemEntityType.notFound) {
      if (create) await directory.create();
      return directory;
    }
    if (type != FileSystemEntityType.directory) {
      throw const TransactionFileGatewayException(
        'transaction.artifact_invalid',
        'Transaction artifacts are not a safe directory.',
      );
    }
    return directory;
  }

  Future<File> _resourceFile(
    String storageKey, {
    required bool createParents,
  }) async {
    final segments = validateProjectRelativePath(storageKey);
    if (segments.join('/') != storageKey || segments.first == '.pokemap') {
      throw const TransactionFileGatewayException(
        'transaction.storage_key_invalid',
        'The transaction storage key is invalid.',
      );
    }
    var current = Directory(_projectRoot);
    for (final segment in segments.take(segments.length - 1)) {
      final next = Directory(_join(current.path, segment));
      final type = await FileSystemEntity.type(next.path, followLinks: false);
      if (type == FileSystemEntityType.notFound) {
        if (createParents) await next.create();
      } else if (type != FileSystemEntityType.directory) {
        throw const TransactionFileGatewayException(
          'transaction.storage_parent_invalid',
          'A transaction resource parent is unsafe.',
        );
      }
      current = next;
    }
    final file = File(_join(current.path, segments.last));
    final type = await FileSystemEntity.type(file.path, followLinks: false);
    if (type != FileSystemEntityType.notFound &&
        type != FileSystemEntityType.file) {
      throw const TransactionFileGatewayException(
        'transaction.resource_not_regular',
        'A transaction resource is not a regular file.',
      );
    }
    if (!workspacePathIsWithin(root: _projectRoot, candidate: file.path)) {
      throw const TransactionFileGatewayException(
        'transaction.storage_key_invalid',
        'The transaction resource is outside the project.',
      );
    }
    return file;
  }

  Future<_PayloadPaths> _payloadPaths(
    String operationId,
    String storageKey,
    TransactionPayloadKind kind, {
    required bool createOperation,
  }) async {
    await _resourceFile(storageKey, createParents: false);
    final directory = await _operationDirectory(
      operationId,
      create: createOperation,
    );
    final token = _resourceToken(storageKey);
    return _PayloadPaths(
      descriptor: File(
        _join(directory.path, '$token.${kind.name}.json'),
      ),
      payload: File(
        _join(directory.path, '$token.${kind.name}.bin'),
      ),
    );
  }

  Future<AuthoringPayloadInspection> _inspectFile(File file, String storageKey,
      {String? expectedStagedRevision}) async {
    for (var attempt = 0;; attempt++) {
      final before = await file.stat();
      if (await FileSystemEntity.type(file.path, followLinks: false) !=
              FileSystemEntityType.file ||
          before.type != FileSystemEntityType.file) {
        throw const TransactionFileGatewayException(
            'transaction.resource_not_regular',
            'The resource is not a regular file.');
      }
      final observed = await inspectAuthoringPayload(
          _readFile(file,
              AuthoringPerformanceCounterName.gatewayVerificationReadBytes),
          storageKey: storageKey,
          byteLength: before.size);
      final after = await file.stat();
      if (before.size != after.size ||
          before.modified != after.modified ||
          before.changed != after.changed) {
        if (attempt < 2 &&
            expectedStagedRevision != null &&
            observed.resourceRevision == expectedStagedRevision &&
            before.size == after.size &&
            before.modified == after.modified &&
            before.mode == after.mode &&
            before.type == after.type) {
          continue;
        }
        throw const TransactionFileGatewayException(
            'transaction.resource_changed_during_read',
            'The resource changed during verification.');
      }
      return observed;
    }
  }

  Future<AuthoringPayload> _readVerifiedStagedFile(
    File file,
    String storageKey,
    int byteLength,
    String resourceRevision,
  ) async {
    for (var attempt = 0;; attempt++) {
      final before = await file.stat();
      if (await FileSystemEntity.type(file.path, followLinks: false) !=
              FileSystemEntityType.file ||
          before.type != FileSystemEntityType.file) {
        throw const TransactionFileGatewayException(
            'transaction.resource_not_regular',
            'The resource is not a regular file.');
      }
      AuthoringPayload? source;
      Object? failure;
      StackTrace? stack;
      try {
        source = await AuthoringPayload.verifiedResource(
            storageKey: storageKey,
            byteLength: before.size,
            resourceRevision: resourceRevision,
            openRead: () => _readFile(file,
                AuthoringPerformanceCounterName.gatewayResourceReadBytes));
      } on Object catch (error, trace) {
        failure = error;
        stack = trace;
      }
      final after = await file.stat();
      if (before.size != after.size ||
          before.modified != after.modified ||
          before.changed != after.changed) {
        final matches = source?.resourceRevision == resourceRevision;
        await source?.release();
        if (attempt < 2 &&
            matches &&
            before.size == after.size &&
            before.modified == after.modified &&
            before.mode == after.mode &&
            before.type == after.type) {
          continue;
        }
        throw const TransactionFileGatewayException(
            'transaction.resource_changed_during_read',
            'The resource changed during verification.');
      }
      if (failure != null) Error.throwWithStackTrace(failure, stack!);
      final verified = source!;
      if (verified.byteLength != byteLength) {
        await verified.release();
        throw const TransactionFileGatewayException(
            'transaction.stage_corrupt',
            'The staged payload length differs from its descriptor.');
      }
      return verified;
    }
  }

  Future<void> _writePayloadAtomic(File target, AuthoringPayload payload,
      {required String suffix}) async {
    final temporary = File('${target.path}.$suffix.tmp');
    await _deleteIfExists(temporary);
    try {
      final writer = await temporary.open(mode: FileMode.write);
      try {
        await for (final chunk in payload.openRead()) {
          await writer.writeFrom(chunk);
          _observeBytes(
              AuthoringPerformanceCounterName
                  .gatewayStagedPayloadCompletedWriteInputBytes,
              chunk.length);
        }
        await writer.flush();
      } finally {
        await writer.close();
      }
      if ((await _inspectFile(temporary, payload.storageKey,
                  expectedStagedRevision: payload.resourceRevision))
              .resourceRevision !=
          payload.resourceRevision) {
        throw const TransactionFileGatewayException('transaction.stage_corrupt',
            'The staged payload failed content verification.');
      }
      await temporary.rename(target.path);
    } finally {
      await _deleteIfExists(temporary);
    }
  }

  Future<void> _writeAtomic(
    File target,
    List<int> bytes, {
    required String suffix,
    required String counterName,
  }) async {
    final temporary = File('${target.path}.$suffix.tmp');
    await _deleteIfExists(temporary);
    final writer = await temporary.open(mode: FileMode.write);
    try {
      await writer.writeFrom(bytes);
      _observeBytes(counterName, bytes.length);
      await writer.flush();
    } finally {
      await writer.close();
    }
    await temporary.rename(target.path);
  }

  void _observeBytes(String name, int length) {
    if (length > 0) _performanceObserver?.incrementCounter(name, by: length);
  }

  Stream<List<int>> _readFile(File file, String counterName) =>
      file.openRead().map((chunk) {
        _observeBytes(counterName, chunk.length);
        return chunk;
      });

  Future<void> _requireExpectedProjectRoot() async {
    final expected = _expectedProjectRoot;
    if (expected == null) return;
    if (await FileSystemEntity.type(expected, followLinks: false) !=
            FileSystemEntityType.directory ||
        await Directory(expected).resolveSymbolicLinks() != expected) {
      throw const TransactionFileGatewayException(
          'transaction.project_root_changed',
          'The reserved native project root changed.');
    }
  }

  Future<T> _guardIo<T>(Future<T> Function() operation) async {
    try {
      await _requireExpectedProjectRoot();
      return await operation();
    } on TransactionFileGatewayException {
      rethrow;
    } on AuthoringPayloadPreparationAborted {
      rethrow;
    } on WorkspaceAccessException {
      throw const TransactionFileGatewayException(
        'transaction.storage_key_invalid',
        'The transaction storage key is invalid.',
      );
    } on Object {
      throw const TransactionFileGatewayException(
        'transaction.io',
        'The transaction filesystem operation failed safely.',
      );
    }
  }
}

final RegExp _operationPattern = RegExp(r'^[a-zA-Z0-9][a-zA-Z0-9_.-]*$');

String _safeOperationId(String value) {
  if (value.length > 120 ||
      value.trim() != value ||
      !_operationPattern.hasMatch(value)) {
    throw const TransactionFileGatewayException(
      'transaction.operation_id_invalid',
      'The transaction operation identity is invalid.',
    );
  }
  return value;
}

String _resourceToken(String storageKey) {
  final fingerprint = computeAuthoringJsonFingerprint(
    storageKey,
    logicalName: 'transaction-storage-key.json',
  );
  return fingerprint.substring('sha256:'.length);
}

String _join(String first, String second) =>
    '$first${Platform.pathSeparator}$second';

Future<void> _deleteIfExists(File file) async {
  if (await file.exists()) await file.delete();
}

final class _PayloadPaths {
  const _PayloadPaths({required this.descriptor, required this.payload});
  final File descriptor;
  final File payload;
}

final _projectWriters = <String, Future<void>>{};

Future<T> withLocalProjectWriteQueue<T>(
    String canonicalProjectRoot, Future<T> Function() operation) async {
  final previous =
      _projectWriters[canonicalProjectRoot] ?? Future<void>.value();
  final release = Completer<void>();
  _projectWriters[canonicalProjectRoot] = release.future;
  await previous;
  try {
    return await operation();
  } finally {
    release.complete();
    if (identical(_projectWriters[canonicalProjectRoot], release.future)) {
      _projectWriters.remove(canonicalProjectRoot);
    }
  }
}
