import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:map_authoring/map_authoring_api.dart';
import 'package:test/test.dart';

const _path = 'assets/été灯😀.bin';
const _types = [
  'uint8',
  'uint8-unmodifiable',
  'uint8-view',
  'list',
  'int8',
  'uint16'
];

void main() {
  for (final size in [17, 256 << 10]) {
    for (final type in _types) {
      test(
          'payload byte types keep all digest namespaces type=$type size=$size',
          () async {
        final bytes = _bytes(size);
        final source = _typed(type, bytes);
        final expected = _oracle(bytes);
        expect(
            await inspectAuthoringPayload(Stream.value(source),
                storageKey: _path, byteLength: size),
            expected);
        expect(
            await inspectAuthoringResourceRevision(Stream.value(source),
                storageKey: _path, byteLength: size),
            (resourceRevision: expected.resourceRevision, byteLength: size));
        final stored = await _stored(bytes, () => source);
        try {
          expect(await stored.readBytes(), bytes);
          expect(stored.rawSha256, expected.rawSha256);
          expect(stored.resourceRevision, expected.resourceRevision);
          expect(stored.contentDigest, expected.contentDigest);
        } finally {
          await stored.release();
        }
      });
    }

    for (final entry in [
      ('list', -1),
      ('list', 256),
      ('int8', -1),
      ('uint16', 256)
    ]) {
      final (type, invalid) = entry;
      test('non uint8 byte range rejects $invalid type=$type size=$size',
          () async {
        final bytes = _bytes(size);
        final source = _typed(type, bytes);
        source[size - 1] = invalid;
        for (final kind in ['revision', 'payload']) {
          await expectLater(_inspect(kind, source, size), throwsA(_mismatch));
        }
        List<int> current = bytes;
        final stored = await _stored(bytes, () => current);
        try {
          current = source;
          await expectLater(stored.readBytes(), throwsA(_mismatch));
          current = bytes;
          expect(await stored.readBytes(), bytes);
        } finally {
          await stored.release();
        }
      });
    }

    for (final type in ['uint8', 'list']) {
      for (final delta in [-1, 1]) {
        test('byte length remains checked type=$type delta=$delta size=$size',
            () async {
          final bytes = _bytes(size);
          final source = _typed(type, _bytes(size + delta));
          for (final kind in ['revision', 'payload']) {
            await expectLater(_inspect(kind, source, size), throwsA(_mismatch));
          }
          List<int> current = bytes;
          final stored = await _stored(bytes, () => current);
          final identities =
              (stored.rawSha256, stored.resourceRevision, stored.contentDigest);
          try {
            current = source;
            await expectLater(stored.readBytes(), throwsA(_mismatch));
            expect((
              stored.rawSha256,
              stored.resourceRevision,
              stored.contentDigest
            ), identities);
          } finally {
            await stored.release();
          }
        });
      }
    }

    for (final overflow in [false, true]) {
      test(
          'custom byte callback retains error identity and length precedence overflow=$overflow size=$size',
          () async {
        final failure = StateError('custom getter');
        for (final kind in ['revision', 'payload']) {
          final source = _ThrowingBytes(size + (overflow ? 1 : 0), failure);
          final workerCopyRunsFirst = size >= 256 << 10;
          final shouldRead = !overflow || workerCopyRunsFirst;
          await expectLater(_inspect(kind, source, size),
              throwsA(shouldRead ? same(failure) : _mismatch));
          expect(source.reads, shouldRead ? 1 : 0);
        }
        final bytes = _bytes(size);
        List<int> current = bytes;
        final stored = await _stored(bytes, () => current);
        final source = _ThrowingBytes(size + (overflow ? 1 : 0), failure);
        try {
          current = source;
          await expectLater(stored.readBytes(),
              throwsA(overflow ? _mismatch : same(failure)));
          expect(source.reads, overflow ? 0 : 1);
        } finally {
          await stored.release();
        }
      });
    }

    for (final type in ['uint8', 'uint8-unmodifiable', 'uint8-view']) {
      test(
          'uint8 range does not grant alias immutability type=$type size=$size',
          () async {
        final bytes = _bytes(size);
        final buffer = Uint8List(size + 6)..setRange(3, size + 3, bytes);
        final view = Uint8List.sublistView(buffer, 3, size + 3);
        final List<int> source = switch (type) {
          'uint8-unmodifiable' => view.asUnmodifiableView(),
          'uint8-view' => view,
          _ => buffer.buffer.asUint8List(3, size),
        };
        final stored = await _stored(bytes, () => source);
        final identities =
            (stored.rawSha256, stored.resourceRevision, stored.contentDigest);
        try {
          buffer[3] ^= 1;
          await expectLater(
              stored.readBytes(),
              throwsA(isA<AuthoringPayloadException>().having(
                  (error) => error.code, 'code', 'payload.source_mismatch')));
          expect(
              (stored.rawSha256, stored.resourceRevision, stored.contentDigest),
              identities);
          buffer[3] ^= 1;
          expect(await stored.readBytes(), bytes);
        } finally {
          await stored.release();
        }
      });
    }
  }
}

Future<Object> _inspect(String kind, List<int> bytes, int length) async {
  if (kind == 'revision') {
    return inspectAuthoringResourceRevision(Stream.value(bytes),
        storageKey: _path, byteLength: length);
  }
  return inspectAuthoringPayload(Stream.value(bytes),
      storageKey: _path, byteLength: length);
}

Future<AuthoringPayload> _stored(
        Uint8List original, List<int> Function() source) =>
    AuthoringPayload.verifiedSource(
        storageKey: _path,
        byteLength: original.length,
        rawSha256: sha256.convert(original).toString(),
        openRead: () => Stream.value(source()));

Uint8List _bytes(int length) =>
    Uint8List.fromList(List.generate(length, (i) => i % 127));

List<int> _typed(String type, Uint8List bytes) => switch (type) {
      'uint8' => bytes,
      'uint8-unmodifiable' => bytes.asUnmodifiableView(),
      'uint8-view' => Uint8List.sublistView(
          Uint8List(bytes.length + 6)..setRange(3, bytes.length + 3, bytes),
          3,
          bytes.length + 3),
      'list' => bytes.toList(),
      'int8' => Int8List.fromList(bytes),
      'uint16' => Uint16List.fromList(bytes),
      _ => throw StateError('Unknown byte type'),
    };

AuthoringPayloadInspection _oracle(Uint8List bytes) => (
      rawSha256: sha256.convert(bytes).toString(),
      resourceRevision: _framed(bytes, _path),
      contentDigest: _framed(bytes, 'artifact-content'),
      byteLength: bytes.length,
    );

String _framed(Uint8List bytes, String path) {
  final encoded = utf8.encode(path);
  final framed = BytesBuilder(copy: false)
    ..add((ByteData(8)..setUint64(0, encoded.length, Endian.big))
        .buffer
        .asUint8List())
    ..add(encoded)
    ..add((ByteData(8)..setUint64(0, bytes.length, Endian.big))
        .buffer
        .asUint8List())
    ..add(bytes);
  return 'sha256:${sha256.convert(framed.takeBytes())}';
}

final _mismatch = isA<AuthoringPayloadException>()
    .having((error) => error.code, 'code', 'payload.length_mismatch');

final class _ThrowingBytes extends ListBase<int> {
  _ThrowingBytes(this.count, this.failure);
  final int count;
  final Object failure;
  var reads = 0;
  @override
  int get length => count;
  @override
  set length(int value) => throw UnsupportedError('read only');
  @override
  int operator [](int index) {
    reads++;
    throw failure;
  }

  @override
  void operator []=(int index, int value) =>
      throw UnsupportedError('read only');
}
