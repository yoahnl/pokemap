import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/application/errors/application_errors.dart';
import 'package:map_editor/src/application/models/pokemon_database_index.dart';
import 'package:map_editor/src/application/models/pokemon_project_data_models.dart';
import 'package:map_editor/src/application/services/pokemon_database_index.dart';
import 'package:map_editor/src/application/use_cases/project_management_use_cases.dart';
import 'package:map_editor/src/application/use_cases/seed_pokemon_demo_data_use_case.dart';
import 'package:map_editor/src/infrastructure/filesystem/project_filesystem.dart';
import 'package:map_editor/src/infrastructure/repositories/file_repositories.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory tempProjectRoot;
  late String repoRootPath;
  late ProjectFileSystem workspace;
  late FileProjectRepository projectRepository;
  late FilePokemonReadRepository pokemonReadRepository;
  late PokemonDatabaseIndex indexService;
  late CreateProjectUseCase createProjectUseCase;
  late SeedPokemonDemoDataUseCase seedUseCase;

  setUp(() async {
    tempProjectRoot = await Directory.systemTemp.createTemp('pokemon_index_');
    repoRootPath = _resolveRepositoryRootFromCurrentDirectory();
    workspace = ProjectFileSystem(tempProjectRoot.path);
    projectRepository = FileProjectRepository();
    pokemonReadRepository = const FilePokemonReadRepository();
    indexService = PokemonDatabaseIndex(
      projectRepository: projectRepository,
      pokemonReadRepository: pokemonReadRepository,
    );
    createProjectUseCase = CreateProjectUseCase(
      projectRepository,
      const FileProjectWorkspaceFactory(),
    );
    seedUseCase = const SeedPokemonDemoDataUseCase();
  });

  tearDown(() async {
    if (await tempProjectRoot.exists()) {
      await tempProjectRoot.delete(recursive: true);
    }
  });

  group('PokemonSpeciesIndexEntry.fromJson', () {
    test('keeps the historical lightweight projection local to the model', () {
      // Ce test verrouille explicitement la retenue demandee pour le mini-fix
      // final du lot 11 :
      // - la projection legacy continue de lire du JSON brut ;
      // - elle ne depend pas du contrat complet de `PokemonSpeciesFile` ;
      // - le durcissement du lot 11 reste local au pipeline
      //   `PokemonDatabaseIndex`, pas a ce modele historique.
      final entry = PokemonSpeciesIndexEntry.fromJson(
        <String, dynamic>{
          'id': 'bulbasaur',
          'nationalDex': 1,
          'names': <String, String>{'en': 'Bulbasaur'},
          'typing': <String, dynamic>{
            'types': <String>['grass', 'poison'],
          },
        },
        relativePath: 'data/pokemon/species/0001-bulbasaur.json',
      );

      expect(entry.id, 'bulbasaur');
      expect(entry.nationalDex, 1);
      expect(entry.primaryName, 'Bulbasaur');
      expect(entry.types, <String>['grass', 'poison']);
      expect(entry.relativePath, 'data/pokemon/species/0001-bulbasaur.json');
    });
  });

  group('PokemonDatabaseIndex', () {
    test('indexes seeded species with the minimal list projection', () async {
      await _createProjectAndSeedDemoData(
        createProjectUseCase,
        seedUseCase,
        workspace,
        tempProjectRoot.path,
      );

      final entries = await indexService.build(workspace);
      final speciesIndexEntries =
          await pokemonReadRepository.listSpeciesIndexEntries(workspace);

      expect(entries, hasLength(2));

      final bulbasaur = entries.firstWhere((entry) => entry.id == 'bulbasaur');
      final bulbasaurSpeciesIndex = speciesIndexEntries.firstWhere(
        (entry) => entry.id == 'bulbasaur',
      );
      expect(bulbasaur.nationalDex, 1);
      expect(bulbasaur.primaryName, 'Bulbasaur');
      // Lot 13 : on réutilise l'index local du lot 11 pour alimenter la liste
      // Pokédex simple. On y expose donc aussi les types, déjà disponibles dans
      // la projection légère d'espèce, sans créer un pipeline parallèle.
      expect(bulbasaur.types, <String>['grass', 'poison']);
      // Lot 15 : la génération est déjà lisible dans `PokemonSpeciesFile`.
      // L'exposer ici permet un filtre UI local sans inventer un nouveau
      // pipeline ni relire autrement les species depuis le workspace Pokédex.
      expect(bulbasaur.genIntroduced, 1);
      expect(bulbasaur.id, bulbasaurSpeciesIndex.id);
      expect(bulbasaur.nationalDex, bulbasaurSpeciesIndex.nationalDex);
      expect(bulbasaur.primaryName, bulbasaurSpeciesIndex.primaryName);
      expect(bulbasaur.types, bulbasaurSpeciesIndex.types);
      expect(
        bulbasaur.refs,
        isA<PokemonDatabaseIndexRefs>()
            .having((refs) => refs.learnset, 'learnset', 'bulbasaur')
            .having((refs) => refs.evolution, 'evolution', 'bulbasaur')
            .having((refs) => refs.spriteSet, 'spriteSet', 'bulbasaur')
            .having((refs) => refs.cry, 'cry', 'bulbasaur'),
      );
    });

    test(
        'fails explicitly when a species json is syntactically valid but structurally invalid',
        () async {
      await createProjectUseCase.execute(
        'Pokemon Structurally Invalid Species Index Project',
        tempProjectRoot.path,
      );

      final speciesDir = Directory(
        workspace.resolveProjectRelativePath('data/pokemon/species'),
      );
      await speciesDir.create(recursive: true);
      await File(
        p.join(speciesDir.path, '0001-invalid.json'),
      ).writeAsString('''
{
  "id": "",
  "nationalDex": 0,
  "names": {},
  "typing": {"types": ["grass"]},
  "learnsetRef": "",
  "evolutionRef": "",
  "spriteSetRef": "",
  "cryRef": ""
}
''');

      expect(
        () => indexService.build(workspace),
        throwsA(
          isA<EditorPersistenceException>().having(
            (error) => error.message,
            'message',
            contains('non-empty id'),
          ),
        ),
      );
    });

    test('uses the project pokemon speciesDir instead of a hardcoded path',
        () async {
      await _createProjectAndSeedDemoData(
        createProjectUseCase,
        seedUseCase,
        workspace,
        tempProjectRoot.path,
      );

      final originalManifest = await projectRepository.loadProject(
        workspace.projectManifestPath,
      );
      const customSpeciesDir = 'data/pokemon/custom_species';

      // On deplace seulement les species pour prouver que le service lit la
      // config projet, pas le chemin historique hardcode de la couche legacy.
      final originalSpeciesDir = Directory(
        workspace
            .resolveProjectRelativePath(originalManifest.pokemon.speciesDir),
      );
      final targetSpeciesDir = Directory(
        workspace.resolveProjectRelativePath(customSpeciesDir),
      );
      await targetSpeciesDir.create(recursive: true);

      await for (final entity in originalSpeciesDir.list(recursive: false)) {
        if (entity is File) {
          await entity
              .rename(p.join(targetSpeciesDir.path, p.basename(entity.path)));
        }
      }

      await File(
        workspace.resolveProjectRelativePath(
          'data/pokemon/species/9999-decoy.json',
        ),
      ).create(recursive: true);
      await File(
        workspace.resolveProjectRelativePath(
          'data/pokemon/species/9999-decoy.json',
        ),
      ).writeAsString('''
{
  "id": "decoy",
  "nationalDex": 9999,
  "names": {
    "en": "Decoy"
  },
  "learnsetRef": "decoy",
  "evolutionRef": "decoy",
  "spriteSetRef": "decoy",
  "cryRef": "decoy"
}
''');

      final updatedManifest = originalManifest.copyWith(
        pokemon: originalManifest.pokemon.copyWith(
          speciesDir: customSpeciesDir,
        ),
      );
      await projectRepository.saveProject(
        updatedManifest,
        workspace.projectManifestPath,
      );

      final entries = await indexService.build(workspace);

      expect(
          entries.map((entry) => entry.id),
          containsAll(<String>[
            'bulbasaur',
            'ivysaur',
          ]));
      expect(entries.map((entry) => entry.id), isNot(contains('decoy')));
    });

    test(
        'returns an empty index when the configured species directory is empty',
        () async {
      await createProjectUseCase.execute(
        'Pokemon Empty Index Project',
        tempProjectRoot.path,
      );

      final manifest = await projectRepository.loadProject(
        workspace.projectManifestPath,
      );
      const customSpeciesDir = 'data/pokemon/empty_species';
      await Directory(
        workspace.resolveProjectRelativePath(customSpeciesDir),
      ).create(recursive: true);
      await projectRepository.saveProject(
        manifest.copyWith(
          pokemon: manifest.pokemon.copyWith(speciesDir: customSpeciesDir),
        ),
        workspace.projectManifestPath,
      );

      final entries = await indexService.build(workspace);

      expect(entries, isEmpty);
    });

    test('fails explicitly when a species json file is invalid', () async {
      await createProjectUseCase.execute(
        'Pokemon Invalid Species Index Project',
        tempProjectRoot.path,
      );

      final invalidSpeciesDir = Directory(
        workspace.resolveProjectRelativePath('data/pokemon/species'),
      );
      await invalidSpeciesDir.create(recursive: true);
      await File(
        p.join(invalidSpeciesDir.path, '0001-bulbasaur.json'),
      ).writeAsString('{ invalid json');

      expect(
        () => indexService.build(workspace),
        throwsA(
          isA<EditorPersistenceException>().having(
            (error) => error.message,
            'message',
            contains('Invalid JSON'),
          ),
        ),
      );
    });

    test('does not load learnsets evolutions or media during indexing',
        () async {
      await _createProjectAndSeedDemoData(
        createProjectUseCase,
        seedUseCase,
        workspace,
        tempProjectRoot.path,
      );

      await File(
        workspace.resolveProjectRelativePath(
          'data/pokemon/learnsets/bulbasaur.json',
        ),
      ).writeAsString('{ invalid json');
      await File(
        workspace.resolveProjectRelativePath(
          'data/pokemon/evolutions/bulbasaur.json',
        ),
      ).writeAsString('{ invalid json');

      await Directory(
        workspace.resolveProjectRelativePath('data/pokemon/media'),
      ).create(recursive: true);
      await File(
        workspace
            .resolveProjectRelativePath('data/pokemon/media/bulbasaur.json'),
      ).writeAsString('{ invalid json');

      final entries = await indexService.build(workspace);

      expect(entries.map((entry) => entry.id), contains('bulbasaur'));
      expect(entries.map((entry) => entry.id), contains('ivysaur'));
    });

    test('reads from the workspace project and not Directory.current',
        () async {
      await _createProjectAndSeedDemoData(
        createProjectUseCase,
        seedUseCase,
        workspace,
        tempProjectRoot.path,
      );

      final decoy =
          await Directory.systemTemp.createTemp('pokemon_index_decoy_');
      final originalCurrent = Directory.current;
      try {
        await Directory(
          p.join(decoy.path, 'data', 'pokemon', 'species'),
        ).create(recursive: true);
        await File(
          p.join(decoy.path, 'data', 'pokemon', 'species', '9999-decoy.json'),
        ).writeAsString('''
{
  "id": "decoy",
  "nationalDex": 9999,
  "names": {
    "en": "Decoy"
  },
  "learnsetRef": "decoy",
  "evolutionRef": "decoy",
  "spriteSetRef": "decoy",
  "cryRef": "decoy"
}
''');

        Directory.current = decoy.path;

        final entries = await indexService.build(workspace);

        expect(entries.any((entry) => entry.id == 'decoy'), isFalse);
        expect(entries.any((entry) => entry.id == 'bulbasaur'), isTrue);
      } finally {
        Directory.current = originalCurrent.path;
        if (await decoy.exists()) {
          await decoy.delete(recursive: true);
        }
      }
    });

    test('leaves project.json strictly unchanged', () async {
      await _createProjectAndSeedDemoData(
        createProjectUseCase,
        seedUseCase,
        workspace,
        tempProjectRoot.path,
      );

      final projectFile = File(workspace.projectManifestPath);
      final before = await projectFile.readAsString();

      await indexService.build(workspace);

      final after = await projectFile.readAsString();
      expect(after, before);
    });

    test('does not recreate data or assets at the monorepo root', () async {
      await _createProjectAndSeedDemoData(
        createProjectUseCase,
        seedUseCase,
        workspace,
        tempProjectRoot.path,
      );

      await indexService.build(workspace);

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

Future<void> _createProjectAndSeedDemoData(
  CreateProjectUseCase createProjectUseCase,
  SeedPokemonDemoDataUseCase seedUseCase,
  ProjectFileSystem workspace,
  String projectRootPath,
) async {
  await createProjectUseCase.execute(
    'Pokemon Database Index Project',
    projectRootPath,
  );
  await seedUseCase.execute(workspace);
}
