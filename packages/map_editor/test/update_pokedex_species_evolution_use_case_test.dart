import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/application/errors/application_errors.dart';
import 'package:map_editor/src/application/models/pokemon_project_data_models.dart';
import 'package:map_editor/src/application/use_cases/initialize_pokemon_project_storage_use_case.dart';
import 'package:map_editor/src/application/use_cases/project_management_use_cases.dart';
import 'package:map_editor/src/application/use_cases/update_pokedex_species_evolution_use_case.dart';
import 'package:map_editor/src/infrastructure/filesystem/project_filesystem.dart';
import 'package:map_editor/src/infrastructure/repositories/file_repositories.dart';

void main() {
  late Directory tempProjectRoot;
  late ProjectFileSystem workspace;
  late FilePokemonReadRepository readRepository;
  late FilePokemonWriteRepository writeRepository;
  late UpdatePokedexSpeciesEvolutionUseCase useCase;

  setUp(() async {
    tempProjectRoot = await Directory.systemTemp.createTemp(
      'pokedex_species_evolution_',
    );
    workspace = ProjectFileSystem(tempProjectRoot.path);
    readRepository = const FilePokemonReadRepository();
    writeRepository = const FilePokemonWriteRepository();
    useCase = UpdatePokedexSpeciesEvolutionUseCase(
      readRepository: readRepository,
      writeRepository: writeRepository,
    );

    final createProjectUseCase = CreateProjectUseCase(
      FileProjectRepository(),
      const FileProjectWorkspaceFactory(),
    );
    await createProjectUseCase.execute(
      'Pokedex Species Evolution Project',
      tempProjectRoot.path,
    );
    await const InitializePokemonProjectStorageUseCase().execute(workspace);
  });

  tearDown(() async {
    if (await tempProjectRoot.exists()) {
      await tempProjectRoot.delete(recursive: true);
    }
  });

  test(
      'creates or updates the evolution JSON through the existing ref without touching project manifest',
      () async {
    await writeRepository.saveSpecies(workspace, _speciesWithCustomRefs);

    final projectFile = File(workspace.projectManifestPath);
    final beforeProjectJson = await projectFile.readAsString();

    await useCase.execute(
      workspace,
      const UpdatePokedexSpeciesEvolutionRequest(
        speciesId: 'bulbasaur',
        preEvolution: '',
        evolutions: <PokemonEvolutionEntry>[
          PokemonEvolutionEntry(
            targetSpeciesId: 'ivysaur',
            method: 'level_up',
            minLevel: 16,
            conditionText: <String, String>{
              'fr': 'Évolue au niveau 16',
              'en': 'Evolves at level 16',
            },
          ),
        ],
      ),
    );

    final readBack =
        await readRepository.readEvolutionById(workspace, 'bulbasaur-chain');
    expect(readBack.speciesId, 'bulbasaur-chain');
    expect(readBack.preEvolution, isNull);
    expect(readBack.evolutions.single.targetSpeciesId, 'ivysaur');
    expect(readBack.evolutions.single.minLevel, 16);
    expect(
      await File(
        workspace.resolveProjectRelativePath(
          'data/pokemon/evolutions/bulbasaur-chain.json',
        ),
      ).exists(),
      isTrue,
    );
    expect(await projectFile.readAsString(), beforeProjectJson);
  });

  test('rejects an empty chain and leaves project manifest untouched',
      () async {
    await writeRepository.saveSpecies(workspace, _speciesWithCustomRefs);

    final projectFile = File(workspace.projectManifestPath);
    final beforeProjectJson = await projectFile.readAsString();

    await expectLater(
      () => useCase.execute(
        workspace,
        const UpdatePokedexSpeciesEvolutionRequest(
          speciesId: 'bulbasaur',
          preEvolution: ' ',
          evolutions: <PokemonEvolutionEntry>[],
        ),
      ),
      throwsA(
        isA<EditorValidationException>().having(
          (error) => error.message,
          'message',
          'Pokemon evolution must define preEvolution or evolutions',
        ),
      ),
    );

    expect(
      await File(
        workspace.resolveProjectRelativePath(
          'data/pokemon/evolutions/bulbasaur-chain.json',
        ),
      ).exists(),
      isFalse,
    );
    expect(await projectFile.readAsString(), beforeProjectJson);
  });
}

const PokemonSpeciesFile _speciesWithCustomRefs = PokemonSpeciesFile(
  id: 'bulbasaur',
  slug: 'bulbasaur',
  nationalDex: 1,
  names: <String, String>{'fr': 'Bulbizarre', 'en': 'Bulbasaur'},
  speciesName: <String, String>{'fr': 'Pokémon Graine', 'en': 'Seed Pokemon'},
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
  forms: PokemonSpeciesForms(
    baseFormId: 'bulbasaur',
    isBaseForm: true,
    formId: 'base',
  ),
  classification: PokemonSpeciesClassification(
    isEnabledInProject: true,
    isObtainable: true,
  ),
  refs: PokemonSpeciesRefs(
    learnset: 'bulbasaur-local',
    evolution: 'bulbasaur-chain',
    media: 'bulbasaur-media',
  ),
  dexContent: PokemonSpeciesDexContent(
    heightM: 0.7,
    weightKg: 6.9,
    color: 'green',
    flavorText: 'Une étrange graine a été plantée sur son dos à la naissance.',
  ),
  gameplayFlags: PokemonSpeciesGameplayFlags(
    starterEligible: true,
    giftOnly: false,
    tradeOnly: false,
  ),
  sourceMeta: PokemonSpeciesSourceMeta(
    seededBy: 'test',
    seedVersion: 1,
  ),
);
