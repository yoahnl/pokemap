import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/application/errors/application_errors.dart';
import 'package:map_editor/src/application/models/pokemon_project_data_models.dart';
import 'package:map_editor/src/application/use_cases/import_pokemon_media_json_use_case.dart';
import 'package:map_editor/src/application/use_cases/initialize_pokemon_project_storage_use_case.dart';
import 'package:map_editor/src/application/use_cases/project_management_use_cases.dart';
import 'package:map_editor/src/infrastructure/filesystem/project_filesystem.dart';
import 'package:map_editor/src/infrastructure/repositories/file_repositories.dart';

void main() {
  late Directory tempProjectRoot;
  late Directory tempImportRoot;
  late ProjectFileSystem workspace;
  late ImportPokemonMediaJsonUseCase useCase;
  late FilePokemonReadRepository readRepository;
  late File projectFile;

  setUp(() async {
    tempProjectRoot = await Directory.systemTemp.createTemp(
      'pokemon_media_import_project_',
    );
    tempImportRoot = await Directory.systemTemp.createTemp(
      'pokemon_media_import_source_',
    );
    workspace = ProjectFileSystem(tempProjectRoot.path);
    useCase = const ImportPokemonMediaJsonUseCase(
      FilePokemonWriteRepository(),
    );
    readRepository = const FilePokemonReadRepository();

    final createProjectUseCase = CreateProjectUseCase(
      FileProjectRepository(),
      const FileProjectWorkspaceFactory(),
    );
    await createProjectUseCase.execute(
      'Pokemon Media Import Project',
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

  group('ImportPokemonMediaJsonUseCase', () {
    test('imports one internal media json into the local media directory',
        () async {
      final sourceFile = await _writeSourceJson(
        tempImportRoot,
        'bulbasaur.json',
        _bulbasaurMedia.toJson(),
      );
      final beforeProjectJson = await projectFile.readAsString();

      final imported = await useCase.execute(
        workspace,
        absoluteSourcePath: sourceFile.path,
      );

      expect(imported.speciesId, 'bulbasaur');
      expect(imported.defaultFormId, 'base');

      final savedFile = File(
        workspace.resolveProjectRelativePath(
          'data/pokemon/media/bulbasaur.json',
        ),
      );
      expect(await savedFile.exists(), isTrue);

      final readBack =
          await readRepository.readMediaById(workspace, 'bulbasaur');
      expect(readBack.speciesId, 'bulbasaur');
      expect(
        readBack.variants['base']?.frontStatic,
        'assets/pokemon/sprites/bulbasaur/front.png',
      );
      expect(
        readBack.variants['base']?.animations['battleFront']?.animationId,
        'battle_front',
      );
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
            'Pokemon media source path cannot be empty',
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
            'Pokemon media source file not found',
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
            'Pokemon media import expects a .json file',
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
            contains('Pokemon media JSON is invalid'),
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
            'Pokemon media JSON root must be an object',
          ),
        ),
      );
    });

    test('fails clearly when the source json has wrong field types', () async {
      final brokenJson = _bulbasaurMedia.toJson()
        ..['variants'] = <String, Object?>{
          'base': <String, Object?>{
            'frontStatic': 42,
          },
        };
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
            contains('Pokemon media JSON structure is invalid'),
          ),
        ),
      );
    });

    test('fails clearly when speciesId is empty', () async {
      final brokenJson = _bulbasaurMedia.toJson()..['speciesId'] = '  ';
      final sourceFile = await _writeSourceJson(
        tempImportRoot,
        'empty-species.json',
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
            'Pokemon media speciesId cannot be empty',
          ),
        ),
      );
    });

    test('fails clearly when defaultFormId is empty', () async {
      final brokenJson = _bulbasaurMedia.toJson()..['defaultFormId'] = ' ';
      final sourceFile = await _writeSourceJson(
        tempImportRoot,
        'empty-default-form.json',
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
            'Pokemon media defaultFormId cannot be empty',
          ),
        ),
      );
    });

    test('fails clearly when no variants are defined', () async {
      final brokenJson = _bulbasaurMedia.toJson()
        ..['variants'] = <String, Object?>{};
      final sourceFile = await _writeSourceJson(
        tempImportRoot,
        'empty-variants.json',
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
            'Pokemon media must define at least one variant',
          ),
        ),
      );
    });

    test('fails clearly when defaultFormId is absent from variants', () async {
      final brokenJson = _bulbasaurMedia.toJson()
        ..['defaultFormId'] = 'mega'
        ..['variants'] = <String, Object?>{
          'base': (_bulbasaurMedia.variants['base']!).toJson(),
        };
      final sourceFile = await _writeSourceJson(
        tempImportRoot,
        'missing-default-variant.json',
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
            'Pokemon media defaultFormId must exist in variants',
          ),
        ),
      );
    });

    test('fails clearly when all variants are empty', () async {
      final brokenJson = _bulbasaurMedia.toJson()
        ..['variants'] = <String, Object?>{
          'base': const <String, Object?>{},
        };
      final sourceFile = await _writeSourceJson(
        tempImportRoot,
        'empty-media.json',
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
            'Pokemon media must contain at least one media reference',
          ),
        ),
      );
    });

    test('fails clearly when an animation ref is structurally unusable',
        () async {
      final brokenJson = _bulbasaurMedia.toJson()
        ..['variants'] = <String, Object?>{
          'base': <String, Object?>{
            'animations': <String, Object?>{
              'battleFront': <String, Object?>{
                'sheet': ' ',
                'animationId': 'battle_front',
              },
            },
          },
        };
      final sourceFile = await _writeSourceJson(
        tempImportRoot,
        'broken-animation.json',
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
            'Pokemon media animation sheet cannot be empty',
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

const PokemonMediaFile _bulbasaurMedia = PokemonMediaFile(
  speciesId: 'bulbasaur',
  defaultFormId: 'base',
  variants: <String, PokemonMediaVariant>{
    'base': PokemonMediaVariant(
      frontStatic: 'assets/pokemon/sprites/bulbasaur/front.png',
      backStatic: 'assets/pokemon/sprites/bulbasaur/back.png',
      icon: 'assets/pokemon/sprites/bulbasaur/icon.png',
      party: 'assets/pokemon/sprites/bulbasaur/party.png',
      overworld: 'assets/pokemon/sprites/bulbasaur/overworld.png',
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
