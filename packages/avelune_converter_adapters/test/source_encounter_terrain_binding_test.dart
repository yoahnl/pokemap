import 'dart:convert';
import '../../avelune_converter_core/test/support/interpretation_profile_fixture.dart';

import 'package:avelune_converter_adapters/src/source_encounter_terrain_binding.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import 'support/literal_tile_fixture.dart';

void main() {
  for (final offset in [false, true]) {
    test('terrain target characterization offset=$offset', () async {
      final source = await _source(offsetTerrain: offset);
      final result = _bind(source, [
        'Land',
        'Cave',
        'Water',
        'OldRod',
        'GoodRod',
        'SuperRod',
        'RockSmash'
      ]);
      final evidence = Map<String, Object?>.from(result.evidence)
        ..remove('version');
      evidence['maps'] = [
        for (final raw in result.evidence['maps'] as List)
          Map<String, Object?>.from(raw as Map)
            ..removeWhere((key, _) => _evidenceCellKeys.contains(key))
      ];
      expect(
          canonicalHashOf({
            'evidence': evidence,
            'zones': {
              for (final entry in result.zonesBySourceMapId.entries)
                '${entry.key}': jsonDecode(jsonEncode(
                    entry.value.map((zone) => zone.toJson()).toList()))
            }
          }).value,
          offset
              ? 'd8d29814ae743e6f012b02e650785c51d7faa69e22c5816d4b5f8737c99aa1eb'
              : '7cfd21b412a113cd221a80618f9f6458d7ba2d82c0325d45c2d55a102d79fc10');
    });
  }

  final patterns = {
    'dense': List.generate(3, (_) => List.filled(4, 385)),
    'sparse': [
      [385, 384, 385, 386, 388],
      [388, 386, 384, 385, 384],
    ],
    'holes and multiple rows': [
      [386, 386, 384, 386, 388],
      [386, 384, 386, 386, 388],
      [385, 385, 384, 385, 388],
    ],
    'empty sets': [List.filled(4, 387)],
  };
  for (final pattern in patterns.entries) {
    test('row run terrain evidence round trips ${pattern.key} in exact order',
        () async {
      final source = await _source(terrainRows: pattern.value);
      final result = _bind(source, []);
      expect(result.evidence['version'], 2);
      final map = (result.evidence['maps'] as List).single as Map;
      for (final key in _evidenceCellKeys) {
        final expected = [
          for (var y = 0; y < pattern.value.length; y++)
            for (var x = 0; x < pattern.value[y].length; x++)
              if (switch (key) {
                'landCells' => pattern.value[y][x] == 385,
                'caveCells' => {384, 385}.contains(pattern.value[y][x]),
                'waterCells' => pattern.value[y][x] == 386,
                _ => pattern.value[y][x] == 388,
              })
                {'x': x, 'y': y}
        ];
        expect(_decodeEvidenceCells(map[key]), expected);
      }
      expect(canonicalJsonOf(result.evidence),
          canonicalJsonOf(_bind(source, []).evidence));
      if (pattern.key == 'dense') {
        expect(map['landCells'], {
          'encoding': 'rowRuns',
          'count': 12,
          'runs': [
            [0, 0, 4],
            [1, 0, 4],
            [2, 0, 4]
          ]
        });
      }
    });
  }

  test('large dense evidence fits the same node quota without losing cells',
      () async {
    final source = await _source(
        terrainRows: List.generate(128, (_) => List.filled(128, 385)));
    final evidence = _bind(source, []).evidence;
    final maps = evidence['maps'] as List;
    expect((maps.single as Map)['landCells'], isA<Map>());
    final raw = {
      ...evidence,
      'version': 1,
      'maps': [
        for (final entry in maps)
          {
            ...entry as Map,
            for (final key in _evidenceCellKeys)
              key: _decodeEvidenceCells(entry[key])
          }
      ]
    };
    const limits = ContractLimits(maxNodes: 10000);
    expect(
        () => canonicalJsonOf(raw, limits: limits),
        throwsA(isA<ContractError>()
            .having((error) => error.code, 'code', 'json.quota')));
    expect(() => canonicalJsonOf(evidence, limits: limits), returnsNormally);
    expect(_nodes(evidence), lessThan(_nodes(raw) ~/ 10));
    expect(utf8.encode(jsonEncode(evidence)).length,
        lessThan(utf8.encode(jsonEncode(raw)).length));
    expect(_decodeEvidenceCells((maps.single as Map)['landCells']),
        hasLength(16384));
  });

  test('terrain skips empty, neutral and inactive bridge before grass', () {
    final resolver = SourceEncounterTerrainResolver(resolver: _resolver());
    expect(
        resolver.resolveTerrainTag(_cell([
          _tile(2, terrain: 13),
          _tile(1, terrain: 15),
          _tile(0, terrain: 2),
        ])),
        2);
  });

  test('None ground does not hide lower grass but a significant tag does', () {
    final resolver = SourceEncounterTerrainResolver(resolver: _resolver());
    expect(
        resolver.resolveTerrainTag(_cell([
          _tile(2, terrain: 0),
          _tile(1, terrain: 2),
          _tile(0, terrain: 4)
        ])),
        2);
    expect(
        resolver.resolveTerrainTag(
            _cell([_tile(2, terrain: 4), _tile(1, terrain: 2), _tile(0)])),
        4);
    expect(
        resolver.resolveTerrainTag(
            _cell([_tile(2, terrain: 18), _tile(1, terrain: 2), _tile(0)])),
        isNull);
    expect(
        resolver.resolveTerrainTag(
            _cell([_tile(2, terrain: 2), _tile(1), _tile(0)]),
            context: const SourceSemanticContext(bridgeLevel: 1)),
        isNull);
  });

  test('surf union opens audited water while preserving obstruction above', () {
    final resolver = SourceEncounterTerrainResolver(resolver: _resolver());
    final ground = _cell([_tile(2, id: 0), _tile(1, id: 0), _tile(0)]);
    final water = _cell(
        [_tile(2, id: 0), _tile(1, id: 0), _tile(0, terrain: 7, passage: 15)],
        x: 1);
    expect(
        _resolver()
            .resolveTransition(ground, water, SourceCardinalDirection.right)
            .status,
        SourcePassageStatus.blocked);
    expect(
        resolver
            .resolveWalkSurfTransition(
                ground, water, SourceCardinalDirection.right)
            .status,
        SourcePassageStatus.allowed);
    expect(resolver.resolveWalkSurfEntryTile(water).isPassable, isTrue);
    final obstructed = _cell([
      _tile(2, passage: 15, priority: 1),
      _tile(1, id: 0),
      _tile(0, terrain: 7, passage: 15)
    ], x: 1);
    expect(
        resolver
            .resolveWalkSurfTransition(
                ground, obstructed, SourceCardinalDirection.right)
            .status,
        SourcePassageStatus.blocked);
    expect(resolver.resolveWalkSurfEntryTile(obstructed).isPassable, isFalse);
  });

  test('surf union preserves unknown metadata, waterfall and nonplayer context',
      () {
    final resolver = SourceEncounterTerrainResolver(resolver: _resolver());
    final ground = _cell([_tile(2, id: 0), _tile(1, id: 0), _tile(0)]);
    for (final terrain in [8, 9, 18]) {
      final to = _cell([
        _tile(2, id: 0),
        _tile(1, id: 0),
        _tile(0, terrain: terrain, passage: 15)
      ], x: 1);
      expect(
          resolver
              .resolveWalkSurfTransition(
                  ground, to, SourceCardinalDirection.right)
              .status,
          terrain == 18
              ? SourcePassageStatus.unqualified
              : SourcePassageStatus.blocked);
    }
    final unknown = _cell([
      const SourceSemanticTile(sourceZ: 2, tileId: 390),
      _tile(1, id: 0),
      _tile(0, terrain: 7, passage: 15)
    ], x: 1);
    expect(
        resolver
            .resolveWalkSurfTransition(
                ground, unknown, SourceCardinalDirection.right)
            .status,
        SourcePassageStatus.unqualified);
    expect(
        resolver
            .resolveWalkSurfTransition(
                ground, ground, SourceCardinalDirection.right)
            .status,
        SourcePassageStatus.unqualified);
    expect(
        resolver
            .resolveWalkSurfTransition(
                ground, unknown, SourceCardinalDirection.right,
                context:
                    const SourceSemanticContext(mode: SourceMovementMode.npc))
            .status,
        SourcePassageStatus.unqualified);
  });

  for (final terrain in [8, 9]) {
    test('surf fallback cannot enter excluded terrain $terrain', () {
      final source = _resolver();
      final resolver = SourceEncounterTerrainResolver(resolver: source);
      final water = _cell([
        _tile(2, id: 0),
        _tile(1, id: 0),
        _tile(0, terrain: 7, passage: 15)
      ]);
      final excluded = _cell(
          [_tile(2, id: 0), _tile(1, id: 0), _tile(0, terrain: terrain)],
          x: 1);
      final walk = source.resolveTransition(
          water, excluded, SourceCardinalDirection.right);
      expect(walk.status, SourcePassageStatus.blocked);
      expect(
          resolver
              .resolveWalkSurfTransition(
                  water, excluded, SourceCardinalDirection.right)
              .toJson(),
          walk.toJson());
    });

    test('surf fallback cannot leave excluded terrain $terrain', () {
      final source = _resolver();
      final resolver = SourceEncounterTerrainResolver(resolver: source);
      final excluded =
          _cell([_tile(2, id: 0), _tile(1, id: 0), _tile(0, terrain: terrain)]);
      final water = _cell(
          [_tile(2, id: 0), _tile(1, id: 0), _tile(0, terrain: 7, passage: 15)],
          x: 1);
      final walk = source.resolveTransition(
          excluded, water, SourceCardinalDirection.right);
      expect(walk.status, SourcePassageStatus.blocked);
      expect(
          resolver
              .resolveWalkSurfTransition(
                  excluded, water, SourceCardinalDirection.right)
              .toJson(),
          walk.toJson());
    });

    test('source walk already allowed on terrain $terrain stays unchanged', () {
      final source = _resolver();
      final resolver = SourceEncounterTerrainResolver(resolver: source);
      final ground = _cell([_tile(2, id: 0), _tile(1, id: 0), _tile(0)]);
      final excluded = _cell(
          [_tile(2, id: 0), _tile(1, id: 0), _tile(0, terrain: terrain)],
          x: 1);
      final walk = source.resolveTransition(
          ground, excluded, SourceCardinalDirection.right);
      expect(walk.status, SourcePassageStatus.allowed);
      expect(
          resolver
              .resolveWalkSurfTransition(
                  ground, excluded, SourceCardinalDirection.right)
              .toJson(),
          walk.toJson());
    });
  }

  test(
      'surf fallback preserves ordinary ground and water transitions both ways',
      () {
    final source = _resolver();
    final resolver = SourceEncounterTerrainResolver(resolver: source);
    final water = _cell(
        [_tile(2, id: 0), _tile(1, id: 0), _tile(0, terrain: 7, passage: 15)]);
    final ground = _cell([_tile(2, id: 0), _tile(1, id: 0), _tile(0)], x: 1);
    for (final (from, to, direction) in [
      (water, ground, SourceCardinalDirection.right),
      (ground, water, SourceCardinalDirection.left)
    ]) {
      expect(source.resolveTransition(from, to, direction).status,
          SourcePassageStatus.blocked);
      expect(resolver.resolveWalkSurfTransition(from, to, direction).status,
          SourcePassageStatus.allowed);
    }
  });

  test('surf fallback preserves qualified water transitions both ways', () {
    final source = _resolver();
    final resolver = SourceEncounterTerrainResolver(resolver: source);
    final water = _cell(
        [_tile(2, id: 0), _tile(1, id: 0), _tile(0, terrain: 7, passage: 15)]);
    final otherWater = _cell(
        [_tile(2, id: 0), _tile(1, id: 0), _tile(0, terrain: 6, passage: 15)],
        x: 1);
    for (final (from, to, direction) in [
      (water, otherWater, SourceCardinalDirection.right),
      (otherWater, water, SourceCardinalDirection.left)
    ]) {
      expect(source.resolveTransition(from, to, direction).status,
          SourcePassageStatus.blocked);
      expect(resolver.resolveWalkSurfTransition(from, to, direction).status,
          SourcePassageStatus.allowed);
    }
  });

  test('Land binds only playable grass and Cave excludes water and cliffs',
      () async {
    final source = await _source();
    final result = _bind(source, ['Land', 'Cave']);
    final encounters = result.zonesBySourceMapId[9]!
        .where((zone) => zone.kind == GameplayZoneKind.encounter)
        .toList();
    final land = encounters.singleWhere(
        (zone) => zone.encounter!.encounterTableId == _tableId(source, 'Land'));
    final cave = encounters.singleWhere(
        (zone) => zone.encounter!.encounterTableId == _tableId(source, 'Cave'));
    expect(
        land.cellMask, [const GridPos(x: 0, y: 0), const GridPos(x: 4, y: 2)]);
    expect(cave.cellMask, hasLength(8));
    expect(cave.cellMask, isNot(contains(const GridPos(x: 1, y: 1))));
    final map = MapData(
        id: 'native-9',
        name: 'Test',
        size: const GridSize(width: 5, height: 3),
        gameplayZones: [land]);
    expect(
        resolveEncounterSourceAtPosition(map,
                position: const GridPos(x: 1, y: 0),
                encounterKind: EncounterKind.walk)
            .source,
        isNull);
    expect(
        resolveEncounterSourceAtPosition(map,
                position: const GridPos(x: 4, y: 2),
                encounterKind: EncounterKind.walk)
            .source
            ?.encounter
            .encounterTableId,
        _tableId(source, 'Land'));
  });

  test('all three rods and surf share exact qualified water cells', () async {
    final source = await _source();
    final result = _bind(source, ['Water', 'OldRod', 'GoodRod', 'SuperRod']);
    final encounters = result.zonesBySourceMapId[9]!
        .where((zone) => zone.kind == GameplayZoneKind.encounter)
        .toList();
    expect(encounters.map((zone) => zone.encounter!.encounterKind).toSet(), {
      EncounterKind.surf,
      EncounterKind.oldRod,
      EncounterKind.goodRod,
      EncounterKind.superRod
    });
    for (final zone in encounters) {
      expect(zone.cellMask, [
        const GridPos(x: 0, y: 0),
        const GridPos(x: 1, y: 0),
        const GridPos(x: 0, y: 1),
        const GridPos(x: 1, y: 1),
        const GridPos(x: 1, y: 2)
      ]);
    }
    final movements = result.zonesBySourceMapId[9]!
        .where((zone) => zone.kind == GameplayZoneKind.movement)
        .toList();
    final cells = <GridPos>[];
    for (final zone in movements) {
      expect(zone.cellMask, isNull);
      expect(zone.movement!.requiredMode, MovementMode.surf);
      for (var y = zone.area.pos.y;
          y < zone.area.pos.y + zone.area.size.height;
          y++) {
        for (var x = zone.area.pos.x;
            x < zone.area.pos.x + zone.area.size.width;
            x++) {
          cells.add(GridPos(x: x, y: y));
        }
      }
    }
    expect(cells.toSet(), _worldCells(encounters.first).toSet());
    expect(cells.toSet().length, cells.length);
    expect(movements, hasLength(2));
  });

  test(
      'Surf requirement excludes walkable overlays while preserving water family',
      () async {
    final fixture = await LiteralTileFixture.create(
        scriptsBytes: syntheticInterpretationArchive,
        interpretationProfile: fixtureSourceInterpretationProfile,
        maps: [
          LiteralFixtureMap(id: 9, width: 9, height: 1, layers: [
            [386, 386, 386, 386, 386, 386, 386, 392, 386],
            [384, 0, 387, 388, 389, 390, 391, 0, 393],
            List.filled(9, 0)
          ])
        ],
        tilesets: [
          LiteralFixtureTileset(
              id: 1,
              passages: {386: 15, 387: 15, 388: 1, 391: 15, 392: 0, 393: 8},
              priorities: {390: 1},
              terrainTags: {386: 7, 389: 15, 391: 13, 392: 7})
        ]);
    final source = fixture.source;
    final semantic = SourceSemanticResolver.forProject(source);
    final terrain = SourceEncounterTerrainResolver(resolver: semantic);
    final result = _bind(source, ['Water', 'OldRod', 'GoodRod', 'SuperRod']);
    final movementCells = {
      for (final zone in result.zonesBySourceMapId[9]!)
        if (zone.kind == GameplayZoneKind.movement)
          for (var y = zone.area.pos.y;
              y < zone.area.pos.y + zone.area.size.height;
              y++)
            for (var x = zone.area.pos.x;
                x < zone.area.pos.x + zone.area.size.width;
                x++)
              GridPos(x: x, y: y)
    };
    expect(movementCells, {
      const GridPos(x: 1, y: 0),
      const GridPos(x: 4, y: 0),
      const GridPos(x: 5, y: 0),
      const GridPos(x: 6, y: 0)
    });
    for (var x = 0; x < 9; x++) {
      final cell = semantic.cellAt(9, x, 0);
      expect(terrain.resolveTerrainTag(cell), 7);
      expect(semantic.resolveConnectionEntryTile(cell).isPassable,
          {0, 3, 7, 8}.contains(x));
      expect(terrain.resolveSurfEntryTile(cell).isPassable, x != 2);
    }
    for (final zone in result.zonesBySourceMapId[9]!
        .where((zone) => zone.kind == GameplayZoneKind.encounter)) {
      expect(_worldCells(zone), [
        for (var x = 0; x < 9; x++)
          if (x != 2) GridPos(x: x, y: 0)
      ]);
    }
    final row = (result.evidence['maps'] as List).single as Map;
    expect(_decodeEvidenceCells(row['waterCells']), [
      for (var x = 0; x < 9; x++)
        if (x != 2) {'x': x, 'y': 0}
    ]);
    for (final x in [3, 7, 8]) {
      final passage = semantic.resolveCell(semantic.cellAt(9, x, 0));
      expect(
          passage.allowedMask,
          x == 7
              ? 15
              : x == 8
                  ? 7
                  : 14);
      expect(
          passage.blockedMask,
          x == 7
              ? 0
              : x == 8
                  ? 8
                  : 1);
    }
  });

  for (final passage in [1, 8]) {
    test('Water passage $passage refuses mode-specific directional admission',
        () async {
      final fixture = await LiteralTileFixture.create(
          scriptsBytes: syntheticInterpretationArchive,
          interpretationProfile: fixtureSourceInterpretationProfile,
          maps: [
            LiteralFixtureMap(id: 9, width: 3, height: 2, layers: [
              [384, 384, 384, 384, 384, 386],
              List.filled(6, 0),
              List.filled(6, 0)
            ])
          ],
          tilesets: [
            LiteralFixtureTileset(
                id: 1, passages: {386: passage}, terrainTags: {386: 7})
          ]);
      final source = fixture.source;
      final semantic = SourceSemanticResolver.forProject(source);
      final cell = semantic.cellAt(9, 2, 1);
      expect(semantic.resolveConnectionEntryTile(cell).isPassable, isTrue);
      expect(semantic.resolveCell(cell).blockedMask, passage);
      expect(
          () => _bind(source, []),
          throwsA(isA<ContractError>()
              .having((error) => error.code, 'code',
                  'source_encounter_terrain.mode_specific_passage_unqualified')
              .having((error) => error.path, 'path', r'$.maps.9.cells[1][2]')));
    });
  }

  test('every generated zone passes canonical cell mask validation', () async {
    final source = await _source();
    final result = _bind(source, [
      'Land',
      'Cave',
      'Water',
      'OldRod',
      'GoodRod',
      'SuperRod',
      'RockSmash'
    ]);
    for (final zone in result.zonesBySourceMapId[9]!) {
      expect(() => validateGameplayZoneCellMask(zone), returnsNormally);
    }
  });

  test('nonzero origin keeps local mask and exact world encounter coverage',
      () async {
    final source = await _source(offsetTerrain: true);
    final result = _bind(source, ['Water']);
    final zone = result.zonesBySourceMapId[9]!
        .singleWhere((zone) => zone.kind == GameplayZoneKind.encounter);
    expect(zone.area.pos, const GridPos(x: 2, y: 2));
    expect(zone.cellMask, [
      const GridPos(x: 0, y: 0),
      const GridPos(x: 1, y: 0),
      const GridPos(x: 0, y: 1)
    ]);
    final worldCells = [
      const GridPos(x: 2, y: 2),
      const GridPos(x: 3, y: 2),
      const GridPos(x: 2, y: 3)
    ];
    expect(_worldCells(zone), worldCells);
    final evidence = (result.evidence['maps'] as List).single as Map;
    final encounter = (evidence['encounterZones'] as List).single as Map;
    expect(encounter['cells'], [
      {'x': 2, 'y': 2},
      {'x': 3, 'y': 2},
      {'x': 2, 'y': 3}
    ]);
    final identity = Map<String, Object?>.from(encounter)..remove('zone');
    expect(zone.id,
        'source-encounter-terrain-${canonicalHashOf(identity).value.substring(0, 24)}');
    final map = addGameplayZoneToMap(
        MapData(
            id: 'native-9',
            name: 'Offset water',
            size: const GridSize(width: 6, height: 5)),
        zone: zone);
    for (var y = 0; y < map.size.height; y++) {
      for (var x = 0; x < map.size.width; x++) {
        final position = GridPos(x: x, y: y);
        final expected = worldCells.contains(position);
        expect(gameplayZoneContainsPosition(zone, position), expected);
        expect(
            resolveEncounterSourceAtPosition(map,
                    position: position, encounterKind: EncounterKind.surf)
                .source
                ?.encounter
                .encounterTableId,
            expected ? _tableId(source, 'Water') : null);
      }
    }
  });

  test('bindings and evidence are deterministic, JSON inert and source bound',
      () async {
    final source = await _source();
    final a = _bind(source, ['Land', 'Water']);
    final b = _bind(source, ['Water', 'Land']);
    expect(jsonEncode(a.evidence), jsonEncode(b.evidence));
    expect(a.zonesBySourceMapId, b.zonesBySourceMapId);
    expect(a.evidence['sourceSelectionHash'], source.canonicalHash.value);
    expect(() => canonicalHashOf(a.evidence), returnsNormally);
    expect(a.evidence.containsKey('runtimeQualified'), isFalse);
  });

  for (final method in ['LandDay', 'LandNight', 'LandMorning']) {
    for (final includeLand in [false, true]) {
      test(
          'rejects unqualified $method${includeLand ? ' mixed with Land' : ''}',
          () async {
        final source = await _source();
        final methods = [if (includeLand) 'Land', method];
        expect(
            () => _bind(source, methods),
            throwsA(isA<ContractError>()
                .having((error) => error.code, 'code',
                    'source_encounter_terrain.time_method_unqualified')
                .having((error) => error.path, 'path',
                    '\$.tableIdsBySourceMethod.9.$method')));
      });
    }
  }

  test('RockSmash remains bound as interactive evidence without a terrain zone',
      () async {
    final source = await _source();
    final result = _bind(source, ['RockSmash']);
    expect(
        result.zonesBySourceMapId[9]!
            .where((zone) => zone.kind == GameplayZoneKind.encounter),
        isEmpty);
    expect(result.evidence['ignoredInteractiveMethods'], [
      {
        'sourceMapId': 9,
        'nativeMapId': 'native-9',
        'method': 'RockSmash',
        'nativeTableId': _tableId(source, 'RockSmash')
      }
    ]);
  });

  test('rejects unattested scripts, wrong source hash and foreign references',
      () async {
    final source = await _source();
    expect(SourceSemanticResolver.forProject(source).profile.isQualified, isTrue);
    final scripts = source.snapshot.entries.singleWhere(
        (entry) => entry.relativePath == 'Data/Scripts.rxdata');
    expect(scripts.byteLength, syntheticInterpretationArchive.length);
    expect(scripts.sha256, literalFixtureHash(syntheticInterpretationArchive));
    for (final tableIds in [
      {
        9: {'Land': 'wrong-table'}
      },
      {
        10: {'Land': _tableId(source, 'Land')}
      },
      {
        9: {'WrongMethod': _tableId(source, 'Land')}
      },
    ]) {
      expect(
          () => const SourceEncounterTerrainBinding().bind(
              source: source,
              nativeMapIds: {9: 'native-9'},
              tableIdsBySourceMethod: tableIds),
          throwsA(isA<Exception>()));
    }
    expect(
        () => const SourceEncounterTerrainBinding().bind(
            source: source,
            nativeMapIds: {10: 'native-10'},
            tableIdsBySourceMethod: {}),
        throwsA(isA<Exception>()));
    expect(
        () => const SourceEncounterTerrainBinding().bind(
            source: source,
            nativeMapIds: {9: 'native-9'},
            tableIdsBySourceMethod: {},
            expectedSourceSelectionHash: Sha256Hash('e' * 64)),
        throwsA(isA<Exception>()));
    final unattested = await _source(qualified: false);
    expect(SourceSemanticResolver.forProject(unattested).profile.isQualified,
        isFalse);
    expect(() => _bind(unattested, ['Land']),
        throwsA(isA<FormatException>().having((error) => error.message,
            'message', 'Encounter terrain requires its attested source selection')));
  });
}

SourceEncounterTerrainBindingResult _bind(
        NormalizedSourceProject source, List<String> methods) =>
    const SourceEncounterTerrainBinding().bind(source: source, nativeMapIds: {
      9: 'native-9'
    }, tableIdsBySourceMethod: {
      9: {for (final method in methods) method: _tableId(source, method)}
    });

String _tableId(NormalizedSourceProject source, String method) =>
    'source-native-encounter-${canonicalHashOf({
          'sourceIdentity': SourcePbsIdentity(
                  namespace: source.snapshot.logicalProjectNamespace,
                  family: SourcePbsFamily.encounters,
                  sourceMapId: 9)
              .toJson(),
          'method': method,
        }).value.substring(0, 24)}';

List<GridPos> _worldCells(MapGameplayZone zone) => [
      for (final cell in zone.cellMask!)
        GridPos(x: cell.x + zone.area.pos.x, y: cell.y + zone.area.pos.y)
    ];

Future<NormalizedSourceProject> _source(
    {bool qualified = true,
    bool offsetTerrain = false,
    List<List<int>>? terrainRows}) async {
  final fixture = await LiteralTileFixture.create(
      scriptsBytes: qualified ? syntheticInterpretationArchive : const [4, 8, 48],
      interpretationProfile: qualified ? fixtureSourceInterpretationProfile : null,
      selectedMapIds: {9},
      maps: [
    if (terrainRows != null)
      LiteralFixtureMap(
          id: 9,
          width: terrainRows.first.length,
          height: terrainRows.length,
          layers: [
            terrainRows.expand((row) => row).toList(),
            List.filled(terrainRows.length * terrainRows.first.length, 0),
            List.filled(terrainRows.length * terrainRows.first.length, 0)
          ])
    else if (offsetTerrain)
      LiteralFixtureMap(id: 9, width: 6, height: 5, layers: [
        List<int>.generate(
            30, (index) => {14, 15, 20}.contains(index) ? 386 : 384),
        List.filled(30, 0),
        List.filled(30, 0)
      ])
    else
      LiteralFixtureMap(id: 9, width: 5, height: 3, layers: [
        [
          385,
          384,
          386,
          386,
          387,
          384,
          386,
          386,
          386,
          384,
          384,
          384,
          384,
          386,
          385
        ],
        List.filled(15, 0),
        [0, 0, 0, 0, 0, 0, 387, 0, 0, 0, 0, 0, 0, 0, 0]
      ])
  ], tilesets: [
    LiteralFixtureTileset(
        id: 1,
        passages: {386: 15, 387: 15},
        terrainTags: {385: 2, 386: 7, 387: 4, 388: 18})
  ]);
  return fixture.source;
}

const _evidenceCellKeys = [
  'landCells',
  'caveCells',
  'waterCells',
  'unqualifiedTerrainCells'
];

List<Map<String, int>> _decodeEvidenceCells(Object? value) {
  final encoded = value as Map;
  expect(encoded['encoding'], 'rowRuns');
  final cells = <Map<String, int>>[];
  for (final run in encoded['runs'] as List) {
    final triple = (run as List).cast<int>();
    expect(triple, hasLength(3));
    expect(triple[2], greaterThan(0));
    for (var x = triple[1]; x < triple[1] + triple[2]; x++) {
      cells.add({'x': x, 'y': triple[0]});
    }
  }
  expect(cells.length, encoded['count']);
  return cells;
}

int _nodes(Object? value) => switch (value) {
      Map() =>
        1 + value.values.fold<int>(0, (sum, child) => sum + _nodes(child)),
      List() => 1 + value.fold<int>(0, (sum, child) => sum + _nodes(child)),
      _ => 1,
    };

SourceSemanticResolver _resolver() => SourceSemanticResolver(
        profile: SourceSemanticProfile(
      scriptsArchiveHash: Sha256Hash(
          fixtureSourceInterpretationProfile.scriptsArchiveHash.value),
      sourceSnapshotHash: Sha256Hash('a' * 64),
      sourceSelectionHash: Sha256Hash('b' * 64),
      interpretationProfile: fixtureSourceInterpretationProfile,
    ));

SourceSemanticTile _tile(int z,
        {int terrain = 0, int passage = 0, int priority = 0, int id = 384}) =>
    SourceSemanticTile(
        sourceZ: z,
        tileId: id,
        terrainTag: terrain,
        passage: passage,
        priority: priority);

SourceSemanticCell _cell(List<SourceSemanticTile> stack,
        {int x = 0, int y = 0}) =>
    SourceSemanticCell(
        sourceMapId: 9, x: x, y: y, width: 3, height: 3, stack: stack);
