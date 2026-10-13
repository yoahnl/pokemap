import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_gameplay/src/collision/world_collision_storage.dart';
import 'package:test/test.dart';

import 'support/materialized_border_collision_fixture.dart';

void main() {
  test('canonical geometry retains exact layer feature placement ownership',
      () {
    final f = _fixture(segments: 2);
    final contacts = resolveMaterializedBorderCollisions(
            map: f.map,
            project: f.project,
            tileSize: const PixelSize(width: 32, height: 32))
        .toList();
    final placements = f.feature.materialization!.placements;
    expect(contacts.map((c) => c.owner).toSet(), {
      for (final p in placements)
        BorderCollisionOwner(
            layerId: 'borders', featureId: f.feature.id, placementId: p.id)
    });
    expect(
        contacts.map((c) => _rectValues(c.rect)).toList(),
        resolveMaterializedBorderCollisionRects(
                map: f.map,
                project: f.project,
                tileSize: const PixelSize(width: 32, height: 32))
            .map(_rectValues)
            .toList());
  });

  test('selected placement is excluded only inside intermediate cell', () {
    final f = _fixture();
    final p = f.feature.materialization!.placements.single;
    final world = _world(f);
    final rect = PixelRect(
        leftPx: p.topLeftWorldPx.x + 4,
        topPx: p.topLeftWorldPx.y + 48,
        widthPx: 1,
        heightPx: 1);
    final exclusion = _exclusion(f, rect);
    expect(world.worldStaticObstaclesCollidePixelRect(rect), isTrue);
    expect(
        world.worldStaticObstaclesCollidePixelRect(rect,
            borderExclusion: exclusion),
        isFalse);
    expect(world.worldStaticObstaclesCollidePixelRect(rect), isTrue);
    final outside = PixelRect(
        leftPx: rect.leftPx,
        topPx: exclusion.area.topPx - 1,
        widthPx: 1,
        heightPx: 1);
    expect(
        world.worldStaticObstaclesCollidePixelRect(outside,
            borderExclusion: exclusion),
        isTrue);
    expect(
        world.withPlayer(world.player).worldStaticObstaclesCollidePixelRect(
            rect,
            borderExclusion: exclusion),
        isFalse);
  });

  test(
      'several selected placements can be excluded without selecting entire feature',
      () {
    final f =
        _fixture(segments: 2, offset: const BorderPixelOffset(x: 32, y: 0));
    final ps = f.feature.materialization!.placements;
    final x = ps.last.topLeftWorldPx.x + 4;
    final y = ps.last.topLeftWorldPx.y + 48;
    final rect = PixelRect(leftPx: x, topPx: y, widthPx: 1, heightPx: 1);
    final world = _world(f);
    final area = _cell(rect);
    final first = BorderCollisionOwner(
        layerId: 'borders', featureId: f.feature.id, placementId: ps.first.id);
    final second = BorderCollisionOwner(
        layerId: 'borders', featureId: f.feature.id, placementId: ps.last.id);
    expect(
        world.worldStaticObstaclesCollidePixelRect(rect,
            borderExclusion:
                BorderCollisionExclusion(owners: {first}, area: area)),
        isTrue);
    expect(
        world.worldStaticObstaclesCollidePixelRect(rect,
            borderExclusion:
                BorderCollisionExclusion(owners: {first, second}, area: area)),
        isFalse);
  });

  test('different Border in same layer or another layer remains solid', () {
    final f = _fixture();
    final rect = _contact(f);
    for (final separateLayer in [false, true]) {
      final layer = f.map.layers.single as BorderLayer;
      final feature = separateLayer ? f.feature : _feature(f, 'other-feature');
      final map = f.map.copyWith(
          layers: separateLayer
              ? [
                  layer,
                  MapLayer.border(
                      id: 'other-layer',
                      name: 'Other',
                      content: BorderLayerContent(
                          formatVersion: 3, features: [feature]))
                ]
              : [
                  layer.copyWith(
                      content: BorderLayerContent(
                          formatVersion: 3, features: [f.feature, feature]))
                ]);
      expect(
          _world(f, map: map).worldStaticObstaclesCollidePixelRect(rect,
              borderExclusion: _exclusion(f, rect)),
          isTrue);
    }
  });

  test('tile placed cell and placed pixel collisions remain solid in same cell',
      () {
    final f = _fixture();
    final rect = _contact(f);
    final cell = GridPos(x: rect.leftPx ~/ 32, y: rect.topPx ~/ 32);
    final collisionLayer = MapLayer.collision(
        id: 'solid',
        name: 'Solid',
        collisions: List.generate(100, (i) => i == cell.y * 10 + cell.x));
    expect(
        _world(f,
                map: f.map.copyWith(layers: [...f.map.layers, collisionLayer]))
            .worldStaticObstaclesCollidePixelRect(rect,
                borderExclusion: _exclusion(f, rect)),
        isTrue);
    for (final mask in [false, true]) {
      final profile = mask
          ? ElementCollisionProfile(
              collisionMask: ElementCollisionPixelMask(
                  widthPx: 32,
                  heightPx: 32,
                  dataBase64: ElementCollisionMaskCodec.encodePackedBits(
                      widthPx: 32,
                      heightPx: 32,
                      solidPixels: List.filled(1024, true))))
          : const ElementCollisionProfile(cells: [GridPos(x: 0, y: 0)]);
      final element = ProjectElementEntry(
          id: 'object',
          name: 'Object',
          tilesetId: 'tiles',
          categoryId: 'objects',
          frames: const [
            TilesetVisualFrame(
                source: TilesetSourceRect(x: 0, y: 0, width: 1, height: 1))
          ],
          collisionProfile: profile);
      final map = f.map.copyWith(layers: [
        ...f.map.layers,
        const MapLayer.tile(id: 'objects', name: 'Objects', cells: [])
      ], placedElements: [
        MapPlacedElement(
            id: 'object-instance',
            layerId: 'objects',
            elementId: 'object',
            pos: cell)
      ]);
      expect(
          _world(f,
                  map: map,
                  project: f.project
                      .copyWith(elements: [...f.project.elements, element]))
              .worldStaticObstaclesCollidePixelRect(rect,
                  borderExclusion: _exclusion(f, rect)),
          isTrue);
    }
  });

  test('blocking entity and neighboring obstacle remain solid', () {
    final f = _fixture();
    final rect = _contact(f);
    final cell = GridPos(x: rect.leftPx ~/ 32, y: rect.topPx ~/ 32);
    final map = f.map.copyWith(entities: [
      MapEntity(id: 'blocker', kind: MapEntityKind.npc, pos: cell)
    ]);
    expect(
        _world(f, map: map).worldStaticObstaclesCollidePixelRect(rect,
            borderExclusion: _exclusion(f, rect)),
        isTrue);
    final wide = PixelRect(
        leftPx: cell.x * 32 + 30, topPx: rect.topPx, widthPx: 4, heightPx: 1);
    final neighbor = f.map.copyWith(layers: [
      ...f.map.layers,
      MapLayer.collision(
          id: 'neighbor',
          name: 'Neighbor',
          collisions: List.generate(100, (i) => i == cell.y * 10 + cell.x + 1))
    ]);
    expect(
        _world(f, map: neighbor).worldStaticObstaclesCollidePixelRect(wide,
            borderExclusion: _exclusion(f, rect)),
        isTrue);
  });

  test('exclusion is immutable closed to one Border and one map cell', () {
    final owner = const BorderCollisionOwner(
        layerId: 'borders', featureId: 'wall-feature', placementId: 'p');
    final owners = {owner};
    final exclusion = BorderCollisionExclusion(
        owners: owners,
        area:
            const PixelRect(leftPx: 64, topPx: 128, widthPx: 32, heightPx: 32));
    owners.clear();
    expect(exclusion.owners, {owner});
    expect(() => exclusion.owners.clear(), throwsUnsupportedError);
    expect(() => BorderCollisionExclusion(owners: {}, area: exclusion.area),
        throwsArgumentError);
    expect(
        () => BorderCollisionExclusion(owners: {
              owner,
              const BorderCollisionOwner(
                  layerId: 'borders', featureId: 'other', placementId: 'p')
            }, area: exclusion.area),
        throwsArgumentError);
    expect(
        () => BorderCollisionExclusion(owners: {
              const BorderCollisionOwner(
                  layerId: '', featureId: 'feature', placementId: 'p')
            }, area: exclusion.area),
        throwsArgumentError);
    final f = _fixture();
    final world = _world(f);
    for (final area in [
      const PixelRect(leftPx: 31, topPx: 0, widthPx: 2, heightPx: 1),
      const PixelRect(leftPx: -1, topPx: 0, widthPx: 1, heightPx: 1),
      const PixelRect(leftPx: 0, topPx: 0, widthPx: 0, heightPx: 1)
    ]) {
      expect(
          () => world.worldStaticObstaclesCollidePixelRect(_contact(f),
              borderExclusion:
                  BorderCollisionExclusion(owners: {_owner(f)}, area: area)),
          throwsArgumentError);
    }
  });

  test('unmatched owner does not erase canonical collision', () {
    final f = _fixture();
    final rect = _contact(f);
    final exclusion = BorderCollisionExclusion(owners: {
      const BorderCollisionOwner(
          layerId: 'borders', featureId: 'wall-feature', placementId: 'missing')
    }, area: _cell(rect));
    expect(
        _world(f).worldStaticObstaclesCollidePixelRect(rect,
            borderExclusion: exclusion),
        isTrue);
  });

  test('ownership never bypasses unsupported terrain or dynamic occupancy', () {
    const owner = BorderCollisionOwner(
        layerId: 'borders', featureId: 'wall', placementId: 'panel');
    const rect = PixelRect(leftPx: 36, topPx: 36, widthPx: 1, heightPx: 1);
    final exclusion = BorderCollisionExclusion(owners: {
      owner
    }, area: const PixelRect(leftPx: 32, topPx: 32, widthPx: 32, heightPx: 32));
    WorldCollisionStorageBuilder builder({bool supported = false}) =>
        WorldCollisionStorageBuilder(
            widthCells: 3,
            heightCells: 3,
            tileWidthPx: 32,
            tileHeightPx: 32,
            tileCollisionCells: List.filled(9, false),
            placedElementCollisionCells: List.filled(9, false),
            supportableTerrainCellsByLayer: {
              'terrain': List.generate(9, (i) => i == 4)
            },
            supportRectsByLayer: {
              'terrain': supported ? [exclusion.area] : []
            });
    final unsupportedBuilder = builder()
      ..stampBorderRect(
          const MaterializedBorderCollisionRect(owner: owner, rect: rect));
    final unsupported = unsupportedBuilder.build();
    expect(
        unsupported.collidesPixelRect(rect,
            isDynamicCellBlocked: (_) => false, borderExclusion: exclusion),
        isTrue);
    final supportedBuilder = builder(supported: true)
      ..stampBorderRect(
          const MaterializedBorderCollisionRect(owner: owner, rect: rect));
    final supported = supportedBuilder.build();
    expect(
        supported.collidesPixelRect(rect,
            isDynamicCellBlocked: (_) => false, borderExclusion: exclusion),
        isFalse);
    expect(
        supported.collidesPixelRect(rect,
            isDynamicCellBlocked: (i) => i == 4, borderExclusion: exclusion),
        isTrue);
    supportedBuilder.stampRect(rect);
    expect(
        supported.collidesPixelRect(rect,
            isDynamicCellBlocked: (_) => false, borderExclusion: exclusion),
        isFalse);
    expect(
        supportedBuilder.build().collidesPixelRect(rect,
            isDynamicCellBlocked: (_) => false, borderExclusion: exclusion),
        isTrue);
  });

  test('dense overlapping ownership allocates one aggregate per touched chunk',
      () {
    final builder = WorldCollisionStorageBuilder(
        widthCells: 2,
        heightCells: 2,
        tileWidthPx: 32,
        tileHeightPx: 32,
        tileCollisionCells: List.filled(4, false),
        placedElementCollisionCells: List.filled(4, false));
    final owners = {
      for (var i = 0; i < 1024; i++)
        BorderCollisionOwner(
            layerId: 'borders', featureId: 'wall', placementId: 'panel-$i')
    };
    const solid = PixelRect(leftPx: 1, topPx: 1, widthPx: 1, heightPx: 1);
    const free = PixelRect(leftPx: 16, topPx: 16, widthPx: 12, heightPx: 8);
    for (final owner in owners) {
      builder.stampBorderRect(
          MaterializedBorderCollisionRect(owner: owner, rect: solid));
    }
    final storage = builder.build();
    expect(storage.allocatedPixelMaskChunkCount, 1025);
    expect(storage.allocatedPixelMaskWordCount, 1025 * 32);
    expect(storage.collidesPixelRect(free, isDynamicCellBlocked: (_) => false),
        isFalse);
    expect(storage.collidesPixelRect(solid, isDynamicCellBlocked: (_) => false),
        isTrue);
    const area = PixelRect(leftPx: 0, topPx: 0, widthPx: 32, heightPx: 32);
    expect(
        storage.collidesPixelRect(solid,
            isDynamicCellBlocked: (_) => false,
            borderExclusion:
                BorderCollisionExclusion(owners: {owners.first}, area: area)),
        isTrue);
    expect(
        storage.collidesPixelRect(solid,
            isDynamicCellBlocked: (_) => false,
            borderExclusion:
                BorderCollisionExclusion(owners: owners, area: area)),
        isFalse);
    builder.stampBorderRect(
        MaterializedBorderCollisionRect(owner: owners.first, rect: free));
    expect(storage.collidesPixelRect(free, isDynamicCellBlocked: (_) => false),
        isFalse);
    expect(
        builder
            .build()
            .collidesPixelRect(free, isDynamicCellBlocked: (_) => false),
        isTrue);
  });

  test('missing stale malformed source still refuses before ownership mount',
      () {
    final f = _fixture();
    expect(
        () => GameplayWorldState.initial(
            map: f.map,
            playerPos: const GridPos(x: 0, y: 0),
            tileWidth: 32,
            tileHeight: 32),
        throwsA(isA<ValidationException>()));
    expect(() => _world(f, project: f.project.copyWith(elements: const [])),
        throwsA(isA<ValidationException>()));
    final stale = decodeBorderFeatureJson(
        {...encodeBorderFeatureJson(f.feature, formatVersion: 3), 'seed': '1'},
        formatVersion: 3);
    expect(() => _world(f, map: f.withFeature(stale)),
        throwsA(isA<ValidationException>()));
    final malformed = f.project.elements.single.copyWith(
        collisionProfile: const ElementCollisionProfile(
            collisionMask: ElementCollisionPixelMask(
                widthPx: 32, heightPx: 64, dataBase64: 'AA==')));
    expect(() => _world(f, project: f.project.copyWith(elements: [malformed])),
        throwsFormatException);
  });
}

MaterializedBorderCollisionFixture _fixture(
        {int segments = 1,
        BorderPixelOffset offset = const BorderPixelOffset(x: 0, y: 0)}) =>
    MaterializedBorderCollisionFixture(
        profile: const ElementCollisionProfile(
            cells: [GridPos(x: 0, y: 0), GridPos(x: 0, y: 1)]),
        segments: segments,
        offset: offset);
GameplayWorldState _world(MaterializedBorderCollisionFixture f,
        {MapData? map, ProjectManifest? project}) =>
    GameplayWorldState.initial(
        map: map ?? f.map,
        project: project ?? f.project,
        playerPos: const GridPos(x: 0, y: 0),
        tileWidth: 32,
        tileHeight: 32);
PixelRect _contact(MaterializedBorderCollisionFixture f) {
  final p = f.feature.materialization!.placements.first;
  return PixelRect(
      leftPx: p.topLeftWorldPx.x + 4,
      topPx: p.topLeftWorldPx.y + 48,
      widthPx: 1,
      heightPx: 1);
}

PixelRect _cell(PixelRect rect) => PixelRect(
    leftPx: rect.leftPx ~/ 32 * 32,
    topPx: rect.topPx ~/ 32 * 32,
    widthPx: 32,
    heightPx: 32);
BorderCollisionOwner _owner(MaterializedBorderCollisionFixture f) =>
    BorderCollisionOwner(
        layerId: 'borders',
        featureId: f.feature.id,
        placementId: f.feature.materialization!.placements.first.id);
BorderCollisionExclusion _exclusion(
        MaterializedBorderCollisionFixture f, PixelRect rect) =>
    BorderCollisionExclusion(owners: {_owner(f)}, area: _cell(rect));
BorderFeature _feature(MaterializedBorderCollisionFixture f, String id) {
  final value = decodeBorderFeatureJson({
    ...encodeBorderFeatureJson(f.feature, formatVersion: 3),
    'id': id,
    'materialization': null
  }, formatVersion: 3);
  final request = BorderResolutionRequest(
      mapSize: f.map.size,
      tileSizePx: const GridSize(width: 32, height: 32),
      blueprintId: value.blueprintId,
      blueprintRevision: f.revision,
      feature: value,
      visualSnapshots: f.project.borderCatalog.visualSnapshots,
      resolverVersion: borderResolverVersion);
  final output = resolveBorderFeature(request);
  expect(output.canApply, isTrue);
  return BorderFeature(
      id: value.id,
      name: value.name,
      blueprintId: value.blueprintId,
      seed: value.seed,
      geometry: value.geometry,
      lineSide: value.lineSide,
      paramsOverride: value.paramsOverride,
      overrides: value.overrides,
      keepOutRegions: value.keepOutRegions,
      materialization: output.materialization);
}

(int, int, int, int) _rectValues(PixelRect rect) =>
    (rect.leftPx, rect.topPx, rect.widthPx, rect.heightPx);
