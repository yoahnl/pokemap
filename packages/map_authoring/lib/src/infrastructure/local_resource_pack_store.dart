import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:path/path.dart' as p;

import '../ports/file_backed_payload_store.dart';
import '../ports/project_file_reader.dart' show workspacePathIsWithin;
import '../support/authoring_performance_observer.dart';

final class LocalResourcePackStore implements FileBackedPayloadStore {
  LocalResourcePackStore({
    required String cacheDirectory,
    required Iterable<String> allowedSourceRoots,
    this.policy = const ResourcePackSecurityPolicy(),
    AuthoringPerformanceObserver? performanceObserver,
    DateTime Function()? clock,
    String Function(String prefix)? tokenFactory,
  })  : _cacheDirectory = p.normalize(p.absolute(cacheDirectory)),
        _allowedSourceRoots = List.unmodifiable(allowedSourceRoots),
        _performanceObserver = performanceObserver,
        _clock = clock ?? DateTime.now,
        _tokenFactory = tokenFactory ?? _randomToken {
    if (_allowedSourceRoots.any((root) => !p.isAbsolute(root))) {
      throw ArgumentError('Allowed source roots must be absolute.');
    }
  }

  final Object _operationZoneKey = Object();
  final ResourcePackSecurityPolicy policy;
  final AuthoringPerformanceObserver? _performanceObserver;
  final String _cacheDirectory;
  final List<String> _allowedSourceRoots;
  final DateTime Function() _clock;
  final String Function(String) _tokenFactory;
  final Set<String> _issuedTokens = {};
  final Map<String, _Entry> _entries = {};
  final Map<String, _Lease> _leases = {};
  final Map<String, _Authorization> _authorized = {};
  Future<Directory>? _privateDirectory;
  int _cachedBytes = 0;
  int _reservedBytes = 0;
  bool _closed = false;
  int _operations = 0;
  Completer<void>? _idle;
  Future<void>? _closing;
  final Set<StreamIterator<List<int>>> _copies = {};
  int get cachedBytes => _cachedBytes;
  int get reservedBytes => _reservedBytes;

  Future<void> authorizeSourceFile(String sourcePath) => _owned(() async {
        _checkOpen();
        final resolved = await _resolve(sourcePath);
        final before = await _stat(resolved);
        _checkSource(before);
        final digest = await _hashFile(resolved, before.size,
            counterName:
                AuthoringPerformanceCounterName.resourcePackAuthorizeReadBytes);
        if (await _resolve(sourcePath) != resolved ||
            !_sameIdentity(before, await _stat(resolved))) {
          _fail('source_changed',
              'The selected source changed during authorization.');
        }
        _checkOpen();
        _authorized[p.normalize(p.absolute(sourcePath))] =
            _Authorization(resolved, before, digest);
      });

  Future<FileBackedPayloadLease> stageFile(
          {required FileBackedPayloadScope scope,
          required String sourcePath,
          void Function()? checkCancelled,
          void Function(int copiedBytes)? onProgress}) =>
      _stageFile(
          scope: scope,
          sourcePath: sourcePath,
          checkCancelled: checkCancelled,
          onProgress: onProgress,
          maximumBytes: policy.maxArchiveBytes,
          requireUtf8: false);

  Future<FileBackedPayloadLease> stageLicenseFile(
          {required FileBackedPayloadScope scope,
          required String sourcePath,
          void Function()? checkCancelled,
          void Function(int copiedBytes)? onProgress}) =>
      _stageFile(
          scope: scope,
          sourcePath: sourcePath,
          checkCancelled: checkCancelled,
          onProgress: onProgress,
          maximumBytes: policy.maxFileBytes,
          requireUtf8: true);

  Future<FileBackedPayloadLease> _stageFile(
          {required FileBackedPayloadScope scope,
          required String sourcePath,
          required int maximumBytes,
          required bool requireUtf8,
          void Function()? checkCancelled,
          void Function(int copiedBytes)? onProgress}) =>
      _owned(() async {
        _checkScope(scope);
        final resolved = await _resolve(sourcePath);
        final authorized = _authorized[p.normalize(p.absolute(sourcePath))];
        if (authorized != null && authorized.resolved != resolved) {
          _fail('source_changed_after_authorization',
              'The selected source now resolves to a different file.');
        }
        var allowed = false;
        for (final root in _allowedSourceRoots) {
          final resolvedRoot = await _resolve(root, directory: true);
          if (workspacePathIsWithin(root: resolvedRoot, candidate: resolved)) {
            allowed = true;
          }
        }
        if (authorized == null && !allowed) {
          _fail('source_outside_allowed_roots',
              'The source is outside the authorized roots.');
        }
        final before = await _stat(resolved);
        _checkSource(before);
        if (before.size > maximumBytes) {
          _fail('too_large',
              'The selected source exceeds its certified file limit.');
        }
        if (authorized != null && !_sameIdentity(authorized.identity, before)) {
          _fail('source_changed_after_authorization',
              'The selected source changed after authorization.');
        }
        FileBackedPayloadLease? lease;
        try {
          var copied = 0;
          Stream<List<int>> chunks() async* {
            final text = requireUtf8
                ? utf8.decoder.startChunkedConversion(const _DiscardUtf8Text())
                : null;
            final reader = await File(resolved).open();
            try {
              while (true) {
                checkCancelled?.call();
                final chunk = await reader.read(policy.maxChunkBytes);
                _observe(
                    AuthoringPerformanceCounterName
                        .resourcePackStageSourceReadBytes,
                    chunk.length);
                if (chunk.isEmpty) {
                  try {
                    text?.close();
                  } on FormatException {
                    _fail('license_invalid_utf8',
                        'A licence must contain strict UTF-8 text.');
                  }
                  break;
                }
                try {
                  text?.add(chunk);
                } on FormatException {
                  _fail('license_invalid_utf8',
                      'A licence must contain strict UTF-8 text.');
                }
                yield chunk;
                copied += chunk.length;
                onProgress?.call(copied);
              }
            } finally {
              await reader.close();
            }
          }

          lease = await stage(
              scope: scope,
              chunks: chunks(),
              byteLength: before.size,
              expectedRawSha256: authorized?.rawSha256,
              checkCancelled: checkCancelled);
          if (await _resolve(sourcePath) != resolved ||
              !_sameIdentity(before, await _stat(resolved)) ||
              await _hashFile(resolved, before.size,
                      counterName: AuthoringPerformanceCounterName
                          .resourcePackPostCopyVerifyReadBytes,
                      checkCancelled: checkCancelled) !=
                  lease.payload.rawSha256 ||
              !_sameIdentity(before, await _stat(resolved)) ||
              await _resolve(sourcePath) != resolved) {
            _fail('source_changed',
                'The source changed while the private snapshot was created.');
          }
          _checkOpen();
          return lease;
        } catch (_) {
          if (lease != null) {
            _leases.remove(lease.leaseId);
            final entry = _entries.remove(lease.payload.handle);
            if (entry != null) {
              _cachedBytes -= entry.payload.byteLength;
              await _delete(entry.file);
            }
          }
          rethrow;
        }
      });

  @override
  Future<FileBackedPayloadLease> stage({
    required FileBackedPayloadScope scope,
    required Stream<List<int>> chunks,
    required int byteLength,
    String? expectedRawSha256,
    void Function()? checkCancelled,
  }) =>
      _owned(() async {
        _checkScope(scope);
        if (byteLength < 0 || byteLength > policy.maxArchiveBytes) {
          _fail('too_large',
              'The staged payload exceeds the configured size limit.');
        }
        if (expectedRawSha256 != null &&
            !RegExp(r'^[a-f0-9]{64}$').hasMatch(expectedRawSha256)) {
          _fail('digest_invalid',
              'A raw SHA-256 must contain 64 lowercase hexadecimal characters.');
        }
        await collectExpired();
        _checkOpen();
        if (_cachedBytes + _reservedBytes + byteLength > policy.maxCacheBytes) {
          _fail('cache_full',
              'The session cache has insufficient unreserved capacity.');
        }
        _reservedBytes += byteLength;
        File? file;
        RandomAccessFile? writer;
        StreamIterator<List<int>>? iterator;
        try {
          checkCancelled?.call();
          final directory =
              await (_privateDirectory ??= _createPrivateDirectory());
          _checkOpen();
          final handle = _token('payload');
          file = File(p.join(directory.path, handle));
          await file.create(exclusive: true);
          writer = await file.open(mode: FileMode.writeOnly);
          final digest = _DigestSink();
          final input = sha256.startChunkedConversion(digest);
          var copied = 0;
          _checkOpen();
          iterator = StreamIterator(chunks);
          _copies.add(iterator);
          while (await iterator.moveNext()) {
            final block = iterator.current;
            for (var offset = 0; offset < block.length;) {
              checkCancelled?.call();
              _checkOpen();
              final take = min(policy.maxChunkBytes, block.length - offset);
              if (copied + take > byteLength) {
                _fail('source_changed',
                    'The source exceeds its reserved byte length.');
              }
              final chunk =
                  Uint8List.fromList(block.sublist(offset, offset + take));
              if (block is! Uint8List &&
                  block.skip(offset).take(take).any((b) => b < 0 || b > 255)) {
                _fail('bytes_invalid',
                    'A payload stream contains invalid bytes.');
              }
              input.add(chunk);
              await writer.writeFrom(chunk);
              _observe(
                  AuthoringPerformanceCounterName
                      .resourcePackStagePrivateCompletedWriteInputBytes,
                  chunk.length);
              copied += take;
              offset += take;
            }
          }
          _checkOpen();
          input.close();
          if (copied != byteLength) {
            _fail('source_changed',
                'The source differs from its reserved byte length.');
          }
          if (expectedRawSha256 != null && digest.value != expectedRawSha256) {
            _fail('hash_mismatch',
                'The source raw digest does not match the expected value.');
          }
          checkCancelled?.call();
          await writer.flush();
          await writer.close();
          writer = null;
          _checkOpen();
          final entry = _Entry(
              scope,
              file,
              StoredFilePayload(
                  handle: handle,
                  byteLength: byteLength,
                  rawSha256: digest.value));
          final lease = _newLease(entry, FileBackedPayloadPurpose.owner);
          _entries[handle] = entry;
          _cachedBytes += byteLength;
          return lease;
        } catch (_) {
          if (writer != null) await writer.close();
          if (file != null) await _delete(file);
          rethrow;
        } finally {
          try {
            if (iterator != null) await iterator.cancel();
          } finally {
            if (iterator != null) _copies.remove(iterator);
            _reservedBytes -= byteLength;
          }
        }
      });

  @override
  Future<FileBackedPayloadLease> retain(
          {required FileBackedPayloadScope scope,
          required String handle,
          FileBackedPayloadPurpose purpose = FileBackedPayloadPurpose.owner}) =>
      _owned(() async {
        await collectExpired();
        return _newLease(_require(scope, handle), purpose);
      });

  FileBackedPayloadLease retainForJob({
    required FileBackedPayloadScope scope,
    required String handle,
  }) => _newLease(_require(scope, handle), FileBackedPayloadPurpose.job);

  @override
  Future<bool> release(
          {required FileBackedPayloadScope scope, required String leaseId}) =>
      _owned(() async {
        _checkScope(scope);
        final lease = _leases[leaseId];
        if (lease == null) return false;
        if (lease.entry.scope != scope) {
          _fail('owner_mismatch',
              'The lease belongs to another session or project.');
        }
        if (!lease.active) return false;
        lease.active = false;
        lease.entry.references--;
        if (lease.entry.references == 0) lease.entry.unreferencedAt = _clock();
        return true;
      });

  @override
  Future<T> withSource<T>(
          {required FileBackedPayloadScope scope,
          required String handle,
          required FutureOr<T> Function(RandomAccessPackageSource source)
              read}) =>
      _owned(() async {
        final entry = _require(scope, handle);
        entry.readers++;
        _OwnedSource? source;
        try {
          final before = await _stat(entry.file.path);
          if (before.type != FileSystemEntityType.file ||
              before.size != entry.payload.byteLength ||
              await entry.file.resolveSymbolicLinks() != entry.file.path ||
              await _hashFile(entry.file.path, entry.payload.byteLength,
                      counterName: AuthoringPerformanceCounterName
                          .resourcePackStageVerifyReadBytes) !=
                  entry.payload.rawSha256) {
            _fail('stage_corrupt',
                'The staged payload no longer matches its verified digest.');
          }
          source = _OwnedSource(entry.file.openSync(), entry.payload.byteLength,
              policy.maxChunkBytes,
              onRead: (length) => _observe(
                  AuthoringPerformanceCounterName
                      .resourcePackConsumerReadAtReturnedBytes,
                  length));
          final result = await read(source);
          if (!_sameIdentity(before, await _stat(entry.file.path))) {
            _fail('stage_corrupt', 'The stage changed while it was read.');
          }
          return result;
        } finally {
          source?.close();
          entry.readers--;
        }
      });

  Future<T> withSourceInIsolate<T>({
    required FileBackedPayloadScope scope,
    required String handle,
    required FutureOr<T> Function(RandomAccessPackageSource source) read,
  }) =>
      _owned(() async {
        final entry = _require(scope, handle);
        entry.readers++;
        try {
          final path = entry.file.path;
          final length = entry.payload.byteLength;
          final digest = entry.payload.rawSha256;
          final chunk = policy.maxChunkBytes;
          late final (T, Map<String, int>) result;
          try {
            result = await _runWorker(path, length, digest, chunk, read,
                _performanceObserver != null);
          } on Object {
            _performanceObserver?.incrementCounter(
                AuthoringPerformanceCounterName
                    .resourcePackWorkerCoverageIncompleteOperations);
            rethrow;
          }
          for (final entry in result.$2.entries) {
            _performanceObserver?.incrementCounter(entry.key, by: entry.value);
          }
          return result.$1;
        } finally {
          entry.readers--;
        }
      });

  Future<T> withSourcesInIsolate<T>({
    required FileBackedPayloadScope scope,
    required Iterable<String> handles,
    required FutureOr<T> Function(Map<String, RandomAccessPackageSource>) read,
  }) =>
      _owned(() async {
        final entries = [
          for (final handle in handles.toSet()) _require(scope, handle),
        ];
        for (final entry in entries) {
          entry.readers++;
        }
        try {
          final descriptors = [
            for (final entry in entries)
              (
                entry.payload.handle,
                entry.file.path,
                entry.payload.byteLength,
                entry.payload.rawSha256,
                policy.maxChunkBytes,
              ),
          ];
          late final (T, Map<String, int>) result;
          try {
            result = await _runSourcesWorker(
                descriptors, read, _performanceObserver != null);
          } on Object {
            _performanceObserver?.incrementCounter(
                AuthoringPerformanceCounterName
                    .resourcePackWorkerCoverageIncompleteOperations);
            rethrow;
          }
          for (final entry in result.$2.entries) {
            _performanceObserver?.incrementCounter(entry.key, by: entry.value);
          }
          return result.$1;
        } finally {
          for (final entry in entries) {
            entry.readers--;
          }
        }
      });

  @override
  Future<void> collectExpired() => _owned(() async {
        final expired = _entries.values
            .where((entry) =>
                entry.references == 0 &&
                entry.readers == 0 &&
                entry.unreferencedAt != null &&
                _clock().difference(entry.unreferencedAt!) >=
                    policy.maxUnreferencedAge)
            .toList();
        for (final entry in expired) {
          if (entry.references != 0 ||
              entry.readers != 0 ||
              _entries[entry.payload.handle] != entry) {
            continue;
          }
          _entries.remove(entry.payload.handle);
          try {
            await _delete(entry.file);
          } catch (_) {
            _entries[entry.payload.handle] = entry;
            rethrow;
          }
          _cachedBytes -= entry.payload.byteLength;
          _leases.removeWhere((_, lease) => lease.entry == entry);
        }
      });

  Future<void> close() {
    if (Zone.current[_operationZoneKey] == this) {
      _fail('close_reentrant',
          'Close must be called outside owned payload callbacks.');
    }
    _closed = true;
    return _closing ??= _dispose();
  }

  Future<T> _owned<T>(Future<T> Function() operation) async {
    _checkOpen();
    _operations++;
    try {
      return await runZoned(operation, zoneValues: {_operationZoneKey: this});
    } finally {
      _operations--;
      if (_operations == 0) {
        _idle?.complete();
        _idle = null;
      }
    }
  }

  Future<void> _dispose() async {
    try {
      await Future.wait(_copies.toList().map((copy) => copy.cancel()));
    } catch (_) {}
    if (_operations != 0) await (_idle ??= Completer<void>()).future;
    final pendingDirectory = _privateDirectory;
    Directory? directory;
    if (pendingDirectory != null) {
      try {
        directory = await pendingDirectory;
      } catch (_) {}
    }
    if (directory != null && await directory.exists()) {
      if (await FileSystemEntity.type(directory.path, followLinks: false) !=
              FileSystemEntityType.directory ||
          await directory.resolveSymbolicLinks() != directory.path) {
        _fail('cache_invalid',
            'The owned stage directory changed before cleanup.');
      }
      await directory.delete(recursive: true);
    }
    _entries.clear();
    _leases.clear();
    _authorized.clear();
    _issuedTokens.clear();
    _cachedBytes = 0;
    _reservedBytes = 0;
  }

  Future<Directory> _createPrivateDirectory() async {
    final canonical = _canonicalCachePath();
    var ancestor = canonical;
    while (true) {
      if (File(p.join(ancestor, 'project.json')).existsSync()) {
        _fail('cache_inside_project',
            'Private stages must remain outside native project directories.');
      }
      final parent = p.dirname(ancestor);
      if (parent == ancestor) break;
      ancestor = parent;
    }
    final cache = Directory(canonical)..createSync(recursive: true);
    final before = cache.statSync();
    if (FileSystemEntity.typeSync(cache.path, followLinks: false) !=
            FileSystemEntityType.directory ||
        cache.resolveSymbolicLinksSync() != canonical ||
        Directory(_cacheDirectory).resolveSymbolicLinksSync() != canonical ||
        !_sameIdentity(before, cache.statSync())) {
      _fail('cache_invalid',
          'The cache changed while its canonical location was checked.');
    }
    final private = cache.createTempSync('resource-pack-');
    final privateIdentity = private.statSync();
    if (privateIdentity.type != FileSystemEntityType.directory ||
        private.resolveSymbolicLinksSync() != private.path ||
        cache.resolveSymbolicLinksSync() != canonical ||
        Directory(_cacheDirectory).resolveSymbolicLinksSync() != canonical ||
        !_sameIdentity(privateIdentity, private.statSync())) {
      private.deleteSync();
      _fail('cache_invalid',
          'The private stage directory changed during creation.');
    }
    return private;
  }

  String _canonicalCachePath() {
    var ancestor = _cacheDirectory;
    final suffix = <String>[];
    while (FileSystemEntity.typeSync(ancestor, followLinks: false) ==
        FileSystemEntityType.notFound) {
      suffix.insert(0, p.basename(ancestor));
      final parent = p.dirname(ancestor);
      if (parent == ancestor) {
        _fail('cache_invalid', 'A stable cache ancestor is required.');
      }
      ancestor = parent;
    }
    if (ancestor == _cacheDirectory &&
        FileSystemEntity.typeSync(ancestor, followLinks: false) !=
            FileSystemEntityType.directory) {
      _fail('cache_invalid', 'The cache itself must be a regular directory.');
    }
    final directory = Directory(ancestor);
    final resolved = directory.resolveSymbolicLinksSync();
    if (directory.statSync().type != FileSystemEntityType.directory) {
      _fail('cache_invalid',
          'The existing cache ancestor must resolve to a directory.');
    }
    return p.normalize(p.joinAll([resolved, ...suffix]));
  }

  _Entry _require(FileBackedPayloadScope scope, String handle) {
    _checkScope(scope);
    final entry = _entries[handle];
    if (entry == null ||
        entry.references == 0 &&
            entry.readers == 0 &&
            entry.unreferencedAt != null &&
            _clock().difference(entry.unreferencedAt!) >=
                policy.maxUnreferencedAge) {
      _fail('unknown', 'The payload is unknown or expired.');
    }
    if (entry.scope != scope) {
      _fail('owner_mismatch',
          'The payload belongs to another session or project.');
    }
    return entry;
  }

  FileBackedPayloadLease _newLease(
      _Entry entry, FileBackedPayloadPurpose purpose) {
    final id = _token('lease');
    entry.references++;
    entry.unreferencedAt = null;
    _leases[id] = _Lease(entry);
    return FileBackedPayloadLease(
        leaseId: id, payload: entry.payload, purpose: purpose);
  }

  String _token(String prefix) {
    final value = _tokenFactory(prefix);
    if (!RegExp(r'^[a-zA-Z0-9_-]{1,128}$').hasMatch(value) ||
        _entries.containsKey(value) ||
        _leases.containsKey(value) ||
        !_issuedTokens.add(value)) {
      _fail('token_invalid',
          'The opaque handle factory returned an invalid or reused token.');
    }
    return value;
  }

  void _checkOpen() {
    if (_closed) _fail('closed', 'The payload store is closed.');
  }

  void _checkScope(FileBackedPayloadScope scope) {
    _checkOpen();
    if (scope.sessionId.trim().isEmpty || scope.projectId.trim().isEmpty) {
      _fail('owner_invalid',
          'A trusted session and stable project identity are required.');
    }
  }

  void _checkSource(FileStat stat) {
    if (stat.type != FileSystemEntityType.file) {
      _fail('source_not_regular', 'The source must be a regular file.');
    }
    if (stat.size > policy.maxArchiveBytes) {
      _fail('too_large', 'The source exceeds the archive limit.');
    }
  }

  void _observe(String name, int length) {
    if (length > 0) _performanceObserver?.incrementCounter(name, by: length);
  }

  Future<String> _hashFile(String path, int length,
      {required String counterName, void Function()? checkCancelled}) async {
    final reader = await File(path).open();
    final digest = _DigestSink();
    final sink = sha256.startChunkedConversion(digest);
    try {
      var total = 0;
      while (total < length) {
        checkCancelled?.call();
        final bytes =
            await reader.read(min(policy.maxChunkBytes, length - total));
        _observe(counterName, bytes.length);
        if (bytes.isEmpty) {
          _fail('source_changed',
              'The source became shorter during verification.');
        }
        sink.add(bytes);
        total += bytes.length;
      }
      final trailing = await reader.read(1);
      _observe(counterName, trailing.length);
      if (trailing.isNotEmpty) {
        _fail('source_changed', 'The source grew during verification.');
      }
      sink.close();
      return digest.value;
    } finally {
      await reader.close();
    }
  }
}

Future<(T, Map<String, int>)> _runWorker<T>(
  String path,
  int length,
  String digest,
  int chunk,
  FutureOr<T> Function(RandomAccessPackageSource) read,
  bool observeReads,
) =>
    Isolate.run(() async {
      final counters = observeReads ? <String, int>{} : null;
      final value = await _readInWorker(path, length, digest, chunk, read,
          counters: counters);
      return (value, counters ?? const <String, int>{});
    });

Future<T> _readInWorker<T>(
  String path,
  int length,
  String digest,
  int chunk,
  FutureOr<T> Function(RandomAccessPackageSource) read, {
  Map<String, int>? counters,
}) async {
  final file = File(path);
  final before = file.statSync();
  if (before.type != FileSystemEntityType.file ||
      before.size != length ||
      file.resolveSymbolicLinksSync() != path) {
    _fail('stage_corrupt', 'The worker stage is missing or changed.');
  }
  var verifying = true;
  final source = _OwnedSource(file.openSync(), length, chunk,
      onRead: counters == null
          ? null
          : (length) => _workerBytes(
              counters,
              verifying
                  ? AuthoringPerformanceCounterName
                      .resourcePackWorkerVerifyReadBytes
                  : AuthoringPerformanceCounterName
                      .resourcePackWorkerConsumerReadAtReturnedBytes,
              length));
  try {
    final result = _DigestSink();
    final sink = sha256.startChunkedConversion(result);
    for (var offset = 0; offset < length; offset += chunk) {
      sink.add(source.readAtSync(offset, min(chunk, length - offset)));
    }
    sink.close();
    if (result.value != digest) {
      _fail(
          'stage_corrupt', 'The worker stage failed raw digest verification.');
    }
    verifying = false;
    final value = await read(source);
    if (!_sameIdentity(before, file.statSync())) {
      _fail('stage_corrupt', 'The worker stage changed during inspection.');
    }
    return value;
  } finally {
    source.close();
  }
}

void _workerBytes(Map<String, int> counters, String name, int length) {
  if (length > 0) {
    counters.update(name, (value) => value + length, ifAbsent: () => length);
  }
}

final class _Entry {
  _Entry(this.scope, this.file, this.payload);
  final FileBackedPayloadScope scope;
  final File file;
  final StoredFilePayload payload;
  int references = 0;
  int readers = 0;
  DateTime? unreferencedAt;
}

final class _Lease {
  _Lease(this.entry);
  final _Entry entry;
  bool active = true;
}

final class _Authorization {
  _Authorization(this.resolved, this.identity, this.rawSha256);
  final String resolved;
  final FileStat identity;
  final String rawSha256;
}

final class _OwnedSource implements RandomAccessPackageSource {
  _OwnedSource(this.reader, this.length, this.chunkBytes, {this.onRead});
  final RandomAccessFile reader;
  @override
  final int length;
  final int chunkBytes;
  final void Function(int length)? onRead;
  bool closed = false;
  @override
  Uint8List readAtSync(int offset, int length) {
    if (closed ||
        offset < 0 ||
        length < 0 ||
        length > chunkBytes ||
        offset + length > this.length) {
      _fail('read_invalid',
          'The owned source is closed or the read exceeds its bounded range.');
    }
    reader.setPositionSync(offset);
    final bytes = reader.readSync(length);
    onRead?.call(bytes.length);
    if (bytes.length != length) {
      _fail('stage_corrupt', 'The stage changed during reading.');
    }
    return bytes;
  }

  void close() {
    if (!closed) {
      closed = true;
      reader.closeSync();
    }
  }
}

final class _DigestSink implements Sink<Digest> {
  String? _value;
  String get value => _value ?? (throw StateError('Digest unfinished.'));
  @override
  void add(Digest value) {
    _value = value.toString();
  }

  @override
  void close() {}
}

Future<String> _resolve(String path, {bool directory = false}) async {
  if (!p.isAbsolute(path)) {
    _fail('source_invalid', 'Source paths must be absolute.');
  }
  try {
    return directory
        ? await Directory(path).resolveSymbolicLinks()
        : await File(path).resolveSymbolicLinks();
  } on FileSystemException {
    _fail('source_unavailable', 'The source cannot be resolved.');
  }
}

Future<FileStat> _stat(String path) async {
  final stat = await FileStat.stat(path);
  if (stat.type == FileSystemEntityType.notFound) {
    _fail('source_unavailable', 'The source is unavailable.');
  }
  return stat;
}

bool _sameIdentity(FileStat a, FileStat b) =>
    a.type == b.type &&
    a.size == b.size &&
    a.modified == b.modified &&
    a.changed == b.changed;
Future<void> _delete(File file) async {
  if (await file.exists()) await file.delete();
}

String _randomToken(String prefix) {
  final random = Random.secure();
  return '$prefix-${List.generate(24, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0')).join()}';
}

Never _fail(String code, String message) =>
    throw FileBackedPayloadException('resource_pack.$code', message);

Future<(T, Map<String, int>)> _runSourcesWorker<T>(
  List<(String, String, int, String, int)> descriptors,
  FutureOr<T> Function(Map<String, RandomAccessPackageSource>) read,
  bool observeReads,
) =>
    Isolate.run(() async {
      final counters = observeReads ? <String, int>{} : null;
      final sources = <String, RandomAccessPackageSource>{};
      for (final descriptor in descriptors) {
        await _readInWorker(
          descriptor.$2,
          descriptor.$3,
          descriptor.$4,
          descriptor.$5,
          (_) => true,
          counters: counters,
        );
        sources[descriptor.$1] = _WorkerFileSource(
          descriptor.$2,
          descriptor.$3,
          descriptor.$5,
          counters,
        );
      }
      final value = await read(sources);
      for (final descriptor in descriptors) {
        await _readInWorker(
          descriptor.$2,
          descriptor.$3,
          descriptor.$4,
          descriptor.$5,
          (_) => true,
          counters: counters,
        );
      }
      return (value, counters ?? const <String, int>{});
    });

final class _WorkerFileSource implements RandomAccessPackageSource {
  const _WorkerFileSource(
      this.path, this.length, this.chunkBytes, this.counters);
  final String path;
  @override
  final int length;
  final int chunkBytes;
  final Map<String, int>? counters;
  @override
  Uint8List readAtSync(int offset, int count) {
    final source = _OwnedSource(File(path).openSync(), length, chunkBytes,
        onRead: counters == null
            ? null
            : (length) => _workerBytes(
                counters!,
                AuthoringPerformanceCounterName
                    .resourcePackWorkerConsumerReadAtReturnedBytes,
                length));
    try {
      return source.readAtSync(offset, count);
    } finally {
      source.close();
    }
  }
}

final class _DiscardUtf8Text implements Sink<String> {
  const _DiscardUtf8Text();
  @override
  void add(String value) {}
  @override
  void close() {}
}
