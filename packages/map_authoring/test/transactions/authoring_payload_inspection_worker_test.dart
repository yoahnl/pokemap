import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:map_authoring/map_authoring_api.dart';
import 'package:map_core/map_core_domain.dart'
    show NarrativeProjectFingerprintBuilder;
import 'package:test/test.dart';

void main() {
  for (final size in [
    0,
    17,
    (256 << 10) - 1,
    256 << 10,
    (256 << 10) + 17,
    1 << 20
  ]) {
    for (final chunkSizes in [
      <int>[size + 1],
      <int>[1, 17, 131075, 8191],
      <int>[65536],
    ]) {
      test(
          'inspection preserves canonical digests for $size bytes in $chunkSizes chunks',
          () async {
        final bytes = _bytes(size);
        final observed = await inspectAuthoringPayload(
          _chunks(bytes, chunkSizes),
          storageKey: './assets//été\\灯😀.bin',
          byteLength: size,
        );
        expect(observed, _oracle(bytes, 'assets/été/灯😀.bin'));
      });
    }
  }

  for (final declared in [17, 256 << 10]) {
    for (final delta in [-1, 1]) {
      test('inspection rejects length delta $delta at declared $declared bytes',
          () async {
        await expectLater(
          inspectAuthoringPayload(
            _chunks(_bytes(declared + delta), [65536]),
            storageKey: 'assets/length.bin',
            byteLength: declared,
          ),
          throwsA(_lengthMismatch),
        );
      });
    }
  }

  for (final invalid in [-1, 256]) {
    for (final size in [17, (256 << 10) + 17]) {
      test('inspection rejects byte $invalid without coercion at $size bytes',
          () async {
        Stream<List<int>> chunks() async* {
          yield Uint8List(size - 1);
          yield [invalid];
        }

        await expectLater(
          inspectAuthoringPayload(
            chunks(),
            storageKey: 'assets/invalid.bin',
            byteLength: size,
          ),
          throwsA(_lengthMismatch),
        );
      });
    }
  }

  for (final size in [17, 256 << 10]) {
    test(
        'inspection preserves upstream stream error and releases source for $size bytes',
        () async {
      final failure = StateError('upstream sentinel');
      var released = false;
      Stream<List<int>> chunks() async* {
        try {
          yield Uint8List(7);
          throw failure;
        } finally {
          released = true;
        }
      }

      await expectLater(
        inspectAuthoringPayload(
          chunks(),
          storageKey: 'assets/upstream.bin',
          byteLength: size,
        ),
        throwsA(same(failure)),
      );
      expect(released, isTrue);
    });
  }

  test('large inspection subscribes before a synchronous broadcast emits',
      () async {
    final bytes = _bytes(256 << 10);
    final source = StreamController<List<int>>.broadcast(sync: true);
    addTearDown(source.close);
    final inspection = inspectAuthoringPayload(
      source.stream,
      storageKey: 'assets/broadcast.bin',
      byteLength: bytes.length,
    );
    source.add(bytes);
    await source.close();
    expect(await inspection, _oracle(bytes, 'assets/broadcast.bin'));
  });

  test('invalid input cancels its source before consuming further chunks',
      () async {
    var released = false;
    var consumedTail = false;
    Stream<List<int>> chunks() async* {
      try {
        yield [-1];
        consumedTail = true;
        yield Uint8List(256 << 10);
      } finally {
        released = true;
      }
    }

    await expectLater(
      inspectAuthoringPayload(
        chunks(),
        storageKey: 'assets/cancel.bin',
        byteLength: 256 << 10,
      ),
      throwsA(_lengthMismatch),
    );
    expect(released, isTrue);
    expect(consumedTail, isFalse);
  });

  test('inspection handles producer reuse of a bounded mutable chunk',
      () async {
    final expected = BytesBuilder(copy: false);
    final buffer = Uint8List(65536);
    Stream<List<int>> chunks() async* {
      for (var index = 0; index < 8; index++) {
        buffer.fillRange(0, buffer.length, index);
        expected.add(Uint8List.fromList(buffer));
        yield buffer;
      }
    }

    final observed = await inspectAuthoringPayload(
      chunks(),
      storageKey: 'assets/reused.bin',
      byteLength: buffer.length * 8,
    );
    expect(observed, _oracle(expected.takeBytes(), 'assets/reused.bin'));
  });

  test('queued inspections recover after concurrent invalid streams', () async {
    final bytes = _bytes((256 << 10) + 1);
    final expected = _oracle(bytes, 'assets/recovery.bin');
    final operations = [
      for (var index = 0; index < 8; index++)
        () async {
          if (index.isEven) {
            await expectLater(
              inspectAuthoringPayload(
                Stream.value(<int>[-1]),
                storageKey: 'assets/recovery.bin',
                byteLength: bytes.length,
              ),
              throwsA(_lengthMismatch),
            );
          } else {
            expect(
              await inspectAuthoringPayload(
                _chunks(bytes, [8191, 131075]),
                storageKey: 'assets/recovery.bin',
                byteLength: bytes.length,
              ),
              expected,
            );
          }
        }(),
    ];
    await Future.wait(operations);
    expect(
      await inspectAuthoringPayload(
        _chunks(bytes, [65536]),
        storageKey: 'assets/recovery.bin',
        byteLength: bytes.length,
      ),
      expected,
    );
  });

  test('negative declared length fails without consuming the stream', () async {
    var consumed = false;
    Stream<List<int>> chunks() async* {
      consumed = true;
      yield [0];
    }

    await expectLater(
      inspectAuthoringPayload(chunks(),
          storageKey: 'asset.bin', byteLength: -1),
      throwsArgumentError,
    );
    expect(consumed, isFalse);
  });

  test('large inspection rejects a path outside the canonical resource domain',
      () async {
    var listened = false;
    final source = StreamController<List<int>>(
      onListen: () => listened = true,
    );
    await expectLater(
      inspectAuthoringPayload(
        source.stream,
        storageKey: '../outside.bin',
        byteLength: 256 << 10,
      ),
      throwsArgumentError,
    );
    expect(listened, isFalse);
    unawaited(source.close());
  });

  for (final revisionOnly in [false, true]) {
    for (final size in [
      (256 << 10) - 1,
      256 << 10,
      (256 << 10) + 1,
      (4 << 20) - 1,
      4 << 20,
      (4 << 20) + 1,
    ]) {
      test(
          'native and worker keep boundary oracle revision=$revisionOnly size=$size',
          () async {
        final bytes = _bytes(size);
        final expected = _inspectionOracle(revisionOnly, bytes);
        expect(await _inspectCase(revisionOnly, Stream.value(bytes), size),
            expected);
        expect(
            await runZoned(
              () => _inspectCase(revisionOnly, Stream.value(bytes), size),
              zoneValues: {#authoringPayloadWorkerForTesting: true},
            ),
            expected);
      });
    }

    test('native slices yield real event turns revision=$revisionOnly',
        () async {
      const size = 512 << 10;
      var beats = 0;
      final checkpoints = <int>[];
      final timer = Timer.periodic(Duration.zero, (_) => beats++);
      try {
        final source = _ProbeBytes(size, (index) {
          if (index % (128 << 10) == 0) checkpoints.add(beats);
          return index & 255;
        });
        final result =
            await _inspectCase(revisionOnly, Stream.value(source), size);
        expect(
            result,
            _inspectionOracle(
                revisionOnly,
                Uint8List.fromList(
                  List.generate(size, (index) => index & 255),
                )));
        expect(checkpoints, hasLength(4));
        for (var index = 1; index < checkpoints.length; index++) {
          expect(checkpoints[index], greaterThan(checkpoints[index - 1]));
        }
      } finally {
        timer.cancel();
      }
    }, skip: !NarrativeProjectFingerprintBuilder.nativeBackendAvailable);

    test(
        'native freezes each typed slice before yielding revision=$revisionOnly',
        () async {
      const size = 512 << 10;
      final bytes = Uint8List(size);
      Stream<List<int>> source() async* {
        Timer.run(() => bytes.fillRange(0, size, 9));
        yield bytes.asUnmodifiableView();
      }

      final result = await _inspectCase(revisionOnly, source(), size);
      final expected = Uint8List(size)..fillRange(128 << 10, size, 9);
      expect(result, _inspectionOracle(revisionOnly, expected));
      expect(bytes.first, 9);
    }, skip: !NarrativeProjectFingerprintBuilder.nativeBackendAvailable);

    test(
        'copy and source failures keep identity and release slots revision=$revisionOnly',
        () async {
      const size = 256 << 10;
      for (final forceWorker in [false, true]) {
        for (final failure in [
          StateError('getter'),
          ArgumentError.value(7, 'source')
        ]) {
          final source = _ProbeBytes(size, (index) {
            if (index == (128 << 10) + 5) throw failure;
            return index & 255;
          });
          await expectLater(
              runZoned(
                () => _inspectCase(revisionOnly, Stream.value(source), size),
                zoneValues: {#authoringPayloadWorkerForTesting: forceWorker},
              ),
              throwsA(same(failure)));
        }
      }
      final bytes = _bytes(size);
      expect(await _inspectCase(revisionOnly, Stream.value(bytes), size),
          _inspectionOracle(revisionOnly, bytes));
    });

    test(
        'constructor failures do not subscribe and release admission revision=$revisionOnly',
        () async {
      const size = 256 << 10;
      for (final forceWorker in [false, true]) {
        var listened = false;
        Stream<List<int>> source() async* {
          listened = true;
          yield Uint8List(size);
        }

        await expectLater(
            runZoned(
              () => _inspectCase(revisionOnly, source(), size,
                  path: '../outside.bin'),
              zoneValues: {#authoringPayloadWorkerForTesting: forceWorker},
            ),
            throwsA(isA<ArgumentError>()
                .having((error) => error.invalidValue, 'invalidValue',
                    '../outside.bin')
                .having((error) => error.name, 'name', 'relativePath')));
        expect(listened, isFalse);
      }
      final bytes = _bytes(size);
      expect(await _inspectCase(revisionOnly, Stream.value(bytes), size),
          _inspectionOracle(revisionOnly, bytes));
    });
  }

  test('native and worker share at most two admitted subscriptions', () async {
    const size = 256 << 10;
    final bytes = _bytes(size);
    final started = List.generate(5, (_) => Completer<void>());
    final gates = List.generate(5, (_) => Completer<void>());
    var active = 0;
    var maximum = 0;
    Stream<List<int>> source(int index) async* {
      active++;
      if (active > maximum) maximum = active;
      started[index].complete();
      try {
        await gates[index].future;
        yield bytes;
      } finally {
        active--;
      }
    }

    final operations = [
      for (var index = 0; index < 5; index++)
        runZoned(
          () => _inspectCase(index.isOdd, source(index), size),
          zoneValues: {
            #authoringPayloadWorkerForTesting: index == 1 || index == 3
          },
        )
    ];
    try {
      await Future.wait(started.take(2).map((value) => value.future))
          .timeout(const Duration(seconds: 5));
      expect(started.skip(2).every((value) => !value.isCompleted), isTrue);
      gates[0].complete();
      await operations[0];
      await started[2].future.timeout(const Duration(seconds: 5));
      expect(maximum, 2);
    } finally {
      for (final gate in gates) {
        if (!gate.isCompleted) gate.complete();
      }
      await Future.wait(operations);
    }
    expect(active, 0);
    expect(maximum, 2);
  });
}

final _lengthMismatch = isA<AuthoringPayloadException>().having(
  (error) => error.code,
  'code',
  'payload.length_mismatch',
);

Uint8List _bytes(int length) => Uint8List.fromList(
      List.generate(length, (index) => (index * 37 + (index >> 8)) & 255),
    );

Stream<List<int>> _chunks(Uint8List bytes, List<int> sizes) async* {
  yield const [];
  for (var offset = 0, index = 0; offset < bytes.length; index++) {
    final end = offset + sizes[index % sizes.length];
    final next = end < bytes.length ? end : bytes.length;
    yield Uint8List.sublistView(bytes, offset, next);
    offset = next;
  }
  yield const [];
}

AuthoringPayloadInspection _oracle(Uint8List bytes, String normalizedPath) => (
      rawSha256: sha256.convert(bytes).toString(),
      resourceRevision: _framedDigest(bytes, normalizedPath),
      byteLength: bytes.length,
      contentDigest: _framedDigest(bytes, 'artifact-content'),
    );

String _framedDigest(Uint8List bytes, String path) {
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

Future<Object> _inspectCase(
    bool revisionOnly, Stream<List<int>> source, int size,
    {String path = 'assets/native-route.bin'}) async {
  if (revisionOnly) {
    return inspectAuthoringResourceRevision(source,
        storageKey: path, byteLength: size);
  }
  return inspectAuthoringPayload(source, storageKey: path, byteLength: size);
}

Object _inspectionOracle(bool revisionOnly, Uint8List bytes) {
  final full = _oracle(bytes, 'assets/native-route.bin');
  return revisionOnly
      ? (resourceRevision: full.resourceRevision, byteLength: bytes.length)
      : full;
}

final class _ProbeBytes extends ListBase<int> {
  _ProbeBytes(this.length, this.read);
  @override
  final int length;
  final int Function(int) read;
  @override
  set length(int value) => throw UnsupportedError('read only');
  @override
  int operator [](int index) => read(index);
  @override
  void operator []=(int index, int value) =>
      throw UnsupportedError('read only');
}
