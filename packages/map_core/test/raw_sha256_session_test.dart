import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:map_core/map_core.dart';
import 'package:map_core/map_core_domain.dart' as domain;
import 'package:map_core/src/operations/narrative_fingerprint_sha256_portable.dart'
    as portable;
import 'package:map_core/src/operations/raw_sha256_session.dart';
import 'package:test/test.dart';

void main() {
  for (final portableOnly in [false, true]) {
    for (final length in [0, 1, 65, 65537, 262145]) {
      test('raw session oracle portable=$portableOnly length=$length', () {
        final bytes = Uint8List.fromList(
          List.generate(length + 7, (i) => i * 31),
        );
        final view = Uint8List.sublistView(bytes, 7);
        final session = portableOnly
            ? RawSha256Session.withSinkFactory(
                portable.createNarrativeFingerprintSha256Sink,
              )
            : RawSha256Session();
        try {
          session.add([]);
          for (var offset = 0; offset < length; offset += 8191) {
            session.add(
              Uint8List.sublistView(
                view,
                offset,
                offset + 8191 < length ? offset + 8191 : length,
              ),
            );
          }
          final expected = sha256.convert(view).toString();
          expect(session.finish(), expected);
          expect(session.finish(), expected);
          expect(expected, isNot(startsWith('sha256:')));
          expect(() => session.add([]), throwsStateError);
        } finally {
          session.dispose();
        }
        expect(session.finish, throwsStateError);
      });
    }
  }

  test('raw session is exported through both public core namespaces', () {
    final domain.RawSha256Session fromDomain = RawSha256Session();
    try {
      fromDomain.add(utf8.encode('été灯😀'));
      expect(
        fromDomain.finish(),
        sha256.convert(utf8.encode('été灯😀')).toString(),
      );
    } finally {
      fromDomain.dispose();
    }
  });

  test('raw session retains integer truncation and streaming boundaries', () {
    final session = RawSha256Session();
    try {
      session.add([-1, 256]);
      session.add([511, -257]);
      expect(session.finish(), sha256.convert([255, 0, 255, 255]).toString());
    } finally {
      session.dispose();
    }
  });

  test('dispose disables output before closing an unfinished backend', () {
    late Sink<Digest> output;
    var closedAfterDiscard = false;
    final sink = _Sink(
      onClose: () {
        output.add(Digest(List.filled(32, 1)));
        output.add(Digest(List.filled(32, 2)));
        closedAfterDiscard = true;
      },
    );
    final session = RawSha256Session.withSinkFactory((target) {
      output = target;
      return ByteConversionSink.from(sink);
    });
    session.add([1]);
    session.dispose();
    expect(closedAfterDiscard, isTrue);
    expect(sink.closes, 1);
    expect(session.finish, throwsStateError);
    expect(() => session.add([2]), throwsStateError);
    session.dispose();
    expect(sink.closes, 1);
    expect(() => output.add(Digest(List.filled(32, 3))), returnsNormally);
  });

  test('upstream error survives throwing disposal in a finally block', () {
    final primary = StateError('source');
    final secondary = StateError('cleanup');
    final sink = _Sink(onClose: () => throw secondary);
    final session = RawSha256Session.withSinkFactory(
      (_) => ByteConversionSink.from(sink),
    );
    expect(() {
      try {
        session.add([1]);
        throw primary;
      } finally {
        session.dispose();
      }
    }, throwsA(same(primary)));
    expect(sink.closes, 1);
    expect(session.finish, throwsStateError);
  });

  test('backend add failure survives a secondary cleanup failure', () {
    final primary = StateError('add');
    final secondary = StateError('cleanup');
    final sink = _Sink(
      onAdd: (_) => throw primary,
      onClose: () => throw secondary,
    );
    final session = RawSha256Session.withSinkFactory(
      (_) => ByteConversionSink.from(sink),
    );
    expect(() => session.add([1]), throwsA(same(primary)));
    expect(sink.closes, 1);
    expect(session.finish, throwsStateError);
    session.dispose();
    expect(sink.closes, 1);
  });

  test('backend finish failure survives a secondary cleanup failure', () {
    final primary = StateError('finish');
    final secondary = StateError('cleanup');
    var calls = 0;
    final sink = _Sink(
      onClose: () {
        throw ++calls == 1 ? primary : secondary;
      },
    );
    final session = RawSha256Session.withSinkFactory(
      (_) => ByteConversionSink.from(sink),
    );
    session.add([1]);
    expect(session.finish, throwsA(same(primary)));
    expect(sink.closes, 2);
    expect(session.finish, throwsStateError);
    session.dispose();
    expect(sink.closes, 2);
  });

  test(
    'missing or duplicate backend digest cannot become a successful finish',
    () {
      for (final duplicate in [false, true]) {
        late Sink<Digest> output;
        final sink = _Sink(
          onClose: () {
            if (duplicate) {
              output.add(Digest(List.filled(32, 1)));
              output.add(Digest(List.filled(32, 2)));
            }
          },
        );
        final session = RawSha256Session.withSinkFactory((target) {
          output = target;
          return ByteConversionSink.from(sink);
        });
        expect(session.finish, throwsStateError);
        expect(session.finish, throwsStateError);
        session.dispose();
      }
    },
  );

  test(
    'factory failure neutralizes captured output without hiding the error',
    () {
      final failure = StateError('factory');
      late Sink<Digest> output;
      expect(
        () => RawSha256Session.withSinkFactory((target) {
          output = target;
          throw failure;
        }),
        throwsA(same(failure)),
      );
      output.add(Digest(List.filled(32, 1)));
      expect(() => output.add(Digest(List.filled(32, 2))), returnsNormally);
    },
  );
}

final class _Sink implements Sink<List<int>> {
  _Sink({this.onAdd, this.onClose});
  final void Function(List<int>)? onAdd;
  final void Function()? onClose;
  var closes = 0;
  @override
  void add(List<int> value) => onAdd?.call(value);
  @override
  void close() {
    closes++;
    onClose?.call();
  }
}
