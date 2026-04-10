import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/application/errors/application_errors.dart';
import 'package:map_editor/src/application/models/pokemon_project_data_models.dart';
import 'package:map_editor/src/application/use_cases/import_pokemon_species_json_use_case.dart';
import 'package:map_editor/src/application/use_cases/initialize_pokemon_project_storage_use_case.dart';
import 'package:map_editor/src/application/use_cases/project_management_use_cases.dart';
import 'package:map_editor/src/infrastructure/filesystem/project_filesystem.dart';
import 'package:map_editor/src/infrastructure/repositories/file_repositories.dart';

void main() {
  late Directory tempProjectRoot;
  late Directory tempImportRoot;
  late ProjectFileSystem workspace;
  late ImportPokemonSpeciesJsonUseCase useCase;
  late FilePokemonReadRepository readRepository;
  late File projectFile;

  setUp(() async {
    tempProjectRoot = await Directory.systemTemp.createTemp(
      'pokemon_species_import_project_',
    );
    tempImportRoot = await Directory.systemTemp.createTemp(
      'pokemon_species_import_source_',
    );
    workspace = ProjectFileSystem(tempProjectRoot.path);
    useCase = const ImportPokemonSpeciesJsonUseCase(
      FilePokemonWriteRepository(),
    );
    readRepository = const FilePokemonReadRepository();

    final createProjectUseCase = CreateProjectUseCase(
      FileProjectRepository(),
      const FileProjectWorkspaceFactory(),
    );
    await createProjectUseCase.execute(
      'Pokemon Species Import Project',
      tempProjectRoot.path,
    );
    await const InitializePokemonProjectStorageUseCase().execute(workspace);
    projectFile = File(workspace.projectManifestPath);
  });

  tearDown(() async {
    if (await tempProjectRoot.exists()) {
      await tempProjectRoot.delete(recursive: true);
    }
    if (await tempImportRoot.exists()) {
      await tempImportRoot.delete(recursive: true);
    }
  });

  group('ImportPokemonSpeciesJsonUseCase', () {
    test('fails clearly when the source path is empty', () async {
      await expectLater(
        () => useCase.execute(
          workspace,
          absoluteSourcePath: '   ',
        ),
        throwsA(
          isA<EditorValidationException>().having(
            (error) => error.message,
            'message',
            'Pokemon species source path cannot be empty',
          ),
        ),
      );
    });

    test('imports one internal species json into the local species directory',
        () async {
      final sourceFile = await _writeSourceJson(
        tempImportRoot,
        'bulbasaur.json',
        _bulbasaurSpecies.toJson(),
      );
      final beforeProjectJson = await projectFile.readAsString();

      final imported = await useCase.execute(
        workspace,
        absoluteSourcePath: sourceFile.path,
      );

      expect(imported.id, 'bulbasaur');
      expect(imported.nationalDex, 1);

      final savedFile = File(
        workspace.resolveProjectRelativePath(
          'data/pokemon/species/0001-bulbasaur.json',
        ),
      );
      expect(await savedFile.exists(), isTrue);

      final readBack =
          await readRepository.readSpeciesById(workspace, 'bulbasaur');
      expect(readBack.id, 'bulbasaur');
      expect(readBack.typing.types, <String>['grass', 'poison']);
      expect(readBack.refs.learnset, 'bulbasaur');
      expect(await projectFile.readAsString(), beforeProjectJson);
    });

    test('fails clearly when the source file does not exist', () async {
      await expectLater(
        () => useCase.execute(
          workspace,
          absoluteSourcePath: '${tempImportRoot.path}/missing.json',
        ),
        throwsA(
          isA<EditorValidationException>().having(
            (error) => error.message,
            'message',
            'Pokemon species source file not found',
          ),
        ),
      );
    });

    test('fails clearly when the source file is not a json file', () async {
      final sourceFile = File('${tempImportRoot.path}/bulbasaur.txt');
      await sourceFile.writeAsString('not a json import');

      await expectLater(
        () => useCase.execute(
          workspace,
          absoluteSourcePath: sourceFile.path,
        ),
        throwsA(
          isA<EditorValidationException>().having(
            (error) => error.message,
            'message',
            'Pokemon species import expects a .json file',
          ),
        ),
      );
    });

    test('fails clearly when the source json is syntactically invalid',
        () async {
      final sourceFile = File('${tempImportRoot.path}/broken.json');
      await sourceFile.writeAsString('{ this is not valid json');

      await expectLater(
        () => useCase.execute(
          workspace,
          absoluteSourcePath: sourceFile.path,
        ),
        throwsA(
          isA<EditorPersistenceException>().having(
            (error) => error.message,
            'message',
            contains('Pokemon species JSON is invalid'),
          ),
        ),
      );
    });

    test('fails clearly when the source json root is not an object', () async {
      final sourceFile = await _writeSourceJson(
        tempImportRoot,
        'array.json',
        <Object?>['not', 'an', 'object'],
      );

      await expectLater(
        () => useCase.execute(
          workspace,
          absoluteSourcePath: sourceFile.path,
        ),
        throwsA(
          isA<EditorPersistenceException>().having(
            (error) => error.message,
            'message',
            'Pokemon species JSON root must be an object',
          ),
        ),
      );
    });

    test('fails clearly when the source json has wrong field types', () async {
      final brokenJson = _bulbasaurSpecies.toJson()
        ..['names'] = <Object?>['not', 'a', 'map'];
      final sourceFile = await _writeSourceJson(
        tempImportRoot,
        'wrong-types.json',
        brokenJson,
      );

      await expectLater(
        () => useCase.execute(
          workspace,
          absoluteSourcePath: sourceFile.path,
        ),
        throwsA(
          isA<EditorPersistenceException>().having(
            (error) => error.message,
            'message',
            contains('Pokemon species JSON structure is invalid'),
          ),
        ),
      );
    });

    test('fails clearly when the parsed species is structurally invalid',
        () async {
      final brokenJson = _bulbasaurSpecies.toJson()
        ..['id'] = '   '
        ..['slug'] = '';
      final sourceFile = await _writeSourceJson(
        tempImportRoot,
        'broken-species.json',
        brokenJson,
      );

      await expectLater(
        () => useCase.execute(
          workspace,
          absoluteSourcePath: sourceFile.path,
        ),
        throwsA(
          isA<EditorValidationException>().having(
            (error) => error.message,
            'message',
            'Pokemon species id cannot be empty',
          ),
        ),
      );

      expect(
        await File(
          workspace.resolveProjectRelativePath(
            'data/pokemon/species/0001-bulbasaur.json',
          ),
        ).exists(),
        isFalse,
      );
    });

    test('fails clearly when the species has no usable names', () async {
      final brokenJson = _bulbasaurSpecies.toJson()
        ..['names'] = <String, String>{'fr': '   ', 'en': ''};
      final sourceFile = await _writeSourceJson(
        tempImportRoot,
        'nameless.json',
        brokenJson,
      );

      await expectLater(
        () => useCase.execute(
          workspace,
          absoluteSourcePath: sourceFile.path,
        ),
        throwsA(
          isA<EditorValidationException>().having(
            (error) => error.message,
            'message',
            'Pokemon species names cannot be empty',
          ),
        ),
      );
    });

    test('fails clearly when genIntroduced is not positive', () async {
      final brokenJson = _bulbasaurSpecies.toJson()..['genIntroduced'] = 0;
      final sourceFile = await _writeSourceJson(
        tempImportRoot,
        'invalid-generation.json',
        brokenJson,
      );

      await expectLater(
        () => useCase.execute(
          workspace,
          absoluteSourcePath: sourceFile.path,
        ),
        throwsA(
          isA<EditorValidationException>().having(
            (error) => error.message,
            'message',
            'Pokemon species genIntroduced must be positive',
          ),
        ),
      );
    });

    test('fails clearly when the species has no type declared', () async {
      final brokenJson = _bulbasaurSpecies.toJson()
        ..['typing'] = <String, Object?>{'types': <String>[]};
      final sourceFile = await _writeSourceJson(
        tempImportRoot,
        'typeless.json',
        brokenJson,
      );

      await expectLater(
        () => useCase.execute(
          workspace,
          absoluteSourcePath: sourceFile.path,
        ),
        throwsA(
          isA<EditorValidationException>().having(
            (error) => error.message,
            'message',
            'Pokemon species must declare at least one type',
          ),
        ),
      );
    });

    test('fails clearly when refs.learnset is empty', () async {
      final brokenJson = _bulbasaurSpecies.toJson()
        ..['refs'] = <String, Object?>{
          'learnset': '   ',
          'evolution': 'bulbasaur',
          'media': 'bulbasaur',
        };
      final sourceFile = await _writeSourceJson(
        tempImportRoot,
        'missing-learnset-ref.json',
        brokenJson,
      );

      await expectLater(
        () => useCase.execute(
          workspace,
          absoluteSourcePath: sourceFile.path,
        ),
        throwsA(
          isA<EditorValidationException>().having(
            (error) => error.message,
            'message',
            'Pokemon species refs.learnset cannot be empty',
          ),
        ),
      );
    });

    test('fails clearly when refs.evolution is empty', () async {
      final brokenJson = _bulbasaurSpecies.toJson()
        ..['refs'] = <String, Object?>{
          'learnset': 'bulbasaur',
          'evolution': '',
          'media': 'bulbasaur',
        };
      final sourceFile = await _writeSourceJson(
        tempImportRoot,
        'missing-evolution-ref.json',
        brokenJson,
      );

      await expectLater(
        () => useCase.execute(
          workspace,
          absoluteSourcePath: sourceFile.path,
        ),
        throwsA(
          isA<EditorValidationException>().having(
            (error) => error.message,
            'message',
            'Pokemon species refs.evolution cannot be empty',
          ),
        ),
      );
    });

    test('fails clearly when refs.media is empty', () async {
      final brokenJson = _bulbasaurSpecies.toJson()
        ..['refs'] = <String, Object?>{
          'learnset': 'bulbasaur',
          'evolution': 'bulbasaur',
          'media': ' ',
        };
      final sourceFile = await _writeSourceJson(
        tempImportRoot,
        'missing-media-ref.json',
        brokenJson,
      );

      await expectLater(
        () => useCase.execute(
          workspace,
          absoluteSourcePath: sourceFile.path,
        ),
        throwsA(
          isA<EditorValidationException>().having(
            (error) => error.message,
            'message',
            'Pokemon species refs.media cannot be empty',
          ),
        ),
      );
    });
  });
}

Future<File> _writeSourceJson(
  Directory importRoot,
  String fileName,
  Object payload,
) async {
  final file = File('${importRoot.path}/$fileName');
  await file.writeAsString(
    const JsonEncoder.withIndent('  ').convert(payload),
  );
  return file;
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
    'fr': 'Pokemon Graine',
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
    flavorText: 'A strange seed was planted on its back at birth.',
  ),
  gameplayFlags: PokemonSpeciesGameplayFlags(
    starterEligible: true,
  ),
  sourceMeta: PokemonSpeciesSourceMeta(
    seededBy: 'test',
    seedVersion: 1,
  ),
);
