import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:map_core/map_core_domain.dart';

import '../ports/file_backed_payload_store.dart';
import '../support/authoring_fingerprint.dart';

final class AuthoringPayloadException implements Exception {
  const AuthoringPayloadException(this.code, this.message);
  final String code;
  final String message;
  @override
  String toString() => 'AuthoringPayloadException($code): $message';
}

sealed class AuthoringPayload {
  const AuthoringPayload();

  factory AuthoringPayload.inline(Iterable<int> values,
      {required String storageKey}) {
    final source = values.toList(growable: false);
    final bytes = Uint8List.fromList(source);
    if (source.any((value) => value < 0 || value > 255)) {
      throw ArgumentError.value(values, 'values', 'must contain bytes');
    }
    return _InlineAuthoringPayload(bytes.asUnmodifiableView(), storageKey);
  }

  static Future<AuthoringPayload> stored({
    required FileBackedPayloadStore store,
    required FileBackedPayloadScope scope,
    required StoredFilePayload payload,
    required String storageKey,
    String? resourceRevision,
    Future<void> Function()? release,
  }) async {
    FileBackedPayloadLease? lease;
    final stored = await verifiedSource(
      storageKey: storageKey,
      byteLength: payload.byteLength,
      rawSha256: payload.rawSha256,
      resourceRevision: resourceRevision,
      release: () async {
        final owned = lease;
        if (owned != null) {
          await store.release(scope: scope, leaseId: owned.leaseId);
        }
        await release?.call();
      },
      openRead: () {
        late final StreamController<List<int>> controller;
        controller = StreamController<List<int>>(onListen: () async {
          try {
            await store.withSource<void>(
                scope: scope,
                handle: payload.handle,
                read: (source) async {
                  Stream<List<int>> chunks() async* {
                    for (var offset = 0;
                        offset < source.length;
                        offset += chunkSize) {
                      yield source.readAtSync(
                          offset, min(chunkSize, source.length - offset));
                    }
                  }

                  await controller.addStream(chunks());
                });
          } on Object catch (error, stack) {
            controller.addError(error, stack);
          } finally {
            await controller.close();
          }
        });
        return controller.stream;
      },
    );
    try {
      lease = await store.retain(
          scope: scope,
          handle: payload.handle,
          purpose: FileBackedPayloadPurpose.plan);
      return stored;
    } on Object {
      await stored.release();
      rethrow;
    }
  }

  static Future<AuthoringPayload> verifiedSource({
    required String storageKey,
    required int byteLength,
    required String rawSha256,
    required Stream<List<int>> Function() openRead,
    String? resourceRevision,
    Future<void> Function()? release,
  }) async {
    final observed = await inspectAuthoringPayload(openRead(),
        storageKey: storageKey, byteLength: byteLength);
    if (observed.rawSha256 != rawSha256 ||
        (resourceRevision != null &&
            resourceRevision != observed.resourceRevision)) {
      throw const AuthoringPayloadException('payload.source_mismatch',
          'The stored payload failed content verification.');
    }
    return _StoredAuthoringPayload(storageKey, byteLength, rawSha256,
        observed.resourceRevision, observed.contentDigest, openRead, release);
  }

  static const int chunkSize = 64 * 1024;
  static Future<AuthoringPayload> verifiedResource({
    required String storageKey,
    required int byteLength,
    required String resourceRevision,
    required Stream<List<int>> Function() openRead,
  }) async {
    final observed = await inspectAuthoringPayload(openRead(),
        storageKey: storageKey, byteLength: byteLength);
    if (resourceRevision != observed.resourceRevision) {
      throw const AuthoringPayloadException('payload.source_mismatch',
          'The stored payload failed content verification.');
    }
    return _StoredAuthoringPayload(storageKey, byteLength, observed.rawSha256,
        observed.resourceRevision, observed.contentDigest, openRead, null);
  }

  String get storageKey;
  int get byteLength;
  String get rawSha256;
  String get resourceRevision;
  String get contentDigest;
  bool get isInline;
  List<int> get inlineBytes;
  Stream<List<int>> openRead();
  Future<void> release();

  AuthoringPayload checkingPreparation(void Function() check) =>
      _PreparationCheckedPayload(this, check);

  Future<List<int>> readBytes() async {
    final builder = BytesBuilder(copy: false);
    await for (final chunk in openRead()) {
      builder.add(chunk);
    }
    return builder.takeBytes().asUnmodifiableView();
  }
}

final class _InlineAuthoringPayload extends AuthoringPayload {
  _InlineAuthoringPayload(this.inlineBytes, this.storageKey)
      : rawSha256 = sha256.convert(inlineBytes).toString(),
        resourceRevision = computeAuthoringBytesFingerprint(inlineBytes,
            logicalName: storageKey);
  @override
  final List<int> inlineBytes;
  @override
  final String storageKey;
  @override
  final String rawSha256;
  @override
  final String resourceRevision;
  @override
  int get byteLength => inlineBytes.length;
  @override
  String get contentDigest => computeAuthoringBytesFingerprint(inlineBytes,
      logicalName: 'artifact-content');
  @override
  bool get isInline => true;
  @override
  Stream<List<int>> openRead() async* {
    for (var offset = 0;
        offset < inlineBytes.length;
        offset += AuthoringPayload.chunkSize) {
      yield inlineBytes.sublist(
          offset, min(offset + AuthoringPayload.chunkSize, inlineBytes.length));
    }
  }

  @override
  Future<void> release() async {}
}

final class _StoredAuthoringPayload extends AuthoringPayload {
  _StoredAuthoringPayload(this.storageKey, this.byteLength, this.rawSha256,
      this.resourceRevision, this.contentDigest, this._openRead, this._release);
  @override
  final String storageKey;
  @override
  final int byteLength;
  @override
  final String rawSha256;
  @override
  final String resourceRevision;
  @override
  final String contentDigest;
  final Stream<List<int>> Function() _openRead;
  final Future<void> Function()? _release;
  Future<void>? _releaseFuture;
  @override
  bool get isInline => false;
  @override
  List<int> get inlineBytes => throw StateError(
      'Stored payload bytes require an explicit asynchronous read.');
  @override
  Stream<List<int>> openRead() async* {
    if (_releaseFuture != null) {
      throw const AuthoringPayloadException(
          'payload.released', 'The owned payload has been released.');
    }
    final digest = _DigestSink();
    final raw = sha256.startChunkedConversion(digest);
    var length = 0;
    await for (final chunk in _openRead()) {
      length += chunk.length;
      if (length > byteLength ||
          chunk.any((byte) => byte < 0 || byte > 255)) {
        throw const AuthoringPayloadException('payload.length_mismatch',
            'The payload length or byte range is invalid.');
      }
      raw.add(chunk);
      yield chunk;
    }
    if (length != byteLength) {
      throw const AuthoringPayloadException('payload.length_mismatch',
          'The payload length differs from its descriptor.');
    }
    raw.close();
    if (digest.value != rawSha256) {
      throw const AuthoringPayloadException('payload.source_mismatch',
          'The stored payload changed during reading.');
    }
  }

  @override
  Future<void> release() =>
      _releaseFuture ??= Future<void>.sync(() => _release?.call());
}

typedef AuthoringPayloadInspection = ({
  String rawSha256,
  String resourceRevision,
  int byteLength,
  String contentDigest,
});

Future<AuthoringPayloadInspection> inspectAuthoringPayload(
    Stream<List<int>> chunks,
    {required String storageKey,
    required int byteLength}) async {
  if (const bool.fromEnvironment('dart.library.io') &&
      byteLength >= 256 * 1024 &&
      !chunks.isBroadcast) {
    return _inspectAuthoringPayloadInWorker(chunks,
        storageKey: storageKey, byteLength: byteLength);
  }
  final inspection = _PayloadInspection(storageKey, byteLength);
  await for (final chunk in chunks) {
    inspection.add(chunk);
  }
  return inspection.close();
}

var _activePayloadInspectionWorkers = 0;
final _waitingPayloadInspections = <Completer<void>>[];

Future<void> _acquirePayloadInspectionWorker() {
  if (_activePayloadInspectionWorkers < 2) {
    _activePayloadInspectionWorkers++;
    return Future.value();
  }
  final waiting = Completer<void>();
  _waitingPayloadInspections.add(waiting);
  return waiting.future;
}

void _releasePayloadInspectionWorker() {
  if (_waitingPayloadInspections.isNotEmpty) {
    _waitingPayloadInspections.removeAt(0).complete();
  } else {
    _activePayloadInspectionWorkers--;
  }
}

Future<AuthoringPayloadInspection> _inspectAuthoringPayloadInWorker(
  Stream<List<int>> chunks, {
  required String storageKey,
  required int byteLength,
}) async {
  await _acquirePayloadInspectionWorker();
  final replies = ReceivePort();
  final iterator = StreamIterator<Object?>(replies);
  Isolate? worker;
  Future<List<Object?>> next() async {
    if (!await iterator.moveNext()) {
      throw StateError(
          'The payload inspection worker stopped without a result.');
    }
    final value = iterator.current;
    if (value == null) {
      throw StateError(
          'The payload inspection worker exited before completion.');
    }
    if (value is! List || value.isEmpty) {
      throw StateError(
          'The payload inspection worker returned an invalid message.');
    }
    if (value.first == 'error') {
      throw AuthoringPayloadException(value[1] as String, value[2] as String);
    }
    if (value.first == 'argumentError') {
      throw ArgumentError.value(value[1], value[2] as String?, value[3]);
    }
    if (value.length == 2 && value[0] is String && value[1] is String) {
      throw RemoteError(value[0] as String, value[1] as String);
    }
    return value.cast<Object?>();
  }

  try {
    worker = await Isolate.spawn<List<Object?>>(
      _runPayloadInspectionWorker,
      [replies.sendPort, storageKey, byteLength],
      onError: replies.sendPort,
      onExit: replies.sendPort,
      errorsAreFatal: true,
    );
    final ready = await next();
    if (ready.first != 'ready' || ready[1] is! SendPort) {
      throw StateError('The payload inspection worker failed to initialize.');
    }
    final commands = ready[1] as SendPort;
    await for (final chunk in chunks) {
      for (var offset = 0; offset < chunk.length; offset += 128 * 1024) {
        final end = min(offset + 128 * 1024, chunk.length);
        final Uint8List bytes;
        if (chunk is Uint8List) {
          bytes = Uint8List.sublistView(chunk, offset, end);
        } else {
          bytes = Uint8List(end - offset);
          for (var index = offset; index < end; index++) {
            final value = chunk[index];
            if (value < 0 || value > 255) {
              throw const AuthoringPayloadException('payload.length_mismatch',
                  'The payload length or byte range is invalid.');
            }
            bytes[index - offset] = value;
          }
        }
        commands.send([
          'chunk',
          TransferableTypedData.fromList([bytes])
        ]);
        if ((await next()).first != 'ack') {
          throw StateError(
              'The payload inspection worker did not accept a chunk.');
        }
      }
    }
    commands.send(['finish']);
    final result = await next();
    if (result.first != 'done') {
      throw StateError(
          'The payload inspection worker did not return a digest.');
    }
    return (
      rawSha256: result[1] as String,
      resourceRevision: result[2] as String,
      byteLength: result[3] as int,
      contentDigest: result[4] as String,
    );
  } finally {
    worker?.kill(priority: Isolate.immediate);
    replies.close();
    try {
      await iterator.cancel();
    } finally {
      _releasePayloadInspectionWorker();
    }
  }
}

void _runPayloadInspectionWorker(List<Object?> arguments) async {
  final reply = arguments[0] as SendPort;
  final commands = ReceivePort();
  try {
    final inspection =
        _PayloadInspection(arguments[1] as String, arguments[2] as int);
    reply.send(['ready', commands.sendPort]);
    await for (final message in commands) {
      final request = message as List;
      if (request.first == 'chunk') {
        inspection.add(
            (request[1] as TransferableTypedData).materialize().asUint8List());
        reply.send(['ack']);
      } else if (request.first == 'finish') {
        final result = inspection.close();
        reply.send([
          'done',
          result.rawSha256,
          result.resourceRevision,
          result.byteLength,
          result.contentDigest,
        ]);
        return;
      } else {
        throw StateError(
            'The payload inspection worker received an invalid command.');
      }
    }
  } on AuthoringPayloadException catch (failure) {
    reply.send(['error', failure.code, failure.message]);
  } on ArgumentError catch (failure) {
    reply.send([
      'argumentError',
      failure.invalidValue,
      failure.name,
      failure.message,
    ]);
  } finally {
    commands.close();
  }
}

final class _PayloadInspection {
  _PayloadInspection(String storageKey, this.expectedLength) {
    if (expectedLength < 0) {
      throw ArgumentError.value(expectedLength, 'byteLength');
    }
    content.startEntry(
        relativePath: 'artifact-content', byteLength: expectedLength);
    framed.startEntry(relativePath: storageKey, byteLength: expectedLength);
    raw = sha256.startChunkedConversion(digest);
  }
  final int expectedLength;
  final framed = NarrativeProjectFingerprintBuilder();
  final content = NarrativeProjectFingerprintBuilder();
  final digest = _DigestSink();
  late final ByteConversionSink raw;
  var length = 0;
  void add(List<int> bytes) {
    length += bytes.length;
    if (length > expectedLength ||
        bytes.any((byte) => byte < 0 || byte > 255)) {
      throw const AuthoringPayloadException('payload.length_mismatch',
          'The payload length or byte range is invalid.');
    }
    framed.addBytes(bytes);
    content.addBytes(bytes);
    raw.add(bytes);
  }

  AuthoringPayloadInspection close() {
    if (length != expectedLength) {
      throw const AuthoringPayloadException('payload.length_mismatch',
          'The payload length differs from its descriptor.');
    }
    raw.close();
    framed.endEntry();
    content.endEntry();
    return (
      rawSha256: digest.value!,
      resourceRevision: framed.close(),
      byteLength: length,
      contentDigest: content.close(),
    );
  }
}

final class AuthoringPayloadOwner {
  final Set<AuthoringPayload> _payloads = {};
  final List<FutureOr<void> Function()> _cleanups = [];
  Future<void>? _releaseFuture;

  AuthoringPayload own(AuthoringPayload payload) {
    if (_releaseFuture != null) {
      throw StateError('The payload owner has been released.');
    }
    _payloads.add(payload);
    return payload;
  }

  void onRelease(FutureOr<void> Function() cleanup) {
    if (_releaseFuture != null) {
      throw StateError('The payload owner has been released.');
    }
    _cleanups.add(cleanup);
  }

  Future<void> release() => _releaseFuture ??= _releaseOwned();

  Future<void> _releaseOwned() async {
    final payloads = _payloads.toList(growable: false);
    final cleanups = _cleanups.toList(growable: false);
    _payloads.clear();
    _cleanups.clear();
    final results = await Future.wait([
      releaseAuthoringPayloads(payloads)
          .then<Object?>((_) => null, onError: (Object error) => error),
      for (final cleanup in cleanups)
        Future<void>.sync(cleanup)
            .then<Object?>((_) => null, onError: (Object error) => error),
    ]);
    for (final error in results) {
      if (error != null) throw error;
    }
  }
}

Future<void> releaseAuthoringPayloads(
    Iterable<AuthoringPayload?> values) async {
  final payloads = values.whereType<AuthoringPayload>().toSet();
  final results = await Future.wait([
    for (final payload in payloads)
      payload
          .release()
          .then<Object?>((_) => null, onError: (Object error) => error)
  ]);
  for (final error in results) {
    if (error != null) throw error;
  }
}

final class _DigestSink implements Sink<Digest> {
  String? value;
  @override
  void add(Digest data) {
    value = data.toString();
  }

  @override
  void close() {}
}

final class AuthoringPayloadPreparationAborted implements Exception {
  const AuthoringPayloadPreparationAborted();
}

final class _PreparationCheckedPayload extends AuthoringPayload {
  const _PreparationCheckedPayload(this.source, this.check);
  final AuthoringPayload source;
  final void Function() check;
  void _check() {
    try {
      check();
    } on Object {
      throw const AuthoringPayloadPreparationAborted();
    }
  }

  @override
  String get storageKey => source.storageKey;
  @override
  int get byteLength => source.byteLength;
  @override
  String get rawSha256 => source.rawSha256;
  @override
  String get resourceRevision => source.resourceRevision;
  @override
  String get contentDigest => source.contentDigest;
  @override
  bool get isInline => source.isInline;
  @override
  List<int> get inlineBytes {
    _check();
    return source.inlineBytes;
  }

  @override
  Stream<List<int>> openRead() async* {
    _check();
    await for (final chunk in source.openRead()) {
      _check();
      yield chunk;
    }
    _check();
  }

  @override
  Future<void> release() async {}
}
