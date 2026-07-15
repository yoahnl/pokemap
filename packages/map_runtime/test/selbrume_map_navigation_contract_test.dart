import 'dart:collection';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';

import 'support/selbrume_map_test_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('port navigation connects local anchors and blocks the boat basin',
      () async {
    final portBundle = await loadRuntimeMapBundle(
      projectFilePath: SelbrumeMapTestFixture.projectFilePath,
      mapId: 'map_port_brisants',
    );
    final bourgBundle = await loadRuntimeMapBundle(
      projectFilePath: SelbrumeMapTestFixture.projectFilePath,
      mapId: 'map_bourg_selbrume',
    );
    final port = portBundle.map;
    final bourg = bourgBundle.map;
    final portWorld = GameplayWorldState.initial(
      map: port,
      playerPos: const GridPos(x: 28, y: 0),
      playerMovementMode: MovementMode.walk,
      project: portBundle.manifest,
      tileWidth: portBundle.manifest.settings.tileWidth,
      tileHeight: portBundle.manifest.settings.tileHeight,
      npcMapPresencePredicate: (_, __) => false,
    );
    final bourgWorld = GameplayWorldState.initial(
      map: bourg,
      playerPos: const GridPos(x: 28, y: 54),
      playerMovementMode: MovementMode.walk,
      project: bourgBundle.manifest,
      tileWidth: bourgBundle.manifest.settings.tileWidth,
      tileHeight: bourgBundle.manifest.settings.tileHeight,
      npcMapPresencePredicate: (_, __) => false,
    );

    final north = port.connections.where(
      (connection) =>
          connection.direction == MapConnectionDirection.north &&
          connection.targetMapId == bourg.id &&
          connection.offset == 0,
    );
    expect(north, hasLength(1));
    expect(
      bourg.connections.where(
        (connection) =>
            connection.direction == MapConnectionDirection.south &&
            connection.targetMapId == port.id &&
            connection.offset == 0,
      ),
      hasLength(1),
    );
    expect(
      _hasAlignedPassableConnectionPair(
        sourceMap: port,
        sourceWorld: portWorld,
        targetMap: bourg,
        targetWorld: bourgWorld,
        connection: north.single,
      ),
      isTrue,
    );
    for (var x = 26; x <= 30; x += 1) {
      expect(
        portWorld.isBlocked(x, 0, movementMode: MovementMode.walk),
        isFalse,
        reason: 'north corridor ($x,0)',
      );
    }

    final entry = port.gameplayZones.singleWhere(
      (zone) => zone.id == 'zone_port_entry',
    );
    final center = port.gameplayZones.singleWhere(
      (zone) => zone.id == 'zone_port_center',
    );
    expect(_passableZoneCells(entry, port, portWorld), isNotEmpty);
    expect(_passableZoneCells(center, port, portWorld), isNotEmpty);
    final nest = port.placedElements.singleWhere(
      (placed) => placed.id == 'pe_port_nid_goelise',
    );
    final soline = port.entities.singleWhere(
      (entity) => entity.id == 'anchor_port_soline',
    );
    final lysa = port.entities.singleWhere(
      (entity) => entity.id == 'anchor_port_lysa',
    );
    final reached = _reachableCells(
      map: port,
      world: portWorld,
      starts: const <GridPos>[GridPos(x: 28, y: 0)],
    );
    for (final target in <GridPos>[
      const GridPos(x: 28, y: 1),
      lysa.pos,
      nest.pos,
      soline.pos,
    ]) {
      expect(
        portWorld.isBlocked(
          target.x,
          target.y,
          movementMode: MovementMode.walk,
        ),
        isFalse,
        reason: 'local Port anchor $target',
      );
      expect(
        reached,
        contains(_cellIndex(port, target)),
        reason: 'local Port anchor $target must reach Bourg corridor',
      );
    }

    final boat = port.placedElements.singleWhere(
      (placed) => placed.id == 'pe_port_bateau',
    );
    expect(boat.pos, const GridPos(x: 0, y: 21));
    final boatElement = portBundle.manifest.elements.singleWhere(
      (element) => element.id == boat.elementId,
    );
    final boatSource = boatElement.frames.primarySource;
    expect(
      boatSource,
      const TilesetSourceRect(x: 26, y: 6, width: 10, height: 5),
    );
    for (var y = boat.pos.y; y < boat.pos.y + boatSource.height; y += 1) {
      for (var x = boat.pos.x; x < boat.pos.x + boatSource.width; x += 1) {
        expect(
          portWorld.isBlocked(x, y, movementMode: MovementMode.walk),
          isTrue,
          reason: 'boat/water footprint ($x,$y)',
        );
      }
    }
  });

  test('bourg navigation joins Port, Bois, spawn, Mael reserve and house',
      () async {
    final bourgBundle = await loadRuntimeMapBundle(
      projectFilePath: SelbrumeMapTestFixture.projectFilePath,
      mapId: 'map_bourg_selbrume',
    );
    final portBundle = await loadRuntimeMapBundle(
      projectFilePath: SelbrumeMapTestFixture.projectFilePath,
      mapId: 'map_port_brisants',
    );
    final forestBundle = await loadRuntimeMapBundle(
      projectFilePath: SelbrumeMapTestFixture.projectFilePath,
      mapId: 'map_bois_chaise_brume',
    );
    final houseBundle = await loadRuntimeMapBundle(
      projectFilePath: SelbrumeMapTestFixture.projectFilePath,
      mapId: 'map_maison_joueur',
    );
    final bourg = bourgBundle.map;
    final world = GameplayWorldState.initial(
      map: bourg,
      playerPos: const GridPos(x: 17, y: 24),
      playerMovementMode: MovementMode.walk,
      project: bourgBundle.manifest,
      tileWidth: bourgBundle.manifest.settings.tileWidth,
      tileHeight: bourgBundle.manifest.settings.tileHeight,
      npcMapPresencePredicate: (_, __) => false,
    );
    expect(
      bourg.connections,
      unorderedEquals(<MapConnection>[
        const MapConnection(
          direction: MapConnectionDirection.south,
          targetMapId: 'map_port_brisants',
        ),
        const MapConnection(
          direction: MapConnectionDirection.east,
          targetMapId: 'map_bois_chaise_brume',
        ),
      ]),
    );
    expect(
      portBundle.map.connections.where(
        (connection) =>
            connection.direction == MapConnectionDirection.north &&
            connection.targetMapId == bourg.id &&
            connection.offset == 0,
      ),
      hasLength(1),
    );
    expect(
      forestBundle.map.connections.where(
        (connection) =>
            connection.direction == MapConnectionDirection.west &&
            connection.targetMapId == bourg.id &&
            connection.offset == 0,
      ),
      hasLength(1),
    );
    expect(bourg.warps, hasLength(1));
    final houseWarp = bourg.warps.single;
    expect(houseWarp.id, 'warp_bourg_to_maison');
    expect(houseWarp.pos, const GridPos(x: 13, y: 23));
    expect(houseWarp.targetMapId, houseBundle.map.id);
    expect(houseWarp.targetPos, const GridPos(x: 10, y: 13));
    expect(
      houseBundle.map.warps.where(
        (warp) =>
            warp.id == 'warp_maison_to_bourg' &&
            warp.targetMapId == bourg.id &&
            warp.targetPos == const GridPos(x: 13, y: 24),
      ),
      hasLength(1),
    );

    final reached = _reachableCells(
      map: bourg,
      world: world,
      starts: const <GridPos>[GridPos(x: 17, y: 24)],
    );
    final targets = <GridPos>[
      const GridPos(x: 13, y: 24),
      const GridPos(x: 27, y: 20),
      for (var x = 26; x <= 30; x += 1) GridPos(x: x, y: 54),
      for (var y = 24; y <= 28; y += 1) GridPos(x: 54, y: y),
    ];
    for (final target in targets) {
      expect(
        world.isBlocked(
          target.x,
          target.y,
          movementMode: MovementMode.walk,
        ),
        isFalse,
        reason: 'Bourg critical cell $target',
      );
      expect(
        reached,
        contains(_cellIndex(bourg, target)),
        reason: 'Bourg critical cell $target must reach the spawn',
      );
    }

    final houseWorld = GameplayWorldState.initial(
      map: houseBundle.map,
      playerPos: const GridPos(x: 10, y: 13),
      playerMovementMode: MovementMode.walk,
      project: houseBundle.manifest,
      tileWidth: houseBundle.manifest.settings.tileWidth,
      tileHeight: houseBundle.manifest.settings.tileHeight,
      npcMapPresencePredicate: (_, __) => false,
    );
    expect(
      houseWorld.isBlocked(10, 13, movementMode: MovementMode.walk),
      isFalse,
      reason: 'The Bourg warp arrival inside the house must be passable.',
    );
  });

  test('maison_joueur navigation keeps the doorway corridor reciprocal',
      () async {
    final houseBundle = await loadRuntimeMapBundle(
      projectFilePath: SelbrumeMapTestFixture.projectFilePath,
      mapId: 'map_maison_joueur',
    );
    final bourgBundle = await loadRuntimeMapBundle(
      projectFilePath: SelbrumeMapTestFixture.projectFilePath,
      mapId: 'map_bourg_selbrume',
    );
    final house = houseBundle.map;
    final world = GameplayWorldState.initial(
      map: house,
      playerPos: const GridPos(x: 10, y: 11),
      playerMovementMode: MovementMode.walk,
      project: houseBundle.manifest,
      tileWidth: houseBundle.manifest.settings.tileWidth,
      tileHeight: houseBundle.manifest.settings.tileHeight,
      npcMapPresencePredicate: (_, __) => false,
    );
    final reached = _reachableCells(
      map: house,
      world: world,
      starts: const <GridPos>[GridPos(x: 10, y: 11)],
    );
    for (final pos in const <GridPos>[
      GridPos(x: 10, y: 11),
      GridPos(x: 10, y: 12),
      GridPos(x: 10, y: 13),
      GridPos(x: 10, y: 14),
      GridPos(x: 10, y: 15),
    ]) {
      expect(
        world.isBlocked(pos.x, pos.y, movementMode: MovementMode.walk),
        isFalse,
        reason: 'player-house doorway corridor $pos',
      );
      expect(
        reached,
        contains(_cellIndex(house, pos)),
        reason: 'player-house doorway corridor $pos must reach the spawn',
      );
    }
    for (final blockedFurniture in const <GridPos>[
      GridPos(x: 2, y: 3),
      GridPos(x: 14, y: 5),
      GridPos(x: 16, y: 3),
      GridPos(x: 0, y: 0),
    ]) {
      expect(
        world.isBlocked(
          blockedFurniture.x,
          blockedFurniture.y,
          movementMode: MovementMode.walk,
        ),
        isTrue,
        reason: 'solid player-house furniture/wall $blockedFurniture',
      );
    }

    expect(house.warps, hasLength(1));
    final exitWarp = house.warps.single;
    expect(exitWarp.id, 'warp_maison_to_bourg');
    expect(exitWarp.pos, const GridPos(x: 10, y: 15));
    expect(exitWarp.targetMapId, bourgBundle.map.id);
    expect(exitWarp.targetPos, const GridPos(x: 13, y: 24));
    final bourgWorld = GameplayWorldState.initial(
      map: bourgBundle.map,
      playerPos: exitWarp.targetPos,
      playerMovementMode: MovementMode.walk,
      project: bourgBundle.manifest,
      tileWidth: bourgBundle.manifest.settings.tileWidth,
      tileHeight: bourgBundle.manifest.settings.tileHeight,
      npcMapPresencePredicate: (_, __) => false,
    );
    expect(
      bourgWorld.isBlocked(
        exitWarp.targetPos.x,
        exitWarp.targetPos.y,
        movementMode: MovementMode.walk,
      ),
      isFalse,
    );
    expect(
      bourgBundle.map.warps.where(
        (warp) =>
            warp.id == 'warp_bourg_to_maison' &&
            warp.targetMapId == house.id &&
            warp.targetPos == const GridPos(x: 10, y: 13),
      ),
      hasLength(1),
    );
  });

  test('bois navigation keeps exits loops clearings and canopy passable',
      () async {
    final forestBundle = await loadRuntimeMapBundle(
      projectFilePath: SelbrumeMapTestFixture.projectFilePath,
      mapId: 'map_bois_chaise_brume',
    );
    final bourgBundle = await loadRuntimeMapBundle(
      projectFilePath: SelbrumeMapTestFixture.projectFilePath,
      mapId: 'map_bourg_selbrume',
    );
    final marshBundle = await loadRuntimeMapBundle(
      projectFilePath: SelbrumeMapTestFixture.projectFilePath,
      mapId: 'map_marais_salants',
    );
    final forest = forestBundle.map;
    final world = GameplayWorldState.initial(
      map: forest,
      playerPos: const GridPos(x: 0, y: 26),
      playerMovementMode: MovementMode.walk,
      project: forestBundle.manifest,
      tileWidth: forestBundle.manifest.settings.tileWidth,
      tileHeight: forestBundle.manifest.settings.tileHeight,
      npcMapPresencePredicate: (_, __) => false,
    );
    PixelRect cellPixelRect(GridPos pos) => PixelRect(
          leftPx: pos.x * forestBundle.manifest.settings.tileWidth,
          topPx: pos.y * forestBundle.manifest.settings.tileHeight,
          widthPx: forestBundle.manifest.settings.tileWidth,
          heightPx: forestBundle.manifest.settings.tileHeight,
        );
    expect(
      forest.connections,
      unorderedEquals(<MapConnection>[
        const MapConnection(
          direction: MapConnectionDirection.west,
          targetMapId: 'map_bourg_selbrume',
        ),
        const MapConnection(
          direction: MapConnectionDirection.east,
          targetMapId: 'map_marais_salants',
        ),
      ]),
    );
    expect(
      bourgBundle.map.connections.where(
        (connection) =>
            connection.direction == MapConnectionDirection.east &&
            connection.targetMapId == forest.id &&
            connection.offset == 0,
      ),
      hasLength(1),
    );
    expect(
      marshBundle.map.connections.where(
        (connection) =>
            connection.direction == MapConnectionDirection.west &&
            connection.targetMapId == forest.id &&
            connection.offset == 0,
      ),
      hasLength(1),
    );

    final primary = forest.layers
        .whereType<PathLayer>()
        .singleWhere((layer) => layer.id == 'l_path_primary');
    final tallGrass = forest.layers
        .whereType<PathLayer>()
        .singleWhere((layer) => layer.id == 'l_path_secondary');
    expect(primary.presetId, 'dirth_path');
    expect(tallGrass.presetId, 'haute_herbe');
    for (var index = 0; index < primary.cells.length; index++) {
      if (primary.cells[index]) expect(tallGrass.cells[index], isFalse);
    }

    final reached = _reachableCells(
      map: forest,
      world: world,
      starts: const <GridPos>[GridPos(x: 0, y: 26)],
      allowedCells: primary.cells,
    );
    final criticalCells = <GridPos>[
      for (var y = 24; y <= 28; y++) ...<GridPos>[
        GridPos(x: 0, y: y),
        GridPos(x: 44, y: y),
      ],
      const GridPos(x: 14, y: 15),
      const GridPos(x: 24, y: 16),
      const GridPos(x: 24, y: 23),
      const GridPos(x: 31, y: 30),
    ];
    for (final pos in criticalCells) {
      final index = _cellIndex(forest, pos);
      expect(primary.cells[index], isTrue, reason: 'forest path $pos');
      expect(
        world.isBlocked(pos.x, pos.y, movementMode: MovementMode.walk),
        isFalse,
        reason: 'forest collision $pos',
      );
      expect(reached, contains(index), reason: 'forest reachability $pos');
    }
    for (final center in const <GridPos>[
      GridPos(x: 14, y: 15),
      GridPos(x: 31, y: 30),
    ]) {
      for (var y = center.y - 1; y <= center.y + 1; y++) {
        for (var x = center.x - 1; x <= center.x + 1; x++) {
          final pos = GridPos(x: x, y: y);
          final index = _cellIndex(forest, pos);
          expect(primary.cells[index], isTrue, reason: 'clearing $center');
          expect(tallGrass.cells[index], isFalse, reason: 'clearing $center');
          expect(
            world.isBlocked(x, y, movementMode: MovementMode.walk),
            isFalse,
            reason: 'clearing $center',
          );
          expect(reached, contains(index), reason: 'clearing $center');
        }
      }
    }
    for (final crossing in const <List<GridPos>>[
      <GridPos>[
        GridPos(x: 13, y: 20),
        GridPos(x: 14, y: 20),
        GridPos(x: 15, y: 20),
      ],
      <GridPos>[
        GridPos(x: 23, y: 20),
        GridPos(x: 24, y: 20),
        GridPos(x: 25, y: 20),
      ],
      <GridPos>[
        GridPos(x: 30, y: 26),
        GridPos(x: 31, y: 26),
        GridPos(x: 32, y: 26),
      ],
    ]) {
      expect(
        crossing.where(
          (pos) {
            final index = _cellIndex(forest, pos);
            return primary.cells[index] &&
                !world.isBlocked(
                  pos.x,
                  pos.y,
                  movementMode: MovementMode.walk,
                );
          },
        ),
        hasLength(3),
      );
    }
    final loopOnly = List<bool>.from(primary.cells);
    for (var x = 15; x <= 23; x++) {
      loopOnly[24 * forest.size.width + x] = false;
    }
    final loopReached = _reachableCells(
      map: forest,
      world: world,
      starts: const <GridPos>[GridPos(x: 14, y: 24)],
      allowedCells: loopOnly,
    );
    expect(
      loopReached,
      contains(_cellIndex(forest, const GridPos(x: 24, y: 24))),
      reason: 'The optional loop must retain two distinct main-path joins.',
    );

    for (final passable in const <GridPos>[
      GridPos(x: 2, y: 2),
      GridPos(x: 10, y: 10),
      GridPos(x: 28, y: 10),
      GridPos(x: 8, y: 31),
    ]) {
      expect(
        world.worldStaticObstaclesCollidePixelRect(cellPixelRect(passable)),
        isFalse,
        reason: 'canopy/structural grass must remain passable at $passable',
      );
    }
    for (final solidBase in const <GridPos>[
      GridPos(x: 4, y: 8),
      GridPos(x: 5, y: 9),
      GridPos(x: 21, y: 7),
      GridPos(x: 39, y: 8),
      GridPos(x: 37, y: 30),
      GridPos(x: 18, y: 37),
      GridPos(x: 19, y: 21),
      GridPos(x: 27, y: 22),
      GridPos(x: 3, y: 22),
    ]) {
      expect(
        world.worldStaticObstaclesCollidePixelRect(cellPixelRect(solidBase)),
        isTrue,
        reason: 'forest base must block at $solidBase',
      );
    }
  });

  test('marais navigation reaches every reserve and blocks all basins',
      () async {
    final marshBundle = await loadRuntimeMapBundle(
      projectFilePath: SelbrumeMapTestFixture.projectFilePath,
      mapId: 'map_marais_salants',
    );
    final forestBundle = await loadRuntimeMapBundle(
      projectFilePath: SelbrumeMapTestFixture.projectFilePath,
      mapId: 'map_bois_chaise_brume',
    );
    final passageBundle = await loadRuntimeMapBundle(
      projectFilePath: SelbrumeMapTestFixture.projectFilePath,
      mapId: 'map_passage_dames',
    );
    final marsh = marshBundle.map;
    final world = GameplayWorldState.initial(
      map: marsh,
      playerPos: const GridPos(x: 0, y: 26),
      playerMovementMode: MovementMode.walk,
      project: marshBundle.manifest,
      tileWidth: marshBundle.manifest.settings.tileWidth,
      tileHeight: marshBundle.manifest.settings.tileHeight,
      npcMapPresencePredicate: (_, __) => false,
    );

    expect(
      marsh.connections,
      unorderedEquals(<MapConnection>[
        const MapConnection(
          direction: MapConnectionDirection.west,
          targetMapId: 'map_bois_chaise_brume',
        ),
        const MapConnection(
          direction: MapConnectionDirection.south,
          targetMapId: 'map_passage_dames',
        ),
      ]),
    );
    expect(
      forestBundle.map.connections.where(
        (connection) =>
            connection.direction == MapConnectionDirection.east &&
            connection.targetMapId == marsh.id &&
            connection.offset == 0,
      ),
      hasLength(1),
    );
    expect(
      passageBundle.map.connections.where(
        (connection) =>
            connection.direction == MapConnectionDirection.north &&
            connection.targetMapId == marsh.id &&
            connection.offset == 0,
      ),
      hasLength(1),
    );

    final primary = marsh.layers
        .whereType<PathLayer>()
        .singleWhere((layer) => layer.id == 'l_path_primary');
    final secondary = marsh.layers
        .whereType<PathLayer>()
        .singleWhere((layer) => layer.id == 'l_path_secondary');
    expect(primary.presetId, 'pavement_path');
    expect(secondary.presetId, 'haute_herbe');
    for (var index = 0; index < primary.cells.length; index++) {
      if (primary.cells[index]) expect(secondary.cells[index], isFalse);
    }
    final allowed = <bool>[
      for (var index = 0; index < primary.cells.length; index++)
        primary.cells[index] || secondary.cells[index],
    ];
    final reached = _reachableCells(
      map: marsh,
      world: world,
      starts: const <GridPos>[GridPos(x: 0, y: 26)],
      allowedCells: allowed,
    );

    final criticalCells = <GridPos>[
      for (var y = 24; y <= 28; y++) GridPos(x: 0, y: y),
      for (var x = 30; x <= 34; x++) GridPos(x: x, y: 44),
      const GridPos(x: 10, y: 12),
      const GridPos(x: 8, y: 32),
      const GridPos(x: 32, y: 10),
      const GridPos(x: 34, y: 34),
      const GridPos(x: 14, y: 7),
      const GridPos(x: 24, y: 28),
      const GridPos(x: 38, y: 22),
      const GridPos(x: 6, y: 18),
      const GridPos(x: 18, y: 24),
      const GridPos(x: 31, y: 30),
      const GridPos(x: 19, y: 17),
      const GridPos(x: 31, y: 25),
    ];
    for (final pos in criticalCells) {
      final index = _cellIndex(marsh, pos);
      expect(primary.cells[index], isTrue, reason: 'marsh path $pos');
      expect(
        world.isBlocked(pos.x, pos.y, movementMode: MovementMode.walk),
        isFalse,
        reason: 'marsh collision $pos',
      );
      expect(reached, contains(index), reason: 'marsh reachability $pos');
    }

    for (final basin in const <GridPos>[
      GridPos(x: 20, y: 5),
      GridPos(x: 40, y: 40),
      GridPos(x: 24, y: 15),
    ]) {
      expect(
        world.isBlocked(basin.x, basin.y, movementMode: MovementMode.walk),
        isTrue,
        reason: 'marsh basin $basin',
      );
    }
    for (final structuralObstacle in const <GridPos>[
      GridPos(x: 4, y: 14),
      GridPos(x: 18, y: 16),
      GridPos(x: 30, y: 24),
      GridPos(x: 27, y: 18),
    ]) {
      expect(
        world.isBlocked(
          structuralObstacle.x,
          structuralObstacle.y,
          movementMode: MovementMode.walk,
        ),
        isTrue,
        reason: 'marsh structural obstacle $structuralObstacle',
      );
    }
  });

  test('passage navigation keeps a three-cell causeway and blocks the sea',
      () async {
    final passageBundle = await loadRuntimeMapBundle(
      projectFilePath: SelbrumeMapTestFixture.projectFilePath,
      mapId: 'map_passage_dames',
    );
    final marshBundle = await loadRuntimeMapBundle(
      projectFilePath: SelbrumeMapTestFixture.projectFilePath,
      mapId: 'map_marais_salants',
    );
    final lighthouseBundle = await loadRuntimeMapBundle(
      projectFilePath: SelbrumeMapTestFixture.projectFilePath,
      mapId: 'map_phare_exterieur',
    );
    final passage = passageBundle.map;
    final world = GameplayWorldState.initial(
      map: passage,
      playerPos: const GridPos(x: 32, y: 0),
      playerMovementMode: MovementMode.walk,
      project: passageBundle.manifest,
      tileWidth: passageBundle.manifest.settings.tileWidth,
      tileHeight: passageBundle.manifest.settings.tileHeight,
      npcMapPresencePredicate: (_, __) => false,
    );

    expect(
      marshBundle.map.connections.where(
        (connection) =>
            connection.direction == MapConnectionDirection.south &&
            connection.targetMapId == passage.id &&
            connection.offset == 0,
      ),
      hasLength(1),
    );
    expect(
      lighthouseBundle.map.connections.where(
        (connection) =>
            connection.direction == MapConnectionDirection.west &&
            connection.targetMapId == passage.id &&
            connection.offset == 0,
      ),
      hasLength(1),
    );
    final primary = passage.layers
        .whereType<PathLayer>()
        .singleWhere((layer) => layer.id == 'l_path_primary');
    final sea = passage.layers
        .whereType<PathLayer>()
        .singleWhere((layer) => layer.id == 'l_path_secondary');
    expect(primary.presetId, 'pavement_path');
    expect(sea.presetId, 'nouveau-chemin');
    for (var index = 0; index < primary.cells.length; index++) {
      expect(primary.cells[index] || sea.cells[index], isTrue);
      expect(primary.cells[index] && sea.cells[index], isFalse);
    }
    final reached = _reachableCells(
      map: passage,
      world: world,
      starts: const <GridPos>[GridPos(x: 32, y: 0)],
      allowedCells: primary.cells,
    );
    final critical = <GridPos>[
      for (var x = 30; x <= 34; x++) GridPos(x: x, y: 0),
      for (var y = 12; y <= 16; y++) GridPos(x: 59, y: y),
      for (var y = 9; y <= 11; y++)
        for (var x = 49; x <= 51; x++) GridPos(x: x, y: y),
      for (final x in const <int>[28, 29, 30, 31]) GridPos(x: x, y: 4),
      const GridPos(x: 44, y: 12),
      const GridPos(x: 50, y: 10),
      const GridPos(x: 57, y: 13),
    ];
    for (final pos in critical) {
      final index = _cellIndex(passage, pos);
      expect(primary.cells[index], isTrue, reason: 'passage path $pos');
      expect(
        world.isBlocked(pos.x, pos.y, movementMode: MovementMode.walk),
        isFalse,
        reason: 'passage collision $pos',
      );
      expect(reached, contains(index), reason: 'passage reachability $pos');
    }
    for (var x = 32; x <= 35; x++) {
      expect(
        world.isBlocked(x, 4, movementMode: MovementMode.walk),
        isTrue,
        reason: 'closed barrier x=$x',
      );
    }
    for (final seaCell in const <GridPos>[
      GridPos(x: 29, y: 8),
      GridPos(x: 35, y: 8),
      GridPos(x: 40, y: 11),
      GridPos(x: 40, y: 17),
    ]) {
      final index = _cellIndex(passage, seaCell);
      expect(sea.cells[index], isTrue, reason: '$seaCell');
      expect(
        world.isBlocked(
          seaCell.x,
          seaCell.y,
          movementMode: MovementMode.walk,
        ),
        isTrue,
        reason: '$seaCell',
      );
    }
  });

  test('phare_exterieur navigation reaches both open doors from Passage',
      () async {
    final exteriorBundle = await loadRuntimeMapBundle(
      projectFilePath: SelbrumeMapTestFixture.projectFilePath,
      mapId: 'map_phare_exterieur',
    );
    final passageBundle = await loadRuntimeMapBundle(
      projectFilePath: SelbrumeMapTestFixture.projectFilePath,
      mapId: 'map_passage_dames',
    );
    final interiorBundle = await loadRuntimeMapBundle(
      projectFilePath: SelbrumeMapTestFixture.projectFilePath,
      mapId: 'map_phare_interieur',
    );
    final cabinBundle = await loadRuntimeMapBundle(
      projectFilePath: SelbrumeMapTestFixture.projectFilePath,
      mapId: 'map_cabane_gardien',
    );
    final exterior = exteriorBundle.map;
    final world = GameplayWorldState.initial(
      map: exterior,
      playerPos: const GridPos(x: 0, y: 14),
      playerMovementMode: MovementMode.walk,
      project: exteriorBundle.manifest,
      tileWidth: exteriorBundle.manifest.settings.tileWidth,
      tileHeight: exteriorBundle.manifest.settings.tileHeight,
      npcMapPresencePredicate: (_, __) => false,
    );

    expect(
      passageBundle.map.connections.where(
        (connection) =>
            connection.direction == MapConnectionDirection.east &&
            connection.targetMapId == exterior.id &&
            connection.offset == 0,
      ),
      hasLength(1),
    );
    expect(
      exterior.connections.where(
        (connection) =>
            connection.direction == MapConnectionDirection.west &&
            connection.targetMapId == passageBundle.map.id &&
            connection.offset == 0,
      ),
      hasLength(1),
    );

    final exteriorWarps = <String, MapWarp>{
      for (final warp in exterior.warps) warp.id: warp,
    };
    expect(
        exteriorWarps.keys,
        unorderedEquals(<String>[
          'warp_phare_ext_to_interieur',
          'warp_phare_ext_to_cabane',
        ]));
    expect(
      interiorBundle.map.warps.where(
        (warp) =>
            warp.id == 'warp_phare_interieur_to_exterieur' &&
            warp.pos == const GridPos(x: 18, y: 44) &&
            warp.targetMapId == exterior.id &&
            warp.targetPos == const GridPos(x: 23, y: 19),
      ),
      hasLength(1),
    );
    expect(
      cabinBundle.map.warps.where(
        (warp) =>
            warp.id == 'warp_cabane_to_phare_exterieur' &&
            warp.pos == const GridPos(x: 10, y: 15) &&
            warp.targetMapId == exterior.id &&
            warp.targetPos == const GridPos(x: 8, y: 34),
      ),
      hasLength(1),
    );

    final primary = exterior.layers
        .whereType<PathLayer>()
        .singleWhere((layer) => layer.id == 'l_path_primary');
    final secondary = exterior.layers
        .whereType<PathLayer>()
        .singleWhere((layer) => layer.id == 'l_path_secondary');
    expect(primary.presetId, 'pavement_path');
    expect(secondary.presetId, 'dirth_path');
    final land = <bool>[
      for (var index = 0; index < primary.cells.length; index++)
        primary.cells[index] || secondary.cells[index],
    ];
    for (var index = 0; index < land.length; index++) {
      expect(primary.cells[index] && secondary.cells[index], isFalse);
    }
    final reached = _reachableCells(
      map: exterior,
      world: world,
      starts: const <GridPos>[GridPos(x: 0, y: 14)],
      allowedCells: land,
    );
    for (final pos in const <GridPos>[
      GridPos(x: 0, y: 12),
      GridPos(x: 0, y: 16),
      GridPos(x: 23, y: 18),
      GridPos(x: 23, y: 19),
      GridPos(x: 8, y: 33),
      GridPos(x: 8, y: 34),
    ]) {
      expect(
        world.isBlocked(pos.x, pos.y, movementMode: MovementMode.walk),
        isFalse,
        reason: 'critical lighthouse approach $pos',
      );
      expect(
        reached,
        contains(_cellIndex(exterior, pos)),
        reason: 'critical lighthouse reachability $pos',
      );
    }
    for (final wall in const <GridPos>[
      GridPos(x: 23, y: 8),
      GridPos(x: 24, y: 12),
      GridPos(x: 22, y: 17),
      GridPos(x: 6, y: 29),
      GridPos(x: 10, y: 31),
      GridPos(x: 7, y: 32),
      GridPos(x: 40, y: 5),
      GridPos(x: 42, y: 40),
      GridPos(x: 2, y: 42),
    ]) {
      expect(
        world.isBlocked(wall.x, wall.y, movementMode: MovementMode.walk),
        isTrue,
        reason: 'lighthouse wall or cliff $wall',
      );
    }
  });

  test(
      'phare_interieur navigation connects entrance note optional room and top',
      () async {
    final interiorBundle = await loadRuntimeMapBundle(
      projectFilePath: SelbrumeMapTestFixture.projectFilePath,
      mapId: 'map_phare_interieur',
    );
    final exteriorBundle = await loadRuntimeMapBundle(
      projectFilePath: SelbrumeMapTestFixture.projectFilePath,
      mapId: 'map_phare_exterieur',
    );
    final topBundle = await loadRuntimeMapBundle(
      projectFilePath: SelbrumeMapTestFixture.projectFilePath,
      mapId: 'map_sommet_phare',
    );
    final interior = interiorBundle.map;
    final world = GameplayWorldState.initial(
      map: interior,
      playerPos: const GridPos(x: 18, y: 42),
      playerMovementMode: MovementMode.walk,
      project: interiorBundle.manifest,
      tileWidth: interiorBundle.manifest.settings.tileWidth,
      tileHeight: interiorBundle.manifest.settings.tileHeight,
      npcMapPresencePredicate: (_, __) => false,
    );

    expect(
      exteriorBundle.map.warps.where(
        (warp) =>
            warp.id == 'warp_phare_ext_to_interieur' &&
            warp.targetMapId == interior.id &&
            warp.targetPos == const GridPos(x: 18, y: 42),
      ),
      hasLength(1),
    );
    expect(
      topBundle.map.warps.where(
        (warp) =>
            warp.id == 'warp_sommet_to_phare_interieur' &&
            warp.targetMapId == interior.id &&
            warp.targetPos == const GridPos(x: 18, y: 2),
      ),
      hasLength(1),
    );
    expect(
      interior.warps,
      unorderedEquals(const <MapWarp>[
        MapWarp(
          id: 'warp_phare_interieur_to_exterieur',
          pos: GridPos(x: 18, y: 44),
          targetMapId: 'map_phare_exterieur',
          targetPos: GridPos(x: 23, y: 19),
        ),
        MapWarp(
          id: 'warp_phare_interieur_to_sommet',
          pos: GridPos(x: 18, y: 1),
          targetMapId: 'map_sommet_phare',
          targetPos: GridPos(x: 12, y: 22),
        ),
      ]),
    );

    final reached = _reachableCells(
      map: interior,
      world: world,
      starts: const <GridPos>[GridPos(x: 18, y: 42)],
      allowedCells: List<bool>.filled(36 * 45, true),
    );
    final critical = <GridPos>[
      const GridPos(x: 18, y: 44),
      const GridPos(x: 18, y: 42),
      const GridPos(x: 10, y: 24),
      const GridPos(x: 10, y: 26),
      const GridPos(x: 18, y: 2),
      const GridPos(x: 18, y: 1),
      for (var x = 26; x <= 28; x++) GridPos(x: x, y: 28),
      for (var y = 29; y <= 30; y++)
        for (var x = 28; x <= 29; x++) GridPos(x: x, y: y),
      for (final x in const <int>[18, 19]) GridPos(x: x, y: 31),
      for (final x in const <int>[10, 11, 26, 27]) GridPos(x: x, y: 20),
    ];
    for (final pos in critical) {
      expect(
        world.isBlocked(pos.x, pos.y, movementMode: MovementMode.walk),
        isFalse,
        reason: 'lighthouse route $pos',
      );
      expect(
        reached,
        contains(_cellIndex(interior, pos)),
        reason: 'lighthouse reachability $pos',
      );
    }
    for (final pos in <GridPos>[
      for (var y = 0; y < 3; y++)
        for (var x = 17; x < 20; x++) GridPos(x: x, y: y),
      for (var y = 42; y < 45; y++)
        for (var x = 17; x < 20; x++) GridPos(x: x, y: y),
      for (var y = 29; y < 31; y++)
        for (var x = 28; x < 30; x++) GridPos(x: x, y: y),
    ]) {
      expect(
        world.isBlocked(pos.x, pos.y, movementMode: MovementMode.walk),
        isFalse,
        reason: 'stairs/trapdoor must stay free $pos',
      );
    }
    for (final wall in const <GridPos>[
      GridPos(x: 0, y: 10),
      GridPos(x: 34, y: 11),
      GridPos(x: 2, y: 31),
      GridPos(x: 14, y: 20),
      GridPos(x: 22, y: 25),
      GridPos(x: 25, y: 23),
      GridPos(x: 27, y: 8),
    ]) {
      expect(
        world.isBlocked(wall.x, wall.y, movementMode: MovementMode.walk),
        isTrue,
        reason: 'lighthouse wall/obstacle $wall',
      );
    }
  });

  test('sommet keeps the full confrontation zone readable and return open',
      () async {
    final topBundle = await loadRuntimeMapBundle(
      projectFilePath: SelbrumeMapTestFixture.projectFilePath,
      mapId: 'map_sommet_phare',
    );
    final interiorBundle = await loadRuntimeMapBundle(
      projectFilePath: SelbrumeMapTestFixture.projectFilePath,
      mapId: 'map_phare_interieur',
    );
    final top = topBundle.map;
    final world = GameplayWorldState.initial(
      map: top,
      playerPos: const GridPos(x: 12, y: 22),
      playerMovementMode: MovementMode.walk,
      project: topBundle.manifest,
      tileWidth: topBundle.manifest.settings.tileWidth,
      tileHeight: topBundle.manifest.settings.tileHeight,
      npcMapPresencePredicate: (_, __) => false,
    );

    expect(
      interiorBundle.map.warps.where(
        (warp) =>
            warp.id == 'warp_phare_interieur_to_sommet' &&
            warp.targetMapId == top.id &&
            warp.targetPos == const GridPos(x: 12, y: 22),
      ),
      hasLength(1),
    );
    expect(
      top.warps,
      const <MapWarp>[
        MapWarp(
          id: 'warp_sommet_to_phare_interieur',
          pos: GridPos(x: 12, y: 23),
          targetMapId: 'map_phare_interieur',
          targetPos: GridPos(x: 18, y: 2),
        ),
      ],
    );
    final reached = _reachableCells(
      map: top,
      world: world,
      starts: const <GridPos>[GridPos(x: 12, y: 22)],
      allowedCells: List<bool>.filled(24 * 24, true),
    );
    for (var y = 5; y < 15; y++) {
      for (var x = 7; x < 17; x++) {
        final pos = GridPos(x: x, y: y);
        expect(
          world.isBlocked(x, y, movementMode: MovementMode.walk),
          isFalse,
          reason: 'zone_lighthouse_top $pos',
        );
        expect(
          reached,
          contains(_cellIndex(top, pos)),
          reason: 'zone_lighthouse_top reachability $pos',
        );
      }
    }
    for (final pos in const <GridPos>[
      GridPos(x: 12, y: 22),
      GridPos(x: 12, y: 23),
      GridPos(x: 12, y: 10),
      GridPos(x: 11, y: 22),
      GridPos(x: 11, y: 23),
    ]) {
      expect(
        world.isBlocked(pos.x, pos.y, movementMode: MovementMode.walk),
        isFalse,
        reason: 'summit return route $pos',
      );
      expect(reached, contains(_cellIndex(top, pos)), reason: '$pos');
    }

    final elementsById = <String, ProjectElementEntry>{
      for (final element in topBundle.manifest.elements) element.id: element,
    };
    for (final placed in top.placedElements.where(
      (placed) => placed.elementId.startsWith('el_selbrume_sommet_parapet_'),
    )) {
      final profile = elementsById[placed.elementId]!.collisionProfile!;
      for (final cell in profile.cells) {
        final pos = GridPos(
          x: placed.pos.x + cell.x,
          y: placed.pos.y + cell.y,
        );
        expect(
          world.isBlocked(pos.x, pos.y, movementMode: MovementMode.walk),
          isTrue,
          reason: '${placed.id} $pos',
        );
      }
    }
    for (final pos in const <GridPos>[
      GridPos(x: 11, y: 0),
      GridPos(x: 12, y: 2),
      GridPos(x: 17, y: 15),
      GridPos(x: 21, y: 19),
    ]) {
      expect(
        world.isBlocked(pos.x, pos.y, movementMode: MovementMode.walk),
        isTrue,
        reason: 'visible summit obstacle $pos',
      );
    }
    final placedFx = top.placedElements.where(
      (placed) => placed.elementId.startsWith('el_selbrume_fx_'),
    );
    expect(placedFx, hasLength(1));
    expect(placedFx.single.applyCollision, isFalse);
    expect(
      elementsById[placedFx.single.elementId]?.collisionProfile,
      isNull,
    );
    for (final element in topBundle.manifest.elements.where(
      (element) => element.tilesetId == 'ts_selbrume_lighthouse_fx',
    )) {
      expect(element.collisionProfile, isNull, reason: element.id);
      expect(element.recommendedLayerId, 'l_tile_fx');
    }
  });

  test('cabane_gardien reaches both exits journal and key from its arrival',
      () async {
    final cabinBundle = await loadRuntimeMapBundle(
      projectFilePath: SelbrumeMapTestFixture.projectFilePath,
      mapId: 'map_cabane_gardien',
    );
    final exteriorBundle = await loadRuntimeMapBundle(
      projectFilePath: SelbrumeMapTestFixture.projectFilePath,
      mapId: 'map_phare_exterieur',
    );
    final passageBundle = await loadRuntimeMapBundle(
      projectFilePath: SelbrumeMapTestFixture.projectFilePath,
      mapId: 'map_passage_dames',
    );
    final cabin = cabinBundle.map;
    final world = GameplayWorldState.initial(
      map: cabin,
      playerPos: const GridPos(x: 10, y: 13),
      playerMovementMode: MovementMode.walk,
      project: cabinBundle.manifest,
      tileWidth: cabinBundle.manifest.settings.tileWidth,
      tileHeight: cabinBundle.manifest.settings.tileHeight,
      npcMapPresencePredicate: (_, __) => false,
    );
    final reached = _reachableCells(
      map: cabin,
      world: world,
      starts: const <GridPos>[GridPos(x: 10, y: 13)],
      allowedCells: List<bool>.filled(20 * 16, true),
    );
    for (final pos in const <GridPos>[
      GridPos(x: 10, y: 13),
      GridPos(x: 10, y: 15),
      GridPos(x: 19, y: 8),
      GridPos(x: 6, y: 5),
      GridPos(x: 7, y: 5),
      GridPos(x: 14, y: 9),
    ]) {
      expect(
        world.isBlocked(pos.x, pos.y, movementMode: MovementMode.walk),
        isFalse,
        reason: 'keeper-cabin critical cell $pos',
      );
      expect(
        reached,
        contains(_cellIndex(cabin, pos)),
        reason: 'keeper-cabin reachability $pos',
      );
    }
    for (final pos in const <GridPos>[
      GridPos(x: 0, y: 0),
      GridPos(x: 19, y: 5),
      GridPos(x: 2, y: 3),
      GridPos(x: 6, y: 6),
      GridPos(x: 10, y: 4),
      GridPos(x: 16, y: 2),
      GridPos(x: 2, y: 10),
      GridPos(x: 5, y: 7),
      GridPos(x: 8, y: 7),
    ]) {
      expect(
        world.worldStaticObstaclesCollidePixelRect(
          PixelRect(
            leftPx: pos.x * cabinBundle.manifest.settings.tileWidth,
            topPx: pos.y * cabinBundle.manifest.settings.tileHeight,
            widthPx: cabinBundle.manifest.settings.tileWidth,
            heightPx: cabinBundle.manifest.settings.tileHeight,
          ),
        ),
        isTrue,
        reason: 'keeper-cabin collision mask $pos',
      );
    }

    expect(
      cabin.warps,
      const <MapWarp>[
        MapWarp(
          id: 'warp_cabane_to_phare_exterieur',
          pos: GridPos(x: 10, y: 15),
          targetMapId: 'map_phare_exterieur',
          targetPos: GridPos(x: 8, y: 34),
        ),
        MapWarp(
          id: 'warp_cabane_to_passage',
          pos: GridPos(x: 19, y: 8),
          targetMapId: 'map_passage_dames',
          targetPos: GridPos(x: 50, y: 10),
        ),
      ],
    );
    expect(
      exteriorBundle.map.warps.where(
        (warp) =>
            warp.id == 'warp_phare_ext_to_cabane' &&
            warp.targetMapId == cabin.id &&
            warp.targetPos == const GridPos(x: 10, y: 13),
      ),
      hasLength(1),
    );
    final exteriorWorld = GameplayWorldState.initial(
      map: exteriorBundle.map,
      playerPos: const GridPos(x: 8, y: 34),
      playerMovementMode: MovementMode.walk,
      project: exteriorBundle.manifest,
      tileWidth: exteriorBundle.manifest.settings.tileWidth,
      tileHeight: exteriorBundle.manifest.settings.tileHeight,
      npcMapPresencePredicate: (_, __) => false,
    );
    final passageWorld = GameplayWorldState.initial(
      map: passageBundle.map,
      playerPos: const GridPos(x: 50, y: 10),
      playerMovementMode: MovementMode.walk,
      project: passageBundle.manifest,
      tileWidth: passageBundle.manifest.settings.tileWidth,
      tileHeight: passageBundle.manifest.settings.tileHeight,
      npcMapPresencePredicate: (_, __) => false,
    );
    expect(
      exteriorWorld.isBlocked(8, 34, movementMode: MovementMode.walk),
      isFalse,
    );
    expect(
      passageWorld.isBlocked(50, 10, movementMode: MovementMode.walk),
      isFalse,
    );
    final secondaryDoor = cabin.placedElements.singleWhere(
      (placed) => placed.id == 'pe_cabane_porte_secondaire',
    );
    expect(
      secondaryDoor.elementId,
      'el_selbrume_cabane_porte_secondaire_fermee',
    );
    expect(secondaryDoor.applyCollision, isFalse);
  });

  test(
    'keeps all ten Selbrume maps mutually reachable through static geometry',
    () async {
      final bundles = await SelbrumeMapTestFixture.loadAllBetaBundles();
      _validateNavigationContract(
        manifest: bundles.values.first.manifest,
        mapsByManifestId:
            bundles.map((mapId, bundle) => MapEntry(mapId, bundle.map)),
        expectedMapIds: SelbrumeMapTestFixture.allBetaMapIds,
        startMapId: SelbrumeMapTestFixture.startMapId,
        requiredZoneIdsByMap: SelbrumeMapTestFixture.requiredZoneIdsByMap,
      );
    },
  );

  group('navigation negative contracts', () {
    test('rejects a manifest map whose MapData is missing', () {
      expect(
        () => _validateNavigationContract(
          manifest: _manifest(<String>['map_a', 'map_b']),
          mapsByManifestId: <String, MapData>{
            'map_a': _map('map_a'),
          },
          expectedMapIds: const <String>['map_a', 'map_b'],
          startMapId: 'map_a',
          requiredZoneIdsByMap: const <String, List<String>>{},
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.toString(),
            'message',
            allOf(contains('map_b'), contains('Map data missing')),
          ),
        ),
      );
    });

    test('rejects a manifest entry whose MapData.id does not match', () {
      expect(
        () => _validateNavigationContract(
          manifest: _manifest(<String>['map_a']),
          mapsByManifestId: <String, MapData>{
            'map_a': _map('wrong_id'),
          },
          expectedMapIds: const <String>['map_a'],
          startMapId: 'map_a',
          requiredZoneIdsByMap: const <String, List<String>>{},
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.toString(),
            'message',
            allOf(contains('map_a'), contains('does not match MapData.id')),
          ),
        ),
      );
    });

    test('rejects a warp with a dangling target map', () {
      expect(
        () => _validateNavigationContract(
          manifest: _manifest(<String>['map_a']),
          mapsByManifestId: <String, MapData>{
            'map_a': _map(
              'map_a',
              warps: const <MapWarp>[
                MapWarp(
                  id: 'warp_dangling',
                  pos: GridPos(x: 0, y: 0),
                  targetMapId: 'map_missing',
                  targetPos: GridPos(x: 0, y: 0),
                ),
              ],
            ),
          },
          expectedMapIds: const <String>['map_a'],
          startMapId: 'map_a',
          requiredZoneIdsByMap: const <String, List<String>>{},
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.toString(),
            'message',
            allOf(contains('warp_dangling'), contains('missing target map')),
          ),
        ),
      );
    });

    test('rejects a warp arrival outside target map bounds', () {
      expect(
        () => _validateNavigationContract(
          manifest: _manifest(<String>['map_a', 'map_b']),
          mapsByManifestId: <String, MapData>{
            'map_a': _map(
              'map_a',
              warps: const <MapWarp>[
                MapWarp(
                  id: 'warp_out_of_bounds',
                  pos: GridPos(x: 0, y: 0),
                  targetMapId: 'map_b',
                  targetPos: GridPos(x: 2, y: 0),
                ),
              ],
            ),
            'map_b': _map('map_b'),
          },
          expectedMapIds: const <String>['map_a', 'map_b'],
          startMapId: 'map_a',
          requiredZoneIdsByMap: const <String, List<String>>{},
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.toString(),
            'message',
            allOf(contains('warp_out_of_bounds'), contains('out of bounds')),
          ),
        ),
      );
    });

    test('rejects a map isolated from the start map', () {
      expect(
        () => _validateNavigationContract(
          manifest: _manifest(<String>['map_a', 'map_b']),
          mapsByManifestId: <String, MapData>{
            'map_a': _map('map_a'),
            'map_b': _map('map_b'),
          },
          expectedMapIds: const <String>['map_a', 'map_b'],
          startMapId: 'map_a',
          requiredZoneIdsByMap: const <String, List<String>>{},
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.toString(),
            'message',
            allOf(contains('map_b'), contains('not reachable')),
          ),
        ),
      );
    });

    test('rejects a warp whose target cell is statically blocked', () {
      expect(
        () => _validateNavigationContract(
          manifest: _manifest(<String>['map_a', 'map_b']),
          mapsByManifestId: <String, MapData>{
            'map_a': _map(
              'map_a',
              warps: const <MapWarp>[
                MapWarp(
                  id: 'warp_blocked',
                  pos: GridPos(x: 0, y: 0),
                  targetMapId: 'map_b',
                  targetPos: GridPos(x: 0, y: 0),
                ),
              ],
            ),
            'map_b': _map(
              'map_b',
              collisions: const <bool>[true, false, false, false],
            ),
          },
          expectedMapIds: const <String>['map_a', 'map_b'],
          startMapId: 'map_a',
          requiredZoneIdsByMap: const <String, List<String>>{},
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.toString(),
            'message',
            allOf(contains('warp_blocked'), contains('statically blocked')),
          ),
        ),
      );
    });

    test('rejects reciprocal self-connections', () {
      expect(
        () => _validateNavigationContract(
          manifest: _manifest(<String>['map_a']),
          mapsByManifestId: <String, MapData>{
            'map_a': _map(
              'map_a',
              connections: const <MapConnection>[
                MapConnection(
                  direction: MapConnectionDirection.east,
                  targetMapId: 'map_a',
                ),
                MapConnection(
                  direction: MapConnectionDirection.west,
                  targetMapId: 'map_a',
                ),
              ],
            ),
          },
          expectedMapIds: const <String>['map_a'],
          startMapId: 'map_a',
          requiredZoneIdsByMap: const <String, List<String>>{},
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.toString(),
            'message',
            allOf(contains('map_a'), contains('must not target its own map')),
          ),
        ),
      );
    });

    test('rejects a split anchor masked by multi-source BFS', () {
      const splitMap = MapData(
        id: 'map_a',
        name: 'Split anchors',
        size: GridSize(width: 3, height: 1),
        layers: <MapLayer>[
          MapLayer.object(id: 'objects', name: 'Objects'),
          MapLayer.collision(
            id: 'collision',
            name: 'Collision',
            collisions: <bool>[false, true, false],
          ),
        ],
        gameplayZones: <MapGameplayZone>[
          MapGameplayZone(
            id: 'zone_split',
            kind: GameplayZoneKind.custom,
            area: MapRect(
              pos: GridPos(x: 0, y: 0),
              size: GridSize(width: 3, height: 1),
            ),
          ),
          MapGameplayZone(
            id: 'zone_right',
            kind: GameplayZoneKind.custom,
            area: MapRect(
              pos: GridPos(x: 2, y: 0),
              size: GridSize(width: 1, height: 1),
            ),
          ),
        ],
      );

      expect(
        () => _validateNavigationContract(
          manifest: _manifest(<String>['map_a']),
          mapsByManifestId: const <String, MapData>{'map_a': splitMap},
          expectedMapIds: const <String>['map_a'],
          startMapId: 'map_a',
          requiredZoneIdsByMap: const <String, List<String>>{
            'map_a': <String>['zone_split', 'zone_right'],
          },
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.toString(),
            'message',
            allOf(contains('zone_split'), contains('disconnected')),
          ),
        ),
      );
    });

    test('rejects reciprocal connections without an aligned passable pair', () {
      expect(
        () => _validateNavigationContract(
          manifest: _manifest(<String>['map_a', 'map_b']),
          mapsByManifestId: <String, MapData>{
            'map_a': _map(
              'map_a',
              collisions: const <bool>[false, false, false, true],
              connections: const <MapConnection>[
                MapConnection(
                  direction: MapConnectionDirection.east,
                  targetMapId: 'map_b',
                ),
              ],
            ),
            'map_b': _map(
              'map_b',
              collisions: const <bool>[true, false, false, false],
              connections: const <MapConnection>[
                MapConnection(
                  direction: MapConnectionDirection.west,
                  targetMapId: 'map_a',
                ),
              ],
            ),
          },
          expectedMapIds: const <String>['map_a', 'map_b'],
          startMapId: 'map_a',
          requiredZoneIdsByMap: const <String, List<String>>{},
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.toString(),
            'message',
            allOf(contains('map_a'), contains('aligned passable border')),
          ),
        ),
      );
    });
  });
}

void _validateNavigationContract({
  required ProjectManifest manifest,
  required Map<String, MapData> mapsByManifestId,
  required List<String> expectedMapIds,
  required String startMapId,
  required Map<String, List<String>> requiredZoneIdsByMap,
}) {
  final expectedIds = expectedMapIds.toSet();
  if (expectedIds.length != expectedMapIds.length) {
    throw StateError('Expected map IDs contain duplicates.');
  }
  final manifestIds = manifest.maps.map((entry) => entry.id).toList();
  for (final mapId in expectedMapIds) {
    final entryCount = manifestIds.where((id) => id == mapId).length;
    if (entryCount != 1) {
      throw StateError(
        'Expected one manifest entry for $mapId, found $entryCount.',
      );
    }
    final map = mapsByManifestId[mapId];
    if (map == null) {
      throw StateError('Map data missing for manifest entry: $mapId');
    }
    if (map.id != mapId) {
      throw StateError(
        'Manifest entry $mapId does not match MapData.id ${map.id}.',
      );
    }
  }
  if (manifestIds.toSet().difference(expectedIds).isNotEmpty ||
      expectedIds.difference(manifestIds.toSet()).isNotEmpty) {
    throw StateError(
      'Manifest/map inventory mismatch. Expected $expectedIds, '
      'found ${manifestIds.toSet()}.',
    );
  }
  if (!expectedIds.contains(startMapId)) {
    throw StateError(
        'Start map is absent from the expected catalog: $startMapId');
  }

  final worldByMapId = <String, GameplayWorldState>{
    for (final mapId in expectedMapIds)
      mapId: GameplayWorldState.initial(
        map: mapsByManifestId[mapId]!,
        playerPos: const GridPos(x: 0, y: 0),
        playerMovementMode: MovementMode.walk,
        project: manifest,
        tileWidth: manifest.settings.tileWidth,
        tileHeight: manifest.settings.tileHeight,
        // Narrative NPC positions are dynamic. This contract intentionally
        // evaluates only authored static layers/elements/geometry.
        npcMapPresencePredicate: (_, __) => false,
      ),
  };
  final outgoing = <String, Set<String>>{
    for (final mapId in expectedMapIds) mapId: <String>{},
  };
  final incomingWarpTargets = <String, List<_AnchorGroup>>{
    for (final mapId in expectedMapIds) mapId: <_AnchorGroup>[],
  };

  for (final sourceId in expectedMapIds) {
    final sourceMap = mapsByManifestId[sourceId]!;
    for (final warp in sourceMap.warps) {
      if (!_isInBounds(sourceMap, warp.pos)) {
        throw StateError(
            'Warp ${warp.id} source is out of bounds on $sourceId.');
      }
      if (warp.targetMapId == sourceId) {
        throw StateError('Warp ${warp.id} must not target its own map.');
      }
      final targetMap = mapsByManifestId[warp.targetMapId];
      if (targetMap == null) {
        throw StateError(
          'Warp ${warp.id} on $sourceId has missing target map '
          '${warp.targetMapId}.',
        );
      }
      if (!_isInBounds(targetMap, warp.targetPos)) {
        throw StateError(
          'Warp ${warp.id} target ${warp.targetPos} is out of bounds on '
          '${warp.targetMapId}.',
        );
      }
      if (worldByMapId[warp.targetMapId]!.isBlocked(
        warp.targetPos.x,
        warp.targetPos.y,
        movementMode: MovementMode.walk,
      )) {
        throw StateError(
          'Warp ${warp.id} target ${warp.targetPos} is statically blocked on '
          '${warp.targetMapId}.',
        );
      }
      outgoing[sourceId]!.add(warp.targetMapId);
      incomingWarpTargets[warp.targetMapId]!.add(
        _AnchorGroup(
          label: 'arrival from $sourceId via ${warp.id}',
          cells: <GridPos>[warp.targetPos],
        ),
      );
    }

    for (final connection in sourceMap.connections) {
      if (connection.targetMapId == sourceId) {
        throw StateError(
          'Connection ${connection.direction.name} on $sourceId must not '
          'target its own map.',
        );
      }
      final targetMap = mapsByManifestId[connection.targetMapId];
      if (targetMap == null) {
        throw StateError(
          'Connection ${connection.direction.name} on $sourceId has missing '
          'target map ${connection.targetMapId}.',
        );
      }
      if (connection.offset != 0) {
        throw StateError(
          'Connection $sourceId -> ${connection.targetMapId} must use offset 0.',
        );
      }
      if (!_hasAlignedPassableConnectionPair(
        sourceMap: sourceMap,
        sourceWorld: worldByMapId[sourceId]!,
        targetMap: targetMap,
        targetWorld: worldByMapId[connection.targetMapId]!,
        connection: connection,
      )) {
        throw StateError(
          'Connection $sourceId ${connection.direction.name} -> '
          '${connection.targetMapId} has no aligned passable border-cell pair.',
        );
      }
      final reciprocal = targetMap.connections
          .where(
            (candidate) =>
                candidate.targetMapId == sourceId &&
                candidate.direction == connection.direction.opposite &&
                candidate.offset == 0,
          )
          .toList(growable: false);
      if (reciprocal.length != 1) {
        throw StateError(
          'Connection $sourceId ${connection.direction.name} -> '
          '${connection.targetMapId} needs exactly one reciprocal '
          '${connection.direction.opposite.name} connection with offset 0.',
        );
      }
      outgoing[sourceId]!.add(connection.targetMapId);
    }
  }

  final reachable = _reachableMapIds(startMapId, outgoing);
  final unreachable = expectedIds.difference(reachable);
  if (unreachable.isNotEmpty) {
    throw StateError(
      'Selbrume maps not reachable from $startMapId: $unreachable',
    );
  }
  final reverse = <String, Set<String>>{
    for (final mapId in expectedMapIds) mapId: <String>{},
  };
  for (final source in outgoing.entries) {
    for (final target in source.value) {
      reverse[target]!.add(source.key);
    }
  }
  final ableToReturn = _reachableMapIds(startMapId, reverse);
  final unableToReturn = expectedIds.difference(ableToReturn);
  if (unableToReturn.isNotEmpty) {
    throw StateError(
      'Selbrume maps without a return route to $startMapId: $unableToReturn',
    );
  }

  for (final mapId in expectedMapIds) {
    _validateStaticAnchorConnectivity(
      map: mapsByManifestId[mapId]!,
      world: worldByMapId[mapId]!,
      requiredZoneIds: requiredZoneIdsByMap[mapId] ?? const <String>[],
      incomingWarpTargets: incomingWarpTargets[mapId]!,
    );
  }
}

void _validateStaticAnchorConnectivity({
  required MapData map,
  required GameplayWorldState world,
  required List<String> requiredZoneIds,
  required List<_AnchorGroup> incomingWarpTargets,
}) {
  final anchors = <_AnchorGroup>[...incomingWarpTargets];

  for (final zoneId in requiredZoneIds) {
    final zones = map.gameplayZones.where((zone) => zone.id == zoneId).toList();
    if (zones.length != 1) {
      throw StateError(
        '${map.id} must contain required zone $zoneId exactly once.',
      );
    }
    anchors.add(
      _AnchorGroup(
        label: 'zone $zoneId',
        cells: _passableZoneCells(zones.single, map, world),
      ),
    );
  }

  for (final warp in map.warps) {
    anchors.add(
      _AnchorGroup(
        label: 'warp ${warp.id}',
        cells: _passableWarpApproachCells(warp, map, world),
      ),
    );
  }
  for (final connection in map.connections) {
    anchors.add(
      _AnchorGroup(
        label: 'connection ${connection.direction.name} '
            'to ${connection.targetMapId}',
        cells: _passableConnectionEdgeCells(connection.direction, map, world),
      ),
    );
  }

  for (final anchor in anchors) {
    if (anchor.cells.isEmpty) {
      throw StateError(
          '${map.id} ${anchor.label} has no passable static cell.');
    }
  }
  if (anchors.isEmpty) {
    return;
  }

  final canonicalStart = _canonicalAnchorCell(anchors.first.cells);
  final reachable = _reachableCells(
    map: map,
    world: world,
    starts: <GridPos>[canonicalStart],
  );
  for (final anchor in anchors) {
    final disconnectedCells = anchor.cells
        .where((cell) => !reachable.contains(_cellIndex(map, cell)))
        .toList(growable: false);
    if (disconnectedCells.isNotEmpty) {
      throw StateError(
        '${map.id} ${anchor.label} has disconnected passable cells '
        '$disconnectedCells from canonical ${anchors.first.label} cell '
        '$canonicalStart through GameplayWorldState.isBlocked geometry.',
      );
    }
  }
}

GridPos _canonicalAnchorCell(List<GridPos> cells) {
  final ordered = List<GridPos>.from(cells)
    ..sort((left, right) {
      final byY = left.y.compareTo(right.y);
      return byY != 0 ? byY : left.x.compareTo(right.x);
    });
  return ordered.first;
}

List<GridPos> _passableZoneCells(
  MapGameplayZone zone,
  MapData map,
  GameplayWorldState world,
) {
  final cells = <GridPos>[];
  final right = zone.area.pos.x + zone.area.size.width;
  final bottom = zone.area.pos.y + zone.area.size.height;
  for (var y = zone.area.pos.y; y < bottom; y += 1) {
    for (var x = zone.area.pos.x; x < right; x += 1) {
      final pos = GridPos(x: x, y: y);
      if (_isInBounds(map, pos) &&
          !world.isBlocked(x, y, movementMode: MovementMode.walk)) {
        cells.add(pos);
      }
    }
  }
  return cells;
}

List<GridPos> _passableWarpApproachCells(
  MapWarp warp,
  MapData map,
  GameplayWorldState world,
) {
  // An on-bump warp may legitimately occupy a blocked door cell; the usable
  // navigation anchor is then a passable cardinal approach cell.
  final candidates = warp.triggerMode == MapWarpTriggerMode.onEnter
      ? <GridPos>[warp.pos]
      : <GridPos>[
          GridPos(x: warp.pos.x, y: warp.pos.y - 1),
          GridPos(x: warp.pos.x + 1, y: warp.pos.y),
          GridPos(x: warp.pos.x, y: warp.pos.y + 1),
          GridPos(x: warp.pos.x - 1, y: warp.pos.y),
        ];
  return candidates
      .where(
        (pos) =>
            _isInBounds(map, pos) &&
            !world.isBlocked(
              pos.x,
              pos.y,
              movementMode: MovementMode.walk,
            ),
      )
      .toList(growable: false);
}

List<GridPos> _passableConnectionEdgeCells(
  MapConnectionDirection direction,
  MapData map,
  GameplayWorldState world,
) {
  final candidates = <GridPos>[];
  switch (direction) {
    case MapConnectionDirection.north:
      for (var x = 0; x < map.size.width; x += 1) {
        candidates.add(GridPos(x: x, y: 0));
      }
    case MapConnectionDirection.south:
      for (var x = 0; x < map.size.width; x += 1) {
        candidates.add(GridPos(x: x, y: map.size.height - 1));
      }
    case MapConnectionDirection.east:
      for (var y = 0; y < map.size.height; y += 1) {
        candidates.add(GridPos(x: map.size.width - 1, y: y));
      }
    case MapConnectionDirection.west:
      for (var y = 0; y < map.size.height; y += 1) {
        candidates.add(GridPos(x: 0, y: y));
      }
  }
  return candidates
      .where(
        (pos) => !world.isBlocked(
          pos.x,
          pos.y,
          movementMode: MovementMode.walk,
        ),
      )
      .toList(growable: false);
}

bool _hasAlignedPassableConnectionPair({
  required MapData sourceMap,
  required GameplayWorldState sourceWorld,
  required MapData targetMap,
  required GameplayWorldState targetWorld,
  required MapConnection connection,
}) {
  final sourceCells = _passableConnectionEdgeCells(
    connection.direction,
    sourceMap,
    sourceWorld,
  );
  for (final sourceCell in sourceCells) {
    final targetCell = resolveConnectedMapTargetPos(
      sourcePos: sourceCell,
      sourceSize: sourceMap.size,
      targetSize: targetMap.size,
      direction: connection.direction,
      offset: connection.offset,
    );
    if (targetCell != null &&
        !targetWorld.isBlocked(
          targetCell.x,
          targetCell.y,
          movementMode: MovementMode.walk,
        )) {
      return true;
    }
  }
  return false;
}

Set<int> _reachableCells({
  required MapData map,
  required GameplayWorldState world,
  required List<GridPos> starts,
  List<bool>? allowedCells,
}) {
  final reached = <int>{};
  final queue = Queue<GridPos>();
  for (final start in starts) {
    if (reached.add(_cellIndex(map, start))) {
      queue.add(start);
    }
  }
  const offsets = <GridPos>[
    GridPos(x: 0, y: -1),
    GridPos(x: 1, y: 0),
    GridPos(x: 0, y: 1),
    GridPos(x: -1, y: 0),
  ];
  while (queue.isNotEmpty) {
    final current = queue.removeFirst();
    for (final offset in offsets) {
      final next = GridPos(
        x: current.x + offset.x,
        y: current.y + offset.y,
      );
      if (!_isInBounds(map, next) ||
          (allowedCells != null && !allowedCells[_cellIndex(map, next)]) ||
          world.isBlocked(
            next.x,
            next.y,
            movementMode: MovementMode.walk,
          )) {
        continue;
      }
      if (reached.add(_cellIndex(map, next))) {
        queue.add(next);
      }
    }
  }
  return reached;
}

Set<String> _reachableMapIds(
  String start,
  Map<String, Set<String>> graph,
) {
  final reached = <String>{start};
  final queue = Queue<String>()..add(start);
  while (queue.isNotEmpty) {
    final current = queue.removeFirst();
    for (final target in graph[current] ?? const <String>{}) {
      if (reached.add(target)) {
        queue.add(target);
      }
    }
  }
  return reached;
}

bool _isInBounds(MapData map, GridPos pos) {
  return pos.x >= 0 &&
      pos.y >= 0 &&
      pos.x < map.size.width &&
      pos.y < map.size.height;
}

int _cellIndex(MapData map, GridPos pos) => pos.y * map.size.width + pos.x;

ProjectManifest _manifest(List<String> mapIds) {
  return ProjectManifest(
    name: 'Navigation contract fixture',
    maps: <ProjectMapEntry>[
      for (final mapId in mapIds)
        ProjectMapEntry(
          id: mapId,
          name: mapId,
          relativePath: 'maps/$mapId.json',
        ),
    ],
    tilesets: const <ProjectTilesetEntry>[],
    settings: const ProjectSettings(displayScale: 1),
  );
}

MapData _map(
  String id, {
  List<MapWarp> warps = const <MapWarp>[],
  List<MapConnection> connections = const <MapConnection>[],
  List<bool>? collisions,
}) {
  return MapData(
    id: id,
    name: id,
    size: const GridSize(width: 2, height: 2),
    layers: <MapLayer>[
      const MapLayer.object(id: 'objects', name: 'Objects'),
      if (collisions != null)
        MapLayer.collision(
          id: 'collision',
          name: 'Collision',
          collisions: collisions,
        ),
    ],
    warps: warps,
    connections: connections,
  );
}

final class _AnchorGroup {
  const _AnchorGroup({required this.label, required this.cells});

  final String label;
  final List<GridPos> cells;
}
