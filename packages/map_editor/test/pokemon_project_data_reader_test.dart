import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/application/errors/application_errors.dart';
import 'package:map_editor/src/application/services/pokemon_project_data_reader.dart';
import 'package:map_editor/src/application/use_cases/project_management_use_cases.dart';
import 'package:map_editor/src/application/use_cases/seed_pokemon_demo_data_use_case.dart';
import 'package:map_editor/src/infrastructure/filesystem/project_filesystem.dart';
import 'package:map_editor/src/infrastructure/repositories/file_repositories.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory tempProjectRoot;
  late ProjectFileSystem workspace;
  late SeedPokemonDemoDataUseCase seedUseCase;
  late PokemonProjectDataReader reader;

  setUp(() async {
    tempProjectRoot = await Directory.systemTemp.createTemp('pokemon_readers_');
    workspace = ProjectFileSystem(tempProjectRoot.path);
    seedUseCase = const SeedPokemonDemoDataUseCase();
    reader = const PokemonProjectDataReader();
  });

  tearDown(() async {
    if (await tempProjectRoot.exists()) {
      await tempProjectRoot.delete(recursive: true);
    }
  });

  group('PokemonProjectDataReader', () {
    test('reads the manifest from the project workspace', () async {
      await seedUseCase.execute(workspace);

      final manifest = await reader.readManifest(workspace);

      expect(manifest.schemaVersion, 1);
      expect(manifest.kind, 'pokemon_data_manifest');
      expect(
        manifest.catalogFiles['moves'],
        'catalogs/moves.json',
      );
      expect(
        manifest.futureDataFolders['species'],
        'species/',
      );
    });

    test('reads a species file by id', () async {
      await seedUseCase.execute(workspace);

      final species = await reader.readSpeciesById(workspace, 'bulbasaur');

      expect(species.id, 'bulbasaur');
      expect(species.nationalDex, 1);
      expect(species.typing.types, <String>['grass', 'poison']);
      expect(species.learnsetRef, 'bulbasaur');
      expect(species.evolutionRef, 'bulbasaur');
      expect(species.dexContent.heightM, 0.7);
      expect(species.gameplayFlags.starterEligible, isTrue);
      expect(species.sourceMeta.seededBy, 'SeedPokemonDemoDataUseCase');
    });

    test('reads a learnset file with explicit level-up entries', () async {
      await seedUseCase.execute(workspace);

      final learnset = await reader.readLearnsetById(workspace, 'bulbasaur');

      expect(learnset.speciesId, 'bulbasaur');
      expect(learnset.startingMoves, containsAll(<String>['tackle', 'growl']));
      expect(learnset.levelUp, isNotEmpty);
      expect(learnset.levelUp.first.moveId, 'tackle');
      expect(learnset.levelUp.first.level, 1);
      expect(learnset.levelUp.first.source, 'level_up');
      expect(learnset.levelUp.first.versionGroup, 'demo');
    });

    test('reads an evolution file', () async {
      await seedUseCase.execute(workspace);

      final evolution = await reader.readEvolutionById(workspace, 'bulbasaur');

      expect(evolution.speciesId, 'bulbasaur');
      expect(evolution.preEvolution, isNull);
      expect(evolution.evolutions, hasLength(1));
      expect(evolution.evolutions.single.targetSpeciesId, 'ivysaur');
      expect(evolution.evolutions.single.method, 'level_up');
      expect(evolution.evolutions.single.minLevel, 16);
    });

    test('reads a catalog by logical key', () async {
      await seedUseCase.execute(workspace);

      final movesCatalog = await reader.readCatalogByKey(workspace, 'moves');

      expect(movesCatalog.catalog, 'moves');
      expect(
        movesCatalog.entries.map((entry) => entry['id']).toSet(),
        containsAll(<String>{'tackle', 'growl', 'vine_whip', 'razor_leaf'}),
      );
    });

    test('lists species files from the workspace project only', () async {
      await seedUseCase.execute(workspace);

      final files = await reader.listSpeciesFiles(workspace);

      expect(
        files,
        <String>[
          'data/pokemon/species/0001-bulbasaur.json',
          'data/pokemon/species/0002-ivysaur.json',
        ],
      );
    });

    test('builds a lightweight species index with stable list data', () async {
      await seedUseCase.execute(workspace);

      final entries = await reader.listSpeciesIndexEntries(workspace);

      expect(entries, hasLength(2));

      final bulbasaur = entries.firstWhere((entry) => entry.id == 'bulbasaur');
      expect(bulbasaur.nationalDex, 1);
      expect(bulbasaur.primaryName, 'Bulbasaur');
      expect(bulbasaur.types, <String>['grass', 'poison']);
      expect(
        bulbasaur.relativePath,
        'data/pokemon/species/0001-bulbasaur.json',
      );
    });

    test('uses species id as final primary name fallback instead of filename',
        () async {
      await seedUseCase.execute(workspace);

      final customSpeciesFile = File(
        workspace.resolveProjectRelativePath(
          'data/pokemon/species/9999-not-the-display-name.json',
        ),
      );
      await customSpeciesFile.writeAsString('''
{
  "id": "mystery_mon",
  "nationalDex": 9999,
  "names": {},
  "typing": {
    "types": ["grass"]
  }
}
''');

      final entries = await reader.listSpeciesIndexEntries(workspace);
      final mystery = entries.firstWhere((entry) => entry.id == 'mystery_mon');
      final species = await reader.readSpeciesById(workspace, 'mystery_mon');

      expect(mystery.primaryName, 'mystery_mon');
      expect(mystery.relativePath, 'data/pokemon/species/9999-not-the-display-name.json');
      expect(species.id, 'mystery_mon');
      expect(species.slug, isEmpty);
    });

    test('keeps species lookup coherent with the lightweight index', () async {
      await seedUseCase.execute(workspace);

      final entries = await reader.listSpeciesIndexEntries(workspace);
      final bulbasaurEntry = entries.firstWhere(
        (entry) => entry.id == 'bulbasaur',
      );
      final species = await reader.readSpeciesById(workspace, bulbasaurEntry.id);

      expect(species.id, bulbasaurEntry.id);
      expect(species.nationalDex, bulbasaurEntry.nationalDex);
      expect(species.names['en'], bulbasaurEntry.primaryName);
      expect(species.typing.types, bulbasaurEntry.types);
    });

    test('throws explicit error when species is missing', () async {
      await seedUseCase.execute(workspace);

      expect(
        () => reader.readSpeciesById(workspace, 'venusaur'),
        throwsA(
          isA<EditorNotFoundException>().having(
            (error) => error.message,
            'message',
            contains('Pokemon species not found'),
          ),
        ),
      );
    });

    test('throws explicit error when catalog key is unknown', () async {
      await seedUseCase.execute(workspace);

      expect(
        () => reader.readCatalogByKey(workspace, 'berries'),
        throwsA(
          isA<EditorNotFoundException>().having(
            (error) => error.message,
            'message',
            contains('Pokemon catalog not declared in manifest'),
          ),
        ),
      );
    });

    test('throws explicit error when json is invalid', () async {
      await seedUseCase.execute(workspace);

      final speciesFile = File(
        workspace.resolveProjectRelativePath(
          'data/pokemon/species/0001-bulbasaur.json',
        ),
      );
      await speciesFile.writeAsString('{ invalid json');

      expect(
        () => reader.readSpeciesById(workspace, 'bulbasaur'),
        throwsA(
          isA<EditorPersistenceException>().having(
            (error) => error.message,
            'message',
            contains('Invalid JSON'),
          ),
        ),
      );
    });

    test('fails explicitly when the species projection encounters invalid json',
        () async {
      await seedUseCase.execute(workspace);

      final unrelatedBrokenFile = File(
        workspace.resolveProjectRelativePath(
          'data/pokemon/species/0000-decoy.json',
        ),
      );
      await unrelatedBrokenFile.writeAsString('{ invalid json');

      expect(
        () => reader.listSpeciesIndexEntries(workspace),
        throwsA(
          isA<EditorPersistenceException>().having(
            (error) => error.message,
            'message',
            contains('Invalid JSON'),
          ),
        ),
      );
      expect(
        () => reader.readSpeciesById(workspace, 'bulbasaur'),
        throwsA(
          isA<EditorPersistenceException>().having(
            (error) => error.message,
            'message',
            contains('Invalid JSON'),
          ),
        ),
      );
    });

    test('throws explicit error when multiple species files resolve to same id',
        () async {
      await seedUseCase.execute(workspace);

      final duplicateFile = File(
        workspace.resolveProjectRelativePath(
          'data/pokemon/species/9999-bulbasaur.json',
        ),
      );
      await duplicateFile.writeAsString('''
{
  "id": "bulbasaur",
  "nationalDex": 9999,
  "names": {
    "en": "Bulbasaur Duplicate"
  },
  "typing": {
    "types": ["grass"]
  }
}
''');

      expect(
        () => reader.readSpeciesById(workspace, 'bulbasaur'),
        throwsA(
          isA<EditorConflictException>().having(
            (error) => error.message,
            'message',
            contains('Multiple Pokemon species files share the same id "bulbasaur"'),
          ),
        ),
      );
    });

    test('reads from workspace root even if Directory.current points elsewhere',
        () async {
      await seedUseCase.execute(workspace);

      final decoy = await Directory.systemTemp.createTemp('pokemon_reader_decoy_');
      final originalCurrent = Directory.current;
      try {
        await Directory(
          p.join(decoy.path, 'data', 'pokemon', 'species'),
        ).create(recursive: true);
        await File(
          p.join(decoy.path, 'data', 'pokemon', 'species', '9999-decoy.json'),
        ).writeAsString('{"id":"decoy","nationalDex":9999}');

        Directory.current = decoy.path;

        final species = await reader.readSpeciesById(workspace, 'bulbasaur');
        final listed = await reader.listSpeciesFiles(workspace);
        final indexed = await reader.listSpeciesIndexEntries(workspace);

        expect(species.id, 'bulbasaur');
        expect(listed, contains('data/pokemon/species/0001-bulbasaur.json'));
        expect(listed.any((path) => path.contains('9999-decoy')), isFalse);
        expect(indexed.any((entry) => entry.id == 'decoy'), isFalse);
      } finally {
        Directory.current = originalCurrent.path;
        if (await decoy.exists()) {
          await decoy.delete(recursive: true);
        }
      }
    });

    test('leaves project.json strictly unchanged after reads', () async {
      final createProjectUseCase = CreateProjectUseCase(
        FileProjectRepository(),
        const FileProjectWorkspaceFactory(),
      );
      await createProjectUseCase.execute('Pokemon Reader Project', tempProjectRoot.path);
      await seedUseCase.execute(workspace);

      final projectFile = File(workspace.projectManifestPath);
      final before = await projectFile.readAsString();

      await reader.readManifest(workspace);
      await reader.readCatalogByKey(workspace, 'moves');
      await reader.readSpeciesById(workspace, 'bulbasaur');
      await reader.readLearnsetById(workspace, 'bulbasaur');
      await reader.readEvolutionById(workspace, 'bulbasaur');
      await reader.listSpeciesFiles(workspace);
      await reader.listSpeciesIndexEntries(workspace);

      final after = await projectFile.readAsString();
      expect(after, before);
    });
  });
}
