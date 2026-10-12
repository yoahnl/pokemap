import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:test/test.dart';

Sha256Hash _hash(String digit) => Sha256Hash(List.filled(64, digit).join());

SourceSemanticProfile _profile({String? scriptsHash, String selection = 'b'}) =>
    SourceSemanticProfile.kantoPlayerWalk(
      scriptsArchiveHash: Sha256Hash(
          scriptsHash ?? SourceSemanticProfile.kantoScriptsArchiveSha256),
      sourceSnapshotHash: _hash('a'),
      sourceSelectionHash: _hash(selection),
    );

SourceSemanticTile _tile(int z,
        {int id = 384,
        int? passage = 0,
        int? priority = 0,
        int? terrain = 0}) =>
    SourceSemanticTile(
        sourceZ: z,
        tileId: id,
        passage: passage,
        priority: priority,
        terrainTag: terrain);

SourceSemanticCell _cell(
        {int map = 9,
        int x = 1,
        int y = 1,
        int width = 4,
        int height = 4,
        List<SourceSemanticTile>? stack}) =>
    SourceSemanticCell(
        sourceMapId: map,
        x: x,
        y: y,
        width: width,
        height: height,
        stack: stack ?? [_tile(2, id: 0), _tile(1, id: 0), _tile(0)]);

void main() {
  final resolver = SourceSemanticResolver(profile: _profile());

  group('qualified source profile', () {
    test('only the audited script archive qualifies player walking', () {
      expect(_profile().isQualified, isTrue);
      expect(_profile(scriptsHash: _hash('c').value).isQualified, isFalse);
      expect(
          SourceSemanticProfile.kantoPlayerWalk(
                  scriptsArchiveHash: null,
                  sourceSnapshotHash: _hash('a'),
                  sourceSelectionHash: _hash('b'))
              .isQualified,
          isFalse);
    });

    test('profile hash binds snapshot and selection with explicit context', () {
      expect(_profile().canonicalHash,
          isNot(_profile(selection: 'c').canonicalHash));
      final result = resolver.resolveCell(_cell());
      expect(
          result.toJson()['context'], containsPair('scope', 'staticMapTiles'));
      expect(result.context.mode, SourceMovementMode.playerWalk);
      expect(result.context.bridgeLevel, 0);
      expect(result.profile.sourceSnapshotHash, _hash('a'));
    });

    test('an unattested script archive returns unknown, never false or true',
        () {
      final result = SourceSemanticResolver(
              profile: _profile(scriptsHash: _hash('c').value))
          .resolveCell(_cell());
      expect(result.unqualifiedMask, 15);
      expect(
          result.inDirection(SourceCardinalDirection.down).isPassable, isNull);
      expect(result.inDirection(SourceCardinalDirection.down).reason,
          SourcePassageReason.unqualifiedProfile);
    });
  });

  group('source layer passage', () {
    test('orders Z2 to Z0 and skips zero tiles', () {
      final result = resolver.resolveCell(
          _cell(stack: [_tile(0), _tile(2, id: 0), _tile(1, id: 0)]));
      expect(result.allowedMask, 15);
      expect(result.blockedMask, 0);
      expect(
          result
              .inDirection(SourceCardinalDirection.down)
              .trace
              .map((step) => step.tile.sourceZ),
          [2, 1, 0]);
      expect(
          result
              .inDirection(SourceCardinalDirection.down)
              .trace
              .map((step) => step.reason),
          [
            SourcePassageReason.emptyTile,
            SourcePassageReason.emptyTile,
            SourcePassageReason.groundAllows
          ]);
    });

    test('empty stacks follow the oracle exhausted-stack allow', () {
      final result = resolver.resolveCell(
          _cell(stack: [_tile(2, id: 0), _tile(1, id: 0), _tile(0, id: 0)]));
      expect(result.allowedMask, 15);
      expect(result.inDirection(SourceCardinalDirection.up).reason,
          SourcePassageReason.stackExhausted);
    });

    test('all four source bits retain their cardinal meaning', () {
      for (final direction in SourceCardinalDirection.values) {
        final result = resolver.resolveCell(_cell(stack: [
          _tile(2, passage: direction.bit, priority: 0),
          _tile(1, id: 0),
          _tile(0)
        ]));
        expect(result.blockedMask, direction.bit);
        expect(result.allowedMask, 15 ^ direction.bit);
        expect(result.inDirection(direction).isPassable, isFalse);
        expect(direction.sourceValue + direction.reverse.sourceValue, 10);
      }
    });

    test('a directional refusal precedes ground priority zero', () {
      final result = resolver.resolveCell(_cell(stack: [
        _tile(2, passage: 4, priority: 0),
        _tile(1, passage: 0),
        _tile(0)
      ]));
      expect(result.inDirection(SourceCardinalDirection.right).reason,
          SourcePassageReason.directionBlocked);
      expect(result.inDirection(SourceCardinalDirection.right).trace,
          hasLength(1));
    });

    test('all-directions refusal remains false with priority zero', () {
      final result = resolver.resolveCell(
          _cell(stack: [_tile(2, passage: 15), _tile(1, id: 0), _tile(0)]));
      expect(result.blockedMask, 15);
      expect(result.inDirection(SourceCardinalDirection.up).reason,
          SourcePassageReason.allDirectionsBlocked);
    });

    test('a raised tile passes evaluation down to the blocking ground', () {
      final result = resolver.resolveCell(_cell(stack: [
        _tile(2, passage: 0, priority: 3),
        _tile(1, id: 0),
        _tile(0, passage: 15)
      ]));
      expect(result.blockedMask, 15);
      expect(
          result.inDirection(SourceCardinalDirection.down).trace.first.reason,
          SourcePassageReason.raisedTileContinues);
    });

    test('a ground allow stops before shadowed lower metadata', () {
      final result = resolver.resolveCell(_cell(
          stack: [_tile(2), _tile(1, terrain: 99), _tile(0, passage: 15)]));
      expect(result.allowedMask, 15);
      expect(
          result.inDirection(SourceCardinalDirection.down).trace, hasLength(1));
      expect(result.rawTerrainTags, [0, 99, 0]);
    });

    test('neutral and inactive bridge layers never overrule underlying ground',
        () {
      final result = resolver.resolveCell(_cell(stack: [
        _tile(2, passage: 15, terrain: 13),
        _tile(1, passage: 15, terrain: 15),
        _tile(0)
      ]));
      expect(result.allowedMask, 15);
      expect(
          result
              .inDirection(SourceCardinalDirection.down)
              .trace
              .map((step) => step.reason),
          [
            SourcePassageReason.ignoredTerrain,
            SourcePassageReason.inactiveBridge,
            SourcePassageReason.groundAllows
          ]);
    });

    test('unknown tags and absent passage metadata remain unqualified', () {
      for (final tile in [
        _tile(2, terrain: 99),
        _tile(2, passage: null),
        _tile(2, priority: null),
        _tile(2, terrain: null)
      ]) {
        final result = resolver
            .resolveCell(_cell(stack: [tile, _tile(1, id: 0), _tile(0)]));
        expect(result.unqualifiedMask, 15);
        expect(result.allowedMask, 0);
      }
    });

    test('negative or invalid source metadata remains unqualified', () {
      for (final tile in [
        _tile(2, passage: -1),
        _tile(2, passage: 256),
        _tile(2, priority: -1),
        _tile(2, priority: 6),
        _tile(2, terrain: -1)
      ]) {
        expect(
            resolver
                .resolveCell(_cell(stack: [tile, _tile(1, id: 0), _tile(0)]))
                .unqualifiedMask,
            15);
      }
    });

    test('all registered nonledge terrain tags keep the normal walk rule', () {
      for (var terrain = 0; terrain <= 17; terrain++) {
        if (terrain == 1 || terrain == 13 || terrain == 15) continue;
        expect(
            resolver
                .resolveCell(_cell(stack: [
                  _tile(2, terrain: terrain),
                  _tile(1, id: 0),
                  _tile(0)
                ]))
                .allowedMask,
            15);
      }
    });

    test('bush counter and raw terrain metadata survive independently', () {
      final result = resolver.resolveCell(_cell(stack: [
        _tile(2, passage: 0x40, priority: 3, terrain: 2),
        _tile(1, passage: 0x80, priority: 1, terrain: 3),
        _tile(0, terrain: 10)
      ]));
      expect(result.allowedMask, 15);
      expect(result.bush, isTrue);
      expect(result.counter, isTrue);
      expect(result.rawTerrainTags, [2, 3, 10]);
      expect(() => result.directions.add(result.directions.first),
          throwsUnsupportedError);
      expect(
          () => result.directions.first.trace.clear(), throwsUnsupportedError);
      expect(() => result.cell.stack.clear(), throwsUnsupportedError);
      expect(() => result.rawTerrainTags.add(12), throwsUnsupportedError);
    });

    test('ledge movement is an explicit gameplay gap', () {
      final result = resolver.resolveCell(
          _cell(stack: [_tile(2, terrain: 1), _tile(1, id: 0), _tile(0)]));
      expect(result.unqualifiedMask, 15);
      expect(result.inDirection(SourceCardinalDirection.down).reason,
          SourcePassageReason.ledgeRequiresGameplay);
    });

    test('unsupported movement contexts never fabricate normal walk results',
        () {
      for (final mode in SourceMovementMode.values
          .where((mode) => mode != SourceMovementMode.playerWalk)) {
        final result = resolver.resolveCell(_cell(),
            context: SourceSemanticContext(mode: mode));
        expect(result.unqualifiedMask, 15);
        expect(result.inDirection(SourceCardinalDirection.down).reason,
            SourcePassageReason.unsupportedContext);
      }
      for (final context in [
        const SourceSemanticContext(bridgeLevel: 1),
        const SourceSemanticContext(actorWidth: 2),
        const SourceSemanticContext(actorHeight: 2)
      ]) {
        expect(resolver.resolveCell(_cell(), context: context).unqualifiedMask,
            15);
      }
    });
  });

  group('source and destination transition', () {
    test('requires the exit bit and the inverse entry bit', () {
      final from = _cell();
      final to = _cell(
          x: 2,
          stack: [_tile(2, id: 0), _tile(1, id: 0), _tile(0, passage: 2)]);
      final result =
          resolver.resolveTransition(from, to, SourceCardinalDirection.right);
      expect(result.exit.status, SourcePassageStatus.allowed);
      expect(result.entry.direction, SourceCardinalDirection.left);
      expect(result.entry.status, SourcePassageStatus.blocked);
      expect(result.isPassable, isFalse);
    });

    test('static normal cardinal transitions are reciprocal', () {
      for (var sourceMask = 0; sourceMask < 16; sourceMask++) {
        for (var destinationMask = 0; destinationMask < 16; destinationMask++) {
          final from = _cell(stack: [
            _tile(2, id: 0),
            _tile(1, id: 0),
            _tile(0, passage: sourceMask)
          ]);
          final to = _cell(x: 2, stack: [
            _tile(2, id: 0),
            _tile(1, id: 0),
            _tile(0, passage: destinationMask)
          ]);
          final forward = resolver.resolveTransition(
              from, to, SourceCardinalDirection.right);
          final reverse = resolver.resolveTransition(
              to, from, SourceCardinalDirection.left);
          expect(forward.status, reverse.status);
          expect(forward.isPassable,
              (sourceMask & 4) == 0 && (destinationMask & 2) == 0);
        }
      }
    });

    test('blocked exits remain a proved refusal despite unknown destinations',
        () {
      final from =
          _cell(stack: [_tile(2, passage: 4), _tile(1, id: 0), _tile(0)]);
      final to = _cell(
          x: 2, stack: [_tile(2, terrain: 99), _tile(1, id: 0), _tile(0)]);
      final result =
          resolver.resolveTransition(from, to, SourceCardinalDirection.right);
      expect(result.status, SourcePassageStatus.blocked);
      expect(result.entry.status, SourcePassageStatus.unqualified);
    });

    test('unknown exits with allowed entries remain unqualified', () {
      final from =
          _cell(stack: [_tile(2, terrain: 99), _tile(1, id: 0), _tile(0)]);
      expect(
          resolver
              .resolveTransition(
                  from, _cell(x: 2), SourceCardinalDirection.right)
              .isPassable,
          isNull);
    });

    test('out of bounds is blocked and nonadjacent or crossmap is a gap', () {
      expect(
          resolver
              .resolveTransition(
                  _cell(x: 3), _cell(x: 4), SourceCardinalDirection.right)
              .reason,
          SourcePassageReason.outOfBounds);
      expect(
          resolver
              .resolveTransition(
                  _cell(x: 3), _cell(x: 4), SourceCardinalDirection.right)
              .status,
          SourcePassageStatus.blocked);
      expect(
          resolver
              .resolveTransition(
                  _cell(), _cell(x: 3), SourceCardinalDirection.right)
              .reason,
          SourcePassageReason.nonAdjacentCell);
      expect(
          resolver
              .resolveTransition(
                  _cell(), _cell(map: 10, x: 2), SourceCardinalDirection.right)
              .reason,
          SourcePassageReason.crossMapTransition);
    });
  });
}
