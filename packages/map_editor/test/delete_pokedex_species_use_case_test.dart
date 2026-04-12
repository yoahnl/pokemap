import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/application/errors/application_errors.dart';
import 'package:map_editor/src/application/models/pokemon_project_data_models.dart';
import 'package:map_editor/src/application/use_cases/delete_pokedex_species_use_case.dart';
import 'package:map_editor/src/application/use_cases/initialize_pokemon_project_storage_use_case.dart';
import 'package:map_editor/src/application/use_cases/project_management_use_cases.dart';
import 'package:map_editor/src/infrastructure/filesystem/project_filesystem.dart';
import 'package:map_editor/src/infrastructure/repositories/file_repositories.dart';

void main() {
  late Directory tempProjectRoot;
  late ProjectFileSystem workspace;
  late FilePokemonReadRepository readRepository;
  late FilePokemonWriteRepository writeRepository;
  late DeletePokedexSpeciesUseCase useCase;

  setUp(() async {
    tempProjectRoot = await Directory.systemTemp.createTemp(
      'delete_pokedex_species_',
    );
    workspace = ProjectFileSystem(tempProjectRoot.path);
    readRepository = const FilePokemonReadRepository();
    writeRepository = const FilePokemonWriteRepository();
    useCase = DeletePokedexSpeciesUseCase(
      readRepository: readRepository,
    );

    final createProjectUseCase = CreateProjectUseCase(
      FileProjectRepository(),
      const FileProjectWorkspaceFactory(),
    );
    await createProjectUseCase.execute(
      'Delete Pokedex Species Project',
      tempProjectRoot.path,
    );
    await const InitializePokemonProjectStorageUseCase().execute(workspace);
  });

  tearDown(() async {
    if (await tempProjectRoot.exists()) {
      await tempProjectRoot.delete(recursive: true);
    }
  });

  group('DeletePokedexSpeciesUseCase', () {
    test(
        'deletes species sidecars and referenced assets without touching project.json',
        () async {
      await writeRepository.saveSpecies(workspace, _bulbasaurSpecies);
      await writeRepository.saveLearnset(workspace, _bulbasaurLearnset);
      await writeRepository.saveEvolution(workspace, _bulbasaurEvolution);
      await writeRepository.saveMedia(workspace, _bulbasaurMedia);
      for (final relativePath in _bulbasaurAssetPaths) {
        await writeRepository.saveBinaryAsset(
          workspace,
          relativePath: relativePath,
          bytes: const <int>[1, 2, 3, 4],
        );
      }

      final projectFile = File(workspace.projectManifestPath);
      final beforeProjectJson = await projectFile.readAsString();

      final result = await useCase.execute(workspace, 'bulbasaur');

      expect(result.speciesId, 'bulbasaur');
      expect(result.primaryName, 'Bulbizarre');
      expect(
        result.deletedRelativePaths,
        containsAll(<String>[
          'data/pokemon/species/0001-bulbasaur.json',
          'data/pokemon/learnsets/bulbasaur.json',
          'data/pokemon/evolutions/bulbasaur.json',
          'data/pokemon/media/bulbasaur.json',
          ..._bulbasaurAssetPaths,
        ]),
      );

      await expectLater(
        () => readRepository.readSpeciesById(workspace, 'bulbasaur'),
        throwsA(isA<EditorNotFoundException>()),
      );

      for (final relativePath in <String>[
        'data/pokemon/species/0001-bulbasaur.json',
        'data/pokemon/learnsets/bulbasaur.json',
        'data/pokemon/evolutions/bulbasaur.json',
        'data/pokemon/media/bulbasaur.json',
        ..._bulbasaurAssetPaths,
      ]) {
        final absolutePath = workspace.resolveProjectRelativePath(relativePath);
        expect(await workspace.fileExists(absolutePath), isFalse);
      }

      expect(await projectFile.readAsString(), beforeProjectJson);
    });

    test('tolerates missing sidecars and still deletes the species file',
        () async {
      await writeRepository.saveSpecies(workspace, _bulbasaurSpecies);

      final result = await useCase.execute(workspace, 'bulbasaur');

      expect(result.deletedRelativePaths, <String>[
        'data/pokemon/species/0001-bulbasaur.json',
      ]);

      await expectLater(
        () => readRepository.readSpeciesById(workspace, 'bulbasaur'),
        throwsA(isA<EditorNotFoundException>()),
      );
    });
  });
}

const PokemonSpeciesFile _bulbasaurSpecies = PokemonSpeciesFile(
  id: 'bulbasaur',
  slug: 'bulbasaur',
  nationalDex: 1,
  names: <String, String>{
    'fr': 'Bulbizarre',
    'en': 'Bulbasaur',
  },
  speciesName: <String, String>{
    'fr': 'Pokémon Graine',
    'en': 'Seed Pokemon',
  },
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

const PokemonLearnsetFile _bulbasaurLearnset = PokemonLearnsetFile(
  speciesId: 'bulbasaur',
  startingMoves: <String>['tackle', 'growl'],
);

const PokemonEvolutionFile _bulbasaurEvolution = PokemonEvolutionFile(
  speciesId: 'bulbasaur',
  evolutions: <PokemonEvolutionEntry>[
    PokemonEvolutionEntry(
      targetSpeciesId: 'ivysaur',
      method: 'level_up',
      minLevel: 16,
    ),
  ],
);

const PokemonMediaFile _bulbasaurMedia = PokemonMediaFile(
  speciesId: 'bulbasaur',
  defaultFormId: 'base',
  variants: <String, PokemonMediaVariant>{
    'base': PokemonMediaVariant(
      frontStatic: 'assets/pokemon/sprites/bulbasaur/front.png',
      backStatic: 'assets/pokemon/sprites/bulbasaur/back.png',
      icon: 'assets/pokemon/sprites/bulbasaur/icon.png',
      portrait: 'assets/pokemon/portraits/bulbasaur.png',
      cry: 'assets/pokemon/cries/bulbasaur.ogg',
      animations: <String, PokemonMediaAnimationRef>{
        'battleFront': PokemonMediaAnimationRef(
          sheet: 'assets/pokemon/sprites/bulbasaur/battle_front_sheet.png',
          animationId: 'battle_front',
        ),
      },
    ),
  },
);

const List<String> _bulbasaurAssetPaths = <String>[
  'assets/pokemon/sprites/bulbasaur/front.png',
  'assets/pokemon/sprites/bulbasaur/back.png',
  'assets/pokemon/sprites/bulbasaur/icon.png',
  'assets/pokemon/portraits/bulbasaur.png',
  'assets/pokemon/cries/bulbasaur.ogg',
  'assets/pokemon/sprites/bulbasaur/battle_front_sheet.png',
];
