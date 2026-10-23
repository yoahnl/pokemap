import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/application/runtime_project_catalog.dart';
import 'package:path/path.dart' as p;

void main() {
  for (final partitioned in [false, true]) {
    test('route appearance demand excludes inaccessible scene skins partitioned=$partitioned', () async {
      final root = await Directory.systemTemp.createTemp('route-appearance-catalog-');
      addTearDown(() => root.delete(recursive: true));
      final project = ProjectManifest(name: 'Route skin scope', maps: [],
        tilesets: [for (final id in ['base', 'costume', 'unused'])
          ProjectTilesetEntry(id: id, name: id, relativePath: '$id.png')],
        characters: [for (final id in ['base', 'costume', 'unused'])
          ProjectCharacterEntry(id: id, name: id, tilesetId: id)],
        eventRegistry: NarrativeEventRegistry(schemaVersion: 1, mode: EventSystemMode.v2Only,
          records: [NarrativeEventRecord.configuredStructurallyUnchecked(NarrativeEventDefinition(
            id: 'evt_00000000-0000-7000-8000-000000000026', name: 'Costume route',
            source: NarrativeEventSourceRef.entityInteract('room', 'actor'), conditions: [],
            sceneId: 'costume', reusePolicy: NarrativeEventReusePolicy.reusable, priority: 0, order: 0), enabled: true)],
          legacyClaims: const []),
        scenes: [for (final id in ['costume', 'unused']) SceneAsset(id: id, name: id,
          graph: SceneGraph(startNodeId: 'start', nodes: [
            SceneNode(id: 'start', kind: SceneNodeKind.start),
            SceneNode(id: 'skin', kind: SceneNodeKind.action, payload: SceneActionPayload.interactive(
              SceneInteractiveCommand.actorRoute(target: SceneActorTarget.player(mapId: 'room'),
                steps: [SceneActorRouteStep.appearance(characterId: id)]))),
            SceneNode(id: 'end', kind: SceneNodeKind.end),
          ], edges: [SceneEdge(id: 'start-skin', fromNodeId: 'start', fromPortId: 'completed', toNodeId: 'skin', kind: SceneEdgeKind.defaultFlow),
            SceneEdge(id: 'skin-end', fromNodeId: 'skin', fromPortId: 'completed', toNodeId: 'end', kind: SceneEdgeKind.actionCompleted)]))]);
      final catalog = await RuntimeProjectCatalog.open(await _writeProject(root, project, partitioned: partitioned));
      addTearDown(catalog.dispose);
      const map = MapData(id: 'room', name: 'Room', size: GridSize(width: 2, height: 2),
        entities: [MapEntity(id: 'actor', kind: MapEntityKind.npc, pos: GridPos(x: 0, y: 0), npc: MapEntityNpcData(characterId: 'base'))]);
      final selected = await catalog.manifestForMap(map);
      expect(selected.characters.map((value) => value.id).toSet(), {'base', 'costume'});
      expect(selected.tilesets.map((value) => value.id).toSet(), {'base', 'costume'});
    });
  }
  for (final partitioned in [false, true]) {
    test(
      'identical typed roots reuse one owned projection, partitioned=$partitioned',
      () async {
        final root = await Directory.systemTemp.createTemp(
          'runtime-projection-reuse-',
        );
        addTearDown(() => root.delete(recursive: true));
        final project =
            PortableCatalogPublication.withProjectDynamicDependencies(
              ProjectManifest(
                name: 'Projection reuse',
                maps: const [],
                tilesets: [
                  for (final id in ['tile-0', 'tile-1', 'tile-2'])
                    ProjectTilesetEntry(
                      id: id,
                      name: id,
                      relativePath: '$id.png',
                    ),
                ],
              ),
              [
                CatalogDynamicDependency(
                  owner: CatalogDefinitionKey(
                    CatalogDefinitionKind.tileset,
                    'tile-0',
                  ),
                  targets: [
                    CatalogDefinitionKey(
                      CatalogDefinitionKind.tileset,
                      'tile-1',
                    ),
                  ],
                ),
              ],
            );
        final path = await _writeProject(
          root,
          project,
          partitioned: partitioned,
        );
        final catalog = await RuntimeProjectCatalog.open(path);
        addTearDown(catalog.dispose);
        const map = MapData(
          id: 'map',
          name: 'Map',
          size: GridSize(width: 1, height: 1),
          tilesetId: 'tile-0',
        );
        final first = await catalog.manifestForMap(map);
        final second = await catalog.manifestForMap(
          map.copyWith(id: 'other', name: 'Other'),
        );
        final third = await catalog.manifestForMap(map);
        if (partitioned) {
          expect(second, same(first));
          expect(third, same(first));
        } else {
          expect(second.toJson(), first.toJson());
          expect(third.toJson(), first.toJson());
        }
        expect(first.tilesets.map((entry) => entry.id), ['tile-0', 'tile-1']);
        expect(RuntimeProjectCatalog.ownerOf(first), same(catalog));
        final changed = await catalog.manifestForMap(
          map.copyWith(tilesetId: 'tile-2'),
        );
        expect(changed, isNot(same(first)));
        expect(changed.tilesets.map((entry) => entry.id), ['tile-2']);
        final returned = await catalog.manifestForMap(map);
        if (partitioned) {
          expect(returned, same(first));
        } else {
          expect(returned.toJson(), first.toJson());
        }
      },
    );
  }

  test('portable projection singleflight shares one result for concurrent equal roots', () async {
    final root = await Directory.systemTemp.createTemp(
      'runtime-projection-flight-',
    );
    addTearDown(() => root.delete(recursive: true));
    final catalog = await RuntimeProjectCatalog.open(
      await _writeProject(root, _projectionCacheProject()),
    );
    addTearDown(catalog.dispose);
    const map = MapData(
      id: 'a',
      name: 'A',
      size: GridSize(width: 1, height: 1),
      tilesetId: 'tile',
    );
    final results = await Future.wait([
      catalog.manifestForMap(map),
      catalog.manifestForMap(map.copyWith(id: 'b')),
      catalog.manifestForMap(map),
    ]);
    expect(results[1], same(results[0]));
    expect(results[2], same(results[0]));
    expect(RuntimeProjectCatalog.ownerOf(results[0]), same(catalog));
  });

  test('portable projection keys include typed extras and ignore root order and duplicates', () async {
    final root = await Directory.systemTemp.createTemp(
      'runtime-projection-roots-',
    );
    addTearDown(() => root.delete(recursive: true));
    final catalog = await RuntimeProjectCatalog.open(
      await _writeProject(root, _projectionCacheProject()),
    );
    addTearDown(catalog.dispose);
    const tileMap = MapData(
      id: 'a',
      name: 'A',
      size: GridSize(width: 1, height: 1),
      tilesetId: 'tile',
    );
    final otherMap = tileMap.copyWith(id: 'b', tilesetId: 'other');
    final plain = await catalog.manifestForMap(tileMap);
    final withCharacter = await catalog.manifestForMap(
      tileMap,
      extraCharacterIds: ['tile'],
    );
    expect(withCharacter, isNot(same(plain)));
    expect(plain.characters, isEmpty);
    expect(withCharacter.characters.single.id, 'tile');
    expect(withCharacter.tilesets.map((entry) => entry.id).toSet(), {
      'tile',
      'other',
    });
    final batch = await catalog.manifestForMaps([tileMap, otherMap, tileMap]);
    expect(await catalog.manifestForMaps([otherMap, tileMap]), same(batch));
    expect(
      await catalog.manifestForMap(
        tileMap,
        extraCharacterIds: ['tile', 'tile'],
      ),
      same(withCharacter),
    );
    expect(batch.characters, isEmpty);
  });

  test(
    'portable projections retain at most eight root sets in least recent order',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'runtime-projection-lru-',
      );
      addTearDown(() => root.delete(recursive: true));
      final project = ProjectManifest(
        name: 'Projection LRU',
        maps: const [],
        tilesets: [
          for (var i = 0; i < 9; i++)
            ProjectTilesetEntry(
              id: 'tile-$i',
              name: '$i',
              relativePath: '$i.png',
            ),
        ],
      );
      final catalog = await RuntimeProjectCatalog.open(
        await _writeProject(root, project),
      );
      addTearDown(catalog.dispose);
      final maps = [
        for (var i = 0; i < 9; i++)
          MapData(
            id: '$i',
            name: '$i',
            size: const GridSize(width: 1, height: 1),
            tilesetId: 'tile-$i',
          ),
      ];
      final retained = [
        for (final map in maps.take(8)) await catalog.manifestForMap(map),
      ];
      expect(await catalog.manifestForMap(maps[0]), same(retained[0]));
      await catalog.manifestForMap(maps[8]);
      expect(await catalog.manifestForMap(maps[0]), same(retained[0]));
      expect(await catalog.manifestForMap(maps[1]), isNot(same(retained[1])));
    },
  );

  test('projection ownership is isolated across changed publications at the same path', () async {
    final root = await Directory.systemTemp.createTemp(
      'runtime-projection-owner-',
    );
    addTearDown(() => root.delete(recursive: true));
    final project = _projectionCacheProject();
    final path = await _writeProject(root, project);
    final a = await RuntimeProjectCatalog.open(path);
    addTearDown(a.dispose);
    const map = MapData(
      id: 'a',
      name: 'A',
      size: GridSize(width: 1, height: 1),
      tilesetId: 'tile',
    );
    final first = await a.manifestForMap(map);
    await _writeProject(
      root,
      project.copyWith(
        tilesets: [
          for (final tile in project.tilesets)
            tile.copyWith(name: '${tile.name} changed'),
        ],
      ),
    );
    final b = await RuntimeProjectCatalog.open(path);
    addTearDown(b.dispose);
    final second = await b.manifestForMap(map);
    expect(second, isNot(same(first)));
    expect(second.tilesets.single.name, 'tile changed');
    expect(first.tilesets.single.name, 'tile');
    expect(RuntimeProjectCatalog.ownerOf(first), same(a));
    expect(RuntimeProjectCatalog.ownerOf(second), same(b));
    expect(await a.manifestForMap(map), same(first));
    a.dispose();
    expect(RuntimeProjectCatalog.ownerOf(first), isNull);
    await expectLater(a.manifestForMap(map), throwsStateError);
    expect(await b.manifestForMap(map), same(second));
  });

  test('portable projection retention is bounded by source bytes and skips oversized results', () async {
    final root = await Directory.systemTemp.createTemp(
      'runtime-projection-bytes-',
    );
    addTearDown(() => root.delete(recursive: true));
    final padding = 'x' * 900000;
    final project = ProjectManifest(
      name: 'Projection byte budget',
      maps: const [],
      tilesets: [
        for (var i = 0; i < 10; i++)
          ProjectTilesetEntry(
            id: 'large-$i',
            name: 'Large $i',
            relativePath: '$i.png',
            paletteEntries: [
              TilesetPaletteEntry(
                id: 'palette-$i',
                name: padding,
                frames: const [
                  TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 0)),
                ],
              ),
            ],
          ),
      ],
    );
    final publication = PortableCatalogPublication.encodeProject(project);
    final sourceBytes = publication.storage.objects.values.fold<int>(
      0,
      (total, bytes) => total + bytes.length,
    );
    expect(sourceBytes, greaterThan(8 * 1024 * 1024));
    final path = p.join(root.path, 'project.json');
    await File(path).writeAsString(jsonEncode(publication.descriptor));
    for (final entry in publication.storage.objects.entries) {
      final target = File(
        p.join(root.path, 'catalog/objects/${entry.key}.json'),
      );
      await target.parent.create(recursive: true);
      await target.writeAsBytes(entry.value);
    }
    final catalog = await RuntimeProjectCatalog.open(path);
    addTearDown(catalog.dispose);
    final maps = [
      for (var i = 0; i < 10; i++)
        MapData(
          id: '$i',
          name: '$i',
          size: const GridSize(width: 1, height: 1),
          tilesetId: 'large-$i',
        ),
    ];
    final firstHalf = await catalog.manifestForMaps(maps.take(5));
    expect(
      identical(await catalog.manifestForMaps(maps.take(5)), firstHalf),
      isTrue,
    );
    await catalog.manifestForMaps(maps.skip(5));
    expect(
      identical(await catalog.manifestForMaps(maps.take(5)), firstHalf),
      isFalse,
    );
    final oversized = await catalog.manifestForMaps(maps);
    expect(oversized.tilesets, hasLength(10));
    expect(identical(await catalog.manifestForMaps(maps), oversized), isFalse);
  });

  test('portable projection results beyond the retained unit ceiling remain valid but uncached', () async {
    final root = await Directory.systemTemp.createTemp(
      'runtime-projection-units-',
    );
    addTearDown(() => root.delete(recursive: true));
    final project = PortableCatalogPublication.withProjectDynamicDependencies(
      ProjectManifest(
        name: 'Projection unit budget',
        maps: const [],
        tilesets: [
          for (var i = 0; i < 257; i++)
            ProjectTilesetEntry(
              id: 'unit-$i',
              name: '$i',
              relativePath: '$i.png',
            ),
        ],
      ),
      [
        CatalogDynamicDependency(
          owner: CatalogDefinitionKey(CatalogDefinitionKind.tileset, 'unit-0'),
          targets: [
            for (var i = 1; i < 257; i++)
              CatalogDefinitionKey(CatalogDefinitionKind.tileset, 'unit-$i'),
          ],
        ),
      ],
    );
    final catalog = await RuntimeProjectCatalog.open(
      await _writeProject(root, project),
    );
    addTearDown(catalog.dispose);
    final maps = [
      for (var i = 0; i < 257; i++)
        MapData(
          id: '$i',
          name: '$i',
          size: const GridSize(width: 1, height: 1),
          tilesetId: 'unit-$i',
        ),
    ];
    final first = await catalog.manifestForMaps(maps);
    final second = await catalog.manifestForMaps(maps);
    expect(first.tilesets, hasLength(257));
    expect(
      second.tilesets.map((entry) => entry.id),
      first.tilesets.map((entry) => entry.id),
    );
    expect(identical(first, second), isFalse);
    final closureFirst = await catalog.manifestForMap(maps.first);
    final closureSecond = await catalog.manifestForMap(maps.first);
    expect(closureFirst.tilesets, hasLength(257));
    expect(
      closureSecond.tilesets.map((entry) => entry.id),
      closureFirst.tilesets.map((entry) => entry.id),
    );
    expect(identical(closureFirst, closureSecond), isFalse);
  });

  test('disposing a session rejects a warmed projection hit before its result is observed', () async {
    final root = await Directory.systemTemp.createTemp(
      'runtime-projection-dispose-hit-',
    );
    addTearDown(() => root.delete(recursive: true));
    final catalog = await RuntimeProjectCatalog.open(
      await _writeProject(root, _projectionCacheProject()),
    );
    addTearDown(catalog.dispose);
    const map = MapData(
      id: 'a',
      name: 'A',
      size: GridSize(width: 1, height: 1),
      tilesetId: 'tile',
    );
    final warm = await catalog.manifestForMap(map);
    final pendingHit = catalog.manifestForMap(map);
    catalog.dispose();
    await expectLater(pendingHit, throwsStateError);
    expect(RuntimeProjectCatalog.ownerOf(warm), isNull);
  });

  test(
    'partitioned session resolves each map and declared dependencies only',
    () async {
      final root = await Directory.systemTemp.createTemp('runtime-catalog-');
      addTearDown(() => root.delete(recursive: true));
      final project = PortableCatalogPublication.withProjectDynamicDependencies(
        ProjectManifest(
          name: 'Maps',
          version: ProjectVersion.v8,
          maps: const [],
          tilesets: [
            for (var i = 0; i < 1000; i++)
              ProjectTilesetEntry(
                id: 'tileset-$i',
                name: '$i',
                relativePath: '$i.png',
              ),
          ],
        ),
        [
          CatalogDynamicDependency(
            owner: CatalogDefinitionKey(
              CatalogDefinitionKind.tileset,
              'tileset-0',
            ),
            targets: [
              CatalogDefinitionKey(CatalogDefinitionKind.tileset, 'tileset-1'),
            ],
          ),
        ],
      );
      final publication = PortableCatalogPublication.encodeProject(project);
      final file = File(p.join(root.path, 'project.json'));
      await file.writeAsString(jsonEncode(publication.descriptor));
      for (final object in publication.storage.objects.entries) {
        final decoded = jsonDecode(utf8.decode(object.value)) as Map;
        if (decoded['key'] case {'id': 'tileset-999'}) continue;
        final target = File(
          p.join(root.path, 'catalog/objects/${object.key}.json'),
        );
        await target.parent.create(recursive: true);
        await target.writeAsBytes(object.value);
      }
      final catalog = await RuntimeProjectCatalog.open(file.path);
      addTearDown(catalog.dispose);
      expect(catalog.projectMetadata.tilesets, isEmpty);
      expect(
        RuntimeProjectCatalog.ownerOf(catalog.projectMetadata),
        same(catalog),
      );
      final map = MapData(
        id: 'a',
        name: 'A',
        size: const GridSize(width: 2, height: 2),
        tilesetId: 'tileset-0',
      );
      final first = await catalog.manifestForMap(map);
      expect(first.tilesets.map((entry) => entry.id), [
        'tileset-0',
        'tileset-1',
      ]);
      expect(RuntimeProjectCatalog.ownerOf(first), same(catalog));
      final second = await catalog.manifestForMap(
        map.copyWith(tilesetId: 'tileset-2'),
      );
      expect(second.tilesets.map((entry) => entry.id), ['tileset-2']);
      expect(catalog.projectMetadata.tilesets, isEmpty);
      await expectLater(
        catalog.manifestForMap(map.copyWith(tilesetId: 'tileset-999')),
        throwsA(isA<FileSystemException>()),
      );
      catalog.dispose();
      expect(RuntimeProjectCatalog.ownerOf(first), isNull);
      await expectLater(catalog.manifestForMap(map), throwsStateError);
    },
  );

  test('a map batch preserves the union of individual catalog views', () async {
    final root = await Directory.systemTemp.createTemp('runtime-map-batch-');
    addTearDown(() => root.delete(recursive: true));
    final project = PortableCatalogPublication.withProjectDynamicDependencies(
      ProjectManifest(
        name: 'Batch maps',
        version: ProjectVersion.v8,
        maps: const [],
        tilesets: [
          for (final i in [0, 1, 2, 999])
            ProjectTilesetEntry(
              id: 'tileset-$i',
              name: '$i',
              relativePath: '$i.png',
            ),
        ],
        globalProperties: const {'batchFixture': 'unchanged'},
      ),
      [
        for (final owner in ['tileset-0', 'tileset-2'])
          CatalogDynamicDependency(
            owner: CatalogDefinitionKey(CatalogDefinitionKind.tileset, owner),
            targets: [
              CatalogDefinitionKey(CatalogDefinitionKind.tileset, 'tileset-1'),
            ],
          ),
      ],
    );
    final path = await _writeProject(root, project);
    final publication = PortableCatalogPublication.encodeProject(project);
    for (final object in publication.storage.objects.entries) {
      final decoded = jsonDecode(utf8.decode(object.value)) as Map;
      if (decoded['key'] case {'id': 'tileset-999'}) {
        await File(p.join(root.path, 'catalog/objects/${object.key}.json'))
            .delete();
      }
    }
    final catalog = await RuntimeProjectCatalog.open(path);
    addTearDown(catalog.dispose);
    const firstMap = MapData(
      id: 'a',
      name: 'A',
      size: GridSize(width: 2, height: 2),
      tilesetId: 'tileset-0',
    );
    final secondMap = firstMap.copyWith(id: 'b', tilesetId: 'tileset-2');
    final firstView = await catalog.manifestForMap(firstMap);
    final secondView = await catalog.manifestForMap(secondMap);
    final expected = catalog.mergeNarrativeVisualDefinitions(
      catalog.projectMetadata,
      [firstView, secondView],
    );
    final batch = await catalog.manifestForMaps([firstMap, secondMap]);
    expect(batch.toJson(), expected.toJson());
    expect(batch.tilesets.map((entry) => entry.id), [
      'tileset-0',
      'tileset-1',
      'tileset-2',
    ]);
    expect(RuntimeProjectCatalog.ownerOf(batch), same(catalog));
    expect(catalog.projectMetadata.tilesets, isEmpty);
    await expectLater(
      catalog.manifestForMaps([
        firstMap,
        secondMap.copyWith(tilesetId: 'tileset-999'),
      ]),
      throwsA(isA<FileSystemException>()),
    );
    expect(
      (await catalog.manifestForMap(firstMap)).toJson(),
      firstView.toJson(),
    );
  });

  test(
    'a portrait-only character resolves definitions without map actor roots',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'runtime-portrait-only-',
      );
      addTearDown(() => root.delete(recursive: true));
      final project = ProjectManifest(
        name: 'Portrait',
        maps: [],
        settings: const ProjectSettings(defaultPlayerCharacterId: 'hero'),
        tilesets: [
          for (final id in [
            'speaker',
            'hero',
            ...List.generate(1000, (i) => 'unused-$i'),
          ])
            ProjectTilesetEntry(id: id, name: id, relativePath: '$id.png'),
        ],
        characters: const [
          ProjectCharacterEntry(id: 'hero', name: 'Hero', tilesetId: 'hero'),
          ProjectCharacterEntry(
            id: 'speaker',
            name: 'Speaker',
            tilesetId: 'speaker',
          ),
        ],
      );
      final catalog = await RuntimeProjectCatalog.open(
        await _writeProject(root, project),
      );
      addTearDown(catalog.dispose);
      final view = await catalog.manifestForCharacter('speaker');
      expect(view.characters.single.id, 'speaker');
      expect(view.tilesets.single.id, 'speaker');
      expect(RuntimeProjectCatalog.ownerOf(view), same(catalog));
      expect(catalog.projectMetadata.characters, isEmpty);
      await expectLater(
        catalog.manifestForCharacter('unknown'),
        throwsA(
          isA<RuntimeCatalogDefinitionMissingException>().having(
            (error) => error.key,
            'key',
            CatalogDefinitionKey(CatalogDefinitionKind.character, 'unknown'),
          ),
        ),
      );
    },
  );

  for (final partitioned in [false, true]) {
    test(
      'publication freshness and nested metadata, partitioned=$partitioned',
      () async {
        final root = await Directory.systemTemp.createTemp(
          'runtime-freshness-',
        );
        addTearDown(() => root.delete(recursive: true));
        const project = ProjectManifest(
          name: 'Same name',
          maps: [],
          tilesets: [],
          globalProperties: {
            'nested': {
              'values': [1, 2],
            },
            'revision': 1,
          },
        );
        final path = await _writeProject(
          root,
          project,
          partitioned: partitioned,
        );
        final first = await RuntimeProjectCatalog.open(path);
        addTearDown(first.dispose);
        expect(await first.isCurrentPublication(), isTrue);
        final nested = first.projectMetadata.globalProperties['nested'] as Map;
        expect(() => nested['added'] = true, throwsUnsupportedError);
        expect(() => (nested['values'] as List).add(3), throwsUnsupportedError);
        final view = await first.manifestForMap(
          const MapData(
            id: 'map',
            name: 'Map',
            size: GridSize(width: 1, height: 1),
          ),
        );
        expect(
          () => ((view.globalProperties['nested'] as Map)['values'] as List)
              .clear(),
          throwsUnsupportedError,
        );
        await _writeProject(
          root,
          project.copyWith(globalProperties: {'revision': 2}),
          partitioned: partitioned,
        );
        final second = await RuntimeProjectCatalog.open(path);
        addTearDown(second.dispose);
        expect(first.projectMetadata.name, second.projectMetadata.name);
        expect(await first.isCurrentPublication(), isFalse);
        expect(await second.isCurrentPublication(), isTrue);
        final file = File(path);
        final saved = await file.readAsString();
        await file.writeAsString('{');
        expect(await second.isCurrentPublication(), isFalse);
        await file.writeAsString(saved);
        expect(await second.isCurrentPublication(), isTrue);
        await file.delete();
        expect(await second.isCurrentPublication(), isFalse);
        second.dispose();
        expect(await second.isCurrentPublication(), isFalse);
      },
    );
  }

  for (final quota in ['bytes', 'values']) {
    test('retries cannot bypass the global catalog $quota ceiling', () async {
      final root = await Directory.systemTemp.createTemp('runtime-quota-');
      addTearDown(() => root.delete(recursive: true));
      const project = ProjectManifest(
        name: 'Quota',
        maps: [],
        tilesets: [
          ProjectTilesetEntry(
            id: 'tile',
            name: 'Tile',
            relativePath: 'tile.png',
          ),
        ],
      );
      final built = PortableCatalogPublication.encodeProject(project);
      final bytes = built.storage.objects.values.fold<int>(
        0,
        (total, object) => total + object.length,
      );
      final values = built.storage.objects.entries.fold<int>(
        0,
        (total, object) =>
            total +
            PortableCatalogPublication.validateCatalogObjectBytes(
              CatalogObjectReference(
                sha256: object.key,
                byteLength: object.value.length,
              ),
              object.value,
            ),
      );
      final path = await _writeProject(root, project);
      final catalog = await RuntimeProjectCatalog.open(
        path,
        limits: CatalogStorageLimits(
          maxStoredBytes: quota == 'bytes' ? bytes - 1 : 128 * 1024 * 1024,
        ),
        maximumCatalogJsonValues: quota == 'values' ? values - 1 : 8000000,
      );
      addTearDown(catalog.dispose);
      for (var retry = 0; retry < 3; retry++) {
        await expectLater(
          catalog.manifestForMap(
            const MapData(
              id: 'map',
              name: 'Map',
              size: GridSize(width: 1, height: 1),
              tilesetId: 'tile',
            ),
          ),
          throwsFormatException,
        );
      }
    });
  }

  for (final marker in ['format', 'kind', 'root']) {
    test('native documents cannot bypass publication marker $marker', () async {
      final root = await Directory.systemTemp.createTemp('runtime-marker-');
      addTearDown(() => root.delete(recursive: true));
      final file = File(p.join(root.path, 'project.json'));
      final raw = const ProjectManifest(
        name: 'Native',
        maps: [],
        tilesets: [],
      ).toJson();
      raw[marker] = marker == 'kind' ? 'project' : 'invalid';
      await file.writeAsString(jsonEncode(raw));
      await expectLater(
        RuntimeProjectCatalog.open(file.path),
        throwsFormatException,
      );
    });
  }

  for (final partitioned in [false, true]) {
    test(
      'typed decor and character closure, partitioned=$partitioned',
      () async {
        final root = await Directory.systemTemp.createTemp('runtime-typed-');
        addTearDown(() => root.delete(recursive: true));
        final project = ProjectManifest(
          name: 'Typed',
          maps: [],
          tilesets: [
            for (final id in ['base', 'override', 'hero', 'saved', 'unused'])
              ProjectTilesetEntry(id: id, name: id, relativePath: '$id.png'),
          ],
          elements: const [
            ProjectElementEntry(
              id: 'decor',
              name: 'Decor',
              tilesetId: 'base',
              categoryId: 'child',
              frames: [
                TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 0)),
                TilesetVisualFrame(
                  tilesetId: 'override',
                  source: TilesetSourceRect(x: 0, y: 0),
                ),
              ],
            ),
          ],
          elementCategories: const [
            ProjectElementCategory(id: 'parent', name: 'Parent'),
            ProjectElementCategory(
              id: 'child',
              name: 'Child',
              parentCategoryId: 'parent',
            ),
          ],
          characters: const [
            ProjectCharacterEntry(id: 'hero', name: 'Hero', tilesetId: 'hero'),
            ProjectCharacterEntry(
              id: 'saved',
              name: 'Saved avatar',
              tilesetId: 'saved',
            ),
            ProjectCharacterEntry(
              id: 'unused',
              name: 'Unused',
              tilesetId: 'unused',
            ),
          ],
        );
        final path = await _writeProject(
          root,
          project,
          partitioned: partitioned,
        );
        final catalog = await RuntimeProjectCatalog.open(path);
        addTearDown(catalog.dispose);
        final view = await catalog.manifestForMap(
          const MapData(
            id: 'map',
            name: 'Map',
            size: GridSize(width: 1, height: 1),
            placedElements: [
              MapPlacedElement(
                id: 'decor',
                layerId: 'objects',
                elementId: 'decor',
                pos: GridPos(x: 0, y: 0),
              ),
            ],
          ),
          extraCharacterIds: ['saved'],
        );
        expect(view.tilesets.map((value) => value.id).toSet(), {
          'base',
          'override',
          'saved',
        });
        expect(view.characters.single.id, 'saved');
        expect(view.elementCategories.map((value) => value.id).toSet(), {
          'child',
          'parent',
        });
        expect(catalog.projectMetadata.characters, isEmpty);
      },
    );
  }

  test(
    'Smart Tile rules, patterns, animations and all their atlas frames close',
    () async {
      final root = await Directory.systemTemp.createTemp('runtime-smart-');
      addTearDown(() => root.delete(recursive: true));
      final project = ProjectManifest(
        name: 'Smart',
        maps: [],
        tilesets: [
          for (final id in ['base', 'animated', 'unused'])
            ProjectTilesetEntry(id: id, name: id, relativePath: '$id.png'),
        ],
        smartTileCatalog: ProjectSmartTileCatalog(
          materials: const [
            ProjectSmartTileMaterial(
              id: 'grass',
              name: 'Grass',
              connectionGroupId: 'grass',
            ),
          ],
          atlases: [
            for (final id in ['base', 'animated', 'unused'])
              ProjectSmartTileAtlas(
                id: id,
                name: id,
                tilesetId: id,
                columns: 1,
                rows: 1,
              ),
          ],
          animations: const [
            ProjectSmartTileAnimation(
              id: 'wind',
              name: 'Wind',
              frames: [
                ProjectSmartTileAnimationFrame(
                  frame: SmartTileFrameRef(
                    atlasId: 'animated',
                    column: 0,
                    row: 0,
                  ),
                  durationMs: 100,
                ),
              ],
            ),
          ],
          presets: const [
            ProjectSmartTilePreset(
              id: 'ground',
              name: 'Ground',
              usage: SmartTileUsage.terrain,
              topology: SmartTileTopology.uniform,
              coveragePolicy: SmartTileCoveragePolicy.sparse,
              coverageProfile: SmartTileCoverageProfile(
                mode: SmartTileCoverageMode.template,
              ),
              transformPolicy: SmartTileTransformPolicy(),
              defaultMaterialId: 'grass',
              allowedMaterialIds: ['grass'],
              rules: [
                SmartTileRule(
                  id: 'base',
                  centerMatch: SmartTileSlotMatch.material('grass'),
                  candidates: [
                    SmartTileCandidate(
                      id: 'base',
                      parts: [
                        SmartTileVisualPart(
                          source: SmartTileVisualSource.frame(
                            frame: SmartTileFrameRef(
                              atlasId: 'base',
                              column: 0,
                              row: 0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
          patterns: const [
            ProjectSmartTilePattern(
              id: 'flowers',
              name: 'Flowers',
              usage: SmartTileUsage.terrain,
              width: 1,
              height: 1,
              cells: [
                SmartTilePatternCell(
                  x: 0,
                  y: 0,
                  parts: [
                    SmartTileVisualPart(
                      source: SmartTileVisualSource.animation(
                        animationId: 'wind',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      );
      final catalog = await RuntimeProjectCatalog.open(
        await _writeProject(root, project),
      );
      addTearDown(catalog.dispose);
      final view = await catalog.manifestForMap(
        const MapData(
          id: 'map',
          name: 'Map',
          size: GridSize(width: 1, height: 1),
          layers: [
            MapLayer.smartTile(
              id: 'ground',
              name: 'Ground',
              presetId: 'ground',
              usage: SmartTileUsage.terrain,
              field: SmartTileField.cell(semanticCells: [0]),
              patternStrokes: [
                SmartTilePatternStroke(
                  id: 'flowers',
                  patternId: 'flowers',
                  cells: [GridPos(x: 0, y: 0)],
                ),
              ],
            ),
          ],
        ),
      );
      expect(view.tilesets.map((value) => value.id).toSet(), {
        'base',
        'animated',
      });
      expect(view.smartTileCatalog.animations.single.id, 'wind');
      expect(view.smartTileCatalog.patterns.single.id, 'flowers');
      expect(view.smartTileCatalog.materials.single.id, 'grass');
    },
  );

  test(
    'static dependency cycles fail without retaining a partial map',
    () async {
      final root = await Directory.systemTemp.createTemp('runtime-cycle-');
      addTearDown(() => root.delete(recursive: true));
      final project = ProjectManifest(
        name: 'Cycle',
        maps: [],
        tilesets: const [
          ProjectTilesetEntry(
            id: 'tile',
            name: 'Tile',
            relativePath: 'tile.png',
            folderId: 'a',
          ),
        ],
        tilesetFolders: const [
          ProjectTilesetFolder(id: 'a', name: 'A', parentFolderId: 'b'),
          ProjectTilesetFolder(id: 'b', name: 'B', parentFolderId: 'a'),
        ],
      );
      final catalog = await RuntimeProjectCatalog.open(
        await _writeProject(root, project),
      );
      addTearDown(catalog.dispose);
      const map = MapData(
        id: 'map',
        name: 'Map',
        size: GridSize(width: 1, height: 1),
        tilesetId: 'tile',
      );
      await expectLater(catalog.manifestForMap(map), throwsFormatException);
      expect(
        (await catalog.manifestForMap(map.copyWith(tilesetId: ''))).tilesets,
        isEmpty,
      );
    },
  );

  test(
    'spatial instances and environment palettes close all useful models',
    () async {
      final root = await Directory.systemTemp.createTemp('runtime-models-');
      addTearDown(() => root.delete(recursive: true));
      final bounds = Model3dBounds(
        min: Model3dVector3.zero,
        max: Model3dVector3(x: 1, y: 1, z: 1),
      );
      final project = ProjectManifest(
        name: 'Models',
        maps: [],
        tilesets: [],
        models3d: [
          for (final id in ['house', 'tree', 'unused'])
            ProjectModel3dEntry(
              id: id,
              name: id,
              sourceAssetId: 'source-$id',
              relativePath: 'assets/models3d/$id.glb',
              inspection: Model3dInspection(
                bounds: bounds,
                meshCount: 1,
                triangleCount: 1,
              ),
            ),
        ],
        environmentPresets: [
          EnvironmentPreset(
            id: 'forest',
            name: 'Forest',
            templateId: 'forest',
            palette: [EnvironmentPaletteItem(modelId: 'tree', weight: 1)],
            defaultParams: EnvironmentGenerationParams.standard(),
            sortOrder: 0,
          ),
        ],
      );
      final catalog = await RuntimeProjectCatalog.open(
        await _writeProject(root, project),
      );
      addTearDown(catalog.dispose);
      final map = MapData(
        id: 'map',
        name: 'Map',
        version: ProjectVersion.v9,
        size: const GridSize(width: 1, height: 1),
        spatialScene: MapSpatialScene(
          width: 1,
          depth: 1,
          instances: [
            SpatialModelInstance(
              id: 'house',
              modelId: 'house',
              position: Model3dVector3.zero,
            ),
          ],
        ),
        layers: [
          MapLayer.environment(
            id: 'forest',
            name: 'Forest',
            content: EnvironmentLayerContent(
              areas: [
                EnvironmentArea(
                  id: 'area',
                  name: 'Area',
                  presetId: 'forest',
                  seed: 0,
                  mask: EnvironmentAreaMask(width: 1, height: 1, cells: [true]),
                ),
              ],
            ),
          ),
        ],
      );
      final view = await catalog.manifestForMap(map);
      expect(view.models3d.map((model) => model.id).toSet(), {'house', 'tree'});
      expect(view.environmentPresets.single.id, 'forest');
    },
  );

  for (final escaped in [false, true]) {
    test(
      'selected catalog object rejects tampering, escaped=$escaped',
      () async {
        final root = await Directory.systemTemp.createTemp('runtime-tamper-');
        final outside = await Directory.systemTemp.createTemp(
          'runtime-outside-',
        );
        addTearDown(() async {
          await root.delete(recursive: true);
          await outside.delete(recursive: true);
        });
        const project = ProjectManifest(
          name: 'Tamper',
          maps: [],
          tilesets: [
            ProjectTilesetEntry(
              id: 'tile',
              name: 'Tile',
              relativePath: 'tile.png',
            ),
          ],
        );
        final built = PortableCatalogPublication.encodeProject(project);
        final path = await _writeProject(root, project);
        final object = built.storage.objects.entries.firstWhere((entry) {
          final json = jsonDecode(utf8.decode(entry.value)) as Map;
          return json['key'] is Map &&
              (json['key'] as Map)['kind'] == 'tileset';
        });
        final file = File(
          p.join(root.path, 'catalog/objects/${object.key}.json'),
        );
        if (escaped) {
          final target = File(p.join(outside.path, 'object.json'));
          await target.writeAsBytes(object.value);
          await file.delete();
          await Link(file.path).create(target.path);
        } else {
          await file.writeAsString(
            utf8.decode(object.value).replaceFirst('Tile', 'Fake'),
          );
        }
        final catalog = await RuntimeProjectCatalog.open(path);
        addTearDown(catalog.dispose);
        await expectLater(
          catalog.manifestForMap(
            const MapData(
              id: 'map',
              name: 'Map',
              size: GridSize(width: 1, height: 1),
              tilesetId: 'tile',
            ),
          ),
          throwsFormatException,
        );
        if (escaped) {
          await Link(file.path).delete();
        }
        await file.writeAsBytes(object.value);
        final retried = await catalog.manifestForMap(
          const MapData(
            id: 'map',
            name: 'Map',
            size: GridSize(width: 1, height: 1),
            tilesetId: 'tile',
          ),
        );
        expect(retried.tilesets.single.id, 'tile');
      },
    );
  }

  test(
    'catalog identity changes when a publication at the same path changes',
    () async {
      final root = await Directory.systemTemp.createTemp('runtime-identity-');
      addTearDown(() => root.delete(recursive: true));
      const first = ProjectManifest(name: 'First', maps: [], tilesets: []);
      final path = await _writeProject(root, first);
      final a = await RuntimeProjectCatalog.open(path);
      addTearDown(a.dispose);
      await _writeProject(root, first.copyWith(name: 'Second'));
      final b = await RuntimeProjectCatalog.open(path);
      addTearDown(b.dispose);
      expect(a.identity, isNot(b.identity));
      expect(a.projectMetadata.name, 'First');
      expect(b.projectMetadata.name, 'Second');
    },
  );

  test(
    'media asset catalog is loaded once from its canonical storage key',
    () async {
      final root = await Directory.systemTemp.createTemp('runtime-media-');
      addTearDown(() => root.delete(recursive: true));
      final path = await _writeProject(
        root,
        const ProjectManifest(name: 'Media', maps: [], tilesets: []),
      );
      final file = File(p.join(root.path, assetCatalogStorageKey));
      await file.parent.create(recursive: true);
      await file.writeAsString(jsonEncode(AssetCatalog().toJson()));
      final catalog = await RuntimeProjectCatalog.open(path);
      addTearDown(catalog.dispose);
      final loaded = await catalog.loadAssetCatalog();
      expect(loaded, isNotNull);
      await file.writeAsString('{}');
      expect(await catalog.loadAssetCatalog(), same(loaded));
    },
  );

  test('disposing a session rejects an in-flight definition lookup', () async {
    final root = await Directory.systemTemp.createTemp('runtime-dispose-');
    addTearDown(() => root.delete(recursive: true));
    final path = await _writeProject(
      root,
      const ProjectManifest(
        name: 'Dispose',
        maps: [],
        tilesets: [
          ProjectTilesetEntry(
            id: 'tile',
            name: 'Tile',
            relativePath: 'tile.png',
          ),
        ],
      ),
    );
    final catalog = await RuntimeProjectCatalog.open(path);
    final pending = catalog.manifestForMap(
      const MapData(
        id: 'map',
        name: 'Map',
        size: GridSize(width: 1, height: 1),
        tilesetId: 'tile',
      ),
    );
    catalog.dispose();
    await expectLater(pending, throwsStateError);
  });

  test('every conditional entity presentation retains its character', () async {
    final root = await Directory.systemTemp.createTemp(
      'runtime-presentations-',
    );
    addTearDown(() => root.delete(recursive: true));
    final path = await _writeProject(
      root,
      const ProjectManifest(
        name: 'Variants',
        maps: [],
        tilesets: [
          ProjectTilesetEntry(
            id: 'sheet',
            name: 'Sheet',
            relativePath: 'sheet.png',
          ),
        ],
        characters: [
          ProjectCharacterEntry(
            id: 'before',
            name: 'Before',
            tilesetId: 'sheet',
          ),
          ProjectCharacterEntry(id: 'after', name: 'After', tilesetId: 'sheet'),
        ],
      ),
    );
    final catalog = await RuntimeProjectCatalog.open(path);
    addTearDown(catalog.dispose);
    final map = MapData(
      id: 'map',
      name: 'Map',
      size: const GridSize(width: 1, height: 1),
      entities: [
        MapEntity(
          id: 'event',
          kind: MapEntityKind.custom,
          pos: const GridPos(x: 0, y: 0),
          presentation: MapEntityPresentation(
            variants: [
              for (final id in ['before', 'after'])
                MapEntityPresentationVariant(
                  id: id,
                  characterId: id,
                  condition: NarrativeEventConditionExpression.all([]),
                  blocksMovement: false,
                ),
            ],
          ),
        ),
      ],
    );
    final view = await catalog.manifestForMap(map);
    expect(view.characters.map((value) => value.id).toSet(), {
      'before',
      'after',
    });
    expect(view.tilesets.single.id, 'sheet');
  });

  for (final partitioned in [false, true]) {
    test(
      'selected resource keeps map ownership, partitioned=$partitioned',
      () async {
        final root = await Directory.systemTemp.createTemp('runtime-scope-');
        addTearDown(() => root.delete(recursive: true));
        final project = ProjectManifest(
          name: 'Scoped',
          maps: const [
            ProjectMapEntry(id: 'a', name: 'A', relativePath: 'maps/a.json'),
          ],
          tilesets: const [
            ProjectTilesetEntry(
              id: 'tile',
              name: 'Tile',
              relativePath: 'tile.png',
            ),
          ],
          elements: const [
            ProjectElementEntry(
              id: 'decor',
              name: 'Decor',
              tilesetId: 'tile',
              categoryId: 'props',
              frames: [
                TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 0)),
              ],
            ),
          ],
          elementCategories: const [
            ProjectElementCategory(id: 'props', name: 'Props'),
          ],
          resourceLibraryCatalog: ResourceLibraryCatalog(
            families: [
              ResourceFamily(id: 'parent', name: 'Parent', parentId: 'props'),
              ResourceFamily(id: 'child', name: 'Child', parentId: 'parent'),
            ],
            entries: [
              ResourceLibraryEntry(
                resourceKind: 'element',
                resourceId: 'decor',
                familyId: 'child',
                mapId: 'a',
                placementContext: ResourcePlacementContext.interior,
              ),
            ],
          ),
        );
        final catalog = await RuntimeProjectCatalog.open(
          await _writeProject(root, project, partitioned: partitioned),
        );
        addTearDown(catalog.dispose);
        final view = await catalog.manifestForMap(
          const MapData(
            id: 'a',
            name: 'A',
            size: GridSize(width: 1, height: 1),
            placedElements: [
              MapPlacedElement(
                id: 'decor',
                elementId: 'decor',
                layerId: 'props',
                pos: GridPos(x: 0, y: 0),
              ),
            ],
          ),
        );
        final library = view.resourceLibraryCatalog;
        expect(library.availableForMap('element', 'decor', 'a'), isTrue);
        expect(library.availableForMap('element', 'decor', 'b'), isFalse);
        expect(library.families.map((family) => family.id).toSet(), {
          'parent',
          'child',
        });
        expect(
          library.entries.single.placementContext,
          ResourcePlacementContext.interior,
        );
      },
    );
  }
}

Future<String> _writeProject(
  Directory root,
  ProjectManifest project, {
  bool partitioned = true,
}) async {
  final file = File(p.join(root.path, 'project.json'));
  if (!partitioned) {
    await file.writeAsString(jsonEncode(project.toJson()));
    return file.path;
  }
  final publication = PortableCatalogPublication.encodeProject(project);
  await file.writeAsString(jsonEncode(publication.descriptor));
  for (final object in publication.storage.objects.entries) {
    final target = File(
      p.join(root.path, 'catalog/objects/${object.key}.json'),
    );
    await target.parent.create(recursive: true);
    await target.writeAsBytes(object.value);
  }
  return file.path;
}

ProjectManifest _projectionCacheProject() => const ProjectManifest(
  name: 'Projection cache',
  maps: [],
  tilesets: [
    ProjectTilesetEntry(id: 'tile', name: 'tile', relativePath: 'tile.png'),
    ProjectTilesetEntry(id: 'other', name: 'other', relativePath: 'other.png'),
    ProjectTilesetEntry(id: 'third', name: 'third', relativePath: 'third.png'),
  ],
  characters: [
    ProjectCharacterEntry(id: 'tile', name: 'Tile actor', tilesetId: 'other'),
  ],
);
