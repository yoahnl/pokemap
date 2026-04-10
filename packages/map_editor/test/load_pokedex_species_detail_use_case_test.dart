import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/application/errors/application_errors.dart';
import 'package:map_editor/src/application/models/pokedex_species_detail.dart';
import 'package:map_editor/src/application/models/pokemon_database_index.dart';
import 'package:map_editor/src/application/models/pokemon_project_data_models.dart';
import 'package:map_editor/src/application/ports/pokemon_read_repository.dart';
import 'package:map_editor/src/application/ports/project_workspace.dart';
import 'package:map_editor/src/application/use_cases/load_pokedex_species_detail_use_case.dart';

void main() {
  group('LoadPokedexSpeciesDetailUseCase', () {
    test('loads species and linked files via refs', () async {
      final repository = _FakePokemonReadRepository(
        speciesById: <String, PokemonSpeciesFile>{
          'bulbasaur': _buildSpecies(
            id: 'bulbasaur',
            learnsetRef: 'bulbasaur-learnset',
            evolutionRef: 'bulbasaur-evolution',
            mediaRef: 'bulbasaur-media',
          ),
        },
        learnsetsById: <String, PokemonLearnsetFile>{
          'bulbasaur-learnset': const PokemonLearnsetFile(
            speciesId: 'bulbasaur',
            levelUp: <PokemonLearnsetLevelUpEntry>[
              PokemonLearnsetLevelUpEntry(
                moveId: 'vine_whip',
                level: 7,
                source: 'level_up',
                versionGroup: 'scarlet-violet',
              ),
            ],
          ),
        },
        evolutionsById: <String, PokemonEvolutionFile>{
          'bulbasaur-evolution': const PokemonEvolutionFile(
            speciesId: 'bulbasaur',
            evolutions: <PokemonEvolutionEntry>[
              PokemonEvolutionEntry(
                targetSpeciesId: 'ivysaur',
                method: 'level_up',
                minLevel: 16,
              ),
            ],
          ),
        },
        mediaById: <String, PokemonMediaFile>{
          'bulbasaur-media': const PokemonMediaFile(
            speciesId: 'bulbasaur',
            defaultFormId: 'base',
            variants: <String, PokemonMediaVariant>{
              'base': PokemonMediaVariant(
                frontStatic: 'assets/pokemon/sprites/bulbasaur/front.png',
              ),
            },
          ),
        },
      );

      final useCase = LoadPokedexSpeciesDetailUseCase(repository);
      const workspace = _FakeWorkspace();

      final PokedexSpeciesDetail detail = await useCase.execute(
        workspace,
        'bulbasaur',
      );

      expect(detail.species.id, 'bulbasaur');
      expect(detail.learnset?.speciesId, 'bulbasaur');
      expect(detail.evolution?.evolutions.single.targetSpeciesId, 'ivysaur');
      expect(
        detail.media?.variants['base']?.frontStatic,
        'assets/pokemon/sprites/bulbasaur/front.png',
      );
      expect(repository.readLearnsetIds, <String>['bulbasaur-learnset']);
      expect(repository.readEvolutionIds, <String>['bulbasaur-evolution']);
      expect(repository.readMediaIds, <String>['bulbasaur-media']);
    });

    test('keeps species mandatory but tolerates missing ancillary files',
        () async {
      final repository = _FakePokemonReadRepository(
        speciesById: <String, PokemonSpeciesFile>{
          'bulbasaur': _buildSpecies(
            id: 'bulbasaur',
            learnsetRef: 'bulbasaur',
            evolutionRef: 'bulbasaur',
            mediaRef: 'bulbasaur',
          ),
        },
      );

      final useCase = LoadPokedexSpeciesDetailUseCase(repository);
      const workspace = _FakeWorkspace();

      final detail = await useCase.execute(workspace, 'bulbasaur');

      expect(detail.species.id, 'bulbasaur');
      expect(detail.learnset, isNull);
      expect(detail.evolution, isNull);
      expect(detail.media, isNull);
    });

    test('treats blank refs as absent ancillary files without reading',
        () async {
      final repository = _FakePokemonReadRepository(
        speciesById: <String, PokemonSpeciesFile>{
          'bulbasaur': _buildSpecies(
            id: 'bulbasaur',
            learnsetRef: '   ',
            evolutionRef: '',
            mediaRef: '\n',
          ),
        },
      );

      final useCase = LoadPokedexSpeciesDetailUseCase(repository);
      const workspace = _FakeWorkspace();

      final detail = await useCase.execute(workspace, 'bulbasaur');

      expect(detail.species.id, 'bulbasaur');
      expect(detail.learnset, isNull);
      expect(detail.evolution, isNull);
      expect(detail.media, isNull);
      expect(repository.readLearnsetIds, isEmpty);
      expect(repository.readEvolutionIds, isEmpty);
      expect(repository.readMediaIds, isEmpty);
    });

    test('keeps species read mandatory', () async {
      final repository = _FakePokemonReadRepository();

      final useCase = LoadPokedexSpeciesDetailUseCase(repository);

      await expectLater(
        () => useCase.execute(const _FakeWorkspace(), 'missingno'),
        throwsA(isA<Exception>()),
      );
    });

    test('rethrows unexpected ancillary read errors', () async {
      final repository = _FakePokemonReadRepository(
        speciesById: <String, PokemonSpeciesFile>{
          'bulbasaur': _buildSpecies(
            id: 'bulbasaur',
            learnsetRef: 'bulbasaur',
            evolutionRef: 'bulbasaur',
            mediaRef: 'bulbasaur',
          ),
        },
        learnsetErrorById: <String, Object>{
          'bulbasaur': const FormatException('broken learnset'),
        },
      );

      final useCase = LoadPokedexSpeciesDetailUseCase(repository);

      await expectLater(
        () => useCase.execute(const _FakeWorkspace(), 'bulbasaur'),
        throwsA(isA<FormatException>()),
      );
    });

    test('rethrows unexpected evolution read errors', () async {
      final repository = _FakePokemonReadRepository(
        speciesById: <String, PokemonSpeciesFile>{
          'bulbasaur': _buildSpecies(
            id: 'bulbasaur',
            learnsetRef: '',
            evolutionRef: 'bulbasaur',
            mediaRef: '',
          ),
        },
        evolutionErrorById: <String, Object>{
          'bulbasaur': const FormatException('broken evolution'),
        },
      );

      final useCase = LoadPokedexSpeciesDetailUseCase(repository);

      await expectLater(
        () => useCase.execute(const _FakeWorkspace(), 'bulbasaur'),
        throwsA(isA<FormatException>()),
      );
    });

    test('rethrows unexpected media read errors', () async {
      final repository = _FakePokemonReadRepository(
        speciesById: <String, PokemonSpeciesFile>{
          'bulbasaur': _buildSpecies(
            id: 'bulbasaur',
            learnsetRef: '',
            evolutionRef: '',
            mediaRef: 'bulbasaur',
          ),
        },
        mediaErrorById: <String, Object>{
          'bulbasaur': const FormatException('broken media'),
        },
      );

      final useCase = LoadPokedexSpeciesDetailUseCase(repository);

      await expectLater(
        () => useCase.execute(const _FakeWorkspace(), 'bulbasaur'),
        throwsA(isA<FormatException>()),
      );
    });
  });
}

class _FakePokemonReadRepository implements PokemonReadRepository {
  _FakePokemonReadRepository({
    this.speciesById = const <String, PokemonSpeciesFile>{},
    this.learnsetsById = const <String, PokemonLearnsetFile>{},
    this.evolutionsById = const <String, PokemonEvolutionFile>{},
    this.mediaById = const <String, PokemonMediaFile>{},
    this.learnsetErrorById = const <String, Object>{},
    this.evolutionErrorById = const <String, Object>{},
    this.mediaErrorById = const <String, Object>{},
  });

  final Map<String, PokemonSpeciesFile> speciesById;
  final Map<String, PokemonLearnsetFile> learnsetsById;
  final Map<String, PokemonEvolutionFile> evolutionsById;
  final Map<String, PokemonMediaFile> mediaById;
  final Map<String, Object> learnsetErrorById;
  final Map<String, Object> evolutionErrorById;
  final Map<String, Object> mediaErrorById;
  final List<String> readLearnsetIds = <String>[];
  final List<String> readEvolutionIds = <String>[];
  final List<String> readMediaIds = <String>[];

  @override
  Future<PokemonSpeciesFile> readSpeciesById(
    ProjectWorkspace workspace,
    String speciesId,
  ) async {
    final species = speciesById[speciesId];
    if (species == null) {
      throw Exception('missing species');
    }
    return species;
  }

  @override
  Future<PokemonLearnsetFile> readLearnsetById(
    ProjectWorkspace workspace,
    String speciesId,
  ) async {
    readLearnsetIds.add(speciesId);
    final error = learnsetErrorById[speciesId];
    if (error != null) {
      throw error;
    }
    final learnset = learnsetsById[speciesId];
    if (learnset == null) {
      throw const EditorNotFoundException('missing learnset');
    }
    return learnset;
  }

  @override
  Future<PokemonEvolutionFile> readEvolutionById(
    ProjectWorkspace workspace,
    String speciesId,
  ) async {
    readEvolutionIds.add(speciesId);
    final error = evolutionErrorById[speciesId];
    if (error != null) {
      throw error;
    }
    final evolution = evolutionsById[speciesId];
    if (evolution == null) {
      throw const EditorNotFoundException('missing evolution');
    }
    return evolution;
  }

  @override
  Future<PokemonMediaFile> readMediaById(
    ProjectWorkspace workspace,
    String speciesId,
  ) async {
    readMediaIds.add(speciesId);
    final error = mediaErrorById[speciesId];
    if (error != null) {
      throw error;
    }
    final media = mediaById[speciesId];
    if (media == null) {
      throw const EditorNotFoundException('missing media');
    }
    return media;
  }

  @override
  Future<List<PokemonDatabaseIndexEntry>> listDatabaseIndexEntries(
    ProjectWorkspace workspace, {
    required String speciesDirectoryRelativePath,
  }) =>
      throw UnimplementedError();

  @override
  Future<List<PokemonSpeciesIndexEntry>> listSpeciesIndexEntries(
    ProjectWorkspace workspace,
  ) =>
      throw UnimplementedError();

  @override
  Future<List<String>> listSpeciesFiles(ProjectWorkspace workspace) =>
      throw UnimplementedError();

  @override
  Future<PokemonSpeciesFile> readSpeciesByRelativePath(
    ProjectWorkspace workspace,
    String relativePath,
  ) =>
      throw UnimplementedError();

  @override
  Future<PokemonDataManifest> readManifest(ProjectWorkspace workspace) =>
      throw UnimplementedError();

  @override
  Future<PokemonCatalogFile> readCatalogByKey(
    ProjectWorkspace workspace,
    String catalogKey,
  ) =>
      throw UnimplementedError();

  @override
  Future<List<String>> listLearnsetIds(ProjectWorkspace workspace) =>
      throw UnimplementedError();

  @override
  Future<List<String>> listEvolutionIds(ProjectWorkspace workspace) =>
      throw UnimplementedError();

  @override
  Future<List<String>> listMediaIds(ProjectWorkspace workspace) =>
      throw UnimplementedError();
}

class _FakeWorkspace implements ProjectWorkspace {
  const _FakeWorkspace();

  @override
  String get projectRoot => '/tmp/pokedex';

  @override
  String get projectManifestPath => '/tmp/pokedex/project.json';

  @override
  String resolveMapPath(String relativePath) => '$projectRoot/$relativePath';

  @override
  String getMapPath(String mapId) => '$projectRoot/maps/$mapId.json';

  @override
  String getMapRelativePath(String mapId) => 'maps/$mapId.json';

  @override
  String resolveTilesetPath(String relativePath) =>
      '$projectRoot/$relativePath';

  @override
  String resolveProjectRelativePath(String relativePath) =>
      '$projectRoot/$relativePath';

  @override
  Future<void> ensureDirectoryExists(String path) => throw UnimplementedError();

  @override
  Future<bool> fileExists(String path) => throw UnimplementedError();

  @override
  Future<bool> directoryExists(String path) => throw UnimplementedError();

  @override
  Future<String> readTextFile(String path) => throw UnimplementedError();

  @override
  Future<void> writeTextFile(String path, String contents) =>
      throw UnimplementedError();

  @override
  Future<void> copyFile(String sourcePath, String destinationPath) =>
      throw UnimplementedError();

  @override
  Future<void> moveFile(String sourcePath, String destinationPath) =>
      throw UnimplementedError();

  @override
  Future<void> moveDirectory(String sourcePath, String destinationPath) =>
      throw UnimplementedError();

  @override
  Future<void> deleteDirectoryIfEmpty(String path) =>
      throw UnimplementedError();

  @override
  Future<String> importTilesetImage(
    String sourcePath, {
    String? preferredName,
  }) =>
      throw UnimplementedError();

  @override
  Future<void> deleteRelativeFile(String relativePath) =>
      throw UnimplementedError();
}

PokemonSpeciesFile _buildSpecies({
  required String id,
  required String learnsetRef,
  required String evolutionRef,
  required String mediaRef,
}) {
  return PokemonSpeciesFile(
    id: id,
    slug: id,
    nationalDex: 1,
    names: const <String, String>{'en': 'Bulbasaur'},
    speciesName: const <String, String>{'en': 'Seed Pokemon'},
    genIntroduced: 1,
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
    forms: const PokemonSpeciesForms(
      baseFormId: 'bulbasaur',
      isBaseForm: true,
      formId: 'base',
    ),
    classification: const PokemonSpeciesClassification(),
    refs: PokemonSpeciesRefs(
      learnset: learnsetRef,
      evolution: evolutionRef,
      media: mediaRef,
    ),
    dexContent: const PokemonSpeciesDexContent(
      heightM: 0.7,
      weightKg: 6.9,
      color: 'green',
      flavorText: 'A strange seed was planted on its back at birth.',
    ),
    gameplayFlags: const PokemonSpeciesGameplayFlags(
      starterEligible: true,
    ),
    sourceMeta: const PokemonSpeciesSourceMeta(
      seededBy: 'test',
      seedVersion: 1,
    ),
  );
}
