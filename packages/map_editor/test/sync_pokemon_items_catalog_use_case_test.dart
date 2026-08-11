import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/ports/pokemon_external_source_repository.dart';
import 'package:map_editor/src/application/use_cases/load_pokemon_items_catalog_use_case.dart';
import 'package:map_editor/src/application/use_cases/project_management_use_cases.dart';
import 'package:map_editor/src/application/use_cases/sync_pokemon_items_catalog_use_case.dart';
import 'package:map_editor/src/infrastructure/filesystem/project_filesystem.dart';
import 'package:map_editor/src/infrastructure/repositories/file_repositories.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory root;
  late ProjectFileSystem workspace;
  late _FakeExternalRepository external;
  late SyncExternalPokemonItemsCatalogUseCase sync;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('strict-item-sync-');
    workspace = ProjectFileSystem(root.path);
    external = _FakeExternalRepository();
    sync = SyncExternalPokemonItemsCatalogUseCase(
      externalSourceRepository: external,
      writeRepository: const FilePokemonWriteRepository(),
    );
    await CreateProjectUseCase(
      FileProjectRepository(),
      const FileProjectWorkspaceFactory(),
    ).execute('Strict Item Sync', root.path);
    await _writeCatalog(root, _catalog());
  });

  tearDown(() => root.delete(recursive: true));

  test(
    'writes only the strict canonical schema without inferring effects',
    () async {
      external.addItem('potion', _potionPayload());

      final result = await sync.execute(workspace);
      final raw = await _readRawCatalog(root);
      final catalog = decodeProjectItemCatalog(raw);
      final potion = catalog.entries.singleWhere((item) => item.id == 'potion');

      expect(result.createdIds, ['potion']);
      expect(potion.displayName, 'Potion');
      expect(potion.pocketId, 'medicine');
      expect(potion.buyPrice, 300);
      expect(potion.tags, contains('category:medicine'));
      expect(potion.description, 'A spray-type medicine for wounds.');
      expect(potion.uses, isEmpty);
      expect(potion.capture, isNull);
      expect(raw.keys, unorderedEquals(['schemaVersion', 'entries']));
      expect(jsonEncode(raw), isNot(contains('categoryId')));
      expect(jsonEncode(raw), isNot(contains('effectText')));
      expect(jsonEncode(raw), isNot(contains('spriteUrl')));
    },
  );

  test(
    'preserves authored gameplay capabilities while refreshing metadata',
    () async {
      final local = ProjectItemDefinition(
        id: 'potion',
        displayName: 'Local Potion',
        pocketId: 'medicine',
        uses: const [
          ProjectItemUseDefinition(
            contexts: {ProjectItemUseContext.overworld},
            target: ProjectItemTargetKind.partyMember,
            consumption: ProjectItemConsumptionPolicy.onApplied,
            effect: ProjectItemEffectDefinition.healHp(
              mode: ProjectItemAmountMode.flat,
              amount: 20,
            ),
          ),
        ],
      );
      await _writeCatalog(
        root,
        ProjectItemCatalog(schemaVersion: 1, entries: [local]).normalized(),
      );
      external.addItem('potion', _potionPayload());

      final result = await sync.execute(workspace);
      final catalog = decodeProjectItemCatalog(await _readRawCatalog(root));
      final potion = catalog.entries.single;

      expect(result.updatedIds, ['potion']);
      expect(potion.displayName, 'Potion');
      expect(
        potion.uses.single.effect,
        const ProjectItemEffectDefinition.healHp(
          mode: ProjectItemAmountMode.flat,
          amount: 20,
        ),
      );
    },
  );

  test('rejects a legacy local catalog without rewriting it', () async {
    final file = _catalogFile(root);
    final legacy = jsonEncode({
      'catalog': 'items',
      'entries': [
        {'id': 'potion', 'name': 'Potion', 'categoryId': 'medicine'},
      ],
    });
    await file.writeAsString(legacy);
    external.addItem('potion', _potionPayload());

    await expectLater(
      () => sync.execute(workspace),
      throwsA(isA<FormatException>()),
    );
    expect(await file.readAsString(), legacy);
  });

  test(
    'downloads deterministic local sprites without polluting item JSON',
    () async {
      external.addItem('poke-ball', _pokeBallPayload());
      external.binaryAssets[_spriteUrl] = PokemonExternalBinaryAsset(
        sourceUrl: _spriteUrl,
        bytes: Uint8List.fromList([1, 2, 3, 4]),
        contentType: 'image/png',
      );

      final result = await sync.execute(workspace, downloadSprites: true);
      final sprite = File(
        p.join(
          root.path,
          'data',
          'pokemon',
          'assets',
          'items',
          'poke-ball.png',
        ),
      );
      final loaded = await const LoadPokemonItemsCatalogUseCase().execute(
        workspace,
      );
      final raw = await _readRawCatalog(root);

      expect(result.downloadedSpriteIds, ['poke-ball']);
      expect(await sprite.readAsBytes(), [1, 2, 3, 4]);
      expect(
        loaded.entries.single.localSpritePath,
        'data/pokemon/assets/items/poke-ball.png',
      );
      expect(jsonEncode(raw), isNot(contains('localSpritePath')));
      expect(jsonEncode(raw), isNot(contains('spriteUrl')));
    },
  );

  test(
    'dry-run does not mutate the strict catalog or download assets',
    () async {
      external.addItem('potion', _potionPayload());
      final before = await _catalogFile(root).readAsString();

      final result = await sync.execute(
        workspace,
        dryRun: true,
        downloadSprites: true,
      );

      expect(result.dryRun, isTrue);
      expect(result.createdIds, ['potion']);
      expect(await _catalogFile(root).readAsString(), before);
      expect(external.fetchedBinaryAssets, isEmpty);
    },
  );
}

ProjectItemCatalog _catalog() {
  return const ProjectItemCatalog(schemaVersion: 1, entries: []);
}

Future<void> _writeCatalog(Directory root, ProjectItemCatalog catalog) async {
  final file = _catalogFile(root);
  await file.create(recursive: true);
  await file.writeAsString(
    const JsonEncoder.withIndent(
      ' ',
    ).convert(encodeProjectItemCatalog(catalog)),
  );
}

File _catalogFile(Directory root) {
  return File(p.join(root.path, 'data', 'pokemon', 'catalogs', 'items.json'));
}

Future<Map<String, Object?>> _readRawCatalog(Directory root) async {
  return (jsonDecode(await _catalogFile(root).readAsString()) as Map)
      .cast<String, Object?>();
}

Map<String, dynamic> _potionPayload() {
  return {
    'id': 17,
    'name': 'potion',
    'names': [
      {
        'language': {'name': 'en'},
        'name': 'Potion',
      },
    ],
    'category': {'name': 'medicine'},
    'pocket': {'name': 'medicine'},
    'cost': 300,
    'fling_power': 30,
    'effect_entries': [
      {
        'language': {'name': 'en'},
        'effect': 'Restores 20 HP.',
        'short_effect': 'Restores HP.',
      },
    ],
    'flavor_text_entries': [
      {
        'language': {'name': 'en'},
        'text': 'A spray-type medicine for wounds.',
      },
    ],
    'sprites': <String, dynamic>{},
  };
}

Map<String, dynamic> _pokeBallPayload() {
  return {
    'id': 4,
    'name': 'poke-ball',
    'names': [
      {
        'language': {'name': 'en'},
        'name': 'Poké Ball',
      },
    ],
    'category': {'name': 'standard-balls'},
    'pocket': {'name': 'balls'},
    'cost': 200,
    'effect_entries': const <Object?>[],
    'flavor_text_entries': const <Object?>[],
    'sprites': {'default': _spriteUrl},
  };
}

const _spriteUrl = 'https://example.test/poke-ball.png';

class _FakeExternalRepository implements PokemonExternalSourceRepository {
  final List<String> itemIds = [];
  final Map<String, Map<String, dynamic>> payloads = {};
  final Map<String, PokemonExternalBinaryAsset> binaryAssets = {};
  final List<String> fetchedBinaryAssets = [];

  void addItem(String id, Map<String, dynamic> payload) {
    itemIds.add(id);
    payloads[id] = payload;
  }

  @override
  Future<Map<String, dynamic>> fetchPokeApiItemsResourceList({
    required int limit,
    required int offset,
  }) async {
    if (offset > 0) {
      return {'results': <Object?>[], 'next': null};
    }
    return {
      'results': [
        for (final id in itemIds)
          {'name': id, 'url': 'https://pokeapi.co/api/v2/item/$id/'},
      ],
      'next': null,
    };
  }

  @override
  Future<Map<String, dynamic>> fetchPokeApiItemPayload(
    String itemIdOrName,
  ) async =>
      payloads[itemIdOrName]!;

  @override
  Future<PokemonExternalBinaryAsset> fetchBinaryAsset(String sourceUrl) async {
    fetchedBinaryAssets.add(sourceUrl);
    return binaryAssets[sourceUrl]!;
  }

  @override
  Future<Map<String, dynamic>> fetchPokeApiEvolutionChainPayload(
    String speciesId,
  ) =>
      throw UnimplementedError();

  @override
  Future<Map<String, dynamic>> fetchPokeApiPokemonPayload(String speciesId) =>
      throw UnimplementedError();

  @override
  Future<Map<String, dynamic>> fetchPokeApiPokemonSpeciesPayload(
    String speciesId,
  ) =>
      throw UnimplementedError();

  @override
  Future<Map<String, dynamic>> fetchShowdownMovesSnapshot() =>
      throw UnimplementedError();

  @override
  Future<Map<String, dynamic>> fetchShowdownPokedexSnapshot() =>
      throw UnimplementedError();

  @override
  Future<Map<String, dynamic>> fetchShowdownSpeciesPayload(String speciesId) =>
      throw UnimplementedError();
}
