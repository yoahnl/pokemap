import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/infrastructure/external/pokemon_sdk_studio_source.dart';

void main() {
  group('PokemonSdkStudioSource', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('psdk_studio_source_');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('loads sorted raw Studio payloads from Data/Studio', () async {
      _writeJson(
        tempDir,
        'Data/Studio/moves/002_scratch.json',
        <String, Object?>{'dbSymbol': 'scratch'},
      );
      _writeJson(
        tempDir,
        'Data/Studio/moves/001_tackle.json',
        <String, Object?>{'dbSymbol': 'tackle'},
      );
      _writeJson(
        tempDir,
        'Data/Studio/abilities/overgrow.json',
        <String, Object?>{'dbSymbol': 'overgrow'},
      );
      _writeJson(
        tempDir,
        'Data/Studio/items/potion.json',
        <String, Object?>{'dbSymbol': 'potion'},
      );
      _writeJson(
        tempDir,
        'Data/Studio/types/grass.json',
        <String, Object?>{'dbSymbol': 'grass'},
      );
      _writeJson(
        tempDir,
        'Data/Studio/pokemon/bulbasaur.json',
        <String, Object?>{'dbSymbol': 'bulbasaur'},
      );

      final payload =
          await const PokemonSdkStudioSource().loadProject(tempDir.path);

      expect(payload.moves.map((move) => move['dbSymbol']), [
        'tackle',
        'scratch',
      ]);
      expect(payload.abilities.single['dbSymbol'], 'overgrow');
      expect(payload.items.single['dbSymbol'], 'potion');
      expect(payload.types.single['dbSymbol'], 'grass');
      expect(payload.pokemon.single['dbSymbol'], 'bulbasaur');
    });

    test('keeps missing Studio subdirectories as empty lists', () async {
      Directory('${tempDir.path}/Data/Studio/moves')
          .createSync(recursive: true);

      final payload =
          await const PokemonSdkStudioSource().loadProject(tempDir.path);

      expect(payload.moves, isEmpty);
      expect(payload.abilities, isEmpty);
      expect(payload.items, isEmpty);
      expect(payload.types, isEmpty);
      expect(payload.pokemon, isEmpty);
    });

    test('fails clearly when Data/Studio is missing', () async {
      expect(
        () => const PokemonSdkStudioSource().loadProject(tempDir.path),
        throwsA(
          isA<PokemonSdkStudioSourceException>().having(
            (error) => error.message,
            'message',
            contains('Data/Studio'),
          ),
        ),
      );
    });

    test('fails clearly when a Studio file is not a JSON object', () async {
      final file = File('${tempDir.path}/Data/Studio/moves/broken.json')
        ..createSync(recursive: true)
        ..writeAsStringSync('[1, 2, 3]');

      expect(
        () => const PokemonSdkStudioSource().loadProject(tempDir.path),
        throwsA(
          isA<PokemonSdkStudioSourceException>().having(
            (error) => error.message,
            'message',
            contains(file.path),
          ),
        ),
      );
    });
  });
}

void _writeJson(
  Directory root,
  String relativePath,
  Map<String, Object?> payload,
) {
  File('${root.path}/$relativePath')
    ..createSync(recursive: true)
    ..writeAsStringSync(jsonEncode(payload));
}
