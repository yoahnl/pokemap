import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/models/pokemon_project_data_models.dart';
import 'package:map_editor/src/application/ports/pokemon_external_source_repository.dart';
import 'package:map_editor/src/application/use_cases/initialize_pokemon_project_storage_use_case.dart';
import 'package:map_editor/src/application/use_cases/project_management_use_cases.dart';
import 'package:map_editor/src/application/use_cases/sync_pokemon_sdk_moves_catalog_use_case.dart';
import 'package:map_editor/src/infrastructure/external/pokemon_sdk_studio_payload.dart';
import 'package:map_editor/src/infrastructure/filesystem/project_filesystem.dart';
import 'package:map_editor/src/infrastructure/repositories/file_repositories.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory tempProjectRoot;
  late ProjectFileSystem workspace;
  late FilePokemonReadRepository readRepository;
  late FilePokemonWriteRepository writeRepository;
  late _FakePokemonSdkExternalSourceRepository externalRepository;
  late SyncPokemonSdkMovesCatalogUseCase useCase;

  setUp(() async {
    tempProjectRoot = await Directory.systemTemp.createTemp(
      'psdk_moves_catalog_sync_',
    );
    workspace = ProjectFileSystem(tempProjectRoot.path);
    readRepository = const FilePokemonReadRepository();
    writeRepository = const FilePokemonWriteRepository();
    externalRepository = _FakePokemonSdkExternalSourceRepository(
      payload: PokemonSdkStudioProjectPayload(
        moves: <Map<String, dynamic>>[
          _psdkMove(
            dbSymbol: 'tackle',
            name: 'Tackle',
            power: 40,
          ),
          _psdkMove(
            dbSymbol: 'thunder_wave',
            name: 'Thunder Wave',
            type: 'electric',
            category: 'status',
            power: 0,
            accuracy: 90,
            battleEngineMethod: 's_status',
          ),
        ],
        abilities: const <Map<String, dynamic>>[],
        items: const <Map<String, dynamic>>[],
        types: const <Map<String, dynamic>>[],
        pokemon: const <Map<String, dynamic>>[],
      ),
    );
    useCase = SyncPokemonSdkMovesCatalogUseCase(
      externalSourceRepository: externalRepository,
      readRepository: readRepository,
      writeRepository: writeRepository,
    );

    final createProjectUseCase = CreateProjectUseCase(
      FileProjectRepository(),
      const FileProjectWorkspaceFactory(),
    );
    await createProjectUseCase.execute(
      'PSDK Moves Catalog Sync Project',
      tempProjectRoot.path,
    );
    await const InitializePokemonProjectStorageUseCase().execute(workspace);
  });

  tearDown(() async {
    if (await tempProjectRoot.exists()) {
      await tempProjectRoot.delete(recursive: true);
    }
  });

  test('dry-run previews PSDK moves without writing files', () async {
    await writeRepository.saveCatalogByKey(
      workspace,
      'moves',
      _localPsdkCatalogBeforeSync,
    );
    final catalogFile = File(
      workspace.resolveProjectRelativePath('data/pokemon/catalogs/moves.json'),
    );
    final beforeCatalogJson = await catalogFile.readAsString();
    final projectFile = File(workspace.projectManifestPath);
    final beforeProjectJson = await projectFile.readAsString();

    final result = await useCase.execute(
      workspace,
      psdkProjectRootPath: '/tmp/fake-psdk-project',
      dryRun: true,
    );

    expect(result.dryRun, isTrue);
    expect(result.createdIds, <String>['tackle']);
    expect(result.updatedIds, <String>['thunder_wave']);
    expect(result.preservedLocalOnlyIds, <String>['custom_local_move']);
    expect(result.externalEntryCount, 2);
    expect(externalRepository.loadedProjectRoots, <String>[
      '/tmp/fake-psdk-project',
    ]);
    expect(await catalogFile.readAsString(), beforeCatalogJson);
    expect(await projectFile.readAsString(), beforeProjectJson);
  });

  test('sync writes canonical PSDK moves and preserves local-only fields',
      () async {
    await writeRepository.saveCatalogByKey(
      workspace,
      'moves',
      _localPsdkCatalogBeforeSync,
    );
    final projectFile = File(workspace.projectManifestPath);
    final beforeProjectJson = await projectFile.readAsString();

    final result = await useCase.execute(
      workspace,
      psdkProjectRootPath: '/tmp/fake-psdk-project',
    );
    final catalog = await readRepository.readCatalogByKey(workspace, 'moves');

    expect(result.dryRun, isFalse);
    expect(result.createdIds, <String>['tackle']);
    expect(result.updatedIds, <String>['thunder_wave']);
    expect(result.preservedLocalOnlyIds, <String>['custom_local_move']);
    expect(catalog.meta.sourcePriority, contains('pokemon_sdk_studio'));
    expect(
      catalog.entries.map((entry) => entry['id']),
      <String>['custom_local_move', 'tackle', 'thunder_wave'],
    );

    final thunderWave = catalog.entries.firstWhere(
      (entry) => entry['dbSymbol'] == 'thunder_wave',
    );
    final canonicalThunderWave = PokemonMove.fromJson(thunderWave);
    expect(canonicalThunderWave.source, 'pokemon_sdk_studio');
    expect(canonicalThunderWave.battleEngineMethod, 's_status');
    expect(canonicalThunderWave.accuracy,
        const PokemonMoveAccuracy.percent(value: 90));
    expect(
      (thunderWave['names'] as Map<String, dynamic>)['fr'],
      'Cage-Eclair',
    );
    expect(thunderWave['editorNote'], 'Keep local move note');
    expect(thunderWave.containsKey('power'), isFalse);
    expect(await projectFile.readAsString(), beforeProjectJson);
  });

  test('sync creates the moves catalog when the local file is missing',
      () async {
    final catalogFile = File(
      workspace.resolveProjectRelativePath('data/pokemon/catalogs/moves.json'),
    );
    if (catalogFile.existsSync()) {
      await catalogFile.delete();
    }

    final result = await useCase.execute(
      workspace,
      psdkProjectRootPath: '/tmp/fake-psdk-project',
    );

    expect(result.createdIds, <String>['tackle', 'thunder_wave']);
    expect(catalogFile.existsSync(), isTrue);
    final catalog = await readRepository.readCatalogByKey(workspace, 'moves');
    expect(catalog.entries, hasLength(2));
  });

  test('sync honors a custom pokemon data root for the moves catalog path',
      () async {
    await _configureCustomPokemonDataRoot(
      projectRoot: tempProjectRoot,
      dataRoot: 'custom/pokemon',
      movesCatalogRelativePath: 'catalogs/project-moves.json',
    );
    final defaultCatalogFile = File(
      workspace.resolveProjectRelativePath('data/pokemon/catalogs/moves.json'),
    );
    if (defaultCatalogFile.existsSync()) {
      await defaultCatalogFile.delete();
    }

    final result = await useCase.execute(
      workspace,
      psdkProjectRootPath: '/tmp/fake-psdk-project',
    );

    final customCatalogFile = File(
      workspace.resolveProjectRelativePath(
        'custom/pokemon/catalogs/project-moves.json',
      ),
    );
    expect(result.createdIds, <String>['tackle', 'thunder_wave']);
    expect(defaultCatalogFile.existsSync(), isFalse);
    expect(customCatalogFile.existsSync(), isTrue);
  });

  test('fails clearly when the PSDK project exposes no moves', () async {
    externalRepository.payload = PokemonSdkStudioProjectPayload(
      moves: const <Map<String, dynamic>>[],
      abilities: const <Map<String, dynamic>>[],
      items: const <Map<String, dynamic>>[],
      types: const <Map<String, dynamic>>[],
      pokemon: const <Map<String, dynamic>>[],
    );

    await expectLater(
      () => useCase.execute(
        workspace,
        psdkProjectRootPath: '/tmp/empty-psdk-project',
      ),
      throwsA(
        isA<Exception>().having(
          (error) => error.toString(),
          'message',
          contains('moves catalog cannot be empty'),
        ),
      ),
    );
  });
}

class _FakePokemonSdkExternalSourceRepository
    implements PokemonExternalSourceRepository {
  _FakePokemonSdkExternalSourceRepository({
    required this.payload,
  });

  PokemonSdkStudioProjectPayload payload;
  final List<String> loadedProjectRoots = <String>[];

  @override
  Future<PokemonSdkStudioProjectPayload> fetchPokemonSdkStudioProjectPayload(
    String projectRootPath,
  ) async {
    loadedProjectRoots.add(projectRootPath);
    return payload;
  }

  @override
  Future<Map<String, dynamic>> fetchShowdownPokedexSnapshot() {
    throw UnimplementedError();
  }

  @override
  Future<Map<String, dynamic>> fetchShowdownSpeciesPayload(String speciesId) {
    throw UnimplementedError();
  }

  @override
  Future<Map<String, dynamic>> fetchShowdownMovesSnapshot() {
    throw UnimplementedError();
  }

  @override
  Future<Map<String, dynamic>> fetchPokeApiItemsResourceList({
    required int limit,
    required int offset,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Map<String, dynamic>> fetchPokeApiItemPayload(String itemIdOrName) {
    throw UnimplementedError();
  }

  @override
  Future<Map<String, dynamic>> fetchPokeApiPokemonPayload(String speciesId) {
    throw UnimplementedError();
  }

  @override
  Future<Map<String, dynamic>> fetchPokeApiPokemonSpeciesPayload(
    String speciesId,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<Map<String, dynamic>> fetchPokeApiEvolutionChainPayload(
    String speciesId,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<PokemonExternalBinaryAsset> fetchBinaryAsset(String sourceUrl) {
    throw UnimplementedError();
  }
}

Map<String, dynamic> _psdkMove({
  required String dbSymbol,
  required String name,
  String type = 'normal',
  String category = 'physical',
  int power = 40,
  int accuracy = 100,
  String battleEngineMethod = 's_basic',
}) {
  return <String, dynamic>{
    'dbSymbol': dbSymbol,
    'name': name,
    'type': type,
    'category': category,
    'power': power,
    'accuracy': accuracy,
    'pp': 35,
    'battleEngineMethod': battleEngineMethod,
    'battleEngineAimedTarget': 'adjacent_foe',
  };
}

final PokemonCatalogFile _localPsdkCatalogBeforeSync = PokemonCatalogFile(
  schemaVersion: 1,
  kind: 'pokemon_catalog',
  catalog: 'moves',
  meta: const PokemonDataMeta(
    description: 'Local PSDK moves catalog before sync.',
  ),
  entries: <Map<String, dynamic>>[
    const <String, dynamic>{
      'id': 'custom_local_move',
      'name': 'Custom Local Move',
      'source': 'project_custom',
    },
    const PokemonMove(
      id: 'thunder_wave',
      name: 'Old Thunder Wave',
      names: <String, String>{
        'fr': 'Cage-Eclair',
      },
      source: 'pokemon_sdk_studio',
      dbSymbol: 'thunder_wave',
      type: 'electric',
      category: PokemonMoveCategory.status,
      battleEngineAimedTarget: PokemonMoveAimedTarget.adjacentFoe,
      accuracy: PokemonMoveAccuracy.percent(value: 100),
      pp: 20,
      battleEngineMethod: 's_status',
      sourceRefs: PokemonMoveSourceRefs(
        psdkDbSymbol: 'thunder_wave',
        psdkBattleEngineMethod: 's_status',
      ),
    ).toJson()
      ..['editorNote'] = 'Keep local move note'
      ..['power'] = 0,
  ],
);

Future<void> _configureCustomPokemonDataRoot({
  required Directory projectRoot,
  required String dataRoot,
  required String movesCatalogRelativePath,
}) async {
  final manifestFile = File(p.join(projectRoot.path, 'project.json'));
  final manifest = ProjectManifest.fromJson(
    jsonDecode(await manifestFile.readAsString()) as Map<String, dynamic>,
  );
  await manifestFile.writeAsString(
    const JsonEncoder.withIndent('  ').convert(
      manifest
          .copyWith(
            pokemon: manifest.pokemon.copyWith(
              dataRoot: dataRoot,
            ),
          )
          .toJson(),
    ),
  );

  final bootstrapManifest = File(
    p.join(projectRoot.path, dataRoot, 'pokemon_data_manifest.json'),
  );
  await bootstrapManifest.create(recursive: true);
  await bootstrapManifest.writeAsString(
    const JsonEncoder.withIndent('  ').convert(
      <String, Object?>{
        'schemaVersion': 1,
        'kind': 'pokemon_data_manifest',
        'meta': <String, Object?>{
          'description': 'Custom bootstrap manifest.',
        },
        'catalogFiles': <String, Object?>{
          'moves': movesCatalogRelativePath,
        },
        'futureDataFolders': <String, Object?>{},
      },
    ),
  );
}
