import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/application/errors/application_errors.dart';
import 'package:map_editor/src/application/models/pokemon_project_data_models.dart';
import 'package:map_editor/src/application/use_cases/import_pokemon_learnset_json_use_case.dart';
import 'package:map_editor/src/application/use_cases/initialize_pokemon_project_storage_use_case.dart';
import 'package:map_editor/src/application/use_cases/project_management_use_cases.dart';
import 'package:map_editor/src/infrastructure/filesystem/project_filesystem.dart';
import 'package:map_editor/src/infrastructure/repositories/file_repositories.dart';

void main() {
  late Directory tempProjectRoot;
  late Directory tempImportRoot;
  late ProjectFileSystem workspace;
  late ImportPokemonLearnsetJsonUseCase useCase;
  late FilePokemonReadRepository readRepository;
  late File projectFile;

  setUp(() async {
    tempProjectRoot = await Directory.systemTemp.createTemp(
      'pokemon_learnset_import_project_',
    );
    tempImportRoot = await Directory.systemTemp.createTemp(
      'pokemon_learnset_import_source_',
    );
    workspace = ProjectFileSystem(tempProjectRoot.path);
    useCase = const ImportPokemonLearnsetJsonUseCase(
      FilePokemonWriteRepository(),
    );
    readRepository = const FilePokemonReadRepository();

    final createProjectUseCase = CreateProjectUseCase(
      FileProjectRepository(),
      const FileProjectWorkspaceFactory(),
    );
    await createProjectUseCase.execute(
      'Pokemon Learnset Import Project',
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

  group('ImportPokemonLearnsetJsonUseCase', () {
    test(
        'imports one internal learnset json into the local learnsets directory',
        () async {
      final sourceFile = await _writeSourceJson(
        tempImportRoot,
        'bulbasaur.json',
        _bulbasaurLearnset.toJson(),
      );
      final beforeProjectJson = await projectFile.readAsString();

      final imported = await useCase.execute(
        workspace,
        absoluteSourcePath: sourceFile.path,
      );

      expect(imported.speciesId, 'bulbasaur');
      expect(imported.levelUp, hasLength(2));

      final savedFile = File(
        workspace.resolveProjectRelativePath(
          'data/pokemon/learnsets/bulbasaur.json',
        ),
      );
      expect(await savedFile.exists(), isTrue);

      final readBack =
          await readRepository.readLearnsetById(workspace, 'bulbasaur');
      expect(readBack.speciesId, 'bulbasaur');
      expect(readBack.tm.single.moveId, 'protect');
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
            'Pokemon learnset source path cannot be empty',
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
            'Pokemon learnset source file not found',
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
            'Pokemon learnset import expects a .json file',
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
            contains('Pokemon learnset JSON is invalid'),
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
            'Pokemon learnset JSON root must be an object',
          ),
        ),
      );
    });

    test('fails clearly when the source json has wrong field types', () async {
      final brokenJson = _bulbasaurLearnset.toJson()
        ..['levelUp'] = <Object?>[
          <String, Object?>{
            'moveId': 'tackle',
            'level': 'oops',
            'source': 'level-up',
            'versionGroup': 'scarlet-violet',
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
            contains('Pokemon learnset JSON structure is invalid'),
          ),
        ),
      );
    });

    test('fails clearly when the parsed learnset is structurally invalid',
        () async {
      final brokenJson = _bulbasaurLearnset.toJson()
        ..['speciesId'] = '  '
        ..['startingMoves'] = <String>[]
        ..['relearnMoves'] = <String>[]
        ..['levelUp'] = <Object?>[]
        ..['tm'] = <Object?>[]
        ..['tutor'] = <Object?>[]
        ..['egg'] = <Object?>[]
        ..['event'] = <Object?>[]
        ..['transfer'] = <Object?>[];
      final sourceFile = await _writeSourceJson(
        tempImportRoot,
        'broken-learnset.json',
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
            'Pokemon learnset speciesId cannot be empty',
          ),
        ),
      );

      expect(
        await File(
          workspace.resolveProjectRelativePath(
            'data/pokemon/learnsets/bulbasaur.json',
          ),
        ).exists(),
        isFalse,
      );
    });

    test('fails clearly when the learnset has no move section', () async {
      final brokenJson = _bulbasaurLearnset.toJson()
        ..['startingMoves'] = <String>[]
        ..['relearnMoves'] = <String>[]
        ..['levelUp'] = <Object?>[]
        ..['tm'] = <Object?>[]
        ..['tutor'] = <Object?>[]
        ..['egg'] = <Object?>[]
        ..['event'] = <Object?>[]
        ..['transfer'] = <Object?>[];
      final sourceFile = await _writeSourceJson(
        tempImportRoot,
        'empty-learnset.json',
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
            'Pokemon learnset must contain at least one move section',
          ),
        ),
      );
    });

    test('fails clearly when a level-up entry is incomplete', () async {
      final brokenJson = _bulbasaurLearnset.toJson()
        ..['levelUp'] = <Object?>[
          <String, Object?>{
            'moveId': 'vine-whip',
            'level': 7,
            'source': 'level-up',
            'versionGroup': '',
          },
        ];
      final sourceFile = await _writeSourceJson(
        tempImportRoot,
        'broken-level-up.json',
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
            'Pokemon learnset levelUp versionGroup cannot be empty',
          ),
        ),
      );
    });

    test('fails clearly when a move-entry section is incomplete', () async {
      final brokenJson = _bulbasaurLearnset.toJson()
        ..['tm'] = <Object?>[
          <String, Object?>{
            'moveId': 'protect',
            'versionGroup': ' ',
          },
        ];
      final sourceFile = await _writeSourceJson(
        tempImportRoot,
        'broken-tm.json',
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
            'Pokemon learnset tm versionGroup cannot be empty',
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

const PokemonLearnsetFile _bulbasaurLearnset = PokemonLearnsetFile(
  speciesId: 'bulbasaur',
  startingMoves: <String>['tackle', 'growl'],
  relearnMoves: <String>['tackle', 'growl', 'vine-whip'],
  levelUp: <PokemonLearnsetLevelUpEntry>[
    PokemonLearnsetLevelUpEntry(
      moveId: 'tackle',
      level: 1,
      source: 'level-up',
      versionGroup: 'scarlet-violet',
    ),
    PokemonLearnsetLevelUpEntry(
      moveId: 'vine-whip',
      level: 7,
      source: 'level-up',
      versionGroup: 'scarlet-violet',
    ),
  ],
  tm: <PokemonLearnsetMoveEntry>[
    PokemonLearnsetMoveEntry(
      moveId: 'protect',
      versionGroup: 'scarlet-violet',
    ),
  ],
  tutor: <PokemonLearnsetMoveEntry>[
    PokemonLearnsetMoveEntry(
      moveId: 'seed-bomb',
      versionGroup: 'scarlet-violet',
    ),
  ],
  egg: <PokemonLearnsetMoveEntry>[
    PokemonLearnsetMoveEntry(
      moveId: 'petal-dance',
      versionGroup: 'scarlet-violet',
    ),
  ],
  event: <PokemonLearnsetMoveEntry>[
    PokemonLearnsetMoveEntry(
      moveId: 'celebrate',
      versionGroup: 'scarlet-violet',
    ),
  ],
  transfer: <PokemonLearnsetMoveEntry>[
    PokemonLearnsetMoveEntry(
      moveId: 'toxic',
      versionGroup: 'scarlet-violet',
    ),
  ],
);
