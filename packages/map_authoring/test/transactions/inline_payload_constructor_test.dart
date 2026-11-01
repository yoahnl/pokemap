import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:map_authoring/map_authoring_api.dart';
import 'package:test/test.dart';

void main() {
  const path = 'maps/été灯😀.json';
  for (final length in [0, 17, 65535, 65536, 65537, 262144, 262145]) {
    for (final typed in [false, true]) {
      test(
          'inline digests retain canonical framing length=$length typed=$typed',
          () {
        final bytes = Uint8List.fromList(
            List.generate(length, (index) => (index * 37) & 255));
        final payload = AuthoringPayload.inline(
            typed ? bytes : _SinglePassBytes(bytes),
            storageKey: path);
        expect(payload.byteLength, length);
        expect(payload.resourceRevision, _framedDigest(bytes, path));
        expect(payload.contentDigest, _framedDigest(bytes, 'artifact-content'));
        final raw = payload.rawSha256;
        expect(raw, sha256.convert(bytes).toString());
        expect(identical(raw, payload.rawSha256), isTrue);
        expect(payload.inlineBytes, bytes);
      });
    }
  }

  for (final offset in [0, 3]) {
    test(
        'typed input is privately copied before first raw digest offset=$offset',
        () async {
      final buffer = Uint8List.fromList(List.generate(20, (index) => index));
      final source = Uint8List.sublistView(buffer, offset, offset + 8);
      final expected = Uint8List.fromList(source);
      final payload = AuthoringPayload.inline(source, storageKey: path);
      buffer.fillRange(0, buffer.length, 255);
      expect(payload.inlineBytes, expected);
      expect(payload.resourceRevision, _framedDigest(expected, path));
      expect(payload.rawSha256, sha256.convert(expected).toString());
      expect(
          payload.contentDigest, _framedDigest(expected, 'artifact-content'));
      expect(await payload.readBytes(), expected);
    });
  }

  final mutations = <String, void Function(Uint8List)>{
    'direct': (bytes) => bytes[0] = 99,
    'unmodifiable view': (bytes) => bytes.asUnmodifiableView()[0] = 99,
    'buffer byte view': (bytes) => bytes.buffer.asUint8List()[0] = 99,
    'buffer signed view': (bytes) => bytes.buffer.asInt8List()[0] = 99,
    'buffer data view': (bytes) => bytes.buffer.asByteData().setUint8(0, 99),
    'typed view': (bytes) =>
        Uint8List.view(bytes.buffer, bytes.offsetInBytes, bytes.length)[0] = 99,
    'typed sublist view': (bytes) => Uint8List.sublistView(bytes)[0] = 99,
  };
  for (final mutation in mutations.entries) {
    test('inline bytes refuse mutation through ${mutation.key}', () {
      final expected = Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8]);
      final payload = AuthoringPayload.inline(expected, storageKey: path);
      expect(() => mutation.value(payload.inlineBytes as Uint8List),
          throwsUnsupportedError);
      expect(payload.inlineBytes, expected);
      expect(payload.resourceRevision, _framedDigest(expected, path));
      expect(payload.rawSha256, sha256.convert(expected).toString());
      expect(
          payload.contentDigest, _framedDigest(expected, 'artifact-content'));
    });
  }

  test('generic source is consumed once and privately frozen', () {
    final bytes = [0, 1, 255];
    final source = _SinglePassBytes(bytes);
    final payload = AuthoringPayload.inline(source, storageKey: path);
    expect(source.iterations, 1);
    bytes[0] = 99;
    expect(payload.inlineBytes, [0, 1, 255]);
    expect(payload.rawSha256, sha256.convert([0, 1, 255]).toString());
    expect(source.iterations, 1);
  });

  for (final invalid in [-1, 256]) {
    test('generic source rejects $invalid without coercion or re-iteration',
        () {
      final source = _SinglePassBytes([0, invalid, 255]);
      expect(
          () => AuthoringPayload.inline(source, storageKey: path),
          throwsA(isA<ArgumentError>()
              .having((error) => error.name, 'name', 'values')
              .having((error) => identical(error.invalidValue, source),
                  'original source', isTrue)));
      expect(source.iterations, 1);
    });
  }

  for (final source in <List<int>>[
    Int8List.fromList([0, -1]),
    Uint16List.fromList([0, 256]),
  ]) {
    test(
        'non Uint8List typed input keeps range validation ${source.runtimeType}',
        () {
      expect(() => AuthoringPayload.inline(source, storageKey: path),
          throwsArgumentError);
    });
  }

  test('generic iteration failures propagate unchanged', () {
    final error = StateError('interrupted source');
    var iterations = 0;
    Iterable<int> source() sync* {
      iterations++;
      yield 0;
      throw error;
    }

    expect(() => AuthoringPayload.inline(source(), storageKey: path),
        throwsA(same(error)));
    expect(iterations, 1);
  });

  test('change construction has its framed revision before raw digest access',
      () {
    final bytes = Uint8List.fromList([0, 1, 255]);
    final payload = AuthoringPayload.inline(bytes, storageKey: path);
    final change = AuthoringResourceChange.withPayloads(
        resource: AuthoringResourceRef(kind: 'map', id: 'map'),
        storageKey: path,
        beforePayload: null,
        afterPayload: payload);
    expect(change.afterRevision, _framedDigest(bytes, path));
    expect(change.toJson()['afterRevision'], _framedDigest(bytes, path));
    expect(change.toJson()['afterByteLength'], bytes.length);
    expect(payload.rawSha256, sha256.convert(bytes).toString());
  });

  test('raw digest rejects dynamic assignment before its first read', () {
    final bytes = Uint8List.fromList([0, 1, 255]);
    final payload = AuthoringPayload.inline(bytes, storageKey: path);
    expect(() => (payload as dynamic).rawSha256 = 'forged',
        throwsNoSuchMethodError);
    expect(payload.rawSha256, sha256.convert(bytes).toString());
  });
}

final class _SinglePassBytes extends IterableBase<int> {
  _SinglePassBytes(this.values);

  final List<int> values;
  int iterations = 0;

  @override
  Iterator<int> get iterator {
    iterations++;
    if (iterations != 1) {
      throw StateError('The source was consumed twice.');
    }
    return values.iterator;
  }
}

String _framedDigest(List<int> bytes, String path) {
  final pathBytes = utf8.encode(path);
  final pathLength = ByteData(8)..setUint64(0, pathBytes.length, Endian.big);
  final contentLength = ByteData(8)..setUint64(0, bytes.length, Endian.big);
  final framed = BytesBuilder(copy: false)
    ..add(pathLength.buffer.asUint8List())
    ..add(pathBytes)
    ..add(contentLength.buffer.asUint8List())
    ..add(bytes);
  return 'sha256:${sha256.convert(framed.takeBytes())}';
}
