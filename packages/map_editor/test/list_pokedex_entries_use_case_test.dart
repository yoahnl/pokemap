import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/application/errors/application_errors.dart';
import 'package:map_editor/src/application/models/pokemon_database_index.dart';
import 'package:map_editor/src/application/models/pokedex_list_entry.dart';
import 'package:map_editor/src/application/models/pokemon_project_data_models.dart';
import 'package:map_editor/src/application/ports/pokemon_read_repository.dart';
import 'package:map_editor/src/application/ports/project_workspace.dart';
import 'package:map_editor/src/application/use_cases/list_pokedex_entries_use_case.dart';
import 'package:map_editor/src/application/use_cases/project_management_use_cases.dart';
import 'package:map_editor/src/application/use_cases/seed_pokemon_demo_data_use_case.dart';
import 'package:map_editor/src/infrastructure/filesystem/project_filesystem.dart';
import 'package:map_editor/src/infrastructure/repositories/file_repositories.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory tempProjectRoot;
  late ProjectFileSystem workspace;

  setUp(() async {
    tempProjectRoot = await Directory.systemTemp.createTemp('pokedex_list_');
    workspace = ProjectFileSystem(tempProjectRoot.path);
  });

  tearDown(() async {
    if (await tempProjectRoot.exists()) {
      await tempProjectRoot.delete(recursive: true);
    }
  });

  group('ListPokedexEntriesUseCase with abstract repository', () {
    test('returns a sorted pokedex list from the project workspace', () async {
      final repository = _RecordingPokemonReadRepository(
        indexEntries: <PokemonSpeciesIndexEntry>[
          const PokemonSpeciesIndexEntry(
            id: 'ivysaur',
            nationalDex: 2,
            primaryName: 'Ivysaur',
            types: <String>['grass', 'poison'],
            relativePath: 'data/pokemon/species/0002-ivysaur.json',
          ),
          const PokemonSpeciesIndexEntry(
            id: 'bulbasaur',
            nationalDex: 1,
            primaryName: 'Bulbasaur',
            types: <String>['grass', 'poison'],
            relativePath: 'data/pokemon/species/0001-bulbasaur.json',
          ),
        ],
        speciesById: <String, PokemonSpeciesFile>{
          'bulbasaur': _species(
            id: 'bulbasaur',
            nationalDex: 1,
            starterEligible: true,
            genIntroduced: 1,
          ),
          'ivysaur': _species(
            id: 'ivysaur',
            nationalDex: 2,
            starterEligible: false,
            genIntroduced: 1,
          ),
        },
      );
      final useCase = ListPokedexEntriesUseCase(repository);

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
      expect(repository.workspacesSeen, everyElement(same(workspace)));
    });

    test('does not expose filesystem concerns in the application model',
        () async {
      final repository = _RecordingPokemonReadRepository(
        indexEntries: <PokemonSpeciesIndexEntry>[
          const PokemonSpeciesIndexEntry(
            id: 'bulbasaur',
            nationalDex: 1,
            primaryName: 'Bulbasaur',
            types: <String>['grass', 'poison'],
            relativePath: 'data/pokemon/species/0001-bulbasaur.json',
          ),
        ],
        speciesById: <String, PokemonSpeciesFile>{
          'bulbasaur': _species(
            id: 'bulbasaur',
            nationalDex: 1,
            starterEligible: true,
            genIntroduced: 1,
          ),
        },
      );
      final useCase = ListPokedexEntriesUseCase(repository);

      final entries = await useCase.execute(workspace);
      final PokedexListEntry entry = entries.first;
      final dynamic dynamicEntry = entry;

      expect(
          () => dynamicEntry.relativePath, throwsA(isA<NoSuchMethodError>()));
    });

    test('returns starter eligibility from species gameplay flags', () async {
      final repository = _RecordingPokemonReadRepository(
        indexEntries: <PokemonSpeciesIndexEntry>[
          const PokemonSpeciesIndexEntry(
            id: 'bulbasaur',
            nationalDex: 1,
            primaryName: 'Bulbasaur',
            types: <String>['grass', 'poison'],
            relativePath: 'data/pokemon/species/0001-bulbasaur.json',
          ),
          const PokemonSpeciesIndexEntry(
            id: 'ivysaur',
            nationalDex: 2,
            primaryName: 'Ivysaur',
            types: <String>['grass', 'poison'],
            relativePath: 'data/pokemon/species/0002-ivysaur.json',
          ),
        ],
        speciesById: <String, PokemonSpeciesFile>{
          'bulbasaur': _species(
            id: 'bulbasaur',
            nationalDex: 1,
            starterEligible: true,
            genIntroduced: 1,
          ),
          'ivysaur': _species(
            id: 'ivysaur',
            nationalDex: 2,
            starterEligible: false,
            genIntroduced: 1,
          ),
        },
      );
      final useCase = ListPokedexEntriesUseCase(repository);

      final entries = await useCase.execute(workspace);

      final bulbasaur = entries.firstWhere((entry) => entry.id == 'bulbasaur');
      final ivysaur = entries.firstWhere((entry) => entry.id == 'ivysaur');
      expect(bulbasaur.isStarterEligible, isTrue);
      expect(ivysaur.isStarterEligible, isFalse);
    });

    test('fails explicitly when repository species data is invalid', () async {
      final repository = _RecordingPokemonReadRepository(
        indexEntries: <PokemonSpeciesIndexEntry>[
          const PokemonSpeciesIndexEntry(
            id: 'bulbasaur',
            nationalDex: 1,
            primaryName: 'Bulbasaur',
            types: <String>['grass', 'poison'],
            relativePath: 'data/pokemon/species/0001-bulbasaur.json',
          ),
        ],
        speciesError:
            const EditorPersistenceException('Invalid JSON in species'),
      );
      final useCase = ListPokedexEntriesUseCase(repository);

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

  group('ListPokedexEntriesUseCase with filesystem repository', () {
    late SeedPokemonDemoDataUseCase seedUseCase;
    late ListPokedexEntriesUseCase useCase;

    setUp(() {
      seedUseCase = const SeedPokemonDemoDataUseCase();
      useCase = const ListPokedexEntriesUseCase(FilePokemonReadRepository());
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

        final entries = await useCase.execute(workspace);

        expect(entries.map((entry) => entry.id), isNot(contains('venusaur')));
        expect(
            entries.map((entry) => entry.id),
            containsAll(<String>[
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
      await createProjectUseCase.execute(
        'Pokedex List Project',
        tempProjectRoot.path,
      );
      await seedUseCase.execute(workspace);

      final projectFile = File(workspace.projectManifestPath);
      final before = await projectFile.readAsString();

      await useCase.execute(workspace);

      final after = await projectFile.readAsString();
      expect(after, before);
    });
  });
}

class _RecordingPokemonReadRepository implements PokemonReadRepository {
  _RecordingPokemonReadRepository({
    required this.indexEntries,
    this.speciesById = const <String, PokemonSpeciesFile>{},
    this.speciesError,
  });

  final List<PokemonSpeciesIndexEntry> indexEntries;
  final Map<String, PokemonSpeciesFile> speciesById;
  final EditorApplicationException? speciesError;
  final List<ProjectWorkspace> workspacesSeen = <ProjectWorkspace>[];

  @override
  Future<List<PokemonSpeciesIndexEntry>> listSpeciesIndexEntries(
    ProjectWorkspace workspace,
  ) async {
    workspacesSeen.add(workspace);
    return indexEntries;
  }

  @override
  Future<List<PokemonDatabaseIndexEntry>> listDatabaseIndexEntries(
    ProjectWorkspace workspace, {
    required String speciesDirectoryRelativePath,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<PokemonSpeciesFile> readSpeciesById(
    ProjectWorkspace workspace,
    String speciesId,
  ) async {
    workspacesSeen.add(workspace);
    if (speciesError != null) {
      throw speciesError!;
    }
    final species = speciesById[speciesId];
    if (species == null) {
      throw EditorNotFoundException('Pokemon species not found: $speciesId');
    }
    return species;
  }

  @override
  Future<PokemonCatalogFile> readCatalogByKey(
    ProjectWorkspace workspace,
    String catalogKey,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<PokemonEvolutionFile> readEvolutionById(
    ProjectWorkspace workspace,
    String speciesId,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<PokemonMediaFile> readMediaById(
    ProjectWorkspace workspace,
    String speciesId,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<PokemonLearnsetFile> readLearnsetById(
    ProjectWorkspace workspace,
    String speciesId,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<PokemonDataManifest> readManifest(ProjectWorkspace workspace) {
    throw UnimplementedError();
  }

  @override
  Future<List<String>> listEvolutionIds(ProjectWorkspace workspace) {
    throw UnimplementedError();
  }

  @override
  Future<List<String>> listLearnsetIds(ProjectWorkspace workspace) {
    throw UnimplementedError();
  }

  @override
  Future<List<String>> listMediaIds(ProjectWorkspace workspace) {
    throw UnimplementedError();
  }

  @override
  Future<List<String>> listSpeciesFiles(ProjectWorkspace workspace) {
    throw UnimplementedError();
  }

  @override
  Future<PokemonSpeciesFile> readSpeciesByRelativePath(
    ProjectWorkspace workspace,
    String relativePath,
  ) {
    throw UnimplementedError();
  }
}

PokemonSpeciesFile _species({
  required String id,
  required int nationalDex,
  required bool starterEligible,
  required int genIntroduced,
}) {
  return PokemonSpeciesFile(
    id: id,
    slug: id,
    nationalDex: nationalDex,
    names: <String, String>{'en': id == 'bulbasaur' ? 'Bulbasaur' : 'Ivysaur'},
    speciesName: const <String, String>{'en': 'Seed Pokemon'},
    genIntroduced: genIntroduced,
    typing: const PokemonSpeciesTyping(types: <String>['grass', 'poison']),
    baseStats: const PokemonSpeciesBaseStats(
      hp: 45,
      atk: 49,
      def: 49,
      spa: 65,
      spd: 65,
      spe: 45,
      bst: 318,
    ),
    abilities: const PokemonSpeciesAbilities(
      primary: 'overgrow',
      hidden: 'chlorophyll',
    ),
    breeding: const PokemonSpeciesBreeding(
      genderRatio: <String, double>{'male': 0.875, 'female': 0.125},
      eggGroups: <String>['monster', 'grass'],
      hatchCycles: 20,
    ),
    progression: const PokemonSpeciesProgression(
      growthRateId: 'medium_slow',
      baseExp: 64,
      catchRate: 45,
      baseFriendship: 50,
    ),
    refs: PokemonSpeciesRefs(
      learnset: id,
      evolution: id,
      media: id,
    ),
    dexContent: const PokemonSpeciesDexContent(
      heightM: 0.7,
      weightKg: 6.9,
      color: 'green',
      flavorText: 'Demo entry',
    ),
    gameplayFlags: PokemonSpeciesGameplayFlags(
      starterEligible: starterEligible,
    ),
    sourceMeta: const PokemonSpeciesSourceMeta(
      seededBy: 'test',
      seedVersion: 1,
    ),
  );
}
