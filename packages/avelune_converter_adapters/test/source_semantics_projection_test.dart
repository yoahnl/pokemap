import 'dart:typed_data';

import 'package:avelune_converter_adapters/src/source_semantics_projection.dart';
import 'package:avelune_converter_adapters/src/native_project_writer.dart';
import 'package:avelune_converter_adapters/src/literal_tile_composer.dart';
import 'package:avelune_converter_adapters/src/source_player_character_import.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:image/image.dart' as image;
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

import 'support/literal_tile_fixture.dart';

void main() {
  for (final priority in [1, 2]) {
    test('split image budget bounds each occlusion image before allocation priority $priority', () async {
      final fixture = await LiteralTileFixture.create(maps: [
        LiteralFixtureMap(id: 1, width: 5, height: 5, layers: [
          List.filled(25, 391),
          [for (var index = 0; index < 25; index++) index == 12 ? 384 : 0],
          List.filled(25, 0),
        ]),
      ], tilesets: [LiteralFixtureTileset(id: 1, priorities: {384: priority})]);
      final base = await const LiteralTileComposer().compose(source: fixture.source, files: fixture.files,
        selectedSourceMapIds: [1], projectName: 'Bounded occlusion', parentPath: '/private/tmp', folderName: 'bounded-occlusion');
      final future = const SourceSemanticsProjector().project(source: fixture.source, base: base,
        player: _playerForFixture(fixture), files: fixture.files,
        limits: const NativeWriteLimits(maxImagePixels: 16384, maxTotalImagePixels: 50000));
      if (priority == 1) {
        expect((await future).artifacts, isNotEmpty);
      } else {
        await expectLater(future, throwsA(isA<NativeWriteException>().having(
          (error) => error.code, 'code', 'semantics.quota.pixels')));
      }
    });
  }


  group('Source occlusion layout', () {
    test('preserves exact tall-player depth and original pixel position', () {
      final layout = SourceOcclusionLayout.resolve(
        priority: 1,
        sourcePlayerDepthOffsetPx: 32,
        x: 2,
        y: 3,
        mapSize: const GridSize(width: 10, height: 10),
      );
      expect(layout.topPaddingPx, 31);
      expect(layout.bottomPaddingPx, 1);
      expect(layout.frameHeightTiles, 2);
      expect(layout.logicalPos, const GridPos(x: 2, y: 3));
      expect(layout.atlasOffsetY, -31);
      expect(layout.visualTopPx + layout.topPaddingPx, 3 * 32);
      expect(layout.depthSortYPx, (3 + 1 + 1) * 32 + 1 - 32);
    });

    test('keeps exact priority-two padding and moves logical bottom in bounds',
        () {
      final layout = SourceOcclusionLayout.resolve(
        priority: 2,
        sourcePlayerDepthOffsetPx: 32,
        x: 0,
        y: 9,
        mapSize: const GridSize(width: 10, height: 10),
      );
      expect(layout.logicalPos.y, 7);
      expect(layout.atlasOffsetY, 33);
      expect(layout.bottomPaddingPx, 33);
      expect(layout.visualTopPx + layout.topPaddingPx, 9 * 32);
      expect(layout.depthSortYPx, 12 * 32 - 31);
    });

    test('normal player offset preserves the source player tie bonus', () {
      final layout = SourceOcclusionLayout.resolve(
        priority: 1,
        sourcePlayerDepthOffsetPx: 1,
        x: 0,
        y: 0,
        mapSize: const GridSize(width: 2, height: 2),
      );
      expect(layout.topPaddingPx, 0);
      expect(layout.bottomPaddingPx, 32);
      expect(layout.depthSortYPx, 64);
    });

    test('rejects frames that cannot fit and unqualified depth offsets', () {
      expect(
        () => SourceOcclusionLayout.resolve(
          priority: 2,
          sourcePlayerDepthOffsetPx: 32,
          x: 0,
          y: 0,
          mapSize: const GridSize(width: 1, height: 1),
        ),
        throwsA(isA<Exception>()),
      );
      expect(
        () => SourceOcclusionLayout.resolve(
          priority: 1,
          sourcePlayerDepthOffsetPx: 31,
          x: 0,
          y: 0,
          mapSize: const GridSize(width: 2, height: 2),
        ),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('Source collision projection', () {
    test('owns a horizontal wall on the south side of the blocked arc', () {
      final cells = _cells({1: 1});
      final result = SourceCollisionProjection.resolve(
        cells: cells,
        resolver: _resolver(),
        mapSize: const GridSize(width: 3, height: 3),
      );
      expect(result.wallMasksByCell[4], SourceCardinalDirection.up.bit);
      expect(result.wallMasksByCell[1], isNull);
      expect(result.fullyBlockedCells[1], isFalse);
      expect(result.qualified, isTrue);
      final mask = sourceBoundaryCollisionMask(result.wallMasksByCell[4]!);
      final decoded = ElementCollisionMaskCodec.decodePackedBits(
          widthPx: 32, heightPx: 32, dataBase64: mask.dataBase64);
      expect(decoded.take(32).every((pixel) => pixel), isTrue);
      expect(decoded.skip(32).every((pixel) => !pixel), isTrue);
    });

    test('fully blocked graph cells do not impose walls on their neighbors',
        () {
      final result = SourceCollisionProjection.resolve(
        cells: _cells({4: 15}),
        resolver: _resolver(),
        mapSize: const GridSize(width: 3, height: 3),
      );
      expect(result.fullyBlockedCells[4], isTrue);
      expect(result.wallMasksByCell, isEmpty);
      expect(
          result.fullyBlockedCells.where((blocked) => blocked), hasLength(1));
    });

    test('isolated source-allowed cells keep their arrival space', () {
      final cells = _cells({1: 1, 3: 4, 5: 2, 7: 8});
      final resolver = _resolver();
      final result = SourceCollisionProjection.resolve(
        cells: cells,
        resolver: resolver,
        mapSize: const GridSize(width: 3, height: 3),
      );
      expect(resolver.resolveConnectionEntryTile(cells[4]).isPassable, isTrue);
      expect(result.allowedTransitions[4], 0);
      expect(result.fullyBlockedCells[4], isFalse);
      expect(result.wallMasksByCell[4], 10);
      expect(result.wallMasksByCell[5], 2);
      expect(result.wallMasksByCell[7], 8);
      expect(result.qualified, isTrue);
    });

    test('source d0 border admission survives four blocked cardinal arcs', () {
      final cells = _cells({3: 8, 4: 15, 6: 15}, terrainTags: {3: 17});
      final resolver = _resolver();
      final result = SourceCollisionProjection.resolve(
        cells: cells,
        resolver: resolver,
        mapSize: const GridSize(width: 3, height: 3),
      );
      expect(resolver.resolveConnectionEntryTile(cells[3]).isPassable, isTrue);
      expect(result.allowedTransitions[3], 0);
      expect(result.fullyBlockedCells[3], isFalse);
      expect(result.fullyBlockedCells[4], isTrue);
      expect(result.fullyBlockedCells[6], isTrue);
      expect(result.wallMasksByCell[3], SourceCardinalDirection.up.bit);
      expect(result.qualified, isTrue);
    });

    test(
        'native feet fit an isolated arrival while all four steps stay blocked',
        () {
      const size = GridSize(width: 3, height: 3);
      for (final (cells, arrival) in [
        (_cells({1: 1, 3: 4, 5: 2, 7: 8}), const GridPos(x: 1, y: 1)),
        (
          _cells({3: 8, 4: 15, 6: 15}, terrainTags: {3: 17}),
          const GridPos(x: 0, y: 1)
        ),
      ]) {
        final collision = SourceCollisionProjection.resolve(
          cells: cells,
          resolver: _resolver(),
          mapSize: size,
        );
        final world = _collisionWorld(collision, size, arrival);
        expect(world.worldStaticObstaclesCollidePlayerCollisionRect(), isFalse);
        for (final direction in Direction.values) {
          final step = stepGameplayWorld(
              world, MoveIntent(direction, pixelsPerStep: 32));
          expect(step, isA<Blocked>(), reason: '$arrival $direction');
          expect(step.world.player.playerPositionPx,
              world.player.playerPositionPx);
        }
      }
    });

    test('unknown metadata remains unqualified and cannot become an open arc',
        () {
      final cells = _cells({});
      cells[4] = SourceSemanticCell(
          sourceMapId: 1,
          x: 1,
          y: 1,
          width: 3,
          height: 3,
          stack: const [
            SourceSemanticTile(sourceZ: 2, tileId: 0),
            SourceSemanticTile(sourceZ: 1, tileId: 0),
            SourceSemanticTile(sourceZ: 0, tileId: 384),
          ]);
      final result = SourceCollisionProjection.resolve(
        cells: cells,
        resolver: _resolver(),
        mapSize: const GridSize(width: 3, height: 3),
      );
      expect(result.qualified, isFalse);
      expect(result.unqualifiedTransitionCount, greaterThan(0));
      expect(result.allowedTransitions[4], 0);
      expect(result.wallMasksByCell, isNotEmpty);
    });
  });

  test('preview start selects the largest component with safe ground', () {
    const size = GridSize(width: 7, height: 4);
    final resolver = _resolver();
    final cells = _cells(
      {for (var y = 0; y < 4; y++) y * 7 + 4: 15},
      width: 7,
      height: 4,
      terrainTags: {
        for (var y = 0; y < 4; y++)
          for (var x = 0; x < 4; x++) y * 7 + x: 4
      },
    );
    final collision = SourceCollisionProjection.resolve(
        cells: cells, resolver: resolver, mapSize: size);
    final spawn = sourcePreviewSpawn(
        mapSize: size,
        cells: cells,
        collision: collision,
        resolver: resolver,
        playerFrameHeightPx: 48,
        eventCells: {},
        raisedCells: {});
    expect(spawn, (const GridPos(x: 5, y: 1), 8));
    final constrained = sourcePreviewSpawn(
        mapSize: size,
        cells: cells,
        collision: collision,
        resolver: resolver,
        playerFrameHeightPx: 48,
        eventCells: {12},
        raisedCells: {19});
    expect(constrained, (const GridPos(x: 6, y: 1), 8));
  });

  test(
      'source-bound projection preserves alpha, removes original, and is deterministic',
      () async {
    final fixture = await LiteralTileFixture.create(maps: [
      LiteralFixtureMap(id: 1, width: 3, height: 3, layers: [
        List.filled(9, 391),
        [0, 0, 0, 0, 384, 0, 0, 0, 0],
        List.filled(9, 0),
      ]),
    ], tilesets: [
      LiteralFixtureTileset(id: 1, priorities: {384: 1})
    ]);
    final base = await const LiteralTileComposer().compose(
      source: fixture.source,
      files: fixture.files,
      selectedSourceMapIds: [1],
      projectName: 'Semantic projection fixture',
      parentPath: '/private/tmp',
      folderName: 'semantic-projection-fixture',
    );
    final imported = _playerForFixture(fixture);
    Future<SourceSemanticsProjection> project() =>
        const SourceSemanticsProjector().project(
            source: fixture.source,
            base: base,
            player: imported,
            files: fixture.files);
    final result = await project();
    final native = result.nativeMaps[1]!;
    expect(() => MapValidator.validate(native), returnsNormally);
    final layerId = base.layerProvenance
        .singleWhere((entry) => entry.sourceZ == 1)
        .nativeLayerId;
    expect(
        (native.layers.singleWhere((entry) => entry.id == layerId) as TileLayer)
            .cells[4],
        0);
    final placed = native.placedElements
        .singleWhere((entry) => entry.id.startsWith('ac12-occ-'));
    final definition = ProjectElementEntry.fromJson(Map<String, dynamic>.from(
        result
            .mutations
            .singleWhere((mutation) =>
                mutation.actionId == 'element.upsert' &&
                mutation.parameters['element'] is Map &&
                (mutation.parameters['element'] as Map)['id'] ==
                    placed.elementId)
            .parameters['element'] as Map));
    final frame = definition.frames.single;
    final imageImport = result.mutations.singleWhere((mutation) =>
        mutation.actionId == 'tileset.import_image' &&
        mutation.parameters['tilesetId'] == frame.tilesetId);
    final artifact = result.artifacts.singleWhere(
        (entry) => entry.handle == imageImport.parameters['artifactHandle']);
    final raster = image.decodePng(Uint8List.fromList(artifact.bytes))!;
    final pixel =
        raster.getPixel(frame.source.x * 32 + 1, frame.source.y * 32 + 31);
    expect([pixel.r, pixel.g, pixel.b, pixel.a], [17, 29, 43, 127]);
    expect(raster.getPixel(frame.source.x * 32 + 1, frame.source.y * 32).a, 0);
    expect(result.playableCertified, isFalse);
    expect(result.staticSemanticsQualified, isFalse);
    expect(result.semanticEvidence['sourceScriptsExecuted'], 0);
    expect(result.semanticEvidence['aiCalls'], 0);
    final again = await project();
    expect(canonicalHashOf(result.semanticEvidence),
        canonicalHashOf(again.semanticEvidence));
    expect(result.artifacts.map((entry) => entry.rawSha256),
        again.artifacts.map((entry) => entry.rawSha256));
    expect(result.nativeMaps[1]!.toJson(), again.nativeMaps[1]!.toJson());
  });

  test(
      'boundary instances use empty tile layers accepted by native map validation',
      () async {
    final known = SourceCollisionProjection.resolve(
        cells: _cells({4: 8}),
        resolver: _resolver(),
        mapSize: const GridSize(width: 3, height: 3));
    expect(known.qualified, isTrue);
    expect(known.fullyBlockedCells[4], isFalse);
    expect(known.wallMasksByCell[4], SourceCardinalDirection.up.bit);
    final fixture = await LiteralTileFixture.create(maps: [
      LiteralFixtureMap(id: 1, width: 3, height: 3, layers: [
        [391, 391, 391, 391, 384, 391, 391, 391, 391],
        List.filled(9, 0),
        List.filled(9, 0),
      ]),
    ], tilesets: [
      LiteralFixtureTileset(id: 1, passages: {384: 8})
    ]);
    final base = await const LiteralTileComposer().compose(
        source: fixture.source,
        files: fixture.files,
        selectedSourceMapIds: [1],
        projectName: 'Boundary projection fixture',
        parentPath: '/private/tmp',
        folderName: 'boundary-projection-fixture');
    final result = await const SourceSemanticsProjector().project(
        source: fixture.source,
        base: base,
        player: _playerForFixture(fixture),
        files: fixture.files);
    final native = result.nativeMaps[1]!;
    final boundaryInstances = native.placedElements
        .where((entry) => entry.id.startsWith('ac12-wall-'))
        .toList();
    expect(boundaryInstances, isNotEmpty);
    for (final instance in boundaryInstances) {
      final layer =
          native.layers.singleWhere((entry) => entry.id == instance.layerId);
      expect(layer, isA<TileLayer>());
      final tileLayer = layer as TileLayer;
      expect(tileLayer.cells, List.filled(9, 0));
      expect(tileLayer.palette, isEmpty);
    }
    expect(() => MapValidator.validate(native), returnsNormally);
    expect(result.staticSemanticsQualified, isFalse);
  });

  test('equal tile numbers keep their own tileset priority and pixels', () async {
    final fixture = await LiteralTileFixture.create(maps: [
      for (final id in [1, 2])
        LiteralFixtureMap(id: id, tilesetId: id, width: 3, height: 3, layers: [
          List.filled(9, 391),
          [0, 0, 0, 0, 384, 0, 0, 0, 0],
          List.filled(9, 0),
        ]),
    ], tilesets: [
      LiteralFixtureTileset(id: 1, priorities: {384: 1}),
      LiteralFixtureTileset(id: 2, priorities: {384: 2},
          png: literalFixtureAtlas(alternate: true)),
    ]);
    final base = await const LiteralTileComposer().compose(
        source: fixture.source, files: fixture.files,
        selectedSourceMapIds: [1, 2], projectName: 'Independent crop identities',
        parentPath: '/private/tmp', folderName: 'independent-crops');
    final result = await const SourceSemanticsProjector().project(
        source: fixture.source, base: base,
        player: _playerForFixture(fixture), files: fixture.files);
    final ids = <String>{};
    for (final (id, expectedHeight, expectedRed) in [(1, 64, 201), (2, 96, 101)]) {
      final placed = result.nativeMaps[id]!.placedElements
          .singleWhere((entry) => entry.id.startsWith('ac12-occ-'));
      ids.add(placed.elementId);
      final element = ProjectElementEntry.fromJson(Map<String, dynamic>.from(
          result.mutations.singleWhere((mutation) =>
              mutation.actionId == 'element.upsert' &&
              (mutation.parameters['element'] as Map)['id'] == placed.elementId)
              .parameters['element'] as Map));
      expect(element.collisionProfile!.occlusionMask!.heightPx, expectedHeight);
      final frame = element.frames.single;
      final mutation = result.mutations.singleWhere((entry) =>
          entry.actionId == 'tileset.import_image' &&
          entry.parameters['tilesetId'] == frame.tilesetId);
      final artifact = result.artifacts.singleWhere((entry) =>
          entry.handle == mutation.parameters['artifactHandle']);
      final raster = image.decodePng(Uint8List.fromList(artifact.bytes))!;
      final pixel = raster.getPixel(frame.source.x * 32 + 16,
          frame.source.y * 32 + 31 + 16);
      expect(pixel.r.toInt(), expectedRed);
    }
    expect(ids, hasLength(2));
  });

  test(
      'reflective tags retain positive-priority pixels below actors and expose a gap',
      () async {
    final fixture = await LiteralTileFixture.create(maps: [
      for (final id in [1, 2])
        LiteralFixtureMap(id: id, tilesetId: id, width: 3, height: 3, layers: [
          List.filled(9, 391),
          [0, 0, 0, 0, 384, 0, 0, 0, 0],
          List.filled(9, 0),
        ]),
    ], tilesets: [
      LiteralFixtureTileset(id: 1, priorities: {384: 1}, terrainTags: {384: 6}),
      LiteralFixtureTileset(
          id: 2, priorities: {384: 1}, terrainTags: {384: 16}),
    ]);
    final base = await const LiteralTileComposer().compose(
        source: fixture.source,
        files: fixture.files,
        selectedSourceMapIds: [1, 2],
        projectName: 'Reflection projection fixture',
        parentPath: '/private/tmp',
        folderName: 'reflection-projection-fixture');
    final result = await const SourceSemanticsProjector().project(
        source: fixture.source,
        base: base,
        player: _playerForFixture(fixture),
        files: fixture.files);
    for (final id in [1, 2]) {
      final layerId = base.layerProvenance
          .singleWhere((entry) => entry.sourceMapId == id && entry.sourceZ == 1)
          .nativeLayerId;
      final original = base.nativeMaps[id]!.layers
          .singleWhere((layer) => layer.id == layerId) as TileLayer;
      final projected = result.nativeMaps[id]!.layers
          .singleWhere((layer) => layer.id == layerId) as TileLayer;
      expect(original.cells[4], greaterThan(0));
      expect(projected.cells[4], original.cells[4]);
      expect(
          result.nativeMaps[id]!.placedElements
              .where((entry) => entry.id.startsWith('ac12-occ-')),
          isEmpty);
    }
    final gaps = (result.semanticEvidence['gaps'] as List)
        .where((entry) =>
            (entry as Map)['code'] ==
            'semantics.render.reflections.unqualified')
        .toList();
    expect(gaps, hasLength(2));
    expect(
        gaps.every((entry) =>
            (entry as Map)['sourceDepthZ'] == -100 &&
            entry['sourceTileCount'] == 1),
        isTrue);
    expect(
        result.mutations.where((entry) =>
            entry.actionId == 'tileset.import_image' &&
            (entry.parameters['tilesetId'] as String)
                .startsWith('ac12-occlusion-')),
        isEmpty);
    expect(result.staticSemanticsQualified, isFalse);
    expect(result.playableCertified, isFalse);
  });
}

SourcePlayerCharacterImport _playerForFixture(LiteralTileFixture fixture) {
  final entries = fixture.snapshot.entries;
  return SourcePlayerCharacterImport(
    sourceSnapshotHash: fixture.snapshot.canonicalHash,
    metadataFile: entries
        .firstWhere((entry) => entry.relativePath == 'Data/MapInfos.rxdata'),
    imageFile: entries.firstWhere(
        (entry) => entry.relativePath.startsWith('Graphics/Tilesets/')),
    imageBytes: literalFixtureAtlas(),
    outputBytes: literalFixtureAtlas(),
    selectedHeaderId: 1,
    charsetName: 'Synthetic fixed tall preview',
    sheetWidth: 128,
    sheetHeight: 192,
    frameWidthPx: 32,
    frameHeightPx: 48,
    assetId: 'preview-player',
    tilesetId: 'preview-player',
    character: const ProjectCharacterEntry(
        id: 'preview-player', name: 'Preview', tilesetId: 'preview-player'),
  );
}

SourceSemanticResolver _resolver() => SourceSemanticResolver(
      profile: SourceSemanticProfile.kantoPlayerWalk(
        scriptsArchiveHash:
            Sha256Hash(SourceSemanticProfile.kantoScriptsArchiveSha256),
        sourceSnapshotHash: Sha256Hash(List.filled(64, 'a').join()),
        sourceSelectionHash: Sha256Hash(List.filled(64, 'b').join()),
      ),
    );

GameplayWorldState _collisionWorld(
    SourceCollisionProjection collision, GridSize size, GridPos arrival) {
  final map = MapData(
      id: 'source-arrival',
      name: 'Source arrival',
      size: size,
      layers: [
        MapLayer.collision(
            id: 'collision',
            name: 'Source passages',
            collisions: collision.fullyBlockedCells),
        MapLayer.tile(
            id: 'boundaries',
            name: 'Source boundaries',
            cells: List.filled(size.width * size.height, 0)),
      ],
      placedElements: [
        for (final wall in collision.wallMasksByCell.entries)
          MapPlacedElement(
              id: 'wall-${wall.key}',
              layerId: 'boundaries',
              elementId: 'wall-${wall.value}',
              pos:
                  GridPos(x: wall.key % size.width, y: wall.key ~/ size.width)),
      ]);
  final manifest = ProjectManifest(
      name: 'Source arrival',
      maps: const [],
      tilesets: const [],
      settings: const ProjectSettings(tileWidth: 32, tileHeight: 32),
      elements: [
        for (final mask in collision.wallMasksByCell.values.toSet())
          ProjectElementEntry(
              id: 'wall-$mask',
              name: 'Source boundary',
              tilesetId: 'boundaries',
              categoryId: 'source',
              frames: const [
                TilesetVisualFrame(
                    source: TilesetSourceRect(x: 0, y: 0, width: 1, height: 1)),
              ],
              collisionProfile: ElementCollisionProfile(
                  collisionMask: sourceBoundaryCollisionMask(mask))),
      ]);
  return GameplayWorldState.initial(
      map: map,
      playerPos: arrival,
      project: manifest,
      tileWidth: 32,
      tileHeight: 32);
}

List<SourceSemanticCell> _cells(Map<int, int> passages,
        {int width = 3,
        int height = 3,
        Map<int, int> terrainTags = const {}}) =>
    [
      for (var index = 0; index < width * height; index++)
        SourceSemanticCell(
            sourceMapId: 1,
            x: index % width,
            y: index ~/ width,
            width: width,
            height: height,
            stack: [
              const SourceSemanticTile(sourceZ: 2, tileId: 0),
              const SourceSemanticTile(sourceZ: 1, tileId: 0),
              SourceSemanticTile(
                  sourceZ: 0,
                  tileId: 384,
                  passage: passages[index] ?? 0,
                  priority: 0,
                  terrainTag: terrainTags[index] ?? 0),
            ]),
    ];
