import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/application/errors/application_errors.dart';
import 'package:map_editor/src/application/models/pokemon_project_data_models.dart';
import 'package:map_editor/src/application/use_cases/initialize_pokemon_project_storage_use_case.dart';
import 'package:map_editor/src/application/use_cases/project_management_use_cases.dart';
import 'package:map_editor/src/application/use_cases/update_pokedex_species_media_use_case.dart';
import 'package:map_editor/src/infrastructure/filesystem/project_filesystem.dart';
import 'package:map_editor/src/infrastructure/repositories/file_repositories.dart';

void main() {
  late Directory tempProjectRoot;
  late ProjectFileSystem workspace;
  late FilePokemonReadRepository readRepository;
  late FilePokemonWriteRepository writeRepository;
  late UpdatePokedexSpeciesMediaUseCase useCase;

  setUp(() async {
    tempProjectRoot = await Directory.systemTemp.createTemp(
      'pokedex_species_media_',
    );
    workspace = ProjectFileSystem(tempProjectRoot.path);
    readRepository = const FilePokemonReadRepository();
    writeRepository = const FilePokemonWriteRepository();
    useCase = UpdatePokedexSpeciesMediaUseCase(
      readRepository: readRepository,
      writeRepository: writeRepository,
    );

    final createProjectUseCase = CreateProjectUseCase(
      FileProjectRepository(),
      const FileProjectWorkspaceFactory(),
    );
    await createProjectUseCase.execute(
      'Pokedex Species Media Project',
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
      'creates or updates the media JSON through the existing ref without touching project manifest',
      () async {
    await writeRepository.saveSpecies(workspace, _speciesWithCustomRefs);

    final projectFile = File(workspace.projectManifestPath);
    final beforeProjectJson = await projectFile.readAsString();

    await useCase.execute(
      workspace,
      const UpdatePokedexSpeciesMediaRequest(
        speciesId: 'bulbasaur',
        defaultFormId: 'base',
        variants: <String, PokemonMediaVariant>{
          'base': PokemonMediaVariant(
            frontStatic: 'assets/pokemon/sprites/bulbasaur/front.png',
            backStatic: 'assets/pokemon/sprites/bulbasaur/back.png',
            icon: 'assets/pokemon/sprites/bulbasaur/icon.png',
            party: 'assets/pokemon/sprites/bulbasaur/party.png',
            portrait: 'assets/pokemon/portraits/bulbasaur.png',
            cry: 'assets/pokemon/cries/bulbasaur.ogg',
            animations: <String, PokemonMediaAnimationRef>{
              'battleFront': PokemonMediaAnimationRef(
                sheet:
                    'assets/pokemon/sprites/bulbasaur/battle_front_sheet.png',
                animationId: 'battle_front',
              ),
            },
          ),
        },
      ),
    );

    final readBack =
        await readRepository.readMediaById(workspace, 'bulbasaur-media');
    expect(readBack.speciesId, 'bulbasaur-media');
    expect(readBack.defaultFormId, 'base');
    expect(
      readBack.variants['base']?.portrait,
      'assets/pokemon/portraits/bulbasaur.png',
    );
    expect(
      readBack.variants['base']?.animations['battleFront']?.animationId,
      'battle_front',
    );
    expect(
      await File(
        workspace.resolveProjectRelativePath(
          'data/pokemon/media/bulbasaur-media.json',
        ),
      ).exists(),
      isTrue,
    );
    expect(await projectFile.readAsString(), beforeProjectJson);
  });

  test('rejects an invalid default form and leaves project manifest untouched',
      () async {
    await writeRepository.saveSpecies(workspace, _speciesWithCustomRefs);

    final projectFile = File(workspace.projectManifestPath);
    final beforeProjectJson = await projectFile.readAsString();

    await expectLater(
      () => useCase.execute(
        workspace,
        const UpdatePokedexSpeciesMediaRequest(
          speciesId: 'bulbasaur',
          defaultFormId: 'missing',
          variants: <String, PokemonMediaVariant>{
            'base': PokemonMediaVariant(
              portrait: 'assets/pokemon/portraits/bulbasaur.png',
            ),
          },
        ),
      ),
      throwsA(
        isA<EditorValidationException>().having(
          (error) => error.message,
          'message',
          'Pokemon media defaultFormId must exist in variants',
        ),
      ),
    );

    expect(
      await File(
        workspace.resolveProjectRelativePath(
          'data/pokemon/media/bulbasaur-media.json',
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
