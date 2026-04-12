import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/application/errors/application_errors.dart';
import 'package:map_editor/src/application/models/pokemon_project_data_models.dart';
import 'package:map_editor/src/application/use_cases/initialize_pokemon_project_storage_use_case.dart';
import 'package:map_editor/src/application/use_cases/project_management_use_cases.dart';
import 'package:map_editor/src/application/use_cases/update_pokedex_species_metadata_use_case.dart';
import 'package:map_editor/src/infrastructure/filesystem/project_filesystem.dart';
import 'package:map_editor/src/infrastructure/repositories/file_repositories.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory tempProjectRoot;
  late ProjectFileSystem workspace;
  late FilePokemonReadRepository readRepository;
  late FilePokemonWriteRepository writeRepository;
  late UpdatePokedexSpeciesMetadataUseCase useCase;

  setUp(() async {
    tempProjectRoot = await Directory.systemTemp.createTemp(
      'pokedex_species_metadata_',
    );
    workspace = ProjectFileSystem(tempProjectRoot.path);
    readRepository = const FilePokemonReadRepository();
    writeRepository = const FilePokemonWriteRepository();
    useCase = UpdatePokedexSpeciesMetadataUseCase(
      readRepository: readRepository,
      writeRepository: writeRepository,
    );

    final createProjectUseCase = CreateProjectUseCase(
      FileProjectRepository(),
      const FileProjectWorkspaceFactory(),
    );
    await createProjectUseCase.execute(
      'Pokedex Species Metadata Project',
      tempProjectRoot.path,
    );
    await const InitializePokemonProjectStorageUseCase().execute(workspace);
  });

  tearDown(() async {
    if (await tempProjectRoot.exists()) {
      await tempProjectRoot.delete(recursive: true);
    }
  });

  group('UpdatePokedexSpeciesMetadataUseCase', () {
    test(
        'persists enabled state and simple metadata while keeping refs and project.json unchanged',
        () async {
      await writeRepository.saveSpecies(workspace, _bulbasaurSpecies);

      final projectFile = File(workspace.projectManifestPath);
      final beforeProjectJson = await projectFile.readAsString();

      await useCase.execute(
        workspace,
        const UpdatePokedexSpeciesMetadataRequest(
          speciesId: 'bulbasaur',
          isEnabledInProject: false,
          names: <String, String>{
            'fr': 'Bulbizarre Projet',
            'en': 'Bulbasaur Project',
          },
          types: <String>['electric', 'fairy'],
          flavorText: 'Texte Pokédex édité localement.',
          starterEligible: false,
          giftOnly: true,
          tradeOnly: true,
        ),
      );

      final readBack =
          await readRepository.readSpeciesById(workspace, 'bulbasaur');

      expect(readBack.classification.isEnabledInProject, isFalse);
      expect(readBack.names['fr'], 'Bulbizarre Projet');
      expect(readBack.names['en'], 'Bulbasaur Project');
      expect(readBack.typing.types, <String>['electric', 'fairy']);
      expect(readBack.dexContent.flavorText, 'Texte Pokédex édité localement.');
      expect(readBack.gameplayFlags.starterEligible, isFalse);
      expect(readBack.gameplayFlags.giftOnly, isTrue);
      expect(readBack.gameplayFlags.tradeOnly, isTrue);

      // On verrouille explicitement le point le plus fragile de cette phase :
      // l'édition simple ne doit jamais casser les refs déjà branchées.
      expect(readBack.refs.learnset, 'bulbasaur');
      expect(readBack.refs.evolution, 'bulbasaur');
      expect(readBack.refs.media, 'bulbasaur');
      expect(readBack.forms.baseFormId, 'bulbasaur');
      expect(readBack.sourceMeta.seededBy, 'test');
      expect(readBack.sourceMeta.seedVersion, 1);

      expect(await projectFile.readAsString(), beforeProjectJson);
    });

    test(
        'rejects metadata updates when all localized names are empty and leaves species and project manifest untouched',
        () async {
      await writeRepository.saveSpecies(workspace, _bulbasaurSpecies);

      final projectFile = File(workspace.projectManifestPath);
      final beforeProjectJson = await projectFile.readAsString();
      final speciesFilesBefore = await _listSpeciesJsonFiles(workspace);
      expect(speciesFilesBefore, hasLength(1));

      final speciesFile = speciesFilesBefore.single;
      final beforeSpeciesJson = await speciesFile.readAsString();

      await expectLater(
        () => useCase.execute(
          workspace,
          const UpdatePokedexSpeciesMetadataRequest(
            speciesId: 'bulbasaur',
            isEnabledInProject: true,
            names: <String, String>{
              'fr': '   ',
              'en': '\n\t',
            },
            types: <String>['grass', 'poison'],
            flavorText: 'Ce texte ne doit jamais être persisté.',
            starterEligible: false,
            giftOnly: true,
            tradeOnly: true,
          ),
        ),
        throwsA(
          isA<EditorValidationException>().having(
            (error) => error.message,
            'message',
            'Pokemon species names must contain at least one non-empty value',
          ),
        ),
      );

      final speciesFilesAfter = await _listSpeciesJsonFiles(workspace);
      expect(speciesFilesAfter, hasLength(1));
      expect(speciesFilesAfter.single.path, speciesFile.path);
      expect(await speciesFile.readAsString(), beforeSpeciesJson);
      expect(await projectFile.readAsString(), beforeProjectJson);

      final readBack =
          await readRepository.readSpeciesById(workspace, 'bulbasaur');
      expect(readBack.names, _bulbasaurSpecies.names);
      expect(
        readBack.dexContent.flavorText,
        _bulbasaurSpecies.dexContent.flavorText,
      );
      expect(readBack.gameplayFlags.starterEligible, isTrue);
      expect(readBack.gameplayFlags.giftOnly, isFalse);
      expect(readBack.gameplayFlags.tradeOnly, isFalse);
      expect(readBack.refs.learnset, 'bulbasaur');
      expect(readBack.refs.evolution, 'bulbasaur');
      expect(readBack.refs.media, 'bulbasaur');
    });

    test(
        'rejects metadata updates when all types are empty and leaves species and project manifest untouched',
        () async {
      await writeRepository.saveSpecies(workspace, _bulbasaurSpecies);

      final projectFile = File(workspace.projectManifestPath);
      final beforeProjectJson = await projectFile.readAsString();
      final speciesFilesBefore = await _listSpeciesJsonFiles(workspace);
      expect(speciesFilesBefore, hasLength(1));

      final speciesFile = speciesFilesBefore.single;
      final beforeSpeciesJson = await speciesFile.readAsString();

      await expectLater(
        () => useCase.execute(
          workspace,
          const UpdatePokedexSpeciesMetadataRequest(
            speciesId: 'bulbasaur',
            isEnabledInProject: true,
            names: <String, String>{
              'fr': 'Bulbizarre',
              'en': 'Bulbasaur',
            },
            types: <String>['   ', '\n\t'],
            flavorText: 'Ce texte ne doit jamais être persisté.',
            starterEligible: false,
            giftOnly: true,
            tradeOnly: true,
          ),
        ),
        throwsA(
          isA<EditorValidationException>().having(
            (error) => error.message,
            'message',
            'Pokemon species must contain at least one non-empty type',
          ),
        ),
      );

      final speciesFilesAfter = await _listSpeciesJsonFiles(workspace);
      expect(speciesFilesAfter, hasLength(1));
      expect(speciesFilesAfter.single.path, speciesFile.path);
      expect(await speciesFile.readAsString(), beforeSpeciesJson);
      expect(await projectFile.readAsString(), beforeProjectJson);

      final readBack =
          await readRepository.readSpeciesById(workspace, 'bulbasaur');
      expect(readBack.typing.types, _bulbasaurSpecies.typing.types);
      expect(readBack.refs.learnset, 'bulbasaur');
      expect(readBack.refs.evolution, 'bulbasaur');
      expect(readBack.refs.media, 'bulbasaur');
    });

    test(
        'reuses an existing non-canonical species path instead of creating a canonical duplicate during metadata updates',
        () async {
      final speciesDir = Directory(
        workspace.resolveProjectRelativePath('data/pokemon/species'),
      );
      await speciesDir.create(recursive: true);

      final customFile = File(
        p.join(speciesDir.path, '0001-bulbizarre-custom.json'),
      );
      await customFile.writeAsString(
        const JsonEncoder.withIndent('  ').convert(_bulbasaurSpecies.toJson()),
      );

      await useCase.execute(
        workspace,
        const UpdatePokedexSpeciesMetadataRequest(
          speciesId: 'bulbasaur',
          isEnabledInProject: true,
          names: <String, String>{
            'fr': 'Bulbizarre Mis à Jour',
            'en': 'Bulbasaur Refreshed',
          },
          types: <String>['grass', 'dragon'],
          flavorText: 'Le writer doit réutiliser le chemin déjà présent.',
          starterEligible: true,
          giftOnly: false,
          tradeOnly: false,
        ),
      );

      final canonicalFile = File(
        workspace.resolveProjectRelativePath(
          'data/pokemon/species/0001-bulbasaur.json',
        ),
      );
      expect(await customFile.exists(), isTrue);
      expect(await canonicalFile.exists(), isFalse);

      final speciesFiles = await speciesDir
          .list(recursive: false)
          .where(
            (entity) => entity is File && p.extension(entity.path) == '.json',
          )
          .cast<File>()
          .toList();
      expect(speciesFiles, hasLength(1));
      expect(
          p.basename(speciesFiles.single.path), '0001-bulbizarre-custom.json');

      final readBack =
          await readRepository.readSpeciesById(workspace, 'bulbasaur');
      expect(readBack.names['en'], 'Bulbasaur Refreshed');
      expect(readBack.typing.types, <String>['grass', 'dragon']);
      expect(
        readBack.dexContent.flavorText,
        'Le writer doit réutiliser le chemin déjà présent.',
      );
      expect(readBack.refs.learnset, 'bulbasaur');
      expect(readBack.refs.evolution, 'bulbasaur');
      expect(readBack.refs.media, 'bulbasaur');
    });
  });
}

Future<List<File>> _listSpeciesJsonFiles(ProjectFileSystem workspace) async {
  final speciesDirectory = Directory(
    workspace.resolveProjectRelativePath('data/pokemon/species'),
  );
  return speciesDirectory
      .list(recursive: false)
      .where((entity) => entity is File && p.extension(entity.path) == '.json')
      .cast<File>()
      .toList();
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
  ),
  sourceMeta: PokemonSpeciesSourceMeta(
    seededBy: 'test',
    seedVersion: 1,
  ),
);
