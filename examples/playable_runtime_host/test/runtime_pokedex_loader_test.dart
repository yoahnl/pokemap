import 'dart:convert';
import 'dart:io';

import 'package:PokeMap_Loader/src/runtime_pokedex_loader.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Ce test prouve que le chargeur runtime lit le manifest du projet, parcourt
  // le dossier species local et construit une projection légère stable.
  // Il cible explicitement le shape consolidé `typing.types`, pour éviter
  // qu'une fixture permissive continue de masquer un mauvais parse des types.
  test('loads and sorts Pokédex entries from the project species directory',
      () async {
    final root = await Directory.systemTemp.createTemp('runtime_pokedex_');
    addTearDown(() async {
      if (await root.exists()) {
        await root.delete(recursive: true);
      }
    });

    final projectFile = File('${root.path}/project.json');
    final speciesDirectory = Directory('${root.path}/data/pokemon/species');
    await speciesDirectory.create(recursive: true);

    final manifest = ProjectManifest(
      name: 'Runtime Test',
      maps: [
        ProjectMapEntry(
          id: 'lab',
          name: 'Lab',
          relativePath: 'maps/lab.json',
        ),
      ],
      tilesets: [],
      surfaceCatalog: ProjectSurfaceCatalog(),
    );
    await projectFile.writeAsString(jsonEncode(manifest.toJson()));

    await File('${speciesDirectory.path}/0002-ivysaur.json').writeAsString(
      jsonEncode({
        'id': 'ivysaur',
        'nationalDex': 2,
        'names': {
          'fr': 'Herbizarre',
          'en': 'Ivysaur',
        },
        'typing': {
          'types': ['poison', '', 'grass'],
        },
        'classification': {
          'isEnabledInProject': false,
        },
        'dexContent': {
          'flavorText': 'Blooming Pokemon',
        },
      }),
    );
    await File('${speciesDirectory.path}/0001-bulbasaur.json').writeAsString(
      jsonEncode({
        'id': 'bulbasaur',
        'nationalDex': 1,
        'names': {
          'en': 'Bulbasaur',
          'fr': 'Bulbizarre',
        },
        'typing': {
          'types': ['grass', ' ', 'poison'],
        },
        'classification': {
          'isEnabledInProject': true,
        },
        'dexContent': {
          'flavorText': 'Seed Pokemon',
        },
      }),
    );

    final entries = await loadRuntimePokedexEntries(
      projectFilePath: projectFile.path,
    );

    expect(entries.map((entry) => entry.id).toList(), ['bulbasaur', 'ivysaur']);
    expect(entries.first.primaryName, 'Bulbasaur');
    expect(entries.first.types, ['grass', 'poison']);
    expect(entries.first.isEnabledInProject, isTrue);
    expect(entries.last.types, ['poison', 'grass']);
    expect(entries.expand((entry) => entry.types), isNot(contains('')));
    expect(entries.expand((entry) => entry.types), isNot(contains(' ')));
    expect(entries.last.isEnabledInProject, isFalse);
    expect(entries.last.flavorText, 'Blooming Pokemon');
  });
}
