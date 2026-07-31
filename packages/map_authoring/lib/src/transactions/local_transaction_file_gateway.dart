import 'dart:convert';
import 'dart:io';

import '../ports/project_file_reader.dart';
import '../ports/transaction_file_gateway.dart';
import '../support/authoring_fingerprint.dart';
import 'transaction_journal.dart';

/// Project-local filesystem adapter with atomic-per-file replacement.
///
/// Multi-file atomicity is deliberately not claimed. The journal and retained
/// staged payloads make the ordered sequence recoverable after any completed
/// filesystem call.
final class LocalTransactionFileGateway implements TransactionFileGateway {
  LocalTransactionFileGateway._(this._projectRoot);

  static Future<LocalTransactionFileGateway> open({
    required String projectRoot,
  }) async {
    try {
      final directory = Directory(projectRoot);
      if ((await directory.stat()).type != FileSystemEntityType.directory) {
        throw const TransactionFileGatewayException(
          'transaction.project_directory_required',
          'The transaction project root is not a directory.',
        );
      }
      return LocalTransactionFileGateway._(
        await directory.resolveSymbolicLinks(),
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

  @override
  Future<T> withExclusiveWriteLock<T>(Future<T> Function() operation) async {
    late final RandomAccessFile lock;
    try {
      final internalRoot = await _ensureInternalRoot();
      lock = await File(_join(internalRoot.path, 'write.lock')).open(
        mode: FileMode.append,
      );
      await lock.lock(FileLock.exclusive);
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
  Future<String?> readResourceRevision(String storageKey) async {
    final bytes = await readResource(storageKey);
    return bytes == null
        ? null
        : computeAuthoringBytesFingerprint(
            bytes,
            logicalName: storageKey,
          );
  }

  @override
  Future<void> stagePayload({
    required String operationId,
    required String storageKey,
    required TransactionPayloadKind kind,
    required List<int>? bytes,
  }) {
    return _guardIo(() async {
      final payload = TransactionStagedPayload(
        storageKey: storageKey,
        bytes: bytes,
      );
      final paths = await _payloadPaths(
        operationId,
        storageKey,
        kind,
        createOperation: true,
      );
      if (await paths.descriptor.exists()) {
        final existing = await readStagedPayload(
          operationId: operationId,
          storageKey: storageKey,
          kind: kind,
        );
        if (existing.revision != payload.revision ||
            !_optionalBytesEqual(existing.bytes, payload.bytes)) {
          throw const TransactionFileGatewayException(
            'transaction.stage_conflict',
            'A different payload is already staged for this transaction.',
          );
        }
        return;
      }

      if (payload.bytes == null) {
        await _deleteIfExists(paths.payload);
      } else {
        await _writeAtomic(
          paths.payload,
          payload.bytes!,
          suffix: '${kind.name}.payload',
        );
      }
      final descriptor = utf8.encode(jsonEncode({
        'schemaVersion': 1,
        'storageKey': storageKey,
        'kind': kind.name,
        'present': payload.bytes != null,
        'revision': payload.revision,
        'byteLength': payload.bytes?.length,
      }));
      // The descriptor is the durable "stage complete" marker and is always
      // promoted after the optional payload has been flushed.
      await _writeAtomic(
        paths.descriptor,
        descriptor,
        suffix: '${kind.name}.descriptor',
      );
    });
  }

  @override
  Future<TransactionStagedPayload> readStagedPayload({
    required String operationId,
    required String storageKey,
    required TransactionPayloadKind kind,
  }) {
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
        final bytes = present ? await paths.payload.readAsBytes() : null;
        final payload = TransactionStagedPayload(
          storageKey: storageKey,
          bytes: bytes,
        );
        if (payload.revision != rawRevision ||
            payload.bytes?.length != rawLength ||
            (!present && await paths.payload.exists())) {
          throw const FormatException();
        }
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
      if (staged.bytes == null) {
        await _deleteIfExists(target);
      } else {
        final token = _resourceToken(storageKey);
        final temporary = File('${target.path}.pokemap-$operationId-$token');
        await _deleteIfExists(temporary);
        final writer = await temporary.open(mode: FileMode.write);
        try {
          await writer.writeFrom(staged.bytes!);
          await writer.flush();
        } finally {
          await writer.close();
        }
        final temporaryRevision = computeAuthoringBytesFingerprint(
          await temporary.readAsBytes(),
          logicalName: storageKey,
        );
        if (temporaryRevision != staged.revision) {
          await _deleteIfExists(temporary);
          throw const TransactionFileGatewayException(
            'transaction.stage_corrupt',
            'The verified promotion payload changed before replacement.',
          );
        }
        await temporary.rename(target.path);
      }
      if (await readResourceRevision(storageKey) != staged.revision) {
        throw const TransactionFileGatewayException(
          'transaction.promotion_unverified',
          'The promoted resource revision could not be verified.',
        );
      }
    });
  }

  @override
  Future<void> writeJournal(AuthoringTransactionJournal journal) {
    return _guardIo(() async {
      final directory = await _operationDirectory(
        journal.operationId,
        create: true,
      );
      await _writeAtomic(
        File(_join(directory.path, 'journal.json')),
        utf8.encode(jsonEncode(journal.toJson())),
        suffix: 'journal',
      );
    });
  }

  @override
  Future<AuthoringTransactionJournal?> readJournal(String operationId) {
    return _guardIo(() async {
      final directory = await _operationDirectory(operationId, create: false);
      final journalFile = File(_join(directory.path, 'journal.json'));
      if (!await journalFile.exists()) return null;
      try {
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
    return _guardIo(() async {
      final root = await _ensureInternalRoot();
      final journals = <AuthoringTransactionJournal>[];
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

  Future<Directory> _ensureInternalRoot() async {
    var current = Directory(_projectRoot);
    for (final segment in const ['.pokemap', 'authoring', 'transactions']) {
      final next = Directory(_join(current.path, segment));
      final type = await FileSystemEntity.type(next.path, followLinks: false);
      if (type == FileSystemEntityType.notFound) {
        await next.create();
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
    final root = await _ensureInternalRoot();
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

  Future<void> _writeAtomic(
    File target,
    List<int> bytes, {
    required String suffix,
  }) async {
    final temporary = File('${target.path}.$suffix.tmp');
    await _deleteIfExists(temporary);
    final writer = await temporary.open(mode: FileMode.write);
    try {
      await writer.writeFrom(bytes);
      await writer.flush();
    } finally {
      await writer.close();
    }
    await temporary.rename(target.path);
  }

  Future<T> _guardIo<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } on TransactionFileGatewayException {
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

bool _optionalBytesEqual(List<int>? left, List<int>? right) {
  if (left == null || right == null) return left == null && right == null;
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}

final class _PayloadPaths {
  const _PayloadPaths({required this.descriptor, required this.payload});

  final File descriptor;
  final File payload;
}
