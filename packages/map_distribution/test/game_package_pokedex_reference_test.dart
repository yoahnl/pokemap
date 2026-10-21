import 'dart:convert';
import 'dart:typed_data';
import 'package:map_distribution/map_distribution.dart';
import 'package:test/test.dart';

void main() {
  void validate(Map<String, Object?> condition) {
    final bytes = Uint8List.fromList(utf8.encode(jsonEncode({
      'payload': {'conditionSource': condition},
    })));
    const GamePackageContentValidator(GamePackageSecurityPolicy()).validate(
      GamePackageFileEntry(
          path: 'project/catalog/objects/${'a' * 64}.json',
          size: bytes.length,
          sha256: '0' * 64,
          mediaType: 'application/json'),
      bytes,
    );
  }

  for (final id in ['national:1:151', 'national:152:251', 'national:1:65535']) {
    test('accepts typed Pokedex range $id without treating it as a URI', () {
      expect(
          () => validate({
                'sourceKind': 'pokedexCaughtCount',
                'sourceId': id,
                'field': 'minimumCount',
                'operator': 'isTrue',
                'value': '10'
              }),
          returnsNormally);
    });
  }
  for (final id in [
    'national:0:151',
    'national:151:1',
    'national:1:65536',
    'national:01:151',
    'national:1:151/../secret',
    '/tmp/outside',
    'file:///tmp/outside',
    'https://example.test/outside'
  ]) {
    test('rejects invalid Pokedex reference $id', () {
      expect(
          () => validate({'sourceKind': 'pokedexCaughtCount', 'sourceId': id}),
          throwsA(isA<GamePackageFormatException>()
              .having((error) => error.code, 'code', 'referenceEscapesRoot')));
    });
  }
  test('other condition kinds retain URI rejection', () {
    expect(
        () => validate({'sourceKind': 'map', 'sourceId': 'national:1:151'}),
        throwsA(isA<GamePackageFormatException>()
            .having((error) => error.code, 'code', 'referenceEscapesRoot')));
  });
  test('Pokedex conditions retain sibling path validation', () {
    expect(
        () => validate({
              'sourceKind': 'pokedexCaughtCount',
              'sourceId': 'national:1:151',
              'assetPath': '../outside.png'
            }),
        throwsA(isA<GamePackageFormatException>()
            .having((error) => error.code, 'code', 'referenceEscapesRoot')));
  });
}
