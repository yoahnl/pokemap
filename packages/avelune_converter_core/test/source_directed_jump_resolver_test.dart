import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:test/test.dart';

Sha256Hash _hash(String value) => Sha256Hash(List.filled(64, value).join());

SourceSemanticResolver _resolver({bool qualified = true}) =>
    SourceSemanticResolver(
      profile: SourceSemanticProfile.kantoPlayerWalk(
        scriptsArchiveHash: qualified
            ? Sha256Hash(SourceSemanticProfile.kantoScriptsArchiveSha256)
            : _hash('c'),
        sourceSnapshotHash: _hash('a'),
        sourceSelectionHash: _hash('b'),
      ),
    );

SourceSemanticTile _tile(int z,
        {int id = 386,
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

SourceSemanticCell _cell(int x, int y,
        {int mapId = 98,
        int width = 72,
        int height = 61,
        int passage = 0,
        int terrain = 0,
        List<SourceSemanticTile>? stack}) =>
    SourceSemanticCell(
      sourceMapId: mapId,
      x: x,
      y: y,
      width: width,
      height: height,
      stack: stack ??
          [
            _tile(2, id: 0),
            _tile(1, id: 0),
            _tile(0,
                id: terrain == 1 ? 1212 : 386,
                passage: passage,
                terrain: terrain),
          ],
    );

void main() {
  test('legal Route 9 south ledge is a two-cell static jump', () {
    final result = _resolver().resolveDirectedJump(
      _cell(64, 8),
      _cell(64, 9, passage: 7, terrain: 1),
      _cell(64, 10),
      SourceCardinalDirection.down,
    );
    expect(result.isPassable, isTrue);
    expect(result.reason, SourceDirectedJumpReason.allowed);
    expect(result.entry.direction, SourceCardinalDirection.up);
    expect(result.landingPassage.isPassable, isTrue);
    expect(result.effectiveTerrainTag, 1);
    expect(result.toJson()['eventStateQualified'], isFalse);
    expect(result.toJson()['distanceCells'], 2);
    expect(result.toJson()['from'], _cell(64, 8).toJson());
    expect(result.toJson()['landing'], _cell(64, 10).toJson());
  });

  test('north Route 9 ledge refusal precedes ledge detection', () {
    final result = _resolver().resolveDirectedJump(
      _cell(68, 21),
      _cell(68, 20, passage: 7, terrain: 1),
      _cell(68, 19),
      SourceCardinalDirection.up,
    );
    expect(result.isPassable, isFalse);
    expect(result.reason, SourceDirectedJumpReason.entryBlocked);
    expect(result.entry.reason, SourcePassageReason.directionBlocked);
  });

  for (final direction in SourceCardinalDirection.values) {
    test('jump obeys ${direction.name} departure passage', () {
      final result = _resolver().resolveDirectedJump(
        _cell(20, 20, passage: direction.bit),
        _cell(20 + direction.dx, 20 + direction.dy, terrain: 1),
        _cell(20 + 2 * direction.dx, 20 + 2 * direction.dy),
        direction,
      );
      expect(result.isPassable, isFalse);
      expect(result.reason, SourceDirectedJumpReason.exitBlocked);
    });
  }

  test('landing uses d0 rather than a reverse cardinal bit', () {
    final result = _resolver().resolveDirectedJump(
      _cell(64, 8),
      _cell(64, 9, passage: 7, terrain: 1),
      _cell(64, 10, passage: 14),
      SourceCardinalDirection.down,
    );
    expect(result.isPassable, isTrue);
    expect(result.landingPassage.toJson()['sourceDirection'], 0);
    expect(
        _resolver()
            .resolveCell(result.landing)
            .inDirection(SourceCardinalDirection.up)
            .isPassable,
        isFalse);
  });

  test('a fully blocked landing refuses the whole jump', () {
    final result = _resolver().resolveDirectedJump(
      _cell(64, 8),
      _cell(64, 9, passage: 7, terrain: 1),
      _cell(64, 10, passage: 15),
      SourceCardinalDirection.down,
    );
    expect(result.isPassable, isFalse);
    expect(result.reason, SourceDirectedJumpReason.landingBlocked);
    expect(
        result.landingPassage.reason, SourcePassageReason.allDirectionsBlocked);
  });

  test('a shadowed ledge does not produce a jump', () {
    final result = _resolver().resolveDirectedJump(
      _cell(64, 8),
      _cell(64, 9, stack: [
        _tile(2, terrain: 2, priority: 3),
        _tile(1, id: 0),
        _tile(0, terrain: 1, passage: 7),
      ]),
      _cell(64, 10),
      SourceCardinalDirection.down,
    );
    expect(result.isPassable, isFalse);
    expect(result.reason, SourceDirectedJumpReason.notLedge);
    expect(result.effectiveTerrainTag, 2);
  });

  test('effective terrain ignores priority and skips the None terrain', () {
    final result = _resolver().resolveDirectedJump(
      _cell(64, 8),
      _cell(64, 9, stack: [
        _tile(2, terrain: 0, priority: 0),
        _tile(1, terrain: 1, passage: 7, priority: 3),
        _tile(0),
      ]),
      _cell(64, 10),
      SourceCardinalDirection.down,
    );
    expect(result.isPassable, isTrue);
    expect(result.terrainTrace.map((step) => step.tile.sourceZ), [2, 1]);
    expect(result.terrainTrace.first.reason, SourceTerrainTagReason.noTerrain);
    expect(result.effectiveTerrainTag, 1);
  });

  test('inactive bridges and ignored tags do not hide a lower ledge', () {
    final result = _resolver().resolveDirectedJump(
      _cell(64, 8),
      _cell(64, 9, stack: [
        _tile(2, terrain: 15, passage: 15),
        _tile(1, terrain: 13, passage: 15),
        _tile(0, terrain: 1, passage: 7),
      ]),
      _cell(64, 10),
      SourceCardinalDirection.down,
    );
    expect(result.isPassable, isTrue);
    expect(result.terrainTrace.map((step) => step.reason), [
      SourceTerrainTagReason.inactiveBridge,
      SourceTerrainTagReason.ignoredTerrain,
      SourceTerrainTagReason.effectiveTerrain,
    ]);
  });

  test('unknown effective terrain below passable None remains unqualified', () {
    final result = _resolver().resolveDirectedJump(
      _cell(64, 8),
      _cell(64, 9, stack: [
        _tile(2, terrain: 0),
        _tile(1, terrain: 99),
        _tile(0, terrain: 1),
      ]),
      _cell(64, 10),
      SourceCardinalDirection.down,
    );
    expect(result.isPassable, isNull);
    expect(result.reason, SourceDirectedJumpReason.terrainUnqualified);
    expect(result.terrainTrace.last.reason,
        SourceTerrainTagReason.unknownTerrainTag);
  });

  test('missing landing metadata is never replaced by a free native cell', () {
    final result = _resolver().resolveDirectedJump(
      _cell(64, 8),
      _cell(64, 9, passage: 7, terrain: 1),
      _cell(64, 10, stack: [
        _tile(2, passage: null),
        _tile(1, id: 0),
        _tile(0),
      ]),
      SourceCardinalDirection.down,
    );
    expect(result.isPassable, isNull);
    expect(result.reason, SourceDirectedJumpReason.landingUnqualified);
  });

  test('a two-cell jump cannot cross a map boundary', () {
    final result = _resolver().resolveDirectedJump(
      _cell(64, 8),
      _cell(64, 9, passage: 7, terrain: 1),
      _cell(64, 10, mapId: 100),
      SourceCardinalDirection.down,
    );
    expect(result.isPassable, isNull);
    expect(result.reason, SourceDirectedJumpReason.crossMapJump);
  });

  test('noncontiguous landing and mismatched dimensions are not admitted', () {
    for (final landing in [_cell(64, 11), _cell(64, 10, width: 73)]) {
      final result = _resolver().resolveDirectedJump(
        _cell(64, 8),
        _cell(64, 9, passage: 7, terrain: 1),
        landing,
        SourceCardinalDirection.down,
      );
      expect(result.isPassable, isNull);
      expect(result.reason, SourceDirectedJumpReason.invalidGeometry);
    }
  });

  test('out-of-bounds landing is a qualified refusal', () {
    final result = _resolver().resolveDirectedJump(
      _cell(64, 59),
      _cell(64, 60, passage: 7, terrain: 1),
      _cell(64, 61),
      SourceCardinalDirection.down,
    );
    expect(result.isPassable, isFalse);
    expect(result.reason, SourceDirectedJumpReason.outOfBounds);
  });

  test('an unattested source cannot certify a directed jump', () {
    final result = _resolver(qualified: false).resolveDirectedJump(
      _cell(64, 8),
      _cell(64, 9, passage: 7, terrain: 1),
      _cell(64, 10),
      SourceCardinalDirection.down,
    );
    expect(result.isPassable, isNull);
    expect(result.reason, SourceDirectedJumpReason.unqualifiedProfile);
  });

  test('unsupported actor contexts never become native jump permissions', () {
    for (final context in [
      const SourceSemanticContext(actorWidth: 2),
      const SourceSemanticContext(actorHeight: 2),
      const SourceSemanticContext(bridgeLevel: 1),
      const SourceSemanticContext(mode: SourceMovementMode.surf),
    ]) {
      final result = _resolver().resolveDirectedJump(
        _cell(64, 8),
        _cell(64, 9, passage: 7, terrain: 1),
        _cell(64, 10),
        SourceCardinalDirection.down,
        context: context,
      );
      expect(result.isPassable, isNull);
      expect(result.reason, SourceDirectedJumpReason.unsupportedContext);
    }
  });

  test('qualified jump does not change ordinary cardinal ledge permission', () {
    final resolver = _resolver();
    final from = _cell(64, 8);
    final via = _cell(64, 9, passage: 7, terrain: 1);
    expect(
        resolver
            .resolveDirectedJump(
                from, via, _cell(64, 10), SourceCardinalDirection.down)
            .isPassable,
        isTrue);
    expect(
        resolver
            .resolveTransition(from, via, SourceCardinalDirection.down)
            .isPassable,
        isNull);
  });
}
