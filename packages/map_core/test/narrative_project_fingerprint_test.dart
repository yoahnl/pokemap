import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('is stable across input order and slash normalization', () {
    final first = computeNarrativeProjectFingerprint([
      NarrativeProjectFingerprintEntry(
          relativePath: 'maps/a.json', bytes: utf8.encode('A')),
      NarrativeProjectFingerprintEntry(
          relativePath: r'dialogues\intro.yarn', bytes: utf8.encode('B')),
    ]);
    final second = computeNarrativeProjectFingerprint([
      NarrativeProjectFingerprintEntry(
          relativePath: 'dialogues/intro.yarn', bytes: utf8.encode('B')),
      NarrativeProjectFingerprintEntry(
          relativePath: './maps/a.json', bytes: utf8.encode('A')),
    ]);
    expect(second, first);
  });

  test('includes path boundaries and every file byte', () {
    final base = computeNarrativeProjectFingerprint([
      NarrativeProjectFingerprintEntry(
          relativePath: 'project.json', bytes: utf8.encode('AB')),
    ]);
    final split = computeNarrativeProjectFingerprint([
      NarrativeProjectFingerprintEntry(
          relativePath: 'project.json', bytes: utf8.encode('A')),
      NarrativeProjectFingerprintEntry(
          relativePath: 'maps/a.json', bytes: utf8.encode('B')),
    ]);
    expect(split, isNot(base));
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
          relativePath: '../secret', bytes: const []),
      throwsArgumentError,
    );
  });
}
