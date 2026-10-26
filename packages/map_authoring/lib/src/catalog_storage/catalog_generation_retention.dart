import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:map_core/map_core.dart';

import '../history/content_blob_store.dart';
import '../history/history_store.dart';
import '../ports/idempotency_store.dart';
import '../ports/project_file_reader.dart';
import '../ports/transaction_file_gateway.dart';
import '../security/authoring_permission.dart';
import '../support/authoring_fingerprint.dart';
import 'catalog_storage_store.dart';

enum CatalogLeasePurpose { reader, preparation }

final class CatalogGenerationLease {
  CatalogGenerationLease._(this._retention, this.id, this.ownerId, this.roots);

  final CatalogGenerationRetention _retention;
  final String id;
  final String ownerId;
  final List<CatalogObjectReference> roots;
  bool _closed = false;
  bool get closed => _closed;

  Future<List<int>> readObject(CatalogObjectReference reference) {
    if (closed) {
      throw const CatalogStorageException(
          'catalog.lease_closed', 'The snapshot lease is closed.');
    }
    return _retention.store.readObject(reference);
  }

  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    await _retention.store.gateway.withExclusiveWriteLock(
      () => _retention.releaseUnderLock(id),
    );
  }
}

final class LeasedCatalogSnapshot {
  const LeasedCatalogSnapshot({required this.snapshot, required this.lease});
  final CatalogSnapshot snapshot;
  final CatalogGenerationLease lease;
  String get rootRevision => snapshot.root.sha256;
  Future<void> close() => lease.close();
}

final class CatalogCollectionResult {
  const CatalogCollectionResult({
    required this.retainedObjects,
    required this.deletedObjects,
    required this.deletedBytes,
    required this.reclaimedLeases,
  });
  final int retainedObjects;
  final int deletedObjects;
  final int deletedBytes;
  final int reclaimedLeases;
}

final class CatalogGenerationRetention {
  CatalogGenerationRetention({required this.store});

  final CatalogStorageStore store;
  static final Map<String, RandomAccessFile> _guards = {};
  static const _maximumRecords = 4096;
  static const _maximumObjects = 200000;
  static const _maximumBytes = 2 * 1024 * 1024 * 1024;
  late final Future<String> _root =
      const LocalProjectFileReader().canonicalizeDirectory(store.projectRoot);

  Future<void> bindProjectUnderLock(String projectId) async {
    safeAuthoringSecurityIdentifier(projectId, 'projectId');
    AuthoringIdempotencyScope(
        actorId: 'catalog',
        projectId: projectId,
        actionId: 'catalog.units.patch',
        actionVersion: 1,
        key: 'catalog-identity-admission');
    await _directory('catalog', create: true);
    final file = await _file('catalog/IDENTITY.json', allowMissing: true);
    if (file == null) {
      final head = await store.readHead();
      if (head == null) {
        throw const CatalogStorageException(
            'catalog.missing', 'There is no catalog generation.');
      }
      await store.restoreIndexAdmission((await store.openRoot(head)).snapshot);
      await _replace(
          'catalog/IDENTITY.json',
          utf8.encode(canonicalAuthoringJson({
            'schemaVersion': 1,
            'projectId': projectId,
          })));
      return;
    }
    if (await file.length() > 4096) {
      throw const FormatException('catalog.identity: oversized record');
    }
    final text = await file.readAsString();
    final json = jsonDecode(text);
    if (json is! Map<String, dynamic> ||
        json.length != 2 ||
        json['schemaVersion'] is! int ||
        json['schemaVersion'] != 1 ||
        json['projectId'] is! String ||
        canonicalAuthoringJson(json) != text) {
      throw const FormatException('catalog.identity: invalid record');
    }
    if (json['projectId'] != projectId) {
      throw const CatalogStorageException('catalog.project_mismatch',
          'The catalog belongs to a different project.');
    }
  }

  Future<LeasedCatalogSnapshot> openSnapshot() =>
      store.gateway.withExclusiveWriteLock(() async {
        final root = await store.readHead();
        if (root == null) {
          throw const CatalogStorageException(
              'catalog.missing', 'There is no catalog generation.');
        }
        final lease = await protectUnderLock(
          roots: [root],
          ownerId: _token(),
          purpose: CatalogLeasePurpose.reader,
        );
        try {
          final snapshot = await CatalogSnapshot.open(
            root: root,
            limits: store.limits,
            readObject: lease.readObject,
          );
          return LeasedCatalogSnapshot(snapshot: snapshot, lease: lease);
        } catch (_) {
          await releaseUnderLock(lease.id);
          rethrow;
        }
      });

  Future<CatalogGenerationLease> protectUnderLock({
    required Iterable<CatalogObjectReference> roots,
    required String ownerId,
    required CatalogLeasePurpose purpose,
  }) async {
    if (ownerId.isEmpty ||
        ownerId.length > 256 ||
        ownerId.runes.any((value) => value < 32 || value == 127)) {
      throw const FormatException('catalog.lease: invalid owner');
    }
    final values = roots.toSet().toList()
      ..sort((a, b) => a.sha256.compareTo(b.sha256));
    if (values.isEmpty || values.length > 16) {
      throw const FormatException('catalog.lease: invalid roots');
    }
    final id = _token();
    final directory = await _directory('catalog/lease-locks', create: true);
    final guard = File('${directory.path}/$id.lock');
    await guard.create(exclusive: true);
    final handle = await guard.open(mode: FileMode.append);
    final identity = '${await _root}/$id';
    try {
      await handle.lock(FileLock.exclusive);
      _guards[identity] = handle;
      final record = {
        'schemaVersion': 1,
        'id': id,
        'ownerId': ownerId,
        'ownerPid': pid,
        'purpose': purpose.name,
        'roots': values.map((root) => root.toJson()).toList(),
      };
      await _replace('catalog/leases/$id.json',
          utf8.encode(canonicalAuthoringJson(record)));
    } catch (_) {
      _guards.remove(identity);
      await handle.close();
      if (await guard.exists()) await guard.delete();
      rethrow;
    }
    return CatalogGenerationLease._(
        this, id, ownerId, List.unmodifiable(values));
  }

  Future<void> releaseUnderLock(String id) async {
    _requireToken(id);
    final identity = '${await _root}/$id';
    final handle = _guards.remove(identity);
    try {
      await _replace('catalog/leases/$id.json', null);
    } finally {
      if (handle != null) await handle.close();
    }
    final guard =
        await _file('catalog/lease-locks/$id.lock', allowMissing: true);
    if (guard != null) await guard.delete();
  }

  Future<void> releaseOwnerUnderLock(String ownerId) async {
    for (final record in await _records()) {
      if (record.ownerId == ownerId &&
          record.purpose == CatalogLeasePurpose.preparation) {
        await releaseUnderLock(record.id);
      }
    }
  }

  Future<void> requireNoPreparedGenerationsUnderLock() async {
    for (final record in await _records()) {
      if (record.purpose == CatalogLeasePurpose.preparation &&
          await _active(record)) {
        throw const CatalogStorageException('catalog.preparation_active',
            'Finish or discard prepared catalog edits before history maintenance.');
      }
    }
  }

  Future<void> requireNoPendingTransactionsUnderLock() async {
    final root = await _directory('.pokemap/authoring/transactions');
    final pending = [root];
    var inspected = 0;
    while (pending.isNotEmpty) {
      final directory = pending.removeLast();
      await for (final entity in directory.list(followLinks: false)) {
        if (++inspected > _maximumRecords) {
          throw const CatalogStorageException('catalog.collection_limit',
              'The transaction inventory exceeds the maintenance budget.');
        }
        if (entity is Directory) {
          pending.add(entity);
        } else if (entity is! File ||
            directory.path != root.path ||
            entity.uri.pathSegments.last != 'write.lock' ||
            await entity.length() != 0) {
          throw const CatalogStorageException('catalog.recovery_required',
              'Finalize all project transaction namespaces before history maintenance.');
        }
      }
    }
  }

  Future<CatalogCollectionResult> collect({
    required String projectId,
    required AuthoringHistoryStore history,
    required AuthoringContentBlobStore blobs,
    bool dryRun = false,
  }) =>
      store.gateway.withExclusiveWriteLock(() => collectUnderLock(
          projectId: projectId,
          history: history,
          blobs: blobs,
          dryRun: dryRun));

  Future<CatalogCollectionResult> collectUnderLock({
    required String projectId,
    required AuthoringHistoryStore history,
    required AuthoringContentBlobStore blobs,
    bool dryRun = false,
    CatalogObjectReader? readObject,
  }) async {
    await bindProjectUnderLock(projectId);
    final roots = <CatalogObjectReference>{};
    final head = await store.readHead();
    if (head != null) roots.add(head);
    final journals = await store.gateway.listJournals();
    final catalogOperations = {
      for (final journal in journals)
        if (journal.entries.any(
            (entry) => entry.storageKey == CatalogStorageStore.headStorageKey))
          journal.operationId,
    };
    final records = await _records();
    final stale = <_LeaseRecord>[];
    for (final record in records) {
      final pending = record.purpose == CatalogLeasePurpose.preparation &&
          catalogOperations.contains(record.ownerId);
      if (pending || await _active(record)) {
        roots.addAll(record.roots);
      } else {
        stale.add(record);
      }
    }
    for (final operation in catalogOperations) {
      if (!records.any((record) =>
          record.purpose == CatalogLeasePurpose.preparation &&
          record.ownerId == operation)) {
        throw const CatalogStorageException('catalog.recovery_required',
            'An unresolved catalog transaction has no generation pin.');
      }
    }
    AuthoringHistoryCursor? cursor;
    final cursors = <String>{};
    var historyEntries = 0;
    do {
      final page =
          await history.list(projectId: projectId, limit: 100, cursor: cursor);
      historyEntries += page.entries.length;
      if (historyEntries > _maximumRecords) {
        throw const CatalogStorageException('catalog.collection_limit',
            'The retained history exceeds the collection budget.');
      }
      for (final entry in page.entries) {
        if (entry.nonUndoableReason != null) continue;
        for (final change in entry.changes) {
          if (change.storageKey != CatalogStorageStore.headStorageKey) {
            continue;
          }
          for (final (id, revision) in [
            (change.beforeBlobId, change.beforeRevision),
            (change.afterBlobId, change.afterRevision),
          ]) {
            if (id == null) continue;
            final payload = await blobs.get(id);
            if (payload == null ||
                payload.byteLength > CatalogStorageStore.maximumHeadBytes) {
              throw const CatalogStorageException('catalog.history_unavailable',
                  'A retained generation is unavailable.');
            }
            final bytes = BytesBuilder(copy: false);
            await for (final chunk in payload.openRead()) {
              if (bytes.length + chunk.length >
                  CatalogStorageStore.maximumHeadBytes) {
                throw const FormatException('catalog.history: oversized head');
              }
              bytes.add(chunk);
            }
            final headBytes = bytes.takeBytes();
            if (computeAuthoringBytesFingerprint(headBytes,
                    logicalName: CatalogStorageStore.headStorageKey) !=
                revision) {
              throw const CatalogStorageException('catalog.history_unavailable',
                  'A retained generation does not match its history revision.');
            }
            roots.add(_decodeHead(headBytes));
          }
        }
      }
      cursor = page.nextCursor;
      if (cursor != null && !cursors.add(cursor.wireValue)) {
        throw const FormatException('catalog.history: repeated cursor');
      }
    } while (cursor != null);
    if (roots.length > _maximumRecords) {
      throw const FormatException('catalog.collection: too many roots');
    }
    final retained = <String>{};
    var retainedBytes = 0;
    for (final root in roots) {
      final snapshot = await store.openRoot(root, readObject: readObject);
      for (final reference in await snapshot.snapshot.objectReferences()) {
        if (retained.add(reference.sha256)) {
          retainedBytes += reference.byteLength;
        }
        if (retained.length > _maximumObjects ||
            retainedBytes > _maximumBytes) {
          throw const FormatException('catalog.collection: graph budget');
        }
      }
    }
    final directory = await _directory('catalog/objects');
    final garbage = <(String, int)>[];
    var inspectedBytes = 0;
    var inspectedObjects = 0;
    await for (final entity in directory.list(followLinks: false)) {
      if (entity is! File ||
          !RegExp(r'/[a-f0-9]{64}\.json$').hasMatch(entity.path)) {
        throw const FormatException('catalog.collection: unsafe object entry');
      }
      if (++inspectedObjects > _maximumObjects) {
        throw const FormatException('catalog.collection: object budget');
      }
      final digest = entity.path.split('/').last.substring(0, 64);
      final size = await entity.length();
      inspectedBytes += size;
      if (size < 1 ||
          size > store.limits.maxUnitBytes ||
          inspectedBytes > _maximumBytes) {
        throw const FormatException('catalog.collection: byte budget');
      }
      final bytes = await store
          .readObject(CatalogObjectReference(sha256: digest, byteLength: size));
      if (bytes.length != size || sha256.convert(bytes).toString() != digest) {
        throw const CatalogStorageException('catalog.object_corrupt',
            'A catalog object failed verification before collection.');
      }
      if (!retained.contains(digest)) {
        garbage.add(('catalog/objects/$digest.json', size));
      }
    }
    var deletedBytes = 0;
    for (final (path, size) in garbage) {
      if (!dryRun) await _replace(path, null);
      deletedBytes += size;
    }
    if (!dryRun) {
      for (final record in stale) {
        await releaseUnderLock(record.id);
      }
    }
    return CatalogCollectionResult(
      retainedObjects: retained.length,
      deletedObjects: garbage.length,
      deletedBytes: deletedBytes,
      reclaimedLeases: stale.length,
    );
  }

  Future<bool> _active(_LeaseRecord record) async {
    if (record.ownerPid == pid) return true;
    final file = await _file('catalog/lease-locks/${record.id}.lock');
    if (await file!.length() != 0) {
      throw const FormatException('catalog.lease: invalid guard');
    }
    final handle = await file.open(mode: FileMode.append);
    try {
      try {
        await handle.lock(FileLock.exclusive);
      } on FileSystemException catch (error) {
        if (const {11, 13, 35}.contains(error.osError?.errorCode)) return true;
        rethrow;
      }
      await handle.unlock();
      return false;
    } finally {
      await handle.close();
    }
  }

  Future<List<_LeaseRecord>> _records() async {
    final directory = await _directory('catalog/leases', create: true);
    final result = <_LeaseRecord>[];
    await for (final entity in directory.list(followLinks: false)) {
      final name = entity.path.split('/').last;
      if (entity is! File || !RegExp(r'^[a-f0-9]{32}\.json$').hasMatch(name)) {
        throw const FormatException('catalog.lease: unsafe record');
      }
      if (result.length >= _maximumRecords) {
        throw const FormatException('catalog.lease: record budget');
      }
      final file = (await _file('catalog/leases/$name'))!;
      if (await file.length() > 8192) {
        throw const FormatException('catalog.lease: oversized record');
      }
      final text = await file.readAsString();
      final json = jsonDecode(text);
      if (json is! Map<String, dynamic> ||
          canonicalAuthoringJson(json) != text ||
          json.length != 6 ||
          json['schemaVersion'] is! int ||
          json['schemaVersion'] != 1 ||
          json['id'] != name.substring(0, 32) ||
          json['ownerId'] is! String ||
          (json['ownerId'] as String).isEmpty ||
          json['ownerPid'] is! int ||
          (json['ownerPid'] as int) <= 0 ||
          json['roots'] is! List ||
          (json['roots'] as List).isEmpty ||
          (json['roots'] as List).length > 16 ||
          !CatalogLeasePurpose.values
              .any((purpose) => purpose.name == json['purpose'])) {
        throw const FormatException('catalog.lease: invalid record');
      }
      result.add(_LeaseRecord(
        json['id'] as String,
        json['ownerId'] as String,
        json['ownerPid'] as int,
        CatalogLeasePurpose.values
            .singleWhere((purpose) => purpose.name == json['purpose']),
        (json['roots'] as List)
            .map((root) => CatalogObjectReference.fromJson(
                Map<String, Object?>.from(root as Map)))
            .toList(),
      ));
    }
    return result;
  }

  Future<void> _replace(String path, List<int>? bytes) async {
    final operation = 'catalog-retention-${_token()}';
    try {
      final before = await store.gateway.readResourceRevision(path);
      if (before == null && bytes == null) return;
      await store.gateway.stagePayload(
          operationId: operation,
          storageKey: path,
          kind: TransactionPayloadKind.after,
          bytes: bytes);
      await store.gateway.promoteStaged(
          operationId: operation,
          storageKey: path,
          kind: TransactionPayloadKind.after,
          expectedCurrentRevision: before);
    } finally {
      await store.gateway.deleteTransaction(operation);
    }
  }

  Future<Directory> _directory(String path, {bool create = false}) async {
    var current = await _root;
    for (final segment in path.split('/')) {
      current = '$current${Platform.pathSeparator}$segment';
      var type = await FileSystemEntity.type(current, followLinks: false);
      if (type == FileSystemEntityType.notFound && create) {
        await Directory(current).create();
        type = await FileSystemEntity.type(current, followLinks: false);
      }
      if (type != FileSystemEntityType.directory) {
        throw const FormatException('catalog.retention: unsafe directory');
      }
    }
    return Directory(current);
  }

  Future<File?> _file(String path, {bool allowMissing = false}) async {
    final parts = path.split('/');
    final directory = await _directory(parts.take(parts.length - 1).join('/'));
    final file = File('${directory.path}/${parts.last}');
    final type = await FileSystemEntity.type(file.path, followLinks: false);
    if (allowMissing && type == FileSystemEntityType.notFound) return null;
    if (type != FileSystemEntityType.file) {
      throw const FormatException('catalog.retention: unsafe file');
    }
    return file;
  }
}

final class _LeaseRecord {
  const _LeaseRecord(
      this.id, this.ownerId, this.ownerPid, this.purpose, this.roots);
  final String id;
  final String ownerId;
  final int ownerPid;
  final CatalogLeasePurpose purpose;
  final List<CatalogObjectReference> roots;
}

CatalogObjectReference _decodeHead(List<int> bytes) {
  final json = jsonDecode(utf8.decode(bytes));
  if (json is! Map<String, dynamic> ||
      json.length != 2 ||
      json['schemaVersion'] is! int ||
      json['schemaVersion'] != 1 ||
      json['root'] is! Map) {
    throw const FormatException('catalog.history: invalid head');
  }
  final root = CatalogObjectReference.fromJson(
      Map<String, Object?>.from(json['root'] as Map));
  final expected = CatalogStorageStore.encodeHead(root);
  if (sha256.convert(bytes).toString() != sha256.convert(expected).toString()) {
    throw const FormatException('catalog.history: noncanonical head');
  }
  return root;
}

String _token() {
  final random = Random.secure();
  return List.generate(
      16, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
}

void _requireToken(String value) {
  if (!RegExp(r'^[a-f0-9]{32}$').hasMatch(value)) {
    throw const FormatException('catalog.lease: invalid identity');
  }
}
