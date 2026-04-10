import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/application/errors/application_errors.dart';
import 'package:map_editor/src/infrastructure/filesystem/project_filesystem.dart';
import 'package:map_editor/src/infrastructure/repositories/file_repositories.dart';
import 'package:map_editor/src/application/use_cases/project_management_use_cases.dart';
import 'package:map_editor/src/application/use_cases/seed_pokemon_demo_data_use_case.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory tempProjectRoot;
  late String repoRootPath;
  late ProjectFileSystem workspace;
  late SeedPokemonDemoDataUseCase seedUseCase;
  late FilePokemonReadRepository repository;

  setUp(() async {
    tempProjectRoot = await Directory.systemTemp.createTemp('pokemon_repo_');
    repoRootPath = _resolveRepositoryRootFromCurrentDirectory();
    workspace = ProjectFileSystem(tempProjectRoot.path);
    seedUseCase = const SeedPokemonDemoDataUseCase();
    repository = const FilePokemonReadRepository();
  });

  tearDown(() async {
    if (await tempProjectRoot.exists()) {
      await tempProjectRoot.delete(recursive: true);
    }
  });

  group('FilePokemonReadRepository', () {
    test('reads from the workspace project and not the monorepo root',
        () async {
      await seedUseCase.execute(workspace);

      final decoy =
          await Directory.systemTemp.createTemp('pokemon_repo_decoy_');
      final originalCurrent = Directory.current;
      try {
        await Directory(
          p.join(decoy.path, 'data', 'pokemon', 'species'),
        ).create(recursive: true);
        await File(
          p.join(
              decoy.path, 'data', 'pokemon', 'species', '0003-venusaur.json'),
        ).writeAsString('''
{
  "id": "venusaur",
  "nationalDex": 3,
  "names": {"en": "Venusaur"},
  "typing": {"types": ["grass", "poison"]}
}
''');

        Directory.current = decoy.path;

        final entries = await repository.listSpeciesIndexEntries(workspace);
        final species =
            await repository.readSpeciesById(workspace, 'bulbasaur');

        expect(entries.map((entry) => entry.id), isNot(contains('venusaur')));
        expect(species.id, 'bulbasaur');
      } finally {
        Directory.current = originalCurrent.path;
        if (await decoy.exists()) {
          await decoy.delete(recursive: true);
        }
      }
    });

    test('reads the seeded pokemon files through the repository abstraction',
        () async {
      await seedUseCase.execute(workspace);

      final manifest = await repository.readManifest(workspace);
      final species = await repository.readSpeciesById(workspace, 'bulbasaur');
      final learnset =
          await repository.readLearnsetById(workspace, 'bulbasaur');
      final evolution =
          await repository.readEvolutionById(workspace, 'bulbasaur');
      final media = await repository.readMediaById(workspace, 'bulbasaur');
      final moves = await repository.readCatalogByKey(workspace, 'moves');

      expect(manifest.kind, 'pokemon_data_manifest');
      expect(species.id, 'bulbasaur');
      expect(learnset.speciesId, 'bulbasaur');
      expect(evolution.evolutions.single.targetSpeciesId, 'ivysaur');
      expect(media.speciesId, 'bulbasaur');
      expect(media.variants['base']?.cry, 'assets/pokemon/cries/bulbasaur.ogg');
      expect(
        moves.entries.map((entry) => entry['id']),
        containsAll(<String>['tackle', 'growl', 'vine_whip', 'razor_leaf']),
      );
    });

    test('throws explicit error when a species file is missing', () async {
      await seedUseCase.execute(workspace);

      expect(
        () => repository.readSpeciesById(workspace, 'venusaur'),
        throwsA(
          isA<EditorNotFoundException>().having(
            (error) => error.message,
            'message',
            contains('Pokemon species not found'),
          ),
        ),
      );
    });

    test('throws explicit error when a species json file is invalid', () async {
      await seedUseCase.execute(workspace);

      final speciesFile = File(
        workspace.resolveProjectRelativePath(
          'data/pokemon/species/0001-bulbasaur.json',
        ),
      );
      await speciesFile.writeAsString('{ invalid json');

      expect(
        () => repository.readSpeciesById(workspace, 'bulbasaur'),
        throwsA(
          isA<EditorPersistenceException>().having(
            (error) => error.message,
            'message',
            contains('Invalid JSON'),
          ),
        ),
      );
    });

    test('leaves project.json strictly unchanged', () async {
      final createProjectUseCase = CreateProjectUseCase(
        FileProjectRepository(),
        const FileProjectWorkspaceFactory(),
      );
      await createProjectUseCase.execute(
          'Pokemon Repo Project', tempProjectRoot.path);
      await seedUseCase.execute(workspace);

      final projectFile = File(workspace.projectManifestPath);
      final before = await projectFile.readAsString();

      await repository.readSpeciesById(workspace, 'bulbasaur');
      await repository.readCatalogByKey(workspace, 'moves');

      final after = await projectFile.readAsString();
      expect(after, before);
    });

    test('does not recreate data or assets at the monorepo root', () async {
      await seedUseCase.execute(workspace);

      await repository.listSpeciesIndexEntries(workspace);

      expect(Directory(p.join(repoRootPath, 'data')).existsSync(), isFalse);
      expect(Directory(p.join(repoRootPath, 'assets')).existsSync(), isFalse);
    });
  });
}

String _resolveRepositoryRootFromCurrentDirectory() {
  var current = Directory.current.absolute;

  while (true) {
    final agentsFile = File(p.join(current.path, 'AGENTS.md'));
    final mapEditorDir =
        Directory(p.join(current.path, 'packages', 'map_editor'));
    if (agentsFile.existsSync() && mapEditorDir.existsSync()) {
      return current.path;
    }

    final parent = current.parent;
    if (parent.path == current.path) {
      throw StateError(
        'Could not resolve repository root from Directory.current: '
        '${Directory.current.path}',
      );
    }
    current = parent;
  }
}
