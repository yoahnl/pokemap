import 'dart:convert';

import 'package:avelune_converter_adapters/src/source_encounter_terrain_binding.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import 'support/literal_tile_fixture.dart';

void main() {
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
        const GridPos(x: 2, y: 0),
        const GridPos(x: 3, y: 0),
        const GridPos(x: 2, y: 1),
        const GridPos(x: 3, y: 1),
        const GridPos(x: 3, y: 2)
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
    expect(cells.toSet(), encounters.first.cellMask!.toSet());
    expect(cells.toSet().length, cells.length);
    expect(movements, hasLength(2));
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
    expect(() => _bind(unattested, ['Land']), throwsA(isA<Exception>()));
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

Future<NormalizedSourceProject> _source({bool qualified = true}) async {
  final fixture = await LiteralTileFixture.create(maps: [
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
        terrainTags: {385: 2, 386: 7, 387: 4})
  ]);
  final snapshot = SourceSnapshot(
      logicalProjectNamespace: fixture.snapshot.logicalProjectNamespace,
      policyHash: fixture.snapshot.policyHash,
      entries: [
        ...fixture.snapshot.entries,
        SourceFileEntry(
            fileId: ConverterId('fixture:scripts'),
            relativePath: 'Data/Scripts.rxdata',
            kind: SourceNodeKind.file,
            byteLength: 1,
            sha256: Sha256Hash(qualified
                ? SourceSemanticProfile.kantoScriptsArchiveSha256
                : 'e' * 64),
            format: 'ruby-marshal',
            family: 'data')
      ],
      diagnostics: [],
      excludedPaths: [],
      profileEvidence: fixture.snapshot.profileEvidence,
      state: SourceScanState.complete);
  return const RmxpSourceNormalizer().normalize(
      snapshot: snapshot,
      files: LiteralFixtureFiles(snapshot, fixture.sourceBytes),
      selectedMapIds: {9});
}

SourceSemanticResolver _resolver() => SourceSemanticResolver(
        profile: SourceSemanticProfile.kantoPlayerWalk(
      scriptsArchiveHash:
          Sha256Hash(SourceSemanticProfile.kantoScriptsArchiveSha256),
      sourceSnapshotHash: Sha256Hash('a' * 64),
      sourceSelectionHash: Sha256Hash('b' * 64),
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
