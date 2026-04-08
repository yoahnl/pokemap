import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/application/errors/application_errors.dart';
import 'package:map_editor/src/application/models/pokedex_list_entry.dart';
import 'package:map_editor/src/application/use_cases/list_pokedex_entries_use_case.dart';
import 'package:map_editor/src/application/use_cases/project_management_use_cases.dart';
import 'package:map_editor/src/application/use_cases/seed_pokemon_demo_data_use_case.dart';
import 'package:map_editor/src/infrastructure/filesystem/project_filesystem.dart';
import 'package:map_editor/src/infrastructure/repositories/file_repositories.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory tempProjectRoot;
  late ProjectFileSystem workspace;
  late SeedPokemonDemoDataUseCase seedUseCase;
  late ListPokedexEntriesUseCase useCase;

  setUp(() async {
    tempProjectRoot = await Directory.systemTemp.createTemp('pokedex_list_');
    workspace = ProjectFileSystem(tempProjectRoot.path);
    seedUseCase = const SeedPokemonDemoDataUseCase();
    useCase = const ListPokedexEntriesUseCase();
  });

  tearDown(() async {
    if (await tempProjectRoot.exists()) {
      await tempProjectRoot.delete(recursive: true);
    }
  });

  group('ListPokedexEntriesUseCase', () {
    test('returns a sorted pokedex list from the project workspace', () async {
      await seedUseCase.execute(workspace);

      final entries = await useCase.execute(workspace);

      expect(entries, hasLength(2));
      expect(entries.map((entry) => entry.id).toList(), <String>[
        'bulbasaur',
        'ivysaur',
      ]);

      final bulbasaur = entries.first;
      expect(bulbasaur.nationalDex, 1);
      expect(bulbasaur.primaryName, 'Bulbasaur');
      expect(bulbasaur.types, <String>['grass', 'poison']);
      expect(bulbasaur.isStarterEligible, isTrue);
    });

    test('does not expose filesystem concerns in the application model',
        () async {
      await seedUseCase.execute(workspace);

      final entries = await useCase.execute(workspace);
      final PokedexListEntry entry = entries.first;
      final dynamic dynamicEntry = entry;

      expect(() => dynamicEntry.relativePath, throwsA(isA<NoSuchMethodError>()));
    });

    test('uses the workspace project data and not the monorepo root', () async {
      await seedUseCase.execute(workspace);

      final decoy = await Directory.systemTemp.createTemp('pokedex_decoy_');
      final originalCurrent = Directory.current;
      try {
        await Directory(
          p.join(decoy.path, 'data', 'pokemon', 'species'),
        ).create(recursive: true);
        await File(
          p.join(decoy.path, 'data', 'pokemon', 'species', '0003-venusaur.json'),
        ).writeAsString('''
{
  "id": "venusaur",
  "nationalDex": 3,
  "names": {"en": "Venusaur"},
  "typing": {"types": ["grass", "poison"]}
}
''');

        Directory.current = decoy.path;

        final entries = await useCase.execute(workspace);

        expect(entries.map((entry) => entry.id), isNot(contains('venusaur')));
        expect(entries.map((entry) => entry.id), containsAll(<String>[
          'bulbasaur',
          'ivysaur',
        ]));
      } finally {
        Directory.current = originalCurrent.path;
        if (await decoy.exists()) {
          await decoy.delete(recursive: true);
        }
      }
    });

    test('leaves project.json strictly unchanged', () async {
      final createProjectUseCase = CreateProjectUseCase(
        FileProjectRepository(),
        const FileProjectWorkspaceFactory(),
      );
      await createProjectUseCase.execute('Pokedex List Project', tempProjectRoot.path);
      await seedUseCase.execute(workspace);

      final projectFile = File(workspace.projectManifestPath);
      final before = await projectFile.readAsString();

      await useCase.execute(workspace);

      final after = await projectFile.readAsString();
      expect(after, before);
    });

    test('returns starter eligibility from species gameplay flags', () async {
      await seedUseCase.execute(workspace);

      final entries = await useCase.execute(workspace);

      final bulbasaur = entries.firstWhere((entry) => entry.id == 'bulbasaur');
      final ivysaur = entries.firstWhere((entry) => entry.id == 'ivysaur');

      expect(bulbasaur.isStarterEligible, isTrue);
      expect(ivysaur.isStarterEligible, isFalse);
    });

    test('fails explicitly when species data is invalid', () async {
      await seedUseCase.execute(workspace);

      final speciesFile = File(
        workspace.resolveProjectRelativePath(
          'data/pokemon/species/0002-ivysaur.json',
        ),
      );
      await speciesFile.writeAsString('{ invalid json');

      expect(
        () => useCase.execute(workspace),
        throwsA(
          isA<EditorPersistenceException>().having(
            (error) => error.message,
            'message',
            contains('Invalid JSON'),
          ),
        ),
      );
    });
  });
}
