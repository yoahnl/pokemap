import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/application/runtime_pokemon_species_loader.dart';
import 'package:path/path.dart' as p;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RuntimePokemonSpeciesLoader', () {
    late Directory tempRoot;

    setUp(() async {
      tempRoot = await Directory.systemTemp.createTemp(
        'runtime_species_loader_',
      );
    });

    tearDown(() async {
      if (await tempRoot.exists()) {
        await tempRoot.delete(recursive: true);
      }
    });

    test(
        'loads the requested species without failing on unrelated invalid files',
        () async {
      final speciesDir = Directory(
        p.join(tempRoot.path, 'data', 'pokemon', 'species'),
      );
      await speciesDir.create(recursive: true);

      await File(p.join(speciesDir.path, 'targetmon.json')).writeAsString(
        jsonEncode(<String, dynamic>{
          'id': 'targetmon',
          'typing': <String, dynamic>{
            'types': <String>['grass'],
          },
          'baseStats': <String, dynamic>{
            'hp': 45,
            'atk': 49,
            'def': 49,
            'spa': 65,
            'spd': 65,
            'spe': 45,
          },
          'abilities': <String, dynamic>{
            'primary': 'overgrow',
          },
          'refs': <String, dynamic>{
            'learnset': 'targetmon',
          },
        }),
      );
      await File(p.join(speciesDir.path, 'broken.json')).writeAsString(
        '{this is not valid json',
      );

      final loader = RuntimePokemonSpeciesLoader();
      final species = await loader.loadById(
        projectRootDirectory: tempRoot.path,
        pokemonConfig: const ProjectPokemonConfig(
          speciesDir: 'data/pokemon/species',
        ),
        speciesId: 'targetmon',
      );

      expect(species.id, 'targetmon');
      expect(species.primaryAbilityId, 'overgrow');
    });
  });
}
