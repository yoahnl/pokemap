import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/models/pokemon_project_data_models.dart';
import 'package:map_editor/src/application/ports/pokemon_external_source_repository.dart';
import 'package:map_editor/src/application/use_cases/initialize_pokemon_project_storage_use_case.dart';
import 'package:map_editor/src/application/use_cases/project_management_use_cases.dart';
import 'package:map_editor/src/application/use_cases/sync_pokemon_moves_catalog_use_case.dart';
import 'package:map_editor/src/infrastructure/filesystem/project_filesystem.dart';
import 'package:map_editor/src/infrastructure/repositories/file_repositories.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory tempProjectRoot;
  late ProjectFileSystem workspace;
  late FilePokemonReadRepository readRepository;
  late FilePokemonWriteRepository writeRepository;
  late _FakePokemonExternalSourceRepository externalRepository;
  late SyncExternalPokemonMovesCatalogUseCase syncUseCase;
  late LoadPokemonMovesCatalogUseCase loadUseCase;

  setUp(() async {
    tempProjectRoot =
        await Directory.systemTemp.createTemp('moves_catalog_sync_');
    workspace = ProjectFileSystem(tempProjectRoot.path);
    readRepository = const FilePokemonReadRepository();
    writeRepository = const FilePokemonWriteRepository();
    externalRepository = _FakePokemonExternalSourceRepository();
    syncUseCase = SyncExternalPokemonMovesCatalogUseCase(
      externalSourceRepository: externalRepository,
      readRepository: readRepository,
      writeRepository: writeRepository,
    );
    loadUseCase = LoadPokemonMovesCatalogUseCase(
      readRepository: readRepository,
    );

    final createProjectUseCase = CreateProjectUseCase(
      FileProjectRepository(),
      const FileProjectWorkspaceFactory(),
    );
    await createProjectUseCase.execute(
      'Moves Catalog Sync Project',
      tempProjectRoot.path,
    );
    await const InitializePokemonProjectStorageUseCase().execute(workspace);
  });

  tearDown(() async {
    if (await tempProjectRoot.exists()) {
      await tempProjectRoot.delete(recursive: true);
    }
  });

  Future<PokemonMovesCatalogView> loadViewFromCatalog(
    PokemonCatalogFile catalog,
  ) async {
    await writeRepository.saveCatalogByKey(
      workspace,
      'moves',
      catalog,
    );
    return loadUseCase.execute(workspace);
  }

  test('dry-run previews the sync without writing the local catalog', () async {
    await writeRepository.saveCatalogByKey(
      workspace,
      'moves',
      _localMovesCatalogBeforeSync,
    );

    final catalogFile = File(
      workspace.resolveProjectRelativePath('data/pokemon/catalogs/moves.json'),
    );
    final beforeCatalogJson = await catalogFile.readAsString();
    final projectFile = File(workspace.projectManifestPath);
    final beforeProjectJson = await projectFile.readAsString();

    final result = await syncUseCase.execute(workspace, dryRun: true);

    expect(result.dryRun, isTrue);
    expect(result.createdIds, containsAll(<String>['swift', 'thunderbolt']));
    expect(result.updatedIds, contains('vine_whip'));
    expect(result.preservedLocalOnlyIds, contains('custom_move'));
    expect(await catalogFile.readAsString(), beforeCatalogJson);
    expect(await projectFile.readAsString(), beforeProjectJson);
  });

  test('sync creates the moves catalog when it is missing', () async {
    final catalogPath = workspace.resolveProjectRelativePath(
      'data/pokemon/catalogs/moves.json',
    );
    final catalogFile = File(catalogPath);
    if (catalogFile.existsSync()) {
      await catalogFile.delete();
    }

    final dryRunResult = await syncUseCase.execute(workspace, dryRun: true);
    expect(dryRunResult.createdIds, isNotEmpty);
    expect(catalogFile.existsSync(), isFalse);

    final syncResult = await syncUseCase.execute(workspace);
    expect(syncResult.createdIds, isNotEmpty);
    expect(catalogFile.existsSync(), isTrue);
  });

  test(
      'sync merges Showdown moves into the local catalog and preserves local-only metadata',
      () async {
    await writeRepository.saveCatalogByKey(
      workspace,
      'moves',
      _localMovesCatalogBeforeSync,
    );

    final projectFile = File(workspace.projectManifestPath);
    final beforeProjectJson = await projectFile.readAsString();

    final result = await syncUseCase.execute(workspace);
    final syncedCatalog = await readRepository.readCatalogByKey(
      workspace,
      'moves',
    );
    final loadedView = await loadUseCase.execute(workspace);

    expect(result.dryRun, isFalse);
    expect(result.createdIds, containsAll(<String>['swift', 'thunderbolt']));
    expect(result.updatedIds, contains('vine_whip'));
    expect(result.preservedLocalOnlyIds, contains('custom_move'));
    expect(
      syncedCatalog.entries.map((entry) => entry['id']),
      containsAll(<String>['custom_move', 'swift', 'thunderbolt', 'vine_whip']),
    );

    final vineWhip = syncedCatalog.entries.firstWhere(
      (entry) => entry['id'] == 'vine_whip',
    );
    final canonicalVineWhip = PokemonMove.fromJson(vineWhip);
    expect(canonicalVineWhip.name, 'Vine Whip');
    expect(canonicalVineWhip.type, 'grass');
    expect(canonicalVineWhip.basePower, 45);
    expect(canonicalVineWhip.generation, 1);
    expect(canonicalVineWhip.source, 'showdown');
    expect(vineWhip.containsKey('power'), isFalse);
    expect(vineWhip.containsKey('accuracyText'), isFalse);
    expect(vineWhip.containsKey('shortDesc'), isFalse);
    expect(
      ((vineWhip['names'] as Map<String, dynamic>)['fr'] as String),
      'Fouet Lianes',
    );
    expect(vineWhip['editorNote'], 'Keep this local-only field after sync.');

    final swift = syncedCatalog.entries.firstWhere(
      (entry) => entry['id'] == 'swift',
    );
    final canonicalSwift = PokemonMove.fromJson(swift);
    expect(
      canonicalSwift.accuracy,
      const PokemonMoveAccuracy.alwaysHits(),
    );

    expect(loadedView.isAvailable, isTrue);
    final thunderboltView = loadedView.entries.firstWhere(
      (entry) => entry.id == 'thunderbolt',
    );
    expect(thunderboltView.power, 90);
    expect(thunderboltView.accuracyLabel, '100');
    expect(thunderboltView.shortDesc, 'May paralyze the target.');

    final swiftView = loadedView.entries.firstWhere(
      (entry) => entry.id == 'swift',
    );
    expect(swiftView.accuracyLabel, 'always');
    expect(await projectFile.readAsString(), beforeProjectJson);
  });

  test(
      'sync honors a custom pokemon data root for the moves catalog path',
      () async {
    await _configureCustomPokemonDataRoot(
      projectRoot: tempProjectRoot,
      dataRoot: 'custom/pokemon',
      movesCatalogRelativePath: 'catalogs/project-moves.json',
    );

    final defaultCatalogPath = File(
      workspace.resolveProjectRelativePath('data/pokemon/catalogs/moves.json'),
    );
    if (defaultCatalogPath.existsSync()) {
      await defaultCatalogPath.delete();
    }

    final previewResult = await syncUseCase.execute(workspace, dryRun: true);
    expect(previewResult.createdIds, isNotEmpty);
    expect(
      File(
        workspace.resolveProjectRelativePath(
          'custom/pokemon/catalogs/project-moves.json',
        ),
      ).existsSync(),
      isFalse,
    );

    final syncResult = await syncUseCase.execute(workspace);
    final customCatalogPath = File(
      workspace.resolveProjectRelativePath(
        'custom/pokemon/catalogs/project-moves.json',
      ),
    );
    final syncedCatalog = await readRepository.readCatalogByKey(
      workspace,
      'moves',
    );

    expect(syncResult.createdIds, isNotEmpty);
    expect(customCatalogPath.existsSync(), isTrue);
    expect(defaultCatalogPath.existsSync(), isFalse);
    expect(
      syncedCatalog.entries.map((entry) => entry['id']),
      contains('thunderbolt'),
    );
  });

  test(
      'load use case does not silently downgrade an invalid canonical move to legacy projection',
      () async {
    final loadedView = await loadViewFromCatalog(
      _catalogWithEntries(
        <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'broken_move',
            'name': 'Broken Move',
            'names': <String, String>{'en': 'Broken Move'},
            'source': 'showdown',
            'type': 'normal',
            'category': 'physical',
            'target': 'normal',
            'basePower': 40,
            'accuracy': <String, dynamic>{'kind': 'percent', 'value': 0},
            'pp': 10,
            'priority': 0,
            'critRatio': 1,
            'flags': <String>[],
            'effects': <Map<String, dynamic>>[],
            'shortDescription': 'Broken canonical payload.',
            'description': 'Broken canonical payload.',
            'engineSupportLevel': 'structured_supported',
            'unsupportedReasons': <String>[],
            'sourceRefs': <String, dynamic>{
              'showdownMoveId': 'brokenmove',
              'showdownHooksPresent': <String>[],
            },
          },
        ],
        description: 'Broken canonical move catalog.',
      ),
    );

    expect(loadedView.isAvailable, isTrue);
    expect(loadedView.entries, isEmpty);
    expect(loadedView.diagnostics, hasLength(1));
    expect(
      loadedView.diagnostics.single.message,
      contains('invalid canonical PokemonMove entry'),
    );
  });

  test('load use case reads a valid canonical move entry correctly', () async {
    final loadedView = await loadViewFromCatalog(
      _catalogWithEntries(
        <Map<String, dynamic>>[
          _canonicalMoveEntry(
            const PokemonMove(
              id: 'thunderbolt',
              name: 'Thunderbolt',
              names: <String, String>{'en': 'Thunderbolt'},
              generation: 1,
              source: 'showdown',
              type: 'electric',
              category: PokemonMoveCategory.special,
              target: PokemonMoveTarget.normal,
              basePower: 90,
              accuracy: PokemonMoveAccuracy.percent(value: 100),
              pp: 15,
              priority: 0,
              critRatio: 1,
              effects: <PokemonMoveEffect>[
                PokemonMoveEffect.applyStatus(
                  chance: 10,
                  statusId: 'par',
                ),
              ],
              shortDescription: 'May paralyze the target.',
              description:
                  'A strong electric blast crashes down on the target.',
              engineSupportLevel:
                  PokemonMoveEngineSupportLevel.structuredSupported,
              sourceRefs: PokemonMoveSourceRefs(
                showdownMoveId: 'thunderbolt',
              ),
            ),
          ),
        ],
        description: 'Valid canonical move catalog.',
      ),
    );

    expect(loadedView.isAvailable, isTrue);
    expect(loadedView.entries, hasLength(1));
    expect(loadedView.entries.single.id, 'thunderbolt');
    expect(loadedView.entries.single.power, 90);
    expect(loadedView.entries.single.accuracyLabel, '100');
    expect(loadedView.entries.single.shortDesc, 'May paralyze the target.');
  });

  test(
      'load use case treats basePower plus scalar accuracy as invalid canonical instead of legacy',
      () async {
    final loadedView = await loadViewFromCatalog(
      _catalogWithEntries(
        <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'broken_base_power_move',
            'name': 'Broken Base Power Move',
            'names': <String, String>{'en': 'Broken Base Power Move'},
            'type': 'normal',
            'category': 'physical',
            'target': 'normal',
            'basePower': 40,
            'accuracy': 95,
            'pp': 15,
            'priority': 0,
          },
        ],
        description: 'Broken canonical candidate by basePower.',
      ),
    );

    expect(loadedView.isAvailable, isTrue);
    expect(loadedView.entries, isEmpty);
    expect(loadedView.diagnostics, hasLength(1));
    expect(
      loadedView.diagnostics.single.message,
      contains('invalid canonical PokemonMove entry'),
    );
  });

  test(
      'load use case treats other canonical markers as invalid canonical instead of legacy',
      () async {
    final loadedView = await loadViewFromCatalog(
      _catalogWithEntries(
        <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'broken_effects_move',
            'name': 'Broken Effects Move',
            'names': <String, String>{'en': 'Broken Effects Move'},
            'type': 'psychic',
            'category': 'status',
            'accuracy': <String, dynamic>{'kind': 'always_hits'},
            'effects': <Map<String, dynamic>>[
              <String, dynamic>{
                'kind': 'set_weather',
              },
            ],
          },
        ],
        description: 'Broken canonical candidate by effects.',
      ),
    );

    expect(loadedView.isAvailable, isTrue);
    expect(loadedView.entries, isEmpty);
    expect(loadedView.diagnostics, hasLength(1));
    expect(
      loadedView.diagnostics.single.message,
      contains('invalid canonical PokemonMove entry'),
    );
  });

  test('load use case still accepts a true legacy move entry', () async {
    final loadedView = await loadViewFromCatalog(
      _catalogWithEntries(
        const <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'legacy_move',
            'name': 'Legacy Move',
            'names': <String, String>{'en': 'Legacy Move'},
            'type': 'normal',
            'category': 'physical',
            'power': 50,
            'accuracy': 95,
            'pp': 20,
            'priority': 0,
            'target': 'normal',
            'shortDesc': 'A true legacy move entry.',
            'generation': 3,
          },
        ],
        description: 'Legacy move catalog.',
      ),
    );

    expect(loadedView.isAvailable, isTrue);
    expect(loadedView.entries, hasLength(1));
    expect(loadedView.entries.single.id, 'legacy_move');
    expect(loadedView.entries.single.power, 50);
    expect(loadedView.entries.single.accuracyLabel, '95');
    expect(loadedView.entries.single.shortDesc, 'A true legacy move entry.');
  });

  test('load use case accepts a minimal local move entry shape',
      () async {
    final loadedView = await loadViewFromCatalog(
      _catalogWithEntries(
        const <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'unknown_shape_move',
            'name': 'Unknown Shape Move',
            'names': <String, String>{'en': 'Unknown Shape Move'},
            'type': 'normal',
            'category': 'status',
            'target': 'normal',
          },
        ],
        description: 'Unknown move catalog shape.',
      ),
    );

    expect(loadedView.isAvailable, isTrue);
    expect(loadedView.diagnostics, isEmpty);
    expect(loadedView.entries, hasLength(1));
    expect(loadedView.entries.single.id, 'unknown_shape_move');
    expect(loadedView.entries.single.name, 'Unknown Shape Move');
    expect(loadedView.entries.single.category, 'status');
  });
}

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

PokemonCatalogFile _catalogWithEntries(
  List<Map<String, dynamic>> entries, {
  required String description,
}) {
  return PokemonCatalogFile(
    schemaVersion: 1,
    kind: 'pokemon_catalog',
    catalog: 'moves',
    meta: PokemonDataMeta(
      description: description,
    ),
    entries: entries,
  );
}

Map<String, dynamic> _canonicalMoveEntry(PokemonMove move) => move.toJson();

class _FakePokemonExternalSourceRepository
    implements PokemonExternalSourceRepository {
  @override
  Future<Map<String, dynamic>> fetchShowdownPokedexSnapshot() {
    throw UnimplementedError();
  }

  @override
  Future<Map<String, dynamic>> fetchShowdownMovesSnapshot() async {
    return <String, dynamic>{
      'vinewhip': <String, dynamic>{
        'name': 'Vine Whip',
        'type': 'Grass',
        'category': 'Physical',
        'basePower': 45,
        'accuracy': 100,
        'pp': 25,
        'priority': 0,
        'target': 'normal',
        'shortDesc': 'Strikes the target with slender, whiplike vines.',
        'desc': 'The target is struck with slender, whiplike vines.',
        'gen': 1,
      },
      'thunderbolt': <String, dynamic>{
        'name': 'Thunderbolt',
        'type': 'Electric',
        'category': 'Special',
        'basePower': 90,
        'accuracy': 100,
        'pp': 15,
        'priority': 0,
        'target': 'normal',
        'secondary': <String, dynamic>{
          'chance': 10,
          'status': 'par',
        },
        'shortDesc': 'May paralyze the target.',
        'desc': 'A strong electric blast crashes down on the target.',
        'gen': 1,
      },
      'swift': <String, dynamic>{
        'name': 'Swift',
        'type': 'Normal',
        'category': 'Special',
        'basePower': 60,
        'accuracy': true,
        'pp': 20,
        'priority': 0,
        'target': 'allAdjacentFoes',
        'shortDesc': 'This move does not check accuracy.',
        'desc': 'Star-shaped rays are shot at opposing Pokémon.',
        'gen': 1,
      },
    };
  }

  @override
  Future<Map<String, dynamic>> fetchShowdownSpeciesPayload(String speciesId) {
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

const PokemonCatalogFile _localMovesCatalogBeforeSync = PokemonCatalogFile(
  schemaVersion: 1,
  kind: 'pokemon_catalog',
  catalog: 'moves',
  meta: PokemonDataMeta(
    description: 'Local moves catalog before external sync.',
  ),
  entries: <Map<String, dynamic>>[
    <String, dynamic>{
      'id': 'custom_move',
      'name': 'Custom Move',
      'names': <String, String>{'en': 'Custom Move'},
      'type': 'normal',
      'category': 'status',
      'power': null,
      'accuracy': 100,
      'pp': 5,
      'priority': 0,
      'target': 'self',
      'shortDesc': 'A local-only move that must be preserved.',
      'generation': 9,
    },
    <String, dynamic>{
      'id': 'vine_whip',
      'name': 'Liane',
      'names': <String, String>{
        'en': 'Vine Whip',
        'fr': 'Fouet Lianes',
      },
      'type': 'grass',
      'category': 'physical',
      'power': 40,
      'accuracy': 95,
      'pp': 20,
      'priority': 0,
      'target': 'normal',
      'shortDesc': 'Old local description.',
      'generation': 3,
      'editorNote': 'Keep this local-only field after sync.',
    },
  ],
);
