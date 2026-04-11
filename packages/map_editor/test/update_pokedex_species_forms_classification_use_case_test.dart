import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/application/models/pokemon_project_data_models.dart';
import 'package:map_editor/src/application/use_cases/initialize_pokemon_project_storage_use_case.dart';
import 'package:map_editor/src/application/use_cases/project_management_use_cases.dart';
import 'package:map_editor/src/application/use_cases/update_pokedex_species_forms_classification_use_case.dart';
import 'package:map_editor/src/infrastructure/filesystem/project_filesystem.dart';
import 'package:map_editor/src/infrastructure/repositories/file_repositories.dart';

void main() {
  late Directory tempProjectRoot;
  late ProjectFileSystem workspace;
  late FilePokemonReadRepository readRepository;
  late FilePokemonWriteRepository writeRepository;
  late UpdatePokedexSpeciesFormsClassificationUseCase useCase;

  setUp(() async {
    tempProjectRoot = await Directory.systemTemp.createTemp(
      'pokedex_species_forms_classification_',
    );
    workspace = ProjectFileSystem(tempProjectRoot.path);
    readRepository = const FilePokemonReadRepository();
    writeRepository = const FilePokemonWriteRepository();
    useCase = UpdatePokedexSpeciesFormsClassificationUseCase(
      readRepository: readRepository,
      writeRepository: writeRepository,
    );

    final createProjectUseCase = CreateProjectUseCase(
      FileProjectRepository(),
      const FileProjectWorkspaceFactory(),
    );
    await createProjectUseCase.execute(
      'Pokedex Species Forms Classification Project',
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
      'persists forms and classification flags while preserving enabled status refs and project manifest',
      () async {
    await writeRepository.saveSpecies(workspace, _bulbasaurSpecies);

    final projectFile = File(workspace.projectManifestPath);
    final beforeProjectJson = await projectFile.readAsString();

    await useCase.execute(
      workspace,
      const UpdatePokedexSpeciesFormsClassificationRequest(
        speciesId: 'bulbasaur',
        baseFormId: 'bulbasaur',
        isBaseForm: false,
        formId: 'mega',
        formName: 'Méga',
        otherForms: <String>['base', 'gmax', 'gmax', '  '],
        isObtainable: false,
        isLegendary: true,
        isMythical: false,
        isBaby: false,
      ),
    );

    final readBack =
        await readRepository.readSpeciesById(workspace, 'bulbasaur');

    expect(readBack.forms.baseFormId, 'bulbasaur');
    expect(readBack.forms.isBaseForm, isFalse);
    expect(readBack.forms.formId, 'mega');
    expect(readBack.forms.formName, 'Méga');
    expect(readBack.forms.otherForms, <String>['base', 'gmax']);
    expect(readBack.classification.isEnabledInProject, isTrue);
    expect(readBack.classification.isObtainable, isFalse);
    expect(readBack.classification.isLegendary, isTrue);
    expect(readBack.classification.isMythical, isFalse);
    expect(readBack.classification.isBaby, isFalse);
    expect(readBack.refs.learnset, 'bulbasaur');
    expect(readBack.refs.evolution, 'bulbasaur');
    expect(readBack.refs.media, 'bulbasaur');
    expect(readBack.gameplayFlags.starterEligible, isTrue);
    expect(readBack.gameplayFlags.giftOnly, isFalse);
    expect(readBack.gameplayFlags.tradeOnly, isFalse);
    expect(await projectFile.readAsString(), beforeProjectJson);
  });
}

const PokemonSpeciesFile _bulbasaurSpecies = PokemonSpeciesFile(
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
    otherForms: <String>['mega'],
  ),
  classification: PokemonSpeciesClassification(
    isEnabledInProject: true,
    isObtainable: true,
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
