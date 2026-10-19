import '../transactions/local_authoring_payload.dart';
import 'dart:async';
import 'dart:io';

import '../transactions/authoring_payload.dart';

final class AuthoringContentBlobStoreException implements Exception {
  const AuthoringContentBlobStoreException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => 'AuthoringContentBlobStoreException($code): $message';
}

final class AuthoringContentBlobRef {
  AuthoringContentBlobRef({required String id, required this.byteLength})
      : id = _blobId(id) {
    if (byteLength < 0) {
      throw ArgumentError.value(byteLength, 'byteLength', 'must be >= 0');
    }
  }

  final String id;
  final int byteLength;
}

abstract interface class AuthoringContentBlobStore {
  Future<AuthoringContentBlobRef> put(Iterable<int> bytes);

  Future<AuthoringPayload?> get(String id);

  Future<bool> contains(String id);

  Future<List<String>> listIds();

  Future<int> prune({required Set<String> retainIds});
}

abstract interface class StreamingAuthoringContentBlobStore {
  Future<AuthoringContentBlobRef> putPayload(AuthoringPayload payload);
  Future<AuthoringPayload?> capturePayload(String id,
      {required String storageKey});
}

extension AuthoringPayloadBlobStore on AuthoringContentBlobStore {
  Future<AuthoringContentBlobRef> putPayload(AuthoringPayload payload) {
    final store = this;
    if (store is StreamingAuthoringContentBlobStore) {
      return (store as StreamingAuthoringContentBlobStore).putPayload(payload);
    }
    return put(payload.inlineBytes);
  }

  Future<AuthoringPayload?> capturePayload(String id,
      {required String storageKey}) async {
    final store = this;
    if (store is StreamingAuthoringContentBlobStore) {
      return (store as StreamingAuthoringContentBlobStore)
          .capturePayload(id, storageKey: storageKey);
    }
    throw const AuthoringContentBlobStoreException('history.streaming_required',
        'The history store cannot restore a bounded payload.');
  }
}

/// Content-addressed retained payloads shared by history entries.
final class FileAuthoringContentBlobStore
    implements AuthoringContentBlobStore, StreamingAuthoringContentBlobStore {
  FileAuthoringContentBlobStore._(this._projectRoot);

  static Future<FileAuthoringContentBlobStore> open({
    required String projectRoot,
  }) async {
    try {
      final directory = Directory(projectRoot);
      if ((await directory.stat()).type != FileSystemEntityType.directory) {
        throw const AuthoringContentBlobStoreException(
          'history.blob_project_required',
          'The history blob project root is not a directory.',
        );
      }
      return FileAuthoringContentBlobStore._(
        await directory.resolveSymbolicLinks(),
      );
    } on AuthoringContentBlobStoreException {
      rethrow;
    } on Object {
      throw const AuthoringContentBlobStoreException(
        'history.blob_project_unavailable',
        'The history blob project root is unavailable.',
      );
    }
  }

  final String _projectRoot;

  static final Map<String, Future<void>> _inProcessLocks = {};

  @override
  Future<AuthoringContentBlobRef> put(Iterable<int> values) => putPayload(
      AuthoringPayload.inline(values, storageKey: 'authoring-history-blob'));

  @override
  Future<AuthoringContentBlobRef> putPayload(AuthoringPayload payload) =>
      _guard(() async {
        final inspection = await inspectAuthoringPayload(payload.openRead(),
            storageKey: 'authoring-history-blob',
            byteLength: payload.byteLength);
        final id = inspection.resourceRevision;
        return _withLock(() async {
          final file = await _blobFile(id);
          if (await file.exists()) {
            await _verifyBlob(file, id);
            return AuthoringContentBlobRef(
                id: id, byteLength: payload.byteLength);
          }
          final temporary = File('${file.path}.tmp');
          try {
            final writer = await temporary.open(mode: FileMode.write);
            try {
              await for (final chunk in payload.openRead()) {
                await writer.writeFrom(chunk);
              }
              await writer.flush();
            } finally {
              await writer.close();
            }
            await _verifyBlob(temporary, id);
            await temporary.rename(file.path);
          } finally {
            if (await temporary.exists()) await temporary.delete();
          }
          return AuthoringContentBlobRef(
              id: id, byteLength: payload.byteLength);
        });
      });

  @override
  Future<AuthoringPayload?> get(String id) => _guard(() => _withLock(() async {
        final file = await _blobFile(_blobId(id));
        if (!await file.exists()) return null;
        final observed = await _verifyBlob(file, id);
        return AuthoringPayload.verifiedSource(
            storageKey: 'authoring-history-blob',
            byteLength: observed.byteLength,
            rawSha256: observed.rawSha256,
            resourceRevision: id,
            openRead: file.openRead);
      }));

  @override
  Future<AuthoringPayload?> capturePayload(String id,
          {required String storageKey}) =>
      _guard(() => _withLock(() async {
            final file = await _blobFile(_blobId(id));
            if (!await file.exists()) return null;
            final observed = await _verifyBlob(file, id);
            return captureAuthoringPayload(
                storageKey: storageKey,
                chunks: file.openRead(),
                byteLength: observed.byteLength);
          }));

  @override
  Future<bool> contains(String id) => _guard(() => _withLock(() async {
        final file = await _blobFile(_blobId(id));
        if (!await file.exists()) return false;
        await _verifyBlob(file, id);
        return true;
      }));

  Future<AuthoringPayloadInspection> _verifyBlob(File file, String id) async {
    for (var attempt = 0; attempt < 2; attempt++) {
      final before = await file.stat();
      final observed = await inspectAuthoringPayload(file.openRead(),
          storageKey: 'authoring-history-blob', byteLength: before.size);
      final after = await file.stat();
      if (observed.resourceRevision != id ||
          before.type != FileSystemEntityType.file ||
          after.type != FileSystemEntityType.file ||
          before.size != after.size ||
          before.modified != after.modified) {
        break;
      }
      if (before.changed == after.changed) return observed;
    }
    throw const AuthoringContentBlobStoreException('history.blob_corrupt',
        'A retained history blob failed verification.');
  }

  @override
  Future<List<String>> listIds() {
    return _guard(() async {
      return _withLock(() async {
        final root = await _blobRoot();
        final ids = <String>[];
        await for (final entity in root.list(followLinks: false)) {
          if (entity is! File || !entity.path.endsWith('.blob')) {
            throw const AuthoringContentBlobStoreException(
              'history.blob_path_invalid',
              'The history blob directory contains an unsafe entry.',
            );
          }
          final name = entity.uri.pathSegments.last;
          ids.add(_blobId('sha256:${name.substring(0, name.length - 5)}'));
        }
        ids.sort();
        return List.unmodifiable(ids);
      });
    });
  }

  @override
  Future<int> prune({required Set<String> retainIds}) {
    final retained = retainIds.map(_blobId).toSet();
    return _guard(() async {
      return _withLock(() async {
        final root = await _blobRoot();
        var removed = 0;
        await for (final entity in root.list(followLinks: false)) {
          if (entity is! File || !entity.path.endsWith('.blob')) continue;
          final name = entity.uri.pathSegments.last;
          final id = _blobId('sha256:${name.substring(0, name.length - 5)}');
          if (!retained.contains(id)) {
            await entity.delete();
            removed++;
          }
        }
        return removed;
      });
    });
  }

  Future<File> _blobFile(String id) async {
    final root = await _blobRoot();
    final file = File(_join(root.path, '${id.substring(7)}.blob'));
    final type = await FileSystemEntity.type(file.path, followLinks: false);
    if (type != FileSystemEntityType.notFound &&
        type != FileSystemEntityType.file) {
      throw const AuthoringContentBlobStoreException(
        'history.blob_path_invalid',
        'A retained history blob path is unsafe.',
      );
    }
    return file;
  }

  Future<Directory> _blobRoot() async {
    var current = Directory(_projectRoot);
    for (final segment in const ['.pokemap', 'authoring', 'blobs']) {
      final next = Directory(_join(current.path, segment));
      final type = await FileSystemEntity.type(next.path, followLinks: false);
      if (type == FileSystemEntityType.notFound) {
        await next.create();
      } else if (type != FileSystemEntityType.directory) {
        throw const AuthoringContentBlobStoreException(
          'history.blob_path_invalid',
          'The history blob directory is unsafe.',
        );
      }
      current = next;
    }
    return current;
  }

  Future<T> _withLock<T>(Future<T> Function() operation) async {
    final previous = _inProcessLocks[_projectRoot] ?? Future<void>.value();
    final completion = Completer<void>();
    _inProcessLocks[_projectRoot] = completion.future;
    await previous;
    try {
      late final RandomAccessFile lock;
      try {
        final authoringRoot = (await _blobRoot()).parent;
        lock = await File(_join(authoringRoot.path, 'blobs.lock')).open(
          mode: FileMode.append,
        );
        await lock.lock(FileLock.exclusive);
      } on AuthoringContentBlobStoreException {
        rethrow;
      } on Object {
        throw const AuthoringContentBlobStoreException(
          'history.blob_io',
          'The history blob lock failed safely.',
        );
      }
      try {
        return await operation();
      } finally {
        try {
          await lock.unlock();
        } on Object {
          // Closing still releases the OS lock.
        }
        await lock.close();
      }
    } finally {
      completion.complete();
      if (identical(_inProcessLocks[_projectRoot], completion.future)) {
        _inProcessLocks.remove(_projectRoot);
      }
    }
  }

  Future<T> _guard<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } on AuthoringContentBlobStoreException {
      rethrow;
    } on Object {
      throw const AuthoringContentBlobStoreException(
        'history.blob_io',
        'The history blob store failed safely.',
      );
    }
  }
}

String _blobId(String value) {
  if (!RegExp(r'^sha256:[0-9a-f]{64}$').hasMatch(value)) {
    throw ArgumentError.value(value, 'id', 'must be a SHA-256 blob identity');
  }
  return value;
}

String _join(String first, String second) =>
    [first, second].join(Platform.pathSeparator);
