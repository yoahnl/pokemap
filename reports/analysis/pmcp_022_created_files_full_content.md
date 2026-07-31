# PMCP-022 — Created Files Full Content

This appendix reproduces every file created by PMCP-022 exactly as it stood immediately before the lot commit. The Evidence Pack and this appendix are reporting artifacts and are intentionally not self-reproduced.

## `packages/map_authoring/lib/src/ports/transaction_file_gateway.dart`

~~~~~~~~dart
import '../support/authoring_fingerprint.dart';
import '../transactions/transaction_journal.dart';

enum TransactionPayloadKind { before, after }

final class TransactionFileGatewayException implements Exception {
  const TransactionFileGatewayException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => 'TransactionFileGatewayException($code): $message';
}

final class TransactionStagedPayload {
  TransactionStagedPayload({
    required this.storageKey,
    required Iterable<int>? bytes,
  }) : bytes = bytes == null
            ? null
            : List<int>.unmodifiable(bytes.toList(growable: false)) {
    if (this.bytes?.any((value) => value < 0 || value > 255) ?? false) {
      throw ArgumentError.value(bytes, 'bytes', 'must contain bytes');
    }
    revision = this.bytes == null
        ? null
        : computeAuthoringBytesFingerprint(
            this.bytes!,
            logicalName: storageKey,
          );
  }

  final String storageKey;
  final List<int>? bytes;
  late final String? revision;
}

/// Project-local storage capabilities required by the write state machine.
abstract interface class TransactionFileGateway {
  Future<T> withExclusiveWriteLock<T>(Future<T> Function() operation);

  Future<List<int>?> readResource(String storageKey);

  Future<String?> readResourceRevision(String storageKey);

  Future<void> stagePayload({
    required String operationId,
    required String storageKey,
    required TransactionPayloadKind kind,
    required List<int>? bytes,
  });

  Future<TransactionStagedPayload> readStagedPayload({
    required String operationId,
    required String storageKey,
    required TransactionPayloadKind kind,
  });

  Future<void> promoteStaged({
    required String operationId,
    required String storageKey,
    required TransactionPayloadKind kind,
    required String? expectedCurrentRevision,
  });

  Future<void> writeJournal(AuthoringTransactionJournal journal);

  Future<AuthoringTransactionJournal?> readJournal(String operationId);

  Future<List<AuthoringTransactionJournal>> listJournals();

  Future<void> deleteTransaction(String operationId);
}
~~~~~~~~
## `packages/map_authoring/lib/src/transactions/transaction_journal.dart`

~~~~~~~~dart
import '../contracts/authoring_receipt.dart';
import '../contracts/resource_ref.dart';
import '../ports/idempotency_store.dart';
import '../ports/project_file_reader.dart';
import '../support/authoring_fingerprint.dart';
import 'revision_set.dart';

enum AuthoringTransactionStatus {
  preparing,
  staged,
  prepared,
  promoting,
  committed,
  compensating,
  compensated,
}

final class AuthoringTransactionJournalEntry {
  AuthoringTransactionJournalEntry({
    required this.resource,
    required String storageKey,
    required String? beforeRevision,
    required String? afterRevision,
    this.promoted = false,
    this.compensated = false,
  })  : storageKey = _storageKey(storageKey),
        beforeRevision = _optionalRevision(beforeRevision, 'beforeRevision'),
        afterRevision = _optionalRevision(afterRevision, 'afterRevision') {
    if (beforeRevision == null && afterRevision == null) {
      throw ArgumentError(
        'A transaction journal entry requires a before or after revision.',
      );
    }
  }

  factory AuthoringTransactionJournalEntry.fromJson(
    Map<String, dynamic> json,
  ) {
    const keys = {
      'resource',
      'storageKey',
      'beforeRevision',
      'afterRevision',
      'promoted',
      'compensated',
    };
    if (json.keys.any((key) => !keys.contains(key))) {
      throw const FormatException('Unknown transaction journal entry field.');
    }
    final rawResource = json['resource'];
    if (rawResource is! Map ||
        !json.containsKey('beforeRevision') ||
        !json.containsKey('afterRevision')) {
      throw const FormatException('Invalid transaction journal entry.');
    }
    final beforeRevision = json['beforeRevision'];
    final afterRevision = json['afterRevision'];
    if ((beforeRevision != null && beforeRevision is! String) ||
        (afterRevision != null && afterRevision is! String)) {
      throw const FormatException('Journal revisions must be strings or null.');
    }
    try {
      return AuthoringTransactionJournalEntry(
        resource: AuthoringResourceRef.fromJson(
          Map<String, dynamic>.from(rawResource),
        ),
        storageKey: _requiredString(json['storageKey'], 'storageKey'),
        beforeRevision: beforeRevision as String?,
        afterRevision: afterRevision as String?,
        promoted: _requiredBool(json['promoted'], 'promoted'),
        compensated: _requiredBool(json['compensated'], 'compensated'),
      );
    } on ArgumentError catch (error) {
      throw FormatException(error.message.toString());
    }
  }

  final AuthoringResourceRef resource;
  final String storageKey;
  final String? beforeRevision;
  final String? afterRevision;
  final bool promoted;
  final bool compensated;

  AuthoringTransactionJournalEntry copyWith({
    bool? promoted,
    bool? compensated,
  }) {
    return AuthoringTransactionJournalEntry(
      resource: resource,
      storageKey: storageKey,
      beforeRevision: beforeRevision,
      afterRevision: afterRevision,
      promoted: promoted ?? this.promoted,
      compensated: compensated ?? this.compensated,
    );
  }

  Map<String, Object?> toJson() => {
        'resource': resource.toJson(),
        'storageKey': storageKey,
        'beforeRevision': beforeRevision,
        'afterRevision': afterRevision,
        'promoted': promoted,
        'compensated': compensated,
      };
}

/// Durable intent and checkpoint record for one recoverable transaction.
final class AuthoringTransactionJournal {
  AuthoringTransactionJournal({
    required String operationId,
    required String planId,
    required this.scope,
    required this.status,
    required DateTime createdAt,
    required DateTime updatedAt,
    required Iterable<AuthoringTransactionJournalEntry> entries,
    required this.intendedReceipt,
    this.finalReceipt,
  })  : operationId = _safeIdentity(operationId, 'operationId'),
        planId = _safeIdentity(planId, 'planId'),
        createdAt = createdAt.toUtc(),
        updatedAt = updatedAt.toUtc(),
        entries = _sortedEntries(entries) {
    if (this.entries.isEmpty) {
      throw ArgumentError.value(entries, 'entries', 'must not be empty');
    }
    final resources = <String>{};
    final storageKeys = <String>{};
    for (final entry in this.entries) {
      if (!resources.add('${entry.resource.kind}\u0000${entry.resource.id}') ||
          !storageKeys.add(entry.storageKey)) {
        throw ArgumentError(
          'Transaction journal resources and storage keys must be unique.',
        );
      }
    }
    if (this.updatedAt.isBefore(this.createdAt)) {
      throw ArgumentError.value(
        updatedAt,
        'updatedAt',
        'must not precede createdAt',
      );
    }
    final isFinal = status == AuthoringTransactionStatus.committed ||
        status == AuthoringTransactionStatus.compensated;
    if (isFinal != (finalReceipt != null)) {
      throw ArgumentError(
        'Committed or compensated journals require exactly one final receipt.',
      );
    }
    _requireReceiptMatchesScope(intendedReceipt, scope);
    if (intendedReceipt.status != AuthoringReceiptStatus.applied) {
      throw ArgumentError(
        'The intended transaction receipt must have applied status.',
      );
    }
    final receiptResources = {
      for (final resource in intendedReceipt.affectedResources)
        '${resource.kind}\u0000${resource.id}',
    };
    if (receiptResources.length != resources.length ||
        !receiptResources.containsAll(resources)) {
      throw ArgumentError(
        'Journal entries must match the intended receipt resource set.',
      );
    }
    final beforeSet = AuthoringRevisionSet([
      for (final entry in this.entries)
        AuthoringResourceRevision(
          resource: entry.resource,
          revision: entry.beforeRevision,
        ),
    ]);
    final afterSet = AuthoringRevisionSet([
      for (final entry in this.entries)
        AuthoringResourceRevision(
          resource: entry.resource,
          revision: entry.afterRevision,
        ),
    ]);
    if (intendedReceipt.beforeRevision != beforeSet.fingerprint ||
        intendedReceipt.afterRevision != afterSet.fingerprint) {
      throw ArgumentError(
        'Intended receipt revisions must match journal resource revisions.',
      );
    }
    if (finalReceipt != null) {
      _requireReceiptMatchesScope(finalReceipt!, scope);
      if (finalReceipt!.receiptId != intendedReceipt.receiptId) {
        throw ArgumentError(
          'The final receipt must retain the intended receipt identity.',
        );
      }
      if (canonicalAuthoringJson(finalReceipt!.diff.toJson()) !=
          canonicalAuthoringJson(intendedReceipt.diff.toJson())) {
        throw ArgumentError(
          'The final receipt must retain the intended structured diff.',
        );
      }
      final expectedFinalRevision =
          status == AuthoringTransactionStatus.compensated
              ? beforeSet.fingerprint
              : afterSet.fingerprint;
      if (finalReceipt!.afterRevision != expectedFinalRevision) {
        throw ArgumentError(
          'The final receipt revision must match the final journal state.',
        );
      }
    }
  }

  factory AuthoringTransactionJournal.fromJson(Map<String, dynamic> json) {
    const keys = {
      'schemaVersion',
      'operationId',
      'planId',
      'scope',
      'status',
      'createdAtUtc',
      'updatedAtUtc',
      'entries',
      'intendedReceipt',
      'finalReceipt',
    };
    if (json.keys.any((key) => !keys.contains(key)) ||
        json['schemaVersion'] != 1) {
      throw const FormatException('Invalid transaction journal schema.');
    }
    final rawScope = json['scope'];
    final rawEntries = json['entries'];
    final rawIntended = json['intendedReceipt'];
    final rawFinal = json['finalReceipt'];
    if (rawScope is! Map ||
        rawEntries is! List ||
        rawIntended is! Map ||
        (rawFinal != null && rawFinal is! Map)) {
      throw const FormatException('Invalid transaction journal objects.');
    }
    final rawStatus = json['status'];
    if (rawStatus is! String) {
      throw const FormatException('Transaction status must be a string.');
    }
    final status = AuthoringTransactionStatus.values.firstWhere(
      (candidate) => candidate.name == rawStatus,
      orElse: () => throw const FormatException('Unknown transaction status.'),
    );
    try {
      return AuthoringTransactionJournal(
        operationId: _requiredString(json['operationId'], 'operationId'),
        planId: _requiredString(json['planId'], 'planId'),
        scope: AuthoringIdempotencyScope.fromJson(
          Map<String, dynamic>.from(rawScope),
        ),
        status: status,
        createdAt: _utcDate(json['createdAtUtc'], 'createdAtUtc'),
        updatedAt: _utcDate(json['updatedAtUtc'], 'updatedAtUtc'),
        entries: rawEntries.map((rawEntry) {
          if (rawEntry is! Map) {
            throw const FormatException('Journal entry must be an object.');
          }
          return AuthoringTransactionJournalEntry.fromJson(
            Map<String, dynamic>.from(rawEntry),
          );
        }),
        intendedReceipt: AuthoringReceipt.fromJson(
          Map<String, dynamic>.from(rawIntended),
        ),
        finalReceipt: rawFinal == null
            ? null
            : AuthoringReceipt.fromJson(
                Map<String, dynamic>.from(rawFinal),
              ),
      );
    } on ArgumentError catch (error) {
      throw FormatException(error.message.toString());
    }
  }

  final String operationId;
  final String planId;
  final AuthoringIdempotencyScope scope;
  final AuthoringTransactionStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<AuthoringTransactionJournalEntry> entries;
  final AuthoringReceipt intendedReceipt;
  final AuthoringReceipt? finalReceipt;

  AuthoringTransactionJournal copyWith({
    AuthoringTransactionStatus? status,
    DateTime? updatedAt,
    Iterable<AuthoringTransactionJournalEntry>? entries,
    Object? finalReceipt = _unchangedReceipt,
  }) {
    return AuthoringTransactionJournal(
      operationId: operationId,
      planId: planId,
      scope: scope,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      entries: entries ?? this.entries,
      intendedReceipt: intendedReceipt,
      finalReceipt: identical(finalReceipt, _unchangedReceipt)
          ? this.finalReceipt
          : finalReceipt as AuthoringReceipt?,
    );
  }

  Map<String, Object?> toJson() => {
        'schemaVersion': 1,
        'operationId': operationId,
        'planId': planId,
        'scope': scope.toJson(),
        'status': status.name,
        'createdAtUtc': createdAt.toIso8601String(),
        'updatedAtUtc': updatedAt.toIso8601String(),
        'entries': [for (final entry in entries) entry.toJson()],
        'intendedReceipt': intendedReceipt.toJson(),
        if (finalReceipt != null) 'finalReceipt': finalReceipt!.toJson(),
      };
}

const Object _unchangedReceipt = Object();

List<AuthoringTransactionJournalEntry> _sortedEntries(
  Iterable<AuthoringTransactionJournalEntry> entries,
) {
  final sorted = entries.toList()
    ..sort((left, right) {
      final storageOrder = left.storageKey.compareTo(right.storageKey);
      if (storageOrder != 0) return storageOrder;
      final kindOrder = left.resource.kind.compareTo(right.resource.kind);
      return kindOrder != 0
          ? kindOrder
          : left.resource.id.compareTo(right.resource.id);
    });
  return List.unmodifiable(sorted);
}

void _requireReceiptMatchesScope(
  AuthoringReceipt receipt,
  AuthoringIdempotencyScope scope,
) {
  if (receipt.actionId != scope.actionId ||
      receipt.actionVersion != scope.actionVersion) {
    throw ArgumentError(
      'Transaction receipt action must match the idempotency scope.',
    );
  }
}

String _storageKey(String value) {
  final segments = validateProjectRelativePath(value);
  if (segments.join('/') != value || segments.first == '.pokemap') {
    throw ArgumentError.value(
      value,
      'storageKey',
      'must be a normalized project-relative resource key',
    );
  }
  return value;
}

String? _optionalRevision(String? value, String field) {
  if (value != null && !RegExp(r'^sha256:[0-9a-f]{64}$').hasMatch(value)) {
    throw ArgumentError.value(value, field, 'must be a SHA-256 fingerprint');
  }
  return value;
}

String _safeIdentity(String value, String field) {
  final normalized = value.trim();
  if (normalized != value ||
      !RegExp(r'^[a-zA-Z0-9][a-zA-Z0-9_.:-]*$').hasMatch(normalized)) {
    throw ArgumentError.value(value, field, 'must be a safe opaque identity');
  }
  return normalized;
}

String _requiredString(Object? value, String field) {
  if (value is! String) throw FormatException('$field must be a string.');
  return value;
}

bool _requiredBool(Object? value, String field) {
  if (value is! bool) throw FormatException('$field must be a boolean.');
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
~~~~~~~~

## `packages/map_authoring/lib/src/transactions/local_transaction_file_gateway.dart`

~~~~~~~~dart
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
~~~~~~~~

## `packages/map_authoring/lib/src/transactions/journaled_transaction.dart`

~~~~~~~~dart
import 'dart:async';

import '../contracts/authoring_receipt.dart';
import '../contracts/authoring_request.dart';
import '../ports/idempotency_store.dart';
import '../ports/transaction_file_gateway.dart';
import '../support/authoring_fingerprint.dart';
import 'authoring_plan.dart';
import 'idempotency_ledger.dart';
import 'plan_store.dart';
import 'revision_set.dart';
import 'transaction_journal.dart';

enum AuthoringTransactionCheckpoint {
  afterJournalPreparing,
  afterPayloadsStaged,
  afterJournalStaged,
  afterReservation,
  afterJournalPrepared,
  beforeResourcePromotion,
  afterResourcePromoted,
  afterResourceJournaled,
  afterJournalCommitted,
}

final class AuthoringTransactionCheckpointContext {
  const AuthoringTransactionCheckpointContext({
    required this.checkpoint,
    required this.operationId,
    this.storageKey,
    this.promotionIndex,
  });

  final AuthoringTransactionCheckpoint checkpoint;
  final String operationId;
  final String? storageKey;
  final int? promotionIndex;
}

typedef AuthoringTransactionFaultInjector = FutureOr<void> Function(
  AuthoringTransactionCheckpointContext context,
);

final class AuthoringTransactionSimulatedCrash implements Exception {
  const AuthoringTransactionSimulatedCrash();
}

final class JournaledAuthoringTransactionException implements Exception {
  const JournaledAuthoringTransactionException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() =>
      'JournaledAuthoringTransactionException($code): $message';
}

/// Applies a plan through a durable, recoverable multi-file state machine.
final class JournaledAuthoringTransaction {
  const JournaledAuthoringTransaction({
    required AuthoringPlanStore plans,
    required TransactionFileGateway gateway,
    required AuthoringIdempotencyLedger idempotency,
    required DateTime Function() clock,
    AuthoringTransactionFaultInjector? faultInjector,
  })  : _plans = plans,
        _gateway = gateway,
        _idempotency = idempotency,
        _clock = clock,
        _faultInjector = faultInjector;

  final AuthoringPlanStore _plans;
  final TransactionFileGateway _gateway;
  final AuthoringIdempotencyLedger _idempotency;
  final DateTime Function() _clock;
  final AuthoringTransactionFaultInjector? _faultInjector;

  Future<AuthoringReceipt> apply({
    required String planId,
    required AuthoringRequest request,
    required String currentProjectRevision,
    required AuthoringIdempotencyScope scope,
    required String operationId,
  }) {
    return _gateway.withExclusiveWriteLock(() async {
      final replay = await _idempotency.inspect(
        scope: scope,
        request: request,
      );
      if (replay != null) return replay;

      final plan = _plans.resolve(
        planId,
        currentProjectRevision: currentProjectRevision,
      );
      _requireRequestMatchesPlan(request, plan);
      final expected = AuthoringRevisionSet.beforeChangeSet(plan.changeSet);
      final current = await _currentRevisions(plan);
      expected.requireMatches(current);

      final existingJournal = await _gateway.readJournal(operationId);
      if (existingJournal != null) {
        final safelyRestartable = existingJournal.planId == plan.planId &&
            existingJournal.scope.storageKey == scope.storageKey &&
            (existingJournal.status == AuthoringTransactionStatus.preparing ||
                existingJournal.status == AuthoringTransactionStatus.staged);
        if (!safelyRestartable) {
          throw const JournaledAuthoringTransactionException(
            'transaction.operation_conflict',
            'This operation identity already owns another durable intent.',
          );
        }
        await _gateway.deleteTransaction(operationId);
      }

      final now = _clock().toUtc();
      final afterRevisions =
          AuthoringRevisionSet.afterChangeSet(plan.changeSet);
      final intendedReceipt = AuthoringReceipt(
        receiptId: plan.receiptId,
        requestId: request.requestId,
        actionId: request.actionId,
        actionVersion: request.actionVersion,
        status: AuthoringReceiptStatus.applied,
        beforeRevision: expected.fingerprint,
        afterRevision: afterRevisions.fingerprint,
        createdAtUtc: now.toIso8601String(),
        diff: plan.changeSet.diff,
        artifacts: plan.artifacts,
        extensions: {
          'planId': plan.planId,
          'operationId': operationId,
          'multiFileGuarantee': 'recoverable',
        },
      );
      var journal = AuthoringTransactionJournal(
        operationId: operationId,
        planId: plan.planId,
        scope: scope,
        status: AuthoringTransactionStatus.preparing,
        createdAt: now,
        updatedAt: now,
        entries: [
          for (final change in plan.changeSet.changes)
            AuthoringTransactionJournalEntry(
              resource: change.resource,
              storageKey: change.storageKey,
              beforeRevision: change.beforeRevision,
              afterRevision: change.afterRevision,
            ),
        ],
        intendedReceipt: intendedReceipt,
      );

      // The journal exists before idempotency reservation. A process stop can
      // therefore leave either a harmless unreserved intent or a recoverable
      // pending reservation, never a pending key with no transaction identity.
      await _gateway.writeJournal(journal);
      await _checkpoint(
        AuthoringTransactionCheckpoint.afterJournalPreparing,
        operationId,
      );

      for (final change in plan.changeSet.changes) {
        await _gateway.stagePayload(
          operationId: operationId,
          storageKey: change.storageKey,
          kind: TransactionPayloadKind.before,
          bytes: change.beforeBytes,
        );
        await _gateway.stagePayload(
          operationId: operationId,
          storageKey: change.storageKey,
          kind: TransactionPayloadKind.after,
          bytes: change.afterBytes,
        );
        await _requireStagedRevision(
          operationId: operationId,
          storageKey: change.storageKey,
          kind: TransactionPayloadKind.before,
          expectedRevision: change.beforeRevision,
        );
        await _requireStagedRevision(
          operationId: operationId,
          storageKey: change.storageKey,
          kind: TransactionPayloadKind.after,
          expectedRevision: change.afterRevision,
        );
      }
      await _checkpoint(
        AuthoringTransactionCheckpoint.afterPayloadsStaged,
        operationId,
      );
      journal = journal.copyWith(
        status: AuthoringTransactionStatus.staged,
        updatedAt: _clock().toUtc(),
      );
      await _gateway.writeJournal(journal);
      await _checkpoint(
        AuthoringTransactionCheckpoint.afterJournalStaged,
        operationId,
      );

      return _idempotency.execute(
        scope: scope,
        request: request,
        operationId: operationId,
        apply: () async {
          await _checkpoint(
            AuthoringTransactionCheckpoint.afterReservation,
            operationId,
          );
          journal = journal.copyWith(
            status: AuthoringTransactionStatus.prepared,
            updatedAt: _clock().toUtc(),
          );
          await _gateway.writeJournal(journal);
          await _checkpoint(
            AuthoringTransactionCheckpoint.afterJournalPrepared,
            operationId,
          );

          journal = journal.copyWith(
            status: AuthoringTransactionStatus.promoting,
            updatedAt: _clock().toUtc(),
          );
          await _gateway.writeJournal(journal);
          for (var index = 0; index < journal.entries.length; index++) {
            final entry = journal.entries[index];
            await _checkpoint(
              AuthoringTransactionCheckpoint.beforeResourcePromotion,
              operationId,
              storageKey: entry.storageKey,
              promotionIndex: index,
            );
            await _gateway.promoteStaged(
              operationId: operationId,
              storageKey: entry.storageKey,
              kind: TransactionPayloadKind.after,
              expectedCurrentRevision: entry.beforeRevision,
            );
            await _checkpoint(
              AuthoringTransactionCheckpoint.afterResourcePromoted,
              operationId,
              storageKey: entry.storageKey,
              promotionIndex: index,
            );
            journal = journal.copyWith(
              updatedAt: _clock().toUtc(),
              entries: _replaceEntry(
                journal.entries,
                index,
                entry.copyWith(promoted: true),
              ),
            );
            await _gateway.writeJournal(journal);
            await _checkpoint(
              AuthoringTransactionCheckpoint.afterResourceJournaled,
              operationId,
              storageKey: entry.storageKey,
              promotionIndex: index,
            );
          }

          journal = journal.copyWith(
            status: AuthoringTransactionStatus.committed,
            updatedAt: _clock().toUtc(),
            finalReceipt: intendedReceipt,
          );
          await _gateway.writeJournal(journal);
          await _checkpoint(
            AuthoringTransactionCheckpoint.afterJournalCommitted,
            operationId,
          );
          return intendedReceipt;
        },
      );
    });
  }

  Future<AuthoringRevisionSet> _currentRevisions(
    AuthoringPlan plan,
  ) async {
    return AuthoringRevisionSet([
      for (final change in plan.changeSet.changes)
        AuthoringResourceRevision(
          resource: change.resource,
          revision: await _gateway.readResourceRevision(change.storageKey),
        ),
    ]);
  }

  Future<void> _requireStagedRevision({
    required String operationId,
    required String storageKey,
    required TransactionPayloadKind kind,
    required String? expectedRevision,
  }) async {
    final staged = await _gateway.readStagedPayload(
      operationId: operationId,
      storageKey: storageKey,
      kind: kind,
    );
    if (staged.revision != expectedRevision) {
      throw const TransactionFileGatewayException(
        'transaction.stage_corrupt',
        'A staged transaction revision differs from the frozen plan.',
      );
    }
  }

  Future<void> _checkpoint(
    AuthoringTransactionCheckpoint checkpoint,
    String operationId, {
    String? storageKey,
    int? promotionIndex,
  }) async {
    final injector = _faultInjector;
    if (injector == null) return;
    await injector(
      AuthoringTransactionCheckpointContext(
        checkpoint: checkpoint,
        operationId: operationId,
        storageKey: storageKey,
        promotionIndex: promotionIndex,
      ),
    );
  }
}

void _requireRequestMatchesPlan(
  AuthoringRequest request,
  AuthoringPlan plan,
) {
  final planned = plan.request;
  final sameSemantics = request.actionId == planned.actionId &&
      request.actionVersion == planned.actionVersion &&
      request.expectedRevision == planned.expectedRevision &&
      request.idempotencyKey == planned.idempotencyKey &&
      request.dryRun == planned.dryRun &&
      canonicalAuthoringJson(request.parameters) ==
          canonicalAuthoringJson(planned.parameters) &&
      canonicalAuthoringJson(request.extensions) ==
          canonicalAuthoringJson(planned.extensions);
  if (!sameSemantics) {
    throw const JournaledAuthoringTransactionException(
      'transaction.request_plan_mismatch',
      'The apply request does not match the frozen mutation plan.',
    );
  }
}

List<AuthoringTransactionJournalEntry> _replaceEntry(
  List<AuthoringTransactionJournalEntry> entries,
  int index,
  AuthoringTransactionJournalEntry replacement,
) {
  return List.unmodifiable([
    for (var entryIndex = 0; entryIndex < entries.length; entryIndex++)
      if (entryIndex == index) replacement else entries[entryIndex],
  ]);
}
~~~~~~~~

## `packages/map_authoring/lib/src/transactions/recovery_service.dart`

~~~~~~~~dart
import '../contracts/authoring_receipt.dart';
import '../ports/idempotency_store.dart';
import '../ports/transaction_file_gateway.dart';
import 'idempotency_ledger.dart';
import 'revision_set.dart';
import 'transaction_journal.dart';

enum AuthoringRecoveryDisposition {
  unreservedIntent,
  resumable,
  completed,
  blocked,
}

final class AuthoringRecoveryInspection {
  const AuthoringRecoveryInspection({
    required this.operationId,
    required this.journalStatus,
    required this.disposition,
    required this.message,
  });

  final String operationId;
  final AuthoringTransactionStatus journalStatus;
  final AuthoringRecoveryDisposition disposition;
  final String message;

  Map<String, Object?> toJson() => {
        'operationId': operationId,
        'journalStatus': journalStatus.name,
        'disposition': disposition.name,
        'message': message,
      };
}

final class AuthoringRecoveryException implements Exception {
  const AuthoringRecoveryException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => 'AuthoringRecoveryException($code): $message';
}

/// Inspects, resumes, or compensates a durable transaction without guessing.
final class AuthoringRecoveryService {
  const AuthoringRecoveryService({
    required TransactionFileGateway gateway,
    required AuthoringIdempotencyLedger idempotency,
    required DateTime Function() clock,
  })  : _gateway = gateway,
        _idempotency = idempotency,
        _clock = clock;

  final TransactionFileGateway _gateway;
  final AuthoringIdempotencyLedger _idempotency;
  final DateTime Function() _clock;

  Future<List<AuthoringRecoveryInspection>> inspect() {
    return _gateway.withExclusiveWriteLock(() async {
      final journals = await _gateway.listJournals();
      final inspections = <AuthoringRecoveryInspection>[];
      for (final journal in journals) {
        inspections.add(await _inspectJournal(journal));
      }
      return List.unmodifiable(inspections);
    });
  }

  Future<AuthoringReceipt> resume(String operationId) {
    return _gateway.withExclusiveWriteLock(() async {
      var journal = await _requireJournal(operationId);
      final record = await _requireRecoveryRecord(journal);
      if (record.status == AuthoringIdempotencyStatus.completed) {
        return record.receipt!;
      }
      await _requireStages(journal);
      if (journal.status == AuthoringTransactionStatus.compensated) {
        return _idempotency.completeRecovered(
          scope: journal.scope,
          operationId: operationId,
          receipt: journal.finalReceipt!,
        );
      }

      final states = await _states(journal);
      _requireOnlyBeforeOrAfter(states);
      if (journal.status == AuthoringTransactionStatus.committed) {
        if (!states.every((state) => state.isAfter)) {
          throw const AuthoringRecoveryException(
            'recovery.committed_state_mismatch',
            'Committed transaction resources do not match their after state.',
          );
        }
        final recovered = _recoveredReceipt(
          journal,
          outcome: 'resumed',
          beforeRevision: journal.intendedReceipt.beforeRevision,
          afterRevision: journal.intendedReceipt.afterRevision,
        );
        journal = journal.copyWith(
          updatedAt: _clock().toUtc(),
          finalReceipt: recovered,
        );
        await _gateway.writeJournal(journal);
        return _idempotency.completeRecovered(
          scope: journal.scope,
          operationId: operationId,
          receipt: recovered,
        );
      }

      journal = journal.copyWith(
        status: AuthoringTransactionStatus.promoting,
        updatedAt: _clock().toUtc(),
      );
      await _gateway.writeJournal(journal);
      for (var index = 0; index < journal.entries.length; index++) {
        final entry = journal.entries[index];
        final current = await _gateway.readResourceRevision(entry.storageKey);
        if (current == entry.afterRevision) {
          journal = await _checkpointEntry(
            journal,
            index,
            entry.copyWith(promoted: true),
          );
          continue;
        }
        if (current != entry.beforeRevision) {
          throw const AuthoringRecoveryException(
            'recovery.revision_conflict',
            'A transaction resource has an unexpected recovery revision.',
          );
        }
        await _gateway.promoteStaged(
          operationId: operationId,
          storageKey: entry.storageKey,
          kind: TransactionPayloadKind.after,
          expectedCurrentRevision: entry.beforeRevision,
        );
        journal = await _checkpointEntry(
          journal,
          index,
          entry.copyWith(promoted: true),
        );
      }

      final recovered = _recoveredReceipt(
        journal,
        outcome: 'resumed',
        beforeRevision: journal.intendedReceipt.beforeRevision,
        afterRevision: journal.intendedReceipt.afterRevision,
      );
      journal = journal.copyWith(
        status: AuthoringTransactionStatus.committed,
        updatedAt: _clock().toUtc(),
        finalReceipt: recovered,
      );
      await _gateway.writeJournal(journal);
      return _idempotency.completeRecovered(
        scope: journal.scope,
        operationId: operationId,
        receipt: recovered,
      );
    });
  }

  Future<AuthoringReceipt> compensate(String operationId) {
    return _gateway.withExclusiveWriteLock(() async {
      var journal = await _requireJournal(operationId);
      final record = await _requireRecoveryRecord(journal);
      if (record.status == AuthoringIdempotencyStatus.completed) {
        if (journal.status == AuthoringTransactionStatus.compensated) {
          return record.receipt!;
        }
        throw const AuthoringRecoveryException(
          'recovery.already_completed',
          'A completed transaction must be undone as a new transaction.',
        );
      }
      await _requireStages(journal);
      final states = await _states(journal);
      _requireOnlyBeforeOrAfter(states);

      journal = journal.copyWith(
        status: AuthoringTransactionStatus.compensating,
        updatedAt: _clock().toUtc(),
        finalReceipt: null,
      );
      await _gateway.writeJournal(journal);
      for (var index = journal.entries.length - 1; index >= 0; index--) {
        final entry = journal.entries[index];
        final current = await _gateway.readResourceRevision(entry.storageKey);
        if (current == entry.beforeRevision) {
          journal = await _checkpointEntry(
            journal,
            index,
            entry.copyWith(compensated: true),
          );
          continue;
        }
        if (current != entry.afterRevision) {
          throw const AuthoringRecoveryException(
            'recovery.revision_conflict',
            'A transaction resource has an unexpected compensation revision.',
          );
        }
        await _gateway.promoteStaged(
          operationId: operationId,
          storageKey: entry.storageKey,
          kind: TransactionPayloadKind.before,
          expectedCurrentRevision: entry.afterRevision,
        );
        journal = await _checkpointEntry(
          journal,
          index,
          entry.copyWith(compensated: true),
        );
      }

      final beforeSet = AuthoringRevisionSet([
        for (final entry in journal.entries)
          AuthoringResourceRevision(
            resource: entry.resource,
            revision: entry.beforeRevision,
          ),
      ]);
      final recovered = _recoveredReceipt(
        journal,
        outcome: 'compensated',
        beforeRevision: journal.intendedReceipt.afterRevision,
        afterRevision: beforeSet.fingerprint,
      );
      journal = journal.copyWith(
        status: AuthoringTransactionStatus.compensated,
        updatedAt: _clock().toUtc(),
        finalReceipt: recovered,
      );
      await _gateway.writeJournal(journal);
      return _idempotency.completeRecovered(
        scope: journal.scope,
        operationId: operationId,
        receipt: recovered,
      );
    });
  }

  Future<bool> discardUnreserved(String operationId) {
    return _gateway.withExclusiveWriteLock(() async {
      final journal = await _requireJournal(operationId);
      final record = await _idempotency.recordForRecovery(journal.scope);
      if (record != null ||
          (journal.status != AuthoringTransactionStatus.preparing &&
              journal.status != AuthoringTransactionStatus.staged)) {
        throw const AuthoringRecoveryException(
          'recovery.intent_reserved',
          'Only an unreserved preparation may be discarded.',
        );
      }
      final states = await _states(journal);
      if (!states.every((state) => state.isBefore)) {
        throw const AuthoringRecoveryException(
          'recovery.revision_conflict',
          'An unreserved intent cannot be discarded after a resource change.',
        );
      }
      await _gateway.deleteTransaction(operationId);
      return true;
    });
  }

  Future<AuthoringRecoveryInspection> _inspectJournal(
    AuthoringTransactionJournal journal,
  ) async {
    final record = await _idempotency.recordForRecovery(journal.scope);
    final states = await _states(journal);
    final stagesValid = await _stagesValid(journal);
    final hasUnexpected =
        states.any((state) => !state.isBefore && !state.isAfter);
    final stageRequired = record != null ||
        (journal.status != AuthoringTransactionStatus.preparing &&
            journal.status != AuthoringTransactionStatus.staged);
    if (hasUnexpected ||
        (stageRequired && !stagesValid) ||
        (record != null && record.operationId != journal.operationId)) {
      return _inspection(
        journal,
        AuthoringRecoveryDisposition.blocked,
        'Recovery is blocked by an unexpected resource or reservation state.',
      );
    }
    if (record == null) {
      final discardable =
          (journal.status == AuthoringTransactionStatus.preparing ||
                  journal.status == AuthoringTransactionStatus.staged) &&
              states.every((state) => state.isBefore);
      return _inspection(
        journal,
        discardable
            ? AuthoringRecoveryDisposition.unreservedIntent
            : AuthoringRecoveryDisposition.blocked,
        discardable
            ? 'The unreserved intent can be discarded or retried safely.'
            : 'Recovery is blocked because the durable reservation is absent.',
      );
    }
    if (record.status == AuthoringIdempotencyStatus.completed) {
      final stateMatches = switch (journal.status) {
        AuthoringTransactionStatus.committed =>
          states.every((state) => state.isAfter),
        AuthoringTransactionStatus.compensated =>
          states.every((state) => state.isBefore),
        _ => false,
      };
      return _inspection(
        journal,
        stateMatches
            ? AuthoringRecoveryDisposition.completed
            : AuthoringRecoveryDisposition.blocked,
        stateMatches
            ? 'The transaction and idempotency receipt are complete.'
            : 'A completed receipt conflicts with journal or resource state.',
      );
    }
    return _inspection(
      journal,
      AuthoringRecoveryDisposition.resumable,
      'The pending transaction can be resumed or compensated.',
    );
  }

  Future<AuthoringTransactionJournal> _requireJournal(
    String operationId,
  ) async {
    final journal = await _gateway.readJournal(operationId);
    if (journal == null) {
      throw const AuthoringRecoveryException(
        'recovery.journal_missing',
        'The requested recovery journal is unavailable.',
      );
    }
    return journal;
  }

  Future<AuthoringIdempotencyRecord> _requireRecoveryRecord(
    AuthoringTransactionJournal journal,
  ) async {
    final record = await _idempotency.recordForRecovery(journal.scope);
    if (record == null || record.operationId != journal.operationId) {
      throw const AuthoringRecoveryException(
        'recovery.reservation_missing',
        'The matching pending reservation is unavailable.',
      );
    }
    return record;
  }

  Future<List<_ResourceRecoveryState>> _states(
    AuthoringTransactionJournal journal,
  ) async {
    return [
      for (final entry in journal.entries)
        _ResourceRecoveryState(
          entry: entry,
          currentRevision:
              await _gateway.readResourceRevision(entry.storageKey),
        ),
    ];
  }

  void _requireOnlyBeforeOrAfter(List<_ResourceRecoveryState> states) {
    if (states.any((state) => !state.isBefore && !state.isAfter)) {
      throw const AuthoringRecoveryException(
        'recovery.revision_conflict',
        'A transaction resource has an unexpected recovery revision.',
      );
    }
  }

  Future<bool> _stagesValid(AuthoringTransactionJournal journal) async {
    try {
      for (final entry in journal.entries) {
        final before = await _gateway.readStagedPayload(
          operationId: journal.operationId,
          storageKey: entry.storageKey,
          kind: TransactionPayloadKind.before,
        );
        final after = await _gateway.readStagedPayload(
          operationId: journal.operationId,
          storageKey: entry.storageKey,
          kind: TransactionPayloadKind.after,
        );
        if (before.revision != entry.beforeRevision ||
            after.revision != entry.afterRevision) {
          return false;
        }
      }
      return true;
    } on TransactionFileGatewayException {
      return false;
    }
  }

  Future<void> _requireStages(AuthoringTransactionJournal journal) async {
    if (!await _stagesValid(journal)) {
      throw const AuthoringRecoveryException(
        'recovery.stage_invalid',
        'A staged recovery payload is missing or corrupt.',
      );
    }
  }

  Future<AuthoringTransactionJournal> _checkpointEntry(
    AuthoringTransactionJournal journal,
    int index,
    AuthoringTransactionJournalEntry replacement,
  ) async {
    final updated = journal.copyWith(
      updatedAt: _clock().toUtc(),
      entries: [
        for (var entryIndex = 0;
            entryIndex < journal.entries.length;
            entryIndex++)
          if (entryIndex == index) replacement else journal.entries[entryIndex],
      ],
    );
    await _gateway.writeJournal(updated);
    return updated;
  }

  AuthoringReceipt _recoveredReceipt(
    AuthoringTransactionJournal journal, {
    required String outcome,
    required String? beforeRevision,
    required String? afterRevision,
  }) {
    final intended = journal.intendedReceipt;
    return AuthoringReceipt(
      receiptId: intended.receiptId,
      requestId: intended.requestId,
      actionId: intended.actionId,
      actionVersion: intended.actionVersion,
      status: AuthoringReceiptStatus.recovered,
      beforeRevision: beforeRevision,
      afterRevision: afterRevision,
      createdAtUtc: _clock().toUtc().toIso8601String(),
      diff: intended.diff,
      artifacts: intended.artifacts,
      extensions: {
        ...intended.extensions,
        'recoveryOutcome': outcome,
      },
    );
  }
}

AuthoringRecoveryInspection _inspection(
  AuthoringTransactionJournal journal,
  AuthoringRecoveryDisposition disposition,
  String message,
) {
  return AuthoringRecoveryInspection(
    operationId: journal.operationId,
    journalStatus: journal.status,
    disposition: disposition,
    message: message,
  );
}

final class _ResourceRecoveryState {
  const _ResourceRecoveryState({
    required this.entry,
    required this.currentRevision,
  });

  final AuthoringTransactionJournalEntry entry;
  final String? currentRevision;

  bool get isBefore => currentRevision == entry.beforeRevision;
  bool get isAfter => currentRevision == entry.afterRevision;
}
~~~~~~~~

## `packages/map_authoring/test/support/transaction_test_fixture.dart`

~~~~~~~~dart
import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';

final class TransactionTestHarness {
  TransactionTestHarness._({
    required this.projectDirectory,
    required this.planStore,
    required this.plan,
    required this.scope,
    required this.gateway,
    required this.ledger,
    required this.transaction,
    required this.now,
  });

  static Future<TransactionTestHarness> create({
    AuthoringTransactionFaultInjector? faultInjector,
  }) async {
    final projectDirectory = await Directory.systemTemp.createTemp(
      'pokemap_transaction_',
    );
    final dataDirectory = await Directory(
      _join(projectDirectory.path, 'data'),
    ).create();
    await File(_join(dataDirectory.path, 'a.json')).writeAsBytes(beforeA);
    await File(_join(dataDirectory.path, 'b.json')).writeAsBytes(beforeB);
    await File(_join(dataDirectory.path, 'deleted.json'))
        .writeAsBytes(beforeDeleted);

    final now = DateTime.utc(2026, 7, 31, 12);
    final snapshotRevision = computeAuthoringBytesFingerprint(
      utf8.encode('transaction-test-snapshot'),
      logicalName: 'snapshot',
    );
    final snapshot = ProjectSnapshot(
      projectHandle: const ProjectHandle('prj_transaction'),
      revision: snapshotRevision,
      manifest: ProjectManifest(
        name: 'Transaction Fixture',
        maps: const [],
        tilesets: const [],
      ),
      maps: const [],
      resourceFingerprints: {'project': snapshotRevision},
    );
    final planStore = AuthoringPlanStore(clock: () => now);
    var token = 0;
    final planner = AuthoringActionPlanner(
      store: planStore,
      tokenFactory: (prefix) => '$prefix${token++}',
      seedFactory: () => 404,
    );
    final plan = await planner.plan(
      request: AuthoringRequest(
        requestId: 'req-transaction',
        actionId: 'fixture.multiWrite',
        actionVersion: 1,
        workspaceHandle: 'workspace:transaction',
        parameters: const {'fixture': true},
        expectedRevision: snapshotRevision,
        idempotencyKey: 'idem-transaction',
      ),
      snapshot: snapshot,
      build: (_) => _draft(),
    );
    final scope = AuthoringIdempotencyScope(
      actorId: 'actor-transaction',
      projectId: 'project-transaction',
      actionId: plan.request.actionId,
      actionVersion: plan.request.actionVersion,
      key: plan.request.idempotencyKey!,
    );
    final gateway = await LocalTransactionFileGateway.open(
      projectRoot: projectDirectory.path,
    );
    final ledger = _ledger(projectDirectory.path, now);
    return TransactionTestHarness._(
      projectDirectory: projectDirectory,
      planStore: planStore,
      plan: plan,
      scope: scope,
      gateway: gateway,
      ledger: ledger,
      transaction: JournaledAuthoringTransaction(
        plans: planStore,
        gateway: gateway,
        idempotency: ledger,
        clock: () => now,
        faultInjector: faultInjector,
      ),
      now: now,
    );
  }

  static final List<int> beforeA = utf8.encode('{"id":"a","value":0}');
  static final List<int> afterA = utf8.encode('{"id":"a","value":1}');
  static final List<int> beforeB = utf8.encode('{"id":"b","value":0}');
  static final List<int> afterB = utf8.encode('{"id":"b","value":1}');
  static final List<int> afterCreated = utf8.encode('{"id":"created"}');
  static final List<int> beforeDeleted = utf8.encode('{"id":"deleted"}');

  final Directory projectDirectory;
  final AuthoringPlanStore planStore;
  final AuthoringPlan plan;
  final AuthoringIdempotencyScope scope;
  final LocalTransactionFileGateway gateway;
  final AuthoringIdempotencyLedger ledger;
  final JournaledAuthoringTransaction transaction;
  final DateTime now;

  String get operationId => 'operation-transaction';
  String get currentProjectRevision => plan.baseRevision;
  String get ledgerPath => _join(
        projectDirectory.path,
        '.pokemap',
        'authoring',
        'idempotency.jsonl',
      );

  Future<AuthoringReceipt> apply() {
    return transaction.apply(
      planId: plan.planId,
      request: plan.request,
      currentProjectRevision: currentProjectRevision,
      scope: scope,
      operationId: operationId,
    );
  }

  Future<List<int>?> readA() => gateway.readResource('data/a.json');
  Future<List<int>?> readB() => gateway.readResource('data/b.json');
  Future<List<int>?> readCreated() => gateway.readResource('data/created.json');
  Future<List<int>?> readDeleted() => gateway.readResource('data/deleted.json');

  Future<void> writeExternalA(List<int> bytes) =>
      File(_join(projectDirectory.path, 'data', 'a.json')).writeAsBytes(bytes);

  Future<void> writeExternalB(List<int> bytes) =>
      File(_join(projectDirectory.path, 'data', 'b.json')).writeAsBytes(bytes);

  Future<AuthoringTransactionJournal?> readJournal() =>
      gateway.readJournal(operationId);

  Future<AuthoringRecoveryService> reopenRecovery() async {
    final reopenedGateway = await LocalTransactionFileGateway.open(
      projectRoot: projectDirectory.path,
    );
    return AuthoringRecoveryService(
      gateway: reopenedGateway,
      idempotency: _ledger(projectDirectory.path, now),
      clock: () => now,
    );
  }

  Future<void> dispose() => projectDirectory.delete(recursive: true);
}

AuthoringIdempotencyLedger _ledger(String projectPath, DateTime now) {
  return AuthoringIdempotencyLedger(
    store: FileIdempotencyStore(
      filePath: _join(
        projectPath,
        '.pokemap',
        'authoring',
        'idempotency.jsonl',
      ),
    ),
    clock: () => now,
  );
}

AuthoringMutationDraft _draft() {
  final resourceA = AuthoringResourceRef(kind: 'fixture', id: 'a');
  final resourceB = AuthoringResourceRef(kind: 'fixture', id: 'b');
  final changeA = AuthoringResourceChange(
    resource: resourceA,
    storageKey: 'data/a.json',
    beforeBytes: TransactionTestHarness.beforeA,
    afterBytes: TransactionTestHarness.afterA,
  );
  final changeB = AuthoringResourceChange(
    resource: resourceB,
    storageKey: 'data/b.json',
    beforeBytes: TransactionTestHarness.beforeB,
    afterBytes: TransactionTestHarness.afterB,
  );
  final createdResource = AuthoringResourceRef(kind: 'fixture', id: 'created');
  final deletedResource = AuthoringResourceRef(kind: 'fixture', id: 'deleted');
  final create = AuthoringResourceChange(
    resource: createdResource,
    storageKey: 'data/created.json',
    beforeBytes: null,
    afterBytes: TransactionTestHarness.afterCreated,
  );
  final delete = AuthoringResourceChange(
    resource: deletedResource,
    storageKey: 'data/deleted.json',
    beforeBytes: TransactionTestHarness.beforeDeleted,
    afterBytes: null,
  );
  return AuthoringMutationDraft(
    changeSet: AuthoringChangeSet(
      changes: [delete, changeB, create, changeA],
      diff: AuthoringDiff([
        AuthoringDiffEntry(
          operation: AuthoringDiffOperation.replace,
          resource: resourceB,
          path: r'$.value',
          before: 0,
          after: 1,
        ),
        AuthoringDiffEntry(
          operation: AuthoringDiffOperation.replace,
          resource: resourceA,
          path: r'$.value',
          before: 0,
          after: 1,
        ),
        AuthoringDiffEntry(
          operation: AuthoringDiffOperation.add,
          resource: createdResource,
          path: r'$',
          after: const {'id': 'created'},
        ),
        AuthoringDiffEntry(
          operation: AuthoringDiffOperation.remove,
          resource: deletedResource,
          path: r'$',
          before: const {'id': 'deleted'},
        ),
      ]),
    ),
  );
}

String _join(
  String first,
  String second, [
  String? third,
  String? fourth,
]) =>
    [
      first,
      second,
      if (third != null) third,
      if (fourth != null) fourth,
    ].join(Platform.pathSeparator);
~~~~~~~~

## `packages/map_authoring/test/transactions/crash_boundary_test.dart`

~~~~~~~~dart
import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:test/test.dart';

import '../support/transaction_test_fixture.dart';

void main() {
  group('JournaledAuthoringTransaction', () {
    test('applies update create and delete once then replays exact receipt',
        () async {
      final harness = await TransactionTestHarness.create();
      addTearDown(harness.dispose);

      final first = await harness.apply();
      final retry = await harness.apply();

      expect(first.status, AuthoringReceiptStatus.applied);
      expect(retry.toJson(), first.toJson());
      expect(await harness.readA(), TransactionTestHarness.afterA);
      expect(await harness.readB(), TransactionTestHarness.afterB);
      expect(await harness.readCreated(), TransactionTestHarness.afterCreated);
      expect(await harness.readDeleted(), isNull);
      expect(
        (await harness.readJournal())?.status,
        AuthoringTransactionStatus.committed,
      );

      final replayWithoutPlan = JournaledAuthoringTransaction(
        plans: AuthoringPlanStore(clock: () => harness.now),
        gateway: await LocalTransactionFileGateway.open(
          projectRoot: harness.projectDirectory.path,
        ),
        idempotency: AuthoringIdempotencyLedger(
          store: FileIdempotencyStore(filePath: harness.ledgerPath),
          clock: () => harness.now,
        ),
        clock: () => harness.now,
      );
      final durableReplay = await replayWithoutPlan.apply(
        planId: 'plan_no_longer_in_memory',
        request: AuthoringRequest(
          requestId: 'req-after-restart',
          actionId: harness.plan.request.actionId,
          actionVersion: harness.plan.request.actionVersion,
          workspaceHandle: 'workspace:reopened',
          parameters: harness.plan.request.parameters,
          expectedRevision: harness.plan.request.expectedRevision,
          idempotencyKey: harness.plan.request.idempotencyKey,
        ),
        currentProjectRevision: 'sha256:${List.filled(64, 'f').join()}',
        scope: harness.scope,
        operationId: 'operation-after-restart',
      );
      expect(durableReplay.toJson(), first.toJson());
    });

    for (final checkpoint in [
      AuthoringTransactionCheckpoint.afterJournalPreparing,
      AuthoringTransactionCheckpoint.afterPayloadsStaged,
      AuthoringTransactionCheckpoint.afterJournalStaged,
    ]) {
      test('$checkpoint leaves an unreserved discardable intent', () async {
        var crashed = false;
        final harness = await TransactionTestHarness.create(
          faultInjector: (context) {
            if (!crashed && context.checkpoint == checkpoint) {
              crashed = true;
              throw const AuthoringTransactionSimulatedCrash();
            }
          },
        );
        addTearDown(harness.dispose);

        await expectLater(
            harness.apply,
            throwsA(
              isA<AuthoringTransactionSimulatedCrash>(),
            ));

        final recovery = await harness.reopenRecovery();
        final inspection = (await recovery.inspect()).single;
        expect(inspection.disposition,
            AuthoringRecoveryDisposition.unreservedIntent);
        expect(await harness.readA(), TransactionTestHarness.beforeA);
        expect(await harness.readB(), TransactionTestHarness.beforeB);
        expect(await recovery.discardUnreserved(harness.operationId), isTrue);
        expect(await recovery.inspect(), isEmpty);
      });
    }

    for (final checkpoint in [
      AuthoringTransactionCheckpoint.afterReservation,
      AuthoringTransactionCheckpoint.afterJournalPrepared,
      AuthoringTransactionCheckpoint.afterResourcePromoted,
      AuthoringTransactionCheckpoint.afterResourceJournaled,
      AuthoringTransactionCheckpoint.afterJournalCommitted,
    ]) {
      test('$checkpoint resumes idempotently after service reconstruction',
          () async {
        var crashed = false;
        final harness = await TransactionTestHarness.create(
          faultInjector: (context) {
            final firstResourceBoundary =
                context.promotionIndex == null || context.promotionIndex == 0;
            if (!crashed &&
                context.checkpoint == checkpoint &&
                firstResourceBoundary) {
              crashed = true;
              throw const AuthoringTransactionSimulatedCrash();
            }
          },
        );
        addTearDown(harness.dispose);

        await expectLater(
          harness.apply,
          throwsA(isA<AuthoringTransactionSimulatedCrash>()),
        );
        if (checkpoint ==
                AuthoringTransactionCheckpoint.afterResourcePromoted ||
            checkpoint ==
                AuthoringTransactionCheckpoint.afterResourceJournaled) {
          expect(await harness.readA(), TransactionTestHarness.afterA);
          expect(await harness.readB(), TransactionTestHarness.beforeB);
        }

        final recovery = await harness.reopenRecovery();
        expect(
          (await recovery.inspect()).single.disposition,
          AuthoringRecoveryDisposition.resumable,
        );
        final recovered = await recovery.resume(harness.operationId);
        final repeated = await recovery.resume(harness.operationId);

        expect(recovered.status, AuthoringReceiptStatus.recovered);
        expect(repeated.toJson(), recovered.toJson());
        expect(await harness.readA(), TransactionTestHarness.afterA);
        expect(await harness.readB(), TransactionTestHarness.afterB);
        expect(
          await harness.readCreated(),
          TransactionTestHarness.afterCreated,
        );
        expect(await harness.readDeleted(), isNull);
        expect(
          (await harness.readJournal())?.status,
          AuthoringTransactionStatus.committed,
        );
      });
    }

    test('rejects stale touched resources before journal or reservation',
        () async {
      final harness = await TransactionTestHarness.create();
      addTearDown(harness.dispose);
      await harness.writeExternalB(utf8.encode('{"external":true}'));

      await expectLater(
        harness.apply,
        throwsA(isA<AuthoringRevisionConflict>()),
      );

      expect(await harness.readJournal(), isNull);
      expect(
          await FileIdempotencyStore(filePath: harness.ledgerPath)
              .read(harness.scope),
          isNull);
      expect(await harness.readA(), TransactionTestHarness.beforeA);
      expect(await harness.readB(), utf8.encode('{"external":true}'));
    });

    test('rejects an apply request that differs from the frozen plan',
        () async {
      final harness = await TransactionTestHarness.create();
      addTearDown(harness.dispose);
      final mismatched = AuthoringRequest(
        requestId: 'req-mismatch',
        actionId: harness.plan.request.actionId,
        actionVersion: harness.plan.request.actionVersion,
        workspaceHandle: harness.plan.request.workspaceHandle,
        parameters: const {'fixture': false},
        expectedRevision: harness.plan.request.expectedRevision,
        idempotencyKey: harness.plan.request.idempotencyKey,
      );

      await expectLater(
        () => harness.transaction.apply(
          planId: harness.plan.planId,
          request: mismatched,
          currentProjectRevision: harness.currentProjectRevision,
          scope: harness.scope,
          operationId: harness.operationId,
        ),
        throwsA(
          isA<JournaledAuthoringTransactionException>().having(
            (error) => error.code,
            'code',
            'transaction.request_plan_mismatch',
          ),
        ),
      );
      expect(await harness.readJournal(), isNull);
      expect(
        await FileIdempotencyStore(filePath: harness.ledgerPath)
            .read(harness.scope),
        isNull,
      );
    });

    test('second CAS blocks an external edit immediately before promotion',
        () async {
      late TransactionTestHarness harness;
      var changed = false;
      harness = await TransactionTestHarness.create(
        faultInjector: (context) async {
          if (!changed &&
              context.checkpoint ==
                  AuthoringTransactionCheckpoint.beforeResourcePromotion &&
              context.promotionIndex == 0) {
            changed = true;
            await harness.writeExternalA(
              utf8.encode('{"external":"late"}'),
            );
          }
        },
      );
      addTearDown(harness.dispose);

      await expectLater(
        harness.apply,
        throwsA(
          isA<TransactionFileGatewayException>().having(
            (error) => error.code,
            'code',
            'transaction.revision_conflict',
          ),
        ),
      );

      final inspection =
          (await (await harness.reopenRecovery()).inspect()).single;
      expect(inspection.disposition, AuthoringRecoveryDisposition.blocked);
      expect(await harness.readA(), utf8.encode('{"external":"late"}'));
      expect(await harness.readB(), TransactionTestHarness.beforeB);
    });

    test('rejects symlink parents and path-like operation identifiers',
        () async {
      final harness = await TransactionTestHarness.create();
      addTearDown(harness.dispose);
      final external = await Directory.systemTemp.createTemp(
        'pokemap_transaction_external_',
      );
      addTearDown(() => external.delete(recursive: true));
      await File('${external.path}${Platform.pathSeparator}outside.json')
          .writeAsString('{"outside":true}');
      await Link(
        '${harness.projectDirectory.path}${Platform.pathSeparator}linked',
      ).create(external.path);

      await expectLater(
        () => harness.gateway.readResource('linked/outside.json'),
        throwsA(isA<TransactionFileGatewayException>()),
      );
      await expectLater(
        () => harness.gateway.readJournal('../escape'),
        throwsA(
          isA<TransactionFileGatewayException>().having(
            (error) => error.code,
            'code',
            'transaction.operation_id_invalid',
          ),
        ),
      );
      expect(
        await File('${external.path}${Platform.pathSeparator}outside.json')
            .readAsString(),
        '{"outside":true}',
      );
    });
  });
}
~~~~~~~~

## `packages/map_authoring/test/transactions/recovery_idempotence_test.dart`

~~~~~~~~dart
import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:test/test.dart';

import '../support/transaction_test_fixture.dart';

void main() {
  group('AuthoringRecoveryService', () {
    test('compensates a partial promotion in reverse and closes idempotency',
        () async {
      var crashed = false;
      final harness = await TransactionTestHarness.create(
        faultInjector: (context) {
          if (!crashed &&
              context.checkpoint ==
                  AuthoringTransactionCheckpoint.afterResourcePromoted &&
              context.promotionIndex == 0) {
            crashed = true;
            throw const AuthoringTransactionSimulatedCrash();
          }
        },
      );
      addTearDown(harness.dispose);
      await expectLater(
        harness.apply,
        throwsA(isA<AuthoringTransactionSimulatedCrash>()),
      );

      final recovery = await harness.reopenRecovery();
      final receipt = await recovery.compensate(harness.operationId);
      final replay = await harness.apply();

      expect(receipt.status, AuthoringReceiptStatus.recovered);
      expect(receipt.extensions['recoveryOutcome'], 'compensated');
      expect(replay.toJson(), receipt.toJson());
      expect(await harness.readA(), TransactionTestHarness.beforeA);
      expect(await harness.readB(), TransactionTestHarness.beforeB);
      expect(await harness.readCreated(), isNull);
      expect(
        await harness.readDeleted(),
        TransactionTestHarness.beforeDeleted,
      );
      expect(
        (await harness.readJournal())?.status,
        AuthoringTransactionStatus.compensated,
      );
    });

    test('compensation refuses a promoted resource changed by another writer',
        () async {
      final harness = await _crashAfterFirstPromotion();
      addTearDown(harness.dispose);
      final external = utf8.encode('{"external":"after-promotion"}');
      await harness.writeExternalA(external);
      final recovery = await harness.reopenRecovery();

      await expectLater(
        () => recovery.compensate(harness.operationId),
        throwsA(isA<AuthoringRecoveryException>()),
      );

      expect(await harness.readA(), external);
      expect(await harness.readB(), TransactionTestHarness.beforeB);
      expect(
        (await recovery.inspect()).single.disposition,
        AuthoringRecoveryDisposition.blocked,
      );
    });

    test('forward recovery refuses an unpromoted resource changed externally',
        () async {
      final harness = await _crashAfterFirstPromotion();
      addTearDown(harness.dispose);
      final external = utf8.encode('{"external":"before-promotion"}');
      await harness.writeExternalB(external);
      final recovery = await harness.reopenRecovery();

      await expectLater(
        () => recovery.resume(harness.operationId),
        throwsA(isA<AuthoringRecoveryException>()),
      );

      expect(await harness.readA(), TransactionTestHarness.afterA);
      expect(await harness.readB(), external);
    });

    test('committed journal finalizes a pending ledger exactly once', () async {
      var crashed = false;
      final harness = await TransactionTestHarness.create(
        faultInjector: (context) {
          if (!crashed &&
              context.checkpoint ==
                  AuthoringTransactionCheckpoint.afterJournalCommitted) {
            crashed = true;
            throw const AuthoringTransactionSimulatedCrash();
          }
        },
      );
      addTearDown(harness.dispose);
      await expectLater(
        harness.apply,
        throwsA(isA<AuthoringTransactionSimulatedCrash>()),
      );

      final recovery = await harness.reopenRecovery();
      final first = await recovery.resume(harness.operationId);
      final second = await recovery.resume(harness.operationId);

      expect(first.status, AuthoringReceiptStatus.recovered);
      expect(second.toJson(), first.toJson());
      expect((await recovery.inspect()).single.disposition,
          AuthoringRecoveryDisposition.completed);
    });

    test('committed but unreceipted create and delete can be compensated',
        () async {
      var crashed = false;
      final harness = await TransactionTestHarness.create(
        faultInjector: (context) {
          if (!crashed &&
              context.checkpoint ==
                  AuthoringTransactionCheckpoint.afterJournalCommitted) {
            crashed = true;
            throw const AuthoringTransactionSimulatedCrash();
          }
        },
      );
      addTearDown(harness.dispose);
      await expectLater(
        harness.apply,
        throwsA(isA<AuthoringTransactionSimulatedCrash>()),
      );
      expect(await harness.readCreated(), TransactionTestHarness.afterCreated);
      expect(await harness.readDeleted(), isNull);

      final receipt = await (await harness.reopenRecovery())
          .compensate(harness.operationId);

      expect(receipt.extensions['recoveryOutcome'], 'compensated');
      expect(await harness.readCreated(), isNull);
      expect(
        await harness.readDeleted(),
        TransactionTestHarness.beforeDeleted,
      );
    });

    test('unreserved preparation can be discarded only while targets match',
        () async {
      var crashed = false;
      final harness = await TransactionTestHarness.create(
        faultInjector: (context) {
          if (!crashed &&
              context.checkpoint ==
                  AuthoringTransactionCheckpoint.afterJournalStaged) {
            crashed = true;
            throw const AuthoringTransactionSimulatedCrash();
          }
        },
      );
      addTearDown(harness.dispose);
      await expectLater(
        harness.apply,
        throwsA(isA<AuthoringTransactionSimulatedCrash>()),
      );
      final recovery = await harness.reopenRecovery();
      await harness.writeExternalA(utf8.encode('{"external":true}'));

      await expectLater(
        () => recovery.discardUnreserved(harness.operationId),
        throwsA(isA<AuthoringRecoveryException>()),
      );
      expect(
        (await recovery.inspect()).single.disposition,
        AuthoringRecoveryDisposition.blocked,
      );
    });

    test('corrupt staged payload blocks recovery before any promotion',
        () async {
      var crashed = false;
      final harness = await TransactionTestHarness.create(
        faultInjector: (context) {
          if (!crashed &&
              context.checkpoint ==
                  AuthoringTransactionCheckpoint.afterJournalPrepared) {
            crashed = true;
            throw const AuthoringTransactionSimulatedCrash();
          }
        },
      );
      addTearDown(harness.dispose);
      await expectLater(
        harness.apply,
        throwsA(isA<AuthoringTransactionSimulatedCrash>()),
      );
      final operationDirectory = Directory(
        [
          harness.projectDirectory.path,
          '.pokemap',
          'authoring',
          'transactions',
          harness.operationId,
        ].join(Platform.pathSeparator),
      );
      final stagedAfter = operationDirectory
          .listSync()
          .whereType<File>()
          .firstWhere((file) => file.path.endsWith('.after.bin'));
      await stagedAfter.writeAsString('corrupt');

      final recovery = await harness.reopenRecovery();
      expect(
        (await recovery.inspect()).single.disposition,
        AuthoringRecoveryDisposition.blocked,
      );
      await expectLater(
        () => recovery.resume(harness.operationId),
        throwsA(isA<AuthoringRecoveryException>()),
      );
      expect(await harness.readA(), TransactionTestHarness.beforeA);
      expect(await harness.readB(), TransactionTestHarness.beforeB);
    });
  });
}

Future<TransactionTestHarness> _crashAfterFirstPromotion() async {
  var crashed = false;
  final harness = await TransactionTestHarness.create(
    faultInjector: (context) {
      if (!crashed &&
          context.checkpoint ==
              AuthoringTransactionCheckpoint.afterResourcePromoted &&
          context.promotionIndex == 0) {
        crashed = true;
        throw const AuthoringTransactionSimulatedCrash();
      }
    },
  );
  await expectLater(
    harness.apply,
    throwsA(isA<AuthoringTransactionSimulatedCrash>()),
  );
  return harness;
}
~~~~~~~~
