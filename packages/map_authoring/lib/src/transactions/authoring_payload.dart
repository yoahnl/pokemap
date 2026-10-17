import 'dart:async';
import 'dart:convert';
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
  String get storageKey;
  int get byteLength;
  String get rawSha256;
  String get resourceRevision;
  String get contentDigest;
  bool get isInline;
  List<int> get inlineBytes;
  Stream<List<int>> openRead();
  Future<void> release();

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
    final inspection = _PayloadInspection(storageKey, byteLength);
    await for (final chunk in _openRead()) {
      inspection.add(chunk);
      yield chunk;
    }
    final observed = inspection.close();
    if (observed.rawSha256 != rawSha256 ||
        observed.resourceRevision != resourceRevision) {
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
  final inspection = _PayloadInspection(storageKey, byteLength);
  await for (final chunk in chunks) {
    inspection.add(chunk);
  }
  return inspection.close();
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
