import 'dart:collection';
import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('is stable across input order and slash normalization', () {
    final first = computeNarrativeProjectFingerprint([
      NarrativeProjectFingerprintEntry(
        relativePath: 'maps/a.json',
        bytes: utf8.encode('A'),
      ),
      NarrativeProjectFingerprintEntry(
        relativePath: r'dialogues\intro.yarn',
        bytes: utf8.encode('B'),
      ),
    ]);
    final second = computeNarrativeProjectFingerprint([
      NarrativeProjectFingerprintEntry(
        relativePath: 'dialogues/intro.yarn',
        bytes: utf8.encode('B'),
      ),
      NarrativeProjectFingerprintEntry(
        relativePath: './maps/a.json',
        bytes: utf8.encode('A'),
      ),
    ]);
    expect(second, first);
  });

  test('includes path boundaries and every file byte', () {
    final base = computeNarrativeProjectFingerprint([
      NarrativeProjectFingerprintEntry(
        relativePath: 'project.json',
        bytes: utf8.encode('AB'),
      ),
    ]);
    final split = computeNarrativeProjectFingerprint([
      NarrativeProjectFingerprintEntry(
        relativePath: 'project.json',
        bytes: utf8.encode('A'),
      ),
      NarrativeProjectFingerprintEntry(
        relativePath: 'maps/a.json',
        bytes: utf8.encode('B'),
      ),
    ]);
    expect(split, isNot(base));
  });

  test('chunked builder preserves the canonical fingerprint framing', () {
    final expected = computeNarrativeProjectFingerprint([
      NarrativeProjectFingerprintEntry(
        relativePath: 'dialogues/intro.yarn',
        bytes: utf8.encode('Bonjour'),
      ),
      NarrativeProjectFingerprintEntry(
        relativePath: 'project.json',
        bytes: utf8.encode('{"name":"Chunked"}'),
      ),
    ]);
    expect(
      expected,
      'sha256:4e08ae7d811e3170f2cb695014512fcc9d2a32b15bdc14adcf50d659502611a5',
    );
    final builder = NarrativeProjectFingerprintBuilder();
    final dialogueBytes = utf8.encode('Bonjour');
    builder
      ..startEntry(
        relativePath: 'dialogues/intro.yarn',
        byteLength: dialogueBytes.length,
      )
      ..addBytes(dialogueBytes.sublist(0, 3))
      ..addBytes(dialogueBytes.sublist(3))
      ..endEntry();
    final projectBytes = utf8.encode('{"name":"Chunked"}');
    builder
      ..startEntry(
        relativePath: 'project.json',
        byteLength: projectBytes.length,
      )
      ..addBytes(projectBytes)
      ..endEntry();

    expect(builder.close(), expected);
  });

  test('chunked builder rejects truncated and out-of-order entries', () {
    final truncated = NarrativeProjectFingerprintBuilder()
      ..startEntry(relativePath: 'a', byteLength: 2)
      ..addBytes(const [1]);
    expect(truncated.endEntry, throwsStateError);

    final outOfOrder = NarrativeProjectFingerprintBuilder()
      ..startEntry(relativePath: 'b', byteLength: 0)
      ..endEntry();
    expect(
      () => outOfOrder.startEntry(relativePath: 'a', byteLength: 0),
      throwsArgumentError,
    );
  });

  test('explicit disposal after a source error abandons the builder', () {
    final builder = NarrativeProjectFingerprintBuilder()
      ..startEntry(relativePath: 'a', byteLength: 1);
    final error = StateError('source length');
    expect(
      () => builder.addBytes(_LengthFailureBytes(error)),
      throwsA(same(error)),
    );
    builder.dispose();
    expect(() => builder.addBytes(const [1]), throwsStateError);
    expect(builder.close, throwsStateError);
  });

  test('pre-ingestion source and framing guards remain recoverable', () {
    final builder = NarrativeProjectFingerprintBuilder();
    try {
      expect(
        () => builder.startEntry(relativePath: '../a', byteLength: 1),
        throwsArgumentError,
      );
      builder.startEntry(relativePath: 'a', byteLength: 1);
      expect(
        () => builder.addBytes(_LengthFailureBytes(StateError('length'))),
        throwsStateError,
      );
      expect(() => builder.addBytes(const [1, 2]), throwsStateError);
      expect(builder.endEntry, throwsStateError);
      expect(builder.close, throwsStateError);
      builder.addBytes(const [1]);
      builder.endEntry();
      expect(
        builder.close(),
        computeNarrativeProjectFingerprint([
          NarrativeProjectFingerprintEntry(relativePath: 'a', bytes: const [1]),
        ]),
      );
    } finally {
      builder.dispose();
    }
  });

  test('rejects duplicate and escaping relative paths', () {
    expect(
      () => computeNarrativeProjectFingerprint([
        NarrativeProjectFingerprintEntry(relativePath: 'a', bytes: const []),
        NarrativeProjectFingerprintEntry(relativePath: './a', bytes: const []),
      ]),
      throwsArgumentError,
    );
    expect(
      () => NarrativeProjectFingerprintEntry(
        relativePath: '../secret',
        bytes: const [],
      ),
      throwsArgumentError,
    );
  });
}

final class _LengthFailureBytes extends ListBase<int> {
  _LengthFailureBytes(this.error);
  final Object error;

  @override
  int get length => throw error;
  @override
  set length(int value) => throw UnsupportedError('immutable');
  @override
  int operator [](int index) => throw error;
  @override
  void operator []=(int index, int value) =>
      throw UnsupportedError('immutable');
}
