import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:map_core/map_core.dart';

import '../ports/project_file_reader.dart';
import '../ports/transaction_file_gateway.dart';
import '../support/authoring_fingerprint.dart';
import '../transactions/local_transaction_file_gateway.dart';
import 'catalog_history_compatibility.dart';
import 'trusted_catalog_admissions.dart';

final class CatalogStorageException implements Exception {
  const CatalogStorageException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => 'CatalogStorageException($code): $message';
}

final class PublishedCatalogSnapshot {
  const PublishedCatalogSnapshot({
    required this.rootRevision,
    required this.snapshot,
  });

  final String rootRevision;
  final CatalogSnapshot snapshot;
}

final class CatalogStorageStore {
  CatalogStorageStore({
    required this.projectRoot,
    required ProjectFileReader reader,
    required TransactionFileGateway gateway,
    CatalogStorageLimits? limits,
    Directory? trustedAdmissionDirectory,
  })  : _admissions = TrustedCatalogAdmissions(
            projectRoot: projectRoot, directory: trustedAdmissionDirectory),
        _reader = reader,
        _gateway = gateway,
        _limits = limits ?? CatalogStorageLimits();

  static Future<CatalogStorageStore> open({
    required String projectRoot,
    CatalogStorageLimits? limits,
    Directory? trustedAdmissionDirectory,
  }) async {
    const reader = LocalProjectFileReader();
    final root = await reader.canonicalizeDirectory(projectRoot);
    return CatalogStorageStore(
      projectRoot: root,
      reader: reader,
      gateway: await LocalTransactionFileGateway.open(projectRoot: root),
      limits: limits,
      trustedAdmissionDirectory: trustedAdmissionDirectory,
    );
  }

  static const headStorageKey = 'catalog/HEAD.json';
  static const maximumHeadBytes = 4096;

  final String projectRoot;
  final TrustedCatalogAdmissions _admissions;
  final ProjectFileReader _reader;
  final TransactionFileGateway _gateway;
  final CatalogStorageLimits _limits;
  TransactionFileGateway get gateway => _gateway;
  CatalogStorageLimits get limits => _limits;
  late final Future<String> _canonicalProjectRoot =
      _reader.canonicalizeDirectory(projectRoot);

  Future<PublishedCatalogSnapshot?> openSnapshot() async {
    if (await _requireLocalPath('catalog/IDENTITY.json', allowMissing: true)) {
      throw const CatalogStorageException('catalog.lease_required',
          'Open a leased snapshot for a managed catalog.');
    }
    final head = await _readHead();
    if (head == null) return null;
    return _openRoot(head);
  }

  static List<int> encodeHead(CatalogObjectReference root) => _headBytes(root);

  Future<CatalogObjectReference?> readHead() => _readHead();

  Future<void> restoreIndexAdmission(CatalogSnapshot snapshot) =>
      _admissions.restore(snapshot);

  Future<void> publishIndexAdmissionUnderLock(CatalogSnapshot snapshot) =>
      _admissions.publish(snapshot);

  Future<bool> metadataIndexPrepared(CatalogSnapshot snapshot) =>
      _admissions.metadataIndexPrepared(snapshot);

  Future<void> requireMetadataIndexAdmission(CatalogSnapshot snapshot) async {
    if (!await metadataIndexPrepared(snapshot)) {
      throw const CatalogStorageException('catalog.preparation_required',
          'Prepare this catalog explicitly before using local workshop document indexes.');
    }
  }

  Future<void> publishMetadataIndexAdmissionUnderLock(
          CatalogSnapshot snapshot) =>
      _admissions.publishMetadataIndex(snapshot);

  Future<void> publishHistoryConversionUnderLock(
      CatalogPreparedHistoryConversion prepared) async {
    prepared.requireOwner(this);
    await requireMetadataIndexAdmission(prepared.targetSnapshot);
    await _admissions.publishHistoryConversion(prepared);
  }

  Future<void> requireHistoryConversion(
          CatalogHistoryRootConversion conversion) =>
      _admissions.requireHistoryConversion(conversion, limits);

  Future<bool> prepareLocalEditing() =>
      _gateway.withExclusiveWriteLock(() async {
        final root = await _readHead();
        if (root == null) {
          throw const CatalogStorageException(
              'catalog.missing', 'There is no catalog generation.');
        }
        final snapshot = (await _openRoot(root)).snapshot;
        try {
          await restoreIndexAdmission(snapshot);
          return false;
        } on CatalogStorageException catch (error) {
          if (error.code != 'catalog.preparation_required') rethrow;
        }
        await snapshot.validate();
        await publishIndexAdmissionUnderLock(snapshot);
        return true;
      });

  Future<String?> readProjectId() async {
    const path = 'catalog/IDENTITY.json';
    if (!await _requireLocalPath(path, allowMissing: true)) return null;
    final bytes = await _readBounded(path, 4096);
    final source = utf8.decode(bytes);
    final value = jsonDecode(source);
    if (value is! Map<String, dynamic> ||
        value.length != 2 ||
        value['schemaVersion'] is! int ||
        value['schemaVersion'] != 1 ||
        value['projectId'] is! String ||
        canonicalAuthoringJson(value) != source) {
      throw const FormatException('catalog.identity: invalid record');
    }
    return value['projectId']! as String;
  }

  Future<List<int>> readObject(CatalogObjectReference reference) =>
      _readBounded(_objectPath(reference.sha256), reference.byteLength);

  Future<PublishedCatalogSnapshot> openRoot(CatalogObjectReference root,
          {CatalogObjectReader? readObject}) =>
      _openRoot(root, readObject: readObject);

  Future<void> publishObjectsUnderLock(Map<String, List<int>> objects) async {
    for (final entry in objects.entries) {
      _requireDigest(entry.key);
      if (_sha256(entry.value) != entry.key) {
        throw const CatalogStorageException('catalog.build_corrupt',
            'A prepared object does not match its content address.');
      }
    }
    final operationId = _operationId();
    try {
      for (final entry in objects.entries) {
        final path = _objectPath(entry.key);
        final existing = await _gateway.readResourceRevision(path);
        if (existing == null) {
          await _gateway.stagePayload(
              operationId: operationId,
              storageKey: path,
              kind: TransactionPayloadKind.after,
              bytes: entry.value);
          await _gateway.promoteStaged(
              operationId: operationId,
              storageKey: path,
              kind: TransactionPayloadKind.after,
              expectedCurrentRevision: null);
        }
        final bytes = await _readBounded(path, entry.value.length);
        if (_sha256(bytes) != entry.key) {
          throw const CatalogStorageException('catalog.object_corrupt',
              'A published catalog object failed verification.');
        }
        await _gateway.deleteTransaction(operationId);
      }
    } finally {
      await _gateway.deleteTransaction(operationId);
    }
  }

  Future<PublishedCatalogSnapshot> publish(
    CatalogStorageBuild build, {
    required String? expectedRootRevision,
  }) async {
    final prepared = await CatalogSnapshot.open(
      root: build.root,
      readObject: (reference) async {
        final bytes = build.objects[reference.sha256];
        if (bytes == null) {
          throw const CatalogStorageException('catalog.build_incomplete',
              'The prepared generation is missing a required object.');
        }
        return bytes;
      },
      limits: _limits,
    );
    await prepared.validate();
    for (final entry in build.objects.entries) {
      _requireDigest(entry.key);
      if (_sha256(entry.value) != entry.key) {
        throw const CatalogStorageException('catalog.build_corrupt',
            'A prepared object does not match its content address.');
      }
    }
    return _gateway.withExclusiveWriteLock(() async {
      if (await _requireLocalPath('catalog/IDENTITY.json',
          allowMissing: true)) {
        throw const CatalogStorageException('catalog.editing_required',
            'Managed catalogs must be changed through an editing transaction.');
      }
      for (final journal in await _gateway.listJournals()) {
        if (journal.entries
            .any((entry) => entry.storageKey == headStorageKey)) {
          throw const CatalogStorageException('catalog.recovery_required',
              'Recover the pending catalog transaction before publication.');
        }
      }
      final previous = await _readHead();
      if (previous?.sha256 != expectedRootRevision) {
        throw const CatalogStorageException('catalog.revision_conflict',
            'The catalog generation changed before publication.');
      }
      final headRevision = await _gateway.readResourceRevision(headStorageKey);
      final observedRevision = previous == null
          ? null
          : computeAuthoringBytesFingerprint(_headBytes(previous),
              logicalName: headStorageKey);
      if (headRevision != observedRevision) {
        throw const CatalogStorageException('catalog.revision_conflict',
            'The catalog head changed during publication admission.');
      }
      final operationId = _operationId();
      try {
        for (final entry in build.objects.entries) {
          final path = _objectPath(entry.key);
          final existing = await _gateway.readResourceRevision(path);
          if (existing != null) {
            final bytes = await _readBounded(path, entry.value.length);
            if (_sha256(bytes) != entry.key) {
              throw const CatalogStorageException('catalog.object_corrupt',
                  'An existing catalog object failed verification.');
            }
            continue;
          }
          await _gateway.stagePayload(
              operationId: operationId,
              storageKey: path,
              kind: TransactionPayloadKind.after,
              bytes: entry.value);
          await _gateway.promoteStaged(
              operationId: operationId,
              storageKey: path,
              kind: TransactionPayloadKind.after,
              expectedCurrentRevision: null);
          final bytes = await _readBounded(path, entry.value.length);
          if (_sha256(bytes) != entry.key) {
            throw const CatalogStorageException('catalog.object_corrupt',
                'A published catalog object failed verification.');
          }
          await _gateway.deleteTransaction(operationId);
        }
        final published = await _openRoot(build.root);
        await published.snapshot.validate();
        await publishIndexAdmissionUnderLock(published.snapshot);
        final head = _headBytes(build.root);
        if (head.length > maximumHeadBytes) {
          throw const CatalogStorageException(
              'catalog.head_invalid', 'The catalog head exceeds its limit.');
        }
        await _gateway.stagePayload(
            operationId: operationId,
            storageKey: headStorageKey,
            kind: TransactionPayloadKind.after,
            bytes: head);
        await _gateway.promoteStaged(
            operationId: operationId,
            storageKey: headStorageKey,
            kind: TransactionPayloadKind.after,
            expectedCurrentRevision: headRevision);
        return published;
      } finally {
        await _gateway.deleteTransaction(operationId);
      }
    });
  }

  Future<PublishedCatalogSnapshot> _openRoot(CatalogObjectReference root,
          {CatalogObjectReader? readObject}) async =>
      PublishedCatalogSnapshot(
        rootRevision: root.sha256,
        snapshot: await CatalogSnapshot.open(
          root: root,
          readObject: readObject ??
              (reference) => _readBounded(
                  _objectPath(reference.sha256), reference.byteLength),
          limits: _limits,
        ),
      );

  Future<CatalogObjectReference?> _readHead() async {
    if (!await _requireLocalPath(headStorageKey, allowMissing: true)) {
      return null;
    }
    final reader = _reader;
    if (reader is! ProjectResourceProbeReader) {
      throw const CatalogStorageException('catalog.probe_required',
          'Catalog storage requires a resource probe reader.');
    }
    final root = await _canonicalProjectRoot;
    final probe = await (reader as ProjectResourceProbeReader)
        .probeResource(projectRoot: root, relativePath: headStorageKey);
    if (probe.status == ProjectResourceProbeStatus.missing) return null;
    if (probe.status != ProjectResourceProbeStatus.exists) {
      throw const CatalogStorageException('catalog.head_unavailable',
          'The catalog head is unavailable or unsafe.');
    }
    if (probe.identity!.byteLength > maximumHeadBytes) {
      throw const CatalogStorageException(
          'catalog.read_limit', 'The catalog head exceeds its read limit.');
    }
    final bytes = await _readBounded(headStorageKey, maximumHeadBytes);
    try {
      final decoded = jsonDecode(utf8.decode(bytes));
      if (decoded is! Map ||
          decoded.length != 2 ||
          decoded['schemaVersion'] is! int ||
          decoded['schemaVersion'] != 1 ||
          decoded['root'] is! Map) {
        throw const FormatException();
      }
      final root = CatalogObjectReference.fromJson(
          Map<String, dynamic>.from(decoded['root'] as Map));
      _requireDigest(root.sha256);
      final canonical = _headBytes(root);
      if (bytes.length != canonical.length) {
        throw const FormatException();
      }
      for (var index = 0; index < bytes.length; index++) {
        if (bytes[index] != canonical[index]) throw const FormatException();
      }
      return root;
    } on Object {
      throw const CatalogStorageException(
          'catalog.head_invalid', 'The catalog head is invalid.');
    }
  }

  Future<List<int>> _readBounded(String path, int maximumBytes) async {
    await _requireLocalPath(path);
    if (maximumBytes <= 0) {
      throw const CatalogStorageException(
          'catalog.read_limit', 'The requested catalog read limit is invalid.');
    }
    final reader = _reader;
    if (reader is! ProjectResourceStreamReader ||
        !(reader as ProjectResourceStreamReader).supportsStreamingResources) {
      throw const CatalogStorageException('catalog.streaming_required',
          'Catalog storage requires a bounded streaming resource reader.');
    }
    final bytes = BytesBuilder(copy: false);
    final root = await _canonicalProjectRoot;
    await for (final chunk in (reader as ProjectResourceStreamReader)
        .openRead(projectRoot: root, relativePath: path)) {
      if (bytes.length + chunk.length > maximumBytes) {
        throw const CatalogStorageException(
            'catalog.read_limit', 'A catalog resource exceeds its read limit.');
      }
      bytes.add(chunk);
    }
    return bytes.takeBytes();
  }

  Future<bool> _requireLocalPath(String path,
      {bool allowMissing = false}) async {
    var current = await _canonicalProjectRoot;
    final segments = path.split('/');
    for (var index = 0; index < segments.length; index++) {
      current = '$current${Platform.pathSeparator}${segments[index]}';
      final type = await FileSystemEntity.type(current, followLinks: false);
      if (type == FileSystemEntityType.notFound && allowMissing) return false;
      final expected = index == segments.length - 1
          ? FileSystemEntityType.file
          : FileSystemEntityType.directory;
      if (type != expected) {
        throw CatalogStorageException(
            path == headStorageKey
                ? 'catalog.head_unavailable'
                : 'catalog.object_unavailable',
            'A catalog resource is unavailable or is not a safe regular path.');
      }
    }
    return true;
  }
}

String _objectPath(String digest) {
  _requireDigest(digest);
  return 'catalog/objects/$digest.json';
}

void _requireDigest(String digest) {
  if (!RegExp(r'^[a-f0-9]{64}$').hasMatch(digest)) {
    throw const CatalogStorageException(
        'catalog.digest_invalid', 'A catalog content address is invalid.');
  }
}

String _sha256(List<int> bytes) => crypto.sha256.convert(bytes).toString();

List<int> _headBytes(CatalogObjectReference root) => utf8.encode(jsonEncode({
      'schemaVersion': 1,
      'root': root.toJson(),
    }));

String _operationId() {
  final random = Random.secure();
  final token = List.generate(
      16, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
  return 'catalog-$token';
}
