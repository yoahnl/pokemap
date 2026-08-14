import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/errors/application_errors.dart';
import 'package:map_editor/src/application/services/pokemon_project_data_reader.dart';
import 'package:map_editor/src/application/use_cases/delete_pokedex_species_use_case.dart';
import 'package:map_editor/src/application/use_cases/initialize_pokemon_project_storage_use_case.dart';
import 'package:map_editor/src/application/use_cases/seed_pokemon_demo_data_use_case.dart';
import 'package:map_editor/src/infrastructure/filesystem/project_filesystem.dart';
import 'package:map_editor/src/infrastructure/repositories/file_repositories.dart';

void main() {
  late Directory projectRoot;
  late ProjectFileSystem workspace;
  late _CountingPokemonSpeciesSnapshotMetrics metrics;
  late PokemonProjectDataReader reader;
  late SeedPokemonDemoDataUseCase seedUseCase;

  setUp(() async {
    projectRoot = await Directory.systemTemp.createTemp(
      'pokemon_species_snapshot_',
    );
    workspace = ProjectFileSystem(projectRoot.path);
    metrics = _CountingPokemonSpeciesSnapshotMetrics();
    reader = PokemonProjectDataReader(snapshotMetrics: metrics);
    seedUseCase = SeedPokemonDemoDataUseCase(
      snapshotController: FilePokemonReadRepository(reader: reader),
    );
  });

  tearDown(() async {
    if (await projectRoot.exists()) {
      await projectRoot.delete(recursive: true);
    }
  });

  test(
    'reuses one snapshot for concurrent and repeated species lookups',
    () async {
      await seedUseCase.execute(workspace);

      final species = await Future.wait(<Future<PokemonSpeciesFile>>[
        reader.readSpeciesById(workspace, 'bulbasaur'),
        reader.readSpeciesById(workspace, 'ivysaur'),
        reader.readSpeciesById(workspace, 'bulbasaur'),
      ]);
      await reader.listSpeciesIndexEntries(workspace);
      await reader.resolveSpeciesRelativePathById(workspace, 'ivysaur');

      expect(species.map((value) => value.id), <String>[
        'bulbasaur',
        'ivysaur',
        'bulbasaur',
      ]);
      expect(metrics.snapshotBuilds, 1);
      expect(metrics.directoryListings, 1);
      expect(metrics.speciesJsonReads, 2);
    },
  );

  test(
    'reuses one snapshot across workspace objects for the same root',
    () async {
      await seedUseCase.execute(workspace);
      final otherWorkspace = ProjectFileSystem(projectRoot.path);

      final first = await reader.readSpeciesById(workspace, 'bulbasaur');
      final second = await reader.readSpeciesById(otherWorkspace, 'ivysaur');

      expect(first.id, 'bulbasaur');
      expect(second.id, 'ivysaur');
      expect(metrics.snapshotBuilds, 1);
      expect(metrics.directoryListings, 1);
      expect(metrics.speciesJsonReads, 2);
    },
  );

  test(
    'rejects duplicate ids deterministically from the shared snapshot',
    () async {
      await seedUseCase.execute(workspace);
      final source = File(
        workspace.resolveProjectRelativePath(
          'data/pokemon/species/0001-bulbasaur.json',
        ),
      );
      await source.copy(
        workspace.resolveProjectRelativePath(
          'data/pokemon/species/9999-bulbasaur-copy.json',
        ),
      );

      await expectLater(
        reader.readSpeciesById(workspace, 'bulbasaur'),
        throwsA(
          isA<EditorConflictException>().having(
            (error) => error.message,
            'message',
            contains('Multiple Pokemon species files share the same id'),
          ),
        ),
      );
      expect(metrics.snapshotBuilds, 1);
      expect(metrics.directoryListings, 1);
      expect(metrics.speciesJsonReads, 3);
    },
  );

  test(
    'invalidates the shared workspace snapshot after a successful write',
    () async {
      await seedUseCase.execute(workspace);
      final mutationWorkspace = ProjectFileSystem(projectRoot.path);
      final repository = FilePokemonWriteRepository(reader: reader);
      final original = await reader.readSpeciesById(workspace, 'bulbasaur');
      final json = original.toJson().cast<String, dynamic>();
      json['names'] = <String, String>{'en': 'Bulbasaur Updated'};

      await repository.saveSpecies(
        mutationWorkspace,
        PokemonSpeciesFile.fromJson(json),
      );
      final updated = await reader.readSpeciesById(workspace, 'bulbasaur');

      expect(updated.names['en'], 'Bulbasaur Updated');
      expect(metrics.snapshotBuilds, 2);
      expect(metrics.directoryListings, 2);
      expect(metrics.speciesJsonReads, 4);
    },
  );

  test(
    'retries a failed snapshot construction after the source is repaired',
    () async {
      await seedUseCase.execute(workspace);
      final ivysaurFile = File(
        workspace.resolveProjectRelativePath(
          'data/pokemon/species/0002-ivysaur.json',
        ),
      );
      final original = await ivysaurFile.readAsString();
      await ivysaurFile.writeAsString('{ invalid json');

      await expectLater(
        reader.readSpeciesById(workspace, 'bulbasaur'),
        throwsA(isA<EditorPersistenceException>()),
      );
      await ivysaurFile.writeAsString(original);

      final species = await reader.readSpeciesById(workspace, 'bulbasaur');

      expect(species.id, 'bulbasaur');
      expect(metrics.snapshotBuilds, 2);
      expect(metrics.directoryListings, 2);
      expect(metrics.speciesJsonReads, 4);
    },
  );

  test(
    'invalidates the shared root snapshot after demo species are seeded',
    () async {
      await const InitializePokemonProjectStorageUseCase().execute(workspace);
      expect(await reader.listSpeciesIndexEntries(workspace), isEmpty);
      final mutationWorkspace = ProjectFileSystem(projectRoot.path);

      await SeedPokemonDemoDataUseCase(
        snapshotController: FilePokemonReadRepository(reader: reader),
      ).execute(mutationWorkspace);
      final entries = await reader.listSpeciesIndexEntries(workspace);

      expect(entries.map((entry) => entry.id), <String>[
        'bulbasaur',
        'ivysaur',
      ]);
      expect(metrics.snapshotBuilds, 2);
      expect(metrics.directoryListings, 2);
      expect(metrics.speciesJsonReads, 2);
    },
  );

  test('invalidates the shared workspace snapshot after deletion', () async {
    await seedUseCase.execute(workspace);
    final repository = FilePokemonReadRepository(reader: reader);
    await reader.readSpeciesById(workspace, 'bulbasaur');

    await DeletePokedexSpeciesUseCase(
      readRepository: repository,
    ).execute(workspace, 'bulbasaur');

    await expectLater(
      reader.readSpeciesById(workspace, 'bulbasaur'),
      throwsA(isA<EditorNotFoundException>()),
    );
    expect(metrics.snapshotBuilds, 2);
    expect(metrics.directoryListings, 2);
    expect(metrics.speciesJsonReads, 3);
  });

  test('isolates snapshots for different project workspaces', () async {
    final otherRoot = await Directory.systemTemp.createTemp(
      'pokemon_species_snapshot_other_',
    );
    try {
      final otherWorkspace = ProjectFileSystem(otherRoot.path);
      await seedUseCase.execute(workspace);
      await seedUseCase.execute(otherWorkspace);
      final otherSpeciesFile = File(
        otherWorkspace.resolveProjectRelativePath(
          'data/pokemon/species/0001-bulbasaur.json',
        ),
      );
      final otherJson =
          jsonDecode(await otherSpeciesFile.readAsString())
              as Map<String, dynamic>;
      otherJson['names'] = <String, String>{'en': 'Other Bulbasaur'};
      await otherSpeciesFile.writeAsString(jsonEncode(otherJson));

      final first = await reader.readSpeciesById(workspace, 'bulbasaur');
      final second = await reader.readSpeciesById(otherWorkspace, 'bulbasaur');

      expect(first.names['en'], 'Bulbasaur');
      expect(second.names['en'], 'Other Bulbasaur');
      expect(metrics.snapshotBuilds, 2);
      expect(metrics.directoryListings, 2);
      expect(metrics.speciesJsonReads, 4);
    } finally {
      if (await otherRoot.exists()) {
        await otherRoot.delete(recursive: true);
      }
    }
  });

  test(
    'keeps index order deterministic when files are created in reverse',
    () async {
      final speciesDirectory = Directory(
        workspace.resolveProjectRelativePath('data/pokemon/species'),
      );
      await speciesDirectory.create(recursive: true);
      await File(
        '${speciesDirectory.path}/z-ivysaur.json',
      ).writeAsString(jsonEncode(_speciesJson(id: 'ivysaur', nationalDex: 2)));
      await File('${speciesDirectory.path}/a-bulbasaur.json').writeAsString(
        jsonEncode(_speciesJson(id: 'bulbasaur', nationalDex: 1)),
      );

      final entries = await reader.listSpeciesIndexEntries(workspace);

      expect(entries.map((entry) => entry.id), <String>[
        'bulbasaur',
        'ivysaur',
      ]);
      expect(metrics.snapshotBuilds, 1);
      expect(metrics.directoryListings, 1);
      expect(metrics.speciesJsonReads, 2);
    },
  );
}

Map<String, Object?> _speciesJson({
  required String id,
  required int nationalDex,
}) {
  return <String, Object?>{
    'id': id,
    'slug': id,
    'nationalDex': nationalDex,
    'names': <String, String>{'en': id},
    'typing': <String, Object?>{
      'types': <String>['grass'],
    },
  };
}

class _CountingPokemonSpeciesSnapshotMetrics
    extends PokemonSpeciesSnapshotMetrics {
  int snapshotBuilds = 0;
  int directoryListings = 0;
  int speciesJsonReads = 0;

  @override
  void onSnapshotBuildStarted(String projectRoot, String relativeDirectory) {
    snapshotBuilds++;
  }

  @override
  void onSpeciesDirectoryListed(String projectRoot, String relativeDirectory) {
    directoryListings++;
  }

  @override
  void onSpeciesJsonRead(String projectRoot, String relativePath) {
    speciesJsonReads++;
  }
}
