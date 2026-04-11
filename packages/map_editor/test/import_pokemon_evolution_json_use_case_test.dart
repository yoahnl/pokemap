import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/application/errors/application_errors.dart';
import 'package:map_editor/src/application/models/pokemon_project_data_models.dart';
import 'package:map_editor/src/application/use_cases/import_pokemon_evolution_json_use_case.dart';
import 'package:map_editor/src/application/use_cases/initialize_pokemon_project_storage_use_case.dart';
import 'package:map_editor/src/application/use_cases/project_management_use_cases.dart';
import 'package:map_editor/src/infrastructure/filesystem/project_filesystem.dart';
import 'package:map_editor/src/infrastructure/repositories/file_repositories.dart';

void main() {
  late Directory tempProjectRoot;
  late Directory tempImportRoot;
  late ProjectFileSystem workspace;
  late ImportPokemonEvolutionJsonUseCase useCase;
  late FilePokemonReadRepository readRepository;
  late File projectFile;

  setUp(() async {
    tempProjectRoot = await Directory.systemTemp.createTemp(
      'pokemon_evolution_import_project_',
    );
    tempImportRoot = await Directory.systemTemp.createTemp(
      'pokemon_evolution_import_source_',
    );
    workspace = ProjectFileSystem(tempProjectRoot.path);
    useCase = const ImportPokemonEvolutionJsonUseCase(
      FilePokemonWriteRepository(),
    );
    readRepository = const FilePokemonReadRepository();

    final createProjectUseCase = CreateProjectUseCase(
      FileProjectRepository(),
      const FileProjectWorkspaceFactory(),
    );
    await createProjectUseCase.execute(
      'Pokemon Evolution Import Project',
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

  group('ImportPokemonEvolutionJsonUseCase', () {
    test(
        'imports one internal evolution json into the local evolutions directory',
        () async {
      final sourceFile = await _writeSourceJson(
        tempImportRoot,
        'bulbasaur.json',
        _bulbasaurEvolution.toJson(),
      );
      final beforeProjectJson = await projectFile.readAsString();

      final imported = await useCase.execute(
        workspace,
        absoluteSourcePath: sourceFile.path,
      );

      expect(imported.speciesId, 'bulbasaur');
      expect(imported.evolutions, hasLength(1));

      final savedFile = File(
        workspace.resolveProjectRelativePath(
          'data/pokemon/evolutions/bulbasaur.json',
        ),
      );
      expect(await savedFile.exists(), isTrue);

      final readBack =
          await readRepository.readEvolutionById(workspace, 'bulbasaur');
      expect(readBack.speciesId, 'bulbasaur');
      expect(readBack.evolutions.single.targetSpeciesId, 'ivysaur');
      expect(await projectFile.readAsString(), beforeProjectJson);
    });

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
            'Pokemon evolution source path cannot be empty',
          ),
        ),
      );
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
            'Pokemon evolution source file not found',
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
            'Pokemon evolution import expects a .json file',
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
            contains('Pokemon evolution JSON is invalid'),
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
            'Pokemon evolution JSON root must be an object',
          ),
        ),
      );
    });

    test('fails clearly when the source json has wrong field types', () async {
      final brokenJson = _bulbasaurEvolution.toJson()
        ..['evolutions'] = <Object?>[
          <String, Object?>{
            'targetSpeciesId': 'ivysaur',
            'method': 'level_up',
            'minLevel': 'oops',
          },
        ];
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
            contains('Pokemon evolution JSON structure is invalid'),
          ),
        ),
      );
    });

    test('fails clearly when the parsed evolution is structurally invalid',
        () async {
      final brokenJson = _bulbasaurEvolution.toJson()
        ..['speciesId'] = '  '
        ..['preEvolution'] = null
        ..['evolutions'] = <Object?>[];
      final sourceFile = await _writeSourceJson(
        tempImportRoot,
        'broken-evolution.json',
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
            'Pokemon evolution speciesId cannot be empty',
          ),
        ),
      );

      expect(
        await File(
          workspace.resolveProjectRelativePath(
            'data/pokemon/evolutions/bulbasaur.json',
          ),
        ).exists(),
        isFalse,
      );
    });

    test('fails clearly when the file defines no chain information', () async {
      final brokenJson = _bulbasaurEvolution.toJson()
        ..['preEvolution'] = null
        ..['evolutions'] = <Object?>[];
      final sourceFile = await _writeSourceJson(
        tempImportRoot,
        'empty-chain.json',
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
            'Pokemon evolution must define preEvolution or evolutions',
          ),
        ),
      );
    });

    test('fails clearly when an evolution target is empty', () async {
      final brokenJson = _bulbasaurEvolution.toJson()
        ..['evolutions'] = <Object?>[
          <String, Object?>{
            'targetSpeciesId': ' ',
            'method': 'level_up',
            'minLevel': 16,
          },
        ];
      final sourceFile = await _writeSourceJson(
        tempImportRoot,
        'empty-target.json',
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
            'Pokemon evolution targetSpeciesId cannot be empty',
          ),
        ),
      );
    });

    test('fails clearly when an evolution targets itself', () async {
      final brokenJson = _bulbasaurEvolution.toJson()
        ..['evolutions'] = <Object?>[
          <String, Object?>{
            'targetSpeciesId': 'bulbasaur',
            'method': 'level_up',
            'minLevel': 16,
          },
        ];
      final sourceFile = await _writeSourceJson(
        tempImportRoot,
        'self-target.json',
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
            'Pokemon evolution cannot target itself',
          ),
        ),
      );
    });

    test('fails clearly when an evolution method is empty', () async {
      final brokenJson = _bulbasaurEvolution.toJson()
        ..['evolutions'] = <Object?>[
          <String, Object?>{
            'targetSpeciesId': 'ivysaur',
            'method': ' ',
            'minLevel': 16,
          },
        ];
      final sourceFile = await _writeSourceJson(
        tempImportRoot,
        'empty-method.json',
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
            'Pokemon evolution method cannot be empty',
          ),
        ),
      );
    });

    test('fails clearly when level_up minLevel is not positive', () async {
      final brokenJson = _bulbasaurEvolution.toJson()
        ..['evolutions'] = <Object?>[
          <String, Object?>{
            'targetSpeciesId': 'ivysaur',
            'method': 'level_up',
            'minLevel': 0,
          },
        ];
      final sourceFile = await _writeSourceJson(
        tempImportRoot,
        'invalid-min-level.json',
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
            'Pokemon evolution minLevel must be positive for level_up',
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

const PokemonEvolutionFile _bulbasaurEvolution = PokemonEvolutionFile(
  speciesId: 'bulbasaur',
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
);
