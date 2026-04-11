import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/application/errors/application_errors.dart';
import 'package:map_editor/src/application/models/pokemon_project_data_models.dart';
import 'package:map_editor/src/application/use_cases/import_pokemon_catalog_json_use_case.dart';
import 'package:map_editor/src/application/use_cases/initialize_pokemon_project_storage_use_case.dart';
import 'package:map_editor/src/application/use_cases/project_management_use_cases.dart';
import 'package:map_editor/src/infrastructure/filesystem/project_filesystem.dart';
import 'package:map_editor/src/infrastructure/repositories/file_repositories.dart';

void main() {
  late Directory tempProjectRoot;
  late Directory tempImportRoot;
  late ProjectFileSystem workspace;
  late ImportPokemonCatalogJsonUseCase useCase;
  late FilePokemonReadRepository readRepository;
  late File projectFile;

  setUp(() async {
    tempProjectRoot = await Directory.systemTemp.createTemp(
      'pokemon_catalog_import_project_',
    );
    tempImportRoot = await Directory.systemTemp.createTemp(
      'pokemon_catalog_import_source_',
    );
    workspace = ProjectFileSystem(tempProjectRoot.path);
    useCase = const ImportPokemonCatalogJsonUseCase(
      FilePokemonWriteRepository(),
    );
    readRepository = const FilePokemonReadRepository();

    final createProjectUseCase = CreateProjectUseCase(
      FileProjectRepository(),
      const FileProjectWorkspaceFactory(),
    );
    await createProjectUseCase.execute(
      'Pokemon Catalog Import Project',
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

  group('ImportPokemonCatalogJsonUseCase', () {
    test('imports one internal catalog json into the local catalogs directory',
        () async {
      final sourceFile = await _writeSourceJson(
        tempImportRoot,
        'moves.json',
        _movesCatalog.toJson(),
      );
      final beforeProjectJson = await projectFile.readAsString();

      final imported = await useCase.execute(
        workspace,
        catalogKey: 'moves',
        absoluteSourcePath: sourceFile.path,
      );

      expect(imported.catalog, 'moves');
      expect(imported.entries, hasLength(2));

      final savedFile = File(
        workspace.resolveProjectRelativePath(
          'data/pokemon/catalogs/moves.json',
        ),
      );
      expect(await savedFile.exists(), isTrue);

      final readBack =
          await readRepository.readCatalogByKey(workspace, 'moves');
      expect(readBack.catalog, 'moves');
      expect(
        readBack.entries.map((entry) => entry['id']),
        containsAll(<String>['tackle', 'growl']),
      );
      expect(await projectFile.readAsString(), beforeProjectJson);
    });

    test('fails clearly when the catalog key is empty', () async {
      final sourceFile = await _writeSourceJson(
        tempImportRoot,
        'moves.json',
        _movesCatalog.toJson(),
      );

      await expectLater(
        () => useCase.execute(
          workspace,
          catalogKey: '   ',
          absoluteSourcePath: sourceFile.path,
        ),
        throwsA(
          isA<EditorValidationException>().having(
            (error) => error.message,
            'message',
            'Pokemon catalog key cannot be empty',
          ),
        ),
      );
    });

    test('fails clearly when the source path is empty', () async {
      await expectLater(
        () => useCase.execute(
          workspace,
          catalogKey: 'moves',
          absoluteSourcePath: '   ',
        ),
        throwsA(
          isA<EditorValidationException>().having(
            (error) => error.message,
            'message',
            'Pokemon catalog source path cannot be empty',
          ),
        ),
      );
    });

    test('fails clearly when the source file does not exist', () async {
      await expectLater(
        () => useCase.execute(
          workspace,
          catalogKey: 'moves',
          absoluteSourcePath: '${tempImportRoot.path}/missing.json',
        ),
        throwsA(
          isA<EditorValidationException>().having(
            (error) => error.message,
            'message',
            'Pokemon catalog source file not found',
          ),
        ),
      );
    });

    test('fails clearly when the source file is not a json file', () async {
      final sourceFile = File('${tempImportRoot.path}/moves.txt');
      await sourceFile.writeAsString('not a json import');

      await expectLater(
        () => useCase.execute(
          workspace,
          catalogKey: 'moves',
          absoluteSourcePath: sourceFile.path,
        ),
        throwsA(
          isA<EditorValidationException>().having(
            (error) => error.message,
            'message',
            'Pokemon catalog import expects a .json file',
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
          catalogKey: 'moves',
          absoluteSourcePath: sourceFile.path,
        ),
        throwsA(
          isA<EditorPersistenceException>().having(
            (error) => error.message,
            'message',
            contains('Pokemon catalog JSON is invalid'),
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
          catalogKey: 'moves',
          absoluteSourcePath: sourceFile.path,
        ),
        throwsA(
          isA<EditorPersistenceException>().having(
            (error) => error.message,
            'message',
            'Pokemon catalog JSON root must be an object',
          ),
        ),
      );
    });

    test('fails clearly when the source json has wrong field types', () async {
      final brokenJson = _movesCatalog.toJson()
        ..['meta'] = <Object?>['not', 'a', 'map'];
      final sourceFile = await _writeSourceJson(
        tempImportRoot,
        'wrong-types.json',
        brokenJson,
      );

      await expectLater(
        () => useCase.execute(
          workspace,
          catalogKey: 'moves',
          absoluteSourcePath: sourceFile.path,
        ),
        throwsA(
          isA<EditorPersistenceException>().having(
            (error) => error.message,
            'message',
            contains('Pokemon catalog JSON structure is invalid'),
          ),
        ),
      );
    });

    test('fails clearly when the parsed catalog is structurally invalid',
        () async {
      final brokenJson = _movesCatalog.toJson()
        ..['schemaVersion'] = 0
        ..['entries'] = <Object?>[];
      final targetFile = File(
        workspace.resolveProjectRelativePath(
          'data/pokemon/catalogs/moves.json',
        ),
      );
      final beforeExists = await targetFile.exists();
      final beforeContents =
          beforeExists ? await targetFile.readAsString() : null;
      final sourceFile = await _writeSourceJson(
        tempImportRoot,
        'broken-catalog.json',
        brokenJson,
      );

      await expectLater(
        () => useCase.execute(
          workspace,
          catalogKey: 'moves',
          absoluteSourcePath: sourceFile.path,
        ),
        throwsA(
          isA<EditorValidationException>().having(
            (error) => error.message,
            'message',
            'Pokemon catalog schemaVersion must be positive',
          ),
        ),
      );

      expect(await targetFile.exists(), beforeExists);
      if (beforeContents != null) {
        expect(await targetFile.readAsString(), beforeContents);
      }
    });

    test('fails clearly when the catalog has no entries', () async {
      final brokenJson = _movesCatalog.toJson()..['entries'] = <Object?>[];
      final sourceFile = await _writeSourceJson(
        tempImportRoot,
        'empty-entries.json',
        brokenJson,
      );

      await expectLater(
        () => useCase.execute(
          workspace,
          catalogKey: 'moves',
          absoluteSourcePath: sourceFile.path,
        ),
        throwsA(
          isA<EditorValidationException>().having(
            (error) => error.message,
            'message',
            'Pokemon catalog entries cannot be empty',
          ),
        ),
      );
    });

    test('fails clearly when the catalog entry id is missing', () async {
      final brokenJson = _movesCatalog.toJson()
        ..['entries'] = <Object?>[
          <String, Object?>{
            'id': ' ',
            'name': 'Broken',
          },
        ];
      final sourceFile = await _writeSourceJson(
        tempImportRoot,
        'missing-entry-id.json',
        brokenJson,
      );

      await expectLater(
        () => useCase.execute(
          workspace,
          catalogKey: 'moves',
          absoluteSourcePath: sourceFile.path,
        ),
        throwsA(
          isA<EditorValidationException>().having(
            (error) => error.message,
            'message',
            'Pokemon catalog entries must define a non-empty id',
          ),
        ),
      );
    });

    test('fails clearly when the catalog key does not match the payload',
        () async {
      final sourceFile = await _writeSourceJson(
        tempImportRoot,
        'abilities.json',
        _abilitiesCatalog.toJson(),
      );

      await expectLater(
        () => useCase.execute(
          workspace,
          catalogKey: 'moves',
          absoluteSourcePath: sourceFile.path,
        ),
        throwsA(
          isA<EditorValidationException>().having(
            (error) => error.message,
            'message',
            'Pokemon catalog key mismatch: requested "moves" but payload is '
                '"abilities"',
          ),
        ),
      );
    });

    test('fails clearly when the catalog key is not supported by storage',
        () async {
      final sourceFile = await _writeSourceJson(
        tempImportRoot,
        'berries.json',
        _berriesCatalog.toJson(),
      );

      await expectLater(
        () => useCase.execute(
          workspace,
          catalogKey: 'berries',
          absoluteSourcePath: sourceFile.path,
        ),
        throwsA(
          isA<EditorNotFoundException>().having(
            (error) => error.message,
            'message',
            'Pokemon catalog write path not declared for key: berries',
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

const PokemonCatalogFile _movesCatalog = PokemonCatalogFile(
  schemaVersion: 1,
  kind: 'pokemon_catalog',
  catalog: 'moves',
  meta: PokemonDataMeta(
    description: 'Move catalog for the local Pokemon project database.',
    sourcePriority: <String>['internal'],
    notes: <String>['Import catalog integration test data.'],
  ),
  entries: <Map<String, dynamic>>[
    <String, dynamic>{
      'id': 'tackle',
      'name': 'Tackle',
      'type': 'normal',
    },
    <String, dynamic>{
      'id': 'growl',
      'name': 'Growl',
      'type': 'normal',
    },
  ],
);

const PokemonCatalogFile _abilitiesCatalog = PokemonCatalogFile(
  schemaVersion: 1,
  kind: 'pokemon_catalog',
  catalog: 'abilities',
  meta: PokemonDataMeta(
    description: 'Ability catalog for mismatch test.',
    sourcePriority: <String>['internal'],
    notes: <String>[],
  ),
  entries: <Map<String, dynamic>>[
    <String, dynamic>{
      'id': 'overgrow',
      'name': 'Overgrow',
    },
  ],
);

const PokemonCatalogFile _berriesCatalog = PokemonCatalogFile(
  schemaVersion: 1,
  kind: 'pokemon_catalog',
  catalog: 'berries',
  meta: PokemonDataMeta(
    description: 'Unsupported catalog for storage-key test.',
    sourcePriority: <String>['internal'],
    notes: <String>[],
  ),
  entries: <Map<String, dynamic>>[
    <String, dynamic>{
      'id': 'oran_berry',
      'name': 'Oran Berry',
    },
  ],
);
