import 'dart:convert';

import 'package:map_distribution/map_distribution.dart';
import 'package:test/test.dart';

void main() {
  const samples = <String>[
    '',
    'a',
    'ab',
    'project/a.json',
    'project/a.json.bak',
    'project/b.json',
    'project/A.json',
    'project/\u00e9.json',
    'project/\u07ff.json',
    'project/\u0800.json',
    'project/\ud7ff.json',
    'project/\ue000.json',
    'project/\uffff.json',
    'project/\u{10000}.json',
    'project/\u{1f98a}.json',
    'project/\u{10ffff}.json',
    'project/\ud800',
    'project/\ud800x',
    'project/\udfff',
    'project/\udfffx',
    'project/\ud83d',
    'project/\ud83dx',
    'project/\ufffd',
    'project/\ufffdx',
    'project/\u{1f600}',
    'project/\u{1f600}x',
    'project/\u{1f600}\ud83d',
  ];

  test('compareUtf8 orders strings by their UTF-8 bytes', () {
    for (final left in samples) {
      for (final right in samples) {
        expect(
          PackagePathPolicy.compareUtf8(left, right).sign,
          _byteOrder(left, right).sign,
          reason: '${left.codeUnits} vs ${right.codeUnits}',
        );
      }
    }
  });

  test('sorting with compareUtf8 matches the byte order of the inventory', () {
    final sorted = [...samples]..sort(PackagePathPolicy.compareUtf8);
    final expected = [...samples]..sort(_byteOrder);
    expect(
      sorted.map(utf8.encode).toList(),
      expected.map(utf8.encode).toList(),
    );
  });

  test('segment byte limits count multi-byte characters', () {
    for (final (segment, accepted) in <(String, bool)>[
      ('\u00e9' * 127 + 'a', true),
      ('\u00e9' * 128, false),
      ('\u0800' * 85, true),
      ('\u0800' * 85 + 'a', false),
      ('\u{1f98a}' * 63 + 'abc', true),
      ('\u{1f98a}' * 64, false),
    ]) {
      final path = 'project/$segment';
      if (accepted) {
        expect(
          () => PackagePathPolicy.validate(path, errorPath: 'path'),
          returnsNormally,
          reason: '${utf8.encode(segment).length} bytes',
        );
      } else {
        expect(
          () => PackagePathPolicy.validate(path, errorPath: 'path'),
          throwsA(isA<GamePackageFormatException>()),
          reason: '${utf8.encode(segment).length} bytes',
        );
      }
    }
  });

  test('reserved device names are refused in any case and with extensions', () {
    for (final name in [
      'con',
      'Con.json',
      'PRN.txt',
      'aux',
      'nul.tar.gz',
      'COM1',
      'com9.json',
      'LPT1',
      'lpt5.png',
    ]) {
      expect(
        () => PackagePathPolicy.validate('project/$name', errorPath: 'path'),
        throwsA(isA<GamePackageFormatException>()),
        reason: name,
      );
    }
    for (final name in [
      'COM0',
      'COM10',
      'LPT0',
      'CONSOLE',
      'xcon',
      'con-x.json',
      'NULL',
    ]) {
      expect(
        () => PackagePathPolicy.validate('project/$name', errorPath: 'path'),
        returnsNormally,
        reason: name,
      );
    }
  });
}

int _byteOrder(String left, String right) {
  final leftBytes = utf8.encode(left);
  final rightBytes = utf8.encode(right);
  for (var index = 0;
      index < leftBytes.length && index < rightBytes.length;
      index++) {
    if (leftBytes[index] != rightBytes[index]) {
      return leftBytes[index] - rightBytes[index];
    }
  }
  return leftBytes.length - rightBytes.length;
}
