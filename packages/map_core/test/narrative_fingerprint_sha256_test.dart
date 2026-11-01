import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:map_core/map_core.dart';
import 'package:map_core/src/operations/narrative_fingerprint_sha256.dart'
    as backend;
import 'package:map_core/src/operations/narrative_fingerprint_sha256_native.dart';
import 'package:map_core/src/operations/narrative_fingerprint_sha256_portable.dart'
    as portable;
import 'package:test/test.dart';

void main() {
  test('CommonCrypto context matches the platform ABI', () {
    expect(sizeOf<NarrativeSha256Context>(), 104);
  });

  test('native context and scratch are owned and released on close', () {
    final bindings = _Bindings();
    final output = _DigestOutput();
    final input = bindings.sink(output);
    expect(bindings.allocations, [136]);
    expect(bindings.initializations, 1);
    expect(bindings.updates, isEmpty);
    input.add([]);
    expect(bindings.allocations, [136]);
    input.add([1, 2, 3]);
    expect(bindings.allocations, [136, 3]);
    input.add(List.filled(70000, 4));
    expect(bindings.allocations, [136, 3, 65536]);
    expect(bindings.liveBytes, 136 + 65536);
    expect(bindings.maxLiveBytes, 136 + 65536);
    expect(bindings.updates, [3, 65536, 4464]);
    input.close();
    expect(
      output.digest.toString(),
      sha256.convert([1, 2, 3, ...List.filled(70000, 4)]).toString(),
    );
    expect(bindings.finals, 1);
    expect(bindings.releases, hasLength(3));
    expect(bindings.liveBytes, 0);
    input.close();
    expect(bindings.finals, 1);
    expect(() => input.add([]), throwsStateError);
  }, skip: !Platform.isMacOS);

  for (final native in [false, true]) {
    for (final length in [0, 1, 65, 65537, 262145]) {
      for (final chunks in [
        [65536],
        [17, 8191, 65537],
      ]) {
        test('SHA256 oracle native=$native length=$length chunks=$chunks', () {
          final bytes = Uint8List.fromList(
            List.generate(length + 31, (index) => index * 31),
          );
          final view = Uint8List.sublistView(bytes, 13, 13 + length);
          final output = _DigestOutput();
          final input = native
              ? _Bindings().sink(output)
              : portable.createNarrativeFingerprintSha256Sink(output);
          for (var offset = 0, index = 0; offset < length; index++) {
            final end = min(length, offset + chunks[index % chunks.length]);
            input.add(Uint8List.sublistView(view, offset, end));
            offset = end;
          }
          input.close();
          expect(output.digest.toString(), sha256.convert(view).toString());
        }, skip: native && !Platform.isMacOS);
      }
    }
    test('slice and integer truncation oracle native=$native', () {
      final output = _DigestOutput();
      final input = native
          ? _Bindings().sink(output)
          : portable.createNarrativeFingerprintSha256Sink(output);
      input.addSlice([99, -1, 256, 511, -257, 99], 1, 5, false);
      input.addSlice(
        utf8.encode('été灯😀'),
        0,
        utf8.encode('été灯😀').length,
        true,
      );
      expect(
        output.digest.toString(),
        sha256.convert([255, 0, 255, 255, ...utf8.encode('été灯😀')]).toString(),
      );
      input.close();
      expect(() => input.add([1]), throwsStateError);
    }, skip: native && !Platform.isMacOS);
    test(
      'invalid slice leaves the adapter semantics intact native=$native',
      () {
        final output = _DigestOutput();
        final input = native
            ? _Bindings().sink(output)
            : portable.createNarrativeFingerprintSha256Sink(output);
        expect(() => input.addSlice([1, 2], -1, 1, false), throwsRangeError);
        input.addSlice([1, 2], 0, 2, true);
        expect(output.digest.toString(), sha256.convert([1, 2]).toString());
      },
      skip: native && !Platform.isMacOS,
    );
  }

  test('platform and symbol fallback happen before native ingestion', () {
    for (final macOS in [false, true]) {
      var loads = 0;
      final output = _DigestOutput();
      final input = createNarrativeFingerprintSha256Sink(
        output,
        macOS: macOS,
        loadBindings: () {
          loads++;
          throw ArgumentError('missing symbol');
        },
      );
      input.add([1, 2, 3]);
      input.close();
      expect(output.digest.toString(), sha256.convert([1, 2, 3]).toString());
      expect(loads, macOS ? 1 : 0);
    }
  });

  for (final failure in [
    'allocate-context-null',
    'allocate-context-throw',
    'allocate-scratch-null',
    'allocate-scratch-throw',
    'initialize-zero',
    'initialize-throw',
    'update-zero',
    'update-throw',
    'finish-zero',
    'finish-throw',
    'digest-add',
    'digest-close',
  ]) {
    test(
      'native $failure frees every owned allocation without accepting a digest',
      () {
        final bindings = _Bindings(failure: failure);
        final output = _DigestOutput(failure: failure);
        ByteConversionSink? input;
        expect(() {
          input = bindings.sink(output);
          input!.add([1, 2, 3]);
          input!.close();
        }, throwsA(isA<StateError>()));
        expect(bindings.liveBytes, 0);
        expect(bindings.releases, unorderedEquals(bindings.allocatedAddresses));
        if (failure == 'digest-close') {
          expect(
            output.digest.toString(),
            sha256.convert([1, 2, 3]).toString(),
          );
        } else {
          expect(output.digest, isNull);
        }
        final created = input;
        if (created != null) {
          expect(() => created.add([1]), throwsStateError);
          final released = bindings.releases.length;
          created.close();
          expect(bindings.releases, hasLength(released));
        }
      },
      skip: !Platform.isMacOS,
    );
  }

  for (final failure in [
    'late-update-zero',
    'late-update-throw',
    'grow-null',
    'grow-throw',
  ]) {
    test('native $failure never falls back after successful ingestion', () {
      final bindings = _Bindings(failure: failure);
      final output = _DigestOutput();
      final input = bindings.sink(output);
      input.add([1, 2, 3]);
      expect(bindings.updates, [3]);
      expect(() => input.add(List.filled(70000, 4)), throwsStateError);
      expect(output.digest, isNull);
      expect(bindings.finals, 0);
      expect(bindings.liveBytes, 0);
      expect(bindings.releases, unorderedEquals(bindings.allocatedAddresses));
      input.close();
      expect(output.digest, isNull);
      expect(() => input.add([5]), throwsStateError);
    }, skip: !Platform.isMacOS);
  }

  test('independent native streams never share contexts or scratch', () {
    final bindings = _Bindings();
    final first = _DigestOutput();
    final second = _DigestOutput();
    final a = bindings.sink(first);
    final b = bindings.sink(second);
    a.add([1, 2]);
    b.add([3, 4]);
    a.add([5]);
    b.close();
    a.close();
    expect(first.digest.toString(), sha256.convert([1, 2, 5]).toString());
    expect(second.digest.toString(), sha256.convert([3, 4]).toString());
    expect(bindings.liveBytes, 0);
  }, skip: !Platform.isMacOS);

  test(
    'builder keeps exact canonical framing for unicode and multiple entries',
    () {
      final entries = [
        (
          ' ./assets//été\\灯😀.bin ',
          'assets/été/灯😀.bin',
          [-1, 256, 511, -257],
        ),
        ('maps/a.json', 'maps/a.json', utf8.encode('{"name":"été😀"}')),
        ('project.json', 'project.json', <int>[]),
      ];
      final framed = BytesBuilder(copy: false);
      final builder = NarrativeProjectFingerprintBuilder();
      for (final (path, normalized, bytes) in entries) {
        final pathBytes = utf8.encode(normalized);
        framed.add(
          (ByteData(
            8,
          )..setUint64(0, pathBytes.length, Endian.big)).buffer.asUint8List(),
        );
        framed.add(pathBytes);
        framed.add(
          (ByteData(
            8,
          )..setUint64(0, bytes.length, Endian.big)).buffer.asUint8List(),
        );
        framed.add(Uint8List.fromList(bytes));
        builder.startEntry(relativePath: path, byteLength: bytes.length);
        for (final byte in bytes) {
          builder.addBytes([byte]);
        }
        builder.endEntry();
      }
      final expected = 'sha256:${sha256.convert(framed.takeBytes())}';
      expect(builder.close(), expected);
      expect(builder.close(), expected);
      expect(() => builder.addBytes([]), throwsStateError);
    },
  );

  test(
    'native availability agrees across default factory facade and builder',
    () {
      expect(portable.nativeNarrativeFingerprintSha256Available, isFalse);
      expect(
        backend.nativeNarrativeFingerprintSha256Available,
        nativeNarrativeFingerprintSha256Available,
      );
      expect(
        NarrativeProjectFingerprintBuilder.nativeBackendAvailable,
        nativeNarrativeFingerprintSha256Available,
      );
      if (!Platform.isMacOS) {
        expect(nativeNarrativeFingerprintSha256Available, isFalse);
      }
      final output = _DigestOutput();
      backend.createNarrativeFingerprintSha256Sink(output)
        ..add([1, 2, 3])
        ..close();
      expect(output.digest.toString(), sha256.convert([1, 2, 3]).toString());
    },
  );

  test('native framed builder abort releases all owned memory', () {
    final bindings = _Bindings();
    final builder =
        NarrativeProjectFingerprintBuilder.withSinkFactory(bindings.sink)
          ..startEntry(relativePath: 'a', byteLength: 3)
          ..addBytes([1]);
    expect(bindings.liveBytes, greaterThan(0));
    builder.dispose();
    expect(bindings.liveBytes, 0);
    expect(bindings.releases, unorderedEquals(bindings.allocatedAddresses));
    final releases = bindings.releases.length;
    builder.dispose();
    expect(bindings.releases, hasLength(releases));
    expect(builder.close, throwsStateError);
  }, skip: !Platform.isMacOS);

  test('abandon neutralizes output before closing an unfinished backend', () {
    late Sink<Digest> output;
    late _LifecycleSink sink;
    final builder = NarrativeProjectFingerprintBuilder.withSinkFactory((
      target,
    ) {
      output = target;
      sink = _LifecycleSink(
        onClose: () {
          output.add(Digest(List.filled(32, 1)));
          output.add(Digest(List.filled(32, 2)));
        },
      );
      return ByteConversionSink.from(sink);
    })..startEntry(relativePath: 'a', byteLength: 1);
    builder.dispose();
    builder.dispose();
    expect(sink.closes, 1);
    expect(builder.close, throwsStateError);
    expect(
      () => builder.startEntry(relativePath: 'b', byteLength: 0),
      throwsStateError,
    );
    expect(() => builder.addBytes([]), throwsStateError);
    expect(builder.endEntry, throwsStateError);
    expect(() => output.add(Digest(List.filled(32, 3))), returnsNormally);
  });

  test('successful close remains cached after disposal', () {
    late _LifecycleSink sink;
    final builder =
        NarrativeProjectFingerprintBuilder.withSinkFactory((output) {
            final delegate = portable.createNarrativeFingerprintSha256Sink(
              output,
            );
            sink = _LifecycleSink(onAdd: delegate.add, onClose: delegate.close);
            return ByteConversionSink.from(sink);
          })
          ..startEntry(relativePath: 'a', byteLength: 1)
          ..addBytes([1])
          ..endEntry();
    final expected = computeNarrativeProjectFingerprint([
      NarrativeProjectFingerprintEntry(relativePath: 'a', bytes: [1]),
    ]);
    expect(builder.close(), expected);
    builder.dispose();
    expect(builder.close(), expected);
    builder.dispose();
    expect(sink.closes, 1);
    expect(() => builder.addBytes([]), throwsStateError);
  });

  test('owner finally preserves the source error over cleanup failure', () {
    final source = StateError('source');
    final cleanup = StateError('cleanup');
    late _LifecycleSink sink;
    final builder = NarrativeProjectFingerprintBuilder.withSinkFactory((_) {
      sink = _LifecycleSink(onClose: () => throw cleanup);
      return ByteConversionSink.from(sink);
    })..startEntry(relativePath: 'a', byteLength: 1);
    expect(() {
      try {
        throw source;
      } finally {
        builder.dispose();
      }
    }, throwsA(same(source)));
    expect(sink.closes, 1);
    expect(builder.close, throwsStateError);
  });

  test('failed framed ingestion abandons without masking its error', () {
    final primary = StateError('ingestion');
    final cleanup = StateError('cleanup');
    var fail = false;
    late _LifecycleSink sink;
    final builder = NarrativeProjectFingerprintBuilder.withSinkFactory((_) {
      sink = _LifecycleSink(
        onAdd: (_) {
          if (fail) throw primary;
        },
        onClose: () => throw cleanup,
      );
      return ByteConversionSink.from(sink);
    })..startEntry(relativePath: 'a', byteLength: 1);
    fail = true;
    expect(() => builder.addBytes([1]), throwsA(same(primary)));
    expect(sink.closes, 1);
    expect(builder.close, throwsStateError);
  });

  for (final duplicate in [false, true]) {
    test('invalid backend digest cannot finish duplicate=$duplicate', () {
      late _LifecycleSink sink;
      final builder = NarrativeProjectFingerprintBuilder.withSinkFactory((
        output,
      ) {
        sink = _LifecycleSink(
          onClose: () {
            if (duplicate) {
              output.add(Digest(List.filled(32, 1)));
              output.add(Digest(List.filled(32, 2)));
            }
          },
        );
        return ByteConversionSink.from(sink);
      });
      expect(builder.close, throwsStateError);
      expect(builder.close, throwsStateError);
      final closes = sink.closes;
      builder.dispose();
      expect(sink.closes, closes);
    });
  }

  test(
    'failed close discards its partial digest and preserves the primary error',
    () {
      final primary = StateError('close');
      final cleanup = StateError('cleanup');
      late _LifecycleSink sink;
      final builder = NarrativeProjectFingerprintBuilder.withSinkFactory((
        output,
      ) {
        sink = _LifecycleSink(
          onClose: () {
            output.add(Digest(List.filled(32, 1)));
            throw sink.closes == 1 ? primary : cleanup;
          },
        );
        return ByteConversionSink.from(sink);
      });
      expect(builder.close, throwsA(same(primary)));
      expect(builder.close, throwsStateError);
      expect(sink.closes, 2);
      builder.dispose();
      expect(sink.closes, 2);
    },
  );
}

final class _DigestOutput implements Sink<Digest> {
  _DigestOutput({this.failure});
  final String? failure;
  Digest? digest;
  @override
  void add(Digest value) {
    if (failure == 'digest-add') throw StateError('digest add');
    digest = value;
  }

  @override
  void close() {
    if (failure == 'digest-close') throw StateError('digest close');
  }
}

final class _Bindings {
  _Bindings({this.failure});
  final String? failure;
  final system = loadNarrativeFingerprintSha256Bindings();
  final allocations = <int>[];
  final allocatedAddresses = <int>[];
  final releases = <int>[];
  final liveAddresses = <int>{};
  final sizes = <int, int>{};
  final updates = <int>[];
  var initializations = 0;
  var finals = 0;
  var liveBytes = 0;
  var maxLiveBytes = 0;

  ByteConversionSink sink(
    Sink<Digest> output,
  ) => createNarrativeFingerprintSha256Sink(
    output,
    macOS: true,
    loadBindings: () => NarrativeFingerprintSha256Bindings(
      finalizer: system.finalizer,
      allocate: (size) {
        allocations.add(size);
        final phase = allocations.length == 1 ? 'context' : 'scratch';
        if (failure == 'allocate-$phase-null' ||
            failure == 'grow-null' && allocations.length == 3)
          return nullptr;
        if (failure == 'allocate-$phase-throw' ||
            failure == 'grow-throw' && allocations.length == 3)
          throw StateError('allocation');
        final pointer = system.allocate(size);
        expect(liveAddresses.add(pointer.address), isTrue);
        allocatedAddresses.add(pointer.address);
        sizes[pointer.address] = size;
        liveBytes += size;
        maxLiveBytes = max(maxLiveBytes, liveBytes);
        return pointer;
      },
      release: (pointer) {
        expect(liveAddresses.remove(pointer.address), isTrue);
        releases.add(pointer.address);
        liveBytes -= sizes[pointer.address]!;
        system.release(pointer);
      },
      initialize: (context) {
        initializations++;
        if (failure == 'initialize-throw') throw StateError('initialize');
        return failure == 'initialize-zero' ? 0 : system.initialize(context);
      },
      update: (context, bytes, size) {
        updates.add(size);
        if (failure == 'update-throw' ||
            failure == 'late-update-throw' && updates.length == 2)
          throw StateError('update');
        return failure == 'update-zero' ||
                failure == 'late-update-zero' && updates.length == 2
            ? 0
            : system.update(context, bytes, size);
      },
      finish: (digest, context) {
        finals++;
        if (failure == 'finish-throw') throw StateError('finish');
        return failure == 'finish-zero' ? 0 : system.finish(digest, context);
      },
    ),
  );
}

final class _LifecycleSink implements Sink<List<int>> {
  _LifecycleSink({this.onAdd, this.onClose});
  final void Function(List<int>)? onAdd;
  final void Function()? onClose;
  int closes = 0;

  @override
  void add(List<int> data) => onAdd?.call(data);

  @override
  void close() {
    closes++;
    onClose?.call();
  }
}
