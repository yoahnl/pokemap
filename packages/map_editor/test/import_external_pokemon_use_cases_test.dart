import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/application/errors/application_errors.dart';
import 'package:map_editor/src/application/models/pokemon_project_data_models.dart';
import 'package:map_editor/src/application/ports/pokemon_external_source_repository.dart';
import 'package:map_editor/src/application/services/pokeapi_pokemon_learnset_converter.dart';
import 'package:map_editor/src/application/services/showdown_pokemon_species_converter.dart';
import 'package:map_editor/src/application/use_cases/import_external_pokemon_use_cases.dart';
import 'package:map_editor/src/application/use_cases/initialize_pokemon_project_storage_use_case.dart';
import 'package:map_editor/src/application/use_cases/project_management_use_cases.dart';
import 'package:map_editor/src/infrastructure/filesystem/project_filesystem.dart';
import 'package:map_editor/src/infrastructure/repositories/file_repositories.dart';

void main() {
  late Directory tempProjectRoot;
  late ProjectFileSystem workspace;
  late ImportExternalPokemonSpeciesUseCase singleUseCase;
  late BatchImportExternalPokemonSpeciesUseCase batchUseCase;
  late _FakePokemonExternalSourceRepository externalSourceRepository;
  late FilePokemonReadRepository readRepository;
  late FilePokemonWriteRepository writeRepository;
  late File projectFile;

  setUp(() async {
    tempProjectRoot = await Directory.systemTemp.createTemp(
      'pokemon_external_import_project_',
    );
    workspace = ProjectFileSystem(tempProjectRoot.path);
    externalSourceRepository = _FakePokemonExternalSourceRepository(
      showdownSpeciesPayloads: <String, Map<String, dynamic>>{
        'bulbasaur':
            jsonDecode(_bulbasaurShowdownPayload) as Map<String, dynamic>,
        'ivysaur': jsonDecode(_ivysaurShowdownPayload) as Map<String, dynamic>,
      },
      pokeApiPokemonPayloads: <String, Map<String, dynamic>>{
        'bulbasaur':
            jsonDecode(_bulbasaurPokemonPayload) as Map<String, dynamic>,
        'ivysaur': jsonDecode(_ivysaurPokemonPayload) as Map<String, dynamic>,
      },
      pokeApiEvolutionChainPayloads: <String, Map<String, dynamic>>{
        'bulbasaur':
            jsonDecode(_bulbasaurEvolutionChainPayload) as Map<String, dynamic>,
        'ivysaur':
            jsonDecode(_bulbasaurEvolutionChainPayload) as Map<String, dynamic>,
      },
    );
    writeRepository = const FilePokemonWriteRepository();
    readRepository = const FilePokemonReadRepository();
    singleUseCase = ImportExternalPokemonSpeciesUseCase(
      externalSourceRepository: externalSourceRepository,
      writeRepository: writeRepository,
    );
    batchUseCase = BatchImportExternalPokemonSpeciesUseCase(singleUseCase);

    final createProjectUseCase = CreateProjectUseCase(
      FileProjectRepository(),
      const FileProjectWorkspaceFactory(),
    );
    await createProjectUseCase.execute(
      'Pokemon External Import Project',
      tempProjectRoot.path,
    );
    await const InitializePokemonProjectStorageUseCase().execute(workspace);
    projectFile = File(workspace.projectManifestPath);
  });

  tearDown(() async {
    if (await tempProjectRoot.exists()) {
      await tempProjectRoot.delete(recursive: true);
    }
  });

  group('ImportExternalPokemonSpeciesUseCase', () {
    test('imports one species from external payloads into local storage',
        () async {
      final beforeProjectJson = await projectFile.readAsString();

      final result = await singleUseCase.execute(
        workspace,
        speciesId: 'bulbasaur',
      );

      expect(result.importedSpeciesId, 'bulbasaur');
      expect(result.dryRun, isFalse);
      expect(result.hasConflicts, isFalse);
      expect(
        result.artifacts.map((artifact) => artifact.action).toList(),
        <PokemonExternalImportArtifactAction>[
          PokemonExternalImportArtifactAction.create,
          PokemonExternalImportArtifactAction.create,
          PokemonExternalImportArtifactAction.create,
          PokemonExternalImportArtifactAction.create,
        ],
      );

      expect(
        await File(
          workspace.resolveProjectRelativePath(
            'data/pokemon/species/0001-bulbasaur.json',
          ),
        ).exists(),
        isTrue,
      );
      expect(
        await File(
          workspace.resolveProjectRelativePath(
            'data/pokemon/learnsets/bulbasaur.json',
          ),
        ).exists(),
        isTrue,
      );
      expect(
        await File(
          workspace.resolveProjectRelativePath(
            'data/pokemon/evolutions/bulbasaur.json',
          ),
        ).exists(),
        isTrue,
      );
      expect(
        await File(
          workspace.resolveProjectRelativePath(
            'data/pokemon/media/bulbasaur.json',
          ),
        ).exists(),
        isTrue,
      );

      final species =
          await readRepository.readSpeciesById(workspace, 'bulbasaur');
      final learnset =
          await readRepository.readLearnsetById(workspace, 'bulbasaur');
      final evolution =
          await readRepository.readEvolutionById(workspace, 'bulbasaur');
      final media = await readRepository.readMediaById(workspace, 'bulbasaur');

      expect(species.typing.types, <String>['grass', 'poison']);
      expect(learnset.tm.single.moveId, 'solar_beam');
      expect(evolution.evolutions.single.targetSpeciesId, 'ivysaur');
      expect(
        media.variants['base']?.portrait,
        'assets/pokemon/portraits/bulbasaur.png',
      );
      expect(await projectFile.readAsString(), beforeProjectJson);
    });

    test('dry-run resolves everything but writes nothing', () async {
      final beforeProjectJson = await projectFile.readAsString();

      final result = await singleUseCase.execute(
        workspace,
        speciesId: 'bulbasaur',
        mergePolicy: PokemonExternalImportMergePolicy.overwriteExisting,
        dryRun: true,
      );

      expect(result.dryRun, isTrue);
      expect(result.hasWritesApplied, isFalse);
      expect(
        result.artifacts.map((artifact) => artifact.action).toList(),
        <PokemonExternalImportArtifactAction>[
          PokemonExternalImportArtifactAction.create,
          PokemonExternalImportArtifactAction.create,
          PokemonExternalImportArtifactAction.create,
          PokemonExternalImportArtifactAction.create,
        ],
      );

      expect(
        await File(
          workspace.resolveProjectRelativePath(
            'data/pokemon/species/0001-bulbasaur.json',
          ),
        ).exists(),
        isFalse,
      );
      expect(await projectFile.readAsString(), beforeProjectJson);
    });

    test('fail_on_conflict reports conflicts and writes nothing', () async {
      await singleUseCase.execute(
        workspace,
        speciesId: 'bulbasaur',
      );
      final beforeProjectJson = await projectFile.readAsString();

      final result = await singleUseCase.execute(
        workspace,
        speciesId: 'bulbasaur',
        mergePolicy: PokemonExternalImportMergePolicy.failOnConflict,
      );

      expect(result.hasConflicts, isTrue);
      expect(result.hasWritesApplied, isFalse);
      expect(
        result.artifacts.map((artifact) => artifact.action).toList(),
        <PokemonExternalImportArtifactAction>[
          PokemonExternalImportArtifactAction.conflict,
          PokemonExternalImportArtifactAction.conflict,
          PokemonExternalImportArtifactAction.conflict,
          PokemonExternalImportArtifactAction.conflict,
        ],
      );
      expect(await projectFile.readAsString(), beforeProjectJson);
    });

    test(
        'skip_existing skips files already present and still writes missing ones',
        () async {
      await singleUseCase.execute(
        workspace,
        speciesId: 'bulbasaur',
        dryRun: true,
      );
      await writeRepository.saveSpecies(
        workspace,
        const ShowdownPokemonSpeciesConverter().convert(
          jsonDecode(_bulbasaurShowdownPayload) as Map<String, dynamic>,
        ),
      );
      final beforeProjectJson = await projectFile.readAsString();

      final result = await singleUseCase.execute(
        workspace,
        speciesId: 'bulbasaur',
        mergePolicy: PokemonExternalImportMergePolicy.skipExisting,
      );

      expect(
        result.artifacts.map((artifact) => artifact.action).toList(),
        <PokemonExternalImportArtifactAction>[
          PokemonExternalImportArtifactAction.skip,
          PokemonExternalImportArtifactAction.create,
          PokemonExternalImportArtifactAction.create,
          PokemonExternalImportArtifactAction.create,
        ],
      );
      expect(await projectFile.readAsString(), beforeProjectJson);
    });

    test('overwrite_existing replaces an existing artefact', () async {
      await writeRepository.saveLearnset(
        workspace,
        const PokeApiPokemonLearnsetConverter().convert(
          speciesId: 'bulbasaur',
          payload: jsonDecode(_legacyBulbasaurPokemonPayload)
              as Map<String, dynamic>,
        ),
      );
      final beforeProjectJson = await projectFile.readAsString();

      final result = await singleUseCase.execute(
        workspace,
        speciesId: 'bulbasaur',
        mergePolicy: PokemonExternalImportMergePolicy.overwriteExisting,
      );

      final learnset =
          await readRepository.readLearnsetById(workspace, 'bulbasaur');

      expect(
        result.artifacts
            .firstWhere(
              (artifact) =>
                  artifact.kind == PokemonExternalImportArtifactKind.learnset,
            )
            .action,
        PokemonExternalImportArtifactAction.overwrite,
      );
      expect(learnset.tm.single.moveId, 'solar_beam');
      expect(await projectFile.readAsString(), beforeProjectJson);
    });

    test(
        'overwrite_existing reuses an existing non-canonical species path '
        'without creating a duplicate canonical file', () async {
      await writeRepository.saveSpecies(
        workspace,
        _customSlugBulbasaurSpecies,
      );
      final beforeProjectJson = await projectFile.readAsString();

      final result = await singleUseCase.execute(
        workspace,
        speciesId: 'bulbasaur',
        mergePolicy: PokemonExternalImportMergePolicy.overwriteExisting,
      );

      final speciesArtifact = result.artifacts.firstWhere(
        (artifact) =>
            artifact.kind == PokemonExternalImportArtifactKind.species,
      );
      final customFile = File(
        workspace.resolveProjectRelativePath(
          'data/pokemon/species/0001-bulbizarre-custom.json',
        ),
      );
      final canonicalFile = File(
        workspace.resolveProjectRelativePath(
          'data/pokemon/species/0001-bulbasaur.json',
        ),
      );
      final species =
          await readRepository.readSpeciesById(workspace, 'bulbasaur');

      expect(speciesArtifact.action,
          PokemonExternalImportArtifactAction.overwrite);
      expect(
        speciesArtifact.relativePath,
        'data/pokemon/species/0001-bulbizarre-custom.json',
      );
      expect(await customFile.exists(), isTrue);
      expect(await canonicalFile.exists(), isFalse);
      expect(species.slug, 'bulbasaur');
      expect(species.names['en'], 'Bulbasaur');
      expect(await projectFile.readAsString(), beforeProjectJson);
    });

    test(
        'overwrite_existing ignores a misleading basename with another json id',
        () async {
      await writeRepository.saveSpecies(
        workspace,
        _customSlugBulbasaurSpecies,
      );

      final misleadingFile = File(
        workspace.resolveProjectRelativePath(
          'data/pokemon/species/9999-bulbasaur.json',
        ),
      );
      await misleadingFile.parent.create(recursive: true);
      final misleadingJson = _customSlugBulbasaurSpecies.toJson()
        ..['id'] = 'something_else'
        ..['slug'] = 'something-else';
      await misleadingFile.writeAsString(
        const JsonEncoder.withIndent('  ').convert(misleadingJson),
      );
      final beforeProjectJson = await projectFile.readAsString();

      final result = await singleUseCase.execute(
        workspace,
        speciesId: 'bulbasaur',
        mergePolicy: PokemonExternalImportMergePolicy.overwriteExisting,
      );

      final speciesArtifact = result.artifacts.firstWhere(
        (artifact) =>
            artifact.kind == PokemonExternalImportArtifactKind.species,
      );
      final customFile = File(
        workspace.resolveProjectRelativePath(
          'data/pokemon/species/0001-bulbizarre-custom.json',
        ),
      );
      final canonicalFile = File(
        workspace.resolveProjectRelativePath(
          'data/pokemon/species/0001-bulbasaur.json',
        ),
      );
      final species =
          await readRepository.readSpeciesById(workspace, 'bulbasaur');

      expect(speciesArtifact.action,
          PokemonExternalImportArtifactAction.overwrite);
      expect(
        speciesArtifact.relativePath,
        'data/pokemon/species/0001-bulbizarre-custom.json',
      );
      expect(await customFile.exists(), isTrue);
      expect(await canonicalFile.exists(), isFalse);
      expect(await misleadingFile.exists(), isTrue);
      expect(species.slug, 'bulbasaur');
      expect(species.names['en'], 'Bulbasaur');
      expect(await projectFile.readAsString(), beforeProjectJson);
    });

    test('surfaces external source errors clearly', () async {
      externalSourceRepository.pokeApiPokemonPayloads.remove('bulbasaur');

      await expectLater(
        () => singleUseCase.execute(
          workspace,
          speciesId: 'bulbasaur',
        ),
        throwsA(
          isA<EditorNotFoundException>().having(
            (error) => error.message,
            'message',
            'External PokeAPI pokemon payload not found for species "bulbasaur"',
          ),
        ),
      );
    });
  });

  group('BatchImportExternalPokemonSpeciesUseCase', () {
    test('imports a batch successfully with deterministic ordering', () async {
      final beforeProjectJson = await projectFile.readAsString();

      final result = await batchUseCase.execute(
        workspace,
        speciesIds: <String>['ivysaur', 'bulbasaur', 'ivysaur'],
      );

      expect(
        result.entries.map((entry) => entry.speciesId).toList(),
        <String>['bulbasaur', 'ivysaur'],
      );
      expect(result.successfulCount, 2);
      expect(result.failedCount, 0);
      expect(result.conflictCount, 0);
      expect(await projectFile.readAsString(), beforeProjectJson);
    });

    test('continues on partial failures and reports them by species', () async {
      externalSourceRepository.showdownSpeciesPayloads.remove('ivysaur');

      final result = await batchUseCase.execute(
        workspace,
        speciesIds: <String>['bulbasaur', 'ivysaur'],
      );

      expect(result.successfulCount, 1);
      expect(result.failedCount, 1);
      expect(
        result.entries
            .firstWhere((entry) => entry.speciesId == 'ivysaur')
            .errorMessage,
        'External Showdown species payload not found for species "ivysaur"',
      );
      expect(
        await File(
          workspace.resolveProjectRelativePath(
            'data/pokemon/species/0001-bulbasaur.json',
          ),
        ).exists(),
        isTrue,
      );
    });
  });
}

class _FakePokemonExternalSourceRepository
    implements PokemonExternalSourceRepository {
  _FakePokemonExternalSourceRepository({
    required this.showdownSpeciesPayloads,
    required this.pokeApiPokemonPayloads,
    required this.pokeApiEvolutionChainPayloads,
  });

  final Map<String, Map<String, dynamic>> showdownSpeciesPayloads;
  final Map<String, Map<String, dynamic>> pokeApiPokemonPayloads;
  final Map<String, Map<String, dynamic>> pokeApiEvolutionChainPayloads;

  @override
  Future<Map<String, dynamic>> fetchPokeApiEvolutionChainPayload(
    String speciesId,
  ) async {
    final payload = pokeApiEvolutionChainPayloads[speciesId];
    if (payload == null) {
      throw EditorNotFoundException(
        'External PokeAPI evolution chain payload not found for species '
        '"$speciesId"',
      );
    }
    return _deepCopy(payload);
  }

  @override
  Future<Map<String, dynamic>> fetchPokeApiPokemonPayload(
    String speciesId,
  ) async {
    final payload = pokeApiPokemonPayloads[speciesId];
    if (payload == null) {
      throw EditorNotFoundException(
        'External PokeAPI pokemon payload not found for species "$speciesId"',
      );
    }
    return _deepCopy(payload);
  }

  @override
  Future<Map<String, dynamic>> fetchShowdownSpeciesPayload(
    String speciesId,
  ) async {
    final payload = showdownSpeciesPayloads[speciesId];
    if (payload == null) {
      throw EditorNotFoundException(
        'External Showdown species payload not found for species "$speciesId"',
      );
    }
    return _deepCopy(payload);
  }

  Map<String, dynamic> _deepCopy(Map<String, dynamic> source) {
    return jsonDecode(jsonEncode(source)) as Map<String, dynamic>;
  }
}

const String _bulbasaurShowdownPayload = '''
{
  "name": "Bulbasaur",
  "num": 1,
  "gen": 1,
  "types": ["Grass", "Poison"],
  "baseStats": {
    "hp": 45,
    "atk": 49,
    "def": 49,
    "spa": 65,
    "spd": 65,
    "spe": 45
  },
  "abilities": {
    "0": "Overgrow",
    "H": "Chlorophyll"
  },
  "eggGroups": ["Monster", "Grass"],
  "expType": "Medium Slow",
  "baseExp": 64,
  "catchRate": 45,
  "baseFriendship": 50,
  "heightm": 0.7,
  "weightkg": 6.9
}
''';

const String _ivysaurShowdownPayload = '''
{
  "name": "Ivysaur",
  "num": 2,
  "gen": 1,
  "types": ["Grass", "Poison"],
  "baseStats": {
    "hp": 60,
    "atk": 62,
    "def": 63,
    "spa": 80,
    "spd": 80,
    "spe": 60
  },
  "abilities": {
    "0": "Overgrow",
    "H": "Chlorophyll"
  },
  "eggGroups": ["Monster", "Grass"],
  "expType": "Medium Slow",
  "baseExp": 142,
  "catchRate": 45,
  "baseFriendship": 50,
  "heightm": 1.0,
  "weightkg": 13.0
}
''';

const PokemonSpeciesFile _customSlugBulbasaurSpecies = PokemonSpeciesFile(
  id: 'bulbasaur',
  slug: 'bulbizarre-custom',
  nationalDex: 1,
  names: <String, String>{'en': 'Bulbasaur Custom'},
  speciesName: <String, String>{},
  genIntroduced: 1,
  typing: PokemonSpeciesTyping(types: <String>['grass', 'poison']),
  baseStats: PokemonSpeciesBaseStats(
    hp: 45,
    atk: 49,
    def: 49,
    spa: 65,
    spd: 65,
    spe: 45,
    bst: 318,
  ),
  abilities: PokemonSpeciesAbilities(
    primary: 'overgrow',
    hidden: 'chlorophyll',
  ),
  breeding: PokemonSpeciesBreeding(
    genderRatio: <String, double>{'male': 0.875, 'female': 0.125},
    eggGroups: <String>['monster', 'grass'],
    hatchCycles: 20,
  ),
  progression: PokemonSpeciesProgression(
    growthRateId: 'medium_slow',
    baseExp: 64,
    catchRate: 45,
    baseFriendship: 50,
  ),
  refs: PokemonSpeciesRefs(
    learnset: 'bulbasaur',
    evolution: 'bulbasaur',
    media: 'bulbasaur',
  ),
  dexContent: PokemonSpeciesDexContent(
    heightM: 0.7,
    weightKg: 6.9,
    color: 'green',
    flavorText: 'Custom slug seed for overwrite proof.',
  ),
  gameplayFlags: PokemonSpeciesGameplayFlags(),
  sourceMeta: PokemonSpeciesSourceMeta(
    seededBy: 'test',
    seedVersion: 1,
  ),
);

const String _bulbasaurPokemonPayload = '''
{
  "name": "bulbasaur",
  "moves": [
    {
      "move": {"name": "vine-whip"},
      "version_group_details": [
        {
          "level_learned_at": 7,
          "move_learn_method": {"name": "level-up"},
          "version_group": {"name": "scarlet-violet"}
        }
      ]
    },
    {
      "move": {"name": "tackle"},
      "version_group_details": [
        {
          "level_learned_at": 1,
          "move_learn_method": {"name": "level-up"},
          "version_group": {"name": "scarlet-violet"}
        }
      ]
    },
    {
      "move": {"name": "growl"},
      "version_group_details": [
        {
          "level_learned_at": 1,
          "move_learn_method": {"name": "level-up"},
          "version_group": {"name": "scarlet-violet"}
        }
      ]
    },
    {
      "move": {"name": "solar-beam"},
      "version_group_details": [
        {
          "level_learned_at": 0,
          "move_learn_method": {"name": "machine"},
          "version_group": {"name": "scarlet-violet"}
        }
      ]
    }
  ]
}
''';

const String _legacyBulbasaurPokemonPayload = '''
{
  "name": "bulbasaur",
  "moves": [
    {
      "move": {"name": "cut"},
      "version_group_details": [
        {
          "level_learned_at": 0,
          "move_learn_method": {"name": "machine"},
          "version_group": {"name": "scarlet-violet"}
        }
      ]
    }
  ]
}
''';

const String _ivysaurPokemonPayload = '''
{
  "name": "ivysaur",
  "moves": [
    {
      "move": {"name": "razor-leaf"},
      "version_group_details": [
        {
          "level_learned_at": 20,
          "move_learn_method": {"name": "level-up"},
          "version_group": {"name": "scarlet-violet"}
        }
      ]
    }
  ]
}
''';

const String _bulbasaurEvolutionChainPayload = '''
{
  "chain": {
    "species": {"name": "bulbasaur"},
    "evolution_details": [],
    "evolves_to": [
      {
        "species": {"name": "ivysaur"},
        "evolution_details": [
          {
            "trigger": {"name": "level-up"},
            "min_level": 16
          }
        ],
        "evolves_to": [
          {
            "species": {"name": "venusaur"},
            "evolution_details": [
              {
                "trigger": {"name": "use-item"},
                "item": {"name": "leaf-stone"},
                "known_move": {"name": "solar-beam"},
                "location": {"name": "special-garden"}
              }
            ],
            "evolves_to": []
          }
        ]
      }
    ]
  }
}
''';
