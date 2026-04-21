import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/errors/application_errors.dart';
import 'package:map_editor/src/application/models/pokemon_project_data_models.dart';
import 'package:map_editor/src/application/ports/pokemon_external_source_repository.dart';
import 'package:map_editor/src/application/use_cases/initialize_pokemon_project_storage_use_case.dart';
import 'package:map_editor/src/application/use_cases/load_pokemon_items_catalog_use_case.dart';
import 'package:map_editor/src/application/use_cases/project_management_use_cases.dart';
import 'package:map_editor/src/application/use_cases/sync_pokemon_items_catalog_use_case.dart';
import 'package:map_editor/src/infrastructure/filesystem/project_filesystem.dart';
import 'package:map_editor/src/infrastructure/repositories/file_repositories.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory tempProjectRoot;
  late ProjectFileSystem workspace;
  late FilePokemonReadRepository readRepository;
  late FilePokemonWriteRepository writeRepository;
  late _FakePokemonExternalSourceRepository externalRepository;
  late SyncExternalPokemonItemsCatalogUseCase syncUseCase;
  late LoadPokemonItemsCatalogUseCase loadUseCase;

  setUp(() async {
    tempProjectRoot =
        await Directory.systemTemp.createTemp('items_catalog_sync_');
    workspace = ProjectFileSystem(tempProjectRoot.path);
    readRepository = const FilePokemonReadRepository();
    writeRepository = const FilePokemonWriteRepository();
    externalRepository = _FakePokemonExternalSourceRepository();
    syncUseCase = SyncExternalPokemonItemsCatalogUseCase(
      externalSourceRepository: externalRepository,
      readRepository: readRepository,
      writeRepository: writeRepository,
    );
    loadUseCase = LoadPokemonItemsCatalogUseCase(
      readRepository: readRepository,
    );

    await CreateProjectUseCase(
      FileProjectRepository(),
      const FileProjectWorkspaceFactory(),
    ).execute('Items Catalog Sync Project', tempProjectRoot.path);
    await const InitializePokemonProjectStorageUseCase().execute(workspace);
  });

  tearDown(() async {
    if (await tempProjectRoot.exists()) {
      await tempProjectRoot.delete(recursive: true);
    }
  });

  test('dry-run previews the item sync without writing the catalog or sprites',
      () async {
    await writeRepository.saveCatalogByKey(
      workspace,
      'items',
      _localItemsCatalogBeforeSync,
    );

    externalRepository.itemListPagesByOffset[0] = _buildItemsListPage(
      <Map<String, dynamic>>[
        <String, dynamic>{
          'name': 'poke-ball',
          'url': 'https://pokeapi.co/api/v2/item/4/',
        },
        <String, dynamic>{
          'name': 'potion',
          'url': 'https://pokeapi.co/api/v2/item/17/',
        },
      ],
      count: 2,
    );
    externalRepository.itemPayloadsByName.addAll(
      <String, Map<String, dynamic>>{
        'poke-ball': _pokeBallPayload(),
        'potion': _potionPayload(),
      },
    );
    externalRepository.binaryAssetsByUrl[_pokeBallSpriteUrl] =
        _pngBinaryAsset(_pokeBallSpriteUrl);

    final catalogFile = File(
      workspace.resolveProjectRelativePath('data/pokemon/catalogs/items.json'),
    );
    final beforeCatalogJson = await catalogFile.readAsString();
    final projectFile = File(workspace.projectManifestPath);
    final beforeProjectJson = await projectFile.readAsString();

    final result = await syncUseCase.execute(
      workspace,
      dryRun: true,
      downloadSprites: true,
    );

    expect(result.dryRun, isTrue);
    expect(result.createdIds, contains('potion'));
    expect(result.updatedIds, contains('poke-ball'));
    expect(result.preservedLocalOnlyIds, contains('festival-ticket'));
    expect(result.downloadedSpriteIds, isEmpty);
    expect(result.skippedSpriteIds, isEmpty);
    expect(result.failedSpriteIds, isEmpty);
    expect(externalRepository.fetchedBinaryAssets, isEmpty);
    expect(await catalogFile.readAsString(), beforeCatalogJson);
    expect(await projectFile.readAsString(), beforeProjectJson);
    expect(
      File(
        workspace.resolveProjectRelativePath(
          'data/pokemon/assets/items/poke-ball.png',
        ),
      ).existsSync(),
      isFalse,
    );
  });

  test(
      'sync writes the merged items catalog, preserves local-only entries, and keeps local custom fields',
      () async {
    await writeRepository.saveCatalogByKey(
      workspace,
      'items',
      _localItemsCatalogBeforeSync,
    );

    externalRepository.itemListPagesByOffset[0] = _buildItemsListPage(
      <Map<String, dynamic>>[
        <String, dynamic>{
          'name': 'poke-ball',
          'url': 'https://pokeapi.co/api/v2/item/4/',
        },
        <String, dynamic>{
          'name': 'potion',
          'url': 'https://pokeapi.co/api/v2/item/17/',
        },
      ],
      count: 2,
    );
    externalRepository.itemPayloadsByName.addAll(
      <String, Map<String, dynamic>>{
        'poke-ball': _pokeBallPayload(),
        'potion': _potionPayload(),
      },
    );

    final projectFile = File(workspace.projectManifestPath);
    final beforeProjectJson = await projectFile.readAsString();

    final result = await syncUseCase.execute(workspace);
    final syncedCatalog = await readRepository.readCatalogByKey(
      workspace,
      'items',
    );

    expect(result.dryRun, isFalse);
    expect(result.createdIds, contains('potion'));
    expect(result.updatedIds, contains('poke-ball'));
    expect(result.unchangedIds, isEmpty);
    expect(result.preservedLocalOnlyIds, contains('festival-ticket'));
    expect(result.resultingEntryCount, 3);
    expect(await projectFile.readAsString(), beforeProjectJson);

    final pokeBall = syncedCatalog.entries.firstWhere(
      (entry) => entry['id'] == 'poke-ball',
    );
    expect(pokeBall['name'], 'Poké Ball');
    expect((pokeBall['names'] as Map<String, dynamic>)['en'], 'Poké Ball');
    expect(pokeBall['categoryId'], 'standard-balls');
    expect(pokeBall['pocketId'], 'poke-balls');
    expect(pokeBall['cost'], 200);
    expect(pokeBall['flingPower'], 10);
    expect(pokeBall['flingEffectId'], 'item-catch');
    expect(pokeBall['shortEffectText'], 'Catches wild Pokémon.');
    expect(pokeBall['effectText'], 'Used to catch wild Pokémon.');
    expect(pokeBall['flavorText'], 'A device for catching wild Pokémon.');
    expect(pokeBall['spriteUrl'], _pokeBallSpriteUrl);
    expect(pokeBall['source'], 'pokeapi');
    expect(
      (pokeBall['sourceRefs'] as Map<String, dynamic>)['pokeApiItemId'],
      4,
    );
    expect(
      (pokeBall['sourceRefs'] as Map<String, dynamic>)['pokeApiName'],
      'poke-ball',
    );
    expect(pokeBall['editorNote'], 'Keep this local custom field after sync.');

    final localOnly = syncedCatalog.entries.firstWhere(
      (entry) => entry['id'] == 'festival-ticket',
    );
    expect(localOnly['name'], 'Festival Ticket');
    expect(localOnly['source'], 'local');
  });

  test('sync downloads sprites locally and writes localSpritePath', () async {
    externalRepository.itemListPagesByOffset[0] = _buildItemsListPage(
      <Map<String, dynamic>>[
        <String, dynamic>{
          'name': 'poke-ball',
          'url': 'https://pokeapi.co/api/v2/item/4/',
        },
      ],
      count: 1,
    );
    externalRepository.itemPayloadsByName['poke-ball'] = _pokeBallPayload();
    externalRepository.binaryAssetsByUrl[_pokeBallSpriteUrl] =
        _pngBinaryAsset(_pokeBallSpriteUrl);

    final result = await syncUseCase.execute(
      workspace,
      downloadSprites: true,
    );
    final syncedCatalog = await readRepository.readCatalogByKey(
      workspace,
      'items',
    );
    final pokeBall = syncedCatalog.entries.single;

    expect(result.downloadedSpriteIds, contains('poke-ball'));
    expect(result.skippedSpriteIds, isEmpty);
    expect(result.failedSpriteIds, isEmpty);
    expect(
      pokeBall['localSpritePath'],
      'data/pokemon/assets/items/poke-ball.png',
    );
    expect(
      File(
        workspace.resolveProjectRelativePath(
          'data/pokemon/assets/items/poke-ball.png',
        ),
      ).existsSync(),
      isTrue,
    );
  });

  test(
      'sync skips sprite downloads when sprite metadata is missing or a local sprite already exists',
      () async {
    final existingSpritePath = workspace.resolveProjectRelativePath(
      'data/pokemon/assets/items/poke-ball.png',
    );
    await File(existingSpritePath).create(recursive: true);
    await File(existingSpritePath).writeAsBytes(<int>[9, 8, 7, 6]);

    externalRepository.itemListPagesByOffset[0] = _buildItemsListPage(
      <Map<String, dynamic>>[
        <String, dynamic>{
          'name': 'poke-ball',
          'url': 'https://pokeapi.co/api/v2/item/4/',
        },
        <String, dynamic>{
          'name': 'mystery-item',
          'url': 'https://pokeapi.co/api/v2/item/999/',
        },
      ],
      count: 2,
    );
    externalRepository.itemPayloadsByName.addAll(
      <String, Map<String, dynamic>>{
        'poke-ball': _pokeBallPayload(),
        'mystery-item': _mysteryItemPayload(),
      },
    );
    externalRepository.binaryAssetsByUrl[_pokeBallSpriteUrl] =
        _pngBinaryAsset(_pokeBallSpriteUrl);

    final result = await syncUseCase.execute(
      workspace,
      downloadSprites: true,
    );
    final syncedCatalog = await readRepository.readCatalogByKey(
      workspace,
      'items',
    );
    final pokeBall = syncedCatalog.entries.firstWhere(
      (entry) => entry['id'] == 'poke-ball',
    );
    final mysteryItem = syncedCatalog.entries.firstWhere(
      (entry) => entry['id'] == 'mystery-item',
    );

    expect(result.downloadedSpriteIds, isEmpty);
    expect(result.skippedSpriteIds, containsAll(<String>[
      'poke-ball',
      'mystery-item',
    ]));
    expect(result.failedSpriteIds, isEmpty);
    expect(externalRepository.fetchedBinaryAssets, isEmpty);
    expect(
      pokeBall['localSpritePath'],
      'data/pokemon/assets/items/poke-ball.png',
    );
    expect(mysteryItem['localSpritePath'], isNull);
    expect(await File(existingSpritePath).readAsBytes(), <int>[9, 8, 7, 6]);
  });

  test(
      'sync records warnings when a sprite download fails without aborting the sync',
      () async {
    externalRepository.itemListPagesByOffset[0] = _buildItemsListPage(
      <Map<String, dynamic>>[
        <String, dynamic>{
          'name': 'poke-ball',
          'url': 'https://pokeapi.co/api/v2/item/4/',
        },
      ],
      count: 1,
    );
    externalRepository.itemPayloadsByName['poke-ball'] = _pokeBallPayload();
    externalRepository.failingBinaryUrls.add(_pokeBallSpriteUrl);

    final result = await syncUseCase.execute(
      workspace,
      downloadSprites: true,
    );
    final syncedCatalog = await readRepository.readCatalogByKey(
      workspace,
      'items',
    );
    final pokeBall = syncedCatalog.entries.single;

    expect(result.downloadedSpriteIds, isEmpty);
    expect(result.failedSpriteIds, contains('poke-ball'));
    expect(result.warnings.join(' '), contains('poke-ball'));
    expect(pokeBall['spriteUrl'], _pokeBallSpriteUrl);
    expect(pokeBall['localSpritePath'], isNull);
    expect(
      File(
        workspace.resolveProjectRelativePath(
          'data/pokemon/assets/items/poke-ball.png',
        ),
      ).existsSync(),
      isFalse,
    );
  });

  test(
      'sync converts PokeAPI item payload fields into the local catalog shape',
      () async {
    externalRepository.itemListPagesByOffset[0] = _buildItemsListPage(
      <Map<String, dynamic>>[
        <String, dynamic>{
          'name': 'master-ball',
          'url': 'https://pokeapi.co/api/v2/item/1/',
        },
      ],
      count: 1,
    );
    externalRepository.itemPayloadsByName['master-ball'] = _masterBallPayload();

    await syncUseCase.execute(workspace);
    final syncedCatalog = await readRepository.readCatalogByKey(
      workspace,
      'items',
    );
    final masterBall = syncedCatalog.entries.single;

    expect(masterBall['id'], 'master-ball');
    expect(masterBall['pokeApiId'], 1);
    expect(masterBall['name'], 'Master Ball');
    expect((masterBall['names'] as Map<String, dynamic>)['en'], 'Master Ball');
    expect(masterBall['categoryId'], 'standard-balls');
    expect(masterBall['pocketId'], 'poke-balls');
    expect(masterBall['cost'], isNull);
    expect(masterBall['flingPower'], isNull);
    expect(masterBall['flingEffectId'], isNull);
    expect(masterBall['shortEffectText'], 'Catches wild Pokémon without fail.');
    expect(masterBall['effectText'], 'The best Ball with the ultimate performance.');
    expect(masterBall['flavorText'], 'The best Ball with the ultimate level of performance.');
    expect(masterBall['spriteUrl'], _masterBallSpriteUrl);
    expect(masterBall['source'], 'pokeapi');
    expect(
      (masterBall['sourceRefs'] as Map<String, dynamic>)['pokeApiName'],
      'master-ball',
    );
  });

  test(
      'sync tolerates malformed payloads and duplicate external resources with warnings',
      () async {
    externalRepository.itemListPagesByOffset[0] = _buildItemsListPage(
      <Map<String, dynamic>>[
        <String, dynamic>{
          'name': 'poke-ball',
          'url': 'https://pokeapi.co/api/v2/item/4/',
        },
        <String, dynamic>{
          'name': 'poke-ball',
          'url': 'https://pokeapi.co/api/v2/item/4/',
        },
        <String, dynamic>{
          'name': 'broken-item',
          'url': 'https://pokeapi.co/api/v2/item/404/',
        },
      ],
      count: 3,
    );
    externalRepository.itemPayloadsByName.addAll(
      <String, Map<String, dynamic>>{
        'poke-ball': _pokeBallPayload(),
        'broken-item': <String, dynamic>{
          'id': 404,
          'name': 'broken-item',
          'cost': 'expensive',
        },
      },
    );

    final result = await syncUseCase.execute(workspace);
    final syncedCatalog = await readRepository.readCatalogByKey(
      workspace,
      'items',
    );

    expect(result.externalEntryCount, 2);
    expect(result.createdIds, contains('poke-ball'));
    expect(result.createdIds, isNot(contains('broken-item')));
    expect(result.warnings.join(' '), contains('duplicate'));
    expect(result.warnings.join(' '), contains('broken-item'));
    expect(
      syncedCatalog.entries.map((entry) => entry['id']).toList(),
      contains('poke-ball'),
    );
    expect(
      syncedCatalog.entries.where((entry) => entry['id'] == 'broken-item'),
      isEmpty,
    );
  });

  test(
      'sync honors a custom pokemon data root for both the items catalog and local sprite assets',
      () async {
    await _configureCustomPokemonDataRoot(
      projectRoot: tempProjectRoot,
      dataRoot: 'custom/pokemon',
      itemsCatalogRelativePath: 'catalogs/project-items.json',
    );

    externalRepository.itemListPagesByOffset[0] = _buildItemsListPage(
      <Map<String, dynamic>>[
        <String, dynamic>{
          'name': 'poke-ball',
          'url': 'https://pokeapi.co/api/v2/item/4/',
        },
      ],
      count: 1,
    );
    externalRepository.itemPayloadsByName['poke-ball'] = _pokeBallPayload();
    externalRepository.binaryAssetsByUrl[_pokeBallSpriteUrl] =
        _pngBinaryAsset(_pokeBallSpriteUrl);

    await syncUseCase.execute(
      workspace,
      downloadSprites: true,
    );

    final customCatalog = File(
      workspace.resolveProjectRelativePath(
        'custom/pokemon/catalogs/project-items.json',
      ),
    );
    final syncedCatalog = await readRepository.readCatalogByKey(
      workspace,
      'items',
    );
    final pokeBall = syncedCatalog.entries.single;

    expect(customCatalog.existsSync(), isTrue);
    expect(
      pokeBall['localSpritePath'],
      'custom/pokemon/assets/items/poke-ball.png',
    );
    expect(
      File(
        workspace.resolveProjectRelativePath(
          'custom/pokemon/assets/items/poke-ball.png',
        ),
      ).existsSync(),
      isTrue,
    );
  });

  test('load use case reads the synced catalog after a real sync', () async {
    externalRepository.itemListPagesByOffset[0] = _buildItemsListPage(
      <Map<String, dynamic>>[
        <String, dynamic>{
          'name': 'poke-ball',
          'url': 'https://pokeapi.co/api/v2/item/4/',
        },
      ],
      count: 1,
    );
    externalRepository.itemPayloadsByName['poke-ball'] = _pokeBallPayload();

    await syncUseCase.execute(workspace);
    final loadedView = await loadUseCase.execute(workspace);

    expect(loadedView.loadState, PokemonItemsCatalogLoadState.ready);
    expect(loadedView.entries, hasLength(1));
    expect(loadedView.entries.single.id, 'poke-ball');
    expect(loadedView.entries.single.name, 'Poké Ball');
    expect(loadedView.entries.single.shortEffectText, 'Catches wild Pokémon.');
  });
}

Future<void> _configureCustomPokemonDataRoot({
  required Directory projectRoot,
  required String dataRoot,
  required String itemsCatalogRelativePath,
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
          'items': itemsCatalogRelativePath,
        },
        'futureDataFolders': <String, Object?>{},
      },
    ),
  );
}

Map<String, dynamic> _buildItemsListPage(
  List<Map<String, dynamic>> results, {
  required int count,
}) {
  return <String, dynamic>{
    'count': count,
    'next': null,
    'previous': null,
    'results': results,
  };
}

PokemonExternalBinaryAsset _pngBinaryAsset(String sourceUrl) {
  return PokemonExternalBinaryAsset(
    sourceUrl: sourceUrl,
    bytes: Uint8List.fromList(_tinyTransparentPng),
    contentType: 'image/png',
  );
}

Map<String, dynamic> _pokeBallPayload() {
  return <String, dynamic>{
    'id': 4,
    'name': 'poke-ball',
    'names': <Map<String, dynamic>>[
      <String, dynamic>{
        'language': <String, dynamic>{'name': 'en'},
        'name': 'Poké Ball',
      },
      <String, dynamic>{
        'language': <String, dynamic>{'name': 'fr'},
        'name': 'Poké Ball',
      },
    ],
    'category': <String, dynamic>{'name': 'standard-balls'},
    'pocket': <String, dynamic>{'name': 'poke-balls'},
    'cost': 200,
    'fling_power': 10,
    'fling_effect': <String, dynamic>{'name': 'item-catch'},
    'effect_entries': <Map<String, dynamic>>[
      <String, dynamic>{
        'language': <String, dynamic>{'name': 'en'},
        'effect': 'Used to catch wild Pokémon.',
        'short_effect': 'Catches wild Pokémon.',
      },
    ],
    'flavor_text_entries': <Map<String, dynamic>>[
      <String, dynamic>{
        'language': <String, dynamic>{'name': 'en'},
        'text': 'A device for catching wild Pokémon.',
      },
    ],
    'sprites': <String, dynamic>{'default': _pokeBallSpriteUrl},
  };
}

Map<String, dynamic> _potionPayload() {
  return <String, dynamic>{
    'id': 17,
    'name': 'potion',
    'names': <Map<String, dynamic>>[
      <String, dynamic>{
        'language': <String, dynamic>{'name': 'en'},
        'name': 'Potion',
      },
    ],
    'category': <String, dynamic>{'name': 'medicine'},
    'pocket': <String, dynamic>{'name': 'medicine'},
    'cost': 300,
    'effect_entries': <Map<String, dynamic>>[
      <String, dynamic>{
        'language': <String, dynamic>{'name': 'en'},
        'effect': 'Restores 20 HP.',
        'short_effect': 'Restores HP.',
      },
    ],
    'flavor_text_entries': <Map<String, dynamic>>[
      <String, dynamic>{
        'language': <String, dynamic>{'name': 'en'},
        'text': 'A spray-type medicine for wounds.',
      },
    ],
    'sprites': <String, dynamic>{},
  };
}

Map<String, dynamic> _masterBallPayload() {
  return <String, dynamic>{
    'id': 1,
    'name': 'master-ball',
    'names': <Map<String, dynamic>>[
      <String, dynamic>{
        'language': <String, dynamic>{'name': 'en'},
        'name': 'Master Ball',
      },
    ],
    'category': <String, dynamic>{'name': 'standard-balls'},
    'pocket': <String, dynamic>{'name': 'poke-balls'},
    'cost': null,
    'fling_power': null,
    'fling_effect': null,
    'effect_entries': <Map<String, dynamic>>[
      <String, dynamic>{
        'language': <String, dynamic>{'name': 'en'},
        'effect': 'The best Ball with the ultimate performance.',
        'short_effect': 'Catches wild Pokémon without fail.',
      },
    ],
    'flavor_text_entries': <Map<String, dynamic>>[
      <String, dynamic>{
        'language': <String, dynamic>{'name': 'en'},
        'text': 'The best Ball with the ultimate level of performance.',
      },
    ],
    'sprites': <String, dynamic>{'default': _masterBallSpriteUrl},
  };
}

Map<String, dynamic> _mysteryItemPayload() {
  return <String, dynamic>{
    'id': 999,
    'name': 'mystery-item',
    'names': <Map<String, dynamic>>[
      <String, dynamic>{
        'language': <String, dynamic>{'name': 'en'},
        'name': 'Mystery Item',
      },
    ],
    'category': <String, dynamic>{'name': 'unknown'},
    'effect_entries': const <Map<String, dynamic>>[],
    'flavor_text_entries': const <Map<String, dynamic>>[],
  };
}

const String _pokeBallSpriteUrl =
    'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/items/poke-ball.png';
const String _masterBallSpriteUrl =
    'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/items/master-ball.png';

const List<int> _tinyTransparentPng = <int>[
  137,
  80,
  78,
  71,
  13,
  10,
  26,
  10,
  0,
  0,
  0,
  13,
  73,
  72,
  68,
  82,
  0,
  0,
  0,
  1,
  0,
  0,
  0,
  1,
  8,
  6,
  0,
  0,
  0,
  31,
  21,
  196,
  137,
  0,
  0,
  0,
  12,
  73,
  68,
  65,
  84,
  8,
  153,
  99,
  0,
  1,
  0,
  0,
  5,
  0,
  1,
  13,
  10,
  44,
  181,
  0,
  0,
  0,
  0,
  73,
  69,
  78,
  68,
  174,
  66,
  96,
  130,
];

const PokemonCatalogFile _localItemsCatalogBeforeSync = PokemonCatalogFile(
  schemaVersion: 1,
  kind: 'pokemon_catalog',
  catalog: 'items',
  meta: PokemonDataMeta(
    description: 'Local items catalog before external sync.',
  ),
  entries: <Map<String, dynamic>>[
    <String, dynamic>{
      'id': 'festival-ticket',
      'name': 'Festival Ticket',
      'source': 'local',
      'effectText': 'Unlocks a local-only event.',
    },
    <String, dynamic>{
      'id': 'poke-ball',
      'name': 'Pokeball',
      'names': <String, String>{
        'en': 'Pokeball',
        'fr': 'Poké Ball',
      },
      'categoryId': 'old-category',
      'pocketId': 'old-pocket',
      'cost': 100,
      'shortEffectText': 'Old short effect.',
      'effectText': 'Old long effect.',
      'editorNote': 'Keep this local custom field after sync.',
    },
  ],
);

class _FakePokemonExternalSourceRepository
    implements PokemonExternalSourceRepository {
  final Map<int, Map<String, dynamic>> itemListPagesByOffset =
      <int, Map<String, dynamic>>{};
  final Map<String, Map<String, dynamic>> itemPayloadsByName =
      <String, Map<String, dynamic>>{};
  final Map<String, PokemonExternalBinaryAsset> binaryAssetsByUrl =
      <String, PokemonExternalBinaryAsset>{};
  final Set<String> failingBinaryUrls = <String>{};
  final List<String> fetchedItems = <String>[];
  final List<String> fetchedBinaryAssets = <String>[];

  @override
  Future<Map<String, dynamic>> fetchPokeApiItemsResourceList({
    required int limit,
    required int offset,
  }) async {
    final payload = itemListPagesByOffset[offset];
    if (payload == null) {
      return <String, dynamic>{
        'count': 0,
        'next': null,
        'previous': null,
        'results': const <Object?>[],
      };
    }
    return jsonDecode(jsonEncode(payload)) as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> fetchPokeApiItemPayload(String itemIdOrName) async {
    fetchedItems.add(itemIdOrName);
    final payload = itemPayloadsByName[itemIdOrName];
    if (payload == null) {
      throw EditorNotFoundException('Missing fake payload for $itemIdOrName');
    }
    return jsonDecode(jsonEncode(payload)) as Map<String, dynamic>;
  }

  @override
  Future<PokemonExternalBinaryAsset> fetchBinaryAsset(String sourceUrl) async {
    fetchedBinaryAssets.add(sourceUrl);
    if (failingBinaryUrls.contains(sourceUrl)) {
      throw EditorPersistenceException('Binary asset download failed: $sourceUrl');
    }
    final asset = binaryAssetsByUrl[sourceUrl];
    if (asset == null) {
      throw EditorNotFoundException('Missing fake binary asset for $sourceUrl');
    }
    return asset;
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
}
