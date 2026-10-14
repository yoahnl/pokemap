import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:test/test.dart';

Sha256Hash _hash(String digit) => Sha256Hash(List.filled(64, digit).join());

SourceSemanticProfile _profile({bool qualified = true}) =>
    SourceSemanticProfile.kantoPlayerWalk(
      scriptsArchiveHash: qualified
          ? Sha256Hash(SourceSemanticProfile.kantoScriptsArchiveSha256)
          : _hash('c'),
      sourceSnapshotHash: _hash('a'),
      sourceSelectionHash: _hash('b'),
    );

SourceSemanticTile _tile(int z,
        {int id = 490,
        int? passage = 0,
        int? priority = 0,
        int? terrain = 0}) =>
    SourceSemanticTile(
      sourceZ: z,
      tileId: id,
      passage: passage,
      priority: priority,
      terrainTag: terrain,
    );

SourceSemanticCell _cell({List<SourceSemanticTile>? stack, int x = 0}) =>
    SourceSemanticCell(
      sourceMapId: 100,
      x: x,
      y: 14,
      width: 30,
      height: 85,
      stack: stack ?? [_tile(2, id: 0), _tile(1, id: 0), _tile(0)],
    );

void main() {
  final resolver = SourceSemanticResolver(profile: _profile());

  test('stationary d0 is not the union of four directional refusals', () {
    final cell = _cell(stack: [
      _tile(2, passage: 1, priority: 1),
      _tile(1, passage: 2, priority: 1),
      _tile(0, passage: 12, priority: 1),
    ]);
    expect(resolver.resolveCell(cell).blockedMask, 15);
    final stationary = resolver.resolveConnectionEntryTile(cell);
    expect(stationary.isPassable, isTrue);
    expect(stationary.reason, SourcePassageReason.stackExhausted);
  });

  test('connection entry uses source d0 rather than a reverse cardinal bit',
      () {
    for (final passage in [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14]) {
      final cell = _cell(stack: [
        _tile(2, passage: passage),
        _tile(1, id: 0),
        _tile(0, passage: 15),
      ]);
      expect(resolver.resolveConnectionEntryTile(cell).isPassable, isTrue,
          reason: 'Source d0 allows directional passage $passage');
    }
    final directional = _cell(stack: [
      _tile(2, passage: 2),
      _tile(1, id: 0),
      _tile(0),
    ]);
    expect(
        resolver
            .resolveCell(directional)
            .inDirection(SourceCardinalDirection.left)
            .isPassable,
        isFalse);
    expect(resolver.resolveConnectionEntryTile(directional).isPassable, isTrue);
  });

  test('a full low passage nibble blocks entry before ground priority', () {
    for (final passage in [15, 31, 63, 79, 143, 255]) {
      final result = resolver.resolveConnectionEntryTile(_cell(stack: [
        _tile(2, passage: passage),
        _tile(1, id: 0),
        _tile(0),
      ]));
      expect(result.isPassable, isFalse);
      expect(result.reason, SourcePassageReason.allDirectionsBlocked);
      expect(result.trace.single.tile.sourceZ, 2);
    }
  });

  test('source stack order is Z2 then Z1 then Z0 and skips empty cells', () {
    final result = resolver.resolveConnectionEntryTile(_cell(stack: [
      _tile(0),
      _tile(2, id: 0),
      _tile(1, id: 0),
    ]));
    expect(result.isPassable, isTrue);
    expect(result.trace.map((step) => step.tile.sourceZ), [2, 1, 0]);
    expect(result.trace.map((step) => step.reason), [
      SourcePassageReason.emptyTile,
      SourcePassageReason.emptyTile,
      SourcePassageReason.groundAllows,
    ]);
  });

  test('raised tiles continue to the blocking lower ground', () {
    final result = resolver.resolveConnectionEntryTile(_cell(stack: [
      _tile(2, passage: 2, priority: 3),
      _tile(1, id: 0),
      _tile(0, passage: 15),
    ]));
    expect(result.isPassable, isFalse);
    expect(result.trace.first.reason, SourcePassageReason.raisedTileContinues);
    expect(result.trace.last.tile.sourceZ, 0);
  });

  test('ground permission does not inspect shadowed lower metadata', () {
    final result = resolver.resolveConnectionEntryTile(_cell(stack: [
      _tile(2, passage: 14),
      _tile(1, terrain: 99),
      _tile(0, passage: null),
    ]));
    expect(result.isPassable, isTrue);
    expect(result.trace, hasLength(1));
  });

  test('inactive bridge and ignored terrain leave the lower layer decisive',
      () {
    final result = resolver.resolveConnectionEntryTile(_cell(stack: [
      _tile(2, terrain: 15, passage: 15),
      _tile(1, terrain: 13, passage: 15),
      _tile(0),
    ]));
    expect(result.isPassable, isTrue);
    expect(result.trace.map((step) => step.reason), [
      SourcePassageReason.inactiveBridge,
      SourcePassageReason.ignoredTerrain,
      SourcePassageReason.groundAllows,
    ]);
  });

  test('ledge tags follow d0 player tiles without inventing an NPC ledge rule',
      () {
    final result = resolver.resolveConnectionEntryTile(_cell(stack: [
      _tile(2, terrain: 1, passage: 4),
      _tile(1, id: 0),
      _tile(0),
    ]));
    expect(result.isPassable, isTrue);
    expect(result.reason, SourcePassageReason.groundAllows);
  });

  test('walking onto source water still honors its full passage refusal', () {
    final result = resolver.resolveConnectionEntryTile(_cell(stack: [
      _tile(2, terrain: 7, passage: 15),
      _tile(1, id: 0),
      _tile(0),
    ]));
    expect(result.isPassable, isFalse);
  });

  test('water terrain without a full refusal remains allowed by source d0', () {
    final result = resolver.resolveConnectionEntryTile(_cell(stack: [
      _tile(2, terrain: 7, passage: 0),
      _tile(1, id: 0),
      _tile(0),
    ]));
    expect(result.isPassable, isTrue);
    expect(result.reason, SourcePassageReason.groundAllows);
  });

  test('exhausted empty or raised stacks follow the source allow', () {
    for (final stack in [
      [_tile(2, id: 0), _tile(1, id: 0), _tile(0, id: 0)],
      [_tile(2, priority: 1), _tile(1, priority: 2), _tile(0, priority: 3)],
    ]) {
      final result = resolver.resolveConnectionEntryTile(_cell(stack: stack));
      expect(result.isPassable, isTrue);
      expect(result.reason, SourcePassageReason.stackExhausted);
    }
  });

  test('missing or invalid metadata stays unqualified', () {
    for (final tile in [
      _tile(2, passage: null),
      _tile(2, passage: -1),
      _tile(2, passage: 256),
      _tile(2, priority: null),
      _tile(2, priority: -1),
      _tile(2, priority: 6),
      _tile(2, terrain: null),
      _tile(2, terrain: -1),
      _tile(2, id: -1),
    ]) {
      final result = resolver.resolveConnectionEntryTile(
          _cell(stack: [tile, _tile(1, id: 0), _tile(0)]));
      expect(result.isPassable, isNull);
      expect(result.reason, SourcePassageReason.missingMetadata);
    }
  });

  test('unknown terrain does not silently become a passable seam', () {
    final result = resolver.resolveConnectionEntryTile(_cell(stack: [
      _tile(2, terrain: 99),
      _tile(1, id: 0),
      _tile(0),
    ]));
    expect(result.isPassable, isNull);
    expect(result.reason, SourcePassageReason.unknownTerrainTag);
  });

  test('unsupported movement context is never claimed equivalent', () {
    for (final context in [
      const SourceSemanticContext(mode: SourceMovementMode.surf),
      const SourceSemanticContext(mode: SourceMovementMode.cycling),
      const SourceSemanticContext(mode: SourceMovementMode.npc),
      const SourceSemanticContext(bridgeLevel: 1),
      const SourceSemanticContext(actorWidth: 2),
      const SourceSemanticContext(actorHeight: 2),
    ]) {
      final result =
          resolver.resolveConnectionEntryTile(_cell(), context: context);
      expect(result.isPassable, isNull);
      expect(result.reason, SourcePassageReason.unsupportedContext);
    }
  });

  test('out of map bounds blocks the source connection destination', () {
    for (final x in [-1, 30]) {
      final result = resolver.resolveConnectionEntryTile(_cell(x: x));
      expect(result.isPassable, isFalse);
      expect(result.reason, SourcePassageReason.outOfBounds);
    }
  });

  test('an unattested archive cannot qualify connection entry', () {
    final result = SourceSemanticResolver(profile: _profile(qualified: false))
        .resolveConnectionEntryTile(_cell());
    expect(result.isPassable, isNull);
    expect(result.reason, SourcePassageReason.unqualifiedProfile);
  });

  test('evidence binds the exact source cell and does not claim event parity',
      () {
    final result = resolver.resolveConnectionEntryTile(_cell());
    final evidence = result.toJson();
    expect(evidence['sourceDirection'], 0);
    expect(evidence['directionBit'], 0);
    expect(evidence['scope'], 'destinationStaticTiles');
    expect(evidence['eventStateQualified'], isFalse);
    expect(evidence['profile'], _profile().toJson());
    expect(evidence['cell'], _cell().toJson());
    expect(evidence['oracle'], contains('PokemonMapFactory'));
    expect(() => result.trace.clear(), throwsUnsupportedError);
  });
}
