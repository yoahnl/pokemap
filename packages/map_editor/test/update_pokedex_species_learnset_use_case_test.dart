import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/application/errors/application_errors.dart';
import 'package:map_editor/src/application/models/pokemon_project_data_models.dart';
import 'package:map_editor/src/application/use_cases/initialize_pokemon_project_storage_use_case.dart';
import 'package:map_editor/src/application/use_cases/project_management_use_cases.dart';
import 'package:map_editor/src/application/use_cases/update_pokedex_species_learnset_use_case.dart';
import 'package:map_editor/src/infrastructure/filesystem/project_filesystem.dart';
import 'package:map_editor/src/infrastructure/repositories/file_repositories.dart';

void main() {
  late Directory tempProjectRoot;
  late ProjectFileSystem workspace;
  late FilePokemonReadRepository readRepository;
  late FilePokemonWriteRepository writeRepository;
  late UpdatePokedexSpeciesLearnsetUseCase useCase;

  setUp(() async {
    tempProjectRoot = await Directory.systemTemp.createTemp(
      'pokedex_species_learnset_',
    );
    workspace = ProjectFileSystem(tempProjectRoot.path);
    readRepository = const FilePokemonReadRepository();
    writeRepository = const FilePokemonWriteRepository();
    useCase = UpdatePokedexSpeciesLearnsetUseCase(
      readRepository: readRepository,
      writeRepository: writeRepository,
    );

    final createProjectUseCase = CreateProjectUseCase(
      FileProjectRepository(),
      const FileProjectWorkspaceFactory(),
    );
    await createProjectUseCase.execute(
      'Pokedex Species Learnset Project',
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
      'creates or updates the learnset JSON through the existing ref without touching project manifest',
      () async {
    await writeRepository.saveSpecies(workspace, _speciesWithCustomRefs);

    final projectFile = File(workspace.projectManifestPath);
    final beforeProjectJson = await projectFile.readAsString();

    await useCase.execute(
      workspace,
      const UpdatePokedexSpeciesLearnsetRequest(
        speciesId: 'bulbasaur',
        startingMoves: <String>['tackle', 'growl', 'tackle'],
        relearnMoves: <String>['vine_whip'],
        levelUp: <PokemonLearnsetLevelUpEntry>[
          PokemonLearnsetLevelUpEntry(
            moveId: 'vine_whip',
            level: 7,
            source: 'level_up',
            versionGroup: 'scarlet-violet',
          ),
        ],
        tm: <PokemonLearnsetMoveEntry>[
          PokemonLearnsetMoveEntry(
            moveId: 'protect',
            versionGroup: 'scarlet-violet',
          ),
        ],
        tutor: <PokemonLearnsetMoveEntry>[],
        egg: <PokemonLearnsetMoveEntry>[],
        event: <PokemonLearnsetMoveEntry>[],
        transfer: <PokemonLearnsetMoveEntry>[],
      ),
    );

    final readBack =
        await readRepository.readLearnsetById(workspace, 'bulbasaur-local');
    expect(readBack.speciesId, 'bulbasaur-local');
    expect(readBack.startingMoves, <String>['tackle', 'growl']);
    expect(readBack.relearnMoves, <String>['vine_whip']);
    expect(readBack.levelUp.single.moveId, 'vine_whip');
    expect(readBack.tm.single.moveId, 'protect');
    expect(
      await File(
        workspace.resolveProjectRelativePath(
          'data/pokemon/learnsets/bulbasaur-local.json',
        ),
      ).exists(),
      isTrue,
    );
    expect(await projectFile.readAsString(), beforeProjectJson);
  });

  test('rejects an empty learnset and leaves project manifest untouched',
      () async {
    await writeRepository.saveSpecies(workspace, _speciesWithCustomRefs);

    final projectFile = File(workspace.projectManifestPath);
    final beforeProjectJson = await projectFile.readAsString();

    await expectLater(
      () => useCase.execute(
        workspace,
        const UpdatePokedexSpeciesLearnsetRequest(
          speciesId: 'bulbasaur',
          startingMoves: <String>[],
          relearnMoves: <String>[],
          levelUp: <PokemonLearnsetLevelUpEntry>[],
          tm: <PokemonLearnsetMoveEntry>[],
          tutor: <PokemonLearnsetMoveEntry>[],
          egg: <PokemonLearnsetMoveEntry>[],
          event: <PokemonLearnsetMoveEntry>[],
          transfer: <PokemonLearnsetMoveEntry>[],
        ),
      ),
      throwsA(
        isA<EditorValidationException>().having(
          (error) => error.message,
          'message',
          'Pokemon learnset must contain at least one move section',
        ),
      ),
    );

    expect(
      await File(
        workspace.resolveProjectRelativePath(
          'data/pokemon/learnsets/bulbasaur-local.json',
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
